# ~/.zsh/fzf-worktree.zsh

# fzf-based git worktree selector
function fzf-worktree() {
    local selected_worktree=$(git worktree list | fzf \
        --prompt="worktrees > " \
        --header="Select a worktree to cd into" \
        --preview="echo '📦 Branch:' && git -C {1} branch --show-current && echo '' && echo '📝 Changed files:' && git -C {1} status --porcelain | head -10 && echo '' && echo '📚 Recent commits:' && git -C {1} log --oneline --decorate -10" \
        --preview-window="right:40%" \
        --reverse \
        --border \
        --ansi)

    if [ $? -ne 0 ]; then
        return 0
    fi

    if [ -n "$selected_worktree" ]; then
        local selected_path=${${(s: :)selected_worktree}[1]}

        if [ -d "$selected_path" ]; then
            if zle; then
                BUFFER="cd ${selected_path}"
                zle accept-line
            else
                cd "$selected_path"
            fi
        else
            echo "Directory not found: $selected_path"
            return 1
        fi
    fi

    if zle; then
        zle clear-screen
    fi
}

zle -N fzf-worktree
bindkey '^n' fzf-worktree

# =============================================================================
# AI Agents with Git Worktrees (pure tmux, no xpanes required)
# =============================================================================

# Create N tmux panes with git worktrees, each running selected AI command
# Usage: wt_agents [num_agents] [--ai <command>] [--no-ai]
# Examples:
#   wt_agents 3 --ai claude
#   wt_agents 2 --ai codex
#   wt_agents --ai "opencode --session dev"
wt_agents() {
  local n="3"
  local ai_cmd="claude"
  local no_ai=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ai=*)
        ai_cmd="${1#*=}"
        shift
        ;;
      --ai|-a)
        if [[ -z "$2" ]]; then
          echo "Error: --ai requires a command"
          echo "Usage: wt_agents [num_agents] [--ai <command>] [--no-ai]"
          return 1
        fi
        ai_cmd="$2"
        shift 2
        ;;
      --no-ai|--no-claude)
        no_ai=true
        shift
        ;;
      -h|--help)
        echo "Usage: wt_agents [num_agents] [--ai <command>] [--no-ai]"
        echo ""
        echo "Options:"
        echo "  --ai, -a <command>   AI command to launch in each pane (default: claude)"
        echo "  --no-ai              Create panes only, do not launch AI command"
        echo "  --no-claude          Backward-compatible alias of --no-ai"
        return 0
        ;;
      *)
        if [[ "$1" =~ '^[0-9]+$' ]]; then
          n="$1"
          shift
        else
          echo "Error: Unknown argument: $1"
          echo "Usage: wt_agents [num_agents] [--ai <command>] [--no-ai]"
          return 1
        fi
        ;;
    esac
  done

  # Verify we're in a git repo
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "Error: Not in a git repository"
    return 1
  }

  # Verify we're in tmux
  if [[ -z "$TMUX" ]]; then
    echo "Error: Not in a tmux session"
    return 1
  fi

  if ! $no_ai; then
    local ai_bin="${ai_cmd%% *}"
    if ! command -v "$ai_bin" &>/dev/null; then
      echo "Error: AI command not found: $ai_bin"
      return 1
    fi
  fi

  local base="$(basename "$root")"
  local parent="$(dirname "$root")"
  local wt_paths=()

  # Create worktrees
  for i in $(seq 1 "$n"); do
    local name="${base}-wt${i}"
    local wt_dir="${parent}/${name}"
    local branch="wt/${name}"

    if [[ -d "$wt_dir" ]]; then
      echo "Worktree already exists: $wt_dir"
    else
      git worktree add -b "$branch" "$wt_dir" HEAD 2>/dev/null || \
      git worktree add "$wt_dir" "$branch" 2>/dev/null || {
        echo "Error creating worktree: $wt_dir"
        continue
      }
      echo "Created worktree: $wt_dir ($branch)"
    fi
    wt_paths+=("$wt_dir")
  done

  [[ ${#wt_paths[@]} -eq 0 ]] && {
    echo "No worktrees to open"
    return 1
  }

  # Create tmux panes
  local first=true
  for wt_dir in "${wt_paths[@]}"; do
    if $first; then
      # First pane: change directory in current pane
      cd "$wt_dir"
      $no_ai || tmux send-keys "$ai_cmd" C-m
      first=false
    else
      # Subsequent panes: split and send commands
      if $no_ai; then
        tmux split-window -h -c "$wt_dir"
      else
        tmux split-window -h -c "$wt_dir" "$ai_cmd"
      fi
    fi
  done

  # Arrange panes evenly
  tmux select-layout tiled

  if $no_ai; then
    echo "Created ${#wt_paths[@]} panes with worktrees (AI launch disabled)"
  else
    echo "Created ${#wt_paths[@]} panes with worktrees (AI: $ai_cmd)"
  fi
}

# Cleanup worktrees created by wt_agents
# Usage: wt_cleanup
wt_cleanup() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "Error: Not in a git repository"
    return 1
  }

  local base="$(basename "$root")"
  local parent="$(dirname "$root")"

  # List worktrees to remove
  local worktrees
  worktrees=$(git worktree list | command grep -E "${base}-wt[0-9]+" | awk '{print $1}')

  if [[ -z "$worktrees" ]]; then
    echo "No worktrees matching pattern: ${base}-wt*"
    return 0
  fi

  echo "Worktrees to remove:"
  echo "$worktrees"
  echo ""
  read -q "REPLY?Remove these worktrees? (y/n) "
  echo ""

  [[ "$REPLY" != "y" ]] && return 0

  while IFS= read -r wt_path; do
    [[ -z "$wt_path" ]] && continue
    local branch_name="wt/$(basename "$wt_path")"
    echo "Removing worktree: $wt_path"
    git worktree remove "$wt_path" --force 2>/dev/null

    # Also delete the branch if it exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
      echo "Deleting branch: $branch_name"
      git branch -D "$branch_name" 2>/dev/null
    fi
  done <<< "$worktrees"

  echo "Cleanup complete"
}

# Quick aliases
alias wta='wt_agents'
alias wtc='wt_cleanup'
