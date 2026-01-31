# Claude Code Hooks

Custom hooks for Claude Code to enhance development workflow.

## Hook Types

| Hook | Trigger | Timeout | Description |
|------|---------|---------|-------------|
| SessionStart | Session begins | 30s | Initialize session, show git status, restore state |
| UserPromptSubmit | User sends prompt | 10s | Detect intent, provide contextual hints |
| PostToolUse | After tool execution | 30-60s | Auto-format files after edits |
| Stop | Session ends | 30s | Save state, warn about uncommitted changes |

## Files

```
hooks/
├── types.ts          # Type definitions for all hooks
├── session-start.ts  # SessionStart hook
├── user-prompt.ts    # UserPromptSubmit hook
├── format.ts         # PostToolUse hook (auto-format)
├── auto-git-add.ts   # PostToolUse hook (auto-stage tracked files)
├── error-detector.ts # PostToolUse hook (TypeScript/lint error detection)
├── session-stop.ts   # Stop hook
├── notify.ts         # Desktop notifications
└── README.md         # This file
```

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

- **Deno** (required): Runtime for TypeScript hooks
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
        "hooks": [{ "type": "command", "command": "deno run ... session-start.ts" }]
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
- `.ts`, `.tsx`, `.js`, `.jsx` files - formatted with Biome (for Node.js projects) or Deno
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

The notify hook sends desktop notifications when:
- Claude Code stops execution (`Stop` event)
- Claude Code needs user attention (`Notification` event)
