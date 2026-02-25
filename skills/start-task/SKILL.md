<agentcore_skill>
  <skill_definition>
    <name>start-task</name>
    <description>Initiates the process of building a new feature, bugfix, refactor, or chore. Enforces strict QA discovery, implementation planning, and TDD.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
    3. Always end your response by explicitly stating the current step and telling the user what commands they can use to proceed.
  </state_machine_directives>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, abort the skill and point the user to `docs/ai/EXPECTED_PROJECT_STRUCTURE.md`. Do NOT hallucinate their contents.</action>
  </pre_flight>

  <workflow>
    <phase id="1" name="Context Initialization">
      <step id="1.1">
        <action>
          Ask the user to classify the task: (1) Feature, (2) Bugfix, (3) Refactor, or (4) Chore.
          Ask for a brief description of the goal.
        </action>
        <yield>[PAUSE - AWAIT USER CLASSIFICATION]</yield>
      </step>
    </phase>

    <phase id="2" name="Memory Update & Planning">
      <step id="2.1">
        <action>
          Silently create a new session file in `.agentcore/active_sessions/` named `task_[name].md`.
          Silently update `.agentcore/current_state.md` to point to this new file.
          Write the task classification and description into the session file.
          Next, draft the step-by-step implementation plan directly inside the `<implementation_plan>` block of the newly created `task_[name].md` file.
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
          Tag the test with the appropriate [REQ-ID] from `docs/core/SPEC.md`.
        </action>
        <yield>[PAUSE - AWAIT TEST APPROVAL]</yield>
      </step>
      <step id="3.2">
        <action>
          Write the minimum application code required to make the failing test pass.
          Ensure you do not violate `docs/core/SYSTEM_ARCHITECTURE.md`.
          Run the project's linters/checkers.
        </action>
        <yield>[PAUSE - AWAIT COMMAND TO PROCEED TO NEXT TDD STEP OR FINISH]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
