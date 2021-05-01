
from datetime import datetime
from pathlib import Path
import os
import re
import sys
import shlex

class Quoter:
    def q1(self, arg):
        if isinstance(arg, list):
            return self.q1('\n '.join(arg))
        elif re.match('^[\w-]+$', arg):
            return arg
        else:
            return "'" + arg.replace("'", "''") + "'"

    def __call__(self, *args):
        return ' '.join(map(self.q1, args))

    def __getattr__(self, s):
        return lambda *args: self(s.replace('_', '-'), *args)

q = Quoter()

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
'''

def replace_buffer(*lines):
    return q.exec('-draft', '%|', r"printf '%s\n' " + shlex.join(lines), '<ret>')

def main(command='', *args):

    bufname=os.environ.get('kak_bufname')
    filer_path=os.environ.get('kak_opt_filer_path', '.')
    filer_open=os.environ.get('kak_quoted_opt_filer_open', '')
    filer_mark=os.environ.get('kak_quoted_opt_filer_mark', '')

    if not bufname.startswith('*filer'):
        yield 'edit -scratch *filer*'

    try:
        filer_open = set(shlex.split(filer_open))
    except:
        filer_open = set()

    try:
        filer_mark = set(shlex.split(filer_mark))
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
    else:
        yield prelude
        if command:
            filer_path = command
            yield q.set('window', 'filer_watcher', '')
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

    yield 'set window filer_flags %val{timestamp} ' + q(*repls)

    yield q.set('window', 'filer_open', *sorted(filer_open))
    yield q.set('window', 'filer_mark', *sorted(filer_mark))

    yield q.watch_dirs(*open_dirs)

    yield from at_end

if __name__ == '__main__':
    print('\n'.join(main(*sys.argv[1:])))
