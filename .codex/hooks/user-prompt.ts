import type { UserPromptSubmitHookData } from "./types.ts";
import { readStdinWithTimeout } from "./utils.ts";

// Intent detection patterns
// Note: \b doesn't work with Japanese characters, so we use plain patterns for Japanese
export const INTENT_PATTERNS = {
  planning: [
    /\bplan\b/i,
    /設計/,
    /\barchitect/i,
    /\bdesign\b/i,
    /どうやって|どうする/,
    /方針/,
  ],
  implementation: [
    /実装/,
    /\bimplement/i,
    /\bcreate\b/i,
    /作って|作る|作成/,
    /\badd\b/i,
    /追加/,
    /\bwrite\b/i,
    /書いて|書く/,
  ],
  debugging: [
    /\bdebug/i,
    /\bfix\b/i,
    /\berror/i,
    /修正/,
    /バグ/,
    /直して|直す/,
    /動かない|動きません/,
  ],
  review: [
    /\breview/i,
    /レビュー/,
    /\bcheck\b/i,
    /確認/,
    /\bverify\b/i,
    /検証/,
  ],
  testing: [
    /\btest/i,
    /テスト/,
    /\btdd\b/i,
    /\bspec\b/i,
  ],
  refactoring: [
    /\brefactor/i,
    /リファクタ/,
    /\bclean\b/i,
    /整理/,
    /改善/,
  ],
} as const;

export type Intent = keyof typeof INTENT_PATTERNS;

export function detectIntent(prompt: string): Intent | null {
  for (const [intent, patterns] of Object.entries(INTENT_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(prompt)) {
        return intent as Intent;
      }
    }
  }
  return null;
}

export function getIntentEmoji(intent: Intent): string {
  const emojis: Record<Intent, string> = {
    planning: "📋",
    implementation: "🔨",
    debugging: "🐛",
    review: "👀",
    testing: "🧪",
    refactoring: "♻️",
  };
  return emojis[intent] || "💭";
}

export function getIntentHint(intent: Intent): string {
  const hints: Record<Intent, string> = {
    planning:
      "Consider using /plan command or planner agent for structured planning",
    implementation:
      "Remember: TDD approach - write tests first, then implement",
    debugging: "Check error logs, add strategic console.log, use debugger",
    review:
      "Use /review command for comprehensive code review with security checks",
    testing: "Use /tdd command for test-driven development workflow",
    refactoring:
      "Ensure tests pass before and after refactoring (Green → Refactor → Green)",
  };
  return hints[intent];
}

export const SECURITY_KEYWORDS = [
  /\bpassword/i,
  /\bsecret/i,
  /\btoken/i,
  /\bapi[_-]?key/i,
  /\bcredential/i,
  /\bauth/i,
];

export function detectSecurityKeyword(prompt: string): boolean {
  for (const pattern of SECURITY_KEYWORDS) {
    if (pattern.test(prompt)) {
      return true;
    }
  }
  return false;
}

export async function processPrompt(data: UserPromptSubmitHookData): Promise<{
  intent: Intent | null;
  hasSecurity: boolean;
}> {
  const intent = detectIntent(data.prompt);
  const hasSecurity = detectSecurityKeyword(data.prompt);

  if (intent) {
    const emoji = getIntentEmoji(intent);
    const hint = getIntentHint(intent);
    console.log(`${emoji} Detected intent: ${intent}`);
    console.log(`💡 ${hint}`);
  }

  if (hasSecurity) {
    console.log("🔐 Security-sensitive operation detected");
    console.log(
      "💡 Consider running security-reviewer agent after implementation",
    );
  }

  return { intent, hasSecurity };
}

async function main() {
  try {
    const data = await readStdinWithTimeout<UserPromptSubmitHookData>();
    if (!data) return;
    await processPrompt(data);
  } catch (error) {
    // Fail silently - don't block prompt submission
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[user-prompt hook error]: ${errorMessage}`);
  }
}

// Only run main when executed directly
if (import.meta.main) {
  await main();
}
