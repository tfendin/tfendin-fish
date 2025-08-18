#!/usr/bin/env fish
source (status dirname)/../functions/forward_shell_word.fish
source (status dirname)/test_helper.fish


function tokens_from_string --description 'Split a string into tokens, preserving simple quoted strings'
    set -l str $argv
    set -l tokens
    set -l current ''
    set -l inquote ''

    for word in (string split ' ' -- $str)
        if test -n "$inquote"
            set current "$current $word"
            if string match -q "*$inquote" "$word"
                set tokens $tokens $current
                set current ''
                set inquote ''
            end
        else
            if string match -q "'*" -- "$word"; or string match -q '"*' -- "$word"
                set inquote (string sub -s 1 -l 1 $word)
                if string match -q "*$inquote" "$word" && test (string length -- $word) -gt 1
                    set tokens $tokens $word
                    set inquote ''
                else
                    set current $word
                end
            else
                set tokens $tokens $word
            end
        end
    end

    if test -n "$current"
        set tokens $tokens $current
    end

    printf "%s\n" $tokens
end

function test_case --description 'Run one test case against __forward_shell_word_pos_core with 0-based indexes'
    account_test
    set -l cmdline   $argv[1]
    set -l cursor0   $argv[2]
    set -l expected0 $argv[3]

    set -l toks (tokens_from_string $cmdline)

    set -l cursor1 (math $cursor0 + 1)
    #set -g fish_trace 1
    set -l actual1 (__forward_shell_word_pos_core "$cmdline" $cursor1 $toks)
    set --erase -g fish_trace
    set -l actual0 (math $actual1 - 1)

    if test "$actual0" = "$expected0"
        echo "OK   '$cmdline' (cur:$cursor0) -> $actual0"
        #set -g __passed_tests (math $__passed_tests + 1)
        pass_test
    else
        echo "❌ FAIL '$cmdline' (cur:$cursor0) -> expected '$expected0', got '$actual0'"
        echo "   Actual:"
        show_cursor "$cmdline" $actual0
        echo "   Expected:"
        show_cursor "$cmdline" $expected0
    end
end

# -------------------------
# Forward‑movement tests
# -------------------------

# echo aba bab tab foo bar
test_case "echo aba bab tab foo bar" 0 4     # at start 'echo' → end of 'echo'
test_case "echo aba bab tab foo bar" 1 4     # inside 'echo' → end of 'echo'
test_case "echo aba bab tab foo bar" 4 8     # at 'o' end → end of 'aba'
test_case "echo aba bab tab foo bar" 5 8     # start of 'aba' → end of 'aba'
test_case "echo aba bab tab foo bar" 8 12    # at end of 'aba' → end of 'bab'
test_case "echo aba bab tab foo bar" 9 12    # inside 'bab' → end of 'bab'
test_case "echo aba bab tab foo bar" 12 16   # at end of 'bab' → end of 'tab'
test_case "echo aba bab tab foo bar" 13 16   # inside 'tab' → end of 'tab'
test_case "echo aba bab tab foo bar" 16 20   # at end of 'tab' → end of 'foo'
test_case "echo aba bab tab foo bar" 17 20   # inside 'foo' → end of 'foo'
test_case "echo aba bab tab foo bar" 20 24   # at end of 'foo' → end of 'bar'
test_case "echo aba bab tab foo bar" 21 24   # inside 'bar' → end of 'bar'
test_case "echo aba bab tab foo bar" 24 24   # at end of 'bar' → EOL
test_case "echo aba bab tab foo bar" 25 24   # After EOL → EOL


test_case "echo '/dir A/file one' fileB '/dir B/file two'" 0 4
test_case "echo '/dir A/file one' fileB '/dir B/file two'" 1 4
test_case "echo '/dir A/file one' fileB '/dir B/file two'" 4 22
test_case "echo '/dir A/file one' fileB '/dir B/file two'" 13 22
test_case "echo '/dir A/file one' fileB '/dir B/file two'" 24 28
test_case "echo '/dir A/file one' fileB '/dir B/file two'" 28 46

# Short single word
test_case "word" 0 4
test_case "word" 2 4
test_case "word" 4 4  # after last char → EOL

# Whitespace only
test_case "     " 0 5
test_case "     " 3 5

# Quoted
test_case "git commit -m 'Initial commit'" 0 3   # 'git' → end
test_case "git commit -m 'Initial commit'" 4 10  # 'commit'
test_case "git commit -m 'Initial commit'" 11 13 # '-m'
test_case "git commit -m 'Initial commit'" 14 30 # quoted string
test_case "git commit -m 'Initial commit'" 29 30 # at final char → EOL

# Mixed quoted/unquoted
test_case "echo 'first part' plain" 0 4
test_case "echo 'first part' plain" 5 17
test_case "echo 'first part' plain" 18 23
test_case "echo 'first part' plain" 22 23
test_case "echo 'first part' plain" 23 23

