# セキュリティエンジニアリング・暗号・脅威モデリング

## セキュリティエンジニアリング（Anderson『Security Engineering 3rd ed.』ベース）

### セキュリティの基本原則

| 原則 | 内容 |
|------|------|
| 最小権限 (Least Privilege) | 必要最小限の権限のみ付与 |
| 多層防御 (Defense in Depth) | 単一の防御に依存しない |
| フェイルセキュア (Fail Secure) | 障害時は安全側に倒す |
| 完全な仲介 (Complete Mediation) | 全アクセスを検証 |
| 経済性 (Economy of Mechanism) | セキュリティ機構は単純に |
| オープン設計 (Open Design) | 秘密に依存しない設計 |
| 権限分離 (Separation of Privilege) | 複数の条件で権限を付与 |
| 心理的受容性 (Psychological Acceptability) | ユーザーが自然に使えるセキュリティ |

### 信頼境界（Trust Boundary）

```
【信頼境界の識別】
システムを信頼レベルの異なるゾーンに分割:

  インターネット（非信頼）
    ↓ [信頼境界 1: WAF/LB]
  DMZ（部分信頼）
    ↓ [信頼境界 2: APIゲートウェイ]
  アプリケーション層（信頼）
    ↓ [信頼境界 3: DB接続]
  データ層（高信頼）

信頼境界を越えるデータは必ず:
  1. 認証: 送信者は本人か
  2. 認可: 権限があるか
  3. 検証: データは正しい形式か
  4. サニタイズ: 危険な内容を除去
```

### エージェントセキュリティの設計原則

```
【エージェント固有の脅威】
1. Prompt Injection: ユーザー入力やツール出力にLLMへの指示を混入
2. Tool権限逸脱: エージェントが意図しないツールを実行
3. 秘密情報漏洩: APIキー、トークンがログやレスポンスに混入
4. 過剰な自律性: 人間の承認なく破壊的操作を実行
5. データ汚染: 外部ソースから悪意あるデータを取り込み

【対策パターン】
├ サンドボックス実行: コンテナ/VM内でツールを実行
├ 権限の明示的宣言: ツールごとにアクセス可能なリソースを制限
├ 人間の承認ゲート: 破壊的操作（削除、送信、デプロイ）前に確認
├ 入力/出力フィルタ: LLMへの入出力をサニタイズ
├ 監査ログ: 全操作をトレース（o11y）
└ レートリミット: エージェントのアクション速度を制限
```

### 認証の設計

```
【認証要素】
知識: パスワード、PIN、秘密の質問
所持: ハードウェアトークン、スマートフォン、証明書
生体: 指紋、顔、虹彩

【パスワード保存】
絶対にやってはいけない: 平文保存、MD5/SHA1
正しい方法:
  bcrypt(password, cost=12+)
  argon2id(password, memory=65536, iterations=3, parallelism=4)
  scrypt(password, N=2^15, r=8, p=1)

【セッション管理】
JWT: ステートレス（署名検証のみ）
  長所: サーバー側でセッション管理不要
  短所: 即時失効が困難（短い有効期限 + リフレッシュトークン）
  必須: alg: none を拒否、RS256以上、exp/iss/aud検証

セッションID: サーバー側でセッションストアに保持
  長所: 即時失効可能
  短所: セッションストアの管理

Cookie属性: HttpOnly + Secure + SameSite=Strict + __Host- prefix
```

### 監査と監視

```
【監査ログに記録すべきイベント】
- 認証: ログイン成功/失敗、ログアウト、パスワード変更
- 認可: アクセス拒否、権限変更
- データ: 作成、読取（機密データ）、更新、削除
- システム: 起動、停止、設定変更、エラー
- エージェント: ツール呼び出し、LLMリクエスト、承認/拒否

【記録してはいけないもの】
- パスワード、APIキー、トークン
- クレジットカード番号（PCI DSS）
- 個人情報（マスキング）
```

## 暗号技術（Aumasson『Serious Cryptography 2nd ed.』ベース）

### 暗号プリミティブ

#### 対称鍵暗号

```
【AES（Advanced Encryption Standard）】
ブロック暗号: 128ビットブロック、鍵長128/192/256ビット
→ 単体では使わない。必ず暗号利用モードと組み合わせる

【暗号利用モード】
ECB: ×使ってはいけない（パターンが漏れる）
CBC: ブロック連鎖。パディングオラクル攻撃に注意
CTR: カウンタモード。並列処理可能
GCM: CTR + 認証タグ。現在の推奨（AEAD）
CCM: CTR + CBC-MAC。IoT向け

【AEAD（Authenticated Encryption with Associated Data）】
暗号化 + 認証を同時に行う
→ AES-256-GCM が標準
→ ChaCha20-Poly1305 がソフトウェア実装の代替（ARM等）
```

#### ハッシュ関数

```
SHA-256: 256ビット出力。一般的な完全性検証
SHA-3 (Keccak): SHA-2の代替。構造が異なる
BLAKE2: SHA-3競合。高速
BLAKE3: さらに高速（並列処理可能）

【使い分け】
パスワード → bcrypt/argon2id（ハッシュ関数ではない）
完全性検証 → SHA-256
高速ハッシュ → BLAKE3
MAC → HMAC-SHA256
```

#### MAC（メッセージ認証コード）

```
HMAC: H(K ⊕ opad || H(K ⊕ ipad || message))
→ 鍵を知らないと生成も検証もできない
→ Webhook署名、APIリクエスト認証に使用

HMAC-SHA256(key, message) → 256ビットのタグ
検証: constant-time comparison（タイミング攻撃対策）
```

#### 公開鍵暗号

```
【RSA】
鍵生成: p, q（大きな素数）→ n = p×q, e, d
暗号化: c = m^e mod n
復号: m = c^d mod n
推奨鍵長: 2048ビット以上（3072+ が望ましい）
→ 暗号化よりも署名に使われることが多い

【楕円曲線暗号（ECC）】
同じセキュリティレベルでRSAより短い鍵
  ECC 256ビット ≈ RSA 3072ビット
曲線: P-256（NIST）、Curve25519（推奨）
鍵交換: ECDH（Elliptic Curve Diffie-Hellman）
署名: ECDSA、Ed25519（推奨: 定時間、実装ミスに強い）
```

#### 鍵交換

```
【Diffie-Hellman鍵交換】
Alice: a（秘密）→ g^a mod p（公開）
Bob:   b（秘密）→ g^b mod p（公開）
共有鍵: g^(ab) mod p（両者が計算可能）
→ 中間者攻撃に脆弱（認証が必要）

【ECDH（楕円曲線DH）】
X25519が推奨
→ TLS 1.3 のデフォルト鍵交換

【Forward Secrecy（前方秘匿性）】
一時的な鍵ペアを毎回生成
→ 長期鍵が漏れても過去の通信は復号不可
→ TLS 1.3 は強制
```

### TLS の暗号的側面

```
【TLS 1.3 の暗号スイート】
TLS_AES_128_GCM_SHA256
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256

【排除されたもの（TLS 1.2以前）】
RC4、3DES、CBC（パディングオラクル）、RSA鍵交換（前方秘匿性なし）
静的DH、輸出グレード暗号、NULL暗号

【証明書】
X.509: 公開鍵 + 所有者情報 + CA署名
Let's Encrypt: 無料の自動証明書（ACME プロトコル）
Certificate Transparency: 発行された証明書の公開ログ
```

### ポスト量子暗号

```
量子コンピュータの脅威:
  RSA、ECC、DH → Shorのアルゴリズムで破られる
  AES → Groverのアルゴリズムで鍵長が実質半減（AES-256→128相当）

NIST PQC標準（2024年〜）:
  鍵カプセル化: ML-KEM（Kyber）
  デジタル署名: ML-DSA（Dilithium）、SLH-DSA（SPHINCS+）

移行戦略:
  ハイブリッド: 古典暗号 + PQC を併用（TLS で実装進行中）
  Harvest Now, Decrypt Later 攻撃への備え
```

### 安全な乱数

```
【暗号論的に安全な疑似乱数生成器（CSPRNG）】
Linux: /dev/urandom（getrandom() syscall 推奨）
macOS: arc4random()
Windows: BCryptGenRandom()

【やってはいけない】
Math.random()（JavaScript）: 暗号用途には使えない
time ベースのシード: 予測可能
自前の乱数生成器: 既存のCSPRNGを使う
```

## 脅威モデリング（Shostack『Threat Modeling』ベース）

### STRIDE

| 脅威 | 説明 | セキュリティ特性 |
|------|------|----------------|
| **S**poofing | なりすまし | 認証 |
| **T**ampering | 改ざん | 完全性 |
| **R**epudiation | 否認 | 否認防止（監査ログ） |
| **I**nformation Disclosure | 情報漏洩 | 機密性 |
| **D**enial of Service | サービス拒否 | 可用性 |
| **E**levation of Privilege | 権限昇格 | 認可 |

### 脅威モデリングプロセス

```
1. What are we working on?
   → データフロー図（DFD）を描く
   → 信頼境界を識別

2. What can go wrong?
   → STRIDEを各コンポーネントに適用
   → 攻撃ツリーを構築

3. What are we going to do about it?
   → 脅威ごとに対策を決定:
     Mitigate（緩和）/ Transfer（転嫁）/ Accept（受容）/ Avoid（回避）

4. Did we do a good enough job?
   → レビュー、テスト、更新
```

### エージェントシステムの脅威モデル

```
【DFD: AIエージェントシステム】

[User] → (API Gateway) → [Agent Orchestrator] → (LLM API)
                               ↓
                         [Tool Executor]
                          ↓        ↓
                    [File System] [External API]
                          ↓
                    [Database/Vector Store]

【信頼境界】
TB1: ユーザー → API Gateway（認証）
TB2: Agent → LLM API（APIキー管理）
TB3: Agent → Tool Executor（権限制御）
TB4: Tool → External API（認証、入力検証）
TB5: Tool → File System（サンドボックス）

【STRIDEの適用例】
| コンポーネント | S | T | R | I | D | E |
|---------------|---|---|---|---|---|---|
| API Gateway | ○ | - | ○ | - | ○ | - |
| LLM API呼出し | - | ○ | - | ○ | ○ | - |
| Tool Executor | ○ | ○ | ○ | ○ | - | ○ |
| File System | - | ○ | - | ○ | - | ○ |
| Vector Store | - | ○ | - | ○ | - | - |

【Prompt Injection の脅威分析】
位置: ユーザー入力、ツールの出力（Webページ、ファイル内容）
種類:
  Direct: ユーザーがプロンプトに直接注入
  Indirect: 外部データ（Webページ、メール等）経由
対策:
  ├ 入力サニタイズ（限界あり）
  ├ 権限の最小化（ツールごとのスコープ制限）
  ├ 人間の承認ゲート（破壊的操作前）
  ├ 出力フィルタ（機密データのマスキング）
  └ モニタリング（異常な操作パターンの検出）
```

### 攻撃ツリー

```
【目標: エージェントのAPIキーを窃取】
├ 1. ログからの漏洩
│   ├ 1.1 エラーメッセージにキーが含まれる
│   └ 1.2 デバッグログにキーが記録される
├ 2. 環境変数からの漏洩
│   ├ 2.1 /proc/self/environ へのアクセス
│   └ 2.2 コンテナの環境変数リスト
├ 3. Prompt Injection
│   ├ 3.1 ユーザー入力で「APIキーを表示して」
│   └ 3.2 外部データにAPIキー抽出の指示を埋め込み
├ 4. コードリポジトリ
│   ├ 4.1 .env ファイルがコミットされている
│   └ 4.2 Git履歴に残存
└ 5. メモリダンプ
    └ 5.1 プロセスメモリの読み取り
```
