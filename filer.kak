
eval %sh{
    name=filer
    dir=$(dirname "$kak_source")
    py="$dir/$name.py"
    vars=$(grep -o 'kak_\w*' "$py" | sort -u | tr '\n' ' ')
    args='"$@"'
    printf %s "
        def -override $name -params .. %{
            eval %sh{
                # $vars
                python $py $args
            }
        }
    "
}

declare-option line-specs filer_flags
declare-option str filer_path .
declare-option str filer_watcher .
declare-option str-list filer_open
declare-option str-list filer_mark
declare-option str filer_open_json []
declare-option str filer_mark_json []

def -override filer-on -params 1 %{
    eval -save-regs s %{
        eval -draft %{
            exec <a-x><a-s>
            eval reg s %val{selections}
        }
        filer %arg{1} %reg{s}
    }
}

def -override filer-mark -params 1 %{
    exec <a-x><a-s>
    filer mark %arg{1} %val{selections}
    echo -debug E
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
