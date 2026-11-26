#!/bin/bash
# check.sh — Checks that every skill points to the safe file operations rule, then runs ShellCheck on all shell scripts.

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

if ! command -v shellcheck &> /dev/null; then
  echo "ShellCheck not installed (brew install shellcheck). Skipping ShellCheck."
  exit $failed
fi

while IFS= read -r -d '' f; do
  shellcheck "$f" || failed=1
done < <(find . -name "*.sh" -not -path "./node_modules/*" -not -path "./.git/*" -print0)

exit $failed
