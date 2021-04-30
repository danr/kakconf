
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
    # parent_full_path = root.getospath('.').decode()
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

@define
def filer(command='redraw', *args, bufname, filer_path='.', filer_open='[]', filer_mark='[]'):

    if not bufname.startswith('*filer'):
        yield 'edit -scratch *filer*'

    try:
        filer_open = set(json.loads(filer_open))
    except:
        filer_open = set()

    try:
        filer_mark = set(json.loads(filer_mark))
    except:
        filer_mark = set()

    yield '''
        declare-option line-specs filer_flags
        declare-option str filer_path .
        declare-option str filer_open []
        declare-option str filer_mark []

        map window normal o 'ghGL: eval filer open %val{selections}<ret>'
        map window normal c 'ghGL: eval filer close %val{selections}<ret>'
        map window normal m ': filer-mark toggle<ret>'
        map window normal M ': filer-mark set<ret>'
        map window normal <a-m> ': filer-mark remove<ret>'

        def -override filer-mark -params 1 %{
            eval -draft %{
                exec <a-x><a-s>
                eval filer mark %arg{1} %val{selections}
                echo -debug E
            }
            echo -debug F
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

        # map window user x ': eval fg %val{selections}; filer<ret>'
        # map window normal D ': filer-mark-rm<ret>'
        # def -override filer-mark-rm %{
        #     exec <a-s><a-x>
        #     try %{
        #         exec '<a-K>^rm<ret>irm <esc>;'
        #     } catch %{
        #         exec jgh
        #     }
        # }

    '''

    ret = []

    at_end = []

    if command == 'open':
        for arg in args:
            if arg.endswith('/'):
                filer_open |= {arg}
            else:
                yield q.spawn('danneopen', arg)
    elif command == 'close':
        if any(arg in filer_open for arg in args):
            filer_open -= set(args)
        else:
            parents = set()
            for arg in args:
                if arg not in filer_open:
                    parents.add('^\Q' + str(Path(arg).parent) + '/\E$')
            parents = '(' + '|'.join(parents) + ')'
            at_end += [
                q.exec_if_you_can(
                    '%s' + parents + '<ret>ghGL',
                    q.fail('no parent'),
                )
            ]
    elif command == 'redraw':
        pass
    elif command == 'mark':
        subcommand, *paths = args
        paths = {path.strip() for path in paths}
        if subcommand == 'toggle':
            if any(arg not in filer_mark for arg in paths):
                filer_mark |= paths
            else:
                filer_mark -= paths
        elif subcommand == 'set':
            filer_mark = paths
        elif subcommand == 'remove':
            filer_mark -= paths
        else:
            yield q.fail(f'no such mark {subcommand = }')
    else:
        filer_path = command
        if filer_path:
            yield q.set('window', 'filer_path', filer_path)

    rows = sorted(go(filer_path, filer_open))

    lines = []
    repls = []

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

    lines = '\n'.join(lines)

    yield q.eval(
        '\n' + q.reg('c', lines),
        '\n' + q.exec('%|printf %s "$kak_reg_c"<ret>', draft=True),
        draft=True,
    )

    yield 'set window filer_flags %val{timestamp} ' + q(*repls)

    yield q.set('window', 'filer_open', json.dumps(list(sorted(list(filer_open)))))
    yield q.set('window', 'filer_mark', json.dumps(list(sorted(list(filer_mark)))))

    yield r'''
        rmhl window/filer1
        rmhl window/filer2
        rmhl window/filer3
        addhl window/filer1 regex ^[^\n]*/ 0:blue
        addhl window/filer2 regex [^/\n]*/$ 0:green
        # addhl window/filer3 regex [^/\n]*$ 0:yellow

        rmhl window/filerflags
        addhl window/filerflags flag-lines magenta filer_flags
    '''

    # yield q.echo('-debug', repr(filer_mark))

    yield q.echo('-debug', repr(args))

    yield from at_end
    yield 'echo -debug D'

    if ret:
        ret = '\n'.join(ret)
        yield q.info(ret)

