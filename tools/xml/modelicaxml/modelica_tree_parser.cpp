/* $ANTLR 2.7.7 (2006-11-01): "walker.g" -> "modelica_tree_parser.cpp"$ */
#include "modelica_tree_parser.hpp"
#include <antlr/Token.hpp>
#include <antlr/AST.hpp>
#include <antlr/NoViableAltException.hpp>
#include <antlr/MismatchedTokenException.hpp>
#include <antlr/SemanticException.hpp>
#include <antlr/BitSet.hpp>
#line 52 "walker.g"


#line 13 "modelica_tree_parser.cpp"
#line 1 "walker.g"
#line 15 "modelica_tree_parser.cpp"
modelica_tree_parser::modelica_tree_parser()
	: ANTLR_USE_NAMESPACE(antlr)TreeParser() {
}

DOMElement * modelica_tree_parser::stored_definition(RefMyAST _t,
	mstring moFilename, DOMDocument* pModelicaXMLDocParam
) {
#line 184 "walker.g"
	DOMElement *ast;
#line 25 "modelica_tree_parser.cpp"
	RefMyAST stored_definition_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST stored_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 184 "walker.g"
	
	DOMElement *within = 0;
	l_stack el_stack;
	pModelicaXMLDoc = pModelicaXMLDocParam;
	
		pRootElementModelicaXML = pModelicaXMLDoc->createElement(X("modelicaxml"));
		// set the location of the .mo file we're representing in XML
		pRootElementModelicaXML->setAttribute(X("file"), X(moFilename.c_str()));
	
		DOMElement* pDefinitionElement = 0;
	
#line 44 "modelica_tree_parser.cpp"
	
	RefMyAST __t2 = _t;
	RefMyAST tmp1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp1_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp1_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp1_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp1_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST2 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STORED_DEFINITION);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case WITHIN:
	{
		pRootElementModelicaXML=within_clause(_t,pRootElementModelicaXML);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case FINAL:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == FINAL || _t->getType() == CLASS_DEFINITION)) {
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case FINAL:
			{
				f = _t;
				RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
				match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FINAL);
				_t = _t->getNextSibling();
				break;
			}
			case CLASS_DEFINITION:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
#line 199 "walker.g"
			pDefinitionElement = pModelicaXMLDoc->createElement(X("definition"));
#line 111 "modelica_tree_parser.cpp"
			pDefinitionElement=class_definition(_t,f != NULL, pDefinitionElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 201 "walker.g"
			
			if (pDefinitionElement /* adrpo modified 2004-10-27 && pDefinitionElement->hasChildNodes()*/)
			{
			el_stack.push_back(pDefinitionElement);
			}
			
#line 122 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop6;
		}
		
	}
	_loop6:;
	} // ( ... )*
	currentAST = __currentAST2;
	_t = __t2;
	_t = _t->getNextSibling();
#line 209 "walker.g"
	
				//pRootElementModelicaXML = within;
				pRootElementModelicaXML = (DOMElement*)appendKids(el_stack, pRootElementModelicaXML);
	ast = pRootElementModelicaXML;
	
#line 140 "modelica_tree_parser.cpp"
	stored_definition_AST = RefMyAST(currentAST.root);
	returnAST = stored_definition_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::within_clause(RefMyAST _t,
	DOMElement* parent
) {
#line 219 "walker.g"
	DOMElement* ast;
#line 152 "modelica_tree_parser.cpp"
	RefMyAST within_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST within_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 219 "walker.g"
	
		void* pNamePath = 0;
	
#line 161 "modelica_tree_parser.cpp"
	
	RefMyAST __t8 = _t;
	RefMyAST tmp2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp2_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp2_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST8 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WITHIN);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	{
		pNamePath=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST8;
	_t = __t8;
	_t = _t->getNextSibling();
#line 224 "walker.g"
	
			    if (pNamePath) parent->setAttribute(X("within"), X(((mstring *)pNamePath)->c_str()));
				ast = parent;
	
#line 204 "modelica_tree_parser.cpp"
	within_clause_AST = RefMyAST(currentAST.root);
	returnAST = within_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::class_definition(RefMyAST _t,
	bool final, DOMElement *definitionElement
) {
#line 233 "walker.g"
	DOMElement* ast;
#line 216 "modelica_tree_parser.cpp"
	RefMyAST class_definition_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cd = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cd_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ex = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ex_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 233 "walker.g"
	
	class_specifier_t sClassSpec;
	sClassSpec.composition = definitionElement;
	
#line 238 "modelica_tree_parser.cpp"
	
	RefMyAST __t11 = _t;
	cd = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST cd_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	cd_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(cd));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(cd_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST11 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CLASS_DEFINITION);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ENCAPSULATED:
	{
		e = _t;
		RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ENCAPSULATED);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case EXPANDABLE:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case PARTIAL:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case PARTIAL:
	{
		p = _t;
		RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PARTIAL);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case EXPANDABLE:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXPANDABLE:
	{
		ex = _t;
		RefMyAST ex_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		ex_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ex));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ex_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPANDABLE);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
	case FUNCTION:
	case MODEL:
	case PACKAGE:
	case RECORD:
	case TYPE:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	r = (_t == ASTNULL) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	class_restriction(_t);
	_t = _retTree;
	r_AST = returnAST;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		i = _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ALGORITHM:
	case ANNOTATION:
	case EQUATION:
	case EXTENDS:
	case EXTERNAL:
	case IMPORT:
	case PROTECTED:
	case PUBLIC:
	case CONSTRAINEDBY:
	case EQUALS:
	case CLASS_EXTENDS:
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	case STRING_COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	class_specifier(_t,sClassSpec);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 244 "walker.g"
	definitionElement=sClassSpec.composition;
#line 398 "modelica_tree_parser.cpp"
	currentAST = __currentAST11;
	_t = __t11;
	_t = _t->getNextSibling();
#line 246 "walker.g"
	
	definitionElement->setAttribute(
					X("ident"),
					X(i?i->getText().c_str():"_EXTENDED_"));
				definitionElement->setAttribute(X("sline"), X(itoa(cd->getLine(),stmp,10)));
				definitionElement->setAttribute(X("scolumn"), X(itoa(cd->getColumn(),stmp,10)));
	
				if (p != 0) definitionElement->setAttribute(X("partial"), X("true"));
				if (final) definitionElement->setAttribute(X("final"), X("true"));
				if (e != 0) definitionElement->setAttribute(X("encapsulated"), X("true"));
				if (ex) definitionElement->setAttribute(X("restriction"), X("expandable"));
				if (r) definitionElement->setAttribute(X("restriction"), str2xml(r));
				if (sClassSpec.string_comment)
				{
					definitionElement->appendChild(sClassSpec.string_comment);
				}
				if (sClassSpec.composition)
				{
					// nothing to do, already done at the lower level.
					//definitionElement->appendChild(sClassSpec.composition);
					//appendKids(definitionElement, sClassSpec.composition);
				}
				if (sClassSpec.derived)
				{
					definitionElement->appendChild(sClassSpec.derived);
				}
				if (sClassSpec.enumeration)
				{
					definitionElement->appendChild(sClassSpec.enumeration);
				}
				if (sClassSpec.overload)
				{
					definitionElement->appendChild(sClassSpec.overload);
				}
				if (sClassSpec.pder)
				{
					definitionElement->appendChild(sClassSpec.pder);
				}
				if (sClassSpec.classExtends)
				{
					definitionElement->appendChild(sClassSpec.classExtends);
				}
				ast = definitionElement;
	
#line 447 "modelica_tree_parser.cpp"
	class_definition_AST = RefMyAST(currentAST.root);
	returnAST = class_definition_AST;
	_retTree = _t;
	return ast;
}

void * modelica_tree_parser::name_path(RefMyAST _t) {
#line 2431 "walker.g"
	void *ast;
#line 457 "modelica_tree_parser.cpp"
	RefMyAST name_path_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST name_path_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST d = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST d_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2431 "walker.g"
	
		void *s1=0;
		void *s2=0;
	
#line 473 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		i = _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
		_t = _t->getNextSibling();
#line 2438 "walker.g"
		
					ast = (void*)new mstring(i->getText());
				
#line 490 "modelica_tree_parser.cpp"
		name_path_AST = RefMyAST(currentAST.root);
		break;
	}
	case DOT:
	{
		RefMyAST __t339 = _t;
		d = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST d_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		d_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(d));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(d_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST339 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DOT);
		_t = _t->getFirstChild();
		i2 = _t;
		RefMyAST i2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i2));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
		_t = _t->getNextSibling();
		s2=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST339;
		_t = __t339;
		_t = _t->getNextSibling();
#line 2442 "walker.g"
		
					s1 = (void*)new mstring(i2->getText());
					ast = (void*)new mstring(mstring(((mstring*)s1)->c_str())+mstring(".")+mstring(((mstring*)s2)->c_str()));
				
#line 523 "modelica_tree_parser.cpp"
		name_path_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = name_path_AST;
	_retTree = _t;
	return ast;
}

void modelica_tree_parser::class_restriction(RefMyAST _t) {
	RefMyAST class_restriction_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_restriction_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS:
	{
		RefMyAST tmp3_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp3_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp3_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp3_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp3_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CLASS);
		_t = _t->getNextSibling();
		break;
	}
	case MODEL:
	{
		RefMyAST tmp4_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp4_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp4_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp4_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp4_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),MODEL);
		_t = _t->getNextSibling();
		break;
	}
	case RECORD:
	{
		RefMyAST tmp5_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp5_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp5_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp5_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp5_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),RECORD);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	{
		RefMyAST tmp6_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp6_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp6_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp6_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp6_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),BLOCK);
		_t = _t->getNextSibling();
		break;
	}
	case CONNECTOR:
	{
		RefMyAST tmp7_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp7_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp7_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp7_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp7_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CONNECTOR);
		_t = _t->getNextSibling();
		break;
	}
	case TYPE:
	{
		RefMyAST tmp8_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp8_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp8_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp8_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp8_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),TYPE);
		_t = _t->getNextSibling();
		break;
	}
	case PACKAGE:
	{
		RefMyAST tmp9_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp9_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp9_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp9_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PACKAGE);
		_t = _t->getNextSibling();
		break;
	}
	case FUNCTION:
	{
		RefMyAST tmp10_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp10_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp10_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp10_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FUNCTION);
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	class_restriction_AST = RefMyAST(currentAST.root);
	returnAST = class_restriction_AST;
	_retTree = _t;
}

void modelica_tree_parser::class_specifier(RefMyAST _t,
	class_specifier_t& sClassSpec
) {
	RefMyAST class_specifier_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_specifier_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 313 "walker.g"
	
		DOMElement *comp = 0;
		DOMElement *cmt = 0;
		DOMElement *d = 0;
		DOMElement *e = 0;
		DOMElement *o = 0;
		DOMElement *p = 0;
		void *cmod = 0;
	
#line 665 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case 3:
	case ALGORITHM:
	case ANNOTATION:
	case EQUATION:
	case EXTENDS:
	case EXTERNAL:
	case IMPORT:
	case PROTECTED:
	case PUBLIC:
	case CONSTRAINEDBY:
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	case STRING_COMMENT:
	{
		{
		{
		cmt=string_comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		comp=composition(_t,sClassSpec.composition);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 326 "walker.g"
		
		if (cmt) sClassSpec.string_comment = cmt;
						sClassSpec.composition = comp;
					
#line 700 "modelica_tree_parser.cpp"
		}
		class_specifier_AST = RefMyAST(currentAST.root);
		break;
	}
	case EQUALS:
	{
		RefMyAST __t22 = _t;
		RefMyAST tmp11_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp11_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp11_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp11_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp11_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST22 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case STREAM:
		case IDENT:
		{
			d=derived_class(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case ENUMERATION:
		{
			e=enumeration(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case OVERLOAD:
		{
			o=overloading(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case DER:
		{
			p=pder(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST22;
		_t = __t22;
		_t = _t->getNextSibling();
#line 337 "walker.g"
		
					sClassSpec.derived = d;
					sClassSpec.enumeration = e;
					sClassSpec.overload = o;
					sClassSpec.pder = p;
				
#line 774 "modelica_tree_parser.cpp"
		class_specifier_AST = RefMyAST(currentAST.root);
		break;
	}
	case CLASS_EXTENDS:
	{
		RefMyAST __t24 = _t;
		RefMyAST tmp12_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp12_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp12_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp12_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp12_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST24 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CLASS_EXTENDS);
		_t = _t->getFirstChild();
		i = _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
		_t = _t->getNextSibling();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_MODIFICATION:
		{
			cmod=class_modification(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		case ALGORITHM:
		case ANNOTATION:
		case EQUATION:
		case EXTENDS:
		case EXTERNAL:
		case IMPORT:
		case PROTECTED:
		case PUBLIC:
		case CONSTRAINEDBY:
		case DECLARATION:
		case DEFINITION:
		case INITIAL_EQUATION:
		case INITIAL_ALGORITHM:
		case STRING_COMMENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 344 "walker.g"
		
								  sClassSpec.classExtends = pModelicaXMLDoc->createElement(X("extended_class"));
								  if (cmod) sClassSpec.classExtends =
									  (DOMElement*)appendKidsFromStack((l_stack *)cmod, sClassSpec.classExtends);
								
#line 838 "modelica_tree_parser.cpp"
		cmt=string_comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		comp=composition(_t,sClassSpec.classExtends);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST24;
		_t = __t24;
		_t = _t->getNextSibling();
#line 350 "walker.g"
		
					sClassSpec.classExtends = pModelicaXMLDoc->createElement(X("extended_class"));
		if (cmt) sClassSpec.classExtends->appendChild(cmt);
		sClassSpec.classExtends->setAttribute(
						X("ident"),
						X(i->getText().c_str()));
		
#line 856 "modelica_tree_parser.cpp"
		class_specifier_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = class_specifier_AST;
	_retTree = _t;
}

DOMElement*  modelica_tree_parser::string_comment(RefMyAST _t) {
#line 2683 "walker.g"
	DOMElement* ast;
#line 872 "modelica_tree_parser.cpp"
	RefMyAST string_comment_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST string_comment_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sc = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sc_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING_COMMENT:
	{
#line 2684 "walker.g"
		
			  DOMElement* cmt=0;
			  ast = 0;
			
#line 890 "modelica_tree_parser.cpp"
		RefMyAST __t386 = _t;
		sc = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sc_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sc_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sc));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sc_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST386 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STRING_COMMENT);
		_t = _t->getFirstChild();
		cmt=string_concatenation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST386;
		_t = __t386;
		_t = _t->getNextSibling();
#line 2689 "walker.g"
		
					DOMElement *pStringComment = pModelicaXMLDoc->createElement(X("string_comment"));
		
					pStringComment->setAttribute(X("sline"), X(itoa(sc->getLine(),stmp,10)));
					pStringComment->setAttribute(X("scolumn"), X(itoa(sc->getColumn(),stmp,10)));
		
					pStringComment->appendChild(cmt);
					ast = pStringComment;
				
#line 917 "modelica_tree_parser.cpp"
		string_comment_AST = RefMyAST(currentAST.root);
		break;
	}
	case 3:
	case ALGORITHM:
	case ANNOTATION:
	case EQUATION:
	case EXTENDS:
	case EXTERNAL:
	case IMPORT:
	case PROTECTED:
	case PUBLIC:
	case CONSTRAINEDBY:
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	{
#line 2699 "walker.g"
		
					ast = 0;
				
#line 940 "modelica_tree_parser.cpp"
		string_comment_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = string_comment_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::composition(RefMyAST _t,
	DOMElement* definition
) {
#line 526 "walker.g"
	DOMElement* ast;
#line 959 "modelica_tree_parser.cpp"
	RefMyAST composition_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST composition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 526 "walker.g"
	
	DOMElement* el = 0;
	l_stack el_stack;
	DOMElement*  ann;
	DOMElement* pExternalFunctionCall = 0;
	
#line 971 "modelica_tree_parser.cpp"
	
	definition=element_list(_t,1 /* public */, definition);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_0.member(_t->getType()))) {
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case PUBLIC:
			{
				definition=public_element_list(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case PROTECTED:
			{
				definition=protected_element_list(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case EQUATION:
			case INITIAL_EQUATION:
			{
				definition=equation_clause(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case ALGORITHM:
			case INITIAL_ALGORITHM:
			{
				definition=algorithm_clause(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
		}
		else {
			goto _loop56;
		}
		
	}
	_loop56:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL:
	{
		RefMyAST __t58 = _t;
		RefMyAST tmp13_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp13_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp13_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp13_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp13_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST58 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXTERNAL);
		_t = _t->getFirstChild();
#line 543 "walker.g"
		pExternalFunctionCall = pModelicaXMLDoc->createElement(X("external"));
#line 1048 "modelica_tree_parser.cpp"
		{
		pExternalFunctionCall=external_function_call(_t,pExternalFunctionCall);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case ANNOTATION:
		{
			pExternalFunctionCall=annotation(_t,0 /*none*/, pExternalFunctionCall, INSIDE_EXTERNAL);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		case EXTERNAL_ANNOTATION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			if ((_t->getType() == EXTERNAL_ANNOTATION)) {
#line 547 "walker.g"
				pExternalFunctionCall->appendChild(pModelicaXMLDoc->createElement(X("semicolon")));
#line 1083 "modelica_tree_parser.cpp"
				RefMyAST __t62 = _t;
				RefMyAST tmp14_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				RefMyAST tmp14_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				tmp14_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
				tmp14_AST_in = _t;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
				ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST62 = currentAST;
				currentAST.root = currentAST.child;
				currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXTERNAL_ANNOTATION);
				_t = _t->getFirstChild();
				pExternalFunctionCall=annotation(_t,0 /*none*/, pExternalFunctionCall, INSIDE_EXTERNAL);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				currentAST = __currentAST62;
				_t = __t62;
				_t = _t->getNextSibling();
			}
			else {
				goto _loop63;
			}
			
		}
		_loop63:;
		} // ( ... )*
		currentAST = __currentAST58;
		_t = __t58;
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 552 "walker.g"
	
				if (pExternalFunctionCall) definition->appendChild(pExternalFunctionCall);
	ast = definition;
	
#line 1129 "modelica_tree_parser.cpp"
	composition_AST = RefMyAST(currentAST.root);
	returnAST = composition_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::derived_class(RefMyAST _t) {
#line 402 "walker.g"
	DOMElement* ast;
#line 1139 "modelica_tree_parser.cpp"
	RefMyAST derived_class_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST derived_class_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 402 "walker.g"
	
		void* p = 0;
		DOMElement* as = 0;
		void *cmod = 0;
		DOMElement* cmt = 0;
		DOMElement* attr = 0;
		type_prefix_t pfx;
		DOMElement* pDerived = pModelicaXMLDoc->createElement(X("derived"));
	
#line 1154 "modelica_tree_parser.cpp"
	
	{
	type_prefix(_t,pDerived);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	p=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		as=array_subscripts(_t,0);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case CLASS_MODIFICATION:
	case COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		cmod=class_modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 418 "walker.g"
	
					if (p)               pDerived->setAttribute(X("type"), X(((mstring*)p)->c_str()));
					if (as)              pDerived->appendChild(as);
					if (cmod)            pDerived = (DOMElement*)appendKidsFromStack((l_stack *)cmod, pDerived);
					if (cmt)             pDerived->appendChild(cmt);
					ast = pDerived;
				
#line 1237 "modelica_tree_parser.cpp"
	}
	derived_class_AST = RefMyAST(currentAST.root);
	returnAST = derived_class_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::enumeration(RefMyAST _t) {
#line 431 "walker.g"
	DOMElement* ast;
#line 1248 "modelica_tree_parser.cpp"
	RefMyAST enumeration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST en = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST en_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 431 "walker.g"
	
		l_stack el_stack;
		DOMElement* el = 0;
		DOMElement* cmt = 0;
	
#line 1263 "modelica_tree_parser.cpp"
	
	RefMyAST __t39 = _t;
	en = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST en_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	en_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(en));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(en_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST39 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ENUMERATION);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ENUMERATION_LITERAL:
	{
		{
		el=enumeration_literal(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 440 "walker.g"
		el_stack.push_back(el);
#line 1287 "modelica_tree_parser.cpp"
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			if ((_t->getType() == ENUMERATION_LITERAL)) {
				el=enumeration_literal(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 443 "walker.g"
				el_stack.push_back(el);
#line 1298 "modelica_tree_parser.cpp"
			}
			else {
				goto _loop43;
			}
			
		}
		_loop43:;
		} // ( ... )*
		}
		break;
	}
	case COLON:
	{
		c = _t;
		RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),COLON);
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST39;
	_t = __t39;
	_t = _t->getNextSibling();
#line 451 "walker.g"
	
				DOMElement* pEnumeration = pModelicaXMLDoc->createElement(X("enumeration"));
				pEnumeration->setAttribute(X("sline"), X(itoa(en->getLine(),stmp,10)));
				pEnumeration->setAttribute(X("scolumn"), X(itoa(en->getColumn(),stmp,10)));
				if (c)
				{
					pEnumeration->setAttribute(X("colon"), X("true"));
				}
				else
				{
				pEnumeration = (DOMElement*)appendKids(el_stack, pEnumeration);
				}
				if (cmt) pEnumeration->appendChild(cmt);
				ast = pEnumeration;
			
#line 1366 "modelica_tree_parser.cpp"
	enumeration_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::overloading(RefMyAST _t) {
#line 494 "walker.g"
	DOMElement* ast;
#line 1376 "modelica_tree_parser.cpp"
	RefMyAST overloading_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST overloading_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ov = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ov_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 494 "walker.g"
	
		std::deque<void*> el_stack;
		void* el = 0;
		DOMElement* cmt = 0;
	
#line 1389 "modelica_tree_parser.cpp"
	
	RefMyAST __t49 = _t;
	ov = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST ov_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ov_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ov));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ov_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST49 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),OVERLOAD);
	_t = _t->getFirstChild();
	el=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 503 "walker.g"
	el_stack.push_back(el);
#line 1406 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == DOT || _t->getType() == IDENT)) {
			el=name_path(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 506 "walker.g"
			el_stack.push_back(el);
#line 1417 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop51;
		}
		
	}
	_loop51:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST49;
	_t = __t49;
	_t = _t->getNextSibling();
#line 511 "walker.g"
	
				DOMElement* pOverload = pModelicaXMLDoc->createElement(X("overload"));
				if (cmt) pOverload->appendChild(cmt);
	
				pOverload->setAttribute(X("sline"), X(itoa(ov->getLine(),stmp,10)));
				pOverload->setAttribute(X("scolumn"), X(itoa(ov->getColumn(),stmp,10)));
	
				ast = pOverload;
			
#line 1460 "modelica_tree_parser.cpp"
	overloading_AST = RefMyAST(currentAST.root);
	returnAST = overloading_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::pder(RefMyAST _t) {
#line 359 "walker.g"
	DOMElement* ast;
#line 1470 "modelica_tree_parser.cpp"
	RefMyAST pder_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST pder_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 359 "walker.g"
	
	void* func=0;
	DOMElement* var_lst=0;
	
#line 1480 "modelica_tree_parser.cpp"
	
	RefMyAST __t27 = _t;
	RefMyAST tmp15_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp15_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp15_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp15_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp15_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST27 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DER);
	_t = _t->getFirstChild();
	func=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	var_lst=ident_list(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST27;
	_t = __t27;
	_t = _t->getNextSibling();
#line 365 "walker.g"
	
				ast = pModelicaXMLDoc->createElement(X("pder"));
				if (func) ast->setAttribute(X("type"), X(((mstring*)func)->c_str()));
				ast->appendChild(var_lst);
	
#line 1508 "modelica_tree_parser.cpp"
	pder_AST = RefMyAST(currentAST.root);
	returnAST = pder_AST;
	_retTree = _t;
	return ast;
}

void * modelica_tree_parser::class_modification(RefMyAST _t) {
#line 1068 "walker.g"
	void *stack;
#line 1518 "modelica_tree_parser.cpp"
	RefMyAST class_modification_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1068 "walker.g"
	
		stack = 0;
	
#line 1527 "modelica_tree_parser.cpp"
	
	RefMyAST __t145 = _t;
	RefMyAST tmp16_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp16_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp16_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp16_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp16_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST145 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CLASS_MODIFICATION);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ARGUMENT_LIST:
	{
		stack=argument_list(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST145;
	_t = __t145;
	_t = _t->getNextSibling();
	class_modification_AST = RefMyAST(currentAST.root);
	returnAST = class_modification_AST;
	_retTree = _t;
	return stack;
}

DOMElement*  modelica_tree_parser::ident_list(RefMyAST _t) {
#line 372 "walker.g"
	DOMElement* ast;
#line 1573 "modelica_tree_parser.cpp"
	RefMyAST ident_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST ident_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 372 "walker.g"
	
	l_stack el_stack;
		DOMElement* pIdent = 0;
	
#line 1587 "modelica_tree_parser.cpp"
	
	RefMyAST __t29 = _t;
	RefMyAST tmp17_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp17_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp17_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp17_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp17_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST29 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT_LIST);
	_t = _t->getFirstChild();
	{
	i = _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getNextSibling();
#line 379 "walker.g"
	
					pIdent = pModelicaXMLDoc->createElement(X("pder_var"));
					pIdent->setAttribute(X("ident"), X(i->getText().c_str()));
					el_stack.push_back(pIdent);
				
#line 1613 "modelica_tree_parser.cpp"
	}
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == IDENT)) {
			i2 = _t;
			RefMyAST i2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			i2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i2));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
			_t = _t->getNextSibling();
#line 385 "walker.g"
			
							pIdent = pModelicaXMLDoc->createElement(X("pder_var"));
							pIdent->setAttribute(X("ident"), X(i2->getText().c_str()));
							el_stack.push_back(pIdent);
						
#line 1632 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop32;
		}
		
	}
	_loop32:;
	} // ( ... )*
	currentAST = __currentAST29;
	_t = __t29;
	_t = _t->getNextSibling();
#line 391 "walker.g"
	
	
				DOMElement* pIdentList = pModelicaXMLDoc->createElement(X("variables"));
				pIdentList = (DOMElement*)appendKids(el_stack, pIdentList);
				ast = pIdentList;
	
#line 1651 "modelica_tree_parser.cpp"
	ident_list_AST = RefMyAST(currentAST.root);
	returnAST = ident_list_AST;
	_retTree = _t;
	return ast;
}

void modelica_tree_parser::type_prefix(RefMyAST _t,
	DOMElement* parent
) {
	RefMyAST type_prefix_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST type_prefix_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST d = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST d_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FLOW:
	{
		f = _t;
		RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FLOW);
		_t = _t->getNextSibling();
		break;
	}
	case STREAM:
	{
		s = _t;
		RefMyAST s_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		s_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(s));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STREAM);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DISCRETE:
	{
		d = _t;
		RefMyAST d_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		d_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(d));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(d_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DISCRETE);
		_t = _t->getNextSibling();
		break;
	}
	case PARAMETER:
	{
		p = _t;
		RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PARAMETER);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	{
		c = _t;
		RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CONSTANT);
		_t = _t->getNextSibling();
		break;
	}
	case INPUT:
	case OUTPUT:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case INPUT:
	{
		i = _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INPUT);
		_t = _t->getNextSibling();
		break;
	}
	case OUTPUT:
	{
		o = _t;
		RefMyAST o_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		o_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(o));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(o_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),OUTPUT);
		_t = _t->getNextSibling();
		break;
	}
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 932 "walker.g"
	
				if (f != NULL) { parent->setAttribute(X("flow"), X("true")); }
				if (s != NULL) { parent->setAttribute(X("stream"), X("true")); }
				if (d != NULL) { parent->setAttribute(X("variability"), X("discrete")); }
				else if (p != NULL) { parent->setAttribute(X("variability"), X("parameter")); }
				else if (c != NULL) { parent->setAttribute(X("variability"), X("constant")); }
				//else { parent->setAttribute(X("variability"), X("variable")); }
				if (i != NULL) { parent->setAttribute(X("direction"), X("input")); }
				else if (o != NULL) { parent->setAttribute(X("direction"), X("output")); }
				//else { parent->setAttribute(X("direction"), X("bidirectional")); }
			
#line 1814 "modelica_tree_parser.cpp"
	type_prefix_AST = RefMyAST(currentAST.root);
	returnAST = type_prefix_AST;
	_retTree = _t;
}

DOMElement*  modelica_tree_parser::array_subscripts(RefMyAST _t,
	int kind
) {
#line 2616 "walker.g"
	DOMElement* ast;
#line 1825 "modelica_tree_parser.cpp"
	RefMyAST array_subscripts_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST array_subscripts_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2616 "walker.g"
	
		l_stack el_stack;
		DOMElement* s = 0;
		DOMElement *pArraySubscripts = 0;
		if (kind)
		  pArraySubscripts = pModelicaXMLDoc->createElement(X("type_array_subscripts"));
		else
		  pArraySubscripts = pModelicaXMLDoc->createElement(X("array_subscripts"));
	
#line 1842 "modelica_tree_parser.cpp"
	
	RefMyAST __t377 = _t;
	lbk = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST lbk_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	lbk_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lbk));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lbk_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST377 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LBRACK);
	_t = _t->getFirstChild();
	pArraySubscripts=subscript(_t,pArraySubscripts);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_1.member(_t->getType()))) {
			pArraySubscripts=subscript(_t,pArraySubscripts);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		else {
			goto _loop379;
		}
		
	}
	_loop379:;
	} // ( ... )*
	currentAST = __currentAST377;
	_t = __t377;
	_t = _t->getNextSibling();
#line 2629 "walker.g"
	
	
				pArraySubscripts->setAttribute(X("sline"), X(itoa(lbk->getLine(),stmp,10)));
				pArraySubscripts->setAttribute(X("scolumn"), X(itoa(lbk->getColumn(),stmp,10)));
	
				ast = pArraySubscripts;
			
#line 1884 "modelica_tree_parser.cpp"
	array_subscripts_AST = RefMyAST(currentAST.root);
	returnAST = array_subscripts_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::comment(RefMyAST _t) {
#line 2662 "walker.g"
	DOMElement* ast;
#line 1894 "modelica_tree_parser.cpp"
	RefMyAST comment_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST comment_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2662 "walker.g"
	
		DOMElement* ann=0;
		DOMElement* cmt=0;
	ast = 0;
		DOMElement *pComment = pModelicaXMLDoc->createElement(X("comment"));
		bool bAnno = false;
	
#line 1909 "modelica_tree_parser.cpp"
	
	RefMyAST __t383 = _t;
	c = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST383 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),COMMENT);
	_t = _t->getFirstChild();
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2670 "walker.g"
	if (cmt) pComment->appendChild(cmt);
#line 1926 "modelica_tree_parser.cpp"
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ANNOTATION:
	{
		pComment=annotation(_t,0 /* none */, pComment, INSIDE_COMMENT);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2671 "walker.g"
		bAnno = true;
#line 1938 "modelica_tree_parser.cpp"
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST383;
	_t = __t383;
	_t = _t->getNextSibling();
#line 2672 "walker.g"
	
				if (c)
				{
					pComment->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
					pComment->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
				}
				if ((cmt !=0) || bAnno) ast = pComment;
				else ast = 0;
			
#line 1964 "modelica_tree_parser.cpp"
	comment_AST = RefMyAST(currentAST.root);
	returnAST = comment_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::enumeration_literal(RefMyAST _t) {
#line 472 "walker.g"
	DOMElement* ast;
#line 1974 "modelica_tree_parser.cpp"
	RefMyAST enumeration_literal_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_literal_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i1 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
#line 473 "walker.g"
	
	DOMElement* c1=0;
	
#line 1986 "modelica_tree_parser.cpp"
	RefMyAST __t46 = _t;
	RefMyAST tmp18_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp18_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp18_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp18_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp18_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST46 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ENUMERATION_LITERAL);
	_t = _t->getFirstChild();
	i1 = _t;
	RefMyAST i1_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i1_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i1));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i1_AST));
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getNextSibling();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		c1=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST46;
	_t = __t46;
	_t = _t->getNextSibling();
#line 477 "walker.g"
	
				DOMElement* pEnumerationLiteral = pModelicaXMLDoc->createElement(X("enumeration_literal"));
				pEnumerationLiteral->setAttribute(X("ident"), str2xml(i1));
	
				pEnumerationLiteral->setAttribute(X("sline"), X(itoa(i1->getLine(),stmp,10)));
				pEnumerationLiteral->setAttribute(X("scolumn"), X(itoa(i1->getColumn(),stmp,10)));
	
				if (c1) pEnumerationLiteral->appendChild(c1);
				ast = pEnumerationLiteral;
			
#line 2039 "modelica_tree_parser.cpp"
	enumeration_literal_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_literal_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::element_list(RefMyAST _t,
	int iSwitch, DOMElement*definition
) {
#line 652 "walker.g"
	DOMElement* ast;
#line 2051 "modelica_tree_parser.cpp"
	RefMyAST element_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 652 "walker.g"
	
	DOMElement* e = 0;
	l_stack el_stack;
	DOMElement* ann = 0;
	
#line 2062 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXTENDS:
		case IMPORT:
		case CONSTRAINEDBY:
		case DECLARATION:
		case DEFINITION:
		{
			{
			definition=element(_t,iSwitch, definition);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case ANNOTATION:
		{
			{
			definition=annotation(_t,iSwitch, definition, INSIDE_ELEMENT);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		default:
		{
			goto _loop81;
		}
		}
	}
	_loop81:;
	} // ( ... )*
#line 661 "walker.g"
	
				ast = definition;
	
#line 2103 "modelica_tree_parser.cpp"
	element_list_AST = RefMyAST(currentAST.root);
	returnAST = element_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::public_element_list(RefMyAST _t,
	DOMElement* definition
) {
#line 558 "walker.g"
	DOMElement* ast;
#line 2115 "modelica_tree_parser.cpp"
	RefMyAST public_element_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST public_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 558 "walker.g"
	
	DOMElement* el;
	
#line 2126 "modelica_tree_parser.cpp"
	
	RefMyAST __t65 = _t;
	p = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST65 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PUBLIC);
	_t = _t->getFirstChild();
	definition=element_list(_t,1 /* public */, definition);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST65;
	_t = __t65;
	_t = _t->getNextSibling();
#line 566 "walker.g"
	
				ast = definition;
	
#line 2148 "modelica_tree_parser.cpp"
	public_element_list_AST = RefMyAST(currentAST.root);
	returnAST = public_element_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::protected_element_list(RefMyAST _t,
	DOMElement* definition
) {
#line 571 "walker.g"
	DOMElement* ast;
#line 2160 "modelica_tree_parser.cpp"
	RefMyAST protected_element_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST protected_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 571 "walker.g"
	
	DOMElement* el;
	
#line 2171 "modelica_tree_parser.cpp"
	
	RefMyAST __t67 = _t;
	p = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST67 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PROTECTED);
	_t = _t->getFirstChild();
	definition=element_list(_t,2 /* protected */, definition);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST67;
	_t = __t67;
	_t = _t->getNextSibling();
#line 580 "walker.g"
	
				ast = definition;
	
#line 2193 "modelica_tree_parser.cpp"
	protected_element_list_AST = RefMyAST(currentAST.root);
	returnAST = protected_element_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::equation_clause(RefMyAST _t,
	DOMElement *definition
) {
#line 1237 "walker.g"
	DOMElement* ast;
#line 2205 "modelica_tree_parser.cpp"
	RefMyAST equation_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1237 "walker.g"
	
		l_stack el_stack;
		DOMElement* e = 0;
		DOMElement* ann = 0;
	
#line 2218 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUATION:
	{
		RefMyAST __t176 = _t;
		eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST176 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUATION);
		_t = _t->getFirstChild();
		{
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EQUATION_STATEMENT:
			{
				definition=equation(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case ANNOTATION:
			{
				definition=annotation(_t,0 /*none*/, definition, INSIDE_EQUATION);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			default:
			{
				goto _loop179;
			}
			}
		}
		_loop179:;
		} // ( ... )*
		}
		currentAST = __currentAST176;
		_t = __t176;
		_t = _t->getNextSibling();
#line 1251 "walker.g"
		
					ast = definition;
				
#line 2271 "modelica_tree_parser.cpp"
		equation_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	case INITIAL_EQUATION:
	{
		RefMyAST __t180 = _t;
		RefMyAST tmp19_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp19_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp19_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp19_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp19_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST180 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INITIAL_EQUATION);
		_t = _t->getFirstChild();
		RefMyAST __t181 = _t;
		RefMyAST tmp20_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp20_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp20_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp20_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp20_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST181 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUATION);
		_t = _t->getFirstChild();
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EQUATION_STATEMENT:
			{
				definition=equation(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case ANNOTATION:
			{
				definition=annotation(_t,0 /* none */, definition, INSIDE_EQUATION );
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			default:
			{
				goto _loop183;
			}
			}
		}
		_loop183:;
		} // ( ... )*
		currentAST = __currentAST181;
		_t = __t181;
		_t = _t->getNextSibling();
#line 1261 "walker.g"
		
						ast = definition;
					
#line 2333 "modelica_tree_parser.cpp"
		currentAST = __currentAST180;
		_t = __t180;
		_t = _t->getNextSibling();
		equation_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = equation_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::algorithm_clause(RefMyAST _t,
	DOMElement* definition
) {
#line 1267 "walker.g"
	DOMElement* ast;
#line 2355 "modelica_tree_parser.cpp"
	RefMyAST algorithm_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1267 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* ann;
	
#line 2366 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ALGORITHM:
	{
		RefMyAST __t185 = _t;
		RefMyAST tmp21_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp21_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp21_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp21_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp21_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST185 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ALGORITHM);
		_t = _t->getFirstChild();
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case ALGORITHM_STATEMENT:
			{
				definition=algorithm(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case ANNOTATION:
			{
				definition=annotation(_t,0 /* none */, definition, INSIDE_ALGORITHM);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			default:
			{
				goto _loop187;
			}
			}
		}
		_loop187:;
		} // ( ... )*
		currentAST = __currentAST185;
		_t = __t185;
		_t = _t->getNextSibling();
#line 1278 "walker.g"
		
					ast = definition;
				
#line 2418 "modelica_tree_parser.cpp"
		algorithm_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	case INITIAL_ALGORITHM:
	{
		RefMyAST __t188 = _t;
		RefMyAST tmp22_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp22_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp22_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp22_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp22_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST188 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INITIAL_ALGORITHM);
		_t = _t->getFirstChild();
		RefMyAST __t189 = _t;
		RefMyAST tmp23_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp23_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp23_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp23_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp23_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST189 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ALGORITHM);
		_t = _t->getFirstChild();
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case ALGORITHM_STATEMENT:
			{
				definition=algorithm(_t,definition);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case ANNOTATION:
			{
				definition=annotation(_t,0 /* none */, definition, INSIDE_ALGORITHM);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			default:
			{
				goto _loop191;
			}
			}
		}
		_loop191:;
		} // ( ... )*
		currentAST = __currentAST189;
		_t = __t189;
		_t = _t->getNextSibling();
#line 1287 "walker.g"
		
						ast = definition;
					
#line 2480 "modelica_tree_parser.cpp"
		currentAST = __currentAST188;
		_t = __t188;
		_t = _t->getNextSibling();
		algorithm_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = algorithm_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::external_function_call(RefMyAST _t,
	DOMElement *pExternalFunctionCall
) {
#line 596 "walker.g"
	DOMElement* ast;
#line 2502 "modelica_tree_parser.cpp"
	RefMyAST external_function_call_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST external_function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 596 "walker.g"
	
		DOMElement* temp=0;
		DOMElement* temp2=0;
		DOMElement* temp3=0;
		ast = 0;
		DOMElement* pExternalEqual = pModelicaXMLDoc->createElement(X("external_equal"));
	
#line 2523 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING:
	{
		s = _t;
		RefMyAST s_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		s_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(s));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STRING);
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ANNOTATION:
	case EXTERNAL_ANNOTATION:
	case EXTERNAL_FUNCTION_CALL:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL_FUNCTION_CALL:
	{
		RefMyAST __t71 = _t;
		RefMyAST tmp24_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp24_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp24_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp24_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp24_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST71 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXTERNAL_FUNCTION_CALL);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case IDENT:
		{
			{
			i = _t;
			RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXPRESSION_LIST:
			{
				temp=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
			}
#line 609 "walker.g"
			
									if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));
									if (i != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i));
									if (temp) pExternalFunctionCall->appendChild(temp);
			
									pExternalFunctionCall->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
									pExternalFunctionCall->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			
									ast = pExternalFunctionCall;
								
#line 2615 "modelica_tree_parser.cpp"
			break;
		}
		case EQUALS:
		{
			RefMyAST __t75 = _t;
			e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST75 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
			_t = _t->getFirstChild();
			temp2=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			i2 = _t;
			RefMyAST i2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			i2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i2));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXPRESSION_LIST:
			{
				temp3=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
			currentAST = __currentAST75;
			_t = __t75;
			_t = _t->getNextSibling();
#line 620 "walker.g"
			
									if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));
									if (i2 != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i2));
									pExternalFunctionCall->setAttribute(X("sline"), X(itoa(i2->getLine(),stmp,10)));
									pExternalFunctionCall->setAttribute(X("scolumn"), X(itoa(i2->getColumn(),stmp,10)));
									DOMElement* pExternalEqual =
										pModelicaXMLDoc->createElement(X("external_equal"));
									if (temp2) pExternalEqual->appendChild(temp2);
									pExternalFunctionCall->appendChild(pExternalEqual);
									if (temp3) pExternalFunctionCall->appendChild(temp3);
									ast = pExternalFunctionCall;
								
#line 2676 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST71;
		_t = __t71;
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ANNOTATION:
	case EXTERNAL_ANNOTATION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 634 "walker.g"
	
				if (!ast)
				{
					//parent->appendChild(ast);
					ast = pExternalFunctionCall;
				}
	
#line 2710 "modelica_tree_parser.cpp"
	external_function_call_AST = RefMyAST(currentAST.root);
	returnAST = external_function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::annotation(RefMyAST _t,
	int iSwitch, DOMElement *parent, enum anno awhere
) {
#line 2743 "walker.g"
	DOMElement* ast;
#line 2722 "modelica_tree_parser.cpp"
	RefMyAST annotation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST annotation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2743 "walker.g"
	
	void* cmod=0;
	
#line 2733 "modelica_tree_parser.cpp"
	
	RefMyAST __t390 = _t;
	a = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST a_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	a_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(a));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(a_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST390 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ANNOTATION);
	_t = _t->getFirstChild();
	cmod=class_modification(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST390;
	_t = __t390;
	_t = _t->getNextSibling();
#line 2749 "walker.g"
	
				DOMElement *pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
	
				pAnnotation->setAttribute(X("sline"), X(itoa(a->getLine(),stmp,10)));
				pAnnotation->setAttribute(X("scolumn"), X(itoa(a->getColumn(),stmp,10)));
	
				switch (awhere)
				{
				case INSIDE_ELEMENT:
						pAnnotation->setAttribute(X("inside"), X("element"));
						break;
				case INSIDE_EQUATION:
						pAnnotation->setAttribute(X("inside"), X("equation"));
						break;
				case INSIDE_ALGORITHM:
						pAnnotation->setAttribute(X("inside"), X("algorithm"));
						break;
				case INSIDE_COMMENT:
						pAnnotation->setAttribute(X("inside"), X("comment"));
						break;
				default:
						//pAnnotation->setAttribute(X("inside"), X("unspecified"));
					   ;
				}
				setVisibility(iSwitch, pAnnotation);
				if (cmod) pAnnotation = (DOMElement*)appendKidsFromStack((l_stack *)cmod, pAnnotation);
				parent->appendChild(pAnnotation);
				ast = parent;
	
#line 2781 "modelica_tree_parser.cpp"
	annotation_AST = RefMyAST(currentAST.root);
	returnAST = annotation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::expression_list(RefMyAST _t) {
#line 2568 "walker.g"
	DOMElement* ast;
#line 2791 "modelica_tree_parser.cpp"
	RefMyAST expression_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2568 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		//DOMElement* pComma = pModelicaXMLDoc->createElement(X("comma"));
	
#line 2804 "modelica_tree_parser.cpp"
	
	{
	RefMyAST __t368 = _t;
	el = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST el_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	el_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(el));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST368 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2576 "walker.g"
	el_stack.push_back(e);
#line 2822 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2577 "walker.g"
			el_stack.push_back(pModelicaXMLDoc->createElement(X("comma"))); el_stack.push_back(e);
#line 2833 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop370;
		}
		
	}
	_loop370:;
	} // ( ... )*
	currentAST = __currentAST368;
	_t = __t368;
	_t = _t->getNextSibling();
	}
#line 2580 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "expression_list");
	
				ast->setAttribute(X("sline"), X(itoa(el->getLine(),stmp,10)));
				ast->setAttribute(X("scolumn"), X(itoa(el->getColumn(),stmp,10)));
			
#line 2853 "modelica_tree_parser.cpp"
	expression_list_AST = RefMyAST(currentAST.root);
	returnAST = expression_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::component_reference(RefMyAST _t) {
#line 2448 "walker.g"
	DOMElement* ast;
#line 2863 "modelica_tree_parser.cpp"
	RefMyAST component_reference_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_reference_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2448 "walker.g"
	
		DOMElement* arr = 0;
		DOMElement* id = 0;
	
#line 2877 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		RefMyAST __t342 = _t;
		i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST342 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			arr=array_subscripts(_t,0);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST342;
		_t = __t342;
		_t = _t->getNextSibling();
#line 2455 "walker.g"
		
						DOMElement *pCref = pModelicaXMLDoc->createElement(X("component_reference"));
		
						pCref->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
						pCref->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
		
						pCref->setAttribute(X("ident"), str2xml(i));
						if (arr) pCref->appendChild(arr);
						ast = pCref;
					
#line 2930 "modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	{
		RefMyAST __t344 = _t;
		RefMyAST tmp25_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp25_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp25_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp25_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp25_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST344 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DOT);
		_t = _t->getFirstChild();
		RefMyAST __t345 = _t;
		i2 = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST i2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i2));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST345 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			arr=array_subscripts(_t,0);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST345;
		_t = __t345;
		_t = _t->getNextSibling();
		ast=component_reference(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST344;
		_t = __t344;
		_t = _t->getNextSibling();
#line 2467 "walker.g"
		
						DOMElement *pCref = pModelicaXMLDoc->createElement(X("component_reference"));
						pCref->setAttribute(X("ident"), str2xml(i2));
		
						pCref->setAttribute(X("sline"), X(itoa(i2->getLine(),stmp,10)));
						pCref->setAttribute(X("scolumn"), X(itoa(i2->getColumn(),stmp,10)));
		
						if (arr) pCref->appendChild(arr);
						pCref->appendChild(ast);
						ast = pCref;
					
#line 2998 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	component_reference_AST = RefMyAST(currentAST.root);
	returnAST = component_reference_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::element(RefMyAST _t,
	int iSwitch, DOMElement *parent
) {
#line 670 "walker.g"
	DOMElement* ast;
#line 3018 "modelica_tree_parser.cpp"
	RefMyAST element_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST re = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST re_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST re2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST re2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fd = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fd_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST id = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST id_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST od = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST od_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST rd = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST rd_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 670 "walker.g"
	
		DOMElement* class_def = 0;
		DOMElement* e_spec = 0;
		DOMElement* final = 0;
		DOMElement* innerouter = 0;
		DOMElement* constr = 0;
		DOMElement* cmt = 0;
		DOMElement* comp_clause = 0;
	
#line 3053 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IMPORT:
	{
		parent=import_clause(_t,iSwitch, parent);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 682 "walker.g"
		
						ast = parent;
					
#line 3068 "modelica_tree_parser.cpp"
		break;
	}
	case EXTENDS:
	case CONSTRAINEDBY:
	{
		parent=extends_clause(_t,iSwitch, parent);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 686 "walker.g"
		
						ast = parent;
					
#line 3081 "modelica_tree_parser.cpp"
		break;
	}
	case DECLARATION:
	{
		RefMyAST __t84 = _t;
		RefMyAST tmp26_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp26_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp26_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp26_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp26_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST84 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DECLARATION);
		_t = _t->getFirstChild();
		{
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case REDELCARE:
		{
			re = _t;
			RefMyAST re_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			re_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(re));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(re_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REDELCARE);
			_t = _t->getNextSibling();
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FINAL:
		case FLOW:
		case INNER:
		case INPUT:
		case OUTER:
		case OUTPUT:
		case PARAMETER:
		case REPLACEABLE:
		case DOT:
		case STREAM:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 691 "walker.g"
		
						   DOMElement* componentElement = pModelicaXMLDoc->createElement(X("component_clause"));
						   setVisibility(iSwitch, componentElement);
						   if (re) componentElement->setAttribute(X("redeclare"), X("true"));
					
#line 3140 "modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FINAL:
		{
			f = _t;
			RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FINAL);
			_t = _t->getNextSibling();
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INNER:
		case INPUT:
		case OUTER:
		case OUTPUT:
		case PARAMETER:
		case REPLACEABLE:
		case DOT:
		case STREAM:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 696 "walker.g"
		if (f) componentElement->setAttribute(X("final"), X("true"));
#line 3178 "modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INNER:
		{
			i = _t;
			RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INNER);
			_t = _t->getNextSibling();
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTER:
		case OUTPUT:
		case PARAMETER:
		case REPLACEABLE:
		case DOT:
		case STREAM:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case OUTER:
		{
			o = _t;
			RefMyAST o_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			o_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(o));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(o_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),OUTER);
			_t = _t->getNextSibling();
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case REPLACEABLE:
		case DOT:
		case STREAM:
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 698 "walker.g"
		
								  if (i && o) componentElement->setAttribute(X("innerouter"), X("innerouter"));
								  else
								  {
									if (i) componentElement->setAttribute(X("innerouter"), X("inner"));
									if (o) componentElement->setAttribute(X("innerouter"), X("outer"));
								  }
							
#line 3255 "modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case STREAM:
		case IDENT:
		{
			parent=component_clause(_t,parent, componentElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 707 "walker.g"
			
										ast = parent;
									
#line 3277 "modelica_tree_parser.cpp"
			break;
		}
		case REPLACEABLE:
		{
			r = _t;
			RefMyAST r_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			r_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REPLACEABLE);
			_t = _t->getNextSibling();
#line 710 "walker.g"
			if (r) componentElement->setAttribute(X("replaceable"), X("true"));
#line 3290 "modelica_tree_parser.cpp"
			parent=component_clause(_t,parent, componentElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
			case CONSTRAINEDBY:
			{
				constr=constraining_clause(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				cmt=comment(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
#line 713 "walker.g"
			
			if (constr)
										{
											// append the comment to the constraint
											if (cmt) ((DOMElement*)constr)->appendChild(cmt);
											parent->appendChild(constr);
										}
										ast = parent;
									
#line 3329 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		}
		currentAST = __currentAST84;
		_t = __t84;
		_t = _t->getNextSibling();
		break;
	}
	case DEFINITION:
	{
		RefMyAST __t92 = _t;
		RefMyAST tmp27_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp27_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp27_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp27_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp27_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST92 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DEFINITION);
		_t = _t->getFirstChild();
		{
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case REDECLARE:
		{
			re2 = _t;
			RefMyAST re2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			re2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(re2));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(re2_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REDECLARE);
			_t = _t->getNextSibling();
			break;
		}
		case FINAL:
		case INNER:
		case OUTER:
		case REPLACEABLE:
		case CLASS_DEFINITION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 727 "walker.g"
		
								DOMElement* definitionElement = pModelicaXMLDoc->createElement(X("definition"));
								setVisibility(iSwitch, definitionElement);
						        if (re2) definitionElement->setAttribute(X("redeclare"), X("true"));
							
#line 3392 "modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FINAL:
		{
			fd = _t;
			RefMyAST fd_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			fd_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(fd));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(fd_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FINAL);
			_t = _t->getNextSibling();
			break;
		}
		case INNER:
		case OUTER:
		case REPLACEABLE:
		case CLASS_DEFINITION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 732 "walker.g"
		if (fd) definitionElement->setAttribute(X("final"), X("true"));
#line 3422 "modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INNER:
		{
			id = _t;
			RefMyAST id_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			id_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(id));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(id_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INNER);
			_t = _t->getNextSibling();
			break;
		}
		case OUTER:
		case REPLACEABLE:
		case CLASS_DEFINITION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case OUTER:
		{
			od = _t;
			RefMyAST od_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			od_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(od));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(od_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),OUTER);
			_t = _t->getNextSibling();
			break;
		}
		case REPLACEABLE:
		case CLASS_DEFINITION:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 734 "walker.g"
		
								  if (i && o) definitionElement->setAttribute(X("innerouter"), X("outer"));
								  else
								  {
									  if (i) definitionElement->setAttribute(X("innerouter"), X("inner"));
									  if (o) definitionElement->setAttribute(X("innerouter"), X("outer"));
								  }
							
#line 3483 "modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			definitionElement=class_definition(_t,fd != NULL, definitionElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 744 "walker.g"
			
										if (definitionElement && definitionElement->hasChildNodes())
											parent->appendChild(definitionElement);
										ast = parent;
									
#line 3499 "modelica_tree_parser.cpp"
			break;
		}
		case REPLACEABLE:
		{
			{
			rd = _t;
			RefMyAST rd_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			rd_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(rd));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(rd_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REPLACEABLE);
			_t = _t->getNextSibling();
			definitionElement=class_definition(_t,fd != NULL, definitionElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
			case CONSTRAINEDBY:
			{
				constr=constraining_clause(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				cmt=comment(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
			}
#line 754 "walker.g"
			
										if (definitionElement)
										{
											if (innerouter) definitionElement->appendChild(innerouter);
											if (constr)
											{
												definitionElement->appendChild(constr);
												// append the comment to the constraint
												if (cmt) ((DOMElement*)constr)->appendChild(cmt);
											}
											if (rd) definitionElement->setAttribute(X("replaceable"), X("true"));
											if (definitionElement->hasChildNodes())
												parent->appendChild(definitionElement);
										}
										ast = parent;
									
#line 3557 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		}
		currentAST = __currentAST92;
		_t = __t92;
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	element_AST = RefMyAST(currentAST.root);
	returnAST = element_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::import_clause(RefMyAST _t,
	int iSwitch, DOMElement *parent
) {
#line 779 "walker.g"
	DOMElement* ast;
#line 3589 "modelica_tree_parser.cpp"
	RefMyAST import_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST import_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 779 "walker.g"
	
		DOMElement* imp = 0;
		DOMElement* cmt = 0;
	
#line 3601 "modelica_tree_parser.cpp"
	
	RefMyAST __t102 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST102 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IMPORT);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	{
		imp=explicit_import_name(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case QUALIFIED:
	case UNQUALIFIED:
	{
		imp=implicit_import_name(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST102;
	_t = __t102;
	_t = _t->getNextSibling();
#line 791 "walker.g"
	
				DOMElement* pImport = pModelicaXMLDoc->createElement(X("import"));
				setVisibility(iSwitch, pImport);
	
				pImport->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pImport->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				pImport->appendChild(imp);
				if (cmt) pImport->appendChild(cmt);
				parent->appendChild(pImport);
				ast = parent;
			
#line 3675 "modelica_tree_parser.cpp"
	import_clause_AST = RefMyAST(currentAST.root);
	returnAST = import_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::extends_clause(RefMyAST _t,
	int iSwitch, DOMElement* parent
) {
#line 860 "walker.g"
	DOMElement* ast;
#line 3687 "modelica_tree_parser.cpp"
	RefMyAST extends_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST extends_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cb = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST cb_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 860 "walker.g"
	
		void *path = 0;
		void *mod = 0;
	
#line 3701 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTENDS:
	{
		RefMyAST __t113 = _t;
		e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST113 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXTENDS);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_MODIFICATION:
		{
			mod=class_modification(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST113;
		_t = __t113;
		_t = _t->getNextSibling();
#line 868 "walker.g"
		
						DOMElement* pExtends = pModelicaXMLDoc->createElement(X("extends"));
						setVisibility(iSwitch, pExtends);
		
						pExtends->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
						pExtends->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));
		
						if (mod) pExtends = (DOMElement*)appendKidsFromStack((l_stack *)mod, pExtends);
						if (path) pExtends->setAttribute(X("type"), X(((mstring*)path)->c_str()));
						parent->appendChild(pExtends);
						ast = parent;
					
#line 3759 "modelica_tree_parser.cpp"
		break;
	}
	case CONSTRAINEDBY:
	{
		RefMyAST __t115 = _t;
		cb = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST cb_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		cb_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(cb));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(cb_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST115 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CONSTRAINEDBY);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_MODIFICATION:
		{
			mod=class_modification(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST115;
		_t = __t115;
		_t = _t->getNextSibling();
#line 881 "walker.g"
		
						DOMElement* pExtends = pModelicaXMLDoc->createElement(X("constrainedby"));
						setVisibility(iSwitch, pExtends);
		
						pExtends->setAttribute(X("sline"), X(itoa(cb->getLine(),stmp,10)));
						pExtends->setAttribute(X("scolumn"), X(itoa(cb->getColumn(),stmp,10)));
		
						if (mod) pExtends = (DOMElement*)appendKidsFromStack((l_stack *)mod, pExtends);
						if (path) pExtends->setAttribute(X("type"), X(((mstring*)path)->c_str()));
						parent->appendChild(pExtends);
						ast = parent;
					
#line 3814 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	extends_clause_AST = RefMyAST(currentAST.root);
	returnAST = extends_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::component_clause(RefMyAST _t,
	DOMElement* parent, DOMElement* attributes
) {
#line 910 "walker.g"
	DOMElement* ast;
#line 3834 "modelica_tree_parser.cpp"
	RefMyAST component_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 910 "walker.g"
	
		type_prefix_t pfx;
		void* path = 0;
		DOMElement* arr = 0;
		DOMElement* comp_list = 0;
	
#line 3846 "modelica_tree_parser.cpp"
	
	type_prefix(_t,attributes);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	path=type_specifier(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 919 "walker.g"
	if (path) attributes->setAttribute(X("type"), X(((mstring*)path)->c_str()));
#line 3856 "modelica_tree_parser.cpp"
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		arr=array_subscripts(_t,1);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	parent=component_list(_t,parent, attributes, arr);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 922 "walker.g"
	
				ast = parent;
			
#line 3885 "modelica_tree_parser.cpp"
	component_clause_AST = RefMyAST(currentAST.root);
	returnAST = component_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::constraining_clause(RefMyAST _t) {
#line 899 "walker.g"
	DOMElement* ast;
#line 3895 "modelica_tree_parser.cpp"
	RefMyAST constraining_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST constraining_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 899 "walker.g"
	
	DOMElement* pConstrain = pModelicaXMLDoc->createElement(X("constrain"));
	
#line 3904 "modelica_tree_parser.cpp"
	
	{
	ast=extends_clause(_t,0, pConstrain);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	constraining_clause_AST = RefMyAST(currentAST.root);
	returnAST = constraining_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::explicit_import_name(RefMyAST _t) {
#line 808 "walker.g"
	DOMElement* ast;
#line 3920 "modelica_tree_parser.cpp"
	RefMyAST explicit_import_name_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST explicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 808 "walker.g"
	
		void* path;
	
#line 3931 "modelica_tree_parser.cpp"
	
	RefMyAST __t106 = _t;
	RefMyAST tmp28_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp28_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp28_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp28_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp28_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST106 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
	_t = _t->getFirstChild();
	i = _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getNextSibling();
	path=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST106;
	_t = __t106;
	_t = _t->getNextSibling();
#line 814 "walker.g"
	
				DOMElement* pExplicitImport = pModelicaXMLDoc->createElement(X("named_import"));
				pExplicitImport->setAttribute(X("ident"), str2xml(i));
	
				pExplicitImport->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pExplicitImport->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				if (path) pExplicitImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
				ast = pExplicitImport;
			
#line 3967 "modelica_tree_parser.cpp"
	explicit_import_name_AST = RefMyAST(currentAST.root);
	returnAST = explicit_import_name_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::implicit_import_name(RefMyAST _t) {
#line 828 "walker.g"
	DOMElement* ast;
#line 3977 "modelica_tree_parser.cpp"
	RefMyAST implicit_import_name_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST implicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST unq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST unq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST qua = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST qua_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 828 "walker.g"
	
		void* path;
	
#line 3990 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNQUALIFIED:
	{
		RefMyAST __t109 = _t;
		unq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST unq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		unq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(unq));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(unq_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST109 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNQUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST109;
		_t = __t109;
		_t = _t->getNextSibling();
#line 834 "walker.g"
		
						DOMElement* pUnqImport = pModelicaXMLDoc->createElement(X("unqualified_import"));
						if (path) pUnqImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
		
						pUnqImport->setAttribute(X("sline"), X(itoa(unq->getLine(),stmp,10)));
						pUnqImport->setAttribute(X("scolumn"), X(itoa(unq->getColumn(),stmp,10)));
		
						ast = pUnqImport;
					
#line 4024 "modelica_tree_parser.cpp"
		break;
	}
	case QUALIFIED:
	{
		RefMyAST __t110 = _t;
		qua = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST qua_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		qua_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(qua));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(qua_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST110 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),QUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST110;
		_t = __t110;
		_t = _t->getNextSibling();
#line 844 "walker.g"
		
						DOMElement* pQuaImport = pModelicaXMLDoc->createElement(X("qualified_import"));
						if (path) pQuaImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
		
						pQuaImport->setAttribute(X("sline"), X(itoa(qua->getLine(),stmp,10)));
						pQuaImport->setAttribute(X("scolumn"), X(itoa(qua->getColumn(),stmp,10)));
		
						ast = pQuaImport;
					
#line 4055 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	implicit_import_name_AST = RefMyAST(currentAST.root);
	returnAST = implicit_import_name_AST;
	_retTree = _t;
	return ast;
}

void*  modelica_tree_parser::type_specifier(RefMyAST _t) {
#line 946 "walker.g"
	void* ast;
#line 4073 "modelica_tree_parser.cpp"
	RefMyAST type_specifier_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST type_specifier_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	ast=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	type_specifier_AST = RefMyAST(currentAST.root);
	returnAST = type_specifier_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::component_list(RefMyAST _t,
	DOMElement* parent, DOMElement *attributes, DOMElement* type_array
) {
#line 952 "walker.g"
	DOMElement* ast;
#line 4093 "modelica_tree_parser.cpp"
	RefMyAST component_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 952 "walker.g"
	
		l_stack el_stack;
		DOMElement* e=0;
	
#line 4103 "modelica_tree_parser.cpp"
	
	parent=component_declaration(_t,parent, attributes, type_array);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == IDENT)) {
			parent=component_declaration(_t,parent, attributes, type_array);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		else {
			goto _loop128;
		}
		
	}
	_loop128:;
	} // ( ... )*
#line 961 "walker.g"
	
				ast = parent;
			
#line 4128 "modelica_tree_parser.cpp"
	component_list_AST = RefMyAST(currentAST.root);
	returnAST = component_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::component_declaration(RefMyAST _t,
	DOMElement* parent, DOMElement *attributes, DOMElement *type_array
) {
#line 982 "walker.g"
	DOMElement* ast;
#line 4140 "modelica_tree_parser.cpp"
	RefMyAST component_declaration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 982 "walker.g"
	
		DOMElement* cmt = 0;
		DOMElement* dec = 0;
		DOMElement* cda = 0;
	
#line 4151 "modelica_tree_parser.cpp"
	
	{
	dec=declaration(_t,attributes, type_array);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IF:
	{
		cda=conditional_attribute(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case EXTENDS:
	case CONSTRAINEDBY:
	case IDENT:
	case COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case EXTENDS:
	case CONSTRAINEDBY:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 993 "walker.g"
	
				if (cmt) dec->appendChild(cmt);
				if (cda) dec->appendChild(cda);
				parent->appendChild(dec);
				ast = parent;
			
#line 4214 "modelica_tree_parser.cpp"
	component_declaration_AST = RefMyAST(currentAST.root);
	returnAST = component_declaration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::conditional_attribute(RefMyAST _t) {
#line 966 "walker.g"
	DOMElement* ast;
#line 4224 "modelica_tree_parser.cpp"
	RefMyAST conditional_attribute_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_attribute_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 966 "walker.g"
	
		DOMElement* cda = 0;
		DOMElement* e = 0;
	
#line 4236 "modelica_tree_parser.cpp"
	
	RefMyAST __t130 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST130 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST130;
	_t = __t130;
	_t = _t->getNextSibling();
#line 972 "walker.g"
	
		cda = pModelicaXMLDoc->createElement(X("conditional"));
		cda->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
		cda->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
		cda->appendChild(e);
		ast = cda;
	
#line 4262 "modelica_tree_parser.cpp"
	conditional_attribute_AST = RefMyAST(currentAST.root);
	returnAST = conditional_attribute_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::expression(RefMyAST _t) {
#line 1827 "walker.g"
	DOMElement* ast;
#line 4272 "modelica_tree_parser.cpp"
	RefMyAST expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case DER:
	case END:
	case FALSE:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case RANGE2:
	case RANGE3:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=simple_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IF:
	{
		ast=if_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case CODE_EXPRESSION:
	case CODE_MODIFICATION:
	case CODE_ELEMENT:
	case CODE_EQUATION:
	case CODE_INITIALEQUATION:
	case CODE_ALGORITHM:
	case CODE_INITIALALGORITHM:
	{
		ast=code_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	expression_AST = RefMyAST(currentAST.root);
	returnAST = expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::declaration(RefMyAST _t,
	DOMElement* parent, DOMElement* type_array
) {
#line 1003 "walker.g"
	DOMElement* ast;
#line 4364 "modelica_tree_parser.cpp"
	RefMyAST declaration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1003 "walker.g"
	
		DOMElement* arr = 0;
		DOMElement* mod = 0;
		DOMElement* id = 0;
	
#line 4377 "modelica_tree_parser.cpp"
	
	RefMyAST __t136 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST136 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		arr=array_subscripts(_t,0);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		mod=modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST136;
	_t = __t136;
	_t = _t->getNextSibling();
#line 1011 "walker.g"
	
				DOMElement *pComponent = pModelicaXMLDoc->createElement(X("component"));
				pComponent->setAttribute(X("ident"), str2xml(i));
				pComponent->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pComponent->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
				setAttributes(pComponent, parent);
				if (type_array) pComponent->appendChild(type_array);
				if (arr) pComponent->appendChild(arr);
				if (mod) pComponent->appendChild(mod);
				ast = pComponent;
			
#line 4451 "modelica_tree_parser.cpp"
	declaration_AST = RefMyAST(currentAST.root);
	returnAST = declaration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::modification(RefMyAST _t) {
#line 1024 "walker.g"
	DOMElement* ast;
#line 4461 "modelica_tree_parser.cpp"
	RefMyAST modification_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1024 "walker.g"
	
		DOMElement* e = 0;
		void *cm = 0;
		int iswitch = 0;
	
#line 4476 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		cm=class_modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case AND:
		case DER:
		case END:
		case FALSE:
		case IF:
		case NOT:
		case OR:
		case TRUE:
		case UNSIGNED_REAL:
		case DOT:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case STAR:
		case SLASH:
		case POWER:
		case PLUS_EW:
		case MINUS_EW:
		case STAR_EW:
		case SLASH_EW:
		case POWER_EW:
		case LESS:
		case LESSEQ:
		case GREATER:
		case GREATEREQ:
		case EQEQ:
		case LESSGT:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		case CODE_EXPRESSION:
		case CODE_MODIFICATION:
		case CODE_ELEMENT:
		case CODE_EQUATION:
		case CODE_INITIALEQUATION:
		case CODE_ALGORITHM:
		case CODE_INITIALALGORITHM:
		case FUNCTION_CALL:
		case INITIAL_FUNCTION_CALL:
		case RANGE2:
		case RANGE3:
		case UNARY_MINUS:
		case UNARY_PLUS:
		case UNARY_MINUS_EW:
		case UNARY_PLUS_EW:
		{
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		case STRING_COMMENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		break;
	}
	case EQUALS:
	{
		RefMyAST __t142 = _t;
		eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST142 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST142;
		_t = __t142;
		_t = _t->getNextSibling();
#line 1032 "walker.g"
		iswitch = 1;
#line 4577 "modelica_tree_parser.cpp"
		break;
	}
	case ASSIGN:
	{
		RefMyAST __t143 = _t;
		as = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST as_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		as_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(as));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(as_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST143 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ASSIGN);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST143;
		_t = __t143;
		_t = _t->getNextSibling();
#line 1033 "walker.g"
		iswitch = 2;
#line 4600 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 1035 "walker.g"
	
				DOMElement *pModificationEQorASorARG = null;
				if (iswitch == 1) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_equals"));
				if (iswitch == 2) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_assign"));
				if (iswitch == 0) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_arguments"));
				if (cm) pModificationEQorASorARG = (DOMElement*)appendKidsFromStack((l_stack*)cm, pModificationEQorASorARG);
				if (e)
				{
					if (iswitch == 0)
					{
						DOMElement *z = pModelicaXMLDoc->createElement(X("modification_equals"));
						z->appendChild(e);
						pModificationEQorASorARG->appendChild(z);
					}
					else
					{
						pModificationEQorASorARG->appendChild(e);
					}
				}
				if (eq)
				{
					pModificationEQorASorARG->setAttribute(X("sline"), X(itoa(eq->getLine(),stmp,10)));
					pModificationEQorASorARG->setAttribute(X("scolumn"), X(itoa(eq->getColumn(),stmp,10)));
				}
				if (as)
				{
					pModificationEQorASorARG->setAttribute(X("sline"), X(itoa(as->getLine(),stmp,10)));
					pModificationEQorASorARG->setAttribute(X("scolumn"), X(itoa(as->getColumn(),stmp,10)));
				}
				ast = pModificationEQorASorARG;
			
#line 4641 "modelica_tree_parser.cpp"
	modification_AST = RefMyAST(currentAST.root);
	returnAST = modification_AST;
	_retTree = _t;
	return ast;
}

void * modelica_tree_parser::argument_list(RefMyAST _t) {
#line 1076 "walker.g"
	void *stack;
#line 4651 "modelica_tree_parser.cpp"
	RefMyAST argument_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST argument_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1076 "walker.g"
	
		l_stack *el_stack = new l_stack;
		DOMElement* e;
	
#line 4661 "modelica_tree_parser.cpp"
	
	RefMyAST __t148 = _t;
	RefMyAST tmp29_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp29_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp29_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp29_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp29_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST148 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ARGUMENT_LIST);
	_t = _t->getFirstChild();
	e=argument(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1083 "walker.g"
	el_stack->push_back(e);
#line 4679 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELEMENT_MODIFICATION || _t->getType() == ELEMENT_REDECLARATION)) {
			e=argument(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1084 "walker.g"
			el_stack->push_back(e);
#line 4690 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop150;
		}
		
	}
	_loop150:;
	} // ( ... )*
	currentAST = __currentAST148;
	_t = __t148;
	_t = _t->getNextSibling();
#line 1086 "walker.g"
	
				if (el_stack->size()) stack = (void*)el_stack;
				else (stack = 0);
			
#line 4707 "modelica_tree_parser.cpp"
	argument_list_AST = RefMyAST(currentAST.root);
	returnAST = argument_list_AST;
	_retTree = _t;
	return stack;
}

DOMElement*  modelica_tree_parser::argument(RefMyAST _t) {
#line 1092 "walker.g"
	DOMElement* ast;
#line 4717 "modelica_tree_parser.cpp"
	RefMyAST argument_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST em = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST em_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST er = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST er_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELEMENT_MODIFICATION:
	{
		RefMyAST __t152 = _t;
		em = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST em_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		em_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(em));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(em_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST152 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELEMENT_MODIFICATION);
		_t = _t->getFirstChild();
		ast=element_modification_or_replaceable(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST152;
		_t = __t152;
		_t = _t->getNextSibling();
#line 1095 "walker.g"
		
					if (em)
					{
						ast->setAttribute(X("sline"), X(itoa(em->getLine(),stmp,10)));
						ast->setAttribute(X("scolumn"), X(itoa(em->getColumn(),stmp,10)));
					}
				
#line 4756 "modelica_tree_parser.cpp"
		argument_AST = RefMyAST(currentAST.root);
		break;
	}
	case ELEMENT_REDECLARATION:
	{
		RefMyAST __t153 = _t;
		er = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST er_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		er_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(er));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(er_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST153 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELEMENT_REDECLARATION);
		_t = _t->getFirstChild();
		ast=element_redeclaration(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST153;
		_t = __t153;
		_t = _t->getNextSibling();
#line 1103 "walker.g"
		
					if (er)
					{
						ast->setAttribute(X("sline"), X(itoa(er->getLine(),stmp,10)));
						ast->setAttribute(X("scolumn"), X(itoa(er->getColumn(),stmp,10)));
					}
				
#line 4786 "modelica_tree_parser.cpp"
		argument_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = argument_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::element_modification_or_replaceable(RefMyAST _t) {
#line 1112 "walker.g"
	DOMElement* ast;
#line 4803 "modelica_tree_parser.cpp"
	RefMyAST element_modification_or_replaceable_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_or_replaceable_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EACH:
	{
		e = _t;
		RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EACH);
		_t = _t->getNextSibling();
		break;
	}
	case FINAL:
	case REPLACEABLE:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FINAL:
	{
		f = _t;
		RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FINAL);
		_t = _t->getNextSibling();
		break;
	}
	case REPLACEABLE:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	{
		ast=element_modification(_t,e!=NULL,f!=NULL);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case REPLACEABLE:
	{
		ast=element_replaceable(_t,e!=NULL,f!=NULL,false);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	element_modification_or_replaceable_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_or_replaceable_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::element_redeclaration(RefMyAST _t) {
#line 1140 "walker.g"
	DOMElement* ast;
#line 4900 "modelica_tree_parser.cpp"
	RefMyAST element_redeclaration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_redeclaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1140 "walker.g"
	
		DOMElement* class_def = 0;
		DOMElement* e_spec = 0;
		DOMElement* constr = 0;
		class_def = pModelicaXMLDoc->createElement(X("definition"));
	
#line 4918 "modelica_tree_parser.cpp"
	
	{
	RefMyAST __t162 = _t;
	r = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST r_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	r_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST162 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REDECLARE);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EACH:
	{
		e = _t;
		RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EACH);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FINAL:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case REPLACEABLE:
	case DOT:
	case STREAM:
	case IDENT:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FINAL:
	{
		f = _t;
		RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FINAL);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case REPLACEABLE:
	case DOT:
	case STREAM:
	case IDENT:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case DOT:
	case STREAM:
	case IDENT:
	case CLASS_DEFINITION:
	{
		{
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,false, class_def);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1152 "walker.g"
			
										DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
										if (class_def && class_def->hasChildNodes())
											pElementRedeclaration->appendChild(class_def);
										if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
										if (e) pElementRedeclaration->setAttribute(X("each"), X("true"));
										ast = pElementRedeclaration;
									
#line 5034 "modelica_tree_parser.cpp"
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case STREAM:
		case IDENT:
		{
#line 1160 "walker.g"
			DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
#line 5049 "modelica_tree_parser.cpp"
			pElementRedeclaration=component_clause1(_t,pElementRedeclaration);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1162 "walker.g"
			
										if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
										if (e) pElementRedeclaration->setAttribute(X("each"), X("true"));
										ast = pElementRedeclaration;
									
#line 5059 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		}
		break;
	}
	case REPLACEABLE:
	{
		{
		ast=element_replaceable(_t,e!=NULL, f!=NULL, true /* has redeclare */);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST162;
	_t = __t162;
	_t = _t->getNextSibling();
	}
	element_redeclaration_AST = RefMyAST(currentAST.root);
	returnAST = element_redeclaration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::element_modification(RefMyAST _t,
	bool e, bool f
) {
#line 1119 "walker.g"
	DOMElement* ast;
#line 5101 "modelica_tree_parser.cpp"
	RefMyAST element_modification_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1119 "walker.g"
	
		DOMElement* cref;
		DOMElement* mod=0;
		DOMElement* cmt=0;
	
#line 5112 "modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		mod=modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	case STRING_COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1129 "walker.g"
	
				DOMElement *pModification = pModelicaXMLDoc->createElement(X("element_modification"));
				if (f) pModification->setAttribute(X("final"), X("true"));
				if (e) pModification->setAttribute(X("each"), X("true"));
				pModification->appendChild(cref);
				if (mod) pModification->appendChild(mod);
				if (cmt) pModification->appendChild(cmt);
				ast = pModification;
			
#line 5154 "modelica_tree_parser.cpp"
	element_modification_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::element_replaceable(RefMyAST _t,
	bool eachB, bool finalB, bool redeclareB
) {
#line 1175 "walker.g"
	DOMElement* ast;
#line 5166 "modelica_tree_parser.cpp"
	RefMyAST element_replaceable_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_replaceable_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1175 "walker.g"
	
		DOMElement* class_def = 0;
		DOMElement* e_spec = 0;
		DOMElement* constr = 0;
		DOMElement* cmt = 0;
		class_def = pModelicaXMLDoc->createElement(X("definition"));
	
#line 5179 "modelica_tree_parser.cpp"
	
	{
	RefMyAST __t171 = _t;
	RefMyAST tmp30_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp30_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp30_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp30_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp30_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST171 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REPLACEABLE);
	_t = _t->getFirstChild();
#line 1186 "walker.g"
	DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
#line 5195 "modelica_tree_parser.cpp"
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_DEFINITION:
	{
		class_def=class_definition(_t,false, class_def);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case DOT:
	case STREAM:
	case IDENT:
	{
		pElementRedeclaration=component_clause1(_t,pElementRedeclaration);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTENDS:
	case CONSTRAINEDBY:
	{
		constr=constraining_clause(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 1191 "walker.g"
	
						if (finalB) pElementRedeclaration->setAttribute(X("final"), X("true"));
						if (true) pElementRedeclaration->setAttribute(X("replaceable"), X("true"));
						if (class_def &&  class_def->hasChildNodes())
						{
							pElementRedeclaration->appendChild(class_def);	                
							if (constr) 
							{
							   if (cmt) ((DOMElement*)constr)->appendChild(cmt);
							   pElementRedeclaration->appendChild(constr);
							}
						}
						else
						{
							if (constr) 
							{
							   if (cmt) ((DOMElement*)constr)->appendChild(cmt);
							   pElementRedeclaration->appendChild(constr);
							}
						}
						ast = pElementRedeclaration;
					
#line 5276 "modelica_tree_parser.cpp"
	currentAST = __currentAST171;
	_t = __t171;
	_t = _t->getNextSibling();
	}
	element_replaceable_AST = RefMyAST(currentAST.root);
	returnAST = element_replaceable_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::component_clause1(RefMyAST _t,
	DOMElement *parent
) {
#line 1218 "walker.g"
	DOMElement* ast;
#line 5292 "modelica_tree_parser.cpp"
	RefMyAST component_clause1_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_clause1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1218 "walker.g"
	
		type_prefix_t pfx;
		DOMElement* attr = pModelicaXMLDoc->createElement(X("tmp"));
		void* path = 0;
		DOMElement* arr = 0;
		DOMElement* comp_decl = 0;
		DOMElement* comp_list = 0;
	
#line 5306 "modelica_tree_parser.cpp"
	
	type_prefix(_t,attr);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	path=type_specifier(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1229 "walker.g"
	if (path) attr->setAttribute(X("type"), X(((mstring*)path)->c_str()));
#line 5316 "modelica_tree_parser.cpp"
	parent=component_declaration(_t,parent, attr, null);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1231 "walker.g"
	
				ast = parent;
			
#line 5324 "modelica_tree_parser.cpp"
	component_clause1_AST = RefMyAST(currentAST.root);
	returnAST = component_clause1_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::equation(RefMyAST _t,
	DOMElement* definition
) {
#line 1293 "walker.g"
	DOMElement* ast;
#line 5336 "modelica_tree_parser.cpp"
	RefMyAST equation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST es = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST es_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1293 "walker.g"
	
		DOMElement* cmt = 0;
	
#line 5347 "modelica_tree_parser.cpp"
	
	RefMyAST __t193 = _t;
	es = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST es_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	es_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(es));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(es_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST193 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUATION_STATEMENT);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	{
		ast=equality_equation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IF:
	{
		ast=conditional_equation_e(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case FOR:
	{
		ast=for_clause_e(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case WHEN:
	{
		ast=when_clause_e(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case CONNECT:
	{
		ast=connect_clause(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case DOT:
	case IDENT:
	{
		ast=equation_funcall(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 1307 "walker.g"
	
					DOMElement*  pEquation = pModelicaXMLDoc->createElement(X("equation"));
					pEquation->appendChild(ast);
					if (cmt) pEquation->appendChild(cmt);
					if (es)
					{
						pEquation->setAttribute(X("sline"), X(itoa(es->getLine(),stmp,10)));
						pEquation->setAttribute(X("scolumn"), X(itoa(es->getColumn(),stmp,10)));
					}
					definition->appendChild(pEquation);
					ast = definition;
				
#line 5446 "modelica_tree_parser.cpp"
	currentAST = __currentAST193;
	_t = __t193;
	_t = _t->getNextSibling();
	equation_AST = RefMyAST(currentAST.root);
	returnAST = equation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::algorithm(RefMyAST _t,
	DOMElement *definition
) {
#line 1337 "walker.g"
	DOMElement* ast;
#line 5461 "modelica_tree_parser.cpp"
	RefMyAST algorithm_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST az = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST az_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1337 "walker.g"
	
		DOMElement* expLeft;
		DOMElement* cref;
		DOMElement* expr;
		DOMElement* tuple;
		DOMElement* args;
		DOMElement* cmt=0;
	
#line 5479 "modelica_tree_parser.cpp"
	
	RefMyAST __t198 = _t;
	as = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST as_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	as_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(as));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(as_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST198 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ALGORITHM_STATEMENT);
	_t = _t->getFirstChild();
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ASSIGN:
	{
		RefMyAST __t200 = _t;
		az = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST az_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		az_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(az));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(az_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST200 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ASSIGN);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case AND:
		case DER:
		case END:
		case FALSE:
		case NOT:
		case OR:
		case TRUE:
		case UNSIGNED_REAL:
		case DOT:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case STAR:
		case SLASH:
		case POWER:
		case PLUS_EW:
		case MINUS_EW:
		case STAR_EW:
		case SLASH_EW:
		case POWER_EW:
		case LESS:
		case LESSEQ:
		case GREATER:
		case GREATEREQ:
		case EQEQ:
		case LESSGT:
		case IDENT:
		case UNSIGNED_INTEGER:
		case STRING:
		case FUNCTION_CALL:
		case INITIAL_FUNCTION_CALL:
		case RANGE2:
		case RANGE3:
		case UNARY_MINUS:
		case UNARY_PLUS:
		case UNARY_MINUS_EW:
		case UNARY_PLUS_EW:
		{
			expLeft=simple_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			expr=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1350 "walker.g"
			
										DOMElement*  pAlgAssign = pModelicaXMLDoc->createElement(X("alg_assign"));
										if (az)
										{
											pAlgAssign->setAttribute(X("sline"), X(itoa(az->getLine(),stmp,10)));
											pAlgAssign->setAttribute(X("scolumn"), X(itoa(az->getColumn(),stmp,10)));
										}
										pAlgAssign->appendChild(expLeft);
										pAlgAssign->appendChild(expr);
										ast = pAlgAssign;
									
#line 5569 "modelica_tree_parser.cpp"
			break;
		}
		case EXPRESSION_LIST:
		{
			{
			tuple=tuple_expression_list(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			args=function_call(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
#line 1362 "walker.g"
			
										DOMElement*  pAlgAssign = pModelicaXMLDoc->createElement(X("alg_assign"));
										DOMElement*  pCall = pModelicaXMLDoc->createElement(X("call"));
			
										if (az)
										{
											pAlgAssign->setAttribute(X("sline"), X(itoa(az->getLine(),stmp,10)));
											pAlgAssign->setAttribute(X("scolumn"), X(itoa(az->getColumn(),stmp,10)));
										}
			
										pAlgAssign->appendChild(tuple);
			
										pCall->appendChild(cref);
										pCall->appendChild(args);
			
										pAlgAssign->appendChild(pCall);
			
										ast = pAlgAssign;
										/*
			<!ELEMENT alg_assign ((component_reference, %exp;) | (output_expression_list, component_reference, function_arguments))>
			<!ATTLIST alg_assign
				%location;
			>
			*/
									
#line 5611 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST200;
		_t = __t200;
		_t = _t->getNextSibling();
		break;
	}
	case DOT:
	case IDENT:
	{
		ast=algorithm_function_call(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case IF:
	{
		ast=conditional_equation_a(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case FOR:
	{
		ast=for_clause_a(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case WHILE:
	{
		ast=while_clause(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case WHEN:
	{
		ast=when_clause_a(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 1396 "walker.g"
	
					DOMElement* pAlgorithm = pModelicaXMLDoc->createElement(X("algorithm"));
					if (as)
					{
						pAlgorithm->setAttribute(X("sline"), X(itoa(as->getLine(),stmp,10)));
						pAlgorithm->setAttribute(X("scolumn"), X(itoa(as->getColumn(),stmp,10)));
					}
					pAlgorithm->appendChild(ast);
					if (cmt) pAlgorithm->appendChild(cmt);
					definition->appendChild(pAlgorithm);
					ast = definition;
					/*
					<!ELEMENT algorithm ((alg_assign | alg_call | alg_if | alg_for | alg_while | alg_when | alg_break | alg_return), comment?)>
					<!ATTLIST algorithm
						initial (true) #IMPLIED
						%location;
					>
					*/
		  		
#line 5708 "modelica_tree_parser.cpp"
	currentAST = __currentAST198;
	_t = __t198;
	_t = _t->getNextSibling();
	algorithm_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::equality_equation(RefMyAST _t) {
#line 1439 "walker.g"
	DOMElement* ast;
#line 5721 "modelica_tree_parser.cpp"
	RefMyAST equality_equation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equality_equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1439 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 5733 "modelica_tree_parser.cpp"
	
	RefMyAST __t206 = _t;
	eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST206 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
	_t = _t->getFirstChild();
	e1=simple_expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	e2=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST206;
	_t = __t206;
	_t = _t->getNextSibling();
#line 1446 "walker.g"
	
				DOMElement*  pEquEqual = pModelicaXMLDoc->createElement(X("equ_equal"));
				pEquEqual->setAttribute(X("sline"), X(itoa(eq->getLine(),stmp,10)));
				pEquEqual->setAttribute(X("scolumn"), X(itoa(eq->getColumn(),stmp,10)));
				pEquEqual->appendChild(e1);
				pEquEqual->appendChild(e2);
				ast = pEquEqual;
				/*
				<!ELEMENT equ_equal (%exp;, %exp;)>
				<!ATTLIST equ_equal
					%location;
				>
				*/
			
#line 5769 "modelica_tree_parser.cpp"
	equality_equation_AST = RefMyAST(currentAST.root);
	returnAST = equality_equation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::conditional_equation_e(RefMyAST _t) {
#line 1462 "walker.g"
	DOMElement* ast;
#line 5779 "modelica_tree_parser.cpp"
	RefMyAST conditional_equation_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1462 "walker.g"
	
		DOMElement* e1;
		DOMElement* then_b;
		DOMElement* else_b = 0;
		DOMElement* else_if_b;
		l_stack el_stack;
		DOMElement* e;
	
		DOMElement*  pEquIf = pModelicaXMLDoc->createElement(X("equ_if"));
		DOMElement*  pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
	DOMElement*  pEquElse = pModelicaXMLDoc->createElement(X("equ_else"));
	
		bool fbElse = false;
	
#line 5801 "modelica_tree_parser.cpp"
	
	RefMyAST __t208 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST208 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1479 "walker.g"
	pEquIf->appendChild(e1);
#line 5818 "modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1480 "walker.g"
	pEquIf->appendChild(pEquThen);
#line 5824 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=equation_elseif(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1481 "walker.g"
			el_stack.push_back(e);
#line 5835 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop210;
		}
		
	}
	_loop210:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		RefMyAST tmp31_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp31_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp31_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp31_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp31_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSE);
		_t = _t->getNextSibling();
		pEquElse=equation_list(_t,pEquElse);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1482 "walker.g"
		fbElse = true;
#line 5862 "modelica_tree_parser.cpp"
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST208;
	_t = __t208;
	_t = _t->getNextSibling();
#line 1484 "walker.g"
	
				pEquIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pEquIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				if (el_stack.size()>0) pEquIf = (DOMElement*)appendKids(el_stack, pEquIf); // ?? is this ok?
				if (fbElse) pEquIf->appendChild(pEquElse);
				ast = pEquIf;
			
#line 5887 "modelica_tree_parser.cpp"
	conditional_equation_e_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::for_clause_e(RefMyAST _t) {
#line 1535 "walker.g"
	DOMElement* ast;
#line 5897 "modelica_tree_parser.cpp"
	RefMyAST for_clause_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1535 "walker.g"
	
		DOMElement* f;
		DOMElement* eq;
		DOMElement*  pEquFor = pModelicaXMLDoc->createElement(X("equ_for"));
	
#line 5910 "modelica_tree_parser.cpp"
	
	RefMyAST __t218 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST218 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR);
	_t = _t->getFirstChild();
	f=for_indices(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1542 "walker.g"
	pEquFor->appendChild(f);
#line 5927 "modelica_tree_parser.cpp"
	pEquFor=equation_list(_t,pEquFor);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST218;
	_t = __t218;
	_t = _t->getNextSibling();
#line 1544 "walker.g"
	
				pEquFor->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pEquFor->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				ast = pEquFor;
			
#line 5941 "modelica_tree_parser.cpp"
	for_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = for_clause_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::when_clause_e(RefMyAST _t) {
#line 1652 "walker.g"
	DOMElement* ast;
#line 5951 "modelica_tree_parser.cpp"
	RefMyAST when_clause_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1652 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* body;
		DOMElement* el = 0;
		DOMElement* pEquWhen = pModelicaXMLDoc->createElement(X("equ_when"));
		DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
	
#line 5967 "modelica_tree_parser.cpp"
	
	RefMyAST __t232 = _t;
	wh = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST wh_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	wh_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(wh));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(wh_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST232 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1663 "walker.g"
	pEquWhen->appendChild(e);
#line 5984 "modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1664 "walker.g"
	pEquWhen->appendChild(pEquThen);
#line 5990 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEWHEN)) {
			el=else_when_e(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1665 "walker.g"
			el_stack.push_back(el);
#line 6001 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop234;
		}
		
	}
	_loop234:;
	} // ( ... )*
	currentAST = __currentAST232;
	_t = __t232;
	_t = _t->getNextSibling();
#line 1667 "walker.g"
	
				pEquWhen->setAttribute(X("sline"), X(itoa(wh->getLine(),stmp,10)));
				pEquWhen->setAttribute(X("scolumn"), X(itoa(wh->getColumn(),stmp,10)));
	
				if (el_stack.size()>0) pEquWhen = (DOMElement*)appendKids(el_stack, pEquWhen); // ??is this ok?
				ast = pEquWhen;
			
#line 6021 "modelica_tree_parser.cpp"
	when_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::connect_clause(RefMyAST _t) {
#line 1804 "walker.g"
	DOMElement* ast;
#line 6031 "modelica_tree_parser.cpp"
	RefMyAST connect_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST connect_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1804 "walker.g"
	
		DOMElement* r1;
		DOMElement* r2;
	
#line 6043 "modelica_tree_parser.cpp"
	
	RefMyAST __t254 = _t;
	c = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST254 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CONNECT);
	_t = _t->getFirstChild();
	r1=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	r2=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST254;
	_t = __t254;
	_t = _t->getNextSibling();
#line 1814 "walker.g"
	
				DOMElement* pEquConnect = pModelicaXMLDoc->createElement(X("equ_connect"));
	
				pEquConnect->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
				pEquConnect->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
	
				pEquConnect->appendChild(r1);
				pEquConnect->appendChild(r2);
				ast = pEquConnect;
			
#line 6075 "modelica_tree_parser.cpp"
	connect_clause_AST = RefMyAST(currentAST.root);
	returnAST = connect_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::equation_funcall(RefMyAST _t) {
#line 1322 "walker.g"
	DOMElement* ast;
#line 6085 "modelica_tree_parser.cpp"
	RefMyAST equation_funcall_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_funcall_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1322 "walker.g"
	
	DOMElement* fcall = 0;
	DOMElement* cref = 0;
	
#line 6095 "modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	fcall=function_call(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1329 "walker.g"
	
				 DOMElement*  pEquCall = pModelicaXMLDoc->createElement(X("equ_call"));
				 pEquCall->appendChild(cref);
				 pEquCall->appendChild(fcall);
				 ast = pEquCall;
			
#line 6110 "modelica_tree_parser.cpp"
	equation_funcall_AST = RefMyAST(currentAST.root);
	returnAST = equation_funcall_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::function_call(RefMyAST _t) {
#line 2481 "walker.g"
	DOMElement* ast;
#line 6120 "modelica_tree_parser.cpp"
	RefMyAST function_call_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fa = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fa_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST __t348 = _t;
	fa = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST fa_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	fa_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(fa));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(fa_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST348 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FUNCTION_ARGUMENTS);
	_t = _t->getFirstChild();
	ast=function_arguments(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2484 "walker.g"
	
				ast->setAttribute(X("sline"), X(itoa(fa->getLine(),stmp,10)));
				ast->setAttribute(X("scolumn"), X(itoa(fa->getColumn(),stmp,10)));
			
#line 6146 "modelica_tree_parser.cpp"
	currentAST = __currentAST348;
	_t = __t348;
	_t = _t->getNextSibling();
	function_call_AST = RefMyAST(currentAST.root);
	returnAST = function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::simple_expression(RefMyAST _t) {
#line 1888 "walker.g"
	DOMElement* ast;
#line 6159 "modelica_tree_parser.cpp"
	RefMyAST simple_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST simple_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r3 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r3_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1888 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
		DOMElement* e3;
	
#line 6174 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case RANGE3:
	{
		RefMyAST __t265 = _t;
		r3 = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST r3_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		r3_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r3));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r3_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST265 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),RANGE3);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e3=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST265;
		_t = __t265;
		_t = _t->getNextSibling();
#line 1898 "walker.g"
		
						DOMElement* pRange = pModelicaXMLDoc->createElement(X("range"));
		
						pRange->setAttribute(X("sline"), X(itoa(r3->getLine(),stmp,10)));
						pRange->setAttribute(X("scolumn"), X(itoa(r3->getColumn(),stmp,10)));
		
						pRange->appendChild(e1);
						pRange->appendChild(e2);
						pRange->appendChild(e3);
						ast = pRange;
						/*
						<!ELEMENT range ((%exp;), (%exp;, (%exp;)?)?)>
						<!ATTLIST range
							%location;
						>
						*/
					
#line 6222 "modelica_tree_parser.cpp"
		break;
	}
	case RANGE2:
	{
		RefMyAST __t266 = _t;
		r2 = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST r2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		r2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r2));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r2_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST266 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),RANGE2);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e3=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST266;
		_t = __t266;
		_t = _t->getNextSibling();
#line 1916 "walker.g"
		
						DOMElement* pRange = pModelicaXMLDoc->createElement(X("range"));
		
						pRange->setAttribute(X("sline"), X(itoa(r2->getLine(),stmp,10)));
						pRange->setAttribute(X("scolumn"), X(itoa(r2->getColumn(),stmp,10)));
		
						pRange->appendChild(e1);
						pRange->appendChild(e3);
						ast = pRange;
					
#line 6257 "modelica_tree_parser.cpp"
		break;
	}
	case AND:
	case DER:
	case END:
	case FALSE:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	simple_expression_AST = RefMyAST(currentAST.root);
	returnAST = simple_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::tuple_expression_list(RefMyAST _t) {
#line 2588 "walker.g"
	DOMElement* ast;
#line 6318 "modelica_tree_parser.cpp"
	RefMyAST tuple_expression_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST tuple_expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2588 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		//DOMElement* pComma = pModelicaXMLDoc->createElement(X("comma"));
	
#line 6331 "modelica_tree_parser.cpp"
	
	{
	RefMyAST __t373 = _t;
	el = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST el_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	el_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(el));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST373 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2596 "walker.g"
	el_stack.push_back(e);
#line 6349 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2597 "walker.g"
			el_stack.push_back(pModelicaXMLDoc->createElement(X("comma"))); el_stack.push_back(e);
#line 6360 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop375;
		}
		
	}
	_loop375:;
	} // ( ... )*
	currentAST = __currentAST373;
	_t = __t373;
	_t = _t->getNextSibling();
	}
#line 2600 "walker.g"
	
				if (el_stack.size() == 1)
				{
					ast = el_stack.back();
				}
				else
				{
					DOMElement *pTuple = pModelicaXMLDoc->createElement(X("output_expression_list"));
					pTuple = (DOMElement*)appendKids(el_stack, pTuple);
					pTuple->setAttribute(X("sline"), X(itoa(el->getLine(),stmp,10)));
					pTuple->setAttribute(X("scolumn"), X(itoa(el->getColumn(),stmp,10)));
					ast = pTuple;
				}
			
#line 6388 "modelica_tree_parser.cpp"
	tuple_expression_list_AST = RefMyAST(currentAST.root);
	returnAST = tuple_expression_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::algorithm_function_call(RefMyAST _t) {
#line 1418 "walker.g"
	DOMElement* ast;
#line 6398 "modelica_tree_parser.cpp"
	RefMyAST algorithm_function_call_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1418 "walker.g"
	
		DOMElement* cref;
		DOMElement* args;
	
#line 6408 "modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	args=function_call(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1425 "walker.g"
	
				DOMElement*  pAlgCall = pModelicaXMLDoc->createElement(X("alg_call"));
				pAlgCall->appendChild(cref);
				pAlgCall->appendChild(args);
				ast = pAlgCall;
				/*
				<!ELEMENT alg_call (component_reference, function_arguments)>
				<!ATTLIST alg_call
					%location;
				>
				*/
			
#line 6429 "modelica_tree_parser.cpp"
	algorithm_function_call_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::conditional_equation_a(RefMyAST _t) {
#line 1494 "walker.g"
	DOMElement* ast;
#line 6439 "modelica_tree_parser.cpp"
	RefMyAST conditional_equation_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1494 "walker.g"
	
		DOMElement* e1;
		DOMElement* then_b;
		DOMElement* else_b = 0;
		DOMElement* else_if_b;
		l_stack el_stack;
		DOMElement* e;
		DOMElement*  pAlgIf = pModelicaXMLDoc->createElement(X("alg_if"));
		DOMElement*  pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
		DOMElement*  pAlgElse = pModelicaXMLDoc->createElement(X("alg_else"));
		bool fbElse = false;
	
#line 6459 "modelica_tree_parser.cpp"
	
	RefMyAST __t213 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST213 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1509 "walker.g"
	pAlgIf->appendChild(e1);
#line 6476 "modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1511 "walker.g"
	
					if (pAlgThen)
					pAlgIf->appendChild(pAlgThen);
				
#line 6485 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=algorithm_elseif(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1515 "walker.g"
			el_stack.push_back(e);
#line 6496 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop215;
		}
		
	}
	_loop215:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		RefMyAST tmp32_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp32_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp32_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp32_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp32_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSE);
		_t = _t->getNextSibling();
		pAlgElse=algorithm_list(_t,pAlgElse);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1516 "walker.g"
		fbElse = true;
#line 6523 "modelica_tree_parser.cpp"
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST213;
	_t = __t213;
	_t = _t->getNextSibling();
#line 1518 "walker.g"
	
				pAlgIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pAlgIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
				if (el_stack.size()>0) pAlgIf = (DOMElement*)appendKids(el_stack, pAlgIf);
				if (fbElse)  pAlgIf->appendChild(pAlgElse);
				ast = pAlgIf;
			
#line 6547 "modelica_tree_parser.cpp"
	conditional_equation_a_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::for_clause_a(RefMyAST _t) {
#line 1553 "walker.g"
	DOMElement* ast;
#line 6557 "modelica_tree_parser.cpp"
	RefMyAST for_clause_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1553 "walker.g"
	
		DOMElement* f;
		DOMElement* eq;
		DOMElement*  pAlgFor = pModelicaXMLDoc->createElement(X("alg_for"));
	
#line 6570 "modelica_tree_parser.cpp"
	
	RefMyAST __t220 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST220 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR);
	_t = _t->getFirstChild();
	f=for_indices(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1561 "walker.g"
	
					f->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
					f->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
					pAlgFor->appendChild(f);
				
#line 6591 "modelica_tree_parser.cpp"
	pAlgFor=algorithm_list(_t,pAlgFor);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST220;
	_t = __t220;
	_t = _t->getNextSibling();
#line 1567 "walker.g"
	
				pAlgFor->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pAlgFor->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				ast = pAlgFor;
			
#line 6605 "modelica_tree_parser.cpp"
	for_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = for_clause_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::while_clause(RefMyAST _t) {
#line 1622 "walker.g"
	DOMElement* ast;
#line 6615 "modelica_tree_parser.cpp"
	RefMyAST while_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST while_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST w = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST w_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1622 "walker.g"
	
		DOMElement* e;
		DOMElement* body;
		DOMElement* pAlgWhile = pModelicaXMLDoc->createElement(X("alg_while"));
	
#line 6628 "modelica_tree_parser.cpp"
	
	RefMyAST __t230 = _t;
	w = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST w_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	w_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(w));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(w_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST230 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WHILE);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1631 "walker.g"
	
				  pAlgWhile->appendChild(e);
			
#line 6647 "modelica_tree_parser.cpp"
	pAlgWhile=algorithm_list(_t,pAlgWhile);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST230;
	_t = __t230;
	_t = _t->getNextSibling();
#line 1635 "walker.g"
	
				pAlgWhile->setAttribute(X("sline"), X(itoa(w->getLine(),stmp,10)));
				pAlgWhile->setAttribute(X("scolumn"), X(itoa(w->getColumn(),stmp,10)));
	
				ast = pAlgWhile;
			
#line 6661 "modelica_tree_parser.cpp"
	while_clause_AST = RefMyAST(currentAST.root);
	returnAST = while_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::when_clause_a(RefMyAST _t) {
#line 1695 "walker.g"
	DOMElement* ast;
#line 6671 "modelica_tree_parser.cpp"
	RefMyAST when_clause_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1695 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* body;
		DOMElement* el = 0;
		DOMElement* pAlgWhen = pModelicaXMLDoc->createElement(X("alg_when"));
		DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
	
#line 6687 "modelica_tree_parser.cpp"
	
	RefMyAST __t238 = _t;
	wh = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST wh_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	wh_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(wh));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(wh_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST238 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1706 "walker.g"
	pAlgWhen->appendChild(e);
#line 6704 "modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1707 "walker.g"
	pAlgWhen->appendChild(pAlgThen);
#line 6710 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEWHEN)) {
			el=else_when_a(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1708 "walker.g"
			el_stack.push_back(el);
#line 6721 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop240;
		}
		
	}
	_loop240:;
	} // ( ... )*
	currentAST = __currentAST238;
	_t = __t238;
	_t = _t->getNextSibling();
#line 1710 "walker.g"
	
				pAlgWhen->setAttribute(X("sline"), X(itoa(wh->getLine(),stmp,10)));
				pAlgWhen->setAttribute(X("scolumn"), X(itoa(wh->getColumn(),stmp,10)));
	
				if (el_stack.size() > 0) pAlgWhen = (DOMElement*)appendKids(el_stack, pAlgWhen);
				ast = pAlgWhen;
			
#line 6741 "modelica_tree_parser.cpp"
	when_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::equation_list(RefMyAST _t,
	DOMElement* pEquationList
) {
#line 1780 "walker.g"
	DOMElement* ast;
#line 6753 "modelica_tree_parser.cpp"
	RefMyAST equation_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1780 "walker.g"
	
		DOMElement* e;
		l_stack el_stack;
	
#line 6763 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == EQUATION_STATEMENT)) {
			pEquationList=equation(_t,pEquationList);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		else {
			goto _loop249;
		}
		
	}
	_loop249:;
	} // ( ... )*
#line 1787 "walker.g"
	
				ast = pEquationList;
			
#line 6785 "modelica_tree_parser.cpp"
	equation_list_AST = RefMyAST(currentAST.root);
	returnAST = equation_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::equation_elseif(RefMyAST _t) {
#line 1738 "walker.g"
	DOMElement* ast;
#line 6795 "modelica_tree_parser.cpp"
	RefMyAST equation_elseif_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1738 "walker.g"
	
		DOMElement* e;
		DOMElement* eq;
		DOMElement* pEquElseIf = pModelicaXMLDoc->createElement(X("equ_elseif"));
		DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
	
#line 6809 "modelica_tree_parser.cpp"
	
	RefMyAST __t244 = _t;
	els = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST els_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	els_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(els));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(els_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST244 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1747 "walker.g"
	pEquElseIf->appendChild(e);
#line 6826 "modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST244;
	_t = __t244;
	_t = _t->getNextSibling();
#line 1750 "walker.g"
	
				pEquElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
				pEquElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));
	
				pEquElseIf->appendChild(pEquThen);
				ast = pEquElseIf;
			
#line 6841 "modelica_tree_parser.cpp"
	equation_elseif_AST = RefMyAST(currentAST.root);
	returnAST = equation_elseif_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::algorithm_list(RefMyAST _t,
	DOMElement*  pAlgorithmList
) {
#line 1792 "walker.g"
	DOMElement* ast;
#line 6853 "modelica_tree_parser.cpp"
	RefMyAST algorithm_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1792 "walker.g"
	
		DOMElement* e;
		l_stack el_stack;
	
#line 6863 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ALGORITHM_STATEMENT)) {
			pAlgorithmList=algorithm(_t,pAlgorithmList);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		else {
			goto _loop252;
		}
		
	}
	_loop252:;
	} // ( ... )*
#line 1799 "walker.g"
	
				ast = pAlgorithmList;
			
#line 6885 "modelica_tree_parser.cpp"
	algorithm_list_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::algorithm_elseif(RefMyAST _t) {
#line 1759 "walker.g"
	DOMElement* ast;
#line 6895 "modelica_tree_parser.cpp"
	RefMyAST algorithm_elseif_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1759 "walker.g"
	
		DOMElement* e;
		DOMElement* body;
		DOMElement* pAlgElseIf = pModelicaXMLDoc->createElement(X("alg_elseif"));
		DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
	
#line 6909 "modelica_tree_parser.cpp"
	
	RefMyAST __t246 = _t;
	els = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST els_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	els_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(els));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(els_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST246 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1768 "walker.g"
	pAlgElseIf->appendChild(e);
#line 6926 "modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST246;
	_t = __t246;
	_t = _t->getNextSibling();
#line 1771 "walker.g"
	
				pAlgElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
				pAlgElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));
	
				pAlgElseIf->appendChild(pAlgThen);
				ast = pAlgElseIf;
			
#line 6941 "modelica_tree_parser.cpp"
	algorithm_elseif_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_elseif_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::for_indices(RefMyAST _t) {
#line 1596 "walker.g"
	DOMElement* ast;
#line 6951 "modelica_tree_parser.cpp"
	RefMyAST for_indices_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_indices_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1596 "walker.g"
	
		DOMElement* f;
		DOMElement* e;
		l_stack el_stack;
	
#line 6964 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == IN)) {
			RefMyAST __t226 = _t;
			RefMyAST tmp33_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp33_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp33_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp33_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp33_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST226 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IN);
			_t = _t->getFirstChild();
			i = _t;
			RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case AND:
			case DER:
			case END:
			case FALSE:
			case IF:
			case NOT:
			case OR:
			case TRUE:
			case UNSIGNED_REAL:
			case DOT:
			case LPAR:
			case LBRACK:
			case LBRACE:
			case PLUS:
			case MINUS:
			case STAR:
			case SLASH:
			case POWER:
			case PLUS_EW:
			case MINUS_EW:
			case STAR_EW:
			case SLASH_EW:
			case POWER_EW:
			case LESS:
			case LESSEQ:
			case GREATER:
			case GREATEREQ:
			case EQEQ:
			case LESSGT:
			case IDENT:
			case UNSIGNED_INTEGER:
			case STRING:
			case CODE_EXPRESSION:
			case CODE_MODIFICATION:
			case CODE_ELEMENT:
			case CODE_EQUATION:
			case CODE_INITIALEQUATION:
			case CODE_ALGORITHM:
			case CODE_INITIALALGORITHM:
			case FUNCTION_CALL:
			case INITIAL_FUNCTION_CALL:
			case RANGE2:
			case RANGE3:
			case UNARY_MINUS:
			case UNARY_PLUS:
			case UNARY_MINUS_EW:
			case UNARY_PLUS_EW:
			{
				e=expression(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
			currentAST = __currentAST226;
			_t = __t226;
			_t = _t->getNextSibling();
#line 1604 "walker.g"
			
					DOMElement* pForIndex = pModelicaXMLDoc->createElement(X("for_index"));
					pForIndex->setAttribute(X("ident"), str2xml(i));
			
					pForIndex->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
					pForIndex->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			
					if (e) pForIndex->appendChild(e);
					el_stack.push_back(pForIndex);
				
#line 7069 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop228;
		}
		
	}
	_loop228:;
	} // ( ... )*
#line 1615 "walker.g"
	
			DOMElement*  pForIndices = pModelicaXMLDoc->createElement(X("for_indices"));
			pForIndices = (DOMElement*)appendKids(el_stack, pForIndices);
			ast = pForIndices;
		
#line 7084 "modelica_tree_parser.cpp"
	for_indices_AST = RefMyAST(currentAST.root);
	returnAST = for_indices_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::for_iterator(RefMyAST _t) {
#line 1576 "walker.g"
	DOMElement* ast;
#line 7094 "modelica_tree_parser.cpp"
	RefMyAST for_iterator_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_iterator_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1576 "walker.g"
	
		DOMElement* expr;
		DOMElement* iter;
	
#line 7108 "modelica_tree_parser.cpp"
	
	RefMyAST __t222 = _t;
	f = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST222 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	RefMyAST __t223 = _t;
	RefMyAST tmp34_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp34_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp34_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp34_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST223 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IN);
	_t = _t->getFirstChild();
	i = _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getNextSibling();
	iter=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST223;
	_t = __t223;
	_t = _t->getNextSibling();
	currentAST = __currentAST222;
	_t = __t222;
	_t = _t->getNextSibling();
#line 1583 "walker.g"
	
			    DOMElement*  pForIter = pModelicaXMLDoc->createElement(X("for_iterator"));
				pForIter->appendChild(expr);
				DOMElement* pForIndex = pModelicaXMLDoc->createElement(X("for_index"));
				pForIndex->setAttribute(X("ident"), str2xml(i));
				pForIndex->setAttribute(X("sline"), X(itoa(f->getLine(),stmp,10)));
				pForIndex->setAttribute(X("scolumn"), X(itoa(f->getColumn(),stmp,10)));
			    if (iter) pForIndex->appendChild(iter);
				pForIter->appendChild(pForIndex);
				ast = pForIter;
	
#line 7161 "modelica_tree_parser.cpp"
	for_iterator_AST = RefMyAST(currentAST.root);
	returnAST = for_iterator_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::else_when_e(RefMyAST _t) {
#line 1676 "walker.g"
	DOMElement* ast;
#line 7171 "modelica_tree_parser.cpp"
	RefMyAST else_when_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1676 "walker.g"
	
		DOMElement*  expr;
		DOMElement*  eqn;
		DOMElement* pEquElseWhen = pModelicaXMLDoc->createElement(X("equ_elsewhen"));
	DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
	
#line 7185 "modelica_tree_parser.cpp"
	
	RefMyAST __t236 = _t;
	e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST236 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1684 "walker.g"
	pEquElseWhen->appendChild(expr);
#line 7202 "modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST236;
	_t = __t236;
	_t = _t->getNextSibling();
#line 1686 "walker.g"
	
				pEquElseWhen->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
				pEquElseWhen->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));
	
				pEquElseWhen->appendChild(pEquThen);
				ast = pEquElseWhen;
			
#line 7217 "modelica_tree_parser.cpp"
	else_when_e_AST = RefMyAST(currentAST.root);
	returnAST = else_when_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::else_when_a(RefMyAST _t) {
#line 1719 "walker.g"
	DOMElement* ast;
#line 7227 "modelica_tree_parser.cpp"
	RefMyAST else_when_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1719 "walker.g"
	
		DOMElement*  expr;
		DOMElement*  alg;
		DOMElement* pAlgElseWhen = pModelicaXMLDoc->createElement(X("alg_elsewhen"));
		DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
	
#line 7241 "modelica_tree_parser.cpp"
	
	RefMyAST __t242 = _t;
	e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST242 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1727 "walker.g"
	pAlgElseWhen->appendChild(expr);
#line 7258 "modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST242;
	_t = __t242;
	_t = _t->getNextSibling();
#line 1729 "walker.g"
	
				pAlgElseWhen->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
				pAlgElseWhen->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));
	
		        pAlgElseWhen->appendChild(pAlgThen);
				ast = pAlgElseWhen;
			
#line 7273 "modelica_tree_parser.cpp"
	else_when_a_AST = RefMyAST(currentAST.root);
	returnAST = else_when_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::if_expression(RefMyAST _t) {
#line 1835 "walker.g"
	DOMElement* ast;
#line 7283 "modelica_tree_parser.cpp"
	RefMyAST if_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST if_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1835 "walker.g"
	
		DOMElement* cond;
		DOMElement* thenPart;
		DOMElement* elsePart;
		DOMElement* e;
		DOMElement* elseifPart;
		l_stack el_stack;
	
#line 7299 "modelica_tree_parser.cpp"
	
	RefMyAST __t258 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST258 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IF);
	_t = _t->getFirstChild();
	cond=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	thenPart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=elseif_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1846 "walker.g"
			el_stack.push_back(e);
#line 7327 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop260;
		}
		
	}
	_loop260:;
	} // ( ... )*
	elsePart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1847 "walker.g"
	
					DOMElement* pIf = pModelicaXMLDoc->createElement(X("if"));
					DOMElement* pThen = pModelicaXMLDoc->createElement(X("then"));
					DOMElement* pElse = pModelicaXMLDoc->createElement(X("else"));
	
					pIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
					pIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
					pIf->appendChild(cond);
					pThen->appendChild(thenPart);
					pIf->appendChild(pThen);
					if (el_stack.size()>0) pIf = (DOMElement*)appendKids(el_stack, pIf); //??is this ok??
					pElse->appendChild(elsePart);
					pIf->appendChild(pElse);
					ast = pIf;
				
#line 7356 "modelica_tree_parser.cpp"
	currentAST = __currentAST258;
	_t = __t258;
	_t = _t->getNextSibling();
	if_expression_AST = RefMyAST(currentAST.root);
	returnAST = if_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::code_expression(RefMyAST _t) {
#line 1931 "walker.g"
	DOMElement* ast;
#line 7369 "modelica_tree_parser.cpp"
	RefMyAST code_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1931 "walker.g"
	
		DOMElement*pCode = pModelicaXMLDoc->createElement(X("code"));
	
#line 7378 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CODE_MODIFICATION:
	{
		RefMyAST __t268 = _t;
		RefMyAST tmp35_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp35_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp35_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp35_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp35_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST268 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_MODIFICATION);
		_t = _t->getFirstChild();
		{
		ast=modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST268;
		_t = __t268;
		_t = _t->getNextSibling();
#line 1938 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pModification = pModelicaXMLDoc->createElement(X("modification"));
					pModification->appendChild(ast);
					ast = pModification;
					/*
					ast = Absyn__CODE(Absyn__C_5fMODIFICATION(ast));
					*/
				
#line 7414 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_EXPRESSION:
	{
		RefMyAST __t270 = _t;
		RefMyAST tmp36_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp36_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp36_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp36_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp36_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST270 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_EXPRESSION);
		_t = _t->getFirstChild();
		{
		ast=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST270;
		_t = __t270;
		_t = _t->getNextSibling();
#line 1949 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pExpression = pModelicaXMLDoc->createElement(X("expression"));
					pExpression->appendChild(ast);
					ast = pExpression;
					/* ast = Absyn__CODE(Absyn__C_5fEXPRESSION(ast)); */
				
#line 7447 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_ELEMENT:
	{
		RefMyAST __t272 = _t;
		RefMyAST tmp37_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp37_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp37_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp37_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp37_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST272 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_ELEMENT);
		_t = _t->getFirstChild();
		{
		ast=element(_t,0 /* none */, pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST272;
		_t = __t272;
		_t = _t->getNextSibling();
#line 1958 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pElement = pModelicaXMLDoc->createElement(X("element"));
					pElement->appendChild(ast);
					ast = pElement;
					/* ast = Absyn__CODE(Absyn__C_5fELEMENT(ast)); */
				
#line 7480 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_EQUATION:
	{
		RefMyAST __t274 = _t;
		RefMyAST tmp38_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp38_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp38_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp38_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp38_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST274 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_EQUATION);
		_t = _t->getFirstChild();
		{
		ast=equation_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST274;
		_t = __t274;
		_t = _t->getNextSibling();
#line 1967 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
					pEquationSection->appendChild(ast);
					ast = pEquationSection;
					/* ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_FALSE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1)))); */
				
#line 7514 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_INITIALEQUATION:
	{
		RefMyAST __t276 = _t;
		RefMyAST tmp39_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp39_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp39_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp39_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp39_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST276 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_INITIALEQUATION);
		_t = _t->getFirstChild();
		{
		ast=equation_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST276;
		_t = __t276;
		_t = _t->getNextSibling();
#line 1977 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
					((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
					pEquationSection->appendChild(ast);
					ast = pEquationSection;
					/*
					ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_TRUE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 7551 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_ALGORITHM:
	{
		RefMyAST __t278 = _t;
		RefMyAST tmp40_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp40_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp40_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp40_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp40_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST278 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_ALGORITHM);
		_t = _t->getFirstChild();
		{
		ast=algorithm_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST278;
		_t = __t278;
		_t = _t->getNextSibling();
#line 1989 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pAlgorithmSection = pModelicaXMLDoc->createElement(X("algorithm_section"));
					pAlgorithmSection->appendChild(ast);
					ast = pAlgorithmSection;
					/*
					ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_FALSE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 7587 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_INITIALALGORITHM:
	{
		RefMyAST __t280 = _t;
		RefMyAST tmp41_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp41_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp41_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp41_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp41_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST280 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_INITIALALGORITHM);
		_t = _t->getFirstChild();
		{
		ast=algorithm_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST280;
		_t = __t280;
		_t = _t->getNextSibling();
#line 2000 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pAlgorithmSection = pModelicaXMLDoc->createElement(X("algorithm_section"));
					((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
					pAlgorithmSection->appendChild(ast);
					ast = pAlgorithmSection;
					/*
					ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_TRUE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 7624 "modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = code_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::elseif_expression(RefMyAST _t) {
#line 1866 "walker.g"
	DOMElement* ast;
#line 7641 "modelica_tree_parser.cpp"
	RefMyAST elseif_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST elseif_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1866 "walker.g"
	
		DOMElement* cond;
		DOMElement* thenPart;
	
#line 7653 "modelica_tree_parser.cpp"
	
	RefMyAST __t262 = _t;
	els = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST els_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	els_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(els));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(els_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST262 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEIF);
	_t = _t->getFirstChild();
	cond=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	thenPart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1873 "walker.g"
	
				DOMElement* pElseIf = pModelicaXMLDoc->createElement(X("elseif"));
	
				pElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
				pElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));
	
				pElseIf->appendChild(cond);
				DOMElement* pThen = pModelicaXMLDoc->createElement(X("then"));
				pThen->appendChild(thenPart);
				pElseIf->appendChild(pThen);
				ast = pElseIf;
			
#line 7684 "modelica_tree_parser.cpp"
	currentAST = __currentAST262;
	_t = __t262;
	_t = _t->getNextSibling();
	elseif_expression_AST = RefMyAST(currentAST.root);
	returnAST = elseif_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::logical_expression(RefMyAST _t) {
#line 2013 "walker.g"
	DOMElement* ast;
#line 7697 "modelica_tree_parser.cpp"
	RefMyAST logical_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2013 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 7709 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case DER:
	case END:
	case FALSE:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=logical_term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case OR:
	{
		RefMyAST __t284 = _t;
		o = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST o_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		o_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(o));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(o_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST284 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),OR);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=logical_term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST284;
		_t = __t284;
		_t = _t->getNextSibling();
#line 2021 "walker.g"
		
						DOMElement* pOr = pModelicaXMLDoc->createElement(X("or"));
		
						pOr->setAttribute(X("sline"), X(itoa(o->getLine(),stmp,10)));
						pOr->setAttribute(X("scolumn"), X(itoa(o->getColumn(),stmp,10)));
		
						pOr->appendChild(e1);
						pOr->appendChild(e2);
						ast = pOr;
					
#line 7789 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	logical_expression_AST = RefMyAST(currentAST.root);
	returnAST = logical_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::logical_term(RefMyAST _t) {
#line 2035 "walker.g"
	DOMElement* ast;
#line 7807 "modelica_tree_parser.cpp"
	RefMyAST logical_term_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_term_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2035 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 7819 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DER:
	case END:
	case FALSE:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=logical_factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case AND:
	{
		RefMyAST __t287 = _t;
		a = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST a_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		a_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(a));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(a_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST287 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),AND);
		_t = _t->getFirstChild();
		e1=logical_term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=logical_factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST287;
		_t = __t287;
		_t = _t->getNextSibling();
#line 2043 "walker.g"
		
						DOMElement* pAnd = pModelicaXMLDoc->createElement(X("and"));
		
						pAnd->setAttribute(X("sline"), X(itoa(a->getLine(),stmp,10)));
						pAnd->setAttribute(X("scolumn"), X(itoa(a->getColumn(),stmp,10)));
		
						pAnd->appendChild(e1);
						pAnd->appendChild(e2);
						ast = pAnd;
					
#line 7898 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	logical_term_AST = RefMyAST(currentAST.root);
	returnAST = logical_term_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::logical_factor(RefMyAST _t) {
#line 2056 "walker.g"
	DOMElement* ast;
#line 7916 "modelica_tree_parser.cpp"
	RefMyAST logical_factor_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST n = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST n_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case NOT:
	{
		RefMyAST __t289 = _t;
		n = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST n_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		n_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(n));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(n_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST289 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),NOT);
		_t = _t->getFirstChild();
		ast=relation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2059 "walker.g"
		
				DOMElement* pNot = pModelicaXMLDoc->createElement(X("not"));
		
				pNot->setAttribute(X("sline"), X(itoa(n->getLine(),stmp,10)));
				pNot->setAttribute(X("scolumn"), X(itoa(n->getColumn(),stmp,10)));
		
				pNot->appendChild(ast);
				ast = pNot;
			
#line 7952 "modelica_tree_parser.cpp"
		currentAST = __currentAST289;
		_t = __t289;
		_t = _t->getNextSibling();
		logical_factor_AST = RefMyAST(currentAST.root);
		break;
	}
	case DER:
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=relation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		logical_factor_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = logical_factor_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::relation(RefMyAST _t) {
#line 2070 "walker.g"
	DOMElement* ast;
#line 8013 "modelica_tree_parser.cpp"
	RefMyAST relation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST relation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lt = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lt_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lte = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lte_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST gt = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST gt_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST gte = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST gte_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ne = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ne_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2070 "walker.g"
	
		DOMElement* e1;
		DOMElement* op = 0;
		DOMElement* e2 = 0;
	
#line 8036 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DER:
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	{
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LESS:
		{
			RefMyAST __t293 = _t;
			lt = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST lt_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			lt_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lt));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lt_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST293 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LESS);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST293;
			_t = __t293;
			_t = _t->getNextSibling();
#line 2080 "walker.g"
			op = pModelicaXMLDoc->createElement(X("lt")); /* Absyn__LESS; */
#line 8110 "modelica_tree_parser.cpp"
			break;
		}
		case LESSEQ:
		{
			RefMyAST __t294 = _t;
			lte = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST lte_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			lte_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lte));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lte_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST294 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LESSEQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST294;
			_t = __t294;
			_t = _t->getNextSibling();
#line 2082 "walker.g"
			op = pModelicaXMLDoc->createElement(X("lte")); /* Absyn__LESSEQ; */
#line 8136 "modelica_tree_parser.cpp"
			break;
		}
		case GREATER:
		{
			RefMyAST __t295 = _t;
			gt = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST gt_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			gt_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(gt));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(gt_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST295 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),GREATER);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST295;
			_t = __t295;
			_t = _t->getNextSibling();
#line 2084 "walker.g"
			op = pModelicaXMLDoc->createElement(X("gt")); /* Absyn__GREATER; */
#line 8162 "modelica_tree_parser.cpp"
			break;
		}
		case GREATEREQ:
		{
			RefMyAST __t296 = _t;
			gte = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST gte_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			gte_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(gte));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(gte_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST296 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),GREATEREQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST296;
			_t = __t296;
			_t = _t->getNextSibling();
#line 2086 "walker.g"
			op = pModelicaXMLDoc->createElement(X("gte")); /* Absyn__GREATEREQ; */
#line 8188 "modelica_tree_parser.cpp"
			break;
		}
		case EQEQ:
		{
			RefMyAST __t297 = _t;
			eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST297 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQEQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST297;
			_t = __t297;
			_t = _t->getNextSibling();
#line 2088 "walker.g"
			op = pModelicaXMLDoc->createElement(X("eq")); /* Absyn__EQUAL; */
#line 8214 "modelica_tree_parser.cpp"
			break;
		}
		case LESSGT:
		{
			RefMyAST __t298 = _t;
			ne = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST ne_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			ne_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ne));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ne_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST298 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LESSGT);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			currentAST = __currentAST298;
			_t = __t298;
			_t = _t->getNextSibling();
#line 2090 "walker.g"
			op = pModelicaXMLDoc->createElement(X("ne")); /* op = Absyn__NEQUAL; */
#line 8240 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 2092 "walker.g"
		
						op->appendChild(e1);
						op->appendChild(e2);
						if (lt) { op->setAttribute(X("sline"), X(itoa(lt->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(lt->getColumn(),stmp,10))); }
						if (lte){ op->setAttribute(X("sline"), X(itoa(lte->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(lte->getColumn(),stmp,10)));	}
						if (gt) { op->setAttribute(X("sline"), X(itoa(gt->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(gt->getColumn(),stmp,10))); }
						if (gte){ op->setAttribute(X("sline"), X(itoa(gte->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(gte->getColumn(),stmp,10)));	}
						if (eq)	{ op->setAttribute(X("sline"), X(itoa(eq->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(eq->getColumn(),stmp,10))); }
						if (ne) { op->setAttribute(X("sline"), X(itoa(ne->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(ne->getColumn(),stmp,10))); }
						ast = op;
					
#line 8261 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	relation_AST = RefMyAST(currentAST.root);
	returnAST = relation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::arithmetic_expression(RefMyAST _t) {
#line 2106 "walker.g"
	DOMElement* ast;
#line 8279 "modelica_tree_parser.cpp"
	RefMyAST arithmetic_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST arithmetic_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2106 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 8297 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DER:
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case STAR:
	case SLASH:
	case POWER:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		ast=unary_arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case PLUS:
	{
		RefMyAST __t301 = _t;
		add = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST add_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		add_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(add));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(add_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST301 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PLUS);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST301;
		_t = __t301;
		_t = _t->getNextSibling();
#line 2114 "walker.g"
		
						DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));
						pAdd->setAttribute(X("sline"), X(itoa(add->getLine(),stmp,10)));
						pAdd->setAttribute(X("scolumn"), X(itoa(add->getColumn(),stmp,10)));
						pAdd->setAttribute(X("operation"), X("binary"));
						pAdd->appendChild(e1);
						pAdd->appendChild(e2);
						ast = pAdd;
					
#line 8364 "modelica_tree_parser.cpp"
		break;
	}
	case MINUS:
	{
		RefMyAST __t302 = _t;
		sub = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sub_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sub_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sub));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sub_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST302 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),MINUS);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST302;
		_t = __t302;
		_t = _t->getNextSibling();
#line 2124 "walker.g"
		
						DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
						pSub->setAttribute(X("sline"), X(itoa(sub->getLine(),stmp,10)));
						pSub->setAttribute(X("scolumn"), X(itoa(sub->getColumn(),stmp,10)));
						pSub->setAttribute(X("operation"), X("binary"));
						pSub->appendChild(e1);
						pSub->appendChild(e2);
						ast = pSub;
					
#line 8398 "modelica_tree_parser.cpp"
		break;
	}
	case PLUS_EW:
	{
		RefMyAST __t303 = _t;
		add_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST add_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		add_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(add_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(add_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST303 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PLUS_EW);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST303;
		_t = __t303;
		_t = _t->getNextSibling();
#line 2134 "walker.g"
		
						DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add_element_wise"));
						pAdd->setAttribute(X("sline"), X(itoa(add_ew->getLine(),stmp,10)));
						pAdd->setAttribute(X("scolumn"), X(itoa(add_ew->getColumn(),stmp,10)));
						pAdd->setAttribute(X("operation"), X("binary"));
						pAdd->appendChild(e1);
						pAdd->appendChild(e2);
						ast = pAdd;
					
#line 8432 "modelica_tree_parser.cpp"
		break;
	}
	case MINUS_EW:
	{
		RefMyAST __t304 = _t;
		sub_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sub_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sub_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sub_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sub_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST304 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),MINUS_EW);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST304;
		_t = __t304;
		_t = _t->getNextSibling();
#line 2144 "walker.g"
		
						DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub_element_wise"));
						pSub->setAttribute(X("sline"), X(itoa(sub_ew->getLine(),stmp,10)));
						pSub->setAttribute(X("scolumn"), X(itoa(sub_ew->getColumn(),stmp,10)));
						pSub->setAttribute(X("operation"), X("binary"));
						pSub->appendChild(e1);
						pSub->appendChild(e2);
						ast = pSub;
					
#line 8466 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	arithmetic_expression_AST = RefMyAST(currentAST.root);
	returnAST = arithmetic_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::unary_arithmetic_expression(RefMyAST _t) {
#line 2156 "walker.g"
	DOMElement* ast;
#line 8484 "modelica_tree_parser.cpp"
	RefMyAST unary_arithmetic_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST unary_arithmetic_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNARY_PLUS:
	{
		RefMyAST __t307 = _t;
		add = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST add_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		add_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(add));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(add_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST307 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNARY_PLUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST307;
		_t = __t307;
		_t = _t->getNextSibling();
#line 2160 "walker.g"
		
						DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));
						pAdd->setAttribute(X("sline"), X(itoa(add->getLine(),stmp,10)));
						pAdd->setAttribute(X("scolumn"), X(itoa(add->getColumn(),stmp,10)));
						pAdd->setAttribute(X("operation"), X("unary"));
						pAdd->appendChild(ast);
						ast = pAdd;
					
#line 8529 "modelica_tree_parser.cpp"
		break;
	}
	case UNARY_MINUS:
	{
		RefMyAST __t308 = _t;
		sub = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sub_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sub_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sub));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sub_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST308 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNARY_MINUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST308;
		_t = __t308;
		_t = _t->getNextSibling();
#line 2169 "walker.g"
		
						DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
						pSub->setAttribute(X("sline"), X(itoa(sub->getLine(),stmp,10)));
						pSub->setAttribute(X("scolumn"), X(itoa(sub->getColumn(),stmp,10)));
						pSub->setAttribute(X("operation"), X("unary"));
						pSub->appendChild(ast);
						ast = pSub;
					
#line 8559 "modelica_tree_parser.cpp"
		break;
	}
	case UNARY_PLUS_EW:
	{
		RefMyAST __t309 = _t;
		add_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST add_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		add_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(add_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(add_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST309 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNARY_PLUS_EW);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST309;
		_t = __t309;
		_t = _t->getNextSibling();
#line 2178 "walker.g"
		
						DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add_ement_wise"));
						pAdd->setAttribute(X("sline"), X(itoa(add_ew->getLine(),stmp,10)));
						pAdd->setAttribute(X("scolumn"), X(itoa(add_ew->getColumn(),stmp,10)));
						pAdd->setAttribute(X("operation"), X("unary"));
						pAdd->appendChild(ast);
						ast = pAdd;
					
#line 8589 "modelica_tree_parser.cpp"
		break;
	}
	case UNARY_MINUS_EW:
	{
		RefMyAST __t310 = _t;
		sub_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sub_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sub_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sub_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sub_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST310 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNARY_MINUS_EW);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST310;
		_t = __t310;
		_t = _t->getNextSibling();
#line 2187 "walker.g"
		
						DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub_elwment_wise"));
						pSub->setAttribute(X("sline"), X(itoa(sub_ew->getLine(),stmp,10)));
						pSub->setAttribute(X("scolumn"), X(itoa(sub_ew->getColumn(),stmp,10)));
						pSub->setAttribute(X("operation"), X("unary"));
						pSub->appendChild(ast);
						ast = pSub;
					
#line 8619 "modelica_tree_parser.cpp"
		break;
	}
	case DER:
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case STAR:
	case SLASH:
	case POWER:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	unary_arithmetic_expression_AST = RefMyAST(currentAST.root);
	returnAST = unary_arithmetic_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::term(RefMyAST _t) {
#line 2199 "walker.g"
	DOMElement* ast;
#line 8663 "modelica_tree_parser.cpp"
	RefMyAST term_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST term_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST mul = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST mul_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST div = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST div_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST mul_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST mul_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST div_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST div_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2199 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 8681 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DER:
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case POWER:
	case POWER_EW:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case STAR:
	{
		RefMyAST __t313 = _t;
		mul = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST mul_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		mul_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(mul));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(mul_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST313 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STAR);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST313;
		_t = __t313;
		_t = _t->getNextSibling();
#line 2208 "walker.g"
		
						DOMElement* pMul = pModelicaXMLDoc->createElement(X("mul"));
						pMul->setAttribute(X("sline"), X(itoa(mul->getLine(),stmp,10)));
						pMul->setAttribute(X("scolumn"), X(itoa(mul->getColumn(),stmp,10)));
						pMul->appendChild(e1);
						pMul->appendChild(e2);
						ast = pMul;
					
#line 8739 "modelica_tree_parser.cpp"
		break;
	}
	case SLASH:
	{
		RefMyAST __t314 = _t;
		div = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST div_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		div_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(div));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(div_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST314 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),SLASH);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST314;
		_t = __t314;
		_t = _t->getNextSibling();
#line 2217 "walker.g"
		
						DOMElement* pDiv = pModelicaXMLDoc->createElement(X("div"));
						pDiv->setAttribute(X("sline"), X(itoa(div->getLine(),stmp,10)));
						pDiv->setAttribute(X("scolumn"), X(itoa(div->getColumn(),stmp,10)));
						pDiv->appendChild(e1);
						pDiv->appendChild(e2);
						ast = pDiv;
					
#line 8772 "modelica_tree_parser.cpp"
		break;
	}
	case STAR_EW:
	{
		RefMyAST __t315 = _t;
		mul_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST mul_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		mul_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(mul_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(mul_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST315 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STAR_EW);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST315;
		_t = __t315;
		_t = _t->getNextSibling();
#line 2226 "walker.g"
		
						DOMElement* pMul = pModelicaXMLDoc->createElement(X("mul_element_wise"));
						pMul->setAttribute(X("sline"), X(itoa(mul_ew->getLine(),stmp,10)));
						pMul->setAttribute(X("scolumn"), X(itoa(mul_ew->getColumn(),stmp,10)));
						pMul->appendChild(e1);
						pMul->appendChild(e2);
						ast = pMul;
					
#line 8805 "modelica_tree_parser.cpp"
		break;
	}
	case SLASH_EW:
	{
		RefMyAST __t316 = _t;
		div_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST div_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		div_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(div_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(div_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST316 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),SLASH_EW);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=factor(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST316;
		_t = __t316;
		_t = _t->getNextSibling();
#line 2235 "walker.g"
		
						DOMElement* pDiv = pModelicaXMLDoc->createElement(X("div_element_wise"));
						pDiv->setAttribute(X("sline"), X(itoa(div_ew->getLine(),stmp,10)));
						pDiv->setAttribute(X("scolumn"), X(itoa(div_ew->getColumn(),stmp,10)));
						pDiv->appendChild(e1);
						pDiv->appendChild(e2);
						ast = pDiv;
					
#line 8838 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	term_AST = RefMyAST(currentAST.root);
	returnAST = term_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::factor(RefMyAST _t) {
#line 2246 "walker.g"
	DOMElement* ast;
#line 8856 "modelica_tree_parser.cpp"
	RefMyAST factor_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST pw = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST pw_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST pw_ew = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST pw_ew_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2246 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 8870 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DER:
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=primary(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case POWER:
	{
		RefMyAST __t319 = _t;
		pw = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST pw_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		pw_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(pw));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(pw_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST319 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),POWER);
		_t = _t->getFirstChild();
		e1=primary(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=primary(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST319;
		_t = __t319;
		_t = _t->getNextSibling();
#line 2255 "walker.g"
		
						DOMElement* pPow = pModelicaXMLDoc->createElement(X("pow"));
		
						pPow->setAttribute(X("sline"), X(itoa(pw->getLine(),stmp,10)));
						pPow->setAttribute(X("scolumn"), X(itoa(pw->getColumn(),stmp,10)));
		
						pPow->appendChild(e1);
						pPow->appendChild(e2);
						ast = pPow;
					
#line 8928 "modelica_tree_parser.cpp"
		break;
	}
	case POWER_EW:
	{
		RefMyAST __t320 = _t;
		pw_ew = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST pw_ew_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		pw_ew_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(pw_ew));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(pw_ew_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST320 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),POWER_EW);
		_t = _t->getFirstChild();
		e1=primary(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		e2=primary(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST320;
		_t = __t320;
		_t = _t->getNextSibling();
#line 2266 "walker.g"
		
						DOMElement* pPow = pModelicaXMLDoc->createElement(X("pow_element_wise"));
		
						pPow->setAttribute(X("sline"), X(itoa(pw_ew->getLine(),stmp,10)));
						pPow->setAttribute(X("scolumn"), X(itoa(pw_ew->getColumn(),stmp,10)));
		
						pPow->appendChild(e1);
						pPow->appendChild(e2);
						ast = pPow;
					
#line 8963 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	factor_AST = RefMyAST(currentAST.root);
	returnAST = factor_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::primary(RefMyAST _t) {
#line 2279 "walker.g"
	DOMElement* ast;
#line 8981 "modelica_tree_parser.cpp"
	RefMyAST primary_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST primary_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ui = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ui_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ur = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ur_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST str = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST str_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST t = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST t_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST d = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST d_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbr = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbr_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tend = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tend_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2279 "walker.g"
	
		l_stack* el_stack = new l_stack;
		DOMElement* e;
		DOMElement* exp = 0;
		DOMElement* pSemicolon = pModelicaXMLDoc->createElement(X("semicolon"));
	
#line 9011 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNSIGNED_INTEGER:
	{
		ui = _t;
		RefMyAST ui_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		ui_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ui));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ui_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNSIGNED_INTEGER);
		_t = _t->getNextSibling();
#line 2288 "walker.g"
		
						DOMElement* pIntegerLiteral = pModelicaXMLDoc->createElement(X("integer_literal"));
						pIntegerLiteral->setAttribute(X("value"), str2xml(ui));
		
						pIntegerLiteral->setAttribute(X("sline"), X(itoa(ui->getLine(),stmp,10)));
						pIntegerLiteral->setAttribute(X("scolumn"), X(itoa(ui->getColumn(),stmp,10)));
		
						ast = pIntegerLiteral;
					
#line 9035 "modelica_tree_parser.cpp"
		break;
	}
	case UNSIGNED_REAL:
	{
		ur = _t;
		RefMyAST ur_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		ur_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ur));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ur_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNSIGNED_REAL);
		_t = _t->getNextSibling();
#line 2298 "walker.g"
		
						DOMElement* pRealLiteral = pModelicaXMLDoc->createElement(X("real_literal"));
						pRealLiteral->setAttribute(X("value"), str2xml(ur));
		
						pRealLiteral->setAttribute(X("sline"), X(itoa(ur->getLine(),stmp,10)));
						pRealLiteral->setAttribute(X("scolumn"), X(itoa(ur->getColumn(),stmp,10)));
		
						ast = pRealLiteral;
					
#line 9056 "modelica_tree_parser.cpp"
		break;
	}
	case STRING:
	{
		str = _t;
		RefMyAST str_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		str_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(str));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(str_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STRING);
		_t = _t->getNextSibling();
#line 2308 "walker.g"
		
						DOMElement* pStringLiteral = pModelicaXMLDoc->createElement(X("string_literal"));
						pStringLiteral->setAttribute(X("value"), str2xml(str));
		
						pStringLiteral->setAttribute(X("sline"), X(itoa(str->getLine(),stmp,10)));
						pStringLiteral->setAttribute(X("scolumn"), X(itoa(str->getColumn(),stmp,10)));
		
						ast = pStringLiteral;
					
#line 9077 "modelica_tree_parser.cpp"
		break;
	}
	case FALSE:
	{
		f = _t;
		RefMyAST f_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		f_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(f));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(f_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FALSE);
		_t = _t->getNextSibling();
#line 2318 "walker.g"
		
					DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
					pBoolLiteral->setAttribute(X("value"), X("false"));
		
					pBoolLiteral->setAttribute(X("sline"), X(itoa(f->getLine(),stmp,10)));
					pBoolLiteral->setAttribute(X("scolumn"), X(itoa(f->getColumn(),stmp,10)));
		
					ast = pBoolLiteral;
				
#line 9098 "modelica_tree_parser.cpp"
		break;
	}
	case TRUE:
	{
		t = _t;
		RefMyAST t_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		t_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(t));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(t_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),TRUE);
		_t = _t->getNextSibling();
#line 2328 "walker.g"
		
					DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
					pBoolLiteral->setAttribute(X("value"), X("true"));
		
					pBoolLiteral->setAttribute(X("sline"), X(itoa(t->getLine(),stmp,10)));
					pBoolLiteral->setAttribute(X("scolumn"), X(itoa(t->getColumn(),stmp,10)));
		
					ast = pBoolLiteral;
				
#line 9119 "modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	case IDENT:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=component_reference__function_call(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case DER:
	{
		RefMyAST __t323 = _t;
		d = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST d_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		d_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(d));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(d_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST323 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DER);
		_t = _t->getFirstChild();
		e=function_call(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST323;
		_t = __t323;
		_t = _t->getNextSibling();
#line 2339 "walker.g"
		
						DOMElement* pDer = pModelicaXMLDoc->createElement(X("der"));
						pDer->setAttribute(X("sline"), X(itoa(d->getLine(),stmp,10)));
						pDer->setAttribute(X("scolumn"), X(itoa(d->getColumn(),stmp,10)));
						pDer->appendChild(e);
						ast = pDer;
		
#line 9158 "modelica_tree_parser.cpp"
		break;
	}
	case LPAR:
	{
		RefMyAST __t324 = _t;
		RefMyAST tmp42_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp42_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp42_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp42_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp42_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST324 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LPAR);
		_t = _t->getFirstChild();
		ast=tuple_expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST324;
		_t = __t324;
		_t = _t->getNextSibling();
		break;
	}
	case LBRACK:
	{
		RefMyAST __t325 = _t;
		lbk = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST lbk_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		lbk_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lbk));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lbk_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST325 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LBRACK);
		_t = _t->getFirstChild();
		e=expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2347 "walker.g"
		el_stack->push_back(e);
#line 9199 "modelica_tree_parser.cpp"
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			if ((_t->getType() == EXPRESSION_LIST)) {
				e=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2348 "walker.g"
				el_stack->push_back(e);
#line 9210 "modelica_tree_parser.cpp"
			}
			else {
				goto _loop327;
			}
			
		}
		_loop327:;
		} // ( ... )*
		currentAST = __currentAST325;
		_t = __t325;
		_t = _t->getNextSibling();
#line 2349 "walker.g"
		
						DOMElement* pConcat = pModelicaXMLDoc->createElement(X("concat"));
		
						pConcat->setAttribute(X("sline"), X(itoa(lbk->getLine(),stmp,10)));
						pConcat->setAttribute(X("scolumn"), X(itoa(lbk->getColumn(),stmp,10)));
		
						pConcat = (DOMElement*)appendKidsFromStack(el_stack, pConcat);
						//if (el_stack) delete el_stack;
						ast = pConcat;
					
#line 9233 "modelica_tree_parser.cpp"
		break;
	}
	case LBRACE:
	{
		RefMyAST __t328 = _t;
		lbr = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST lbr_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		lbr_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lbr));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lbr_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST328 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LBRACE);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXPRESSION_LIST:
		{
			{
			ast=expression_list(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			break;
		}
		case FOR_ITERATOR:
		{
			RefMyAST __t331 = _t;
			RefMyAST tmp43_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp43_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp43_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp43_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp43_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST331 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR_ITERATOR);
			_t = _t->getFirstChild();
			{
			ast=for_iterator(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			currentAST = __currentAST331;
			_t = __t331;
			_t = _t->getNextSibling();
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST328;
		_t = __t328;
		_t = _t->getNextSibling();
#line 2361 "walker.g"
		
					/* was before: ast = function_arguments */
					DOMElement* pArray = pModelicaXMLDoc->createElement(X("array"));
		
					pArray->setAttribute(X("sline"), X(itoa(lbr->getLine(),stmp,10)));
					pArray->setAttribute(X("scolumn"), X(itoa(lbr->getColumn(),stmp,10)));
		
					if (!exp) pArray->appendChild(ast);
					else
					{
						DOMElement* pFargs = pModelicaXMLDoc->createElement(X("function_arguments"));
						pFargs->appendChild(exp);
						pFargs->appendChild(ast);
						pArray->appendChild(pFargs);
					}
					ast = pArray;
				
#line 9311 "modelica_tree_parser.cpp"
		break;
	}
	case END:
	{
		tend = _t;
		RefMyAST tend_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tend_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(tend));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tend_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),END);
		_t = _t->getNextSibling();
#line 2379 "walker.g"
		
					DOMElement* pEnd = pModelicaXMLDoc->createElement(X("end"));
					pEnd->setAttribute(X("sline"), X(itoa(tend->getLine(),stmp,10)));
					pEnd->setAttribute(X("scolumn"), X(itoa(tend->getColumn(),stmp,10)));
					ast = pEnd;
				
#line 9329 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	primary_AST = RefMyAST(currentAST.root);
	returnAST = primary_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::component_reference__function_call(RefMyAST _t) {
#line 2388 "walker.g"
	DOMElement* ast;
#line 9347 "modelica_tree_parser.cpp"
	RefMyAST component_reference__function_call_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_reference__function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fc = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fc_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ifc = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ifc_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2388 "walker.g"
	
		DOMElement* cref;
		DOMElement* fnc = 0;
	
#line 9363 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	case FUNCTION_CALL:
	{
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FUNCTION_CALL:
		{
			RefMyAST __t335 = _t;
			fc = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST fc_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			fc_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(fc));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(fc_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST335 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FUNCTION_CALL);
			_t = _t->getFirstChild();
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case FUNCTION_ARGUMENTS:
			{
				fnc=function_call(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			}
			}
			}
			currentAST = __currentAST335;
			_t = __t335;
			_t = _t->getNextSibling();
#line 2395 "walker.g"
			
							DOMElement* pCall = pModelicaXMLDoc->createElement(X("call"));
			
							pCall->setAttribute(X("sline"), X(itoa(fc->getLine(),stmp,10)));
							pCall->setAttribute(X("scolumn"), X(itoa(fc->getColumn(),stmp,10)));
			
							pCall->appendChild(cref);
							if (fnc) pCall->appendChild(fnc);
							ast = pCall;
						
#line 9426 "modelica_tree_parser.cpp"
			break;
		}
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2406 "walker.g"
			
							if (fnc && cref) cref->appendChild(fnc);
							ast = cref;
						
#line 9440 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		component_reference__function_call_AST = RefMyAST(currentAST.root);
		break;
	}
	case INITIAL_FUNCTION_CALL:
	{
		RefMyAST __t337 = _t;
		ifc = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST ifc_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		ifc_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ifc));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ifc_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST337 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INITIAL_FUNCTION_CALL);
		_t = _t->getFirstChild();
		i = _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INITIAL);
		_t = _t->getNextSibling();
		currentAST = __currentAST337;
		_t = __t337;
		_t = _t->getNextSibling();
#line 2413 "walker.g"
		
						// calling function initial
						DOMElement* pCall = pModelicaXMLDoc->createElement(X("call"));
		
						DOMElement* pCref = pModelicaXMLDoc->createElement(X("component_reference"));
						pCref->setAttribute(X("ident"), X("initial"));
						pCref->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
						pCref->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
		
						pCall->appendChild(pCref);
		
						pCall->setAttribute(X("sline"), X(itoa(ifc->getLine(),stmp,10)));
						pCall->setAttribute(X("scolumn"), X(itoa(ifc->getColumn(),stmp,10)));
		
						ast = pCall;
					
#line 9490 "modelica_tree_parser.cpp"
		component_reference__function_call_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = component_reference__function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::function_arguments(RefMyAST _t) {
#line 2512 "walker.g"
	DOMElement* ast;
#line 9507 "modelica_tree_parser.cpp"
	RefMyAST function_arguments_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST function_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2512 "walker.g"
	
		l_stack el_stack;
		DOMElement* e=0;
		DOMElement* namel=0;
		DOMElement *pFunctionArguments = pModelicaXMLDoc->createElement(X("function_arguments"));
	
#line 9519 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case 3:
	case EXPRESSION_LIST:
	case NAMED_ARGUMENTS:
	{
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXPRESSION_LIST:
		{
			pFunctionArguments=expression_list2(_t,pFunctionArguments);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		case NAMED_ARGUMENTS:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case NAMED_ARGUMENTS:
		{
			pFunctionArguments=named_arguments(_t,pFunctionArguments);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 2523 "walker.g"
		
					ast = pFunctionArguments;
			
#line 9576 "modelica_tree_parser.cpp"
		break;
	}
	case FOR_ITERATOR:
	{
		RefMyAST __t358 = _t;
		RefMyAST tmp44_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp44_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp44_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp44_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp44_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST358 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR_ITERATOR);
		_t = _t->getFirstChild();
		ast=for_iterator(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST358;
		_t = __t358;
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	function_arguments_AST = RefMyAST(currentAST.root);
	returnAST = function_arguments_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::expression_list2(RefMyAST _t,
	DOMElement *parent
) {
#line 2492 "walker.g"
	DOMElement* ast;
#line 9617 "modelica_tree_parser.cpp"
	RefMyAST expression_list2_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2492 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
	
#line 9629 "modelica_tree_parser.cpp"
	
	{
	RefMyAST __t351 = _t;
	el = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST el_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	el_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(el));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST351 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2499 "walker.g"
	parent->appendChild(e);
#line 9647 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2500 "walker.g"
			parent->appendChild(e);
#line 9658 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop353;
		}
		
	}
	_loop353:;
	} // ( ... )*
	currentAST = __currentAST351;
	_t = __t351;
	_t = _t->getNextSibling();
	}
#line 2503 "walker.g"
	
				ast = parent;
			
#line 9675 "modelica_tree_parser.cpp"
	expression_list2_AST = RefMyAST(currentAST.root);
	returnAST = expression_list2_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::named_arguments(RefMyAST _t,
	DOMElement *parent
) {
#line 2533 "walker.g"
	DOMElement* ast;
#line 9687 "modelica_tree_parser.cpp"
	RefMyAST named_arguments_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST na = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST na_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2533 "walker.g"
	
		l_stack el_stack;
		DOMElement* n;
	
#line 9699 "modelica_tree_parser.cpp"
	
	RefMyAST __t360 = _t;
	na = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST na_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	na_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(na));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(na_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST360 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),NAMED_ARGUMENTS);
	_t = _t->getFirstChild();
	{
	n=named_argument(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2539 "walker.g"
	parent->appendChild(n);
#line 9717 "modelica_tree_parser.cpp"
	}
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == EQUALS)) {
			n=named_argument(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2540 "walker.g"
			parent->appendChild(n);
#line 9729 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop363;
		}
		
	}
	_loop363:;
	} // ( ... )*
	currentAST = __currentAST360;
	_t = __t360;
	_t = _t->getNextSibling();
#line 2541 "walker.g"
	
				ast = parent;
			
#line 9745 "modelica_tree_parser.cpp"
	named_arguments_AST = RefMyAST(currentAST.root);
	returnAST = named_arguments_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::named_argument(RefMyAST _t) {
#line 2546 "walker.g"
	DOMElement* ast;
#line 9755 "modelica_tree_parser.cpp"
	RefMyAST named_argument_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2546 "walker.g"
	
		DOMElement* temp;
	
#line 9768 "modelica_tree_parser.cpp"
	
	RefMyAST __t365 = _t;
	eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST365 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
	_t = _t->getFirstChild();
	i = _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getNextSibling();
	temp=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST365;
	_t = __t365;
	_t = _t->getNextSibling();
#line 2552 "walker.g"
	
				DOMElement *pNamedArgument = pModelicaXMLDoc->createElement(X("named_argument"));
				pNamedArgument->setAttribute(X("ident"), str2xml(i));
	
				pNamedArgument->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pNamedArgument->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				pNamedArgument->appendChild(temp);
				ast = pNamedArgument;
			
#line 9803 "modelica_tree_parser.cpp"
	named_argument_AST = RefMyAST(currentAST.root);
	returnAST = named_argument_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::subscript(RefMyAST _t,
	DOMElement* parent
) {
#line 2638 "walker.g"
	DOMElement* ast;
#line 9815 "modelica_tree_parser.cpp"
	RefMyAST subscript_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST subscript_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2638 "walker.g"
	
		DOMElement* e;
		DOMElement* pColon = pModelicaXMLDoc->createElement(X("colon"));
	
#line 9827 "modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case DER:
	case END:
	case FALSE:
	case IF:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case DOT:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case POWER:
	case PLUS_EW:
	case MINUS_EW:
	case STAR_EW:
	case SLASH_EW:
	case POWER_EW:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case CODE_EXPRESSION:
	case CODE_MODIFICATION:
	case CODE_ELEMENT:
	case CODE_EQUATION:
	case CODE_INITIALEQUATION:
	case CODE_ALGORITHM:
	case CODE_INITIALALGORITHM:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case RANGE2:
	case RANGE3:
	case UNARY_MINUS:
	case UNARY_PLUS:
	case UNARY_MINUS_EW:
	case UNARY_PLUS_EW:
	{
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2646 "walker.g"
		
						parent->appendChild(e);
						ast = parent;
					
#line 9889 "modelica_tree_parser.cpp"
		break;
	}
	case COLON:
	{
		c = _t;
		RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),COLON);
		_t = _t->getNextSibling();
#line 2651 "walker.g"
		
		
						pColon->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
						pColon->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
		
						parent->appendChild(pColon);
						ast = parent;
					
#line 9909 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	subscript_AST = RefMyAST(currentAST.root);
	returnAST = subscript_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::string_concatenation(RefMyAST _t) {
#line 2704 "walker.g"
	DOMElement* ast;
#line 9927 "modelica_tree_parser.cpp"
	RefMyAST string_concatenation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST string_concatenation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2704 "walker.g"
	
			DOMElement*pString1;
			l_stack el_stack;
		
#line 9943 "modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING:
	{
		s = _t;
		RefMyAST s_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		s_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(s));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STRING);
		_t = _t->getNextSibling();
#line 2711 "walker.g"
		
					DOMElement *pString = pModelicaXMLDoc->createElement(X("string_literal"));
					pString->setAttribute(X("value"), str2xml(s));
		
					pString->setAttribute(X("sline"), X(itoa(s->getLine(),stmp,10)));
					pString->setAttribute(X("scolumn"), X(itoa(s->getColumn(),stmp,10)));
		
			  		ast=pString;
				
#line 9966 "modelica_tree_parser.cpp"
		string_concatenation_AST = RefMyAST(currentAST.root);
		break;
	}
	case PLUS:
	{
		RefMyAST __t388 = _t;
		p = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST388 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PLUS);
		_t = _t->getFirstChild();
		pString1=string_concatenation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		s2 = _t;
		RefMyAST s2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		s2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(s2));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s2_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STRING);
		_t = _t->getNextSibling();
		currentAST = __currentAST388;
		_t = __t388;
		_t = _t->getNextSibling();
#line 2721 "walker.g"
		
					 DOMElement *pString = pModelicaXMLDoc->createElement(X("add_string"));
		
					 pString->setAttribute(X("sline"), X(itoa(p->getLine(),stmp,10)));
					 pString->setAttribute(X("scolumn"), X(itoa(p->getColumn(),stmp,10)));
		
					 pString->appendChild(pString1);
					 DOMElement *pString2 = pModelicaXMLDoc->createElement(X("string_literal"));
					 pString2->setAttribute(X("value"), str2xml(s2));
		
					 pString2->setAttribute(X("sline"), X(itoa(s2->getLine(),stmp,10)));
					 pString2->setAttribute(X("scolumn"), X(itoa(s2->getColumn(),stmp,10)));
		
					 pString->appendChild(pString2);
					 ast=pString;
				
#line 10011 "modelica_tree_parser.cpp"
		string_concatenation_AST = RefMyAST(currentAST.root);
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	returnAST = string_concatenation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  modelica_tree_parser::interactive_stmt(RefMyAST _t) {
#line 2781 "walker.g"
	DOMElement* ast;
#line 10028 "modelica_tree_parser.cpp"
	RefMyAST interactive_stmt_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST interactive_stmt_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2781 "walker.g"
	
	DOMElement* al=0;
	DOMElement* el=0;
		l_stack el_stack;
	DOMElement *pInteractiveSTMT = pModelicaXMLDoc->createElement(X("ISTMT"));
		DOMElement *pInteractiveALG = pModelicaXMLDoc->createElement(X("IALG"));
	
#line 10043 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INTERACTIVE_ALG:
		{
			RefMyAST __t393 = _t;
			RefMyAST tmp45_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp45_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp45_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp45_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp45_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST393 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INTERACTIVE_ALG);
			_t = _t->getFirstChild();
			{
			pInteractiveALG=algorithm(_t,pInteractiveALG);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			currentAST = __currentAST393;
			_t = __t393;
			_t = _t->getNextSibling();
#line 2792 "walker.g"
			
							//pInteractiveALG->appendChild(al);
							el_stack.push_back(pInteractiveALG);
						
#line 10076 "modelica_tree_parser.cpp"
			break;
		}
		case INTERACTIVE_EXP:
		{
			RefMyAST __t395 = _t;
			RefMyAST tmp46_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp46_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp46_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp46_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp46_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST395 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INTERACTIVE_EXP);
			_t = _t->getFirstChild();
			{
			el=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			currentAST = __currentAST395;
			_t = __t395;
			_t = _t->getNextSibling();
#line 2798 "walker.g"
			
							DOMElement *pInteractiveEXP = pModelicaXMLDoc->createElement(X("IEXP"));
							pInteractiveEXP->appendChild(el);
							el_stack.push_back(pInteractiveEXP);
						
#line 10106 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			goto _loop397;
		}
		}
	}
	_loop397:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case SEMICOLON:
	{
		s = _t;
		RefMyAST s_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		s_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(s));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(s_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),SEMICOLON);
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 2805 "walker.g"
	
				pInteractiveSTMT = (DOMElement*)appendKids(el_stack, pInteractiveSTMT);
				if (s) pInteractiveSTMT->setAttribute(X("semicolon"),X("true"));
				ast = pInteractiveSTMT;
			
#line 10147 "modelica_tree_parser.cpp"
	interactive_stmt_AST = RefMyAST(currentAST.root);
	returnAST = interactive_stmt_AST;
	_retTree = _t;
	return ast;
}

void modelica_tree_parser::initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory )
{
	factory.setMaxNodeType(156);
}
const char* modelica_tree_parser::tokenNames[] = {
	"<0>",
	"EOF",
	"<2>",
	"NULL_TREE_LOOKAHEAD",
	"\"algorithm\"",
	"\"and\"",
	"\"annotation\"",
	"\"block\"",
	"\"Code\"",
	"\"class\"",
	"\"connect\"",
	"\"connector\"",
	"\"constant\"",
	"\"discrete\"",
	"\"der\"",
	"\"each\"",
	"\"else\"",
	"\"elseif\"",
	"\"elsewhen\"",
	"\"end\"",
	"\"enumeration\"",
	"\"equation\"",
	"\"encapsulated\"",
	"\"expandable\"",
	"\"extends\"",
	"\"external\"",
	"\"false\"",
	"\"final\"",
	"\"flow\"",
	"\"for\"",
	"\"function\"",
	"\"if\"",
	"\"import\"",
	"\"in\"",
	"\"initial\"",
	"\"inner\"",
	"\"input\"",
	"\"loop\"",
	"\"model\"",
	"\"not\"",
	"\"outer\"",
	"\"overload\"",
	"\"or\"",
	"\"output\"",
	"\"package\"",
	"\"parameter\"",
	"\"partial\"",
	"\"protected\"",
	"\"public\"",
	"\"record\"",
	"\"redeclare\"",
	"\"replaceable\"",
	"\"results\"",
	"\"then\"",
	"\"true\"",
	"\"type\"",
	"\"unsigned_real\"",
	"\".\"",
	"\"when\"",
	"\"while\"",
	"\"within\"",
	"\"constrainedby\"",
	"\"return\"",
	"\"break\"",
	"\"stream\"",
	"LPAR",
	"RPAR",
	"LBRACK",
	"RBRACK",
	"LBRACE",
	"RBRACE",
	"EQUALS",
	"ASSIGN",
	"PLUS",
	"MINUS",
	"STAR",
	"SLASH",
	"POWER",
	"PLUS_EW",
	"MINUS_EW",
	"STAR_EW",
	"SLASH_EW",
	"POWER_EW",
	"COMMA",
	"LESS",
	"LESSEQ",
	"GREATER",
	"GREATEREQ",
	"EQEQ",
	"LESSGT",
	"COLON",
	"SEMICOLON",
	"WS",
	"ML_COMMENT",
	"ML_COMMENT_CHAR",
	"SL_COMMENT",
	"an identifier",
	"an identifier",
	"NONDIGIT",
	"DIGIT",
	"EXPONENT",
	"UNSIGNED_INTEGER",
	"STRING",
	"SCHAR",
	"QCHAR",
	"SESCAPE",
	"ESC",
	"ALGORITHM_STATEMENT",
	"ARGUMENT_LIST",
	"BEGIN_DEFINITION",
	"CLASS_DEFINITION",
	"CLASS_EXTENDS",
	"CLASS_MODIFICATION",
	"CODE_EXPRESSION",
	"CODE_MODIFICATION",
	"CODE_ELEMENT",
	"CODE_EQUATION",
	"CODE_INITIALEQUATION",
	"CODE_ALGORITHM",
	"CODE_INITIALALGORITHM",
	"COMMENT",
	"COMPONENT_DEFINITION",
	"DECLARATION",
	"DEFINITION",
	"END_DEFINITION",
	"ENUMERATION_LITERAL",
	"ELEMENT",
	"ELEMENT_MODIFICATION",
	"ELEMENT_REDECLARATION",
	"EQUATION_STATEMENT",
	"EXTERNAL_ANNOTATION",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"IMPORT_DEFINITION",
	"IDENT_LIST",
	"EXPRESSION_LIST",
	"EXTERNAL_FUNCTION_CALL",
	"FOR_INDICES",
	"FOR_ITERATOR",
	"FUNCTION_CALL",
	"INITIAL_FUNCTION_CALL",
	"FUNCTION_ARGUMENTS",
	"NAMED_ARGUMENTS",
	"QUALIFIED",
	"RANGE2",
	"RANGE3",
	"STORED_DEFINITION",
	"STRING_COMMENT",
	"UNARY_MINUS",
	"UNARY_PLUS",
	"UNARY_MINUS_EW",
	"UNARY_PLUS_EW",
	"UNQUALIFIED",
	"INTERACTIVE_STMT",
	"INTERACTIVE_ALG",
	"INTERACTIVE_EXP",
	"REDELCARE",
	0
};

const unsigned long modelica_tree_parser::_tokenSet_0_data_[] = { 2097168UL, 98304UL, 0UL, 0UL, 24UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "equation" "protected" "public" INITIAL_EQUATION INITIAL_ALGORITHM 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_tree_parser::_tokenSet_0(_tokenSet_0_data_,12);
const unsigned long modelica_tree_parser::_tokenSet_1_data_[] = { 2215133216UL, 54527104UL, 133692970UL, 16646241UL, 15931392UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "der" "end" "false" "if" "not" "or" "true" "unsigned_real" "." 
// LPAR LBRACK LBRACE PLUS MINUS STAR SLASH POWER PLUS_EW MINUS_EW STAR_EW 
// SLASH_EW POWER_EW LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT COLON IDENT 
// UNSIGNED_INTEGER STRING CODE_EXPRESSION CODE_MODIFICATION CODE_ELEMENT 
// CODE_EQUATION CODE_INITIALEQUATION CODE_ALGORITHM CODE_INITIALALGORITHM 
// FUNCTION_CALL INITIAL_FUNCTION_CALL RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
// UNARY_MINUS_EW UNARY_PLUS_EW 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_tree_parser::_tokenSet_1(_tokenSet_1_data_,12);
const unsigned long modelica_tree_parser::_tokenSet_2_data_[] = { 2215133216UL, 54527104UL, 66584106UL, 16646241UL, 15931392UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "der" "end" "false" "if" "not" "or" "true" "unsigned_real" "." 
// LPAR LBRACK LBRACE PLUS MINUS STAR SLASH POWER PLUS_EW MINUS_EW STAR_EW 
// SLASH_EW POWER_EW LESS LESSEQ GREATER GREATEREQ EQEQ LESSGT IDENT UNSIGNED_INTEGER 
// STRING CODE_EXPRESSION CODE_MODIFICATION CODE_ELEMENT CODE_EQUATION 
// CODE_INITIALEQUATION CODE_ALGORITHM CODE_INITIALALGORITHM FUNCTION_CALL 
// INITIAL_FUNCTION_CALL RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS UNARY_MINUS_EW 
// UNARY_PLUS_EW 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_tree_parser::_tokenSet_2(_tokenSet_2_data_,12);


