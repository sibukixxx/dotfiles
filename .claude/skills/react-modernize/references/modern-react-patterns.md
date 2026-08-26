# 最新 React パターン（React 18 / 19 / Compiler 時代）

クラス → 関数への移行は「機械変換ではなく設計の見直し」だが、その設計の基準は **2020 年の関数コンポーネント** ではなく **現在の React (19 + Compiler)** に置く。

このドキュメントは「移行後のコードを今の React の流儀に合わせる」ためのリファレンス。

## 基本姿勢

| 旧来の関数コンポーネント | 現在の関数コンポーネント |
|---------------------|---------------------|
| `forwardRef` でラップ | `ref` を普通の prop として受ける（React 19+） |
| `<Context.Provider>` | `<Context>` 自体を Provider として使う（React 19+） |
| `defaultProps` | デフォルト引数（`function Foo({ x = 0 })`） |
| `useEffect` で fetch | `use(promise)` + Suspense / TanStack Query / Server Components |
| `useState` で送信中フラグ | `useActionState` / `useFormStatus` |
| `useState` で楽観 UI | `useOptimistic` |
| 手動 `useMemo` / `useCallback` | React Compiler に任せる（適用済み環境） |
| `useRef` で外部ストア購読 | `useSyncExternalStore` |
| 自前 ID 生成 | `useId` |
| Effect で重い更新 | `useTransition` / `useDeferredValue` |

「移行が終わった後 = 関数コンポーネント完成」ではない。**そこから現在の React の流儀に乗せて初めて完成**。

---

## React 19 の必修 API

### `use()` — promise / context を読む

`useEffect` + `useState` で書いていた fetch を Suspense 境界に寄せられる。

```tsx
import { use, Suspense } from 'react';

function Profile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise); // Suspense でハングする
  return <p>{user.name}</p>;
}

function App({ id }: { id: string }) {
  const userPromise = useMemo(() => fetchUser(id), [id]);
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <Profile userPromise={userPromise} />
    </Suspense>
  );
}
```

- **条件分岐の中で呼べる**（`useState` などとは違う）
- promise は **キャッシュされる前提**。毎レンダー新しい promise を渡すと無限ループ
- 実プロジェクトでは Server Components / TanStack Query と組み合わせるのが現実的
- `use(MyContext)` で `useContext` の代わりにも使える（条件付きで読める）

### Actions と `<form action>`

`onSubmit` でフラグ管理する代わりに、**async 関数を `action` に渡す**。

```tsx
function CommentForm({ postId }: { postId: string }) {
  async function submit(formData: FormData) {
    await postComment(postId, formData.get('text') as string);
  }
  return (
    <form action={submit}>
      <textarea name="text" />
      <SubmitButton />
    </form>
  );
}
```

React が pending / error / success を自動管理する。送信中の UI は子コンポーネントで `useFormStatus` を読む。

### `useActionState` — フォーム結果を state に

旧 `useFormState`。送信結果と pending を一括管理。

```tsx
import { useActionState } from 'react';

function LoginForm() {
  const [state, action, isPending] = useActionState(
    async (_prev: State, formData: FormData) => {
      const res = await login(formData.get('email') as string);
      return res.ok ? { ok: true } : { ok: false, error: res.error };
    },
    { ok: false } as State,
  );

  return (
    <form action={action}>
      <input name="email" />
      <button disabled={isPending}>Login</button>
      {!state.ok && state.error && <p>{state.error}</p>}
    </form>
  );
}
```

`useState` で「送信中フラグ + エラーメッセージ + 結果」を別々に管理していたコードはここに集約できる。

### `useFormStatus` — 親 form の状態を子から読む

```tsx
import { useFormStatus } from 'react-dom';

function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>{pending ? 'Sending...' : 'Send'}</button>;
}
```

「送信中だけボタンを disable したい」を、props バケツリレーなしで実現。

### `useOptimistic` — 楽観 UI

```tsx
function Thread({ messages, sendMessage }: Props) {
  const [optimisticMessages, addOptimistic] = useOptimistic(
    messages,
    (state, newMsg: Message) => [...state, { ...newMsg, sending: true }],
  );

  async function handleSubmit(formData: FormData) {
    const text = formData.get('text') as string;
    addOptimistic({ id: 'temp', text });
    await sendMessage(text);
  }

  return (
    <>
      {optimisticMessages.map(m => <p key={m.id}>{m.text}{m.sending && ' …'}</p>)}
      <form action={handleSubmit}><input name="text" /></form>
    </>
  );
}
```

「送信前に表示 → 失敗したら自動で巻き戻し」が React の責務になる。

### `ref` を普通の prop として受ける

React 19+ では関数コンポーネントが `ref` を直接受け取れる。`forwardRef` は不要。

```tsx
type Props = { label: string; ref?: React.Ref<HTMLInputElement> };

function Input({ label, ref }: Props) {
  return <input aria-label={label} ref={ref} />;
}

// 使用側
<Input label="Email" ref={inputRef} />
```

**新規コードでは `forwardRef` を書かない**。既存の `forwardRef` も漸次外していく。

### `<Context>` を Provider として使う

```tsx
const ThemeContext = createContext<Theme>('light');

// 旧
<ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>

// 新（React 19+）
<ThemeContext value={theme}>{children}</ThemeContext>
```

`.Provider` は引き続き動くが、新規は短い形を使う。

### ref callback の cleanup

ref callback が **クリーンアップ関数を返せる**ようになった。

```tsx
<div
  ref={(node) => {
    if (!node) return;
    const observer = new IntersectionObserver(...);
    observer.observe(node);
    return () => observer.disconnect(); // ← クリーンアップ
  }}
/>
```

旧来は ref callback で `null` チェックして `useEffect` に逃がしていたものが、ref 一箇所で完結する。

### document metadata

`<title>`, `<meta>`, `<link>` をコンポーネント内に書くと自動で `<head>` に hoist される。`react-helmet` の役割の多くを置き換える。

```tsx
function ArticlePage({ article }: Props) {
  return (
    <>
      <title>{article.title}</title>
      <meta name="description" content={article.summary} />
      <link rel="canonical" href={article.url} />
      <article>{article.body}</article>
    </>
  );
}
```

### asset preloading

```tsx
import { preload, preinit } from 'react-dom';

preload('/fonts/inter.woff2', { as: 'font', type: 'font/woff2', crossOrigin: 'anonymous' });
preinit('/styles/critical.css', { as: 'style' });
```

クラス時代に `componentDidMount` で `<link>` を append していた処理は不要。

### スタイルシートの `precedence`

```tsx
<link rel="stylesheet" href="/foo.css" precedence="default" />
```

複数コンポーネントが同じスタイルを参照しても重複ロードされない。

### エラーハンドリング改善

`createRoot` / `hydrateRoot` のオプションで error 報告を統一できる。

```tsx
createRoot(container, {
  onCaughtError: (error, info) => log(error, info),
  onUncaughtError: (error, info) => log(error, info),
  onRecoverableError: (error, info) => log(error, info),
});
```

**ErrorBoundary は依然として class でしか書けない**。class が生き残る数少ない正当な理由。

---

## React 18 で入った（が見落とされがちな）API

### `useId` — 安定 ID

label/aria 用の ID は手書き or `Math.random` ではなく `useId`。

```tsx
function Field({ label }: { label: string }) {
  const id = useId();
  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input id={id} />
    </>
  );
}
```

SSR でハイドレーション不一致を起こさない。a11y 対応の必修。

### `useSyncExternalStore` — 外部ストア購読

`window` / Redux / Zustand / Observable などに購読する場合、`useEffect` + `useState` の自前実装ではなく `useSyncExternalStore`。tearing（concurrent rendering 中に値が割れる）を防ぐ。

```tsx
function useOnline() {
  return useSyncExternalStore(
    (cb) => {
      window.addEventListener('online', cb);
      window.addEventListener('offline', cb);
      return () => {
        window.removeEventListener('online', cb);
        window.removeEventListener('offline', cb);
      };
    },
    () => navigator.onLine, // client snapshot
    () => true, // server snapshot (SSR)
  );
}
```

`useEffect` で `window.addEventListener` していたコードはこれに置き換える。

### `useTransition` — 重い更新を非同期化

タブ切り替え・検索フィルタなど、即座でなくてよい更新を「ノンブロッキング」にする。

```tsx
function SearchUI() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Item[]>([]);
  const [isPending, startTransition] = useTransition();

  function onChange(e: React.ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value); // 入力反映は urgent
    startTransition(() => {
      setResults(search(e.target.value)); // 重い計算は transition
    });
  }
  return <>{isPending && <Spinner />}<List items={results} /></>;
}
```

### `useDeferredValue` — props を遅延

親から来る値を「直近の最新値ではなく、少し前の値」として使う。

```tsx
function Search({ query }: { query: string }) {
  const deferred = useDeferredValue(query);
  const isStale = deferred !== query;
  return <List query={deferred} className={isStale ? 'opacity-50' : ''} />;
}
```

React 19 では `useDeferredValue(value, initialValue)` で初期値も指定可能。

### Suspense for data

データ読み込み中の UI は `useState` の loading フラグではなく Suspense 境界。

```tsx
<Suspense fallback={<Skeleton />}>
  <Profile id={id} />
</Suspense>
```

中の `Profile` が `use(promise)` / TanStack Query 等で「読み込み中」を投げると自動でフォールバック。loading 状態が UI ツリーから消せる。

---

## React Compiler

`babel-plugin-react-compiler` 適用環境では、**手動の `useMemo` / `useCallback` / `React.memo` は基本不要**。

- 適用済みなら新規で `useMemo` / `useCallback` を書く前に「Compiler が拾えるはず」と疑う
- ただし React の Rules（[Rules of React](https://react.dev/reference/rules)）違反コードは Compiler が無視する。Pure な関数 / イミュータブルな更新を徹底
- まだ未導入の既存プロジェクトでは、移行ついでに Compiler 適用検討する価値あり

### 適用可否の確認

```bash
pnpm dlx eslint-plugin-react-compiler --check
```

`'use no memo'` ディレクティブで一時的に除外可能だが、原因（Rules 違反）を直すのが本筋。

---

## モダンなデータ取得

`useEffect` + `fetch` を新規で書かない。

| 環境 | 推奨 |
|-----|-----|
| Server Components が使える（Next.js App Router 等） | サーバ側で `await fetch()`、クライアントには結果だけ渡す |
| 純クライアント SPA | TanStack Query / SWR / Relay |
| Suspense と組み合わせたい | `use(promise)` + 上位の Suspense / TanStack Query の `useSuspenseQuery` |
| GraphQL | Apollo Client / Relay / urql |

**自前 hook で `useState` + `useEffect` + `AbortController` を書くのは最後の手段**。race / cleanup / cache / dedup / refetch / retry を自前で正しく実装するのは難しい。

---

## モダナイゼーションのチェック項目

クラス → 関数の移行が終わった後に、以下を点検する：

- [ ] `forwardRef` が新規で書かれていないか（ref-as-prop に置き換え可能か）
- [ ] `<Context.Provider>` が新規で書かれていないか（`<Context>` でよいか）
- [ ] フォーム送信フラグを自前 `useState` で管理していないか（`useActionState` / `useFormStatus`）
- [ ] 楽観 UI を自前 state で組んでいないか（`useOptimistic`）
- [ ] `useState` の `id` / `aria-id` が `useId` になっているか
- [ ] 外部ストア購読が `useEffect` ではなく `useSyncExternalStore` か
- [ ] 重い更新が `useTransition` / `useDeferredValue` で非ブロッキング化されているか
- [ ] Loading / Error が UI ツリーに散らばっていないか（Suspense + ErrorBoundary に集約）
- [ ] `react-helmet` / 自前 `<head>` 操作 → document metadata API
- [ ] `<link rel="preload">` 手動挿入 → `preload` / `preinit`
- [ ] `useEffect` + `fetch` が残っていないか（TanStack Query / Server Component / `use()`）
- [ ] React Compiler 適用環境で手動 `useMemo` / `useCallback` が惰性で残っていないか
- [ ] `defaultProps` がコードベースに残っていないか（React 19 で削除）
- [ ] 旧 JSX transform（`import React from 'react'` だけのため）が残っていないか
- [ ] ErrorBoundary 以外で class component が残っていないか

---

## 各機能の最小マイグレーションパス

| 旧パターン | 新パターン | 移行の重さ |
|---------|---------|---------|
| `forwardRef(({...}, ref) => ...)` | `function X({ ref })` | 軽（型修正のみ） |
| `<Context.Provider value>` | `<Context value>` | 軽（テキスト置換） |
| `defaultProps = {...}` | `function X({ y = ... })` | 軽 |
| `componentDidMount` で `addEventListener` | `useSyncExternalStore` | 中（hook化） |
| `componentDidMount` で fetch | `use()` + Suspense / TanStack Query | 中〜重（境界設計） |
| 自前 form pending state | `useFormStatus` / `useActionState` | 中 |
| 自前 optimistic update | `useOptimistic` | 中 |
| `react-helmet` | document metadata as JSX | 軽 |
| 手動 `useMemo` / `useCallback` | Compiler 適用 | 重（環境整備） |

「軽」のものは移行 PR と同時にやるのが効率的。「中〜重」は別 PR で。

---

## 参考リンク

- [React 19 release notes](https://react.dev/blog/2024/12/05/react-19)
- [Rules of React](https://react.dev/reference/rules)
- [React Compiler](https://react.dev/learn/react-compiler)
- [`use`](https://react.dev/reference/react/use)
- [`useActionState`](https://react.dev/reference/react/useActionState)
- [`useFormStatus`](https://react.dev/reference/react-dom/hooks/useFormStatus)
- [`useOptimistic`](https://react.dev/reference/react/useOptimistic)
- [`useSyncExternalStore`](https://react.dev/reference/react/useSyncExternalStore)
- [`useId`](https://react.dev/reference/react/useId)
