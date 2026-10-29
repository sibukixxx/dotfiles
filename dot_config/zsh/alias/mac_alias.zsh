# =============================================================================
# macOS Specific Aliases
# =============================================================================

# Workspace
alias ww="cd ~/workspace/"

# Finder
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# DNS cache
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Lock screen
alias afk="pmset displaysleepnow"

# Quick Look
alias ql='qlmanage -p'
