# OneDrive Utilities

Utilities for handling file sync issues with Navy FlankSpeed OneDrive.

## The Problem

OneDrive restricts syncing files with certain extensions (e.g., `.bat`, `.exe`, `.ps1`). When these files are present in a synced folder, OneDrive creates sync errors and refuses to upload them.

## The Solution

These scripts rename files with restricted extensions so they can be synced, and restore them when needed.

### Naming Conventions

Two naming conventions have been used:

| Convention | Example | Status |
|------------|---------|--------|
| **Append underscore** (new) | `file.bat` → `file.bat_` | Current method |
| **Separator replacement** (old) | `file.bat` → `file_._bat` | Legacy, still unfixable |

The old `_._` method worked for years but OneDrive's filename checking now examines the end of filenames. The new method simply appends an underscore.

## Scripts

| Script | Purpose |
|--------|---------|
| `fix_bad_extensions.sh` | Rename files by appending `_` to bypass OneDrive restrictions |
| `unfix_bad_extensions.sh` | Restore original filenames (handles both old and new formats) |
| `lib_onedrive.sh` | Shared library with extension lists and helper functions |
| `kill_bad_extensions.sh` | Delete files with bad extensions |
| `unkill_bad_extensions.sh` | Restore deleted files from git |
| `rm_onedrive_dupes.sh` | Remove OneDrive duplicate files |
| `rm_tracked_bad_extensions.sh` | Remove tracked files with bad extensions |

## Usage

```bash
# Fix files in current directory
./fix_bad_extensions.sh .

# Fix files in specific directory
./fix_bad_extensions.sh /path/to/directory

# Restore original filenames
./unfix_bad_extensions.sh .
```

### Migrating from Old to New Format

If you have files using the old `_._` format and want to migrate them to the new `_` format, run unfix first, then fix:

```bash
# Step 1: Restore original filenames (handles both old and new formats)
./unfix_bad_extensions.sh .

# Step 2: Apply new naming convention
./fix_bad_extensions.sh .
```

This ensures all files use the same naming convention.

## Restricted Extensions

The following extensions are restricted by OneDrive (defined in `lib_onedrive.sh`):

`bat`, `bin`, `cmd`, `crt`, `csh`, `exe`, `gz`, `js`, `ksh`, `mar`, `osx`, `out`, `prf`, `ps`, `ps1`

## Restricted Base Names

The following base names are also restricted:

`con`
