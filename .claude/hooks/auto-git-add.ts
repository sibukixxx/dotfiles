import { $ } from "bun";
import type {
  FileModificationToolParams,
  PostToolUseHookData,
} from "./types.ts";

// Files to exclude from auto-staging
const EXCLUDE_PATTERNS = [
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

function shouldExclude(filePath: string): boolean {
  return EXCLUDE_PATTERNS.some((pattern) => pattern.test(filePath));
}

async function isInGitRepo(): Promise<boolean> {
  try {
    await $`git rev-parse --is-inside-work-tree`.quiet();
    return true;
  } catch {
    return false;
  }
}

async function isFileTracked(filePath: string): Promise<boolean> {
  try {
    await $`git ls-files --error-unmatch ${filePath}`.quiet();
    return true;
  } catch {
    return false;
  }
}

async function gitAddFile(filePath: string): Promise<void> {
  try {
    await $`git add ${filePath}`.quiet();
    console.log(`[auto-git-add] Staged: ${filePath}`);
  } catch (error) {
    console.error(`[auto-git-add] Failed to stage ${filePath}:`, error);
  }
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: PostToolUseHookData<FileModificationToolParams> = JSON.parse(input);

    // Only process file modification tools
    if (!["Write", "Edit", "MultiEdit"].includes(data.tool_name)) {
      return;
    }

    // Check if we're in a git repo
    if (!(await isInGitRepo())) {
      return;
    }

    const filePath = data.tool_input?.file_path;
    if (!filePath) {
      return;
    }

    // Check exclusion patterns
    if (shouldExclude(filePath)) {
      console.log(`[auto-git-add] Excluded (sensitive): ${filePath}`);
      return;
    }

    // Only auto-add if file is already tracked (avoid adding new untracked files)
    const isTracked = await isFileTracked(filePath);

    if (isTracked) {
      await gitAddFile(filePath);
    } else {
      // For new files, just notify
      console.log(`[auto-git-add] New file (not auto-staged): ${filePath}`);
      console.log(`[auto-git-add] Use 'git add ${filePath}' to stage manually`);
    }
  } catch (error) {
    // Fail silently - don't block tool execution
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[auto-git-add error]: ${errorMessage}`);
  }
}

await main();
