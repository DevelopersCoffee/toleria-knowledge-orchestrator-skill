#!/bin/bash
###############################################################################
# extract-and-sync.sh - Digital Twin: Extract codebase knowledge, sync to vault
#
# Usage:
#   extract-and-sync.sh --repo /path/to/repo [--schedule daily|hourly]
#
# Scans codebase, extracts decisions/patterns/tech debt, processes through
# Toleria pipeline, keeps knowledge graph updated.
###############################################################################

set -e

REPO_PATH="${1:-.}"
VAULT_ROOT="${VAULT_ROOT:-$HOME/Documents/Vault}"
TOLERIA_SKILLS="${TOLERIA_SKILLS:-$HOME/.claude/skills/toleria/skills}"
TOLERIA_REPO="${TOLERIA_REPO:-$HOME/workspace/toleria-knowledge-orchestrator-skill}"

# Handle both old and new Toleria locations
if [ ! -d "$TOLERIA_SKILLS" ]; then
  TOLERIA_SKILLS="$TOLERIA_REPO/skills"
fi

SYNC_STATE="$HOME/.toleria/last-extract-$(basename $REPO_PATH).json"
mkdir -p "$HOME/.toleria" "$VAULT_ROOT"/{INBOX,DECISIONS,PATTERNS,EXECUTION,PROJECTS,STACKS,INDEX}

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }

###############################################################################
# SCAN: Find source files
###############################################################################

scan_repo() {
  local repo="$1"
  local tmp_manifest="/tmp/manifest-$$.txt"

  find "$repo" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.md" \) \
    | grep -v node_modules | grep -v ".git" | grep -v "__pycache__" > "$tmp_manifest"

  cat "$tmp_manifest"
  rm -f "$tmp_manifest"
}

###############################################################################
# EXTRACT: Parse markers from source files
###############################################################################

extract_from_file() {
  local file="$1"
  local tmp_out="/tmp/extract-$$.json"

  # Use Toleria's knowledge.extract if available, else fallback to grep
  if [ -x "$TOLERIA_SKILLS/knowledge.extract" ]; then
    cat "$file" | "$TOLERIA_SKILLS/knowledge.extract" 2>/dev/null > "$tmp_out" || echo "[]" > "$tmp_out"
  else
    # Fallback: extract markers manually
    grep -E "Decision:|Pattern:|Tech debt:|TODO:|FIXME:" "$file" 2>/dev/null | \
      jq -R '{type: (if contains("Decision:") then "decision" elif contains("Pattern:") then "pattern" else "tech-debt" end), content: .}' | \
      jq -s '.' > "$tmp_out" || echo "[]" > "$tmp_out"
  fi

  cat "$tmp_out"
  rm -f "$tmp_out"
}

###############################################################################
# GENERATE: Create INBOX items from extracted knowledge
###############################################################################

generate_inbox_items() {
  local repo="$1"
  local item_count=0

  log "Extracting knowledge from $(basename $repo)..."

  while IFS= read -r file; do
    [ -z "$file" ] && continue

    # Extract knowledge from this file
    extracted=$(extract_from_file "$file" 2>/dev/null || echo "[]")

    # If nothing extracted, check for docstrings/comments in Python/JS
    if [ "$(echo "$extracted" | jq 'length')" -eq 0 ]; then
      case "$file" in
        *.py)
          # Extract Python docstrings
          extracted=$(python3 -c "
import ast, json
try:
  with open('$file') as f:
    tree = ast.parse(f.read())
  items = []
  for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.ClassDef, ast.Module)):
      doc = ast.get_docstring(node)
      if doc and ('Decision:' in doc or 'Pattern:' in doc or 'Tech debt:' in doc):
        items.append({'type': 'component', 'title': node.name, 'content': doc})
  print(json.dumps(items))
except: print('[]')
" 2>/dev/null || echo "[]")
          ;;
      esac
    fi

    # Create INBOX item for each extracted piece
    echo "$extracted" | jq -r '.[] | @json' | while read -r item; do
      [ -z "$item" ] && continue

      type=$(echo "$item" | jq -r '.type // "other"')
      content=$(echo "$item" | jq -r '.content // .title // ""')

      [ -z "$content" ] && continue

      # Create INBOX file
      filename="$(date +%s)_$(echo "$file" | md5sum | cut -c1-6).md"

      cat > "$VAULT_ROOT/INBOX/$filename" << EOF
---
---
$type: $content
EOF

      ((item_count++))
    done
  done < <(scan_repo "$repo")

  echo "$item_count"
}

###############################################################################
# PROCESS: Run items through Toleria pipeline
###############################################################################

process_inbox() {
  local processed=0
  local errors=0

  log "Processing INBOX items..."

  while IFS= read -r file; do
    [ -z "$file" ] && continue

    filename=$(basename "$file")
    result=$("$TOLERIA_SKILLS/inbox.process" "$filename" 2>&1)

    if echo "$result" | jq -e '.moved_to' >/dev/null 2>&1; then
      ((processed++))
    else
      ((errors++))
    fi
  done < <(find "$VAULT_ROOT/INBOX" -type f -name "*.md" 2>/dev/null)

  echo "$processed"
}

###############################################################################
# VALIDATE & INDEX
###############################################################################

validate_and_index() {
  log "Validating vault..."
  "$TOLERIA_SKILLS/vault.validate" "$VAULT_ROOT" >/dev/null 2>&1
  success "Vault validated"

  log "Generating INDEX..."
  "$TOLERIA_SKILLS/vault.index" "$VAULT_ROOT" >/dev/null 2>&1
  success "INDEX generated"
}

###############################################################################
# REPORT
###############################################################################

report() {
  local repo="$1"
  local extracted="$2"

  decisions=$(find "$VAULT_ROOT/DECISIONS" -type f -name "*.md" 2>/dev/null | wc -l)
  patterns=$(find "$VAULT_ROOT/PATTERNS" -type f -name "*.md" 2>/dev/null | wc -l)
  techdebt=$(find "$VAULT_ROOT/EXECUTION" -type f -name "*.md" 2>/dev/null | wc -l)

  echo ""
  log "EXTRACTION COMPLETE"
  echo "  Repo: $repo"
  echo "  Extracted items: $extracted"
  echo "  Vault items:"
  echo "    - Decisions: $decisions"
  echo "    - Patterns: $patterns"
  echo "    - Tech debt: $techdebt"
  echo ""
  echo "  Next: jq '.[] | {id, type}' $VAULT_ROOT/INDEX/decisions.json"
  echo ""
}

###############################################################################
# MAIN
###############################################################################

log "Digital Twin: Toleria Knowledge Extraction"
echo "  Repo: $REPO_PATH"
echo "  Vault: $VAULT_ROOT"
echo ""

# Generate INBOX items
extracted=$(generate_inbox_items "$REPO_PATH")
success "Generated $extracted items"

# Process through Toleria
processed=$(process_inbox)
success "Processed $processed items"

# Validate & index
validate_and_index

# Report
report "$REPO_PATH" "$extracted"

# Save sync state
echo '{"last_sync": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "items_extracted": '$extracted'}' > "$SYNC_STATE"
success "Sync state saved"
