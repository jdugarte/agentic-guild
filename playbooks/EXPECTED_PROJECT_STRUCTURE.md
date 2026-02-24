# Expected Project Structure (AgentCore OS)

This document lists every referenced path, its purpose, and how it fits into the AgentCore Operating System. 

## 1. The Agent RAM (Transient Memory)
*Located in `.agentcore/` (Gitignored)*
| Path | Purpose |
|------|---------|
| `current_state.md` | Tracks the active skill, phase, and step. Used to resume tasks. |
| `blocker_log.md` | Logs CI/CD failures or missing user inputs. |
| `pending_refactors.md` | Logs tech debt discovered outside the scope of a current task. |
| `active_sessions/task_*.md` | The runtime memory for specific features/bugfixes. |

## 2. The Engine (XML Skills)
*Located in `.cursor/skills/`*
| Path | Purpose |
|------|---------|
| `start-task/SKILL.md` | Initializes planning, memory tracking, and strict TDD. |
| `finish-branch/SKILL.md` | Orchestrates the compliance audit and PR pipeline. |
| `code-review/SKILL.md` | Runs project-specific static analysis. |
| `audit-compliance/SKILL.md` | IV&V agent that mathematically checks code determinism. |
| `status-check/SKILL.md` | Reads `.agentcore/` to diagnose blockers and rehydrate context. |
| `harvest-rules/SKILL.md` | Scans diffs to update architecture docs and `.cursorrules`. |
| `sync-schema-docs/SKILL.md` | Maps DB tables to business logic in `SPEC.md`. |
| `pr-description/SKILL.md` | Generates a Git-based PR draft. |

## 3. The Constitution (Project Governance)
*Located in `docs/core/`*
| Path | Purpose |
|------|---------|
| `SYSTEM_ARCHITECTURE.md` | The absolute boundaries (Tech stack, forbidden libraries). |
| `SPEC.md` | Business logic, Domain Glossary, and [REQ-IDs]. |
| `SCHEMA_REFERENCE.md` | Auto-generated mapping of the DB to `SPEC.md`. |
| `deterministic_coding_standards.md` | The HRE mathematical constraints (Complexity, Bounds). |
| `TESTING_STRATEGY_MATRIX.md` | Rules of engagement for unit, integration, and E2E tests. |
| `DATA_FLOW_MAP.md` | Defines entity lifecycles and cascading side-effects. |
| `ADRs/` | Architectural Decision Records to bypass `SYSTEM_ARCHITECTURE.md`. |
