# Context

**Purpose:** Facts, decisions, and history for AI agents working on this project.

---

## Author

**Name:** Jon Lighthall
**Role:** Developer
**Organization:** Personal utilities repository
**Domain:** System administration, shell scripting, automation

**Primary tools:**
- Bash shell scripting
- Git version control
- WSL (Windows Subsystem for Linux) environment
- VS Code editor

**General preferences:**
- Impersonal voice for expository writing
- Mathematical "we" acceptable in derivations ("we substitute...", "we obtain...")
- Avoid editorial "we" ("we believe...", "we recommend...")
- Prefer minimal changes over extensive rewrites

**Writing style:**
- Target the style appropriate for the project (technical docs, code comments, etc.)
- **Target audience:** Developers familiar with bash and Unix utilities
- **Level of detail:** Concise, assumes shell scripting familiarity

**What NOT to do:**
- **No meta-commentary:** Don't create summary markdown files after edits. If context is worth preserving, put it in `.ai/` files.
- **No hyper-literal headers:** If asked to "add a clarifying statement," don't create a section titled "Clarifying Statement." Integrate naturally.
- **No AI self-narration:** Don't describe what you're doing in the document itself. Just do it.

---

## This Project

### Overview

A collection of bash utility scripts for personal use. The repository provides automation for:
- File management and cleanup
- Git operations and repository maintenance
- Date/time manipulation and formatting
- Remote synchronization
- OneDrive integration and file extension handling
- History file management and deduplication

**Repository:** `jonlighthall/bash`
**License:** MIT (Copyright 2017 Jon Lighthall)
**Location:** `/home/jlighthall/utils/bash` (symlinked or cloned)

### Key Files

| File | Role |
|------|------|
| `make_links.sh` | Creates symlinks from scripts to `${HOME}/bin` |
| `install_packages.sh` | Installs dependencies |
| `git/lib_git.sh` | Shared git utility functions |
| `datetime/lib_date.sh` | Shared date/time utility functions |
| `onedrive/lib_onedrive.sh` | Shared OneDrive utility functions |

### External Dependencies

Scripts expect these external resources:
- `${HOME}/config/.bashrc_pretty` — Shared bash utilities (formatting, traps, colors)
- `${HOME}/bin` — Target directory for script symlinks

### Coding Conventions

**Script header pattern:**
```bash
#!/bin/bash -u
# ------------------------------------------------------------------------------
#
# Mon YYYY JCL
#
# ------------------------------------------------------------------------------
```

**Timing pattern:** Many scripts capture start time for elapsed time reporting:
```bash
start_time=$(date +%s%N)
```

**Directory handling:** Scripts often save and restore working directory:
```bash
start_dir=$PWD
# ... do work ...
cd "$start_dir"
```

---

## Decisions and Constraints

### Error Handling

**Decision:** Use `set -eu` flags for strict error handling.
- `-e`: Exit on error
- `-u`: Treat unbound variables as errors

**Exception:** Some scripts conditionally apply `-e` only when executed (not sourced):
```bash
if ! (return 0 2>/dev/null); then
    set -e
fi
```

### Exit Code Capture Pattern

**Current:** Use `command && status=$? || status=$?` to capture exit codes without triggering `set -e`.

**Rationale:** Direct `command; status=$?` fails under `set -e` if the command returns non-zero. The `&& ... || ...` pattern ensures the assignment always happens.

### Quoting Standards

**Current:** All variable expansions should be quoted, especially in:
- `cd "$directory"`
- `source "$file"`
- Function arguments: `func "$1" "$2"`
- Array expansion: `"$@"`

**Rationale:** Prevents word splitting and glob expansion issues with paths containing spaces or special characters.

### Integer vs String Comparison

**Current:** Use arithmetic operators (`-eq`, `-ne`, etc.) for numeric comparisons in `[ ]` tests.

**Rationale:** `=` and `!=` are string operators. Using them with numbers works but is semantically incorrect and can cause issues with leading zeros or whitespace.

---

## History

### 2025-10: OneDrive Script Fixes
- Fixed `print_git_status` function calls for deleted files to avoid nameref errors
- Fixed error trap handling with `&& git_status=$? || git_status=$?` pattern

### 2025-11: Repository Reorganization
- Created `cleanup/` directory
- Moved `rm_broken.sh`, `rm_broken_dupes.sh`, `rmbin.sh`, `clean_mac.sh` to `cleanup/`
- Updated `make_links.sh` to reference new locations

### 2025-11: Code Quality Improvements
- Fixed unquoted `cd` commands (~6 files)
- Fixed unquoted `source` commands (~46+ instances)
- Fixed integer comparisons using `=` instead of `-eq` (7 files)
- Fixed useless use of cat patterns (10+ instances across sort/, find/, and utility scripts)

---

## Superseded Decisions

*None documented yet.*
