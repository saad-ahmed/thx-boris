# Example TypeScript Project

A Next.js application with TypeScript, Tailwind CSS, and Prisma.

## Development Workflow

**Package manager:** `pnpm` (not npm or yarn)

**Before committing:** Always run `pnpm check`

## Commands

```bash
# Development
pnpm dev              # Start dev server (port 3000)
pnpm build            # Production build
pnpm start            # Start production server
pnpm test             # Run tests with Vitest
pnpm test:watch       # Watch mode

# Quality checks
pnpm lint             # ESLint
pnpm typecheck        # TypeScript
pnpm format           # Prettier
pnpm check            # All checks (lint + typecheck + test)

# Database
pnpm db:migrate       # Run Prisma migrations
pnpm db:seed          # Seed database
pnpm db:studio        # Open Prisma Studio
```

## Project Structure

```
src/
├── app/              # Next.js App Router pages
├── components/       # React components
│   ├── ui/           # Reusable UI components
│   └── features/     # Feature-specific components
├── lib/              # Utilities and helpers
├── server/           # Server-side code
│   ├── api/          # API route handlers
│   └── db/           # Database queries
└── types/            # TypeScript types
```

## Code Style

### TypeScript

- Use `type` over `interface`
- Use string unions over `enum`: `type Status = 'active' | 'inactive'`
- Prefer `unknown` over `any`
- Export types from `types/` directory

### React

- Functional components only
- Use `useCallback` for event handlers passed to children
- Prefer composition over prop drilling
- Client components: `'use client'` at top of file

### Naming

- Files: `kebab-case.ts`
- Components: `PascalCase`
- Functions/variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

## Testing

- Test files: `*.test.ts` next to source
- Use `describe`/`it` pattern
- Mock external services
- Minimum 80% coverage

## Anti-Patterns

- Don't use `moment.js` - use `date-fns`
- Don't create components in `pages/` - only in `components/`
- Don't use `var` - use `const` or `let`
- Don't mutate state directly - use immutable patterns
- Don't import from `..` more than 2 levels - use `@/` alias

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Postgres connection string |
| `NEXTAUTH_SECRET` | Auth secret key |
| `NEXTAUTH_URL` | App URL (http://localhost:3000) |
