
def fzf-kitty -params 2..3 %{
    connect kitty-terminal bash -c "
        %arg{1} $(
            %arg{2} 2>/dev/null |
            fzf --height=100%% --preview-window=down,40%% --preview '
                test -d {} && ls --color=always -lh {} || bat --color=always {}' %arg{3}
        )
    "
}

try %{
    declare-user-mode fzf-kitty
}

map global normal k ': enter-user-mode fzf-kitty<ret>'

map global fzf-kitty m -docstring mru         %(: fzf-kitty %(krc send edit) %(cat ~/.mru | awk '!count[$1]++')<ret>)
map global fzf-kitty f -docstring file        %(: fzf-kitty %(krc send edit) %(rg --files)<ret>)
map global fzf-kitty o -docstring file        %(: fzf-kitty %(krc send edit) %(rg --files)<ret>)
map global fzf-kitty t -docstring file        %(: fzf-kitty %(krc send edit) %(git ls-files)<ret>)
map global fzf-kitty h -docstring 'file ~'    %(: fzf-kitty %(krc send edit) %(rg ~ --files)<ret>)

map global fzf-kitty g -docstring 'goto line' %(: fzf-kitty-line-goto %(cat ~/.mru | xargs rg -n . .)<ret>)
map global fzf-kitty c -docstring 'copy line' %(: fzf-kitty-line-copy %(cat ~/.mru | xargs rg -n . .)<ret>)

map global fzf-kitty d -docstring 'dir ~'     %(: fzf-kitty %(krc send cd) %(fd -t d . ~)<ret>)
map global fzf-kitty b -docstring buffer      %(: fzf-kitty %(krc send buffer) %(source ~/code/krc/krc-bash-aliases; buffers)<ret>)

def fzf-kitty-line-goto -params 1 %{
    fzf-kitty %(
        k () {
            hit="$1"
            file=$(echo "$hit" | cut -f 1 -d:)
            line=$(echo "$hit" | cut -f 2 -d:)
            if [ "$file" != "" ]; then
                krc send edit "$file" "$line"
            fi
        }
        k) %arg(1) %(-d: -n 3.. --preview '
            hit={}
            file=$(echo "$hit" | cut -f 1 -d:)
            line=$(echo "$hit" | cut -f 2 -d:)
            bat $file --theme base16 --number --highlight-line "$line" --line-range $((line > 4 ? line - 4 : 1)): --color=always
        ')
}

def fzf-kitty-line-copy -params 1 %{
    fzf-kitty %(
        k () {
            hit="$1"
            file=$(echo "$hit" | cut -f 1 -d:)
            line=$(echo "$hit" | cut -f 2 -d:)
            if [ "$file" != "" ]; then
                krc send reg '"' "$(sed -ne "${line}p" "$file")"$'\n'
                krc send exec P
            fi
        }
        k) %arg(1) %(-d: -n 3.. --preview '
            hit={}
            file=$(echo "$hit" | cut -f 1 -d:)
            line=$(echo "$hit" | cut -f 2 -d:)
            bat $file --theme base16 --number --highlight-line "$line" --line-range $((line > 4 ? line - 4 : 1)): --color=always
        ')
}

