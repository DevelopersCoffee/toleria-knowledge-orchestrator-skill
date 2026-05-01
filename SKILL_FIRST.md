# Skill-First Mandate

**Toleria skill is the execution engine. MCP is fallback only.**

---

## Rule

```
IF operation_in_skill:
  MUST use skill
  FORBID MCP
ELSE IF operation_not_in_skill:
  OPTIONAL MCP
  REQUIRED: normalize + re-validate before write
ELSE IF both_possible:
  MUST prefer skill
```

---

## Why

| Layer | Property | Skill | MCP |
|-------|----------|-------|-----|
| **Determinism** | Same input = same output | ✅ Enforced | ❌ Flexible |
| **Validation** | Schema lock | ✅ Strict | ❌ Optional |
| **Atomicity** | All-or-nothing writes | ✅ Guaranteed | ❌ Possible fail |
| **Idempotency** | Rerun = same result | ✅ Verified | ❌ Not guaranteed |
| **Traceability** | Source tracking | ✅ Enforced | ❌ Optional |

Mixing = drift.

---

## Skill Coverage (Mandatory)

```
[SKILL COVERAGE]

✅ init-vault
✅ scan-repo / scan-all-repos
✅ extract-decisions / extract-patterns
✅ identify-stack
✅ sync-execution-state
✅ deduplicate-knowledge
✅ build-index
✅ validate
✅ health-check
✅ migrate-schema
✅ resolve-conflict
✅ query-knowledge
✅ publish-stack
✅ archive-project

If any missing → expand skill, don't use MCP fallback.
```

---

## MCP Fallback (Rare)

Only allowed for:

```
1. External data fetch (GitHub API, cloud services)
2. UI operations (open note, highlight, set filter)
3. Agent-specific features (Claude Code edits, reasoning blocks)

NOT allowed for:
- write / update / delete vault files
- schema modifications
- deduplication logic
- project state changes
```

---

## MCP Guard Rules

```yaml
IF operation == write AND path.startswith("~/Documents/Vault"):
  MUST use skill
  MUST NOT use MCP
  ENFORCE: abort if MCP attempted

IF MCP used for data fetch:
  REQUIRED: normalize to skill schema
  REQUIRED: re-validate before write
  REQUIRED: log fallback event
```

---

## Fallback Tracking

```bash
~/Documents/Vault/INDEX/fallback_log.json
```

```json
{
  "timestamp": "2026-05-01T12:00:00Z",
  "fallback_events": [
    {
      "operation": "fetch_github_issues",
      "reason": "external_dependency",
      "resolved": true,
      "escalation": false
    },
    {
      "operation": "update_execution_state",
      "reason": "mcp_attempted_vault_write",
      "resolved": false,
      "escalation": true,
      "error": "BLOCKED: use skill instead"
    }
  ]
}
```

---

## Self-Improvement Loop

```bash
if fallback_count(operation) > 3:
  create_task:
    priority: HIGH
    action: "Extend skill to support {operation}"
    reason: "MCP fallback used {N} times"
```

---

## System Prompt

```yaml
INSTRUCTION:

- Always attempt skill execution first
- Never use MCP for structured writes to vault
- Normalize all MCP outputs before storage
- Treat MCP as temporary bridge, not system layer
- Log every fallback event
- Escalate if MCP prevents skill execution
```

---

## Enforcement

### During Development

```bash
/toleria validate
# Must PASS with zero MCP fallbacks
```

### During Publishing

```bash
/toleria health-check
# Check fallback_log for escalations
# If any escalation: CANNOT PUBLISH
```

### During Operation

Agent monitors `fallback_log.json`:
```
if escalation_count > 0:
  alert("Skill coverage gap detected")
  suggest("Extend skill to reduce MCP usage")
```

---

## Migration: Old MCP Workflows → Skill

### Before (MCP-heavy)
```
Agent: Update project state
→ MCP: edit file
→ Manual validation
→ Manual schema fix
→ Possible drift
```

### After (Skill-first)
```
Agent: Update project state
→ Skill: sync-execution-state
→ Auto validation
→ Auto schema compliance
→ Zero drift
```

---

## Access Control via Skill

MCP cannot:
- Write directly to vault
- Modify schema
- Run deduplication

MCP can (with restrictions):
- Read public knowledge
- Fetch external data
- Trigger UI actions
- Normalize and pass to skill

---

**Result: Vault integrity preserved. System stays deterministic.**

**Skill is the source of truth. MCP is the adapter.**
