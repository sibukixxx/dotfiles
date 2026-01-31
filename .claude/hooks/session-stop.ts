import { $ } from "bun";
import { readFileSync, writeFileSync, appendFileSync, existsSync } from "node:fs";
import type { SessionState, StopHookData } from "./types.ts";

const STATUS_DIR = `${process.env.HOME}/.claude/status`;
const STATE_FILE = `${STATUS_DIR}/session_state.json`;
const LOG_FILE = `${STATUS_DIR}/session_log.md`;

async function getGitStatus(): Promise<string[]> {
  try {
    const result = await $`git status --porcelain`.text();
    return result.trim().split("\n").filter((line) => line.length > 0);
  } catch {
    return [];
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
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function appendSessionLog(
  sessionId: string,
  startedAt: string,
  endedAt: string,
  uncommittedFiles: string[],
): void {
  const logEntry = `
## Session: ${sessionId}
- **Started**: ${startedAt}
- **Ended**: ${endedAt}
- **Uncommitted Files**: ${uncommittedFiles.length}
${uncommittedFiles.length > 0 ? uncommittedFiles.map((f) => `  - ${f}`).join("\n") : "  - (none)"}

---
`;

  try {
    if (existsSync(LOG_FILE)) {
      appendFileSync(LOG_FILE, logEntry);
    } else {
      writeFileSync(LOG_FILE, `# Claude Code Session Log\n\n${logEntry}`);
    }
  } catch {
    writeFileSync(LOG_FILE, `# Claude Code Session Log\n\n${logEntry}`);
  }
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: StopHookData = JSON.parse(input);

    const messages: string[] = [];
    const endedAt = new Date().toISOString();

    // 1. Load current session state
    const state = loadSessionState();

    // 2. Check git status
    const gitChanges = await getGitStatus();

    if (gitChanges.length > 0) {
      messages.push(`\n⚠️  ${gitChanges.length} uncommitted changes:`);
      gitChanges.slice(0, 5).forEach((f) => messages.push(`   ${f}`));
      if (gitChanges.length > 5) {
        messages.push(`   ... and ${gitChanges.length - 5} more`);
      }
      messages.push("\n💡 Consider committing before ending session");
    }

    // 3. Update and save session state
    if (state) {
      state.last_activity = endedAt;
      state.uncommitted_files = gitChanges;
      saveSessionState(state);

      // 4. Append to session log
      appendSessionLog(
        data.session_id,
        state.started_at,
        endedAt,
        gitChanges,
      );
    }

    // 5. Show task stack reminder
    if (state?.task_stack && state.task_stack.length > 0) {
      messages.push(`\n📚 Pending tasks in stack: ${state.task_stack.length}`);
      state.task_stack.slice(0, 3).forEach((task) => {
        messages.push(`   [${task.priority}] ${task.title}`);
      });
    }

    // Output session end info
    if (messages.length > 0) {
      console.log("━".repeat(50));
      console.log("📋 Session Summary");
      console.log("━".repeat(50));
      messages.forEach((msg) => console.log(msg));
      console.log("━".repeat(50));
    }
  } catch (error) {
    // Fail silently - don't block session end
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[session-stop hook error]: ${errorMessage}`);
  }
}

await main();
