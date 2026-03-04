#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  improve-loop.sh [minutes] [--rounds N] [options]

Examples:
  improve-loop.sh 120
  improve-loop.sh --rounds 5
  improve-loop.sh 120 --rounds 5 --max-changed-files 40 --max-diff-lines 1500

Options:
  --minutes N              Time budget in minutes
  --rounds N               Max rounds (default: 999999)
  --max-changed-files N    Hard limit for changed files per run (default: 40)
  --max-diff-lines N       Hard limit for diff lines per run (default: 1500)
  --critical-path CSV      Glob patterns for critical paths
                           default: src/core/**,src/domain/**,db/migrations/**,infra/**,auth/**,payment/**
  --qa-cmd CMD             QA phase command
  --fix-cmd CMD            Fix phase command
  --refactor-cmd CMD       Refactor phase command
  --e2e-cmd CMD            E2E command
  --issue-count-cmd CMD    Command that prints open issue count as integer
  --report-dir DIR         Report output dir (default: reports)
  -h, --help               Show help
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >&2
}

warn() {
  printf '[%s] [WARN] %s\n' "$(date '+%H:%M:%S')" "$*" >&2
}

fail() {
  printf '[%s] [ERROR] %s\n' "$(date '+%H:%M:%S')" "$*" >&2
  exit 1
}

cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_default_e2e_cmd() {
  if [[ -n "${e2e_cmd:-}" ]]; then
    return
  fi
  if [[ -f package.json ]] && cmd_exists npm; then
    if npm run | grep -q "test:e2e"; then
      e2e_cmd="npm run -s test:e2e"
      return
    fi
  fi
  if [[ -f package.json ]] && cmd_exists pnpm; then
    if pnpm run | grep -q "test:e2e"; then
      e2e_cmd="pnpm -s test:e2e"
      return
    fi
  fi
  if [[ -f Makefile ]] && grep -qE '^e2e:' Makefile; then
    e2e_cmd="make e2e"
    return
  fi
  warn "E2E command not found automatically. Using 'true'."
  e2e_cmd="true"
}

detect_default_phase_cmds() {
  if [[ -z "${qa_cmd:-}" ]]; then
    if [[ -x ./scripts/improve-qa.sh ]]; then
      qa_cmd="./scripts/improve-qa.sh"
    else
      warn "QA command not specified. Using 'true'."
      qa_cmd="true"
    fi
  fi
  if [[ -z "${fix_cmd:-}" ]]; then
    if [[ -x ./scripts/improve-fix.sh ]]; then
      fix_cmd="./scripts/improve-fix.sh"
    else
      warn "Fix command not specified. Using 'true'."
      fix_cmd="true"
    fi
  fi
  if [[ -z "${refactor_cmd:-}" ]]; then
    if [[ -x ./scripts/improve-refactor.sh ]]; then
      refactor_cmd="./scripts/improve-refactor.sh"
    else
      warn "Refactor command not specified. Using 'true'."
      refactor_cmd="true"
    fi
  fi
}

detect_default_issue_cmd() {
  if [[ -n "${issue_count_cmd:-}" ]]; then
    return
  fi
  if cmd_exists gh && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    issue_count_cmd="gh issue list --state open --json number --limit 500 | jq 'length'"
    return
  fi
  issue_count_cmd=""
}

run_cmd() {
  local title="$1"
  local cmd="$2"
  log "$title: $cmd"
  bash -lc "$cmd"
}

count_open_issues() {
  if [[ -z "${issue_count_cmd:-}" ]]; then
    echo "-1"
    return
  fi

  local out
  if ! out="$(bash -lc "$issue_count_cmd" 2>/dev/null | tr -d '[:space:]')"; then
    echo "-1"
    return
  fi

  if [[ "$out" =~ ^[0-9]+$ ]]; then
    echo "$out"
  else
    echo "-1"
  fi
}

sum_numstat() {
  awk 'NF==3 {add+=$1; del+=$2} END {print add+del+0}'
}

changed_files_since() {
  local since_sha="$1"
  {
    git diff --name-only "$since_sha"...HEAD
    git diff --name-only HEAD
  } | awk 'NF' | sort -u
}

changed_loc_since() {
  local since_sha="$1"
  local committed working
  committed="$(git diff --numstat "$since_sha"...HEAD | sum_numstat)"
  working="$(git diff --numstat HEAD | sum_numstat)"
  echo $((committed + working))
}

count_failed_tests_from_log() {
  local logfile="$1"
  local n
  n="$(grep -Eio '([0-9]+)[[:space:]]+failed' "$logfile" | awk '{print $1}' | head -n1 || true)"
  if [[ -z "$n" ]]; then
    echo "0"
  else
    echo "$n"
  fi
}

run_e2e_and_count_failures() {
  local label="$1"
  local logfile="$2"
  set +e
  bash -lc "$e2e_cmd" >"$logfile" 2>&1
  local rc=$?
  set -e

  local failed
  failed="$(count_failed_tests_from_log "$logfile")"
  if [[ $rc -ne 0 && "$failed" -eq 0 ]]; then
    failed=1
  fi
  log "$label E2E rc=$rc failed=$failed"
  echo "$failed|$rc"
}

matches_critical_path() {
  local file="$1"
  local pattern
  for pattern in "${critical_patterns[@]}"; do
    [[ -z "$pattern" ]] && continue
    if [[ "$file" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

auto_revert_refactor_changes() {
  local before_sha="$1"
  local after_sha="$2"

  if [[ "$before_sha" != "$after_sha" ]]; then
    log "Refactor produced commit(s). Reverting commits in ${before_sha}..${after_sha}"
    local commit
    while IFS= read -r commit; do
      [[ -z "$commit" ]] && continue
      run_cmd "Auto revert commit $commit" "git revert --no-edit $commit"
    done < <(git rev-list "${before_sha}..${after_sha}")
    return
  fi

  if ! git diff --quiet HEAD; then
    log "Refactor changed working tree only. Restoring working tree to HEAD."
    git restore --worktree --staged --source=HEAD -- .
  fi
}

minutes=0
max_rounds=999999
max_changed_files=40
max_diff_lines=1500
critical_path_csv="src/core/**,src/domain/**,db/migrations/**,infra/**,auth/**,payment/**"
qa_cmd=""
fix_cmd=""
refactor_cmd=""
e2e_cmd=""
issue_count_cmd=""
report_dir="reports"

if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
  minutes="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minutes)
      minutes="${2:-}"
      shift 2
      ;;
    --rounds)
      max_rounds="${2:-}"
      shift 2
      ;;
    --max-changed-files)
      max_changed_files="${2:-}"
      shift 2
      ;;
    --max-diff-lines)
      max_diff_lines="${2:-}"
      shift 2
      ;;
    --critical-path)
      critical_path_csv="${2:-}"
      shift 2
      ;;
    --qa-cmd)
      qa_cmd="${2:-}"
      shift 2
      ;;
    --fix-cmd)
      fix_cmd="${2:-}"
      shift 2
      ;;
    --refactor-cmd)
      refactor_cmd="${2:-}"
      shift 2
      ;;
    --e2e-cmd)
      e2e_cmd="${2:-}"
      shift 2
      ;;
    --issue-count-cmd)
      issue_count_cmd="${2:-}"
      shift 2
      ;;
    --report-dir)
      report_dir="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

[[ "$minutes" =~ ^[0-9]+$ ]] || fail "--minutes must be integer"
[[ "$max_rounds" =~ ^[0-9]+$ ]] || fail "--rounds must be integer"
[[ "$max_changed_files" =~ ^[0-9]+$ ]] || fail "--max-changed-files must be integer"
[[ "$max_diff_lines" =~ ^[0-9]+$ ]] || fail "--max-diff-lines must be integer"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "This script must run inside a git repository."
fi

if ! git diff --quiet HEAD; then
  fail "Working tree must be clean before running improve loop."
fi

IFS=',' read -r -a critical_patterns <<<"$critical_path_csv"
detect_default_phase_cmds
detect_default_e2e_cmd
detect_default_issue_cmd

mkdir -p "$report_dir" .tmp/improve

start_epoch="$(date +%s)"
deadline_epoch=0
if [[ "$minutes" -gt 0 ]]; then
  deadline_epoch=$((start_epoch + minutes * 60))
fi

run_date="$(date +%Y%m%d)"
report_file="${report_dir}/improve-${run_date}.md"
raw_log=".tmp/improve/improve-${run_date}-$(date +%H%M%S).tsv"

cat >"$report_file" <<EOF
# Improve Run Report (${run_date})

- Started: $(date '+%Y-%m-%d %H:%M:%S')
- Minutes budget: ${minutes}
- Round budget: ${max_rounds}
- Max changed files: ${max_changed_files}
- Max diff lines: ${max_diff_lines}
- Critical path: ${critical_path_csv}

## Round Metrics

| Round | Open Issues (Before->After) | Failed E2E (Before->After) | Changed Files | Changed LOC | Status |
| --- | --- | --- | --- | --- | --- |
EOF

printf "round\topen_before\topen_after\tfailed_before\tfailed_after\tchanged_files\tchanged_loc\tstatus\n" >"$raw_log"

log "Starting improve loop"
log "QA command: $qa_cmd"
log "Fix command: $fix_cmd"
log "Refactor command: $refactor_cmd"
log "E2E command: $e2e_cmd"

status="completed"
round=1
while [[ $round -le $max_rounds ]]; do
  now="$(date +%s)"
  if [[ $deadline_epoch -gt 0 && $now -ge $deadline_epoch ]]; then
    status="time_budget_reached"
    break
  fi

  round_start_sha="$(git rev-parse HEAD)"
  log "Round $round started (base=$round_start_sha)"

  open_before="$(count_open_issues)"

  e2e_before_log=".tmp/improve/round-${round}-e2e-before.log"
  before_pair="$(run_e2e_and_count_failures "Round $round BEFORE" "$e2e_before_log")"
  failed_before="${before_pair%%|*}"

  if [[ "$open_before" -eq 0 ]]; then
    log "Open issues already zero. Early exit."
    printf "| %d | %s->%s | %s->%s | %d | %d | %s |\n" \
      "$round" "$open_before" "$open_before" "$failed_before" "$failed_before" 0 0 "early_exit_no_open_issues" >>"$report_file"
    printf "%d\t%s\t%s\t%s\t%s\t%d\t%d\t%s\n" \
      "$round" "$open_before" "$open_before" "$failed_before" "$failed_before" 0 0 "early_exit_no_open_issues" >>"$raw_log"
    status="early_exit_no_open_issues"
    break
  fi

  run_cmd "Round $round QA" "$qa_cmd"
  run_cmd "Round $round Fix" "$fix_cmd"

  refactor_before_sha="$(git rev-parse HEAD)"
  run_cmd "Round $round Refactor" "$refactor_cmd"
  refactor_after_sha="$(git rev-parse HEAD)"

  e2e_after_log=".tmp/improve/round-${round}-e2e-after.log"
  after_pair="$(run_e2e_and_count_failures "Round $round AFTER" "$e2e_after_log")"
  failed_after="${after_pair%%|*}"
  e2e_after_rc="${after_pair##*|}"

  if [[ "$e2e_after_rc" -ne 0 ]]; then
    warn "Round $round: refactor broke E2E. Auto-reverting refactor changes."
    auto_revert_refactor_changes "$refactor_before_sha" "$refactor_after_sha"
    rerun_log=".tmp/improve/round-${round}-e2e-rerun.log"
    rerun_pair="$(run_e2e_and_count_failures "Round $round RERUN" "$rerun_log")"
    failed_after="${rerun_pair%%|*}"
  fi

  open_after="$(count_open_issues)"
  changed_loc="$(changed_loc_since "$round_start_sha")"
  changed_files_list="$(changed_files_since "$round_start_sha" || true)"
  changed_files=0
  if [[ -n "$changed_files_list" ]]; then
    changed_files="$(printf "%s\n" "$changed_files_list" | awk 'NF' | wc -l | tr -d ' ')"
  fi

  round_status="ok"

  if [[ "$changed_files" -gt "$max_changed_files" ]]; then
    round_status="stopped_max_changed_files"
  fi

  if [[ "$changed_loc" -gt "$max_diff_lines" ]]; then
    round_status="stopped_max_diff_lines"
  fi

  critical_hit=""
  if [[ -n "$changed_files_list" ]]; then
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if matches_critical_path "$f"; then
        critical_hit="$f"
        round_status="waiting_human_review_critical_path"
        break
      fi
    done <<<"$changed_files_list"
  fi

  printf "| %d | %s->%s | %s->%s | %d | %d | %s |\n" \
    "$round" "$open_before" "$open_after" "$failed_before" "$failed_after" "$changed_files" "$changed_loc" "$round_status" >>"$report_file"
  printf "%d\t%s\t%s\t%s\t%s\t%d\t%d\t%s\n" \
    "$round" "$open_before" "$open_after" "$failed_before" "$failed_after" "$changed_files" "$changed_loc" "$round_status" >>"$raw_log"

  if [[ -n "$critical_hit" ]]; then
    {
      echo ""
      echo "### Round ${round} Critical Path"
      echo ""
      echo "- Changed critical path file: \`${critical_hit}\`"
      echo "- Action: stop and wait for human review"
    } >>"$report_file"
    status="$round_status"
    break
  fi

  if [[ "$round_status" != "ok" ]]; then
    status="$round_status"
    break
  fi

  if [[ "$open_after" -eq 0 ]]; then
    status="early_exit_no_open_issues"
    break
  fi

  round=$((round + 1))
done

{
  echo ""
  echo "## Final Summary"
  echo ""
  echo "- Finished: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "- Status: ${status}"
  echo "- Raw metrics: \`${raw_log}\`"
} >>"$report_file"

log "Improve loop finished: $status"
log "Report: $report_file"
