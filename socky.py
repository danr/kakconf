
import os, sys, glob, socket, shlex, re

import pandas as pd

def quote(*args):
    c = "'"
    return " ".join(
        s if re.match("[\w-]+$", s) else c + s.replace(c, c+c) + c
        for s in args
    )

def serve(arg_string='%arg{@}', mode='sync'):
    assert mode in {'sync', 'async'}
    def serve_inner(f):

        name = f.__name__
        filepath = os.path.abspath(sys.argv[0])

        if sys.argv[1:] == ['init']:

            print(r''' # kak
                try %{
                    nop %opt{NAME_arg_string}
                } catch %{
                    decl -hidden str NAME_arg_string ""
                }
                def NAME -override -params .. %{
                    eval echo -quoting shell -to-file /tmp/NAME-arg %opt{NAME_arg_string}
                    eval %sh{
                        mtime=$(stat -c %Y FILEPATH)
                        sockfile="/tmp/NAME-$mtime.sock"
                        init () {
                            printf 'init\0' | socat STDIO "UNIX-CONNECT:$sockfile"
                            printf '\n%s\n' "echo NAME ready"
                            printf '%s\n' "follow /tmp/NAME.log"
                            printf '%s\n' "NAME %arg{@}"
                        }
                        if test ! -S "$sockfile"; then
                            ( {
                                python FILEPATH serve "$sockfile" 2>&1 | tee -a /tmp/NAME.log
                            } & ) >/dev/null 2>&1 </dev/null
                            for i in {1..250}; do
                                sleep 0.01
                                if test -S "$sockfile"; then
                                    init
                                    printf '%s\n' "spawn finished after $i rounds" >&2
                                    exit
                                fi
                            done
                            printf '%s\n' "fail failed spawning NAME (FILEPATH)" >&2
                            printf '%s\n' "fail failed spawning NAME (FILEPATH)"
                        elif test "$kak_opt_NAME_arg_string" = ""; then
                            init
                        else
                            input=$(cat /tmp/NAME-arg)
                            if test MODE = async; then
                                ( {
                                    printf 'call %s\0' "$input" | socat -t300 STDIO "UNIX-CONNECT:$sockfile" | kak -p "$kak_session"
                                } & ) >/dev/null 2>&1 </dev/null
                            else
                                printf 'call %s\0' "$input" | socat -t300 STDIO "UNIX-CONNECT:$sockfile" | cat
                            fi
                        fi
                    }
                }
             '''.replace('NAME', name)
                .replace('FILEPATH', filepath)
                .replace('MODE', mode)
            )

        elif sys.argv[1:2] == ['serve']:

            for old_sockfile in glob.glob(f'/tmp/{name}-*.sock'):
                print('sending to', old_sockfile)
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                try:
                    s.connect(old_sockfile)
                    s.send(b'\0')
                    s.close()
                except:
                    os.remove(old_sockfile)

            sockfile = sys.argv[2]
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.bind(sockfile)
            s.listen()
            while True:
                conn, addr = s.accept()
                chunks = []
                while True:
                    chunks += [conn.recv(4096)]
                    if b'\0' in chunks[-1]:
                        break
                msg = b''.join(chunks)
                if msg[-1:] == b'\0':
                    msg = msg[:-1]
                msg = msg.decode()
                args = shlex.split(msg)
                if not args:
                    print('empty message, shutting down...')
                    try:
                        conn.close()
                    except:
                        pass
                    os.remove(sockfile)
                    break
                elif args == ["init"]:
                    conn.sendall(quote('set', 'global', f'{name}_arg_string', arg_string).encode())
                    conn.close()
                elif args[0] == "call":
                    try:
                        res = f(*args[1:])
                        if isinstance(res, str):
                            reply = res
                        else:
                            reply = '\n'.join(res)
                        print('reply:', reply)
                    except:
                        import traceback as tb
                        import reprlib
                        tb.print_exc()
                        reply = '\n'.join((
                            # '%sh' + quote('printf nop; >&2 printf %s ' + shlex.quote(tb.format_exc())),
                            *(
                                quote('echo', '-debug', '--', l)
                                for l in ['<<<', *tb.format_exc().splitlines(), '>>>']
                            ),
                            quote('echo', '-debug', '--', reprlib.repr(args)),
                            quote('info', '--', tb.format_exc()) if mode == 'sync' else
                            'eval -client %sh{for client in $kak_client_list; do printf %s "$client"; exit; done} ' +
                                quote(quote('info', '--', tb.format_exc())),
                            quote('echo', '-markup', '--', '{Error}' + tb.format_exc().splitlines()[-1]),
                        ))
                    conn.sendall(reply.encode())
                    conn.close()
            else:
                print('bad message', msg)

        return f

    return serve_inner

