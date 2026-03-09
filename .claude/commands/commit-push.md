---
description: "変更内容を分析し、Conventional Commit形式でコミットしてpushする"
argument-hint: "[--no-push]"
---

# /commit-push

Task tool で `commit-pusher` サブエージェントを起動してコミット＆プッシュを実行。

- Conventional Commit の `type` は `feat` / `fix` など標準の英語表記を使う
- コミットメッセージの件名と本文は日本語で作成する

- 引数なし → コミット後にプッシュ
- `--no-push` → コミットのみ

引数 `$1` をそのまま commit-pusher に渡す。
