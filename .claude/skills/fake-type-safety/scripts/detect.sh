#!/usr/bin/env bash
# fake-type-safety detector
# Detects 4 patterns of "fake type safety" in TypeScript code.
#
# Usage: detect.sh [target-dir]
#   target-dir defaults to "src" if it exists, else "."

set -uo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  if [[ -d "src" ]]; then TARGET="src"; else TARGET="."; fi
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: directory not found: $TARGET" >&2
  exit 1
fi

# rg or grep fallback
if command -v rg >/dev/null 2>&1; then
  SEARCH() {
    rg -n --no-heading --color=never \
      --type-add 'tsx:*.tsx' --type ts --type tsx \
      --glob '!*.d.ts' \
      --glob '!*.test.ts' --glob '!*.test.tsx' \
      --glob '!*.spec.ts' --glob '!*.spec.tsx' \
      --glob '!*.generated.ts' \
      --glob '!node_modules' --glob '!dist' --glob '!build' --glob '!out' --glob '!.next' \
      "$1" "$TARGET" 2>/dev/null || true
  }
else
  SEARCH() {
    grep -RnE \
      --include='*.ts' --include='*.tsx' \
      --exclude='*.d.ts' \
      --exclude='*.test.ts' --exclude='*.test.tsx' \
      --exclude='*.spec.ts' --exclude='*.spec.tsx' \
      --exclude='*.generated.ts' \
      --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=out --exclude-dir=.next \
      "$1" "$TARGET" 2>/dev/null || true
  }
fi

COUNT_TOTAL=0

print_section() {
  local title="$1" pattern="$2" results
  results=$(SEARCH "$pattern")
  if [[ -n "$results" ]]; then
    local n
    n=$(printf '%s\n' "$results" | wc -l | tr -d ' ')
    COUNT_TOTAL=$((COUNT_TOTAL + n))
    echo ""
    echo "=== $title ($n hits) ==="
    printf '%s\n' "$results"
  fi
}

echo "fake-type-safety scan: $TARGET"
echo "----------------------------------------"

# Pattern 4 (most critical, listed first)
print_section "[CRITICAL] @ts-nocheck (file-wide suppression)" '@ts-nocheck'
print_section "[CRITICAL] @ts-ignore"                          '@ts-ignore'
print_section "[WARN]     @ts-expect-error without description" '@ts-expect-error\s*$'

# Pattern 3
print_section "[CRITICAL] Double-cast: as unknown as ..." 'as unknown as\b'
print_section "[CRITICAL] Double-cast: as any as ..."     'as any as\b'

# Pattern 1
print_section "[HIGH] Explicit : any annotation" ': any\b'
print_section "[HIGH] as any cast"               'as any\b'
print_section "[HIGH] Generic <any>"             '<any>'
print_section "[HIGH] any[] / Array<any>"        '(: any\[|Array<any>)'
print_section "[HIGH] Record<*, any>"            'Record<[^,]+,\s*any>'

# Pattern 2 — broad, may include false positives
print_section "[MED]  as PascalCaseType (review each)" '\bas [A-Z][A-Za-z0-9_]+(\b|\[\])'

echo ""
echo "----------------------------------------"
if [[ $COUNT_TOTAL -eq 0 ]]; then
  echo "OK: no fake-type-safety patterns detected."
  exit 0
fi
echo "Total potential issues: $COUNT_TOTAL"
echo ""
echo "Next steps:"
echo "  1. Review each hit and decide if it's a real issue or justified"
echo "  2. See references/remediation.md for fix recipes"
echo "  3. Add reason comments for any that must remain"
echo ""
echo "Note: 'as PascalCaseType' has many false positives (as const, as Date, type-guard returns)."
exit 1
