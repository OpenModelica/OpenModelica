#ifndef INC_modelica_tree_parser_hpp_
#define INC_modelica_tree_parser_hpp_

#line 2 "walker.g"

// adrpo disabling warnings
#pragma warning( disable : 4267)  // Disable warning messages C4267 
// disable: 'initializing' : conversion from 'size_t' to 'int', possible loss of data

#pragma warning( disable : 4231)  // Disable warning messages C4231 
// disable: nonstandard extension used : 'extern' before template explicit instantiation

#pragma warning( disable : 4101)  // Disable warning messages C4101 
// disable: warning C4101: 'pe' : unreferenced local variable

#line 17 "modelica_tree_parser.hpp"
#include <antlr/config.hpp>
#include "modelica_tree_parserTokenTypes.hpp"
/* $ANTLR 2.7.2: "walker.g" -> "modelica_tree_parser.hpp"$ */
#include <antlr/TreeParser.hpp>

#line 15 "walker.g"

/************************************************************************
File: walker.g
Created By: Adrian Pop adrpo@ida.liu.se 
Date:       2003-06-10
Revised on 2003-10-26 17:58:42
Comments: we walk on the modelica tree, buil a XML DOM tree and serialize
************************************************************************/

  #define null 0

  extern "C" 
  {
    #include <stdio.h>
  }
    
  #include <cstdlib>
  #include <iostream>
  #include <stack>
  #include <string>

#ifndef __MODELICAXML_H_
#include "modelicaxml.h"
#endif


#line 50 "modelica_tree_parser.hpp"
class modelica_tree_parser : public ANTLR_USE_NAMESPACE(antlr)TreeParser, public modelica_tree_parserTokenTypes
{
#line 69 "walker.g"


	/* some xml helpers declarations */
    DOMDocument* pModelicaXMLDoc;
    DOMElement* pRootElementModelica;
	DOMElement* pRootElementModelicaXML;
    DOMImplementation* pDOMImpl;
	DOMElement *pColon;
	DOMElement *pSemiColon;

    typedef std::string mstring;
    
    const XMLCh* str2xml(antlr::RefAST &node)
    {
		return XMLString::transcode(node->getText().c_str());
    }

	/*
    DOMNode* make_inner_outer(antlr::RefAST &i,antlr::RefAST &o)
    {
		DOMElement *innerouter = pModelicaXMLDoc->createElement(X("innerouter"));
		if (i!=NULL) 
		{
			innerouter->setAttribute(X("innerouter"), X("inner")); 
		} 
		else 
			if (o != NULL) 
			{
				innerouter->setAttribute(X("innerouter"), X("outer")); 
			} 
			else 
			{
				innerouter->setAttribute(X("innerouter"), X("unspecified")); 
			}
		return innerouter;
	}
	*/

    /*
    int str2int(mstring const& str)
    {
		return atoi(str.c_str());
    }
    
    double str2double(std::string const& str)
    {
        return atof(str.c_str());
    }
	*/
    
    typedef std::stack<DOMNode*> l_stack;

    DOMNode* stack2DOMNode(l_stack& s, mstring name)
    {
		// @HACK,@FIXME reverse the stack (better use a fifo) 
		DOMElement *pHoldingNode = pModelicaXMLDoc->createElement(X(name.c_str()));
		l_stack s_reverse;
        while (!s.empty())
        {            
			s_reverse.push(s.top());
			s.pop();
        }   
        while (!s_reverse.empty())
        {
			pHoldingNode->appendChild((DOMElement*)s_reverse.top());
            s_reverse.pop();
        }   
        return pHoldingNode;
    }

    
    DOMNode* appendKids(l_stack& s, DOMNode* pParentNode)
    {
		// @HACK,@FIXME reverse the stack (better use a fifo) 
		l_stack s_reverse;
        while (!s.empty())
        {            
			s_reverse.push(s.top());
			s.pop();
        }   
        while (!s_reverse.empty())
        {
			pParentNode->appendChild((DOMElement*)s_reverse.top());
            s_reverse.pop();
        }   
        return pParentNode;
    }
    
    struct type_prefix_t
    {
        type_prefix_t():flow(0), variability(0),direction(0){}
		DOMNode* flow;
        DOMNode* variability;
        DOMNode* direction;
    };

    struct class_specifier_t
    {
        class_specifier_t():string_comment(0), composition(0), enumeration(0), derived(0), overload(0){}
		DOMNode* string_comment;
		DOMNode *composition;
        DOMNode* derived;
        DOMNode* enumeration;
		DOMNode* overload;
    };

	DOMAttr* getAttributeNode(DOMNode* pNode, mstring stdstr)
	{
		return ((DOMElement*)pNode)->getAttributeNode(X(stdstr.c_str()));
	}

	void appendKids(DOMNode* pNode, DOMNodeList* pNodeList)
	{
		XMLSize_t i;
		for (i=0; i < pNodeList->getLength(); i++) 
			((DOMElement*)pNode)->appendChild(pNodeList->item(i));
	}
#line 54 "modelica_tree_parser.hpp"
public:
	modelica_tree_parser();
	void initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory );
	int getNumTokens() const
	{
		return modelica_tree_parser::NUM_TOKENS;
	}
	const char* getTokenName( int type ) const
	{
		if( type > getNumTokens() ) return 0;
		return modelica_tree_parser::tokenNames[type];
	}
	public: DOMNode * stored_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		mstring filename
	);
	public: DOMNode*  within_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  class_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		bool final
	);
	public: DOMNode*  name_path(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void class_restriction(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void class_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		class_specifier_t& sClassSpec
	);
	public: DOMNode*  string_comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  composition(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  derived_class(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  enumeration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  overloading(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: void type_prefix(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		type_prefix_t& prefix
	);
	public: DOMNode*  array_subscripts(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  class_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  enumeration_literal(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
		int iSwitch
	);
	public: DOMNode*  public_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  protected_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  equation_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  algorithm_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  external_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  annotation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  component_reference(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  element(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  import_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  extends_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  component_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  constraining_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  explicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  implicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  type_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  component_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  component_declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  argument_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  element_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  element_redeclaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  component_clause1(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  algorithm(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  equality_equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  conditional_equation_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  for_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  when_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  connect_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  equation_funcall(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  algorithm_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  conditional_equation_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  for_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  while_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  when_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  simple_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  equation_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  equation_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  algorithm_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  algorithm_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  for_indices(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  else_when_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  else_when_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  if_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  code_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  elseif_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  logical_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  logical_term(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  logical_factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  relation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  unary_arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  term(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  primary(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  component_reference__function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  tuple_expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  function_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  named_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  named_argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  subscript(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  string_concatenation(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
	public: DOMNode*  interactive_stmt(ANTLR_USE_NAMESPACE(antlr)RefAST _t);
private:
	static const char* tokenNames[];
#ifndef NO_STATIC_CONSTS
	static const int NUM_TOKENS = 134;
#else
	enum {
		NUM_TOKENS = 134
	};
#endif
	
	static const unsigned long _tokenSet_0_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_0;
	static const unsigned long _tokenSet_1_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_1;
	static const unsigned long _tokenSet_2_data_[];
	static const ANTLR_USE_NAMESPACE(antlr)BitSet _tokenSet_2;
};

#endif /*INC_modelica_tree_parser_hpp_*/
