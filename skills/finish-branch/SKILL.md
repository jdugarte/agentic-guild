<agentcore_skill>
  <skill_definition>
    <name>finish-branch</name>
    <description>Handles the completion of a branch, PR creation, and CI/Bot feedback loops.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
  </state_machine_directives>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, abort the skill and point the user to `docs/ai/EXPECTED_PROJECT_STRUCTURE.md`. Do NOT hallucinate their contents.</action>
  </pre_flight>

  <workflow>
    <phase id="1" name="Interactive Local Review">
      <step id="1.1">
        <action>Trigger the `code-review` skill. Wait for its completion.</action>
        <yield>[PAUSE - AWAIT CODE REVIEW COMPLETION]</yield>
      </step>
    </phase>

    <phase id="2" name="Compliance & Traceability Audit">
      <step id="2.1">
        <action>
          Read `docs/core/deterministic_coding_standards.md`.
          Analyze the branch to ensure no cyclomatic complexity or function length violations occurred.
          Scan all new tests for `[REQ-ID]` tags referencing `docs/core/SPEC.md`.
        </action>
        <yield>[PAUSE - REPORT FINDINGS. AWAIT COMMAND TO FIX OR PROCEED]</yield>
      </step>
    </phase>

    <phase id="3" name="Remote Async Review">
      <step id="3.1">
        <action>
          Instruct the user to commit, push, and wait for CI/BugBot feedback.
          Update `.agentcore/current_state.md` to indicate waiting status.
        </action>
        <yield>[PAUSE - STAY IN STEP 3.1 UNTIL USER PASTES BUGBOT FEEDBACK OR SAYS "CI IS GREEN"]</yield>
      </step>
    </phase>

    <phase id="4" name="Final Spackle & PR">
      <step id="4.1">
        <action>Trigger `sync-schema-docs` if the database was modified.</action>
        <yield>[PAUSE - AWAIT CONFIRMATION TO PROCEED]</yield>
      </step>
      <step id="4.2">
        <action>Trigger `harvest-rules` to identify new patterns.</action>
        <yield>[PAUSE - AWAIT CONFIRMATION TO PROCEED]</yield>
      </step>
      <step id="4.3">
        <action>Trigger `pr-description-clipboard`.</action>
        <yield>[PAUSE - BRANCH IS FINISHED]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
