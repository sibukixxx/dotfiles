---
name: pm-folder-system
description: |
  Implement and evolve a Claude Code PM project using the 7-folder hub structure and bottom-up skill growth pattern.
  ALWAYS use this skill when the user mentions: フォルダ構成の設計・整理, スキルのリファクタ・被り・整理, パイプラインの設計, 情報の流れの設計, "スキルが増えてきた", "どこに置けばいいかわからない", "セッションが切れても続きから再開したい", "スナップショット", "ボトムアップ", "まずやってみる", project folder structure, skill pipeline, or any request about how to organize a Claude Code PM project operationally.
  Use alongside pm-layer-separation when both folder structure AND CLAUDE.md/skill separation are needed.
---

# PM Folder System — 7フォルダ構造とスキルの育て方

## 関連スキルとの役割分担

```
pm-layer-separation  → 設計原則: CLAUDE.mdとskillsの役割分担（何をどこに書くか）
pm-folder-system     → 実装と運用: フォルダ構造・情報の流れ・スキルの育て方（どう動かすか）
```

両方のスキルが必要なとき（新プロジェクト立ち上げなど）は、先に`pm-layer-separation`を参照してCLAUDE.mdとskillの設計原則を確認してから、このスキルでフォルダ構造と運用を実装する。

---

## Core Concept: フォルダがハブになる

```
あらゆる情報がこのフォルダを経由する
外部サービス（Notion / Slack / Gmail）は届け先であって作業場所ではない
加工のたびにスナップショットが残る → セッションが切れても再開できる
```

**なぜ効くか**: 情報がどこに散らばっていても「ここを見ればわかる」状態が常に維持される。Claude Codeはフォルダの役割が明確なので、指示しなくても適切な情報源に辿り着く。

---

## 7フォルダ構造

```
project/
├── CLAUDE.md            # プロジェクトの脳（ドメイン知識レイヤー）
├── .claude/skills/      # PM業務のビルディングブロック（処理レイヤー）
├── minutes/             # 情報の一次着地点（音声 → 文字起こし → 議事録）
├── reports/             # 加工済みアウトプット（ステークホルダー向け）
├── docs/                # 業務棚卸し・オンボーディング資料
├── work-description/    # タスク定義書（各業務の手順と目的）
└── data/                # 分析用生データ（CSV等、DuckDB/SQLで集計）
```

各フォルダの詳細と判断基準 → `references/folder-roles.md`

---

## 情報フローの原則

```
外部入力 → minutes/ or data/  （着地点）
          ↓ スキル処理
          → reports/ or docs/  （アウトプット）
          ↓ スキル処理
          → Notion / Slack / Gmail  （届け先）
```

**スキルのI/O設計**: フォルダ構成が決まれば、スキルの入力元と出力先は自明に決まる。

| 情報の種類 | 読む場所 | 書く場所 |
|---|---|---|
| 会議の音声・メモ | minutes/ | minutes/（文字起こし）+ Notion |
| プロジェクト状況 | reports/ | reports/ or Notion |
| 生データ・進捗数値 | data/ | reports/ |
| タスク手順の確認 | work-description/ | — |

---

## Step 1: 状況診断（Claude Codeで実行）

```bash
# プロジェクトの現状を把握
ls -la
find . -maxdepth 3 -type f -name "*.md" | sort
find . -maxdepth 3 -type f -name "*.m4a" -o -name "*.csv" | sort
```

判断基準:
- **新プロジェクト** → Step 2へ（フォルダを作る）
- **既存プロジェクト・フォルダ整理** → Step 3へ（ファイルを分類する）
- **スキルが増えて被ってきた** → Step 4へ（リファクタする）

---

## Step 2: 新プロジェクトのセットアップ

**原則: 最初から全部作らない。今必要なものだけ作る。**

最低限から始める構成:
```bash
mkdir -p .claude/skills
mkdir -p minutes
mkdir -p reports
# CLAUDE.md を作成（pm-layer-separationのテンプレートを使う）
```

`docs/`, `work-description/`, `data/` は必要になったら追加する。ファイルが散らかってきたタイミングが追加の合図。

CLAUDE.md の書き方 → `pm-layer-separation` スキルの `references/claude-md-template.md` を参照。

---

## Step 3: 既存プロジェクトのフォルダ整理

散らかったファイルを7フォルダに分類する:

```bash
# 現状のファイル一覧を取得して分類を検討
find . -maxdepth 2 -type f | grep -v ".git" | sort
```

分類の判断基準:

| ファイルの性質 | 移動先 |
|---|---|
| 会議録音・文字起こし・議事録 | minutes/ |
| 完成した報告書・週次レポート | reports/ |
| 「これどうやるんだっけ」系のメモ | work-description/ |
| 業務整理・オンボーディング用まとめ | docs/ |
| CSV・数値データ | data/ |
| 再利用可能な処理手順 | .claude/skills/<name>/SKILL.md |

整理後は CLAUDE.md の「Active Skills」セクションを更新する。

---

## Step 4: スキルのボトムアップ育成サイクル

```
① 自然言語で頼む  →  ② 繰り返したらスキル化  →  ③ 被ったらリファクタ
      ↑___________________________________________________|
```

### ① 自然言語で頼む
スキルを作ろうとしない。「このMTGの録音を文字起こしして議事録にして」と頼む。Claude Codeが試行錯誤しながらやる。うまくいかなければ指摘する。

### ② 2〜3回繰り返したらスキル化
```
「これ毎回やるからスキルにして」
```
Claude Codeがやった手順を `.claude/skills/<name>/SKILL.md` として書き出す。
スキルのI/Oは7フォルダから自動的に決まる（Step 2の表を参照）。
スキルの書き方の原則 → `pm-layer-separation` スキルの `references/skill-scaffold-template.md` を参照。

### ③ 被ってきたらリファクタ
症状: 「どっちのスキル使うんだっけ？」と自分が迷う、またはClaude Codeの回答が曖昧になる。

```bash
# スキル一覧を確認
ls .claude/skills/
cat .claude/skills/*/SKILL.md | grep "^name:\|^description:"
```

壁打ちの聞き方:
```
「/skill-aと/skill-bの役割が被ってるけど、データの流れ的にどう整理すればいい？」
```

整理パターン:
- **統合**: 完全に役割が同じ → 1つにまとめる
- **分割**: 共通部分と固有部分に分ける → atomic skillにする
- **パイプライン化**: A→B→Cの順序関係がある → 呼び出し順を明記したパイプラインskillを作る

---

## Step 5: スナップショット設計（セッション継続性）

**原則: 加工のたびにフォルダにファイルを残す。**

良い設計:
```
音声ファイル配置
  → minutes/YYYY-MM-DD_internal.m4a        （元データ）
  → minutes/YYYY-MM-DD_internal.txt        （文字起こし）
  → minutes/YYYY-MM-DD_internal.md         （構造化議事録）
  → Notion（内部議事録ページ）              （届け先）
```

スキル設計時のチェック:
- [ ] 中間生成物はローカルフォルダに残るか？
- [ ] セッションが切れた場合、どのスナップショットから再開できるか？
- [ ] 再開コマンドは何か？（スキルのRESTART SECTIONに書いておく）

---

## Reference Files

- `references/folder-roles.md` — 7フォルダの詳細な役割定義と判断基準
- `references/pipeline-example.md` — 議事録パイプラインの完全な実装例（8ステップ）
