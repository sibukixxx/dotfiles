---
description: "自律改善ループを実行（QA -> Fix -> Refactor）。時間/ラウンド上限、差分上限、critical pathレビュー待ち、E2E自動revert、朝用レポート出力を有効化"
argument-hint: "[minutes|--rounds N] [--max-changed-files N] [--max-diff-lines N]"
---

# /improve

`improve` コマンドを実行して、自律改善ループを開始する。

## 使い方

```bash
/improve 120
/improve --rounds 5
/improve 120 --rounds 5 --max-changed-files 30 --max-diff-lines 1200
```

## 実行手順

0. 実行前に git working tree が clean であることを確認する。

1. Bashで以下を実行:

```bash
improve $ARGUMENTS
```

2. 実行完了後、`reports/improve-YYYYMMDD.md` を開いて結果を要約する。

3. `waiting_human_review_critical_path` で停止していたら、その変更を先に人間レビューへ回す。
