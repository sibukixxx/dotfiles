# Claude Code — user-level guidance

Project-specific shared rules belong in each repository's `AGENTS.md`; project `CLAUDE.md` files import that source.

## Claude-specific routing
- Detailed reusable workflows live under `~/.claude/skills/`. Open only the Skill relevant to the current task; do not copy Skill procedures into repository root instructions.
- Mandatory formatting, notification, error-detection, permission, and related behavior is implemented by hooks/settings under `~/.claude/`. Treat hook results as authoritative; do not bypass them or restate them as manual rituals.
- Respect Claude Code permission prompts and repository-local `.claude/settings*.json`; do not broaden permissions merely to complete a task.
- Repository-local Claude supplements may add tool-specific information, but shared architecture/commands/Done criteria stay in `AGENTS.md`.

## Maintenance
- When a general workflow needs substantial procedure, create/update a Skill instead of growing this file.
- When a rule must always execute mechanically, implement/update a Hook and its tests instead of relying on prose.
- Do not pin transient model names here unless a feature genuinely requires one.
