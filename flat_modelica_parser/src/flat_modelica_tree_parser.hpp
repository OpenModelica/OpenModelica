#ifndef INC_flat_modelica_tree_parser_hpp_
#define INC_flat_modelica_tree_parser_hpp_

#include "antlr/config.hpp"
#include "flat_modelica_tree_parserTokenTypes.hpp"
/* $ANTLR 2.7.1: "walker.g" -> "flat_modelica_tree_parser.hpp"$ */
#include "antlr/TreeParser.hpp"

#line 2 "walker.g"

	#define null 0
    
	#include <iostream>
	#include <stack>
	#include <string>

    //Kaj
    #ifndef modSimPackTest_h
    #define modSimPackTest_h
    #include "modSimPackTest.h"
    #endif    



struct type_prefix_t
{
  type_prefix_t():flow(0), variability(0),direction(0){}
  int flow;
  int variability;
  int direction;

  //          void* flow;
  //          void* variability;
  //          void* direction;
};



#line 40 "flat_modelica_tree_parser.hpp"
class flat_modelica_tree_parser : public ANTLR_USE_NAMESPACE(antlr)TreeParser, public flat_modelica_tree_parserTokenTypes
 {
#line 47 "walker.g"


//Kaj - Stack for storing equations
    stack<string> eq_stack;

//Kaj - Stack for temporarily storing variable declarations
    stack<string> var_stack;

//Kaj - Variable for storing the variable type. Slightly faster then
//searching through the AST.
  string variable_type;

#line 44 "flat_modelica_tree_parser.hpp"
public:
	flat_modelica_tree_parser();
	public: void * stored_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * within_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public:  void*  class_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		bool final
	);
	public: void*  name_path(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  class_restriction(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  class_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * string_comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  composition(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * derived_class(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  enumeration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void type_prefix(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		type_prefix_t &prefix
	);
	public: void*  array_subscripts(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  class_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * enumeration_literal(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  public_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  protected_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  equation_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  algorithm_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  external_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public:  void * annotation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  component_reference(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  element(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  import_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  extends_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  component_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * constraining_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  explicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  implicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  type_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  component_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  component_declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  argument_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  element_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  element_redeclaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  component_clause1(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  algorithm(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  equality_equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  conditional_equation_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  for_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  when_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  connect_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  equation_funcall(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  algorithm_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  conditional_equation_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  for_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  while_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  when_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  simple_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  equation_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  equation_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  algorithm_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  algorithm_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * else_when_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void * else_when_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  connector_ref(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  connector_ref_2(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  if_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  elseif_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  logical_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  logical_term(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  logical_factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  relation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  rel_op(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  unary_arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  term(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  primary(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  component_reference__function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  tuple_expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  function_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  named_argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  named_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void*  subscript(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void *  string_concatenation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
private:
	static const char* _tokenNames[];
	
	static const unsigned long _tokenSet_0_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_0;
	static const unsigned long _tokenSet_1_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_1;
	static const unsigned long _tokenSet_2_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_2;
};

#endif /*INC_flat_modelica_tree_parser_hpp_*/
