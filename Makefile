.PHONY: all bootstrap update verify packages edit diff lint lint-shell lint-yaml lint-toml clean help

# OS検出
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
  OS := macos
else ifeq ($(shell grep -q Microsoft /proc/version 2>/dev/null && echo wsl),wsl)
  OS := wsl
else
  OS := linux
endif

# デフォルトターゲット
.DEFAULT_GOAL := help

help:
	@echo "dotfiles - 開発環境セットアップ"
	@echo ""
	@echo "セットアップ:"
	@echo "  make bootstrap  - 初回セットアップ (chezmoi init + apply)"
	@echo "  make update     - dotfiles更新 (chezmoi update)"
	@echo "  make verify     - セットアップ検証"
	@echo "  make packages   - パッケージ同期 (brew bundle / home-manager)"
	@echo ""
	@echo "編集:"
	@echo "  make edit       - 設定編集 (chezmoi edit)"
	@echo "  make diff       - 適用前の差分確認 (chezmoi diff)"
	@echo ""
	@echo "品質チェック:"
	@echo "  make lint       - 全てのリントを実行"
	@echo "  make lint-shell - シェルスクリプトのリント (shellcheck)"
	@echo "  make lint-yaml  - YAMLファイルのリント"
	@echo "  make lint-toml  - TOMLファイルのチェック"
	@echo ""
	@echo "その他:"
	@echo "  make clean      - キャッシュをクリア"
	@echo ""
	@echo "検出されたOS: $(OS)"

# =============================================================================
# セットアップコマンド
# =============================================================================

bootstrap:
	@echo "==> Bootstrapping dotfiles..."
	@if command -v chezmoi >/dev/null 2>&1; then \
		chezmoi init --apply; \
	else \
		echo "chezmoi が見つかりません。インストールしてください:"; \
		echo "  macOS: brew install chezmoi"; \
		echo "  Linux: sh -c \"\$$(curl -fsLS get.chezmoi.io)\""; \
		exit 1; \
	fi

update:
	@echo "==> Updating dotfiles..."
	chezmoi update

verify:
	@echo "==> Verifying setup..."
	@if [ -x "$(HOME)/.local/bin/verify-setup" ]; then \
		$(HOME)/.local/bin/verify-setup; \
	else \
		echo "verify-setup スクリプトが見つかりません"; \
		echo "先に 'make bootstrap' を実行してください"; \
		exit 1; \
	fi

packages:
	@echo "==> Syncing packages..."
ifeq ($(OS),macos)
	@if [ -f "$(CURDIR)/Brewfile" ]; then \
		brew bundle --file=$(CURDIR)/Brewfile; \
	else \
		echo "Brewfile が見つかりません"; \
		exit 1; \
	fi
else
	@if command -v home-manager >/dev/null 2>&1; then \
		home-manager switch; \
	else \
		echo "home-manager が見つかりません"; \
		echo "Nix + Home Manager をインストールしてください"; \
		exit 1; \
	fi
endif

# =============================================================================
# 編集コマンド
# =============================================================================

edit:
	@echo "==> Opening chezmoi source directory..."
	chezmoi edit

diff:
	@echo "==> Showing pending changes..."
	chezmoi diff

# =============================================================================
# 品質チェック
# =============================================================================

lint: lint-shell lint-yaml lint-toml
	@echo "==> All lint checks completed"

lint-shell:
	@echo "==> Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -o -name "*.sh.tmpl" 2>/dev/null | \
		grep -v ".git" | \
		xargs -I {} shellcheck {} 2>/dev/null || true; \
		echo "Shellcheck completed"; \
	else \
		echo "shellcheck が見つかりません。インストールしてください:"; \
		echo "  macOS: brew install shellcheck"; \
		echo "  Linux: apt install shellcheck"; \
	fi

lint-yaml:
	@echo "==> Checking YAML files..."
	@if command -v yamllint >/dev/null 2>&1; then \
		find . -name "*.yml" -o -name "*.yaml" 2>/dev/null | \
		grep -v ".git" | \
		xargs -I {} yamllint -d "{extends: relaxed, rules: {line-length: disable}}" {} 2>/dev/null || true; \
		echo "YAML lint completed"; \
	else \
		echo "yamllint が見つかりません (スキップ)"; \
	fi

lint-toml:
	@echo "==> Checking TOML files..."
	@if command -v taplo >/dev/null 2>&1; then \
		find . -name "*.toml" 2>/dev/null | \
		grep -v ".git" | \
		xargs -I {} taplo check {} 2>/dev/null || true; \
		echo "TOML check completed"; \
	else \
		echo "taplo が見つかりません (スキップ)"; \
		echo "  インストール: cargo install taplo-cli"; \
	fi

# =============================================================================
# その他
# =============================================================================

clean:
	@echo "==> Cleaning caches..."
	@rm -rf ~/.cache/sheldon 2>/dev/null || true
	@rm -f ~/.zcompdump* 2>/dev/null || true
	@echo "Cache cleaned"
