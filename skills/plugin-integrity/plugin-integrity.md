---
name: xgh:plugin-integrity
description: Validate command/skill parity in the xgh plugin. Lists commands missing a matching skill directory and skills missing a command wrapper.
---

Check parity between `commands/` and `skills/` in the xgh plugin repo. Run from the repo root:

```bash
echo "=== Commands without a matching skill ==="
for f in commands/*.md; do
  name=$(basename "$f" .md)
  [ -d "skills/$name" ] || echo "  MISSING SKILL:   $name"
done

echo ""
echo "=== Skills without a matching command ==="
for d in skills/*/; do
  name=$(basename "$d")
  [ -f "commands/$name.md" ] || echo "  MISSING COMMAND: $name"
done
```

Present the results as two lists. If both are empty, report "All commands and skills are in parity."
