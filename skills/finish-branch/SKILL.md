<agentic_guild_skill>
  <skill_definition>
    <name>finish-branch</name>
    <description>Handles the completion of a branch: code review, compliance audit, the Draft PR, remote review loop, rule harvest, docs, and archive. Runs stepped (every report stops for the owner) or hands-off (the review loops chain automatically after each owner choice).</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response, except where a nested skill (`code-review`, `audit-compliance`) chains its own fix and re-review rounds in hands-off mode.
    2. When you reach a pause marker (text in square brackets starting with PAUSE), you MUST completely stop generating text and wait for the owner's reply.
    3. CYCLIC EXECUTION: You may loop back between steps when a step says so.
    4. End every response with a short, conversational progress summary and an invitation to proceed.
    5. REPLY WORDS: `FIX 1,3`, `FIX all`, `FIX all except 2`, `ACCEPT 2`, `APPLY 1,2` or `APPLY all` (rule harvest), `CONTINUE` (`PROCEED` is accepted), `STOP` (end without further changes). Free-form replies still work; offer these words.
    6. MODE: Read `finish_branch_mode` in `.agenticguild/config.json` with `cat` (`stepped` when absent). The owner can also say "finish branch hands-off" for this run. In BOTH modes every report from `code-review` and `audit-compliance` stops for the owner's choice. In hands-off mode only: after the owner's choice, the nested skill applies the fixes, updates the review ledger, runs the checks, commits, and runs the next pass over the whole branch automatically; the "ready to move on?" pauses between phases are skipped. These still stop in hands-off mode: the `sync-docs` confirmation, the `harvest-rules` approval, the wait for remote review results, the question about clearing the task, any finding that needs a product or architecture decision, and every action the git rules forbid.
    7. REMOTE REVIEW: Some remote reviewers (for example Bugbot) review a PR only once. Never trigger the remote reviewer yourself, and never post its re-run comment unless the owner explicitly asks. Never suggest a re-run after docs-only changes. Tell the owner when a manual re-run is worthwhile: when code changed after the review.
    8. PUSH TIMING (applies when the git mode or hands-off allows pushing): Before the Draft PR exists, commit and push as work finishes. After the Draft exists, push only (a) at each remote review fix round and (b) once at the very end, after the documentation and archive steps, with no pushes in between. In a hands-off run, run `git pull --rebase` on the feature branch before each push; if it conflicts, stop and ask, and never force-push. In stepped mode, if a push is rejected, report it to the owner and wait.
    9. PR TIMING: NEVER create a PR before the code review and the compliance audit have both closed with `CONTINUE` (clean, or with remaining findings explicitly named and accepted) and the full check of step 2.3 is accepted, as defined in step 2.4.1. The Draft PR is created only at step 2.5.2. Never mark a PR Ready and never merge.
    10. PAUSE KINDS: Every pause names exactly one kind, and the owner's reply is read only by that kind's rule (in `<pause_kinds>`). Nothing else decides what a reply means. A reply the kind does not cover is answered briefly and the same question is asked again; it is never guessed.
  </state_machine_directives>

  <hard_constraints>
    GIT MODES: Read `agent_git` in `.agenticguild/config.json` with `cat` (`suggest` when absent). `suggest`: never run `git commit` or `git push`; when a commit is appropriate, output a suggested message as a plain-text code block and the owner runs git. `commit`: you may run `git commit` on the current feature branch, never `git push`. `cloud`: you may run `git commit` and `git push` on the current feature branch. A hands-off run (`start_task_mode` or `finish_branch_mode` set to hands-off, or the owner said hands-off for this run) allows commit and push for that run in any mode.
    ALWAYS FORBIDDEN in every mode: `git merge`, `git push --force` (and `--force-with-lease`), amending commits that were already pushed, pushing to the default branch, `gh pr merge`, `gh pr close`, `gh pr ready`, `gh release create`, and creating a PR. The only PR you may create is the Draft PR at the finish-branch PR step, and only when the owner chose that step.
    SAFE FILE OPERATIONS: Never overwrite or delete an existing file without the user's explicit confirmation. Before any file write, move, or delete, read `docs/ai/SAFE_FILE_OPERATIONS.md` and follow it.
  </hard_constraints>

  <persona>
    Act as a highly experienced, composed, and helpfully collaborative pair programmer, and an approachable, reliable teammate. Communicate in a conversational, professional, and pleasant tone. Hide the technical "phases and steps" of this workflow behind natural, grounded conversation.
    When generating artifacts or documentation, your writing must be exact, complete, and professional. Strip out conversational fluff and prioritize clear structure.
  </persona>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/deterministic_coding_standards.md`, `docs/core/SYSTEM_ARCHITECTURE.md`, and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, tell the owner we need these files to start and offer to initialize the project templates. If the owner says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without owner confirmation. [PAUSE - QUESTION: initialize the missing files? yes or no]</action>
  </pre_flight>

  <pause_kinds>
    QUESTION: a yes/no or choice question. Read the owner's reply as the listed answers only. Anything else: answer it briefly and ask the question again.
    DECISION: the owner decides whether to move on. `CONTINUE` moves on to the next step the pause names; `STOP` ends finish-branch. A reply that asks for changes: make them, then ask again. A reply that pastes review findings or CI errors: fix them (FIX-FINDINGS in step 3.2) and return to the remote review pause.
    RESULT: the owner reports an outcome: remote review findings or CI errors, a full check result, or a clear/green status. Pasted failures or findings: fix them (FIX-FINDINGS or FIX-CHECK) and return to the same RESULT pause. A clear or green report, or `CONTINUE` (which at a RESULT pause means clear or green), moves on as the step says. `ACCEPT` accepts an outstanding failure: record it in the session under `## Review disposition` with the failing output it covers, then move on. `STOP` ends finish-branch. Guidance for a failure: use it for the next fix attempt, then return to the same pause. Anything else: say which replies are accepted and ask again.
    NESTED: a nested skill (`code-review`, `audit-compliance`, `harvest-rules`) reads its own reply words. When it closes with `CONTINUE`, the step names the next pause or step. When it closes with `STOP`, finish-branch ends.
  </pause_kinds>

  <workflow>
    <phase id="0" name="Setup">
      <step id="0.1">
        <action>
          Use `cat` to quietly read `.agenticguild/config.json`. If it contains `"stealth_mode": true`, remember that you are operating in stealth mode. Note `finish_branch_mode` (`stepped` when absent), `agent_git` (`suggest` when absent), and `verification` (`tdd` when absent). If the owner said "hands-off" in this request, run hands-off for this run. Do not announce any of this to the user.
          Check whether `docs/core/BEHAVIOUR_MATRIX.md` exists with `test -e`. If it does, do step 0.2; otherwise go to step 1.1.
        </action>
        <yield>[AUTO-TRANSITION TO 0.2 or TO 1.1]</yield>
      </step>
      <step id="0.2">
        <action>
          Classify each in-scope row of the behaviour matrix for the feature(s) in the active session and the branch diff: `automated` (a test path exists), `manual-only` (an explicit reason is documented), `planned` (no test and not manual-only: a gap), or `n/a` (excluded with a rationale). Report the counts and list every `planned` row. If there are none, go to step 1.1.
        </action>
        <yield>[PAUSE - QUESTION: for each planned row, write the test now, mark it manual-only with a reason, or defer it with a note. Reply with one resolution per row. Until every row has one, the review does not start.]</yield>
      </step>
    </phase>

    <phase id="1" name="Code Review">
      <step id="1.1">
        <action>Use the `view_file` tool to read and follow `.cursor/skills/code-review/SKILL.md`. Execute the full skill, including its own stops, until the owner replies `CONTINUE` (clean, or with remaining findings explicitly named and accepted) or `STOP`. On `STOP`, end finish-branch. In hands-off mode, continue to 2.1 after `CONTINUE` without an extra pause.</action>
        <yield>[PAUSE - NESTED: code review, handled by its own skill. In stepped mode, after `CONTINUE` go to 1.2.]</yield>
      </step>
      <step id="1.2">
        <action>Confirm the code review is closed and name any findings left unfixed.</action>
        <yield>[PAUSE - DECISION: code review is closed. `CONTINUE` runs the compliance audit; `STOP` ends finish-branch.]</yield>
      </step>
    </phase>

    <phase id="2" name="Compliance Audit and Full Check">
      <step id="2.1">
        <action>
          Use the `view_file` tool to read and follow `.cursor/skills/audit-compliance/SKILL.md`. Execute the full skill, including its own stops, until the owner replies `CONTINUE` (clean, or with remaining findings explicitly named and accepted) or `STOP`. The audit covers complexity and function length, test traceability (skipped in Stealth Mode and under `verification: human-review`), and domain primitives (CbC), as defined by `docs/core/deterministic_coding_standards.md`. On `STOP`, end finish-branch.
        </action>
        <yield>[PAUSE - NESTED: compliance audit, handled by its own skill. In stepped mode, after `CONTINUE` go to 2.2; in hands-off mode, after `CONTINUE` go to 2.3.]</yield>
      </step>
      <step id="2.2">
        <action>Confirm the compliance audit is closed and name any findings left unfixed.</action>
        <yield>[PAUSE - DECISION: compliance audit is closed. `CONTINUE` runs the full check before the Draft PR; `STOP` ends finish-branch.]</yield>
      </step>
      <step id="2.3">
        <action>
          Gate: the code review and the compliance audit must both have closed with `CONTINUE`. If one ended with `STOP` or has not run, do not proceed: name the outstanding check and ask whether to run it now.
          Full check before the Draft PR: run the project's full test and check suite now (and any quality or check commands listed in `docs/ai/code_review_prompt.md`), so failures are fixed locally before the Draft opens. Under `verification: human-review`, run only documented linters and checks, or note that none exist.
          - `agent_git: cloud` or hands-off: run it yourself and report what ran (claim "passed" only for commands you actually ran). If anything fails, fix it, log the fix in `.agenticguild/review_ledger.md` if applicable, commit, and re-run until it passes. In hands-off mode, if a failure persists after an honest fix attempt, stop and report the failing output. Once green, go to 2.4.
          - `agent_git: suggest` or `commit` outside hands-off: ask the owner to run the full check and report the result. Do not claim it passed and do not prompt for the Draft yet. A green report moves on to 2.4; a failure is fixed with the owner (log it, commit or suggest the commit message, and ask for a re-run).
        </action>
        <yield>
          `cloud` or hands-off, green: [AUTO-TRANSITION TO 2.4].
          `cloud` or hands-off, still failing after an honest fix attempt: [PAUSE - RESULT: the full check still fails. Reply with guidance for the next fix attempt, or ACCEPT to proceed with this failure recorded.]
          `suggest` or `commit` outside hands-off: [PAUSE - RESULT: please run the full check and report the result. Reply with green once it passes, or paste the failing output.]
        </yield>
      </step>
    </phase>

    <phase id="2.4" name="Draft PR">
      <step id="2.4.1">
        <action>
          Gate: the full check is accepted when it passed (green by the agent in `cloud` or hands-off, or confirmed green by the owner) or when the owner replied `ACCEPT` to a failing result. This is the only definition of "accepted"; directive 9, step 3.2, and this step all use it. If it is not accepted, do not continue.
          Make sure the work is committed and pushed first, within the git rules (PUSH TIMING: pushes are allowed before the Draft exists):
          - `suggest` mode outside hands-off: output the git commit and push commands as a plain-text code block for the owner to run.
          - `commit` mode outside hands-off: commit any uncommitted changes and ask the owner to push.
          - `cloud` mode or hands-off: commit any uncommitted changes, run `git pull --rebase` if hands-off, and push.
          If a PR already exists for this branch, use it. Otherwise open a Draft PR (never a ready PR):
          - `suggest` or `commit` mode outside hands-off, or no PR tool available: give the owner the PR description from `.cursor/skills/pr-description/SKILL.md` (the filled PR template) to paste, and ask them to open the Draft.
          - `agent_git: cloud` outside hands-off with a PR tool: ask whether to open the Draft now. On yes, create a Draft with the PR tool, using the filled PR template as the body.
          - Hands-off with a PR tool: create the Draft with the PR tool, using the filled PR template as the body.
          If QA ran and the session holds a staged `## QA reviewer record` not yet marked as posted: post it once on the Draft (manual mode: give the owner the text), then mark it posted in the session with a targeted edit. Never repost one already marked posted.
          Update `.agenticguild/current_state.md` with a targeted edit to indicate waiting for remote review (keep `<active_task_pointer>` unchanged).
        </action>
        <yield>
          `cloud` mode outside hands-off, after asking: [PAUSE - QUESTION: open the Draft PR now? yes or no. `no` ends finish-branch without a PR.]
          `suggest`, `commit`, or no PR tool: [PAUSE - RESULT: tell me when the Draft is open (its link is enough), or paste any remote review findings or CI errors now.] A confirmation that it is open moves on to step 3.1; pasted findings go to step 3.2.
          Hands-off or after the Draft is created: [AUTO-TRANSITION TO 3.1].
        </yield>
      </step>
    </phase>

    <phase id="3" name="Remote Review Loop">
      <step id="3.1">
        <action>
          Tell the owner the Draft is waiting for the remote review (the remote reviewer reviews the Draft once, automatically; CI checks normally run only after the PR is marked Ready, unless the repo runs CI on drafts). Ask for any remote review findings or CI errors, or a clear status.
        </action>
        <yield>[PAUSE - RESULT: remote review status. Paste findings or CI errors, or reply clear if there are none.]</yield>
      </step>
      <step id="3.2">
        <action>
          Read the reply by its pause kind (RESULT above), then:
          - Findings or CI errors pasted (FIX-FINDINGS): analyze them, fix the real issues (ignore noise and false positives after a brief note), and for EACH fixed issue silently append an entry to `.agenticguild/review_ledger.md` (check with `test -e`; create if missing; never overwrite): **Source** ("CI check" or "Remote review"), **Issue**, **Diagnosis/Why it failed**, **Outcome** (fixed), **Fix**. Run the project's checks (claim "verified" only for commands you ran), commit, and push if the git rules allow it (PUSH TIMING). If the fixes change user-visible behavior, update `CHANGELOG.md` and the PR description as needed (not in Stealth Mode). Mention that a manual re-run of the remote reviewer is worthwhile now because code changed (never post it yourself). Then return to step 3.1.
          - Clear (remote review clear): if no code changed since the accepted full check of step 2.4.1, skip any re-run and go to CLEAR. If code changed since then, run the full check again: in `cloud` mode or hands-off, run it yourself; a failure is fixed (logged with Source "Full check", committed, pushed per PUSH TIMING) and re-run, and a failure that persists after an honest fix attempt stops with the failing output in a RESULT pause (ACCEPT or guidance). In `suggest` or `commit` mode outside hands-off, ask the owner to run it and report, and wait in a RESULT pause. A passing or accepted re-run goes to CLEAR; a fix made here does not send the flow back to the remote review.
          - CLEAR: tell the owner the remote review is clear and that we are ready for the final docs and archive steps. If code changed after the remote review, mention that a manual re-run of the remote reviewer is worthwhile if they want one; you will not post it and will not wait for it.
          - STOP: end finish-branch without further changes.
        </action>
        <yield>
          CLEAR in stepped mode: [PAUSE - DECISION: remote review is clear. `CONTINUE` moves to the docs and archive steps; `STOP` ends finish-branch.]
          CLEAR in hands-off mode: [AUTO-TRANSITION TO 4.1].
          Findings fixed: [PAUSE - RESULT: remote review status, as in step 3.1].
        </yield>
      </step>
    </phase>

    <phase id="4" name="Harvest, Docs & Close-out">
      <step id="4.1">
        <action>
          If NOT in Stealth Mode: Use the `view_file` tool to read and follow `.cursor/skills/harvest-rules/SKILL.md`, including its own stops (`APPLY`, `CONTINUE`, or `STOP`). If the owner replies `STOP`, end finish-branch without clearing the active task or the ledger. Harvest runs before the docs so that the docs step can skip rules harvest just wrote.
          If in Stealth Mode: Skip `harvest-rules` entirely and go to step 4.2.
        </action>
        <yield>[PAUSE - NESTED: harvest, handled by its own skill. After `CONTINUE`, go to 4.2.]</yield>
      </step>
      <step id="4.2">
        <action>
          If NOT in Stealth Mode: Use the `view_file` tool to read and follow `.cursor/skills/sync-docs/SKILL.md` until it yields. It analyzes the branch diff and the session and updates any docs that need changes.
          If in Stealth Mode: Skip `sync-docs` entirely.
        </action>
        <yield>[PAUSE - DECISION: docs are synced. `CONTINUE` moves on; `STOP` ends finish-branch.]</yield>
      </step>
      <step id="4.3">
        <action>
          If NOT in Stealth Mode: ensure `CHANGELOG.md` is updated if user-facing changes exist. Read `<roadmap_item>` from the active session with `cat`. If this branch completes a roadmap item, update `docs/ROADMAP.md`: move the item to Done and add today's date. If it is unclear which item (if any), ask.
          If in Stealth Mode: do not modify or remind about `CHANGELOG.md` or `docs/ROADMAP.md`.
          Then use the `view_file` tool to read and follow `.cursor/skills/pr-description/SKILL.md` until it yields. The filled PR template is the PR body: update the Draft PR body with the final text (with the PR tool in `cloud` mode or hands-off; otherwise give the owner the text to paste).
        </action>
        <yield>[PAUSE - QUESTION: confirm the PR text and the roadmap item. Answers: yes, the name of a roadmap item, or none.]</yield>
      </step>
      <step id="4.4">
        <action>
          Tell the owner the branch is finished. If NOT in Stealth Mode, say task knowledge was synced to the docs (harvest-rules and sync-docs). If in Stealth Mode, say the PR is ready and that sync-docs and harvest-rules were intentionally skipped.
        </action>
        <yield>[PAUSE - QUESTION: clear the active task from memory and archive its session file to `.agenticguild/completed_sessions/`? yes or no.]</yield>
      </step>
      <step id="4.5">
        <action>
          On yes: Use `cat` to read `.agenticguild/current_state.md` for `<active_task_pointer>`. If it names a session file: create `.agenticguild/completed_sessions/` if missing, MOVE the session file from `.agenticguild/active_sessions/` to `.agenticguild/completed_sessions/` with a date suffix (e.g. `task_foo_YYYY-MM-DD.md`), never overwrite an archived file, then set `<active_task_pointer>` to `[NONE]` and `<execution_context>` to `<active_skill>[NONE]</active_skill>`, `<current_phase>[NONE]</current_phase>`, `<current_step>[NONE]</current_step>` with a targeted edit. If the pointer was already `[NONE]` or the file is missing, just set current_state to `[NONE]`. Confirm to the owner.
          On no: make no changes; the session stays in `active_sessions/` and they can clear it later.
        </action>
        <yield>[AUTO-TRANSITION TO 4.6]</yield>
      </step>
      <step id="4.6">
        <action>
          Close-out. Make one final commit of any uncommitted harvest, docs, and archive changes (allowed in `commit` and `cloud` modes and in hands-off; in `suggest` mode output a suggested commit message instead). If the git rules allow pushing (`cloud` mode or hands-off), push once, as the last push (in hands-off, `git pull --rebase` first). Then remind the owner to mark the PR Ready for review so the final CI check runs. Do not suggest re-running the remote reviewer after docs-only changes. Never mark the PR Ready yourself and never merge.
        </action>
        <yield>[END - FINISH-BRANCH COMPLETE. Later messages are new requests.]</yield>
      </step>
    </phase>
  </workflow>
</agentic_guild_skill>
