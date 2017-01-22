#!/usr/bin/env bash

#usage: ./dotfilesLink {DOTFILES_PATH}

export DOTFILES_PATH=$1

ln -sf ${DOTFILES_PATH}/.zshrc ~/.zshrc
ln -sf ${DOTFILES_PATH}/.vimrc ~/.vimrc
