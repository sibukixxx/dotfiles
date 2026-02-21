// Theme template for promo video compositions
// Copy this file to: apps/promo-video/src/compositions/<Name>/theme.ts

export const __NAME__Theme = {
  colors: {
    // Primary brand colors
    primary: '#1e3a5f',      // Main brand color
    secondary: '#3b82f6',    // Secondary brand color
    accent: '#93c5fd',       // Accent/highlight color

    // Text colors
    text: '#e2e8f0',         // Primary text (light)
    textDim: '#94a3b8',      // Secondary text (dimmed)

    // Background colors
    bg: '#0f172a',           // Main background (dark)
    bgLight: '#1e293b',      // Lighter background
    bgDark: '#020617',       // Darker background
  },
  fonts: {
    heading: 'Noto Sans JP, sans-serif',
    body: 'Noto Sans JP, sans-serif',
  },
};

// Usage:
// import { __NAME__Theme } from './theme';
// const theme = __NAME__Theme;
