---
description: "/address の対応結果を PR の各レビューコメントに返信する。投稿前に必ず返信一覧をユーザーに提示する"
argument-hint: "[PR番号 | PR URL]"
allowed-tools: ["Bash(gh api:*)", "Bash(gh pr:*)", "Read", "AskUserQuestion"]
---

# /reply-review - レビューコメントへの返信

`/address` でレビュー対応を終えたあと、各コメントに「対応した」「対応不要と判断した」旨を返信する。

## 使い方

```
/reply-review           # 直前の会話のレビュー対応サマリーと PR 情報を使う
/reply-review 123       # PR #123
/reply-review <PR URL>  # URL から番号を抽出
```

## 前提

- `/address` による対応が完了していること
- 直前の会話に「レビュー対応サマリー」（対応した指摘 / 対応しなかった指摘）があること

## 手順

1. PR 番号を特定する（引数、無ければ直前の会話や `gh pr view` から）
2. 直前の会話からレビュー対応サマリーを取り出す
3. レビューコメント一覧を取得する
   - `gh api repos/{owner}/{repo}/pulls/<番号>/comments` — インラインコメント
   - `gh api repos/{owner}/{repo}/pulls/<番号>/reviews` — レビュー本文
4. コメントごとに、サマリーを元に返信文を作る
5. **返信一覧をユーザーに提示し、承認を得てから**投稿する
6. `gh api` で投稿する

## 返信の形式

対応した指摘:

```
修正しました。<修正内容の簡潔な説明>

（Claude Code による返信）
```

対応不要と判断した指摘:

```
確認しましたが、以下の理由により現状維持としました。

<理由>

（Claude Code による返信）
```

## 返信 API

インラインコメントへの返信:

```bash
gh api repos/{owner}/{repo}/pulls/<番号>/comments/<comment_id>/replies -f body="返信内容"
```

レビュー本文（全体コメント）への返信:

```bash
gh api repos/{owner}/{repo}/issues/<番号>/comments -f body="返信内容"
```

## 注意

- 返信は外部に公開される。承認なしに投稿しない
- 既に返信済みのコメントには重複して返信しない
- 絵文字は使わない
