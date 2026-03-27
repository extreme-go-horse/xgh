# opencode-driver

Reliable OpenCode CLI dispatch with command construction, model selection, output parsing, and error handling.

## Model

sonnet

## Dispatched by

`opencode` skill

## What it handles

1. Constructs correct OpenCode invocation
2. Selects appropriate model via `--model provider/name`
3. Parses output and handles errors
4. Retries on transient failures

## Tools

Bash, Read, Glob, Write
