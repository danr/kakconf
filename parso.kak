eval %sh{
    python $(dirname "$kak_source")/parsokak.py init
}

try %{
    declare-user-mode parso
}

map global normal q ': enter-user-mode parso<ret>'
map global normal Q ': enter-user-mode -lock parso<ret>'

map -docstring next-node     global parso r ': parso next-node     <ret>'
map -docstring next-leaf     global parso s ': parso next-leaf     <ret>'
map -docstring next-at-level global parso l ': parso next-at-level <ret>'
map -docstring next-of-kind  global parso t ': parso next-of-kind  <ret>'
map -docstring last-child    global parso z ': parso last-child    <ret>'
map -docstring prev-node     global parso c ': parso prev-node     <ret>'
map -docstring prev-leaf     global parso h ': parso prev-leaf     <ret>'
map -docstring prev-at-level global parso g ': parso prev-at-level <ret>'
map -docstring prev-of-kind  global parso n ': parso prev-of-kind  <ret>'
map -docstring first-child   global parso m ': parso first-child   <ret>'
map -docstring parent        global parso w ': parso parent        <ret>'
