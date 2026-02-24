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
    <action>If they are missing, abort the skill and point the user to `docs/ai/EXPECTED_PROJECT_STRUCTURE.md`. Do NOT hallucinate their contents.</action>
  </pre_flight>

  <workflow>
    <phase id="1" name="State Read">
      <step id="1.1">
        <action>
          Read `.agentcore/current_state.md`.
          Read the active session file in `.agentcore/active_sessions/` indicated by the current state.
          Read `docs/implementation_plan.md` to see unchecked boxes.
          Read `git status` and `git diff main --name-status`.
        </action>
        <yield>[PAUSE - AUTO-TRANSITION TO 1.2]</yield>
      </step>
      <step id="1.2">
        <action>
          Output a strict Status Report:
          1. Macro Status: (e.g., Active Skill, Current Phase)
          2. Micro Status: (e.g., Current Step, active files)
          3. Blockers: (Read from `.agentcore/blocker_log.md` or failing tests)
          4. Recovery Command: (Explicitly tell the user what to type to resume, e.g., "Reply RESUME to continue Phase 2, Step 2 of finish-branch").
        </action>
        <yield>[PAUSE - AWAIT TACTICAL COMMAND OR 'RESUME']</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
