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

// When called from Notification hooks
export async function notify(input: Notification): Promise<void> {
  await $`terminal-notifier -title ${input.title} -message ${input.message} -sound default`;
}

// When called from Stop hooks
export async function notifyWhenStop(): Promise<void> {
  await $`terminal-notifier -title "Claude Code" -message "Wait next action" -sound default`;
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
