/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
grammar Modelica;

options {
  ASTLabelType = pANTLR3_BASE_TREE;
  language = C;
}

tokens {
  T_ALGORITHM	= 'algorithm'	;
  T_AND		= 'and'		;
  T_ANNOTATION	= 'annotation'	;
  BLOCK		= 'block'	;
  CODE		= '$Code'	;
  CLASS		= 'class'	;
  CONNECT	= 'connect'	;
  CONNECTOR	= 'connector'	;
  CONSTANT	= 'constant'	;
  DISCRETE	= 'discrete'	;
  DER           = 'der' 	;
  DEFINEUNIT    = 'defineunit'  ;
  EACH		= 'each'	;
  ELSE		= 'else'	;
  ELSEIF	= 'elseif'	;
  ELSEWHEN	= 'elsewhen'	;
  T_END		= 'end'		;
  ENUMERATION	= 'enumeration'	;
  EQUATION	= 'equation'	;
  ENCAPSULATED	= 'encapsulated';
  EXPANDABLE	= 'expandable'  ;
  EXTENDS	= 'extends'     ;
  CONSTRAINEDBY = 'constrainedby' ;
  EXTERNAL	= 'external'	;
  T_FALSE	= 'false'	;
  FINAL		= 'final'	;
  FLOW		= 'flow'	;
  FOR		= 'for'		;
  FUNCTION	= 'function'	;
  IF		= 'if'		;
  IMPORT	= 'import'	;
  T_IN		= 'in'		;
  INITIAL	= 'initial'	;
  INNER		= 'inner'	;
  T_INPUT	= 'input'	;
  LOOP		= 'loop'	;
  MODEL		= 'model'	;
  T_NOT		= 'not'		;
  T_OUTER	= 'outer'	;
  OPERATOR	= 'operator'; 
  OVERLOAD	= 'overload'	;
  T_OR		= 'or'		;
  T_OUTPUT	= 'output'	;
  PACKAGE	= 'package'	;
  PARAMETER	= 'parameter'	;
  PARTIAL	= 'partial'	;
  PROTECTED	= 'protected'	;
  PUBLIC	= 'public'	;
  RECORD	= 'record'	;
  REDECLARE	= 'redeclare'	;
  REPLACEABLE	= 'replaceable'	;
  RESULTS	= 'results'	;
  THEN		= 'then'	;
  T_TRUE	= 'true'	;
  TYPE		= 'type'	;
  UNSIGNED_REAL	= 'unsigned_real';
  WHEN		= 'when'	;
  WHILE		= 'while'	;
  WITHIN	= 'within' 	;
  RETURN	= 'return'  ;
  BREAK		= 'break'	;
  STREAM	= 'stream'	; /* for Modelica 3.1 stream connectors */	
  /* MetaModelica keywords. I guess not all are needed here. */
  AS		= 'as'	          ;
  CASE		= 'case'	  ;
  EQUALITY	= 'equality'      ;
  FAILURE	= 'failure'       ;
  LOCAL		= 'local'	  ;
  MATCH		= 'match'	  ;
  MATCHCONTINUE	= 'matchcontinue' ;
  UNIONTYPE	= 'uniontype'	  ;
  WILD		= '_'		  ;
  SUBTYPEOF   	= 'subtypeof'     ;
  COLONCOLON ;
  
  // ---------
  // Operators
  // ---------
  
  DOT		= '.'           ;  
  LPAR		= '('		;
  RPAR		= ')'		;
  LBRACK	= '['		;
  RBRACK	= ']'		;
  LBRACE	= '{'		;
  RBRACE	= '}'		;
  EQUALS	= '='		;
  ASSIGN	= ':='		;
  COMMA		= ','		;
  COLON		= ':'		;
  SEMICOLON	= ';'		;
  /* elementwise operators */  
  PLUS_EW     	= '.+'  	; /* Modelica 3.0 */
  MINUS_EW    	= '.-'     	; /* Modelica 3.0 */    
  STAR_EW     	= '.*'     	; /* Modelica 3.0 */
  SLASH_EW    	= './'		; /* Modelica 3.0 */  
  POWER_EW    	= '.^' 		; /* Modelica 3.0 */
  
  /* MetaModelica operators */
  COLONCOLON    = '::'  	;
  MOD		= '%'   ;
  
  // parser tokens 
ALGORITHM_STATEMENT;
ARGUMENT_LIST;
CLASS_DEFINITION;
CLASS_EXTENDS ;
CLASS_MODIFICATION;
CODE_EXPRESSION;
CODE_MODIFICATION;
CODE_ELEMENT;
CODE_EQUATION;
CODE_INITIALEQUATION;
CODE_ALGORITHM;
CODE_INITIALALGORITHM;
COMMENT;
COMPONENT_DEFINITION;
DECLARATION	;
DEFINITION ;
ENUMERATION_LITERAL;
ELEMENT		;
ELEMENT_MODIFICATION		;
ELEMENT_REDECLARATION	;
EQUATION_STATEMENT;
EXTERNAL_ANNOTATION ;
INITIAL_EQUATION;
INITIAL_ALGORITHM;
IMPORT_DEFINITION;
IDENT_LIST;
EXPRESSION_LIST;
EXTERNAL_FUNCTION_CALL;
FOR_INDICES ;
FOR_ITERATOR ;
FUNCTION_CALL		;
INITIAL_FUNCTION_CALL		;
FUNCTION_ARGUMENTS;
NAMED_ARGUMENTS;
QUALIFIED;
RANGE2		;
RANGE3		;
STORED_DEFINITION ;
STRING_COMMENT;
UNARY_MINUS	;
UNARY_PLUS	;
UNARY_MINUS_EW ;
UNARY_PLUS_EW ;
UNQUALIFIED;
FLAT_IDENT;
TYPE_LIST;
EMPTY;
OPERATOR;
}


@includes {
  #include <stdio.h>
  #include "rml.h"
  #include "Absyn.h"
  #define mk_rcon(x) 0
  #define mk_scon(x) 0
  #define mk_box0(x1) 0
  #define mk_box1(x1,x2) 0
  #define mk_box2(x1,x2,x3) 0
  #define mk_box3(x1,x2,x3,x4) 0
  #define mk_box4(x1,x2,x3,x4,x5) 0
  #define mk_box5(x1,x2,x3,x4,x5,x6) 0
  #define mk_box6(x1,x2,x3,x4,x5,x6,x7) 0
  #define mk_box7(x1,x2,x3,x4,x5,x6,x7,x8) 0
  #define mk_box8(x1,x2,x3,x4,x5,x6,x7,x8,x9) 0
  #define mk_box9(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) 0
  #define mk_cons(x,y) 0
  #define getCurrentTime(void) 0
  #define token_to_scon(tok) mk_scon(tok.text->chars)
  #define INFO(void) Absyn__INFO(file, isReadOnly, \$start->line, \$start->charPosition, \$stop->line, \$stop->charPosition, getCurrentTime())
  typedef unsigned char bool;
}

@members
{
}




/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/

STAR		: '*'('.')? 				;
MINUS		: '-'('.')?					;
PLUS		: '+'('.'|'&')?				; 
LESS		: '<'('.')?					;
LESSEQ		: '<='('.')?				;
LESSGT		: '!='('.')?|'<>'('.')?		;
GREATER		: '>'('.')?					;
GREATEREQ	: '>='('.')?				;
EQEQ		: '=='('.'|'&')?			;
POWER		: '^'('.')?					;
SLASH		: '/'('.')?					;

WS : ( ' ' | '\t' | NL )+ { $channel=HIDDEN; }
	;
	
LINE_COMMENT
    : '//' ( ~('\r'|'\n')* ) (NL|EOF) { $channel=HIDDEN; }
    ;	

ML_COMMENT
    :   '/*' (options {greedy=false;} : .)* '*/' { $channel=HIDDEN;  }
    ;

fragment 
NL: (('\r')? '\n');

IDENT :
		   ('_' {  $type = WILD; } | NONDIGIT { $type = IDENT; })
		   (('_' | NONDIGIT | DIGIT) { $type = IDENT; })*
		| (QIDENT { $type = IDENT; })
		;

fragment
QIDENT :
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

fragment
QCHAR :	NL	| '\t' | ~('\n' | '\t' | '\r' | '\\' | '\'');

fragment
NONDIGIT : 	('a'..'z' | 'A'..'Z');

fragment
DIGIT :
	'0'..'9'
	;

fragment
EXPONENT :
	('e'|'E') ('+' | '-')? (DIGIT)+
	;


UNSIGNED_INTEGER :
    (DIGIT)+ ('.' (DIGIT)* { $type = UNSIGNED_REAL; } )? (EXPONENT { $type = UNSIGNED_REAL; } )?
  | ('.' { $type = DOT; } )
      ( (DIGIT)+ { $type = UNSIGNED_REAL; } (EXPONENT { $type = UNSIGNED_REAL; } )?
         | /* Modelica 3.0 element-wise operators! */
         (('+' { $type = PLUS_EW; }) 
          |('-' { $type = MINUS_EW; }) 
          |('*' { $type = STAR_EW; }) 
          |('/' { $type = SLASH_EW; }) 
          |('^' { $type = POWER_EW; })
          )?
      )
	;

STRING : '"' STRING_GUTS '"'
       {SETTEXT($STRING_GUTS.text);};

fragment
STRING_GUTS: (SCHAR | SESCAPE)*
       ;

fragment
SCHAR :	NL | '\t' | ~('\n' | '\t' | '\r' | '\\' | '"');

fragment
SESCAPE : '\\' ('\\' | '"' | '\'' | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');


/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

stored_definition returns [void* ast] :
	(within=within_clause SEMICOLON)?
	cl=class_definition_list?
    {
      ast = Absyn__PROGRAM(cl || mk_nil(),within || Absyn__TOP,Absyn__TIMESTAMP(mk_rcon(0.0),mk_rcon(getCurrentTime())));
    }
	;

within_clause returns [void* ast] :
  	WITHIN (name_path)?
	;

class_definition_list returns [void* ast] :
  ((f=FINAL)? cd=class_definition[f != NULL] SEMICOLON) cl=class_definition_list?
    {
      ast = mk_cons(cd, cl || mk_nil());
    }
  ;

class_definition [bool final] returns [void* ast]
@declarations {
  void* name = 0;
}
  :
	((e=ENCAPSULATED)? (p=PARTIAL)? class_type class_specifier[&name])
    {
      ast = Absyn__CLASS(
                name,
                RML_PRIM_MKBOOL(p != 0),
                RML_PRIM_MKBOOL(final),
                RML_PRIM_MKBOOL(e != 0),
                class_type,
                class_specifier,
                INFO()
            );
    }
	;

class_type returns [void* ast] :
	( CLASS { ast = Absyn__R_5fCLASS; }
	| MODEL { ast = Absyn__R_5fMODEL; }
	| RECORD { ast = Absyn__R_5fRECORD; }
	| BLOCK { ast = Absyn__R_5fBLOCK; }
	| ( e=EXPANDABLE )? CONNECTOR { ast = e ? Absyn__R_5fEXP_5fCONNECTOR : Absyn__R_5fCONNECTOR; }
	| TYPE { ast = Absyn__R_5fTYPE; }
	| PACKAGE { ast = Absyn__R_5fPACKAGE; }
	| FUNCTION { ast = Absyn__R_5fFUNCTION; } 
	| UNIONTYPE { ast = Absyn__R_5fUNIONTYPE; }
	| OPERATOR (f=FUNCTION | r=RECORD)? 
          { 
            ast = f ? Absyn__R_5fOPERATOR_5fFUNCTION : 
                  r ? Absyn__R_5fOPERATOR_5fRECORD : 
                  Absyn__R_5fOPERATOR;
          }
	)
	;

class_specifier [void** name] returns [void* ast] :
        i1=IDENT {*name = mk_scon(i1.text->chars);} spec=class_specifier2 {ast = spec;}
    |   EXTENDS i1=IDENT {*name = token_to_scon(i1);} (class_modification)? string_comment composition T_END i2=IDENT
        ;

class_specifier2 returns [void* ast] :
( 
  string_comment c=composition T_END i2=IDENT 
  /* { fprintf(stderr,"position composition for \%s -> \%d\n", $i2.text->chars, $c->getLine()); } */
| EQUALS base_prefix type_specifier ( class_modification )? comment
| EQUALS enumeration
| EQUALS pder
| EQUALS overloading
| SUBTYPEOF type_specifier
)
;

pder returns [void* ast] :
  DER LPAR func=name_path COMMA var_lst=ident_list RPAR cmt=comment
  {
    ast = Absyn__PDER(func, var_lst, cmt ? mk_some(cmt) : mk_none());
  }
  ;

ident_list returns [void* ast]:
	i=IDENT (COMMA il=ident_list)?
    {
      ast = mk_cons(i, il ? il : mk_nil());
    }
  ;


overloading returns [void* ast] :
	OVERLOAD LPAR name_list RPAR cmt=comment
    {
			ast = Absyn__OVERLOAD(name_list, cmt ? mk_some(cmt) : mk_none());
		}
	;

base_prefix:
	type_prefix
	;

name_list returns [void* ast] :
	n=name_path (COMMA nl=name_list)?
    {
      ast = mk_cons(n, nl ? nl : mk_nil());
    }
	;

enumeration returns [void* ast] :
	ENUMERATION LPAR (el=enum_list | c=COLON ) RPAR comment
    {
      if (c) {
        ast = Absyn__ENUMERATION(Absyn__ENUM_5fCOLON, cmt ? mk_some(cmt) : mk_none());
      } else {
        ast = Absyn__ENUMERATION(Absyn__ENUMLITERALS(el), cmt ? mk_some(cmt) : mk_none());
      }
    }
	;

enum_list returns [void* ast] :
	e=enumeration_literal ( COMMA el=enum_list )?
    {
      ast = mk_cons(e, el || mk_nil());
    }
	;

enumeration_literal returns [void* ast] :
	i1=IDENT c1=comment
    {
      ast = Absyn__ENUMLITERAL(token_to_scon(i1),c1 ? mk_some(c1) : mk_none());
    }
	;

composition :
	element_list
	( public_element_list
	| protected_element_list
	| initial_equation_clause
	| initial_algorithm_clause
	| equation_clause
	| algorithm_clause
	)*
	( external_clause )?
	;

external_clause :
        EXTERNAL
        ( language_specification )?
        ( external_function_call )?
        ( annotation )? SEMICOLON
        ( external_annotation )?
        ;

external_annotation:
	annotation SEMICOLON /* -> (EXTERNAL_ANNOTATION external_annotation) */
	;

public_element_list :
	PUBLIC element_list
	;

protected_element_list :
	PROTECTED element_list
	;

language_specification :
	STRING
	;

external_function_call :
	( component_reference EQUALS )?
	IDENT LPAR ( expression_list )? RPAR /* -> (EXTERNAL_FUNCTION_CALL external_function_call) */
	;

element_list :
	((e=element | a=annotation ) s=SEMICOLON)*
	;

element :
	  ic=import_clause
	| ec=extends_clause
	| defineunit_clause
	| (REDECLARE)? (f=FINAL)? (INNER)? (T_OUTER)?
	( (class_definition[f != NULL] | cc=component_clause) 
	| (REPLACEABLE ( class_definition[f != NULL] | cc2=component_clause ) (constraining_clause comment)? )
	)
	;

import_clause :
	IMPORT (explicit_import_name | implicit_import_name) comment
	;
defineunit_clause :
	DEFINEUNIT IDENT (LPAR named_arguments RPAR)?		
	;

explicit_import_name:
	IDENT EQUALS name_path
	;

implicit_import_name
:
np = name_path_star
;

/*
 * 2.2.3 Extends
 */

// Note that this is a minor modification of the standard by
// allowing the comment.
extends_clause :
	EXTENDS name_path (class_modification)? (annotation)?
		;

constraining_clause :
	  EXTENDS name_path  (class_modification)? 
	| CONSTRAINEDBY name_path ( class_modification )?
	;

/*
 * 2.2.4 Component clause
 */

component_clause :
	tp = type_prefix np=type_specifier clst=component_list
	;

type_prefix :
	(FLOW|STREAM)? (DISCRETE|PARAMETER|CONSTANT)? (T_INPUT|T_OUTPUT)?
	;

type_specifier :
	np=name_path
	(type_specifier_list)?
	(as=array_subscripts)?
	;

type_specifier_list:
	(LESS np1=type_specifier (COMMA np2=type_specifier)* GREATER)
	/* -> (TYPE_LIST type_specifier_list) */
	;

component_list :
	component_declaration (COMMA component_declaration)*
	;

component_declaration :
	declaration (conditional_attribute)? comment
	;

conditional_attribute :
        IF expression
        ;

declaration :
	( IDENT | OPERATOR ) (array_subscripts)? (modification)?
	;

/*
 * 2.2.5 Modification
 */

modification :
	( class_modification ( EQUALS expression )?
	| EQUALS expression
	| ASSIGN expression
	)
	;

class_modification :
	LPAR ( argument_list )? RPAR /* -> (CLASS_MODIFICATION class_modification) */
	;

argument_list :
	argument ( COMMA argument )* /* -> (ARGUMENT_LIST argument_list) */
	;

argument  :
	(
	  em=element_modification_or_replaceable /* -> (ELEMENT_MODIFICATION em) */
	| er=element_redeclaration  /* -> (ELEMENT_REDECLARATION er) */
	)
	;

element_modification_or_replaceable:
        (EACH)? (f=FINAL)? (element_modification | element_replaceable[f != NULL])
    ;

element_modification :
	component_reference ( modification )? string_comment
	;

element_redeclaration :
	REDECLARE (EACH)? (f=FINAL)?
	( (class_definition[f != NULL] | component_clause1) | element_replaceable[f != NULL] )
	;

element_replaceable [bool final] :
        REPLACEABLE ( class_definition[final] | component_clause1 ) (constraining_clause comment)?
	;
	
component_clause1 :
	type_prefix type_specifier component_declaration1
	;

component_declaration1 :
        declaration comment
	;


/*
 * 2.2.6 Equations
 */

initial_equation_clause :
	{ LA(2)==EQUATION }?
	INITIAL ec=equation_clause /* -> (INITIAL_EQUATION ec) */
	;

equation_clause :
	EQUATION equation_annotation_list
  	;

equation_annotation_list :
	{ LA(1) == T_END || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
	|
	( equation SEMICOLON | annotation SEMICOLON) equation_annotation_list
	;

algorithm_clause :
	T_ALGORITHM algorithm_annotation_list
	;

initial_algorithm_clause :
	{ LA(2)==T_ALGORITHM }?
	INITIAL ac = algorithm_clause /* -> (INITIAL_ALGORITHM ac) */
	;

algorithm_annotation_list :
	{ LA(1) == T_END || LA(1) == EQUATION || LA(1) == T_ALGORITHM || LA(1)==INITIAL || LA(1) == PROTECTED || LA(1) == PUBLIC }?
	|
	( algorithm SEMICOLON | annotation SEMICOLON) algorithm_annotation_list
	;

equation :
	( equality_equation	 
	| conditional_equation_e
	| for_clause_e
	| connect_clause
	| when_clause_e   
	| FAILURE LPAR equation RPAR
	| EQUALITY LPAR equation RPAR
	)
	comment
        
        /* -> (EQUATION_STATEMENT equation); */

	;

algorithm :
	( assign_clause_a
	| conditional_equation_a
	| for_clause_a
	| while_clause
	| when_clause_a
	| BREAK
	| RETURN
	| FAILURE LPAR algorithm RPAR
	| EQUALITY LPAR algorithm RPAR
	)
	comment
	
	/* -> (ALGORITHM_STATEMENT algorithm) */
	;

assign_clause_a :          		  
	simple_expression 
	( ASSIGN expression  | i1 = EQUALS expression
	/* 
          {      
             throw ANTLR_USE_NAMESPACE(antlr)RecognitionException(
        		"Algorithms can not contain equations ('='), use assignments (':=') instead", 
        		modelicafilename, $i1->getLine(), $i1->getColumn());
          }
          */
        )?  
	;

equality_equation :		  
	simple_expression ( EQUALS expression )? 		
	;

conditional_equation_e :
	IF expression THEN equation_list ( equation_elseif )* ( ELSE equation_list )? T_END IF
	;

conditional_equation_a :
	IF expression THEN algorithm_list ( algorithm_elseif )* ( ELSE algorithm_list )? T_END IF
	;

for_clause_e :
	FOR for_indices LOOP equation_list T_END FOR
	;

for_clause_a :
	FOR for_indices LOOP algorithm_list T_END FOR
	;

while_clause :
	WHILE expression LOOP algorithm_list T_END WHILE
	;

when_clause_e :
	WHEN expression THEN equation_list (else_when_e)* T_END WHEN
	;

else_when_e :
	ELSEWHEN expression THEN equation_list
	;

when_clause_a :
	WHEN expression THEN algorithm_list (else_when_a)* T_END WHEN
	;

else_when_a :
	ELSEWHEN expression THEN algorithm_list
	;

equation_elseif :
	ELSEIF expression THEN equation_list
	;

algorithm_elseif :
	ELSEIF expression THEN algorithm_list
	;

equation_list_then :
        { LA(1) == THEN }?
	| (equation SEMICOLON equation_list_then)
	;


equation_list :
	{LA(1) != T_END || (LA(1) == T_END && LA(2) != IDENT)}?
	|
	( equation SEMICOLON equation_list )
	;

algorithm_list :
	{LA(1) != T_END || (LA(1) == T_END && LA(2) != IDENT)}?
	|
	( algorithm SEMICOLON algorithm_list )
	;

connect_clause :
	CONNECT LPAR connector_ref COMMA connector_ref RPAR
	;

connector_ref :
	IDENT ( array_subscripts )? ( DOT connector_ref_2 )?
	;

connector_ref_2 :
	IDENT ( array_subscripts )?
	;

/*
 * 2.2.7 Expressions
 */
expression returns [void* ast] :
	( if_expression
	| simple_expression
	| code_expression
	| (MATCHCONTINUE expression_or_empty
	   local_clause
	   cases
	   T_END MATCHCONTINUE)
	| (MATCH expression_or_empty
	   local_clause
	   cases
	   T_END MATCH)
	)
	;

expression_or_empty :
	e = expression /* { $expression_or_empty = $e; } */
	| LPAR RPAR /* -> (EMPTY expression_or_empty) */
	;

local_clause:
	(LOCAL element_list)?
	;

cases:
	(onecase)+ (ELSE string_comment local_clause (EQUATION equation_list_then)?
	THEN expression_or_empty SEMICOLON)?
	;

onecase:
	(CASE pattern string_comment local_clause (EQUATION equation_list_then)?
	THEN expression_or_empty SEMICOLON)
	;

pattern:
	expression_or_empty
	;

if_expression :
	IF expression THEN expression (elseif_expression)* ELSE expression
	;

elseif_expression :
	ELSEIF expression THEN expression
	;

for_indices :
        for_index (COMMA for_index)*
	;

for_index:
        (IDENT (T_IN expression)?)
	;

simple_expression :
	  simple_expr (COLONCOLON simple_expr)*
	| IDENT AS simple_expression
	;

simple_expr :
	l1=logical_expression ( COLON l2=logical_expression ( COLON l3=logical_expression )? )?
	;

/* Code quotation mechanism */
code_expression  :
	CODE LPAR ((expression RPAR)=> e=expression | m=modification | el=element (SEMICOLON)?
	| eq=code_equation_clause | ieq=code_initial_equation_clause
	| alg=code_algorithm_clause | ialg=code_initial_algorithm_clause
	)  RPAR
	;

code_equation_clause :
	( EQUATION ( equation SEMICOLON | annotation SEMICOLON )*  )
	;

code_initial_equation_clause :
	{ LA(2)==EQUATION }?
	INITIAL ec=code_equation_clause 
	;

code_algorithm_clause :
	T_ALGORITHM (algorithm SEMICOLON | annotation SEMICOLON)*
	;

code_initial_algorithm_clause :
	{ LA(2) == T_ALGORITHM }?
	INITIAL T_ALGORITHM
	( algorithm SEMICOLON | annotation SEMICOLON )* 
	;
/* End Code quotation mechanism */

logical_expression :
	logical_term   ( T_OR logical_term )*
	;

logical_term :
	logical_factor ( T_AND logical_factor )*
	;

logical_factor :
	( T_NOT )? relation
	;

relation :
	arithmetic_expression 
	( ( LESS | LESSEQ | GREATER | GREATEREQ | EQEQ | LESSGT ) arithmetic_expression )?
	;

arithmetic_expression :
	unary_arithmetic_expression ( ( PLUS | MINUS | PLUS_EW | MINUS_EW ) term )*
	;

unary_arithmetic_expression  :
	( PLUS t1=term     
	| MINUS t2=term	   
	| PLUS_EW t3=term  
	| MINUS_EW t4=term 
	| t5=term          
	)
	;

term returns [void* ast] @declarations {
  void* op;
} :
	e1=factor {ast = e1;}
    (
      ( STAR {op=Absyn__MUL;} | SLASH {op=Absyn__DIV;} | STAR_EW {op=Absyn__MUL_5fEW;} | SLASH_EW {op=Absyn__DIV_5fEW;} )
      e2=factor {ast = Absyn__BINARY(e1,op,e2);}
    )*
	;

factor returns [void* ast] :
	e1=primary ( ( pw=POWER | pw_ew=POWER_EW ) e2=primary )?
    {
      ast = e2 ? Absyn__BINARY(e1, pw ? Absyn__POW : Absyn__POW_5fEW, e2) : e1;
    }
	;

primary returns [void* ast]:
	( v=UNSIGNED_INTEGER {ast = mk_icon($v.int);}
	| v=UNSIGNED_REAL {ast = mk_rcon(atof($v.text->chars));}
	| v=STRING {ast = mk_scon($v.text->chars);}
	| T_FALSE {ast = RML_FALSE;}
	| T_TRUE {ast = RML_TRUE;}
	| ptr=component_reference__function_call {ast = ptr;}
  | DER el=function_call {ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("der"), mk_nil()),el);}
	| LPAR expression_list RPAR
	| LBRACK e1=expression_list (SEMICOLON expression_list)* RBRACK
	| LBRACE fel=for_or_expression_list RBRACE {ast = fel;}
	| T_END
	)
	;

component_reference__function_call returns [void* ast] :
	cr=component_reference ( fc=function_call )? {
      if (fc != NULL) {
        ast = Absyn__CALL(cr,fc);
      }
    }
	| i=INITIAL LPAR RPAR {
      ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("initial"), mk_nil()),Absyn__FUNCTIONARGS(mk_nil(),mk_nil()));
    }
	;

name_path :
	{ LA(2)!=DOT }? IDENT 
	| IDENT DOT name_path
	;

name_path_star 
	:
	  { LA(2) != DOT }? IDENT ( STAR_EW )?
	| i=IDENT DOT np=name_path_star 
	;

component_reference returns [void* ast] :
    ( IDENT | OPERATOR) ( array_subscripts )? ( DOT component_reference )?
	| WILD {ast = Absyn__WILD;}
	;

function_call returns [void* ast] :
	LPAR (function_arguments) RPAR
	;

function_arguments returns [void* ast] :
	(elist=for_or_expression_list) (namel=named_arguments) ?
    {
      ast = Absyn__FUNCTIONARGS(elist,namel);
    }
	;

for_or_expression_list returns [void* ast]:
	({LA(1)==IDENT || LA(1)==OPERATOR && LA(2) == EQUALS || LA(1) == RPAR || LA(1) == RBRACE}?
	 /* empty */
	|(e=expression ( COMMA explist=for_or_expression_list2 | FOR forind=for_indices)? )
	)
		;

for_or_expression_list2 :
	  {LA(2) == EQUALS}?
	| expression (COMMA for_or_expression_list2)?
	;

named_arguments returns [void* ast]:
	named_arguments2 
	;

named_arguments2 :
	named_argument (COMMA named_argument)*
	;

named_argument :
	( IDENT | OPERATOR) EQUALS expression
	;

expression_list returns [void* ast] :
	expression_list2 
	;

expression_list2 returns [void* ast] :
	e1=expression (COMMA el=expression_list2)? {
    ast = (el==NULL ? mk_cons(e1,mk_nil()) : mk_cons(e1,el));
  } 
	;

array_subscripts :
	LBRACK subscript ( COMMA subscript )* RBRACK
	;

subscript :
	expression | COLON
	;

comment :
	(string_comment (annotation)?) 
	;

string_comment :
	( STRING (PLUS STRING)*)?
	;

annotation :
	T_ANNOTATION class_modification
	;

