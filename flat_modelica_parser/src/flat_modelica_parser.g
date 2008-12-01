/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linkopings University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkopings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

header "post_include_hpp" {
#define null 0
#include "MyAST.h"

#include "../../Compiler/runtime/errorext.h"

#include "../../Compiler/runtime/error_reporting.h"

typedef ANTLR_USE_NAMESPACE(antlr)ASTRefCount<MyAST> RefMyAST;

}

options {
	language = "Cpp";
}

class flat_modelica_parser extends Parser;

options {
    codeGenMakeSwitchThreshold = 3;
    codeGenBitsetTestThreshold = 4;
	importVocab = modelica;
    defaultErrorHandler = false;
	k = 2;
	buildAST = true;
    ASTLabelType = "RefMyAST";

}

tokens {
    ALGORITHM_STATEMENT;
	ARGUMENT_LIST;
	CLASS_DEFINITION	;
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
	UNQUALIFIED;
	FLAT_IDENT;
	TYPE_LIST;
	EMPTY;
}


/*
 * 2.2.1 Stored definition
 */


stored_definition :

			(within_clause SEMICOLON!)?
			((FINAL)? cd:class_definition s:SEMICOLON!
			{
			  /* adrpo, fix the end of this AST node */
			  if(#cd != NULL)
			  {
            		  	/*
            		  	std::cout << (#cd)->toString() << std::endl;
            		  	std::cout << s->getLine() << ":" << s->getColumn() << std::endl;
            		  	*/
				RefMyAST(#cd)->setEndLine(s->getLine());
				RefMyAST(#cd)->setEndColumn(s->getColumn());
			   }
			}
			)*
			/*EOF!   By not checking for EOF we allow some crap (debug text,etc) to be at the end
				of the file, which can be produced by some Modelica tools.*/
			{
				#stored_definition = #([STORED_DEFINITION,"STORED_DEFINITION"],
				#stored_definition);
			}
			;


within_clause :
  				WITHIN^ (name_path)?
			;

/*
 * 2.2.2 Class definition
 */

class_definition :
		(ENCAPSULATED)?
		(PARTIAL)?
		class_type
        class_specifier
		{
			#class_definition = #([CLASS_DEFINITION, "CLASS_DEFINITION"],class_definition);
		}
		;

class_type :
		( CLASS | MODEL | RECORD | BLOCK | ( EXPANDABLE )? CONNECTOR | TYPE | PACKAGE | FUNCTION | UNIONTYPE )
		;

class_specifier:
        n1:name_path /*was IDENT in modelica_parser*/ class_specifier2[#n1]
    |   EXTENDS! i1:IDENT (class_modification)? string_comment composition END! i2:IDENT!
        {
        	// check if the identifiers at the start and end are the same!
        	if (i1->getText() != i2->getText())
        	{
        		throw
        		ANTLR_USE_NAMESPACE(antlr)
        		RecognitionException("The identifier at start and end are different",
        		                     modelicafilename, i2->getLine(), i2->getColumn());
        	}
            #class_specifier = #([CLASS_EXTENDS,"CLASS_EXTENDS"],#class_specifier);
        }
        ;

class_specifier2 [RefMyAST name_path1]:
		( string_comment composition e:END! /* was IDENT! */ n2:name_path!
		  {
		    // check if the identifiers at the start and end are the same!
		    if (RefMyAST(name_path1)->getText() != RefMyAST(#n2)->getText())
		  	{
        		throw
        		ANTLR_USE_NAMESPACE(antlr)
        		RecognitionException("The identifier at start and end are different",
        		                     modelicafilename, e->getLine(), e->getColumn());
		  	}
		  }
		| EQUALS^ base_prefix type_specifier ( class_modification )? comment
		| EQUALS^ enumeration
        | EQUALS^ pder
		| EQUALS^ overloading
		| SUBTYPEOF^ type_specifier
		)
		;

pder:   DER^ LPAR! name_path COMMA! ident_list RPAR! comment ;

ident_list :
      IDENT
    | IDENT COMMA! ident_list
      {
         #ident_list=#([IDENT_LIST,"IDENT_LIST"],#ident_list);
      }
    ;


overloading:
      OVERLOAD^ LPAR! name_list RPAR! comment
	;

base_prefix:
		type_prefix
		;

name_list:
		name_path (COMMA! name_path)*
		;

enumeration :
		ENUMERATION^ LPAR! (enum_list | COLON ) RPAR! comment
		;
		
enum_list :
		enumeration_literal ( COMMA! enumeration_literal)*
		;

enumeration_literal :
		IDENT comment
		{
			#enumeration_literal=#([ENUMERATION_LITERAL,
					"ENUMERATION_LITERAL"],#enumeration_literal);
		}
		;

composition :
		element_list
		(	public_element_list
		|	protected_element_list
		| 	initial_equation_clause
		| 	initial_algorithm_clause
		|	equation_clause
		|	algorithm_clause
		)*
		( external_clause )?
		;

external_clause :
        EXTERNAL^
        ( language_specification )?
        ( external_function_call )?
        ( annotation )? SEMICOLON!
        ( external_annotation )?
        ;

external_annotation:
		annotation SEMICOLON!
        {
            #external_annotation=#([EXTERNAL_ANNOTATION,
					"EXTERNAL_ANNOTATION"],#external_annotation);
        }
    ;

public_element_list :
		PUBLIC^ element_list
		;

protected_element_list :
		PROTECTED^ element_list
		;

language_specification :
		STRING
		;

external_function_call :
		( component_reference EQUALS^ )?
		IDENT LPAR! ( expression_list )? RPAR!
		{
			#external_function_call=#([EXTERNAL_FUNCTION_CALL,
					"EXTERNAL_FUNCTION_CALL"],#external_function_call);
		}
		;

element_list :
		((e:element | a:annotation ) s:SEMICOLON!
		{
		   /* adrpo, fix the end of this AST node */
		   if (#e)
		   {
    		  	/*
    		  	std::cout << (#e)->toString() << std::endl;
    		  	std::cout << s->getLine() << ":" << s->getColumn() << std::endl;
    		  	*/
			RefMyAST(#e)->setEndLine(s->getLine());
			RefMyAST(#e)->setEndColumn(s->getColumn());
		   	if (#e->getFirstChild())
		   	{
		   	   /*
    		  	   std::cout << (#e->getFirstChild())->toString() << std::endl;
    		  	   std::cout << s->getLine() << ":" << s->getColumn() << std::endl;
    		  	   */
			   RefMyAST(#e->getFirstChild())->setEndLine(s->getLine());
			   RefMyAST(#e->getFirstChild())->setEndColumn(s->getColumn());
		        }
		   }

		}
		)*
		;
        exception
        catch [ANTLR_USE_NAMESPACE(antlr)RecognitionException &e]
        {
          BEFORE_SYNC;

          // Sync to {PUBLIC, PROTECTED, EQUATION, ALGORITHM, EXTERNAL, END}
          while(LA(1) != PUBLIC && LA(1) != PROTECTED && LA(1) != EQUATION && LA(1) != ALGORITHM && LA(1) != EXTERNAL && LA(1) != END)
          {
            if(LA(1) == EOF_)
            {
              throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", modelicafilename, LT(1)->getLine(), LT(1)->getColumn());
            }
            consume();
          }

          AFTER_SYNC;
        }

element :
			ic:import_clause
		|	ec:extends_clause
		|	(REDECLARE)?
        (FINAL)?
        (INNER)?
        (OUTER)?
		(	(class_definition | cc:component_clause)
			|(REPLACEABLE ( class_definition | cc2:component_clause )
				(constraining_clause comment)?
			 )
		)
		{
			if(#cc != null || #cc2 != null)
			{
				#element = #([DECLARATION,"DECLARATION"], #element);
			}
			else
			{
				#element = #([DEFINITION,"DEFINITION"], #element);
			}
		}
		;
        exception
        catch [ANTLR_USE_NAMESPACE(antlr)RecognitionException &e]
        {
          BEFORE_SYNC;

          // Sync to SEMICOLON
          while(LA(1) != SEMICOLON)
          {
            if(LA(1) == EOF_)
            {
              throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", modelicafilename, LT(1)->getLine(), LT(1)->getColumn());
            }
            consume();
          }

          AFTER_SYNC;
        }

import_clause :
		IMPORT^ (explicit_import_name | implicit_import_name) comment
		;

explicit_import_name:
		IDENT EQUALS^ name_path
		;

implicit_import_name!
		{
			bool has_star = false;
		}
		:
		has_star = np:name_path_star
		{
			if (has_star)
			{
				#implicit_import_name = #([UNQUALIFIED,"UNQUALIFIED"],#np);
			}
			else
			{
				#implicit_import_name = #([QUALIFIED,"QUALIFIED"],#np);
			}
		};
/*
 * 2.2.3 Extends
 */

// Note that this is a minor modification of the standard by
// allowing the comment.
extends_clause :
		EXTENDS^ name_path ( class_modification )?
		;

constraining_clause :
		extends_clause | CONSTRAINEDBY^ name_path ( class_modification )?
		;

/*
 * 2.2.4 Component clause
 */

component_clause :
		tp: type_prefix np:type_specifier clst:component_list
		;

type_prefix :
		(FLOW
		|STREAM)?
		(DISCRETE
		|PARAMETER
		|CONSTANT
		)?
		(INPUT
		|OUTPUT
		)?
		;

type_specifier :
		np:name_path
		(type_specifier_list)?
		(as:array_subscripts)?
		;

type_specifier_list:
		(LESS! np1:type_specifier (COMMA np2:type_specifier)* GREATER!)
		{
			#type_specifier_list = #([TYPE_LIST, "TYPE_LIST"], #type_specifier_list);
		}
	;

component_list :
		component_declaration (COMMA! component_declaration)*
		;

component_declaration :
		declaration (conditional_attribute)? comment
		;

conditional_attribute:
        IF^ expression
        ;

declaration !
		:
		comp:component_reference /* was: IDENT^  (array_subscripts)?*/ (mod:modification)?
		{
			if (#mod) {
				#declaration = #([FLAT_IDENT,"FLAT_IDENT"],#comp,#mod);
			} else {
			   #declaration = #comp;
			}
		}
		;

/*
 * 2.2.5 Modification
 */

modification :
		(	class_modification ( EQUALS expression )?
		|	EQUALS^ expression
		|	ASSIGN^ expression
		)
		;

class_modification :
		LPAR! ( argument_list )? RPAR!
		{
			#class_modification=#([CLASS_MODIFICATION,"CLASS_MODIFICATION"],
				#class_modification);
		}
		;

argument_list :
		argument ( COMMA! argument )*
		{
			#argument_list=#([ARGUMENT_LIST,"ARGUMENT_LIST"],#argument_list);
		}
		;

argument ! :
		(em:element_modification_or_replaceable
		{
			#argument = #([ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION"], #em);
		}
		| er:element_redeclaration
		{
			#argument = #([ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION"], #er); 		}
		)
		;

element_modification_or_replaceable:
        (EACH)? (FINAL)? (element_modification | element_replaceable)
    ;

element_modification :
		component_reference ( modification )? string_comment
	;

element_redeclaration :
		REDECLARE^ ( EACH )? (FINAL )?
		(	(class_definition | component_clause1) | element_replaceable )
		;

element_replaceable:
        REPLACEABLE^ ( class_definition | component_clause1 )
				(constraining_clause comment)?
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
		{ LA(2)==EQUATION}?
		INITIAL! ec:equation_clause
        {
            #initial_equation_clause = #([INITIAL_EQUATION,"INTIAL_EQUATION"], ec);
        }

		;

equation_clause :
		EQUATION^
		    equation_annotation_list
  		;

equation_annotation_list :
		{ LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL
		 || LA(1) == PROTECTED || LA(1) == PUBLIC }?
		|
		( equation SEMICOLON! | annotation SEMICOLON!) equation_annotation_list
		;
        exception
        catch [ANTLR_USE_NAMESPACE(antlr)RecognitionException &e]
        {
          BEFORE_SYNC;

          // Sync to {END, EQUATION, ALGORITHM, INITIAL, PROTECTED, PUBLIC}
          while(LA(1) != END && LA(1) != EQUATION && LA(1) != ALGORITHM && LA(1) != INITIAL
                && LA(1) != PROTECTED && LA(1) != PUBLIC)
          {
            if(LA(1) == EOF_)
            {
              throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", modelicafilename, LT(1)->getLine(), LT(1)->getColumn());
            }
            consume();
          }

          AFTER_SYNC;
        }

algorithm_clause :
		ALGORITHM^
		    algorithm_annotation_list
		;

initial_algorithm_clause :
		{ LA(2)==ALGORITHM }?
		INITIAL! ac: algorithm_clause
        {
            #initial_algorithm_clause = #([INITIAL_ALGORITHM,"INTIAL_ALGORITHM"], ac);
        }
		;

algorithm_annotation_list :
		{ LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL
		 || LA(1) == PROTECTED || LA(1) == PUBLIC }?
		|
		( algorithm SEMICOLON! | annotation SEMICOLON!) algorithm_annotation_list
		;
        exception
        catch [ANTLR_USE_NAMESPACE(antlr)RecognitionException &e]
        {
          BEFORE_SYNC;

          // Sync to {END, EQUATION, ALGORITHM, INITIAL, PROTECTED, PUBLIC}
          while(LA(1) != END && LA(1) != EQUATION && LA(1) != ALGORITHM && LA(1) != INITIAL
                && LA(1) != PROTECTED && LA(1) != PUBLIC)
          {
            if(LA(1) == EOF_)
            {
              throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", modelicafilename, LT(1)->getLine(), LT(1)->getColumn());
            }
            consume();
          }

          AFTER_SYNC;
        }

equation :
		(   (simple_expression EQUALS) => equality_equation
		|	conditional_equation_e
		|	for_clause_e
		|	connect_clause
		|	when_clause_e
		|   component_reference function_call // function call
		|   FAILURE^ LPAR! equation RPAR!
		|   EQUALITY^ LPAR! equation RPAR!
		)
        {
            #equation = #([EQUATION_STATEMENT,"EQUATION_STATEMENT"], #equation);
        }
		comment
		;
        exception
        catch [ANTLR_USE_NAMESPACE(antlr)RecognitionException &e]
        {
          BEFORE_SYNC;

          // Sync to SEMICOLON
          while(LA(1) != SEMICOLON)
          {
            if(LA(1) == EOF_)
            {
              throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", modelicafilename, LT(1)->getLine(), LT(1)->getColumn());
            }
            consume();
          }

          AFTER_SYNC;
        }

algorithm :
		(	(simple_expression ASSIGN) => assign_clause_a
		|	component_reference function_call
		|	conditional_equation_a
		|	for_clause_a
		|	while_clause
		|	when_clause_a
		|   BREAK
		|   RETURN
		|   FAILURE^ LPAR! algorithm RPAR!
		|   EQUALITY^ LPAR! algorithm RPAR!
		)
		comment
        {
            #algorithm = #([ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT"], #algorithm);
        }
		;
        exception
        catch [ANTLR_USE_NAMESPACE(antlr)RecognitionException &e]
        {
          BEFORE_SYNC;

          // Sync to SEMICOLON
          while(LA(1) != SEMICOLON)
          {
            if(LA(1) == EOF_)
            {
              throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", modelicafilename, LT(1)->getLine(), LT(1)->getColumn());
            }
            consume();
          }

          AFTER_SYNC;
        }

assign_clause_a :
		   simple_expression ASSIGN^ expression
		;

equality_equation :
		simple_expression EQUALS^ expression
		;

conditional_equation_e :
		IF^ expression THEN! equation_list
		( equation_elseif )*
		( ELSE equation_list )?
		END! IF!
		;

conditional_equation_a :
		IF^ expression THEN! algorithm_list
		( algorithm_elseif )*
		( ELSE algorithm_list )?
		END! IF!
		;

for_clause_e :
		FOR^ for_indices LOOP!
		equation_list
		END! FOR!
		;

for_clause_a :
		FOR^ for_indices LOOP!
		algorithm_list
		END! FOR!
		;

while_clause :
		WHILE^ expression LOOP!
		algorithm_list
		END! WHILE!
		;

when_clause_e :
		WHEN^ expression THEN!
		equation_list
		(else_when_e) *
		END! WHEN!
		;

else_when_e :
		ELSEWHEN^ expression THEN!
		equation_list
		;

when_clause_a :
		WHEN^ expression THEN!
		algorithm_list
		(else_when_a)*
		END! WHEN!
		;

else_when_a :
		ELSEWHEN^ expression THEN!
		algorithm_list
		;

equation_elseif :
		ELSEIF^ expression THEN!
		equation_list
		;

algorithm_elseif :
		ELSEIF^ expression THEN!
		algorithm_list
		;

equation_list_then :
          { LA(1) == THEN }?
		| (equation SEMICOLON! equation_list_then)
		;


equation_list :
		{LA(1) != END || (LA(1) == END && LA(2) != IDENT)}?
		|
		(equation SEMICOLON! equation_list)
		;

algorithm_list :
		{LA(1) != END || (LA(1) == END && LA(2) != IDENT)}?
		|
		( algorithm SEMICOLON! algorithm_list )
		;

connect_clause :
		CONNECT^ LPAR! connector_ref COMMA! connector_ref RPAR!
		;

connector_ref :
		IDENT^ ( array_subscripts )? ( DOT^ connector_ref_2 )?
		;

connector_ref_2 :
		IDENT^ ( array_subscripts )?
		;

/*
 * 2.2.7 Expressions
 */

expression :
		( if_expression
		| simple_expression
		| code_expression
		| (MATCHCONTINUE^ expression_or_empty
		   local_clause
		   cases
		   END! MATCHCONTINUE!
 	       )
		| (MATCH^ expression_or_empty
		   local_clause
		   cases
		   END! MATCH!
 	       )
		)
		;

expression_or_empty !:
	e:expression
	{
		#expression_or_empty = #e;
	}
	| LPAR! RPAR!
	{
		#expression_or_empty = #([EMPTY,"EMPTY"], #expression_or_empty);
	}
	;

local_clause:
	(LOCAL^ element_list)?
	;

cases:
	(onecase)+ (ELSE^ string_comment local_clause (EQUATION! equation_list_then)?
	THEN! expression_or_empty SEMICOLON!)?
	;

onecase:
	(CASE^ pattern string_comment local_clause (EQUATION! equation_list_then)?
	THEN! expression_or_empty SEMICOLON!)
	;

pattern:
	expression_or_empty
	;

if_expression :
		IF^ expression THEN! expression (elseif_expression)* ELSE! expression
    ;

elseif_expression :
		ELSEIF^ expression THEN! expression
		;

for_indices :
        for_index (COMMA! for_index)*
    ;

for_index:
        (IDENT (IN expression)?)
;

simple_expression :
		  simple_expr (COLONCOLON^ simple_expr)*
		| IDENT AS^ simple_expression
		;

simple_expr !:
		l1:logical_expression
		( COLON l2:logical_expression
		    ( COLON l3:logical_expression
		    )?
		)?
		{
			if (#l3 != null)
			{
				#simple_expr = #([RANGE3,"RANGE3"], l1, l2, l3);
			}
			else if (#l2 != null)
			{
				#simple_expr = #([RANGE2,"RANGE2"], l1, l2);
			}
			else
			{
				#simple_expr = #l1;
			}
		}
		;

/* Code quotation mechanism */
code_expression ! :
		CODE LPAR ((expression RPAR)=> e:expression | m:modification | el:element (SEMICOLON!)?
		| eq:code_equation_clause | ieq:code_initial_equation_clause
		| alg:code_algorithm_clause | ialg:code_initial_algorithm_clause
		)  RPAR
 		{
 			if (#e) {
 				#code_expression = #([CODE_EXPRESSION, "CODE_EXPRESSION"],#e);
 			} else if (#m) {
 				#code_expression = #([CODE_MODIFICATION, "CODE_MODIFICATION"],#m);
 			} else if (#el) {
 				#code_expression = #([CODE_ELEMENT, "CODE_ELEMENT"],#el);
 			} else if (#eq) {
				#code_expression = #([CODE_EQUATION, "CODE_EQUATION"],#eq);
 			} else if (#ieq) {
 				#code_expression = #([CODE_INITIALEQUATION, "CODE_EQUATION"],#ieq);
 			} else if (#alg) {
				#code_expression = #([CODE_ALGORITHM, "CODE_ALGORITHM"],#alg);
  			} else if (#ialg) {
 				#code_expression = #([CODE_INITIALALGORITHM, "CODE_ALGORITHM"],#ialg);
			}
		}
	;

code_equation_clause :
		( EQUATION^ (equation SEMICOLON! | annotation SEMICOLON! )*  )
		;

code_initial_equation_clause :
 		{ LA(2)==EQUATION}?
 		INITIAL! ec:code_equation_clause
         {
             #code_initial_equation_clause = #([INITIAL_EQUATION,"INTIAL_EQUATION"], ec);
         }
 		;

code_algorithm_clause :
		ALGORITHM^ (algorithm SEMICOLON! | annotation SEMICOLON!)*
		;
code_initial_algorithm_clause :
		{ LA(2) == ALGORITHM }?
		INITIAL! ALGORITHM^
		(algorithm SEMICOLON!
		|annotation SEMICOLON!
		)*
		{
			#code_initial_algorithm_clause = #([INITIAL_ALGORITHM,"INTIAL_ALGORITHM"], #code_initial_algorithm_clause);
		}
		;

/* End Code quotation mechanism */

logical_expression :
		logical_term ( OR^ logical_term )*
		;

logical_term :
		logical_factor ( AND^ logical_factor )*
		;

logical_factor :
		( NOT^ )?
		relation
		;

relation :
		arithmetic_expression ( ( LESS^ | LESSEQ^ | GREATER^ | GREATEREQ^ | EQEQ^ | LESSGT^ | RLESS^ | RGREATER^ ) arithmetic_expression )?
		;

rel_op :
		( LESS^ | LESSEQ^ | GREATER^ | GREATEREQ^ | EQEQ^ | LESSGT^ )
		;

arithmetic_expression :
		unary_arithmetic_expression ( ( PLUS^ | MINUS^ ) term )*
		;

unary_arithmetic_expression ! :
		( PLUS t1:term
		{
			#unary_arithmetic_expression = #([UNARY_PLUS,"PLUS"], #t1);
		}
		| MINUS t2:term
		{
			#unary_arithmetic_expression = #([UNARY_MINUS,"MINUS"], #t2);
		}
		| t3:term
		{
			#unary_arithmetic_expression = #t3;
		}
		)
		;

term :
		factor ( ( STAR^ | SLASH^ ) factor )*
		;

factor :
		primary ( POWER^ primary )?
		;

primary :
		( UNSIGNED_INTEGER
		| UNSIGNED_REAL
		| STRING
		| FALSE
		| TRUE
		| component_reference__function_call
        | DER^ function_call
		| LPAR^ expression_list RPAR!
		| LBRACK^ expression_list (SEMICOLON! expression_list)* RBRACK!
		| LBRACE^ for_or_expression_list RBRACE!
		| END
		)
    ;

component_reference__function_call ! :
		cr:component_reference ( fc:function_call )?
		{
			if (#fc != null)
			{
				#component_reference__function_call = #([FUNCTION_CALL,"FUNCTION_CALL"], #cr, #fc);
			}
			else
			{
				#component_reference__function_call = #cr;
			}
		}
	| i:INITIAL LPAR! RPAR! {
			#component_reference__function_call = #([INITIAL_FUNCTION_CALL,"INITIAL_FUNCTION_CALL"],i);
		}
	;

name_path :
		{ LA(2)!=DOT }? IDENT |
		IDENT DOT^ name_path
		;

name_path_star returns [bool val=false]
		:
		{ LA(2)!=DOT }? IDENT { val=false;}|
		{ LA(2)!=DOT }? STAR! { val=true;}|
		i:IDENT DOT^ val = np:name_path_star
		{
			if(!(#np))
			{
				#name_path_star = #i;
			}
		}
		;

component_reference :
		IDENT^ ( array_subscripts )? ( DOT^ component_reference )?
		| WILD
		;

function_call :
		LPAR! (function_arguments) RPAR!
		{
			#function_call = #([FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS"],#function_call);
		}
		;

function_arguments :
			(for_or_expression_list)
			(named_arguments) ?
		;

for_or_expression_list
    :
		(
			{LA(1)==IDENT && LA(2) == EQUALS || LA(1) == RPAR || LA(1) == RBRACE}?
		|
			(
				e:expression
				( COMMA! explist:for_or_expression_list2
				| FOR^ forind:for_indices
				)?
			)
            {
                if (#forind != null) {
                    #for_or_expression_list =
                        #([FOR_ITERATOR,"FOR_ITERATOR"], #for_or_expression_list);
                }
                else {
                    #for_or_expression_list =
                        #([EXPRESSION_LIST,"EXPRESSION_LIST"], #for_or_expression_list);
                }
            }
		)
		;

for_or_expression_list2 :
		{LA(2) == EQUALS}?
		|
		expression (COMMA! for_or_expression_list2)?
		;

named_arguments :
		named_arguments2
		{
			#named_arguments=#([NAMED_ARGUMENTS,"NAMED_ARGUMENTS"],#named_arguments);
		}
		;

named_arguments2 :
		named_argument ( COMMA! (COMMA IDENT EQUALS) => named_arguments2)?
		;

named_argument :
		IDENT EQUALS^ expression
		;

expression_list :
		expression_list2
		{
			#expression_list=#([EXPRESSION_LIST,"EXPRESSION_LIST"],#expression_list);
		}
		;
expression_list2 :
		expression (COMMA! expression_list2)?
	    ;

array_subscripts :
		LBRACK^ subscript ( COMMA! subscript )* RBRACK!
	;

subscript :
		expression | COLON
		;

comment :
		(
			//string_comment	 ANNOTATION )=> annotation
			string_comment (annotation)?
		)
		{
			#comment=#([COMMENT,"COMMENT"],#comment);
		}
		;

string_comment :
		( STRING ((PLUS STRING) => ( PLUS^ STRING )+ | ) )?
		{
            if (#string_comment)
            {
                #string_comment = #([STRING_COMMENT,"STRING_COMMENT"],	#string_comment);
            }
		}
;

annotation :
		ANNOTATION^ class_modification
		;
