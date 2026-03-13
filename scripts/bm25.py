#!/usr/bin/env python3
"""Lightweight BM25 search over markdown files in the xgh context tree."""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import re
from collections import Counter

TOKEN_RE = re.compile(r"[a-z0-9]+")


def tokenize(text: str) -> list[str]:
    return TOKEN_RE.findall(text.lower())


def parse_title(lines: list[str], fallback: str) -> str:
    if len(lines) >= 3 and lines[0].strip() == "---":
        for line in lines[1:]:
            if line.strip() == "---":
                break
            if line.strip().startswith("title:"):
                return line.split(":", 1)[1].strip().strip('"').strip("'") or fallback
    return fallback


def load_docs(root: pathlib.Path) -> list[dict]:
    docs = []
    for path in root.rglob("*.md"):
        rel = path.relative_to(root).as_posix()
        if rel.startswith("_archived/"):
            continue
        if path.name == "_index.md":
            continue

        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        title = parse_title(lines, path.stem)
        tokens = tokenize(text)

        docs.append(
            {
                "path": rel,
                "title": title,
                "text": text,
                "tokens": tokens,
                "length": max(len(tokens), 1),
            }
        )

    return docs


def bm25_search(query: str, docs: list[dict], top: int) -> list[dict]:
    if not docs:
        return []

    query_terms = tokenize(query)
    if not query_terms:
        return []

    avgdl = sum(doc["length"] for doc in docs) / len(docs)
    k1 = 1.5
    b = 0.75

    doc_freq: dict[str, int] = {}
    for term in query_terms:
        doc_freq[term] = sum(1 for doc in docs if term in set(doc["tokens"]))

    scored = []
    for doc in docs:
        tf = Counter(doc["tokens"])
        score = 0.0
        for term in query_terms:
            freq = tf.get(term, 0)
            if freq == 0:
                continue

            df = doc_freq.get(term, 0)
            idf = math.log(1.0 + (len(docs) - df + 0.5) / (df + 0.5))
            denom = freq + k1 * (1.0 - b + b * doc["length"] / avgdl)
            score += idf * (freq * (k1 + 1.0)) / denom

        if score <= 0:
            continue

        snippet = doc["text"][:180].replace("\n", " ").strip()
        scored.append(
            {
                "path": doc["path"],
                "title": doc["title"],
                "score": round(score, 6),
                "snippet": snippet,
            }
        )

    scored.sort(key=lambda item: item["score"], reverse=True)
    return scored[:top]


def main() -> int:
    parser = argparse.ArgumentParser(description="BM25 search for xgh context tree")
    parser.add_argument("query", help="search query")
    parser.add_argument("--root", default=".xgh/context-tree", help="context tree root")
    parser.add_argument("--top", type=int, default=10, help="number of results")
    args = parser.parse_args()

    root = pathlib.Path(args.root)
    root.mkdir(parents=True, exist_ok=True)

    docs = load_docs(root)
    results = bm25_search(args.query, docs, args.top)
    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
