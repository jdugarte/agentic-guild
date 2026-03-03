# AgentCore: Correct-by-Construction (CbC) & Generation Extension 🏗️

**Version:** 1.0
**Purpose:** To define the strict prompt engineering mechanisms and structural patterns required to generate zero-defect, aerospace-grade code on the first attempt.

---

## 1. The Core Philosophy: Make Invalid States Unrepresentable

In traditional AI generation, you might ask for a "User model with an age." The AI generates an integer. A traditional validation step checks if `age > 0`.
In **Correct by Construction**, you force the AI to define a domain primitive (e.g., a `ValidAge` type or value object) that *cannot* be instantiated with a negative number.

### AI Generation Rule

The AI must never use primitive types (`String`, `Integer`) for domain concepts. It must generate Value Objects (in Ruby) or Branded Types (in TypeScript) to child-proof the code.

---

## 2. Structural Prompt Engineering (The XML Matrix)

To achieve high reliability, natural language is too vague. Prompt engineering for code generation must use structural techniques, dividing prompts into multiple sections using XML-style tags to create absolute boundaries for the LLM.

### The Standard Generation Prompt Template

Every AgentCore code generation prompt MUST be wrapped in this XML structure to enforce constraints:

```xml
<context>
  </context>

<role>
  You are an expert aerospace-grade software architect. Your code must be Correct-by-Construction.
</role>

<constraints>
  1. ALL loops must have a fixed, hard-coded upper bound.
  2. NO function may exceed 60 lines of code.
  3. You MUST include at least two state assertions (Pre-condition and Post-condition) per function.
  4. Make invalid states unrepresentable using domain primitives.
</constraints>

<output_format>
  Do not explain the code. Output ONLY the raw code blocks required.
</output_format>

```

---

## 3. Advanced Generation Mechanisms

To prevent the AI from taking "shortcuts," AgentCore must implement advanced prompting techniques during the generation phase.

### A. Prompt Chaining (Multi-Step Generation)

Do not force the AI to do everything in one go. Breaking tasks into logical, manageable steps enhances the AI's ability to solve complex tasks.

* **Step 1:** "Generate the Ruby Interface / TypeScript Type Definitions based on `SPEC.md`."
* **Step 2:** "Generate the RSpec / Vitest files that test this interface."
* **Step 3:** "Generate the implementation code that satisfies the tests."

### B. Self-Consistency & Meta-Prompting

Models can generate non-deterministic outputs. Meta-prompting enables the AI to self-correct and refine its approach before showing you the result.

* **Implementation:** Inject a `<reflection>` step into your prompt.
* **Prompt Instruction:** *"Before outputting the final code, write a `<reflection>` block where you critique your own proposed code against the NASA 10 Rules of Coding. If you detect a missing assertion or a potentially unbounded loop, fix the code before your final output."*

### C. Pinning & Traceability

As you build more complex applications, you must pin your production applications to specific model snapshots (e.g., Claude 3.5 Sonnet or GPT-4o specific versions) to ensure consistent behavior over time.

---

## 4. The AgentCore "Code Generation" Playbook

To make this actionable in Cursor or your CLI, create a new skill called `generate-cbc-feature`.

### The Protocol:

1. **The "Dry Run" Context:** Whenever you start a new feature, provide the AI with the exact relevant details—the project background, the specification, and the technical constraints.
2. **Explicit Role and Workflow Guidance:** Frame the model as a software engineering agent with well-defined responsibilities.
3. **The "No-Code" Agreement:** The AI is strictly forbidden from writing functional code until it has generated the Data Types/Interfaces and the user has explicitly typed "Approved."

---

## 🚀 Next Step

To physically implement this into your IDE workflow, **would you like me to draft the exact XML-formatted `generate-cbc-feature.md` skill file that you can add to your `PROMPT_LIBRARY`?** This will act as the master template you paste into Cursor whenever you want it to write NASA-grade code.
