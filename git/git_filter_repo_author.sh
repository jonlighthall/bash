git filter-repo --partial --commit-callback '
    auth_list = [b"jlighthall@fsu.edu",b"lighthall@lsu.edu"]
    correct_email = b"jon.lighthall@gmail.com"
    if commit.author_email in auth_list:
       commit.author_email = correct_email
    '
