---
name: token-optimization-toolkit
description: Claude Code のトークン消費を削減する外部ツール群（プロキシ・MCPサーバー・プラグイン・テンプレート）の選定と導入を支援する。「トークン節約」「コンテキスト圧縮」「Claude Code が遅い／高い」「コードベース検索 MCP」「CLI 出力が context を食う」「ghost token」「セッション継続したい」「巨大モノレポで Claude が迷子」などで発動。10ツールの批判的比較と推奨組み合わせを持つ。
---

# Token Optimization Toolkit

Claude Code 周辺の「トークン削減」を謳うツールは乱立しており、主張する削減率（75%・97%・98% 等）は多くがチェリーピックされたベンチマークである。本スキルは10ツールを **批判的に比較** し、ユーザーの状況に応じた **最小構成の組み合わせ** を提示する。

## 発動条件

以下のいずれかでこのスキルを使う：

- ユーザーが「Claude Code のトークン消費を減らしたい」「コンテキストが足りない」「料金が高い」と訴える
- 「RTK」「Caveman」「Token Savior」「Claude Context」「Context Mode」「Code Review Graph」など特定ツール名が出る
- 「ghost token」「context bloat」「セッション圧縮（compaction）対策」のキーワードが出る
- 大規模モノレポで Claude が無関係なファイルを大量に読んでいる兆候がある
- 新規プロジェクトの初期セットアップでトークン最適化を検討したい

## 重要な前提（必ず最初に伝える）

1. **削減率の主張は鵜呑みにしない**。各ツールが提示する 90%／97%／98% は、自社が選んだベンチマーク条件でのチャンピオンデータ。実プロジェクトでは数十%程度に落ちることが多い。
2. **入れすぎない**。多くのツールは互いに **代替関係** にあり、組み合わせると効果が打ち消し合うか競合する。
3. **計測が前提**。導入前後で実トークン消費（`/cost`、トレース、ログ）を比較しないなら、入れる意味は薄い。
4. **既存 CLAUDE.md と重複していないか確認**。本リポジトリの `.claude/CLAUDE.md` は既に「Tone and style」「default to no comments」など出力削減ルールを内包している。Caveman・Claude Token Efficient は実質これと重複する。

## 決定木：どれを入れるか

ユーザーの主訴に応じて、以下の順で推奨する。

### ケース A: CLI 出力（`git status`, `npm test`, `find` 等）が context を食っている

→ **RTK (Rust Token Killer)** を最優先。
- 理由: 単一バイナリ・ゼロ依存・透過プロキシ。他ツールと競合しない。
- 効果: 60–90% 削減（実案件でも 50%+ は出やすい）。
- 注意: Claude が rewrite に気付かない設計。デバッグ時にオリジナル出力が見たい場合は一時無効化が必要。

### ケース B: 大規模リポ／モノレポで「全ファイル grep」が走っている

→ 以下のいずれか1つ（**併用しない**）：

| 候補 | 適性 |
|------|------|
| **Claude Context (Zilliztech)** | Zilliz Cloud バックアップ。チーム共有・大規模で安定。BM25+ベクトルのハイブリッド検索。40% 削減（誠実な数字）。 |
| **Code Review Graph (tirth8205)** | Tree-sitter で AST グラフ構築。ローカル完結・Python pip。コードレビュー文脈で 6.8x、変更影響範囲（blast radius）解析が強み。 |
| **Token Savior (Mibayy)** | シンボル単位ナビ + 永続メモリ。SQLite WAL+FTS5+vector。「同じファイルを何度も読み直す」問題に効く。 |

選定基準:
- チーム共有・本番運用 → **Claude Context**
- 個人・コードレビュー特化 → **Code Review Graph**
- 永続メモリも欲しい → **Token Savior**

### ケース C: セッション圧縮（compaction）で文脈が飛ぶ

→ **Context Mode (mksglu)**。
- 理由: ツール出力を SQLite に sandbox し、`--continue` で復元。
- 効果: 単一セッション内のツール結果サイズを 98%→ 5% 程度。
- 注意: 「持続する作業状態」が前提。短いワンショットには合わない。

### ケース D: 監査・可視化（どこでトークンを浪費しているか分からない）

→ **alexgreensh/token-optimizer**。
- 理由: 6並列エージェントで Claude Code / OpenClaw 設定を audit。ダッシュボード提供。
- 注意: あくまで **診断ツール**。これ自体が削減するわけではない。

### ケース E: 新規プロジェクトのセットアップ

→ **nadimtuhin/claude-token-optimizer** の手法を参考に：
- `.claude/QUICK_START.md`（コマンド集、~100 tokens）
- `.claude/ARCHITECTURE_MAP.md`（構造、~150 tokens）
- `.claude/COMMON_MISTAKES.md`（過去のハマり、1時間以上かかったバグのみ）
- `CLAUDE.md`（テスト方針・型・デプロイ規約、~450 tokens）

ただし本リポジトリの CLAUDE.md は既にこの構造に近い。**プロジェクト固有のリポジトリにのみ適用**。

### ケース F: MCP ツール経由のトークン消費が膨らんでいる

→ **ooples/token-optimizer-mcp**。
- 理由: MCP レスポンスを Brotli 圧縮 + SQLite キャッシュ。tiktoken で正確計測。
- 注意: 自分の MCP サーバー実装に問題がある場合は、まずそちらを直す。

### ケース G: ユーザーが「Caveman」「Claude Token Efficient」を入れたいと言う

→ **既存の `.claude/CLAUDE.md` ですでに簡潔出力ルールがあることを伝える**。
- それでも入れたい場合: profiles のいずれかを CLAUDE.md にマージ可能か検討。コンフリクトしないかレビュー必須。

## 推奨スターターパック

トークン消費に困っているがどれか1つから始めたいユーザー向け：

```
1. RTK（CLI出力圧縮）           ← 副作用が最小、効果が出やすい
2. Claude Context もしくは Code Review Graph（コードベース検索） ← 規模次第
3. （必要なら）Context Mode（セッション継続）
```

このスターターパック以上は **計測してから追加**。

## 詳細リファレンス

- 各ツールの GitHub リンク・主張・実態・既知の落とし穴: [references/tools-overview.md](references/tools-overview.md)
- セットアップ手順とコンフリクト回避: [references/setup-recipes.md](references/setup-recipes.md)
- 主張する削減率の解釈と検証方法: [references/benchmark-skepticism.md](references/benchmark-skepticism.md)

## 出力フォーマット

ユーザーから相談を受けたら、以下の順で答える：

1. **ユーザーの主訴を1行で要約**（例: 「モノレポで Claude が無関係ファイルを読みすぎる」）
2. **該当ケース（A〜G）の特定**
3. **推奨ツール 1〜2個**（複数推す場合は併用可否を明示）
4. **削減率の現実的レンジ**（ベンダー主張ではなく、実プロジェクトで期待できる値）
5. **競合・既存 CLAUDE.md との重複の有無**
6. **計測方法**（導入後に何を見て効果判定するか）

## やってはいけないこと

- 10ツール全部を勧める（互いに代替/競合）
- ベンダーの主張削減率をそのまま提示する
- 既存 CLAUDE.md のルールと重複するスタイル系ツール（Caveman / Claude Token Efficient）を最初に勧める
- 計測なしの導入を勧める
