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
#include "yacclib.h"
#include "Assignment.h"
#else
#include "meta/meta_modelica.h"
void* getAST()
{
  return absyntree;
}


/* Program */
extern struct record_description Assignment_Program_PROGRAM__desc;
#define Assignment__PROGRAM(X1,X2) (mmc_mk_box3(3,&Assignment_Program_PROGRAM__desc,(X1),(X2)))

/* Exp */
extern struct record_description Assignment_Exp_BINARY__desc;
extern struct record_description Assignment_Exp_UNARY__desc;
extern struct record_description Assignment_Exp_ASSIGN__desc;
extern struct record_description Assignment_Exp_IDENT__desc;

#define Assignment__BINARY(X1,OP,X2) (mmc_mk_box4(4,&Assignment_Exp_BINARY__desc,(X1),(OP),(X2)))
#define Assignment__UNARY(OP,X1) (mmc_mk_box3(5,&Assignment_Exp_UNARY__desc,(OP),(X1)))
#define Assignment__ASSIGN(X1,X2) (mmc_mk_box3(6,&Assignment_Exp_ASSIGN__desc,(X1),(X2)))
#define Assignment__IDENT(X1) (mmc_mk_box2(7,&Assignment_Exp_IDENT__desc,(X1)))

/* BinOp */
extern struct record_description Assignment_BinOp_ADD__desc;
extern struct record_description Assignment_BinOp_SUB__desc;
extern struct record_description Assignment_BinOp_MUL__desc;
extern struct record_description Assignment_BinOp_DIV__desc;

#define Assignment__ADD (mmc_mk_box1(3,&Assignment_BinOp_ADD__desc))
#define Assignment__SUB (mmc_mk_box1(4,&Assignment_BinOp_SUB__desc))
#define Assignment__MUL (mmc_mk_box1(5,&Assignment_BinOp_MUL__desc))
#define Assignment__DIV (mmc_mk_box1(6,&Assignment_BinOp_DIV__desc))

/* UnOp */
extern struct record_description Assignment_UnOp_NEG__desc;

#define Assignment__NEG (mmc_mk_box1(3,&Assignment_UnOp_NEG__desc))
#endif

%}

%token T_SEMIC
%token T_ASSIGN
%token T_IDENT
%token T_INTCONST
%token T_LPAREN T_RPAREN
%token T_ADD
%token T_SUB
%token T_MUL
%token T_DIV
%token T_GARBAGE

%token T_ERR

%%

/* Yacc BNF grammar of the expression language Assignments */

program         :  assignments T_SEMIC expression
                        { absyntree = Assignment__PROGRAM($1, $3);}

assignments     :  assignments  assignment
                        { $$ = mmc_mk_cons($2, $1);}
                |
                        { $$ = mmc_mk_nil();}

assignment      :  T_IDENT  T_ASSIGN  expression
                        { $$ = Assignment__ASSIGN($1, $3);}

expression      :  term
                        { $$ = $1;}
                |  expression  weak_operator  term
                        { $$ = Assignment__BINARY($1, $2, $3);}

term            :  u_element
                        { $$ = $1;}
                |  term  strong_operator  u_element
                        { $$ = Assignment__BINARY($1, $2, $3);}

u_element       :  element
                        { $$ = $1;}
                |  unary_operator  element
                        { $$ = Assignment__UNARY($1, $2);}

element         :  T_INTCONST
                        { $$ = $1;}
                |  T_IDENT
                        { $$ = Assignment__IDENT($1);}
                |  T_LPAREN  expression  T_RPAREN
                        { $$ = $2;}
                |  T_LPAREN  assignment  T_RPAREN
                        { $$ = $2;}

weak_operator   :  T_ADD
                        { $$ = Assignment__ADD;}
                |  T_SUB
                        { $$ = Assignment__SUB;}

strong_operator :  T_MUL
                        { $$ = Assignment__MUL;}
                |  T_DIV
                        { $$ = Assignment__DIV;}

unary_operator  :  T_SUB
                        { $$ = Assignment__NEG;}


