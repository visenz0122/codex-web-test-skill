#!/usr/bin/env bash
set -euo pipefail

edition="${1:-zh}"
skill_name="${2:-codex-web-test}"

if [[ "$edition" != "zh" && "$edition" != "en" ]]; then
  echo "Usage: scripts/install-local.sh [zh|en] [skill-name]" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
target="$codex_home/skills/$skill_name"

mkdir -p "$codex_home/skills"
rm -rf "$target"
cp -R "$repo_root/$edition" "$target"

echo "Installed $edition edition to $target"
echo "Restart Codex or open a new Codex session to reload skills."
