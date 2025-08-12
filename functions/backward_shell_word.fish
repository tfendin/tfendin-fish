function __backward_shell_word_pos --argument input cursor_pos
    set -l n (string length -- $input)
    if test $n -lt 1
        printf "%s\n" 1
        return
    end

    if test $cursor_pos -lt 1
        set cursor_pos 1
    end
    if test $cursor_pos -gt $n
        set cursor_pos $n
    end

    # Step 1: Skip trailing whitespace
    while test $cursor_pos -ge 1
        set -l char (string sub -s $cursor_pos -l 1 -- $input)
        if not string match --quiet -r '\s' -- $char
            break
        end
        set cursor_pos (math $cursor_pos - 1)
    end

    # If we skipped everything, just start at 1
    if test $cursor_pos -lt 1
        set cursor_pos 1
    end

    # Step 2: Move left until previous char is whitespace
    while test $cursor_pos -gt 1
        set -l prev (string sub -s (math $cursor_pos - 1) -l 1 -- $input)
        set cursor_pos (math $cursor_pos - 1)
        if string match --quiet -r '\s' -- $prev
            break
        end
    end

    printf "%s\n" $cursor_pos
end

function backward_shell_word
    set input (commandline)
    set cursor_pos (commandline -C)
    set new_pos (__backward_shell_word_pos $input $cursor_pos)
    commandline -C $new_pos
end
