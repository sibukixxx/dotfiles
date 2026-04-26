# CLAUDE.md - Global Project Guidelines

## z-ai/ directory

- `z-ai/` is globally gitignored.
- This directory is used for local AI documents such as plans and progress
  tracking.
- Do NOT ask whether `z-ai/` is gitignored — it always is.

## Testing Philosophy (t-wada Style)

このプロジェクトでは、和田卓人（t-wada）氏のテスト駆動開発の哲学に基づいてテストを行う。

### TDD サイクル (Red → Green → Refactor)

1. **Red**: まず失敗するテストを書く
2. **Green**: テストを通す最小限のコードを書く
3. **Refactor**: コードを整理する（テストは常に Green を維持）

### テストの原則

- **テストファースト**: 実装コードを書く前にテストを書く
- **小さなステップ**: 一度に一つのことだけをテストする
- **テストコードも本番コード**: テストコードの品質も本番コードと同様に重要
- **独立性**: 各テストは他のテストに依存しない
- **再現性**: 何度実行しても同じ結果になる
- **高速**: テストは素早く実行できる

### テスト構造 (Arrange-Act-Assert / Given-When-Then)

```
// Arrange (Given) - 準備
const calculator = new Calculator();

// Act (When) - 実行
const result = calculator.add(1, 2);

// Assert (Then) - 検証
expect(result).toBe(3);
```

### テスト名の命名規則

テスト名は「何をテストしているか」を明確に表現する：
- `it('should return sum of two numbers')`
- `it('throws error when input is negative')`
- `describe('Calculator#add')` でグループ化

### テストダブルの使い方

- **本物を使えるなら本物を使う**
- 外部依存（DB、API、ファイルシステム）のみモック化
- モックは最小限に、振る舞いの検証は慎重に

### テストピラミッド

```
      /\
     /  \     E2E テスト（少）
    /----\
   /      \   統合テスト（中）
  /--------\
 /          \ ユニットテスト（多）
/------------\
```

### 避けるべきアンチパターン

- テストのないコードをコミットしない
- 複数のことを一つのテストで検証しない
- テストの実行順序に依存しない
- 本番コードにテスト用のロジックを入れない
- 実装の詳細をテストしない（振る舞いをテストする）

### リファクタリング時の注意

- リファクタリング中はテストを変更しない
- テストが Green のままであることを常に確認
- 小さなステップで進める

## AI Agent Observability (o11y First)

AIエージェントを開発する際は、**トレーシングを最初に組み込む**。

> トレースデータさえあれば細かい調整はコーディングエージェントに投げるだけ。
> トレースがなければ改善のしようがない。

- LLM呼び出し・ツール呼び出し・サブエージェントの3層を必ずトレース
- 詳細は `rules/core/ai-agent-o11y.md` を参照
- セットアップは `/ai-agent-o11y` スキルで実行

## Code Quality

- コードを書く際は、まずテストを考える
- 「このコードはどうテストするか？」を常に意識する
- テストしにくいコードは設計を見直すサイン

## Claude Code 運用ルール (Opus 4.7+)

Opus 4.7 で挙動・推奨が変わったため、運用面で守るべきこと：

- **Scaffolding ではなく context を渡す** — 過剰な逐次指示は逆効果。目的・制約・受入条件を明確にして委譲
- **Effort Level は xhigh（既定）で十分** — `max` は本当に難しい問題のみ（過思考の主因）
- **`--dangerously-skip-permissions` は隔離環境のみ** — 通常は **auto mode** を使う
- **長時間セッションは作業の重要度で監視レベルを変える** — 本番影響ありは各ステップで承認
- **Subagent を反射で呼ばない** — multi-agent は 4-7x のトークン消費。1 レスポンスで済むなら呼ばない
- **Trust but verify** — agent の summary は意図、実際の差分・テスト・実機で検証する

詳細は `rules/core/claude-code-usage.md` を参照。

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
