# Troubleshooting

Common Claude Code problems and how to fix them. Start with `/doctor` (in a session) or `claude doctor` (in a terminal).

## Contents
- Installation and auth
- Hooks
- Subagents and skills
- CLAUDE.md and settings
- Context and performance
- MCP
- Sessions
- Git mishaps
- Getting help

---

## Installation and auth

**`claude: command not found`**
```bash
curl -fsSL https://claude.ai/install.sh | bash   # Native installer (recommended)
claude doctor                                     # Checks install, PATH, and auto-update
```
An old npm global install can shadow the native binary. Run `which -a claude` and remove the stale one.

**Auth errors / "Invalid API key"**
- Run `/login` in a session to switch between a claude.ai subscription and Console/API auth.
- If `ANTHROPIC_API_KEY` is set in your shell, it overrides subscription login. Unset it if that's not what you want.

---

## Hooks

**Hooks never run**
1. `jq '.hooks | keys' .claude/settings.json`: events must sit **under `"hooks"`**, not at the top level.
2. `/hooks` in a session lists what actually registered.
3. `matcher` matches **tool names** only (`Bash`, `Write|Edit`). Move argument filters to `"if": "Bash(git commit *)"`.
4. `claude --debug` shows each hook's execution and stderr.

**A gate hook doesn't block**
It exits 1. Only **exit 2** blocks. End the command with `|| exit 2`.

**A hook can't find the file path**
There are no `$FILE_PATH`/`$TOOL_INPUT` env vars. Read stdin: `jq -r '.tool_input.file_path'`.

**Hooks are slow**
Format only the edited file, add `if` filters, and move long checks to `Stop` or `async: true`.

---

## Subagents and skills

**Subagent doesn't appear in `/agents`**
The file must start with `---` frontmatter containing both `name` and `description`. Without them it's skipped silently, and `claude --debug` logs the reason.

**Skill never triggers**
- The description is too vague. Add what it does, "Use when …", and concrete keywords or file types.
- `paths:` globs may be too narrow.
- Check `/skills` to confirm it loaded and isn't set to `off`.
- `/skill-doctor` shows invocation counts and context cost.
- `/skill-name` always works manually.

**Skill triggers too often**
Narrow the description and add "Not for …". For side-effect skills, set `disable-model-invocation: true`.

**Skill fails with "Shell command failed for pattern"**
An `` !`command` `` injection exited non-zero. Append `|| true`, or fix the command.

**Upload to claude.ai / API fails**
Frontmatter contains Claude Code-only fields. Keep only `name`, `description`, `license`, `compatibility`, `metadata`, and `allowed-tools`.

---

## CLAUDE.md and settings

**Claude ignores CLAUDE.md**
- It must be named `CLAUDE.md` exactly, at the project root (or `.claude/CLAUDE.md`). Run `/memory` to see which files loaded.
- It's too long or too vague. Trim it to imperative bullets and move details to linked files or `.claude/rules/`.
- Contradictory instructions: remove the stale one.

**Settings don't apply**
- Validate with `jq . .claude/settings.json`.
- Precedence is managed > CLI args > `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.json`.
- `/config` and `/permissions` show the effective values.

---

## Context and performance

**Responses degrade in long sessions**
`/clear` between unrelated tasks, `/compact` to summarize, and `/context` to see what's using space.

**Claude reads irrelevant or sensitive files**
Add `permissions.deny` rules such as `Read(./dist/**)` or `Read(./.env)`. There is no `.claudeignore`, and `.gitignore`d files are already excluded from file search.

**Slow overall**
Delegate broad searches to subagents (`Explore`), keep MCP servers to the ones you need, and lower `/effort` for simple tasks.

---

## MCP

**MCP tools missing**
1. `/mcp` shows status and handles auth.
2. `claude mcp list` checks configured servers.
3. `jq . .mcp.json`: the top-level key must be `mcpServers`.
4. `claude --debug=mcp` logs startup errors.

---

## Sessions

**Can't find an old session**
`claude -r` opens a picker. Name sessions with `/rename` so you can run `claude -r <name>` later.

**Context vanished mid-task**
Auto-compaction summarized it. Re-state the key constraints, or put durable ones in CLAUDE.md.

---

## Git mishaps

**Claude committed to the wrong branch**
```bash
git branch correct-branch          # Keep the commit on a new branch
git reset --keep HEAD~1            # Remove it from the current branch
git switch correct-branch
```

**Undo Claude's edits**
Use `/rewind` (or press `Esc` twice) to restore code and conversation to an earlier checkpoint. For edits made by background subagents, use `git restore <file>`.

---

## Getting help

- `/doctor` for diagnostics
- Docs: https://code.claude.com/docs
- Issues: https://github.com/anthropics/claude-code/issues
