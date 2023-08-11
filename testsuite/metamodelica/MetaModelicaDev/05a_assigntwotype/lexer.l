%{

#define YYSTYPE void*
#include "parser.h"
#ifdef RML
#include "yacclib.h"
#else
#include "meta/meta_modelica.h"
#endif

%}

whitespace   [ \t\n\r]+
letter       [a-zA-Z_]
ident        {letter}({letter}|{digit})*
digit        [0-9]
digits       {digit}+
icon         {digits}
pt           "."
sign         [+-]
exponent     ([eE]{sign}?{digits})
rcon1        {digits}({pt}{digits}?)?{exponent}
rcon2        {digits}?{pt}{digits}{exponent}?
rcon         {rcon1}|{rcon2}
istring      \"{icon}\"
%%

{whitespace} ;
{ident}      return lex_ident(); /* T_IDENT */
{icon}       return lex_icon();  /* T_INTCONST */
{rcon}       return lex_rcon();   /* T_REALCONST */
{istring}    return lex_string(); /* T_STRINGCONST */      
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
  yylval = mmc_mk_icon(atoi(yytext));
  return T_INTCONST;
}

int lex_rcon()
{
  yylval = mmc_mk_rcon(atof(yytext));
  return T_REALCONST;
}

int lex_string()
{
  char *buff = strdup(yytext);
  /* Remove first/last quotes */
  buff[strlen(buff)-1] = '\0';
  yylval = mmc_mk_scon(buff+1);
  free(buff);
  return T_STRINGCONST;
}

int lex_ident()
{
  yylval = mmc_mk_scon(yytext);
  return T_IDENT;
}
