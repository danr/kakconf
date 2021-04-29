
from libkak import *
import json
# import fs
# from viable import *
from datetime import datetime
import re

from subprocess import run
# import sys

import os

def show_ts(ts):
    return datetime.fromtimestamp(int(ts))

def show_size(size, units=' KMGTPE'):
    """ Returns a human readable string representation of size """
    return str(round(size, 0)) + units[0] if size < 1000 else show_size(size / 1024, units[1:])

if 0:
    for e in os.scandir('.'):
        print(e.is_dir(), '\t', e.stat().st_size, '\t', show_ts(e.stat().st_mtime), '\t', e.path, '\t', e.name)

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
            # if not is_open:
            yield entry_key, is_dir, is_open, root, path, entry.stat()
            if is_open:
                yield from go(
                    entry.path,
                    opened,
                    entry_key
                )
    except PermissionError:
        pass

@define
def filer(command='redraw', *args, filer_open='', filer_path='.', selections_desc, timestamp):

    try:
        filer_open = json.loads(filer_open)
    except:
        filer_open = []

    yield '''
        declare-option range-specs filer
        declare-option line-specs filer_flags
        declare-option str filer_path .
        try %{ declare-option str filer_open [] }

        map window normal o 'xH: eval filer open %val{selections}<ret>'
        map window normal c 'xH: filer close %val{selection}<ret>'
        map window user x ': eval fg %val{selections}; filer<ret>'
        map window normal D ': filer-mark-rm<ret>'

        def -override filer-mark-rm %{
            exec <a-s><a-x>
            try %{
                exec '<a-K>^rm<ret>irm <esc>;'
            } catch %{
                exec jgh
            }
        }
    '''

    ret = []

    at_end = []

    yield q.echo('-debug', json.dumps(args))

    if command == 'open':
        for arg in args:
            if arg.endswith('/'):
                filer_open += args
            else:
                # yield f'nop %sh[danneopen {json.dumps(arg)}]'
                yield q.spawn('danneopen', arg)
                # ret += [str(run(['danneopen', arg]))]
        filer_open = list(set(filer_open))
        yield q.set('window', 'filer_open', json.dumps(filer_open))
    elif command == 'close':
        arg = args[0]
        if arg in filer_open:
            filer_open = list(set(filer_open) - set(args))
            yield q.set('window', 'filer_open', json.dumps(filer_open))
        else:
            # already closed, instead focus parent ...
            at_end += [
                q.exec('gg/\Q', '/'.join(arg.rstrip('/').split('/')[:-1])[1:], '<ret>xH')
            ]
    elif command == 'run':
        for arg in args:
            yield f'nop %sh[danneopen {json.dumps(arg)}]'
            # ret += [run(['danneopen', arg])]

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

        repls += [f'{i}|{r}']
        lines += [path]

    lines = '\n'.join(lines)

    yield q.eval(
        q.reg('c', lines) + '\n',
        q.exec('%"cR', draft=True) + '\n',
        draft=True,
    )

    yield 'set window filer_flags %val{timestamp} ' + q(*repls)

    yield 'select ' + selections_desc

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

    yield from at_end

    if ret:
        ret = '\n'.join(ret)
        yield q.info(ret)

