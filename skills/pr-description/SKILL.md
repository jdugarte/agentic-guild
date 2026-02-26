<agentcore_skill>
  <skill_definition>
    <name>pr-description</name>
    <description>Drafts a PR description from Git history and outputs it in a code block for the user to copy.</description>
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
    <phase id="1" name="Context & Drafting">
      <step id="1.1">
        <action>
          Run `git log main..HEAD --oneline` and `git diff main...HEAD --name-only` in the terminal to gather absolute facts. Use the default branch (e.g. `main`) unless the project uses a different convention.
          Read `.github/PULL_REQUEST_TEMPLATE.md` if it exists.
          Draft the PR description. If this PR likely completes a roadmap item (check branch name or session metadata), add a reminder: "If this closes a roadmap item, ensure `docs/ROADMAP.md` was updated (finish-branch does this) and mention it in the PR."
          Output the draft in a markdown code block directly in the chat (do not write to a file or copy to clipboard).
        </action>
        <yield>[PAUSE - PR DESCRIPTION READY. USER MAY COPY FROM CODE BLOCK. SKILL COMPLETE]</yield>
      </step>
    </phase>
  </workflow>
</agentcore_skill>
