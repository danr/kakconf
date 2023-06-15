map global insert <c-t> '<a-;>: close<ret>'

try %{ decl -hidden str closing_char }
try %{ decl -hidden str opening_desc }

# foo['zzaazz'] =
# 'xxx'   'yy'     'zz' a
# "xxx"   "yy"     "zz" a
# `xxx`   `yy`     `zz` a
# x` aoeu `

def -hidden find-quote-start -params 2 %{
    # doesn't handle backslash-escaped quotes
    eval -draft %{
        exec GH s "^([^%arg{1}]*%arg{1}[^%arg{1}]*%arg{1})*[^%arg{1}]*%arg{1}\K.*(?=.)" <ret>
        exec <a-K> %arg{1} <ret> h
        exec-draft %arg{2}
    }
}

def -hidden exec-draft -params .. %{ exec -draft -save-regs '' %arg{@} }

def -hidden find-open %{
    eval -save-regs ^c -draft %{
        exec-draft GGZ
        try %{ exec-draft [{ \; <a-Z>> ; nop extra } close for the %{..} block }
        try %{ exec-draft [[ \; <a-Z>> }
        try %{ exec-draft [( \; <a-Z>> }
        try %{ find-quote-start \' <a-Z>> }
        try %{ find-quote-start \" <a-Z>> }
        try %{ find-quote-start  ` <a-Z>> }
        exec 'z;'
        set window opening_desc ''
        set window closing_char ''
        try %{ exec <a-k>\Q{ <ret> ; set window closing_char  } ; set window opening_desc %val{selection_desc}}
        try %{ exec <a-k>\Q[ <ret> ; set window closing_char  ] ; set window opening_desc %val{selection_desc}}
        try %{ exec <a-k>\Q( <ret> ; set window closing_char  ) ; set window opening_desc %val{selection_desc}}
        try %{ exec <a-k>\Q' <ret> ; set window closing_char \' ; set window opening_desc %val{selection_desc}}
        try %{ exec <a-k>\Q" <ret> ; set window closing_char \" ; set window opening_desc %val{selection_desc}}
        try %{ exec <a-k>\Q` <ret> ; set window closing_char  ` ; set window opening_desc %val{selection_desc}}
    }
}

def close %{
    eval -draft -itersel %{
        exec <,>
        find-open
        exec i %opt{closing_char} <esc>
    }
}

try %{ decl -hidden range-specs openings }
try %{ addhl global/ ranges openings }

def open-show %{
    eval -draft %{
        exec <,>
        find-open
        try %{
            set window openings %val{timestamp} "%opt{opening_desc}|magenta+f"
        } catch %{
            set window openings %val{timestamp}
        }
    }
}

def goto-open %{
    eval -itersel %{
        find-open
        select %opt{opening_desc}
    }
}

rmhooks global open-show

hook -group open-show global WinCreate .* %{
    hook -group open-show window NormalIdle .* open-show
    hook -group open-show window InsertIdle .* open-show
}
