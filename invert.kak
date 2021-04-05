def invert %{
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
