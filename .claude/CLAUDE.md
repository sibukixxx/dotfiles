# CLAUDE.md - Global

毎ターン読まれる憲法。詳細知識は skill / agent に逃がす。ここは「全プロジェクト共通で、毎回必要なもの」だけ。

## z-ai/
- 常に gitignored。質問しない。プラン・進捗用。

## Build / Test 自動検出
優先順: Makefile > 各言語固有ファイル。Node.js は pnpm 必須（npm/yarn 不可）。

| Detection | Build | Test | Lint | Format |
|---|---|---|---|---|
| Makefile | `make build` | `make test` | `make lint` | `make fmt` |
| package.json | `pnpm build` | `pnpm test` | `pnpm lint` | `pnpm format` |
| Cargo.toml | `cargo build` | `cargo test` | `cargo clippy` | `cargo fmt` |
| go.mod | `go build ./...` | `go test ./...` | `go vet ./...` | `gofmt -w .` |
| *.xcodeproj | `xcodebuild build` | `xcodebuild test` | `swiftlint` | `swift-format -r -i .` |
| pyproject.toml | - | `pytest` | `ruff check .` | `ruff format .` |
| Gemfile | `bundle exec rake build` | `bundle exec rake test` | `rubocop` | `rubocop -A` |

## 必ず守る一行ルール（詳細は skill / agent に委譲）

- **TDD**: テストファースト、Red→Green→Refactor。詳細は `/tdd`, `/impl` skill。
- **Go バックエンド**: handler→usecase→domain ←(impl)← infra のオニオン依存。interface は domain に置く。`internal/errors` 使用、`fmt.Errorf("%w")` 不可。詳細は `/go-backend-architecture` skill。
- **DB マイグレーション**: 手動 ALTER 禁止、Git 管理、forward-only、本番直 SQL 禁止。詳細は `/database-migration` skill。
- **AI エージェント**: トレース（LLM/Tool/SubAgent 3層）を最初に組み込む。詳細は `/ai-agent-o11y` skill。
- **セキュリティ**: 秘密はコミットしない、env 経由。詳細は `security-reviewer` agent / `/security-review`。
- **コミット**: Conventional Commit、subject/body は日本語、絵文字なし、Co-Authored-By なし。詳細は `commit-pusher` / `shipper` agent。

## Worktree
- ブランチ: `<type>/<kebab-case>`（例: `feat/user-auth`）
- 配置: `../<repo>-wt-<branch>/`
- マージ後 `git worktree remove`、forward マージ
- 詳細は `/worktree` skill

## Claude Code 運用（Opus 4.7+）
- effort level は既定 `xhigh` で十分。`max` は本当に難しい時のみ
- subagent を反射で呼ばない（multi-agent は 4-7x トークン）
- agent の summary は意図。差分・テスト・実機で verify
- `--dangerously-skip-permissions` は隔離環境のみ。通常は auto mode
