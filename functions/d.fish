function d
    set current (basename $PWD)
    set siblings ../*/
    set index (contains -i ../$current/ $siblings)

    if not test "$index"
        echo "Current directory not found among siblings"
        return 1
    end
    
    set total (count $siblings)
    if test "$argv[1]" = "-"
        set index (math "($index - 1) % $total")
        if test "$index" -eq 0
            set index $total
        end
    else
        set index (math "($index + 1) % $total")
    end
    
    cd $siblings[$index]
end
