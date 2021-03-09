map global insert <c-t> '<a-;>: close<ret>'

try %{ decl -hidden str closing_char }
try %{ decl -hidden str opening_desc }

def -hidden find-open %{
    eval -save-regs ^c -draft %{
        exec -draft -save-regs '' GGZ
        try %{ exec -draft -save-regs '' [{ <a-Z>- ; nop extra \} close for %{ ... } blocks to work }
        try %{ exec -draft -save-regs '' [[ <a-Z>- }
        try %{ exec -draft -save-regs '' [( <a-Z>- }
        try %{ exec -draft -save-regs '' [< <a-Z>- }
        try %{ exec -draft -save-regs '' [' <a-Z>- }
        try %{ exec -draft -save-regs '' [" <a-Z>- }
        try %{ exec -draft -save-regs '' [` <a-Z>- }
        exec 'z;'
        set window opening_desc %val{selection_desc}
        try %{ exec <a-k>{ <ret> ; set window closing_char \} }
        try %{ exec <a-k>[ <ret> ; set window closing_char \] }
        try %{ exec <a-k>( <ret> ; set window closing_char \) }
        try %{ exec <a-k>< <ret> ; set window closing_char \> }
        try %{ exec <a-k>' <ret> ; set window closing_char \' }
        try %{ exec <a-k>" <ret> ; set window closing_char \" }
        try %{ exec <a-k>` <ret> ; set window closing_char \` }
    }
}

def close %{
    eval -draft -itersel %{
        find-open
        exec i %opt{closing_char} <esc>
    }
}

try %{ decl -hidden range-specs openings }
try %{ addhl global/ ranges openings }

def open-show %{
    eval -draft %{
        exec <space>
        find-open
        set window openings %val{timestamp} "%opt{opening_desc}|magenta+f"
    }
}

def goto-open %{
    eval -itersel %{
        find-open
        select %opt{opening_desc}
    }
}

rmhooks global open-show

hook -group open-show global NormalIdle .* open-show
hook -group open-show global InsertIdle .* open-show
# hook -group open-show global RawKey .* open-show
