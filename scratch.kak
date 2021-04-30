
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

def print-args -params .. %{
    eval %sh{
        python -c "if 1:
            import sys
            import json
            for arg in sys.argv[2:]:
                print('echo -debug -- \'', json.dumps(arg).replace('\'', '\'\''), '\'', sep='')
        " -- "$@"
    }
}

def print-selections %{
    eval reg s %val{selections}
    print-args %reg{s}
}

