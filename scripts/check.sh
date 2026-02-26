#!/bin/bash
# check.sh — Runs ShellCheck and markdown-link-check.
# Neither tool has auto-fix; they report only.

set -e

failed=0
cd "$(dirname "$0")/.."

run_shellcheck() {
  if ! command -v shellcheck &> /dev/null; then
    echo "ShellCheck not installed (brew install shellcheck). Skipping shell checks."
    return 0
  fi
  local f
  while IFS= read -r -d '' f; do
    shellcheck "$f" || failed=1
  done < <(find . -name "*.sh" -not -path "./node_modules/*" -not -path "./.git/*" -print0)
}

run_markdown_link_check() {
  local count
  count=$(find . -name "*.md" -not -path "./node_modules/*" -not -path "./.git/*" | wc -l)
  if [ "$count" -eq 0 ]; then
    return 0
  fi
  find . -name "*.md" -not -path "./node_modules/*" -not -path "./.git/*" -print0 |
    xargs -0 npx markdown-link-check -c .markdown-link-check.json -q -- || failed=1
}

run_shellcheck
run_markdown_link_check

exit $failed
