#!/bin/bash
# check.sh — Runs Prettier, ShellCheck, and markdown-link-check.
# Prettier: if check fails (and not in CI), runs --write and re-checks.
# ShellCheck and markdown-link-check have no auto-fix; they report only.
# In CI (CI=true), Prettier skips auto-fix so the run fails when formatting is wrong.

set -e

failed=0
cd "$(dirname "$0")/.."

run_prettier() {
  if npx prettier --check .; then
    return 0
  fi
  if [ "${CI:-}" = "true" ]; then
    echo "Prettier: formatting issues (no auto-fix in CI)"
    return 1
  fi
  echo "Prettier: applying fixes, then re-checking..."
  npx prettier --write .
  npx prettier --check .
}

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
  find . -name "*.md" -not -path "./node_modules/*" -not -path "./.git/*" -print0 \
    | xargs -0 npx markdown-link-check -c .markdown-link-check.json -q -- || failed=1
}

# 1. Prettier (fix-and-recheck when not in CI)
if ! run_prettier; then
  failed=1
fi

# 2. ShellCheck (no auto-fix)
run_shellcheck

# 3. markdown-link-check (no auto-fix)
run_markdown_link_check

exit $failed
