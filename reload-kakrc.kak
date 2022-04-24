
# Reload kakrc and .kak when saving.
# Adds -override to definitions (unless they seem to be python defs!)
# Evals provide module directly
# Idea: remove all grouped hooks?

def resource -params 1 %{
    eval %sh{
        file=$(dirname "$1")/.reload.kak
        cat "$1" |
            sed 's/^def \([^:]*\)$/def -override \1/' |
            sed 's/^define-command /def -override /'  |
            sed 's/^addhl /addhl -override /'  |
            sed 's/^add-highlighter /addhl -override /'  |
            sed 's/^provide-module \w\+ /eval /'      |
            cat > "$file"
        printf %s "
            source $file
            nop %sh{
                rm $file
            }
        "
    }
    echo Reloaded %arg{1}
}

rmhooks global reload-kak
hook -group reload-kak global BufWritePost (.*kakrc|.*\.kak) %{
     resource %val{hook_param}
}

