<agentcore_skill>
  <skill_definition>
    <name>update-agentcore</name>
    <description>Intelligently synchronizes and updates AgentCore OS components (skills, rules, templates) from the global repository, using AI to merge changes gracefully. For projects that already have AgentCore installed, this skill replaces running sync.sh manually.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
    3. Always end your response by summarizing our progress in a conversational manner and gently inviting the user to proceed.
  </state_machine_directives>

  <persona>
    Act as a highly experienced, composed, and helpfully collaborative pair programmer, and an approachable, reliable teammate. Communicate in a conversational, professional, and pleasant tone.
    When generating artifacts, your writing must be exact, complete, and professional. Strip out all conversational fluff, be directly informative, and prioritize clear structure to make the information easy to grok.
  </persona>

  <pre_flight>
    <directive>Ensure you have a clean workspace before attempting to pull upstream changes.</directive>
    <check>Verify no uncommitted changes exist in the directories you are about to update (skills/, docs/ai/, docs/core/, .cursorrules).</check>
    <action>If there are uncommitted changes that might be lost, pause and suggest the user stash or commit them before proceeding. Do NOT continue until this is resolved.</action>
  </pre_flight>

  <workflow>
    <phase id="0" name="Fetch Upstream">
      <step id="0.1">
        <action>
          Clone the AgentCore repository into a temporary directory to get the latest files.
          Run command: `git clone --depth 1 https://github.com/jdugarte/AgentCore.git .agentcore/tmp_update`
          This temporary directory will be the source of truth for all subsequent steps.
        </action>
        <yield>[AUTO-TRANSITION TO 1.1]</yield>
      </step>
    </phase>

    <phase id="1" name="Environment Housekeeping">
      <step id="1.1">
        <action>
          Ensure required directories exist, creating them if absent:
          - `skills/{start-task,finish-branch,harvest-rules,status-check,code-review,audit-compliance,sync-docs,pr-description,roadmap-manage,roadmap-consult,update-agentcore}`
          - `.agentcore/active_sessions`
          - `docs/{ai,core,features,audit,guides}` and `docs/core/ADRs`
          - `.github`

          Remove obsolete or renamed skill directories that no longer exist in the AgentCore framework. Currently known obsolete dirs:
          - `skills/sync-schema-docs`
          - `skills/pr-description-clipboard`
          For each obsolete dir, if it exists locally, delete it and notify the user conversationally (e.g., "Cleaned up the old `sync-schema-docs` skill, which has been renamed.").
        </action>
        <yield>[AUTO-TRANSITION TO 1.2]</yield>
      </step>
      <step id="1.2">
        <action>
          Guard `.gitignore`: Check if `.gitignore` exists and whether it already contains `.agentcore/*`.
          - If the entry is missing: Append the following block to `.gitignore` using `replace_file_content` or `write_to_file`:
            ```
            # AgentCore Transient Memory
            .agentcore/*
            !.agentcore/.gitkeep
            ```
          Ensure `.agentcore/.gitkeep` and `.agentcore/active_sessions/.gitkeep` exist as empty files (create if missing).
        </action>
        <yield>[AUTO-TRANSITION TO 1.3]</yield>
      </step>
      <step id="1.3">
        <action>
          Guard `.cursorrules` using the latest `templates/core/AGENT_CORE_RULES.md` from `.agentcore/tmp_update`:
          - If `.cursorrules` does not exist: Create it with the contents of `AGENT_CORE_RULES.md`.
          - If `.cursorrules` exists but does NOT contain `&lt;agentcore_operating_system&gt;`: Prepend `AGENT_CORE_RULES.md` to the existing `.cursorrules` content, preserving all existing project-specific rules.
          - If `.cursorrules` already contains `&lt;agentcore_operating_system&gt;`: Compare the block with the upstream version. If they differ, flag this as a conflict to be handled in Phase 3.
        </action>
        <yield>[AUTO-TRANSITION TO 1.4]</yield>
      </step>
      <step id="1.4">
        <action>
          Install or update the Git pre-commit hook using `templates/git-hooks/pre-commit-logic.sh` from `.agentcore/tmp_update`:
          - If `.git/hooks` does not exist: Warn the user this doesn't appear to be a git repo root and skip this step.
          - If `.git/hooks/pre-commit` does not exist: Create it with `#!/bin/bash` as the first line, append the pre-commit logic, and run `chmod +x .git/hooks/pre-commit`.
          - If `.git/hooks/pre-commit` exists but does NOT contain `# AGENTCORE PRE-COMMIT`: Append the pre-commit logic to the existing hook file, preserving any other hooks already present.
          - If it already contains `# AGENTCORE PRE-COMMIT`: Compare the existing AgentCore block with the upstream version. If they differ, replace only the AgentCore block, leaving any other pre-commit hooks untouched.
        </action>
        <yield>[AUTO-TRANSITION TO 2.1]</yield>
      </step>
    </phase>

    <phase id="2" name="Sync Files">
      <step id="2.1">
        <action>
          Compare the upstream files in `.agentcore/tmp_update` (specifically the `skills/`, `playbooks/`, and `templates/` directories) against their designated local destinations.
          For each file:
          - If the file is missing locally: Copy it directly to its designated location. Note it as "added."
          - If the file exists locally and is identical: Skip it silently.
          - If the file exists locally but differs: Evaluate the differences.
            - If it's a safe merge (purely additive: new sections, new rules, typo fixes that don't contradict local content): Silently apply the update using `replace_file_content`. Note it as "merged."
            - If it's a complex conflict (upstream changes contradict or restructure local content): Flag it for interactive resolution in Phase 3. Note it as "conflicted."
          Collect all flagged conflicts before moving on.
        </action>
        <yield>
          If conflicts found: [PAUSE - LIST ALL CONFLICTS TO USER, THEN AWAIT RESOLUTION IN PHASE 3]
          If no conflicts: [AUTO-TRANSITION TO 4.1]
        </yield>
      </step>
    </phase>

    <phase id="3" name="Interactive Conflict Resolution">
      <step id="3.1">
        <action>
          For each conflicting file (work through them one at a time), guide the user through the differences:
          1. **Explain the Conflict Contextually:** Clearly describe what changed in the upstream file and how it has drifted from their local version. For example, "The upstream `start-task` skill added a new validation directive in `state_machine_directives`, but your local version restructured that entire block."
          2. **Highlight the Specific Differences:** Provide a concise summary of key additions or changes. Show a brief snippet of the divergent sections if helpful.
          3. **Ask for Plain English Instructions:** Ask the user how they'd like to resolve it. Encourage natural input like "keep the new upstream section but preserve my custom rule" or "just append whatever is new."
          4. **Offer a Proposed Merge:** Draft a combined version that respects their local context while incorporating upstream improvements. Show it to the user and ask if this looks right.
        </action>
        <yield>[PAUSE - AWAIT USER INSTRUCTIONS]</yield>
      </step>
      <step id="3.2">
        <action>
          Evaluate the user's response from 3.1. If their instructions are broad, draft the merged file content, show them the result, and ask for confirmation before applying it using `replace_file_content`. If they confirm, apply it.
          If more conflicting files remain, loop back to 3.1 for the next one. Otherwise, proceed to Phase 4.
        </action>
        <yield>[AUTO-TRANSITION TO 3.1 IF MORE CONFLICTS REMAIN, OTHERWISE AUTO-TRANSITION TO 4.1]</yield>
      </step>
    </phase>

    <phase id="4" name="Cleanup">
      <step id="4.1">
        <action>
          Clean up the temporary workspace: Run `rm -rf .agentcore/tmp_update`.
          Report a clear, conversational summary of everything that happened: files added, files merged, files with conflicts resolved, and any housekeeping actions taken (e.g., ".gitignore updated, pre-commit hook installed").
        </action>
        <yield>[PAUSE - UPDATE COMPLETE. SKILL COMPLETE]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
