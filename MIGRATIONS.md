# Schema Migrations & Evolution

**How to safely evolve vault schema without breaking old data.**

---

## Versioning Rule

Every decision/pattern/project carries schema version:

```json
{
  "decision_id": "DECISION_abc123",
  "schema_version": "1.0.0",
  "data": { ... }
}
```

On read:
```
IF schema_version != current:
  apply migration
  rewrite file to new schema
```

---

## Migration Chain

```yaml
1.0.0 → 1.1.0 → 1.2.0 → 2.0.0
```

Each step is reversible.

---

## Migration File Format

```bash
MIGRATIONS/
├── 001_v1_0_0_to_v1_1_0.sh
├── 002_v1_1_0_to_v1_2_0.sh
└── 003_v2_0_0_schema_refactor.sh
```

Each migration:
- Names field changes clearly
- Handles missing fields (default values)
- Is idempotent (rerun = no change)
- Validates output

---

## Example: Add `importance` Field

### Before (v1.0.0)
```json
{
  "decision_id": "DECISION_abc",
  "title": "Why PostgreSQL?",
  "stack_id": "JAVA_SPRING"
}
```

### After (v1.1.0)
```json
{
  "decision_id": "DECISION_abc",
  "title": "Why PostgreSQL?",
  "stack_id": "JAVA_SPRING",
  "importance": "HIGH",
  "schema_version": "1.1.0"
}
```

### Migration Script
```bash
#!/bin/bash
# 001_add_importance_field.sh

VAULT_ROOT="${1:?Vault root required}"

for file in $(find "$VAULT_ROOT/DECISIONS" -name "*.json"); do
  # Add importance field if missing
  if ! jq -e '.importance' "$file" >/dev/null 2>&1; then
    jq '.importance = "MEDIUM" | .schema_version = "1.1.0"' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
    echo "Migrated: $(basename $file)"
  fi
done
```

---

## Running Migrations

```bash
/toleria migrate-schema [from-version] [to-version]
```

Example:
```bash
/toleria migrate-schema 1.0.0 1.1.0
```

Steps:
1. Create backup: `vault_backup_1.0.0/`
2. Run migration script
3. Validate schema
4. If FAIL → restore backup
5. If PASS → update vault.config.json

---

## Rollback

```bash
/toleria rollback 1.1.0
```

Restores to previous snapshot.

---

## Migration Checklist

Before deploying a schema change:

- [ ] Write migration script (reversible)
- [ ] Test on copy of real vault
- [ ] Validate output matches new schema
- [ ] Rollback test (restore backup, verify)
- [ ] Performance test (timing on 1000+ files)
- [ ] Document changes in CHANGELOG
- [ ] Update SCHEMA.json
- [ ] Bump schema_version in vault.config.json

---

## What Happens Without Migrations

```
v1.0.0 schema
    ↓ (add field to v1.1.0)
v1.1.0 schema
    ↓ (old code reads without migration)
CRASH or SILENT DATA LOSS
```

This is non-recoverable.

---

## Backwards Compatibility

**Don't break old schemas.**

```yaml
v1.0.0:
  - title (required)
  - content (required)

v1.1.0:
  - title (required)
  - content (required)
  - importance (optional, default="MEDIUM")
```

v1.1.0 code can read v1.0.0 files. ✓

---

## Semantic Versioning

```
MAJOR.MINOR.PATCH

1.0.0 → 1.1.0  (add optional field)
1.1.0 → 2.0.0  (breaking change, requires migration)
1.1.0 → 1.1.1  (bugfix, no schema change)
```

---

## Current State

Vault schema version: **1.0.0** (see `vault.config.json`)

Migration support: Ready (framework in place)

---

**Before publishing any schema change, run migrations + validation.**

**No silent data loss allowed.**
