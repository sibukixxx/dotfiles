# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on all endpoints
- [ ] Error messages don't leak sensitive data

## OWASP Top 10 (2021) チェックリスト

コードレビュー・実装時に以下を確認：

| # | カテゴリ | チェック項目 |
|---|---------|------------|
| A01 | アクセス制御の不備 | IDOR防止（オブジェクトIDの直接参照禁止）、RBAC/ABAC実装、CORS設定 |
| A02 | 暗号化の失敗 | TLS強制、パスワードはbcrypt/argon2、機密データの平文保存禁止 |
| A03 | インジェクション | SQL/NoSQL/OS/LDAPインジェクション防止、パラメータ化クエリ、入力サニタイズ |
| A04 | 安全でない設計 | 脅威モデリング実施、ビジネスロジックのバリデーション |
| A05 | セキュリティ設定ミス | デフォルト認証情報の変更、不要な機能・ポートの無効化、セキュリティヘッダー設定 |
| A06 | 脆弱なコンポーネント | 依存パッケージの脆弱性スキャン（`npm audit` / `trivy`）、EOLライブラリ禁止 |
| A07 | 認証の失敗 | MFA推奨、セッション固定攻撃防止、パスワードポリシー強制 |
| A08 | ソフトウェア整合性の失敗 | CI/CDパイプラインの署名検証、依存関係の完全性チェック |
| A09 | ログと監視の失敗 | セキュリティイベントのログ記録、ログに機密情報を含めない |
| A10 | SSRF | 内部URLへのリクエスト制限、URLホワイトリスト、メタデータAPI（169.254.169.254）ブロック |

## OWASP API Security Top 10

API開発時の必須チェック：

- **API1 BOLA**: オブジェクトレベルの認可チェック（全エンドポイントで所有者確認）
- **API2 認証の不備**: JWT検証（署名・期限・issuer）、トークンローテーション
- **API3 プロパティレベル認可**: レスポンスフィルタリング（余計なフィールドを返さない）
- **API5 機能レベル認可**: 管理者APIのアクセス制御、HTTPメソッド制限
- **API6 Mass Assignment**: 許可フィールドのホワイトリスト（`pick` / DTO使用）
- **API7 セキュリティ設定ミス**: CORSの厳格設定、不要なHTTPメソッド無効化
- **API8 インジェクション**: GraphQL introspection本番無効化、クエリ深度制限
- **API9 不適切な資産管理**: 未使用APIバージョンの廃止、APIインベントリ管理

## Secret Management

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx"

// ALWAYS: Environment variables
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

## 認証・セッション管理

- パスワードハッシュ: bcrypt (cost >= 12) or argon2id
- JWT: RS256以上、`none` アルゴリズム拒否、短い有効期限 + リフレッシュトークン
- セッション: HTTPOnly + Secure + SameSite=Strict Cookie
- OAuth: state パラメータ必須、PKCE 推奨

## クラウドセキュリティ

- IAM: 最小権限の原則、ワイルドカード (`*`) ポリシー禁止
- ストレージ: S3/GCS バケットの公開アクセスブロック
- メタデータAPI: IMDSv2 強制（`--metadata-options HttpTokens=required`）
- シークレット: AWS Secrets Manager / GCP Secret Manager 使用（環境変数に直接書かない）
- ネットワーク: セキュリティグループのインバウンド `0.0.0.0/0` 最小化

## コンテナセキュリティ

- ベースイメージ: distroless or alpine（最小構成）
- root 実行禁止: `USER nonroot` 指定
- 脆弱性スキャン: `trivy image <image>` をCI/CDに組み込み
- シークレット: ビルド時にイメージにシークレットを焼き込まない
- K8s: Pod Security Standards 適用、Service Account トークン自動マウント無効化

## メールセキュリティ（独自ドメイン運用時）

- SPF / DKIM / DMARC レコード設定
- オープンリレー禁止
- SMTP認証の暗号化（STARTTLS / TLS）

## Security Response Protocol

If security issue found:
1. STOP immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar issues
