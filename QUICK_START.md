# Toleria Quick Start: First Time & Ongoing

Complete step-by-step guide for first-time setup and repeated use.

---

## FIRST TIME SETUP (One-time)

### Step 1: Install Toleria Skills

**Option A: From repo (Recommended)**

```bash
cd ~/workspace/toleria-knowledge-orchestrator-skill
./install-skill.sh toleria-digital-twin --global
```

**Option B: Manual install**

```bash
mkdir -p ~/.claude/skills/toleria-digital-twin
cp skills/digital-twin/* ~/.claude/skills/toleria-digital-twin/
```

**Verify:**

```bash
ls ~/.claude/skills/toleria-digital-twin/SKILL.md
# Should exist
```

### Step 2: Create Vault Directory

```bash
mkdir -p ~/Documents/Vault/{INBOX,DECISIONS,PATTERNS,EXECUTION,PROJECTS,TOPICS,STACKS,INDEX}
```

**Verify:**

```bash
ls ~/Documents/Vault/
# Should show: DECISIONS EXECUTION INBOX INDEX PATTERNS PROJECTS STACKS TOPICS
```

### Step 3: Restart Claude Code

Skill won't show up until Claude Code reloads.

- Close Claude Code IDE
- Reopen

Then try:

```bash
/toleria-digital-twin --help
```

Should work now.

---

## FIRST TIME USAGE (Per Project)

### Example: Extract BrewPress

#### 1️⃣ Extract Knowledge

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress
```

**Output:**

```
✓ Scanned: 19 files
✓ Extracted: 35 items
  - Decisions: 5
  - Patterns: 5
  - Components: 6
  - Tech Debt: 5
  - Requirements: 4
  - Metadata: 5
✓ Processed: 35/35 items
✓ Vault validated: OK
✓ INDEX generated: ready
```

**What happened:**

- Scanned all `.py`, `.js`, `.ts`, `.go`, `.md` files
- Parsed for `Decision:`, `Pattern:`, `Tech debt:` markers
- Created 35 INBOX items
- Classified each item (decision/pattern/tech-debt/component)
- Moved to vault (DECISIONS/, PATTERNS/, EXECUTION/)
- Generated fast-lookup INDEX

#### 2️⃣ Create Project Entry

```bash
project-organizer.sh --project "BrewPress" ~/workspace/developerscoffee.com/src/brewpress
```

**Output:**

```
✓ Created project: PROJECT_BREWPRESS
```

**What it does:**

- Creates `PROJECTS/PROJECT_BREWPRESS.md`
- Sets up project metadata (repo, status, etc.)

#### 3️⃣ Create Topics

```bash
project-organizer.sh --topic "Architecture" PROJECT_BREWPRESS
project-organizer.sh --topic "Agents" PROJECT_BREWPRESS
project-organizer.sh --topic "State Management" PROJECT_BREWPRESS
project-organizer.sh --topic "Tech Debt" PROJECT_BREWPRESS
```

**Output:**

```
✓ Created topic: TOPIC_ARCHITECTURE
✓ Created topic: TOPIC_AGENTS
✓ Created topic: TOPIC_STATE_MANAGEMENT
✓ Created topic: TOPIC_TECH_DEBT
```

**What it does:**

- Creates topic entry for each area
- Organizes knowledge hierarchically

#### 4️⃣ Link Notes to Project/Topic

**Manually (for key items):**

```bash
# Architectural decisions → Architecture topic
project-organizer.sh --link DECISION_bf8e40 PROJECT_BREWPRESS TOPIC_ARCHITECTURE
project-organizer.sh --link DECISION_a80edb PROJECT_BREWPRESS TOPIC_ARCHITECTURE

# Agents → Agents topic
project-organizer.sh --link NOTE_component_writer_agent PROJECT_BREWPRESS TOPIC_AGENTS

# Tech debt → Tech Debt topic
project-organizer.sh --link TECHDEBT_multilang PROJECT_BREWPRESS TOPIC_TECH_DEBT
```

**Or automatically:**

```bash
project-organizer.sh --organize-all
```

(Infers project/topic from content)

#### 5️⃣ Query Knowledge Graph

**List all decisions:**

```bash
jq '.[] | select(.type=="decision") | {id, title, project, topic}' \
  ~/Documents/Vault/INDEX/decisions.json
```

**Output:**

```json
{
  "id": "DECISION_bf8e40",
  "title": "Use atomic writes for state persistence",
  "project": "brewpress",
  "topic": "architecture"
}
{
  "id": "DECISION_a80edb",
  "title": "Store prompt logic in Markdown skill files",
  "project": "brewpress",
  "topic": "architecture"
}
...
```

**Filter by project:**

```bash
jq '.[] | select(.project=="brewpress")' \
  ~/Documents/Vault/INDEX/decisions.json | jq -c '{id, topic, title}'
```

**Filter by topic:**

```bash
jq '.[] | select(.topic=="architecture")' \
  ~/Documents/Vault/INDEX/decisions.json
```

#### 6️⃣ Generate Documentation

```bash
project-organizer.sh --generate-docs PROJECT_BREWPRESS docs/ARCHITECTURE.md
```

**Output:**

```
✓ Documentation written to: docs/ARCHITECTURE.md
```

**File contents:**

```markdown
# Brewpress

Generated: 2026-05-01 17:30:00

## Architectural Decisions

### Use atomic writes (temp file + os.rename) for state persistence
...

### Store prompt logic in Markdown skill files
...

## Design Patterns

### Tool-first: Tools run first, LLM only when needed
...

## Tech Debt

### Multi-language support
...
```

---

## NTH TIME USAGE (Ongoing Updates)

### Scenario 1: Code Changed, Re-extract

**Code was modified, new decisions added.**

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress
```

**Output:**

```
✓ Scanned: 19 files
✓ Extracted: 2 items (new)
  - Decisions: 1
  - Patterns: 1
✓ Processed: 2/2 items
✓ Vault validated: OK
✓ INDEX updated
```

**What happened:**

- Detected 2 new decisions (idempotent, no duplicates)
- Old items preserved
- INDEX regenerated

**Update documentation:**

```bash
project-organizer.sh --generate-docs PROJECT_BREWPRESS docs/ARCHITECTURE.md
```

Overwrites with latest knowledge.

### Scenario 2: Enable Continuous Sync

**Keep knowledge updated automatically (daily):**

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress --schedule daily
```

**Output:**

```
✓ Cron job created
✓ Runs at: 00:00 (midnight) daily
✓ Next run: 2026-05-02 00:00:00
```

**Verify cron:**

```bash
crontab -l | grep toleria
```

**Output:**

```
0 0 * * * bash ~/.claude/skills/toleria-digital-twin/extract-and-sync.sh ~/workspace/developerscoffee.com/src/brewpress
```

Now, every midnight:
- Extract new/changed files
- Add to vault (no duplicates)
- Update INDEX
- Knowledge graph stays current

### Scenario 3: Query by Topic

**Want all architecture decisions:**

```bash
jq '.[] | select(.project=="brewpress" and .topic=="architecture" and .type=="decision") | .title' \
  ~/Documents/Vault/INDEX/decisions.json
```

**Output:**

```
"Use atomic writes for state persistence"
"Store prompt logic in Markdown skill files"
"Separate draft and publish into two independent pipelines"
"Load all secrets and config from environment variables"
...
```

### Scenario 4: Add Manual Notes

**Found interesting pattern in code (not auto-extracted):**

Create manually:

```bash
cat > ~/Documents/Vault/INBOX/manual_pattern.md << 'EOF'
---
---
Pattern: Request batching with exponential backoff
Details: When API calls fail, batch requests and retry with exponential backoff to avoid overwhelming service.
EOF
```

Process:

```bash
/toleria-digital-twin --repo .
# Picks up manual_pattern.md from INBOX, classifies, moves to PATTERNS
```

### Scenario 5: Search Knowledge

**Find all items mentioning "cache":**

```bash
find ~/Documents/Vault -name "*.md" -exec grep -l "cache\|caching" {} \;
```

**Get full content:**

```bash
grep -r "cache" ~/Documents/Vault/DECISIONS ~/Documents/Vault/PATTERNS --include="*.md"
```

**Via jq (fulltext):**

```bash
jq '.[] | select(.title | contains("cache") or .content | contains("cache"))' \
  ~/Documents/Vault/INDEX/decisions.json
```

---

## Daily Workflow (After Setup)

### Morning

```bash
# Check if vault was updated (cron ran overnight)
ls -la ~/Documents/Vault/DECISIONS | tail -5

# Query what's new
jq '.[] | select(.created_at > "2026-05-01T00:00:00Z")' \
  ~/Documents/Vault/INDEX/decisions.json
```

### During Development

```bash
# Add decision to code comments
# Decision: Use Redis for session cache instead of in-memory

# Push code
git push origin feature/sessions

# Extract (can run multiple times, idempotent)
/toleria-digital-twin --repo ~/workspace/my-project
```

### Weekly

```bash
# Generate updated docs
project-organizer.sh --generate-docs PROJECT_MYPROJECT docs/ARCHITECTURE.md

# Commit docs
git add docs/ARCHITECTURE.md
git commit -m "docs: sync knowledge graph"
```

### Monthly

```bash
# Full audit
jq 'group_by(.project) | map({project: .[0].project, count: length})' \
  ~/Documents/Vault/INDEX/decisions.json

# Review tech debt
jq '.[] | select(.type=="tech-debt") | {title, priority, effort}' \
  ~/Documents/Vault/INDEX/decisions.json | jq -s 'group_by(.priority)'
```

---

## Common Tasks

### Task 1: Add New Project

```bash
# 1. Extract
/toleria-digital-twin --repo ~/workspace/new-project

# 2. Create project
project-organizer.sh --project "NewProject" ~/workspace/new-project

# 3. Create topics
project-organizer.sh --topic "Architecture" PROJECT_NEWPROJECT
project-organizer.sh --topic "Database" PROJECT_NEWPROJECT
project-organizer.sh --topic "API" PROJECT_NEWPROJECT

# 4. Organize
project-organizer.sh --organize-all

# 5. Generate docs
project-organizer.sh --generate-docs PROJECT_NEWPROJECT docs/ARCHITECTURE.md

# 6. Query
jq '.[] | select(.project=="newproject")' ~/Documents/Vault/INDEX/decisions.json | head -3
```

### Task 2: Find Related Items

```bash
# Find all items linked to "State Management" topic
jq '.[] | select(.topic=="state_management")' \
  ~/Documents/Vault/INDEX/decisions.json

# Find decisions that depend on specific pattern
jq '.[] | select(.type=="decision" and (.links[]?.id == "PATTERN_tool_first"))' \
  ~/Documents/Vault/INDEX/decisions.json
```

### Task 3: Update Existing Note

```bash
# Read note
vault.read "DECISIONS/DECISION_bf8e40.md" | jq .

# Edit manually in ~/Documents/Vault/DECISIONS/DECISION_bf8e40.md
# (update description, add tags, change status, etc.)

# Vault updates automatically (file-first)
# INDEX regenerates on next extraction
/toleria-digital-twin --repo .
```

### Task 4: Export to Markdown

```bash
# All decisions to one file
jq -r '.[] | select(.type=="decision") | "# \(.title)\n\n\(.content)\n\n---\n\n"' \
  ~/Documents/Vault/INDEX/decisions.json > DECISIONS.md

# By topic
jq -r '.[] | select(.topic=="architecture") | "# \(.title)\n\n\(.content)\n\n---\n\n"' \
  ~/Documents/Vault/INDEX/decisions.json > ARCHITECTURE.md

# By project
jq -r '.[] | select(.project=="brewpress") | "# \(.title)\n\n\(.content)\n\n---\n\n"' \
  ~/Documents/Vault/INDEX/decisions.json > BREWPRESS.md
```

### Task 5: Share Knowledge (Team)

```bash
# Export JSON
cp ~/Documents/Vault/INDEX/decisions.json team-knowledge.json

# Or use shared vault
export VAULT_ROOT=/Volumes/shared-drive/team-knowledge
/toleria-digital-twin --repo ~/workspace/my-project
# Now writes to shared location
```

---

## Troubleshooting

### Issue: Skill not found

**Fix:**

```bash
# Reinstall
./install-skill.sh toleria-digital-twin --global

# Restart Claude Code
# Close IDE, reopen
```

### Issue: "UP TO DATE" (no new items)

**Normal.** Code hasn't changed. Safe to ignore.

Force re-extract:

```bash
rm ~/.toleria/last-extract-*.json
/toleria-digital-twin --repo ~/workspace/my-project
```

### Issue: Vault INDEX corrupted

**Regenerate:**

```bash
~/.claude/skills/toleria/skills/vault.index ~/Documents/Vault
```

### Issue: Cron not running (daily sync)

**Check:**

```bash
crontab -l | grep toleria

# If empty, cron not set
# Manually re-run:
/toleria-digital-twin --repo ~/workspace/my-project --schedule daily
```

---

## Command Reference

### Extraction

```bash
# One-go
/toleria-digital-twin --repo ~/workspace/my-project

# With continuous sync
/toleria-digital-twin --repo ~/workspace/my-project --schedule daily

# Manual sync
/toleria-digital-twin --repo ~/workspace/my-project
```

### Organization

```bash
# Create project
project-organizer.sh --project "Name" ~/workspace/repo

# Create topic
project-organizer.sh --topic "TopicName" PROJECT_NAME

# Link note
project-organizer.sh --link NOTE_ID PROJECT_NAME TOPIC_NAME

# Generate docs
project-organizer.sh --generate-docs PROJECT_NAME output.md

# List projects
project-organizer.sh --list-projects

# List topics
project-organizer.sh --list-topics PROJECT_NAME

# Auto-organize all
project-organizer.sh --organize-all
```

### Querying

```bash
# All decisions
jq '.[] | select(.type=="decision")' ~/Documents/Vault/INDEX/decisions.json

# By project
jq '.[] | select(.project=="brewpress")' ~/Documents/Vault/INDEX/decisions.json

# By topic
jq '.[] | select(.topic=="architecture")' ~/Documents/Vault/INDEX/decisions.json

# By type
jq '.[] | select(.type=="pattern")' ~/Documents/Vault/INDEX/patterns.json

# By priority
jq '.[] | select(.priority=="high")' ~/Documents/Vault/INDEX/decisions.json
```

---

## Timeline

**Day 1 (Setup):** 30 minutes
- Install skills
- Create vault
- Extract first project
- Create project/topics
- Generate documentation

**Day 2+ (Usage):** 5 minutes per update
- New code → `/toleria-digital-twin` → Documentation updated
- Continuous sync (daily) → Zero manual effort

**Month 1:** Growth
- 2-3 projects extracted
- 100+ knowledge items
- Team using docs

**Ongoing:** Maintenance
- New extraction on code changes (cron daily)
- Documentation auto-updated
- Knowledge stays current

---

**Status:** Ready to use. Install and start extracting!
