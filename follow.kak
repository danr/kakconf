def follow -file-completion -params 1 %{
    unfollow %arg{1}
    eval %sh{
        ( {
            kakquote() { printf "%s" "$*" | sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }
            header=""
            tail -n0 -v -F "$1" | while IFS=$'\n' read line; do
                if printf '%s' "$line" | grep '^==>'; then
                    header="$line"
                else
                    printf '%s\n' "echo -debug -- $(kakquote "$header: $line")" | kak -p "$kak_session"
                fi
            done &
            opt="follow_pid_$(printf '%s' ""$1"" | base32 -w0 | tr -d =)"
            printf '%s\n' "
                decl -hidden str $opt $!
                set global $opt $!
                echo -debug set global $opt $!
            " | kak -p "$kak_session"
        } &
        ) >/dev/null 2>&1 </dev/null
    }
}
def unfollow -file-completion -params 1 %{
    eval %sh{
        opt="follow_pid_$(printf '%s' ""$1"" | base32 -w0 | tr -d =)"
        printf '%s\n' 'eval %sh{
            pid="$kak_opt_'"$opt"'"
            test "$pid" != "" && kill "$pid" || true
        }'
        printf '%s\n' "set global $opt ''"
    }
}
