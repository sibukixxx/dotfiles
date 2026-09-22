---
name: gemini-japanese-check
description: Gemini 3.8 Flashで成果物の日本語表現だけを校正する。Codexが日本語を含む文章、UI文言、説明、メール、記事、仕様書、コメント等を新規作成または大幅編集したとき、最終化前の自然さ・文法・表記統一チェックに使う。コードのロジックや日本語を含まない内容のレビューには使わない。
---

# Gemini 日本語チェック

成果物を作成・編集する主体はCodexのままとし、最終化前にGemini 3.8 Flashを日本語校正者として使う。

## 実行

1. 対象となる完成稿を `scripts/check_japanese.py` に標準入力またはファイル引数で渡す。スクリプトは日本語を含む行だけを抽出する。
2. Geminiの指摘を原文と照合し、意図・固有名詞・プロジェクト固有の用語を壊さない妥当な修正だけを成果物へ反映する。Geminiの出力を無条件に採用しない。
3. 修正により別の日本語箇所が大きく変わった場合だけ、もう一度チェックする。通常は最大2回で終了する。

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/gemini-japanese-check/scripts/check_japanese.py" path/to/file
```

標準入力も利用できる。

```bash
printf '%s' "$TEXT_TO_REVIEW" | python3 "${CODEX_HOME:-$HOME/.codex}/skills/gemini-japanese-check/scripts/check_japanese.py"
```

既定モデルは `gemini-3.8-flash-high`。一時的にモデルを変える場合だけ `--model` を使う。初回はターミナルで `agy` を対話起動し、Googleアカウントでサインインしてから利用する。ログイン資格情報はAntigravity CLIがOSのキーチェーンに保存する。

## 境界

- ユーザー向け日本語がない成果物では呼び出さない。
- 日本語を含む行だけをAntigravity CLI経由でGeminiへ送る。ただし、その行に機密情報、認証情報、個人情報が含まれる可能性があれば送信せず、その旨を短く伝えてCodex自身で確認する。
- コードブロック内でも、日本語コメントや日本語文字列がある行だけが対象になる。コードの正しさはこのチェックの対象外。
- Antigravity CLI（`agy`）が未導入、未認証、または実行に失敗した場合は、失敗理由を短く伝え、作業全体を止めずCodex自身で日本語を確認する。
- 指摘がなければ成果物を変更しない。チェックを実行したことを最終報告に一言だけ含める。
