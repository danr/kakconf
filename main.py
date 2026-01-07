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

@k.cmd
def py_replace(*_parts: str):
    '''
    Replace each selection with the result from a python expression

    The content of the selection is in `s`, and parsed as int in `i` and as double in `d`, 1-based index in `ix`, `v` is json.loads or ast.literal_eval, if any of them work
    '''
    import re, sys, os, shlex, json, math, textwrap, shutil, glob, subprocess as sub, io, ast
    from pprint import pprint, pp, pformat

    g = locals() | dict(k=k, q=q)
    g = {k: v for k, v in g.items() if not k.startswith('_')}
    out: list[str] = []
    for ix, s in enumerate(k.val.selections, start=1):
        try:
            i = int(s)
        except:
            i = None
        try:
            d = float(s)
        except:
            d = None
        try:
            v = ast.literal_eval(s)
        except:
            try:
                v = json.loads(s)
            except:
                v = None
        try:
            res = eval(' '.join(_parts), dict(g, i=i, s=s, d=d, ix=ix, v=v))
        except Exception as e:
            k.eval(q('info', repr(e)))
            k.debug(repr(e))
            return
        res = str(res)
        out += [res]

    k.debug(out)
    k.eval(q('reg', 'c', *out), q('exec', '"cR'))

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
    alias global sed py_replace
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

import urllib.request
import urllib.parse
import re
import ast
import json

def ask(prompt: str, model: str='dolphin-mistral'):
    data: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }

    data_str = json.dumps(data)

    # Create a request object
    request_url = 'http://127.0.0.1:11434/api/generate'
    headers = {'Content-Type': 'application/json'}
    request = urllib.request.Request(request_url, data=data_str.encode(), headers=headers)

    # Send the request and read the response
    response = urllib.request.urlopen(request)

    res = json.loads(response.read().decode())
    return res['response']

def stream(prompt: str, model: str='dolphin-mistral'):
    data: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "stream": True
    }

    data_str = json.dumps(data)

    # Create a request object
    request_url = 'http://127.0.0.1:11434/api/generate'
    headers = {'Content-Type': 'application/json'}
    request = urllib.request.Request(request_url, data=data_str.encode(), headers=headers)

    text = ''

    with urllib.request.urlopen(request) as response:
        for line in response:
            data = json.loads(line.decode())
            if data['done']:
                return
            else:
                text += data['response']
                yield text

def spawn(f: Callable[[], None]) -> None:
    '''

    '''
    threading.Thread(target=f, daemon=True).start()

@k.cmd
def complete():
    lines = k.val.bufstr.splitlines(keepends=True)
    y, x = k.val.cursor_line - 1, k.val.cursor_column - 1
    pre, this, post = lines[:y], lines[y], lines[y:]
    pre = ''.join(pre) + this[:x]
    post = this[x:] + ''.join(post)

    filetype = k.opt.filetype

    prompt = f'Complete this code ```{filetype}\n{this[:x]}'

    client = k.val.client

    @spawn
    def _():
        for text in stream(prompt):
            k.eval(q.info(text), client=client)

