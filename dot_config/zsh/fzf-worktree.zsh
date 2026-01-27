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
# Claude Agents with Git Worktrees (pure tmux, no xpanes required)
# =============================================================================

# Create N tmux panes with git worktrees, each running claude
# Usage: wt_agents [num_agents] [--no-claude]
wt_agents() {
  local n="${1:-3}"
  local no_claude=false
  [[ "$2" == "--no-claude" ]] && no_claude=true

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
      $no_claude || tmux send-keys "claude" C-m
      first=false
    else
      # Subsequent panes: split and send commands
      if $no_claude; then
        tmux split-window -h -c "$wt_dir"
      else
        tmux split-window -h -c "$wt_dir" "claude"
      fi
    fi
  done

  # Arrange panes evenly
  tmux select-layout tiled

  echo "Created ${#wt_paths[@]} panes with worktrees"
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
  worktrees=$(git worktree list | grep -E "${base}-wt[0-9]+" | awk '{print $1}')

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

