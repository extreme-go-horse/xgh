---
name: xgh-test-builder
description: "Generate and run tailored test suites from architectural analysis — init to generate, run to execute"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh test-builder`. Use markdown tables for structured data. End with an italicized next step.

# /xgh-test-builder — Test Suite Generator

Run the `xgh:test-builder` skill to generate or execute a tailored test suite based on architectural analysis.

## Usage

```
/xgh-test-builder init
/xgh-test-builder run [flow-name]
```

- `init`: Analyze architecture and generate `.xgh/test-builder/manifest.yaml`
- `run [flow-name]`: Execute all flows, or a specific flow by name

`ARGUMENTS: $ARGUMENTS`
