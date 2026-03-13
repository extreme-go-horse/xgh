# xgh Memory Verification

Validate that newly curated knowledge is retrievable and correctly ranked.

## Verification Workflow

1. Query by exact title keywords and expect the entry in top 5.
2. Query by natural language paraphrase and expect the entry in top 5.
3. Confirm file exists in context tree and metadata is present.
4. Confirm `_manifest.json` includes the entry path.
5. Confirm maturity and importance reflect expected state.

## Acceptance

A curation is complete only when retrieval works through both exact and semantic-style queries.
