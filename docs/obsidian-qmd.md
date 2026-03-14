# Obsidian + qmd セットアップガイド

ローカルナレッジベースを構築し、Claude Code から検索可能にする。

## 概要

- **Obsidian**: ローカルマークダウンベースのノートアプリ
- **qmd**: BM25 + ベクトル検索 + LLM リランキングのローカル検索 CLI（by Tobi Lütke）

## 自動セットアップ

`chezmoi apply` を実行すると以下が自動で行われる:

1. Obsidian Vault (`~/obsidian-vault`) の作成とディレクトリ構造の初期化
2. qmd (`@tobilu/qmd`) のグローバルインストール
3. Vault を qmd コレクションとして登録
4. 初回エンベディングの生成

## 手動セットアップ

```bash
# qmd インストール
npm install -g @tobilu/qmd
# or
bun install -g @tobilu/qmd

# Vault をコレクションに追加
qmd collection add ~/obsidian-vault

# エンベディング生成（初回は数分かかる）
qmd embed
```

## Vault ディレクトリ構造

```
~/obsidian-vault/
├── notes/
│   ├── inbox/           # 未整理ノート
│   ├── docs/
│   │   ├── records/     # 調査記録
│   │   └── howto/       # 手順書
│   ├── projects/        # プロジェクト別
│   └── daily/           # デイリーノート
└── templates/           # テンプレート
```

## qmd コマンド

| コマンド | 説明 |
|---------|------|
| `qmd search 'keyword'` | BM25 全文検索 |
| `qmd vsearch 'concept'` | セマンティック検索 |
| `qmd query 'question'` | ハイブリッド検索 + LLM リランキング |
| `qmd embed` | エンベディング再生成（ノート追加後） |
| `qmd collection add <path>` | コレクション追加 |

## Claude Code との連携

Claude Code セッションで直接 qmd を呼び出して、Obsidian のノートを検索できる:

```bash
# Claude Code 内で
qmd query "プロダクト戦略に関する意思決定"
```

ノートを追加するたびに `qmd embed` でインデックスを更新すると、
次回以降の検索精度が向上する。

## MCP サーバー連携

qmd は MCP サーバーとしても動作する。Claude Desktop や Claude Code の
MCP 設定に追加することで、ツールとして直接利用可能:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```
