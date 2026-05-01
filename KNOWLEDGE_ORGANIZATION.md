# Toleria Knowledge Organization System

Organize extracted knowledge by Projects → Topics → Notes with explicit Types.

---

## Architecture: Hierarchical Knowledge Graph

```
Projects
├── BrewPress
│   ├── Topics
│   │   ├── Architecture
│   │   │   ├── Note: Agent Orchestration (decision)
│   │   │   ├── Note: State Management (pattern)
│   │   │   └── Note: Atomic Writes (decision)
│   │   ├── Agents
│   │   │   ├── Note: WriterAgent (component)
│   │   │   ├── Note: CriticAgent (component)
│   │   │   └── Note: MediaAgent (component)
│   │   └── Tech Debt
│   │       ├── Note: Multi-language Support (tech-debt)
│   │       ├── Note: Distributed State (tech-debt)
│   │       └── Note: Rate Limiting (tech-debt)
│   └── Stack: Python_Gemini_WordPress
│
├── MyProject
│   ├── Topics
│   │   ├── Database
│   │   ├── API Design
│   │   └── Security
│   └── Stack: Node_React_PostgreSQL
│
└── AnotherProject
    └── ...
```

---

## Vault Structure (File Organization)

```
~/Documents/Vault/
├── PROJECTS/
│   ├── PROJECT_brewpress.md
│   ├── PROJECT_myproject.md
│   └── PROJECT_*.md
│
├── TOPICS/
│   ├── TOPIC_architecture.md
│   ├── TOPIC_agents.md
│   ├── TOPIC_database.md
│   └── TOPIC_*.md
│
├── NOTES/
│   ├── NOTE_decision_agent_orch.md
│   ├── NOTE_pattern_draft_first.md
│   ├── NOTE_component_writer_agent.md
│   ├── NOTE_techdebt_multilang.md
│   └── NOTE_*.md
│
├── DECISIONS/
│   ├── DECISION_*.md (20+ items)
│   └── (auto-organized by project/topic via frontmatter)
│
├── PATTERNS/
│   ├── PATTERN_*.md (15+ items)
│   └── (auto-organized by project/topic via frontmatter)
│
├── EXECUTION/ (Tech Debt)
│   ├── TECHDEBT_*.md (5+ items)
│   └── (auto-organized by project/topic via frontmatter)
│
├── STACKS/
│   ├── STACK_python_gemini.md
│   ├── STACK_node_react.md
│   └── STACK_*.md
│
├── INDEX/
│   ├── decisions.json        ← All decisions, queryable
│   ├── patterns.json         ← All patterns, queryable
│   ├── projects.json         ← All projects, queryable
│   ├── topics.json           ← All topics, queryable
│   └── graph.json            ← Full knowledge graph
│
└── INBOX/
    └── (new items before classification)
```

---

## Metadata: Frontmatter Schema

Every note has frontmatter that ties it to projects, topics, types:

### Project Entry

```markdown
---
id: PROJECT_brewpress
type: project
name: BrewPress
description: Blog generation + WordPress publishing
repo: ~/workspace/developerscoffee.com/src/brewpress
status: active
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---

# BrewPress

Blog generation platform using Gemini AI + WordPress REST API.
```

### Topic Entry

```markdown
---
id: TOPIC_architecture
type: topic
name: Architecture
project: brewpress
description: System design and architectural patterns
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---

# Architecture

Design decisions, patterns, and components.
```

### Decision Note

```markdown
---
id: DECISION_bf8e40
type: decision
title: Use atomic writes for state persistence
project: brewpress
topic: architecture
stack: Python_Gemini_WordPress
status: active
links:
  - {id: "TOPIC_architecture", title: "Architecture"}
  - {id: "PROJECT_brewpress", title: "BrewPress"}
tags: ["state-management", "persistence", "atomic"]
created_at: 2026-05-01T11:13:24Z
updated_at: 2026-05-01T11:13:24Z
---

# Decision: Use atomic writes (temp file + os.rename) for state persistence

Context: BrewPress state is single-file (last_draft.json). Process can be killed mid-operation.

Rationale: os.rename is atomic on POSIX. Guarantees state never corrupted.

Details: StateStore.save() writes to .tmp file, fsync(), then atomic rename.
```

### Pattern Note

```markdown
---
id: PATTERN_tool_first
type: pattern
title: Tools run first, LLM only when needed
project: brewpress
topic: architecture
stack: Python_Gemini_WordPress
status: active
links:
  - {id: "TOPIC_architecture", title: "Architecture"}
  - {id: "PROJECT_brewpress", title: "BrewPress"}
tags: ["optimization", "cost", "latency"]
created_at: 2026-05-01T11:13:24Z
updated_at: 2026-05-01T11:13:24Z
---

# Pattern: Tools run first, LLM only when needed

Evidence: SEO agent runs seo.full tool first. If passed, returns pass without LLM.
```

### Component Note

```markdown
---
id: NOTE_component_writer_agent
type: component
title: WriterAgent
project: brewpress
topic: agents
description: Generates blog post body from diff/topic
links:
  - {id: "TOPIC_agents", title: "Agents"}
  - {id: "PROJECT_brewpress", title: "BrewPress"}
tags: ["agent", "generation", "creative"]
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---

# WriterAgent

Generates blog post body from diff and/or topic.

Input: BlogJob with diff_path, topic, notes
Output: job.draft_body_md (Markdown)
```

### Tech Debt Note

```markdown
---
id: TECHDEBT_multilang
type: tech-debt
title: Multi-language support
project: brewpress
topic: future-work
priority: high
effort: high
status: blocked
links:
  - {id: "PROJECT_brewpress", title: "BrewPress"}
tags: ["i18n", "globalization", "future"]
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-01T00:00:00Z
---

# Tech Debt: Multi-language blog generation

Current: English only. Prompts hardcoded for English.

Issue: Global audience needs non-English content.

Effort: High (every agent skill file needs language parameter)

Blocker: Language param must thread through entire pipeline.
```

---

## Type System

### Core Types

| Type | Purpose | Count | Example |
|------|---------|-------|---------|
| **decision** | Architectural choice | 20+ | "Use atomic writes", "Agent-based orchestration" |
| **pattern** | Proven approach | 15+ | "Tool-first", "Draft-first", "Critic loop" |
| **component** | Technical building block | 10+ | "WriterAgent", "StateStore", "WordPressClient" |
| **tech-debt** | Known issues | 5+ | "Multi-language", "Distributed state", "Rate limiting" |
| **project** | Repository/product | 1+ | "BrewPress", "MyProject" |
| **topic** | Theme/area | 5+ | "Architecture", "Agents", "Database" |
| **stack** | Technology stack | 1+ | "Python_Gemini_WordPress" |

### Custom Types (Optional)

- **requirement** — Functional requirement
- **risk** — Risk assessment
- **opportunity** — Growth/improvement opportunity
- **question** — Open question for research
- **experiment** — Proposed experiment
- **postmortem** — Incident analysis

---

## Querying: Find Knowledge by Project/Topic

### Query all decisions for BrewPress

```bash
jq '.[] | select(.project=="brewpress" and .type=="decision")' \
  ~/Documents/Vault/INDEX/decisions.json
```

### Query all patterns in Architecture topic

```bash
jq '.[] | select(.topic=="architecture" and .type=="pattern")' \
  ~/Documents/Vault/INDEX/patterns.json
```

### List all topics for a project

```bash
jq '.[] | select(.project=="brewpress" and .type=="topic") | .name' \
  ~/Documents/Vault/INDEX/graph.json
```

### Find tech debt by priority

```bash
jq '.[] | select(.type=="tech-debt" and .priority=="high")' \
  ~/Documents/Vault/INDEX/graph.json
```

### Get all notes linked to Architecture topic

```bash
jq '.[] | select(.links[].id=="TOPIC_architecture")' \
  ~/Documents/Vault/INDEX/graph.json
```

---

## Organization Workflows

### Workflow 1: Extract → Organize → Link

```bash
# 1. Extract from codebase
/toleria-digital-twin --repo ~/workspace/brewpress

# 2. Classify into projects/topics
# (manual or via automation)
# vault.write adds project + topic to frontmatter

# 3. Link related items
vault.link DECISION_xyz TOPIC_architecture PROJECT_brewpress

# 4. Index for querying
vault.index ~/Documents/Vault
```

### Workflow 2: Browse by Project

```bash
# List all projects
jq '.[] | select(.type=="project") | .name' \
  ~/Documents/Vault/INDEX/graph.json

# Get project details
jq '.[] | select(.id=="PROJECT_brewpress")' \
  ~/Documents/Vault/INDEX/graph.json

# List all topics in project
jq '.[] | select(.project=="brewpress" and .type=="topic")' \
  ~/Documents/Vault/INDEX/graph.json

# List all decisions in project/topic
jq '.[] | select(.project=="brewpress" and .topic=="architecture" and .type=="decision")' \
  ~/Documents/Vault/INDEX/graph.json
```

### Workflow 3: Generate Documentation by Project

```bash
#!/bin/bash
PROJECT="brewpress"

# Create docs/ARCHITECTURE.md
cat > docs/ARCHITECTURE.md << 'EOF'
# BrewPress Architecture

EOF

# Add decisions
echo "## Architectural Decisions" >> docs/ARCHITECTURE.md
jq -r '.[] | select(.project=="'$PROJECT'" and .type=="decision") | "### \(.title)\n\(.description)\n"' \
  ~/Documents/Vault/INDEX/graph.json >> docs/ARCHITECTURE.md

# Add patterns
echo "## Design Patterns" >> docs/ARCHITECTURE.md
jq -r '.[] | select(.project=="'$PROJECT'" and .type=="pattern") | "### \(.title)\n\(.description)\n"' \
  ~/Documents/Vault/INDEX/graph.json >> docs/ARCHITECTURE.md

# Add tech debt
echo "## Tech Debt" >> docs/ARCHITECTURE.md
jq -r '.[] | select(.project=="'$PROJECT'" and .type=="tech-debt") | "### \(.title)\n\(.description)\n"' \
  ~/Documents/Vault/INDEX/graph.json >> docs/ARCHITECTURE.md
```

---

## Index: Full Knowledge Graph

Generate comprehensive `graph.json` with all relationships:

```json
{
  "projects": [
    {
      "id": "PROJECT_brewpress",
      "type": "project",
      "name": "BrewPress",
      "repo": "~/workspace/developerscoffee.com/src/brewpress",
      "topics": ["architecture", "agents", "state-management"],
      "decision_count": 8,
      "pattern_count": 5,
      "techdebt_count": 5
    }
  ],
  "topics": [
    {
      "id": "TOPIC_architecture",
      "type": "topic",
      "name": "Architecture",
      "project": "brewpress",
      "decisions": ["DECISION_bf8e40", "DECISION_a80edb", ...],
      "patterns": ["PATTERN_tool_first", "PATTERN_draft_first", ...],
      "components": ["NOTE_component_orchestrator", ...]
    }
  ],
  "decisions": [...],
  "patterns": [...],
  "components": [...],
  "techdebt": [...],
  "links": [
    {
      "from": "DECISION_bf8e40",
      "to": "TOPIC_architecture",
      "type": "belongs_to"
    },
    {
      "from": "DECISION_bf8e40",
      "to": "PROJECT_brewpress",
      "type": "belongs_to"
    }
  ]
}
```

---

## Create Project

### Step 1: Extract knowledge from codebase

```bash
/toleria-digital-twin --repo ~/workspace/my-project
```

### Step 2: Create project entry

```bash
vault.write "PROJECTS/PROJECT_myproject.md" '{
  "id": "PROJECT_myproject",
  "type": "project",
  "name": "My Project",
  "repo": "~/workspace/my-project",
  "status": "active",
  "created_at": "2026-05-01T00:00:00Z",
  "updated_at": "2026-05-01T00:00:00Z"
}' "# My Project

Description here."
```

### Step 3: Create topic entries

```bash
vault.write "TOPICS/TOPIC_architecture.md" '{
  "id": "TOPIC_architecture",
  "type": "topic",
  "name": "Architecture",
  "project": "myproject",
  "created_at": "2026-05-01T00:00:00Z",
  "updated_at": "2026-05-01T00:00:00Z"
}' "# Architecture

System design and architectural patterns."
```

### Step 4: Link knowledge to project/topic

```bash
vault.link DECISION_xyz PROJECT_myproject TOPIC_architecture
```

### Step 5: Index

```bash
vault.index ~/Documents/Vault
```

### Step 6: Query

```bash
jq '.[] | select(.project=="myproject")' ~/Documents/Vault/INDEX/graph.json
```

---

## UI Integration (Tolaria/Obsidian)

**Left sidebar structure:**

```
VIEWS
├── Projects (1)
├── Topics (5)
├── Notes (40)
├── Types
│   ├── decisions (24)
│   ├── patterns (22)
│   ├── components (12)
│   ├── tech-debt (5)
│   └── others (21)

FOLDERS
├── vault/
│   ├── PROJECTS/       (project entries)
│   ├── TOPICS/         (topic entries)
│   ├── NOTES/          (all notes organized by project/topic)
│   ├── DECISIONS/      (auto-organized decisions)
│   ├── PATTERNS/       (auto-organized patterns)
│   ├── EXECUTION/      (auto-organized tech debt)
│   ├── INBOX/          (new items)
│   └── INDEX/          (JSON indexes)
```

**Right panel (backlinks):**

Shows which projects/topics link to current note. Enables navigation:

```
BrewPress Project
  └─ Architecture Topic
      ├─ DECISION_bf8e40
      ├─ PATTERN_tool_first
      └─ NOTE_component_orchestrator
```

---

## Automation: Extract & Organize

Create automation to assign project/topic on extraction:

```bash
#!/bin/bash
# extract-and-organize.sh

REPO_PATH="$1"
PROJECT_NAME=$(basename "$REPO_PATH")
PROJECT_ID="PROJECT_$(echo $PROJECT_NAME | tr a-z A-Z)"

# Extract
/toleria-digital-twin --repo "$REPO_PATH"

# Add project to all newly extracted items
while IFS= read -r file; do
  # Read item
  item=$(vault.read "$file")
  
  # Add project field
  item_with_project=$(echo "$item" | jq ".frontmatter.project=\"${PROJECT_NAME}\"")
  
  # Auto-assign topic based on content
  topic=$(infer_topic_from_content "$item")
  item_with_topic=$(echo "$item_with_project" | jq ".frontmatter.topic=\"${topic}\"")
  
  # Write back
  vault.write "$file" "$(echo $item_with_topic | jq .frontmatter)" "$(echo $item_with_topic | jq -r .content)"
done < <(find ~/Documents/Vault/DECISIONS -type f -name "*.md" -newer "$LAST_EXTRACT")

# Index
vault.index ~/Documents/Vault
```

---

## Success Metrics

- ✓ All knowledge organized by project
- ✓ Topics group related knowledge
- ✓ Types enable filtering (decisions vs patterns vs tech-debt)
- ✓ Backlinks enable navigation
- ✓ Queries return filtered, sorted results
- ✓ Documentation auto-generated per project
- ✓ Knowledge graph is traversable

---

**Status:** Ready to implement.

Next: Add project/topic management to digital twin skill.
