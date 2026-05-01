# Conflict Resolution Strategy

**When two decisions or patterns are semantically similar but not identical.**

---

## Conflict Detection

Triggered when:

```
hash(title_1) != hash(title_2)
BUT
semantic_similarity(content_1, content_2) > 0.85
```

Example:
```
Decision 1: "PostgreSQL vs MySQL for scaling"
Decision 2: "Why we chose PostgreSQL"

Content similar → Conflict
```

---

## Resolution Rules

### Strategy: Merge Prefer Richer

```
IF decision_1.content.length > decision_2.content.length:
  keep = decision_1
  merge_from = decision_2
ELSE:
  keep = decision_2
  merge_from = decision_1
```

**Result:**
```json
{
  "decision_id": keep.id,
  "title": keep.title,
  "content": keep.content + " [See also: " + merge_from.id + "]",
  "merged_from": [merge_from.id],
  "source_projects": [...keep, ...merge_from]
}
```

Delete `merge_from` decision.

---

### Strategy: Merge Prefer Recent

```
IF decision_1.last_updated > decision_2.last_updated:
  keep = decision_1
  merge_from = decision_2
ELSE:
  keep = decision_2
  merge_from = decision_1
```

---

### Strategy: Mark Conflict

```
conflict = {
  "decision_1": id_1,
  "decision_2": id_2,
  "reason": "similar content",
  "similarity_score": 0.87,
  "action": "REQUIRES_MANUAL_REVIEW"
}
```

Manual resolution required.

---

## Conflict Log

```bash
~/Documents/Vault/INDEX/conflicts.json
```

```json
{
  "timestamp": "2026-05-01T12:00:00Z",
  "conflicts": [
    {
      "decision_1": "DECISION_abc",
      "decision_2": "DECISION_def",
      "similarity": 0.87,
      "source_projects_1": ["repo1"],
      "source_projects_2": ["repo2"],
      "resolved": true,
      "resolution": "merge_prefer_richer",
      "result_id": "DECISION_abc"
    }
  ]
}
```

---

## Manual Resolution

If auto-resolution fails:

```bash
/toleria resolve-conflict DECISION_abc DECISION_def
```

Interactive menu:
```
1. Keep DECISION_abc (add tradeoffs from DECISION_def)
2. Keep DECISION_def (add context from DECISION_abc)
3. Merge manually (edit combined version)
4. Keep separate (different angles, both valid)
5. Delete one (mark as obsolete)
```

---

## Pattern Conflict Resolution

Same rules apply to patterns:

```
pattern_1: "Structured logging in JSON"
pattern_2: "JSON-based logging strategy"

Similarity > 0.85 → Conflict detected
```

---

## What NOT to Merge

Some decisions should stay separate:

```
Decision 1: "Auth strategy for mobile app"
Decision 2: "Auth strategy for web app"

Similarity: 0.80 (below threshold)
Result: Keep separate
```

---

## Conflict Prevention

Design to avoid conflicts:

```yaml
decision_title:
  pattern: "{context}: {choice}"
  examples:
    - "Payment processing: Stripe over Square"
    - "Database: PostgreSQL for scaling"
    - "Caching: Redis for session store"

Specific titles = fewer semantic collisions
```

---

## Escalation

Conflicts with:
```
similarity > 0.95 → AUTO MERGE
similarity 0.85-0.95 → MERGE_PREFER_RICHER (log)
similarity 0.75-0.85 → MARK_CONFLICT (require review)
similarity < 0.75 → KEEP_SEPARATE
```

---

**Result: One canonical decision per concept, multiple source projects linked.**
