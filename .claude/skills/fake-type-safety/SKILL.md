---
name: fake-type-safety
description: TypeScriptで「型は通っているが本番で落ちる」コード（fake type safety）を検出・修正するスキル。LLMが書いたTSコードに頻出する4パターン（any揉み消し / asキャスト / as unknown as 二段キャスト / @ts-ignore）を検出し、Zod等のランタイムバリデーションや型ガードで安全に修正する。「TypeScriptをレビューして」「型安全性チェック」「fake type safety」「any使ってない？」「as キャスト確認」「ts-ignore 探して」「型の嘘」「LLMが書いたTS見て」「tracecheck」などで発動。
trigger:
  - "fake type safety"
  - "fake-type-safety"
  - "型安全性チェック"
  - "型の嘘"
  - "型が通っているのに落ちる"
  - "any 揉み消し"
  - "as キャスト"
  - "as unknown as"
  - "ts-ignore"
  - "@ts-ignore"
  - "@ts-nocheck"
  - "@ts-expect-error"
  - "tracecheck"
  - "LLMが書いたTypeScript"
  - "TypeScript レビュー"
  - "型システムを欺く"
references:
  - references/patterns.md
  - references/detection.md
  - references/remediation.md
scripts:
  - scripts/detect.sh
---

# Fake Type Safety Detector

TypeScriptで「コンパイラは黙っているが、ランタイムでは何も保証されていない」コードを検出する。

> コンパイラが何も言わないコード = 何も保証されないコード。
> 「型が通ったから安全」という油断が、一番危ない。

## 検出対象の 4 パターン

| # | パターン | 例 | 危険度 |
|---|---------|-----|--------|
| 1 | `any` で型エラー揉み消し | `const data: any = ...` | High |
| 2 | `as` で無理やりキャスト | `response as User` | High |
| 3 | `as unknown as Foo` 二段キャスト | `raw as unknown as ServerConfig` | Critical |
| 4 | `@ts-ignore` で完全黙殺 | `// @ts-ignore` | Critical |

詳細は [references/patterns.md](references/patterns.md) を参照。

## 使い方

### Step 1: スキャン実行

```bash
bash .claude/skills/fake-type-safety/scripts/detect.sh [target-dir]
```

引数を省略すると `src/` をデフォルトでスキャンする。
`*.test.ts` / `*.d.ts` / `node_modules` は除外される。

### Step 2: 検出結果のトリアージ

各検出箇所について以下を判断：

1. **正当な理由があるか** — 例：
   - サードパーティ製の型定義が壊れている
   - 段階的な型導入の途中
   - 動的型のメタプログラミング
2. **修正可能か** — 大半のケースは [references/remediation.md](references/remediation.md) のレシピで修正可能
3. **正当性が確認できれば理由をコメントで明記** — `// any: 理由`

### Step 3: 修正

パターン別の修正レシピは [references/remediation.md](references/remediation.md) を参照：

- パターン1 (`any`) → `unknown` + 型ガード or Zod
- パターン2 (`as`) → 型ガード関数 or Zod schema
- パターン3 (`as unknown as`) → 設計を疑う、Zod でランタイムバリデーション
- パターン4 (`@ts-ignore`) → 根本原因を直す。やむを得ない場合は `@ts-expect-error` + 理由

### Step 4: コミット前チェック

CIに組み込む場合の設定例：

```bash
# package.json
"scripts": {
  "lint:type-safety": "bash .claude/skills/fake-type-safety/scripts/detect.sh src"
}
```

ESLint ルールの併用を推奨：
- `@typescript-eslint/no-explicit-any`
- `@typescript-eslint/no-unsafe-assignment`
- `@typescript-eslint/no-unsafe-member-access`
- `@typescript-eslint/ban-ts-comment`

## なぜこれが起きるか

LLM は「エラーが出ない状態」を「正しい状態」だと誤認しやすい。
特に以下の状況で fake type safety が生まれる：

- ユーザーから「型エラー直して」と言われた
- テストを書かずに実装している
- 外部APIレスポンスを扱っている（最頻出）
- リファクタリング中に型不整合が発生した

### LLM が書いた TS の見分け方

- ファイル先頭に大量の `any` 型変数
- 連続する `as` キャスト
- `as unknown as` が一つでもある（人間はほぼ書かない）
- `// @ts-ignore` の理由コメントなし

## Examples

### Example 1: APIレスポンスの「型整え」

ユーザー: 「TypeScriptをレビューして」

```typescript
// 検出 (Pattern 1 + 2)
const data: any = await fetch('/api/user').then(r => r.json());
const user = data as User;
```

修正提案:

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});

const raw = await fetch('/api/user').then(r => r.json());
const user = UserSchema.parse(raw); // ランタイムで検証
```

### Example 2: 設定ファイル読み込み

ユーザー: 「any 使ってない？」

```typescript
// 検出 (Pattern 3)
const config = rawData as unknown as ServerConfig;
```

修正提案:

```typescript
const ServerConfigSchema = z.object({
  port: z.number().int().positive(),
  host: z.string(),
});

const config = ServerConfigSchema.parse(rawData);
```

### Example 3: 黙殺された型エラー

ユーザー: 「@ts-ignore 探して」

```typescript
// 検出 (Pattern 4)
// @ts-ignore
const result = doSomething(wrongArgs);
```

修正提案:
1. まず `wrongArgs` の型を確認し、本来の引数型に合わせる
2. やむを得ない場合のみ `@ts-expect-error` に置き換え + 理由コメント

```typescript
// @ts-expect-error: TypeScript 5.x のジェネリック推論バグ (#XXXX) — 2026-Q3 の TS 6.0 で解消予定
const result = doSomething(wrongArgs);
```

## 関連

- 検出ロジックの詳細: [references/detection.md](references/detection.md)
- 修正レシピ集: [references/remediation.md](references/remediation.md)
- パターン詳細解説: [references/patterns.md](references/patterns.md)
- 外部ツール: tracecheck.dev (検出器名: `fake-type-safety`)
