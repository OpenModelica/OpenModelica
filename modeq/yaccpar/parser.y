/* yaccpar.y -- Unified yacc parser for Modelica and RML.
 *
 * $Id$
 */

%token KW_CLASS KW_MODEL KW_RECORD KW_BLOCK KW_CONNECTOR KW_PACKAGE KW_FUNCTION
%token KW_FLOW KW_DISCRETE KW_PARAMETER KW_CONST KW_INPUT KW_OUTPUT
%token KW_ENCAPSULATED KW_PARTIAL KW_WITHIN KW_FINAL KW_EACH

%token KW_ENUMERATION KW_PUBLIC KW_EXTERNAL KW_OVERLOAD KW_IMPORT KW_PROTECTED
%token KW_INNER KW_OUTER KW_IF KW_THEN KW_ELSE KW_ELSEIF KW_FOR KW_LOOP KW_IN
%token KW_REPLACEABLE KW_WHEN KW_WHILE KW_ELSEWHEN KW_CONNECT
%token KW_INITIAL KW_ANNOTATION KW_TRUE KW_FALSE
%token KW_REDECLARE KW_EQUATION KW_ALGORITHM KW_EXTENDS KW_CODE

%token KW_AND KW_AS KW_ABSTYPE KW_AXIOM KW_DATATYPE KW_DEFAULT
%token KW_END KW_EQTYPE KW_FAIL KW_INTERFACE KW_LET KW_MODULE
%token KW_NOT KW_OF KW_OR KW_RELATION KW_RULE KW_TYPE KW_VAL
%token KW_WITH KW_WITHTYPE

%token ASSIGN COLONCOLON DASHES YIELDS EQUALS
%token LESSEQ GREATEREQ EQEQ LESSGT POWER
%token INTEGER_LITERAL REAL_LITERAL STRING_LITERAL CHAR_LITERAL

%token IDENT TYVARIDENT
%{
#include <stdio.h>
#include "yacclib.h"
#include "rml.h"
#include "absyn.h"
#include "defs.h"
#define MAXCOMMENT 2000
extern int yylineno;
extern char yyCommentBuffer[];
extern char parserCommentBuffer[];

#define YYSTYPE rml_t
extern YYSTYPE  yylval;
extern YYSTYPE  *absyntree;

/* Let these be macros for the moment. Perhaps convert them to
 * functions later.
 */
#define tok_rml_int(tok)    mk_icon((((struct Token *)(tok))->u.number))
#define tok_rml_real(tok)   mk_rcon((((struct Token *)(tok))->u.realnumber))
#define tok_rml_string(tok) mk_icon((((struct Token *)(tok))->u.string))
#define tok_rml_char(tok)   mk_ccon((((struct Token *)(tok))->u.number))
#define c_rml_string(cstr)  mk_scon((cstr))

%}

%%
start:
        stored_definition
        {
          $$ = $1;
          absyntree = $1;
        }

COLON:      ':' ;
COMMA:      ',' ;
SEMICOLON:  ';' ;
DOT:        '.' ;
PIPEBAR:    '|' ;
AMPERSAND:  '&' ;
LPAR:       '(' ;
RPAR:       ')' ;
LBRACK:     '[' ;
RBRACK:     ']' ;
LBRACE:     '{' ;
RBRACE:     '}' ;
STAR:       '*' ;
UNDERSCORE: '_' ;
PLUS:       '+' ;
MINUS:      '-' ;
DIV:        '/' ;
SLASH:      '/' ;
LESS:       '<' ;
GREATER:    '>' ;


stored_definition:
	optENCAPSULATED optPARTIAL class_type ident
	{
	  $$ = Absyn__BEGIN_5fDEFINITION(Absyn__IDENT($4), $3, $2, $1);
	}
	|
	KW_END ident SEMICOLON
	{
          $$ = Absyn__END_5fDEFINITION($2);
	}
	|
	component_clause SEMICOLON
	{
	  $$ = Absyn__COMP_5fDEFINITION($1,mk_none());
	}
	|
	import_clause SEMICOLON
	{
	  $$ = Absyn__IMPORT_5fDEFINITION($1,mk_none());
	}
	|
	opt_within_clause class_definition_list
	{
	  $$ = Absyn__PROGRAM($2,$1);
        }
	|
	rml_file
	{
	  $$ = $1;
	}
	;


optENCAPSULATED:
	KW_ENCAPSULATED { $$ = RML_PRIM_MKBOOL(1);}
	|
	{ $$ = RML_PRIM_MKBOOL(0);}
	;

optPARTIAL:
	KW_PARTIAL { $$ = RML_PRIM_MKBOOL(1);}
	|
	{ $$ = RML_PRIM_MKBOOL(0);}
	;

optFINAL:
	KW_FINAL	{ $$ = RML_TRUE;}
	|
		{ $$ = RML_FALSE;}
	;

optEACH:
	KW_EACH	{ $$ = Absyn__EACH;}
	|
		{ $$ = Absyn__NON_5fEACH;}
	;

optSEMICOLON:
	SEMICOLON { $$ = 1;}
	|
	{ $$ = 0;}
	;

opt_within_clause:
	within_clause { $$ = $1;}
	|
	{ $$ = Absyn__TOP;}
	;


within_clause:
	KW_WITHIN name_path
		{ $$ = Absyn__WITHIN($2);}
	;


class_definition:
	optENCAPSULATED optPARTIAL class_type ident class_specifier
	{
	  /* FIXME: need to distinguish whether FINAL or not from
	   * invocation.
	   */
	  $$ = Absyn__CLASS($4,
				$2,
				RML_FALSE /* FINAL */,
				$1,
				$3,
				$5);
	}
	;


class_type:
	KW_CLASS     { $$ = Absyn__R_5fCLASS;}
|	KW_MODEL     { $$ = Absyn__R_5fMODEL;}
|	KW_RECORD    { $$ = Absyn__R_5fMODEL;}
|	KW_BLOCK     { $$ = Absyn__R_5fBLOCK;}
|	KW_CONNECTOR { $$ = Absyn__R_5fCONNECTOR;}
|	KW_TYPE      { $$ = Absyn__R_5fTYPE;}
|	KW_PACKAGE   { $$ = Absyn__R_5fPACKAGE;}
|	KW_FUNCTION  { $$ = Absyn__R_5fFUNCTION;}
;

base_prefix:
	flow_prefix variability_prefix direction_prefix
		{ $$ = Absyn__ATTR($1, $2, $3, mk_nil());}
	;

class_specifier:
	string_comment composition KW_END IDENT
	{
	  $$ = Absyn__PARTS($2, $1);
	}
|
	EQUALS	base_prefix
		name_path
		opt_array_subscripts
		opt_class_modification
		comment
	{
	  $$ = Absyn__DERIVED($3, /* name path */
		              $4, /* array subscripts */
                              $2, /* prefix attributes */
                              $5, /* class modification */
                              $6); /* comment */
	}
|
	EQUALS enumeration
		{ $$ = $1;}
|
	EQUALS overloading
		{ $$ = $1;}
;


enumeration:
	KW_ENUMERATION LPAR enum_list RPAR comment
		{ $$ = Absyn__ENUMERATION($3,$5);}	
	;

enum_list:
	enumeration_literal COMMA enum_list
		{ $$ = mk_cons($1, $3);}
	|
	enumeration_literal
		{ $$ = mk_cons($1, mk_nil());}
	;

enumeration_literal:
	ident comment
		{ $$ = Absyn__ENUMLITERAL($1,$2);}
	;

overloading:
	KW_OVERLOAD LPAR name_path_list RPAR comment
		{ $$ = Absyn__OVERLOAD($3, $5);}
	;

name_path_list:
	name_path COMMA name_path_list
		{ $$ = mk_cons($1,$3);}
	|
	name_path
		{ $$ = mk_cons($1,mk_nil());}
	;
	
flow_prefix:
	KW_FLOW
		{ $$ = RML_PRIM_MKBOOL(1);}
	|
		{ $$ = RML_PRIM_MKBOOL(0);}
;

variability_prefix:
	KW_DISCRETE	{ $$ = Absyn__DISCRETE;}
|	KW_PARAMETER	{ $$ = Absyn__PARAM;}
|	KW_CONST		{ $$ = Absyn__CONST;}
|			{ $$ = Absyn__VAR;}
;

direction_prefix:
	KW_INPUT		{ $$ = Absyn__INPUT;}
|	KW_OUTPUT	{ $$ = Absyn__OUTPUT;}
|			{ $$ = Absyn__BIDIR;}
;

component_clause:
	flow_prefix variability_prefix direction_prefix
	type_specifier opt_array_subscripts component_list
	{
		$$ = Absyn__COMPONENTS(Absyn__ATTR($1,$2,$3,$5),$4,$6);
	}
	;

component_clause1:
	flow_prefix variability_prefix direction_prefix
	type_specifier component_declaration
	{
		$$ = Absyn__COMPONENTS(Absyn__ATTR($1,$2,$3,mk_nil()),$4,$5);
	}
	;

composition:
	flow_prefix variability_prefix direction_prefix
	type_specifier opt_array_subscripts opt_class_modification
		{ /* FIXME */ }
	;

import_clause:
	KW_IMPORT explicit_import_name comment
		{ $$ = Absyn__IMPORT($2,$3);}
	|
	KW_IMPORT implicit_import_name comment
		{ $$ = Absyn__IMPORT($2,$3);}
	;

explicit_import_name:
	ident EQUALS name_path
		{ $$ = Absyn__NAMED_5fIMPORT($1,$3);}
	;

implicit_import_name:
	name_path DOT STAR
		{ $$ = Absyn__UNQUAL_5fIMPORT($1);}
	|
	name_path
		{ $$ = Absyn__QUAL_5fIMPORT($1);}
	;

class_definition_list:
	optFINAL class_definition class_definition_list
		{ $$ = $1 ? mk_cons($2,$3) : $3; /* FIXME: Correct? */ }
	|
		{ $$ = 	mk_nil();}
	;

composition:
	element_list composition_sublist
	{
		$$ = mk_cons(Absyn__PUBLIC($1), $2);
	}
	;

composition_sublist:
	KW_PUBLIC element_list composition_sublist
		{ $$ = mk_cons(Absyn__PUBLIC($1), $2);}
	|
	KW_PROTECTED element_list composition_sublist
		{ $$ = mk_cons(Absyn__PROTECTED($1), $2);}
	|
	equation_clause composition_sublist
		{ $$ = mk_cons($1, $2);}
	|
	initial_equation_clause composition_sublist
		{ $$ = mk_cons($1, $2);}
	|
	algorithm_clause composition_sublist
		{ $$ = mk_cons($1, $2);}
	|
	initial_algorithm_clause composition_sublist
		{ $$ = mk_cons($1, $2);}
	|
	KW_EXTERNAL
		opt_language_specification
		opt_external_function_call
		optSEMICOLON
		opt_annotation
	{ /* an external_clause must be the last composition item, so
	   * we don't have composition_sublist at the end of this rule.
	   * This also means we must add the NIL at the end of the list
	   * ourselves.
	   */

	  /*FIXME: the language specification data should probably be part
     	   * of the external function call data, so opt_language_specification
	   * should probably be inside opt_external_function_call rule?
	   */ 

	  /* FIXME: handle annotation. */

		$$ = mk_cons($3, mk_nil());
	}
	|
		{ $$ = mk_nil();}
	;

language_specification:
	STRING_LITERAL
		{ $$ = tok_rml_string($1);}
	;

opt_language_specification:
	language_specification
		{ $$ = $1;}
	|
		{ $$ = 0;}
	;

opt_component_reference_equals:
	component_reference EQUALS
		{ $$ = $1;}
	|
		{ $$ = 0;}
	;

opt_external_function_call:
	external_function_call
		{ $$ = $1;}
	|
		{ $$ = mk_nil();}
	;

external_function_call:
	component_reference EQUALS ident LPAR opt_expression_list RPAR
	{
	  $$ = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some($3),
			mk_none() /*lang?*/, 
			$1,
			$5),
			mk_none() /* annotation? */
			);

	}
	|
	ident LPAR opt_expression_list RPAR
	{
	  $$ = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some($1),
			mk_none() /*lang?*/, 
			mk_none() /*no component reference here*/,
			$3),
			mk_none() /* annotation? */
			);
	  /* FIXME: annotations? */
	}
	;

opt_expression_list:
	expression_list { $$ = $1;}
	|
		{ $$ = mk_nil();}
	;

element_list:
	element SEMICOLON element_list
		{ $$ = mk_cons(Absyn__ELEMENTITEM($1), $3);}
	|
	annotation SEMICOLON element_list
		{ $$ = mk_cons(Absyn__ANNOTATIONITEM($1), $3);}
	|
		{ $$ = mk_nil();}
	;

element:
		{ positionPush();}
	element1
		{
		  $$ = $1;
		  positionPop();
		}
	;

element1:
	import_clause
	{
	  $$ = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,
				mk_scon("import"),$1,
				mk_scon(positionFileName()),
				mk_icon(positionLineNo()),mk_none());
	}
	|
	extends_clause
	{
	  $$ = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,
				mk_scon("extends"),$1,
				mk_scon(positionFileName()),
				mk_icon(positionLineNo()),mk_none());
	}
	|
	optFINAL inner_outer KW_REPLACEABLE class_definition
		opt_constraining_clause comment
		{ $$ = parser_make_element($1, $2,  1, $4,  0,  $5, $6);}
	|
	optFINAL inner_outer class_definition
		{ $$ = parser_make_element($1, $2,  0, $3,  0,   0,  0);}
	|
	optFINAL inner_outer KW_REPLACEABLE component_clause
		opt_constraining_clause comment
		{ $$ = parser_make_element($1, $2,  1,  0,  $4, $5, $6);}
	|
	optFINAL inner_outer component_clause
		{ $$ = parser_make_element($1, $2,  0,  0,  $3,  0, 0);}
	;

inner_outer:
	KW_INNER	{ $$ = Absyn__INNER;}
|	KW_OUTER	{ $$ = Absyn__OUTER;}
|		{ $$ = Absyn__UNSPECIFIED;}
;

subscript:
	expression
		{ $$ = Absyn__SUBSCRIPT($1);}
	|
	COLON
		{ $$ = Absyn__NOSUB;}
	;

subscript_list:
	subscript COMMA subscript_list
		{ $$ = mk_cons($1,$3);}
	|
	subscript
		{ $$ = mk_cons($1,mk_nil());}
	;

array_subscripts:
	LBRACK subscript_list RBRACK
		{ $$ = $1;}
	;

opt_array_subscripts:
	array_subscripts
		{ $$ = $1;}
	|
		{ $$ = mk_nil();}
	;

type_specifier:
	name_path
		{ $$ = $1;}
	;

component_list:
	component_declaration COMMA component_list
		{ $$ = mk_cons($1, $3);}
	|
	component_declaration
		{ $$ = mk_cons($1, mk_nil());}
	;

component_declaration:
	declaration comment
		{ $$ = Absyn__COMPONENTITEM($1, $2);}
	;

declaration:
	ident opt_array_subscripts opt_modification
	{ 
	  $$ = Absyn__COMPONENT($1, $2, $3);
	}
	;	


modification:
	class_modification EQUALS expression
		{ $$ = Absyn__CLASSMOD($1, mk_some($3));}
	|
	class_modification
		{ $$ = Absyn__CLASSMOD($1, mk_none());}
	|
	EQUALS expression
		{ $$ = Absyn__CLASSMOD(mk_nil(), mk_some($2));}
	|
	ASSIGN expression
		{ $$ = Absyn__CLASSMOD(mk_nil(), mk_some($2));}
	;

opt_modification:
	modification
		{ $$ = $1;}
	|
		{ $$ = mk_nil();}
	;

class_modification:
	LPAR argument_list RPAR
		{ $$ = $2;}
	|
	LPAR RPAR
		{ $$ = mk_nil();}
	;

opt_class_modification:
	class_modification
		{ $$ = $1;}
	|
		{ $$ = mk_nil();}
	;

argument_list:
	argument COMMA argument_list
		{ $$ = mk_cons($1, $3);}
	|
	argument
		{ $$ = mk_cons($1, mk_nil());}
	;

argument:
	optEACH optFINAL component_reference opt_modification string_comment
	{
	  /* element_modification */
	  $$ = Absyn__MODIFICATION($1, $2, $3, $4, $5);
	}
	|
	KW_REDECLARE optEACH optFINAL KW_REPLACEABLE
		class_definition opt_constraining_clause
	{
	  $$ = Absyn__REDECLARATION($2, $3,
			Absyn__CLASSDEF(RML_TRUE,$5), $6);
	}
	|
	KW_REDECLARE optEACH optFINAL KW_REPLACEABLE
		component_clause1 opt_constraining_clause
	{
	  $$ = Absyn__REDECLARATION($2, $3, $5, $6);
	}
	|
	KW_REDECLARE optEACH optFINAL class_definition
	{
	  $$ = Absyn__REDECLARATION($2, $3,
		Absyn__CLASSDEF(RML_FALSE,$4), mk_none());
	}
	|
	KW_REDECLARE optEACH optFINAL component_clause1
	{
	  $$ = Absyn__REDECLARATION($2, $3, $4, mk_none());
	}
	;


initial_equation_clause:
	KW_INITIAL equation_clause
		{ $$ = Absyn__INITIALEQUATIONS($2);}
	;

equation_clause:
	KW_EQUATION equation_annotation_list
		{ $$ = $2;}
	;

equation_annotation_list:
	equation SEMICOLON opt_equation_annotation_list
		{ $$ = mk_cons($1, $3);}
	|
	annotation SEMICOLON opt_equation_annotation_list
		{ $$ = mk_cons(Absyn__EQUATIONITEMANN($1), $3);}
	;

opt_equation_annotation_list:
	equation_annotation_list
		{ $$ = $1;}
	|
		{ $$ = mk_nil();}
	;

constraining_clause:
	extends_clause
		{ $$ = $1;}
	;

opt_constraining_clause:
	constraining_clause
		{ $$ = mk_some($1);}
	|
		{ $$ = mk_none();}
	;

extends_clause:
	KW_EXTENDS name_path opt_class_modification
	{
	  $$ = Absyn__EXTENDS($2, $3);
	}
	;

algorithm_clause:
	KW_ALGORITHM algorithm_clause_list
		{ $$ = $2;}
	;

initial_algorithm_clause:
	KW_INITIAL KW_ALGORITHM algorithm_clause_list
		{ $$ = Absyn__INITIALALGORITHMS($3);}
	;

algorithm_clause_list:
	algorithm SEMICOLON algorithm_clause_list
		{ $$ = mk_cons($1, $3);}
	|
	annotation SEMICOLON algorithm_clause_list
		{ $$ = mk_cons(Absyn__ALGORITHMITEMANN($1), $3);}
	|
		{ $$ = mk_nil();}
	;

equation:
	simple_expression EQUALS expression
	{
	  /* Comment handling? Unclear what the ANTLR parser does; the
	   * walker seems to look for comments in the parse tree, but
	   * the parser doesn't seem to put any comment nodes in the
	   * parse tree...? For now, do mk_none() for all comments; this
	   * goes for all alternatives in this rule. */
	  $$ = Absyn__EQUATIONITEM(Absyn__EQ_5fEQUALS($1,$3), mk_none());
	}
	|
	conditional_equation_e
		{ $$ = Absyn__EQUATIONITEM($1, mk_none());}
	|
	for_clause_e
		{ $$ = Absyn__EQUATIONITEM($1, mk_none());}
	|
	connect_clause
		{ $$ = Absyn__EQUATIONITEM($1, mk_none());}
	|
	when_clause_e
		{ $$ = Absyn__EQUATIONITEM($1, mk_none());}
	|
	IDENT function_call
	{
	  $$ = Absyn__EQUATIONITEM(Absyn__EQ_5fNORETCALL($1,$2), mk_none());
	}
	;

algorithm:
	algorithm1 comment
		{ $$ = Absyn__ALGORITHMITEM($1, $2);}
	;

algorithm1:
	component_reference ASSIGN expression
		{ $$ = Absyn__ALG_5fASSIGN($1,$3);}
	|
	LPAR expression_list RPAR ASSIGN component_reference function_call
	{
	  $$ = Absyn__ALG_5fTUPLE_5fASSIGN(Absyn__TUPLE($2),
					Absyn__CALL($5,$6));
	}
	|
	conditional_equation_a
		{ $$ = $1;}
	|
	for_clause_a
		{ $$ = $1;}
	|
	while_clause
		{ $$ = $1;}
	|
	when_clause_a
		{ $$ = $1;}
	;

equation_elseif:
	KW_ELSEIF expression KW_THEN equation_list equation_elseif
		{ $$ = mk_cons(mk_box2(0,$2,$4), $5);}
	|
		{ $$ = mk_nil();}
	;

algorithm_elseif:
	KW_ELSEIF expression KW_THEN algorithm_list equation_elseif
		{ $$ = mk_cons(mk_box2(0,$2,$4), $5);}
	|
		{ $$ = mk_nil();}
	;

opt_equation_else:
	KW_ELSE equation_list
		{ $$ = $2;}
	|
		{ $$ = mk_nil();}
	;

opt_algorithm_else:
	KW_ELSE algorithm_list
		{ $$ = $2;}
	|
		{ $$ = mk_nil();}
	;

conditional_equation_e:
	KW_IF expression KW_THEN
	    equation_list
	    equation_elseif
	    opt_equation_else
	KW_END KW_IF
		{ $$ = Absyn__EQ_5fIF($1,$4,$5,$6);}
	;

conditional_equation_a:
	KW_IF expression KW_THEN
	    algorithm_list
	    algorithm_elseif
	    opt_algorithm_else
	KW_END KW_IF
		{ $$ = Absyn__ALG_5fIF($1,$4,$5,$6);}
	;

for_clause_e:
	KW_FOR ident KW_LOOP equation_list KW_END KW_FOR
		{ $$ = Absyn__EQ_5fFOR($2,mk_nil(),$6);}
	|
	KW_FOR ident KW_IN expression KW_LOOP equation_list KW_END KW_FOR
		{ $$ = Absyn__EQ_5fFOR($2,$4,$6);}
	;

for_clause_a:
	KW_FOR ident KW_LOOP algorithm_list KW_END KW_FOR
		{ $$ = Absyn__ALG_5fFOR($2,mk_nil(),$6);}
	|
	KW_FOR ident KW_IN expression KW_LOOP algorithm_list KW_END KW_FOR
		{ $$ = Absyn__ALG_5fFOR($2,$4,$6);}
	;

while_clause:
	KW_WHILE expression KW_LOOP algorithm_list KW_END KW_WHILE
		{ $$ = Absyn__ALG_5fWHILE($2,$4);}
	;

when_clause_e:
	KW_WHEN expression KW_THEN equation_list else_when_e KW_END KW_WHEN
		{ $$ = Absyn__EQ_5fWHEN_5fE($2,$4,$5);}
	;

else_when_e:
	KW_ELSEWHEN expression KW_THEN equation_list else_when_e
		{ $$ = mk_cons(mk_box2(0,$2,$4), $5);}
	|
		{ $$ = mk_nil();}
	;

when_clause_a:
	KW_WHEN expression KW_THEN algorithm_list else_when_a KW_END KW_WHEN
		{ $$ = Absyn__ALG_5fWHEN_5fA($2,$4,$5);}
	;

else_when_a:
	KW_ELSEWHEN expression KW_THEN algorithm_list else_when_e
		{ $$ = mk_cons(mk_box2(0,$2,$4), $5);}
	|
		{ $$ = mk_nil();}
	;

equation_list:
	equation SEMICOLON equation_list
		{ $$ = mk_cons($1,$3);}
	|
		{ $$ = mk_nil();}
	;

algorithm_list:
	algorithm SEMICOLON algorithm_list
		{ $$ = mk_cons($1,$3);}
	|
		{ $$ = mk_nil();}
	;

connect_clause:
	KW_CONNECT LPAR connector_ref COMMA connector_ref RPAR
		{ $$ = Absyn__EQ_5fCONNECT($3,$5);}
	;

connector_ref:
	ident opt_array_subscripts DOT ident opt_array_subscripts
		{ $$ = Absyn__CREF_5fQUAL($1,$2,Absyn__CREF_5fIDENT($4,$5));}
	|
	ident opt_array_subscripts
		{ $$ = Absyn__CREF_5fIDENT($1,$2);}
	;

expression:
	code_expression
		{ $$ = $1;}
	|
	if_expression
		{ $$ = $1;}
	|
	simple_expression
		{ $$ = $1;}
	;

code_expression:
	KW_CODE LPAR code_expression1 RPAR
		{ $$ = $3;}
	;

code_expression1:
	expression
		{ $$ = Absyn__CODE(Absyn__C_5fEXPRESSION($1));}
	|
	modification
		{ $$ = Absyn__CODE(Absyn__C_5fMODIFICATION($1));}
	|
	element optSEMICOLON
		{ $$ = Absyn__CODE(Absyn__C_5fELEMENT($1));}
	|
	equation_clause
	{
	  $$ = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_FALSE,
				RML_FETCH(RML_OFFSET(RML_UNTAGPTR($1),1))));
	}
	|
	initial_equation_clause
	{
	  $$ = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_TRUE,
				RML_FETCH(RML_OFFSET(RML_UNTAGPTR($1),1))));
	}
	|
	algorithm_clause
	{
	  $$ = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_FALSE,
				RML_FETCH(RML_OFFSET(RML_UNTAGPTR($1),1))));
	}
	|
	initial_algorithm_clause
	{
	  $$ = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_TRUE,
				RML_FETCH(RML_OFFSET(RML_UNTAGPTR($1),1))));
	}
	;

if_expression:
	KW_IF expression
	KW_THEN expression elseif_expression_list
	KW_ELSE expression
		{ $$ = Absyn__IFEXP($2,$4,$7,$5);}
	;

elseif_expression_list:
	KW_ELSEIF expression KW_THEN expression elseif_expression_list
		{ $$ = mk_cons(mk_box2(0,$2,$4), $5);}
	|
		{ $$ = mk_nil();}
	;

simple_expression:
	logical_expression COLON logical_expression COLON logical_expression
		{ $$ = Absyn__RANGE($1,mk_some($3),$5);}
	|
	logical_expression COLON logical_expression
		{ $$ = Absyn__RANGE($1,mk_none(),$3);}
	|
	logical_expression
		{ $$ = $1;}
	;

logical_expression:
	logical_term KW_OR logical_expression
		{ $$ = Absyn__LBINARY($1,Absyn__OR,$3);}
	|
	logical_term
		{ $$ = $1;}
	;

logical_term:
	logical_factor KW_AND logical_term
		{ $$ = Absyn__LBINARY($1,Absyn__AND,$3);}
	|
	logical_factor
		{ $$ = $1;}
	;

logical_factor:
	KW_NOT relation
		{ $$ = Absyn__LUNARY(Absyn__NOT,$2);}
	|
	relation
		{ $$ = $1;}
	;

relation:
	arithmetic_expression rel_op arithmetic_expression
		{ $$ = Absyn__RELATION($1,$2,$3);}
	;

rel_op:
	LESS		{ $$ = Absyn__LESS;}
|	LESSEQ		{ $$ = Absyn__LESSEQ;}
|	GREATER		{ $$ = Absyn__GREATER;}
|	GREATEREQ	{ $$ = Absyn__GREATEREQ;}
|	EQEQ		{ $$ = Absyn__EQUAL;}
|	LESSGT		{ $$ = Absyn__NEQUAL;}
;


arithmetic_expression:
	unary_arithmetic_expression
	|
	unary_arithmetic_expression PLUS arithmetic_expression
		{ $$ = Absyn__BINARY($1,Absyn__ADD,$3);}
	|
	unary_arithmetic_expression MINUS arithmetic_expression
		{ $$ = Absyn__BINARY($1,Absyn__SUB,$3);}
	;

unary_arithmetic_expression:
	PLUS term { $$ = Absyn__UNARY(Absyn__UPLUS,$2);}
	|
	MINUS term { $$ = Absyn__UNARY(Absyn__UMINUS,$2);}
	|
	term { $$ = $1;}
	;

term:
	factor STAR term { $$ = Absyn__BINARY($1,Absyn__MUL,$3);}
	|
	factor SLASH term { $$ = Absyn__BINARY($1,Absyn__DIV,$3);}
	|
	factor { $$ = $1;}
	;

factor:
	primary POWER primary { $$ = Absyn__BINARY($1,Absyn__POW,$3);}
	|
	primary { $$ = $1;}
	;

expression_matrix_list:
	expression_list SEMICOLON expression_matrix_list
		{ $$ = mk_cons($1, $3);}
	|
	expression_list
		{ $$ = mk_cons($1, mk_nil());}
	;

expression_matrix:
	expression_matrix_list
		{ $$ = Absyn__MATRIX($1);}
	;

primary:
	INTEGER_LITERAL { $$ = Absyn__INTEGER(tok_rml_int($1));}
	|
	REAL_LITERAL { $$ = Absyn__REAL(tok_rml_real($1));}
	|
	STRING_LITERAL { $$ = Absyn__STRING(tok_rml_str($1));}
	|
	KW_FALSE { $$ = Absyn__BOOL(RML_FALSE);}
	|
	KW_TRUE { $$ = Absyn__BOOL(RML_TRUE);}
	|
	component_reference__function_call { $$ = $1;}
	|
	LPAR expression_list RPAR { $$ = $1;}
	|
	LBRACK expression_matrix RBRACK { $$ = $2;}
	|
	LBRACE for_or_expression_list RBRACE { $$ = $2;}
	;

component_reference__function_call:
	component_reference function_call
		{ $$ = Absyn__CALL($1, $2);}
	|
	component_reference
		{ $$ = Absyn__CREF($1);}
	|
	KW_INITIAL LPAR RPAR
		{ $$ = Absyn__CALL(Absyn__CREF_5fIDENT(
					mk_scon("initial"), mk_nil()),
				   Absyn__FUNCTIONARGS(mk_nil(), mk_nil()));
 		}
	;

name_path:
	ident DOT name_path { $$ = Absyn__QUALIFIED($1, $3);}
	|
	ident { $$ = Absyn__IDENT($1);}
	;

component_reference:
	ident opt_array_subscripts DOT component_reference
		{ $$ = Absyn__CREF_5fQUAL($1,$2,$4);}
	|
	ident opt_array_subscripts
		{ $$ = Absyn__CREF_5fIDENT($1,$2);}
	;

function_call:
	LPAR function_arguments RPAR
		{ $$ = $2;}
	;

function_arguments:
	for_or_expression_list
	opt_named_arguments
		{ /* FIXME */;}
	;

opt_named_arguments:
	named_arguments
		{ /* FIXME */;}
	|
		{ $$ = mk_nil();}
	;

for_or_expression_list:
	expression COMMA expression_list
		{ $$ = mk_cons($1,$2);}
	|
	expression KW_FOR ident KW_IN expression
		{ $$ = Absyn__FOR_5fITER_5fFARG($1,$3,$5);}
	|
	expression KW_FOR ident
		{ $$ = Absyn__FOR_5fITER_5fFARG($1,$3,mk_nil());}
	;

named_arguments:
	named_argument named_arguments
		{ $$ = mk_cons($1,$2);}
	|
		{ $$ = mk_nil();}
	;

named_arguments2: { /* ANTLR relic? should this rule do anything? */};

named_argument:
	ident EQUALS expression
		{ $$ = Absyn__NAMEDARG($1,$3);}
	;

expression_list:
	expression COMMA expression_list
		{ $$ = mk_cons($1,$3);}
	|
	expression
		{ $$ = mk_cons($1,mk_nil());}
	;

comment:
	string_comment opt_annotation
		{ $$ = mk_some(Absyn__COMMENT($2, $1));}
	|
		{ $$ = mk_none();}
	;

string_comment:
		{ parserCommentBuffer[0] = 0;}
	string_concats
		{ $$ = mk_some(mk_rml_str(parserCommentBuffer));}
	;

string_comment_part:
	STRING_LITERAL
		{
		    if (strlen(yyCommentBuffer)+strlen($1) < MAXCOMMENT)
			strcat(yyCommentBuffer, $1);
		}
	;

string_concats:
	string_comment_part PLUS string_concats
		{ $$ = $1; /* FIXME */ }
	|
	string_comment_part
		{ $$ = $1;}
	;
		    
annotation:
	KW_ANNOTATION class_modification
		{ $$ = Absyn__ANNOTATION($2);}
	;

opt_annotation:
	annotation
		{ $$ = $1;}
	|
		{ $$ = mk_none();}
	;

ident:
	IDENT
		{ $$ = tok_rml_string($1);}
	;

/*********************************************/
/**************** RML Grammar ****************/
/*********************************************/

rml_file:
	KW_MODULE ident COLON rml_interface rml_definitions
		{ $$ = Absyn__RML_5fFILE($2, $4, $5);}
	|
	KW_INTERFACE ident COLON rml_interface
		{ $$ = Absyn__RML_5fFILE($2, $4, mk_nil());}
	;

rml_interface:
	rml_interface_item_star
		{ $$ = $1;}
	KW_END
	;

rml_interface_item_star:
	rml_interface_item rml_interface_item_star
		{ $$ = mk_cons($1, $2);}
	|
		{ $$ = mk_nil();}
	;

rml_interface_item:
	KW_WITH STRING_LITERAL
		{ $$ = Absyn__WITH(tok_rml_string($2));}
	|
	KW_TYPE tyvarparseq ident
		{ $$ = mk_nil(); /* FIXME!! */;}
	|
	KW_TYPE typbind_plus
		{ $$ = $2;}
	|
	KW_DATATYPE datbind_plus withbind
		{ $$ = $2; /* FIXME: withbind */}
	|
	KW_VAL ident COLON ty
		{ $$ = Absyn__VALINTERFACE($2, $4);}
	|
	KW_RELATION ident COLON ty
		{ $$ = Absyn__RELATION_5fINTERFACE($2, $4);}
	;

rml_definitions:
	rml_definition_item rml_definitions
		{ $$ = mk_cons($1, $2);}
	|
		{ $$ = mk_nil();}
	;

rml_definition_item:
	KW_WITH STRING_LITERAL
		{ $$ = Absyn__WITH(tok_rml_string($2));}
	|
	KW_TYPE typbind_plus
		{ $$ = $2;}
	|
	KW_DATATYPE datbind_plus withbind
		{ $$ = Absyn__DATATYPEDECL($2); /* FIXME: support withbind */}
	|
	KW_VAL ident EQUALS rml_expression
		{ $$ = Absyn__VALDEF($2, $4);}
	|
	KW_RELATION relbind
		{ $$ = $2;}
	;

opt_type:
	COLON ty
		{ $$ = $2;}
	|
	empty
		{ $$ = mk_nil();}
	;

relbind:
	ident opt_type EQUALS clause_plus default_opt KW_END
		{ $$ = Absyn__RELATION_5fDEFINITION($1, $2, $4);}
	;

withbind:
		{ $$ = mk_nil();}
	|
	KW_WITHTYPE typbind_plus
		{ $$ = $2;}
	;

typbind_plus:
	typbind KW_AND typbind_plus /* do we really want to support this? */
		{ $$ = mk_cons($1, $3);}
	|
	typbind
		{ $$ = $1;}
	;

typbind:
	tyvarseq ident EQUALS ty
		{ $$ = mk_nil(); /* FIXME! */ }
	;

datbind_plus:
	datbind KW_AND datbind_plus
		{ $$ = mk_cons($1, $3);}
	|
	datbind
		{ $$ = mk_cons($1, mk_nil());}
	;

datbind:
	tyvarseq ident EQUALS conbind_plus
		{ $$ = Absyn__DATATYPE($2, $3); /* FIXME: $1 */ }
	;

conbind_plus:
	conbind PIPEBAR conbind_plus
		{ $$ = mk_cons($1, $3);}
	|
	conbind
		{ $$ = mk_cons($1, mk_nil());}
	;

conbind:
	ident
		{ $$ = Absyn__DTCONS($1, mk_nil());}
	|
	ident KW_OF tuple_ty
		{ $$ = Absyn__DTCONS($1, $3);}
	;

default_opt:
	/* empty */
	|
	KW_DEFAULT clause_plus
		{ /* FIXME */}
	;

clause_plus:
	clause clause_plus
		{ $$ = mk_cons($1, $2);}
	|
	clause
		{ $$ = mk_cons($1, mk_nil());}
	;

clause:
	KW_RULE conjunctive_goal_opt DASHES ident seq_pat result
		{ $$ = Absyn__RMLRULE($4, $5, $2, $6);}
	|
	KW_AXIOM ident seq_pat result
		{ $$ = Absyn__RMLRULE($2, $3, mk_nil(), $4);}
	;

result:
	/* empty */
		{ $$ = Absyn__RMLNoResult;}
	|
	YIELDS seq_exp
		{ $$ = Absyn__RMLResultExp($2);}
	|
	YIELDS KW_FAIL
		{ $$ = Absyn__RMLResultFail;}
	;

conjunctive_goal_opt:
	/* empty */
		{ $$ = mk_nil();}
	|
	conjunctive_goal
		{ $$ = $1;}
	;

conjunctive_goal:
	atomic_goal AMPERSAND conjunctive_goal
		{ $$ = Absyn__RMLGOAL_AND($1, $3);}
|
	atomic_goal
		{ $$ = $1;}
	;

atomic_goal:
	longorshortid seq_exp res_pat
		{ $$ = Absyn__RMLGOAL_5fRELATION($1, $2, $3);}
	|
	ident EQUALS rml_expression
		{ $$ = Absyn__RMLGOAL_5fEQUAL($1, $3);}
	|
	KW_LET ident EQUALS rml_expression
		{ $$ = Absyn__RMLGOAL_5fLET($2, $4);}
	|
	KW_NOT atomic_goal
		{ $$ = Absyn__RMLGOAL_5fNOT($2);}
	|
	LPAR conjunctive_goal RPAR
		{ $$ = $2;}
	;

/* RML Expressions */

rml_expression:
	rml_exp_a COLONCOLON rml_expression
		{ $$ = Absyn__RMLCONS($1, $2);}
	|
	rml_exp_a
		{ $$ = $1;}
	;

rml_expression_list:
	rml_expression COMMA rml_expression_list
		{ $$ = mk_cons($1, $3);}
|
	rml_expression
		{ $$ = mk_cons($1, mk_nil());}
;

rml_exp_a:
	LPAR RPAR
		{ $$ = mk_nil();}
	|
	LPAR rml_expression RPAR
		{ $$ = $2;}
	|
	LPAR rml_expression_list RPAR
		{ $$ = $2;}
	|
	rml_exp_c
		{ $$ = $1;}
	;

rml_exp_b:
	rml_exp_c COLONCOLON rml_exp_b
		{ $$ = Absyn__RMLCONS($1, $3);}
	|
	rml_exp_c
		{ $$ = $1;}
	;

rml_exp_c:
	longorshortid rml_exp_star
		{ $$ = Absyn__RMLCALL($1, $2);}
	|
	rml_addsub
		{ $$ = $1;}
	;

rml_addsub:
	rml_muldiv PLUS rml_addsub
		{ $$ = Absyn__BINARY($1, Absyn__ADD, $3);}
	|
	rml_muldiv MINUS rml_addsub
		{ $$ = Absyn__BINARY($1, Absyn__SUB, $3);}
	|
	rml_muldiv
		{ $$ = $1;}
	;

rml_muldiv:
	rml_unary STAR rml_muldiv
		{ $$ = Absyn__BINARY($1, Absyn__MUL, $3);}
	|
	rml_unary DIV rml_muldiv
		{ $$ = Absyn__BINARY($1, Absyn__DIV, $3);}
	|
	rml_unary 
		{ $$ = $1;}
	;

rml_unary:
	MINUS rml_unary
		{ $$ = Absyn__UNARY(Absyn__UMINUS, $2);}
	|
	rml_primary
		{ $$ = $1;}
	;

rml_primary:
	rml_literal
		{ $$ = $1;}
	|
	longorshortid
		{ $$ = $1;}
	|
	LBRACK rml_exp_comma_star RBRACK
		{ $$ = $2;}
	|
	LPAR rml_expression RPAR
		{ $$ = $2;}
	|
	LPAR RPAR
		{ $$ = RML_NILHDR;}
	;

rml_exp_comma_star:
	/* empty */
		{ $$ = mk_nil();}
	|
	rml_exp_comma_plus
		{ $$ = $1;}
	;

rml_exp_comma_plus:
	rml_expression COMMA rml_exp_comma_plus
		{ $$ = mk_cons($1, $3);}
|
	rml_expression
		{ $$ = mk_cons($1, mk_nil());}
	;

rml_exp_star:
	LPAR rml_exp_comma_star RPAR
		{ $$ = $2;}
;

seq_exp:
	/* empty */
		{ $$ = mk_nil();}
	|
	rml_exp_b
		{ $$ = mk_cons($1, mk_nil());}
	|
	rml_exp_star
		{ $$ = $1;}
;

/* RML Patterns */

pat:
	ident KW_AS pat
		{ $$ = Absyn__RMLPAT_5fAS($1, $3);}
	|
	pat_a
		{ $$ = $1;}
	;

pat_a:
	pat_b COLONCOLON pat_a
		{ $$ = Absyn__RMLPAT_5fCONS($1, $3);}
	|
	pat_b
		{ $$ = $1;}
	;

pat_b:
	LPAR RPAR
		{ $$ = Absyn__RMLPAT_5fNIL;}
	|
	LPAR pat RPAR
		{ $$ = $1;}
	|
	LPAR pat COMMA pat_comma_plus RPAR
		{ $$ = Absyn__RMLPAT_5fSTRUCT(mk_cons($2, $4));}
	|
	pat_d
		{ $$ = $1;}
	;

pat_c:
	pat_d COLONCOLON pat_c
		{ $$ = Absyn__RMLPAT_5fCONS($1, $3);}
	|
	pat_d
		{ $$ = $1;}
	;

pat_d:
	longorshortid pat_star
		{ $$ = Absyn__RMLPAT_5fCALL($1, $2);}
	|
	longorshortid pat_e
		{ $$ = Absyn__RMLPAT_5fCALL($1, $2);}
	|
	pat_e
		{ $$ = $1;}
	;

pat_e:
	UNDERSCORE
		{ $$ = Absyn__RMLPAT_5fWILDCARD;}
	|
	rml_literal
		{ $$ = Absyn__RMLPAT_5fLITERAL($1);}
	|
	longid
		{ $$ = Absyn__RMLPAT_5fIDENT($1);}
	|
	ident
		{ $$ = Absyn__RMLPAT_5fIDENT($1);}
	|
	LBRACK pat_comma_star RBRACK
		{ $$ = $1; /* CHECKME */}
	;

res_pat: /* CHECKME */
	/* empty */
		{ $$ = mk_nil();}
	|
	YIELDS seq_pat
		{ $$ = $2;}
	;

seq_pat:
	/* empty */
		{ $$ = mk_nil();}
	|
	pat_c
		{ $$ = $1;}
	|
	pat_star
		{ $$ = $1;}
	;

pat_star:
	LPAR pat_comma_star RPAR
		{ $$ = $2;}
	;

pat_comma_star:
	/* empty */
		{ $$ = mk_nil();}
	|
	pat_comma_plus
		{ $$ = $1;}
	;

pat_comma_plus:
	pat COMMA pat_comma_plus
		{ $$ = mk_cons($1, $3);}
	|
	pat
		{ $$ = mk_cons($1, mk_nil());}
	;

/* RML Literals */

rml_literal:
	CHAR_LITERAL
		{ $$ = Absyn__RMLLIT_5fCHAR(tok_rml_char($1));}
	|
	INTEGER_LITERAL
		{ $$ = Absyn__RMLLIT_5fINTEGER(tok_rml_int($1));}
	|
	REAL_LITERAL
		{ $$ = Absyn__RMLLIT_5fREAL(tok_rml_real($1));}
	|
	STRING_LITERAL
		{ $$ = Absyn__RMLLIT_5fSTRING(tok_rml_string($1));}
	;

/* RML Types */

ty:
	seq_ty YIELDS seq_ty
		{ $$ = Absyn__RMLTYPE_5fSIGNATURE(
                              Absyn__CALLSIGN($1, $3));}
	|
	tuple_ty
		{ $$ = Absyn__RMLTYPE_5fTUPLE($1);}
	;

tuple_ty:
	ty_sans_star STAR tuple_ty
		{ $$ = mk_cons($1, $3);}
	|
	ty_sans_star
		{ $$ = mk_cons($1, mk_nil());}
	;

ty_sans_star:
/* **FIXME!**
	ty_sans_star longorshortid
	|
	LPAR ty_comma_seq2 RPAR longorshortid
	|
*/
	LPAR ty RPAR
		{ $$ = $2;}
	|
	tyvar
		{ $$ = Absyn__RMLTYPE_5fTYVAR($1);}
	|
	longorshortid
		{ $$ = Absyn__RMLTYPE_5fUSERDEFINED($1);}
	;

ty_comma_seq2:
	ty COMMA ty_comma_seq2
		{ $$ = mk_cons($1, $3);}
	|
	ty COMMA ty
		{ $$ = mk_cons($1, mk_cons($3, mk_nil()));}
	;

seq_ty:
	LPAR RPAR
		{ $$ = mk_nil();}
	|
	LPAR ty_comma_seq2 RPAR
		{ $$ = $2;}
	|
	tuple_ty
		{ $$ = $1;}
	;

tyvarseq1:
	tyvar COMMA tyvarseq1
		{ $$ = mk_cons($1, $3);}
	|
	tyvar
		{ $$ = mk_cons($1, mk_nil());}
	;

tyvarparseq:
	LPAR tyvarseq1 RPAR
		{ $$ = $2;}
	;

tyvarseq:
	/* empty */
		{ $$ = mk_nil();}
	|
	tyvar
		{ $$ = $1;}
	|
	tyvarparseq
		{ $$ = $1;}
	;

/* RML Identifiers */

longid:
	ident DOT ident
		{ $$ = Absyn__RMLLONGID($1, $3);}
	;

longorshortid:
	longid
		{ $$ = $1;}
	|
	ident
		{ $$ = Absyn__RMLSHORTID($1);}
	;

ident:
	IDENT
		{ $$ = to_rml_string($1);}
	;

tyvar:
	TYVARIDENT
		{ $$ = mk_scon($1);}
	;

empty:	;


%%

#define PCOMMENTBUF 2000

static char parserCommentBuffer[PCOMMENTBUF+10];

#define MAXPOSINDEX   50
static int posIndex  = 0;
static int posLineNo[MAXPOSINDEX+1];
extern int yylineno;

void positionPush()
{
    if (++posIndex > 50)
	yyerror("Internal error: positionPush(): overflow.\n");
    posLineNo[posIndex] = yylineno;
}

void positionPop()
{
    if (--posIndex < 0)
	yyerror("Internal error: positionPop(): underflow.\n");
}

int positionLineNo()
{
    return posLineNo[posIndex];
}

char *positionFileName()
{
    return "NoFile";
}

void *parser_make_element(int   is_final,
			  void *innerouter,
			  int   is_replaceable,
			  void *classdef,
			  void *componentclause,
			  void *constraint,
			  void *comment)
{
    void *final       = is_final ? RML_TRUE : RML_FALSE;
    void *replaceable = is_replaceable ? RML_TRUE : RML_FALSE;

    if (componentclause)
    {
	/* Declaration. */
	return Absyn__ELEMENT(final,
			      replaceable,
			      is_replaceable ? Absyn__UNSPECIFIED : innerouter,
			      c_rml_string(is_replaceable
                                           ? "replaceable component"
                                           : "component"),
			      componentclause,
			      mk_scon(positionFileName()),
			      mk_scon(positionLineNo()),
			      constraint ? mk_some(constraint) : mk_none());
    }
    else if (classdef)
    {
	/* Definition. */
	return Absyn__ELEMENT(final,
			      replaceable,
			      is_replaceable ? Absyn__UNSPECIFIED : innerouter,
			      c_rml_string(is_replaceable
                                           ? "?replaceable classdef?"
                                           : "?classdef?"),
			      Absyn__CLASSDEF(replaceable, classdef),
			      mk_scon(positionFileName()),
			      mk_scon(positionLineNo()),
			      constraint ? mk_some(constraint) : mk_none());

    }
    else
	yyerror("Internal error in parser_make_element().\n");
}

void **tempQuadMake(void *v1, void *v2, void *v3, void *v4)
{
    void **quad = malloc(sizeof(void *)*4);
    if (!quad)
	yyerror("Out of memory.");
    quad[0] = v1;
    quad[1] = v2;
    quad[2] = v3;
    quad[3] = v4;
    return quad;
}

void *tempQuadGet(void **quad, int element)
{
    if (!quad || element < 0 || element > 3)
	yyerror("Internal error: tempQuadGet(): bad arguments.");
    return quad[element];
}

void tempQuadFree(void **quad)
{
    if (quad)
	free(quad);
}
