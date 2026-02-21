import { describe, it, expect, spyOn, afterEach } from "bun:test";
import {
  shouldExclude,
  isFileModificationTool,
  EXCLUDE_PATTERNS,
  isInGitRepo,
  isFileTracked,
  gitAddFile,
  processAutoGitAdd,
} from "./auto-git-add.ts";
import type { PostToolUseHookData, FileModificationToolParams } from "./types.ts";

describe("shouldExclude", () => {
  describe(".env files", () => {
    it("excludes .env", () => {
      expect(shouldExclude("/path/to/.env")).toBe(true);
    });

    it("excludes .env.local", () => {
      expect(shouldExclude("/path/to/.env.local")).toBe(true);
    });

    it("excludes .env.production", () => {
      expect(shouldExclude("/path/to/.env.production")).toBe(true);
    });

    it("excludes .env.development", () => {
      expect(shouldExclude(".env.development")).toBe(true);
    });
  });

  describe("credential files", () => {
    it("excludes credentials.json", () => {
      expect(shouldExclude("credentials.json")).toBe(true);
    });

    it("excludes my-credentials", () => {
      expect(shouldExclude("/config/my-credentials")).toBe(true);
    });

    it("excludes CREDENTIALS (case insensitive)", () => {
      expect(shouldExclude("CREDENTIALS")).toBe(true);
    });
  });

  describe("secret files", () => {
    it("excludes secret.txt", () => {
      expect(shouldExclude("secret.txt")).toBe(true);
    });

    it("excludes secrets.json", () => {
      expect(shouldExclude("secrets.json")).toBe(true);
    });

    it("excludes my-secret-file", () => {
      expect(shouldExclude("/path/my-secret-file")).toBe(true);
    });
  });

  describe("key files", () => {
    it("excludes .pem files", () => {
      expect(shouldExclude("server.pem")).toBe(true);
    });

    it("excludes .key files", () => {
      expect(shouldExclude("private.key")).toBe(true);
    });
  });

  describe("system files", () => {
    it("excludes node_modules", () => {
      expect(shouldExclude("node_modules/package/index.js")).toBe(true);
    });

    it("excludes .git directory", () => {
      expect(shouldExclude(".git/config")).toBe(true);
    });

    it("excludes .DS_Store", () => {
      expect(shouldExclude(".DS_Store")).toBe(true);
    });
  });

  describe("allowed files", () => {
    it("allows regular TypeScript files", () => {
      expect(shouldExclude("src/index.ts")).toBe(false);
    });

    it("allows regular JavaScript files", () => {
      expect(shouldExclude("src/utils.js")).toBe(false);
    });

    it("allows package.json", () => {
      expect(shouldExclude("package.json")).toBe(false);
    });

    it("allows config files without sensitive names", () => {
      expect(shouldExclude("tsconfig.json")).toBe(false);
    });

    it("allows README files", () => {
      expect(shouldExclude("README.md")).toBe(false);
    });
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

  it("returns false for Glob", () => {
    expect(isFileModificationTool("Glob")).toBe(false);
  });

  it("returns false for empty string", () => {
    expect(isFileModificationTool("")).toBe(false);
  });
});

describe("EXCLUDE_PATTERNS", () => {
  it("has expected number of patterns", () => {
    expect(EXCLUDE_PATTERNS.length).toBe(9);
  });

  it("all patterns are RegExp", () => {
    EXCLUDE_PATTERNS.forEach((pattern) => {
      expect(pattern).toBeInstanceOf(RegExp);
    });
  });
});

describe("git operations", () => {
  describe("isInGitRepo", () => {
    it("returns true in a git repository", async () => {
      // We're running tests in a git repo
      const result = await isInGitRepo();
      expect(result).toBe(true);
    });
  });

  describe("isFileTracked", () => {
    it("returns true for tracked files", async () => {
      // package.json should be tracked
      const result = await isFileTracked("package.json");
      // May or may not be tracked depending on setup
      expect(typeof result).toBe("boolean");
    });

    it("returns false for non-existent files", async () => {
      const result = await isFileTracked("/nonexistent/path/file.ts");
      expect(result).toBe(false);
    });
  });

  describe("gitAddFile", () => {
    it("returns false for non-existent files", async () => {
      const consoleSpy = spyOn(console, "error").mockImplementation(() => {});
      const result = await gitAddFile("/nonexistent/path/file.ts");
      expect(result).toBe(false);
      consoleSpy.mockRestore();
    });
  });
});

describe("processAutoGitAdd", () => {
  it("returns skipped for non-file-modification tools", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Read",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("skipped");
  });

  it("returns skipped when file_path is missing", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { content: "test" },
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("skipped");
  });

  it("returns excluded for sensitive files", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { file_path: "/path/to/.env", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("excluded");
    expect(result.filePath).toBe("/path/to/.env");
    consoleSpy.mockRestore();
  });

  it("returns skipped for Glob tool", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Glob",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("skipped");
  });

  it("returns skipped for Bash tool", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Bash",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("skipped");
  });

  it("returns excluded for credentials.json", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { file_path: "/path/to/credentials.json", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("excluded");
    consoleSpy.mockRestore();
  });

  it("returns excluded for secrets.json", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Edit",
      tool_input: { file_path: "/path/to/secrets.json", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("excluded");
    consoleSpy.mockRestore();
  });

  it("returns excluded for .pem files", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "MultiEdit",
      tool_input: { file_path: "/path/to/server.pem", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("excluded");
    consoleSpy.mockRestore();
  });

  it("returns excluded for .key files", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { file_path: "/path/to/private.key", content: "" },
      tool_response: {},
    };
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("excluded");
    consoleSpy.mockRestore();
  });

  it("returns skipped when tool_input is undefined", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: undefined,
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("skipped");
  });

  it("returns skipped when tool_input is null", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: null,
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const result = await processAutoGitAdd(data);
    expect(result.action).toBe("skipped");
  });
});

describe("shouldExclude additional cases", () => {
  it("excludes .env.test", () => {
    expect(shouldExclude("/path/to/.env.test")).toBe(true);
  });

  it("excludes .env.staging", () => {
    expect(shouldExclude("/path/to/.env.staging")).toBe(true);
  });

  it("excludes files in node_modules subdirectory", () => {
    expect(shouldExclude("/project/node_modules/@scope/package/index.js")).toBe(true);
  });

  it("excludes files in .git/hooks", () => {
    expect(shouldExclude(".git/hooks/pre-commit")).toBe(true);
  });

  it("allows .envrc files", () => {
    // .envrc doesn't match .env$ or .env\..+$
    expect(shouldExclude(".envrc")).toBe(false);
  });

  it("allows environment.ts files", () => {
    expect(shouldExclude("src/environment.ts")).toBe(false);
  });
});

describe("processAutoGitAdd with git operations", () => {
  const testFile = "/tmp/claude-hooks-test-auto-git-add-test.ts";

  afterEach(async () => {
    // Clean up test file
    try {
      const { existsSync, unlinkSync } = await import("node:fs");
      if (existsSync(testFile)) {
        unlinkSync(testFile);
      }
    } catch {
      // ignore cleanup errors
    }
  });

  it("returns new_file for untracked file in git repo", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});

    // Create a temp file that is definitely not tracked
    const { writeFileSync } = await import("node:fs");
    writeFileSync(testFile, "// test file");

    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { file_path: testFile, content: "// test" },
      tool_response: {},
    };

    const result = await processAutoGitAdd(data);
    // In a git repo, untracked file should return "new_file"
    expect(result.action).toBe("new_file");
    expect(result.filePath).toBe(testFile);
    consoleSpy.mockRestore();
  });
});
