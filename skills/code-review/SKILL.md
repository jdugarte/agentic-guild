<agentcore_skill>
  <skill_definition>
    <name>code-review</name>
    <description>Triggers a strict self-review of current project code changes. Uses the project's specific docs/ai/code_review_prompt.md.</description>
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
    <phase id="1" name="Audit Execution">
      <step id="1.1">
        <action>
          Read `docs/ai/code_review_prompt.md`.
          Analyze the `git diff` of the current branch against `main`.
          Format your output using strict hierarchical numbering (e.g., 1. Architecture, 1.1 Extract Service Object, 1.2 Fix N+1 Query, 2. Type Safety, 2.1 Add return type).
        </action>
        <yield>
          [PAUSE - AWAIT USER COMMAND]
          Ask the user: "Reply with the comma-separated numbers of the fixes you want me to apply (e.g., '1.2, 2.1'), reply 'ALL' to implement everything, or 'SKIP' to ignore."
        </yield>
      </step>
    </phase>

    <phase id="2" name="Implementation">
      <step id="2.1">
        <action>
          Parse the user's numeric selection.
          Implement only the requested fixes.
          Run the local test suite and linter.
        </action>
        <yield>[PAUSE - AWAIT COMMAND TO RE-REVIEW OR EXIT]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
