import jedi, os, sys, json, re, socky
from socky import quote

pipe_escape = lambda s: s.replace("|", "\\|")

@socky.serve('%val{buffile} %val{client} %val{timestamp} %val{cursor_line} %val{cursor_column} %reg{b} %opt{jedi_info} %opt{jedi_last_name} %arg{@}', mode='async')
def jedi_impl(buffile, client, timestamp, line, column, code, info_str, last_name, *args):
    line   = int(line)
    column = int(column)
    if args[0] == "complete":
        script = jedi.Script(code=code, path=buffile)
        completions = (
            pipe_escape(c.name) + "|" +
            pipe_escape("evaluate-commands " + quote(
                "set-option buffer jedi_last_name " + quote(c.name) +
                ";" +
                "jedi completion-info-request " + quote(c.name)
            )) + "|" +
            pipe_escape(c.name)
            for c in script.complete(line=line, column=column-1)
        )
        header = str(line) + "." + str(column) + "@" + timestamp
        cmds = [
            quote("echo", "completed"),
            quote("set-option", "buffer=" + buffile, "jedi_info", "{}"),
            quote("set-option", "buffer=" + buffile, "jedi_last_name", ""),
            quote("set-option", "buffer=" + buffile, "jedi_completions", header, *completions),
        ]
    elif args[0] == "completion-info-request":
        name = args[1]
        cmds = []
        script = jedi.Script(code=code, path=buffile)
        names = script.goto(line=line, column=column-1)
        if names:
            import textwrap
            doc = "\n".join(names[0].docstring().splitlines()[:9])
        else:
            doc = ""
        cmds += ["info -- " + quote(doc)]
    elif args[0] == "info":
        script = jedi.Script(code=code, path=buffile)
        names = script.goto(line=line, column=column-1)
        if names:
            cmds = ["info -- " + quote(names[0].docstring())]
        else:
            cmds = []
    elif args[0] == "goto":
        script = jedi.Script(code=code, path=buffile)
        names = script.infer(line=line, column=column-1)
        if names:
            name = names[0]
            cmds = [quote("edit", str(name.module_path), str(name.line), str(name.column + 1))]
        else:
            cmds = ["info nope"]
    else:
        cmds = [quote("info", "--", "No command in:" + repr(args))]
    return quote("evaluate-commands", "-client", client, "\n".join(cmds))
