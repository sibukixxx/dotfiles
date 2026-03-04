# 議事録パイプライン — 完全実装例

「内部MTGの内容を整理して、外部定例に臨み、議事録をステークホルダーに送る」
PMの日常業務がどう処理されるかを8ステップで追う。

---

## パイプライン全体図

```
① 音声を minutes/ に配置
       ↓
② /transcribe-and-update
   minutes/*.m4a → minutes/*.txt → Notion（内部議事録）
       ↓
③ /share-internal-minutes
   Notion（内部）→ Slack（内部チャンネル）
       ↓
④ /create-minutes
   日付 → Notion（外部議事録テンプレート作成）
       ↓
⑤ /fill-external-minutes
   minutes/ + reports/ + data/ + Notion → Notion（外部議事録を記入）
       ↓
⑥ 外部MTG（人間の仕事）
       ↓
⑦ /transcribe-and-update（2回目）
   minutes/external*.m4a → Notion（外部議事録を完成版に更新）
       ↓
⑧ /share-minutes
   Notion → PDF + メール下書き → 送信確認
```

---

## 各ステップの詳細

### ① 音声を minutes/ に配置
```bash
# 録音ファイルをプロジェクトフォルダへ
cp ~/Downloads/2026-02-25_internal.m4a ./minutes/
```
スナップショット: `minutes/2026-02-25_internal.m4a`

---

### ② /transcribe-and-update — 文字起こし → 内部議事録

**SKILL.mdの骨格**:
```markdown
## Context Loading
Read CLAUDE.md:
- stakeholders（参加者の役割確認）
- terminology（専門用語の正確な変換）

## Input
- minutes/YYYY-MM-DD_internal.m4a

## Processing
1. 音声を文字起こし
2. CLAUDE.mdのterminologyを適用して専門用語を補正
3. トピック別に再構成（議題・決定事項・アクションアイテム）
4. stakeholdersの役割情報を使って発言者を識別

## Output
- minutes/YYYY-MM-DD_internal.txt （文字起こし生テキスト）
- Notion: 内部議事録DBに新規ページ作成・更新
```

スナップショット: `minutes/2026-02-25_internal.txt` + Notion内部議事録

---

### ③ /share-internal-minutes — 内部チームへ共有

```markdown
## Input
- Notion（内部議事録ページ）

## Processing
- 議題とアクションアイテムを抽出
- Slack投稿フォーマットに変換（CLAUDE.mdの報告スタイル適用）

## Output
- Slack: 内部チャンネルに投稿
```

スナップショット: Slackの投稿（外部サービス）

---

### ④ /create-minutes — 外部議事録テンプレート作成

```markdown
## Input
- 日付（引数として受け取る）

## Processing
- CLAUDE.mdのステークホルダー情報からアジェンダ構造を生成
- 外部向け議事録のテンプレートを作成

## Output
- Notion: 外部議事録DBに新規テンプレートページ作成
```

スナップショット: Notion外部議事録ページ（空のテンプレート）

---

### ⑤ /fill-external-minutes — テンプレートに情報を記入

**このスキルが複数ソースを統合する中核スキル**

```markdown
## Context Loading
Read CLAUDE.md:
- internal_boundary（何をフィルタリングするか）
- stakeholders（誰向けに書くか）
- reporting_style.external（粒度・トーン）
- terminology（内部用語 → 外部用語の変換）

## Input（4ソース）
1. minutes/YYYY-MM-DD_internal.md （内部議事録）
2. reports/latest-project-status.md （プロジェクト状況）
3. data/progress.csv （進捗数値）
4. Notion: 検証メモ・過去のフィードバック

## Processing
1. 4ソースから関連情報を抽出
2. internal_boundaryに基づいてフィルタリング
3. 内部の技術的議論をステークホルダー向けの言葉に翻訳
4. reporting_style.externalに合わせて構成・粒度を調整
5. ④で作ったテンプレートに記入

## Output
- Notion: 外部議事録ページを更新
```

**ポータビリティの確認**:
このスキルの処理手順はどのプロジェクトでも同じ。CLAUDE.mdの `internal_boundary`, `stakeholders`, `reporting_style`, `terminology` が変われば、全く異なる出力が生成される。

スナップショット: Notion外部議事録ページ（記入済み）

---

### ⑥ 外部MTG（人間の仕事）

Notionの議事録をアジェンダ兼資料として画面共有。MTG中にメモを取り、音声も録音する。

```bash
# MTG終了後、録音を minutes/ に配置
cp ~/Downloads/2026-02-25_external.m4a ./minutes/
```

---

### ⑦ /transcribe-and-update（2回目） — 議事録を完成版に

```markdown
## Input
- minutes/2026-02-25_external.m4a
- MTG中のメモ（テキストで渡す）

## Processing
- 外部MTGの音声を文字起こし
- メモと音声を統合
- 決定事項・フィードバック・次回アクションアイテムを追記
- Notionの外部議事録ページを完成版に更新

## Output
- minutes/2026-02-25_external.txt
- Notion: 外部議事録ページを完成版に更新
```

スナップショット: `minutes/2026-02-25_external.txt` + Notion完成版議事録

---

### ⑧ /share-minutes — 届ける

```markdown
## Input
- Notion（完成版の外部議事録）

## Processing
1. NotionページをPDFにエクスポート
2. 要点を3-5行に要約
3. CLAUDE.mdのステークホルダー情報から宛先を特定
4. メール下書きを作成

## Output
- PDF（ローカルに保存）
- Gmail: メール下書き（送信前に確認）
```

スナップショット: `reports/2026-02-25_external-minutes.pdf` + Gmail下書き

---

## セッション切断からの再開

各スナップショットから再開できる:

| 再開点 | 確認コマンド | 再開方法 |
|---|---|---|
| ②の後 | `ls minutes/*.txt` | `/fill-external-minutes`から |
| ⑤の後 | Notionで確認 | 外部MTG後に⑦から |
| ⑦の後 | `ls minutes/*external.txt` | `/share-minutes`から |
