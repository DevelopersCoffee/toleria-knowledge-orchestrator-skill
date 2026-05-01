#!/bin/bash

###############################################################################
# process-knowledge.sh - Full knowledge processing pipeline with idempotency
#
# Processes INBOX → classifies → writes → validates → indexes
# Detects already-processed items and skips them
#
# Usage:
#   process-knowledge.sh [--check]      # Check pending items
#   process-knowledge.sh [--all]        # Process all INBOX items
#
# Exit codes:
#   0 = success
#   1 = error
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_DIR/skills"

source "$REPO_DIR/platform.sh"

VAULT_ROOT="${VAULT_ROOT:-$(get_home)/Documents/Vault}"
MODE="${1:---all}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_status() {
  echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_skip() {
  echo -e "${YELLOW}↷${NC} $1"
}

# Check mode: just report pending
if [[ "$MODE" == "--check" ]]; then
  echo ""
  echo "Checking INBOX status..."
  result=$("$SKILLS_DIR/inbox.process-check" 2>&1)

  status=$(echo "$result" | jq -r '.status')
  count=$(echo "$result" | jq -r '.pending_count')

  if [[ "$status" == "up_to_date" ]]; then
    echo -e "${GREEN}Status: UP TO DATE${NC}"
    echo "No pending items in INBOX"
  else
    echo -e "${YELLOW}Status: PENDING${NC}"
    echo "$count items waiting to process:"
    echo "$result" | jq -r '.items[]' | sed 's/^/  ├─ /'
  fi
  echo ""
  exit 0
fi

# Full process mode
log_status "Starting knowledge processing pipeline"
echo ""

# Check what's pending
check_result=$("$SKILLS_DIR/inbox.process-check" 2>&1)
pending=$(echo "$check_result" | jq -r '.pending_count')

if (( pending == 0 )); then
  echo -e "${GREEN}UP TO DATE${NC}"
  echo "No items to process"
  echo ""
  exit 0
fi

log_status "Found $pending items in INBOX"
echo ""

# Process each item
processed=0
errors=0

while IFS= read -r file; do
  filename=$(basename "$file")

  # Try to process
  result=$("$SKILLS_DIR/inbox.process" "$filename" 2>&1)

  if echo "$result" | jq -e '.moved_to' >/dev/null 2>&1; then
    type=$(echo "$result" | jq -r '.type')
    id=$(echo "$result" | jq -r '.id')

    log_success "$type: $(echo "$filename" | sed 's/.md//')"
    echo "         └─ $id"

    ((processed++))
  else
    error=$(echo "$result" | jq -r '.error // "unknown error"')
    log_skip "$filename: $error"
    ((errors++))
  fi
done < <(find "$VAULT_ROOT/INBOX" -type f -name "*.md" 2>/dev/null)

echo ""
log_status "Processing complete"
echo "  Processed: $processed"
echo "  Skipped: $errors"
echo ""

# Validate
log_status "Validating vault schema..."
validation=$("$SKILLS_DIR/vault.validate" "$VAULT_ROOT" 2>&1)
valid=$(echo "$validation" | jq -r '.valid_count')
invalid=$(echo "$validation" | jq -r '.invalid_count')

if (( invalid == 0 )); then
  log_success "All $valid items valid"
else
  log_skip "$invalid items have schema issues"
fi
echo ""

# Index
log_status "Generating INDEX..."
"$SKILLS_DIR/vault.index" "$VAULT_ROOT" >/dev/null 2>&1
log_success "INDEX updated"
echo ""

# Summary
log_status "Summary"
decisions=$(jq 'length' "$VAULT_ROOT/INDEX/decisions.json")
patterns=$(jq 'length' "$VAULT_ROOT/INDEX/patterns.json")

echo "  Decisions: $decisions"
echo "  Patterns: $patterns"
echo "  Valid: $valid"
echo ""

if [[ "$processed" -gt 0 ]]; then
  echo -e "${GREEN}Processing complete${NC}"
else
  echo -e "${GREEN}UP TO DATE${NC}"
fi

echo ""
exit 0
