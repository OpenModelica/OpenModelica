/* -*- C -*- */

#header <<

/* #include "bool.h" */
typedef int bool;
#define false 0
#define true  1

#include "attrib.h"
#include "parser.h"
#include "modAST.h"

#define AST_FIELDS Attrib *attr; void *rml;
#define zzcr_ast(ast,atr,ttype,text) ast->attr=copy_attr(atr); ast->rml=NULL;

>>

<<

#include <stdlib.h>

#include "rml.h"
#include "yacclib.h"
#include "exp.h"
#include "absyn.h"
#include "errno.h"

static int errors=0;

static char *filename=NULL;
static char *outputfilename=NULL;

void newline()
{
  zzline++;
}

AST *zzmk_ast(AST *ast, Attrib *at)
{
  ast->attr = copy_attr(at);
  return ast;
}

extern void *sibling_list(AST *ast);

>>

/**************************************************************/
/* Token definitions for the the lexical analyzer. */

#lexclass START
#token "/\*"		<< zzskip(); zzmode(C_STYLE_COMMENT); >>
#token IMPORT		"import"
#token CLASS_		"class"
#token BOUNDARY		"boundary"
#token MODEL		"model"
#token FUNCTION		"function"
#token PACKAGE		"package"
#token RECORD		"record"
#token BLOCK		"block"
#token CONNECTOR	"connector"
#token TYPE		"type"
#token END		"end"

#token ANNOTATION	"annotation"

#token EXTERNAL		"external"
#token EXTENDS		"extends"
#token PARAMETER	"parameter"
#token CONSTANT		"constant"
#token REPLACEABLE	"replaceable"
#token PARTIAL		"partial"
#token REDECLARE	"redeclare"
#token INPUT		"input"
#token OUTPUT		"output"
#token FLOW		"flow"

#token EQUATION		"equation"
#token ALGORITHM	"algorithm"
#token RESULTS		"results"

#token FINAL		"final"
#token PUBLIC		"public"
/* #token PRIVATE		"private" */
#token PROTECTED	"protected"
#token LPAR		"\("
#token RPAR		"\)"
#token LBRACK		"\["
#token RBRACK		"\]"
/* #token RECORD_BEGIN	"\{" */
/* #token RECORD_END	"\}" */
#token IF		"if"
#token THEN		"then"
#token ELSE		"else"
#token ELSEIF		"elseif"
/* #token ENDIF		"endif" */
/* #token WHEN		"when" */
/* #token ENDWHEN		"endwhen" */
#token OR		"or"
#token AND		"and"
#token NOT		"not"
#token TIME		"time"
#token FALS		"false"
#token TRU		"true"

/* #token FORALL		"forall" */
/* #token ENDFORALL	"endforall" */
#token IN		"in"
#token FOR		"for"
#token WHILE		"while"
#token LOOP		"loop"

#token DER		"der"

/*
#token NEW		"new"
#token INIT		"init"
#token DER		"der"
#token RESIDUE		"residue"
*/

#token EQUALS           "="
#token ASSIGN           ":="
#token PLUS             "\+"
#token MINUS            "\-"
#token MULT             "\*"
#token DIV              "/"
#token DOT		"."

/* #tokclass COMP_BEGIN	{ LPAR RECORD_BEGIN } */
/* #tokclass COMP_END	{ RPAR RECORD_END } */

/* #tokclass ARR_ARG_BEG	{ LPAR LBRACK } */
/* #tokclass ARR_ARG_END   { RPAR RBRACK } */

#tokclass REL_OP 	{ "<" "<=" ">" ">=" "==" "<>" }
#tokclass ADD_OP	{ PLUS MINUS }
#tokclass MUL_OP	{ MULT DIV }

/* synthetic nodes */
#token EXTRA_TOKEN	/* used for synthetic nodes */
#token COMPONENTS
#token TYPE_PREFIX
#token FUNCALL
#token ELEMENT
#token MODIFICATION

#token "//(~[\n])*"  << zzskip(); >> /* skip C++-style comments */

#token IDENT 		"([a-z]|[A-Z])([a-z]|[A-Z]|[0-9]|_)*"

#token STRING		"\"(~[\"])*\""

#token UNSIGNED_NUMBER	"[0-9]+{\.[0-9]*}{[eE]{[\+\-]}[0-9]+}"

#token "[\ \t]+"    << zzskip(); >>
#token "\n"         << zzskip(); newline(); >>

#lexclass C_STYLE_COMMENT

#token	"[\n\r]"	<< zzskip(); newline(); >>
#token	"\*/"		<< zzskip(); zzmode(START); >>
#token	"\*"		<< zzskip(); >>
#token	"~[\*\n\r]+"	<< zzskip(); >>


#lexclass START

/**************************************************************/
/* The main part of the Modelica parser. */

model_specification :
	(
	  cl:class_definition[false,false] ";"! 
	| import_statement
	)+
	"@"!
	;

import_statement :
	im:IMPORT^ STRING ";"! << /* #im->ni.type=IMPORT_STATEMENT; */ >>
	;

class_definition[bool is_replaceable,bool is_final] :
        << void *restr;
	   bool partial=false, has_array_decl=false, has_class_spec=false; >>
	{ PARTIAL << partial = true; >> }
        ( CLASS_                  << restr = Absyn__CL_5fCLASS; >>
	| MODEL			  << restr = Absyn__CL_5fMODEL; >>
	| RECORD		  << restr = Absyn__CL_5fRECORD; >>
	| BLOCK			  << restr = Absyn__CL_5fBLOCK; >>
	| CONNECTOR		  << restr = Absyn__CL_5fCONNECTOR; >>
	| TYPE			  << restr = Absyn__CL_5fTYPE; >>
	| PACKAGE		  << restr = Absyn__CL_5fPACKAGE; >>
	| { EXTERNAL } FUNCTION   << restr = Absyn__CL_5fFUNCTION; >>
	)
        i:IDENT
	comment
	( c:composition END! { IDENT! }
	  << 
	     Attrib a = $[CLASS_,"---"];
	     #0 = #(#[&a], #0);
	     #0->rml = Absyn__CLASS(mk_scon($i.u.stringval),
				    RML_PRIM_MKBOOL(partial),
				    restr, Absyn__PARTS(sibling_list(#c)));
	  >>
	| EQUALS di:IDENT
	  { da:array_decl << has_array_decl=true; >> }
	  { ds:class_specialization << has_class_spec=true; >> } 
	  << 
	     Attrib a = $[CLASS_,"---"];
	     #0 = #(#[&a], #0);
	     #0->rml = Absyn__CLASS(mk_scon($i.u.stringval),
				    RML_PRIM_MKBOOL(partial),
				    restr,
				    Absyn__DERIVED(mk_scon($di.u.stringval),
						   (has_array_decl
						    ? mk_some(#da->rml)
						    : mk_none()),
						   (has_class_spec
						    ? mk_some(#ds->rml)
						    : mk_none())));
	  >>
	)
	;

composition :
	default_public
	( public_elements    |
	  protected_elements |
	  equation_clause    |
	  algorithm_clause
	)*
	;

default_public:
	element_list[false]
	<< 
	   Attrib a = $[PUBLIC,"---"];
	   void *els = sibling_list(#0);
	   printf("default_public\n");
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__PUBLIC(els);
	>>
        ;

public_elements:
	PUBLIC^ element_list[false]
	<< #0->rml = Absyn__PUBLIC(mk_nil()); >>
	;
protected_elements:
	PROTECTED^ element_list[true]
	<< #0->rml = Absyn__PROTECTED(mk_nil()); >>
	;

element_list[bool is_protected] :
	( el:element ";"!
	| annotation! ";"! )*
	;

element :
	<< bool is_replaceable=false; bool is_final=false; void *spec; >>
	{ FINAL << is_final = true; >> }
	( { REPLACEABLE << is_replaceable=true; >> }
	  c:class_definition[is_replaceable,is_final]
	  << spec=Absyn__CLASSDEF(RML_PRIM_MKBOOL(is_replaceable), #c->rml); >>
	| ec:extends_clause << spec = #ec->rml; >>
	| cc:component_clause << spec = #cc->rml; >>  )
	<< Attrib a = $[ELEMENT,"---"];
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__ELEMENT(RML_PRIM_MKBOOL(is_final), spec); >>
	;

/*
 * Extends
 */

extends_clause:
	EXTENDS^ i:IDENT
	{ class_specialization }
	<< #0->rml = Absyn__EXTENDS(mk_scon(i.u.stringval),
				    mk_nil() /* FIXME */); >>
	;

/*
 * Component clause
 */

component_clause!: << Attrib a = $[COMPONENTS,"---"]; >>
	p:type_prefix
	s:type_specifier
	l:component_list[NO_SPECIAL]
        << bool fl=false, pa=false, co=false, in=false, ou=false;
	   #0 = #(#[&a], #p, #s, #l);
	   /* FIXME: Split to several elements */

	   #0->rml = Absyn__COMPONENT(RML_PRIM_MKBOOL(fl),
				      RML_PRIM_MKBOOL(pa),
				      RML_PRIM_MKBOOL(co),
				      RML_PRIM_MKBOOL(in),
				      RML_PRIM_MKBOOL(ou),
				      #s->rml,
				      #l->rml,
				      mk_none(),
				      mk_none());

#if 0
	   #0->rml = Absyn__EXTENDS(mk_scon("shit"),mk_nil());
#endif
	>> 
	;

type_prefix : << Attrib a = $[TYPE_PREFIX,"---"]; >>
	{ f:FLOW      } 
	{ p:PARAMETER
	| c:CONSTANT  }
	{ i:INPUT     
	| o:OUTPUT    }
        << #0 = #(#[&a],#0); >>
	;

type_specifier :
	name_path
	;

component_list[NodeType nt] :
    component_declaration[nt] ( ","! component_declaration[nt] )*
	;

component_declaration[NodeType nt] :
        declaration[nt] comment
	;

declaration[NodeType nt] :
	i:IDENT^ << /* #i->ni.type=nt; */ >>
	{ array_decl  }
	{ specialization }
	<< #i->rml = mk_scon($i.u.stringval); >>
        ;

array_decl :
	brak:LBRACK^
	subscript_list
	RBRACK!
	<< /* #brak->setOpType(OP_ARRAYDECL); */ >>
	;

subscript_list :
	subscript 
 	( "," subscript )*
	;

subscript! :
  (expression ":")? ex1:expression ":" { ex2:expression }

	<< 
/* 	   if ex2 was parsed, build a [n:m] treee */
  /*if (ex2_ast) #0=#(0,#ex1,#[EXTRA_TOKEN,"|"],#ex2); */
/* 	   else build a [n:] tree */
  /* else #0=#(0,#ex1,#[EXTRA_TOKEN,"|"],#[EXTRA_TOKEN,"_"]); */
	>>

  | ":" { ex3:expression }
	<<
/* 	  if (ex3_ast) { */
/* 	    if ex3 was parsed, build a [:m] tree */
	    /* #0=#(0,#[EXTRA_TOKEN,"1"],#[EXTRA_TOKEN,"|"],#ex3); */
/* 	  } else { */
/* 	    else build a [:] tree */
	    /* #0=#(0,#[EXTRA_TOKEN,"_"]); */
/* 	  } */
	>>
  | ex4:expression
	<<
/* 	  single expression; build [n] tree */
  /* #0=#(0,#ex4); */
	>>
  ;

/*
 * Modification (here: specialization)
 */

specialization :
	  c:class_specialization /* { EQUALS expression } */
	  << #0->rml = Absyn__CLASSMOD(#c); >>
	| EQUALS^ e:expression
	  << #0->rml = Absyn__EQUALMOD(#e->rml); >>
	;

class_specialization :
	  LPAR^ al:argument_list RPAR! 
	  << #0->rml = sibling_list(#al); >>
	;

argument_list :
	  argument ( ","! argument )*
	;

argument :
	  element_modification
	| element_redeclaration
	;
 
element_modification : << bool is_final=false; >>
	{ FINAL << is_final=true; >> } 
	cr:component_reference
	sp:specialization
	<< 
	   Attrib a = $[MODIFICATION,"---"];
	   #0 = #(#[&a],#0);
	   #0->rml = Absyn__MODIFICATION(RML_PRIM_MKBOOL(is_final),
					 #cr->rml,
					 #sp->rml);
	>>
	;

element_redeclaration :
	  << bool is_final=false; >>
	  REDECLARE
	  { FINAL << is_final=true; >> }
	  ( extends_clause
	  | class_definition[false,is_final]
	  | component_clause1[ET_COMPONENT] )
	;

component_clause1[NodeType nt] :
	type_prefix
	type_specifier
	component_declaration[ET_COMPONENT]
	;

/* component_clause1![NodeType nt] : */
/* 	  type_prefix  */
/* 	  t:type_specifier << #t->ni.type=nt; >> */
/* 	  c:component_declaration[ET_COMPONENT] */
/* 	  // manual tree construction: */
/* 	  // the type specifier is a new root with the component_declaration */
/* 	  // as a child. */
/* 	  << #0=#(#t,#c); >> */
/* 	  ; */

/*
 * Equations
 */


equation_clause	: 
	EQUATION^ ( equation ";"! | annotation! ";"! )*
	<< #0->rml = Absyn__EQUATIONS(sibling_list(#0->down)); >>
	;

algorithm_clause :
	ALGORITHM^ ( equation ";"! | annotation! ";"! )*
	<< #0->rml = Absyn__ALGORITHMS(mk_nil()); >>
	;

equation : << bool is_assign = false; AST *top; >>
	( lh:simple_expression << top = #lh; >>
	  { ( a:ASSIGN^ << top = #a; >>
	    | e:EQUALS^ << top = #e; >> )
	    rh:expression << is_assign=true; >> }
	  << 
	     if(is_assign)
	       top->rml = Absyn__EQ_5fEQUALS(#lh->rml, #rh->rml);
	     else
	       top->rml = Absyn__EQ_5fEXPR(#lh->rml);
	  >>
	| conditional_equation
	| for_clause
	| while_clause )
	comment!
	;

/* conditional_equation : */
/* 	  i:IF^ expression << #i->setOpType(OP_FUNCTION); #i->setTranslation("If"); >>  */
/* 	  THEN! */
/* 	  el:equation_list << #el->setTranslation(";"); >> */
/* 	  ( */
/* 	   elseif_clause */
/* 	  | ELSE! */
/* 	    el2:equation_list << #el2->setTranslation(";"); >> */
/* 	  |  */
/* 	  ) */
/* 	    END! IF! */
/* 	  ; */

/* elseif_clause: */
/* 	  e:ELSEIF^ << #e->setOpType(OP_FUNCTION); #e->setTranslation("If"); >> */
/* 	  expression THEN!  */
/* 	  el:equation_list << #el->setTranslation(";"); >> */
/* 	  ( elseif_clause | ELSE! el2:equation_list << #el2->setTranslation(";"); >> | ) */
/* 	  ; */

conditional_equation :
	<< bool is_elseif=false; /* AST *e_ast; */ >>

	i:IF^ expression THEN!

	el:equation_list << /* #el->setTranslation(";"); */ >>

	( ELSEIF! << is_elseif=true; >> expression THEN!
	el1:equation_list << /* #el1->setTranslation(";"); */ >> )*

/* 	The LT(1) is there just to silence an ANTLR warning. It's not used. */
	{ ( <</*LT(1),*/is_elseif>>? els:ELSE << /* #els->setTranslation("True"); */ >> | ELSE! )
	  el2:equation_list << /* #el2->setTranslation(";"); */ >> }

	END! IF!
	<< if (is_elseif) {
	  /* #i->setOpType(OP_FUNCTION); 
	     #i->setTranslation("Which"); */
	   } else {
	  /* #i->setOpType(OP_FUNCTION); 
	     #i->setTranslation("If");  */
	   }
	>>
	;

for_clause ! :
	for_:FOR id:IDENT IN! e1:expression ":"! e2:expression
	{ ":"! e3:expression } LOOP!
	el:equation_list << /* #el->setTranslation(";"); */ >>
	END! FOR!
	<< /* #for_=#[for_];
	   #for_->setOpType(OP_FUNCTION); 
	   #for_->setTranslation("For");
	   if (e3_ast) {
	     #0=#(#for_,
	          #(#[EXTRA_TOKEN,"="],#[id],#e1),
                  #(#[EXTRA_TOKEN,"<="],#[id],#e2),
	          #(#[EXTRA_TOKEN,"="],#[id],#(#[EXTRA_TOKEN,"+"],#[id],#e3)),
	          #el);
          } else {
	     #0=#(#for_,
	          #(#[EXTRA_TOKEN,"="],#[id],#e1),
                  #(#[EXTRA_TOKEN,"<="],#[id],#e2),
	          #(#[EXTRA_TOKEN,"++",OP_POSTFIX],#[id]),
	          #el);
           }	 */   
	>>
	;

while_clause :
	while_:WHILE^ expression LOOP!

	el:equation_list << /* #el->setTranslation(";"); */ >>
	END! WHILE!
	<< /* #while_->setOpType(OP_FUNCTION); 
	      #while_->setTranslation("While"); */
	>>
	;

equation_list :
	( equation ";"! )*
	<< /* #0=#(#[EXTRA_TOKEN],#0); */ >>
	;

/*
 * Expressions
 */

expression :

	simple_expression 
	| ifpart:IF^ << /* #ifpart->setOpType(OP_FUNCTION); #ifpart->setTranslation("If"); */ >>
	  expression 
	  THEN!
	  simple_expression
	  ELSE!
	  expression
	  ;

simple_expression :
	logical_term
	( o:OR^ logical_term << /* #o->setTranslation("||"); */ >>
	)*
	;

logical_term :
	logical_factor
	( a:AND^ logical_factor << /* #a->setTranslation("&&"); */ >>
	)*
	;

logical_factor :
	not:NOT^ relation
	| relation 
	;

relation :
	arithmetic_expression 
	{ rel:REL_OP^ arithmetic_expression 
	<< /* if (!strcmp(mytoken($rel)->getText(),"<>")) #rel->setTranslation("!=");
	      else if (!strcmp(mytoken($rel)->getText(),"==")) #rel->setTranslation("==="); */
	>>
	}
	;

arithmetic_expression : << void *op; >>

	unary_arithmetic_expression
	(
	  ( PLUS^ << op = Exp__ADD; >> | MINUS^ << op = Exp__SUB; >> )
	  e2:term
	  << #0->rml = Exp__BINARY(#0->down->rml,op,#e2->rml); >>
	)*
	;

unary_arithmetic_expression:

	PLUS^ t1:term   << #0->rml = Exp__UNARY(Exp__UPLUS,#t1->rml); >>
      | MINUS^ t2:term << #0->rml = Exp__UNARY(Exp__UMINUS,#t2->rml); >>
      | term
	;

term :

	factor
	(
	  MUL_OP^  factor
	)*
	;

factor :
	primary 
	{ "^"^ primary}

/* 	Easy translation of der() function by me. */
 	| op:DER^ LPAR! primary RPAR! 
		<< /* #op->setOpType(OP_POSTFIX);
		      #op->setTranslation("'"); */
		>>
	;

primary : << bool is_matrix; >>
	  par:LPAR^
	  e:expression RPAR!
	  << #par->rml = #e->rml; >>
	| op:LBRACK^ << /* #op->setOpType(OP_BALANCED,'}');
			   #op->setTranslation("{"); */ >>
	  column_expression > [is_matrix] 
	  << if (!is_matrix) {
	        /* Probable memory leak! */
/* 		elevate row expression to get rid of {{ }} */
	  /* #0->setDown(#0->down()->down()); */
		  }
	  >>
	  RBRACK!

	| nr:UNSIGNED_NUMBER << #nr->rml = Exp__NUMBER(mk_rcon($nr.u.floatval)); >>
	| f:FALS/*E*/        << #f->rml = Exp__BOOL(RML_FALSE); >>
	| t:TRU/*E*/         << #t->rml = Exp__BOOL(RML_TRUE); >>
	| (name_path_function_arguments)?
	| (member_list)?
	| i:name_path        << #0->rml = Exp__PATH(#i->rml); >>
	| TIME               << #0->rml = Exp__TIME; >>
	| s:STRING           << #s->rml = Exp__STRING(mk_scon($s.u.stringval)); >>
	;

name_path_function_arguments ! : << Attrib a = $[FUNCALL,"---"]; >>
	n:name_path f:function_arguments
	<< 
	   #0=#(#[&a],#n,#f);
	   #0->rml = Exp__CALL(#n->rml, sibling_list(#f));
	>>
	;

name_path : << bool qualified = false; >>
	i:IDENT^
	{ dot:DOT^ n:name_path << qualified = true; >> }
        << if(qualified)
	     #0->rml = Exp__QUALIFIED(mk_scon($i.u.stringval),#n->rml);
           else
             #0->rml = Exp__IDENT(mk_scon($i.u.stringval)); >>
	;

member_list:
	comp_ref { dot:DOT^
	( (member_list)? | name_path ) }
	;

comp_ref:
	name_path b:LBRACK^ subscript_list RBRACK!
	;

component_reference : << void *tail = NULL; >>
	  i:IDENT^ { a:array_decl }
	  << #i->rml = mk_box2(0,
			       mk_scon($i.u.stringval),
			       mk_nil() /* FIXME */); >>
	  { dot:DOT^ c:component_reference << tail = #c->rml; >> }
	  << #0->rml = mk_cons(#i->rml, tail != NULL ? tail : mk_nil()); >>
	;

/* not in document's grammar */
column_expression > [bool is_matrix] :
	<< $is_matrix=false; >>
	row_expression ( ";"! row_expression << $is_matrix=true; >> )*
	;

row_expression :
	expression 
	( ","! expression 
	)*
        /* create token with translation {, balancer }, type BALANCED */
	<< /* #0=#(#[EXTRA_TOKEN,"{",OP_BALANCED,'}'],#0); */ >>
	;

function_arguments :
	p:LPAR! expression ( ","! expression )* RPAR! 
	;

comment : 
        /* several strings in a row is really one string continued on
	   several lines. */
	( s:STRING! )*
        /* Why is this syntactic predicate necessary?? */
	{ (annotation)? annotation! }
	;

annotation :
	ANNOTATION class_specialization
	;
