#!/usr/bin/env fish
source ../functions/backward_shell_word.fish

function show_cursor --argument-names input pos
    echo "$input"
    set -l padding (string repeat -n (math $pos - 1) "~")
    echo "$padding^"
end

set -g __total_tests 0
set -g __passed_tests 0

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
                # starting a quote
                set inquote (string sub -s 1 -l 1 $word)
                if string match -q "*$inquote" "$word" && test (string length -- $word) -gt 1
                    # quote starts and ends in same word
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

    # If we ended still in quotes, push the unfinished token (best‑effort)
    if test -n "$current"
        set tokens $tokens $current
    end

    printf "%s\n" $tokens
end

function test_case --description 'Run one test case against __backward_shell_word_pos_core with 0-based indexes'
    set -g __total_tests (math $__total_tests + 1)

    set -l cmdline       $argv[1]
    set -l cursor0       $argv[2]   # 0-based from caller
    set -l expected0     $argv[3]   # 0-based from caller

    # Simulate tokenization
    set -l toks (tokens_from_string $cmdline)

    # echo "Tokens:"
    # for token in $toks
    #     echo $token
    # end
    # echo "End of tokens"

    # Convert to 1-based before calling the core
    set -l cursor1 (math $cursor0 + 1)
    set -l actual1 (__backward_shell_word_pos_core "$cmdline" $cursor1 $toks)
    set --erase fish_trace
    # Convert back to 0-based for comparison
    set -l actual0 (math $actual1 - 1)

    if test "$actual0" = "$expected0"
        echo "OK   '$cmdline' (cur:$cursor0) -> $actual0"
        set -g __passed_tests (math $__passed_tests + 1)
    else
        echo "❌ FAIL '$cmdline' (cur:$cursor0) -> expected '$expected0', got '$actual0'"
        echo "   Actual:"
        show_cursor "$cmdline" $actual0
        echo "   Expected:"
        show_cursor "$cmdline" $expected0
    end
end

# -------------------------
# Tests
# -------------------------

# echo aba bab tab foo bar
#set fish_trace 1
test_case "echo aba bab tab foo bar" 24 21   # inside 'bar' → start of 'bar'
test_case "echo aba bab tab foo bar" 21 17   # at start of 'bar' → start of 'foo'
test_case "echo aba bab tab foo bar" 19 17   # inside 'foo' → start of 'foo'
test_case "echo aba bab tab foo bar" 15 13   # inside 'tab' → start of 'tab'
test_case "echo aba bab tab foo bar" 14 13   # inside 'tab' → start of 'tab'
test_case "echo aba bab tab foo bar" 13 9   # at start of 'tab' → start of 'bab'
test_case "echo aba bab tab foo bar" 9 5    # at start of 'bab' → start of 'aba'
test_case "echo aba bab tab foo bar" 5 0     # at start of 'aba' → start of 'echo'
test_case "echo aba bab tab foo bar" 1 0     # inside 'echo' → start of 'echo'
test_case "echo aba bab tab foo bar" 0 0     # at start of 'echo' → stays

# # ls -l /usr/bin /etc /var
test_case "ls -l /usr/bin /etc /var" 23 20   # inside '/var' → start of '/var'
test_case "ls -l /usr/bin /etc /var" 20 15   # at start of '/var' → end slash → start of '/etc'
test_case "ls -l /usr/bin /etc /var" 17 15   # inside '/etc' → start of '/etc'
test_case "ls -l /usr/bin /etc /var" 15 6   # at start of '/etc' → slash → start of '/usr/bin'
test_case "ls -l /usr/bin /etc /var" 12 6   # inside '/usr/bin' → start of '/usr/bin'
test_case "ls -l /usr/bin /etc /var" 10 6    # at slash after '/usr/' → start of '/usr'
test_case "ls -l /usr/bin /etc /var" 9 6     # inside 'usr' → start of 'usr'
test_case "ls -l /usr/bin /etc /var" 6 3     # before 'usr' slash → start of '-l'
test_case "ls -l /usr/bin /etc /var" 5 3     # at space after '-l' → start of '-l'
test_case "ls -l /usr/bin /etc /var" 3 0     # at start of '-l' → start of 'ls'
test_case "ls -l /usr/bin /etc /var" 0 0     # start → stays

# git commit -m 'Initial commit'
# Indexes include quotes; behavior treats quotes as non-whitespace.
test_case "git commit -m 'Initial commit'" 29 14  
test_case "git commit -m 'Initial commit'" 21 14  # at space before 'commit' → start of 'Initial'
test_case "git commit -m 'Initial commit'" 16 14  # at 'I' (start of Initial) → start of '-m'
test_case "git commit -m 'Initial commit'" 12 11  # inside '-m' → start of '-m'
test_case "git commit -m 'Initial commit'" 11 4   # at '-' (start of -m) → start of 'commit'
test_case "git commit -m 'Initial commit'" 7 4
test_case "git commit -m 'Initial commit'" 4 0    # at start of first 'commit' → start of 'git'
test_case "git commit -m 'Initial commit'" 0 0    # start → stays

# Line: ls '/dir A/file one' fileB '/dir B/file two'
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 41 27   # inside 'two' → start of '/dir B/file two'
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 39 27   # at space before 'two' → start of quoted word
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 30 27   # inside '/dir B/file two' → start of '/dir B/file two'
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 27 21   # at start of '/dir B/file two' → start of 'fileB'
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 22 21   # inside 'fileB' → start of 'fileB'
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 21 3    # at start of 'fileB' → start of '/dir A/file one'
test_case "ls '/dir A/file one' fileB '/dir B/file two'" 3 0     # at start of '/dir A/file one' → start of 'ls'

# Line: echo 'first part' "second part" plain
test_case "echo 'first part' \"second part\" plain" 34 32   # inside "plain" → start of 'plain'
test_case "echo 'first part' \"second part\" plain" 32 18   # inside "second part" → start of quoted string
test_case "echo 'first part' \"second part\" plain" 17 5   # at start of "second part" → jumps to start of 'first part'
test_case "echo 'first part' \"second part\" plain" 13 5    # inside 'first part' → jumps to opening '
test_case "echo 'first part' \"second part\" plain" 5 0     # before first quote → start of 'echo'

# Line: git commit -m 'Broken quoted commit
#test_case "git commit -m 'Broken quoted commit" 33 28   # inside unmatched quote → jump to opening '

# Line: echo "mismatch 'quotes" test
#test_case "echo \"mismatch 'quotes\" test" 28 1          # no proper pair — fallback to whitespace

# Line: echo 'incomplete quote test
#test_case "echo 'incomplete quote test" 28 1             # unmatched quote — fallback

# Line: say "mixed 'quotes" and 'then end
#test_case "say \"mixed 'quotes\" and 'then end" 34 27    # inside second quote — jump to its opening

# Line: echo 'this has a "nested" quote'
#test_case "echo 'this has a \"nested\" quote'" 35 30     # inside inner quotes — treat outer as dominant

# # Edge cases
test_case "" 0 0                 # empty input
test_case "" 5 0                 # empty input with arbitrary cursor

test_case "word" 4 0             # inside 'word' → start
test_case "word" 2 0             # inside 'word' → start
test_case "word" 0 0             # already at start

test_case "w" 2 0                # single char
test_case "w" 1 0                # single char
test_case "w" 0 0                # single char

test_case "     " 5 0            # only whitespace

test_case "word     " 9 0        # trailing space, inside whitespace → start of 'word'
test_case "word     " 4 0        # end of 'word' → start of 'word'
test_case "word     " 0 0        # already at start

test_case "     word" 9 5        # inside 'word' → start of 'word'
test_case "     word" 5 5        # at 'w' → stays at 'w' (start of word)
test_case "     word" 3 0        # in leading spaces → run left to start

test_case "echo hello!" 11 5     # after '!' → start of 'hello'
test_case "echo hello!" 10 5     # after '!' → start of 'hello'
test_case "echo hello!" 9 5     # inside 'hello' → start of 'hello'
test_case "echo hello!" 5 0      # at 'h' → start of 'echo'
test_case "echo hello!" 4 0      # at space before 'hello' → start of 'echo'
test_case "echo hello!" 1 0      # start → stays

test_case "a b c d e" 9 8        # after 'e' → start of 'e'
test_case "a b c d e" 8 6        # space before 'e' → start of 'd'
test_case "a b c d e" 7 6        # at 'd' → start of 'c'
test_case "a b c d e" 6 4        # at 'd' → start of 'c'
test_case "a b c d e" 4 2        # space → start of 'b'
test_case "a b c d e" 0 0        # start → stays

# -------------------------
# Final summary
# -------------------------
echo ""
if test $__passed_tests -eq $__total_tests
    echo -n "🎉"
else
    echo -n "❌"
end
echo " Final Summary: $__passed_tests of $__total_tests tests passed"
