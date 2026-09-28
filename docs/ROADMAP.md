# Project Roadmap

Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.

**Format:** Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies.

---

## Done
*(No completed items yet)*

## In Progress
*(No items currently in progress)*

## Pending (by priority)

1. [ ] Remove automatic rubocop/linter/test runs from skills — stop mid-workflow auto-runs of quality gates; leave quality checks to explicit review/CI steps unless the user asks.
2. [ ] Include uncommitted changes in code review — review the full working tree (staged + unstaged), not only committed diffs.
3. [ ] Update memory and implementation plan after each task step — during `start-task` (and related flows), persist progress to the active session and keep `<implementation_plan>` current as steps complete.
4. [ ] Multi-explore / single start-task policy — allow several explore sessions; enforce only one active `start-task` / implementation at a time (clarify pointer and handoff rules).
5. [ ] Close skill execution fidelity gaps — diagnose why agents diverge from skill instructions mid-run (context drift, relaxed constraints, forgotten hard rules) and define mitigations so instructions stay binding for the whole skill.
6. [ ] Audit token consumption in skills — measure verbosity and trim skills without losing enforceable constraints.
7. [ ] Cross-wire `.cursorrules` and code-review prompts — apply project rules during code review; apply code-review criteria during code generation.
8. [ ] Code review loops until all findings fixed — local review must loop on fixes until clean before proceeding (beyond the existing finish-branch CI loop).
9. [ ] Always suggest a commit message when executing an implementation plan — after meaningful plan progress in `start-task`, propose a commit message (same pattern as code-review).
10. [ ] Prefer yes/no questions in skills — rewrite agent questions to be answerable with yes/no whenever possible.
11. [ ] Audit `.agenticguild/review_ledger.md` usage — verify it is written at the right steps (e.g. process-feedback) and consumed/cleared correctly (e.g. harvest-rules).
12. [ ] Document the Philosophy of Compound Engineering — user-facing docs; also check whether skills need related routing or references.
13. [ ] Document how to start a project — user-facing onboarding (init → first explore/start-task); also check whether skills need related guidance or entry points.
14. [ ] Harvest skill tweaks from projects using agentic:guild — collect local skill edits across those repos, compare to canonical skills here, and fold back what improves the overall protocol.

## Backlog

- [ ] Distill `.cursorrules` and harvest-rules knowledge from existing Rails projects into this repo’s Cursor rules / stack templates (collect → compare → merge later).
- [ ] Explore uses for REQ-ID cross-references — reports, graphs, or inference over SPEC/test traceability tags.
- [ ] Stronger always-on instruction enforcement — research mechanisms so critical rules cannot be forgotten or hallucinated away across prompts (may overlap fidelity work and MCP/runtime enforcement proposals).

<!--
Dropped / deferred notes (not tracked as work):
- Reorder finish-branch so “wait for CI green” is last — rejected; Harvest Rules needs CI/runner results earlier in the flow.
- Explicit “don’t generate code” for explore-task — already present in explore-task constraints; real issue tracked under skill execution fidelity.
-->
