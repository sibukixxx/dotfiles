# gh dash configuration reference

Read this reference when creating or editing a gh dash YAML configuration. For options not covered here, consult the live [official configuration documentation](https://www.gh-dash.dev/configuration/) and [schema](https://gh-dash.dev/schema.json).

## Baseline

```yaml
# yaml-language-server: $schema=https://gh-dash.dev/schema.json

prSections:
  - title: My Pull Requests
    filters: is:open author:@me
  - title: Needs My Review
    filters: is:open review-requested:@me
  - title: Involved
    filters: is:open involves:@me -author:@me

issuesSections:
  - title: Assigned to Me
    filters: is:open assignee:@me

notificationsSections:
  - title: Unread
    filters: is:unread

defaults:
  view: prs
  prsLimit: 20
  issuesLimit: 20
  notificationsLimit: 20
  refetchIntervalMinutes: 30
  preview:
    open: true
    width: 0.45
    height: 0.60
    position: auto
```

Keep only sections the user needs. Default view accepts `prs`, `issues`, or `notifications`. A refetch interval of `0` disables periodic refresh.

## Dynamic dates

Use `nowModify` for moving windows:

```yaml
- title: Recently Updated
  filters: >-
    is:open
    updated:>={{ nowModify "-2w" }}
```

Supported suffixes include ordinary Go duration units plus `d`, `w`, `M`/`mo`, and `y`.

## Repository paths

```yaml
repoPaths:
  example-org/*: /absolute/path/to/example-org/*
  owner/special-repo: /absolute/path/to/special-repo
```

Use real paths. `RepoPath` is required for local checkout and custom commands that change into a repository.

## Custom keybindings

```yaml
keybindings:
  universal:
    - key: g
      name: lazygit
      command: cd "{{.RepoPath}}" && lazygit
  prs:
    - key: O
      builtin: checkout
  issues:
    - key: P
      name: pin issue
      command: gh issue pin "{{.IssueNumber}}" --repo "{{.RepoName}}"
```

PR variables: `.RepoName`, `.RepoPath`, `.PrNumber`, `.HeadRefName`, `.BaseRefName`, `.Author`.

Issue variables: `.RepoName`, `.RepoPath`, `.IssueNumber`, `.Author`.

Current documentation also covers notification bindings and additional built-ins. Check it before adding them rather than relying on memory.

## Useful runtime keys

- `?`: show the current help and effective bindings
- `/`: edit the current search temporarily
- `r` / `R`: refresh current / all sections
- `s`: switch work-item views
- `p`: toggle preview
- `j` / `k`, `h` / `l`: move through rows and sections
- `o`: open the selected item in GitHub
- `y` / `Y`: copy number / URL
- `q`: quit

These defaults may be overridden. Prefer the in-app `?` help over a static list.
