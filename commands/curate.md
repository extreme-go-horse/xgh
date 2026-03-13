# /xgh curate

Capture durable knowledge from implementation outcomes.

## Usage

`/xgh curate --domain <domain> --topic <topic> --title <title> --content <notes>`

## Execution Steps

1. Store session learning via `cipher_extract_and_operate_memory`.
2. Persist markdown knowledge via `scripts/ct-sync.sh curate`.
3. Rebuild manifest and indexes.
4. Confirm retrieval through a follow-up search.

## Required Metadata

- title
- domain/topic
- frontmatter quality fields (`importance`, `recency`, `maturity`)
