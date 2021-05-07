map global normal ] ': expand<ret>'

map global normal ( ': move-line-above %val{count}<ret>'
map global normal ) ': move-line-below %val{count}<ret>'

map global user m ': mark-word<ret>'

map global normal ^ ': vertical-selection-up-and-down<ret>'

hook -group kakrc global BufSetOption filetype=(java|type)script %{
    set buffer tabstop 2
    set buffer indentwidth 2
}
hook -group kakrc global WinSetOption filetype=(java|type)script %{
    set window tabstop 2
    set window indentwidth 2
}

# Dvorak movement, dodging empty lines
import nonempty-lines
map global normal t 'j: while-empty j<ret>'
map global normal n 'k: while-empty k<ret>'
map global normal T 'J: while-empty J<ret>'
map global normal N 'K: while-empty K<ret>'
map global normal s l
map global normal S L

# Remove empty lines above and under
map global normal x ': remove-adjacent-empty-line j<ret>'
map global normal X ': remove-adjacent-empty-line k<ret>'
map global normal <a-x> ': remove-all-adjacent-empty-lines<ret>'

map global normal "'" )
map global normal '"' <a-)>
map global normal "<a-'>" (
map global normal '<a-">' <a-(>

# Make new selections above and under, left and right, and at words
def newsel -params 1 %{
    eval -no-hooks -save-regs i %{
        exec \"iZ
        exec %arg{1}
        exec \"i<a-z>a
    }
    # print-selection-info
}
map global normal <c-t>       C
map global normal <c-n>       <a-C>
map global normal <backspace> ': newsel h<ret>'
map global normal <c-s>       ': newsel l<ret>'
map global normal <c-w>       ': newsel <lt>a-w<gt> <ret>'
map global normal <c-e>       ': newsel <lt>a-e<gt> <ret>'
map global normal <c-b>       ': newsel <lt>a-b<gt> <ret>'
map global normal <a-m>       ': newsel m\;<ret>'
                 # <c-m> is <ret>

# Select paragraphs (Use <a-i>p and repeat with full-line-ifte?)
map global normal <a-t> ]p
map global normal <a-n> [p
map global normal <a-T> }p
map global normal <a-N> {p
map global normal <a-s-t> }p
map global normal <a-s-n> {p

# Extend selections left and right
map global normal <c-s>   gl
map global normal <a-s> \;Gl
map global normal <a-S>   Gl
map global normal <backspace> gi
map global normal <c-h> gi
map global normal <a-h> \;Gi
map global normal <a-H>   Gi
map global normal <c-a>   gh
map global normal <a-a> \;Gh
map global normal <a-A>   Gh

# Outer object <a-[oO]>
map global normal <a-o> <a-a>
map global normal <a-O> <a-A>


# g: next/prev match
map global normal g     n978vh
map global normal G     N978vh
map global normal <a-g> <a-n>978vh
map global normal <a-G> <a-N>978vh

# J a'la vim
def J %{exec -itersel <A-J><a-_>c<space><esc><space>vm }
map global normal J ': J<ret>'
map -docstring join global user   j <A-J>

# Overwrite a'la vim R
import overwrite
map global normal R ': overwrite<ret>'
map global normal C 'r<space>: overwrite<ret>'

# t on k
map global normal k     t
map global normal K     T
map global normal <a-k> <a-t>
map global normal <a-K> <a-T>

# Split and select
map global normal -- - s
map global normal L S
map global normal l <A-s>

map global normal @ ': select-all-focus-closest<ret>'
map global normal _ ': exec s<ret><ret>'

#map -docstring %{select all} global user   a :select-all-focus-closest<ret>

# Keep selections
map -docstring %{keep} global user k <a-k>
map -docstring %{keep not} global user K <a-K>

def old_X %{
    try %{
        exec -draft \; <a-k>\n<ret>
        exec X
    } catch %{
        exec <a-x><a-:>
    }
}

# Line selection commands on v as in vim's visual mode
import line-selection
map global normal v     ': line-select<ret>'
map global normal V     ': old_X<ret>'
map global normal <A-v> <A-x>
map global normal <A-V> <A-X>
map global normal <c-v> ': line-new-cursor<ret>'
map global normal D     ': old_X<ret>dgi'

# Macros, one selection and remove highlighting
map global normal <esc> '<esc>: noh<ret><space>'

# ret...
map -docstring <ret> global user <ret> <ret>

# Nav
map global normal <space> '<space>: pagewise j<ret>'
map global normal <ret>   '<space>: pagewise k<ret>'

decl int viewport_h
decl int viewport_y
def viewport_update %{
    eval -draft -save-regs ct %{
        eval -draft -no-hooks %{
            reg c %val{cursor_line}
            exec gt
            reg t %val{cursor_line}
        }
        set window viewport_y %sh{ echo $(($kak_main_reg_c - $kak_main_reg_t)) }
    }
}

def pagewise -params 1 %{
    viewport_update
    exec %val{window_height} %arg{1} vt %opt{viewport_y} vk
}

def viewport_preserve -params 1 %{
    viewport_update
    exec %arg{1} vt %opt{viewport_y} vk
}

map global normal <c-g> ': viewport_preserve n<ret>'

# Selection fiddling
map global normal * lbhe*
map -docstring * global user   8 *

map global normal = <space>

def selinfo %{
    info '
<a-;>  swap direction
<a-:>  face forward
<esc>  one selection (space)
:      reduce selection to cursor (;)
    '
}

#hook -group kakrc global NormalKey '^(<a-[:;]>|<space>|;)$' selinfo

# Register
map -docstring register global user r '"'

# Paste and replace
map global normal <c-r> R

# Xclipboard
map -docstring 'xser paste'    global user P %{<a-!>xclip -o<ret>}
map -docstring 'xsel Paste'    global user p %{!xclip -o<ret>}
map -docstring 'xsel replace'  global user R %{: reg w "%sh{xclip -o}"<ret>"wR}
map -docstring 'xcopy bufname' global user y %{: xcopy %val{bufname}<ret>}
map -docstring 'xcopy buffile' global user Y %{: xcopy %val{buffile}<ret>}


def xcopy -params 0..1 %{eval %sh{
  if [ -z "$1" ]; then
    val=$(eval echo "$kak_quoted_reg_dquote")
  else
    val=$1
  fi
  echo -n "$val" | xsel --input --primary
  echo -n "$val" | xsel --input --clipboard
  l=$(echo -n "$val" | wc -l)
  val=${val//./..}
  if [[ $l -eq 0 ]]; then
    echo echo "copied %.$val."
  elif [[ $l -eq 1 ]]; then
    echo echo "copied 1 line"
  else
    echo echo "copied $l lines"
  fi
}}

# Sync %reg{"} with X clipboard, idea from alexherbo2
map global normal y 'y: xcopy<ret>'
#hook global -group kakrc NormalKey y %{xcopy}

# Execute current selection(s)
map -docstring eval global user x %{: eval -itersel %val{selection}<ret>}

# Write and close buffer
map -docstring write  global user w ': w<ret>'
map -docstring bufdel global user d %{ : delete-buffer<ret>: exec ga<ret> }

# Comment line
map global normal '#' ': comment-line<ret>'

# Buffers
hook global WinDisplay .* info-buffers

map global normal <a-0> ': buffer *debug*<ret>'
map global normal <a-`> ': edit ~/.kakrc<ret>'
map global normal <a-c> ': bp<ret>'
map global normal <a-r> ': bn<ret>'
map global normal <a-,> ': bp<ret>'
map global normal <a-.> ': bn<ret>'
map global normal <a-minus> 'ga'
map global normal <a-d> ': db<ret>'
map global normal <a-q> ': db!<ret>'

# Format using fmt
map -docstring format global user q '|fmt -w 80<ret>: echo -markup {green}[sel] | fmt -w 80<ret>'

# Object map
# Some upper-case variants:
map global object P p
map global object I i

#

# Aliases
alias global colo colorscheme
alias global wqa  write-all-quit
alias global bd   delete-buffer
alias global bd!  delete-buffer!
alias global rg   grep
def setf -params 1 %{set buffer filetype %arg{1}}
def auinfo %{set -add window autoinfo normal}
def cd-here %{cd %sh{cd $(dirname $kak_buffile); git rev-parse --show-toplevel 2>/dev/null || echo $PWD}}
alias global cd! cd-here

map -docstring pwd global user ` %{: echo %val{client_env_PWD}<ret>}

# Auto-mkdir when saving buffer to file, from alexherbo2
hook global -group kakrc BufWritePre .* %{ nop %sh{
  dir=$(dirname $kak_buffile)
  [ -d $dir ] || mkdir --parents $dir
}}

# Remove trailing whitespaces before saving
hook global -group trim-whitespace-pre-buf-write BufWritePre .* %{
  try %{ exec -draft '%s\h+$<ret>d' }
}
hook global -group expandtabs-pre-buf-write BufWritePre .* %{
  try %{ exec -draft '%@' }
}

hook global BufSetOption filetype=makefile %{
  set buffer disabled_hooks expandtabs.*
  addhl window show_whitespaces -lf ' ' -spc ' '
}

# Options
set global ui_options ncurses_assistant=none ncurses_set_title=false
hook global WinCreate .* %{
    set -add window ui_options "ncurses_set_title=%val{bufname} - kakoune"
}
set global tabstop 4
set global idle_timeout 50
set global scrolloff 1,0

# Insert mode
map global insert <c-s> <c-o>    ; # silent: stop completion
map global insert <c-c> <c-x>    ; # complete here
map global insert <a-l> <c-x>L ; # complete here
map global insert <c-k> <c-v>    ; # raw insert, use vim binding
map global insert <c-y> '<c-r>"' ; # paste from normal yank register, readline key
map global insert <c-h> <a-\;>   ; # execute one normal kak command

# Reload .Xresources upon saving it
rmhooks global reload-xres
hook -group reload-xres global BufWritePost .*Xresources %{
  nop %sh{ xrdb -merge ~/.Xresources }
  echo xrdb -merge %val{bufname}
}

# Reload sxhkd upon saving it
rmhooks global reload-sxhkd
hook -group reload-sxhkd global BufWritePost .*sxhkd.* %{
  nop %sh{ pkill -USR1 -x sxhkd }
  echo pkill -USR1 -x sxhkd
}

hook -group kakrc global BufCreate .*sxhkd.* %{ set buffer filetype sh }
hook -group kakrc global BufCreate .*bspwm.* %{ set buffer filetype sh }

rmhooks global smarttab
def delete-tab %{exec 'hGh' "s\A(( {%opt{indentwidth}})*) *\z<ret>" '"1R'}
hook -group smarttab global InsertDelete ' ' %{
    eval -draft -itersel %{try delete-tab}
}

hook global -group kakrc WinResize .* %{
    echo "%val{window_height}:%val{window_width}"
}

# Auto expand tabs into spaces
hook -group expandtabs global InsertChar \t %{ exec -draft -itersel x@ }

set global grepcmd 'rg -n'

hook global -group kakrc BufCreate .*(bashrc|xinitrc).* %{
set buffer filetype sh
}

hook global -group kakrc BufCreate .*(Makefile).* %{
    set buffer filetype makefile
}

set global completers filename

map global insert <a-w> <c-x><c-w>
map global insert <a-h> '<a-;>: lsp-signature-help<ret>'

hook global -group kakrc BufCreate .*kak.* %{
    set -add buffer extra_word_chars -
}

hook global -group kakrc BufOpenFifo '\*grep\*' %{ map -docstring grep-next buffer user n ':grep-next<ret>' }

hook -group kakrc global WinSetOption filetype=man %{
    unmap window normal <ret> ': man-jump<ret>'
    map window user <ret> ': man-jump<ret>'
}

hook global -group kakrc WinSetOption filetype=(c|cpp) %{
    clang-enable-autocomplete
    clang-enable-diagnostics
    alias window lint clang-parse
    alias window lint-next clang-diagnostics-next
    eval %sh{
        if [ $PWD = "/home/dan/code/kakoune/src" ]; then
           echo "set buffer clang_options '-std=c++14 -DKAK_DEBUG'"
           # -include-pch precomp-header.h.gch -DKAK_DEBUG'"
        fi
    }
    #ycmd-enable-autocomplete
}

hook global -group kakrc WinSetOption filetype=sh %{
    set buffer lintcmd 'shellcheck -fgcc -eSC2006'
    lint-enable
}

hook -group kakrc global BufSetOption filetype=pug %{
  set buffer tabstop 2
  set buffer indentwidth 2
  set buffer disabled_hooks (pug-hooks|pug-indent)
}

hook global -group kakrc WinSetOption filetype=python pysetup

def pysetup -hidden %{
    set window lintcmd 'mypy --show-column-numbers'
    jedi-enable-autocomplete
    set window tab_at_word_end 'eval -draft %{exec b; jedi-complete; at-idle-select-next}'
    # lint-enable
    map window user . ': jedi-goto<ret>'
    map window user b ': i3-new-up; jedi-goto<ret>'
    map window user i ': jedi-info<ret>'
}

def ide %{
    rename-client main
    new rename-client docs
    new rename-client tools
    set global docsclient docs
    set global toolsclient tools
    set global jumpclient main
}

#colorscheme base16-eighties
# colorscheme base16base
#colorscheme base16bland

# make import and plug look like keywords :)
try %{
    addhl shared/kakrc/code/a regex \b(import|plug)\b 0:keyword
    addhl shared/kakrc/code/b regex \b(def|eval|exec|set|reg|decl|addhl)\b 0:keyword
}

map -docstring '/(?i)'     global user '/'     /(?i)
map -docstring '<a-/>(?i)' global user '<a-/>' <a-/>(?i)
map -docstring '?(?i)'     global user '?'     ?(?i)
map -docstring '<a-?>(?i)' global user '<a-?>' <a-?>(?i)

map -docstring 'merge sels' global user M <a-_>

decl str modeline_info  ''

rmhooks global update-modeline
hook -group update-modeline global WinCreate .* %{
    hook -group update-modeline window WinDisplay .* %{try update_modeline_info}
    hook -group update-modeline window PromptIdle .* %{try update_modeline_info}
    hook -group update-modeline window InsertIdle .* %{try update_modeline_info}
    hook -group update-modeline window NormalIdle .* %{try update_modeline_info}
    hook -group update-modeline window NormalKey [jknJKN] %{try update_modeline_info}
}

def update_modeline_info %{
    set window modeline_info %sh{printf '%3d%% |' $((kak_buf_line_count > 1 ? 100 * ($kak_cursor_line - 1) / ($kak_buf_line_count - 1) : 0))}
}

set global modelinefmt %{
{{context_info}} | {{mode_info}} | %val{bufname} |
%val{cursor_line}:%val{cursor_char_column} |
%opt{modeline_info}
%val{session}}

def saveas -params 1 -file-completion %{ rename-buffer -file %arg{1}; write }

def lsp-window-completion %{
    map window insert <a-c> '<a-;>: lsp-completion<ret>'
    hook window -group test InsertChar \. lsp-completion
}

import rofi

hook global WinCreate .* %{
    eval -draft %{
        try %{
            exec '%<a-k>\t<ret>'
            set window disabled_hooks .*expandtab.*
            echo "disabled hooks: %opt{disabled_hooks}"
            echo -debug "disabled hooks: %opt{disabled_hooks}"
        }
    }
}


# mawww's find
define-command open -menu -params 1 -shell-script-candidates %{ rg -l '' . } %{ edit %arg{1} }
alias global o open

define-command mru-dirs -menu -params 1 -shell-script-candidates %{ rg -l '' $(mru-dirs 100) } %{ edit %arg{1} }
define-command mru-open -menu -params 1 -shell-script-candidates %{ cat ~/.mru } %{ edit %arg{1} }
alias global m mru-open

def spawn -params .. %{
    eval %sh{
        echo "echo -debug $@"
        "$@" >/dev/null 2>&1 </dev/null &
    }
}

alias global bg spawn

def fg -params .. %{
    eval %sh{
        out="$($@)"
        out="> $*"$'\n'"$out"
        out=${out//\'/\'\'}
        echo info "'$out'"
    }
}

alias global sh fg

def chmod -params 1 %{
    info -- %sh{
        chmod -v "$1" "$kak_buffile"
    }
}

def wc -params .. %{
    info -- %sh{
        set -x
        eval set -- "$(printf '%s' "$kak_quoted_buflist" | sed "s,~,$HOME,g")"
        wc "$@"
    }
}

def quiet -params .. -shell-script-candidates %{ printf '%s\n' hooks shell profile keys commands } %{
    rmhooks window update-modeline
    rmhooks window open-show
    try %{
        set window debug %sh{
            printf %s "$1"
            shift 2>/dev/null
            if [ "$1" != "" ]; then
                printf '|%s' "$@"
            fi
        }
    }
}
def qc %{quiet commands}
def qs %{quiet shell}
def qsc %{quiet shell commands}

map global user f ': filer<ret>'

try %{declare-user-mode block}

map global block w <a-a>p
map global block v '<a-a>p<a-;>[p'
map global block W }p
map global block V '{p'

map global block t 'ghj<a-x>'
map global block n 'ghk<a-x>'
map global block T 'GHJ<a-x>'
map global block N 'GHK<a-x>'

map global normal q ': enter-user-mode -lock block<ret>'
