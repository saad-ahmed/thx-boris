#!/bin/bash
# validate-claude-md.sh - Validate CLAUDE.md structure against thx-boris recommendations
# Usage: bash scripts/validate-claude-md.sh [path-to-CLAUDE.md]

set -euo pipefail

CLAUDE_MD="${1:-CLAUDE.md}"
ERRORS=0
WARNINGS=0

echo "Validating: $CLAUDE_MD"
echo "---"

# Check file exists
if [ ! -f "$CLAUDE_MD" ]; then
  echo "❌ File not found: $CLAUDE_MD"
  exit 1
fi

# Check filename is exactly CLAUDE.md (case-sensitive)
BASENAME=$(basename "$CLAUDE_MD")
if [ "$BASENAME" != "CLAUDE.md" ]; then
  echo "❌ Filename must be exactly 'CLAUDE.md' (case-sensitive), got: $BASENAME"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ Filename is correct: CLAUDE.md"
fi

# Check required sections
echo "---"
echo "Required sections:"

if grep -q '^## Commands' "$CLAUDE_MD" || grep -q '^# Commands' "$CLAUDE_MD"; then
  echo "  ✅ Commands section"
else
  echo "  ❌ Missing Commands section"
  ERRORS=$((ERRORS + 1))
fi

if grep -q '^## Code Style' "$CLAUDE_MD" || grep -q '^# Code Style' "$CLAUDE_MD"; then
  echo "  ✅ Code Style section"
else
  echo "  ❌ Missing Code Style section"
  ERRORS=$((ERRORS + 1))
fi

# Check recommended sections
echo "---"
echo "Recommended sections:"

if grep -q '^## Anti-Patterns' "$CLAUDE_MD" || grep -q '^# Anti-Patterns' "$CLAUDE_MD" || grep -q 'Things Claude Got Wrong' "$CLAUDE_MD"; then
  echo "  ✅ Anti-Patterns section"
else
  echo "  ⚠️  Missing Anti-Patterns section (recommended for the feedback loop)"
  WARNINGS=$((WARNINGS + 1))
fi

if grep -q '^## Testing' "$CLAUDE_MD" || grep -q '^# Testing' "$CLAUDE_MD"; then
  echo "  ✅ Testing section"
else
  echo "  ℹ️  No Testing section (optional)"
fi

if grep -q '^## Domain Knowledge' "$CLAUDE_MD" || grep -q '^# Domain Knowledge' "$CLAUDE_MD"; then
  echo "  ✅ Domain Knowledge section"
else
  echo "  ℹ️  No Domain Knowledge section (optional)"
fi

if grep -q '^## Development Workflow' "$CLAUDE_MD" || grep -q '^# Development Workflow' "$CLAUDE_MD"; then
  echo "  ✅ Development Workflow section"
else
  echo "  ℹ️  No Development Workflow section (optional)"
fi

# Check for package manager declaration
echo "---"
echo "Best practices:"

if grep -qi 'package.manager\|npm\|yarn\|pnpm\|bun' "$CLAUDE_MD"; then
  echo "  ✅ Package manager mentioned"
else
  echo "  ⚠️  No package manager declared (add 'Always use [pkg], not [other]')"
  WARNINGS=$((WARNINGS + 1))
fi

# Check file length
LINE_COUNT=$(wc -l < "$CLAUDE_MD")
WORD_COUNT=$(wc -w < "$CLAUDE_MD")

if [ "$LINE_COUNT" -lt 20 ]; then
  echo "  ⚠️  File is only $LINE_COUNT lines (may be too brief)"
  WARNINGS=$((WARNINGS + 1))
elif [ "$LINE_COUNT" -gt 500 ]; then
  echo "  ⚠️  File is $LINE_COUNT lines (consider moving details to separate files)"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  ✅ File length: $LINE_COUNT lines"
fi

echo "  ℹ️  Word count: $WORD_COUNT words"

# Check for common anti-patterns in the file itself
echo "---"
echo "Content checks:"

if grep -q '```' "$CLAUDE_MD"; then
  echo "  ✅ Contains code examples"
else
  echo "  ⚠️  No code blocks found (commands section should have examples)"
  WARNINGS=$((WARNINGS + 1))
fi

if grep -qi 'don.t\|never\|avoid\|not' "$CLAUDE_MD"; then
  echo "  ✅ Contains 'don't/never/avoid' guidance"
else
  echo "  ℹ️  Consider adding explicit 'Don't do X' patterns"
fi

echo "---"
echo "Results: $ERRORS error(s), $WARNINGS warning(s)"

if [ "$ERRORS" -gt 0 ]; then
  echo "❌ Validation FAILED"
  exit 1
else
  echo "✅ Validation PASSED"
  exit 0
fi
