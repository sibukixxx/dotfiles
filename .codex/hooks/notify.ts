import { $ } from "bun";
import { parseArgs } from "util";

export type Notification = {
  session_id: string;
  transcript_path: string;
  message: string;
  title: string;
};

export type NotifyFlags = {
  type?: string;
};

export function parseNotifyFlags(args: string[]): NotifyFlags {
  const { values } = parseArgs({
    args,
    options: {
      type: { type: "string" },
    },
  });
  return values;
}

// macOS 標準の osascript で通知する (追加インストール不要)。
// title / message は AppleScript のソースに埋め込まず argv で渡す (クォートによるインジェクション防止)
export function buildNotificationArgs(title: string, message: string): string[] {
  return [
    "osascript",
    "-e", "on run argv",
    "-e", 'display notification (item 2 of argv) with title (item 1 of argv) sound name "default"',
    "-e", "end run",
    title,
    message,
  ];
}

// 通知は補助機能なので、失敗 (通知が OFF 等) しても hook をエラーにしない
async function sendNotification(title: string, message: string): Promise<void> {
  await $`${buildNotificationArgs(title, message)}`.nothrow().quiet();
}

// When called from Notification hooks
export async function notify(input: Notification): Promise<void> {
  await sendNotification(input.title, input.message);
}

// When called from Stop hooks
export async function notifyWhenStop(): Promise<void> {
  await sendNotification("Claude Code", "Wait next action");
}

export async function main(flags: NotifyFlags): Promise<void> {
  switch (flags.type) {
    case "notify": {
      const input: Notification = await Bun.stdin.json();
      await notify(input);
      break;
    }
    case "stop":
      await notifyWhenStop();
      break;
  }
}

if (import.meta.main && process.platform === "darwin") {
  const flags = parseNotifyFlags(Bun.argv.slice(2));
  await main(flags);
}
