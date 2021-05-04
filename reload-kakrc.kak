
# Reload kakrc and .kak when saving.
# Adds -override to definitions (unless they seem to be python defs!)
# Evals provide module directly
# Idea: remove all grouped hooks?

decl -hidden str reload_file

def resource -params 1 %{
    set global reload_file %sh{ mktemp /tmp/kak-source.XXXXXX }
    eval -draft %{
        exec \%
        echo -to-file %opt{reload_file} %val{selection}
    }

    nop %sh{
        sed -i 's/^def \([^:]*\)$/def -override \1/' $kak_opt_reload_file
        sed -i 's/^define-command /def -override /' $kak_opt_reload_file
        sed -i 's/^provide-module \w\+ /eval /' $kak_opt_reload_file
        sed -i 's/add-highlighter/#/' $kak_opt_reload_file
    }
    eval %sh{
        echo echo -debug %file{$kak_opt_reload_file}
    }
    source %opt{reload_file}
    echo Reloaded %val{bufname}
    nop %sh{ rm $kak_opt_reload_file }
}

rmhooks global reload-kak
hook -group reload-kak global BufWritePost (.*kakrc|.*\.kak) %{
     resource %val{hook_param}
}

