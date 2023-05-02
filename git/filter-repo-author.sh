git filter-repo $@ --partial --commit-callback '
    correct_name = b"Jon Lighthall"
    auth_list = [b"jlighthall@fsu.edu",b"lighthall@lsu.edu"]
    auth_list.append(b"jonlighthall@users.noreply.github.com")
    auth_list.append(b"jon.lighthall@ygmail.com")
    auth_list.append(b"jonathan.lighthall@")
    auth_list.append(b"jonathan.c.lighthall@")
    correct_email = b"jon.lighthall@gmail.com"
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
'
