
def if -params 4..5 %{
    decl -hidden str ifeq_cont
    try %{
        def -hidden -override "ifeq-%arg{1}-%arg{1}" nop
        eval "ifeq-%arg{1}-%arg{3}"
        set global ifeq_cont %arg{4}
    } catch %{
        def -hidden -override if-empty- -params 1 nop
        eval "if-empty-%arg{5}"
        set global ifeq_cont nop
    } catch %{
        set global ifeq_cont %arg{5}
    }
    eval %opt{ifeq_cont}
}

decl -hidden int sel_line 1
decl -hidden str sel_mode normal
decl -hidden str sel_key_type none
decl -hidden str sel_buffer_type normal

def add-selection %{
    eval -no-hooks -draft -save-regs s %{
        exec '"sZ'
        edit -debug -scratch "*sel-%val{client}-%val{buffile}*"
        set buffer sel_buffer_type sel
        try %{
            add-highlighter buffer/sel line '%opt{sel_line}' default+r
        }
        exec "%opt{sel_line}g" <a-x> '"s<a-p>' a<space><esc> <space><semicolon>
        set buffer sel_line %val{cursor_line}
        exec GEd
    }
}

def change-selection -params 1 %{
    set window sel_key_type change-selection
    eval -no-hooks -save-regs s %{
        eval -draft %{
            edit -debug -scratch "*sel-%val{client}-%val{buffile}*"
            exec "%opt{sel_line}g" %arg{1} GL S<space><ret> '"sy'
            exec -draft '%|uniq<ret>'
            set buffer sel_line %val{cursor_line}
        }
        try %{
            exec '"sz'
        }
    }
}

def prev-selection %{ change-selection k }
def next-selection %{ change-selection j }

map global normal <a-u> ': prev-selection<ret>'
map global normal <a-U> ': next-selection<ret>'

rmhooks global selundo
hook -group selundo global ModeChange .*:.*:(.*) %{
    try %{
        set window sel_mode %val{hook_param_capture_1}
    }
}
hook -group selundo global NormalIdle .* %{
    if %opt{sel_buffer_type} == normal %{
        if %opt{sel_mode} == normal %{
            if %opt{sel_key_type} == change-selection %{
                set window sel_key_type none
            } %{
                add-selection
            }
        }
    }
}

