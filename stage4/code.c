#include "hoc.h"
#include "y.tab.h"
#include <stdio.h>

#define NSTACK 256
static Datum  stack[NSTACK];   /* the stack */
static Datum *stackp;          /* next free spot on stack */

#define NPROG 2000
       Inst   prog[NPROG];     /* the machine */
static Inst  *progp;           /* next free spot (for code generation) */
static Inst  *pc;              /* program counter (for code execution) */

void initcode(void)  /* initialize for code generation */
{
        stackp = stack;
        progp = prog;
}

static void push(Datum d)  /* push d onto stack */
{
        if (stackp >= &stack[NSTACK])
                execerror("stack overflow", 0);
        *stackp++ = d;
}

static Datum pop(void)  /* pop and return top elem from stack */
{
        if (stackp <= stack)
                execerror("stack underflow", 0);
        return *--stackp;
}

Inst *code(Inst f, const char *s)  /* emit one instruction or operand */
{
        Inst *oldprogp = progp;
        if (progp >= &prog[NPROG])
                execerror("program too big", 0);
        *progp++ = f;

        if (verbose > 0)
                fprintf(stderr, "%2zu: %s\n", oldprogp-prog, s);

        return oldprogp;
}

void execute(Inst *p)  /* run the machine */
{
        for (pc = p; *pc != STOP; )
                (*(*pc++))();
}

/* machine instructions */

void constpush(void)  /* push constant onto stack */
{
        Datum d;
        d.val = ((Symbol *) *pc++)->u.val;
        push(d);
}

void varpush(void)  /* push variable onto stack */
{
        Datum d;
        d.sym = (Symbol *) (*pc++);
        push(d);
}

void drop(void)  /* pop and discard top item from stack */
{
        (void) pop();
}

void add(void)  /* add top two elems on stack */
{
        Datum y = pop();
        Datum x = pop();
        x.val += y.val;
        push(x);
}

void sub(void)  /* subtract top two elems on stack */
{
        Datum y = pop();
        Datum x = pop();
        x.val -= y.val;
        push(x);
}

void mul(void)  /* multiply top two elems on stack */
{
        Datum y = pop();
        Datum x = pop();
        x.val *= y.val;
        push(x);
}

void divide(void)  /* divide top two elems on stack */
{
        Datum y = pop();
        Datum x = pop();
        if (y.val == 0.0)
                execerror("division by zero", 0);
        x.val /= y.val;
        push(x);
}

void negate(void)  /* negate top of stack */
{
        Datum x = pop();
        x.val = -x.val;
        push(x);
}

void power(void)  /* raise to power */
{
        extern double Pow(double,double);
        Datum y = pop();
        Datum x = pop();
        x.val = Pow(x.val, y.val);
        push(x);
}

void eval(void)  /* evaluate variable on stack */
{
        Datum d = pop();
        if (d.sym->type == UNDEF)
                execerror("undefined variable", d.sym->name);
        d.val = d.sym->u.val;
        push(d);
}

void assign(void)  /* assign to top var next-to-top value */
{
        Datum v = pop();
        Datum x = pop();
        if (v.sym->type != VAR && v.sym->type != UNDEF)
                execerror("assignment to non-variable", v.sym->name);
        v.sym->u.val = x.val;
        v.sym->type = VAR;  /* no longer UNDEF */
        push(x);  /* push value because asgn is an expr */
}

void print(void)  /* pop top value from stack, print it */
{
        Datum d = pop();
        printf("\t%.8g\n", d.val);
}

void bltin(void)  /* evaluate built-in on top of stack */
{
        Datum d = pop();
        d.val = (*(double (*)())(void*)(*pc++))(d.val);
        push(d);
}

