---
name: thx-boris
description: Production-tested patterns for maximizing Claude Code effectiveness. Covers CLAUDE.md setup, subagent design, hooks, permissions, parallel sessions, and MCP integration. Not for general coding or debugging.
argument-hint: "[topic] e.g., 'hooks', 'CLAUDE.md', 'subagents', 'permissions', 'parallel sessions'"
license: MIT
compatibility: Claude Code CLI, Claude.ai, and web. Requires shell for scripts/.
metadata:
  author: saad-ahmed
  version: 3.0.0
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
| Set up a new project | The Living CLAUDE.md Pattern | [assets/claude-md-template.md](assets/claude-md-template.md) |
| Create an agent | Subagent Design | [references/subagent-templates.md](references/subagent-templates.md) |
| Configure hooks | Hook Automation | [references/hooks-patterns.md](references/hooks-patterns.md) |
| Optimize permissions/sessions/MCP | — | [references/session-and-mcp.md](references/session-and-mcp.md) |
| Run parallel sessions | Parallel Orchestration | — |
| Create your own skill | — | [references/skill-authoring.md](references/skill-authoring.md) |
| Troubleshoot issues | — | [references/troubleshooting.md](references/troubleshooting.md) |
| Avoid common mistakes | — | [references/anti-patterns.md](references/anti-patterns.md) |

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

**Real-world example from Claude Code development:**

```markdown
## Anti-Patterns
- Don't use `enum` for union types — use `type Status = 'active' | 'inactive'`
  (Claude kept generating TypeScript enums until this was added)
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

### Running Skills as Subagents

Use `context: fork` in SKILL.md frontmatter to run a skill in an isolated subagent. The skill content becomes the subagent's task prompt (no conversation history).

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---
```

Available agent types: `Explore` (fast codebase search), `Plan` (architecture), `general-purpose` (default).

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

## Parallel Orchestration

Running multiple Claudes maximizes throughput for complex projects.

### The 5-Tab Terminal Strategy (Boris's Pattern)

```
Tab 1: Claude — main coding session
Tab 2: Claude — research/exploration (isolated context)
Tab 3: git / manual commands
Tab 4: dev server / build watcher
Tab 5: test runner
```

This prevents context pollution between coding and research tasks.

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

### Custom Slash Commands & Skills

Create project-specific commands in `.claude/commands/`:

```markdown
# .claude/commands/commit-push-pr.md
Commit all changes with a descriptive message, push to origin, and open a PR.
```

Design principles: Atomic, Idempotent, Verbose, Recoverable.

**March 2026 skill features** (for skill authors):

| Feature | Description |
|---------|-------------|
| `context: fork` | Run skill in isolated context |
| `context: agent` | Run as subagent, returns summary |
| `$ARGUMENTS` | User input after skill name |
| `$CLAUDE_SKILL_DIR` | Path to skill directory |
| `!`\`command\` | Dynamic context injection |
| `allowed-tools` | Restrict which tools skill can use |
| `disable-model-invocation` | Prevent auto-triggering |
| `effort: low\|medium\|high` | Hint at expected complexity |

See [references/skill-authoring.md](references/skill-authoring.md) for full documentation.

For permissions, sessions, and MCP configuration, see [references/session-and-mcp.md](references/session-and-mcp.md).

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

See [templates/typescript-project/](templates/typescript-project/) for a working example.

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

See [templates/python-project/](templates/python-project/) for a working example.

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

## Model Selection

**Default:** Opus 4.6 (the most capable Claude model).

**Why Opus over Sonnet for complex work:**
- Less steering required
- Better tool use
- Fewer mistakes = faster overall

**When Sonnet 4.6 is acceptable:**
- Simple, well-defined tasks
- High-volume, low-complexity work
- When latency matters more than quality

Override per-skill with `model:` in frontmatter.

---

## Quick Reference

| Task | Solution |
|------|----------|
| Claude repeats mistake | Add to CLAUDE.md |
| Repetitive workflow | Create subagent in `.claude/agents/` |
| Auto-format code | PostToolUse hook |
| Reduce permission prompts | /permissions allow |
| Complex feature | Parallel Claudes with git worktrees |
| Common multi-step | Create a skill in `.claude/skills/` |
| Side-effect workflow | Skill with `disable-model-invocation: true` |
| Isolated research | Skill with `context: fork` + `agent: Explore` |
| New project setup | Run `scripts/setup-project.sh` |

---

## References

- [references/subagent-templates.md](references/subagent-templates.md) - Complete subagent templates
- [references/hooks-patterns.md](references/hooks-patterns.md) - Hook configuration examples
- [references/session-and-mcp.md](references/session-and-mcp.md) - Sessions, permissions, MCP config
- [references/skill-authoring.md](references/skill-authoring.md) - Creating your own skills
- [references/troubleshooting.md](references/troubleshooting.md) - Common issues and fixes
- [references/anti-patterns.md](references/anti-patterns.md) - What NOT to do
- [assets/agents/](assets/agents/) - Ready-to-use agent files
- [assets/claude-md-template.md](assets/claude-md-template.md) - Copy-paste starter for new projects
- [templates/](templates/) - Complete TypeScript and Python project examples
- [scripts/setup-project.sh](scripts/setup-project.sh) - Bootstrap Claude Code for a new project
- [scripts/validate-skill.sh](scripts/validate-skill.sh) - Validate skill folder structure
- [scripts/validate-claude-md.sh](scripts/validate-claude-md.sh) - Validate CLAUDE.md structure
