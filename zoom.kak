decl str zoom_pos
decl str zoom_buf

def zoom %{
    eval -save-regs sp %{
        eval -draft %{
            exec <a-s>S\n<ret>
            exec <a-K>\n<ret>
            exec '"sy'
            exec '"pZ'
            set global zoom_pos %sh{printf %s "$kak_reg_p"}
            set global zoom_buf %val{buffile}
        }
        eval -try-client %opt{jumpclient} %{
            edit -scratch "*zoom*"
            exec '%d'
            exec '"s<a-R>a<ret><esc>'
            exec ged
        }
    }
}

def zoom-update %{
    eval -draft -save-regs sp %{
        eval -draft %{
            edit -scratch "*zoom*"
            exec '%'
            exec <a-s>S\n<ret>
            try %{ exec <a-K>\n<ret> }
            exec '"sy'
        }
        edit -existing %opt{zoom_buf}
        eval %sh{printf %s "reg p $kak_opt_zoom_pos"}
        exec '"pz"sR'
        exec '"pZ'
        set global zoom_pos %sh{printf %s "$kak_reg_p"}
    }
}
