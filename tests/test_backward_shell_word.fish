#!/usr/bin/env fish
source ../functions/backward_shell_word.fish

function show_cursor --argument-names input pos
    echo "$input"
    set -l padding (string repeat -n (math $pos - 1) "~")
    echo "$padding^"
end

set -g __total_tests 0
set -g __passed_tests 0

# test_case: Assert one call to __backward_shell_word_pos
# Args: input cursor_pos expected_pos
function test_case --argument-names input cursor_pos expected_pos
    set -g __total_tests (math $__total_tests + 1)

    set -l result (__backward_shell_word_pos "$input" $cursor_pos)

    if test "$result" = "$expected_pos"
        #echo "✅ PASS: '$input' @ $cursor_pos → $result"
        set -g __passed_tests (math $__passed_tests + 1)
    else
        echo ""
        echo "❌ FAIL: '$input' @ $cursor_pos → $result (expected $expected_pos)"
        echo "   Actual:"
        show_cursor "$input" $result
        echo "   Expected:"
        show_cursor "$input" $expected_pos
    end
end

# -------------------------
# Tests
# -------------------------

# echo aba bab tab foo bar
test_case "echo aba bab tab foo bar" 24 21   # inside 'bar' → start of 'bar'
test_case "echo aba bab tab foo bar" 21 17   # at start of 'bar' → start of 'foo'
test_case "echo aba bab tab foo bar" 19 17   # inside 'foo' → start of 'foo'
test_case "echo aba bab tab foo bar" 14 13   # inside 'tab' → start of 'tab'
test_case "echo aba bab tab foo bar" 13 9   # at start of 'tab' → start of 'bab'
test_case "echo aba bab tab foo bar" 9 5    # at start of 'bab' → start of 'aba'
test_case "echo aba bab tab foo bar" 5 1     # at start of 'aba' → start of 'echo'
test_case "echo aba bab tab foo bar" 1 1     # at start of 'echo' → stays

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
test_case "ls -l /usr/bin /etc /var" 3 1     # at start of '-l' → start of 'ls'
test_case "ls -l /usr/bin /etc /var" 1 1     # start → stays

# # git commit -m 'Initial commit'
# # Indexes include quotes; behavior treats quotes as non-whitespace.
# test_case "git commit -m 'Initial commit'" 30 29  # after final quote → move onto quote
# test_case "git commit -m 'Initial commit'" 29 23  # at final quote → start of 'commit'
# test_case "git commit -m 'Initial commit'" 24 23  # inside 'commit' → start of 'commit'
# test_case "git commit -m 'Initial commit'" 23 16  # at space before 'commit' → start of 'Initial'
# test_case "git commit -m 'Initial commit'" 16 14  # at 'I' (start of Initial) → start of '-m'
# test_case "git commit -m 'Initial commit'" 14 12  # inside '-m' → start of '-m'
# test_case "git commit -m 'Initial commit'" 12 7   # at '-' (start of -m) → start of 'commit'
# test_case "git commit -m 'Initial commit'" 7 1    # at start of first 'commit' → start of 'git'
# test_case "git commit -m 'Initial commit'" 1 1    # start → stays

# # Edge cases
test_case "" 1 1                 # empty input
test_case "" 5 1                 # empty input with arbitrary cursor

test_case "word" 4 1             # inside 'word' → start
test_case "word" 2 1             # inside 'word' → start
test_case "word" 1 1             # already at start

test_case "w" 2 1                # single char
test_case "w" 1 1                # single char

test_case "     " 5 1            # only whitespace

test_case "word     " 9 1        # trailing space, inside whitespace → start of 'word'
test_case "word     " 5 1        # end of 'word' → start of 'word'
test_case "word     " 1 1        # already at start

test_case "     word" 9 5        # inside 'word' → start of 'word'
test_case "     word" 5 1        # at 'w' → stays at 'w' (start of word)
test_case "     word" 3 1        # in leading spaces → run left to start

test_case "echo hello!" 11 5     # after '!' → start of 'hello'
test_case "echo hello!" 10 5     # inside 'hello' → start of 'hello'
test_case "echo hello!" 5 1      # at 'h' → start of 'echo'
test_case "echo hello!" 4 1      # at space before 'hello' → start of 'echo'
test_case "echo hello!" 1 1      # start → stays

test_case "a b c d e" 9 8        # after 'e' → start of 'e'
test_case "a b c d e" 8 6        # space before 'e' → start of 'd'
test_case "a b c d e" 7 6        # at 'd' → start of 'c'
test_case "a b c d e" 6 4        # at 'd' → start of 'c'
test_case "a b c d e" 4 2        # space → start of 'b'
test_case "a b c d e" 1 1        # start → stays

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
