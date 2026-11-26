<agentic_guild_skill>
  <skill_definition>
    <name>update-agentic-guild</name>
    <description>Intelligently synchronizes and updates agentic:guild OS components (skills, rules, templates) from the global repository, using AI to merge changes gracefully. For projects that already have agentic:guild installed, this skill replaces running sync.sh manually.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
    3. Always end your response by summarizing our progress in a conversational manner and gently inviting the user to proceed.
    4. CONFLICT QUEUE: Maintain a mental list called the "Conflict Queue" throughout the entire skill execution. Any step that detects a conflict MUST add it to this queue rather than attempting to resolve it inline. Phase 3 is the sole owner of conflict resolution. A conflict is only "done" when Phase 3 has fully resolved it.
  </state_machine_directives>

  <hard_constraints>
    GIT MODES: Read `agent_git` in `.agenticguild/config.json` with `cat` (`suggest` when absent). `suggest`: never run `git commit` or `git push`; when a commit is appropriate, output a suggested message as a plain-text code block and the owner runs git. `commit`: you may run `git commit` on the current feature branch, never `git push`. `cloud`: you may run `git commit` and `git push` on the current feature branch. A hands-off run (`start_task_mode` or `finish_branch_mode` set to hands-off, or the owner said hands-off for this run) allows commit and push for that run in any mode.
    ALWAYS FORBIDDEN in every mode: `git merge`, `git push --force` (and `--force-with-lease`), amending commits that were already pushed, pushing to the default branch, `gh pr merge`, `gh pr close`, `gh pr ready`, `gh release create`, and creating a PR. The only PR you may create is the Draft PR at the finish-branch PR step, and only when the owner chose that step.
    SAFE FILE OPERATIONS: Never overwrite or delete an existing file without the user's explicit confirmation. Before any file write, move, or delete, read `docs/ai/SAFE_FILE_OPERATIONS.md` and follow it.
  </hard_constraints>

  <persona>
    Act as a highly experienced, composed, and helpfully collaborative pair programmer, and an approachable, reliable teammate. Communicate in a conversational, professional, and pleasant tone.
    When generating artifacts, your writing must be exact, complete, and professional. Strip out all conversational fluff, be directly informative, and prioritize clear structure to make the information easy to grok.
  </persona>

  <pre_flight>
    <directive>Ensure you have a clean workspace before attempting to pull upstream changes.</directive>
    <check>Verify no uncommitted changes exist in the directories you are about to update (.cursor/skills/, docs/ai/, docs/core/, .cursorrules).</check>
    <action>If there are uncommitted changes that might be lost, pause and suggest the user stash or commit them before proceeding. Do NOT continue until this is resolved. Also check whether `.agenticguild/tmp_update` already exists from an interrupted previous run; if so, mention it — it will be cleaned up in Step 0.2.</action>
  </pre_flight>

  <workflow>
    <phase id="0" name="Pre-Update Checks">
      <step id="0.1">
        <action>
          Use the `view_file` tool to quietly read `.agenticguild/config.json`. If it exists and contains `"stealth_mode": true`, remember that you are operating in stealth mode. Do not announce this to the user.
        </action>
        <yield>[AUTO-TRANSITION TO 0.2]</yield>
      </step>
      <step id="0.2">
        <action>
          Clone the agentic:guild repository into a temporary directory to get the latest files.
          First, remove any leftover temp directory from a previously interrupted run: `rm -rf .agenticguild/tmp_update`
          Then run: `git clone --depth 1 https://github.com/jdugarte/agentic-guild.git .agenticguild/tmp_update`
          This temporary directory will be the source of truth for all subsequent steps.
          Initialize the Conflict Queue as empty.
        </action>
        <yield>[AUTO-TRANSITION TO 1.1]</yield>
      </step>
    </phase>

    <phase id="1" name="Environment Housekeeping">
      <step id="1.1">
        <action>
          Ensure required directories exist, creating them if absent:
          - `.agenticguild/active_sessions`
          - `.agenticguild/completed_sessions`

          Do not pre-create skill folders. The Sync Registry decides which skill folders exist: when a registry destination is copied in Phase 2, create its parent directory first if it does not exist.

          If NOT in stealth mode, also ensure these directories exist:
          - `docs/{ai,core,features,audit,guides}` and `docs/core/ADRs`
          - `.github`
        </action>
        <yield>[AUTO-TRANSITION TO 1.2]</yield>
      </step>
      <step id="1.2">
        <action>
          Guard the git ignore rules for `.agenticguild/`. Follow `docs/ai/SAFE_FILE_OPERATIONS.md`: never rewrite `.gitignore` or `.git/info/exclude`. Append only, after checking with `grep` that the rule is missing. Remove or replace existing lines only after the user confirms the exact lines.

          Read `.agenticguild/config.json` with `cat` for `track_memory` (default `false`). Check whether the project already tracks its memory: if `git ls-files .agenticguild` lists any file other than `.gitkeep`, the project has chosen to commit `.agenticguild/`.

          If NOT in stealth mode:
          - If the project already tracks its memory files, or `track_memory` is `true`: never add an `.agenticguild/*` ignore-all rule. If `.gitignore` has no rule for `.agenticguild/current_state.md`, append this block:
            ```
            # agentic:guild: ephemeral files only (sessions and logs are tracked)
            .agenticguild/current_state.md
            .agenticguild/review_ledger.md
            .agenticguild/backups/
            ```
            If an old `.agenticguild/*` block is present, add to the Conflict Queue a proposal that shows the exact lines to remove; do not remove them without confirmation. Adding ignore rules does not untrack files that are already committed: tell the owner to run `git rm --cached .agenticguild/current_state.md .agenticguild/review_ledger.md` themselves; do not run it.
          - Otherwise (`track_memory` is `false` or absent): if `.gitignore` has no rule that mentions `.agenticguild`, append this block:
            ```
            # agentic:guild Transient Memory
            .agenticguild/*
            !.agenticguild/.gitkeep
            !.agenticguild/config.json
            !.agenticguild/source_package.json
            ```
            If an older block already exists without the two `config.json` and `source_package.json` exceptions, add to the Conflict Queue a proposal to append those two lines.

          If in stealth mode: ensure `.git/info/exclude` contains `.agenticguild/*` (append the block below if missing). Stealth Mode never tracks `.agenticguild/`.
            ```
            # agentic:guild (Stealth Mode)
            .agenticguild/*
            ```

          Ensure `.agenticguild/.gitkeep`, `.agenticguild/active_sessions/.gitkeep`, and `.agenticguild/completed_sessions/.gitkeep` exist (create the directories and files if missing; never overwrite an existing file).
        </action>
        <yield>[AUTO-TRANSITION TO 1.3]</yield>
      </step>
      <step id="1.3">
        <action>
          Guard `.cursorrules` using the latest `templates/core/AGENTIC_GUILD_RULES.md` from `.agenticguild/tmp_update`:
          - If `.cursorrules` does not exist: Create it with the contents of `AGENTIC_GUILD_RULES.md`. If in Stealth Mode, append `.cursorrules` to `.git/info/exclude` using `echo ".cursorrules" >> .git/info/exclude` (if not already present).
          - If `.cursorrules` exists but does NOT contain `&lt;agentic_guild_os&gt;`: Add `AGENTIC_GUILD_RULES.md` at the top of the existing `.cursorrules`, preserving all existing project-specific rules. Do not rewrite the file: keep a copy in `.agenticguild/backups/.cursorrules.bak`, build the new content in a temporary file, and replace `.cursorrules` only after confirming that every original line is still present. If in Stealth Mode, add a warning to your final summary that `.cursorrules` blocks were added and should be stripped before committing if the team does not want the agentic:guild config.
          - If `.cursorrules` already contains `&lt;agentic_guild_os&gt;` AND the block is identical to the upstream version: Skip silently.
          - If `.cursorrules` already contains `&lt;agentic_guild_os&gt;` AND the block differs from upstream: Add `{ file: ".cursorrules", reason: "agentic:guild OS block has drifted from upstream" }` to the Conflict Queue. Do NOT attempt to resolve it here.
        </action>
        <yield>[AUTO-TRANSITION TO 1.4]</yield>
      </step>
      <step id="1.4">
        <action>
          If in stealth mode: Skip this step entirely to avoid disrupting team workflows. [AUTO-TRANSITION TO 2.1].
          
          If NOT in stealth mode:
          Install or update the Git pre-commit hook using `templates/git-hooks/pre-commit-logic.sh` from `.agenticguild/tmp_update`:
          - If `.git/hooks` does not exist: Warn the user this doesn't appear to be a git repo root and skip this step.
          - If `.git/hooks/pre-commit` does not exist: Create it with `#!/bin/bash` as the first line, append the pre-commit logic, and run `chmod +x .git/hooks/pre-commit`.
          - If `.git/hooks/pre-commit` exists but does NOT contain `# AGENTIC-GUILD PRE-COMMIT`: Append the pre-commit logic to the existing hook file, preserving any other hooks already present.
          - If it already contains `# AGENTIC-GUILD PRE-COMMIT` AND the block is identical to upstream: Skip silently.
          - If it already contains `# AGENTIC-GUILD PRE-COMMIT` AND the block differs from upstream: Show the user the exact block and its upstream replacement, and only after the user confirms, keep a copy of the hook in `.agenticguild/backups/` and replace only the agentic:guild block, leaving any other pre-commit hooks untouched.
        </action>
        <yield>[AUTO-TRANSITION TO 2.1]</yield>
      </step>
    </phase>

    <phase id="2" name="Sync Files">
      <step id="2.1">
        <action>
          Read the **Sync Registry** from `.agenticguild/tmp_update/playbooks/SYNC_REGISTRY.md` using the `view_file` tool. This file is the single source of truth for all file mappings and strategies. Parse the `SYNC_REGISTRY [START]` / `SYNC_REGISTRY [END]` table to get the full list of `Upstream Source`, `Local Destination`, and `Strategy` values.

          IMPORTANT: Skip any rows for `templates/core/AGENTIC_GUILD_RULES.md` and `templates/git-hooks/pre-commit-logic.sh` — these were already handled with specialized logic in Phase 1.

          Follow `docs/ai/SAFE_FILE_OPERATIONS.md` for every write in this phase. Create the parent directory of each destination before copying a file into it.

          For each row in the registry with strategy `merge`:
          - If the file is missing locally: Copy it to its destination. Note it as "added." If in Stealth Mode, append the new file path to `.git/info/exclude` using `echo "path/to/file" >> .git/info/exclude` (if not already present).
          - If the file exists locally and is identical to upstream: Skip it silently.
          - If the file exists locally but differs from upstream:
            - If in Stealth Mode AND the file is NOT listed in `.git/info/exclude`, skip it entirely to avoid dirtying team-tracked files (e.g., `.github/PULL_REQUEST_TEMPLATE.md`).
            - Otherwise:
              - If it's a safe merge (purely additive: new sections, new rules, typo fixes that don't contradict local content): Apply silently with a targeted edit. Note it as "merged." Anything that would remove or replace existing local text is NOT a safe merge: add it to the Conflict Queue.
              - If it's a complex conflict (upstream changes contradict or restructure local content): Add it to the Conflict Queue. Note it as "conflicted."

          For each row in the registry with strategy `init`:
          - If missing locally: Copy it to its destination. Note it as "added." If in Stealth Mode, append the new file path to `.git/info/exclude` using `echo "path/to/file" >> .git/info/exclude` (if not already present).
          - If already exists locally: Skip it entirely. Do not compare, diff, or overwrite. These are project-specific files.

          Collect all conflicts into the Conflict Queue. Do NOT transition to cleanup until Phase 3 has cleared them.
        </action>
        <yield>
          [AUTO-TRANSITION TO 3.1] (Phase 3 will immediately proceed to cleanup if the Conflict Queue is empty)
        </yield>
      </step>
    </phase>

    <phase id="3" name="Interactive Conflict Resolution">
      <step id="3.1">
        <action>
          Check the Conflict Queue (accumulated from all previous phases, including .cursorrules from Phase 1).
          If the queue is empty: [AUTO-TRANSITION TO 4.1].
          If conflicts remain: Present the full list of conflicts to the user conversationally (e.g., "I found 2 files that need your input before I can finish: .cursorrules and .cursor/skills/start-task/SKILL.md"). Then work through them one at a time:
          1. **Explain the Conflict Contextually:** Clearly describe what changed in the upstream file and how it has drifted from their local version.
          2. **Highlight the Specific Differences:** Provide a concise summary of key additions or changes. Show a brief snippet of the divergent sections if helpful.
          3. **Ask for Plain English Instructions:** Ask the user how they'd like to resolve it. Encourage natural input like "keep the new upstream section but preserve my custom rule" or "just append whatever is new."
          4. **Offer a Proposed Merge:** Draft a combined version that respects their local context while incorporating upstream improvements. Show it to the user and ask if this looks right.
        </action>
        <yield>[PAUSE - AWAIT USER INSTRUCTIONS]</yield>
      </step>
      <step id="3.2">
        <action>
          Evaluate the user's response from 3.1. If their instructions are broad, draft the merged file content, show them the result, and ask for confirmation before applying it using `replace_file_content`. If they confirm, keep a backup of the local file as `docs/ai/SAFE_FILE_OPERATIONS.md` describes (skip it when the file is tracked and has no uncommitted changes), apply the merge with a targeted edit, and remove the file from the Conflict Queue.
          If more conflicts remain in the Conflict Queue, loop back to 3.1 for the next one. Otherwise, proceed to Phase 4.
        </action>
        <yield>
          [PAUSE - AWAIT USER CONFIRMATION BEFORE APPLYING MERGE]
          If the user confirms: apply the merge using `replace_file_content`, remove the file from the Conflict Queue, then [AUTO-TRANSITION TO 3.1 IF MORE CONFLICTS REMAIN, OTHERWISE AUTO-TRANSITION TO 4.1].
        </yield>
      </step>
    </phase>

    <phase id="4" name="Review & Cleanup">
      <step id="4.1">
        <action>
          If `.agenticguild/tmp_update/CHANGELOG.md` exists, use the `view_file` tool to quietly read it to discover what is new in the latest version. If it does not exist, skip the changelog read and leave out the "What's New" section without raising an error.
          In every case, clean up the temporary workspace: Run `rm -rf .agenticguild/tmp_update` (this scratch directory, created by this skill, is the only path this skill may delete).
          Report a clear, conversational summary of everything that happened to the local project: files added, files merged, conflicts resolved, and housekeeping actions taken.
          If you read a changelog, finish with a "🎉 What's New in agentic:guild" section where you summarize the most exciting new features, improvements, or fixes from it.
        </action>
        <yield>[PAUSE - UPDATE COMPLETE. SKILL COMPLETE]</yield>
      </step>
    </phase>
  </workflow>
</agentic_guild_skill>
