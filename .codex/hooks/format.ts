import { $ } from "bun";
import { extname } from "node:path";
import { existsSync } from "node:fs";
import type {
  FileModificationToolParams,
  PostToolUseHookData,
} from "./types.ts";
import { isFileModificationTool, readStdinWithTimeout } from "./utils.ts";

export { isFileModificationTool };

export type FormatResult = {
  formatted: boolean;
  formatter?: string;
  error?: string;
};

export function getFileExtension(filePath: string): string {
  return extname(filePath);
}

export function isFormattableExtension(ext: string): boolean {
  const formattable = [".go", ".rs", ".ts", ".tsx", ".js", ".jsx", ".json", ".jsonc", ".swift", ".lua"];
  return formattable.includes(ext);
}

export async function formatGoFile(filePath: string): Promise<FormatResult> {
  try {
    await $`gofmt -w ${filePath}`.quiet();
    console.log(`Formatted Go file: ${filePath}`);
    return { formatted: true, formatter: "gofmt" };
  } catch (error) {
    console.error(`Error formatting ${filePath}:`, error);
    return { formatted: false, error: String(error) };
  }
}

export async function formatRustFile(filePath: string): Promise<FormatResult> {
  try {
    await $`rustfmt ${filePath}`.quiet();
    console.log(`Formatted Rust file: ${filePath}`);
    return { formatted: true, formatter: "rustfmt" };
  } catch (error) {
    console.error(`Error formatting ${filePath}:`, error);
    return { formatted: false, error: String(error) };
  }
}

export async function formatTypeScriptFile(filePath: string): Promise<FormatResult> {
  const nodeModulesExists = existsSync("node_modules");

  if (!nodeModulesExists) {
    console.log(`No node_modules found, skipping format for: ${filePath}`);
    return { formatted: false, error: "no_node_modules" };
  }

  const biomeConfigExists = existsSync("biome.json") || existsSync("biome.jsonc");
  const oxfmtConfigExists = existsSync("oxfmt.toml");

  if (biomeConfigExists) {
    try {
      await $`npx @biomejs/biome format --write ${filePath}`.quiet();
      console.log(`Formatted TypeScript/JavaScript file with Biome: ${filePath}`);
      return { formatted: true, formatter: "biome" };
    } catch {
      // biome not available or failed
    }
  }

  if (oxfmtConfigExists) {
    try {
      await $`npx oxfmt ${filePath}`.quiet();
      console.log(`Formatted TypeScript/JavaScript file with oxfmt: ${filePath}`);
      return { formatted: true, formatter: "oxfmt" };
    } catch {
      // oxfmt not available or failed
    }
  }

  console.log(`No formatter available for: ${filePath}`);
  return { formatted: false, error: "no_formatter" };
}

export async function formatJsonFile(filePath: string): Promise<FormatResult> {
  try {
    await $`jq . ${filePath} > ${filePath}.tmp && mv ${filePath}.tmp ${filePath}`.quiet();
    console.log(`Formatted JSON file with jq: ${filePath}`);
    return { formatted: true, formatter: "jq" };
  } catch {
    console.log(`Failed to format JSON file: ${filePath}`);
    return { formatted: false, error: "jq_failed" };
  }
}

export async function formatSwiftFile(filePath: string): Promise<FormatResult> {
  try {
    await $`swift-format -i ${filePath}`.quiet();
    console.log(`Formatted Swift file: ${filePath}`);
    return { formatted: true, formatter: "swift-format" };
  } catch {
    try {
      await $`swiftformat ${filePath}`.quiet();
      console.log(`Formatted Swift file: ${filePath}`);
      return { formatted: true, formatter: "swiftformat" };
    } catch (error) {
      console.error(`Error formatting ${filePath}:`, error);
      return { formatted: false, error: String(error) };
    }
  }
}

export async function formatLuaFile(filePath: string): Promise<FormatResult> {
  try {
    await $`stylua ${filePath}`.quiet();
    console.log(`Formatted Lua file: ${filePath}`);
    return { formatted: true, formatter: "stylua" };
  } catch (error) {
    console.error(`Error formatting ${filePath}:`, error);
    return { formatted: false, error: String(error) };
  }
}

export async function formatFile(filePath: string): Promise<FormatResult> {
  const ext = getFileExtension(filePath);

  switch (ext) {
    case ".go":
      return formatGoFile(filePath);
    case ".rs":
      return formatRustFile(filePath);
    case ".ts":
    case ".tsx":
    case ".js":
    case ".jsx":
      return formatTypeScriptFile(filePath);
    case ".json":
    case ".jsonc":
      return formatJsonFile(filePath);
    case ".swift":
      return formatSwiftFile(filePath);
    case ".lua":
      return formatLuaFile(filePath);
    default:
      console.log(`No formatter configured for extension: ${ext}`);
      return { formatted: false, error: "unsupported_extension" };
  }
}

export async function processFormat(
  data: PostToolUseHookData<FileModificationToolParams>
): Promise<FormatResult | null> {
  if (!isFileModificationTool(data.tool_name)) {
    return null;
  }

  if (!data.tool_input) {
    return null;
  }

  const filePath = data.tool_input.file_path;
  if (!filePath) {
    return null;
  }

  return formatFile(filePath);
}

async function main() {
  try {
    const data = await readStdinWithTimeout<PostToolUseHookData<FileModificationToolParams>>();
    if (!data) return;
    await processFormat(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[format error]: ${errorMessage}`);
  }
}

if (import.meta.main) {
  await main();
}
