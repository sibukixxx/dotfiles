# AI エージェント開発の Observability ルール

## 原則: AIエージェントつくるなら初手o11y

AIエージェントを開発する際、**トレーシングは最初に組み込む**。
トレースデータさえあれば、細かい調整はコーディングエージェントに投げて直せる。
トレースがなければ、何が起きているか分からず改善のしようがない。

## 必須トレース対象

AIエージェントでは以下の3層を必ずトレースする：

### 1. LLM 呼び出し (最重要)

```
span: llm.call
├── attributes:
│   ├── llm.model          # モデル名 (gpt-4o, claude-sonnet-4-20250514, etc.)
│   ├── llm.provider       # プロバイダ (openai, anthropic, etc.)
│   ├── llm.temperature    # temperature
│   ├── llm.max_tokens     # max_tokens
│   ├── llm.tokens.input   # 入力トークン数
│   ├── llm.tokens.output  # 出力トークン数
│   ├── llm.tokens.total   # 合計トークン数
│   ├── llm.cost           # コスト (USD)
│   ├── llm.latency_ms     # レイテンシ
│   └── llm.stop_reason    # 停止理由 (end_turn, tool_use, max_tokens)
├── events:
│   ├── prompt.sent        # プロンプト送信（本番ではハッシュのみ）
│   └── response.received  # レスポンス受信
└── status: OK / ERROR
```

### 2. ツール呼び出し

```
span: tool.call
├── attributes:
│   ├── tool.name          # ツール名
│   ├── tool.args_hash     # 引数のハッシュ（ログ肥大防止）
│   ├── tool.result_size   # 結果サイズ
│   ├── tool.success       # 成否
│   └── tool.duration_ms   # 実行時間
├── events:
│   ├── tool.invoked       # 呼び出し時
│   └── tool.completed     # 完了時（エラー情報含む）
└── status: OK / ERROR
```

### 3. サブエージェント呼び出し

```
span: agent.delegate
├── attributes:
│   ├── agent.type         # エージェント種別
│   ├── agent.task         # 委譲されたタスクの要約
│   ├── agent.llm_calls    # 内部LLM呼び出し回数
│   ├── agent.tool_calls   # 内部ツール呼び出し回数
│   ├── agent.tokens.total # 合計消費トークン
│   └── agent.duration_ms  # 全体実行時間
├── children:              # 子スパンとしてLLM/ツール呼び出しがネスト
│   ├── llm.call
│   ├── tool.call
│   └── ...
└── status: OK / ERROR
```

## スパン階層の設計

```
trace: agent.run (ルートスパン)
├── llm.call              # 最初のLLM判断
├── tool.call             # ツール実行
├── llm.call              # 結果を見てLLM判断
├── agent.delegate        # サブエージェントに委譲
│   ├── llm.call
│   ├── tool.call
│   └── llm.call
├── llm.call              # サブエージェント結果を統合
└── agent.finalize        # 最終出力生成
```

## トレースに記録しないもの

- プロンプト全文（本番環境）→ ハッシュで代替
- ユーザーの個人情報 → マスキング必須
- APIキー・シークレット → 絶対に記録しない

## コスト追跡

各 `llm.call` スパンでコストを計算し、ルートスパンに集約する：

```
root_span.set_attribute("agent.total_cost_usd", total_cost)
root_span.set_attribute("agent.total_tokens", total_tokens)
```

## 実装チェックリスト

AIエージェントプロジェクトで最初にやること：

- [ ] トレーシングSDK導入 (OpenTelemetry or Langfuse or Phoenix)
- [ ] LLM呼び出しのラッパー関数にスパン計装
- [ ] ツール呼び出しのラッパー関数にスパン計装
- [ ] サブエージェント呼び出しにスパン計装
- [ ] トークン数・コストの自動記録
- [ ] ローカル開発用のトレースビューア (Jaeger / Phoenix UI)
- [ ] エラー時のスパンステータス設定

## なぜログではなくトレースか

| 観点 | ログ | トレース |
|------|------|----------|
| 構造 | フラットテキスト | 階層的なスパンツリー |
| 因果関係 | grep で手動追跡 | 親子関係が自動可視化 |
| LLM→Tool→LLMの流れ | 紐付け困難 | trace_id で自動紐付け |
| コスト分析 | 集計スクリプト必要 | スパン属性で即集計 |
| デバッグ | 「なぜこの判断をした？」が追えない | スパンツリーで判断過程を再現 |
| エージェント改善 | 何を直すべきか分からない | ボトルネック・失敗パターンが一目瞭然 |
