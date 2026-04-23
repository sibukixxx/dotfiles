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

| class | hooks |
|-------|-------|
| `static contextType = MyContext; this.context` | `const value = useContext(MyContext)` |
| `<MyContext.Consumer>{v => ...}</MyContext.Consumer>` | `useContext` で十分なことが多い |

## Refs forwarding

```jsx
// class
const Button = React.forwardRef((props, ref) => <button ref={ref} {...props} />);

// hooks（同じ書き方。中身が function なだけ）
const Button = React.forwardRef<HTMLButtonElement, Props>((props, ref) => (
  <button ref={ref} {...props} />
));
```

React 19 では `ref` を通常の prop として受け取れる場合もあるが、後方互換のために `forwardRef` も引き続き使える。
