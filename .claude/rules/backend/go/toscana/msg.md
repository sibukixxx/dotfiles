---
paths: internal/msg/*.go
---

# メッセージカタログ (`internal/msg/*.go`)

`messages.yml` から自動生成されるメッセージカタログのコードは、`internal/msg` ディレクトリ配下に配置される。
`make fix` コマンドを使用して、YAML ファイルから Go の定数や関数を生成する。これにより、アプリケーション内で一貫したメッセージ管理が可能となる。
