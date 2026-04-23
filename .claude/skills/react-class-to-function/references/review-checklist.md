# レビューチェックリスト

移行後の PR をレビューするとき、以下の観点で差分を見る。

## 設計系（最重要）

- [ ] 不要な `useEffect` が残っていないか
  - props → state の同期 Effect
  - イベント処理を Effect で書いている
  - 親への通知を Effect で行っている
  - 導出値の計算を Effect でやっている
- [ ] 導出できる値を state として持っていないか
  - `const filtered = items.filter(...)` で済むものを state にしていないか
  - `fullName`, `isEmpty`, `total` のような値が state にあれば要確認
- [ ] props を state にコピーしていないか
  - `useState(props.x)` の形は警戒対象
  - 編集用 draft の場合は `key` リセットで明示的にする
- [ ] 1つの巨大 useEffect にまとまっていないか
  - 関心事ごとに分割されているか
  - 複数の関心事が混ざっているとテストも難しい

## React API 使用

- [ ] `React.FC` / `React.FunctionComponent` を惰性で使っていないか
  - 暗黙 children、default props の扱い、ジェネリクス問題
- [ ] `children` を明示的に型宣言しているか
  - 受け取るなら `children: React.ReactNode`（or 他の適切な型）
- [ ] `createRef` がコンポーネント本体に残っていないか
  - 必ず `useRef` へ
- [ ] `forceUpdate` 相当のロジックが残っていないか
  - 設計を疑う
- [ ] dependency array が正確か
  - eslint-plugin-react-hooks の `exhaustive-deps` 警告がないか
  - 依存を嘘つくコメント（`// eslint-disable`）は理由を書く
- [ ] `setState` の移行で object マージ依存が残っていないか
  - `setX({ partial })` で他フィールド消える事故

## Hooks の原則

- [ ] Hooks はトップレベルでのみ呼ばれているか
  - 条件分岐・ループ内の呼び出しがないか
- [ ] custom hook の命名が `useXxx` になっているか
  - リンターが Hook ルールを検出できるように
- [ ] cleanup 関数が必要な場所で書かれているか
  - subscription, timer, event listener, AbortController

## 最適化

- [ ] `memo` / `useMemo` / `useCallback` の使用に正当性があるか
  - 計測 or 明確な理由（props 安定化のため、重い計算）
  - 惰性で全部に付いていないか
- [ ] `useMemo` / `useCallback` の dependency が正しいか
  - 嘘の依存はバグの温床

## TypeScript

- [ ] `useState(null)` / `useState([])` / `useState({})` に型引数が必要な箇所で付いているか
- [ ] event 型が明示されているか（ハンドラが関数として分離されている場合）
- [ ] `useRef` の型が DOM / mutable で適切に分かれているか
- [ ] 新規で `React.FC` を使っていないか

## React 19 関連

- [ ] 新 JSX transform が有効か（`tsconfig.json` の `"jsx": "react-jsx"`）
- [ ] `@types/react` / `@types/react-dom` のバージョンが揃っているか
- [ ] 不要な `import React from 'react'` が残っていないか（型参照以外で）
- [ ] `defaultProps` を関数コンポーネントで使っていないか（React 19 で削除）

## stale closure 対策

- [ ] timer / interval / listener 内で古い値を握っていないか
  - `setX(prev => ...)` updater 形式の使用
  - 最新値参照なら `useRef` で退避
- [ ] async 処理の終了後に unmount されたコンポーネントの state 更新をしていないか
  - AbortController / mounted フラグ / `useQuery` 等のライブラリ

## テスト

- [ ] 初期表示のテスト
- [ ] props 変更時のテスト
- [ ] cleanup のテスト（アンマウント時の挙動）
- [ ] 非同期完了後の UI テスト
- [ ] callback 呼び出しのテスト
- [ ] ref 経由の挙動テスト（imperative API）
- [ ] 不要な re-render が発生していないかのテスト（React DevTools Profiler、またはテストでの render count）

## コード品質

- [ ] state の命名が意図を表しているか（`data` より `userProfile` など）
- [ ] Effect の中身が短く、関心事が明確か
- [ ] custom hook に切り出した方がよい複雑なロジックが本体に残っていないか
- [ ] 古い class API の残骸（`this.xxx`, `bind`, `static` など）がないか

## PR レビュー時の質問テンプレ

設計的な問い：

- 「この `useState` は本当に state か？ props から導出できないか？」
- 「この `useEffect` は何と同期している？ 外部システム以外なら別の場所に置けないか？」
- 「この `useCallback` はなぜ必要？ `memo` された子に渡している？」
- 「このロジックが custom hook になっていないのはなぜ？」

挙動面の問い：

- 「props が途中で変わったとき、古い値を握っている箇所はないか？」
- 「アンマウント時に解除すべきリソースは全部 cleanup されているか？」
- 「非同期完了時にコンポーネントが既に unmount されていた場合、警告や事故は起きないか？」
