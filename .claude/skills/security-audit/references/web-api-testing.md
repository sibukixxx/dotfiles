# Web Application & API セキュリティテスト

## Web Application Testing

OWASP Testing Guide に準拠した診断項目。

### インジェクション系

#### SQL Injection

```bash
# SQLMap による自動検出
sqlmap -u "https://target.com/page?id=1" --batch --dbs
sqlmap -u "https://target.com/page?id=1" --batch --tables -D dbname
sqlmap -u "https://target.com/page?id=1" --batch --dump -T users -D dbname

# POST リクエスト
sqlmap -u "https://target.com/login" --data="user=admin&pass=test" --batch

# Cookie ベース
sqlmap -u "https://target.com/page" --cookie="session=abc123" --batch
```

手動テストペイロード（検出用）:
- `' OR '1'='1`
- `1; DROP TABLE--`
- `" OR ""="`
- `1 UNION SELECT null,null,null--`

#### XSS (Cross-Site Scripting)

テスト箇所:
- 検索フォーム、コメント欄、プロフィール入力
- URLパラメータの反射
- DOM操作（`innerHTML`, `document.write`）

防止策:
- 出力エスケープ（コンテキスト別: HTML / JS / URL / CSS）
- Content-Security-Policy ヘッダー
- `HttpOnly` Cookie

#### コマンドインジェクション

テスト対象: ファイル操作、DNS lookup、ping等のシステムコマンド呼び出し

```
; ls -la
| cat /etc/passwd
$(whoami)
`id`
```

#### XXE (XML External Entity)

```xml
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>
```

### 認証・セッション管理

チェック項目:
- [ ] ブルートフォース保護（ロックアウト / レート制限）
- [ ] パスワードポリシー（最低長、複雑性）
- [ ] セッションIDのランダム性・長さ
- [ ] ログアウト時のセッション無効化
- [ ] セッション固定攻撃への耐性
- [ ] Remember Me トークンの安全性
- [ ] パスワードリセットフローの安全性

### 認可制御

- [ ] IDOR (Insecure Direct Object Reference): `GET /api/users/123` → `GET /api/users/124`
- [ ] 水平権限昇格: 同一ロールの他ユーザーリソースへのアクセス
- [ ] 垂直権限昇格: 管理者機能への一般ユーザーアクセス
- [ ] 強制ブラウジング: 非公開URLの直接アクセス

### ビジネスロジック

- [ ] 数量操作（負の値、ゼロ、極大値）
- [ ] ワークフロースキップ（ステップの飛ばし）
- [ ] レースコンディション（同時リクエスト）
- [ ] 金額計算の整合性

### セキュリティヘッダー

必須ヘッダー:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

### 主要ツール

| ツール | 用途 |
|--------|------|
| **Burp Suite** | Webアプリ診断の統合プラットフォーム |
| **OWASP ZAP** | OSS版 Burp 代替 |
| **SQLMap** | SQL Injection 自動化 |
| **Gobuster / ffuf** | ディレクトリ・ファイル列挙 |
| **Nuclei** | テンプレートベースの脆弱性スキャン |

---

## API Testing

OWASP API Security Top 10 に基づく診断。

### API1: Broken Object Level Authorization (BOLA)

```bash
# 正規ユーザーAのトークンで他ユーザーBのリソースにアクセス
curl -H "Authorization: Bearer <token_A>" \
  https://api.target.com/v1/users/USER_B_ID/profile
```

チェック:
- 全APIエンドポイントでオブジェクトIDに対する所有者確認
- UUIDを使用してもIDの推測可能性を排除しない（認可チェックが必須）

### API2: Broken Authentication

```bash
# JWT の署名なし攻撃
# ヘッダーの alg を "none" に変更

# JWT の弱い秘密鍵
john --wordlist=rockyou.txt jwt_hash.txt

# リフレッシュトークンの再利用
curl -X POST https://api.target.com/auth/refresh \
  -d '{"refresh_token": "<expired_or_revoked_token>"}'
```

### API3: Broken Object Property Level Authorization

チェック:
- レスポンスに不要な内部フィールドが含まれていないか
- Mass Assignment: PUT/PATCH で `role`, `is_admin` 等を送信

```bash
curl -X PATCH https://api.target.com/v1/users/me \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "role": "admin", "is_active": true}'
```

### API5: Broken Function Level Authorization

```bash
# 一般ユーザーのトークンで管理者APIにアクセス
curl -H "Authorization: Bearer <user_token>" \
  https://api.target.com/admin/users

# HTTPメソッドの変更
curl -X DELETE -H "Authorization: Bearer <user_token>" \
  https://api.target.com/v1/users/123
```

### GraphQL 固有

```graphql
# Introspection クエリ（本番で無効化すべき）
{
  __schema {
    types {
      name
      fields {
        name
        type { name }
      }
    }
  }
}
```

チェック:
- [ ] Introspection が本番で無効化されている
- [ ] クエリ深度制限が設定されている
- [ ] クエリコスト分析が実装されている
- [ ] バッチクエリの制限

### API レート制限テスト

```bash
# 短時間での大量リクエスト
for i in $(seq 1 100); do
  curl -s -o /dev/null -w "%{http_code}\n" \
    https://api.target.com/v1/endpoint
done | sort | uniq -c
# 429 が返ることを確認
```

### 認証トークン診断

JWT チェックリスト:
- [ ] 署名アルゴリズム検証（`none` 拒否）
- [ ] RS256 / ES256 使用（HS256 は共有秘密鍵リスク）
- [ ] 有効期限（`exp`）が適切に短い
- [ ] `iss` / `aud` クレームの検証
- [ ] リフレッシュトークンのローテーション
- [ ] トークン失効機構（ブラックリスト / 短寿命）
