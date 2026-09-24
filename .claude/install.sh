#!/bin/bash
# Claude Code Configuration Setup Script
# Idempotent installation script for portable dotfiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLAUDE_DIR="$HOME/.claude"
DOTFILES_CLAUDE="$(cd "$(dirname "$0")" && pwd)"

# Older installations linked ~/.claude to a separate dotfiles clone. Replace
# that root link with a real runtime directory so only the explicit config
# paths below are managed and caches/history remain local to this machine.
if [ -L "$CLAUDE_DIR" ]; then
    CLAUDE_BACKUP="${CLAUDE_DIR}.bak"
    CLAUDE_BACKUP_SUFFIX=1
    while [ -e "$CLAUDE_BACKUP" ] || [ -L "$CLAUDE_BACKUP" ]; do
        CLAUDE_BACKUP="${CLAUDE_DIR}.bak.${CLAUDE_BACKUP_SUFFIX}"
        CLAUDE_BACKUP_SUFFIX=$((CLAUDE_BACKUP_SUFFIX + 1))
    done
    mv "$CLAUDE_DIR" "$CLAUDE_BACKUP"
    echo "Backed up legacy Claude link to $CLAUDE_BACKUP"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Claude Code Configuration Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to create symlink (replace if exists)
link_if_not_exists() {
    local src="$1"
    local dst="$2"
    local name="$3"

    if [ -L "$dst" ]; then
        # Remove existing symlink
        rm -f "$dst"
    elif [ -e "$dst" ]; then
        # Backup existing file/directory
        echo -e "${YELLOW}⚠ Backing up existing $name to ${dst}.bak${NC}"
        mv "$dst" "${dst}.bak"
    fi

    if [ -e "$src" ]; then
        ln -s "$src" "$dst"
        echo -e "${GREEN}✓ Linked: $name${NC}"
    else
        echo -e "${YELLOW}⚠ Source not found: $src${NC}"
    fi
}

# Function to check if a tool is installed
check_tool() {
    local tool="$1"
    local required="$2"

    if command -v "$tool" &> /dev/null; then
        local version=$(command "$tool" --version 2>/dev/null | head -n1 || echo "installed")
        echo -e "${GREEN}✓ $tool: $version${NC}"
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}✗ $tool: NOT INSTALLED (required)${NC}"
            return 1
        else
            echo -e "${YELLOW}⚠ $tool: NOT INSTALLED (optional)${NC}"
            return 0
        fi
    fi
}

# Create directories
echo -e "\n${BLUE}Creating directories...${NC}"
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/status/queue"
mkdir -p "$CLAUDE_DIR/cache"
echo -e "${GREEN}✓ Directories created${NC}"

# Create symlinks
echo -e "\n${BLUE}Creating symlinks...${NC}"
link_if_not_exists "$DOTFILES_CLAUDE/commands" "$CLAUDE_DIR/commands" "commands"
link_if_not_exists "$DOTFILES_CLAUDE/hooks" "$CLAUDE_DIR/hooks" "hooks"
link_if_not_exists "$DOTFILES_CLAUDE/agents" "$CLAUDE_DIR/agents" "agents"
link_if_not_exists "$DOTFILES_CLAUDE/skills" "$CLAUDE_DIR/skills" "skills"
link_if_not_exists "$DOTFILES_CLAUDE/rules" "$CLAUDE_DIR/rules" "rules"
link_if_not_exists "$DOTFILES_CLAUDE/contexts" "$CLAUDE_DIR/contexts" "contexts"
link_if_not_exists "$DOTFILES_CLAUDE/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
link_if_not_exists "$DOTFILES_CLAUDE/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"

# Install bun if not present
install_bun() {
    echo -e "${BLUE}Installing bun...${NC}"
    if curl -fsSL https://bun.sh/install | bash; then
        # Add to PATH for current session
        export PATH="$HOME/.bun/bin:$PATH"
        echo -e "${GREEN}✓ bun installed: $(bun --version)${NC}"
    else
        echo -e "${RED}✗ bun installation failed${NC}"
        return 1
    fi
}

# bun installed from bun.sh lives in ~/.bun/bin, which is not on PATH inside
# chezmoi run scripts. Make it visible so an existing install is not repeated.
export PATH="$HOME/.bun/bin:$PATH"

# settings.json calls ~/.bun/bin/bun by fixed path. When bun comes from Homebrew,
# nix or another manager, expose it under that path so hooks work on every machine.
ensure_bun_path() {
    if [ -x "$HOME/.bun/bin/bun" ]; then
        return 0
    fi
    local found
    found="$(command -v bun 2>/dev/null || true)"
    if [ -n "$found" ]; then
        mkdir -p "$HOME/.bun/bin"
        ln -sf "$found" "$HOME/.bun/bin/bun"
        echo -e "${GREEN}✓ Linked ~/.bun/bin/bun -> $found (hooks use this fixed path)${NC}"
    fi
}

# Check dependencies
echo -e "\n${BLUE}Checking dependencies...${NC}"
has_errors=0

# Required tools
if ! check_tool "bun" "required"; then
    install_bun || has_errors=1
fi
ensure_bun_path

# jq is required by the PreToolUse validators (validate-bash.sh / validate-read.sh);
# without it they silently allow everything.
check_tool "jq" "required" || has_errors=1
check_tool "git" "optional"

# Language-specific formatters (optional)
echo -e "\n${BLUE}Checking formatters (optional)...${NC}"
check_tool "gofmt" "optional"
check_tool "rustfmt" "optional"
check_tool "biome" "optional"

# OS-specific setup
echo -e "\n${BLUE}OS-specific setup...${NC}"
case "$(uname -s)" in
    Darwin)
        echo -e "${GREEN}✓ macOS detected${NC}"
        # macOS-specific setup if needed
        ;;
    Linux)
        echo -e "${GREEN}✓ Linux detected${NC}"
        # Linux-specific setup if needed
        ;;
    *)
        echo -e "${YELLOW}⚠ Unknown OS: $(uname -s)${NC}"
        ;;
esac

# Verify hooks can run
echo -e "\n${BLUE}Verifying hooks...${NC}"
if [ -f "$CLAUDE_DIR/hooks/session-start.ts" ]; then
    if bun run "$CLAUDE_DIR/hooks/session-start.ts" --dry-run < /dev/null 2>/dev/null; then
        echo -e "${GREEN}✓ Hooks verified${NC}"
    else
        echo -e "${YELLOW}⚠ Hook verification skipped${NC}"
    fi
fi

# Summary
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $has_errors -eq 0 ]; then
    echo -e "${GREEN}✓ Claude Code setup complete!${NC}"
else
    echo -e "${YELLOW}⚠ Setup complete with warnings${NC}"
    echo -e "${YELLOW}  Please install missing required dependencies${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Show available commands
echo -e "\n${BLUE}Available commands:${NC}"
if [ -d "$CLAUDE_DIR/commands" ]; then
    for cmd in "$CLAUDE_DIR/commands"/*.md; do
        if [ -f "$cmd" ]; then
            name=$(basename "$cmd" .md)
            echo -e "  /${name}"
        fi
    done
fi

echo ""
