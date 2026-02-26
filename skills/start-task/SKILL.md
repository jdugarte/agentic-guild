<agentcore_skill>
  <skill_definition>
    <name>start-task</name>
    <description>Initiates the process of building a new feature, bugfix, refactor, or chore. Enforces strict QA discovery, implementation planning, and TDD.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
    3. Always end your response by explicitly stating the current step and telling the user what commands they can use to proceed.
    4. CYCLIC EXECUTION: You are permitted to loop backward (e.g. return to Step 3.1 from 3.3) when the workflow dictates it for TDD iteration.
  </state_machine_directives>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, abort the skill, inform the user, and explicitly ask: "Do you want me to initialize the missing files using the templates?" If the user says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without user confirmation.</action>
    <tdd_strictness>If the user prompts you to write implementation code before a failing test has been confirmed, remind them of the strict TDD routine (write failing test first, then make it pass) and ask if they want to proceed with TDD or skip.</tdd_strictness>
  </pre_flight>

  <workflow>
    <phase id="1" name="Context Initialization">
      <step id="1.1">
        <action>
          First, determine if the user's message already contains a task description (e.g. "start task add export" or "build the dashboard feature").
          - If the user provided a description: Read `docs/ROADMAP.md` if it exists. Try to infer which pending roadmap item matches. If a match is found: Ask "Did you mean [item]? Reply YES to confirm, or NO to treat as a new task." [PAUSE]. On user reply, [AUTO-TRANSITION TO 1.3]. If no match: Treat as new task and [AUTO-TRANSITION TO 1.3].
          - If the user did NOT provide a description: If `docs/ROADMAP.md` exists, list pending items and ask: "Pick one, or describe a new task." [PAUSE]. If ROADMAP does not exist: Ask for a brief description of the goal. [PAUSE].
        </action>
        <yield>
          If no roadmap match (description path): [AUTO-TRANSITION TO 1.3].
          If you asked a question ("Did you mean [item]?", "Pick one, or describe", or "Describe the goal"): [PAUSE] — user's YES/NO to "Did you mean [item]?" is handled in step 1.3.
        </yield>
      </step>
      <step id="1.2">
        <action>
          Parse the user's reply. If they picked an item from the roadmap: Set that as the task, write `<roadmap_item>` to the session metadata, infer classification (Feature/Bugfix/Refactor/Chore), and [AUTO-TRANSITION TO 2.1]. If they described something: Try to infer which pending roadmap item matches (if any). If a match is found: Ask "Did you mean [item]? Reply YES to confirm, or NO to treat as a new task." [PAUSE]. On user reply, [AUTO-TRANSITION TO 1.3]. If no match: Treat as new task and [AUTO-TRANSITION TO 1.3].
        </action>
        <yield>[PAUSE - AWAIT CONFIRMATION OF INFERENCE, OR AUTO-TRANSITION]</yield>
      </step>
      <step id="1.3">
        <action>
          If user replied YES to inference: Use that roadmap item, set `<roadmap_item>`, infer classification, and [AUTO-TRANSITION TO 2.1]. If NO or new task: The task description is already known (from 1.1 or 1.2). Ask the user to classify: (1) Feature, (2) Bugfix, (3) Refactor, or (4) Chore.
        </action>
        <yield>[PAUSE - AWAIT USER CLASSIFICATION]</yield>
      </step>
    </phase>

    <phase id="2" name="Memory Update & Planning">
      <step id="2.1">
        <action>
          Derive `[name]` as a short, kebab-case slug from the task description (e.g. `add-export`, `fix-login-bug`, `dashboard-widget`). Silently create a new session file in `.agentcore/active_sessions/` named `task_[name].md`. If the task came from the roadmap, include `<roadmap_item>` in the session metadata.
          Silently update `.agentcore/current_state.md` to point to this new file.
          Write the task classification and description into the session file.
          Next, draft the step-by-step implementation plan directly inside the `<implementation_plan>` block of the newly created `task_[name].md` file. Use `<step id="N" status="pending">[Description]</step>` format (see task_template.md).
          - If Bugfix: Step 1 MUST be "Write a failing test that reproduces the bug."
          - If Refactor: Step 1 MUST be "Run existing tests to establish a green baseline."
          - If Feature: You MUST define Pre-conditions and Post-conditions for any new core functions.
        </action>
        <yield>[PAUSE - AWAIT PLAN APPROVAL]</yield>
      </step>
    </phase>

    <phase id="3" name="Execution (Iterative TDD)">
      <step id="3.1">
        <action>
          Read the next pending step from the `<implementation_plan>` block inside the active `task_[name].md` file.
          Write the failing test for this step only.
          Tag the test with the appropriate [REQ-ID] from `docs/core/SPEC.md` (format: `REQ-[DOMAIN]-[NNN]`, e.g. `REQ-AUTH-001`; projects may customize).
        </action>
        <yield>[PAUSE - AWAIT TEST APPROVAL]</yield>
      </step>
      <step id="3.2">
        <action>
          Write the minimum application code required to make the failing test pass.
          Ensure you do not violate `docs/core/SYSTEM_ARCHITECTURE.md`.
          Run the project's linters/checkers. If `docs/ai/code_review_prompt.md` exists, read it for project-specific commands (e.g. Quality or Pre-Flight section); otherwise run the project's standard linters.
          Mark the completed step in the session file (set `status="complete"` on the step).
        </action>
        <yield>[PAUSE - AWAIT COMMAND TO PROCEED TO NEXT TDD STEP OR FINISH]</yield>
      </step>
      <step id="3.3">
        <action>
          If more steps remain in the `<implementation_plan>` with `status="pending"`, return to Step 3.1. Otherwise, announce Phase 3 complete and suggest running the `finish-branch` skill.
        </action>
        <yield>[PAUSE - PHASE 3 COMPLETE OR PROCEED TO NEXT STEP]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
