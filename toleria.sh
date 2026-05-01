#!/bin/bash

###############################################################################
# Toleria Knowledge Orchestrator - Main Script
#
# Platform-agnostic core implementation
# No MCP dependency - pure bash/shell
#
# Works on: Linux, macOS, Windows (MSYS2/Cygwin)
#
# Usage:
#   toleria <function> [args...]
#
###############################################################################

set -e

# Load platform-agnostic helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform.sh"

# Config
VAULT_ROOT="${VAULT_ROOT:-$(get_home)/Documents/Vault}"
STRICT_MODE="${STRICT_MODE:-true}"
REPO_READ_ONLY="${REPO_READ_ONLY:-true}"

# Normalize paths
VAULT_ROOT="$(normalize_path "$VAULT_ROOT")"

# Utilities
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate vault exists
validate_vault() {
  if [[ ! -d "$VAULT_ROOT" ]]; then
    log_error "Vault not initialized at: $VAULT_ROOT"
    log_info "Run: /toleria init-vault"
    exit 1
  fi
}

# Validate repo path
validate_repo() {
  local repo="$1"
  if [[ ! -d "$repo/.git" ]]; then
    log_error "Not a git repository: $repo"
    exit 1
  fi
}

# Validate path doesn't write to repo
validate_write_target() {
  local target="$1"
  local repo="$2"

  if [[ "$REPO_READ_ONLY" == "true" ]]; then
    # Check if target is inside repo
    if [[ "$target" == "$repo"* ]]; then
      log_error "Attempted write inside repository (read-only mode): $target"
      exit 1
    fi
  fi
}

# Get repo name
get_repo_name() {
  basename "$1"
}

# Detect language
detect_language() {
  local repo="$1"

  if [[ -f "$repo/go.mod" ]]; then
    echo "Go"
  elif [[ -f "$repo/Cargo.toml" ]]; then
    echo "Rust"
  elif [[ -f "$repo/Gemfile" ]]; then
    echo "Ruby"
  elif [[ -f "$repo/requirements.txt" ]] || [[ -f "$repo/setup.py" ]] || [[ -f "$repo/pyproject.toml" ]]; then
    echo "Python"
  elif [[ -f "$repo/package.json" ]]; then
    echo "JavaScript"
  elif [[ -f "$repo/pom.xml" ]]; then
    echo "Java"
  elif [[ -f "$repo/build.gradle" ]]; then
    echo "Java"
  else
    echo "Unknown"
  fi
}

# Detect framework
detect_framework() {
  local repo="$1"

  if [[ -f "$repo/pom.xml" ]] && platform_grep "spring-boot" "$repo/pom.xml" >/dev/null 2>&1; then
    echo "Spring Boot"
  elif [[ -f "$repo/requirements.txt" ]] && platform_grep "flask" "$repo/requirements.txt" >/dev/null 2>&1; then
    echo "Flask"
  elif [[ -f "$repo/requirements.txt" ]] && platform_grep "django" "$repo/requirements.txt" >/dev/null 2>&1; then
    echo "Django"
  elif [[ -f "$repo/package.json" ]] && platform_grep "react" "$repo/package.json" >/dev/null 2>&1; then
    echo "React"
  elif [[ -f "$repo/package.json" ]] && platform_grep "express" "$repo/package.json" >/dev/null 2>&1; then
    echo "Express"
  else
    echo "None"
  fi
}

# Detect database
detect_database() {
  local repo="$1"

  if [[ -n "$(platform_grep_r_type "postgres\|postgresql" "*.json" "$repo" | head -1)" ]]; then
    echo "Postgres"
  elif [[ -n "$(platform_grep_r_type "mysql" "*.json" "$repo" | head -1)" ]]; then
    echo "MySQL"
  elif [[ -n "$(platform_grep_r_type "mongodb" "*.json" "$repo" | head -1)" ]]; then
    echo "MongoDB"
  elif [[ -n "$(platform_grep_r_type "sqlite" "*.json" "$repo" | head -1)" ]]; then
    echo "SQLite"
  else
    echo "None"
  fi
}

# Generate STACK_ID
generate_stack_id() {
  local language="$1"
  local framework="$2"
  local database="$3"

  # Convert to UPPER_SNAKE_CASE (using parameter expansion instead of sed for portability)
  language=$(echo "$language" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
  framework=$(echo "$framework" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
  database=$(echo "$database" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')

  # Remove _NONE and duplicate underscores using parameter expansion
  local stack_id="${language}_${framework}_${database}"
  stack_id="${stack_id//_NONE/}"  # Remove _NONE
  while [[ "$stack_id" == *"__"* ]]; do
    stack_id="${stack_id//__/_}"  # Replace __ with _
  done
  echo "$stack_id"
}

# Command: init-vault
cmd_init_vault() {
  log_info "Initializing vault at: $VAULT_ROOT"

  mkdir -p "$VAULT_ROOT"/{STACKS,PROJECTS,DECISIONS,PATTERNS/{logging,error-handling,api-design,testing,config-management},EXECUTION,INDEX}

  log_success "Vault structure created"

  # Create config file
  cat > "$VAULT_ROOT/vault.config.json" << EOF
{
  "vault_root": "$VAULT_ROOT",
  "strict_mode": $STRICT_MODE,
  "repo_read_only": $REPO_READ_ONLY,
  "deduplication": true,
  "created_at": "$(platform_date_iso8601)",
  "version": "1.0.0"
}
EOF

  log_success "Configuration saved"
}

# Command: identify-stack
cmd_identify_stack() {
  local repo="$1"

  validate_repo "$repo"

  log_info "Identifying stack for: $repo"

  local language=$(detect_language "$repo")
  local framework=$(detect_framework "$repo")
  local database=$(detect_database "$repo")

  local stack_id=$(generate_stack_id "$language" "$framework" "$database")

  log_success "Stack detected: $stack_id"

  cat << EOF
{
  "stack_id": "$stack_id",
  "language": "$language",
  "framework": "$framework",
  "database": "$database",
  "repo": "$repo"
}
EOF
}

# Command: scan-repo
cmd_scan_repo() {
  local repo="$1"

  validate_vault
  validate_repo "$repo"

  local repo_name=$(get_repo_name "$repo")
  local project_dir="$VAULT_ROOT/PROJECTS/$repo_name"

  log_info "Scanning: $repo_name"

  # Create project directory
  mkdir -p "$project_dir"

  # Get stack info
  local language=$(detect_language "$repo")
  local framework=$(detect_framework "$repo")
  local database=$(detect_database "$repo")
  local stack_id=$(generate_stack_id "$language" "$framework" "$database")

  # Get last commit
  local last_commit=$(cd "$repo" && git log -1 --format='%h' 2>/dev/null || echo "unknown")
  local last_commit_msg=$(cd "$repo" && git log -1 --format='%s' 2>/dev/null || echo "unknown")
  local last_commit_date=$(cd "$repo" && git log -1 --format='%aI' 2>/dev/null || echo "unknown")

  # Determine status
  local status="DEV"
  if [[ -f "$repo/package.json" ]] && grep -q '"version"' "$repo/package.json"; then
    status="ACTIVE"
  fi

  # Create project metadata
  cat > "$project_dir/project.meta.json" << EOF
{
  "project_id": "$repo_name",
  "repo_path": "$repo",
  "vault_path": "$project_dir",
  "stack_id": "$stack_id",
  "status": "$status",
  "language": "$language",
  "framework": "$framework",
  "database": "$database",
  "created_at": "$(platform_date_iso8601)",
  "last_updated": "$(platform_date_iso8601)",
  "last_commit": "$last_commit",
  "last_commit_msg": "$last_commit_msg",
  "last_commit_date": "$last_commit_date"
}
EOF

  # Create stack directory if needed
  local stack_dir="$VAULT_ROOT/STACKS/$stack_id"
  mkdir -p "$stack_dir"

  # Create/update stack metadata
  if [[ ! -f "$stack_dir/stack.meta.json" ]]; then
    cat > "$stack_dir/stack.meta.json" << EOF
{
  "stack_id": "$stack_id",
  "language": "$language",
  "framework": "$framework",
  "database": "$database",
  "projects": ["$repo_name"],
  "decision_count": 0,
  "pattern_count": 0,
  "created_at": "$(platform_date_iso8601)",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  else
    # Add project to existing stack (simple append, could be smarter)
    log_warn "Stack already exists: $stack_id"
  fi

  log_success "Project scanned: $repo_name (stack: $stack_id)"

  # Return result
  cat "$project_dir/project.meta.json"
}

# Command: health-check
cmd_health_check() {
  validate_vault

  log_info "Running health check..."

  local violations=0

  # Check for projects without stack_id
  for project in "$VAULT_ROOT/PROJECTS"/*; do
    if [[ -f "$project/project.meta.json" ]]; then
      if ! grep -q '"stack_id"' "$project/project.meta.json"; then
        log_warn "Missing stack_id: $(basename $project)"
        violations=$((violations + 1))
      fi
    fi
  done

  # Check for valid JSON
  for file in $(find "$VAULT_ROOT" -name "*.json"); do
    if ! jq empty "$file" 2>/dev/null; then
      log_warn "Invalid JSON: $file"
      violations=$((violations + 1))
    fi
  done

  if [[ $violations -eq 0 ]]; then
    log_success "Vault is healthy (0 violations)"
  else
    log_warn "Found $violations violations"
  fi

  echo "{\"status\": \"ok\", \"violations\": $violations}"
}

# Main dispatcher
main() {
  local cmd="$1"
  shift || true

  case "$cmd" in
    init-vault)
      cmd_init_vault "$@"
      ;;
    identify-stack)
      cmd_identify_stack "$@"
      ;;
    scan-repo)
      cmd_scan_repo "$@"
      ;;
    health-check)
      cmd_health_check "$@"
      ;;
    *)
      log_error "Unknown command: $cmd"
      echo "Usage: toleria <command> [args...]"
      echo "Commands: init-vault, identify-stack, scan-repo, health-check"
      exit 1
      ;;
  esac
}

main "$@"
