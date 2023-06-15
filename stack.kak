# example mappings to traverse search results:
# temporary dependency on kak-lsp for brevity
map global normal <c-n> %{:lsp-next-location %opt{locations_stack_top}<ret>}
map global normal <c-p> %{:lsp-previous-location %opt{locations_stack_top}<ret>}
map global normal <c-r> %{:locations-pop<ret>}

declare-option -hidden str-list locations_stack

declare-option -hidden str locations_stack_top
hook global GlobalSetOption locations_stack=.* %{
    set-option global locations_stack_top %sh{
        eval set -- $kak_quoted_opt_locations_stack
        for top; do :; done
        printf %s "$top"
    }
}

hook -group my global WinDisplay \*(?:callees|callers|diagnostics|goto|find|grep|implementations|lint-output|references|symbols)\*(?:-\d+)? %{
    locations-push
}

def locations-push -docstring "push a new locations buffer onto the stack" %{
    evaluate-commands %sh{
        eval set -- $kak_quoted_opt_locations_stack
        if printf '%s\n' "$@" | grep -Fxq -- "$kak_bufname"; then
            exit # already in the stack
        fi
        # rename to avoid conflict with *grep* etc.
        newname=$kak_bufname-$#
        echo "try %{ delete-buffer! $newname }"
        echo "rename-buffer $newname"
        echo "set-option -add global locations_stack %val{bufname}"
    }
    # set-option global my_grep_buffer %val{bufname}
}

def locations-pop -docstring "pop a locations buffer from the stack and return to previous location" %{
    evaluate-commands %sh{
        eval set -- $kak_quoted_opt_locations_stack
        if [ $# -lt 2 ]; then
g           echo "fail locations-pop: no grep buffer to pop"
            exit
        fi
        echo 'delete-buffer %opt{locations_stack_top}'
        echo 'set-option -remove global locations_stack %opt{locations_stack_top}'
    }
    try %{
        evaluate-commands -try-client %opt{jumpclient} %{
            buffer %opt{locations_stack_top}
            grep-jump
        }
    }
}

def locations-clear -docstring "delete locations buffers" %{
    evaluate-commands %sh{
        eval set --  $kak_quoted_opt_locations_stack
        printf 'try %%{ delete-buffer %s }\n' "$@"
    }
    set-option global locations_stack
}
