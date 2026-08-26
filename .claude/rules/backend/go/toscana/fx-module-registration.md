---
paths: internal/usecase/module.go,internal/handler/module.go,internal/infra/persistence/module.go
---

# FX モジュール登録ルール (`module.go`)

## ソート不要

`// *startsort*` と `// *endsort*` の間なら**末尾に追加**して `make fix` で自動ソート。アルファベット順を気にする必要なし。

## 基本原則

新しいユースケースやハンドラーを作成した場合、対応する `module.go` に `fx.Provide` で登録する。登録を忘れると起動時に依存性解決エラーが発生する。

## 登録パターン

### usecase/module.go

`*startsort*` 領域は1つ。

```go
fx.Provide(New{UsecaseName}Usecase),
```

### handler/module.go

`*startsort*` 領域が **3つ** ある。種別に応じて正しい領域に追加すること。

| 領域 | 種別 | 登録パターン |
|------|------|-------------|
| 1つ目 | 通常ハンドラー（Mutation/Query用） | `fx.Provide(New{Name}Handler)` |
| 2つ目 | リスナー（PostgreSQL LISTEN/NOTIFY） | `fx.Provide(fx.Annotate(New{Name}Handler, fx.ResultTags(\`group:"listeners"\`)))` |
| 3つ目 | ジョブハンドラー（SQS Worker） | `fx.Provide(fx.Annotate(New{Name}Handler, fx.ResultTags(\`group:"jobhandlers"\`)))` |

通常の Mutation ハンドラーは **1つ目の領域** に追加する。間違った領域に追加すると DI 解決エラーになる。

## 命名規則

| レイヤー | ファイル名 | コンストラクタ名 |
|---------|-----------|-----------------|
| Usecase | `{action}_{entity}_usecase.go` | `New{ActionEntity}Usecase` |
| Handler | `{action}_{entity}_handler.go` | `New{ActionEntity}Handler` |

## hygen 使用時の注意

hygen は `// FIXME:` 付きで **`fx.Module(...)` の閉じ括弧の外（ファイル末尾）** に追記する。この位置は `*startsort*` / `*endsort*` の外側であり、`make fix` のソート対象にならない。

**正しい手順**:

1. ファイル末尾に追加された `// FIXME:` 行を **削除**
2. 正しい `*startsort*` / `*endsort*` 領域内に `fx.Provide(...)` を追加
3. `make fix` を実行（自動ソートされる）
