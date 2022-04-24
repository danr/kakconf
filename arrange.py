from libpykak import k, q

@k.cmd
def arrange(dir: str = ''):
    buflist = k.val.buflist
    modified = dict(k.eval_sync(
        'eval -buffer * ' + q(k.pk_send, '%val(bufname)', '%val(modified)')
    ))
    buflist = [b for b in buflist if not '*debug' in b]
    bufname = k.val.bufname

    pos = {b: float(i) for i, b in enumerate(buflist)}

    if dir == 'up':
        pos[bufname] -= 1.5
    if dir == 'down':
        pos[bufname] += 1.5
    if dir == 'top':
        pos[bufname] = -1
    if dir == 'bottom':
        pos[bufname] = len(buflist)

    buflist = [
        b for b, _i in sorted(pos.items(), key=lambda bi: bi[1])
    ]

    lines = [
        ('>' if b == bufname else ' ') +
        f' {i+1:2d} - {b}' +
        (' [+]' if modified[b] == 'true' else '')
        for i, b in enumerate(buflist)
    ]

    k.eval(
        q('info', '-title', f'{len(buflist)} buffers', '--', '\n'.join(lines)),
        q('arrange-buffers', *buflist),
    )

def init():
    k.eval('''
        map global normal <a-,> ': bp;arrange<ret>'
        map global normal <a-.> ': bn;arrange<ret>'
        map global normal <a-lt> ': arrange up<ret>'
        map global normal <a-gt> ': arrange down<ret>'
    ''')
