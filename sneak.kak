
try %{
    decl str sneakdir
    decl str sneak1
    decl str sneak2
}

def forward         -params 1 %{ %arg{1} /     }
def forward-extend  -params 1 %{ %arg{1} ?     }
def backward        -params 1 %{ %arg{1} <a-/> }
def backward-extend -params 1 %{ %arg{1} <a-?> }

def sneak-standard -params 1 %{
    set window sneakdir %arg{1}
    sneak-start %{
        exec -save-regs '' %opt{sneakdir} \Q %opt{sneak1} %opt{sneak2} <ret>
    }
}

def sneak-word -params 1 %{
    set window sneakdir %arg{1}
    sneak-start %{
        exec -save-regs '' %opt{sneakdir} \b[\w-]*\Q %opt{sneak1} \E[\w-]*\Q %opt{sneak2} \E[\w-]*\b <ret>
    }
}

def sneak-start -params 1 %{
    on-key %{
        set window sneak1 %val{key}
        on-key %{
            set window sneak2 %val{key}
            eval -save-regs '' %arg{1}
        }
    }
}

map global normal k     ': forward         sneak-standard<ret>'
map global normal K     ': forward-extend  sneak-standard<ret>'
map global normal <a-k> ': backward        sneak-standard<ret>'
map global normal <a-K> ': backward-extend sneak-standard<ret>'

# map global user s     ': forward           sneak-word<ret>'
# map global user S     ': forward-extend    sneak-word<ret>'
# map global user <a-s> ': backward          sneak-word<ret>'
# map global user <a-S> ': backward-extend   sneak-word<ret>'

