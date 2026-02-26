<agentcore_skill>
  <skill_definition>
    <name>sync-docs</name>
    <description>Keeps project docs in sync with branch changes. Analyzes the diff against the docs-to-sync list, then applies all necessary updates in one batch.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER execute more than ONE <step> per response.
    2. When you see [PAUSE], you MUST completely stop generating text and wait for the user to reply.
  </state_machine_directives>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, abort the skill, inform the user, and explicitly ask: "Do you want me to initialize the missing files using the templates?" If the user says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without user confirmation.</action>
  </pre_flight>

  <workflow>
    <phase id="1" name="Impact Analysis">
      <step id="1.1">
        <action>
          Read the git diff of the current branch against the default branch (e.g. `main`).
          Read the "Docs to Sync" table in `docs/ai/EXPECTED_PROJECT_STRUCTURE.md` to get the list of docs and their update conditions.
          For each doc in the list that exists in the project: determine whether the branch changes require updates based on the condition.
          Output a report: [Doc] → [Needs update: Yes/No] + brief reason.
        </action>
        <yield>[PAUSE - AWAIT USER CONFIRMATION TO PROCEED OR SKIP]</yield>
      </step>
    </phase>

    <phase id="2" name="Schema Path Resolution">
      <step id="2.1">
        <action>
          If SCHEMA_REFERENCE.md does NOT need update: [AUTO-TRANSITION TO 3.1]. Otherwise: Resolve the schema file path. Read `.cursorrules` and look for the `&lt;project_config&gt;` block, specifically "Schema path:".
          - If filled in with a valid path: use it and [AUTO-TRANSITION TO 3.1].
          - If not filled in: Tell the user to fill in "Schema path:" in the `&lt;project_config&gt;` block of `.cursorrules` for future runs (see `docs/ai/EXPECTED_PROJECT_STRUCTURE.md` § 5.1). Infer the schema path from common locations (e.g. `db/schema.rb`, `prisma/schema.prisma`, `db/schema.ts`). Output your inferred path.
        </action>
        <yield>
          If schema path was resolved (from project_config or not needed): [AUTO-TRANSITION TO 3.1].
          If you inferred the path: [PAUSE] Ask: "I inferred the schema is at [path]. Reply YES to confirm, the correct path to use instead, or NO to skip SCHEMA_REFERENCE update for this run."
        </yield>
      </step>
      <step id="2.2">
        <action>
          Parse the user's reply from Step 2.1. If they replied YES or provided a path: use that path and proceed to 3.1. If they replied NO: note that SCHEMA_REFERENCE will be skipped for this run; proceed to 3.1.
        </action>
        <yield>[AUTO-TRANSITION TO 3.1]</yield>
      </step>
    </phase>

    <phase id="3" name="Apply Updates">
      <step id="3.1">
        <action>
          For each doc that needs updates, apply the changes in a single batch:
          - **SCHEMA_REFERENCE.md**: Use the schema path resolved in Phase 2 (or skip if user refused). Read the raw schema file, map to SPEC.md, generate/overwrite.
          - **SPEC.md**: Update domain logic, entities, glossary, or REQ-IDs as implied by the diff.
          - **DATA_FLOW_MAP.md**: Update entity lifecycles or side-effects.
          - **ADRs/**: Add or update ADRs for new architectural decisions.
          - **SYSTEM_ARCHITECTURE.md**: Update stack, boundaries, or forbidden libs.
          Output a summary of what was updated.
          Remind the user: "To have more docs updated automatically, add them to the 'Docs to Sync' table in `docs/ai/EXPECTED_PROJECT_STRUCTURE.md`."
        </action>
        <yield>[PAUSE - DOCS SYNCED. ASK IF THEY WANT TO RUN HARVEST-RULES]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
