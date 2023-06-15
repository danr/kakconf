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

from lxml import etree

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
        - of currently container
        - of all subtrees (!?)
        - to keep or to remove
    * cycle through nodes starting (or ending) at cursor anchor/head

re of things to skip (their parent adopts their children):
    - block
    - expression_statement
    (maybe not in preorder traversal, just skip them if they have exactly the same range)

'''

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

def etree_named_children(node: Any) -> list[tuple[str | None, Any]]:
    out: list[tuple[str | None, Any]] = []
    cursor = node.walk()
    cursor.goto_first_child()
    for child in node.children:
        field_name = cursor.current_field_name()
        out += [(field_name, child)]
        cursor.goto_next_sibling()
    return out

@dataclass(frozen=False)
class Node:
    node: Any

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

    '''

       [ node ]     wider       focus="contains"   .//*[@container]
        [node]      exact       focus="exact"      not(ancestor::@focus)
        no[d]e      inside      focus="partial"
        no[de  ]    partial
      [ n]od[e ]    ?partial
        node []     outside

    '''

    def included(self, *byte_pos: int) -> bool:
        return all(
            self.b0 <= b <= self.b1
            for b in byte_pos
        )

    def container(self, *byte_pos: int) -> bool:
        '''
        .....WORD....
        ..[   ]......
        .......[   ].
        ...[       ].
        ......[ ]....
        not (r < b0 or l > b1) =
        not (r < b0) and not (l > b1) =
        r >= b0 and l <= b1
        '''
        b0, b1 = min(self.range), max(self.range)
        l, r = min(byte_pos), max(byte_pos)
        return b0 <= l and r <= b1

    def selection(self, *byte_pos: int) -> bool:
        b0, b1 = min(self.range), max(self.range)
        l, r = min(byte_pos), max(byte_pos)
        return b0 == l and r == b1

@dataclass(frozen=True)
class XML:
    root: Any

    @staticmethod
    def parse(buf: str, *byte_pos: int) -> XML:
        t: Any = parser.parse(buf.encode())     # type: ignore
        return XML.from_tree(t.root_node, *byte_pos)

    @staticmethod
    def from_tree(t: Any, *byte_pos: int) -> XML:
        def go(node: Any, parent: Any, field_name: str | None = None):
            node_type = shorten(node.type)
            if not re.match(r'[\w_][\w\d_\-]*$', node_type):
                node_type = 'delim'
            attrib: dict[str, str] = {
                'text': node.text.decode(),
                'desc': str(Node(node).kak_coord()),
            }
            if Node(node).container(*byte_pos):
                attrib['container'] = 'true'
            if Node(node).selection(*byte_pos):
                attrib['selection'] = 'true'
            if field_name:
                # attrib['field'] = shorten(field_name)
                attrib[shorten(field_name)] = "field"
            if 0 and node.type == 'comment':
                parent.append(etree.Comment(
                    ' ' + node.text.decode().replace('--', '−−') + ' '
                ))
                return
            name = node_type # 'nt' if node.children else 't'
            this = etree.SubElement(parent, node_type, **attrib)
            for field_name, child in etree_named_children(node):
                go(child, this, field_name)
            # string contents?
            if not node.children:
                this.text = node.text.decode()
        root = etree.Element('root')
        go(t, root)
        return XML(root)

    def pp(self):
        if isinstance(self.root, str):
            return repr(self.root)
        return etree.tostring(
            self.root,
            pretty_print=True,
            encoding='unicode'
        )

    def pr(self):
        print(self.pp().strip())

    def xpath(self, s: str):
        return [
            # XML(e.getparent()) if hasattr(e, 'getparent') else XML(e)
            # XML(e.getparent())
            # if 'ElementUnicodeResult' in repr(type(e)) else
            XML(e)
            for e in self.root.xpath(s)
        ]

def test():
    s = '''if 1:
        f.x(1, 2, 3)
        if a:
            b
        elif c:
            d
        elif e:
            f
        else:
            g
        maps = {
            't': this.siblings().next(this),
            'n': this.siblings().prev(this),
            '<a-t>': this.cousins_and_siblings().next(this),
        }

    '''
    doc = XML.parse(s, 2, len(s))
    doc.pr()
    # for sub in doc.xpath('//arg-list/integer'):
    #     sub.pr()

    # for sub in doc.xpath('//*[@start >= 17 and @end <= 25]'):
    #     sub.pr()

    examples = '''
        //expr-stmt/call
        //expr-stmt[call]
        //call[parent::expr-stmt]
        //call[../../expr-stmt]
        //dict//*[@key]
        //dict//*[@value]//ident
        //integer
        //ident[@condition]
        //arg-list/*[not(self::delim)]
        //arg-list/*[not(name()="delim")]
        //arg-list/*[count(self::delim)=0]
        //arg-list/*[1]
        (//arg-list/*)[1]
        //*[@*="field"][count(.//*)<=2]
        //@container
    '''.splitlines()

    for ex in examples:
        ex = ex.strip()
        if not ex:
            continue
        print('>>>', ex)
        for sub in doc.xpath(ex):
            sub.pr()

    ns = etree.FunctionNamespace(None)
    @ns
    def has(ctx, name):
        return name in ctx.context_node.attrib

    # print(doc.root.xpath(r"//*[has('key')]/.."))

if __name__ == '__main__':
    test()

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
        xml = XML.parse(buf, *byte_offsets())
        sel = '(//*[@container and not(*/@container)])'
        k.eval(
            q.debug(
                # '=== full:',
                # xml.pp(),
                # '=== parent:',
                # *[e.pp() for e in xml.xpath(f'{sel}/ancestor::*[not(@selection)][1]')],
                # '=== children:',
                # *[e.pp() for e in xml.xpath(f'{sel}/*')],
                # '=== siblings:',
                # *[e.pp() for e in xml.xpath(f'{sel}/preceding-sibling::* | {sel}/following-sibling::*')],
                ' ',
                # '=== prev sibling:',
                # '=== prev:',
                # *[e.pp() for e in xml.xpath(f'(({sel}/preceding-sibling::*[1]) | ({sel}/following-sibling::*[last()]))[1]')],
                # '=== selected:',
                # *[e.pp() for e in xml.xpath(f'({sel}/preceding-sibling::* | {sel} | {sel}/following-sibling::*)')],
                # '=== next:',
                # *[e.pp() for e in xml.xpath(f'(({sel}/following-sibling::*[1]) | ({sel}/../*[1]))[last()]')],
                '=== test:',
                *[e.pp() for e in xml.xpath(f'({sel}/preceding-sibling::*[1])')],
                '=== test2:',
                *[e.pp() for e in xml.xpath(f'({sel}/preceding-sibling::*)[1]')],
                '=== test3:',
                *[e.pp() for e in xml.xpath(f'({sel}/preceding-sibling::*)[last()]')],
                '=== a1:',
                *[e.pp() for e in xml.xpath(f'{sel}/../*[1] | {sel}/../*[last()]')],
                '=== a2:',
                *[e.pp() for e in xml.xpath(f'{sel}/../*[last()] | {sel}/../*[1]')],
                # *[e.pp() for e in xml.xpath(sel)],
                # '=== next sibling:',
                # *[e.pp() for e in xml.xpath(f'({sel}/following-sibling::* | {sel}/../*[1])')],
                # '=== next preorder:',
                # *[e.pp() for e in xml.xpath(f'({sel}/descendant::* | {sel}/following::*)[1]')],
                # '=== prev preorder:',
                # *[e.pp() for e in xml.xpath(f'({sel}/preceding::* | {sel}/ancestor::*)[last()]')],
            )
        )

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

