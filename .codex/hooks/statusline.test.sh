#!/usr/bin/env bash
# statusline.sh の振る舞いテスト — 直接実行:
#   bash .claude/hooks/statusline.test.sh

set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/statusline.sh"
pass=0
fail=0

# orca 連携などホーム配下の副作用を避けるため HOME を退避先に向ける
export HOME
HOME="$(mktemp -d)"
trap 'rm -r "$HOME"' EXIT

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "✘ $label"
    echo "    expected to contain: $needle"
    echo "    got: $haystack"
  fi
}

assert_not_contains() {
  local label="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "✘ $label"
    echo "    expected NOT to contain: $needle"
    echo "    got: $haystack"
  fi
}

strip_ansi() { sed -E $'s/\x1b\\[[0-9;]*m//g'; }

# --- used_percentage がある通常ケース ------------------------------------
out="$(printf '%s' '{
  "model": {"id": "claude-fable-5-1", "display_name": "Fable 5.1 (1M context)"},
  "workspace": {"current_dir": "/tmp/proj/sub", "project_dir": "/tmp/proj"},
  "context_window": {"used_percentage": 42.7, "context_window_size": 1000000},
  "rate_limits": {"five_hour": {"used_percentage": 12}, "seven_day": {"used_percentage": 91}}
}' | bash "$HOOK" | strip_ansi)"
assert_contains "shows model name" "$out" "Fable 5.1 1M"
assert_contains "shows current dir basename" "$out" "sub"
assert_contains "shows ctx percentage (floored)" "$out" "42%"
assert_contains "shows 5h rate limit" "$out" "5h"
assert_contains "shows 7d rate limit" "$out" "91%"
assert_contains "low ctx usage uses full battery" "$out" "🔋"
assert_contains "high 7d usage uses low battery" "$out" "🪫"

# --- used_percentage が無い場合は current_usage から算出 -----------------
out="$(printf '%s' '{
  "model": {"display_name": "Sonnet 5"},
  "workspace": {"current_dir": "/tmp/proj", "project_dir": "/tmp/proj"},
  "context_window": {
    "context_window_size": 200000,
    "current_usage": {"input_tokens": 40000, "cache_creation_input_tokens": 5000, "cache_read_input_tokens": 5000}
  }
}' | bash "$HOOK" | strip_ansi)"
assert_contains "computes ctx from current_usage (50000/200000)" "$out" "25%"
assert_not_contains "omits rate limits when absent" "$out" "5h"

# --- git リポジトリ内ではブランチ名を出す ---------------------------------
repo="$(mktemp -d)"
git -C "$repo" init -q -b feat/statusline-demo >/dev/null 2>&1
out="$(printf '{"model":{"display_name":"X"},"workspace":{"current_dir":"%s","project_dir":"%s"},"context_window":{"used_percentage":0}}' "$repo" "$repo" | bash "$HOOK" | strip_ansi)"
assert_contains "shows git branch" "$out" "feat/statusline-demo"
rm -r "$repo"

# --- 空入力では何も出さず 0 で終わる -------------------------------------
out="$(printf '' | bash "$HOOK")"
rc=$?
[[ "$rc" -eq 0 && -z "$out" ]] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "✘ empty stdin should be silent (rc=$rc, out='$out')"; }

# --- 壊れた JSON でも落ちない --------------------------------------------
printf 'not json' | bash "$HOOK" >/dev/null 2>&1
[[ "$?" -eq 0 ]] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "✘ invalid JSON should exit 0"; }

echo "statusline: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
