# Security Scanner

Scan codebase for security vulnerabilities before deployment.

## When to Run
- Before merging to main
- Before production deploy
- After adding new dependencies
- Weekly automated scan
- "Check for security issues"

## Scan Categories

| Category | Tools | Priority |
|----------|-------|----------|
| Dependencies | npm audit, Snyk | Critical |
| Secrets | gitleaks, trufflehog | Critical |
| Code (SAST) | Semgrep, CodeQL | High |
| Containers | Trivy, Grype | High |
| Infrastructure | tfsec, checkov | Medium |

## Steps

### 1. Dependency Vulnerabilities

```bash
# npm
npm audit --audit-level=high

# pnpm
pnpm audit --audit-level=high

# yarn
yarn audit --level high

# Snyk (if installed)
snyk test --severity-threshold=high
```

### 2. Secret Detection

```bash
# gitleaks - scan entire repo history
gitleaks detect --source . --verbose

# gitleaks - scan only staged changes
gitleaks protect --staged --verbose

# trufflehog - scan for high-entropy strings
trufflehog filesystem . --only-verified
```

**Common secrets to detect:**
- API keys (AWS, GCP, Stripe, etc.)
- Database credentials
- JWT secrets
- Private keys
- OAuth tokens

### 3. Static Analysis (SAST)

```bash
# Semgrep - general security rules
semgrep scan --config=auto .

# Semgrep - OWASP top 10
semgrep scan --config=p/owasp-top-ten .

# ESLint security plugin
npx eslint --plugin security --rule 'security/*: error' src/
```

### 4. Container Scanning

```bash
# Trivy - scan Docker image
trivy image {{IMAGE_NAME}}:{{TAG}}

# Trivy - scan Dockerfile
trivy config Dockerfile

# Grype
grype {{IMAGE_NAME}}:{{TAG}}
```

### 5. Infrastructure as Code

```bash
# Terraform
tfsec .

# CloudFormation / Terraform / K8s
checkov -d .

# Kubernetes manifests
kubesec scan deployment.yaml
```

## OWASP Top 10 Checklist

| # | Vulnerability | Check |
|---|--------------|-------|
| A01 | Broken Access Control | Review auth middleware |
| A02 | Cryptographic Failures | Check encryption usage |
| A03 | Injection | Parameterized queries? |
| A04 | Insecure Design | Threat model reviewed? |
| A05 | Security Misconfiguration | Headers, CORS, defaults |
| A06 | Vulnerable Components | Dependency scan |
| A07 | Auth Failures | Session management |
| A08 | Data Integrity Failures | Input validation |
| A09 | Logging Failures | Sensitive data in logs? |
| A10 | SSRF | URL validation |

## Quick Fixes

### SQL Injection
```typescript
// ❌ Bad
const query = `SELECT * FROM users WHERE id = ${userId}`;

// ✅ Good
const query = `SELECT * FROM users WHERE id = $1`;
await db.query(query, [userId]);
```

### XSS
```typescript
// ❌ Bad
element.innerHTML = userInput;

// ✅ Good
element.textContent = userInput;
// Or use DOMPurify
element.innerHTML = DOMPurify.sanitize(userInput);
```

### Exposed Secrets
```bash
# If secret committed, rotate immediately!
# 1. Generate new secret
# 2. Update in secret manager
# 3. Remove from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch {{FILE_WITH_SECRET}}" \
  --prune-empty --tag-name-filter cat -- --all
```

### Insecure Headers
```typescript
// Add security headers
app.use(helmet());

// Or manually:
res.setHeader('X-Content-Type-Options', 'nosniff');
res.setHeader('X-Frame-Options', 'DENY');
res.setHeader('Content-Security-Policy', "default-src 'self'");
res.setHeader('Strict-Transport-Security', 'max-age=31536000');
```

## Output

```
## Security Scan Report

**Scanned:** {{REPO_NAME}} @ {{COMMIT_SHA}}
**Date:** {{SCAN_DATE}}

### Summary
| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | ✅ |
| High | 2 | ⚠️ |
| Medium | 5 | ⚠️ |
| Low | 12 | ℹ️ |

### Critical/High Findings

#### 1. SQL Injection (High)
- **File:** src/api/users.ts:45
- **Description:** User input directly concatenated in SQL query
- **Fix:** Use parameterized query
```typescript
// Change this:
const q = `SELECT * FROM users WHERE name = '${name}'`;
// To this:
const q = `SELECT * FROM users WHERE name = $1`;
await db.query(q, [name]);
```

#### 2. Exposed API Key (High)
- **File:** src/config.ts:12
- **Description:** Stripe API key hardcoded in source
- **Fix:** Move to environment variable
```typescript
// Change this:
const STRIPE_KEY = 'sk_live_abc123...';
// To this:
const STRIPE_KEY = process.env.STRIPE_SECRET_KEY;
```

### Dependency Vulnerabilities
| Package | Severity | Vulnerability | Fix |
|---------|----------|---------------|-----|
| lodash | High | Prototype pollution | Upgrade to 4.17.21 |
| axios | Medium | SSRF | Upgrade to 1.6.0 |

### Secrets Detected
| Type | File | Line | Status |
|------|------|------|--------|
| AWS Key | .env.example | 5 | ⚠️ Example file, verify not real |

### Passed Checks
- ✅ No critical vulnerabilities in dependencies
- ✅ No secrets in git history
- ✅ Security headers configured
- ✅ HTTPS enforced
- ✅ CORS properly configured

---
**Verdict:** ⚠️ 2 high-severity issues require attention before deploy

### Required Actions
1. [ ] Fix SQL injection in users.ts
2. [ ] Move Stripe key to environment variable
3. [ ] Upgrade lodash to 4.17.21
```

## CI Integration

```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for secret scanning

      - name: Dependency audit
        run: npm audit --audit-level=high

      - name: Secret detection
        uses: gitleaks/gitleaks-action@v2

      - name: SAST scan
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/security-audit

      - name: Container scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_NAME }}
```

## False Positive Management

```yaml
# .semgrepignore
tests/
*.test.ts
*.spec.ts
__mocks__/

# .gitleaksignore
# Format: commit:file:rule
abc1234:tests/fixtures/fake-key.json:generic-api-key
```
