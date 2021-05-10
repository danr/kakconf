
try %{
    declare-user-mode surround
}

map global user u ': enter-user-mode surround<ret>'

def surround-add -params 2 %{
    exec i %arg{1} <esc> H a %arg{2} <esc>
}

def surround-del %{
    exec i <del> <esc> a <backspace> <esc>
}

def map-surround-add -params 3 %{
    map -docstring "add %sh{echo ""$2""|head -c 1}...%arg{3}" global surround %arg{1} ": surround-add %%~%arg{2}~ %%~%arg{3}~<ret>"
}

map-surround-add f <lt> >
map-surround-add g { }
map-surround-add c ( )
map-surround-add h [ ]
map-surround-add t %_'_ %_'_
map-surround-add n %_"_ %_"_

map -docstring del global surround d ": surround-del<ret>"

