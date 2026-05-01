# Performance & Importance Scoring

**Incremental updates + relevance ranking.**

---

## Problem: Full Scan Collapses at Scale

```
10 projects: ~5s
100 projects: ~50s
500 projects: ~4min
1000+ projects: TIMEOUT
```

Full scan every time = broken.

---

## Solution: Incremental Mode

```bash
/toleria scan-all-repos ~/workspace --mode=incremental
```

Only scans changed files:

```
git diff $(last_scan_commit)...HEAD --name-only
→ apply extraction only to changed files
→ merge new data with cached
→ update index
```

**Result: 1000 projects → <5s** (only changed ones scanned)

---

## Execution Modes

### Full Scan (Manual)
```bash
/toleria scan-all-repos ~/workspace --mode=full --force
```

When:
- Initial vault setup
- Major schema upgrade
- Cache corruption

Time: ~4min (100 projects)

### Incremental (Default)
```bash
/toleria scan-all-repos ~/workspace
```

Triggers:
- `git diff` changed files
- File modification (via watcher)
- Manual request (`--force`)

Time: <5s (typical)

### Watch Mode (Continuous)
```bash
/toleria scan-all-repos ~/workspace --mode=watch
```

Auto-scan on filesystem change.

---

## Importance Scoring

Every decision/pattern gets a score:

```json
{
  "decision_id": "DECISION_abc",
  "importance": "HIGH",
  "reuse_score": 87,
  "created_at": "2026-05-01",
  "last_used": "2026-05-10"
}
```

---

## Importance Levels

```
HIGH
  - >3 projects reference it
  - >6 months active
  - strategic decision (auth, db, scaling)

MEDIUM
  - 1-2 projects reference it
  - active but not critical
  - good-to-know patterns

LOW
  - single project only
  - experimental
  - candidate for removal
```

---

## Reuse Score (0-100)

```
reuse_score = (
  source_project_count * 20 +
  days_since_created / 365 * 10 +
  citation_count * 5 +
  pattern_matches * 3
) / 100

capped at 100
```

Higher = more valuable.

---

## Retrieval Priority

When querying knowledge:

```bash
/toleria query stack JAVA_SPRING --sort=importance
```

Results ordered by:
1. Importance (HIGH → LOW)
2. Reuse score (100 → 0)
3. Recency (newest first)

---

## Stale Knowledge Detection

```bash
/toleria find-stale --days=90
```

Finds:
- Decisions not referenced in >90 days
- Patterns unused in >90 days
- Projects with no recent commits

Action:
```
STALE decision → mark "ARCHIVED"
STALE pattern → move to "reference-only"
STALE project → suggest archival
```

---

## Query Optimization

Without importance:
```
/toleria query decision auth
→ 47 results (overwhelmed)
```

With importance:
```
/toleria query decision auth --sort=importance
→ Top 5: HIGH-reuse decisions first
```

---

## Performance Tuning

### Vault Size Handling

```
<100 projects: Full scan OK
100-500: Use incremental + index
500+: Must use watch mode + incremental
```

### Index Strategy

```
STALE INDEX (>1 hour old):
  - Use cached index + git diff
  
FRESH INDEX (<1 hour):
  - Full in-memory index
  
NO INDEX:
  - Force rebuild (slow, ~30s)
```

---

## Caching Strategy

```
~/.toleria/cache/
├── vault_index.json (refreshed hourly)
├── git_state.json (refreshed on git change)
└── decision_hashes.json (refreshed on dedup)
```

Cache invalidation:
```
IF git_head_changed:
  invalidate git_state
IF new_decisions_added:
  invalidate decision_hashes
IF >60min since refresh:
  full refresh
```

---

## Incremental Merge Logic

```
1. Get last scan state (last_vault_state.json)
2. Compute git diff since last scan
3. Re-extract only changed files
4. Merge new decisions with cached ones
5. Re-deduplicate (only new vs cached)
6. Update index (merge new + remove deleted)
7. Validate schema (quick check)
8. Save new state
```

**Result: 50 projects, 1 changed = <100ms**

---

## Performance Monitoring

```bash
~/Documents/Vault/INDEX/performance_log.json
```

```json
{
  "scans": [
    {
      "timestamp": "2026-05-01T12:00:00Z",
      "mode": "incremental",
      "projects_total": 150,
      "projects_changed": 3,
      "decisions_new": 2,
      "patterns_new": 1,
      "duration_ms": 235,
      "cache_hit": true
    }
  ]
}
```

---

## Scaling Rules

| Project Count | Recommended Mode | Max Latency |
|---|---|---|
| <50 | Full scan | <5s |
| 50-200 | Incremental + cache | <1s |
| 200-500 | Watch mode + incremental | <500ms |
| 500+ | Distributed (multi-vault) | <500ms each |

---

**Result: Vault scales from 10 → 1000+ projects without collapse.**
