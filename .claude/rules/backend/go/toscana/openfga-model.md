---
paths: docs/spec/spec-design-file-management-authorization.md,internal/infra/openfga/model.fga,internal/infra/openfga/model.fga.yaml
---

- docs/spec/spec-design-file-management-authorization.md はファイル管理機能の認可モデルの仕様書。
- internal/infra/openfga/model.fga は OpenFGA のモデル定義ファイル。
- internal/infra/openfga/model.fga.yaml は OpenFGA のモデル定義に対するテストケースを記述したファイル。

internal/infra/openfga/model.fgaを変更した場合は、internal/infra/openfga/model.fga.yamlにテストケースを追加、削除、更新しろ。
また、Makefileのopenfga-testターゲットを実行して、テストがすべて成功することを確認しろ。
テスト成功後、docs/spec/spec-design-file-management-authorization.mdの内容を必要に応じて更新しろ。
