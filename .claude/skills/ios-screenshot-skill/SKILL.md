---
name: ios-screenshot
description: >
  iOS App Store 審査用スクリーンショットの自動化。Fastlane（snapshot + deliver）を使った
  スクショ撮影・App Store Connect アップロードの設定生成・トラブル解決に使う。
  「スクショ自動化」「審査スクリーンショット」「fastlane snapshot」「App Store スクショ」
  「deliver アップロード」などのキーワードが出たら必ずこのスキルを使うこと。
  Fastlane 未導入のプロジェクトへのゼロからのセットアップも対応する。
---

# iOS スクリーンショット自動化スキル

## このスキルでできること

- Fastlane 未導入プロジェクトへのセットアップ手順生成
- `Snapfile` / `Deliverfile` / `Fastfile` のプロジェクト固有設定ファイル生成
- UITest スクショ撮影コード（Swift）の生成
- App Store Connect API キー設定
- トラブルシューティング

---

## ユーザーへの確認事項（最初に把握する）

スキルを使う前に以下を確認する（不明な場合は質問する）:

| 項目 | 確認内容 |
|------|---------|
| Bundle ID | `com.example.myapp` 形式 |
| スキーム名 | Xcode のスキーム名（UITest スキーム名） |
| 対応言語 | ja のみ？ en-US も？ |
| 対応デバイス | iPhone のみ？ iPad も必要？ |
| Fastlane 導入済み？ | brew でインストール済みか |
| API キー取得済み？ | App Store Connect の .p8 ファイルがあるか |

---

## ワークフロー

```
1. インストール確認 → 2. fastlane init → 3. Snapfile 生成
      ↓
4. UITest コード生成 → 5. snapshot 実行 → 6. deliver でアップロード
```

詳細手順は `references/setup.md` を参照。

---

## 設定ファイル生成テンプレート

### Snapfile

```ruby
# fastlane/Snapfile
devices([
  "iPhone 16 Pro Max",    # 6.9インチ（必須）
  "iPhone 15 Plus",       # 6.5インチ（後方互換、省略可）
  # "iPad Pro 13-inch (M4)"  # iPad 対応時はコメント解除
])

languages([
  "ja",
  # "en-US",  # 多言語対応時はコメント解除
])

output_directory("./fastlane/screenshots")
scheme("{{UITEST_SCHEME}}")  # ← 要変更
clear_previous_screenshots(true)
```

### Deliverfile

```ruby
# fastlane/Deliverfile
apple_id("{{APPLE_ID}}")           # ← 要変更
app_identifier("{{BUNDLE_ID}}")    # ← 要変更
screenshots_path("./fastlane/screenshots")
api_key_path("./fastlane/api_key.json")
submit_for_review(false)
overwrite_screenshots(true)
```

### Fastfile（レーン定義）

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  lane :screenshots do
    snapshot
  end

  lane :upload_screenshots do
    snapshot
    deliver(
      skip_binary_upload: true,
      skip_metadata: true,
      overwrite_screenshots: true
    )
  end
end
```

### api_key.json テンプレート

```json
{
  "key_id": "XXXXXXXXXX",
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "duration": 1200,
  "in_house": false
}
```

---

## UITest スクショコード（Swift）

```swift
// {{APP_NAME}}UITests/SnapshotTests.swift
import XCTest

class SnapshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)  // ← Fastlane が自動追加する SnapshotHelper を使用
        app.launch()
    }

    func testScreenshots() {
        // ▼ 画面ごとに追記する
        snapshot("01_Home")

        // 例: タブ遷移
        // app.tabBars.buttons["検索"].tap()
        // snapshot("02_Search")
    }
}
```

> `SnapshotHelper.swift` は `fastlane snapshot` を初回実行すると自動生成される。
> UITest ターゲットに追加してビルドターゲットに含めること。

---

## 実行コマンド

```bash
# 初回セットアップ
fastlane init

# スクショ撮影のみ
fastlane screenshots

# 撮影 → ASC アップロード
fastlane upload_screenshots

# デバッグ: 特定デバイスのみ
fastlane snapshot --devices "iPhone 16 Pro Max"
```

---

## App Store 必須スクショサイズ（2025年）

| 優先度 | サイズ | Fastlane デバイス名 |
|--------|--------|-------------------|
| ✅ 必須 | 6.9インチ | `iPhone 16 Pro Max` |
| 推奨 | 6.5インチ | `iPhone 15 Plus` |
| 任意 | iPad 13インチ | `iPad Pro 13-inch (M4)` |

> 6.9インチのみでも審査は通過可能。

---

## トラブルシューティング（よくあるエラー）

| エラー | 原因 | 対処 |
|--------|------|------|
| `SnapshotHelper not found` | helper 未追加 | `fastlane snapshot` を一度実行 → 生成された `SnapshotHelper.swift` をターゲットに追加 |
| シミュレータが起動しない | 未インストール | Xcode > Settings > Platforms でダウンロード |
| API 認証エラー | JSON 設定ミス | `issuer_id` / `key_id` を App Store Connect で再確認 |
| スクショが真っ白 | `setupSnapshot` 漏れ | `setUp()` 内に `setupSnapshot(app)` があるか確認 |
| deliver が既存スクショを消さない | オプション未設定 | `overwrite_screenshots: true` を追加 |
| `Scheme not found` | スキーム名不一致 | Xcode の Product > Scheme で UITest スキーム名を確認 |

詳細なセットアップ手順は `references/setup.md` を参照。

---

## .gitignore 追記

```gitignore
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output/
fastlane/api_key.json
*.p8
```
