#!/usr/bin/env bash
# -a = -rlptgoD (no -H -A -X)
source include array


# echo 'US/Central - 10:26 PM (CST)'
# [[ "US/Central - 10:26 PM (CST)" =~ -[[:space:]]*([0-9]{2}:[0-9]{2}) ]] 
# echo ${BASH_REMATCH[1]}

array.new short
array.new long
function processHelp {
   local l s d # long short description
   local regShort regLong
   regShort="^-([[:alpha:][:digit:]]),?"'$'
   # regLong="--([[:alnum:]-]+)(=[[:alnum:]]+)?"
   regLong="^--([[:alnum:]-]+)"
   while read -r -a a # array
   do
      l= s= d=
      for word in "${a[@]}"; do
         if [[ $word =~ $regShort && $d = "" && $l = "" && $s = "" ]]; then s=${BASH_REMATCH[1]}
         elif [[ $word =~ $regLong && $d = "" && $l = "" ]]; then l=${BASH_REMATCH[1]}
         else
            d+=$word
            d+=" "
         fi
      done
      printf "%10s, %-34s %s\n" "$s" "$l" "$d"
      if [[ $s && $l ]]; then short[$s]=$l; fi
   done
}

# Carbon Copy Cloner using rsync:
# /Users/medion/Downloads/Carbon Copy Cloner.app/Contents/MacOS/ccc_helper.app/Contents/MacOS/rsync -A -X -H -go --numeric-ids -D --protect-decmpfs -l -rtpx -N --fileflags --force-change --protect-args --delete-during --filter=._/var/folders/ld/86dvd2t15ld9_3c_pn_wq0j40000gn/T/com.bombich.ccc_filter.QZAbHb // /Volumes/Macintosh HD
# fast rsync
#         -6, --ipv6                  prefer IPv6
# 0123456789 01234567890 0123456789 0123456789 0123456789 0123456789 0123456789
# man rsync | egrep '^        (-.,|   ) (--|                        )'
processHelp <<'EOD'
        -v, --verbose               increase verbosity
            --info=FLAGS            fine-grained informational verbosity
            --debug=FLAGS           fine-grained debug verbosity
            --msgs2stderr           special output handling for debugging
        -q, --quiet                 suppress non-error messages
            --no-motd               suppress daemon-mode MOTD (see caveat)
        -c, --checksum              skip based on checksum, not mod-time & size
        -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
            --no-OPTION             turn off an implied OPTION (e.g. --no-D)
        -r, --recursive             recurse into directories
        -R, --relative              use relative path names
            --no-implied-dirs       don't send implied dirs with --relative
        -b, --backup                make backups (see --suffix & --backup-dir)
            --backup-dir=DIR        make backups into hierarchy based in DIR
            --suffix=SUFFIX         backup suffix (default ~ w/o --backup-dir)
        -u, --update                skip files that are newer on the receiver
            --inplace               update destination files in-place
            --append                append data onto shorter files
            --append-verify         --append w/old data in file checksum
        -d, --dirs                  transfer directories without recursing
        -l, --links                 copy symlinks as symlinks
        -L, --copy-links            transform symlink into referent file/dir
            --copy-unsafe-links     only "unsafe" symlinks are transformed
            --safe-links            ignore symlinks that point outside the tree
            --munge-links           munge symlinks to make them safer
        -k, --copy-dirlinks         transform symlink to dir into referent dir
        -K, --keep-dirlinks         treat symlinked dir on receiver as dir
        -H, --hard-links            preserve hard links
        -p, --perms                 preserve permissions
            --fileflags             preserve file-flags (aka chflags)
        -E, --executability         preserve executability
            --chmod=CHMOD           affect file and/or directory permissions
        -A, --acls                  preserve ACLs (implies -p)
        -X, --xattrs                preserve extended attributes
            --hfs-compression       preserve HFS compression if supported
            --protect-decmpfs       preserve HFS compression as xattrs
        -o, --owner                 preserve owner (super-user only)
        -g, --group                 preserve group
            --devices               preserve device files (super-user only)
            --specials              preserve special files
        -t, --times                 preserve modification times
        -N, --crtimes               preserve create times (newness)
        -O, --omit-dir-times        omit directories from --times
        -J, --omit-link-times       omit symlinks from --times
            --super                 receiver attempts super-user activities
            --fake-super            store/recover privileged attrs using xattrs
        -S, --sparse                handle sparse files efficiently
            --preallocate           allocate dest files before writing
        -n, --dry-run               perform a trial run with no changes made
        -W, --whole-file            copy files whole (w/o delta-xfer algorithm)
        -x, --one-file-system       don't cross filesystem boundaries
        -B, --block-size=SIZE       force a fixed checksum block-size
        -e, --rsh=COMMAND           specify the remote shell to use
            --rsync-path=PROGRAM    specify the rsync to run on remote machine
            --existing              skip creating new files on receiver
            --ignore-existing       skip updating files that exist on receiver
            --remove-source-files   sender removes synchronized files (non-dir)
            --del                   an alias for --delete-during
            --delete                delete extraneous files from dest dirs
            --delete-before         receiver deletes before xfer, not during
            --delete-during         receiver deletes during the transfer
            --delete-delay          find deletions during, delete after
            --delete-after          receiver deletes after transfer, not during
            --delete-excluded       also delete excluded files from dest dirs
            --ignore-missing-args   ignore missing source args without error
            --delete-missing-args   delete missing source args from destination
            --ignore-errors         delete even if there are I/O errors
            --force-delete          force deletion of dirs even if not empty
            --force-change          affect user/system immutable files/dirs
            --force-uchange         affect user-immutable files/dirs
            --force-schange         affect system-immutable files/dirs
            --max-delete=NUM        don't delete more than NUM files
            --max-size=SIZE         don't transfer any file larger than SIZE
            --min-size=SIZE         don't transfer any file smaller than SIZE
            --partial               keep partially transferred files
            --partial-dir=DIR       put a partially transferred file into DIR
            --delay-updates         put all updated files into place at end
        -m, --prune-empty-dirs      prune empty directory chains from file-list
            --numeric-ids           don't map uid/gid values by user/group name
            --usermap=STRING        custom username mapping
            --groupmap=STRING       custom groupname mapping
            --chown=USER:GROUP      simple username/groupname mapping
            --timeout=SECONDS       set I/O timeout in seconds
            --contimeout=SECONDS    set daemon connection timeout in seconds
        -I, --ignore-times          don't skip files that match size and time
            --size-only             skip files that match in size
            --modify-window=NUM     compare mod-times with reduced accuracy
        -T, --temp-dir=DIR          create temporary files in directory DIR
        -y, --fuzzy                 find similar file for basis if no dest file
            --compare-dest=DIR      also compare received files relative to DIR
            --copy-dest=DIR         ... and include copies of unchanged files
            --link-dest=DIR         hardlink to files in DIR when unchanged
        -z, --compress              compress file data during the transfer
            --compress-level=NUM    explicitly set compression level
            --skip-compress=LIST    skip compressing files with suffix in LIST
        -C, --cvs-exclude           auto-ignore files in the same way CVS does
        -f, --filter=RULE           add a file-filtering RULE
        -F                          same as --filter='dir-merge /.rsync-filter' repeated: --filter='- .rsync-filter'
            --exclude=PATTERN       exclude files matching PATTERN
            --exclude-from=FILE     read exclude patterns from FILE
            --include=PATTERN       don't exclude files matching PATTERN
            --include-from=FILE     read include patterns from FILE
            --files-from=FILE       read list of source-file names from FILE
        -0, --from0                 all *from/filter files are delimited by 0s
        -s, --protect-args          no space-splitting; wildcard chars only
            --address=ADDRESS       bind address for outgoing socket to daemon
            --port=PORT             specify double-colon alternate port number
            --sockopts=OPTIONS      specify custom TCP options
            --blocking-io           use blocking I/O for the remote shell
            --outbuf=N|L|B          set out buffering to None, Line, or Block
            --stats                 give some file-transfer stats
        -8, --8-bit-output          leave high-bit chars unescaped in output
        -h, --human-readable        output numbers in a human-readable format
            --progress              show progress during transfer
        -i, --itemize-changes       output a change-summary for all updates
        -M, --remote-option=OPTION  send OPTION to the remote side only
            --out-format=FORMAT     output updates using the specified FORMAT
            --log-file=FILE         log what we're doing to the specified FILE
            --log-file-format=FMT   log updates using the specified FMT
            --password-file=FILE    read daemon-access password from FILE
            --list-only             list the files instead of copying them
            --bwlimit=RATE          limit socket I/O bandwidth
            --write-batch=FILE      write a batched update to FILE
            --only-write-batch=FILE like --write-batch but w/o updating dest
            --read-batch=FILE       read a batched update from FILE
            --protocol=NUM          force an older protocol version to be used
            --iconv=CONVERT_SPEC    request charset conversion of filenames
            --checksum-seed=NUM     set block/file checksum seed (advanced)
        -4, --ipv4                  prefer IPv4
        -6, --ipv6                  prefer IPv6
            --version               print version number
            --daemon                run as an rsync daemon
            --address=ADDRESS       bind to the specified address
            --bwlimit=RATE          limit socket I/O bandwidth
            --config=FILE           specify alternate rsyncd.conf file
        -M, --dparam=OVERRIDE       override global daemon config parameter
            --no-detach             do not detach from the parent
            --port=PORT             listen on alternate port number
            --log-file=FILE         override the "log file" setting
            --log-file-format=FMT   override the "log format" setting
            --sockopts=OPTIONS      specify custom TCP options
        -4, --ipv4                  prefer IPv4
        -6, --ipv6                  prefer IPv6
        -h, --help                  show this help (if used after --daemon)
EOD

for arg in r l p t g o D 
do
   echo ${short[$arg]}
done

RSYNC="rsync --exclude-from=exclude.txt --copy-dirlinks --links -az --numeric-ids --progress -e 'ssh -p 2222 -T -c arcfour -o Compression=no -x' root@spanky.nt4.com:/storage/fwbackups/ebtg/latest/* ."
