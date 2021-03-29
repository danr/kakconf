
def chargrab-init %{
    eval %sh{ python /home/dan/code/chargrab/chargrab.py init }
}

def neptyne-init %{
    try %{ eval %sh{ neptyne kak_source } }
    # map global user n ': neptyne<ret>'
}

# declare-user-mode buffers
# def info-buffers ''

# def start-ghci-bridge -params 0..1 -docstring '
#     start-ghci-bridge [GHCI_CMD]
#
#     Starts the bridge.py using the GHCI_CMD, default "make ghci"
# ' %{
#     %sh{
#         dir=$PWD
#         cd ~/code/kakoune-ghci-bridge
#         (
#             python bridge.py "$kak_session" "$dir" "${1:-make ghci}"
#         ) > /dev/null 2>&1 < /dev/null &
#     }
# }

# def on-one-line -params 1 %{
#   eval -no-hooks %{
#     try %{
#       exec -save-regs '' Z %arg{1} <a-K>\n<ret>
#     } catch %{
#       exec z
#     }
#   }
# }

# set global expand_commands %{
#     expand-impl 'on-one-line <a-i>q'                     # quotes on the same line
#     expand-impl 'on-one-line <a-i>Q'                     # quotes on the same line
#     expand-impl 'on-one-line <a-a>q'                     # quotes on the same line
#     expand-impl 'on-one-line <a-a>Q'                     # quotes on the same line
#     expand-impl 'exec <a-i>b'                            # parentheses
#     expand-impl 'exec <a-i>B'                            # braces
#     expand-impl 'exec <a-i>r'                            # brackets
#     expand-impl 'exec <a-i>a'                            # <>
#     expand-impl 'exec <a-a>b'                            # parentheses
#     expand-impl 'exec <a-a>B'                            # braces
#     expand-impl 'exec <a-a>r'                            # brackets
#     expand-impl 'exec <a-a>a'                            # <>
#     expand-impl 'exec <a-i>i'                            # indent
#     expand-impl 'exec \'<a-:><a-;>k<a-K>^$<ret><a-i>i\'' # next ident level (upward)
#     expand-impl 'exec \'<a-:>j<a-K>^$<ret><a-i>i\''      # next ident level (downward)
#     expand-impl 'select-indented-paragraph'              # paragraph with the same indent
# }

# snippets
# import snippets

# hook -group kakrc global WinSetOption filetype=haskell %{
    # set window snippets %{
        # fc <esc>dZ<a-/>^module<ret>O{-# Language FlexibleContexts #-}<esc>zi
        # fi <esc>dZ<a-/>^module<ret>O{-# Language FlexibleInstances #-}<esc>zi
        # tsi <esc>dZ<a-/>^module<ret>O{-# Language TypeSynonymInstances #-}<esc>zi
        # vp <esc>dZ<a-/>^module<ret>O{-# Language ViewPatterns #-}<esc>zi
        # pg <esc>dZ<a-/>^module<ret>O{-# Language PatternGuards #-}<esc>zi
        # nfp <esc>dZ<a-/>^module<ret>O{-# Language NamedFieldPuns #-}<esc>zi
        # rwc <esc>dZ<a-/>^module<ret>O{-# Language RecordWildCards #-}<esc>zi
        # gnd <esc>dZ<a-/>^module<ret>O{-# Language GeneralizedNewtypeDeriving #-}<esc>zi
        # tos <esc>dZ<a-/>^module<ret>O{-# Language TypeOperators #-}<esc>zi
        # lc <esc>dZ<a-/>^module<ret>O{-# Language LambdaCase #-}<esc>zi
        # th <esc>dZ<a-/>^module<ret>O{-# Language TemplateHaskell #-}<esc>zi
        # mptc <esc>dZ<a-/>^module<ret>O{-# Language MultiParamTypeClasses #-}<esc>zi
        # os <esc>dZ<a-/>^module<ret>O{-# Language OverloadedStrings #-}<esc>zi
        # icm <esc>dZ<a-/>^import<ret>oimport Control.Monad<esc>zi
        # imr <esc>dZ<a-/>^import<ret>oimport Control.Monad.Reader<esc>zi
        # ims <esc>dZ<a-/>^import<ret>oimport Control.Monad.State<esc>zi
        # imw <esc>dZ<a-/>^import<ret>oimport Control.Monad.Writer<esc>zi
        # imc <esc>dZ<a-/>^import<ret>oimport Control.Monad.Cont<esc>zi
        # imb <esc>dZ<a-/>^import<ret>oimport Data.Maybe<esc>zi
        # idl <esc>dZ<a-/>^import<ret>oimport Data.List<esc>zi
        # idc <esc>dZ<a-/>^import<ret>oimport Data.Char<esc>zi
        # ips <esc>dZ<a-/>^import<ret>oimport Text.Show.Pretty<esc>zi
        # ipp <esc>dZ<a-/>^import<ret>oimport Text.PrettyPrint<esc>zi
        # idm <esc>dZ<a-/>^import<ret>oimport Data.Map (Map)<ret>import qualified Data.Map as M<esc>zi
        # ids <esc>dZ<a-/>^import<ret>oimport Data.Set (Set)<ret>import qualified Data.Set as S<esc>zi
        # deq <space><space>deriving (Eq, Ord, Show)
    # }
# }

# hook -group kakrc global WinSetOption filetype=kak %{
    # set window snippets %{
        # mgn map global normal
        # mgu map global user
        # hg hook -group kakrc global
    # }
# }

def div -params 0..1 -docstring %{Wraps selected text with a tag and indents it.

The parameter can be omitted and then defaults to div.} %{
    eval -itersel %{
        exec <a-:><a-x>H Zo< / %sh{[ -n "$1" ] && echo "$1" || echo "div"} ><esc><a-x>yz<A-P>s/<ret>dz>
    }
}

def select-indent -docstring %{Select to the same indentation level, upwards} %{
    eval -itersel %{
        exec glh<a-/>^(\h*)<ret><a-?>^<c-r>1\H<ret><a-x><a-:>
    }
}
alias global si select-indent

def select-tag -docstring %{Selects xml tag from start to end.

Assumptions:

- Start tag begins on an own line
- Closing tag has the same indentation as start tag or tag is self-closing} %{
    eval -itersel %{
        try %{
            exec <a-/> ^(\h*) <([\w.]+) <ret> ?<c-r>1 < / <c-r>2 ><ret>
        } catch %{
            exec ? /> <ret>
        }
    }
}
alias global st select-tag

def jsautoeval %{
    hook -group aur buffer BufWritePost .*[jt]sx? %{
        exec -draft \%"cy
        info -title jseval "%reg{c}"
    }
}

def mdn %{
    eval -draft %{
        exec <space>lbhe*
        spawn qutebrowser "https://developer.mozilla.org/en-US/docs/Web/API/%val{selection}"
    }
}

def mdn_search %{
    eval -draft %{
        exec <space>lbhe*
        spawn qutebrowser "'%val{selection} !mdn'"
    }
}

def connect-nnn %{
    connect-terminal sh -c '(NNN_OPENER=edit nnn; NNN_OPENER=edit bash)'

}
map global user n ': connect-nnn<ret>'

