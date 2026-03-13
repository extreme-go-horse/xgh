# /xgh query

Search prior team knowledge before coding.

## Usage

`/xgh query <question>`

## Execution Steps

1. Run semantic search via `cipher_memory_search`.
2. Run keyword search via `scripts/context-tree.sh search "<question>"`.
3. Merge and summarize findings with links to affected entries.

## Output

- Top matching memories and context-tree entries.
- Confidence notes and missing-context callouts.
