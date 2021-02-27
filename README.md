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
- source of [hoc at stage 3](./stage3/)
  (add arbitrarily named variables and built-ins)
- source of [hoc at stage 4](./stage4/)
  (internal change: generate code)
- source of [hoc at stage 5](./stage5/)
  (add control flow and relational operators)
- source of [hoc at stage 6](./stage6/)
  (add recursive functions and input/output)
- [the manual](man/hocman.pdf) for hoc at stage 6 (PDF)

The highly recommended source:

Brian W. Kernighan, Rob Pike:
*The UNIX Programming Environment.*
Prentice-Hall, 1984, 376pp., ISBN 013937681X.
[Amazon](https://www.amazon.com/dp/013937681X)

Copyright (c) 1984 by Bell Telephone Laboratories, Incorporated.

## Remarks

Starting with stage 3, the Makefile has a target `check`
that runs hoc it against some test data.

Starting with stage 3, the variable `$` refers to the
last result. At stage 3, the code for the production
`list: list expr '\n'` prints the value and assigns it
to `$`, at stage 4 and on it generates code that performs
this assignment.

Starting with stage 4, the implementation puts literal numbers
into the symbol table, where they accumulate. We could purge
those from the symbol table every once in a while, or store them
into the machine, which is already recycled after each statement.
For the latter approach, the machine would have to be changed
into an array of the union of an instruction pointer and a double.
Should we ever change the numeric representation to a non-constant
size, the former approach seems more attractive.

At stage 5, some of the suggestions from exercises have been
implemented: newlines are allowed inside `(...)` and `{...}`,
and semicolons act as statement terminators as do newlines.
Comments begin with `#` and last to the end of the line.
They were carried over to stage 6, and in this respect the
implementation here differs from the book's manual.

At stage 6, the command `syms` dumps the symbol table to
stderr, and when the variable `debug` has a positive value,
the code generated at func/proc definition time and prior
to interactive execution will be dumped to stderr.
