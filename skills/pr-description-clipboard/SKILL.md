<agentcore_skill>
  <skill_definition>
    <name>pr-description-clipboard</name>
    <description>Drafts a PR description using Git history and prepares it for copying.</description>
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
    <phase id="1" name="Context & Drafting">
      <step id="1.1">
        <action>
          Run `git log main..HEAD --oneline` and `git diff main...HEAD --name-only` in the terminal to gather absolute facts.
          Read `.github/PULL_REQUEST_TEMPLATE.md` if it exists.
          Draft the PR description to `.cursor/pr-draft.md`.
          Print the draft in the chat.
        </action>
        <yield>[PAUSE - AWAIT USER APPROVAL OF PR TEXT]</yield>
      </step>
    </phase>

    <phase id="2" name="Clipboard Execution">
      <step id="2.1">
        <action>
          Execute the OS-specific terminal command to copy the contents of `.cursor/pr-draft.md` to the user's clipboard.
        </action>
        <yield>[PAUSE - PR DRAFT COPIED. SKILL COMPLETE]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
