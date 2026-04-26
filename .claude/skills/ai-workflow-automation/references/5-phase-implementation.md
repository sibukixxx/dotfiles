# 5フェーズ実装手順（堅牢版）

元記事の 5 フェーズに **観測性・テスト・セキュリティ・コスト** を統合した堅牢版。各フェーズに **成果物（deliverables）** と **完了条件（DoD）** を明示する。

---

## Phase 1: ワークフロー棚卸し（Week 1-2）

元記事の Week 1 は楽観的。実態は 1〜2 週間。

### 成果物

`workflows.yaml`（または同等のドキュメント）に以下を全ワークフロー分記録：

```yaml
- id: weekly-status-report
  area: operations
  current_state: manual          # manual / partially_automated / automated
  trigger: 毎週金曜 15:00
  steps:
    - name: CRM データ取得
      classification: 🟢          # 🟢=auto / 🟡=AI assist / 🔴=human
      data_sensitivity: 社内      # public / internal / PII / regulated
      time_minutes: 20
      tools: [Salesforce]
    - name: 数値検算
      classification: 🟡
      data_sensitivity: 社内
      time_minutes: 15
    - name: ナラティブ執筆
      classification: 🟡
      data_sensitivity: 社内
      time_minutes: 45
    - name: 経営層への送信判断
      classification: 🔴
      data_sensitivity: 社内
      time_minutes: 5
  total_time_minutes: 85
  frequency_per_week: 1
  weekly_time_cost: 85 minutes
  failure_impact: 中  # 低/中/高（誤った数値が経営判断に使われたら？）
  customer_facing: false
```

### 完了条件 (DoD)

- [ ] 営業 / マーケ / サポート / 運営 / 経理の 5 領域すべて棚卸し済み
- [ ] 各ステップに 🟢🟡🔴 + データ機密性 + customer_facing フラグが付与されている
- [ ] 自動化候補（🟢🟡）が **時間削減量で降順** に並んでいる
- [ ] **顧客対面（customer_facing: true）** のワークフローには「最初に作らない」マーカー

### よくある失敗

- 「全部 🟢」と楽観評価 → 後で人間判断が必要だったことに気付き手戻り
- データ機密性を考慮せず PII を AI に流す設計をしてしまう
- 失敗時の影響評価を怠る → 高リスクワークフローから着手して事故

---

## Phase 2: アーキテクチャ設計（Week 3）

各ワークフローを 5 コンポーネント + 拡張要素で設計する。

### 5コンポーネント + 拡張

| コンポーネント | 設計内容 | 本 repo の規約 |
|---------------|---------|--------------|
| **Trigger** | webhook / cron / event / manual | レート制御、idempotency key |
| **Input Processing** | 抽出 / 正規化 / コンテキスト取得 | PII マスキング・スキーマバリデーション |
| **AI Processing** | system prompt / tools / モデル選択 | プロンプトを Git 管理。`prompts/v1.0.0/` のように versioning |
| **Output Routing** | 宛先 / フォーマット / フォールバック | 失敗時の DLQ（dead letter queue） |
| **Quality Check** | 自動検証 / 人間レビュー / 信頼度しきい値 | confidence < threshold で human-in-the-loop |
| **🆕 Observability** | tracing / metrics / logging | `.claude/CLAUDE.md` の o11y 規約に準拠（`llm.call`, `tool.call`, `agent.delegate` スパン） |
| **🆕 Cost Budget** | per-run 上限 / 月次上限 / アラート | $0.50/run, $200/月 等具体値 |
| **🆕 Security** | secret 管理 / 権限スコープ / 監査ログ | OWASP Top 10 準拠 |
| **🆕 Failure Mode** | retry / circuit breaker / fallback / rollback | 何回 retry するか、retry 間隔、最終的にどこへ |

### 設計図テンプレ

```
+----------+    +------------------+    +---------------+    +--------+    +-------+
| Trigger  | -> | Input Processing | -> | AI Processing | -> | Output | -> | QC    |
| (cron)   |    | (PII mask + ctx) |    | (Claude+tools)|    | (Slack)|    | (auto)|
+----------+    +------------------+    +---------------+    +--------+    +-------+
                         |                      |                  |            |
                         v                      v                  v            v
                    [Trace span]         [Trace span]       [Trace span]  [Trace span]
                         |                      |                  |            |
                         +----------------------+------------------+------------+
                                                |
                                                v
                                    [Central observability backend]
                                         (Langfuse / Phoenix / OTel)
```

### 完了条件 (DoD)

- [ ] 5+4 コンポーネントすべて記述済み
- [ ] トレース設計図あり（どのスパンが何を記録するか）
- [ ] コスト上限が **数値で** 設定されている
- [ ] PII / シークレットの取扱いが明記されている
- [ ] 失敗時の挙動が retry / fallback / DLQ レベルで決まっている
- [ ] **rollback 手順** が書かれている（変更前の状態に戻す方法）

---

## Phase 3: コア3ワークフロー構築（Week 4-8）

**順序**: Report Factory → Content Engine → Email Center。記事の逆順。

### TDD アプローチ

各ワークフローを Red → Green → Refactor で構築：

1. **Red**: 期待する出力（fixture）を先に書く。「この入力に対しこの出力が出ること」を assertion で表現
2. **Green**: 最小プロンプト + ツールで通す
3. **Refactor**: プロンプト整理、コスト最適化、可読性向上

### Report Factory（最初に作る）

- **トリガ**: cron（金曜 15:00）
- **入力**: CRM / アナリティクス API（READ ONLY token）
- **AI**: 数値検算 + ナラティブ生成
- **出力**: PDF/Markdown を共有ドライブへ + Slack 通知
- **QC**: 数値整合性自動チェック（合計が一致するか） + 異常値フラグ（前期比 >20%） + 経営サマリは人間レビュー後に配信
- **失敗時**: retry 3 回 → 失敗で「手動でやって」Slack 通知

なぜ最初か: 内部向けで顧客に飛び火しない、データ構造化、頻度が低くデバッグ余裕あり。

### Content Engine（次）

- **トリガ**: 月曜朝 cron
- **入力**: トレンド情報 + コンテンツカレンダー
- **AI**: ネタ出し → 人間が3つ選ぶ（HITL）→ 下書き → 各プラットフォーム向け再構成
- **出力**: ドラフトをコンテンツフォルダへ
- **QC**: voice guide 適合度の自動スコアリング + 必ず人間レビュー後に公開
- **失敗時**: ドラフト破棄、人間に通知

### Email Operations Center（最後）

リスクが高い。**前 2 つで仕組みが成熟してから着手**。

- 必須: 顧客返信は **100% 人間承認** から始める
- 段階的に「定型応答のみ自動送信」を解禁
- 誤分類率を週次でレビュー、99%+ になるまで自動送信を増やさない

### 完了条件 (DoD)

各ワークフローについて：

- [ ] テストケース ≥ 5 件（成功 / 失敗 / 異常入力 / コスト上限超過 / モデル劣化）
- [ ] 本番投入前に **shadow mode**（並行稼働で出力を比較）を 1 週間以上実施
- [ ] トレースが o11y バックエンドに流れている
- [ ] コストダッシュボードで per-run / 月次が見える
- [ ] runbook あり（「壊れたとき何を見るか」「どう戻すか」）

---

## Phase 4: ワークフロー連携（Week 9-10）

### 疎結合の原則

各ワークフローは **イベントを emit するだけ**。他ワークフローはそれを listen する。一つが落ちても他は動く。

```
Email Center emit "new_lead" event
                ↓
         (event bus: Redis / SQS / EventBridge)
                ↓
    Lead Qualification listens → emit "qualified_lead"
                ↓
    Meeting Prep listens → emit "meeting_brief_ready"
                ↓
    Reporter aggregates events → next weekly report
```

### ベンダーロックイン回避

- プロンプトを **モデル非依存** に抽象化（Claude 4 専用構文に依存しすぎない）
- 重要ワークフローは **最低 2 モデルで動作確認**（Claude / GPT / Gemini のうち 2）
- LLM 呼び出しを **薄いラッパー** で抽象化（モデル切替が 1 ファイルで済むように）

### 完了条件 (DoD)

- [ ] イベントスキーマがドキュメント化されている
- [ ] 1 ワークフローを停止しても他が動くことを実証（chaos test）
- [ ] LLM 呼び出しが抽象化レイヤを通っている
- [ ] モデル切替手順が runbook にある

---

## Phase 5: 監視・改善（永続）

### 必須メトリクス

| メトリクス | 目標 | 監視頻度 |
|----------|------|--------|
| Success rate | ≥ 95% | リアルタイム |
| Latency P50/P95/P99 | ワークフロー固有 | リアルタイム |
| Cost per run | 想定の 1.5x 以内 | 日次 |
| Monthly cost | 予算上限内 | 日次（アラート） |
| Quality score（10% sampling） | ≥ 4/5 | 週次 |
| Trace 完全性 | 100% | リアルタイム |
| Security incident | 0 | 即時 |

### 改善サイクル

| 周期 | やること |
|-----|--------|
| 日次 | コスト・エラー率の異常検知 |
| 週次 | 品質サンプリング、最低スコアの workflow を診断 |
| 月次 | プロンプトバージョン更新、A/B テスト結果反映 |
| 四半期 | 新モデル / 新 MCP / 新ツールで既存 workflow を upgrade 検討 |
| 年次 | データ保持・GDPR ポリシー見直し |

### 完了条件 (DoD)

- [ ] ダッシュボードがチームで見られる状態
- [ ] アラートが Slack / PagerDuty に飛ぶ
- [ ] 月次レビュー会議の枠が確保されている
- [ ] post-mortem テンプレートがある（事故ったとき書く）

---

## 現実的なタイムライン

元記事は Week 1-8。実態は副業 / 兼任で **3-6 ヶ月**。専任なら **6-10 週間**。最初の workflow 1 つを動かすだけでも **2-3 週間**。

「すぐ全部自動化」は幻想。1 つずつ堅牢に積む。
