# Verify App

End-to-end application verification before deployment.

## When to Run
- Before merging to main
- Before production deploy
- After major refactor
- After dependency updates

## Configuration

Create a `.claude/verify-app.json` to customize checks:

```json
{
  "build": {
    "command": "{{BUILD_COMMAND}}",
    "timeout": 300
  },
  "healthCheck": {
    "url": "{{HEALTH_CHECK_URL}}",
    "expectedStatus": 200
  },
  "flows": [
    {
      "name": "{{FLOW_NAME}}",
      "steps": ["{{STEP_1}}", "{{STEP_2}}"]
    }
  ],
  "integrations": [
    {
      "name": "{{SERVICE_NAME}}",
      "checkCommand": "{{CHECK_COMMAND}}"
    }
  ]
}
```

## Steps

### 1. Build Verification

```bash
# Clean build from scratch
rm -rf node_modules/.cache dist build .next
{{PKG}} install
{{PKG}} run build
```

**Checks:**
- [ ] Build completes without errors
- [ ] No TypeScript errors: `{{PKG}} run typecheck`
- [ ] No lint errors: `{{PKG}} run lint`
- [ ] All tests pass: `{{PKG}} test`

### 2. Runtime Verification

**Start the application:**
```bash
{{PKG}} run start &
APP_PID=$!
sleep 5  # Wait for startup
```

**Health check endpoint:**
```bash
# Basic health check
curl -f {{HEALTH_CHECK_URL}} || exit 1

# Detailed health check (if available)
curl {{HEALTH_CHECK_URL}}/ready | jq '.status == "ok"'
```

**Core user flows to verify:**
- [ ] `{{PRIMARY_FLOW_1}}` - e.g., "User can sign up"
- [ ] `{{PRIMARY_FLOW_2}}` - e.g., "User can log in"
- [ ] `{{PRIMARY_FLOW_3}}` - e.g., "User can complete checkout"

**Console check:**
```bash
# Capture browser console errors (if using Playwright/Puppeteer)
npx playwright test --grep="no-console-errors"
```

### 3. Integration Verification

| Service | Check Command | Expected |
|---------|--------------|----------|
| Database | `{{DB_CHECK_COMMAND}}` | Connection successful |
| Redis | `redis-cli ping` | PONG |
| API | `curl {{API_URL}}/health` | 200 OK |
| Auth | `curl {{AUTH_URL}}/.well-known/openid-configuration` | Valid JSON |

### 4. Performance Baseline

```bash
# Lighthouse CI (if configured)
npx lhci autorun

# Or manual checks
curl -w "@curl-format.txt" -o /dev/null -s {{APP_URL}}
```

**Thresholds:**
| Metric | Threshold |
|--------|-----------|
| Time to First Byte | < 200ms |
| Largest Contentful Paint | < 2.5s |
| Bundle Size | < {{MAX_BUNDLE_SIZE}} |

## Rollback Procedure

If verification fails after deploy:

```bash
# 1. Immediate rollback
git revert HEAD --no-edit
git push origin main

# 2. Or deploy previous version
{{DEPLOY_COMMAND}} --version={{PREVIOUS_VERSION}}

# 3. Notify team
echo "Deployment rolled back due to: {{FAILURE_REASON}}" | \
  slack-cli -c {{ALERTS_CHANNEL}}
```

## Success Criteria

All verification steps pass with no errors:
- Build: 0 errors, 0 warnings (or only whitelisted warnings)
- Runtime: App responds to health checks
- Flows: All critical user flows complete
- Integrations: All external services reachable

## Output

```
## App Verification: {{BRANCH}} @ {{COMMIT_SHA}}

### Build ✅
- Clean install: pass (45s)
- TypeScript: 0 errors
- ESLint: 0 errors, 3 warnings (whitelisted)
- Tests: 142/142 passed (23s)
- Bundle size: 245KB (limit: 300KB) ✅

### Runtime ✅
- Startup time: 2.3s
- Health check: 200 OK (12ms)
- Memory usage: 128MB (limit: 512MB)

### User Flows ✅
- Sign up flow: pass (1.2s)
- Login flow: pass (0.8s)
- Checkout flow: pass (2.1s)

### Integrations ✅
- PostgreSQL: connected (3ms latency)
- Redis: connected (1ms latency)
- Stripe API: responding (45ms latency)
- Auth0: responding (67ms latency)

### Performance ✅
- TTFB: 89ms (limit: 200ms)
- LCP: 1.8s (limit: 2.5s)
- CLS: 0.02 (limit: 0.1)

---
**Verdict: ✅ Ready for deploy**
Verification completed in 3m 42s
```

OR

```
## App Verification: feature/new-auth @ abc1234

### Build ❌
- Tests: 140/142 passed
  - FAILED: auth.test.ts - "should refresh expired token"
  - FAILED: auth.test.ts - "should handle invalid refresh token"

---
**Verdict: ❌ Blocked**
Reason: 2 test failures in auth module

### Suggested Actions:
1. Fix failing tests in `src/auth/__tests__/auth.test.ts`
2. Re-run verification with `claude verify-app`

### Rollback (if already deployed):
\`\`\`bash
git revert abc1234 --no-edit && git push origin main
\`\`\`
```

## Template Variables

Replace these placeholders with your project values:

| Placeholder | Example | Description |
|-------------|---------|-------------|
| `{{PKG}}` | `pnpm` | Package manager |
| `{{BUILD_COMMAND}}` | `pnpm build` | Build command |
| `{{HEALTH_CHECK_URL}}` | `http://localhost:3000/health` | Health endpoint |
| `{{PRIMARY_FLOW_1}}` | `User registration` | Critical flow 1 |
| `{{PRIMARY_FLOW_2}}` | `User login` | Critical flow 2 |
| `{{PRIMARY_FLOW_3}}` | `Purchase completion` | Critical flow 3 |
| `{{DB_CHECK_COMMAND}}` | `pg_isready -h localhost` | DB health check |
| `{{API_URL}}` | `http://localhost:3000/api` | API base URL |
| `{{MAX_BUNDLE_SIZE}}` | `300KB` | Bundle size limit |
| `{{DEPLOY_COMMAND}}` | `vercel deploy` | Deploy command |
| `{{ALERTS_CHANNEL}}` | `#eng-alerts` | Slack channel |
