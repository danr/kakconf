import jedi, os, sys, json, re, socky
from socky import quote

pipe_escape = lambda s: s.replace("|", "\\|")

@socky.serve('%val{buffile} %val{client} %val{timestamp} %val{cursor_line} %val{cursor_column} %val{window_height} %val{bufstr} %arg{@}', mode='async')
def jedi(buffile, client, timestamp, line, column, window_height, bufstr, *args):
    line   = int(line)
    column = int(column)
    window_height = int(window_height)
    cmds = []
    if args[0] == "complete":
        script = jedi.Script(code=bufstr, path=buffile)
        completions = (
            pipe_escape(c.name) +
            "|" + pipe_escape(quote("evaluate-commands", "jedi completion-info-request")) +
            "|" + pipe_escape(c.name)
            for c in script.complete(line=line, column=column-1)
        )
        header = str(line) + "." + str(column) + "@" + timestamp
        cmds += [
            quote("echo", "completed"),
            quote("set-option", "buffer=" + buffile, "jedi_completions", header, *completions),
        ]
    elif args[0] == "completion-info-request":
        script = jedi.Script(code=bufstr, path=buffile)
        names = script.goto(line=line, column=column-1)
        if names:
            import textwrap
            doc = names[0].docstring()
            doc = '\n\n'.join(
                textwrap.fill(par, subsequent_indent='' if i else '    ')
                if re.match('^.{80}', par) else par
                for i, par in enumerate(doc.split('\n\n'))
            )
            doc = '\n'.join(doc.splitlines()[:max(9, window_height - 9)])
        else:
            doc = ""
        cmds += ["info -- " + quote(doc)]
    elif args[0] == "info":
        script = jedi.Script(code=bufstr, path=buffile)
        names = script.goto(line=line, column=column-1)
        if names:
            cmds += ["info -- " + quote(names[0].docstring())]
        else:
            cmds += []
    elif args[0] == "goto":
        script = jedi.Script(code=bufstr, path=buffile)
        names = script.infer(line=line, column=column-1)
        if names:
            name = names[0]
            cmds += [quote("edit", str(name.module_path), str(name.line), str(name.column + 1))]
        else:
            cmds += ["info nope"]
    else:
        cmds += [quote("info", "--", "No command in:" + repr(args))]
    return quote("evaluate-commands", "-client", client, "\n".join(cmds))
