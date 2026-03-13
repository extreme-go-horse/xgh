# xgh Continuous Learning

This skill enforces the xgh iron law:

1. Before writing code, run `cipher_memory_search` and inspect related context-tree entries.
2. During implementation, verify conventions and architecture constraints.
3. After significant changes, run `cipher_extract_and_operate_memory` to store learnings.
4. For architecture decisions, store rationale with `cipher_store_reasoning_memory`.

## Required Checks

- Confirm at least one memory query happened before code edits.
- Confirm curation happened after major changes.
- Confirm reasoning memories were stored for non-trivial decisions.

## Failure Pattern

If a session produced code but no memory updates, the loop is incomplete and must be corrected before closure.
