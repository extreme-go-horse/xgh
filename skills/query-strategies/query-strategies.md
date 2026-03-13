# xgh Query Strategies

Use a tiered query approach for high recall and precision.

## Strategy

1. Start with semantic memory using `cipher_memory_search` for similar past work.
2. Run keyword retrieval on the context tree with `context-tree.sh search`.
3. Merge insights and resolve conflicts before coding.
4. Re-run queries after implementation if architecture changed.

## Query Types

- Semantic query: natural language problem statement.
- Structural query: exact subsystem terms and file paths.
- Hybrid query: semantic + exact keywords for ambiguous domains.

This strategy balances semantic recall and deterministic keyword matching.
