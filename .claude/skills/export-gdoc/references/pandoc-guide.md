# export-gdoc: pandoc ガイド

## pandoc フォールバック手順

MCP が利用できない場合の .docx 出力方法。

### インストール

```bash
brew install pandoc
```

### 基本コマンド

```bash
pandoc input.md -o output.docx \
  --reference-doc=~/.config/pandoc/notion-style.docx \
  -f markdown -t docx
```

出力先: `~/Desktop/[ファイル名].docx`

### リファレンステンプレート初期化

初回実行時に `~/.config/pandoc/notion-style.docx` が存在しなければ生成:

```bash
mkdir -p ~/.config/pandoc
pandoc -o ~/.config/pandoc/notion-style.docx --print-default-data-file reference.docx
```

### Notion風デザインルール

| 要素 | スタイル |
|------|---------|
| 見出し H1 | 大きくボールド |
| 見出し H2 | ミディアム |
| 見出し H3 | スモール |
| テーブル | 罫線付き、ヘッダー行にグレー背景 |
| チェックリスト | チェックボックス形式を維持 |
| 引用 | 左ボーダー付きインデント |
| コードブロック | モノスペースフォント、薄いグレー背景 |
| 全体 | 余白を十分に取り、視認性を重視 |

### 手動アップロード

.docx 生成後:
1. Google Drive を開く
2. 「新規」→「ファイルのアップロード」
3. .docx ファイルを選択
4. Google Docs 形式で開く
