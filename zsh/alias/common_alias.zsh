# alias
alias ls='ls -G'
alias ll='ls -la'
alias la='ls -A'
alias lal="ls -l -A"
alias cp="cp -i"
alias mv="mv -i"
alias locate="locate -i"
alias lv="lv -c -T8192"
if [[ -x `which colordiff` ]]; then
  alias diff='colordiff -u'
else
  alias diff='diff -u'
fi

# for Git
alias pu="pushd"
alias po="popd"

# for Ocaml
alias ocaml='rlwrap ocaml'

# for Go
alias gopath='cd $GOPATH'

# for iPython
alias iPythonNotebook='cd ~/Dropbox/ipythondir;jupyter notebook'



