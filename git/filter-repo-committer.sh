git filter-repo $1 --partial --commit-callback '
    correct_name = b"Jon Lighthall"
    auth_list = [b"jlighthall@fsu.edu",b"lighthall@lsu.edu"]
    correct_email = b"jon.lighthall@gmail.com"
    if commit.committer_email in auth_list:
        commit.committer_email = correct_email
        if commit.committer_name != correct_name:
            commit.committer_name = correct_name
'
