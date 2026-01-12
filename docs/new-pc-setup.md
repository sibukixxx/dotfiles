# 新しいPCでのセットアップガイド

このガイドでは、[chezmoi](https://www.chezmoi.io/) を使用して新しいPCにdotfiles環境を完全にセットアップする手順を説明します。

## 目次

1. [ブートストラップ（初回セットアップ）](#ブートストラップ初回セットアップ)
2. [前提条件](#前提条件)
3. [詳細セットアップ](#詳細セットアップ)
4. [ターミナルエミュレータ](#ターミナルエミュレータ)
5. [SSH/GPGキーの設定](#sshgpgキーの設定)
6. [オプション設定](#オプション設定)
7. [セットアップ確認チェックリスト](#セットアップ確認チェックリスト)
8. [トラブルシューティング](#トラブルシューティング)
9. [chezmoi の使い方](#chezmoi-の使い方)

---

## ブートストラップ（初回セットアップ）

SSH鍵は age で暗号化されてdotfilesに含まれています。新しいPCでは以下の手順でセットアップします。

### 概要図

```
┌─────────────────────────────────────────────────────────────────┐
│ 旧PC                                                            │
│                                                                 │
│  ~/.config/chezmoi/key.txt  ──────┐                            │
│                                    │ AirDrop / USB / SCP        │
└────────────────────────────────────│────────────────────────────┘
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 新PC                                                            │
│                                                                 │
│  1. chezmoi init (HTTPS)  ─► dotfilesをクローン                │
│                                                                 │
│  2. key.txt を配置        ─► ~/.config/chezmoi/key.txt         │
│                                                                 │
│  3. chezmoi apply         ─► SSH鍵・設定ファイルが復元         │
│                                                                 │
│  4. git remote set-url    ─► 以降はSSHで操作                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Step 1: 旧PCから age 鍵を転送

新PCでSSH鍵を復号するために、`key.txt` を安全に転送します。

| 方法 | コマンド/手順 |
|------|---------------|
| **AirDrop** | Finderで `~/.config/chezmoi/key.txt` を送信 |
| **USB** | USBメモリにコピーして転送 |
| **一時SCP** | `scp old-pc:~/.config/chezmoi/key.txt /tmp/` |

**重要**: `key.txt` は秘密鍵です。転送後、一時ファイルは削除してください。

### Step 2: 新PCで chezmoi をインストール

```bash
# macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi age

# Linux / WSL
sh -c "$(curl -fsLS get.chezmoi.io)"
sudo apt install age  # または nix で
```

### Step 3: dotfiles をクローン（HTTPS経由）

SSH鍵がまだないので、**HTTPS** でクローンします。

```bash
# HTTPS でクローン（SSH鍵不要）
chezmoi init https://github.com/sibukixxx/dotfiles.git
```

### Step 4: age 鍵を配置

```bash
# ディレクトリ作成
mkdir -p ~/.config/chezmoi

# 転送した key.txt を配置
mv /path/to/key.txt ~/.config/chezmoi/key.txt

# パーミッション設定
chmod 600 ~/.config/chezmoi/key.txt
```

### Step 5: dotfiles を適用

```bash
# 適用（SSH鍵が自動的に復号・復元される）
chezmoi apply
```

これで以下が復元されます：
- `~/.ssh/id_rsa` - SSH秘密鍵
- `~/.ssh/id_rsa.pub` - SSH公開鍵
- `~/.ssh/config` - SSH設定
- その他すべての設定ファイル

### Step 6: リモートをSSHに切り替え

```bash
# SSH鍵が使えるようになったので、SSHに切り替え
chezmoi cd
git remote set-url origin git@github.com:sibukixxx/dotfiles.git

# 確認
git remote -v
```

### Step 7: シェルを再起動

```bash
source ~/.zshrc
# または、ターミナルを再起動
```

### クイックコマンド（まとめ）

```bash
# 1. chezmoi + age インストール
brew install chezmoi age

# 2. HTTPS でクローン
chezmoi init https://github.com/sibukixxx/dotfiles.git

# 3. age鍵を配置（事前に転送しておく）
mkdir -p ~/.config/chezmoi
mv ~/Downloads/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 4. 適用
chezmoi apply

# 5. SSHに切り替え
chezmoi cd && git remote set-url origin git@github.com:sibukixxx/dotfiles.git
```

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

## アプリケーション（自動インストール）

`chezmoi apply` 実行時に Brewfile から以下のアプリが自動インストールされます。

### インストールされるアプリ

| カテゴリ | アプリ | 説明 |
|----------|--------|------|
| **ターミナル** | Ghostty, Alacritty | GPU高速ターミナル |
| **ブラウザ** | Google Chrome | |
| **コミュニケーション** | Slack, Discord | |
| **IDE・エディタ** | VS Code, JetBrains Toolbox | WebStorm等はToolbox経由 |
| **コンテナ** | OrbStack | Docker/Linux VM |
| **生産性** | Alfred, Clipy, Obsidian, Dropbox | |
| **AI** | Claude Desktop | |
| **その他** | Kindle, Steam | |

### Xcode / iOS Simulator

Xcode は Mac App Store から手動インストールが必要です（サイズが大きいため）。

```bash
# Mac App Store CLI
mas install 497799835  # Xcode

# または App Store から手動インストール
open "macappstore://apps.apple.com/app/id497799835"
```

Xcode インストール後、Simulator が利用可能になります。

```bash
# Simulator を開く
open -a Simulator
```

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

### 既存のSSH鍵を復元（推奨）

SSH鍵は age で暗号化されてdotfilesに含まれています。復元するには：

```bash
# 1. age鍵を安全に転送（旧PCから）
# 方法A: AirDrop/USB で ~/.config/chezmoi/key.txt をコピー
# 方法B: 一時的にSCPで転送
scp old-pc:~/.config/chezmoi/key.txt ~/.config/chezmoi/

# 2. chezmoi apply で自動復元
chezmoi apply

# SSH鍵が ~/.ssh/ に復元されます
```

**重要**: `key.txt` は絶対にGitにコミットしないでください。これは復号に必要な秘密鍵です。

### 新しいSSH鍵を生成する場合

```bash
# Ed25519 キーの生成（推奨）
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### SSH キーの設定

```bash
# SSH エージェントを起動
eval "$(ssh-agent -s)"

# キーを追加（macOS）
ssh-add --apple-use-keychain ~/.ssh/id_rsa

# キーを追加（Linux）
ssh-add ~/.ssh/id_rsa
```

### GitHub への登録

```bash
# GitHub CLI を使用する場合（推奨）
gh auth login
gh ssh-key add ~/.ssh/id_rsa.pub -t "New PC $(date +%Y-%m-%d)"
```

### SSH 設定ファイル

SSH設定は chezmoi apply で自動的に `~/.ssh/config` に復元されます。

手動で作成する場合:

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
