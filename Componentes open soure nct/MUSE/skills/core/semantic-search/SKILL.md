---
name: semantic-search
description: Zero-dependency TF-IDF search across MUSE memory, roles, and skills. Use when user wants to find information across their project context.
version: 1.0.0
author: muse
tags: [core, search, memory, context]
---

# Semantic Search

Search across your entire MUSE project context using TF-IDF ranking.

## When to Use

- User asks "where did we discuss X?"
- User wants to find a past decision or lesson
- User needs to locate a specific skill
- Context recovery when resuming work

## Usage

```bash
# Search everything
./scripts/search.sh "auth jwt oauth"

# Search only memory files
./scripts/search.sh "database migration" --scope memory

# Search only role files
./scripts/search.sh "dashboard" --scope roles --top 3

# Search only skills
./scripts/search.sh "testing" --scope skills --top 10
```

## How It Works

1. **Tokenization**: Query is split into lowercase terms
2. **TF (Term Frequency)**: For each file, count occurrences of each query term, normalized by file length
3. **IDF (Inverse Document Frequency)**: Terms that appear in fewer files get higher weight
4. **Score**: TF × IDF summed across all query terms
5. **Ranking**: Files sorted by score, top N shown with best-matching line as context snippet

## Scopes

| Scope | Files Indexed |
|-------|--------------|
| `all` (default) | memory/ + .muse/ + MEMORIES.md + skills/ |
| `memory` | memory/*.md + MEMORIES.md |
| `roles` | .muse/*.md |
| `skills` | skills/**/SKILL.md + .agent/skills/**/SKILL.md |

## Integration

When resuming a conversation, you can use search to quickly find relevant context:

```bash
# Before /resume — find what was done last week
./scripts/search.sh "migration deploy" --scope memory --top 3
```

## Limitations

- Pure TF-IDF, no semantic understanding (no embeddings/vectors)
- Exact term matching only (no synonyms)
- Best for keyword-based queries with specific terms
- For semantic search, consider integrating with mem0 or memsearch
