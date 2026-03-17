# インフラ・クラウド・コンテナ セキュリティテスト

## Network Testing

### パスワード攻撃

```bash
# SSH ブルートフォース
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://target.com

# HTTP Basic Auth
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  https-get://target.com/admin

# パスワードスプレー（アカウントロックアウト回避）
crackmapexec smb target.com -u users.txt -p 'Password123!' --no-bruteforce
```

### ネットワーク攻撃

```bash
# LLMNR/NBT-NS ポイズニング（内部NWのみ）
responder -I eth0 -dwP

# ARP スプーフィング検出
arp -a | sort
```

### プロトコル診断

| プロトコル | チェック項目 |
|-----------|------------|
| SSH | 弱い暗号アルゴリズム、パスワード認証有効、古いバージョン |
| SSL/TLS | 証明書有効性、TLS 1.0/1.1 無効化、弱い暗号スイート |
| RDP | NLA有効化、暗号化レベル |
| SMTP | オープンリレー、STARTTLS、SPF/DKIM/DMARC |
| DNS | ゾーン転送許可、DNSSEC |

### SSL/TLS 検証

```bash
# SSL/TLS 設定の包括的チェック
nmap --script ssl-enum-ciphers -p 443 target.com

# testssl.sh（推奨）
testssl.sh target.com
```

---

## Cloud Security Testing

### AWS

```bash
# S3 バケットの公開チェック
aws s3 ls s3://bucket-name --no-sign-request

# IAM 設定の監査
aws iam get-account-authorization-details

# EC2 メタデータAPI（SSRF経由の情報取得）
curl http://169.254.169.254/latest/meta-data/
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# IMDSv2 強制確認
aws ec2 describe-instances --query \
  'Reservations[].Instances[].MetadataOptions'
```

### 主要ツール

| ツール | 対象 | 用途 |
|--------|------|------|
| **ScoutSuite** | AWS/Azure/GCP | マルチクラウド設定監査 |
| **Prowler** | AWS | CIS ベンチマーク準拠チェック |
| **Pacu** | AWS | AWS ペネトレーションテストフレームワーク |
| **CloudSploit** | マルチクラウド | OSS クラウドセキュリティスキャナ |

### クラウド固有の攻撃面

- [ ] IAM ポリシーのワイルドカード (`*`) 使用
- [ ] 公開ストレージバケット（S3, GCS, Azure Blob）
- [ ] メタデータAPI経由の認証情報取得（SSRF + IMDSv1）
- [ ] Lambda/Cloud Functions の過剰権限
- [ ] KMS キーポリシーの設定不備
- [ ] CloudTrail / 監査ログの無効化

---

## Container & Kubernetes Security

### コンテナ診断

```bash
# イメージの脆弱性スキャン
trivy image target-image:latest

# Dockerfile のセキュリティチェック
trivy config Dockerfile

# 実行中コンテナの内部調査
docker exec -it <container> /bin/sh

# コンテナエスケープの可能性チェック
# 特権モード確認
cat /proc/1/status | grep -i cap
# マウントされたホストパス
mount | grep -v "overlay"
```

### Kubernetes 診断

```bash
# K8s API Server の認証なしアクセス
curl -k https://<k8s-api>:6443/api/v1/pods

# Service Account トークン取得
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Pod Security の確認
kubectl get psp  # (deprecated → Pod Security Standards)
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

# etcd からの情報取得
etcdctl get / --prefix --keys-only
```

### コンテナセキュリティチェックリスト

- [ ] root ユーザーで実行していない
- [ ] 特権モード (`--privileged`) を使用していない
- [ ] 不要な capabilities が削除されている (`--cap-drop ALL`)
- [ ] Read-only ファイルシステム (`--read-only`)
- [ ] ホストネットワーク・PID 名前空間を共有していない
- [ ] リソース制限が設定されている（CPU, メモリ）
- [ ] イメージが署名・検証されている
- [ ] ベースイメージが最新でパッチ適用済み

### K8s セキュリティチェックリスト

- [ ] RBAC が適切に設定されている
- [ ] NetworkPolicy でPod間通信が制限されている
- [ ] Service Account の自動マウントが無効化されている
- [ ] etcd が暗号化されている
- [ ] Admission Controller（OPA/Kyverno）が設定されている
- [ ] Pod Security Standards が適用されている
- [ ] シークレットが外部シークレットマネージャと連携している

### 主要ツール

| ツール | 用途 |
|--------|------|
| **Trivy** | コンテナイメージ・IaC 脆弱性スキャン |
| **kube-hunter** | K8s クラスタのペネトレーションテスト |
| **kube-bench** | CIS Kubernetes ベンチマーク |
| **Falco** | ランタイムセキュリティ監視 |
| **CDK** | コンテナ環境の攻撃・エスケープツール |

---

## VPN / Remote Access

### SSL VPN 主要脆弱性

| 製品 | CVE | 影響 |
|------|-----|------|
| Fortinet | CVE-2018-13379 | パストラバーサル（認証情報漏洩） |
| Pulse Secure | CVE-2019-11510 | 任意ファイル読取 |
| Citrix | CVE-2019-19781 | リモートコード実行 |
| Palo Alto | CVE-2024-3400 | コマンドインジェクション |

### 診断項目

- [ ] SSL/TLS バージョン・暗号スイートの安全性
- [ ] IPSec Aggressive Mode の無効化
- [ ] VPNアプライアンスのファームウェアバージョン
- [ ] スプリットトンネリングの設定
- [ ] MFA の有効化

---

## Database Security

### RDBMS 別攻撃ベクトル

| DB | 攻撃手法 |
|----|---------|
| **MSSQL** | `xp_cmdshell`（OS コマンド実行）、`xp_dirtree`（UNC パス） |
| **PostgreSQL** | `COPY TO/FROM PROGRAM`（OS コマンド実行） |
| **MySQL** | UDF（ユーザー定義関数）、`LOAD_FILE` / `INTO OUTFILE` |
| **Oracle** | ODAT（Oracle Database Attacking Tool） |
| **MongoDB** | 演算子インジェクション (`$gt`, `$ne`)、認証なしアクセス |
| **Redis** | SSH 鍵書き込み、`CONFIG SET dir` |

### DB セキュリティチェックリスト

- [ ] デフォルト認証情報が変更されている
- [ ] リモートアクセスが制限されている
- [ ] 不要なストアドプロシージャが無効化されている
- [ ] 最小権限のユーザーでアプリケーションが接続している
- [ ] 監査ログが有効化されている
- [ ] 暗号化（保存時・転送時）が設定されている

---

## Email Security

### プロトコル検証

```bash
# SPF レコード確認
dig TXT target.com | grep spf

# DKIM レコード確認
dig TXT selector._domainkey.target.com

# DMARC レコード確認
dig TXT _dmarc.target.com

# SMTP オープンリレーチェック
nmap --script smtp-open-relay -p 25 target.com
```

### Exchange 主要脆弱性

- **ProxyLogon** (CVE-2021-26855): SSRF → RCE
- **ProxyShell** (CVE-2021-34473): RCE チェーン
- OWA ブルートフォース / パスワードスプレー

### M365 / Google Workspace

- [ ] MFA が全ユーザーに適用されている
- [ ] レガシー認証（Basic Auth）が無効化されている
- [ ] 条件付きアクセスポリシーが設定されている
- [ ] メールフロールール（転送ルール）の監査
