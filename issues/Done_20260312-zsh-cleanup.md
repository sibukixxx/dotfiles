# zsh cleanup

- Status: done
- Updated: 2026-03-12
- Progress: 100%
- Summary: Redundant prompt settings and dead `peco` helper code were removed without breaking shell syntax.
- Evidence:
- `dot_zshrc` no longer duplicates generic `vcs_info` format declarations on top of the git-specific settings.
- `dot_config/zsh/peco.zsh` no longer contains the empty `rgvim` function stub.
- `zsh -n dot_zshrc` and `zsh -n dot_config/zsh/peco.zsh` both passed on 2026-03-12.
- Remaining work: none
