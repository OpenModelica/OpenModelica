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
/* $ANTLR 2.7.6 (2005-12-22): "walker.g" -> "modelica_tree_parser.hpp"$ */
#include <antlr/TreeParser.hpp>

#line 15 "walker.g"

/************************************************************************
File: walker.g
Created By: Adrian Pop adrpo@ida.liu.se
Date:       2003-06-10
Revised on 2003-10-26 17:58:42 (write the definition even if has no childs)
Comments: we walk on the modelica tree, buil a XML DOM tree and serialize
************************************************************************/

  #define null 0

  extern "C"
  {
    #include <stdio.h>
  }

  #include <cstdlib>
  #include <iostream>
  #include <deque>
  #include <string>

#ifndef __MODELICAXML_H_
#include "ModelicaXML.h"
#endif

#include "MyAST.h"

typedef ANTLR_USE_NAMESPACE(antlr)ASTRefCount<MyAST> RefMyAST;


#line 54 "modelica_tree_parser.hpp"
class CUSTOM_API modelica_tree_parser : public ANTLR_USE_NAMESPACE(antlr)TreeParser, public modelica_tree_parserTokenTypes
{
#line 74 "walker.g"


	/* some xml helpers declarations */
	DOMDocument* pModelicaXMLDoc;
	DOMElement* pRootElementModelicaXML;
	char stmp[500];


    char* itoa( int value, char* buffer, int radix )
    {
      /*
      char* x = (char*)malloc(sizeof(char)*21);
      */
      sprintf(buffer, "%d", value);
      return buffer;
    }

    typedef std::deque<DOMElement*> l_stack;
    typedef std::string mstring;
	enum anno {UNSPECIFIED, INSIDE_EXTERNAL, INSIDE_ELEMENT, INSIDE_EQUATION, INSIDE_ALGORITHM, INSIDE_COMMENT};

    const XMLCh* str2xml(RefMyAST node)
    {
		return XMLString::transcode(node->getText().c_str());
    }

    DOMElement* stack2DOMNode(l_stack& s, mstring name)
    {
		DOMElement *pHoldingNode = pModelicaXMLDoc->createElement(X(name.c_str()));
		std::deque<DOMElement*>::reverse_iterator itList;
		for (itList=s.rbegin(); itList!=s.rend(); ++itList)
		{
			pHoldingNode->appendChild((DOMElement*)*itList);
		}
        return pHoldingNode;
    }

    DOMElement* appendKids(l_stack& s, DOMElement* pParentNode)
    {
		std::deque<DOMElement*>::reverse_iterator itList;
		for (itList=s.rbegin(); itList!=s.rend(); ++itList)
		{
		  pParentNode->appendChild((DOMElement*)*itList);
		}
        return pParentNode;
    }

    DOMElement* appendKidsFromStack(l_stack* s, DOMElement* pParentNode)
    {
		std::deque<DOMElement*>::reverse_iterator itList;
		for (itList=s->rbegin(); itList!=s->rend(); ++itList)
		{
		  pParentNode->appendChild((DOMElement*)*itList);
		}
		delete s;
        return pParentNode;
    }

	void setAttributes(DOMElement *pNodeTo, DOMElement *pNodeFrom)
	{
		DOMNamedNodeMap *pAttributes = pNodeFrom->getAttributes();
		for (XMLSize_t i=0; i < pAttributes->getLength(); i++)
		{
			DOMAttr *z = (DOMAttr*)pAttributes->item(i);
			pNodeTo->setAttribute(z->getName(), z->getValue());
		}
	}

    struct type_prefix_t
    {
        type_prefix_t():flow(0), variability(0),direction(0){}
		DOMElement* flow;
        DOMElement* variability;
        DOMElement* direction;
    };

    struct class_specifier_t
    {
        class_specifier_t():string_comment(0), composition(0), enumeration(0), derived(0), overload(0), pder(0), classExtends(0){}
		DOMElement* string_comment;
		DOMElement *composition;
        DOMElement* derived;
        DOMElement* enumeration;
		DOMElement* overload;
		DOMElement* pder;
		DOMElement* classExtends;
    };

	DOMAttr* getAttributeNode(DOMElement* pNode, mstring stdstr)
	{
		return ((DOMElement*)pNode)->getAttributeNode(X(stdstr.c_str()));
	}


	void setVisibility(int iSwitch, DOMElement* pNode)
	{
		if (iSwitch == 1) pNode->setAttribute(X("visibility"), X("public"));
		else if (iSwitch == 2) pNode->setAttribute(X("visibility"), X("protected"));
		else { /* error, shouldn't happen */ }
	}
#line 58 "modelica_tree_parser.hpp"
public:
	modelica_tree_parser();
	static void initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory );
	int getNumTokens() const
	{
		return modelica_tree_parser::NUM_TOKENS;
	}
	const char* getTokenName( int type ) const
	{
		if( type > getNumTokens() ) return 0;
		return modelica_tree_parser::tokenNames[type];
	}
	const char* const* getTokenNames() const
	{
		return modelica_tree_parser::tokenNames;
	}
	public: DOMElement * stored_definition(RefMyAST _t,
		mstring moFilename, DOMDocument* pModelicaXMLDocParam
	);
	public: DOMElement*  within_clause(RefMyAST _t,
		DOMElement* parent
	);
	public: DOMElement*  class_definition(RefMyAST _t,
		bool final, DOMElement *definitionElement
	);
	public: void * name_path(RefMyAST _t);
	public: void class_restriction(RefMyAST _t);
	public: void class_specifier(RefMyAST _t,
		class_specifier_t& sClassSpec
	);
	public: DOMElement*  string_comment(RefMyAST _t);
	public: DOMElement*  composition(RefMyAST _t,
		DOMElement* definition
	);
	public: DOMElement*  derived_class(RefMyAST _t);
	public: DOMElement*  enumeration(RefMyAST _t);
	public: DOMElement*  overloading(RefMyAST _t);
	public: DOMElement*  pder(RefMyAST _t);
	public: void * class_modification(RefMyAST _t);
	public: DOMElement*  ident_list(RefMyAST _t);
	public: void type_prefix(RefMyAST _t,
		DOMElement* parent
	);
	public: DOMElement*  array_subscripts(RefMyAST _t,
		int kind
	);
	public: DOMElement*  comment(RefMyAST _t);
	public: DOMElement*  enumeration_literal(RefMyAST _t);
	public: DOMElement*  element_list(RefMyAST _t,
		int iSwitch, DOMElement*definition
	);
	public: DOMElement*  public_element_list(RefMyAST _t,
		DOMElement* definition
	);
	public: DOMElement*  protected_element_list(RefMyAST _t,
		DOMElement* definition
	);
	public: DOMElement*  equation_clause(RefMyAST _t,
		DOMElement *definition
	);
	public: DOMElement*  algorithm_clause(RefMyAST _t,
		DOMElement* definition
	);
	public: DOMElement*  external_function_call(RefMyAST _t,
		DOMElement *pExternalFunctionCall
	);
	public: DOMElement*  annotation(RefMyAST _t,
		int iSwitch, DOMElement *parent, enum anno awhere
	);
	public: DOMElement*  expression_list(RefMyAST _t);
	public: DOMElement*  component_reference(RefMyAST _t);
	public: DOMElement*  element(RefMyAST _t,
		int iSwitch, DOMElement *parent
	);
	public: DOMElement*  import_clause(RefMyAST _t,
		int iSwitch, DOMElement *parent
	);
	public: DOMElement*  extends_clause(RefMyAST _t,
		int iSwitch, DOMElement* parent
	);
	public: DOMElement*  component_clause(RefMyAST _t,
		DOMElement* parent, DOMElement* attributes
	);
	public: DOMElement*  constraining_clause(RefMyAST _t);
	public: DOMElement*  explicit_import_name(RefMyAST _t);
	public: DOMElement*  implicit_import_name(RefMyAST _t);
	public: void*  type_specifier(RefMyAST _t);
	public: DOMElement*  component_list(RefMyAST _t,
		DOMElement* parent, DOMElement *attributes, DOMElement* type_array
	);
	public: DOMElement*  component_declaration(RefMyAST _t,
		DOMElement* parent, DOMElement *attributes, DOMElement *type_array
	);
	public: DOMElement*  conditional_attribute(RefMyAST _t);
	public: DOMElement*  expression(RefMyAST _t);
	public: DOMElement*  declaration(RefMyAST _t,
		DOMElement* parent, DOMElement* type_array
	);
	public: DOMElement*  modification(RefMyAST _t);
	public: void * argument_list(RefMyAST _t);
	public: DOMElement*  argument(RefMyAST _t);
	public: DOMElement*  element_modification(RefMyAST _t);
	public: DOMElement*  element_redeclaration(RefMyAST _t);
	public: DOMElement*  component_clause1(RefMyAST _t,
		DOMElement *parent
	);
	public: DOMElement*  equation(RefMyAST _t,
		DOMElement* definition
	);
	public: DOMElement*  algorithm(RefMyAST _t,
		DOMElement *definition
	);
	public: DOMElement*  equality_equation(RefMyAST _t);
	public: DOMElement*  conditional_equation_e(RefMyAST _t);
	public: DOMElement*  for_clause_e(RefMyAST _t);
	public: DOMElement*  when_clause_e(RefMyAST _t);
	public: DOMElement*  connect_clause(RefMyAST _t);
	public: DOMElement*  equation_funcall(RefMyAST _t);
	public: DOMElement*  function_call(RefMyAST _t);
	public: DOMElement*  tuple_expression_list(RefMyAST _t);
	public: DOMElement*  algorithm_function_call(RefMyAST _t);
	public: DOMElement*  conditional_equation_a(RefMyAST _t);
	public: DOMElement*  for_clause_a(RefMyAST _t);
	public: DOMElement*  while_clause(RefMyAST _t);
	public: DOMElement*  when_clause_a(RefMyAST _t);
	public: DOMElement*  simple_expression(RefMyAST _t);
	public: DOMElement*  equation_list(RefMyAST _t,
		DOMElement* pEquationList
	);
	public: DOMElement*  equation_elseif(RefMyAST _t);
	public: DOMElement*  algorithm_list(RefMyAST _t,
		DOMElement*  pAlgorithmList
	);
	public: DOMElement*  algorithm_elseif(RefMyAST _t);
	public: DOMElement*  for_indices(RefMyAST _t);
	public: DOMElement*  for_iterator(RefMyAST _t);
	public: DOMElement*  else_when_e(RefMyAST _t);
	public: DOMElement*  else_when_a(RefMyAST _t);
	public: DOMElement*  if_expression(RefMyAST _t);
	public: DOMElement*  code_expression(RefMyAST _t);
	public: DOMElement*  elseif_expression(RefMyAST _t);
	public: DOMElement*  logical_expression(RefMyAST _t);
	public: DOMElement*  logical_term(RefMyAST _t);
	public: DOMElement*  logical_factor(RefMyAST _t);
	public: DOMElement*  relation(RefMyAST _t);
	public: DOMElement*  arithmetic_expression(RefMyAST _t);
	public: DOMElement*  unary_arithmetic_expression(RefMyAST _t);
	public: DOMElement*  term(RefMyAST _t);
	public: DOMElement*  factor(RefMyAST _t);
	public: DOMElement*  primary(RefMyAST _t);
	public: DOMElement*  component_reference__function_call(RefMyAST _t);
	public: DOMElement*  function_arguments(RefMyAST _t);
	public: DOMElement*  expression_list2(RefMyAST _t,
		DOMElement *parent
	);
	public: DOMElement*  named_arguments(RefMyAST _t,
		DOMElement *parent
	);
	public: DOMElement*  named_argument(RefMyAST _t);
	public: DOMElement*  subscript(RefMyAST _t,
		DOMElement* parent
	);
	public: DOMElement*  string_concatenation(RefMyAST _t);
	public: DOMElement*  interactive_stmt(RefMyAST _t);
public:
	ANTLR_USE_NAMESPACE(antlr)RefAST getAST()
	{
		return ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST);
	}

protected:
	RefMyAST returnAST;
	RefMyAST _retTree;
private:
	static const char* tokenNames[];
#ifndef NO_STATIC_CONSTS
	static const int NUM_TOKENS = 151;
#else
	enum {
		NUM_TOKENS = 151
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
