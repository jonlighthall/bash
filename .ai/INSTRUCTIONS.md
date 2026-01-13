# Instructions

**Purpose:** Procedures and standing orders for AI agents working on this project.

---

## Quick Start

1. Read this file for procedures
2. Read `CONTEXT.md` for project facts and decisions
3. Read the relevant topic's `CONTEXT.md` for specific background
4. Read the relevant topic's `INSTRUCTIONS.md` for specific procedures

---

## Context Maintenance (Standing Order)

When the user provides substantial clarifying information, **integrate it into the appropriate `.ai/` file without being asked** (see table below).

### Where to put new information:

| Type of Information | Destination |
|---------------------|-------------|
| Project-wide decisions, facts, history | `.ai/CONTEXT.md` |
| Project-wide procedures, standing orders | `.ai/INSTRUCTIONS.md` |
| Topic-specific history, validation, decisions | `<topic>/CONTEXT.md` |
| Topic-specific procedures, checklists | `<topic>/INSTRUCTIONS.md` |

### When to create a topic folder:

Topic folders add granularity but also overhead. **Default to project-wide files; split when justified.**

**CREATE a topic folder when:**
- The topic has its own lifecycle (can be "completed" independently)
- It has unique decisions or terminology that don't apply elsewhere
- Multiple AI sessions will focus specifically on this topic
- Adding to project-wide files would exceed ~100 lines for this topic alone

**DON'T create a topic folder when:**
- It's a one-off task or short-term work
- The context fits in a few paragraphs
- It shares most decisions with the main project
- You're unsure (start in project-wide files; split later if needed)

**If topic folders already exist:** Use them. Don't consolidate without user direction.

### When to update:

**DO update when:**
- User provides ≥2-3 sentences of explanatory context
- User answers clarifying questions about the project
- User makes a decision that should persist across sessions
- User corrects a misconception (especially if AI-generated)

**DON'T update for:**
- Routine edits, minor corrections
- Conversational exchanges
- Information already documented

### Why this matters:

Context files exist so future AI sessions don't need to re-ask the same questions. If you receive substantial context and don't document it, the next session will be less effective.

### Handling conflicts:

Topic-specific files may override project-wide decisions, but **conflicts must be explicitly documented**.

**If you notice a conflict:**
1. Check if the topic file explicitly notes the override (e.g., "Exception: this component uses X despite project-wide guidance")
2. If the override is documented → follow the topic-specific guidance
3. If the override is NOT documented → ask the user which applies before proceeding

**When creating an intentional override:** Add a note in the topic file explaining what is being overridden and why.

### Handling deprecated/superseded information:

When harvesting context from old chats or updating documentation with newer decisions:

**Newer decisions take precedence**, but preserve the evolution if it's instructive:

```markdown
### [Decision Name]
**Current:** [What we do now]

**Superseded:** Previously we tried [X] but switched because [reason].
(Chat from YYYY-MM-DD)
```

**When to preserve the old approach:**
- It explains *why* we don't do something (prevents re-asking)
- It documents a failed experiment (prevents repeating mistakes)
- It shows the evolution of thinking

**When to simply delete:**
- Trivial or obvious corrections
- Typos/errors with no instructive value
- Exploratory ideas that were never actually tried

**If chronology is unclear:** Ask the user which version is current before overwriting.

### If you cannot write to these files:

Some AI tools have read-only access. If you receive substantial context but cannot update the `.ai/` files, summarize what should be added and ask the user to update the files manually.

---

## General Quality Standards

### Before Editing:
1. Verify you have sufficient context
2. Check terminology against `CONTEXT.md`
3. Use the author's preferred voice (see `CONTEXT.md`)

### After Editing:
1. Verify the edit didn't break anything (compilation, syntax, etc.)
2. Update the relevant `CONTEXT.md` if you made decisions that should persist
3. Check for errors introduced

### When Uncertain:
- Ask clarifying questions before making changes
- Document assumptions in the relevant `CONTEXT.md`
- Prefer minimal changes over extensive rewrites

---

## This Project

### Shell Script Standards

**Shebang and options:**
- Use `#!/bin/bash -u` for scripts that should fail on unbound variables
- Add `set -e` for scripts that should exit on errors (often done conditionally)

**Quoting:**
- Always quote variable expansions: `"$var"`, `"$1"`, `"$@"`
- Quote arguments to `cd`, `source`, and file operations
- Use `"${var}"` when concatenating with other text

**Integer comparisons:**
- Use `-eq`, `-ne`, `-lt`, `-gt`, `-le`, `-ge` for numeric comparisons in `[ ]`
- The `=` and `!=` operators are for string comparisons only

**Pattern: Capturing exit codes**
- Use `command && status=$? || status=$?` to always capture return value without triggering `set -e`
- Or use direct conditionals: `if command; then ...` instead of `command; if [ $? -eq 0 ]`

**Avoid:**
- Useless use of cat: prefer `cmd < file` or `cmd file` over `cat file | cmd`
- Unquoted variable expansions in paths

### File Organization

| Directory | Purpose |
|-----------|---------|
| `datetime/` | Date/time manipulation utilities |
| `find/` | File finding and matching utilities |
| `git/` | Git automation scripts |
| `onedrive/` | OneDrive-specific file management |
| `remote/` | Remote sync and copy operations |
| `sort/` | Sorting and deduplication utilities |
| `test/` | Test scripts and examples |
| `cleanup/` | File cleanup utilities (rmbin, rm_broken, clean_mac) |

### Common Library Pattern

Scripts typically source shared utilities:
```bash
config_dir="${HOME}/config"
fpretty="${config_dir}/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
    print_source
fi
```

### Linking Convention

Scripts are linked to `${HOME}/bin` via `make_links.sh`. When adding new scripts:
1. Add the script name (without `.sh`) to the list in `make_links.sh`
2. Include subdirectory prefix if applicable (e.g., `datetime/cp_date`)
