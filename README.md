# dotfiles

[![macOS](https://img.shields.io/badge/macOS-supported-brightgreen?logo=apple)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-supported-brightgreen?logo=linux&logoColor=white)](https://www.linux.org/)
[![WSL](https://img.shields.io/badge/WSL-supported-brightgreen?logo=windows)](https://docs.microsoft.com/en-us/windows/wsl/)
[![chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue?logo=git)](https://www.chezmoi.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

macOS / Linux / WSL 対応の開発環境設定ファイル。[chezmoi](https://www.chezmoi.io/) で管理。

---

## 目次

- [セットアップフロー](#セットアップフロー)
- [設計思想](#設計思想)
- [特徴](#特徴)
- [主なツール](#主なツール)
- [クイックスタート](#クイックスタート)
- [キーバインド](#キーバインド)
- [エイリアス](#エイリアス)
- [カスタマイズ](#カスタマイズ)
- [ドキュメント](#ドキュメント)

---

## セットアップフロー

```
┌──────────────────────────────────────────────────────────────────┐
│                        セットアップフロー                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  新規PC:   make bootstrap → chezmoi init → パッケージ → 完了    │
│                                                                  │
│  日常:     make update    → git pull     → apply     → 完了    │
│                                                                  │
│  検証:     make verify    → ツール確認   → 結果表示             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

詳細なアーキテクチャ: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## 設計思想

### なぜ chezmoi か

| 課題 | 従来の方法 | chezmoi での解決 |
|------|-----------|-----------------|
| シークレット管理 | `.gitignore` で除外 | age 暗号化でリポジトリに含める |
| マシン固有設定 | 手動で分岐 | テンプレートで自動分岐 |
| 適用前確認 | できない | `chezmoi diff` で差分表示 |
| 部分適用 | 全体 or 手動 | ファイル単位で適用可能 |

### ツール選定基準

1. **速度**: 起動・実行が高速であること（Rust製ツールを優先）
2. **保守性**: アクティブにメンテナンスされていること
3. **移植性**: macOS / Linux で同様に動作すること
4. **統合性**: 他のツールと連携しやすいこと

### ディレクトリ哲学

```
~/.config/          # XDG Base Directory 準拠
~/.local/bin/       # カスタムスクリプト
~/workspace/        # ghq 管理のリポジトリ群
```

---

## 特徴

| 特徴 | 説明 |
|------|------|
| **chezmoi 管理** | テンプレート機能、マシン固有設定、安全なシークレット管理 |
| **マルチプラットフォーム** | macOS, Linux, WSL をシームレスにサポート |
| **モダン CLI** | Rust製の高速ツール群（eza, bat, ripgrep, fd, zoxide） |
| **プラグイン管理** | Sheldon による高速な zsh プラグイン管理 |
| **ターミナルマルチプレクサ** | Zellij（tmux 代替、より直感的） |
| **パッケージマネージャ** | macOS: Homebrew / Linux: Nix + Home Manager |
| **リポジトリ一括クローン** | 初期セットアップ時に GitHub 全リポジトリを自動クローン |
| **SSH鍵暗号化** | age 暗号化で SSH 鍵を安全に管理・復元 |

---

## 主なツール

### コアツール

| ツール | 説明 | 代替 | 選定理由 |
|--------|------|------|----------|
| **[chezmoi](https://www.chezmoi.io/)** | dotfiles マネージャー | stow, yadm | テンプレート・暗号化機能 |
| **[Neovim](https://neovim.io/)** | モダンな Vim | Vim | Lua 設定、LSP 統合 |
| **[zsh](https://www.zsh.org/)** | シェル | bash, fish | 補完・プラグインエコシステム |
| **[Sheldon](https://sheldon.cli.rs/)** | zsh プラグイン管理 | zinit, zplug | Rust製で高速 |

### ターミナル環境

| ツール | 説明 | 代替 | 選定理由 |
|--------|------|------|----------|
| **[Ghostty](https://ghostty.org/)** | ターミナルエミュレータ | iTerm2 | GPU高速、ネイティブ |
| **[Alacritty](https://alacritty.org/)** | ターミナルエミュレータ | - | フォールバック用 |
| **[Zellij](https://zellij.dev/)** | ターミナルマルチプレクサ | tmux | モダン UI、設定が容易 |

### モダン CLI ツール（Rust製）

| ツール | 置換対象 | 主な利点 |
|--------|----------|----------|
| **[eza](https://eza.rocks/)** | `ls` | アイコン、Git ステータス表示 |
| **[bat](https://github.com/sharkdp/bat)** | `cat` | シンタックスハイライト、行番号 |
| **[ripgrep](https://github.com/BurntSushi/ripgrep)** | `grep` | 高速、`.gitignore` 対応 |
| **[fd](https://github.com/sharkdp/fd)** | `find` | 高速、直感的な構文 |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | `cd` | 学習型ディレクトリジャンプ |
| **[fzf](https://github.com/junegunn/fzf)** | - | ファジーファインダー |

### 開発ツール

| ツール | 説明 |
|--------|------|
| **[ghq](https://github.com/x-motemen/ghq)** | リポジトリ管理 (`~/workspace/github.com/...`) |
| **[gh](https://cli.github.com/)** | GitHub CLI |
| **[delta](https://github.com/dandavison/delta)** | Git diff ビューア |

---

## アプリケーション（自動インストール）

Brewfile で管理されているアプリケーション:

| カテゴリ | アプリ |
|----------|--------|
| **ターミナル** | Ghostty, Alacritty |
| **ブラウザ** | Google Chrome |
| **コミュニケーション** | Slack, Discord |
| **IDE・エディタ** | VS Code, JetBrains Toolbox |
| **コンテナ** | OrbStack |
| **生産性** | Alfred, Clipy, Obsidian, Dropbox |
| **AI** | Claude Desktop |
| **その他** | Kindle, Steam |

```bash
# アプリケーションのインストール
make packages
# または
brew bundle --file=~/dotfiles/Brewfile
```

---

## クイックスタート

### 前提条件

| OS | 必要なもの |
|----|-----------|
| **macOS** | なし（Homebrew が自動インストール） |
| **Linux** | `curl`, `git` |
| **WSL** | WSL2、Windows Terminal 推奨 |

### Makefile コマンド（推奨）

| コマンド | 説明 | 使用場面 |
|----------|------|----------|
| `make bootstrap` | 初回セットアップ | 新規 PC |
| `make update` | dotfiles 更新 | 日常使用 |
| `make verify` | セットアップ検証 | 動作確認 |
| `make packages` | パッケージ同期 | アプリ追加後 |
| `make diff` | 適用前の差分確認 | 変更確認 |
| `make edit` | 設定編集 | カスタマイズ |
| `make help` | ヘルプ表示 | コマンド確認 |

### 新規インストール

**ワンライナー（推奨）**

```bash
# macOS: Homebrew がなければ先にインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
brew install chezmoi

# dotfiles を適用
chezmoi init --apply YOUR_GITHUB_USERNAME
```

**手動インストール**

```bash
# chezmoi インストール
brew install chezmoi  # macOS
# または
sh -c "$(curl -fsLS get.chezmoi.io)"  # Linux/WSL

# 初期化と適用
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git
chezmoi diff    # 差分確認（推奨）
chezmoi apply   # 適用
```

### 既存マシンの更新

```bash
chezmoi update
# または
make update
```

### SSH 鍵の復元（新規 PC）

```bash
# 1. 旧 PC から age 鍵を転送（AirDrop/USB/SCP）
mkdir -p ~/.config/chezmoi
mv /path/to/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 2. 適用（SSH 鍵が自動復号される）
chezmoi apply
```

**詳細ガイド**: [docs/new-pc-setup.md](docs/new-pc-setup.md)

---

## chezmoi コマンド

### 基本コマンド

| コマンド | 説明 |
|----------|------|
| `chezmoi init <repo>` | リポジトリから dotfiles を初期化 |
| `chezmoi apply` | 変更を適用 |
| `chezmoi diff` | 適用前の差分を確認 |
| `chezmoi update` | リモートから更新を取得して適用 |
| `chezmoi cd` | ソースディレクトリに移動 |

### 編集・管理

| コマンド | 説明 |
|----------|------|
| `chezmoi edit <file>` | ファイルを編集 |
| `chezmoi add <file>` | ファイルを管理対象に追加 |
| `chezmoi add --encrypt <file>` | 暗号化して追加 |
| `chezmoi add --template <file>` | テンプレートとして追加 |
| `chezmoi managed` | 管理対象ファイル一覧 |
| `chezmoi data` | テンプレートデータを表示 |

### トラブルシューティング

| コマンド | 説明 |
|----------|------|
| `chezmoi apply -v` | 詳細ログで適用 |
| `chezmoi verify` | ファイル状態を検証 |
| `chezmoi doctor` | 設定の問題を診断 |
| `chezmoi state delete-bucket --bucket=scriptState` | スクリプト状態をリセット |

---

## ディレクトリ構成

```
dotfiles/
├── .chezmoi.toml.tmpl         # chezmoi 設定テンプレート
├── .chezmoiignore             # 無視ファイル
├── Makefile                   # セットアップコマンド
├── Brewfile                   # Homebrew パッケージ（macOS）
│
├── dot_zshrc                  # ~/.zshrc（メインエントリ）
├── dot_config/
│   ├── nvim/                  # Neovim 設定
│   ├── zsh/                   # zsh モジュール
│   │   ├── tools.zsh          # ツール統合（zoxide/fzf/ghq）
│   │   ├── alias/             # エイリアス定義
│   │   ├── mac.zsh            # macOS 固有
│   │   └── linux.zsh          # Linux 固有
│   ├── ghostty/               # Ghostty 設定
│   ├── alacritty/             # Alacritty 設定
│   ├── zellij/                # Zellij 設定
│   ├── sheldon/               # プラグイン管理
│   ├── git/                   # Git 設定（XDG準拠）
│   └── karabiner/             # キーリマッパー（macOS）
│
├── dot_local/bin/             # カスタムスクリプト
│   ├── executable_verify-setup
│   └── executable_clone-all-repos
│
├── nix/
│   └── home.nix               # Home Manager（Linux/WSL）
│
├── run_onchange_before_*      # インストール前スクリプト
├── run_once_after_*           # インストール後スクリプト
│
└── docs/
    ├── ARCHITECTURE.md        # アーキテクチャ解説
    ├── TROUBLESHOOTING.md     # トラブルシューティング
    ├── new-pc-setup.md        # 新規 PC セットアップ
    └── zellij.md              # Zellij ガイド
```

---

## キーバインド

### Ghostty

| キー | 機能 |
|------|------|
| `Cmd+Enter` | フルスクリーン切り替え |
| `Cmd+T` | 新規タブ |
| `Cmd+W` | タブを閉じる |
| `Cmd+[` / `Cmd+]` | 前/次のタブ |
| `Cmd+1-5` | タブ番号で移動 |
| `Cmd++/-/0` | フォントサイズ変更 |
| `Cmd+K` | 画面クリア |
| `Ctrl+\`` | クイックターミナル（グローバル） |

### Zellij（Prefix: `Ctrl+x`）

| キー | 機能 | キー | 機能 |
|------|------|------|------|
| `Ctrl+x \|` | 縦分割 | `Ctrl+x -` | 横分割 |
| `Ctrl+x x` | ペインを閉じる | `Ctrl+x z` | ペイン最大化 |
| `Ctrl+x h/j/k/l` | ペイン移動 | `Ctrl+x H/J/K/L` | リサイズ |
| `Ctrl+x c` | 新規タブ | `Ctrl+x n/p` | 次/前のタブ |
| `Ctrl+x 1-9` | タブ番号で移動 | `Ctrl+x d` | デタッチ |
| `Ctrl+x w` | セッション管理 | `Ctrl+x [` | スクロール |
| `Ctrl+x e` | ペイン同期 | `Ctrl+x f` | フローティング |

### zsh キーバインド

| キー | 機能 |
|------|------|
| `Ctrl+G` | ghq リポジトリを fzf で選択 |
| `Ctrl+R` | 履歴を fzf で検索 |
| `z <dir>` | zoxide でスマートジャンプ |
| `zi` | zoxide インタラクティブ選択 |

### zsh コマンド

| コマンド | 機能 |
|----------|------|
| `gcd` | ghq リポジトリに移動 |
| `gg <repo>` | ghq get して自動 cd |
| `fe` | fzf でファイル選択して編集 |
| `fcd` | fzf でディレクトリ選択して cd |
| `fbr` | fzf で git ブランチ切り替え |
| `flog` | fzf で git ログを閲覧 |

---

## エイリアス

### Zellij セッション管理

```bash
zj      # zellij 起動
zja     # zellij attach（セッションに接続）
zjl     # zellij list-sessions
zjk     # zellij kill-session
zs      # セッションに接続 or 新規作成
```

### モダン CLI ツール（自動置換）

```bash
ls      # → eza --icons
ll      # → eza -la --icons --git
lt      # → eza --tree --icons --level=2
cat     # → bat --paging=never
find    # → fd
grep    # → rg
```

### Git ショートカット

```bash
g       # git
gs      # git status
ga      # git add
gc      # git commit
gp      # git push
gl      # git pull
gd      # git diff
gco     # git checkout
gb      # git branch
glog    # git log --oneline --graph --decorate
```

### ナビゲーション

```bash
..      # cd ..
...     # cd ../..
....    # cd ../../..
pu      # pushd
po      # popd
```

### エディタ

```bash
vi/vim  # nvim
view    # nvim -R（読み取り専用）
```

---

## プラグイン管理

### Sheldon

```bash
# プラグインを更新
sheldon lock --update

# 設定を確認
cat ~/.config/sheldon/plugins.toml
```

### インストール済みプラグイン

| プラグイン | 説明 |
|-----------|------|
| **zsh-defer** | 遅延読み込みで高速起動 |
| **zsh-autosuggestions** | コマンド提案（履歴ベース） |
| **zsh-syntax-highlighting** | シンタックスハイライト |
| **zsh-completions** | 追加の補完定義 |
| **zsh-history-substring-search** | 履歴の部分文字列検索 |

---

## マルチプラットフォーム対応

### macOS

```bash
# chezmoi がすべてを自動で行います
chezmoi init --apply YOUR_GITHUB_USERNAME
```

自動処理:
- Xcode Command Line Tools インストール
- Rosetta 2 インストール（Apple Silicon）
- Homebrew インストール
- Brewfile からパッケージインストール

### Linux / WSL

```bash
# chezmoi がすべてを自動で行います
chezmoi init --apply YOUR_GITHUB_USERNAME
```

自動処理:
- Nix インストール
- Home Manager 設定
- `home.nix` からパッケージインストール

---

## フォント

Ghostty / Alacritty で使用するフォント（HackGen Nerd Font）:

```bash
# macOS
brew install --cask font-hackgen-nerd

# Linux
# https://github.com/yuru7/HackGen/releases からダウンロード
mkdir -p ~/.local/share/fonts
# フォントファイルをコピー
fc-cache -fv
```

---

## カスタマイズ

### 新しいファイルを追加

```bash
# 通常のファイル
chezmoi add ~/.some-config

# テンプレートとして追加（マシン固有設定用）
chezmoi add --template ~/.some-config

# 暗号化して追加（機密情報用）
chezmoi add --encrypt ~/.ssh/id_ed25519
```

### ファイルを編集

```bash
# 1. ソースファイルを編集
chezmoi edit ~/.zshrc

# 2. 適用前に差分確認
chezmoi diff

# 3. 適用
chezmoi apply

# 4. コミット
chezmoi cd && git add -A && git commit -m "Update zshrc"
```

### パッケージを追加

**macOS:**
```bash
# Brewfile を編集
vi ~/dotfiles/Brewfile

# 適用
make packages
```

**Linux/WSL:**
```nix
# nix/home.nix を編集
home.packages = with pkgs; [
  new-package
];

# 適用
home-manager switch
```

---

## ドキュメント

| ドキュメント | 説明 |
|-------------|------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | 全体設計、フロー図、ディレクトリ構造 |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | よくある問題と解決策 |
| [new-pc-setup.md](docs/new-pc-setup.md) | 新規 PC セットアップの詳細ガイド |
| [zellij.md](docs/zellij.md) | Zellij の使い方ガイド |

---

## リポジトリ管理

### 初期セットアップ時の一括クローン

chezmoi の初期セットアップ時に、GitHub の全リポジトリを `~/workspace` に自動クローン:

```
セットアップ時のプロンプト:
GitHub username? sibukixxx
Clone all GitHub repositories to ~/workspace? (y/n) y
```

リポジトリは ghq 形式で管理:
```
~/workspace/
└── github.com/
    └── sibukixxx/
        ├── dotfiles/
        ├── project-a/
        └── project-b/
```

### 手動でのクローン

```bash
# 全リポジトリをクローン
clone-all-repos sibukixxx

# 個別にクローン
ghq get github.com/sibukixxx/repo-name
```

### リポジトリへのアクセス

```bash
# fuzzy finder でリポジトリを選択
gcd

# または Ctrl+G でも選択可能
```

---

## SSH 鍵の管理

SSH 鍵は age で暗号化されてリポジトリに含まれています。

### 新しい PC での復元

```bash
# 1. age 鍵を転送（AirDrop, USB, SCP など）
mkdir -p ~/.config/chezmoi
# key.txt を ~/.config/chezmoi/ にコピー

# 2. chezmoi apply で自動復元
chezmoi apply
# → ~/.ssh/id_rsa, ~/.ssh/config が復元される
```

### 新しい SSH 鍵を追加

```bash
# 暗号化して追加
chezmoi add --encrypt ~/.ssh/id_ed25519
chezmoi add --encrypt ~/.ssh/id_ed25519.pub
```

**重要**: `~/.config/chezmoi/key.txt` は復号に必要な秘密鍵です。安全に保管し、Git にはコミットしないでください。

---

## レガシースクリプト

以下のスクリプトは chezmoi 移行前のものです。現在は **chezmoi を推奨** します。

| スクリプト | 状態 | 代替手段 |
|------------|------|----------|
| `init.sh` | 廃止予定 | `make bootstrap` |
| `dotfilesLink.sh` | 廃止予定 | chezmoi が自動処理 |

---

## 貢献

1. Issue を作成して問題や提案を報告
2. Fork してブランチを作成
3. 変更をコミット
4. Pull Request を作成

---

## ライセンス

MIT
