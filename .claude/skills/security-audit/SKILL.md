---
name: security-audit
description: PTES準拠のセキュリティ監査・脆弱性診断ガイド。Webアプリ・API・クラウド・コンテナ・ネットワークの包括的なセキュリティテストを支援する。
trigger:
  - "セキュリティ監査"
  - "脆弱性診断"
  - "ペネトレーションテスト"
  - "ペンテスト"
  - "security audit"
  - "pentest"
  - "vulnerability assessment"
  - "OWASP"
  - "セキュリティテスト"
  - "セキュリティチェック"
  - "脆弱性スキャン"
references:
  - references/ptes-methodology.md
  - references/web-api-testing.md
  - references/infra-testing.md
---

# Security Audit Guide

PTES（Penetration Testing Execution Standard）に基づくセキュリティ監査スキル。

> **重要**: 正当な認可を得たセキュリティテスト・CTF・教育目的でのみ使用すること。

## フェーズ概要

```
1. スコープ定義 → 2. 偵察 → 3. スキャン → 4. 脆弱性分析
→ 5. テスト実行 → 6. レポート作成
```

## 使い方

ユーザーに以下を確認し、適切なフェーズを実行：

### Step 1: テスト対象の特定

- **Webアプリ？** → `references/web-api-testing.md` の Web Application Testing セクション
- **API？** → `references/web-api-testing.md` の API Testing セクション
- **クラウド環境？** → `references/infra-testing.md` の Cloud セクション
- **コンテナ/K8s？** → `references/infra-testing.md` の Container セクション
- **ネットワーク？** → `references/infra-testing.md` の Network セクション
- **コードレビュー？** → `rules/core/security.md` の OWASP Top 10 チェックリスト

### Step 2: テスト種別の決定

| 種別 | 情報量 | 用途 |
|------|--------|------|
| BlackBox | なし | 外部攻撃者視点 |
| GrayBox | 一部（認証情報等） | 最も一般的 |
| WhiteBox | 全て（ソースコード含む） | 最も網羅的 |

### Step 3: テスト実行

各 references ファイルに記載のチェックリストとツールコマンドを使用。

### Step 4: レポート作成

発見事項は以下の形式で記録：

```markdown
## [深刻度] 脆弱性タイトル

- **CVSS**: X.X
- **CWE**: CWE-XXX
- **対象**: 影響を受けるコンポーネント
- **再現手順**: ステップバイステップ
- **影響**: ビジネスインパクト
- **修正方法**: 具体的な対策
- **優先度**: Critical / High / Medium / Low / Info
```

## security-reviewer エージェントとの連携

コード実装中のセキュリティチェックには `security-reviewer` エージェントを使用。
本スキルは、より広範囲なセキュリティ監査・診断計画に使用する。
