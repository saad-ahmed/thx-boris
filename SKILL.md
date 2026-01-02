---
name: thx-boris
description: Meta-workflow for using Claude Code effectively, based on patterns from Boris Cherny (Claude Code creator). Use when setting up a new project with Claude Code, optimizing an existing workflow, creating CLAUDE.md files, designing subagents, configuring hooks, or running parallel Claude sessions. Triggers on "how should I structure my CLAUDE.md", "create a subagent for X", "set up hooks", "optimize my Claude Code setup".
---

# thx-boris: Claude Code Mastery

Production-tested patterns for maximizing Claude Code effectiveness, based on workflows from the Claude Code team.

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

**Real example from Claude Code repo:**
```markdown
# Before (Claude used enum)
- Prefer `type` over `interface`; avoid `enum` (use string unions)

# After (strengthened after violation)
- Prefer `type` over `interface`; **never use `enum`** (use string literal unions instead)
```

### Team CLAUDE.md Protocol

For team projects, CLAUDE.md is a shared artifact:
1. Check into git alongside code
2. All team members contribute
3. Review CLAUDE.md changes in PRs
4. Treat as living documentation

---

## Subagent Design

Subagents are specialized Claude instances with focused responsibilities. Store in `.claude/agents/`.

### When to Create Subagents

| Task Type | Subagent? | Rationale |
|-----------|-----------|-----------|
| Repetitive validation | ✅ Yes | Consistent checks |
| Code review patterns | ✅ Yes | Domain expertise |
| Complex multi-step | ✅ Yes | Focused context |
| One-off tasks | ❌ No | Overhead not worth it |

### Subagent Templates

See `references/subagent-templates.md` for complete templates:
- **build-validator** - Verify builds pass before commit
- **code-architect** - High-level design decisions
- **code-simplifier** - Reduce complexity
- **oncall-guide** - Production incident response
- **verify-app** - End-to-end application testing

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

See `references/hooks-patterns.md` for complete hook configurations.

---

## Permission Optimization

Pre-allow safe commands to reduce friction. Access via `/permissions` command.

### Safe to Pre-Allow

```
Bash(bun run build:*)
Bash(bun run lint:*)
Bash(bun run test:*)
Bash(bun run typecheck:*)
Bash(npm run build:*)
Bash(npm run lint:*)
Bash(npm run test:*)
Bash(find:*)
Bash(grep:*)
Bash(cat:*)
Bash(head:*)
Bash(tail:*)
```

### Never Pre-Allow

```
Bash(rm -rf *)
Bash(git push -f *)
Bash(sudo *)
Bash(curl * | bash)
```

---

## Parallel Orchestration

Running multiple Claudes maximizes throughput for complex projects.

### Terminal Strategy (Boris Pattern)

```
Tab 1: Feature A implementation
Tab 2: Tests for Feature A  
Tab 3: Feature B implementation
Tab 4: Bug fixes
Tab 5: Documentation
```

**Key setup:**
1. Number tabs 1-5 for quick switching
2. Enable system notifications for when Claude needs input
3. Use descriptive window titles

### Web + Terminal Hybrid

```
Terminal Claudes: Deep implementation work (numbered tabs)
Web Claudes: Research, docs, parallel exploration

Handoff patterns:
- Terminal → Web: Use & to background session
- Web → Terminal: Use --teleport to resume locally
```

### Task Decomposition for Parallelization

```
❌ Bad: "Implement the entire authentication system"
✅ Good: Split into parallel tracks:
   - Claude 1: Auth API endpoints
   - Claude 2: Auth UI components
   - Claude 3: Auth tests
   - Claude 4: Auth documentation
```

---

## Custom Slash Commands

Create project-specific commands for common workflows.

### Example: /commit-push-pr

```markdown
# .claude/commands/commit-push-pr.md
Commit all changes with a descriptive message, push to origin, and open a PR.

Steps:
1. Stage all changes
2. Generate commit message from diff
3. Push to current branch
4. Create PR with description from commits
```

### Command Design Principles

1. **Atomic** - One clear outcome
2. **Idempotent** - Safe to run multiple times
3. **Verbose** - Log what's happening
4. **Recoverable** - Handle failures gracefully

---

## Model Selection

**Default: Opus 4.5 with thinking**

Why Opus over Sonnet for complex work:
- Less steering required
- Better tool use
- Fewer mistakes = faster overall
- Thinking mode catches edge cases

When Sonnet is acceptable:
- Simple, well-defined tasks
- High-volume, low-complexity work
- When latency matters more than quality

---

## MCP Integration

Connect Claude to external services via MCP servers.

### Example: Slack Integration

```json
// .mcp.json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://slack.mcp.anthropic.com/mcp"
    }
  }
}
```

### Available First-Party MCPs
- Slack
- Google Drive
- GitHub

---

## Quick Reference

| Task | Solution |
|------|----------|
| Claude repeats mistake | Add to CLAUDE.md |
| Repetitive workflow | Create subagent |
| Auto-format code | PostToolUse hook |
| Reduce permission prompts | /permissions allow |
| Complex feature | Parallel Claudes |
| Common multi-step | Custom slash command |

---

## References

- `references/subagent-templates.md` - Complete subagent templates
- `references/hooks-patterns.md` - Hook configuration examples
- `assets/agents/` - Ready-to-use agent files
