#!/bin/bash
###############################################################################
# project-organizer.sh
#
# Organize extracted knowledge by Projects → Topics → Notes with Types
#
# Usage:
#   project-organizer.sh --project brewpress --topics architecture,agents,state
#   project-organizer.sh --list-projects
#   project-organizer.sh --organize-all
#
###############################################################################

set -e

VAULT_ROOT="${VAULT_ROOT:-$HOME/Documents/Vault}"
TOLERIA_SKILLS="${TOLERIA_SKILLS:-$HOME/.claude/skills/toleria/skills}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

###############################################################################
# Create Project
###############################################################################

create_project() {
  local project_name="$1"
  local project_id="PROJECT_$(echo "$project_name" | tr '[:lower:]' '[:upper:]')"
  local repo_path="${2:-.}"

  log "Creating project: $project_name"

  local frontmatter=$(jq -n \
    --arg id "$project_id" \
    --arg name "$project_name" \
    --arg repo "$repo_path" \
    '{
      id: $id,
      type: "project",
      name: $name,
      repo: $repo,
      status: "active",
      created_at: now | todate,
      updated_at: now | todate
    }')

  "$TOLERIA_SKILLS/vault.write" \
    "PROJECTS/${project_id}.md" \
    "$frontmatter" \
    "# $project_name

Repository: $repo_path
" > /dev/null 2>&1

  success "Created project: $project_id"
  echo "$project_id"
}

###############################################################################
# Create Topic
###############################################################################

create_topic() {
  local topic_name="$1"
  local project_id="$2"
  local topic_id="TOPIC_$(echo "$topic_name" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')"

  log "Creating topic: $topic_name (for $project_id)"

  local frontmatter=$(jq -n \
    --arg id "$topic_id" \
    --arg name "$topic_name" \
    --arg project "${project_id#PROJECT_}" \
    '{
      id: $id,
      type: "topic",
      name: $name,
      project: $project,
      created_at: now | todate,
      updated_at: now | todate
    }')

  "$TOLERIA_SKILLS/vault.write" \
    "TOPICS/${topic_id}.md" \
    "$frontmatter" \
    "# $topic_name

Topics and notes related to $topic_name.
" > /dev/null 2>&1

  success "Created topic: $topic_id"
  echo "$topic_id"
}

###############################################################################
# Link Note to Project/Topic
###############################################################################

link_to_project() {
  local note_id="$1"
  local project_id="$2"
  local topic_id="${3:-}"

  log "Linking $note_id to $project_id"

  # Find the note file
  local note_file=$(find "$VAULT_ROOT" -name "${note_id}.md" -type f | head -1)
  [ -z "$note_file" ] && { warn "Note not found: $note_id"; return 1; }

  # Read note
  local note=$("$TOLERIA_SKILLS/vault.read" "$(basename "$(dirname "$note_file")")/${note_id}.md")

  # Add project to frontmatter
  local updated=$(echo "$note" | jq \
    --arg proj "${project_id#PROJECT_}" \
    '.frontmatter.project = $proj')

  # Add topic if specified
  if [ -n "$topic_id" ]; then
    updated=$(echo "$updated" | jq \
      --arg topic "${topic_id#TOPIC_}" \
      '.frontmatter.topic = $topic')
  fi

  # Write back
  local dir=$(dirname "$note_file" | xargs basename)
  "$TOLERIA_SKILLS/vault.write" \
    "$dir/${note_id}.md" \
    "$(echo "$updated" | jq -c .frontmatter)" \
    "$(echo "$updated" | jq -r .content)" > /dev/null 2>&1

  success "Linked: $note_id → $project_id ${topic_id:+→ $topic_id}"
}

###############################################################################
# Organize Notes by Project/Topic
###############################################################################

organize_all() {
  log "Organizing all notes by project/topic..."

  local count=0

  # For each decision
  while IFS= read -r file; do
    [ -z "$file" ] && continue

    local id=$(basename "$file" .md)
    local content=$(cat "$file")

    # Try to infer project from content
    if echo "$content" | grep -q "BrewPress\|brewpress"; then
      link_to_project "$id" "PROJECT_BREWPRESS" "TOPIC_ARCHITECTURE"
      ((count++))
    fi
  done < <(find "$VAULT_ROOT/DECISIONS" -name "DECISION_*.md" -type f)

  success "Organized $count items"
}

###############################################################################
# List Projects
###############################################################################

list_projects() {
  log "Projects:"

  while IFS= read -r file; do
    [ -z "$file" ] && continue

    local id=$(basename "$file" .md)
    local name=$(grep "^name:" "$file" | head -1 | sed 's/.*: //')

    echo "  • $id: ${name:-$id}"
  done < <(find "$VAULT_ROOT/PROJECTS" -name "PROJECT_*.md" -type f 2>/dev/null)
}

###############################################################################
# List Topics for Project
###############################################################################

list_topics() {
  local project_id="$1"
  local project_name="${project_id#PROJECT_}"

  log "Topics for $project_id:"

  while IFS= read -r file; do
    [ -z "$file" ] && continue

    local id=$(basename "$file" .md)
    local name=$(grep "^name:" "$file" | head -1 | sed 's/.*: //')

    echo "  • $id: ${name:-$id}"
  done < <(grep -l "project: $project_name" "$VAULT_ROOT/TOPICS"/*.md 2>/dev/null)
}

###############################################################################
# Generate Project Documentation
###############################################################################

generate_docs() {
  local project_id="$1"
  local project_name="${project_id#PROJECT_}"
  local output_file="${2:-${project_name}.md}"

  log "Generating documentation for $project_id..."

  # Create header
  {
    echo "# ${project_name^}"
    echo ""
    echo "Generated: $(date)"
    echo ""

    # Decisions
    echo "## Architectural Decisions"
    echo ""
    find "$VAULT_ROOT/DECISIONS" -name "DECISION_*.md" -type f | while read -r file; do
      if grep -q "project: $project_name" "$file" 2>/dev/null; then
        local id=$(basename "$file" .md)
        local title=$(grep "^# Decision:" "$file" | head -1 | sed 's/^# Decision: //')
        echo "### $title"
        grep -A 5 "^Decision:" "$file" | tail -5
        echo ""
      fi
    done

    # Patterns
    echo "## Design Patterns"
    echo ""
    find "$VAULT_ROOT/PATTERNS" -name "PATTERN_*.md" -type f | while read -r file; do
      if grep -q "project: $project_name" "$file" 2>/dev/null; then
        local id=$(basename "$file" .md)
        local title=$(grep "^# Pattern:" "$file" | head -1 | sed 's/^# Pattern: //')
        echo "### $title"
        grep -A 5 "^Pattern:" "$file" | tail -5
        echo ""
      fi
    done

    # Tech Debt
    echo "## Tech Debt"
    echo ""
    find "$VAULT_ROOT/EXECUTION" -name "TECHDEBT_*.md" -type f | while read -r file; do
      if grep -q "project: $project_name" "$file" 2>/dev/null; then
        local id=$(basename "$file" .md)
        local title=$(grep "^# Tech Debt:" "$file" | head -1 | sed 's/^# Tech Debt: //')
        echo "### $title"
        grep -A 5 "^Tech Debt:" "$file" | tail -5
        echo ""
      fi
    done
  } > "$output_file"

  success "Documentation written to: $output_file"
}

###############################################################################
# Main
###############################################################################

COMMAND="${1:-help}"

case "$COMMAND" in
  --project)
    PROJECT_NAME="$2"
    REPO_PATH="${3:-.}"
    create_project "$PROJECT_NAME" "$REPO_PATH"
    ;;

  --topic)
    TOPIC_NAME="$2"
    PROJECT_ID="$3"
    create_topic "$TOPIC_NAME" "$PROJECT_ID"
    ;;

  --link)
    NOTE_ID="$2"
    PROJECT_ID="$3"
    TOPIC_ID="$4"
    link_to_project "$NOTE_ID" "$PROJECT_ID" "$TOPIC_ID"
    ;;

  --organize-all)
    organize_all
    ;;

  --list-projects)
    list_projects
    ;;

  --list-topics)
    PROJECT_ID="$2"
    list_topics "$PROJECT_ID"
    ;;

  --generate-docs)
    PROJECT_ID="$2"
    OUTPUT_FILE="$3"
    generate_docs "$PROJECT_ID" "$OUTPUT_FILE"
    ;;

  *)
    cat << 'EOF'
project-organizer.sh — Organize knowledge by Projects → Topics → Notes

Usage:
  # Create project
  project-organizer.sh --project "BrewPress" ~/workspace/brewpress

  # Create topic
  project-organizer.sh --topic "Architecture" PROJECT_BREWPRESS

  # Link note to project/topic
  project-organizer.sh --link DECISION_xyz PROJECT_BREWPRESS TOPIC_ARCHITECTURE

  # Organize all
  project-organizer.sh --organize-all

  # List projects
  project-organizer.sh --list-projects

  # List topics for project
  project-organizer.sh --list-topics PROJECT_BREWPRESS

  # Generate documentation
  project-organizer.sh --generate-docs PROJECT_BREWPRESS output.md
EOF
    ;;
esac
