declare-option -hidden range-specs mark_show_ranges
set-face global SavedMark default+u
define-command mark-show-update-ranges -hidden %{
    # Clear any previous highlighting converted from saved marks.
    evaluate-commands -buffer * unset-option buffer mark_show_ranges
    evaluate-commands %sh{
        kakquote() { printf %s "$*" | sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }
        # Extract the bufname and timestamp from the head element, if any.
        eval set -- "$kak_quoted_reg_caret"
        case "$1" in
            *@*@*)
                bufname=${1%%@*}
                tail=${1#*@}
                timestamp=${tail%%@*}
                ;;
            *)
                # This register does not appear to contain a mark, skip it.
                exit
                ;;
        esac
        shift
        # Use the selections to set mark_show_ranges in the target buffer
        printf 'eval -buffer %s set-option buffer mark_show_ranges %d' \
            "$(kakquote "$bufname")" \
            $timestamp
        for desc; do
             printf ' %s|SavedMark' $desc
        done
    }
}
define-command mark-show-enable \
    -docstring "Show the location of marks in the default mark register (^)" \
%{
    add-highlighter global/mark_show_ranges ranges mark_show_ranges
    hook global -group mark-show RegisterModified \^ mark-show-update-ranges
    mark-show-update-ranges
}
define-command mark-show-disable \
    -docstring "Hide the location of marks in the default mark register (^)" \
%{
    remove-hooks global mark-show
    evaluate-commands -buffer * unset-option buffer mark_show_ranges
    remove-highlighter global/mark_show_ranges
}
