# Helper function for backward_shell_word and forward_shell_word
function __token_starts_core --description 'Compute token start indices from buf and injected tokens'
    set -l buf $argv[1]
    set -l toks $argv[2..-1]
    set -l n (string length -- $buf)
    set -l i 1
    set -l starts

    for tok in $toks
        # Skip whitespace
        while test $i -le $n
            set -l ch (string sub -s $i -l 1 -- $buf)
            if string match --quiet -r '\s' -- $ch
                set i (math $i + 1)
            else
                break
            end
        end

        set -l L (string length -- $tok)
        if test $L -eq 0
            set -a starts $i
            continue
        end

        # Fast path
        if test (string sub -s $i -l $L -- $buf) = "$tok"
            set -a starts $i
            set i (math $i + $L)
            continue
        end

        # Fallback search
        set -l patt (string escape --style=regex -- $tok)
        set -l tail (string sub -s $i -- $buf)
        set -l rel (string match -r -n -- $patt -- $tail)

        if test -n "$rel"
            set -l indexes (string split ' ' -- $rel)
            set -l start_idx $indexes[1]
            set -l start (math $i + $start_idx - 1)

            # Step back if the preceding char is a quote
            if test $start -gt 1
                set -l prev_ch (string sub -s (math $start - 1) -l 1 -- $buf)
                if string match -q '"*\'' -- $prev_ch
                    set start (math $start - 1)
                end
            end

            set -a starts $start
            set i (math $start + $L)
        else
            set -a starts $i
            set i (math $i + $L)
        end
    end

    printf "%s\n" $starts
end
