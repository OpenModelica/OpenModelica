#ifndef INC_modelica_parser_hpp_
#define INC_modelica_parser_hpp_

#include <antlr/config.hpp>
/* $ANTLR 2.7.7 (2006-11-01): "modelica_parser.g" -> "modelica_parser.hpp"$ */
#include <antlr/TokenStream.hpp>
#include <antlr/TokenBuffer.hpp>
#include "modelica_parserTokenTypes.hpp"
#include <antlr/LLkParser.hpp>

#line 2 "modelica_parser.g"

#define null 0
#include "MyAST.h"

typedef ANTLR_USE_NAMESPACE(antlr)ASTRefCount<MyAST> RefMyAST;


#line 20 "modelica_parser.hpp"
class CUSTOM_API modelica_parser : public ANTLR_USE_NAMESPACE(antlr)LLkParser, public modelica_parserTokenTypes
{
#line 1 "modelica_parser.g"
#line 24 "modelica_parser.hpp"
public:
	void initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory );
protected:
	modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf, int k);
public:
	modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenBuffer& tokenBuf);
protected:
	modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer, int k);
public:
	modelica_parser(ANTLR_USE_NAMESPACE(antlr)TokenStream& lexer);
	modelica_parser(const ANTLR_USE_NAMESPACE(antlr)ParserSharedInputState& state);
	int getNumTokens() const
	{
		return modelica_parser::NUM_TOKENS;
	}
	const char* getTokenName( int type ) const
	{
		if( type > getNumTokens() ) return 0;
		return modelica_parser::tokenNames[type];
	}
	const char* const* getTokenNames() const
	{
		return modelica_parser::tokenNames;
	}
	public: void stored_definition();
	public: void class_type();
	public: void component_clause();
	public: void import_clause();
	public: void within_clause();
	public: void class_definition();
	public: void name_path();
	public: void class_specifier();
	public: void class_specifier2();
	public: void class_modification();
	public: void string_comment();
	public: void composition();
	public: void base_prefix();
	public: void array_subscripts();
	public: void comment();
	public: void enumeration();
	public: void pder();
	public: void overloading();
	public: void ident_list();
	public: void name_list();
	public: void type_prefix();
	public: void enum_list();
	public: void enumeration_literal();
	public: void element_list();
	public: void public_element_list();
	public: void protected_element_list();
	public: void initial_equation_clause();
	public: void initial_algorithm_clause();
	public: void equation_clause();
	public: void algorithm_clause();
	public: void external_clause();
	public: void language_specification();
	public: void external_function_call();
	public: void annotation();
	public: void external_annotation();
	public: void component_reference();
	public: void expression_list();
	public: void element();
	public: void extends_clause();
	public: void constraining_clause();
	public: void explicit_import_name();
	public: void implicit_import_name();
	public: bool  name_path_star();
	public: void type_specifier();
	public: void component_list();
	public: void component_declaration();
	public: void declaration();
	public: void conditional_attribute();
	public: void expression();
	public: void modification();
	public: void argument_list();
	public: void argument();
	public: void element_modification_or_replaceable();
	public: void element_redeclaration();
	public: void element_modification();
	public: void element_replaceable();
	public: void component_clause1();
	public: void component_declaration1();
	public: void equation_annotation_list();
	public: void equation();
	public: void algorithm_annotation_list();
	public: void simple_expression();
	public: void equality_equation();
	public: void conditional_equation_e();
	public: void for_clause_e();
	public: void connect_clause();
	public: void when_clause_e();
	public: void function_call();
	public: void algorithm();
	public: void assign_clause_a();
	public: void multi_assign_clause_a();
	public: void conditional_equation_a();
	public: void for_clause_a();
	public: void while_clause();
	public: void when_clause_a();
	public: void equation_list();
	public: void equation_elseif();
	public: void algorithm_list();
	public: void algorithm_elseif();
	public: void for_indices();
	public: void else_when_e();
	public: void else_when_a();
	public: void connector_ref();
	public: void connector_ref_2();
	public: void if_expression();
	public: void code_expression();
	public: void elseif_expression();
	public: void for_index();
	public: void for_indices2();
	public: void logical_expression();
	public: void code_equation_clause();
	public: void code_initial_equation_clause();
	public: void code_algorithm_clause();
	public: void code_initial_algorithm_clause();
	public: void logical_term();
	public: void logical_factor();
	public: void relation();
	public: void arithmetic_expression();
	public: void rel_op();
	public: void unary_arithmetic_expression();
	public: void term();
	public: void factor();
	public: void primary();
	public: void component_reference__function_call();
	public: void for_or_expression_list();
	public: void function_arguments();
	public: void named_arguments();
	public: void for_or_expression_list2();
	public: void named_arguments2();
	public: void named_argument();
	public: void expression_list2();
	public: void subscript();
public:
	ANTLR_USE_NAMESPACE(antlr)RefAST getAST()
	{
		return ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
	}
	
protected:
	RefMyAST returnAST;
private:
	static const char* tokenNames[];
#ifndef NO_STATIC_CONSTS
	static const int NUM_TOKENS = 153;
#else
	enum {
		NUM_TOKENS = 153
	};
#endif
	
	static const unsigned long _tokenSet_0_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_0;
	static const unsigned long _tokenSet_1_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_1;
	static const unsigned long _tokenSet_2_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_2;
	static const unsigned long _tokenSet_3_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_3;
	static const unsigned long _tokenSet_4_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_4;
	static const unsigned long _tokenSet_5_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_5;
	static const unsigned long _tokenSet_6_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_6;
	static const unsigned long _tokenSet_7_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_7;
	static const unsigned long _tokenSet_8_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_8;
	static const unsigned long _tokenSet_9_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_9;
	static const unsigned long _tokenSet_10_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_10;
	static const unsigned long _tokenSet_11_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_11;
	static const unsigned long _tokenSet_12_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_12;
	static const unsigned long _tokenSet_13_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_13;
	static const unsigned long _tokenSet_14_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_14;
	static const unsigned long _tokenSet_15_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_15;
	static const unsigned long _tokenSet_16_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_16;
	static const unsigned long _tokenSet_17_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_17;
	static const unsigned long _tokenSet_18_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_18;
	static const unsigned long _tokenSet_19_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_19;
	static const unsigned long _tokenSet_20_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_20;
	static const unsigned long _tokenSet_21_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_21;
	static const unsigned long _tokenSet_22_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_22;
	static const unsigned long _tokenSet_23_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_23;
	static const unsigned long _tokenSet_24_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_24;
	static const unsigned long _tokenSet_25_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_25;
	static const unsigned long _tokenSet_26_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_26;
	static const unsigned long _tokenSet_27_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_27;
	static const unsigned long _tokenSet_28_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_28;
	static const unsigned long _tokenSet_29_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_29;
	static const unsigned long _tokenSet_30_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_30;
	static const unsigned long _tokenSet_31_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_31;
	static const unsigned long _tokenSet_32_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_32;
	static const unsigned long _tokenSet_33_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_33;
	static const unsigned long _tokenSet_34_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_34;
	static const unsigned long _tokenSet_35_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_35;
	static const unsigned long _tokenSet_36_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_36;
};

#endif /*INC_modelica_parser_hpp_*/
