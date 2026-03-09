# iOS スクリーンショット自動化 詳細セットアップ手順

## 目次
1. [Fastlane インストール](#1-fastlane-インストール)
2. [プロジェクト初期化](#2-プロジェクト初期化)
3. [UITest ターゲット追加](#3-uitest-ターゲット追加)
4. [SnapshotHelper の追加](#4-snapshothelper-の追加)
5. [App Store Connect API キー取得](#5-app-store-connect-api-キー取得)
6. [初回実行チェックリスト](#6-初回実行チェックリスト)

---

## 1. Fastlane インストール

```bash
# Homebrew 経由（推奨）
brew install fastlane

# バージョン確認
fastlane --version
# → fastlane 2.x.x が表示されれば OK
```

---

## 2. プロジェクト初期化

```bash
cd /path/to/YourApp

fastlane init
# → 対話式で質問される
# "What would you like to use fastlane for?" → 4 (Manual setup) を選択
```

生成されるファイル:
```
fastlane/
├── Appfile      # Apple ID / Bundle ID
├── Fastfile     # レーン定義（空の状態）
└── Gemfile      # Ruby 依存（あれば）
```

`Snapfile` と `Deliverfile` は手動で作成する（SKILL.md のテンプレートを使用）。

---

## 3. UITest ターゲット追加

1. Xcode でプロジェクトを開く
2. `File > New > Target` を選択
3. `UI Testing Bundle` を選択
4. Product Name: `{AppName}UITests`（例: `MyAppUITests`）
5. Target to be tested: メインアプリを選択
6. Finish

---

## 4. SnapshotHelper の追加

```bash
# SnapshotHelper.swift を自動生成
fastlane snapshot --help
# → まず空打ちして helper を生成させる
fastlane snapshot 2>&1 | head -5
```

または手動で追加:
```bash
# Fastlane が提供する helper を UITest ターゲットにコピー
# 場所: ~/.gem/ruby/{version}/gems/fastlane-{version}/snapshot/lib/assets/SnapshotHelper.swift
```

Xcode で:
1. `SnapshotHelper.swift` を UITest グループにドラッグ
2. Target Membership で UITest ターゲットのみにチェック（メインターゲットは外す）

---

## 5. App Store Connect API キー取得

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. **ユーザーとアクセス > 統合 > App Store Connect API**
3. **キーを追加**:
   - 名前: `Fastlane` など任意
   - アクセス: `App Manager`
4. `.p8` ファイルをダウンロード（**1回しかダウンロードできない**）
5. Key ID と Issuer ID をコピー
6. `api_key.json` を作成（SKILL.md のテンプレートを参照）

```bash
# .p8 の内容を1行にする（改行を \n に変換）
cat AuthKey_XXXXXXXXXX.p8 | awk 'NR==1{printf $0} NR>1{printf "\\n"$0} END{print ""}'
```

---

## 6. 初回実行チェックリスト

```bash
# ① Snapfile の scheme 名が正しいか確認
# Xcode > Product > Scheme > Manage Schemes で UITest スキームを確認

# ② シミュレータが存在するか確認
xcrun simctl list devices | grep "iPhone 16 Pro Max"

# ③ テスト実行確認（Xcode から）
# Product > Test（⌘U）で UITest が通るか確認

# ④ snapshot 単体テスト
fastlane snapshot --devices "iPhone 16 Pro Max" --languages "ja"

# ⑤ 問題なければフルで実行
fastlane upload_screenshots
```

---

## Fastlane バージョン管理（チーム開発向け）

`Gemfile` を使うとチーム全員が同じバージョンを使える:

```ruby
# Gemfile
source "https://rubygems.org"
gem "fastlane"
```

```bash
# インストール
bundle install

# 実行時は bundle exec を付ける
bundle exec fastlane screenshots
```
