#include "hoc.h"
#include <math.h>
#include <errno.h>
#include <stdlib.h>

double errcheck(double d, const char *s);

double Log(double x)           { return errcheck(log(x),   "log");   }
double Log10(double x)         { return errcheck(log10(x), "log10"); }
double Exp(double x)           { return errcheck(exp(x),   "exp");   }
double Sqrt(double x)          { return errcheck(sqrt(x),  "sqrt");  }

double Pow(double x, double y) { return errcheck(pow(x,y),  "pow");  }
double Mod(double x, double y) { return errcheck(fmod(x,y), "mod");  }
double Atan2(double y, double x) { return errcheck(atan2(y,x), "atan2"); }

double Rand() { return (double) rand() / (double) RAND_MAX; }
double integer(double x) { return (double) (long) x; }

double errcheck(double d, const char *s)  /* check result of library call */
{
  if (errno == EDOM) {
    errno = 0;
    execerror(s, "argument out of domain");
  }
  else if (errno == ERANGE) {
    errno = 0;
    execerror(s, "result out of range");
  }
  return d;
}

