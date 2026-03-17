---
description: "Fix-Firstコードレビュー。機械的修正は自動適用、判断が必要な問題のみ質問。TDD/テスト品質、コード品質、セキュリティ、アーキテクチャ、プロジェクトルール、パフォーマンスの6観点。"
argument-hint: "[--staged | --all | --base <branch>]"
allowed-tools: ["Bash(git status:*)", "Bash(git diff:*)", "Bash(git rev-parse:*)", "Bash(git fetch:*)", "Bash(git log:*)", "Read", "Edit", "Glob", "Grep", "AskUserQuestion"]
---

# /review - Fix-First コードレビュー

機械的な問題は自動修正し、判断が必要な問題だけユーザーに確認する。

## 使い方

```
/review              # ワーキングツリーの全変更をレビュー
/review --staged     # ステージ済みのみ
/review --base main  # 特定ブランチとの差分をレビュー（PR向け）
```

---

## Step 1: 変更検出

### 引数の解析

```
引数: $ARGUMENTS
- --staged: ステージ済み変更のみ
- --base <branch>: 指定ブランチとの差分（featureブランチのPRレビュー向け）
- --all または 空: すべての変更
```

### gitリポジトリ確認

```bash
git rev-parse --git-dir 2>/dev/null
```

gitリポジトリでない場合、エラーを表示して終了。

### ベースブランチの検出（--base指定時）

```bash
git fetch origin <base> --quiet
```

### 差分取得

`--base <branch>` の場合:
```bash
git diff origin/<base>...HEAD
git diff origin/<base> --stat
```

`--staged` の場合:
```bash
git diff --staged
```

それ以外:
```bash
git diff
git diff --staged
```

変更が0件の場合: 「レビュー対象の変更がありません。」と表示して終了。

---

## Step 2: チェックリスト読み込み

`review-checklist.md` の内容に基づいてレビューを実施する。

---

## Step 3: コンテキスト収集

### 変更ファイルの読み込み

各変更ファイルについてReadツールで内容を読み込む。

### テストファイルの検索

| 言語             | パターン                                     |
| ---------------- | -------------------------------------------- |
| Go               | `*_test.go`（同一ディレクトリ）              |
| Rust             | `tests/**/*.rs`, モジュール内 `#[cfg(test)]` |
| TypeScript/React | `*.test.ts`, `*.test.tsx`, `__tests__/**`    |
| Python           | `test_*.py`, `*_test.py`                     |
| Ruby             | `*_spec.rb`, `*_test.rb`                     |

### プロジェクトルール読み込み

以下が存在すればReadツールで読み込む:
1. `CLAUDE.md`（プロジェクトルート）
2. `docs/DESIGN.md`
3. `.claude/rules/`（ディレクトリ内のファイル）

---

## Step 4: Two-Pass Review

### Pass 1 — CRITICAL

チェックリストの Pass 1 カテゴリを適用:
1. **SQL & Data Safety**
2. **Race Conditions & Concurrency**
3. **Input Validation & Trust Boundary**
4. **Enum & Value Completeness** — diff外のコードもGrepで追跡

### Pass 2 — INFORMATIONAL

チェックリストの Pass 2 カテゴリを適用:
1. **Conditional Side Effects**
2. **Magic Numbers & String Coupling**
3. **Dead Code & Consistency**
4. **Test Gaps**
5. **Crypto & Entropy**
6. **Type Safety at Boundaries**
7. **Performance**

### 追加観点（常に実施）

1. **TDD/テスト品質** - テストの有無、カバレッジ、テストファースト準拠
2. **アーキテクチャ** - 設計パターン、依存関係、責務分離、Tidy First
3. **プロジェクトルール** - CLAUDE.md, DESIGN.md, .claude/rules準拠

---

## Step 5: Fix-First Review

**すべての指摘にアクションを取る — 報告だけで終わらない。**

### Step 5a: 各指摘を分類

チェックリストの Fix-First Heuristic に基づき、各指摘を AUTO-FIX または ASK に分類。

### Step 5b: AUTO-FIX を自動適用

各修正をEditツールで直接適用。1行サマリーを出力:
```
[AUTO-FIXED] [file:line] 問題 → 修正内容
```

### Step 5c: ASK をバッチ質問

ASK項目が残っている場合、**1つの AskUserQuestion** にまとめる:

```
自動修正: N件完了。以下 M件はご判断ください:

1. [CRITICAL] app/models/post.rb:42 — ステータス遷移のレースコンディション
   修正案: WHERE句にold_status条件を追加
   → A) 修正  B) スキップ

2. [INFORMATIONAL] app/services/generator.rb:88 — LLM出力の型チェック未実施
   修正案: JSONスキーマバリデーション追加
   → A) 修正  B) スキップ

推奨: 両方修正 — #1は実際のレースコンディション、#2はサイレントデータ破損を防止。
```

3件以下のASK項目なら個別のAskUserQuestionでも可。

### Step 5d: ユーザー承認後に修正適用

「修正」を選択された項目をEditツールで適用。

ASK項目がない場合（全てAUTO-FIX）、質問をスキップ。

---

## Step 6: レビュー結果サマリー

```markdown
# Pre-Landing Review

## Summary
| カテゴリ           | Critical | Warning | Info |
|--------------------|----------|---------|------|
| SQL & Data Safety  | X        | X       | X    |
| ...                | ...      | ...     | ... |
| **合計**           | **X**    | **X**   | **X**|

## Auto-Fixed (N件)
- [file:line] 問題 → 修正内容

## User-Decided (M件)
- [file:line] 問題 → 修正/スキップ

## Suppressions Applied
チェックリストの抑制ルールに基づきN件スキップ
```

---

## 重要な注意事項

### Fix-First の原則
- **レポートだけで終わらない** — すべての指摘にアクションを取る
- **AUTO-FIX は承認不要** — 機械的な修正は直接適用
- **コミットはしない** — 修正はワーキングツリーに適用のみ。コミットは `/ship` の仕事
- **FULL diff を先に読む** — diff内で既に対処済みの問題をフラグしない

### レビュー対象外
- バイナリファイル
- 自動生成ファイル（`node_modules/`, `.git/`等）
- ロックファイル（`package-lock.json`, `Cargo.lock`等）
- 設定ファイル（`.gitignore`, `.editorconfig`等）

### エラーハンドリング
- gitリポジトリでない → エラー表示して終了
- ファイル読み込みエラー → スキップして続行
- 100ファイル以上 → `--staged` や `--base` で対象を絞ることを推奨
