<agentcore_skill>
  <skill_definition>
    <name>harvest-rules</name>
    <description>Analyzes branch changes to identify new architectural patterns and map them to the correct documentation files.</description>
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
    <phase id="1" name="Pattern Analysis">
      <step id="1.1">
        <action>
          Read the `git diff` of the current branch against `main`.
          Analyze the changes for new error handling, naming conventions, UI patterns, or data structures.
          Scan the `docs/` directory and `.cursorrules` to determine where these new patterns should be codified.
          Output a list of "New Rule Candidates" formatted as: `[Target File] -> [Proposed Rule Addition]`.
        </action>
        <yield>[PAUSE - WRITE LOCK ACTIVE. AWAIT USER APPROVAL OF CANDIDATES]</yield>
      </step>
    </phase>

    <phase id="2" name="Knowledge Commit">
      <step id="2.1">
        <action>
          Parse the user's approval.
          Write the approved rules directly into the corresponding target files (e.g., `.cursorrules`, `docs/core/SYSTEM_ARCHITECTURE.md`).
        </action>
        <yield>[PAUSE - RULES HARVESTED. SKILL COMPLETE]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
