# analyze

Classify inbox items, extract structured memories, and generate daily digests.

## When it runs

- **Automatically:** Every 30 minutes via scheduler
- **On demand:** `/xgh-analyze`

## What it does

1. Checks token cap and quiet hours
2. Reads unprocessed items from `~/.xgh/inbox/`
3. For each item:
   - Classifies content type (decision, spec_change, p0, wip, awaiting_reply, etc.)
   - Scores urgency using keyword matching and relevance weighting
   - Extracts structured memories into lossless-claude workspace
   - Deduplicates against existing memories (threshold: 0.85)
4. Generates daily digest in `~/.xgh/digests/`
5. Moves processed items to `~/.xgh/inbox/processed/`

## Model

sonnet (needs classification ability)

## Configuration

- `analyzer.max_inbox_items`: Max items per run (default: 50)
- `analyzer.dedup_threshold`: Similarity threshold (default: 0.85, tune via `/xgh-calibrate`)
- `analyzer.min_urgency_to_store`: Minimum urgency to store (default: 10)
- `analyzer.max_memories_per_run`: Max memories extracted (default: 30)
