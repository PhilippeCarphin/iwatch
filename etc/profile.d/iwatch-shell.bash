#!/usr/bin/env bash

_iwatch_shell_usage(){
    cat <<-EOF
		USAGE: $0 FILE(s) CMD

		Run CMD every time one of FILE(s) is written to.

		FILE(s): Comma separated list of files
		CMD: Command to run when an event happens.

		- If CMD is long running the previous run of CMD is sent the TERM
		  signal and a new run is started when an event happens.
		- CMD is run whenever certain events happen to the watched files so not
		  exactly when the file is written to.  Other events are ignored like
		  opening the file which happens very frequently if we have an LSP
		  running
	EOF
}

iwatch-shell()(
    case "$1" in -h|--help) _iwatch_shell_usage ; exit 0 ;; esac
    local logprefix="\033[38;5;242m${0##*/}:main"

    local resolve_percent=true
    if [[ "${1}" == --no-percent ]] ; then
        resolve_percent=false
        shift
    fi

    local -a files
    _iwatch_get_filenames "$1" ; shift
    if ((${#files[@]} == 0)) ; then
        echo "${0##*/}: ERROR: Zero files to watch" >&2
    fi

    local -a cmd=("$@")
    if ${resolve_percent} ; then
        local i e
        for i in ${!cmd[@]} ; do
            e=${cmd[i]}
            e=${e//%^/${files[*]}}
            e=${e//%/${files[0]}}
            cmd[i]=${e}
        done
    fi

    # Cant't do trap in the same process
    trap 'if kill -TERM ${run_pid} 2>/dev/null ; then wait ${run_pid} ; fi' EXIT

    local -a event event_files event_type
    case "$(uname)" in
        Darwin) watch_cmd(){ fswatch -1 "$@" ; } ;;
        *) watch_cmd(){ inotifywait -q "${files[@]}" ; } ;;
    esac

    # Watch a file, by default, fswatch runs forever and ouputs a line for each
    # event that occurs.  See [2].
    while true ; do
        if ! event=($(watch_cmd "${files[@]}")) ; then
            echo "${0}: Error in inotifywait command"
            exit 1
        fi
        event_file=${event[0]}
        event_type=${event[1]}
        echo "Obtained even on file ${event_file}"

        # Disregard some events that are triggered too frequently [1]
        case ${event_type} in
            OPEN) printf "$logprefix: INFO: ignoring event: ${event[*]}\033[0m\n"
                  continue ;;
        esac

        # Kill previous invocation of CMD if there is one and wait for it to finish
        if kill ${run_pid} 2>/dev/null ; then
            printf "waiting on process ${run_pid}\n"
            wait ${run_pid}
        fi

        # Start next run and note it's PID
        # bash -c 'run "$@"' "${0##*/}:run-handler" "${cmd[@]}" &
        # run_pid=$!
        _iwatch_runner "${event_type}" "${event_file}" "${cmd[@]}" &
        run_pid=$!

        # Sleep to avoid reacting to groups of events.
        sleep 0.5
    done
)
_iwatch_complete(){
    local cur prev words cword
    # local words
    words=()
    _comp__reassemble_words ":" words cword
    cur=${words[${cword}]}

    # declare -p words
    # declare -p cword
    case ${cword} in
        1) COMPREPLY+=($(compgen -W "@:" -- "${cur}")) ;;
        2) COMPREPLY+=($(compgen -c -- "${cur}")) ;;
        *) compopt -o default ;;
    esac
}
complete -F _iwatch_complete iwatch-shell

_iwatch_runner(){
    # Stack overflow answer: https://unix.stackexchange.com/a/146770/161630
    local caught_term=0
    local child_pid
    _term() {
        echo "${FUNCNAME[0]}: run process caught a signal"
        kill -TERM "$child_pid" 2>/dev/null
        caught_term=1
    }
    trap _term SIGTERM

    local event_type=$1 ; shift
    local event_file=$1 ; shift
    local -a args=("$@")

    local c="\033[38;5;242m"
    printf "$c========================================================================\033[0m\n"
    printf "$c${FUNCNAME[0]}: Event: \033[36m%s\033[0m$c,\033[0m\n" "${event_type}"
    printf "$c${FUNCNAME[0]}: File: \033[35m%s\033[0m\n" "${event_file}"
    printf "$c${FUNCNAME[0]}: Starting command '\033[1m%s\033[0m'\n" "${args[*]}"

    local a i
    for i in ${!args[@]} ; do
        if [[ $a == *@* ]] ; then
            _args[i]="${args[i]//@/${event_file}}"
        fi
    done

    "${args[@]}" &
    child_pid=$!

    wait ${child_pid}
    exit_code=$?

    if [[ ${caught_term} == 1 ]] ; then
        wait ${child_pid}
        printf "$c${FUNCNAME[0]}: Command '%s' ended by \033[1;33mTERM\033[0m\n" "$*"
    elif ! ((exit_code)) ; then
        printf "$c${FUNCNAME[0]}: Command '%s' ended with \033[1;32mSUCCESS\033[0m\n\n" "$*"
    else
        printf "$c${FUNCNAME[0]}: Command '%s' ended with \033[1;31mERROR: ${exit_code}\033[0m\n\n" "$*"
    fi
}

#
# Change elements of array by replacing '%^' by the list of files and '%' by
# the first file.  This is inspired by $^ (whole dependency list) and '$<'
# (the first dependency) for Makefiles but with '%' instead of '%<' because
# '%<' would only work inside quotes (otherwise the '<'  would get interpreted
# as a redirection) while '%' and '%^' work outside of quotes.
#

_iwatch_get_filenames(){
    files=()
    local args="$@"
    if [[ "$1" == @* ]] ; then
        local dir
        case $1 in
            @:*) dir=$(git rev-parse --show-toplevel)/${1#@:} ;;
            @) dir=$PWD/${1#@}
        esac
        printf "$logprefix: INFO: Watching all tracked files in ${dir}\033[0m\n" >&2
        while read f ; do
            if [[ -L ${f} ]] ; then
                printf "$logprefix: INFO: ... except $f because it is a link\033[0m\n" >&2
                continue
            fi
            files+=("${f}")
        done < <(git ls-files ${dir})
        printf "$logprefix: INFO: watching '$1' gave ${#files[@]} files\033[0m\n" >&2
        declare -p files >&2
    else
        local IFS="${IFS},"
        files=($1)
        #
        # See [1] for why links deserve a warning
        #
        for f in "${files[@]}" ; do
            if [[ -L $f ]] ; then
                printf "\033[33mWARNING\033[0m: file '$f' is a link\n"
            fi
        done
    fi
}

# So I can source the file and test individual functions interactively
if ! (return 0 2>/dev/null) ; then
    main "$@"
fi

# [1]: Language servers may open files and any git operation will open most of
#      the files in a repo.
#
#      This has a drawback that seems to only occur when vim opens files through
#      a link.  When vim opens a normal file, when we save the file, the events
#      MOVE_SELF followed by OPEN occur.  However, when opening a link, only
#      the event OPEN happens
#
#      We warn if the one of the files is a link because as long as the real
#      file is opened with vim, it doesn't matter if this script receives the
#      link or the real file, we will see a MOVE_SELF event.
#
# [2]: Tested with VIM.  The inotifywait command takes a file name but it looks
#      up the inode number of that file and watches that inode.  The problem
#      with vim is that when we save, vim deletes the initial file and creates
#      a new one which means that it gets a new inode.  This is why the
#      commented out version below with 'inotifywait ${file} | while ... done'
#      doesn't work.  The following does work because with every event, we
#      relaunch inotifywait.
#
#      I'm not sure if this would be a problem with fswatch because I went with
#      the loop option to make inotifywait work.
#
