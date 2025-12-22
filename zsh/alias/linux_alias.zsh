# =============================================================================
# Linux-specific aliases
# =============================================================================

# Package management (apt for Debian/Ubuntu)
if command -v apt &>/dev/null; then
  alias apt-update='sudo apt update && sudo apt upgrade -y'
  alias apt-install='sudo apt install'
  alias apt-remove='sudo apt remove'
  alias apt-search='apt search'
  alias apt-clean='sudo apt autoremove -y && sudo apt autoclean'
fi

# System
alias reboot='sudo reboot'
alias shutdown='sudo shutdown -h now'

# Network
alias myip='curl -s ifconfig.me'
alias ports='ss -tulanp'

# Systemd
if command -v systemctl &>/dev/null; then
  alias sc='sudo systemctl'
  alias scs='sudo systemctl status'
  alias scr='sudo systemctl restart'
  alias sce='sudo systemctl enable'
  alias scd='sudo systemctl disable'
fi
