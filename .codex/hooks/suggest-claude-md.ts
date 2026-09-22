// suggest-claude-md.ts
// 記事 https://zenn.dev/appbrew/articles/e2f38677f6a0ce のアイデアを基に実装
//
// SessionEnd / PreCompact 時に会話トランスクリプトを分析し、
// CLAUDE.md に追加すべきルール・パターンを提案する。
// 人間が忘れる手動実行に頼らず、Hookで自動実行する。

import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { $ } from "bun";
import type { StopHookData, PreCompactHookData } from "./types.ts";
import { readStdinWithTimeout, ensureStatusDir, STATUS_DIR } from "./utils.ts";

// 無限ループ防止用の環境変数フラグ（記事のアイデア）
const GUARD_ENV = "SUGGEST_CLAUDE_MD_RUNNING";

// 提案ログの保存先
const SUGGESTIONS_DIR = `${STATUS_DIR}/claude-md-suggestions`;

export type TranscriptMessage = {
  role: "user" | "assistant" | "system";
  content: string | Array<{ type: string; text?: string; tool_use_id?: string; content?: string }>;
};

export type Suggestion = {
  category: "project-rule" | "repeated-correction" | "consistency";
  description: string;
  proposed_addition: string;
};

/**
 * トランスクリプトファイルからメッセージを抽出する
 * NDJSON形式 (1行1JSON) を想定
 */
export function loadTranscript(transcriptPath: string): TranscriptMessage[] {
  try {
    const content = readFileSync(transcriptPath, "utf-8");
    const messages: TranscriptMessage[] = [];

    for (const line of content.split("\n")) {
      if (!line.trim()) continue;
      try {
        const entry = JSON.parse(line);
        // テキストコンテンツが空のメッセージは除外（記事のノイズフィルタリング）
        if (entry.type === "message" || entry.role) {
          const text = extractText(entry);
          if (text.trim()) {
            messages.push({
              role: entry.role || "assistant",
              content: text,
            });
          }
        }
      } catch {
        // 不正なJSONは無視
      }
    }
    return messages;
  } catch {
    return [];
  }
}

/**
 * メッセージからテキストを抽出する
 */
export function extractText(entry: Record<string, unknown>): string {
  if (typeof entry.content === "string") return entry.content;
  if (Array.isArray(entry.content)) {
    return entry.content
      .filter((block: Record<string, unknown>) => block.type === "text" && typeof block.text === "string")
      .map((block: Record<string, unknown>) => block.text as string)
      .join("\n");
  }
  if (typeof entry.message === "object" && entry.message !== null) {
    return extractText(entry.message as Record<string, unknown>);
  }
  return "";
}

/**
 * 現在のCLAUDE.mdの内容を読み込む
 */
export function loadClaudeMd(cwd: string): string {
  const candidates = [
    resolve(cwd, ".claude/CLAUDE.md"),
    resolve(cwd, "CLAUDE.md"),
  ];
  for (const path of candidates) {
    try {
      return readFileSync(path, "utf-8");
    } catch {
      continue;
    }
  }
  return "";
}

/**
 * 会話パターンを分析し、CLAUDE.md改善の提案を生成する
 *
 * 提案対象（記事のアプローチ）:
 * 1. プロジェクト独自ルールが指摘された場合
 * 2. 同じ修正指示の繰り返し
 * 3. 関連箇所での整合性が求められる場合
 */
export function analyzeForSuggestions(
  messages: TranscriptMessage[],
  currentClaudeMd: string,
): Suggestion[] {
  const suggestions: Suggestion[] = [];
  const userMessages = messages
    .filter((m) => m.role === "user")
    .map((m) => (typeof m.content === "string" ? m.content : ""));

  // パターン1: 繰り返される指示を検出
  const instructionPatterns = detectRepeatedInstructions(userMessages);
  for (const pattern of instructionPatterns) {
    if (!currentClaudeMd.includes(pattern.keyword)) {
      suggestions.push({
        category: "repeated-correction",
        description: `「${pattern.keyword}」に関する指示が${pattern.count}回繰り返されています`,
        proposed_addition: pattern.suggestedRule,
      });
    }
  }

  // パターン2: 明示的なルール指定を検出
  const explicitRules = detectExplicitRules(userMessages);
  for (const rule of explicitRules) {
    if (!currentClaudeMd.toLowerCase().includes(rule.keyword.toLowerCase())) {
      suggestions.push({
        category: "project-rule",
        description: rule.description,
        proposed_addition: rule.suggestedRule,
      });
    }
  }

  // パターン3: コーディング規約パターンを検出
  const conventionPatterns = detectConventionPatterns(messages);
  for (const conv of conventionPatterns) {
    if (!currentClaudeMd.includes(conv.keyword)) {
      suggestions.push({
        category: "consistency",
        description: conv.description,
        proposed_addition: conv.suggestedRule,
      });
    }
  }

  return suggestions;
}

/**
 * 繰り返される指示パターンを検出
 */
export function detectRepeatedInstructions(
  userMessages: string[],
): Array<{ keyword: string; count: number; suggestedRule: string }> {
  const results: Array<{ keyword: string; count: number; suggestedRule: string }> = [];

  // 「〜しないで」「〜してください」「〜を使って」のパターンを検出
  const patterns = [
    { regex: /(?:は|を)使わないで|(?:は|を)使うな/g, extractKeyword: (m: string) => extractNegation(m) },
    { regex: /必ず(.+?)(?:して|を使って|にして|をつけて|を書いて|すること)/g, extractKeyword: (_m: string, match: RegExpMatchArray) => match[1]?.trim() },
    { regex: /(.+?)(?:ではなく|じゃなくて)(.+?)(?:を使って|にして|で)/g, extractKeyword: (_m: string, match: RegExpMatchArray) => `${match[1]?.trim()} → ${match[2]?.trim()}` },
  ];

  const keywordCounts = new Map<string, number>();

  for (const msg of userMessages) {
    for (const pattern of patterns) {
      const matches = [...msg.matchAll(pattern.regex)];
      for (const match of matches) {
        const keyword = pattern.extractKeyword(msg, match);
        if (keyword && keyword.length > 1 && keyword.length < 50) {
          keywordCounts.set(keyword, (keywordCounts.get(keyword) || 0) + 1);
        }
      }
    }
  }

  for (const [keyword, count] of keywordCounts) {
    if (count >= 2) {
      results.push({
        keyword,
        count,
        suggestedRule: `- ${keyword}`,
      });
    }
  }

  return results;
}

function extractNegation(msg: string): string {
  const match = msg.match(/(.{2,20})(?:は|を)使わないで|(.{2,20})(?:は|を)使うな/);
  return match?.[1]?.trim() || match?.[2]?.trim() || "";
}

/**
 * 明示的なルール指定を検出
 */
export function detectExplicitRules(
  userMessages: string[],
): Array<{ keyword: string; description: string; suggestedRule: string }> {
  const results: Array<{ keyword: string; description: string; suggestedRule: string }> = [];

  const rulePatterns = [
    // 「このプロジェクトでは〜」パターン
    { regex: /このプロジェクトでは(.+?)(?:。|$)/g, type: "project-convention" as const },
    // 「ルールとして〜」パターン
    { regex: /ルール(?:として|:)\s*(.+?)(?:。|$)/g, type: "explicit-rule" as const },
    // 「常に〜する」パターン
    { regex: /常に(.+?)(?:する|して|こと)(?:。|$)/g, type: "always-do" as const },
    // 「絶対に〜しない」パターン
    { regex: /絶対に(.+?)(?:しない|するな|禁止)(?:。|$)/g, type: "never-do" as const },
  ];

  for (const msg of userMessages) {
    for (const pattern of rulePatterns) {
      const matches = [...msg.matchAll(pattern.regex)];
      for (const match of matches) {
        const content = match[1]?.trim();
        if (content && content.length > 3 && content.length < 100) {
          results.push({
            keyword: content,
            description: `ユーザーが明示的に指定: "${match[0].trim()}"`,
            suggestedRule: `- ${match[0].trim()}`,
          });
        }
      }
    }
  }

  return results;
}

/**
 * コーディング規約パターンを検出
 */
export function detectConventionPatterns(
  messages: TranscriptMessage[],
): Array<{ keyword: string; description: string; suggestedRule: string }> {
  const results: Array<{ keyword: string; description: string; suggestedRule: string }> = [];

  // assistantのメッセージで修正されたパターンを検出
  const corrections = messages.filter(
    (m, i) =>
      m.role === "user" &&
      i > 0 &&
      typeof m.content === "string" &&
      (m.content.includes("違う") ||
        m.content.includes("そうじゃなく") ||
        m.content.includes("修正して") ||
        m.content.includes("直して")),
  );

  if (corrections.length >= 2) {
    const correctionTexts = corrections.map((c) =>
      typeof c.content === "string" ? c.content : "",
    );

    // 共通する修正パターンがあるか確認
    const commonWords = findCommonKeywords(correctionTexts);
    for (const word of commonWords) {
      results.push({
        keyword: word,
        description: `「${word}」に関する修正指示が${corrections.length}回発生`,
        suggestedRule: `- ${word}に関する規約を確認すること`,
      });
    }
  }

  return results;
}

/**
 * 複数テキスト中の共通キーワードを抽出
 * 日本語の場合、完全一致ではなく部分文字列マッチも行う
 */
function findCommonKeywords(texts: string[]): string[] {
  if (texts.length < 2) return [];

  // 各テキストから単語候補を抽出（区切り文字分割 + N-gram的な部分文字列）
  const wordSets = texts.map((t) => {
    const words = new Set<string>();
    // 区切り文字で分割
    for (const w of t.split(/[\s、。,.\n]+/)) {
      if (w.length >= 2) words.add(w);
    }
    return { words, text: t };
  });

  const firstSet = wordSets[0];
  if (!firstSet) return [];

  const common: string[] = [];

  // 完全一致チェック
  for (const word of firstSet.words) {
    if (wordSets.every((set) => set.words.has(word))) {
      common.push(word);
    }
  }

  // 完全一致がなければ、部分文字列マッチ（2文字以上の共通部分）
  if (common.length === 0) {
    for (const word of firstSet.words) {
      // 各単語の部分文字列（3文字以上）が他のすべてのテキストに含まれるか
      for (let len = Math.min(word.length, 8); len >= 3; len--) {
        for (let start = 0; start <= word.length - len; start++) {
          const sub = word.substring(start, start + len);
          if (wordSets.every((set) => set.text.includes(sub)) && !common.includes(sub)) {
            common.push(sub);
          }
        }
      }
    }
  }

  return common.slice(0, 3); // 最大3個
}

/**
 * 提案をログファイルに保存
 */
export function saveSuggestions(
  sessionId: string,
  suggestions: Suggestion[],
): string {
  if (!existsSync(SUGGESTIONS_DIR)) {
    mkdirSync(SUGGESTIONS_DIR, { recursive: true });
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const logFile = `${SUGGESTIONS_DIR}/${sessionId}-${timestamp}.md`;

  const content = `# CLAUDE.md 改善提案
- **Session**: ${sessionId}
- **Generated**: ${new Date().toISOString()}
- **Suggestions**: ${suggestions.length}件

${suggestions.map((s, i) => `## ${i + 1}. [${s.category}] ${s.description}

\`\`\`
${s.proposed_addition}
\`\`\`
`).join("\n")}

---
> このファイルは suggest-claude-md フックにより自動生成されました。
> 採用する提案があれば CLAUDE.md に手動で反映してください。
`;

  writeFileSync(logFile, content);
  return logFile;
}

/**
 * メイン処理
 */
export async function processSuggestions(
  data: StopHookData | PreCompactHookData,
): Promise<{ suggestions: Suggestion[]; logFile: string | null }> {
  // 無限ループ防止
  if (process.env[GUARD_ENV]) {
    return { suggestions: [], logFile: null };
  }

  const transcriptPath = data.transcript_path;
  if (!transcriptPath || !existsSync(transcriptPath)) {
    return { suggestions: [], logFile: null };
  }

  const messages = loadTranscript(transcriptPath);
  if (messages.length < 3) {
    // 短すぎるセッションは分析しない
    return { suggestions: [], logFile: null };
  }

  const claudeMd = loadClaudeMd(data.cwd);
  const suggestions = analyzeForSuggestions(messages, claudeMd);

  if (suggestions.length === 0) {
    return { suggestions: [], logFile: null };
  }

  const logFile = saveSuggestions(data.session_id, suggestions);

  // サマリ出力
  console.log("━".repeat(50));
  console.log("💡 CLAUDE.md 改善提案");
  console.log("━".repeat(50));
  console.log(`${suggestions.length}件の提案があります:`);
  for (const s of suggestions) {
    console.log(`  [${s.category}] ${s.description}`);
  }
  console.log(`\n📄 詳細: ${logFile}`);
  console.log("━".repeat(50));

  return { suggestions, logFile };
}

async function main() {
  // 無限ループ防止チェック
  if (process.env[GUARD_ENV]) {
    return;
  }

  // 環境変数セット（子プロセスへの伝搬用）
  process.env[GUARD_ENV] = "1";

  try {
    const data = await readStdinWithTimeout<StopHookData | PreCompactHookData>();
    if (!data) return;
    await processSuggestions(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[suggest-claude-md hook error]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
