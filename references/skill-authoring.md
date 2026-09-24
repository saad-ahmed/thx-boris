# Skill Authoring Guide

How to write, test, and ship Agent Skills that trigger reliably and work in Claude Code, claude.ai, and the API.

## Contents
- Anatomy and progressive disclosure
- Frontmatter: portable fields
- Frontmatter: Claude Code extensions
- Writing the description
- Writing the body
- Arguments and substitutions
- Dynamic context injection
- Running a skill in a subagent
- Where skills live
- Evaluations and iteration
- Packaging and validation
- Pre-ship checklist

---

## Anatomy and progressive disclosure

```
my-skill/
├── SKILL.md          # Required: frontmatter + instructions (< 500 lines)
├── references/       # Docs Claude reads only when needed
├── scripts/          # Code Claude runs; only its output enters context
├── assets/           # Templates, schemas, static files
└── evals/            # Test scenarios (not loaded by Claude)
```

Loading happens in three levels:
1. **Metadata** (~100 tokens): `name` + `description` for every installed skill, always in context.
2. **Body**: all of `SKILL.md`, loaded when the skill triggers. Aim for under 5,000 tokens and 500 lines.
3. **Resources**: files Claude reads or scripts it runs, only when a task needs them.

Rules:
- Link every reference file **directly from SKILL.md** (one level deep). Claude may only preview nested links with `head`.
- Give any reference file over 100 lines a **Contents** list at the top.
- Name files by content (`hooks-patterns.md`, not `doc2.md`). Use forward slashes in paths.
- Say whether Claude should **run** a script ("Run `scripts/validate.sh`") or **read** it ("See `scripts/validate.sh` for the algorithm").

---

## Frontmatter: portable fields

These are the only fields in the [Agent Skills spec](https://agentskills.io/specification). They work everywhere. **Any other field makes claude.ai uploads and the Skills API fail.**

```yaml
---
name: processing-pdfs
description: Extracts text and tables from PDFs, fills forms, merges files. Use when working with PDF files or when the user mentions PDFs or forms.
license: MIT
compatibility: Requires Python 3 and pdfplumber
metadata:
  author: example-org
  version: "1.0"
allowed-tools: Bash(python *) Read
---
```

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | 1–64 chars; `a-z`, `0-9`, `-`; no leading, trailing, or double hyphen; must match the folder name; must not contain `claude` or `anthropic` |
| `description` | Yes | 1–1,024 chars; non-empty; no XML tags |
| `license` | No | License name or bundled file name |
| `compatibility` | No | ≤ 500 chars; only if the skill has real environment requirements |
| `metadata` | No | Map of **string → string**. Quote versions (`"1.0"`) and flatten lists into strings |
| `allowed-tools` | No | Space-separated pre-approved tools (experimental in the spec) |

Naming: gerund form (`processing-pdfs`) is preferred. Noun phrases (`pdf-processing`) and action names (`process-pdfs`) are fine. Avoid `helper`, `utils`, and `tools`.

---

## Frontmatter: Claude Code extensions

Use these only in skills that live in `.claude/skills/`, `~/.claude/skills/`, or plugins, never in uploaded skills.

| Field | Values | Effect |
|-------|--------|--------|
| `when_to_use` | string | Extra trigger text appended to `description`. The two together are truncated at 1,536 chars in the listing |
| `argument-hint` | string | Autocomplete hint, e.g. `[issue-number]` |
| `arguments` | list/string | Named positional args for `$name` substitution |
| `disable-model-invocation` | bool | User-only (`/name`); Claude never auto-invokes it. Use for side effects (deploy, commit, send) |
| `user-invocable` | bool | `false` hides it from `/`, leaving background knowledge Claude loads itself |
| `disallowed-tools` | list/string | Removes tools while the skill is active |
| `model` | `opus`, `sonnet`, `haiku`, full ID, `inherit` | Model override |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max` | Effort override (levels depend on the model) |
| `context` | `fork` | Run in an isolated subagent. The skill body becomes its prompt |
| `agent` | `Explore`, `Plan`, `general-purpose`, or a custom agent | Subagent type for `context: fork` |
| `background` | bool | With `fork`, `false` waits for the result in the same turn |
| `hooks` | object | Hooks registered when the skill runs |
| `paths` | globs | Only auto-activate when working on matching files |
| `shell` | `bash`, `powershell` | Shell used for `!` injections |

Invocation control:

| Frontmatter | User can `/invoke` | Claude auto-invokes | Description in context |
|-------------|:-:|:-:|:-:|
| (default) | ✓ | ✓ | ✓ |
| `disable-model-invocation: true` | ✓ | ✗ | ✗ |
| `user-invocable: false` | ✗ | ✓ | ✓ |

---

## Writing the description

The description is the **only** thing Claude sees when it decides whether to load the skill, often among 100+ others.

- Write in the **third person**: "Processes Excel files…", not "I can help…" or "You can use this…".
- State **what** the skill does and **when** to use it ("Use when…"), with concrete keywords, file types, and phrases users actually say.
- Add a negative scope when neighbouring skills overlap: "Not for general debugging."
- Don't put anything time-sensitive in it.

```yaml
# Good
description: Generates commit messages by analyzing staged git diffs. Use when the user asks for a commit message or to review staged changes.
# Bad
description: Helps with git.
```

---

## Writing the body

- **Assume Claude is already smart.** Only add what it can't know: your conventions, gotchas, and exact commands. Cut explanations of general concepts.
- **Match freedom to fragility.** Use prose heuristics for open-ended work (reviews), templates or pseudocode when a preferred pattern exists, and exact commands ("run exactly this, don't add flags") for fragile steps (migrations).
- **Give one default, not a menu.** "Use pdfplumber. For scanned PDFs, use pytesseract instead."
- **Use workflows with checklists** for multi-step tasks. Claude copies the checklist and checks off each step.
- **Add feedback loops**: run the validator, fix, and repeat until it passes. For risky batch work, have Claude write a plan file, validate it, then execute.
- **Keep terminology consistent.** Pick one term ("field", "endpoint") and stick to it.
- **Avoid time-sensitive facts.** Put deprecated approaches in an "Old patterns" section instead of "before <date> do X".
- **Use concrete examples.** Input/output pairs beat descriptions of the style you want.
- **MCP tools**: use fully qualified names (`mcp__github__create_issue` in Claude Code, `GitHub:create_issue` in the spec convention).
- **Scripts should solve, not punt.** Handle errors with actionable messages, justify every constant, and list dependencies explicitly (`pip install pypdf`).

---

## Arguments and substitutions

Claude Code only. On claude.ai the text stays literal.

| Placeholder | Value |
|-------------|-------|
| `$ARGUMENTS` | Everything after `/skill-name`. If the body has no placeholder, Claude Code appends `ARGUMENTS: <value>` |
| `$ARGUMENTS[N]`, `$N` | 0-based positional argument (`$0`, `$1`, …); shell-style quoting groups words |
| `$name` | Named argument declared in `arguments:` |
| `${CLAUDE_SKILL_DIR}` | Folder containing this `SKILL.md`; use it to call bundled scripts from any cwd |
| `${CLAUDE_PROJECT_DIR}` | Project root |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_EFFORT}` | Current effort level |
| `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` | Plugin skills only |

Escape a literal dollar sign before a digit or name with a backslash: `\$1.00`.

```markdown
---
name: fix-issue
arguments: [issue]
argument-hint: "[issue-number]"
disable-model-invocation: true
---
Fix GitHub issue #$issue. Run `bash ${CLAUDE_SKILL_DIR}/scripts/repro.sh $issue` first.
```

---

## Dynamic context injection

`` !`command` `` (at the start of a line or after whitespace) or a ```` ```! ```` fenced block runs **before** Claude sees the skill, and the output replaces it.

```markdown
Branch: !`git branch --show-current`
Recent commits:
!`git log --oneline -5`
```

- A **non-zero exit aborts the whole skill.** Append `|| true` to anything that can fail (`grep`, `diff`, and similar search commands are exempt on exit 1).
- The command must be allowed by permission rules or listed in `allowed-tools`. Outside auto mode, an unapproved command aborts the skill.
- 2-minute timeout. Keep commands fast and output small (`| head`).
- Injection doesn't run for skills synced from claude.ai, and `disableSkillShellExecution` turns it off by policy.
- Don't echo secrets.

---

## Running a skill in a subagent

```yaml
---
name: deep-research
description: Researches a codebase question in isolation and returns a summary.
context: fork
agent: Explore
---
```

- The subagent **doesn't see the conversation**, so the body must stand alone.
- It runs in the background by default. Set `background: false` to wait for the result.
- `Explore` and `Plan` skip CLAUDE.md and git status to keep context small.
- Edits from a background fork aren't covered by `/rewind`. Use git to revert them.
- `context: fork` is the only fork value. There is no `context: agent`.

---

## Where skills live

| Location | Path | Scope |
|----------|------|-------|
| Enterprise | managed settings dir `/.claude/skills/<name>/` | Whole organization |
| Personal | `~/.claude/skills/<name>/` | All your projects (not cloud sessions) |
| Project | `.claude/skills/<name>/` | Anyone working in the repo (commit it) |
| Nested | `<subdir>/.claude/skills/<name>/` | Monorepo packages; loads when Claude touches that subdir |
| Plugin | `<plugin>/skills/<name>/` | Namespaced `/plugin:name` |
| claude.ai | Enabled on your account | Synced to `~/.claude/skills/synced/` |

When names collide, the first match wins: Enterprise > Personal > Project. A skill beats a `.claude/commands/` file of the same name. The **folder name** is the command. For local skills, `name` only sets the display label. Don't name a folder `synced`.

Edits to `SKILL.md` apply live without a restart. `/skills` toggles visibility, and `/skill-doctor` shows usage and context cost and flags skills that never get invoked.

---

## Evaluations and iteration

Write evals **before** writing extensive docs, so the skill fixes real failures instead of imagined ones.

1. Run Claude on representative tasks **without** the skill and note what it gets wrong.
2. Write at least **3 scenarios** covering those gaps (see `evals/evals.json`):
   ```json
   {
     "skills": ["thx-boris"],
     "query": "My pre-commit hook doesn't stop commits when tests fail",
     "files": [],
     "expected_behavior": ["Explains that only exit code 2 blocks", "Uses `if: Bash(git commit *)`"]
   }
   ```
3. Measure the baseline, write the **minimum** instructions that make the evals pass, then iterate.
4. Test with every model you plan to use. Haiku needs more guidance, and Opus is hurt by over-explanation.
5. Watch how Claude navigates the skill. Files it never opens are dead weight, and files it always opens probably belong in `SKILL.md`.

**Claude A / Claude B loop:** one session (A) edits the skill while a fresh session (B) uses it on real tasks. Take B's specific failures back to A.

---

## Packaging and validation

```bash
bash scripts/validate-skill.sh path/to/my-skill      # this repo's validator
skills-ref validate path/to/my-skill                 # reference validator from agentskills.io
```

- **Claude Code:** commit the folder under `.claude/skills/`, or distribute it as a plugin (`/plugin`).
- **claude.ai / API:** zip the folder with `SKILL.md` at the top level, using only portable frontmatter fields, then upload it in Settings → Capabilities or via the Skills API.

```bash
zip -r my-skill.zip my-skill/ -x "*.git*" "*node_modules*" "*.DS_Store" "my-skill/evals/*"
```

---

## Pre-ship checklist

**Core quality**
- [ ] The description is third person and says what and when, with concrete keywords
- [ ] `SKILL.md` body is under 500 lines; details live in linked files
- [ ] References are one level deep, and files over 100 lines have a Contents list
- [ ] No time-sensitive info (or it's in an "Old patterns" section)
- [ ] Terminology is consistent and examples are concrete
- [ ] Multi-step workflows have checklists and validation loops

**Scripts**
- [ ] Scripts handle errors with actionable messages, and their constants are justified
- [ ] Dependencies are listed; paths use forward slashes
- [ ] Instructions say whether to run or read each script

**Testing**
- [ ] At least 3 evals, passing
- [ ] Tested on Haiku, Sonnet, and Opus if all three will be used
- [ ] Tried on real tasks, with team feedback folded in
