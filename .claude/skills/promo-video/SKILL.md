---
name: promo-video
description: Create TikTok/short-form promo videos for LP sites using Remotion. Generates 20-30 second Before/After style videos with theme, composition, effects, BGM, and captions. Supports advanced features like speaker identification, auto-timing captions, WebGL/ThreeJS animations, and AI-powered content generation. Triggers on "promo video", "TikTok video", "create video for LP", "promotional video", "short video", "SNS video".
---

# Promo Video

LP(ランディングページ)のショート動画をRemotionで生成する。

## 台本構造

| 要素 | 説明 |
|------|------|
| **HOOK** | 冒頭3秒。否定 or 驚きで視聴者を止める |
| **SHOT** | 映像指示。顔出し不要の素材指定 |
| **LINE** | セリフ/テロップ |
| **CTA** | 行動導線。次のアクションを促す |

詳細: [script-template.md](references/script-template.md)

## 動画仕様

- **長さ**: 20〜30秒（固定）
- **冒頭**: 3秒で否定 or 驚き（HOOK）
- **顔出し**: 不要
- **解像度**: 1080x1920（縦型）or 1920x1080（横型）

---

## Workflow

### Basic Flow

```
1. LP分析 → 2. 台本作成 → 3. テーマ作成 → 4. コンポジション生成 → 5. レンダリング
```

### Advanced Flow

```
1. 台本作成 → 2. 画像生成 → 3. 動画生成 → 4. 音声生成 → 5. 動画編集
```

詳細: [advanced-workflow.md](references/advanced-workflow.md)

---

## Step 1: LP分析

```typescript
interface LPInfo {
  name: string;
  serviceName: string;
  targetAudience: string;
  mainProblem: string;
  solution: string;
  keyFeature: string;
  cta: string;
  colors: { primary: string; secondary: string; accent: string; };
}
```

## Step 2: 台本作成

### タイムライン構成（25秒版）

| セクション | 時間 | 目的 |
|-----------|------|------|
| HOOK | 0-3s | 視聴停止させる（否定/驚き） |
| PROBLEM | 3-8s | 共感・問題提起 |
| SOLUTION | 8-15s | 解決策の提示 |
| BENEFIT | 15-22s | メリット・証拠 |
| CTA | 22-25s | 行動導線 |

### HOOKパターン

**否定型:**
```
❌ まだ〇〇してるの？
❌ 〇〇は時代遅れ
❌ これ知らないとヤバい
```

**驚き型:**
```
😱 実は〇〇の9割が間違ってる
😱 たった3秒で〇〇できる方法
😱 知らないと損する〇〇
```

### SHOT指示（顔出し不要）

| type | 用途 |
|------|------|
| text | テキスト中心（グラデーション背景） |
| screen | アプリ/サービスの画面キャプチャ |
| product | 商品画像（回転/ズーム） |
| graph | Before/After 比較グラフ |
| animation | アイコン/フローチャート |

## Step 3-5: テーマ・コンポジション・レンダリング

テンプレート: [assets/](assets/)
エフェクト: [effects-api.md](references/effects-api.md)
シーン構成: [scene-patterns.md](references/scene-patterns.md)

```bash
cd apps/promo-video && npx remotion render <CompositionId> out/<name>.mp4
```

---

## Advanced Features

### BGM & 効果音

```tsx
import { Audio, staticFile } from 'remotion';
<Audio src={staticFile('bgm/upbeat.mp3')} volume={0.3} />
```

### 話者識別 & テロップ色変更

```typescript
const speakers = [
  { id: 'host', color: '#3b82f6' },
  { id: 'guest', color: '#ec4899' },
];
```

### WebGL/ThreeJS アニメーション

```tsx
import { ThreeCanvas } from '@remotion/three';
```

### Effects Hub

Character FX: `Pop`, `Slide`, `Shake`, `Zoom`, `Blur`, `Glitch`, `Bounce`, `Neon`, `Glow`
Screen FX: `Flash`, `Bloom`, `DustCloud`, `HardKick`, `HoneyGlow`

---

## Quick Reference

### Video Specs
- Duration: 20-30 seconds (600-900 frames at 30fps)
- Resolution: 1080x1920 (vertical) or 1920x1080 (horizontal)
- HOOK: First 3 seconds (denial or surprise)
- No face required

### Scene Timing (25秒版 at 30fps)

| Section | Start | Duration |
|---------|-------|----------|
| HOOK | 0 | 90f (3s) |
| PROBLEM | 90 | 150f (5s) |
| SOLUTION | 240 | 210f (7s) |
| BENEFIT | 450 | 210f (7s) |
| CTA | 660 | 90f (3s) |

### Remotion Skills

```bash
npx skills add remotion-dev/skills
```

詳細: [remotion-prompts.md](references/remotion-prompts.md)
