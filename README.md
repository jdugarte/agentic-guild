# 🧠 AgentCore: The AI Developer Operating System

[![Status: Active](https://img.shields.io/badge/Status-Active-success.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)]()

AgentCore is a meta-tooling framework designed to centralize, standardize, and harden AI-assisted developer workflows. 

Modern AI coding assistants (like Cursor, GitHub Copilot, or Aider) are fundamentally "eager completion engines." If left unconstrained, they hallucinate workflows, bypass architectural boundaries, and suffer from "context amnesia" during long tasks. 

AgentCore solves this by acting as a **Local Operating System** that forces AI agents to operate as strict, step-by-step state machines with transient memory and hard execution gateways.

## ✨ The Core Philosophy: Determinism Over Speed

AgentCore separates the **way we work** (SOPs) from the **tech we use** (Stack Specifics). It injects three critical layers into your local project:

1. **The Engine (XML State Machines):** Universal skills are written in strict XML. The AI is programmed to hit hard `[PAUSE]` gateways, forcing it to stop generating text and wait for human authorization before proceeding to the next step.
2. **The RAM (Transient Memory):** AgentCore initializes a git-ignored `.agentcore/` directory. The AI uses this to track active sessions, log blockers, and resume tasks precisely where it left off, surviving conversational tangents and context window limits.
3. **The Constitution (Project Governance):** Agnostic templates (`SYSTEM_ARCHITECTURE.md`, `SPEC.md`, `deterministic_coding_standards.md`) anchor the AI. `SPEC.md` defines domain entities, workflows, and the REQ-ID traceability format (`REQ-[DOMAIN]-[NNN]`, e.g. `REQ-AUTH-001`). If you ask the AI to use a forbidden library, it will reject the request and demand an Architectural Decision Record (ADR).

## 📦 What's Included

### Universal AI Skills (The Engine)
Located in `.cursor/skills/`, these tech-agnostic workflows orchestrate the development lifecycle:
* **`start-task`**: The Discovery, Planning, and TDD Loop engine. Creates session files with deterministic kebab-case names (e.g. `task_add-export.md`). Enforces Correct-by-Construction (CbC).
* **`finish-branch`**: Orchestrates local code review, High-Reliability Engineering (HRE) compliance audits, and PR preparation.
* **`code-review`**: Runs project-specific static analysis and formats actionable, numbered fixes.
* **`audit-compliance`**: An Independent Verification (IV&V) agent that mathematically checks code determinism.
* **`status-check`**: The GPS. Reads the `.agentcore/` memory folder to diagnose blockers and rehydrate context.
* **`harvest-rules`**: Scans Git diffs to extract new architectural patterns and map them to living documentation. Filters proposals against `SYSTEM_ARCHITECTURE.md` and `.cursorrules` to prevent duplication.
* **`sync-docs`**: Keeps project docs in sync with branch changes (SPEC, SCHEMA_REFERENCE, DATA_FLOW_MAP, ADRs, etc.).
* **`pr-description`**: Outputs a Git-history-based PR description in a code block for the user to copy.
* **`roadmap-manage`**: Add, prioritize, and catalog items in `docs/ROADMAP.md`.
* **`roadmap-consult`**: Read-only view of roadmap status (done, pending, priorities).

### Universal Playbooks & Templates
* **`AI_DEVELOPER_PROTOCOL.md`**: A 6-phase masterclass playbook to audit, clean, and refine documentation in any legacy project.
* **Governance Templates**: Starter files for `DATA_FLOW_MAP.md`, `ROADMAP.md`, `TESTING_STRATEGY_MATRIX.md`, and enterprise-grade coding standards. AgentCore standardizes on `ROADMAP.md` for project planning.
* **Stack Configurations**: Pre-configured `.cursorrules` and code review prompts for Rails, Django, and React Native.

## 🚀 Getting Started

You can inject the AgentCore OS into any existing or new project using the provided synchronization script.

1. Navigate to your target project's root directory.
2. Run the sync script pointing to the AgentCore repository:

    ```bash
    curl -s https://raw.githubusercontent.com/jdugarte/AgentCore/main/sync.sh | bash
    ```

3. The script will automatically:
* Build the `.agentcore/` memory scaffold and secure it in `.gitignore`.
* Download the Universal XML Skills into `.cursor/skills/`.
* Initialize missing Governance templates in `docs/core/`.
* Inject the `AGENT_CORE_RULES.md` router into your project's `.cursorrules`.
* Skills that require `SPEC.md` or `SYSTEM_ARCHITECTURE.md` will offer to initialize them (via sync.sh or minimal placeholders) if missing, instead of aborting.
4. Copy the specific stack templates (e.g., Rails, React Native) from the AgentCore repo into your project to provide the "Fuel" for the OS.

## 🗺️ Roadmap

AgentCore is actively evolving to support larger teams and deeper automation. The following features are currently in development or proposed:

* [ ] **The `ai-tools` Go CLI:** Replacing `sync.sh` with a compiled, zero-dependency Go binary distributed via Homebrew for robust versioning and multi-project synchronization.
* [ ] **Localization Bridge:** "English for Rules, Local for Output." Allowing teams to configure the AI to communicate and generate specs in their native language while maintaining English code logic.
* [ ] **Deep CI Integration:** Moving async holding patterns (like the BugBot loop) from local execution directly into GitHub Actions via API.
* [ ] **Skill Versioning:** Allowing enterprise projects to pin their `.cursor/skills/` to specific AgentCore release versions.
* [ ] **Visual Workflow Builder:** A GUI tool to generate the strict XML state-machine `SKILL.md` files without writing XML by hand.
* [ ] **Central Config (agent_core.yml):** Optional project config file for schema path, default branch, and other options. See [specs/proposals/AGENT_CORE_CONFIG_SPEC.md](specs/proposals/AGENT_CORE_CONFIG_SPEC.md).

## 🤝 Contributing

We welcome contributions! If you have developed a stack-agnostic AI skill, or have improvements to the High-Reliability Engineering (HRE) constraints, please submit a PR.

Ensure any proposed workflows strictly follow the XML state-machine format and utilize the `[PAUSE]` gateway methodology.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
