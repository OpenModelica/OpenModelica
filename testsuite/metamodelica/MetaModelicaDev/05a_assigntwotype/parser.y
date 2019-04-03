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
#include "AssignTwoType.h"
#ifndef AssignTwoType__STRING
#define AssignTwoType__STRING(X) yyerror(X)
#endif
#else
#include "meta/meta_modelica.h"
void* getAST()
{
  return absyntree;
}

/* Program */
extern struct record_description AssignTwoType_Program_PROGRAM__desc;

#define AssignTwoType__PROGRAM(X1,X2) (mmc_mk_box3(3,&AssignTwoType_Program_PROGRAM__desc,(X1),(X2)))

/* Exp */
extern struct record_description AssignTwoType_Exp_INT__desc;
extern struct record_description AssignTwoType_Exp_REAL__desc;
extern struct record_description AssignTwoType_Exp_BINARY__desc;
extern struct record_description AssignTwoType_Exp_UNARY__desc;
extern struct record_description AssignTwoType_Exp_ASSIGN__desc;
extern struct record_description AssignTwoType_Exp_IDENT__desc;
const char* WORKAROUND__AssignTwoType_Exp_STRING__desc__fields[] = {"string"};
struct record_description WORKAROUND__AssignTwoType_Exp_STRING__desc = {
    "AssignTwoType_Exp_STRING",
    "AssignTwoType.Exp.STRING",
    WORKAROUND__AssignTwoType_Exp_STRING__desc__fields
};

#define AssignTwoType__INT(X1) (mmc_mk_box2(3,&AssignTwoType_Exp_INT__desc,(X1)))
#define AssignTwoType__REAL(X1) (mmc_mk_box2(4,&AssignTwoType_Exp_REAL__desc,(X1)))
#define AssignTwoType__BINARY(X1,OP,X2) (mmc_mk_box4(5,&AssignTwoType_Exp_BINARY__desc,(X1),(OP),(X2)))
#define AssignTwoType__UNARY(OP,X1) (mmc_mk_box3(6,&AssignTwoType_Exp_UNARY__desc,(OP),(X1)))
#define AssignTwoType__ASSIGN(X1,X2) (mmc_mk_box3(7,&AssignTwoType_Exp_ASSIGN__desc,(X1),(X2)))
#define AssignTwoType__IDENT(X1) (mmc_mk_box2(8,&AssignTwoType_Exp_IDENT__desc,(X1)))
#define AssignTwoType__STRING(X1) (mmc_mk_box2(9,&WORKAROUND__AssignTwoType_Exp_STRING__desc,(X1)))

/* BinOp */
extern struct record_description AssignTwoType_BinOp_ADD__desc;
extern struct record_description AssignTwoType_BinOp_SUB__desc;
extern struct record_description AssignTwoType_BinOp_MUL__desc;
extern struct record_description AssignTwoType_BinOp_DIV__desc;

#define AssignTwoType__ADD (mmc_mk_box1(3,&AssignTwoType_BinOp_ADD__desc))
#define AssignTwoType__SUB (mmc_mk_box1(4,&AssignTwoType_BinOp_SUB__desc))
#define AssignTwoType__MUL (mmc_mk_box1(5,&AssignTwoType_BinOp_MUL__desc))
#define AssignTwoType__DIV (mmc_mk_box1(6,&AssignTwoType_BinOp_DIV__desc))

/* UnOp */
extern struct record_description AssignTwoType_UnOp_NEG__desc;

#define AssignTwoType__NEG (mmc_mk_box1(3,&AssignTwoType_UnOp_NEG__desc))
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

/* Yacc BNF grammar of the expression language Assigntwotypes */

program         :  assignments T_SEMIC expression
                        { absyntree = (void*) AssignTwoType__PROGRAM($1, $3);}

assignments     :  assignments  assignment
                        { $$ = (void*) mmc_mk_cons($2, $1);}
                |
                        { $$ = (void*) mmc_mk_nil();}

assignment      :  T_IDENT  T_ASSIGN  expression
                        { $$ = (void*) AssignTwoType__ASSIGN($1, $3);}

expression      :  term
                        { $$ = $1;}
                |  expression  weak_operator  term
                        { $$ = (void*) AssignTwoType__BINARY($1, $2, $3);}

term            :  u_element
                        { $$ = $1;}
                |  term  strong_operator  u_element
                        { $$ = (void*) AssignTwoType__BINARY($1, $2, $3);}

u_element       :  element
                        { $$ = $1;}
                |  unary_operator  element
                        { $$ = (void*) AssignTwoType__UNARY($1, $2);}

element         :  T_INTCONST
                        { $$ = (void*) AssignTwoType__INT($1);}
                |  T_REALCONST
                        { $$ = (void*) AssignTwoType__REAL($1);}
                |  T_STRINGCONST
                        { $$ = (void*) AssignTwoType__STRING($1); }
                |  T_IDENT
                        { $$ = (void*) AssignTwoType__IDENT($1);}
                |  T_LPAREN  expression  T_RPAREN
                        { $$ = $2;}
                |  T_LPAREN  assignment  T_RPAREN
                        { $$ = $2;}

weak_operator   :  T_ADD
                        { $$ = (void*) AssignTwoType__ADD;}
                |  T_SUB
                        { $$ = (void*) AssignTwoType__SUB;}

strong_operator :  T_MUL
                        { $$ = (void*) AssignTwoType__MUL;}
                |  T_DIV
                        { $$ = (void*) AssignTwoType__DIV;}

unary_operator  :  T_SUB
                        { $$ = (void*) AssignTwoType__NEG;}


