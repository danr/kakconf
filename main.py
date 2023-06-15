from typing import *
import threading

import commas
commas.init()

import arrange
arrange.init()

import invert
invert.init()

import filer
filer.init()

# import tree
# tree.init()

from libpykak import k, q
import contextlib

def py_run(*_parts: str, _mode: str):
    import re, sys, os, shlex, json, math, textwrap, shutil, glob, subprocess as sub, io
    from pprint import pprint, pp, pformat

    _stdout = io.StringIO()

    with contextlib.redirect_stdout(_stdout):
        g = locals() | dict(k=k, q=q)
        g = {k: v for k, v in g.items() if not k.startswith('_')}
        if _mode == 'eval':
            res = eval(' '.join(_parts), g)
        else:
            res = exec(textwrap.dedent(' '.join(_parts)), g)

    out = _stdout.getvalue().strip()
    if res is not None or not out:
        if isinstance(res, str):
            out = out + '\n' + res
        else:
            out = out + '\n' + pformat(res)
    out = out.strip()
    k.debug(out)
    k.eval(q('info', out))
    k.eval(q('reg', '"', out))

@k.cmd
def py_exec(*parts: str):
    '''
    exec python code. arguments will be joined with space. results in yank registers.
    '''
    return py_run(*parts, _mode='exec')

@k.cmd
def py_eval(*parts: str):
    '''
    eval python code. arguments will be joined with space. results in yank registers.
    '''
    return py_run(*parts, _mode='eval')

k.eval('''
    alias global py py_eval
    alias global py-exec py_exec
''')

k.eval('''
    def -override py_exec_para %{
        eval -draft %{
            exec <a-a>p
            reg p %val{selection}
        }
        py_exec %reg{p}
    }
    hook global WinSetOption filetype=python %{
        map window user e ': py_exec_para<ret>'
    }
''')

@k.cmd
def toggle(scope: str, on: str, off: str):
    import json
    k.eval('try "decl str toggles"')
    try:
        toggles = json.loads(k.opt.toggles[0])
    except:
        toggles = []
    if not isinstance(toggles, list):
        toggles = []
    if on in toggles:
        toggles.remove(on)
        k.eval(
            f'set {scope} toggles ' + q(json.dumps(toggles)),
            off,
            q('info', off),
        )
    else:
        toggles += [on]
        k.eval(
            f'set {scope} toggles ' + q(json.dumps(toggles)),
            on,
            q('info', on),
        )

@k.cmd
def goto_file_sloppy(fragment: str):
    import re
    m = re.search(r'([^\s:]+):?(\d*)', fragment)
    filename, line_str = m.groups()
    if line_str.isdigit():
        line = int(line_str)
    else:
        line = 1
    k.eval(f'edit {filename} {line}')

k.eval('''
    map global user g ': goto_file_sloppy %sh{xclip -o}<ret>'
''')

@k.cmd
def reload():
    from pathlib import Path
    import sys
    import runpy
    for name, m in list(sys.modules.items()):
        a = Path(getattr(m, '__file__', None) or '').parent
        b = Path(__file__).parent
        if a == b and not name.startswith('__'):
            print('purging', name)
            del sys.modules[name]
    runpy.run_module('main')
    print(flush=True)

@k.cmd
def sort_buffers():
    k.eval(q('arrange-buffers',sorted(k.val.buflist)))

