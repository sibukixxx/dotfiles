---
name: improve-english-prompt
description: |
  AI臭さ（AI slop）を検出・除去する文章改善スキル。英語・日本語の両方に対応。
  プロンプト・ドキュメント・README・ブログ記事・提案書のAI生成パターンを特定し、
  自然な人間らしい文章に書き換える。
  「英語を直して」「AI臭い」「improve english」「英文改善」「deslopify」「tropes」
  「日本語を直して」「AI文体」「humanize」「文章改善」などで発動。
references:
  - references/ai-writing-tropes.md
  - references/ai-writing-tropes-ja.md
---

# /improve-english-prompt - AI臭さを除去する文章改善

ユーザーが書いたテキストから AI Writing Tropes を検出し、自然な文章に書き換える。英語・日本語の両方に対応。

## Instructions

1. ユーザーからテキスト（プロンプト、ドキュメント、README、ブログ記事など）を受け取る
2. **言語を自動判定** し、該当するチェックリストを適用:
   - 英語 → `references/ai-writing-tropes.md`
   - 日本語 → `references/ai-writing-tropes-ja.md`
3. 検出結果を一覧で提示し、書き換え案を出力する
4. 必要に応じてファイルを直接修正する

## Rules

- 検出だけでなく、必ず具体的な書き換え案を提示する
- 書き換えは「自然な人間が書いた英語」を目指す：varied, imperfect, specific
- 1つのパターンが1回だけ出現する場合は許容範囲。複数のトロープが集中している箇所を優先的に修正する
- 元の意味を変えない。簡潔さと具体性を重視する
- プロンプト改善の場合は、AI への指示として機能するかも確認する

## 主要トロープカテゴリ（クイックリファレンス）

### 英語
| カテゴリ | 代表パターン |
|---------|------------|
| Word Choice | "quietly", "delve", "tapestry", "serves as" |
| Sentence | "It's not X -- it's Y", "The X? A Y.", tricolon abuse |
| Paragraph | Short punchy fragments, listicle in a trench coat |
| Tone | "Here's the kicker", "Think of it as...", stakes inflation |
| Formatting | Em-dash addiction, bold-first bullets, unicode decoration |
| Composition | Fractal summaries, dead metaphor, signposted conclusion |

### 日本語
| カテゴリ | 代表パターン |
|---------|------------|
| 語彙 | 「さらに」「加えて」連打、「包括的」「革新的」 |
| 文構造 | 三点セット強制、定型結論「今後の展開が注目されます」 |
| トーン | 曖昧な出典、過剰なヘッジング、追従的表現 |
| 書式 | **太字:** 箇条書き、emダッシュ過用 |
| 高次 | 魂のない平板な文章、チャットボット残留表現 |

## Output Format

### インライン修正の場合

対象ファイルを直接編集し、変更箇所のサマリーを出力する。

### レビューのみの場合

```
## AI Tropes 検出レポート

### 検出されたパターン
| # | 箇所 | トロープ名 | 該当テキスト |
|---|------|-----------|-------------|
| 1 | L12  | Em-Dash Addiction | "The problem -- and this is..." |

### 書き換え案
#### 1. (L12)
- Before: "The problem -- and this is the part nobody talks about -- is systemic."
- After: "The systemic problem gets overlooked."

### 総評
{全体的なAI臭さのレベルと、特に気をつけるべきポイント}
```

## Troubleshooting

### トロープが多すぎて書き換え量が膨大な場合
複数トロープが集中している箇所から優先的に対応。1回のパスで全修正しなくてよい。

### 技術文書で意図的なパターンとの区別が難しい場合
文脈を考慮し、技術的に必要な表現（例: API文書での箇条書き）は維持する。

### 原文の意図が不明な場合
推測で書き換えず、ユーザーに確認する。
