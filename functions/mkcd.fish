function mkcd --description "cd to directory, create it if doesn't exist" --argument-names directory
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    mkdir -pv {$directory}
    and cd {$directory}
end
