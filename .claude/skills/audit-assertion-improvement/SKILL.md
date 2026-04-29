---
name: audit-assertion-improvement
description: Use when writing or modifying usecase tests. Also use when replacing gomock.Any() with util.NewAuditEventMatcher, or when reviewing audit log assertions in prepare/setup functions of usecase test files.
---

# Audit Log Assertion Improvement

## Overview

ユースケーステストの監査ログアサーションを `util.NewAuditEventMatcher` に統一するテクニック。以下のレガシーパターンをすべて置換対象とする:
- `gomock.Any()` による検証なし
- `builder.Build()` を直接 Log 引数に渡す
- `.Do` ハンドラ内で `*audit.AuditEvent` に型アサーションして手動フィールドチェック

**正常系・異常系の両方が改善対象。** 1件ずつ修正→テスト実行のサイクルで進める。

## When to Use

- ユースケーステストを新規作成するとき（最初から `NewAuditEventMatcher` を使う）
- 既存テストで `mockLogger.EXPECT().Log(gomock.Any(), gomock.Any())` を発見したとき
- 既存テストで `mockLogger.EXPECT().Log(gomock.Any(), builder.Build())` を発見したとき
- 既存テストで `.Do(func(ctx context.Context, event domainaudit.Event) { ... })` による手動検証を発見したとき
- テストの `prepare` 関数内で `audit.NewAuditEventBuilder` が使われているとき
- 監査ログの検証を強化・具体化するとき

**対象外:**
- 監査ログを記録しないユースケース

## Core Pattern

```
Before (パターン1 — 検証なし):
mocks.mockLogger.EXPECT().Log(gomock.Any(), gomock.Any())

Before (パターン2 — builder.Build() 直接渡し):
builder := audit.NewAuditEventBuilder(...)
mocks.mockLogger.EXPECT().NewBuilder(...).Return(builder)
mocks.mockLogger.EXPECT().Log(gomock.Any(), builder.Build())

Before (パターン3 — .Do 手動検証):
builder := audit.NewAuditEventBuilder(...)
mocks.mockLogger.EXPECT().NewBuilder(...).Return(builder)
mocks.mockLogger.EXPECT().Log(gomock.Any(), builder.Build()).Do(func(ctx context.Context, event domainaudit.Event) {
    e, ok := event.(*audit.AuditEvent)
    if !ok { t.Fatalf("expected event to be *audit.AuditEvent") }
    if e.Action != domainaudit.ActionUpdate { t.Errorf(...) }
    if e.Resource != domainaudit.ResourceWorkspaceUser { t.Errorf(...) }
    // ... 個別フィールドチェックが続く ...
})

After (Create — 正常系):
mocks.mockLogger.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourceXxx),
    util.WithChanges(domainaudit.FieldChanges{
        {Field: "field_name", OldValue: nil, NewValue: expectedValue},
    }),
))

After (Update — 正常系):
mocks.mockLogger.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionUpdate),
    util.WithResource(domainaudit.ResourceXxx),
    util.WithResourceID(knownID),
    util.WithChanges(domainaudit.FieldChanges{
        {Field: "field_name", OldValue: oldVal, NewValue: newVal},
    }),
))

After (Delete — 正常系):
mocks.mockLogger.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionDelete),
    util.WithResource(domainaudit.ResourceXxx),
    util.WithResourceID(knownID),
    util.WithChanges(domainaudit.FieldChanges{
        {Field: "field_name", OldValue: oldVal, NewValue: nil},
    }),
))

After (異常系 — エラーメッセージ検証):
mocks.mockLogger.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionXxx),
    util.WithResource(domainaudit.ResourceXxx),
    util.WithResourceID(knownID),  // ResourceID がセットされている場合のみ
    util.WithErrorMessageContains("error substring"),
))

After (WithChanges が使えない場合 — 動的UUID等):
mocks.mockLogger.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourceXxx),
))
```

## Quick Reference

| Matcher Option | 用途 |
|---|---|
| `WithAction(domainaudit.ActionXxx)` | Create/Update/Delete の検証 |
| `WithResource(domainaudit.ResourceXxx)` | リソース種別の検証 |
| `WithResourceID(id)` | リソースIDの検証（IDが既知の場合のみ） |
| `WithChanges(fieldChanges)` | フィールド変更内容の検証 |
| `WithErrorMessage(msg)` | エラーメッセージ完全一致 |
| `WithErrorMessageContains(sub)` | エラーメッセージ部分一致 |

## Implementation Steps

### 1. 調査フェーズ（必ず最初に実行）

5つの情報を**並列で**収集する:

1. **テストファイル**: レガシーパターンを使っているテストケースを特定（正常系・異常系の両方）
2. **ユースケース実装**: `builder.ResourceID()` / `builder.RecordChange()` / `entity.TrackOldValue(builder)` / `entity.TrackNewValue(builder)` の呼び出し箇所と、エラー発生箇所を確認
3. **ドメインモデルの `TrackNewValue` / `TrackOldValue`**: フィールド一覧と型を確認（手動デリファレンスの有無も確認）
4. **Mock の初期化方法**: `NewMockLogger(ctrl)` / `NewMockTxManager(ctrl)` か `WithImpl` サフィックス付きかを確認。サフィックスなしなら `WithImpl` へのマイグレーションが必要
5. **ビルダーの生成元**: ユースケースが `u.audits.NewBuilder()` を呼んでいるか、外部から受け取ったビルダーをそのまま `Log` に渡しているかを確認（後者なら `gomock.Any()` が適切）

```bash
# 1. テストファイルでレガシーパターンを使っている Log 呼び出しを検索
Grep: \.EXPECT\(\)\.Log\(gomock\.Any\(\),   # gomock.Any() / builder.Build() / .Do 全パターンを確認

# 2. ユースケース実装の監査ログ関連コードを検索
Grep: builder\.(ResourceID|RecordChange)|\.TrackOldValue|\.TrackNewValue

# 3. ドメインモデルのフィールド一覧を取得
Grep: func (.*ModelName) Track(New|Old)Value
→ TrackNewValues / TrackOldValues の引数リストがフィールド一覧

# 4. Mock 初期化方法を確認（Logger と TxManager の両方）
Grep: NewMockLogger(WithImpl)?\(ctrl\)
Grep: NewMockTxManager(WithImpl)?\(ctrl\)

# 5. ビルダーの生成元を確認
Grep: u\.audits\.NewBuilder   # ユースケース内でビルダーを生成しているか
Grep: auditBuilders\s+\[\]   # 外部から受け取ったビルダーを使っているか
```

### 1b. 調査結果の判定フロー

収集した5つの情報から、次のいずれかに判定する:

| ユースケースの実装 | テストの状態 | Mock 初期化 | ビルダー生成元 | 判定 |
|---|---|---|---|---|
| `TrackNewValue` のみ呼ぶ | `gomock.Any()` / `builder.Build()` / `.Do` | 任意 | 自身で生成 | → **Create パターンで WithChanges を追加** |
| `TrackOldValue` + `TrackNewValue` 両方呼ぶ | `gomock.Any()` / `builder.Build()` / `.Do` | 任意 | 自身で生成 | → **Update パターンで WithChanges を追加** |
| `TrackOldValue` のみ呼ぶ（Delete操作） | `gomock.Any()` / `builder.Build()` / `.Do` | 任意 | 自身で生成 | → **Delete パターンで WithChanges を追加** |
| `builder.RecordChange()` を直接呼ぶ | `gomock.Any()` / `builder.Build()` / `.Do` | 任意 | 自身で生成 | → **RecordChange パターン（後述）** |
| `audits.NewBuilder` を呼ばない | `gomock.Any()` | 任意 | 外部から受取 | → **修正不要（`gomock.Any()` が適切）** |
| 任意 | 既に `NewAuditEventMatcher` を使用 | サフィックスなし | 自身で生成 | → **Mock マイグレーションのみ実施** |
| 任意 | 既に `NewAuditEventMatcher` を使用 | `WithImpl` 付き | 自身で生成 | → **修正不要** |

**「修正不要」は正当な結論である。** 調査の結果、既に適切なアサーションが書かれている場合は無理に修正しない。

**重要:**
- `NewMockLogger(ctrl)` / `NewMockTxManager(ctrl)` を使用しているファイルは、アサーション改善の有無に関わらず `WithImpl` サフィックス付きへのマイグレーションを必ず行う。
- ユースケースが `audits.NewBuilder` を呼ばず、外部から受け取ったビルダーをそのまま `Log` に渡す場合は、`gomock.Any()` が適切であり改善対象外。

### 1c. Resource / Action の妥当性検証（重要）

調査時に以下を必ず確認する。誤ったリソース種別やアクション種別は監査ログの信頼性を損なう:

| チェック項目 | 確認内容 |
|---|---|
| **Resource が操作対象と一致するか** | 例: Patient の consent file を操作するのに `ResourceBlob` を使っていたら `ResourcePatient` に修正すべき |
| **Action が操作の意味と一致するか** | 例: 子リソースの部分削除は親リソースの `ActionUpdate` であって `ActionDelete` ではない |
| **子リソース操作の原則** | 親リソースの属性変更として記録する（Attachment 操作 → 親エンティティの Update） |

**よくある誤り:**

| 操作 | 誤った設定 | 正しい設定 |
|---|---|---|
| Patient の consent file を追加 | `ActionCreate` + `ResourceBlob` | `ActionCreate` + `ResourcePatient` |
| Patient の consent file を部分削除 | `ActionDelete` + `ResourceBlob` | `ActionUpdate` + `ResourcePatient` |
| ChannelMessage の添付ファイルを削除 | `ActionDelete` + `ResourceBlob` | `ActionUpdate` + `ResourceChannelMessage` |

### 1d. TrackOldValue / TrackNewValue の配置原則

ユースケース実装を確認する際、以下の配置原則に従っているか検証する。違反していればユースケース実装も修正する:

| 原則 | 説明 |
|---|---|
| **TrackOldValue は DB 読み込み直後に呼ぶ** | エンティティ取得直後、バリデーションや業務ロジックの前に記録する。エラー時にも旧値が監査ログに残る |
| **TrackNewValue はバリデーション前に呼ぶ** | `validator.Struct()` の前に記録する。バリデーションエラー時にも新値が監査ログに残る |

```go
// 正しい配置
entity := repo.FindByID(ctx, id)
builder.ResourceID(entity.ID)
entity.TrackOldValue(builder)     // ← DB読み込み直後

entity.Name = input.Name
entity.TrackNewValue(builder)     // ← バリデーション前

if err := validator.Struct(entity); err != nil {
    return err
}
```

### 1e. ユースケースの監査ログ記録フローの把握

テストケースごとにどこまで処理が進むかを把握し、マッチャーに何を含めるべきか判定する:

| テストケースの種類 | ResourceID | TrackOldValue | TrackNewValue | Error | 使うマッチャー |
|---|---|---|---|---|---|
| 正常系（Create） | ✗（動的） | ✗ | ✓ | ✗ | `WithAction` + `WithResource` + `WithChanges` |
| 正常系（Update） | ✓ | ✓ | ✓ | ✗ | `WithAction` + `WithResource` + `WithResourceID` + `WithChanges` |
| 正常系（Delete） | ✓ | ✓ | ✗ | ✗ | `WithAction` + `WithResource` + `WithResourceID` + `WithChanges`（NewValue全nil） |
| 正常系（No-op） | ✓ | ✓ | ✗ | ✗ | `WithAction` + `WithResource`（TrackNewValue未呼出のため Changes 不完全） |
| 異常系（入力nil早期リターン） | ✗ | ✗ | ✗ | ✓ | `WithAction` + `WithResource` + `WithErrorMessageContains` |
| 異常系（権限チェック後エラー） | ✓ | ✓ | ✗ | ✓ | `WithAction` + `WithResource` + `WithResourceID` + `WithErrorMessageContains` |
| 異常系（DB操作エラー） | ✓ | ✓ | ✓(Update時) | ✓ | `WithAction` + `WithResource` + `WithResourceID` + `WithErrorMessageContains` |

**ポイント:** ユースケース実装のどの行でエラーが発生するかによって、`ResourceID` や `TrackOldValue` がセットされているかが決まる。実装を必ず読んで判断する。

## RecordChange パターン

`TrackNewValue` / `TrackOldValue` を使わず、`builder.RecordChange()` を直接呼ぶユースケースがある。典型例:

- Attachment の ID リストを手動記録するケース
- ドメインモデルに `TrackNewValue` が定義されていないリソースの操作
- カスタム型スライスの変更記録（例: `[]model.WorkspaceUserAbilityType`）

### RecordChange パターンの判定

```go
// ユースケース実装例
builder.RecordChange("consent_file_ids", nil, attachmentIDs)
```

この場合、`WithChanges` で検証できるかは**値の予測可能性**による:

| 値の状態 | 対応 |
|---|---|
| テスト内で値が確定している（固定文字列等） | `WithChanges` で完全検証 |
| モック内で `uuid.NewString()` 等で動的生成 | `WithChanges` は使えない → `WithAction` + `WithResource` のみで検証 |

```go
// 動的UUIDで WithChanges が使えない場合
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourcePatient),
))
```

## 複数監査ログの分割パターン

1つのユースケースが複数の監査ログを記録する場合、`.Times(N)` を個別のマッチャーに分割する:

```go
// Before: 何を記録しているか不明
m.mockAudits.EXPECT().Log(gomock.Any(), gomock.Any()).Times(2)

// After: 各監査ログの内容を個別に検証
// 監査ログ1: EmailVerification の更新
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionUpdate),
    util.WithResource(domainaudit.ResourceWorkspaceUserEmailVerification),
    util.WithResourceID("ver-123"),
))
// 監査ログ2: EmailNotificationSettings の作成
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourceWorkspaceUserEmailNotificationSettings),
    util.WithResourceID("settings-123"),
))
```

### 異なるリソースタイプを持つ複数監査ログの例

`CreateWorkspaceUser` のように、1つのユースケースが複数の異なるリソースタイプの監査ログを記録する場合:

```go
// ユースケース実装側:
// 1. WorkspaceUser 作成の監査ログ
// 2. WorkspaceUserAuthenticate 作成の監査ログ
// 3. ChannelUser 作成の監査ログ（デフォルトチャンネルへの参加）

// テスト側: 3つの別々のマッチャーで検証
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourceWorkspaceUser),
))
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourceWorkspaceUserAuthenticate),
))
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionCreate),
    util.WithResource(domainaudit.ResourceChannelUser),
))
```

**ポイント:** gomock は順序非依存でマッチングするため、`InOrder` を使わない限り呼び出し順序を気にする必要はない。

## 外部コンポーネントからビルダーを受け取るパターン

### shared コンポーネントがビルダーを返す場合

`WorkspaceUserCreator` のように、shared コンポーネントがビルダーを返し、呼び出し元のユースケースで `Log` を呼ぶパターンがある:

```go
// ユースケース実装
createdUser, builders, _, err := u.userCreator.Execute(ctx, currentUser, workspace, user, auth, u.audits, false)
// ...
for _, builder := range builders {
    u.audits.Log(ctx, builder.Error(err).Build())
}
```

**テスト側の対応:**

1. **`audit.NewAuditEventBuilder` ではなく `m.mockAudits.NewBuilder` を使う** — モックの `NewBuilder` を通してビルダーを作成することで、`NewMockLoggerWithImpl` の内部実装と整合性を保つ
2. **Return で `[]domainaudit.Builder` を返す**

```go
// Before: audit パッケージの NewAuditEventBuilder を直接使用（禁止）
m.mockUserCreator.EXPECT().Execute(...).Return(
    createdUser,
    []domainaudit.Builder{audit.NewAuditEventBuilder(domainaudit.ActionCreate, domainaudit.ResourceChannelUser)},
    nil,
    nil,
)

// After: モックの NewBuilder を使用
m.mockUserCreator.EXPECT().Execute(...).Return(
    createdUser,
    []domainaudit.Builder{m.mockAudits.NewBuilder(domainaudit.ActionCreate, domainaudit.ResourceChannelUser)},
    nil,
    nil,
)
```

**理由:** `audit.NewAuditEventBuilder` を使うと、テスト内で `audit` パッケージをインポートする必要があり、レガシーパターンが残る。`m.mockAudits.NewBuilder` を使うことで import を削除でき、モックとの一貫性も保たれる。

### gomock.Any() が適切なケース（例外）

以下のケースでは `gomock.Any()` が適切であり、無理に `NewAuditEventMatcher` に置き換えない:

1. **ビルダーが完全に外部から渡される場合** — usecase が `audits.NewBuilder` を呼ばず、受け取ったビルダーをそのまま `Log` に渡す場合

```go
// ユースケース実装: ビルダーを外部から受け取り、そのまま Log に渡す
func (u *fetchChannelMessagesAroundIdUsecase) Execute(
    ctx context.Context,
    input *graphmodel.FetchChannelMessagesAroundIdInput,
    auditBuilders []domainaudit.Builder,  // 外部から受け取る
) (*FetchChannelMessagesAroundIdOutput, error) {
    // ...
    for _, builder := range auditBuilders {
        u.audits.Log(ctx, builder.Build())  // そのまま Log
    }
}
```

この場合、ビルダーの内容はユースケースの責務外であるため、`gomock.Any()` で十分:

```go
// テスト側: 受け取ったビルダーをそのまま渡すだけなので gomock.Any() が適切
m.mockAudits.EXPECT().Log(gomock.Any(), gomock.Any()).Times(len(auditBuilders))
```

**判定基準:** ユースケース実装で `u.audits.NewBuilder()` を呼んでいるかを確認する。呼んでいなければ `gomock.Any()` が適切。

## テストの Mock パターン

### NewMockLoggerWithImpl / NewMockTxManagerWithImpl を必ず使う（必須）

**`NewMockLogger(ctrl)` / `NewMockTxManager(ctrl)` の直接使用は禁止。** 必ず `WithImpl` サフィックス付きを使うこと。

| Mock | 禁止 | 必須 | 自動提供されるメソッド |
|---|---|---|---|
| audit.Logger | `NewMockLogger(ctrl)` | `NewMockLoggerWithImpl(ctrl)` | `NewBuilder` |
| repository.TxManager | `NewMockTxManager(ctrl)` | `NewMockTxManagerWithImpl(ctrl)` | `RunInWritingTransaction` |

```go
m.mockAudits = mock_audit.NewMockLoggerWithImpl(ctrl)
m.mockTx = mock_repository.NewMockTxManagerWithImpl(ctrl)
// NewBuilder, RunInWritingTransaction の EXPECT 不要、Log のみ設定
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(...))
```

### レガシーパターン一覧（すべて禁止 — 発見次第マイグレーション）

#### パターン1: NewMockLogger + `gomock.Any()`

```go
// ❌ 禁止
m.mockAudits = mock_audit.NewMockLogger(ctrl)
builder := audit.NewAuditEventBuilder(domainaudit.ActionCreate, domainaudit.ResourcePatient)
m.mockAudits.EXPECT().NewBuilder(domainaudit.ActionCreate, domainaudit.ResourcePatient).Return(builder)
m.mockAudits.EXPECT().Log(gomock.Any(), gomock.Any())
```

#### パターン2: NewMockLogger + `builder.Build()` 直接渡し

```go
// ❌ 禁止: builder.Build() を直接 Log 引数に使用
builder := audit.NewAuditEventBuilder(domainaudit.ActionUpdate, domainaudit.ResourceWorkspaceUser)
m.audits.EXPECT().NewBuilder(domainaudit.ActionUpdate, domainaudit.ResourceWorkspaceUser).Return(builder)
m.audits.EXPECT().Log(gomock.Any(), builder.Build())
```

#### パターン3: `.Do` ハンドラによる手動検証（最も冗長）

```go
// ❌ 禁止: 手動型アサーション + 個別フィールドチェック（数十行になることが多い）
builder := audit.NewAuditEventBuilder(domainaudit.ActionUpdate, domainaudit.ResourceWorkspaceUser)
m.audits.EXPECT().NewBuilder(domainaudit.ActionUpdate, domainaudit.ResourceWorkspaceUser).Return(builder)
m.audits.EXPECT().Log(gomock.Any(), builder.Build()).Do(func(ctx context.Context, eventInterface domainaudit.Event) {
    e, ok := eventInterface.(*audit.AuditEvent)
    if !ok { t.Fatalf("expected event to be *audit.AuditEvent") }
    if e.Action != domainaudit.ActionUpdate { t.Errorf(...) }
    if e.Resource != domainaudit.ResourceWorkspaceUser { t.Errorf(...) }
    // ... 個別フィールドチェックが続く ...
})
```

**パターン3 の特徴:** `slices`, `context` などの import が `.Do` ハンドラ内でのみ使用されていることが多い。マイグレーション後にこれらの不要 import も削除する。

### マイグレーション手順

**重要: マイグレーションは原子的に行う。** `NewMockLoggerWithImpl` は内部で `NewBuilder` の EXPECT を `AnyTimes()` で登録するため、個別テストケースの手動 `NewBuilder` EXPECT と競合する。**全テストケース（正常系・異常系）の `NewBuilder` 関連コードを一括で削除すること。**

1. **mockContainer の初期化を変更**: `mock_audit.NewMockLogger(ctrl)` → `mock_audit.NewMockLoggerWithImpl(ctrl)`
2. **全テストケース（正常系・異常系）の `prepare` 関数から `NewBuilder` 関連コードを一括削除**:
   - `builder := audit.NewAuditEventBuilder(...)` の行を削除
   - `m.mockAudits.EXPECT().NewBuilder(...).Return(builder)` の行を削除
   - `builder.Build()` を Log 引数に使っている場合は `gomock.Any()` か `util.NewAuditEventMatcher(...)` に置換
   - `.Do(func(...) { ... })` ハンドラがある場合は、全体を `util.NewAuditEventMatcher(...)` に置換
3. **不要になった import を削除**:
   - `"github.com/medtech-inc/toscana/api/internal/audit"` — `audit.NewAuditEventBuilder` のためだけにインポートされていた場合
   - `"slices"` — `.Do` ハンドラ内の `slices.Equal` のみで使用されていた場合
   - `"context"` — `.Do` ハンドラの引数型でのみ使用されていた場合（`args` 構造体で使用されていれば残す）
4. **テスト実行で検証**

```go
// Before (各テストケースの prepare 内):
builder := audit.NewAuditEventBuilder(domainaudit.ActionUpdate, domainaudit.ResourcePatient)
m.mockAudits.EXPECT().NewBuilder(domainaudit.ActionUpdate, domainaudit.ResourcePatient).Return(builder)
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(...))

// After (各テストケースの prepare 内):
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(...))
```

**注意:** `audit` パッケージ import の削除判断は慎重に行う。`audit.NewAuditEventBuilder` 以外の用途（例: `audit.ActionCreate` 等の定数参照）で使われている場合は削除しない。ただし通常、定数は `domainaudit` エイリアスで参照するため、`audit` の import が `NewAuditEventBuilder` のみに使われているケースが多い。

## import 追加チェックリスト

マッチャーを追加する際に必要な import を確認する。テストファイルに不足していれば追加する:

| 使う機能 | 必要な import |
|---|---|
| `domainaudit.ActionXxx`, `domainaudit.ResourceXxx` | `domainaudit "github.com/medtech-inc/toscana/api/internal/domain/audit"` |
| `util.NewAuditEventMatcher`, `util.WithAction` 等 | `"github.com/medtech-inc/toscana/api/test/util"` |
| `domainaudit.FieldChanges`, `domainaudit.FieldChange` | （`domainaudit` と同じ） |
| `cmpopts.IgnoreSliceElements`, `cmpopts.EquateApproxTime` | `"github.com/google/go-cmp/cmp/cmpopts"` |

**よくあるミス:** `domainaudit` import は既存テストに入っていないことが多い。最初の修正前に必ず追加する。

### 2. 値の型推論（dereferenceValue ルール）

`TrackNewValues` / `TrackOldValues` に渡される値は内部で `dereferenceValue` 関数によりポインタがデリファレンスされる:

| 渡される型 | Matcher での期待値 |
|---|---|
| `string` ("hello") | `"hello"` |
| `*string` (non-nil) | デリファレンスされた `string` 値 |
| `*string` (nil) | `nil` |
| `int` (42) | `42` |
| `*int` (non-nil) | デリファレンスされた `int` 値 |
| `*int` (nil) | `nil` |
| `bool` (true) | `true` |
| `model.XxxKind` | `model.XxxKindYyy`（enum値そのまま） |
| `*model.TimeOfDay` → `*string` 変換後 | `"HH:MM"` string（non-nil時）/ `nil`（nil時） |

**注意:** `TrackNewValue` 内で `*string` に変換してから渡しているフィールド（TimeOfDay等）は、
`dereferenceValue` で `string` にデリファレンスされる。実装を必ず確認すること。

### 2b. 手動デリファレンスパターン（重要）

一部のドメインモデルは `TrackOldValue` 内で `*string` を手動でデリファレンスしてから渡している:

```go
// CalendarSubscription.TrackOldValue の例
func (s *CalendarSubscription) TrackOldValue(t audit.ValueTracker) {
    calendarID := ""
    if s.CalendarID != nil {
        calendarID = *s.CalendarID
    }
    externalIcsURL := ""
    if s.ExternalIcsURL != nil {
        externalIcsURL = *s.ExternalIcsURL
    }
    t.TrackOldValues(
        "calendar_id", calendarID,        // ← string 型で渡される（nil ではなく ""）
        "external_ics_url", externalIcsURL, // ← 同上
    )
}
```

**この場合、値は常に `string` 型であり `nil` にならない。** ポインタが nil の場合はゼロ値（`""`）が渡される。マッチャーでも `""` を期待値にする:

```go
// ✅ 正しい: 手動デリファレンスされたフィールドはゼロ値
{Field: "calendar_id", OldValue: "", NewValue: nil},       // CalendarID が nil の場合
{Field: "calendar_id", OldValue: "cal-1", NewValue: nil},  // CalendarID が non-nil の場合

// ❌ 間違い: nil を期待してしまう
{Field: "calendar_id", OldValue: nil, NewValue: nil},
```

**ルール:** `TrackOldValue` / `TrackNewValue` の実装を必ず読み、ポインタフィールドが手動デリファレンスされているか `dereferenceValue` に任されているかを確認する。

### 2c. enum型の string キャスト

一部の `TrackOldValue` / `TrackNewValue` は enum 型を `string()` でキャストしてから渡している:

```go
t.TrackOldValues(
    "allocation_status", string(s.AllocationStatus),  // model.AllocationStatus → string
    "sync_status", string(s.SyncStatus),              // model.SyncStatus → string
    "permission", string(s.Permission),               // model.SharePermission → string
)
```

マッチャーでは `string()` キャスト後の値を期待値にする:

```go
{Field: "allocation_status", OldValue: "tentative", NewValue: "confirmed"},
// または enum 定数の string() を使う
{Field: "sync_status", OldValue: string(model.SyncStatusOK), NewValue: nil},
{Field: "permission", OldValue: string(model.SharePermissionView), NewValue: nil},
```

### 2d. 複雑な型の対処

`dereferenceValue` はポインタ型のみデリファレンスする。スライス・map・構造体はそのまま `any` として `FieldChange` に格納され、`cmp.Diff` で再帰比較される。

#### 型付きスライス全般（`[]string`, `[]model.XxxType` 等）

`RecordChange` や `TrackNewValue` でスライスを渡すケースがある。

**型付き nil スライスの罠（重要）:**

Go ではnil スライスを `any` に格納すると、型情報を持つインターフェース値になる。`WithChanges` の期待値では**型付き nil** を使わなければ `cmp.Diff` で不一致になる:

```go
// ❌ 不一致: any(nil) != any([]model.WorkspaceUserAbilityType(nil))
{Field: "abilities", OldValue: nil, NewValue: ...}

// ✅ 一致: 型付き nil を使う
{Field: "abilities", OldValue: []model.WorkspaceUserAbilityType(nil), NewValue: ...}
```

**ルール:** `RecordChange` や `TrackNewValues` に渡されるスライスが nil になりうる場合、`WithChanges` の期待値でも同じ型の nil スライスリテラルを使用する。

#### `[]string` スライスの例

`TrackNewValue` 内でスライスに変換して渡すケースがある（例: `SharedChannelGroup` の `workspace_ids`）。

```go
// ドメインモデル側
workspaceIDs := lo.Map(m.Workspaces, func(item *SharedChannelGroupWorkspace, _ int) string {
    return item.WorkspaceID
})
slices.Sort(workspaceIDs)
t.TrackNewValues("workspace_ids", workspaceIDs)

// テスト側: そのままスライスで期待値を書く
{Field: "workspace_ids", OldValue: []string{"ws-1", "ws-2"}, NewValue: []string{"ws-1", "ws-2", "ws-3"}},
```

**注意:** スライスの要素順序が一致する必要がある。ドメインモデル側でソートしている場合はテスト側も同じ順序にする。

#### `time.Time`

`*time.Time` は `dereferenceValue` で `time.Time` にデリファレンスされる。`time.Now()` を含む動的な値は正確な比較が困難。

**対処法1: `cmpopts.EquateApproxTime` で近似比較**

```go
util.WithChanges(domainaudit.FieldChanges{
    {Field: "revoked_at", OldValue: nil, NewValue: time.Now()},
}, cmpopts.EquateApproxTime(time.Second))
```

**対処法2: `cmpopts.IgnoreSliceElements` で動的フィールドを除外**

```go
util.WithChanges(domainaudit.FieldChanges{
    {Field: "channel_id", OldValue: nil, NewValue: channelID},
    // revoked_at は検証しない
}, cmpopts.IgnoreSliceElements(func(c domainaudit.FieldChange) bool {
    return c.Field == "revoked_at"
}))
```

**対処法3: 複合 — 変更なしフィールドを除外 + 動的フィールドを近似比較**

Update操作で変更されるフィールドが `time.Time` 型のみの場合、変更なしフィールドを除外しつつ近似比較を組み合わせる:

```go
util.WithChanges(domainaudit.FieldChanges{
    {Field: "verified_at", OldValue: nil, NewValue: time.Now()},
}, cmpopts.IgnoreSliceElements(func(c domainaudit.FieldChange) bool {
    return c.OldValue == c.NewValue
}), cmpopts.EquateApproxTime(time.Second))
```

#### 変更なしフィールドの一括除外

Update操作で多数のフィールドが変更されない場合、`IgnoreSliceElements` で OldValue == NewValue のフィールドを除外し、変更のあるフィールドだけ検証できる:

```go
util.WithChanges(domainaudit.FieldChanges{
    {Field: "name", OldValue: "旧名", NewValue: "新名"},
}, cmpopts.IgnoreSliceElements(func(c domainaudit.FieldChange) bool {
    return c.OldValue == c.NewValue
}))
```

**使い分けの判断基準:**

| 状況 | 推奨 |
|---|---|
| フィールドが少ない（5個以下）、全て固定値 | 全フィールドを明示的に書く |
| フィールドが多い（6個以上）、動的UUIDを含む | `IgnoreSliceElements` で変更なしフィールドを除外し、変更フィールドのみ検証 |
| Delete操作で全フィールドが固定値 | 全フィールドを明示的に書く（NewValue は全て nil） |
| Update操作で1-2フィールドのみ変更、他は動的UUID | `IgnoreSliceElements` で変更なしフィールドを除外 |

#### `WithChanges` の第2引数（`changesOptions`）

`WithChanges` は可変長引数で `cmp.Option` を受け取る。内部では `cmpopts.SortSlices`（Field名でソート）が常に適用され、追加オプションがマージされる:

```go
// 署名
func WithChanges(changes domainaudit.FieldChanges, changesOptions ...cmp.Option) AuditEventMatcherOption

// 使える主な cmp.Option:
// - cmpopts.EquateApproxTime(d)          : time.Time の近似比較
// - cmpopts.IgnoreSliceElements(func)    : 条件に合うFieldChangeを除外
// - cmpopts.SortSlices(func)             : スライス値のソート（FieldChanges自体は自動ソート済み）
```

### 3. Create / Update / Delete の判定

| 操作 | OldValue | NewValue | WithResourceID | WithChanges |
|---|---|---|---|---|
| **Create** | 全て `nil` | 実際の値 | 使わない（IDは動的生成） | あり |
| **Update** | 変更前の値 | 変更後の値 | IDが既知なら使う | あり |
| **Delete** | 削除前の値 | 全て `nil` | IDが既知なら使う | あり |

### 3b. WithResourceID の使用判断

| IDの定義方法 | WithResourceID |
|---|---|
| 固定文字列（`shareID = "share-1"`） | ✅ 使う |
| テスト上部の `var` ブロックで定義（`subscriptionID = "subscription-1"`） | ✅ 使う |
| `uuid.NewString()` で動的生成 | ✗ 使わない |
| モック内の `DoAndReturn` で動的に返却 | ✗ 使わない |

### 3c. Update操作のOldValue特定方法

Update操作では `prepare` 関数内で既存エンティティが設定される。OldValueはこのエンティティの値から読み取る:

```go
// prepare 関数内の典型的なパターン
args.input.ShiftScheduleDefinition = &model.ShiftScheduleDefinition{
    ID:          defID,
    WorkspaceID: workspaceID,
    Position:    1,           // ← OldValue: 1
    Name:        "病棟A シフト表", // ← OldValue: "病棟A シフト表"
    ClosingDate: 20,          // ← OldValue: 20
    IsEnabled:   true,        // ← OldValue: true
}
```

inputの更新フィールド（例: `Name: util.AnyPtr("病棟B シフト表")`）がNewValueになり、それ以外のフィールドはOld == Newになる。

### 3d. No-op パターン（同値更新）

同じ値への更新が no-op として処理されるケースがある。`TrackOldValue` は呼ばれるが `TrackNewValue` は呼ばれないため、`Changes` が不完全になる。`WithChanges` は使わず `WithAction` + `WithResource` のみで検証する:

```go
// 同じステータスへの更新（no-op）
mocks.mockLogger.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionUpdate),
    util.WithResource(domainaudit.ResourceCalendarEventResourceAllocation),
))
```

### 3e. 早期リターンパターン（nil 入力）

入力が nil の場合に早期リターンするユースケースでは、最小限の builder が作成される。`ResourceID` や `TrackOldValue` は呼ばれない:

```go
// ユースケース実装
if input.Subscription == nil {
    builder := u.audits.NewBuilder(audit.ActionDelete, audit.ResourceCalendarSubscription).
        Context(ctx).
        Error(repository.ErrNotFound)
    u.audits.Log(ctx, builder.Build())
    return nil, errors.WithHint(repository.ErrNotFound, msg.UnsubscribeCalendarNotFound)
}
```

テストでは `WithResourceID` を省略し、エラーメッセージのみ検証する:

```go
m.mockAudits.EXPECT().Log(gomock.Any(), util.NewAuditEventMatcher(
    util.WithAction(domainaudit.ActionDelete),
    util.WithResource(domainaudit.ResourceCalendarSubscription),
    util.WithErrorMessageContains("NOT_FOUND"),
))
```

### 4. 修正→テスト実行サイクル

**1件ずつ修正→テスト実行を繰り返す。複数テストケースを一括修正しない。**

```bash
# 1件目のテスト実行
go test -timeout 30s -v -race -vet=all -run "TestName/テストケース名" ./internal/usecase/

# 成功したら次のテストケースへ

# 全件完了後の最終検証
go test -timeout 30s -v -race -vet=all -run "TestName" ./internal/usecase/
```

### 4b. エラーメッセージの発見ワークフロー

異常系テストで `WithErrorMessageContains` を使う際、正確なエラーメッセージが事前に分からないことが多い。以下のワークフローで効率的に対応する:

1. **ユースケース実装からエラー発生箇所を特定** — `errors.Wrap(err, "...")` や `model.ErrXxx` の文字列を確認
2. **最善の推測で部分一致文字列を設定** — ドメインエラー変数名やラップメッセージから推測
3. **テスト実行** — 失敗した場合、エラー出力に実際のメッセージが表示される
4. **実際のメッセージに修正** — 出力の `got "..."` 部分から正確な部分文字列を選ぶ

```
// テスト失敗時の出力例:
// expected to contain "invalid status transition",
// got "UpdateAllocationStatus(): invalid participation status transition: invalid state"
//                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                                 この部分を WithErrorMessageContains に使う
```

**よくある実エラーメッセージパターン:**

| ドメインエラー | 実際のエラーメッセージ（例） |
|---|---|
| `model.ErrWorkspaceMismatch` | `"workspace mismatch"` |
| `model.ErrCalendarNotOwner` | `"not the calendar owner"` |
| `model.ErrSubscriptionNotOwner` | `"not the subscription owner"` |
| `model.ErrInvalidStatusTransition` | `"invalid participation status transition"` |
| `model.ErrResourceUpdateForbidden` | `"forbidden"` |
| `model.ErrCalendarDataInconsistency` | `"workspace mismatch"` （注: 内部的にはワークスペース不一致として処理される場合あり） |
| `repository.ErrNotFound` | `"NOT_FOUND"` |

**注意:** エラーメッセージはドメインモデルの実装に依存する。推測で書くのではなく、テスト実行結果から正確に取得すること。

**重要: テスト名とエラーメッセージは一致しないことがある**

テストケース名が「割り当てとイベントが不一致の場合」であっても、ドメインモデルの実装によっては `"workspace mismatch"` エラーになることがある。これは、ドメインモデルがデータ整合性チェックを特定の順序で行うためである。

```
// テストケース名: "異常系: 割り当てとイベントが不一致の場合NOT_FOUNDエラー"
// 期待（推測）: WithErrorMessageContains("data inconsistency")
// 実際: WithErrorMessageContains("workspace mismatch")
```

**必ずテスト実行結果で実際のエラーメッセージを確認すること。テスト名から推測しない。**

### 4c. 最終確認

全テストケースの修正が完了したら、以下を確認する:

1. **全テスト実行** — `go test -timeout 30s -v -race -vet=all -run "TestName" ./internal/usecase/`
2. **`gomock.Any()` の残存確認** — `Grep: \.Log\(gomock\.Any\(\), gomock\.Any\(\)\)` でファイルを検索し、監査ログの `Log` 呼び出しに `gomock.Any()` が残っていないことを確認

## Common Mistakes

| 間違い | 正しい対応 |
|---|---|
| Create操作で `WithResourceID` を指定 | IDは動的生成されるため省略する |
| `*string` フィールドの期待値を `util.AnyPtr("val")` にする | `dereferenceValue` で `string` になるので `"val"` にする |
| nil pointer の期待値を `(*string)(nil)` にする | `dereferenceValue` で `nil` (interface) になるので `nil` にする |
| 全テストを一括修正 | 1件ずつ修正→テスト実行で確認する |
| `TrackNewValue` の実装を見ずに推測でフィールドを書く | 必ずドメインモデルの実装を読んで正確なフィールドリストを取得する |
| 既に `NewAuditEventMatcher` を使用しているテストを無理に修正する | 調査結果が「修正不要」なら何もしない |
| `.Times(N)` をそのまま残す | 個別のマッチャーに分割して各監査ログの内容を検証する |
| Resource/Action の妥当性を検証しない | 操作対象のリソースと一致するか、アクションが操作の意味と一致するか確認する |
| モック内で `uuid.NewString()` した値を `WithChanges` で検証しようとする | 動的値は検証不能。`WithAction` + `WithResource` のみで検証する |
| `TrackNewValue` をバリデーション後に呼ぶ | バリデーション前に呼ぶ。バリデーションエラー時にも新値が記録される |
| `TrackOldValue` を業務ロジック実行後に呼ぶ | DB読み込み直後に呼ぶ。エラー時にも旧値が記録される |
| `NewMockLogger(ctrl)` を直接使用する | **禁止。** `NewMockLoggerWithImpl(ctrl)` を使う。発見次第マイグレーションする |
| マイグレーション時に `NewBuilder` の EXPECT を残す | `NewMockLoggerWithImpl` は `NewBuilder` を自動提供するため、手動 EXPECT は競合してテスト失敗する |
| nil スライスの期待値に素の `nil` を使用する | `RecordChange` に渡された nil スライスは型情報を持つ。`[]model.XxxType(nil)` と書く |
| `.Do` ハンドラの手動検証をそのまま残す | `util.NewAuditEventMatcher` に置換する。`.Do` 内の `*audit.AuditEvent` 型アサーションは不要 |
| `builder.Build()` を Log 引数に残す | `NewMockLoggerWithImpl` 移行後は builder への参照がないため `util.NewAuditEventMatcher` に置換する |
| マイグレーション時に一部テストケースだけ `NewBuilder` EXPECT を削除する | `NewMockLoggerWithImpl` の `NewBuilder` EXPECT (`AnyTimes()`) と競合する。全テストケースを一括で削除する |
| `.Do` ハンドラでのみ使用されていた import を残す | `slices`, `context`（args 構造体で未使用の場合）等の不要 import を削除する |
| 異常系テストの `gomock.Any()` をそのまま残す | 異常系も `WithAction` + `WithResource` + `WithErrorMessageContains` に置換する |
| エラーメッセージを推測だけで書いて修正しない | テスト実行結果から実際のメッセージを確認して正確な部分文字列を使う |
| `domainaudit` import を追加し忘れる | マッチャー追加前にテストファイルの import セクションを確認・追加する |
| `cmpopts` import を追加し忘れる | `IgnoreSliceElements` や `EquateApproxTime` を使う場合は `cmpopts` import が必要 |
| 手動デリファレンスされたフィールドの期待値を `nil` にする | `TrackOldValue` 実装を読み、手動デリファレンス時はゼロ値（`""`）を期待値にする |
| Delete操作の NewValue を旧値のままにする | Delete操作では全 NewValue が `nil` |
| 固定文字列IDで `WithResourceID` を省略する | 固定文字列ID（`"share-1"` 等）は必ず `WithResourceID` で検証する |
| `NewMockTxManager(ctrl)` を直接使用する | **禁止。** `NewMockTxManagerWithImpl(ctrl)` を使う。`RunInWritingTransaction` の EXPECT が不要になる |
| shared コンポーネントの Return で `audit.NewAuditEventBuilder` を使う | `m.mockAudits.NewBuilder` を使う。`audit` import を削除でき、モックとの一貫性を保てる |
| ビルダーを外部から受け取るだけのユースケースで `NewAuditEventMatcher` を強制する | usecase が `audits.NewBuilder` を呼ばない場合は `gomock.Any()` が適切 |
| テストケース名からエラーメッセージを推測する | テスト名と実際のエラーは一致しないことがある。必ずテスト実行結果から確認する |
| `.Times(N)` を残したまま異なるリソースタイプの監査ログを検証しない | 個別のマッチャーに分割し、各リソースタイプを明示的に検証する |
