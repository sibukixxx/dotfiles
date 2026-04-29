# 7つの絶対ルール（詳細）

## 1. DBスキーマ変更は必ず migration SQL として作る

**やってはいけないこと**：
- 本番DBやstaging DBに `psql` / `mysql` / `wrangler d1 execute` で直接 DDL を流す
- 「ちょっと試すだけ」で `ALTER TABLE` を手動実行する
- ORM の auto-migrate / `synchronize: true` 機能で本番スキーマを変更する

**やること**：
- すべてのスキーマ変更は **バージョン番号付きの SQL ファイル** として作成
- ファイル名規則: `<連番4桁>_<snake_case_description>.sql`
- migration ツール（Prisma Migrate / Drizzle / Flyway / Liquibase / wrangler d1 migrations / sqlx migrate / Alembic 等）の規約に従う

## 2. migration ファイルは Git 管理する

- migration ファイルは **コードと一緒に PR レビューする**
- `.gitignore` に migration ディレクトリを入れない
- **一度 main にマージされた migration ファイルは絶対に編集・削除しない**
  - 履歴の整合性が崩れる
  - 既に staging/production に適用済みのチームメンバーがいる場合、再適用できなくなる
- 修正が必要なら新しい migration（forward-only）で対応する

## 3. local → staging → production の順に適用する

```
[local 開発機]  →  [staging / preview]  →  [production]
     ↓                  ↓                       ↓
  毎回流す         PRマージ前に流す         手順書に従って流す
```

- どの環境にもまず local で適用してテストが通ることを確認
- staging で **実データに近いボリューム** で適用、アプリの動作確認
  - 件数が少ない staging では検出できない問題（ロック時間、index 効果）がある
- production は最後。staging で問題なかったものだけ流す

## 4. production に直接 SQL を流さない

**禁止**：
- `psql production-db -c "ALTER TABLE ..."` を手元から実行
- 管理画面（phpMyAdmin、Cloud SQL Studio 等）から直接 DDL
- migration ツールを介さずに本番DBを変更

**推奨**：migration ツールの公式コマンドで適用

| ツール | 適用コマンド |
|--------|------------|
| Cloudflare D1 | `wrangler d1 migrations apply <DB> --remote` |
| Prisma | `pnpm prisma migrate deploy` |
| Drizzle | `pnpm drizzle-kit migrate` |
| Flyway | `flyway -environments=production migrate` |
| Liquibase | `liquibase update` |
| Rails | `bundle exec rails db:migrate RAILS_ENV=production` |
| Alembic (Python) | `alembic upgrade head` |
| sqlx (Rust) | `sqlx migrate run` |
| golang-migrate | `migrate -path ./migrations -database "$DB_URL" up` |

CI/CD 経由で自動適用するのが望ましい（デプロイの一部として）。

## 5. 破壊的変更は原則避ける

**破壊的変更**とは：
- 既存データを失う
- 旧コードと互換性がなくなる
- 既存の制約に違反する

**避けるべき変更**：
- `DROP COLUMN` / `DROP TABLE` の即時実行
- `ALTER COLUMN` で型を非互換に変える
  - 例: `VARCHAR(255)` → `INT`、`TEXT` → `JSON`
- 列名・テーブル名の rename（旧名で動いているコードが落ちる）
- `NOT NULL` 制約を default なしで追加（既存行が違反する）
- `UNIQUE` 制約を後付け追加（重複行があると失敗）
- 大量行に対する `ALTER TABLE`（ロックでサービス停止）

**段階的（multi-step）デプロイ**：

```
[Phase 1] 新カラム追加（NULL許可・defaultあり）
          + アプリの読み書きを両対応に
[Phase 2] backfill migration で既存データを補填
[Phase 3] アプリを新カラムのみ参照に切り替え
[Phase 4] 旧カラムを deprecated にして放置（数週間〜数ヶ月）
[Phase 5] 旧カラムを DROP（別 migration）
```

ロックを伴う操作の対策：
- PostgreSQL: `CREATE INDEX CONCURRENTLY`
- MySQL: `pt-online-schema-change` / `gh-ost`
- 大規模 batch update: 1万行ずつ chunked update

## 6. rollback 前提ではなく forward-only で設計する

**やってはいけない発想**：
- 「ダメだったら down migration で戻せばいい」前提で本番に流す

**正しい発想（forward-only）**：
- 一度適用した migration は戻さない
- 戻すなら **新しい migration で打ち消す**

**理由**：
- down migration は **データを失う**ことが多い（`DROP COLUMN` で戻す等）
- 本番DBは不可逆な状態を持つ
- 複数replica やレプリケーションがあると down は破滅的
- そもそも down が複雑で正しく書けることは稀
- production に down を流す経路がそもそも危険

**例外**：ローカル開発時の試行錯誤では down を使ってよい。本番には適用しない。

## 7. 本番適用前に backup / export / staging 検証を必ず行う

production に migration を流す前のチェックリスト：

- [ ] **バックアップ取得済み**
  - フルバックアップ
  - or point-in-time recovery が有効
  - or `pg_dump` / `mysqldump` / D1 export で snapshot
- [ ] **staging で同じ migration を適用して問題なかった**
- [ ] **staging で実データボリュームに近いデータで実行時間を計測した**
  - 巨大テーブルは特に重要
- [ ] **巻き戻し手順をドキュメント化した**（forward-only でも対応 SQL は用意）
- [ ] **アプリのデプロイ順序を決めた**
  - migration → app（後方互換変更の場合）
  - app → migration（新カラムを使う場合は両対応で先にデプロイ）
- [ ] **大規模テーブルは低トラフィック時間帯に流す**
- [ ] **適用直後に動作確認するクエリ・画面を決めた**
- [ ] **チーム / オンコールに告知した**
