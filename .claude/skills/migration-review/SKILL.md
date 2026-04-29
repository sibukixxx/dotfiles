---
name: migration-review
description: Use when creating, reviewing, or modifying goose SQL migration files in migrates/ directory. Also use when PR contains migration changes, or when asked to check migration safety for zero-downtime deployment.
---

# Migration Review

## Overview

goose SQL マイグレーションファイルを `docs/development_zero_downtime_migrations.md` のガイドラインに基づきレビューし、ゼロダウンタイムデプロイを阻害する操作を検出する。

## When to Use

- `migrates/*.sql` ファイルが新規作成・変更されたとき
- PR に含まれるマイグレーションファイルのレビュー
- `make create-table` / `make create-migration` 後の安全性チェック

## When NOT to Use

- マイグレーション以外の SQL ファイル（seed データ等）
- Go コード内の SQL クエリレビュー

## 検出ルール

### 🔴 CRITICAL — 即座にブロック

| ID  | パターン                                     | 検出方法                                                                                    | 安全な代替                                               |
| --- | -------------------------------------------- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| C1  | `CREATE INDEX` without `CONCURRENTLY`        | `CREATE\s+(UNIQUE\s+)?INDEX\s+(?!CONCURRENTLY)` かつ `-- +goose no transaction` なし        | `CREATE INDEX CONCURRENTLY` + `-- +goose no transaction` |
| C2  | `DROP INDEX` without `CONCURRENTLY`          | `DROP\s+INDEX\s+(?!CONCURRENTLY)`                                                           | `DROP INDEX CONCURRENTLY` + `-- +goose no transaction`   |
| C3  | `RENAME TABLE` / `ALTER TABLE ... RENAME TO` | `RENAME\s+TO` on table                                                                      | 新テーブル + デュアルライト + 切り替え                   |
| C4  | `RENAME COLUMN`                              | `RENAME\s+COLUMN`                                                                           | 新カラム + デュアルライト + 切り替え                     |
| C5  | スキーマ変更 + データ更新の混在              | 同一ファイル内に DDL (`ALTER TABLE`, `CREATE`) と DML (`UPDATE`, `INSERT`, `DELETE`) が共存 | 別マイグレーションに分離                                 |
| C6  | `REINDEX` without `CONCURRENTLY`             | `REINDEX\s+(?!.*CONCURRENTLY)`                                                              | `REINDEX ... CONCURRENTLY` (PG 12+)                      |
| C7  | `ALTER COLUMN TYPE` (テーブル書き換え)       | `ALTER\s+COLUMN\s+\w+\s+(SET\s+DATA\s+)?TYPE` で安全な変換でないもの                        | 新カラム + デュアルライト                                |

### 🟡 WARNING — 手順確認が必要

| ID  | パターン                                                | 検出方法                                                          | 確認事項                                           |
| --- | ------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------- | --- | ----------------- | --------------- | -------------- | ------------------------------------------------- |
| W1  | `ADD CONSTRAINT ... FOREIGN KEY` without `NOT VALID`    | `FOREIGN KEY.*REFERENCES` で `NOT VALID` なし                     | `NOT VALID` + 別トランザクションで `VALIDATE`      |
| W2  | `ADD CONSTRAINT ... CHECK` without `NOT VALID`          | `CHECK\s*\(` で `NOT VALID` なし (ただし `CREATE TABLE` 内は除外) | `NOT VALID` + 別トランザクションで `VALIDATE`      |
| W3  | `ALTER COLUMN SET NOT NULL` without CHECK 制約          | `SET\s+NOT\s+NULL`                                                | CHECK 制約 → VALIDATE → SET NOT NULL の3段階       |
| W4  | `ADD COLUMN ... DEFAULT <揮発性値>`                     | `DEFAULT\s+(gen_random_uuid                                       | uuid_generate_v7                                   | now | current_timestamp | clock_timestamp | random)\s\*\(` | カラム追加 + デフォルト設定 + バックフィルの3段階 |
| W5  | `ADD CONSTRAINT ... UNIQUE` (非 USING INDEX)            | `ADD\s+CONSTRAINT.*UNIQUE\s*\(` で `USING\s+INDEX` なし           | `CREATE UNIQUE INDEX CONCURRENTLY` + `USING INDEX` |
| W6  | 大量 UPDATE (WHERE なし or 全行対象)                    | `UPDATE\s+\w+\s+SET` でバッチ制御なし                             | バッチ処理に分割                                   |
| W7  | `CONCURRENTLY` 使用時に `-- +goose no transaction` なし | `CONCURRENTLY` があるが `no transaction` ディレクティブなし       | `-- +goose no transaction` を追加                  |
| W8  | 複数テーブルへの DDL が1トランザクション                | 同一ファイル内で異なるテーブルの `ALTER TABLE` が複数             | 各テーブルへの変更を別マイグレーションに分離       |
| W9  | `lock_timeout` の設定なし                               | `ACCESS EXCLUSIVE` ロックが必要な操作で `SET lock_timeout` なし   | `SET lock_timeout = '2s'` を追加                   |

### 🟢 INFO — 確認推奨

| ID  | パターン                   | 確認事項                                                                     |
| --- | -------------------------- | ---------------------------------------------------------------------------- |
| I1  | `DROP TABLE`               | コードからテーブル参照が全て削除されているか                                 |
| I2  | `DROP COLUMN`              | コードからカラム参照が全て削除されているか、依存インデックスが削除済みか     |
| I3  | `ALTER TYPE ... ADD VALUE` | `-- +goose no transaction` が必要か確認（PG 12未満はトランザクション内不可） |

## 実行手順

### Step 1: 対象ファイルの特定

```bash
# 引数で指定された場合はそのファイル
# 指定なしの場合は最近の変更を対象にする
git diff --name-only HEAD~5 | grep 'migrates/.*\.sql$'
# または未コミットの変更
git status --porcelain | grep 'migrates/.*\.sql$'
```

対象が見つからない場合はユーザーに確認する。

### Step 2: 各ファイルをレビュー

対象ファイルを Read で読み込み、上記の検出ルール全てに対してチェックする。

**チェック順序:**

1. `-- +goose no transaction` ディレクティブの有無を確認
2. CRITICAL ルール (C1-C7) をチェック
3. WARNING ルール (W1-W9) をチェック
4. INFO ルール (I1-I3) をチェック

**安全な型変換の例外リスト（C7 で除外）:**

- `VARCHAR(n)` → `TEXT`
- `VARCHAR(n)` → `VARCHAR(m)` (m > n)
- `NUMERIC(p,s)` → `NUMERIC(p2,s)` (p2 > p, s 同一)
- `CIDR` → `INET`
- `CITEXT` → `TEXT`
- `TIMESTAMP` → `TIMESTAMPTZ`

### Step 3: レポート出力

```markdown
## マイグレーションレビュー: <ファイル名>

### 検出結果サマリ

| レベル      | 件数 |
| ----------- | ---- |
| 🔴 CRITICAL | N    |
| 🟡 WARNING  | N    |
| 🟢 INFO     | N    |

### 検出項目

| #   | レベル | ルール | 行  | 内容                                  | 修正方法                                                             |
| --- | ------ | ------ | --- | ------------------------------------- | -------------------------------------------------------------------- |
| 1   | 🔴     | C1     | L3  | `CREATE INDEX` が `CONCURRENTLY` なし | `CREATE INDEX CONCURRENTLY` に変更 + `-- +goose no transaction` 追加 |
```

**問題なしの場合**: `✅ LGTM — ゼロダウンタイムマイグレーションのガイドラインに適合` と報告。

### Step 4: 修正提案（CRITICAL/WARNING がある場合）

各検出項目に対して具体的な修正後の SQL を提示する。

## Common Mistakes

| 間違い                                            | 正しい対応                                                                                 |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `CREATE TABLE` 内の FK を W1 で検出する           | `CREATE TABLE` 内の FK は新テーブルなのでロック影響なし — 対象外                           |
| `-- +goose Down` セクションの操作を検出する       | Down マイグレーションはロールバック用 — レビュー対象外（ただし参考として言及可）           |
| GIN/GiST インデックスの `CONCURRENTLY` を見落とす | `USING gin(...)` / `USING gist(...)` も `CONCURRENTLY` が必要                              |
| `IF NOT EXISTS` / `IF EXISTS` があれば安全と判断  | 冪等性とゼロダウンタイムは別の概念 — ロック問題は残る                                      |
| `ALTER TYPE ... ADD VALUE` を CRITICAL にする     | ENUM 値追加はテーブルロックなし — INFO レベル                                              |
| `VALIDATE CONSTRAINT` をロック問題として検出する  | `VALIDATE` は `SHARE UPDATE EXCLUSIVE` で読み書き可能 — 安全                               |
| 新規テーブルの `CREATE INDEX` を C1 で検出する    | 同一マイグレーション内で `CREATE TABLE` と一緒に作られるインデックスはデータ不在のため安全 |

## 参考

- `docs/development_zero_downtime_migrations.md` — ガイドライン本体
- `migrates/` — マイグレーションファイル格納ディレクトリ
