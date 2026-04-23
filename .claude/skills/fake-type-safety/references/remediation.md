# 修正レシピ集

各パターンの正しい修正方法。「コンパイラを黙らせる」のではなく「実際に安全にする」。

## 修正の基本原則

1. **外部入力はスキーマで検証** — Zod / Valibot / ArkType
2. **`any` の代わりに `unknown` + 型ガード**
3. **`as` の代わりに型ガード関数**
4. **`@ts-ignore` の代わりに根本原因を修正**

## Pattern 1: any の修正

### Before

```typescript
const data: any = await fetch('/api/user').then(r => r.json());
console.log(data.email);
```

### After A: Zod でランタイム検証（推奨）

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string(),
});
type User = z.infer<typeof UserSchema>;

const raw: unknown = await fetch('/api/user').then(r => r.json());
const user = UserSchema.parse(raw); // ランタイムで検証、失敗時は ZodError
console.log(user.email);
```

### After B: 軽量 — unknown + 型ガード

```typescript
function isUser(x: unknown): x is User {
  return (
    typeof x === 'object' &&
    x !== null &&
    'email' in x &&
    typeof (x as { email: unknown }).email === 'string'
  );
}

const raw: unknown = await fetch('/api/user').then(r => r.json());
if (!isUser(raw)) throw new Error('Invalid user response');
console.log(raw.email);
```

### 正当な any のケース（理由コメント必須）

```typescript
// any: サードパーティ SDK の型定義が壊れている (issue: foo/bar#123)
const sdkInternal: any = (sdk as any).__internal;
```

## Pattern 2: as キャストの修正

### Before

```typescript
const user = response as User;
```

### After: 型ガード関数で narrowing

```typescript
function assertUser(x: unknown): asserts x is User {
  if (!isUser(x)) throw new Error('Not a User');
}

assertUser(response);
const user = response; // 型は User に narrowing 済み
```

### After: Zod が最強

```typescript
const user = UserSchema.parse(response);
```

### 残してよい as

```typescript
// as const — リテラル型化
const COLORS = ['red', 'blue'] as const;

// satisfies + as — 検証済みの narrowing
const config = { port: 3000 } satisfies ServerConfig as ServerConfig;

// HTMLElement の特殊な narrowing（DOM API）
const input = e.target as HTMLInputElement;  // 文脈上明らか
```

## Pattern 3: as unknown as の修正

`as unknown as` が出てきたら、ほぼ必ず設計に問題がある。

### Before

```typescript
const config = rawData as unknown as ServerConfig;
```

### After: Zod で検証

```typescript
import { z } from 'zod';

const ServerConfigSchema = z.object({
  port: z.number().int().min(1).max(65535),
  host: z.string().min(1),
  timeout: z.number().positive().optional(),
});

const config = ServerConfigSchema.parse(rawData);
```

### After: 段階的 narrowing

```typescript
function parseConfig(raw: unknown): ServerConfig {
  if (typeof raw !== 'object' || raw === null) {
    throw new Error('Config must be an object');
  }
  const obj = raw as Record<string, unknown>;
  if (typeof obj.port !== 'number') throw new Error('Invalid port');
  if (typeof obj.host !== 'string') throw new Error('Invalid host');
  return { port: obj.port, host: obj.host };
}

const config = parseConfig(rawData);
```

### 例外: DOM API の文脈

```typescript
// やむを得ないケース（DOM API の特殊型）
const customEvent = e as unknown as CustomEvent<MyDetail>;
// より良い: instanceof チェック
if (e instanceof CustomEvent) { ... }
```

## Pattern 4: @ts-ignore の修正

### 原則: 根本原因を直す

```typescript
// Before
// @ts-ignore
const result = doSomething(wrongArgs);

// After: そもそも引数を正しくする
const correctArgs = transformArgs(wrongArgs);
const result = doSomething(correctArgs);
```

### やむを得ない場合: @ts-expect-error + 理由

```typescript
// @ts-expect-error: TS 5.x のジェネリック推論バグ
// (microsoft/TypeScript#58234, TS 6.0 で解消予定)
// 期日: 2026-Q3 に再評価
const result = doSomething(wrongArgs);
```

`@ts-expect-error` の利点：
- 将来エラーが消えたら、TypeScript が「不要な抑制」と警告してくれる
- `@ts-ignore` はエラーが消えても黙ったまま腐っていく

### @ts-nocheck は撲滅

ファイル冒頭の `// @ts-nocheck` は、そのファイル全体の型保証を破壊する。
リファクタリングで分割するか、必要な箇所だけ `@ts-expect-error` に置き換える。

## 推奨ライブラリ

| ライブラリ | 特徴 | 用途 |
|-----------|------|------|
| [Zod](https://zod.dev/) | 最も普及、型推論強力 | API レスポンス、設定、フォーム |
| [Valibot](https://valibot.dev/) | バンドルサイズ小、tree-shakable | フロントエンド |
| [ArkType](https://arktype.io/) | TS 構文に近い、最速 | 型定義から自動 schema 化 |
| [io-ts](https://github.com/gcanti/io-ts) | fp-ts エコシステム | 関数型志向のチーム |

## チェックリスト（コミット前）

- [ ] 新規追加した `any` には理由コメントがある
- [ ] `as` は安全なケース（`const` / `satisfies` / 型ガード後）のみ
- [ ] `as unknown as` は使っていない、または明確な理由がある
- [ ] `@ts-ignore` は使わず、`@ts-expect-error` + 10 文字以上の理由
- [ ] 外部入力（API, file, env, user input）には Zod 等のランタイム検証
- [ ] `tsconfig.json` の `strict: true` が有効
