#!/bin/bash
# setup-project.sh - Initialize Claude Code configuration for a project
# Usage: bash scripts/setup-project.sh [project-dir] [npm|pnpm|bun|yarn|auto]
#
# Creates (never overwrites existing files):
#   .claude/settings.json               hooks + permissions
#   .claude/agents/build-validator.md   subagent with required frontmatter
#   .claude/skills/                     place for project skills

set -euo pipefail

PROJECT_DIR="${1:-.}"
PKG="${2:-auto}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [ "$PKG" = "auto" ]; then
  if [ -f "$PROJECT_DIR/bun.lockb" ] || [ -f "$PROJECT_DIR/bun.lock" ]; then PKG="bun"
  elif [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then PKG="pnpm"
  elif [ -f "$PROJECT_DIR/yarn.lock" ]; then PKG="yarn"
  else PKG="npm"; fi
  echo "Detected package manager: $PKG"
fi

case "$PKG" in
  npm|pnpm|bun|yarn) ;;
  *) echo "Error: unsupported package manager '$PKG' (use npm, pnpm, bun, yarn, or auto)" >&2; exit 1 ;;
esac

echo "Setting up Claude Code in: $PROJECT_DIR (using $PKG)"
mkdir -p "$PROJECT_DIR/.claude/agents" "$PROJECT_DIR/.claude/skills"

CREATED=()
SKIPPED=()

# write_if_absent <path>: writes stdin to <path> unless it already exists
write_if_absent() {
  if [ -e "$1" ]; then
    SKIPPED+=("$1")
    cat > /dev/null
  else
    cat > "$1"
    CREATED+=("$1")
  fi
}

# Hooks must sit under a top-level "hooks" key. The commit gate filters with
# "if" (matchers only see tool names) and exits 2, the only code that blocks.
write_if_absent "$PROJECT_DIR/.claude/settings.json" << SETTINGS
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "$PKG run format >/dev/null 2>&1 || true" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git commit *)",
            "command": "$PKG run lint >&2 && $PKG test >&2 || exit 2",
            "timeout": 300,
            "statusMessage": "Running lint and tests..."
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash($PKG run *)",
      "Bash($PKG test *)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  }
}
SETTINGS

write_if_absent "$PROJECT_DIR/.claude/agents/build-validator.md" << AGENT
---
name: build-validator
description: Verifies typecheck, lint, and tests pass and reports each failure with a suggested fix. Use proactively before committing or opening a PR.
tools: Read, Grep, Glob, Bash
model: sonnet
---

# Build Validator

Verify all checks pass before any commit.

## Steps
1. Run typecheck: \`$PKG run typecheck\`
2. Run linter: \`$PKG run lint\`
3. Run tests: \`$PKG test\`
4. Report each failure as file:line with a concrete fix

## Success Criteria
- Typecheck: 0 errors
- Lint: 0 errors (warnings OK)
- Tests: all pass
AGENT

if command -v jq > /dev/null 2>&1; then
  jq empty "$PROJECT_DIR/.claude/settings.json" || { echo "Error: .claude/settings.json is not valid JSON" >&2; exit 1; }
fi

echo ""
if [ "${#CREATED[@]}" -gt 0 ]; then
  echo "Created:"; printf '  %s\n' "${CREATED[@]}"
fi
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "Kept existing (not overwritten):"; printf '  %s\n' "${SKIPPED[@]}"
fi
echo ""
echo "Next steps:"
echo "  1. Copy assets/claude-md-template.md to CLAUDE.md and customize it"
echo "  2. Make sure package.json defines format, lint, typecheck, and test scripts"
echo "  3. Start 'claude' and run /hooks and /agents to confirm everything loaded"
