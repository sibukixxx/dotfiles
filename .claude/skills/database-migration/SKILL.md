---
name: database-migration
description: |
  データベースマイグレーションの設計・運用ルールを適用するスキル。
  DBスキーマ変更を扱うとき（CREATE TABLE / ALTER TABLE / DROP COLUMN /
  index 追加 / カラム rename 等）、production DB への適用、
  migrations/ ディレクトリの構成、forward-only 設計の検討時に必ず使用する。
  「マイグレーション作って」「ALTERしたい」「カラム追加したい」「DBスキーマ変更」
  「migration」「db migrate」「prisma migrate」「wrangler d1 migrations」
  「flyway」「alembic」「rails db:migrate」などで発動。
trigger:
  - "マイグレーション"
  - "migration"
  - "db migrate"
  - "DBスキーマ変更"
  - "スキーマ変更"
  - "ALTER TABLE"
  - "CREATE TABLE"
  - "DROP COLUMN"
  - "カラム追加"
  - "カラム削除"
  - "index追加"
  - "prisma migrate"
  - "wrangler d1 migrations"
  - "flyway"
  - "alembic"
  - "rails db:migrate"
  - "drizzle"
  - "sqlx migrate"
references:
  - references/seven-rules.md
  - references/directory-layout.md
  - references/destructive-change-playbook.md
---

# Database Migration Skill

DBスキーマ変更は本番障害・データ消失の最大リスク領域。
このスキルは **「7つの絶対ルール」** をユーザーの作業に適用する。

> グローバルルール本体: `~/dotfiles/.claude/rules/core/database-migration.md`

## 7つの絶対ルール（要約）

1. **DBスキーマ変更は必ず migration SQL として作る**（手動 ALTER 禁止）
2. **migration ファイルは Git 管理する**（マージ後の編集禁止）
3. **local → staging → production の順に適用する**
4. **production に直接 SQL を流さない**（migration ツール経由のみ）
5. **破壊的変更は原則避ける**（段階的デプロイで安全に）
6. **rollback 前提ではなく forward-only で設計する**
7. **本番適用前に backup / export / staging 検証を必ず行う**

詳細は `references/seven-rules.md` 参照。

## このスキルの使い方

### Step 1: 状況の特定

ユーザーが何をしたいか確認する：

- 新規テーブル作成 → §A
- カラム追加 → §B
- カラム削除・rename・型変更 → §C（破壊的変更）
- index 追加 → §D
- データ補填（backfill）→ §E
- production への適用 → §F

### Step 2: ディレクトリ構成の確認

プロジェクトの migration ディレクトリを確認：

```bash
# よくある場所
ls migrations/
ls db/migrate/        # Rails
ls prisma/migrations/ # Prisma
ls drizzle/           # Drizzle
ls src/migrations/    # 各種
```

ない場合は `references/directory-layout.md` のパターンから選んで提案。

### Step 3: 既存 migration の連番を確認

```bash
ls migrations/ | sort | tail -5
```

最後の連番 + 1 を新規ファイルの番号にする。

### Step 4: migration ファイルを作成

ファイル名規則：
```
<連番4桁>_<動詞>_<対象>.sql
```

ファイル先頭にメタ情報を書く：
```sql
-- migration: 0042_add_campaign_status
-- author: <ユーザー>
-- date: <YYYY-MM-DD>
-- purpose: <なぜこの変更が必要か>
-- safety: <後方互換性 / ロック / データ影響>
-- rollback: forward-only（撤回するなら新しい migration で）
```

### Step 5: 安全性チェック

- [ ] 後方互換か？（旧コードでも動くか）
- [ ] ロック時間は許容範囲か？（巨大テーブルは要注意）
- [ ] 既存データに違反する制約を入れていないか？
- [ ] アプリのデプロイ順序を決めたか？

### Step 6: production 適用前チェックリスト

詳細は `references/seven-rules.md` の「§7」参照。

## §A. 新規テーブル作成

```sql
-- migration: 0042_create_wallet_tables
CREATE TABLE wallets (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  balance INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX idx_wallets_user_id ON wallets(user_id);
```

注意：
- 主キー・必須カラム・タイムスタンプを最初から入れる
- 後から追加するより最初から正しく作るほうが安全

## §B. カラム追加（基本は安全）

```sql
-- migration: 0043_add_campaign_status
ALTER TABLE campaigns
  ADD COLUMN status TEXT NOT NULL DEFAULT 'active';
```

注意：
- `NOT NULL` で追加するなら **必ず default を指定**（既存行が違反する）
- 巨大テーブルでは `DEFAULT` 指定が full table rewrite を起こす DB がある（PostgreSQL 11+ は不要）

## §C. 破壊的変更（要・段階的デプロイ）

詳細は `references/destructive-change-playbook.md` 参照。

```
[Phase 1] 新カラム追加 + アプリの読み書きを両対応に
[Phase 2] backfill migration で旧→新にデータコピー
[Phase 3] アプリを新カラムのみ参照に切り替え
[Phase 4] 旧カラムを deprecated（コード上では参照しない）
[Phase 5] 後日、旧カラムを DROP（別 migration）
```

## §D. index 追加

```sql
-- PostgreSQL: ロック回避
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- MySQL: pt-online-schema-change を検討
-- SQLite / Cloudflare D1: 通常の CREATE INDEX
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

## §E. データ補填（backfill）

DDL とは **別の migration ファイル** に分ける：

```sql
-- migration: 0044_backfill_user_locale
UPDATE users SET locale = 'ja' WHERE locale IS NULL;
```

巨大テーブルは batch で処理（1万行ずつ等）。

## §F. production への適用

migration ツール経由で実行：

| ツール | コマンド |
|--------|---------|
| Cloudflare D1 | `wrangler d1 migrations apply <DB> --remote` |
| Prisma | `pnpm prisma migrate deploy` |
| Drizzle | `pnpm drizzle-kit migrate` |
| Flyway | `flyway -environments=production migrate` |
| Rails | `bundle exec rails db:migrate RAILS_ENV=production` |
| Alembic | `alembic upgrade head` |
| sqlx | `sqlx migrate run` |

**直接 SQL を流すコマンド（`wrangler d1 execute --remote --command "..."` 等）は使わない**。

## アンチパターン警告

ユーザーが以下をしようとしていたら止める：

- 「ちょっとだけ ALTER TABLE 流したい」 → migration ファイルを作って
- 「down migration で戻せばいい」 → forward-only にして
- 「production に直接接続して試す」 → staging でやって
- 「マージ済みの migration を直接書き換える」 → 新しい migration を作って
- 「ORM の auto-migrate を本番で使う」 → 明示的な migration ツールに切り替えて
