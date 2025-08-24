function di --description 'Print directory stack, one per line'
    argparse --max-args=0 -- $argv
    or return

    set -l index 0
    for directory in $PWD $dirstack
        set -l shortened (string replace -r '^'"$HOME"'($|/)' '~$1' -- $directory)
        printf "%2d %s\n" $index $shortened
        set index (math $index + 1)
    end
end
