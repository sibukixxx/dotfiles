---
name: sentry-batch-fix
description: Sentry APIからエラー/不具合を収集・分析し、Claude Codeのbatch機能で優先度順に一括改善する運用スキル。ユーザーが「Sentryで不具合分析」「エラーをまとめて直したい」「batchで一気に改善したい」と言ったときに使用する。
---

# Sentry Batch Fix

SentryのIssue/EventをAPIで取得し、再現条件と影響範囲を整理して、Claude Codeの`/batch`で修正タスクを一気に回す。

## 前提

1. `SENTRY_AUTH_TOKEN`（`project:read`, `event:read`, `org:read` 推奨）を設定
2. `SENTRY_ORG` を設定
3. 必要なら `SENTRY_PROJECTS`（カンマ区切り）を設定
4. `jq` が使えること

## Workflow

### Step 1: Sentry から不具合を収集

`scripts/sentry-export-issues.sh` を実行し、Issue一覧をJSONで保存する。

```bash
bash .claude/skills/sentry-batch-fix/scripts/sentry-export-issues.sh \
  --days 14 \
  --limit 100 \
  --query "is:unresolved level:error"
```

出力:
- `.tmp/sentry/issues_raw.json`
- `.tmp/sentry/issues_ranked.json`

### Step 2: 優先度を決める

`issues_ranked.json` の上位から対応する。優先順位は以下。

1. `isUnhandled=true` かつ `level=error|fatal`
2. `count`（発生数）が多い
3. `userCount`（影響ユーザー）が多い
4. 直近発生 (`lastSeen`) が新しい

### Step 3: 修正単位を作る

Issueごとに以下を整理して修正タスク化する。

1. エラー名・スタックトレース先頭
2. 発生条件（endpoint, browser/os, release）
3. 影響範囲（ユーザー数、主要機能）
4. 修正案（防御コード、入力検証、リトライ、フォールバック）
5. 回帰テスト案

### Step 4: Claude Code `/batch` で一括修正

バッチ入力では、Issue単位で「再現条件」「修正対象ファイル」「受け入れ条件」を明記する。

```text
/batch
対象: sentry top 10 issues
共通ルール:
- 既存仕様を壊さない
- 各Issueで再現テストか回帰テストを追加
- 変更ごとに影響範囲とロールバック手順を記載

Issue-1: <id/title>
- 症状:
- 主要スタック:
- 修正対象:
- 受け入れ条件:
...
```

### Step 5: リリース後検証

1. 修正Issueの `firstSeen/lastSeen` と再発を確認
2. release健康度（crash-freeやerror rate）を比較
3. 再発Issueを次バッチに繰り越し

## 実行ルール

- まず再現または失敗テストを作ってから修正する
- 高頻度Issueは暫定回避策（guard/fallback）を先に入れる
- API起因の不具合はタイムアウト・リトライ・サーキットブレーカを検討
- 分析結果に推測を含むときは「推測」と明示する

