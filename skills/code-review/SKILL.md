<agentcore_skill>
  <skill_definition>
    <name>code-review</name>
    <description>Triggers a strict self-review of current project code changes, implementing a continuous review-fix-commit loop until perfect.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
    3. CYCLIC EXECUTION: If a step explicitly instructs you to loop back to a previous phase, you must update your state and execute that target step in the NEXT response.
  </state_machine_directives>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/ai/code_review_prompt.md` exists.</check>
    <action>If they are missing, abort the skill, inform the user, and explicitly ask: "Do you want me to initialize the missing files using the templates?" If the user says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without user confirmation.</action>
  </pre_flight>

  <workflow>
    <phase id="1" name="Audit Execution">
      <step id="1.1">
        <action>
          Read `docs/ai/code_review_prompt.md`.
          Analyze the `git diff` of the current branch against the default branch (e.g. `main`). Use the repository's default branch unless the project uses a different convention.
          Format your output using strict hierarchical numbering (e.g., 1. Architecture, 1.1 Extract Service Object, 1.2 Fix N+1 Query, 2. Type Safety, 2.1 Add return type).
        </action>
        <yield>
          [PAUSE - AWAIT USER COMMAND]
          Ask the user: "Reply with the comma-separated numbers of the fixes you want me to apply (e.g., '1.2, 2.1'), reply 'ALL' to implement everything, or 'SKIP' to ignore."
        </yield>
      </step>
    </phase>

    <phase id="2" name="Implementation & Verification Loop">
      <step id="2.1">
        <action>
          Parse the user's numeric selection.
          Implement only the requested fixes.
          Run the local test suite and linter. If `docs/ai/code_review_prompt.md` exists, run the commands it specifies (e.g. Quality or Pre-Flight section).
        </action>
        <yield>
          [PAUSE - AWAIT COMMAND]
          Ask the user to review the applied changes and commit them locally if satisfied.
          Offer two explicit commands:
          1. "Reply 'RE-REVIEW' to loop back to Phase 1, Step 1.1 and scan the new commits for remaining issues."
          2. "Reply 'DONE' to exit the code review skill."
        </yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
