git filter-repo $@ --partial --commit-callback '
    correct_name = b"Jon Lighthall"
    auth_list = [b"jlighthall@fsu.edu",b"lighthall@lsu.edu"]
    auth_list.append(b"jonlighthall@users.noreply.github.com")
    auth_list.append(b"jonathan.lighthall@")
    auth_list.append(b"jonathan.c.lighthall@")
    correct_email = b"jon.lighthall@gmail.com"
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
    if commit.committer_email in auth_list:
        commit.committer_email = correct_email
        if commit.committer_name != correct_name:
            commit.committer_name = correct_name
    if commit.tagger_email in auth_list:
        commit.tagger_email = correct_email
        if commit.tagger_name != correct_name:
            commit.tagger_name = correct_name
'
