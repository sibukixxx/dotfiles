// Shared utility functions for Claude Code hooks
// Extracted from duplicated code across hook files

import { $ } from "bun";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname } from "node:path";
import type { SessionState } from "./types.ts";

// ============================================
// Tool Classification
// ============================================

/** File modification tool names used by Claude Code */
const FILE_MODIFICATION_TOOLS = ["Write", "Edit", "MultiEdit"] as const;

export function isFileModificationTool(toolName: string): boolean {
  return (FILE_MODIFICATION_TOOLS as readonly string[]).includes(toolName);
}

// ============================================
// Git Operations
// ============================================

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

// ============================================
// Session State I/O
// ============================================

export const STATUS_DIR = `${process.env.HOME}/.claude/status`;
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

export function loadSessionState(filePath: string = STATE_FILE): SessionState | null {
  try {
    const content = readFileSync(filePath, "utf-8");
    return JSON.parse(content);
  } catch {
    return null;
  }
}

export function saveSessionState(state: SessionState, filePath: string = STATE_FILE): void {
  ensureStatusDir();
  const dir = dirname(filePath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  writeFileSync(filePath, JSON.stringify(state, null, 2));
}

// ============================================
// stdin Reading
// ============================================

const DEFAULT_STDIN_TIMEOUT_MS = 5000;

export async function readStdinWithTimeout<T>(
  timeoutMs: number = DEFAULT_STDIN_TIMEOUT_MS
): Promise<T | null> {
  const stdinPromise = Bun.stdin.text();
  const timeoutPromise = new Promise<null>((resolve) =>
    setTimeout(() => resolve(null), timeoutMs)
  );
  const input = await Promise.race([stdinPromise, timeoutPromise]);
  if (input === null || input.trim() === "") {
    return null;
  }
  return JSON.parse(input) as T;
}
