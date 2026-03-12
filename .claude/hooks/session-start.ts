import { readFileSync } from "node:fs";
import type { SessionStartHookData, SessionState } from "./types.ts";
import {
  getGitStatus,
  getGitBranch,
  ensureStatusDir,
  loadSessionState,
  saveSessionState,
  readStdinWithTimeout,
  STATUS_DIR,
  STATE_FILE,
} from "./utils.ts";

export { getGitStatus, getGitBranch, ensureStatusDir, loadSessionState, saveSessionState, STATUS_DIR, STATE_FILE };

export const CURRENT_FILE = `${STATUS_DIR}/current.md`;

export function getCurrentTask(filePath: string = CURRENT_FILE): string | null {
  try {
    const content = readFileSync(filePath, "utf-8");
    return content.trim() || null;
  } catch {
    return null;
  }
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
    const data = await readStdinWithTimeout<SessionStartHookData>();
    if (!data) return;
    await processSessionStart(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[session-start hook error]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
