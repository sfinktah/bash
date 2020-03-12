#!/usr/bin/env bash
TARGET=/etc/ssh/moduli
TARGET_BACKUP=/etc/ssh/moduli.orig

function error { printf "$@"; echo; exit 1; } >&2

function require_cmd { ! which "$1" 2>&1 > /dev/null && error "Required command '%s' missing"; }

function file_size { FILE_SIZE=$( stat --printf="%s" "$1" ); }

function check_moduli { test -f "$1" || error "moduli file '%s' does not exist" "$1"; 
   file_size "$1"; (( FILE_SIZE < 65535 )) && error "moduli file '%s' is too small" "$1"; }

# mtime; how many minutes since file $1 was modified (mtime)
function mtime { now=$( date +%s ); mtime=$( stat --printf="%Y" "$1" ); 
   echo $(( ( now - mtime ) / 60 )); return $(( ( now - mtime ) / 3600 )); }

function mktmp { TEMPDIR=$( mktemp -dt "$(basename -- "$0").$$.XXXX" ); touch "$TEMPDIR"/.tmpdir; }

# Calmly and carefully remove our temporary directory
function rmtmp {
   test -e "$TEMPDIR" && # Ensure file exists
   test -d "$TEMPDIR" && # Ensure it is a directory
   test -O "$TEMPDIR" && # Ensure we own it
   test -e "$TEMPDIR"/.tmpdir && # Check we left our secret smell
   rm -rdi "$TEMPDIR" # Hopefully we can safely delete
}

function main {
   for cmd in stat curl; {
         require_cmd "$cmd"
   }

   mtime=$( mtime "$TARGET" )
   (( mtime < 86400 )) && error "moduli file has been updated in the last %s minutes" "$mtime" 

   check_moduli "$TARGET"

   pushd . > /dev/null; 

   mktmp && cd "$TEMPDIR" || error "couldn't move into temporary directory %s" "$TEMPDIR"
   curl --insecure https://2ton.com.au/dhparam/2048/ssh -o moduli || error "curl responded with non-0 exit"

   check_moduli "moduli"
   cp "$TARGET" "$TARGET_BACKUP" || error "failure creating backup %s" "$TARGET_BACKUP"
   cat moduli > "$TARGET" || error "failure overwriting %s" "$TARGET"

   rm moduli
   cd ~1
   rmtmp  

   echo "OK"
   exit 0
}

main
