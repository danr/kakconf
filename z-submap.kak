
try %{
    declare-user-mode z
}

map -docstring i3-right global z r ': i3-new-right<ret>'
map -docstring i3-right global z v ': i3-new-right<ret>'
map -docstring i3-down  global z w ': i3-new-down<ret>'

map -docstring vt global z t ': exec vt<ret>'
map -docstring vc global z c ': exec vc<ret>'
map -docstring vb global z b ': exec vb<ret>'

map -docstring gg global z g ': exec gg<ret>'
map -docstring Gg global z G ': exec Gg<ret>'
map -docstring ge global z n ': exec ge<ret>'
map -docstring Ge global z N ': exec Ge<ret>'

map -docstring '<line:> g' global z z ': prompt %{line: } %{exec %val{text} g}<ret>'
map -docstring '<line:> G' global z Z ': prompt %{line: } %{exec %val{text} G}<ret>'

map global normal z ': enter-user-mode z<ret>'

# map global z 6 ': exec gt<ret>'
# map global z 7 ': exec gc<ret>'
# map global z 8 ': exec gb<ret>'

# map global z w ': exec <lt>c-f>gc<ret>: enter-user-mode z<ret>'
# map global z v ': exec <lt>c-b>gc<ret>: enter-user-mode z<ret>'
# map global z W ': exec <lt>c-d>gc<ret>: enter-user-mode z<ret>'
# map global z V ': exec <lt>c-u>gc<ret>: enter-user-mode z<ret>'

map -docstring '<a-a> (o)uter' global z o '<a-a>'
map -docstring '<a-i> (i)nner' global z i '<a-i>'
