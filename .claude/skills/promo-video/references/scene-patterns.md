# Scene Patterns

## Before/After 5シーン構成

15秒動画の標準パターン。

```
┌─────────────────────────────────────────────────────────────────┐
│  共感      │   理解    │  解決策   │   機能    │    CTA     │
│  (4s)      │   (3s)    │   (3s)    │   (3s)    │    (2s)    │
│ 0-120f     │ 120-210f  │ 210-300f  │ 300-390f  │  390-450f  │
└─────────────────────────────────────────────────────────────────┘
```

### シーン実装テンプレート

```tsx
export const MyHero: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = myTheme;

  return (
    <AbsoluteFill>
      {/* 背景 */}
      <GradientBackground colors={[theme.colors.bg, theme.colors.primary]} />
      <Particles type="stars" count={50} color={theme.colors.accent} seed={42} />

      {/* コンテンツ */}
      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', fontFamily }}>

        {/* Scene 1: 共感 (0-4s) */}
        <Sequence durationInFrames={fps * 4}>
          <EmpathyScene theme={theme} />
        </Sequence>

        {/* Scene 2: 理解 (4-7s) */}
        <Sequence from={fps * 4} durationInFrames={fps * 3}>
          <UnderstandingScene theme={theme} />
        </Sequence>

        {/* Scene 3: 解決策 (7-10s) */}
        <Sequence from={fps * 7} durationInFrames={fps * 3}>
          <SolutionScene theme={theme} />
        </Sequence>

        {/* Scene 4: 機能 (10-13s) */}
        <Sequence from={fps * 10} durationInFrames={fps * 3}>
          <FeatureScene theme={theme} />
        </Sequence>

        {/* Scene 5: CTA (13-15s) */}
        <Sequence from={fps * 13} durationInFrames={fps * 2}>
          <CTAScene theme={theme} />
        </Sequence>

      </AbsoluteFill>
    </AbsoluteFill>
  );
};
```

---

## シーン別パターン

### Scene 1: 共感シーン

ターゲットの悩みを言語化。2行構成が効果的。

```tsx
const EmpathyScene: React.FC<{ theme: Theme }> = ({ theme }) => (
  <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 20 }}>
    <TextReveal
      text="眠れない夜が"
      fontSize={56}
      color={theme.colors.text}
      effect="fade"
    />
    <TextReveal
      text="続いていませんか"
      fontSize={56}
      color={theme.colors.text}
      effect="fade"
      delay={0.5}
    />
  </AbsoluteFill>
);
```

**コピー例:**
- 「〇〇で困っていませんか」
- 「〇〇したくありませんか」
- 「〇〇、不安ですよね」

### Scene 2: 理解シーン

悩みの背景に共感。「でも...」で次へ繋ぐ。

```tsx
const UnderstandingScene: React.FC<{ theme: Theme }> = ({ theme }) => (
  <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
    <TextReveal
      text="原因は分かっている"
      fontSize={48}
      color={theme.colors.textDim}
      effect="fade"
    />
    <TextReveal
      text="でも..."
      fontSize={48}
      color={theme.colors.textDim}
      effect="fade"
      delay={0.8}
    />
  </AbsoluteFill>
);
```

### Scene 3: 解決策シーン

プレッシャーなしの提案。アニメーション要素を追加。

```tsx
const SolutionScene: React.FC<{ theme: Theme }> = ({ theme }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      <CustomAnimation frame={frame} fps={fps} />
      <TextReveal
        text="禁酒を強制しません"
        fontSize={52}
        color={theme.colors.accent}
        effect="fade"
        delay={0.3}
      />
    </AbsoluteFill>
  );
};
```

### Scene 4: 機能シーン

具体的な使い方を説明。

```tsx
const FeatureScene: React.FC<{ theme: Theme }> = ({ theme }) => (
  <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
    <TextReveal text="ただ記録して" fontSize={48} color={theme.colors.text} effect="fade" />
    <TextReveal text="振り返るだけ" fontSize={48} color={theme.colors.text} effect="fade" delay={0.5} />
  </AbsoluteFill>
);
```

### Scene 5: CTAシーン

サービス名 + キャッチ + ボタン。

```tsx
const CTAScene: React.FC<{ theme: Theme }> = ({ theme }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 24 }}>
      <TextReveal
        text="睡眠記録"
        fontSize={64}
        color={theme.colors.text}
        fontWeight={700}
        effect="pop"
      />
      <TextReveal
        text="ひとりじゃない"
        fontSize={28}
        color={theme.colors.textDim}
        effect="fade"
        delay={0.3}
      />
      <CTAButton frame={frame} fps={fps} />
    </AbsoluteFill>
  );
};
```

---

## カスタムアニメーションコンポーネント

### CTAボタン

```tsx
const CTAButton: React.FC<{ frame: number; fps: number }> = ({ frame }) => {
  const scale = interpolate(frame, [10, 20], [0, 1], { extrapolateRight: 'clamp' });
  const pulse = Math.sin(frame * 0.15) * 0.05 + 1;

  return (
    <div style={{
      padding: '16px 48px',
      background: '#ffffff',
      borderRadius: 50,
      fontSize: 24,
      fontWeight: 700,
      color: '#ec4899',
      transform: `scale(${scale * pulse})`,
      boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
    }}>
      無料で始める →
    </div>
  );
};
```

### 呼吸円アニメーション

```tsx
const BreathingCircle: React.FC<{ frame: number }> = ({ frame }) => {
  const breathe = Math.sin(frame * 0.05) * 0.3 + 1;
  const opacity = interpolate(frame, [0, 20], [0, 0.3], { extrapolateRight: 'clamp' });

  return (
    <div style={{
      width: 150,
      height: 150,
      borderRadius: '50%',
      border: '2px solid rgba(147,197,253,0.5)',
      transform: `scale(${breathe})`,
      opacity,
    }} />
  );
};
```

### スキャンラインアニメーション

```tsx
const ScanLine: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const y = interpolate(frame, [0, fps * 2], [0, 100], { extrapolateRight: 'clamp' });

  return (
    <div style={{
      position: 'absolute',
      top: `${y}%`,
      left: 0,
      right: 0,
      height: 3,
      background: 'linear-gradient(90deg, transparent, #ec4899, transparent)',
      boxShadow: '0 0 20px #ec4899',
    }} />
  );
};
```

---

## テーマ別背景パターン

### 夜空（睡眠系）
```tsx
<GradientBackground colors={['#0f172a', '#1e3a5f', '#0c1929']} direction="to-bottom" />
<Particles type="stars" count={80} color="#93c5fd" seed={123} />
```

### 美容・化粧品
```tsx
<GradientBackground colors={['#2d1b4e', '#ec4899', '#f472b6']} direction="to-bottom-right" animate />
<Particles type="bubbles" count={30} color="#f472b6" seed={42} />
```

### 自然・和（お茶など）
```tsx
<GradientBackground colors={['#1a2f1a', '#2d4a2d', '#1f3d1f']} direction="to-bottom" />
<Particles type="fog" count={20} color="#a7d4a7" seed={88} />
```
