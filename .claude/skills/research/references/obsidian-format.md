# Obsidian Note Format Reference

このプロジェクト（idea/）のノート形式ルール。

## 必須 Frontmatter

```yaml
---
title: ノートのタイトル
created: 2025-01-31
tags:
  - tag1
  - tag2
draft: false
---
```

## 調査ノート用 Frontmatter

```yaml
---
title: "[トピック名] - 調査メモ"
created: 2025-01-31
type: research
query: "検索クエリ"
tags:
  - research
sources:
  - url: "URL"
    title: "タイトル"
draft: false
---
```

## Wikilinks

```markdown
[[ノート名]]                    → リンク
[[ノート名|表示テキスト]]        → エイリアス付き
[[projects/プロジェクト名]]     → フォルダ指定
```

## 保存場所

| ディレクトリ | 用途 |
|-------------|------|
| notes/docs/records/ | 調査記録（デフォルト） |
| notes/docs/howto/ | 手順書 |
| notes/inbox/ | 未整理 |
