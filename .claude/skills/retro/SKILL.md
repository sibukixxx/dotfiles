---
name: retro
description: |
  週次エンジニアリング振り返り。コミット履歴、作業パターン、コード品質メトリクスを分析し、
  チーム貢献の称賛と成長機会を含む振り返りレポートを生成する。
  JSON履歴を保存してトレンド追跡も可能。
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
---

# /retro — エンジニアリング振り返り

コミット履歴、作業パターン、コード品質メトリクスを分析する包括的な振り返りレポートを生成する。

## 使い方

- `/retro` — デフォルト: 過去7日間
- `/retro 24h` — 過去24時間
- `/retro 14d` — 過去14日間
- `/retro 30d` — 過去30日間
- `/retro compare` — 今期 vs 前期の比較
- `/retro compare 14d` — 明示的なウィンドウで比較

## Instructions

引数 `$ARGUMENTS` をパースして期間を決定する。デフォルトは7日間。

### Step 1: デフォルトブランチ検出

```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "main"
```

### Step 2: データ収集

まず origin をフェッチし、ユーザーを特定:

```bash
git fetch origin <default> --quiet
git config user.name
git config user.email
```

以下の git コマンドを**並列で**実行:

```bash
# 1. 全コミット（タイムスタンプ、サブジェクト、ハッシュ、著者、変更統計）
git log origin/<default> --since="<window>" --format="%H|%aN|%ae|%ai|%s" --shortstat

# 2. テスト vs 本番 LOC 内訳
git log origin/<default> --since="<window>" --format="COMMIT:%H|%aN" --numstat

# 3. セッション検出用タイムスタンプ
git log origin/<default> --since="<window>" --format="%at|%aN|%ai|%s" | sort -n

# 4. ホットスポット分析
git log origin/<default> --since="<window>" --format="" --name-only | grep -v '^$' | sort | uniq -c | sort -rn

# 5. PR番号抽出
git log origin/<default> --since="<window>" --format="%s" | grep -oE '#[0-9]+' | sed 's/^#//' | sort -n | uniq | sed 's/^/#/'

# 6. 著者別ファイルホットスポット
git log origin/<default> --since="<window>" --format="AUTHOR:%aN" --name-only

# 7. 著者別コミット数
git shortlog origin/<default> --since="<window>" -sn --no-merges
```

### Step 3: メトリクス算出

| メトリクス | 値 |
|-----------|---|
| main へのコミット | N |
| コントリビューター | N |
| マージ済みPR | N |
| 追加行数 | N |
| 削除行数 | N |
| 差引LOC | N |
| テストLOC（追加） | N |
| テストLOC比率 | N% |
| アクティブ日数 | N |
| 検出セッション | N |
| セッション時間あたりLOC | N |

著者別リーダーボード:
```
Contributor         Commits   +/-          Top area
You (name)               32   +2400/-300   src/
alice                    12   +800/-150    app/services/
```

### Step 4: コミット時間分布

時間別ヒストグラムを表示:
```
Hour  Commits  ████████████████
 09:    8      ████████
 14:    5      █████
```

ピーク時間、デッドゾーン、深夜コーディングクラスタを特定。

### Step 5: 作業セッション検出

連続コミット間の **45分ギャップ** でセッションを区切る:

- **ディープセッション** (50分以上)
- **ミディアムセッション** (20-50分)
- **マイクロセッション** (20分未満)

アクティブコーディング合計時間、平均セッション長、アクティブ時間あたりLOCを算出。

### Step 6: コミットタイプ内訳

Conventional Commit プレフィックスで分類:
```
feat:     20  (40%)  ████████████████████
fix:      27  (54%)  ███████████████████████████
refactor:  2  ( 4%)  ██
```

fix比率が50%超 → フラグ（「ship fast, fix fast」パターン）。

### Step 7: ホットスポット分析

変更頻度上位10ファイル。以下をフラグ:
- 5回以上変更されたファイル（チャーンホットスポット）
- テストファイル vs 本番ファイルの割合

### Step 8: PR サイズ分布

- **Small** (<100 LOC)
- **Medium** (100-500 LOC)
- **Large** (500-1500 LOC)
- **XL** (1500+ LOC) — ファイル数とともにフラグ

### Step 9: フォーカススコア & 今週のShip

**フォーカススコア**: コミットの最多トップレベルディレクトリへの集中率。高い = 集中的な深い作業。

**今週のShip**: 期間中の最大LOC PR をハイライト。

### Step 10: チームメンバー分析

各コントリビューター（自分含む）について:
1. コミット数・LOC
2. フォーカス領域（上位3ディレクトリ）
3. コミットタイプミックス
4. セッションパターン
5. テスト規律（テストLOC比率）
6. 最大Ship

**自分（"You"）**: 最も詳細に分析。

**各チームメート**: 2-3文の作業要約 + **称賛**（1-2個、コミットに基づく具体的なもの）+ **成長機会**（1個、建設的な提案）。

### Step 11: ストリーク追跡

```bash
# チームストリーク: 全コミット日のユニーク一覧
git log origin/<default> --format="%ad" --date=format:"%Y-%m-%d" | sort -u

# 個人ストリーク
git log origin/<default> --author="<user_name>" --format="%ad" --date=format:"%Y-%m-%d" | sort -u
```

今日から遡って連続コミット日数をカウント。

### Step 12: 履歴読み込み & 比較

```bash
ls -t .context/retros/*.json 2>/dev/null
```

前回の振り返りが存在すれば、Readツールで読み込んでデルタを算出:
```
                    Last        Now         Delta
Test ratio:         22%    →    41%         ↑19pp
Sessions:           10     →    14          ↑4
LOC/hour:           200    →    350         ↑75%
```

初回の場合: 「初回の振り返りを記録 — 来週再実行するとトレンドが見えます。」

### Step 13: 履歴保存

```bash
mkdir -p .context/retros
```

JSONスナップショットを保存:
```json
{
  "date": "2026-03-17",
  "window": "7d",
  "metrics": {
    "commits": 47,
    "contributors": 3,
    "insertions": 3200,
    "deletions": 800,
    "net_loc": 2400,
    "test_loc": 1300,
    "test_ratio": 0.41,
    "active_days": 6,
    "sessions": 14,
    "deep_sessions": 5,
    "avg_session_minutes": 42,
    "loc_per_session_hour": 350,
    "feat_pct": 0.40,
    "fix_pct": 0.30,
    "peak_hour": 22,
    "ai_assisted_commits": 32
  },
  "authors": {
    "name": { "commits": 32, "insertions": 2400, "deletions": 300, "test_ratio": 0.41, "top_area": "src/" }
  },
  "streak_days": 47,
  "tweetable": "Week of Mar 1: 47 commits, 3.2k LOC, 41% tests, peak: 10pm"
}
```

### Step 14: ナラティブ出力

---

**ツイート可能サマリー**（最初の行）:
```
Week of Mar 17: 47 commits (3 contributors), 3.2k LOC, 41% tests, 12 PRs, peak: 10pm | Streak: 47d
```

## Engineering Retro: [date range]

### サマリーテーブル
(Step 3)

### 前回との比較
(Step 12 — 初回はスキップ)

### 時間 & セッションパターン
(Steps 4-5)

### シッピング速度
(Steps 6-8)

### コード品質シグナル
- テストLOC比率トレンド
- ホットスポット分析
- XL PR のフラグ

### フォーカス & ハイライト
(Step 9)

### あなたの1週間（個人ディープダイブ）
(Step 10)

### チームブレークダウン
(Step 10 — ソロリポジトリはスキップ)

### チームの3大Win
(期間中の最高インパクト3件)

### 改善すべき3つ
(具体的、実行可能、コミットに基づく)

### 来週の3つの習慣
(採用に5分もかからない実践的なもの)

---

## Compare モード

`/retro compare` 実行時:
1. 今期のメトリクスを算出
2. 前の同期間のメトリクスを `--since` と `--until` で算出
3. サイドバイサイド比較テーブルとデルタ・矢印を表示
4. 最大の改善と後退をハイライトするナラティブ

## トーン

- 励ましつつ率直。甘やかさない
- 具体的 — 常に実際のコミット/コードに基づく
- 一般的な称賛（「いい仕事！」）は省略 — 何が良かったか・なぜ良かったかを具体的に
- 改善はレベルアップとしてフレーミング、批判ではない
- 合計 2000-4000 words
- データはmarkdownテーブルとコードブロック、解釈はプロース
- 出力は会話に直接 — .context/retros/ JSON のみファイル書き出し
