try %{ decl str mode char }

set global modelinefmt '
{{context_info}} | %opt{mode} | {{mode_info}} | %val{bufname} |
%val{cursor_line}:%val{cursor_char_column} |
%opt{modeline_info}
%val{session}'

try %{ decl -hidden str-list modal_keys }

define-command mode-key -params 1 -docstring "
    Execute the key in the current mode.
" %{
    eval "exec -save-regs '' %%opt{key_%opt{mode}_%arg{1}}"
}

define-command add-modal-keys-with-modifiers -params .. -docstring "
    add-modal-keys-with-modifiers <...keys>:
    for each key k in <keys> add k, K, <a-k>, <a-K> and <c-k> as modal key.
" %{
    eval %sh{
        printf 'add-modal-keys '
        for key in "$@"; do
            KEY=$(printf '%s' "$key" | tr a-z A-Z)
            printf '%s '   "$key"
            printf 'a_%s ' "$key"
            printf 'c_%s ' "$key"
            printf '%s '   "$KEY"
            printf 'a_%s ' "$KEY"
        done
    }
}

define-command add-modal-keys -params .. -docstring "
    add-modal-keys <...keys>: map the keys in global normal mode to be modal keys.
" %{
    eval %sh{
        printf 'set -add global modal_keys'
        printf ' %s' "$@"
        printf '\n'
        for key in "$@"; do
            map_key=$(printf '%s' "$key" | sed 's/_/-/g')
            map_key="<$map_key>"
            printf 'map global normal %s ": mode-key %s<ret>"\n' "$map_key" "$key"
        done
    }
}

define-command add-modes -params .. -docstring "
    add-modes <...modes>: make each key added with add-modal-keys available in these modes.
" %{
    eval %sh{
        if test -z "$kak_opt_modal_keys"; then
            printf 'fail No keys to add modes for! Use add-modal-keys.'
        fi
        for mode in "$@"; do
            for key in $kak_opt_modal_keys; do
                printf 'try %%{ decl -hidden str key_%s_%s }\n' "$mode" "$key"
            done
        done
    }
}

define-command map-modal -params 3 -docstring "
    map-modal <mode> <key> <keys>: map <key> to <keys> in mode <mode>

    Use add-modal-keys to make <key> available for mapping and add-modes to add a <mode>.
" %{
    try %{ set global "key_%arg{1}_%arg{2}" %arg{3} } catch %{
           set global "key_%arg{1}_%sh{printf '%s' ""$2"" | tr - _ | tr -d '<>'}" %arg{3} }
}

set global modal_keys
add-modal-keys-with-modifiers h t n s b w e v # r l ' .
add-modes char line view sel search

map global normal <esc> '<esc><space>' # : set window mode char<ret>'
map global normal g ': set window mode search<ret>'
map global normal k ': set window mode char<ret>'
map global normal x ': set window mode sel<ret>'
map global normal j ': set window mode line<ret>'
map global normal q ': set window mode view<ret>'
# f

# where to put f, t?
# where should select all, %, go?

map-modal char h h
map-modal char t j
map-modal char n k
map-modal char s l
map-modal char H H
map-modal char T J
map-modal char N K
map-modal char S L

map-modal char c-t C
map-modal char c-n <a-C>

map-modal char b b
map-modal char w w
map-modal char e e
map-modal char B B
map-modal char E E
map-modal char W W

map-modal char v ': line-select<ret>'
map-modal char V ': old_X<ret>'

def copy-line-dn %{ exec -itersel <a-x>d<a-p> }
def copy-line-up %{ exec -itersel <a-x>dk<a-P> }

# Select paragraphs (Use <a-i>p and repeat with full-line-ifte?)
map-modal char a-t ': copy-line-dn<ret>'
map-modal char a-n ': copy-line-up<ret>'
map-modal char a-T '' # : copy-line-dn<ret>'
map-modal char a-N '' # : copy-line-up<ret>'

# Extend selections left and right
map-modal char c-s   gl
map-modal char a-s \;Gl
map-modal char a-S   Gl
map-modal char a-h \;Gi
map-modal char a-H   Gi

map-modal line h ''
map-modal line t ]p
map-modal line n [p
map-modal line s ''
map-modal line H ''
map-modal line T }p
map-modal line N {p
map-modal line S ''

map-modal line <a-t> ': copy-par-dn<ret>'
map-modal line <a-n> ': copy-par-up<ret>'

def copy-par-dn %{ exec -itersel d]p<a-p> }
def copy-par-up %{ exec -itersel d[p[p<a-p> }

map-modal search h '<a-/>'
map-modal search t 'n'
map-modal search n '<a-n>'
map-modal search s '/'
map-modal search H '<a-?>'
map-modal search T 'N'
map-modal search N '<a-N>'
map-modal search S '?'
map-modal search c-t '/<ret>'
map-modal search c-n '<a-/><ret>'
map-modal search e ': select-all-focus-closest<ret>'

map-modal view h 'vh'
map-modal view t 'vj'
map-modal view n 'vk'
map-modal view s 'vl'
map-modal view H ''
map-modal view T ''
map-modal view N ''
map-modal view S ''
map-modal view w '<c-f>'
map-modal view v '<c-b>'
map-modal view e 'ge'
map-modal view b 'gg'
map-modal view E 'Ge'
map-modal view B 'Gg'

# ?add these to sel: k <a-k> $ <a-$>
map-modal sel h '<semicolon>'
map-modal sel t ')'
map-modal sel n '('
map-modal sel s ''
map-modal sel H '<a-:><a-semicolon>'
map-modal sel T '<a-)>'
map-modal sel N '<a-(>'
map-modal sel S '<a-:>'
map-modal sel b '<a-semicolon>'
map-modal sel w '<a-space>'
map-modal sel e '<space>'
