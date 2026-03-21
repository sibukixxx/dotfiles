#!/usr/bin/env bash
# =============================================================================
# AI Rules Generator
# =============================================================================
# .claude/rules/core/ のルールファイルから各AIツール向けの設定ファイルを生成する。
# フロントマター（---...---）を除去し、ツール固有のヘッダーを付与する。
#
# Usage:
#   ./ai-rules/generate.sh                    # ai-rules/generated/ に出力
#   ./ai-rules/generate.sh /path/to/project   # 指定プロジェクトに直接配置
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_DIR="$DOTFILES_DIR/.claude/rules/core"
OUTPUT_DIR="${1:-$SCRIPT_DIR/generated}"

# フロントマターを除去して本文のみ返す
strip_frontmatter() {
  local file="$1"
  if head -1 "$file" | grep -q '^---$'; then
    sed '1,/^---$/d' "$file"
  else
    cat "$file"
  fi
}

# ルールファイルを結合（指定ファイル群）
concat_rules() {
  local files=("$@")
  for f in "${files[@]}"; do
    if [ -f "$RULES_DIR/$f" ]; then
      strip_frontmatter "$RULES_DIR/$f"
      echo ""
      echo "---"
      echo ""
    fi
  done
}

# 出力対象のルールファイル（順序が重要）
CORE_RULES=(
  "design.md"
  "tdd.md"
  "testing.md"
  "security.md"
  "commit.md"
)

REFERENCE_RULES=(
  "references/test-doubles.md"
  "references/test-naming.md"
)

echo "==> Generating AI rules from .claude/rules/core/"
echo "    Source: $RULES_DIR"
echo "    Output: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/.github"

# =========================================================================
# .cursorrules (Cursor)
# =========================================================================
{
  cat <<'HEADER'
# Project Rules for Cursor
# Generated from .claude/rules/core/ — DO NOT EDIT DIRECTLY
# Regenerate with: make ai-rules

HEADER
  concat_rules "${CORE_RULES[@]}"
  concat_rules "${REFERENCE_RULES[@]}"
} > "$OUTPUT_DIR/.cursorrules"
echo "  ✅ .cursorrules"

# =========================================================================
# .github/copilot-instructions.md (GitHub Copilot)
# =========================================================================
{
  cat <<'HEADER'
# Copilot Instructions
<!-- Generated from .claude/rules/core/ — DO NOT EDIT DIRECTLY -->
<!-- Regenerate with: make ai-rules -->

HEADER
  concat_rules "${CORE_RULES[@]}"
  concat_rules "${REFERENCE_RULES[@]}"
} > "$OUTPUT_DIR/.github/copilot-instructions.md"
echo "  ✅ .github/copilot-instructions.md"

# =========================================================================
# .clinerules (Cline)
# =========================================================================
{
  cat <<'HEADER'
# Project Rules for Cline
# Generated from .claude/rules/core/ — DO NOT EDIT DIRECTLY
# Regenerate with: make ai-rules

HEADER
  concat_rules "${CORE_RULES[@]}"
  concat_rules "${REFERENCE_RULES[@]}"
} > "$OUTPUT_DIR/.clinerules"
echo "  ✅ .clinerules"

# =========================================================================
# .windsurfrules (Windsurf)
# =========================================================================
{
  cat <<'HEADER'
# Project Rules for Windsurf
# Generated from .claude/rules/core/ — DO NOT EDIT DIRECTLY
# Regenerate with: make ai-rules

HEADER
  concat_rules "${CORE_RULES[@]}"
  concat_rules "${REFERENCE_RULES[@]}"
} > "$OUTPUT_DIR/.windsurfrules"
echo "  ✅ .windsurfrules"

# =========================================================================
# RULES.md (汎用 — Aider / OpenAI 等)
# =========================================================================
{
  cat <<'HEADER'
# Project Coding Rules
<!-- Generated from .claude/rules/core/ — DO NOT EDIT DIRECTLY -->
<!-- Any AI coding assistant can reference this file -->
<!-- Regenerate with: make ai-rules -->

HEADER
  concat_rules "${CORE_RULES[@]}"
  concat_rules "${REFERENCE_RULES[@]}"
} > "$OUTPUT_DIR/RULES.md"
echo "  ✅ RULES.md (universal)"

echo ""
echo "Done! Copy files to your project:"
echo "  cp $OUTPUT_DIR/.cursorrules /path/to/project/"
echo "  cp $OUTPUT_DIR/.github/copilot-instructions.md /path/to/project/.github/"
echo "  cp $OUTPUT_DIR/RULES.md /path/to/project/"
