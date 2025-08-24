function tree
    argparse --ignore-unknown 'a' -- $argv

    set -l args 
    if not set -ql _flag_a
        set -a args -I '*~'
    end

    command tree $args $argv
end
