# APIキー運用ガイド（1Password CLI + direnv + gitleaks）

個人開発向けに、APIキーを安全に登録・参照・ローテーションするための運用手順。

## 前提

- `1password-cli`（`op` コマンド）がインストール済み
- `direnv` と `gitleaks` が利用可能
- dotfiles 適用済み（`~/.gitleaks.toml` と `~/.config/direnv/templates/api-keys.envrc` が配置済み）

## 1. 1Password CLI 初期設定

```bash
op --version
op signin
```

`op signin` は 1Password アプリ連携で承認する運用を推奨。

## 2. APIキーを 1Password に登録

Item はサービスごとに分け、Field 名は `API key` に統一する。

### 2-1. 新規作成（CLI）

```bash
op item create \
  --vault "Private" \
  --category "API Credential" \
  --title "OpenAI" \
  --tags "api,personal,dev" \
  'API key[password]=<YOUR_OPENAI_API_KEY>'
```

```bash
op item create \
  --vault "Private" \
  --category "API Credential" \
  --title "Anthropic" \
  --tags "api,personal,dev" \
  'API key[password]=<YOUR_ANTHROPIC_API_KEY>'
```

履歴に値を残したくない場合は、対話入力で値を受け取って変数展開する。

```bash
read -rs OPENAI_API_KEY && echo
op item create \
  --vault "Private" \
  --category "API Credential" \
  --title "OpenAI" \
  'API key[password]='"$OPENAI_API_KEY"
unset OPENAI_API_KEY
```

### 2-2. 更新（ローテーション）

```bash
read -rs NEW_OPENAI_API_KEY && echo
op item edit "OpenAI" --vault "Private" \
  'API key[password]='"$NEW_OPENAI_API_KEY"
unset NEW_OPENAI_API_KEY
```

## 3. 読み出し確認

```bash
op read "op://Private/OpenAI/API key"
op read "op://Private/Anthropic/API key"
```

## 4. direnv と連携

```bash
cp ~/.config/direnv/templates/api-keys.envrc .envrc
direnv allow
```

`.envrc` は Git に含めない（`.envrc`, `.direnv/` は ignore 済み）。

## 5. gitleaks で漏えい検知

```bash
gitleaks detect --source . --verbose
```

## 運用ルール

- サービスごと・環境ごとに Item を分ける（例: `OpenAI-dev`, `OpenAI-prod`）
- キー漏えい疑い時は `revoke -> 再発行 -> op item edit` の順で即時対応
- 60-90日目安で定期ローテーション
