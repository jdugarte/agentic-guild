# 🧠 AgentCore: Engineering-Grade AI Development

[![Status: Active](https://img.shields.io/badge/Status-Active-success.svg)](https://github.com/jdugarte/AgentCore)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> *Stop vibe coding. Start engineering.*

> *"Code is a liability. Judgment is an asset."*

AgentCore is a meta-framework that turns your AI coding assistant into a **disciplined software engineer** — one that follows the strict practices, processes, and documentation standards we've always known mattered, but rarely enforced.

---

## The Problem With AI-Assisted Development Today

Left to their own devices, AI coding assistants are **eager completion engines**. They will:

- Jump to solutions before understanding the problem
- Silently bypass architecture boundaries they don't know about
- Forget everything you agreed on three conversations ago
- Generate code that *looks* right but violates your own rules

The result is **vibe coding** — fast, messy, inconsistent, and increasingly difficult to maintain. You get output, but not engineering.

---

## What AgentCore Does

AgentCore injects a **software engineering operating system** into your project. It gives your AI agent:

- 📋 **A process to follow** — step-by-step workflows it cannot skip or shortcut
- 🧠 **A memory** — a git-ignored local state it uses to resume tasks exactly where they left off
- 📐 **A constitution** — architecture and spec documents it must consult and obey before touching your code
- 🚦 **Hard stops** — mandatory human approval gates before any destructive or irreversible action
- 🔍 **A code review standard** — not stylistic suggestions, but numbered, actionable, engineering-grade feedback

The AI doesn't just help you type faster. It **becomes a team member with a job description**.

---

## Who Is This For?

AgentCore is for developers and technical leads who:

- Are tired of AI assistants that confidently do the wrong thing
- Want their AI to reason about architecture, not just autocomplete
- Are building something complex enough that documentation, traceability, and standards actually matter
- Want to delegate entire development tasks to an AI — with confidence the output will hold up to review

If you've ever thought *"I need this AI to follow the same rules my team follows"* — that's exactly what AgentCore is for.

---

## How It Transforms Your Workflow

### Before AgentCore
- You describe a feature, the AI codes it, you review, it breaks something, you fix it, repeat.
- Documentation drifts from reality.
- Architecture rules exist in your head, not in your project.
- Every new conversation starts from scratch.

### After AgentCore
- The AI **classifies** every task before it touches anything.
- It **writes a traceable implementation plan** you approve before the first line of code changes.
- It uses **Test-Driven Development** by default, enforced by a Correct-by-Construction gate.
- It **audits its own output** against your architectural standards before delivering it.
- It **never commits or pushes** without your explicit instruction.
- Every requirement gets a **REQ-ID traceability tag** (`REQ-AUTH-001`), creating an audit trail from spec to code.
- Your documentation **stays in sync** with your code, automatically.

---

## The Core Skills (What Your AI Can Now Do)

Once AgentCore is installed, your AI assistant gains a suite of structured, stateful workflows:

| Skill | What It Does |
|---|---|
| `start-task` | Full task lifecycle: classify → plan → TDD loop → CbC gate. Never starts coding without a plan you've approved. |
| `explore-task` | Deep discovery for new features or ambiguous work. Explores options, surfaces trade-offs, and documents findings before any commitment. |
| `finish-branch` | Runs local code review, HRE compliance audit, and prepares a structured PR — in sequence, with gates between each phase. |
| `code-review` | Project-aware static analysis that produces numbered, actionable fixes — not generic advice. |
| `audit-compliance` | An independent verification pass. Checks code determinism, REQ-ID traceability, and HRE compliance mathematically. |
| `status-check` | The GPS. Reads persistent memory to diagnose exactly where a task is blocked and fully rehydrates context. |
| `harvest-rules` | Scans Git diffs to extract new architectural patterns and maps them to living documentation. The AI learns from its own work — rules improve as the project grows. |
| `sync-docs` | Keeps SPEC, DATA_FLOW_MAP, ADRs, and schema references synchronized with every branch change. |
| `roadmap-manage` | Add, prioritize, and track features and bugs in a structured `ROADMAP.md`. |
| `pr-description` | Generates a complete, Git-history-based PR description for you to review and submit. |

### A Note on `harvest-rules`: The Self-Improving Feedback Loop

Most AI assistants operate in one direction: you give them rules, they follow (or ignore) them. AgentCore's `harvest-rules` skill closes the loop.

Here's how it works:

1. **Rules as guardrails** — Your `SYSTEM_ARCHITECTURE.md` and `.cursorrules` act as the AI's engineering conscience. Every code generation decision is made *against* these constraints.
2. **Experience as input** — After each task, `harvest-rules` scans the Git diff for patterns that emerged organically: new abstractions, solutions to recurring problems, architectural decisions that actually worked.
3. **Rules as output** — It evaluates those patterns against your existing documentation and, where they represent genuine new knowledge, proposes additions to your living standards.

The result is an AI that doesn't just *follow* your first set of rules. It **gets better at engineering** as the project matures — surfacing its own good decisions back into the standards that govern future decisions. Its capacity for architecturally sound judgment compounds over time.

---

## Getting Started

AgentCore syncs into any existing or new project in seconds.

### 1. Run the sync script from your project root

```bash
curl -s https://raw.githubusercontent.com/jdugarte/AgentCore/main/sync.sh | bash
```

The script will:
- Create a git-ignored `.agentcore/` memory directory for AI task state
- Install all skills into `.cursor/skills/`
- Initialize governance templates in `docs/core/` if they don't exist
- Inject the AgentCore rules router into your `.cursorrules`

### 2. Initialize your project's constitution

AgentCore works best when your project has two anchor documents. If they don't exist, the sync script will help you create starters:

- **`docs/core/SPEC.md`** — your domain entities, workflows, and REQ-ID definitions
- **`docs/core/SYSTEM_ARCHITECTURE.md`** — your stack, boundaries, forbidden libraries, and ADRs

These are the documents your AI will be required to consult and obey. Think of them as the rules your new engineer had to read before their first PR.

### 3. Start working with structure

Once installed, you trigger skills through your AI assistant naturally:

```
"Let's start this task"        → triggers start-task
"Let's explore this feature"   → triggers explore-task
"Let's finish this branch"     → triggers finish-branch
"What's the status?"           → triggers status-check
```

The AI handles the rest — structured, gated, auditable.

---

## The Engineering Standards AgentCore Enforces

AgentCore ships with battle-tested templates for the standards that improve code quality and maintainability:

- **Deterministic Coding Standards** — rules that eliminate ambiguity in how code behaves
- **REQ-ID Traceability** — every requirement tagged, every implementation linked (`REQ-[DOMAIN]-[NNN]`)
- **Correct-by-Construction (CbC)** — the AI self-audits generated code against all constraints before delivery
- **High-Reliability Engineering (HRE)** — engineering practices borrowed from mission-critical systems, applied to your codebase
- **Architectural Decision Records (ADRs)** — every significant architectural choice documented, with context and rationale
- **PR Governance** — PR templates that force attestation: did you update the spec? did you update the architecture doc?

---

## Stack Templates Included

AgentCore is **tech-stack-agnostic** at its core and ships with ready-to-use configurations for:

- **Ruby on Rails**
- **Django**
- **React Native**

Each template provides stack-specific `.cursorrules` and code-review prompts so the AI understands your conventions from day one.

---

## Roadmap

AgentCore is actively evolving. Upcoming work:

- [ ] **`ai-tools` Go CLI** — replace `sync.sh` with a compiled, zero-dependency binary distributed via Homebrew, with versioning and multi-project sync
- [ ] **Localization Bridge** — English rules, local-language output. Configure AI to generate specs in your team's native language while maintaining English code
- [ ] **Deep CI Integration** — move async quality gate loops directly into GitHub Actions
- [ ] **Skill Versioning** — pin your project's `.cursor/skills/` to a specific AgentCore release
- [ ] **Visual Workflow Builder** — a GUI to generate skill state-machine files without writing XML by hand
- [ ] **Central Config (`agent_core.yml`)** — per-project configuration for schema paths, default branches, and more (see [`specs/proposals/AGENT_CORE_CONFIG_SPEC.md`](specs/proposals/AGENT_CORE_CONFIG_SPEC.md))

---

## Contributing

AgentCore is built in the open. If you've built a stack-agnostic skill, improved an HRE constraint, or have a new governance template — PRs are welcome.

To contribute:
1. Read [`playbooks/AI_DEVELOPER_PROTOCOL.md`](playbooks/AI_DEVELOPER_PROTOCOL.md) to understand the philosophy
2. Read [`playbooks/EXPECTED_PROJECT_STRUCTURE.md`](playbooks/EXPECTED_PROJECT_STRUCTURE.md) to understand how the repo is organized
3. Ensure any new skills follow the `<agentcore_skill>` XML state-machine format with `[PAUSE]` gateway methodology
4. Open a PR — the `finish-branch` skill will guide you through our own review process

We are building the practices that make AI-assisted development trustworthy. Come build them with us.

---

## License

MIT — see [LICENSE](LICENSE) for details.
