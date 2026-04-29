---
name: storybook-story-patterns
description: Storybook story ファイルの書き方・Template 集を提供する skill。小型 showcase 集約・大型 Dialog variant 分離・Form + Wrapper・Context Wrapper・超複雑 orchestrator 例外の 5 Template と、共通 Snippet、Container/Presentation 選択基準、GraphQL 型の扱いを含む。新規 story 作成・既存 story の書き換え両方で使う。
---

# Storybook Story Patterns Skill

## このスキルはいつ使うか

- 新規 story ファイルを書くとき（どの雛形を使うか決めたい）
- 既存 story を書き直すとき（Template に寄せたい）
- GraphQL fragment 依存の mock データを構築するとき
- 親 context 必須なコンポーネント（Tabs / Form / Accordion 等）の story を書くとき

snapshot 判定は `storybook-snapshot-policy`、Apollo mock（admin/ は MockedProvider、web/ は MSW）は `storybook-feature-mocking` を参照。

## Container vs Presentation の選択

**Presentation 層で story を作るのが既定**。本プロジェクトでは 155 コンポーネント中 81（52%）が `XxxPresentation` を export しており、hooks 依存の重い feature 系ほどこの比率が高い。

### なぜ Presentation が既定か

- Container は `useQuery`・`useRouter`・Jotai store 等に依存し、Storybook で動かすには mock が重い
- Presentation は props で全て受け取るため、mock データをそのまま渡せば確定的に render される
- Snapshot の signal/noise 比が高い（外部副作用なし = 安定した render）

### 判断手順

1. `rg "export const \w+Presentation" <target>/index.tsx` で Presentation の有無を確認
2. **ある → Presentation で story を作る**（既定）
3. **ない → Container で story を作る**（hook 依存は `storybook-feature-mocking` の MSW handler で mock、または Template 4 で skill 例外）

### JSDoc は Container と Presentation の両方に書く

- Container：「どの hook でデータを取り、Presentation にどう流すか」
- Presentation：「props で何を受け取り、どう描画するか」
- Container の JSDoc に「Storybook では `XxxPresentation` を使う」旨を明記する

## GraphQL fragment データ取得

story で GraphQL fragment 型の mock データが必要なとき、以下の手順で shape を確認する：

1. 対象コンポーネントの `graphql\`fragment XxxFragment on YyyType { ... }\`` 定義を grep
   ```bash
   rg -n "fragment <FragmentName>" src/ --type ts --type tsx
   ```
2. フラグメントを使う query / mutation を探し、実際の返り値 shape を見る
   ```bash
   rg -n "<FragmentName>" src/hooks src/features -g '*.ts' -g '*.tsx'
   ```
3. 生成済みの型を確認
   ```bash
   rg -n "export type <FragmentName>Fragment" src/generated/graphql.ts
   ```

### Mock データの必須フィールド

- **`__typename` は必須**（Apollo cache が使うため、`as const` 付与）
  ```ts
  { __typename: "WorkspaceUser" as const, id: "u1", ... }
  ```
- 忘れると型エラー：`Property '__typename' is missing in type '...'`
- nested オブジェクトにも `__typename` を付ける
- nullable フィールドは `null` を明示的に渡す（`undefined` だと型エラーになることがある）

### GraphQL enum は string literal union 型として扱う

codegen は GraphQL enum を **TypeScript enum ではなく string literal union 型** として出力する：

```ts
// 生成例（src/generated/graphql.ts）
export type CalendarSyncStatus = "ERROR" | "OK" | "SYNCING"
```

そのため `CalendarSyncStatus.OK` のような値参照は **`'CalendarSyncStatus' only refers to a type, but is being used as a value here` 型エラー**になる。mock 値は string literal + `as const` で指定する：

```ts
// NG
syncStatus: CalendarSyncStatus.OK

// OK
syncStatus: "OK" as const
```

enum 風の型を見つけたら `grep "^export type <Name>" src/generated/graphql.ts` で union か object か判別する。

## Story Template 集

### Template 1: 小型 showcase 集約

表示領域が小さく variant が複数あるコンポーネント向け。全 variant を 1 snapshot で検出する。

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { StoryItem, StoryShowcase } from "@/components/storybook"

import { Component } from "./index"

const meta = {
  args: { /* 必須 props のデフォルト */ },
  argTypes: {
    // 使い方が非自明な prop のみ description
  },
  component: Component,
  parameters: {
    backgrounds: { default: "light" },
    docs: {
      description: {
        component: "全 variant を 1 snapshot で検出する小型コンポーネント。",
      },
    },
  },
  tags: ["autodocs"],
  title: "Components/<name>",
} satisfies Meta<typeof Component>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  parameters: {
    docs: {
      description: {
        story: "全 variant を横並びで確認する代表 showcase。regression はこの 1 snapshot で検出する。",
      },
    },
  },
  render: (args) => (
    <StoryShowcase>
      <StoryItem title="Primary"><Component {...args} variant="primary" /></StoryItem>
      <StoryItem title="Secondary"><Component {...args} variant="secondary" /></StoryItem>
      <StoryItem title="Disabled"><Component {...args} disabled /></StoryItem>
    </StoryShowcase>
  ),
}
```

### Template 2: 大型（Dialog / Page）— Default + disableSnapshot variants

Dialog / モーダル / ページ級の大型コンポーネント向け。代表 1 snapshot + 他 variant は無効化。

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { fn } from "storybook/test"

import { Component } from "./index"

const meta = {
  args: {
    open: true,
    onClose: fn(),
    /* 必須 props のデフォルト */
  },
  argTypes: { /* ... */ },
  component: Component,
  parameters: {
    backgrounds: { default: "light" },
    docs: {
      description: {
        component: "大型レイアウト。variant 別 story + `disableSnapshot` で snapshot 最小化する。",
      },
    },
  },
  tags: ["autodocs"],
  title: "Features/<path>",
} satisfies Meta<typeof Component>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  parameters: {
    docs: { description: { story: "代表ケース。regression はこの 1 snapshot で検出する。" } },
  },
}

export const Loading: Story = {
  args: { loading: true },
  parameters: {
    chromatic: { disableSnapshot: true },
    docs: { description: { story: "読込中状態の docs variant。" } },
  },
}
```

### Template 3: Form 系（useForm + Wrapper）

Presentation が `UseFormReturn` を prop で要求する場合、story 内で `useForm` を呼ぶ Wrapper を挟む。

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { useForm } from "react-hook-form"
import { fn } from "storybook/test"

import { XxxPresentation } from "./index"
import { Schema } from "./validation"

const Wrapper = (props: { isLoading: boolean; initial: boolean }) => {
  const form = useForm<Schema>({ values: { someField: props.initial } })
  return (
    <XxxPresentation
      form={form}
      isLoading={props.isLoading}
      onOpenChange={fn()}
      onSubmit={async () => undefined}
      open
    />
  )
}

const meta = {
  args: { isLoading: false, initial: false },
  component: Wrapper,
  // ...
} satisfies Meta<typeof Wrapper>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = { /* ... */ }
export const Loading: Story = {
  args: { isLoading: true },
  parameters: { chromatic: { disableSnapshot: true } },
}
```

### Template 3.5: Context Wrapper（親 context 必須な Presentation）

`Tabs` 内の `TabsContent`、`Form` 内の `FormField`、Radix UI の `Accordion` 等は親 context が必須。これらを story 化するとき、story 内で context provider を wrap する。

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { useRef } from "react"
import { fn } from "storybook/test"

import { Tabs } from "@/components/ui/tabs"

import { XxxTabPresentation } from "./index"

const Wrapper = (props: { /* 外側から変えたい props */ }) => {
  return (
    <Tabs defaultValue="target-tab">
      <XxxTabPresentation
        /* ... props ... */
      />
    </Tabs>
  )
}

const meta = {
  args: { /* Wrapper の props */ },
  component: Wrapper,
  // ...
} satisfies Meta<typeof Wrapper>
```

meta.args は Wrapper の props にしておく（Presentation の内部 props ではなく）。

### Template 4: 超複雑 orchestrator（全 disableSnapshot、skill 例外）

`channel-room` / `calendar-event-detail-dialog` のように Apollo / Quill / 多段依存で minimal mock の render が不完全になる場合、全 story を snapshot 無効にする。

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { useRef } from "react"
import { fn } from "storybook/test"

import { ComponentPresentation } from "./index"

const Wrapper = () => {
  const someRef = useRef(null)
  return (
    <ComponentPresentation
      /* 必須 props 全て — 型コンパイル検証のみが目的 */
      someRef={someRef}
      /* ... */
    />
  )
}

const meta = {
  component: Wrapper,
  parameters: {
    backgrounds: { default: "light" },
    chromatic: { disableSnapshot: true },  // meta で宣言すれば全 story に伝搬
    docs: {
      description: {
        component:
          "<Component> は Apollo / Quill / 仮想スクロール依存の orchestrator。" +
          "minimal mock の render は signal 比が低いため、全 story を disableSnapshot にし " +
          "Chromatic 対象外とする（e2e テストに regression 検出を委ねる、skill 例外扱い）。",
      },
    },
    layout: "fullscreen",
  },
  tags: ["autodocs"],
  title: "Features/<path>",
} satisfies Meta<typeof Wrapper>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  parameters: {
    // meta で chromatic.disableSnapshot を宣言済なので story 側は記述不要
    docs: { description: { story: "最小 Loading 状態の型検証用描画。snapshot 対象外。" } },
  },
}
```

**注意**：`parameters` は meta と story で deep merge される。meta で `chromatic: { disableSnapshot: true }` を宣言すれば全 story に継承されるので、個別 story で重複宣言しない（DRY 違反）。

skill 例外を選ぶ判定基準（両方が当てはまる場合）:

- 実装が 500 行超 or 10 以上の子コンポーネント／hook に依存
- Presentation 層でも Apollo / Quill / 仮想スクロール等の外部依存が残る

## 共通 Snippets

GraphQL fragment 依存の mock で頻出するパターン：

### Workspace / WorkspaceUser の最小 mock

```ts
const workspace = { __typename: "Workspace" as const, id: "workspace-1" }

const workspaceUser = {
  __typename: "WorkspaceUser" as const,
  displayName: "田中太郎",
  groupName: "医師",
  id: "u1",
  profileImage: null,  // or { __typename: "Blob" as const, id: "img1", url: "..." }
  username: "tanaka",
  workspace,
}
```

### Async function prop の mock

```ts
import { fn } from "storybook/test"

// 成功する async 関数 mock
const resolveFn = fn().mockResolvedValue(undefined)

// 同期ハンドラ
const syncFn = fn()

// async を手書きする場合
const customAsync = async () => undefined
```

### 共通 import 先

| 用途 | import 先 |
|---|---|
| Meta / StoryObj | `@storybook/nextjs` |
| fn（mock helper） | `storybook/test` |
| StoryShowcase / StoryItem | `@/components/storybook`（`/index` は不要、付けても動く） |

## Showcase の書き方（補足）

既存コードで variant 別 story が複数ある場合、retrofit で showcase 集約するときは：

1. 各 variant の args の差分を抽出
2. `Default` story にまとめて `render` に展開
3. 元の個別 story は削除（snapshot 削減になる）
4. commit message に「N 件の variant story を showcase に集約（X → 1 snapshot）」と明記

## 落とし穴

### 1. `perfectionist/sort-intersection-types` は JSDoc を追加すると発火する

`type Foo = Ref & { ...JSDoc付きフィールド... }` のように intersection に type literal を後ろに置くと lint エラーになる。JSDoc 追加後は **type literal を先頭に並べる**：

```ts
// NG
export type Props = ComponentProps<typeof Base> & {
  /** ... */
  foo: string
}

// OK
export type Props = {
  /** ... */
  foo: string
} & ComponentProps<typeof Base>
```

### 2. Linter が meta のキー順を変更する

`perfectionist/sort-objects` が `args` → `argTypes` などキー順を自動調整する。編集時に特定の順序で書いても問題ない。

### 3. `satisfies Meta<typeof Component>` + `render` ありの Story は meta.args に必須プロパティを provide

`render: (args) => ...` を含む Story は、TypeScript が meta.args を自動継承しない。コンポーネントの必須プロパティ（required props）を **すべて meta.args に書く**こと。足りないと `Property 'args' is missing in type '...'` の型エラーが `pnpm test`（tsc）で出る。

### 4. 既存 showcase story は既に `kept=1` の場合が多い

`src/components/` 配下の慣習として、1 つの `Default` story 内で `StoryShowcase` / `StoryItem` を使って複数 variant を並べる形式が定着している。この場合 N=1 で snapshot 削減の余地はない。新たに variant story を追加して `disableSnapshot` で無効化する拡張は **やらない**（snapshot 総数を増やさないため）。代わりに既存 showcase 内の記述を整理し、docs 強化に集中する。

## admin/ 固有メモ

- **`@/components/storybook` が StoryShowcase / StoryItem を提供**（Template 1 で使う）。admin/ で過去に存在しなかった場合は `src/components/storybook/index.tsx` に薄い実装を置けば良い（118 件 retrofit プロジェクトで実装済み）。
- **MSW は使えない**。`parameters.msw.handlers` を書いても無視される。Apollo mock は `MockedProvider` を story の `decorators` に書く。詳細は `storybook-feature-mocking` §1。
- title 規約は `docs/storybook-playbook.md` §1（`Components/` `Features/` `Pages/` PascalCase 先頭、サブセグメント kebab-case、中間 `components/` `features/` 削除）。

## 関連 Skill

- `storybook-retrofit`：retrofit の全体ワークフロー
- `storybook-snapshot-policy`：snapshot 対象判定・命名規約
- `storybook-feature-mocking`：admin/ MockedProvider または web/ MSW mock レシピ
