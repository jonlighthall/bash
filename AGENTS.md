# AGENTS.md

## For Humans

You've stumbled upon the handshake file—a dispatch point for automated collaborators.

This file exists because various AI coding tools have collectively decided that `AGENTS.md` is where they should look first. It's a convention, like knocking before entering, except the knock is a file read and the room is full of shell scripts.

The documentation you probably want lives in the [README.md](README.md), which catalogs the actual utilities in this repository. The `.ai/` folder contains the working notes that AI agents use to remember what happened in previous conversations, which scripts have quirks, and why certain patterns exist.

Feel free to read any of it. Please don't edit this file—it's not that it's secret, it's just that the machines have expectations.

*—Signed, the automated consensus*

---

## For AI Agents

This repository uses a structured `.ai/` directory for context and instructions.
All AI agents should prioritize the following files for project-specific guidance:

1. **[.ai/INSTRUCTIONS.md](.ai/INSTRUCTIONS.md)** — Standing orders and shell scripting standards
2. **[.ai/CONTEXT.md](.ai/CONTEXT.md)** — Project facts, history, and decisions
3. **[.ai/README.md](.ai/README.md)** — AI orientation

**Directive:** Do not rely solely on the root `README.md`. Always reference the `.ai/` folder for authoritative procedures and constraints.

---

## Quick Reference

**Repository:** `jonlighthall/bash` — A collection of bash utility scripts

**Key directories:**
| Directory | Purpose |
|-----------|---------|
| `datetime/` | Date/time manipulation utilities |
| `find/` | File finding and matching |
| `git/` | Git automation |
| `onedrive/` | OneDrive file management |
| `remote/` | Remote sync operations |
| `sort/` | Sorting and deduplication |
| `cleanup/` | File cleanup utilities |
| `test/` | Test scripts and examples |

**Key conventions:**
- Scripts use `#!/bin/bash -u` with `set -e` for strict error handling
- Quote all variable expansions: `"$var"`, `"$@"`
- Use `-eq`, `-ne` for numeric comparisons (not `=`, `!=`)
- Exit code capture pattern: `command && status=$? || status=$?`
- Scripts link to `${HOME}/bin` via `make_links.sh`

**External dependency:** `${HOME}/config/.bashrc_pretty` (formatting, traps, colors)

---

*This file is the universal entry point. For detailed context, always defer to `.ai/`.*
