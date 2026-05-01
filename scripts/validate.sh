#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "== git diff whitespace check =="
git diff --check
git diff --cached --check

echo "== required Codex Web Test markers =="
required_patterns=(
  "name: codex-web-test"
  "Quick Feature Test"
  "Full Flow Test"
  "Codex-tool-plan"
  "Viewport Discipline"
  "small-codex-viewport"
  "Coordinator Final Review"
  "Browser Use + Screenshot Review"
  "API/Security Supplemental"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -F -q "$pattern" README.md zh en; then
    echo "Missing required pattern: $pattern" >&2
    exit 1
  fi
done

echo "== deprecated wording guard =="
deprecated_patterns=(
  "Claude in Chrome"
  "Chrome extension tool"
  "Operator-mode A"
  "Operator-mode B"
  "Operator-mode C"
  "Operator Hybrid"
  "LLM Browser"
)

for pattern in "${deprecated_patterns[@]}"; do
  if rg -F -n "$pattern" README.md zh en; then
    echo "Deprecated pattern still present: $pattern" >&2
    exit 1
  fi
done

echo "== legacy Operator-mode compatibility check =="
if rg -n "Operator-mode" README.md zh en | rg -i -v "legacy|旧|兼容|compatibility|可选|optional|P0|P1|not only|不再只用|no longer"; then
  echo "Operator-mode appears outside explicit compatibility language." >&2
  exit 1
fi

echo "Validation passed."
