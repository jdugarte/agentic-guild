#!/bin/bash
# check.sh — Checks that every skill points to the safe file operations rule, that finish-branch names exactly the waiting states its table defines, then runs ShellCheck on all shell scripts.

set -e

failed=0
cd "$(dirname "$0")/.."

POINTER="docs/ai/SAFE_FILE_OPERATIONS.md"
for skill in skills/*/SKILL.md; do
  if ! grep -q "$POINTER" "$skill"; then
    echo "Missing the safe file operations pointer ($POINTER): $skill"
    failed=1
  fi
done

FINISH_BRANCH="skills/finish-branch/SKILL.md"
outside_table=$(awk '/^  <waiting_states>$/ {skip=1; next} /^  <\/waiting_states>$/ {skip=0; next} !skip' "$FINISH_BRANCH")
state_names() {
  local text
  text=$(cat)
  { grep -oE '\b[A-Z]+(-[A-Z]+)*-(WAIT|DONE|PAUSE)\b' <<< "$text" || true; grep -oE 'STATE [A-Z]+(-[A-Z]+)*' <<< "$text" | sed 's/^STATE //' || true; } | sort -u
}
defined_states=$(grep -oE '^    \| [A-Z]+(-[A-Z]+)* \(' "$FINISH_BRANCH" | sed -E 's/^ +\| //; s/ \($//' | sort -u)
named_anywhere=$(state_names < "$FINISH_BRANCH")
named_in_steps=$(state_names <<< "$outside_table")
undefined_states=$(comm -13 <(echo "$defined_states") <(echo "$named_anywhere"))
unused_states=$(comm -23 <(echo "$defined_states") <(echo "$named_in_steps"))
if [ -n "$undefined_states" ]; then
  echo "finish-branch names waiting states that are not in its table: $undefined_states"
  failed=1
fi
if [ -n "$unused_states" ]; then
  echo "finish-branch defines waiting states that no directive, pre-flight, or step names: $unused_states"
  failed=1
fi

if ! command -v shellcheck &> /dev/null; then
  echo "ShellCheck not installed (brew install shellcheck). Skipping ShellCheck."
  exit $failed
fi

while IFS= read -r -d '' f; do
  shellcheck "$f" || failed=1
done < <(find . -name "*.sh" -not -path "./node_modules/*" -not -path "./.git/*" -print0)

exit $failed
