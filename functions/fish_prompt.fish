function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '$'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write pipestatus
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    set -l prompt_status
    if test $__fish_prompt_status_generation != $status_generation
        set __fish_prompt_status_generation $status_generation
        set -l status_color (set_color $fish_color_status)
        set -l statusb_color (set_color --bold $fish_color_status)
        set prompt_status " "(__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)
    else
        set prompt_status ""
    end


    echo -ns                                                      \
        (__prompt_login_with_shortened_me)' '                     \
        (set_color $color_cwd)                                    \
        (prompt_pwd)                                              \
        $normal                                                   \
        (__prompt_dirstack)                                       \
        (fish_vcs_prompt)                                         \
        $prompt_status                                            \
        " $suffix "
end

function __prompt_login_with_shortened_me
    set -l prompt_user "$USER"
    if set -q prompt_user_me; and string match -q "$prompt_user" "$prompt_user_me"
        set prompt_user "me"
    end
    USER=$prompt_user prompt_login
end


function __prompt_dirstack
    set -l stack_size (count $dirstack)

    if test $stack_size -gt 0
        printf " (d:%d)" (math $stack_size + 1)
    end
end
