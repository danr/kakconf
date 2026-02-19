
eval %sh{krc kak-defs}
def connect-x11-terminal -params .. %{ connect x11-terminal %arg{@} }
def connect-tmux-terminal -params .. %{ connect tmux-terminal-window %arg{@} }
evaluate-commands %sh{
    if [ -n "$DISPLAY" ]; then
        echo 'alias global t connect-x11-terminal'
    elif [ -n "$TMUX" ]; then
        echo 'alias global t connect-tmux-terminal'
    fi
}

rmhooks global krc

hook global -group krc FocusIn .* %{
    nop %sh{if [ "$kak_buffile" != "*filer*" ]; then {
              echo "export session=$kak_session"
              echo "export client=$kak_client"; } > ~/.mrk; fi}
}
