# dotfiles

macOS用の開発環境設定ファイル。

## 主なツール

| ツール | 説明 |
|--------|------|
| **Alacritty** | GPU対応の高速ターミナルエミュレータ |
| **Zellij** | モダンなターミナルマルチプレクサ（tmux代替） |
| **Sheldon** | 高速なzshプラグインマネージャー |
| **zoxide** | スマートなディレクトリジャンプ |
| **fzf** | ファジーファインダー |
| **ghq** | リポジトリ管理 |
| **eza** | モダンなls代替 |
| **bat** | シンタックスハイライト付きcat |
| **ripgrep** | 高速grep |
| **fd** | 高速find |

## クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# セットアップを実行
./init.sh
```

## 手動インストール

```bash
# Homebrewをインストール（未インストールの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# パッケージをインストール
brew bundle --file=~/dotfiles/Brewfile

# シンボリックリンクを作成
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.config/alacritty ~/.config/alacritty
ln -sf ~/dotfiles/.config/zellij ~/.config/zellij
ln -sf ~/dotfiles/.config/sheldon ~/.config/sheldon

# シェルを再読み込み
source ~/.zshrc
```

## ディレクトリ構成

```
dotfiles/
├── init.sh                    # セットアップスクリプト
├── Brewfile                   # Homebrewパッケージ一覧
├── .zshrc                     # zsh設定
├── .gitconfig                 # Git設定
├── .vimrc                     # Vim設定
├── bin/
│   └── toggle_opacity         # Alacritty透過切り替え
├── zsh/
│   ├── tools.zsh              # zoxide/fzf/ghq設定
│   ├── peco.zsh
│   ├── fzf-worktree.zsh
│   ├── mac.zsh
│   └── alias/
│       ├── common_alias.zsh
│       └── mac_alias.zsh
└── .config/
    ├── alacritty/
    │   └── alacritty.toml     # Alacritty設定
    ├── zellij/
    │   └── config.kdl         # Zellij設定
    ├── sheldon/
    │   └── plugins.toml       # Sheldonプラグイン
    └── nvim/                  # Neovim設定
```

## キーバインド

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
| `fbr` | fzfでgitブランチ切り替え |

### Alacritty

| キー | 機能 |
|------|------|
| `Cmd+Return` | フルスクリーン切り替え |
| `Cmd+U` | 透過切り替え（Hammerspoon経由） |
| `Cmd++/-/0` | フォントサイズ変更 |
| `Ctrl+Shift+Space` | Viモード |

## エイリアス

```bash
# Zellij
zj      # zellij
zja     # zellij attach
zjl     # zellij list-sessions
zjk     # zellij kill-session
zs      # セッションに接続 or 新規作成

# エディタ
vi/vim  # nvim
view    # nvim -R
```

## フォント

Alacrittyで使用するフォント（HackGen Nerd Font）をインストール：

```bash
brew tap homebrew/cask-fonts
brew install --cask font-hackgen-nerd
```

## Hammerspoon設定（オプション）

`Cmd+U`でAlacrittyの透過を切り替えるには、Hammerspoonをインストールして設定：

```bash
brew install --cask hammerspoon
```

`~/.hammerspoon/init.lua`:

```lua
hs.hotkey.bind({ "cmd" }, "U", function()
  hs.execute("toggle_opacity", true)
end)
```

## プラグイン管理

### Sheldon

```bash
# プラグインを更新
sheldon lock --update

# 設定を確認
cat ~/.config/sheldon/plugins.toml
```

### プラグイン一覧

- **zsh-autosuggestions** - コマンド提案
- **zsh-syntax-highlighting** - シンタックスハイライト
- **zsh-completions** - 追加の補完
- **zsh-history-substring-search** - 履歴検索

## トラブルシューティング

### ツールが見つからない

```bash
# 不足しているツールを確認
./init.sh

# 手動でインストール
brew install <tool_name>
```

### sheldonが動かない

```bash
# プラグインをロック
sheldon lock

# キャッシュをクリア
rm -rf ~/.local/share/sheldon
sheldon lock
```

### Alacrittyのフォントが表示されない

```bash
# フォントキャッシュを更新
fc-cache -fv

# フォントを確認
fc-list | grep -i hackgen
```
