
define-command replace-with-expansion %{
    # What operations trigger kakoune's builtin differ?
    # Screwtape: Piping it through an external process would probably do it.
    execute-keys '|printf %s "$kak_window_range"<ret>'
}

define-command awk-env %{
    # you can pass things to awk in a %sh-block via environment variables
    info %sh{
        awk 'BEGIN {
            print ENVIRON["kak_selection"]
        }'
    }
}

define-command example-with-quoted-selections %{
    # use shlex and kak_quoted_ to make a kakoune str-list to a python list of str
    echo -debug %sh{
        python -c 'import os, shlex; print(repr(shlex.split(os.environ["kak_quoted_selections"])))'
    }
}

define-command replace-ranges-test %{
    # also see: https://gist.github.com/Screwtapello/5ff1be32fccf62acd1830aeaf8d7b69d
    decl range-specs repl
    rmhl window/repl
    addhl window/repl replace-ranges repl
    set window repl %val{timestamp} '18.38,22.6|..' '20.21,22.4|..'
}

define-command align-jsonl %{
    eval -draft %{
        try %{ execute-keys '%s \K +<ret>d' }
        execute-keys '%s( \d+\.|, \K")<ret>&'
    }
}

define-command -hidden select-until-aux -params 0..1 %{
    try %{
        set-register t %val{text}
        execute-keys -save-regs '/' "%arg{1}z%arg{1}?.*?(?=<c-r>t)<ret>"
    }
}

define-command select-until %{
    execute-keys -save-regs '' Z
    prompt -on-change 'select-until-aux <a-semicolon>' until: select-until-aux
}

