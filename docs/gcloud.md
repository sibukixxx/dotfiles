# gcloud 接続先管理

gcloud の接続先（アカウント・プロジェクト・リージョン）を名前付き configuration として管理し、fzf やディレクトリ連動で素早く切り替える。

---

## 概要

| 機能 | コマンド | スコープ |
|------|----------|----------|
| fzf で configuration を切り替え | `gsc` | グローバル（全ターミナル） |
| ディレクトリ移動で自動切り替え | 自動（`.gcloud-config` ファイル） | per-shell（そのターミナルのみ） |
| プロンプトに configuration 名を表示 | 自動 | - |

---

## セットアップ

### 1. gcloud configuration を作成

```bash
# configuration を作成して切り替え
gcloud config configurations create company-a-prod

# アカウント・プロジェクト・リージョンをセット
gcloud config set account user@company-a.com
gcloud config set project my-prod-project-123
gcloud config set compute/region asia-northeast1
```

複数の接続先がある場合は、それぞれ configuration を作成する：

```bash
# 本番環境
gcloud config configurations create company-a-prod
gcloud config set account user@company-a.com
gcloud config set project company-a-prod-12345
gcloud config set compute/region asia-northeast1

# 開発環境
gcloud config configurations create company-a-dev
gcloud config set account user@company-a.com
gcloud config set project company-a-dev-67890
gcloud config set compute/region asia-northeast1

# 別のクライアント
gcloud config configurations create client-b-staging
gcloud config set account contractor@client-b.com
gcloud config set project client-b-staging-99999
gcloud config set compute/region us-central1
```

### 2. プロジェクトディレクトリに `.gcloud-config` を配置

```bash
# configuration 名をファイルに書くだけ
echo "company-a-prod" > ~/workspace/github.com/company-a/service-x/.gcloud-config

echo "client-b-staging" > ~/workspace/github.com/client-b/app/.gcloud-config
```

> `.gcloud-config` は `.gitignore` に追加することを推奨（個人のアカウント設定のため）。

---

## 使い方

### fzf スイッチャー（`gsc`）

```bash
gsc
```

configuration 一覧が fzf で表示される。右ペインにアカウント・プロジェクト・リージョンの詳細がプレビューされる。

選択すると `gcloud config configurations activate` が実行され、**グローバルに**（全ターミナルで）切り替わる。

### ディレクトリ自動切り替え

`.gcloud-config` ファイルがあるディレクトリ（またはその配下）に `cd` すると自動的に切り替わる：

```bash
$ cd ~/workspace/github.com/company-a/service-x
gcloud: config -> company-a-prod
# プロンプト: [@mac service-x] (gcloud:company-a-prod) $

$ cd ~/workspace/github.com/client-b/app
gcloud: config -> client-b-staging
# プロンプト: [@mac app] (gcloud:client-b-staging) $

$ cd ~
# gcloud 表示が消える（グローバルのデフォルト configuration に戻る）
```

ディレクトリ自動切り替えは `CLOUDSDK_ACTIVE_CONFIG_NAME` 環境変数を使用するため：

- **そのターミナルだけ**に影響する（他のターミナルには影響しない）
- サブプロセスを起動しないため**高速**
- ディレクトリを離れると自動で**解除**される

### プロンプト表示

configuration が有効な場合、プロンプトに `(gcloud:configuration名)` がシアンで表示される。

---

## 仕組み

```
┌─────────────────────────────────────────────────────────┐
│  gsc（手動切り替え）                                      │
│  → gcloud config configurations activate <name>         │
│  → グローバルに反映（~/.config/gcloud/properties）       │
├─────────────────────────────────────────────────────────┤
│  .gcloud-config（ディレクトリ自動切り替え）                │
│  → export CLOUDSDK_ACTIVE_CONFIG_NAME=<name>            │
│  → per-shell で即座に切り替え                             │
│  → cd で離れると unset → グローバル設定にフォールバック    │
├─────────────────────────────────────────────────────────┤
│  プロンプト表示                                           │
│  → CLOUDSDK_ACTIVE_CONFIG_NAME があれば表示               │
│  → なければ .gcloud-project（レガシー）にフォールバック    │
└─────────────────────────────────────────────────────────┘
```

---

## レガシーとの互換性

以前の `.gcloud-project` ファイルも引き続き動作する。`.gcloud-config` が見つからない場合に `.gcloud-project` を参照し、プロジェクト名をプロンプトに表示する。

ただし `.gcloud-project` はプロンプト表示のみで、自動切り替えは行わない。新しいプロジェクトでは `.gcloud-config` の使用を推奨。

| ファイル | 自動切り替え | プロンプト表示 | 推奨 |
|----------|:----------:|:----------:|:---:|
| `.gcloud-config` | o | o | o |
| `.gcloud-project` | x | o | - |

---

## 関連ファイル

| ファイル | 説明 |
|----------|------|
| `~/.config/zsh/gcloud.zsh` | gsc 関数、chpwd フック |
| `~/.zshrc` | `gcloud_project_prompt()` |
| `~/.config/sheldon/plugins.toml` | プラグイン登録 |

---

## Tips

### configuration 一覧の確認

```bash
gcloud config configurations list
```

### 現在の設定を確認

```bash
gcloud config list
```

### configuration の削除

```bash
gcloud config configurations delete old-config
```

### 特定の configuration のプロパティを変更

```bash
gcloud config configurations activate company-a-prod
gcloud config set compute/region us-west1
```
