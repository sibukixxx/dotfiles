# ~/.config/zsh/gcloud.zsh - gcloud configuration management
#
# Usage:
#   gsc              - fzf で gcloud configuration を切り替え（グローバル）
#   .gcloud-config   - ディレクトリに配置すると cd 時に自動で configuration を切り替え（per-shell）
#
# Setup:
#   gcloud config configurations create my-project
#   gcloud config set project my-project-id
#   gcloud config set account me@example.com
#   gcloud config set compute/region asia-northeast1
#
#   echo "my-project" > ~/workspace/my-project/.gcloud-config

# =============================================================================
# fzf-based gcloud configuration switcher
# =============================================================================
gsc() {
  if ! command -v gcloud &>/dev/null; then
    echo "Error: gcloud not found"
    return 1
  fi

  local list
  list=$(gcloud config configurations list \
    --format="table[no-heading](name,is_active.yesno(yes='*',no=' '),properties.core.account,properties.core.project,properties.compute.region)" 2>/dev/null)

  [[ -z "$list" ]] && { echo "No gcloud configurations found"; return 1; }

  local selected
  selected=$(echo "$list" | column -t | \
    fzf --prompt="gcloud config > " \
        --header="NAME    ACTIVE  ACCOUNT              PROJECT              REGION" \
        --preview="gcloud config configurations describe {1} 2>/dev/null" \
        --preview-window="right:50%" \
        --reverse \
        --border)

  [[ -z "$selected" ]] && return 0

  local config_name="${${(s: :)selected}[1]}"
  gcloud config configurations activate "$config_name" && \
    echo "Activated: $config_name"
}

# =============================================================================
# Directory-based auto-switch via chpwd hook
# =============================================================================
# Uses CLOUDSDK_ACTIVE_CONFIG_NAME (per-shell, instant, no subprocess)
# - cd into directory with .gcloud-config → sets override
# - cd out → unsets override, falls back to global active config
_gcloud_chpwd_hook() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.gcloud-config" ]]; then
      local wanted="$(<"$dir/.gcloud-config")"
      wanted="${wanted%%[[:space:]]}"  # trim trailing whitespace/newlines
      [[ -z "$wanted" ]] && return 0
      if [[ "$CLOUDSDK_ACTIVE_CONFIG_NAME" != "$wanted" ]]; then
        export CLOUDSDK_ACTIVE_CONFIG_NAME="$wanted"
        echo "gcloud: config -> $wanted"
      fi
      return 0
    fi
    dir="${dir:h}"
  done
  # No .gcloud-config found: unset override to use global default
  [[ -n "$CLOUDSDK_ACTIVE_CONFIG_NAME" ]] && unset CLOUDSDK_ACTIVE_CONFIG_NAME
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _gcloud_chpwd_hook

# Run once at load time for initial directory
_gcloud_chpwd_hook
