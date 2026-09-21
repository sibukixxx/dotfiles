# dotfiles

Personal development-environment source repository. Files under `.claude/` are deployed user-level Claude Code configuration, not ordinary project-local settings.

## Source of truth
- Claude user config: `.claude/`
- Reusable Claude Skills: `.claude/skills/`
- Generated/install behavior: repository setup scripts and `Makefile`

## Commands
- Use `make help` / documented Make targets before invoking setup scripts directly.
- Validate JSON/settings and changed shell/templates with their existing repository checks.

## Shared rules
- Do not hard-code machine-specific secrets, tokens, or absolute private workspace data into tracked dotfiles.
- Detailed TDD, observability, migration, security, and other procedures belong in their existing Skills; do not duplicate them in root instructions.
- Hooks are executable policy. Change hook behavior in the hook/config implementation, not by adding prose that claims the hook will run.
- Installation/update scripts must preserve existing user state according to their merge/backup contract.
- `.claude/CLAUDE.md` is user-level Claude-specific guidance; keep cross-agent repository rules here.

## Change-dependent checks
- Claude settings/hooks: parse settings and run focused hook/script tests.
- Installer/template: test against a disposable target/home where possible.
- Skill: verify referenced scripts/docs exist and run its deterministic checker.

## Done
- Tracked config parses and changed scripts pass their checks.
- Installation remains non-destructive.
- No private machine secret/path was newly embedded.
