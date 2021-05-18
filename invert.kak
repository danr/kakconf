
def invert -docstring "select everything that isn't selected" %{
    eval -save-regs slrb %{
        exec -draft -save-regs '' '<a-:>"sZ'
        exec -draft -save-regs '' '<a-:><a-;>h"lZ'
        exec -draft -save-regs '' '<a-:>l"rZ'
        exec -draft -save-regs '' '%"bZ'
        eval %sh{
            python -c 'if 1:
                import os
                def parse(s):
                    _, *coords = s.split()
                    return [c.split(",") for c in coords]
                selection=parse(os.environ["kak_reg_s"])
                left=parse(os.environ["kak_reg_l"])
                right=parse(os.environ["kak_reg_r"])
                [[begin, end]]=parse(os.environ["kak_reg_b"])
                selection={p for ps in selection for p in ps}
                right=[p[1] for p in right]
                left=[p[0] for p in left]
                pairs=[[begin,left[0]], *zip(right,left[1:]), [right[-1], end]]
                pairs=[",".join(pair) for pair in pairs if selection.isdisjoint(pair)]
                print("select", *pairs)
            '
        }
    }
}

try %{ declare-user-mode sels }

map -docstring sels global user s ': enter-user-mode sels<ret>'

map -docstring 'reg^ := sels         (p)ut       ' global sels p Z
map -docstring 'sels := reg^         (g)et       ' global sels g z
map -docstring 'sels := sels ∪ reg^  (u)nion     ' global sels u <a-z>a
map -docstring 'sels := sels ∩ reg^  i(n)tersect ' global sels n ': invert<ret>"sZz: invert<ret>"s<a-z>a: invert<ret>'
map -docstring 'sels := sels − reg^  (d)ifference' global sels d ': invert<ret>"sZz"s<a-z>a: invert<ret>'
map -docstring 'sels := ∁ sels       inve(r)t    ' global sels r ': invert<ret>'
