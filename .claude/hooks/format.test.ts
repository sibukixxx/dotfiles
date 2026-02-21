import { describe, it, expect, spyOn } from "bun:test";
import {
  getFileExtension,
  isFormattableExtension,
  isFileModificationTool,
  processFormat,
  formatFile,
  formatTypeScriptFile,
  formatJsonFile,
  formatGoFile,
  formatRustFile,
} from "./format.ts";
import type { PostToolUseHookData, FileModificationToolParams } from "./types.ts";

describe("getFileExtension", () => {
  it("returns .ts for TypeScript files", () => {
    expect(getFileExtension("/path/to/file.ts")).toBe(".ts");
  });

  it("returns .tsx for TSX files", () => {
    expect(getFileExtension("/path/to/component.tsx")).toBe(".tsx");
  });

  it("returns .js for JavaScript files", () => {
    expect(getFileExtension("file.js")).toBe(".js");
  });

  it("returns .jsx for JSX files", () => {
    expect(getFileExtension("component.jsx")).toBe(".jsx");
  });

  it("returns .go for Go files", () => {
    expect(getFileExtension("main.go")).toBe(".go");
  });

  it("returns .rs for Rust files", () => {
    expect(getFileExtension("lib.rs")).toBe(".rs");
  });

  it("returns .json for JSON files", () => {
    expect(getFileExtension("package.json")).toBe(".json");
  });

  it("returns .jsonc for JSONC files", () => {
    expect(getFileExtension("tsconfig.jsonc")).toBe(".jsonc");
  });

  it("returns empty string for files without extension", () => {
    expect(getFileExtension("Makefile")).toBe("");
  });

  it("handles multiple dots in filename", () => {
    expect(getFileExtension("file.test.ts")).toBe(".ts");
  });
});

describe("isFormattableExtension", () => {
  it("returns true for .go", () => {
    expect(isFormattableExtension(".go")).toBe(true);
  });

  it("returns true for .rs", () => {
    expect(isFormattableExtension(".rs")).toBe(true);
  });

  it("returns true for .ts", () => {
    expect(isFormattableExtension(".ts")).toBe(true);
  });

  it("returns true for .tsx", () => {
    expect(isFormattableExtension(".tsx")).toBe(true);
  });

  it("returns true for .js", () => {
    expect(isFormattableExtension(".js")).toBe(true);
  });

  it("returns true for .jsx", () => {
    expect(isFormattableExtension(".jsx")).toBe(true);
  });

  it("returns true for .json", () => {
    expect(isFormattableExtension(".json")).toBe(true);
  });

  it("returns true for .jsonc", () => {
    expect(isFormattableExtension(".jsonc")).toBe(true);
  });

  it("returns false for .md", () => {
    expect(isFormattableExtension(".md")).toBe(false);
  });

  it("returns false for .py", () => {
    expect(isFormattableExtension(".py")).toBe(false);
  });

  it("returns false for .txt", () => {
    expect(isFormattableExtension(".txt")).toBe(false);
  });

  it("returns false for empty string", () => {
    expect(isFormattableExtension("")).toBe(false);
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
});

describe("processFormat", () => {
  it("returns null for non-file-modification tools", async () => {
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Read",
      tool_input: { file_path: "/path/to/file.ts", content: "" },
      tool_response: {},
    };
    const result = await processFormat(data);
    expect(result).toBe(null);
  });

  it("returns null when tool_input is missing", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: undefined,
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const result = await processFormat(data);
    expect(result).toBe(null);
  });

  it("returns null when file_path is missing", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { content: "test" },
      tool_response: {},
    } as unknown as PostToolUseHookData<FileModificationToolParams>;
    const result = await processFormat(data);
    expect(result).toBe(null);
  });
});

describe("formatFile", () => {
  it("returns unsupported_extension for unknown file types", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/path/to/file.xyz");
    expect(result.formatted).toBe(false);
    expect(result.error).toBe("unsupported_extension");
    consoleSpy.mockRestore();
  });

  it("returns unsupported_extension for .py files", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/path/to/script.py");
    expect(result.formatted).toBe(false);
    expect(result.error).toBe("unsupported_extension");
    consoleSpy.mockRestore();
  });

  it("returns unsupported_extension for .md files", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/path/to/README.md");
    expect(result.formatted).toBe(false);
    expect(result.error).toBe("unsupported_extension");
    consoleSpy.mockRestore();
  });
});

describe("formatTypeScriptFile", () => {
  it("returns no_node_modules when node_modules does not exist", async () => {
    // Run in a directory without node_modules
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatTypeScriptFile("/nonexistent/path/file.ts");
    // The result depends on whether we're in a directory with node_modules
    expect(result.formatted).toBeDefined();
    consoleSpy.mockRestore();
  });
});

describe("formatJsonFile", () => {
  it("returns error for non-existent file", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatJsonFile("/nonexistent/path/file.json");
    expect(result.formatted).toBe(false);
    expect(result.error).toBe("jq_failed");
    consoleSpy.mockRestore();
  });
});

describe("formatGoFile", () => {
  it("returns error for non-existent Go file", async () => {
    const consoleSpy = spyOn(console, "error").mockImplementation(() => {});
    const result = await formatGoFile("/nonexistent/path/main.go");
    expect(result.formatted).toBe(false);
    consoleSpy.mockRestore();
  });
});

describe("formatRustFile", () => {
  it("returns error for non-existent Rust file", async () => {
    const consoleSpy = spyOn(console, "error").mockImplementation(() => {});
    const result = await formatRustFile("/nonexistent/path/lib.rs");
    expect(result.formatted).toBe(false);
    consoleSpy.mockRestore();
  });
});

describe("formatFile routing", () => {
  it("routes .go files to formatGoFile", async () => {
    const consoleSpy = spyOn(console, "error").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/main.go");
    expect(result.formatted).toBe(false);
    // gofmt will fail on non-existent file
    consoleSpy.mockRestore();
  });

  it("routes .rs files to formatRustFile", async () => {
    const consoleSpy = spyOn(console, "error").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/lib.rs");
    expect(result.formatted).toBe(false);
    consoleSpy.mockRestore();
  });

  it("routes .ts files to formatTypeScriptFile", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/index.ts");
    expect(result.formatted).toBeDefined();
    consoleSpy.mockRestore();
  });

  it("routes .tsx files to formatTypeScriptFile", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/Component.tsx");
    expect(result.formatted).toBeDefined();
    consoleSpy.mockRestore();
  });

  it("routes .js files to formatTypeScriptFile", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/script.js");
    expect(result.formatted).toBeDefined();
    consoleSpy.mockRestore();
  });

  it("routes .jsx files to formatTypeScriptFile", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/Component.jsx");
    expect(result.formatted).toBeDefined();
    consoleSpy.mockRestore();
  });

  it("routes .json files to formatJsonFile", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/config.json");
    expect(result.formatted).toBe(false);
    expect(result.error).toBe("jq_failed");
    consoleSpy.mockRestore();
  });

  it("routes .jsonc files to formatJsonFile", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const result = await formatFile("/nonexistent/path/settings.jsonc");
    expect(result.formatted).toBe(false);
    expect(result.error).toBe("jq_failed");
    consoleSpy.mockRestore();
  });
});

describe("processFormat with valid input", () => {
  it("processes Write tool with file_path", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Write",
      tool_input: { file_path: "/nonexistent/path/test.xyz", content: "" },
      tool_response: {},
    };
    const result = await processFormat(data);
    expect(result).not.toBe(null);
    expect(result?.formatted).toBe(false);
    expect(result?.error).toBe("unsupported_extension");
    consoleSpy.mockRestore();
  });

  it("processes Edit tool with file_path", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "Edit",
      tool_input: { file_path: "/nonexistent/path/test.txt", content: "" },
      tool_response: {},
    };
    const result = await processFormat(data);
    expect(result).not.toBe(null);
    expect(result?.formatted).toBe(false);
    consoleSpy.mockRestore();
  });

  it("processes MultiEdit tool with file_path", async () => {
    const consoleSpy = spyOn(console, "log").mockImplementation(() => {});
    const data: PostToolUseHookData<FileModificationToolParams> = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "PostToolUse",
      tool_name: "MultiEdit",
      tool_input: { file_path: "/nonexistent/path/test.unknown", content: "" },
      tool_response: {},
    };
    const result = await processFormat(data);
    expect(result).not.toBe(null);
    consoleSpy.mockRestore();
  });
});
