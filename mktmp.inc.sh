#!/usr/bin/env bash
mktmp () 
{ 
    INPUT_STRING=$0;
    OUTPUT_STRING=${INPUT_STRING//[![:alnum:]]};
    TEMPDIR=$( mktemp -dt "$OUTPUT_STRING.$$.XXXX" );
    printf "DEBUG: mktmp(): made directory '%s'\n" "$TEMPDIR" 1>&2;
    touch "$TEMPDIR"/.tmpdir
}

# Calmly and carefully remove our temporary directory, but only if it is empty
function rmtmp {
    test -e "$TEMPDIR" && # Ensure file exists
    test -d "$TEMPDIR" && # Ensure it is a directory
    test -O "$TEMPDIR" && # Ensure we own it 
    test -e "$TEMPDIR"/.tmpdir && # Check we left our secret smell
    rm "$TEMPDIR"/.tmpdir && # Remove secret file
    rmdir "$TEMPDIR"      # We delete the directory, hoping it's empty.
}
# vim: set ts=4 sts=4 sw=4 et:
