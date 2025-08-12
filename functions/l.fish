function l --description 'ls -1'
    command ls -1 (string split ' ' -- $LS_OPTIONS) $argv
end
