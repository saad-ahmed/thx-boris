#!/bin/bash
# setup-project.sh - Initialize Claude Code configuration for a new project
# Usage: bash scripts/setup-project.sh [project-dir] [package-manager]

set -euo pipefail

PROJECT_DIR="${1:-.}"
PKG="${2:-npm}"

echo "Setting up Claude Code for: $PROJECT_DIR (using $PKG)"

# Create .claude directory structure
mkdir -p "$PROJECT_DIR/.claude/agents"
mkdir -p "$PROJECT_DIR/.claude/commands"

# Detect package manager if not specified
if [ "$PKG" = "auto" ]; then
  if [ -f "$PROJECT_DIR/bun.lockb" ]; then PKG="bun"
  elif [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then PKG="pnpm"
  elif [ -f "$PROJECT_DIR/yarn.lock" ]; then PKG="yarn"
  else PKG="npm"; fi
  echo "Detected package manager: $PKG"
fi

# Create settings.json with hooks
cat > "$PROJECT_DIR/.claude/settings.json" << SETTINGS
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "$PKG run format || true"
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "Bash(git commit*)",
      "hooks": [
        {
          "type": "command",
          "command": "$PKG run lint && $PKG test"
        }
      ]
    }
  ],
  "permissions": {
    "allow": [
      "Bash($PKG run *)",
      "Bash($PKG test*)",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)"
    ]
  }
}
SETTINGS

# Create build-validator agent
cat > "$PROJECT_DIR/.claude/agents/build-validator.md" << 'AGENT'
# Build Validator

Verify all builds and checks pass before any commit.

## Steps
1. Run typecheck
2. Run linter on changed files
3. Run tests related to changes
4. Report specific failures with fix suggestions

## Success Criteria
- Typecheck: 0 errors
- Lint: 0 errors (warnings OK)
- Tests: all pass
AGENT

# Create .claudeignore if it doesn't exist
if [ ! -f "$PROJECT_DIR/.claudeignore" ]; then
  cat > "$PROJECT_DIR/.claudeignore" << 'IGNORE'
node_modules/
.next/
dist/
build/
coverage/
.env
.env.local
*.log
*.min.js
*.min.css
__pycache__/
.venv/
IGNORE
fi

echo ""
echo "Claude Code setup complete!"
echo "Created:"
echo "  .claude/settings.json      - Hooks and permissions"
echo "  .claude/agents/             - Agent templates"
echo "  .claudeignore               - File exclusions"
echo ""
echo "Next steps:"
echo "  1. Copy assets/claude-md-template.md to CLAUDE.md and customize"
echo "  2. Run 'claude' to start your session"
