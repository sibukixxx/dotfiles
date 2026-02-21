# Effects API Reference

## GradientBackground

背景にグラデーションを描画。

```tsx
interface GradientBackgroundProps {
  colors: string[];           // グラデーション色の配列
  direction?: 'to-bottom' | 'to-right' | 'to-bottom-right' | 'radial';
  animate?: boolean;          // アニメーション有効化
  children?: React.ReactNode;
}
```

**使用例:**

```tsx
// 静的グラデーション
<GradientBackground
  colors={['#0f172a', '#1e3a5f', '#0c1929']}
  direction="to-bottom"
/>

// アニメーション付き
<GradientBackground
  colors={['#2d1b4e', '#ec4899', '#f472b6']}
  direction="to-bottom-right"
  animate
/>
```

---

## Particles

パーティクルエフェクト。

```tsx
interface ParticlesProps {
  type: 'stars' | 'bubbles' | 'fog' | 'leaves';
  count?: number;    // デフォルト: 50
  color?: string;    // デフォルト: '#ffffff'
  seed?: number;     // ランダムシード (再現性のため)
}
```

**タイプ別の特徴:**

| Type | 特徴 | 適したテーマ |
|------|------|-------------|
| stars | キラキラ光る星 | 夜、睡眠、夢 |
| bubbles | 上昇する泡 | 美容、化粧品、水 |
| fog | 漂う霧 | ミステリアス、落ち着き |
| leaves | 落ちる葉 | 自然、お茶、和 |

**使用例:**

```tsx
<Particles type="stars" count={80} color="#93c5fd" seed={123} />
<Particles type="bubbles" count={30} color="#f472b6" seed={42} />
```

---

## TextReveal

テキスト表示アニメーション。

```tsx
interface TextRevealProps {
  text: string;
  delay?: number;           // 遅延（秒）デフォルト: 0
  fontSize?: number;        // デフォルト: 48
  color?: string;           // デフォルト: '#ffffff'
  fontFamily?: string;
  fontWeight?: number;      // デフォルト: 700
  style?: React.CSSProperties;
  effect?: 'fade' | 'slide' | 'pop' | 'typewriter';
}
```

**エフェクト別の特徴:**

| Effect | 動作 | 適した場面 |
|--------|------|-----------|
| fade | フェードイン + 上昇 | 通常のテキスト表示 |
| slide | 左からスライドイン | 動きのあるシーン |
| pop | バウンス付きスケール | 強調、インパクト |
| typewriter | 1文字ずつ表示 | 説明、ストーリー |

**使用例:**

```tsx
<TextReveal
  text="眠れない夜が"
  fontSize={56}
  color="#e2e8f0"
  effect="fade"
  style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)' }}
/>

<TextReveal
  text="続いていませんか"
  fontSize={56}
  color="#e2e8f0"
  effect="fade"
  delay={0.5}  // 0.5秒遅れて表示
/>
```

---

## FadeIn

子要素をフェードイン。

```tsx
interface FadeInProps {
  children: React.ReactNode;
  delay?: number;      // 遅延（秒）
  duration?: number;   // アニメーション時間（秒）
}
```

**使用例:**

```tsx
<FadeIn delay={0.3} duration={0.5}>
  <div>フェードインするコンテンツ</div>
</FadeIn>
```

---

## Remotion Core Utilities

よく使うRemotionのユーティリティ:

```tsx
import {
  useCurrentFrame,    // 現在のフレーム番号
  useVideoConfig,     // { fps, width, height, durationInFrames }
  interpolate,        // 値の補間
  spring,             // スプリングアニメーション
  Sequence,           // シーケンス（シーン管理）
  AbsoluteFill,       // 画面全体を覆うコンテナ
} from 'remotion';

// 補間の例
const opacity = interpolate(frame, [0, 30], [0, 1], {
  extrapolateRight: 'clamp',
});

// スプリングの例
const scale = spring({
  frame,
  fps,
  config: { damping: 10, stiffness: 100 },
});
```
