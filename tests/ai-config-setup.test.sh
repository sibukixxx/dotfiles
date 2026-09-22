#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

fake_source="$test_root/source"
fake_home="$test_root/home"
legacy_claude_source="$test_root/legacy-claude"
mkdir -p "$fake_source/.codex/agents" "$fake_source/.codex/skills/example" \
  "$fake_home/.codex/agents" "$legacy_claude_source"

printf 'managed = true\n' > "$fake_source/.codex/config.default.toml"
printf '# managed\n' > "$fake_source/.codex/AGENTS.md"
printf 'agent\n' > "$fake_source/.codex/agents/example.toml"
printf '%s\n' '---' 'name: example' 'description: example skill' '---' > "$fake_source/.codex/skills/example/SKILL.md"
printf 'runtime data\n' > "$fake_home/.codex/history.jsonl"
printf 'old agent\n' > "$fake_home/.codex/agents/old.toml"

AI_CONFIG_SOURCE_DIR="$fake_source" \
AI_CONFIG_CODEX_DIR="$fake_home/.codex" \
  bash "$repo_root/.codex/install.sh"

test -f "$fake_home/.codex/config.toml"
test ! -L "$fake_home/.codex/config.toml"
test -L "$fake_home/.codex/AGENTS.md"
test -L "$fake_home/.codex/agents"
test -L "$fake_home/.codex/skills/example"
test -f "$fake_home/.codex/agents.bak/old.toml"
test -f "$fake_home/.codex/history.jsonl"

# A second run must be idempotent and preserve runtime state.
AI_CONFIG_SOURCE_DIR="$fake_source" \
AI_CONFIG_CODEX_DIR="$fake_home/.codex" \
  bash "$repo_root/.codex/install.sh"

test -L "$fake_home/.codex/agents"
test -f "$fake_home/.codex/history.jsonl"

# Managed configuration must not embed the source machine's user or home path.
if rg -n --glob '!settings.local.json' '/Users/sibukixxx|/home/sibukixxx' \
  "$repo_root/.codex/config.default.toml" "$repo_root/.codex/hooks.json" \
  "$repo_root/.codex/install.sh" "$repo_root/.claude" "$repo_root/flake.nix" \
  "$repo_root/dot_config/git"; then
  echo "Managed configuration contains a machine-specific home path" >&2
  exit 1
fi

if rg -n 'sibukixxx' "$repo_root/.codex/config.default.toml" \
  "$repo_root/.codex/hooks.json" "$repo_root/.claude/settings.json" \
  "$repo_root/flake.nix" "$repo_root/dot_config/git"; then
  echo "Managed user configuration contains a fixed account name" >&2
  exit 1
fi

# A legacy root symlink must become a local runtime directory. Runtime state
# should never be written through to the dotfiles checkout.
printf 'legacy runtime\n' > "$legacy_claude_source/history.jsonl"
ln -s "$legacy_claude_source" "$fake_home/.claude"
HOME="$fake_home" bash "$repo_root/.claude/install.sh"

test -d "$fake_home/.claude"
test ! -L "$fake_home/.claude"
test -L "$fake_home/.claude/settings.json"
test -f "$fake_home/.claude.bak/history.jsonl"

echo "AI configuration setup tests passed"
