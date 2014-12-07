alias r=rails
alias ll= ls-la
alias be='bundle exec'
alias bi='bundle install --path vendor/bundle'
alias r='bundle exec rails'
alias ww="cd ~/workspace/ "
alias pu="pushd"
alias po="popd"

# prompt
PS1="[@${HOST%%.*} %1~]%(!.#.$) "
RPROMPT="%T"                      # 右側に時間を表示する
setopt transient_rprompt          # 右側まで入力がきたら時間を消す
setopt prompt_subst               # 便利なプロント
bindkey -e                        # emacsライクなキーバインド
autoload -U compinit
compinit -u
compinit
setopt autopushd
setopt pushd_ignore_dups
setopt auto_cd
setopt list_packed
setopt list_types

# hisotry
HISTFILE=$HOME/.zsh-history           # 履歴をファイルに保存する
HISTSIZE=100000                       # メモリ内の履歴の数
SAVEHIST=100000                       # 保存される履歴の数
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
export EDITOR=/usr/bin/vim
export PATH="/usr/local/bin:$PATH"
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export LS_COLORS='di=01;36'

# function
#rm() {
#    mv $* ~/.Trash/
#}

# alias
alias ls='ls -G'
alias ll='ls -la'
alias la='ls -A'
alias lal="ls -l -A"
alias cp="cp -i"
alias mv="mv -i"
alias locate="locate -i"
alias lv="lv -c -T8192"
alias py=python

## 補完関連
# sudo でも頑張って補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1

# 基本的な設定
autoload -U predict-on
setopt no_hup

## ターミナルのウィンドウ・タイトルを動的に変更.3 -- screen 対応版
precmd() {
    [[ -t 1 ]] || return
    case $TERM in
        *xterm*|rxvt|(dt|k|E)term)
            #print -Pn "\e]2;%n%%${ZSH_NAME}@%m:%~ [%l]\a"
            #print -Pn "\e]2;[%n@%m %~] [%l]\a"
            print -Pn "\e]2;[%n@%m %~]\a"      # %l ← pts/1 等の表示を削除
            ;;
        # screen)
        #      #print -Pn "\e]0;[%n@%m %~] [%l]\a"
        #      print -Pn "\e]0;[%n@%m %~]\a"
        #      ;;
    esac
}

## java 環境変数
export MAVEN_OPTS=-Dfile.encoding=UTF-8
export JAVA_OPTIONS="-Dfile.encoding=UTF-8"
export _JAVA_OPTIONS="-Dfile.encoding=UTF-8"

# title bar 変更
function title()
{
    echo -n "\e]2;$1\a"
}

# function
funtion datetime()
{
    date +'%Y%m%d_%H%M%S'
}




# ディレクトリ名を入力するだけでカレントディレクトリを変更
setopt auto_cd
# タブキー連打で補完候補を順に表示
setopt auto_menu


WORKON_HOME=$HOME/venvs
SCALA_HOME=/usr/local/share/scala 
PATH=$HOME/local/py3/bin:$PATH

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/Users/takada_yuichi/.gvm/bin/gvm-init.sh" ]] && source "/Users/takada_yuichi/.gvm/bin/gvm-init.sh"


PATH=$HOME/local/py3/bin:$PATH
WORKON_HOME=$HOME/venvs
. ~/local/py3/bin/virtualenvwrapper.sh


# GOLANG 用PATH設定 #############           
if [ -x "`which go`" ]; then              
export GOPATH=/Users/takada_yuichi/GOPATH/      
export GOROOT=/usr/local/go                 
export CC=clang # textql用                  
fi                                          
################################            

export PATH=/Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin:/usr/local/php5/bin:/Users/takada_yuichi/local/py3/bin:/usr/local/heroku/bin:/usr/local/bin:/Users/takada_yuichi/usr/local/hadoop/bin:/usr/local/bin:/Users/takada_yuichi/Library/Haskell/bin:/opt/local/bin:/opt/local/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/local/git/bin:/Users/takada_yuichi/Library/Haskell/bin:/Users/takada_yuichi/.rbenv/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/usr/local/git/bin:/usr/local/go/bin:/Applications/Sublime:/Users/takada_yuichi/GOPATH/bin


## ghq + peco  #######################
stty stop undef
function peco-src () {
    local selected_dir=$(ghq list --full-path | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-src
bindkey '^S' peco-src
#########################################

#######################################
# peco hitory
#######################################
function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac=";tac";
    else
        tac=";tail -r";
    fi
    BUFFER=$(history -n 1|   \
        eval $tac | \
        peco --query "$LBUFFER";)
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

function vig {
    STR="$1"
    vim $(grep -n ${STR} **/*.go | grep -v "[0-9]:\s*//" | peco | awk -F ":" '{print "-c "$2" "$1}')
}


