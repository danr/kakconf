declare-option int autowrap 80
def autowrap %{
    hook -group autowrap global InsertChar [^\n] %{
        eval -draft %{
            try %{
                exec <esc>
                exec \;<a-x>
                exec <a-k>.{ %opt{autowrap} }<ret>
                exec <a-k><space><ret>
                exec gh /.{ %opt{autowrap} }<ret> \;<a-/><space><ret>
                exec i<ret><esc>
            }
        }
	}
}
