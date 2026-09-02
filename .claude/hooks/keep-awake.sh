#!/usr/bin/env bash
# keep-awake.sh — エージェントが働いている間だけ macOS をスリープさせない
#
# 使い方（settings.json の hooks から呼ぶ）:
#   UserPromptSubmit → keep-awake.sh acquire   # 作業開始: caffeinate を起動
#   Stop / SessionEnd → keep-awake.sh release  # 作業終了: caffeinate を停止
#
# stdin にはフックの JSON が来る。session_id ごとに pid ファイルを持ち、
# 同じセッションで二重起動しない。release を取りこぼしても
# KEEP_AWAKE_MAX_SECONDS（既定 4 時間）で自動的に終了する。
#
# 制限: caffeinate -s は AC 電源接続時のみ有効。バッテリー駆動でフタを閉じた
# 場合は macOS の仕様で止められない（外部ディスプレイ + 電源のクラムシェル
# 運用か、Adrafinil.app のような専用ツールが必要）。

set -uo pipefail

action="${1:-}"

usage() {
  echo "usage: $0 acquire|release" >&2
  exit 1
}

case "$action" in
  acquire | release) ;;
  *) usage ;;
esac

# macOS 以外、caffeinate が無い環境では何もしない
if [[ "$(uname -s)" != "Darwin" ]] || ! command -v caffeinate >/dev/null 2>&1; then
  exit 0
fi

input="$(cat 2>/dev/null || true)"
session_id=""
if [[ -n "$input" ]] && command -v jq >/dev/null 2>&1; then
  session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
fi
[[ -n "$session_id" ]] || session_id="${CLAUDE_CODE_SESSION_ID:-default}"
# pid ファイル名に使えない文字を潰す
session_id="${session_id//[^A-Za-z0-9._-]/_}"

dir="${KEEP_AWAKE_DIR:-${TMPDIR:-/tmp}/claude-keep-awake}"
mkdir -p "$dir"
pidfile="$dir/${session_id}.pid"
max_seconds="${KEEP_AWAKE_MAX_SECONDS:-14400}"

is_alive() {
  local pid
  [[ -f "$pidfile" ]] || return 1
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

case "$action" in
  acquire)
    if is_alive; then
      exit 0
    fi
    # -i: アイドルスリープ抑止 / -s: システムスリープ抑止(AC時) / -t: 最大秒数
    nohup caffeinate -i -s -t "$max_seconds" >/dev/null 2>&1 &
    echo $! >"$pidfile"
    disown 2>/dev/null || true
    ;;
  release)
    if [[ -f "$pidfile" ]]; then
      pid="$(cat "$pidfile" 2>/dev/null || true)"
      [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
      rm -f "$pidfile"
    fi
    ;;
esac

exit 0
