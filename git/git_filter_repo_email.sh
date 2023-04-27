git filter-repo --commit-callback '
    auth_list = [b"jlighthall@fsu.edu",b"lighthall@lsu.edu"]
    correct_email = b"jon.lighthall@gmail.com"
    if commit.author_email in auth_list:
       commit.author_email = correct_email
    if commit.committer_email in auth_list:
       commit.committer_email = correct_email
  '
