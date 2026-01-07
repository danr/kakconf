try %{ decl str mode normal }

set global modelinefmt '
{{context_info}} | {StatusLineMode}%opt{mode}{default} | {{mode_info}} | %val{bufname} |
%val{cursor_line}:%val{cursor_char_column} |
%opt{modeline_info}
%val{session}'

def key -params 2 %{eval -save-regs '' "exec -save-regs '' %%opt{key_%arg{1}_%arg{2}}"}

def mode-key -params 1 %{try %{key %opt{mode} %arg{1}} catch %{enter-mode normal; key %opt{mode} %arg{1}}}

def map-modal -params 1 %{
    eval %sh{
        # kakquote() { printf "%s" "$*" | sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }
        kakquote() { printf "'%s'" "${*//\'/\'\'}"; }
        map ()  {
            mode="$1"
            key="$2"
            rhs="$3"
            opt_key="${key//-/_}"
            printf '%s\n' "map global normal <$key> $(kakquote ": mode-key $opt_key<ret>")"
            printf '%s\n' "decl str key_${mode}_${opt_key} $(kakquote "$rhs")"
        }
        eval "$1"
    }
}

def enter-mode -params 1 %{
    set window mode %arg{1}
    trigger-user-hook "ModeEnter:%arg{1}"
    # info -- "-- %arg{1} mode --"
    # echo -- "-- %opt{mode} mode --"
    hook -once window RawKey .* %{
        info -anchor "%val{cursor_line}.%val{cursor_column}" -style above -markup -- "{yellow}-- %opt{mode} mode --"
    }
}

rmhooks global modal
hook global -group modal User ModeEnter:line %{exec x}

def move-line-dn %{ exec -draft <a-x>d<a-p> }
def move-line-up %{ exec -draft <a-x>dk<a-P> }

map-modal %{
    map normal h h
    map normal t j
    map normal n k
    map normal s l
    map normal H H
    map normal T J
    map normal N K
    map normal S L

    map normal c-n ': eval -draft move-lines-up<ret>'
    map normal c-t ': eval -draft move-lines-down<ret>'

    map visual h H
    map visual t J
    map visual n K
    map visual s L

    mnv () {
        map normal "$1" "$2"
        map visual "$1" "$3"
    }

    mnv w w W
    mnv e e E
    mnv b b B
    mnv a-w '<a-w>' '<a-W>'
    mnv a-e '<a-e>' '<a-E>'
    mnv a-b '<a-b>' '<a-B>'
    mnv c-a gh GH
    mnv c-s gl GL
    mnv c-h gi GI

    map normal c-s   gl
    map normal c-h   gi
    map normal c-a   gh

    map normal   a-s '<semicolon>Gl'
    map normal a-s-s             Gl
    map normal   a-h '<semicolon>Gi'
    map normal a-s-h             Gi
    map normal   a-a '<semicolon>Gh'
    map normal a-s-a             Gh

    # map line h ': enter-mode normal<ret>: mode-key h<ret>'
    map line t 'Jx'
    map line n 'Kx'
    # map line s ': enter-mode normal<ret>: mode-key s<ret>'

    map block h H
    map block t C
    map block n '<a-C>'
    map block s L
    map block H h
    map block T j
    map block N k
    map block S l

    map par h '<lt>'
    map par t ]p
    map par n [p
    map par s '<gt>'
    map par h '<lt>'
    map par N '{p'
    map par T '}p'
    map par s '<gt>'

    map par c-n ': eval -draft move-par-up<ret>'
    map par c-t ': eval -draft move-par-down<ret>'

    map sel h '<a-:><a-semicolon>'
    map sel t ')'
    map sel n '('
    map sel s '<a-:>'
    map sel H ''
    map sel T '<a-)>'
    map sel N '<a-(>'
    map sel S ''

    map search h '<a-/>'
    map search t 'n'
    map search n '<a-n>'
    map search s '/'
    map search H '<a-?>'
    map search T 'N'
    map search N '<a-N>'
    map search S '?'
    map search c-t '/<ret>'
    map search c-n '<a-/><ret>'
}

def normal-esc %{
    eval %sh{
        if test "$kak_opt_mode" == "normal"; then
            echo exec '<esc><,>'
        else
            echo enter-mode normal
        fi
    }
}

map global normal <esc> ': normal-esc<ret>'
map global normal v     ': enter-mode visual <ret>'
map global normal V     ': enter-mode line   <ret>'
map global normal <c-v> ': enter-mode block  <ret>'
map global normal x     ': enter-mode par    <ret>'
map global normal "'"   ': enter-mode sel    <ret>'
map global normal <c-/> ': enter-mode search <ret>'




##
## map-modal view h 'vh'
## map-modal view t 'vj'
## map-modal view n 'vk'
## map-modal view s 'vl'
## map-modal view H ''
## map-modal view T ''
## map-modal view N ''
## map-modal view S ''
## map-modal view w '<c-f>'
## map-modal view v '<c-b>'
## map-modal view e 'ge'
## map-modal view b 'gg'
## map-modal view E 'Ge'
## map-modal view B 'Gg'
##

# From alexherbo2/move-line.kak
def move-lines-down -docstring 'Move selected lines down' %{
    # Select whole lines
    execute-keys '<x><a-_><a-:>'

    # Iterate each selection and move the lines below
    evaluate-commands -itersel %{
        execute-keys -draft 'w'
        execute-keys -draft 'Zj<x>dzP'
    }
}

# From alexherbo2/move-line.kak
def move-lines-up -docstring 'Move selected lines up' %{
    # Select whole lines
    execute-keys '<x><a-_><a-:>'

    # Iterate each selection and move the lines above
    evaluate-commands -itersel %{
        execute-keys -draft '<a-;>b'
        execute-keys -draft '<a-;>Zk<x>dzp'
    }
}

def move-par-down -docstring 'Move selected paragraph down' %{
    # Select whole paragraphs
    exec 'S\n\n+<ret><a-a>p'

    # Iterate each selection and move the paragraph below
    evaluate-commands -itersel %{
        execute-keys -draft '<a-a>p'
        execute-keys -draft 'Z<a-a>pdzP'
    }
}

def move-par-up -docstring 'Move selected paragraph up' %{
    # Select whole paragraphs
    exec 'S\n\n+<ret><a-a>p'

    # Iterate each selection and move the paragraph above
    evaluate-commands -itersel %{
        execute-keys -draft '[p[p<a-a>p'
        execute-keys -draft 'Z[p[p<a-a>pdzp'
    }
}
