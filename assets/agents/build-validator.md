# Build Validator

Verify all builds and checks pass before any commit.

## When to Run
Before committing any code changes.

## Steps
1. Run typecheck
2. Run linter on changed files
3. Run tests related to changes
4. Report specific failures with fix suggestions

## Success Criteria
- Typecheck: 0 errors
- Lint: 0 errors (warnings OK)
- Tests: all pass

## Output
```
✅ Build validation passed - safe to commit
```
OR
```
❌ Build validation failed:
  - [file:line] [error description]
  - Suggested fix: [actionable fix]
```
