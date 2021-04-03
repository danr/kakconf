
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


maps = {}
maps[10] = r'''  1 2 3 4 5  6 7 8 9 0    --  ! @ # $ %  ^ & * ( )    --  ! , . $ %  ^ & * ( )    '''
maps[24] = r'''  ' , . p y  f g c r l /  --  " < > P Y  F G C R L ?  --  ! , + | %  > { ( ) } ?  '''
maps[38] = r'''  a o e u i  d h t n s    --  A O E U I  D H T N S    --  & @ = _ ~  $ [ ' " ]    '''
maps[52] = r'''  : q j k x  b m w v z    --  ; Q J K X  B M W V Z    --  å ä ö \ ^  < * w ` ;    '''
maps[9]  = r'''  Escape -- Escape -- space  '''

import re

ckm = {}
for start, row in maps.items():
    parts = row.strip().split('--')
    for code, keys in enumerate(zip(*[ part.split() for part in parts ]), start=start):
        keys = list(keys)
        if len(keys) == 3:
            keys += [keys[-1].upper()]
        a, b, c, d = keys
        if re.match("[a-z:',.]$", a):
            ckm[a] = c

from textwrap import indent

def seq(*cmds):
    body = '\n' + '\n'.join(cmds)
    body = indent(body, prefix='  ')
    return q.eval(body)
    # if not re.search('[()]', body):
    #     return 'eval %(' + body + ')'
    # elif not re.search('[{}]', body):
    #     return 'eval %{' + body + '}'
    # elif not re.search(r'[\[\]]', body):
    #     return 'eval %[' + body + ']'
    # elif not re.search('[<>]', body):
    #     return 'eval %<' + body + '>'
    # else:
    #     return q.eval(body)

def start_comma():
    cleanup = 'rmhooks window comma-once'
    yield cleanup
    for trigger, output in ckm.items():
        if output == ')':
            cmd = 'eval %{exec <backspace><backspace>; close}'
        else:
            cmd = 'exec <backspace><backspace> ' + q(output)
        cmd = seq(
            # 'set window debug commands',
            cmd,
            cleanup,
            # 'set window debug ""',
        )
        yield 'hook -group comma-once -once window InsertChar ' + q(r'\Q' + trigger) + ' ' + q(cmd)
    yield 'hook -group comma-once -once window ModeChange .*    ' + q(cleanup)
    yield 'hook -group comma-once -once window InsertChar .*    ' + q(cleanup)
    yield 'hook -group comma-once -once window RawKey     [^,]+ ' + q(cleanup)

@define(style='raw')
def setup_comma():
    yield 'rmhooks global commas'
    yield 'hook -group commas global InsertChar , ' + q(seq(*start_comma()))

@define(style='on-key')
def hmm(*, key):
    yield q.echo(key)
