
def autotable-align %{
    try %{
        exec -draft <a-i>ps\K\|<ret>&
    }
}

def -hidden autotable-shorten %{
    try %{
        exec -draft <a-i>ps\h\K\h+(?=\|)<ret>d
        autotable-align
    }
}

def autotable-enable %{
    hook -group autotable window InsertKey .* autotable-align
    hook -group autotable window ModeChange pop:insert:normal autotable-shorten
}

def autotable-disable %{
    rmhooks window autotable
}
