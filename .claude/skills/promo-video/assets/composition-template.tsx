// Composition template for promo video
// Copy this file to: apps/promo-video/src/compositions/<Name>/<Name>Hero.tsx

import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Sequence,
} from 'remotion';
import { loadFont } from '@remotion/google-fonts/NotoSansJP';
import { GradientBackground, Particles, TextReveal } from '../../components/effects';
import { __NAME__Theme } from './theme';

const { fontFamily } = loadFont();

export const __NAME__Hero: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const theme = __NAME__Theme;

  return (
    <AbsoluteFill>
      {/* Background */}
      <GradientBackground
        colors={[theme.colors.bg, theme.colors.primary, theme.colors.bgDark]}
        direction="to-bottom"
      />

      {/* Particles - choose: stars, bubbles, fog, leaves */}
      <Particles type="stars" count={60} color={theme.colors.accent} seed={42} />

      {/* Main content */}
      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily,
        }}
      >
        {/* Scene 1: Empathy (0-4s) */}
        <Sequence durationInFrames={fps * 4}>
          <AbsoluteFill
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 20,
            }}
          >
            <TextReveal
              text="__EMPATHY_LINE_1__"
              fontSize={56}
              color={theme.colors.text}
              fontFamily={fontFamily}
              effect="fade"
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)' }}
            />
            <TextReveal
              text="__EMPATHY_LINE_2__"
              fontSize={56}
              color={theme.colors.text}
              fontFamily={fontFamily}
              effect="fade"
              delay={0.5}
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)' }}
            />
          </AbsoluteFill>
        </Sequence>

        {/* Scene 2: Understanding (4-7s) */}
        <Sequence from={fps * 4} durationInFrames={fps * 3}>
          <AbsoluteFill
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <TextReveal
              text="__UNDERSTANDING_LINE_1__"
              fontSize={48}
              color={theme.colors.textDim}
              fontFamily={fontFamily}
              effect="fade"
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)' }}
            />
            <TextReveal
              text="__UNDERSTANDING_LINE_2__"
              fontSize={48}
              color={theme.colors.textDim}
              fontFamily={fontFamily}
              effect="fade"
              delay={0.8}
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)', marginTop: 16 }}
            />
          </AbsoluteFill>
        </Sequence>

        {/* Scene 3: Solution (7-10s) */}
        <Sequence from={fps * 7} durationInFrames={fps * 3}>
          <AbsoluteFill
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <TextReveal
              text="__SOLUTION_TEXT__"
              fontSize={52}
              color={theme.colors.accent}
              fontFamily={fontFamily}
              effect="fade"
              delay={0.3}
              style={{
                textShadow: `0 2px 30px ${theme.colors.accent}50`,
              }}
            />
          </AbsoluteFill>
        </Sequence>

        {/* Scene 4: Feature (10-13s) */}
        <Sequence from={fps * 10} durationInFrames={fps * 3}>
          <AbsoluteFill
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <TextReveal
              text="__FEATURE_LINE_1__"
              fontSize={48}
              color={theme.colors.text}
              fontFamily={fontFamily}
              effect="fade"
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)' }}
            />
            <TextReveal
              text="__FEATURE_LINE_2__"
              fontSize={48}
              color={theme.colors.text}
              fontFamily={fontFamily}
              effect="fade"
              delay={0.5}
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)', marginTop: 16 }}
            />
          </AbsoluteFill>
        </Sequence>

        {/* Scene 5: CTA (13-15s) */}
        <Sequence from={fps * 13} durationInFrames={fps * 2}>
          <AbsoluteFill
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 24,
            }}
          >
            <TextReveal
              text="__SERVICE_NAME__"
              fontSize={64}
              color={theme.colors.text}
              fontFamily={fontFamily}
              fontWeight={700}
              effect="pop"
              style={{ textShadow: '0 4px 30px rgba(0,0,0,0.5)' }}
            />
            <TextReveal
              text="__TAGLINE__"
              fontSize={28}
              color={theme.colors.textDim}
              fontFamily={fontFamily}
              effect="fade"
              delay={0.3}
              style={{ textShadow: '0 2px 20px rgba(0,0,0,0.5)' }}
            />
            <CTAButton frame={frame - fps * 13} />
          </AbsoluteFill>
        </Sequence>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// CTA Button Component
const CTAButton: React.FC<{ frame: number }> = ({ frame }) => {
  const scale = interpolate(frame, [10, 20], [0, 1], { extrapolateRight: 'clamp' });
  const pulse = Math.sin(frame * 0.15) * 0.05 + 1;

  return (
    <div
      style={{
        padding: '16px 48px',
        background: '#ffffff',
        borderRadius: 50,
        fontSize: 24,
        fontWeight: 700,
        color: __NAME__Theme.colors.primary,
        transform: `scale(${scale * pulse})`,
        boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
      }}
    >
      __CTA_TEXT__ →
    </div>
  );
};

// Placeholder replacements:
// __NAME__ → PascalCase name (e.g., Sleep, Cosmetiker)
// __EMPATHY_LINE_1__, __EMPATHY_LINE_2__ → Scene 1 copy
// __UNDERSTANDING_LINE_1__, __UNDERSTANDING_LINE_2__ → Scene 2 copy
// __SOLUTION_TEXT__ → Scene 3 copy
// __FEATURE_LINE_1__, __FEATURE_LINE_2__ → Scene 4 copy
// __SERVICE_NAME__ → Service name for CTA
// __TAGLINE__ → Short tagline
// __CTA_TEXT__ → Button text (e.g., "無料で始める")
