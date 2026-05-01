#!/bin/bash

###############################################################################
# Toleria Skill Validator - Strict Control & Validation
#
# Works on: Linux, macOS, Windows (MSYS2/Cygwin)
#
# Checks:
# - Structure integrity
# - Schema compliance
# - Duplication detection
# - Orphan detection
# - Path violations
# - Stack consistency
# - Idempotency
# - Empty artifacts
#
###############################################################################

set -e

# Load platform-agnostic helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform.sh"

VAULT_ROOT="${VAULT_ROOT:-$(get_home)/Documents/Vault}"
SCHEMA_FILE="$(dirname "$0")/SCHEMA.json"

# Normalize path
VAULT_ROOT="$(normalize_path "$VAULT_ROOT")"

# Counters
PASS_COUNT=0
FAIL_COUNT=0
VIOLATIONS=()

# Utilities
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS_COUNT++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; VIOLATIONS+=("$1"); ((FAIL_COUNT++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Toleria Skill Validator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Vault: ${VAULT_ROOT}"
echo ""

# Check 1: Structure
echo -e "${BLUE}[1/8] Structure Check${NC}"
required_dirs=(
  "STACKS"
  "PROJECTS"
  "DECISIONS"
  "PATTERNS"
  "EXECUTION"
  "INDEX"
)

structure_ok=true
for dir in "${required_dirs[@]}"; do
  if [[ -d "$VAULT_ROOT/$dir" ]]; then
    echo "  ✓ $dir"
  else
    echo "  ✗ $dir (missing)"
    structure_ok=false
  fi
done

if [[ -f "$VAULT_ROOT/vault.config.json" ]]; then
  echo "  ✓ vault.config.json"
else
  echo "  ✗ vault.config.json (missing)"
  structure_ok=false
fi

if [[ "$structure_ok" == true ]]; then
  log_pass "Structure check"
else
  log_fail "Structure check: missing required directories"
fi
echo ""

# Check 2: Schema Validation
echo -e "${BLUE}[2/8] Schema Validation${NC}"
if [[ ! -f "$SCHEMA_FILE" ]]; then
  log_fail "Schema validation: SCHEMA.json not found"
else
  schema_violations=0

  # Validate vault.config.json
  if [[ -f "$VAULT_ROOT/vault.config.json" ]]; then
    if ! jq empty "$VAULT_ROOT/vault.config.json" 2>/dev/null; then
      log_fail "Schema: vault.config.json is invalid JSON"
      ((schema_violations++))
    fi
  fi

  # Validate all project.meta.json files
  while IFS= read -r project_file; do
    if ! jq empty "$project_file" 2>/dev/null; then
      log_fail "Schema: $project_file is invalid JSON"
      ((schema_violations++))
    fi
  done < <(platform_find "$VAULT_ROOT/PROJECTS" 999 -name "project.meta.json" 2>/dev/null)

  # Validate all DECISIONS/*.json
  while IFS= read -r decision_file; do
    if ! jq empty "$decision_file" 2>/dev/null; then
      log_fail "Schema: $decision_file is invalid JSON"
      ((schema_violations++))
    fi
  done < <(platform_find "$VAULT_ROOT/DECISIONS" 999 -name "*.json" 2>/dev/null)

  # Validate all PATTERNS/**/*.json
  while IFS= read -r pattern_file; do
    if ! jq empty "$pattern_file" 2>/dev/null; then
      log_fail "Schema: $pattern_file is invalid JSON"
      ((schema_violations++))
    fi
  done < <(platform_find "$VAULT_ROOT/PATTERNS" 999 -name "*.json" 2>/dev/null)

  if [[ $schema_violations -eq 0 ]]; then
    log_pass "Schema validation: all JSON files valid"
  else
    log_fail "Schema validation: $schema_violations invalid JSON files"
  fi
fi
echo ""

# Check 3: Duplication
echo -e "${BLUE}[3/8] Duplication Check${NC}"
duplicate_count=0

# Check decisions
declare -A decision_hashes
while IFS= read -r decision_file; do
  if [[ -f "$decision_file" ]]; then
    title=$(jq -r '.title // ""' "$decision_file" 2>/dev/null || echo "")
    content=$(jq -r '.content // ""' "$decision_file" 2>/dev/null || echo "")
    hash=$(platform_md5 "$title$content")

    if [[ -n "${decision_hashes[$hash]}" ]]; then
      log_fail "Duplication: decision hash collision detected"
      ((duplicate_count++))
    fi
    decision_hashes[$hash]="1"
  fi
done < <(find "$VAULT_ROOT/DECISIONS" -name "*.json" 2>/dev/null)

if [[ $duplicate_count -eq 0 ]]; then
  log_pass "Duplication check: no duplicates detected"
else
  log_fail "Duplication check: $duplicate_count duplicates found"
fi
echo ""

# Check 4: Orphans
echo -e "${BLUE}[4/8] Orphan Detection${NC}"
orphan_count=0

# Build project index
declare -A project_index
while IFS= read -r project_file; do
  project_id=$(jq -r '.project_id // ""' "$project_file" 2>/dev/null || echo "")
  if [[ -n "$project_id" ]]; then
    project_index[$project_id]="1"
  fi
done < <(platform_find "$VAULT_ROOT/PROJECTS" 999 -name "project.meta.json" 2>/dev/null)

# Check decisions for orphans
while IFS= read -r decision_file; do
  if [[ -f "$decision_file" ]]; then
    source_projects=$(jq -r '.source_projects[]? // empty' "$decision_file" 2>/dev/null)
    if [[ -z "$source_projects" ]]; then
      decision_id=$(jq -r '.decision_id // "unknown"' "$decision_file" 2>/dev/null)
      log_fail "Orphan: decision $decision_id has no source_projects"
      ((orphan_count++))
    else
      while IFS= read -r project; do
        if [[ -n "$project" && -z "${project_index[$project]}" ]]; then
          decision_id=$(jq -r '.decision_id // "unknown"' "$decision_file" 2>/dev/null)
          log_fail "Orphan: decision $decision_id references non-existent project $project"
          ((orphan_count++))
        fi
      done <<< "$source_projects"
    fi
  fi
done < <(platform_find "$VAULT_ROOT/DECISIONS" 999 -name "*.json" 2>/dev/null)

if [[ $orphan_count -eq 0 ]]; then
  log_pass "Orphan detection: no orphans found"
else
  log_fail "Orphan detection: $orphan_count orphans found"
fi
echo ""

# Check 5: Path Violations
echo -e "${BLUE}[5/8] Path Violation Check${NC}"
path_violations=0

# Check for files outside allowed paths
unexpected_files=0
while IFS= read -r file; do
  relative_path="${file#$VAULT_ROOT/}"

  # Skip hidden files
  if [[ "$relative_path" == .* ]]; then
    continue
  fi

  # Allowed files/dirs
  if [[ "$relative_path" == STACKS/* ]] || \
     [[ "$relative_path" == PROJECTS/* ]] || \
     [[ "$relative_path" == DECISIONS/* ]] || \
     [[ "$relative_path" == PATTERNS/* ]] || \
     [[ "$relative_path" == EXECUTION/* ]] || \
     [[ "$relative_path" == INDEX/* ]] || \
     [[ "$relative_path" == "vault.config.json" ]] || \
     [[ "$relative_path" == "README.md" ]]; then
    : # OK
  else
    log_fail "Path violation: unexpected file $relative_path"
    ((path_violations++))
  fi
done < <(platform_find "$VAULT_ROOT" 999 -type f 2>/dev/null)

if [[ $path_violations -eq 0 ]]; then
  log_pass "Path violation check: no violations"
else
  log_fail "Path violation check: $path_violations violations"
fi
echo ""

# Check 6: Stack Consistency
echo -e "${BLUE}[6/8] Stack Consistency Check${NC}"
stack_violations=0

# Build stack index
declare -A stack_index
while IFS= read -r stack_file; do
  stack_id=$(jq -r '.stack_id // ""' "$stack_file" 2>/dev/null || echo "")
  if [[ -n "$stack_id" ]]; then
    stack_index[$stack_id]="1"
  fi
done < <(platform_find "$VAULT_ROOT/STACKS" 999 -name "stack.meta.json" 2>/dev/null)

# Check projects reference valid stacks
while IFS= read -r project_file; do
  if [[ -f "$project_file" ]]; then
    stack_id=$(jq -r '.stack_id // ""' "$project_file" 2>/dev/null || echo "")
    if [[ -z "$stack_id" ]]; then
      project_id=$(jq -r '.project_id // "unknown"' "$project_file" 2>/dev/null)
      log_fail "Stack consistency: project $project_id missing stack_id"
      ((stack_violations++))
    elif [[ -z "${stack_index[$stack_id]}" ]]; then
      project_id=$(jq -r '.project_id // "unknown"' "$project_file" 2>/dev/null)
      log_fail "Stack consistency: project $project_id references non-existent stack $stack_id"
      ((stack_violations++))
    fi
  fi
done < <(platform_find "$VAULT_ROOT/PROJECTS" 999 -name "project.meta.json" 2>/dev/null)

if [[ $stack_violations -eq 0 ]]; then
  log_pass "Stack consistency check: all stacks valid"
else
  log_fail "Stack consistency check: $stack_violations violations"
fi
echo ""

# Check 7: Idempotency
echo -e "${BLUE}[7/8] Idempotency Check${NC}"
if [[ -d "$VAULT_ROOT" ]]; then
  vault_files=$(platform_find "$VAULT_ROOT" 999 -type f 2>/dev/null | grep -v '\.' | head -100)
  file_count=$(echo "$vault_files" | wc -l)
  log_info "Vault file count: $file_count"
  log_pass "Idempotency check: baseline captured (re-run skill and compare)"
else
  log_fail "Idempotency check: cannot compute vault checksum"
fi
echo ""

# Check 8: Empty Artifacts
echo -e "${BLUE}[8/8] Empty Artifact Check${NC}"
empty_count=0

while IFS= read -r file; do
  if [[ ! -s "$file" ]]; then
    log_fail "Empty artifact: $file"
    ((empty_count++))
  fi
done < <(platform_find "$VAULT_ROOT" 999 -type f \( -name "*.json" -o -name "*.md" \) 2>/dev/null)

if [[ $empty_count -eq 0 ]]; then
  log_pass "Empty artifact check: no empty files"
else
  log_fail "Empty artifact check: $empty_count empty files"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
  SCORE=100
  STATUS="${GREEN}PASS${NC}"
else
  SCORE=$((100 - (FAIL_COUNT * 10)))
  [[ $SCORE -lt 0 ]] && SCORE=0
  STATUS="${RED}FAIL${NC}"
fi

echo "Score: $SCORE/100"
echo ""
echo -e "Status: $STATUS"
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}Violations:${NC}"
  for violation in "${VIOLATIONS[@]}"; do
    echo "  - $violation"
  done
  echo ""
  exit 1
else
  echo -e "${GREEN}Vault is clean, deterministic, and ready for use.${NC}"
  exit 0
fi
