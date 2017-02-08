#!/usr/bin/env bash

#usage: ./dotfilesLink {DOTFILES_PATH}
#exsample: ./dotfilesLink `pwd`  

export DOTFILES_PATH=$1

if [ $# -ne 1 ]; then
	echo "Error: One argument is required to execute" 1>&2
	exit 1
fi

ln -sf ${DOTFILES_PATH}/.zshrc ~/.zshrc
ln -sf ${DOTFILES_PATH}/.vimrc ~/.vimrc
ln -sf ${DOTFILES_PATH}/.tmuxinatior ~/.tmuxinatior
ln -sf ${DOTFILES_PATH}/.tmux.conf ~/.tmux.conf
