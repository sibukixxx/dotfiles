---
paths:
  - .github/workflows/*.yml
  - .github/workflows/*.yaml
---

# GitHub Actions workflow の検証ルール

`.github/workflows/` 配下を編集したら、完了と報告する前に必ず lint を通す。

```bash
actionlint
```

- `actionlint` は必須。警告・エラーがゼロになるまで直す
- `zizmor` / `ghalint` が PATH にあれば併せて実行する（`zizmor -p .github/workflows/*`、`ghalint run`）。無ければ導入は提案に留める
- サードパーティ action は `uses: owner/repo@<commit-sha>` で固定し、コメントにタグを添える（`# v4.1.0`）
- `permissions:` を明示し、既定の write 権限に頼らない
- `pull_request_target` と `secrets` の組み合わせは原則使わない
