
from libpykak import k, q
from datetime import datetime
from pathlib import Path
import os
import re
import sys
import shlex
from typing import Any, Tuple, Iterator

def show_ts(ts: float | int):
    return datetime.fromtimestamp(int(ts))

def show_size(size: int, units: str=' KMGTPE') -> str:
    """ Returns a human readable string representation of size """
    return str(round(size, 0)) + units[0] if size < 1000 else show_size(size // 1024, units[1:])

def go(root: str, opened: set[str], key: list[Any]=[]) -> Iterator[
    tuple[list[Any], bool, bool, str, str, os.stat_result]
]:
    try:
        for entry in os.scandir(root):
            if entry.name.startswith('.'):
                continue
            if '.egg-info' in entry.name:
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

def init():
    k.eval('''
        try %(decl line-specs filer_flags)
        try %(decl str filer_path .)
        try %(decl str-list filer_open)
        try %(decl str-list filer_mark)
        def -override exec-if-you-can -params 2 %(
            try %(
                exec -draft %arg(1)
                exec %arg(1)
            ) catch %(
                eval %arg(2)
            )
        )

        def -override filer-popup %(
            eval -draft -save-regs '' %(
                exec ghGL
                reg s %val(selection)
            )
            info -- %sh(
                file -i "$kak_reg_s"
                file -b "$kak_reg_s" | fmt
                if file -bi "$kak_reg_s" | grep -v charset=binary >/dev/null; then
                    echo
                    head -c 10000 "$kak_reg_s" |
                    cut -c -80 | # $((kak_window_width / 2)) |
                    head -n $((kak_window_height / 2))
                fi
            )
        )

        def -override filer-idle-popup-enable %(
            hook window -group filer-idle-popup NormalIdle .* filer-popup
        )

        def -override filer-idle-popup-disable %(
            rmhooks window filer-idle-popup
        )
    ''')

prelude = str(r'''
    map buffer normal o     ': filer open        <ret>'
    map buffer normal c     ': filer close       <ret>'
    map buffer normal m     ': filer mark-toggle <ret>'
    map buffer normal M     ': filer mark-set    <ret>'
    map buffer normal <a-m> ': filer mark-remove <ret>'

    rmhl buffer/filer1
    rmhl buffer/filer2
    addhl buffer/filer1 regex ^[^\n]*/ 0:blue
    addhl buffer/filer2 regex [^/\n]*/$ 0:green

    rmhl buffer/filerflags
    addhl buffer/filerflags flag-lines magenta filer_flags

    rmhooks buffer filer-redraw
    hook -group filer-redraw buffer WinDisplay .* %(filer redraw)

''')

def replace_buffer(*lines: str):
    return q('exec', '-draft', '%|', r"printf '%s\n' " + shlex.join(lines), '<ret>')

from typing_extensions import ParamSpec
from typing import Iterator, Callable
from functools import wraps
P = ParamSpec('P')

def eval_generator(f: Callable[P, Iterator[str]]) -> Callable[P, None]:
    @wraps(f)
    def inner(*args: P.args, **kws: P.kwargs):
        k.eval(*f(*args, **kws))
    return inner

from threading import RLock
from pathlib import Path
from contextlib import contextmanager

@contextmanager
def chdir(path: str, __pwd_lock: RLock = RLock()):
    at_begin = os.getcwd()
    with __pwd_lock:
        try:
            os.chdir(path)
            yield
        finally:
            os.chdir(at_begin)

@k.cmd
@eval_generator
def filer(command: str='', *args: str) -> Iterator[str]:
    bufname    = k.val.bufname
    filer_path = k.opt.filer_path.as_str()
    filer_open = k.opt.filer_open.as_str_list()
    filer_mark = k.opt.filer_mark.as_str_list()
    pwd = k.pwd()
    with chdir(pwd):

        if not bufname.startswith('*filer'):
            yield 'edit -scratch *filer*'

        filer_open = set(filer_open)
        filer_mark = set(filer_mark)

        [selected_paths] = k.eval_sync(f'''
            eval -save-regs s %(
                eval -draft %(
                    exec <a-x><a-s>
                    {k.pk_send} %val(selections)
                )
            )
        ''')

        arg_paths = {path.strip('\n') for path in selected_paths}

        at_end: list[str] = []

        print('lol')

        if command == 'open':
            for arg in arg_paths:
                if arg.endswith('/'):
                    filer_open |= {arg}
                else:
                    yield q.debug('open', arg)
                    # yield q.debug('nop %sh' + q('danneopen ' + shlex.quote(arg)))
                    # yield 'nop %sh' + q('danneopen ' + shlex.quote(arg))
                    yield q('bg', 'danneopen', arg)
        elif command == 'close':
            if any(arg in filer_open for arg in arg_paths):
                filer_open -= arg_paths
            else:
                parents: set[str] = set()
                for arg in arg_paths:
                    if arg not in filer_open:
                        parents.add(r'^\Q' + str(Path(arg).parent) + r'/\E$')
                parents_str: str = '(' + '|'.join(parents) + ')'
                at_end += [
                    q('exec-if-you-can',
                        '%s' + parents_str + '<ret>ghGL',
                        q('fail', 'no parent'),
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
        else:
            yield prelude
            if command:
                filer_path = command
                yield q('set', 'buffer', 'filer_path', filer_path)

        lines: list[str] = []
        repls: list[str] = []

        rows = list(sorted(go(filer_path, filer_open)))

        paths: set[str] = set()

        open_dirs = {filer_path}

        for i, (key, is_dir, is_open, root, path, stat) in enumerate(rows, start=1):
            paths.add(path)
            if is_dir and is_open:
                open_dirs.add(path)

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

        yield replace_buffer(*lines)

        yield 'set buffer filer_flags %val{timestamp} ' + q(*repls)

        yield q('set', 'buffer', 'filer_open', *sorted(filer_open))
        yield q('set', 'buffer', 'filer_mark', *sorted(filer_mark))

        yield from at_end

@k.cmd
def filer_xargs(*args: str):
    files = k.opt.filer_mark
    if files:
        parts = [
            *args,
            *k.opt.filer_mark,
        ]
        script = ' '.join(map(shlex.quote, parts))
        k.eval(f'info %sh[{script}]')

@k.cmd
def filer_mv(dest: str):
    filer_xargs(
        'mv',
        '--target-directory', dest,
    )

k.eval('''
    alias global mv filer_mv
    alias global filer-xargs filer_xargs
''')
