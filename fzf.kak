
def fzf-kitty -params 2..3 %{
    connect kitty-terminal bash -c "%arg{1} $(%arg{2} | fzf --height=100%% --preview 'test -d {} && ls --color=always -lh {} || bat --color=always {}' %arg{3})"
}

try %{
    declare-user-mode fzf-kitty
}

map global normal j ': enter-user-mode fzf-kitty<ret>'

try %{
    decl str rg_types
}
set global rg_types '--type-add kak:\*.kak --type json --type py --type hs --type md --type ts --type js --type julia --type kak --type xml --type txt --type toml --type rust'
map global fzf-kitty F -docstring 'file ~'   %(: fzf-kitty %(krc send edit) %(rg ~ --files)<ret>)
map global fzf-kitty f -docstring file       %(: fzf-kitty %(krc send edit) %(rg --files)<ret>)
map global fzf-kitty c -docstring code       %(: fzf-kitty %(krc send edit) 'rg ~ ~/.config ~/config --ignore-file ~/.binignore --files %opt{rg_types}'<ret>)
map global fzf-kitty d -docstring dir        %(: fzf-kitty %(krc send cd) %(fd -t d)<ret>)
map global fzf-kitty D -docstring 'dir ~'    %(: fzf-kitty %(krc send cd) %(echo ~; fd -t d . ~)<ret>)
map global fzf-kitty b -docstring buffer     %(: fzf-kitty %(krc send buffer) %(source ~/code/krc/krc-bash-aliases; buffers)<ret>)
map global fzf-kitty m -docstring mru        %(: fzf-kitty %(krc send edit) %(cat ~/.mru | awk '!count[$1]++')<ret>)
map global fzf-kitty l -docstring line       %(: fzf-kitty-line<ret>)

def fzf-kitty-line %{
    fzf-kitty %(
        k () {
            hit="$1"
            file=$(echo "$hit" | cut -f 1 -d:)
            line=$(echo "$hit" | cut -f 2 -d:)
            krc send edit $file $line
        }
        k) %(rg -n .) %(-d: -n 3.. --preview '
            hit={}
            file=$(echo "$hit" | cut -f 1 -d:)
            line=$(echo "$hit" | cut -f 2 -d:)
            bat $file --highlight-line "$line" --line-range $((line > 10 ? line - 10 : 1)): --color=always
        ')
}

def unused-fzf-file-from-git-here %{
    fzf-file %sh{
        cd $(dirname $kak_buffile)
        git rev-parse --show-toplevel
    }
}

