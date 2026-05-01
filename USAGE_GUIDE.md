# Toleria Skill - Installation & Usage

## ✓ Installation Status
**Plugin: INSTALLED**  
Location: `~/.claude/skills/toleria`  
Status: Ready to use

---

## Setup (30 seconds)

### 1. Create vault directories
```bash
mkdir -p ~/Documents/Vault/{DECISIONS,PATTERNS,INBOX,EXECUTION}
```

### 2. Verify installation
```bash
ls ~/.claude/skills/toleria/skills/
# Should show: vault.read vault.write knowledge.extract ...
```

### 3. Test (optional)
```bash
cd ~/.claude/skills/toleria
./test/run-tests.sh
# Expected: 14/14 passing
```

---

## Quick Demo (2 minutes)

### Add knowledge to INBOX
```bash
cat > ~/Documents/Vault/INBOX/test.md << 'EOF'
---
---
Decision: Use PostgreSQL for durability
EOF
```

### Process it
```bash
cd ~/.claude/skills/toleria
./skills/inbox.process "test.md"
```

Response:
```json
{
  "file": "test.md",
  "moved_to": "DECISIONS/DECISION_abc123.md",
  "type": "decision",
  "id": "DECISION_abc123"
}
```

### Read it back
```bash
./skills/vault.read "DECISIONS/DECISION_abc123.md"
```

---

## Core Skills

| Command | Purpose |
|---------|---------|
| `vault.read PATH` | Read + parse frontmatter |
| `vault.write PATH JSON CONTENT` | Write atomically |
| `knowledge.extract` | Parse Decision:/Pattern:/Tech debt: markers |
| `knowledge.link ID PROJECT STACK` | Create wikilinks |
| `inbox.process FILE` | Classify INBOX note → move to folder |
| `vault.validate` | Check schema |
| `vault.index` | Generate decisions.json, patterns.json |

---

## Workflows

### Extract knowledge from text
```bash
echo "Decision: Use Redis for caching" | \
  ~/.claude/skills/toleria/skills/knowledge.extract
```

### Process all INBOX items
```bash
cd ~/.claude/skills/toleria
./scripts/process-knowledge.sh --all
```

### Check what's pending
```bash
./scripts/process-knowledge.sh --check
```

### Query knowledge
```bash
# All decisions
jq '.[]' ~/Documents/Vault/INDEX/decisions.json

# By type
jq '.[] | select(.type == "decision")' \
  ~/Documents/Vault/INDEX/decisions.json

# By project
jq '.[] | select(.project == "brewstack")' \
  ~/Documents/Vault/INDEX/decisions.json
```

---

## File Format

```markdown
---
id: DECISION_abc123
type: decision|pattern|tech-debt|project|stack
project: myapp
stack: JAVA_SPRING
tags: ["auto:extracted"]
links: [{"id": "project_id", "title": "Project"}]
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---

# Title

Content here.
```

**Required:** id, type, created_at, updated_at

---

## Idempotency

Safe to run multiple times:

```bash
# Run 1: Process new items
./skills/inbox.process "note.md"  → SUCCESS

# Run 2: Retry same
./skills/inbox.process "note.md"  → "file not found" = UP TO DATE

# Run 3: New items only
./skills/inbox.process "note2.md" → SUCCESS
```

Items removed from INBOX on success → retry = safe skip

---

## Vault Layout

```
~/Documents/Vault/
├── INBOX/           ← Add notes here
├── DECISIONS/       ← Processed decisions
├── PATTERNS/        ← Processed patterns
├── EXECUTION/       ← Tech debt
├── PROJECTS/
├── STACKS/
└── INDEX/           ← Generated
    ├── decisions.json
    ├── patterns.json
    └── projects.json
```

---

## Environment

```bash
export VAULT_ROOT=~/Documents/Vault   # Custom location (optional)
export NO_COLOR=1                     # Disable colors (optional)
```

---

## Troubleshooting

**"file not found"** → Correct behavior (file already processed from INBOX)

**"invalid YAML"** → Check required fields: id, type, created_at, updated_at

**Skills not found** → Run from correct directory: `cd ~/.claude/skills/toleria`

**Test fails** → Check platform compatibility (Darwin/Linux/Windows)

---

## Full Commands

### Read note
```bash
~/.claude/skills/toleria/skills/vault.read "DECISIONS/DECISION_001.md"
```

### Write note
```bash
fm='{"id":"D1","type":"decision","created_at":"2026-05-01T00:00:00Z","updated_at":"2026-05-01T00:00:00Z"}'
~/.claude/skills/toleria/skills/vault.write "DECISIONS/D1.md" "$fm" "Content"
```

### Extract from text
```bash
echo "Decision: Use caching" | \
  ~/.claude/skills/toleria/skills/knowledge.extract
```

### Process INBOX
```bash
~/.claude/skills/toleria/skills/inbox.process "filename.md"
```

### Validate
```bash
~/.claude/skills/toleria/skills/vault.validate ~/Documents/Vault
```

### Index
```bash
~/.claude/skills/toleria/skills/vault.index ~/Documents/Vault
```

---

## Next Steps

1. Create vault directory: `mkdir -p ~/Documents/Vault/{INBOX,DECISIONS,PATTERNS}`
2. Add note to INBOX: `cat > ~/Documents/Vault/INBOX/note.md`
3. Process: `~/.claude/skills/toleria/skills/inbox.process "note.md"`
4. Query: `jq '.' ~/Documents/Vault/INDEX/decisions.json`

**Status:** Production ready. All 14 tests passing.
