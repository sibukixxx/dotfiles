# テスト観点

移行作業の各ステップで Green を維持するため、テストは以下の観点をカバーする。`@testing-library/react` 前提。

## 基本の観点

### 1. 初期表示

props を与えて最初のレンダー結果を確認。

```tsx
it('renders user name on initial mount', () => {
  render(<UserCard user={{ id: 1, name: 'Alice' }} />);
  expect(screen.getByText('Alice')).toBeInTheDocument();
});
```

移行前後でスナップショットを突き合わせるのも有効（ただしスナップショットに頼りすぎない）。

### 2. props 変更時の挙動

`rerender` で props を変え、期待通りに反応するか。

```tsx
it('updates when user prop changes', () => {
  const { rerender } = render(<UserCard user={{ id: 1, name: 'Alice' }} />);
  rerender(<UserCard user={{ id: 2, name: 'Bob' }} />);
  expect(screen.getByText('Bob')).toBeInTheDocument();
});
```

これは `componentDidUpdate` / `getDerivedStateFromProps` の代わりを検証する重要なテスト。props → state コピーの事故を検出できる。

### 3. cleanup（アンマウント時）

subscription / timer / listener が解除されるか。

```tsx
it('unsubscribes on unmount', () => {
  const unsubscribe = vi.fn();
  const subscribe = vi.fn(() => unsubscribe);
  const { unmount } = render(<Subscriber subscribe={subscribe} />);
  unmount();
  expect(unsubscribe).toHaveBeenCalled();
});
```

`componentWillUnmount` の移行確認として必須。

### 4. 非同期完了後の UI

fetch / Promise / timer の完了後に UI が更新されるか。

```tsx
it('renders data after fetch resolves', async () => {
  render(<Profile id={1} />);
  expect(await screen.findByText('Alice')).toBeInTheDocument();
});
```

`findByX` は自動で await するので race condition も検出しやすい。

### 5. callback の受け渡し

親からの callback が正しく呼ばれるか、引数も含めて検証。

```tsx
it('calls onSelect with selected item', () => {
  const onSelect = vi.fn();
  render(<List items={items} onSelect={onSelect} />);
  fireEvent.click(screen.getByText('Item 1'));
  expect(onSelect).toHaveBeenCalledWith(items[0]);
});
```

`useCallback` / `useEffect` での通知 Effect の事故を検出。

### 6. ref 経由の挙動

imperative API を公開している場合。

```tsx
it('exposes focus method via ref', () => {
  const ref = React.createRef<InputHandle>();
  render(<Input ref={ref} />);
  ref.current?.focus();
  expect(document.activeElement).toBe(screen.getByRole('textbox'));
});
```

`forwardRef` + `useImperativeHandle` を使っている場合の検証。

### 7. re-render 境界

不要な re-render が発生していないかをチェック。

```tsx
it('does not re-render child when unrelated prop changes', () => {
  const renderSpy = vi.fn();
  const Child = React.memo(() => { renderSpy(); return <div />; });

  function Parent({ count, label }: { count: number; label: string }) {
    return <><span>{count}</span><Child /></>;
  }

  const { rerender } = render(<Parent count={1} label="a" />);
  renderSpy.mockClear();
  rerender(<Parent count={1} label="b" />);
  // Child は memo で count/label どちらも関係ないので 0 回
  expect(renderSpy).toHaveBeenCalledTimes(0);
});
```

パフォーマンス回帰の検出に有効。ただし過剰にこの種のテストを書くと実装詳細に依存しすぎるので、Critical Path のみに絞る。

## stale closure 検出のテスト

timer / interval 内で最新値を使うかの検証：

```tsx
it('increments count using latest value in interval', () => {
  vi.useFakeTimers();
  render(<Timer />);
  expect(screen.getByText('0')).toBeInTheDocument();

  act(() => { vi.advanceTimersByTime(1000); });
  expect(screen.getByText('1')).toBeInTheDocument();

  act(() => { vi.advanceTimersByTime(3000); });
  expect(screen.getByText('4')).toBeInTheDocument(); // stale closure だと 1 のまま
});
```

## race condition 検出のテスト

id が連続変化したときに古いレスポンスで上書きされないか：

```tsx
it('ignores stale fetch response when id changes quickly', async () => {
  const { rerender } = render(<Profile id={1} />);
  rerender(<Profile id={2} />); // id=1 の fetch 結果が後から来ても無視されるはず
  await waitFor(() => {
    expect(screen.getByText(/User 2/)).toBeInTheDocument();
  });
});
```

## StrictMode 下でのテスト

React 18/19 の StrictMode は開発時に Effect を意図的に 2 回実行する。これで壊れる設計はバグ。

```tsx
render(
  <React.StrictMode>
    <Component />
  </React.StrictMode>
);
```

StrictMode で壊れるなら本番でも壊れる可能性が高い（hot reload、Suspense 再実行など）。

## テストしにくいコードのサイン

以下の症状があれば設計を見直す：

- `act(() => { ... })` を大量に書かないと警告が出る → Effect が多すぎる疑い
- timer / setTimeout をモックしないと動かない → 外部同期が多すぎる
- 特定の順序で rerender しないと通らない → 副作用の依存関係が暗黙的
- 内部の useState を直接検証したくなる → 導出 state の持ちすぎ

テストしにくいコードはコード臭。「テストが書きやすい設計にするとどうなるか？」を問う。

## カバレッジより挙動

100% カバレッジより、上記の **挙動** が網羅されているかを重視する。特に cleanup とアンマウント後の挙動は抜けやすいので意識的にテストを書く。
