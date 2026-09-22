#!/usr/bin/env bash
# keep-awake.sh の振る舞いテスト — 直接実行:
#   bash .claude/hooks/keep-awake.test.sh
#
# acquire で caffeinate が 1 つだけ起動し、release で確実に止まることを検証する。

set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/keep-awake.sh"
pass=0
fail=0

export KEEP_AWAKE_DIR
KEEP_AWAKE_DIR="$(mktemp -d)"
trap 'rm -r "$KEEP_AWAKE_DIR"' EXIT

assert() {
  local label="$1" ok="$2"
  if [[ "$ok" == "0" ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "✘ $label"
  fi
}

payload='{"session_id":"test-session","hook_event_name":"UserPromptSubmit"}'
pidfile="$KEEP_AWAKE_DIR/test-session.pid"

# --- acquire: pid ファイルが作られ caffeinate が生きている ------------------
printf '%s' "$payload" | bash "$HOOK" acquire
assert "acquire exits 0" "$?"
[[ -f "$pidfile" ]]; assert "acquire creates pidfile" "$?"
pid1="$(cat "$pidfile" 2>/dev/null || echo 0)"
kill -0 "$pid1" 2>/dev/null; assert "acquire starts a live process" "$?"
# nohup → caffeinate の exec 直後は comm がまだ切り替わっていないことがあるので少し待つ
for _ in 1 2 3 4 5 6 7 8 9 10; do
  ps -p "$pid1" -o comm= 2>/dev/null | grep -q caffeinate && break
  sleep 0.05
done
ps -p "$pid1" -o comm= 2>/dev/null | grep -q caffeinate; assert "process is caffeinate" "$?"

# --- acquire は冪等: 2 回目は同じ pid のまま ------------------------------
printf '%s' "$payload" | bash "$HOOK" acquire
pid2="$(cat "$pidfile" 2>/dev/null || echo 0)"
[[ "$pid1" == "$pid2" ]]; assert "second acquire reuses the same process" "$?"

# --- release: プロセスが止まり pid ファイルが消える -----------------------
printf '%s' "$payload" | bash "$HOOK" release
assert "release exits 0" "$?"
sleep 0.2
! kill -0 "$pid1" 2>/dev/null; assert "release stops caffeinate" "$?"
[[ ! -f "$pidfile" ]]; assert "release removes pidfile" "$?"

# --- release は pid ファイルが無くても静かに成功 ----------------------------
printf '%s' "$payload" | bash "$HOOK" release
assert "release without pidfile exits 0" "$?"

# --- stdin が空でも壊れない（session_id は default に落ちる） ---------------
printf '' | bash "$HOOK" acquire
assert "acquire with empty stdin exits 0" "$?"
printf '' | bash "$HOOK" release
assert "release with empty stdin exits 0" "$?"
[[ -z "$(ls -A "$KEEP_AWAKE_DIR")" ]]; assert "no leftover pidfiles" "$?"

# --- 不明なサブコマンドは非 0 ---------------------------------------------
printf '' | bash "$HOOK" bogus 2>/dev/null
[[ "$?" != "0" ]]; assert "unknown action fails" "$?"

echo "keep-awake: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
