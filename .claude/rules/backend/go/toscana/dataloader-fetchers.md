---
paths: internal/dataloader/fetchers.go,internal/dataloader/fetchers_gen.go,internal/dataloader/loaders.go
---

# DataLoader 編集ルール

## ソート不要

`// *startsort*` と `// *endsort*` の間なら**末尾に追加**して `make fix` で自動ソート。アルファベット順を気にする必要なし。

## 編集箇所

### fetchers.go

`Fetchers` 構造体のみ編集。`NewFetchersParams` と `NewFetchers` は `fetchers_gen.go` に `make fix` で自動生成されるため編集不要。

### fetchers_gen.go

**直接編集禁止。** `fetchers_generate.go` によって `fetchers.go` の `Fetchers` struct から自動生成される。

### loaders.go

`Loaders` 構造体と `NewLoaders` 関数の両方を編集。`Clear()` メソッドは `loaders_generated.go` に自動生成される。

## 命名対応

| Fetchers | Loaders |
|----------|---------|
| `Load{Entity}sUsecase` | `{Entity}` |
| `Load{Entity}sByXxxUsecase` | `{Entity}s` または `{Entity}ByXxx` |
