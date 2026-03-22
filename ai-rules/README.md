# ai-rules/ - AI Agent 共有ルール

## 概要

`.claude/rules/` に格納されたルールをソースとし、各AIコーディングツール向けの
設定ファイルを生成する。ルールの実体は `.claude/rules/core/` にあり、
このディレクトリには生成スクリプトと出力ファイルを置く。

## 対応ツール

| ツール | 設定ファイル | 配置先 |
|--------|-------------|--------|
| Claude Code | `.claude/rules/` | `~/.claude/rules/` (global) |
| Cursor | `.cursorrules` | プロジェクトルート |
| GitHub Copilot | `.github/copilot-instructions.md` | プロジェクトルート |
| Cline | `.clinerules` | プロジェクトルート |
| Windsurf | `.windsurfrules` | プロジェクトルート |
| Aider | `.aider.conf.yml` | プロジェクトルート |

## 使い方

```bash
# プロジェクトルートで実行 → 各ツール向けファイルを生成
make ai-rules

# 特定のプロジェクトに配置
cp ai-rules/generated/.cursorrules /path/to/project/
cp ai-rules/generated/.github/copilot-instructions.md /path/to/project/.github/
```

## ルールのソース (Single Source of Truth)

`.claude/rules/core/` 以下のファイルが正本:

- `design.md` - 設計原則 (SOLID, YAGNI, 命名規則)
- `tdd.md` - TDD ルール (Red→Green→Refactor)
- `testing.md` - テスト共通ルール
- `security.md` - セキュリティチェックリスト
- `commit.md` - コミット規約
- `ai-agent-o11y.md` - AI Agent Observability
- `references/` - テストダブル、テスト命名規則
