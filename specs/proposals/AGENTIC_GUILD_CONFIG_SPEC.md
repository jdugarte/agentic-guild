# Proposal: agentic:guild Configuration (agentic_guild.yml)

**Status**: Draft / Future Feature  
**Goal**: Document configuration options, evaluate a central config file, and guide future implementation.

---

## 1. Current Configuration Approach

Configuration is scattered across several places:

| Location | Options | Used By |
|----------|---------|---------|
| `.cursorrules` `<project_config>` | Schema path, Roadmap path | sync-docs, roadmap skills |
| `docs/ai/code_review_prompt.md` | Linter commands | start-task, code-review |
| `docs/ai/EXPECTED_PROJECT_STRUCTURE.md` | Docs to Sync table | sync-docs |
| Skill text | Default branch (e.g. `main`) | code-review, harvest-rules, pr-description |

**Pros**: `.cursorrules` is always loaded by Cursor; no extra config file; skills are self-documenting.  
**Cons**: No single source of truth; hard to add new options; not machine-parseable for tooling (e.g. ai-tools CLI).

---

## 2. Should We Add agentic_guild.yml?

**Recommendation**: Add it when we need more config options (e.g. Localization Bridge, custom paths) or when the ai-tools CLI needs machine-parseable config. Until then, the current approach is sufficient.

**If added**: Make it optional. Skills check `agentic_guild.yml` first, fall back to `.cursorrules` project_config, then defaults. Existing projects keep working without changes.

---

## 3. Options That Could Go in agentic_guild.yml

### 3.1 Existing / Could Be Centralized

| Option | Current Location | Default | Notes |
|--------|------------------|---------|-------|
| `schema_path` | `.cursorrules` project_config | (inferred) | Path to raw database schema |
| `roadmap_path` | `.cursorrules` project_config | `docs/ROADMAP.md` | Project roadmap file |
| `default_branch` | Skill text | `main` | Base branch for git diff operations |

### 3.2 Paths Currently Hardcoded

| Option | Hardcoded Today | Would Allow |
|--------|-----------------|-------------|
| `docs_core_path` | `docs/core/` | Projects using `docs/specs/`, `spec/` |
| `docs_ai_path` | `docs/ai/` | Custom AI docs location |
| `code_review_prompt_path` | `docs/ai/code_review_prompt.md` | Different prompt location |

### 3.3 Future / Useful Options

| Option | Purpose |
|--------|---------|
| `output_language` | Localization Bridge (e.g. `en`, `es`). See [LOCALIZATION_BRIDGE.md](./LOCALIZATION_BRIDGE.md). |
| `linter_command` | e.g. `npm run check`, `bundle exec rubocop` |
| `migration_paths` | Paths to check for schema changes (e.g. `db/`, `prisma/`) |
| `skills_enabled` | Optional list to disable specific skills |
| `remote_review_clear_phrase` | Phrase for "CI check and remote review are clear" (default `CONTINUE`; for example `CI IS GREEN`) |

---

## 4. Example agentic_guild.yml Structure

```yaml
# agentic_guild.yml (optional - projects can omit and use .cursorrules / defaults)

schema_path: db/schema.rb
roadmap_path: docs/ROADMAP.md
default_branch: main

# Optional overrides
# docs_core_path: docs/core/
# docs_ai_path: docs/ai/
# code_review_prompt_path: docs/ai/code_review_prompt.md

# Future
# output_language: en
# linter_command: npm run check
# migration_paths: [db/, prisma/]
```

---

## 5. Implementation Notes

- **Location**: `agentic_guild.yml` or `docs/ai/agentic_guild.yml` at project root (or configurable).
- **sync.sh / ai-tools**: Could create a template `agentic_guild.yml.example` on init; projects copy and customize.
- **Skills**: Add a pre-flight or early step: "If `agentic_guild.yml` exists, read it for config; else check `.cursorrules` project_config."
- **EXPECTED_PROJECT_STRUCTURE**: Document the config file and all options when implemented.

---

## 6. Related Specs

- [LOCALIZATION_BRIDGE.md](./LOCALIZATION_BRIDGE.md) – mentions `AGENT_CONFIG.json` for output language.
- [AI_TOOLS_CLI_SPEC.md](./AI_TOOLS_CLI_SPEC.md) – CLI would read config for init/status/update.
