
# Support count with insert

# Remember register # and <c-r># in insert mode!

map global normal i %{:same-point-insert %val{count}<ret>}

def -hidden -params 1 same-point-insert %{
  eval %sh{
    if [[ $1 -eq 0 ]]; then
        echo exec i;
    else
        echo _same-point-insert $1
    fi
  }
}

def -hidden -params 1 _same-point-insert %{
    eval -save-regs i %{
        exec -no-hooks -draft a.<esc>\; \"id
        exec -no-hooks <a-:><a-\;>\; %arg{1} \"iP %arg{1} H <a-:>H s.<ret> c
        try print-selection-info
    }
}
