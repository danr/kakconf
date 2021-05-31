
try %{
    declare-user-mode test2
}

eval %sh{
    for mod in '' a- c- a-c-; do
        for key in {a..z} {A..Z} {0..9} . lt gt / ? minus _ '"' "'"; do
            printf '%s\n' "map global test2 <$mod$key> %{: exec -with-maps -with-hooks <$mod$key><ret>}"
        done
    done
}

map window user t ': enter-user-mode test2<ret>'
