function forward_shell_word
    set cursor_pos (commandline -C)
    set current_input (commandline)

    # Get input after cursor
    set input_after (string sub -s (math $cursor_pos + 1) -- $current_input)
    set words (string split ' ' $input_after)

    set word_count (count $words)
    if test $word_count -gt 0
        # Calculate new cursor position
        set next_word (string length $words[1])
        set new_pos (math "$cursor_pos + $next_word + 1") # account for space
        commandline -C $new_pos
    else
        commandline -C (string length $current_input)
    end
end
