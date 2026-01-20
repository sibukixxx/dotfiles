# アーキテクチャ

このドキュメントでは、dotfiles リポジトリの全体設計、セットアップフロー、ディレクトリ構造について解説します。

## 全体概要

このdotfilesは [chezmoi](https://www.chezmoi.io/) で管理され、macOS / Linux / WSL をサポートしています。

### 設計思想

- **宣言的管理**: chezmoiによる状態管理で、どのマシンでも同じ環境を再現
- **マルチプラットフォーム**: テンプレート機能でOS固有の設定を切り替え
- **セキュリティ**: age暗号化でSSH鍵などの機密情報を安全に管理
- **モダンツール**: Rust製の高速CLIツール群を標準採用

---

## セットアップフロー図

### 新規PCセットアップ

```
┌─────────────────────────────────────────────────────────────────────┐
│                      新規PCセットアップ                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. chezmoi init                                                    │
│     └─→ .chezmoi.toml.tmpl からユーザー設定を対話入力               │
│         (email, name, githubUser, isWork, cloneRepos)               │
│                                                                     │
│  2. run_onchange_before_01-install-prerequisites                    │
│     └─→ macOS: Xcode CLT / Rosetta 2                               │
│     └─→ Linux/WSL: curl / git / sudo                               │
│                                                                     │
│  3. run_onchange_before_02-install-packages                         │
│     └─→ macOS: brew bundle (Brewfile)                              │
│     └─→ Linux/WSL: home-manager switch (nix/home.nix)              │
│                                                                     │
│  4. run_onchange_before_03-install-rust-tools                       │
│     └─→ ripgrep, fd, bat, eza, zoxide, sheldon, zellij             │
│                                                                     │
│  5. ファイル展開                                                    │
│     └─→ dot_* → ~/*  (例: dot_zshrc → ~/.zshrc)                    │
│     └─→ dot_config/* → ~/.config/*                                 │
│     └─→ encrypted_* → 復号して展開                                 │
│                                                                     │
│  6. run_once_after_01-setup-shell                                   │
│     └─→ zsh をデフォルトシェルに設定                               │
│     └─→ Sheldon プラグインをロック                                 │
│     └─→ fzf キーバインド設定                                       │
│                                                                     │
│  7. run_once_after_02-clone-repositories (オプション)               │
│     └─→ gh + ghq で GitHub の全リポジトリをクローン                │
│     └─→ ~/workspace/github.com/<user>/<repo> 形式で配置            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 日常更新フロー

```
┌─────────────────────────┐
│  chezmoi update         │
│  または make update     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  git pull (自動)        │
│  リモートから最新取得   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  chezmoi apply          │
│  (差分のみ適用)         │
│  run_onchange_* 実行    │
└─────────────────────────┘
```

### 設定編集フロー

```
┌─────────────────────────┐
│  chezmoi edit <file>    │
│  または make edit       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  エディタで編集         │
│  (ソースディレクトリ)   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  chezmoi diff           │
│  または make diff       │
│  (変更内容を確認)       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  chezmoi apply          │
│  (変更を適用)           │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  git commit & push      │
│  (リポジトリに反映)     │
└─────────────────────────┘
```

---

## ディレクトリ構造詳解

### chezmoi 命名規則

| プレフィックス | 展開先 | 例 |
|----------------|--------|-----|
| `dot_` | `.` (ドット) | `dot_zshrc` → `~/.zshrc` |
| `private_` | パーミッション 600 | `private_dot_ssh` |
| `executable_` | 実行権限付与 | `executable_verify-setup` |
| `*.tmpl` | テンプレート処理 | `.chezmoi.toml.tmpl` |
| `encrypted_` | age暗号化 | `encrypted_private_key` |
| `run_once_*` | 初回のみ実行 | `run_once_after_01-*` |
| `run_onchange_*` | 変更時に実行 | `run_onchange_before_*` |
| `modify_*` | 既存ファイルを修正 | `modify_dot_bashrc` |
| `create_*` | 存在しない場合のみ作成 | `create_dot_gitconfig` |
| `symlink_*` | シンボリックリンク | `symlink_dot_vim` |

### スクリプト実行順序

```
1. run_onchange_before_* (変更時、適用前に実行)
2. run_once_before_*     (初回のみ、適用前に実行)
3. ファイル展開          (dot_* → ~/*)
4. run_once_after_*      (初回のみ、適用後に実行)
5. run_onchange_after_*  (変更時、適用後に実行)
```

### 主要ディレクトリ

```
dotfiles/
├── .chezmoi.toml.tmpl       # chezmoi 設定テンプレート（対話入力用）
├── .chezmoiignore           # chezmoi の無視ファイル
├── .chezmoiexternal.toml    # 外部リソースの定義（オプション）
├── Makefile                 # セットアップコマンド
├── Brewfile                 # Homebrew パッケージ一覧 (macOS)
│
├── dot_zshrc                # ~/.zshrc メインエントリ
├── dot_vimrc                # ~/.vimrc (レガシー互換)
├── dot_tmux.conf            # ~/.tmux.conf (レガシー互換)
│
├── dot_config/              # ~/.config/ にマッピング
│   ├── nvim/               # Neovim 設定
│   │   ├── init.lua        # メイン設定
│   │   └── lua/            # Lua モジュール
│   ├── zsh/                # zsh 追加設定
│   │   ├── tools.zsh       # zoxide/fzf/ghq 統合
│   │   ├── peco.zsh        # peco 関連（フォールバック）
│   │   ├── fzf-worktree.zsh # git worktree + fzf
│   │   ├── mac.zsh         # macOS 固有設定
│   │   ├── linux.zsh       # Linux 固有設定
│   │   └── alias/          # エイリアス定義
│   ├── git/                # Git 設定（XDG準拠）
│   │   └── config          # ~/.config/git/config
│   ├── sheldon/            # プラグイン管理
│   │   └── plugins.toml    # プラグイン定義
│   ├── zellij/             # ターミナルマルチプレクサ
│   │   └── config.kdl      # Zellij 設定
│   ├── ghostty/            # ターミナル（推奨）
│   │   └── config          # Ghostty 設定
│   ├── alacritty/          # ターミナル（フォールバック）
│   │   └── alacritty.toml  # Alacritty 設定
│   └── karabiner/          # キーリマッパー (macOS)
│
├── dot_local/
│   └── bin/                # ~/.local/bin/ カスタムスクリプト
│       ├── executable_verify-setup      # セットアップ検証
│       ├── executable_clone-all-repos   # リポジトリ一括クローン
│       ├── executable_toggle_opacity    # 透過度切り替え
│       └── executable_git-localinfo     # Git 情報表示
│
├── dot_ssh/                 # ~/.ssh/ (暗号化ファイル含む)
│   └── config.tmpl         # SSH 設定テンプレート
│
├── nix/                     # Linux/WSL 用 Home Manager
│   └── home.nix            # Home Manager 設定
│
├── run_onchange_before_*/   # インストール前スクリプト
├── run_once_after_*/        # インストール後スクリプト
│
├── docs/                    # ドキュメント
│   ├── ARCHITECTURE.md     # このファイル
│   ├── new-pc-setup.md     # 新規PCセットアップガイド
│   └── zellij.md           # Zellij ガイド
│
└── .claude/                 # Claude Code 設定
    └── settings.local.json
```

---

## マルチプラットフォーム対応

### プラットフォーム別の違い

| 項目 | macOS | Linux/WSL |
|------|-------|-----------|
| パッケージ管理 | Homebrew | Nix + Home Manager |
| 設定ファイル | `Brewfile` | `nix/home.nix` |
| キーバインド | Karabiner-Elements | - |
| フォント管理 | `brew install --cask` | Nix fonts |
| クリップボード | `pbcopy` / `pbpaste` | `xclip` / `wl-copy` |

### テンプレートによる分岐

`.chezmoi.toml.tmpl` で取得した変数と、OSの自動検出を組み合わせて分岐:

```
{{ if eq .chezmoi.os "darwin" }}
# macOS 固有の設定
{{ else if eq .chezmoi.os "linux" }}
# Linux 固有の設定
{{ end }}
```

---

## テンプレート変数

`.chezmoi.toml.tmpl` で定義される変数:

| 変数 | 説明 | 使用例 |
|------|------|--------|
| `email` | メールアドレス | Git コミット設定 |
| `name` | ユーザー名 | Git コミット設定 |
| `githubUser` | GitHub ユーザー名 | リポジトリクローン |
| `isWork` | 業務用マシンかどうか | 条件分岐で設定切り替え |
| `cloneRepos` | リポジトリ自動クローン | 初期セットアップ時の動作 |

### 使用例

```
# dot_config/git/config.tmpl
[user]
    name = {{ .name }}
    email = {{ .email }}

{{ if .isWork }}
[url "git@github-work:"]
    insteadOf = https://github.com/company/
{{ end }}
```

---

## セキュリティ設計

### age 暗号化

SSH鍵などの機密情報は age で暗号化してリポジトリに保存:

```
暗号化の流れ:
1. chezmoi add --encrypt ~/.ssh/id_ed25519
2. age で暗号化 → encrypted_private_dot_ssh/id_ed25519
3. Git にコミット（暗号化済み）

復号の流れ:
1. ~/.config/chezmoi/key.txt に復号キーを配置
2. chezmoi apply
3. 自動復号 → ~/.ssh/id_ed25519
```

### キーの管理

- 復号キー: `~/.config/chezmoi/key.txt`
- 暗号化キー: 公開鍵を `.chezmoi.toml` の `encryption.recipient` に設定
- **重要**: `key.txt` は Git にコミットしない

### 新しいマシンでの設定

```bash
# 1. 既存マシンから key.txt を転送（AirDrop, USB, SCP など）
mkdir -p ~/.config/chezmoi
# key.txt を配置

# 2. chezmoi apply で自動復号
chezmoi apply
```

---

## レガシースクリプトについて

以下のスクリプトは chezmoi 移行前のレガシーです:

| スクリプト | 状態 | 代替手段 |
|------------|------|----------|
| `init.sh` | 廃止予定 | `make bootstrap` / `chezmoi init --apply` |
| `dotfilesLink.sh` | 廃止予定 | chezmoi が自動処理 |
| `Makefile.old` | 参考用 | 新しい `Makefile` |

これらは参考用として残していますが、新規セットアップでは **chezmoi を推奨** します。

---

## 拡張ガイド

### 新しいdotfileを追加

```bash
# 1. ファイルを chezmoi の管理下に追加
chezmoi add ~/.new-config

# 2. テンプレートが必要な場合
chezmoi add --template ~/.new-config

# 3. 暗号化が必要な場合
chezmoi add --encrypt ~/.secret-file

# 4. 確認
chezmoi managed

# 5. コミット
cd ~/dotfiles && git add -A && git commit -m "Add new-config"
```

### 新しいスクリプトを追加

スクリプトの命名規則:
- `run_once_before_XX-name.sh.tmpl`: 初回のみ、適用前に実行
- `run_once_after_XX-name.sh.tmpl`: 初回のみ、適用後に実行
- `run_onchange_before_XX-name.sh.tmpl`: 変更時、適用前に実行
- `run_onchange_after_XX-name.sh.tmpl`: 変更時、適用後に実行

`XX` は実行順序を制御する2桁の数字。

### パッケージを追加

**macOS (Homebrew):**
```bash
# Brewfile に追加
brew "package-name"
cask "app-name"

# 適用
make packages
```

**Linux/WSL (Home Manager):**
```nix
# nix/home.nix に追加
home.packages = with pkgs; [
  package-name
];

# 適用
home-manager switch
```

---

## 関連ドキュメント

- [新規PCセットアップガイド](new-pc-setup.md)
- [Zellij ガイド](zellij.md)
- [chezmoi 公式ドキュメント](https://www.chezmoi.io/user-guide/command-overview/)
