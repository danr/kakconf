from __future__ import annotations
from tree_sitter import Language, Parser
import re
from typing import Any
from dataclasses import dataclass, field
from typing import Iterator
import functools
from collections import Counter
from pprint import pp
import shlex

Language.build_library(
  # Store the library in the `build` directory
  './my-languages.so',
  # Include one or more languages
  [
    # 'tree-sitter-go',
    # 'tree-sitter-javascript',
    'tree-sitter-python'
  ]
)

# GO_LANGUAGE = Language('my-languages.so', 'go')
# JS_LANGUAGE = Language('my-languages.so', 'javascript')
PY_LANGUAGE = Language('./my-languages.so', 'python')

parser = Parser()
parser.set_language(PY_LANGUAGE)

@dataclass(frozen=False)
class Node:
    node: Any
    parent: Node | None = None
    children: list[Node] = field(default_factory=list)

    def ancestors(self) -> list[Node]:
        if self.parent:
            return [self, *self.parent.ancestors()]
        else:
            return [self]

    @property
    def b0(self) -> int:
        return self.node.start_byte + 1

    @property
    def b1(self) -> int:
        return self.node.end_byte

    @property
    def range(self) -> tuple[int, int]:
        return self.b0, self.b1

    @property
    def width(self) -> int:
        return self.b1 - self.b0 + 1

    def kak_coord(self) -> str:
        y0, x0 = [i+1 for i in self.node.start_point]
        y1, x1 = [i+1 for i in self.node.end_point]
        return f'{y0}.{x0},{y1}.{x1-1}'

    def contains(self, *byte_pos: int) -> bool:
        return all(
            self.b0 <= b <= self.b1
            for b in byte_pos
        )

    def siblings(self) -> NodeList:
        if self.parent:
            return NodeList(self.parent.children)
        else:
            return NodeList()

    def cousins_and_siblings(self) -> NodeList:
        if self.parent and self.parent.parent:
            return NodeList([
                cousin
                for uncle in self.parent.parent.children
                for cousin in uncle.children
            ])
        else:
            return self.siblings()

    def first_child(self) -> Node | None:
        if self.children:
            return self.children[0]
        else:
            return None

    def last_child(self) -> Node | None:
        if self.children:
            return self.children[-1]
        else:
            return None

    @property
    def text(self):
        return self.node.text.decode()

    @property
    def type(self):
        return shorten(self.node.type)

    def inorder(self) -> Iterator[Node]:
        for _i, node in self.inorder_with_depth():
            yield node

    def inorder_with_depth(self, depth: int=0) -> Iterator[tuple[int, Node]]:
        yield depth, self
        for child in self.children:
            yield from child.inorder_with_depth(depth+1)

class NodeList(list[Node]):
    def cursor(self, focus: Node, direction: int=1, cycle: bool=True) -> NodeList:
        for i, node in enumerate(self):
            if node is focus:
                if cycle:
                    return NodeList([self[(i + direction) % len(self)]])
                else:
                    try:
                        return NodeList([self[i + direction]])
                    except IndexError:
                        break
        return NodeList([])

    def children(self) -> NodeList:
        return NodeList(
            child
            for node in self
            for child in node.children
        )

    def children_at_pos(self, *pos: int) -> NodeList:
        return NodeList(
            child
            for node in self
            for i, child in enumerate(node.children)
            if i in pos
        )

    @staticmethod
    def make(*nodes: Node | None) -> NodeList:
        return NodeList([
            node
            for node in nodes
            if node
        ])

    def next(self, focus: Node, cycle: bool=True) -> NodeList:
        return self.cursor(focus, 1, cycle=cycle)

    def prev(self, focus: Node, cycle: bool=True) -> NodeList:
        return self.cursor(focus, -1, cycle=cycle)

    def prev_in(self, nodes: list[Node]) -> Node | None:
        for prev, node in zip(nodes, nodes[1:]):
            if node is self:
                return prev
        return None

    def select(self):
        return ' '.join(('select', *(node.kak_coord() for node in self)))

    def find_all(self, *byte_pos: int) -> NodeList:
        return NodeList(
            sorted(
                (
                    node
                    for node in self
                    if node.contains(*byte_pos)
                ),
                key=lambda node: -node.width
            )
        )

    def find(self, *byte_pos: int) -> Node | None:
        if all := self.find_all(*byte_pos):
            return all[-1]
        else:
            return None

    def collapse_same_range(self) -> NodeList:
        out = NodeList()
        seen = set[tuple[int, int]]()
        for node in self:
            if node.type == 'block':
                continue
            if node.range not in seen:
                seen.add(node.range)
                out += [node]
        return out

    def remove_nonalpha(self) -> NodeList:
        return NodeList(
            node
            for node in self
            if re.match(r'^\w+$', node.type)
        )

    def inplace_update_nodes(self) -> NodeList:
        here = set[int]()
        for node in self:
            here.add(id(node))
        for node in self:
            parent = node.parent
            while parent:
                if id(parent) in here:
                    node.parent = parent
                    break
                else:
                    parent = parent.parent
        for child in self:
            if child.parent:
                child.parent.children.append(child)
        return self

    @functools.lru_cache
    @staticmethod
    def parse(buf: str, filetype: str='python'):
        t: Any = parser.parse(buf.encode())     # type: ignore
        return NodeList.from_tree(t.root_node)

    @staticmethod
    def from_tree(tree: Any) -> NodeList:
        def go(node: Any, parent: Node | None = None) -> Iterator[Node]:
            this = Node(node, parent)
            yield this
            for c in node.children:
                yield from go(c, this)
        out = NodeList(go(tree))
        out = out.remove_nonalpha()
        # out = out.collapse_same_range()
        out.inplace_update_nodes()
        return out

from lxml import etree

def tree_to_xml(t: Any):
    def go(node: Any, parent: Any, field: None | str = None):
        attrib: dict[str, str] = {
            'start': str(node.start_byte),
            'end':   str(node.end_byte),
        }
        if field:
            attrib['field'] = field
        name = shorten(node.type)
        if name == 'comment':
            parent.append(etree.Comment(
                ' ' + node.text.decode().replace('--', '−−') + ' '
            ))
            return
        if not re.match(r'\w[\w\d_\-]*$', name):
            attrib['name'] = name
            name = 'delim'
        this = etree.SubElement(parent, name, **attrib)
        cursor = node.walk()
        cursor.goto_first_child()
        for child in node.children:
            field_name = cursor.current_field_name()
            go(child, this, field=field_name or None)
            cursor.goto_next_sibling()
        if not node.children:
            this.text = node.text.decode()
    root = etree.Element('root')
    go(t, root)
    return root

'''
ops:
    * select parent (for each selection, merging if needed)
    * select children (for each selection, makes a new selection at each child)
    * select prev/next in preorder traversal (optional: of same type, field: for field:type)
    * select first/last child
    * select prev/next sibling (optional: of same type, field: for field:type)
    * select all siblings (all cousins?) (optional: of same type, field: for field:type)
    * select prev/next leaf (?)
    * extend forward/backward
    * filter by type, field:, or field:type, or depth
        - of currently selected
        - of all subtrees (!?)
        - to keep or to remove
    * cycle through nodes starting (or ending) at cursor anchor/head

re of things to skip (their parent adopts their children):
    - block
    - expression_statement
    (maybe not in preorder traversal, just skip them if they have exactly the same range)

'''

def skip(s: str) -> bool:
    return s in '''
        block
        expression_statement
    '''.split()

@functools.lru_cache
def shorten(s: str) -> str:
    subst = {
        'class_definition': 'class',
        'function_definition': 'def',
        '_definition': '_def',
        'decorated_': '@',
        'statement': 'stmt',
        # '_statement': '',
        'expression': 'expr',
        'conditional_expr': 'if_expr',
        'dictionary': 'dict',
        '_comprehension': 'comp',
        'comprehension': 'comp',
        '_operator': 'op',
        'comparison': 'cmp',
        'boolean': 'bool',
        'binary': 'bin',
        'unary': 'un',
        'identifier': 'ident',
        'parameter': 'param',
        'separator': 'sep',
        'assignment': 'assign',
        'attribute': 'attr',
        'parenthesized': 'par',
        'argument': 'arg',
        '_specifier': '_spec',
        '_conversion': '_conv',
        '_': '-',
    }
    for k, v in subst.items():
        s = s.replace(k, v)
    return s

from typing import TypeVar, Callable
A = TypeVar('A')
def split_at(xs: list[A], p: Callable[[A], bool]) -> tuple[list[A], list[A]]:
    for i, x in enumerate(xs):
        if p(x):
            return xs[:i], xs[i:]
    return xs, []

def transpose(xs: list[str]) -> list[str]:
    return [''.join(t) for t in zip(*xs)]

def collapse_vertical_whitespace(canvas: list[str]) -> list[str]:
    cols = transpose(canvas)
    skip = {
        i
        for i, col in enumerate(cols[:-1])
        if col.isspace() and cols[i+1].isspace()
    }
    cols = [col for i, col in enumerate(cols) if i not in skip]
    return transpose(cols)

from libpykak import k, q

def init():
    k.eval('''
        try %(declare-user-mode tree)
        rmhooks global tree
        map global normal x ': enter_tree_mode<ret>'
    ''')

    def byte_offsets():
        [b1s], [b0s] = k.eval_sync(f'''
            eval -draft %(
                exec <a-:>
                {k.pk_send} %val(cursor_byte_offset)
                exec <a-semicolon>
                {k.pk_send} %val(cursor_byte_offset)
            )
        ''')
        b0 = int(b0s)+1
        b1 = int(b1s)+1
        return b0, b1

    @k.cmd
    def xml():
        buf = k.val.bufstr
        t: Any = parser.parse(buf.encode())     # type: ignore
        root = tree_to_xml(t.root_node)
        k.eval(q.debug(etree.tostring(root, pretty_print=True, encoding='unicode')))

    def tree_stuff():
        if k.opt.filetype != 'python':
            return None
        buf = k.val.bufstr
        b0, b1 = byte_offsets()
        node_list = NodeList.parse(buf)
        nodes = node_list.find_all(b0, b1)
        maps: dict[str, NodeList] = {}
        if nodes:
            this = nodes[-1]
            return this, node_list
        else:
            return None

    # @k.hook('NormalIdle', group='tree')
    def log_tree_stuff():
        ts = tree_stuff()
        if not ts:
            return
        this, node_list = ts
        nodes = this.ancestors()
        nodes, (stmt, *_) = split_at(nodes, lambda node: bool(re.search('stmt|def|class', node.type)))
        nodes = (nodes + [stmt])[::-1]
        root= nodes[0]
        b0, b1 = root.range
        d_max = 1 + max(d for d, _ in root.inorder_with_depth())
        canvas = [' ' * root.width for _ in range(d_max)]
        for d, t in root.inorder_with_depth():
            canvas[d] = canvas[d][:t.b0 - b0] + t.text.replace('\n', ' ') + canvas[d][t.b1 - b0 + 1:]
        canvas = collapse_vertical_whitespace(canvas)
        lines = ['...'] + [
            (
                f'[{node.type:<14}] {node.text.splitlines()[0]}'
                if node
                else '[...]'
            )
            for node in [
                *nodes,
                # None,
                # this.prev_in(node_list),
                # None,
                # *this.cousins_and_siblings(),
                # None,
                # this.next_in(node_list),
            ]
        ] + canvas
        k.eval(q.debug(*lines))

    def selected_nodes():
        ts = tree_stuff()
        if not ts:
            raise ValueError('no nodes!')
        _, node_list = ts
        b0, b1 = byte_offsets()
        node_list = NodeList([
            node
            for node in node_list
            if b0 <= node.b0 and node.b1 <= b1
        ])
        return node_list

    @k.cmd
    def leaves():
        node_list = selected_nodes()
        node_list = NodeList([
            node
            for node in node_list
            if not node.children
        ])
        k.eval(node_list.select())

    @k.cmd
    def pick_subtrees():
        on_revert_cmd = q('select', *map(str, k.val.selections_desc))
        node_list = selected_nodes()
        node_types = Counter(
            node.type
            for node in node_list
        )
        args: list[str] = []
        node_dict: dict[str, NodeList] = {}
        for type, count in node_types.most_common():
            node_dict[type] = NodeList(
                node
                for node in node_list
                if node.type == type
            )
        on_change_name = f'on_change_{k.unique()}'
        @k.command(hidden=True, name=on_change_name)
        def on_change():
            text = k.val.text
            head, _, rest = text.partition(' ')
            print(repr(text), head, rest.split())
            if nodes := node_dict.get(head):
                if rest == '.':
                    nodes = nodes.children()
                elif re.match(r'[\d\s]+$', rest):
                    pos = [int(x) - 1 for x in rest.split()]
                    print(pos)
                    nodes = nodes.children_at_pos(*pos)
                k.eval(nodes.select())
        cmd = q(
            'prompt',
            '-shell-script-candidates',
            'printf %s ' + shlex.quote('\n'.join(node_dict.keys())),
            '-on-change', on_change_name,
            '-on-abort', on_revert_cmd,
            'pick:',
            on_change_name
        )
        k.eval(cmd)

    @k.cmd
    def enter_tree_mode():
        ts = tree_stuff()
        if not ts:
            return
        this, node_list = ts
        maps: dict[str, NodeList] = {}
        nodes = this.ancestors()
        maps = {
            't': this.siblings().next(this),
            'n': this.siblings().prev(this),
            '<a-t>': this.cousins_and_siblings().next(this),
            '<a-n>': this.cousins_and_siblings().prev(this),
            'm': this.cousins_and_siblings(),
            'b': this.siblings(),
            'h': node_list.prev(this),
            's': node_list.next(this),
            'g': NodeList.make(this.parent),
            'c': NodeList.make(*this.children),
        }
        k.eval(
            *[
                'map window tree ' + q(k, f': {v.select()};enter_tree_mode<ret>')
                for k, v in maps.items()
            ],
            'enter-user-mode tree',
        )

# [[1, 2], [3, 4]]

if 0:
    def go(p, d=0, name=''):
        if re.match(r'^\w+$', p.type):
            print(f'[{p.type:<20} {name or "":>30}]', '  ' * d, '␤'.join(p.text.decode().splitlines()))
        cursor = p.walk()
        cursor.goto_first_child()
        for child in p.children:
            field_name = cursor.current_field_name()
            if field_name:
                field_name = p.type + '.' + field_name
            go(child, d=d+1, name=field_name or "")
            cursor.goto_next_sibling()

    if __name__ == '__main__':
        t = parser.parse(open(__file__, 'rb').read())
        go(t.root_node)

