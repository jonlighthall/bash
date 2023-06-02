# bash
A collection of bash scripts of varying utility.

## Scripts specific to this repository

| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`install_packages`](install_packages.sh) | install dependencies  |
| [`make_links`](make_links.sh) | link scripts to `~/bin`  |

## General utilities

| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`update_packages`](update_packages.sh) | update, upgrade, and autoremove installed packages with `apt install`  then check for a release upgrade |
| log |
| add_paths | add arguments to PATH|
|bell|
|whats up| print host, display, user, path, and PID information |
| xtest | test X11 functionality |
| untar | unpack an archive |

## Time
| script               | description                           | useage |
| -------------------- | ------------------------------------  | -- |
|date2time| | `ls -tr --color=no | xargs -n 1 date +%s -r | xargs -n 1 date2age` |
|file age| | `\ls -tr | xargs -n 1 file_age` |
|print_times | print different time standards \
| sec2elap | convert an integer to a human-readable interval string |

## File cleanup
| script               | description                           | 
| -------------------- | ------------------------------------  | 
|cleam_mac|
|fix_bad_extensions |
|rmbin |
|unfix bad extensions |

# bash history
| script               | description                           | 
| -------------------- | ------------------------------------  | 
|dedup_history|
|sort_history |
| ps hist cp link |

# copying files
| script               | description                           | 
| -------------------- | ------------------------------------  | 
|cp tar |
| rpath |
| rpull |
| rpush |
| rsync2 |

# finding files
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| find matching |
| find matching and move |
| find missing and empty |
| grep matching |

## Git
see [git](git)

## Test
see [test](test)
