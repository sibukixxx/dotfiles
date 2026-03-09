---
description: "Git worktreeの作成・一覧・削除・並列タスク実行を管理する"
argument-hint: "[create|list|remove|spawn] [args...]"
---

# /worktree - Worktree管理コマンド

Git worktreeの作成、一覧表示、削除、並列タスク生成を行う。

## 使い方

```
/worktree create feat/user-auth        # worktree作成
/worktree list                          # 一覧表示
/worktree remove feat/user-auth         # 削除
/worktree spawn plan.md                 # プランからworktree群を生成
```

引数なしの場合は一覧を表示する。

---

## サブコマンド

### create - Worktree作成

```
/worktree create <branch-name> [base-branch]
```

**処理**:

1. ブランチ名のバリデーション（`<type>/<kebab-case>` 形式）
2. base-branch（デフォルト: 現在のブランチ）から新しいブランチを作成
3. worktreeを `../<repo-name>-wt-<branch-name>/` に配置

```bash
# リポジトリ名を取得
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
BRANCH_NAME=$1
BASE_BRANCH=${2:-$(git branch --show-current)}
WT_DIR="../${REPO_NAME}-wt-$(echo $BRANCH_NAME | tr '/' '-')"

# worktree作成
git worktree add -b "$BRANCH_NAME" "$WT_DIR" "$BASE_BRANCH"
```

**出力**:
```
✓ Worktree created
  Branch: feat/user-auth
  Path: ../my-app-wt-feat-user-auth/
  Base: main
```

### list - 一覧表示

```
/worktree list
```

```bash
git worktree list
```

各worktreeのブランチ名、パス、最新コミットを表示。

### remove - Worktree削除

```
/worktree remove <branch-name>
```

**処理**:

1. worktreeに未コミットの変更がないか確認
2. 変更がある場合はユーザーに確認（AskUserQuestion）
3. worktreeを削除
4. ブランチも削除するか確認

```bash
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
BRANCH_NAME=$1
WT_DIR="../${REPO_NAME}-wt-$(echo $BRANCH_NAME | tr '/' '-')"

# 未コミット変更の確認
git -C "$WT_DIR" status --porcelain

# worktree削除
git worktree remove "$WT_DIR"

# ブランチ削除（ユーザー確認後）
git branch -d "$BRANCH_NAME"
```

### spawn - プランからworktree群を生成

```
/worktree spawn <plan-file>
```

プランファイル（DESIGN.md, TODO.md, plan.md など）を読み込み、フェーズごとにworktreeを作成する。

**処理**:

1. プランファイルを読み取り
2. フェーズ/タスクを解析
3. 各フェーズ用のworktreeを作成
4. 各worktreeにタスク情報を配置

**プランファイルの形式**:

```markdown
### Phase 1: User Authentication
- [ ] Login form
- [ ] JWT tokens

### Phase 2: Dashboard
- [ ] Stats overview
- [ ] Charts
```

**実行結果**:
```
✓ Spawned 2 worktrees from plan.md

Worktrees:
1. feat/phase-1-user-auth → ../my-app-wt-feat-phase-1-user-auth/
2. feat/phase-2-dashboard → ../my-app-wt-feat-phase-2-dashboard/

推奨マージ順序:
1. feat/phase-1-user-auth (依存なし)
2. feat/phase-2-dashboard (phase-1に依存する可能性あり)
```

---

## Worktree命名規則

CLAUDE.mdの Worktree Conventions セクションに従う：

- **ブランチ名**: `<type>/<kebab-case-description>`
- **配置先**: `../<repo-name>-wt-<branch-name>/`
- **typeの種類**: feat, fix, refactor, chore, docs, test

---

## マージワークフロー

worktreeの作業が完了したら、以下の手順でマージ：

```bash
# 1. メインブランチを最新に
git checkout main && git pull

# 2. worktreeのブランチをマージ
git merge feat/user-auth

# 3. worktreeを削除
git worktree remove ../my-app-wt-feat-user-auth/
git branch -d feat/user-auth
```

---

## 重要な注意事項

- **未コミット変更の保護**: 削除前に必ず確認
- **マージ順序**: 依存関係を考慮
- **メインブランチの同期**: マージ前にpull
- **クリーンアップ**: マージ後はworktreeとブランチを削除
