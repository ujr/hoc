%{
#include <ctype.h>
#include <math.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>
#define UNUSED(x) ((void)(x))
double mem[26];     /* memory for variables 'a' to 'z' */
int yylex(void);
void yyerror(char *s);
%}
%union {
        double  val; /* actual value */
        int   index; /* index into mem[] */
}
%token  <val>   NUMBER
%token  <index> VAR
%type   <val>   expr
%right  '='
%left   '+' '-'      /* left associative, same precedence */
%left   '*' '/' '%'  /* left assoc., higher precedence */
%left   UNARYPM      /* unary + and - have highest precedence */
%%
list:     /* nothing */
        | list       '\n'
        | list       ';'
        | list expr  '\n'  { printf("\t%.8g\n", $2); }
        | list expr  ';'
        | list error '\n'  { yyerrok; }
        ;
expr:     NUMBER         { $$ = $1; }
        | VAR            { $$ = mem[$1]; }
        | VAR '=' expr   { $$ = mem[$1] = $3; }
        | '-' expr  %prec UNARYPM  { $$ = -$2; }
        | '+' expr  %prec UNARYPM  { $$ = $2; }
        | expr '+' expr  { $$ = $1 + $3; }
        | expr '-' expr  { $$ = $1 - $3; }
        | expr '*' expr  { $$ = $1 * $3; }
        | expr '/' expr  { $$ = $1 / $3; }
        | expr '%' expr  { $$ = fmod($1, $3); }
        | '(' expr ')'   { $$ = $2; }
        ;
%%

char    *progname;     /* for error messages */
int     lineno = 1;
jmp_buf begin;

void warning(char *s, char *t);
void fpecatch(int signum);

int main(int argc, char *argv[])  /* hoc2 */
{
        UNUSED(argc);
        progname = argv[0];
        setjmp(begin);
        signal(SIGFPE, fpecatch);
        yyparse();
        return 0;
}

int yylex(void)  /* hoc2 */
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
        if (islower(c)) {
                yylval.index = c - 'a';  /* ASCII only */
                return VAR;
        }
        if (c == '\n')
                lineno++;
        return c;
}

void yyerror(char *s)  /* called for yacc syntax error */
{
        warning(s, (char *) 0);
}

void warning(char *s, char *t)  /* print warning message */
{
        fprintf(stderr, "%s: %s", progname, s);
        if (t) fprintf(stderr, " %s", t);
        fprintf(stderr, " near line %d\n", lineno);
}

void execerror(char *s, char *t)  /* run-time error recovery */
{
        warning(s, t);
        longjmp(begin, 0);
}

void fpecatch(int signum)  /* catch floating point exceptions */
{
        UNUSED(signum);
        execerror("floating point exceptoin", (char *) 0);
}

