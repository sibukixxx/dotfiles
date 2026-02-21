# Remotion AI Prompts & Best Practices

公式リソース: https://www.remotion.dev/prompts

## Remotion Skills のインストール

```bash
npx skills add remotion-dev/skills
```

Claude Code、Codex、Cursor などのAIエージェントで利用可能。

---

## プロンプト・テンプレート

### 新規動画プロジェクト作成

```
Create a new Remotion project for a [動画タイプ] video.
Duration: [秒数] seconds
Resolution: [幅]x[高さ]
Features needed: [必要な機能リスト]
```

### シーン追加

```
Add a new scene to the composition with:
- Duration: [秒数] seconds
- Text: "[表示するテキスト]"
- Animation: [アニメーションタイプ]
- Background: [背景の説明]
```

### エフェクト適用

```
Apply the following effects to [コンポーネント名]:
- Entry animation: [fade/slide/pop/zoom]
- Duration: [秒数]
- Easing: [easing関数]
- Color scheme: [色の指定]
```

---

## アニメーション指定のベストプラクティス

### タイミング指定

```typescript
// フレーム数での指定（推奨）
const startFrame = fps * 2;  // 2秒後に開始
const duration = fps * 3;    // 3秒間

// Sequenceでのシーン管理
<Sequence from={startFrame} durationInFrames={duration}>
  {/* コンテンツ */}
</Sequence>
```

### イージング関数

```typescript
import { Easing, interpolate } from 'remotion';

// 標準イージング
interpolate(frame, [0, 30], [0, 1], { easing: Easing.bezier(0.25, 0.1, 0.25, 1) });

// バウンス
interpolate(frame, [0, 30], [0, 1], { easing: Easing.bounce });

// スプリング（推奨）
spring({ frame, fps, config: { damping: 10, stiffness: 100 } });
```

---

## 音声同期のプロンプト

### ナレーション同期

```
Add narration audio and sync captions:
- Audio file: [ファイルパス]
- Caption style: [スタイル指定]
- Auto-timing: enabled
```

### BGM追加

```
Add background music with:
- Volume: [0-1]
- Fade in: [秒数] seconds
- Fade out: [秒数] seconds
- Duck when narration: true/false
```

---

## 品質チェック用プロンプト

### テキスト校正

```
Check the following text for typos and errors:
[テキスト内容]
Language: Japanese
```

### タイミング検証

```
Verify timing for all text overlays:
- Minimum display time: 2 seconds per line
- Reading speed: 4 characters per second (Japanese)
- No overlapping text
```

---

## 解説系動画のプロンプト

### レイアウト指定

```
Create an educational video layout with:
- Speaker area: bottom-right corner
- Main content: center
- Caption bar: bottom
- Progress indicator: top
- Lower thirds for key points
```

### インサート動画

```
Add insert video/image sequence:
- Duration: [秒数]
- Transition: [fade/cut/slide]
- Position: [center/pip]
- Scale: [スケール]
```

---

## WebGL/3D アニメーション

### ThreeJS シーン

```
Create a 3D scene using @remotion/three:
- Object: [オブジェクトの説明]
- Animation: [アニメーション内容]
- Camera movement: [カメラの動き]
- Lighting: [ライティング設定]
```

### パーティクルエフェクト

```
Add particle effects:
- Type: [stars/confetti/smoke/dust]
- Count: [数]
- Color: [色]
- Movement: [動きのパターン]
```
