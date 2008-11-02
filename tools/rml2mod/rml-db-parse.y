%{
#include "rml.h"
#include "stdio.h"
#include "yacclib.h"
#include "absyn.h"


extern int yyrmldblex(void);

extern int yyrmldb_lineno;

#define YYMAXDEPTH 100000000
#define YYDEBUG 1
#define YYERROR_VERBOSE                  /* Have this defined to give better
                                            error messages. Using it causes
					    some bison warnings at compiler
					    compile time, however. Use as you
					    wish. Not mandatory. */
typedef void* rml_t;
#define YYSTYPE rml_t
extern rml_t yyrmldb_absyntree;

/* define this shit in advance */
rml_t mktuplety(rml_t p_tuplety);
%}


%token T_EOF T_EOL
%token T_VAL T_VAR T_CON T_TYPE T_RELATION
%token T_LBRACK T_RBRACK T_FATARROW T_DOT T_MORE T_COLON
%token T_LPAR T_RPAR T_COMMA T_STAR

%token T_id
%token T_tyvar
%token T_number
%token T_file

/* v:<main.rml>:99.53.99.57|[97.9.99.86]|buildNormalAst[stmts:Absyn.Stmt list]
 * t:<values.rml>:40.12.40.16|Values.Value
 * c:<values.rml>:47.20.47.25|Values.RECORD:(Values.Value list,string list) => Values.Value
 * r:<values.rml>:428.10.428.20|Values.mult_matrix:(Values.Value list,Values.Value list) => Values.Value list
 * l:<Builtin.rml>:660.5.660.20|n2real2arrayreal:Types.TType*'a option
 */

%%


start:
 lines
 {
   yyrmldb_absyntree = Absyn__RMLDB($1);
   YYACCEPT;
 }
 ;


lines: line T_EOL lines
{
  $$ = mk_cons($1, $3);
}
|
{
  $$ = mk_nil();
}
;

line:
T_VAL T_file T_COLON range T_MORE ident T_COLON ty
{
  /* l:<Builtin.rml>:660.5.660.20|n2real2arrayreal:Types.TType*'a option */
  $$ = Absyn__RMLDB_5fVAR(
   $2,
   $6,
   $4,
   $4,
   Absyn__RMLSHORTID(
      mk_scon("_VL_"), /* val declaration */
      Absyn__INFO(
       mk_scon(""),
       mk_icon(0),
       mk_icon(0),
       mk_icon(0),
       mk_icon(0))),
   $8);
}
| T_VAR T_file T_COLON range T_MORE T_LBRACK range T_RBRACK T_MORE ident T_LBRACK ident T_COLON ty T_RBRACK
{
  /* v:<main.rml>:99.53.99.57|[97.9.99.86]|buildNormalAst[stmts:Absyn.Stmt list] */
  $$ = Absyn__RMLDB_5fVAR($2, $12, $4, $7, $10, $14);
}
| T_CON T_file T_COLON range T_MORE ident T_COLON ty
{
  /* c:<values.rml>:47.20.47.25|Values.RECORD:(Values.Value list,string list) => Values.Value */
  $$ = Absyn__RMLDB_5fCTOR($2, $6, $4, $8);
}
| T_TYPE T_file T_COLON range T_MORE ident
{
  /* t:<values.rml>:40.12.40.16|Values.Value */
  $$ = Absyn__RMLDB_5fTY($2, $6, $4);
}
| T_RELATION T_file T_COLON range T_MORE ident T_COLON ty
{
  /* r:<values.rml>:428.10.428.20|Values.mult_matrix:(Values.Value list,Values.Value list) => Values.Value list */
  $$ = Absyn__RMLDB_5fREL($2, $6, $4, $8);
}
;

range:
	T_number T_DOT T_number T_DOT T_number T_DOT T_number
	{
	  $$  = Absyn__RMLDB_5fRANGE($1,$3,$5,$7);
	}
	;

/*
    excerpt from rml.grm
    datatype ident	= IDENT of string * info ref
    type tyvar		= ident
    datatype longid	= LONGID of ident option * ident
    datatype ty	= VARty of tyvar
				| CONSty of ty list * longid
				| TUPLEty of ty list
				| RELty of ty list * ty list
%nonterm ty of Absyn.ty
	   | ty_sans_star of Absyn.ty
	   | tuple_ty of Absyn.ty list
	   | ty_comma_seq2 of Absyn.ty list
	   | seq_ty of Absyn.ty list
*/

ty
	: seq_ty T_FATARROW seq_ty
	{
	  /*
	  Absyn.RELty(seq_ty1, seq_ty2)
	  printf ("Ty.REL(%p,%p)",$1,$3);
	  */
	  $$  = Absyn__RMLTYPE_5fSIGNATURE(
		      Absyn__CALLSIGN($1, $3));
	}
	| tuple_ty
	{
		/*
		mktuplety(tuple_ty)
		printf ("Ty.TUPLE(%p)",$1);
		*/
	  if (yyrmldbdebug)
	  {
	    fprintf(stderr, "\nty:\n");
	    rmldb_var_print($1);
	    fprintf(stderr, "\nty_now:\n");
	    rmldb_var_print(mktuplety($1));
	  }
	  $$ = mktuplety($1);
	}
	;

tuple_ty
	: ty_sans_star T_STAR tuple_ty
	{
	   /*
	   ty_sans_star :: tuple_ty
	   printf ("Ty.LIST(%p,%p)",$1,$3);
	   */
	  $$ = mk_cons($1, $3);
	}
	| ty_sans_star
	{
		/*
		[ty_sans_star]
	    printf ("Ty.LIST(%p)",$1);
	    */
	  $$  =  mk_cons($1, mk_nil());
	}
        ;

ty_sans_star
	: ty_sans_star ident
	{
	  /*
	  ( Absyn.CONSty([ty_sans_star], longorshortid)
	  printf ("Ty.CONSty(list:%p,%s)",$1,$2);
	  */
	  $$  =  Absyn__RMLTYPE_5fTYCONS(mk_cons($1,mk_nil()), $2);
	}
	| T_LPAR ty_comma_seq2 T_RPAR ident
	{
		/*
		printf ("(Ty.CONSty(list:%p,%s))",$2,$4);
		( Absyn.CONSty(ty_comma_seq2, longorshortid)
		*/
	  $$  =  Absyn__RMLTYPE_5fTYCONS($2, $4);
	}
	| T_LPAR ty T_RPAR
	{
	  /*
	  ty
	  printf ("Ty(:%p)",$2);
	  */
	  $$  =  $2;
	}
	| T_tyvar
	{
		/*
	    printf ("Tyvar(:%p)",$1);
		( Absyn.VARty(tyvar, makeInfo myLoc (tyvarleft, tyvarright)) )
		*/
	  $$  = Absyn__RMLTYPE_5fTYVAR(
		 Absyn__RMLSHORTID(
		    $1,
		    Absyn__INFO(
		       mk_scon(""),
		       mk_icon(0),
		       mk_icon(0),
		       mk_icon(0),
		       mk_icon(0))));
	}
	| ident
	{
		/*
		( Absyn.CONSty([], longorshortid,
	    printf ("Ty.CONSty(:%s)",$1);
	    */
	  $$  =  Absyn__RMLTYPE_5fUSERDEFINED($1);
	}
	;

ty_comma_seq2
	: ty T_COMMA ty_comma_seq2
	{
		/*
		( ty :: ty_comma_seq2 )
		printf ("TyList(:%p,%p)",$1,$3);
		*/
	  $$ = mk_cons($1, $3);
	}
	| ty T_COMMA ty
	{
		/*
		( [ty1, ty2] )
		printf ("TyList(:%p,%p)",$1,$3);
		*/
	  $$ = mk_cons($1, mk_cons($3, mk_nil()));
	}
	;

seq_ty
	: T_LPAR T_RPAR
	{
		/*
		([])
		printf ("seq_ty_empty");
		*/
	  $$ = mk_nil();
	}
	| T_LPAR ty_comma_seq2 T_RPAR
	{
		/*
		printf ("(Ty_comma_seq2(%p))",$2);
		( ty_comma_seq2 )
		*/
	  $$  =  $2;
	}
	| tuple_ty
	{
		/*
		printf ("Ty.TUPLE(%p)",$1);
		( [mktuplety(tuple_ty)] )
		*/
	  if (yyrmldbdebug)
	  {
	    fprintf(stderr, "\nty:\n");
	    rmldb_var_print($1);
	    fprintf(stderr, "\nty_now:\n");
	    rmldb_var_print(mktuplety($1));
	  }
	  $$ = mk_cons((rml_t)mktuplety($1), mk_nil());
	}
	;


ident:
T_id T_DOT T_id
{
  $$ = Absyn__RMLLONGID($1, $3);
}
| T_id
{
  $$ = Absyn__RMLSHORTID($1, Absyn__INFO(mk_scon(""), mk_icon(0), mk_icon(0), mk_icon(0), mk_icon(0)));
}
;


%%

char* yyrmldbfilename;

int yyrmldberror(char *s)
{
  fprintf(stderr, "Error: bad syntax \n %s:%d Parse Error:%s",
    yyrmldbfilename, yyrmldb_lineno, s);
  return  -1;
}


rml_t mktuplety(rml_t p_tuplety)
{
  void *lst = p_tuplety;
  int len = 0;
  for(; RML_GETHDR(lst) == RML_CONSHDR; ++len, lst = RML_CDR(lst))
    ;
  if (yyrmldbdebug) fprintf(stderr, "Tuple list length:%d\n", len);
  if (len == 1)
    return RML_CAR(p_tuplety); /* take the first and only component */
  else
    return Absyn__RMLTYPE_5fTUPLE(p_tuplety); /* make a tuple out of the tuple list */
}
