#!/usr/bin/env bash

set -euo pipefail

source_root=${AI_CONFIG_SOURCE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}
managed_dir="$source_root/.codex"
target_dir=${AI_CONFIG_CODEX_DIR:-"$HOME/.codex"}

backup_existing() {
    local path=$1
    local backup="${path}.bak"
    local suffix=1

    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="${path}.bak.${suffix}"
        suffix=$((suffix + 1))
    done

    mv "$path" "$backup"
    printf 'Backed up %s to %s\n' "$path" "$backup"
}

link_managed_path() {
    local source=$1
    local target=$2

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        return
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        backup_existing "$target"
    fi

    ln -s "$source" "$target"
    printf 'Linked %s -> %s\n' "$target" "$source"
}

mkdir -p "$target_dir" "$target_dir/skills"

if [ ! -e "$target_dir/config.toml" ] && [ -e "$managed_dir/config.default.toml" ]; then
    cp "$managed_dir/config.default.toml" "$target_dir/config.toml"
    printf 'Created local %s from portable defaults\n' "$target_dir/config.toml"
fi

for name in AGENTS.md hooks.json agents hooks rules; do
    if [ -e "$managed_dir/$name" ]; then
        link_managed_path "$managed_dir/$name" "$target_dir/$name"
    fi
done

for source in "$managed_dir"/skills/*; do
    [ -d "$source" ] || continue
    name=$(basename "$source")
    link_managed_path "$source" "$target_dir/skills/$name"
done

printf 'Codex configuration setup complete\n'
