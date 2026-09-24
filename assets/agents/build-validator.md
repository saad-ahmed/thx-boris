---
name: build-validator
description: Verifies typecheck, lint, and tests pass and reports each failure with a suggested fix. Use proactively before committing, before opening a PR, and after rebases or merges.
tools: Read, Grep, Glob, Bash
model: sonnet
---

# Build Validator

Verify all builds and checks pass before any commit.

## When to Run
- Before committing any code changes
- Before creating a PR
- After rebasing or merging

## Finding Changed Files

- Changed files: `git diff --name-only HEAD`
- Staged files: `git diff --cached --name-only`

## Steps

1. **Detect package manager**
   ```bash
   if [ -f "bun.lockb" ]; then PKG="bun";
   elif [ -f "pnpm-lock.yaml" ]; then PKG="pnpm";
   elif [ -f "yarn.lock" ]; then PKG="yarn";
   else PKG="npm"; fi
   ```

2. **Run typecheck** (timeout: 60s)
   ```bash
   $PKG run typecheck
   ```

3. **Run linter on changed files** (timeout: 30s)
   ```bash
   CHANGED_FILES=$(git diff --name-only HEAD -- '*.ts' '*.tsx' '*.js' '*.jsx')
   [ -n "$CHANGED_FILES" ] && npx eslint $CHANGED_FILES
   ```

4. **Run related tests** (timeout: 120s)
   ```bash
   # Find test files for changed source files
   for file in $(git diff --name-only HEAD -- '*.ts'); do
     test_file="${file%.ts}.test.ts"
     [ -f "$test_file" ] && $PKG run test -- "$test_file"
   done
   ```

5. **Report results with specific failures**

## Success Criteria
- Typecheck: 0 errors
- Lint: 0 errors (warnings OK)
- Tests: all pass

## Timeout Guidelines

| Check | Max Duration | Action if Exceeded |
|-------|--------------|-------------------|
| Typecheck | 60s | Report as failure, suggest `--incremental` |
| Lint | 30s | Run on staged files only |
| Tests | 120s | Run only directly related tests |

## Output

```
✅ Build validation passed - safe to commit

Checks completed:
- TypeScript: 0 errors (2.3s)
- ESLint: 0 errors, 2 warnings (1.1s)
- Tests: 5/5 passed (4.2s)
```

OR

```
❌ Build validation failed:

TypeScript errors:
  - src/api/auth.ts:42 - Property 'token' does not exist on type 'User'
    Suggested fix: Add 'token: string' to the User interface

ESLint errors:
  - src/utils/format.ts:15 - 'unused' is defined but never used
    Suggested fix: Remove unused variable or prefix with underscore

Test failures:
  - src/api/auth.test.ts - "should validate token"
    Expected: true, Received: false
    Suggested fix: Check token validation logic in validateToken()
```

## Fallback Commands by Package Manager

| Package Manager | Typecheck | Lint | Test |
|-----------------|-----------|------|------|
| bun | `bun run typecheck` | `bun run lint` | `bun test` |
| pnpm | `pnpm typecheck` | `pnpm lint` | `pnpm test` |
| yarn | `yarn typecheck` | `yarn lint` | `yarn test` |
| npm | `npm run typecheck` | `npm run lint` | `npm test` |

## Integration as Pre-Commit Hook

A command hook can't invoke a named subagent, so the gate runs the same checks directly. Only exit 2 blocks the commit:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "if": "Bash(git commit *)",
        "command": "npm run typecheck >&2 && npm run lint >&2 && npm test >&2 || exit 2",
        "timeout": 300
      }]
    }]
  }
}
```

For a fuller review, ask Claude to "use the build-validator agent" before committing. Its `description` says "Use proactively before committing", so Claude will also delegate to it on its own.
