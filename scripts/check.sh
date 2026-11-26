#!/bin/bash
# check.sh — Checks that every skill points to the safe file operations rule, that the git rules are identical in every skill, that the skill transition tables are valid (check-flow.sh), then runs ShellCheck on all shell scripts.

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

for rule in "GIT MODES:" "ALWAYS FORBIDDEN"; do
  distinct=$(grep -h "^[[:space:]]*$rule" skills/*/SKILL.md | sed 's/^[[:space:]]*//' | sort -u | wc -l)
  if [ "$distinct" -gt 1 ]; then
    echo "The \"$rule\" rule differs between skills; every skill must carry the identical line:"
    grep -c "^[[:space:]]*$rule" skills/*/SKILL.md | grep -v ':0$' | cut -d: -f1 | while read -r f; do
      echo "  $(grep -h "^[[:space:]]*$rule" "$f" | sed 's/^[[:space:]]*//' | md5sum | cut -c1-8) $f"
    done
    failed=1
  fi
done

if ! bash scripts/check-flow.sh; then
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
