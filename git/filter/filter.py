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
    # File not found, print error message
    print("Error: File not found")

# conditionally replace emails and names
if commit.author_email in auth_list:
    if commit.author_email != CORRECT_EMAIL:
        commit.author_email = CORRECT_EMAIL
    if commit.author_name != CORRECT_NAME:
        commit.author_name = CORRECT_NAME

if commit.committer_email in auth_list:
    if commit.committer_email != CORRECT_EMAIL:
        commit.committer_email = CORRECT_EMAIL
    if commit.committer_name != CORRECT_NAME:
        commit.committer_name = CORRECT_NAME
