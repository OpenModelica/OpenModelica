// -*- C++ -*-

#header <<

#include "parser.h"
// #include "comments.h"
#include "modAST.h"

#ifndef __GNUG__
#include "bool.h"
#endif

#ifdef _WIN32
int getopt(int nargc, char **nargv, char *ostr);
extern int optind;
extern char *optarg;
char *__progname;
#endif

>>

<<

#include <stdlib.h>		// getopt
#include "DLexerBase.h"		// Base info for DLG-generated scanner
#include "DLGLexer.h"
#include "AToken.h"		// Base token definitions for ANTLR

#include "rml.h"
// #include "codegen.h"
#include "dae.h"
#include "exp.h"
#include "class.h"

static int errors=0;

static char *filename=NULL;
static char *outputfilename=NULL;

int main(int argc, char **argv)
{
  
#ifdef _WIN32
  __progname = argv[0];
#endif
  
  bool nocode=false;
  bool dump=false;
  bool noprint=true;
  bool verbosemode=false;
  
  FILE *source;
  
  int c;
  extern char *optarg;
  extern int optind;
  int errflg = 0;
  
  // Initialize RML
  Exp_5finit();
  DAE_5finit();
  Class_5finit();
  
  while ((c = getopt(argc, argv, "svxdr:o:D")) != EOF)
    switch (c) {
    case 'v':
      verbosemode=true;
      break;
    case 'd':
      noprint=false;
      break;
    case 'D':
      dump=true;
      break;
    case 'o':
      outputfilename = optarg;
      //	cout << "ofile = " << ofile << "\n";
      break;
    case '?':
      errflg++;
    }
  if (errflg) {
    fprintf(stderr, "usage: modeq [-v] [-x] [-d] [-D] [-r <contextname>] [-o <filename>] file\n");
    exit (2);
  }
  
  if (verbosemode) {
    fprintf(stderr, "Input filename: %s\n", ( filename? filename : "stdin" ));
    fprintf(stderr, "Output filename: %s\n", ( outputfilename? outputfilename : "stdout" ));
  }

  filename = argv[optind];
  
  if (filename) {
    source=fopen(filename,"r");
  } else {
    source=stdin;
  }
  
  // Declare the parser objects
  DLGFileInput in(source);          // define the input file; in this case, source
  DLGLexer scanner(&in);           // define an instance of your scanner
  ANTLRTokenBuffer pipe(&scanner); // define a token buffer between scanner and parser
  ANTLRToken tok;                  // create a token to use as a model
  ASTBase *root=NULL;
  AST *rootCopy;
  ModParse parser(&pipe);        // create an instance of your parser
  
  scanner.setToken(&tok);          // tell the scanner what type the token is
  
  parser.init();                 // initialize your parser
  parser.model_specification(&root);              // start first rule
  
  if (filename) fclose(source);
  
  rootCopy=(AST *) root;
  if (!noprint) {
    printf("Dump of tree:\n");
    rootCopy->preorder();
    printf("\n\n");
  }
  if (dump) {
    printf("Dump of tree:\n");
    rootCopy->dumpTree();
  }

  rootCopy->destroy();
  //    fprintf(stderr,"%d errors.\n",errors);
  return 0;                        // it's over Johnnie... it's over
}


>>

/**************************************************************/
/* Token definitions for the the lexical analyzer. */

#lexclass START
#token "/\*"		<< skip(); mode(C_STYLE_COMMENT); >>
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
#token VIRTUAL		"virtual"
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
//#token PRIVATE		"private"
#token PROTECTED	"protected"
#token LPAR		"\("
#token RPAR		"\)"
#token LBRACK		"\["
#token RBRACK		"\]"
//#token RECORD_BEGIN	"\{"
//#token RECORD_END	"\}"
#token IF		"if"
#token THEN		"then"
#token ELSE		"else"
#token ELSEIF		"elseif"
//#token ENDIF		"endif"
//#token WHEN		"when"
//#token ENDWHEN		"endwhen"
#token OR		"or"
#token AND		"and"
#token NOT		"not"
#token TIME		"time"
#token FALS		"false"
#token TRU		"true"

//#token FORALL		"forall"
//#token ENDFORALL	"endforall"
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

//#tokclass COMP_BEGIN	{ LPAR RECORD_BEGIN }
//#tokclass COMP_END	{ RPAR RECORD_END }

//#tokclass ARR_ARG_BEG	{ LPAR LBRACK }
//#tokclass ARR_ARG_END   { RPAR RBRACK }

#tokclass REL_OP 	{ "<" "<=" ">" ">=" "==" "<>" }
#tokclass ADD_OP	{ "\+" "\-" }
#tokclass MUL_OP	{ "\*" "/" }

#tokclass ASSIGN	{ "=" ":=" }

#token EXTRA_TOKEN	// used for synthetic nodes

#token "//(~[\n])*"  << skip(); >> // skip C++-style comments

#token IDENT 		"([a-z]|[A-Z])([a-z]|[A-Z]|[0-9]|_)*"

#token STRING		"\"(~[\"])*\""

#token UNSIGNED_NUMBER	"[0-9]+{\.[0-9]*}{[eE]{[\+\-]}[0-9]+}"

#token "[\ \t]+"    << skip(); >>
#token "\n"         << skip(); newline(); >>

#lexclass C_STYLE_COMMENT

#token	"[\n\r]"	<< skip(); newline(); >>
#token	"\*/"		<< skip(); mode(START); >>
#token	"\*"		<< skip(); >>
#token	"~[\*\n\r]+"	<< skip(); >>


#lexclass START

/**************************************************************/
/* The main part of the Modelica parser. */

class ModParse {

model_specification :
	(
	  cl:class_definition[false,false] ";"! 
	  | import_statement
	)+
	"@"!
	;

import_statement :
	im:IMPORT^ STRING ";"! << #im->ni.type=IMPORT_STATEMENT; >>
	;

class_definition[bool is_virtual,bool is_final] :
	<< bool is_ext=false,is_external=false,is_fun=false, is_type=false,is_partial=false; char *classType; >>
	{ PARTIAL! << is_partial=true; >> } 
        ( CLASS_! << classType="Class"; >>
	  | MODEL! << classType="Model"; >>
	  | RECORD! << classType="RecordType"; >>
	  | BLOCK! << classType="BlockClass"; >>
	  | CONNECTOR! << classType="Connector"; >>
	  | TYPE! << classType="Type"; is_type=true; >>
	  | PACKAGE! << classType="Package"; >>
	  | { EXTERNAL! << is_external=true; >> } FUNCTION! << is_fun=true; >> )
	id:IDENT^
	comment
	( composition END! { IDENT! } |
	  "="! << is_ext=true; >> 
	  IDENT { array_decl } { class_specialization } 	  
	)
	<< if (is_ext) {
	     #id->ni.type=ET_EXTCLASS;
	   } else if (is_fun) {
	     #id->ni.type=ET_FUNCTION;
	   } else {
	     #id->ni.type=CLASSDEF;
	   }
  	  #id->classType=classType;
          // #id->classType="Class";
	  if (is_virtual)  #id->ni.properties |= CLASS_VIRTUAL;
	  if (is_final)    #id->ni.properties |= IS_FINAL;
	  if (is_partial)  #id->ni.properties |= CLASS_PARTIAL;
	  if (is_external) #id->ni.properties |= FUNCTION_EXTERNAL;
	>>
	;

composition :
	default_public
	( public_elements    |
	  protected_elements |
	  equation_clause    |
	  algorithm_clause
	)*
	;

default_public!:
	el:element_list[false] << #0=#(#[EXTRA_TOKEN],#el); >> ;

public_elements: PUBLIC^ element_list[false];
protected_elements: PROTECTED^ element_list[true];


element_list[bool is_protected] :
	( el:element ";"! << if (is_protected) #el->ni.properties |= ELEMENT_PROTECTED; >>
	  | annotation ";"! )*
    ;

element :
	<< bool is_virtual=false; bool is_final=false; >>
	{ FINAL! << is_final=true; >> }
	( { VIRTUAL! << is_virtual=true; >> } class_definition[is_virtual,is_final]
	| extends_clause
	| component_clause[ET_COMPONENT] )
	;

//
// Extends
//

extends_clause:
	EXTENDS! i:IDENT^ << #i->ni.type=ET_INHERIT; >>
	{ class_specialization }
	;

//
// Component clause
//

component_clause![NodeType nt] :
	p:type_prefix
	t:type_specifier << #t->ni.type=nt; >>
	c:component_list[NO_SPECIAL]
	<<  #0=#(#t,#(#[EXTRA_TOKEN],#p),#c); >>
	;

type_prefix :
	{ f1:FLOW << #f1->setTranslation("Flow "); >> } 
	{ f2:PARAMETER << #f2->setTranslation("Parameter "); >> 
	| f3:CONSTANT << #f3->setTranslation("Constant "); >> }
	{ f4:INPUT << #f4->setTranslation("Input "); >>
	| f5:OUTPUT << #f5->setTranslation("Output "); >> }
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
	i:IDENT^ << #i->ni.type=nt; >>
	{ array_decl  }
	{ specialization["="] }
        ;

array_decl :
	brak:LBRACK^
	subscript_list
	RBRACK!
	<< #brak->setOpType(OP_ARRAYDECL); >>
	;

subscript_list :
	subscript 
 	( "," subscript )*
	;

subscript! :
  (expression ":")? ex1:expression ":" { ex2:expression }

	<< 
	   // if ex2 was parsed, build a [n:m] treee
	   if (ex2_ast) #0=#(0,#ex1,#[EXTRA_TOKEN,"|"],#ex2);
	   // else build a [n:] tree
	   else #0=#(0,#ex1,#[EXTRA_TOKEN,"|"],#[EXTRA_TOKEN,"_"]);
	>>

  | ":" { ex3:expression }
	<<
	  if (ex3_ast) {
	    // if ex3 was parsed, build a [:m] tree
	    #0=#(0,#[EXTRA_TOKEN,"1"],#[EXTRA_TOKEN,"|"],#ex3);
	  } else {
	    // else build a [:] tree
	    #0=#(0,#[EXTRA_TOKEN,"_"]);
	  }
	>>
  | ex4:expression
	<<
	  // single expression; build [n] tree
	  #0=#(0,#ex4);
	>>
  ;

//
// Modification (here: specialization)
//

specialization[char *tr] : 
	class_specialization { "=" expression }
	| eq:"=" expression << #eq->setTranslation(tr); >>
	;

class_specialization :
	LPAR^ argument_list RPAR! 
	;

argument_list :
	argument ( ","! argument )*
	;

argument :
	element_modification
	| element_redeclaration
	;
 
element_modification :
	{ FINAL } 
	id:IDENT^ << #id->ni.type=ELEMENT_MOD; >> 
	{ array_decl } 
	specialization["->"]
	;

element_redeclaration :
	<< bool is_final=false; >>
	REDECLARE!
	{ FINAL! << is_final=true; >> }
	( extends_clause
	  | class_definition[false,is_final]
	  | component_clause1[ET_COMPONENT] )
	;

component_clause1![NodeType nt] :
	p:type_prefix
	t:type_specifier << #t->ni.type=nt; >>
	c:component_declaration[ET_COMPONENT]
	<<  #0=#(#t,#(#[EXTRA_TOKEN],#p),#c); >>
	;

//component_clause1![NodeType nt] :
//	  type_prefix 
//	  t:type_specifier << #t->ni.type=nt; >>
//	  c:component_declaration[ET_COMPONENT]
//	  // manual tree construction:
//	  // the type specifier is a new root with the component_declaration
//	  // as a child.
//	  << #0=#(#t,#c); >>
//	  ;

//
// Equations
//


equation_clause	: 
	EQUATION^
	( eq:equation ";"! << #eq->ni.type=ET_EQUATION; >>
	  | an:annotation ";"! << #an->ni.type=ET_ANNOTATION; >>
	)*
	;

algorithm_clause :
	ALGORITHM^
	( eq:equation ";"! << #eq->ni.type=ET_ALGORITHM; >> 
	  | an:annotation ";"! << #an->ni.type=ET_ANNOTATION; >>
	)*
	;

equation :
	( 
	  simple_expression { op:ASSIGN^ << #op->setTranslation("=="); >> expression }
	  | conditional_equation
	  | for_clause
	  | while_clause )
	comment
	;

//conditional_equation :
//	  i:IF^ expression << #i->setOpType(OP_FUNCTION); #i->setTranslation("If"); >> 
//	  THEN!
//	  el:equation_list << #el->setTranslation(";"); >>
//	  (
//	   elseif_clause
//	  | ELSE!
//	    el2:equation_list << #el2->setTranslation(";"); >>
//	  | 
//	  )
//	    END! IF!
//	  ;
//
//elseif_clause:
//	  e:ELSEIF^ << #e->setOpType(OP_FUNCTION); #e->setTranslation("If"); >>
//	  expression THEN! 
//	  el:equation_list << #el->setTranslation(";"); >>
//	  ( elseif_clause | ELSE! el2:equation_list << #el2->setTranslation(";"); >> | )
//	  ;

conditional_equation :
	<< bool is_elseif=false; AST *e_ast;>>

	i:IF^ expression THEN!

	el:equation_list << #el->setTranslation(";"); >>

	( ELSEIF! << is_elseif=true; >> expression THEN!
	el1:equation_list << #el1->setTranslation(";"); >> )*

	// The LT(1) is there just to silence an ANTLR warning. It's not used.
	{ ( <<LT(1),is_elseif>>? els:ELSE << #els->setTranslation("True"); >> | ELSE! )
	  el2:equation_list << #el2->setTranslation(";"); >> }

	END! IF!
	<< if (is_elseif) {
	     #i->setOpType(OP_FUNCTION); 
	     #i->setTranslation("Which");
	   } else {
	     #i->setOpType(OP_FUNCTION); 
	     #i->setTranslation("If"); 
	   }
	>>
	;

for_clause ! :
	for_:FOR id:IDENT IN! e1:expression ":"! e2:expression
	{ ":"! e3:expression } LOOP!
	el:equation_list << #el->setTranslation(";"); >>
	END! FOR!
	<< #for_=#[for_];
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
           }	   
	>>
	;

while_clause :
	while_:WHILE^ expression LOOP!

	el:equation_list << #el->setTranslation(";"); >>
	END! WHILE!
	<< #while_->setOpType(OP_FUNCTION); 
	   #while_->setTranslation("While");
	>>
	;

equation_list :
	( equation ";"! )*
	<< #0=#(#[EXTRA_TOKEN],#0); >>
	;

//
// Expressions
//

expression :

	simple_expression 
	| ifpart:IF^ << #ifpart->setOpType(OP_FUNCTION); #ifpart->setTranslation("If");
			 >>
	  expression 
	  THEN!
	  simple_expression
	  ELSE!
	  expression
	  ;

simple_expression :
	logical_term
	( o:OR^ logical_term << #o->setTranslation("||"); >>
	)*
	;

logical_term :
	logical_factor
	( a:AND^ logical_factor << #a->setTranslation("&&"); >>
	)*
	;

logical_factor :
	not:NOT^ << #not->setOpType(OP_PREFIX); #not->setTranslation("!"); >> 
	relation
	| relation 
	;

relation :
	arithmetic_expression 
	{ rel:REL_OP^ arithmetic_expression 
	<< if (!strcmp(mytoken($rel)->getText(),"<>")) #rel->setTranslation("!=");
           else if (!strcmp(mytoken($rel)->getText(),"==")) #rel->setTranslation("===");
	>>
	}
	;

arithmetic_expression :

	unary_arithmetic_expression
	(
	  ADD_OP^ term
	)*
	;

unary_arithmetic_expression:

	plus:"\+"^ term << #plus->setOpType(OP_PREFIX); >>
	| minus:"\-"^ term << #minus->setOpType(OP_PREFIX); >>
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

	// Easy translation of der() function by me.
 	| op:DER^ LPAR! primary RPAR! 
		<< #op->setOpType(OP_POSTFIX);
		   #op->setTranslation("'");
		>>
	;

primary :
	<< bool is_matrix; >>
	par:LPAR^  << #par->setOpType(OP_BALANCED,')'); >> 
	expression RPAR!

	| op:LBRACK^ << #op->setOpType(OP_BALANCED,'}');
			#op->setTranslation("{"); >>
	  column_expression > [is_matrix] 
	<< if (!is_matrix) {
		// Probable memory leak!
		// elevate row expression to get rid of {{ }}
		#0->setDown(#0->down()->down());
		}
	>>
	  RBRACK!

	| nr:UNSIGNED_NUMBER << mytoken($nr)->convertFloat(); >>
	| FALS/*E*/
	| TRU/*E*/
	| (name_path_function_arguments)? name_path_function_arguments
	//| new_component_reference
	| (member_list)?
	| name_path
	| TIME
	| STRING
	;

name_path_function_arguments ! :
	n:name_path f:function_arguments
	<< #0=#(#[EXTRA_TOKEN],#n,#f); >>
	;

name_path :
	IDENT { dot:"."^ << #dot->setTranslation("`"); >> name_path }
	;

new_component_reference :
	a:array_op
	{ dot:"."^ << #dot->setTranslation("`"); >>  new_component_reference }
	;

member_list:
	comp_ref { dot:"."^ << #dot->setTranslation("Member"); #dot->setOpType(OP_FUNCTION); >> 
	( (member_list)? | name_path ) }
	;

comp_ref:
	name_path b:LBRACK^ << #b->setOpType(OP_ARRAYRANGE); >> subscript_list RBRACK!
	;

array_op :
	i:IDENT 
	{ brak:LBRACK^ subscript_list RBRACK! << #brak->setOpType(OP_ARRAYRANGE); >> }
	;

component_reference ! :
	i:IDENT { a:array_decl } { dot:"." c:component_reference }
	;

// not in document's grammar
column_expression > [bool is_matrix] :
	<< $is_matrix=false; >>
	row_expression ( ";"! row_expression << $is_matrix=true; >> )*
	;

row_expression :
	expression 
	( ","! expression 
	)*
	// create token with translation {, balancer }, type BALANCED
	<< #0=#(#[EXTRA_TOKEN,"{",OP_BALANCED,'}'],#0); >>
	;

function_arguments :
	p:LPAR^ expression ( ","! expression )* RPAR! 
	<< #p->setOpType(OP_FUNCTION); 
	   #p->setTranslation(""); // don't output (
	>>
	;

comment : 
	// several strings in a row is really one string continued on
	// several lines.
	( s:STRING! )*
	// Why is this syntactic predicate necessary??
	{ (annotation)? annotation! }
	;

annotation :
	ANNOTATION class_specialization
	;
