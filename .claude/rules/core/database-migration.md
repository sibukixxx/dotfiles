# データベースマイグレーション運用ルール

DBスキーマの変更は本番障害・データ消失の最大リスク領域の一つ。
**マイグレーションを軽く扱うとサービスが落ちる**ので、以下を必ず守る。

## 7つの絶対ルール

### 1. DBスキーマ変更は必ず migration SQL として作る

❌ 本番DBやstaging DBに `psql` / `mysql` / `wrangler d1 execute` で直接 DDL を流す
❌ 「ちょっと試すだけ」で `ALTER TABLE` を手動実行する
❌ ORM の auto-migrate / `sync: true` 機能で本番スキーマを変更する

✅ すべてのスキーマ変更は **バージョン番号付きの SQL ファイル** として作成する
✅ ファイル名規則: `<連番4桁>_<snake_case_description>.sql`（例: `0001_create_wallet_tables.sql`）
✅ migration ツール（Prisma Migrate / Drizzle / Flyway / Liquibase / wrangler d1 migrations / sqlx migrate / Alembic 等）の規約に従う

### 2. migration ファイルは Git 管理する

- migration ファイルは **コードと一緒に PR レビューする**
- `.gitignore` に migration ディレクトリを入れない
- 一度 main にマージされた migration ファイルは **絶対に編集・削除しない**（履歴の整合性が崩れる）
- 修正が必要なら新しい migration（forward-only）で対応する

### 3. local → staging → production の順に適用する

```
[local 開発機] → [staging / preview env] → [production]
     ↓                ↓                       ↓
  毎回流す      PRマージ前に流す         手順書に従って流す
```

- どの環境にもまず local で適用してテストが通ることを確認
- staging で実データに近いボリュームで適用、アプリの動作確認
- production は最後。staging で問題なかったものだけ流す

### 4. production に直接 SQL を流さない

❌ `psql production-db -c "ALTER TABLE ..."` を手元から実行する
❌ 管理画面の SQL コンソールから直接 DDL を打つ
❌ migration ツールを介さずに本番DBを変更する

✅ migration ツールの公式コマンドで適用する
- `wrangler d1 migrations apply <DB> --remote`
- `pnpm prisma migrate deploy`
- `flyway migrate -environments=production`
- `bundle exec rails db:migrate RAILS_ENV=production`
- `alembic upgrade head`

✅ CI/CD 経由で自動適用するのが望ましい（デプロイの一部として）

### 5. 破壊的変更は原則避ける

破壊的変更 = 既存データを失う、もしくは旧コードと互換性がなくなる変更。

❌ 避けるべき：

- `DROP COLUMN` / `DROP TABLE`（即時実行）
- `ALTER COLUMN` で型を非互換に変える（例: `VARCHAR(255)` → `INT`）
- 列名・テーブル名の rename（旧名で動いているコードが落ちる）
- `NOT NULL` 制約を default なしで追加（既存行が違反する）
- 大量行に対する index 作成・`ALTER TABLE`（ロックでサービス停止）

✅ 段階的（multi-step）デプロイで安全にやる：

```
[Phase 1] 新カラム追加（NULL許可・defaultあり）+ アプリの読み書きを両対応に
[Phase 2] 既存データを backfill
[Phase 3] アプリを新カラムのみ参照に切り替え
[Phase 4] 旧カラムを deprecated にして放置（数週間〜数ヶ月）
[Phase 5] 旧カラムを DROP
```

ロックを伴う操作は `CONCURRENTLY` (Postgres) や `pt-online-schema-change` (MySQL) を検討。

### 6. rollback 前提ではなく forward-only で設計する

❌ 「ダメだったら down migration で戻せばいい」という前提で本番に流す
✅ **forward-only**: 一度適用した migration は戻さない、戻すなら新しい migration で打ち消す

理由：
- down migration は **データを失う**ことが多い（`DROP COLUMN` で戻す等）
- 本番DBは不可逆な状態を持つ。複数replicaやレプリケーションがあると down は破滅的
- そもそも down が複雑で正しく書けることは稀

例外: ローカル開発時の試行錯誤では down を使ってよい。**本番には適用しない**。

### 7. 本番適用前に backup / export / staging 検証を必ず行う

production に migration を流す前のチェックリスト：

- [ ] **バックアップ取得済み**（フルバックアップ or point-in-time recovery が有効）
- [ ] **staging で同じ migration を適用して問題なかった**
- [ ] **staging で実データボリュームに近いデータで実行時間を計測した**（巨大テーブルは要注意）
- [ ] **巻き戻し手順をドキュメント化した**（forward-only でも対応 SQL は用意）
- [ ] **アプリのデプロイ順序を決めた**（migration → app or app → migration）
- [ ] **大規模テーブルは低トラフィック時間帯に流す**
- [ ] **適用直後に動作確認するクエリ・画面を決めた**

## ディレクトリ構成パターン

### 単一アプリ

```
my-app/
  src/
  migrations/
    0001_create_users.sql
    0002_add_user_email_index.sql
    0003_create_orders.sql
  package.json
```

### モノレポ（Cloudflare D1 / マルチアプリ）

```
repo-root/
  migrations/                     # コア / 共通スキーマ
    0001_core_init.sql
    0002_wallet_plugin_tables.sql
    0003_campaign_plugin_tables.sql
  emdash-site/
    src/
    migrations/                   # アプリ固有のマイグレーション
      0001_create_wallet_tables.sql
      0002_add_campaign_status.sql
      0003_add_campaign_indexes.sql
    wrangler.jsonc
    package.json
```

ポイント：
- ルート `migrations/` = 全アプリ共通の骨格（初期テーブル、プラグイン共通テーブル）
- アプリ配下 `<app>/migrations/` = そのアプリ・機能固有の追加変更
- 連番はディレクトリごとに独立（衝突しないようツール側で管理）

### ファイル命名規則

```
<連番4桁>_<動詞>_<対象>.sql
```

| 動詞 | 用途 |
|------|------|
| `create` | 新規テーブル/index作成 |
| `add` | カラム/制約/index追加 |
| `drop` | 削除（最終フェーズのみ） |
| `rename` | リネーム |
| `backfill` | データ補填（DDL なし） |
| `alter` | 型変更等 |

例：
- `0042_add_campaign_status.sql`
- `0043_create_wallet_tables.sql`
- `0044_backfill_user_locale.sql`

## migration ファイルの中身ガイドライン

```sql
-- migration: 0042_add_campaign_status
-- author: sibukixxx
-- date: 2026-04-29
-- purpose: campaigns テーブルに status カラムを追加（active/paused/ended）
-- safety: 後方互換あり。default 'active' を入れて NULL不可にする。
-- rollback: forward-only。撤回は次の migration で DROP COLUMN すること。

ALTER TABLE campaigns
  ADD COLUMN status TEXT NOT NULL DEFAULT 'active';

CREATE INDEX idx_campaigns_status ON campaigns(status);
```

ポイント：
- 何のための変更か **意図** をコメントで残す
- 1ファイル1関心事（複数の関係ない変更を混ぜない）
- ロック時間が長くなる操作は明示する

## 緊急時のホットフィックス

production で migration 起因の障害が起きたとき：

1. **まず影響範囲を特定**（どのテーブル / どのクエリ / どの API）
2. **アプリ側のロールバック** で済むなら、まずアプリを戻す（DBは触らない）
3. DBを戻す必要があるなら **新しい forward migration を書く**
4. 障害ポストモーテムを残す（同じ事故を防ぐため）

## チェックリスト（PR レビュー時）

- [ ] migration ファイルが追加されているか（手動 SQL になっていないか）
- [ ] ファイル名の連番が衝突していないか
- [ ] 一度マージされた既存 migration を編集していないか
- [ ] 破壊的変更が含まれる場合、段階的デプロイ計画があるか
- [ ] backfill が必要なら backfill migration が分離されているか
- [ ] ロック時間が長くなりそうなら staging で計測したか
- [ ] アプリ側コードが migration 適用前後の両方の状態で動くか
