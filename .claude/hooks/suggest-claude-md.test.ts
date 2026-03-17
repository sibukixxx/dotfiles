import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import { mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs";
import {
  extractText,
  loadTranscript,
  loadClaudeMd,
  analyzeForSuggestions,
  detectRepeatedInstructions,
  detectExplicitRules,
  detectConventionPatterns,
  saveSuggestions,
  processSuggestions,
  type TranscriptMessage,
  type Suggestion,
} from "./suggest-claude-md.ts";

const TEST_DIR = "/tmp/test-suggest-claude-md";

beforeEach(() => {
  mkdirSync(TEST_DIR, { recursive: true });
});

afterEach(() => {
  if (existsSync(TEST_DIR)) {
    rmSync(TEST_DIR, { recursive: true, force: true });
  }
});

// ============================================
// extractText
// ============================================
describe("extractText", () => {
  it("returns string content directly", () => {
    const entry = { content: "hello world" };
    expect(extractText(entry)).toBe("hello world");
  });

  it("extracts text from array content blocks", () => {
    const entry = {
      content: [
        { type: "text", text: "first" },
        { type: "tool_use", id: "123" },
        { type: "text", text: "second" },
      ],
    };
    expect(extractText(entry)).toBe("first\nsecond");
  });

  it("returns empty string for missing content", () => {
    expect(extractText({})).toBe("");
  });

  it("extracts text from nested message object", () => {
    const entry = { message: { content: "nested text" } };
    expect(extractText(entry)).toBe("nested text");
  });
});

// ============================================
// loadTranscript
// ============================================
describe("loadTranscript", () => {
  it("returns empty array for non-existent file", () => {
    expect(loadTranscript("/tmp/nonexistent.jsonl")).toEqual([]);
  });

  it("parses NDJSON transcript with role field", () => {
    const transcriptPath = `${TEST_DIR}/transcript.jsonl`;
    const lines = [
      JSON.stringify({ role: "user", content: "pnpmを使って" }),
      JSON.stringify({ role: "assistant", content: "了解です" }),
      JSON.stringify({ role: "user", content: "テストも書いて" }),
    ];
    writeFileSync(transcriptPath, lines.join("\n"));

    const messages = loadTranscript(transcriptPath);
    expect(messages).toHaveLength(3);
    expect(messages[0].role).toBe("user");
    expect(messages[0].content).toBe("pnpmを使って");
  });

  it("skips empty lines and invalid JSON", () => {
    const transcriptPath = `${TEST_DIR}/transcript.jsonl`;
    const lines = [
      JSON.stringify({ role: "user", content: "hello" }),
      "",
      "not json",
      JSON.stringify({ role: "assistant", content: "hi" }),
    ];
    writeFileSync(transcriptPath, lines.join("\n"));

    const messages = loadTranscript(transcriptPath);
    expect(messages).toHaveLength(2);
  });

  it("filters out messages with empty text content", () => {
    const transcriptPath = `${TEST_DIR}/transcript.jsonl`;
    const lines = [
      JSON.stringify({ role: "user", content: "" }),
      JSON.stringify({ role: "user", content: "real content" }),
    ];
    writeFileSync(transcriptPath, lines.join("\n"));

    const messages = loadTranscript(transcriptPath);
    expect(messages).toHaveLength(1);
    expect(messages[0].content).toBe("real content");
  });
});

// ============================================
// loadClaudeMd
// ============================================
describe("loadClaudeMd", () => {
  it("loads .claude/CLAUDE.md from cwd", () => {
    const projectDir = `${TEST_DIR}/project`;
    mkdirSync(`${projectDir}/.claude`, { recursive: true });
    writeFileSync(`${projectDir}/.claude/CLAUDE.md`, "# Test Rules\n- rule1");

    expect(loadClaudeMd(projectDir)).toBe("# Test Rules\n- rule1");
  });

  it("falls back to CLAUDE.md in root", () => {
    const projectDir = `${TEST_DIR}/project2`;
    mkdirSync(projectDir, { recursive: true });
    writeFileSync(`${projectDir}/CLAUDE.md`, "# Root CLAUDE.md");

    expect(loadClaudeMd(projectDir)).toBe("# Root CLAUDE.md");
  });

  it("returns empty string when no CLAUDE.md exists", () => {
    expect(loadClaudeMd(`${TEST_DIR}/no-project`)).toBe("");
  });
});

// ============================================
// detectRepeatedInstructions
// ============================================
describe("detectRepeatedInstructions", () => {
  it("detects repeated negation patterns", () => {
    const messages = [
      "npmは使わないで",
      "npmは使わないで、pnpmを使って",
      "もう一度言うけどnpmは使わないで",
    ];

    const results = detectRepeatedInstructions(messages);
    expect(results.length).toBeGreaterThanOrEqual(1);
    expect(results.some((r) => r.keyword.includes("npm"))).toBe(true);
  });

  it("detects repeated mandatory patterns", () => {
    const messages = [
      "必ず型アノテーションをつけてほしい",
      "必ず型アノテーションをつけてほしい",
      "型アノテーション忘れないで",
    ];

    const results = detectRepeatedInstructions(messages);
    // 「必ず〜をつけて」パターンで抽出される
    expect(results.some((r) => r.keyword.includes("型アノテーション"))).toBe(true);
  });

  it("detects repeated 'must write' pattern", () => {
    const messages = [
      "必ずテストを書いてほしい",
      "必ずテストを書いてください",
    ];

    const results = detectRepeatedInstructions(messages);
    expect(results.some((r) => r.keyword.includes("テスト"))).toBe(true);
  });

  it("returns empty for non-repeated instructions", () => {
    const messages = [
      "ファイルを作成して",
      "テストを実行して",
    ];

    const results = detectRepeatedInstructions(messages);
    expect(results).toHaveLength(0);
  });
});

// ============================================
// detectExplicitRules
// ============================================
describe("detectExplicitRules", () => {
  it("detects 'このプロジェクトでは' pattern", () => {
    const messages = [
      "このプロジェクトではpnpmを使う。",
    ];

    const results = detectExplicitRules(messages);
    expect(results.length).toBeGreaterThanOrEqual(1);
    expect(results[0].keyword).toContain("pnpm");
  });

  it("detects 'ルールとして' pattern", () => {
    const messages = [
      "ルールとして: コミットメッセージは日本語で書く。",
    ];

    const results = detectExplicitRules(messages);
    expect(results.length).toBeGreaterThanOrEqual(1);
  });

  it("detects 'always do' pattern", () => {
    const messages = [
      "常にエラーハンドリングを入れること。",
    ];

    const results = detectExplicitRules(messages);
    expect(results.length).toBeGreaterThanOrEqual(1);
  });

  it("detects 'never do' pattern", () => {
    const messages = [
      "絶対にanyを使うな禁止。",
    ];

    const results = detectExplicitRules(messages);
    expect(results.length).toBeGreaterThanOrEqual(1);
  });

  it("returns empty for normal messages", () => {
    const results = detectExplicitRules(["こんにちは", "ファイルを読んで"]);
    expect(results).toHaveLength(0);
  });
});

// ============================================
// detectConventionPatterns
// ============================================
describe("detectConventionPatterns", () => {
  it("detects repeated corrections with common keywords", () => {
    const messages: TranscriptMessage[] = [
      { role: "assistant", content: "コードを書きました" },
      { role: "user", content: "インデントが違う、修正して" },
      { role: "assistant", content: "修正しました" },
      { role: "user", content: "またインデントが違う、直して" },
    ];

    const results = detectConventionPatterns(messages);
    expect(results.some((r) => r.keyword.includes("インデント"))).toBe(true);
  });

  it("returns empty when no corrections found", () => {
    const messages: TranscriptMessage[] = [
      { role: "user", content: "ファイルを作成して" },
      { role: "assistant", content: "作成しました" },
    ];

    const results = detectConventionPatterns(messages);
    expect(results).toHaveLength(0);
  });
});

// ============================================
// analyzeForSuggestions
// ============================================
describe("analyzeForSuggestions", () => {
  it("returns empty when no patterns found", () => {
    const messages: TranscriptMessage[] = [
      { role: "user", content: "hello" },
      { role: "assistant", content: "hi" },
    ];

    const suggestions = analyzeForSuggestions(messages, "");
    expect(suggestions).toHaveLength(0);
  });

  it("filters out suggestions already in CLAUDE.md", () => {
    const messages: TranscriptMessage[] = [
      { role: "user", content: "このプロジェクトではpnpmを使う。" },
    ];

    // CLAUDE.mdに同じキーワード「pnpmを使う」が含まれていれば提案されない
    const suggestions = analyzeForSuggestions(messages, "このプロジェクトではpnpmを使う");
    expect(suggestions).toHaveLength(0);
  });

  it("returns suggestions for rules not in CLAUDE.md", () => {
    const messages: TranscriptMessage[] = [
      { role: "user", content: "このプロジェクトではBiomeを使う。" },
    ];

    const suggestions = analyzeForSuggestions(messages, "# Rules\n- pnpm only");
    expect(suggestions.length).toBeGreaterThanOrEqual(1);
    expect(suggestions[0].category).toBe("project-rule");
  });
});

// ============================================
// saveSuggestions
// ============================================
describe("saveSuggestions", () => {
  it("saves suggestions to a markdown file", () => {
    // Override SUGGESTIONS_DIR via the function
    const suggestions: Suggestion[] = [
      {
        category: "project-rule",
        description: "pnpmを使うルール",
        proposed_addition: "- pnpmを使用すること",
      },
    ];

    const logFile = saveSuggestions("test-session-123", suggestions);
    expect(existsSync(logFile)).toBe(true);
  });
});

// ============================================
// processSuggestions
// ============================================
describe("processSuggestions", () => {
  it("returns empty when guard env is set", async () => {
    const originalEnv = process.env.SUGGEST_CLAUDE_MD_RUNNING;
    process.env.SUGGEST_CLAUDE_MD_RUNNING = "1";

    const result = await processSuggestions({
      session_id: "test",
      transcript_path: "/tmp/nonexistent",
      hook_event_name: "Stop",
      stop_reason: "end_turn",
      cwd: "/tmp",
    });

    expect(result.suggestions).toHaveLength(0);
    expect(result.logFile).toBeNull();

    // cleanup
    if (originalEnv === undefined) {
      delete process.env.SUGGEST_CLAUDE_MD_RUNNING;
    } else {
      process.env.SUGGEST_CLAUDE_MD_RUNNING = originalEnv;
    }
  });

  it("returns empty for non-existent transcript", async () => {
    const result = await processSuggestions({
      session_id: "test",
      transcript_path: "/tmp/nonexistent.jsonl",
      hook_event_name: "Stop",
      stop_reason: "end_turn",
      cwd: "/tmp",
    });

    expect(result.suggestions).toHaveLength(0);
  });

  it("returns empty for short sessions (< 3 messages)", async () => {
    const transcriptPath = `${TEST_DIR}/short.jsonl`;
    writeFileSync(
      transcriptPath,
      [
        JSON.stringify({ role: "user", content: "hello" }),
        JSON.stringify({ role: "assistant", content: "hi" }),
      ].join("\n"),
    );

    const result = await processSuggestions({
      session_id: "test",
      transcript_path: transcriptPath,
      hook_event_name: "Stop",
      stop_reason: "end_turn",
      cwd: TEST_DIR,
    });

    expect(result.suggestions).toHaveLength(0);
  });
});
