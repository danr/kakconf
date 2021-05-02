
def -override python -params .. %{
    eval %sh{
        vars=$(
            [ "$1" = "-c" ] && printf %s "$2" || cat "$1" |
            grep -o 'kak_\w*' | sort -u | tr '\n' ' '
        )
        args='"$@"'
        printf %s "eval %sh{python $args # $vars}"
    }
}

decl -hidden str filer_source_dir %sh{dirname "$kak_source"}

def -override filer -params .. %{
    python "%opt{filer_source_dir}/filer.py" %arg{@}
}

decl line-specs filer_flags
decl str filer_path .
decl str filer_watcher .
decl str-list filer_open
decl str-list filer_mark

def -override filer-on -params 1 %{
    eval -save-regs s %{
        eval -draft %{
            exec <a-x><a-s>
            eval reg s %val{selections}
        }
        filer %arg{1} %reg{s}
    }
}

def -override exec-if-you-can -params 2 %{
    try %{
        exec -draft %arg{1}
        exec %arg{1}
    } catch %{
        eval %arg{2}
    }
}

def -override filer-popup %{
    eval -draft -save-regs '' %{
        exec ghGL
        reg s %val{selection}
    }
    info -- %sh{
        file -i "$kak_reg_s"
        file -b "$kak_reg_s" | fmt
        if file -bi "$kak_reg_s" | grep -v charset=binary >/dev/null; then
            echo
            head -c 10000 "$kak_reg_s" |
            cut -c -80 | # $((kak_window_width / 2)) |
            head -n $((kak_window_height / 2))
        fi
    }
}

def -override filer-idle-popup-enable %{
    hook window -group filer-idle-popup NormalIdle .* filer-popup
}

def -override filer-idle-popup-disable %{
    rmhooks window filer-idle-popup
}

def -override redraw-when-you-see-me -params 1 %{
    eval %sh{
        if [ "$kak_bufname" = "$1" ]; then
            printf %s 'filer redraw'
        else
            printf %s "
                hook -group filer-redraw -once global WinDisplay \Q$1 %{
                    filer redraw
                }
            "
        fi
    }
}

def -override watch-dirs -params .. %{
    eval %sh{
        if [ ! -e "$kak_opt_filer_watcher" ]; then
            filer_watcher=$(mktemp --suffix=.filer_watcher)
            touch "$filer_watcher"
            echo "set window filer_watcher $filer_watcher"
            ( {
                printf '%s\n' "$@" |
                    inotifywait --fromfile - -e attrib,modify,move,create,delete,delete_self,unmount
                sleep 0.05
                rm "$filer_watcher"
                printf %s "eval -client $kak_client 'redraw-when-you-see-me $kak_bufname'" |
                    kak -p "$kak_session"
            } & ) >/dev/null 2>/dev/null
        fi
    }
}
