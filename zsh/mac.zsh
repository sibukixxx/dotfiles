# =============================================================================
# macOS Specific Settings
# =============================================================================

# =============================================================================
# Clipboard
# =============================================================================
alias pbp="pbpaste"

pb() {
  if [[ -t 0 ]]; then
    cat "$1" | pbcopy
  else
    pbcopy < /dev/stdin
  fi
}

alias pwdpwd="pwd | tee >(pbcopy)"

# =============================================================================
# Applications
# =============================================================================
alias chrome="open -a 'Google Chrome'"

# =============================================================================
# Time sync (without NTP)
# =============================================================================
timeset() {
  local unixtime
  unixtime=$(curl -s "http://www.convert-unix-time.com/api?timestamp=now&timezone=tokyo" | jq .timestamp)
  local fmttime
  fmttime=$(date -r "$unixtime" +%m%d%H%M%y)
  sudo date "$fmttime"
}

# =============================================================================
# MySQL helpers
# =============================================================================
_mysql_select() {
  mysql -uroot -e "SET NAMES utf8; SELECT $*"
}

_mysql_show() {
  mysql -uroot -e "SET NAMES utf8; SHOW $*"
}

alias SELECT="noglob _mysql_select"
alias SHOW="noglob _mysql_show"

# =============================================================================
# Less with syntax highlighting (if source-highlight is available)
# =============================================================================
if [[ -f /usr/local/bin/src-hilite-lesspipe.sh ]]; then
  export LESS='-R'
  export LESSOPEN='| /usr/local/bin/src-hilite-lesspipe.sh %s'
elif [[ -f /opt/homebrew/bin/src-hilite-lesspipe.sh ]]; then
  export LESS='-R'
  export LESSOPEN='| /opt/homebrew/bin/src-hilite-lesspipe.sh %s'
fi
