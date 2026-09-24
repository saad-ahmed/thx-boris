#!/bin/bash
# validate-skill.sh - Validate a skill folder against the Agent Skills spec
# (agentskills.io) and Claude Code / Anthropic authoring best practices.
# Usage: bash scripts/validate-skill.sh [skill-directory]
# Exit code: 0 = no errors (warnings allowed), 1 = errors found.

set -uo pipefail

SKILL_DIR="${1:-.}"
SKILL_MD="$SKILL_DIR/SKILL.md"
ERRORS=0
WARNINGS=0

err()  { echo "❌ $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "⚠️  $*"; WARNINGS=$((WARNINGS + 1)); }
ok()   { echo "✅ $*"; }
info() { echo "ℹ️  $*"; }

# Frontmatter is the text between the first two '---' lines.
frontmatter() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1"; }
# Top-level value of a frontmatter key, surrounding quotes stripped.
fm_value() { frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 | sed -E 's/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/'; }
# Line count of the body (everything after the closing ---).
body_lines() { awk 'c>=2{n++} /^---$/{c++} END{print n+0}' "$1"; }

echo "Validating skill in: $SKILL_DIR"
echo "---"

if [ ! -f "$SKILL_MD" ]; then
  err "SKILL.md not found (must be exactly SKILL.md, case-sensitive)"
  echo "Results: $ERRORS error(s), $WARNINGS warning(s)"; exit 1
fi
ok "SKILL.md exists"

if [ "$(head -1 "$SKILL_MD")" != "---" ]; then
  err "First line must be '---'. Without it the whole file is treated as body and has no name/description"
fi

FM=$(frontmatter "$SKILL_MD")

# ---- name -------------------------------------------------------------------
NAME=$(fm_value "$SKILL_MD" name)
FOLDER_NAME=$(basename "$(cd "$SKILL_DIR" && pwd)")
if [ -z "$NAME" ]; then
  err "Missing required 'name' field"
else
  if [ "${#NAME}" -gt 64 ]; then err "name exceeds 64 characters (${#NAME})"; fi
  if echo "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    ok "name is valid: $NAME"
  else
    err "name must be lowercase a-z/0-9/hyphens, with no leading, trailing, or double hyphen: $NAME"
  fi
  if echo "$NAME" | grep -qiE 'claude|anthropic'; then
    err "name must not contain reserved words 'claude' or 'anthropic'"
  fi
  if [ "$NAME" != "$FOLDER_NAME" ]; then
    warn "name '$NAME' does not match folder '$FOLDER_NAME' (spec requires a match; in Claude Code the folder name is the command)"
  fi
  if [ "$FOLDER_NAME" = "synced" ]; then err "Folder name 'synced' is reserved by Claude Code"; fi
fi

# ---- description ------------------------------------------------------------
DESC=$(fm_value "$SKILL_MD" description)
if [ -z "$DESC" ]; then
  if echo "$FM" | grep -qE '^description:[[:space:]]*[>|]'; then
    DESC=$(echo "$FM" | awk '/^description:/{f=1;next} f&&/^[^[:space:]]/{exit} f{print}' | tr '\n' ' ')
  fi
fi
if [ -z "$DESC" ]; then
  err "Missing required 'description' field"
else
  DLEN=${#DESC}
  if [ "$DLEN" -gt 1024 ]; then err "description exceeds 1,024 characters ($DLEN)"; else ok "description present ($DLEN chars)"; fi
  if echo "$DESC" | grep -qiE 'use (it |this )?when|use for|when the user|trigger'; then
    ok "description says when to use it"
  else
    warn "description should say when to use it (e.g. 'Use when ...')"
  fi
  if echo "$DESC" | grep -qiE "(^|[^a-z])(you|your|i can|i will|i'll)([^a-z]|$)"; then
    warn "description should be third person (avoid 'I'/'you')"
  fi
  if echo "$DESC" | grep -q '<[A-Za-z/]'; then err "description must not contain XML tags"; fi
  if [ "$DLEN" -lt 40 ]; then warn "description is very short; add concrete keywords and triggers"; fi
fi

# ---- portability of frontmatter --------------------------------------------
PORTABLE="name description license compatibility metadata allowed-tools"
CC_ONLY="when_to_use argument-hint arguments disable-model-invocation user-invocable disallowed-tools model effort context agent background hooks paths shell"
NONPORTABLE=""
for key in $(echo "$FM" | grep -oE '^[A-Za-z_-]+:' | tr -d ':'); do
  if echo " $PORTABLE " | grep -q " $key "; then continue; fi
  if echo " $CC_ONLY " | grep -q " $key "; then NONPORTABLE="$NONPORTABLE $key"; continue; fi
  warn "Unknown frontmatter field '$key'"
done
if [ -n "$NONPORTABLE" ]; then
  info "Claude Code-only fields:$NONPORTABLE (fine in .claude/skills; remove before uploading to claude.ai or the Skills API)"
else
  ok "Frontmatter uses only portable Agent Skills fields"
fi

COMPAT=$(fm_value "$SKILL_MD" compatibility)
if [ "${#COMPAT}" -gt 500 ]; then err "compatibility exceeds 500 characters"; fi

CONTEXT=$(fm_value "$SKILL_MD" context)
if [ -n "$CONTEXT" ] && [ "$CONTEXT" != "fork" ]; then err "context must be 'fork' (got '$CONTEXT')"; fi
EFFORT=$(fm_value "$SKILL_MD" effort)
if [ -n "$EFFORT" ] && ! echo "$EFFORT" | grep -qE '^(low|medium|high|xhigh|max)$'; then
  err "effort must be low, medium, high, xhigh, or max (got '$EFFORT')"
fi

# metadata must be a map of string -> string (no nested lists/maps)
if echo "$FM" | grep -q '^metadata:'; then
  META=$(echo "$FM" | awk '/^metadata:/{f=1;next} f&&/^[^[:space:]]/{exit} f{print}')
  if echo "$META" | grep -qE '^[[:space:]]+[A-Za-z0-9_-]+:[[:space:]]*(\[|\{|$)'; then
    err "metadata values must be strings (no lists, maps, or empty values)"
  elif echo "$META" | grep -qE '^[[:space:]]+[A-Za-z0-9_-]+:[[:space:]]*[0-9][0-9.]*[[:space:]]*$'; then
    warn "metadata has an unquoted number; quote it (e.g. version: \"1.0\")"
  else
    ok "metadata is a string map"
  fi
fi

if echo "$FM" | grep -q '<[A-Za-z/]'; then err "XML tags found in frontmatter"; fi

# ---- body -------------------------------------------------------------------
BODY_LINES=$(body_lines "$SKILL_MD")
if [ "$BODY_LINES" -gt 500 ]; then
  warn "SKILL.md body is $BODY_LINES lines (keep under 500; move details to references)"
else
  ok "SKILL.md body is $BODY_LINES lines"
fi
WORDS=$(wc -w < "$SKILL_MD")
if [ "$WORDS" -gt 5000 ]; then warn "SKILL.md is $WORDS words (aim for under ~5,000 tokens)"; fi

if grep -nE '[A-Za-z]:\\[A-Za-z]|[a-z_]+\\[a-z_]+\.(md|py|sh)' "$SKILL_MD" > /dev/null; then
  warn "Windows-style backslash paths found; use forward slashes"
fi

if grep -nE '\((as of|since|before|after) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* 20[0-9]{2}|(January|February|March|April|May|June|July|August|September|October|November|December) 20[0-9]{2} ([a-z]+ )?(features|best practices|spec)' "$SKILL_MD" > /dev/null; then
  warn "Time-sensitive wording found in SKILL.md; move it to an 'Old patterns' section"
fi

# Linked files must exist
MISSING=0
for link in $(grep -oE '\]\([^)#]+\)' "$SKILL_MD" | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^(https?:|mailto:)' | sort -u); do
  if [ ! -e "$SKILL_DIR/$link" ]; then err "Broken link in SKILL.md: $link"; MISSING=1; fi
done
[ "$MISSING" -eq 0 ] && ok "All relative links in SKILL.md resolve"

# ---- references -------------------------------------------------------------
echo "---"
echo "Supporting files:"
for d in scripts references assets templates evals; do
  [ -d "$SKILL_DIR/$d" ] && echo "  ✅ $d/"
done

for ref in "$SKILL_DIR"/references/*.md; do
  [ -f "$ref" ] || continue
  base=$(basename "$ref")
  if ! grep -q "references/$base" "$SKILL_MD"; then
    warn "references/$base is not linked from SKILL.md (Claude may never find it)"
  fi
  if grep -qE '\]\((\.\./)?references/' "$ref"; then
    warn "references/$base links to other reference files (keep references one level deep)"
  fi
  lines=$(wc -l < "$ref")
  if [ "$lines" -gt 100 ] && ! head -20 "$ref" | grep -qiE '^#+ (contents|table of contents)'; then
    warn "references/$base is $lines lines with no 'Contents' section near the top"
  fi
done

# Subagent files bundled with the skill must have name + description frontmatter
while IFS= read -r agent; do
  [ -f "$agent" ] || continue
  rel=${agent#"$SKILL_DIR"/}
  if [ "$(head -1 "$agent")" != "---" ] || [ -z "$(fm_value "$agent" name)" ] || [ -z "$(fm_value "$agent" description)" ]; then
    err "$rel: subagent needs frontmatter with name and description (Claude Code silently skips it otherwise)"
  fi
done < <(find "$SKILL_DIR" -path '*/.git' -prune -o \( -path '*/agents/*.md' \) -print 2>/dev/null)

# settings.json files bundled with the skill must nest hooks under "hooks"
while IFS= read -r settings; do
  [ -f "$settings" ] || continue
  rel=${settings#"$SKILL_DIR"/}
  if command -v jq > /dev/null 2>&1; then
    if ! jq empty "$settings" 2> /dev/null; then err "$rel: invalid JSON"; continue; fi
    if jq -e 'keys[] | select(test("^(Pre|Post)ToolUse$|^Stop$|^Notification$|^SessionStart$|^UserPromptSubmit$"))' "$settings" > /dev/null; then
      err "$rel: hook events at top level; nest them under \"hooks\""
    fi
    if jq -e '.. | objects | select(has("matcher")) | .matcher | select(test("\\("))' "$settings" > /dev/null 2>&1; then
      err "$rel: matcher contains arguments like Bash(...); matchers see tool names only, so use \"if\""
    fi
  fi
done < <(find "$SKILL_DIR" -path '*/.git' -prune -o -name 'settings*.json' -print 2>/dev/null)

# ---- evals ------------------------------------------------------------------
echo "---"
if [ -f "$SKILL_DIR/evals/evals.json" ]; then
  if command -v jq > /dev/null 2>&1; then
    N=$(jq 'length' "$SKILL_DIR/evals/evals.json" 2> /dev/null || echo 0)
    if [ "$N" -ge 3 ]; then ok "evals/evals.json has $N scenarios"; else warn "evals/evals.json has $N scenarios (recommend at least 3)"; fi
  else
    ok "evals/evals.json present"
  fi
else
  warn "No evals/evals.json. Write at least 3 evaluation scenarios"
fi

echo "---"
echo "Results: $ERRORS error(s), $WARNINGS warning(s)"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ Validation FAILED"
  exit 1
fi
echo "✅ Validation PASSED"
exit 0
