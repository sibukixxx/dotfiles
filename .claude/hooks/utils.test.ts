import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import { mkdirSync, writeFileSync, rmSync, existsSync } from "node:fs";
import {
  isFileModificationTool,
  getGitStatus,
  getGitBranch,
  ensureStatusDir,
  loadSessionState,
  saveSessionState,
  STATUS_DIR,
  STATE_FILE,
} from "./utils.ts";
import type { SessionState } from "./types.ts";

// ============================================
// isFileModificationTool
// ============================================

describe("isFileModificationTool", () => {
  describe("returns true for file modification tools", () => {
    it("returns true for Write", () => {
      expect(isFileModificationTool("Write")).toBe(true);
    });

    it("returns true for Edit", () => {
      expect(isFileModificationTool("Edit")).toBe(true);
    });

    it("returns true for MultiEdit", () => {
      expect(isFileModificationTool("MultiEdit")).toBe(true);
    });
  });

  describe("returns false for non-file-modification tools", () => {
    it("returns false for Read", () => {
      expect(isFileModificationTool("Read")).toBe(false);
    });

    it("returns false for Bash", () => {
      expect(isFileModificationTool("Bash")).toBe(false);
    });

    it("returns false for Glob", () => {
      expect(isFileModificationTool("Glob")).toBe(false);
    });

    it("returns false for Grep", () => {
      expect(isFileModificationTool("Grep")).toBe(false);
    });

    it("returns false for empty string", () => {
      expect(isFileModificationTool("")).toBe(false);
    });

    it("returns false for lowercase write", () => {
      expect(isFileModificationTool("write")).toBe(false);
    });

    it("returns false for WRITE (uppercase)", () => {
      expect(isFileModificationTool("WRITE")).toBe(false);
    });
  });
});

// ============================================
// Git Operations
// ============================================

describe("getGitStatus", () => {
  it("returns an array", async () => {
    const status = await getGitStatus();
    expect(Array.isArray(status)).toBe(true);
  });

  it("returns strings for each changed file", async () => {
    const status = await getGitStatus();
    for (const line of status) {
      expect(typeof line).toBe("string");
      expect(line.length).toBeGreaterThan(0);
    }
  });
});

describe("getGitBranch", () => {
  it("returns a non-empty string in a git repo", async () => {
    const branch = await getGitBranch();
    expect(typeof branch).toBe("string");
    expect(branch.length).toBeGreaterThan(0);
  });

  it("does not contain newlines", async () => {
    const branch = await getGitBranch();
    expect(branch).not.toContain("\n");
  });
});

// ============================================
// Session State I/O
// ============================================

const TEST_DIR = "/tmp/claude-hooks-test-utils";
const TEST_STATE_FILE = `${TEST_DIR}/session_state.json`;

describe("loadSessionState", () => {
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
    writeFileSync(TEST_STATE_FILE, "not valid json {{{");
    const loaded = loadSessionState(TEST_STATE_FILE);
    expect(loaded).toBe(null);
  });

  it("returns null when file does not exist", () => {
    const loaded = loadSessionState(`${TEST_DIR}/nonexistent.json`);
    expect(loaded).toBe(null);
  });

  it("returns null for empty file", () => {
    writeFileSync(TEST_STATE_FILE, "");
    const loaded = loadSessionState(TEST_STATE_FILE);
    expect(loaded).toBe(null);
  });

  it("loads state with current_task", () => {
    const state: SessionState = {
      session_id: "test-456",
      started_at: "2024-01-01T00:00:00Z",
      last_activity: "2024-01-01T01:00:00Z",
      current_task: {
        id: "task-1",
        title: "Test task",
        priority: "p1",
        status: "in_progress",
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:30:00Z",
      },
      task_stack: [],
      uncommitted_files: ["M file.ts"],
      notes: ["note 1"],
    };
    writeFileSync(TEST_STATE_FILE, JSON.stringify(state));
    const loaded = loadSessionState(TEST_STATE_FILE);
    expect(loaded?.current_task?.title).toBe("Test task");
    expect(loaded?.uncommitted_files).toEqual(["M file.ts"]);
  });
});

describe("saveSessionState", () => {
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

  it("saves and can be loaded back", () => {
    const state: SessionState = {
      session_id: "save-test",
      started_at: "2024-01-01T00:00:00Z",
      last_activity: "2024-01-01T01:00:00Z",
      task_stack: [],
      uncommitted_files: ["M file1.ts", "A file2.ts"],
      notes: ["note"],
    };
    saveSessionState(state, TEST_STATE_FILE);
    const loaded = loadSessionState(TEST_STATE_FILE);
    expect(loaded).toEqual(state);
  });

  it("overwrites existing file", () => {
    const state1: SessionState = {
      session_id: "first",
      started_at: "",
      last_activity: "",
      task_stack: [],
      uncommitted_files: [],
      notes: [],
    };
    const state2: SessionState = {
      session_id: "second",
      started_at: "",
      last_activity: "",
      task_stack: [],
      uncommitted_files: [],
      notes: [],
    };
    saveSessionState(state1, TEST_STATE_FILE);
    saveSessionState(state2, TEST_STATE_FILE);
    const loaded = loadSessionState(TEST_STATE_FILE);
    expect(loaded?.session_id).toBe("second");
  });

  it("creates parent directories if they do not exist", () => {
    const deepPath = `${TEST_DIR}/deep/nested/dir/state.json`;
    const state: SessionState = {
      session_id: "deep-test",
      started_at: "",
      last_activity: "",
      task_stack: [],
      uncommitted_files: [],
      notes: [],
    };
    saveSessionState(state, deepPath);
    expect(existsSync(deepPath)).toBe(true);
    const loaded = loadSessionState(deepPath);
    expect(loaded?.session_id).toBe("deep-test");
  });

  it("saves state with pretty-printed JSON (indented)", () => {
    const state: SessionState = {
      session_id: "pretty-test",
      started_at: "",
      last_activity: "",
      task_stack: [],
      uncommitted_files: [],
      notes: [],
    };
    saveSessionState(state, TEST_STATE_FILE);
    const { readFileSync } = require("node:fs");
    const raw = readFileSync(TEST_STATE_FILE, "utf-8");
    expect(raw).toContain("\n");
    expect(raw).toContain("  ");
  });
});

describe("ensureStatusDir", () => {
  it("is a function", () => {
    expect(typeof ensureStatusDir).toBe("function");
  });

  it("does not throw when called", () => {
    expect(() => ensureStatusDir()).not.toThrow();
  });
});
