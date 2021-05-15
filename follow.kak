def tail -file-completion -params 1 %{
    follow "tail -n0 -q -F '%arg{1}'" ">>> %arg{1}: "
}
def untail -file-completion -params 1 %{
    unfollow "tail -n0 -q -F '%arg{1}'"
}
def follow -file-completion -params 1..2 %{
    unfollow %arg{1}
    eval %sh{
        ( {
            header="$2"
            opt="follow_pid_$(printf '%s' ""$1"" | md5sum | head -c 32)"
            kakquote() { printf "%s" "$*" | sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }
            eval "$1" | while IFS=$'\n' read line; do
                printf '%s\n' "echo -debug -- $(kakquote "$header$line")" | kak -p "$kak_session"
            done &
            printf '%s\n' "
                decl -hidden str $opt $!
                set global $opt $!
                echo -debug set global $opt $!
            " | kak -p "$kak_session"
        } &
        ) >/dev/null 2>&1 </dev/null
    }
}
def unfollow -file-completion -params 1..2 %{
    eval %sh{
        opt="follow_pid_$(printf '%s' ""$1"" | md5sum | head -c 32)"
        printf '%s\n' 'eval %sh{
            pid="$kak_opt_'"$opt"'"
            test "$pid" != "" && kill "$pid" || true
        }'
        printf '%s\n' "try %{set global $opt ''}"
    }
}
