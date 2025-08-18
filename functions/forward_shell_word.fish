function __forward_shell_word_pos_core --description 'Compute target index using injected tokens'
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

    # Helper: skip any whitespace right of cursor
    function __skip_right_ws --argument-names s p
        set -l n (string length -- $s)
        while test $p -le $n
            set -l c (string sub -s $p -l 1 -- $s)
            if string match --quiet -r '\s' -- $c
                set p (math $p + 1)
            else
                break
            end
        end
        echo $p
    end

    # Step 1: if currently on whitespace, skip it to the right
    set cur (__skip_right_ws "$buf" $cur)
    if test $cur -gt $n
        # Only trailing whitespace to the end → go to EOL (n + 1)
        echo (math $n + 1)
        return
    end

    set -l starts (__token_starts_core "$buf" $toks)
    if test (count $starts) -eq 0
        echo (math $n + 1)
        return
    end

    set -l target_after (math $n + 1)
    set -l count_t (count $toks)

    for idx in (seq 1 $count_t)
        set -l s $starts[$idx]
        set -l L (string length -- $toks[$idx])

        # Skip empty tokens to avoid degenerate ranges
        if test $L -eq 0
            continue
        end

        set -l e (math $s + $L - 1)

        if test $cur -lt $s
            # Before this token → jump to its end
            set target_after (math $e + 1)
            break
        else if test $cur -lt $e
            # Inside this token (not on last char) → jump to its end
            set target_after (math $e + 1)
            break
        else if test $cur -eq $e
            # On last char → jump to end of next token if any, else end of this one
            if test $idx -lt $count_t
                # Find next non-empty token to the right
                for jdx in (seq (math $idx + 1) $count_t)
                    set -l L2 (string length -- $toks[$jdx])
                    if test $L2 -gt 0
                        set -l s2 $starts[$jdx]
                        set -l e2 (math $s2 + $L2 - 1)
                        set target_after (math $e2 + 1)
                        break
                    end
                end
                if test -z "$target_after"
                    set target_after (math $e + 1)
                end
            else
                set target_after (math $e + 1)
            end
            break
        end
        # else: cur > e → keep scanning
    end

    echo $target_after
end

# Live version: pulls buf/cursor/tokens from the real commandline
# and moves the cursor in-place
function forward_shell_word --description 'Jump to end of current/next token'
    set -l buf (commandline)
    set -l cur (commandline -C)
    set -l toks (commandline --tokens-raw)

    set -l newpos (__forward_shell_word_pos_core "$buf" $cur $toks)

    # Convert 1-based "after token" position to fish's 0-based cursor index
    set -l newpos (math $newpos - 1)

    commandline -C $newpos
end
