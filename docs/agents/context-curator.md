# context-curator

Classify retrieved context and store structured memories in lossless-claude workspace.

## Model

haiku

## Dispatched by

`analyze` skill

## What it does

1. Reads raw inbox items
2. Classifies content type (decision, spec_change, p0, wip, etc.)
3. Extracts structured facts
4. Stores in lossless-claude memory with appropriate metadata

## Tools

Read, Grep, Glob, Write, Edit
