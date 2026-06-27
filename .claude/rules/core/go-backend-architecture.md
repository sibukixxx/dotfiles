# Go バックエンドアーキテクチャ規約

`toscana/api` の構造を Go 製バックエンドサービスのリファレンスとして抽出したもの。
**このルールはアプリケーション（サーバー）に適用する。SDK / ライブラリには適用しない**
（適用範囲は末尾「適用スコープ」を参照）。

---

## 0. 適用スコープ

| 種別 | このルールを適用するか |
|------|----------------------|
| **API サーバー** （HTTP / GraphQL / gRPC） | ✅ 全面適用 |
| **非同期 worker / scheduler サービス** | ✅ 全面適用 |
| **CLI ツール (`cmd/<tool>`)** | ⚠️ DDD レイヤは省略可。命名・errors・config は適用 |
| **Go ライブラリ / SDK** （`go get` で他サービスから利用） | ❌ 全面適用しない。ルート package を公開 API、`internal/` を実装詳細、`adapters/` を変換層、とする小型構成を採る。詳細は「Go ライブラリのレイアウト」参照 |

判定は「`cmd/<server>/main.go` で http server / worker を起動するか？」を主基準にする。
起動するならバックエンドサービス。`go get` 用に export しているならライブラリ。

---

## 1. ディレクトリ構造（オニオンアーキテクチャ）

```
<repo>/
├── cmd/                          # エントリポイント（main 関数のみ）
│   └── <service>/main.go
├── internal/                     # アプリケーション本体
│   ├── domain/
│   │   ├── model/               # エンティティ・値オブジェクト
│   │   ├── repository/          # リポジトリ「インターフェース」のみ
│   │   ├── service/             # ドメインサービス
│   │   └── policy/              # ビジネスポリシー
│   ├── usecase/                 # アプリケーションロジック
│   ├── handler/                 # GraphQL リゾルバ / HTTP ハンドラ / job ハンドラ
│   ├── graph/                   # GraphQL リゾルバ・presenter・directive・dataloader
│   │   ├── presenter/          # domain → GraphQL 変換
│   │   ├── enum/
│   │   └── directive/
│   ├── infra/                   # 外部システムとの境界
│   │   ├── persistence/        # repository「実装」
│   │   ├── db/                 # コネクション / Tx 管理
│   │   ├── aws/, gcp/, firebase/
│   │   ├── http/               # 外部 API クライアント
│   │   ├── logger/, sentry/
│   │   └── ...
│   ├── models/                  # SQLBoiler 等のコード生成モデル
│   ├── server/                  # HTTP server / route / middleware
│   ├── worker/, scheduler/, listener/, ticker/   # 非同期処理
│   ├── config/                  # 設定読み込み（cleanenv + yaml）
│   ├── auth/, audit/, errors/, encrypt/, cursor/, dataloader/
├── graph/                       # GraphQL スキーマ (*.graphqls)
├── migrates/  または  migrations/  # SQL マイグレーション
├── test/
│   ├── factory/                 # テストデータ factory（functional options）
│   ├── e2e/
│   └── util/
├── docs/                        # 設計書 / ADR
├── deployment/                  # 環境別の config 上書き
├── go.mod, Makefile, gqlgen.yml, sqlboiler.toml, config.yml, Dockerfile
```

**禁止**:
- ルート直下に業務 `.go` を置かない（`main.go` も `cmd/<service>/` の中）
- `pkg/` を作らない（`internal/` で隠す。export が必要なら別リポジトリの SDK にする）

---

## 2. オニオン依存方向（最重要）

```
[handler / graph]  ──→  [usecase]  ──→  [domain]
                                          ↑
[infra / persistence / aws / ...] ─────────┘ （interface 実装）
```

絶対ルール：

1. **domain は何にも依存しない**（`internal/infra/*` を import 禁止）
2. **usecase は domain にのみ依存する**（`internal/handler/*`, `internal/infra/*` import 禁止）
3. **handler は usecase + domain 型に依存する**（infra 直接呼びは禁止）
4. **infra は domain interface を実装する**（usecase / handler を import 禁止）
5. interface は **domain 層に定義する**（infra に書かない）

検出方法（CI に入れる）：
```bash
# domain が infra を import していたら fail
go list -deps ./internal/domain/... | grep "internal/infra" && exit 1
```

---

## 3. 命名規則

### ファイル名

| レイヤ | パターン | 例 |
|--------|----------|----|
| domain repository（interface） | `<entity>_repository.go` | `internal/domain/repository/channel_user_repository.go` |
| usecase | `<verb>_<noun>_usecase.go` | `internal/usecase/create_faximo_receive_account_usecase.go` |
| handler | `<verb>_<noun>_handler.go` | `internal/handler/delete_calendar_resource_handler.go` |
| persistence（実装） | `<entity>_persistence.go` / `_command.go` / `_query.go` | `internal/infra/persistence/workspace_user_group_persistence_command.go` |
| GraphQL resolver | `<noun>.resolvers.go` （gqlgen 生成） | `internal/graph/workspace_user.resolvers.go` |
| presenter | `<noun>_presenter.go` | `internal/graph/presenter/workspace_user_presenter.go` |
| test | `<file>_test.go` （同パッケージ同居） | `internal/handler/sync_external_ics_handler_test.go` |
| mock | `mocks/mock_<file>.go` （MockGen 出力） | `internal/handler/mocks/mock_create_workspace_user_handler.go` |

### パッケージ名

- 単数形・小文字・短く。`repository` / `usecase` / `handler` / `persistence` / `presenter` で揃える
- 1 ファイル＝1 type 1 constructor を基本とする（共通定義は `module.go` か `base.go`）

### 型名

- interface: そのまま責務名（`ChannelUserRepository`）
- 実装: 末尾を実装場所で区別（`ChannelUserPersistence` / `ChannelUserService`）
- usecase / handler: 型名 = ファイル名 PascalCase（`CreateFaximoReceiveAccountUsecase`）

---

## 4. DI（Uber Fx）

各レイヤに `module.go` を置き、`fx.Provide(constructor...)` でまとめる。

```go
// internal/handler/module.go
var Module = fx.Module("handler",
    fx.Provide(
        NewCreateWorkspaceUserHandler,
        NewArchiveChannelHandler,
        // ...
    ),
)

// cmd/<service>/main.go
fx.New(
    config.Module,
    infra.Module,
    domain.Module,
    usecase.Module,
    handler.Module,
    server.Module,
).Run()
```

ルール：
- **コンストラクタは interface を受け取り interface を返す**（具象返しは worker/server の lifecycle のみ）
- **`init()` 関数で副作用を持たせない**（テスト不能になる）
- **シングルトンは fx に任せる**（手動 `var instance` は禁止）

---

## 5. エラーハンドリング

### 標準ライブラリ

`internal/errors` パッケージで cockroachdb/errors をラップした共通関数を提供。

```go
// 必ずこれを使う
errors.New("...")
errors.Newf("... %d", x)
errors.Wrap(err, "...")
errors.Wrapf(err, "... %d", x)
```

ルール：
- 標準 `errors.New` / `fmt.Errorf("...: %w", err)` を直接使わない（スタック取得不可）
- スタックは自動付与。**多重ラップしてもスタック重複しない**実装になっていることを前提とする
- domain / usecase 層では sentinel error を `internal/domain/repository/error.go` 等に定義

### GraphQL エラーマッピング

Apollo 規約：
- `UNAUTHENTICATED` / `FORBIDDEN` / `BAD_USER_INPUT` / `NOT_FOUND` / `INTERNAL_SERVER_ERROR`
- handler では sentinel error を返し、resolver / middleware で GraphQL extension に変換

---

## 6. データベース・永続化

### SQLBoiler パターン

```go
// internal/infra/persistence/<entity>_persistence_command.go
func (p *XxxPersistence) Create(ctx context.Context, m *model.Xxx) (*model.Xxx, error) {
    exec := p.GetExecutor(ctx)              // Tx 取得（Tx なければ DB）
    r := translateToBoilerModel(m)          // domain → SQLBoiler
    if err := r.Insert(ctx, exec, boil.Infer()); err != nil {
        return nil, toRepoError(err)
    }
    return translateFromBoilerModel(r), nil
}
```

- **Query / Command 分離**：`*_persistence_query.go` / `*_persistence_command.go`
- **Executor 抽象化**：`BasePersistence.GetExecutor(ctx)` で Tx か DB を返す
- **domain ↔ boiler 変換**：persistence 内の `translate*` 関数で完結。domain に boiler 型を漏らさない
- **生成コードは絶対に手で編集しない**（`internal/models/` / `internal/graph/generated.go` 等）

### マイグレーション

`migrates/` （または `migrations/`）配下、`YYYYMMDDHHMMSS_<snake_description>.sql` 形式。
詳細は `rules/core/database-migration.md` を参照。

---

## 7. GraphQL（gqlgen）

```
graph/*.graphqls          ← スキーマ（手書き）
internal/graph/
  generated.go            ← 生成（編集禁止）
  *.resolvers.go          ← 生成 + 手で実装本体を書く
  presenter/              ← domain → GraphQL DTO
  enum/, directive/, utils/, model/
```

ルール：
- **resolver は薄く**：handler を呼んで結果を presenter に渡すだけ
- **presenter で domain 型を GraphQL DTO に変換**（domain leak 防止）
- **DataLoader を必ず使う**（N+1 防止）
- **認証はディレクティブで宣言**（`@hasAuthn` 等）

---

## 8. ロギング・観測

- `log/slog` 構造化ログ。フォーマットは config で json/text 切替
- リクエスト単位で `request_id` を context に注入
- `internal/infra/sentry/` でエラートラッキング
- LLM / ツール呼び出しがある場合は `rules/core/ai-agent-o11y.md` に従いトレース

ログに**出してはいけないもの**：
- 秘密情報（AppID / API key / token / password）
- 個人情報（メール本文 / 電話 / 住所 / マイナンバー）
- 大きなクエリ文字列・URL（メタデータのみ）

---

## 9. テスト

- **同一パッケージ同居**：`xxx.go` と `xxx_test.go` を並べる
- **モック**：`mockgen -source=file.go -destination=mocks/mock_file.go -typed=true`
- **ファクトリ**：`test/factory/<entity>.go` に functional options で
  ```go
  func NewAnnouncement(opts ...AnnouncementOpt) *Announcement { ... }
  func WithAnnouncementID(id string) AnnouncementOpt { ... }
  ```
- **e2e**：`test/e2e/` 配下、build tag `e2e`、実 DB / 実 API 接続前提
- **テスト名**：t-wada 流。`Test<Receiver><Method>Should<Result>When<Condition>` を推奨
- 詳細は `rules/core/tdd.md`、`rules/core/testing.md` を参照

---

## 10. 設定（config）

- `internal/config/config.go` に root struct、セクションごとに `internal/config/<section>.go`
- cleanenv + yaml。env var は `<APPNAME>_<SECTION>_<FIELD>` で大文字スネーク
- `config.yml` を repo に置きデフォルト・dev 値を持つ。秘密値は env で上書き
- 環境別差分は `deployment/<env>/` 配下で管理

---

## 11. Go ライブラリのレイアウト（参考・例外）

`go get` 用 SDK は本ルールを適用しない代わりに、以下の小型構成を採る。

```
<repo>/
├── *.go                    # ルート package = 公開 API
│                           #   client.go / config.go / errors.go / mock.go ...
├── internal/<subsystem>/   # 実装詳細（外部から見えない）
├── adapters/<usecase>/     # 業務 DTO 変換層（純粋関数）
├── examples/<scenario>/    # 動作するサンプル
├── test/e2e/               # 実 API テスト（build tag）
├── testdata/               # ゴールデンファイル
├── scripts/seed/           # testdata 取得スクリプト
├── Makefile / .golangci.yml / .github/workflows/
```

ライブラリにも適用するルール：
- **internal/ で実装詳細を隠す**
- **エラーは構造化（`*XxxError` + `errors.As` 対応）**
- **設定は struct で受け取る**（`Config` 構造体 + `Validate()` + `WithDefaults()`）
- **mock は同梱可**（`MockClient` の関数フィールドパターン）
- **adapters は純粋関数**（I/O・mutation 禁止）
- **table-driven test + golden file**

ライブラリには適用しないルール：
- DDD オニオンレイヤ（domain/usecase/handler/infra）
- fx DI（小規模なので不要）
- gqlgen / sqlboiler / migrations / RLS
- worker / scheduler / listener / ticker

---

## 12. PR レビュー時のチェックリスト

- [ ] domain が infra / handler を import していないか
- [ ] usecase が infra を直接呼んでいないか（interface 経由か）
- [ ] interface は domain 層に置かれているか
- [ ] ファイル名が命名規則に従っているか
- [ ] エラーが `internal/errors` 経由か（`fmt.Errorf("%w", ...)` を直接使っていないか）
- [ ] persistence で domain ↔ boiler の変換が完結しているか
- [ ] resolver / handler に DB アクセス・外部 API 呼び出しが直書きされていないか
- [ ] `init()` で副作用を持たせていないか
- [ ] 生成コード（`generated.go` 等）を手で編集していないか
- [ ] `*_test.go` が同パッケージにあるか、mock は `mocks/` か
- [ ] migration が `database-migration.md` のルールに従っているか
- [ ] ログに秘密情報・PII を出していないか
