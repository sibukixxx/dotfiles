---
description: "Pre-Landing Review付きの完全自動shipワークフロー。baseマージ → テスト → レビュー → bisectableコミット → push → PR作成 → merge。"
argument-hint: "[--squash|--rebase|--merge] [--draft] [--no-merge] [--no-review]"
---

# /ship — 完全自動 Ship ワークフロー

ユーザーが `/ship` と言ったら**実行する**。確認を求めない（例外あり）。

**確認を求める場合のみ:**
- ベースブランチにいる場合（中止）
- マージコンフリクトが自動解決不可（停止、コンフリクト表示）
- テスト失敗（停止、失敗表示）
- Pre-Landing Reviewで ASK 項目がある場合

**確認不要:**
- 未コミット変更（常に含める）
- コミットメッセージ（自動生成）
- CHANGELOG内容（自動生成）

---

## Step 1: Pre-flight

1. 現在のブランチを確認。ベースブランチ上なら **中止**: 「ベースブランチにいます。フィーチャーブランチからshipしてください。」

2. `git status` で状態確認（`-uall` は使わない）。

3. ベースブランチを検出:
```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "main"
```

4. `git diff <base>...HEAD --stat` と `git log <base>..HEAD --oneline` で変更内容を把握。

---

## Step 2: ベースブランチのマージ（テスト前）

```bash
git fetch origin <base> && git merge origin/<base> --no-edit
```

**マージコンフリクト**: 単純なら自動解決を試みる。複雑なら **停止** してコンフリクトを表示。

---

## Step 3: テスト実行（マージ後のコードで）

CLAUDE.md の Build / Test Command Detection テーブルに基づいてテストコマンドを自動検出:

| Detection File | Test Command |
|----------------|-------------|
| `Makefile` | `make test` |
| `package.json` | `pnpm test` |
| `Cargo.toml` | `cargo test` |
| `go.mod` | `go test ./...` |
| `pyproject.toml` | `pytest` |
| `Gemfile` | `bundle exec rake test` |

**テスト失敗**: 失敗を表示して **停止**。続行しない。

**全パス**: 簡潔にカウントを表示して続行。

テストフレームワークが検出されない場合はスキップして続行。

---

## Step 4: Pre-Landing Review（`--no-review` でスキップ可）

`review-checklist.md` の内容に基づきdiffをレビュー:

1. `git diff origin/<base>` で全差分を取得。

2. Two-Pass Review:
   - **Pass 1 (CRITICAL)**: SQL, Race Conditions, Input Validation, Enum Completeness
   - **Pass 2 (INFORMATIONAL)**: 残りのカテゴリ

3. **Fix-First Heuristic** で分類:
   - **AUTO-FIX**: 機械的修正は直接適用。1行サマリーを出力。
   - **ASK**: 判断が必要なものは AskUserQuestion でバッチ質問。

4. **修正が適用された場合**:
   修正ファイルをステージして続行（別コミットにはしない — Step 6でまとめる）。

5. **出力**: `Pre-Landing Review: N issues — M auto-fixed, K asked (J fixed, L skipped)`

---

## Step 5: ドキュメント鮮度チェック

差分がドキュメントファイル（README.md, ARCHITECTURE.md, CLAUDE.md等）の記述内容に影響する場合、INFORMATIONAL としてフラグ:
「ドキュメントが古くなっている可能性: [file]」

---

## Step 6: Bisectable コミット

**目標**: `git bisect` でうまく動く小さな論理コミットを作成。

1. 差分を論理グループに分析。各コミットは **1つの一貫した変更** を表す。

2. **コミット順序**（早いものから）:
   - **インフラ**: マイグレーション、設定、ルート
   - **モデル & サービス**: 新モデル、サービス（テスト含む）
   - **コントローラー & ビュー**: コントローラー、ビュー、JS/Reactコンポーネント（テスト含む）
   - **メタデータ**: VERSION + CHANGELOG（ある場合、最終コミット）

3. **分割ルール**:
   - モデルとそのテストは同じコミット
   - 差分が小さい（< 50行、< 4ファイル）なら単一コミットで良い

4. **各コミットは独立して有効** — 壊れたインポートや存在しないコードへの参照なし。

5. コミットメッセージ形式:
```bash
git commit -m "$(cat <<'EOF'
<emoji> <type>: <日本語サブジェクト>

<日本語ボディ>

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

CLAUDE.md の Conventional Commit ルールに従う。

---

## Step 7: Push

```bash
git push -u origin <branch-name>
```

---

## Step 8: PR 作成

引数に基づいてマージ戦略を決定:
- `--squash`（デフォルト）: squash merge
- `--rebase`: rebase merge
- `--merge`: 通常のmerge commit
- `--draft`: Draft PR を作成（マージなし）
- `--no-merge`: PR作成まで（マージなし）

```bash
gh pr create --base <base> --title "<emoji> <type>: <日本語サマリー>" --body "$(cat <<'EOF'
## Summary
<変更の箇条書き>

## Pre-Landing Review
<Step 4の結果。問題なしなら "No issues found.">

## Test plan
- [x] テスト全パス
- [x] Pre-Landing Review 完了

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

`--draft` でなく `--no-merge` でもない場合、PR作成後にマージ:

```bash
gh pr merge --squash --delete-branch
```

（`--rebase` / `--merge` 指定時はそれぞれの戦略を使用）

**PR URL を出力** — ユーザーが最後に見るもの。

---

## Important Rules

- **テストをスキップしない** — 失敗したら停止
- **強制pushしない** — 通常の `git push` のみ
- **bisectableにコミットを分割** — 各コミット = 1つの論理変更
- **目標: ユーザーが `/ship` と言ったら、次に見るのは PR URL**
