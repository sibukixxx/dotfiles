---
name: react-modernize
description: React コードを最新の流儀（19 + Compiler 時代）に揃えるスキル。クラスコンポーネント → 関数コンポーネント + Hooks への移行に加え、関数コンポーネント内に残る旧 API・自前パターンも最新 API へ置き換える。文法変換ではなく設計の見直しとして進め、「Effect を減らす」「導出 state を消す」「class 的発想を捨てる」「旧 API（forwardRef / Context.Provider / defaultProps / 自前 form 状態 / 自前楽観 UI / 自前 ID）を最新 API に置き換える」ことを最重要視する。「クラスコンポーネントを関数コンポーネントに」「React 移行」「class to function」「クラスから関数に書き換え」「React 関数化」「hooks 移行」「componentDidMount を useEffect に」「setState を useState に」「React 19 化」「最新 React に」「modernize React」「React modernize」などで発動する。lifecycle をそのまま useEffect に機械変換せず、props/state から導出できる値を state にしない方針でレビューする。
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
  - "React 19 化"
  - "最新 React に"
  - "modernize React"
  - "React modernization"
  - "forwardRef を ref prop に"
  - "useActionState"
  - "useFormStatus"
  - "useOptimistic"
  - "React Compiler"
references:
  - references/migration-order.md
  - references/hooks-mapping.md
  - references/anti-patterns.md
  - references/typescript-guide.md
  - references/review-checklist.md
  - references/testing.md
  - references/modern-react-patterns.md
---

# React Modernize

React のクラスコンポーネントを関数コンポーネント + Hooks に書き換え、**さらに最新の React (19 + Compiler 時代) の流儀に揃える**。

**最重要**: 文法変換ではなく設計見直しとして進める。

> - Effect を減らす
> - 導出 state を消す
> - class 的発想を捨てる
> - 旧 API（`forwardRef` / `Context.Provider` / `defaultProps` / 自前 form 状態）を最新 API に置き換える

この4つがゴール。lifecycle を機械的に useEffect へマッピングするのは失敗パターンであり、関数コンポーネント化したからといって「2020 年の関数コンポーネント」止まりも同じく失敗パターン。

「どこまでやるか」は対象コードの規模・優先度で決めるが、**少なくとも新規コードで旧 API を温存しない**ことを基準にする。

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
6. **最適化（必要なら）** — `memo` / `useMemo` / `useCallback`（Compiler 適用環境では原則不要）
7. **TypeScript 型整理** — `React.FC` を外す、event 型・ref 型を明示
8. **最新 React API への置き換え** — 旧 API（`forwardRef` / `Context.Provider` / `defaultProps` / 自前 form 状態 / 自前楽観 UI / 自前 ID）を最新 API へ

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
- React 19 の `ref` 受け取りは普通の prop として書き、`forwardRef` をラップしない

詳細は [references/typescript-guide.md](references/typescript-guide.md) を参照。

### Step 6: 最新 React API へ揃える（モダナイゼーション）

ここで「2020 年の関数コンポーネント」から「現在の React」に引き上げる。**少なくとも以下が新規コードに残っていない**ことを確認する。

| 旧パターン | 新パターン | 理由 |
|---------|---------|-----|
| `forwardRef(({...}, ref) => ...)` | `function X({ ref })` | React 19+ で `ref` は普通の prop |
| `<Context.Provider value>` | `<Context value>` | React 19+ で Context 自身が Provider |
| `defaultProps = {...}` | デフォルト引数 `function X({ y = 0 })` | React 19 で関数 component の `defaultProps` 削除 |
| `import React from 'react'`（型参照以外） | new JSX transform に任せる | `tsconfig.json` の `"jsx": "react-jsx"` |
| 自前 form pending state | `useFormStatus` / `useActionState` | React 19 で標準化 |
| 自前 optimistic UI | `useOptimistic` | race / rollback を React に任せる |
| 自前 ID 生成 / `Math.random` | `useId` | SSR ハイドレーション安全 |
| `useEffect` で `addEventListener` (外部ストア購読) | `useSyncExternalStore` | concurrent rendering で tearing しない |
| `useEffect` + `fetch` | `use(promise)` + Suspense / TanStack Query / SWR | race / cleanup / cache を任せる |
| `react-helmet` / 手動 `<head>` 操作 | `<title>` / `<meta>` / `<link>` を JSX に直接 | React 19 で `<head>` に hoist |
| `<link rel="preload">` 手動挿入 | `preload` / `preinit`（`react-dom`） | フレームワーク標準 |
| 重い更新で UI が固まる | `useTransition` / `useDeferredValue` | ノンブロッキング更新 |
| 手動 `useMemo` / `useCallback` / `React.memo` 多用 | React Compiler に任せる（適用環境） | 自動最適化 |
| `componentDidCatch`（class） | **そのまま class の ErrorBoundary を残す** | hooks に移行不可。例外的に class 残す |

`forwardRef` / `Context.Provider` / `defaultProps` の置き換えは機械的に進む。`useFormStatus` / `useOptimistic` / `useSyncExternalStore` は設計が変わるので、**移行と同じ PR でやらない**ほうがレビューしやすい。

詳細は [references/modern-react-patterns.md](references/modern-react-patterns.md) を参照。

### Step 7: テストで挙動を担保する

以下のテスト観点を揃えると回帰に気づける：

- 初期表示
- props 変更時の挙動
- cleanup（アンマウント時に subscription が解除されるか）
- 非同期完了後の UI
- callback の受け渡し
- ref 経由の挙動
- re-render 境界（不要な再レンダーが発生していないか）

詳細は [references/testing.md](references/testing.md) を参照。

### Step 8: レビューチェックリストを通す

次の観点で差分をレビューする：

設計：

- [ ] props を state にコピーしていないか
- [ ] 導出できる値を state にしていないか
- [ ] 不要な useEffect が残っていないか
- [ ] dependency array が実態と合っているか（嘘の dependency がないか）
- [ ] `useReducer` を使うべき箇所で巨大 `useState` になっていないか

旧来の関数コンポーネント遺産：

- [ ] `React.FC` を惰性で使っていないか
- [ ] 暗黙の `children` を受け取っていないか
- [ ] `createRef` の残りがないか
- [ ] 過剰な `memo` / `useMemo` / `useCallback` がないか（Compiler 適用環境）

最新 React への追従：

- [ ] `forwardRef` を新規で書いていないか（`ref` を prop で受ける）
- [ ] `<Context.Provider>` を新規で書いていないか
- [ ] `defaultProps` がコードベースに残っていないか
- [ ] フォーム送信 pending を自前 `useState` で管理していないか（`useFormStatus` / `useActionState`）
- [ ] 楽観 UI を自前で組んでいないか（`useOptimistic`）
- [ ] 外部ストア購読が `useSyncExternalStore` か
- [ ] アンカー的 ID が `useId` か
- [ ] React 19 対応（new JSX transform、`@types/react*` のバージョン揃え）

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

### 例4: 移行ついでに最新 API へ揃える（モダナイゼーション）

**Before（class、自前 pending state）**:
```jsx
class CommentForm extends React.Component {
  state = { text: '', sending: false, error: null };

  handleSubmit = async (e) => {
    e.preventDefault();
    this.setState({ sending: true, error: null });
    try {
      await this.props.onSubmit(this.state.text);
      this.setState({ text: '', sending: false });
    } catch (err) {
      this.setState({ sending: false, error: err.message });
    }
  };

  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <textarea value={this.state.text} onChange={e => this.setState({ text: e.target.value })} />
        <button disabled={this.state.sending}>{this.state.sending ? 'Sending...' : 'Send'}</button>
        {this.state.error && <p>{this.state.error}</p>}
      </form>
    );
  }
}
```

**ダメな移行**（関数化しただけ、API は古いまま）:
```jsx
function CommentForm({ onSubmit }) {
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState(null);

  async function handleSubmit(e) {
    e.preventDefault();
    setSending(true); setError(null);
    try {
      await onSubmit(text);
      setText(''); setSending(false);
    } catch (err) {
      setError(err.message); setSending(false);
    }
  }

  return (...); // 同じ JSX
}
```

**良い移行**（React 19 の `useActionState` で集約）:
```jsx
function CommentForm({ onSubmit }) {
  const [state, action, isPending] = useActionState(
    async (_prev, formData) => {
      try {
        await onSubmit(formData.get('text'));
        return { ok: true };
      } catch (err) {
        return { ok: false, error: err.message };
      }
    },
    { ok: true },
  );

  return (
    <form action={action}>
      <textarea name="text" defaultValue="" />
      <button disabled={isPending}>{isPending ? 'Sending...' : 'Send'}</button>
      {!state.ok && <p>{state.error}</p>}
    </form>
  );
}
```

3 つの `useState` と手書きの try/catch/finally が `useActionState` 1 本に集約。`isPending` は React が管理するので忘れない。

## アンチパターン早見表

設計：

| アンチパターン | 代わりに |
|-------------|---------|
| props から state にコピー | 導出値として render 時に計算 |
| useEffect で props → state の同期 | 導出値で置き換え |
| useEffect で親への通知 | イベントハンドラで親 callback を呼ぶ |
| 1つの巨大 useEffect | 関心ごとに分割 |
| lifecycle を 1:1 で useEffect に | 不要になるものが大半 |
| 最初から useMemo/useCallback 多用 | pure な設計を先に固める（Compiler 適用環境では原則不要） |
| `this` の代わりに単なる変数 | 再レンダーで消える。state か ref か判断 |

旧来の関数コンポーネント遺産（型・API 面）：

| アンチパターン | 代わりに |
|-------------|---------|
| `useState(null)` のまま型推論任せ | `useState<T \| null>(null)` |
| `React.FC<Props>` を惰性で | 普通の関数 + props 型明示 |
| createRef をコンポーネント関数内で | `useRef` |
| `forwardRef(({}, ref) => ...)` を新規で書く | `function X({ ref })`（React 19+） |
| `<Context.Provider value>` を新規で書く | `<Context value>`（React 19+） |
| `defaultProps = {}` を関数 component に付ける | デフォルト引数 |

最新 React 機会損失：

| アンチパターン | 代わりに |
|-------------|---------|
| 自前 `useState` で submit pending 管理 | `useFormStatus` / `useActionState` |
| 自前 `useState` で楽観 UI rollback | `useOptimistic` |
| 自前 ID / `Math.random` で id 生成 | `useId` |
| `useEffect` で `addEventListener` (外部ストア) | `useSyncExternalStore` |
| `useEffect` + `fetch` で初回読み込み | `use(promise)` + Suspense / TanStack Query / SWR |
| `react-helmet` / 手動 `<head>` 操作 | `<title>` / `<meta>` を JSX に直接（React 19+） |
| 大量更新で UI が固まる | `useTransition` / `useDeferredValue` |

詳細は [references/anti-patterns.md](references/anti-patterns.md) と [references/modern-react-patterns.md](references/modern-react-patterns.md) を参照。

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
- [最新 React パターン（19 + Compiler）](references/modern-react-patterns.md)
