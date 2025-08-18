
set -g __total_tests 0
set -g __passed_tests 0

function account_test
    set -g __total_tests (math $__total_tests + 1)    
end

function pass_test
    set -g __passed_tests (math $__passed_tests + 1)
end


function test_summary --on-event fish_exit --description "Write how many passes/fails there are and set exit code if there are fails"
    set -l final_status $status
    echo ""
    if test $__passed_tests -eq $__total_tests
        echo -n "🎉"
        set -g exit_code $final_status
    else
        echo -n "❌"
        set -g exit_code 1
    end
    echo " Final Summary: $__passed_tests of $__total_tests tests passed"
    exit $exit_code
end

function show_cursor --argument-names input pos
    echo "$input"
    set -l padding (string repeat -n (math $pos - 1) "~")
    echo "$padding^"
end

function tokens_from_string --description 'Split a string into tokens, preserving simple quoted strings'
    set -l str $argv
    set -l tokens
    set -l current ''
    set -l inquote ''

    for word in (string split ' ' -- $str)
        if test -n "$inquote"
            set current "$current $word"
            if string match -q "*$inquote" "$word"
                set -a tokens $current
                set current ''
                set inquote ''
            end
        else
            if string match -q "'*" -- "$word"; or string match -q '"*' -- "$word"
                # starting a quote
                set inquote (string sub -s 1 -l 1 $word)
                if string match -q "*$inquote" "$word" && test (string length -- $word) -gt 1
                    # quote starts and ends in same word
                    set -a tokens $word
                    set inquote ''
                else
                    set current $word
                end
            else
                set -a tokens $word
            end
        end
    end

    # If we ended still in quotes, push the unfinished token (best‑effort)
    if test -n "$current"
        set tokens $tokens $current
    end

    printf "%s\n" $tokens
end
