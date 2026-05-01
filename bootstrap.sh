#!/bin/bash

###############################################################################
# Toleria Knowledge Orchestrator - Bootstrap Script
#
# Initialize vault structure and perform first scan
# Works on: Linux, macOS, Windows (MSYS2/Cygwin)
#
# Usage:
#   ./bootstrap.sh [--vault-root ~/Documents/Vault] [--workspace ~/workspace]
#
###############################################################################

set -e

# Load platform-agnostic helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform.sh"

# Defaults
VAULT_ROOT="$(get_home)/Documents/Vault"
WORKSPACE_ROOT="$(get_home)/workspace"
STRICT_MODE=true
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --vault-root)
      VAULT_ROOT="$2"
      shift 2
      ;;
    --workspace)
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Normalize paths
VAULT_ROOT="$(normalize_path "$VAULT_ROOT")"
WORKSPACE_ROOT="$(normalize_path "$WORKSPACE_ROOT")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Toleria Knowledge Orchestrator${NC}"
echo -e "${BLUE}Bootstrap Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Vault Root: ${VAULT_ROOT}"
echo "  Workspace: ${WORKSPACE_ROOT}"
echo "  Strict Mode: ${STRICT_MODE}"
echo "  Dry Run: ${DRY_RUN}"
echo ""

# Step 1: Validate paths
echo -e "${BLUE}[1/5] Validating paths...${NC}"
if [[ ! -d "$WORKSPACE_ROOT" ]]; then
  echo -e "${RED}ERROR: Workspace not found: ${WORKSPACE_ROOT}${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Workspace found${NC}"

# Step 2: Create vault structure
echo ""
echo -e "${BLUE}[2/5] Creating vault structure...${NC}"

create_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo -e "${YELLOW}  → ${dir} (exists)${NC}"
  else
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$dir"
    fi
    echo -e "${GREEN}  ✓ ${dir}${NC}"
  fi
}

create_dir "${VAULT_ROOT}"
create_dir "${VAULT_ROOT}/STACKS"
create_dir "${VAULT_ROOT}/PROJECTS"
create_dir "${VAULT_ROOT}/DECISIONS"
create_dir "${VAULT_ROOT}/PATTERNS"
create_dir "${VAULT_ROOT}/PATTERNS/logging"
create_dir "${VAULT_ROOT}/PATTERNS/error-handling"
create_dir "${VAULT_ROOT}/PATTERNS/api-design"
create_dir "${VAULT_ROOT}/PATTERNS/testing"
create_dir "${VAULT_ROOT}/PATTERNS/config-management"
create_dir "${VAULT_ROOT}/EXECUTION"
create_dir "${VAULT_ROOT}/INDEX"

echo -e "${GREEN}✓ Vault structure created${NC}"

# Step 3: Initialize index files
echo ""
echo -e "${BLUE}[3/5] Initializing index files...${NC}"

create_index_file() {
  local file="$1"
  local content="$2"

  if [[ "$DRY_RUN" == false ]]; then
    if [[ ! -f "$file" ]]; then
      echo "$content" > "$file"
      echo -e "${GREEN}  ✓ Created ${file}${NC}"
    else
      echo -e "${YELLOW}  → ${file} (exists)${NC}"
    fi
  else
    echo -e "${BLUE}  [dry-run] Would create ${file}${NC}"
  fi
}

# Stack index
create_index_file "${VAULT_ROOT}/INDEX/stack_index.json" \
'{
  "stacks": [],
  "last_updated": "'$(platform_date_iso8601)'",
  "total_stacks": 0,
  "total_projects": 0
}'

# Project index
create_index_file "${VAULT_ROOT}/INDEX/project_index.json" \
'{
  "projects": [],
  "last_updated": "'$(platform_date_iso8601)'",
  "total_projects": 0
}'

# Decision index
create_index_file "${VAULT_ROOT}/INDEX/decision_index.json" \
'{
  "decisions": [],
  "last_updated": "'$(platform_date_iso8601)'",
  "total_decisions": 0
}'

# Pattern index
create_index_file "${VAULT_ROOT}/INDEX/pattern_index.json" \
'{
  "patterns": [],
  "last_updated": "'$(platform_date_iso8601)'",
  "total_patterns": 0
}'

# Config
create_index_file "${VAULT_ROOT}/vault.config.json" \
'{
  "vault_root": "'${VAULT_ROOT}'",
  "strict_mode": '${STRICT_MODE}',
  "repo_read_only": true,
  "deduplication": true,
  "created_at": "'$(platform_date_iso8601)'",
  "version": "1.0.0"
}'

echo -e "${GREEN}✓ Index files initialized${NC}"

# Step 4: Scan workspace for repositories
echo ""
echo -e "${BLUE}[4/5] Scanning workspace for repositories...${NC}"

REPO_COUNT=0
while IFS= read -r repo_path; do
  if [[ -d "$repo_path/.git" ]]; then
    REPO_COUNT=$((REPO_COUNT + 1))
    repo_name=$(basename "$repo_path")
    echo -e "${YELLOW}  Found: ${repo_name}${NC}"
  fi
done < <(platform_find "$WORKSPACE_ROOT" 3 -type d -name ".git" 2>/dev/null | sed 's|/.git||')

echo -e "${GREEN}✓ Found ${REPO_COUNT} repositories${NC}"

# Step 5: Create README
echo ""
echo -e "${BLUE}[5/5] Creating vault README...${NC}"

if [[ "$DRY_RUN" == false ]]; then
  cat > "${VAULT_ROOT}/README.md" << 'EOF'
# Toleria Vault

Central knowledge repository for personal engineering projects.

## Structure

- **STACKS/** — Technology stack definitions and linked projects
- **PROJECTS/** — One-to-one mapping of repositories to projects
- **DECISIONS/** — Canonical decision library (deduplicated globally)
- **PATTERNS/** — Reusable code and design patterns by category
- **EXECUTION/** — Real-time project state and activity tracking
- **INDEX/** — Fast lookup indexes (auto-maintained)

## Quick Start

```bash
# Initialize vault (first time only)
/toleria init-vault

# Scan a project
/toleria scan-repo ~/workspace/my-project

# Scan all projects
/toleria scan-all-repos ~/workspace

# Find patterns for a tech stack
/toleria query stack JAVA_SPRING

# Check vault health
/toleria health-check
```

## Key Rules

1. **One repo = one project** (strict 1:1 mapping)
2. **Vault only** (never write docs inside repo)
3. **No duplication** (global deduplication enforced)
4. **Stack required** (every project must have stack_id)
5. **State current** (EXECUTION/ always reflects reality)

## Usage

See [SKILL.md](../SKILL.md) for complete documentation.

---

Generated: $(platform_date_iso8601)
Vault Root: $VAULT_ROOT
EOF
  echo -e "${GREEN}✓ README created${NC}"
fi

# Final report
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Bootstrap Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Vault Root: ${VAULT_ROOT}"
echo "Workspace: ${WORKSPACE_ROOT}"
echo "Repositories Found: ${REPO_COUNT}"
echo ""
echo "Next Steps:"
echo "  1. Install skill to your platform:"
echo "     - Claude Code: ~/.claude/skills/"
echo "     - Gemini CLI: ~/.gemini/skills/"
echo "     - Copilot CLI: ~/.copilot/skills/"
echo ""
echo "  2. Scan your projects:"
echo "     /toleria scan-all-repos ${WORKSPACE_ROOT}"
echo ""
echo "  3. Explore your vault:"
echo "     /toleria query stack <STACK_NAME>"
echo ""
echo "Documentation: See SKILL.md"
echo ""
