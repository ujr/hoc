%{
#include "hoc.h"
#include <stdint.h>
#include <stdio.h>
#define UNUSED(x) ((void)(x))
#define code1(c1)       code(c1,#c1);
#define code2(c1,c2)    code(c1,#c1); code(c2,#c2)
#define code3(c1,c2,c3) code(c1,#c1); code(c2,#c2); code(c3,#c3)
#define code4(a,b,c,d)  code2(a,b); code2(c,d);
#define code8(a,b,c,d,e,f,g,h) code4(a,b,c,d); code4(e,f,g,h)
#define codeopeq(var,op) code8(varpush,var,eval,swap,op,varpush,var,assign)

int yylex(void);
void yyerror(char *s);
void defnonly(char *s);
Symbol  *prev;         /* previous result */
Symbol  *debug;        /* debugging output */
static int plevel = 0; /* paren nesting level */
static int blevel = 0; /* brace nesting level */
static char *indef = 0;
%}

%union {
        Symbol *sym;   /* symbol table pointer */
        Inst   *inst;  /* machine instruction */
        int    narg;   /* number of arguments */
}

%token  <sym>   NUMBER STRING CONST VAR BLTIN UNDEF READ PRINT SYMS
%token  <sym>   WHILE IF ELSE FUNCTION PROCEDURE RETURN FUNC PROC
%token  <narg>  ARG

%type   <inst>  expr stmt asgn prlist stmtlist
%type   <inst>  cond while if begin end
%type   <sym>   procname
%type   <narg>  arglist

%right  '=' ADDBY SUBBY MULBY DIVBY
%left   OR
%left   AND
%left   GT GE LT LE EQ NE
%left   '+' '-'
%left   '*' '/'
%left   UNARYPM NOT INCR DECR
%right  '^'

%%

list:     /* nothing */
        | list       term    /* allow empty lines and extra semicolons */
        | list SYMS  term    { dumpsyms(); }
        | list defn  term
        | list asgn  term    { code2(drop, STOP); return 1; }
        | list stmt  term    { code1(STOP); return 1; }
        | list expr  term    { code3(varpush, (Inst) prev, assign);
                               code2(print, STOP); return 1; }
        | list error term    { yyerrok; plevel = blevel = 0; }
        ;
term:     ';' | '\n'         /* statement (and asgn and expr) terminator */
        ;
asgn:     VAR '=' expr       { $$=$3; code3(varpush, (Inst) $1, assign); }
        | VAR ADDBY expr     { $$=$3; codeopeq((Inst) $1, add); }
        | VAR SUBBY expr     { $$=$3; codeopeq((Inst) $1, sub); }
        | VAR MULBY expr     { $$=$3; codeopeq((Inst) $1, mul); }
        | VAR DIVBY expr     { $$=$3; codeopeq((Inst) $1, divide); }
        | ARG '=' expr       { defnonly("$"); code2(argassign, (Inst) (intptr_t) $1);
                               $$=$3; }
        ;
stmt:     expr               { code1(drop); }
        | RETURN             { defnonly("return"); code1(procret); }
        | RETURN expr        { defnonly("return"); $$=$2; code1(funcret); }
        | PROCEDURE begin '(' arglist ')'
                             { $$=$2; code3(call, (Inst)$1, (Inst)(intptr_t)$4); }
        | PRINT prlist       { $$ = $2; }
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
begin:    /* nothing */      { $$ = progp; }
        ;
end:      /* nothing */      { code1(STOP); $$ = progp; }
        ;
stmtlist: /* nothing */      { $$ = progp; }
        | stmtlist term
        | stmtlist stmt
        ;

expr:     NUMBER             { $$ = code2(constpush, (Inst) $1); }
        | VAR                { $$ = code3(varpush, (Inst) $1, eval); }
        | ARG                { defnonly("$");
                               $$ = code2(arg, (Inst)(intptr_t) $1); }
        | asgn               { $$ = $1; }

        | FUNCTION begin '(' arglist ')'
                             { $$ = $2;
                               code3(call, (Inst)$1, (Inst)(intptr_t)$4); }
        | READ '(' VAR ')'   { $$ = code2(varread, (Inst) $3); }

          /* could also do without specific instructions, e.g. pre inc:
             constpush 1, varpush $2 eval, add, varpush $2 assign */
        | INCR VAR           { $$ = code3(varpush, (Inst) $2, preincr); }
        | DECR VAR           { $$ = code3(varpush, (Inst) $2, predecr); }
        | VAR INCR           { $$ = code3(varpush, (Inst) $1, postincr); }
        | VAR DECR           { $$ = code3(varpush, (Inst) $1, postdecr); }

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
prlist:   expr               { code1(prexpr); }
        | STRING             { $$ = code2(prstr, (Inst) $1); }
        | prlist ',' expr    { code1(prexpr); }
        | prlist ',' STRING  { code2(prstr, (Inst) $3); }
        ;
defn:     FUNC procname { $2->type = FUNCTION; indef = $2->name; }
            '(' ')' stmt { code1(procret); define($2); indef = 0; }
        | PROC procname { $2->type = PROCEDURE; indef = $2->name; }
            '(' ')' stmt { code1(procret); define($2); indef = 0; }
        ;
procname: VAR
        | FUNCTION
        | PROCEDURE
        ;
arglist:  /* nothing */      { $$ = 0; }
        | expr               { $$ = 1; }
        | arglist ',' expr   { $$ = $1 + 1; }
        ;
%%

#include <ctype.h>
#include <errno.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>

char    *progname;     /* for error messages */
int      gargc;        /* global argument count */
char   **gargv;        /* global argument list */
int      lineno = 1;   /* line counter for current file */
char    *infn;         /* current input file name (0 for stdin) */
FILE    *infp;         /* current input file pointer */
jmp_buf  begin;

void fpecatch(int signum);
void interrupt(int signum);
int moreinput(void);

/* Lexical Scanner */

static int follow(int expect, int ifyes, int ifno)
{
        int c = getc(infp);
        if (c == expect)  return ifyes;
        ungetc(c, infp); return ifno;
}

static int backslash(int c)  /* get next char with \'s interpreted */
{
        static char transtab[] = "b\bf\fn\nr\rt\t";
        if (c != '\\') return c;
        c = getc(infp);
        if (islower(c) && strchr(transtab, c))
                return strchr(transtab, c)[1];
        return c;
}

int yylex(void)  /* hoc6, called from yyparse */
{
        int c;
        while ((c = getc(infp)) == ' ' || c == '\t' ||
               (c == '\n' && (plevel > 0 || blevel > 0)))
                ;
        if (c == EOF)
                return 0;  /* zero is EOF to yyparse */
        if (c == '.' || isdigit(c)) {  /* number */
                double d;
                ungetc(c, infp);
                fscanf(infp, "%lf", &d);
                yylval.sym = install("", NUMBER, d);
                return NUMBER;
        }
        if (c == '$') {  /* argument (or previous result) */
                int n = 0;
                while (isdigit(c = getc(infp)))
                        n = 10*n + c - '0';
                ungetc(c, infp);
                if (n == 0) {
                        yylval.sym = prev;
                        return VAR;
                }
                yylval.narg = n;
                return ARG;
        }
        if (isalpha(c)) {  /* name */
                Symbol *sp;
                char sbuf[100], *p = sbuf;
                char *end = sbuf + sizeof(sbuf);
                do { if (p < end) *p++ = c; }
                while ((c = getc(infp)) != EOF && isalnum(c));
                ungetc(c, infp);
                if (p >= end)
                        execerror("name too long", 0);
                *p = '\0';
                if ((sp = lookup(sbuf)) == 0)
                        sp = install(sbuf, UNDEF, 0.0);
                yylval.sym = sp;
                if (strcmp(sbuf, "syms") == 0)
                        return SYMS;
                return sp->type == UNDEF || sp->type == CONST
                        ? VAR  /* CONST and UNDEF are grammatically VARs */
                        : sp->type;
        }
        if (c == '"') {  /* quoted string */
                char sbuf[100], *p;
                for (p = sbuf; (c = getc(infp)) != '"'; p++) {
                        if (c == '\n' || c == EOF)
                                execerror("missing quote", "");
                        if (p >= sbuf + sizeof(sbuf) - 1) {
                                *p = '\0';
                                execerror("string too long", sbuf);
                        }
                        *p = backslash(c);
                }
                *p = 0;
                yylval.sym = emalloc(strlen(sbuf)+1);
                strcpy((char*)(void*) yylval.sym, sbuf);
                return STRING;
        }
        if (c == '#') {  /* comment */
                do c = getc(infp);
                while (c != EOF && c != '\n');
                if (c == EOF) return 0;
        }
        if (c == '\n')
                lineno++;
        switch (c) {
        case '>':   return follow('=', GE, GT);
        case '<':   return follow('=', LE, LT);
        case '=':   return follow('=', EQ, '=');
        case '+':   return follow('=', ADDBY, follow('+', INCR, '+'));
        case '-':   return follow('=', SUBBY, follow('-', DECR, '-'));
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

/* Error Handling */

static void warning(const char *s, const char *t)  /* print warning message */
{
        fprintf(stderr, "%s: %s", progname, s);
        if (t) fprintf(stderr, " %s", t);
        if (infn) fprintf(stderr, " in %s", infn);
        fprintf(stderr, " near line %d\n", lineno);
}

void yyerror(char *s)  /* called for yacc syntax error */
{
        warning(s, 0);
}

void execerror(const char *s, const char *t)  /* run-time error recovery */
{
        warning(s, t);
        fseek(infp, 0L, 2);  /* flush rest of file */
        longjmp(begin, 0);
}

void defnonly(char *s)  /* warn if illegal definition */
{
        if (!indef)
                execerror(s, "used outside definition");
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

/* Main Program */

static void run(void)  /* execute until EOF */
{
        setjmp(begin);
        signal(SIGFPE, fpecatch);

        for (initcode(); yyparse(); initcode()) {
                signal(SIGINT, interrupt);
                if (debug->u.val)
                        dumpprog(progbase);
                execute(progbase);
                signal(SIGINT, SIG_DFL);
        }
}

int main(int argc, char *argv[])  /* hoc6 */
{
        static char *stdinonly[] = { "-" };
        progname = argv[0];

        if (argc <= 1) {
                gargc = 1;
                gargv = stdinonly;
        }
        else {
                gargc = argc - 1;
                gargv = argv + 1;
        }

        init();
        prev = install("$", VAR, 0.0);
        debug = install("debug", VAR, 0.0);

        while (moreinput())
                run();

        return 0;
}

int moreinput(void)
{
        if (gargc-- <= 0) return 0;  /* no more input */
        if (infp && infp != stdin)
                fclose(infp);
        infn = *gargv++;
        if (strcmp(infn, "-") == 0) {
                infp = stdin;
                infn = 0;
        }
        else if ((infp = fopen(infn, "r")) == NULL) {
                fprintf(stderr, "%s: can't open %s: %s\n",
                        progname, infn, strerror(errno));
                return moreinput();
        }
fprintf(stderr, "{reading from %s}\n", infn ? infn : "(stdin)");
        lineno = 1;
        return 1;  /* more input */
}

