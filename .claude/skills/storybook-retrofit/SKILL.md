---
name: storybook-retrofit
description: 既存コンポーネントに Storybook story を作成／整備する retrofit ワークフロー。Pre-flight チェックと 8 ステップの手順を提供し、snapshot 判定・story 書き方・Apollo mock の各詳細は関連 skill に委譲する hub skill。
---

# Storybook Retrofit Skill（hub）

## このスキルはいつ使うか

- `src/components/` or `src/features/` 配下のコンポーネントに story を新規作成するとき
- 既存 story に JSDoc / description / Chromatic snapshot 制御が未整備で、best-practices を適用したいとき

`src/components/ui/` 配下（shadcn/ui プリミティブ）は CLAUDE.md の "avoid editing" 指針によりコンポーネント側の JSDoc 追加は避ける。story 追加のみ可。

**セッション反映の注意**：skill ファイルを新規作成した場合、現セッションの `Skill` tool からは invoke できず、次セッションから有効になる。本 skill の指示は直接この SKILL.md を読んで従うことも可能。

## 関連 Skill（分業）

本 skill はハブで、詳細ルールは以下に分離されている。該当セクションの判断が必要になったら呼び出す：

- **`storybook-snapshot-policy`**：どの story を Chromatic snapshot 対象にするかの大原則・判定決定木・`SNAPSHOT-RATIONALE:` 形式・命名規約・機械判定スクリプト
- **`storybook-story-patterns`**：Template 1〜4（showcase / Dialog / Form / Context Wrapper / skill 例外）・共通 Snippets・Container/Presentation 選択・GraphQL fragment shape 取得
- **`storybook-feature-mocking`**：非 lazy `useQuery` / `useSubscription` 依存コンポーネント向けの mock 設計（admin/ は MockedProvider、web/ は MSW、§1/§2 を分けて記述）

## admin/ プロジェクト固有のリソース

admin/ で本 skill を使う場合、以下のリソースに依存する:

- `docs/storybook-playbook.md`：4 skill を合成した admin/ 専用ハンドブック。subagent に prompt 経由で参照させると便利。
- `scripts/verify-story.sh`：Step 6 の 4 検査を一括実行。
- `scripts/check-story-titles.sh`：title 規約検証（CI 組み込み可）。
- `docs/storybook-inventory.md`：未着手 component の対応表（118 件 retrofit プロジェクト時）。
- `src/components/storybook/index.tsx`：`StoryShowcase` / `StoryItem` の薄い共通ヘルパー。

**注意**：admin/ は MSW を使っていない。`.storybook/preview.ts` は `apolloDecorator` + `jotaiDecorator` のみ。Apollo mock は `MockedProvider` を story の `decorators` で wrap する。詳細は `storybook-feature-mocking` §1。

## Pre-flight チェックリスト（Step 1 前に必ず確認）

retrofit 着手前に以下を順番に判定する。判定結果で選ぶ Template が決まる。

1. **Presentation 層を探す（52% のコンポーネントに存在する）**
   - `rg "export const \w+Presentation" <target>/index.tsx` で確認
   - **ある → Presentation で story を作る**（本プロジェクトの既定パターン。hook 依存を完全に迂回でき、props だけで確定的に render できる）
   - **ない → Container で story を作る**（Apollo 依存があれば次項で MSW mock を検討）
   - 詳細は `storybook-story-patterns` の「Container vs Presentation の選択」
2. **Apollo / GraphQL 依存は？（非 lazy `useQuery` / `useMutation` の自動発火）**
   - `useLazyQuery` / `useMutation` のみ → 自動発火しないので無視可、通常 template で story 化
   - 非 lazy `useQuery` / `useSubscription` が内部で発火 → **`storybook-feature-mocking` skill を併用**して MSW handler で mock（preview.tsx に既存の MSW setup あり）
   - MSW mock が現実的でないほど深い依存（複雑な pagination・fetchMore・Quill エディタ統合等） → Template 4（skill 例外）
3. **GraphQL fragment に依存するか？**
   - 依存する → `storybook-story-patterns` の「GraphQL fragment データ取得」で shape を確認
   - しない → mock データ不要
4. **表示サイズ判定**（`storybook-snapshot-policy` 参照）
   - 小型 → Template 1（showcase 集約）
   - 大型（Dialog / Modal / Sheet / Drawer / Page 全て含む）→ Template 2（variant 別 + disableSnapshot）
   - Form 系 → Template 3（useForm + Wrapper）
   - 親 context 必須 → Template 3.5（Context Wrapper）を追加適用
   - 超複雑 orchestrator → Template 4（skill 例外）

### skill 例外を選ぶ前に自問する

skill 例外（Template 4）の snapshot 無効 story は docs カタログ登録のみが目的で、**コンポーネントへの JSDoc 追加だけで docs 価値は代替可能**。

次のどちらかを選ぶ：

- **story を書かず JSDoc のみで完了**（コンポーネント本体の JSDoc は追加、story ファイルは作らない）
- story も書く（Template 4）

story 数が増える保守コストを避けたければ前者が合理的。

## Per-component ワークフロー

### Step 0: TaskCreate 強制化（skip 禁止）

**per-component で以下 3 タスクを必ず TaskCreate で登録してから着手する**。複数コンポーネントを一括処理する場合も省略不可。タスク未登録の着手はこの skill 上 **違反** とみなす。

対象 1 件ごとに：

- `<component-name>: Step 4 JSDoc 追加`
- `<component-name>: Step 5 story 作成`
- `<component-name>: Step 6 lint+test+snapshot 検証`

Step 4 / 5 / 6 は依存関係があるため、**Step 4 を completed にする前に Step 5 に着手しない**。これが一括処理で JSDoc が skip される最大の事故パターン（再発防止案件）。

28 件以上など一括処理する場合は per-step バッチではなくカテゴリ別バッチ（「cards 8 件：4 → 5 → 6」「pickers 6 件：4 → 5 → 6」…）に分割する。**カテゴリ内で Step 4 全件 completed まで Step 5 着手禁止**。

### Step 1: Pre-flight チェック（上述）

Template 1-4 のどれを使うかを決定する。

### Step 2: 現状把握

```bash
TARGET=src/features/<path>
cat $TARGET/index.tsx
[ -f $TARGET/types.ts ] && cat $TARGET/types.ts
[ -f $TARGET/types.tsx ] && cat $TARGET/types.tsx
[ -f $TARGET/index.stories.tsx ] && cat $TARGET/index.stories.tsx
```

**`types.ts` と `types.tsx` の両方を必ずチェック**する。後者を使うプロジェクト慣習があるため、片方だけ cat すると見落とす。

既存 story 一覧と baseline snapshot 数を確認する（`storybook-snapshot-policy` の機械判定スクリプト参照）。

### Step 3: 代表 story の決定

通常 `Default` を代表に採用。`Default` が存在しない／実用上代表でない場合のみ別 story を昇格（理由を commit message に記述）。

### Step 4: コンポーネント JSDoc 追加

**⚠️ 最も skip されやすい step。成果物が story ファイルほど目立たないため、急いでいると丸ごと忘れる。Step 0 で必ずタスク化し、Step 5 着手前に completed にすること。**

`export` 直上に `@summary` 付きブロック、Props type に各フィールド JSDoc 1 行。Container と Presentation 両方に書く。

Retrofit 適用チェックリスト：

**A. コンポーネント側**
1. Export 直上の JSDoc（`@summary` 1 行 60 字以内 + 用途・代替リンク）
2. Props type の各フィールドに JSDoc 1 行
3. Container / Presentation 両方が export されていれば両方に JSDoc

**B. Story meta**
4. `parameters.docs.description.component` にコンポーネント概要
5. `argTypes` — 使い方が非自明な prop のみ `description`
6. `tags: ["autodocs"]` 付与
7. 必須 props のうち `render` で差し替えない分は **すべて meta.args に provide**

**C. 個別 story**
8. `parameters.docs.description.story` に **why**（ユースケース）
9. Snapshot 対象の選定（`storybook-snapshot-policy` の決定木）
10. 既存 story も retrofit 対象（代表以外に `disableSnapshot` を追加）

**D. やらないこと（YAGNI）**
- 既存の `StoryShowcase` / `StoryItem` 構造を壊さない
- Mock データ・decorator の構造変更はしない
- 新規 story を安易に追加しない（rationale なしでは不可）
- `src/components/ui/` の JSDoc 編集は避ける

### Step 5: Story 作成（Template 1-4 から選んで流し込む）

- `storybook-story-patterns` から該当 Template をコピー
- meta.args に **必須 props をすべて provide**（落とし穴 #1）
- GraphQL fragment mock は `storybook-story-patterns` の「GraphQL fragment データ取得」手順で shape を確認
- 命名規約（`storybook-snapshot-policy` の「Story 命名規約」）に従う

### Step 6: 品質ゲート + snapshot カウント検証

**admin/ では `scripts/verify-story.sh` が一括実行**してくれる。手動で順番に走らせるのは web/ または verify-story.sh が無い環境のみ。

#### admin/ パターン: verify-story.sh で一括検証

```bash
cd admin
bash scripts/verify-story.sh <story-file>
# 例: bash scripts/verify-story.sh src/features/account-status-card/index.stories.tsx
```

これが内部で実行する 4 step:
1. `pnpm test` (tsc + vitest)
2. JSDoc gate (`@summary` の有無、ui/ は除外)
3. snapshot count 検証 (`kept == 1 + R`、meta-level disableSnapshot は kept=0 を許容)
4. title 規約チェック (`scripts/check-story-titles.sh` を呼ぶ)

すべて pass で `=== ALL CHECKS PASSED ===` が出る。FAIL なら該当 step を修正してから再実行。

#### 手動パターン (web/ または verify-story.sh が無い環境)

**必ず lint → test → JSDoc grep の順で全部走らせる**（lint は通るが tsc で落ちるケースあり、tsc は通るが JSDoc を忘れるケースあり）：

```bash
# 1. lint（自動 fix + 構文エラー検出）
pnpm lint src/features/<path>/

# 2. tsc + vitest（型エラー検出 ← ここで meta.args 不足等が発覚）
pnpm test

# 3. JSDoc 必須 gate（Step 4 の成果物検証。ui/* は対象外）
MISSING=$(for f in <TARGETS>; do
  [[ "$f" == */ui/* ]] && continue
  grep -L "@summary" "$f"
done)
[ -z "$MISSING" ] || { echo "FAIL: JSDoc missing in:"; echo "$MISSING"; exit 1; }

# 4. snapshot カウント検証
# `storybook-snapshot-policy` の機械判定スクリプト参照
```

JSDoc grep が FAIL した場合は **commit せずに Step 4 に戻る**。story ファイルが完成していても JSDoc 無しなら未完了。

`pnpm build-storybook` は Task 全体の最後に 1 回だけ走らせる（コンポーネント毎に走らせない）。

Template 4（skill 例外）の場合、`kept == 1 + R` は満たさない（kept=0 になる）。この場合はスキップ可。

### Step 7: chrome-devtools MCP によるブラウザ表示検証（推奨）

admin/ では `pnpm storybook` がバックグラウンドで起動済み前提（`lsof -i :6006` で確認）。**親 agent が subagent 完了後に必ず実行する 4 ステップ**:

1. **HMR 待ち 3 秒**（新規 story 追加直後）
   ```bash
   sleep 4
   ```
2. **navigate**: title を kebab-case 化 + 小文字化したパスに移動
   - title `Components/sub-navigation-menu` → URL path `components-sub-navigation-menu--default`
   - title `Pages/calendar/shift-management` → URL path `pages-calendar-shift-management--default`
   ```
   mcp__chrome-devtools__navigate_page url=http://localhost:6006/?path=/story/<kebab>--default
   ```
3. **console error 確認**:
   ```
   mcp__chrome-devtools__list_console_messages types=["error"]
   ```
   - `<no console messages found>` なら OK
   - 404 image/asset エラーは fallback variant の意図的なものなら無視可
   - `atob` JWT decode エラーは BaseLayout 系の既知パターン、UI render 成功なら許容
4. **必要なら take_screenshot で視認確認**（render が崩れていないか）。take_snapshot は出力が大きい（Storybook サイドバー全部 + logo SVG embed）ため通常は省略する。

#### chrome-devtools MCP が無い場合

`take_screenshot` 相当の検証ができないが、`scripts/verify-story.sh` の静的検査で大部分のリグレッションは検出可能。許容して進める。

### Step 8: コミット

**必ず直前に `pnpm test` が緑であることを確認する**。Step 6 の lint → test を通過していない状態で commit すると、type error 入りのコミットが残って amend / fix-up が必要になる。ワンライナーで安全化する：

```bash
pnpm test && git add <path> && git commit -m "..."
```

（`&&` で test 失敗時の commit をブロックする）

PR ベースで運用する場合は `storybook-retrofit/<component-name>` ブランチで作業、commit message に snapshot 削減数（before → after）を含める。

```
Apply storybook best-practices to <component>

Snapshot: kept <before> → <after> (<rationale if needed>)
```

**skill 例外（Template 4）の場合**は snapshot 変化ゼロが自明なので `Snapshot: n/a（skill 例外）` と表記してもよい。無理に `0 → 0` と書く必要はない。

## 大規模 retrofit（118 件）で得た実戦知見

2026-04 に admin/ で 118 件を順次 retrofit した結果、以下が有効だった:

### 1. 「empty mocks で MockedProvider wrap」だけで多くが成立する

複雑な fragment shape を全部 mock する前に、**まず空 mocks で wrap して empty props を渡す**だけでも多くの大型 feature が render 成立する（loading state or empty state）。snapshot は空状態のままでも UI 構造の崩れ検出には有効。

```tsx
decorators: [(Story) => <MockedProvider addTypename={false} mocks={[]}><Story /></MockedProvider>]
```

これで render が成立しないコンポーネントだけ MockedProvider 詳細 mock or Template 4 にエスカレートする。「最小コストで snapshot を取る」が現実解。

### 2. Pre-flight で「skip 候補」を見極める

JSX を含むファイルでも、以下は story を作らずに skip する判断が正しい:

- `data.tsx` のような **columns + mock data export ファイル**（実際に render されるのは sibling 経由）
- `editor-component.tsx` のように **dynamic import で親 story が既にカバー**しているもの
- `components/ui/` 配下（shadcn 準拠で最初から対象外）

skip した理由は inventory に明記する（`Notes` 欄）。

### 3. 検証で許容してよい console error

以下は snapshot 価値を損なわず許容する:

- **404 image/asset**: profile-image など fallback variant の意図的 404
- **`atob` JWT decode エラー**: BaseLayout 系で auth store 初期値が空のため発生。UI render は成功するので可
- **Apollo deprecation warn**: 上流のフレームワーク警告

逆に **`Maximum update depth exceeded` / `Cannot read property of undefined` / 真っ白** は要修正。

### 4. inventory + verify-story.sh + chrome-devtools MCP の三点セットが効く

- **inventory（todo→in-progress→done）**: 進捗管理 + skip rationale 記録
- **verify-story.sh**: 静的検査 4 step を 1 コマンドで
- **chrome-devtools MCP**: render 失敗の最終 gatekeeper（HMR 3 秒待機 → navigate → console error 確認）

これにより 1 component を平均 2-3 分で完了できる（subagent 起動時間込み）。

### 5. 共通ヘルパー欠如時は最小実装を 1 度だけ作る

`@/components/storybook` の `StoryShowcase` / `StoryItem` が無い admin/ では最初の Template 1 案件で薄い実装を作り、以降の 117 件で再利用する。skill が前提とするヘルパーが欠けていたら **スコープを広げて 1 度だけ作る**判断が合理的。

## ワークフロー中によくある落とし穴

（コンポーネント実装側／Template 側の落とし穴は `storybook-story-patterns` を参照）

### 1. commit 前に `pnpm test` を走らせない

Step 6 で lint は通っても tsc で落ちるケースあり（`satisfies Meta` + `render` での meta.args 不足、GraphQL `__typename` 漏れ、enum の value/type 誤用等）。`pnpm test && git commit` のワンライナー必須。

### 2. `types.tsx` vs `types.ts` の揺れ

`types.tsx` を使う component があるため Step 2 で両方 cat する。片方だけ見て Props を把握したつもりになると Step 4 の JSDoc 追加で漏れる。

### 3. `build-storybook` 実行タイミング

コンポーネント毎に走らせると時間コスト高。Task 全体の最後に 1 回だけで十分。CI では別途走る。

### 4. Skill load 遅延

skill を新規作成した直後の session では `Skill` tool から呼べないことがある。次 session で有効になる。現 session では SKILL.md を直接読んで従う運用で対応。

### 5. Step 4 JSDoc の silent skip（再発防止案件）

**実際の事故事例**：28 コンポーネントを一括 retrofit した際、Step 4（コンポーネント JSDoc 追加）を丸ごと skip し、story ファイルだけ作って「完了」と claim した。原因は：

- 一括処理で per-component タスクを TaskCreate しなかった
- Step 4 は成果物が目立たず「実行したつもり」になりやすい
- Step 5（story 作成）は新規ファイルが増えるので可視、Step 4 は既存ファイルへの diff で埋もれる

**防止策**：

- Step 0 の TaskCreate 強制化を守る
- Step 6 の JSDoc grep gate を必ず走らせる
- 一括処理では「カテゴリ内で Step 4 全件 completed まで Step 5 着手禁止」を守る

user への verification コストを上げる skip なので、失敗コストは高い。機械検証で防ぐこと。

## Skill 外の項目

以下は本 skill 群のスコープ外：

- **タグベース snapshot 制御**（`tags: ["snapshot"]` 方式）：`admin/` との統一を伴うため別案件
- **`manifest` タグによる MCP manifest curation**：best-practices.md の応用編、Storybook MCP の成熟を待つ
- **既存 154 stories への一括自動 retrofit**：個別判断が必要なので自動化不可
- **`src/components/ui/` への JSDoc 追加**：CLAUDE.md の avoid editing 指針に従い対象外

## 参照

- Spec: `docs/superpowers/specs/2026-04-16-storybook-retrofit-design.md`
- Plan: `docs/superpowers/plans/2026-04-16-storybook-retrofit.md`
- Storybook best-practices: `docs/best-practices.md`
