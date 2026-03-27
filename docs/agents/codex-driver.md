# codex-driver

Reliable Codex CLI dispatch with flag detection, model fallback, sandbox config, output parsing, and retry logic.

## Model

sonnet

## Dispatched by

`codex` skill

## What it handles

1. Detects correct flags for the installed Codex version
2. Configures sandbox and execution mode (`--full-auto`)
3. Parses structured output from Codex
4. Retries on transient failures

## Tools

Bash, Read, Glob, Write
