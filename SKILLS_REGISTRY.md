# Toleria Skills Registry

Community skills for Toleria knowledge extraction system.

## Available Skills

### Core Skills (7)

Built-in Toleria skills. No installation needed.

| Skill | Purpose | Type |
|-------|---------|------|
| `vault.read` | Read and parse notes | I/O |
| `vault.write` | Atomic writes with validation | I/O |
| `knowledge.extract` | Parse Decision:/Pattern:/Tech debt: | Parser |
| `knowledge.link` | Create wikilinks | Linker |
| `inbox.process` | Classify and move items | Processor |
| `vault.validate` | Schema validation | Validator |
| `vault.index` | Generate fast-lookup INDEX | Indexer |

### Plugin Skills

Installable via `skills.sh`.

#### toleria-digital-twin (v1.0.0)

**Extract and continuously sync codebase knowledge to Toleria vault. Digital twin keeps knowledge graph updated.**

- **Trigger:** `/toleria-digital-twin`
- **Author:** Toleria Team
- **License:** MIT
- **Status:** Production ready
- **Requirements:** Toleria core skills, jq, bash 4.0+

**Features:**
- One-go extraction (scan entire repo, extract 30+ items)
- Incremental updates (only new/changed files)
- Continuous sync (optional daily/hourly)
- Idempotent (safe to re-run)
- Digital twin pattern (knowledge mirrors codebase)

**Installation:**
```bash
skills.sh install toleria-digital-twin
```

**Usage:**
```bash
# One-go extraction
/toleria-digital-twin --repo ~/workspace/your-project

# With continuous sync
/toleria-digital-twin --repo ~/workspace/your-project --schedule daily
```

**Files:**
- `SKILL.md` — Skill spec & workflows
- `extract-and-sync.sh` — Extraction engine
- `manifest.json` — Config & metadata
- `README.md` — Feature guide
- `SETUP.md` — Integration guide

**Documentation:** See `skills/digital-twin/README.md`

---

## Installation

### Option 1: Via skills.sh

```bash
# Install from registry
skills.sh install toleria-digital-twin

# List installed
skills.sh list | grep toleria

# Invoke
/toleria-digital-twin --repo ~/workspace/project
```

### Option 2: Manual installation

```bash
# Clone repo
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git

# Install skill
mkdir -p ~/.claude/skills/toleria-digital-twin
cp skills/digital-twin/* ~/.claude/skills/toleria-digital-twin/

# Register in CLAUDE.md
echo "- **toleria-digital-twin** - Extract and sync codebase knowledge" >> ~/.claude/CLAUDE.md

# Verify
ls ~/.claude/skills/toleria-digital-twin/SKILL.md
```

### Option 3: As a submodule

```bash
# In your project
git submodule add https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git .claude/skills/toleria

# Install digital twin
cp .claude/skills/toleria/skills/digital-twin ~/.claude/skills/

# Register
echo "export TOLERIA_SKILLS=./.claude/skills/toleria/skills" >> .env
```

---

## Discovery

### Find skills

```bash
# List all skills
skills.sh list

# Search
skills.sh search knowledge
skills.sh search extraction
skills.sh search vault

# Get info
skills.sh info toleria-digital-twin
skills.sh help toleria-digital-twin
```

### Registry metadata

Skills are discoverable via `skills.sh` CLI. Registry stored in:
- `SKILLS_REGISTRY.md` (this file)
- `manifest.json` (per-skill metadata)
- GitHub releases (for versioning)

---

## Publishing Your Own Skill

### 1. Create skill structure

```
my-skill/
├── SKILL.md              # Skill definition (required)
├── manifest.json         # Metadata (required)
├── README.md             # Documentation
├── SETUP.md              # Integration guide
├── my-skill.sh           # Implementation
└── tests/                # Test cases
```

### 2. Write manifest.json

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "What your skill does",
  "author": "Your Name",
  "license": "MIT",
  "triggers": ["/my-skill"],
  "dependencies": {
    "toleria": ">=1.0.0",
    "jq": ">=1.6"
  }
}
```

### 3. Write SKILL.md

Follow skill spec format. See `skills/digital-twin/SKILL.md` as example.

### 4. Add to registry

```bash
# 1. Add to SKILLS_REGISTRY.md
# 2. Create PR to main repo
# 3. Community review
# 4. Merge to main
# 5. Tag release: v1.x.x
# 6. Published to registry
```

### 5. Submit to skills.sh

Register with skills.sh team:
- Email: skills@developers.coffee
- GitHub: Issue on DevelopersCoffee/skills-registry
- Format: skill name, repo URL, contact

---

## Testing Skills

### Manual testing

```bash
# Test single skill
bash skills/digital-twin/extract-and-sync.sh ~/workspace/test-project

# Test with Toleria pipeline
cd ~/workspace/toleria-knowledge-orchestrator-skill
bash test/run-tests.sh
```

### CI/CD testing

Skills should include test cases:

```bash
# skills/digital-twin/test/test-extraction.sh
#!/bin/bash
# Test extraction from sample repo
# Verify: 30+ items extracted
# Verify: All items in vault
# Verify: INDEX valid JSON
# Verify: Idempotent (re-run = 0 new)
```

---

## Versioning

Skills follow semantic versioning:

- `1.0.0` — Major.Minor.Patch
- `1.x.x` — Incompatible API changes
- `x.1.x` — Backwards-compatible features
- `x.x.1` — Bug fixes

Tags: `v1.0.0`, `v1.0.1`, etc.

---

## License

All Toleria skills: MIT License

Community skills: Developer's choice (MIT, Apache 2.0, GPL, etc.)

---

## Support

### Community

- GitHub Issues: DevelopersCoffee/toleria-knowledge-orchestrator-skill
- Discussions: DevelopersCoffee/discussions
- Slack: #toleria-skills (if available)

### Maintainers

- **toleria-digital-twin:** Toleria Team (@ DevelopersCoffee)

---

## Roadmap

### Phase 1 (Current)
- [x] 7 core skills
- [x] Digital twin skill
- [x] skills.sh integration
- [x] Community registry

### Phase 2
- [ ] Multi-repo aggregation skill
- [ ] NLP extraction skill
- [ ] Graph visualization skill
- [ ] Team collaboration skill
- [ ] External integration skills (Confluence, Notion, Linear)

### Phase 3
- [ ] Real-time sync (webhook triggers)
- [ ] Web UI for knowledge browser
- [ ] Mobile app for knowledge access
- [ ] API server for team access

---

**Status:** Production ready. Ready for community publishing.
