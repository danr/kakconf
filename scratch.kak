
def replace-with-expansion %{
    # What operations trigger kakoune's builtin differ?
    # Screwtape: Piping it through an external process would probably do it.
    exec '|printf %s "$kak_window_range"<ret>'
}


def awk-env %{
    # you can pass things to awk in a %sh-block via environment variables
    info %sh{
        awk 'BEGIN {
            print ENVIRON["kak_selection"]
        }'
    }
}

def example-with-quoted-selections %{
    # use shlex and kak_quoted_ to make a kakoune str-list to a python list of str
    echo -debug %sh{
        python -c 'import os, shlex; print(repr(shlex.split(os.environ["kak_quoted_selections"])))'
    }
}

def replace-ranges-test %{
    # also see: https://gist.github.com/Screwtapello/5ff1be32fccf62acd1830aeaf8d7b69d
    decl range-specs repl
    rmhl window/repl
    addhl window/repl replace-ranges repl
    set window repl %val{timestamp} '18.38,22.6|..' '20.21,22.4|..'
}

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
