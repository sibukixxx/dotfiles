import { describe, it, expect } from "bun:test";
import {
  isWriteToolParams,
  isEditToolParams,
  isMultiEditToolParams,
  isWriteToolResponse,
  isEditToolResponse,
  isMultiEditToolResponse,
} from "./types.ts";

describe("isWriteToolParams", () => {
  it("returns true for valid WriteToolParams", () => {
    const params = {
      file_path: "/path/to/file.ts",
      content: "file content",
    };
    expect(isWriteToolParams(params)).toBe(true);
  });

  it("returns false when missing file_path", () => {
    const params = { content: "file content" };
    expect(isWriteToolParams(params)).toBe(false);
  });

  it("returns false when missing content", () => {
    const params = { file_path: "/path/to/file.ts" };
    expect(isWriteToolParams(params)).toBe(false);
  });

  it("returns false for null", () => {
    expect(isWriteToolParams(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isWriteToolParams(undefined)).toBe(false);
  });

  it("returns false for non-object", () => {
    expect(isWriteToolParams("string")).toBe(false);
    expect(isWriteToolParams(123)).toBe(false);
    expect(isWriteToolParams(true)).toBe(false);
  });
});

describe("isEditToolParams", () => {
  it("returns true for valid EditToolParams", () => {
    const params = {
      file_path: "/path/to/file.ts",
      old_string: "old",
      new_string: "new",
    };
    expect(isEditToolParams(params)).toBe(true);
  });

  it("returns true with optional replace_all", () => {
    const params = {
      file_path: "/path/to/file.ts",
      old_string: "old",
      new_string: "new",
      replace_all: true,
    };
    expect(isEditToolParams(params)).toBe(true);
  });

  it("returns false when missing file_path", () => {
    const params = { old_string: "old", new_string: "new" };
    expect(isEditToolParams(params)).toBe(false);
  });

  it("returns false when missing old_string", () => {
    const params = { file_path: "/path", new_string: "new" };
    expect(isEditToolParams(params)).toBe(false);
  });

  it("returns false when missing new_string", () => {
    const params = { file_path: "/path", old_string: "old" };
    expect(isEditToolParams(params)).toBe(false);
  });

  it("returns false for null", () => {
    expect(isEditToolParams(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isEditToolParams(undefined)).toBe(false);
  });
});

describe("isMultiEditToolParams", () => {
  it("returns true for valid MultiEditToolParams", () => {
    const params = {
      file_path: "/path/to/file.ts",
      edits: [
        { old_string: "old1", new_string: "new1" },
        { old_string: "old2", new_string: "new2", replace_all: true },
      ],
    };
    expect(isMultiEditToolParams(params)).toBe(true);
  });

  it("returns true with empty edits array", () => {
    const params = {
      file_path: "/path/to/file.ts",
      edits: [],
    };
    expect(isMultiEditToolParams(params)).toBe(true);
  });

  it("returns false when missing file_path", () => {
    const params = { edits: [] };
    expect(isMultiEditToolParams(params)).toBe(false);
  });

  it("returns false when missing edits", () => {
    const params = { file_path: "/path" };
    expect(isMultiEditToolParams(params)).toBe(false);
  });

  it("returns false when edits is not an array", () => {
    const params = { file_path: "/path", edits: "not array" };
    expect(isMultiEditToolParams(params)).toBe(false);
  });

  it("returns false for null", () => {
    expect(isMultiEditToolParams(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isMultiEditToolParams(undefined)).toBe(false);
  });
});

describe("isWriteToolResponse", () => {
  it("returns true for valid WriteToolResponse", () => {
    const response = {
      type: "create",
      filePath: "/path/to/file.ts",
      content: "file content",
      structuredPatch: [],
      userModified: false,
    };
    expect(isWriteToolResponse(response)).toBe(true);
  });

  it("returns true for update type", () => {
    const response = {
      type: "update",
      filePath: "/path/to/file.ts",
      content: "file content",
    };
    expect(isWriteToolResponse(response)).toBe(true);
  });

  it("returns false when missing type", () => {
    const response = { filePath: "/path", content: "content" };
    expect(isWriteToolResponse(response)).toBe(false);
  });

  it("returns false when missing filePath", () => {
    const response = { type: "create", content: "content" };
    expect(isWriteToolResponse(response)).toBe(false);
  });

  it("returns false when missing content", () => {
    const response = { type: "create", filePath: "/path" };
    expect(isWriteToolResponse(response)).toBe(false);
  });

  it("returns false for null", () => {
    expect(isWriteToolResponse(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isWriteToolResponse(undefined)).toBe(false);
  });
});

describe("isEditToolResponse", () => {
  it("returns true for valid EditToolResponse", () => {
    const response = {
      filePath: "/path/to/file.ts",
      oldString: "old",
      newString: "new",
      originalFile: "original content",
      structuredPatch: [],
      userModified: false,
      replaceAll: false,
    };
    expect(isEditToolResponse(response)).toBe(true);
  });

  it("returns false when missing filePath", () => {
    const response = { oldString: "old", newString: "new" };
    expect(isEditToolResponse(response)).toBe(false);
  });

  it("returns false when missing oldString", () => {
    const response = { filePath: "/path", newString: "new" };
    expect(isEditToolResponse(response)).toBe(false);
  });

  it("returns false when missing newString", () => {
    const response = { filePath: "/path", oldString: "old" };
    expect(isEditToolResponse(response)).toBe(false);
  });

  it("returns false for null", () => {
    expect(isEditToolResponse(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isEditToolResponse(undefined)).toBe(false);
  });
});

describe("isMultiEditToolResponse", () => {
  it("returns true for valid MultiEditToolResponse", () => {
    const response = {
      filePath: "/path/to/file.ts",
      edits: [
        { old_string: "old", new_string: "new", replace_all: false },
      ],
      originalFileContents: "original",
      structuredPatch: [],
      userModified: false,
    };
    expect(isMultiEditToolResponse(response)).toBe(true);
  });

  it("returns true with empty edits array", () => {
    const response = {
      filePath: "/path/to/file.ts",
      edits: [],
    };
    expect(isMultiEditToolResponse(response)).toBe(true);
  });

  it("returns false when missing filePath", () => {
    const response = { edits: [] };
    expect(isMultiEditToolResponse(response)).toBe(false);
  });

  it("returns false when missing edits", () => {
    const response = { filePath: "/path" };
    expect(isMultiEditToolResponse(response)).toBe(false);
  });

  it("returns false when edits is not an array", () => {
    const response = { filePath: "/path", edits: "not array" };
    expect(isMultiEditToolResponse(response)).toBe(false);
  });

  it("returns false for null", () => {
    expect(isMultiEditToolResponse(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isMultiEditToolResponse(undefined)).toBe(false);
  });
});
