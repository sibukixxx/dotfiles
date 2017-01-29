# prompt
PS1="[@${HOST%%.*} %1~]%(!.#.$) "
RPROMPT="%T"                      # 右側に時間を表示する
setopt transient_rprompt          # 右側まで入力がきたら時間を消す
setopt prompt_subst               # 便利なプロント
bindkey -e                        # emacsライクなキーバインド
autoload -U compinit
compinit -u
setopt autopushd
setopt pushd_ignore_dups
setopt auto_cd
setopt list_packed
setopt list_types

# hisotry
HISTFILE=$HOME/.zsh-history           # 履歴をファイルに保存する
HISTSIZE=1000000                       # メモリ内の履歴の数
SAVEHIST=1000000                       # 保存される履歴の数
setopt hist_ignore_dups           # 重複を記録しない
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_reduce_blanks         # スペース排除
setopt extended_history               # 履歴ファイルに時刻を記録
setopt share_history                  # 端末間の履歴を共有
function history-all { history -E 1 } # 全履歴の一覧を出力する

# history 操作まわり
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# export
export EDITOR=/usr/local/bin/vim
export PATH="/usr/local/bin:/Users/shibukixxx/.local/bin:$PATH"
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export LS_COLORS='di=01;36'

## export original variable
export DOTFILES=$HOME/.ghq/github.com/sibukixxx/dotfiles
#export DOTFILES=$HOME/dotfiles

## 補完関連
# sudo でも頑張って補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1

# 基本的な設定
autoload -U predict-on
setopt no_hup

## java 環境変数
export MAVEN_OPTS=-Dfile.encoding=UTF-8
export JAVA_OPTIONS="-Dfile.encoding=UTF-8"
export _JAVA_OPTIONS="-Dfile.encoding=UTF-8"

# ディレクトリ名を入力するだけでカレントディレクトリを変更
setopt auto_cd
# タブキー連打で補完候補を順に表示
setopt auto_menu

# GOLANG環境設定 #############           
if [ -x "`which go`" ]; then              
export GOPATH=$HOME/godev
export PATH=$GOPATH/bin:$PATH
export GOROOT=/usr/local/opt/go/libexec # homebrew 
export CC=clang # textql用 

#Fot Appengine Go
export PATH=$GOPATH/src/gae/go_appengine:$PATH
fi                                          

# For npm
export PATH=$HOME/.nodebrew/current/bin:$PATH


# git settings # vcs info
autoload -Uz vcs_info
zstyle ':vcs_info:*' formats '(%s)-[%b]'
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a]'
precmd () {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
RPROMPT="%1(v|%F{magenta}%1v%f%F{green}[%~]%f|%F{green}[%~]%f)"


# TODO: export
# For Rust
export PATH=$HOME/.multirust/toolchains/stable/cargo/bin:$PATH
export PATH=$HOME/.multirust/toolchains/nightly/cargo/bin:$PATH
export PATH=$HOME/workspace/rust/src/rustc-1.11.0/src:$PATH


#[ -d "$DOTFILES/pkg/peco" ] && export PATH=$DOTFILES/pkg/peco:$PATH

# include
if [ `uname` = "Darwin" ]; then
  # Mac
  [ -f ${DOTFILES}/zsh/mac.zsh ] && source ${DOTFILES}/zsh/mac.zsh
  [ -f ${DOTFILES}/zsh/docker-machine.zsh ] && source ${DOTFILES}/zsh/docker-machine.zsh
  [ -f ${DOTFILES}/zsh/alias/mac_alias.zsh ] && source ${DOTFILES}/zsh/alias/mac_alias.zsh
elif [ `uname` = "Linux" ]; then
  [ -f ${DOTFILES}/zsh/ubuntu.zsh ] && source ${DOTFILES}/zsh/ubuntu.zsh
fi

[ -f ${DOTFILES}/zsh/peco.zsh ] && source ${DOTFILES}/zsh/peco.zsh
[ -f ${DOTFILES}/zsh/npm-completion.zsh ] && source ${DOTFILES}/zsh/npm-completion.zsh
[ -f ${DOTFILES}/zsh/alias/common_alias.zsh ] && source ${DOTFILES}/zsh/alias/common_alias.zsh

# The next line updates PATH for the Google Cloud SDK.
[ -f '/usr/local/bin/google-cloud-sdk/path.zsh.inc' ] && source '/usr/local/bin/google-cloud-sdk/path.zsh.inc'
# The next line enables shell command completion for gcloud.
[ -f '/usr/local/bin/google-cloud-sdk/completion.zsh.inc' ] && source '/usr/local/bin/google-cloud-sdk/completion.zsh.inc'
