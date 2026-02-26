# AgentCore: The Global AI Developer Protocol

This document captures the master vision for AgentCore—a framework designed to eliminate fragmentation and documentation drift in AI-enhanced development.

---

## 1. The Core Problem: Fragmentation
As developers manage multiple projects across diverse tech stacks, AI "intelligence" becomes siloed. Improvements in prompt engineering or new workflow SOPs discovered in one project don't benefit others, leading to "Playbook Drift."

## 2. The Solution: The Engine vs. Fuel Model
AgentCore separates the **way we work** (SOPs) from the **tech we use** (Stack Specifics).

### ⚙️ The Engine (Universal SOPs)
High-level workflows stored in `.cursor/skills/`. The logic of "How to start a task" is tech-agnostic and shared across all projects.

### ⛽ The Fuel (Project Rules)
Stack-specific instructions in `.cursorrules` and project documentation. This tells the Engine how to apply its universal logic to specific libraries (e.g., Rails vs. Django).

---

## 3. The Ecosystem Architecture

### 🛡️ AgentCore Repository (The Source of Truth)
The central database of wisdom.
- `/skills/`: Master versions of universal workflows.
- `/playbooks/`: Tech-agnostic developer protocols.
- `/templates/`: Starter `.cursorrules` and stack-specific prompts.
- `/specs/proposals/`: Strategic development roadmaps (e.g. [AGENT_CORE_CONFIG_SPEC.md](./AGENT_CORE_CONFIG_SPEC.md), [LOCALIZATION_BRIDGE.md](./LOCALIZATION_BRIDGE.md)).

### 🛠️ `ai-tools` CLI (The Bridge)
A system-wide utility to initialize and synchronize projects with the Global Brain.
> **Detailed Spec:** See [AI_TOOLS_CLI_SPEC.md](./AI_TOOLS_CLI_SPEC.md)

### 🔄 The Network Effect
1. **Discovery:** Improve a workflow in a **Go** project.
2. **Harvesting:** AI formalizes the new pattern.
3. **Sync:** Push the improvement back to `AgentCore`.
4. **Cross-Pollination:** Update your **Rails** project; it immediately inherits the improved logic.

---

## 4. Strategic Roadmap

### Phase 1: Foundation (Current)
- Unified PR Templates and Anti-Drift Checklists.
- Standardized `SPEC.md` and `ROADMAP.md` templates.
- Baseline `sync.sh` for multi-repo synchronization.

### Phase 2: Professionalization
- **Localization Bridge**: Support for localized communication while keeping English code logic.
- **Go-based CLI (`ai-tools`)**: Replacing `sync.sh` with a robust binary distributable via Homebrew.

### Phase 3: Intelligence & Verification
- **Automated Benchmarking**: CI-integrated validation of AI-generated code against protocols.
- **Developer Dashboard**: Aggregated project health and feature status via `status-check`.
