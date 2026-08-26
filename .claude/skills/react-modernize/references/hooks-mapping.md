# Class → Hooks 対応表

**機械変換の表ではない。** 多くの場合、Hooks に書き換える前に「そもそも不要ではないか」を疑う。

## State

| class | hooks | 注意 |
|-------|-------|-----|
| `this.state = { ... }` | `const [x, setX] = useState(initial)` | 意味単位で分割。1つの巨大 object にしない |
| `this.setState({ x: v })` | `setX(v)` | `useState` は **マージしない**。置き換え |
| `this.setState({ x: v }, callback)` | `useEffect(() => callback(), [x])` or そもそも別の場所へ | 更新後に何かしたいケースは大抵 Effect じゃなくて別設計 |
| `this.setState(prev => ...)` | `setX(prev => ...)` | stale closure 対策で updater 形式は有用 |
| 複数 state の相互依存更新 | `useReducer` | setX → setY → setZ が連鎖するなら reducer |

## Props

| class | hooks |
|-------|-------|
| `this.props` | 引数の `props` or 分割代入 `function Foo({ x, y })` |
| `defaultProps` | 関数のデフォルト引数 `function Foo({ x = 0 })` |

## Ref / instance variable

| class | hooks | 注意 |
|-------|-------|-----|
| `this.xxxRef = React.createRef()` | `const xxxRef = useRef<T>(initial)` | |
| `this.xxx = ...`（インスタンス変数） | `useRef` か `useState` | 再レンダー影響なし → `useRef`、影響あり → `useState` |
| DOM 参照 | `useRef<HTMLElement \| null>(null)` | JSX の `ref={...}` に渡す |
| timer ID, subscription | `useRef` | 再レンダーで消えないようにする |

## Lifecycle

### componentDidMount

```jsx
// class
componentDidMount() {
  doSomething();
}

// hooks（機械変換: だいたい良くない）
useEffect(() => {
  doSomething();
}, []);
```

**先に疑う**:
- 初期値計算なら `useState(() => ...)` で十分ではないか
- 同期的にやれるなら Effect なしで render 時にやればいい
- 外部 API 呼び出しならデータ取得ライブラリに寄せるべきではないか
- グローバル listener 登録なら `useEffect(..., [])` が妥当

### componentDidUpdate

```jsx
// class
componentDidUpdate(prevProps, prevState) {
  if (prevProps.x !== this.props.x) doA();
  if (prevState.y !== this.state.y) doB();
}
```

**悪い移行（1つの巨大 Effect）**:
```jsx
useEffect(() => {
  doA();
  doB();
}, [x, y]); // 関心事が混ざる
```

**良い移行（関心事ごと）**:
```jsx
useEffect(() => { doA(); }, [x]);
useEffect(() => { doB(); }, [y]);
```

**さらに良い移行（Effect なし）**:
```jsx
// doA() は x から導出できる値の計算だった
const a = compute(x);

// doB() は y に反応するイベント処理だった → ハンドラへ移動
```

### componentWillUnmount

```jsx
// class
componentWillUnmount() {
  this.subscription.unsubscribe();
}

// hooks
useEffect(() => {
  // 登録はここ
  const sub = something.subscribe(...);
  return () => sub.unsubscribe(); // cleanup
}, []);
```

cleanup は dependency 変更時にも呼ばれる点が class の unmount と違う。

### shouldComponentUpdate / PureComponent

**原則として削除**。

- まず Effect / state を整理して余計な re-render を減らす
- それでもパフォーマンス問題があれば、局所的に `React.memo(Component)` を適用
- 子 component に渡す callback は `useCallback`、重い計算結果は `useMemo` で安定化

### getDerivedStateFromProps

**ほぼ必ず削除可能**。導出値は render 時に計算する。

```jsx
// class
static getDerivedStateFromProps(props, state) {
  if (props.user.id !== state.userId) {
    return { userId: props.user.id, formDraft: '' };
  }
  return null;
}

// hooks — key でリセット
<Form key={user.id} user={user} />

function Form({ user }) {
  const [formDraft, setFormDraft] = useState('');
  // user.id が変わると key でコンポーネントが作り直される
}
```

key を変えると React が unmount → mount するので state が初期化される。

### getSnapshotBeforeUpdate / componentDidCatch

- `getSnapshotBeforeUpdate`: hooks で直接の対応なし。`useLayoutEffect` と `useRef` を組み合わせる
- `componentDidCatch`: hooks で直接の対応なし。**class の ErrorBoundary はそのまま残す**

ErrorBoundary は React 19 現在も hooks では書けない。class のままでよい。

## Forcing update

| class | hooks |
|-------|-------|
| `this.forceUpdate()` | 原則使わない。state を正しく持つ |

`forceUpdate` の代替が必要な局面は、ほぼ設計の問題。

## Context

| class | hooks | 注意 |
|-------|-------|-----|
| `static contextType = MyContext; this.context` | `const value = useContext(MyContext)` | React 19 では `use(MyContext)` も可（条件分岐内で読める） |
| `<MyContext.Consumer>{v => ...}</MyContext.Consumer>` | `useContext` で十分なことが多い | |
| `<MyContext.Provider value={...}>` | `<MyContext value={...}>` | **React 19+** で `.Provider` 不要。新規はこちらを使う |

```jsx
// React 18 以前
<MyContext.Provider value={theme}>{children}</MyContext.Provider>

// React 19+
<MyContext value={theme}>{children}</MyContext>
```

`.Provider` は引き続き動くが、新規コードでは短い形を使う。

## Refs forwarding

```jsx
// 旧（React 18 以前）
const Button = React.forwardRef((props, ref) => <button ref={ref} {...props} />);

const Button = React.forwardRef<HTMLButtonElement, Props>((props, ref) => (
  <button ref={ref} {...props} />
));
```

**React 19+**: `ref` は普通の prop として受け取れる。`forwardRef` でラップしない。

```tsx
type Props = { label: string; ref?: React.Ref<HTMLButtonElement> };

function Button({ label, ref }: Props) {
  return <button ref={ref}>{label}</button>;
}
```

新規コードでは `forwardRef` を書かない。既存の `forwardRef` も漸次外していく。

### ref callback の cleanup（React 19+）

ref callback はクリーンアップ関数を返せる。

```tsx
<div
  ref={(node) => {
    if (!node) return;
    const observer = new IntersectionObserver(...);
    observer.observe(node);
    return () => observer.disconnect();
  }}
/>
```

旧来は ref callback で `null` チェックして `useEffect` に逃がしていたものが、ref 一箇所で完結する。

## defaultProps（React 19 で削除）

| 旧 | 新 |
|---|---|
| `MyComponent.defaultProps = { x: 0 }` | デフォルト引数 `function MyComponent({ x = 0 })` |

React 19 で関数コンポーネントの `defaultProps` サポートが削除された。デフォルト引数で置き換える。class component の `defaultProps` は引き続き動く。

## Form / Action 系（React 19 新規）

class 時代に `useState` で submit pending を管理していたコードは、関数コンポーネント化のついでに最新 API へ。

| 自前パターン | React 19 API |
|------------|------------|
| `useState` で submit pending / error を管理 | `useActionState(action, initial)` |
| 子から親 form の状態を見る | `useFormStatus()` |
| 楽観 UI rollback を自前で組む | `useOptimistic(state, updater)` |
| `<form onSubmit={...}>` で preventDefault + state 更新 | `<form action={async (formData) => ...}>` |

詳細は [modern-react-patterns.md](modern-react-patterns.md) を参照。

## 外部ストア購読

| パターン | 対応 |
|--------|-----|
| `componentDidMount` で `addEventListener` + `setState` | `useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)` |
| Redux / Zustand / RxJS 等の購読 | 各ライブラリの hook、または `useSyncExternalStore` |

`useEffect` + `useState` の自前実装は concurrent rendering で tearing する可能性あり。`useSyncExternalStore` を使う。

## ID 生成

| 旧 | 新 |
|---|---|
| `Math.random()` で id 生成 / counter | `useId()` |
| `uuid` ライブラリで render 時生成 | `useId()` |

label / aria 用 id は `useId` を使うと SSR ハイドレーション安全。
