import os
import sys

# Note: This is a git-filter-repo callback script.
# The 'commit' object is automatically provided by git-filter-repo
# when this script is executed as a callback.

# define correct name
CORRECT_NAME = b"Jon Lighthall"

# define correct email
CORRECT_EMAIL = b"jon.lighthall@gmail.com"

# list emails to replace
auth_list = [b"jonlighthall@users.noreply.github.com"]
# define list file
file_name = os.path.expanduser("~/utils/bash/git/filter/author_list.txt")
# check if file exists
if os.path.isfile(file_name):
    # File exists
    with open(file_name, "r", encoding="us-ascii") as file:
        for line in file:
            auth_list.append(line.strip().encode())
else:
    # File not found, print error message and exit
    print(f"Error: Author list file not found: {file_name}")
    sys.exit(1)

# conditionally replace emails and names
commit_header_printed = False

if commit.author_email in auth_list:
    commit_hash = (
        commit.original_id.decode() if commit.original_id else f"mark:{commit.id}"
    )
    print(f"Commit {commit_hash[:8]}:")
    commit_header_printed = True
    if commit.author_email != CORRECT_EMAIL:
        print(
            f"   Updating    author: {commit.author_email.decode()} -> {CORRECT_EMAIL.decode()}"
        )
        commit.author_email = CORRECT_EMAIL
    if commit.author_name != CORRECT_NAME:
        print(
            f"   Updating    author: {commit.author_name.decode()} -> {CORRECT_NAME.decode()}"
        )
        commit.author_name = CORRECT_NAME

if commit.committer_email in auth_list:
    commit_hash = (
        commit.original_id.decode() if commit.original_id else f"mark:{commit.id}"
    )
    if not commit_header_printed:
        print(f"Commit {commit_hash[:8]}:")
    if commit.committer_email != CORRECT_EMAIL:
        print(
            f"   Updating committer: {commit.committer_email.decode()} -> {CORRECT_EMAIL.decode()}"
        )
        commit.committer_email = CORRECT_EMAIL
    if commit.committer_name != CORRECT_NAME:
        print(
            f"   Updating committer: {commit.committer_name.decode()} -> {CORRECT_NAME.decode()}"
        )
        commit.committer_name = CORRECT_NAME
