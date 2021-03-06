#include "hoc.h"
#include "y.tab.h"
#include <stdio.h>

#define NSTACK 256
static Datum  stack[NSTACK];   /* the stack */
static Datum *stackp;          /* next free spot on stack */

#define NPROG 2000
       Inst   prog[NPROG];     /* the machine */
       Inst  *progp;           /* next free spot (for code generation) */
static Inst  *pc;              /* program counter (for code execution) */
static char  *syms[NPROG];
static char **symsp;

void dumpprog(void)
{
  int i;
  Inst *p;
  FILE *fp = stderr;
  for (i = 0, p = prog; p < progp; ++i, ++p) {
    if (p > prog && *(p-1) == varpush)
      fprintf(fp, "%02d:   %s\n", i, ((Symbol *) *p)->name);
    else if (i > 0 && prog[i-1] == constpush)
      fprintf(fp, "%02d:   %.8g\n", i, ((Symbol *) *p)->u.val);
    else
      fprintf(fp, "%02d: %s\n", i, syms[i]);
  }
}

void initcode(void)  /* initialize for code generation */
{
        stackp = stack;
        progp = prog;
        symsp = syms;
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
        *symsp++ = (char *) s;

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

void swap(void)  /* swap (exchange) top two items */
{
        Datum y = pop();
        Datum x = pop();
        push(y);
        push(x);
}

void dup(void)  /* duplicate top item of stack */
{
        Datum d = pop();
        push(d);
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

void preincr(void) /* ++x */
{
        Datum x = pop();
        if (x.sym->type == UNDEF)
                execerror("undefined variable", x.sym->name);
        if (x.sym->type != VAR)
                execerror("assignment to non-variable", x.sym->name);
        x.val = ++(x.sym->u.val);
        push(x);
}

void postincr(void) /* x++ */
{
        Datum x = pop();
        if (x.sym->type == UNDEF)
                execerror("undefined variable", x.sym->name);
        if (x.sym->type != VAR)
                execerror("assignment to non-variable", x.sym->name);
        x.val = (x.sym->u.val)++;
        push(x);
}

void predecr(void) /* --x */
{
        Datum x = pop();
        if (x.sym->type == UNDEF)
                execerror("undefined variable", x.sym->name);
        if (x.sym->type != VAR)
                execerror("assignment to non-variable", x.sym->name);
        x.val = --(x.sym->u.val);
        push(x);
}

void postdecr(void) /* x-- */
{
        Datum x = pop();
        if (x.sym->type == UNDEF)
                execerror("undefined variable", x.sym->name);
        if (x.sym->type != VAR)
                execerror("assignment to non-variable", x.sym->name);
        x.val = (x.sym->u.val)--;
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

void prexpr(void)  /* print numeric value */
{
        Datum d = pop();
        printf("%.8g ", d.val);
}

void bltin(void)  /* evaluate built-in on top of stack */
{
        Datum d = pop();
        d.val = (*(double (*)())(void*)(*pc++))(d.val);
        push(d);
}

void whilecode(void)
{
        Datum d;
        Inst *savepc = pc;  /* loop body */
        execute(savepc+2);  /* condition */
        d = pop();
        while (d.val) {
                execute(*((Inst **)(savepc)));  /* body */
                execute(savepc+2);
                d = pop();
        }
        pc = *((Inst **)(savepc+1));  /* next statement */
}

void ifcode(void)
{
        Datum d;
        Inst *savepc = pc;  /* then part */
        execute(savepc+3);  /* condition */
        d = pop();
        if (d.val)
                execute(*((Inst **)(savepc)));
        else if (*((Inst **)(savepc+1)))  /* else part? */
                execute(*((Inst **)(savepc+1)));
        pc = *((Inst **)(savepc+2));  /* next stmt */
}

void eq(void)
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val == y.val);
        push(x);
}

void ne(void)
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val != y.val);
        push(x);
}

void lt(void)
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val < y.val);
        push(x);
}

void le(void)
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val <= y.val);
        push(x);
}

void gt(void)
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val > y.val);
        push(x);
}

void ge(void)
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val >= y.val);
        push(x);
}

void land(void)  /* logical and */
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val != 0.0 && y.val != 0.0);
        push(x);
}

void lor(void)  /* logical or */
{
        Datum y = pop();
        Datum x = pop();
        x.val = (double) (x.val != 0.0 || y.val != 0.0);
        push(x);
}

void lnot(void)  /* logical not */
{
        Datum x = pop();
        x.val = (double) (x.val == 0.0);
        push(x);
}

