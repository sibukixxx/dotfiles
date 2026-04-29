# 破壊的変更プレイブック

破壊的変更（旧コードと互換性が失われる変更、データを失う変更）は
**1つの migration では絶対にやらない**。
Phase で分けて、各 Phase の間にアプリのデプロイと観測期間を挟む。

## ケース1: カラム削除

### ❌ 危険な単一 migration

```sql
ALTER TABLE users DROP COLUMN legacy_token;
```

旧コードがまだ `legacy_token` を読んでいる間に流すと、即時障害。

### ✅ 段階的アプローチ（4 phase）

**Phase 1: アプリから参照を取り除く**
- 新コードでは `legacy_token` を読み書きしない
- 該当カラムを参照するクエリを削除
- アプリをデプロイ
- **観測期間（数日〜数週間）**: ログ・エラーで「あれ？まだ使ってた」がないか確認

**Phase 2: deprecated marker を入れる（任意）**
- ORM 上で `@deprecated` コメントを付ける
- 新規開発者が使わないように

**Phase 3: DROP migration**

```sql
-- migration: 0099_drop_users_legacy_token
ALTER TABLE users DROP COLUMN legacy_token;
```

**Phase 4: 関連 index も掃除**

```sql
-- 不要になった index を削除
DROP INDEX IF EXISTS idx_users_legacy_token;
```

## ケース2: カラム rename

### ❌ 危険な単一 migration

```sql
ALTER TABLE users RENAME COLUMN email TO email_address;
```

旧コードと新コードが混在する瞬間（デプロイ中）に必ず壊れる。

### ✅ 段階的アプローチ（5 phase）

**Phase 1: 新カラム追加（旧と並走）**

```sql
-- migration: 0050_add_users_email_address
ALTER TABLE users ADD COLUMN email_address TEXT;
```

**Phase 2: アプリを「両書き・旧読み」に**
- INSERT/UPDATE: 両方に書く（`email` と `email_address` 両方）
- SELECT: まだ旧カラム `email` を読む

**Phase 3: backfill**

```sql
-- migration: 0051_backfill_users_email_address
UPDATE users SET email_address = email WHERE email_address IS NULL;
```

**Phase 4: アプリを「両書き・新読み」に切替**
- INSERT/UPDATE: 両方に書く
- SELECT: 新カラム `email_address` を読む
- 観測期間: 新カラムで問題ないか確認

**Phase 5: アプリを「新だけ」に**
- 新カラムだけ読み書き
- アプリデプロイ後、観測期間

**Phase 6: 旧カラム削除**

```sql
-- migration: 0080_drop_users_email
ALTER TABLE users DROP COLUMN email;
```

## ケース3: NOT NULL 制約の追加

既存行に NULL があると失敗する。

### ✅ 段階的アプローチ

**Phase 1: default 付きで NULL 許可カラムを追加（新規カラムの場合）**

```sql
ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'pending';
```

**Phase 2: 既存 NULL 行を補填**

```sql
-- migration: 0061_backfill_orders_status
UPDATE orders SET status = 'unknown' WHERE status IS NULL;
```

**Phase 3: NOT NULL 制約を追加**

```sql
-- PostgreSQL
ALTER TABLE orders ALTER COLUMN status SET NOT NULL;

-- MySQL
ALTER TABLE orders MODIFY COLUMN status TEXT NOT NULL DEFAULT 'pending';
```

注意：
- 巨大テーブルでの ALTER は table rewrite を起こす DB あり
- PostgreSQL 12+ なら制約追加は速い
- それ以前は `CHECK (status IS NOT NULL) NOT VALID` → `VALIDATE CONSTRAINT` の二段階

## ケース4: 型変更（互換性のない型へ）

例: `VARCHAR(255)` → `INTEGER`

### ✅ 段階的アプローチ

**Phase 1: 新カラムを追加（新型）**

```sql
ALTER TABLE users ADD COLUMN age_int INTEGER;
```

**Phase 2: backfill（変換ロジックを書く）**

```sql
UPDATE users SET age_int = CAST(age_str AS INTEGER) WHERE age_str ~ '^\d+$';
```

**Phase 3: アプリを新カラムへ移行**（rename と同じ流れ）

**Phase 4: 旧カラム削除**

## ケース5: UNIQUE 制約の追加

重複データがあると失敗する。

### ✅ 段階的アプローチ

**Phase 1: 重複データを調査**

```sql
SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1;
```

**Phase 2: 重複データを解決**
- アプリ側でマージ or 削除 or 別名化

**Phase 3: UNIQUE 制約追加**

```sql
-- PostgreSQL: CONCURRENTLY で長時間ロック回避
CREATE UNIQUE INDEX CONCURRENTLY idx_users_email_unique ON users(email);
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE USING INDEX idx_users_email_unique;
```

## ケース6: 大規模 index 作成

### PostgreSQL

```sql
-- ロック回避
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
```

注意：
- `CONCURRENTLY` はトランザクション外で実行する必要あり
- migration ツールによってはトランザクションラップを解除する設定が必要
  - Rails: `disable_ddl_transaction!`
  - sqlx: `-- migrate:up transaction=false`

### MySQL

```bash
# pt-online-schema-change を使う
pt-online-schema-change \
  --alter "ADD INDEX idx_user_id (user_id)" \
  D=mydb,t=orders --execute
```

または `gh-ost` を使う。

### Cloudflare D1 / SQLite

- `CREATE INDEX` は通常 lock を取るが、D1 は管理されているので通常は問題ない
- 巨大テーブルの場合は staging で実行時間を計測

## 共通の進行管理

破壊的変更の Phase 進行は **migration ファイル名に Phase 番号を入れる** と追跡しやすい：

```
0050_phase1_add_users_email_address.sql
0051_phase2_backfill_users_email_address.sql
0080_phase3_drop_users_email.sql
```

各 Phase の間に：
1. アプリのデプロイ
2. 観測期間（最低1日、できれば1週間）
3. 異常がないか確認

を必ず入れる。
