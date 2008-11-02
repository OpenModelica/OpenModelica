%{

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include "rml-db-parse.h"
#include "yacclib.h"

typedef void* rml_t;
#define YYSTYPE rml_t

int yyrmldb_lineno = 1;
extern int yyrmldbdebug;


%}


%option 8bit
%option nodefault
%option outfile = "rml-db-scan.c"
%option prefix = "yyrmldb"
%option noyywrap

LETTER  [A-Za-z_]
DIGIT	[0-9]
ident   {LETTER}({LETTER}|{DIGIT}|"'"|"-")*
tyvar   "'"{LETTER}({LETTER}|{DIGIT}|"-"|"'")*
file    ({LETTER}|{DIGIT}|"."|"\\"|"/"|"-")*

%x c_comment

%%

^"l:" {
	return T_VAL;
}

^"v:" {
	return T_VAR;
}


^"c:" {
	return T_CON;
}

^"t:" {
	return T_TYPE;
}

^"r:" {
	return T_RELATION;
}

"(" {
  return T_LPAR;
}

")" {
  return T_RPAR;
}

"," {
  return T_COMMA;
}

"[" {
  return T_LBRACK;
}

"]" {
  return T_RBRACK;
}

"*" {
  return T_STAR;
}

"=>" {
 return T_FATARROW;
 }

"." {
return T_DOT;
}

":" {
return T_COLON;
}

"|" {
return T_MORE;
}

{DIGIT}+ {
	yyrmldblval = (rml_t) mk_icon(atoi(yyrmldbtext));
	if (yyrmldbdebug) fprintf(stderr, "FLEX:[NUMBER:%s at line %d]", yyrmldbtext, yyrmldb_lineno);
	return T_number;
}

{ident} {
	if (yyrmldbdebug) fprintf(stderr, "FLEX:[ID:%s at line %d]", yyrmldbtext, yyrmldb_lineno);
	yyrmldblval = (rml_t) mk_scon(yyrmldbtext);
	return T_id;
}

{tyvar} {
	if (yyrmldbdebug) fprintf(stderr, "FLEX:[TYVAR:%s at line %d]", yyrmldbtext, yyrmldb_lineno);
	yyrmldblval = (rml_t) mk_scon(yyrmldbtext);
	return T_tyvar;
}

"<"{file}">" {
        char* x;//[1000];
	if (yyrmldbdebug) fprintf(stderr, "FLEX:[FILE:%s at line %d]", yyrmldbtext, yyrmldb_lineno);
        x = strdup(yyrmldbtext+1);
        x[strlen(x)-1]='\0';
	yyrmldblval = (rml_t) mk_scon(x);
	return T_file;
}

"/\*"           {
                    BEGIN(c_comment);
                }

<c_comment>
{
    "\*/\n"       {
                    BEGIN(INITIAL);
                }
    "/\*"       {
                     yyrmldberror("Suspicious comment");
                }
    [^\n]       /* Skip stuff in comments */
    \n          /* Skip stuff in comments */
    <<EOF>>     {
                     yyrmldberror("Unterminated comment");
                     yyrmldb_lineno = 1;
                     return T_EOF;
                 }
}
\n              { yyrmldb_lineno++; return T_EOL; }
[ \t\r\010]+	{ /* Skip whitespace */ }
<<EOF>>			{  yyrmldb_lineno = 1; return T_EOF; }
\/\/.*$         /* Skip single-line comment */
.				{ if (yyrmldbdebug) fprintf(stderr,"FLEX:bad character: %s at line %d\n", yyrmldbtext, yyrmldb_lineno); }
%%




