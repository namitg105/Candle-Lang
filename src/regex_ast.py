"""
regex_ast.py
------------
A small hand-written regex parser for the pattern language used by
CandleLang. This is deliberately NOT using Python's `re` module — the
whole point of the TOC project is to build the pattern-matching pipeline
from first principles (regex -> NFA -> DFA), so we need our own AST first.

Supported syntax (enough to express real candlestick patterns over the
alphabet {U, D, F, G}):

    a          literal symbol (a in {U,D,F,G})
    (r)        grouping
    r1 r2      concatenation (juxtaposition, no operator)
    r1|r2      union / alternation
    r*         Kleene star (0 or more)
    r+         one or more   (sugar: r r*)
    r?         zero or one   (sugar: r|epsilon)
    [abc]      character class (sugar: a|b|c)
    r{n,}      "at least n" (sugar: expands to r repeated n times, then r*)

Grammar (standard precedence: union lowest, then concat, then postfix *,+,?):

    union   := concat ('|' concat)*
    concat  := repeat*
    repeat  := atom ('*' | '+' | '?' | '{' NUM ',}' )?
    atom    := LITERAL | '(' union ')' | '[' LITERAL+ ']'
"""

from dataclasses import dataclass, field
from typing import List, Union as TUnion


# ---- AST node types ---------------------------------------------------

@dataclass
class Char:
    value: str


@dataclass
class Epsilon:
    pass


@dataclass
class Concat:
    parts: List["Node"]


@dataclass
class Union:
    parts: List["Node"]


@dataclass
class Star:
    inner: "Node"


Node = TUnion[Char, Epsilon, Concat, Union, Star]


class RegexSyntaxError(Exception):
    pass


class RegexParser:
    def __init__(self, pattern: str):
        self.pattern = pattern
        self.pos = 0

    def peek(self):
        return self.pattern[self.pos] if self.pos < len(self.pattern) else None

    def advance(self):
        ch = self.peek()
        self.pos += 1
        return ch

    def parse(self) -> Node:
        node = self.parse_union()
        if self.pos != len(self.pattern):
            raise RegexSyntaxError(
                f"Unexpected character '{self.peek()}' at position {self.pos} in /{self.pattern}/"
            )
        return node

    def parse_union(self) -> Node:
        parts = [self.parse_concat()]
        while self.peek() == "|":
            self.advance()
            parts.append(self.parse_concat())
        return parts[0] if len(parts) == 1 else Union(parts)

    def parse_concat(self) -> Node:
        parts = []
        while self.peek() is not None and self.peek() not in ("|", ")"):
            parts.append(self.parse_repeat())
        if not parts:
            return Epsilon()
        return parts[0] if len(parts) == 1 else Concat(parts)

    def parse_repeat(self) -> Node:
        atom = self.parse_atom()
        while self.peek() in ("*", "+", "?", "{"):
            op = self.advance()
            if op == "*":
                atom = Star(atom)
            elif op == "+":
                atom = Concat([atom, Star(atom)])
            elif op == "?":
                atom = Union([atom, Epsilon()])
            elif op == "{":
                num = ""
                while self.peek() and self.peek().isdigit():
                    num += self.advance()
                if self.peek() != ",":
                    raise RegexSyntaxError("Only {n,} (at-least-n) form is supported")
                self.advance()  # consume ','
                if self.peek() != "}":
                    raise RegexSyntaxError("Only {n,} (at-least-n) form is supported")
                self.advance()  # consume '}'
                n = int(num)
                if n < 1:
                    raise RegexSyntaxError("{n,} requires n >= 1")
                copies = [atom] * n + [Star(atom)]
                atom = Concat(copies) if len(copies) > 1 else copies[0]
        return atom

    def parse_atom(self) -> Node:
        ch = self.peek()
        if ch is None:
            raise RegexSyntaxError("Unexpected end of pattern")
        if ch == "(":
            self.advance()
            node = self.parse_union()
            if self.peek() != ")":
                raise RegexSyntaxError("Expected closing ')'")
            self.advance()
            return node
        if ch == "[":
            self.advance()
            choices = []
            while self.peek() != "]":
                if self.peek() is None:
                    raise RegexSyntaxError("Unclosed character class '['")
                choices.append(Char(self.advance()))
            self.advance()  # consume ']'
            return choices[0] if len(choices) == 1 else Union(choices)
        if ch.isalpha():
            self.advance()
            return Char(ch)
        raise RegexSyntaxError(f"Unexpected character '{ch}' at position {self.pos}")


def parse_regex(pattern: str) -> Node:
    return RegexParser(pattern).parse()
