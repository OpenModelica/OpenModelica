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
#include "Absyn.h"
#include "yacclib.h"
#ifndef Absyn__STRING
#define Absyn__STRING(X) yyerror(X)
#endif
#else
#include "meta/meta_modelica.h"
void* getAST()
{
  return absyntree;
}

/* Exp */
extern struct record_description Absyn_Exp_INT__desc;
extern struct record_description Absyn_Exp_REAL__desc;
extern struct record_description Absyn_Exp_BINARY__desc;
extern struct record_description Absyn_Exp_UNARY__desc;
extern struct record_description Absyn_Exp_ASSIGN__desc;
extern struct record_description Absyn_Exp_IDENT__desc;
const char* WORKAROUND__Absyn_Exp_STRING__desc__fields[] = {"string"};
struct record_description WORKAROUND__Absyn_Exp_STRING__desc = {
    "Absyn_Exp_STRING",
    "Absyn.Exp.STRING",
    WORKAROUND__Absyn_Exp_STRING__desc__fields
};

#define Absyn__INT(X1) (mmc_mk_box2(3,&Absyn_Exp_INT__desc,(X1)))
#define Absyn__REAL(X1) (mmc_mk_box2(4,&Absyn_Exp_REAL__desc,(X1)))
#define Absyn__BINARY(X1,OP,X2) (mmc_mk_box4(5,&Absyn_Exp_BINARY__desc,(X1),(OP),(X2)))
#define Absyn__UNARY(OP,X1) (mmc_mk_box3(6,&Absyn_Exp_UNARY__desc,(OP),(X1)))
#define Absyn__ASSIGN(X1,X2) (mmc_mk_box3(7,&Absyn_Exp_ASSIGN__desc,(X1),(X2)))
#define Absyn__IDENT(X1) (mmc_mk_box2(8,&Absyn_Exp_IDENT__desc,(X1)))
#define Absyn__STRING(X1) (mmc_mk_box2(9,&WORKAROUND__Absyn_Exp_STRING__desc,(X1)))

/* BinOp */
extern struct record_description Absyn_BinOp_ADD__desc;
extern struct record_description Absyn_BinOp_SUB__desc;
extern struct record_description Absyn_BinOp_MUL__desc;
extern struct record_description Absyn_BinOp_DIV__desc;

#define Absyn__ADD (mmc_mk_box1(3,&Absyn_BinOp_ADD__desc))
#define Absyn__SUB (mmc_mk_box1(4,&Absyn_BinOp_SUB__desc))
#define Absyn__MUL (mmc_mk_box1(5,&Absyn_BinOp_MUL__desc))
#define Absyn__DIV (mmc_mk_box1(6,&Absyn_BinOp_DIV__desc))

/* UnOp */
extern struct record_description Absyn_UnOp_NEG__desc;

#define Absyn__NEG (mmc_mk_box1(3,&Absyn_UnOp_NEG__desc))
#endif

%}

%token T_SEMIC
%token T_ASSIGN
%token T_IDENT
%token T_INTCONST
%token T_REALCONST
%token T_STRINGCONST
%token T_LPAREN T_RPAREN
%token T_ADD
%token T_SUB
%token T_MUL
%token T_DIV
%token T_GARBAGE

%token T_ERR

%%

program         :  assignment
                        { absyntree = $1; }
                |  expression
                        { absyntree = $1; }

assignment      :  T_IDENT  T_ASSIGN  expression
                        { $$ = Absyn__ASSIGN($1, $3); }

expression      :  term
                        { $$ = $1;  }
                |  expression  weak_operator  term
                        { $$ = Absyn__BINARY($1, $2, $3);}

term            :  u_element
                        { $$ = $1;}
                |  term  strong_operator  u_element
                        { $$ = Absyn__BINARY($1, $2, $3);}

u_element       :  element
                        { $$ = $1;}
                |  unary_operator  element
                        { $$ = Absyn__UNARY($1, $2);}

element         :  T_INTCONST
                        { $$ = Absyn__INT($1);}
                |  T_REALCONST
                        { $$ = Absyn__REAL($1);}
                |  T_STRINGCONST
                        { $$ = Absyn__STRING($1);}
                |  T_IDENT
                        { $$ = Absyn__IDENT($1);}
                |  T_LPAREN  expression  T_RPAREN
                        { $$ = $2;}
                |  T_LPAREN  assignment  T_RPAREN
                        { $$ = $2;}

weak_operator   :  T_ADD
                        { $$ = Absyn__ADD;}
                |  T_SUB
                        { $$ = Absyn__SUB;}

strong_operator :  T_MUL
                        { $$ = Absyn__MUL;}
                |  T_DIV
                        { $$ = Absyn__DIV;}

unary_operator  :  T_SUB
                        { $$ = Absyn__NEG;}
