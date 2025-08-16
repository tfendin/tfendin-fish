
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

function __backward_shell_word_pos_core --description 'Compute target index using injected tokens'
    set -l buf $argv[1]
    set -l cur $argv[2]
    set -l toks $argv[3..-1]

    set -l n (string length -- $buf)
    if test $n -lt 1
        echo 1
        return
    end

    # Clamp cursor to [1, n]
    if test -z "$cur"
        set cur 1
    else if test $cur -lt 1
        set cur 1
    else if test $cur -gt $n
        set cur $n
    end

    # Helper: skip any whitespace left of cursor
    function __skip_left_ws --argument-names s p
        while test $p -ge 1
            set -l c (string sub -s $p -l 1 -- $s)
            if string match --quiet -r '\s' -- $c
                set p (math $p - 1)
            else
                break
            end
        end
        echo $p
    end

    # Step 1: if currently on whitespace, skip it first
    set cur (__skip_left_ws "$buf" $cur)

    set -l starts (__token_starts_core "$buf" $toks)
    if test (count $starts) -eq 0
        echo 1
        return
    end

    set -l target_start 1
    for idx in (seq 1 (count $toks))
        set -l s $starts[$idx]
        set -l e (math $s + (string length -- $toks[$idx]) - 1)

        if test $cur -gt $s; and test $cur -le $e
            # Inside token → jump to its start
            set target_start $s
            break
        else if test $cur -eq $s
            # On first char → jump to previous token (if any)
            if test $idx -gt 1
                set target_start $starts[(math $idx - 1)]
            else
                set target_start $s
            end
            break
        end

        if test $cur -gt $e
            set target_start $s
        end
    end

    echo $target_start
end

# Live version: pulls buf/cursor/tokens from the real commandline
# and moves the cursor in-place
function backward_shell_word --description 'Jump to start of current/prev token'
    set -l buf (commandline)
    set -l cur (commandline -C)
    set -l toks (commandline --tokens-raw)

    set -l newpos (__backward_shell_word_pos_core "$buf" $cur $toks)

    set -l newpos (math $newpos - 1)

    # Set the cursor to the computed position
    commandline -C $newpos
end
