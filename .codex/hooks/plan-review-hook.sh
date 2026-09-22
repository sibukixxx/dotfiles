#!/bin/bash
# =============================================================================
# Plan Review Hook
# ExitPlanMode の PreToolUse hook として動作し、
# Codex で実装プランを自動レビュー。致命的な指摘があればブロックする。
#
# セットアップ:
#   1. このファイルを ~/.claude/plan-review-hook.sh にコピー
#   2. chmod +x ~/.claude/plan-review-hook.sh
#   3. ~/.claude/settings.json に以下を追加:
#      "hooks": {
#        "PreToolUse": [{
#          "matcher": "ExitPlanMode",
#          "hooks": [{ "type": "command", "command": "~/.claude/plan-review-hook.sh", "timeout": 300000 }]
#        }]
#      }
#
# フロー:
#   1. Claude Code が ExitPlanMode を呼ぶ → このhookが発火
#   2. codex でプランをレビュー
#   3. 指摘あり → exit 2（ブロック）→ Claude がプラン修正 → 再度 ExitPlanMode → 2に戻る
#   4. 指摘なし（LGTM）→ exit 0 → ExitPlanMode 成功
#
# 環境変数:
#   CODEX_MODEL          - 使用するモデル (default: gpt-5.4)
#   PLAN_REVIEW_DISABLED - "1" でレビューをスキップ
# =============================================================================

# Skip if disabled
[[ "${PLAN_REVIEW_DISABLED:-}" == "1" ]] && exit 0

# Check codex availability
if ! command -v codex &>/dev/null; then
    echo "[Plan Review] codex コマンドが見つかりません。レビューをスキップします。" >&2
    exit 0
fi

# Read stdin (hook receives JSON context from Claude Code)
input=$(cat)

# Find the most recent plan file
plan_file=$(ls -t ~/.claude/plans/*.md 2>/dev/null | head -1)

if [[ -z "$plan_file" ]]; then
    # No plan file found - allow ExitPlanMode
    exit 0
fi

# Find CLAUDE.md for context reference
claude_md_ref=""
if [[ -f "./CLAUDE.md" ]]; then
    claude_md_ref="(ref: $(pwd)/CLAUDE.md)"
fi

# Configuration
model="${CODEX_MODEL:-gpt-5.4}"
review_instruction="細かい点は無視して、致命的な問題だけ指摘して。指摘がなければ最終行に「LGTM」とだけ出力して"

# State management: first review vs subsequent (for codex session resume)
state_file="/tmp/.codex-plan-review-$(id -u)"

if [[ -f "$state_file" ]] && [[ "$(cat "$state_file" 2>/dev/null)" == "$plan_file" ]]; then
    # Subsequent review - resume codex session for context continuity
    output=$(codex exec resume --last -m "$model" \
        "プランを更新したからレビューして。${review_instruction}: ${plan_file} ${claude_md_ref}" 2>&1)
    codex_rc=$?
else
    # Initial review - start new codex session
    output=$(codex exec -m "$model" \
        "このプランをレビューして。${review_instruction}: ${plan_file} ${claude_md_ref}" 2>&1)
    codex_rc=$?
    echo "$plan_file" > "$state_file"
fi

# Handle codex execution failure (network error, auth issue, etc.)
if [[ $codex_rc -ne 0 ]]; then
    echo "[Plan Review] codex 実行エラー (exit: $codex_rc)。レビューをスキップします。" >&2
    rm -f "$state_file"
    exit 0
fi

# Determine result: LGTM = pass, otherwise = block
if echo "$output" | tail -5 | grep -qi "LGTM"; then
    rm -f "$state_file"
    echo "[Plan Review] LGTM - プランに致命的な問題は見つかりませんでした。" >&2
    exit 0
else
    echo "[Plan Review] Codex から指摘があります。プランを修正して再度 ExitPlanMode してください:" >&2
    echo "---" >&2
    echo "$output" >&2
    echo "---" >&2
    exit 2
fi
