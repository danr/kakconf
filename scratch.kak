
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

