<agentcore_skill>
  <skill_definition>
    <name>status-check</name>
    <description>Rehydrates project context and acts as the GPS for AgentCore execution state.</description>
  </skill_definition>

  <state_machine_directives>
    1. NEVER generate or modify application code during this skill.
    2. Your ONLY job is diagnosis and context rehydration.
  </state_machine_directives>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, abort the skill, inform the user, and explicitly ask: "Do you want me to initialize the missing files using the templates?" If the user says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without user confirmation.</action>
    <rehydrate>If `.agentcore/` or `.agentcore/current_state.md` is missing or empty: Create the minimal structure (current_state.md, blocker_log.md, pending_refactors.md, active_sessions/), advise the user to run sync.sh for full setup, and output a minimal status report. Then [PAUSE].</rehydrate>
  </pre_flight>

  <memory_format>
    <current_state>Expected format: `<active_task_pointer>` = session filename (e.g. `task_foo.md`) or `[NONE]`; `<execution_context>` contains `<active_skill>`, `<current_phase>`, `<current_step>`.</current_state>
  </memory_format>

  <workflow>
    <phase id="1" name="State Read">
      <step id="1.1">
        <action>
          Read `.agentcore/current_state.md`, the active session file in `.agentcore/active_sessions/` (indicated by current state), the `<implementation_plan>` block inside that session file, `git status`, and `git diff` against the default branch (e.g. `main`).
          If `docs/ROADMAP.md` exists: Count Done, In Progress, Pending, Backlog for a one-line summary (e.g. "Roadmap: 3 done, 1 in progress, 5 pending").
          Output a strict Status Report:
          1. Macro Status: (e.g., Active Skill, Current Phase, Roadmap summary)
          2. Micro Status: (e.g., Current Step, active files)
          3. Blockers: (Read from `.agentcore/blocker_log.md` or failing tests)
          4. Recovery Command: (Explicitly tell the user what to type to resume, e.g., "Reply RESUME to continue Phase 2, Step 2 of finish-branch").
        </action>
        <yield>[PAUSE - AWAIT TACTICAL COMMAND OR 'RESUME']</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
