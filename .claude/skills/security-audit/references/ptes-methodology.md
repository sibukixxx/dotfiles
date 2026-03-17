# PTES 方法論リファレンス

## フレームワーク比較

| フレームワーク | 特徴 | 適用場面 |
|--------------|------|---------|
| **PTES** | 7フェーズの実践的ガイド、最も広く採用 | 汎用ペネトレーションテスト |
| **OWASP Testing Guide v4** | Web特化の体系的テストケース | Webアプリ診断 |
| **NIST SP 800-115** | 政府系ガイドライン | 行政・公共系システム |
| **MITRE ATT&CK** | 攻撃手法の分類マトリクス | 脅威モデリング・レッドチーム |

## PTES 7フェーズ

```
1. Pre-engagement（事前交渉）
2. Intelligence Gathering（情報収集）
3. Threat Modeling（脅威モデリング）
4. Vulnerability Analysis（脆弱性分析）
5. Exploitation（攻撃実行）
6. Post-Exploitation（侵入後活動）
7. Reporting（報告）
```

## 1. Pre-engagement（事前交渉）

テスト開始前に必ず合意すべき事項：

- **スコープ定義**: テスト対象のIP/URL/アプリケーション範囲
- **Rules of Engagement**: テスト時間帯、禁止行為、緊急連絡先
- **テスト種別**: BlackBox / GrayBox / WhiteBox
- **書面による明示的な認可**: 必須（口頭合意のみは不可）
- **免責事項**: サービス中断リスク等の相互理解

## 2. Intelligence Gathering（情報収集）

### パッシブ偵察ツール

```bash
# メール・サブドメイン収集
theHarvester -d target.com -b google,bing,linkedin

# サブドメイン列挙（OWASP公式）
amass enum -passive -d target.com

# DNS列挙・ゾーン転送チェック
dnsrecon -d target.com -t axfr

# OSINT フレームワーク
recon-ng
```

### インターネット検索エンジン

```bash
# Shodan（インターネット接続デバイス）
shodan search "hostname:target.com"

# Censys
censys search "target.com"

# Google Dorks
site:target.com filetype:pdf
site:target.com inurl:admin
```

## 3. Scanning（スキャニング）

### Nmap 基本コマンド

```bash
# TCP SYNスキャン（全ポート）
nmap -sS -p- -T4 target.com

# サービス・OS検出
nmap -sV -O target.com

# 脆弱性スクリプト
nmap --script=vuln -p 80,443 target.com

# UDP スキャン（主要ポートのみ）
nmap -sU --top-ports 100 target.com
```

### 脆弱性スキャナ

| ツール | 特徴 |
|--------|------|
| **Nessus** | 商用、最も網羅的なプラグインDB |
| **OpenVAS** | OSS、Nessus代替 |
| **Nikto** | Webサーバ特化の軽量スキャナ |
| **Trivy** | コンテナ・IaC・依存関係の脆弱性スキャン |

### 認証 vs 非認証スキャン

- **認証スキャン**: パッチ状態を正確に把握、内部脆弱性を検出
- **非認証スキャン**: 外部攻撃者の視点に近い

## 4. Reporting（レポート構成）

### レポートの必須要素

1. **エグゼクティブサマリー**: 経営層向け、ビジネスリスクの翻訳
2. **テスト概要**: スコープ、期間、方法論
3. **発見事項詳細**: 脆弱性ごとの技術詳細
4. **リスクマトリクス**: 深刻度 × 悪用可能性
5. **修正提案**: 具体的な対策と優先度
6. **付録**: 証跡、ツール出力

### 深刻度分類

| 深刻度 | CVSS | 基準 |
|--------|------|------|
| Critical | 9.0-10.0 | リモートから認証なしで悪用可能、データ漏洩・RCE |
| High | 7.0-8.9 | 重大な影響があるが悪用に条件が必要 |
| Medium | 4.0-6.9 | 限定的な影響、または悪用に複数条件が必要 |
| Low | 0.1-3.9 | 情報漏洩等、直接的な攻撃に繋がりにくい |
| Info | 0.0 | ベストプラクティスからの逸脱 |
