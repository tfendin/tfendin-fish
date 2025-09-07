function fish_right_prompt
    if test "$right_prompt_hidden" != "true"
        date '+%b %d %H:%M'
    end
end
