%{
#include "hoc.h"
#define UNUSED(x) ((void)(x))
#define code1(c1)       code(c1,#c1);
#define code2(c1,c2)    code(c1,#c1); code(c2,#c2)
#define code3(c1,c2,c3) code(c1,#c1); code(c2,#c2); code(c3,#c3)
#define code4(a,b,c,d)  code2(a,b); code2(c,d);
#define code8(a,b,c,d,e,f,g,h) code4(a,b,c,d); code4(e,f,g,h)
#define codeopeq(var,op) code8(varpush,var,eval,swap,op,varpush,var,assign)

int yylex(void);
void yyerror(char *s);
Symbol  *prev;         /* previous result */
static int plevel = 0; /* paren nesting level */
static int blevel = 0; /* brace nesting level */
%}

%union {
        Symbol *sym;   /* symbol table pointer */
        Inst   *inst;  /* machine instruction */
}

%token  <sym>   NUMBER CONST VAR BLTIN UNDEF WHILE IF ELSE PRINT
%type   <inst>  stmt asgn expr stmtlist cond while if end
%right  '=' ADDBY SUBBY MULBY DIVBY
%left   OR
%left   AND
%left   GT GE LT LE EQ NE
%left   '+' '-'
%left   '*' '/'
%left   UNARYPM NOT
%right  '^'

%%

list:     /* nothing */
        | list       term    /* allow empty lines and extra semicolons */
        | list asgn  term    { code2(drop, STOP); return 1; }
        | list stmt  term    { code1(STOP); return 1; }
        | list expr  term    { code3(varpush, (Inst) prev, assign);
                               code2(print, STOP); return 1; }
        | list error '\n'    { yyerrok; plevel = blevel = 0; }
        ;
term:     ';' | '\n'         /* statement (and asgn and expr) terminator */
        ;
asgn:     VAR '=' expr       { $$=$3; code3(varpush, (Inst) $1, assign); }
        | VAR ADDBY expr     { $$=$3; codeopeq((Inst) $1, add); }
        | VAR SUBBY expr     { $$=$3; codeopeq((Inst) $1, sub); }
        | VAR MULBY expr     { $$=$3; codeopeq((Inst) $1, mul); }
        | VAR DIVBY expr     { $$=$3; codeopeq((Inst) $1, divide); }
        ;
stmt:     expr               { code1(drop); }
        | PRINT expr         { code1(prexpr); $$ = $2; }
        | while cond stmt end {
                ($1)[1] = (Inst)$3;        /* body of loop */
                ($1)[2] = (Inst)$4; }      /* end, if cond fails */
        | if cond stmt end {               /* else-less if */
                ($1)[1] = (Inst)$3;        /* thenpart */
                ($1)[3] = (Inst)$4; }      /* end, if cond fails */
        | if cond stmt end ELSE stmt end { /* if with else */
                ($1)[1] = (Inst)$3;        /* thenpart */
                ($1)[2] = (Inst)$6;        /* elsepart */
                ($1)[3] = (Inst)$7; }      /* end, if cond fails */
        | '{' stmtlist '}'   { $$ = $2; }
        ;
cond:     '(' expr ')'       { code1(STOP); $$ = $2; }
        ;
while:    WHILE   { $$ = code3(whilecode, STOP, STOP); }
        ;
if:       IF      { $$ = code1(ifcode); code3(STOP, STOP, STOP); }
        ;
end:      /* nothing */      { code1(STOP); $$ = progp; }
        ;
stmtlist: /* nothing */      { $$ = progp; }
        | stmtlist term
        | stmtlist stmt
        ;

expr:     NUMBER             { $$ = code2(constpush, (Inst) $1); }
        | VAR                { $$ = code3(varpush, (Inst) $1, eval); }
        | asgn
        | BLTIN '(' expr ')' { $$ = $3; code2(bltin, (void*) $1->u.ptr); }
        | '(' expr ')'       { $$ = $2; }

        | expr '+' expr      { code1(add); }
        | expr '-' expr      { code1(sub); }
        | expr '*' expr      { code1(mul); }
        | expr '/' expr      { code1(divide); }
        | expr '^' expr      { code1(power); }

        | '-' expr  %prec UNARYPM  { $$ = $2; code1(negate); }
        | '+' expr  %prec UNARYPM  { $$ = $2; }

        | expr GT expr       { code1(gt); }
        | expr GE expr       { code1(ge); }
        | expr LT expr       { code1(lt); }
        | expr LE expr       { code1(le); }
        | expr EQ expr       { code1(eq); }
        | expr NE expr       { code1(ne); }
        | expr AND expr      { code1(land); }
        | expr OR expr       { code1(lor); }
        | NOT expr           { $$ = $2; code1(lnot); }
        ;

%%

#include <ctype.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>

char    *progname;     /* for error messages */
int     verbose = 0;
int     lineno = 1;
jmp_buf begin;

void warning(const char *s, const char *t);
void fpecatch(int signum);
void interrupt(int signum);
static int follow(int expect, int ifyes, int ifno);

int main(int argc, char *argv[])  /* hoc5 */
{
        UNUSED(argc);

        progname = argv[0];
        init();
        prev = install("$", VAR, 0.0);
        setjmp(begin);
        signal(SIGFPE, fpecatch);

        for (initcode(); yyparse(); initcode()) {
                signal(SIGINT, interrupt);
                execute(prog);
                signal(SIGINT, SIG_DFL);
        }

        return 0;
}

int yylex(void)  /* hoc5 */
{
        int c;
        while ((c = getchar()) == ' ' || c == '\t' ||
               (c == '\n' && (plevel > 0 || blevel > 0)))
                ;
        if (c == EOF)
                return 0;  /* zero is EOF to yyparse */
        if (c == '.' || isdigit(c)) {  /* number */
                double d;
                ungetc(c, stdin);
                scanf("%lf", &d);
                yylval.sym = install("", NUMBER, d);
                return NUMBER;
        }
        if (c == '$') {  /* previous result */
                yylval.sym = prev;
                return VAR;
        }
        if (isalpha(c)) {  /* name */
                Symbol *sp;
                char sbuf[100], *p = sbuf;
                char *end = sbuf + sizeof(sbuf);
                do { if (p < end) *p++ = c; }
                while ((c = getchar()) != EOF && isalnum(c));
                ungetc(c, stdin);
                if (p >= end)
                        execerror("name too long", 0);
                *p = '\0';
                if ((sp = lookup(sbuf)) == 0)
                        sp = install(sbuf, UNDEF, 0.0);
                yylval.sym = sp;
                return sp->type == UNDEF || sp->type == CONST
                        ? VAR  /* CONST and UNDEF are grammatically VARs */
                        : sp->type;
        }
        if (c == '#') {  /* comment */
                do c = getchar();
                while (c != EOF && c != '\n');
                if (c == EOF) return 0;
        }
        if (c == '\n')
                lineno++;
        switch (c) {
        case '>':   return follow('=', GE, GT);
        case '<':   return follow('=', LE, LT);
        case '=':   return follow('=', EQ, '=');
        case '+':   return follow('=', ADDBY, '+');
        case '-':   return follow('=', SUBBY, '-');
        case '*':   return follow('=', MULBY, '*');
        case '/':   return follow('=', DIVBY, '/');
        case '!':   return follow('=', NE, NOT);
        case '|':   return follow('|', OR, '|');
        case '&':   return follow('&', AND, '&');
        case '(':   plevel += 1; return c;
        case ')':   plevel -= 1; return c;
        case '{':   blevel += 1; return c;
        case '}':   blevel -= 1; return c;
        }
        return c;
}

static int follow(int expect, int ifyes, int ifno)
{
        int c = getchar();
        if (c == expect)  return ifyes;
        ungetc(c, stdin); return ifno;
}

void yyerror(char *s)  /* called for yacc syntax error */
{
        warning(s, 0);
}

void warning(const char *s, const char *t)  /* print warning message */
{
        fprintf(stderr, "%s: %s", progname, s);
        if (t) fprintf(stderr, " %s", t);
        fprintf(stderr, " near line %d\n", lineno);
}

void execerror(const char *s, const char *t)  /* run-time error recovery */
{
        warning(s, t);
        longjmp(begin, 0);
}

void fpecatch(int signum)  /* catch floating point exceptions */
{
        UNUSED(signum);
        execerror("floating point exception", 0);
}

void interrupt(int signum)  /* catch sig int */
{
        UNUSED(signum);
        fflush(stdout);
        execerror("interrupted", 0);
}

