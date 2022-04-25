
try %{
    declare-user-mode jump
    declare-user-mode jump-extend
}

import sneak

# t on k
map global normal j     ': enter-user-mode jump<ret>'

map global jump        -docstring 'extend'     k ': enter-user-mode jump-extend<ret>'

map global jump        -docstring 'until'      t t
map global jump-extend -docstring 'until'      t T

map global jump        -docstring 'to'         f f
map global jump-extend -docstring 'to'         f F

map global jump        -docstring 'reverse'    r <a-f>
map global jump-extend -docstring 'reverse'    r <a-F>

map global jump        -docstring 'sneak'      n ': forward        sneak-standard<ret>'
map global jump-extend -docstring 'sneak'      n ': forward-extend sneak-standard<ret>'

map global jump        -docstring 'sneak word' w ': forward        sneak-word<ret>'
map global jump-extend -docstring 'sneak word' w ': forward-extend sneak-word<ret>'
