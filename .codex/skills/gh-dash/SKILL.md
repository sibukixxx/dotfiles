---
name: gh-dash
description: Set up, configure, troubleshoot, or optimize the gh dash terminal dashboard for GitHub pull requests, issues, and notifications. Use when a user mentions gh dash, .gh-dash.yml, dashboard sections, repoPaths, gh dash filters, layouts, themes, or custom keybindings; do not use for ordinary gh CLI tasks unrelated to the dashboard.
---

# gh dash

Help the user turn their GitHub work queue into a useful terminal dashboard. Prefer a small configuration tailored to their actual workflow over an exhaustive example.

## Establish the task

Determine which outcome is requested:

- install or update `gh dash`
- create a new global or repository-local configuration
- modify or troubleshoot an existing configuration
- explain navigation or daily usage
- add sections, layouts, themes, `repoPaths`, or custom keybindings

Inspect the current repository, existing config, and installed commands before proposing changes. Ask only for information that cannot be inferred, such as organization names or local repository roots.

## Installation

Check prerequisites with `gh --version`, `gh auth status`, and `gh extension list`. If missing, install GitHub CLI using the platform-appropriate package manager, authenticate with `gh auth login`, then install the extension with:

```sh
gh extension install dlvhdr/gh-dash
```

Update it with `gh extension upgrade dlvhdr/gh-dash`. Treat installation, authentication, and updates as external mutations and follow the active permission policy. Recommend a Nerd Font only when icons render incorrectly; do not make it mandatory.

## Choose the configuration scope

Use the user's chosen location. Otherwise:

- choose `.gh-dash.yml` in the repository root for project-specific, shareable behavior;
- choose the global config for personal cross-repository workflow.

Resolution order is `GH_DASH_CONFIG`, repository `.gh-dash.yml`/`.gh-dash.yaml`, then `$XDG_CONFIG_HOME/gh-dash/config.yml` or the platform default. Do not overwrite an existing file. Read it, preserve unrelated settings and comments where practical, and make a focused edit.

For configuration details and a baseline example, read [references/configuration.md](references/configuration.md). Consult the live official schema or documentation when a requested option is absent or may have changed.

## Design the dashboard

Translate the user's work queues into a few clearly named sections. Common starting points are authored PRs, requested reviews, involved PRs, assigned issues, and unread notifications. Use GitHub search qualifiers directly, but omit `is:pr` from `prSections` because gh dash adds it.

Prefer `@me` over hard-coded usernames. Add an explicit `repo:` or `org:` qualifier only when the section should be scoped that way. Explain that repository launch may apply smart filtering to sections without `repo:` and set `smartFilteringAtLaunch: false` only when the user wants global results from inside repositories.

Add `repoPaths` only for checkout or commands that need `.RepoPath`. Map the narrowest useful owner/repository pattern to a real local path; do not invent paths.

For custom commands:

- use the documented template variables for the relevant view;
- quote shell arguments defensively;
- avoid commands containing embedded credentials or untrusted interpolation;
- flag key collisions and commands with destructive side effects;
- require explicit user confirmation before adding shortcuts that merge, close, force-update, approve workflows, or otherwise mutate remote state without a built-in confirmation.

## Verify

Add the schema directive to generated YAML unless the user declines:

```yaml
# yaml-language-server: $schema=https://gh-dash.dev/schema.json
```

Verify, in proportion to the change:

1. parse the YAML with an available local parser;
2. compare keys and values with the current schema or official docs;
3. run `gh dash --version` and `gh dash --help` when installed;
4. for filters, use a read-only `gh search prs` or `gh search issues` equivalent when feasible;
5. launch with `gh dash --config <path>` only in an interactive terminal, and do not claim visual verification if it was not performed.

Report the config path, sections added or changed, verification performed, and any remaining user-specific placeholders.

## Operational guidance

For daily use, teach only the keys relevant to the immediate goal. Mention `?` as the authoritative in-app help because keybindings can be overridden. Before instructing the user to approve, merge, close, reopen, update, or comment, state the effect and ensure the selected repository and item are correct.

## Sources

- [Official documentation](https://www.gh-dash.dev/)
- [Configuration schema](https://gh-dash.dev/schema.json)
- [GitHub repository](https://github.com/dlvhdr/gh-dash)
- [Japanese overview used as inspiration](https://zenn.dev/nonejp/articles/d6dedc467ef803)
