#!/bin/bash
# security-filter.sh
# スキャン結果の生出力を受け取り、8,000文字以内にフィルタして返す
# 使用方法: <スキャンコマンド> | bash ~/.claude/hooks/security-filter.sh

INPUT=$(cat)

# JSON形式の場合: Critical/High のみ抽出して深刻度降順にソート
FILTERED=$(echo "$INPUT" \
  | jq '[.[] | select(.severity == "critical" or .severity == "high" or .severity == "HIGH" or .severity == "CRITICAL")]
        | sort_by(.severity)
        | reverse' 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$FILTERED" ] && [ "$FILTERED" != "[]" ]; then
  echo "$FILTERED" | head -c 8000
else
  # JSONでない場合: CRITICAL / HIGH / ERROR 行のみ抽出
  echo "$INPUT" | grep -E "CRITICAL|HIGH|ERROR|critical|high|error" | head -c 8000
fi
