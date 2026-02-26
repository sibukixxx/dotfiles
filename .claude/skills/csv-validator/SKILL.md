---
name: csv-validator
description: CSVファイルをJSONスキーマ定義に基づいてバリデーションする。「CSVを検証して」「CSVのフォーマットチェックして」「CSVバリデーションして」「CSVの型チェック」「validate CSV」などで発動。ヘッダー構造、カラム型（string, integer, float, boolean, date, datetime, email, url, enum, phone）、必須フィールド、制約条件のチェックに対応。
---

# CSV Validator

CSVファイルをJSONスキーマ定義に基づいてバリデーションする。型チェック、必須フィールド、カスタム制約に対応。

## Prerequisites

標準ライブラリのみ使用。追加パッケージ不要。

## Instructions

### Step 1: CSVファイルを特定する

ユーザーに以下を確認する：
- バリデーション対象のCSVファイルパス
- エンコーディング（デフォルト: utf-8）
- デリミタ（デフォルト: カンマ）

### Step 2: CSVの構造を分析する

対象CSVのヘッダーとサンプルデータを確認し、スキーマ定義に必要な情報を把握する。

```bash
head -5 data.csv
```

### Step 3: スキーマファイルを作成する

CSVの構造に合わせてJSONスキーマを作成する。スキーマ形式の詳細は `references/schema_format.md` を参照。

```json
{
  "name": "schema_name",
  "fields": [
    {"name": "column_name", "type_def": {"type": "string"}, "required": true}
  ]
}
```

#### 対応する型と制約

| 型 | 制約 |
|------|------------|
| string | min_len, max_len, pattern |
| integer / int | min_val, max_val |
| float / number | min_val, max_val |
| boolean / bool | （なし）true/false, 1/0, yes/no を許容 |
| date | format（デフォルト: `%Y-%m-%d`） |
| datetime | format（デフォルト: `%Y-%m-%d %H:%M:%S`） |
| email | （なし） |
| url | （なし） |
| enum | values（許容値リスト） |
| phone | pattern |

#### スキーマ例

```json
{
  "name": "orders",
  "fields": [
    {"name": "order_id", "type_def": {"type": "integer", "min_val": 1}, "required": true},
    {"name": "customer_email", "type_def": {"type": "email"}, "required": true},
    {"name": "amount", "type_def": {"type": "float", "min_val": 0}, "required": true},
    {"name": "status", "type_def": {"type": "enum", "values": ["pending", "shipped", "delivered"]}, "required": true},
    {"name": "order_date", "type_def": {"type": "date", "format": "%Y-%m-%d"}, "required": true}
  ]
}
```

### Step 4: バリデーションを実行する

スクリプトのパスは `~/.claude/skills/csv-validator/scripts/validate_csv.py` にある。

```bash
python3 ~/.claude/skills/csv-validator/scripts/validate_csv.py <csv_file> <schema_file> [options]
```

**オプション：**

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--encoding ENCODING` | CSVファイルのエンコーディング | utf-8 |
| `--delimiter DELIMITER` | CSVのデリミタ | , |
| `--output text\|json` | 出力フォーマット | text |

**実行例：**

```bash
# 基本的なバリデーション
python3 ~/.claude/skills/csv-validator/scripts/validate_csv.py data.csv schema.json

# TSVファイルのバリデーション
python3 ~/.claude/skills/csv-validator/scripts/validate_csv.py data.tsv schema.json --delimiter $'\t'

# JSON形式で結果を出力
python3 ~/.claude/skills/csv-validator/scripts/validate_csv.py data.csv schema.json --output json

# Shift_JISエンコーディングのCSV
python3 ~/.claude/skills/csv-validator/scripts/validate_csv.py data.csv schema.json --encoding shift_jis
```

### Step 5: 結果を報告する

実行結果をユーザーに報告する：
- バリデーション結果（VALID / INVALID）
- 検査した行数
- エラー数と内容（行番号・カラム名・値・期待される型）
- 警告（余分なヘッダーなど）
- エラーがある場合は修正案を提示

### Step 6: エラーがある場合の修正サイクル

1. エラー内容を確認してCSVまたはスキーマを修正
2. 再度バリデーションを実行
3. すべてのエラーが解消されるまで繰り返す

## Workflow

1. CSVの構造（ヘッダー・サンプルデータ）を分析
2. スキーマJSONを作成
3. `validate_csv.py` でバリデーション実行
4. エラーを確認し、CSVまたはスキーマを修正
5. 再実行してパスするまで繰り返す

## Troubleshooting

### エンコーディングエラー

`--encoding` オプションで正しいエンコーディングを指定する。日本語CSVは `shift_jis` や `cp932` が多い。

### ヘッダー名が一致しない

スキーマの `name` フィールドはCSVヘッダーと完全一致が必要。大文字小文字・空白に注意。

### 大量のエラーが出る場合

まず `--output json` で全エラーを確認し、パターンを特定して一括修正する。
