# High Order Calculator

An example of classical programming on the UNIX system.

In *The UNIX Programming Environment* (1984), Kernighan
and Pike present a programmable calculator, called `hoc`
for “high order calculator”, as a non-trivial programming
example. The code here has been slightly edited to make it
conform with ANSI C.

- [excerpt](doc/unixdev.pdf) from *The UNIX Programming Environment*
- source of [hoc at stage 1](./stage1/hoc.y)
  (four-function calculator, `hoc.y`)
- source of [hoc at stage 2](./stage2/hoc.y)
  (add unary minus and variables `a` to `z`)
- source of hoc at stage 3
  (add arbitrarily named variables and built-ins)
- source of hoc at stage 4
  (internal change: generate code)
- source of hoc at stage 5
  (add control flow and relational operators)
- source of hoc at stage 6
  (add recursive functions and input/output)
- [the manual](man/hocman.pdf) for hoc at stage 6 (PDF)

The highly recommended source:

Brian W. Kernighan, Rob Pike:
*The UNIX Programming Environment.*
Prentice-Hall, 1984, 376pp., ISBN 013937681X.
[Amazon](https://www.amazon.com/dp/013937681X)

Copyright (c) 1984 by Bell Telephone Laboratories, Incorporated.
