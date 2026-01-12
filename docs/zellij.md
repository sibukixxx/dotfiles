# Zellij 使い方ガイド

Zellij は Rust 製のモダンなターミナルマルチプレクサ。tmux の代替として使える。

## インストール

```bash
# macOS (Homebrew)
brew install zellij

# Cargo
cargo install --locked zellij

# Nix
nix-env -i zellij
```

## 基本的な起動

```bash
# 新規セッション開始
zellij

# 名前付きセッション
zellij -s my-session

# セッション一覧
zellij list-sessions
zellij ls

# 既存セッションにアタッチ
zellij attach my-session
zellij a my-session

# デタッチ中のセッションにアタッチ（なければ新規作成）
zellij attach -c my-session
```

## キーバインド

デフォルトのプレフィックスキーは `Ctrl + <key>`。

### モード切り替え

| キー | 説明 |
|------|------|
| `Ctrl + p` | Pane モード |
| `Ctrl + t` | Tab モード |
| `Ctrl + n` | Resize モード |
| `Ctrl + h` | Move モード |
| `Ctrl + s` | Scroll モード |
| `Ctrl + o` | Session モード |
| `Ctrl + g` | Locked モード（キーバインド無効化） |
| `Esc` / `Enter` | Normal モードに戻る |

### Pane 操作 (Ctrl + p → ...)

| キー | 説明 |
|------|------|
| `n` | 新規ペイン（下に分割） |
| `d` | 新規ペイン（右に分割） |
| `x` | 現在のペインを閉じる |
| `f` | ペインをフルスクリーン切り替え |
| `z` | ペインをフレーム表示切り替え |
| `w` | フローティングペイン切り替え |
| `e` | ペイン内容を外部エディタで編集 |
| `c` | ペイン名を変更 |
| `h/j/k/l` or `←/↓/↑/→` | ペイン間移動 |

### Tab 操作 (Ctrl + t → ...)

| キー | 説明 |
|------|------|
| `n` | 新規タブ |
| `x` | 現在のタブを閉じる |
| `r` | タブ名を変更 |
| `h/l` or `←/→` | タブ間移動 |
| `1-9` | タブ番号で移動 |
| `s` | 同期モード切り替え（全ペインに同時入力） |
| `b` | ペイン配置を切り替え |

### Resize モード (Ctrl + n → ...)

| キー | 説明 |
|------|------|
| `h/j/k/l` or `←/↓/↑/→` | ペインサイズ変更 |
| `+/-` | サイズ増減 |
| `=` | サイズを均等化 |

### Scroll モード (Ctrl + s → ...)

| キー | 説明 |
|------|------|
| `j/k` or `↓/↑` | 1行スクロール |
| `d/u` | 半ページスクロール |
| `Page Down/Up` | 1ページスクロール |
| `s` | テキスト検索開始 |
| `e` | スクロールバッファをエディタで開く |

### Session 操作 (Ctrl + o → ...)

| キー | 説明 |
|------|------|
| `d` | セッションからデタッチ |
| `w` | セッションマネージャー表示 |
| `c` | セッションマネージャーから設定 |

## よく使うショートカット（Normal モード）

| キー | 説明 |
|------|------|
| `Alt + n` | 新規ペイン |
| `Alt + h/j/k/l` | ペイン間移動 |
| `Alt + +/-/=` | ペインサイズ調整 |
| `Alt + [/]` | 前後のタブに移動 |

## レイアウト

```bash
# 組み込みレイアウトで起動
zellij --layout compact
zellij --layout default
zellij --layout strider

# カスタムレイアウトファイルを指定
zellij --layout ~/.config/zellij/layouts/my-layout.kdl
```

### レイアウトファイル例 (KDL形式)

```kdl
// ~/.config/zellij/layouts/dev.kdl
layout {
    pane size=1 borderless=true {
        plugin location="tab-bar"
    }
    pane split_direction="vertical" {
        pane
        pane split_direction="horizontal" {
            pane
            pane
        }
    }
    pane size=2 borderless=true {
        plugin location="status-bar"
    }
}
```

## 設定ファイル

設定ファイルの場所: `~/.config/zellij/config.kdl`

### 設定ファイル例

```kdl
// ~/.config/zellij/config.kdl

// テーマ設定
theme "dracula"

// デフォルトモード
default_mode "normal"

// マウスサポート
mouse_mode true

// スクロールバッファサイズ
scroll_buffer_size 10000

// コピー時のコマンド（macOS）
copy_command "pbcopy"

// 簡略化されたUI
simplified_ui true

// ペインフレーム
pane_frames false

// デフォルトレイアウト
default_layout "compact"

// セッション名を自動設定
session_name "dev"

// キーバインドのカスタマイズ
keybinds {
    normal {
        // Ctrl+a をプレフィックスに（tmux風）
        bind "Ctrl a" { SwitchToMode "tmux"; }
    }
    tmux {
        bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }
        bind "|" { NewPane "Right"; SwitchToMode "Normal"; }
        bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
        bind "c" { NewTab; SwitchToMode "Normal"; }
        bind "x" { CloseFocus; SwitchToMode "Normal"; }
    }
}
```

## プラグイン

```bash
# プラグイン一覧表示
zellij plugin -- list

# セッションマネージャープラグイン（標準搭載）
# Ctrl + o → w で起動
```

### よく使うプラグイン

- `tab-bar`: タブバー表示
- `status-bar`: ステータスバー表示
- `strider`: ファイルツリー
- `session-manager`: セッション管理

## Tips

### tmux から移行する場合

```kdl
// config.kdl に追加
keybinds {
    unbind "Ctrl b"  // tmux のデフォルトプレフィックス解除
}
```

### 起動を高速化

```bash
# バックグラウンドでサーバー起動
zellij setup --generate-auto-start bash >> ~/.bashrc
zellij setup --generate-auto-start zsh >> ~/.zshrc
```

### セッション自動保存・復元

zellij はデフォルトでセッションを自動保存する。デタッチ後も状態が保持される。

### フローティングペイン

`Ctrl + p → w` でフローティングペインを表示/非表示。一時的なコマンド実行に便利。

## コマンドリファレンス

```bash
zellij --help              # ヘルプ表示
zellij options             # 利用可能なオプション
zellij setup --dump-config # デフォルト設定を出力
zellij setup --dump-layout default  # デフォルトレイアウトを出力
zellij kill-session <name> # セッション削除
zellij kill-all-sessions   # 全セッション削除
zellij action <action>     # アクション実行（スクリプト用）
```

## 参考リンク

- [公式サイト](https://zellij.dev/)
- [GitHub](https://github.com/zellij-org/zellij)
- [ドキュメント](https://zellij.dev/documentation/)
