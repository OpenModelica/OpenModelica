
header "post_include_hpp" {

#define null 0

}

options {
	language = "Cpp";
}

class modelica_parser extends Parser;

options {
	importVocab = modelica;
	k = 2;
	buildAST = true;
}

tokens {
    ALGORITHM_STATEMENT;
	ARGUMENT_LIST;
	CLASS_DEFINITION	;
	CLASS_MODIFICATION;
	COMMENT;
	DECLARATION	;
	DEFINITION ;
	ELEMENT		;
	ELEMENT_MODIFICATION		;
	ELEMENT_REDECLARATION	;
    EQUATION_STATEMENT;
	EXPRESSION_LIST;
	EXTERNAL_FUNCTION_CALL;
	FUNCTION_CALL		;
	FUNCTION_ARGUMENTS;
	QUALIFIED;
	RANGE2		;
	RANGE3		;
  	STORED_DEFINITION ;
	STRING_COMMENT;
	UNARY_MINUS	;
	UNARY_PLUS	;
	UNQUALIFIED;

}


/*
 * 2.2.1 Stored definition
 */


stored_definition :
			(within_clause SEMICOLON!)?
			((f:FINAL)? class_definition SEMICOLON!)*
			EOF!
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
		IDENT
		class_specifier
		{ 
			#class_definition = #([CLASS_DEFINITION, "CLASS_DEFINITION"], 
				class_definition); 
		}
		;

class_type :
		( CLASS | MODEL | RECORD | BLOCK | CONNECTOR | TYPE | PACKAGE 
			| FUNCTION 
		)
		;

class_specifier :
		( string_comment composition END! IDENT!
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
			SEMICOLON!
			( annotation SEMICOLON! )?
		)?
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
		((element | annotation ) SEMICOLON!)*
		;

//element_list_annotation :
//		annotation
//		{ 
//			#element_list_annotation = #([ELEMENT,"c"], 
//				#element_list_annotation); 
//		}
//		;


element :
			ic:import_clause
		|	ec:extends_clause			 
		|	(FINAL)?	 
			(INNER | OUTER)?
		(	(class_definition | cc:component_clause)
			|(REPLACEABLE ( class_definition | cc2:component_clause )
				(constraining_clause)?
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
		EXTENDS^ name_path ( class_modification )? comment
		;

constraining_clause :
		extends_clause
		;

/*
 * 2.2.4 Component clause
 */

component_clause :
		type_prefix type_specifier (array_subscripts)? component_list
		;

type_prefix :
		(FLOW)?
		(DISCRETE
		|PARAMETER
		|CONSTANT
		)?
		(INPUT
		|OUTPUT
		)?
		;

type_specifier :
		name_path
		;

component_list :
		component_declaration (COMMA! component_declaration)*
		;

component_declaration :
		declaration comment
		;

declaration :
		IDENT^ (array_subscripts)? (modification)?
		;

/*
 * 2.2.5 Modification
 */

modification :
		(	class_modification ( EQUALS! expression )?
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
		(em:element_modification 
		{ 
			#argument = #([ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION"], #em); 
		}
		| er:element_redeclaration 
		{ 
			#argument = #([ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION"], #er); 		}
		)
		;

element_modification :
		( FINAL )? component_reference modification string_comment
	;

element_redeclaration :
		REDECLARE^
		(	(class_definition | component_clause1)
			|
			( REPLACEABLE ( class_definition | component_clause1 )
				(constraining_clause)?
			)
		)
		;

component_clause1 :
		type_prefix type_specifier component_declaration
		;


/*
 * 2.2.6 Equations
 */

equation_clause :
		EQUATION^
		(equation SEMICOLON!
		|annotation SEMICOLON!
		)*
		;

algorithm_clause :
		ALGORITHM^
		(algorithm SEMICOLON!
		|annotation SEMICOLON!
		)*
		;

equation :
		(	equality_equation
		|	conditional_equation_e
		|	for_clause_e
		|	when_clause_e
		|	connect_clause
		|	assert_clause
		)
        {
            #equation = #([EQUATION_STATEMENT,"EQUATION_STATEMENT"], #equation);
        }
		comment
		;

algorithm :
		( assign_clause_a
		|	multi_assign_clause_a
		|	conditional_equation_a
		|	for_clause_a
		|	while_clause
		|	when_clause_a
		|	assert_clause
		)
		comment
        {
            #algorithm = #([ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT"], #algorithm);
        }
		;

assign_clause_a : component_reference	( ASSIGN^ expression | function_call );

multi_assign_clause_a :
        LPAR! expression_list RPAR! ASSIGN^ component_reference function_call;

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
		FOR^ IDENT IN! expression LOOP!
		equation_list
		END! FOR!
		;

for_clause_a :
		FOR^ IDENT IN! expression LOOP!
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
		END! WHEN!
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

equation_list :
		( equation SEMICOLON! )*
		;

algorithm_list :
		( algorithm SEMICOLON! )*
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

assert_clause :
		ASSERT^ LPAR! expression COMMA! STRING ( PLUS^ STRING )* RPAR!
		|TERMINATE LPAR! STRING ( PLUS^ STRING )* RPAR!
		;

/*
 * 2.2.7 Expressions
 */

expression :
		(	simple_expression
		|	if_expression
		)
		;

if_expression :
		IF^ expression THEN! expression ELSE! expression
		;

simple_expression ! :
		l1:logical_expression 
		( COLON l2:logical_expression 
			( COLON l3:logical_expression 
			)? 
		)?
		{ 
			if (#l3 != null) 
			{ 
				#simple_expression = #([RANGE3,"RANGE3"], l1, l2, l3); 
			}
			else if (#l2 != null) 
			{ 
				#simple_expression = #([RANGE2,"RANGE2"], l1, l2); 
			}
			else 
			{ 
				#simple_expression = #l1; 
			}
		}
		;

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
		arithmetic_expression ( ( LESS^ | LESSEQ^ | GREATER^ | GREATEREQ^ | EQEQ^ | LESSGT^ ) arithmetic_expression )?
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
		| LPAR^ expression_list RPAR!
		| LBRACK^ expression_list (SEMICOLON! expression_list)* RBRACK!
		| LBRACE^ expression_list RBRACE!
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
		;

name_path :
		{ LA(2)!=DOT }? IDENT |
		IDENT DOT^ name_path
		;

name_path_star returns [bool val]
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
		;

function_call :
		LPAR! function_arguments RPAR!
		{
			#function_call=#([FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS"],#function_call);
		}
		;

function_arguments :
		( expression_list
		| named_arguments
		)?
		;

named_arguments :
		named_argument ( COMMA! named_argument )*
		;

named_argument :
		IDENT EQUALS^ expression
		;

expression_list :
		expression ( COMMA! expression )*
		{
			#expression_list=#([EXPRESSION_LIST,"EXPRESSION_LIST"],#expression_list);
		}
		;

array_subscripts :
		LBRACK^ subscript ( COMMA! subscript )* RBRACK!
	;

subscript :
		expression | COLON
		;

comment :
		string_comment (annotation)?
		{
			if (#comment)
            {
                #comment=#([COMMENT,"COMMENT"],#comment);
            }
		}
//		string_comment	( ( ANNOTATION )=> annotation
		;

string_comment :
		( STRING ( PLUS^ STRING )* )?
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
