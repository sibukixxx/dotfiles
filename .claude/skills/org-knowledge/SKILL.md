---
name: org-knowledge
description: |
  組織エージェント向けの共有ナレッジベース。SES営業プロセス、提案書テンプレート、
  ブランドガイドライン、競合調査手順をreferencesとして提供する。
  各エージェントが参照する社内マニュアル・ガイドラインの集約先。
references:
  - references/ses-sales-manual.md
  - references/proposal-guide.md
  - references/brand-guidelines.md
  - references/competitive-research-guide.md
  - references/yuho-analysis.md
  - references/roic-management.md
  - references/group-tax-consolidation.md
  - references/mbo-legal-tax.md
---

# org-knowledge: 組織共有ナレッジ

各エージェントが参照する社内マニュアル・ガイドラインを集約したナレッジベース。

## 含まれるガイドライン

| ガイドライン | 対象エージェント | 内容 |
|-------------|----------------|------|
| SES営業マニュアル | ses-sales | SES営業の全プロセス |
| 提案書ガイド | proposal-writer | 提案書・見積書のテンプレート |
| ブランドガイドライン | content-marketer | トーン&マナー・表記統一 |
| 競合調査ガイド | strategy-analyst | 競合調査の手順・テンプレート |
| 有報分析ガイド | accountant | 有価証券報告書の3視点分析 |
| ROIC経営ガイド | accountant | ROIC/WACC/EVA/資本コスト管理 |
| グループ通算制度 | accountant | 損益通算・加入離脱・税効果会計 |
| MBO法務税務 | accountant | MBOストラクチャー・TOB・税務 |

## 使い方

各エージェントは必要に応じて `references/` 配下のガイドラインを参照する。
直接 `/org-knowledge` として呼び出す必要はない。
