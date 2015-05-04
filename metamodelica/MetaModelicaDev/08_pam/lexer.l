%{
#define YYSTYPE void*
#include "parser.h"

#ifdef RML
#include "yacclib.h"
#include "Pam.h"
#else
#include "meta/meta_modelica.h"

extern struct record_description Pam_Exp_INT__desc;

#define Pam__INT(X1) (mmc_mk_box2(3,&Pam_Exp_INT__desc,(X1)))

#endif

int linenr = 1;
long absyn_integer(char *s);
long absyn_ident_or_keyword(char *s);
int yywrap();

%}

%option yylineno

%x c_comment

whitespace   [ \t]+
newline      [\n]
letter       [a-zA-Z]
ident        {letter}({letter}|{digit})*
digit        [0-9]
digits       {digit}+
icon         {digits}
/* Lex style lexical syntax of tokens in the PAM language */

%%
{whitespace} ;
{newline}    linenr++;
{ident}      return absyn_ident_or_keyword(yytext); /* T_IDENT */
{digits}     return absyn_integer(yytext);  /* T_INTCONST */

"/\*"	     {
		BEGIN(c_comment);
             }
<c_comment>
{
    "\*/"    { BEGIN(INITIAL); }
    "/\*"    { yyerror("Suspicious comment"); }
    [^\n]    ;
    \n       linenr++;
    <<EOF>>  {
               yyerror("Unterminated comment");
	       yyterminate();
	     }
}


":="         return T_ASSIGN;
"+"          return T_ADD;
"-"          return T_SUB;
"*"          return T_MUL;
"/"          return T_DIV;
"("          return T_LPAREN;
")"          return T_RPAREN;
"<"          return T_LT;
"<="         return T_LE;
"="          return T_EQ;
"<>"         return T_NE;
">="         return T_GE;
">"          return T_GT;
";"          return T_SEMIC;
%%

/* Make a boxed integer from a C string representation (decimal),
   box it for our abstract syntax, put in yylval and return constant token. */
 
long absyn_integer(char *s)
{
  yylval= Pam__INT(mmc_mk_icon(atoi(s)));
  return T_INTCONST;
}
 
/* Make an String or a keyword token from a C string */
/* Reserved words: if,then,else,endif,while,do,end,to,read,write */
 
static struct keyword_s
{
  char *name;
  int token;
} kw[] =
{
  {"do",     T_DO},
  {"else",   T_ELSE},
  {"end",    T_END},
  {"endif",  T_ENDIF},
  {"if",     T_IF},
  {"read",   T_READ},
  {"then",   T_THEN},
  {"to",     T_TO},
  {"while",  T_WHILE},
  {"write",  T_WRITE},
};

long absyn_ident_or_keyword(char *s)
{
  int low = 0;
  int high = (sizeof kw) / sizeof(struct keyword_s) - 1;

  while( low <= high ) {
    int mid = (low + high) / 2;
    int cmp = strcmp(kw[mid].name, yytext);
    if( cmp == 0 )
    {
      return kw[mid].token;
    }
    else if( cmp < 0 )
      low = mid + 1;
    else
      high = mid - 1;
  }
  yylval = mmc_mk_scon(s);
  return T_IDENT;
}

int yywrap()
{
	return 1;
}
