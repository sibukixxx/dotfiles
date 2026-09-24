# Claude Code Hooks

Custom hooks for Claude Code to enhance development workflow.

## Hook Types

| Hook | Trigger | Timeout | Description |
|------|---------|---------|-------------|
| SessionStart | Session begins | 30s | Initialize session, show git status, restore state |
| UserPromptSubmit | User sends prompt | 10s | Detect intent, provide contextual hints; keep macOS awake |
| PreToolUse | Before Bash / Read / ExitPlanMode | 10s | Deny dangerous commands and sensitive file reads; plan review |
| PostToolUse | After tool execution | 30-60s | Auto-format files after edits |
| Notification | Claude needs attention | 10s | Desktop notification (permission prompt, idle) |
| Stop | Turn ends | 30s | Save state, warn about uncommitted changes, release sleep lock, notify |
| SessionEnd | Session ends | 5s | Release sleep lock |
| statusLine | Every refresh | - | Model, dir, branch, context usage as battery |

## Files

```
hooks/
├── types.ts            # Type definitions for all hooks
├── session-start.ts    # SessionStart hook
├── user-prompt.ts      # UserPromptSubmit hook
├── format.ts           # PostToolUse hook (auto-format)
├── auto-git-add.ts     # PostToolUse hook (auto-stage tracked files)
├── error-detector.ts   # PostToolUse hook (TypeScript/lint error detection)
├── session-stop.ts     # Stop hook
├── suggest-claude-md.ts# Stop / PreCompact hook (CLAUDE.md suggestions)
├── notify.ts           # Desktop notifications (Notification / Stop)
├── keep-awake.sh       # UserPromptSubmit / Stop / SessionEnd: caffeinate control
├── statusline.sh       # statusLine command
├── validate-bash.sh    # PreToolUse(Bash): deny rm -rf / curl / wget / chmod 777
├── validate-read.sh    # PreToolUse(Read): deny .env / keys / credentials / secrets
├── plan-review-hook.sh # PreToolUse(ExitPlanMode): Codex plan review
├── *.test.ts / *.test.sh  # Tests (bun test / bash <file>)
└── README.md           # This file
```

All hooks are referenced from `settings.json` as `~/.claude/hooks/<file>` (the
directory is a symlink into `dotfiles/.claude/hooks`). Do not use
`$CLAUDE_PROJECT_DIR` for global hooks — it points at the current project.

## Keep-Awake Hook (`keep-awake.sh`)

Keeps the Mac awake only while the agent is working:

- `UserPromptSubmit` → `keep-awake.sh acquire` starts `caffeinate -i -s` (one per session, tracked by pid file)
- `Stop` / `SessionEnd` → `keep-awake.sh release` kills it
- Safety cap: `KEEP_AWAKE_MAX_SECONDS` (default 4h) so a missed release never keeps the machine up forever

Limitation: `caffeinate -s` only holds on AC power. Closing the lid on battery
still sleeps (macOS rule). For lid-closed battery runs, use clamshell mode or a
dedicated app such as Adrafinil.

Test: `bash keep-awake.test.sh`

## Statusline (`statusline.sh`)

```
Fable 5.1 1M | dotfiles (master) | ctx 🔋 42% | 5h 🔋 12% | 7d 🪫 91%
```

- Percentages are **used** amounts. Battery flips to 🪫 at ≥80%, color goes green → yellow (70%) → red (90%)
- `ctx` comes from `context_window.used_percentage`, falling back to `current_usage / context_window_size`
- `5h` / `7d` appear only when `rate_limits` is present in the payload
- The payload is forwarded to `~/.orca/agent-hooks/claude-statusline.sh` when it exists, so Orca keeps working

Test: `bash statusline.test.sh`

## Validation Hooks (`validate-bash.sh`, `validate-read.sh`)

Return `permissionDecision: deny` with a reason. The agent is instructed (global
CLAUDE.md) to give up on denied operations instead of hunting for workarounds.

## State Management

Session state is stored in `~/.claude/status/`:

```
status/
├── current.md           # Current active task
├── session_state.json   # Session state (auto-managed)
├── session_log.md       # Session history log
└── queue/
    ├── p1.md            # Priority 1 tasks
    ├── p2.md            # Priority 2 tasks
    └── p3.md            # Priority 3 tasks
```

## Type Definitions

The `types.ts` file provides TypeScript types for all hook events:

### Hook Data Types

- **SessionStartHookData**: Session initialization data
- **UserPromptSubmitHookData**: User prompt data with intent detection
- **PostToolUseHookData**: Tool execution results (Write, Edit, MultiEdit)
- **StopHookData**: Session end data with stop reason

### Tool Parameter Types

- **WriteToolParams**: Parameters for the Write tool
  - `file_path`: string - The absolute path to write to
  - `content`: string - The content to write

- **EditToolParams**: Parameters for the Edit tool
  - `file_path`: string - The absolute path to edit
  - `old_string`: string - The text to replace
  - `new_string`: string - The replacement text
  - `replace_all?`: boolean - Whether to replace all occurrences

- **MultiEditToolParams**: Parameters for the MultiEdit tool
  - `file_path`: string - The absolute path to edit
  - `edits`: Array of edit operations

### State Types

- **SessionState**: Tracks session info, tasks, and uncommitted files
- **TaskState**: Individual task with priority, status, and context

## Dependencies

- **Bun** (required): Runtime for TypeScript hooks
- **jq** (optional): JSON formatting
- **gofmt/rustfmt/biome** (optional): Language-specific formatters

## Configuration

Hooks are configured in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "bun run ~/.claude/hooks/session-start.ts" }]
      }
    ],
    "UserPromptSubmit": [...],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

## Design Principles

1. **Fail-safe**: All hooks use try-catch, never block the session
2. **Timeout aware**: Respect recommended timeouts
3. **Matcher-based**: Use specific matchers (e.g., `Edit|Write`) to reduce noise
4. **State persistence**: File-based state survives across sessions

## Format Hook Details

The format hook runs after Write, Edit, or MultiEdit operations and automatically formats files based on their extension:

- `.go` files - formatted with `gofmt`
- `.rs` files - formatted with `rustfmt`
- `.ts`, `.tsx`, `.js`, `.jsx` files - formatted with Biome
- `.json`, `.jsonc` files - formatted with `jq`

## Auto Git Add Hook

Automatically stages tracked files after edits:
- Only stages files already tracked by git (won't add new files)
- Excludes sensitive files (`.env`, credentials, secrets, keys)
- Logs actions for transparency

## Error Detector Hook

Detects TypeScript and lint errors after file edits:
- Runs `tsc --noEmit` for TypeScript files
- Checks Biome lint if configured
- Provides error suggestions and fix hints
- Logs errors to `~/.claude/status/errors.md`

## Notify Hook

The notify hook (`notify.ts`, uses the built-in macOS `osascript`; failures are ignored) sends desktop notifications when:
- Claude Code stops execution (`Stop` event) — `--type stop`
- Claude Code needs user attention (`Notification` event) — `--type notify`
