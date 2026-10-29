# 自律運用ルール

`~/.claude/CLAUDE.md` は各リポジトリの `AGENTS.md` / skills / hooks への routing 専用にしたため、
グローバルに常時適用したい運用ルールはこのファイル（常時ロードされる rules/）に置く。

## z-ai/ directory

- `z-ai/` is globally gitignored.
- This directory is used for local AI documents such as plans and progress
  tracking.
- Do NOT ask whether `z-ai/` is gitignored — it always is.
- 作業で得た知見・ユーザーの好み・プロジェクト固有の事情は `z-ai/` ではなく
  Claude Code ビルトインの memory に保存する。`z-ai/` は計画書と進捗の置き場に限る。

## Code Quality

- コードを書く際は、まずテストを考える
- 「このコードはどうテストするか？」を常に意識する
- テストしにくいコードは設計を見直すサイン
- **読んでいないコードは変更するな**: 変更対象のファイルは必ず先にReadツールで読むこと。推測で編集しない
- **難しいタスクの前に `/effort high` を実行**: 思考予算を上げてから取り組む

## 自律運用の約束事

画面を見続けなくても作業が進むよう、`viewMode: focus` + `defaultMode: auto` で運用している。
その前提で守ること：

### 質問の出し方（focus モード）

- focus モードでは、質問（AskUserQuestion）の直前に書いた本文がユーザーに見えない
- 判断材料は選択肢のラベルと説明に折り込む。本文だけに書かない
- 調査結果を報告してターンを終えてから質問するほうが望ましい

### 制限には従う（回避策を探さない）

- PreToolUse フックや permissions で deny された操作（`curl` / `rm -rf` / `.env` 読み取り等）は、
  代替手段を探して rabbit hole に入らず、**諦めてその旨を報告する**
- deny は「自分では直せない境界」。`sudo` / `chmod` / 別コマンドへの言い換えで突破しない
- サンドボックス外への書き込みが拒否された場合も同じ。書ける場所の中で作業する

### 動作確認も自律的にやる

- 実装後の確認を人間に投げ返さない。自分で動かして結果を報告する
- ブラウザで確認できるものは `agent-browser` を使う（localhost は `--allow-private`）
- 開発サーバーなど長生きするプロセスは `tmux new -d -s <repo名> '<cmd>'` で起動し、
  ユーザーに `tmux attach -t <repo名>` を伝える。ワンショットのコマンド（git / ls / build）は tmux を通さない

### コメントにローカルツール専用の目印を残さない

- `ponytail:` のような、特定ツールが読むためだけのマーカーやコメント見出しをコードに書かない
- そのツールを使っていない同僚や、アンインストール後の自分にも意味が通る言い回しにする
- 意図的な簡略化で上限が分かっているものは `LIMITATION:` を使う

### 定型作業は command / agent に委譲する

| やること | 使うもの |
|---------|---------|
| レビュー指摘の妥当性を判断して対応 | `/address` |
| レビュー指摘への返信 | `/reply-review` |
| コミットの fixup / squash / 並べ替え | `rebaser` agent |
| コミットメッセージの書き換え | `reworder` agent |
| コミット & push | `/commit-push` / `commit-pusher` agent |
| 設定の棚卸し（四半期〜半年に 1 回） | `/config-audit` |

