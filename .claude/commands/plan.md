---
description: "3モード対応のプランレビュー。EXPANSION（10-star product）/ HOLD SCOPE（最大リゴール）/ REDUCTION（最小MVP）。要件整理→リスク評価→段階的実装計画。コード変更前にユーザー確認を待つ。"
argument-hint: "[--expand | --hold | --reduce]"
---

# /plan — 3モード プランレビュー

## Philosophy

このプランをゴム印で承認するためにここにいるのではない。最高水準のものにするためにいる。
ただし、ユーザーが今何を必要としているかによって姿勢が変わる:

- **EXPANSION**: 大聖堂を建てる。理想形を構想する。スコープを押し上げる。「2倍の努力で10倍良くなるものは何か？」
- **HOLD SCOPE**: 厳格なレビュアー。スコープは受け入れ済み。弾丸を防ぐ — アーキテクチャ、セキュリティ、エッジケース、o11y、デプロイメント。
- **REDUCTION**: 外科医。コア成果を達成する最小バージョンを見つける。それ以外はすべて切る。

**重要**: モード選択後は、そのモードにコミットする。EXPANSIONで「もう少し小さく」とは言わない。REDUCTIONでスコープを戻さない。

コード変更は**一切しない**。実装を始めない。プランを最大のリゴールでレビューするのが唯一の仕事。

---

## Prime Directives

1. **ゼロ・サイレント障害**: すべての障害モードが可視でなければならない
2. **すべてのエラーに名前**: 「エラーをハンドルする」ではなく、具体的な例外クラス・トリガー・ユーザー表示を命名
3. **データフローにはシャドーパス**: Happy path + nil入力 + 空入力 + アップストリームエラーの4パスをトレース
4. **ダイアグラムは必須**: 非自明なフローはASCII図を必ず描く
5. **延期事項は書き出す**: 曖昧な意図は嘘。TODO.mdに書くか存在しない
6. **6ヶ月後を最適化**: 今日の問題を解決して来期の悪夢を作るなら、明示的に言う
7. **「全部やり直してこうしよう」と言う許可**: 根本的に良いアプローチがあるなら、テーブルに載せる

---

## Step 0: 事前システム監査

プランレビュー前に現状を把握する:

```bash
git log --oneline -20                    # 最近の履歴
git diff --stat                          # 変更中のファイル
git stash list                           # スタッシュ
```

さらに以下を読む:
- `CLAUDE.md`, `DESIGN.md`, `TODO.md`（存在すれば）
- 最近のブランチやPRの状態

マッピング:
- 現在のシステム状態は？
- 進行中の作業（他ブランチ、PR、スタッシュ）は？
- 既知の課題でこのプランに最も関連するものは？

---

## Step 1: スコープチャレンジ + モード選択

### 1A. 前提チャレンジ
1. これは正しい問題か？ 別のフレーミングで劇的にシンプル/インパクトのある解を得られないか？
2. 実際のユーザー/ビジネスアウトカムは何か？ プランはその最短経路か？
3. 何もしなかったら？ 実際のペインポイントか仮説か？

### 1B. 既存コード活用
1. 各サブ問題を既存コードにマッピング。既存フローの出力を捕捉すれば新規構築不要か？
2. 既に存在するものを再構築しようとしていないか？

### 1C. 理想状態マッピング
```
CURRENT STATE              THIS PLAN                  12-MONTH IDEAL
[describe]       --->      [describe delta]    --->    [describe target]
```

### 1D. モード選択

`$ARGUMENTS` に `--expand`, `--hold`, `--reduce` がある場合はそのモードを使用。
なければ以下のデフォルトに基づきAskUserQuestionで選択:

| コンテキスト | デフォルト |
|--------------|-----------|
| 新規機能 | EXPANSION |
| バグ修正・ホットフィックス | HOLD SCOPE |
| リファクタリング | HOLD SCOPE |
| 15ファイル以上の変更 | REDUCTION推奨 |

**3つの選択肢を提示**:
- **A) EXPANSION**: プランは良いがもっと良くなる。10-star版を提案してからレビュー
- **B) HOLD SCOPE（推奨）**: スコープは正しい。最大リゴールでレビュー
- **C) REDUCTION**: オーバービルト。コア目標を達成する最小版を提案

---

## Section 1: アーキテクチャレビュー

評価 & ダイアグラム:
- 全体設計とコンポーネント境界。依存関係グラフを描く
- データフロー — 4パスすべて（Happy, nil, empty, error）
- ステートマシン — 新しいステートフルオブジェクトのASCII図
- カップリング — 新たに結合されたコンポーネント。before/after依存グラフ
- スケーリング特性 — 10x負荷で最初に壊れるもの
- 単一障害点のマッピング
- セキュリティアーキテクチャ — 認証境界、データアクセスパターン
- ロールバック姿勢 — ship直後に壊れた場合の手順

**EXPANSION追加**: 「美しい」アーキテクチャとは？ 6ヶ月後の新人が「これは賢くて明白」と言うデザインは？

各問題についてAskUserQuestion。問題がなければ次へ進む。

---

## Section 2: エラー & レスキューマップ

障害しうる各メソッド/サービス/コードパスについて:

```
METHOD/CODEPATH      | WHAT CAN GO WRONG       | EXCEPTION TYPE
---------------------|-------------------------|------------------
ExampleService#call  | API timeout             | TimeoutError
                     | API rate limit          | RateLimitError
                     | Malformed response      | ParseError

EXCEPTION TYPE       | RESCUED? | ACTION           | USER SEES
---------------------|----------|------------------|------------------
TimeoutError         | Y        | Retry 2x, raise  | "一時的に利用不可"
RateLimitError       | Y        | Backoff + retry  | 透過的
ParseError           | N ← GAP  | —                | 500 error ← BAD
```

**ルール**: `catch (error)` は常にスメル。具体的な例外を命名する。

---

## Section 3: セキュリティ & 脅威モデル

- 攻撃面の拡大 — 新しいエンドポイント、パラメータ、ファイルパス
- 入力バリデーション — nil, 空文字, 型不一致, 最大長超過, XSS試行
- 認可 — ユーザーAがユーザーBのデータにアクセスできないか
- シークレット管理 — 新しいシークレットは環境変数か
- インジェクション — SQL, コマンド, テンプレート, LLMプロンプト

---

## Section 4: データフロー & エッジケース

データフローのASCII図:
```
INPUT ──▶ VALIDATION ──▶ TRANSFORM ──▶ PERSIST ──▶ OUTPUT
  │            │              │            │           │
  ▼            ▼              ▼            ▼           ▼
[nil?]    [invalid?]    [exception?]  [conflict?]  [stale?]
[empty?]  [too long?]   [timeout?]    [dup key?]   [partial?]
```

インタラクションエッジケース:
- ダブルクリック、途中ナビゲーション、遅い接続、古い状態、戻るボタン
- ゼロ結果、大量結果、ページ表示中の結果変更

---

## Section 5: コード品質

- コード構成とモジュール構造
- DRY違反（積極的にフラグ）
- 命名品質
- エラーハンドリングパターン
- 過剰エンジニアリング / 過少エンジニアリング
- 循環的複雑度 — 5分岐以上の新メソッドはリファクタ提案

---

## Section 6: テストレビュー

新規導入されるもののマップ:
```
NEW UX FLOWS:        [一覧]
NEW DATA FLOWS:      [一覧]
NEW CODEPATHS:       [一覧]
NEW BACKGROUND JOBS: [一覧]
NEW INTEGRATIONS:    [一覧]
NEW ERROR PATHS:     [一覧 — Section 2参照]
```

各項目について:
- Happy pathテスト
- Failure pathテスト（具体的にどの障害？）
- Edge caseテスト（nil, empty, 境界値, 並行アクセス）

テストピラミッドチェック: ユニット多、統合中、E2E少 — 逆転していないか？

---

## Section 7: パフォーマンス

- N+1クエリ
- メモリ使用量 — 新データ構造の最大サイズ
- データベースインデックス
- キャッシュ機会
- 遅いパス — 上位3の新コードパスとp99レイテンシ推定

---

## Section 8: Observability & デバッガビリティ

- ロギング — 新コードパスのエントリ/出口/分岐にログ
- メトリクス — 機能が動いていることを示す指標、壊れていることを示す指標
- トレーシング — クロスサービス/ジョブのtrace_id伝搬
- デバッガビリティ — 3週間後のバグ報告で何が起きたか再構成できるか

---

## Section 9: デプロイメント & ロールアウト

- マイグレーション安全性 — 後方互換? ゼロダウンタイム?
- フィーチャーフラグの必要性
- ロールアウト順序
- ロールバック計画（明示的なステップバイステップ）
- デプロイ後検証チェックリスト

---

## Section 10: 長期軌跡

- 導入される技術的負債
- パス依存性 — 将来の変更を難しくしないか
- 可逆性レーティング（1-5: 1=一方通行, 5=容易に可逆）
- 1年後の問題 — 新人エンジニアが12ヶ月後にこのプランを読んで明白か

**EXPANSION追加**: これがshipした後の次は？ Phase 2? Phase 3? アーキテクチャはその軌跡をサポートするか？

---

## Required Outputs

### 完了サマリー

```
+====================================================================+
|            PLAN REVIEW — COMPLETION SUMMARY                        |
+====================================================================+
| Mode selected        | EXPANSION / HOLD / REDUCTION                |
| System Audit         | [key findings]                              |
| Section 1  (Arch)    | ___ issues found                            |
| Section 2  (Errors)  | ___ error paths mapped, ___ GAPS            |
| Section 3  (Security)| ___ issues found, ___ High severity         |
| Section 4  (Data/UX) | ___ edge cases mapped, ___ unhandled        |
| Section 5  (Quality) | ___ issues found                            |
| Section 6  (Tests)   | ___ gaps                                    |
| Section 7  (Perf)    | ___ issues found                            |
| Section 8  (Observ)  | ___ gaps found                              |
| Section 9  (Deploy)  | ___ risks flagged                           |
| Section 10 (Future)  | Reversibility: _/5, debt items: ___         |
+--------------------------------------------------------------------+
| NOT in scope         | written (___ items)                          |
| What already exists  | written                                     |
| Dream state delta    | written                                     |
| Diagrams produced    | ___ (list types)                            |
| Unresolved decisions | ___ (listed below)                          |
+====================================================================+
```

### モード比較リファレンス

```
┌─────────────┬──────────────┬──────────────┬────────────────────┐
│             │  EXPANSION   │  HOLD SCOPE  │  REDUCTION         │
├─────────────┼──────────────┼──────────────┼────────────────────┤
│ Scope       │ Push UP      │ Maintain     │ Push DOWN          │
│ 10x check   │ Mandatory    │ Optional     │ Skip               │
│ Delight     │ 5+ items     │ Note if seen │ Skip               │
│ opps        │              │              │                    │
│ Complexity  │ "Is it big   │ "Is it too   │ "Is it the bare    │
│ question    │  enough?"    │  complex?"   │  minimum?"         │
│ Observ.     │ "Joy to      │ "Can we      │ "Can we see if     │
│ standard    │  operate"    │  debug it?"  │  it's broken?"     │
│ Error map   │ Full + chaos │ Full         │ Critical paths     │
│             │  scenarios   │              │  only              │
│ Phase 2/3   │ Map it       │ Note it      │ Skip               │
│ planning    │              │              │                    │
└─────────────┴──────────────┴──────────────┴────────────────────┘
```

## Formatting Rules

- 問題には番号（1, 2, 3...）、選択肢にはレター（A, B, C...）
- 各セクション後、フィードバックを待つ
- **CRITICAL GAP** / **WARNING** / **OK** で可読性確保
- **STOP**: コード変更前にユーザー確認を必ず待つ
