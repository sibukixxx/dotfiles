// Type definitions for Claude Code Hooks
// Supports: SessionStart, UserPromptSubmit, PostToolUse, Stop

// Tool response types based on actual log data
export type WriteToolResponse = {
  type: "update" | "create";
  filePath: string;
  content: string;
  structuredPatch: Array<{
    oldStart: number;
    oldLines: number;
    newStart: number;
    newLines: number;
    lines: string[];
  }>;
  userModified: boolean;
};

export type EditToolResponse = {
  filePath: string;
  oldString: string;
  newString: string;
  originalFile: string;
  structuredPatch: Array<{
    oldStart: number;
    oldLines: number;
    newStart: number;
    newLines: number;
    lines: string[];
  }>;
  userModified: boolean;
  replaceAll: boolean;
};

export type MultiEditToolResponse = {
  filePath: string;
  edits: Array<{
    old_string: string;
    new_string: string;
    replace_all: boolean;
  }>;
  originalFileContents: string;
  structuredPatch: Array<{
    oldStart: number;
    oldLines: number;
    newStart: number;
    newLines: number;
    lines: string[];
  }>;
  userModified: boolean;
};

// Union type for all tool responses
export type ToolResponse =
  | WriteToolResponse
  | EditToolResponse
  | MultiEditToolResponse
  | Record<string, unknown>;

// Correct PostToolUse hook data structure based on actual log data
export type PostToolUseHookData<T = ToolParams, R = ToolResponse> = {
  session_id: string;
  transcript_path: string;
  hook_event_name: string;
  tool_name: string;
  tool_input: T;
  tool_response: R;
};

// Base tool parameter types
export type WriteToolParams = {
  file_path: string;
  content: string;
};

export type EditToolParams = {
  file_path: string;
  old_string: string;
  new_string: string;
  replace_all?: boolean;
};

export type MultiEditToolParams = {
  file_path: string;
  edits: Array<{
    old_string: string;
    new_string: string;
    replace_all?: boolean;
  }>;
};

// Union type for all file modification tools
export type FileModificationToolParams =
  | WriteToolParams
  | EditToolParams
  | MultiEditToolParams;

// Type guard functions for tool params
export function isWriteToolParams(params: unknown): params is WriteToolParams {
  return typeof params === "object" && params !== null &&
    "content" in params && "file_path" in params;
}

export function isEditToolParams(params: unknown): params is EditToolParams {
  return typeof params === "object" && params !== null &&
    "old_string" in params && "new_string" in params && "file_path" in params;
}

export function isMultiEditToolParams(
  params: unknown,
): params is MultiEditToolParams {
  return typeof params === "object" && params !== null &&
    "edits" in params &&
    Array.isArray((params as Record<string, unknown>).edits) &&
    "file_path" in params;
}

// Type guard functions for tool responses
export function isWriteToolResponse(
  response: unknown,
): response is WriteToolResponse {
  return typeof response === "object" && response !== null &&
    "type" in response && "filePath" in response && "content" in response;
}

export function isEditToolResponse(
  response: unknown,
): response is EditToolResponse {
  return typeof response === "object" && response !== null &&
    "filePath" in response && "oldString" in response &&
    "newString" in response;
}

export function isMultiEditToolResponse(
  response: unknown,
): response is MultiEditToolResponse {
  return typeof response === "object" && response !== null &&
    "filePath" in response && "edits" in response &&
    Array.isArray((response as Record<string, unknown>).edits);
}

// Generic tool params type for other tools
export type ToolParams = FileModificationToolParams | Record<string, unknown>;

// ============================================
// SessionStart Hook Types
// ============================================
export type SessionStartHookData = {
  session_id: string;
  transcript_path: string;
  hook_event_name: "SessionStart";
  cwd: string;
};

// ============================================
// UserPromptSubmit Hook Types
// ============================================
export type UserPromptSubmitHookData = {
  session_id: string;
  transcript_path: string;
  hook_event_name: "UserPromptSubmit";
  prompt: string;
  cwd: string;
};

// ============================================
// Stop Hook Types
// ============================================
export type StopHookData = {
  session_id: string;
  transcript_path: string;
  hook_event_name: "Stop";
  stop_reason: "end_turn" | "tool_use" | "max_tokens" | "stop_sequence";
  cwd: string;
};

// ============================================
// Union type for all hook data
// ============================================
export type HookData =
  | SessionStartHookData
  | UserPromptSubmitHookData
  | PostToolUseHookData
  | StopHookData;

// ============================================
// State Management Types
// ============================================
export type TaskPriority = "p1" | "p2" | "p3";

export type TaskState = {
  id: string;
  title: string;
  description?: string;
  priority: TaskPriority;
  status: "pending" | "in_progress" | "completed" | "blocked";
  created_at: string;
  updated_at: string;
  context?: Record<string, unknown>;
};

export type SessionState = {
  session_id: string;
  started_at: string;
  last_activity: string;
  current_task?: TaskState;
  task_stack: TaskState[];
  uncommitted_files: string[];
  notes: string[];
};

// ============================================
// Hook Result Types
// ============================================
export type HookResult = {
  success: boolean;
  message?: string;
  inject_context?: string; // Context to inject into conversation
  block?: boolean; // Whether to block the operation
};
