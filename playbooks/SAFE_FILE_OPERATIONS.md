# Safe File Operations

This document is read by every agentic:guild skill before it writes, moves, or deletes a file. It applies while a skill is running. It does not apply once the owner has been released from the process (see the explore-first warning in `start-task`) or to edits made outside a skill.

The goal is simple: **a skill must never destroy work that cannot be recovered.** Work in `.agenticguild/active_sessions/` (especially explore sessions) is the most valuable and the most protected.

## The rules

1. **Never remove, overwrite, truncate, or recreate an existing file without the user's explicit confirmation in chat.** Say exactly what would be lost before asking.
2. **Change files only with targeted edits.** Replace a specific span of text, or append. Never rewrite a whole file to change part of it. Session files (`.agenticguild/active_sessions/*` and `.agenticguild/completed_sessions/*`) are the most protected.
3. **Check whether a file exists with the shell, never with a search or read tool alone.** Search and read tools that respect `.gitignore` cannot see ignored files and will report them missing. Use the recipes below. A "not found" from a search or read tool is inconclusive.
4. **If an editing tool cannot reach a file, edit it through the shell with a targeted method** (append with `>>`, or an exact-match replacement that fails if the text is not found). Never fall back to delete-and-recreate.
5. **"Clear", "reset", and "discard" mean move or archive, not delete.** The only deletions allowed are scratch paths the skill created itself in this run (for example `.agenticguild/tmp_update`, and older backups replaced by a newer backup of the same file).
6. **Do not rewrite `.gitignore`, `.git/info/exclude`, the pre-commit hook, or `.cursorrules`.** Append new lines or blocks, or do an exact-match replacement that the user confirmed after seeing the exact lines.
7. **If an operation fails, or the state of a file is unclear, stop and ask.** Do not retry with a destructive operation.

## Recipes for files that search tools cannot see

| Question | Command |
|:---------|:--------|
| Does the file exist? | `test -e PATH && echo exists \|\| echo missing` |
| What does it contain? | `cat PATH` |
| Is it tracked by git? | `git ls-files --error-unmatch PATH` (exit code 0 means tracked) |
| Is it ignored, and by which rule? | `git check-ignore -v PATH` |
| Does it have uncommitted changes? | `git diff --quiet -- PATH` (exit code 0 means no changes) |

## Backups

Before any operation that could make existing content unrecoverable (see the list below), and only after the user has confirmed it:

1. Skip the backup if the file is **tracked and has no uncommitted changes**. Git is the backup.
2. Otherwise copy the file to `.agenticguild/backups/<path with each / replaced by _>.bak`. Keep **one backup per file**; the next backup of the same file replaces it.
3. Tell the user the path of the backup.

Appending to a file and inserting new text do not need a backup.

## Operations that can destroy content

Phrase decisions by effect: any operation that could make existing content unrecoverable needs the confirmation and the backup above. Examples:

| Type | Examples |
|:-----|:---------|
| Whole-file write over an existing file | a write tool, `>` redirect, `tee`, `cp` or `mv` onto an existing path, `curl` output onto an existing file, `open(path, 'w')` |
| Truncation | `: > file`, `truncate` |
| Deletion | `rm`, `rm -rf`, `find -delete`, delete tools, `git clean`, `git rm` |
| Edits that remove or replace text | any targeted edit where old text goes away (pure appends and insertions are safe) |
| Directory overwrites | `cp -r`, archive extraction, `mv` into an existing directory |
| Git commands that discard changes | `git reset --hard`, `git checkout -- PATH`, `git restore`, `git stash drop` |
