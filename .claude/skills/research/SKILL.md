---
name: research
description: Web検索を実行し、調査結果をObsidianノート形式で保存するリサーチツール。「〇〇について調べて」「〇〇をリサーチして」「〇〇の情報を集めて」「research 〇〇」などのリクエストで発動。検索結果を構造化されたマークダウンノートとして出力する。
---

# Research Skill

Web検索結果をObsidianノート形式で保存する調査支援ツール。

## Workflow

1. **検索実行**: WebSearchツールでトピックを検索
2. **情報収集**: 関連性の高い結果から詳細を取得（必要に応じてWebFetch）
3. **構造化**: 収集した情報をノート形式に整理
4. **保存**: Obsidian形式でnotes/docs/に保存

## Output Format

ノートは以下の形式で出力:

```markdown
---
title: "[トピック名] - 調査メモ"
created: YYYY-MM-DD
type: research
query: "検索クエリ"
tags:
  - research
  - [関連タグ]
sources:
  - url: "ソースURL"
    title: "ページタイトル"
draft: false
---

## 概要

[トピックの要約を1-2段落で]

## 主要な発見

### [発見1のタイトル]

[詳細な説明]

### [発見2のタイトル]

[詳細な説明]

## 情報源

- [タイトル1](URL1) - 概要
- [タイトル2](URL2) - 概要

## 関連トピック

- [[関連ノート1]]
- [[関連ノート2]]

## メモ

[追加の考察やアクションアイテム]
```

## File Naming

ファイル名: `{topic}-調査.md`
- スペースはハイフンに置換
- 日本語OK、特殊文字は除去

例: `Claude-Code-Skills-調査.md`

## Save Location

デフォルト: `notes/docs/records/`

ユーザーが別の場所を指定した場合はそちらに保存。

## Search Strategy

1. **初回検索**: トピック全体で検索
2. **深掘り**: 重要なサブトピックがあれば追加検索
3. **検証**: 複数ソースで情報を確認

検索は最大3回まで。情報が十分であれば早めに切り上げる。

## Quality Checklist

- [ ] 概要が簡潔にまとまっているか
- [ ] 情報源が明記されているか
- [ ] frontmatterが正しい形式か
- [ ] 関連ノートへのリンクがあるか
