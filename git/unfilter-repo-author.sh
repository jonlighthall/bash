git filter-repo $1 --partial --commit-callback '
    correct_name = b"Jon Lighthall"
    auth_list = [b"jlighthall@fsu.edu",b"jon.lighthall@gmail.com",b"lighthall@lsu.edu"]
    auth_list.append(b"jonathan.c.lighthall@")
    correct_email = b"jonathan.lighthall@"
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
'
