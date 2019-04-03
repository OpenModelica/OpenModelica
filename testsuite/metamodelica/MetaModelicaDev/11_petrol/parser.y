/* parser.y */

%{
#include <stdarg.h>
#include <stdio.h>

#include "parsutil.h"

#ifdef RML
#include "yacclib.h"
#include "lexerPetrol.h"
#else
#include "meta/meta_modelica.h"
#endif

typedef void *rml_t;
void* absyntree;
void yyerror(const char *msg);

void* parse() {
  absyntree = NULL;
  if (yyparse() != 0) {
    fprintf(stderr, "Error: Parsing failed\n");
    absyntree = pu_PROG(mmc_mk_scon("#ERROR#"), pu_BLOCK(mmc_mk_nil(),mmc_mk_nil(),mmc_mk_nil(),mmc_mk_nil(),pu_Stmt_SKIP()));
  }
  return absyntree;
}
%}

%union {
    void	*voidp;
    enum uop	uop;
    enum bop	bop;
    enum rop	rop;
    enum eop	eop;
}

/* terminals */
%token T_AMPER
%token T_AND
%token T_ARRAY
%token T_ASSIGN
%token T_BEGIN
%token T_CARET
%token T_CAST
%token T_COLON
%token T_COMMA
%token T_CONST
%token T_DO
%token T_DOT
%token T_ELSE
%token T_ELSIF
%token T_END
%token T_EQ
%token T_EXTERN
%token T_FUNCTION
%token T_GE
%token T_GT
%token <voidp> T_ICON
%token <voidp> T_IDENT
%token T_IDIV
%token T_IF
%token T_IMOD
%token T_LBRACK
%token T_LE
%token T_LPAREN
%token T_LT
%token T_MINUS
%token T_MUL
%token T_NE
%token T_NOT
%token T_OF
%token T_OR
%token T_PLUS
%token T_PROCEDURE
%token T_PROGRAM
%token T_RBRACK
%token <voidp> T_RCON
%token T_RDIV
%token T_RECORD
%token T_RETURN
%token T_RPAREN
%token T_SEMI
%token T_THEN
%token T_TYPE
%token T_VAR
%token T_WHILE

/* non-terminals */
%type <voidp> block body
%type <voidp> const_part const_decls const_decl constant
%type <voidp> type_part type_decls type_decl type
%type <voidp> var_part var_decls var_decl
%type <voidp> sub_part sub_decls sub_decl opt_param_list param_list param
%type <voidp> comp_stmt stmt_list stmt elsif_part else_part
%type <voidp> opt_exp_list exp_list exp eq_exp rel_exp add_exp
%type <voidp> mul_exp unary_exp postfix_exp primary_exp
%type <uop> unary_op
%type <bop> mul_op add_op
%type <rop> rel_op
%type <eop> eq_op

/* start symbol */
%start program

%%

program		: T_PROGRAM T_IDENT T_SEMI block T_DOT
			{ absyntree = pu_PROG($2, $4); YYACCEPT; }

block		: const_part type_part var_part sub_part comp_stmt
			{ $$ = pu_BLOCK($1, $2, $3, $4, $5); }

body		: T_EXTERN
			{ $$ = mmc_mk_none(); }
		| block
			{ $$ = mmc_mk_some($1); }

/*
 * CONSTANTS
 */

const_part	: T_CONST const_decls
			{ $$ = $2; }
		| /*empty*/
			{ $$ = mmc_mk_nil(); }

const_decls	: const_decl
			{ $$ = mmc_mk_cons($1, mmc_mk_nil()); }
		| const_decl const_decls
			{ $$ = mmc_mk_cons($1, $2); }

const_decl	: T_IDENT T_EQ constant T_SEMI
			{ $$ = pu_CONBND($1, $3); }

constant	: T_ICON
			{ $$ = pu_Constant_INTcon($1); }
		| T_RCON
			{ $$ = pu_Constant_REALcon($1); }
		| T_IDENT
			{ $$ = pu_Constant_IDENTcon($1); }

/*
 * TYPES
 */

type_part	: T_TYPE type_decls
			{ $$ = $2; }
		| /*empty*/
			{ $$ = mmc_mk_nil(); }

type_decls	: type_decl
			{ $$ = mmc_mk_cons($1, mmc_mk_nil()); }
		| type_decl type_decls
			{ $$ = mmc_mk_cons($1, $2); }

type_decl	: T_IDENT T_EQ type T_SEMI
			{ $$ = pu_TYBND($1, $3); }

type		: T_IDENT
			{ $$ = pu_Ty_NAME($1); }
		| T_CARET type
			{ $$ = pu_Ty_PTR($2); }
		| T_ARRAY T_LBRACK constant T_RBRACK T_OF type
			{ $$ = pu_Ty_ARR($3, $6); }
		| T_RECORD var_decls T_END
			{ $$ = pu_Ty_REC($2); }

/*
 * VARIABLES
 */

var_part	: T_VAR var_decls
			{ $$ = $2; }
		| /*empty*/
			{ $$ = mmc_mk_nil(); }

var_decls	: var_decl
			{ $$ = mmc_mk_cons($1, mmc_mk_nil()); }
		| var_decl var_decls
			{ $$ = mmc_mk_cons($1, $2); }

var_decl	: T_IDENT T_COLON type T_SEMI
			{ $$ = pu_VARBND($1, $3); }

/*
 * SUB-PROGRAMS
 */

sub_part	: sub_decls
		| /*empty*/
			{ $$ = mmc_mk_nil(); }

sub_decls	: sub_decl
			{ $$ = mmc_mk_cons($1, mmc_mk_nil()); }
		| sub_decl sub_decls
			{ $$ = mmc_mk_cons($1, $2); }

sub_decl	: T_PROCEDURE T_IDENT opt_param_list T_SEMI body T_SEMI
			{ $$ = pu_SubBnd_PROCBND($2, $3, $5); }
		| T_FUNCTION T_IDENT opt_param_list T_COLON type T_SEMI body T_SEMI
			{ $$ = pu_SubBnd_FUNCBND($2, $3, $5, $7); }

opt_param_list	: T_LPAREN param_list T_RPAREN
			{ $$ = $2; }
		| T_LPAREN T_RPAREN
			{ $$ = mmc_mk_nil(); }
		| /*empty*/
			{ $$ = mmc_mk_nil(); }

param_list	: param
			{ $$ = mmc_mk_cons($1, mmc_mk_nil()); }
		| param T_SEMI param_list
			{ $$ = mmc_mk_cons($1, $3); }

param		: T_IDENT T_COLON type
			{ $$ = pu_VARBND($1, $3); }

/*
 * STATEMENTS
 */

comp_stmt	: T_BEGIN stmt_list T_END
			{ $$ = $2; }

stmt_list	: stmt
		| stmt T_SEMI stmt_list
			{ $$ = pu_Stmt_SEQ($1, $3); }

stmt		: T_IF exp T_THEN stmt_list elsif_part
			{ $$ = pu_Stmt_IF($2, $4, $5); }
		| T_WHILE exp T_DO stmt_list T_END
			{ $$ = pu_Stmt_WHILE($2, $4); }
		| T_IDENT T_LPAREN opt_exp_list T_RPAREN
			{ $$ = pu_Stmt_PCALL($1, $3); }
		| unary_exp T_ASSIGN exp
			{ $$ = pu_Stmt_ASSIGN($1, $3); }
		| T_RETURN exp
			{ $$ = pu_Stmt_FRETURN($2); }
		| T_RETURN
			{ $$ = pu_Stmt_PRETURN(); }
		| /*empty*/
			{ $$ = pu_Stmt_SKIP(); }

elsif_part	: T_ELSIF exp T_THEN stmt_list elsif_part
			{ $$ = pu_Stmt_IF($2, $4, $5); }
		| else_part

else_part	: T_ELSE stmt_list T_END
			{ $$ = $2; }
		| T_END
			{ $$ = pu_Stmt_SKIP(); }

/*
 * EXPRESSIONS
 */

opt_exp_list	: exp_list
		| /*empty*/
			{ $$ = mmc_mk_nil(); }

exp_list	: exp
			{ $$ = mmc_mk_cons($1, mmc_mk_nil()); }
		| exp T_COMMA exp_list
			{ $$ = mmc_mk_cons($1, $3); }

exp		: eq_exp

eq_exp		: rel_exp
		| eq_exp eq_op rel_exp
			{ $$ = pu_Exp_EQUALITY($1, $2, $3); }

eq_op		: T_EQ
			{ $$ = EOP_EQ; }
		| T_NE
			{ $$ = EOP_NE; }

rel_exp		: add_exp
		| rel_exp rel_op add_exp
			{ $$ = pu_Exp_RELATION($1, $2, $3); }

rel_op		: T_LT
			{ $$ = ROP_LT; }
		| T_LE
			{ $$ = ROP_LE; }
		| T_GE
			{ $$ = ROP_GE; }
		| T_GT
			{ $$ = ROP_GT; }

add_exp		: mul_exp
		| add_exp add_op mul_exp
			{ $$ = pu_Exp_BINARY($1, $2, $3); }

add_op		: T_OR
			{ $$ = BOP_IOR; }
		| T_PLUS
			{ $$ = BOP_ADD; }
		| T_MINUS
			{ $$ = BOP_SUB; }

mul_exp		: unary_exp
		| mul_exp mul_op unary_exp
			{ $$ = pu_Exp_BINARY($1, $2, $3); }

mul_op		: T_AND
			{ $$ = BOP_IAND; }
		| T_MUL
			{ $$ = BOP_MUL; }
		| T_RDIV
			{ $$ = BOP_RDIV; }
		| T_IDIV
			{ $$ = BOP_IDIV; }
		| T_IMOD
			{ $$ = BOP_IMOD; }

unary_exp	: postfix_exp
		| unary_op unary_exp
			{ $$ = pu_Exp_UNARY($1, $2); }

unary_op	: T_AMPER
			{ $$ = UOP_ADDR; }
		| T_NOT
			{ $$ = UOP_NOT; }
		| T_PLUS
			{ $$ = UOP_PLUS; }
		| T_MINUS
			{ $$ = UOP_MINUS; }

postfix_exp	: primary_exp
		| postfix_exp T_CARET
			{ $$ = pu_Exp_UNARY(UOP_INDIR, $1); }
		| postfix_exp T_DOT T_IDENT
			{ $$ = pu_Exp_FIELD($1, $3); }
		| postfix_exp T_LBRACK exp T_RBRACK
			{ $$ = pu_Exp_UNARY(UOP_INDIR,
					    pu_Exp_BINARY($1, BOP_ADD, $3)); }
		| T_IDENT T_LPAREN opt_exp_list T_RPAREN
			{ $$ = pu_Exp_FCALL($1, $3); }
		| T_CAST T_LPAREN type T_COMMA exp T_RPAREN
			{ $$ = pu_Exp_CAST($3, $5); }

primary_exp	: T_IDENT
			{ $$ = pu_Exp_IDENT($1); }
		| T_ICON
			{ $$ = pu_Exp_INT($1); }
		| T_RCON
			{ $$ = pu_Exp_REAL($1); }
		| T_LPAREN exp T_RPAREN
			{ $$ = $2; }
%%

#if	YYDEBUG
extern int yydebug;
#endif

void yyerror(const char *msg)
{
#if	YYDEBUG
    if( yydebug )
	lexerror("%s at token %s\n", msg, lex_token_to_string(yychar));
    else
#endif
	lexerror("%s\n", msg);
}

static void yyprintf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
}
#define printf yyprintf
