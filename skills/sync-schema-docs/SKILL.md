<agentcore_skill>
  <skill_definition>
    <name>sync-schema-docs</name>
    <description>Automatically maps raw database schemas to business logic in SPEC.md, generating SCHEMA_REFERENCE.md.</description>
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
    <phase id="1" name="Schema Ingestion">
      <step id="1.1">
        <action>
          Read the project's raw database schema file.
          Read `docs/core/SPEC.md` to rehydrate your understanding of the business logic.
          Map every table and column to its purpose based on `SPEC.md`.
        </action>
        <yield>
          If ANY column's purpose is ambiguous, list your questions and [PAUSE - DO NOT GENERATE DOCS UNTIL RESOLVED].
          If all columns are perfectly clear, [PAUSE - AUTO-TRANSITION TO 1.2].
        </yield>
      </step>
      <step id="1.2">
        <action>
          Generate or overwrite `docs/core/SCHEMA_REFERENCE.md` using strict Markdown tables containing the Column, Type, and Semantic Business Logic.
        </action>
        <yield>[PAUSE - AWAIT USER TO REVIEW SCHEMA. ASK IF THEY WANT TO RUN HARVEST-RULES]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
