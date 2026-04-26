# 10ツール詳細リファレンス（批判的評価付き）

各ツールの **主張 / 実態 / 落とし穴** を整理する。削減率はベンダー公称値であり、自プロジェクトで再現する保証はない。

## カテゴリ分類

| カテゴリ | ツール |
|----------|-------|
| 出力スタイル変更 | #1 Caveman, #9 Claude Token Efficient |
| CLI 出力圧縮プロキシ | #2 RTK |
| コードベース検索 / グラフ | #3 Code Review Graph, #8 Claude Context, #10 Token Savior |
| セッション仮想化 | #4 Context Mode |
| プロジェクトセットアップ | #5 nadimtuhin Token Optimizer |
| 監査・可視化 | #6 alexgreensh Token Optimizer |
| MCP 圧縮 | #7 ooples Token Optimizer MCP |

---

## 1. Caveman Claude

- **Repo**: https://github.com/JuliusBrussee/caveman
- **形態**: Claude Code Skill（プラグイン）
- **主張**: 出力トークンを 22–87%（平均 65%）削減
- **手法**: Claude に「洞窟人風」短文で返答させる。Classical Chinese 圧縮モードあり
- **実態**:
  - 削減対象は **出力（Assistant メッセージ）トークンのみ**。Claude Code のコスト構造では入力／キャッシュ読み込みが支配的なため、総コスト削減幅は限定的
  - thinking トークンには影響しない
  - GitHub 5K star（2025末時点）でバズ枠
- **落とし穴**:
  - 既存 `.claude/CLAUDE.md` の "Tone and style" ルールと **完全に重複**
  - レビュー文書・PR 説明など人間が読む出力で可読性を損なう
  - 文体の極端化により、後続ターンでユーザー指示を誤解しやすくなる懸念

---

## 2. RTK (Rust Token Killer)

- **Repo**: https://github.com/rtk-ai/rtk
- **形態**: Rust 製単一バイナリ、CLI 透過プロキシ
- **主張**: 60–90% 削減（CLI 出力経由）
- **手法**: `git status` → `rtk git status` のように rewrite。プログレスバー・冗長ログ・成功テストの省略
- **実態**:
  - Claude Code, Cursor, Gemini CLI, Aider, Codex, Windsurf, Cline をサポート
  - **入力トークン側の削減** に効くため、コスト直結
  - ゼロ依存・単一バイナリ → 撤去も容易
- **落とし穴**:
  - エラー時にオリジナル出力を見たい場合、一時的に無効化する必要
  - 一部ツールが期待する詳細出力（テスト失敗の完全 stack trace 等）が削れていないか要確認
- **本リポジトリでの推奨**: ✅ **最初に試すべき1つ**

---

## 3. Code Review Graph

- **Repo**: https://github.com/tirth8205/code-review-graph
- **形態**: Python パッケージ + MCP サーバー
- **主張**: レビューで 6.8x、デイリーコーディングで 49x 少ないトークン
- **手法**: Tree-sitter で AST グラフ構築。関数・クラス・import・呼び出し関係をノード／エッジ化。ファイル変更時に「blast radius」を計算し関係箇所のみ Claude に渡す
- **実態**:
  - インクリメンタル更新（SHA-256 ハッシュ）で 2,900 ファイル < 2 秒で再インデックス
  - ローカル完結・MIT
  - MCP 経由なので Claude Code に統合しやすい
- **落とし穴**:
  - **49x 削減は変更影響解析タスク限定**。普通の Q&A ではここまで出ない
  - 言語サポートは Tree-sitter grammar 次第
  - インデックス再構築コストを無視できない頻度の変更があると、効果薄

---

## 4. Context Mode

- **Repo**: https://github.com/mksglu/context-mode
- **形態**: Claude Code プラグイン
- **主張**: 98% 削減（ツール出力サイズ 315 KB → 5.4 KB）
- **手法**: ツール呼び出し結果を per-project SQLite に永続化。Markdown を heading で chunk 分割し FTS5 + Porter stemming で BM25 検索。`--continue` 時に作業状態を自動再構築
- **実態**:
  - Claude Code, Gemini CLI, VS Code Copilot で full session continuity 対応
  - **セッション圧縮（compaction）対策** としては筋が良い
- **落とし穴**:
  - 単発の質問・短時間タスクには benefit が小さい
  - SQLite のローカル管理が増える（`.gitignore` 必要）
  - 98% は「ツール出力経由のトークンのみ」の数字

---

## 5. nadimtuhin Claude Token Optimizer

- **Repo**: https://github.com/nadimtuhin/claude-token-optimizer
- **形態**: bash スクリプト + 設定プロンプト
- **主張**: 11K → 1.3K トークン（典型 83–87% 削減）
- **手法**: 5分のセットアップで以下を生成：
  - `CLAUDE.md`（~450 tokens）
  - `.claude/COMMON_MISTAKES.md`（~350 tokens）
  - `.claude/QUICK_START.md`（~100 tokens）
  - `.claude/ARCHITECTURE_MAP.md`（~150 tokens）
- **実態**:
  - **手法は王道**。実質「ちゃんとしたプロジェクト初期化」
  - 8 フレームワーク向けパターンあり
- **落とし穴**:
  - 既に `.claude/` を作り込んでいるリポジトリには差分が無い
  - COMMON_MISTAKES は「1時間以上溶かしたバグ」だけ書く規律が必要、それを破ると逆に context bloat
- **本リポジトリでの推奨**: ✅ **新規プロジェクト初期化時のチェックリストとして有用**

---

## 6. alexgreensh Token Optimizer

- **Repo**: https://github.com/alexgreensh/token-optimizer
- **形態**: Claude Code プラグイン（マーケットプレイス）
- **主張**: ghost token 駆除、compaction 後の品質劣化防止
- **手法**:
  - 6並列エージェントで AI セットアップを audit
  - 7-signal 品質スコアリング、Smart Compaction チェックポイント
  - ライブダッシュボード（USD・トークン・ターン）
- **実態**:
  - **診断ツール**。これ自体が tokens を削るのではなく「どこを削るべきか」を可視化
  - GitHub 647+ star、Claude Code / OpenClaw 対応
- **落とし穴**:
  - レポートを読んで自分で対処する前提
  - 「ghost token はプラン枠を消費」は事実だが、cached トークンとの区別を理解していないと誤読する

---

## 7. ooples Token Optimizer MCP

- **Repo**: https://github.com/ooples/token-optimizer-mcp
- **形態**: MCP サーバー（npm: `@ooples/token-optimizer-mcp`）
- **主張**: 95%+ 削減
- **手法**:
  - Brotli 圧縮（典型 2–4x、繰り返し多いコンテンツで最大 82x）
  - SQLite ベース永続キャッシュ
  - tiktoken で正確なトークン計測
  - 65 ツール（caching / compression / smart file ops）
- **実態**:
  - TypeScript 実装、オフライン動作・ゼロ依存
  - postinstall で Claude Desktop, Cursor, Cline 自動設定
- **落とし穴**:
  - 95%+ は **キャッシュヒット時** の数字。初回アクセスは効果なし
  - 65 ツールは多すぎて把握コストあり、選んで使う必要

---

## 8. Claude Context (Zilliz)

- **Repo**: https://github.com/zilliztech/claude-context
- **形態**: MCP サーバー（@zilliz/claude-context-mcp）+ VSCode 拡張 + コアエンジン
- **主張**: 同等検索品質下で 40% トークン削減
- **手法**:
  - BM25 + dense vector のハイブリッド検索
  - Merkle tree によるインクリメンタルインデックス
  - AST チャンキング
  - Zilliz Cloud / 自前 Milvus へ接続
- **実態**:
  - **大手バックアップ**（Zilliz）で安定運用が期待できる
  - 40% という数字は他ツールに比べ控えめで信頼度が高い
  - 大規模コードベース向け
- **落とし穴**:
  - Zilliz Cloud / Milvus セットアップが必要（ローカル完結ではない構成もある）
  - 埋め込み API のコスト（OpenAI / 他）が別途発生
- **本リポジトリでの推奨**: ✅ **チーム・本番運用ならこれ**

---

## 9. Claude Token Efficient

- **Repo**: https://github.com/drona23/claude-token-efficient
- **形態**: CLAUDE.md テンプレート集
- **主張**: 出力ヘビータスクで平均 ~63% 出力トークン削減
- **手法**: 3つの profile（agents / coding / 等）を使い分け
- **実態**:
  - **コードゼロ・ドロップインのテンプレート**
  - 持続セッション・大量出力タスク向け（一発質問では benefit 薄い）
- **落とし穴**:
  - 既存 `.claude/CLAUDE.md` と **強く重複**。マージするとルール衝突の可能性
  - 短時間 / フレッシュセッション中心の使い方では恩恵なし

---

## 10. Token Savior

- **Repo**: https://github.com/Mibayy/token-savior
- **形態**: MCP サーバー（pip: `token-savior-recall[mcp]`）
- **主張**: コードナビ 97% 削減、170+ セッションでの実測
- **手法**:
  - シンボル単位（function/class/import/call graph）でインデックス
  - SQLite WAL + FTS5 + vector embeddings
  - 永続メモリ（決定・bugfix・convention・session rollup）を Bayesian ROI ランキングで次回先頭に再注入
  - 106 ツール
- **実態**:
  - 「同じファイルを何度も読み直す」問題に直撃
  - 11 カテゴリのベンチマーク（audit / bug_fixing / refactoring 等）で 100%
- **落とし穴**:
  - MCP ツール 106 個は導入後の選定コスト
  - 永続メモリは **腐る情報** がノイズになりうる。定期的な棚卸しが必要

---

## まとめ：本リポジトリで導入を推奨するもの

| Tier | ツール | 理由 |
|------|--------|------|
| S | RTK | 副作用最小・入力トークン直撃 |
| A | Claude Context **or** Code Review Graph | 規模に応じて1つ |
| A | Context Mode | セッション継続を重視するなら |
| B | nadimtuhin Token Optimizer（手法のみ参照） | 新規プロジェクト初期化チェックリスト |
| B | alexgreensh Token Optimizer | 監査用、診断目的で時々起動 |
| C | ooples Token Optimizer MCP | MCP 経由のトークン消費が問題化したとき |
| C | Token Savior | 永続メモリが必要になったら |
| 不要 | Caveman, Claude Token Efficient | 既存 CLAUDE.md と重複 |
