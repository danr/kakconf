set global startup_info_version 20301010

require-module x11

hook global BufCreate [^*].* %{
    nop %sh{
        echo "$kak_buffile" >> ~/.mru
    }
}

decl -hidden str source_dir %sh{dirname "$kak_source"}

def import -params 1 %{
    try %{
        source "~/code/kakconf/%arg{1}.kak"
    } catch %{
        echo -debug %val{error}
    }
}

import ../libpykak/fork
fork-shell eval '(
    cd "$kak_opt_source_dir"
    python -u main.py
)'

try %{
    source "~/code/kakconf/plugins/plug.kak/rc/plug.kak"
}
plug andreyorst/plug.kak noload

plug occivink/kakoune-vertical-selection
plug occivink/kakoune-find
plug occivink/kakoune-phantom-selection

map global normal f     ": phantom-selection-add-selection<ret>"
map global normal F     ": phantom-selection-select-all; phantom-selection-clear<ret>"
map global normal <a-f> ": phantom-selection-iterate-next<ret>"
map global normal <a-F> ": phantom-selection-iterate-prev<ret>"

# this would be nice, but currrently doesn't work
# see https://github.com/mawww/kakoune/issues/1916
#map global insert <a-f> "<a-;>: phantom-selection-iterate-next<ret>"
#map global insert <a-F> "<a-;>: phantom-selection-iterate-prev<ret>"
# so instead, have an approximate version that uses 'i'
map global insert <a-f> "<esc>: phantom-selection-iterate-next<ret>i"
map global insert <a-F> "<esc>: phantom-selection-iterate-prev<ret>i"

plug delapouite/kakoune-livedown
plug delapouite/kakoune-i3
plug delapouite/kakoune-buffers

# plug ul/kak-lsp do "cargo build --release --locked; cargo install --force --path ."
# set global lsp_cmd "kak-lsp -s %val{session}"
eval %sh{kak-lsp -s "$kak_session" --kakoune -c /home/dan/code/kakconf/kak-lsp.toml}

rmhl global/show-matching
plug laelath/kakoune-show-matching-insert config %{ addhl global/ ranges show_matching_insert }
addhl global/ show-matching

plug occivink/kakoune-interactive-itersel
plug occivink/kakoune-sudo-write

map -docstring 'lint'      global user e ': try lint-enable; lint<ret>'
map -docstring 'lint next' global user n ': try lint-enable; lint-next-message<ret>'
map -docstring 'lint prev' global user t ': try lint-enable; lint-previous-message<ret>'

def lsp-win %{
    lsp-enable-window
    lsp-diagnostic-lines-disable window
    lsp-inline-diagnostics-disable window
}

# plug occivink/kakoune-expand

import mark-show
mark-show-enable


import follow
import krc
import reload-kakrc
import one-char-replace
import selections
import z-submap
import fzf
import sneak
import base16base
import filer
import tab-at-word-end
import invert
import wip
import find-open
import modeline
import surround
# import jedi
# import parso
import modal

import jump

# import sel-editor

# import selundo
import zoom

import python
import wip2

# plug caksoylar/kakoune-smooth-scroll
# plug caksoylar/kakoune-focus
# plug JacobTravers/kakoune-grep-write
import grep-write

def focus-live-enable %{
    focus-selections
    hook -group focus window NormalIdle .* %{ focus-selections }
    hook -group focus window InsertIdle .* %{ focus-selections }
}
def focus-live-disable %{
    remove-hooks window focus
    focus-clear
}

def history %{
    edit -scratch *history*
    exec '%d'
    exec '":<a-R>a<ret><esc>'
    exec ged
}

# plug 'https://gitlab.com/kstr0k/fast-context.kak.git' demand fast-context

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

def arrange -params .. %{
    sh python -c %{if 1:
        import os, sys, shlex, json
        def quote(s): return "'" + s.replace("'", "''") + "'"
        env = os.environ.get
        args = sys.argv[1:]

        def main():
            buflist = shlex.split(env('kak_quoted_buflist'))
            buflist = [b for b in buflist if not '*' in b]
            bufname = env('kak_bufname')

            pos = {b: i for i, b in enumerate(buflist)}

            if args == ['up']:
                pos[bufname] -= 1.5
            if args == ['down']:
                pos[bufname] += 1.5

            buflist = [
                b for b, i in sorted(pos.items(), key=lambda bi: bi[1])
            ]

            lines = [
                ('>' if b == bufname else ' ') +
                ' ' + b
                for b in buflist
            ]

            print(json.dumps(locals(), indent=2), file=sys.stderr)
            print('info -- ' + quote('\n'.join(lines)))
            print('arrange-buffers', *map(quote, buflist))

        main()
    } %arg{@}
}

map global normal <a-lt> ': arrange up<ret>'
map global normal <a-gt> ': arrange down<ret>'

