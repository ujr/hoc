%{
#include "hoc.h"
#define UNUSED(x) ((void)(x))
#define code1(c1)       code(c1,#c1);
#define code2(c1,c2)    code(c1,#c1); code(c2,#c2)
#define code3(c1,c2,c3) code(c1,#c1); code(c2,#c2); code(c3,#c3)
int yylex(void);
void yyerror(char *s);
Symbol  *prev;         /* previous result */
%}
%union {
        Symbol *sym;   /* symbol table pointer */
        Inst   *inst;  /* machine instruction */
}
%token  <sym>   NUMBER CONST VAR BLTIN UNDEF
%right  '='            /* right associative, least precedence */
%left   '+' '-'        /* left associative, same precedence */
%left   '*' '/'        /* left assoc., higher precedence */
%left   UNARYPM        /* unary + and - have highest precedence */
%right  '^'            /* exponentiation */
%%
list:     /* nothing */
        | list       '\n'
        | list asgn  '\n'    { code2(drop, STOP); return 1; }
        | list expr  '\n'    { code3(varpush, (Inst) prev, assign);
                               code2(print, STOP); return 1; }
        | list error '\n'    { yyerrok; }
        ;
asgn:     VAR '=' expr       { code3(varpush, (Inst) $1, assign); }
        ;
expr:     NUMBER             { code2(constpush, (Inst) $1); }
        | VAR                { code3(varpush, (Inst) $1, eval); }
        | asgn
        | BLTIN '(' expr ')' { code2(bltin, (void*) $1->u.ptr); }
        | expr '+' expr      { code1(add); }
        | expr '-' expr      { code1(sub); }
        | expr '*' expr      { code1(mul); }
        | expr '/' expr      { code1(divide); }
        | expr '^' expr      { code1(power); }
        | '(' expr ')'
        | '-' expr  %prec UNARYPM  { code1(negate); }
        | '+' expr  %prec UNARYPM
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

int main(int argc, char *argv[])  /* hoc4 */
{
        UNUSED(argc);
        progname = argv[0];
        init();
        prev = install("$", VAR, 0.0);
        setjmp(begin);
        signal(SIGFPE, fpecatch);
        for (initcode(); yyparse(); initcode())
                execute(prog);
        return 0;
}

int yylex(void)  /* hoc4 */
{
        int c;
        while ((c = getchar()) == ' ' || c == '\t')
                ;
        if (c == EOF)
                return 0;
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
        if (c == '\n')
                lineno++;
        return c;
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
        execerror("floating point exceptoin", (char *) 0);
}

