# Original (fish 4.0.2):
# bind --preset alt-d 'if test "$(commandline; printf .)" = \\n.; __fish_echo dirh; else; commandline -f kill-word; end'
# bind --preset alt-b prevd-or-backward-word
# bind --preset alt-f nextd-or-forward-word


if status is-interactive
    bind alt-d 'if test "$(commandline; printf .)" = \\n.; __fish_echo di; else; commandline -f kill-word; end'
    bind alt-f '
       if test "$(commandline; printf .)" = \\n.
          pu +1
          commandline -f repaint
       else
          commandline -f forward-token
       end'
    bind alt-b '
       if test "$(commandline; printf .)" = \\n.
          pu -1
          commandline -f repaint
       else
          commandline -f backward-token
       end'
end
