%{
#include <stdlib.h>
#include <stdio.h>

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
#include "Exp2.h"
#include "yacclib.h"
#ifndef Exp2__FAC
#define Exp2__FAC (void*)yyerror("")
#endif
#ifndef Exp2__POW
#define Exp2__POW (void*)yyerror("")
#endif
#else
#include "meta/meta_modelica.h"

void* getAST()
{
  return absyntree;
}

/* Exp */
extern struct record_description Exp2_Exp_BINARY__desc;
extern struct record_description Exp2_Exp_UNARY__desc;
#define Exp2__BINARY(X1,OP,X2) (mmc_mk_box4(4,&Exp2_Exp_BINARY__desc,(X1),(OP),(X2)))
#define Exp2__UNARY(OP,X1) (mmc_mk_box3(5,&Exp2_Exp_UNARY__desc,(OP),(X1)))

/* BinOp */
extern struct record_description Exp2_BinOp_ADD__desc;
extern struct record_description Exp2_BinOp_SUB__desc;
extern struct record_description Exp2_BinOp_MUL__desc;
extern struct record_description Exp2_BinOp_DIV__desc;
const char* WORKAROUND__Exp2_BinOp_POW__desc__fields[] = {};
struct record_description WORKAROUND__Exp2_BinOp_POW__desc = {
    "Exp2_BinOp_POW",
    "Exp2.BinOp.POW",
    WORKAROUND__Exp2_BinOp_POW__desc__fields
};


#define Exp2__ADD (mmc_mk_box1(3,&Exp2_BinOp_ADD__desc))
#define Exp2__SUB (mmc_mk_box1(4,&Exp2_BinOp_SUB__desc))
#define Exp2__MUL (mmc_mk_box1(5,&Exp2_BinOp_MUL__desc))
#define Exp2__DIV (mmc_mk_box1(6,&Exp2_BinOp_DIV__desc))
#define Exp2__POW (mmc_mk_box1(8,&WORKAROUND__Exp2_BinOp_POW__desc))

/* UnOp */
extern struct record_description Exp2_UnOp_NEG__desc;
const char* WORKAROUND__Exp2_UnOp_FAC__desc__fields[] = {};
struct record_description WORKAROUND__Exp2_UnOp_FAC__desc = {
    "Exp2_UnOp_FAC",
    "Exp2.UnOp.FAC",
    WORKAROUND__Exp2_UnOp_FAC__desc__fields
};

#define Exp2__NEG (mmc_mk_box1(3,&Exp2_UnOp_NEG__desc))
#define Exp2__FAC (mmc_mk_box1(4,&WORKAROUND__Exp2_UnOp_FAC__desc))
#endif

%}

%token T_INTCONST
%token T_LPAREN T_RPAREN
%token T_ADD
%token T_SUB
%token T_MUL
%token T_DIV
%token T_GARBAGE
%token T_FACTORIAL
%token T_POW

%token T_ERR

%%

/* Yacc BNF Syntax of the expression language Exp2 */

program
                 :  expression
                    { absyntree = $1; }

expression       :  term
                 |  expression  T_ADD  term
                    { $$ = Exp2__BINARY($1, Exp2__ADD, $3);}
                 |  expression  T_SUB  term
                    { $$ = Exp2__BINARY($1, Exp2__SUB, $3);}
                 
term             :  u_element
                 |  term  T_MUL  u_element
                    { $$ = Exp2__BINARY($1, Exp2__MUL, $3);}
                 |  term  T_DIV  u_element
                    { $$ = Exp2__BINARY($1, Exp2__DIV, $3);}

u_element        :  element
                 |  T_SUB  element
                    { $$ = Exp2__UNARY(Exp2__NEG, $2);}
                 |  T_FACTORIAL  element
                    { $$ = Exp2__UNARY(Exp2__FAC, $2);}
                 |  element T_POW  u_element
                    { $$ = Exp2__BINARY($1, Exp2__POW, $3);}

element          :  T_INTCONST
                 |  T_LPAREN  expression  T_RPAREN
                    { $$ = $2;}




