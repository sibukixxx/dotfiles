## (Mac)

# color
# autoload -U colors
# colors

# prompt configuration
# COLOR_USER="%{$fg_bold[blue]%}"
# COLOR_RESET="%{$reset_color%}"
# COLOR_RED="%{$fg[red]%}"
# COLOR_CYAN="%{$fg[cyan]%}"
# PROMPT="${COLOR_USER}%n${COLOR_RESET}$ "
# PROMPT2="${COLOR_RED}%_> ${COLOR_RESET}"
# RPROMPT="${COLOR_CYAN}[%~]${COLOR_RESET}"
# SPROMPT="${COLOR_RED}correct?: %R -> %r [n,y,a,e]:${COLOR_RESET}"

# copy
alias pbp="pbpaste"

alias pb="pbcopy"
function pb() {
  if [ -t 0 ]; then
    cat $1 | pbcopy
  else
    pbcopy < /dev/stdin
  fi
}

# time setting without ntp
function timeset() {
  UNIXTIME=$(curl -s "http://www.convert-unix-time.com/api?timestamp=now&timezone=tokyo" | jq .timestamp)
  fmttime=$(date -r $UNIXTIME +%m%d%H%M%y)
  sudo date $fmttime
}

# vim
export EDITOR=/usr/local/bin/vim
alias vim='env LANG=ja_JP.UTF-8 $EDITOR "$@"'

alias pwdpwd="pwd | tee >(pbcopy)"
alias google_chrome="open -a Google\ Chrome"


function SELECT () {
    mysql -uroot -e "SET NAMES utf8; SELECT $*"
}


function SHOW () {
    mysql -uroot -e "SET NAMES utf8; SHOW $*"
}

alias SELECT="noglob SELECT"
alias SHOW="noglob SHOW"

## For HAskell
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
#eval "$(stack --bash-completion-script stack)"
