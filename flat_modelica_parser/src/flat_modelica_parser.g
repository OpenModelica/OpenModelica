
header "post_include_hpp" {
#define null 0
#include "MyAST.h"
#include <string>
typedef ANTLR_USE_NAMESPACE(antlr)ASTRefCount<MyAST> RefMyAST;
}

options {
	language = "Cpp";
}

class flat_modelica_parser extends Parser;

options {
    codeGenMakeSwitchThreshold = 3;
    codeGenBitsetTestThreshold = 4;
	importVocab = flatmodelica;
    defaultErrorHandler = false;
	k = 2;
	buildAST = true;
    ASTLabelType = "RefMyAST";

}

tokens {
    ALGORITHM_STATEMENT;
	ARGUMENT_LIST;
    BEGIN_DEFINITION;
	CLASS_DEFINITION	;
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
    END_DEFINITION;
	ENUMERATION_LITERAL;
	ELEMENT		;
	ELEMENT_MODIFICATION		;
	ELEMENT_REDECLARATION	;
    EQUATION_STATEMENT;
 	INITIAL_EQUATION;
	INITIAL_ALGORITHM;
    IMPORT_DEFINITION;
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
    DOT_IDENT;
}


/*
 * 2.2.1 Stored definition
 */


//Removed final?
stored_definition :
        ((FINAL)? class_definition )+
        {
            #stored_definition = #([STORED_DEFINITION,"STORED_DEFINITION"],
            #stored_definition);
        }
        
    ;


/*
 * 2.2.2 Class definition
 */

//This is a new item for flat modelica. It allows IDENTS with dots inside them 
dot_ident  
        {
            std::string text;
        } :
        i:IDENT { text.append(i->getText()); }
        (DOT^ j:IDENT^ 
            { text.append(".");
                text.append(j->getText()); }
        )*
        {

            #dot_ident = #([DOT_IDENT,text]);
        }
        ;

class_definition :
		MODEL
		dot_ident
		class_specifier
		{ 
			#class_definition = #([CLASS_DEFINITION, "CLASS_DEFINITION"], 
				class_definition); 
		}
		;

//End of rule to enable extra "garbage" after the end model-statement. 
class_specifier :
		( string_comment composition END! name_path! SEMICOLON! (.)* EOF!
		| EQUALS^  base_prefix name_path ( array_subscripts )?  comment
		| EQUALS^ enumeration
		)
		;

base_prefix:
		type_prefix
		;

name_list:
		name_path (COMMA! name_path)*
		;

enumeration :
		ENUMERATION^ LPAR! enum_list RPAR! comment 
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
		(element  SEMICOLON!)*
		;


element :
		|	(FINAL)?	 
			(INNER | OUTER)?
		(	(class_definition | cc:component_clause)
		)
		{ 
			if(#cc != null) 
			{ 
				#element = #([DECLARATION,"DECLARATION"], #element); 
			}
			else	
			{ 
				#element = #([DEFINITION,"DEFINITION"], #element); 
			}
		}
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
		dot_ident (array_subscripts)? (modification)?
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
        )
		;

element_modification :
		( EACH )? ( FINAL )? component_reference ( modification )? string_comment
	;

component_clause1 :
		type_prefix type_specifier component_declaration
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
		{ LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL }?
		|
		equation SEMICOLON! equation_annotation_list
		; 

algorithm_clause :
		ALGORITHM^
		(algorithm SEMICOLON!)*
		;
initial_algorithm_clause :
		{ LA(2)==ALGORITHM}?
		INITIAL! ALGORITHM^
		(algorithm SEMICOLON!)*
		{
	            #initial_algorithm_clause = #([INITIAL_ALGORITHM,"INTIAL_ALGORITHM"], #initial_algorithm_clause);
		}
		;
equation :

		(	(simple_expression EQUALS) => equality_equation
		|	conditional_equation_e
		|	for_clause_e
		|	when_clause_e
		|   IDENT function_call
		)
        {
            #equation = #([EQUATION_STATEMENT,"EQUATION_STATEMENT"], #equation);
        }
		comment
		;

algorithm :
		( assign_clause_a
		|	conditional_equation_a
		|	for_clause_a
		|	while_clause
		|	when_clause_a
		)
		comment
        {
            #algorithm = #([ALGORITHM_STATEMENT,"ALGORITHM_STATEMENT"], #algorithm);
        }
		;

assign_clause_a : component_reference	( ASSIGN^ expression | function_call );

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

equation_list :
		{LA(1) != END || (LA(1) == END && LA(2) != IDENT)}?
		|
		(equation SEMICOLON! equation_list)
		;

algorithm_list :
		( algorithm SEMICOLON! )*
		;

/*
 * 2.2.7 Expressions
 */

expression :
		( if_expression 
        | simple_expression
		)
		;

if_expression :
		IF^ expression THEN! expression (elseif_expression)* ELSE! expression
    ;

elseif_expression : 
		ELSEIF^ expression THEN! expression
		;

for_indices :
        for_index for_indices2
    ;
for_indices2 :
	{LA(2) != IN}?
		| 
		(COMMA! for_index) for_indices2
		;

for_index:
        (IDENT (IN^ expression)?)
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
			{LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR}?
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
			string_comment 
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

