alias psp="ps aux | peco"
alias killp="ps aux | peco | awk '{print \$2}' | xargs kill -9"

# move to directory found with peco
function cdp() {
  if [[ $PWD = $HOME ]];then
    cd $(find . -maxdepth 3 -type d ! -path "*/.*" | peco)
  else
    cd $(find . -maxdepth 4 -type d ! -path "*/.*" | peco)
  fi
}

## peco
function peco-src () {
    local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
    typeset selected_dir
if [ -n "$selected_dir" ]; then
        #selected_dir="$GOPATH/src/$selected_dir"
        selected_dir="$selected_dir"
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-src
bindkey '^f' peco-src

# ignore duplicates from history
function peco-select-history() {
  local tac_cmd
  if command -v tac > /dev/null 2>&1; then
    tac_cmd="tac"
  else
    tac_cmd="tail -r"
  fi
  BUFFER=$(fc -rl 1 | sed 's/^ *[0-9]*\** *//' | awk '!a[$0]++' | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
}
zle -N peco-select-history
bindkey '^v' peco-select-history

# move to GPATH/src
function cdgo() {
  cd ${GOPATH}/src
}

