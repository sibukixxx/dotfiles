---
name: storybook-snapshot-policy
description: Storybook story のうちどれを Chromatic snapshot 対象にすべきかを決める skill。従量課金下で snapshot 数を最小化するための大原則・判定決定木・命名規約・機械判定スクリプトを提供する。新規 story 作成時にも既存 story 整理時にも単独で呼べる。
---

# Storybook Snapshot Policy Skill

## このスキルはいつ使うか

- 新しく追加した story に `chromatic.disableSnapshot` を付けるかどうか迷ったとき
- 既存の story 群から snapshot 数を削減したいとき
- 複数 variant を持つコンポーネントを showcase に集約すべきか、variant 別 story として残すか判断したいとき

Story の書き方自体は `storybook-story-patterns` を、retrofit 全体のワークフローは `storybook-retrofit` を参照する。

## 大原則：Snapshot 最小化を最優先

Chromatic は従量課金。snapshot を増やす設計は罪。

- **1 コンポーネント = 1 snapshot が既定値**
- 代表 1 story（通常 `Default`）のみ snapshot 対象、残りは全て `parameters.chromatic.disableSnapshot: true`
- 追加 snapshot を残したい場合は **`SNAPSHOT-RATIONALE:` コメントによる正当化が必須**
- 新規 story variant を安易に増やさない。既存で済むなら追加しない
- Retrofit の結果として snapshot 総数は減る方向にしか動かない

既存プロジェクト規約は opt-out 方式（`parameters.chromatic.disableSnapshot: true` を個別 story に付与）。`admin/` が先行実装しており、`web/` も同方式で揃える。

## Snapshot 判定決定木

### 事前判断：表示領域が小さいコンポーネントか？

**判断基準は「描画されたときの画面上のサイズ」。ソースコードの行数・props 数・実装の複雑さではない。**

例：

- **小型（集約推奨）**：アイコン、ボタン、バッジ、チップ、アバター、ラベル、スピナー、タグ、小型フォーム入力（input 単体・checkbox 等）、**ドロップダウンリストメニュー**（メニュー本体は幅 200〜300px 程度で並べても収まる）
- **大型（variant 別推奨）**：ダイアログ、モーダル、AlertDialog、Sheet、Drawer、全画面サイドシート、ページ、大型フォーム全体、データテーブル、カレンダー、エディタ、ヘッダー検索のような幅広ポップオーバー

実装が 500 行あっても描画されるのがアイコン 1 個なら「小型」。実装が 50 行でも画面全体を占有するなら「大型」。同じ「ドロップダウン」でも、リストメニューのような小さな overlay は「小型」扱い、幅広タブ付きのものは「大型」扱い。`index.tsx` や stories の行数は判定に無関係。

迷ったら **Storybook 上で variant を横並びに並べたときに 1 画面（例：1920×1080）に収まり、視覚的に不自然にならないか** で判断する。

**Dialog / AlertDialog / Sheet / Drawer / Modal 系はすべて大型に分類**（モーダルオーバーレイで画面全体を占有するため）。

### 方針

- **小型 × variant 複数** → variant 別 story を作らず、**1 つの `Default` showcase に集約**（`storybook-story-patterns` の Template 1）
- **大型 × variant 複数** → variant 別 story + **代表以外は `disableSnapshot`**（同 Template 2）
- **どちらもデータが揃わずレンダリング不完全** → **全 story で snapshot 無効**の skill 例外扱い（同 Template 4）

### 個別 story の判定

showcase 集約で済まない場合、story ごとに以下を順番に判定：

1. `Default`（または代表指定）story か？ → **snapshot 残す**（`disableSnapshot` なし）
2. Showcase / matrix / variant 羅列 story か？ → **`disableSnapshot: true`**（rationale 不要）
3. `Loading` / `Error` / `Empty` 等の状態 story か？ → デフォルト **`disableSnapshot: true`**
4. 上記 3 で snapshot を残したい場合のみ、**コミット時点で再現可能な regression リスク** を rationale に記述
5. Rationale 判定者：**PR レビュアー**

## `SNAPSHOT-RATIONALE:` コメント形式

- 配置：story 宣言の直前行（`export const` の上）
- 形式：`// SNAPSHOT-RATIONALE: <理由>`
- 理由は 1 行 120 字以内、過去の regression 事例参照（Sentry issue / PR 番号）があれば記載
- 自動検査 grep パターン：`^\s*// SNAPSHOT-RATIONALE:`
- **disableSnapshot を付ける story には書かない**（snapshot を「残す理由」のコメントであって「無効化する理由」ではない）

例：

```tsx
// SNAPSHOT-RATIONALE: 全拡張子アイコンのレンダリング崩れを一括検出するため matrix を残す
export const AllExtensions: Story = { ... }
```

## Story 命名規約

状態別 variant story の命名は以下で統一する（命名一貫性により docs / grep が容易になる）：

| 目的 | 命名 |
|---|---|
| 代表 | `Default` |
| 読込中 | `Loading` |
| エラー | `Error` |
| 空状態 | `Empty` |
| 無効化 | `Disabled` |
| 選択済み | `Selected` |
| ホバー | `Hover`（通常 play function 必要、snapshot 対象外） |
| 特定入力値 | `With<Value>`（例: `WithError`, `WithCustomTitle`） |
| サイズ違い | `Size<Value>`（例: `SizeSmall`、`SizeLarge`） |

複合状態は `<State1>And<State2>`（例: `DisabledAndSelected`、`LoadingWithError`）。

`Default` が使えないケース（`Default` が無かった既存コード、複数の "代表" 候補がある等）では一番頻度の高いユースケースに近い名前を代表に昇格させ、commit message に理由を書く（例: `DesktopMessagesTab` を代表に昇格）。

## 機械判定スクリプト

story ファイルに対する snapshot 数の検証：

```bash
FILE=src/components/<name>/index.stories.tsx
N=$(rg -c 'export const \w+\s*:\s*Story' "$FILE"); N=${N:-0}
D=$(rg -c 'disableSnapshot:\s*true' "$FILE" 2>/dev/null); D=${D:-0}
R=$(rg -c '^\s*// SNAPSHOT-RATIONALE:' "$FILE" 2>/dev/null); R=${R:-0}
echo "N=$N D=$D R=$R kept=$((N-D)) expected=$((1+R))"
test $((N-D)) -eq $((1+R)) && echo "snapshot OK" || { echo "snapshot FAIL"; exit 1; }
```

判定式：**`kept (N-D) == 1 + R`**

- N: 総 story 数
- D: `disableSnapshot: true` 付与数
- R: `SNAPSHOT-RATIONALE:` コメント数（追加 snapshot の正当化）
- kept: snapshot 対象の story 数
- expected: 代表 1 件 + rationale 付き追加分

skill 例外（全 disableSnapshot、Template 4）の場合は `kept == 0` になるためこの不等式は満たさない。例外扱いは上記スクリプトの判定から除外する。

## Skill 例外を選ぶ前に自問する

skill 例外（全 disableSnapshot）の snapshot 無効 story は docs カタログ登録のみが目的で、**コンポーネントへの JSDoc 追加だけで docs 価値は代替可能**。

次のどちらかを選ぶ：

- **story を書かず JSDoc のみで完了**（コンポーネント本体の JSDoc は追加、story ファイルは作らない）
- story も書く（Template 4）

story 数が増える保守コストを避けたければ前者が合理的。「docs タブで型が見えるだけ」に満足するなら後者。PR レビュアーと方針を合わせる。

## 関連 Skill

- `storybook-retrofit`：retrofit の全体ワークフロー
- `storybook-story-patterns`：story ファイルの書き方・Template 集
- `storybook-feature-mocking`：Apollo/MSW mock レシピ
