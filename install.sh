#!/bin/bash

###############################################################################
# Toleria Skill - Universal Installation Script
#
# Installs skill to central location and symlinks from all agent platforms
# Works on: Claude Code, Gemini CLI, Copilot CLI
#
# Usage:
#   ./install.sh [--uninstall]
#
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="toleria"
AGENTS_DIR="$HOME/.agents/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Uninstall mode
if [[ "$1" == "--uninstall" ]]; then
  log_info "Uninstalling $SKILL_NAME from all platforms..."

  for platform_dir in ~/.claude/skills ~/.codex/skills ~/.gemini/skills ~/.copilot/skills; do
    if [[ -L "$platform_dir/$SKILL_NAME" ]]; then
      rm "$platform_dir/$SKILL_NAME"
      log_success "Removed symlink from $platform_dir"
    fi
  done

  if [[ -d "$AGENTS_DIR/$SKILL_NAME" ]]; then
    rm -rf "$AGENTS_DIR/$SKILL_NAME"
    log_success "Removed central installation"
  fi

  log_success "Uninstall complete"
  exit 0
fi

# Install mode
log_info "Installing $SKILL_NAME skill..."
log_info "Source: $SCRIPT_DIR"
log_info "Central location: $AGENTS_DIR"
echo ""

# Step 1: Copy to central location
log_info "Step 1/3: Installing to central location..."
mkdir -p "$AGENTS_DIR"
cp -r "$SCRIPT_DIR" "$AGENTS_DIR/$SKILL_NAME"
log_success "Copied to $AGENTS_DIR/$SKILL_NAME"
echo ""

# Step 2: Create symlinks for each platform
log_info "Step 2/3: Creating platform symlinks..."

declare -A platforms=(
  ["Claude Code"]="$HOME/.claude/skills"
  ["Gemini CLI"]="$HOME/.gemini/skills"
  ["Copilot CLI"]="$HOME/.copilot/skills"
  ["Codex"]="$HOME/.codex/skills"
)

for platform_name in "${!platforms[@]}"; do
  platform_dir="${platforms[$platform_name]}"

  if [[ ! -d "$platform_dir" ]]; then
    mkdir -p "$platform_dir"
    log_warn "Created $platform_dir"
  fi

  # Remove old symlink/directory if exists
  if [[ -e "$platform_dir/$SKILL_NAME" ]]; then
    rm -rf "$platform_dir/$SKILL_NAME"
  fi

  # Create symlink to central location
  ln -s "$AGENTS_DIR/$SKILL_NAME" "$platform_dir/$SKILL_NAME"
  log_success "$platform_name: $platform_dir/$SKILL_NAME"
done
echo ""

# Step 3: Verify installation
log_info "Step 3/3: Verifying installation..."

all_ok=true
for platform_name in "${!platforms[@]}"; do
  platform_dir="${platforms[$platform_name]}"
  if [[ -L "$platform_dir/$SKILL_NAME" ]]; then
    target=$(readlink "$platform_dir/$SKILL_NAME")
    log_success "$platform_name: OK → $target"
  else
    log_error "$platform_name: FAILED"
    all_ok=false
  fi
done
echo ""

if [[ "$all_ok" == true ]]; then
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Installation Complete!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Skill available on:"
  echo "  • Claude Code"
  echo "  • Gemini CLI"
  echo "  • Copilot CLI"
  echo "  • Codex"
  echo ""
  echo "Use in any platform:"
  echo "  /toleria init-vault"
  echo "  /toleria scan-repo ~/workspace/my-project"
  echo "  /toleria health-check"
  echo ""
  echo "Central location: $AGENTS_DIR/$SKILL_NAME"
  echo "Uninstall: ./install.sh --uninstall"
  echo ""
else
  log_error "Installation had issues"
  exit 1
fi
