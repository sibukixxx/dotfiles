# ビルド/テストコマンドの判定と Worktree 規約

## Build / Test Command Detection

プロジェクトルートのファイルからビルド・テスト・リントコマンドを自動判定する。

| Detection File | Build | Test | Lint | Format |
|----------------|-------|------|------|--------|
| `Makefile` | `make build` | `make test` | `make lint` | `make fmt` |
| `package.json` | `pnpm build` | `pnpm test` | `pnpm lint` | `pnpm format` |
| `Cargo.toml` | `cargo build` | `cargo test` | `cargo clippy` | `cargo fmt` |
| `go.mod` | `go build ./...` | `go test ./...` | `go vet ./...` | `gofmt -w .` |
| `*.xcodeproj` | `xcodebuild build` | `xcodebuild test` | `swiftlint` | `swift-format -r -i .` |
| `pyproject.toml` | - | `pytest` | `ruff check .` | `ruff format .` |
| `Gemfile` | `bundle exec rake build` | `bundle exec rake test` | `rubocop` | `rubocop -A` |

**優先順位**: `Makefile` > 各言語固有ファイル（Makefileがあればmakeを優先）

**pnpm優先**: Node.jsプロジェクトではnpm/yarnではなくpnpmを使用する。

## Worktree Conventions

### ブランチ命名

`<type>/<kebab-case-description>`

例: `feat/user-auth`, `fix/login-redirect`, `refactor/api-client`

### Worktree配置

メインリポジトリの兄弟ディレクトリに配置：

```
../<repo-name>-wt-<branch-name>/
```

例: `../my-app-wt-feat-user-auth/`

### マージ順序

1. 依存関係のないworktreeから順にマージ
2. マージ後はworktreeを削除（`git worktree remove`）
3. マージ前にメインブランチをpull

### Worktree内の.claude/設定

worktree作成時に `.claude/` ディレクトリは自動共有される（gitで管理されているため）。
