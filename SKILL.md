---
name: thx-boris
description: Production-tested patterns for maximizing Claude Code effectiveness. Use when setting up a new project with Claude Code, creating CLAUDE.md files, designing subagents, configuring hooks, optimizing permissions, or running parallel Claude sessions. Triggers on "how should I structure my CLAUDE.md", "create a subagent for X", "set up hooks", "optimize my Claude Code setup", "configure Claude Code for my project". Do NOT use for general coding questions, debugging specific bugs, or writing application code.
license: MIT
compatibility: Designed for Claude Code CLI and Claude.ai. Requires shell access for scripts/ executables.
metadata:
  author: saad-ahmed
  version: 2.0.0
  category: developer-tools
  tags: [claude-code, workflow, automation, devtools]
---

# thx-boris: Claude Code Mastery

Production-tested patterns for maximizing Claude Code effectiveness, based on workflows from the Claude Code team.

## Instructions

### Step 1: Identify the User's Goal

Determine which workflow the user needs:

| Goal | Section | Reference |
|------|---------|-----------|
| Set up a new project | The Living CLAUDE.md Pattern | `assets/claude-md-template.md` |
| Create an agent | Subagent Design | `references/subagent-templates.md` |
| Configure hooks | Hook Automation | `references/hooks-patterns.md` |
| Optimize permissions | Permission Optimization | — |
| Run parallel sessions | Parallel Orchestration | — |
| Set up MCP servers | MCP Integration | — |
| Troubleshoot issues | — | `references/troubleshooting.md` |
| Avoid common mistakes | — | `references/anti-patterns.md` |

### Step 2: Apply the Relevant Pattern

Follow the pattern for the user's goal. Each pattern includes step-by-step instructions, success criteria, and common pitfalls.

### Step 3: Validate the Setup

Run `scripts/validate-skill.sh` to verify configuration, or run `scripts/setup-project.sh` to bootstrap a new project.

---

## The Living CLAUDE.md Pattern

**Core principle:** Every Claude mistake becomes a permanent lesson.

### Structure

```markdown
# Development Workflow

**Always use `[package-manager]`, not `[alternative]`.**

## Commands
[Ordered by frequency of use]

## Code Style
[Project-specific patterns Claude should follow]

## Anti-Patterns
[Things Claude got wrong - add new ones as discovered]

## Domain Knowledge
[Project-specific context Claude needs]
```

### The Feedback Loop

```
Claude makes mistake → Human notices → Add to CLAUDE.md → Claude never repeats
```

### Team CLAUDE.md Protocol

For team projects, CLAUDE.md is a shared artifact:
1. Check into git alongside code
2. All team members contribute
3. Review CLAUDE.md changes in PRs
4. Treat as living documentation

A ready-to-use template is available at `assets/claude-md-template.md`.

---

## Subagent Design

Subagents are specialized Claude instances with focused responsibilities. Store in `.claude/agents/`.

### When to Create Subagents

| Task Type | Subagent? | Rationale |
|-----------|-----------|-----------|
| Repetitive validation | Yes | Consistent checks |
| Code review patterns | Yes | Domain expertise |
| Complex multi-step | Yes | Focused context |
| One-off tasks | No | Overhead not worth it |

### Available Agent Templates

Ready-to-use agents in `assets/agents/`:
- **build-validator** - Verify builds pass before commit
- **code-simplifier** - Reduce complexity
- **verify-app** - End-to-end application testing
- **dependency-updater** - Safe dependency updates
- **migration-runner** - Database migration with rollback
- **security-scanner** - OWASP-based security checks

See `references/subagent-templates.md` for additional templates (code-architect, oncall-guide, pr-reviewer, test-writer).

### Creating a Subagent

```bash
# Create agent file
touch .claude/agents/[agent-name].md

# Agent file structure:
# 1. Purpose (one line)
# 2. Trigger conditions
# 3. Step-by-step procedure
# 4. Success criteria
# 5. Handoff instructions
```

---

## Hook Automation

Hooks run automatically before/after Claude actions. Configure in `.claude/settings.json`.

### Common Patterns

**Auto-format on write:**
```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "bun run format || true"
    }]
  }]
}
```

**Lint before commit:**
```json
{
  "PreToolUse": [{
    "matcher": "Bash(git commit*)",
    "hooks": [{
      "type": "command",
      "command": "bun run lint:claude && bun run test"
    }]
  }]
}
```

CRITICAL: PostToolUse hooks should always end with `|| true` to avoid blocking Claude. PreToolUse hooks should NOT use `|| true` so they block on failure.

See `references/hooks-patterns.md` for complete hook configurations including Notification, Stop, and chaining patterns.

---

## Permission Optimization

Pre-allow safe commands to reduce friction. Access via `/permissions` command.

### Safe to Pre-Allow

```
# Build & test commands
Bash(bun run build:*)
Bash(bun run lint:*)
Bash(bun run test:*)
Bash(bun run typecheck:*)
Bash(npm run build:*)
Bash(npm run lint:*)
Bash(npm run test:*)
Bash(yarn build:*)
Bash(yarn lint:*)
Bash(yarn test:*)
Bash(pnpm build:*)
Bash(pnpm lint:*)
Bash(pnpm test:*)

# Git read operations
Bash(git status)
Bash(git diff*)
Bash(git log*)
Bash(git branch*)
Bash(git show*)

# File exploration
Bash(find:*)
Bash(grep:*)
Bash(cat:*)
Bash(head:*)
Bash(tail:*)
Bash(ls:*)
Bash(tree:*)
Bash(wc:*)
```

### Never Pre-Allow

```
Bash(rm -rf *)
Bash(git push -f *)
Bash(git reset --hard *)
Bash(sudo *)
Bash(curl * | bash)
Bash(chmod 777 *)
```

### Personal Overrides

For personal permissions that shouldn't be committed, use `.claude/settings.local.json`.

---

## Parallel Orchestration

Running multiple Claudes maximizes throughput for complex projects.

### Git Worktrees (Recommended)

```bash
# Create worktrees for parallel work
git worktree add ../myproject-feature-a feature-a
git worktree add ../myproject-feature-b feature-b

# Each worktree gets its own Claude instance
cd ../myproject-feature-a && claude
cd ../myproject-feature-b && claude
```

### Task Decomposition

```
Bad: "Implement the entire authentication system"
Good: Split into parallel tracks:
  - Claude 1: Auth API endpoints
  - Claude 2: Auth UI components
  - Claude 3: Auth tests
  - Claude 4: Auth documentation
```

---

## Custom Slash Commands

Create project-specific commands in `.claude/commands/`.

```markdown
# .claude/commands/commit-push-pr.md
Commit all changes with a descriptive message, push to origin, and open a PR.

Steps:
1. Stage all changes
2. Generate commit message from diff
3. Push to current branch
4. Create PR with description from commits
```

Design principles: Atomic, Idempotent, Verbose, Recoverable.

---

## MCP Integration

Connect Claude to external services via MCP servers. Configure in `.mcp.json`.

| MCP Server | Use Case |
|------------|----------|
| Slack | Send messages, read channels |
| Google Drive | Read/write docs, sheets |
| GitHub | Issues, PRs, code search |
| Sentry | Error tracking, issue lookup |
| PostgreSQL | Direct database queries |
| Puppeteer | Browser automation, screenshots |

---

## Session Management

```bash
# Resume last session
claude --continue

# Resume specific session
claude --resume SESSION_ID

# Headless / CI mode
claude -p "fix all TypeScript errors" --output-format json
```

---

## Examples

### Example 1: Setting up a new TypeScript project

User says: "Set up Claude Code for my Next.js project"

Actions:
1. Run `scripts/setup-project.sh . pnpm`
2. Copy `assets/claude-md-template.md` to `CLAUDE.md`
3. Customize CLAUDE.md with project-specific commands and style
4. Copy relevant agents from `assets/agents/` to `.claude/agents/`

Result: Complete Claude Code configuration with hooks, permissions, and agents.

See `assets/example-configs/typescript-project/` for a working example.

### Example 2: Creating a custom subagent

User says: "Create a subagent for code review"

Actions:
1. Consult `references/subagent-templates.md` for the pr-reviewer template
2. Copy to `.claude/agents/pr-reviewer.md`
3. Customize trigger conditions and review checklist

Result: Agent file ready to use in `.claude/agents/`.

### Example 3: Configuring hooks for a Python project

User says: "Set up auto-formatting hooks for my Python project"

Actions:
1. Consult `references/hooks-patterns.md` for the Python project pattern
2. Create `.claude/settings.json` with Black + isort PostToolUse hooks
3. Add pytest + mypy PreToolUse hooks for pre-commit

Result: Auto-formatting on every file change, validation before every commit.

See `assets/example-configs/python-project/` for a working example.

---

## Troubleshooting

### Hooks not running
Cause: Invalid JSON in `.claude/settings.json` or wrong matcher pattern
Solution: Validate JSON with `cat .claude/settings.json | jq .` and check matcher syntax in `references/hooks-patterns.md`

### Claude ignores CLAUDE.md instructions
Cause: File not at project root, wrong filename, or instructions too verbose
Solution: Verify file is exactly `CLAUDE.md` at root. Keep instructions concise with bullet points. Move details to references.

### Skill doesn't trigger
Cause: Description too vague or missing trigger phrases
Solution: Run `scripts/validate-skill.sh` to check. Add specific trigger phrases to the description field.

### Over-triggering
Cause: Description too broad
Solution: Add negative triggers ("Do NOT use for...") and be more specific about scope.

See `references/troubleshooting.md` for comprehensive troubleshooting.

---

## Quick Reference

| Task | Solution |
|------|----------|
| Claude repeats mistake | Add to CLAUDE.md |
| Repetitive workflow | Create subagent |
| Auto-format code | PostToolUse hook |
| Reduce permission prompts | /permissions allow |
| Complex feature | Parallel Claudes with git worktrees |
| Common multi-step | Custom slash command |
| New project setup | Run `scripts/setup-project.sh` |

---

## References

- `references/subagent-templates.md` - Complete subagent templates
- `references/hooks-patterns.md` - Hook configuration examples
- `references/troubleshooting.md` - Common issues and fixes
- `references/anti-patterns.md` - What NOT to do
- `assets/agents/` - Ready-to-use agent files
- `assets/claude-md-template.md` - Copy-paste starter for new projects
- `assets/example-configs/` - Complete TypeScript and Python project examples
- `scripts/setup-project.sh` - Bootstrap Claude Code for a new project
- `scripts/validate-skill.sh` - Validate skill folder structure
