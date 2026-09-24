---
name: thx-boris
description: Applies production-tested Claude Code workflow patterns from the Claude Code team - living CLAUDE.md files, subagents, hooks, permissions, skills, parallel sessions with git worktrees, and MCP servers. Use when setting up Claude Code for a project, writing or fixing .claude/settings.json hooks, creating subagents or skills, reducing permission prompts, or running several Claude sessions in parallel. Not for general coding or debugging unrelated to Claude Code configuration.
license: MIT
compatibility: Claude Code (CLI, desktop, web), claude.ai, and the Skills API. Bundled scripts need bash; jq is optional for JSON checks.
metadata:
  author: saad-ahmed
  version: "4.0.0"
  category: developer-tools
  tags: "claude-code, workflow, automation, devtools"
---

# thx-boris: Claude Code Mastery

Production-tested patterns for getting the most out of Claude Code, based on how the Claude Code team uses it.

## Workflow

Copy this checklist and track progress:

```
Progress:
- [ ] Step 1: Identify the goal
- [ ] Step 2: Apply the pattern
- [ ] Step 3: Validate (fix and re-run until clean)
```

**Step 1: Identify the goal.** Pick the row that matches the request and read only that reference.

| Goal | Section below | Reference |
|------|---------------|-----------|
| Set up a new project | Living CLAUDE.md | [assets/claude-md-template.md](assets/claude-md-template.md), [templates/](templates/) |
| Create a subagent | Subagents | [references/subagent-templates.md](references/subagent-templates.md) |
| Configure hooks | Hooks | [references/hooks-patterns.md](references/hooks-patterns.md) |
| Permissions, sessions, MCP | — | [references/session-and-mcp.md](references/session-and-mcp.md) |
| Run parallel sessions | Parallel sessions | — |
| Write a skill | Skills | [references/skill-authoring.md](references/skill-authoring.md) |
| Fix something broken | Troubleshooting | [references/troubleshooting.md](references/troubleshooting.md) |
| Avoid common mistakes | — | [references/anti-patterns.md](references/anti-patterns.md) |

**Step 2: Apply the pattern** from the matching section.

**Step 3: Validate.** Run the matching script, fix every error, and run it again. Continue only when it passes.

| What changed | Validator |
|--------------|-----------|
| A skill folder | `bash scripts/validate-skill.sh <skill-dir>` |
| `CLAUDE.md` | `bash scripts/validate-claude-md.sh <CLAUDE.md>` |
| `.claude/settings.json` | `jq . .claude/settings.json` (valid JSON, and hooks sit under a top-level `"hooks"` key) |

To bootstrap a project in one step, run `bash scripts/setup-project.sh <project-dir> <npm|pnpm|bun|yarn|auto>`.

---

## Living CLAUDE.md

**Core principle:** every mistake Claude makes becomes a permanent lesson.

```
Claude makes a mistake → a human notices → add a line to CLAUDE.md → Claude stops repeating it
```

Structure:

```markdown
# Development Workflow

**Always use `[package-manager]`, not `[alternative]`.**

## Commands
[Ordered by how often they're used]

## Code Style
[Project-specific patterns]

## Anti-Patterns
[Things Claude got wrong. Add new ones as they come up]

## Domain Knowledge
[Context Claude can't infer from the code]
```

Example anti-pattern entry:

```markdown
- Don't use `enum` for union types. Use `type Status = 'active' | 'inactive'`.
```

Team rules:
1. Commit `CLAUDE.md` to git; keep personal notes in `CLAUDE.local.md` (gitignored).
2. Review `CLAUDE.md` changes in PRs like code.
3. Keep it short. Every line costs context in every session. Move long details into files and point to them.
4. Put rules for one area of the code in `.claude/rules/*.md` scoped with `paths:` frontmatter rather than growing the root file.

Starter: [assets/claude-md-template.md](assets/claude-md-template.md).

---

## Subagents

Subagents are specialized Claude instances with their own context window and tool set. They live in `.claude/agents/<name>.md` (project) or `~/.claude/agents/` (personal).

**Every agent file needs YAML frontmatter with `name` and `description`.** Claude Code silently skips files without them.

```markdown
---
name: build-validator
description: Verifies typecheck, lint, and tests pass. Use before committing or opening a PR.
tools: Read, Grep, Glob, Bash
model: sonnet
---

Run the typecheck, linter, and tests. Report each failure with file:line and a suggested fix.
```

| Task | Subagent? | Why |
|------|-----------|-----|
| Repeated validation | Yes | Consistent checks |
| Review against a checklist | Yes | Focused expertise |
| Large search or research | Yes | Keeps main context clean |
| One-off task | No | Not worth the overhead |

Ready-to-copy agents in [assets/agents/](assets/agents/): `build-validator`, `code-simplifier`, `verify-app`, `dependency-updater`, `migration-runner`, `security-scanner`. More templates (code-architect, oncall-guide, pr-reviewer, test-writer) are in [references/subagent-templates.md](references/subagent-templates.md).

---

## Hooks

Hooks run shell commands (or HTTP, MCP, prompt, and agent handlers) at lifecycle events. Configure them in `.claude/settings.json` **under a top-level `"hooks"` key**.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "npm run format >/dev/null 2>&1 || true" }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "if": "Bash(git commit *)",
          "command": "npm run lint >&2 && npm test >&2 || exit 2"
        }]
      }
    ]
  }
}
```

Rules that matter:
- `matcher` matches the **tool name** (`Write|Edit`, `Bash`, `mcp__github__.*`). Filter by arguments with `if` using permission-rule syntax (`Bash(git commit *)`, `Edit(*.ts)`).
- **Only exit code 2 blocks** (on `PreToolUse`, `UserPromptSubmit`, and a few others). Exit 1 is a non-blocking error, so a gate must end with `|| exit 2` and write its reason to stderr.
- Hook input arrives as **JSON on stdin**. There is no `$FILE_PATH` env var. Read it with `jq -r '.tool_input.file_path'`.
- `PostToolUse` runs after the tool has already finished, so it can't undo anything. Use `|| true` there to keep failure noise out of the transcript.

Full patterns for formatting, gating, notifications, and Stop hooks: [references/hooks-patterns.md](references/hooks-patterns.md).

---

## Parallel Sessions

Several Claudes running at once raises throughput. Give each one its own checkout so they never edit the same files.

```bash
git worktree add ../myproject-feature-a -b feature-a
git worktree add ../myproject-feature-b -b feature-b
(cd ../myproject-feature-a && claude)   # in one terminal tab
(cd ../myproject-feature-b && claude)   # in another
```

Suggested terminal layout:

```
Tab 1-3: Claude sessions, one per worktree/task
Tab 4:   dev server / build watcher
Tab 5:   git and manual commands
```

Split work by boundary, not by size:

```
Bad:  "Implement the entire authentication system"
Good: Claude 1: auth API · Claude 2: auth UI · Claude 3: auth tests
```

Also useful: subagents with `isolation: worktree` get a temporary worktree automatically, and background tasks let one session keep working while another job runs.

---

## Skills

Skills are the current way to package repeatable workflows. Put them in `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (personal). Legacy `.claude/commands/*.md` files still work, but prefer skills for new work because they can bundle scripts and references.

```markdown
---
name: commit-push-pr
description: Commits staged work, pushes the branch, and opens a PR. Use when the user asks to ship or open a PR.
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git push *) Bash(gh pr create *)
---

Current status:
!`git status --short`

Commit with a descriptive message, push with `git push -u origin HEAD`, then open a PR.
```

The essentials (details in [references/skill-authoring.md](references/skill-authoring.md)):
- The `description` decides whether the skill triggers. Write it in the third person and say both **what** it does and **when** to use it.
- Keep `SKILL.md` under 500 lines. Move detail into reference files linked **one level deep** from `SKILL.md`.
- Only `name`, `description`, `license`, `compatibility`, `metadata`, and `allowed-tools` are portable. Other fields (`context`, `agent`, `effort`, `model`, `hooks`, `paths`, `argument-hint`, ...) are Claude Code extensions and break uploads to claude.ai or the API.
- Write at least three evaluations before writing extensive instructions. This skill's evals are in [evals/evals.json](evals/evals.json).

---

## Examples

**"Set up Claude Code for my Next.js project"**
1. Run `bash scripts/setup-project.sh . auto`.
2. Copy `assets/claude-md-template.md` to `CLAUDE.md`, then fill in the commands and style.
3. Copy relevant agents from `assets/agents/` to `.claude/agents/`.
4. Validate: `jq . .claude/settings.json` and `bash scripts/validate-claude-md.sh CLAUDE.md`.

Working example: [templates/typescript-project/](templates/typescript-project/).

**"Create a code-review subagent"**
1. Copy the pr-reviewer template from `references/subagent-templates.md` to `.claude/agents/pr-reviewer.md`.
2. Confirm the frontmatter has `name` and `description`, then narrow `tools` to `Read, Grep, Glob, Bash`.

**"My commit hook doesn't block failing tests"**
1. Check that the config sits under `"hooks"` and the matcher is `Bash` with `"if": "Bash(git commit *)"`.
2. Make the command end with `|| exit 2`. Exit 1 never blocks.

Working example: [templates/python-project/](templates/python-project/).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Hooks never run | Events at the top level of settings.json | Nest them under `"hooks"`; check with `/hooks` |
| Gate hook doesn't block | Exits 1 | End with `\|\| exit 2` |
| Subagent missing from `/agents` | No frontmatter, or no `name`/`description` | Add frontmatter on line 1 |
| Skill never triggers | Vague description | Add concrete trigger phrases and file types |
| Skill over-triggers | Description too broad | Narrow the scope; add "Not for ..." |
| CLAUDE.md ignored | Too long or vague | Trim it; use imperative bullets |

More: [references/troubleshooting.md](references/troubleshooting.md).

---

## Model Selection

- **Default to the most capable Opus model** (`/model opus`) for complex work. It needs less steering, uses tools better, and makes fewer mistakes, so tasks finish faster overall.
- Use **Sonnet** for well-defined, high-volume work, and **Haiku** for cheap, fast subagents (search, lint triage).
- Adjust depth with `/effort` (`low` … `max`) instead of switching models for every task.
- Set a per-subagent `model:` in its frontmatter.

---

## Quick Reference

| Task | Solution |
|------|----------|
| Claude repeats a mistake | Add it to CLAUDE.md |
| Repetitive workflow | Skill in `.claude/skills/` |
| Specialized worker | Subagent in `.claude/agents/` |
| Auto-format code | PostToolUse hook, matcher `Write\|Edit` |
| Block bad commits | PreToolUse hook, `if: Bash(git commit *)`, `exit 2` |
| Fewer permission prompts | `/permissions`, or `permissions.allow` in settings |
| Hide secrets from Claude | `permissions.deny: ["Read(./.env)"]` |
| Big feature | Parallel Claudes in git worktrees |
| Side-effect workflow | Skill with `disable-model-invocation: true` |
| Isolated research | Skill with `context: fork` + `agent: Explore` |
