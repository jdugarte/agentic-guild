<agentic_guild_skill>
  <skill_definition>
    <name>finish-branch</name>
    <description>Handles the completion of a branch: code review, compliance audit, the Draft PR, CI check and remote review loops, rule harvest, docs, and archive. Runs stepped (every report stops for the owner) or hands-off (the review loops chain automatically after each owner choice).</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response, except where a nested skill (`code-review`, `audit-compliance`) chains its own fix and re-review rounds in hands-off mode.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
    3. CYCLIC EXECUTION: You are permitted to loop backward between steps if the workflow dictates it.
    4. Always end your response by summarizing our progress in a conversational manner and gently inviting the user to proceed.
    5. REPLY WORDS: `FIX 1,3` or `FIX all`, `FIX all except 2`, `ACCEPT 2`, `APPLY 1,2` or `APPLY all` (rule harvest), `CONTINUE` (move on; `PROCEED` is accepted), `STOP` (end without further changes). Free-form replies still work; offer these words.
    6. MODE: Read `finish_branch_mode` in `.agenticguild/config.json` with `cat` (`stepped` when absent). The owner can also say "finish branch hands-off" for this run. In BOTH modes every report from `code-review` and `audit-compliance` stops for the owner's choice. In hands-off mode only: after the owner's choice, the nested skill applies the fixes, updates the review ledger, runs the checks, commits, and runs the next pass over the whole branch automatically, then stops at the new report; and the "ready to move on?" pauses between phases are skipped. These still stop in hands-off mode: the `sync-docs` confirmation, the `harvest-rules` approval, the wait for CI check and remote review results, the question about clearing the task, any finding that needs a product or architecture decision, and every action the git rules forbid.
    7. REMOTE REVIEW: Some remote reviewers (for example Bugbot) review a PR only once. Never trigger the remote reviewer yourself, and never post its re-run comment unless the owner explicitly asks. Never suggest a re-run after docs-only changes. Tell the owner when a manual re-run is worthwhile: when code changed after the review.
    8. PUSH TIMING (applies when the git mode or hands-off allows pushing): Before the Draft PR exists, commit and push as work finishes. After the Draft exists, push only (a) at each CI check or remote review fix round and (b) once at the very end, after the documentation and archive steps, with no pushes in between. In a hands-off run, run `git pull --rebase` on the feature branch before each push; if it conflicts, stop and ask, and never force-push. In stepped mode, if a push is rejected, report it to the owner and wait; the owner tells you to pull and rebase.
    9. PR TIMING: NEVER create a PR before the code review and the compliance audit have closed with `CONTINUE` (clean, or with remaining findings explicitly named and accepted) and the pre-Draft full check (step 2.5.1) has passed. The full check has passed when it ran green (`cloud` mode or hands-off), when the owner confirmed it green (`suggest` or `commit` mode), or when the owner explicitly accepted proceeding without a green run by replying `CONTINUE` at step 2.5.1; the check itself never needs a `CONTINUE` when it ran green by itself. The Draft PR is created only at step 2.5.2. Never mark a PR Ready and never merge.
  </state_machine_directives>

  <hard_constraints>
    GIT MODES: Read `agent_git` in `.agenticguild/config.json` with `cat` (`suggest` when absent). `suggest`: never run `git commit` or `git push`; when a commit is appropriate, output a suggested message as a plain-text code block and the owner runs git. `commit`: you may run `git commit` on the current feature branch, never `git push`. `cloud`: you may run `git commit` and `git push` on the current feature branch. A hands-off run (`start_task_mode` or `finish_branch_mode` set to hands-off, or the owner said hands-off for this run) allows commit and push for that run in any mode.
    ALWAYS FORBIDDEN in every mode: `git merge`, `git push --force` (and `--force-with-lease`), amending commits that were already pushed, pushing to the default branch, `gh pr merge`, `gh pr close`, `gh pr ready`, `gh release create`, and creating a PR. The only PR you may create is the Draft PR at the finish-branch PR step, and only when the owner chose that step.
    SAFE FILE OPERATIONS: Never overwrite or delete an existing file without the user's explicit confirmation. Before any file write, move, or delete, read `docs/ai/SAFE_FILE_OPERATIONS.md` and follow it.
  </hard_constraints>

  <persona>
    Act as a highly experienced, composed, and helpfully collaborative pair programmer, and an approachable, reliable teammate. Communicate in a conversational, professional, and pleasant tone. Hide the technical "phases and steps" of this workflow behind natural, grounded conversation (e.g. "Let's check the CI results" instead of "Transitioning to Phase 3").
    When generating artifacts or documentation, your writing must be exact, complete, and professional. Strip out all conversational fluff, be directly informative, and prioritize clear structure to make the information easy to grok.
  </persona>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/deterministic_coding_standards.md`, `docs/core/SYSTEM_ARCHITECTURE.md`, and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, pause our work and gently let the user know we need these files to start. Offer to gracefully initialize the project templates for them. If the user says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without user confirmation.</action>
  </pre_flight>

  <workflow>
    <phase id="0" name="Stealth Check">
      <step id="0.1">
        <action>
          Use `cat` to quietly read `.agenticguild/config.json`. If it contains `"stealth_mode": true`, remember that you are operating in stealth mode. Note `finish_branch_mode` (`stepped` when absent), `agent_git` (`suggest` when absent), and `verification` (`tdd` when absent). If the owner said "hands-off" in this request, run hands-off for this run. Do not announce any of this to the user.
          Check whether `docs/core/BEHAVIOUR_MATRIX.md` exists with `test -e`. If it does, the behaviour matrix coverage check (phase 0.5) applies; otherwise skip it.
        </action>
        <yield>[AUTO-TRANSITION TO 0.5.1 if the behaviour matrix file exists, otherwise TO 1.1]</yield>
      </step>
    </phase>

    <phase id="0.5" name="Behaviour Matrix Coverage (only when docs/core/BEHAVIOUR_MATRIX.md exists)">
      <step id="0.5.1">
        <action>
          Determine the audit scope: the feature(s) named in the active session plus every feature touched by the branch diff. If the scope is unclear, audit all rows. Classify each in-scope row by its status: `automated` (a test path exists), `manual-only` (an explicit reason is documented), `planned` (no test and not marked manual-only: a gap), or `n/a` (excluded with a rationale).
          Report the counts and list every `planned` row. A `planned` row blocks the review unless the owner writes the missing test now, marks the row `manual-only` with a reason, or consciously defers it with a note. If every in-scope row is `automated`, `manual-only`, or `n/a`, confirm the coverage and [AUTO-TRANSITION TO 1.1].
        </action>
        <yield>[PAUSE - AWAIT RESOLUTION OF EACH PLANNED ROW (auto-transition if there are none)]</yield>
      </step>
    </phase>

    <phase id="1" name="Interactive Local Review">
      <step id="1.1">
        <action>Use the `view_file` tool to read and follow `.cursor/skills/code-review/SKILL.md`. Execute the full skill, including its own stops, until the owner replies `CONTINUE` (clean, or with any remaining findings explicitly named and accepted) or `STOP`. On `STOP`, end finish-branch. In hands-off mode, hand directly to Phase 2 without an extra pause; in stepped mode, confirm the result and pause.</action>
        <yield>[PAUSE - AWAIT CODE REVIEW COMPLETION (stepped mode; hands-off continues to 2.1 after CONTINUE)]</yield>
      </step>
    </phase>

    <phase id="2" name="Compliance & Traceability Audit">
      <step id="2.1">
        <action>
          Use the `view_file` tool to read and follow `.cursor/skills/audit-compliance/SKILL.md`. Execute the full skill, including its own stops, until the owner replies `CONTINUE` (clean, or with any remaining findings explicitly named and accepted) or `STOP`. The audit covers complexity and function length, test traceability (skipped in Stealth Mode and under `verification: human-review`), and domain primitives (CbC), as defined by `docs/core/deterministic_coding_standards.md`. On `STOP`, end finish-branch. In hands-off mode, hand directly to Phase 2.5; in stepped mode, confirm the result and pause.
        </action>
        <yield>[PAUSE - AWAIT COMPLIANCE AUDIT COMPLETION (stepped mode; hands-off continues to 2.5.1 after CONTINUE)]</yield>
      </step>
    </phase>

    <phase id="2.5" name="Full Check & Draft PR">
      <step id="2.5.1">
        <action>
          Gate: continue only if both the code review and the compliance audit closed with `CONTINUE`. If either ended with `STOP` or has not run, do not proceed: tell the owner which check is outstanding and invite them to re-run it. No PR is created before this gate passes.
          Full check before the Draft PR: because CI checks usually do not run on draft PRs, run the project's full test and check suite now so any failure is fixed locally before opening the Draft (if `docs/ai/code_review_prompt.md` lists quality or check commands, run those too; under `verification: human-review`, run only documented linters/checks and skip automated tests, or note that none exist and continue).
          - `agent_git: cloud` or hands-off: run the full check yourself and report what ran (claim "passed" only for commands you actually ran). If anything fails, fix it, log the fix in `.agenticguild/review_ledger.md` if applicable, re-run the full check, and commit until it passes (in hands-off, stop if a failure persists after an honest fix attempt). Once green, [AUTO-TRANSITION TO 2.5.2].
          - `agent_git: suggest` or `commit` outside hands-off: ask the owner to run the full check and report the result (do not claim it passed and do not prompt for the Draft PR yet). If the owner reports failures, fix them, log them in `.agenticguild/review_ledger.md` if applicable, commit (in `commit` mode) or suggest a commit message (in `suggest` mode), and ask the owner to re-run — stay in step 2.5.1. Advance to step 2.5.2 only after the owner confirms the full check is green (or explicitly replies `CONTINUE` to proceed anyway).
        </action>
        <yield>
          If the full check passed in `cloud` mode or hands-off (or under `human-review` with no check commands): [AUTO-TRANSITION TO 2.5.2].
          Otherwise (`suggest` or `commit` mode outside hands-off, or an unresolved failure): [PAUSE - AWAIT FULL CHECK CONFIRMATION BEFORE STEP 2.5.2].
        </yield>
      </step>
      <step id="2.5.2">
        <action>
          Gate: enter only after step 2.5.1 confirmed the full check is green (or the owner explicitly replied `CONTINUE` to proceed anyway).
          Make sure the work is committed and pushed first, within the git rules (PUSH TIMING: pushes are allowed before the Draft exists):
          - `suggest` mode outside hands-off: output the git commit and push commands as a plain-text code block for the owner to run.
          - `commit` mode outside hands-off: commit any uncommitted changes and ask the owner to push.
          - `cloud` mode or hands-off: commit any uncommitted changes, run `git pull --rebase` if hands-off, and push.
          If a PR already exists for this branch, use it. Otherwise, open a Draft PR (never a ready PR):
          - `suggest` or `commit` mode outside hands-off (or whenever no PR tool is available): tell the owner it is time to open the Draft PR now, and give them the PR description from `.cursor/skills/pr-description/SKILL.md` (the filled PR template) to paste.
          - `agent_git: cloud` outside hands-off (with a PR tool): ask "Do you want me to open the Draft PR now?" and wait for the answer. On yes, create a Draft with the PR tool, using the filled PR template as the body.
          - Hands-off (with a PR tool): open the Draft PR automatically using the filled PR template as the body.
          If QA ran for this task and the session holds a staged QA reviewer record under `## QA reviewer record` that is not yet marked as posted: post it once on the Draft PR (manual mode: give the owner the text to paste), then mark it as posted in the session with a targeted edit. A later QA run produces a new comment; never edit or delete the older one. Never repost a comment that is already marked as posted.
          Update `.agenticguild/current_state.md` with a targeted edit to indicate waiting for remote review (retain `<active_task_pointer>` unchanged).
        </action>
        <yield>[PAUSE - AWAIT THE DRAFT PR (when the owner must open it or confirm opening it); hands-off (or once the Draft is open) continues to 3.1]</yield>
      </step>
    </phase>

    <phase id="3" name="Remote Review Loop (remote review on Draft; CI check after Ready)">
      <step id="3.1">
        <action>
          Tell the owner the Draft PR is waiting for the remote review (the remote reviewer reviews the Draft once, automatically; CI checks normally run only after the PR is marked Ready, unless the repo runs CI on drafts). Ask them to paste any remote review findings or CI errors, or to reply `CONTINUE` if clear.
        </action>
        <yield>
          [PAUSE - AWAIT REMOTE REVIEW STATUS]
        </yield>
      </step>
      <step id="3.2">
        <action>
          Parse the owner's input:
          - If they pasted errors or findings: analyze them, fix the real issues (ignore noise and false positives after a brief note), and for EACH fixed issue silently append an entry to `.agenticguild/review_ledger.md` (check with `test -e`; create if missing; never overwrite): **Source** ("CI check" or "Remote review"), **Issue**, **Diagnosis/Why it failed**, **Outcome** (fixed), **Fix**. Run the project's checks (claim "verified" only for commands you ran), commit, and push if the git rules allow it (PUSH TIMING (a)). If the fixes change user-visible behavior, also touch up `CHANGELOG.md` and the PR description text as needed (not in Stealth Mode). Then wait for the next status; mention that a manual re-run of the remote reviewer is worthwhile now because code changed (never post it yourself).
          - If they replied `CONTINUE` (remote review is clear): skip fixes and decide whether the full check must run again.
            - If no code changed since step 2.5.1, no re-run is needed: the outcome of step 2.5.1 stands (green, or accepted by the owner's explicit `CONTINUE` there). Go to the clear branch below.
            - If code changed during the remote review loop (since step 2.5.1), run the full check pass again (under `verification: human-review`, run only documented linters/checks). In `cloud` mode or hands-off, run it yourself and report what ran: if it passes, go to the clear branch below; if it fails, fix it as one more fix round above (log it, commit, push per PUSH TIMING (a)) and re-run, and in hands-off stop if a failure persists after an honest fix attempt. In `suggest` or `commit` mode outside hands-off, ask the owner to run it and wait: when the owner confirms green, or replies `CONTINUE` to proceed anyway, go to the clear branch; if the owner reports a failure, fix it as one more fix round above and ask again.
          - If they replied `STOP`: end finish-branch without making further changes.
        </action>
        <yield>
          If fixes were applied: [PAUSE - AWAIT REMOTE REVIEW STATUS] (silently set the state back to 3.1).
          If waiting on the owner to confirm the post-loop full check (`suggest` or `commit` mode outside hands-off): [PAUSE - AWAIT FULL CHECK CONFIRMATION BEFORE PHASE 4].
          Clear branch (the remote review is clear and either no re-run was needed or the re-run passed or was accepted by the owner): tell the owner we are ready for the final docs and archive steps; in stepped mode ask `CONTINUE` to move forward or `STOP` to end ([PAUSE - AWAIT CONTINUE OR STOP]); in hands-off mode [AUTO-TRANSITION TO 4.1].
        </yield>
      </step>
    </phase>

    <phase id="4" name="Harvest, Docs & Close-out">
      <step id="4.1">
        <action>
          If NOT in Stealth Mode: Use the `view_file` tool to read and follow `.cursor/skills/harvest-rules/SKILL.md`, including its own stops (`APPLY`, `CONTINUE`, or `STOP`). If the owner replies `STOP`, end finish-branch without clearing the active task or the ledger. Harvest runs before the docs so that the docs step can skip rules harvest just wrote.
          If in Stealth Mode: Skip `harvest-rules` entirely, as writing tracking rules inferred from Git diffs into tracked files violates stealth mode constraints, and move directly to step 4.2.
        </action>
        <yield>[PAUSE - AWAIT CONTINUE (the harvest approval always stops)]</yield>
      </step>
      <step id="4.2">
        <action>
          If NOT in Stealth Mode: Use the `view_file` tool to read and follow `.cursor/skills/sync-docs/SKILL.md` until it yields. The skill analyzes the branch diff and the session and updates any docs that need changes.
          If in Stealth Mode: Skip `sync-docs` entirely, as automatically modifying architectural documents violates stealth mode constraints.
        </action>
        <yield>[PAUSE - AWAIT CONFIRMATION TO PROCEED (the docs confirmation always stops)]</yield>
      </step>
      <step id="4.3">
        <action>
          If NOT in Stealth Mode: Check if user-facing changes exist; if so, ensure `CHANGELOG.md` is updated. Use `cat` to read the active session file (if any) for `<roadmap_item>`. If this branch corresponds to a roadmap item, update `docs/ROADMAP.md`: move the item to Done, add today's date. If unclear, ask the user which roadmap item (if any) this branch completes.
          If in Stealth Mode: Do NOT modify or remind the user about `CHANGELOG.md` or `docs/ROADMAP.md` to avoid altering the external team's tracked documentation.

          Then (in all modes): use the `view_file` tool to read and follow `.cursor/skills/pr-description/SKILL.md` until it yields. The filled PR template is the PR body: update the Draft PR body with the final text (with the PR tool in `cloud` mode or hands-off; otherwise give the owner the text to paste).
        </action>
        <yield>[PAUSE - AWAIT CONFIRMATION]</yield>
      </step>
      <step id="4.4">
        <action>
          If NOT in Stealth Mode: The branch is finished and task knowledge has been synced to the docs (harvest-rules and sync-docs). Conversationally tell the user that.
          If in Stealth Mode: Conversationally tell the user the PR is ready (remember sync-docs and harvest-rules were intentionally skipped).

          Then (in all modes): Ask: "Would you like me to clear the active task from memory? I'll set the active task to none and move the session file to `.agenticguild/completed_sessions/` so it's no longer the current task. Reply CONTINUE to clear and archive, or STOP to leave it as-is for now."
        </action>
        <yield>[PAUSE - AWAIT CONTINUE OR STOP (this question always stops)]</yield>
      </step>
      <step id="4.5">
        <action>
          Parse the user's reply. If they replied `CONTINUE` (or confirmed, e.g. "yes", "clear", "archive"): Use `cat` to read `.agenticguild/current_state.md` to get `<active_task_pointer>`. If the pointer contains a session filename (e.g. `task_foo.md`): Create `.agenticguild/completed_sessions/` if it does not exist. MOVE the session file from `.agenticguild/active_sessions/` to `.agenticguild/completed_sessions/` with a date suffix in the filename (e.g. `task_foo_YYYY-MM-DD.md`); never copy-and-delete and never overwrite an existing archived file. Then use a targeted edit to update `.agenticguild/current_state.md`: set `<active_task_pointer>` to `[NONE]` and `<execution_context>` to `<active_skill>[NONE]</active_skill>`, `<current_phase>[NONE]</current_phase>`, `<current_step>[NONE]</current_step>`. If the pointer was already [NONE] or the session file was missing, just update current_state to [NONE]. Confirm to the user that the task was cleared and the session file was archived.
          If they replied `STOP` (or declined): Acknowledge; no changes. The session stays in active_sessions and the pointer unchanged; they can clear later via status-check or by running finish-branch again.
        </action>
        <yield>[AUTO-TRANSITION TO 4.6]</yield>
      </step>
      <step id="4.6">
        <action>
          Close-out. Make one final commit of any uncommitted harvest, docs, and archive changes (allowed in `commit` and `cloud` modes and in hands-off; in `suggest` mode output a suggested commit message instead). If the git rules allow pushing (`cloud` mode or hands-off), push once, as the last push (in hands-off, `git pull --rebase` first). Then remind the owner to mark the PR Ready for review so the final CI check runs. Do not suggest re-running the remote reviewer after docs-only changes. Never mark the PR Ready yourself and never merge.
        </action>
        <yield>[PAUSE - FINISH-BRANCH COMPLETE]</yield>
      </step>
    </phase>
  </workflow>
</agentic_guild_skill>
