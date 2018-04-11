#!/usr/bin/env python

import sys

# Inefficient-but-public-domain Commodore BASIC 2.0 tokenizer.
# This work is in the public domain, covered under the UNLICENSE;
# see the file UNLICENSE in the root directory of this distribution,
# or http://www.unlicense.org/ for full details.

# references:
#   http://justsolve.archiveteam.org/wiki/Commodore_BASIC_tokenized_file
#   http://www.c64-wiki.com/index.php/BASIC_token

TOKENS = (
    ('restore', 140),
    ('input#', 132),
    ('return', 142),
    ('verify', 149),
    ('print#', 152),
    ('right$', 201),
    ('input', 133),
    ('gosub', 141),
    ('print', 153),
    ('close', 160),
    ('left$', 200),
    ('next', 130),
    ('data', 131),
    ('read', 135),
    ('goto', 137),
    ('stop', 144),
    ('wait', 146),
    ('load', 147),
    ('save', 148),
    ('poke', 151),
    ('cont', 154),
    ('list', 155),
    ('open', 159),
    ('tab(', 163),
    ('spc(', 166),
    ('then', 167),
    ('step', 169),
    ('peek', 194),
    ('str$', 196),
    ('chr$', 199),
    ('mid$', 202),
    ('end', 128),
    ('for', 129),
    ('dim', 134),
    ('let', 136),
    ('run', 138),
    ('rem', 143),
    ('def', 150),
    ('clr', 156),
    ('cmd', 157),
    ('sys', 158),
    ('get', 161),
    ('new', 162),
    ('not', 168),
    ('and', 175),
    ('sgn', 180),
    ('int', 181),
    ('abs', 182),
    ('usr', 183),
    ('fre', 184),
    ('pos', 185),
    ('sqr', 186),
    ('rnd', 187),
    ('log', 188),
    ('exp', 189),
    ('cos', 190),
    ('sin', 191),
    ('tan', 192),
    ('atn', 193),
    ('len', 195),
    ('val', 197),
    ('asc', 198),
    ('if', 139),
    ('on', 145),
    ('to', 164),
    ('fn', 165),
    ('or', 176),
    ('go', 203),
    ('+', 170),
    ('-', 171),
    ('*', 172),
    ('/', 173),
    ('^', 174),
    ('>', 177),
    ('=', 178),
    ('<', 179),

    # MEGA65 MEGA BASIC new keywords
    # (token values are expressed similarly to in the 6502 source for MEGA BASIC
    #  for easier tracking)
    ('fast', 0xcc+0),
    ('slow', 0xcc+1),
    ('canvas', 0xcc+2),
    ('colour', 0xcc+3),
    ('color', 0xcc+3),
    ('tile', 0xcc+4),
    ('text', 0xcc+5+0),
    ('sprite', 0xcc+5+1),
    ('screen', 0xcc+5+2),
    ('border', 0xcc+5+3),
    ('set', 0xcc+5+4),
    ('delete', 0xcc+5+5),
    ('stamp', 0xcc+5+6),
    ('at', 0xcc+5+7),
    ('from', 0xcc+5+8),
)

SPECIAL = (
    ('{rvs off}',  0x92),
    ('{SHIFT-@}',  0xba),
    ('{rvs on}',   0x12),
    ('{CBM-+}',    0xa6),
    ('{CBM-E}',    0xb1),
    ('{CBM-R}',    0xb2),
    ('{CBM-T}',    0xa3),
    ('{down}',     0x11),
    ('{home}',     0x13),
    ('{lblu}',     0x9a),
    ('{left}',     0x9d),
    ('{rght}',     0x1d),
    ('{blk}',      0x90),    
    ('{blu}',      0x1f),
    ('{clr}',      0x93),
    ('{cyn}',      0x9f),
    ('{grn}',      0x1e),
    ('{pur}',      0x9c),
    ('{red}',      0x1c),
    ('{wht}',      0x05),
    ('{yel}',      0x9e),
    ('{up}',       0x91),
)


def ascii_to_petscii(o):  # int -> int
    if o <= ord('@') or o in (ord('['), ord(']')):
        return o
    if o == ord('^'):
        return o;
    if o >= ord('a') and o <= ord('z'):
        return o - ord('a') + 0x41
    if o >= ord('A') and o <= ord('Z'):
        # adding 0x61 should be enough for PETSCII but.. tokenization adds
        # something more?  oh dear.
        return o - ord('A') + 0x61 + 0x60
    # TODO:
    # pound sign? 0x5c
    # up arrow? 0x5e
    # left arrow? 0x5f
    # hatched box? 0x60
    # pi? 0x7e
    # upper right triangle? 0x7f
    raise NotImplementedError("Cannot PETSCII: %s" % hex(o))


def scan(s, tokenize=True):
    # so inefficient.  I don't care.
    if tokenize:
        for (token, value) in TOKENS:
            if s.startswith(token):
               return (value, s[len(token):])
    if s[0] == '{':
        for (token, value) in SPECIAL:
           if s.startswith(token):
               return (value, s[len(token):])                
        raise NotImplementedError(s)
    return (ascii_to_petscii(ord(s[0])), s[1:])


def scan_line_number(s):
    s = s.lstrip()
    acc = []
    while s and s[0].isdigit():
        acc.append(s[0])
        s = s[1:]
    return (int(''.join(acc)), s.lstrip())


def tokenize(s):
    (line_number, s) = scan_line_number(s)
    bytes = []
    in_quotes = False
    in_remark = False
    while s:
        (byte, s) = scan(s, tokenize=not (in_quotes or in_remark))
        bytes.append(byte)
        if byte == ord('"'):
            in_quotes = not in_quotes
        if byte == 143:
            in_remark = True
    return (line_number, bytes)


def write_word(f, word):
    """f being a file-like object, word being an integer 0-65535"""
    low = word & 255
    high = (word >> 8) & 255
    f.write(chr(low) + chr(high))


class TokenizedLine(object):
    def __init__(self, s, addr):
        (line_number, bytes) = tokenize(s)
        self.line_number = line_number
        self.bytes = bytes
        self.addr = addr
        self.next_addr = None

    def __len__(self):
        return len(self.bytes) + 5

    def write_to(self, f):
        """f being a file-like object"""
        assert self.next_addr is not None
        write_word(f, self.next_addr)
        write_word(f, self.line_number)
        for byte in self.bytes:
            f.write(chr(byte))
        f.write(chr(0))


class Sentinel(object):
    def __init__(self, addr):
        self.addr = addr
        self.next_addr = None

    def __len__(self):
        return 2

    def write_to(self, f):
        """f being a file-like object"""
        write_word(f, 0)


def main(argv):
    start_addr = 0x0801

    # parse command line
    while argv:
        switch = argv.pop(0)
        if switch == '-l':
            start_addr = eval('0x' + argv.pop(0))
        else:
            raise NotImplementedError(switch)

    # set sys.stdout to binary mode for Windows folks
    # reference: http://code.activestate.com/recipes/65443-sending-binary-data-to-stdout-under-windows/
    if sys.platform == "win32":
        import os, msvcrt
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

    # tokenize all lines of input, and terminate with a sentinel
    tokenized_lines = []
    addr = start_addr
    for line in sys.stdin:
        if not line.strip():
            continue
        tokenized_line = TokenizedLine(line.rstrip(), addr)
        addr += len(tokenized_line)
        tokenized_lines.append(tokenized_line)
    tokenized_lines.append(Sentinel(addr))

    # make second pass to resolve each line's pointer to start of next line
    i = 1
    while i < len(tokenized_lines):
        tokenized_lines[i - 1].next_addr = tokenized_lines[i].addr
        i += 1

    # write tokenized lines to output
    outfile = sys.stdout
    write_word(outfile, start_addr)
    for tokenized_line in tokenized_lines:
        tokenized_line.write_to(outfile)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

