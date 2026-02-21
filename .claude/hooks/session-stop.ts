import { $ } from "bun";
import { readFileSync, writeFileSync, appendFileSync, existsSync } from "node:fs";
import type { SessionState, StopHookData } from "./types.ts";

export const STATUS_DIR = `${process.env.HOME}/.claude/status`;
export const STATE_FILE = `${STATUS_DIR}/session_state.json`;
export const LOG_FILE = `${STATUS_DIR}/session_log.md`;

export async function getGitStatus(): Promise<string[]> {
  try {
    const result = await $`git status --porcelain`.text();
    return result.trim().split("\n").filter((line) => line.length > 0);
  } catch {
    return [];
  }
}

export function loadSessionState(filePath: string = STATE_FILE): SessionState | null {
  try {
    const content = readFileSync(filePath, "utf-8");
    return JSON.parse(content);
  } catch {
    return null;
  }
}

export function saveSessionState(state: SessionState, filePath: string = STATE_FILE): void {
  writeFileSync(filePath, JSON.stringify(state, null, 2));
}

export function formatSessionLogEntry(
  sessionId: string,
  startedAt: string,
  endedAt: string,
  uncommittedFiles: string[]
): string {
  return `
## Session: ${sessionId}
- **Started**: ${startedAt}
- **Ended**: ${endedAt}
- **Uncommitted Files**: ${uncommittedFiles.length}
${uncommittedFiles.length > 0 ? uncommittedFiles.map((f) => `  - ${f}`).join("\n") : "  - (none)"}

---
`;
}

export function appendSessionLog(
  sessionId: string,
  startedAt: string,
  endedAt: string,
  uncommittedFiles: string[],
  logFilePath: string = LOG_FILE
): void {
  const logEntry = formatSessionLogEntry(sessionId, startedAt, endedAt, uncommittedFiles);

  try {
    if (existsSync(logFilePath)) {
      appendFileSync(logFilePath, logEntry);
    } else {
      writeFileSync(logFilePath, `# Claude Code Session Log\n\n${logEntry}`);
    }
  } catch {
    writeFileSync(logFilePath, `# Claude Code Session Log\n\n${logEntry}`);
  }
}

export function buildStopMessages(
  gitChanges: string[],
  state: SessionState | null
): string[] {
  const messages: string[] = [];

  // Git changes warning
  if (gitChanges.length > 0) {
    messages.push(`\n⚠️  ${gitChanges.length} uncommitted changes:`);
    gitChanges.slice(0, 5).forEach((f) => messages.push(`   ${f}`));
    if (gitChanges.length > 5) {
      messages.push(`   ... and ${gitChanges.length - 5} more`);
    }
    messages.push("\n💡 Consider committing before ending session");
  }

  // Task stack reminder
  if (state?.task_stack && state.task_stack.length > 0) {
    messages.push(`\n📚 Pending tasks in stack: ${state.task_stack.length}`);
    state.task_stack.slice(0, 3).forEach((task) => {
      messages.push(`   [${task.priority}] ${task.title}`);
    });
  }

  return messages;
}

export function printSessionSummary(messages: string[]): void {
  if (messages.length > 0) {
    console.log("━".repeat(50));
    console.log("📋 Session Summary");
    console.log("━".repeat(50));
    messages.forEach((msg) => console.log(msg));
    console.log("━".repeat(50));
  }
}

export async function processSessionStop(data: StopHookData): Promise<{
  messages: string[];
  gitChanges: string[];
}> {
  const endedAt = new Date().toISOString();
  const state = loadSessionState();
  const gitChanges = await getGitStatus();

  // Update and save session state
  if (state) {
    state.last_activity = endedAt;
    state.uncommitted_files = gitChanges;
    saveSessionState(state);

    // Append to session log
    appendSessionLog(
      data.session_id,
      state.started_at,
      endedAt,
      gitChanges,
    );
  }

  const messages = buildStopMessages(gitChanges, state);
  printSessionSummary(messages);

  return { messages, gitChanges };
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: StopHookData = JSON.parse(input);
    await processSessionStop(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[session-stop hook error]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
