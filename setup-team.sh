#!/bin/bash

###############################################################################
# Toleria Skill - Team Installation Script
#
# One-command setup for team members
# Works on: Claude Code, Gemini CLI, Copilot CLI, Codex
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill/main/setup-team.sh | bash
#   OR
#   bash ./setup-team.sh
#
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Toleria Skill - Team Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Clone or use existing
log_info "Step 1/4: Getting toleria-knowledge-orchestrator-skill..."

REPO_URL="https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git"
TEMP_DIR="/tmp/toleria-setup-$$"

if [[ -d "/Users/udaychauhan/workspace/toleria-knowledge-orchestrator-skill" ]]; then
  log_warn "Using local copy from workspace"
  SKILL_SOURCE="/Users/udaychauhan/workspace/toleria-knowledge-orchestrator-skill"
else
  log_info "Cloning from GitHub..."
  mkdir -p "$TEMP_DIR"
  git clone "$REPO_URL" "$TEMP_DIR/toleria" 2>/dev/null
  SKILL_SOURCE="$TEMP_DIR/toleria"
  log_success "Cloned"
fi

echo ""
log_info "Step 2/4: Installing to ~/.agents/skills/toleria..."

mkdir -p ~/.agents/skills
cp -r "$SKILL_SOURCE" ~/.agents/skills/toleria
log_success "Installed"

echo ""
log_info "Step 3/4: Creating platform symlinks..."

for platform in claude gemini copilot codex; do
  platform_dir="$HOME/.${platform}/skills"
  mkdir -p "$platform_dir"

  if [[ -e "$platform_dir/toleria" ]]; then
    rm -rf "$platform_dir/toleria"
  fi

  ln -s ~/.agents/skills/toleria "$platform_dir/toleria"
  log_success "${platform}: $platform_dir/toleria"
done

echo ""
log_info "Step 4/4: Initializing vault..."

if bash ~/.agents/skills/toleria/toleria.sh init-vault >/dev/null 2>&1; then
  log_success "Vault initialized at ~/Documents/Vault"
else
  log_warn "Vault init skipped (might already exist)"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Toleria is ready to use in:"
echo "  • Claude Code"
echo "  • Gemini CLI"
echo "  • Copilot CLI"
echo "  • Codex"
echo ""
echo "Quick start:"
echo "  1. Restart your IDE/CLI"
echo "  2. Run: /toleria scan-repo ~/workspace/my-project"
echo "  3. Or: /toleria init-vault"
echo ""
echo "Documentation:"
echo "  • README: ~/.agents/skills/toleria/README.md"
echo "  • Install: ~/.agents/skills/toleria/INSTALL.md"
echo "  • Skill: ~/.agents/skills/toleria/SKILL.md"
echo ""
echo "Vault location:"
echo "  ~/.agents/skills/toleria/vault.config.json"
echo ""

# Cleanup
if [[ -d "$TEMP_DIR" ]]; then
  rm -rf "$TEMP_DIR"
fi

log_success "Team setup complete!"
