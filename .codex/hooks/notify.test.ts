import { describe, it, expect } from "bun:test";
import { buildNotificationArgs, parseNotifyFlags } from "./notify.ts";
import type { Notification, NotifyFlags } from "./notify.ts";

// ============================================
// Notification type
// ============================================

describe("Notification type", () => {
  it("accepts valid notification object", () => {
    const notification: Notification = {
      session_id: "session-123",
      transcript_path: "/tmp/transcript",
      message: "Task completed",
      title: "Claude Code",
    };
    expect(notification.session_id).toBe("session-123");
    expect(notification.message).toBe("Task completed");
    expect(notification.title).toBe("Claude Code");
    expect(notification.transcript_path).toBe("/tmp/transcript");
  });
});

// ============================================
// parseNotifyFlags
// ============================================

describe("parseNotifyFlags", () => {
  it("parses --type notify flag", () => {
    const flags = parseNotifyFlags(["--type", "notify"]);
    expect(flags.type).toBe("notify");
  });

  it("parses --type stop flag", () => {
    const flags = parseNotifyFlags(["--type", "stop"]);
    expect(flags.type).toBe("stop");
  });

  it("returns undefined type when no flag provided", () => {
    const flags = parseNotifyFlags([]);
    expect(flags.type).toBeUndefined();
  });

  it("parses --type with arbitrary string value", () => {
    const flags = parseNotifyFlags(["--type", "custom"]);
    expect(flags.type).toBe("custom");
  });

  it("handles --type=value syntax", () => {
    const flags = parseNotifyFlags(["--type=notify"]);
    expect(flags.type).toBe("notify");
  });
});

// ============================================
// buildNotificationArgs
// ============================================

describe("buildNotificationArgs", () => {
  it("builds osascript args passing title and message via argv", () => {
    const args = buildNotificationArgs("Claude Code", "Wait next action");
    expect(args[0]).toBe("osascript");
    expect(args.slice(-2)).toEqual(["Claude Code", "Wait next action"]);
  });

  it("does not embed title or message in the AppleScript source when they contain quotes", () => {
    const args = buildNotificationArgs('a"b', 'x" & do shell script "id');
    const script = args.filter((_, i) => args[i - 1] === "-e").join("\n");
    expect(script).not.toContain('a"b');
    expect(script).not.toContain("do shell script");
    expect(args.slice(-2)).toEqual(['a"b', 'x" & do shell script "id']);
  });
});

// ============================================
// main routing
// ============================================

describe("main routing logic", () => {
  it("unknown type does nothing (no crash)", async () => {
    // Import main and call with unknown type - should not throw
    const { main } = await import("./notify.ts");
    const flags: NotifyFlags = { type: "unknown" };
    // Should complete without error since switch has no default
    await expect(main(flags)).resolves.toBeUndefined();
  });

  it("undefined type does nothing (no crash)", async () => {
    const { main } = await import("./notify.ts");
    const flags: NotifyFlags = {};
    await expect(main(flags)).resolves.toBeUndefined();
  });
});

// ============================================
// Platform check
// ============================================

describe("platform guard", () => {
  it("process.platform is accessible", () => {
    expect(typeof process.platform).toBe("string");
    expect(process.platform.length).toBeGreaterThan(0);
  });
});
