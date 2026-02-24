# AgentCore: High-Reliability Engineering (HRE) Extension 🚀

**Version:** 1.0
**Purpose:** To upgrade AgentCore from a standard AI-assistant workflow into a deterministic, enterprise-grade software engineering protocol. This extension ensures zero-defect tolerance, strict traceability, and mathematically provable architectural compliance.

---

## 1. The Core Philosophy: Determinism Over Speed

In high-reliability engineering, software is not "written"; it is specified, generated, and mathematically verified. For AgentCore, this means shifting the AI from a "helpful coding partner" to a "strict compliance engine."

The primary directive is **Maker/Checker Isolation**: The AI persona that writes the code must never be the same persona that audits the code.

---

## 2. The Deterministic Coding Standards

Based on strict high-reliability standards, these rules enforce determinism. AI agents naturally drift toward complex, clever, or heavily abstracted code. These rules force the AI to write "boring," readable, and testable code.

### The Rules

* **Acyclomatic Simplicity:** No deeply nested logic. Maximum cyclomatic complexity of 10 per method.
* **Strict Bounding:** All loops and recursive functions must have explicit, hard-coded upper execution bounds to prevent infinite loops.
* **Memory Determinism:** Avoid dynamic memory allocation after initialization (where applicable by language).
* **Function Constraints:** Maximum 60 lines per function. Functions must fit on one printed page to ensure the AI's limited attention mechanism can parse the entire context flawlessly.
* **Assertion Density:** Minimum of two state assertions per critical function (Pre-condition and Post-condition checks).

### AI Implementation Strategy

To make the AI follow this, you cannot just tell it to "be careful." You must bind these rules to the CI/CD pipeline and the prompt parser.

* **Create `SKILL: audit-compliance`:** An Independent Verification and Validation (IV&V) state machine that forces the AI to check every changed file against `docs/core/deterministic_coding_standards.md` before allowing a branch to close.
* **XML Rule Boxing:** In your `.cursorrules`, wrap these constraints in strict XML tags. AI models are trained to prioritize XML-bounded system instructions.
```xml
<hre_compliance_rules>
  1. Reject any function over 60 lines.
  2. Inject pre-condition assertions for all data mutations.
</hre_compliance_rules>

```

---

## 3. Enterprise-Grade Artifact Mapping (IEEE/ISO)

Industry standards require specific documentation. AgentCore maps to formal IEEE 730 / ISO 12207 standards so the AI understands the *weight* of each file.

| AgentCore Artifact | IEEE/ISO Equivalent | Description & AI Implementation |
| --- | --- | --- |
| `docs/core/SPEC.md` | **SRS** (Software Requirements Specification) | The absolute truth. **AI Action:** The AI is strictly forbidden from writing code for a feature that does not possess a unique ID in this document (e.g., `REQ-AUTH-001`). |
| `docs/core/SCHEMA_REFERENCE.md` | **SADD** (Software Architecture Design Document) | Defines interfaces and state flow. **AI Action:** Used by the AI to validate database migrations before applying them. |
| `docs/core/ADRs/` | **VDD** (Version Description Document) | Explains the evolution of the system. **AI Action:** The AI must read the last 3 ADRs before proposing any new gem, library, or architectural pattern. |
| `docs/ai/TEST_PLAN.md` | **SQAP** (Software Quality Assurance Plan) | Defines how to prove the software works. **AI Action:** The AI must generate a matrix linking every `REQ-ID` to a test file. |

---

## 4. Bi-Directional Traceability (The Golden Thread)

Traceability is the hallmark of mission-critical software. If a line of code exists, it must trace back to a business requirement. If a requirement exists, it must trace forward to a test.

### The Concept

There are no "orphan" features. Every PR, every commit, and every test block must contain a reference to the specific requirement it fulfills.

### AI Implementation Strategy

* **The PR/Commit Hook:** Update the `finish-branch` skill to enforce a strict traceability audit before PR creation.
* *AI Enforcement:* If the AI attempts to close a branch without linking a `REQ-ID` from `SPEC.md`, the `audit-compliance` skill throws a hard error.
* **Test Generation Prompt:** When asking the AI to write tests via `start-task`, inject: *"You must tag each `it` block (RSpec) or `test` block (Vitest) with the `REQ-ID` it validates."*

---

## 5. Independent Verification Agent (IV&V)

In high-reliability environments, the engineer who writes the code cannot be the one who signs off on its safety.

### The Concept

You must simulate a "Red Team" or a separate QA department using AI tooling.

### AI Implementation Strategy

* **The `Auditor` Persona:** Create a completely separate XML skill called `audit-compliance`.
* **State Ignorance:** This skill must be run in a *clean context window*. It should not have access to the chat history where you and the AI brainstormed the code.
* **Execution:** 1.  The Auditor Agent is fed only the `SPEC.md` and the final code `diff`.

2. Prompt: *"You are an independent IEEE software auditor. Compare the provided code against the deterministic standards. Identify any requirements in the SRS that lack test coverage in the code."*

---

## 6. Secure Build Pipelines & Sandboxing

Critical software assumes the environment is hostile.

### AI Implementation Strategy

* **Library Paranoia:** Create a skill called `audit-dependencies`. Before the AI is allowed to add a new Gem or NPM package, it must write a micro-ADR explaining why a native Rails or standard library approach is insufficient.
* **No Auto-Execution:** The AI must never be granted permission to run raw database migrations or execute `eval` commands autonomously.
