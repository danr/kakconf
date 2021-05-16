from __future__ import annotations

from datetime import datetime, timedelta
from contextlib import contextmanager
import sys

@contextmanager
def time(what: str):
    start_time = datetime.now()
    yield
    stop_time = datetime.now()
    duration=round((stop_time - start_time).total_seconds(), 3)
    print(duration, what, file=sys.stderr)

from tabulate import tabulate
import os
import re
from dataclasses import *
from typing import *
import parso
from pprint import pprint

def uid(thing: Any, mem={None: -1, False: 0, True: 1}) -> int:
    addr = id(thing)
    if addr not in mem:
        mem[addr] = len(mem)
    return mem[addr]

def shorten(s: str, N=80) -> str:
    if len(s) >= N:
        return s[:N//2-10] + ' ... ' + s[-N//2:]
    return s

def skip(node: Node) -> bool:
    if node.type in 'newline endmarker operator'.split():
        return True
    if node.type == 'keyword':
        code = node.get_code(include_prefix=False)
        return code not in '... None True False'.split()
    return False

Node = parso.tree.BaseNode
Pos = Tuple[int, int]

@dataclass(frozen=True)
class Row:
    node: Node
    tags: list[str]
    parents: list[Node]

    def parent(self, index: int) -> Node | None:
        try:
            return self.parents[index]
        except IndexError:
            return None

    def starts_before(self: Row, pos: Pos) -> bool:
        '''(inclusive)'''
        start_line, start_col = self.node.start_pos
        line, col = pos
        return (
            start_line < line or
            (start_line == line and start_col <= col)
        )

    def ends_after(self: Row, pos: Pos) -> bool:
        '''(inclusive)'''
        end_line, end_col = self.node.end_pos
        line, col = pos
        return (
            end_line > line or
            (end_line == line and end_col >= col)
        )

    def contains(self: Row, *pos: Pos) -> bool:
        '''(inclusive)'''
        return all(self.starts_before(p) and self.ends_after(p) for p in pos)


def siblings(r1: Row, r2: Row):
    return r1.parent(-1) is r2.parent(-1)

def cousins(r1: Row, r2: Row):
    return r1.parent(-2) is r2.parent(-2)

def cols(row: Row) -> list[Any]:
    node = row.node
    code = node.get_code(include_prefix=False)
    return [
        shorten('.'.join(row.tags), 75),
        node.type,
        uid(row.parent(-2)),
        uid(row.parent(-1)),
        uid(node),
        node.start_pos[0],
        # node.end_pos[0],
        shorten(code.replace('\n', '␤'), 37),
    ]

def go(node, tags=[], parents=[]) -> Iterator[Row]:
    if skip(node):
        return

    yield Row(node, tags, parents)

    if isinstance(node, Node):
        for tag, c in flat_children(node):
            yield from go(c, tags=tags + [tag], parents=parents + [node])

def flat_children(node: Node) -> list[Tuple[str, Node]]:
    if node.type == 'atom_expr':
        parts = []
        for c in node.children:
            if c.type == 'trailer':
                part = []
                is_function_call = len(c.children) and (c.children[0] == '(' or c.children[0].type == 'argument')
                i = 0
                for tc in c.children:
                    if skip(tc):
                        continue
                    if tc.type == 'arglist':
                        prev = None
                        for arg in tc.children:
                            if prev and arg.start_pos[0] != prev.start_pos[0]:
                                i = 0
                            prev = arg
                            if skip(arg):
                                continue
                            if arg.type == 'argument' and len(arg.children) > 1:
                                x1, x2, *xs = arg.children
                                if x1 == '*':
                                    part += [('args', x2)]
                                    continue
                                if x1 == '**':
                                    part += [('kws', x2)]
                                    continue
                                if x1.type == 'name' and x2 == '=' and len(xs) == 1:
                                    kw = x1.get_code(include_prefix=False)
                                    part += [('kw_' + kw, xs[0])]
                                    continue
                            i += 1
                            part += [(f'arg{i}⮓', arg)]
                    elif c.children[0] == '(':
                        i += 1
                        part += [(f'arg{i}⮓', tc)]
                    elif c.children[0] == '[':
                        part += [('sub', tc)]
                    elif c.children[0] == '.':
                        part += [('attr', tc)]
                    else:
                        part += [(tc.type, tc)]
                parts += [part]
            else:
                parts += [[('head', c)]]
        return [
            (f'call({i},{j})', c)
            for i, part in enumerate(parts)
            for j, c in part
            if not skip(c)
        ]
    else:
        out = []
        i = 0
        prev = None
        for c in node.children:
            if skip(c):
                continue
            if prev and c.start_pos[0] != prev.start_pos[0]:
                i = 0
            prev = c
            i += 1
            out += [(f'{node.type}{i}⮓', c)]
        return out

def test():
    m = parso.parse(open(__file__, 'r').read())
    r = list(map(cols, go(m)))
    print(tabulate(r, tablefmt='plain'))
    # print(tabulate(sorted(r), tablefmt='plain'))

def quote(*args):
    c = "'"
    return " ".join(
        s if re.match("[\w-]+$", s) else c + s.replace(c, c+c) + c
        for s in args
    )

from functools import lru_cache

@lru_cache
def buf_to_rows(buf):
    with time('parse'):
        m = parso.parse(buf)
    with time('rows'):
        rows = list(go(m))
    return rows

def sel(node):
    line1, col1 = node.start_pos
    line2, col2 = node.end_pos
    if col2 == 0:
        col2 = 1
    return f'select {line1}.{col1+1},{line2}.{col2}'

import socky

@socky.serve('%val{selection_desc} %val{bufstr} %arg{@}')
def parso(desc, buf, arg1, *args):
    coords = [
        [ int(c) - i for i, c in enumerate(p.split('.')) ]
        for p in desc.split(',')
    ]
    (line1, col1), (line2, col2) = coords
    rows = buf_to_rows(buf)
    for i, row in enumerate(rows):
        if row.contains(*coords):
            cursor = row
            ci = i
    if arg1 == "info":
        info = (
            [
                ['self', i, row.node.get_code(False)]
                for i, row in enumerate(rows)
                if cursor is row
            ] + [
                ['same_kind', i, row.node.get_code(False)]
                for i, row in enumerate(rows)
                if cursor.tags == row.tags and cursor is not row
            ] + [
                ['cousins  ', i, row.node.get_code(False)]
                for i, row in enumerate(rows)
                if cousins(row, cursor) and cursor is not row
            ] + [
                ['parents  ', i, row.node.get_code(False)]
                for i, row in enumerate(rows)
                if row.node == cursor.parent(-1)
            ] + [
                ['children ', i, row.node.get_code(False)]
                for i, row in enumerate(rows)
                if row.parent(-1) == cursor.node
            ]
        )
        yield quote('info', '--', tabulate(info, tablefmt='plain'))
    elif arg1 == "next-node":
        yield sel(rows[ci+1].node)
    elif arg1 == "prev-node":
        yield sel(rows[ci-1].node)
    elif arg1 == "next-at-level":
        for row in rows[ci+1:]:
            if len(row.tags) == len(cursor.tags):
                yield sel(row.node)
                break
    elif arg1 == "prev-at-level":
        for row in reversed(rows[:ci]):
            if len(row.tags) == len(cursor.tags):
                yield sel(row.node)
                break
    elif arg1 == "next-leaf":
        for row in rows[ci+1:]:
            if isinstance(row.node, parso.tree.Leaf):
                yield sel(row.node)
                break
    elif arg1 == "prev-leaf":
        for row in reversed(rows[:ci]):
            if isinstance(row.node, parso.tree.Leaf):
                yield sel(row.node)
                break
    elif arg1 == "next-of-kind":
        for row in rows[ci+1:]:
            if row.tags == cursor.tags:
                yield sel(row.node)
                break
    elif arg1 == "prev-of-kind":
        for row in reversed(rows[:ci]):
            if row.tags == cursor.tags:
                yield sel(row.node)
                break
    elif arg1 == "parent":
        for row in rows:
            if row.node is cursor.parent(-1):
                yield sel(row.node)
                break
    elif arg1 == "first-child":
        for row in rows:
            if row.parent(-1) is cursor.node:
                yield sel(row.node)
                break
    elif arg1 == "last-child":
        for row in reversed(rows):
            if row.parent(-1) is cursor.node:
                yield sel(row.node)
                break
    else:
        raise ValueError(f'no such command: {arg1}')

if __name__ == '__main__':
    if sys.argv[1:2] == ["test"]:
        test()

