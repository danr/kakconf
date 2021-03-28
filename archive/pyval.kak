
def pyval %{
    eval -no-hooks -collapse-jumps -draft %{
        try %{
            exec 'ge<a-x><a-k>"""<ret>k<a-?>"""<ret>JGh<a-x>d'
        } catch %{
            exec 'geo"""<ret>"""<esc>gh'
        }
        exec ! %sh{
            out=$(mktemp)
            err=$(mktemp)
            python $kak_buffile > $out 2> $err
            echo cat '<space>' "$err" '";cat"' '<space>' "$out" '<ret>'H
        }
    }
}

