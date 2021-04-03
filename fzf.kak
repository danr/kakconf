
def fzf-kitty -params 2 %{
    connect kitty-terminal bash -c "%arg{1} $(%arg{2} | fzf --height=100%% --preview 'test -d {} && ls --color=always -lh {} || bat --color=always {}')"
}

try %{
    declare-user-mode fzf-kitty
}

map global normal j ': enter-user-mode fzf-kitty<ret>'

try %{
    decl str rg_types
}
set global rg_types '--type-add kak:\*.kak --type json --type py --type hs --type md --type ts --type js --type julia --type kak --type xml --type txt --type toml --type rust'
map global fzf-kitty F -docstring 'file ~'   ': fzf-kitty %(krc send edit) %(rg ~ --files)<ret>'
map global fzf-kitty f -docstring file       ': fzf-kitty %(krc send edit) %(rg --files)<ret>'
map global fzf-kitty c -docstring code       ": fzf-kitty %(krc send edit) 'rg ~ ~/.config ~/config --ignore-file ~/.binignore --files %opt{rg_types}'<ret>"
map global fzf-kitty g -docstring 'git file' ': fzf-kitty %(krc send edit) %(git ls-tree -r --name-only HEAD)<ret>'
map global fzf-kitty d -docstring dir        ': fzf-kitty %(krc send cd) %(fd -t d)<ret>'
map global fzf-kitty D -docstring 'dir ~'    ': fzf-kitty %(krc send cd) %(echo ~; fd -t d . ~)<ret>'
map global fzf-kitty b -docstring buffer     ': fzf-kitty %(krc send buffer) %(source ~/code/krc/krc-bash-aliases; buffers)<ret>'

def unused-fzf-file-from-git-here %{
    fzf-file %sh{
        cd $(dirname $kak_buffile)
        git rev-parse --show-toplevel
    }
}

