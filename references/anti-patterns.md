# Anti-Patterns

Common mistakes to avoid when using Claude Code.

---

## Prompt Anti-Patterns

### Vague Instructions

**Bad:**
```
Fix the bug
```

**Good:**
```
Fix the TypeError in src/auth/login.ts:45 where 'user.email' is undefined
```

**Why:** Vague prompts lead to wrong assumptions. Claude may fix a different bug or make unnecessary changes.

---

### Asking for Too Much at Once

**Bad:**
```
Build a complete e-commerce site with user auth, product catalog, shopping cart,
payment processing, admin dashboard, email notifications, and analytics
```

**Good:**
```
Let's build an e-commerce site. Start with user authentication:
1. Create a User model with email and password
2. Add signup endpoint at POST /api/auth/signup
3. Add login endpoint at POST /api/auth/login
4. Use JWT for session management
```

**Why:** Large requests exceed context limits and lead to incomplete implementations.

---

### Not Providing Context

**Bad:**
```
Add the new feature
```

**Good:**
```
Add a dark mode toggle to the settings page.
- The app uses Tailwind CSS
- Current theme is in React context (ThemeContext)
- Toggle should persist to localStorage
```

**Why:** Without context, Claude has to guess architecture decisions.

---

## Code Anti-Patterns

### Over-Engineering

**Bad (Claude might do this):**
```typescript
// Factory for creating validators
class ValidatorFactory {
  private static instance: ValidatorFactory;
  private validators: Map<string, Validator> = new Map();

  static getInstance(): ValidatorFactory {
    if (!ValidatorFactory.instance) {
      ValidatorFactory.instance = new ValidatorFactory();
    }
    return ValidatorFactory.instance;
  }

  createValidator(type: string): Validator {
    // ... 50 more lines
  }
}
```

**Good:**
```typescript
function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

**Prevention:** Add to CLAUDE.md:
```markdown
- Keep solutions simple. Don't add abstraction layers unless there are 3+ concrete use cases.
```

---

### Adding Unnecessary Dependencies

**Bad:**
```bash
npm install lodash    # For one array operation
npm install moment    # For one date format
npm install axios     # When fetch works fine
```

**Good:**
```typescript
// Native alternatives
array.filter(x => x.active)           // Instead of _.filter
new Date().toISOString()              // Instead of moment
fetch('/api/data')                    // Instead of axios
```

**Prevention:** Add to CLAUDE.md:
```markdown
- Don't add dependencies for simple operations. Use native APIs when possible.
- Check bundle size before adding dependencies: https://bundlephobia.com
```

---

### Ignoring Existing Patterns

**Bad:**
```typescript
// Existing codebase uses kebab-case files
// Claude creates:
src/components/UserProfile.tsx
src/components/ShoppingCart.tsx
```

**Good:**
```typescript
// Following existing convention:
src/components/user-profile.tsx
src/components/shopping-cart.tsx
```

**Prevention:** Add to CLAUDE.md:
```markdown
- Follow existing naming conventions in the codebase
- Files: kebab-case (user-profile.tsx)
- Components: PascalCase (UserProfile)
- Functions: camelCase (getUserProfile)
```

---

### Breaking API Contracts

**Bad:**
```typescript
// Before: returns { data: User[] }
// Claude changes to: returns User[]
async function getUsers(): Promise<User[]> {
  return users;
}
```

**Good:**
```typescript
// Maintains API contract
async function getUsers(): Promise<{ data: User[] }> {
  return { data: users };
}
```

**Prevention:** Add to CLAUDE.md:
```markdown
- Never change return types of public APIs without explicit approval
- Maintain backwards compatibility for all exported functions
```

---

## Configuration Anti-Patterns

### Overly Permissive Hooks

**Bad:**
```json
{
  "PreToolUse": [{
    "matcher": "*",
    "hooks": [{
      "type": "command",
      "command": "rm -rf node_modules && npm install"
    }]
  }]
}
```

**Good:**
```json
{
  "PreToolUse": [{
    "matcher": "Bash(git commit*)",
    "hooks": [{
      "type": "command",
      "command": "npm run lint && npm test"
    }]
  }]
}
```

**Why:** Wildcard matchers run on every tool use, causing massive slowdown.

---

### Pre-Allowing Dangerous Commands

**Bad:**
```
/permissions allow Bash(*)
/permissions allow Bash(rm -rf *)
/permissions allow Bash(sudo *)
```

**Good:**
```
/permissions allow Bash(npm run test)
/permissions allow Bash(npm run build)
/permissions allow Bash(git status)
```

**Why:** Overly permissive allows can lead to destructive operations.

---

### Ignoring .claudeignore

**Bad:** No `.claudeignore`, Claude reads everything

**Good:**
```
# .claudeignore
node_modules/
dist/
build/
.git/
*.log
coverage/
.env
*.min.js
```

**Why:** Without ignore rules, Claude wastes context on irrelevant files.

---

## Workflow Anti-Patterns

### Not Reviewing Changes

**Bad:**
1. Ask Claude to make changes
2. Commit immediately
3. Push to main
4. Find bugs in production

**Good:**
1. Ask Claude to make changes
2. Review diff: `git diff`
3. Run tests: `npm test`
4. Test manually
5. Commit and push

---

### Running Parallel Claudes on Same Files

**Bad:**
```
Tab 1: Claude editing src/api/users.ts
Tab 2: Claude editing src/api/users.ts
```

**Good:**
```
Tab 1: Claude editing src/api/users.ts
Tab 2: Claude editing src/api/products.ts
```

**Or use git worktrees:**
```bash
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b
```

---

### Committing Without Testing

**Bad:**
```
"Commit these changes"
```

**Good:**
```
"Run the test suite, fix any failures, then commit"
```

**Prevention:** Add PreToolUse hook:
```json
{
  "PreToolUse": [{
    "matcher": "Bash(git commit*)",
    "hooks": [{
      "type": "command",
      "command": "npm test"
    }]
  }]
}
```

---

## Communication Anti-Patterns

### Accepting Everything

**Bad:** Always saying "looks good" without reviewing

**Good:**
- Review diffs before committing
- Question architectural decisions
- Push back on over-engineering

---

### Not Correcting Mistakes

**Bad:** Manually fixing Claude's mistakes without feedback

**Good:**
1. Tell Claude what was wrong
2. Add to CLAUDE.md Anti-Patterns section
3. Claude learns for next time

---

### Providing Conflicting Instructions

**Bad:**
```
CLAUDE.md: "Use functional components"
Prompt: "Create a class component for..."
```

**Good:**
```
Prompt: "Create a component for... (use class component for this one exception because...)"
```

---

## Summary: Prevention Checklist

Add these to your CLAUDE.md:

```markdown
## Anti-Patterns to Avoid

- Don't add dependencies without checking if native APIs work
- Don't change public API return types without approval
- Don't create abstractions for single use cases
- Don't ignore existing naming conventions
- Don't skip tests before committing
- Don't create files in project root (use proper directories)
- Don't use `any` type - use `unknown` or proper types
- Don't leave TODO comments without ticket references
```
