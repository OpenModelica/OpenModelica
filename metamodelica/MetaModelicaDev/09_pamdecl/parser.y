%{
#include <stdio.h>

void yyerror(char *str);
typedef void *rml_t;
#define YYSTYPE rml_t
rml_t absyntree;

void* parse()
{
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

/* Expr */
extern struct record_description Absyn_Expr_INTCONST__desc;
extern struct record_description Absyn_Expr_REALCONST__desc;
extern struct record_description Absyn_Expr_BINARY__desc;
extern struct record_description Absyn_Expr_UNARY__desc;
extern struct record_description Absyn_Expr_RELATION__desc;
extern struct record_description Absyn_Expr_VARIABLE__desc;

#define Absyn__INTCONST(X1)       (mmc_mk_box2(3,&Absyn_Expr_INTCONST__desc,X1))
#define Absyn__REALCONST(X1)      (mmc_mk_box2(4,&Absyn_Expr_REALCONST__desc,X1))
#define Absyn__BINARY(X1,OP,X2)   (mmc_mk_box4(5,&Absyn_Expr_BINARY__desc,X1,OP,X2))
#define Absyn__UNARY(OP,X1)       (mmc_mk_box3(6,&Absyn_Expr_UNARY__desc,OP,X1))
#define Absyn__RELATION(X1,OP,X2) (mmc_mk_box4(7,&Absyn_Expr_RELATION__desc,X1,OP,X2))
#define Absyn__VARIABLE(X1)       (mmc_mk_box2(8,&Absyn_Expr_VARIABLE__desc,X1))

/* Stmt */
extern struct record_description Absyn_Stmt_ASSIGN__desc;
extern struct record_description Absyn_Stmt_WRITE__desc;
extern struct record_description Absyn_Stmt_NOOP__desc;
extern struct record_description Absyn_Stmt_IF__desc;
extern struct record_description Absyn_Stmt_WHILE__desc;
extern struct record_description Absyn_Stmt_VARIABLE__desc;

#define Absyn__ASSIGN(X1,X2) (mmc_mk_box3(3,&Absyn_Stmt_ASSIGN__desc,X1,X2))
#define Absyn__WRITE(X1)     (mmc_mk_box2(4,&Absyn_Stmt_WRITE__desc,X1))
#define Absyn__NOOP          (mmc_mk_box1(5,&Absyn_Stmt_NOOP__desc))
#define Absyn__IF(X1,X2,X3)  (mmc_mk_box4(6,&Absyn_Stmt_IF__desc,X1,X2,X3))
#define Absyn__WHILE(X1,X2)  (mmc_mk_box3(7,&Absyn_Stmt_WHILE__desc,X1,X2))

#endif 
%}
 
%token T_PROGRAM
%token T_BODY
%token T_END
%token T_IF
%token T_THEN
%token T_ELSE
%token T_WHILE
%token T_DO
 
%token T_WRITE
%token T_ASSIGN
%token T_SEMICOLON
%token T_COLON
 
%token T_CONST_INT
%token T_CONST_REAL
%token T_CONST_BOOL
%token T_IDENT
 
%token T_LPAREN T_RPAREN
 
%nonassoc T_LT T_LE T_GT T_GE T_NE T_EQ
%left T_PLUS  T_MINUS
%left T_TIMES T_DIVIDE
%left T_UMINUS
 
%token T_GARBAGE
 
%%
 
program
        : T_PROGRAM decl_list T_BODY stmt_list T_END T_PROGRAM
        { absyntree = Absyn__PROG($2,$4); }
 
decl_list
        : 
            { $$ = mmc_mk_nil();}
        | decl decl_list
            { $$ = mmc_mk_cons($1,$2); }
 
decl
        : T_IDENT T_COLON T_IDENT T_SEMICOLON
        { $$ = Absyn__NAMEDECL($1,$3);}
 
stmt_list
        : 
            { $$ = mmc_mk_nil();}
        | stmt stmt_list
            { $$ = mmc_mk_cons($1,$2); }
 
stmt
        : simple_stmt T_SEMICOLON
        | combined_stmt
 
simple_stmt
        : assign_stmt
        | write_stmt
        | noop_stmt
 
combined_stmt
        : if_stmt
        | while_stmt
 
assign_stmt
: T_IDENT T_ASSIGN expr
            { $$ = Absyn__ASSIGN($1,$3);}
 
write_stmt
        : T_WRITE expr
            { $$ = Absyn__WRITE($2);}
 
noop_stmt
        :
            { $$ = Absyn__NOOP;}
 
if_stmt
        : T_IF expr T_THEN stmt_list T_ELSE stmt_list T_END T_IF
            { $$ = Absyn__IF($2,$4,$6); }
        | T_IF expr T_THEN stmt_list T_END T_IF
            { $$ = Absyn__IF($2,$4,mmc_mk_cons(Absyn__NOOP,mmc_mk_nil())); }
 
while_stmt
        : T_WHILE expr T_DO stmt_list T_END T_WHILE
            { $$ = Absyn__WHILE($2,$4); }
 
expr
        : T_CONST_INT
        | T_CONST_REAL
        | T_CONST_BOOL
        | T_LPAREN expr T_RPAREN
            { $$ = $2;}
        | T_IDENT
            { $$ = Absyn__VARIABLE($1);}
        | expr_bin
        | expr_un
        | expr_rel
 
expr_bin
        : expr T_PLUS expr
            { $$ = Absyn__BINARY($1, Absyn__ADD,$3);}
        | expr T_MINUS expr
            { $$ = Absyn__BINARY($1, Absyn__SUB,$3);}
        | expr T_TIMES expr
            { $$ = Absyn__BINARY($1, Absyn__MUL,$3);}
        | expr T_DIVIDE expr
            { $$ = Absyn__BINARY($1, Absyn__DIV,$3);}
        
expr_un
        : T_MINUS expr %prec T_UMINUS
            { $$ = Absyn__UNARY(Absyn__ADD,$2);}
 
expr_rel
        : expr T_LT expr
            { $$ = Absyn__RELATION($1,Absyn__LT,$3);}
        | expr T_LE expr
            { $$ = Absyn__RELATION($1,Absyn__LE,$3);}
        | expr T_GT expr
            { $$ = Absyn__RELATION($1,Absyn__GT,$3);}
        | expr T_GE expr
            { $$ = Absyn__RELATION($1,Absyn__GE,$3);}
        | expr T_NE expr
            { $$ = Absyn__RELATION($1,Absyn__NE,$3);}
        | expr T_EQ expr
            { $$ = Absyn__RELATION($1,Absyn__EQ,$3);}
 
%%

void yyerror(char *str) {
        printf("%s on line %d!\n", str, -1);
}
