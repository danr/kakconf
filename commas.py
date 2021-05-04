
from textwrap import indent
import sys
import re
import os

from filer import q

maps = {}
maps[10] = r'''  1 2 3 4 5  6 7 8 9 0    --  ! @ # $ %  ^ & * ( )    --  ! , . $ %  ^ & * ( )    '''
maps[24] = r'''  ' , . p y  f g c r l /  --  " < > P Y  F G C R L ?  --  ! , + | %  < { ( ) } ?  '''
maps[38] = r'''  a o e u i  d h t n s    --  A O E U I  D H T N S    --  & @ = _ ~  $ [ ' " ]    '''
maps[52] = r'''  : q j k x  b m w v z    --  ; Q J K X  B M W V Z    --  å ä ö \ ^  > * w ` ;    '''
maps[9]  = r'''  Escape -- Escape -- space  '''

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

def setup():
    yield 'rmhooks global commas'
    yield 'hook -group commas global InsertChar , ' + q([*hook_on_insert()])

def hook_on_insert():
    cleanup = 'rmhooks window comma-once'
    yield cleanup
    for trigger, output in ckm.items():
        if output == ')':
            cmd = 'eval %{exec <backspace><backspace>; close}'
        else:
            cmd = 'exec <backspace><backspace> ' + q(output)
        cmd = q('eval', [
            # 'set window debug commands',
            cmd,
            cleanup,
            # 'set window debug ""',
        ])
        yield 'hook -group comma-once -once window InsertChar ' + q(r'\Q' + trigger) + ' ' + q(cmd)
    yield 'hook -group comma-once -once window ModeChange .*    ' + q(cleanup)
    yield 'hook -group comma-once -once window InsertChar .*    ' + q(cleanup)
    yield 'hook -group comma-once -once window RawKey     [^,]+ ' + q(cleanup)

def main(cmd):
    if cmd == 'setup':
        print('\n'.join(setup()))
    elif cmd == 'replace':
        key = os.environ["kak_key"]
        repl = ckm.get(key)
        if repl == 'C':
            print('exec', 's.<ret>d')
            print('close')
        elif repl:
            print('exec', 'r', q(repl))
        else:
            print('exec', 'r', q(key))

if __name__ == '__main__':
    main(*sys.argv[1:])
