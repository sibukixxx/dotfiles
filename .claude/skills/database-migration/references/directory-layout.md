# migration ディレクトリ構成パターン

## パターン1: 単一アプリ（最も一般的）

```
my-app/
  src/
  migrations/
    0001_create_users.sql
    0002_add_user_email_index.sql
    0003_create_orders.sql
    0004_add_orders_status.sql
  package.json
```

- migration ツールが migrations/ 直下を見る
- 連番は単一系列
- 小〜中規模プロジェクト向け

## パターン2: モノレポ - アプリ別 migrations/

```
repo-root/
  emdash-site/
    src/
    public/
    migrations/                       # アプリ専用
      0001_create_wallet_tables.sql
      0002_add_campaign_status.sql
      0003_add_campaign_indexes.sql
    wrangler.jsonc
    package.json
  another-app/
    src/
    migrations/                       # 別アプリ専用
      0001_init.sql
  package.json                        # workspace ルート
```

- 各アプリが独立した migration 履歴を持つ
- DB が別々（アプリごとに D1 / Postgres インスタンス分離）の場合に適合

## パターン3: モノレポ - コア + プラグイン構成（emdash 型）

```
repo-root/
  migrations/                         # コア / 共通スキーマ
    0001_emdash_core_init.sql
    0002_wallet_plugin_tables.sql
    0003_campaign_plugin_tables.sql
  emdash-site/
    src/
    migrations/                       # アプリ固有の追加変更
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

適用場面：
- プラグイン式アーキテクチャでコアと拡張を分離したい
- 同一 DB を複数アプリ・モジュールで共有
- emdash / WordPress のようなプラグインベースのシステム

注意：
- 同じ DB に対して複数の migrations/ を流す場合、
  **適用順序を別途ドキュメント化** しないと事故る
  - 例: README.md に「ルート migrations → 各アプリ migrations の順で流す」と明記
- ツールによっては複数ディレクトリ管理に対応しないものがあるので、
  シェルスクリプトでまとめるなど工夫が必要

## パターン4: 環境別 migrations（非推奨）

```
migrations/
  common/
  development/    # ❌
  production/     # ❌
```

❌ 環境別に migration を分けるのは原則アンチパターン
- 環境間で DB スキーマが異なる時点で「production で動くか」が保証できない
- どうしても環境差異が必要なら、 seed データ・設定値で吸収する

## ファイル命名規則

```
<連番4桁>_<動詞>_<対象>.sql
```

| 動詞 | 用途 | 例 |
|------|------|-----|
| `create` | 新規テーブル/index作成 | `0001_create_wallet_tables.sql` |
| `add` | カラム/制約/index追加 | `0042_add_campaign_status.sql` |
| `drop` | 削除（最終フェーズのみ） | `0099_drop_legacy_user_tokens.sql` |
| `rename` | リネーム | `0050_rename_users_email_to_email_address.sql` |
| `backfill` | データ補填（DDL なし） | `0044_backfill_user_locale.sql` |
| `alter` | 型変更等 | `0060_alter_orders_total_to_decimal.sql` |

連番の桁数：
- 4桁推奨（9999 まで使えれば事実上十分）
- タイムスタンプ形式（`20260429120000_xxx.sql`）も可だが衝突しにくいが読みづらい
- ツールに合わせる（Rails: `YYYYMMDDHHMMSS`、Prisma: `YYYYMMDDHHMMSS_name/`）

## migration ファイルのヘッダーテンプレート

```sql
-- migration: 0042_add_campaign_status
-- author: <name>
-- date: <YYYY-MM-DD>
-- purpose: <なぜこの変更が必要か>
-- safety: <後方互換性 / ロック時間 / データ影響>
-- rollback: forward-only（撤回するなら新しい migration で打ち消す）

-- ここから DDL/DML
```

## .gitignore の確認

migration ファイルは **絶対に gitignore しない**。

```gitignore
# ❌ これは絶対にやらない
migrations/
*.sql

# ✅ ローカル DB ファイルだけ除外する
*.sqlite
*.db
.wrangler/
```
