#include "hoc.h"
#include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void *emalloc(unsigned nbytes);

static Symbol *symlist = 0;  /* symbol table: linked list */

Symbol *lookup(const char *s)  /* find s in symbol table */
{
  Symbol *sp;
  for (sp = symlist; sp; sp = sp->next)
    if (strcmp(sp->name, s) == 0)
      return sp;
  return 0;  /* not found */
}

Symbol *install(const char *s, int t, double d)  /* add s to symtab */
{
  Symbol *sp = emalloc(sizeof(Symbol));
  sp->name = emalloc(strlen(s)+1);  /* +1 for '\0' */
  strcpy(sp->name, s);
  sp->type = t;
  sp->u.val = d;
  sp->next = symlist;  /* put at front of list */
  symlist = sp;
  return sp;
}

void *emalloc(unsigned nbytes)  /* check return from malloc */
{
  void *p = malloc(nbytes);
  if (!p) execerror("out of memory", 0);
  return p;
}

void dumpsyms(void)
{
  Symbol *sp;
  FILE *fp = stderr;
  for (sp = symlist; sp; sp = sp->next) {
    switch (sp->type) {
      case BLTIN:
        fprintf(fp, "BLTIN %s @ 0x%p\n", sp->name, sp->u.ptr); break;
      case CONST:
        fprintf(fp, "CONST %s = %.8g\n", sp->name, sp->u.val); break;
      case NUMBER:
        fprintf(fp, "NUMBER %.8g\n", sp->u.val); break;
      case VAR:
        fprintf(fp, "VAR %s = %.8g\n", sp->name, sp->u.val); break;
      default:
        fprintf(fp, "UNDEF %s\n", sp->name); break;
    }
  }
}
