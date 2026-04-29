---
name: persistence-code-review
description: 永続層のコードを調査し、型安全性、ベストプラクティス、不要コードの観点からレビュー・改善を行う。
---

# Persistence Code Review

## 目的

永続層（`internal/infra/persistence/`）のコードを以下の観点でレビュー・改善する：

- **型安全性**: 文字列リテラルを自動生成された定数に置き換え
- **null パッケージの正しい使用**: `github.com/aarondl/null/v8` のメソッド使用確認
- **不要コードの削除**: 到達不能コードや冗長なエラーチェックの除去
- **定数の活用**: マジックナンバーや bool リテラルを定数に置き換え
- **samber/lo の活用**: 適用可能なパターンへの置き換え

## このスキルを使用するタイミング

- 永続層のコードレビューを依頼されたとき
- 新規作成された永続層ファイルの品質チェック

## 実行手順

### Phase 1: サブエージェントによる並列調査

対象ファイルに対して、以下の4つの調査を **Taskツールで並列実行** する。

```
┌─────────────────────────────────────────────────────────────────┐
│ Task 1: null パッケージ使用調査 (subagent_type=Explore)          │
│ - `null.StringFrom`, `null.TimeFrom` 等の使用箇所を特定          │
│ - `*string` や `*time.Time` からの変換で `FromPtr` が使えるか    │
│ - 冗長な nil チェック後の From 呼び出しがあれば報告              │
│ - `.Valid` + `&.String` パターンで `Ptr()` が使えるか            │
├─────────────────────────────────────────────────────────────────┤
│ Task 2: sql.ErrNoRows チェック調査 (subagent_type=Explore)       │
│ - `.All()`, `.Count()`, `.Exists()` 後の不要な ErrNoRows チェック│
│ - `.One()` 後の必要な ErrNoRows チェックの有無                   │
├─────────────────────────────────────────────────────────────────┤
│ Task 3: 型安全性・定数使用調査 (subagent_type=Explore)           │
│ - Upsert の conflictColumns に文字列リテラルがないか             │
│ - Upsert の第3引数が true/false リテラルでないか                 │
│ - boil.Whitelist/Blacklist で文字列リテラルを使っていないか      │
│ - qm.OrderBy で文字列リテラル ("id DESC" 等) を使っていないか    │
├─────────────────────────────────────────────────────────────────┤
│ Task 4: samber/lo 適用可能性調査 (subagent_type=Explore)         │
│ - エラーを返さない変換ループで lo.Map が使えるか                 │
│ - マップ構築で lo.KeyBy/lo.SliceToMap が使えるか                 │
├─────────────────────────────────────────────────────────────────┤
│ Task 5: SQLBoiler アソシエーションメソッド調査 (subagent_type=   │
│         Explore)                                                 │
│ - `r.R != nil` + `r.R.GetXxx()` を `r.GetXxx()` に置換可能か    │
│ - `r.R.Xxx.Field` 直接アクセスを `r.GetXxx()` に置換可能か      │
│ - `r.R == nil || r.R.Xxx == nil` 手動チェックの除去              │
└─────────────────────────────────────────────────────────────────┘
```

**重要: 5つのTaskを1つのメッセージで並列起動すること。**

#### サブエージェント起動テンプレート

```
Task(
  subagent_type=Explore,
  description="null パッケージ使用調査",
  prompt="""以下のファイルで null パッケージの使用状況を調査せよ：
${FILE_LIST}

調査内容：
1. `null.StringFrom`, `null.TimeFrom`, `null.IntFrom` 等の使用箇所を特定
2. `*string` や `*time.Time` からの変換で `FromPtr` が使えるか確認
3. 冗長な nil チェック後の From 呼び出しがあれば報告
4. `.Valid` チェック後に `&.String` でポインタ取得している箇所で `Ptr()` が使えるか確認

出力形式：
問題がある場合のみファイル名、行番号、改善内容を報告せよ。問題がなければ「問題なし」と報告。"""
)

Task(
  subagent_type=Explore,
  description="sql.ErrNoRows チェック調査",
  prompt="""以下のファイルで sql.ErrNoRows チェックの妥当性を調査せよ：
${FILE_LIST}

調査内容：
1. `.All()`, `.Count()`, `.Exists()` 後の sql.ErrNoRows チェックは不要（空スライス/0/false を返すため）
2. `.One()` 後の sql.ErrNoRows チェックは必要（0件時にエラーを返すため）
3. 不要な sql.ErrNoRows チェックがあれば報告

出力形式：
問題がある場合のみファイル名、行番号、改善内容を報告せよ。問題がなければ「問題なし」と報告。"""
)

Task(
  subagent_type=Explore,
  description="型安全性・定数使用調査",
  prompt="""以下のファイルで型安全性と定数使用を調査せよ：
${FILE_LIST}

調査内容：
1. Upsert の conflictColumns 引数に文字列リテラル（例: "workspace_id"）がないか
   → models.XXXColumns.YYY の形式を使うべき
2. Upsert の第3引数（updateOnConflict）が true/false リテラルになっていないか
   → const.go の updateOnConflict / ignoreOnConflict 定数を使うべき
3. boil.Whitelist/boil.Blacklist で文字列リテラルを使っていないか
4. qm.OrderBy で文字列リテラル（"id DESC" 等）を使っていないか
   → models.XXXTableColumns.ID+" DESC" の形式を使うべき
5. qm.Where などで文字列リテラルのカラム名を使っていないか
   → models.XXXWhere.YYY を使うべき

出力形式：
問題がある場合のみファイル名、行番号、現在のコード、改善後のコードを報告せよ。問題がなければ「問題なし」と報告。"""
)

Task(
  subagent_type=Explore,
  description="samber/lo 適用可能性調査",
  prompt="""以下のファイルで samber/lo の適用可能性を調査せよ：
${FILE_LIST}

調査内容：
1. for ループでスライス変換を行っている箇所で、変換関数がエラーを返さない場合は lo.Map が使える
2. for ループでマップを構築している箇所で、キー取得がエラーを返さない場合は lo.KeyBy/lo.SliceToMap が使える
3. 単純なフィルタリングループは lo.Filter が使える

注意：変換関数がエラーを返す場合は lo.Map は適用不可

出力形式：
問題がある場合のみファイル名、行番号、現在のコード、改善後のコードを報告せよ。問題がなければ「問題なし」と報告。"""
)

Task(
  subagent_type=Explore,
  description="SQLBoiler アソシエーションメソッド調査",
  prompt="""以下のファイルで SQLBoiler アソシエーションメソッドの活用状況を調査せよ：
${FILE_LIST}

調査内容：
1. `r.R != nil` チェック後に `r.R.GetXxx()` を呼んでいる箇所で `r.GetXxx()` に置換可能か確認
2. `r.R.Xxx.Field` のように EagerLoaded リレーションのフィールドに直接アクセスしている箇所で
   `r.GetXxx()` を使って nil 安全にアクセスできるか確認
3. `r.R == nil || r.R.Xxx == nil` の手動 nil チェックが `r.GetXxx() != nil` で置換可能か確認

SQLBoiler はモデル本体に `o.GetXxx()` メソッドを生成する。
このメソッドは内部で o.R の nil ガード込みで o.R.GetXxx() を呼ぶため、
手動の R nil チェックは不要になる。

出力形式：
問題がある場合のみファイル名、行番号、現在のコード、改善後のコードを報告せよ。問題がなければ「問題なし」と報告。"""
)
```

### Phase 2: 調査結果の統合

サブエージェントの結果を統合し、問題の有無を判定する。

**問題がない場合:** `LGTM` とだけ返す。

**問題がある場合のみ**、以下の形式でレポート：

```markdown
## 改善点

| 項目 | ファイル | 行 | 内容 |
|------|----------|-----|------|
| 不要な ErrNoRows チェック | xxx_persistence_query.go | 46 | `.All()` 後の sql.ErrNoRows チェックは到達不能 |
| 文字列リテラル → 定数 | xxx_persistence_query.go | 232 | `"id DESC"` → `models.XXXTableColumns.ID+" DESC"` |
| lo.Map 適用可能 | xxx_persistence.go | 84-86 | エラーを返さない変換ループ |
| FromPtr 使用可能 | xxx_persistence.go | 120 | `null.StringFrom(*r.X)` → `null.StringFromPtr(r.X)` |
| Ptr() 使用可能 | xxx_persistence.go | 56 | `if r.X.Valid { result.X = &r.X.String }` → `result.X = r.X.Ptr()` |
| GetXxx() 簡素化 | xxx_persistence.go | 37 | `r.R != nil` + `r.R.GetXxx()` → `r.GetXxx()` |
```

### Phase 3: TDDアプローチで修正

改善点がある場合のみ、TDDアプローチで修正を実施する。

#### Step 1: テストが存在することを確認

```bash
# 対象ファイルのテストを実行し、現在の状態を確認
go test -v -race -run "TestXxxPersistence" ./internal/infra/persistence/...
```

テストがない場合は、修正前にテストを追加する。

#### Step 2: 修正を適用

1. **対象ファイルを Read ツールで読み込む**
2. **Edit ツールで修正を適用する**

#### Step 3: テストが通ることを確認

```bash
make fix test
```

**確認項目:**
- 全てのテストが PASS すること
- 不要なインポート（`database/sql`, `errors`）が残っていないか
- lint エラーがないか

---

## チェック項目詳細

### 1. null/v8 パッケージの使用確認

**利用可能な型とメソッド:**

| 型             | From             | FromPtr                      | Ptr              | New                    |
| -------------- | ---------------- | ---------------------------- | ---------------- | ---------------------- |
| `null.String`  | `StringFrom(s)`  | `StringFromPtr(s *string)`   | `Ptr() *string`  | `NewString(s, valid)`  |
| `null.Time`    | `TimeFrom(t)`    | `TimeFromPtr(t *time.Time)`  | `Ptr() *time.Time` | `NewTime(t, valid)`  |
| `null.Int`     | `IntFrom(i)`     | `IntFromPtr(i *int)`         | `Ptr() *int`     | `NewInt(i, valid)`     |
| `null.Int64`   | `Int64From(i)`   | `Int64FromPtr(i *int64)`     | `Ptr() *int64`   | `NewInt64(i, valid)`   |
| `null.Float64` | `Float64From(f)` | `Float64FromPtr(f *float64)` | `Ptr() *float64` | `NewFloat64(f, valid)` |
| `null.Bool`    | `BoolFrom(b)`    | `BoolFromPtr(b *bool)`       | `Ptr() *bool`    | `NewBool(b, valid)`    |

**方向別の使い分け:**

- **ドメイン(`*T`) → DB(`null.T`)**: `FromPtr()` を使う
- **DB(`null.T`) → ドメイン(`*T`)**: `Ptr()` を使う

**改善パターン（DB → ドメイン: `Ptr()`）:**

```go
// ❌ 冗長な Valid チェック + アドレス取得
if r.SenderTsid.Valid {
    result.SenderTsid = &r.SenderTsid.String
}

// ✅ Ptr() で直接変換（Valid=false なら nil、Valid=true なら *string）
result.SenderTsid = r.SenderTsid.Ptr()
```

構造体リテラルに直接インライン化できる：

```go
// ❌ リテラル外で個別代入
result := &model.Entity{
    ID: r.ID,
}
if r.OptionalField.Valid {
    result.OptionalField = &r.OptionalField.String
}

// ✅ リテラル内にインライン化
result := &model.Entity{
    ID:            r.ID,
    OptionalField: r.OptionalField.Ptr(),
}
```

**改善パターン（ドメイン → DB: `FromPtr()`）:**

```go
// ❌ 冗長な nil チェック + デリファレンス
if r.SenderTsid != nil {
    result.SenderTsid = null.StringFrom(*r.SenderTsid)
}

// ✅ FromPtr() で直接変換（nil なら Valid=false）
result.SenderTsid = null.StringFromPtr(r.SenderTsid)
```

**注意**: 変換処理が必要な場合は `FromPtr` / `Ptr()` は使えない

```go
// ❌ FromPtr は使えない（phonenumbers.Format で変換が必要）
if r.SenderFaxNumber != nil {
    result.SenderFaxNumber = null.StringFrom(phonenumbers.Format(r.SenderFaxNumber, phonenumbers.E164))
}

// ❌ FromPtr は使えない（型変換が必要）
if r.Status != nil {
    result.Status = null.StringFrom(string(*r.Status))
}
```

### 2. sql.ErrNoRows チェックの必要性

**SQLBoiler メソッドの挙動:**

| メソッド    | 0件時の挙動            | `sql.ErrNoRows` チェック |
| ----------- | ---------------------- | ------------------------ |
| `.One()`    | `sql.ErrNoRows` を返す | **必要**                 |
| `.All()`    | 空スライスを返す       | **不要**                 |
| `.Count()`  | `0` を返す             | **不要**                 |
| `.Exists()` | `false` を返す         | **不要**                 |

**削除対象パターン:**

```go
// ❌ 不要（.All() は sql.ErrNoRows を返さない）
r, err := models.Entities(mods...).All(ctx, exec)
if err != nil {
    if errors.Is(err, sql.ErrNoRows) {
        return result, errs  // この分岐は到達不能
    }
}
```

### 3. 型安全な定数の使用

**Upsert の conflictColumns:**

```go
// ❌ 文字列リテラル（タイポ検出不可）
err := m.Upsert(ctx, exec, false, []string{"workspace_id", "faximo_idxcnt"}, ...)

// ✅ 自動生成された定数（コンパイル時チェック）
err := m.Upsert(ctx, exec, ignoreOnConflict, []string{
    models.FaxReceivedColumns.WorkspaceID,
    models.FaxReceivedColumns.FaximoIdxcnt,
}, ...)
```

**qm.OrderBy での定数使用:**

```go
// ❌ 文字列リテラル（タイポ検出不可）
mods = append(mods, qm.OrderBy("id DESC"))

// ✅ 自動生成された定数（コンパイル時チェック）
mods = append(mods, qm.OrderBy(models.EntityTableColumns.ID+" DESC"))
```

**利用可能な定数:**

```go
models.EntityColumns.FieldName      // カラム名
models.EntityTableColumns.FieldName // テーブル名.カラム名（ORDER BY, JOIN で使用）
models.EntityWhere.FieldName        // WHERE条件ビルダー
models.EntityRels.RelationName      // リレーション名
```

### 4. bool リテラルの定数化

**const.go で定義済みの定数:**

```go
// internal/infra/persistence/const.go
const (
    updateOnConflict = true  // 衝突時に既存レコードを更新
    ignoreOnConflict = false // 衝突時に何もしない (DO NOTHING)
)
```

**改善パターン:**

```go
// ❌ 意図が不明確
err := m.Upsert(ctx, exec, false, conflictColumns, ...)

// ✅ 意図が明確
err := m.Upsert(ctx, exec, ignoreOnConflict, conflictColumns, ...)
```

### 5. samber/lo の活用

**適用可能なパターン:**

| 関数            | 用途            | 適用条件                       |
| --------------- | --------------- | ------------------------------ |
| `lo.Map`        | スライス変換    | 変換関数がエラーを返さない     |
| `lo.KeyBy`      | スライス→マップ | キー取得関数がエラーを返さない |
| `lo.Filter`     | フィルタリング  | -                              |
| `lo.SliceToMap` | スライス→マップ | キー・値変換がエラーを返さない |

**改善パターン:**

```go
// ❌ 手動ループ
result := make([]*model.Entity, len(rs))
for i, v := range rs {
    result[i] = translateEntityModel(v)
}

// ✅ lo.Map
result := lo.Map(rs, func(v *models.Entity, _ int) *model.Entity {
    return translateEntityModel(v)
})
```

**適用不可のケース:**

```go
// ❌ translateModel がエラーを返すため lo.Map は使えない
for i, v := range rs {
    translated, err := translateEntityModel(v)
    if err != nil {
        return nil, err
    }
    result[i] = translated
}
```

### 6. SQLBoiler アソシエーションメソッドの活用

SQLBoiler はモデル本体に `o.GetXxx()` メソッドを自動生成する。このメソッドは内部で `o.R` の nil ガード込みで `o.R.GetXxx()` を呼ぶため、手動の `R` nil チェックは不要。

**パターン A: `r.R != nil` + `r.R.GetXxx()` → `r.GetXxx()`**

```go
// ❌ 冗長な R の nil チェック
if r.R != nil {
    if user := r.R.GetCreatedByWorkspaceUser(); user != nil {
        m.CreatedByUser = translateWorkspaceUserModel(user)
    }
}

// ✅ モデル本体のメソッドが R の nil ガードを含む
if user := r.GetCreatedByWorkspaceUser(); user != nil {
    m.CreatedByUser = translateWorkspaceUserModel(user)
}
```

**パターン B: `r.R.Xxx.Field` 直接アクセス → `r.GetXxx()` で nil 安全にアクセス**

EagerLoading (`qm.Load`) で取得したリレーションのフィールドに直接アクセスすると、リレーションが nil の場合にパニックする。`GetXxx()` を使えば nil 安全にアクセスできる。

```go
// ❌ nil deref パニックのリスク（r.R が nil、または r.R.Feature が nil の場合）
for _, pf := range planFeatures {
    keys = append(keys, model.FeatureKey(pf.R.Feature.Key))
}

// ❌ 手動 nil チェック（冗長）
for _, pf := range planFeatures {
    if pf.R == nil || pf.R.Feature == nil {
        continue
    }
    keys = append(keys, model.FeatureKey(pf.R.Feature.Key))
}

// ✅ アソシエーションメソッドで nil 安全にアクセス
for _, pf := range planFeatures {
    if feature := pf.GetFeature(); feature != nil {
        keys = append(keys, model.FeatureKey(feature.Key))
    }
}
```

**`GetXxx()` の生成ルール:**

SQLBoiler は各リレーションに対して以下を生成する:
- `o.R.GetXxx()` — `planFeatureR` 構造体のメソッド。`R` が nil なら nil を返す
- `o.GetXxx()` — モデル本体のメソッド。`o` が nil でも安全。内部で `o.R.GetXxx()` を呼ぶ

```go
// SQLBoiler 自動生成コード（models/plan_features.go）
func (o *PlanFeature) GetFeature() *Feature {
    if o == nil {
        return nil
    }
    return o.R.GetFeature()
}
```

---

## 参考

- `internal/infra/persistence/const.go`: 共通定数
- `internal/models/*.go`: SQLBoiler 自動生成モデル
- `go doc github.com/aarondl/null/v8`: null パッケージドキュメント
