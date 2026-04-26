# Claude Code 運用ルール (Opus 4.7+)

Anthropic 公式 [Best practices for using Claude Opus 4.7 with Claude Code](https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code) および現場知見を本リポジトリ向けに整理したルール。Opus 4.7 で挙動・推奨が変わった項目を扱う。

## 1. 指示スタイル: Scaffolding を外し、コンテキストを増やす

❌ やめる: 過剰な scaffolding（手取り足取りの逐次指示）

```
ファイル A を開いて、3行目を読んで、関数 B の戻り値を確認して、
それから C に書き戻して、最後に必ず double-check してから報告して
```

✅ 推奨: 計画と広いコンテキストを与えて任せる

```
このディレクトリ全体で X を実装したい。背景は Y、制約は Z。
plan を立てて、影響範囲を洗い出してから着手して。
```

理由:
- Opus 4.7 は instruction を **literal** に解釈する。逐次指示は逆効果
- "double-check" や "interim status" の強制は、自己検証機能と重複してノイズ化
- 「senior contractor に委譲する」発想で接する

ただし「コンテキストを与える」と「曖昧に投げる」は別物。**目的・制約・受入条件** は明確に。

## 2. Effort Level: 既定は xhigh、max は本当に難しいときだけ

| Level | 用途 |
|-------|------|
| low | 単純な編集・確認 |
| medium | 通常タスク |
| high | 難度のある実装 |
| **xhigh（既定）** | **コーディング既定**。Claude Code がこのレベルにデフォルト設定 |
| max | 本当に難しい問題のみ。過思考（overthinking）と diminishing returns あり |

❌ `max` を反射的に常用する → "4.7 が遅い" の主因
✅ 既定の `xhigh` で十分。max は意識的に選ぶ

参考: [Effort - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/effort)

## 3. Permission モード: `--dangerously-skip-permissions` は隔離環境のみ

❌ ローカル開発で常用 → 過去事例: root から `rm -rf` で全ファイル消失
❌ 信用するから外す → prompt injection 耐性なし

✅ 代替: **auto mode**（Anthropic が `--dangerously-skip-permissions` 問題を受けて新設、別の classifier モデルが各アクションを審査）
✅ それでも skip する場合: Docker / CI / 完全隔離 VM 内でのみ

参考:
- [Claude Code auto mode: a safer way to skip permissions](https://www.anthropic.com/engineering/claude-code-auto-mode)
- [Choose a permission mode - Claude Code Docs](https://code.claude.com/docs/en/permission-modes)

## 4. 長時間セッション: 重要度で監視レベルを変える

4.7 は長時間自律稼働の精度が上がったが、**完全放置は別問題**。

| 作業の性質 | 監視レベル |
|---------|----------|
| ローカルのリファクタ・テスト追加 | 完了通知のみで OK |
| 機能実装（PR 作成前） | 区切りでレビュー |
| 本番影響あり（DB マイグレーション、デプロイ、外部 API 課金）| 各ステップで承認 |
| マルチエージェント並列稼働 | 10〜15 分ごとに監視サイクル |

実運用報告では「セッション内で訂正が定着しないケース」がある。**critical な作業ほど監視を厚く**。

参考: [Claude Opus 4.7 Field Report: Eight Hours of Autonomous Work](https://dev.to/kai_outputs/claude-opus-47-field-report-eight-hours-of-autonomous-work-10e3)

## 5. Subagent: 1 レスポンスで済む仕事には呼ばない

❌ 反射的に毎回 subagent → multi-agent は **4-7x のトークン消費**
❌ "丁寧そう" だから subagent → コンテキスト分裂で品質劣化することもある

✅ 呼ぶべき場合:
- 独立した複数項目への並列展開（fan-out）
- 大量ファイル読み込みでメインコンテキストを保護
- 専門性の異なる調査の並行
- 親が結果に依存しない監査・検証

✅ 呼ばないべき場合:
- 1 関数の修正など、目に見えている範囲の作業
- 文脈を引き継ぎながら対話的に進めるべきタスク

参考: [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)

## 6. 検証: Trust but Verify

4.7 は self-verification が改善したが、Anthropic alignment 評価でも「largely well-aligned, **not fully ideal**」。

❌ agent の summary を信じて完了とする
❌ 「テスト通った」だけで品質保証扱いする

✅ 必須の verify:
- agent の **summary は意図** であって実際の変更ではない。差分を読む
- ビルド・型チェック・テストを実行（CLAUDE.md の Build/Test Command Detection ルール）
- UI 変更は実ブラウザで動作確認
- 重要な変更はコミット前に `git diff` を読む

参考: [Best practices for using Claude Opus 4.7 with Claude Code](https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code)

## 7. Adaptive Thinking（旧 budget は廃止）

`thinking: { type: "enabled", budget_tokens: N }` は 4.7 で **使えなくなった**。代わりに adaptive thinking が既定で、モデルが必要に応じて自動判断する。

プロンプトで影響を与える方法:
- 深く考えてほしい: 「think carefully before responding」
- 速く返してほしい: 「prioritize responding quickly」

参考: [Adaptive thinking - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)

## まとめチェックリスト

- [ ] scaffolding ではなく context を提供しているか
- [ ] effort level は xhigh（既定）か、max を意識的に選んだか
- [ ] `--dangerously-skip-permissions` を使うなら隔離環境か
- [ ] 長時間タスクの重要度に見合う監視を設計したか
- [ ] subagent を呼ぶ前に「1 レスポンスで済まないか」確認したか
- [ ] agent 完了報告を summary だけで信じず、差分・テスト・実機で検証したか
