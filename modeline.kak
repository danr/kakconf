
decl str modeline_info  ''

rmhooks global update-modeline
hook -group update-modeline global WinCreate .* %{
    hook -group update-modeline window WinDisplay .* %{try update_modeline_info}
    hook -group update-modeline window PromptIdle .* %{try update_modeline_info}
    hook -group update-modeline window InsertIdle .* %{try update_modeline_info}
    hook -group update-modeline window NormalIdle .* %{try update_modeline_info}
    hook -group update-modeline window NormalKey [jknJKN] %{try update_modeline_info}
}

def update_modeline_info %{
    set window modeline_info %sh{printf '%3d%% |' $((kak_buf_line_count > 1 ? 100 * ($kak_cursor_line - 1) / ($kak_buf_line_count - 1) : 0))}
}

set global modelinefmt %{
{{context_info}} | {{mode_info}} | %val{bufname} |
%val{cursor_line}:%val{cursor_char_column} |
%opt{modeline_info}
%val{session}}

