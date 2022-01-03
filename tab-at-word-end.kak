
def at-idle-select-next %{
    hook -once window InsertIdle .* %{exec <c-n>}
}
decl str tab_at_word_end 'exec <c-x>w; at-idle-select-next'

def tab-at-word-end %{
    if-at-word-end %{ eval %opt{tab_at_word_end} } %{ exec -with-hooks <tab> }
}

def if-at-word-end -params 2 %{
    try %{
        exec -draft 'hL<a-K>\S\s<ret>'
        eval %arg{2}
    } catch %{
        eval %arg{1}
    }
}

map global insert <tab>   '<a-;>: tab-at-word-end<ret>'

rmhooks global tab-at-word-end
hook global -group tab-at-word-end InsertCompletionShow .* %{
    map window insert <tab>   <c-n>
    map window insert <s-tab> <c-p>
}
hook global -group tab-at-word-end InsertCompletionHide .* %{
    unmap window insert <s-tab>
    unmap window insert <tab>
}

