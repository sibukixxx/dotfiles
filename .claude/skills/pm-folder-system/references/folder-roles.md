# 7フォルダの役割定義

## CLAUDE.md — プロジェクトの脳

**役割**: ドメイン知識レイヤー。新しいセッションを立ち上げるたびにClaude Codeが最初に読むファイル。

**書くべき内容**（処理手順は書かない → pm-layer-separationスキル参照）:
- ステークホルダーの名前・役割・責任範囲・報告関係
- 業界固有の専門用語と定義
- 法規制・安全基準・品質要件など外部制約
- 内部/外部の情報境界（何を外部に出してよいか）
- 頻出する検索クエリのテンプレート（メール検索・Notion検索パターン）
- Active Skills 一覧（どのスキルが何をするか）

**確認コマンド**:
```bash
cat CLAUDE.md
wc -l CLAUDE.md  # 長くなりすぎていないか確認（200行以内が目安）
```

---

## .claude/skills/ — PM業務のビルディングブロック

**役割**: 処理レイヤー。各スキルは「どこから読んで、どう加工して、どこに出すか」を定義する。

**構造**:
```
.claude/skills/
├── transcribe-and-update/SKILL.md   # 音声 → 文字起こし → Notion
├── fill-external-minutes/SKILL.md   # 複数ソース統合 → 外部議事録
├── share-minutes/SKILL.md           # Notion → PDF → メール下書き
└── ...
```

**スキルの命名規則**: 動詞-目的語の形式。何をするか一目でわかる名前にする。
- 良い例: `transcribe-and-update`, `fill-external-minutes`, `share-internal-minutes`
- 悪い例: `minutes-tool`, `process1`, `helper`

**スキルが増えたときの整理サイン**:
- 同じ入力元を参照するスキルが3つ以上ある
- 「どっちのスキルを使うか」で迷う頻度が増えた
- CLAUDE.mdのActive Skills一覧を更新するのが面倒になった

---

## minutes/ — 情報の一次着地点

**役割**: 外部から入ってくる情報の最初の着地点。情報がここで段階的に加工される。

**ファイルの命名規則**:
```
YYYY-MM-DD_[internal|external].[m4a|txt|md]
```

**ライフサイクル**:
```
.m4a  → 音声ファイル（配置するだけ）
.txt  → 文字起こし（/transcribe-and-updateが生成）
.md   → 構造化議事録（スキルが生成、または手動編集）
```

**何を置かないか**:
- 完成した外部向け報告書 → reports/へ
- 分析用のCSVデータ → data/へ

---

## reports/ — 加工済みアウトプット

**役割**: minutes/やdata/の一次情報を統合・分析してステークホルダーに届ける形にしたもの。

**典型的なファイル**:
- `YYYY-MM-DD_weekly-report.md` — 週次状況報告
- `YYYY-MM-DD_project-status.md` — プロジェクト全体状況
- `workflow-definitions.md` — 繰り返し実行するワークフローの定義

**特徴**: このフォルダのファイルは「完成品に近い」。スキルが読み込んでNotionやメールで届けるための最終加工前の状態。

**/fill-external-minutesが参照する理由**:
外部議事録を作るときに、プロジェクト全体の状況文脈（reports/）と会議固有の内容（minutes/）を統合するため。

---

## docs/ — 業務棚卸し

**役割**: 「自分が何をやっているか」の定期的な棚卸し。新メンバーのオンボーディング資料にもなる。

**生成方法**: 定期的に以下のように頼む:
```
「今のプロジェクトの業務を整理して、docs/に追記して」
```

**work-description/との違い**:
- `docs/` = プロジェクト全体の状況・構造の説明（横断的）
- `work-description/` = 個別タスクの手順書（縦断的）

---

## work-description/ — タスク定義書

**役割**: 各業務タスクの手順と目的を明文化したもの。タスクごとに1ファイル。

**典型的なファイル**:
- `external-meeting-prep.md` — 外部定例の議事録準備手順
- `data-classification.md` — データの整理・分類手順
- `weekly-report-flow.md` — 週次報告の作成フロー

**スキルとの違い**:
- `work-description/` = 人間が読む手順書（コンテキスト・目的・注意事項を含む）
- `.claude/skills/` = Claude Codeが実行する処理定義（I/O・ステップ・エラー処理）

スキルを作るときに `work-description/` の内容を参照することがある（目的・文脈をスキルに反映するため）。

---

## data/ — 分析用生データ

**役割**: CSVなどの生データファイル。SQLで集計してプロジェクト進捗を把握するために使う。

**典型的な使い方**:
```bash
# DuckDBでCSVを直接クエリ
duckdb -c "SELECT status, COUNT(*) FROM read_csv_auto('data/tasks.csv') GROUP BY status"
```

**reports/との違い**:
- `data/` = 加工前の生データ（変更しない）
- `reports/` = data/を集計・分析した結果（スキルが生成）
