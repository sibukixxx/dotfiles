#!/usr/bin/env bash

# usage: ./dotfilesLink.sh {DOTFILES_PATH}
# example: ./dotfilesLink.sh $(pwd)

set -e

DOTFILES_PATH="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

if [[ ! -d "$DOTFILES_PATH" ]]; then
  echo "Error: Invalid dotfiles path: $DOTFILES_PATH" >&2
  exit 1
fi

echo "==> Creating symbolic links..."
echo "    Dotfiles: $DOTFILES_PATH"

# Basic dotfiles
ln -sf "$DOTFILES_PATH/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_PATH/.vimrc" ~/.vimrc
ln -sf "$DOTFILES_PATH/.tmux.conf" ~/.tmux.conf

# XDG Base Directory: ~/.config/git/
mkdir -p ~/.config/git
for file in config ignore message; do
  if [[ -f "$DOTFILES_PATH/.config/git/$file" ]]; then
    ln -sf "$DOTFILES_PATH/.config/git/$file" ~/.config/git/$file
    echo "    Linked .config/git/$file"
  fi
done

# Remove legacy ~/.gitconfig if it's a symlink
if [[ -L ~/.gitconfig ]]; then
  rm ~/.gitconfig
  echo "    Removed legacy ~/.gitconfig"
fi

echo "==> Done"
