# Orchestrator 選定ガイド（n8n / Zapier / Make / 自前コード）

ワークフロー連携で何を使うか。元記事は「n8n / Zapier / Make」と並列に挙げるだけで選定基準がない。本ドキュメントで補完する。

## 選定マトリクス

| 観点 | Zapier | Make | n8n (Cloud) | n8n (Self-host) | 自前コード |
|------|--------|------|-------------|-----------------|----------|
| 立ち上げ速度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐ |
| 柔軟性 | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| コスト（軽量利用） | $$$ | $$ | $$ | $（VPS 代のみ） | $（API 代のみ） |
| コスト（大規模） | $$$$$ | $$$$ | $$$ | $$ | $$ |
| 学習コスト | 低 | 中 | 中 | 高 | 高 |
| デバッグ容易性 | △（GUI ログ） | ○ | ○ | ◎ | ◎ |
| バージョン管理 | ✗（GUI 内のみ） | ✗ | △（export/import） | ◎（YAML / Git） | ◎ |
| テスト容易性 | △ | △ | ○ | ◎ | ◎ |
| プロンプト管理 | △ | △ | ○ | ◎ | ◎ |
| 連携先の数 | 6000+ | 1500+ | 400+ | 400+ | 自由 |
| ベンダーロックイン | 高 | 高 | 中 | 低 | なし |
| Compliance（GDPR / SOC2） | ◎ | ◎ | ◎ | 自分次第 | 自分次第 |
| LLM 統合 | △（プラグイン経由） | ○ | ○ | ◎ | ◎ |

## 決定木

```
何を作る？
├── 単発のシンプル連携（Slack→Sheets 等）
│   └── Zapier / Make（コードレス、数分で動く）
│
├── 5-10 ステップで複雑な分岐あり
│   └── Make / n8n Cloud
│
├── LLM 中心、プロンプトを Git 管理したい
│   └── n8n（self-host）or 自前コード
│
├── PII / 規制業界（金融 / 医療 / 政府）
│   ├── データ国外移転 NG → n8n self-host or 自前コード
│   └── データ国外移転 OK → SOC2/HIPAA 対応の SaaS（要契約確認）
│
├── ボリューム大（月 100 万 task 以上）
│   └── 自前コード（SaaS 課金が爆発する）
│
└── テスト駆動で開発したい
    └── n8n self-host or 自前コード（GUI ベースは TDD と相性悪い）
```

## 各ツールの落とし穴

### Zapier

- **コストが課金単位で爆発**: 1 zap = 1 task で課金。複雑な workflow は 100 task / run になることも
- **データ通過量制限**: 大きい payload は途中で切られる
- **バージョン管理不可**: GUI 内 history のみ、Git にコミットできない
- **マルチステップで遅い**: ステップ間に数秒の遅延
- **適切な用途**: 単純な 1-3 ステップの連携

### Make

- **複雑な分岐は組めるがメンテ困難**: GUI で分岐が増えるとスパゲッティ化
- **Webhook 1.5 万 / 月で plan upgrade 必要**: 量が増えると Zapier 同様コスト爆発
- **適切な用途**: 5-15 ステップで分岐ありの中規模 workflow

### n8n Cloud

- **OSS だが Cloud は SaaS 課金**: self-host のメリットが消える
- **適切な用途**: n8n の柔軟性を欲しいが運用したくない場合

### n8n Self-host

- **運用コスト**: VPS / k8s の管理が必要、SLA 自分で確保
- **アップデート対応**: minor version 上げで動かなくなる workflow がある
- **secret 管理**: 自前で実装が必要（環境変数 / Vault 等）
- **適切な用途**: 規模・規制・コストを総合判断して self-host が合理的な場合
- **本リポジトリの推奨**: 中長期運用するなら self-host + Git 管理

### 自前コード

- **開発・運用コスト最大**: フレームワーク選定、エラー処理、監視、デプロイすべて自分で
- **柔軟性最大**: 何でもできる
- **適切な用途**: コア事業の workflow で長期運用する、orchestrator では不可能な要件がある場合
- **推奨スタック例**:
  - Python: Prefect / Dagster / Temporal
  - TypeScript: Inngest / Trigger.dev
  - Go: Temporal / 自前

## ハイブリッド戦略（推奨）

実用的には **混在** が現実解：

```
シンプル連携（Slack 通知, Sheets 書き込み等）
└── Zapier / Make でサクッと作る

中核 LLM workflow（分類, 生成, 抽出）
└── n8n self-host or 自前コードで Git 管理

データソース統合（DB から API 経由のデータ取得）
└── 自前コードで薄いラッパー
```

## n8n self-host のサンプル設定

本リポジトリで採用するなら：

```yaml
# docker-compose.yml
services:
  n8n:
    image: n8nio/n8n:latest
    environment:
      N8N_HOST: ${N8N_HOST}
      N8N_PROTOCOL: https
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: ${N8N_USER}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_PASSWORD}
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      EXECUTIONS_DATA_PRUNE: true
      EXECUTIONS_DATA_MAX_AGE: 90  # 90 日で削除
    volumes:
      - n8n_data:/home/node/.n8n
      - ./workflows:/workflows  # Git 管理対象
    secrets:
      - openai_api_key
      - anthropic_api_key
```

### Git 管理パターン

```bash
# workflow を export
$ n8n export:workflow --all --output workflows/

# Git にコミット
$ git add workflows/ && git commit -m "feat: weekly report workflow v1.1.0"

# 別環境で import
$ n8n import:workflow --input workflows/
```

## 移行戦略

最初は Zapier で動かし、規模が拡大したら n8n / 自前へ移行するのが普通：

1. **Phase 1 (PoC)**: Zapier で速攻動かす（1-2 日）
2. **Phase 2 (運用)**: コスト or 柔軟性で限界を感じたら Make へ
3. **Phase 3 (本番)**: バージョン管理・テスト必要になったら n8n self-host
4. **Phase 4 (大規模)**: コスト最適化・特殊要件が出たら自前コード

各 phase の判断基準：

| 移行トリガ | 次へ |
|----------|-----|
| 月額 $200 を超える | Make |
| 月額 $500 を超える | n8n self-host |
| 月額 $2000 を超える | 自前コード |
| バージョン管理が必須 | n8n self-host or 自前 |
| テストが書けない | n8n self-host or 自前 |
| 規制対応が必要 | self-host or 自前 |
