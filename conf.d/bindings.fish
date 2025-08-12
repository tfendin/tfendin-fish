if status is-interactive
    #
    # Standard functions
    #
    bind \cp history-prefix-search-backward
    bind \cn history-prefix-search-forward

    bind ctrl-alt-h backward-kill-word

    #
    # Custom functions
    
    bind ctrl-alt-b backward_shell_word
    bind ctrl-alt-f forward_shell_word
end
