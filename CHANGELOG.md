# Changelog

このファイルは dotfiles リポジトリの主要な変更を記録しています。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいています。

---

## [Unreleased]

### 予定

- pre-commit hooks の追加
- dotfiles バックアップ機能

---

## [2025-01-22] - ドキュメント強化 & CI/CD 追加

### Added

#### CI/CD パイプライン
- `.github/workflows/ci.yml` - GitHub Actions ワークフロー
  - ShellCheck: シェルスクリプトの静的解析
  - chezmoi-verify: テンプレート構文チェック
  - yaml-lint: YAML ファイルのリント
  - toml-check: TOML ファイルの構文チェック
  - markdown-lint: Markdown ファイルのリント
  - validate-brewfile: Brewfile の Ruby 構文チェック（macOS）

#### ドキュメント
- `docs/TROUBLESHOOTING.md` - 包括的なトラブルシューティングガイド
  - 診断コマンド集
  - chezmoi 関連の問題と解決策
  - シェル・プラグイン関連の問題
  - ターミナル関連の問題
  - Git・GitHub 関連の問題
  - パッケージ管理の問題
  - SSH・暗号化関連の問題
  - パフォーマンス問題
  - プラットフォーム固有の問題（macOS, Linux, WSL）

#### 設定ファイル
- `.shellcheckrc` - ShellCheck の設定（無視するルール定義）
- `.claude/rules/` - Claude Code ルールをバージョン管理に追加
  - `core/` - コアルール（commit, TDD, testing, design）
  - `backend/go/` - Go 言語ルール
  - `backend/rust/` - Rust 言語ルール

### Changed

#### README.md（大幅刷新）
- バッジ追加（macOS, Linux, WSL, chezmoi, MIT）
- 目次追加
- 設計思想セクション追加
  - なぜ chezmoi を選んだか
  - ツール選定基準
  - ディレクトリ哲学
- ツール説明にリンクと選定理由を追加
- 前提条件表を追加
- Makefile コマンド表に使用場面を追加
- キーバインドをコンパクトな表形式に変更
- 貢献セクション追加

#### docs/ARCHITECTURE.md（大幅拡充）
- システム構成図追加
- 詳細セットアップフロー図（7フェーズ）
- データフローパイプライン図
- 状態管理の解説
- ツール比較表（chezmoi vs stow vs yadm vs bare git）
- ツール選定フローチャート
- chezmoi 命名規則の詳細表
- スクリプト実行順序図
- テンプレートシステムの解説
- age 暗号化フロー図
- キー管理の解説
- 依存関係グラフ

#### Makefile（機能拡張）
- ヘルプをカテゴリ別に整理
- 品質チェックコマンド追加
  - `make lint` - 全てのリントを実行
  - `make lint-shell` - shellcheck
  - `make lint-yaml` - yamllint
  - `make lint-toml` - taplo
- `make clean` - キャッシュクリア

#### .chezmoiignore
- `.github/` を除外対象に追加
- `.shellcheckrc` を除外対象に追加
- `Makefile` を除外対象に追加

#### .gitignore
- `.claude/rules/` を追跡対象に変更

#### .claude/rules/core/commit.md
- Claude Code リンクを `https://claude.ai/code` に更新

### Commits

```
22a3945 🔧 chore: add CI/CD pipeline with GitHub Actions
56e9e8c 📝 docs: enhance documentation with comprehensive guides
ccc817e 🔧 chore: add Claude Code rules to version control
54cd98f 📝 docs: add Makefile and ARCHITECTURE.md for better onboarding
```

---

## [2025-01-20] - Brewfile 修正

### Fixed

- 非推奨の Homebrew taps を削除
- zsh プロンプトの修正
- `brew bundle` の無効なフラグを削除
- 存在しない kindle cask を Mac App Store 経由に変更

### Commits

```
45346d4 fix: remove deprecated Homebrew taps and fix zsh prompt
a8f70ba fix: remove invalid --no-lock flag from brew bundle
564e98f fix: remove non-existent kindle cask, use Mac App Store instead
```

---

## [2025-01-01] - 初期セットアップ改善

### Changed

- 新規 macOS セットアップ時のスクリプトの信頼性向上
- ブートストラップ手順のドキュメント改善

### Added

- Brewfile にアプリケーションを追加（自動セットアップ用）

### Commits

```
77a11c5 fix: improve run scripts reliability for fresh macOS setup
5e6ce33 docs: clarify bootstrap steps for fresh macOS
5daa153 feat: add applications to Brewfile for automated setup
```

---

## 構成概要

現在の dotfiles リポジトリの構成:

```
dotfiles/
├── .chezmoi.toml.tmpl      # chezmoi 設定テンプレート
├── .chezmoiignore          # chezmoi 無視ファイル
├── .gitignore              # Git 無視ファイル
├── .shellcheckrc           # ShellCheck 設定
├── Makefile                # セットアップ・リントコマンド
├── Brewfile                # Homebrew パッケージ（macOS）
├── CHANGELOG.md            # このファイル
├── README.md               # プロジェクト概要
│
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions CI
│
├── .claude/
│   ├── settings.local.json
│   └── rules/              # Claude Code ルール
│       ├── core/
│       └── backend/
│
├── docs/
│   ├── ARCHITECTURE.md     # アーキテクチャ解説
│   ├── TROUBLESHOOTING.md  # トラブルシューティング
│   ├── new-pc-setup.md     # 新規 PC セットアップ
│   └── zellij.md           # Zellij ガイド
│
├── dot_zshrc               # ~/.zshrc
├── dot_config/             # ~/.config/
├── dot_local/bin/          # ~/.local/bin/
├── nix/                    # Linux/WSL 用 Home Manager
│
└── run_*                   # chezmoi スクリプト
```

---

## Make コマンド一覧

| コマンド | 説明 |
|----------|------|
| `make bootstrap` | 初回セットアップ |
| `make update` | dotfiles 更新 |
| `make verify` | セットアップ検証 |
| `make packages` | パッケージ同期 |
| `make edit` | 設定編集 |
| `make diff` | 差分確認 |
| `make lint` | 全リント実行 |
| `make lint-shell` | ShellCheck |
| `make lint-yaml` | YAML リント |
| `make lint-toml` | TOML チェック |
| `make clean` | キャッシュクリア |
| `make help` | ヘルプ表示 |

---

## ドキュメント一覧

| ドキュメント | 説明 |
|-------------|------|
| [README.md](README.md) | プロジェクト概要、クイックスタート |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | アーキテクチャ、設計思想、フロー図 |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | よくある問題と解決策 |
| [docs/new-pc-setup.md](docs/new-pc-setup.md) | 新規 PC セットアップ詳細ガイド |
| [docs/zellij.md](docs/zellij.md) | Zellij 使い方ガイド |

---

## CI/CD

GitHub Actions で以下のチェックが自動実行されます:

- **ShellCheck**: シェルスクリプトの静的解析
- **chezmoi-verify**: テンプレート構文チェック
- **yaml-lint**: YAML ファイルのリント
- **toml-check**: TOML ファイルの構文チェック
- **markdown-lint**: Markdown ファイルのリント
- **validate-brewfile**: Brewfile の構文チェック（macOS）

トリガー:
- `master` / `main` ブランチへの push
- Pull Request
