#!/usr/bin/env bash
# statusline.sh — Claude Code のステータスライン
#
#   <model> | <dir> (<branch>) | ctx 🔋 42% | 5h 🔋 12% | 7d 🪫 91%
#
# コンテキスト使用率は「使った分」の割合。数値そのものより残量感が分かる
# ように電池絵文字と色で表現する（緑 <70% / 黄 <90% / 赤 ≥90%）。
# 1M コンテキスト時代に細かい数値は意味が薄いので、桁数を抑えている。
#
# Orca（ターミナル）が同じペイロードを必要とするので、末尾で
# ~/.orca/agent-hooks/claude-statusline.sh にも流している。

set -uo pipefail

input="$(cat 2>/dev/null || true)"
[[ -n "$input" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
printf '%s' "$input" | jq -e . >/dev/null 2>&1 || exit 0

j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null || true; }

RESET=$'\e[0m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'

color_for() {
  local pct="$1"
  if ((pct >= 90)); then printf '%s' "$RED"
  elif ((pct >= 70)); then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

# 使用率が高いほど「残量が少ない」電池にする
battery_for() {
  local pct="$1"
  if ((pct >= 80)); then printf '🪫'; else printf '🔋'; fi
}

meter() {
  local label="$1" pct="$2" c
  c="$(color_for "$pct")"
  printf '%s %s%s %d%%%s' "$label" "$c" "$(battery_for "$pct")" "$pct" "$RESET"
}

# --- model ---------------------------------------------------------------
model="$(j '.model.display_name // .model.id // ""')"
model="${model// (1M context)/ 1M}"
effort="$(j '.effort.level // ""')"
[[ -n "$effort" ]] && model="$model $effort"

# --- directory / branch --------------------------------------------------
cur="$(j '.workspace.current_dir // ""')"
proj="$(j '.workspace.project_dir // ""')"
dir="${cur##*/}"
[[ -n "$cur" && -n "$proj" && "$cur" != "$proj" ]] && dir="$dir ⤵"

branch=""
if [[ -n "$cur" && -d "$cur" ]] && git -C "$cur" rev-parse --git-dir >/dev/null 2>&1; then
  branch="$(git -C "$cur" branch --show-current 2>/dev/null || true)"
  if [[ -z "$branch" ]]; then
    branch="HEAD ($(git -C "$cur" rev-parse --short HEAD 2>/dev/null || echo '?'))"
  fi
fi
[[ -n "$branch" ]] && dir="$dir ($branch)"

# --- context usage -------------------------------------------------------
ctx_raw="$(j '.context_window.used_percentage // empty')"
if [[ -z "$ctx_raw" ]]; then
  ctx_raw="$(j '
    (.context_window // {}) as $cw
    | ($cw.context_window_size // 0) as $size
    | (($cw.current_usage // {}) | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))) as $used
    | if $size > 0 then ($used * 100 / $size) else empty end')"
fi
ctx="${ctx_raw%%.*}"
[[ "$ctx" =~ ^[0-9]+$ ]] || ctx=0

# --- rate limits (present only on some plans) ---------------------------
five="$(j '.rate_limits.five_hour.used_percentage // empty')"
week="$(j '.rate_limits.seven_day.used_percentage // empty')"

segments=()
[[ -n "$model" ]] && segments+=("$model")
[[ -n "$dir" ]] && segments+=("$dir")
segments+=("$(meter ctx "$ctx")")
if [[ -n "$five" ]]; then five="${five%%.*}"; [[ "$five" =~ ^[0-9]+$ ]] && segments+=("$(meter 5h "$five")"); fi
if [[ -n "$week" ]]; then week="${week%%.*}"; [[ "$week" =~ ^[0-9]+$ ]] && segments+=("$(meter 7d "$week")"); fi

out=""
for s in "${segments[@]}"; do
  [[ -n "$out" ]] && out="$out | "
  out="$out$s"
done
printf '%s\n' "$out"

# --- Orca 連携（あれば同じペイロードを渡す） ----------------------------
orca="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [[ -x "$orca" ]]; then
  printf '%s' "$input" | "$orca" >/dev/null 2>&1 || true
fi

exit 0
