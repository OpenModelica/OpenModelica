%{
#include <stdio.h>

void yyerror(char *str);
typedef void *rml_t;
#define YYSTYPE rml_t
rml_t absyntree;

void* parse()
{
  absyntree = NULL;
  yyparse();
  return absyntree;
}

#ifdef RML
#include "yacclib.h"
#include "Absyn.h"
#else
#include "meta/meta_modelica.h"

/* Namedecl */
extern struct record_description Absyn_Decl_NAMEDECL__desc;

#define Absyn__NAMEDECL(X1,X2)       (mmc_mk_box3(3,&Absyn_Decl_NAMEDECL__desc,X1,X2))

/* Program */
extern struct record_description Absyn_Prog_PROG__desc;

#define Absyn__PROG(X1,X2)       (mmc_mk_box3(3,&Absyn_Prog_PROG__desc,X1,X2))

/* BinOp */
extern struct record_description Absyn_BinOp_ADD__desc;
extern struct record_description Absyn_BinOp_SUB__desc;
extern struct record_description Absyn_BinOp_MUL__desc;
extern struct record_description Absyn_BinOp_DIV__desc;

#define Absyn__ADD (mmc_mk_box1(3,&Absyn_BinOp_ADD__desc))
#define Absyn__SUB (mmc_mk_box1(4,&Absyn_BinOp_SUB__desc))
#define Absyn__MUL (mmc_mk_box1(5,&Absyn_BinOp_MUL__desc))
#define Absyn__DIV (mmc_mk_box1(6,&Absyn_BinOp_DIV__desc))

/* RelOp */
extern struct record_description Absyn_RelOp_EQ__desc;
extern struct record_description Absyn_RelOp_GT__desc;
extern struct record_description Absyn_RelOp_LT__desc;
extern struct record_description Absyn_RelOp_LE__desc;
extern struct record_description Absyn_RelOp_GE__desc;
extern struct record_description Absyn_RelOp_NE__desc;

#define Absyn__EQ (mmc_mk_box1(3,&Absyn_RelOp_EQ__desc))
#define Absyn__GT (mmc_mk_box1(4,&Absyn_RelOp_GT__desc))
#define Absyn__LT (mmc_mk_box1(5,&Absyn_RelOp_LT__desc))
#define Absyn__LE (mmc_mk_box1(6,&Absyn_RelOp_LE__desc))
#define Absyn__GE (mmc_mk_box1(7,&Absyn_RelOp_GE__desc))
#define Absyn__NE (mmc_mk_box1(8,&Absyn_RelOp_NE__desc))

/* UnOp */
extern struct record_description Absyn_UnOp_NEG__desc;

#define Absyn__NEG (mmc_mk_box1(3,&Absyn_UnOp_NEG__desc))

/* Exp */
extern struct record_description Absyn_Exp_INT__desc;
extern struct record_description Absyn_Exp_IDENT__desc;
extern struct record_description Absyn_Exp_BINARY__desc;
extern struct record_description Absyn_Exp_RELATION__desc;

#define Absyn__INT(X1)            (mmc_mk_box2(3,&Absyn_Exp_INT__desc,X1))
#define Absyn__IDENT(X1)          (mmc_mk_box2(4,&Absyn_Exp_IDENT__desc,X1))
#define Absyn__BINARY(X1,OP,X2)   (mmc_mk_box4(5,&Absyn_Exp_BINARY__desc,X1,OP,X2))
#define Absyn__RELATION(X1,OP,X2) (mmc_mk_box4(6,&Absyn_Exp_RELATION__desc,X1,OP,X2))

/* Stmt */
extern struct record_description Absyn_Stmt_ASSIGN__desc;
extern struct record_description Absyn_Stmt_IF__desc;
extern struct record_description Absyn_Stmt_WHILE__desc;
extern struct record_description Absyn_Stmt_TODO__desc;
extern struct record_description Absyn_Stmt_READ__desc;
extern struct record_description Absyn_Stmt_WRITE__desc;
extern struct record_description Absyn_Stmt_SEQ__desc;
extern struct record_description Absyn_Stmt_SKIP__desc;

#define Absyn__ASSIGN(X1,X2)   (mmc_mk_box3(3,&Absyn_Stmt_ASSIGN__desc,X1,X2))
#define Absyn__IF(X1,X2,X3)    (mmc_mk_box4(4,&Absyn_Stmt_IF__desc,X1,X2,X3))
#define Absyn__WHILE(X1,X2)    (mmc_mk_box3(5,&Absyn_Stmt_WHILE__desc,X1,X2))
#define Absyn__TODO(X1,X2)     (mmc_mk_box3(6,&Absyn_Stmt_TODO__desc,X1,X2))
#define Absyn__READ(X1)        (mmc_mk_box2(7,&Absyn_Stmt_READ__desc,X1))
#define Absyn__WRITE(X1)       (mmc_mk_box2(8,&Absyn_Stmt_WRITE__desc,X1))
#define Absyn__SEQ(X1,X2)      (mmc_mk_box3(9,&Absyn_Stmt_SEQ__desc,X1,X2))
#define Absyn__SKIP            (mmc_mk_box1(10,&Absyn_Stmt_SKIP__desc))

#endif 
%}

%token T_READ
%token T_WRITE
%token T_ASSIGN
%token T_IF
%token T_THEN
%token T_ENDIF
%token T_ELSE
%token T_TO
%token T_DO
%token T_END
%token T_WHILE
%token T_LPAREN
%token T_RPAREN
%token T_IDENT
%token T_INTCONST
%token T_EQ
%token T_LE
%token T_LT
%token T_GT
%token T_GE
%token T_NE
%token T_ADD
%token T_SUB
%token T_MUL
%token T_DIV
%token T_SEMIC

%%

/* Yacc BNF grammar of the PAM language */

program               :  series
                                { absyntree = $1; }
series                :  statement
                                { $$ = Absyn__SEQ($1, Absyn__SKIP); }
                      |  statement series
                                { $$ = Absyn__SEQ($1, $2); }

statement             :  input_statement T_SEMIC
                                { $$ = $1; }
                      |  output_statement T_SEMIC
                                { $$ = $1; }
                      |  assignment_statement T_SEMIC
                                { $$ = $1; }
                      |  conditional_statement
                                { $$ = $1; }
                      |  definite_loop
                                { $$ = $1; }
                      |  while_loop
                                { $$ = $1; }

input_statement       :  T_READ  variable_list
                                { $$ = Absyn__READ($2); }

output_statement      :  T_WRITE  variable_list
                                { $$ = Absyn__WRITE($2); }

variable_list         :  variable
                                { $$ = mmc_mk_cons($1, mmc_mk_nil()); }
                      |  variable variable_list
                                { $$ = mmc_mk_cons($1, $2); }

assignment_statement  :  variable  T_ASSIGN  expression
                                { $$ = Absyn__ASSIGN($1, $3); }

conditional_statement :  T_IF comparison T_THEN series T_ENDIF
                                { $$ = Absyn__IF($2, $4, Absyn__SKIP); }
                      |  T_IF comparison T_THEN series 
                                         T_ELSE series T_ENDIF
                                { $$ = Absyn__IF($2, $4, $6); }

definite_loop         :  T_TO expression T_DO series T_END
                                { $$ = Absyn__TODO($2, $4); }

while_loop            :  T_WHILE comparison T_DO series T_END
                                { $$ = Absyn__WHILE($2, $4); }

expression       :  term
                                { $$ = $1; }
                 |  expression  weak_operator  term
                                { $$ = Absyn__BINARY($1, $2, $3); }

term             :  element
                                { $$ = $1; }
                 |  term  strong_operator  element
                                { $$ = Absyn__BINARY($1, $2, $3); }

element          :  constant
                                { $$ = $1; }
                 |  variable
                                { $$ = Absyn__IDENT($1); }
                 |  T_LPAREN  expression  T_RPAREN
                                { $$ = $2; }

comparison       :  expression  relation  expression
                                { $$ = Absyn__RELATION($1, $2, $3); }

variable         :  T_IDENT
                                { $$ = $1; }
constant         :  T_INTCONST
                                { $$ = $1; }

relation         : T_EQ { $$ = Absyn__EQ;}
                 | T_LE { $$ = Absyn__LE;}
                 | T_LT { $$ = Absyn__LT;}
                 | T_GT { $$ = Absyn__GT;}
                 | T_GE { $$ = Absyn__GE;}
                 | T_NE { $$ = Absyn__NE;}

weak_operator    : T_ADD { $$ = Absyn__ADD;}
                 | T_SUB { $$ = Absyn__SUB;}

strong_operator  : T_MUL { $$ = Absyn__MUL;}
                 | T_DIV { $$ = Absyn__DIV;}

%%

void yyerror(char *str) {
}
