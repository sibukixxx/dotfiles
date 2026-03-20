---
name: export-gdoc
description: |
  ローカルのマークダウンファイルをGoogle Docsに変換・エクスポートするスキル。Notion風のクリーンなデザインで統一出力する。
  「Google Docsに出力して」「export-gdoc」「Gドキュメントに変換」「ドキュメント共有用に変換」「export to google docs」などで発動。
references:
  - references/pandoc-guide.md
---

# export-gdoc: Google Docs エクスポートスキル

マークダウンファイルをGoogle Docsに変換し、Notion風デザインで出力する。

## 前提条件

### 方法 A: Google Docs MCP（推奨）
- Google Docs MCP サーバーが設定済み
- OAuth認証済み

### 方法 B: pandoc（MCP不要のフォールバック）
- pandoc がインストール済み（`brew install pandoc`）
- .docx 形式で出力し、手動で Google Drive にアップロード
- 詳細は `references/pandoc-guide.md` を参照

## 使い方

```
/export-gdoc [ファイルパス]
```

ファイルパスが省略された場合、直近の mtg-prep や follow-up の出力を候補として提示する。

## Workflow

### Step 1: ソースファイル選択

1. 引数でファイルパスが指定された場合はそれを使用
2. 指定がなければ、直近の出力ファイルを検索して候補をリストアップ

### Step 2: エクスポート

#### MCP利用可能な場合
1. Google Docs API で新規ドキュメント作成
2. Notion風デザインルール適用
3. 指定フォルダに保存
4. 共有リンクを返す

#### pandoc フォールバック
`references/pandoc-guide.md` の手順に従い .docx を生成。

### Step 3: 完了通知

- エクスポート先のパスまたはURLを表示
- （MCP利用時）共有設定の確認

## Save Location

変換元ファイルと同じディレクトリに `.docx` も保存する（バックアップ用）。

## Quality Checklist

- [ ] テーブルが崩れていないか
- [ ] 日本語フォントが正しく表示されるか
- [ ] 見出し階層が正しいか
- [ ] リンクが生きているか

## Troubleshooting

### pandoc がインストールされていない場合
`brew install pandoc` でインストール。

### テーブルが崩れる場合
pandoc のバージョンを確認（3.0以上推奨）。パイプテーブル形式を使用。

### 日本語フォントが文字化けする場合
リファレンスドキュメントのフォント設定を確認。Noto Sans JP を推奨。

### Google Docs MCP の認証エラー
OAuth トークンの有効期限を確認。`claude mcp` で再認証。
