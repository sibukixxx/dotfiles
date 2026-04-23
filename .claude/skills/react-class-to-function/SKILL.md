---
name: react-class-to-function
description: React のクラスコンポーネントを関数コンポーネント + Hooks に移行するスキル。単なる文法変換ではなく設計の見直しとして進め、「Effect を減らす」「導出 state を消す」「class 的発想を捨てる」ことを最重要視する。「クラスコンポーネントを関数コンポーネントに」「React 移行」「class to function」「クラスから関数に書き換え」「React 関数化」「hooks 移行」「componentDidMount を useEffect に」「setState を useState に」などで発動する。lifecycle をそのまま useEffect に機械変換せず、props/state から導出できる値を state にしない方針でレビューする。
trigger:
  - "クラスコンポーネントを関数コンポーネントに"
  - "class to function"
  - "クラスから関数に"
  - "React 関数化"
  - "hooks 移行"
  - "React migration"
  - "componentDidMount を useEffect"
  - "setState を useState"
  - "class component"
  - "function component"
  - "React.Component"
  - "PureComponent"
  - "React 19 移行"
references:
  - references/migration-order.md
  - references/hooks-mapping.md
  - references/anti-patterns.md
  - references/typescript-guide.md
  - references/review-checklist.md
  - references/testing.md
---

# React Class to Function Migration

React のクラスコンポーネントを関数コンポーネント + Hooks に書き換える。

**最重要**: 文法変換ではなく設計見直しとして進める。

> - Effect を減らす
> - 導出 state を消す
> - class 的発想を捨てる

この3つが移行の本質。lifecycle を機械的に useEffect へマッピングするのは失敗パターン。

## 移行前の心構え

| class 的発想 | 関数コンポーネント的発想 |
|------------|-----------------------|
| インスタンスが1つあり続ける | 再レンダーごとに本体が再実行される |
| `this.state` でまとめて保持 | 意味単位で `useState` を分ける |
| lifecycle に処理を配置 | 導出値は render 時に計算、Effect は外部同期のみ |
| `setState` は部分マージ | `useState` は置き換え |
| `this.xxx` で最新値にアクセス | stale closure に注意（`useRef` 検討） |

## 使い方

### Step 1: 既存クラスコンポーネントの責務を分解する

まず移行前に、対象コンポーネントの責務を洗い出す。

- render で何を返しているか
- state に何を持っているか（本当に state か、導出値か）
- lifecycle で何をしているか（外部同期か、導出計算か、イベント処理か）
- ref を何に使っているか（DOM 参照か、mutable 保持か）
- this で束縛された callback がどこで使われているか

**最重要の問い**: 「この state は本当に state か？ props から導出できないか？」

### Step 2: 推奨の移行順で進める

1. **render 関数化** — `render()` の中身をそのまま関数本体に移す
2. **state 移行** — `this.state` を意味単位で分割して `useState` 化
3. **ref 移行** — `createRef` → `useRef`、DOM 用と mutable 用を区別
4. **lifecycle 移行** — ここで初めて Effect を検討。ただし多くはそもそも不要
5. **不要な Effect / state 削除** — 導出値は計算、イベントはハンドラへ
6. **最適化（必要なら）** — `memo` / `useMemo` / `useCallback`

詳細は [references/migration-order.md](references/migration-order.md) を参照。

### Step 3: lifecycle → Hooks の対応を確認する

lifecycle を useEffect に機械変換してはいけない。実際には次のように分類する：

| 旧 lifecycle | 移行先 | 注意 |
|------------|-------|-----|
| `componentDidMount` | 外部同期だけ `useEffect(..., [])` | 初期値計算は `useState(() => ...)` で足りる |
| `componentDidUpdate` | 関心ごとに分割した複数の `useEffect` | 巨大な1つにまとめない |
| `componentWillUnmount` | `useEffect` の cleanup | subscription / timer / listener / imperative API のみ |
| `shouldComponentUpdate` | 原則不要（必要時のみ `memo`） | 先に最適化しない |
| `getDerivedStateFromProps` | render 時の計算で置き換え | state に持たない |

完全な対応表は [references/hooks-mapping.md](references/hooks-mapping.md) を参照。

### Step 4: 不要な useEffect を削除する

移行後に一番見直すべきはここ。以下のパターンは Effect ではなく通常の計算やハンドラで書ける：

- `useEffect` で props から state を計算している → 導出値（render 時に計算）
- `useEffect` でイベント結果を state に書いている → イベントハンドラで直接
- `useEffect` で親に値を通知している → イベントハンドラで親の callback を呼ぶ
- `useEffect` で state を連鎖更新している → 1つの state とreducer、または単純な計算に

原則: **useEffect は外部システム（DOM、ネットワーク、subscription、timer）との同期に限定する**。

詳細とコード例は [references/anti-patterns.md](references/anti-patterns.md) を参照。

### Step 5: TypeScript 型を整える

- `React.FC` を前提にしない（暗黙の children、ジェネリクスの扱い、default props の問題）
- props 型は明示、children は必要なときだけ
- `useState` は初期値で型推論が効かないとき型引数を付ける（`useState<User | null>(null)`）
- event 型（`React.ChangeEvent<HTMLInputElement>` など）を明示
- `useRef<HTMLInputElement | null>(null)` と `useRef<number | undefined>(undefined)` を使い分け

詳細は [references/typescript-guide.md](references/typescript-guide.md) を参照。

### Step 6: テストで挙動を担保する

以下のテスト観点を揃えると回帰に気づける：

- 初期表示
- props 変更時の挙動
- cleanup（アンマウント時に subscription が解除されるか）
- 非同期完了後の UI
- callback の受け渡し
- ref 経由の挙動
- re-render 境界（不要な再レンダーが発生していないか）

詳細は [references/testing.md](references/testing.md) を参照。

### Step 7: レビューチェックリストを通す

次の観点で差分をレビューする：

- [ ] `React.FC` を惰性で使っていないか
- [ ] 暗黙の `children` を受け取っていないか
- [ ] props を state にコピーしていないか
- [ ] 導出できる値を state にしていないか
- [ ] 不要な useEffect が残っていないか
- [ ] dependency array が実態と合っているか（嘘の dependency がないか）
- [ ] `createRef` の残りがないか
- [ ] 過剰な `memo` / `useMemo` / `useCallback` がないか
- [ ] `useReducer` を使うべき箇所で巨大 `useState` になっていないか
- [ ] React 19 対応（JSX transform、`@types/react*` のバージョン）

完全なチェックリストは [references/review-checklist.md](references/review-checklist.md) を参照。

## 例

### 例1: 導出 state を排除する

**Before（class）**:
```jsx
class UserList extends React.Component {
  state = { filtered: [] };

  componentDidMount() {
    this.setState({ filtered: this.props.users.filter(u => u.active) });
  }

  componentDidUpdate(prev) {
    if (prev.users !== this.props.users) {
      this.setState({ filtered: this.props.users.filter(u => u.active) });
    }
  }

  render() { return <List items={this.state.filtered} />; }
}
```

**After（関数）**:
```jsx
function UserList({ users }) {
  const filtered = users.filter(u => u.active); // 導出値は render 時に計算
  return <List items={filtered} />;
}
```

`useEffect` も `useState` も不要。`filtered` は `users` から導出できるため state に持つ理由がない。

### 例2: componentDidMount を機械変換しない

**Before**:
```jsx
class Profile extends React.Component {
  state = { data: null };
  componentDidMount() {
    fetch(`/api/users/${this.props.id}`).then(r => r.json()).then(data => this.setState({ data }));
  }
  render() { ... }
}
```

**ダメな移行**（機械変換）:
```jsx
function Profile({ id }) {
  const [data, setData] = useState(null);
  useEffect(() => {
    fetch(`/api/users/${id}`).then(r => r.json()).then(setData);
  }, []); // ← id が変わっても取り直さないバグ
  ...
}
```

**良い移行**:
```jsx
function Profile({ id }) {
  const { data } = useUserQuery(id); // データ取得ライブラリに寄せる
  ...
}
```

custom hook やデータ取得ライブラリ（React Query / SWR / Relay など）へ寄せる方が、race condition、cleanup、依存変更への対応が正しくなる。

### 例3: stale closure に注意する

**Before**（class）: `this.state.count` は常に最新値。

**After**（関数）:
```jsx
function Timer() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setCount(count + 1), 1000); // ← count は 0 のまま
    return () => clearInterval(id);
  }, []);
}
```

**修正**:
```jsx
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000); // updater 形式
  return () => clearInterval(id);
}, []);
```

または「最新値を参照したいだけ」なら `useRef` に退避する。

## アンチパターン早見表

| アンチパターン | 代わりに |
|-------------|---------|
| props から state にコピー | 導出値として render 時に計算 |
| useEffect で props → state の同期 | 導出値で置き換え |
| useEffect で親への通知 | イベントハンドラで親 callback を呼ぶ |
| 1つの巨大 useEffect | 関心ごとに分割 |
| lifecycle を 1:1 で useEffect に | 不要になるものが大半 |
| 最初から useMemo/useCallback 多用 | pure な設計を先に固める |
| `useState(null)` のまま型推論任せ | `useState<T \| null>(null)` |
| `React.FC<Props>` を惰性で | 普通の関数 + props 型明示 |
| createRef をコンポーネント関数内で | `useRef` |
| `this` の代わりに単なる変数 | 再レンダーで消える。state か ref か判断 |

詳細は [references/anti-patterns.md](references/anti-patterns.md) を参照。

## トラブルシューティング

### Q: 無限ループになる

dependency array に state を入れて、Effect の中でその state を更新している。
→ 更新関数形式（`setX(x => x + 1)`）を使う、または依存から外せる設計に変える。

### Q: タイマーで古い値が見える

stale closure。`setX(x => ...)` の updater 形式、または `useRef` で最新値を保持。

### Q: アンマウント後に setState 警告

cleanup で subscription / timer / fetch abort を解除していない。`AbortController` や cleanup 関数を追加。

### Q: PureComponent の最適化がなくなって遅い

まず pure な設計・props 分解で解決できないか確認。それでも必要なら `memo` を限定的に使う。

### Q: class の this.xxx = ... で保持していた値をどうするか

- 次のレンダーまで持ち越したい → `useState`
- レンダーには影響しないが保持したい → `useRef`
- 導出できる値 → どこにも持たない

## 参考資料

- [移行手順の詳細](references/migration-order.md)
- [lifecycle と Hooks の対応表](references/hooks-mapping.md)
- [アンチパターン集](references/anti-patterns.md)
- [TypeScript 型の書き方](references/typescript-guide.md)
- [レビューチェックリスト](references/review-checklist.md)
- [テスト観点](references/testing.md)
