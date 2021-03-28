# insert mode with commas for symbols

def -hidden with-map -params 1..3 %{
    # X-macro style https://quuxplusone.github.io/blog/2021/02/01/x-macros/
    %arg{1} "'" '!'
    %arg{1}   , ','
    %arg{1}   . '+'
    %arg{1}   p '|'
    %arg{1}   y '%'

    eval %arg{2}

    %arg{1}   f '>'
    %arg{1}   g '{'
    %arg{1}   c '('
    %arg{1}   r 'C'
    %arg{1}   l '}'
    %arg{1}   / '?'
    eval %arg{3}


    %arg{1}   a '&'
    %arg{1}   o '@'
    %arg{1}   e '='
    %arg{1}   u '_'
    %arg{1}   i '~'
    eval %arg{2}

    %arg{1}   d '$'
    %arg{1}   h '['
    %arg{1}   t "'"
    %arg{1}   n '"'
    %arg{1}   s ']'
    eval %arg{3}

    %arg{1}   : 'å'
    %arg{1}   q 'ä'
    %arg{1}   j 'ö'
    %arg{1}   k '\'
    %arg{1}   x '^'
    eval %arg{2}

    %arg{1}   b '<'
    %arg{1}   m '*'
    %arg{1}   w ' '
    %arg{1}   v '`'
    %arg{1}   z ';'
}

try %{ decl -hidden str comma_info '' }

set global comma_info ''
def -hidden k -params 1..2 %{
    set -add global comma_info "%arg{1}%arg{2} "
}
with-map k %{
    set -add global comma_info '  '
} %{
    set -add global comma_info '
' }

def save-map %{
    nop %sh{
        echo 'm={}' > ~/code/keyboard-mapping/kakmap.py
    }
    def -hidden -override k -params 1..2 %{
        nop %sh{
            python -c 'if 1:
                import sys
                _, a, b = sys.argv
                if b.strip():
                    print(f"""m[{a!r}] = {b.replace("C", ")")!r}""")
            ' "$1" "$2" >> ~/code/keyboard-mapping/kakmap.py
        }
    }
    with-map k
}

def modal-clear %{
    info -style modal
}

def -hidden comma-info %{
    info -style below -anchor "%val{cursor_line}.%val{cursor_column}" %opt{comma_info}
}

rmhooks global commas
hook -group commas global InsertChar , %{
    hook -group comma-once -once window InsertIdle .* %{
        comma-info
    }

    def -hidden -override comma-cleanup %{
        rmhooks window comma-once
        modal-clear
    }

    def -hidden -override k -params 1..2 %{
        # did we just press $1?
        hook -group comma-once -once window InsertChar "\Q%arg{1}" "comma-replace-with %arg{2}"
    }

    def -hidden -override comma-replace-with -params .. %{
        # replace it with $2 then
        exec <backspace><backspace> %arg{1}
        try %{
            # C calls close instead
            exec -draft <esc> h <a-k> C <ret> d
            close
        }
        comma-cleanup
    }

    with-map k
    hook -group comma-once -once window ModeChange .* comma-cleanup
    hook -group comma-once -once window InsertChar .* comma-cleanup
    hook -group comma-once -once window RawKey [^,]+ comma-cleanup
}

def comma-replace %{
    info -title 'replace with char' 'enter char to replace with'
    on-key %{
        info
        eval %sh{
            if test "$kak_key" = ","; then
                echo comma-replace-comma
            else
                echo exec r "$kak_key"
            fi
        }
    }
}

def comma-replace-comma %{
    info -title 'replace with char' %opt{comma_info}
    on-key %{
        def -hidden -override k -params 1..2 %{
            eval %sh{
                if test "$kak_key" = "$1"; then
                    if test "$2" = "C"; then
                        echo exec 's.<ret>d'
                        echo close
                    else
                        echo exec r "$2"
                    fi
                fi
            }
        }
        with-map k
        info
    }
}

map global normal r ': comma-replace<ret>'
