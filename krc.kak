
eval %sh{krc kak-defs}
def connect-x11-terminal -params .. %{ connect x11-terminal %arg{@} }
alias global t connect-x11-terminal

rmhooks global krc

hook global -group krc FocusIn .* %{
    nop %sh{
        if [ "$kak_buffile" = "*filer*" ]; then
            true
        else
            {
                echo "export session=$kak_session"
                echo "export client=$kak_client"
            } > ~/.mrk
        fi
    }
}
