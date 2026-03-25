# Skill Authoring Guide

Reference for creating and publishing Claude Code skills (March 2026 best practices).

---

## Frontmatter Fields

All skills require a SKILL.md with YAML frontmatter:

```yaml
---
name: my-skill-name                    # Required, kebab-case
description: Short description here    # Required, under 1024 chars
argument-hint: "[topic]"               # Optional, shows in autocomplete
user-invocable: true                   # Optional, default true
disable-model-invocation: false        # Optional, prevents auto-triggering
model: opus                            # Optional: opus, sonnet, haiku
context: fork                          # Optional: fork, agent
effort: high                           # Optional: low, medium, high
license: MIT                           # Optional
---
```

### Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique kebab-case identifier |
| `description` | Yes | Third-person, what-it-does focus, under 1024 chars |
| `argument-hint` | No | Placeholder shown in autocomplete (e.g., `[file]`, `[topic]`) |
| `user-invocable` | No | If false, skill can only be triggered by Claude (default: true) |
| `disable-model-invocation` | No | If true, prevents Claude from auto-triggering (default: false) |
| `model` | No | Override model for this skill execution |
| `context` | No | `fork` runs in isolated context, `agent` runs as subagent |
| `effort` | No | Hints at expected complexity: low, medium, high |

---

## Dynamic Variables

Skills can access these variables at runtime:

### Built-in Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | User-provided arguments after skill name | `"/my-skill foo bar"` → `"foo bar"` |
| `$CLAUDE_SKILL_DIR` | Absolute path to skill directory | `/home/user/.claude/skills/my-skill` |
| `$CLAUDE_WORKING_DIR` | Current working directory | `/home/user/my-project` |
| `$CLAUDE_SESSION_ID` | Current session identifier | `abc123xyz` |

### Usage in SKILL.md

```markdown
## Instructions

1. The user requested: $ARGUMENTS
2. Skill assets are in: $CLAUDE_SKILL_DIR
3. Working directory: $CLAUDE_WORKING_DIR
```

---

## Dynamic Context Injection

Use `!` prefix to inject command output into skill context:

```markdown
## Project Context

Current git branch:
!`git branch --show-current`

Package manager detected:
!`if [ -f "bun.lockb" ]; then echo "bun"; elif [ -f "pnpm-lock.yaml" ]; then echo "pnpm"; else echo "npm"; fi`

Recent commits:
!`git log --oneline -5`
```

The backtick commands are executed when the skill loads, and output is injected inline.

### Best Practices for Dynamic Context

1. **Keep commands fast** - they run synchronously
2. **Handle errors gracefully** - use `|| echo "fallback"`
3. **Limit output size** - pipe through `head` or `tail` if needed
4. **Don't expose secrets** - avoid echoing env vars

---

## Skills as Subagents

Skills can spawn as isolated subagents using `context: agent`:

```yaml
---
name: code-reviewer
context: agent
model: sonnet
---
```

When invoked, this skill runs as a subagent with:
- Isolated context (doesn't pollute main conversation)
- Can use different model than parent
- Returns summary to parent when complete

### When to Use Agent Context

| Scenario | Context |
|----------|---------|
| Quick lookups, simple tasks | Default (inline) |
| Long-running analysis | `agent` |
| Tasks that generate lots of output | `agent` |
| Tasks needing different model | `agent` |

---

## Skill Directory Structure

```
my-skill/
├── SKILL.md              # Required - main skill definition
├── scripts/              # Optional - executable scripts
│   ├── setup.sh
│   └── validate.py
├── references/           # Optional - supporting docs
│   ├── patterns.md
│   └── examples.md
├── assets/               # Optional - templates, configs
│   └── template.json
└── templates/            # Optional - project scaffolds
    └── typescript/
        ├── CLAUDE.md
        └── .claude/
```

### File Limits

| Constraint | Limit |
|------------|-------|
| SKILL.md words | < 5,000 |
| SKILL.md lines | < 500 |
| Total skill size | < 1MB |
| No binary files | Images, executables not allowed |

---

## Publishing Skills

### As ZIP File

```bash
# Create zip without .git and node_modules
zip -r my-skill.zip my-skill/ -x "*.git*" -x "*node_modules*" -x "*.DS_Store"
```

### As GitHub Repo

1. Create repo with skill at root
2. Users install via: `claude skills add github:user/repo`

### Skill Registry

Submit to official registry (coming soon):
1. Fork anthropic/claude-skills
2. Add skill to registry.json
3. Submit PR

---

## Validation

Run validation before publishing:

```bash
# Using the validate script
bash scripts/validate-skill.sh .

# Manual checks
cat SKILL.md | head -20           # Check frontmatter
wc -w SKILL.md                    # Word count
cat SKILL.md | jq .               # Would fail if YAML invalid
```

### Common Validation Errors

| Error | Fix |
|-------|-----|
| Name not kebab-case | Use `my-skill-name` not `mySkillName` |
| Description too long | Keep under 1024 chars |
| Missing frontmatter | Start file with `---` |
| Reserved name | Can't use `claude` or `anthropic` in name |
| XML tags in frontmatter | Remove any `<tags>` from YAML section |
