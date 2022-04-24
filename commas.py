
from libpykak import k, q
from textwrap import indent
import sys
import re
import os

# from filer import q

maps: dict[int, str] = {}
maps[10] = r'''  1 2 3 4 5  6 7 8 9 0    --  ! @ # $ %  ^ & * ( )    --  ! , . $ %  ^ & * ( )    '''
maps[24] = r'''  ' , . p y  f g c r l /  --  " < > P Y  F G C R L ?  --  ! , + | %  < { ( ) } ?  '''
maps[38] = r'''  a o e u i  d h t n s    --  A O E U I  D H T N S    --  & @ = _ ~  $ [ ' " ]    '''
maps[52] = r'''  : q j k x  b m w v z    --  ; Q J K X  B M W V Z    --  å ä ö \ ^  > * w ` ;    '''
maps[9]  = r'''  Escape -- Escape -- space  '''

ckm: dict[str, str] = {}
for start, row in maps.items():
    parts = row.strip().split('--')
    for code, keys in enumerate(zip(*[ part.split() for part in parts ]), start=start):
        keys = list(keys)
        if len(keys) == 3:
            keys += [keys[-1].upper()]
        a, b, c, d = keys
        if re.match("[a-z:',.]$", a):
            ckm[a] = c

def init():
    k.eval(
        'rmhooks global commas',
        'hook -group commas global InsertChar , ' + q(q.eval(*hook_on_insert())),
    )

def hook_on_insert():
    cleanup = 'rmhooks window comma-once'
    yield cleanup
    for trigger, output in ckm.items():
        if output == ')':
            cmd = 'eval %{exec <backspace><backspace>; close}'
        else:
            cmd = 'exec <backspace><backspace> ' + q(output)
        cmd = q.eval(
            # 'set window debug commands',
            cmd,
            cleanup,
            # 'set window debug ""',
        )
        yield 'hook -group comma-once -once window InsertChar ' + q(r'\Q' + trigger) + ' ' + q(cmd)
    yield 'hook -group comma-once -once window ModeChange .*    ' + q(cleanup)
    yield 'hook -group comma-once -once window InsertChar .*    ' + q(cleanup)
    yield 'hook -group comma-once -once window RawKey     [^,]+ ' + q(cleanup)

@k.map('r')
@k.cmd
def replace():
    @k.on_key
    def first(key: str):
        print(key)
        if key != ',':
            k.eval(q('exec', 'r', key))
        else:
            @k.on_key
            def second(key: str):
                print(key)
                repl = ckm.get(key)
                if repl == 'C':
                    k.eval('exec s.<ret>d', 'close')
                else:
                    k.eval(q('exec', 'r', repl or key))
