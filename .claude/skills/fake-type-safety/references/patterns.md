# Fake Type Safety: 4 つのパターン詳細

LLM が書いた TypeScript に頻出する「型は通っているのに本番で落ちる」コードのパターン。

## Pattern 1: `any` で型エラーを揉み消す

### コード例

```typescript
const data: any = await fetch('/api/user').then(r => r.json());
data.doesNotExist.crash(); // 型エラーは出ないがランタイムで落ちる
```

### LLM の動機

エラーメッセージを見て「まず `any` にしましょう」と判断する。
理由は単純で、最短で「コンパイラを黙らせる」方法だから。

### なぜ危険か

`any` を経由した値はそれ以降すべての型チェックをすり抜ける。
たった一行の `any` が、コードベース全体の型保証を骨抜きにする。

### 検出シグナル

- `: any` の明示的アノテーション
- `as any` のキャスト
- `Array<any>`, `Record<string, any>`, `Promise<any>`
- 関数戻り値型の `: any`
- ジェネリック引数の `<any>`

## Pattern 2: `as` で無理やりキャスト

### コード例

```typescript
const response = await fetch('/api/user').then(r => r.json());
const user = response as User; // 嘘
console.log(user.email.toLowerCase()); // email がなければクラッシュ
```

### LLM の動機

「型を整えました」と報告できる形にしたい。
実際には何も検証していないが、コンパイラは通る。

### なぜ危険か

`as` は TypeScript への「これは X 型です、信じてください」という宣言。
ランタイムでは一切検証されない。

### 検出シグナル

- `as User`, `as Config` など named type への直接キャスト
- `as { ... }` インラインオブジェクト型へのキャスト
- 配列メソッド後の `.map(...) as T[]`

### 例外: 安全なキャスト

- `as const` (リテラル型への narrowing)
- 自分が型を作ったコンストラクタの直後 (`new X() as IX`)
- `satisfies` の後の `as` (typed narrowing)

## Pattern 3: `as unknown as Foo` 二段キャスト

### コード例

```typescript
const config = rawData as unknown as ServerConfig;
```

### LLM の動機

`as Foo` だけだと TypeScript が「型に互換性がありません」と警告する。
それを回避するため `unknown` を経由する。
これは「型システムを通すための儀式」であり、警告を消すこと自体が目的化している。

### なぜ最も危険か

- TypeScript が「これはおかしい」と警告した上での明示的な迂回
- 人間の開発者ですらほぼ書かない (出てきたら LLM 製を疑う)
- ランタイム検証ゼロ
- レビューで「なぜ unknown を経由した？」を確認しないと検知できない

### 検出シグナル

- `as unknown as`
- `as any as`
- `<unknown>` 経由の旧式キャスト

### 例外

- 型レベルプログラミングの一部（極めて稀）
- DOM API の特殊な型変換（`as unknown as HTMLInputElement` など）— この場合も Type Guard 推奨

## Pattern 4: `@ts-ignore` で完全黙殺

### コード例

```typescript
// @ts-ignore
const result = doSomething(wrongArgs);
```

### LLM の動機

「型エラーが出ているので、コメントで消しておきます」
本気でこれを「修正」だと思っている。

### なぜ危険か

- コンパイラを黙らせただけで、バグは何も直っていない
- 次の人が問題に気付けない
- `@ts-ignore` は次の行がエラーかどうかに関係なく無効化する
  → 後でその行が正しくなっても気付けない

### 検出シグナル

- `// @ts-ignore`
- `// @ts-nocheck` (ファイル全体を無効化、最悪)
- `// @ts-expect-error` (理由なし) — これは比較的マシだが理由コメント必須

### 推奨される代替

```typescript
// @ts-expect-error: <具体的な理由とリンク>
// 例: TypeScript 5.x のジェネリック推論バグ #58234, TS 6.0 で fix 予定
const result = doSomething(wrongArgs);
```

`@ts-expect-error` は「ここはエラーが出るはず」を期待する。
将来エラーが消えたら警告してくれるため、`@ts-ignore` よりはるかに安全。

## まとめ: 危険度ランキング

| 順位 | パターン | 危険度 | 検出難易度 |
|------|---------|--------|------------|
| 1 | `as unknown as Foo` | Critical | 易（grep一発） |
| 2 | `// @ts-nocheck` | Critical | 易 |
| 3 | `// @ts-ignore` | Critical | 易 |
| 4 | `: any` / `as any` | High | 中（正当ケースあり） |
| 5 | `as Foo` (named type) | High | 中（多数の偽陽性） |

## 共通する設計の臭い

これらのパターンが必要になる根本原因はだいたい以下のいずれか：

1. **外部入力をスキーマ検証していない** → Zod / Valibot / ArkType を導入
2. **型定義が現実と乖離している** → 型を実装に合わせて更新
3. **過剰に複雑なジェネリック** → シンプルな型に分解
4. **ライブラリの型定義が壊れている** → DefinitelyTyped に PR / 型を上書き宣言
