
header "post_include_hpp" {

#define null 0

#include <cstdlib>
#include <iostream>

#include "indentation.hpp"
}

options {
	language = "Cpp";
}

class modelica_tree_parser extends TreeParser;

options {
	importVocab = modelica_parser;
	k = 2;
	buildAST = true;
}

{
  indentation indent;

  bool print_text;

  void print_indent(int spaces)
  {
	for (int i=0; i < spaces; i++)
	std::cout << " ";
  }

  void print(std::string str, bool insert_space_before = true,
  			bool insert_space_after = false)		
  {
	std::string tmp;
	
	if (indent.indent_next())
	{
		print_indent(indent.top());
		indent.indent_next(false);
	}

	if (insert_space_before) tmp = " ";
	tmp += str;
	if (insert_space_after) tmp += " ";

	std::cout << tmp;
  }
  
  void print(antlr::RefAST& token,bool insert_space_before = true,
  			bool insert_space_after = false)
  {
	print(token->getText(),insert_space_before,insert_space_after);
  }

  void print_line(std::string str,bool insert_space_before = false)
  {
	print(str,insert_space_before);
	if (print_text) cout << endl;
	indent.indent_next(true);
  }

  void print_line(antlr::RefAST& token,bool insert_space_before = false)
  {
	print_line(token->getText(),insert_space_before);
  }
}


stored_definition
			{
				indent.init();
  				print_text = true;
  			}
			:
			#(STORED_DEFINITION 
			( within_clause { 
		  		print_line(";",true);print_line("");} )?
				( (f:FINAL { print(f);} )? 
				class_definition { print_line(";"); print_line(""); indent.pop();}
				)*
			)
			;

within_clause : 
			#(  w:WITHIN^ { print(w);} 
	  			(np:name_path)?
			)
  			;

class_definition :
		#(CLASS_DEFINITION 
			(e:ENCAPSULATED 	{ print(e);} )? 
			(p:PARTIAL	 		{ print(p);} )?
			c:class_type 		{ print(c);}
			i:IDENT 			{ print(i);}
			class_specifier[i->getText()]
		)
		;

class_type :
		( CLASS | MODEL | RECORD | BLOCK | CONNECTOR | TYPE | PACKAGE 
			| FUNCTION 
		)
		;

class_specifier [std::string id]
		:
		( string_comment { print_line(""); indent.push(indent.top()+2);}
			composition		
			{
				indent.pop();
				print("end "+id);
	  		}
		| e:EQUALS {print(e);}
			name_path ( array_subscripts )? ( class_modification )? comment
		)
		;

composition :
		element_list
		(	public_element_list
		|	protected_element_list
		|	equation_clause
		|	algorithm_clause
		)*
		( e:EXTERNAL {print(e);} ( language_specification )? 
			( external_function_call )? {print(";");}
			( annotation {print(";");})?
		)?
		;

public_element_list :
		#(p:PUBLIC {print_line(p);indent.push(indent.top()+2);} 
			element_list {indent.pop();}
		)
		;

protected_element_list :
		#(p:PROTECTED {print_line(p); indent.push(indent.top()+2);}
			element_list {indent.pop();})
		;

language_specification :
		s:STRING {print(s);};

external_function_call :
		#(EXTERNAL_FUNCTION_CALL 
			(
				(i:IDENT {print(i);} {print("(");} (expression_list)? {print(")");})
				|#(e:EQUALS component_reference {print(e);} i2:IDENT {print(i);} {print("(");} (expression_list)? {print(")");})
			)
		)
		;

element_list :
		(( element| annotation) { print_line(";");})*;

element :
		import_clause
		|extends_clause
		|
		#(DECLARATION 
			( (f:FINAL {print(f);})? 
			  (i:INNER {print(i);}| o:OUTER {print(o);})?
			( component_clause
				| r:REPLACEABLE {print(r);} 
			component_clause (constraining_clause)?
			)
			)
		)
		|
		#(DEFINITION
			( (fd:FINAL { print(fd);})?
			(id:INNER { print(id);}| od:OUTER { print(od);})?
			( class_definition
				| rd:REPLACEABLE { print(rd);} class_definition (constraining_clause)?
			)
			)
		)
		;

import_clause :
		#(i:IMPORT {print(i);} (explicit_import_name|implicit_import_name) comment)
		;

explicit_import_name :
		#(e:EQUALS i:IDENT {print(i); print(e);} name_path)	;

implicit_import_name :
		#(UNQUALIFIED name_path {print(".");print("*");})
		|#(QUALIFIED name_path)
		;


// Note that this is a minor modification of the standard by 
// allowing the comment.
extends_clause : 
		#(e:EXTENDS {print(e);} name_path 
	  	( class_modification )? comment)
		;

constraining_clause :
		extends_clause;

component_clause :
		type_prefix type_specifier (array_subscripts)? component_list;

type_prefix :
		(f:FLOW { print(f);})?
		(d:DISCRETE { print(d);}
		|p:PARAMETER { print(p);}
		|c:CONSTANT { print(c);}
		)?
		(i:INPUT { print(i);}
		|o:OUTPUT { print(o);}
		)?
		;

type_specifier :
		name_path;

component_list :
		component_declaration ( {print(",");} component_declaration)*;

component_declaration :
		declaration comment;

declaration :
		#(i:IDENT {print(i);} (array_subscripts)? (modification)?);

modification :
		( class_modification ( {print("=");} expression )?
		|#(e:EQUALS {print(e);} expression)
		|#(a:ASSIGN {print(a);} expression)
		)
		;

class_modification :
		#(CLASS_MODIFICATION {print("(");} (argument_list)? {print(")");})
		;

argument_list :
		#(ARGUMENT_LIST argument ({print(",");} argument)*);

argument :
		#(ELEMENT_MODIFICATION element_modification)
		|
		#(ELEMENT_REDECLARATION element_redeclaration) 
		;

element_modification :
		(f:FINAL {print(f);})? component_reference modification string_comment
		;

element_redeclaration :
		#(r:REDECLARE {print(r);}
		(	(class_definition | component_clause1)
			|
			( re:REPLACEABLE {print(re);}( class_definition | component_clause1 )
				(constraining_clause)?
			)
		)
		)
		;

component_clause1 :
		type_prefix type_specifier component_declaration;

equation_clause :
		#(e:EQUATION { print_line(e->getText());indent.push(indent.top()+2);}
		 (equation { print_line(";");}
			|annotation { print_line(";");})*)
		{
			indent.pop();
		}
		;

algorithm_clause :
		#(a:ALGORITHM { print_line(a->getText());indent.push(indent.top()+2);}
		 (algorithm { print_line(";");}
			| annotation { print_line(";");})*)
		{
			indent.pop();
		}
		;

equation :
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
		;

algorithm :
        #(ALGORITHM_STATEMENT 
            (#(a:ASSIGN (
                        (component_reference {print(a);}(expression | function_call))
                    |	({print("(");} expression_list {print(")");} {print(a);}component_reference function_call)
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
		;

equality_equation :
		#(e:EQUALS simple_expression {print(e->getText());} expression);

conditional_equation_e :
		#(i:IF {print(i);} 
			expression {print_line("then");indent.push(indent.top()+2);} 
			equation_list {indent.pop();}
		( equation_elseif )*
		( e:ELSE {print_line(e);indent.push(indent.top()+2);}
				equation_list {indent.pop();})?
		{indent.pop();print("end if");})
		;

conditional_equation_a :
		#(i:IF {print(i);} 
			expression {print_line("then");indent.push(indent.top()+2);} 
			algorithm_list {indent.pop();}
		( algorithm_elseif )*
		( e:ELSE {print_line(e); indent.push(indent.top()+2);} 
				algorithm_list {indent.pop();})?
		{indent.pop();print("end if");})
		;

for_clause_e :
		#(f:FOR {print(f->getText());} i:IDENT {print(i->getText());print("in");}
			expression {print_line("loop"); indent.push(indent.top()+2);}
			equation_list {indent.pop();print("end for");})
		;

for_clause_a :
		#(f:FOR {print(f->getText());} i:IDENT {print(i->getText());print("in");} expression {print_line("loop"); indent.push(indent.top()+2);} 
			algorithm_list {indent.pop(); print("end for");})
		;

while_clause :
		#(w:WHILE {print(w->getText());} 
			expression {print_line("loop"); indent.push(indent.top()+2);}
			algorithm_list) {indent.pop();print("end while");}
		;

when_clause_e :
		#(w:WHEN { print(w->getText());}
			expression { print_line("then");indent.push(indent.top()+2);}
			equation_list)
		{ indent.pop(); print("end when");}
		;

when_clause_a :
		#(w:WHEN { print(w->getText());} 
			expression { print_line("then"); }
			algorithm_list (else_when_a)*)
		{ indent.pop();print("end when");}
		;

else_when_a :
		#(e:ELSEWHEN {print(e);} expression {print_line("then"); indent.push(indent.top()+2);} algorithm_list {indent.pop();})
		;

equation_elseif :
		#(e:ELSEIF {print(e);} expression {print_line("then");indent.push(indent.top()+2);} equation_list {indent.pop();})
		;

algorithm_elseif :
		#(e:ELSEIF {print(e);} expression {print_line("then");indent.push(indent.top()+2);}
			algorithm_list {indent.pop();}
		)
		;

equation_list :
		(equation {print_line(";");})*;

algorithm_list :
		(algorithm {print_line(";");})*;

connect_clause :
		#(c:CONNECT {print(c);print("(");} connector_ref {print(",");}
			connector_ref {print(")");})
		;

connector_ref :
		#(i:IDENT {print(i);} (array_subscripts)?)
		|#(d:DOT #(i2:IDENT {print(i2);} (array_subscripts)?) 
			{print(d);} connector_ref_2)
		;

connector_ref_2 :
		#(i:IDENT {print(i);} ( array_subscripts )?)
		;

assert_clause :
		#(a:ASSERT { print(a);print("(");}
			expression s:STRING {print(s);} 
			( p:PLUS {print(p);} s2:STRING {print(s2);})* {print(")");})
	    |#(t:TERMINATE {print(t);print("(");} s3:STRING {print(s3);}
			( p2:PLUS {print(p2);} s4:STRING {print(s4);})* {print(")");})
		;

expression :
		(	simple_expression
		|	if_expression
		)
		;

if_expression :
		#(i:IF {print(i);} expression {print("then");} 
			expression {print("else");} expression
		);

simple_expression :
		#(RANGE3 logical_expression {print(":");}
			logical_expression {print(":");}
			logical_expression)
		|#(RANGE2 logical_expression {print(":");} logical_expression)
		|logical_expression
		;

logical_expression :
		logical_term| #(o:OR logical_expression {print(o);} logical_term);

logical_term :
		logical_factor	| #(a:AND logical_term {print(a);} logical_factor );

logical_factor :
		#(n:NOT {print(n);} relation)| relation;

relation :
		arithmetic_expression ( rel_op arithmetic_expression )?	;

rel_op :
		( le:LESS {print(le);}
		| leq:LESSEQ {print(leq);}
		| gr:GREATER {print(gr);}
		| greq:GREATEREQ {print(greq);}
		| eqeq:EQEQ {print(eqeq);}
		| legt:LESSGT {print(legt);})
		;

arithmetic_expression :
		unary_arithmetic_expression
		|#(p:PLUS arithmetic_expression {print(p);} term)
		|#(m:MINUS arithmetic_expression {print(m);} term)
		;

unary_arithmetic_expression :
		#(up:UNARY_PLUS {print(up);} term)
		|#(um:UNARY_MINUS {print("-");} term)
		|term
		;

term :
		factor
		|#(st:STAR term {print(st);} factor)
		|#(sl:SLASH term {print(sl);} factor)
		;

factor 	:
		primary
		|#(POWER primary {print("^");} primary)
		;

primary :
		( ui:UNSIGNED_INTEGER { print(ui);}
		| ur:UNSIGNED_REAL { print(ur);}
		| s:STRING { print(s);}
		| f:FALSE {print(f);}
		| t:TRUE {print(t);}
		| component_reference__function_call
		| #(LPAR {print("(");} expression_list {print(")");})
		| #(LBRACK {print("[");} expression_list 
				({print(";");} expression_list)* {print("]");})
		| #(LBRACE {print("{");} expression_list {print("}");})
		)
		;


component_reference__function_call :
		#(FUNCTION_CALL component_reference (function_call)?)
        | component_reference
		;

name_path :
		i:IDENT { print(i,false);} 
		|#(d:DOT i2:IDENT {print(i2,false);} {print(d,false);} name_path )
		;

component_reference	:
		#(i:IDENT {print(i);} (array_subscripts )?) 
		|#(d:DOT #(i2:IDENT {print(i2);} (array_subscripts)?) {print(d);} 
			component_reference)
		;

function_call :
		#(FUNCTION_ARGUMENTS {print("(");} function_arguments {print(")");});

function_arguments 	:
		( expression_list
		| named_arguments
		)
		;

named_arguments :
		named_argument ({print(",");} named_argument)*;

named_argument :
		#(eq:EQUALS i:IDENT {print(i);print(eq);} expression);

expression_list :
		#(EXPRESSION_LIST expression ({print(",");} expression)*)
		;

array_subscripts :
		#(LBRACK {print("[");} subscript 
			({print(",");} subscript)* {print("]");})
		;

subscript :
		expression | c:COLON {print(c);};

comment :
		#(COMMENT string_comment (annotation)?)|
		;

string_comment :
		#(STRING_COMMENT string_concatenation)
		|
		;

string_concatenation :
        s:STRING { print(s);} 
        |#(p:PLUS string_concatenation {print(p);} s2:STRING {print(s2);})
        ;

annotation :
		#(a:ANNOTATION {print(a);} class_modification);
