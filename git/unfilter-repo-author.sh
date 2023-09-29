git filter-repo $@ --partial --commit-callback '
    correct_name = b"Jon Lighthall"
    auth_list = [b"jlighthall@fsu.edu",b"jon.lighthall@gmail.com",b"lighthall@lsu.edu"]
    text_file = open(os.path.expanduser("~/utils/bash/git/url.txt"), "r")
    url = text_file.read()
    text_file.close()
    email_str="jonathan.c.lighthall@"+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)
    email_str="jonathan.lighthall@"+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)
    correct_email = email_bin
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
'
