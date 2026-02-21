---
name: cli-implementation
description: Guide for implementing production-grade CLI tools with observability, performance monitoring, and quality standards. Use when building CLI applications, adding OpenTelemetry/tracing, implementing command-line tools, or when user mentions "CLI", "command line", "observability", "traces", "spans", "OTel", "Jaeger", or performance optimization.
---

# CLI Implementation Guide

Build production-grade CLI tools with observability and quality standards.

## References

- **OpenTelemetry Guide**: See [references/opentelemetry-guide.md](references/opentelemetry-guide.md) for tracing setup
- **CLI Quality Checklist**: See [references/quality-checklist.md](references/quality-checklist.md) for comprehensive checks

## Core Philosophy

Agentic Coding accelerates feature development but can neglect non-functional requirements.
**Make the CLI observable first** to enable fact-based optimization instead of guesswork.

## Observability-First Approach

### Why Traces Matter

Without OTel:
- "Probably slow here" -> guesswork optimization
- "Add more logs" -> harder to read
- "What was the repro?" -> no record

With OTel:
- "Slow spot visible in span" -> fix specific location
- "Decision recorded in event" -> trace why it's slow
- "Jaeger JSON/screenshot in PR" -> evidence of change

### Minimal OpenTelemetry Setup

#### Step 1: Add SDK

```rust
// Rust example
use opentelemetry::trace::{Tracer, TracerProvider};
use opentelemetry_otlp::WithExportConfig;

fn init_tracer(endpoint: &str) -> impl Tracer {
    let provider = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .http()
                .with_endpoint(endpoint),
        )
        .install_batch(opentelemetry_sdk::runtime::Tokio)
        .expect("Failed to initialize tracer");

    provider.tracer("cli-name")
}
```

```typescript
// TypeScript example
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_ENDPOINT || "http://localhost:4318/v1/traces",
  }),
});
sdk.start();
```

#### Step 2: Instrument Key Phases

Create spans for these phases:
1. **Argument parsing**
2. **Input enumeration** (file discovery)
3. **Input reading**
4. **Processing** (per-item spans)
5. **Report generation**
6. **Output writing**

```rust
tracer.in_span("parse_args", |_| {
    // Argument parsing
});

tracer.in_span("enumerate_inputs", |_| {
    // File discovery
});

tracer.in_span("process", |cx| {
    for item in items {
        tracer.in_span(&format!("process_{}", item.name), |_| {
            // Per-item processing
        });
    }
});
```

#### Step 3: Record Events

Add events for significant decisions:

```rust
span.add_event("cache_hit", vec![
    KeyValue::new("key", cache_key),
]);

span.add_event("parallel_execution", vec![
    KeyValue::new("workers", worker_count as i64),
]);
```

### Jaeger Setup

```bash
# Start Jaeger with OTLP support
docker run -d --name jaeger \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/jaeger:latest
```

Access UI at http://localhost:16686

### CLI Flag

```
--otel <ENDPOINT>    Export traces to OTLP endpoint (e.g., http://localhost:4318)
```

## CLI Architecture Patterns

### Standard Entry Point

```rust
fn main() -> Result<()> {
    // 1. Parse args (before tracing init)
    let args = Args::parse();

    // 2. Init tracing if requested
    let _guard = if let Some(endpoint) = &args.otel {
        Some(init_tracer(endpoint))
    } else {
        None
    };

    // 3. Run with top-level span
    tracer.in_span("cli_run", |_| {
        run(args)
    })
}
```

### Error Handling

```rust
// Record errors as span events
tracer.in_span("operation", |cx| {
    match perform_operation() {
        Ok(result) => result,
        Err(e) => {
            cx.span().record_error(&e);
            cx.span().set_status(Status::Error {
                description: e.to_string().into(),
            });
            return Err(e);
        }
    }
})
```

### Progress Reporting

```rust
// Emit events for progress
for (i, item) in items.iter().enumerate() {
    span.add_event("progress", vec![
        KeyValue::new("current", i as i64),
        KeyValue::new("total", items.len() as i64),
    ]);
    process(item)?;
}
```

## Quality Checklist

### Functional Requirements
- [ ] All commands work as documented
- [ ] Help text is accurate and complete
- [ ] Exit codes are meaningful (0=success, 1=error, etc.)
- [ ] Input validation with clear error messages

### Non-Functional Requirements
- [ ] OpenTelemetry tracing implemented
- [ ] Key phases have spans
- [ ] Decisions recorded as events
- [ ] Performance benchmarks captured
- [ ] Error handling with span status

### Agentic Coding Integration
- [ ] Jaeger JSON exportable for analysis
- [ ] Screenshots attachable to PRs
- [ ] Traces machine-readable for automation
- [ ] Clear span names for filtering

## Development Loop with OTel

1. **Implement feature** (Agent does this)
2. **Run with tracing**: `cli --otel http://localhost:4318`
3. **Analyze in Jaeger**: Find slow spans
4. **Optimize specific location**: Evidence-based
5. **Compare traces**: Before/after JSON
6. **Document in PR**: Screenshots + JSON

## Common Span Patterns

### File Processing

```
cli_run
├── parse_args
├── enumerate_files
│   └── [per-directory spans]
├── read_files
│   └── [per-file spans]
├── process_files
│   └── [per-file spans with events]
├── generate_report
└── write_output
```

### API Calls

```
cli_run
├── parse_args
├── authenticate
├── fetch_data
│   ├── page_1
│   ├── page_2
│   └── ...
├── transform
└── output
```

## Performance Investigation

### Using Jaeger

1. Find slow trace in Jaeger UI
2. Identify longest span
3. Check events for clues
4. Export JSON for PR evidence

### Using MCP (jaegermcp)

```
# Search spans
jaeger_search_spans service=my-cli span_name=process

# Get critical path
jaeger_get_critical_path trace_id=xxx
```

## Exit Codes Convention

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | IO error |
| 4 | Configuration error |
