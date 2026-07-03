# ローカルレビュー実行

CodeRabbit CLI を使用して、現在の変更に対するローカルレビューを実行します。

## 手順

1. 未コミットの変更を確認:
   ```bash
   git status
   git diff --stat
   ```

2. CodeRabbit CLI でレビュー実行:
   ```bash
   coderabbit review --plain
   ```

3. レビュー結果を解析し、TodoWriteで修正タスクを作成

4. 各指摘事項を優先度順に整理:
   - 🔴 Critical: セキュリティ・バグ関連
   - 🟡 Warning: パフォーマンス・可読性
   - 🟢 Info: スタイル・推奨事項

## オプション

トークン効率を重視する場合:
```bash
coderabbit review --prompt-only
```

## 出力形式

```markdown
## ローカルレビュー結果

### Critical (即時対応)
- [ ] ファイル:行 - 内容

### Warning (推奨対応)
- [ ] ファイル:行 - 内容

### Info (任意)
- [ ] ファイル:行 - 内容
```

## 修正後のフロー

1. 指摘事項を修正
2. lint/test 実行
3. 再度 `coderabbit review --plain` で確認
4. 問題なければコミット＆プッシュ
