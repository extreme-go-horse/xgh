# xgh PR Context Bridge

Use this skill to preserve reasoning from pull request work.

## Goal

Bridge pull request discussions and implementation decisions into durable memory.

## Procedure

1. Extract problem statement, alternatives, and chosen approach from PR timeline.
2. Curate the rationale via `cipher_extract_and_operate_memory`.
3. Store a context-tree entry that references the pull request and changed files.
4. Add verification notes for tests and rollout risks.

This keeps pull request knowledge reusable in future sessions.
