import { describe, it, expect, beforeEach, afterEach, spyOn } from "bun:test";
import { mkdirSync, writeFileSync, rmSync, existsSync, readFileSync } from "node:fs";
import {
  isTypeScriptFile,
  isJavaScriptFile,
  isFileModificationTool,
  getSuggestionForError,
  parseTypeScriptError,
  formatErrorLogEntry,
  logErrors,
  processErrorDetection,
  printErrors,
  checkTypeScriptErrors,
  checkLintErrors,
  type ErrorInfo,
} from "./error-detector.ts";
import type { PostToolUseHookData, FileModificationToolParams } from "./types.ts";

const TEST_DIR = "/tmp/claude-hooks-test-error";
const TEST_LOG_FILE = `${TEST_DIR}/errors.md`;

describe("isTypeScriptFile", () => {
  it("returns true for .ts files", () => {
    expect(isTypeScriptFile("/path/to/file.ts")).toBe(true);
  });

  it("returns true for .tsx files", () => {
    expect(isTypeScriptFile("/path/to/component.tsx")).toBe(true);
  });

  it("returns false for .js files", () => {
    expect(isTypeScriptFile("/path/to/file.js")).toBe(false);
  });

  it("returns false for .jsx files", () => {
    expect(isTypeScriptFile("/path/to/component.jsx")).toBe(false);
  });

  it("returns false for .go files", () => {
    expect(isTypeScriptFile("/path/to/main.go")).toBe(false);
  });
});

describe("isJavaScriptFile", () => {
  it("returns true for .ts files", () => {
    expect(isJavaScriptFile("/path/to/file.ts")).toBe(true);
  });

  it("returns true for .tsx files", () => {
    expect(isJavaScriptFile("/path/to/component.tsx")).toBe(true);
  });

  it("returns true for .js files", () => {
    expect(isJavaScriptFile("/path/to/file.js")).toBe(true);
  });

  it("returns true for .jsx files", () => {
    expect(isJavaScriptFile("/path/to/component.jsx")).toBe(true);
  });

  it("returns false for .go files", () => {
    expect(isJavaScriptFile("/path/to/main.go")).toBe(false);
  });

  it("returns false for .py files", () => {
    expect(isJavaScriptFile("/path/to/script.py")).toBe(false);
  });
});

describe("isFileModificationTool", () => {
  it("returns true for Write", () => {
    expect(isFileModificationTool("Write")).toBe(true);
  });

  it("returns true for Edit", () => {
    expect(isFileModificationTool("Edit")).toBe(true);
  });

  it("returns true for MultiEdit", () => {
    expect(isFileModificationTool("MultiEdit")).toBe(true);
  });

  it("returns false for Read", () => {
    expect(isFileModificationTool("Read")).toBe(false);
  });

  it("returns false for Bash", () => {
    expect(isFileModificationTool("Bash")).toBe(false);
  });
});

describe("getSuggestionForError", () => {
  it("returns suggestion for TS2304", () => {
    expect(getSuggestionForError("TS2304")).toContain("imported");
  });

  it("returns suggestion for TS2339", () => {
    expect(getSuggestionForError("TS2339")).toContain("property");
  });

  it("returns suggestion for TS2345", () => {
    expect(getSuggestionForError("TS2345")).toContain("argument");
  });

  it("returns suggestion for TS2322", () => {
    expect(getSuggestionForError("TS2322")).toContain("assigned");
  });

  it("returns suggestion for TS7006", () => {
    expect(getSuggestionForError("TS7006")).toContain("annotation");
  });

  it("returns suggestion for TS2307", () => {
    expect(getSuggestionForError("TS2307")).toContain("module");
  });

  it("returns suggestion for TS1005", () => {
    expect(getSuggestionForError("TS1005")).toContain("syntax");
  });

  it("returns undefined for unknown error code", () => {
    expect(getSuggestionForError("TS9999")).toBe(undefined);
  });
});

describe("parseTypeScriptError", () => {
  it("parses TypeScript error line correctly", () => {
    const line = "src/index.ts(10,5): error TS2304: Cannot find name 'foo'.";
    const error = parseTypeScriptError(line, "src/index.ts");
    expect(error).not.toBe(null);
    expect(error?.file).toBe("src/index.ts");
    expect(error?.type).toBe("typescript");
    expect(error?.line).toBe(10);
    expect(error?.message).toContain("TS2304");
    expect(error?.message).toContain("Cannot find name");
  });

  it("returns null for non-matching line", () => {
    const line = "Some random output";
    const error = parseTypeScriptError(line, "src/index.ts");
    expect(error).toBe(null);
  });

  it("includes suggestion for known error codes", () => {
    const line = "src/index.ts(5,1): error TS2304: Cannot find name 'x'.";
    const error = parseTypeScriptError(line, "src/index.ts");
    expect(error?.suggestion).toBeDefined();
  });
});

describe("formatErrorLogEntry", () => {
  it("returns empty string for empty errors array", () => {
    expect(formatErrorLogEntry([])).toBe("");
  });

  it("formats single error correctly", () => {
    const errors: ErrorInfo[] = [{
      file: "src/index.ts",
      type: "typescript",
      line: 10,
      message: "TS2304: Cannot find name 'foo'",
      suggestion: "Check if imported",
    }];
    const entry = formatErrorLogEntry(errors);
    expect(entry).toContain("### src/index.ts:10");
    expect(entry).toContain("**Type**: typescript");
    expect(entry).toContain("**Message**: TS2304");
    expect(entry).toContain("**Suggestion**: Check if imported");
  });

  it("formats error without line number", () => {
    const errors: ErrorInfo[] = [{
      file: "src/index.ts",
      type: "lint",
      message: "Lint error",
    }];
    const entry = formatErrorLogEntry(errors);
    expect(entry).toContain("### src/index.ts\n");
  });

  it("formats multiple errors", () => {
    const errors: ErrorInfo[] = [
      { file: "file1.ts", type: "typescript", message: "Error 1" },
      { file: "file2.ts", type: "lint", message: "Error 2" },
    ];
    const entry = formatErrorLogEntry(errors);
    expect(entry).toContain("### file1.ts");
    expect(entry).toContain("### file2.ts");
  });

  it("omits suggestion when not present", () => {
    const errors: ErrorInfo[] = [{
      file: "src/index.ts",
      type: "typescript",
      message: "Error",
    }];
    const entry = formatErrorLogEntry(errors);
    expect(entry).not.toContain("**Suggestion**");
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

  describe("logErrors", () => {
    it("does nothing for empty errors array", () => {
      logErrors([], TEST_LOG_FILE);
      expect(existsSync(TEST_LOG_FILE)).toBe(false);
    });

    it("creates new log file when it does not exist", () => {
      const errors: ErrorInfo[] = [{
        file: "test.ts",
        type: "typescript",
        message: "Test error",
      }];
      logErrors(errors, TEST_LOG_FILE);
      expect(existsSync(TEST_LOG_FILE)).toBe(true);
      const content = readFileSync(TEST_LOG_FILE, "utf-8");
      expect(content).toContain("# Error Log");
      expect(content).toContain("Test error");
    });

    it("appends to existing log file", () => {
      writeFileSync(TEST_LOG_FILE, "# Error Log\n\n");
      const errors1: ErrorInfo[] = [{ file: "test1.ts", type: "typescript", message: "Error 1" }];
      const errors2: ErrorInfo[] = [{ file: "test2.ts", type: "lint", message: "Error 2" }];
      logErrors(errors1, TEST_LOG_FILE);
      logErrors(errors2, TEST_LOG_FILE);
      const content = readFileSync(TEST_LOG_FILE, "utf-8");
      expect(content).toContain("Error 1");
      expect(content).toContain("Error 2");
    });
  });
});

describe("processErrorDetection", () => {
  it("returns empty array for non-file-modification tools", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Read",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const errors = await processErrorDetection(data);
    expect(errors).toEqual([]);
  });

  it("returns empty array when file_path is missing", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { content: "test" },
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const errors = await processErrorDetection(data);
    expect(errors).toEqual([]);
  });
});

describe("printErrors", () => {
  it("does nothing for empty errors array", () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    printErrors([], "/path/to/file.ts");
    expect(consoleSpy).not.toHaveBeenCalled();
    consoleSpy.mockRestore();
  });

  it("prints error count and messages", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    const errors: ErrorInfo[] = [{
      file: "test.ts",
      type: "typescript",
      message: "Test error",
    }];
    printErrors(errors, "test.ts");
    expect(calls.some((c) => c.includes("1 issue(s)"))).toBe(true);
    expect(calls.some((c) => c.includes("typescript"))).toBe(true);
    consoleSpy.mockRestore();
  });

  it("shows only first 3 errors", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    const errors: ErrorInfo[] = [
      { file: "test.ts", type: "typescript", message: "Error 1" },
      { file: "test.ts", type: "typescript", message: "Error 2" },
      { file: "test.ts", type: "typescript", message: "Error 3" },
      { file: "test.ts", type: "typescript", message: "Error 4" },
      { file: "test.ts", type: "typescript", message: "Error 5" },
    ];
    printErrors(errors, "test.ts");
    expect(calls.some((c) => c.includes("... and 2 more"))).toBe(true);
    consoleSpy.mockRestore();
  });

  it("prints suggestions when present", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    const errors: ErrorInfo[] = [{
      file: "test.ts",
      type: "typescript",
      message: "Test error",
      suggestion: "Fix this error",
    }];
    printErrors(errors, "test.ts");
    expect(calls.some((c) => c.includes("Fix this error"))).toBe(true);
    consoleSpy.mockRestore();
  });
});

describe("checkTypeScriptErrors", () => {
  it("returns empty array for non-TypeScript files", async () => {
    const errors = await checkTypeScriptErrors("/path/to/file.js");
    expect(errors).toEqual([]);
  });

  it("returns empty array for Go files", async () => {
    const errors = await checkTypeScriptErrors("/path/to/main.go");
    expect(errors).toEqual([]);
  });
});

describe("checkLintErrors", () => {
  it("returns empty array for non-JavaScript files", async () => {
    const errors = await checkLintErrors("/path/to/main.go");
    expect(errors).toEqual([]);
  });

  it("returns empty array for Python files", async () => {
    const errors = await checkLintErrors("/path/to/script.py");
    expect(errors).toEqual([]);
  });

  it("returns empty array for Rust files", async () => {
    const errors = await checkLintErrors("/path/to/lib.rs");
    expect(errors).toEqual([]);
  });
});

describe("logErrors edge cases", () => {
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

  it("handles initial write with error log header", () => {
    const logPath = `${TEST_DIR}/new-errors.md`;
    const errors: ErrorInfo[] = [{
      file: "test.ts",
      type: "typescript",
      message: "Error message",
    }];
    logErrors(errors, logPath);
    const content = readFileSync(logPath, "utf-8");
    expect(content).toContain("# Error Log");
    expect(content).toContain("Error message");
  });
});

describe("processErrorDetection comprehensive", () => {
  it("returns empty array for Bash tool", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Bash",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const errors = await processErrorDetection(data);
    expect(errors).toEqual([]);
  });

  it("returns empty array for Glob tool", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Glob",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const errors = await processErrorDetection(data);
    expect(errors).toEqual([]);
  });

  it("returns empty array when tool_input is null", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: null,
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const errors = await processErrorDetection(data);
    expect(errors).toEqual([]);
  });
});

describe("printErrors edge cases", () => {
  it("prints exactly 3 errors without 'more' message", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    const errors: ErrorInfo[] = [
      { file: "test.ts", type: "typescript", message: "Error 1" },
      { file: "test.ts", type: "typescript", message: "Error 2" },
      { file: "test.ts", type: "typescript", message: "Error 3" },
    ];
    printErrors(errors, "test.ts");
    expect(calls.some((c) => c.includes("... and"))).toBe(false);
    expect(calls.some((c) => c.includes("3 issue(s)"))).toBe(true);
    consoleSpy.mockRestore();
  });

  it("handles error without suggestion", () => {
    const calls: string[] = [];
    const consoleSpy = spyOn(console, "log").mockImplementation((msg) => {
      calls.push(String(msg));
    });
    const errors: ErrorInfo[] = [{
      file: "test.ts",
      type: "lint",
      message: "Lint error without suggestion",
    }];
    printErrors(errors, "test.ts");
    expect(calls.some((c) => c.includes("lint"))).toBe(true);
    consoleSpy.mockRestore();
  });
});

describe("parseTypeScriptError edge cases", () => {
  it("parses error with TS2339 code", () => {
    const line = "src/file.ts(20,10): error TS2339: Property 'foo' does not exist on type 'Bar'.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.line).toBe(20);
    expect(error?.message).toContain("TS2339");
    expect(error?.suggestion).toContain("property");
  });

  it("parses error with TS2345 code", () => {
    const line = "src/file.ts(15,5): error TS2345: Argument of type 'string' is not assignable.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.suggestion).toContain("argument");
  });

  it("parses error with TS2322 code", () => {
    const line = "src/file.ts(8,3): error TS2322: Type 'number' is not assignable to type 'string'.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.suggestion).toContain("assigned");
  });

  it("parses error with TS7006 code", () => {
    const line = "src/file.ts(1,10): error TS7006: Parameter 'x' implicitly has an 'any' type.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.suggestion).toContain("annotation");
  });

  it("parses error with TS2307 code", () => {
    const line = "src/file.ts(1,1): error TS2307: Cannot find module 'foo'.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.suggestion).toContain("module");
  });

  it("parses error with TS1005 code", () => {
    const line = "src/file.ts(5,20): error TS1005: ';' expected.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.suggestion).toContain("syntax");
  });

  it("returns error without suggestion for unknown code", () => {
    const line = "src/file.ts(1,1): error TS9999: Unknown error.";
    const error = parseTypeScriptError(line, "src/file.ts");
    expect(error).not.toBe(null);
    expect(error?.suggestion).toBeUndefined();
  });
});

describe("formatErrorLogEntry edge cases", () => {
  it("formats error with line number", () => {
    const errors: ErrorInfo[] = [{
      file: "test.ts",
      type: "typescript",
      line: 42,
      message: "Error on line 42",
    }];
    const entry = formatErrorLogEntry(errors);
    expect(entry).toContain("### test.ts:42");
    expect(entry).toContain("Error on line 42");
  });

  it("includes timestamp in entry", () => {
    const errors: ErrorInfo[] = [{
      file: "test.ts",
      type: "lint",
      message: "Lint error",
    }];
    const entry = formatErrorLogEntry(errors);
    expect(entry).toContain("Errors detected at");
  });
});
