hook -once global BufSetOption filetype=python %{
    require-module jedi
}

decl -hidden str jedi_source %val{source}

provide-module jedi %{

eval %sh{
    python $(dirname "$kak_opt_jedi_source")/jedikak.py init
}

define-command jedi -params 1.. -hidden %{
    eval -save-regs b %{
        exec -draft '%"by'
        jedi_impl %arg{@}
    }
}

declare-option -docstring "colon separated list of path added to `python`'s $PYTHONPATH environment variable" \
    str jedi_python_path

declare-option -hidden completions jedi_completions
declare-option -hidden str jedi_info
declare-option -hidden str jedi_last_name

define-command jedi-complete -docstring "Complete the current selection" %{
    jedi complete
}

define-command jedi-goto -docstring "goto" %{
    jedi goto
}

define-command jedi-info -docstring "info" %{
    jedi info
}

define-command jedi-enable-autocomplete -docstring "Add jedi completion candidates to the completer" %{
    set-option window completers option=jedi_completions %opt{completers}
    hook window -group jedi-autocomplete InsertIdle .* %{ try %{
        execute-keys -draft <a-h><a-k>\..\z<ret>
        echo 'completing...'
        jedi complete
    } }
    alias window complete jedi-complete
}

define-command jedi-disable-autocomplete -docstring "Disable jedi completion" %{
    set-option window completers %sh{ printf %s\\n "'${kak_opt_completers}'" | sed -e 's/option=jedi_completions://g' }
    remove-hooks window jedi-autocomplete
    unalias window complete jedi-complete
}

}
