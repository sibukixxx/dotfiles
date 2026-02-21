import { describe, it, expect } from "bun:test";
import {
  detectIntent,
  getIntentEmoji,
  getIntentHint,
  detectSecurityKeyword,
  processPrompt,
  INTENT_PATTERNS,
  SECURITY_KEYWORDS,
} from "./user-prompt.ts";

describe("detectIntent", () => {
  describe("planning intent", () => {
    it("detects 'plan' keyword", () => {
      expect(detectIntent("Let's plan this feature")).toBe("planning");
    });

    it("detects '設計' keyword", () => {
      expect(detectIntent("この機能を設計する")).toBe("planning");
    });

    it("detects 'architect' keyword", () => {
      expect(detectIntent("architect the system")).toBe("planning");
    });

    it("detects 'design' keyword", () => {
      expect(detectIntent("design a new component")).toBe("planning");
    });

    it("detects 'どうやって' keyword", () => {
      expect(detectIntent("どうやって実装するか")).toBe("planning");
    });

    it("detects '方針' keyword", () => {
      expect(detectIntent("方針を決める")).toBe("planning");
    });
  });

  describe("implementation intent", () => {
    it("detects '実装' keyword", () => {
      expect(detectIntent("実装してください")).toBe("implementation");
    });

    it("detects 'implement' keyword", () => {
      expect(detectIntent("implement this feature")).toBe("implementation");
    });

    it("detects 'create' keyword", () => {
      expect(detectIntent("create a new file")).toBe("implementation");
    });

    it("detects '作って' keyword", () => {
      expect(detectIntent("新しいコンポーネントを作って")).toBe("implementation");
    });

    it("detects '作る' keyword", () => {
      expect(detectIntent("関数を作る")).toBe("implementation");
    });

    it("detects '作成' keyword", () => {
      expect(detectIntent("ファイルを作成")).toBe("implementation");
    });

    it("detects 'add' keyword", () => {
      expect(detectIntent("add a button")).toBe("implementation");
    });

    it("detects '追加' keyword", () => {
      expect(detectIntent("機能を追加して")).toBe("implementation");
    });

    it("detects 'write' keyword", () => {
      expect(detectIntent("write the code")).toBe("implementation");
    });

    it("detects '書いて' keyword", () => {
      expect(detectIntent("コードを書いて")).toBe("implementation");
    });

    it("detects '書く' keyword", () => {
      expect(detectIntent("テストを書く")).toBe("implementation");
    });
  });

  describe("debugging intent", () => {
    it("detects 'debug' keyword", () => {
      expect(detectIntent("debug this issue")).toBe("debugging");
    });

    it("detects 'fix' keyword", () => {
      expect(detectIntent("fix the bug")).toBe("debugging");
    });

    it("detects 'error' keyword", () => {
      expect(detectIntent("there is an error")).toBe("debugging");
    });

    it("detects '修正' keyword", () => {
      expect(detectIntent("バグを修正して")).toBe("debugging");
    });

    it("detects 'バグ' keyword", () => {
      expect(detectIntent("バグがあります")).toBe("debugging");
    });

    it("detects '直して' keyword", () => {
      expect(detectIntent("これ直して")).toBe("debugging");
    });

    it("detects '直す' keyword", () => {
      expect(detectIntent("エラーを直す")).toBe("debugging");
    });

    it("detects '動かない' keyword", () => {
      expect(detectIntent("コードが動かない")).toBe("debugging");
    });

    it("detects '動きません' keyword", () => {
      expect(detectIntent("正しく動きません")).toBe("debugging");
    });
  });

  describe("review intent", () => {
    it("detects 'review' keyword", () => {
      expect(detectIntent("review my code")).toBe("review");
    });

    it("detects 'レビュー' keyword", () => {
      expect(detectIntent("コードレビューお願い")).toBe("review");
    });

    it("detects 'check' keyword", () => {
      expect(detectIntent("check this code")).toBe("review");
    });

    it("detects '確認' keyword", () => {
      expect(detectIntent("コードを確認して")).toBe("review");
    });

    it("detects 'verify' keyword", () => {
      expect(detectIntent("verify the code")).toBe("review");
    });

    it("detects '検証' keyword", () => {
      expect(detectIntent("動作を検証")).toBe("review");
    });
  });

  describe("testing intent", () => {
    it("detects 'test' keyword", () => {
      expect(detectIntent("test this function")).toBe("testing");
    });

    it("detects 'テスト' keyword", () => {
      expect(detectIntent("テストを実行")).toBe("testing");
    });

    it("detects 'tdd' keyword", () => {
      expect(detectIntent("use tdd approach")).toBe("testing");
    });

    it("detects 'spec' keyword", () => {
      expect(detectIntent("run the spec")).toBe("testing");
    });
  });

  describe("refactoring intent", () => {
    it("detects 'refactor' keyword", () => {
      expect(detectIntent("refactor this code")).toBe("refactoring");
    });

    it("detects 'リファクタ' keyword", () => {
      expect(detectIntent("リファクタリングして")).toBe("refactoring");
    });

    it("detects 'clean' keyword", () => {
      expect(detectIntent("clean up the code")).toBe("refactoring");
    });

    it("detects '整理' keyword", () => {
      expect(detectIntent("コードを整理")).toBe("refactoring");
    });

    it("detects '改善' keyword", () => {
      expect(detectIntent("パフォーマンスを改善")).toBe("refactoring");
    });
  });

  describe("no intent", () => {
    it("returns null for unrelated prompt", () => {
      expect(detectIntent("hello world")).toBe(null);
    });

    it("returns null for empty string", () => {
      expect(detectIntent("")).toBe(null);
    });
  });
});

describe("getIntentEmoji", () => {
  it("returns planning emoji", () => {
    expect(getIntentEmoji("planning")).toBe("📋");
  });

  it("returns implementation emoji", () => {
    expect(getIntentEmoji("implementation")).toBe("🔨");
  });

  it("returns debugging emoji", () => {
    expect(getIntentEmoji("debugging")).toBe("🐛");
  });

  it("returns review emoji", () => {
    expect(getIntentEmoji("review")).toBe("👀");
  });

  it("returns testing emoji", () => {
    expect(getIntentEmoji("testing")).toBe("🧪");
  });

  it("returns refactoring emoji", () => {
    expect(getIntentEmoji("refactoring")).toBe("♻️");
  });
});

describe("getIntentHint", () => {
  it("returns planning hint", () => {
    const hint = getIntentHint("planning");
    expect(hint).toContain("plan");
  });

  it("returns implementation hint", () => {
    const hint = getIntentHint("implementation");
    expect(hint).toContain("TDD");
  });

  it("returns debugging hint", () => {
    const hint = getIntentHint("debugging");
    expect(hint).toContain("error");
  });

  it("returns review hint", () => {
    const hint = getIntentHint("review");
    expect(hint).toContain("review");
  });

  it("returns testing hint", () => {
    const hint = getIntentHint("testing");
    expect(hint).toContain("tdd");
  });

  it("returns refactoring hint", () => {
    const hint = getIntentHint("refactoring");
    expect(hint).toContain("refactoring");
  });
});

describe("detectSecurityKeyword", () => {
  it("detects 'password'", () => {
    expect(detectSecurityKeyword("update password")).toBe(true);
  });

  it("detects 'secret'", () => {
    expect(detectSecurityKeyword("store secret")).toBe(true);
  });

  it("detects 'token'", () => {
    expect(detectSecurityKeyword("refresh token")).toBe(true);
  });

  it("detects 'api_key'", () => {
    expect(detectSecurityKeyword("get api_key")).toBe(true);
  });

  it("detects 'api-key'", () => {
    expect(detectSecurityKeyword("set api-key")).toBe(true);
  });

  it("detects 'apikey'", () => {
    expect(detectSecurityKeyword("use apikey")).toBe(true);
  });

  it("detects 'credential'", () => {
    expect(detectSecurityKeyword("load credentials")).toBe(true);
  });

  it("detects 'auth'", () => {
    expect(detectSecurityKeyword("implement auth")).toBe(true);
  });

  it("returns false for unrelated prompt", () => {
    expect(detectSecurityKeyword("hello world")).toBe(false);
  });

  it("returns false for empty string", () => {
    expect(detectSecurityKeyword("")).toBe(false);
  });

  it("is case insensitive", () => {
    expect(detectSecurityKeyword("PASSWORD")).toBe(true);
    expect(detectSecurityKeyword("Password")).toBe(true);
  });
});

describe("processPrompt", () => {
  it("returns intent and security for implementation with auth", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "UserPromptSubmit" as const,
      prompt: "implement auth feature",
      cwd: "/tmp",
    };
    const result = await processPrompt(data);
    expect(result.intent).toBe("implementation");
    expect(result.hasSecurity).toBe(true);
  });

  it("returns intent only for regular prompt", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "UserPromptSubmit" as const,
      prompt: "refactor this code",
      cwd: "/tmp",
    };
    const result = await processPrompt(data);
    expect(result.intent).toBe("refactoring");
    expect(result.hasSecurity).toBe(false);
  });

  it("returns security only for password prompt without intent", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "UserPromptSubmit" as const,
      prompt: "handle password",
      cwd: "/tmp",
    };
    const result = await processPrompt(data);
    expect(result.intent).toBe(null);
    expect(result.hasSecurity).toBe(true);
  });

  it("returns null for both when no match", async () => {
    const data = {
      session_id: "test",
      transcript_path: "/tmp",
      hook_event_name: "UserPromptSubmit" as const,
      prompt: "hello",
      cwd: "/tmp",
    };
    const result = await processPrompt(data);
    expect(result.intent).toBe(null);
    expect(result.hasSecurity).toBe(false);
  });
});

describe("INTENT_PATTERNS", () => {
  it("has all expected intents", () => {
    expect(Object.keys(INTENT_PATTERNS)).toEqual([
      "planning",
      "implementation",
      "debugging",
      "review",
      "testing",
      "refactoring",
    ]);
  });
});

describe("SECURITY_KEYWORDS", () => {
  it("has expected number of patterns", () => {
    expect(SECURITY_KEYWORDS.length).toBe(6);
  });
});
