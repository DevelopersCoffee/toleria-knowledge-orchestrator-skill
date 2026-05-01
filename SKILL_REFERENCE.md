# Toleria Skills Reference

Complete API reference for all 6 core skills.

---

## vault.read

Read note from vault, parse frontmatter + content.

**Usage:**
```bash
vault.read <file_path>
```

**Input:**
- `file_path` (string): Path relative to VAULT_ROOT (e.g., "DECISIONS/DECISION_abc123.md")

**Output:**
```json
{
  "frontmatter": {
    "id": "DECISION_abc123",
    "type": "decision",
    "project": "myapp",
    "stack": "JAVA_SPRING",
    "tags": ["type:decision", "status:active"],
    "links": [{"id": "myapp", "title": "myapp"}],
    "created_at": "2026-05-01T00:00:00Z",
    "updated_at": "2026-05-01T00:00:00Z"
  },
  "content": "# Decision Title\n\nContent here."
}
```

**Exit codes:**
- `0` = success
- `1` = file not found
- `2` = invalid YAML

---

## vault.write

Write note atomically with schema validation.

**Usage:**
```bash
vault.write <file_path> <frontmatter_json> [content]
```

**Input:**
- `file_path` (string): Path relative to VAULT_ROOT
- `frontmatter_json` (JSON): Frontmatter object (required fields: id, type, created_at, updated_at)
- `content` (string, optional): Note content

**Output:**
```json
{
  "success": true,
  "path": "DECISIONS/DECISION_abc123.md",
  "message": "note written successfully"
}
```

**Exit codes:**
- `0` = success
- `1` = validation failed
- `2` = write failed (permission/disk)
- `3` = atomic rename failed

---

## knowledge.extract

Parse text, extract decisions/patterns/tech-debt.

**Usage:**
```bash
echo "Decision: Use PostgreSQL" | knowledge.extract
# or
knowledge.extract "Decision: Use PostgreSQL"
```

**Input:**
- Plain text with markers: Decision:, Pattern:, Tech debt:, TODO:, FIXME:

**Output:**
```json
[
  {
    "type": "decision",
    "title": "Use PostgreSQL",
    "content": "Decision: Use PostgreSQL",
    "tags": ["auto:extracted"]
  }
]
```

**Exit codes:**
- `0` = success (even if no matches)

---

## knowledge.link

Create wikilinks to project/stack.

**Usage:**
```bash
knowledge.link <entity_id> <project_id> <stack_id> [existing_links_json]
```

**Input:**
- `entity_id` (string): Entity identifier (e.g., DECISION_001)
- `project_id` (string): Project to link
- `stack_id` (string): Stack to link
- `existing_links_json` (JSON, optional): Existing links array

**Output:**
```json
{
  "links": [
    {"id": "myapp", "title": "myapp"},
    {"id": "JAVA_SPRING", "title": "JAVA_SPRING"}
  ]
}
```

**Exit codes:**
- `0` = success
- `1` = missing arguments

---

## inbox.process

Process INBOX notes, classify, move, link.

**Usage:**
```bash
inbox.process [file_path]
# Process single file or all if omitted
```

**Input:**
- `file_path` (string, optional): File in INBOX to process (omitted = process all)

**Output:**
```json
[
  {
    "file": "inbox_note.md",
    "moved_to": "DECISIONS/DECISION_abc123.md",
    "type": "decision",
    "id": "DECISION_abc123"
  }
]
```

**Flow:**
1. Read note from INBOX/
2. Classify (decision/pattern/tech-debt)
3. Generate ID from content
4. Create frontmatter
5. Write to DECISIONS/PATTERNS/EXECUTION/
6. Remove from INBOX

**Exit codes:**
- `0` = success

---

## vault.validate

Schema check, consistency validation.

**Usage:**
```bash
vault.validate [vault_path]
```

**Input:**
- `vault_path` (string, optional): Vault directory (default: VAULT_ROOT)

**Output:**
```json
{
  "violations": [
    {
      "path": "DECISIONS/BAD.md",
      "issue": "missing required field: id",
      "severity": "critical"
    }
  ],
  "valid_count": 42,
  "invalid_count": 1
}
```

**Checks:**
- Valid JSON frontmatter
- Required fields: id, type, created_at, updated_at
- No duplicate ids
- File readability

**Exit codes:**
- `0` = all valid
- Non-zero = violations found

---

## vault.index

Generate INDEX files for fast lookup.

**Usage:**
```bash
vault.index [vault_path]
```

**Input:**
- `vault_path` (string, optional): Vault directory (default: VAULT_ROOT)

**Output:**
```json
{
  "decisions": [
    {
      "id": "DECISION_abc123",
      "title": "Use PostgreSQL",
      "type": "decision",
      "stack": "JAVA_SPRING",
      "project": "myapp",
      "created_at": "2026-05-01T00:00:00Z"
    }
  ],
  "patterns": [...],
  "projects": [...]
}
```

**Files created:**
- `INDEX/decisions.json`: All decisions
- `INDEX/patterns.json`: All patterns
- `INDEX/projects.json`: All projects

**Exit codes:**
- `0` = success

---

## File Contract

Every note in vault must follow this structure:

```markdown
---
id: DECISION_abc123|PATTERN_xyz|PROJECT_myapp|STACK_ID
type: decision|pattern|tech-debt|project|stack
project: myapp
stack: JAVA_SPRING
tags: ["type:decision", "status:active"]
links: [{"id": "myapp", "title": "myapp"}]
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---

# Title

Content here.
```

**Required fields:**
- `id`: Unique identifier
- `type`: decision, pattern, tech-debt, project, stack
- `created_at`: ISO8601 UTC
- `updated_at`: ISO8601 UTC

**Optional fields:**
- `project`: Project reference
- `stack`: Technology stack
- `tags`: Array of tags
- `links`: Array of wikilinks {id, title}

---

## Wikilink Format

Reference notes using wikilinks:

```
[[project_id]]           → Link to project
[[stack_id]]             → Link to stack
[[decision_id|Title]]    → Link with custom title
```

Wikilinks are bidirectional in the knowledge graph. Links update automatically when items are moved.

---

## Environment Variables

- `VAULT_ROOT`: Root directory for vault (default: ~/Documents/Vault)
- `NO_COLOR`: Disable color output in CLI tools

---

## Examples

### Extract + Link + Write

```bash
# Extract knowledge from text
knowledge.extract "Decision: Use PostgreSQL for durability" > decisions.json

# Link to project/stack
knowledge.link "DECISION_001" "myapp" "JAVA_SPRING" > links.json

# Create frontmatter
jq -n '{
  id: "DECISION_001",
  type: "decision",
  project: "myapp",
  stack: "JAVA_SPRING",
  links: .[] | {id: .id, title: .title},
  created_at: now | todate,
  updated_at: now | todate
}' links.json > frontmatter.json

# Write note
vault.write "DECISIONS/DECISION_001.md" "$(cat frontmatter.json)" "Content"
```

### Process INBOX

```bash
# Add note to INBOX
cat > ~/Documents/Vault/INBOX/my_note.md << 'EOF'
---
---
Decision: Adopt microservices architecture
EOF

# Process
inbox.process "my_note.md"

# Verify
vault.read "DECISIONS/DECISION_*.md" | jq '.frontmatter.id'

# Validate
vault.validate ~/Documents/Vault

# Generate index
vault.index ~/Documents/Vault
```

