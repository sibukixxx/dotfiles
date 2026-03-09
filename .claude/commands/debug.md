---
description: "エラーメッセージを解析し、原因を特定して修正する。XCode/Vite/Go/Rust/TypeScript対応"
argument-hint: "[エラーメッセージ or 空白で自動検出]"
---

# /debug - エラー解析＆修正コマンド

エラーメッセージを解析して原因を特定し、修正を提案・実行する。

## 使い方

### エラーメッセージ付き
```
/debug Cannot find module '@/components/Button'
```

### 引数なし（自動検出）
```
/debug
```
直前のビルド/テスト出力からエラーを検出する。

---

## [1/4] エラー取得

### 引数からエラーを取得

- `$1` が存在する場合: エラーメッセージとして解析
- `$1` が空の場合: ビルド/テストを実行してエラーを検出

$1が空の場合、プロジェクトの Build / Test Command Detection テーブル（CLAUDE.md参照）に基づいてビルドコマンドを実行し、エラーを取得する。

```
エラー内容: $1
```

---

## [2/4] エラー解析

### エラーフォーマットの判別

以下のパターンを識別する：

| エラー形式 | 言語/ツール | パターン例 |
|-----------|------------|-----------|
| `file:line:col: error:` | Go, C, GCC | `main.go:15:3: undefined: foo` |
| `error[E0xxx]:` | Rust/Cargo | `error[E0433]: failed to resolve` |
| `TS\d{4}:` | TypeScript | `TS2345: Argument of type...` |
| `error: ...` + `-->file:line:col` | Rust | multiline Rust error |
| `Module not found:` | Webpack/Vite | `Module not found: Can't resolve...` |
| XCode形式 | Swift/ObjC | `Build input file cannot be found` |
| Stack trace | JS/TS/Python | `at Object.<anonymous> (file:line:col)` |
| pytest形式 | Python | `FAILED tests/test_foo.py::test_bar` |

### 情報抽出

1. **ファイルパス** - エラーが発生しているファイル
2. **行番号** - エラーの位置
3. **エラーコード** - あれば（TS2345, E0433 etc.）
4. **エラーメッセージ** - 人間が読める説明
5. **関連ファイル** - import/dependencyエラーの場合の参照先

---

## [3/4] 原因特定

### ファイルの読み取り

エラーで指摘されたファイルを Read ツールで読み取る。

### エラーカテゴリ別の調査

| カテゴリ | 調査内容 |
|---------|---------|
| **Import/Module** | パスの存在確認、tsconfig/vite.config のエイリアス確認 |
| **Type Error** | 型定義の確認、genericsの整合性 |
| **Build Config** | ビルド設定ファイルの確認 |
| **Dependency** | package.json/Cargo.toml/go.mod の依存確認 |
| **Runtime** | スタックトレースの解析、変数の状態推測 |
| **Signing/Provisioning** | XCode署名設定、プロビジョニングプロファイル |

### 関連ファイルの探索

Grep/Glob ツールを使って関連するファイルを探索：
- importしているファイル
- 同じモジュールの他のファイル
- 設定ファイル

---

## [4/4] 修正実行

### 修正の提案

原因を特定したら、修正内容をユーザーに説明：

```
原因: [簡潔な説明]
修正: [何をどう変更するか]
影響範囲: [変更による影響]
```

### 修正の実行

Edit ツールで修正を実行する。

### 修正の確認

修正後、Build / Test Command Detection テーブルに基づいてビルド/テストを再実行し、エラーが解消されたことを確認。

**まだエラーがある場合**: [2/4] に戻って次のエラーを解析。最大10回まで繰り返す。

---

## 完了サマリー

```
✓ デバッグ完了

修正内容:
- [修正した内容のリスト]

変更ファイル:
- [変更したファイルパスのリスト]

ビルド結果: SUCCESS
```

## 重要な注意事項

- **最小限の修正**: エラーを直すために必要な最小限の変更のみ行う
- **リファクタリングしない**: デバッグ中にコードの改善は行わない
- **テストを壊さない**: 既存のテストが通ることを確認
- **10回ループ上限**: 10回修正しても解消しない場合はユーザーに報告して方針を相談
