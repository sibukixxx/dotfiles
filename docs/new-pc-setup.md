# 新しいPCでのセットアップガイド

このガイドでは、[chezmoi](https://www.chezmoi.io/) を使用して新しいPCにdotfiles環境を完全にセットアップする手順を説明します。

## 目次

1. [クイックセットアップ（ワンライナー）](#クイックセットアップワンライナー)
2. [前提条件](#前提条件)
3. [詳細セットアップ](#詳細セットアップ)
4. [ターミナルエミュレータ](#ターミナルエミュレータ)
5. [SSH/GPGキーの設定](#sshgpgキーの設定)
6. [オプション設定](#オプション設定)
7. [セットアップ確認チェックリスト](#セットアップ確認チェックリスト)
8. [トラブルシューティング](#トラブルシューティング)
9. [chezmoi の使い方](#chezmoi-の使い方)

---

## クイックセットアップ（ワンライナー）

最も簡単なセットアップ方法です。chezmoi が自動ですべてを行います。

### macOS

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME
```

### Linux / WSL

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME
```

これで基本的なセットアップは完了です。

---

## 前提条件

### macOS

chezmoi の run_once スクリプトが自動で処理しますが、事前に確認したい場合：

1. **Xcode Command Line Tools**

   ```bash
   xcode-select --install
   ```

2. **Rosetta 2**（Apple Silicon Macのみ）

   ```bash
   softwareupdate --install-rosetta --agree-to-license
   ```

### Linux / WSL

1. **基本パッケージ**

   ```bash
   sudo apt update
   sudo apt install -y curl git
   ```

2. **WSL2の場合**
   - Windows Terminal をインストール推奨
   - WSL2 バージョンを確認: `wsl --version`

---

## 詳細セットアップ

### Step 1: chezmoi のインストール

**macOS（Homebrew）**

```bash
brew install chezmoi
```

**Linux / WSL**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### Step 2: dotfiles の初期化

**HTTPS経由（推奨：初回セットアップ）**

```bash
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git
```

**SSH経由（SSHキー設定済みの場合）**

```bash
chezmoi init git@github.com:YOUR_USERNAME/dotfiles.git
```

### Step 3: 差分の確認

```bash
chezmoi diff
```

### Step 4: dotfiles の適用

```bash
chezmoi apply
```

初回実行時、chezmoi は以下を自動で行います：

| 処理 | macOS | Linux/WSL |
|------|-------|-----------|
| 前提条件チェック | Xcode CLT, Rosetta 2 | curl, git, sudo |
| パッケージマネージャ | Homebrew インストール | Nix + Home Manager |
| パッケージ | Brewfile から | home.nix から |
| Rust ツール | cargo install | cargo install |
| シェル設定 | zsh + Sheldon | zsh + Sheldon |

### Step 5: ターミナルの再起動

```bash
source ~/.zshrc
# または、ターミナルを再起動
```

---

## ターミナルエミュレータ

### Ghostty（推奨）

macOS / Linux 対応の高速ターミナルエミュレータ。

```bash
# macOS
brew install --cask ghostty

# または公式サイトからダウンロード
# https://ghostty.org/
```

### Alacritty

GPU アクセラレーション対応のターミナルエミュレータ。

```bash
# macOS
brew install --cask alacritty

# Linux
sudo apt install alacritty
```

### フォントのインストール

```bash
# macOS
brew tap homebrew/cask-fonts
brew install --cask font-hackgen-nerd

# Linux
# HackGen Nerd Font を手動ダウンロード
# https://github.com/yuru7/HackGen/releases
mkdir -p ~/.local/share/fonts
fc-cache -fv
```

---

## SSH/GPGキーの設定

### SSH キーの生成

```bash
# Ed25519 キーの生成（推奨）
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### SSH キーの設定

```bash
# SSH エージェントを起動
eval "$(ssh-agent -s)"

# キーを追加（macOS）
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# キーを追加（Linux）
ssh-add ~/.ssh/id_ed25519
```

### GitHub への登録

```bash
# GitHub CLI を使用する場合（推奨）
gh auth login
gh ssh-key add ~/.ssh/id_ed25519.pub -t "New PC $(date +%Y-%m-%d)"
```

### SSH 設定ファイル

`~/.ssh/config` を作成:

```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes  # macOS のみ

Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
```

### dotfiles リポジトリを SSH に切り替え

```bash
chezmoi cd
git remote set-url origin git@github.com:YOUR_USERNAME/dotfiles.git
```

---

## オプション設定

### Hammerspoon（macOS のみ）

```bash
brew install --cask hammerspoon
```

**基本設定 (`~/.hammerspoon/init.lua`)**

```lua
-- Alacritty 透過切り替え
hs.hotkey.bind({ "cmd" }, "U", function()
    hs.execute("toggle_opacity", true)
end)
```

### Karabiner-Elements（macOS のみ）

```bash
brew install --cask karabiner-elements
```

### Raycast（macOS のみ）

```bash
brew install --cask raycast
```

### macOS システム設定

```bash
# キーリピートを高速化
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10

# Dock を自動的に隠す
defaults write com.apple.dock autohide -bool true

# Finder で隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true

killall Dock Finder
```

---

## セットアップ確認チェックリスト

### 確認コマンド

```bash
verify-setup
```

### 基本ツール

- [ ] `zsh` - デフォルトシェル
- [ ] `nvim` - Neovim エディタ
- [ ] `git` - バージョン管理
- [ ] `sheldon` - プラグインマネージャー
- [ ] `zellij` - ターミナルマルチプレクサ

### モダン CLI ツール

- [ ] `eza` - `ls` の代替
- [ ] `bat` - `cat` の代替
- [ ] `rg` (ripgrep) - `grep` の代替
- [ ] `fd` - `find` の代替
- [ ] `zoxide` - スマート `cd`
- [ ] `fzf` - ファジーファインダー
- [ ] `ghq` - リポジトリ管理

### Git / GitHub

- [ ] `git config user.name` が設定されている
- [ ] `git config user.email` が設定されている
- [ ] SSH 接続ができる: `ssh -T git@github.com`

---

## トラブルシューティング

### chezmoi apply が失敗する

```bash
# 差分を確認
chezmoi diff

# 詳細ログで実行
chezmoi apply -v

# 特定のファイルだけ適用
chezmoi apply ~/.zshrc
```

### run_once スクリプトを再実行したい

```bash
# 実行状態をリセット
chezmoi state delete-bucket --bucket=scriptState

# 再適用
chezmoi apply
```

### Sheldon が動かない

```bash
rm -rf ~/.local/share/sheldon ~/.cache/sheldon
sheldon lock
```

### フォントアイコンが文字化けする

```bash
fc-cache -fv
fc-list | grep -i hackgen
```

### chezmoi のソースを直接編集したい

```bash
# ソースディレクトリに移動
chezmoi cd

# 編集後、変更を確認
chezmoi diff

# 適用
chezmoi apply
```

---

## chezmoi の使い方

### 基本コマンド

| コマンド | 説明 |
|----------|------|
| `chezmoi init <repo>` | リポジトリから初期化 |
| `chezmoi apply` | 変更を適用 |
| `chezmoi diff` | 差分を表示 |
| `chezmoi update` | リモートから更新して適用 |
| `chezmoi edit <file>` | ファイルを編集 |
| `chezmoi cd` | ソースディレクトリに移動 |
| `chezmoi add <file>` | ファイルを管理対象に追加 |
| `chezmoi managed` | 管理対象ファイル一覧 |

### 新しいファイルを追加

```bash
# 通常のファイル
chezmoi add ~/.some-config

# テンプレートとして追加
chezmoi add --template ~/.some-config

# 実行可能ファイル
chezmoi add --executable ~/.local/bin/my-script
```

### 変更のワークフロー

```bash
# 1. ファイルを編集
chezmoi edit ~/.zshrc

# 2. 差分を確認
chezmoi diff

# 3. 適用
chezmoi apply

# 4. ソースをコミット
chezmoi cd
git add -A
git commit -m "Update zshrc"
git push
```

### 別のマシンで更新を取得

```bash
chezmoi update
```

---

## 新しい PC への移行チェックリスト

1. [ ] `chezmoi init --apply YOUR_GITHUB_USERNAME` を実行
2. [ ] SSH キーを生成または移行
3. [ ] GitHub に SSH キーを登録
4. [ ] ターミナルエミュレータをインストール
5. [ ] フォントをインストール
6. [ ] `verify-setup` で動作確認
7. [ ] dotfiles リポジトリを SSH に切り替え
8. [ ] リポジトリが `~/workspace` にクローンされていることを確認
9. [ ] オプション設定（Hammerspoon 等）

---

## 複数マシンでの設定の違い

chezmoi はテンプレート機能で、マシンごとに異なる設定を管理できます。

### 初回セットアップ時の質問

```
Git email address? your@email.com
Git user name? Your Name
GitHub username? yourusername
Is this a work machine? (y/n) n
Clone all GitHub repositories to ~/workspace? (y/n) y
```

**リポジトリのクローン**: `y` を選択すると、GitHub の全リポジトリを `~/workspace/github.com/<username>/` に ghq 経由でクローンします。

### マシン固有の設定を確認

```bash
chezmoi data
```

### テンプレートの例

```bash
# dot_gitconfig.tmpl
[user]
    name = {{ .name }}
    email = {{ .email }}
{{ if .isWork }}
[url "git@github.work.com:"]
    insteadOf = https://github.work.com/
{{ end }}
```

セットアップに関する質問があれば Issue を作成してください。
