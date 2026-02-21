# ショート動画 台本テンプレート

## 基本構造

| 要素 | 説明 |
|------|------|
| **HOOK** | 冒頭3秒。否定 or 驚きで視聴者を止める |
| **SHOT** | 映像指示。顔出し不要の素材指定 |
| **LINE** | セリフ/テロップ |
| **CTA** | 行動導線。次のアクションを促す |

---

## 動画仕様

- **長さ**: 20〜30秒（固定）
- **冒頭**: 3秒で否定 or 驚き（HOOK）
- **顔出し**: 不要
- **フレームレート**: 30fps
- **解像度**: 1080x1920（縦型）or 1920x1080（横型）

---

## タイムライン構成（25秒版）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  HOOK     │   PROBLEM   │   SOLUTION   │   BENEFIT   │   CTA     │
│  (0-3s)   │   (3-8s)    │   (8-15s)    │   (15-22s)  │  (22-25s) │
└─────────────────────────────────────────────────────────────────────────────┘
```

| セクション | 時間 | 目的 | フレーム数(30fps) |
|-----------|------|------|------------------|
| HOOK | 0-3s | 視聴停止させる | 0-90 |
| PROBLEM | 3-8s | 共感・問題提起 | 90-240 |
| SOLUTION | 8-15s | 解決策の提示 | 240-450 |
| BENEFIT | 15-22s | メリット・証拠 | 450-660 |
| CTA | 22-25s | 行動導線 | 660-750 |

---

## 台本フォーマット

```typescript
interface Script {
  title: string;
  duration: 20 | 25 | 30;  // 秒
  scenes: Scene[];
}

interface Scene {
  id: string;
  section: 'HOOK' | 'PROBLEM' | 'SOLUTION' | 'BENEFIT' | 'CTA';
  startTime: number;  // 秒
  endTime: number;
  SHOT: ShotInstruction;
  LINE: LineContent;
  CTA?: CTAContent;
}

interface ShotInstruction {
  type: 'text' | 'image' | 'screen' | 'product' | 'animation' | 'graph';
  description: string;
  effect?: string;       // エフェクト指定
  transition?: string;   // トランジション
}

interface LineContent {
  text: string;          // テロップ/ナレーション
  style?: 'normal' | 'emphasis' | 'warning' | 'question';
  position?: 'center' | 'top' | 'bottom';
  animation?: string;
}

interface CTAContent {
  action: string;        // "プロフィールをチェック" など
  url?: string;
  button?: string;
}
```

---

## HOOKパターン（冒頭3秒）

### 否定型 HOOK

視聴者の常識を否定して興味を引く。

```
❌ まだ〇〇してるの？
❌ 〇〇は時代遅れ
❌ 〇〇だと思ってない？実は違う
❌ 〇〇するのはやめて
❌ これ知らないとヤバい
```

**例:**
```yaml
HOOK:
  SHOT:
    type: text
    description: "大きな×マーク + テキスト"
    effect: shake
  LINE:
    text: "まだ手作業で確認してるの？"
    style: warning
    animation: pop
```

### 驚き型 HOOK

意外な事実や数字で驚かせる。

```
😱 実は〇〇の9割が間違ってる
😱 〇〇するだけで△△になった
😱 知らないと損する〇〇
😱 たった3秒で〇〇できる方法
😱 〇〇業界の人は絶対言わない真実
```

**例:**
```yaml
HOOK:
  SHOT:
    type: text
    description: "衝撃の数字 + 背景エフェクト"
    effect: flash
  LINE:
    text: "輸入コストの計算、9割が間違えてる"
    style: emphasis
    animation: zoom
```

---

## SHOT指示（顔出し不要パターン）

### テキスト中心

```yaml
SHOT:
  type: text
  description: |
    背景: グラデーション（ブランドカラー）
    メイン: 大きなテキスト（センター配置）
    装飾: パーティクル/アイコン
  effect: fade
```

### 画面キャプチャ

```yaml
SHOT:
  type: screen
  description: |
    アプリ/サービスの実際の画面
    ハイライト: 操作箇所を囲む
    矢印/ポインタでガイド
  effect: zoom
```

### プロダクト

```yaml
SHOT:
  type: product
  description: |
    商品画像（白背景 or ブランド背景）
    360度回転 or ズームイン
    特徴部分にテキストオーバーレイ
  effect: rotate
```

### グラフ/データ

```yaml
SHOT:
  type: graph
  description: |
    Before/After 比較グラフ
    数字がカウントアップ
    改善率をハイライト
  effect: countup
```

### アニメーション

```yaml
SHOT:
  type: animation
  description: |
    アイコンアニメーション
    フローチャート（ステップ表示）
    抽象的なモーショングラフィックス
  effect: sequence
```

---

## CTAパターン

### プロフィール誘導

```yaml
CTA:
  action: "プロフィールをチェック"
  LINE:
    text: "詳しくはプロフィールから"
    animation: pulse
  SHOT:
    type: text
    description: "矢印 + プロフィールアイコン"
```

### リンク誘導

```yaml
CTA:
  action: "リンクから無料で試す"
  LINE:
    text: "今なら無料で使える → リンクから"
    animation: bounce
  SHOT:
    type: text
    description: "ボタン風デザイン + 矢印"
```

### フォロー誘導

```yaml
CTA:
  action: "フォローして続きを見る"
  LINE:
    text: "続きはフォローして待っててね"
    animation: fade
  SHOT:
    type: text
    description: "フォローボタン風 + ハートアイコン"
```

---

## 台本サンプル（25秒版）

### 例: 輸入コスト計算サービス

```yaml
title: "輸入コスト計算の落とし穴"
duration: 25

scenes:
  - id: hook
    section: HOOK
    startTime: 0
    endTime: 3
    SHOT:
      type: text
      description: "大きな×マーク → 数字「9割」がズームイン"
      effect: shake
    LINE:
      text: "輸入コストの計算、9割が間違えてる"
      style: warning
      animation: pop

  - id: problem
    section: PROBLEM
    startTime: 3
    endTime: 8
    SHOT:
      type: animation
      description: "電卓アイコン → 複数の隠れコストが出現"
      effect: sequence
    LINE:
      text: "関税だけじゃない。送料、保険、通関費用..."
      style: normal
      animation: fade

  - id: solution
    section: SOLUTION
    startTime: 8
    endTime: 15
    SHOT:
      type: screen
      description: "サービス画面。数字を入力 → 結果表示"
      effect: zoom
    LINE:
      text: "商品URLを入れるだけ。全部まとめて計算"
      style: emphasis
      animation: slide

  - id: benefit
    section: BENEFIT
    startTime: 15
    endTime: 22
    SHOT:
      type: graph
      description: "Before: 赤字 → After: 黒字 の比較グラフ"
      effect: countup
    LINE:
      text: "発注前に利益が分かる。赤字仕入れゼロに"
      style: emphasis
      animation: fade

  - id: cta
    section: CTA
    startTime: 22
    endTime: 25
    SHOT:
      type: text
      description: "サービス名 + ボタン風デザイン + 矢印"
      effect: pulse
    LINE:
      text: "無料で使える → プロフィールから"
      style: normal
      animation: bounce
    CTA:
      action: "プロフィールをチェック"
```

---

## Remotion実装マッピング

| 台本要素 | Remotion実装 |
|---------|-------------|
| HOOK.effect: shake | `<TextReveal effect="pop">` + CSS shake |
| SHOT.type: text | `<GradientBackground>` + `<TextReveal>` |
| SHOT.type: screen | `<Img>` + `<Sequence>` zoom animation |
| SHOT.type: graph | カスタム `<Graph>` コンポーネント |
| LINE.animation | `<TextReveal effect={...}>` |
| CTA | `<CTAButton>` + pulse animation |

```tsx
// 台本からコンポーネントへの変換例
const sceneToComponent = (scene: Scene) => {
  const { SHOT, LINE, startTime, endTime } = scene;
  const durationInFrames = (endTime - startTime) * fps;

  return (
    <Sequence from={startTime * fps} durationInFrames={durationInFrames}>
      {SHOT.type === 'text' && (
        <GradientBackground colors={theme.colors}>
          <TextReveal
            text={LINE.text}
            effect={LINE.animation || 'fade'}
            fontSize={LINE.style === 'emphasis' ? 64 : 48}
          />
        </GradientBackground>
      )}
    </Sequence>
  );
};
```
