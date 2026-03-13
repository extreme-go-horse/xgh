# xgh Curate Knowledge

Use this skill when converting implementation outcomes into durable knowledge.

## Curation Checklist

1. Capture `title`, `tags`, `keywords`, and concise problem framing.
2. Ensure YAML frontmatter exists and has `importance`, `recency`, and `maturity`.
3. Write `Raw Concept`, `Narrative`, and factual bullet points.
4. Add or update the entry through `ct-sync.sh curate`.
5. Rebuild indexes and validate search discoverability.

## Frontmatter Minimum

```yaml
---
title: Example
tags: [domain, topic]
keywords: [term]
importance: 50
recency: 1.0000
maturity: draft
---
```
