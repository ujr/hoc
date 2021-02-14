%{
#include <stdio.h>
#include <ctype.h>
#define YYSTYPE double  /* data type of yacc stack */
#define UNUSED(x) ((void)(x))
int yylex(void);
void yyerror(char *s);
%}
%token NUMBER
%left  '+' '-'   /* left associative, same precedence */
%left  '*' '/'   /* left assoc., higher precedence */
%%
list:     /* nothing */
        | list '\n'
        | list expr '\n' { printf("\t%.8g\n", $2); }
        ;
expr:     NUMBER         { $$ = $1; }
        | expr '+' expr  { $$ = $1 + $3; }
        | expr '-' expr  { $$ = $1 - $3; }
        | expr '*' expr  { $$ = $1 * $3; }
        | expr '/' expr  { $$ = $1 / $3; }
        | '(' expr ')'   { $$ = $2; }
        ;
%%

char    *progname;     /* for error messages */
int     lineno = 1;

void warning(char *s, char *t);

int main(int argc, char *argv[])  /* hoc1 */
{
        UNUSED(argc);
        progname = argv[0];
        yyparse();
        return 0;
}

int yylex(void)  /* hoc1 */
{
        int c;
        while ((c = getchar()) == ' ' || c == '\t')
                ;
        if (c == EOF)
                return 0;
        if (c == '.' || isdigit(c)) {  /* number */
                ungetc(c, stdin);
                scanf("%lf", &yylval);
                return NUMBER;
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
