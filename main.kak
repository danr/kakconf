set global startup_info_version 20301010

evaluate-commands %sh{
    if [ -n "$DISPLAY" ]; then
        echo 'require-module x11'
        echo 'echo -debug "x11: loaded"'
    else
        echo 'echo -debug "x11: skipping (no DISPLAY)"'
    fi
}

# Clipboard backend: wl-clipboard under wayland (niri), xclip/xsel under X11.
# Resolved once from the server's environment.
decl -hidden str clipboard_paste
decl -hidden str clipboard_copy_primary
decl -hidden str clipboard_copy_clipboard
eval %sh{
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-paste > /dev/null 2>&1; then
        echo 'set global clipboard_paste %{wl-paste --no-newline}'
        echo 'set global clipboard_copy_primary %{wl-copy --primary}'
        echo 'set global clipboard_copy_clipboard %{wl-copy}'
        echo 'echo -debug "clipboard: wl-clipboard"'
    else
        echo 'set global clipboard_paste %{xclip -o}'
        echo 'set global clipboard_copy_primary %{xsel --input --primary}'
        echo 'set global clipboard_copy_clipboard %{xsel --input --clipboard}'
        echo 'echo -debug "clipboard: xclip/xsel"'
    fi
}

hook global BufCreate [^*].* %{
    nop %sh{
        echo "$kak_buffile" >> ~/.mru
    }
}

decl -hidden str source_dir %sh{dirname "$kak_source"}

def import -params 1 %{
    try %{
        source "%opt{source_dir}/%arg{1}.kak"
    } catch %{
        echo -debug %val{error}
    }
}

nop %sh{
    # kak_session
    cd "$kak_opt_source_dir"
    (
        kakquote() { printf "%s" "$*" | sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }

        logfile="/tmp/pykak-$kak_session.log"
        rm -f "$logfile"
        touch "$logfile"
        trap "rm -rf $logfile" EXIT

        PYTHONUNBUFFERED=x uv run --with ../libpykak,typing_extensions --reinstall python -m main |& tee -a "$logfile" &

        tail -f "$logfile" | while IFS=$'\n' read line; do
            printf '%s\n' "echo -debug -- $(kakquote "$line")" | kak -p "$kak_session"
        done &
    ) > /dev/null 2>&1 </dev/null &
}

try %{
    source "~/code/kakconf/plugins/plug.kak/rc/plug.kak"
}
plug andreyorst/plug.kak noload

plug occivink/kakoune-vertical-selection
plug occivink/kakoune-find
plug occivink/kakoune-phantom-selection

map global normal , <space>

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
# plug delapouite/kakoune-buffers

eval %sh{kak-lsp -s "$kak_session" --kakoune}
set global lsp_timeout 0

remove-hooks global lsp-filetype-python
hook -group lsp-filetype-python global BufSetOption filetype=python %{
    set-option buffer lsp_servers %{
        [basedpyright]
        root_globs = ["pyrightconfig.json", "pyproject.toml", "setup.py", ".git", ".hg"]
        command = "uvx"
        args = ["--from", "basedpyright", "basedpyright-langserver", "--stdio"]
    }
}

hook global -group kakrc WinSetOption filetype=python lsp-setup

# hook global -group kakrc WinSetOption filetype=go lsp-setup

def lsp-setup %{
    # lsp-auto-hover-enable
    map -docstring 'lsp toggle auto-hover' window user H ': toggle window lsp-auto-hover-enable lsp-auto-hover-disable<ret>'
    map -docstring 'lsp mode'    window user l ': enter-user-mode lsp<ret>'
    map -docstring 'lsp hover'   window user h ': lsp-hover<ret>'
    map -docstring 'lsp goto'    window user . ': lsp-definition<ret>'
    map -docstring 'lsp prev'    window user n ': lsp-find-error --previous<ret>: lsp-hover<ret>'
    map -docstring 'lsp next'    window user t ': lsp-find-error<ret>: lsp-hover<ret>'
    lsp-enable-window
}



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


import krc
import reload-kakrc
import one-char-replace
import selections
import z-submap
import fzf
import base16base
import tab-at-word-end
import wip
import find-open
import modeline
import surround
import modal

import jump

# import selundo
import zoom

import wip2

# import ./kakoune-rectangles/kakoune-rectangles
# import ./scrollbar.kak/scrollbar
# hook global WinCreate .* %{ scrollbar-enable }

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

