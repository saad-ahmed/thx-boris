# thx-boris

Boris Cherny, creator of Claude Code, shows how he uses Claude Code to build Claude Code. This is a skill to package up that information.

Full tweet content can be found here

https://x.com/bcherny/status/2007179832300581177

## What's inside

| Path | Purpose |
|------|---------|
| `SKILL.md` | Entry point: workflow, core patterns, quick reference |
| `references/` | Hooks, subagents, skill authoring, sessions/permissions/MCP, troubleshooting, anti-patterns |
| `assets/` | Ready-to-copy subagents and a CLAUDE.md template |
| `templates/` | Complete TypeScript and Python project setups |
| `scripts/` | `setup-project.sh`, `validate-skill.sh`, `validate-claude-md.sh` |
| `evals/` | Evaluation scenarios for testing the skill |

## Install

- **Claude Code:** clone into `~/.claude/skills/thx-boris/` (personal) or `.claude/skills/thx-boris/` (project).
- **claude.ai / Skills API:** zip the folder (excluding `.git`, `README.md`, and `evals/`) and upload it. The frontmatter uses only portable Agent Skills fields.

## Validate

```bash
bash scripts/validate-skill.sh .
```
