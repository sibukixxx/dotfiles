# CLAUDE.md Template — Domain Knowledge Layer

> Copy this template for each new project. Fill in every section.
> This file is read by all skills before executing. Incomplete sections cause silent errors.

---

## Project Overview

```
Project name: 
Phase: [kickoff / in-progress / closing]
Primary goal: 
Key constraint: 
```

---

## Stakeholders

| Name / Role | Responsibility | What they care about | Reporting frequency |
|---|---|---|---|
| (例) 田中PM | 全体進行管理 | コスト・スケジュール遵守 | 週次 |
| (例) 山田CTO | 技術判断 | 品質・技術負債 | 月次 |
| (例) クライアントA社 | 発注元 | 成果物・リスク | 隔週 |

---

## Internal vs External Boundary

### Must NEVER appear in external outputs:
- (例) 内部コスト・工数の数値
- (例) チームメンバーの個人評価
- (例) 未確定の仕様変更案
- (例) ベンダーとの価格交渉内容

### Safe to share externally:
- (例) マイルストーンの達成状況
- (例) 合意済み仕様の変更履歴
- (例) リスクと対策（承認済みのもののみ）

---

## Industry / Regulatory Constraints

```
Industry: 
Key regulations: 
Prohibited content: 
Required disclaimers: 
```

(例 — 医療系プロジェクト)
- 未承認の効能効果に関する記述禁止
- 個人を特定できる患者情報の記載禁止
- "治療" という言葉は承認済みの文脈のみ使用可

---

## Terminology Glossary

| Term | Meaning in this project | Do NOT confuse with |
|---|---|---|
| (例) "フェーズ2" | テスト環境への展開工程 | 開発フェーズ2（別プロジェクト） |
| (例) "承認" | クライアント最終承認（稟議通過後） | 内部レビューOK |

---

## Reporting Style by Audience

### 内部向け（チーム）
- 粒度: 詳細（課題の原因・担当者まで）
- トーン: 率直、技術的な表現OK
- 分量: 制限なし

### 外部向け（クライアント）
- 粒度: サマリー（What & So what のみ）
- トーン: フォーマル、専門用語は平易に言い換え
- 分量: A4 1枚相当が目安

### 経営向け（役員報告）
- 粒度: KPIと意思決定事項のみ
- トーン: 結論ファースト
- 分量: 3点以内の箇条書き

---

## Active Skills

Skills configured for this project and what they depend on from this file:

| Skill | Reads from CLAUDE.md |
|---|---|
| (例) meeting-minutes-converter | internal_boundary, terminology, reporting_style |
| (例) weekly-report-generator | stakeholders, reporting_style |
| (例) slack-digest | stakeholders, terminology |

---

## Current Project Status

```
Last updated: 
Current milestone: 
Blockers: 
Next decision needed: 
```
