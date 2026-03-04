# API Costs Dashboard

`api-costs` は、各サービスの API キー発行一覧と今月の利用料金をまとめて表示するコマンドです。

## セットアップ

1. 設定ファイルを作成

```bash
mkdir -p ~/.config/api-costs
cp ~/.config/api-costs/config.example.json ~/.config/api-costs/config.json
```

2. `~/.config/api-costs/config.json` を編集して、各サービスの取得コマンドを設定

```json
{
  "services": [
    {
      "name": "openai",
      "currency": "USD",
      "list_keys_cmd": "YOUR_COMMAND_FOR_KEYS",
      "monthly_cost_cmd": "YOUR_COMMAND_FOR_MONTHLY_COST"
    }
  ]
}
```

## コマンド仕様

- `list_keys_cmd`: JSON 配列を出力するコマンド
  - 例: `["key-a", "key-b"]`
  - 例: `[{"name":"prod","id":"sk-xxx"}]`
- `monthly_cost_cmd`: 金額を出力するコマンド
  - 例: `12.34`
  - 例: `"12.34"`
  - 例: `{"amount":12.34,"currency":"USD"}`

プレースホルダ:
- `{{month}}` -> `YYYY-MM`
- `{{month_start}}` -> `YYYY-MM-01`

## 使い方

```bash
# 今月
api-costs

# 対象月を指定
api-costs --month 2026-03

# 特定サービスのみ
api-costs --service openai

# JSON出力
api-costs --json
```

## 備考

- `jq` が必要です。
- サービス固有の認証情報（API トークンなど）は、各 `*_cmd` 側で環境変数やシークレット管理ツールを使って安全に渡してください。
