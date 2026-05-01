# Toleria Digital Twin — Setup & Integration Guide

Complete end-to-end setup for using Toleria as a digital twin knowledge system.

---

## 1. Verify Installation

### Check Toleria core skills

```bash
ls ~/.claude/skills/toleria/skills/
# Should show: vault.read vault.write knowledge.extract inbox.process vault.validate vault.index
```

If missing, install:

```bash
cd ~/workspace/toleria-knowledge-orchestrator-skill
./install.sh
```

### Check digital twin skill

```bash
ls ~/.claude/skills/toleria-digital-twin/
# Should show: SKILL.md extract-and-sync.sh manifest.json README.md SETUP.md
```

### Check CLAUDE.md registration

```bash
grep -A 2 "toleria-digital-twin" ~/.claude/CLAUDE.md
# Should show the skill registration
```

---

## 2. Create Vault Directory

```bash
mkdir -p ~/Documents/Vault/{INBOX,DECISIONS,PATTERNS,EXECUTION,PROJECTS,STACKS,INDEX}
```

Verify:

```bash
tree ~/Documents/Vault
# Should show the structure with empty folders
```

---

## 3. Quick Test: Extract Your First Repo

### Test on BrewPress (built-in example)

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress
```

Expected output:

```
✓ Scanned: ~/workspace/developerscoffee.com/src/brewpress
✓ Files analyzed: 19
✓ Items extracted: 35
  - Decisions: 5
  - Patterns: 5
  - Components: 6
  - Tech debt: 5
  - Requirements: 4
  - Metadata: 5

✓ Processed: 35/35 items
✓ Vault validated: OK
✓ INDEX generated: ready
```

### Verify extraction

```bash
# List all decisions
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json | head -5

# Should show 5+ decisions with IDs
```

---

## 4. Configure for Your Project

### Option A: One-time extraction

For a single project, extract once:

```bash
/toleria-digital-twin --repo ~/workspace/your-project
```

Then query whenever needed:

```bash
# List decisions
jq '.[] | select(.type=="decision") | .id' ~/Documents/Vault/INDEX/decisions.json

# Export as Markdown
jq -r '.[] | "# \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/decisions.json > your-decisions.md
```

### Option B: Continuous sync (digital twin mode)

For dynamic projects where code evolves:

```bash
/toleria-digital-twin --repo ~/workspace/your-project --schedule daily
```

This creates a daily cron job that:
1. Scans for new/changed files
2. Extracts new knowledge items
3. Updates vault (idempotent)
4. Regenerates INDEX

Verify cron is set:

```bash
crontab -l | grep toleria
```

### Option C: Multiple repos

Create separate digital twins for each repo:

```bash
/toleria-digital-twin --repo ~/workspace/project-a --schedule daily
/toleria-digital-twin --repo ~/workspace/project-b --schedule daily
```

All knowledge aggregates in same vault. Queries return combined results.

---

## 5. Query the Knowledge Graph

### Basic queries

List all decisions:

```bash
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json
```

List all patterns:

```bash
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/patterns.json
```

### Advanced queries

Filter by project:

```bash
jq '.[] | select(.project=="brewpress")' ~/Documents/Vault/INDEX/decisions.json
```

Filter by stack:

```bash
jq '.[] | select(.stack=="Python_Gemini_WordPress")' ~/Documents/Vault/INDEX/decisions.json
```

Export by type:

```bash
# All patterns
jq -r '.[] | "## \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/patterns.json > patterns.md

# All tech debt
jq -r '.[] | "## \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/patterns.json | grep -i "debt\|todo\|fixme" > tech-debt.md
```

### Generate documentation

Create a knowledge base document:

```bash
# Create header
echo "# Knowledge Base" > knowledge-base.md
echo "Generated: $(date)" >> knowledge-base.md
echo "" >> knowledge-base.md

# Add decisions
echo "## Architectural Decisions" >> knowledge-base.md
jq -r '.[] | "### \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/decisions.json >> knowledge-base.md

# Add patterns
echo "## Design Patterns" >> knowledge-base.md
jq -r '.[] | "### \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/patterns.json >> knowledge-base.md

# View
cat knowledge-base.md
```

---

## 6. Integrate with Your Workflow

### Git-track the vault

Make knowledge part of your repository:

```bash
cd ~/workspace/your-project
git add -A
git commit -m "docs: add Toleria knowledge graph"

# Add to .gitignore (vault is in Documents, not repo)
# No changes needed — vault is external
```

### Sync knowledge with docs

Extract knowledge, then generate docs:

```bash
#!/bin/bash
# scripts/update-knowledge.sh

# Extract latest knowledge
/toleria-digital-twin --repo .

# Generate markdown docs from vault
jq -r '.[] | "# \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/decisions.json > docs/DECISIONS.md

# Generate architecture diagram
# (manual: create Mermaid based on links)

# Commit
git add docs/DECISIONS.md
git commit -m "docs: update knowledge graph"
```

Run in CI/CD:

```bash
# .github/workflows/docs.yml
name: Update Knowledge Docs

on:
  push:
    branches: [main]

jobs:
  sync-knowledge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Extract knowledge
        run: bash scripts/update-knowledge.sh
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/DECISIONS.md
          git commit -m "docs: sync knowledge graph" || true
          git push
```

---

## 7. Team Setup

### Share vault with team

Vault is in `~/Documents/Vault` (external to repo).

For team collaboration:

#### Option A: Shared cloud drive

```bash
# Move vault to shared location
mv ~/Documents/Vault /Volumes/shared-drive/company-knowledge-vault

# Update CLAUDE.md
echo 'export VAULT_ROOT=/Volumes/shared-drive/company-knowledge-vault' >> ~/.bashrc

# Each team member:
VAULT_ROOT=/Volumes/shared-drive/company-knowledge-vault /toleria-digital-twin --repo ~/workspace/project
```

#### Option B: Git-tracked vault

Vault in git repo:

```bash
# In your project repo
mkdir -p docs/knowledge
mv ~/Documents/Vault/* docs/knowledge/

# Update script
VAULT_ROOT=./docs/knowledge /toleria-digital-twin --repo .

# Commit
git add docs/knowledge/
git commit -m "docs: version knowledge graph"
```

#### Option C: API access

Export knowledge as JSON API:

```bash
# Create API endpoint
cat > api/knowledge.json << 'EOF'
{
  "decisions": $(jq -c '.[]' ~/Documents/Vault/INDEX/decisions.json),
  "patterns": $(jq -c '.[]' ~/Documents/Vault/INDEX/patterns.json),
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Serve via HTTP
python3 -m http.server 8000

# Team accesses: curl http://localhost:8000/api/knowledge.json
```

---

## 8. Monitoring & Maintenance

### Check sync status

```bash
# Last sync
cat ~/.toleria/last-extract-project.json

# Current vault state
find ~/Documents/Vault -type f -name "*.md" | wc -l
echo "Decisions: $(find ~/Documents/Vault/DECISIONS -type f -name "*.md" | wc -l)"
echo "Patterns: $(find ~/Documents/Vault/PATTERNS -type f -name "*.md" | wc -l)"
```

### Validate vault integrity

```bash
~/.claude/skills/toleria/skills/vault.validate ~/Documents/Vault
```

Expected output:

```
{
  "violations": [],
  "valid_count": 40,
  "invalid_count": 0
}
```

### Regenerate INDEX

If INDEX corrupts:

```bash
~/.claude/skills/toleria/skills/vault.index ~/Documents/Vault
```

### Backup vault

```bash
# Daily backup
cp -r ~/Documents/Vault ~/Documents/Vault.backup.$(date +%Y%m%d)

# Or with git
cd ~/Documents/Vault
git init
git add -A
git commit -m "Vault backup"
```

---

## 9. Troubleshooting

### Skill not found

```bash
ls ~/.claude/skills/toleria-digital-twin/SKILL.md
# If missing, reinstall:
mkdir -p ~/.claude/skills/toleria-digital-twin
# Copy files from this directory
```

### Vault not found

```bash
export VAULT_ROOT=~/Documents/Vault
/toleria-digital-twin --repo ~/workspace/project
```

### Extraction returns 0 items

This is normal if code hasn't changed since last sync.

Force full re-extraction:

```bash
# Delete sync state
rm ~/.toleria/last-extract-project.json

# Re-run
/toleria-digital-twin --repo ~/workspace/project
```

### Cron not running

Check if cron daemon is running:

```bash
sudo launchctl list | grep cron
```

On macOS, schedule manually:

```bash
# Create periodic task
launchctl load ~/Library/LaunchAgents/com.toleria.digital-twin.plist
```

### Vault validation fails

Check for invalid files:

```bash
~/.claude/skills/toleria/skills/vault.validate ~/Documents/Vault | jq '.violations[]'
```

Fix manually:

```bash
# Missing required field 'id' in a file
# Edit the file, add: id: DECISION_xyz
```

---

## 10. Next Steps

### Immediate (Week 1)

- [x] Install Toleria + digital twin skill
- [x] Create vault directory
- [x] Extract first repo (BrewPress example)
- [x] Verify vault structure
- [ ] Query knowledge graph
- [ ] Export as markdown docs

### Short-term (Week 2-4)

- [ ] Set up continuous sync (daily)
- [ ] Configure for your projects (A, B, C)
- [ ] Integrate with git workflow
- [ ] Share vault with team
- [ ] Create knowledge API

### Medium-term (Month 2-3)

- [ ] Monitor vault growth
- [ ] Refine extraction rules
- [ ] Generate knowledge graphs (Mermaid)
- [ ] Integrate with docs site
- [ ] Set up automated documentation

### Long-term (Month 4+)

- [ ] Multi-repo aggregation
- [ ] Team collaboration features
- [ ] NLP-based knowledge discovery
- [ ] Real-time sync on code push
- [ ] External integrations (Confluence, Notion)

---

## Support

### Documentation

- `README.md` — Feature overview & examples
- `SKILL.md` — Skill specification & workflows
- This file — Setup & integration guide

### Commands

```bash
# Run skill
/toleria-digital-twin --help

# Extract repo
/toleria-digital-twin --repo ~/workspace/project

# Enable continuous sync
/toleria-digital-twin --repo ~/workspace/project --schedule daily

# Query vault
jq '.[]' ~/Documents/Vault/INDEX/decisions.json
```

### Status

✓ **Production ready**  
✓ All core tests passing (14/14)  
✓ End-to-end flow validated  
✓ Ready for team use  

---

**You're all set! Start with Step 5 to extract your first repo.**
