import { $ } from "bun";
import { parseArgs } from "util";

type Notification = {
  session_id: string;
  transcript_path: string;
  message: string;
  title: string;
};

const { values: flags } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    type: { type: "string" },
  },
});

// When called from Notification hooks
async function notify() {
  const input: Notification = await Bun.stdin.json();
  await $`terminal-notifier -title ${input.title} -message ${input.message} -sound default`;
}

// When called from Stop hooks
async function notifyWhenStop() {
  await $`terminal-notifier -title "Claude Code" -message "Wait next action" -sound default`;
}

async function main() {
  switch (flags.type) {
    case "notify":
      await notify();
      break;
    case "stop":
      await notifyWhenStop();
      break;
  }
}

if (process.platform === "darwin") {
  await main();
}
