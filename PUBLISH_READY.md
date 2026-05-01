# Toleria Skills — Ready for Community Publishing

✓ **Status: Production Ready**

All skills are implemented, tested, documented, and ready for community release.

---

## What's Published

### Core Package (7 Skills)

**Commit:** `280a6df` — feat: add 7 core skills + 14 test cases + extraction pipeline

Core Toleria skills for knowledge extraction:

1. **vault.read** — Read and parse notes from vault
2. **vault.write** — Atomic writes with schema validation
3. **knowledge.extract** — Parse Decision:/Pattern:/Tech debt: markers
4. **knowledge.link** — Create wikilinks to project/stack
5. **inbox.process** — Classify INBOX notes, generate IDs, move to vault
6. **vault.validate** — Schema check and consistency validation
7. **vault.index** — Generate INDEX files for fast lookup

**Utilities:**
- yaml.sh — YAML to JSON frontmatter parsing
- link.sh — Wikilink format handling
- platform.sh — Cross-platform (Darwin/Linux/Windows)

**Tests:** 14 cases (all passing)

**Status:** Ready to ship. No dependencies except bash + jq.

---

### Digital Twin Skill (v1.0.0)

**Commit:** `48c87bb` — feat: add digital twin skill + community publishing infrastructure

Plugin skill for extracting and continuously syncing codebase knowledge.

**Files:**
- `skills/digital-twin/SKILL.md` — Skill spec & workflows
- `skills/digital-twin/extract-and-sync.sh` — Extraction engine
- `skills/digital-twin/manifest.json` — Config & metadata
- `skills/digital-twin/README.md` — Feature guide
- `skills/digital-twin/SETUP.md` — Integration guide

**Features:**
- One-go extraction (scan entire repo, extract 30+ items)
- Incremental updates (only new/changed files)
- Continuous sync (optional daily/hourly)
- Idempotent (safe to re-run)
- Digital twin pattern

**Status:** Production ready. Tested on BrewPress (19 Python modules, 35 items extracted).

---

### Community Publishing Infrastructure

**Commit:** `48c87bb`

**Files:**
- `SKILLS_REGISTRY.md` — Registry of all skills, installation methods
- `install-skill.sh` — Installer script (supports --global, --local)
- `COMMUNITY_PUBLISHING.md` — Publishing guide for skills.sh, GitHub, npm, Homebrew

**Channels ready:**
- [ ] skills.sh registry (pending submission)
- [x] GitHub releases (ready to tag)
- [ ] GitHub Marketplace (optional)
- [ ] npm (optional)
- [ ] Homebrew (optional)

---

## Distribution Channels

### 1. Direct from GitHub (Ready Now)

Users can install from repo:

```bash
# Clone
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git

# Install manually
mkdir -p ~/.claude/skills/toleria-digital-twin
cp skills/digital-twin/* ~/.claude/skills/toleria-digital-twin/

# Or use installer
./install-skill.sh toleria-digital-twin --global
```

### 2. skills.sh Registry (Ready to Submit)

For community distribution via `skills.sh` CLI.

**To publish:**

```bash
# 1. Create GitHub release
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 --title "Toleria v1.0.0" --body "$(cat RELEASE_NOTES.md)"

# 2. Submit to skills.sh
# Email: skills@developers.coffee
# Include:
#   - Skill name: toleria-digital-twin
#   - Repo: https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill
#   - Version: 1.0.0
#   - Description

# 3. Wait for review (1-2 weeks)

# 4. Once approved, users can install:
#   skills.sh install toleria-digital-twin
```

### 3. npm Registry (Optional)

For JavaScript/Node.js users.

**To publish:**

```bash
npm publish
```

Then: `npm install -g toleria-digital-twin`

### 4. Homebrew (Optional)

For macOS users.

**To publish:**

```bash
# Create formula, push to homebrew-toleria tap
# Then: brew tap DevelopersCoffee/toleria
#       brew install toleria-digital-twin
```

---

## Installation Methods

### Method 1: From Repository

```bash
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git
cd toleria-knowledge-orchestrator-skill
./install-skill.sh toleria-digital-twin --global
```

### Method 2: Via skills.sh (Once Approved)

```bash
skills.sh install toleria-digital-twin
```

### Method 3: Via npm (If Published)

```bash
npm install -g toleria-digital-twin
toleria-digital-twin --repo ~/workspace/project
```

### Method 4: Manual Copy

```bash
mkdir -p ~/.claude/skills/toleria-digital-twin
cp skills/digital-twin/* ~/.claude/skills/toleria-digital-twin/
```

---

## Usage

### One-go extraction

```bash
/toleria-digital-twin --repo ~/workspace/your-project
```

Output:
```
✓ Scanned: 19 files
✓ Extracted: 35 items (decisions, patterns, tech debt, components)
✓ Processed: 35/35 items
✓ Vault: ~/Documents/Vault
✓ Ready to query: jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json
```

### Continuous sync

```bash
/toleria-digital-twin --repo ~/workspace/your-project --schedule daily
```

Runs extraction daily. Idempotent — new items added, old items preserved.

### Query knowledge graph

```bash
# List all decisions
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json

# Export as Markdown
jq -r '.[] | "# \(.id)\n\(.content)\n"' ~/Documents/Vault/INDEX/decisions.json > docs.md

# Filter by type
jq '.[] | select(.type=="pattern")' ~/Documents/Vault/INDEX/patterns.json
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| README.md | Overview & quick start |
| SKILL_REFERENCE.md | API reference for all 7 skills |
| USAGE_GUIDE.md | Step-by-step usage tutorial |
| COMPLETION_REPORT.md | Implementation details & architecture |
| skills/digital-twin/README.md | Digital twin feature guide |
| skills/digital-twin/SETUP.md | Integration guide |
| SKILLS_REGISTRY.md | Skills registry & discovery |
| COMMUNITY_PUBLISHING.md | Publishing guide |

---

## Testing

All skills tested:

```bash
cd ~/workspace/toleria-knowledge-orchestrator-skill
bash test/run-tests.sh

# Expected: 14/14 tests passing
```

Manual test (BrewPress extraction):

```bash
/toleria-digital-twin --repo ~/workspace/developerscoffee.com/src/brewpress

# Expected: 35 items extracted, vault indexed
```

---

## Commits

Two commits ready:

1. **280a6df** — Core skills + tests
   ```
   feat: add 7 core skills + 14 test cases + extraction pipeline
   ```

2. **48c87bb** — Digital twin skill + community publishing
   ```
   feat: add digital twin skill + community publishing infrastructure
   ```

Both pushed to `origin/main`.

---

## Next Steps for Community Release

### Immediate (Week 1)

- [x] Code complete & tested
- [x] Documentation complete
- [x] Community publishing infrastructure ready
- [ ] Create GitHub release tag `v1.0.0`
- [ ] Write RELEASE_NOTES.md (features, installation, examples)
- [ ] Submit to skills.sh registry

### Short-term (Week 2-4)

- [ ] skills.sh approval (1-2 weeks review)
- [ ] Announce on social media (Twitter, LinkedIn, Dev.to)
- [ ] Monitor initial issues & feedback
- [ ] Update docs based on community questions

### Medium-term (Month 2-3)

- [ ] Release v1.0.1 (bug fixes)
- [ ] Release v1.1.0 (enhancements: multi-repo, NLP, etc.)
- [ ] Grow community (stars, installations)
- [ ] Accept community contributions

### Long-term (Month 4+)

- [ ] Major features: real-time sync, web UI, team collaboration
- [ ] External integrations (Confluence, Notion, Linear)
- [ ] API server for team access
- [ ] 5K+ installations milestone

---

## Deployment Checklist

Before releasing:

- [x] All 14 tests passing
- [x] Code reviewed (CEO plan approved)
- [x] Documentation complete (README, SETUP, API ref)
- [x] Cross-platform compatible (Darwin, Linux, Windows tested)
- [x] No hardcoded credentials or secrets
- [x] MIT license included
- [x] Author/contact info in manifest
- [x] Example usage documented
- [x] Installation script working
- [x] Community publishing guide written
- [ ] GitHub release tag created
- [ ] RELEASE_NOTES.md written
- [ ] Submitted to skills.sh

---

## Success Metrics

Target for v1.0:
- 1K+ installations (skills.sh + direct)
- 10+ GitHub stars
- 0 critical issues at 1-month

Target for v1.1:
- 5K+ installations
- Multi-repo aggregation feature
- 20+ GitHub stars
- 3-5 community contributions

---

## Support Plan

Once published:

1. **GitHub Issues** — Bug reports, feature requests
2. **GitHub Discussions** — Questions, ideas
3. **Email** — contact@developers.coffee
4. **Documentation** — Comprehensive guides included
5. **Response time** — 24 hours for issues

---

## Marketing Materials

### Tagline

> Extract your codebase's architectural knowledge. Keep your knowledge graph updated automatically. Digital twin for your project.

### Features (bullet points)

- 🔍 One-go extraction — Scan entire repo, extract 30+ items
- ♻️ Incremental sync — Only new/changed files processed
- 🤖 Continuous updates — Optional daily/hourly automatic sync
- ✅ Idempotent — Safe to re-run multiple times
- 📊 Queryable — Fast JSON lookups via jq
- 🔗 Linked knowledge — Wikilinks for relationships
- 📦 Integrable — Works with git, CI/CD, documentation systems

### Positioning

For teams who want to:
- Extract architectural knowledge from code
- Keep knowledge graphs updated automatically
- Create searchable, versionable documentation
- Make knowledge discovery easy
- Enable team collaboration on architecture

---

## GitHub Release Template

```markdown
# Toleria Digital Twin v1.0.0

Extract and continuously sync codebase knowledge to Toleria vault.

## Features

✨ **One-go extraction**
Scan entire repository, extract architectural decisions, design patterns, 
technical components, and tech debt in one command.

♻️ **Incremental updates**
On re-run, only new/changed files are processed. Idempotent — safe to 
run multiple times without duplicates.

🤖 **Continuous sync (optional)**
Enable daily/hourly automatic extraction. Knowledge graph stays current 
as code evolves.

🔍 **Queryable knowledge graph**
Extract items indexed as JSON. Fast queries via jq or APIs.

## Installation

```bash
# Via skills.sh
skills.sh install toleria-digital-twin

# Or manually
./install-skill.sh toleria-digital-twin --global
```

## Quick Start

```bash
# Extract your project
/toleria-digital-twin --repo ~/workspace/my-project

# Query results
jq '.[] | {id, type}' ~/Documents/Vault/INDEX/decisions.json
```

## Documentation

- [Installation Guide](./skills/digital-twin/SETUP.md)
- [Feature Guide](./skills/digital-twin/README.md)
- [API Reference](./SKILL_REFERENCE.md)

## What's New

- 7 core Toleria skills (vault, extract, link, index, validate)
- Digital twin skill with extraction engine
- 14 comprehensive test cases
- Cross-platform support (macOS, Linux, Windows)
- Community publishing infrastructure

## Status

✓ Production ready  
✓ 14/14 tests passing  
✓ Tested on BrewPress (19 Python modules)  

## Contributing

Welcome! See COMMUNITY_PUBLISHING.md for guidelines.

## License

MIT License. See LICENSE for details.
```

---

## Ready to Ship

**All items ready for community publishing.**

Current status:
- ✓ Code complete & tested
- ✓ Documented
- ✓ Published to GitHub (`main` branch)
- ✓ Community infrastructure ready
- ⏳ Awaiting skills.sh submission

**Next action:** Create GitHub release tag `v1.0.0` and submit to skills.sh.

---

**Date:** 2026-05-01  
**Version:** 1.0.0  
**Status:** Production Ready  
