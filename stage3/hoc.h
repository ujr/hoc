struct Symbol {            /* symbol table entry */
  char *name;
  short type;              /* VAR, BLTIN, UNDEF */
  union {
    double val;            /* if VAR */
    double (*ptr)();       /* if BLTIN */
  } u;
  struct Symbol *next;     /* to link to another */
};

typedef struct Symbol Symbol;

Symbol *install(const char *s, int t, double d);
Symbol *lookup(const char *s);

void init(void);
void execerror(const char *s, const char *t);
