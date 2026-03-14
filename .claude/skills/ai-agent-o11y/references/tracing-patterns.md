# AI エージェント トレーシングパターン

言語別の計装パターン集。コピペして使えるコードを提供する。

## Python

### LLM 呼び出しラッパー

```python
from opentelemetry import trace
import time
import hashlib

tracer = trace.get_tracer("agent")


def traced_llm_call(client, messages, model="claude-sonnet-4-20250514", **kwargs):
    """LLM呼び出しをトレースするラッパー"""
    with tracer.start_as_current_span("llm.call") as span:
        span.set_attribute("llm.model", model)
        span.set_attribute("llm.provider", _detect_provider(client))
        span.set_attribute("llm.temperature", kwargs.get("temperature", 1.0))
        span.set_attribute("llm.max_tokens", kwargs.get("max_tokens", 4096))

        # プロンプトはハッシュのみ記録（プライバシー保護）
        prompt_hash = hashlib.sha256(str(messages).encode()).hexdigest()[:16]
        span.set_attribute("llm.prompt_hash", prompt_hash)

        start = time.monotonic()
        try:
            response = client.messages.create(
                model=model, messages=messages, **kwargs
            )

            duration_ms = (time.monotonic() - start) * 1000
            span.set_attribute("llm.latency_ms", duration_ms)
            span.set_attribute("llm.tokens.input", response.usage.input_tokens)
            span.set_attribute("llm.tokens.output", response.usage.output_tokens)
            span.set_attribute("llm.tokens.total",
                response.usage.input_tokens + response.usage.output_tokens)
            span.set_attribute("llm.stop_reason", response.stop_reason)
            span.set_attribute("llm.cost", _calc_cost(
                model, response.usage.input_tokens, response.usage.output_tokens
            ))

            span.add_event("response.received", {
                "tokens": response.usage.input_tokens + response.usage.output_tokens,
            })

            return response

        except Exception as e:
            span.set_status(trace.StatusCode.ERROR, str(e))
            span.record_exception(e)
            raise


def _detect_provider(client):
    module = type(client).__module__
    if "anthropic" in module:
        return "anthropic"
    if "openai" in module:
        return "openai"
    return "unknown"


def _calc_cost(model, input_tokens, output_tokens):
    """モデル別コスト計算（USD）"""
    # 2025年時点の概算レート
    rates = {
        "claude-sonnet-4-20250514": (3.0 / 1_000_000, 15.0 / 1_000_000),
        "claude-haiku-4-5-20251001": (0.80 / 1_000_000, 4.0 / 1_000_000),
        "gpt-4o": (2.50 / 1_000_000, 10.0 / 1_000_000),
    }
    input_rate, output_rate = rates.get(model, (0, 0))
    return round(input_tokens * input_rate + output_tokens * output_rate, 6)
```

### ツール呼び出しラッパー

```python
import json

def traced_tool_call(tool_name, tool_fn, args):
    """ツール呼び出しをトレースするラッパー"""
    with tracer.start_as_current_span("tool.call") as span:
        span.set_attribute("tool.name", tool_name)
        args_hash = hashlib.sha256(json.dumps(args, sort_keys=True).encode()).hexdigest()[:16]
        span.set_attribute("tool.args_hash", args_hash)

        start = time.monotonic()
        try:
            result = tool_fn(**args)

            duration_ms = (time.monotonic() - start) * 1000
            span.set_attribute("tool.duration_ms", duration_ms)
            span.set_attribute("tool.success", True)
            span.set_attribute("tool.result_size", len(str(result)))

            span.add_event("tool.completed")
            return result

        except Exception as e:
            duration_ms = (time.monotonic() - start) * 1000
            span.set_attribute("tool.duration_ms", duration_ms)
            span.set_attribute("tool.success", False)
            span.set_status(trace.StatusCode.ERROR, str(e))
            span.record_exception(e)
            raise
```

### サブエージェント呼び出し

```python
def traced_agent_delegate(agent_type, task, agent_fn, **kwargs):
    """サブエージェント呼び出しをトレースするラッパー"""
    with tracer.start_as_current_span("agent.delegate") as span:
        span.set_attribute("agent.type", agent_type)
        span.set_attribute("agent.task", task[:200])  # タスク要約は200文字まで

        start = time.monotonic()
        try:
            result = agent_fn(task=task, **kwargs)

            duration_ms = (time.monotonic() - start) * 1000
            span.set_attribute("agent.duration_ms", duration_ms)

            # サブエージェントの内部メトリクスを集約
            if hasattr(result, "metrics"):
                span.set_attribute("agent.llm_calls", result.metrics.llm_calls)
                span.set_attribute("agent.tool_calls", result.metrics.tool_calls)
                span.set_attribute("agent.tokens.total", result.metrics.total_tokens)
                span.set_attribute("agent.cost", result.metrics.total_cost)

            return result

        except Exception as e:
            span.set_status(trace.StatusCode.ERROR, str(e))
            span.record_exception(e)
            raise
```

### エージェントループ全体

```python
def run_agent(task, max_iterations=10):
    """エージェントのメインループ"""
    with tracer.start_as_current_span("agent.run") as root_span:
        root_span.set_attribute("agent.task", task[:200])
        root_span.set_attribute("agent.max_iterations", max_iterations)

        messages = [{"role": "user", "content": task}]
        total_tokens = 0
        total_cost = 0.0

        for i in range(max_iterations):
            root_span.add_event("iteration.start", {"iteration": i + 1})

            # LLM呼び出し
            response = traced_llm_call(client, messages, model="claude-sonnet-4-20250514")
            total_tokens += response.usage.input_tokens + response.usage.output_tokens

            # ツール呼び出しがあれば実行
            if response.stop_reason == "tool_use":
                for block in response.content:
                    if block.type == "tool_use":
                        result = traced_tool_call(
                            block.name, tools[block.name], block.input
                        )
                        messages.append({"role": "assistant", "content": response.content})
                        messages.append({
                            "role": "user",
                            "content": [{"type": "tool_result",
                                         "tool_use_id": block.id,
                                         "content": str(result)}]
                        })
            else:
                break

        root_span.set_attribute("agent.iterations", i + 1)
        root_span.set_attribute("agent.total_tokens", total_tokens)
        root_span.set_attribute("agent.total_cost_usd", total_cost)

        return response
```

## TypeScript

### LLM 呼び出しラッパー

```typescript
import { trace, SpanStatusCode } from "@opentelemetry/api";
import { createHash } from "crypto";

const tracer = trace.getTracer("agent");

interface LLMCallResult {
  content: string;
  usage: { inputTokens: number; outputTokens: number };
  stopReason: string;
}

export async function tracedLLMCall(
  client: any,
  messages: any[],
  model = "claude-sonnet-4-20250514",
  options: Record<string, any> = {}
): Promise<LLMCallResult> {
  return tracer.startActiveSpan("llm.call", async (span) => {
    span.setAttribute("llm.model", model);
    span.setAttribute("llm.temperature", options.temperature ?? 1.0);
    span.setAttribute("llm.max_tokens", options.maxTokens ?? 4096);

    const promptHash = createHash("sha256")
      .update(JSON.stringify(messages))
      .digest("hex")
      .slice(0, 16);
    span.setAttribute("llm.prompt_hash", promptHash);

    const start = performance.now();
    try {
      const response = await client.messages.create({
        model,
        messages,
        ...options,
      });

      const durationMs = performance.now() - start;
      span.setAttribute("llm.latency_ms", durationMs);
      span.setAttribute("llm.tokens.input", response.usage.input_tokens);
      span.setAttribute("llm.tokens.output", response.usage.output_tokens);
      span.setAttribute("llm.stop_reason", response.stop_reason);

      span.addEvent("response.received", {
        tokens: response.usage.input_tokens + response.usage.output_tokens,
      });

      span.end();
      return response;
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: String(error) });
      span.recordException(error as Error);
      span.end();
      throw error;
    }
  });
}
```

### ツール呼び出しラッパー

```typescript
export async function tracedToolCall<T>(
  toolName: string,
  toolFn: (args: any) => Promise<T>,
  args: Record<string, any>
): Promise<T> {
  return tracer.startActiveSpan("tool.call", async (span) => {
    span.setAttribute("tool.name", toolName);
    const argsHash = createHash("sha256")
      .update(JSON.stringify(args))
      .digest("hex")
      .slice(0, 16);
    span.setAttribute("tool.args_hash", argsHash);

    const start = performance.now();
    try {
      const result = await toolFn(args);
      span.setAttribute("tool.duration_ms", performance.now() - start);
      span.setAttribute("tool.success", true);
      span.end();
      return result;
    } catch (error) {
      span.setAttribute("tool.duration_ms", performance.now() - start);
      span.setAttribute("tool.success", false);
      span.setStatus({ code: SpanStatusCode.ERROR, message: String(error) });
      span.recordException(error as Error);
      span.end();
      throw error;
    }
  });
}
```

## Go

### LLM 呼び出しラッパー

```go
package agent

import (
	"context"
	"crypto/sha256"
	"fmt"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("agent")

type LLMResponse struct {
	Content      string
	InputTokens  int
	OutputTokens int
	StopReason   string
}

func TracedLLMCall(ctx context.Context, client LLMClient, messages []Message, model string) (*LLMResponse, error) {
	ctx, span := tracer.Start(ctx, "llm.call")
	defer span.End()

	span.SetAttributes(
		attribute.String("llm.model", model),
	)

	promptHash := fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprint(messages))))[:16]
	span.SetAttributes(attribute.String("llm.prompt_hash", promptHash))

	start := time.Now()
	resp, err := client.CreateMessage(ctx, model, messages)
	durationMs := float64(time.Since(start).Milliseconds())

	span.SetAttributes(attribute.Float64("llm.latency_ms", durationMs))

	if err != nil {
		span.SetStatus(codes.Error, err.Error())
		span.RecordError(err)
		return nil, err
	}

	span.SetAttributes(
		attribute.Int("llm.tokens.input", resp.InputTokens),
		attribute.Int("llm.tokens.output", resp.OutputTokens),
		attribute.Int("llm.tokens.total", resp.InputTokens+resp.OutputTokens),
		attribute.String("llm.stop_reason", resp.StopReason),
	)

	span.AddEvent("response.received", trace.WithAttributes(
		attribute.Int("tokens", resp.InputTokens+resp.OutputTokens),
	))

	return resp, nil
}
```

## Langfuse 統合パターン

OpenTelemetry の代わりに Langfuse を使う場合（LLM特化で楽）:

```python
from langfuse.decorators import observe, langfuse_context

@observe(as_type="generation")
def llm_call(client, messages, model="claude-sonnet-4-20250514", **kwargs):
    langfuse_context.update_current_observation(
        model=model,
        metadata={"temperature": kwargs.get("temperature", 1.0)},
    )
    response = client.messages.create(model=model, messages=messages, **kwargs)
    langfuse_context.update_current_observation(
        usage={
            "input": response.usage.input_tokens,
            "output": response.usage.output_tokens,
        },
    )
    return response

@observe()
def tool_call(tool_name, tool_fn, args):
    langfuse_context.update_current_observation(
        name=f"tool:{tool_name}",
        metadata={"args_keys": list(args.keys())},
    )
    return tool_fn(**args)

@observe()
def run_agent(task):
    """デコレータだけでスパンが自動ネストされる"""
    response = llm_call(client, [{"role": "user", "content": task}])
    if needs_tool(response):
        result = tool_call("search", search_fn, {"query": "..."})
        response = llm_call(client, [...])  # ツール結果を含めて再度LLM
    return response
```

## セマンティック規約

OpenTelemetry の [Semantic Conventions for GenAI](https://opentelemetry.io/docs/specs/semconv/gen-ai/) に準拠する属性名：

| 属性 | 規約名 | 例 |
|------|--------|-----|
| モデル名 | `gen_ai.request.model` | `claude-sonnet-4-20250514` |
| プロバイダ | `gen_ai.system` | `anthropic` |
| 入力トークン | `gen_ai.usage.input_tokens` | `1523` |
| 出力トークン | `gen_ai.usage.output_tokens` | `847` |
| 停止理由 | `gen_ai.response.finish_reasons` | `["stop"]` |
| Temperature | `gen_ai.request.temperature` | `0.7` |
| Max tokens | `gen_ai.request.max_tokens` | `4096` |

> 本ガイドでは簡潔さのため `llm.*` プレフィックスを使っているが、
> OTel エコシステムとの互換性が必要なら `gen_ai.*` に揃えること。
