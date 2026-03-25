#!/bin/bash
# validate-skill.sh - Validate a skill folder meets Anthropic requirements (March 2026)
# Usage: bash scripts/validate-skill.sh [skill-directory]

set -euo pipefail

SKILL_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "Validating skill in: $SKILL_DIR (March 2026 spec)"
echo "---"

# Check SKILL.md exists (case-sensitive)
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  echo "✅ SKILL.md exists"
else
  echo "❌ SKILL.md not found (must be exactly SKILL.md, case-sensitive)"
  ERRORS=$((ERRORS + 1))
fi

# Check no README.md in skill folder
if [ -f "$SKILL_DIR/README.md" ]; then
  echo "⚠️  README.md found - OK for GitHub repo, but exclude when packaging skill as .zip"
  WARNINGS=$((WARNINGS + 1))
else
  echo "✅ No README.md in skill folder"
fi

# Check folder name is kebab-case
FOLDER_NAME=$(basename "$SKILL_DIR")
if echo "$FOLDER_NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "✅ Folder name is kebab-case: $FOLDER_NAME"
else
  echo "⚠️  Folder name may not be kebab-case: $FOLDER_NAME"
  WARNINGS=$((WARNINGS + 1))
fi

# Validate frontmatter
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  # Check for --- delimiters
  FIRST_LINE=$(head -1 "$SKILL_DIR/SKILL.md")
  if [ "$FIRST_LINE" = "---" ]; then
    echo "✅ Frontmatter delimiters present"
  else
    echo "❌ Missing frontmatter --- delimiter on first line"
    ERRORS=$((ERRORS + 1))
  fi

  # Check for name field
  if grep -q '^name:' "$SKILL_DIR/SKILL.md"; then
    NAME=$(grep '^name:' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/name: *//')
    if echo "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      echo "✅ name field is kebab-case: $NAME"
    else
      echo "❌ name field must be kebab-case: $NAME"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "❌ Missing required 'name' field"
    ERRORS=$((ERRORS + 1))
  fi

  # Check for description field
  if grep -q '^description:' "$SKILL_DIR/SKILL.md"; then
    DESC_LEN=$(grep '^description:' "$SKILL_DIR/SKILL.md" | head -1 | wc -c)
    if [ "$DESC_LEN" -gt 1024 ]; then
      echo "❌ Description exceeds 1024 characters ($DESC_LEN chars)"
      ERRORS=$((ERRORS + 1))
    else
      echo "✅ description field present ($DESC_LEN chars)"
    fi

    # Check for trigger phrases
    if grep '^description:' "$SKILL_DIR/SKILL.md" | grep -qi 'use when\|trigger'; then
      echo "✅ Description includes trigger conditions"
    else
      echo "⚠️  Description may be missing trigger conditions (include 'Use when...')"
      WARNINGS=$((WARNINGS + 1))
    fi

    # Check for second-person language (guidelines recommend third-person)
    if grep '^description:' "$SKILL_DIR/SKILL.md" | grep -qiE '\byou\b|\byour\b'; then
      echo "⚠️  Description uses second-person ('you/your') — guidelines recommend third-person"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "❌ Missing required 'description' field"
    ERRORS=$((ERRORS + 1))
  fi

  # Check for XML tags
  if grep -q '<[a-zA-Z]' "$SKILL_DIR/SKILL.md"; then
    echo "⚠️  Possible XML tags found in SKILL.md (forbidden in frontmatter)"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "✅ No XML tags detected"
  fi

  # Check for reserved names
  if grep '^name:' "$SKILL_DIR/SKILL.md" | grep -qi 'claude\|anthropic'; then
    echo "❌ Skill name cannot contain 'claude' or 'anthropic' (reserved)"
    ERRORS=$((ERRORS + 1))
  else
    echo "✅ Name does not use reserved words"
  fi

  # Check for argument-hint (recommended)
  if grep -q '^argument-hint:' "$SKILL_DIR/SKILL.md"; then
    echo "✅ argument-hint field present"
  else
    echo "ℹ️  No argument-hint field (optional, improves autocomplete UX)"
  fi

  # Check for context field (March 2026)
  if grep -q '^context:' "$SKILL_DIR/SKILL.md"; then
    CONTEXT=$(grep '^context:' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/context: *//')
    if echo "$CONTEXT" | grep -qE '^(fork|agent)$'; then
      echo "✅ context field valid: $CONTEXT"
    else
      echo "⚠️  context field should be 'fork' or 'agent': $CONTEXT"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "ℹ️  No context field (optional: fork, agent)"
  fi

  # Check for effort field (March 2026)
  if grep -q '^effort:' "$SKILL_DIR/SKILL.md"; then
    EFFORT=$(grep '^effort:' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/effort: *//')
    if echo "$EFFORT" | grep -qE '^(low|medium|high)$'; then
      echo "✅ effort field valid: $EFFORT"
    else
      echo "⚠️  effort field should be low, medium, or high: $EFFORT"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "ℹ️  No effort field (optional: low, medium, high)"
  fi

  # Check for model field
  if grep -q '^model:' "$SKILL_DIR/SKILL.md"; then
    MODEL=$(grep '^model:' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/model: *//')
    if echo "$MODEL" | grep -qE '^(opus|sonnet|haiku)$'; then
      echo "✅ model field valid: $MODEL"
    else
      echo "⚠️  model field should be opus, sonnet, or haiku: $MODEL"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo "ℹ️  No model field (optional: opus, sonnet, haiku)"
  fi

  # Check word count
  WORD_COUNT=$(wc -w < "$SKILL_DIR/SKILL.md")
  if [ "$WORD_COUNT" -gt 5000 ]; then
    echo "⚠️  SKILL.md is $WORD_COUNT words (recommend under 5,000)"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "✅ SKILL.md is $WORD_COUNT words"
  fi

  # Check line count (March 2026: under 500 lines)
  LINE_COUNT=$(wc -l < "$SKILL_DIR/SKILL.md")
  if [ "$LINE_COUNT" -gt 500 ]; then
    echo "⚠️  SKILL.md is $LINE_COUNT lines (recommend under 500)"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "✅ SKILL.md is $LINE_COUNT lines"
  fi
fi

# Check directory structure
echo "---"
echo "Directory structure:"
[ -d "$SKILL_DIR/scripts" ] && echo "  ✅ scripts/" || echo "  ℹ️  No scripts/ (optional but recommended)"
[ -d "$SKILL_DIR/references" ] && echo "  ✅ references/" || echo "  ℹ️  No references/ (optional)"
[ -d "$SKILL_DIR/assets" ] && echo "  ✅ assets/" || echo "  ℹ️  No assets/ (optional)"
[ -d "$SKILL_DIR/templates" ] && echo "  ✅ templates/" || echo "  ℹ️  No templates/ (optional)"

# Check for nested references (references that link to other references)
if [ -d "$SKILL_DIR/references" ]; then
  for ref in "$SKILL_DIR/references"/*.md; do
    if [ -f "$ref" ] && grep -q 'references/' "$ref" 2>/dev/null; then
      BASENAME=$(basename "$ref")
      echo "  ⚠️  $BASENAME contains references to other reference files (keep one level deep)"
      WARNINGS=$((WARNINGS + 1))
    fi
  done
fi

# Check for dynamic context usage (March 2026)
echo "---"
echo "March 2026 features:"
if grep -q '!`' "$SKILL_DIR/SKILL.md" 2>/dev/null; then
  echo "  ✅ Uses dynamic context injection (\!\`command\`)"
else
  echo "  ℹ️  No dynamic context injection (\!\`command\`) - optional"
fi

if grep -q '\$ARGUMENTS' "$SKILL_DIR/SKILL.md"; then
  echo "  ✅ Uses \$ARGUMENTS variable"
else
  echo "  ℹ️  No \$ARGUMENTS usage - optional"
fi

if grep -q '\$CLAUDE_SKILL_DIR' "$SKILL_DIR/SKILL.md"; then
  echo "  ✅ Uses \$CLAUDE_SKILL_DIR variable"
else
  echo "  ℹ️  No \$CLAUDE_SKILL_DIR usage - optional"
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
