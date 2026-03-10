# /improve-english-prompt - AI臭さを除去する英文プロンプト改善

ユーザーが書いた英語のプロンプト・文章・ドキュメントから、AI生成っぽいパターン（AI slop）を検出し、自然な英語に書き換える。

## Trigger

ユーザーが「英語を直して」「AI臭い」「improve english」「英文改善」「deslopify」「tropes」等のキーワードを使ったとき、または英語の文章やプロンプトのレビュー・改善を依頼されたとき。

## Instructions

1. ユーザーから英語テキスト（プロンプト、ドキュメント、README、ブログ記事など）を受け取る
2. 下記の「AI Writing Tropes」チェックリストに照らして問題箇所を検出する
3. 検出結果を一覧で提示し、書き換え案を出力する
4. 必要に応じてファイルを直接修正する

## Rules

- 検出だけでなく、必ず具体的な書き換え案を提示する
- 書き換えは「自然な人間が書いた英語」を目指す：varied, imperfect, specific
- 1つのパターンが1回だけ出現する場合は許容範囲。複数のトロープが集中している箇所を優先的に修正する
- 元の意味を変えない。簡潔さと具体性を重視する
- プロンプト改善の場合は、AI への指示として機能するかも確認する

## AI Writing Tropes Checklist

Source: [tropes.fyi](https://tropes.fyi) by [ossama.is](https://ossama.is)

---

### Word Choice

#### "Quietly" and Other Magic Adverbs

Overuse of "quietly" and similar adverbs to convey subtle importance or understated power. AI reaches for these adverbs to make mundane descriptions feel significant. Also includes: "deeply", "fundamentally", "remarkably", "arguably".

**Avoid patterns like:**
- "quietly orchestrating workflows, decisions, and interactions"
- "the one that quietly suffocates everything else"
- "a quiet intelligence behind it"

#### "Delve" and Friends

"Delve" went from an uncommon English word to appearing in a staggering percentage of AI-generated text. Part of a family of overused AI vocabulary including "certainly", "utilize", "leverage" (as a verb), "robust", "streamline", and "harness".

**Avoid patterns like:**
- "Let's delve into the details..."
- "Delving deeper into this topic..."
- "We certainly need to leverage these robust frameworks..."

#### "Tapestry" and "Landscape"

Overuse of ornate or grandiose nouns where simpler words would do. Other offenders: "paradigm", "synergy", "ecosystem", "framework".

**Avoid patterns like:**
- "The rich tapestry of human experience..."
- "Navigating the complex landscape of modern AI..."
- "The ever-evolving landscape of technology..."

#### The "Serves As" Dodge

Replacing simple "is" or "are" with pompous alternatives like "serves as", "stands as", "marks", or "represents".

**Avoid patterns like:**
- "The building serves as a reminder of the city's heritage."
- "The station marks a pivotal moment in the evolution of regional transit."

---

### Sentence Structure

#### Negative Parallelism

The "It's not X -- it's Y" pattern. The single most commonly identified AI writing tell. Includes the causal variant "not because X, but because Y".

**Avoid patterns like:**
- "It's not bold. It's backwards."
- "Half the bugs you chase aren't in your code. They're in your head."

#### "Not X. Not Y. Just Z."

The dramatic countdown pattern. AI builds tension by negating two or more things before revealing the actual point.

**Avoid patterns like:**
- "Not a bug. Not a feature. A fundamental design flaw."

#### "The X? A Y."

Self-posed rhetorical questions answered immediately for dramatic effect.

**Avoid patterns like:**
- "The result? Devastating."
- "The worst part? Nobody saw it coming."

#### Anaphora Abuse

Repeating the same sentence opening multiple times in quick succession.

**Avoid patterns like:**
- "They could expose... They could offer... They could provide... They could create..."

#### Tricolon Abuse

Overuse of the rule-of-three pattern.

**Avoid patterns like:**
- "Products impress people; platforms empower them. Products solve problems; platforms create worlds."

#### "It's Worth Noting"

Filler transitions that signal nothing. Also includes: "Importantly", "Interestingly", "Notably".

#### Superficial Analyses

Tacking "-ing" phrases onto sentences to inject shallow analysis. "contributing to the region's rich cultural heritage", "underscoring its role as a dynamic hub".

#### False Ranges

"From X to Y" constructions where X and Y aren't on any real scale.

#### Gerund Fragment Litany

After making a claim, illustrating it with a stream of verbless gerund fragments. "Fixing small bugs. Writing straightforward features. Implementing well-defined tickets."

---

### Paragraph Structure

#### Short Punchy Fragments

Excessive use of very short sentences as standalone paragraphs for manufactured emphasis. "He published this. Openly. In a book. As a priest."

#### Listicle in a Trench Coat

Numbered or labeled points dressed up as continuous prose. "The first wall is... The second wall is... The third wall is..."

---

### Tone

#### "Here's the Kicker"

False suspense transitions. Also: "Here's the thing", "Here's where it gets interesting", "Here's what most people miss".

#### "Think of It As..."

The patronizing analogy. AI defaults to teacher mode and assumes the reader needs a metaphor.

#### "Imagine a World Where..."

The classic AI invitation to futurism.

#### False Vulnerability

Simulated self-awareness that reads as performative. "And yes, I'm openly in love with the platform model."

#### "The Truth Is Simple"

Asserting that something is obvious instead of proving it. "The reality is simpler and less flattering."

#### Grandiose Stakes Inflation

Everything is the most important thing ever. "This will fundamentally reshape how we think about everything."

#### "Let's Break This Down"

Pedagogical hand-holding even for expert audiences. Also: "Let's unpack this", "Let's explore", "Let's dive in".

#### Vague Attributions

"Experts argue that...", "Industry reports suggest..." without naming anyone.

#### Invented Concept Labels

Invented compound labels that sound analytical without being grounded: "the supervision paradox", "the acceleration trap", "workload creep".

---

### Formatting

#### Em-Dash Addiction

A human writer might use 2-3 per piece; AI will use 20+.

#### Bold-First Bullets

Every bullet point starts with bolded text. A telltale sign of AI-generated documentation.

#### Unicode Decoration

Use of unicode arrows, smart quotes, etc. Real writers typing in a text editor produce straight quotes and `->` or `=>`.

---

### Composition

#### Fractal Summaries

"What I'm going to tell you; what I'm telling you; what I just told you" at every level of the document.

#### The Dead Metaphor

Latching onto a single metaphor and repeating it 5-10 times across the entire piece.

#### Historical Analogy Stacking

Rapid-fire listing of historical companies or tech revolutions. "Apple didn't build Uber. Facebook didn't build Spotify..."

#### One-Point Dilution

Making a single argument and restating it 10 different ways across thousands of words.

#### Content Duplication

Repeating entire sections or paragraphs verbatim within the same piece.

#### The Signposted Conclusion

"In conclusion", "To sum up", "In summary". Competent writing doesn't need to announce it's concluding.

#### "Despite Its Challenges..."

The rigid formula where AI acknowledges problems only to immediately dismiss them.

---

**Remember: any of these patterns used once might be fine. The problem is when multiple tropes appear together or when a single trope is used repeatedly. Write like a human: varied, imperfect, specific.**

## Output Format

### インライン修正の場合

対象ファイルを直接編集し、変更箇所のサマリーを出力する。

### レビューのみの場合

以下の形式で出力する：

```
## AI Tropes 検出レポート

### 検出されたパターン
| # | 箇所 | トロープ名 | 該当テキスト |
|---|------|-----------|-------------|
| 1 | L12  | Em-Dash Addiction | "The problem -- and this is..." |
| 2 | L25  | Negative Parallelism | "It's not X -- it's Y" |

### 書き換え案
#### 1. (L12)
- Before: "The problem -- and this is the part nobody talks about -- is systemic."
- After: "The systemic problem gets overlooked."

#### 2. (L25)
- Before: ...
- After: ...

### 総評
{全体的なAI臭さのレベルと、特に気をつけるべきポイント}
```
