# Toleria Skill — Integration Guide

**Platform-specific setup and usage instructions**

## Installation Matrix

| Platform | Dir | Setup |
|----------|-----|-------|
| **Claude Code** | `~/.claude/skills/` | Copy dir + invoke `/toleria` |
| **Gemini CLI** | `~/.gemini/skills/` | Copy dir + `activate_skill` |
| **Copilot CLI** | `~/.copilot/skills/` | Copy dir + register in config |
| **Standalone** | Any | Run `./toleria.sh` directly |

---

## Claude Code

### 1. Install

```bash
mkdir -p ~/.claude/skills/
cp -r toleria-knowledge-orchestrator-skill ~/.claude/skills/
```

### 2. Invoke Skill

In Claude Code conversation:

```
/toleria init-vault
/toleria scan-repo ~/workspace/my-project
/toleria query stack JAVA_SPRING
```

### 3. Add to CLAUDE.md (Optional)

Create `~/.claude/CLAUDE.md`:

```markdown
# Toleria Skill

Use toleria for knowledge management across projects.

## Quick Commands

- `/toleria init-vault` — Initialize vault
- `/toleria scan-repo <path>` — Scan project
- `/toleria scan-all-repos <workspace>` — Scan all projects
- `/toleria query stack <STACK_ID>` — Find patterns/decisions
- `/toleria health-check` — Verify vault integrity

## Rules

1. One repo = one project (strict)
2. All knowledge in ~/Documents/Vault
3. Never write inside repositories
4. Deduplicate globally
5. Track real-time project state
```

### 4. Hook Integration (Optional)

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "on-repo-change": {
      "command": "/toleria sync-execution-state $REPO"
    }
  }
}
```

---

## Gemini CLI

### 1. Install

```bash
mkdir -p ~/.gemini/skills/
cp -r toleria-knowledge-orchestrator-skill ~/.gemini/skills/
```

### 2. Configure

Add to `~/.gemini/config.yaml`:

```yaml
skills:
  toleria-knowledge-orchestrator:
    enabled: true
    vault_root: ~/Documents/Vault
    
hooks:
  - skill: toleria-knowledge-orchestrator
    trigger: post-commit
    function: sync-execution-state
```

### 3. Activate Skill

```bash
gemini activate_skill toleria-knowledge-orchestrator
```

### 4. Invoke

```bash
# Initialize
gemini run toleria init-vault

# Scan project
gemini run toleria scan-repo ~/workspace/my-project

# Query
gemini run toleria query stack JAVA_SPRING
```

### 5. Gemini GEMINI.md

Create `~/.gemini/GEMINI.md`:

```markdown
# Toleria Skill Config

vault_root: ~/Documents/Vault
strict_mode: true
repo_read_only: true

## Skills

- toleria-knowledge-orchestrator (v1.0.0)

## Usage

When I ask you to extract knowledge, use toleria skill:
- Always scan repo first
- Deduplicate decisions
- Group by stack
- Track project state
```

---

## Copilot CLI

### 1. Install

```bash
mkdir -p ~/.copilot/skills/
cp -r toleria-knowledge-orchestrator-skill ~/.copilot/skills/
```

### 2. Configure

Add to `~/.copilot/config.json`:

```json
{
  "skills": [
    {
      "id": "toleria-knowledge-orchestrator",
      "enabled": true,
      "config": {
        "vault_root": "~/Documents/Vault",
        "strict_mode": true
      }
    }
  ],
  "hooks": [
    {
      "trigger": "post-commit",
      "action": "toleria sync-execution-state"
    }
  ]
}
```

### 3. Invoke

```bash
copilot /toleria init-vault
copilot /toleria scan-all-repos ~/workspace
copilot /toleria query decision authentication
```

### 4. Custom Commands

Add to `~/.copilot/commands.json`:

```json
{
  "commands": {
    "vault-scan": "toleria scan-all-repos ~/workspace",
    "vault-health": "toleria health-check",
    "vault-query": "toleria query $1 $2"
  }
}
```

Then:
```bash
copilot vault-scan
copilot vault-health
copilot vault-query stack JAVA_SPRING
```

---

## Standalone (Pure Bash)

### 1. Setup

```bash
# Clone/download skill
cd ~/workspace
git clone <repo-url> toleria-skill
cd toleria-skill

# Make scripts executable
chmod +x bootstrap.sh toleria.sh

# Configure
export VAULT_ROOT=~/Documents/Vault
export WORKSPACE_ROOT=~/workspace
```

### 2. Bootstrap

```bash
./bootstrap.sh --vault-root ~/Documents/Vault --workspace ~/workspace
```

### 3. Run Directly

```bash
# Create alias (optional)
alias toleria='~/workspace/toleria-skill/toleria.sh'

# Use
toleria init-vault
toleria scan-repo ~/workspace/my-project
toleria query stack JAVA_SPRING
```

### 4. Cron Integration (Optional)

Auto-scan projects daily:

```bash
# Add to crontab
0 2 * * * ~/workspace/toleria-skill/toleria.sh scan-all-repos ~/workspace >> ~/.toleria/scan.log 2>&1
```

---

## Agent Usage

Any agent (Claude, Gemini, Copilot) can invoke skill functions:

### Claude Code Agent

```
Agent message: "Please scan all projects and extract decisions"
→ Agent calls: toleria.scan-all-repos
→ Agent calls: toleria.extract-decisions
→ Returns: decisions extracted and indexed
```

### Gemini Agent

```
Agent message: "Show me all patterns for JAVA_SPRING stack"
→ Agent calls: toleria.query-knowledge(stack, JAVA_SPRING)
→ Returns: patterns found
```

### Copilot Agent

```
Agent message: "Health check vault"
→ Agent calls: toleria.health-check
→ Returns: violations report
```

**No platform-specific logic needed.** Agents invoke functions directly.

---

## Environment Variables

Override defaults:

```bash
# Vault location
export VAULT_ROOT=/custom/vault/path

# Strict mode (default: true)
export STRICT_MODE=false

# Read-only repos (default: true)
export REPO_READ_ONLY=true
```

---

## Configuration Files

### vault.config.json

Located in `~/Documents/Vault/`:

```json
{
  "vault_root": "~/Documents/Vault",
  "strict_mode": true,
  "repo_read_only": true,
  "deduplication": true,
  "created_at": "2026-05-01T12:00:00Z",
  "version": "1.0.0"
}
```

Edit to change behavior (will take effect on next run).

---

## Troubleshooting

### "Vault not initialized"

```bash
/toleria init-vault
```

### "Permission denied"

```bash
chmod +x ~/.toleria/scripts/*.sh
```

### "Not a git repository"

```bash
# Ensure path is a valid git repo
cd /path/to/repo && git status
```

### "Invalid JSON in vault"

```bash
/toleria health-check
# Fix reported violations
```

### "Duplicate decision detected"

```bash
/toleria deduplicate-knowledge
```

---

## Performance Tuning

### Parallel Scanning

For many repos, scan in parallel:

```bash
# Via GNU parallel
find ~/workspace -maxdepth 2 -type d -name ".git" | \
  parallel 'toleria scan-repo {/.}'

# Or xargs
find ~/workspace -maxdepth 2 -type d -name ".git" | \
  xargs -I {} toleria scan-repo {%}
```

### Incremental Sync

Only sync changed projects:

```bash
# Run after git push
git diff HEAD~1..HEAD --name-only | \
  xargs -I {} toleria sync-execution-state $(dirname {})
```

### Index Optimization

Rebuild indexes weekly:

```bash
# Cron job (add to crontab)
0 3 * * 0 toleria build-index
```

---

## Multi-Vault Setup (Advanced)

Support multiple vaults per user:

```bash
# Personal vault
export VAULT_ROOT=~/Documents/Vault.personal
toleria scan-repo ~/projects/personal/...

# Work vault
export VAULT_ROOT=~/Documents/Vault.work
toleria scan-repo ~/projects/work/...

# Team vault (shared, read-only)
export VAULT_ROOT=/shared/team-vault
export REPO_READ_ONLY=true
toleria query stack TEAM_STACK
```

---

## Integration with Other Tools

### Git Hooks

Add to `.git/hooks/post-commit`:

```bash
#!/bin/bash
toleria sync-execution-state "$(git rev-parse --show-toplevel)"
```

### IDE Integration

### VS Code

Add to `.vscode/settings.json`:

```json
{
  "terminal.integrated.shellArgs.osx": ["-i", "-l"],
  "terminal.integrated.env.osx": {
    "VAULT_ROOT": "~/Documents/Vault"
  }
}
```

### JetBrains

Add external tool:
- Program: `toleria`
- Arguments: `sync-execution-state $ProjectFileDir`
- Working Dir: `$ProjectFileDir`

### Continuous Integration

In CI/CD pipeline:

```yaml
# .github/workflows/vault-sync.yml
name: Sync Vault

on: [push]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Sync to vault
        run: |
          toleria sync-execution-state ${{ github.workspace }}
```

---

## Getting Help

- **Documentation**: See SKILL.md
- **Examples**: Check README.md
- **Issues**: GitHub issues
- **FAQ**: This guide

---

**Version**: 1.0.0  
**Last Updated**: 2026-05-01
