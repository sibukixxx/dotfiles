# 検出ロジック

## 推奨アプローチ

1. まず `scripts/detect.sh` で grep ベースの一次スキャン
2. 検出結果を Read で1件ずつ確認
3. 偽陽性を除外（テスト・型定義ファイル・正当な理由のあるもの）
4. 残った真陽性を [remediation.md](remediation.md) のレシピで修正

## grep パターン

### Pattern 1: any

```bash
# 明示的 any 型注釈
rg -n ': any\b' --type ts --type tsx
rg -n ': any\[' --type ts --type tsx        # any[] 配列
rg -n '<any>' --type ts --type tsx           # ジェネリック引数
rg -n 'Record<[^,]+,\s*any>' --type ts --type tsx
rg -n 'Promise<any>' --type ts --type tsx

# as any キャスト
rg -n 'as any\b' --type ts --type tsx
```

### Pattern 2: as キャスト

```bash
# 名前付き型へのキャスト（PascalCase で始まるもの）
rg -n '\bas [A-Z][A-Za-z0-9_]+(\[\])?$' --type ts --type tsx
rg -n '\bas [A-Z][A-Za-z0-9_]+\b' --type ts --type tsx
```

**除外すべき安全なケース:**
- `as const` — リテラル型 narrowing
- `as Date` — 既知の安全パターン（要文脈確認）
- 型ガード関数の `is` 戻り値

### Pattern 3: 二段キャスト

```bash
rg -n 'as unknown as\b' --type ts --type tsx
rg -n 'as any as\b' --type ts --type tsx
```

### Pattern 4: ts-ignore 系

```bash
rg -n '@ts-ignore' --type ts --type tsx
rg -n '@ts-nocheck' --type ts --type tsx
rg -n '@ts-expect-error\s*$' --type ts --type tsx   # 理由なしのもの
```

## 偽陽性の除外

以下のファイルは原則スキャン対象外：

- `*.d.ts` — 型定義ファイル（`any` が必要なケースあり）
- `*.test.ts` / `*.spec.ts` — テストでは部分モックに `as` を使うことがある
- `node_modules/` — 外部依存
- `dist/` / `build/` / `out/` — ビルド成果物
- `*.generated.ts` — コード生成物

## ESLint との併用

grep ベースの検出は手軽だが、ESLint ルールの方が正確：

```jsonc
// .eslintrc.json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/no-unsafe-member-access": "error",
    "@typescript-eslint/no-unsafe-call": "error",
    "@typescript-eslint/no-unsafe-return": "error",
    "@typescript-eslint/no-unsafe-argument": "error",
    "@typescript-eslint/consistent-type-assertions": [
      "error",
      { "assertionStyle": "never" }   // 厳格にやるなら as を全面禁止
    ],
    "@typescript-eslint/ban-ts-comment": [
      "error",
      {
        "ts-ignore": true,
        "ts-nocheck": true,
        "ts-expect-error": "allow-with-description",
        "minimumDescriptionLength": 10
      }
    ]
  }
}
```

## tsconfig の強化

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,    // 配列アクセスを T | undefined に
    "exactOptionalPropertyTypes": true
  }
}
```

`noUncheckedIndexedAccess` は特に効く。LLM が書きがちな
`array[0].foo` のようなコードに警告が出るようになる。

## AST ベース検出（高度）

grep では拾えない微妙なケースを検出するには `ts-morph` で AST を解析する：

```typescript
import { Project, SyntaxKind } from 'ts-morph';

const project = new Project({ tsConfigFilePath: './tsconfig.json' });

for (const sf of project.getSourceFiles()) {
  // any 型の変数
  sf.getVariableDeclarations()
    .filter(v => v.getType().isAny())
    .forEach(v => console.log(`${sf.getFilePath()}:${v.getStartLineNumber()} - any`));

  // as アサーション
  sf.getDescendantsOfKind(SyntaxKind.AsExpression)
    .forEach(a => console.log(`${sf.getFilePath()}:${a.getStartLineNumber()} - as cast`));
}
```

ただし大半のケースは grep で十分なので、まずは `scripts/detect.sh` を実行する。
