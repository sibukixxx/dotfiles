# トレーシングプラットフォーム選定ガイド

## 比較表

| プラットフォーム | LLM特化 | セルフホスト | クラウド | OTel互換 | コスト追跡 | 評価機能 | セットアップ難度 |
|------------------|---------|-------------|---------|---------|-----------|---------|----------------|
| **Langfuse** | ○ | ○ | ○ | ○ | ○ | ○ | 低 |
| **Phoenix (Arize)** | ○ | ○ | ○ | ○ | △ | ○ | 低 |
| **Jaeger** | × | ○ | × | ○ | × | × | 低 |
| **Langsmith** | ○ | × | ○ | × | ○ | ○ | 低 |
| **OpenTelemetry Collector** | × | ○ | × | ○ | × | × | 中 |

## 推奨: 用途別

### ローカル開発 → Phoenix

最速で始められる。`pip install` だけで UI 付きトレースビューア。

```bash
pip install arize-phoenix

# Python から起動
python -c "import phoenix as px; px.launch_app()"
# → http://localhost:6006 でUI表示
```

OpenAI/Anthropic の自動計装:

```bash
pip install openinference-instrumentation-openai
pip install openinference-instrumentation-anthropic
```

```python
from openinference.instrumentation.anthropic import AnthropicInstrumentor
from phoenix.otel import register

tracer_provider = register(endpoint="http://localhost:6006/v1/traces")
AnthropicInstrumentor().instrument(tracer_provider=tracer_provider)

# これだけで Anthropic API 呼び出しが自動トレースされる
import anthropic
client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=100,
)
# → Phoenix UI にスパンが表示される
```

### チーム開発 → Langfuse

LLM 特化の機能が充実。コスト追跡・プロンプト管理・評価が統合。

#### セルフホスト (Docker Compose)

```yaml
# docker-compose.yml
services:
  langfuse:
    image: langfuse/langfuse:latest
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/langfuse
      NEXTAUTH_SECRET: mysecret
      NEXTAUTH_URL: http://localhost:3000
      SALT: mysalt
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: langfuse
    volumes:
      - langfuse_db:/var/lib/postgresql/data

volumes:
  langfuse_db:
```

```bash
docker compose up -d
# → http://localhost:3000 でUI表示
```

#### Python 統合

```python
from langfuse import Langfuse

langfuse = Langfuse(
    public_key="pk-...",  # Langfuse UIから取得
    secret_key="sk-...",
    host="http://localhost:3000",  # セルフホストの場合
)

# デコレータベース (最も簡単)
from langfuse.decorators import observe

@observe(as_type="generation")
def call_llm(messages, model="claude-sonnet-4-20250514"):
    response = client.messages.create(model=model, messages=messages)
    return response
```

#### TypeScript 統合

```typescript
import Langfuse from "langfuse";

const langfuse = new Langfuse({
  publicKey: "pk-...",
  secretKey: "sk-...",
  baseUrl: "http://localhost:3000",
});

// トレース作成
const trace = langfuse.trace({ name: "agent-run" });
const generation = trace.generation({
  name: "llm-call",
  model: "claude-sonnet-4-20250514",
  input: messages,
});

const response = await client.messages.create({ model, messages });

generation.end({
  output: response.content,
  usage: {
    input: response.usage.input_tokens,
    output: response.usage.output_tokens,
  },
});
```

### 既存 OTel 基盤あり → OTLP エクスポーター追加

既に Jaeger や Grafana Tempo を使っているなら、エクスポーターを追加するだけ。

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

provider = TracerProvider()
processor = BatchSpanProcessor(
    OTLPSpanExporter(endpoint="http://localhost:4318/v1/traces")
)
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
```

### Jaeger (汎用トレーシング)

LLM 特化機能はないが、OTel エコシステムとの親和性が高い。

```bash
docker run -d --name jaeger \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

- UI: `http://localhost:16686`
- OTLP gRPC: `http://localhost:4317`
- OTLP HTTP: `http://localhost:4318/v1/traces`

## 環境変数テンプレート

`.env.example` に以下を追加：

```bash
# === Observability ===

# OTLP (Jaeger / OTel Collector)
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Langfuse
LANGFUSE_PUBLIC_KEY=pk-...
LANGFUSE_SECRET_KEY=sk-...
LANGFUSE_HOST=http://localhost:3000

# Phoenix
PHOENIX_COLLECTOR_ENDPOINT=http://localhost:6006/v1/traces

# 共通
OTEL_SERVICE_NAME=my-agent
```

## プラットフォーム選定フローチャート

```
Q1: LLM のコスト追跡・プロンプト管理が必要？
├── Yes → Q2: チームで使う？
│         ├── Yes → Langfuse (セルフホスト or Cloud)
│         └── No  → Phoenix (ローカル)
└── No  → Q3: 既に OTel 基盤がある？
          ├── Yes → OTLP エクスポーター追加
          └── No  → Jaeger (シンプル)
```
