
map global insert , '<a-;>: comma-swallow<ret>'
def comma-swallow -docstring 'swallow the previous character when pressing ,' %{
    eval -itersel -draft %{
        exec h
        exec -draft -save-regs h hy
        echo -debug %val{selection_desc}
        echo -debug %val{selection}
        eval %sh{
            # ! , . $ %  ^ & * ( )
            # < = > | %  f g : + l
            # ( [ { ' `  d " } ] )
            # : q j \ ~  b * w v z
            function sub() {
                echo exec di "$1"
            }
            function pad() {
                if test "$kak_reg_h" = ' '; then
                    sub "'$1 '"
                else
                    sub "$1"
                fi
            }
            case "$kak_selection" in
                "'") sub ','    ;;
                 r ) sub "', '" ;;
                 b ) sub "\\"   ;;

                 m ) pad '*'  ;;
                 d ) pad '+'  ;;
                 a ) pad '='  ;;
                 f ) pad '|'  ;;

                 h ) sub '['  ;;
                 u ) sub ']'  ;;
                 . ) sub ')'  ;;
                 t ) sub '{'  ;;
                 e ) sub '}'  ;;
                 s ) sub ';'  ;;

                 c ) echo "exec d"
                     echo "close"
                     ;;

                 * ) echo "exec li," ;;
            esac
        }
    }
}
