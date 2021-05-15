import os, sys, shlex, json, socky, time

calls = 0

@socky.serve('''%val{client} %val{selections} -- %arg{@}''', mode='async')
def sockex_async(client, *args):
    '''
    eval %sh{python sockex_async.py init}; sockex_async
    '''
    global calls
    calls += 1
    time.sleep(1.0)
    return socky.quote(
        'eval',
        '-client', client,
        'info -- ' + socky.quote(json.dumps({
            'args': args,
            'calls': calls,
            'async': True,
        }, indent=2)))
