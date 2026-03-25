# Session Management & MCP Integration

Reference guide for Claude Code sessions and MCP server configuration.

---

## Session Management

### Basic Commands

```bash
# Resume last session
claude --continue

# Resume specific session
claude --resume SESSION_ID

# List sessions
claude sessions list

# Clear old sessions
claude sessions clear
```

### Headless / CI Mode

```bash
# Run prompt and exit
claude -p "fix all TypeScript errors" --output-format json

# Streaming output
claude -p "run tests" --output-format stream

# With file input
claude -p "review this code" --file src/api.ts
```

### Session Best Practices

1. **Resume sessions** to maintain context across interactions
2. **Use headless mode** for CI/CD pipelines and automated tasks
3. **Clear sessions periodically** to free disk space

---

## MCP Integration

Connect Claude to external services via MCP (Model Context Protocol) servers.

### Configuration

Configure in `.mcp.json` at project root:

```json
{
  "servers": {
    "slack": {
      "url": "http://localhost:3001",
      "auth": {
        "type": "bearer",
        "token": "${SLACK_MCP_TOKEN}"
      }
    },
    "github": {
      "url": "http://localhost:3002",
      "auth": {
        "type": "bearer",
        "token": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### Common MCP Servers

| MCP Server | Use Case | Tools Provided |
|------------|----------|----------------|
| Slack | Team communication | send_message, read_channel, search |
| Google Drive | Document access | read_doc, write_doc, list_files |
| GitHub | Repository management | create_issue, comment_pr, search_code |
| Sentry | Error tracking | get_issue, list_errors, resolve |
| PostgreSQL | Database queries | query, schema, explain |
| Puppeteer | Browser automation | screenshot, navigate, click |

### MCP Debugging

```bash
# Enable MCP debug logging
CLAUDE_DEBUG_MCP=1 claude

# Check MCP server health
curl <mcp-server-url>/health

# Validate .mcp.json
cat .mcp.json | jq .
```

### MCP Best Practices

1. **Use environment variables** for tokens and secrets
2. **Run MCP servers locally** for development
3. **Limit scope** - only enable servers you need
4. **Monitor usage** - MCP calls count against rate limits

---

## Permission Optimization

Pre-allow safe commands to reduce friction.

### Access Permissions

Use `/permissions` command to manage:

```bash
# View current permissions
/permissions

# Allow specific command
/permissions allow Bash(npm run test)

# Deny dangerous command
/permissions deny Bash(rm -rf *)
```

### Safe to Pre-Allow

```
# Build & test commands
Bash(bun run build:*)
Bash(bun run lint:*)
Bash(bun run test:*)
Bash(npm run build:*)
Bash(npm run lint:*)
Bash(npm run test:*)
Bash(yarn build:*)
Bash(pnpm build:*)

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
Bash(ls:*)
Bash(tree:*)
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

For permissions that shouldn't be committed, use `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(my-personal-script)"
    ]
  }
}
```

This file should be in `.gitignore`.
