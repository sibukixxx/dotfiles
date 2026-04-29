---
name: e2e-test-impl
description: E2Eテストを実装し、テスト実行・TODO.md更新まで行う。サブエージェントを活用して自律的に実装する。
---

# E2E Test Implementation

## Overview

test/e2e/TODO.mdに基づいてE2Eテストを実装するワークフロー。**サブエージェントを活用**して、調査から実装、テスト実行まで効率的に実行する。

## When to Use

- ユーザーが「E2Eテストを実装して」と指示した場合
- 新機能のMutationやQueryのE2Eテストが必要な場合
- test/e2e/TODO.mdに未実装項目がある場合

## Key Principles

1. **調査は並列**: スキーマ調査とパターン分析は並列でサブエージェント実行
2. **実装も並列**: 複数ファイルに分割する場合は、ファイルごとにサブエージェントを並列起動（最大4個）
3. **実装は修正しない**: 実装上の問題を発見してもResolverやUsecaseは修正せず、すべて`t.Skip`で対処
4. **テスト実行は直接**: `make test-e2e`コマンドで直接実行

## Rules

1. **調査は並列**: スキーマ調査とパターン分析は並列でサブエージェント実行
2. **実装も並列**: 複数ファイルの場合はファイルごとに並列起動（最大4個）
3. **実装は修正しない**: プロダクションコードは変更禁止、問題は`t.Skip`で対処
4. **テストは直接実行**: `make test-e2e`で直接実行して確認
5. **既存パターン遵守**: プロジェクトの既存E2Eテストパターンに従う
6. **ファイル分割**: 1ファイル600行以内（大きすぎる場合は分割）
7. **グループ化**: 機能的関連性でMutationをグループ化（設定系、画像系、権限系など）

---

## Implementation Workflow

### Phase 1: 事前調査（並列サブエージェント）

**目的**: GraphQLスキーマと既存テストパターンを並列調査

```
# サブエージェント1: GraphQLスキーマ調査
Task(
  subagent_type: Explore
  description: GraphQLスキーマ調査
  prompt: |
    {Mutation名リスト}のGraphQLスキーマを調査しろ。

    調査項目:
    - Input型とフィールド（@constraint含む）
    - Output型
    - 認証要件（@hasAuthn）
    - 関連する列挙型

    graph/*.graphqls から調査し報告。
)

# サブエージェント2: 既存パターン分析
Task(
  subagent_type: Explore
  description: 既存テストパターン分析
  prompt: |
    test/e2e/tests/ の既存E2Eテストを分析し、以下を抽出:
    1. テスト関数の構造
    2. アサーションパターン
    3. ファクトリの使い方
    4. 認証トークン生成方法
)
```

---

### Phase 2: テストケース設計

**目的**: 実装前にテストケースを明確に設計する

**なぜ必須か**:

- 実装前にテスト観点を明確化し、漏れを防ぐ
- サブエージェントへの指示が具体的になり、品質が向上
- レビュー可能な成果物として残る

**サブエージェント指示**:

````
Task(
  subagent_type: general-purpose
  description: {機能名} テストケース設計
  prompt: |
    以下のMutationのE2Eテストケースを設計しろ:
    {Mutation一覧}

    Phase 1で調査したスキーマ情報:
    {スキーマ情報をここに貼る}

    ## テスト構造設計
    まずMutation間の関連性を分析し、以下を判断:
    - フローテストが有効か（create→update→deleteのような連携操作がある場合）
    - フローテストでカバーできる正常系は個別テストから除外

    フローテストを採用する場合:
    - フローテスト: 複数Mutationの連携動作（正常系＋RLS異常系）
    - 個別テスト: 異常系のみ（未認証、バリデーションエラー等）

    ## テスト観点
    各Mutationについて以下の観点で網羅:
    - 正常系: 主要なユースケース（フローテストでカバーする場合は除外）
    - 異常系: 未認証（UNAUTHENTICATED）
    - 異常系: 権限不足（FORBIDDEN）- 管理者権限が必要な場合
    - 異常系: バリデーションエラー（BAD_USER_INPUT）
      - 必須フィールド欠落
      - 不正なフォーマット
      - 制約違反（minLength, maxLength等）
    - 異常系: RLS（NOT_FOUND）- 他ワークスペースアクセス
    - エッジ: 境界値、特殊パターン

    ## ファイル命名規則

    ```
    {entity}_{operation}_test.go
    ```

    例:

    - `email_notification_mutation_test.go`
    - `workspace_user_mutation_setting_test.go`
    - `calendar_event_mutation_test.go`

    ## 出力フォーマット
    ### テスト構造
    - フローテスト採用: Yes/No
    - 理由: {Mutation間の関連性分析結果}

    ### ファイル構成
    - {ファイル名1}_test.go: {Mutation1}, {Mutation2}（{理由}）

    ### フローテスト（採用する場合）
    - TestXxx_CreateUpdateRemoveFlow
      - 正常系: create → update → remove の完全フロー
      - 異常系: create後に別ワークスペースからupdateできない（RLS）

    ### 個別テスト
    ## {Mutation名}
    - 異常系: 未認証でUNAUTHENTICATED
    - 異常系: {バリデーションエラーシナリオ}
)
````

**複数グループの並列設計**:

```
# 同時に複数グループのテストケースを設計（最大4個）
Task(subagent_type: general-purpose, description: "設定系テストケース設計")
Task(subagent_type: general-purpose, description: "画像系テストケース設計")
Task(subagent_type: general-purpose, description: "権限系テストケース設計")
Task(subagent_type: general-purpose, description: "管理系テストケース設計")
```

---

### Phase 3: 実装（サブエージェント）

**目的**: Phase 2で設計したテストケースを実装

**原則**: 1ファイル = 1サブエージェント。複数ファイルの場合は並列起動。

**サブエージェント指示**:

````
Task(
  subagent_type: general-purpose
  description: {ファイル名} E2Eテスト実装
  prompt: |
    {機能名}関連のE2Eテストを実装しろ。

    ## 出力ファイル
    test/e2e/tests/{ファイル名}_test.go

    ## 対象Mutation
    ### 1. {Mutation名1}
    - Input: {型名} - {フィールド一覧}
    - Output: {型名}
    - 認証: @hasAuthn

    ### 2. {Mutation名2}
    - Input: {型名} - {フィールド一覧}
    - Output: {型名}
    - 認証: @hasAuthn

    ## 設計済みテストケース
    {Phase 2で設計したテストケース}

    ## 共通パターン（必読）
    .claude/skills/e2e-test-impl/common-patterns.md を参照:
    - t.Parallel()の使い方（トップレベルのみ）
    - テストの基本構造
    - アサーション（e2e.Assert*）
    - テストデータ作成（factory.Create*）
    - 認証トークン生成
    - レスポンスデータ取得
    - Node IDの変換

    ## 実装ルール
    1. 既存パターンに従う
    2. t.Parallel()はトップレベルのみ、サブテストでは呼ばない
    3. factory.Create*でテストデータ作成
    4. e2e.Assert*でアサーション
    5. プロダクションコードは変更禁止（Resolver, Usecase, Repository等）

    ## 実装不備への対処
    実装側の問題を発見した場合、修正せずt.Skipで対処:

    ```go
    // テスト名に「TODO:」を付けて実装不備を明示
    t.Run("TODO: 異常系: 管理者でないユーザーはFORBIDDEN", func(t *testing.T) {
        t.Skip("FIXME: 実装側で管理者チェックが行われていない")
    })
    ```

    - 実装バグ → t.Skip("FIXME: {問題の説明}")
    - 修正できるのはテストコードのみ（コンパイルエラー、テストロジック）

    ## Factory調査
    test/factory/ で以下のファクトリを探せ:
    - {必要なファクトリ名1}
    - {必要なファクトリ名2}
    なければ直接DB挿入

    ## テスト実行
    make test-e2e E2E_RUN="{TestFunctionName}"

    ## 成果物報告
    - ファイル名と行数
    - テストケース一覧（PASS/SKIP）
    - 発見した問題点
)
````

**複数ファイルの並列実装**:

```
# 4ファイルに分割する場合、4つのサブエージェントを同時起動
Task(subagent_type: general-purpose, description: "設定系テスト実装", prompt: "...")
Task(subagent_type: general-purpose, description: "画像系テスト実装", prompt: "...")
Task(subagent_type: general-purpose, description: "権限系テスト実装", prompt: "...")
Task(subagent_type: general-purpose, description: "管理系テスト実装", prompt: "...")
```

---

### Phase 4: テスト実行・確認

サブエージェント完了後、直接テストを実行して確認:

```bash
make test-e2e E2E_RUN="TestFunctionName"
```

---

### Phase 5: TODO.md更新・レポート

1. test/e2e/TODO.mdを更新（`- [ ]` → `- [x]`）
2. Skipがある場合は注記（例: `90% - 管理者チェック未実装`）
3. 最終レポートを出力

---

### Phase 6: 重複テスト削除（フローテスト追加後）

フローテストを追加した後、カバー済みの個別正常系テストを削除する。

**削除対象の判定基準**:

1. フローテストで同じ操作が検証されている
2. 個別テストの正常系（異常系は残す）
3. 使われなくなった変数・定義も削除

**作業手順**:

```
1. フローテストのカバレッジ確認
   - create, update, removeがフローで検証済み → 各個別テストの正常系を削除対象に

2. 個別テストから正常系を削除
   - TestCreate: "正常系: 管理者がグループを作成できる" → 削除
   - TestUpdate: "正常系: グループを更新できる" → 削除
   - TestRemove: "正常系: グループを削除できる" → 削除

3. 不要変数の削除
   - 正常系テストでしか使われていなかったクエリ定義を削除

4. テスト実行で確認
   make test-e2e E2E_RUN="TestXxx"
```

---

## テスト実行コマンド

```bash
# 特定のテスト関数を実行
make test-e2e E2E_RUN="TestEmailNotification"

# 複数パターンを実行
make test-e2e E2E_RUN="TestWorkspaceUser"

# 全E2Eテストを実行
make test-e2e
```

---

### 実装バグへの対処

#### パターン1: nilポインタ参照

```go
t.Run("TODO: 異常系: 別ワークスペースのユーザーをjoinできない", func(t *testing.T) {
    t.Skip("FIXME: 実装側で別ワークスペースユーザーのjoin時にnilポインタ参照が発生する")
    // ...
})
```

**修正後の再有効化**:

1. 実装側でnilチェックを追加
2. スキップを外してテスト再実行
3. PASSすればテスト名から`TODO:`を削除

#### パターン2: RLSによるNOT_FOUND

別ワークスペースのリソースにアクセスすると、RLSにより見えないためNOT_FOUNDになる:

```go
t.Run("異常系: create後に別ワークスペースからupdateできない（RLS）", func(t *testing.T) {
    // 別ワークスペースのユーザーを作成
    otherWorkspace := factory.CreateWorkspace(ctx, app.DB())
    otherUser := factory.CreateWorkspaceUser(ctx, app.DB(),
        factory.WithWorkspaceUserWorkspaceID(otherWorkspace.ID),
    )
    otherToken := app.AuthHelper.GenerateWorkspaceUserToken(otherUser)

    // 別ワークスペースのユーザーがupdateを試行
    updateResp := client.MustQuery(t, updateMutation, updateVariables, otherToken)
    e2e.AssertNotFound(t, updateResp) // RLSにより対象が見つからない
})
```

---

## Success Metrics

- 実装完了率: 100%（Skipは許可）
- テスト成功率: 90%以上（実装不備によるSkipを除く）

## Exit Condition

- test/e2e/TODO.mdの全対象項目が実装完了
- 全体テストが期待通りに動作（Skipは許可）
- test/e2e/TODO.mdが更新済み
- 最終レポートが出力済み

---

## Example: メール通知テスト実装

### Phase 1: 並列調査

```
# 同時に2つのサブエージェントを起動
Task(subagent_type: Explore, description: "GraphQLスキーマ調査")
Task(subagent_type: Explore, description: "既存テストパターン分析")
```

**調査結果**:

- registerEmailForNotification: Input(emailAddress, minLength:1) → EmailVerificationStatus
- verifyEmailForNotification: Input(verificationCode, 6桁固定) → EmailNotificationSettings
- updateEmailNotificationSettings: Input(notificationInterval) → EmailNotificationSettings
- 全て@hasAuthn必須

### Phase 2: テストケース設計

```
Task(
  subagent_type: general-purpose
  description: メール通知テストケース設計
  prompt: |
    以下のMutationのE2Eテストケースを設計しろ:
    1. registerEmailForNotification
    2. verifyEmailForNotification
    3. updateEmailNotificationSettings

    スキーマ情報:
    - registerEmailForNotification: emailAddress (String!, minLength: 1)
    - verifyEmailForNotification: verificationCode (String!, 6桁固定)
    - updateEmailNotificationSettings: notificationInterval (EmailNotificationInterval!)
    - EmailNotificationInterval: OFF, EVERY_6_HOURS, EVERY_3_HOURS, EVERY_1_HOUR, EVERY_30_MINUTES

    各Mutationについて正常系・異常系・エッジケースを網羅しろ。テストサブエージェントかアーキテクトサブエージェントと設計を議論しろ。
)
```

**設計結果**:

```
## ファイル構成
- email_notification_mutation_test.go: 全3 Mutation（関連性が高く600行以内に収まる）

## registerEmailForNotification
- 正常系: メールアドレス登録成功
- 異常系: 未認証でUNAUTHENTICATED
- 異常系: 空のメールアドレスでBAD_USER_INPUT
- エッジ: 同じメールアドレスを再登録（冪等性確認）

## verifyEmailForNotification
- 正常系: 有効な認証コードで検証成功
- 異常系: 未認証でUNAUTHENTICATED
- 異常系: 無効な認証コードでエラー
- 異常系: 5桁のコードでBAD_USER_INPUT
- 異常系: 7桁のコードでBAD_USER_INPUT
- 異常系: 他ユーザーの認証コードは使えない

## updateEmailNotificationSettings
- 正常系: 通知間隔をEVERY_1_HOURに更新
- 正常系: 通知間隔をOFFに設定
- 正常系: 各通知間隔への更新（EVERY_30_MINUTES, EVERY_3_HOURS, EVERY_6_HOURS）
- 異常系: 未認証でUNAUTHENTICATED
- 異常系: メール設定が存在しないユーザーはエラー
```

### Phase 3: 実装サブエージェント起動

```
Task(
  subagent_type: general-purpose
  description: メール通知E2Eテスト実装
  prompt: |
    メール通知関連のE2Eテストを実装しろ。

    ## 出力ファイル
    test/e2e/tests/email_notification_mutation_test.go

    ## 設計済みテストケース
    {Phase 2の設計結果をここに貼る}

    ## Factory調査
    test/factory/ で以下を探せ:
    - CreateWorkspaceUserEmailVerification
    - CreateWorkspaceUserEmailNotificationSetting

    ## テスト実行
    make test-e2e E2E_RUN="TestEmailNotification"
)
```

### Phase 4: テスト実行

```bash
make test-e2e E2E_RUN="TestEmailNotification"
# 結果: 17テスト全PASS
```

### Phase 5: TODO.md更新

```diff
-- [ ] registerEmailForNotification
-- [ ] verifyEmailForNotification
-- [ ] updateEmailNotificationSettings
+- [x] registerEmailForNotification
+- [x] verifyEmailForNotification
+- [x] updateEmailNotificationSettings
```

### 最終レポート

| ファイル                            | 行数  |
| ----------------------------------- | ----- |
| email_notification_mutation_test.go | 423行 |

| Mutation                        | テスト数 | PASS   | SKIP  |
| ------------------------------- | -------- | ------ | ----- |
| registerEmailForNotification    | 4        | 4      | 0     |
| verifyEmailForNotification      | 6        | 6      | 0     |
| updateEmailNotificationSettings | 7        | 7      | 0     |
| **合計**                        | **17**   | **17** | **0** |
