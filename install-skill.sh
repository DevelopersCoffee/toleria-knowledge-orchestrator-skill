#!/bin/bash
###############################################################################
# install-skill.sh
#
# Install Toleria skills to ~/.claude/skills/ for use with Claude Code
#
# Usage:
#   ./install-skill.sh [skill-name] [--global] [--local]
#
# Examples:
#   ./install-skill.sh toleria-digital-twin
#   ./install-skill.sh toleria-digital-twin --global
#   ./install-skill.sh all
#
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="${1:-toleria-digital-twin}"
INSTALL_MODE="${2:---local}"

# Install locations
LOCAL_INSTALL="$SCRIPT_DIR/.claude/skills"
GLOBAL_INSTALL="${HOME}/.claude/skills"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

###############################################################################
# Helper: Install single skill
###############################################################################

install_skill() {
  local name="$1"
  local dest="$2"
  local src="$SCRIPT_DIR/skills/$name"

  if [ ! -d "$src" ]; then
    error "Skill not found: $src"
  fi

  # Create destination
  mkdir -p "$dest/$name"

  # Copy files
  cp -r "$src"/* "$dest/$name/" 2>/dev/null || true

  # Make scripts executable
  find "$dest/$name" -name "*.sh" -exec chmod +x {} \;

  success "Installed: $name → $dest/$name"
}

###############################################################################
# Helper: Register in CLAUDE.md
###############################################################################

register_skill() {
  local name="$1"
  local skill_path="$2"
  local skill_file="$skill_path/SKILL.md"
  local claude_md="${HOME}/.claude/CLAUDE.md"

  # Read skill description from SKILL.md
  local desc=$(grep "^# " "$skill_file" | head -1 | sed 's/^# //')

  # Check if already registered
  if grep -q "^- \*\*$name\*\*" "$claude_md" 2>/dev/null; then
    log "Already registered: $name"
    return
  fi

  # Add to CLAUDE.md
  cat >> "$claude_md" << EOF

# $name
- **$name** (\`$skill_path/SKILL.md\`) - $desc. Trigger: \`/$name\`
When the user types \`/$name\`, invoke the Skill tool with \`skill: "$name"\` before doing anything else.
EOF

  success "Registered in CLAUDE.md: $name"
}

###############################################################################
# Main
###############################################################################

log "Toleria Skills Installer"
echo ""

# Determine install destination
if [ "$INSTALL_MODE" = "--global" ]; then
  DEST="$GLOBAL_INSTALL"
  log "Mode: Global install (user skills)"
elif [ "$INSTALL_MODE" = "--local" ]; then
  DEST="$LOCAL_INSTALL"
  log "Mode: Local install (project skills)"
else
  DEST="$GLOBAL_INSTALL"
  log "Mode: Global install (default)"
fi

echo ""

# Install all or specific skill
if [ "$SKILL_NAME" = "all" ]; then
  log "Installing all skills..."
  for skill_dir in "$SCRIPT_DIR/skills"/*; do
    if [ -d "$skill_dir" ]; then
      skill=$(basename "$skill_dir")
      if [ -f "$skill_dir/SKILL.md" ]; then
        install_skill "$skill" "$DEST"
      fi
    fi
  done
else
  log "Installing: $SKILL_NAME"
  install_skill "$SKILL_NAME" "$DEST"
fi

echo ""

# Register skills in CLAUDE.md
log "Registering skills..."
if [ "$SKILL_NAME" = "all" ]; then
  for skill_dir in "$SCRIPT_DIR/skills"/*; do
    if [ -d "$skill_dir" ]; then
      skill=$(basename "$skill_dir")
      if [ -f "$skill_dir/SKILL.md" ]; then
        register_skill "$skill" "$DEST/$skill"
      fi
    fi
  done
else
  register_skill "$SKILL_NAME" "$DEST/$SKILL_NAME"
fi

echo ""
success "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Verify installation: ls $DEST/$SKILL_NAME/"
echo "  2. Reload Claude Code (restart IDE/terminal)"
echo "  3. Invoke skill: /$SKILL_NAME"
echo ""
