struct Symbol {            /* symbol table entry */
  char *name;
  short type;              /* VAR, BLTIN, UNDEF */
  union {
    double val;            /* VAR */
    double (*ptr)();       /* BLTIN */
    void   (**defn)();     /* FUNCTION, PROCEDURE */
    char   *str;           /* STRING */
  } u;
  struct Symbol *next;     /* to link to another */
};

typedef struct Symbol Symbol;

Symbol *install(const char *s, int t, double d);
Symbol *lookup(const char *s);
void *emalloc(unsigned nbytes);
void dumpsyms(void);
extern Symbol *debug;      /* debug mode if u.val > 0 */

void init(void);
void execerror(const char *s, const char *t);

union Datum {              /* interpreter stack type */
        double  val;       /* for literal numbers */
        Symbol *sym;       /* for variables */
};

typedef union Datum Datum;

typedef void (*Inst)();    /* machine instruction */
#define STOP (Inst) 0      /* instruction to stop execution */

extern void initcode(void);
extern Inst *code(Inst f, const char *s);
extern void define(Symbol *sp);
extern void execute(Inst *p);
extern void dumpprog(Inst *p);

extern Inst prog[], *progp, *progbase;

/* machine instructions */
extern void constpush(), varpush(), swap(), dup(), drop();
extern void add(), sub(), mul(), divide(), power(), negate();
extern void eval(), assign(), bltin(), print(), prexpr(), prstr();
extern void ifcode(), whilecode(), varread(), error();
extern void eq(), ne(), gt(), ge(), lt(), le();
extern void land(), lor(), lnot();
extern void preincr(), postincr(), predecr(), postdecr();
extern void call(), funcret(), procret(), arg(), argassign();

