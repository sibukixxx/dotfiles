---
name: sqlite-to-xlsx
description: SQLiteデータベースをExcelスプレッドシート(.xlsx)に変換する。「SQLiteをExcelに変換して」「DBをスプレッドシートに出力して」「テーブルをExcelにエクスポートして」「SQLiteからxlsx作って」「DBの中身をExcelで見たい」などで発動。テーブル選択、カスタムSQLクエリ、スキーマドキュメント出力、プロフェッショナルな書式設定に対応。
---

# SQLite to Excel Converter

SQLiteデータベースのテーブルをプロフェッショナルな書式のExcelスプレッドシートに変換する。

## Prerequisites

以下のPythonパッケージが必要。なければ自動でインストールする。

```bash
pip install pandas openpyxl
```

## Instructions

### Step 1: 対象のSQLiteファイルを特定する

ユーザーに以下を確認する：
- SQLiteデータベースファイルのパス
- 出力先（指定がなければDBファイルと同じディレクトリに `<db名>.xlsx` として出力）

### Step 2: 依存パッケージを確認する

```bash
python3 -c "import pandas; import openpyxl; print('OK')" 2>/dev/null || pip install pandas openpyxl
```

### Step 3: エクスポートオプションを決定する

ユーザーの要望に応じてオプションを組み合わせる：

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--output FILE` | 出力ファイルパス | `<db名>.xlsx` |
| `--tables t1,t2` | 指定テーブルのみエクスポート | 全テーブル |
| `--query "SQL"` | カスタムSQLクエリの結果をエクスポート | なし |
| `--query-name NAME` | クエリ結果のシート名 | `Query_Result` |
| `--include-schema` | `_Schema`シートにテーブル定義を追加 | OFF |
| `--no-format` | 書式設定をスキップ（大量データ向け） | OFF |

### Step 4: スクリプトを実行する

スクリプトのパスは `~/.claude/skills/sqlite-to-xlsx/scripts/sqlite_to_xlsx.py` にある。

```bash
python3 ~/.claude/skills/sqlite-to-xlsx/scripts/sqlite_to_xlsx.py <database.db> [options]
```

**実行例：**

全テーブルをエクスポート：
```bash
python3 ~/.claude/skills/sqlite-to-xlsx/scripts/sqlite_to_xlsx.py app.db
```

特定テーブルのみ：
```bash
python3 ~/.claude/skills/sqlite-to-xlsx/scripts/sqlite_to_xlsx.py app.db --tables users,orders
```

カスタムクエリ：
```bash
python3 ~/.claude/skills/sqlite-to-xlsx/scripts/sqlite_to_xlsx.py app.db --query "SELECT * FROM orders WHERE status='pending'" --query-name PendingOrders
```

スキーマ付き：
```bash
python3 ~/.claude/skills/sqlite-to-xlsx/scripts/sqlite_to_xlsx.py app.db --include-schema
```

### Step 5: 結果を報告する

実行結果をユーザーに報告する：
- 出力ファイルパス
- エクスポートしたシート数
- 合計行数
- 各シートの行数×列数
- 警告（存在しないテーブル指定など）

## Output Format

- 各テーブル → 個別シート（シート名は31文字で切り詰め）
- ヘッダー: 白文字・青背景・太字・中央揃え
- 列幅: 自動調整（最大50）
- ヘッダー行を固定表示（freeze panes）
- セル罫線あり
- `_Schema`シート（オプション）: 緑背景ヘッダーのテーブル定義一覧

## Troubleshooting

### pandas/openpyxl がインストールされていない

```bash
pip install pandas openpyxl
```

### データベースファイルが見つからない

パスが正しいか確認する。相対パスの場合はカレントディレクトリ基準。

### テーブルが見つからない

`--tables` で指定した名前が正しいか確認する。スクリプトは警告を出して存在するテーブルのみエクスポートする。

### 大量データで遅い

`--no-format` オプションで書式設定をスキップすると高速化できる。
