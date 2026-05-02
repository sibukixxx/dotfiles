# 移行手順の詳細

推奨順序: **render → state → ref → lifecycle → 不要 Effect/state 削除 → 最適化**

一度にやらない。各ステップでテストを通して Green を維持する。

## Step 0: 責務を分解する（移行前に必ずやる）

移行前に以下を書き出す：

```
[責務マップ]
- render: 何を返す？
- state: 何を持つ？ → props から導出できるものはないか
- props: 何を受け取る？
- lifecycle:
  - componentDidMount: 何を初期化？ 外部同期？ それとも初期計算？
  - componentDidUpdate: 何に反応？ 関心事は単一？ 複数？
  - componentWillUnmount: 何を cleanup？
  - shouldComponentUpdate: 本当に必要？ まず外して様子見
  - getDerivedStateFromProps: 導出値で置き換えられる可能性が高い
- ref: 何を保持？ DOM？ mutable 値？
- instance 変数 (this.xxx = ...): 何を保持？ state? ref?
- 束縛された callback: どこで使われている？
```

これを書かずに移行すると、「とりあえず useEffect に入れる」方向に倒れてバグる。

## Step 1: render 関数化

`render()` の中身をそのまま関数本体の return に移す。この時点ではまだ class のまま他のメソッドを残しても良い。

**Before**:
```jsx
class Foo extends React.Component {
  render() {
    const { name } = this.props;
    return <div>{name}</div>;
  }
}
```

**After（途中段階）**:
```jsx
function Foo(props) {
  const { name } = props;
  return <div>{name}</div>;
}
```

- `this.props` → 引数の `props`
- `this.state.x` → 後のステップで `useState` に置き換える
- render 内のローカル関数は関数本体のローカル関数へ
- JSX 内で参照している `this.xxx` メソッドは関数本体に宣言

## Step 2: state 移行

`this.state` を **意味単位で分割して** `useState` 化する。

**Before**:
```jsx
state = { user: null, loading: false, error: null, isEditing: false, draft: '' };
```

**After（悪い）**:
```jsx
const [state, setState] = useState({ user: null, loading: false, error: null, isEditing: false, draft: '' });
```

これは class の `this.state` を 1 つの object にしただけで、`useState` の利点を活かせていない。また `setState` と違って置き換え式なのでバグりやすい。

**After（良い）**:
```jsx
const [user, setUser] = useState<User | null>(null);
const [loading, setLoading] = useState(false);
const [error, setError] = useState<Error | null>(null);
const [isEditing, setIsEditing] = useState(false);
const [draft, setDraft] = useState('');
```

意味単位で分割する。関連する複数の state が同時に動くなら `useReducer` を検討。

### ここで導出 state を削除する

移行前から「state として持っていた」けど実は導出できる値を見つけて消す：

```jsx
// Before
state = { users: [], filteredUsers: [] };
// componentDidUpdate で filteredUsers を更新していた

// After
const [users, setUsers] = useState<User[]>([]);
const filteredUsers = users.filter(u => u.active); // 導出
```

### setState のマージ挙動に注意

```jsx
// class
this.setState({ loading: true }); // 他のフィールドは維持

// function
setStateObj({ loading: true }); // ← これだけになる（他のフィールド消える）
setStateObj(prev => ({ ...prev, loading: true })); // ← 正しい
```

state を object で持つ場合は updater 形式 + スプレッド、または最初から分割しておくほうが安全。

## Step 3: ref 移行

- `React.createRef()` → `useRef<T>(initialValue)`
- `this.xxxRef` → `const xxxRef = useRef(...)`

DOM 参照と mutable 値保持を区別する：

```tsx
// DOM 参照（JSX の ref={...} に渡す）
const inputRef = useRef<HTMLInputElement | null>(null);

// mutable 値保持（レンダーに影響しない値）
const timerIdRef = useRef<number | undefined>(undefined);
const latestValueRef = useRef(initialValue);
```

## Step 4: lifecycle 移行

ここで初めて useEffect を検討する。ただし、移行してみると **半分以上の lifecycle は不要** になることが多い。

### componentDidMount

```jsx
// class
componentDidMount() {
  this.subscription = store.subscribe(this.handleChange);
  this.setState({ initialized: true });
}
```

→ まず分類する：
- `store.subscribe` は **外部同期** → `useEffect(..., [])`
- `setState({ initialized: true })` は **初期値** → `useState(true)` でいい

```jsx
const [initialized] = useState(true); // 最初から true なら state すら不要かも
useEffect(() => {
  const subscription = store.subscribe(handleChange);
  return () => subscription.unsubscribe(); // cleanup も同時に書く
}, []);
```

### componentDidUpdate

```jsx
componentDidUpdate(prevProps, prevState) {
  if (prevProps.userId !== this.props.userId) {
    this.fetchUser(this.props.userId);
  }
  if (prevState.filter !== this.state.filter) {
    this.recomputeList();
  }
}
```

→ 関心事ごとに **分割する**：

```jsx
// userId 変更への反応（外部同期）
useEffect(() => {
  fetchUser(userId);
}, [userId]);

// filter への反応は state ではなく導出値で置き換えられる
const list = useMemo(() => compute(filter, items), [filter, items]);
```

1 つの巨大 useEffect にまとめない。関心事が混ざるとデバッグ困難。

### componentWillUnmount

useEffect の cleanup に統合する：

```jsx
useEffect(() => {
  const id = setInterval(tick, 1000);
  return () => clearInterval(id); // unmount と dependency 変更時に呼ばれる
}, []);
```

### shouldComponentUpdate / PureComponent

**原則として最初は外す**。移行後のコードが実測で遅ければ、局所的に `React.memo` を使う。

### getDerivedStateFromProps

ほぼ必ず導出値で置き換えられる：

```jsx
// Before
static getDerivedStateFromProps(props, state) {
  if (props.value !== state.prevValue) {
    return { displayValue: format(props.value), prevValue: props.value };
  }
  return null;
}

// After
function Foo({ value }) {
  const displayValue = format(value); // 毎レンダー計算。重ければ useMemo
  ...
}
```

## Step 5: 不要な useEffect / state の削除

移行後のコードを見直し、次のパターンを潰す：

- **props → state の同期 useEffect**: 導出値に置き換え
- **state → state の同期 useEffect**: reducer 化 or 導出値
- **イベントに反応する useEffect**: イベントハンドラへ移動
- **親への通知 useEffect**: イベントハンドラで親 callback を呼ぶ

このフェーズが **最も価値が高い**。機械変換しただけのコードと、設計を見直したコードの差はここに出る。

## Step 6: 最適化（必要なら）

プロファイリングで実測してから：

- `React.memo`: 親が頻繁に re-render するが子は props が変わらないとき
- `useMemo`: 重い計算を毎レンダー避けたいとき
- `useCallback`: 子に渡す関数を安定参照にしたいとき（`memo` とセットで）

先にこれらを入れない。先に pure で単純な設計を固める。

## よくある落とし穴

### stale closure

```jsx
// timer が古い count を見続ける
useEffect(() => {
  setInterval(() => setCount(count + 1), 1000);
}, []); // ← count を依存に入れないと stale

// 修正: updater 形式
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000);
  return () => clearInterval(id);
}, []);
```

### 嘘の dependency array

eslint-plugin-react-hooks の exhaustive-deps を有効にして、警告を消す。依存を省略するならその理由を書く。

### 無限ループ

Effect 内で依存している state を更新している。設計を見直す。

## 段階的に進めるためのチェックポイント

1. class のまま render だけ関数化 → テスト Green
2. state を useState へ → テスト Green
3. ref を useRef へ → テスト Green
4. lifecycle を Effect へ（機械変換） → テスト Green
5. 不要な Effect/state を削除 → テスト Green
6. 最適化（必要なら） → テスト Green

各ステップで commit を切ると bisect しやすい。
