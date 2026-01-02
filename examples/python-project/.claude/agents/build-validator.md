# Build Validator

Verify all builds and checks pass before any commit.

## When to Run
Before committing any code changes.

## Steps
1. Run linter: `ruff check .`
2. Run type checker: `mypy .`
3. Run tests: `pytest`
4. Report specific failures with fix suggestions

## Success Criteria
- Ruff: 0 errors
- MyPy: 0 errors
- Pytest: all pass

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
