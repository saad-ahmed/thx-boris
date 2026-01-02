# Hook Patterns

Configuration examples for Claude Code hooks. Add to `.claude/settings.json`.

---

## Understanding Hooks

Hooks are commands that run automatically at specific points in Claude's workflow.

### Hook Types

| Type | When | Use Case |
|------|------|----------|
| `PreToolUse` | Before Claude runs a tool | Validation, preparation |
| `PostToolUse` | After Claude runs a tool | Formatting, verification |

### Matcher Syntax

```
Write           - Matches Write tool
Edit            - Matches Edit tool  
Write|Edit      - Matches Write OR Edit
Bash(git *)     - Matches Bash with git commands
Bash(npm run *) - Matches Bash with npm run commands
*               - Matches everything (use carefully)
```

---

## PostToolUse Patterns

### Auto-Format on File Changes

Most common pattern. Runs formatter after any file write/edit.

**Bun/npm:**
```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "bun run format || true"
    }]
  }]
}
```

**Prettier directly:**
```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "npx prettier --write . || true"
    }]
  }]
}
```

**Python (black + isort):**
```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "black . && isort . || true"
    }]
  }]
}
```

### Auto-Lint After Changes

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "bun run lint:file -- \"$CHANGED_FILE\" || true"
    }]
  }]
}
```

### Run Tests After Implementation Files

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "if [[ ! \"$FILE\" =~ \\.test\\. ]]; then bun run test:file -- \"${FILE%.ts}.test.ts\" || true; fi"
    }]
  }]
}
```

---

## PreToolUse Patterns

### Validate Before Commit

Ensure all checks pass before allowing commit:

```json
{
  "PreToolUse": [{
    "matcher": "Bash(git commit*)",
    "hooks": [{
      "type": "command",
      "command": "bun run lint:claude && bun run typecheck && bun run test"
    }]
  }]
}
```

### Require Test Existence Before Commit

```json
{
  "PreToolUse": [{
    "matcher": "Bash(git commit*)",
    "hooks": [{
      "type": "command", 
      "command": "git diff --cached --name-only | grep -E '\\.(ts|tsx)$' | grep -v '\\.test\\.' | while read f; do test -f \"${f%.ts}.test.ts\" || (echo \"Missing test for $f\" && exit 1); done"
    }]
  }]
}
```

### Backup Before Destructive Operations

```json
{
  "PreToolUse": [{
    "matcher": "Bash(rm *)",
    "hooks": [{
      "type": "command",
      "command": "echo 'Creating backup before deletion...' && cp -r . /tmp/backup-$(date +%s) || true"
    }]
  }]
}
```

---

## Combined Configurations

### TypeScript Project (Recommended)

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "bun run format || true"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "Bash(git commit*)",
      "hooks": [
        {
          "type": "command",
          "command": "bun run lint:claude && bun run test"
        }
      ]
    }
  ]
}
```

### Python Project

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "black . && isort . || true"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "Bash(git commit*)",
      "hooks": [
        {
          "type": "command",
          "command": "pytest && mypy . && ruff check ."
        }
      ]
    }
  ]
}
```

### Go Project

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "gofmt -w . && go vet ./... || true"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "Bash(git commit*)",
      "hooks": [
        {
          "type": "command",
          "command": "go test ./... && golangci-lint run"
        }
      ]
    }
  ]
}
```

---

## Hook Best Practices

### Always Use `|| true` for PostToolUse

PostToolUse hooks shouldn't block Claude's workflow:

```json
// ✅ Good - won't block on format failure
"command": "bun run format || true"

// ❌ Bad - format failure blocks Claude
"command": "bun run format"
```

### PreToolUse Should Block on Failure

PreToolUse hooks SHOULD fail if checks don't pass:

```json
// ✅ Good - blocks commit if tests fail
"command": "bun run test"

// ❌ Bad - allows commit even if tests fail  
"command": "bun run test || true"
```

### Keep Hooks Fast

Hooks run synchronously. Slow hooks = slow Claude.

| Hook Type | Target Duration |
|-----------|-----------------|
| PostToolUse | < 2 seconds |
| PreToolUse | < 10 seconds |

**Optimization tips:**
- Run formatters on changed files only, not entire project
- Use `--cache` flags where available
- Skip hooks for non-code files

### Use Specific Matchers

```json
// ✅ Good - only triggers on git commits
"matcher": "Bash(git commit*)"

// ❌ Bad - triggers on ALL bash commands
"matcher": "Bash(*)"
```

---

## Debugging Hooks

### Test Hook Commands Manually

Before adding a hook, test the command:

```bash
# Test your hook command
bun run format || true

# Test with typical file
echo "test" > test.ts && bun run format || true
```

### Check Hook Execution

Add logging to verify hooks run:

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "echo '[HOOK] Running format...' && bun run format || true"
    }]
  }]
}
```

---

## Advanced Patterns

### Conditional Hooks by File Type

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "if [[ \"$FILE\" =~ \\.py$ ]]; then black \"$FILE\"; elif [[ \"$FILE\" =~ \\.(ts|tsx)$ ]]; then prettier --write \"$FILE\"; fi || true"
    }]
  }]
}
```

### Notification on Completion

```json
{
  "PostToolUse": [{
    "matcher": "Bash(bun run build*)",
    "hooks": [{
      "type": "command",
      "command": "osascript -e 'display notification \"Build complete\" with title \"Claude Code\"' || true"
    }]
  }]
}
```

### Auto-Stage Formatted Files

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "bun run format && git add -u || true"
    }]
  }]
}
```
