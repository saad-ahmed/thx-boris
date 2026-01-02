# Dependency Updater

Safely update project dependencies with automated testing.

## When to Run
- Weekly maintenance window
- Security vulnerability detected
- New major version of critical dependency
- "Update dependencies"

## Safety Principles

1. **One update at a time** - Never batch unrelated updates
2. **Test after each update** - Catch regressions immediately
3. **Commit incrementally** - Easy rollback if issues arise
4. **Read changelogs** - Understand breaking changes before updating

## Steps

### 1. Audit Current State

```bash
# Check for outdated packages
{{PKG}} outdated

# Check for security vulnerabilities
{{PKG}} audit

# List direct dependencies only
{{PKG}} list --depth=0
```

### 2. Categorize Updates

| Priority | Type | Action |
|----------|------|--------|
| Critical | Security patches | Update immediately |
| High | Bug fixes (patch) | Update same session |
| Medium | Minor versions | Update with testing |
| Low | Major versions | Schedule dedicated time |

### 3. Update Process (Per Dependency)

```bash
# 1. Check changelog/release notes
# Visit: https://github.com/{{owner}}/{{repo}}/releases

# 2. Update single dependency
{{PKG}} update {{package}}@{{version}}

# 3. Run tests
{{PKG}} test

# 4. Check for runtime issues
{{PKG}} run build && {{PKG}} run start

# 5. Commit if successful
git add package.json {{LOCKFILE}}
git commit -m "chore(deps): update {{package}} to {{version}}"
```

### 4. Handle Breaking Changes

For major version updates:

```bash
# 1. Create dedicated branch
git checkout -b chore/update-{{package}}-v{{major}}

# 2. Read migration guide
# 3. Make necessary code changes
# 4. Update tests
# 5. Full test suite
{{PKG}} test

# 6. Create PR for review
```

## Lockfile Reference

| Package Manager | Lockfile | Update Command |
|-----------------|----------|----------------|
| npm | `package-lock.json` | `npm update` |
| yarn | `yarn.lock` | `yarn upgrade` |
| pnpm | `pnpm-lock.yaml` | `pnpm update` |
| bun | `bun.lockb` | `bun update` |

## Security Updates

```bash
# Auto-fix vulnerabilities (npm)
npm audit fix

# Auto-fix vulnerabilities (pnpm)
pnpm audit --fix

# For breaking security fixes
npm audit fix --force  # Use with caution!
```

## Output

```
## Dependency Update Report

### Security Updates (Critical)
| Package | From | To | Vulnerability |
|---------|------|-----|---------------|
| lodash | 4.17.20 | 4.17.21 | Prototype pollution (CVE-2021-23337) |

### Updates Applied
| Package | From | To | Type | Tests |
|---------|------|-----|------|-------|
| lodash | 4.17.20 | 4.17.21 | patch | ✅ |
| react | 18.2.0 | 18.3.0 | minor | ✅ |
| typescript | 5.0.0 | 5.3.0 | minor | ✅ |

### Skipped (Require Manual Review)
| Package | From | To | Reason |
|---------|------|-----|--------|
| next | 13.5.0 | 14.0.0 | Major version, breaking changes |

### Summary
- 3 packages updated
- 0 vulnerabilities remaining
- All tests passing

### Next Steps
- [ ] Review Next.js 14 migration guide
- [ ] Schedule major version update for next sprint
```

## Rollback

If issues discovered after update:

```bash
# Revert specific commit
git revert {{COMMIT_SHA}}

# Or reset lockfile
git checkout HEAD~1 -- {{LOCKFILE}}
{{PKG}} install
```

## Automation

Add to CI for weekly checks:

```yaml
# .github/workflows/deps.yml
name: Dependency Check
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday 9am
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit
      - run: npm outdated || true
```

## Do NOT Update

Skip these unless explicitly requested:
- Packages pinned with exact versions (no `^` or `~`)
- Packages with `// DO NOT UPDATE` comments
- Peer dependencies (let parent package manage)
- Packages in active development (pre-1.0)
