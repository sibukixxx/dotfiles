import { $ } from "bun";
import type {
  FileModificationToolParams,
  PostToolUseHookData,
} from "./types.ts";

// Files to exclude from auto-staging
export const EXCLUDE_PATTERNS = [
  /\.env$/,
  /\.env\..+$/,
  /credentials/i,
  /secrets?/i,
  /\.pem$/,
  /\.key$/,
  /node_modules/,
  /\.git\//,
  /\.DS_Store$/,
];

export function shouldExclude(filePath: string): boolean {
  return EXCLUDE_PATTERNS.some((pattern) => pattern.test(filePath));
}

export async function isInGitRepo(): Promise<boolean> {
  try {
    await $`git rev-parse --is-inside-work-tree`.quiet();
    return true;
  } catch {
    return false;
  }
}

export async function isFileTracked(filePath: string): Promise<boolean> {
  try {
    await $`git ls-files --error-unmatch ${filePath}`.quiet();
    return true;
  } catch {
    return false;
  }
}

export async function gitAddFile(filePath: string): Promise<boolean> {
  try {
    await $`git add ${filePath}`.quiet();
    console.log(`[auto-git-add] Staged: ${filePath}`);
    return true;
  } catch (error) {
    console.error(`[auto-git-add] Failed to stage ${filePath}:`, error);
    return false;
  }
}

export function isFileModificationTool(toolName: string): boolean {
  return ["Write", "Edit", "MultiEdit"].includes(toolName);
}

export async function processAutoGitAdd(
  data: PostToolUseHookData<FileModificationToolParams>
): Promise<{
  action: "staged" | "excluded" | "new_file" | "not_git_repo" | "skipped";
  filePath?: string;
}> {
  // Only process file modification tools
  if (!isFileModificationTool(data.tool_name)) {
    return { action: "skipped" };
  }

  // Check if we're in a git repo
  if (!(await isInGitRepo())) {
    return { action: "not_git_repo" };
  }

  const filePath = data.tool_input?.file_path;
  if (!filePath) {
    return { action: "skipped" };
  }

  // Check exclusion patterns
  if (shouldExclude(filePath)) {
    console.log(`[auto-git-add] Excluded (sensitive): ${filePath}`);
    return { action: "excluded", filePath };
  }

  // Only auto-add if file is already tracked
  const isTracked = await isFileTracked(filePath);

  if (isTracked) {
    await gitAddFile(filePath);
    return { action: "staged", filePath };
  } else {
    console.log(`[auto-git-add] New file (not auto-staged): ${filePath}`);
    console.log(`[auto-git-add] Use 'git add ${filePath}' to stage manually`);
    return { action: "new_file", filePath };
  }
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: PostToolUseHookData<FileModificationToolParams> = JSON.parse(input);
    await processAutoGitAdd(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[auto-git-add error]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
