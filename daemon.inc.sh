# redirect tty fds to /dev/null
redirect-std() {
    [[ -t 0 ]] && exec </dev/null
#    [[ -t 1 ]] && exec >/dev/null
    [[ -t 2 ]] && exec 2>/dev/null
}
 
# close all non-std* fds
close-fds() {
    eval exec {3..255}\>\&-
}
 
# full daemonization of external command with setsid
daemonize() {
    (                   # 1. fork
        redirect-std    # 2.1. redirect stdin/stdout/stderr before setsid
#        cd /            # 3. ensure cwd isn't a mounted fs
        # umask 0       # 4. umask (leave this to caller)
        # close-fds       # 5. close unneeded fds
#        exec setsid "$@"
    ) &
}
 
# daemonize without setsid, keeps the child in the jobs table
daemonize-job() {
    (                   # 1. fork
        redirect-std    # 2.2.1. redirect stdin/stdout/stderr
        trap '' 1 2     # 2.2.2. guard against HUP and INT (in child)
        cd /            # 3. ensure cwd isn't a mounted fs
        # umask 0       # 4. umask (leave this to caller)
        # close-fds       # 5. close unneeded fds
        if [[ $(type -t "$1") != file ]]; then
            "$@"
        else
            exec "$@"
        fi
    ) &
    disown -h $!       # 2.2.3. guard against HUP (in parent)
 }
