---
id: toleria-skill-evaluator
name: Toleria Skill Evaluator
version: 1.0.0
author: Uday Chauhan
license: MIT
category: quality-assurance
description: >
  Independent validator for toleria-knowledge-orchestrator output.
  Checks determinism, idempotency, schema compliance, path safety, and orphan detection.
  Must PASS before publishing.

---

# Toleria Skill Evaluator

**Validates that toleria-knowledge-orchestrator maintains control and safety.**

## Core Checks

### 1. Structure Check
```bash
REQUIRED:
  ~/Documents/Vault/STACKS/
  ~/Documents/Vault/PROJECTS/
  ~/Documents/Vault/DECISIONS/
  ~/Documents/Vault/PATTERNS/
  ~/Documents/Vault/EXECUTION/
  ~/Documents/Vault/INDEX/
  ~/Documents/Vault/vault.config.json

RESULT: PASS/FAIL
```

### 2. Schema Validation
```bash
FOR EACH *.json FILE IN VAULT:
  - match against SCHEMA.json
  - verify all required fields
  - validate field types + patterns
  - check ID format (DECISION_*, PATTERN_*)

RESULT: PASS (0 violations) / FAIL (list violations)
```

### 3. Duplication Check
```bash
HASH(decision.title + decision.content) → must be UNIQUE
HASH(pattern.name + pattern.use_case) → must be UNIQUE

IF duplicate found:
  mark both for review
  check source_projects (should merge)

RESULT: PASS (0 duplicates) / FAIL (list duplicates)
```

### 4. Orphan Check
```bash
FOR EACH decision/pattern:
  IF source_projects is empty OR contains non-existent project
    MARK AS ORPHAN

FOR EACH project:
  IF no decision/pattern references it
    MARK AS UNUSED (not an error, just warning)

RESULT: PASS (0 orphans) / FAIL (list orphans)
```

### 5. Path Violation Check
```bash
SCAN vault directory for ANY files NOT in:
  - ~/Documents/Vault/STACKS/
  - ~/Documents/Vault/PROJECTS/
  - ~/Documents/Vault/DECISIONS/
  - ~/Documents/Vault/PATTERNS/
  - ~/Documents/Vault/EXECUTION/
  - ~/Documents/Vault/INDEX/
  - ~/Documents/Vault/vault.config.json
  - ~/Documents/Vault/README.md

RESULT: PASS (only expected files) / FAIL (list violations)
```

### 6. Stack Consistency Check
```bash
FOR EACH project.meta.json:
  IF stack_id references non-existent stack
    FAIL

FOR EACH STACKS/*/stack.meta.json:
  IF projects[] references non-existent project
    LOG WARNING (stale link)

RESULT: PASS / FAIL
```

### 7. Idempotency Check
```bash
SNAPSHOT vault state (all files + hashes)
RUN skill again
SNAPSHOT new state
DIFF snapshots

IF diff exists:
  compare against expected changes only
  IF unexpected changes found
    FAIL idempotency

RESULT: PASS (deterministic) / FAIL (drifts)
```

### 8. Empty Artifact Check
```bash
FOR EACH .json/.md file:
  IF file size == 0 bytes
    FAIL

RESULT: PASS / FAIL
```

---

## Validation Output

### PASS Result
```json
{
  "status": "PASS",
  "timestamp": "2026-05-01T12:00:00Z",
  "checks": {
    "structure": "PASS",
    "schema": "PASS (0 violations)",
    "duplication": "PASS (0 duplicates)",
    "orphans": "PASS (0 orphans)",
    "path_violations": "PASS",
    "stack_consistency": "PASS",
    "idempotency": "PASS",
    "empty_artifacts": "PASS"
  },
  "score": 100,
  "summary": "Vault is clean, deterministic, and ready for use."
}
```

### FAIL Result
```json
{
  "status": "FAIL",
  "timestamp": "2026-05-01T12:00:00Z",
  "checks": {
    "schema": "FAIL",
    "orphans": "FAIL"
  },
  "violations": [
    {
      "check": "schema",
      "file": "DECISIONS/DECISION_001.json",
      "error": "missing required field: stack_id"
    },
    {
      "check": "orphans",
      "decision_id": "DECISION_abc123",
      "error": "source_projects contains non-existent project: ghost-repo"
    }
  ],
  "score": 25,
  "must_fix_before_publish": true
}
```

---

## Usage

### Run Evaluator
```bash
/toleria eval
```

Output: JSON report + exit code (0 = PASS, 1 = FAIL)

### In CI/CD
```bash
/toleria eval || exit 1
```

Must pass before merge.

---

## Determinism Test

```bash
# Step 1: Snapshot
/toleria snapshot v1

# Step 2: Re-run skill
/toleria scan-all-repos ~/workspace

# Step 3: Snapshot again
/toleria snapshot v2

# Step 4: Compare
/toleria diff v1 v2

# Expected: ZERO DIFF
```

---

## Idempotency Test

```bash
# Step 1: Run skill
/toleria scan-all-repos ~/workspace

# Step 2: Wait 10s
sleep 10

# Step 3: Run again
/toleria scan-all-repos ~/workspace

# Expected: ZERO CHANGES
```

---

## Pre-Publish Checklist

- [ ] Structure check: PASS
- [ ] Schema validation: PASS (0 violations)
- [ ] Duplication check: PASS
- [ ] Orphan check: PASS
- [ ] Path violations: PASS
- [ ] Stack consistency: PASS
- [ ] Idempotency: PASS
- [ ] Empty artifacts: PASS
- [ ] Determinism test: PASS
- [ ] Vault contains real data: YES

**All must be PASS before publishing.**

---

## What This Prevents

| Failure Mode | Check | Prevention |
|---|---|---|
| Duplicate decisions drift | Duplication | Hash-based ID + dedup |
| Orphan knowledge | Orphan Check | Every artifact linked to ≥1 project |
| Repo pollution | Path Violation | Abort on write outside vault |
| Invalid schema | Schema Validation | Strict type checking |
| Non-deterministic output | Idempotency | Re-run produces zero diff |
| Broken references | Stack Consistency | Validate all stack/project links |
| Silent corruptions | Snapshot/Diff | Explicit before/after comparison |

---

**Version**: 1.0.0  
**Status**: Production Ready  
**Last Updated**: 2026-05-01
