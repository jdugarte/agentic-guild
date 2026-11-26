# AI Workflow Playbook
Date: 2026-02-20

## Core AI Commands & Skills

### 0. Explore Task
**Goal**: Decide what to build before building it. The owner and the agent lock a specification and an implementation plan together, one decision at a time, in plain language. The result lives in the active session file (`.agenticguild/active_sessions/task_[name].md`) and is the plan `start-task` follows.

### 1. Start Task
**Goal**: Execute an explored plan safely, one step at a time, with Correct-by-Construction (CbC) discipline. If no explored plan exists, the agent warns once per conversation; if the owner chooses to continue anyway, they are released from the guild's process for that task.
**Workflow Steps**:
1. **Explore-first check**: confirm the task has an explored plan; otherwise warn and ask.
2. **Task description**: match the request to a roadmap item or classify it.
3. **Confirm the locked plan**: the plan comes from `explore-task`; `start-task` never drafts one.
4. **Type Definition Gate (Features only)**: confirm the domain types (Value Objects in Ruby, Branded Types in TypeScript) before any test is written.
5. **Execution**: for each plan step, write the failing test (with `verification: tdd`), apply the CbC constraints and the reflection gate, write the minimum implementation, run the checks, and commit with a `Step N:` subject. In `stepped` mode the agent stops after every step and names the next one; a pasted error never authorizes the next step. In `hands-off` mode it chains the steps and stops only at hard stops (a failure after an honest fix attempt, an environment block, a plan change, a product choice, a safety issue, scope creep).
6. **Closing message**: the full test suite, one QA question, and an invitation to start `finish-branch`. The agent never starts it by itself.

### 2. Finish Branch
**Goal**: Safely finalize a branch, ensuring all checks pass and docs are up to date.

Finishing a branch runs, in order: (optionally) a behaviour matrix coverage check; a code review (guided by `docs/ai/code_review_prompt.md`); a compliance and traceability audit; the Draft PR (the only point where a PR is created; never before the review and audit are clean or accepted); the remote review loop (CI check and remote review: the owner pastes failures, the agent fixes and logs them in the review ledger); rule harvest; docs sync; CHANGELOG and roadmap updates; the PR description; clearing and archiving the task; and a final commit with a reminder to mark the PR Ready. Every code-review and compliance report stops for the owner's choice (`FIX 1,3`, `FIX all`, `ACCEPT 2`, `CONTINUE`, `STOP`). In `hands-off` mode, after each choice the agent applies fixes, updates the ledger, runs the checks, commits, and re-reviews the whole branch automatically.

Git behaviour is set by `agent_git` in `.agenticguild/config.json`: `suggest` (default; the agent gives you the commands), `commit` (the agent commits, you push), or `cloud` (the agent commits and pushes). A hands-off run allows commits and pushes for that run. Merging, force-pushing, marking a PR Ready, and pushing to the default branch are always forbidden for the agent.

### 3. QA (optional)
**Goal**: Prove the product matches the plan, after implementation and before `finish-branch`. The agent runs QA only when asked. The project-owned profile `docs/ai/qa_profile.md` says how to run the product and what QA must never touch; the skill creates it through a short question-and-answer when it is missing.

### 4. Status Check
**Goal**: Understand blocking issues and re-hydrate the AI's state.
**Workflow Action**: The AI reads `.agenticguild/current_state.md`, the active session memory plan, the git state, and `docs/ROADMAP.md` (if present) to output a macro/micro status report including a roadmap summary (done, in progress, pending) and identify exactly what is blocking progress.

### Settings (`.agenticguild/config.json`)
| Key | Values (default first) | Effect |
|-----|------------------------|--------|
| `stealth_mode` | false / true | Keeps all guild files out of the repo's tracked files. |
| `track_memory` | false / true | When true, only `current_state.md`, `review_ledger.md`, and `backups/` are ignored by git. |
| `agent_git` | suggest / commit / cloud | What the agent may do with git. |
| `verification` | tdd / human-review | Failing tests first, or step-by-step review by reading the deliverable. |
| `start_task_mode` | stepped / hands-off | Whether `start-task` pauses after every step. |
| `finish_branch_mode` | stepped / hands-off | Whether `finish-branch` chains its review loops. |

### Skills Index
| Skill | Triggers | Purpose |
|-------|----------|---------|
| hello | who are you, hello, what can I do | Introduces the guild and the menu of what to do |
| explore-task | explore task, explore feature, brainstorm | Lock the spec and the implementation plan before coding |
| start-task | start task, begin task, implement feature | Execute the explored plan step by step |
| finish-branch | finish branch, open a PR, complete task | Code review, compliance audit, Draft PR, remote review loop, harvest, docs, archive |
| qa | run QA, set up QA | Opt-in QA pass using the project's QA profile |
| code-review | code review, run code review, review my changes | Project-specific static analysis and fix loop |
| status-check | status check, where are we, blocked | Rehydrate context and diagnose blockers |
| process-feedback | process feedback, fix errors, lint errors | Interrupt subroutine: fix code, log diagnosis to short-term memory, resume previous task |
| harvest-rules | harvest rules, update docs | Extract new patterns from diff, review_ledger, and task session into docs and .cursorrules |
| audit-compliance | audit compliance, run audit | IV&V audit against deterministic standards |
| sync-docs | sync docs, sync project docs | Keep docs in sync with branch diff and task session (semantic analysis → SPEC, SCHEMA_REFERENCE, ADRs, .cursorrules, etc.) |
| pr-description | PR description, draft PR | Fill the repository's PR template (or a standard outline) in a code block |
| roadmap-manage | roadmap, manage roadmap, add to roadmap | Add, prioritize, catalog roadmap items |
| roadmap-consult | roadmap status, what's pending, roadmap consult | Read-only view of done/pending/priorities |
| update-agentic-guild | update agentic guild, update agentic:guild, sync agentic guild | Update the guild's skills, rules, and templates from upstream |

## Memory & State Management (Agent RAM)

agentic:guild utilizes a hidden `.agenticguild/` folder to survive long conversations and tangents. 

* **To Resume Work:** If you get distracted by a tangent or start a new chat window, simply tell the AI: **"Resume Task"** or **"Where were we?"**. The AI will read `.agenticguild/current_state.md` and immediately pick up on the exact phase and step you left off on.
* **To Log Debt:** The AI will automatically log technical debt or blocked tasks into `.agenticguild/pending_refactors.md` and `.agenticguild/blocker_log.md` instead of forgetting them.
