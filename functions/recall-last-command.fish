function recall-last-command --description "Insert previous command from history at cursor, cycling on repeated presses"
    # Initialize globals if not already set
    set --query __recall_last_command_index;        or set --global __recall_last_command_index         1
    set --query __recall_last_command_insert_start; or set --global __recall_last_command_insert_start -1
    set --query __recall_last_command_insert_end;   or set --global __recall_last_command_insert_end   -1
    set --query __recall_last_command_last_buffer;  or set --global __recall_last_command_last_buffer  ""

    set current_buffer (commandline --current-buffer)
    set cursor_position (commandline --cursor)

    # Reset cycle if buffer changed since last invocation
    if test "$current_buffer" != "$__recall_last_command_last_buffer"
        set __recall_last_command_index         1
        set __recall_last_command_insert_start -1
        set __recall_last_command_insert_end   -1
    end

    # Stop if we’ve run out of history
    if test $__recall_last_command_index -gt (count $history)
        return
    end

    set history_entry $history[$__recall_last_command_index]

    # If we have a previous insertion span, remove it
    if test $__recall_last_command_insert_start -ge 0
        set before (string sub -s 1 -l $__recall_last_command_insert_start "$current_buffer")
        set after  (string sub -s (math $__recall_last_command_insert_end + 1) "$current_buffer")
        set current_buffer "$before$after"
        set cursor_position $__recall_last_command_insert_start
    end

    # Decide whether to prefix with a space
    set prefix " "
    if test $cursor_position -gt 0
        set char_before (string sub -s $cursor_position -l 1 "$current_buffer")
        if test "$char_before" = " "
            set prefix ""
        end
    else
        set prefix ""
    end

    # Build the new snippet
    set snippet "$prefix($history_entry)"

    # Insert snippet at cursor
    set before (string sub -s 1 -l $cursor_position "$current_buffer")
    set after  (string sub -s (math $cursor_position + 1) "$current_buffer")
    set new_buffer "$before$snippet$after"

    commandline --replace -- $new_buffer
    commandline --cursor (math $cursor_position + (string length -- $snippet))

    # Update globals
    set --global __recall_last_command_last_buffer $new_buffer
    set --global __recall_last_command_insert_start $cursor_position
    set --global __recall_last_command_insert_end (math $cursor_position + (string length -- $snippet))
    set --global __recall_last_command_index (math $__recall_last_command_index + 1)
end
