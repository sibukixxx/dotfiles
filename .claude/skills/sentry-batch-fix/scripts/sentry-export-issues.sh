#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sentry-export-issues.sh [--days N] [--limit N] [--query QUERY]

Required env:
  SENTRY_AUTH_TOKEN   Sentry API token
  SENTRY_ORG          Organization slug

Optional env:
  SENTRY_PROJECTS     Comma separated project slugs, e.g. "web,api"
  SENTRY_BASE_URL     Default: https://sentry.io

Examples:
  SENTRY_AUTH_TOKEN=xxx SENTRY_ORG=my-org \
    bash sentry-export-issues.sh --days 14 --limit 100 --query "is:unresolved level:error"
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

days=14
limit=100
query='is:unresolved level:error'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      days="${2:-}"
      shift 2
      ;;
    --limit)
      limit="${2:-}"
      shift 2
      ;;
    --query)
      query="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd curl
require_cmd jq

: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN is required}"
: "${SENTRY_ORG:?SENTRY_ORG is required}"
SENTRY_BASE_URL="${SENTRY_BASE_URL:-https://sentry.io}"

out_dir=".tmp/sentry"
mkdir -p "$out_dir"
raw_file="$out_dir/issues_raw.json"
ranked_file="$out_dir/issues_ranked.json"

query_params=(
  --data-urlencode "query=$query"
  --data-urlencode "statsPeriod=${days}d"
  --data-urlencode "limit=$limit"
)

if [[ -n "${SENTRY_PROJECTS:-}" ]]; then
  IFS=',' read -r -a projects <<<"$SENTRY_PROJECTS"
  for p in "${projects[@]}"; do
    query_params+=(--data-urlencode "project=${p}")
  done
fi

curl -fsS -G \
  "${SENTRY_BASE_URL}/api/0/organizations/${SENTRY_ORG}/issues/" \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${query_params[@]}" \
  > "$raw_file"

# Priority score: prioritize unhandled + high count + high userCount + recent issues
jq '
  map(
    .count_num = ((.count // "0") | tonumber) |
    .user_count_num = ((.userCount // 0) | tonumber) |
    .is_unhandled_num = (if (.isUnhandled // false) then 1 else 0 end) |
    .priority_score = (
      (.is_unhandled_num * 1000000) +
      (.count_num * 1000) +
      (.user_count_num * 100)
    ) |
    {
      id,
      shortId,
      title,
      level,
      status,
      isUnhandled,
      count: .count_num,
      userCount: .user_count_num,
      firstSeen,
      lastSeen,
      permalink,
      culprit,
      priorityScore: .priority_score
    }
  )
  | sort_by(-.priorityScore, -.count, -.userCount, -.lastSeen)
' "$raw_file" > "$ranked_file"

echo "Exported:"
echo "  raw:    $raw_file"
echo "  ranked: $ranked_file"
echo ""
echo "Top 10:"
jq -r '
  .[0:10][]
  | "\(.shortId // .id)\tcount=\(.count)\tusers=\(.userCount)\tunhandled=\(.isUnhandled)\t\(.title)"
' "$ranked_file"
