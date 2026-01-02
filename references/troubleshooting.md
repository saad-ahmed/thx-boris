# Troubleshooting

Common issues and solutions when using Claude Code.

---

## Installation & Setup

### Claude Code not found after install

**Symptom:** `claude: command not found`

**Solutions:**
```bash
# 1. Check if installed globally
npm list -g @anthropic-ai/claude-code

# 2. Ensure npm global bin is in PATH
export PATH="$PATH:$(npm config get prefix)/bin"

# 3. Or use npx
npx @anthropic-ai/claude-code
```

### API key not working

**Symptom:** "Invalid API key" or "Unauthorized"

**Solutions:**
```bash
# 1. Verify key is set
echo $ANTHROPIC_API_KEY

# 2. Re-authenticate
claude auth login

# 3. Check key format (should start with sk-ant-)
```

### Permission denied errors

**Symptom:** Can't create/edit files

**Solutions:**
```bash
# 1. Check directory permissions
ls -la .

# 2. Fix ownership
sudo chown -R $(whoami) .

# 3. Check if files are read-only
chmod u+w filename
```

---

## Runtime Issues

### Claude stuck or unresponsive

**Symptom:** No response, spinning forever

**Solutions:**
1. Press `Ctrl+C` to interrupt
2. Check network connection
3. Restart: `claude --continue` to resume
4. Clear cache: `rm -rf ~/.claude/cache`

### High memory usage

**Symptom:** System slowdown, crashes

**Solutions:**
```bash
# 1. Limit context size
claude --max-context 50000

# 2. Work in smaller chunks
# Split large tasks into subtasks

# 3. Close other Claude sessions
```

### Hooks not running

**Symptom:** Format/lint hooks don't trigger

**Solutions:**
```bash
# 1. Verify settings.json syntax
cat .claude/settings.json | jq .

# 2. Check hook command works manually
bun run format

# 3. Enable hook debugging
CLAUDE_DEBUG_HOOKS=1 claude

# 4. Check matcher pattern
# "Write|Edit" not "Write | Edit" (no spaces)
```

### Wrong files being edited

**Symptom:** Claude edits files in wrong directory

**Solutions:**
1. Verify working directory: `pwd`
2. Use absolute paths in requests
3. Create `.claudeignore` to exclude directories
4. Be specific: "Edit `src/components/Button.tsx`" not "Edit the Button component"

---

## Git Issues

### Uncommitted changes warning

**Symptom:** "You have uncommitted changes"

**Solutions:**
```bash
# 1. Stash changes
git stash

# 2. Or commit them
git add . && git commit -m "WIP"

# 3. Or tell Claude to ignore
"Continue despite uncommitted changes"
```

### Merge conflicts after Claude edits

**Symptom:** Git conflicts in files Claude modified

**Solutions:**
```bash
# 1. See what changed
git diff

# 2. Accept Claude's version
git checkout --theirs filename

# 3. Or accept original
git checkout --ours filename

# 4. Manual merge
# Edit file, then: git add filename
```

### Wrong branch

**Symptom:** Claude committed to wrong branch

**Solutions:**
```bash
# 1. Move commit to correct branch
git branch correct-branch
git reset --hard HEAD~1
git checkout correct-branch

# 2. Or cherry-pick
git checkout correct-branch
git cherry-pick <commit-sha>
```

---

## Tool-Specific Issues

### Bash commands fail

**Symptom:** "Command not found" or permission errors

**Solutions:**
```bash
# 1. Check if command exists
which <command>

# 2. Use full path
/usr/local/bin/node instead of node

# 3. Check shell
echo $SHELL
# Claude uses sh, not bash features

# 4. Pre-allow command
/permissions allow Bash(<command>)
```

### Read tool returns empty

**Symptom:** File appears empty when read

**Solutions:**
1. Check file exists: `ls -la <file>`
2. Check file permissions
3. Check if binary file (Claude can't read binaries)
4. Try smaller file (very large files may truncate)

### Write tool fails

**Symptom:** Can't create or modify file

**Solutions:**
1. Check parent directory exists
2. Check write permissions
3. Check disk space: `df -h`
4. Check if file is locked by another process

---

## Performance Issues

### Slow responses

**Symptom:** Claude takes too long to respond

**Causes & Solutions:**
| Cause | Solution |
|-------|----------|
| Large context | Break into smaller tasks |
| Complex codebase | Use `.claudeignore` |
| Network latency | Check internet connection |
| Slow hooks | Optimize hook commands |
| Large files | Read specific line ranges |

### Token limit exceeded

**Symptom:** "Context window exceeded"

**Solutions:**
1. Start new session: `claude`
2. Be more specific in requests
3. Add files to `.claudeignore`
4. Use `--max-context` flag

---

## Configuration Issues

### CLAUDE.md not being read

**Symptom:** Claude ignores project instructions

**Solutions:**
1. Check file location (must be project root)
2. Check filename: `CLAUDE.md` (case-sensitive)
3. Check file encoding (UTF-8)
4. Verify content is valid markdown

### Settings not applying

**Symptom:** `.claude/settings.json` ignored

**Solutions:**
```bash
# 1. Validate JSON
cat .claude/settings.json | jq .

# 2. Check location
# Should be: .claude/settings.json (not .claude.json)

# 3. Check permissions
ls -la .claude/

# 4. Restart Claude
```

### MCP servers not connecting

**Symptom:** MCP tools unavailable

**Solutions:**
```bash
# 1. Check .mcp.json syntax
cat .mcp.json | jq .

# 2. Verify server is running
curl <mcp-server-url>/health

# 3. Check network/firewall

# 4. Restart with verbose logging
CLAUDE_DEBUG_MCP=1 claude
```

---

## Session Issues

### Can't resume session

**Symptom:** `--continue` shows wrong session

**Solutions:**
```bash
# 1. List sessions
claude sessions list

# 2. Resume specific session
claude --resume <session-id>

# 3. Clear old sessions
claude sessions clear
```

### Session data lost

**Symptom:** Context disappeared mid-conversation

**Solutions:**
1. Check `~/.claude/sessions/` for backups
2. Use `--continue` to resume
3. Re-provide important context

---

## Getting Help

If issues persist:

1. **Check logs:** `~/.claude/logs/`
2. **Verbose mode:** `CLAUDE_DEBUG=1 claude`
3. **GitHub Issues:** https://github.com/anthropics/claude-code/issues
4. **Documentation:** https://docs.anthropic.com/claude-code

### Useful Debug Commands

```bash
# Claude version
claude --version

# System info
uname -a
node --version
npm --version

# Claude config
cat ~/.claude/config.json

# Recent logs
tail -100 ~/.claude/logs/latest.log
```
