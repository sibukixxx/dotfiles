# Layer Separation Examples

## Example 1: 議事録変換スキル（内部→外部向け）

### ❌ Before: Layer Mixing (モノリシックな設計)

`CLAUDE.md` に処理手順とドメイン知識が混在:
```markdown
# プロジェクトAのClaude設定

議事録を変換するときは、/docs/minutes/ から読んで /output/external/ に書き出す。
田中PMと山田CTOの発言は外部向けに含めてよいが、コスト情報は絶対に削除すること。
「フェーズ2」は外部向けには「テスト工程」と書き換える。
マークダウン形式で、クライアント向けのトーンで書くこと。
```

**問題点**:
- 処理パス (`/docs/minutes/`) がCLAUDE.mdに書かれている
- 「田中PM」という固有名詞が処理ロジックに埋め込まれている
- 別プロジェクトに使い回せない

---

### ✅ After: Layer Separated（分離後）

**`CLAUDE.md`** — ドメイン知識のみ:
```markdown
## Stakeholders
| Name / Role | Can appear in external outputs? |
|---|---|
| 田中PM | ✅ Yes |
| 山田CTO | ✅ Yes |
| 鈴木（財務） | ❌ No — internal only |

## Internal vs External Boundary
Must NEVER appear externally:
- コスト・工数の数値
- 財務担当者の発言

## Terminology Glossary
| Internal term | External term |
|---|---|
| フェーズ2 | テスト工程 |
| 本番環境移行 | リリース |

## Reporting Style
External (client): フォーマル、サマリーのみ、A4 1枚
```

**`skills/meeting-minutes-converter/SKILL.md`** — 処理のみ:
```markdown
## Processing Steps
1. Read from: /docs/minutes/<date>.md
2. Load CLAUDE.md → extract: internal_boundary, terminology, stakeholders
3. Filter: remove any content or speakers matching internal_boundary
4. Translate: apply terminology glossary
5. Restructure: summarize per reporting_style.external
6. Write to: /output/external/<date>-external.md
```

**横展開**: プロジェクトBでも同じskillファイルを使い、CLAUDE.mdだけ書き換えればOK。

---

## Example 2: 既存プロジェクトの分析と分離提案

**ユーザーが渡したCLAUDE.md（混在している例）**:
```markdown
毎週月曜の朝、/reports/週報.md を読んで要約を作る。
クライアントはA社で、担当は佐藤部長。
A社は製造業で、品質基準はISO 9001準拠。
「不適合品」という言葉は報告書に使わないこと（代わりに「要改善品」）。
要約は3点以内の箇条書きで、月曜9時にSlackの#client-reportingに投稿する。
```

**Claudeの分析結果**:

| 行 | 種別 | 移動先 |
|---|---|---|
| 毎週月曜... /reports/週報.md を読んで | 処理 | skill: weekly-summary |
| クライアントはA社、担当は佐藤部長 | ドメイン知識 | CLAUDE.md: stakeholders |
| 製造業、ISO 9001準拠 | ドメイン知識 | CLAUDE.md: regulatory_constraints |
| 「不適合品」→「要改善品」 | ドメイン知識 | CLAUDE.md: terminology |
| 3点以内の箇条書き | ドメイン知識 | CLAUDE.md: reporting_style |
| 月曜9時にSlackへ投稿 | 処理 | skill: weekly-summary (cron + Slack step) |

---

## Example 3: スキルの横展開

**元プロジェクト（茶輸出）のskill: lead-research**
```
処理: 対象国のバイヤーリストを生成 → 各社の輸入実績を調査 → CSVに出力
```

**プロジェクトBへの横展開（食品加工機械の輸出）**:
- skillファイル: 変更なし
- CLAUDE.mdを書き換えるだけ:
  - industry: 食品加工機械
  - target_markets: ベトナム、タイ、インドネシア
  - key_regulations: CE認証、各国の機械安全基準
  - internal_boundary: 仕入れ原価、代理店マージン率

**結果**: 同じ処理ロジックが、全く異なるドメインのリード調査を実行する。
