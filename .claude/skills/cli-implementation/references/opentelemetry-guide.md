# OpenTelemetry Guide for CLI Tools

## Overview

OpenTelemetry (OTel) provides standardized observability for CLIs:
- **Traces**: Span-based timing for phases
- **Events**: In-span logging for decisions
- **OTLP**: Standard protocol for exporters

## Why Not Just Logs?

| Logs | Traces |
|------|--------|
| Flat text | Hierarchical spans |
| Grep to correlate | Parent-child visible |
| Manual timing | Automatic duration |
| Local files | Jaeger/collectors |

## Setup by Language

### Rust

```toml
# Cargo.toml
[dependencies]
opentelemetry = "0.22"
opentelemetry_sdk = { version = "0.22", features = ["rt-tokio"] }
opentelemetry-otlp = { version = "0.15", features = ["http-proto"] }
tracing = "0.1"
tracing-opentelemetry = "0.23"
tracing-subscriber = "0.3"
```

```rust
use opentelemetry::trace::TracerProvider;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::runtime::Tokio;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

fn init_tracing(endpoint: &str) {
    let provider = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .http()
                .with_endpoint(endpoint),
        )
        .install_batch(Tokio)
        .expect("Failed to initialize tracer");

    let tracer = provider.tracer("cli-name");
    let telemetry = tracing_opentelemetry::layer().with_tracer(tracer);

    tracing_subscriber::registry()
        .with(telemetry)
        .init();
}

// Usage with tracing macros
#[tracing::instrument]
fn process_file(path: &Path) -> Result<()> {
    tracing::info!(path = %path.display(), "Processing file");
    // ...
}
```

### TypeScript/Node.js

```json
{
  "dependencies": {
    "@opentelemetry/api": "^1.7.0",
    "@opentelemetry/sdk-node": "^0.46.0",
    "@opentelemetry/exporter-trace-otlp-http": "^0.46.0",
    "@opentelemetry/auto-instrumentations-node": "^0.40.0"
  }
}
```

```typescript
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { trace } from "@opentelemetry/api";

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_ENDPOINT,
  }),
  serviceName: "cli-name",
});

sdk.start();

// Usage
const tracer = trace.getTracer("cli-name");

async function processFile(path: string) {
  return tracer.startActiveSpan("process_file", async (span) => {
    try {
      span.setAttribute("file.path", path);
      // Process...
      span.addEvent("processing_complete");
    } finally {
      span.end();
    }
  });
}
```

### Go

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer(endpoint string) func() {
    exporter, _ := otlptracehttp.New(
        context.Background(),
        otlptracehttp.WithEndpoint(endpoint),
        otlptracehttp.WithInsecure(),
    )

    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
    )
    otel.SetTracerProvider(tp)

    return func() { tp.Shutdown(context.Background()) }
}

// Usage
tracer := otel.Tracer("cli-name")

func processFile(ctx context.Context, path string) error {
    ctx, span := tracer.Start(ctx, "process_file")
    defer span.End()

    span.SetAttributes(attribute.String("file.path", path))
    // Process...
    span.AddEvent("processing_complete")
    return nil
}
```

## Span Design

### Naming Convention

```
{component}_{action}
```

Examples:
- `args_parse`
- `file_enumerate`
- `file_read`
- `item_process`
- `report_generate`
- `output_write`

### Attributes

Standard attributes:
- `file.path`: File being processed
- `file.size`: File size in bytes
- `item.count`: Number of items
- `error.type`: Error classification

### Events

Use events for:
- **Decisions**: Why a branch was taken
- **Progress**: Completion checkpoints
- **Cache**: Hits/misses
- **Warnings**: Non-fatal issues

```rust
span.add_event("cache_decision", vec![
    KeyValue::new("hit", true),
    KeyValue::new("key", "abc123"),
]);
```

## OTLP Configuration

### Endpoints

HTTP endpoint (default):
```
http://localhost:4318/v1/traces
```

gRPC endpoint:
```
http://localhost:4317
```

### Environment Variables

```bash
export OTEL_SERVICE_NAME=my-cli
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_TRACES_SAMPLER=always_on
```

## Jaeger Integration

### Docker Compose

```yaml
version: "3"
services:
  jaeger:
    image: jaegertracing/jaeger:latest
    ports:
      - "16686:16686"  # UI
      - "4317:4317"    # OTLP gRPC
      - "4318:4318"    # OTLP HTTP
    environment:
      - COLLECTOR_OTLP_ENABLED=true
```

### Using Jaeger UI

1. **Find traces**: Filter by service name
2. **Analyze spans**: Click to expand hierarchy
3. **Check events**: Look for decision points
4. **Export JSON**: Download for PR evidence

### JSON Export

```javascript
// Jaeger JSON structure
{
  "data": [{
    "traceID": "xxx",
    "spans": [{
      "spanID": "yyy",
      "operationName": "process_file",
      "duration": 1234,
      "logs": [{ "fields": [...] }]
    }]
  }]
}
```

## Performance Analysis

### Identifying Bottlenecks

1. Sort spans by duration
2. Look for unexpectedly long spans
3. Check events for clues
4. Compare runs with different inputs

### Critical Path

The critical path is the longest chain of sequential spans.
Use `jaeger_get_critical_path` if jaegermcp is available.

### Before/After Comparison

1. Run before optimization, export JSON
2. Apply optimization
3. Run after optimization, export JSON
4. Compare span durations
5. Document in PR with screenshots

## Graceful Shutdown

Always flush traces before exit:

```rust
// Rust
opentelemetry::global::shutdown_tracer_provider();
```

```typescript
// TypeScript
await sdk.shutdown();
```

```go
// Go
defer cleanup()
```
