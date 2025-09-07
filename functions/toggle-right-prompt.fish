function toggle-right-prompt -d "Toggle visibility of the right prompt"
    if test "$right_prompt_hidden" != "true"
        set -g right_prompt_hidden true
    else
        set -g right_prompt_hidden false
    end
    return 0
end
