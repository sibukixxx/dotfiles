import { $ } from "bun";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname } from "node:path";
import type { SessionStartHookData, SessionState } from "./types.ts";

export const STATUS_DIR = `${process.env.HOME}/.claude/status`;
export const CURRENT_FILE = `${STATUS_DIR}/current.md`;
export const STATE_FILE = `${STATUS_DIR}/session_state.json`;

export function ensureStatusDir(): void {
  if (!existsSync(STATUS_DIR)) {
    mkdirSync(STATUS_DIR, { recursive: true });
  }
  const queueDir = `${STATUS_DIR}/queue`;
  if (!existsSync(queueDir)) {
    mkdirSync(queueDir, { recursive: true });
  }
}

export async function getGitStatus(): Promise<string[]> {
  try {
    const result = await $`git status --porcelain`.text();
    return result.trim().split("\n").filter((line) => line.length > 0);
  } catch {
    return [];
  }
}

export async function getGitBranch(): Promise<string> {
  try {
    return (await $`git branch --show-current`.text()).trim();
  } catch {
    return "unknown";
  }
}

export function getCurrentTask(filePath: string = CURRENT_FILE): string | null {
  try {
    const content = readFileSync(filePath, "utf-8");
    return content.trim() || null;
  } catch {
    return null;
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
  // Ensure the default status directory exists (for default usage)
  ensureStatusDir();
  // Also ensure the parent directory of the given path exists (for custom paths)
  const dir = dirname(filePath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  writeFileSync(filePath, JSON.stringify(state, null, 2));
}

export function buildSessionMessages(
  gitChanges: string[],
  branch: string,
  currentTask: string | null,
  previousState: SessionState | null
): string[] {
  const messages: string[] = [];

  // 1. Git status message
  if (gitChanges.length > 0) {
    messages.push(`⚠️ ${gitChanges.length} uncommitted changes on branch '${branch}'`);
    const preview = gitChanges.slice(0, 5).map((f) => `  ${f}`).join("\n");
    if (gitChanges.length > 5) {
      messages.push(`${preview}\n  ... and ${gitChanges.length - 5} more`);
    } else {
      messages.push(preview);
    }
  } else {
    messages.push(`✓ Clean working tree on branch '${branch}'`);
  }

  // 2. Current task
  if (currentTask) {
    messages.push(`\n📋 Current Task:\n${currentTask}`);
  }

  // 3. Task stack
  if (previousState?.task_stack && previousState.task_stack.length > 0) {
    messages.push(
      `\n📚 Task Stack (${previousState.task_stack.length} items):`,
    );
    previousState.task_stack.slice(0, 3).forEach((task, i) => {
      messages.push(`  ${i + 1}. [${task.priority}] ${task.title}`);
    });
  }

  return messages;
}

export function createNewSessionState(
  sessionId: string,
  previousState: SessionState | null,
  gitChanges: string[]
): SessionState {
  return {
    session_id: sessionId,
    started_at: new Date().toISOString(),
    last_activity: new Date().toISOString(),
    current_task: previousState?.current_task,
    task_stack: previousState?.task_stack || [],
    uncommitted_files: gitChanges,
    notes: [],
  };
}

export function printSessionStart(messages: string[]): void {
  console.log("━".repeat(50));
  console.log("🚀 Claude Code Session Started");
  console.log("━".repeat(50));
  messages.forEach((msg) => console.log(msg));
  console.log("━".repeat(50));
}

export async function processSessionStart(data: SessionStartHookData): Promise<{
  messages: string[];
  newState: SessionState;
}> {
  ensureStatusDir();

  const gitChanges = await getGitStatus();
  const branch = await getGitBranch();
  const currentTask = getCurrentTask();
  const previousState = loadSessionState();

  const messages = buildSessionMessages(gitChanges, branch, currentTask, previousState);
  const newState = createNewSessionState(data.session_id, previousState, gitChanges);

  saveSessionState(newState);
  printSessionStart(messages);

  return { messages, newState };
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: SessionStartHookData = JSON.parse(input);
    await processSessionStart(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[session-start hook error]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
