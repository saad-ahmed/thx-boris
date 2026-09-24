# Sessions, Permissions & MCP

How to resume sessions, run Claude headless, set up permissions, and connect MCP servers.

## Contents
- Sessions (resume, headless/CI)
- Permissions (modes, allow/deny rules, what never to allow)
- MCP servers (.mcp.json, scopes, debugging)

---

## Sessions

### Resume

```bash
claude -c                      # Continue the most recent conversation in this directory
claude -r                      # Pick a past session from a list
claude -r "<id-or-name>" "next step"   # Resume a specific session with a prompt
```

In a session: `/resume` switches sessions, `/rename` names the current one so it's easy to find, `/clear` starts fresh, and `/compact` summarizes to free context.

### Headless / CI

```bash
claude -p "fix all TypeScript errors" --output-format json
claude -p "summarize failures" --output-format stream-json
cat build.log | claude -p "why did this fail?"            # Pipe input via stdin
claude -p "run the release checklist" --max-turns 20 \
  --allowedTools "Bash(npm run *)" "Read" --permission-mode acceptEdits
```

`--output-format` accepts `text`, `json`, or `stream-json`. Pass files to headless runs through stdin or by naming their paths in the prompt.

### Practices

1. **Name long-lived sessions** with `/rename` and resume them by name.
2. **Clear between unrelated tasks.** Stale context degrades results more than a fresh start does.
3. **Use `-p` in CI**, always with a narrow `--allowedTools` and a `--max-turns` cap.

---

## Permissions

### Modes

Cycle with `Shift+Tab` or set `--permission-mode`:

| Mode | Behavior |
|------|----------|
| `default` | Prompts for edits and commands not already allowed |
| `acceptEdits` | Auto-accepts file edits; still prompts for commands |
| `plan` | Read-only planning; no edits |
| `auto` | A classifier approves routine actions and escalates risky ones |
| `dontAsk` | Denies anything not pre-allowed (for CI) |
| `bypassPermissions` | No checks. Only in throwaway sandboxes |

### Rules

Manage them with `/permissions`, or in settings:

```json
{
  "permissions": {
    "allow": ["Bash(npm run test *)", "Bash(git diff *)", "WebFetch(domain:docs.example.com)"],
    "ask":   ["Bash(git push *)"],
    "deny":  ["Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)", "Bash(curl *)"]
  }
}
```

- Precedence is **deny > ask > allow**.
- `Bash(cmd *)` matches `cmd` followed by arguments. The space before `*` matters: `Bash(ls *)` doesn't match `lsof`.
- **`permissions.deny` with `Read(...)` is how you hide files** from Claude. There is no `.claudeignore`. File search already respects `.gitignore`.
- Shared rules go in `.claude/settings.json` (committed). Personal ones go in `.claude/settings.local.json` (gitignored) or `~/.claude/settings.json`.

### Safe to pre-allow

```
Bash(npm run build *)   Bash(npm run lint *)   Bash(npm run test *)
Bash(pnpm build *)      Bash(pnpm lint *)      Bash(pnpm test *)
Bash(git status *)      Bash(git diff *)       Bash(git log *)
Bash(git branch *)      Bash(git show *)
```

Claude's built-in Read, Grep, and Glob tools don't need Bash rules for `cat`, `grep`, or `find`.

### Never pre-allow

```
Bash(*)                 Bash(rm -rf *)         Bash(sudo *)
Bash(git push --force *)  Bash(git reset --hard *)
Bash(curl * | bash)     Bash(chmod 777 *)
```

---

## MCP servers

### Add servers

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport stdio postgres -- npx -y @modelcontextprotocol/server-postgres postgresql://localhost/mydb
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/
claude mcp list
```

Scopes: `local` (default, just you in this project), `project` (written to `.mcp.json` and committed), and `user` (you, across all projects).

### `.mcp.json` (project scope)

```json
{
  "mcpServers": {
    "sentry": { "type": "http", "url": "https://mcp.sentry.dev/mcp" },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    }
  }
}
```

The top-level key is **`mcpServers`**. `${VAR}` and `${VAR:-default}` expand from the environment, so never commit tokens.

### Using MCP tools

- Tool names are `mcp__<server>__<tool>`, e.g. `mcp__github__create_issue`. Use the full name in hook matchers, permission rules, and skill instructions.
- `/mcp` shows server status and handles OAuth logins.
- Only enable the servers a project needs. Every server's tool list costs context.

### Debugging

```bash
claude --debug=mcp             # Log MCP startup and errors
claude mcp list                # Configured servers and health
jq . .mcp.json                 # Valid JSON?
```
