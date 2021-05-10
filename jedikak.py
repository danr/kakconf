import os, sys, json, re
buffile = os.environ["kak_buffile"]
code = os.environ["kak_reg_b"]
line = int(os.environ["kak_cursor_line"])
column = int(os.environ["kak_cursor_column"])
timestamp = os.environ["kak_timestamp"]
client = os.environ["kak_client"]
pipe_escape = lambda s: s.replace("|", "\\|")
def quote(*args):
    c = "'"
    return " ".join(
        s if re.match("[\w-]+$", s) else c + s.replace(c, c+c) + c
        for s in args
    )
import jedi
if sys.argv[1] == "complete":
    script = jedi.Script(code=code, path=buffile)
    completions = (
        pipe_escape(c.name) + "|" +
        pipe_escape("evaluate-commands " + quote(
            "set-option buffer jedi_last_name " + quote(c.name) +
            ";" +
            "jedi-impl completion-info request " + quote(c.name)
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
elif sys.argv[1] == "completion-info":
    last_name = os.environ["kak_opt_jedi_last_name"]
    info_str = os.environ["kak_opt_jedi_info"]
    subcommand = sys.argv[2]
    name = sys.argv[3]
    try:
        info = json.loads(info_str)
    except:
        info = {}
    cmds = []
    if subcommand == "result":
        buffile = sys.argv[4]
        info[name] = sys.argv[5]
        cmds += [
            quote("set-option", "buffer=" + buffile, "jedi_info", json.dumps(info)),
            quote("echo", "-debug", "added", name, "among", *info.keys()),
        ]
    if last_name == name and name in info:
        cmds += ["info -- " + quote(info[name])]
    if subcommand == "request" and name not in info:
        script = jedi.Script(code=code, path=buffile)
        names = script.goto(line=line, column=column-1)
        if names:
            import textwrap
            doc = "\n".join(names[0].docstring().splitlines()[:9])
        else:
            doc = ""
        cmds = [
            quote("jedi-impl", "completion-info", "result", name, buffile, doc)
        ]
elif sys.argv[1] == "info":
    script = jedi.Script(code=code, path=buffile)
    names = script.goto(line=line, column=column-1)
    if names:
        cmds = ["info -- " + quote(names[0].docstring())]
    else:
        cmds = []
elif sys.argv[1] == "goto":
    script = jedi.Script(code=code, path=buffile)
    names = script.infer(line=line, column=column-1)
    if names:
        name = names[0]
        cmds = [quote("edit", str(name.module_path), str(name.line), str(name.column + 1))]
    else:
        cmds = ["info nope"]
else:
    cmds = [quote("info", "--", "No command in:" + repr(sys.argv))]
print(quote("evaluate-commands", "-client", client, "\n".join(cmds)))
