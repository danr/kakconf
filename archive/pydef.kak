
unalias global sh

def sh -params .. %{
    eval eval "%%sh{""$@"" # %sh{printf '%s ' ""$@"" | grep -o 'kak_\w\+' | tr '\n' ' '}}"
}

def example %{
    sh python -c %{if 1:
        import os, sys, shlex, json
        env = os.environ.get

        def quote(s):
            return "'" + s.replace("'", "''") + "'"

        print('info --', quote(json.dumps({
            'buffile': env('kak_buffile'),
            'bufname': env('kak_bufname'),
            'argv': sys.argv,
            'selections': shlex.split(env('kak_quoted_selections'))
        }, indent=2)))
    } %val{selections}
}

def pydef -params .. %{
    sh python -c %{if 1:
        import os, sys, shlex, json, re
        def quote(s): return "'" + s.replace("'", "''") + "'"
        args = sys.argv[1:]
        name, *params, body = args
        vars = re.findall('kak_\w+', body)
        body = 'python -c ' + shlex.quote('if 1:\n' + body)
        body += ' # ' + ' '.join(vars)
        body = quote('eval %sh' + quote(body))
        print('def', name, *params, body)
        print('def', name, *params, body, file=sys.stderr)
    } %arg{@}
}

pydef -override hello %{
    print('info', 'hello')
}

