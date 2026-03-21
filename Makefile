.PHONY: all bootstrap update verify packages macos-defaults edit diff lint lint-shell lint-yaml lint-toml lint-unicode ai-rules clean help

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
	@echo "  make macos-defaults - macOS システム設定を適用"
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
	@echo "  make lint-unicode - 不可視Unicode文字の検出 (GlassWorm対策)"
	@echo ""
	@echo "AI ルール:"
	@echo "  make ai-rules   - 各AIツール向けルールファイルを生成"
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
	@echo "  [1/2] Homebrew (GUI apps & macOS-only tools)..."
	@if [ -f "$(CURDIR)/Brewfile" ]; then \
		brew bundle --file=$(CURDIR)/Brewfile; \
	else \
		echo "Brewfile が見つかりません"; \
		exit 1; \
	fi
	@echo "  [2/2] Nix Home Manager (CLI tools)..."
	@if command -v home-manager >/dev/null 2>&1; then \
		if [ -f "$(CURDIR)/flake.nix" ]; then \
			echo "    flake.nix 検出 → flake モードで実行"; \
			home-manager switch --flake $(CURDIR); \
		else \
			home-manager switch; \
		fi; \
	else \
		echo "⚠️  home-manager が見つかりません (スキップ)"; \
		echo "  CLI ツールの Nix 管理を有効にするには:"; \
		echo "    1. curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh"; \
		echo "    2. nix run home-manager -- switch --flake ."; \
	fi
else
	@if command -v home-manager >/dev/null 2>&1; then \
		if [ -f "$(CURDIR)/flake.nix" ]; then \
			home-manager switch --flake $(CURDIR); \
		else \
			home-manager switch; \
		fi; \
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

lint: lint-shell lint-yaml lint-toml lint-unicode
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

lint-unicode:
	@echo "==> Scanning for invisible Unicode characters (GlassWorm defense)..."
	@FOUND=0; \
	INVISIBLE_PATTERN='[\x{200B}\x{200C}\x{200D}\x{200E}\x{200F}\x{202A}\x{202B}\x{202C}\x{202D}\x{202E}\x{00AD}\x{061C}\x{180E}\x{2060}\x{2061}\x{2062}\x{2063}\x{2064}\x{2066}\x{2067}\x{2068}\x{2069}\x{206A}\x{206B}\x{206C}\x{206D}\x{206E}\x{206F}\x{FEFF}\x{2028}\x{2029}]'; \
	TAG_PATTERN='[\x{E0001}-\x{E007F}]'; \
	RESULTS=$$(grep -rnP "$$INVISIBLE_PATTERN|$$TAG_PATTERN" --include='*.sh' --include='*.zsh' --include='*.bash' --include='*.toml' --include='*.yaml' --include='*.yml' --include='*.json' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.rs' --include='*.rb' --include='*.lua' --include='*.vim' --include='*.conf' --include='*.cfg' --include='*.ini' --include='*.tmpl' --include='*.md' . 2>/dev/null | grep -v '.git/' || true); \
	if [ -n "$$RESULTS" ]; then \
		echo "🚨 不可視Unicode文字を検出:"; \
		echo "$$RESULTS"; \
		FOUND=1; \
	fi; \
	if [ "$$FOUND" -eq 0 ]; then \
		echo "✅ 不可視Unicode文字は検出されませんでした"; \
	else \
		exit 1; \
	fi

# =============================================================================
# macOS 設定
# =============================================================================

macos-defaults:
ifeq ($(OS),macos)
	@macos-defaults
else
	@echo "macOS 以外では実行できません"
endif

# =============================================================================
# AI ルール生成
# =============================================================================

ai-rules:
	@bash ai-rules/generate.sh

# =============================================================================
# その他
# =============================================================================

clean:
	@echo "==> Cleaning caches..."
	@rm -rf ~/.cache/sheldon 2>/dev/null || true
	@rm -f ~/.zcompdump* 2>/dev/null || true
	@echo "Cache cleaned"
