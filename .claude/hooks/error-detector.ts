import { $ } from "bun";
import { extname } from "node:path";
import { existsSync, writeFileSync, appendFileSync } from "node:fs";
import type {
  FileModificationToolParams,
  PostToolUseHookData,
} from "./types.ts";

export const STATUS_DIR = `${process.env.HOME}/.claude/status`;
export const ERROR_LOG = `${STATUS_DIR}/errors.md`;

export type ErrorInfo = {
  file: string;
  type: "typescript" | "lint" | "test" | "build";
  message: string;
  line?: number;
  suggestion?: string;
};

export function isTypeScriptFile(filePath: string): boolean {
  const ext = extname(filePath);
  return [".ts", ".tsx"].includes(ext);
}

export function isJavaScriptFile(filePath: string): boolean {
  const ext = extname(filePath);
  return [".ts", ".tsx", ".js", ".jsx"].includes(ext);
}

export function isFileModificationTool(toolName: string): boolean {
  return ["Write", "Edit", "MultiEdit"].includes(toolName);
}

export function getSuggestionForError(errorCode: string): string | undefined {
  const suggestions: Record<string, string> = {
    TS2304: "Check if the name is imported or declared",
    TS2339: "Verify the property exists on the type, or add type assertion",
    TS2345: "Check argument types match parameter types",
    TS2322: "Verify the assigned value matches the expected type",
    TS7006: "Add type annotation or enable noImplicitAny: false",
    TS2307: "Check module path and ensure file exists",
    TS1005: "Check for missing syntax elements (brackets, semicolons)",
  };
  return suggestions[errorCode];
}

export function parseTypeScriptError(line: string, filePath: string): ErrorInfo | null {
  const match = line.match(/\((\d+),\d+\):\s*error\s*(TS\d+):\s*(.+)/);
  if (match) {
    return {
      file: filePath,
      type: "typescript",
      line: parseInt(match[1]),
      message: `${match[2]}: ${match[3]}`,
      suggestion: getSuggestionForError(match[2]),
    };
  }
  return null;
}

export async function checkTypeScriptErrors(filePath: string): Promise<ErrorInfo[]> {
  const errors: ErrorInfo[] = [];

  if (!isTypeScriptFile(filePath)) {
    return errors;
  }

  try {
    const tsconfigExists = existsSync("tsconfig.json");
    if (!tsconfigExists) {
      return errors;
    }

    const result = await $`npx tsc --noEmit --pretty false 2>&1`.text();
    const lines = result.split("\n").filter((line) => line.includes(filePath));

    for (const line of lines.slice(0, 5)) {
      const error = parseTypeScriptError(line, filePath);
      if (error) {
        errors.push(error);
      }
    }
  } catch {
    // tsc not available or failed
  }

  return errors;
}

export async function checkLintErrors(filePath: string): Promise<ErrorInfo[]> {
  const errors: ErrorInfo[] = [];

  if (!isJavaScriptFile(filePath)) {
    return errors;
  }

  try {
    const biomeConfigExists = existsSync("biome.json") || existsSync("biome.jsonc");

    if (biomeConfigExists) {
      try {
        await $`npx @biomejs/biome check ${filePath}`.quiet();
      } catch (e) {
        const output = e instanceof Error ? e.message : String(e);
        if (output.includes("error")) {
          errors.push({
            file: filePath,
            type: "lint",
            message: "Biome lint errors detected",
            suggestion: "Run 'npx biome check --write' to auto-fix",
          });
        }
      }
    }
  } catch {
    // Lint not available
  }

  return errors;
}

export function formatErrorLogEntry(errors: ErrorInfo[]): string {
  if (errors.length === 0) return "";

  const timestamp = new Date().toISOString();
  let content = `\n## Errors detected at ${timestamp}\n\n`;

  for (const error of errors) {
    content += `### ${error.file}${error.line ? `:${error.line}` : ""}\n`;
    content += `- **Type**: ${error.type}\n`;
    content += `- **Message**: ${error.message}\n`;
    if (error.suggestion) {
      content += `- **Suggestion**: ${error.suggestion}\n`;
    }
    content += "\n";
  }

  return content;
}

export function logErrors(errors: ErrorInfo[], logFilePath: string = ERROR_LOG): void {
  if (errors.length === 0) return;

  const content = formatErrorLogEntry(errors);

  try {
    if (existsSync(logFilePath)) {
      appendFileSync(logFilePath, content);
    } else {
      writeFileSync(logFilePath, `# Error Log\n${content}`);
    }
  } catch {
    writeFileSync(logFilePath, `# Error Log\n${content}`);
  }
}

export function printErrors(errors: ErrorInfo[], filePath: string): void {
  if (errors.length === 0) return;

  console.log(`\n⚠️  ${errors.length} issue(s) detected in ${filePath}:`);

  for (const error of errors.slice(0, 3)) {
    console.log(`  [${error.type}] ${error.message}`);
    if (error.suggestion) {
      console.log(`  💡 ${error.suggestion}`);
    }
  }

  if (errors.length > 3) {
    console.log(`  ... and ${errors.length - 3} more`);
  }
}

export async function processErrorDetection(
  data: PostToolUseHookData<FileModificationToolParams>
): Promise<ErrorInfo[]> {
  if (!isFileModificationTool(data.tool_name)) {
    return [];
  }

  const filePath = data.tool_input?.file_path;
  if (!filePath) {
    return [];
  }

  const [tsErrors, lintErrors] = await Promise.all([
    checkTypeScriptErrors(filePath),
    checkLintErrors(filePath),
  ]);

  const errors = [...tsErrors, ...lintErrors];

  if (errors.length > 0) {
    printErrors(errors, filePath);
    logErrors(errors);
  }

  return errors;
}

async function main() {
  try {
    const input = await Bun.stdin.text();
    const data: PostToolUseHookData<FileModificationToolParams> = JSON.parse(input);
    await processErrorDetection(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[error-detector]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
