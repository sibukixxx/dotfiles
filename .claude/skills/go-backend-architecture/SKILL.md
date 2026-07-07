---
name: go-backend-architecture
description: Go バックエンドサービス（HTTP/GraphQL/gRPC API、worker、scheduler）のオニオンアーキテクチャ準拠を検証・scaffold するスキル。toscana/api 構造をリファレンスとし、命名・レイヤ依存・DI・errors・persistence・GraphQL・テスト構造を一括で確認する。Go ライブラリ/SDK には適用しない。「バックエンドの構造を確認して」「オニオンアーキテクチャに従っているか検証」「Go プロジェクト scaffold」「ディレクトリ構造をリファクタ」などで発動。
---

# Go Backend Architecture

## 目的

`toscana/api` を基準とした Go バックエンドサービスのオニオンアーキテクチャ規約に
従っているかを検証し、違反があればリファクタする。

参照ルール: `skills/go-backend-architecture/references/rules.md`

## このスキルを使うタイミング

- 新規 Go バックエンドサービスをスキャフォールドする
- 既存 Go プロジェクトの構造をオニオンアーキテクチャに合わせて検証
- レイヤ違反（domain → infra 依存等）の発見・修正
- 命名規則の統一・リファクタリング

## このスキルを使わないとき

- **Go ライブラリ / SDK** （`go get` で他サービスから利用される `*.go` 公開パッケージ）
  → 規約は適用しない。`skills/go-backend-architecture/references/rules.md` の「Go ライブラリのレイアウト」を参照
- フロントエンド / 非 Go プロジェクト

## 実行手順

### Phase 0: 適用判定

最初に必ず判定する。

```
1. cmd/<service>/main.go が存在し、http server / worker を起動するか？
   YES → バックエンドサービス（このスキル適用）
   NO  → 次へ
2. ルートディレクトリに公開用の *.go ファイルがあり、go.mod が
   github.com/<user>/<libname> のような import path を export しているか？
   YES → ライブラリ（このスキルを適用しない。ユーザーに確認の上で停止）
   NO  → CLI ツール等。命名・errors のみ適用、レイヤは省略可
```

判定結果をユーザーに伝えてから Phase 1 に進む。

### Phase 1: 構造調査（並列）

以下を `Explore` agent で並列実行：

```
Task A: ディレクトリレイアウト調査
  - cmd/, internal/, graph/, migrates/, test/ の有無
  - internal/ 配下の domain/usecase/handler/infra/graph/server の有無
  - 各レイヤのファイル数・命名パターンサンプル

Task B: レイヤ依存違反の検出
  - go list -deps ./internal/domain/... | grep "internal/infra"
  - go list -deps ./internal/usecase/... | grep "internal/handler\|internal/infra"
  - go list -deps ./internal/handler/... | grep "internal/infra/persistence"
  - 違反ファイルパスを列挙

Task C: 命名規則違反の検出
  - usecase: *_usecase.go 以外のビジネス処理ファイル
  - handler: *_handler.go 以外
  - persistence: *_persistence.go / _command.go / _query.go 以外
  - repository interface が internal/domain/repository/ 以外に定義されていないか
  - test ファイルが同パッケージに同居しているか

Task D: エラーハンドリング検証
  - fmt.Errorf("...: %w", ...) の出現箇所（internal/errors を使うべき）
  - errors.New / errors.Newf / errors.Wrap が internal/errors 経由か

Task E: 設定・DI・観測
  - internal/config/config.go の有無、cleanenv 利用か
  - fx.Module / fx.Provide が各レイヤにあるか
  - log/slog 構造化ログを使っているか
  - sentry / tracing の組み込み
```

**5 つの Task を 1 メッセージで並列起動する。**

### Phase 2: 違反レポート作成

各違反を以下の形式で列挙：

```
## 違反 N: <種別>
- 該当ファイル: <path:line>
- 違反内容: <一行>
- 修正方針: <一行>
- 重要度: critical / high / medium / low
```

重要度の基準：
- **critical**: domain → infra の循環依存、生成コードの手編集
- **high**: usecase → handler/infra の直接依存、レイヤ越境
- **medium**: 命名規則違反、internal/errors 不使用
- **low**: ファイル配置の好み、コメント欠落

### Phase 3: ユーザー確認

critical / high の違反を **必ずユーザーに見せて承認を取る**。
medium / low は auto mode 中は自動修正可。

```
Phase 1-2 の結果を以下にまとめます：
- critical: N 件
- high:     N 件
- medium:   N 件
- low:      N 件

critical/high の修正方針（差分プレビュー）を出します。
これで進めて良いですか？ それとも修正方針を変更しますか？
```

### Phase 4: リファクタリング

承認後、以下の順で修正する：

1. **import パスの整理**（依存違反を解消するためのファイル移動）
2. **interface の domain 層への移設**
3. **ファイル名のリネーム**
4. **errors パッケージへの移行**
5. **テストファイルの再配置**
6. **ビルド・テスト確認** （`make build && make test` または `go build ./... && go test ./...`）

破壊的な移動が必要な場合は **小さなコミット単位**で進める：
- `[STRUCTURAL] refactor: ...` で動作変更なしの構造変更を分離
- `[BEHAVIORAL] fix: ...` で挙動変更を含むものを分離

### Phase 5: 検証ループ

```
go build ./...
go vet ./...
go test ./...
make lint  （存在すれば）
```

すべて緑にしてから完了報告。

## 例: 違反パターン一覧

### Critical: domain が infra に依存

```go
// ❌ internal/domain/model/user.go
import "myapp/internal/infra/persistence"   // 絶対 NG
```

→ infra の型を domain で扱わない。必要なら domain 側に値オブジェクトを定義し、
  persistence で変換する。

### Critical: 生成コードの手編集

```go
// ❌ internal/graph/generated.go の手編集
// ❌ internal/models/users.go の手編集（SQLBoiler 出力）
```

→ スキーマ・SQL を変更し、再生成する。

### High: usecase からの直 DB アクセス

```go
// ❌ internal/usecase/create_user_usecase.go
import "github.com/aarondl/sqlboiler/v4/boil"   // NG
```

→ repository interface 経由に変更。

### High: handler が infra/persistence を直呼び

```go
// ❌ internal/handler/create_user_handler.go
import "myapp/internal/infra/persistence"   // NG
```

→ usecase を経由する。

### Medium: 命名規則違反

```
internal/usecase/user.go            ❌
internal/usecase/create_user.go     ❌
internal/usecase/create_user_usecase.go   ✅
```

### Medium: 標準 fmt.Errorf 使用

```go
// ❌
return fmt.Errorf("failed: %w", err)

// ✅
return errors.Wrap(err, "failed")
```

## 報告フォーマット

最終的に以下を返す：

```
## 検証結果

- 適用判定: <バックエンド / ライブラリ / CLI>
- 適用ルール: skills/go-backend-architecture/references/rules.md
- 違反件数: critical=N high=N medium=N low=N

## 修正内容（実施した場合）

1. <修正 1 行サマリ> （[STRUCTURAL]/[BEHAVIORAL]）
2. ...

## 残課題

- <次回以降に持ち越す事項>
```

## 関連スキル・ルール

- `skills/go-backend-architecture/references/rules.md` - 本スキルが参照する規約
- `skills/database-migration/references/rules.md` - migration の運用ルール
- `skills/tdd-architect/references/rules.md`, `skills/tdd-architect/references/testing-rules.md` - テスト規約
- `skills/ai-agent-o11y/references/rules.md` - AI エージェント計装
- `skills/persistence-code-review/SKILL.md` - 永続層の細かいレビュー
- `skills/migration-review/SKILL.md` - migration ファイル単体レビュー
