header "post_include_hpp" {

#define null 0

}
options {
	language= "Cpp";
}

class flat_modelica_parser extends Parser;

options {
	defaultErrorHandler= false;
	k= 2;
//KAJ - Should we really do this?
	buildAST= true;
	importVocab=modelica_parser;
}

declaration :component_reference  (modification)?
		;

// inherited from grammar modelica_parser
stored_definition :(within_clause SEMICOLON!)?
			((f:FINAL)? class_definition SEMICOLON!)* 
			EOF!
			{
				#stored_definition = #([STORED_DEFINITION,"STORED_DEFINITION"],
				#stored_definition);
			}
			;

// inherited from grammar modelica_parser
within_clause :WITHIN^ (name_path)?
			;

// inherited from grammar modelica_parser
class_definition :(ENCAPSULATED)? 
		(PARTIAL)?
		class_type
		IDENT
		class_specifier
		{ 
			#class_definition = #([CLASS_DEFINITION, "CLASS_DEFINITION"], 
				class_definition); 
		}
		;

// inherited from grammar modelica_parser
class_type :( CLASS | MODEL | RECORD | BLOCK | CONNECTOR | TYPE | PACKAGE 
			| FUNCTION 
		)
		;

// inherited from grammar modelica_parser
class_specifier :( string_comment composition END! IDENT!
		| EQUALS^  base_prefix name_path ( array_subscripts )? ( class_modification )? comment
		| EQUALS^ enumeration 
		)
		;

// inherited from grammar modelica_parser
base_prefix :type_prefix
		;

// inherited from grammar modelica_parser
enumeration :ENUMERATION^ LPAR! enum_list RPAR! comment 
		;

// inherited from grammar modelica_parser
enum_list :enumeration_literal ( COMMA! enumeration_literal)*
		;

// inherited from grammar modelica_parser
enumeration_literal :IDENT comment
		{
			#enumeration_literal=#([ENUMERATION_LITERAL,
					"ENUMERATION_LITERAL"],#enumeration_literal);
		}		
		;

// inherited from grammar modelica_parser
composition :element_list
		(	public_element_list
		|	protected_element_list
		| 	initial_equation_clause	
		| 	initial_algorithm_clause	
		|	equation_clause
		|	algorithm_clause
		)*
		( external_clause )?
		;

// inherited from grammar modelica_parser
external_clause :EXTERNAL^	
            ( language_specification )? 
            ( external_function_call )?
			(SEMICOLON!) ?  
			/* Relaxed from Modelica 2.0. This code will be correct in 2.1 */ 
			( annotation SEMICOLON! )?
        ;

// inherited from grammar modelica_parser
public_element_list :PUBLIC^ element_list
		;

// inherited from grammar modelica_parser
protected_element_list :PROTECTED^ element_list
		;

// inherited from grammar modelica_parser
language_specification :STRING
		;

// inherited from grammar modelica_parser
external_function_call :( component_reference EQUALS^ )?
		IDENT LPAR! ( expression_list )? RPAR!
		{
			#external_function_call=#([EXTERNAL_FUNCTION_CALL,
					"EXTERNAL_FUNCTION_CALL"],#external_function_call);
		}
		;

// inherited from grammar modelica_parser
element_list :((element | annotation ) SEMICOLON!)*
		;

// inherited from grammar modelica_parser
element :ic:import_clause
		|	ec:extends_clause			 
		|	(FINAL)?	 
			(INNER | OUTER)?
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

// inherited from grammar modelica_parser
import_clause :IMPORT^ (explicit_import_name | implicit_import_name) comment
		;

// inherited from grammar modelica_parser
explicit_import_name :IDENT EQUALS^ name_path
		;

// inherited from grammar modelica_parser
implicit_import_name! {
			bool has_star = false;
		}
:has_star = np:name_path_star
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

// inherited from grammar modelica_parser
extends_clause :EXTENDS^ name_path ( class_modification )?
		;

// inherited from grammar modelica_parser
constraining_clause :extends_clause
		;

// inherited from grammar modelica_parser
component_clause :type_prefix type_specifier (array_subscripts)? component_list
		;

// inherited from grammar modelica_parser
type_prefix :(FLOW)?
		(DISCRETE
		|PARAMETER
		|CONSTANT
		)?
		(INPUT
		|OUTPUT
		)?
		;

// inherited from grammar modelica_parser
type_specifier :name_path
		;

// inherited from grammar modelica_parser
component_list :component_declaration (COMMA! component_declaration)*
		;

// inherited from grammar modelica_parser
component_declaration :declaration comment
		;

// inherited from grammar modelica_parser
modification :(	class_modification ( EQUALS! expression )?
		|	EQUALS^ expression
		|	ASSIGN^ expression
		)
		;

// inherited from grammar modelica_parser
class_modification :LPAR! ( argument_list )? RPAR! 
		{
			#class_modification=#([CLASS_MODIFICATION,"CLASS_MODIFICATION"],
				#class_modification);
		}
		;

// inherited from grammar modelica_parser
argument_list :argument ( COMMA! argument )*
		{
			#argument_list=#([ARGUMENT_LIST,"ARGUMENT_LIST"],#argument_list);
		}
		;

// inherited from grammar modelica_parser
argument! :(em:element_modification 
		{ 
			#argument = #([ELEMENT_MODIFICATION,"ELEMENT_MODIFICATION"], #em); 
		}
		| er:element_redeclaration 
		{ 
			#argument = #([ELEMENT_REDECLARATION,"ELEMENT_REDECLARATION"], #er); 		}
		)
		;

// inherited from grammar modelica_parser
element_modification :( EACH )? ( FINAL )? component_reference modification string_comment
	;

// inherited from grammar modelica_parser
element_redeclaration :REDECLARE^ ( EACH )? (FINAL )?
		(	(class_definition | component_clause1)
			|
			( REPLACEABLE ( class_definition | component_clause1 )
				(constraining_clause)?
			)
		)
		;

// inherited from grammar modelica_parser
component_clause1 :type_prefix type_specifier component_declaration
		;

// inherited from grammar modelica_parser
initial_equation_clause :{ LA(2)==EQUATION}?
		INITIAL! ec:equation_clause
        {
            #initial_equation_clause = #([INITIAL_EQUATION,"INTIAL_EQUATION"], ec);
        } 

		;

// inherited from grammar modelica_parser
equation_clause :EQUATION^  
		    equation_annotation_list
  		;

// inherited from grammar modelica_parser
equation_annotation_list :{ LA(1) == END || LA(1) == EQUATION || LA(1) == ALGORITHM || LA(1)==INITIAL}?
		|
		( equation SEMICOLON! | annotation SEMICOLON!) equation_annotation_list
		;

// inherited from grammar modelica_parser
algorithm_clause :ALGORITHM^
		(algorithm SEMICOLON!
		|annotation SEMICOLON!
		)*
		;

// inherited from grammar modelica_parser
initial_algorithm_clause :{ LA(2)==ALGORITHM}?
		INITIAL! ALGORITHM^
		(algorithm SEMICOLON!
		|annotation SEMICOLON!
		)*
		{
	            #initial_algorithm_clause = #([INITIAL_ALGORITHM,"INTIAL_ALGORITHM"], #initial_algorithm_clause);
		}
		;

// inherited from grammar modelica_parser
equation :(	(simple_expression EQUALS) => equality_equation
		|	conditional_equation_e
		|	for_clause_e
		|	connect_clause
		|	when_clause_e
		|   IDENT function_call
		)
        {
            #equation = #([EQUATION_STATEMENT,"EQUATION_STATEMENT"], #equation);
        }
		comment
		;

// inherited from grammar modelica_parser
algorithm :( assign_clause_a
		|	multi_assign_clause_a
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

// inherited from grammar modelica_parser
assign_clause_a :component_reference	( ASSIGN^ expression | function_call );

// inherited from grammar modelica_parser
multi_assign_clause_a :LPAR! expression_list RPAR! ASSIGN^ component_reference function_call;

// inherited from grammar modelica_parser
equality_equation :simple_expression EQUALS^ expression
		;

// inherited from grammar modelica_parser
conditional_equation_e :IF^ expression THEN! equation_list
		( equation_elseif )*
		( ELSE equation_list )?
		END! IF!
		;

// inherited from grammar modelica_parser
conditional_equation_a :IF^ expression THEN! algorithm_list
		( algorithm_elseif )*
		( ELSE algorithm_list )?
		END! IF!
		;

// inherited from grammar modelica_parser
for_clause_e :FOR^ for_indices LOOP!
		equation_list
		END! FOR!
		;

// inherited from grammar modelica_parser
for_clause_a :FOR^ for_indices LOOP!
		algorithm_list
		END! FOR!
		;

// inherited from grammar modelica_parser
while_clause :WHILE^ expression LOOP!
		algorithm_list
		END! WHILE!
		;

// inherited from grammar modelica_parser
when_clause_e :WHEN^ expression THEN!
		equation_list
		(else_when_e) *
		END! WHEN!
		;

// inherited from grammar modelica_parser
else_when_e :ELSEWHEN^ expression THEN! 
		equation_list
		;

// inherited from grammar modelica_parser
when_clause_a :WHEN^ expression THEN!
		algorithm_list
		(else_when_a)*
		END! WHEN!
		;

// inherited from grammar modelica_parser
else_when_a :ELSEWHEN^ expression THEN!
		algorithm_list
		;

// inherited from grammar modelica_parser
equation_elseif :ELSEIF^ expression THEN!
		equation_list
		;

// inherited from grammar modelica_parser
algorithm_elseif :ELSEIF^ expression THEN!
		algorithm_list
		;

// inherited from grammar modelica_parser
equation_list :{LA(1) != END || (LA(1) == END && LA(2) != IDENT)}?
		|
		(equation SEMICOLON! equation_list)
		;

// inherited from grammar modelica_parser
algorithm_list :( algorithm SEMICOLON! )*
		;

// inherited from grammar modelica_parser
connect_clause :CONNECT^ LPAR! connector_ref COMMA! connector_ref RPAR!
		;

// inherited from grammar modelica_parser
connector_ref :IDENT^ ( array_subscripts )? ( DOT^ connector_ref_2 )?
		;

// inherited from grammar modelica_parser
connector_ref_2 :IDENT^ ( array_subscripts )?
		;

// inherited from grammar modelica_parser
expression :( if_expression 
        | simple_expression
		)
		;

// inherited from grammar modelica_parser
if_expression :IF^ expression THEN! expression (elseif_expression)* ELSE! expression
    ;

// inherited from grammar modelica_parser
elseif_expression :ELSEIF^ expression THEN! expression
		;

// inherited from grammar modelica_parser
for_indices :for_index for_indices2
    ;

// inherited from grammar modelica_parser
for_indices2 :{LA(2) != IN}?
		| 
		(COMMA! for_index) for_indices2
		;

// inherited from grammar modelica_parser
for_index :(IDENT (IN^ expression)?)
;

// inherited from grammar modelica_parser
simple_expression! :l1:logical_expression 
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

// inherited from grammar modelica_parser
logical_expression :logical_term ( OR^ logical_term )*
		;

// inherited from grammar modelica_parser
logical_term :logical_factor ( AND^ logical_factor )*
		;

// inherited from grammar modelica_parser
logical_factor :( NOT^ )?
		relation
		;

// inherited from grammar modelica_parser
relation :arithmetic_expression ( ( LESS^ | LESSEQ^ | GREATER^ | GREATEREQ^ | EQEQ^ | LESSGT^ ) arithmetic_expression )?
		;

// inherited from grammar modelica_parser
rel_op :( LESS^ | LESSEQ^ | GREATER^ | GREATEREQ^ | EQEQ^ | LESSGT^ )
		;

// inherited from grammar modelica_parser
arithmetic_expression :unary_arithmetic_expression ( ( PLUS^ | MINUS^ ) term )*
		;

// inherited from grammar modelica_parser
unary_arithmetic_expression! :( PLUS t1:term 
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

// inherited from grammar modelica_parser
term :factor ( ( STAR^ | SLASH^ ) factor )*
		;

// inherited from grammar modelica_parser
factor :primary ( POWER^ primary )?
		;

// inherited from grammar modelica_parser
primary :( UNSIGNED_INTEGER
		| UNSIGNED_REAL
		| STRING
		| FALSE
		| TRUE
		| component_reference__function_call
		| LPAR^ expression_list RPAR!
		| LBRACK^ expression_list (SEMICOLON! expression_list)* RBRACK!
		| LBRACE^ expression_list RBRACE!
		| END
		)
    ;

// inherited from grammar modelica_parser
component_reference__function_call! :cr:component_reference ( fc:function_call )? 
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

// inherited from grammar modelica_parser
name_path :{ LA(2)!=DOT }? IDENT |
		IDENT DOT^ name_path
		;

// inherited from grammar modelica_parser
name_path_star returns [bool val]:{ LA(2)!=DOT }? IDENT { val=false;}|
		{ LA(2)!=DOT }? STAR! { val=true;}|
		i:IDENT DOT^ val = np:name_path_star
		{
			if(!(#np))
			{
				#name_path_star = #i;
			}
		}
		;

// inherited from grammar modelica_parser
component_reference :IDENT^ ( array_subscripts )? ( DOT^ component_reference )?
		;

// inherited from grammar modelica_parser
function_call :LPAR! (function_arguments) RPAR! 
		{
			#function_call = #([FUNCTION_ARGUMENTS,"FUNCTION_ARGUMENTS"],#function_call);
		}	
		;

// inherited from grammar modelica_parser
function_arguments :(for_or_expression_list)
			(named_arguments) ?
		;

// inherited from grammar modelica_parser
for_or_expression_list :(
			{LA(1)==IDENT && LA(2) == EQUALS|| LA(1) == RPAR}?
		|
			(
				e:expression
				( COMMA! for_or_expression_list2 
				| FOR^ for_indices
				)?
			)
			{
				#for_or_expression_list = #([EXPRESSION_LIST,"EXPRESSION_LIST"],#for_or_expression_list);
			}

		)
		;

// inherited from grammar modelica_parser
for_or_expression_list2 :{LA(2) == EQUALS}?
		| 
		expression (COMMA! for_or_expression_list2)?
		;

// inherited from grammar modelica_parser
named_arguments :named_arguments2
		{
			#named_arguments=#([NAMED_ARGUMENTS,"NAMED_ARGUMENTS"],#named_arguments);
		}
		;

// inherited from grammar modelica_parser
named_arguments2 :named_argument ( COMMA! (COMMA IDENT EQUALS) => named_arguments2)?
		;

// inherited from grammar modelica_parser
named_argument :IDENT EQUALS^ expression
		;

// inherited from grammar modelica_parser
expression_list :expression_list2
		{
			#expression_list=#([EXPRESSION_LIST,"EXPRESSION_LIST"],#expression_list);
		}
		;

// inherited from grammar modelica_parser
expression_list2 :expression (COMMA! expression_list2)?
	    ;

// inherited from grammar modelica_parser
array_subscripts :LBRACK^ subscript ( COMMA! subscript )* RBRACK!
	;

// inherited from grammar modelica_parser
subscript :expression | COLON
		;

// inherited from grammar modelica_parser
comment :(
			//string_comment	 ANNOTATION )=> annotation
			string_comment (annotation)?
		)
		{
			#comment=#([COMMENT,"COMMENT"],#comment);
		}
		;

// inherited from grammar modelica_parser
string_comment :( STRING (PLUS STRING) => ( PLUS^ STRING )* )?
		{
            if (#string_comment)
            {
                #string_comment = #([STRING_COMMENT,"STRING_COMMENT"],	#string_comment);
            }
		}
;

// inherited from grammar modelica_parser
annotation :ANNOTATION^ class_modification
		;


