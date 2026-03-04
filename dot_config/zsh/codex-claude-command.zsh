# =============================================================================
# codex-claude-command - Zsh completion
# =============================================================================

_codex_claude_command() {
  local commands_dir
  commands_dir="${CLAUDE_COMMANDS_DIR:-$HOME/.claude/commands}"

  local -a commands
  local file name

  if [[ -d "$commands_dir" ]]; then
    for file in "$commands_dir"/*.md(N); do
      name="${file:t:r}"
      commands+=("${name}:Claude custom command")
    done
  fi

  _arguments -C \
    '1:command:->command' \
    '*::task text:_message -r "task text"'

  case "$state" in
    command)
      if (( ${#commands[@]} > 0 )); then
        _describe -t commands 'commands' commands
      else
        _message "No command definitions in ${commands_dir}"
      fi
      ;;
  esac
}

compdef _codex_claude_command codex-claude-command ccmd
