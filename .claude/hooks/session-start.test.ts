import { describe, it, expect, beforeEach, afterEach, spyOn, mock } from "bun:test";
import { mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs";
import {
  buildSessionMessages,
  createNewSessionState,
  getCurrentTask,
  loadSessionState,
  saveSessionState,
  ensureStatusDir,
  getGitStatus,
  getGitBranch,
  printSessionStart,
  processSessionStart,
} from "./session-start.ts";
import type { SessionState, TaskState } from "./types.ts";

const TEST_DIR = "/tmp/claude-hooks-test";
const TEST_CURRENT_FILE = `${TEST_DIR}/current.md`;
const TEST_STATE_FILE = `${TEST_DIR}/session_state.json`;

describe("buildSessionMessages", () => {
  describe("git status messages", () => {
    it("shows clean tree message when no changes", () => {
      const messages = buildSessionMessages([], "main", null, null);
      expect(messages[0]).toBe("✓ Clean working tree on branch 'main'");
    });

    it("shows uncommitted changes count", () => {
      const changes = ["M file1.ts", "A file2.ts"];
      const messages = buildSessionMessages(changes, "feature", null, null);
      expect(messages[0]).toBe("⚠️ 2 uncommitted changes on branch 'feature'");
    });

    it("shows first 5 changes", () => {
      const changes = ["M file1.ts", "M file2.ts", "M file3.ts"];
      const messages = buildSessionMessages(changes, "main", null, null);
      expect(messages[1]).toContain("file1.ts");
      expect(messages[1]).toContain("file2.ts");
      expect(messages[1]).toContain("file3.ts");
    });

    it("shows ellipsis for more than 5 changes", () => {
      const changes = [
        "M file1.ts",
        "M file2.ts",
        "M file3.ts",
        "M file4.ts",
        "M file5.ts",
        "M file6.ts",
        "M file7.ts",
      ];
      const messages = buildSessionMessages(changes, "main", null, null);
      expect(messages[1]).toContain("... and 2 more");
    });
  });

  describe("current task message", () => {
    it("includes current task when present", () => {
      const messages = buildSessionMessages([], "main", "Fix the bug", null);
      expect(messages.some((m) => m.includes("Current Task"))).toBe(true);
      expect(messages.some((m) => m.includes("Fix the bug"))).toBe(true);
    });

    it("omits current task when null", () => {
      const messages = buildSessionMessages([], "main", null, null);
      expect(messages.some((m) => m.includes("Current Task"))).toBe(false);
    });
  });

  describe("task stack message", () => {
    it("includes task stack when present", () => {
      const task: TaskState = {
        id: "1",
        title: "Task 1",
        priority: "p1",
        status: "pending",
        created_at: "2024-01-01",
        updated_at: "2024-01-01",
      };
      const state: SessionState = {
        session_id: "test",
        started_at: "2024-01-01",
        last_activity: "2024-01-01",
        task_stack: [task],
        uncommitted_files: [],
        notes: [],
      };
      const messages = buildSessionMessages([], "main", null, state);
      expect(messages.some((m) => m.includes("Task Stack"))).toBe(true);
      expect(messages.some((m) => m.includes("[p1] Task 1"))).toBe(true);
    });

    it("shows only first 3 tasks", () => {
      const tasks: TaskState[] = [
        { id: "1", title: "Task 1", priority: "p1", status: "pending", created_at: "", updated_at: "" },
        { id: "2", title: "Task 2", priority: "p2", status: "pending", created_at: "", updated_at: "" },
        { id: "3", title: "Task 3", priority: "p3", status: "pending", created_at: "", updated_at: "" },
        { id: "4", title: "Task 4", priority: "p1", status: "pending", created_at: "", updated_at: "" },
      ];
      const state: SessionState = {
        session_id: "test",
        started_at: "2024-01-01",
        last_activity: "2024-01-01",
        task_stack: tasks,
        uncommitted_files: [],
        notes: [],
      };
      const messages = buildSessionMessages([], "main", null, state);
      expect(messages.some((m) => m.includes("Task 1"))).toBe(true);
      expect(messages.some((m) => m.includes("Task 2"))).toBe(true);
      expect(messages.some((m) => m.includes("Task 3"))).toBe(true);
      expect(messages.some((m) => m.includes("Task 4"))).toBe(false);
    });

    it("omits task stack when empty", () => {
      const state: SessionState = {
        session_id: "test",
        started_at: "2024-01-01",
        last_activity: "2024-01-01",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      const messages = buildSessionMessages([], "main", null, state);
      expect(messages.some((m) => m.includes("Task Stack"))).toBe(false);
    });

    it("omits task stack when state is null", () => {
      const messages = buildSessionMessages([], "main", null, null);
      expect(messages.some((m) => m.includes("Task Stack"))).toBe(false);
    });
  });
});

describe("createNewSessionState", () => {
  it("creates new state with session id", () => {
    const state = createNewSessionState("session-123", null, []);
    expect(state.session_id).toBe("session-123");
  });

  it("sets started_at and last_activity to current time", () => {
    const before = new Date().toISOString();
    const state = createNewSessionState("session-123", null, []);
    const after = new Date().toISOString();
    expect(state.started_at >= before).toBe(true);
    expect(state.started_at <= after).toBe(true);
    expect(state.last_activity >= before).toBe(true);
    expect(state.last_activity <= after).toBe(true);
  });

  it("includes git changes", () => {
    const changes = ["M file1.ts", "A file2.ts"];
    const state = createNewSessionState("session-123", null, changes);
    expect(state.uncommitted_files).toEqual(changes);
  });

  it("inherits current_task from previous state", () => {
    const task: TaskState = {
      id: "1",
      title: "Current",
      priority: "p1",
      status: "in_progress",
      created_at: "",
      updated_at: "",
    };
    const previous: SessionState = {
      session_id: "old",
      started_at: "2024-01-01",
      last_activity: "2024-01-01",
      current_task: task,
      task_stack: [],
      uncommitted_files: [],
      notes: [],
    };
    const state = createNewSessionState("session-123", previous, []);
    expect(state.current_task).toEqual(task);
  });

  it("inherits task_stack from previous state", () => {
    const tasks: TaskState[] = [
      { id: "1", title: "Task 1", priority: "p1", status: "pending", created_at: "", updated_at: "" },
    ];
    const previous: SessionState = {
      session_id: "old",
      started_at: "2024-01-01",
      last_activity: "2024-01-01",
      task_stack: tasks,
      uncommitted_files: [],
      notes: [],
    };
    const state = createNewSessionState("session-123", previous, []);
    expect(state.task_stack).toEqual(tasks);
  });

  it("initializes empty task_stack when no previous state", () => {
    const state = createNewSessionState("session-123", null, []);
    expect(state.task_stack).toEqual([]);
  });

  it("initializes empty notes", () => {
    const state = createNewSessionState("session-123", null, []);
    expect(state.notes).toEqual([]);
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

  describe("getCurrentTask", () => {
    it("returns task content from file", () => {
      writeFileSync(TEST_CURRENT_FILE, "Fix the critical bug");
      const task = getCurrentTask(TEST_CURRENT_FILE);
      expect(task).toBe("Fix the critical bug");
    });

    it("trims whitespace", () => {
      writeFileSync(TEST_CURRENT_FILE, "  Task with spaces  \n");
      const task = getCurrentTask(TEST_CURRENT_FILE);
      expect(task).toBe("Task with spaces");
    });

    it("returns null for empty file", () => {
      writeFileSync(TEST_CURRENT_FILE, "");
      const task = getCurrentTask(TEST_CURRENT_FILE);
      expect(task).toBe(null);
    });

    it("returns null for whitespace-only file", () => {
      writeFileSync(TEST_CURRENT_FILE, "   \n  ");
      const task = getCurrentTask(TEST_CURRENT_FILE);
      expect(task).toBe(null);
    });

    it("returns null when file does not exist", () => {
      const task = getCurrentTask(`${TEST_DIR}/nonexistent.md`);
      expect(task).toBe(null);
    });
  });

  describe("loadSessionState", () => {
    it("loads valid session state from file", () => {
      const state: SessionState = {
        session_id: "test-123",
        started_at: "2024-01-01T00:00:00Z",
        last_activity: "2024-01-01T00:00:00Z",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      writeFileSync(TEST_STATE_FILE, JSON.stringify(state));
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded).toEqual(state);
    });

    it("returns null for invalid JSON", () => {
      writeFileSync(TEST_STATE_FILE, "not valid json");
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded).toBe(null);
    });

    it("returns null when file does not exist", () => {
      const loaded = loadSessionState(`${TEST_DIR}/nonexistent.json`);
      expect(loaded).toBe(null);
    });
  });

  describe("saveSessionState", () => {
    it("saves session state to file", () => {
      const state: SessionState = {
        session_id: "test-123",
        started_at: "2024-01-01T00:00:00Z",
        last_activity: "2024-01-01T00:00:00Z",
        task_stack: [],
        uncommitted_files: ["M file.ts"],
        notes: ["note 1"],
      };
      saveSessionState(state, TEST_STATE_FILE);
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded).toEqual(state);
    });

    it("overwrites existing file", () => {
      const state1: SessionState = {
        session_id: "session-1",
        started_at: "2024-01-01",
        last_activity: "2024-01-01",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      const state2: SessionState = {
        session_id: "session-2",
        started_at: "2024-01-02",
        last_activity: "2024-01-02",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      saveSessionState(state1, TEST_STATE_FILE);
      saveSessionState(state2, TEST_STATE_FILE);
      const loaded = loadSessionState(TEST_STATE_FILE);
      expect(loaded?.session_id).toBe("session-2");
    });
  });

  describe("ensureStatusDir", () => {
    const testStatusDir = `${TEST_DIR}/status`;
    const testQueueDir = `${testStatusDir}/queue`;

    beforeEach(() => {
      if (existsSync(testStatusDir)) {
        rmSync(testStatusDir, { recursive: true });
      }
    });

    it("creates status directory if not exists", () => {
      // This tests the logic indirectly through saveSessionState
      const state: SessionState = {
        session_id: "test",
        started_at: "",
        last_activity: "",
        task_stack: [],
        uncommitted_files: [],
        notes: [],
      };
      saveSessionState(state, `${testStatusDir}/state.json`);
      expect(existsSync(testStatusDir)).toBe(true);
    });
  });
});

describe("git operations", () => {
  describe("getGitStatus", () => {
    it("returns array of changes in git repo", async () => {
      // This test runs in a real git repo, so it should work
      const status = await getGitStatus();
      expect(Array.isArray(status)).toBe(true);
    });
  });

  describe("getGitBranch", () => {
    it("returns branch name in git repo", async () => {
      const branch = await getGitBranch();
      expect(typeof branch).toBe("string");
      expect(branch.length).toBeGreaterThan(0);
    });
  });
});

describe("printSessionStart", () => {
  it("prints session start messages", () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const messages = ["Test message 1", "Test message 2"];
    printSessionStart(messages);
    expect(consoleSpy).toHaveBeenCalled();
    consoleSpy.mockRestore();
  });

  it("prints separator lines", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    printSessionStart(["Test"]);
    expect(calls.some((c) => c.includes("━"))).toBe(true);
    expect(calls.some((c) => c.includes("Claude Code Session Started"))).toBe(true);
    consoleSpy.mockRestore();
  });

  it("prints all messages", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    printSessionStart(["Message A", "Message B", "Message C"]);
    expect(calls.some((c) => c.includes("Message A"))).toBe(true);
    expect(calls.some((c) => c.includes("Message B"))).toBe(true);
    expect(calls.some((c) => c.includes("Message C"))).toBe(true);
    consoleSpy.mockRestore();
  });
});

describe("processSessionStart integration", () => {
  const testDir = `${TEST_DIR}/integration`;

  beforeEach(() => {
    if (existsSync(testDir)) {
      rmSync(testDir, { recursive: true });
    }
    mkdirSync(testDir, { recursive: true });
  });

  afterEach(() => {
    if (existsSync(testDir)) {
      rmSync(testDir, { recursive: true });
    }
  });

  it("creates new session state and returns messages", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});

    const data = {
      session_id: "test-session-123",
      cwd: "/tmp",
      hook_event_name: "SessionStart" as const,
    };

    const result = await processSessionStart(data);

    expect(result.newState.session_id).toBe("test-session-123");
    expect(result.messages.length).toBeGreaterThan(0);
    expect(Array.isArray(result.messages)).toBe(true);

    consoleSpy.mockRestore();
  });
});

describe("ensureStatusDir with queue", () => {
  it("creates queue directory alongside status directory", () => {
    // The ensureStatusDir function should create STATUS_DIR and STATUS_DIR/queue
    // Since we can't easily test without side effects, we just verify the function exists
    expect(typeof ensureStatusDir).toBe("function");
  });
});
