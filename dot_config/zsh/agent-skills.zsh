# =============================================================================
# Agent Skills - Zsh Integration
# =============================================================================
# Provides aliases and completions for agent-skills command.

# Skip if agent-skills is not installed
if ! command -v agent-skills &>/dev/null; then
  return 0
fi

# =============================================================================
# Aliases
# =============================================================================

# Short aliases for common commands
alias asks='agent-skills sync'      # Sync skills to targets
alias askl='agent-skills list'      # List available skills
alias asku='agent-skills update'    # Update sources
alias asks='agent-skills status'    # Show status

# Quick update and sync
alias askup='agent-skills update && agent-skills sync'

# =============================================================================
# Completions
# =============================================================================

_agent_skills() {
  local -a commands
  commands=(
    'list:List available skills from all sources'
    'sync:Install/update skills to target directories'
    'update:Update skill sources (git pull)'
    'add:Add a skill to enabled list'
    'remove:Remove a skill from enabled list'
    'status:Show installation status'
    'help:Show help message'
  )

  local -a skills
  _arguments -C \
    '1:command:->command' \
    '*::arg:->args'

  case "$state" in
    command)
      _describe -t commands 'agent-skills commands' commands
      ;;
    args)
      case "${words[1]}" in
        add|remove)
          # Complete with available skills
          local config_file="${AGENT_SKILLS_CONFIG:-$HOME/.config/agent-skills/skills.yaml}"
          if [[ -f "$config_file" ]] && command -v yq &>/dev/null; then
            local cache_dir="${AGENT_SKILLS_DIR:-$HOME/.agent-skills}/cache"

            # Get sources and their skills
            local sources
            sources=$(yq '.sources | keys | .[]' "$config_file" 2>/dev/null)

            for source in $sources; do
              local source_type
              source_type=$(yq ".sources.$source.type" "$config_file" 2>/dev/null)
              local skills_path

              if [[ "$source_type" == "git" ]]; then
                local source_path
                source_path=$(yq ".sources.$source.path // \".\"" "$config_file" 2>/dev/null)
                skills_path="$cache_dir/$source/$source_path"
              elif [[ "$source_type" == "local" ]]; then
                skills_path=$(yq ".sources.$source.path" "$config_file" 2>/dev/null)
                skills_path="${skills_path/#\~/$HOME}"
              fi

              if [[ -d "$skills_path" ]]; then
                for skill_dir in "$skills_path"/*/; do
                  if [[ -d "$skill_dir" ]]; then
                    local skill_name
                    skill_name=$(basename "$skill_dir")
                    skills+=("$source:$skill_name")
                  fi
                done
              fi
            done

            if [[ ${#skills[@]} -gt 0 ]]; then
              _describe -t skills 'available skills' skills
            fi
          fi
          ;;
      esac
      ;;
  esac
}

compdef _agent_skills agent-skills

# =============================================================================
# Helper Functions
# =============================================================================

# Quick function to add and sync a skill
ask-add() {
  if [[ -z "$1" ]]; then
    echo "Usage: ask-add <source>:<skill>"
    echo "Example: ask-add anthropic:pdf"
    return 1
  fi

  agent-skills add "$1" && agent-skills sync
}

# Quick function to remove a skill (and cleanup symlinks)
ask-remove() {
  if [[ -z "$1" ]]; then
    echo "Usage: ask-remove <source>:<skill>"
    return 1
  fi

  agent-skills remove "$1"
  echo ""
  echo "Run 'agent-skills sync' to cleanup symlinks"
}
