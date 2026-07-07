# レビュー修正ループ

PR番号 `$ARGUMENTS` のレビュー指摘を取得し、修正 → プッシュ → 再レビューのループを実行します。

## 手順

### Phase 1: レビュー内容の取得

1. PRのレビューコメントを取得:
   ```bash
   gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/comments --jq '.[] | select(.user.login | contains("coderabbit")) | {path: .path, line: .line, body: .body}'
   ```

2. PR全体へのレビューを取得:
   ```bash
   gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/reviews --jq '.[] | select(.user.login | contains("coderabbit")) | {state: .state, body: .body}'
   ```

### Phase 2: 修正の実行

1. TodoWriteで修正タスクを作成
2. 各指摘事項に対して:
   - 該当ファイルを読み込み
   - 指摘内容に基づいて修正
   - 必要に応じてテスト実行

### Phase 3: コミット＆プッシュ

1. 変更をステージング:
   ```bash
   git add -A
   ```

2. コミット（レビュー対応であることを明記）:
   ```bash
   git commit -m "fix: CodeRabbit レビュー指摘対応"
   ```

3. プッシュ:
   ```bash
   git push
   ```

### Phase 4: ローカルレビュー（オプション）

push後、CodeRabbit CLI でローカルレビューも実行可能:
```bash
coderabbit review --plain
```

## 注意事項

- 各修正後は lint/test を実行して品質確保
- セキュリティ関連の指摘は最優先で対応
- 不明な指摘は質問して確認

## 完了条件

- 全てのレビュー指摘に対応済み
- lint/test がパス
- 変更がプッシュ済み
