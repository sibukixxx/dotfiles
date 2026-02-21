# Advanced Video Production Workflow

## 完全な動画制作フロー

```
台本作成 → 画像生成 → 動画生成 → 音声生成 → 動画編集
```

### Phase 1: 台本作成

```typescript
interface Script {
  title: string;
  duration: number;  // seconds
  scenes: ScriptScene[];
}

interface ScriptScene {
  id: string;
  startTime: number;
  endTime: number;
  narration: string;      // ナレーション
  onScreenText: string;   // テロップ
  visualDescription: string; // 画像生成プロンプト
  speakerId?: string;     // 話者識別
  effects: string[];      // エフェクト指定
}
```

### Phase 2: 画像生成 (AI)

画像生成プロンプトのベストプラクティス:

```typescript
// 画像生成設定
interface ImageGenConfig {
  style: 'anime' | 'realistic' | 'illustration' | 'minimal';
  aspectRatio: '16:9' | '9:16' | '1:1';
  quality: 'standard' | 'hd';
}

// プロンプト構造
const imagePrompt = `
${scene.visualDescription}
Style: ${config.style}
Composition: centered, clean background
Lighting: soft, professional
`;
```

### Phase 3: 動画生成 (Remotion)

Remotion公式スキルのインストール:

```bash
npx skills add remotion-dev/skills
```

### Phase 4: 音声生成 (ElevenLabs)

```typescript
import { ElevenLabsClient } from 'elevenlabs';

const client = new ElevenLabsClient({ apiKey: process.env.ELEVENLABS_API_KEY });

async function generateNarration(text: string, voiceId: string): Promise<Buffer> {
  const audio = await client.generate({
    voice: voiceId,
    text,
    model_id: 'eleven_multilingual_v2',
  });
  return audio;
}
```

### Phase 5: 動画編集 (BGM & SFX)

BGM/SFXの追加:

```tsx
import { Audio, staticFile } from 'remotion';

<Audio src={staticFile('bgm/upbeat.mp3')} volume={0.3} />
<Audio src={staticFile('sfx/whoosh.mp3')} startFrom={fps * 2} volume={0.8} />
```

---

## Live-Director アーキテクチャ

リアルタイム編集可能なスタジオパネル。

### State Lifting Pattern

```tsx
// MainComposition.tsx
export const MainComposition: React.FC<{ initialLyrics: Lyric[] }> = ({ initialLyrics }) => {
  const [lyrics, setLyrics] = useState(initialLyrics);

  const handleLyricsChange = useCallback((updated: Lyric[]) => {
    setLyrics(updated);
  }, []);

  return (
    <>
      <MVRenderer lyrics={lyrics} />
      <LiveDirectorPanel lyrics={lyrics} onChange={handleLyricsChange} />
    </>
  );
};
```

### Live-Director Panel

```tsx
// VisualEditorOverlay.tsx
interface LiveDirectorProps {
  lyrics: Lyric[];
  onChange: (lyrics: Lyric[]) => void;
}

export const LiveDirectorPanel: React.FC<LiveDirectorProps> = ({ lyrics, onChange }) => {
  const updateLyric = (index: number, updates: Partial<Lyric>) => {
    const newLyrics = [...lyrics];
    newLyrics[index] = { ...newLyrics[index], ...updates };
    onChange(newLyrics);
  };

  return (
    <div className="live-director-panel">
      {lyrics.map((lyric, i) => (
        <LyricEditor
          key={lyric.id}
          lyric={lyric}
          onTextChange={(text) => updateLyric(i, { text })}
          onStartChange={(start) => updateLyric(i, { start })}
          onEndChange={(end) => updateLyric(i, { duration: end - lyric.start })}
          onEffectChange={(effect) => updateLyric(i, { effect })}
        />
      ))}
    </div>
  );
};
```

---

## Effects Hub

### 標準エフェクトセット

**Character FX (文字エフェクト):**
- `Pop` - バウンス付きスケールイン
- `Slide` - 左/右からスライドイン
- `Shake` - 振動エフェクト
- `Zoom` - ズームイン/アウト
- `Blur` - ブラーからフォーカス
- `Glitch` - グリッチエフェクト
- `Bounce` - 弾むアニメーション
- `Neon` - ネオン発光
- `Glow` - 柔らかい発光

**Screen FX (画面エフェクト):**
- `Flash` - 画面フラッシュ
- `Bloom` - ブルームエフェクト
- `DustCloud` - 塵のパーティクル
- `HardKick` - 画面シェイク
- `HoneyGlow` - 暖かい発光

### HyperKineticText (インライン実装)

```tsx
// 環境を選ばず動作するインライン実装
const HyperKineticText: React.FC<{ text: string; effect: string }> = ({ text, effect }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const getAnimation = () => {
    switch (effect) {
      case 'Pop':
        return spring({ frame, fps, config: { damping: 10, stiffness: 100 } });
      case 'Slide':
        return interpolate(frame, [0, 15], [-100, 0], { extrapolateRight: 'clamp' });
      case 'Shake':
        return Math.sin(frame * 0.5) * 5;
      case 'Glitch':
        return Math.random() > 0.9 ? Math.random() * 10 - 5 : 0;
      default:
        return 1;
    }
  };

  // ... render with animation
};
```

---

## 話者識別 & テロップ

### 話者設定

```typescript
interface Speaker {
  id: string;
  name: string;
  color: string;      // テロップ色
  voiceId: string;    // ElevenLabs voice ID
}

const speakers: Speaker[] = [
  { id: 'host', name: 'ホスト', color: '#3b82f6', voiceId: 'xxx' },
  { id: 'guest', name: 'ゲスト', color: '#ec4899', voiceId: 'yyy' },
];
```

### テロップ自動調整

```typescript
// 文字数に基づく表示時間計算
const calculateDuration = (text: string, wordsPerSecond = 4): number => {
  const words = text.length / 2; // 日本語は2文字≒1ワード
  return Math.max(2, Math.ceil(words / wordsPerSecond));
};

// タイミング自動調整
const autoAdjustTimings = (scenes: ScriptScene[]): ScriptScene[] => {
  let currentTime = 0;
  return scenes.map(scene => {
    const duration = calculateDuration(scene.onScreenText);
    const adjusted = {
      ...scene,
      startTime: currentTime,
      endTime: currentTime + duration,
    };
    currentTime += duration + 0.5; // 0.5秒のギャップ
    return adjusted;
  });
};
```

---

## WebGL/ThreeJS/GSAP アニメーション

### ThreeJS with Remotion

```tsx
import { ThreeCanvas } from '@remotion/three';

export const ThreeDScene: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <ThreeCanvas>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <mesh rotation={[0, frame * 0.02, 0]}>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="orange" />
      </mesh>
    </ThreeCanvas>
  );
};
```

### GSAP-style Animations

```typescript
// RemotionでGSAP風のイージング
import { Easing } from 'remotion';

const easeOutBack = (t: number) => {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
};

const value = interpolate(frame, [0, 30], [0, 100], {
  easing: easeOutBack,
});
```
