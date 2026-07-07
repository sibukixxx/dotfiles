---
paths: internal/graph/resolver.go
---

# Resolver 構造体の管理ルール

## ファイル構造

| ファイル | 編集 | 説明 |
|----------|------|------|
| `resolver.go` | **手動編集する** | `Resolver` 構造体を定義 |
| `resolver_gen.go` | **編集禁止** | `resolver_generate.go` が自動生成。`NewResolverParams` と `NewResolver` を含む |
| `resolver_generate.go` | 必要時のみ編集 | ジェネレーター本体。`paramFieldTags` や `packageMap` の変更時のみ |

`make fix` を実行すると、`resolver.go` の `Resolver` struct から `resolver_gen.go` が丸ごと再生成される。

## `Resolver` 構造体の領域

```go
type Resolver struct {
    // ── 固定領域（*startsort* の外）──
    presenter.Presenters                          // 埋め込み
    BlobServer            *config.BlobServer
    Pool                  pond.Pool
    PublicIcsUrlGenerator appurl.PublicIcsUrlGenerator

    // ── ソート領域 ──
    // *startsort*
    SomeHandler  handler.SomeHandler   // handler.* を追加
    SomeUsecase  usecase.SomeUsecase   // usecase.* も追加可
    // *endsort*
}
```

| 領域 | 追加対象 | 注意 |
|------|----------|------|
| 固定領域 | `presenter`, `config`, インフラ依存 | 滅多に変更しない。追加時は `resolver_generate.go` の `packageMap` / `paramFieldTags` も確認 |
| ソート領域 | `handler.*Handler`, `usecase.*Usecase` | 末尾に追加して `make fix` でソート。順序は気にしなくてよい |

## 新規フィールド追加手順

### ソート領域 (handler / usecase)

1. `resolver.go` の `Resolver` 構造体の `// *startsort*` 〜 `// *endsort*` の間にフィールドを追加
2. `make fix` を実行（ソート + `resolver_gen.go` 再生成）

### 固定領域 (インフラ依存など)

1. `resolver.go` の `Resolver` 構造体の `// *startsort*` より上にフィールドを追加
2. 新パッケージなら `resolver_generate.go` の `packageMap` に追加
3. struct tag が必要なら `resolver_generate.go` の `paramFieldTags` に追加
4. `make fix` を実行
