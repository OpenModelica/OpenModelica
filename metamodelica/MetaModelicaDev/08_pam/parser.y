%{
#include <stdio.h>

typedef void *rml_t;
#define YYSTYPE rml_t
rml_t absyntree;

void yyerror(char *str);

void* parse()
{
  yyparse();
  return absyntree;
}

#ifdef RML
#include "yacclib.h"
#include "Pam.h"
#else
#include "meta/meta_modelica.h"

/* BinOp */
extern struct record_description Pam_BinOp_ADD__desc;
extern struct record_description Pam_BinOp_SUB__desc;
extern struct record_description Pam_BinOp_MUL__desc;
extern struct record_description Pam_BinOp_DIV__desc;

#define Pam__ADD (mmc_mk_box1(3,&Pam_BinOp_ADD__desc))
#define Pam__SUB (mmc_mk_box1(4,&Pam_BinOp_SUB__desc))
#define Pam__MUL (mmc_mk_box1(5,&Pam_BinOp_MUL__desc))
#define Pam__DIV (mmc_mk_box1(6,&Pam_BinOp_DIV__desc))

/* RelOp */
extern struct record_description Pam_RelOp_EQ__desc;
extern struct record_description Pam_RelOp_GT__desc;
extern struct record_description Pam_RelOp_LT__desc;
extern struct record_description Pam_RelOp_LE__desc;
extern struct record_description Pam_RelOp_GE__desc;
extern struct record_description Pam_RelOp_NE__desc;

#define Pam__EQ (mmc_mk_box1(3,&Pam_RelOp_EQ__desc))
#define Pam__GT (mmc_mk_box1(4,&Pam_RelOp_GT__desc))
#define Pam__LT (mmc_mk_box1(5,&Pam_RelOp_LT__desc))
#define Pam__LE (mmc_mk_box1(6,&Pam_RelOp_LE__desc))
#define Pam__GE (mmc_mk_box1(7,&Pam_RelOp_GE__desc))
#define Pam__NE (mmc_mk_box1(8,&Pam_RelOp_NE__desc))

/* Exp */
extern struct record_description Pam_Exp_INT__desc;
extern struct record_description Pam_Exp_IDENT__desc;
extern struct record_description Pam_Exp_BINARY__desc;
extern struct record_description Pam_Exp_RELATION__desc;

#define Pam__INT(X1)            (mmc_mk_box2(3,&Pam_Exp_INT__desc,(X1)))
#define Pam__IDENT(X1)          (mmc_mk_box2(4,&Pam_Exp_IDENT__desc,(X1)))
#define Pam__BINARY(X1,X2,X3)   (mmc_mk_box4(5,&Pam_Exp_BINARY__desc,(X1),(X2),(X3)))
#define Pam__RELATION(X1,X2,X3) (mmc_mk_box4(6,&Pam_Exp_RELATION__desc,(X1),(X2),(X3)))

/* Stmt */
extern struct record_description Pam_Stmt_ASSIGN__desc;
extern struct record_description Pam_Stmt_IF__desc;
extern struct record_description Pam_Stmt_WHILE__desc;
extern struct record_description Pam_Stmt_TODO__desc;
extern struct record_description Pam_Stmt_READ__desc;
extern struct record_description Pam_Stmt_WRITE__desc;
extern struct record_description Pam_Stmt_SEQ__desc;
extern struct record_description Pam_Stmt_SKIP__desc;

#define Pam__ASSIGN(X1,X2) (mmc_mk_box3(3,&Pam_Stmt_ASSIGN__desc,(X1),(X2)))
#define Pam__IF(X1,X2,X3)  (mmc_mk_box4(4,&Pam_Stmt_IF__desc,(X1),(X2),(X3)))
#define Pam__WHILE(X1,X2)  (mmc_mk_box3(5,&Pam_Stmt_WHILE__desc,(X1),(X2)))
#define Pam__TODO(X1,X2)   (mmc_mk_box3(6,&Pam_Stmt_TODO__desc,(X1),(X2)))
#define Pam__READ(X1)      (mmc_mk_box2(7,&Pam_Stmt_READ__desc,(X1)))
#define Pam__WRITE(X1)     (mmc_mk_box2(8,&Pam_Stmt_WRITE__desc,(X1)))
#define Pam__SEQ(X1,X2)    (mmc_mk_box3(9,&Pam_Stmt_SEQ__desc,(X1),(X2)))
#define Pam__SKIP          (mmc_mk_box1(10,&Pam_Stmt_SKIP__desc))

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
%token T_COMMENT

%%

/* Yacc BNF grammar of the PAM language */

program               :  series
                                { absyntree = $1; }
series                :  statement
                                { $$ = Pam__SEQ($1, Pam__SKIP); }
                      |  statement series
                                { $$ = Pam__SEQ($1, $2); }

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
                                { $$ = Pam__READ($2); }

output_statement      :  T_WRITE  variable_list
                                { $$ = Pam__WRITE($2); }

variable_list         :  variable
                                { $$ = mmc_mk_cons($1, mmc_mk_nil()); }
                      |  variable variable_list
                                { $$ = mmc_mk_cons($1, $2); }

assignment_statement  :  variable  T_ASSIGN  expression
                                { $$ = Pam__ASSIGN($1, $3); }

conditional_statement :  T_IF comparison T_THEN series T_ENDIF
                                { $$ = Pam__IF($2, $4, Pam__SKIP); }
                      |  T_IF comparison T_THEN series 
                                         T_ELSE series T_ENDIF
                                { $$ = Pam__IF($2, $4, $6); }

definite_loop         :  T_TO expression T_DO series T_END
                                { $$ = Pam__TODO($2, $4); }

while_loop            :  T_WHILE comparison T_DO series T_END
                                { $$ = Pam__WHILE($2, $4); }

expression       :  term
                                { $$ = $1; }
                 |  expression  weak_operator  term
                                { $$ = Pam__BINARY($1, $2, $3); }

term             :  element
                                { $$ = $1; }
                 |  term  strong_operator  element
                                { $$ = Pam__BINARY($1, $2, $3); }

element          :  constant
                                { $$ = $1; }
                 |  variable
                                { $$ = Pam__IDENT($1); }
                 |  T_LPAREN  expression  T_RPAREN
                                { $$ = $2; }

comparison       :  expression  relation  expression
                                { $$ = Pam__RELATION($1, $2, $3); }

variable         :  T_IDENT
                                { $$ = $1; }
constant         :  T_INTCONST
                                { $$ = $1; }

relation         : T_EQ { $$ = Pam__EQ;}
                 | T_LE { $$ = Pam__LE;}
                 | T_LT { $$ = Pam__LT;}
                 | T_GT { $$ = Pam__GT;}
                 | T_GE { $$ = Pam__GE;}
                 | T_NE { $$ = Pam__NE;}

weak_operator    : T_ADD { $$ = Pam__ADD;}
                 | T_SUB { $$ = Pam__SUB;}

strong_operator  : T_MUL { $$ = Pam__MUL;}
                 | T_DIV { $$ = Pam__DIV;}

%%

void yyerror(char *str) {
        extern int linenr;
        printf("%s on line %d!\n", str, linenr);
}

