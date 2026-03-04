---
name: autonomous-improve-loop
description: QA -> Fix -> Refactor の3フェーズを1ラウンドとして自律改善を回すスキル。時間指定（例: improve 120）またはラウンド指定（例: improve --rounds 5）で実行し、変更上限・critical pathレビュー待ち・E2E安全網・日次サマリ保存まで行う。
---

# Autonomous Improve Loop

夜間などの無人時間に、`QA -> Fix -> Refactor` を自動反復して不具合削減と品質改善を進める。

## 主要仕様

1. 停止条件
- 指定分数を超えた
- 指定ラウンド数に達した
- open issue が 0（取得できる場合）

2. 安全網
- `--max-changed-files` と `--max-diff-lines` を超えたら停止
- critical path（`--critical-path`）変更を検知したら人間レビュー待ちで停止
- Refactor後に E2E が壊れたら自動revert

3. 観測
- 各ラウンドで before/after 指標を記録
  - open issue数
  - failed E2E数
  - 変更LOC
- 最終サマリを `reports/improve-YYYYMMDD.md` に保存

## 実行

```bash
improve 120
improve --rounds 5
improve 120 --rounds 5 --max-changed-files 30 --max-diff-lines 1200
```

実行前提:
- git working tree が clean であること（未コミット差分がある場合は実行停止）

## フェーズコマンドの指定

実行ロジックはスクリプトで行い、各フェーズはコマンドで差し替える。

```bash
improve 120 \
  --qa-cmd "./scripts/improve-qa.sh" \
  --fix-cmd "./scripts/improve-fix.sh" \
  --refactor-cmd "./scripts/improve-refactor.sh" \
  --e2e-cmd "npm run test:e2e" \
  --issue-count-cmd "gh issue list --state open --json number --limit 500 | jq 'length'"
```

補足:
- `--issue-count-cmd` 未指定時は `gh issue list` を自動で試す
- `--e2e-cmd` 未指定時は `npm run test:e2e` / `pnpm test:e2e` / `make e2e` を自動探索
- `--qa-cmd` / `--fix-cmd` / `--refactor-cmd` 未指定時は `scripts/improve-*.sh` を探索（なければ `true`）
