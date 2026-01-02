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
| `Notification` | When Claude needs attention | Desktop alerts |
| `Stop` | When Claude session ends | Cleanup, reporting |

### Environment Variables

These variables are available in hook commands:

| Variable | Description | Example |
|----------|-------------|---------|
| `$TOOL_NAME` | Name of the tool being used | `Write`, `Bash` |
| `$TOOL_INPUT` | JSON input to the tool | `{"file_path": "..."}` |
| `$FILE_PATH` | Path of file being modified | `/src/app.ts` |
| `$EXIT_CODE` | Exit code (PostToolUse only) | `0`, `1` |
| `$CLAUDE_SESSION_ID` | Current session identifier | `abc123` |
| `$CLAUDE_WORKING_DIR` | Working directory | `/home/user/project` |

### Matcher Syntax

```
Write           - Matches Write tool
Edit            - Matches Edit tool
Write|Edit      - Matches Write OR Edit
Bash(git *)     - Matches Bash with git commands
Bash(npm run *) - Matches Bash with npm run commands
*               - Matches everything (use carefully)
```

### Testing Hooks

Before deploying hooks, test them:

```bash
# Test hook command manually
echo "Testing hook..." && bun run format

# Run Claude with hook debugging
CLAUDE_DEBUG_HOOKS=1 claude
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

---

## Notification Hooks

Alert when Claude needs input or completes tasks.

### Desktop Notification on Completion

**macOS:**
```json
{
  "Notification": [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": "osascript -e 'display notification \"Claude needs your attention\" with title \"Claude Code\"'"
    }]
  }]
}
```

**Linux (notify-send):**
```json
{
  "Notification": [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": "notify-send 'Claude Code' 'Claude needs your attention'"
    }]
  }]
}
```

### Sound Alert

```json
{
  "Notification": [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": "afplay /System/Library/Sounds/Ping.aiff || paplay /usr/share/sounds/freedesktop/stereo/complete.oga || true"
    }]
  }]
}
```

---

## Stop Hooks

Run cleanup or reporting when Claude session ends.

### Session Summary

```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "echo \"Session $CLAUDE_SESSION_ID ended at $(date)\" >> ~/.claude/session.log"
    }]
  }]
}
```

### Git Status Check

```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "git status --short && echo '---' && git diff --stat"
    }]
  }]
}
```

### Cleanup Temp Files

```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "rm -f /tmp/claude-* || true"
    }]
  }]
}
```

---

## Hook Chaining

Run multiple hooks in sequence for the same trigger.

### Format, Lint, Then Stage

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "prettier --write \"$FILE_PATH\" || true"
      },
      {
        "type": "command",
        "command": "eslint --fix \"$FILE_PATH\" || true"
      },
      {
        "type": "command",
        "command": "git add \"$FILE_PATH\" || true"
      }
    ]
  }]
}
```

### Validate, Test, Then Notify

```json
{
  "PreToolUse": [{
    "matcher": "Bash(git push*)",
    "hooks": [
      {
        "type": "command",
        "command": "bun run typecheck"
      },
      {
        "type": "command",
        "command": "bun run test"
      },
      {
        "type": "command",
        "command": "echo 'All checks passed, pushing...'"
      }
    ]
  }]
}
```

---

## Conditional Hook Execution

### Only Run for Specific File Types

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "if [[ \"$FILE_PATH\" =~ \\.(ts|tsx)$ ]]; then prettier --write \"$FILE_PATH\"; fi || true"
    }]
  }]
}
```

### Skip for Generated Files

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "if ! grep -q '@generated' \"$FILE_PATH\" 2>/dev/null; then bun run format -- \"$FILE_PATH\"; fi || true"
    }]
  }]
}
```

### Different Formatters by Extension

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "case \"$FILE_PATH\" in *.py) black \"$FILE_PATH\";; *.ts|*.tsx) prettier --write \"$FILE_PATH\";; *.go) gofmt -w \"$FILE_PATH\";; esac || true"
    }]
  }]
}
```

---

## Blocking vs Non-Blocking Hooks

### Blocking Hook (PreToolUse)

Stops Claude if check fails:

```json
{
  "PreToolUse": [{
    "matcher": "Bash(git commit*)",
    "hooks": [{
      "type": "command",
      "command": "bun run test"
    }]
  }]
}
```

### Non-Blocking Hook (PostToolUse)

Runs but doesn't stop Claude on failure:

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

### Force Non-Blocking PreToolUse

When you want to warn but not block:

```json
{
  "PreToolUse": [{
    "matcher": "Bash(rm *)",
    "hooks": [{
      "type": "command",
      "command": "(echo '⚠️  Deleting files...' && ls -la $TOOL_INPUT) || true"
    }]
  }]
}
```
