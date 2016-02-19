"-------基本設定--------

"バックスペースキーで行頭を削除する
set backspace=indent,eol,start

"ターミナル接続を高速にする
set ttyfast

"ターミナルで256色表示を使う
set t_Co=256

"vi互換の動作を無効にする
set nocompatible

"ルーラー,行番号を表示
set ruler
set number

"カッコを閉じたとき対応するカッコに一時的に移動
set nostartofline

"タイトルをバッファ名に変更する
set title
set encoding=utf-8
set softtabstop=4

"検索結果をハイライトする
set hlsearch

"ステータスラインにコマンドを表示
set showcmd

"内容が変更されたら自動的に再読み込み
set autoread

"大文字小文字を区別しない
set ignorecase
"大文字で検索されたら対象を大文字限定にする
set smartcase

"行末まで検索したら行頭に戻る
set wrapscan

"バックアップを作成しない
set nobackup

set clipboard+=unnamed
set paste
syntax on

"コマンド、検索パターンを50まで保存
set history=50

"履歴に保存する各種設定
set viminfo='100,/50,%,<1000,f50,s100,:100,c,h,!


""##### Search ######
"インクリメンタルサーチを有効にする
set incsearch

"大文字小文字を区別しない
set ignorecase

"大文字で検索されたら対象を大文字限定にする
set smartcase

"行末まで検索したら行頭に戻る
set wrapscan


""######## Format #########
"自動インデントを有効化する
set smartindent
set autoindent

"括弧の対応をハイライト
set showmatch


"タブ、空白、改行の可視化
"set list
"set listchars=tab:>.,trail:_,eol:↲,extends:>,precedes:<,nbsp:%

" ブックマークを最初から表示
let g:NERDTreeShowBookmarks=1

"全角スペースをハイライト表示
function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=reverse ctermfg=DarkMagenta gui=reverse guifg=DarkMagenta
endfunction
   
if has('syntax')
    augroup ZenkakuSpace
        autocmd!
        autocmd ColorScheme       * call ZenkakuSpace()
        autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
    augroup END
    call ZenkakuSpace()
endif



"--------------------------------------------------------------------------
" neobundle

set nocompatible               " Be iMproved
filetype off                   " Required!

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))

filetype plugin indent on     " Required!

" Installation check.
if neobundle#exists_not_installed_bundles()
    echomsg 'Not installed bundles : ' .
          \ string(neobundle#get_not_installed_bundle_names())
    echomsg 'Please execute ":NeoBundleInstall" command.'   
    "finish
endif
              
" ここに入れたいプラグインを記入
NeoBundle 'mattn/emmet-vim'
" NERDTreeを設定 
NeoBundle 'scrooloose/nerdtree'
" indent
NeoBundle 'Yggdroot/indentLine'
NeoBundle 'Shougo/vimproc', {
  \ 'build' : {
    \ 'windows' : 'make -f make_mingw32.mak',
    \ 'cygwin' : 'make -f make_cygwin.mak',
    \ 'mac' : 'make -f make_mac.mak',
    \ 'unix' : 'make -f make_unix.mak',
  \ },
\ }
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/vimproc'
NeoBundle 'Shougo/unite-outline'

call neobundle#end()

" outlineの設定
let g:unite_split_rule = 'botright'
"noremap <C-o> <ESC>:Unite -vertical -no-quit -winwidth=40 outline<Return>
nnoremap <silent> <Leader>o :<C-u>Unite -vertical -no-quit outline<CR>


" makefile用
autocmd FileType make setlocal noexpandtab
filetype plugin indent on
