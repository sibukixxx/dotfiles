.PHONY: all bootstrap update verify packages edit diff help

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
	@echo "使用方法:"
	@echo "  make bootstrap  - 初回セットアップ (chezmoi init + apply)"
	@echo "  make update     - dotfiles更新 (chezmoi update)"
	@echo "  make verify     - セットアップ検証"
	@echo "  make packages   - パッケージ同期 (brew bundle / home-manager)"
	@echo "  make edit       - 設定編集 (chezmoi edit)"
	@echo "  make diff       - 適用前の差分確認 (chezmoi diff)"
	@echo ""
	@echo "検出されたOS: $(OS)"

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

edit:
	@echo "==> Opening chezmoi source directory..."
	chezmoi edit

diff:
	@echo "==> Showing pending changes..."
	chezmoi diff
