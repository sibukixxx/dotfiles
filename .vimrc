set backspace=indent,eol,start
set number
set runtimepath+=~/.vim/
set hlsearch
set autoread
syntax on

" start dein 
if &compatible
  set nocompatible
endif
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

call dein#begin(expand('~/.vim/dein'))
call dein#add('Shougo/dein.vim')
" interface
" :call dein#install() # install dein
  " unite
    call dein#add('Shougo/unite.vim') "http: //qiita.com/hide/items/77b9c1b0f29577d60397
    call dein#add('Shougo/neomru.vim')
    call dein#add('Shougo/unite-outline')
    call dein#add('Shougo/unite-session')
  " filer
    call dein#add('Shougo/vimfiler.vim')
  " color
    call dein#add('jonathanfilip/vim-lucius')
    call dein#add('h1mesuke/vim-alignta')
    "call dein#add('aereal/vim-colors-japanesque')

call dein#add('Shougo/neosnippet-snippets')
call dein#add('vim-jp/vim-go-extra')
call dein#add('mattn/emmet-vim')
call dein#end()
let g:dein#types#git#clone_depth = 1
" もし、未インストールものものがあったらインストール
if dein#check_install()
  call dein#install()
endif

"" end dein

filetype plugin indent on

"setting golang
set noexpandtab
set tabstop=4
set shiftwidth=4

"setting rust
let g:rustfmt_autosave = 1
let g:rustfmt_command = '$HOME/.cargo/bin/rustfmt'
"setting racer
set hidden
let g:racer_cmd = '$HOME/.cargo/bin/racer'
let $RUST_SRC_PATH="/usr/local/src/rustc-1.5.0/src"

runtime! userautoload/*.vim
runtime! userautoload/init/*.vim
runtime! userautoload/plugins/*.vim
