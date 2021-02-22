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

union Datum {              /* interpreter stack type */
        double  val;       /* for literal numbers */
        Symbol *sym;       /* for variables */
};

typedef union Datum Datum;

typedef void (*Inst)();    /* machine instruction */
#define STOP (Inst) 0      /* instruction to stop execution */

extern Inst prog[], *progp;
extern void constpush(), varpush(), swap(), dup(), drop();
extern void add(), sub(), mul(), divide(), power(), negate();
extern void eval(), assign(), bltin(), print();
extern void prexpr(), ifcode(), whilecode();
extern void eq(), ne(), gt(), ge(), lt(), le();
extern void land(), lor(), lnot();
extern void preincr(), postincr(), predecr(), postdecr();

extern void initcode(void);
extern Inst *code(Inst f, const char *s);
extern void execute(Inst *p);

extern int verbose;
