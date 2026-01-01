# dotfiles

macOS / Linux / WSL 対応の開発環境設定ファイル。

## 特徴

- **マルチプラットフォーム対応**: macOS, Linux, WSL をサポート
- **モダンなCLIツール**: Rust製の高速ツール群（eza, bat, ripgrep, fd, zoxide）
- **プラグイン管理**: Sheldon による高速なzshプラグイン管理
- **ターミナルマルチプレクサ**: Zellij（tmux代替）
- **パッケージマネージャ**: macOS は Homebrew、Linux/WSL は Nix + Home Manager

## 主なツール

| ツール | 説明 | 代替 |
|--------|------|------|
| **Ghostty** | GPU対応の高速ターミナルエミュレータ（推奨） | - |
| **Alacritty** | GPU対応のターミナルエミュレータ | - |
| **Zellij** | モダンなターミナルマルチプレクサ | tmux |
| **Sheldon** | 高速なzshプラグインマネージャー | zinit |
| **zoxide** | スマートなディレクトリジャンプ | z, autojump |
| **fzf** | ファジーファインダー | peco |
| **ghq** | リポジトリ管理 | - |
| **eza** | モダンなls | ls |
| **bat** | シンタックスハイライト付きcat | cat |
| **ripgrep** | 高速grep | grep |
| **fd** | 高速find | find |
| **Neovim** | モダンなVim | Vim |

## クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# セットアップを実行（自動でOS判定）
./init.sh
```

セットアップスクリプトは以下を自動実行します：

| OS | パッケージマネージャ | インストールされるもの |
|----|----------------------|------------------------|
| macOS | Homebrew | Brewfile のパッケージ |
| Linux/WSL | Nix + Home Manager | home.nix で定義されたパッケージ |
| 共通 | Cargo (Rust) | ripgrep, fd, bat, eza, zoxide, sheldon, zellij |

## ディレクトリ構成

```
dotfiles/
├── init.sh                    # 統合セットアップスクリプト
├── dotfilesLink.sh            # シンボリックリンク作成スクリプト
├── Brewfile                   # Homebrewパッケージ一覧（macOS）
├── .zshrc                     # zsh設定（メイン）
├── .vimrc                     # Vim設定
├── .tmux.conf                 # tmux設定（レガシー）
├── bin/
│   ├── toggle_opacity         # Alacritty透過切り替え
│   └── git-localinfo          # Git ローカル情報表示
├── zsh/
│   ├── tools.zsh              # zoxide/fzf/ghq 統合設定
│   ├── peco.zsh               # peco関連（フォールバック）
│   ├── fzf-worktree.zsh       # git worktree + fzf
│   ├── mac.zsh                # macOS固有設定
│   ├── linux.zsh              # Linux固有設定
│   └── alias/
│       ├── common_alias.zsh   # 共通エイリアス
│       ├── mac_alias.zsh      # macOS用エイリアス
│       └── linux_alias.zsh    # Linux用エイリアス
├── nix/
│   └── home.nix               # Home Manager設定（Linux/WSL）
└── .config/
    ├── ghostty/
    │   └── config             # Ghostty設定
    ├── alacritty/
    │   └── alacritty.toml     # Alacritty設定
    ├── zellij/
    │   └── config.kdl         # Zellij設定
    ├── sheldon/
    │   └── plugins.toml       # Sheldonプラグイン
    ├── nvim/                   # Neovim設定
    ├── git/
    │   └── config             # Git設定（XDG準拠）
    └── karabiner/
        └── karabiner.json     # Karabiner-Elements設定
```

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

| キー | 機能 |
|------|------|
| `Ctrl+x \|` | 縦分割 |
| `Ctrl+x -` | 横分割 |
| `Ctrl+x x` | ペインを閉じる |
| `Ctrl+x z` | ペインを最大化 |
| `Ctrl+x h/j/k/l` | ペイン移動 |
| `Ctrl+x H/J/K/L` | ペインリサイズ |
| `Ctrl+x c` | 新規タブ |
| `Ctrl+x n/p` | 次/前のタブ |
| `Ctrl+x 1-9` | タブ番号で移動 |
| `Ctrl+x d` | デタッチ |
| `Ctrl+x w` | セッションマネージャ |
| `Ctrl+x [` | スクロールモード |
| `Ctrl+x e` | ペイン同期（sync） |
| `Ctrl+x f` | フローティングペイン |

### zsh

| キー/コマンド | 機能 |
|---------------|------|
| `Ctrl+G` | ghqリポジトリをfzfで選択 |
| `Ctrl+R` | 履歴をfzfで検索 |
| `z <dir>` | zoxideでスマートジャンプ |
| `zi` | zoxideインタラクティブ選択 |
| `gcd` | ghqリポジトリに移動 |
| `gg <repo>` | ghq getして自動cd |
| `fe` | fzfでファイル選択して編集 |
| `fcd` | fzfでディレクトリ選択してcd |
| `fbr` | fzfでgitブランチ切り替え |
| `flog` | fzfでgitログを閲覧 |

### Alacritty

| キー | 機能 |
|------|------|
| `Cmd+Enter` | フルスクリーン切り替え |
| `Cmd+U` | 透過切り替え（Hammerspoon経由） |
| `Cmd++/-/0` | フォントサイズ変更 |
| `Ctrl+Shift+Space` | Viモード |

## エイリアス

### Zellij

```bash
zj      # zellij
zja     # zellij attach
zjl     # zellij list-sessions
zjk     # zellij kill-session
zs      # セッションに接続 or 新規作成
```

### モダンCLIツール（自動置換）

```bash
ls      # → eza --icons
ll      # → eza -la --icons --git
lt      # → eza --tree --icons --level=2
cat     # → bat --paging=never
find    # → fd
grep    # → rg
```

### Git

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
view    # nvim -R
```

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

### プロファイル

Sheldon は OS ごとに異なるプラグインを読み込みます：

```bash
# macOS
sheldon --profile macos source

# Linux
sheldon --profile linux source
```

## マルチプラットフォーム対応

### macOS

```bash
# Homebrew でパッケージ管理
brew bundle --file=~/dotfiles/Brewfile

# Rust ツールは cargo でインストール
cargo install ripgrep fd-find bat eza zoxide sheldon zellij
```

### Linux / WSL

```bash
# Nix + Home Manager でパッケージ管理
# init.sh が自動で設定

# 手動インストール
sh <(curl -L https://nixos.org/nix/install) --daemon
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# 設定を適用
home-manager switch
```

## フォント

Ghostty / Alacritty で使用するフォント（HackGen Nerd Font）をインストール：

```bash
# macOS
brew tap homebrew/cask-fonts
brew install --cask font-hackgen-nerd

# または直接ダウンロード
# https://github.com/yuru7/HackGen/releases
```

## オプション設定

### Hammerspoon（Alacritty透過切り替え）

`Cmd+U` で Alacritty の透過を切り替え：

```bash
brew install --cask hammerspoon
```

`~/.hammerspoon/init.lua`:

```lua
hs.hotkey.bind({ "cmd" }, "U", function()
  hs.execute("toggle_opacity", true)
end)
```

### Karabiner-Elements

キーボードカスタマイズ設定が `.config/karabiner/` にあります。

## トラブルシューティング

### ツールが見つからない

```bash
# 不足しているツールを確認
./init.sh

# macOS: Homebrew で手動インストール
brew install <tool_name>

# Linux/WSL: Home Manager を再適用
home-manager switch
```

### sheldon が動かない

```bash
# プラグインをロック
sheldon lock

# キャッシュをクリア
rm -rf ~/.local/share/sheldon
sheldon lock
```

### フォントが表示されない

```bash
# フォントキャッシュを更新
fc-cache -fv

# フォントを確認
fc-list | grep -i hackgen
```

### zsh プロンプトに git ブランチが表示されない

```bash
# .zshrc に以下があることを確認
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn hg
```

### シンボリックリンクの再作成

```bash
./dotfilesLink.sh
```

## 手動インストール

init.sh を使わずに手動でセットアップする場合：

```bash
# 1. Homebrew をインストール（macOS）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. パッケージをインストール
brew bundle --file=~/dotfiles/Brewfile

# 3. Rust ツールをインストール
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install ripgrep fd-find bat eza zoxide sheldon zellij

# 4. シンボリックリンクを作成
./dotfilesLink.sh

# 5. Sheldon プラグインをロック
sheldon lock

# 6. シェルを再読み込み
source ~/.zshrc
```

## ライセンス

MIT
