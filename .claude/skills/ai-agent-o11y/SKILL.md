---
name: ai-agent-o11y
description: AIエージェントプロジェクトにObservability（トレーシング）を初手で組み込むセットアップガイド。LLM呼び出し・ツール呼び出し・サブエージェントの計装パターンとプラットフォーム選定を支援する。
trigger:
  - "AIエージェント"
  - "エージェント開発"
  - "トレーシング"
  - "o11y"
  - "observability"
  - "LLMトレース"
  - "Langfuse"
  - "Phoenix"
  - "OpenLLMetry"
  - "エージェントの可観測性"
  - "agent tracing"
  - "agent observability"
references:
  - references/tracing-patterns.md
  - references/platform-setup.md
---

# AI Agent Observability セットアップ

AIエージェントを開発するとき、**最初にやるべきはトレーシングの組み込み**。

> トレースデータさえあれば細かい調整はコーディングエージェントに投げるだけ。
> トレースがなければ何が起きているか分からず改善のしようがない。

## このスキルの使い方

1. プロジェクトの言語・フレームワークを確認
2. トレーシングプラットフォームを選定 → `references/platform-setup.md`
3. 計装パターンを適用 → `references/tracing-patterns.md`
4. ルールに従ってスパン設計 → `rules/core/ai-agent-o11y.md`

## ステップ 1: プラットフォーム選定

ユーザーに以下を確認：

- **ローカル開発のみ？** → Jaeger or Phoenix
- **チームで共有？** → Langfuse (セルフホスト) or Langfuse Cloud
- **既に OTel 基盤がある？** → OTLP エクスポーターを追加するだけ

詳細は `references/platform-setup.md` を参照。

## ステップ 2: SDK導入

### Python (最も一般的)

```bash
# OpenTelemetry ベース
pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp

# Langfuse (LLM特化 - 推奨)
pip install langfuse

# Phoenix (ローカル開発向け)
pip install arize-phoenix openinference-instrumentation-openai
```

### TypeScript

```bash
# OpenTelemetry ベース
pnpm add @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/exporter-trace-otlp-http

# Langfuse
pnpm add langfuse

# Vercel AI SDK + OTel
pnpm add ai @ai-sdk/openai @opentelemetry/api
```

### Go

```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp
```

## ステップ 3: 計装パターン適用

`references/tracing-patterns.md` に言語別の具体的な計装パターンがある。

最低限計装すべき3つ：

1. **LLM呼び出し** — モデル名、トークン数、コスト、レイテンシ
2. **ツール呼び出し** — ツール名、成否、実行時間
3. **サブエージェント** — 委譲理由、内部呼び出し回数、合計トークン

## ステップ 4: 検証

```bash
# Jaeger の場合
docker run -d --name jaeger \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest

# エージェントを実行してトレースが記録されることを確認
# http://localhost:16686 でスパンツリーを確認
```

## チェックリスト

セットアップ完了の確認：

- [ ] トレーシングSDKがインストールされている
- [ ] LLM呼び出しがスパンとして記録される
- [ ] ツール呼び出しがスパンとして記録される
- [ ] サブエージェント呼び出しが親子スパンで記録される
- [ ] トークン数・コストがスパン属性に含まれる
- [ ] ローカルでトレースを可視化できる (Jaeger / Phoenix / Langfuse UI)
- [ ] エラー時にスパンステータスが ERROR になる
- [ ] 本番環境でプロンプト全文が記録されない（ハッシュのみ）
