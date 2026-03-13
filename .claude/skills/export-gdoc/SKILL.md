---
name: export-gdoc
description: |
  ローカルのマークダウンファイルをGoogle Docsに変換・エクスポートするスキル。Notion風のクリーンなデザインで統一出力する。
  「Google Docsに出力して」「export-gdoc」「Gドキュメントに変換」「ドキュメント共有用に変換」「export to google docs」などで発動。
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

## 使い方

```
/export-gdoc [ファイルパス]
```

ファイルパスが省略された場合、直近の mtg-prep や follow-up の出力を候補として提示する。

## Workflow

### Step 1: ソースファイル選択

1. 引数でファイルパスが指定された場合はそれを使用
2. 指定がなければ、直近の出力ファイルを検索:
   ```
   notes/docs/records/mtg-prep/ の最新ファイル
   notes/docs/records/follow-up/ の最新ファイル
   ```
3. 候補をリストアップしてユーザーに選択させる

### Step 2: フォーマット変換

マークダウンを以下のデザインルールで変換:

#### Notion風デザインルール
- **見出し**: H1 は大きくボールド、H2 はミディアム、H3 はスモール
- **テーブル**: 罫線付き、ヘッダー行にグレー背景
- **チェックリスト**: チェックボックス形式を維持
- **引用**: 左ボーダー付きインデント
- **コードブロック**: モノスペースフォント、薄いグレー背景
- **全体**: 余白を十分に取り、視認性を重視

### Step 3: エクスポート

#### MCP利用可能な場合
```
1. Google Docs API で新規ドキュメント作成
2. デザインルール適用
3. 指定フォルダに保存
4. 共有リンクを返す
```

#### pandoc フォールバック
```bash
pandoc input.md -o output.docx \
  --reference-doc=~/.config/pandoc/notion-style.docx \
  -f markdown -t docx
```

出力先: `~/Desktop/[ファイル名].docx`

ユーザーに手動アップロードを案内する。

### Step 4: 完了通知

- エクスポート先のパスまたはURLを表示
- （MCP利用時）共有設定の確認

## pandoc リファレンステンプレート

初回実行時に `~/.config/pandoc/notion-style.docx` が存在しなければ、
デフォルトのリファレンスドキュメントを生成する:

```bash
pandoc -o ~/.config/pandoc/notion-style.docx --print-default-data-file reference.docx
```

## Save Location

変換元ファイルと同じディレクトリに `.docx` も保存する（バックアップ用）。

## Quality Checklist

- [ ] テーブルが崩れていないか
- [ ] 日本語フォントが正しく表示されるか
- [ ] 見出し階層が正しいか
- [ ] リンクが生きているか
