---
description: "commit, push, PR作成, mergeまで一括実行する"
argument-hint: "[--squash|--rebase|--merge] [--draft] [--no-merge]"
---

# /ship

Task tool で `shipper` サブエージェントを起動して、commit → push → PR作成 → merge を一括実行。

- 引数なし → squash merge でマージまで実行
- `--squash` → squash merge（デフォルト）
- `--rebase` → rebase merge
- `--merge` → 通常の merge commit
- `--draft` → Draft PR を作成（マージはしない）
- `--no-merge` → PR 作成まで（マージしない）

引数 `$ARGUMENTS` をそのまま shipper に渡す。
