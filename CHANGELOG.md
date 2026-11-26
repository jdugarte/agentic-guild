# Changelog

All notable changes to agentic:guild are listed here. The "What's New" summary shown by the
`update-agentic-guild` skill is built from the newest section of this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow
[Semantic Versioning](https://semver.org/): the `version` in `package.json` must match the newest
section here.

## [Unreleased]

## [1.1.0] - 2026-11-25

### Added

- **Settings in `.agenticguild/config.json`:** `agent_git` (suggest, commit, or cloud), `verification`
  (tdd or human-review), `start_task_mode` and `finish_branch_mode` (stepped or hands-off),
  `track_memory`, and `stealth_mode`.
- **Hands-off runs:** say "start task hands-off" or "finish branch hands-off" (or set the mode) to
  run without pausing between steps. Hard stops still wait for you.
- **`qa` skill:** an opt-in QA pass that builds a test matrix from the plan, runs it using your
  project's own `docs/ai/qa_profile.md`, and stages a paste-ready reviewer record.
- **Safe file operations:** one shared rule (`docs/ai/SAFE_FILE_OPERATIONS.md`) that every skill
  points to, plus a check in `scripts/check.sh` that fails if a skill loses the pointer.
- **Review ledger:** every fixed finding is logged automatically (source, issue, diagnosis,
  outcome, fix) for `harvest-rules`.
- **`CHANGELOG.md`** (this file).

### Changed

- **`explore-task`** is the place where the spec and the whole implementation plan are locked,
  one decision at a time in plain language. `start-task` no longer drafts a plan.
- **`start-task`** keeps a step lock, commits with `Step N:` subjects, warns once when there is
  no explored plan, and ends with the full test suite, one QA question, and an invitation to
  start `finish-branch` (never started automatically).
- **`finish-branch`** now opens the Draft PR only after the code review and the compliance audit
  are clean or accepted, loops on the CI check and remote review, then harvests rules, syncs docs,
  updates the PR text, and archives the task. It delegates the audit to `audit-compliance`.
- **`code-review` and `audit-compliance`** stop at every report with the same reply words
  (`FIX`, `ACCEPT`, `APPLY`, `CONTINUE`, `STOP`), review the whole branch on every pass, and
  report only the checks they actually ran.
- **`harvest-rules`** keeps only rules that pass four tests and moves the ledger only after it
  finishes. **`sync-docs`** shows an impact table. **`pr-description`** fills your PR template.
- **`sync.sh` and `update-agentic-guild`** never overwrite an existing file, write config only
  when it is missing, and handle `.gitignore` by appending, not rewriting.
- **Git behaviour:** by default the agent suggests git commands; `commit` and `cloud` modes let it
  commit or push. Merging, force-pushing, marking a PR Ready, and pushing to the default branch
  stay forbidden in every mode.
- **Docs:** the workflow playbook, README, and project structure guide list every skill and setting.

### Fixed

- The new-version notice in `start-task`, `explore-task`, and `status-check` now appears only when
  the upstream version is higher than the installed one.
- `update-agentic-guild` reads the changelog only when it exists and always cleans up its
  temporary files, and it no longer creates a hardcoded list of skill folders.
- The workflow playbook no longer claims the agent never commits, and its skills index now lists
  `explore-task`, `hello`, `update-agentic-guild`, and `qa`.

## [1.0.0] - 2026-11-18

First tracked release. It covers everything built since the project started on 2026-02-19.

### Highlights

- **A process your AI agent has to follow.** `explore-task` → `start-task` → `finish-branch`,
  with hard stops where a human must approve before the agent moves on.
- **A memory that survives long conversations.** A local `.agenticguild/` folder tracks the active
  task, the plan, and the current step, so "Resume Task" picks up where you left off.
- **Engineering rules that grow with your project.** `harvest-rules` turns what you actually built
  into proposed additions to your architecture docs and `.cursorrules`.
- **Safe to try on someone else's repo.** Stealth Mode keeps agentic:guild out of the team's
  tracked files.

### Added

- **Task workflow skills:** `start-task` (planning plus test-first execution), `explore-task`
  (a whiteboard for requirements and design before any code is written), and `finish-branch`
  (review, compliance audit, CI loop, docs, PR).
- **Review and compliance skills:** `code-review` with a numbered review-fix loop,
  `audit-compliance` (independent check against your coding standards),
  `harvest-rules`, `sync-docs`, and `pr-description`.
- **Roadmap skills:** `roadmap-manage` and `roadmap-consult`, plus a `ROADMAP.md` template.
- **`status-check`** to see where a task stands and what is blocking it.
- **`process-feedback`:** paste CI logs or reviewer comments; the agent fixes them, records what
  went wrong in a review ledger, and resumes the previous task.
- **`update-agentic-guild`:** updates an installed project from this repo, merging changes instead
  of overwriting local edits. `playbooks/SYNC_REGISTRY.md` is the single list of what gets synced.
- **`hello`:** introduces agentic:guild to new users and checks that the core docs exist.
  Triggered by "Who are you?" or "What is agentic:guild?".
- **Correct-by-Construction (CbC):** domain concepts become Value Objects or Branded Types
  instead of raw strings and numbers, enforced in `explore-task`, `start-task`, and
  `audit-compliance`, with a generation prompt template.
- **Stealth Mode:** `sync.sh --stealth` installs agentic:guild without touching tracked files
  (uses `.git/info/exclude`), skips docs, hooks, and `[REQ-ID]` tags that an external team
  would not want.
- **Project templates:** Rails, Django, and React Native code-review prompts and rules; core
  docs (architecture, spec, data flow, coding standards, testing matrix); PR template.
- **`no-computer-use` rule template** that stops agents from launching browser or desktop
  subagents or switching models, with headless-test guidance for Rails, Flutter, web, and
  React Native.
- **Git pre-commit hook** that guards agentic:guild state files.
- **CI check** (ShellCheck on the shell scripts).

### Changed

- **Intent routing:** the rules block maps plain requests ("review my changes", "where are we")
  to the right skill, and catches unstructured prompts like "build a login page".
- **Conversational tone:** skills talk like a teammate and read free-form answers instead of
  requiring exact words.
- **Active task pointer:** `.agenticguild/current_state.md` names the active session, so the
  task is clear across IDEs and chats. Finishing a branch archives the session.
- **Session to docs:** `sync-docs` now reads the active task session, not only the diff, and
  places domain knowledge and decisions in the right docs.
- **Test-first enforcement** in `start-task`, including plan validation rules for bugfix,
  refactor, and feature tasks.
- **Project renamed** from AgentCore to agentic:guild. Existing installs are detected so
  rules are not duplicated.
- **README rewritten** with the project's philosophy and workflow.

### Fixed

- Agents now use structured file tools instead of guessing at file contents.
- Several skill loops and plan-approval edge cases (tweaks, rejections, "start over") in
  `start-task` and `explore-task`.
- `sync-docs` no longer prompts for `harvest-rules` itself; the two skills stay separate.
- A Flutter QA note in the `no-computer-use` rule: Flutter QA on the cloud VM uses headless
  widget tests; simulator tests stay owner-local manual checks.

### Milestones

| Date | What landed |
|:-----|:------------|
| 2026-02-19 | Project starts: first skills, Rails and React Native templates, `sync.sh` |
| 2026-02-20 | Django template, PR title in PR descriptions, "never commit or push" rule, project structure guide, workflow playbook |
| 2026-02-21 | PR template, missing core docs copied from templates, localization proposal |
| 2026-02-22 | Deterministic coding standards, review-fix loop, CI/Bugbot feedback loop |
| 2026-02-23 | "v2": core doc templates, memory scaffold, `start-task` replaces `start-feature`, `sync.sh` rewrite |
| 2026-02-24 | Intent routing in the rules block |
| 2026-02-25 | Roadmap skills, `sync-docs` covers all docs, explicit schema path, PR template and CI check (#1) |
| 2026-02-26 | Conversational tone (#2), living memory and `explore-task` (#3), structured file tools (#4) |
| 2026-03-02 | `update-agentic-guild` and `SYNC_REGISTRY` (#5), `process-feedback` (#8) |
| 2026-03-03 | Better routing for explore and start (#9), finish-branch loop (#10), CbC (#11), README (#12), rename (#13) |
| 2026-03-05 | Active task pointer, session to docs, archive on finish (#14) |
| 2026-03-06 | `hello` and update notice (#15), Stealth Mode and "What's New" (#16) |
| 2026-11-17 | `no-computer-use` rule template (#19) |
| 2026-11-18 | Flutter headless-test clarification (#20) |
