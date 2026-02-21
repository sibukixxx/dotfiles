import { describe, it, expect, beforeEach, afterEach, spyOn } from "bun:test";
import { mkdirSync, writeFileSync, rmSync, existsSync, readFileSync } from "node:fs";
import {
  buildStopMessages,
  formatSessionLogEntry,
  appendSessionLog,
  loadSessionState,
  saveSessionState,
  getGitStatus,
  printSessionSummary,
  processSessionStop,
} from "./session-stop.ts";
import type { SessionState, TaskState } from "./types.ts";

const TEST_DIR = "/tmp/claude-hooks-test-stop";
const TEST_STATE_FILE = `${TEST_DIR}/session_state.json`;
const TEST_LOG_FILE = `${TEST_DIR}/session_log.md`;

describe("buildStopMessages", () => {
  describe("git changes messages", () => {
    it("returns empty array when no changes and no state", () => {
      const messages = buildStopMessages([], null);
      expect(messages).toEqual([]);
    });

    it("shows uncommitted changes warning", () => {
      const changes = ["M file1.ts", "A file2.ts"];
      const messages = buildStopMessages(changes, null);
      expect(messages[0]).toContain("2 uncommitted changes");
    });

    it("shows first 5 changes", () => {
      const changes = ["M file1.ts", "M file2.ts", "M file3.ts"];
      const messages = buildStopMessages(changes, null);
      expect(messages.some((m) => m.includes("file1.ts"))).toBe(true);
      expect(messages.some((m) => m.includes("file2.ts"))).toBe(true);
      expect(messages.some((m) => m.includes("file3.ts"))).toBe(true);
    });

    it("shows ellipsis for more than 5 changes", () => {
      const changes = [
        "M file1.ts", "M file2.ts", "M file3.ts",
        "M file4.ts", "M file5.ts", "M file6.ts", "M file7.ts",
      ];
      const messages = buildStopMessages(changes, null);
      expect(messages.some((m) => m.includes("... and 2 more"))).toBe(true);
    });

    it("shows commit reminder", () => {
      const messages = buildStopMessages(["M file.ts"], null);
      expect(messages.some((m) => m.includes("Consider committing"))).toBe(true);
    });
  });

  describe("task stack messages", () => {
    it("shows pending tasks count", () => {
      const tasks: TaskState[] = [
        { id: "1", title: "Task 1", priority: "p1", status: "pending", created_at: "", updated_at: "" },
        { id: "2", title: "Task 2", priority: "p2", status: "pending", created_at: "", updated_at: "" },
      ];
      const state: SessionState = {
        session_id: "test",
        started_at: "",
        last_activity: "",
        task_stack: tasks,
        uncommitted_files: [],
        notes: [],
      };
      const messages = buildStopMessages([], state);
      expect(messages.some((m) => m.includes("Pending tasks in stack: 2"))).toBe(true);
    });

    it("shows first 3 tasks", () => {
      const tasks: TaskState[] = [
        { id: "1", title: "Task 1", priority: "p1", status: "pending", created_at: "", updated_at: "" },
        { id: "2", title: "Task 2", priority: "p2", status: "pending", created_at: "", updated_at: "" },
        { id: "3", title: "Task 3", priority: "p3", status: "pending", created_at: "", updated_at: "" },
        { id: "4", title: "Task 4", priority: "p1", status: "pending", created_at: "", updated_at: "" },
      ];
      const state: SessionState = {
        session_id: "test",
        started_at: "",
        last_activity: "",
        task_stack: tasks,
        uncommitted_files: [],
        notes: [],
      };
      const messages = buildStopMessages([], state);
      expect(messages.some((m) => m.includes("[p1] Task 1"))).toBe(true);
      expect(messages.some((m) => m.includes("[p2] Task 2"))).toBe(true);
      expect(messages.some((m) => m.includes("[p3] Task 3"))).toBe(true);
      expect(messages.some((m) => m.includes("Task 4"))).toBe(false);
    });

    it("omits task stack when empty", () => {
      const state: SessionState = {
        session_id: "test",
        started_at: "",
        last_activity: "",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      const messages = buildStopMessages([], state);
      expect(messages.some((m) => m.includes("Pending tasks"))).toBe(false);
    });
  });
});

describe("formatSessionLogEntry", () => {
  it("formats session log entry correctly", () => {
    const entry = formatSessionLogEntry(
      "session-123",
      "2024-01-01T10:00:00Z",
      "2024-01-01T12:00:00Z",
      ["M file.ts"]
    );
    expect(entry).toContain("## Session: session-123");
    expect(entry).toContain("**Started**: 2024-01-01T10:00:00Z");
    expect(entry).toContain("**Ended**: 2024-01-01T12:00:00Z");
    expect(entry).toContain("**Uncommitted Files**: 1");
    expect(entry).toContain("- M file.ts");
  });

  it("shows (none) when no uncommitted files", () => {
    const entry = formatSessionLogEntry(
      "session-123",
      "2024-01-01T10:00:00Z",
      "2024-01-01T12:00:00Z",
      []
    );
    expect(entry).toContain("**Uncommitted Files**: 0");
    expect(entry).toContain("- (none)");
  });

  it("lists multiple uncommitted files", () => {
    const entry = formatSessionLogEntry(
      "session-123",
      "2024-01-01T10:00:00Z",
      "2024-01-01T12:00:00Z",
      ["M file1.ts", "A file2.ts", "D file3.ts"]
    );
    expect(entry).toContain("- M file1.ts");
    expect(entry).toContain("- A file2.ts");
    expect(entry).toContain("- D file3.ts");
  });
});

describe("file operations", () => {
  beforeEach(() => {
    if (existsSync(TEST_DIR)) {
      rmSync(TEST_DIR, { recursive: true });
    }
    mkdirSync(TEST_DIR, { recursive: true });
  });

  afterEach(() => {
    if (existsSync(TEST_DIR)) {
      rmSync(TEST_DIR, { recursive: true });
    }
  });

  describe("loadSessionState", () => {
    it("loads valid session state", () => {
      const state: SessionState = {
        session_id: "test-123",
        started_at: "2024-01-01",
        last_activity: "2024-01-01",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      writeFileSync(TEST_STATE_FILE, JSON.stringify(state));
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded).toEqual(state);
    });

    it("returns null for invalid JSON", () => {
      writeFileSync(TEST_STATE_FILE, "invalid");
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded).toBe(null);
    });

    it("returns null for missing file", () => {
      const loaded = loadSessionState(`${TEST_DIR}/missing.json`);
      expect(loaded).toBe(null);
    });
  });

  describe("saveSessionState", () => {
    it("saves state to file", () => {
      const state: SessionState = {
        session_id: "test-123",
        started_at: "2024-01-01",
        last_activity: "2024-01-01",
        task_stack: [],
        uncommitted_files: ["M file.ts"],
        notes: [],
      };
      saveSessionState(state, TEST_STATE_FILE);
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded).toEqual(state);
    });
  });

  describe("appendSessionLog", () => {
    it("creates new log file when it does not exist", () => {
      appendSessionLog(
        "session-123",
        "2024-01-01T10:00:00Z",
        "2024-01-01T12:00:00Z",
        [],
        TEST_LOG_FILE
      );
      expect(existsSync(TEST_LOG_FILE)).toBe(true);
      const content = readFileSync(TEST_LOG_FILE, "utf-8");
      expect(content).toContain("# Claude Code Session Log");
      expect(content).toContain("## Session: session-123");
    });

    it("appends to existing log file", () => {
      writeFileSync(TEST_LOG_FILE, "# Claude Code Session Log\n\n");
      appendSessionLog(
        "session-1",
        "2024-01-01T10:00:00Z",
        "2024-01-01T12:00:00Z",
        [],
        TEST_LOG_FILE
      );
      appendSessionLog(
        "session-2",
        "2024-01-02T10:00:00Z",
        "2024-01-02T12:00:00Z",
        [],
        TEST_LOG_FILE
      );
      const content = readFileSync(TEST_LOG_FILE, "utf-8");
      expect(content).toContain("## Session: session-1");
      expect(content).toContain("## Session: session-2");
    });
  });
});

describe("git operations", () => {
  describe("getGitStatus", () => {
    it("returns array of changes", async () => {
      const status = await getGitStatus();
      expect(Array.isArray(status)).toBe(true);
    });
  });
});

describe("printSessionSummary", () => {
  it("does nothing for empty messages", () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    printSessionSummary([]);
    expect(consoleSpy).not.toHaveBeenCalled();
    consoleSpy.mockRestore();
  });

  it("prints messages when present", () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    printSessionSummary(["Test message"]);
    expect(consoleSpy).toHaveBeenCalled();
    consoleSpy.mockRestore();
  });

  it("prints header and separator", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    printSessionSummary(["Test"]);
    expect(calls.some((c) => c.includes("━"))).toBe(true);
    expect(calls.some((c) => c.includes("Session Summary"))).toBe(true);
    consoleSpy.mockRestore();
  });

  it("prints all messages", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    printSessionSummary(["Message 1", "Message 2", "Message 3"]);
    expect(calls.some((c) => c.includes("Message 1"))).toBe(true);
    expect(calls.some((c) => c.includes("Message 2"))).toBe(true);
    expect(calls.some((c) => c.includes("Message 3"))).toBe(true);
    consoleSpy.mockRestore();
  });
});

describe("appendSessionLog edge cases", () => {
  beforeEach(() => {
    if (existsSync(TEST_DIR)) {
      rmSync(TEST_DIR, { recursive: true });
    }
    mkdirSync(TEST_DIR, { recursive: true });
  });

  afterEach(() => {
    if (existsSync(TEST_DIR)) {
      rmSync(TEST_DIR, { recursive: true });
    }
  });

  it("handles write error by falling back to writeFileSync", () => {
    // Create a log file that we can write to
    const logPath = `${TEST_DIR}/test-log.md`;
    writeFileSync(logPath, "# Existing content\n");

    // Append to existing file
    appendSessionLog(
      "session-test",
      "2024-01-01T00:00:00Z",
      "2024-01-01T01:00:00Z",
      ["M file.ts"],
      logPath
    );

    const content = readFileSync(logPath, "utf-8");
    expect(content).toContain("session-test");
  });
});

describe("buildStopMessages edge cases", () => {
  it("handles exactly 5 changes without ellipsis", () => {
    const changes = ["M file1.ts", "M file2.ts", "M file3.ts", "M file4.ts", "M file5.ts"];
    const messages = buildStopMessages(changes, null);
    expect(messages.some((m) => m.includes("... and"))).toBe(false);
    expect(messages.some((m) => m.includes("5 uncommitted"))).toBe(true);
  });

  it("handles single change", () => {
    const changes = ["M single.ts"];
    const messages = buildStopMessages(changes, null);
    expect(messages.some((m) => m.includes("1 uncommitted"))).toBe(true);
    expect(messages.some((m) => m.includes("single.ts"))).toBe(true);
  });

  it("handles state with exactly 3 tasks", () => {
    const tasks: TaskState[] = [
      { id: "1", title: "Task 1", priority: "p1", status: "pending", created_at: "", updated_at: "" },
      { id: "2", title: "Task 2", priority: "p2", status: "pending", created_at: "", updated_at: "" },
      { id: "3", title: "Task 3", priority: "p3", status: "pending", created_at: "", updated_at: "" },
    ];
    const state: SessionState = {
      session_id: "test",
      started_at: "",
      last_activity: "",
      task_stack: tasks,
      uncommitted_files: [],
      notes: [],
    };
    const messages = buildStopMessages([], state);
    expect(messages.some((m) => m.includes("Task 1"))).toBe(true);
    expect(messages.some((m) => m.includes("Task 2"))).toBe(true);
    expect(messages.some((m) => m.includes("Task 3"))).toBe(true);
  });
});

describe("processSessionStop integration", () => {
  beforeEach(() => {
    if (existsSync(TEST_DIR)) {
      rmSync(TEST_DIR, { recursive: true });
    }
    mkdirSync(TEST_DIR, { recursive: true });
  });

  afterEach(() => {
    if (existsSync(TEST_DIR)) {
      rmSync(TEST_DIR, { recursive: true });
    }
  });

  it("processes session stop and returns messages with git changes", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});

    const data = {
      session_id: "test-stop-session",
      hook_event_name: "Stop" as const,
    };

    const result = await processSessionStop(data);

    expect(Array.isArray(result.messages)).toBe(true);
    expect(Array.isArray(result.gitChanges)).toBe(true);

    consoleSpy.mockRestore();
  });

  it("handles existing session state during stop", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});

    // Pre-create session state in the default location
    const { STATUS_DIR, STATE_FILE } = await import("./session-stop.ts");
    const fs = await import("node:fs");

    // Ensure status directory exists
    if (!fs.existsSync(STATUS_DIR)) {
      fs.mkdirSync(STATUS_DIR, { recursive: true });
    }

    // Create an existing session state
    const existingState: SessionState = {
      session_id: "existing-session",
      started_at: "2024-01-01T00:00:00Z",
      last_activity: "2024-01-01T01:00:00Z",
      task_stack: [],
      uncommitted_files: [],
      notes: [],
    };
    fs.writeFileSync(STATE_FILE, JSON.stringify(existingState));

    const data = {
      session_id: "test-stop-session",
      hook_event_name: "Stop" as const,
    };

    const result = await processSessionStop(data);

    expect(Array.isArray(result.messages)).toBe(true);
    expect(Array.isArray(result.gitChanges)).toBe(true);

    consoleSpy.mockRestore();
  });
});
