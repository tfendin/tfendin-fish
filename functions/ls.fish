function ls --description 'My incarnation of ls'
    argparse --ignore-unknown 'a/all' 'A/almost-all' -- $argv

    set -l args --color=never --group-directories-first --classify

    if set -ql _flag_a; or set -ql _flag_A
        # noop
    else
        set -a args --ignore-backups
    end

    # argparse removes -a or -A from $argv, add them again
    if set -ql _flag_a
        set -a args -a
    end
    if set -ql _flag_A
        set -a args -A
    end

    command ls $args $argv
end
