# TypeScript 関連ガイド

移行の過程で TS 型も整える。class 時代の「なんとなく書いていた型」を関数コンポーネントの流儀に直す。

## React.FC を前提にしない

**避ける**:
```tsx
const Foo: React.FC<Props> = ({ x }) => <div>{x}</div>;
```

問題点：
- 暗黙の `children?: ReactNode` を受け取る（React 18 で改善されたが意味が曖昧）
- ジェネリクスコンポーネントが書きづらい
- `defaultProps` が使えない（関数のデフォルト引数で代替）
- 戻り値型が `ReactElement | null` で縛られる

**推奨**:
```tsx
type Props = { x: number; y: string };

function Foo({ x, y }: Props) {
  return <div>{x}{y}</div>;
}

// children が必要なときは明示
type LayoutProps = { children: React.ReactNode; title: string };

function Layout({ children, title }: LayoutProps) {
  return <div><h1>{title}</h1>{children}</div>;
}
```

## useState の型

初期値から型推論できるときはそのままで良い：

```tsx
const [count, setCount] = useState(0); // number 推論
const [name, setName] = useState(''); // string 推論
```

**初期値が null / 空 / undefined のときは型引数を明示**：

```tsx
const [user, setUser] = useState<User | null>(null);
const [items, setItems] = useState<Item[]>([]);
const [config, setConfig] = useState<Config | undefined>(undefined);
```

型を付けないと `setUser({ ... })` で型エラーになる。

## useRef の型

DOM 参照と mutable 値保持で書き分ける：

```tsx
// DOM 参照（JSX の ref 属性に渡す）
const inputRef = useRef<HTMLInputElement | null>(null);
// 使用時: inputRef.current?.focus()

// mutable 値（レンダーに影響しない、timer ID など）
const timerRef = useRef<number | undefined>(undefined);
// または
const timerRef = useRef<number | null>(null);

// 初期値が決まっている mutable 値
const countRef = useRef(0);
```

### DOM ref と mutable ref を混同しない

```tsx
// ✗ 混乱する
const ref = useRef<HTMLDivElement | number | null>(null);

// ✓ 用途別に分ける
const divRef = useRef<HTMLDivElement | null>(null);
const counterRef = useRef(0);
```

## Event ハンドラの型

明示的に書く：

```tsx
function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
  setName(e.target.value);
}

function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault();
}

function handleClick(e: React.MouseEvent<HTMLButtonElement>) {
  ...
}

// キーボード
function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
  if (e.key === 'Enter') ...
}
```

インラインで書く場合は文脈から推論される：

```tsx
<input onChange={e => setName(e.target.value)} /> // e は推論される
```

ただし再利用する関数では型を明示する方がよい。

## children の型

| 用途 | 型 |
|-----|---|
| 何でも（テキスト、要素、配列、null など） | `React.ReactNode` |
| 単一の React 要素のみ | `React.ReactElement` |
| Render prop | `(args: Args) => React.ReactNode` |
| 単一の文字列のみ | `string` |

```tsx
type Props = {
  children?: React.ReactNode;
  renderItem?: (item: Item) => React.ReactElement;
};
```

## generic component

class 時代の `class Foo<T> extends React.Component<Props<T>>` より、関数 + ジェネリクスの方が素直：

```tsx
type ListProps<T> = {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
};

function List<T>({ items, renderItem }: ListProps<T>) {
  return <ul>{items.map((it, i) => <li key={i}>{renderItem(it)}</li>)}</ul>;
}

// 使用
<List<User> items={users} renderItem={u => u.name} />
```

TSX では `<T>` が JSX と曖昧になる。`<T,>` や `<T extends unknown>` の回避策もあるが、関数宣言 `function List<T>(...)` なら大抵問題なし。

## default props の代替

関数のデフォルト引数で置き換える：

```tsx
type Props = { label?: string; size?: 'sm' | 'md' | 'lg' };

function Button({ label = 'OK', size = 'md' }: Props) {
  ...
}
```

`defaultProps` は関数コンポーネントでは非推奨。

## forwardRef の型

```tsx
type Props = { label: string };

const Input = React.forwardRef<HTMLInputElement, Props>(function Input(
  { label },
  ref,
) {
  return <input aria-label={label} ref={ref} />;
});
```

React 19 では `ref` を通常の prop として受け取れる（forwardRef 不要）。ただし既存コードベースで後方互換が必要なら forwardRef も引き続き使える。

## useReducer の型

```tsx
type State = { count: number; status: 'idle' | 'loading' | 'error' };
type Action =
  | { type: 'increment' }
  | { type: 'reset' }
  | { type: 'setStatus'; status: State['status'] };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment': return { ...state, count: state.count + 1 };
    case 'reset':     return { ...state, count: 0 };
    case 'setStatus': return { ...state, status: action.status };
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0, status: 'idle' });
}
```

Action を union で書くと discriminated union で安全。

## Context の型

```tsx
type ThemeContextValue = { theme: 'light' | 'dark'; toggle: () => void };

const ThemeContext = React.createContext<ThemeContextValue | null>(null);

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
```

初期値を `null` にして、custom hook で non-null 保証する方が「Provider の外で使った」ミスを早期検知できる。

## React 19 に上げるなら

- `@types/react` / `@types/react-dom` をバージョン揃える
- new JSX transform を使う（`tsconfig.json` の `"jsx": "react-jsx"`）
- `import React from 'react'` を型の名前空間用以外では書かない（JSX だけなら不要）
- `ReactElement` など細かい型が一部変わるので、`@types` 更新後に `tsc --noEmit` で全体確認

### 一括アップグレードのチェックリスト

```bash
# React 19 への更新例
pnpm add react@^19 react-dom@^19
pnpm add -D @types/react@^19 @types/react-dom@^19

# 型エラーを洗い出す
pnpm tsc --noEmit
```

破壊的変更がある箇所：

- `ReactElement` のジェネリクスデフォルト
- `React.ElementRef` など一部型の削除・変更
- `defaultProps` の関数コンポーネントサポート削除
- 暗黙 children の挙動変更
