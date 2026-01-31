import { $ } from "bun";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import type { SessionStartHookData, SessionState } from "./types.ts";

const STATUS_DIR = `${process.env.HOME}/.claude/status`;
const CURRENT_FILE = `${STATUS_DIR}/current.md`;
const STATE_FILE = `${STATUS_DIR}/session_state.json`;

function ensureStatusDir() {
  if (!existsSync(STATUS_DIR)) {
    mkdirSync(STATUS_DIR, { recursive: true });
  }
  const queueDir = `${STATUS_DIR}/queue`;
  if (!existsSync(queueDir)) {
    mkdirSync(queueDir, { recursive: true });
  }
}

async function getGitStatus(): Promise<string[]> {
  try {
    const result = await $`git status --porcelain`.text();
    return result.trim().split("\n").filter((line) => line.length > 0);
  } catch {
    return [];
  }
}

async function getGitBranch(): Promise<string> {
  try {
    return (await $`git branch --show-current`.text()).trim();
  } catch {
    return "unknown";
  }
}

function getCurrentTask(): string | null {
  try {
    const content = readFileSync(CURRENT_FILE, "utf-8");
    return content.trim() || null;
  } catch {
    return null;
  }
}

function loadSessionState(): SessionState | null {
  try {
    const content = readFileSync(STATE_FILE, "utf-8");
    return JSON.parse(content);
  } catch {
    return null;
  }
}

function saveSessionState(state: SessionState): void {
  ensureStatusDir();
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: SessionStartHookData = JSON.parse(input);

    ensureStatusDir();

    const messages: string[] = [];

    // 1. Check git status
    const gitChanges = await getGitStatus();
    const branch = await getGitBranch();

    if (gitChanges.length > 0) {
      messages.push(`⚠️ ${gitChanges.length} uncommitted changes on branch '${branch}'`);
      // Show first 5 changes
      const preview = gitChanges.slice(0, 5).map((f) => `  ${f}`).join("\n");
      if (gitChanges.length > 5) {
        messages.push(`${preview}\n  ... and ${gitChanges.length - 5} more`);
      } else {
        messages.push(preview);
      }
    } else {
      messages.push(`✓ Clean working tree on branch '${branch}'`);
    }

    // 2. Check for current task
    const currentTask = getCurrentTask();
    if (currentTask) {
      messages.push(`\n📋 Current Task:\n${currentTask}`);
    }

    // 3. Load previous session state
    const previousState = loadSessionState();
    if (previousState?.task_stack && previousState.task_stack.length > 0) {
      messages.push(
        `\n📚 Task Stack (${previousState.task_stack.length} items):`,
      );
      previousState.task_stack.slice(0, 3).forEach((task, i) => {
        messages.push(`  ${i + 1}. [${task.priority}] ${task.title}`);
      });
    }

    // 4. Initialize new session state
    const newState: SessionState = {
      session_id: data.session_id,
      started_at: new Date().toISOString(),
      last_activity: new Date().toISOString(),
      current_task: previousState?.current_task,
      task_stack: previousState?.task_stack || [],
      uncommitted_files: gitChanges,
      notes: [],
    };
    saveSessionState(newState);

    // Output session info
    console.log("━".repeat(50));
    console.log("🚀 Claude Code Session Started");
    console.log("━".repeat(50));
    messages.forEach((msg) => console.log(msg));
    console.log("━".repeat(50));
  } catch (error) {
    // Fail silently - don't block session start
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[session-start hook error]: ${errorMessage}`);
  }
}

await main();
