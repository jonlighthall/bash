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

## copying files
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`cp_tar`](cp_tar.sh) |
| [`rpath`](rpath.sh) |
| [`rpull`](rpull.sh) |
| [`rpush`](rpush.sh) |
| [`rsync2`](rsync2.sh) |

## finding files
| script               | description                           | 
| -------------------- | ------------------------------------  | 
| [`find_matching`](find_matching.sh) |
| [`find_matching_and_move`](find_matching_and_move.sh) |
| [`find_missing_and_empty`](find_missing_and_empty.sh) |
| [`grep_matching`](grep_matching.sh) |

### [`grep_matching`](grep_matching.sh) Example
Copying data sets

in the xxxxxx data set, for example, there are over 87k files in the xxx/ directory and over 54k
files in the xx/ directory; over 141k files in total. Using utilities like ls or find to identify
files matching a pattern will take 10s of seconds per search. Instead, use the following
procedure.

First, 'ls' for 'find' the directory once. For example, use the command:

       find ./ -type f -name "*_f00500_*o.bin" > file_list/find_f00500_obin.txt

to generate a list of files matching a particular pattern within a directory. In this example
find_f00500_obin.txt is a list of all xxxxxx files with _f00500 in the file name, corresponding
to 500Hz frequency.

Then the ouput file, not the directory can be interrogated very quickly. The
list can be further wittled down with `grep` or `sed` commands. For example:

     grep "_d0010_f00500" find_500_obin.txt | sort -u > find_d0100_f00500_obin.txt

where find_d0010_f00500_obin.txt is a list of all files with _d0010_f00500 in the file name,
 corresponding to 10m depth and 500Hz frequency.

Once the list has been appropriately reduced, it can be searched using the function
grep_matching. Take for example, a list of file patterns, such as

       $ head out_grep_2023-07-11-t1255/xxxxxx_bathy_cluster_01.txt
       ens0[0-1][0-9]_2020[0-9]\\{6\\}_xxxx_000081_d0010_f00500_[0-9]\\{6\\}o.bin

using the command, 

      grep_matching out_grep_2023-07-11-t1255/xxxxxx_bathy_cluster_01.txt find_d0010_f00500_obin.txt

will generate a list of found files matching the pattern.

Further, the loop command may be used to find several matches

for n in {1..10}; do grep_matching out_grep_2023-07-11-t1255/xxxxxx_bathy_cluster_$(printf "%02d" $n).txt find_d0010_f00500_obin.txt ; done



## other scripts
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
