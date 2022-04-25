
nop %{
decl str py_res
decl str py_prefix
decl str py_pwd

def py -params .. %{
    py-save %arg{@}
    echo %opt{py_res}
    info -title py %opt{py_res}
}

def py-replace -params .. %{
    eval -itersel %{
        py-save %arg{@}
        reg p %opt{py_res}
        exec '"pR'
    }
}

def py-paste -params .. %{
    eval -itersel %{
        py-save %arg{@}
        reg p %opt{py_res}
        exec 'i<c-r>p<esc>'
    }
}

def py-save -params .. %{
    set global py_res %sh{
        set -x
        module=$(printf %s "${kak_bufname%.py}" | sed s,/,.,g)
        module="$kak_opt_py_prefix$module"
        if printf %s "$module" | grep -P '^(\w+\.)*\w+$' >/dev/null; then
            import="from $module import *"
        else
            import=""
        fi
        python -c "if 1:
            import sys, shlex, os
            env = os.environ.get
            bufname = env('kak_bufname')
            buffile = env('kak_buffile')
            sel = selection = env('kak_selection')
            sels = selections = shlex.split(env('kak_quoted_selections'))
            args = sys.argv[1:]
            py_pwd = env('kak_opt_py_pwd')
            if py_pwd:
                os.chdir(py_pwd)
            $import
            if not len(args):
                args = [sel]
            if len(args):
                *init, last = args
                for arg in init:
                    if arg.strip():
                        exec(arg)
                if last.strip():
                    res = eval(last)
                else:
                    res = None
                if res is not None:
                    print(res)
        " "$@" 2>&1
    }
}

try %{
    source init.kak
}
}
