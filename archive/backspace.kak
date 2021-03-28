# make backspace remove spaces snapping at four characters

def backspace %{
    eval -no-hooks -itersel %{
        try %{
            # corner case: at the start of line
            exec -draft ';<a-k>^.\z<ret>i<backspace>'
        } catch %{ try %{
            exec -draft ';' hGhs^([^\t]{ %opt{tabstop} })*\K\h{1, %opt{tabstop} }\z<ret>d
        } catch %{
            # fall back to normal backspace if there are no spaces to remove
            exec -draft i<backspace>
        }}
    }
}

def backspace-keymap %{
    map global insert <backspace> '<a-;>:backspace<ret>'
    map global insert <s-tab>   '<a-;>:backspace<ret>'
}

def backspace-unkeymap %{
    # map global insert <backspace> <backspace>
    # map global insert <s-tab>     <s-tab>
}

backspace-keymap

# map global normal a ': backspace-unkeymap<ret>a'
# hook -group kakrc global NormalKey a %{
#     # fall back on normal backspace behaviour in append mode
#     backspace-unkeymap
# }

# hook -group kakrc global ModeChange insert:normal %{
#     backspace-keymap
# }


