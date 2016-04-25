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

alias be='bundle exec'
alias bi='bundle install --path vendor/bundle'
alias r='bundle exec rails'
alias ww="cd ~/workspace/ "
alias pu="pushd"
alias po="popd"

# alias - Ocaml
alias ocaml='rlwrap ocaml'

if [[ -x `which colordiff` ]]; then
  alias diff='colordiff -u'
else
  alias diff='diff -u'
fi

# vagrant
alias v='vagrant version && vagrant global-status'
alias vst='vagrant status'
alias vup='vagrant up'
alias vdo='vagrant halt'
alias vssh='vagrant ssh'
alias vkill='vagrant destroy'
# laravel 
alias pa="php artisan"
alias par="php artisan routes"
alias pam="php artisan migrate"
alias pam:r="php artisan migrate:refresh"
alias pam:roll="php artisan migrate:rollback"
alias pam:rs="php artisan migrate:refresh --seed"
alias pda="php artisan dumpautoload"
alias cu="composer update"
alias ci="composer install"
alias cda="composer dump-autoload -o"



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

# GOLANG環境設定 #############           
if [ -x "`which go`" ]; then              
export GOPATH=~/GOPATH/      
export GOROOT=/usr/local/go                 
export CC=clang # textql用                  
fi                                          
