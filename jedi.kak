hook -once global BufSetOption filetype=python %{
    require-module jedi
}

provide-module jedi %{

def jedi-log-errfile -params 1 %{
    nop %sh{
        cat "$1" >&2
        rm "$1"
    }
}

def jedi-call-python -params .. %{
    eval eval "%%sh{
        ( {
            errfile=$(mktemp)
            python ""$@"" 2> ""$errfile"" | kak -p ""$kak_session""
            printf %%s ""jedi-log-errfile $errfile"" | kak -p ""$kak_session""
        } & ) >/dev/null 2>&1 </dev/null
        exit $?
        %sh{grep -o 'kak_\w\+' ""$1""}
    }"
}

declare-option -docstring "colon separated list of path added to `python`'s $PYTHONPATH environment variable" \
    str jedi_python_path

declare-option -hidden completions jedi_completions
declare-option -hidden str jedi_info
declare-option -hidden str jedi_last_name

define-command jedi-complete -docstring "Complete the current selection" %{
    jedi-impl complete
}

define-command jedi-goto -docstring "todo" %{
    jedi-impl goto
}

define-command jedi-info -docstring "todo" %{
    jedi-impl info
}

decl -hidden str jedi_source_dir %sh{dirname "$kak_source"}

define-command jedi-impl -params 1.. -hidden %{
    eval -save-regs b %{
        exec -draft '%"by'
        jedi-call-python "%opt{jedi_source_dir}/jedikak.py" %arg{@}
    }
}

define-command jedi-enable-autocomplete -docstring "Add jedi completion candidates to the completer" %{
    set-option window completers option=jedi_completions %opt{completers}
    hook window -group jedi-autocomplete InsertIdle .* %{ try %{
        execute-keys -draft <a-h><a-k>\..\z<ret>
        echo 'completing...'
        jedi-complete
    } }
    alias window complete jedi-complete
}

define-command jedi-disable-autocomplete -docstring "Disable jedi completion" %{
    set-option window completers %sh{ printf %s\\n "'${kak_opt_completers}'" | sed -e 's/option=jedi_completions://g' }
    remove-hooks window jedi-autocomplete
    unalias window complete jedi-complete
}

}
