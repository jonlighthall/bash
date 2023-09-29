git filter-repo $@ --partial --commit-callback '
    # define correct name
    correct_name = b"Jon Lighthall"

    # list emails to replace
    auth_list = [b"jlighthall@fsu.edu",b"jon.lighthall@gmail.com",b"lighthall@lsu.edu"]

    # load url from file
    text_file = open(os.path.expanduser("~/utils/bash/git/url.txt"), "r")
    url = text_file.read()
    text_file.close()

    # add emails with url from files
    email_str="jonathan.c.lighthall@"+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)

    # define correct email
    email_str="jonathan.lighthall@"+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)
    correct_email = email_bin

    # conditionally replace author email and name
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
'
