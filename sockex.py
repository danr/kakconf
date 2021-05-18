import os, sys, shlex, json, socky, time

calls = 0

@socky.serve('''%val{client} "%val{selections}" "%val{selections_desc}" %val{selections} "%opt{xs}" %opt{xs} %arg{@}''', mode='sync')
def sockex(client, selections, descs, sels, *args):
    '''
    eval %sh{python sockex.py init}; sockex
    '''
    global calls
    calls += 1
    return 'info -- ' + socky.quote(json.dumps({
        'selections': selections.split('\0'),
        'sels': sels,
        'descs': descs.split('\0'),
        'args': args,
        'calls': calls,
        'async': False,
    }, indent=2))
