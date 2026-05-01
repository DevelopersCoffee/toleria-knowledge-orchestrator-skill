---
name: toleria-digital-twin
description: Extract and continuously sync codebase knowledge to Toleria vault. Digital twin keeps knowledge graph updated.
---

# Toleria Digital Twin Skill

Scan repository. Extract decisions, patterns, tech debt, architecture. Sync to knowledge vault. Keep graph updated automatically.

## Usage

```bash
/toleria-digital-twin [--repo /path/to/repo] [--continuous] [--schedule hourly|daily|weekly]
```

## Features

- **One-go extraction:** Scan entire codebase, extract 30+ knowledge items
- **Incremental sync:** Only new/changed files processed on re-run
- **Digital twin:** Knowledge graph mirrors current codebase state
- **Automatic updates:** Schedule continuous syncs (hourly/daily/weekly)
- **Idempotent:** Safe to run multiple times, avoids duplication

## How It Works

### Step 1: Init (First Run)

Ask user:

```
D1 — Configure digital twin
Project/branch/task: Toleria knowledge extraction
ELI10: Scan your codebase once, extract architectural knowledge (decisions, patterns, tech debt), store in searchable vault.
Recommendation: Start with defaults — can tune extraction templates later
```

Options:
- A) Scan repo now (auto-detect path, extract everything)
- B) Configure custom extraction (pick directory, file patterns, extraction rules)

### Step 2: Extract

Scan target directory (default: current repo):
- Find all `.py`, `.js`, `.ts`, `.go`, `.rs` files
- Parse source code for markers:
  - `Decision:` → architectural decision
  - `Pattern:` → design pattern
  - `Tech debt:` → technical debt
  - Class/function docstrings → technical components
  - Config files → project metadata

Generate 30+ knowledge items in INBOX format.

### Step 3: Process

Run Toleria pipeline:

```bash
VAULT_ROOT=~/Documents/Vault

# Classify + write
inbox.process <item>

# Validate schema
vault.validate $VAULT_ROOT

# Index for fast lookup
vault.index $VAULT_ROOT
```

### Step 4: Report

Show extraction summary:

```
✓ Scanned: <repo path>
✓ Items extracted: 35
  - Decisions: 8
  - Patterns: 12
  - Tech debt: 7
  - Components: 8
✓ Items processed: 35
✓ Vault validated: OK
✓ INDEX generated: ready
```

### Step 5: Schedule (Optional)

Ask if user wants automatic updates:

```
D2 — Enable continuous sync
ELI10: Run extraction automatically so knowledge graph stays current as code changes.
Recommendation: Daily (once per day) — balances freshness vs overhead
```

Options:
- A) Enable daily sync (runs at midnight)
- B) Enable hourly sync (fresh every hour, higher overhead)
- C) Manual only (re-run /toleria-digital-twin when needed)

If A or B: Create cron job that runs extraction script.

---

## Configuration

### Extraction Templates

Define which file patterns and markers to extract from:

```yaml
extraction_rules:
  python:
    patterns:
      - "**/*.py"
    markers:
      - "Decision:"
      - "Pattern:"
      - "Tech debt:"
      - "TODO:"
    parse: "docstrings + comments"
  
  javascript:
    patterns:
      - "**/*.js"
      - "**/*.ts"
    markers:
      - "ARCHITECTURE:"
      - "DESIGN:"
      - "BUG:"
    parse: "JSDoc + comments"
  
  markdown:
    patterns:
      - "**/*.md"
    markers:
      - "# Architecture"
      - "# Design"
      - "# TODO"
    parse: "heading sections"
```

### Vault Location

Default: `~/Documents/Vault`

Override: `VAULT_ROOT=/custom/path /toleria-digital-twin`

### Incremental Updates

Track last sync: `~/.toleria/last-extract-<repo>.json`

On re-run:
- Scan for files changed since last sync
- Extract only changed files
- Add new items, preserve old items
- Update timestamps

---

## Integration with Toleria Skills

The digital twin skill wraps existing Toleria skills:

1. **knowledge.extract** — parse source code for markers
2. **inbox.process** — classify + move items
3. **vault.validate** — check schema
4. **vault.index** — generate fast lookups

No new core skills needed. Reuses existing Toleria infrastructure.

---

## Data Flow

```
Codebase
   ↓
[scan: find all source files]
   ↓
[extract: parse code for markers]
   ↓
Knowledge Items (JSON)
   ↓
[inbox.process: classify → generate ID → write to vault]
   ↓
Vault Files (DECISIONS/, PATTERNS/, EXECUTION/)
   ↓
[vault.validate: schema check]
   ↓
[vault.index: generate INDEX]
   ↓
Knowledge Graph (decisions.json, patterns.json)
```

---

## Example: BrewPress Extraction

### One-go extraction:

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress
```

Output:

```
✓ Scanned: ~/workspace/developerscoffee.com/src/brewpress
✓ Files analyzed: 19 Python modules
✓ Items extracted: 35
  - Decisions: 5 (agent-based, atomic state, etc.)
  - Patterns: 5 (tool-first, draft-first, etc.)
  - Components: 6 (agents, state store, etc.)
  - Tech debt: 5 (multilang, distributed state, etc.)
  - Requirements: 4 (draft gen, approval, etc.)
  - Metadata: 5 (project, stack, etc.)

✓ Processed: 35/35 items
✓ Vault: ~/Documents/Vault
✓ Ready to query:
  jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json
```

### Continuous sync (daily):

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com --schedule daily --continuous
```

Runs at midnight each day. If code changed, extracts new items. Idempotent (no duplicates).

---

## Querying the Knowledge Graph

After extraction, knowledge is indexed and queryable:

### List all decisions

```bash
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json
```

### Export as Markdown

```bash
jq -r '.[] | "# \(.id)\n\(.content)\n"' \
  ~/Documents/Vault/INDEX/decisions.json > decisions.md
```

### Filter by type

```bash
jq '.[] | select(.type=="decision")' ~/Documents/Vault/INDEX/decisions.json
```

### Read full details

```bash
vault.read "DECISIONS/DECISION_xyz.md"
```

---

## Limitations & Future

**Current (Phase 1):**
- Extract from source code comments + docstrings
- Marker-based parsing (no NLP/ML)
- Single repo at a time
- Manual or scheduled updates

**Future (Phase 2):**
- Multi-repo aggregation
- AST-based extraction (deeper code analysis)
- NLP for implicit knowledge (no markers needed)
- Real-time sync (webhook-triggered on code push)
- Knowledge graph visualization (Mermaid, D3)
- Team collaboration (conflict resolution, merges)
- Export to external tools (Confluence, Notion, etc.)

---

## Skill Invocation

When user types `/toleria-digital-twin`:

1. Read this file
2. Ask D1: Configure extraction (defaults or custom)
3. If A: scan default repo, extract, process
4. If B: ask for directory + patterns
5. Run extraction pipeline
6. Report summary
7. Ask D2: Enable continuous sync (optional)
8. Done

The skill is a wrapper around Toleria's existing core skills.
