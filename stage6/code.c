#include "hoc.h"
#include "y.tab.h"
#include <stdint.h>
#include <stdio.h>

/* Operand Stack */

#define NSTACK 256
static Datum  stack[NSTACK];   /* the stack */
static Datum *stackp;          /* next free spot on stack */

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


/* The Machine & Code Generation */

#define NPROG 2000
       Inst   prog[NPROG];     /* the machine */
       Inst  *progp;           /* next free spot (for code generation) */
static Inst  *pc;              /* program counter (for code execution) */
       Inst  *progbase = prog; /* start of current subprogram */
       int    returning;       /* 1 if return stmt seen */
static char  *syms[NPROG];
static char **symsp;

typedef struct Frame {         /* proc/func call stack frame */
        Symbol  *sp;           /* symbol table entry */
        Inst    *retpc;        /* where to resume after return */
        Datum   *argn;         /* n-th argument on stack */
        int     nargs;         /* number of arguments */
} Frame;

#define NFRAME  100
static Frame frame[NFRAME];
static Frame *fp;              /* frame pointer */

void dumpprog(Inst *p)
{
  FILE *fp = stderr;
  for (; p < progp; ++p) {
    int i = (p - prog);
    char c = p == progbase ? '*' : ' ';
    fprintf(fp, "%c%02d: ", c, i);
    if (*p == constpush && p+1 < progp) {
      fprintf(fp, "constpush %.8g\n", ((Symbol *) p[1])->u.val);
      p += 1;
    }
    else if (*p == varpush && p+1 < progp) {
      fprintf(fp, "varpush %s\n", ((Symbol *) p[1])->name);
      p += 1;
    }
    else if (*p == call && p+2 < progp) {
      fprintf(fp, "call %s/%d\n",
              ((Symbol *) p[1])->name, (int)(intptr_t) p[2]);
      p += 2;
    }
    else if (*p == arg && p+1 < progp) {
      fprintf(fp, "arg %d\n", (int) (intptr_t) p[1]);
      p += 1;
    }
    else if (*p == ifcode && p+3 < progp) {
      fprintf(fp, "ifcode then@%02d else@%02d next@%02d\n",
              (int) ((Inst*)p[1] - prog),
              (int) ((Inst*)p[2] - prog),
              (int) ((Inst*)p[3] - prog));
      p += 3;
    }
    else if (*p == whilecode && p+2 < progp) {
      fprintf(fp, "whilecode body@%02d next@%02d\n",
              (int) ((Inst*)p[1] - prog),
              (int) ((Inst*)p[2] - prog));
      p += 2;
    }
    else if (*p == prstr && p+1 < progp) {
      fprintf(fp, "prstr \"%s\"\n", (char *) p[1]);
      p += 1;
    }
    else
      fprintf(fp, "%s\n", syms[i]);
  }
}

void initcode(void)  /* initialize for code generation */
{
        progp = progbase;
        symsp = syms;
        stackp = stack;
        fp = frame;
        returning = 0;
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

void define(Symbol *sp)  /* put func/proc in symbol table */
{
        if (debug->u.val > 0) {
                fprintf(stderr, "define %s\n", sp->name);
                dumpprog(progbase);
        }

        sp->u.defn = progbase;   /* start of code */
        progbase = progp;        /* next code starts here */
}

void execute(Inst *p)  /* run the machine */
{
        for (pc = p; *pc != STOP && !returning; )
                (*(*pc++))();
}

static double *getarg(void)  /* return pointer to argument */
{
        int nargs = (intptr_t) *pc++;
        if (nargs > fp->nargs)
                execerror(fp->sp->name, "not enough arguments");
        return &fp->argn[nargs - fp->nargs].val;
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

void error(void)  /* trigger a runtime error */
{
        char *s = (char *) *pc++;
        execerror(s ? s : "runtime error", 0);
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

void prstr(void)  /* print string value */
{
        printf("%s", (char *) *pc++);
}

void bltin(void)  /* evaluate built-in on top of stack */
{
        double r;
        Datum d1, d2;
        int nargs = (intptr_t) *pc++;
        Symbol *sp = (Symbol *) *pc++;
        double (*f)() = sp->u.ptr;
        if (nargs != sp->arity) {
                while (nargs-- > 0) pop();
                execerror("arity mismatch for", sp->name);
        }
        switch (nargs) {
        case 0: r = (*f)();
                break;
        case 1: d1 = pop();
                r = (*f)(d1.val);
                break;
        case 2: d2 = pop(); d1 = pop();
                r = (*f)(d1.val, d2.val);
                break;
        default:
                while (nargs-- > 0) pop();
                execerror("arity not supported", 0);
                break;
        }
        d1.val = r;
        push(d1);
}

void whilecode(void)
{
        Datum d;
        Inst *savepc = pc;  /* loop body */
        execute(savepc+2);  /* condition */
        d = pop();
        while (d.val) {
                execute(*((Inst **)(savepc)));  /* body */
                if (returning) break;
                execute(savepc+2);
                d = pop();
        }
        if (!returning)
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
        if (!returning)
                pc = *((Inst **)(savepc+2));  /* next stmt */
}

void varread(void)
{
        Datum d;
        extern FILE *infp;
        extern int moreinput(void);
        Symbol *var = (Symbol *) *pc++;
Again:
        switch (fscanf(infp, "%lf", &var->u.val)) {
        case EOF:
                if (moreinput())
                        goto Again;
                d.val = var->u.val = 0.0;
                break;
        case 0:
                execerror("non-number read into", var->name);
                break;
        default:
                d.val = 1.0;
                break;
        }
        var->type = VAR;
        push(d);  /* 1 = success, 0 = end-of-file */
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

void call(void)  /* call a function or procedure */
{
        Symbol *sp = (Symbol *) pc[0];  /* symbol table entry for function */
        if (fp++ >= &frame[NFRAME-1])
                execerror(sp->name, "call nested too deeply");
        fp->sp = sp;
        fp->nargs = (intptr_t) pc[1];
        fp->retpc = pc + 2;
        fp->argn = stackp - 1;  /* last argument */
        execute(sp->u.defn);
        returning = 0;
}

static void ret(void)  /* common return from func or proc */
{
        int i;
        for (i = 0; i < fp->nargs; i++)
                pop();  /* pop arguments */
        pc = (Inst *) fp->retpc;
        --fp;
        returning = 1;
}

void funcret(void)  /* return from a function */
{
        Datum d;
        if (fp->sp->type == PROCEDURE)
                execerror(fp->sp->name, "(proc) returns value");
        d = pop();  /* preserve function return value */
        ret();
        push(d);
}

void procret(void)  /* return from a procedure */
{
        if (fp->sp->type == FUNCTION)
                execerror(fp->sp->name, "(func) returns no value");
        ret();
}

void arg(void)  /* push argument onto stack */
{
        Datum d;
        d.val = *getarg();
        push(d);
}

void argassign(void)  /* store top of stack in argument */
{
        Datum d = pop();
        push(d);              /* leave value on stack */
        *getarg() = d.val;
}

