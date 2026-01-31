import type { UserPromptSubmitHookData } from "./types.ts";

// Intent detection patterns
const INTENT_PATTERNS = {
  planning: [
    /\bplan\b/i,
    /\b設計\b/,
    /\barchitect/i,
    /\bdesign\b/i,
    /\bどう(やって|する)/,
    /\b方針\b/,
  ],
  implementation: [
    /\b実装/,
    /\bimplement/i,
    /\bcreate\b/i,
    /\b作(って|る|成)/,
    /\badd\b/i,
    /\b追加/,
    /\bwrite\b/i,
    /\b書(いて|く)/,
  ],
  debugging: [
    /\bdebug/i,
    /\bfix\b/i,
    /\berror/i,
    /\b修正/,
    /\bバグ/,
    /\b直(して|す)/,
    /\b動(かない|きません)/,
  ],
  review: [
    /\breview/i,
    /\bレビュー/,
    /\bcheck\b/i,
    /\b確認/,
    /\bverify/i,
    /\b検証/,
  ],
  testing: [
    /\btest/i,
    /\bテスト/,
    /\btdd\b/i,
    /\bspec\b/i,
  ],
  refactoring: [
    /\brefactor/i,
    /\bリファクタ/,
    /\bclean/i,
    /\b整理/,
    /\b改善/,
  ],
};

type Intent = keyof typeof INTENT_PATTERNS;

function detectIntent(prompt: string): Intent | null {
  for (const [intent, patterns] of Object.entries(INTENT_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(prompt)) {
        return intent as Intent;
      }
    }
  }
  return null;
}

function getIntentEmoji(intent: Intent): string {
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

function getIntentHint(intent: Intent): string {
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

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: UserPromptSubmitHookData = JSON.parse(input);

    const intent = detectIntent(data.prompt);

    if (intent) {
      const emoji = getIntentEmoji(intent);
      const hint = getIntentHint(intent);
      console.log(`${emoji} Detected intent: ${intent}`);
      console.log(`💡 ${hint}`);
    }

    // Check for potential security-sensitive operations
    const securityKeywords = [
      /\bpassword/i,
      /\bsecret/i,
      /\btoken/i,
      /\bapi[_-]?key/i,
      /\bcredential/i,
      /\bauth/i,
    ];

    for (const pattern of securityKeywords) {
      if (pattern.test(data.prompt)) {
        console.log("🔐 Security-sensitive operation detected");
        console.log(
          "💡 Consider running security-reviewer agent after implementation",
        );
        break;
      }
    }
  } catch (error) {
    // Fail silently - don't block prompt submission
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[user-prompt hook error]: ${errorMessage}`);
  }
}

await main();
