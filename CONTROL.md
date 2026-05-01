# Toleria Control & Validation Framework

**How the skill prevents drift, corruption, and silent failure.**

---

## Design Principles

### 1. Determinism
Same input → Same output (always).

- Fixed schema (SCHEMA.json)
- Deterministic IDs (hash-based, not sequential)
- No free-form decisions in code
- No optional fields for core objects

### 2. Idempotency
Run 100 times → Same result.

- Overwrite or merge rules defined
- Deduplication is stable (hash-based)
- No partial updates

### 3. Atomicity
Write succeeds completely or not at all.

- Temp file → validate → rename pattern
- No corrupted/partial JSON
- Rollback on validation failure

### 4. Traceability
Everything must map: repo → project → stack → decision/pattern

- No orphan knowledge allowed
- Every artifact has source_projects
- Broken links detected immediately

### 5. Safety
Only write to ~/Documents/Vault. Period.

- Path validation before every write
- Reject writes outside vault
- No repo pollution

---

## Schema Lock (SCHEMA.json)

**All JSON files must match their schema exactly.**

```json
{
  "decision": {
    "required": ["decision_id", "stack_id", "title", "content", "source_projects"],
    "properties": {
      "decision_id": { "pattern": "^DECISION_[a-f0-9]{32}$" },
      "stack_id": { "pattern": "^[A-Z_]+$" },
      "source_projects": { "type": "array", "minItems": 1 }
    }
  }
}
```

Validate on:
- **Read** (before using)
- **Write** (before saving)
- **Scan** (before indexing)

Fail-fast on schema mismatch.

---

## ID Strategy (Deterministic)

### Decision ID
```
decision_id = "DECISION_" + hash(title + content)
```

**Properties:**
- Stable (same title/content = same ID)
- Unique (collision resistance)
- Immutable (never changes unless content changes)

Example:
```
Title: "Why PostgreSQL over MySQL?"
Content: "Scaling requirements..."
Hash: 94e1ce2a7c6b0e5a
Decision ID: DECISION_94e1ce2a7c6b0e5a
```

### Pattern ID
```
pattern_id = "PATTERN_" + hash(name + use_case)
```

Same logic as decisions.

### Stack ID
```
UPPER_SNAKE_CASE
Example: JAVA_SPRING_BOOT_POSTGRES_KAFKA
```

Generated from detected stack, never changes.

### Project ID
```
lowercase, no spaces, alphanumeric + . - _
Example: my-backend, my_app, my.project
```

Derived from repo name.

---

## Validation Pipeline

### Input Validation (On Read)
```
Read file → parse JSON → validate schema → use data
  ↓
Invalid? → ABORT, log error, skip
```

### Output Validation (On Write)
```
Generate decision/pattern → build JSON → validate schema → atomic write
  ↓
Invalid? → ABORT, keep original
```

### Scan-Time Validation
```
Scan all files → validate each → build index
  ↓
Invalid JSON? → skip with warning
Orphan found? → log and continue
```

---

## 8-Check Validation (via /toleria validate)

Run after every major operation.

### 1. Structure Check
```
Must exist:
  ~/Documents/Vault/STACKS/
  ~/Documents/Vault/PROJECTS/
  ~/Documents/Vault/DECISIONS/
  ~/Documents/Vault/PATTERNS/
  ~/Documents/Vault/EXECUTION/
  ~/Documents/Vault/INDEX/
  ~/Documents/Vault/vault.config.json
```

### 2. Schema Validation
```
FOR EACH JSON FILE:
  - Parse JSON (must be valid)
  - Match against SCHEMA.json
  - All required fields present
  - All field types correct
  - All patterns match
```

### 3. Duplication Check
```
decision_hash = hash(title + content)
IF seen_hashes[decision_hash] exists:
  FAIL (duplicate)
ELSE:
  record hash
```

### 4. Orphan Detection
```
FOR EACH decision/pattern:
  IF source_projects is empty
    FAIL (orphan)
  ELSE:
    FOR EACH project in source_projects:
      IF project doesn't exist in PROJECTS/
        FAIL (broken reference)
```

### 5. Path Violation Check
```
SCAN vault directory
FOR EACH file:
  IF NOT in allowed dirs:
    FAIL (unexpected file)
```

### 6. Stack Consistency
```
FOR EACH project:
  stack_id = project.meta.json.stack_id
  IF NOT exists STACKS/{stack_id}/stack.meta.json:
    FAIL (invalid stack reference)
```

### 7. Idempotency Check
```
Before: compute vault hash
Run skill
After: compute vault hash
IF hashes differ AND differences are unexpected:
  FAIL (non-deterministic)
```

### 8. Empty Artifact Check
```
FOR EACH .json/.md file:
  IF file_size == 0:
    FAIL (empty file)
```

---

## Validation Result

### PASS
```json
{
  "status": "PASS",
  "score": 100,
  "checks": {
    "structure": "PASS",
    "schema": "PASS (0 violations)",
    "duplication": "PASS (0 duplicates)",
    "orphans": "PASS (0 orphans)",
    "path_violations": "PASS",
    "stack_consistency": "PASS",
    "idempotency": "PASS",
    "empty_artifacts": "PASS"
  }
}
```

### FAIL
```json
{
  "status": "FAIL",
  "score": 25,
  "violations": [
    {
      "check": "schema",
      "file": "DECISIONS/DECISION_abc.json",
      "error": "missing required field: stack_id"
    }
  ],
  "must_fix": true
}
```

Exit code: 1 (stop processing until fixed)

---

## Pre-Publish Checklist

```bash
# 1. Initialize
/toleria init-vault

# 2. Scan projects
/toleria scan-all-repos ~/workspace

# 3. Extract knowledge
/toleria extract-decisions ~/workspace/my-project
/toleria extract-patterns ~/workspace/my-project

# 4. Deduplicate
/toleria deduplicate-knowledge

# 5. Build index
/toleria build-index

# 6. VALIDATE
/toleria validate

# Must output: PASS, score 100
# If FAIL: fix violations, re-validate
```

Only publish after all checks PASS.

---

## Failure Modes (What This Prevents)

| Failure | Prevention | Check |
|---|---|---|
| **Duplicate decisions** | Hash-based ID + dedup | Duplication |
| **Orphan knowledge** | source_projects required | Orphan detection |
| **Repo pollution** | Path validation | Path violations |
| **Invalid data** | Schema validation | Schema check |
| **Non-deterministic output** | Idempotency test | Idempotency |
| **Broken references** | Stack consistency | Stack consistency |
| **Silent corruption** | Snapshot/diff | Idempotency |
| **Empty artifacts** | File size check | Empty artifacts |

---

## Governance Rules

### What Happens on Violation

1. **Schema violation** → Abort, log error, skip file
2. **Orphan detected** → Log warning, flag for manual review
3. **Duplicate found** → Merge, keep one canonical version
4. **Path violation** → Abort operation, revert changes
5. **Idempotency failure** → Abort, investigate root cause
6. **Stack reference broken** → Log, mark stale link

### Who Runs Validation

- **Developers** (before commit) → `validate.sh`
- **CI/CD** (before publish) → `/toleria validate` must PASS
- **Agents** (after major operation) → auto-run optional
- **Users** (manual audit) → `/toleria health-check`

### Escalation

| Severity | Action |
|---|---|
| **Critical** (orphan, path violation) | Stop, require fix |
| **High** (schema mismatch) | Log, skip |
| **Medium** (stale stack link) | Warn, continue |
| **Low** (unused project) | Info only |

---

## Example: Safe Decision Creation

```bash
# 1. Collect info
title="Why PostgreSQL over MySQL?"
content="Scaling requirements for 1M+ users..."
project="my-backend"
stack="JAVA_SPRING_BOOT_POSTGRES"

# 2. Generate deterministic ID
decision_id="DECISION_$(hash title+content)"
# → DECISION_94e1ce2a7c6b0e5a (always same for same content)

# 3. Build JSON
{
  "decision_id": "DECISION_94e1ce2a7c6b0e5a",
  "stack_id": "JAVA_SPRING_BOOT_POSTGRES",
  "title": "Why PostgreSQL over MySQL?",
  "content": "Scaling requirements...",
  "source_projects": ["my-backend"],
  "created_at": "2026-05-01T12:00:00Z"
}

# 4. Validate schema
jq --arg schema "SCHEMA.json" '. as $data | input | ($data | . == $schema | true)' decision.json SCHEMA.json

# 5. Write atomically
temp="decision.json.tmp"
echo $json > $temp
mv $temp "DECISIONS/DECISION_94e1ce2a7c6b0e5a.json"

# 6. Validate vault
/toleria validate
# → must PASS

# 7. Index
/toleria build-index
```

Result: Deterministic, safe, traceable decision.

---

## Vault Maintenance

### Weekly
```bash
/toleria validate
```

### Monthly
```bash
/toleria deduplicate-knowledge
/toleria build-index
```

### On Change
```bash
/toleria validate
```

---

**Governance** ensures Toleria vault stays clean, deterministic, and reusable across 100+ projects.

No drift. No corruption. No surprises.
