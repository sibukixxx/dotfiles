---
name: cloudwatch-report
description: Use when creating CloudWatch metrics reports for toscana production environment, checking system health, or investigating performance issues. Triggers include production monitoring, weekly health checks, incident investigation, or performance regression analysis.
---

# CloudWatch Report

本番環境のCloudWatch + Performance Insights レポートを作成するスキル。

**サブエージェントにレポート生成を委譲するな。** メトリクス取得からレポート作成まで、このスキルを読んだエージェント自身が実行すること。サブエージェントにはこのテンプレートが渡らないため、フォーマットが崩れる。

## Quick Reference

| 項目 | 値 |
|------|-----|
| AWS Profile | `mt-prd-toscana-ro` |
| デフォルト期間 | 直近7日間 (00:00 JST起点) |
| 出力先 (週次) | `docs/report_production_metrics_YYYY-MM-DD_DD.md` |
| 出力先 (PI日次) | `docs/report_pi_YYYY-MM-DD.md` |
| スクリプト | `.claude/skills/cloudwatch-report/report.mjs` |

## Infrastructure Specs

### ECS Fargate (1 task, オートスケーリング未導入)

| 項目 | 値 | 換算 |
|------|-----|------|
| CPU | 1024 units (1 vCPU) | CPU% = CpuUtilized / 1024 × 100 |
| Memory | 2048 MB | Mem% = MemoryUtilized / 2048 × 100 |
| Platform | ARM64 | |

### Aurora PostgreSQL (db.t4g.large)

| 項目 | 値 |
|------|-----|
| vCPU / RAM | 2 vCPU / 8 GB |
| Engine | aurora-postgresql 16.6 |
| Performance Insights | 有効 (保持期間7日) |

> **Note**: 2026-04-19 (日) 00:00-03:00 JST に db.t4g.medium (4GB) から db.t4g.large (8GB) にスケールアップ実施。vCPU は変わらず、メモリのみ倍増。同期間は CloudFront 5xx 多発 (オリジン到達不能) でサービス断あり。

## CLI

```bash
node .claude/skills/cloudwatch-report/report.mjs [options]
```

### Options

| フラグ | 説明 | デフォルト |
|--------|------|-----------|
| `--mode <weekly\|pi\|cw>` | 実行モード | `weekly` |
| `--start <ISO8601>` | 開始時刻 (UTC) | 7日前 00:00 JST→UTC |
| `--end <ISO8601>` | 終了時刻 (UTC) | 本日 00:00 JST→UTC |
| `--period <seconds>` | CW メトリクス期間 | `3600` |
| `--pi-period <seconds>` | PI メトリクス期間 | pi=300, weekly=3600 |
| `--output <path>` | 出力先 | モードに応じて自動 |
| `--no-fetch` | AWS APIを呼ばず保存済みJSONから生成 | (off) |

### Modes

| モード | CloudFront | ALB | ECS | RDS基本 | PI | 用途 |
|--------|:---:|:---:|:---:|:---:|:---:|------|
| `weekly` | o | o | o | o | o | 週次フルレポート |
| `pi` | - | - | - | - | o | 日次PIキャプチャ |
| `cw` | o | o | o | o | - | CWのみ (PI不要時) |

### JSON キャッシュ

AWS レスポンスは常に `/tmp/cw_report/json/` に自動保存される。
`--no-fetch` を使うと AWS API を呼ばずにキャッシュからレポートを再生成できる（フォーマット修正時に便利）。

## 実行フロー

### 1. メトリクス取得 + レポート生成

```bash
# 週次フルレポート (CW + PI)
node .claude/skills/cloudwatch-report/report.mjs --mode weekly

# 日付指定 (JST 00:00起点をUTCに変換)
node .claude/skills/cloudwatch-report/report.mjs --mode weekly \
  --start 2026-02-09T15:00:00Z --end 2026-02-16T15:00:00Z

# PI のみ (日次キャプチャ)
node .claude/skills/cloudwatch-report/report.mjs --mode pi

# CW のみ (PI スキップ)
node .claude/skills/cloudwatch-report/report.mjs --mode cw
```

出力先 (デフォルト):
- `weekly`: `/tmp/cw_report/report.md`
- `pi`: `/tmp/cw_report/pi_report.md`
- `cw`: `/tmp/cw_report/cw_report.md`

### 2. レポートを最終出力先にコピー

```bash
# 週次
cp /tmp/cw_report/report.md docs/report_production_metrics_YYYY-MM-DD_DD.md

# 日次 PI
cp /tmp/cw_report/pi_report.md docs/report_pi_YYYY-MM-DD.md
```

### 3. レポートをReadで読む

完成したmarkdownレポートを `Read` ツールで読み込み、内容を確認する。

### 4. 所見・推奨アクションをファイルに追記

レポート末尾の「主な所見」「推奨アクション」セクションに、データに基づく分析を記述する。
HTMLコメント (`<!-- ... -->`) のプレースホルダーを実際の内容で置換する。

### フォーマット修正時 (AWS APIを呼ばない)

```bash
# キャッシュ済みJSONからレポートを再生成
node .claude/skills/cloudwatch-report/report.mjs --no-fetch --mode weekly
```

## Report Template

`report.mjs` が以下の構造のmarkdownを自動生成する。エージェントが手動でフォーマットする必要はない。

### ヘッダ (自動生成)

```
# 本番環境メトリクスレポート

**期間**: YYYY/MM/DD (曜日) - YYYY/MM/DD (曜日)
**作成日**: YYYY/MM/DD
**プロファイル**: mt-prd-toscana-ro
**インフラ構成**: ECS Fargate (1 vCPU / 2048 MB) × 1 task, Aurora PostgreSQL db.t4g.large (2 vCPU / 8 GB)
```

### Layer 1: 日次サマリー (自動生成)

CloudFront / ALB / ECS (CPU/Memory) / ECS (Network/Storage) / RDS / 総合サマリーの各テーブル。

### Layer 2: 時間帯別詳細 (自動生成)

1行=1時間の連続テーブル。全日・全時間帯を出力。

### Layer 3: スパイクドリルダウン (自動生成)

以下の条件でスパイクを自動検出:
- ECS CPU max(%) が日次 cpu_max_pct 平均の **3倍以上**
- ALB Requests が日次平均の **2倍以上** (単独ではスパイク判定しない、他条件との複合のみ)
- RDS CPU max が **20%以上**
- ALB 5XX が **1件以上**

### Layer 4: Performance Insights (自動生成, weeklyモードのみ)

- DB Load (時系列)
- Top Wait Events / Top SQL / SQL 文詳細 / Top Users
- OS CPU 内訳 / トランザクション / Tuple 操作 / Temp
- セッション・ロック / OS メモリ & Swap / Aurora Storage I/O
- コネクション & デッドロック / キャッシュ & I/O / チェックポイント

### 主な所見・推奨アクション (エージェントが追記)

```
## 主な所見
### 1. [所見タイトル]
- データに基づく客観的分析

## 推奨アクション
1. **[アクション名]**: 具体的な対応策
```

## CW メトリクス一覧

| サービス | メトリクス数 | 備考 |
|----------|:---:|------|
| CloudFront | 3 | us-east-1, Requests/4xxRate/5xxRate |
| ALB | 6 | RequestCount/2XX/4XX/5XX/RT avg/RT max |
| ECS (CPU/Mem) | 4 | CpuUtilized/MemoryUtilized × avg/max |
| ECS (Net/Stor) | 8 | NetworkRx/Tx + StorageRead/Write × avg/max |
| RDS | 9 | CPU/FreeMem/Conn/Cache/IOPS/Latency/Deadlocks |
| **合計** | **30** | |

## Common Mistakes

| 正解 | 間違い |
|------|--------|
| CloudFrontは **us-east-1** | ap-northeast-1で取得 |
| ECSは **ECS/ContainerInsights** | AWS/ECS namespace |
| RDSは **DBClusterIdentifier** | cluster名をそのまま使用 |
| CpuUtilized ÷ 1024 × 100 = **CPU%** | CpuUtilizedをそのまま%として報告 |
| MemoryUtilized ÷ 2048 × 100 = **Mem%** | MBをそのまま%として報告 |
| FreeableMemory ÷ 1048576 = **MB** | bytesをそのままMBとして報告 |
| デフォルト期間は **直近7日間** | 期間未指定でエラー |
| ファイル名は `report_production_metrics_*` | 不統一なファイル名 |
| レポート本文は **report.mjs が自動生成** | エージェントが手動でテーブルを組み立て |
| 所見・推奨アクションのみ **エージェントが追記** | テーブル部分もエージェントが書く |
| レポート生成は **自身で実行** | サブエージェントに委譲（テンプレートが消える） |
| メトリクス取得は **report.mjs** (AWS CLI via Node.js) | MCP CloudWatch tool（コンテキスト圧迫） |
| フォーマット修正は **--no-fetch** | 毎回AWSを呼び直す |
