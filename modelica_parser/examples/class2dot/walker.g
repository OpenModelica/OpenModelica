
header "post_include_hpp" {

#define null 0
#include <cstdlib>
#include <iostream>
#include <stack>
#include "node_container.hpp"
}

options {
	language = "Cpp";
}

class modelica_tree_parser extends TreeParser;

options {
	importVocab = modelica_parser;
	k = 2;
	buildAST = false;
}

{
  	node_container parents;

	void start_graph()
	{
		cout << "digraph G {" << endl;
	}
	
	void end_graph()
	{
		cout << "}" << endl;
	}

	void print(antlr::RefAST& token)
	{

		if(!parents.empty())
		{
			cout <<  "\t" << parents.index() << "->" 
	  			<< parents.peek_index() << endl;
		}

		cout << "\t" << parents.peek_index() << " [label=\"" 
			<< token->getText() << "\",shape=box]" << endl;	

		parents.push(token->getText());
	}
}
stored_definition
			{
				
			}
			:
			#(STORED_DEFINITION (within_clause)?
				((FINAL)? {start_graph();} class_definition {end_graph();})*)
			{
			// Put your actions here
			}
			;

within_clause :
  			#(WITHIN^ (name_path)?);

class_definition :
		#(CLASS_DEFINITION 
			(ENCAPSULATED)? 
			(PARTIAL)?
			class_type
			i:IDENT
			{
				print(i);
			}
			class_specifier)
		{ 
	  		// Done visiting class_definition.
	  		parents.pop();
		}
		;

class_type :
		( CLASS | MODEL | RECORD | BLOCK | CONNECTOR | TYPE | PACKAGE 
			| FUNCTION 
		)
		;

class_specifier :
		( string_comment composition
		| EQUALS name_path ( array_subscripts )? ( class_modification )? comment
		)
		;

composition :
		element_list
		(	public_element_list
		|	protected_element_list
		|	equation_clause
		|	algorithm_clause
		)*
		( EXTERNAL	( language_specification )? 
			( external_function_call )?
			( annotation )?
		)?
		;

public_element_list 
		{
			// Initialization
		}
		:
		#(PUBLIC element_list)
		{
			// Actions
		}
		;

protected_element_list
		{
			// Initialization
		}
		:
		#(PROTECTED element_list)
		{
			// Actions
		}
		;

language_specification 
		{
			// Initialization
		}
		:
		STRING
		{
			// Actions
		}
		;

external_function_call 
		{
			// Initialization
		}
		:
		#(EXTERNAL_FUNCTION_CALL 
			(
				(IDENT (expression_list)?)
				|#(EQUALS component_reference IDENT (expression_list)?)
			)
		)
		{
			// Actions
		}
		;

element_list 
		{
			// Initialization
		}
		:
		(	(	element
			|	element_list_annotation
			)
		)*
		{
			// Actions
		}
		;

element_list_annotation 
		{
			// Initialization
		}
		:
		annotation
		{ 
			// Actions
		}
		;


element 
		{
			// Initialization:
		}
		:
		import_clause
		|extends_clause
		|
		#(DECLARATION 
			( (FINAL)? (INNER | OUTER)?
			( component_clause
				| REPLACEABLE component_clause (constraining_clause)?
			)
			)
		)
		|
		#(DEFINITION
			( (FINAL)?
			(INNER | OUTER)?
			( class_definition
				| REPLACEABLE class_definition (constraining_clause)?
			)
			)
		)
		{ 
			// Actions
		}
		;

import_clause 
		{
			// Initialization
		}
		:
		#(IMPORT (explicit_import_name|implicit_import_name) comment)
		{
			// Actions
		}
		;

explicit_import_name
		{
			// Initialization
		}
		:
		#(EQUALS IDENT name_path)
		{
			// Actions
		}
		;

implicit_import_name
		{
			//Initialization
		}
		:
		#(UNQUALIFIED name_path)
		|#(QUALIFIED name_path)
		{
			//Actions
		}
		;


// Note that this is a minor modification of the standard by 
// allowing the comment.
extends_clause
		{
			// Initialization
		}
		: 
		#(EXTENDS name_path ( class_modification )? comment)
		{
			// Actions
		}
		;

constraining_clause 
		{
			// Initialization
		}
		:
		extends_clause
		{
			// Actions
		}
		;

component_clause 
		{
			// Initialization
		}
		:
		type_prefix type_specifier (array_subscripts)? component_list
		{
			// Actions
		}
		;

type_prefix 
		{
			// Initialization
		}
		:
		(FLOW)?
		(DISCRETE
		|PARAMETER
		|CONSTANT
		)?
		(INPUT
		|OUTPUT
		)?
		
		{
			// Actions
		}
		;

type_specifier 
		{
			// Initialization
		}
		:
		name_path
		{
			// Actions
		}
		;

component_list
		{
			// Initialization
		}
		:
		component_declaration (component_declaration)*
		{
			// Actions
		}
		;

component_declaration 
		{
			// Initialization
		}
		:
		declaration comment
		{
			// Actions
		}
		;

declaration
		{
			// Initialization
		} 
		:
		#(IDENT (array_subscripts)? (modification)?)
		{
			// Actions
		}
		;

modification 
		{
			// Initialization
		}
		:
		(	class_modification ( expression )?
		|#(EQUALS expression)
		|#(ASSIGN expression)
		)
		{
			// Actions
		}
		;

class_modification
		{
			// Initialization
		}
		:
		#(CLASS_MODIFICATION (argument_list)?)
		{
			// Actions
		}
		;

argument_list
		{
			// Initialization
		}
		:
		#(ARGUMENT_LIST argument (argument)*)
		{	
			// Actions
		}
		;

argument
		{
			// Initialization
		}
		:
		#(ELEMENT_MODIFICATION element_modification)
		{ 
			// Actions
		}
		|
		#(ELEMENT_REDECLARATION element_redeclaration) 
		{ 
			// Actions
		}
		;

element_modification 
		{
			// Initialization
		}
		:
		(FINAL)? component_reference modification string_comment
		{
			// Actions
		}
		;

element_redeclaration 
		{
			// Initialization
		}
		:
		#(REDECLARE
		(	(class_definition | component_clause1)
			|
			( REPLACEABLE ( class_definition | component_clause1 )
				(constraining_clause)?
			)
		)
		)
		{
			// Actions
		};

component_clause1 
		{
			// Initialization
		}
		:
		type_prefix type_specifier component_declaration
		{
			//Actions
		}
		;

equation_clause 
		{
			// Initialization
		}
		:
		#(EQUATION (equation |annotation)*)
		{
			// Actions
		}
		;

algorithm_clause 
		{
			// Initializatioon
		}
		:
		#(ALGORITHM (algorithm | annotation)*)
		{
			// Actions
		}
		;

equation 
		{
			// Initialization
		}
		:
        #(EQUATION_STATEMENT
            (	equality_equation
            |	conditional_equation_e
            |	for_clause_e
            |	when_clause_e
            |	connect_clause
            |	assert_clause
            )
            comment
        )
		{
			//Actions
		}
		;

algorithm 
		{
			// Initialization
		}
		:
        #(ALGORITHM_STATEMENT 
            (#(ASSIGN (
                        (component_reference (expression | function_call))
                    |	(expression_list component_reference function_call)
                    )
                )
            |	conditional_equation_a
            |	for_clause_a
            |	while_clause
            |	when_clause_a
            |	assert_clause
            )
            comment
        )
		{
			// Actions
		}
		;

equality_equation 
		{
			//Initialization
		}
		:
		#(EQUALS simple_expression expression)
		{
			// Actions
		}
		;

conditional_equation_e
		{
			// Initialization
		}
		:
		#(IF expression equation_list
		( equation_elseif )*
		( ELSE equation_list )?
		)
		{
			// Actions
		}
		;

conditional_equation_a 
		{
			// Initialization
		}
		:
		#(IF expression algorithm_list
		( algorithm_elseif )*
		( ELSE algorithm_list )?
		)
		{
			// Actions
		}
		;

for_clause_e 
		{
			// Initialization
		}
		:
		#(FOR IDENT expression equation_list)
		{
			// Actions
		}
		;

for_clause_a 
		{
			// Initialization
		}
		:
		#(FOR IDENT expression algorithm_list)
		{
			// Initialization
		}
		;

while_clause 
		{
			// Initialization
		}
		:
		#(WHILE expression algorithm_list)
		{
			// Actions
		}
		;

when_clause_e
		{
			// Initialization
		}
		:
		#(WHEN expression equation_list)
		{
			// Actions
		}
		;

when_clause_a 
		{
			// Initialization
		}
		:
		#(WHEN expression algorithm_list (else_when_a)*)
		{
			// Actions
		}
		;

else_when_a
		{
			// Initializations
		}
		:
		#(ELSEWHEN expression algorithm_list)
		{
			// Actions
		}
		;

equation_elseif 
		{
			// Initialization
		}
		:
		#(ELSEIF expression equation_list)
		{
			// Actions
		}
		;

algorithm_elseif
		{
			// Initialization
		}
		:
		#(ELSEIF expression	algorithm_list)
		{
			// Actions
		}
		;

equation_list 
		{
			// Initialization
		}
		:
		(equation)*
		{
			// Actions
		}
		;

algorithm_list 
		{
			// Initialization
		}
		:
		(algorithm)*
		{
			// Actions
		}
		;

connect_clause 
		{
			// Initialization
		}
		:
		#(CONNECT connector_ref connector_ref)
		{
			// Actions
		}
		;

connector_ref
		{
			// Initialization
		}
		:
		#(IDENT (array_subscripts)?)
		|#(DOT #(IDENT (array_subscripts)?) connector_ref_2)
		{
			// Actions
		}
		;

connector_ref_2 
		{
			// Initialization
		}
		:
		#(IDENT ( array_subscripts )?)
		{
			// Actions
		}
		;

assert_clause 
		{
			// Initialization
		}
		:
		#(ASSERT expression STRING ( PLUS STRING )*)
	    |#(TERMINATE STRING ( PLUS STRING )*)
		{
			// Actions
		}
		;
expression 
		{
			// Initialization
		}
		:
		(	simple_expression
		|	if_expression
		)
		{
			// Actions
		}
		;

if_expression 
		{
			// Initialization
		}
		:
		#(IF expression expression expression)
		{
			// Actions
		}
		;

simple_expression 
		{
			// Initialization
		}
		:
		#(RANGE3 logical_expression logical_expression logical_expression)
		{
			// Actions
		}
		|#(RANGE2 logical_expression logical_expression)
		{
			// Actions
		}
		|logical_expression
		{
			// Actions
		}
		;

logical_expression 
		{
			// Initialization
		}
		:
		logical_term
		| #(OR logical_expression logical_term)
		{
			// Actions
		}
		;

logical_term 
		{
			// Initialization
		}
		:
		logical_factor
		|
		#(AND logical_term logical_factor )
		{
			// Actions
		}
		;

logical_factor 
		{
			// Initialization
		}
		:
		#(NOT relation)
		| relation
		{
			// Actions
		}
		;

relation 
		{
			// Initialization
		}
		:
		arithmetic_expression ( rel_op arithmetic_expression )?
		{
			// Actions
		}
		;

rel_op 
		{
			// Initialization
		}
		:
		( LESS | LESSEQ | GREATER | GREATEREQ | EQEQ | LESSGT )
		{
			// Actions
		}
		;

arithmetic_expression 
		{
			// Initialization
		}
		:
		unary_arithmetic_expression
		|#(PLUS arithmetic_expression term)
		|#(MINUS arithmetic_expression term)
		{
			// Actions
		}
		;

unary_arithmetic_expression  
		{
			// Initialization
		}
		:
		#(UNARY_PLUS term)
		|#(UNARY_MINUS term)
		|term
		{
			// Actions
		}
		;

term 
		{
			// Initialization
		}
		:
		factor
		|#(STAR term factor)
		|#(SLASH term factor)
		{
			// Actions
		}
		;

factor 
		{
			// Initialization
		}
		:
		primary
		|#(POWER primary primary)
		{
			// Actions
		}
		;

primary 
		{
			// Initialization
		}
		:
		( UNSIGNED_INTEGER
		| UNSIGNED_REAL
		| STRING
		| FALSE
		| TRUE
		| component_reference__function_call
		| #(LPAR expression_list)
		| #(LBRACK expression_list (expression_list)*)
		| #(LBRACE expression_list)
		)
		{
			// Actions
		}
		;


component_reference__function_call
		{
			// Initialization
		}
		:
		#(FUNCTION_CALL component_reference (function_call)?)
        | component_reference
		{
			// Actions
		}
		;

name_path 
		{
			// Initialization
		}
		:
		IDENT
		|#(DOT IDENT name_path)
		{
			// Actions
		}
		;

component_reference 
		{
			// Initialization
		}
		:
		#(IDENT (array_subscripts )?) 
		|#(DOT #(IDENT (array_subscripts)?) component_reference)
		{
			// Actions
		}
		;

function_call 
		{
			// Initialization
		}
		:
		#(FUNCTION_ARGUMENTS function_arguments)
		{
			// Actions
		}
		;

function_arguments 
		{
			// Initialization
		}
		:
		( expression_list
		| named_arguments
		)
		{
			// Actions
		}
		;

named_arguments 
		{
			// Initialization
		}
		:
		named_argument (named_argument)*
		{
			// Actions
		}
		;

named_argument 
		{
			// Initialization
		}
		:
		#(EQUALS IDENT expression)
		{
			// Actions
		}
		;

expression_list 
		{
			// Initialization
		}
		:
		#(EXPRESSION_LIST expression (expression)*)
		{
			// Actions
		}
		;

array_subscripts 
		{
			// Initialization
		}
		:
		#(LBRACK subscript (subscript)*)
		{
			// Actions
		}
		;

subscript 
		{
			// Initialization
		}
		:
		expression | COLON
		{
			// Actions
		}
		;

comment 
		{
			// Initialization
		}
		:
		#(COMMENT string_comment (annotation)?)|
		{
			// Actions
		}
		;

string_comment 
		{
			// Initialization
		}
		:
		#(STRING_COMMENT string_concatenation)|
		{
			// Actions
		}
		;

string_concatenation
        {
            // Initialization
        }
        :
        STRING
        | #(PLUS string_concatenation STRING)
        {
            // Actions
        }
        ;

annotation 
		{
			// Initialization
		}
		:
		#(ANNOTATION class_modification)
		{
			// Actions
		}
		;
