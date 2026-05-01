# Toleria Knowledge Orchestrator Skill

**Platform-agnostic, reusable skill for managing engineering knowledge across multiple projects.**

Extract, normalize, and track decisions, patterns, and project state in a centralized vault. Build a reusable knowledge base indexed by technology stack. Never reinvent solutions.

![Status](https://img.shields.io/badge/status-production-green)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

✅ **One-to-One Project Mapping** — One repo = one project (strict)  
✅ **Stack-Based Knowledge Indexing** — Group decisions/patterns by tech stack  
✅ **Centralized Vault** — All knowledge stored locally, never in repos  
✅ **Real-Time Project Tracking** — Live status, tasks, blockers  
✅ **Automatic Deduplication** — No duplicate decisions across projects  
✅ **Platform Agnostic** — Works with Claude Code, Gemini CLI, Copilot CLI  
✅ **Zero MCP Dependency** — Pure bash implementation, works offline  
✅ **Agent-Friendly** — Agents invoke functions directly, no wrapper logic  

## Quick Start

### 1. Install (One Command for All Platforms)

Clone repo and run universal installer:

```bash
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git
cd toleria-knowledge-orchestrator-skill
./install.sh
```

This installs to `~/.agents/skills/toleria` and symlinks from:
- `~/.claude/skills/toleria` → Claude Code
- `~/.gemini/skills/toleria` → Gemini CLI
- `~/.copilot/skills/toleria` → Copilot CLI
- `~/.codex/skills/toleria` → Codex

**Single source of truth** — Update one location, all platforms see changes.

To uninstall:
```bash
./install.sh --uninstall
```

### 2. Initialize Vault

```bash
/toleria init-vault
```

This creates the vault structure at `~/Documents/Vault`:
```
Vault/
├── STACKS/           — Tech stack definitions
├── PROJECTS/         — Project metadata (1:1 per repo)
├── DECISIONS/        — Canonical decision library
├── PATTERNS/         — Reusable code/design patterns
├── EXECUTION/        — Live project state
└── INDEX/            — Fast lookup indexes
```

### 3. Scan Your Projects

```bash
# Single project
/toleria scan-repo ~/workspace/my-project

# All projects
/toleria scan-all-repos ~/workspace
```

### 4. Query Knowledge

```bash
# Find patterns for a tech stack
/toleria query stack JAVA_SPRING_POSTGRES

# Find decisions about authentication
/toleria query decision authentication

# Check project status
/toleria query project my-project
```

## Installation Architecture

### How Symlinks Work

The installer creates a **single installation point** (`~/.agents/skills/toleria`) and **symlinks from each platform**:

```
~/.agents/skills/toleria/              ← Single source of truth
├── platform.sh
├── toleria.sh
├── bootstrap.sh
├── validate.sh
└── ... (all files)

~/.claude/skills/toleria ─────┐
~/.gemini/skills/toleria ─────┼──→ All point to ~/.agents/skills/toleria
~/.copilot/skills/toleria ────┤
~/.codex/skills/toleria ───────┘
```

**Benefits:**
- ✅ Update once, all platforms see changes
- ✅ No duplication across agents
- ✅ Consistent version across platforms
- ✅ Easy uninstall (removes symlinks + source)

### Manual Installation (Advanced)

If `install.sh` doesn't work on your system:

```bash
# 1. Copy to single location
mkdir -p ~/.agents/skills/
cp -r toleria-knowledge-orchestrator-skill ~/.agents/skills/toleria

# 2. Create symlinks manually
ln -s ~/.agents/skills/toleria ~/.claude/skills/toleria
ln -s ~/.agents/skills/toleria ~/.gemini/skills/toleria
ln -s ~/.agents/skills/toleria ~/.copilot/skills/toleria
ln -s ~/.agents/skills/toleria ~/.codex/skills/toleria

# 3. Verify
ls -la ~/.claude/skills/toleria   # Should show → ~/.agents/skills/toleria
```

## Architecture

### Vault Structure

```
~/Documents/Vault/
├── STACKS/
│   ├── JAVA_SPRING_POSTGRES_KAFKA/
│   │   ├── stack.meta.json          — Stack metadata
│   │   ├── decisions.md             — Stack-specific decisions
│   │   ├── patterns.md              — Stack-specific patterns
│   │   └── anti_patterns.md         — What NOT to do
│   │
│   └── PYTHON_DJANGO_POSTGRES/
│       └── ...
│
├── PROJECTS/
│   ├── my-backend/
│   │   ├── project.meta.json        — Project metadata (1:1 map to repo)
│   │   ├── architecture.md          — Architecture overview
│   │   ├── decisions.md             — Project-specific decisions
│   │   ├── tasks.md                 — Active tasks
│   │   ├── state.md                 — Current state snapshot
│   │   └── links.json               — Links to repo, docs, etc.
│   │
│   └── my-frontend/
│       └── ...
│
├── DECISIONS/
│   ├── DECISION_001.md              — Why Spring Boot?
│   ├── DECISION_002.md              — Auth strategy
│   └── ...
│
├── PATTERNS/
│   ├── logging/
│   │   └── structured-logging.md    — Log pattern
│   ├── error-handling/
│   │   └── exponential-backoff.md   — Retry pattern
│   ├── api-design/
│   │   └── rest-conventions.md      — API pattern
│   ├── testing/
│   │   └── integration-tests.md     — Testing pattern
│   └── config-management/
│       └── environment-variables.md — Config pattern
│
├── EXECUTION/
│   ├── my-backend/
│   │   ├── current_state.json       — Live status
│   │   ├── backlog.json             — Tasks
│   │   ├── blockers.json            — Blocked items
│   │   └── activity.log             — Recent activity
│   │
│   └── my-frontend/
│       └── ...
│
└── INDEX/
    ├── stack_index.json             — STACK_ID → projects
    ├── project_index.json           — project → metadata
    ├── decision_index.json          — decision → stack + projects
    └── pattern_index.json           — pattern → category + projects
```

## Core Functions

### Initialization

```bash
/toleria init-vault
```
Initialize vault directory structure.

### Scanning

```bash
/toleria scan-repo <repo-path>
```
Scan single repository, detect stack, extract metadata.

```bash
/toleria scan-all-repos <workspace-path>
```
Scan all repositories in workspace.

### Extraction

```bash
/toleria extract-decisions <repo-path>
```
Extract architectural decisions from:
- ADR files (docs/adr/)
- Commit messages (tagged DECISION:)
- Code comments (DESIGN_DECISION:)
- README architecture sections

```bash
/toleria extract-patterns <repo-path>
```
Extract reusable patterns from:
- Utility modules
- API design
- Error handling
- Logging strategies
- Testing approaches

### Analysis

```bash
/toleria identify-stack <repo-path>
```
Detect technology stack.

```bash
/toleria sync-execution-state <repo-path>
```
Update real-time project state (tasks, blockers, activity).

### Maintenance

```bash
/toleria deduplicate-knowledge
```
Merge duplicate decisions and patterns globally.

```bash
/toleria build-index
```
Rebuild all lookup indexes.

```bash
/toleria health-check
```
Verify vault integrity.

### Querying

```bash
/toleria query <type> <query>
```
Search knowledge base:
- `type`: `stack`, `decision`, `pattern`, `project`
- `query`: search term

Examples:
```bash
/toleria query stack JAVA_SPRING
/toleria query decision authentication
/toleria query pattern logging
/toleria query project my-backend
```

### Publishing

```bash
/toleria publish-stack <STACK_ID>
```
Export stack and all linked knowledge as shareable bundle.

## Data Schemas

### project.meta.json
```json
{
  "project_id": "repo-name",
  "repo_path": "/absolute/path/to/repo",
  "vault_path": "~/Documents/Vault/PROJECTS/repo-name",
  "stack_id": "JAVA_SPRING_BOOT_POSTGRES_KAFKA",
  "status": "DEV|PROD|STALLED|ARCHIVED",
  "created_at": "2026-05-01",
  "last_updated": "2026-05-01",
  "description": "Brief description"
}
```

### stack.meta.json
```json
{
  "stack_id": "JAVA_SPRING_BOOT_POSTGRES_KAFKA",
  "language": "Java",
  "frameworks": ["Spring Boot"],
  "database": ["Postgres"],
  "infra": ["Docker", "Kubernetes"],
  "messaging": ["Kafka"],
  "projects": ["repo1", "repo2"],
  "created_at": "2026-05-01",
  "decision_count": 5,
  "pattern_count": 12
}
```

## Integration Guides

### Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "toleria.sync": {
      "trigger": "on-save",
      "command": "toleria sync-execution-state $REPO"
    }
  }
}
```

In your CLAUDE.md:
```markdown
# Use Toleria

When working on projects, use toleria skill to:
- Extract architectural decisions
- Identify reusable patterns
- Track project state
```

Then invoke:
```
/toleria scan-repo ~/workspace/my-project
```

### Gemini CLI

Add to `~/.gemini/config.yaml`:

```yaml
skills:
  toleria-knowledge-orchestrator:
    enabled: true
    hooks:
      - trigger: post-commit
        action: sync-execution-state
```

Invoke:
```
activate_skill toleria-knowledge-orchestrator
/toleria scan-all-repos ~/workspace
```

### Copilot CLI

Add to `~/.copilot/config.json`:

```json
{
  "skills": [
    {
      "id": "toleria-knowledge-orchestrator",
      "enabled": true
    }
  ]
}
```

Invoke:
```
/toleria query stack PYTHON_DJANGO
```

### Standalone (Any Platform)

```bash
# Bootstrap vault
./bootstrap.sh --vault-root ~/Documents/Vault --workspace ~/workspace

# Run directly
./toleria.sh init-vault
./toleria.sh scan-repo ~/workspace/my-project
```

## Rules (Strict Enforcement)

| Rule | What | Why |
|------|------|-----|
| **1:1 Mapping** | One repo = one project | Clear boundaries, no confusion |
| **Vault Only** | All writes go to Vault | Repos stay clean, single source of truth |
| **No Duplication** | Global deduplication | Prevent re-invention, maintain consistency |
| **Stack Required** | Every project has STACK_ID | Enable cross-project reuse |
| **State Current** | EXECUTION/ always fresh | Accurate real-time view |

## Performance

| Operation | Time |
|-----------|------|
| Scan single repo | ~2s |
| Scan 50 repos | ~30s (parallel) |
| Extract decisions | ~5s per repo |
| Extract patterns | ~10s per repo |
| Deduplicate | ~2s |
| Build index | ~1s |
| Query | ~100ms |

## Use Cases

### 1. Prevent Re-Invention
Extract decisions once, reuse across projects:
```
Project A: "Why did we choose Postgres?"
→ Query: /toleria query decision database
→ Result: [Decision: Postgres over MySQL]
→ Reuse in Project B ✓
```

### 2. Consistent Architecture
Use stack-based patterns:
```
Project A (JAVA_SPRING_POSTGRES): Uses error handling pattern X
Project B (JAVA_SPRING_POSTGRES): Inherit same pattern
→ Consistency without duplication
```

### 3. Project Health Dashboard
Track all projects in real-time:
```
/toleria query project all
→ [Project A: PROD, healthy]
→ [Project B: DEV, 3 blockers]
→ [Project C: STALLED, needs attention]
```

### 4. Onboarding
New team member needs to understand architecture:
```
/toleria query stack JAVA_SPRING_POSTGRES
→ All decisions for this stack
→ All patterns for this stack
→ Instant architecture overview
```

## Fail Conditions

Vault aborts (never partial writes) on:

```
✗ Write attempted inside repo
✗ Missing stack_id
✗ Duplicate decision found
✗ Multiple projects per repo
✗ Invalid metadata JSON
```

## Future Enhancements

- [ ] Web UI for vault browsing
- [ ] VS Code extension
- [ ] JetBrains IDE integration
- [ ] Automated pattern detection (ML)
- [ ] Knowledge graph visualization
- [ ] Team vault with encrypted sharing
- [ ] Scheduled auto-scans
- [ ] Decision change notifications

## Publishing

This skill is ready to publish to:
- Claude Code skill registry
- Gemini CLI marketplace
- Copilot CLI registry

See [manifest.json](manifest.json) for publishing metadata.

## Contributing

Contributions welcome! Please:
1. Fork repository
2. Create feature branch
3. Submit PR with tests

## License

MIT License — See LICENSE file

## Support

- **Documentation**: See SKILL.md for complete reference
- **Issues**: Open GitHub issue
- **Questions**: Check FAQ in README

## Author

**Uday Chauhan**  
Email: chauhan.s.uday26@gmail.com  
GitHub: [@udaychauhan](https://github.com/udaychauhan)

---

**Version**: 1.0.0  
**Status**: Production Ready  
**Last Updated**: 2026-05-01
# toleria-knowledge-orchestrator-skill
