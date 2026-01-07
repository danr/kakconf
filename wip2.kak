# https://discuss.kakoune.com/t/restoring-selections-after-accidental-clear/1366

# Save selections to the [b]ackup register.
rmhooks global backup-selections
hook -group backup-selections global NormalIdle .* %{
  reg b %reg{z}
  exec -draft '"zZ'
}

# Add a mapping to easily reach the command.
map -docstring 'Restore selections from the [b]ackup register' global user z '"bz'

set global lsp_completion_trigger %{
    execute-keys 'H<a-h><a-k>(from \.?|import |\S\.|,\s*\w|\b\w\w)\z<ret>'
}

def prompt-fiddle %{
    prompt 'basename: ' %{
        fiddle %val{text}
    }
}

def fiddle -params 1 %{
    cd ~/code/fiddle
    edit "%arg{1}.py"
    write!
    connect-shell kitty vire -cr "%arg{1}.py"
}

try %{
    eval %sh{kak-popup init}
}

def complete %{
    eval -draft %{
        exec <a-?>\n\n\K\S<ret>
        echo -to-file /home/dan/request.txt %val{selection}
    }
}
map global jump o ': complete<ret>'


def claude -params .. %{
    connect-terminal restrict.py claude "File: %val{buffile}
Selection line and columns: %val{selection_desc}
Selection content: %val{selection}
%arg{@}"
}

alias global cc claude

def claude-with-clipboard -params .. %{
    connect-terminal restrict.py claude "File: %val{buffile}
Selection line and columns: %val{selection_desc}
Selection content: ```
%val{selection}
```
Clipboard content: ```
%sh{xclip -o}
```
%arg{@}"
}

alias global cb claude-with-clipboard

def claude-yolo -params .. %{
    connect-terminal restrict.py claude --dangerously-skip-permissions "File: %val{buffile}
Selection line and columns: %val{selection_desc}
Selection content: %val{selection}
%arg{@}"
}

alias global cy claude-yolo

def claude-with-clipboard-yolo -params .. %{
    connect-terminal restrict.py claude --dangerously-skip-permissions "File: %val{buffile}
Selection line and columns: %val{selection_desc}
Selection content: ```
%val{selection}
```
Clipboard content: ```
%sh{xclip -o}
```
%arg{@}"
}

alias global cby claude-with-clipboard-yolo
