# Toleria Skill — Quick Reference

**One-page cheat sheet for common operations**

## Installation

```bash
# Copy to platform skill dir
cp -r toleria-knowledge-orchestrator-skill ~/.claude/skills/
# or ~/.gemini/skills/ or ~/.copilot/skills/
```

## Initialize (One-Time)

```bash
/toleria init-vault
```

Creates: `~/Documents/Vault/` with full structure.

## Common Commands

### Scan

```bash
# Single repo
/toleria scan-repo ~/workspace/my-project

# All repos in workspace
/toleria scan-all-repos ~/workspace
```

**Result**: Project metadata created, stack detected.

### Query

```bash
# Patterns for tech stack
/toleria query stack JAVA_SPRING_POSTGRES

# Decisions about topic
/toleria query decision authentication

# Project status
/toleria query project my-backend

# Pattern by name
/toleria query pattern logging
```

### Maintenance

```bash
# Check vault health
/toleria health-check

# Merge duplicates
/toleria deduplicate-knowledge

# Rebuild indexes
/toleria build-index
```

### Extract Knowledge

```bash
# Get architectural decisions
/toleria extract-decisions ~/workspace/my-project

# Get reusable patterns
/toleria extract-patterns ~/workspace/my-project
```

### Stack Info

```bash
# Detect stack for repo
/toleria identify-stack ~/workspace/my-project

# Sync project state (tasks, blockers, activity)
/toleria sync-execution-state ~/workspace/my-project
```

### Share Knowledge

```bash
# Export stack as shareable bundle
/toleria publish-stack JAVA_SPRING_POSTGRES
```

## Vault Structure

```
~/Documents/Vault/
├── STACKS/            ← Tech stack definitions
├── PROJECTS/          ← One per repo (1:1 mapping)
├── DECISIONS/         ← Global decision library
├── PATTERNS/          ← Reusable patterns by category
├── EXECUTION/         ← Live project state
└── INDEX/             ← Fast lookup (auto-maintained)
```

## Stack ID Naming

UPPER_SNAKE_CASE:

```
JAVA_SPRING_BOOT_POSTGRES_KAFKA
PYTHON_DJANGO_POSTGRES
TYPESCRIPT_REACT_NODEJS
GO_GIN_POSTGRESQL
```

## Project Metadata

Every project gets `project.meta.json`:

```json
{
  "project_id": "repo-name",
  "repo_path": "/path/to/repo",
  "stack_id": "JAVA_SPRING_POSTGRES",
  "status": "DEV|PROD|STALLED",
  "created_at": "2026-05-01"
}
```

## Decision Format

```markdown
# Decision: Title

## Context
[What changed]

## Problem
[What needs deciding]

## Decision
[What we chose and why]

## Tradeoffs
- Pro: [benefit]
- Con: [cost]

## Tags
- stack_id: JAVA_SPRING_POSTGRES
- projects: [repo1, repo2]
```

## Pattern Format

```markdown
# Pattern: Name

## Use Case
[When to use]

## Implementation
[How to do it]

## Code Snippet
```[lang]
[example]
```

## Pros
- [benefit]

## Cons
- [tradeoff]

## Used In
- [repo1: path]
```

## Rules (Strict)

| Rule | What |
|------|------|
| 1:1 | One repo = one project (never merge/split) |
| Vault | All writes go to ~/Documents/Vault (never repos) |
| No Dups | Global deduplication (one decision per fact) |
| Stack | Every project has STACK_ID (required) |
| Fresh | EXECUTION/ always reflects reality (current) |

## Fail Conditions (Abort)

```
✗ Writing inside repo
✗ Missing stack_id
✗ Duplicate decision
✗ Multiple projects per repo
✗ Invalid JSON
```

## Environment Variables

```bash
# Vault location
export VAULT_ROOT=~/Documents/Vault

# Strict enforcement (default: true)
export STRICT_MODE=true

# Repo read-only (default: true)
export REPO_READ_ONLY=true
```

## Typical Workflow

```bash
# 1. Initialize (once)
/toleria init-vault

# 2. Scan all projects
/toleria scan-all-repos ~/workspace

# 3. Extract knowledge
/toleria extract-decisions ~/workspace/my-project
/toleria extract-patterns ~/workspace/my-project

# 4. Deduplicate
/toleria deduplicate-knowledge

# 5. Build indexes
/toleria build-index

# 6. Query
/toleria query stack JAVA_SPRING
/toleria query decision auth

# 7. Monitor (periodic)
/toleria sync-execution-state ~/workspace/my-project
/toleria health-check
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Vault not initialized" | `/toleria init-vault` |
| "Not a git repo" | Ensure `.git/` exists in path |
| "Permission denied" | `chmod +x ~/.toleria/scripts/*.sh` |
| "Invalid JSON" | `/toleria health-check` (shows violations) |
| "Duplicate found" | `/toleria deduplicate-knowledge` |

## Performance

| Operation | Time |
|-----------|------|
| Scan 1 repo | ~2s |
| Scan 50 repos | ~30s |
| Extract decisions | ~5s per repo |
| Extract patterns | ~10s per repo |
| Deduplicate | ~2s |
| Query | ~100ms |

## Platforms

| Platform | Status | Command |
|----------|--------|---------|
| Claude Code | ✅ | `/toleria` |
| Gemini CLI | ✅ | `activate_skill + /toleria` |
| Copilot CLI | ✅ | `/toleria` |
| Standalone | ✅ | `./toleria.sh` |

## Links

- **Full Docs**: SKILL.md
- **Integration**: INTEGRATION_GUIDE.md
- **README**: README.md
- **Manifest**: manifest.json

---

**Version**: 1.0.0  
**Status**: Production Ready
