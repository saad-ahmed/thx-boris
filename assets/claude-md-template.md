# {{PROJECT_NAME}}

> Copy this template to your project root as `CLAUDE.md` and customize for your project.

## Development Workflow

**Package manager:** `{{PACKAGE_MANAGER}}` (not npm/yarn/other)

**Before committing:** Always run `{{PACKAGE_MANAGER}} run check`

## Commands

```bash
# Development
{{PACKAGE_MANAGER}} run dev          # Start development server
{{PACKAGE_MANAGER}} run build        # Production build
{{PACKAGE_MANAGER}} run test         # Run tests
{{PACKAGE_MANAGER}} run test:watch   # Run tests in watch mode

# Quality checks
{{PACKAGE_MANAGER}} run lint         # Lint code
{{PACKAGE_MANAGER}} run typecheck    # TypeScript check
{{PACKAGE_MANAGER}} run format       # Format code
{{PACKAGE_MANAGER}} run check        # Run all checks (lint + typecheck + test)

# Database (if applicable)
{{PACKAGE_MANAGER}} run db:migrate   # Run migrations
{{PACKAGE_MANAGER}} run db:seed      # Seed database
{{PACKAGE_MANAGER}} run db:reset     # Reset database
```

## Project Structure

```
{{PROJECT_NAME}}/
├── src/
│   ├── components/    # UI components
│   ├── lib/           # Shared utilities
│   ├── services/      # Business logic
│   └── types/         # TypeScript types
├── tests/             # Test files
└── public/            # Static assets
```

## Code Style

### Do

- Use `type` over `interface` for type definitions
- Use string literal unions instead of `enum`
- Prefer named exports over default exports
- Use early returns to reduce nesting
- Write self-documenting code with clear variable names

### Don't

- Don't use `any` type - use `unknown` if type is truly unknown
- Don't use `enum` - use string literal unions: `type Status = 'active' | 'inactive'`
- Don't leave console.logs in production code
- Don't import from parent directories (`../../../`) - use path aliases

## Testing

- Test files: `*.test.ts` next to source files
- Use `describe`/`it` pattern
- Mock external dependencies
- Minimum coverage: {{COVERAGE_THRESHOLD}}%

## Anti-Patterns (Things Claude Got Wrong)

> Add items here when Claude makes mistakes. This helps prevent future issues.

<!--
Example entries:
- Don't use `moment.js` - use `date-fns` instead (lighter, tree-shakeable)
- Don't create files in `/tmp` - use `os.tmpdir()` for cross-platform support
- API responses must include `requestId` header for tracing
-->

## Domain Knowledge

### Key Concepts

- **{{CONCEPT_1}}**: {{DESCRIPTION_1}}
- **{{CONCEPT_2}}**: {{DESCRIPTION_2}}

### External Services

| Service | Purpose | Docs |
|---------|---------|------|
| {{SERVICE_1}} | {{PURPOSE_1}} | {{DOCS_URL_1}} |
| {{SERVICE_2}} | {{PURPOSE_2}} | {{DOCS_URL_2}} |

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | Database connection string | Yes |
| `API_KEY` | External API key | Yes |
| `DEBUG` | Enable debug logging | No |

## Git Conventions

### Branch Naming

- `feature/{{ticket}}-short-description`
- `fix/{{ticket}}-short-description`
- `chore/short-description`

### Commit Messages

Follow conventional commits:
- `feat: add user authentication`
- `fix: resolve login redirect issue`
- `docs: update API documentation`
- `refactor: simplify payment processing`
- `test: add coverage for auth module`
- `chore: update dependencies`

## Deployment

- **Staging:** Auto-deploy on push to `develop`
- **Production:** Manual deploy after PR merge to `main`

## Troubleshooting

### Common Issues

**Issue:** {{COMMON_ISSUE_1}}
**Solution:** {{SOLUTION_1}}

**Issue:** {{COMMON_ISSUE_2}}
**Solution:** {{SOLUTION_2}}

---

## Quick Setup (New Contributor)

```bash
# 1. Clone and install
git clone {{REPO_URL}}
cd {{PROJECT_NAME}}
{{PACKAGE_MANAGER}} install

# 2. Set up environment
cp .env.example .env
# Edit .env with your values

# 3. Set up database (if applicable)
{{PACKAGE_MANAGER}} run db:migrate
{{PACKAGE_MANAGER}} run db:seed

# 4. Start development
{{PACKAGE_MANAGER}} run dev
```
