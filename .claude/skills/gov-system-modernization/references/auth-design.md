# 認証設計ガイド

行政統計調査システムにおける認証方式の設計指針。

---

## 保証レベルの判定フレームワーク

デジタル庁「行政手続におけるオンラインによる本人確認の手法に関するガイドライン」に基づく。

### 2つの認証プロセス

1. **身元確認** — アカウント登録時に「利用者が実在する」ことを確認
2. **当人認証** — ログイン時に「身元確認された本人である」ことを確認

### 保証レベルの判定

| レベル | 身元確認 | 当人認証 | 適用場面 |
|--------|---------|---------|---------|
| レベル2 | 遠隔/対面での厳格確認 | 複数要素認証 | 不特定多数が利用する行政手続 |
| **レベル1** | 遠隔/対面での確認 | **単要素認証** | **特定法人への調査（推奨）** |

### 統計調査システムでレベル1が適切な理由

- 調査対象は法令に基づき**特定された法人**（不特定多数ではない）
- 身元確認は登録簿等で**実施済み**
- ログインする法人は**限定的**であり、当人認証の信用度は高い

---

## 認証方式の設計

### 推奨方式: ID/パスワード認証（保証レベル1）

```
事業所別にID/パスワードを払い出し
  → ログイン時にID/パスワードで認証
  → 認証後、紐づく企業情報を自動表示
```

### 実装要件

| 項目 | 要件 |
|------|------|
| ID体系 | 事業所単位で一意のIDを発行 |
| パスワード | 英数字記号混合8文字以上、初回ログイン時に変更を強制 |
| セッション | 一定時間操作なしでタイムアウト |
| ロック | 連続認証失敗時のアカウントロック |
| パスワードリセット | 管理者による手動リセット（メール通知） |

### 将来的な拡張（レベル2対応）

GビズID（法人共通認証基盤）との連携を将来的に検討：
- GビズIDのgBizIDプライム/メンバーとの連携
- 多要素認証（MFA）の追加
- 法人番号に基づく厳格な法人確認

---

## React + FastAPI での実装例

### フロントエンド（React TypeScript）

```typescript
// 認証コンテキスト
interface AuthState {
  isAuthenticated: boolean;
  user: {
    userId: string;
    companyId: string;
    companyName: string;
    officeId: string;
    officeName: string;
    role: 'reporter' | 'operator' | 'admin';
  } | null;
  token: string | null;
}

// ログインフォーム
const LoginForm: React.FC = () => {
  const [credentials, setCredentials] = useState({ userId: '', password: '' });
  const [error, setError] = useState('');

  const handleLogin = async () => {
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials),
      });
      if (!response.ok) throw new Error('認証に失敗しました');
      const { token, user } = await response.json();
      // トークン保存・認証状態更新
    } catch (e) {
      setError(e.message);
    }
  };

  return (/* ログインUI */);
};
```

### バックエンド（Python FastAPI）

```python
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

SECRET_KEY = "your-secret-key"  # 環境変数から取得
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

@app.post("/api/auth/login")
async def login(form_data: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.user_id, form_data.password)
    if not user:
        # アカウントロック判定
        increment_failed_attempts(db, form_data.user_id)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="IDまたはパスワードが正しくありません",
        )
    
    # 初回ログイン時のパスワード変更要求
    if user.must_change_password:
        return {"status": "password_change_required", "token": create_temp_token(user)}
    
    access_token = create_access_token(data={"sub": user.id, "role": user.role})
    return {
        "token": access_token,
        "user": {
            "userId": user.id,
            "companyId": user.company_id,
            "companyName": user.company.name,
            "officeId": user.office_id,
            "officeName": user.office.name,
            "role": user.role,
        },
    }
```

---

## ロール設計

| ロール | 対象 | 権限 |
|--------|------|------|
| reporter | 報告事業者 | 調査票の作成・提出・修正・取下げ、自社データの閲覧 |
| operator | 運用事業者 | 全調査票の閲覧・登録・修正、集計実行、帳票生成、マスタ管理 |
| admin | 行政職員 | 統計情報の閲覧・出力・公開、ユーザー管理、フォーマット編集 |
