# PRレビュー取得

指定されたPR番号 `$ARGUMENTS` のCodeRabbitレビューコメントを取得し、修正が必要な箇所を一覧化してください。

## 手順

1. PRの情報を取得:
   ```bash
   gh pr view $ARGUMENTS --json number,title,body,comments,reviews
   ```

2. PRのレビューコメントを取得（CodeRabbitからのコメント含む）:
   ```bash
   gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/comments
   ```

3. PR全体へのレビューコメントを取得:
   ```bash
   gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/reviews
   ```

4. 取得した内容から以下を整理:
   - CodeRabbit (coderabbitai[bot]) からの指摘事項
   - 他のレビュアーからのコメント
   - 修正が必要な箇所のファイル名と行番号

5. 修正タスクをTodoWriteで一覧化

## 出力形式

```markdown
## PRレビューサマリー: #$ARGUMENTS

### CodeRabbit からの指摘
- [ ] ファイル名:行番号 - 指摘内容
- [ ] ...

### 他のレビューコメント
- [ ] ファイル名:行番号 - コメント内容

### 推奨アクション
1. ...
2. ...
```
