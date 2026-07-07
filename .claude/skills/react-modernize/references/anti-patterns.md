# 移行時のアンチパターン集

**機械変換の誘惑に負けない**。以下のパターンを見つけたら「なぜ Effect が必要か」を自問する。

## 1. props → state のコピー

**悪い**:
```jsx
function UserCard({ user }) {
  const [name, setName] = useState(user.name);

  useEffect(() => {
    setName(user.name); // props が変わったら同期
  }, [user.name]);

  return <div>{name}</div>;
}
```

**良い**:
```jsx
function UserCard({ user }) {
  return <div>{user.name}</div>; // そのまま使う
}
```

### props を編集可能にしたい場合

編集用 draft なら key で明示的にリセット：

```jsx
<EditForm key={user.id} user={user} />

function EditForm({ user }) {
  const [draft, setDraft] = useState(user); // 初期値にだけ使う
  // user.id が変わると component が作り直される
}
```

## 2. 導出値を state に持つ

**悪い**:
```jsx
function TodoList({ todos }) {
  const [activeCount, setActiveCount] = useState(0);

  useEffect(() => {
    setActiveCount(todos.filter(t => !t.done).length);
  }, [todos]);

  return <p>{activeCount}</p>;
}
```

**良い**:
```jsx
function TodoList({ todos }) {
  const activeCount = todos.filter(t => !t.done).length;
  return <p>{activeCount}</p>;
}
```

計算コストが高ければ `useMemo`。先に `useMemo` を入れない。

## 3. イベント処理を useEffect に書く

**悪い**:
```jsx
function BuyButton({ product }) {
  const [clicked, setClicked] = useState(false);

  useEffect(() => {
    if (clicked) {
      sendPurchase(product); // ← クリックの結果を Effect で
      setClicked(false);
    }
  }, [clicked, product]);

  return <button onClick={() => setClicked(true)}>Buy</button>;
}
```

**良い**:
```jsx
function BuyButton({ product }) {
  return <button onClick={() => sendPurchase(product)}>Buy</button>;
}
```

イベント処理は **ハンドラに直接書く**。state を挟まない。

## 4. 親への通知を useEffect で行う

**悪い**:
```jsx
function Counter({ onChange }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    onChange(count); // マウント時にも呼ばれてしまう
  }, [count, onChange]);

  return <button onClick={() => setCount(count + 1)}>+</button>;
}
```

**良い**:
```jsx
function Counter({ onChange }) {
  const [count, setCount] = useState(0);

  const handleClick = () => {
    const next = count + 1;
    setCount(next);
    onChange(next); // イベントハンドラで通知
  };

  return <button onClick={handleClick}>+</button>;
}
```

## 5. 1つの巨大 useEffect

**悪い**:
```jsx
useEffect(() => {
  if (userId) fetchUser(userId);
  if (filter) recomputeList();
  document.title = `${userName} - ${count}`;
}, [userId, filter, userName, count]);
```

**良い**:
```jsx
useEffect(() => { fetchUser(userId); }, [userId]);
useEffect(() => { /* recomputeList は導出値にできないか？ */ }, [filter]);
useEffect(() => { document.title = `${userName} - ${count}`; }, [userName, count]);
```

関心事ごとに分ける。関心事が同じでもトリガーが違うなら分ける。

## 6. lifecycle の 1:1 機械変換

**悪い**:
```jsx
useEffect(() => {
  // componentDidMount
  init();
}, []);

useEffect(() => {
  // componentDidUpdate
  update();
});

useEffect(() => {
  return () => {
    // componentWillUnmount
    cleanup();
  };
}, []);
```

これは class をそのまま写した形。関心事が混ざり、依存管理が崩壊しやすい。

**良い**: 関心事ごとに 1 つの Effect（登録 + cleanup）にまとめる：

```jsx
useEffect(() => {
  const sub = subscribe();
  return () => sub.unsubscribe();
}, [/* このEffectが依存するもの */]);
```

## 7. stale closure

**悪い**:
```jsx
function Timer() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    setInterval(() => setCount(count + 1), 1000); // count は 0 で固定
  }, []);
}
```

**良い（updater）**:
```jsx
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000);
  return () => clearInterval(id);
}, []);
```

**良い（最新値を ref で保持）**:
```jsx
const countRef = useRef(count);
countRef.current = count; // render のたびに更新

useEffect(() => {
  const id = setInterval(() => {
    doSomethingWith(countRef.current);
  }, 1000);
  return () => clearInterval(id);
}, []);
```

## 8. 嘘の dependency array

**悪い**:
```jsx
useEffect(() => {
  fetch(`/api/items/${id}`).then(...);
}, []); // ← id を使ってるのに依存から外す。id が変わってもfetchしない
```

eslint-plugin-react-hooks の `exhaustive-deps` で検出できる。**依存を嘘つくとバグる**。

## 9. 無限ループ

**悪い**:
```jsx
const [items, setItems] = useState([]);
useEffect(() => {
  setItems([...items, newItem]); // items を依存にすると無限
}, [items]);
```

**修正**:
```jsx
// updater で依存から外す
useEffect(() => {
  setItems(prev => [...prev, newItem]);
}, [newItem]);

// または state の持ち方を見直す
```

## 10. createRef の残り

**悪い**（関数コンポーネント内）:
```jsx
function Foo() {
  const ref = React.createRef<HTMLInputElement>(); // 毎レンダーで新しい ref
}
```

**良い**:
```jsx
function Foo() {
  const ref = useRef<HTMLInputElement | null>(null);
}
```

`createRef` は class のインスタンスが持ち続けるから成立していた。関数コンポーネントでは毎回作り直されてしまう。

## 11. 過剰最適化

**悪い**（最初からこう書く）:
```jsx
const handleClick = useCallback(() => { ... }, [x, y]);
const filtered = useMemo(() => list.filter(...), [list]);
export default React.memo(Component);
```

`memo` / `useMemo` / `useCallback` は **計測してから** 入れる。理由もなく全部に付けない。

**悪い理由**:
- コードが読みにくくなる
- 依存配列のバグが増える
- `useCallback` 自体のオーバーヘッドで逆に遅くなることも

## 12. React.FC の惰性使用

**悪い**:
```tsx
const Foo: React.FC<Props> = ({ x, y }) => <div />;
// → 暗黙の children を受け取ってしまう（React 18 以前）
// → ジェネリクスが扱いづらい
// → default props との相性が悪い
```

**良い**:
```tsx
type Props = { x: number; y: string; children?: React.ReactNode };
function Foo({ x, y, children }: Props) { ... }
```

children は必要なときだけ明示する。

## 13. state を object でまるごと持つ

**悪い**:
```jsx
const [state, setState] = useState({ user: null, loading: false, error: null });
setState({ loading: true }); // ← user と error が消える
```

**良い**（意味単位で分割）:
```jsx
const [user, setUser] = useState<User | null>(null);
const [loading, setLoading] = useState(false);
const [error, setError] = useState<Error | null>(null);
```

**良い**（どうしても object にしたいなら updater）:
```jsx
setState(prev => ({ ...prev, loading: true }));
```

相互に依存する state 更新が多いなら `useReducer` を検討。

## 14. fetch を useEffect に直書き

**悪い**:
```jsx
useEffect(() => {
  fetch(`/api/${id}`).then(r => r.json()).then(setData);
}, [id]);
```

問題点：
- race condition: id が連続変化すると古いレスポンスが最後に来るかも
- cleanup で AbortController を呼んでいない
- ローディング / エラー状態の管理が各所に散らばる

**良い**: custom hook にする or データ取得ライブラリ（React Query / SWR）を使う

```jsx
const { data, isLoading, error } = useUserQuery(id);
```

## 15. props を state にするレイアウト

**悪い**:
```jsx
function List({ items }) {
  const [sortedItems, setSortedItems] = useState(items.sort(...));
  // items が更新されても sortedItems は古いまま
}
```

**良い**:
```jsx
function List({ items }) {
  const sortedItems = [...items].sort(...); // 導出
}
```

`items.sort` は破壊的なので注意。`[...items].sort(...)` やスプレッドで新配列にする。

## 16. forwardRef を新規で書く（React 19 では不要）

**悪い**（新規コード、React 19+ 環境）:
```tsx
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => (
  <input ref={ref} {...props} />
));
```

**良い**（React 19+）:
```tsx
type Props = { ref?: React.Ref<HTMLInputElement>; placeholder?: string };

function Input({ ref, ...rest }: Props) {
  return <input ref={ref} {...rest} />;
}
```

新規コードでは `forwardRef` のラップを書かない。既存の `forwardRef` も移行ついでに外す。

## 17. Context.Provider を新規で書く（React 19 では不要）

**悪い**（新規コード、React 19+ 環境）:
```jsx
<MyContext.Provider value={value}>
  {children}
</MyContext.Provider>
```

**良い**（React 19+）:
```jsx
<MyContext value={value}>
  {children}
</MyContext>
```

`.Provider` は引き続き動くが新規は短い形を使う。

## 18. defaultProps を関数 component に付ける（React 19 で削除）

**悪い**:
```tsx
function Button({ label, size }) { ... }
Button.defaultProps = { size: 'md' };
```

**良い**:
```tsx
function Button({ label, size = 'md' }) { ... }
```

`defaultProps` のサポートは React 19 で関数 component から削除された。デフォルト引数で。

## 19. submit pending を自前 useState で管理する（React 19 で不要）

**悪い**:
```tsx
function CommentForm({ onSubmit }) {
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setSending(true);
    try { await onSubmit(text); setText(''); } finally { setSending(false); }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={text} onChange={e => setText(e.target.value)} />
      <button disabled={sending}>{sending ? '...' : 'Send'}</button>
    </form>
  );
}
```

**良い**（React 19+）:
```tsx
import { useFormStatus } from 'react-dom';

function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>{pending ? '...' : 'Send'}</button>;
}

function CommentForm({ onSubmit }) {
  return (
    <form action={async (formData) => onSubmit(formData.get('text'))}>
      <input name="text" defaultValue="" />
      <SubmitButton />
    </form>
  );
}
```

`useState` 3 つの代わりに `useFormStatus` 1 行。`useActionState` を使えば結果の保持も含めて集約できる。

## 20. 楽観 UI を自前で組む（React 19 で不要）

**悪い**:
```tsx
const [items, setItems] = useState(initial);

async function add(text) {
  const optimistic = { id: 'temp', text, sending: true };
  setItems(prev => [...prev, optimistic]);
  try {
    const real = await api.create(text);
    setItems(prev => prev.map(i => i.id === 'temp' ? real : i));
  } catch {
    setItems(prev => prev.filter(i => i.id !== 'temp')); // rollback
  }
}
```

**良い**（React 19+）:
```tsx
const [optimistic, addOptimistic] = useOptimistic(
  items,
  (state, newItem) => [...state, { ...newItem, sending: true }],
);

async function add(text) {
  addOptimistic({ id: 'temp', text });
  await api.create(text);
}
```

rollback は React が自動でやる。失敗時の整合性管理が消える。

## 21. 自前 ID 生成（useId を使う）

**悪い**:
```tsx
const id = useState(() => `field-${Math.random()}`)[0]; // SSR でハイドレーション不一致
```

**良い**:
```tsx
const id = useId();
```

`useId` は SSR ハイドレーション安全な ID を返す。label / aria 用は必ず `useId`。

## 22. 外部ストア購読を useEffect + useState で書く

**悪い**:
```tsx
function useOnline() {
  const [online, setOnline] = useState(navigator.onLine);
  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    window.addEventListener('online', update);
    window.addEventListener('offline', update);
    return () => {
      window.removeEventListener('online', update);
      window.removeEventListener('offline', update);
    };
  }, []);
  return online;
}
```

問題: concurrent rendering 中に値が割れる（tearing）可能性。

**良い**（React 18+）:
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
    () => navigator.onLine,
    () => true, // SSR snapshot
  );
}
```

## 23. react-helmet で `<title>` / `<meta>` を操作（React 19 で不要）

**悪い**（React 19+ 環境）:
```tsx
import { Helmet } from 'react-helmet-async';

<Helmet>
  <title>{article.title}</title>
  <meta name="description" content={article.summary} />
</Helmet>
```

**良い**（React 19+）:
```tsx
<>
  <title>{article.title}</title>
  <meta name="description" content={article.summary} />
  <article>{article.body}</article>
</>
```

React 19 は `<head>` への hoist を自動で行う。`react-helmet` 依存が消える。

## 24. 手動 useMemo / useCallback / React.memo（Compiler 適用環境）

**悪い**（Compiler 適用済み環境で新規に書く）:
```tsx
const handleClick = useCallback(() => doSomething(x), [x]);
const filtered = useMemo(() => items.filter(...), [items]);
export default React.memo(Component);
```

**良い**:
```tsx
function handleClick() { doSomething(x); }
const filtered = items.filter(...);
export default Component;
```

Compiler が自動でメモ化する。`'use no memo'` ディレクティブが付いていたら原因（Rules of React 違反）を直すのが本筋。
