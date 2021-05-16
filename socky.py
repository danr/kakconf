
import os, sys, glob, socket, shlex, re

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
                decl -hidden int NAME_seq_num
                try %{
                    nop %opt{NAME_arg_string}
                } catch %{
                    decl -hidden str NAME_arg_string ""
                }
                def NAME -override -params .. %{
                    set -add global NAME_seq_num 1
                    eval echo -quoting shell -to-file "/tmp/NAME.%val{session}.input.%opt{NAME_seq_num}" %opt{NAME_arg_string}
                    eval %sh{
                        mtime=$(stat -c %Y FILEPATH)
                        sockfile="/tmp/NAME.$kak_session.$mtime.sock"
                        sockglob="/tmp/NAME.$kak_session.*.sock"
                        logfile="/tmp/NAME.$kak_session.log"
                        if test ! -S "$sockfile"; then
                            ( {
                                python -u FILEPATH serve "$sockfile" "$sockglob" 2>&1 | tee -a "$logfile"
                            } & ) >/dev/null 2>&1 </dev/null
                            for i in {1..250}; do
                                sleep 0.01
                                if test -S "$sockfile"; then
                                    printf %s "spawn finished after $i rounds" >&2
                                    printf %s get_arg_string | socat STDIO "UNIX-CONNECT:$sockfile"
                                    printf %s "
                                        echo NAME ready
                                        tail $logfile
                                        NAME %arg{@}
                                    "
                                    exit
                                fi
                            done
                            printf %s "fail failed spawning NAME (FILEPATH)" >&2
                            printf %s "fail failed spawning NAME (FILEPATH)"
                        else
                            input="/tmp/NAME.$kak_session.input.$kak_opt_NAME_seq_num"
                            if test MODE = async; then
                                ( {
                                    printf %s "call $input" | socat -t300 STDIO "UNIX-CONNECT:$sockfile" | kak -p "$kak_session"
                                } & ) >/dev/null 2>&1 </dev/null
                            else
                                printf %s "call $input" | socat -t300 STDIO "UNIX-CONNECT:$sockfile"
                            fi
                        fi
                    }
                }
             '''.replace('NAME', name)
                .replace('FILEPATH', filepath)
                .replace('MODE', mode)
            )

        elif sys.argv[1:2] == ['serve']:
            sockfile = sys.argv[2]
            sockglob = sys.argv[3]

            for old_sockfile in glob.glob(sockglob):
                print('sending to', old_sockfile)
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                try:
                    s.connect(old_sockfile)
                    s.send(b'exit')
                    s.close()
                except:
                    os.remove(old_sockfile)

            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.bind(sockfile)
            s.listen()
            while True:
                conn, addr = s.accept()
                msg = conn.recv(1024).decode().split(' ')
                if not msg:
                    print('bad message', msg)
                    conn.close()
                    continue
                cmd = msg[0]
                if cmd == 'exit':
                    print('exit message, shutting down...')
                    try:
                        conn.close()
                    except:
                        pass
                    os.remove(sockfile)
                    break
                elif cmd == 'get_arg_string':
                    conn.sendall(quote('set', 'global', f'{name}_arg_string', arg_string).encode())
                    conn.close()
                elif cmd == 'call' and len(msg) == 2:
                    with open(msg[1]) as fp:
                        args = shlex.split(fp.read())
                    os.remove(msg[1])
                    try:
                        res = f(*args)
                        if isinstance(res, str):
                            reply = res
                        else:
                            reply = '\n'.join(res)
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
                    conn.close()

        return f

    return serve_inner

