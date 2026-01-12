# dotfiles

macOS / Linux / WSL 対応の開発環境設定ファイル。[chezmoi](https://www.chezmoi.io/) で管理。

## 特徴

- **chezmoi による管理**: テンプレート機能、マシン固有設定、安全なシークレット管理
- **マルチプラットフォーム対応**: macOS, Linux, WSL をサポート
- **モダンなCLIツール**: Rust製の高速ツール群（eza, bat, ripgrep, fd, zoxide）
- **プラグイン管理**: Sheldon による高速なzshプラグイン管理
- **ターミナルマルチプレクサ**: Zellij（tmux代替）
- **パッケージマネージャ**: macOS は Homebrew、Linux/WSL は Nix + Home Manager
- **リポジトリ一括クローン**: 初期セットアップ時に全GitHubリポジトリを自動クローン

## 主なツール

| ツール | 説明 | 代替 |
|--------|------|------|
| **chezmoi** | dotfiles マネージャー | stow, yadm |
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

### 新規インストール（推奨）

```bash
# chezmoi で直接インストール（ワンライナー）
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME

# または手動で
brew install chezmoi  # macOS
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git
chezmoi apply
```

### 既存マシンの更新

```bash
chezmoi update
```

**詳細なセットアップガイド**: [docs/new-pc-setup.md](docs/new-pc-setup.md)

## chezmoi コマンド

| コマンド | 説明 |
|----------|------|
| `chezmoi init <repo>` | リポジトリからdotfilesを初期化 |
| `chezmoi apply` | 変更を適用 |
| `chezmoi diff` | 適用前の差分を確認 |
| `chezmoi edit <file>` | ファイルを編集 |
| `chezmoi update` | リモートから更新を取得して適用 |
| `chezmoi cd` | ソースディレクトリに移動 |
| `chezmoi add <file>` | ファイルを管理対象に追加 |
| `chezmoi managed` | 管理対象ファイル一覧 |
| `chezmoi data` | テンプレートデータを表示 |

## ディレクトリ構成

```
dotfiles/
├── .chezmoi.toml.tmpl         # chezmoi設定テンプレート
├── .chezmoiignore             # 無視ファイル
├── run_once_before_*.sh.tmpl  # インストール前スクリプト
├── run_once_after_*.sh.tmpl   # インストール後スクリプト
├── Brewfile                   # Homebrewパッケージ一覧（macOS）
├── dot_zshrc                  # ~/.zshrc
├── dot_vimrc                  # ~/.vimrc
├── dot_tmux.conf              # ~/.tmux.conf（レガシー）
├── dot_local/
│   └── bin/
│       ├── executable_toggle_opacity   # Alacritty透過切り替え
│       ├── executable_git-localinfo    # Git ローカル情報表示
│       ├── executable_verify-setup     # セットアップ検証
│       └── executable_clone-all-repos  # 全リポジトリ一括クローン
├── dot_config/
│   ├── zsh/
│   │   ├── tools.zsh          # zoxide/fzf/ghq 統合設定
│   │   ├── peco.zsh           # peco関連（フォールバック）
│   │   ├── fzf-worktree.zsh   # git worktree + fzf
│   │   ├── mac.zsh            # macOS固有設定
│   │   ├── linux.zsh          # Linux固有設定
│   │   └── alias/
│   │       ├── common_alias.zsh
│   │       ├── mac_alias.zsh
│   │       └── linux_alias.zsh
│   ├── ghostty/
│   │   └── config             # Ghostty設定
│   ├── alacritty/
│   │   └── alacritty.toml     # Alacritty設定
│   ├── zellij/
│   │   └── config.kdl         # Zellij設定
│   ├── sheldon/
│   │   └── plugins.toml       # Sheldonプラグイン
│   ├── nvim/                   # Neovim設定
│   ├── git/
│   │   └── config             # Git設定（XDG準拠）
│   └── karabiner/              # Karabiner-Elements設定（macOS）
├── nix/
│   └── home.nix               # Home Manager設定（Linux/WSL）
└── docs/
    ├── new-pc-setup.md        # 新規PCセットアップガイド
    └── zellij.md              # Zellijガイド
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

## マルチプラットフォーム対応

### macOS

```bash
# chezmoi がすべてを自動で行います
chezmoi init --apply YOUR_GITHUB_USERNAME
```

### Linux / WSL

```bash
# chezmoi がすべてを自動で行います
# Nix + Home Manager も自動インストール
chezmoi init --apply YOUR_GITHUB_USERNAME
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

## トラブルシューティング

### chezmoi apply が失敗する

```bash
# 差分を確認
chezmoi diff

# 詳細ログで実行
chezmoi apply -v

# 強制適用（注意）
chezmoi apply --force
```

### Sheldon が動かない

```bash
# キャッシュをクリア
rm -rf ~/.local/share/sheldon
rm -rf ~/.cache/sheldon

# 再ロック
sheldon lock
```

### セットアップの検証

```bash
verify-setup
```

### シンボリックリンクの状態を確認

```bash
chezmoi managed
chezmoi verify
```

## リポジトリ管理

### 初期セットアップ時の一括クローン

chezmoi の初期セットアップ時に、GitHub の全リポジトリを `~/workspace` に自動クローンできます。

セットアップ時のプロンプト：
```
GitHub username? sibukixxx
Clone all GitHub repositories to ~/workspace? (y/n) y
```

リポジトリは ghq 形式で管理されます：
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

# または ghq で個別にクローン
ghq get github.com/sibukixxx/repo-name
```

### リポジトリへのアクセス

```bash
# fuzzy finder でリポジトリを選択
gcd

# Ctrl+G でも選択可能
# 選択後、自動的にそのディレクトリに移動
```

## 開発

### 新しいファイルを追加

```bash
# 既存ファイルをchezmoiに追加
chezmoi add ~/.some-config

# テンプレートとして追加
chezmoi add --template ~/.some-config
```

### ファイルを編集

```bash
# ソースファイルを編集
chezmoi edit ~/.zshrc

# 適用前に差分確認
chezmoi diff

# 適用
chezmoi apply
```

## ライセンス

MIT
