# トラブルシューティング

よくある問題とその解決策をまとめています。

---

## 目次

- [診断コマンド](#診断コマンド)
- [chezmoi 関連](#chezmoi-関連)
- [シェル・プラグイン関連](#シェルプラグイン関連)
- [ターミナル関連](#ターミナル関連)
- [Git・GitHub 関連](#gitgithub-関連)
- [パッケージ管理](#パッケージ管理)
- [SSH・暗号化関連](#ssh暗号化関連)
- [パフォーマンス問題](#パフォーマンス問題)
- [プラットフォーム固有の問題](#プラットフォーム固有の問題)

---

## 診断コマンド

問題が発生した場合、まず以下のコマンドで状態を確認してください。

### セットアップ検証

```bash
# 全体的なセットアップ状態を確認
verify-setup

# または make 経由で
make verify
```

### chezmoi 診断

```bash
# chezmoi の設定診断
chezmoi doctor

# 管理対象ファイル一覧
chezmoi managed

# ファイルの状態を検証
chezmoi verify

# テンプレートデータを確認
chezmoi data
```

### システム情報

```bash
# OS 情報
uname -a

# シェル確認
echo $SHELL
$SHELL --version

# Homebrew 診断（macOS）
brew doctor

# Nix 診断（Linux）
nix doctor
```

---

## chezmoi 関連

### chezmoi apply が失敗する

#### 症状
```
chezmoi: error: ...
```

#### 解決策

**1. 差分を確認**
```bash
chezmoi diff
```

**2. 詳細ログで実行**
```bash
chezmoi apply -v
# さらに詳細
chezmoi apply -vv
```

**3. 特定のファイルだけ適用**
```bash
chezmoi apply ~/.zshrc
```

**4. 強制適用（注意: 上書きされます）**
```bash
chezmoi apply --force
```

### run_once スクリプトを再実行したい

#### 症状
初回実行済みのスクリプトを再度実行したい。

#### 解決策

```bash
# スクリプト実行状態をリセット
chezmoi state delete-bucket --bucket=scriptState

# 特定のスクリプトだけリセット
chezmoi state delete --bucket=scriptState --key=<script-name>

# 再適用
chezmoi apply
```

### テンプレートエラー

#### 症状
```
chezmoi: error: template: ...
```

#### 解決策

**1. テンプレートデータを確認**
```bash
chezmoi data
```

**2. テンプレートをデバッグ**
```bash
# 展開結果を表示（適用せず）
chezmoi cat ~/.zshrc
```

**3. よくあるテンプレートミス**
```go
// ❌ 間違い: 変数が未定義
{{ .undefinedVar }}

// ✅ 正解: デフォルト値を設定
{{ .undefinedVar | default "default-value" }}

// ❌ 間違い: 空白の扱い
{{ if eq .os "darwin" }}
content
{{ end }}

// ✅ 正解: 空白を制御
{{- if eq .chezmoi.os "darwin" }}
content
{{- end }}
```

### chezmoi init 時にエラー

#### 症状
```
chezmoi: error: failed to init
```

#### 解決策

**1. 既存の状態をクリア**
```bash
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
```

**2. 再初期化**
```bash
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git
```

---

## シェル・プラグイン関連

### Sheldon が動かない

#### 症状
- プラグインが読み込まれない
- `sheldon: command not found`
- シェル起動時にエラー

#### 解決策

**1. Sheldon のインストール確認**
```bash
which sheldon
sheldon --version
```

**2. キャッシュをクリア**
```bash
rm -rf ~/.local/share/sheldon
rm -rf ~/.cache/sheldon
```

**3. プラグインを再ロック**
```bash
sheldon lock
```

**4. 手動で source**
```bash
eval "$(sheldon source)"
```

### zsh の起動が遅い

#### 症状
新しいターミナルを開くのに時間がかかる。

#### 解決策

**1. プロファイリング**
```bash
# 起動時間を計測
time zsh -i -c exit

# 詳細なプロファイリング
zsh -xv 2>&1 | ts -i "%.s" > /tmp/zsh-startup.log
```

**2. よくある原因と対策**

| 原因 | 対策 |
|------|------|
| プラグインが多い | 不要なプラグインを削除 |
| nvm/rbenv の初期化 | 遅延読み込みを使用 |
| compinit が遅い | キャッシュを有効化 |
| PATH の重複 | 重複を削除 |

**3. 遅延読み込みの例（zsh-defer）**
```bash
# ~/.zshrc
zsh-defer source ~/.config/zsh/heavy-plugin.zsh
```

### 補完が効かない

#### 症状
Tab 補完が動作しない。

#### 解決策

**1. 補完システムを再初期化**
```bash
rm -f ~/.zcompdump*
compinit
```

**2. fpath を確認**
```bash
echo $fpath
```

**3. 補完関数の存在確認**
```bash
# 例: git の補完
which _git
```

### エイリアスが効かない

#### 症状
設定したエイリアスが使えない。

#### 解決策

**1. エイリアスの確認**
```bash
alias | grep "target-alias"
```

**2. source 順序を確認**
```bash
# ~/.zshrc でエイリアスファイルが読み込まれているか確認
grep -r "alias" ~/.config/zsh/
```

**3. 関数との競合確認**
```bash
type ls  # alias か function か確認
```

---

## ターミナル関連

### フォントアイコンが文字化けする

#### 症状
- アイコンが `□` や `?` で表示される
- Nerd Font のアイコンが表示されない

#### 解決策

**1. フォントのインストール確認**
```bash
# macOS
brew list --cask | grep font

# Linux
fc-list | grep -i "hackgen\|nerd"
```

**2. フォントキャッシュを更新**
```bash
fc-cache -fv
```

**3. ターミナルのフォント設定を確認**
- Ghostty: `~/.config/ghostty/config` の `font-family`
- Alacritty: `~/.config/alacritty/alacritty.toml` の `font.normal.family`

**4. フォントを再インストール**
```bash
# macOS
brew reinstall --cask font-hackgen-nerd

# Linux
# HackGen Nerd Font をダウンロードして ~/.local/share/fonts/ に配置
fc-cache -fv
```

### Ghostty が起動しない

#### 症状
Ghostty アプリが起動しない、またはクラッシュする。

#### 解決策

**1. 設定ファイルの構文確認**
```bash
# 設定ファイルの場所
cat ~/.config/ghostty/config
```

**2. 設定をリセット**
```bash
mv ~/.config/ghostty/config ~/.config/ghostty/config.bak
# デフォルト設定で起動を試行
```

**3. ログを確認**
```bash
# macOS
open -a Console
# Ghostty で検索
```

### Alacritty の透過が効かない

#### 症状
背景が透過しない。

#### 解決策

**1. 設定を確認**
```toml
# ~/.config/alacritty/alacritty.toml
[window]
opacity = 0.9
```

**2. コンポジターを確認（Linux）**
- Wayland: 通常はサポート
- X11: コンポジターが必要（picom など）

### Zellij のキーバインドが効かない

#### 症状
`Ctrl+x` などのキーバインドが反応しない。

#### 解決策

**1. モードを確認**
Zellij は複数のモードがあり、現在のモードによってキーバインドが異なります。

**2. 設定を確認**
```bash
cat ~/.config/zellij/config.kdl
```

**3. デフォルト設定で試す**
```bash
zellij --config /dev/null
```

---

## Git・GitHub 関連

### SSH 接続ができない

#### 症状
```
Permission denied (publickey).
```

#### 解決策

**1. SSH キーの存在確認**
```bash
ls -la ~/.ssh/
```

**2. SSH エージェントにキーを追加**
```bash
# エージェント起動
eval "$(ssh-agent -s)"

# キーを追加
ssh-add ~/.ssh/id_ed25519  # または id_rsa
```

**3. 接続テスト**
```bash
ssh -T git@github.com
```

**4. 詳細なデバッグ**
```bash
ssh -vT git@github.com
```

### gh コマンドが認証エラー

#### 症状
```
gh: error: authentication required
```

#### 解決策

**1. 認証状態を確認**
```bash
gh auth status
```

**2. 再認証**
```bash
gh auth login
```

**3. トークンをリフレッシュ**
```bash
gh auth refresh
```

### git config が効かない

#### 症状
設定した git config が反映されない。

#### 解決策

**1. 設定の優先順位を確認**
```bash
# すべての設定とソースを表示
git config --list --show-origin
```

**2. XDG 設定を確認**
```bash
# XDG 準拠の場所
cat ~/.config/git/config

# 従来の場所
cat ~/.gitconfig
```

---

## パッケージ管理

### brew bundle が失敗する

#### 症状
```
Error: ...
```

#### 解決策

**1. Homebrew を更新**
```bash
brew update
```

**2. 問題のあるパッケージを特定**
```bash
brew bundle --file=~/dotfiles/Brewfile --verbose
```

**3. 個別にインストール**
```bash
brew install <package-name>
```

**4. キャッシュをクリア**
```bash
brew cleanup
```

### mas（Mac App Store CLI）が動かない

#### 症状
```
Error: Not signed in
```

#### 解決策

**1. App Store にサインイン**
App Store.app を開いてサインインしてください。

**2. mas の状態確認**
```bash
mas account
```

### home-manager switch が失敗する（Linux）

#### 症状
```
error: ...
```

#### 解決策

**1. Nix チャンネルを更新**
```bash
nix-channel --update
```

**2. 詳細ログで実行**
```bash
home-manager switch --show-trace
```

**3. ガベージコレクション**
```bash
nix-collect-garbage -d
```

---

## SSH・暗号化関連

### age 復号が失敗する

#### 症状
```
age: error: no identity matched any of the recipients
```

#### 解決策

**1. key.txt の存在確認**
```bash
ls -la ~/.config/chezmoi/key.txt
```

**2. key.txt のパーミッション**
```bash
chmod 600 ~/.config/chezmoi/key.txt
```

**3. key.txt の内容確認**
```bash
# AGE-SECRET-KEY- で始まっているか確認
head -c 20 ~/.config/chezmoi/key.txt
```

**4. chezmoi の暗号化設定を確認**
```bash
chezmoi data | grep -A5 encryption
```

### SSH キーが復元されない

#### 症状
`chezmoi apply` 後も `~/.ssh/` にキーがない。

#### 解決策

**1. 暗号化ファイルの存在確認**
```bash
ls ~/dotfiles/encrypted_*
```

**2. 手動で復号**
```bash
chezmoi apply ~/.ssh/
```

**3. age の状態確認**
```bash
which age
age --version
```

---

## パフォーマンス問題

### chezmoi apply が遅い

#### 症状
`chezmoi apply` に時間がかかる。

#### 解決策

**1. run_* スクリプトを確認**
```bash
# どのスクリプトが実行されるか確認
chezmoi apply --dry-run -v
```

**2. 特定のファイルだけ適用**
```bash
chezmoi apply ~/.zshrc
```

### eza/bat などのツールが遅い

#### 症状
`ls` や `cat` の応答が遅い。

#### 解決策

**1. Git 統合を無効化（eza）**
```bash
# --git オプションを外す
alias ls='eza --icons'
```

**2. キャッシュを確認（bat）**
```bash
bat cache --clear
bat cache --build
```

---

## プラットフォーム固有の問題

### macOS

#### Rosetta 2 が必要なツールがある

```bash
# Rosetta 2 のインストール
softwareupdate --install-rosetta --agree-to-license
```

#### Xcode Command Line Tools のエラー

```bash
# 再インストール
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

#### Karabiner-Elements が動かない

1. システム環境設定 → セキュリティとプライバシー → 入力監視
2. Karabiner-Elements を許可

### Linux

#### locale エラー

```bash
# ロケール設定
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
```

#### 権限エラー（/usr/local）

```bash
# 所有権を変更
sudo chown -R $(whoami) /usr/local
```

### WSL

#### Windows ファイルシステムが遅い

```bash
# WSL 内のファイルシステムを使用
cd ~  # /mnt/c/ ではなく
```

#### クリップボード連携

```bash
# ~/.zshrc に追加
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard"'
```

#### ネットワークが遅い

```bash
# /etc/wsl.conf に追加
[network]
generateResolvConf = false
```

---

## 問題が解決しない場合

### 情報収集

```bash
# システム情報
uname -a
echo $SHELL
$SHELL --version

# chezmoi 情報
chezmoi doctor
chezmoi data

# 設定ファイル
cat ~/.zshrc | head -50
```

### Issue を作成

上記の情報を添えて Issue を作成してください:
https://github.com/YOUR_USERNAME/dotfiles/issues

### クリーンインストール

最終手段として、設定をリセットできます:

```bash
# 1. chezmoi の状態をクリア
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi/chezmoistate.boltdb

# 2. 再初期化
chezmoi init --apply YOUR_GITHUB_USERNAME
```

---

## 関連ドキュメント

- [README.md](../README.md) - プロジェクト概要
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ解説
- [new-pc-setup.md](new-pc-setup.md) - 新規 PC セットアップガイド
- [chezmoi トラブルシューティング](https://www.chezmoi.io/user-guide/frequently-asked-questions/)
