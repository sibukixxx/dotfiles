---
name: storybook-feature-mocking
description: Apollo の useQuery / useSubscription / useMutation に依存する feature コンポーネントを Storybook で実データレンダリングするための mock 設計ガイド。admin/ は MockedProvider、web/ は MSW handler を使う（プロジェクトで設定が異なる）。storybook-retrofit の Pre-flight #2 で「非 lazy useQuery」に当たったときに併用する。snapshot 対象の story を増やし、skill 例外率を下げるのが目的。
---

# Storybook Feature Mocking Skill

## このスキルはいつ使うか

- 対象コンポーネントが **非 lazy な `useQuery` / `useSubscription`** を内部で発火していて、Storybook で描画すると Apollo リクエストがエラーになる
- `storybook-retrofit` skill の Pre-flight #2 で「Apollo 依存あり」と判定された
- skill 例外（Template 4）に逃げる前に、mock で実データ描画を成立させたい

`useLazyQuery` / `useMutation` は自動発火しないため本 skill は不要。通常 template で story 化可。

## ⚠️ プロジェクトごとの設定差分（最重要）

**admin/ と web/ で Apollo mock の方式が完全に異なる**。間違えるとどんなに mock を書いても render できない。先に `.storybook/preview.ts(.tsx)` を `cat` して確認すること。

| プロジェクト | mock 方式 | preview の中身 |
|---|---|---|
| **admin/** | **`MockedProvider` from `@apollo/client/testing`** | `apolloDecorator` + `jotaiDecorator`（空 ApolloClient + 空 store のみ） |
| **web/** | **MSW (`msw-storybook-addon`)** | `mswLoader` + `ApolloProvider` + `parameters.msw.handlers` |

判定:
```bash
grep -E "msw|MockedProvider|apolloDecorator" .storybook/preview.ts*
# msw-storybook-addon が出る → web/ パターン → §MSW handler 設計 セクション
# apolloDecorator のみ → admin/ パターン → §MockedProvider セクション
```

## §1 admin/ パターン: MockedProvider

admin/ プロジェクトでは `.storybook/preview.ts` が以下:

```tsx
import { apolloDecorator } from "@/lib/storybook/apollo-decorator"  // 空 ApolloClient 提供のみ
import { jotaiDecorator } from "@/lib/storybook/jotai-decorator"    // 空 jotai store 提供のみ

const preview: Preview = {
  decorators: [jotaiDecorator, apolloDecorator],
  // msw 設定なし
}
```

つまり既定の ApolloClient は空。`useQuery` を持つ component は story の decorators で `MockedProvider` を上書きする必要がある。

### 基本パターン（admin/）

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { MockedProvider } from "@apollo/client/testing"

import { GET_XXX } from "./schema"           // or 近傍の query 定義
import { DATA } from "./mocks"               // or 近傍の mock データ
import { MyFeature } from "./index"

const meta: Meta<typeof MyFeature> = {
  component: MyFeature,
  decorators: [
    (Story, context) => {
      const id = context.args.id as string
      const item = DATA.find((d) => d.id === id)
      const mocks = item
        ? [{
            request: { query: GET_XXX, variables: { id } },
            result: { data: { node: item } },
          }]
        : []
      return (
        <MockedProvider addTypename={false} mocks={mocks}>
          <Story />
        </MockedProvider>
      )
    },
  ],
  tags: ["autodocs"],
  title: "Pages/<path>",
}
```

### 空 mocks で wrap だけする最小パターン（admin/）

useQuery が発火するが mock データが不要な場合（empty state を表示したい、またはコンポーネントが loading state でも snapshot 価値がある場合）:

```tsx
decorators: [
  (Story) => (
    <MockedProvider addTypename={false} mocks={[]}>
      <Story />
    </MockedProvider>
  ),
],
```

empty mocks でも MockedProvider が存在することで `useQuery` が「unhandled query」エラーを出さず loading で止まるだけ。これだけで render が成立するケースが多い。

### admin/ 既存参考

- 詳細 mock: `src/features/pages/jobs/components/job-detail-dialog/index.stories.tsx`
- 空 mocks: `src/features/calendar/components/shift-calendar-monthly/index.stories.tsx`

### 注意（admin/ MockedProvider）

- **`addTypename={false}` を必ず付ける**。付けないと mock 側でも `__typename` を埋めないとマッチしない
- query の variables まで一致しないと mock がヒットしない。対象 component が呼ぶ query を grep して variables を確認する
- `mutations` も同じ shape で `mocks` 配列に並べる
- complex な fragment shape は `src/generated/graphql.ts` で型確認
- subscription mock は `MockedProvider` でも難しい。skip して loading 状態で snapshot するのが現実的

### admin/ で MSW は使えない

`parameters.msw.handlers` を書いても admin/ では `msw-storybook-addon` が未設定のため無視される。silent に動かないので注意。

---

## §2 web/ パターン: MSW handler

web/ プロジェクトでは `.storybook/preview.tsx` に以下が揃っている：

- `msw-storybook-addon` の `initialize()` + `mswLoader`
- `ApolloProvider` が全 story を wrap
- `parameters.msw.handlers` に `baselayout` / `editor` のグループが登録済み
- `graphql.query<QueryName>(...)` / `HttpResponse.json(...)` の pattern で handler を書く

**新規 story で Apollo mock するときは `parameters.msw.handlers` を story 側で追加・上書きする**。preview の既存 handler はそのまま継承されるので `BaseLayout` / `Editor` 関連は再定義不要。

### web/ 続き：MSW 詳細パターン

以下は web/ プロジェクトでの MSW handler 設計詳細。admin/ では適用不可（§1 を参照）。

## 基本パターン：query mock

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { graphql, HttpResponse } from "msw"

import type { MyFeatureQuery } from "@/generated/graphql"

import { MyFeature } from "./index"

const meta = {
  args: { /* ... */ },
  component: MyFeature,
  parameters: {
    msw: {
      handlers: [
        graphql.query<MyFeatureQuery>("MyFeature", () =>
          HttpResponse.json({
            data: {
              __typename: "Query",
              node: {
                __typename: "WorkspaceAddressBook",
                id: "ab-1",
                // ...
              },
            },
          }),
        ),
      ],
    },
  },
  tags: ["autodocs"],
  title: "Features/my-feature",
} satisfies Meta<typeof MyFeature>
```

**ポイント**：

- `graphql.query<QueryName>` の第 1 引数は **operation name**（query 定義の `query MyFeature(...)` の `MyFeature`）
- ジェネリクスは生成型（`MyFeatureQuery`）を指定すると response shape が補完される
- `data` トップの `__typename: "Query"`、その下の node にも `__typename` 必須
- nullable フィールドは `null`、optional は省略可

## 必須：使っている query の operation name と型を特定する

1. 対象コンポーネントが使う hook を grep
   ```bash
   rg -n "useQuery|useSubscription" <target-dir> --type ts --type tsx
   ```
2. hook 内の `GET_XXX = graphql(\`query XxxName(...) { ... }\`)` 定義を辿る
3. operation name を `QueryName` として `graphql.query<QueryName>` に渡す
4. 型は `src/generated/graphql.ts` に `export type XxxNameQuery = { ... }` として生成されている

## Connection ページングのモック

Relay-style Connection（`edges`/`pageInfo`）を持つ query は以下の shape で：

```tsx
graphql.query<WorkspaceUsersQuery>("WorkspaceUsers", () =>
  HttpResponse.json({
    data: {
      __typename: "Query",
      me: {
        __typename: "WorkspaceUser",
        id: "user-1",
        workspace: {
          __typename: "Workspace",
          id: "workspace-1",
          workspaceUsers: {
            __typename: "WorkspaceUserConnection",
            edges: [
              {
                __typename: "WorkspaceUserEdge",
                cursor: "user-1",
                node: { __typename: "WorkspaceUser", id: "user-1", displayName: "山田" },
              },
            ],
            pageInfo: {
              __typename: "PageInfo",
              endCursor: null,
              hasNextPage: false,
            },
          },
        },
      },
    },
  }),
)
```

**`fetchMore` が発火するパターン**（scroll sentinel 経由等）を避けたいときは `hasNextPage: false` にしておくと追加リクエストが来ない。

## Mutation のモック

```tsx
graphql.mutation<UpdateXxxMutation>("UpdateXxx", () =>
  HttpResponse.json({
    data: {
      __typename: "Mutation",
      updateXxx: {
        __typename: "UpdateXxxPayload",
        xxx: { __typename: "Xxx", id: "xxx-1" /* ... */ },
      },
    },
  }),
)
```

onSubmit 系の mutation は story 側で触らなければ発火しないが、UI テストで触る場合は最低限のレスポンスを返しておく。

## Subscription のモック

WebSocket subscription は Storybook ではほぼ無視してよい（非同期イベントなので snapshot には影響しない）。ただし mount 時にエラーが出るなら空データで返す：

```tsx
graphql.operation(() =>
  HttpResponse.json({
    data: {
      /* 空 payload */
    },
  }),
)
```

## Loading / Error 状態の別 story

同じコンポーネントを **Default（データあり）・Loading・Error** の 3 state で並べたい場合、story ごとに handler を差し替える：

```tsx
export const Default: Story = {
  parameters: {
    msw: { handlers: [/* データあり */] },
  },
}

export const Loading: Story = {
  parameters: {
    chromatic: { disableSnapshot: true },
    msw: {
      handlers: [
        graphql.query<MyQuery>("MyQuery", async () => {
          await new Promise((r) => setTimeout(r, 1000000))  // 永久 pending
          return HttpResponse.json({ data: {} })
        }),
      ],
    },
  },
}

export const Error: Story = {
  parameters: {
    chromatic: { disableSnapshot: true },
    msw: {
      handlers: [
        graphql.query<MyQuery>("MyQuery", () =>
          HttpResponse.json({ errors: [{ message: "Something went wrong" }] }),
        ),
      ],
    },
  },
}
```

storybook-retrofit の決定木に従って `Default` のみ snapshot 対象、`Loading` / `Error` は `disableSnapshot: true`。

## 共通 handler snippets

よく使う形を最初から block 化しておく：

```ts
// 空 me（ログインしていないユーザー相当）
const meEmpty = graphql.query("Me", () =>
  HttpResponse.json({
    data: {
      __typename: "Query",
      me: null,
    },
  }),
)

// 固定 workspace
const workspaceStub = {
  __typename: "Workspace" as const,
  id: "workspace-1",
  logo: null,
}
```

## Story Template: Feature with Apollo

`storybook-retrofit` の Template 2 をベースに、`parameters.msw.handlers` を追加したもの。

```tsx
import type { Meta, StoryObj } from "@storybook/nextjs"
import { graphql, HttpResponse } from "msw"
import { fn } from "storybook/test"

import type { MyFeatureQuery } from "@/generated/graphql"

import { MyFeature } from "./index"

const myFeatureHandler = graphql.query<MyFeatureQuery>("MyFeature", () =>
  HttpResponse.json({
    data: {
      __typename: "Query",
      /* ... */
    },
  }),
)

const meta = {
  args: {
    onClose: fn(),
    /* ... */
  },
  component: MyFeature,
  parameters: {
    backgrounds: { default: "light" },
    docs: {
      description: {
        component:
          "<Feature> の説明。MSW で GraphQL query をモックして実データ描画する。",
      },
    },
    msw: { handlers: [myFeatureHandler] },
  },
  tags: ["autodocs"],
  title: "Features/<path>",
} satisfies Meta<typeof MyFeature>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  parameters: {
    docs: { description: { story: "mock データあり、代表表示。" } },
  },
}

export const Empty: Story = {
  parameters: {
    chromatic: { disableSnapshot: true },
    msw: {
      handlers: [
        graphql.query<MyFeatureQuery>("MyFeature", () =>
          HttpResponse.json({
            data: { __typename: "Query" /* 空 */ },
          }),
        ),
      ],
    },
    docs: { description: { story: "空データ時の表示 docs variant。" } },
  },
}
```

## 落とし穴

### 1. operation name の typo

handler の operation name は定義側の `query XxxName(...)` と完全一致しないと発火しない。型エラーにはならず、単に silent に preview の default handler か network fallback に流れる。**生成型名（`XxxNameQuery`）ではなく operation name（`XxxName`）を渡す**ことに注意。

### 2. `__typename` の階層漏れ

Apollo cache は全 object に `__typename` を要求する。nested object / edge / connection の全階層に付与する。preview.tsx の既存 handler が参考例。

### 3. 複数 query を使う feature

コンポーネントが 2 つ以上の query を発火する場合、handlers 配列に全部並べる。1 つでも欠けるとエラーで画面が崩れる。grep 時に発火数を数える習慣を。

### 4. preview の既存 handler 上書き

story で `parameters.msw.handlers` を宣言すると **preview の同名 operation は上書きされる**（注意：preview は named group、story は array なので groupbase のリセット挙動は addon のバージョン依存）。問題が出たら preview 側の handler を story 側でも明示的に repeat するのが安全。

### 5. `useSubscription` は mock しなくても落ちないケース

subscription は mount 時に確立される。Storybook で WebSocket が貼れなくても多くの場合 `onError` で無視されるので render は進む。ただし subscription 結果に依存した state がある場合は `loading` や `null` 時の分岐を確認する。

## Fallback：storybook-retrofit Template 4（skill 例外）に戻す条件

以下のいずれかに当たったら MSW mock は諦めて skill 例外に戻す：

- `useQuery` が 5 個以上あり handler を書き切るコストが高すぎる
- `fetchMore` / cursor 更新を含む pagination ロジックを stub しきれず崩れる
- Quill / Google Maps API / その他 non-GraphQL 外部サービスに依存する
- 1 story に 10 個以上の handler を積まないと動かない

無理に mock を書き続けるより、`storybook-retrofit` の Template 4 で docs 目的の snapshot 無効 story にする方が保守コストが低い。

## 関連 Skill

- **`storybook-retrofit`**：retrofit 本体の手順書。本 skill はその Pre-flight #2 で Apollo 依存と判定された時の補助。

## 参照

- `.storybook/preview.tsx`：既存の MSW + ApolloProvider 設定
- `msw-storybook-addon`: https://github.com/mswjs/msw-storybook-addon
