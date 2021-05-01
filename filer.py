
from libkak import *
import json
# import fs
# from viable import *
from datetime import datetime
import re

# import sys

import os
from pathlib import Path

def show_ts(ts):
    return datetime.fromtimestamp(int(ts))

def show_size(size, units=' KMGTPE'):
    """ Returns a human readable string representation of size """
    return str(round(size, 0)) + units[0] if size < 1000 else show_size(size / 1024, units[1:])

def go(root, opened, key=[]):
    try:
        for entry in os.scandir(root):
            if entry.name.startswith('.'):
                continue
            is_dir = entry.is_dir()
            entry_key = [*key, [not is_dir, entry.name]]
            suf = '/' if is_dir else ''
            path = (entry.path + suf)
            if path.startswith('./'):
                path = path[2:]
            is_open = is_dir and path in opened
            try:
                yield entry_key, is_dir, is_open, root, path, entry.stat()
            except FileNotFoundError:
                pass
            if is_open:
                yield from go(
                    entry.path,
                    opened,
                    entry_key
                )
    except PermissionError:
        pass

prelude = r'''
    declare-option line-specs filer_flags
    declare-option str filer_path .
    declare-option str-list filer_open
    declare-option str-list filer_mark
    declare-option str filer_open_json []
    declare-option str filer_mark_json []

    map window normal o     ': filer-on open        <ret>'
    map window normal c     ': filer-on close       <ret>'
    map window normal m     ': filer-on mark-toggle <ret>'
    map window normal M     ': filer-on mark-set    <ret>'
    map window normal <a-m> ': filer-on mark-remove <ret>'

    rmhl window/filer1
    rmhl window/filer2
    addhl window/filer1 regex ^[^\n]*/ 0:blue
    addhl window/filer2 regex [^/\n]*/$ 0:green

    rmhl window/filerflags
    addhl window/filerflags flag-lines magenta filer_flags

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

    def -override exec-if-you-can -params 2 %{
        try %{
            exec -draft %arg{1}
            exec %arg{1}
        } catch %{
            eval %arg{2}
        }
    }

    def -override redraw-when-you-see-me -params 1 %{
        eval %sh{
            if [ "$kak_bufname" = "$1" ]; then
                printf %s 'filer redraw'
            else
                printf %s "
                    hook -group filer-redraw -once global WinDisplay \Q$1 %{
                        rmhooks global filer-redraw
                        filer redraw
                    }
                "
            fi
        }
    }

    def -override replace-buffer -params .. %{
        exec -draft '%|' %sh{tmp=$(mktemp); printf '%s\n' "$@" > "$tmp"; echo "cat $tmp; rm $tmp"} <ret>
    }

    def -override watch-dirs -params .. %{
        nop %sh{
            ( {
                printf '%s\n' "$@" |
                    inotifywait --fromfile - -e attrib,modify,move,create,delete,delete_self,unmount
                sleep 0.55
                printf %s "eval -client $kak_client 'redraw-when-you-see-me $kak_bufname'" |
                    kak -p "$kak_session"
            } & ) >/dev/null 2>/dev/null
        }
    }
'''.replace('    ', ' ')

@define
def filer(command='', *args, bufname, filer_path='.', filer_open_json='[]', filer_mark_json='[]'):

    if not bufname.startswith('*filer'):
        yield 'edit -scratch *filer*'

    try:
        filer_open = set(json.loads(filer_open_json))
    except:
        filer_open = set()

    try:
        filer_mark = set(json.loads(filer_mark_json))
    except:
        filer_mark = set()

    arg_paths = {arg.strip('\n') for arg in args}

    at_end = []

    if command == 'open':
        for arg in arg_paths:
            if arg.endswith('/'):
                filer_open |= {arg}
            else:
                yield q.spawn('danneopen', arg)
    elif command == 'close':
        if any(arg in filer_open for arg in arg_paths):
            filer_open -= arg_paths
        else:
            parents = set()
            for arg in arg_paths:
                if arg not in filer_open:
                    parents.add('^\Q' + str(Path(arg).parent) + '/\E$')
            parents = '(' + '|'.join(parents) + ')'
            at_end += [
                q.exec_if_you_can(
                    '%s' + parents + '<ret>ghGL',
                    q.fail('no parent'),
                )
            ]
    elif command == 'mark-toggle':
        if any(arg not in filer_mark for arg in arg_paths):
            filer_mark |= arg_paths
        else:
            filer_mark -= arg_paths
    elif command == 'mark-set':
        filer_mark = arg_paths
    elif command == 'mark-remove':
        filer_mark -= arg_paths
    elif command == 'redraw':
        pass
    elif not command:
        yield prelude
    else:
        filer_path = command
        if filer_path:
            yield q.set('window', 'filer_path', filer_path)

    lines = []
    repls = []

    rows = list(sorted(go(filer_path, filer_open)))

    paths = set()

    open_dirs = {filer_path}

    for i, (key, is_dir, is_open, root, path, stat) in enumerate(rows, start=1):
        paths.add(path)
        if is_dir and is_open:
            open_dirs.add(path)

    yield q.watch_dirs(*open_dirs)

    filer_mark &= paths

    for i, (key, is_dir, is_open, root, path, stat) in enumerate(rows, start=1):
        if is_dir and is_open:
            r = f'{show_ts(stat.st_mtime)} {"v":>6} '
        elif is_dir and not is_open:
            r = f'{show_ts(stat.st_mtime)} {">":>6} '
        else:
            r = f'{show_ts(stat.st_mtime)} {show_size(stat.st_size):>6} '

        if path in filer_mark:
            r += '{yellow}✔ '
        elif filer_mark:
            r += '  '

        repls += [f'{i}|{r}']
        lines += [path]

    yield q.replace_buffer(*lines)

    yield 'set window filer_flags %val{timestamp} ' + q(*repls)

    yield q.set('window', 'filer_open_json', json.dumps(list(sorted(filer_open))))
    yield q.set('window', 'filer_mark_json', json.dumps(list(sorted(filer_mark))))
    yield q.set('window', 'filer_open', *sorted(filer_open))
    yield q.set('window', 'filer_mark', *sorted(filer_mark))

    yield from at_end

