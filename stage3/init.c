#include "hoc.h"
#include "y.tab.h"
#include <math.h>

extern double Log(), Log10(), Exp(), Sqrt(), integer(), Mod(), Rand();

static struct {  /* Constants */
  char *name;
  double cval;
} consts[] = {
  { "PI",    3.14159265358979323846 },
  { "E",     2.71828182845904523536 },
  { "GAMMA", 0.57721566490153286060 },  /* Euler */
  { "DEG",  57.29577951308232087680 },  /* deg/radian */
  { "PHI",   1.61803398874989484820 },  /* golden ratio */
  { 0,       0 }
};

static struct {  /* Built-ins */
  char *name;
  int arity;
  double (*func)();
} builtins[] = {
  { "sin",   1, sin     },
  { "cos",   1, cos     },
  { "atan",  1, atan    },
  { "atan2", 2, atan2   },
  { "log",   1, Log     },  /* checks argument */
  { "log10", 1, Log10   },  /* checks argument */
  { "exp",   1, Exp     },  /* checks argument */
  { "sqrt",  1, Sqrt    },  /* checks argument */
  { "int",   1, integer },
  { "abs",   1, fabs    },
  { "mod",   2, Mod     },  /* checks argument */
  { "rand",  0, Rand    },
  { 0, 0, 0 }
};

void init(void)  /* install constants and built-ins in symtab */
{
  int i;
  Symbol *sp;

  for (i = 0; consts[i].name; i++)
    install(consts[i].name, CONST, consts[i].cval);
  for (i = 0; builtins[i].name; i++) {
    int a = builtins[i].arity;
    int t = a == 0 ? BLTIN0 : a == 1 ? BLTIN1 : BLTIN2;
    sp = install(builtins[i].name, t, 0.0);
    sp->u.ptr = builtins[i].func;
  }
}

