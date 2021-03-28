
from libkak import expose_def, define, q

expose_def(
    lambda: print('info ' + os.environ.get('kak_buffile', '?')),
    'test',
    ['kak_buffile'],
    '-override'
)

expose_def(
    lambda *args: print(f'''info "{' '.join(args)}"'''),
    'test2',
    [],
    '-params .. -override'
)

@define
def test3(*, buffile, reg_dquote):
    """
    Do amazing things!
    """
    return 'info ' + reg_dquote

@define
def test4(arg1, *, buffile, reg_dquote):
    """
    Do amazing things!
    """
    return [
        q.info('--', reg_dquote),
        q.echo(buffile, arg1, debug=True),
    ]

@define
def test5(arg1, arg2, *args, buffile):
    return ''

@define
def test6(arg1, arg2=2, *args, buffile):
    return ''

@define
def test7(arg1=1, arg2=2, *args, buffile):
    return ''

@define
def test8(arg1, arg2, *, buffile):
    return ''

@define
def test9(arg1, arg2=2, *, buffile):
    return ''

@define
def test0(arg1=1, arg2=2, *, buffile):
    return ''

@define
def snake_case(arg):
    return q.echo(arg.replace('-','_'))

@define
def yields():
    yield q.echo('0-first', debug=True)
    yield q.echo('1-second', debug=True)
    yield q.echo('2-third', debug=True)

@define
def py_impl(f, *, selection):
    return [
        q.reg('r', eval(f, globals(), dict(s=selection))),
        q.exec('"rR'),
    ]

@define
def py(f):
    return q.eval(q.py_impl(f), itersel=True, save_regs='r')

@define
def py_all(f, *, quoted_selections):
    import sys
    import shlex
    selections = shlex.split(quoted_selections)
    return q.eval(
        ';\n'.join(
            ';\n'.join([
                q.reg('r', eval(f, globals(), dict(s=s, i=i))),
                q.exec('<space>"rR', draft=True),
                q.exec(')'),
            ])
            for i, s in enumerate(selections)
        ),
        draft=True,
        save_regs='r',
    )


