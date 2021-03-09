
def rofi-dmenu -params 2 %{
    # connect-shell "%arg{1} $( %arg{2} | rofi -dmenu -monitor -2 -p :)"
    connect-shell bash -c "%arg{1} $( %arg{2} | dmenu -w $(xdotool getwindowfocus) -l 20 -b -i -fn Consolas-16)"
}

try %{
    declare-user-mode rofi
}

map global normal j ': enter-user-mode rofi<ret>'

try %{
    decl str rg_types
}
set global rg_types '--type-add kak:\*.kak --type json --type py --type hs --type md --type ts --type js --type julia --type kak --type xml --type txt --type toml --type rust'
map global rofi F -docstring 'file ~'   ': rofi-dmenu %(krc send edit) %(rg ~ --files)<ret>'
map global rofi f -docstring file       ': rofi-dmenu %(krc send edit) %(rg --files)<ret>'
map global rofi c -docstring code       ": rofi-dmenu %(krc send edit) 'rg ~ ~/.config ~/config --ignore-file ~/.binignore --files %opt{rg_types}'<ret>"
map global rofi g -docstring 'git file' ': rofi-dmenu %(krc send edit) %(git ls-tree -r --name-only HEAD)<ret>'
map global rofi d -docstring dir        ': rofi-dmenu %(krc send cd) %(fd -t d)<ret>'
map global rofi D -docstring 'dir ~'    ': rofi-dmenu %(krc send cd) %(echo ~; fd -t d . ~)<ret>'
map global rofi b -docstring buffer     ': rofi-dmenu %(krc send buffer) %(buffers)<ret>'
