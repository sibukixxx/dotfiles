---
paths: internal/infra/persistence/*.go
---

# 永続層実装における注意点と推奨プラクティス

永続層実装における注意点と推奨プラクティスをまとめる。

## ガイドライン

サマリーとして、以下のように実装を行う

### 共通実装パターン

- **構造体命名**: `{EntityName}Persistence` + `BasePersistence` 埋め込み
- **ファクトリ関数**: `New{EntityName}Persistence()` でリポジトリインターフェース返却
- **標準メソッド**: FindByID, FindByIDs, Fetch, Create, Update の統一実装
- **ページネーション**: カーソルベース（first/after, last/before）
- **エラーハンドリング**: `toRepoError` による一貫したエラー変換

### モデル変換規則

- **命名規則**:
  - ドメインモデル → DB: `translateBoilerEntityModel`
  - DB → ドメインモデル: `translateEntityModel`
- **null 値処理**: `null.String`, `null.Time` 型の適切な変換
- **実装場所**: 永続層内で変換関数をカプセル化

### トランザクション管理

- **管理主体**: ユースケース層が `TxManager.RunInWritingTransaction` / `RunInReadingTransaction` でトランザクションライフサイクルを制御
- **永続層**: `GetExecutor(ctx)` で ctx に紐付くトランザクションを取得（**TxManager 経由必須**。ctx に tx がなければ nil を返し、以降の DB 操作が失敗する）
- **RLS**: TxManager 内部でロールバック/コミットおよび RLS セッション変数の自動設定を担う（永続層側では意識不要）
- **ベストプラクティス**: 短期間、外部呼び出し回避、アクセス順序一貫性、読み取りは `RunInReadingTransaction`

### PostgreSQL 特有対応

- **LIMIT 制限**: DELETE 文での LIMIT 非対応（CTE/副問合せ使用）
- **ページネーション**: OFFSET/LIMIT 性能問題（キーセットページネーション検討）
- **データ型活用**: JSONB、テキスト検索機能の効果的利用
- **`SELECT *` 禁止**: prepared statement のキャッシュ不整合で本番障害を起こすため、カラムは必ず明示する
- **全カラム取得（JOIN なし）**: `models.{Entity}SelectAll`（SQLBoiler 生成済みの全カラム `qm.Select` 変数）を使う
- **JOIN 含むクエリ / 部分カラム指定**: `models.XColumns` / `models.XTableColumns` 定数を `qm.Select` に渡す（`models.XSelectAll` は JOIN で使わない、文字列リテラル直書き禁止）

## 永続層の共通実装パターン

これらのパターンは永続層の実装において一貫性を保ち、保守性を高めるために重要である。

### 構造体とファクトリ関数

- **構造体の命名**: 各エンティティには `{EntityName}Persistence` という命名規則の構造体を定義する
- **BasePersistence の埋め込み**: すべての永続層構造体は `BasePersistence` を埋め込む
- **ファクトリ関数**: `New{EntityName}Persistence()` という関数を提供し、対応するリポジトリインターフェースを返す

```go
// 構造体定義の例
type ChannelPersistence struct {
    BasePersistence
}

// ファクトリ関数の例
func NewChannelPersistence() repository.ChannelRepository {
    return &ChannelPersistence{}
}
```

### 標準メソッド名と実装パターン

以下の標準的なメソッド名とその実装パターンを使用する：

- **FindByID**: 単一 ID によるエンティティ検索

  ```go
  func (p *EntityPersistence) FindByID(ctx context.Context, id string) (*model.Entity, error) {
      exec := p.GetExecutor(ctx)
      r, err := models.FindEntity(ctx, exec, id)
      if err != nil {
          return nil, toRepoError(err)
      }
      return translateEntityModel(r), nil
  }
  ```

- **FindByIDs**: 複数 ID によるエンティティ検索

  ```go
  func (p *EntityPersistence) FindByIDs(ctx context.Context, ids []string) ([]*model.Entity, []error) {
      result := make([]*model.Entity, len(ids))
      errs := make([]error, len(ids))
      exec := p.GetExecutor(ctx)

      // クエリの実行
      r, err := models.Entities(models.EntityWhere.ID.IN(ids)).All(ctx, exec)
      if err != nil {
          // エラーハンドリング
          // ...
      }

      // 結果のマッピング
      // ...

      return result, errs
  }
  ```

- **Fetch**: ページネーション機能付きデータ取得

  ```go
  func (p *EntityPersistence) Fetch(ctx context.Context, first *int, after *string, last *int, before *string) (*repository.FetchOutput[*model.Entity], error) {
      // ページネーションパラメータの検証
      // クエリ条件の構築
      // 結果の取得とページネーション情報の計算
      // ...
  }
  ```

- **Create**: エンティティの新規作成

  ```go
  func (p *EntityPersistence) Create(ctx context.Context, entity *model.Entity) (*model.Entity, error) {
      exec := p.GetExecutor(ctx)
      r := translateBoilerEntityModel(entity)
      if err := r.Insert(ctx, exec, boil.Infer()); err != nil {
          return nil, toRepoError(err)
      }
      return translateEntityModel(r), nil
  }
  ```

- **Update**: 既存エンティティの更新
  ```go
  func (p *EntityPersistence) Update(ctx context.Context, entity *model.Entity) (*model.Entity, error) {
      exec := p.GetExecutor(ctx)
      r := translateBoilerEntityModel(entity)
      if _, err := r.Update(ctx, exec, boil.Infer()); err != nil {
          return nil, toRepoError(err)
      }
      return translateEntityModel(r), nil
  }
  ```

### ページネーション実装

カーソルベースのページネーションを実装するための標準的なパターン：

1. `first`/`after` または `last`/`before` パラメータを使用する
2. パラメータの組み合わせを検証する
3. デフォルトの制限とクエリ条件を設定する
4. `hasNext`/`hasPrev` フラグを計算する
5. 結果を `repository.FetchOutput` 構造体で返す

```go
// カーソルベースのページネーション実装例
if (first == nil && after == nil && last == nil && before == nil) ||
   ((first != nil || after != nil) && (last != nil || before != nil)) {
    return nil, repository.NewError(repository.ErrorInvalidArguments, msg.InvalidArguments)
}

// デフォルトのクエリ条件を構築
defaultMods := []qm.QueryMod{
    models.EntityWhere.WorkspaceID.EQ(workspaceID),
    models.EntityWhere.IsDeleted.EQ(false),
}

// 合計カウントの取得
total, err := models.Entities(defaultMods...).Count(ctx, exec)
if err != nil {
    return nil, toRepoError(err)
}

// ページネーションの実装
// ...

// HasNext/HasPrevの計算
// ...

return &repository.FetchOutput[*model.Entity]{
    Nodes:   result,
    Total:   int(total),
    HasNext: hasNext,
    HasPrev: hasPrev,
}, nil
```

### エラーハンドリングパターン

標準的なエラーハンドリングパターン：

1. `toRepoError` 関数によるデータベースエラーのリポジトリエラーへの変換
2. `sql.ErrNoRows` の特別な処理（多くの場合、nil または空のスライスを返す）
3. エラーメッセージの一貫した提供

```go
// エラーハンドリングの例
if err != nil {
    if errors.Is(err, sql.ErrNoRows) {
        return []*model.Entity{}, nil
    }
    return nil, toRepoError(err)
}
```

### 依存性注入パターン

依存性注入フレームワーク（fx）を使用して永続層の実装を登録する：

```go
// module.goでの依存性注入
var Module = fx.Module("persistence",
    fx.Provide(
        NewChannelPersistence,
        NewAppVersionPersistence,
        NewAttachmentPersistence,
        // 他の永続層ファクトリ関数
    ),
)
```

### SQLBoiler クエリ構築パターン

SQLBoiler のクエリモディファイア（QueryMod）を使用して動的クエリを構築する：

```go
// クエリ構築の例
mods := []qm.QueryMod{
    models.EntityWhere.WorkspaceID.EQ(workspaceID),
    models.EntityWhere.IsDeleted.EQ(false),
}

// 条件付き追加
if filtered {
    mods = append(mods, models.EntityWhere.IsArchived.EQ(false))
}

// 並び替え
mods = append(mods, qm.OrderBy(models.EntityTableColumns.ID+" DESC"))

// ページネーション
mods = append(mods, qm.Limit(limit), qm.Offset(offset))

// クエリ実行
rs, err := models.Entities(mods...).All(ctx, exec)
```

### テストパターン

永続層のテストでは以下のパターンを適用する：

1. テストデータベース環境のセットアップ
2. テストデータの挿入
3. テスト対象の永続層メソッドの呼び出し
4. 結果の検証

```go
// テーブル駆動型テストの例
func TestChannelPersistence_FindByID(t *testing.T) {
    tests := []struct {
        name    string
        id      string
        want    *model.Channel
        wantErr bool
    }{
        // テストケース定義
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // テスト実行と検証
        })
    }
}
```

以上の共通パターンを一貫して適用することで、永続層の実装における一貫性と保守性が向上し、新規開発や変更時のエラーが減少する。

## アーキテクチャパターン

### リポジトリパターン

永続層の実装では、リポジトリパターンを採用している。リポジトリはドメインモデルとデータソースの間の橋渡しを行い、永続化の詳細をドメインロジックから隠蔽する。

```go
// リポジトリインターフェースの定義例
type URLMetadataRepository interface {
    FindByID(ctx context.Context, id string) (*model.URLMetadata, error)
    Save(ctx context.Context, metadata *model.URLMetadata) (*model.URLMetadata, error)
    DeleteExpired(ctx context.Context, beforeTime time.Time) (int64, error)
    // その他の必要なメソッド
}

// 永続層の実装
type URLMetadataPersistence struct {
    BasePersistence
    // 他の依存性
}

// インターフェースの実装
func (p *URLMetadataPersistence) FindByID(ctx context.Context, id string) (*model.URLMetadata, error) {
    // 実装
}
```

#### ベストプラクティス

- リポジトリは**ドメインモデル**を受け取り、**ドメインモデル**を返す
- データベース固有の詳細はリポジトリ内にカプセル化する
- トランザクション管理を一貫して処理できるようにする
- テスト可能性を高めるためにモックしやすい設計にする

## データベース固有の構文

### PostgreSQL の特性と制限

- **ページネーション**: OFFSET/LIMIT の性能低下に注意し、「キーセットページネーション」を検討する

  ```sql
  -- 大きなオフセットでは性能が低下する問題のあるクエリ
  SELECT * FROM url_metadata ORDER BY created_at DESC OFFSET 10000 LIMIT 10;

  -- 代替: キーセットページネーション
  SELECT * FROM url_metadata
  WHERE created_at < '2025-01-01 00:00:00'
  ORDER BY created_at DESC
  LIMIT 10;
  ```

- **その他の PostgreSQL 固有の考慮点**:
  - JSONB データ型の活用
  - テキスト検索機能の違い
  - トランザクション分離レベルの挙動

### `SELECT *` の使用禁止とカラム明示

#### 背景

PostgreSQL の prepared statement はクライアント接続単位でキャッシュされる。デプロイ直後にスキーマが変更されると、新スキーマをロードした接続と旧スキーマのキャッシュを保持した接続が混在し、`SELECT *` ベースのクエリで以下のエラーが発生する。

```
ERROR: cached plan must not change result type
```

これは過去本番で複数回発生しており、カラム追加・削除のたびに再発リスクがある。カラムを明示することでキャッシュされた結果列定義と実際の結果列が一致し続け、このエラーを根本的に回避できる。

#### ルール

1. **生 SQL・`qm.SQL()`・`qm.Select()` のいずれにおいても `SELECT *` を使わない**
2. **全カラム取得が必要で、かつ JOIN を含まないクエリでは `models.{Entity}SelectAll` を使う**
   - SQLBoiler が各テーブルに対して自動生成する `qm.Select(全カラム...)` 変数（例: `models.BlobSelectAll`, `models.AnnouncementViewerSelectAll`）
   - スキーマにカラムを追加・削除しても `make fix` の再生成で自動的に追従するため、単一テーブル取得では最も安全
   - **JOIN を含むクエリでは `models.XSelectAll` を使わない**。生成コード (`internal/models/blobs.go:2787` など) を見ると `XSelectAll` は以下のようにテーブル名をハードコードした形で列を列挙している:
     ```go
     var BlobSelectAll = qm.Select(
         "\"blobs\".\"id\"", "\"blobs\".\"key\"", ...,
     )
     ```
     このため次の 2 つの問題が起こる:
     - (a) JOIN 先テーブルの列が一切含まれない (結合先をまとめて取得したい場合に不足)
     - (b) `FROM blobs AS b` のようにテーブルエイリアスを付けると、`"blobs"."id"` が解決できず SQL エラーになる
     
     JOIN 時は `models.XTableColumns.Field` を必要分だけ `qm.Select` に渡すか、SQLBoiler 標準 API（`qm.Select` 指定なし + `qm.Load` 等の eager loading）に任せる
3. **部分カラム取得の場合、および JOIN を含む場合は SQLBoiler 生成のカラム定数を `qm.Select` に渡す**
   - `models.XColumns.Field`（カラム名のみ、例: `"id"`）: 単一テーブルクエリ
   - `models.XTableColumns.Field`（`table.column` 形式、例: `"announcement_viewers.id"`）: JOIN を含むクエリや `ORDER BY` で使用
4. **文字列リテラル直書きは禁止**（リネーム追従不可・タイポ検知不可）

#### 推奨パターン

```go
// ✅ Best: 全カラムが必要なら models.{Entity}SelectAll
blobs, err := models.Blobs(
    append(mods, models.BlobSelectAll)...,
).All(ctx, exec)

// ✅ Good: 部分カラムだけ必要なら定数を qm.Select に渡す
viewers, err := models.AnnouncementViewers(
    models.AnnouncementViewerWhere.AnnouncementID.EQ(announcementID),
    qm.Select(
        models.AnnouncementViewerColumns.ID,
        models.AnnouncementViewerColumns.WorkspaceUserID,
        models.AnnouncementViewerColumns.AnnouncementID,
    ),
).All(ctx, exec)

// ✅ Good: JOIN を含むクエリは models.XTableColumns.Field を qm.Select に明示的に渡す
//    (models.XSelectAll は "blobs"."id" のようにテーブル名固定のためエイリアス不可、かつ JOIN 先列を取得できない)
blobs, err := models.Blobs(
    qm.InnerJoin("blob_usages ON blob_usages.blob_id = blobs.id"),
    models.BlobUsageWhere.WorkspaceID.EQ(workspaceID),
    qm.Select(
        models.BlobTableColumns.ID,
        models.BlobTableColumns.Filename,
        models.BlobTableColumns.ContentType,
    ),
).All(ctx, exec)

// ✅ Good: SQLBoiler 標準 API (qm.Select 指定なし) はモデル定義に従って自動でカラム列挙する (単一テーブル用)
entities, err := models.Entities(mods...).All(ctx, exec)
```

実装例: `internal/infra/persistence/blob_persistence_query.go:204`、`announcement_viewer_persistence_query.go:93`、`calendar_event_resource_allocation_persistence_query.go:73`、`fax_received_persistence_query.go:42, 179` 等。

#### 禁止パターン

```go
// ❌ Bad: SELECT * は prepared statement キャッシュ不整合の原因
queries.Raw("SELECT * FROM announcements WHERE id = $1", id)

// ❌ Bad: 文字列リテラル直書き（タイポ検知不可、リネーム追従不可）
qm.Select("id", "workspace_user_id", "announcement_id")

// ❌ Bad: 生 SQL でのカラム名リテラル直書き
queries.Raw("SELECT id, workspace_user_id FROM announcement_viewers WHERE ...")
```

生 SQL でもカラム列挙自体は必要なため、`"SELECT "+models.AnnouncementViewerColumns.ID+", "+...` のように SQLBoiler 定数を文字列連結で埋め込み、リテラル直書きを避ける。定数化すればリネーム追従・タイポ検知が効く。

#### レビュー観点

- `SELECT *` を見つけたら即座に指摘する
- 全カラムが必要で JOIN のない場面で `qm.Select(models.XColumns.A, models.XColumns.B, ...)` と手書き列挙していたら、`models.XSelectAll` に置き換えるよう指摘する
- **`models.XSelectAll` が JOIN を含むクエリ（`qm.InnerJoin`, `qm.LeftOuterJoin`, `qm.From` で別テーブルを参照、LATERAL JOIN など）で使われていたら指摘する**。`models.XTableColumns.Field` の個別指定か、`qm.Select` を外した標準 API への切り替えを要求する
- `qm.Select("...")` のような文字列リテラル直書きを見つけたら定数化を要求する
- Bulk Insert/Upsert で生 SQL を組み立てている箇所では、列挙すべきカラムが SQLBoiler 定数で網羅されているか確認する

## Go 言語でのデータアクセス

### エラーハンドリング

- 意味のあるエラーメッセージを提供する
- ドメインに特化したエラー型を定義する
- エラー時のロールバック処理を確実に行う

### SQLBoiler の効果的な使用

- N+1 問題を避けるために EagerLoading を活用する
- トランザクション管理を適切に行う
- クエリのキャッシュを考慮する

## パフォーマンス

### 大量データ処理の最適化

- **バッチ処理**: 大量データを一度に処理せず、バッチに分ける

  ```go
  // 大量のデータを削除する場合
  func DeleteInBatches(ctx context.Context, exec boil.ContextExecutor, batchSize int) (int64, error) {
    var totalDeleted int64
    for {
      // バッチサイズ分だけ削除
      ids, err := fetchExpiredIDs(ctx, exec, batchSize)
      if err != nil {
        return totalDeleted, err
      }
      if len(ids) == 0 {
        break // 削除対象がなくなったら終了
      }

      deleted, err := deleteByIDs(ctx, exec, ids)
      if err != nil {
        return totalDeleted, err
      }
      totalDeleted += deleted

      // 短い休止を入れてDBへの負荷を制御
      time.Sleep(10 * time.Millisecond)
    }
    return totalDeleted, nil
  }
  ```

### DB コネクション管理

- コネクションプールのサイズを適切に設定する
- 長時間実行クエリに対する監視とタイムアウト設定を行う
- トランザクションの範囲を最小限に保つ

## テストと検証

### 永続層のテスト戦略

- 実際の DB を使用した統合テストを実施する
- エッジケースを網羅する（空結果、大量データ、トランザクション競合など）
- テストデータ作成を自動化する

### テスト環境と本番環境の差異への対応

- 環境ごとの設定ファイルを用意する
- 環境変数で切り替え可能にする
- マイグレーションツールを活用して環境間のスキーマ一貫性を確保する

### パフォーマンステスト

- 大量データでのベンチマークテストを実施する
- クエリ実行計画を検証する
- インデックスの有効性を検証する

## モデル変換

### 命名規則と実装場所

- **命名規則**:

  - ドメインモデル → DB モデル: `translateBoilerEntityModel`
  - DB モデル → ドメインモデル: `translateEntityModel`
  - 例: `translateBoilerURLMetadatumModel()`, `translateURLMetadatumModel()`

- **実装場所**:
  - 変換関数は永続層レイヤー内に実装するのがベストプラクティスである
  - ドメインモデルと DB モデル間の依存関係を永続層内にカプセル化する

```go
// ドメインモデル → DBモデル変換の例
func translateBoilerURLMetadatumModel(metadata *model.URLMetadata) *models.URLMetadatum {
    if metadata == nil {
        return nil
    }

    return &models.URLMetadatum{
        ID:          metadata.ID,
        URL:         metadata.URL,
        WorkspaceID: metadata.WorkspaceID,
        Title:       null.StringFromPtr(&metadata.Title),
        Description: null.StringFromPtr(&metadata.Description),
        ImageURL:    null.StringFromPtr(&metadata.ImageURL),
        SiteName:    null.StringFromPtr(&metadata.SiteName),
        FetchedAt:   metadata.FetchedAt,
        ExpiresAt:   metadata.ExpiresAt,
        CreatedAt:   metadata.CreatedAt,
        UpdatedAt:   metadata.UpdatedAt,
        PublishedAt: null.TimeFromPtr(metadata.PublishedAt),
        ModifiedAt:  null.TimeFromPtr(metadata.ModifiedAt),
    }
}

// DBモデル → ドメインモデル変換の例
func translateURLMetadatumModel(dbModel *models.URLMetadatum) *model.URLMetadata {
    if dbModel == nil {
        return nil
    }

    metadata := &model.URLMetadata{
        ID:          dbModel.ID,
        URL:         dbModel.URL,
        WorkspaceID: dbModel.WorkspaceID,
        FetchedAt:   dbModel.FetchedAt,
        ExpiresAt:   dbModel.ExpiresAt,
        CreatedAt:   dbModel.CreatedAt,
        UpdatedAt:   dbModel.UpdatedAt,
    }

    // Null型からの安全な変換
    if dbModel.Title.Valid {
        metadata.Title = dbModel.Title.String
    }
    if dbModel.Description.Valid {
        metadata.Description = dbModel.Description.String
    }
    if dbModel.ImageURL.Valid {
        metadata.ImageURL = dbModel.ImageURL.String
    }
    if dbModel.SiteName.Valid {
        metadata.SiteName = dbModel.SiteName.String
    }
    if dbModel.PublishedAt.Valid {
        metadata.PublishedAt = &dbModel.PublishedAt.Time
    }
    if dbModel.ModifiedAt.Valid {
        metadata.ModifiedAt = &dbModel.ModifiedAt.Time
    }

    return metadata
}
```

### モデル変換のベストプラクティス

- **一貫性**: 同じエンティティ型の変換には常に同じ関数を使用する
- **null 値の処理**: `null.String`や`null.Time`などの型を使用して、nullable な値を適切に処理する
- **バリデーション**: 変換時に基本的なバリデーションを行う（必須フィールドの存在確認など）
- **エラー処理**: 変換中に問題が発生した場合は明示的にエラーを返す
- **再利用**: 複雑なエンティティでは、小さな変換関数を組み合わせて使用する

## トランザクション管理

### 基本方針と責任分担

- **管理主体**: トランザクションの開始、コミット、ロールバックは **ユースケース層** が責任を持つ。これにより、ビジネスロジックの単位でトランザクション境界を定義できる。
- **永続層の役割**: 永続層は、ユースケース層から渡されたトランザクションコンテキスト内でデータベース操作を実行する。永続層自体はトランザクションのライフサイクルを管理しない。
- **TxManager 経由が必須**: 本コードベースでは **全ての DB 操作が `TxManager` 経由のトランザクションコンテキスト内で実行されることが前提**である。非トランザクション経由で永続層を呼び出すと後述の通り `nil` executor で panic する。さらに TxManager は内部で **RLS パラメータ（`workspace_level_security.workspace_id` / `role`）を自動設定/リセット**するため、TxManager を経由しない DB 操作はマルチテナント分離が破綻する。これは単なる抽象化ではなくセキュリティ境界である。

### 実装パターン

1.  **ユースケース層での管理**: `TxManager` の `RunInWritingTransaction` / `RunInReadingTransaction` を使用する

    - 書き込みを伴う処理には `RunInWritingTransaction` を使う（エラー/panic 時は自動ロールバック、正常終了時は自動コミット）
    - 書き込みのない読み取り処理には `RunInReadingTransaction` を使う（読み取り専用トランザクションで、レプリカ利用と意図の明示になる）
    - コールバック関数に渡された `ctx` をそのまま永続層へ渡す（この `ctx` にトランザクションが紐付いている）

    ```go
    // ユースケース層でのトランザクション管理の例（書き込み）
    func (u *UserUseCase) CreateUserWithProfile(ctx context.Context, user *model.User, profile *model.UserProfile) (*model.User, error) {
        var savedUser *model.User
        err := u.txManager.RunInWritingTransaction(ctx, func(ctx context.Context) error {
            var err error
            savedUser, err = u.userRepository.Create(ctx, user)
            if err != nil {
                return err
            }
            profile.UserID = savedUser.ID
            if _, err = u.profileRepository.Create(ctx, profile); err != nil {
                return err
            }
            return nil
        })
        if err != nil {
            return nil, err
        }
        return savedUser, nil
    }
    ```

    参考実装: `internal/domain/repository/tx_manager.go`（インターフェース）、`internal/infra/db/tx/tx.go`（実装、RLS 設定含む）、`internal/usecase/convert_event_type_usecase.go` 他多数。

2.  **永続層でのコンテキスト利用**: `BasePersistence.GetExecutor(ctx)` を使用する

    - `GetExecutor` は ctx に紐付いたトランザクションを返す。**トランザクションがなければ `nil` を返す**（実装: `internal/infra/persistence/base_persistence.go:14-20`）
    - 返り値が `nil` のまま `boil` API に渡すと nil pointer dereference で実行時エラーとなる。永続層メソッドは必ず TxManager 経由で呼ぶこと
    - `BasePersistence` 構造体はフィールドを持たず、`GetExecutor` は純粋に ctx からトランザクションを取り出すだけのユーティリティである

    ```go
    // BasePersistence の実装（参考）
    func (*BasePersistence) GetExecutor(ctx context.Context) boil.ContextExecutor {
        tx := tx.GetFromContext(ctx)
        if tx != nil {
            return tx
        }
        return nil // ← ctx にトランザクションがなければ nil。nil のまま boil API に渡すと nil pointer dereference で失敗するので必ず TxManager 経由で呼ぶこと
    }

    // 永続層メソッド内での利用例
    func (p *EntityPersistence) Create(ctx context.Context, entity *model.Entity) (*model.Entity, error) {
        exec := p.GetExecutor(ctx) // TxManager 経由で呼ばれていればトランザクションが返る
        r := translateBoilerEntityModel(entity)
        if err := r.Insert(ctx, exec, boil.Infer()); err != nil {
            return nil, toRepoError(err)
        }
        return translateEntityModel(r), nil
    }
    ```

### 利点

- **データ整合性**: 複数のデータベース操作をアトミックに実行し、整合性を保証する
- **関心の分離**: ビジネスロジック（ユースケース層）とデータアクセス（永続層）の責任を明確に分離する
- **テスト容易性**: 永続層の単体テストではトランザクションを意識する必要がなく、ユースケース層のテストでトランザクションの挙動を確認できる
- **コード再利用性**: 永続層のメソッドはトランザクション管理から独立しているため、異なるユースケースで再利用しやすい
- **RLS の自動適用**: TxManager が workspace_id/role を自動設定するため、開発者がセッション変数を意識せずに RLS の恩恵を受けられる

### ベストプラクティス

- **読み書きの区別**: 書き込みがない処理は必ず `RunInReadingTransaction` を使う。不用意に `RunInWritingTransaction` を使うとレプリカを活用できず、マスターに負荷が集中する
- **トランザクションは短く**: ロック時間を最小限にするため、トランザクションのスコープは必要最小限に留める
- **外部呼び出しを避ける**: トランザクション内で時間のかかる処理（外部 API コール、重い計算など）を行わない
- **I/O 最小化**: トランザクション内のデータベース I/O 操作を最小限に抑える
- **アクセス順序の一貫性**: デッドロックのリスクを減らすため、複数のテーブルにアクセスする場合は常に同じ順序でアクセスする
- **分散トランザクションの回避**: 可能な限り単一データベース内のトランザクションで完結させ、複雑な分散トランザクションは避ける。必要であれば、Saga パターンなどの最終的整合性を検討する
- **TxManager を経由しない直接 DB アクセス禁止**: RLS が効かなくなり、マルチテナント分離が破綻する

## 永続層コードレビュー

永続層（`internal/infra/persistence/*.go`）のファイルを **作成・編集したら、その編集セッション内で必ず `.claude/skills/persistence-code-review/SKILL.md` スキルを起動してセルフレビューする**。型安全性、ベストプラクティス、不要コードの観点を体系的にチェックするためのチェックリストが定義されている。

### ルール

1. **永続層ファイルを編集したら、編集直後に `persistence-code-review` スキルを起動する**（PR レビュー時や commit 直前まで遅延させず、編集セッション内で即座に実行する）
2. スキルのチェックリストを順に埋めながら、本ドキュメント記載のルール（`SELECT *` 禁止・`models.XSelectAll` の JOIN 有無に応じた使い分け・SQLBoiler 定数使用・TxManager 経由必須など）も含めて検証する
3. 指摘事項があれば同じセッション内で修正し、修正後に再度スキルを実行して解消を確認する
4. PR レビュー時（自身・他者のコード問わず）にも同スキルを併用する

### 対象となる編集

- 新規永続層ファイルの作成
- 既存永続層ファイルの変更（クエリ追加、Bulk 系、トランザクション境界変更、カラム選択変更、ページネーションロジック変更など、種類・規模を問わない）
- 複数ファイルを続けて編集した場合は、一連の編集が一段落した時点でまとめて実行してよい（ただし編集セッションを跨がないこと）

永続層ファイルを編集したのにスキルを起動していない場合は本ルール違反とみなす。

## 永続層のテスト (`internal/infra/persistence/*_test.go`)

このセクションは、`internal/infra/persistence` ディレクトリ配下にある永続層のテストコードの書き方を説明する。

テストコードの基本的な規約（命名規則、アサーション、テスト構造など）は、`docs/testing_rules.md` を参照する。

### テストの目的

永続層のテストは、以下の目的で行う：

- データベースへの CRUD (Create, Read, Update, Delete) 操作が正しく行われることを確認する
- 特定の条件でのデータ取得 (クエリ) が期待通りに動作することを確認する
- ページネーションやソートなどの複雑なクエリロジックを検証する
- データベース制約 (ユニーク制約、外部キー制約など) が正しく機能することを確認する

### テストの構造

永続層のテストでは、可読性と独立性を重視し、**サブテスト (`t.Run`)** を主体として各テストケースを記述する。

```go
func TestUserRepository_Create(t *testing.T) {
    t.Parallel()

    repo := NewUserRepository()

    t.Run("正常系: ユーザーを正常に作成できる", func(t *testing.T) {
        t.Parallel()
        ctx, tx := test.StartTestDB(t, TestDatabaseName)

        // 1. テストデータの準備
        // ...

        // 2. テスト対象メソッドの実行
        // ...

        // 3. 結果の検証
        // ...
    })

    // ... 他のサブテスト
}
```

#### **1. テストごとの DB セットアップ**

各サブテスト (`t.Run`) の中で `test.StartTestDB(t, TestDatabaseName)` を呼び出し、テスト用のデータベース接続とトランザクション (`ctx`, `tx`) を取得する。これにより、各テストケースは独立した環境で実行され、テスト終了時にトランザクションがロールバックされるため、クリーンな状態が保たれる。

#### **2. テストデータの準備**

`github.com/volatiletech/sqlboiler/v4` で生成されたモデル (`models.*`) と `test/factory` パッケージを使用して、テストに必要なデータをデータベースに挿入する。詳細は `docs/testing_rules.md` の「テストデータ準備」セクションを参照する。

#### **3. 結果の検証**

メソッドの実行結果と期待値を比較し、データが正しくデータベースに保存・更新・削除されたかを確認する。
詳細なアサーション方法は `docs/testing_rules.md` の「アサーションと比較」セクションを参照する。
