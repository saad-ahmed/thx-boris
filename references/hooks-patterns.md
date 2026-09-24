# Hook Patterns

Working hook configurations for `.claude/settings.json`. Every snippet is a complete file, or a fragment that merges under the top-level `"hooks"` key.

## Contents
- How hooks work (structure, matchers, `if`, input, exit codes)
- PostToolUse: format and lint
- PreToolUse: gates and guards
- Stop, Notification, and SessionStart hooks
- Complete configs (TypeScript, Python, Go)
- Hooks in skills and subagents
- Best practices
- Debugging
- Old patterns (don't use)

---

## How hooks work

### Structure

```json
{
  "hooks": {
    "<Event>": [
      {
        "matcher": "<tool-name pattern>",
        "hooks": [
          { "type": "command", "if": "<permission rule>", "command": "<shell>", "timeout": 60 }
        ]
      }
    ]
  }
}
```

The three levels are: **event** → **matcher group** → **handlers**. The whole thing sits under `"hooks"`. Events placed at the top level of settings.json are silently ignored.

Where hooks can live: `~/.claude/settings.json` (you), `.claude/settings.json` (team, committed), `.claude/settings.local.json` (you, gitignored), managed policy, plugin `hooks/hooks.json`, and skill or subagent frontmatter.

### Events you'll use most

| Event | Fires | Can block? |
|-------|-------|-----------|
| `PreToolUse` | Before a tool runs | **Yes** (exit 2 or `permissionDecision: "deny"`) |
| `PostToolUse` | After a tool succeeds | No (it has already happened); can feed context back to Claude |
| `UserPromptSubmit` | Before a prompt is processed | Yes |
| `Stop` / `SubagentStop` | When Claude finishes responding | Can ask Claude to keep going (`decision: "block"`) |
| `Notification` | Claude needs attention | No |
| `SessionStart` | startup / resume / clear / compact | No; stdout is added to context |
| `PreCompact`, `SessionEnd`, `PermissionRequest`, `FileChanged`, … | See `/hooks` | Varies |

### Matcher vs. `if`

- `matcher` matches the **tool name** for tool events: `Bash`, `Write|Edit`, `mcp__github__.*`, `*`.
- `if` filters by **arguments** using permission-rule syntax. It only applies to tool events.

```json
{ "matcher": "Bash", "hooks": [{ "type": "command", "if": "Bash(git commit *)", "command": "..." }] }
{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "if": "Edit(*.ts)", "command": "..." }] }
```

`"matcher": "Bash(git commit*)"` is **wrong**. Matchers never see arguments.

### Input: JSON on stdin

Hooks don't get `$FILE_PATH`, `$TOOL_INPUT`, or similar env vars. They get JSON on stdin:

```json
{
  "session_id": "abc123",
  "hook_event_name": "PostToolUse",
  "cwd": "/home/user/project",
  "tool_name": "Edit",
  "tool_input": { "file_path": "/home/user/project/src/app.ts", "...": "..." }
}
```

Extract fields with jq:

```bash
f=$(jq -r '.tool_input.file_path // empty')
```

Use `${CLAUDE_PROJECT_DIR}` to reference scripts regardless of cwd.

### Exit codes

| Exit | Meaning |
|------|---------|
| `0` | Success. JSON on stdout is parsed for decisions; plain stdout goes to the debug log (except `SessionStart`/`UserPromptSubmit`, where it's added to context) |
| **`2`** | **Blocking error.** stderr is sent to Claude as the reason; the action is blocked on blockable events |
| anything else | Non-blocking error. The action proceeds and the first stderr line is shown |

**A test gate that exits 1 does not block.** End gates with `|| exit 2`.

### Handler types

`command` (shell), `http` (POST JSON to a URL), `mcp_tool` (call an MCP tool), `prompt` (ask a fast model yes/no), and `agent` (spawn a verifier subagent; experimental). Useful fields: `timeout` (seconds), `statusMessage`, `async: true` (don't wait), and `once: true` (skill frontmatter only).

---

## PostToolUse: format and lint

### Format only the edited file (fast)

`.claude/hooks/format.sh`:

```bash
#!/usr/bin/env bash
# Formats the file Claude just edited. Never fails the tool call.
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] || [ ! -f "$f" ] && exit 0
grep -q '@generated' "$f" 2>/dev/null && exit 0
case "$f" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md) npx prettier --write "$f" ;;
  *.py) ruff format "$f" && ruff check --fix "$f" ;;
  *.go) gofmt -w "$f" ;;
  *.rs) rustfmt "$f" ;;
esac >/dev/null 2>&1
exit 0
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/format.sh\"" }]
      }
    ]
  }
}
```

### Whole-project formatter (simple, slower)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "npm run format >/dev/null 2>&1 || true" }]
      }
    ]
  }
}
```

### Feed lint errors back to Claude

A PostToolUse hook that exits 2 can't undo the edit, but its stderr reaches Claude, so Claude fixes the error on its next step:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "if": "Edit(*.ts)",
          "command": "f=$(jq -r '.tool_input.file_path'); npx eslint \"$f\" >&2 || exit 2"
        }]
      }
    ]
  }
}
```

---

## PreToolUse: gates and guards

### Block commits unless checks pass

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "if": "Bash(git commit *)",
          "command": "npm run lint >&2 && npm run typecheck >&2 && npm test >&2 || { echo 'Checks failed. Fix them before committing.' >&2; exit 2; }",
          "timeout": 300,
          "statusMessage": "Running pre-commit checks..."
        }]
      }
    ]
  }
}
```

### Block pushes to main

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "if": "Bash(git push *)",
          "command": "cmd=$(jq -r '.tool_input.command'); case \"$cmd\" in *' main'*|*' master'*|*--force*|*' -f'*) echo 'Direct/force push to main is blocked. Push a branch and open a PR.' >&2; exit 2;; esac"
        }]
      }
    ]
  }
}
```

### Protect files from edits (JSON decision form)

```bash
#!/usr/bin/env bash
# .claude/hooks/protect.sh: deny edits to lockfiles, .env, and migrations already applied
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  *.env|*.env.*|*package-lock.json|*pnpm-lock.yaml|*/migrations/applied/*)
    jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:("Protected file: " + $f)}}'
    ;;
esac
exit 0
```

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/protect.sh\"" }] }
    ]
  }
}
```

`permissionDecision` can be `allow`, `deny`, or `ask`. `updatedInput` can rewrite the tool input before it runs.

### Require tests for changed source files

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "if": "Bash(git commit *)",
          "command": "missing=$(git diff --cached --name-only --diff-filter=A | grep -E '^src/.*\\.ts$' | grep -v '\\.test\\.' | while read f; do [ -f \"${f%.ts}.test.ts\" ] || echo \"$f\"; done); [ -z \"$missing\" ] || { echo \"Missing tests for: $missing\" >&2; exit 2; }"
        }]
      }
    ]
  }
}
```

---

## Stop, Notification, and SessionStart hooks

### Desktop notification when Claude needs you

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [{
          "type": "command",
          "command": "osascript -e 'display notification \"Claude needs your attention\" with title \"Claude Code\"' 2>/dev/null || notify-send 'Claude Code' 'Claude needs your attention' 2>/dev/null || true"
        }]
      }
    ]
  }
}
```

### Don't let Claude stop with failing tests

`Stop` can send Claude back to work. Check `stop_hook_active` to avoid loops:

```bash
#!/usr/bin/env bash
# .claude/hooks/stop-gate.sh
[ "$(jq -r '.stop_hook_active')" = "true" ] && exit 0
npm test >/dev/null 2>&1 && exit 0
echo "Tests are failing. Fix them before finishing." >&2
exit 2
```

```json
{ "hooks": { "Stop": [ { "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-gate.sh\"" }] } ] } }
```

### Log sessions

```json
{
  "hooks": {
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "jq -r '\"\\(.session_id) ended \\(now|todate)\"' >> ~/.claude/session.log" }] }
    ]
  }
}
```

### Inject context at startup

stdout from a `SessionStart` hook is added to Claude's context:

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [{ "type": "command", "command": "echo \"Branch: $(git branch --show-current)\"; git log --oneline -5" }] }
    ]
  }
}
```

---

## Complete configs

### TypeScript (pnpm)

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "pnpm format >/dev/null 2>&1 || true" }] }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "if": "Bash(git commit *)", "command": "pnpm lint >&2 && pnpm typecheck >&2 && pnpm test >&2 || exit 2", "timeout": 300 }]
      }
    ]
  }
}
```

### Python (uv + ruff)

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "if": "Edit(*.py)", "command": "f=$(jq -r '.tool_input.file_path'); ruff format \"$f\" >/dev/null 2>&1; ruff check --fix \"$f\" >/dev/null 2>&1; true" }] }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "if": "Bash(git commit *)", "command": "ruff check . >&2 && mypy . >&2 && pytest -q >&2 || exit 2", "timeout": 300 }]
      }
    ]
  }
}
```

### Go

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "if": "Edit(*.go)", "command": "gofmt -w \"$(jq -r '.tool_input.file_path')\" 2>/dev/null; true" }] }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "if": "Bash(git commit *)", "command": "go vet ./... >&2 && go test ./... >&2 && golangci-lint run >&2 || exit 2", "timeout": 300 }]
      }
    ]
  }
}
```

---

## Hooks in skills and subagents

Frontmatter hooks use the same shape in YAML. Skill hooks stay active for the rest of the session after the skill runs. Subagent hooks only run while that subagent does, and a subagent's `Stop` becomes `SubagentStop`.

```yaml
---
name: safe-migrations
description: Runs database migrations with a safety check. Use when applying migrations.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          if: "Bash(*migrate*)"
          command: "bash ${CLAUDE_SKILL_DIR}/scripts/check-backup.sh || exit 2"
---
```

---

## Best practices

- **Gates exit 2**, and their stderr explains what to fix. Claude reads it.
- **PostToolUse hooks work on the edited file only** and stay under ~2 s. Use `>/dev/null 2>&1 || true` for pure formatters.
- **Narrow with `if`** instead of running on every `Bash` call.
- **Put logic in scripts** (`.claude/hooks/*.sh`) referenced through `${CLAUDE_PROJECT_DIR}`. JSON strings are painful to quote.
- **Set a `timeout`** on slow gates, and a `statusMessage` so the user knows what's running.
- **Hooks run with your credentials.** Review hook changes in PRs like code.
- Kill switch: `"disableAllHooks": true`.

---

## Debugging

```bash
jq . .claude/settings.json                    # Valid JSON?
jq '.hooks | keys' .claude/settings.json      # Events under "hooks"?
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/a.ts"}}' | bash .claude/hooks/format.sh; echo "exit=$?"
claude --debug                                # Watch hook execution and stderr
```

In a session, `/hooks` lists what's registered and where it came from.

---

## Old patterns (don't use)

<details>
<summary>Legacy snippets that silently fail</summary>

- Events at the settings.json top level (`{"PostToolUse": [...]}`) → nest them under `"hooks"`.
- `"matcher": "Bash(git commit*)"` → `"matcher": "Bash"` + `"if": "Bash(git commit *)"`.
- `$FILE_PATH`, `$FILE`, `$CHANGED_FILE`, `$TOOL_INPUT` env vars → read stdin with `jq`.
- A gate like `npm test` with no `|| exit 2` → exits 1 and doesn't block.
- `CLAUDE_DEBUG_HOOKS=1` → `claude --debug`.

</details>
