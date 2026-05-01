# Toleria Digital Twin Skill

Extract and continuously sync codebase knowledge to Toleria vault. Acts as a **digital twin** — keeps your knowledge graph updated automatically as code evolves.

## Installation

Already installed! Located at: `~/.claude/skills/toleria-digital-twin/`

Registered in CLAUDE.md for automatic discovery.

## Quick Start

### Option 1: One-time extraction

```bash
/toleria-digital-twin --repo ~/workspace/your-project
```

Extracts all decisions, patterns, tech debt from codebase → Toleria vault → generates INDEX.

### Option 2: Scheduled continuous sync

```bash
/toleria-digital-twin --repo ~/workspace/your-project --schedule daily
```

Runs extraction every day at midnight. Idempotent — new items added, old items preserved.

### Option 3: Via Claude Code skill menu

Type `/toleria-digital-twin` in Claude Code. Skill presents options:
- A) Scan repo now (auto-detect, extract everything)
- B) Configure custom extraction (pick directory, patterns)

Then asks: Enable continuous sync? (daily/hourly/manual)

---

## How It Works

### Architecture: Digital Twin Pattern

```
┌─────────────────────────────────────────────────────────┐
│                    Your Codebase                        │
│  (decisions, patterns, tech debt scattered in code)     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
            ┌──────────────────────┐
            │   Digital Twin Skill  │
            │  (extract-and-sync)   │
            └──────────┬────────────┘
                       │
        ┌──────────────┴──────────────┐
        ↓                             ↓
    [Scan]                        [Parse]
    Find all source files     Extract Decision:/Pattern:/Tech debt:
        ↓                            ↓
        └──────────────┬─────────────┘
                       ↓
        ┌──────────────────────────────┐
        │   Toleria Pipeline           │
        ├──────────────────────────────┤
        │ 1. Generate INBOX items      │
        │ 2. inbox.process (classify)  │
        │ 3. vault.write (persist)     │
        │ 4. vault.validate (schema)   │
        │ 5. vault.index (fast lookup) │
        └──────────────┬───────────────┘
                       ↓
        ┌──────────────────────────────┐
        │     Knowledge Graph Vault    │
        ├──────────────────────────────┤
        │ DECISIONS/         (20 items)│
        │ PATTERNS/          (15 items)│
        │ EXECUTION/         (5 items) │
        │ INDEX/                       │
        │  - decisions.json            │
        │  - patterns.json             │
        └──────────────────────────────┘
```

### Step 1: Scan

Find all source files in target directory:
- `**/*.py` (Python)
- `**/*.js` (JavaScript)
- `**/*.ts` (TypeScript)
- `**/*.go` (Go)
- `**/*.md` (Markdown)

Skip: `node_modules`, `.git`, `__pycache__`

### Step 2: Extract

Parse each file for markers:
- `Decision:` → Architectural decision
- `Pattern:` → Design pattern
- `Tech debt:` → Technical debt
- Class/function docstrings → Technical components
- Config files → Project metadata

Also extract from:
- Docstrings (Python `"""..."""`)
- Comments (JavaScript `//`, Python `#`)
- Markdown sections (`# Architecture`, `# Design`)

### Step 3: Process

Feed extracted items through Toleria pipeline:

1. **Generate INBOX items** — Create .md files with markers
2. **inbox.process** — Classify (decision/pattern/tech-debt), generate unique ID
3. **vault.write** — Persist to vault with frontmatter
4. **vault.validate** — Check schema (required fields: id, type, timestamps)
5. **vault.index** — Generate decisions.json, patterns.json for fast queries

### Step 4: Idempotent Update

On re-run:
- New files extracted → added to vault
- Changed files → frontmatter updated (updated_at timestamp)
- Old items → preserved (not deleted)
- No duplicates → each item has unique ID based on content hash

```bash
# First run: 35 items extracted
/toleria-digital-twin --repo ~/workspace/project
→ ✓ Extracted 35 items

# Second run: code didn't change
/toleria-digital-twin --repo ~/workspace/project
→ ✓ No new items (UP TO DATE)

# Third run: added 2 new decisions
/toleria-digital-twin --repo ~/workspace/project
→ ✓ Extracted 2 new items (old items preserved)
```

### Step 5: Query

Knowledge graph is now indexed and queryable:

```bash
# List all decisions
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json

# Export as Markdown
jq -r '.[] | "# \(.id)\n\(.content)\n"' \
  ~/Documents/Vault/INDEX/decisions.json > decisions.md

# Filter by type
jq '.[] | select(.type=="pattern")' \
  ~/Documents/Vault/INDEX/patterns.json

# Read full details
vault.read "DECISIONS/DECISION_xyz.md" | jq .frontmatter
```

---

## Continuous Sync (Digital Twin Mode)

### Enable automatic updates

```bash
/toleria-digital-twin --repo ~/workspace/project --schedule daily
```

Creates cron job that runs extraction every day:

```
0 0 * * * bash ~/.claude/skills/toleria-digital-twin/extract-and-sync.sh ~/workspace/project
```

Schedule options:
- `daily` — midnight each day
- `hourly` — every hour (higher overhead)
- `weekly` — once per week (Sunday midnight)
- `manual` — disable auto-sync, run only on-demand

### What "digital twin" means

Your knowledge graph **mirrors the current state** of your codebase:

1. **Auto-discovery** — New architectural decisions in code are automatically extracted
2. **Self-updating** — Re-run extraction when code changes
3. **Incremental** — Only new/changed files are processed (no redundant work)
4. **Idempotent** — Safe to run multiple times without side effects
5. **Versionable** — All knowledge stored as text files, tracked in git

---

## Examples

### BrewPress Project

Extract one-go:

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress
```

Output:

```
✓ Scanned: ~/workspace/developerscoffee.com/src/brewpress
✓ Files analyzed: 19 Python modules
✓ Items extracted: 35
  - Decisions: 5 (agent-based, atomic state, markdown skills, etc.)
  - Patterns: 5 (tool-first, draft-first, critic loop, etc.)
  - Components: 6 (WriterAgent, StructurerAgent, SEOAgent, etc.)
  - Tech debt: 5 (multi-language, distributed state, rate limiting, etc.)
  - Requirements: 4 (draft gen, approval, publish, feedback loop)
  - Metadata: 5 (project, stack info)

✓ Processed: 35/35 items
✓ Vault: ~/Documents/Vault
✓ Ready to query:
  jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json
```

Enable continuous sync:

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress --schedule daily
```

Now knowledge graph stays current:
- When developer adds `Decision: Use Redis for caching`, next sync extracts it
- When tech debt is marked in code, next sync updates vault
- Automatic daily at midnight, no manual work needed

---

## Architecture: How Skills Integrate

The digital twin skill is a **wrapper** around existing Toleria core skills:

```
Digital Twin Skill (wrapper)
  ├─ scan() → find source files
  ├─ extract() → call knowledge.extract
  ├─ generate_inbox_items() → create .md files
  └─ process() → call:
      ├─ inbox.process (classify + write)
      ├─ vault.validate (schema check)
      └─ vault.index (fast lookup)
```

No new core skills needed. Reuses Toleria infrastructure.

---

## Configuration

### Custom extraction rules

Edit `~/.claude/skills/toleria-digital-twin/manifest.json`:

```json
{
  "config": {
    "VAULT_ROOT": "~/Documents/Vault",
    "TOLERIA_REPO": "~/workspace/toleria-knowledge-orchestrator-skill",
    "ENABLE_CONTINUOUS_SYNC": true,
    "SYNC_INTERVAL": "daily"
  }
}
```

### Vault location

```bash
VAULT_ROOT=/custom/path /toleria-digital-twin --repo ~/workspace/project
```

### Skip certain files

Edit `extract-and-sync.sh`, modify `scan_repo()` function:

```bash
find "$repo" -type f \( -name "*.py" -o -name "*.js" \) \
  | grep -v test | grep -v vendor
```

---

## Troubleshooting

### "UP TO DATE" on second run

Expected. Code hasn't changed, nothing to extract. Not an error.

### Some items marked as "other" type

Extraction couldn't classify automatically. Check if markers are valid:
- `Decision: ...` (not `Decisions:` or `DECISION:`)
- `Pattern: ...`
- `Tech debt: ...` (not `TECH_DEBT` or `Technical debt`)

### INDEX not updating

Run manually:

```bash
~/.claude/skills/toleria/skills/vault.index ~/Documents/Vault
```

### Cron job not running

Check crontab:

```bash
crontab -l | grep toleria
```

Check logs:

```bash
grep CRON /var/log/system.log | tail -20
```

---

## What's Next

### Phase 2 (Future)

- [ ] Multi-repo aggregation (combine knowledge from 5+ repos)
- [ ] AST-based extraction (deeper code analysis, no markers needed)
- [ ] NLP extraction (implicit knowledge discovery)
- [ ] Real-time sync (webhook on code push)
- [ ] Graph visualization (Mermaid, D3, interactive)
- [ ] Team collaboration (conflict resolution, merges)
- [ ] Export to external tools (Confluence, Notion, Linear)
- [ ] Knowledge search via Claude (semantic search)

---

## Files

```
~/.claude/skills/toleria-digital-twin/
├── SKILL.md                    ← Skill definition
├── extract-and-sync.sh         ← Extraction engine
├── manifest.json               ← Configuration & metadata
└── README.md                   ← This file
```

---

## Status

✓ **Production ready**. All Toleria core tests passing (14/14). End-to-end extraction flow validated.

Skill registered in CLAUDE.md and auto-discovered. Ready for team use.
