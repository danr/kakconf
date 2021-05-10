
try %{
    declare-user-mode z
}

map global z t ': exec vt<ret>'
map global z c ': exec vc<ret>'
map global z b ': exec vb<ret>'

map global z r ': i3-new-right<ret>'
map global z R ': i3-new-down<ret>'

map global z g ': exec gg<ret>'
map global z G ': exec Gg<ret>'
map global z n ': exec ge<ret>'
map global z N ': exec Ge<ret>'

map global z j ': prompt %{line: } %{exec %val{text} g}<ret>'
map global z J ': prompt %{line: } %{exec %val{text} G}<ret>'

map global normal z ': enter-user-mode z<ret>'

# map global z 6 ': exec gt<ret>'
# map global z 7 ': exec gc<ret>'
# map global z 8 ': exec gb<ret>'

# map global z w ': exec <lt>c-f>gc<ret>: enter-user-mode z<ret>'
# map global z v ': exec <lt>c-b>gc<ret>: enter-user-mode z<ret>'
# map global z W ': exec <lt>c-d>gc<ret>: enter-user-mode z<ret>'
# map global z V ': exec <lt>c-u>gc<ret>: enter-user-mode z<ret>'

