---
id: toleria-knowledge-orchestrator
name: Toleria Knowledge Orchestrator
version: 1.0.0
author: Uday Chauhan
license: MIT
category: engineering-productivity
scope: global
platforms: ["claude-code", "gemini-cli", "copilot-cli"]
description: >
  Standardized knowledge extraction, normalization, and project tracking system.
  Extracts decisions, patterns, and architecture from repositories.
  Maintains single vault of reusable knowledge indexed by tech stack.
  Tracks real-time project state across all active projects.
  Platform-agnostic, no MCP dependency for core functionality.

tags:
  - knowledge-management
  - documentation
  - project-tracking
  - architecture
  - reusability
  - decision-tracking

requirements:
  - git (repo inspection)
  - find/grep (code analysis)
  - basic shell utilities
  - file system access

vault_root: "~/Documents/Vault"
strict_mode: true
repo_read_only: true
deduplication: enabled

---

# Toleria Knowledge Orchestrator Skill

## Overview

Master knowledge system for personal repositories. Extracts, normalizes, and indexes all technical decisions, patterns, and project state in a central vault. Prevents re-invention of solutions across projects.

## Core Functions

### 1. initialize-vault
Initialize vault structure at ~/Documents/Vault.

```
usage: /toleria init-vault
```

Creates:
- STACKS/ — tech stack library
- PROJECTS/ — 1:1 repo to project mapping
- DECISIONS/ — canonical decision store
- PATTERNS/ — reusable code/design patterns
- EXECUTION/ — live project state
- INDEX/ — fast lookup indexes

### 2. scan-repo
Scan single repository and extract knowledge.

```
usage: /toleria scan-repo <repo-path>
```

Input:
- repo absolute path

Output:
- stack_id detected
- project.meta.json created
- decisions extracted
- patterns identified
- project state snapshot

### 3. scan-all-repos
Scan all repositories in workspace.

```
usage: /toleria scan-all-repos <workspace-path>
```

Input:
- workspace root

Output:
- project inventory
- stack clustering
- decision library
- pattern library
- execution state for each project

### 4. extract-decisions
Extract decisions from repo sources.

```
usage: /toleria extract-decisions <repo-path>
```

Sources:
- ADR files (docs/adr/ or decisions/)
- Commit messages (tagged: DECISION:)
- Code comments (flagged: DESIGN_DECISION:)
- README architecture sections
- Config files and their rationale

Output:
- DECISIONS/*.md
- Global deduplication
- Stack tagging

### 5. extract-patterns
Extract reusable code patterns and design patterns.

```
usage: /toleria extract-patterns <repo-path>
```

Sources:
- Common utility modules
- API design patterns
- Error handling strategies
- Logging architecture
- Testing approaches
- Config management

Output:
- PATTERNS/<category>/*.md
- Code snippets
- Usage examples
- Pros/cons documented

### 6. identify-stack
Detect tech stack from repo.

```
usage: /toleria identify-stack <repo-path>
```

Detects:
- Language (Python, Java, Go, TypeScript, etc.)
- Framework (Spring, Django, FastAPI, React, etc.)
- Database (Postgres, MySQL, MongoDB, DynamoDB, etc.)
- Infrastructure (Docker, K8s, AWS, GCP, etc.)
- Message queues (Kafka, RabbitMQ, SQS, etc.)
- Additional tools

Output:
- STACK_ID: UPPER_SNAKE_CASE
- stack.meta.json created
- projects linked

### 7. sync-execution-state
Update real-time project state.

```
usage: /toleria sync-execution-state <repo-path>
```

Sources:
- Git: last commit, recent activity
- Gstack: execution graph, pending nodes
- Superpower: active reasoning chains
- TODO/FIXME: pending work
- Open issues: blockers
- Build status: health

Output:
- EXECUTION/<repo>/current_state.json
- activity.log
- blockers.json
- task list

### 8. deduplicate-knowledge
Merge duplicate decisions and patterns globally.

```
usage: /toleria deduplicate-knowledge
```

Algorithm:
1. Hash all decisions (title + context)
2. Detect duplicates
3. Keep best version (by completeness, recency, stack relevance)
4. Merge metadata (source_projects)
5. Update all indexes

Output:
- merged decisions
- removed duplicates
- conflict log

### 9. build-index
Rebuild all indexes for fast lookup.

```
usage: /toleria build-index
```

Outputs:
- INDEX/stack_index.json
  - tech_stack → [projects]
  - STACK_ID → [decisions, patterns]

- INDEX/project_index.json
  - project_id → [metadata, stack_id, state]

- INDEX/decision_index.json
  - decision_id → [stack_id, projects, tags]

- INDEX/pattern_index.json
  - pattern_id → [category, stack_id, projects]

### 10. query-knowledge
Search knowledge base by:
- stack
- project
- pattern name
- decision tag

```
usage: /toleria query <type> <query>
types: stack | decision | pattern | project
examples:
  /toleria query stack JAVA_SPRING
  /toleria query decision auth-strategy
  /toleria query pattern logging
  /toleria query project repo-name
```

### 11. publish-stack
Export stack and all linked knowledge as shareable bundle.

```
usage: /toleria publish-stack <STACK_ID>
```

Output:
- STACK_ID.bundle.json
- Include: stack.meta, all decisions, all patterns
- Importable into other vaults

### 12. health-check
Verify vault integrity.

```
usage: /toleria health-check
```

Checks:
- Missing stack_id
- Orphaned projects (no stack)
- Duplicate decisions
- Broken references
- Missing metadata
- Invalid JSON

Output:
- violations.log
- repair suggestions

### 13. validate
Comprehensive determinism + safety validation.

```
usage: /toleria validate
```

Runs 8 checks:
1. **Structure Check** — required folders exist
2. **Schema Validation** — all JSON matches SCHEMA.json
3. **Duplication Check** — no duplicate decision/pattern IDs
4. **Orphan Detection** — every artifact linked to ≥1 project
5. **Path Violations** — no writes outside ~/Documents/Vault
6. **Stack Consistency** — all project stack_ids exist
7. **Idempotency** — re-run produces zero diff
8. **Empty Artifacts** — no empty files

Output:
```json
{
  "status": "PASS|FAIL",
  "score": 0-100,
  "checks": { ...details },
  "violations": []
}
```

Exit code: 0 (PASS) or 1 (FAIL)

## Data Schema

### project.meta.json
```json
{
  "project_id": "repo-name",
  "repo_path": "/absolute/path",
  "vault_path": "~/Documents/Vault/PROJECTS/repo-name",
  "stack_id": "JAVA_SPRING_BOOT_POSTGRES_KAFKA",
  "status": "DEV|PROD|STALLED|ARCHIVED",
  "created_at": "2026-05-01",
  "last_updated": "2026-05-01",
  "description": "brief description"
}
```

### stack.meta.json
```json
{
  "stack_id": "JAVA_SPRING_BOOT_POSTGRES_KAFKA",
  "languages": ["Java"],
  "frameworks": ["Spring Boot"],
  "database": ["Postgres"],
  "infra": ["Docker", "Kubernetes"],
  "messaging": ["Kafka"],
  "tools": ["Maven", "Docker"],
  "projects": ["repo1", "repo2"],
  "created_at": "2026-05-01",
  "decision_count": 5,
  "pattern_count": 12
}
```

### DECISIONS/{ID}.md
```markdown
# Decision: {Title}

## Context
[what changed]

## Problem
[what needs decision]

## Options Considered
1. Option A: [description]
2. Option B: [description]

## Decision
[what we chose and why]

## Tradeoffs
- Pro: [benefit]
- Con: [cost]

## Impact
[affected systems, teams, timeline]

## Tags
- stack_id: JAVA_SPRING_BOOT_POSTGRES_KAFKA
- projects: [repo1, repo2]
- date: 2026-05-01
- reversible: yes|no

## References
[links to code, docs, tickets]
```

### PATTERNS/{category}/{name}.md
```markdown
# Pattern: {Name}

## Use Case
[when to use]

## Implementation
[how to implement]

## Code Snippet
```[lang]
[example code]
```

## Pros
- [benefit]

## Cons
- [tradeoff]

## Variations
[alternatives]

## Used In
- [repo1: path]
- [repo2: path]

## Tags
- stack_id: [STACK_ID]
- category: [logging|error-handling|api-design]
- reusability: high|medium|low
```

### EXECUTION/{repo-name}/current_state.json
```json
{
  "project_id": "repo-name",
  "stage": "DEV|TEST|PROD|STALLED",
  "active_module": "module-name",
  "completion": "45%",
  "last_commit": {
    "hash": "abc123",
    "message": "...",
    "date": "2026-05-01"
  },
  "pending_tasks": 12,
  "blockers": 2,
  "recent_activity": [
    {
      "type": "commit|issue|pr",
      "summary": "...",
      "date": "2026-05-01"
    }
  ],
  "next_actions": ["..."],
  "last_updated": "2026-05-01T12:00:00Z"
}
```

## Schema Compliance

**All artifacts must conform to SCHEMA.json (strict JSON schema validation).**

Decision ID format: `DECISION_<32-hex-hash>`
Pattern ID format: `PATTERN_<32-hex-hash>`
Stack ID format: `[A-Z_]+` (UPPER_SNAKE_CASE)
Project ID format: `[a-z0-9._-]+` (lowercase, no spaces)

Hashes are deterministic:
```
decision_id = hash(title + content)
pattern_id = hash(name + use_case)
```

Same input → same ID (idempotent).

---

## Validation Guarantees

Run after every operation:

```bash
/toleria validate
```

Fails if:
- Missing required fields
- Invalid field types
- Duplicate IDs (hash collision)
- Orphan artifacts (no source_projects)
- Path violations (write outside vault)
- Stack references non-existent stack
- Empty files

**Must PASS before considering the vault clean.**

---

## Usage Rules

### STRICT ENFORCEMENT:

1. **One Repo = One Project**
   - Never merge multiple repos into one project
   - Never split one repo into multiple projects
   - 1:1 mapping enforced at vault write

2. **Vault Only**
   - All writes go to ~/Documents/Vault
   - Repos are read-only
   - Never create docs inside repo

3. **No Duplication**
   - Global deduplication enforced
   - Every decision has exactly one source
   - Deduplicate before write

4. **Stack Required**
   - Every project must map to exactly one STACK_ID
   - Every decision must be tagged with stack_id
   - Missing stack = abort

5. **State Always Current**
   - EXECUTION/ synced on every run
   - last_updated always reflects reality
   - Stale data detected and refreshed

## Integration Guide

### Claude Code
```bash
# Add to ~/.claude/settings.json hooks
"toleria.scan": {
  "type": "command",
  "trigger": "on-file-save",
  "command": "/toleria sync-execution-state"
}
```

### Gemini CLI
```bash
# Add to ~/.gemini/config.yaml
hooks:
  - skill: toleria-knowledge-orchestrator
    trigger: on-repo-change
    function: sync-execution-state
```

### Copilot CLI
```bash
# Add to ~/.copilot/hooks.json
{
  "hooks": [
    {
      "skill": "toleria-knowledge-orchestrator",
      "event": "post-commit",
      "action": "sync-execution-state"
    }
  ]
}
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Claude Code | ✅ Full | Native skill support |
| Gemini CLI | ✅ Full | Via activate_skill |
| Copilot CLI | ✅ Full | Via skill tool |
| Standalone CLI | ✅ Full | Bootstrap + run scripts |

## Agent Usage

Agents invoke skill functions directly:

```
agent: "Please scan repo at /path/to/repo"
→ toleria.scan-repo /path/to/repo
→ returns: project metadata, stack detected, knowledge extracted
→ writes: ~/Documents/Vault/PROJECTS/...
```

No platform-specific logic required. Pure function invocation.

## Fail Conditions (Abort on Any)

```
- write_path != ~/Documents/Vault → ABORT
- missing stack_id → ABORT
- duplicate decision found → ABORT
- multiple projects per repo → ABORT
- repo write attempted → ABORT
- invalid metadata → ABORT
```

## Output Format (All Functions)

```json
{
  "status": "success|error",
  "function": "function-name",
  "duration_ms": 1234,
  "changes": {
    "projects_created": 1,
    "projects_updated": 2,
    "stacks_updated": 1,
    "decisions_added": 5,
    "patterns_added": 8,
    "duplicates_removed": 2
  },
  "vault_path": "~/Documents/Vault",
  "details": [],
  "errors": []
}
```

## Performance Notes

- Scan 50 projects: ~30s (parallel where possible)
- Extract decisions: ~5s per repo
- Extract patterns: ~10s per repo (code analysis)
- Deduplicate: ~2s (in-memory)
- Build index: ~1s
- Query: ~100ms (JSON index)

## Security & Privacy

- Vault is local filesystem only
- No telemetry or external calls
- Private repos stay private
- MCP integration optional (not required)
- Can work completely offline

## Future Enhancements

- [ ] Web UI for vault browsing
- [ ] IDE integration (VS Code, JetBrains)
- [ ] Knowledge graph visualization
- [ ] Automated pattern detection (ML)
- [ ] Multi-vault federation
- [ ] Team vault (encrypted sharing)

---

**Status:** Production Ready
**Last Updated:** 2026-05-01
**Maintainer:** Uday Chauhan
