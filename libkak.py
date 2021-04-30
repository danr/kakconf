
from textwrap import dedent
from inspect import signature
from functools import wraps
import re
import sys
import os

def balanced(pairs, s):
    open, close = pairs
    count = 0
    for c in s:
        if c == open:
            count += 1
        elif c == close:
            count -= 1
            if count < 0:
                return False
    return count == 0

class Quoter():
    def __call__(self, *args, **kws):
        def with_arg(arg):
            arg = str(arg)
            if not arg:
                return ''
            elif not re.search(r'''[\\\s'";%]''', arg):
                return arg
            elif not re.search(r"[\n']", arg):
                return "'" + arg + "'"
            elif not re.search(r'[\n"%]', arg):
               return '"' + arg + '"'
            elif balanced('{}', arg):
                return '%{' + arg + '}'
            elif balanced('()', arg):
                return '%(' + arg + ')'
            elif balanced('[]', arg):
                return '%[' + arg + ']'
            else:
                arg = arg.replace("'", "''")
                return "'" + arg + "'"

        def with_kws(kws):
            for k, v in kws.items():
                k = '-' + k.replace('_', '-')
                if isinstance(v, bool):
                    if v:
                        yield k
                else:
                    yield k
                    yield v
        if not len(args) and len(kws):
            head = ['']
        elif len(args):
            head, *args = args
            head = [head]
        else:
            head = []
        args = (*head, *with_kws(kws), *args)
        return ' '.join(with_arg(arg) for arg in args)

    def __getattr__(self, s):
        return lambda *args, **kws: self(s.replace('_', '-'), *args, **kws)

q = Quoter()

if '--test-quoter' in sys.argv:
    print(q('echo'))
    print(q(docstring='echo blecho'))
    print(q.info('hello hello', markup=True, style='above'))
    print(q.map('global', 'normal', 'x', ': what<ret>', docstring="hehehe's hello"))
    print(q.exec('bwd', try_client='client0'))
    sys.exit()

usage_written = False

argd = dict(enumerate(sys.argv))

from pathlib import Path

def expose_def(func, name, args=[], switches='', style='def'):
    argv0 = str(Path(sys.argv[0]).resolve())
    if argd.get(1) == '--source' and style != 'raw':
        # eval %sh{python file.py --source}
        if style == 'def':
            print(dedent(f"""
                define-command {name} {switches.strip()} %(
                    eval %sh(
                        python {argv0} --call {name} "$@" # {' '.join(args)}
                    )
                )""").strip())
        elif style == 'on-key':
            print(dedent(f"""
                define-command {name} {switches.strip()} %(
                    on-key %(
                        eval %sh(
                            python {argv0} --call {name} "$@" # {' '.join(args)}
                        )
                    )
                )""").strip())
    elif argd.get(1) == '--call' or style == 'raw':
        if argd.get(2) == name or style == 'raw':
            ret = func(*sys.argv[3:])
            if not ret:
                pass
            elif isinstance(ret, str):
                print(ret)
                print(ret, file=sys.stderr)
            else:
                for x in ret:
                    print(x)
                    print(x, file=sys.stderr)
            if style != 'raw':
                sys.exit(0)
    else:
        global usage_written
        if not usage_written:
            print(f'Usage: python {sys.argv[0]} (--source|--call FUNC_NAME ...ARGS)', file=sys.stderr)
            usage_written = True

def define(switches='', name=None, params=None, override=True, style='def'):
    def inner(f):
        nonlocal switches, params, name
        sig = list(signature(f).parameters.values())
        kw_only = [p.name for p in sig if p.kind == p.KEYWORD_ONLY]
        alts = ['', 'kak_', 'kak_opt_']
        args = [prefix + suffix for prefix in alts for suffix in kw_only]
        args = [arg for arg in args if arg.startswith('kak_')]
        @wraps(f)
        def adapted(*args):
            kws = {}
            for kw in kw_only:
                # kws[kw] = None
                for prefix in alts:
                    var = prefix + kw
                    if var in os.environ:
                        kws[kw] = os.environ[var]
                        break
            return f(*args, **kws)

        switches += q(override=override)

        if f.__doc__:
            switches += q(docstring=f.__doc__)

        if params is not None:
            switches += q(params=params)
        else:
            params = [p for p in sig if p.kind in [p.POSITIONAL_ONLY, p.POSITIONAL_OR_KEYWORD]]
            min_params = len([p for p in params if p.default is p.empty])
            max_params = len(params)

            if any(p.kind == p.VAR_POSITIONAL for p in sig):
                switches += q(params=f'{min_params}..')
            else:
                switches += q(params=f'{min_params}..{max_params}')

        name = name or f.__name__
        name = name.replace('_', '-')
        expose_def(adapted, name, args, switches, style=style)
        return f
    if callable(switches):
        f = switches
        switches = ''
        return inner(f)
    else:
        return inner

