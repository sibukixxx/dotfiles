# =============================================================================
# zeno.zsh - Abbreviation expansion & Smart History Selection
# https://github.com/yuki-yano/zeno.zsh
# =============================================================================

# Config path
export ZENO_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zeno"

# fzf options for zeno
export ZENO_GIT_CAT="bat --color=always"
export ZENO_GIT_TREE="eza --tree --icons --color=always"

# Key bindings (only if zeno is loaded)
if [[ -n "$ZENO_LOADED" ]]; then
  bindkey ' '  zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion
  bindkey '^r' zeno-history-selection
  bindkey '^x^s' zeno-insert-snippet
fi
