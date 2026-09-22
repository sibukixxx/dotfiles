import { describe, it, expect } from "bun:test";
import { parseNotifyFlags } from "./notify.ts";
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
