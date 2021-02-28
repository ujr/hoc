#include "hoc.h"
#include "y.tab.h"
#include <math.h>

extern double Log(), Log10(), Exp(), Sqrt(), integer();

static struct {  /* Keywords */
  char *name;
  int   kval;
} keywords[] = {
  { "proc",   PROC   },
  { "func",   FUNC   },
  { "return", RETURN },
  { "if",     IF     },
  { "else",   ELSE   },
  { "while",  WHILE  },
  { "print",  PRINT  },
  { "read",   READ   },
  { "error",  ERROR  },
  { 0,        0      }
};

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
  double (*func)();
} builtins[] = {
  { "sin",   sin     },
  { "cos",   cos     },
  { "atan",  atan    },
  { "log",   Log     },  /* checks argument */
  { "log10", Log10   },  /* checks argument */
  { "exp",   Exp     },  /* checks argument */
  { "sqrt",  Sqrt    },  /* checks argument */
  { "int",   integer },
  { "abs",   fabs    },
  { 0, 0 }
};

void init(void)  /* install constants and built-ins in symtab */
{
  int i;
  Symbol *sp;

  for (i = 0; keywords[i].name; i++)
    install(keywords[i].name, keywords[i].kval, 0.0);
  for (i = 0; consts[i].name; i++)
    install(consts[i].name, CONST, consts[i].cval);
  for (i = 0; builtins[i].name; i++) {
    sp = install(builtins[i].name, BLTIN, 0.0);
    sp->u.ptr = builtins[i].func;
  }
}

