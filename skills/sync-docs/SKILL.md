<agentic_guild_skill>
  <skill_definition>
    <name>sync-docs</name>
    <description>Keeps project docs in sync with branch changes and with task memory. Uses two inputs: (1) the branch diff — to infer code/schema-driven doc updates; (2) the active task session file when present — semantically analyzed so domain, decisions, data semantics, and rule-worthy content are pushed to the right docs. Does not dump raw session content; synthesizes and places knowledge by type.</description>
  </skill_definition>

  <state_machine_directives>
    1. STEPS: Execute one `<step>` per response. A step whose `<exits kind="AUTO">` has a matching `WHEN` row continues into that row's target in the same response (it is not a pause). Rows are tried top to bottom and the first match is taken.
    2. PAUSES: Exits of kind DECISION or QUESTION are pauses. At a pause you MUST completely stop generating text and wait for the owner's reply.
    3. REPLIES: Read the owner's reply by its meaning at the pause that asked. (a) If it clearly answers a row of this step's exits table, take that row. (b) If it is an instruction for other work (for example fix another finding, or explore something else), do that work now as a side task, say what you did, then return to this same pause and ask again; the instruction does not change the flow by itself. If the work would leave this skill, do not start it here: say so and ask the owner to reply `STOP` to end this run first. (c) If you cannot tell which of these it is, say you did not understand what the owner wants, list the replies this pause accepts, and ask again. `STOP` always takes the STOP row. Never guess a reply into a row it does not fit.
    4. PAUSE PROMPT: End every response that stops at a pause with a short, conversational progress summary and the replies this pause accepts, named in plain words (for example `yes or no`, `fix 1,3`, `continue`, `stop`), and invite the owner to answer in their own words or with those.
    5. REPLY MEANINGS: continue (class CONTINUE: go on with the updates, or use the inferred schema path); skip (class SKIP: do not update the docs, or skip the schema reference; nothing is written); stop (class STOP: abort); a path or instructions (class GUIDANCE).
    6. END: Standalone, tell the owner the docs are synced or skipped (END) or the run was aborted (END-STOPPED) and stop. When invoked from `finish-branch`, return CLOSED (END) or STOPPED (END-STOPPED) to it at once, without pausing; finish-branch decides the next stop. `SKIP` ends CLOSED.
  </state_machine_directives>

  <hard_constraints>
    GIT MODES: Read `agent_git` in `.agenticguild/config.json` with `cat` (`suggest` when absent). `suggest`: never run `git commit` or `git push`; when a commit is appropriate, output a suggested message as a plain-text code block and the owner runs git. `commit`: you may run `git commit` on the current feature branch, never `git push`. `cloud`: you may run `git commit` and `git push` on the current feature branch. A hands-off run allows commit and push for that run in any mode. A run is hands-off when the owner said hands-off for it, or when the mode setting of the workflow it belongs to is hands-off: `start_task_mode` for start-task, `finish_branch_mode` for finish-branch and for every skill finish-branch runs.
    ALWAYS FORBIDDEN in every mode: `git merge`, `git push --force` (and `--force-with-lease`), amending commits that were already pushed, pushing to the default branch, `gh pr merge`, `gh pr close`, `gh pr ready`, `gh release create`, and creating a PR. The only PR you may create is the Draft PR in finish-branch step 2.5, and only as the `<who_does_what>` of that skill allows.
    SAFE FILE OPERATIONS: Never overwrite or delete an existing file without the user's explicit confirmation. Before any file write, move, or delete, read `docs/ai/SAFE_FILE_OPERATIONS.md` and follow it.
  </hard_constraints>

  <persona>
    Act as a highly experienced, composed, and helpfully collaborative pair programmer, and an approachable, reliable teammate. Communicate in a conversational, professional, and pleasant tone. Hide the technical "phases and steps" of this workflow behind natural, grounded conversation.
    When updating SPEC.md, DATA_FLOW_MAP.md, ADRs, or ANY other documentation, your writing must be exact, complete, and professional. Strip out all conversational fluff, be directly informative, and prioritize clear structure so the documents are easy to grok.
  </persona>

  <pre_flight>
    <directive>Before executing the workflow, verify the necessary context exists.</directive>
    <check>Verify `docs/core/SYSTEM_ARCHITECTURE.md` and `docs/core/SPEC.md` exist.</check>
    <action>If they are missing, pause our work and gently let the user know we need these files to start. Offer to gracefully initialize the project templates for them. If the user says yes, run sync.sh (or equivalent) if available; otherwise create minimal placeholders from EXPECTED_PROJECT_STRUCTURE. Do NOT hallucinate contents without user confirmation. If the user declines, end the skill without doing anything else (when invoked from `finish-branch`, return STOPPED).</action>
  </pre_flight>

  <session_to_docs>
    <directive>When an active session file exists, semantically analyze its full content (any structure). Classify fragments by knowledge type and map to the doc(s) below. Do not dump raw session text; synthesize and place. Session structure is free-form; analysis is semantic.</directive>
    <knowledge_type_map>
      Domain, entities, invariants, value objects, glossary → SPEC.md; optionally DATA_FLOW_MAP.md (lifecycles).
      Architectural decisions, path not taken, rejections and rationale → ADRs/.
      Stack, boundaries, "must not use X", constraints → SYSTEM_ARCHITECTURE.md, .cursorrules.
      Conventions, patterns, anti-patterns (harvest-worthy rules) → .cursorrules, docs/core/SYSTEM_ARCHITECTURE.md.
      Data semantics: why and when of data (tables, columns, entities) → SCHEMA_REFERENCE.md (enrichment; structure still from schema file).
      Testing approach, mocking strategy → TESTING_STRATEGY_MATRIX.md or project testing doc if present.
      Risks, assumptions, trade-offs → SPEC or ADRs. Open questions, future work → ROADMAP, SPEC, or ADRs.
    </knowledge_type_map>
  </session_to_docs>

  <workflow>
    <phase id="1" name="Impact Analysis">
      <step id="1.1" name="Analyze and report">
        <action>
          1. Read the git diff of the current branch against the default branch (e.g. `main`).
          2. Use the `view_file` tool to read the "Docs to Sync" table in `docs/ai/EXPECTED_PROJECT_STRUCTURE.md` (or `playbooks/EXPECTED_PROJECT_STRUCTURE.md` if the former is missing) to get the list of docs and their update conditions.
          3. Resolve and read session: Use `cat` to read `.agenticguild/current_state.md` (the file may be ignored by git and invisible to search tools) and parse `<active_task_pointer>`. If the pointer contains a session filename (e.g. `task_foo.md`) and the file exists at `.agenticguild/active_sessions/` + that filename, read the entire session file. If no pointer or file is missing, continue with diff-only.
          4. Diff-based analysis: For each doc in the table that exists in the project, determine whether the branch diff requires updates based on the condition. Build a diff-derived list: [Doc] → needs update (Yes/No) + reason.
          5. Session-based analysis: If a session file was read, semantically analyze the whole session (all sections, any structure). Classify meaningful fragments using the &lt;knowledge_type_map&gt; (domain, decisions, data semantics, conventions/patterns, testing, risks, etc.). For each classified fragment, determine which doc(s) should receive content. Build a session-derived list: [Doc] ← [knowledge type]: brief description of what to add (do not dump raw session text). Include SCHEMA_REFERENCE when the session discusses data (why/when of tables/columns). Include .cursorrules and SYSTEM_ARCHITECTURE for conventions, patterns, anti-patterns.
          6. Merge: Combine the two lists. If a doc is touched by both diff and session, mark source "both" and merge reasons. Result: one list per doc with source (diff | session | both) and reason. If `harvest-rules` already ran in this workflow (finish-branch runs it first), do not propose `.cursorrules` or SYSTEM_ARCHITECTURE additions that are semantically equivalent to the rules it just wrote.
          7. Report: Output a Markdown table with the columns `Document | Needs update? | Source | Reason` (`Yes` or `No` in the second column; `diff`, `session`, or `both` in the Source column). Ask the owner whether to continue with these updates (`CONTINUE` to proceed, `SKIP` to leave the docs unchanged).
        </action>
        <exits kind="DECISION">
          ON CONTINUE -> 2.1
          ON SKIP -> END : write nothing; the docs sync is skipped
          ON STOP -> END-STOPPED
          ON OTHER -> SAME : a request to add or drop a doc changes the table and asks again; anything else is answered briefly and asked again
        </exits>
      </step>
    </phase>

    <phase id="2" name="Schema Path Resolution">
      <step id="2.1" name="Resolve the schema path">
        <action>
          If SCHEMA_REFERENCE.md does NOT need an update, there is nothing to resolve. Otherwise: Resolve the schema file path. Use the `view_file` tool to read `.cursorrules` and look for the `&lt;project_config&gt;` block, specifically "Schema path:".
          - If filled in with a valid path: use it.
          - If not filled in: Conversationally suggest the user fill in "Schema path:" in the `&lt;project_config&gt;` block of `.cursorrules` for future runs (see `docs/ai/EXPECTED_PROJECT_STRUCTURE.md` § 5.1). Infer the schema path from common locations (e.g. `db/schema.rb`, `prisma/schema.prisma`, `db/schema.ts`). Output your inferred path.
        </action>
        <exits kind="AUTO">
          WHEN SCHEMA_REFERENCE.md needs no update, or the schema path is set in `.cursorrules` -> 3.1
          WHEN otherwise (you inferred a path, or found none) -> 2.2
        </exits>
      </step>
      <step id="2.2" name="Confirm the inferred schema path">
        <action>If you inferred a path, ask conversationally: "I inferred the schema is at [path]. Does that look right, or is there a different path we should use? We can also skip this for now." If you found no candidate, ask for the schema path or whether to skip SCHEMA_REFERENCE for now.</action>
        <exits kind="QUESTION">
          ON CONTINUE -> 3.1 : use the inferred path
          ON GUIDANCE -> 3.1 : use the path the owner gave
          ON SKIP -> 3.1 : SCHEMA_REFERENCE is skipped for this run
          ON STOP -> END-STOPPED
          ON OTHER -> SAME : answer briefly, ask again
        </exits>
      </step>
    </phase>

    <phase id="3" name="Apply Updates">
      <step id="3.1" name="Apply the updates">
        <action>
          For each doc that needs updates, apply the changes in a single batch with targeted edits (replace a specific span, or append). Use a write tool only to create a file that does not exist yet; never rewrite an existing doc whole. Use the merged list from Step 1.1 (source: diff, session, or both).
          - **SCHEMA_REFERENCE.md**: Use the schema path resolved in Phase 2 (or skip if the owner chose to skip it). Read the raw schema file and generate the structure (tables, columns, mapping to SPEC). If the session was read and contains data semantics (why and when of data, tables, columns), add those as short semantic notes in the appropriate places (e.g. per table or section). Do not replace structure with session content; enrich the generated doc with session-derived "why/when" where relevant.
          - **SPEC.md**: Update domain logic, entities, glossary, or REQ-IDs from the diff and/or session. When source is "both", merge into one coherent update (session gives domain/entities/glossary; diff may add code-implied details). Use session metadata (req_id, roadmap_item) when present. Synthesize; do not paste raw session text.
          - **DATA_FLOW_MAP.md**: Update entity lifecycles or side-effects from diff and/or session.
          - **ADRs/**: Add or update ADRs from diff and/or session (decisions, path not taken, rationale). Synthesize into concise ADR prose; do not dump raw session.
          - **SYSTEM_ARCHITECTURE.md**: Update stack, boundaries, forbidden libs, and conventions/patterns from diff and/or session. Session-derived rules (conventions, anti-patterns) go here.
          - **.cursorrules**: When session (or diff) yields conventions, patterns, or anti-patterns, add them in the appropriate project rules section. Align with harvest-rules targets.
          Output a helpful summary of what was updated and whether each came from diff, session, or both.
          Remind the user conversationally: "Just a heads up, to have more docs updated automatically, you can add them to the 'Docs to Sync' table in EXPECTED_PROJECT_STRUCTURE."
        </action>
        <exits kind="AUTO">
          WHEN otherwise -> END
        </exits>
      </step>
    </phase>
  </workflow>
</agentic_guild_skill>
