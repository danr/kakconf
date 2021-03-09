# insert mode with commas for symbols

map global insert , '<a-;>: insert-comma<ret>'



def insert-comma %{
    eval -itersel -draft %{
        exec h
        exec -draft -save-regs h hy
        echo -debug %val{selection_desc}
        echo -debug %val{selection}
        exec %sh{
            # ! , . $ %  ^ & * ( )
            # < = > | %  f g : + l
            # ( [ { ' `  d " } ] )
            # : q j \ ~  b * w v z
            pad=''
            f= =
            if test "$kak_reg_h" = ' '; then
                pad='<space>'
            fi
            case "$kak_selection" in
                "'") s=','  ;;
                r) s=', '   ;;
                b) s="\\"   ;;

                m) s='*'  ; s="$s$pad" ;;
                d) s='+'  ; s="$s$pad" ;;
                a) s='='  ; s="$s$pad" ;;
                f) s='|'  ; s="$s$pad" ;;

                h) s='['    ;;
                u) s=']'    ;;
                c) s='('    ;;
                .) s=')'    ;;
                t) s='{'    ;;
                e) s='}'    ;;

                s) s=';'    ;;

                *) ;;
            esac
            test -n "$s" && echo "di$s" || echo "li,"
        }
    }
}
