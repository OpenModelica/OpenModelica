%{
#include <stdio.h>
#include <stdlib.h>

#define YYSTYPE void*
void* absyntree;

int yyerror(char *s)
{
  extern int yylineno;
  fprintf(stderr,"Syntax error at or near line %d.\n",yylineno);
  exit(1);
}

int yywrap()
{
  return 1;
}

#ifdef RML
#include "Exp1.h"
#include "yacclib.h"
#ifndef Exp1__FACop
#define Exp1__FACop(X) (void*)yyerror("")
#endif
#ifndef Exp1__POWop
#define Exp1__POWop(X,Y) (void*)yyerror("")
#endif
#else
#include "meta/meta_modelica.h"
void* getAST()
{
  return absyntree;
}

extern struct record_description Exp1_Exp_ADDop__desc;
extern struct record_description Exp1_Exp_SUBop__desc;
extern struct record_description Exp1_Exp_MULop__desc;
extern struct record_description Exp1_Exp_DIVop__desc;
extern struct record_description Exp1_Exp_NEGop__desc;

const char* WORKAROUND__Exp1_Exp_POWop__desc__fields[] = {"exp1","exp2"};
struct record_description WORKAROUND__Exp1_Exp_POWop__desc = {
    "Exp1_Exp_POWop",
    "Exp1.Exp.POWop",
    WORKAROUND__Exp1_Exp_POWop__desc__fields
};
const char* WORKAROUND__Exp1_Exp_FACop__desc__fields[] = {"exp"};
struct record_description WORKAROUND__Exp1_Exp_FACop__desc = {
    "Exp1_Exp_FACop",
    "Exp1.Exp.FACop",
    WORKAROUND__Exp1_Exp_FACop__desc__fields
};

#define Exp1__ADDop(X1,X2) (mmc_mk_box3(4,&Exp1_Exp_ADDop__desc,(X1),(X2)))
#define Exp1__SUBop(X1,X2) (mmc_mk_box3(5,&Exp1_Exp_SUBop__desc,(X1),(X2)))
#define Exp1__MULop(X1,X2) (mmc_mk_box3(6,&Exp1_Exp_MULop__desc,(X1),(X2)))
#define Exp1__DIVop(X1,X2) (mmc_mk_box3(7,&Exp1_Exp_DIVop__desc,(X1),(X2)))
#define Exp1__NEGop(X1)    (mmc_mk_box2(8,&Exp1_Exp_NEGop__desc,(X1)))
#define Exp1__POWop(X1,X2) (mmc_mk_box3(9,&WORKAROUND__Exp1_Exp_POWop__desc,(X1),(X2)))
#define Exp1__FACop(X1)    (mmc_mk_box2(10,&WORKAROUND__Exp1_Exp_FACop__desc,(X1)))
#endif

%}

%token T_INTCONST
%token T_LPAREN T_RPAREN
%token T_ADD
%token T_SUB
%token T_MUL
%token T_DIV
%token T_GARBAGE
%token T_ERR

%token T_POW
%token T_FACTORIAL

%%

/* Yacc BNF Syntax of the expression language Exp1 */

program
                 :  expression
                    { absyntree = $1; }

expression       :  term
                 |  expression  T_ADD  term
                    { $$ = Exp1__ADDop($1,$3);}
                 |  expression  T_SUB  term
                    { $$ = Exp1__SUBop($1,$3);}
                 
term             :  u_element
                 |  term  T_MUL  u_element
                    { $$ = Exp1__MULop($1,$3);}
                 |  term  T_DIV  u_element
                    { $$ = Exp1__DIVop($1,$3);}

u_element        :  element
                 |  T_SUB  element
                    { $$ = Exp1__NEGop($2);}
                 |  T_FACTORIAL  element
                    { $$ = Exp1__FACop($2);}
                 |  element T_POW  u_element
                    { $$ = Exp1__POWop($1,$3);}

element          :  T_INTCONST
                 |  T_LPAREN  expression  T_RPAREN
                    { $$ = $2;}
