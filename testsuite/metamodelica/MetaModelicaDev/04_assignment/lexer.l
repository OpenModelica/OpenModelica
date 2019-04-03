%{
#define YYSTYPE void*
#include "parser.h"

int lex_icon();
int lex_ident();

#ifdef RML
#include "yacclib.h"
#include "Assignment.h"
#else
#include "meta/meta_modelica.h"

extern struct record_description Assignment_Exp_INT__desc;
#define Assignment__INT(X1) (mmc_mk_box2(3,&Assignment_Exp_INT__desc,(X1)))
#endif

%}

whitespace   [ \t\n]+
letter       [a-zA-Z_]
ident        {letter}({letter}|{digit})*
digit        [0-9]
digits       {digit}+
%%

{whitespace} ;
{ident}      return lex_ident(); /* T_IDENT */
{digits}     return lex_icon();  /* T_INTCONST */
":="         return T_ASSIGN;
"+"          return T_ADD;
"-"          return T_SUB;
"*"          return T_MUL;
"/"          return T_DIV;
"("          return T_LPAREN;
")"          return T_RPAREN;
";"          return T_SEMIC;

%%

int lex_icon()
{
  yylval = Assignment__INT(mmc_mk_icon(atoi(yytext)));  
  return T_INTCONST;        
}

int lex_ident()
{
  yylval = mmc_mk_scon(yytext);
  return T_IDENT;
}
