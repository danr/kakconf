import os, sys, shlex, json, socky

calls = 0

@socky.serve('''%val{client} %val{selections} -- %arg{@}''', mode='sync')
def sockex(client, *args):
    '''
    eval %sh{python code/kakconf/sockex.py init}; sockex
    '''
    global calls
    calls += 1
    return 'info -- ' + socky.quote(json.dumps({
        'args': args,
        'calls': calls,
        'async': False,
    }, indent=2))
