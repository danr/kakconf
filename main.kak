set global startup_info_version 20301010

hook global BufCreate [^*].* %{
    %sh{
        echo "$kak_buffile" >> ~/.mru
    }
}

eval %sh{krc kak-defs}
alias global t connect-terminal

try %{
    source "~/code/kakconf/plugins/plug.kak/rc/plug.kak"
}
plug andreyorst/plug.kak noload
# plug andreyorst/fzf.kak
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
plug ul/kak-lsp do "cargo build --release --locked; cargo install --force --path ."
set global lsp_cmd "kak-lsp -s %val{session} -c %val{config}/plugins/kak-lsp/kak-lsp.toml"

# plug alexherbo2/connect.kak
# plug alexherbo2/explore.kak

plug laelath/kakoune-show-matching-insert config %{ addhl global/ ranges show_matching_insert }
addhl global/ show-matching

plug occivink/kakoune-interactive-itersel
plug occivink/kakoune-sudo-write

# plug occivink/kakoune-number-comparison

map global user n ': connect-nnn<ret>'

def lint-enabled %{
    try %{
        lint-enable
    }
}

map global user e ': lint-enabled; lint<ret>'
map global user n ': lint-enabled; lint-next-error<ret>'
map global user t ': lint-enabled; lint-previous-error<ret>'

def lsp-win %{
    lsp-enable-window
    lsp-diagnostic-lines-disable window
    lsp-inline-diagnostics-disable window
}

# plug occivink/kakoune-gdb
# plug occivink/kakoune-expand
# # plug danr/kakoune-easymotion
# # plug fsub/kakoune-mark

# plug alexherbo2/move-line.kak rc/
#


def import -params 1 %{
    try %{
        source %sh{echo ~/code/kakconf/$1.kak}
    }
}

import find-open
import commas
import github
import marks-submap
import one-char-replace
import reload-kakrc
import selections
import z-submap
import wip

