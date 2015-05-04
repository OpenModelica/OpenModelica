%{
#define YYSTYPE void*
#include "parser.h"

void* absyn_integer(char *s);

#ifdef RML
#include "yacclib.h"
#include "Exp2.h"
#else
#include "meta/meta_modelica.h"
extern struct record_description Exp2_Exp_INT__desc;
#define Exp2__INT(X1) (mmc_mk_box2(3,&Exp2_Exp_INT__desc,(X1)))
#endif

%}

digit           ("0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9")
digits          {digit}+
junk            \n
letter          [$_A-Za-z.]
letters         {letter}+


%%

{digits}     { yylval = absyn_integer(yytext); return T_INTCONST; }
"+"          return T_ADD;
"-"          return T_SUB;
"*"          return T_MUL;
"/"          return T_DIV;
"^"          return T_POW;
"!"          return T_FACTORIAL;
"("          return T_LPAREN;
")"          return T_RPAREN;
{junk}+         ;
{letters}    return T_ERR;

%%

void* absyn_integer(char *s)
{
  return Exp2__INT(mmc_mk_icon(atoi(s)));
}
