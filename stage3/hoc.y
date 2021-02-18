%{
#include "hoc.h"
#include <ctype.h>
#include <math.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>
#define UNUSED(x) ((void)(x))
extern double Pow(double x, double y);
Symbol  *prev;  /* previous result */
int yylex(void);
void yyerror(char *s);
%}
%union {
        double  val;   /* actual value */
        Symbol *sym;   /* symbol table pointer */
}
%token  <val>   NUMBER
%token  <sym>   CONST VAR BLTIN UNDEF
%type   <val>   expr asgn
%right  '='
%left   '+' '-'        /* left associative, same precedence */
%left   '*' '/' '%'    /* left assoc., higher precedence */
%left   UNARYPM        /* unary + and - have highest precedence */
%right  '^'            /* exponentiation */
%%
list:     /* nothing */
        | list       '\n'
        | list asgn  '\n'
        | list expr  '\n'  { printf("\t%.8g\n", $2); prev->u.val = $2; }
        | list error '\n'  { yyerrok; }
        ;
asgn:     VAR '=' expr   { if ($1->type == CONST)
                               execerror("cannot assign to const", $1->name);
                           $1->type = VAR;  /* no longer UNDEF */
                           $$ = $1->u.val = $3; }
        ;
expr:     NUMBER         { $$ = $1; }
        | VAR            { if ($1->type == UNDEF)
                               execerror("undefined variable", $1->name);
                           $$ = $1->u.val; }
        | asgn
        | BLTIN '(' expr ')' { $$ = (*($1->u.ptr))($3); }
        | expr '+' expr  { $$ = $1 + $3; }
        | expr '-' expr  { $$ = $1 - $3; }
        | expr '*' expr  { $$ = $1 * $3; }
        | expr '/' expr  { if ($3 == 0.0)
                               execerror("division by zero", "");
                           $$ = $1 / $3; }
        | expr '%' expr  { if ($3 == 0.0)
                               execerror("division by zero", "");
                           $$ = fmod($1, $3); }
        | expr '^' expr  { $$ = Pow($1, $3); }
        | '(' expr ')'   { $$ = $2; }
        | '-' expr  %prec UNARYPM  { $$ = -$2; }
        | '+' expr  %prec UNARYPM  { $$ = $2; }
        ;
%%

char    *progname;     /* for error messages */
int     lineno = 1;
jmp_buf begin;

void warning(const char *s, const char *t);
void fpecatch(int signum);

int main(int argc, char *argv[])  /* hoc3 */
{
        UNUSED(argc);
        progname = argv[0];
        init();
        prev = install("$", VAR, 0.0);
        setjmp(begin);
        signal(SIGFPE, fpecatch);
        yyparse();
        return 0;
}

int yylex(void)  /* hoc3 */
{
        int c;
        while ((c = getchar()) == ' ' || c == '\t')
                ;
        if (c == EOF)
                return 0;
        if (c == '.' || isdigit(c)) {  /* number */
                ungetc(c, stdin);
                scanf("%lf", &yylval.val);
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

