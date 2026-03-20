---
name: translate-commits
description: Git コミットメッセージを日本語に翻訳した一覧を生成する。Use when user says "コミットを日本語に", "commit translate", "コミット翻訳", "translate commits", or wants to review English commit messages for Japanese translation.
---

# Translate Commits

Git log から英語のコミットメッセージを抽出し、日本語訳の一覧を生成する。

## Overview

プロジェクトの Conventional Commit メッセージを日本語に統一するための支援ツール。
英語のコミットメッセージを検出し、日本語の件名案を自動生成する。

## Instructions

### Step 1: 英語コミットを抽出

プロジェクトに `scripts/translate-commits.sh` があればそれを使う。なければ以下で抽出：

```bash
# 英語のみ抽出（デフォルト）
./scripts/translate-commits.sh

# 全コミット出力
./scripts/translate-commits.sh -a

# オプション
#   -n NUM   対象コミット数 (default: 50)
#   -a       全コミット（日本語含む）を出力
#   -f FMT   出力形式: tsv (default), csv, markdown
#   -o FILE  ファイルに出力
```

スクリプトがない場合は git log から直接取得：

```bash
git log --format="%h%x09%s" -50
```

### Step 2: 日本語件名を生成

抽出された英語コミットに対して、以下のルールで日本語件名を生成する：

1. **Conventional Commit の type はそのまま保持**: `feat`, `fix`, `docs` 等
2. **emoji プレフィックスも保持**: `✨`, `🐛`, `📝` 等
3. **件名（subject）のみ日本語化**: type/emoji の後の説明部分
4. **PR番号・ISSUE番号は保持**: `(#1)`, `(ISSUE 005)` 等
5. **[BEHAVIORAL]/[STRUCTURAL] タグは保持**

### Step 3: 出力形式

markdown テーブルで出力する：

```markdown
| hash | 現在のメッセージ | 日本語案 |
|------|----------------|---------|
| `abc1234` | feat: add user auth | ✨ feat: ユーザー認証を追加 |
```

## Examples

### Example 1: 英語コミットの翻訳一覧

User says: "コミットを日本語にして"

Actions:
1. `./scripts/translate-commits.sh -f markdown` を実行
2. 英語コミットに対する日本語訳を生成
3. markdown テーブルで提示

Result: 翻訳候補の一覧テーブル

### Example 2: 特定の件数

User says: "直近20コミットを翻訳"

Actions:
1. `./scripts/translate-commits.sh -n 20 -f markdown` を実行
2. 日本語訳を生成

## Translation Guidelines

- 技術用語（Terraform, GCP, K8s 等）はそのまま英語で残す
- 動詞は体言止めか「〜を追加」「〜を修正」の形にする
- 簡潔さを優先（原文より短くてもOK）

## Troubleshooting

### スクリプトが見つからない場合
`git log --format="%h%x09%s" -50` で直接取得し、手動でテーブル生成。

### 日本語コミットと英語コミットの混在
`-a` フラグで全コミットを出力し、英語のみフィルタリング。

### Conventional Commit 形式でないコミットがある場合
type なしのコミットはそのまま日本語化。type の推定は行わない。
