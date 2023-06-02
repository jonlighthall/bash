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
| [`add_path`](add_path.sh) | add arguments to PATH |
| [`bell`](bell.sh) |
| [`log`](log.sh) |
| [`untar`](untar.sh) | unpack an archive |
| [`update_packages`](update_packages.sh) | update, upgrade, and autoremove installed packages with `apt install`  then check for a release upgrade |
| [`whatsup`](whatsup.sh) | print host, display, user, path, and PID information |
| [`xtest`](xtest.sh) | test X11 functionality |

## Time
| script               | description                           | useage |
| -------------------- | ------------------------------------  | -- |
| [`date2age`](date2age.sh) | | `ls -tr --color=no \| xargs -n 1 date +%s -r \| xargs -n 1 date2age` |
| [`date2time`](date2time.sh) |
| [`file_age`](file_age.sh) | | `\ls -tr \| xargs -n 1 file_age` |
| [`print_times`](print_times.sh) | print different time standards |
| [`sec2elap`](sec2elap.sh) | convert an integer to a human-readable interval string |

## File cleanup
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`clean_mac`](clean_mac.sh) |
| [`fix_bad_extensions`](fix_bad_extensions.sh) |
| [`rmbin`](rmbin.sh) |
| [`unfix_bad_extensions`](unfix_bad_extensions.sh) |

# bash history
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`dedup_history`](dedup_history.sh) |
| [`ps_hist_cp_lnk`](ps_hist_cp_lnk.sh) |
| [`sort_history`](sort_history.sh) |

# copying files
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`cp_tar`](cp_tar.sh) |
| [`rpath`](rpath.sh) |
| [`rpull`](rpull.sh) |
| [`rpush`](rpush.sh) |
| [`rsync2`](rsync2.sh) |

# finding files
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`find_matching`](find_matching.sh) |
| [`find_matching_and_move`](find_matching_and_move.sh) |
| [`find_missing_and_empty`](find_missing_and_empty.sh) |
| [`grep_matching`](grep_matching.sh) |

# other scripts
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`ls2md`](ls2md.sh) |
| [`set_path`](set_path.sh) |
| [`test_file`](test_file.sh) |
| [`wiggler`](wiggler.sh) |
| [`write_test_dirs`](write_test_dirs.sh) |

## Git
see [git](git)

## Test
see [test](test)
