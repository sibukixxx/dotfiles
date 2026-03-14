# zsh agent-skills alias fix

- Status: done
- Updated: 2026-03-12
- Progress: 100%
- Summary: `agent-skills` alias collision was resolved so `sync` and `status` no longer share the same shortcut.
- Evidence:
- `dot_config/zsh/agent-skills.zsh` now keeps `asks='agent-skills sync'` and moves status to `askst='agent-skills status'`.
- `zsh -n dot_config/zsh/agent-skills.zsh` passed on 2026-03-12.
- Remaining work: none
