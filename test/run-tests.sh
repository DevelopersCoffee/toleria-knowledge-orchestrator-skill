#!/bin/bash

###############################################################################
# Toleria Skill Test Suite
#
# Runs unit + integration tests for all core skills
# Exit code: 0 = all pass, >0 = failures
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_DIR/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
total=0
passed=0
failed=0

# Setup test vault
TEST_VAULT="/tmp/toleria_test_vault"
mkdir -p "$TEST_VAULT"/{DECISIONS,PATTERNS,INBOX,EXECUTION}
export VAULT_ROOT="$TEST_VAULT"

log_test() {
  local name="$1"
  ((total++))
  echo -n "[$total] $name ... "
}

log_pass() {
  ((passed++))
  echo -e "${GREEN}PASS${NC}"
}

log_fail() {
  ((failed++))
  echo -e "${RED}FAIL${NC}"
  echo "  $1"
}

# Test vault.read
test_vault_read() {
  log_test "vault.read: valid file"
  cat > "$TEST_VAULT/DECISIONS/TEST.md" << 'EOF'
---
id: DECISION_test001
type: decision
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---
Content here.
EOF

  local result=$("$SKILLS_DIR/vault.read" "DECISIONS/TEST.md" 2>&1)
  if echo "$result" | jq -e '.frontmatter.id' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "Could not read file: $result"
  fi

  log_test "vault.read: missing file"
  local result=$("$SKILLS_DIR/vault.read" "MISSING.md" 2>&1)
  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "Should return error"
  fi
}

# Test vault.write
test_vault_write() {
  log_test "vault.write: create new note"
  local fm=$(jq -n '{id: "DECISION_new001", type: "decision", created_at: "2026-05-01T00:00:00Z", updated_at: "2026-05-01T00:00:00Z"}')
  local result=$("$SKILLS_DIR/vault.write" "DECISIONS/NEW.md" "$fm" "New content" 2>&1)
  if echo "$result" | jq -e '.success' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi

  log_test "vault.write: schema validation"
  local fm=$(jq -n '{id: "BAD"}')
  local result=$("$SKILLS_DIR/vault.write" "DECISIONS/BAD.md" "$fm" "" 2>&1)
  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "Should validate schema"
  fi
}

# Test knowledge.extract
test_knowledge_extract() {
  log_test "knowledge.extract: extract decision"
  local result=$(echo "Decision: Use PostgreSQL" | "$SKILLS_DIR/knowledge.extract" 2>&1)
  if echo "$result" | jq -e '.[0].type == "decision"' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi

  log_test "knowledge.extract: extract pattern"
  local result=$(echo "Pattern: Use DI for tests" | "$SKILLS_DIR/knowledge.extract" 2>&1)
  if echo "$result" | jq -e '.[0].type == "pattern"' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi

  log_test "knowledge.extract: empty input"
  local result=$(echo "" | "$SKILLS_DIR/knowledge.extract" 2>&1)
  if echo "$result" | jq -e 'length == 0' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi
}

# Test knowledge.link
test_knowledge_link() {
  log_test "knowledge.link: create links"
  local result=$("$SKILLS_DIR/knowledge.link" "DECISION_001" "myapp" "JAVA_SPRING" 2>&1)
  if echo "$result" | jq -e '.links | length == 2' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi

  log_test "knowledge.link: no duplicates"
  local existing='[{"id":"myapp","title":"myapp"}]'
  local result=$("$SKILLS_DIR/knowledge.link" "DECISION_002" "myapp" "PYTHON" "$existing" 2>&1)
  if echo "$result" | jq -e '.links | length == 2' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi
}

# Test inbox.process
test_inbox_process() {
  log_test "inbox.process: classify and move"
  cat > "$TEST_VAULT/INBOX/inbox_test.md" << 'EOF'
---
---
Decision: Adopt Redis for caching
EOF

  local result=$("$SKILLS_DIR/inbox.process" "inbox_test.md" 2>&1)
  if echo "$result" | jq -e '.moved_to' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi

  log_test "inbox.process: file moved from INBOX"
  if [[ ! -f "$TEST_VAULT/INBOX/inbox_test.md" ]]; then
    log_pass
  else
    log_fail "File still in INBOX"
  fi
}

# Test vault.validate
test_vault_validate() {
  log_test "vault.validate: check schema"
  local result=$("$SKILLS_DIR/vault.validate" "$TEST_VAULT" 2>&1)
  if echo "$result" | jq -e '.valid_count' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi
}

# Test vault.index
test_vault_index() {
  log_test "vault.index: generate indices"
  local result=$("$SKILLS_DIR/vault.index" "$TEST_VAULT" 2>&1)
  if echo "$result" | jq -e '.decisions' >/dev/null 2>&1; then
    log_pass
  else
    log_fail "$result"
  fi

  log_test "vault.index: files created"
  if [[ -f "$TEST_VAULT/INDEX/decisions.json" ]]; then
    log_pass
  else
    log_fail "INDEX files not created"
  fi
}

# Run all tests
echo "=== Toleria Skill Tests ==="
echo "Vault: $TEST_VAULT"
echo ""

test_vault_read
test_vault_write
test_knowledge_extract
test_knowledge_link
test_inbox_process
test_vault_validate
test_vault_index

# Cleanup
rm -rf "$TEST_VAULT"

# Report
echo ""
echo "=== Results ==="
echo "Total:  $total"
echo -e "${GREEN}Passed: $passed${NC}"
if (( failed > 0 )); then
  echo -e "${RED}Failed: $failed${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
