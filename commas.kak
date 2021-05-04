# insert mode with commas for symbols

python /home/dan/code/kakconf/commas.py setup

map global normal r ': comma-replace<ret>'

def -override comma-replace %{
    info -title 'replace with char' 'enter char to replace with'
    on-key %{
        info
        eval %sh{
            if test "$kak_key" = ","; then
                printf %s "
                    info -title 'replace with comma char' 'enter char to replace with'
                    on-key 'python /home/dan/code/kakconf/commas.py replace'
                "
            else
                echo exec r "$kak_key"
            fi
        }
    }
}

