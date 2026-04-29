---
name: e2e-worker-test
description: Use when implementing E2E tests for worker jobs (SQS-based async processing), scheduler batch jobs, or fan-out event patterns. Covers ExecuteJob, DrainEvents, FlushPendingEvents, ClearEvents usage and common pitfalls.
---

# E2E Worker Test

## Overview

ワーカージョブ（SQS ベース非同期処理）の E2E テストパターン。ジョブを直接実行し、DB 状態変化やイベント発行件数を検証する。

## When to Use

- Scheduler バッチジョブの E2E テスト実装時
- Fan-Out パターン（1 ジョブ → 複数イベント発行）のテスト実装時
- `ExecuteJob`, `DrainEvents`, `FlushPendingEvents` の使い分けで迷ったとき

## When NOT to Use

- GraphQL Mutation/Query の E2E テスト → `e2e-common-patterns.md` ルールを参照
- ユニットテスト → `testing-rules.md` を参照

## Investigation Checklist（テスト作成前に必ず実施）

テストコードを書く前に以下を全て調査する。調査不足はFK制約違反やNOT NULL違反でのpanicに直結する。

1. **Handler**: `Name()` メソッドでジョブ名を確認（`model.EventName*` 定数）
2. **Usecase**: Direct Worker（DB直接変更）か Fan-Out（イベント発行）か判定
3. **フィルタリング条件の2層分離**: Persistence層（SQL WHERE句）とDomain層（Goメソッド）のフィルタリング条件を**それぞれ独立に**把握する。テストケースは各フィルタ条件ごとに1つずつ作る
4. **Persistence**: 実行されるSQL、eager loading（`qm.Load`）、クエリ条件を確認
5. **Migration**: 対象テーブルの制約を確認（NOT NULL、FK参照、UNIQUE）。FK参照先が深い場合は依存チェーンを末端まで辿る
6. **Factory + 制約の整合性**: 対象テーブルの factory が `test/factory/` に存在するか確認。**factoryが `boil.Whitelist` を使っているか `boil.Infer()` を使っているかを確認する**（後述の Critical Trap 参照）
7. **既存E2Eテスト**: `test/e2e/tests/` で同種ジョブのテストパターンを参照

## Quick Reference

### TestApp メソッド

| メソッド | 効果 | 用途 |
|---------|------|------|
| `app.ExecuteJob(ctx, name, args)` | ジョブハンドラを直接実行、`*PerformedJob` を返す | Scheduler ジョブの実行 |
| `app.DrainEvents(ctx)` | バッファ内イベントを全て処理（ハンドラ実行）、`*DrainResult` を返す | 下流ジョブまで含めた統合テスト |
| `app.FlushPendingEvents()` | バッファ内イベントをフラッシュ（ハンドラ未実行）、`*DrainResult` を返す | 発行件数のみ検証 |
| `app.ClearEvents()` | バッファを破棄（ハンドラ未実行、結果なし） | サブテスト間の独立性確保 |

### アサーション

| 関数 | 検証内容 |
|------|---------|
| `e2e.AssertJobExecuted(t, result)` | ジョブがエラーなしで完了 |
| `e2e.AssertJobCount(t, drainResult, jobName, wantCount)` | 指定名ジョブの件数一致 |
| `e2e.AssertNoJobs(t, drainResult, jobName)` | 指定名ジョブが存在しない |

### DrainResult ヘルパー

| メソッド | 戻り値 | 説明 |
|---------|--------|------|
| `result.FindJob(name)` | `*PerformedJob` | 指定名の最初のジョブ（nil = 未発見） |
| `result.FindJobs(name)` | `[]PerformedJob` | 指定名の全ジョブ |
| `result.FailedJobs()` | `[]PerformedJob` | `Err != nil` のジョブ一覧 |
| `result.JobNames()` | `[]string` | 実行されたジョブ名の一覧 |

## Critical Trap: DrainEvents vs FlushPendingEvents

```
DrainEvents     = イベント取り出し + ハンドラ実行 → DB状態が変わる
FlushPendingEvents = イベント取り出し + ハンドラ未実行 → DB状態は変わらない
```

**Fan-Out ジョブの件数検証では必ず `FlushPendingEvents` を使う。**

`DrainEvents` を使うと下流ハンドラが DB を変更し、後続サブテストでデータ件数がずれる。

```go
// BAD: 下流ハンドラが実行され、DBが変更される
result := app.DrainEvents(ctx)
e2e.AssertJobCount(t, result, "sync_external_ics", 1)

// GOOD: ハンドラ未実行で件数のみ検証
result := app.FlushPendingEvents()
e2e.AssertJobCount(t, result, "sync_external_ics", 1)
```

## Critical Trap: boil.Whitelist vs boil.Infer() と NOT NULL 制約

factory が `boil.Whitelist` を使う場合、zero value もそのまま INSERT される。カスタム型（`TSTZRange`, `null.Time` 等）の zero value が NULL に変換されると、NOT NULL 制約で panic する。

```go
// BAD: publish_period が NOT NULL なのに TSTZRange のzero value（= NULL）で INSERT → panic
factory.CreateAnnouncement(ctx, app.DB(),
    factory.WithAnnouncementWorkspaceID(workspace.ID),
    factory.WithAnnouncementAuthorID(user.ID),
    // PublishPeriod 未設定 → TSTZRange{Valid: false} → NULL → NOT NULL 制約違反!
)

// GOOD: NOT NULL カラムには必ず有効な値を設定
factory.CreateAnnouncement(ctx, app.DB(),
    factory.WithAnnouncementWorkspaceID(workspace.ID),
    factory.WithAnnouncementAuthorID(user.ID),
    factory.WithAnnouncementPublishPeriod(itypes.TSTZRange{
        Valid: true, LowerType: pgtype.Unbounded, UpperType: pgtype.Unbounded,
    }),
)
```

**Investigation 段階で NOT NULL カラムを見つけたら、factory のデフォルト値がそのカラムに有効な値を設定するか確認する。**

## テストデータ作成パターン: baseOpts 関数

ヘルパー関数は **`[]factory.Option` を返すクロージャ** にする。文字列引数のヘルパーは避ける。

```go
// BAD: 文字列引数で型安全性なし、上書きが困難
createPublishedAnnouncement := func(title, wsID, authorID string) *models.Announcement {
    return factory.CreateAnnouncement(ctx, app.DB(),
        factory.WithAnnouncementWorkspaceID(wsID),
        factory.WithAnnouncementIsPublished(true), // ハードコード → スキップテストで使えない
    )
}

// GOOD: 型付き引数 + オプション返却で柔軟に上書き可能
baseAnnouncementOpts := func(ws *models.Workspace, u *models.WorkspaceUser) []factory.AnnouncementOption {
    return []factory.AnnouncementOption{
        factory.WithAnnouncementWorkspaceID(ws.ID),
        factory.WithAnnouncementAuthorID(u.ID),
        factory.WithAnnouncementAuthorName("テスト投稿者"),
        factory.WithAnnouncementTitle("テストお知らせ"),
        factory.WithAnnouncementBody(types.JSON(`{"ops":[{"insert":"\n"}]}`)),
        factory.WithAnnouncementBodySearchable(""),
        factory.WithAnnouncementIsPublished(true),
        factory.WithAnnouncementAllowComment(true),
        factory.WithAnnouncementIsDeleted(false),
    }
}

// 正常系: そのまま使う
opts := append(baseAnnouncementOpts(workspace, user),
    factory.WithAnnouncementPublishPeriod(publishPeriodCurrent),
)
announcement := factory.CreateAnnouncement(ctx, app.DB(), opts...)

// スキップテスト: 特定フィールドだけ上書き
opts := append(baseAnnouncementOpts(workspace, user),
    factory.WithAnnouncementPublishPeriod(publishPeriodCurrent),
    factory.WithAnnouncementIsPublished(false), // 上書き
)
```

**baseOpts の設計原則:**

- **全 NOT NULL フィールドを設定する**（zero value に依存しない）
- **引数は `*models.Workspace`, `*models.WorkspaceUser` 等の型付きオブジェクト**（文字列IDではなく）
- **テストで変動する値（PublishPeriod等）は baseOpts に含めない**（呼び出し側で append する）
- **共通の固定値（TSTZRange等）は変数として事前定義する**

```go
// 共通テスト値を変数化
publishPeriodCurrent := itypes.TSTZRange{
    Valid: true,
    Lower: null.TimeFrom(time.Now().Add(-1 * time.Hour).UTC().Truncate(time.Millisecond)),
    LowerType: pgtype.Inclusive, UpperType: pgtype.Unbounded,
}
publishPeriodFuture := itypes.TSTZRange{
    Valid: true,
    Lower: null.TimeFrom(time.Now().Add(24 * time.Hour).UTC().Truncate(time.Millisecond)),
    LowerType: pgtype.Inclusive, UpperType: pgtype.Unbounded,
}
```

## 明示性の原則

テストデータの値は**常に明示的に設定する**。デフォルト値や暗黙の挙動に依存しない。

```go
// BAD: デフォルトが false であることに暗黙依存
factory.CreateAnnouncementPushNotification(ctx, app.DB(),
    factory.WithAnnouncementPushNotificationAnnouncementID(ann.ID),
    // PushNotificationEnabled はデフォルト false ← コメントで補足しても暗黙依存
)

// GOOD: テストの意図を明示
factory.CreateAnnouncementPushNotification(ctx, app.DB(),
    factory.WithAnnouncementPushNotificationAnnouncementID(ann.ID),
    factory.WithAnnouncementPushNotificationPushNotificationEnabled(false), // 明示的に無効
)
```

## 累積件数コメントの書き方

件数検証のコメントは**累積の内訳を明記する**。「前と同数」のような曖昧な表現は避ける。

```go
// BAD: 何が「前と同数」なのか不明
e2e.AssertJobCount(t, pendingResult, "downstream_job", 1) // 前と同数

// GOOD: 累積の内訳が明確
e2e.AssertJobCount(t, pendingResult, "downstream_job", 1) // サブテスト2の1件のみ（今回追加分はスキップ）

// GOOD: 増加時も内訳を記載
e2e.AssertJobCount(t, pendingResult, "downstream_job", 3) // WS-A 2件 + WS-B 1件 = 3件
```

## Pattern 1: Direct Worker（DB 直接変更型）

ジョブがDB を直接変更するパターン。Before/After で DB 状態を比較する。

**該当例**: `extend_recurring_instances`（繰り返しインスタンス延長バッチ）

```go
func TestMyBatchJob(t *testing.T) {
    t.Parallel()
    app := e2e.NewTestApp(t)
    ctx := app.Context()

    // 共通テストデータ
    workspace := factory.CreateWorkspace(ctx, app.DB())
    // ... 必要なデータ作成 ...

    t.Run("正常系: 対象レコードが処理される", func(t *testing.T) {
        // テスト対象データを作成
        // ...

        // Before: DB状態を記録
        beforeCount, err := models.TargetTable(
            models.TargetTableWhere.SomeColumn.EQ(someValue),
        ).Count(ctx, app.DB())
        if err != nil {
            t.Fatalf("failed to count before: %v", err)
        }

        // ジョブ実行
        result := app.ExecuteJob(ctx, "my_batch_job", "")
        e2e.AssertJobExecuted(t, result)

        // After: DB状態を検証
        afterCount, err := models.TargetTable(
            models.TargetTableWhere.SomeColumn.EQ(someValue),
        ).Count(ctx, app.DB())
        if err != nil {
            t.Fatalf("failed to count after: %v", err)
        }

        if afterCount <= beforeCount {
            t.Errorf("records should increase: before=%d, after=%d",
                beforeCount, afterCount)
        }
    })

    t.Run("正常系: 対象データなしでもエラーなし", func(t *testing.T) {
        result := app.ExecuteJob(ctx, "my_batch_job", "")
        e2e.AssertJobExecuted(t, result)
    })
}
```

## Pattern 2: Fan-Out Worker（イベント発行型）

ジョブが下流ジョブ向けにイベントを発行するパターン。

**該当例**: `sync_all_external_calendars` → `sync_external_ics` を N 件発行

**重要: データ蓄積問題**

サブテスト間でデータが蓄積するため、件数は **累積値** で検証する。各サブテストの冒頭で `ClearEvents()` を呼んでイベントバッファをリセットするが、DB 内のデータは残る。

```go
func TestMyFanOutJob(t *testing.T) {
    t.Parallel()
    app := e2e.NewTestApp(t)
    ctx := app.Context()

    // 共通テストデータ
    workspace := factory.CreateWorkspace(ctx, app.DB())
    user := factory.CreateWorkspaceUser(ctx, app.DB(),
        factory.WithWorkspaceUserWorkspaceID(workspace.ID),
    )

    // 共通テスト値
    publishPeriodCurrent := itypes.TSTZRange{...} // 公開期間内
    publishPeriodFuture := itypes.TSTZRange{...}  // 公開期間が未来

    // baseOpts: 全NOT NULLフィールドを明示設定
    baseOpts := func(ws *models.Workspace, u *models.WorkspaceUser) []factory.SomeOption {
        return []factory.SomeOption{
            factory.WithWorkspaceID(ws.ID),
            factory.WithAuthorID(u.ID),
            // ... 全NOT NULLフィールドを列挙 ...
        }
    }

    t.Run("正常系: 対象なしでもエラーなし", func(t *testing.T) {
        result := app.ExecuteJob(ctx, "my_fan_out_job", "")
        e2e.AssertJobExecuted(t, result)

        pendingResult := app.FlushPendingEvents()
        e2e.AssertNoJobs(t, pendingResult, "downstream_job")
    })

    t.Run("正常系: 対象1件で下流イベント1件発行", func(t *testing.T) {
        opts := append(baseOpts(workspace, user),
            factory.WithPublishPeriod(publishPeriodCurrent),
        )
        record := factory.CreateRecord(ctx, app.DB(), opts...)
        // 関連テーブルも作成
        factory.CreateRelated(ctx, app.DB(),
            factory.WithRecordID(record.ID),
            factory.WithEnabled(true), // 明示的に設定
        )

        app.ClearEvents()
        result := app.ExecuteJob(ctx, "my_fan_out_job", "")
        e2e.AssertJobExecuted(t, result)

        pendingResult := app.FlushPendingEvents()
        e2e.AssertJobCount(t, pendingResult, "downstream_job", 1)
    })

    // --- スキップ条件テスト（フィルタ条件ごとに1つずつ） ---

    t.Run("正常系: [Domain層] 条件Aを満たさないレコードはスキップ", func(t *testing.T) {
        opts := append(baseOpts(workspace, user),
            factory.WithPublishPeriod(publishPeriodCurrent),
        )
        record := factory.CreateRecord(ctx, app.DB(), opts...)
        factory.CreateRelated(ctx, app.DB(),
            factory.WithRecordID(record.ID),
            factory.WithEnabled(false), // このフィールドだけ変更
        )

        app.ClearEvents()
        result := app.ExecuteJob(ctx, "my_fan_out_job", "")
        e2e.AssertJobExecuted(t, result)

        pendingResult := app.FlushPendingEvents()
        // サブテスト2の1件のみ（今回追加分はDomain層フィルタでスキップ）
        e2e.AssertJobCount(t, pendingResult, "downstream_job", 1)
    })

    t.Run("正常系: [Persistence層] 条件Bを満たさないレコードはスキップ", func(t *testing.T) {
        opts := append(baseOpts(workspace, user),
            factory.WithPublishPeriod(publishPeriodFuture), // Persistence層で除外
        )
        record := factory.CreateRecord(ctx, app.DB(), opts...)
        factory.CreateRelated(ctx, app.DB(),
            factory.WithRecordID(record.ID),
            factory.WithEnabled(true),
        )

        app.ClearEvents()
        result := app.ExecuteJob(ctx, "my_fan_out_job", "")
        e2e.AssertJobExecuted(t, result)

        pendingResult := app.FlushPendingEvents()
        // サブテスト2の1件のみ（今回追加分はPersistence層フィルタで除外）
        e2e.AssertJobCount(t, pendingResult, "downstream_job", 1)
    })

    // --- 累積・横断テスト ---

    t.Run("正常系: 追加データで累積件数が増える", func(t *testing.T) {
        opts := append(baseOpts(workspace, user),
            factory.WithPublishPeriod(publishPeriodCurrent),
        )
        record := factory.CreateRecord(ctx, app.DB(), opts...)
        factory.CreateRelated(ctx, app.DB(),
            factory.WithRecordID(record.ID),
            factory.WithEnabled(true),
        )

        app.ClearEvents()
        result := app.ExecuteJob(ctx, "my_fan_out_job", "")
        e2e.AssertJobExecuted(t, result)

        pendingResult := app.FlushPendingEvents()
        // サブテスト2の1件 + 今回1件 = 2件
        e2e.AssertJobCount(t, pendingResult, "downstream_job", 2)
    })

    t.Run("正常系: 複数ワークスペースが横断処理される", func(t *testing.T) {
        workspaceB := factory.CreateWorkspace(ctx, app.DB())
        userB := factory.CreateWorkspaceUser(ctx, app.DB(),
            factory.WithWorkspaceUserWorkspaceID(workspaceB.ID),
        )
        opts := append(baseOpts(workspaceB, userB),
            factory.WithPublishPeriod(publishPeriodCurrent),
        )
        record := factory.CreateRecord(ctx, app.DB(), opts...)
        factory.CreateRelated(ctx, app.DB(),
            factory.WithRecordID(record.ID),
            factory.WithEnabled(true),
        )

        app.ClearEvents()
        result := app.ExecuteJob(ctx, "my_fan_out_job", "")
        e2e.AssertJobExecuted(t, result)

        pendingResult := app.FlushPendingEvents()
        // WS-A 2件 + WS-B 1件 = 3件
        e2e.AssertJobCount(t, pendingResult, "downstream_job", 3)
    })
}
```

### Fan-Out フロー図

```
ClearEvents()           ← 前サブテストのイベント残りを除去
    ↓
ExecuteJob()            ← ジョブ実行、下流イベントがバッファに溜まる
    ↓
FlushPendingEvents()    ← バッファからイベントを取り出し（ハンドラ未実行）
    ↓
AssertJobCount()        ← 件数検証
```

## Test Case Design Checklist

### Direct Worker

- [ ] 空実行: 対象データなしでもエラーなし
- [ ] 正常系: 対象レコードが正しく処理される（Before/After 比較）
- [ ] スキップ条件: 条件を満たさないレコードは処理されない
- [ ] 混在: 対象 + 非対象が混在する場合に正しく分離される
- [ ] 複数ワークスペース横断: Operator コンテキストで全 WS が処理される
- [ ] 冪等性: 2 回実行しても結果が変わらない

### Fan-Out Worker

- [ ] 空実行: 対象なしでもエラーなし、イベント 0 件
- [ ] 正常系: 全フィルタ条件を満たすデータで下流イベントが発行される
- [ ] **[Persistence層スキップ]**: SQL WHERE句の各フィルタ条件ごとに1テスト（例: `is_published=false`, `is_deleted=true`, `publish_period` 範囲外）
- [ ] **[Domain層スキップ]**: Go側の各フィルタ条件ごとに1テスト（例: `PushNotificationEnabled=false`, `PushNotificationSentAt` 設定済み）
- [ ] 境界値: フィルタ条件の境界ケース（例: unbounded range、NULL許容フィールド）
- [ ] 累積件数: サブテストでデータが増えた際の件数が正しい
- [ ] 複数ワークスペース横断: 全 WS の対象がイベント発行される
- [ ] 内部データ除外: 外部連携のみ対象の場合、内部データは除外される

## Common Mistakes

| 間違い | 正しい対応 |
|-------|-----------|
| Fan-Out ジョブの件数検証に `DrainEvents` を使う | `FlushPendingEvents` を使う（下流ハンドラの副作用を回避） |
| `ClearEvents()` を呼ばずに `ExecuteJob` する | サブテスト冒頭で `app.ClearEvents()` を呼んでバッファをリセット |
| 件数を絶対値で期待するが、前のサブテストのデータ蓄積を忘れる | 累積値で期待件数を計算する（DB データはサブテスト間で共有） |
| `ExecuteJob` の戻り値を検証しない | `e2e.AssertJobExecuted(t, result)` で必ずエラーチェック |
| ジョブ名を文字列リテラルで書き間違える | ハンドラの `Name()` メソッドの戻り値と一致させる |
| Direct Worker で Before 状態を取り忘れる | `ExecuteJob` の前に `models.Table(...).Count()` で記録 |
| サブテストで `t.Parallel()` を呼ぶ | トップレベルのみ `t.Parallel()`、サブテストでは呼ばない |
| factory の NOT NULL カラムにデフォルト値を使う | `boil.Whitelist` factory は zero value も INSERT する。NOT NULL カラムは全て明示設定 |
| ヘルパーに値をハードコード（例: `IsPublished=true`） | `baseOpts` パターンで返却し、呼び出し側で上書き可能にする |
| デフォルト値への暗黙依存（例: `// デフォルト false`） | テストの意図を明確にするため明示的に値を設定する |
| 累積コメントが曖昧（「前と同数」） | 「サブテスト2の1件のみ」「WS-A 2件 + WS-B 1件 = 3件」のように内訳を記載 |
| スキップ条件を1テストにまとめる | Persistence層とDomain層のフィルタ条件ごとに独立したテストを書く |
