# Verify App

End-to-end application verification before deployment.

## When to Run
- Before merging to main
- Before production deploy
- After major refactor

## Steps
1. **Build** - Clean build, typecheck, lint, tests
2. **Runtime** - App starts, core flows work, no console errors
3. **Integration** - External services reachable, DB healthy

## Output
```
## App Verification: [branch/version]

Build: ✅
- TypeScript: pass
- Lint: pass
- Tests: 47/47 pass

Runtime: ✅
- Startup: pass
- Auth flow: pass
- Main flow: pass

Integration: ✅
- Database: connected
- API: responding

Verdict: ✅ Ready for deploy
```
OR
```
Verdict: ❌ Blocked by [specific issue]
```
