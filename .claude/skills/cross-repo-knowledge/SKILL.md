---
name: cross-repo-knowledge
description: 兄弟リポジトリを参照・編集しながら、ナレッジが最も濃いリポジトリのコンテキストで作業する。Use when user says "兄弟リポの", "cross-repo", "他のリポジトリで", "別リポで作業", "../ で参照", "外側から作業", "sibling repo", or wants to apply knowledge from this repo to another repo.
---

# Cross-Repo Knowledge - 兄弟リポジトリ越境作業

ナレッジが最も濃いリポジトリ（ここ）で作業しながら、兄弟リポジトリを読み書きする。

## なぜこのスキルが必要か

- モノレポにできない事情があっても、**まるでモノレポであるかのように**扱える
- OSSリポジトリに内部の思考ロジックを書けない → 外側から読み書きで解決
- 他者がメンテしているリポジトリ → 参照しつつこちらのナレッジで作業
- 戦略文書・デザイン文書・マーケコピー・コード、すべてがAIの視界に入る
- ナレッジがコンパウンドで蓄積し、ショートカットが指数関数的に濃縮される

## ワークフロー

### Step 1: ターゲットリポジトリの特定

ユーザーが指定した兄弟リポジトリのパスを確認する。

```bash
# 兄弟リポジトリの存在確認
ls -la ../target-repo/

# リポジトリ構造の把握
rg --files ../target-repo/ | head -100
```

兄弟リポジトリが見つからない場合:
```bash
# 親ディレクトリにある全リポジトリを一覧
ls -la ../
```

### Step 2: ターゲットリポジトリの探索

ファイル構造とコードベースを理解する。

```bash
# ファイル一覧（gitignore考慮）
rg --files ../target-repo/

# 特定パターンのファイル検索
rg --files ../target-repo/ | rg '\.ts$'
rg --files ../target-repo/ | rg '\.md$'

# コード内容の検索
rg 'pattern' ../target-repo/

# 設定ファイルの確認
cat ../target-repo/package.json 2>/dev/null
cat ../target-repo/CLAUDE.md 2>/dev/null
```

Read ツールで直接ファイルを読む場合は **絶対パス** を使用する:
```
Read: /home/user/target-repo/src/index.ts
```

### Step 3: ナレッジの適用

このリポジトリに蓄積されたナレッジ（CLAUDE.md、rules、skills、references）を活用して、ターゲットリポジトリに対する作業を行う。

**読み取り専用の作業**:
- コードレビュー・分析
- アーキテクチャ評価
- ドキュメント生成（こちら側に出力）

**読み書き両方の作業**:
- バグ修正・機能追加
- リファクタリング
- 設定ファイルの更新
- テスト追加

Edit / Write ツールで兄弟リポジトリのファイルを編集する場合も **絶対パス** を使用する:
```
Edit: /home/user/target-repo/src/component.tsx
Write: /home/user/target-repo/docs/guide.md
```

### Step 4: 作業結果の管理

ターゲットリポジトリでの変更をコミットする場合:

```bash
# ターゲットリポジトリのgit操作
git -C ../target-repo/ status
git -C ../target-repo/ diff
git -C ../target-repo/ add -p
git -C ../target-repo/ commit -m "commit message"
```

このリポジトリ側にメモ・ログを残す場合は `z-ai/` に記録:
```bash
# z-ai/ はグローバルにgitignoreされている
echo "## target-repo 作業ログ" >> z-ai/cross-repo-log.md
```

## 活用パターン

### パターン1: OSSリポジトリへの貢献

こちらのリポジトリに戦略・設計意図・PRの下書きを置き、OSSリポジトリにはコードだけをコミットする。

```
dotfiles/z-ai/oss-strategy.md    ← 内部の思考（gitignore済み）
dotfiles/.claude/rules/           ← コーディング規約
../oss-project/src/               ← 実際のコード変更
```

### パターン2: クライアントプロジェクト

ナレッジベース（テンプレート・ベストプラクティス）をこちらに蓄積し、クライアントリポジトリに適用する。

```
dotfiles/.claude/skills/          ← 汎用スキル
dotfiles/.claude/rules/           ← 品質基準
../client-project/                ← クライアントのコード
```

### パターン3: 複数リポジトリの横断作業

共通の変更を複数リポジトリに適用する。

```bash
# 全兄弟リポジトリでパターンを検索
for repo in ../repo-a ../repo-b ../repo-c; do
  echo "=== $repo ==="
  rg 'deprecated-api' "$repo" || true
done
```

### パターン4: ドキュメント・コピーの生成

コードベースを読み取り、マーケティングコピー・README・API仕様書を生成する。

```
dotfiles/.claude/skills/content-creator/  ← コンテンツ生成スキル
../product-repo/src/                      ← 製品コードを参照
../product-repo/docs/                     ← 生成物の出力先
```

## 重要な注意事項

- **絶対パス**: Read / Edit / Write ツールでは必ず絶対パスを使う
- **git操作**: ターゲットリポジトリの `git` 操作は `git -C ../target-repo/` で行う
- **破壊的操作**: 他者のリポジトリでの force push / reset は絶対にしない
- **機密情報**: ターゲットリポジトリの機密情報をこちらにコピーしない
- **z-ai/**: 作業メモ・戦略文書はこちらの `z-ai/` に記録（gitignore済み）
