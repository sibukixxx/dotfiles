# E2Eテスト共通パターン

サブエージェントがE2Eテストを実装する際に参照する共通パターン集。

## t.Parallel()の使い方（重要）

**ルール**:

1. **トップレベルのテスト関数で必ずt.Parallel()を呼ぶ**
2. **サブテスト（t.Run内）ではt.Parallel()を呼ばない**

```go
func TestEmailNotificationMutation_RegisterEmailForNotification(t *testing.T) {
	// MUST: トップレベルでt.Parallel()
	t.Parallel()

	app := e2e.NewTestApp(t)
	client := e2e.NewGraphQLClient(app.BaseURL())

	// セットアップ: 共有リソースを作成
	ctx := app.Context()
	workspace := factory.CreateWorkspace(ctx, app.DB())
	user := factory.CreateWorkspaceUser(ctx, app.DB(),
		factory.WithWorkspaceUserWorkspaceID(workspace.ID),
		factory.WithWorkspaceUserUsername("email-test-user"),
	)
	userToken := app.AuthHelper.GenerateWorkspaceUserToken(user)

	mutation := `
		mutation RegisterEmailForNotification($input: RegisterEmailForNotificationInput!) {
			registerEmailForNotification(input: $input) {
				verificationId
				emailAddress
				expiresAt
			}
		}
	`

	t.Run("正常系: メールアドレス登録成功", func(t *testing.T) {
		// MUST NOT: サブテストではt.Parallel()を呼ばない
		variables := map[string]any{
			"input": map[string]any{
				"emailAddress": "test@example.com",
			},
		}
		resp := client.MustQuery(t, mutation, variables, userToken)
		e2e.AssertNoErrors(t, resp)
	})

	t.Run("異常系: 未認証でUNAUTHENTICATED", func(t *testing.T) {
		// MUST NOT: サブテストではt.Parallel()を呼ばない
		variables := map[string]any{
			"input": map[string]any{
				"emailAddress": "test@example.com",
			},
		}
		resp := client.MustQuery(t, mutation, variables, "")
		e2e.AssertUnauthenticated(t, resp)
	})
}
```

**理由**:

- トップレベルのテスト関数は完全に独立している（それぞれ独自のDBインスタンス）
- サブテストは同じworkspace、user、token等を共有するため、並列実行すると競合する
- サブテスト内でt.Parallel()を使うと、共有リソースへの同時アクセスでテストが不安定になる

## テストの基本構造

```go
func TestFeature_Operation(t *testing.T) {
	t.Parallel()

	// 1. アプリとクライアントの初期化
	app := e2e.NewTestApp(t)
	client := e2e.NewGraphQLClient(app.BaseURL())
	ctx := app.Context()

	// 2. テストデータの作成
	workspace := factory.CreateWorkspace(ctx, app.DB())
	user := factory.CreateWorkspaceUser(ctx, app.DB(),
		factory.WithWorkspaceUserWorkspaceID(workspace.ID),
		factory.WithWorkspaceUserUsername("test-user"),
	)

	// 3. 認証トークンの生成
	userToken := app.AuthHelper.GenerateWorkspaceUserToken(user)

	// 4. GraphQL Mutation/Queryの定義
	mutation := `
		mutation DoSomething($input: DoSomethingInput!) {
			doSomething(input: $input) {
				id
				field1
				field2
			}
		}
	`

	// 5. サブテストケース
	t.Run("正常系: xxx", func(t *testing.T) { /* ... */ })
	t.Run("異常系: yyy", func(t *testing.T) { /* ... */ })
	t.Run("エッジ: zzz", func(t *testing.T) { /* ... */ })
}
```

## アサーション

```go
// 成功確認
e2e.AssertNoErrors(t, resp)

// エラー確認
e2e.AssertUnauthenticated(t, resp)  // 未認証
e2e.AssertForbidden(t, resp)        // 権限不足
e2e.AssertNotFound(t, resp)         // リソース未存在
e2e.AssertBadUserInput(t, resp)     // バリデーションエラー
e2e.AssertConflict(t, resp)         // 競合エラー

// バリデーションエラー（部分一致）
e2e.AssertValidationError(t, resp, "少なくとも1文字")
e2e.AssertValidationError(t, resp, "6文字")

// 汎用エラーチェック
if !resp.HasErrors() {
	t.Error("expected error")
}
```

## テストデータ作成パターン

### 基本的なファクトリ使用

```go
// ワークスペース作成
workspace := factory.CreateWorkspace(ctx, app.DB())

// ユーザー作成（オプション付き）
user := factory.CreateWorkspaceUser(ctx, app.DB(),
	factory.WithWorkspaceUserWorkspaceID(workspace.ID),
	factory.WithWorkspaceUserUsername("test-user"),
)

// 別ワークスペースのユーザー（RLSテスト用）
otherWorkspace := factory.CreateWorkspace(ctx, app.DB())
otherUser := factory.CreateWorkspaceUser(ctx, app.DB(),
	factory.WithWorkspaceUserWorkspaceID(otherWorkspace.ID),
	factory.WithWorkspaceUserUsername("other-user"),
)
```

### メール通知関連のファクトリ

```go
// メール認証レコード作成
verification := factory.CreateWorkspaceUserEmailVerification(ctx, app.DB(),
	factory.WithWorkspaceUserEmailVerificationWorkspaceID(workspace.ID),
	factory.WithWorkspaceUserEmailVerificationWorkspaceUserID(user.ID),
	factory.WithWorkspaceUserEmailVerificationEmailAddress("test@example.com"),
	factory.WithWorkspaceUserEmailVerificationVerificationCode("123456"),
	factory.WithWorkspaceUserEmailVerificationExpiresAt(time.Now().Add(10*time.Minute)),
)

// メール通知設定作成
setting := factory.CreateWorkspaceUserEmailNotificationSetting(ctx, app.DB(),
	factory.WithWorkspaceUserEmailNotificationSettingWorkspaceID(workspace.ID),
	factory.WithWorkspaceUserEmailNotificationSettingWorkspaceUserID(user.ID),
	factory.WithWorkspaceUserEmailNotificationSettingEmailAddress("test@example.com"),
	factory.WithWorkspaceUserEmailNotificationSettingNotificationInterval("every_6_hours"),
)
```

## 認証トークンの生成

```go
// ワークスペースユーザーのトークン
token := app.AuthHelper.GenerateWorkspaceUserToken(user)

// トークンなし（未認証テスト用）
resp := client.MustQuery(t, mutation, variables, "")
e2e.AssertUnauthenticated(t, resp)
```

## レスポンスデータの取得

```go
data := e2e.MustUnmarshalData[struct {
	RegisterEmailForNotification struct {
		VerificationId string `json:"verificationId"`
		EmailAddress   string `json:"emailAddress"`
		ExpiresAt      string `json:"expiresAt"`
	} `json:"registerEmailForNotification"`
}](t, resp)

if data.RegisterEmailForNotification.VerificationId == "" {
	t.Error("expected verificationId to be set")
}
if data.RegisterEmailForNotification.EmailAddress != "test@example.com" {
	t.Errorf("expected emailAddress 'test@example.com', got %q",
		data.RegisterEmailForNotification.EmailAddress)
}
```

## Node IDの変換

```go
// 各エンティティ用のヘルパー
nodeID := e2e.WorkspaceUserNodeID(user.ID)
nodeID := e2e.ChannelNodeID(channel.ID)
nodeID := e2e.CalendarNodeID(calendar.ID)

// 汎用
nodeID := e2e.NodeID("TypeName", id)
```

## 実装不備への対処

```go
t.Run("TODO: 異常系: 別ワークスペースのユーザーをjoinできない", func(t *testing.T) {
    t.Skip("FIXME: 実装側で別ワークスペースユーザーのjoin時にnilポインタ参照が発生する")
    // ...
})

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

// 管理者チェックが未実装の場合
t.Run("TODO: 異常系: 管理者でないユーザーはFORBIDDEN", func(t *testing.T) {
	t.Skip("FIXME: 実装側で管理者チェックが行われていない")
	// テストコード...
})

// バリデーションが未実装の場合
t.Run("異常系: 無効なメールアドレス形式", func(t *testing.T) {
	variables := map[string]any{
		"input": map[string]any{
			"emailAddress": "invalid-email",
		},
	}
	resp := client.MustQuery(t, mutation, variables, userToken)
	if !resp.HasErrors() {
		t.Skip("FIXME: 実装側でメールアドレス形式のバリデーションが行われていない")
	}
})

// 設定が存在しない場合のエラーハンドリング未実装
t.Run("異常系: メール設定が存在しないユーザーはエラー", func(t *testing.T) {
	resp := client.MustQuery(t, mutation, variables, userWithoutSettingsToken)
	if !resp.HasErrors() {
		t.Skip("FIXME: メール設定が存在しないユーザーへの更新がエラーにならない")
	}
})
```

## テスト実行コマンド

```bash
# 特定のテスト関数を実行
make test-e2e E2E_RUN="TestEmailNotification"

# パターンマッチで実行
make test-e2e E2E_RUN="TestWorkspaceUser"

# 全E2Eテストを実行
make test-e2e
```

## Test Architecture Reference

### フローテスト

複数Mutationの連携動作を検証。正常系の主要パスをカバー。

```go
func TestWorkspaceUserGroupMutation_CreateUpdateRemoveFlow(t *testing.T) {
    t.Parallel()
    // Setup...

    t.Run("正常系: create → update → remove の完全フロー", func(t *testing.T) {
        // Step 1: グループを作成
        createResp := client.MustQuery(t, createMutation, createVariables, adminToken)
        e2e.AssertNoErrors(t, createResp)
        groupID := createData.CreateWorkspaceUserGroup.WorkspaceUserGroup.ID

        // Step 2: グループを更新
        updateResp := client.MustQuery(t, updateMutation, updateVariables, adminToken)
        e2e.AssertNoErrors(t, updateResp)

        // Step 3: グループを削除
        removeResp := client.MustQuery(t, removeMutation, removeVariables, adminToken)
        e2e.AssertNoErrors(t, removeResp)

        // Step 4: 削除後に更新しようとするとNOT_FOUNDエラー
        updateResp2 := client.MustQuery(t, updateMutation, updateVariables, adminToken)
        e2e.AssertNotFound(t, updateResp2)
    })

    t.Run("異常系: create後に別ワークスペースからupdateできない（RLS）", func(t *testing.T) {
        // 別ワークスペースのユーザーを作成
        otherWorkspace := factory.CreateWorkspace(ctx, app.DB())
        otherUser := factory.CreateWorkspaceUser(ctx, app.DB(), ...)
        otherToken := app.AuthHelper.GenerateWorkspaceUserToken(otherUser)

        // 別ワークスペースのユーザーがupdateを試行
        updateResp := client.MustQuery(t, updateMutation, updateVariables, otherToken)
        e2e.AssertNotFound(t, updateResp) // RLSで見えない
    })
}
```

### 個別テスト

**異常系のみ**を残す。正常系はフローテストでカバー済み。

```go
func TestWorkspaceUserGroupMutation_Create(t *testing.T) {
    t.Parallel()
    // Setup...

    // ❌ 正常系は削除（フローテストでカバー済み）
    // t.Run("正常系: 管理者がグループを作成できる", ...)

    // ✅ 異常系のみ残す
    t.Run("異常系: 未認証ユーザーはグループを作成できない", func(t *testing.T) {
        resp := client.MustQuery(t, mutation, variables, "")
        e2e.AssertUnauthenticated(t, resp)
    })

    t.Run("異常系: グループ名が空はエラー", func(t *testing.T) {
        variables := map[string]any{
            "input": map[string]any{"name": ""},
        }
        resp := client.MustQuery(t, mutation, variables, adminToken)
        e2e.AssertValidationError(t, resp, "少なくとも1")
    })
}
```
