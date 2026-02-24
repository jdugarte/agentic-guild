# AI Workflow Playbook
Date: 2026-02-20

## Core AI Commands & Skills

### 1. Start Task
**Goal**: Safely begin working on a new feature, enforcing design and discovery before coding.
**Workflow Steps**:
1. **Discovery Q&A**: Interactively gather the context of the feature from the user.
2. **Draft Implementation Plan**: Create a detailed, hierarchical `implementation_plan.md`.
3. **Architectural Shifts (ADRs)**: Flag and document significant changes.
4. **Schema Mapping**: Map any database changes.
5. **Execution**: Loop through a strict, iterative TDD process step-by-step to prevent huge code dumps.

### 2. Finish Branch
**Goal**: Safely finalize a branch before opening a PR, ensuring all tests pass and docs are up-to-date.
**Workflow Steps (Strict 8-Step Pipeline)**:
1. **Local Review**: Check uncommitted files and test status.
2. **Pre-Flight**: Run linters (RuboCop, Reek, ESLint).
3. **BugBot Loop**: Automatically fix basic issues found by linters.
4. **Test Gaps**: Identify and write tests for missing coverage.
5. **Doc Sync**: Synchronize `docs/core/SPEC.md` and update `CHANGELOG.md` if necessary.
6. **Rule Harvesting**: Find new conventions introduced in this branch and add to docs or `.cursorrules`.
7. **PR Draft**: Generate the PR description and propose the commit command. **Crucial:** The AI must NEVER auto-run the `git commit` or `git push` command without explicit user revision and approval.
8. **Merge**: Provide the user with the exact `git push` command to integrate.

### 3. Status Check
**Goal**: Understand blocking issues and re-hydrate the AI's state.
**Workflow Action**: The AI should read `implementation_plan.md`, examine the current git state, run the test suite, and identify exactly _Who_ (the developer, the AI, a specific module) is blocking progress on the feature.
