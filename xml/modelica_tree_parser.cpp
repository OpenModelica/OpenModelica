/* $ANTLR 2.7.2: "walker.g" -> "modelica_tree_parser.cpp"$ */
#include "modelica_tree_parser.hpp"
#include <antlr/Token.hpp>
#include <antlr/AST.hpp>
#include <antlr/NoViableAltException.hpp>
#include <antlr/MismatchedTokenException.hpp>
#include <antlr/SemanticException.hpp>
#include <antlr/BitSet.hpp>
#line 43 "walker.g"


#line 13 "modelica_tree_parser.cpp"
#line 1 "walker.g"
#line 15 "modelica_tree_parser.cpp"
modelica_tree_parser::modelica_tree_parser()
	: ANTLR_USE_NAMESPACE(antlr)TreeParser() {
}

DOMNode * modelica_tree_parser::stored_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	mstring filename
) {
#line 192 "walker.g"
	DOMNode *ast;
#line 25 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST stored_definition_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST stored_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 192 "walker.g"
	
	DOMNode *within = 0;
	DOMNode *class_def = 0;
	l_stack el_stack;
	
		// initialize xml framework
	XMLPlatformUtils::Initialize();
	
	// XML DOM creation
	DOMImplementation* pDOMImpl = DOMImplementationRegistry::getDOMImplementation(X("Core"));
	
	
	// create the document type (according to modelica.dtd)
	DOMDocumentType* pDoctype = pDOMImpl->createDocumentType(
			 X("modelica"), 
			 NULL, 
			 X("http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.dtd"));
	
	// create the <program> root element 
	pModelicaXMLDoc = pDOMImpl->createDocument(
	0,                    // root element namespace URI.
	X("modelica"),         // root element name
	pDoctype);                   // document type object (DTD).
	
	pRootElementModelica = pModelicaXMLDoc->getDocumentElement();
		pRootElementModelicaXML = pModelicaXMLDoc->createElement(X("modelicaxml"));
		// define some widely use constructs
		pColon = pModelicaXMLDoc->createElement(X("colon"));
		pSemiColon = pModelicaXMLDoc->createElement(X("semicolon"));
	
	
#line 64 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t2 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp1_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp1_AST = astFactory->create(_t);
	tmp1_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp1_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST2 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,STORED_DEFINITION);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case WITHIN:
	{
		within=within_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == FINAL || _t->getType() == CLASS_DEFINITION)) {
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case FINAL:
			{
				f = _t;
				ANTLR_USE_NAMESPACE(antlr)RefAST f_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
				f_AST = astFactory->create(f);
				astFactory->addASTChild(currentAST, f_AST);
				match(_t,FINAL);
				_t = _t->getNextSibling();
				break;
			}
			case CLASS_DEFINITION:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			class_def=class_definition(_t,f != NULL);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 229 "walker.g"
			
			if (class_def)
			{   
			el_stack.push(class_def);
			}
			
#line 139 "modelica_tree_parser.cpp"
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
#line 237 "walker.g"
	
	if (within != 0) 
				{ 
					// set within attribute
					pRootElementModelicaXML->appendChild(within);
				}
	
				pRootElementModelicaXML = (DOMElement*)appendKids(el_stack, pRootElementModelicaXML);
				pRootElementModelica->appendChild(pRootElementModelicaXML);
	ast = pRootElementModelica;
	
				unsigned int elementCount = pModelicaXMLDoc->getElementsByTagName(X("*"))->getLength();
				std::cout << std::endl;
		        std::cout << "The tree just created contains: " << elementCount
		        << " elements." << std::endl;
	
		        // create the writer
				DOMWriter* domWriter = pDOMImpl->createDOMWriter();
				// set the pretty print feature
				if (domWriter->canSetFeature(XMLUni::fgDOMWRTFormatPrettyPrint, true))
					 domWriter->setFeature(XMLUni::fgDOMWRTFormatPrettyPrint, true);
				// fix the file
				
				XMLFormatTarget *myFormatTarget = new LocalFileFormatTarget(X(filename.c_str()));
				//XMLFormatTarget *myOutFormatTarget = new StdOutFormatTarget;
	
				// serialize a DOMNode to the local file "
				domWriter->writeNode(myFormatTarget, *pModelicaXMLDoc);
				//domWriter->writeNode(myOutFormatTarget, *pModelicaXMLDoc);
		      
				myFormatTarget->flush();
				//myOutFormatTarget->flush();
				domWriter->release();
		      
				delete myFormatTarget;
				//delete myOutFormatTarget;
				// release the document
				pModelicaXMLDoc->release();
				// terminate the XML framework
				XMLPlatformUtils::Terminate();
	
#line 193 "modelica_tree_parser.cpp"
	stored_definition_AST = currentAST.root;
	returnAST = stored_definition_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::within_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 283 "walker.g"
	DOMNode* ast;
#line 203 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST within_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST within_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 283 "walker.g"
	
		DOMNode* pNamePath = 0;
	
#line 212 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t8 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp2_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp2_AST = astFactory->create(_t);
	tmp2_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp2_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST8 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WITHIN);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	{
		pNamePath=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST8;
	_t = __t8;
	_t = _t->getNextSibling();
#line 288 "walker.g"
	
				DOMElement* pWithinElement = pModelicaXMLDoc->createElement(X("within"));
			    if (pNamePath) pWithinElement->appendChild(pNamePath);
				ast = pWithinElement;
	
#line 256 "modelica_tree_parser.cpp"
	within_clause_AST = currentAST.root;
	returnAST = within_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::class_definition(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	bool final
) {
#line 298 "walker.g"
	DOMNode* ast ;
#line 268 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST class_definition_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_definition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 298 "walker.g"
	
	DOMElement* definitionElement = 0;
	class_specifier_t sClassSpec;
	
#line 286 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t11 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp3_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp3_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp3_AST = astFactory->create(_t);
	tmp3_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp3_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST11 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,CLASS_DEFINITION);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ENCAPSULATED:
	{
		e = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		e_AST = astFactory->create(e);
		astFactory->addASTChild(currentAST, e_AST);
		match(_t,ENCAPSULATED);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	case CLASS:
	case CONNECTOR:
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case PARTIAL:
	{
		p = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST p_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		p_AST = astFactory->create(p);
		astFactory->addASTChild(currentAST, p_AST);
		match(_t,PARTIAL);
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	r = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	class_restriction(_t);
	_t = _retTree;
	r_AST = returnAST;
	astFactory->addASTChild( currentAST, returnAST );
	}
	i = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i_AST = astFactory->create(i);
	astFactory->addASTChild(currentAST, i_AST);
	match(_t,IDENT);
	_t = _t->getNextSibling();
	class_specifier(_t,sClassSpec);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST11;
	_t = __t11;
	_t = _t->getNextSibling();
#line 311 "walker.g"
	
				definitionElement = pModelicaXMLDoc->createElement(X("definition"));
	definitionElement->setAttribute(X("ident"), X(i->getText().c_str()));
				if (p != 0) definitionElement->setAttribute(X("partial"), X("true"));
				if (final) definitionElement->setAttribute(X("final"), X("true"));
				if (e != 0) definitionElement->setAttribute(X("encpsulated"), X("true")); 
				if (r) definitionElement->setAttribute(X("restriction"), str2xml(r));
				if (sClassSpec.string_comment) 
				{ 
					definitionElement->appendChild(sClassSpec.string_comment);	
				}
				if (sClassSpec.composition) 
				{ 
					//appendKids(definitionElement, sClassSpec.composition->getChildNodes());
					definitionElement->appendChild(sClassSpec.composition);
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
	
	/*definitionElement->setAttribute(X("sline"), X(i->getLine()));
	definitionElement->setAttribute(X("scolumn"), X(i->getColumn()));*/ 
				ast = definitionElement;
	/* ast = Absyn__CLASS(to_rml_str(i),RML_PRIM_MKBOOL(p != 0),RML_PRIM_MKBOOL(final),
					        RML_PRIM_MKBOOL(e != 0), restr, class_spec); */                
	
#line 417 "modelica_tree_parser.cpp"
	class_definition_AST = currentAST.root;
	returnAST = class_definition_AST;
	_retTree = _t;
	return ast ;
}

DOMNode*  modelica_tree_parser::name_path(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2258 "walker.g"
	DOMNode* ast;
#line 427 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST name_path_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		i = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		i_AST = astFactory->create(i);
		astFactory->addASTChild(currentAST, i_AST);
		match(_t,IDENT);
		_t = _t->getNextSibling();
#line 2261 "walker.g"
		
					DOMElement* pIdent = pModelicaXMLDoc->createElement(X("ident"));
					pIdent->setAttribute(X("ident"), str2xml(i));
					ast = pIdent;
					/*
					str = str2xml(i);
					ast = Absyn__IDENT(str);
					*/
				
#line 460 "modelica_tree_parser.cpp"
		name_path_AST = currentAST.root;
		break;
	}
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t293 = _t;
		d = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST d_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		d_AST = astFactory->create(d);
		astFactory->addASTChild(currentAST, d_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST293 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DOT);
		_t = _t->getFirstChild();
		i2 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		i2_AST = astFactory->create(i2);
		astFactory->addASTChild(currentAST, i2_AST);
		match(_t,IDENT);
		_t = _t->getNextSibling();
		ast=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST293;
		_t = __t293;
		_t = _t->getNextSibling();
#line 2271 "walker.g"
		
					DOMElement *pNamePath = pModelicaXMLDoc->createElement(X("qualified_name"));
					pNamePath->setAttribute(X("ident"), str2xml(i2));
					pNamePath->appendChild(ast);
					ast = pNamePath;
					/*
					str = str2xml(i2);
					ast = Absyn__QUALIFIED(str, ast);
					*/
				
#line 499 "modelica_tree_parser.cpp"
		name_path_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = name_path_AST;
	_retTree = _t;
	return ast;
}

void modelica_tree_parser::class_restriction(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
	ANTLR_USE_NAMESPACE(antlr)RefAST class_restriction_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_restriction_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp4_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp4_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp4_AST = astFactory->create(_t);
		tmp4_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp4_AST);
		match(_t,CLASS);
		_t = _t->getNextSibling();
		break;
	}
	case MODEL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp5_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp5_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp5_AST = astFactory->create(_t);
		tmp5_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp5_AST);
		match(_t,MODEL);
		_t = _t->getNextSibling();
		break;
	}
	case RECORD:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp6_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp6_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp6_AST = astFactory->create(_t);
		tmp6_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp6_AST);
		match(_t,RECORD);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp7_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp7_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp7_AST = astFactory->create(_t);
		tmp7_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp7_AST);
		match(_t,BLOCK);
		_t = _t->getNextSibling();
		break;
	}
	case CONNECTOR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp8_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp8_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp8_AST = astFactory->create(_t);
		tmp8_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp8_AST);
		match(_t,CONNECTOR);
		_t = _t->getNextSibling();
		break;
	}
	case TYPE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp9_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp9_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp9_AST = astFactory->create(_t);
		tmp9_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp9_AST);
		match(_t,TYPE);
		_t = _t->getNextSibling();
		break;
	}
	case PACKAGE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp10_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp10_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp10_AST = astFactory->create(_t);
		tmp10_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp10_AST);
		match(_t,PACKAGE);
		_t = _t->getNextSibling();
		break;
	}
	case FUNCTION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp11_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp11_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp11_AST = astFactory->create(_t);
		tmp11_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp11_AST);
		match(_t,FUNCTION);
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	class_restriction_AST = currentAST.root;
	returnAST = class_restriction_AST;
	_retTree = _t;
}

void modelica_tree_parser::class_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	class_specifier_t& sClassSpec
) {
	ANTLR_USE_NAMESPACE(antlr)RefAST class_specifier_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 369 "walker.g"
	
		DOMNode *comp = 0;
		DOMNode *cmt = 0;
		DOMNode *d = 0;
		DOMNode *e = 0;
		DOMNode *o = 0;
	
#line 637 "modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
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
		astFactory->addASTChild( currentAST, returnAST );
		}
		comp=composition(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
#line 380 "walker.g"
		
		if (cmt) sClassSpec.string_comment = cmt;
						sClassSpec.composition = comp;
						/* ast = Absyn__PARTS(comp,cmt ? mk_some(cmt) : mk_none()); */
					
#line 672 "modelica_tree_parser.cpp"
		}
		class_specifier_AST = currentAST.root;
		break;
	}
	case EQUALS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t20 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp12_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp12_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp12_AST = astFactory->create(_t);
		tmp12_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp12_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST20 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUALS);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			d=derived_class(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case ENUMERATION:
		{
			e=enumeration(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case OVERLOAD:
		{
			o=overloading(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST20;
		_t = __t20;
		_t = _t->getNextSibling();
#line 391 "walker.g"
		
					sClassSpec.derived = d;
					sClassSpec.enumeration = e;
					sClassSpec.overload = o;
				
#line 737 "modelica_tree_parser.cpp"
		class_specifier_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = class_specifier_AST;
	_retTree = _t;
}

DOMNode*  modelica_tree_parser::string_comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2473 "walker.g"
	DOMNode* ast;
#line 753 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST string_comment_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST string_comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING_COMMENT:
	{
#line 2474 "walker.g"
		
			  DOMNode* cmt=0;
			  ast = 0;	   
			
#line 769 "modelica_tree_parser.cpp"
		ANTLR_USE_NAMESPACE(antlr)RefAST __t333 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp13_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp13_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp13_AST = astFactory->create(_t);
		tmp13_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp13_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST333 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,STRING_COMMENT);
		_t = _t->getFirstChild();
		cmt=string_concatenation(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST333;
		_t = __t333;
		_t = _t->getNextSibling();
#line 2479 "walker.g"
		
					DOMElement *pStringComment = pModelicaXMLDoc->createElement(X("string_comment"));
					pStringComment->appendChild(cmt);
					ast = pStringComment;
				
#line 793 "modelica_tree_parser.cpp"
		string_comment_AST = currentAST.root;
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
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	{
#line 2485 "walker.g"
		
					ast = 0;
				
#line 815 "modelica_tree_parser.cpp"
		string_comment_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = string_comment_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::composition(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 510 "walker.g"
	DOMNode* ast;
#line 832 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST composition_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST composition_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 510 "walker.g"
	
	DOMNode* el = 0;
	l_stack el_stack;
	DOMNode*  ann;	
	
#line 843 "modelica_tree_parser.cpp"
	
	el=element_list(_t,1 /* public */);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 518 "walker.g"
	
				/* 
				DOMElement* pPublic = pModelicaXMLDoc->createElement(X("public"));
				pPublic->appendChild(el);
				el_stack.push(pPublic);
				*/
	el_stack.push(el);
	
#line 857 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_0.member(_t->getType()))) {
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case PUBLIC:
			{
				el=public_element_list(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case PROTECTED:
			{
				el=protected_element_list(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case EQUATION:
			case INITIAL_EQUATION:
			{
				el=equation_clause(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case ALGORITHM:
			case INITIAL_ALGORITHM:
			{
				el=algorithm_clause(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
#line 533 "walker.g"
			
			el_stack.push(el);
			
#line 907 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop43;
		}
		
	}
	_loop43:;
	} // ( ... )*
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t45 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp14_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp14_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp14_AST = astFactory->create(_t);
		tmp14_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp14_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST45 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EXTERNAL);
		_t = _t->getFirstChild();
		{
		el=external_function_call(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case ANNOTATION:
		{
			ann=annotation(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 540 "walker.g"
		
							el_stack.push(el); 
						
#line 963 "modelica_tree_parser.cpp"
		currentAST = __currentAST45;
		_t = __t45;
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 545 "walker.g"
	
	ast = (DOMElement*)stack2DOMNode(el_stack, "composition");
	
#line 983 "modelica_tree_parser.cpp"
	composition_AST = currentAST.root;
	returnAST = composition_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::derived_class(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 402 "walker.g"
	DOMNode* ast;
#line 993 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST derived_class_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST derived_class_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 402 "walker.g"
	
		DOMNode* p = 0;
		DOMNode* as = 0;
		DOMNode* cmod = 0;
		DOMNode* cmt = 0;
		DOMNode* attr = 0;
		type_prefix_t pfx;
	
#line 1007 "modelica_tree_parser.cpp"
	
	{
	type_prefix(_t,pfx);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	p=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		as=array_subscripts(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		cmod=class_modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	case COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 417 "walker.g"
	
					DOMElement* pDerived = pModelicaXMLDoc->createElement(X("derived"));
					if (p)               pDerived->appendChild(p);
					if (as)              pDerived->appendChild(as); 
					if (cmod)            pDerived->appendChild(cmod);
					if (pfx.flow)        pDerived->appendChild(pfx.flow);
					if (pfx.variability) pDerived->appendChild(pfx.variability);
					if (pfx.direction)   pDerived->appendChild(pfx.direction);
					if (cmt)             pDerived->appendChild(cmt);
					ast = pDerived;
				
#line 1094 "modelica_tree_parser.cpp"
	}
	derived_class_AST = currentAST.root;
	returnAST = derived_class_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::enumeration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 434 "walker.g"
	DOMNode* ast;
#line 1105 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 434 "walker.g"
	
		l_stack el_stack;
		DOMNode* el = 0;
		DOMNode* cmt = 0;
	
#line 1116 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t28 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp15_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp15_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp15_AST = astFactory->create(_t);
	tmp15_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp15_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST28 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ENUMERATION);
	_t = _t->getFirstChild();
	el=enumeration_literal(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 443 "walker.g"
	el_stack.push(el);
#line 1134 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ENUMERATION_LITERAL)) {
			el=enumeration_literal(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 446 "walker.g"
			el_stack.push(el);
#line 1145 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop30;
		}
		
	}
	_loop30:;
	} // ( ... )*
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST28;
	_t = __t28;
	_t = _t->getNextSibling();
#line 451 "walker.g"
	
				DOMElement* pEnumeration = pModelicaXMLDoc->createElement(X("enumeration"));
				pEnumeration = (DOMElement*)appendKids(el_stack, pEnumeration);
				if (cmt) pEnumeration->appendChild(cmt);
				ast = pEnumeration;
			
#line 1185 "modelica_tree_parser.cpp"
	enumeration_AST = currentAST.root;
	returnAST = enumeration_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::overloading(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 481 "walker.g"
	DOMNode* ast;
#line 1195 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST overloading_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST overloading_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 481 "walker.g"
	
		l_stack el_stack;
		DOMNode* el = 0;
		DOMNode* cmt = 0;
	
#line 1206 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t36 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp16_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp16_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp16_AST = astFactory->create(_t);
	tmp16_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp16_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST36 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,OVERLOAD);
	_t = _t->getFirstChild();
	el=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 490 "walker.g"
	el_stack.push(el);
#line 1224 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == DOT || _t->getType() == IDENT)) {
			el=name_path(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 493 "walker.g"
			el_stack.push(el);
#line 1235 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop38;
		}
		
	}
	_loop38:;
	} // ( ... )*
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST36;
	_t = __t36;
	_t = _t->getNextSibling();
#line 498 "walker.g"
	
				DOMElement* pOverload = pModelicaXMLDoc->createElement(X("overload"));
				pOverload = (DOMElement*)appendKids(el_stack, pOverload);
				if (cmt) pOverload->appendChild(cmt);
				ast = pOverload;
			
#line 1275 "modelica_tree_parser.cpp"
	overloading_AST = currentAST.root;
	returnAST = overloading_AST;
	_retTree = _t;
	return ast;
}

void modelica_tree_parser::type_prefix(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	type_prefix_t& prefix
) {
	ANTLR_USE_NAMESPACE(antlr)RefAST type_prefix_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_prefix_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST d_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FLOW:
	{
		f = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST f_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		f_AST = astFactory->create(f);
		astFactory->addASTChild(currentAST, f_AST);
		match(_t,FLOW);
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DISCRETE:
	{
		d = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST d_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		d_AST = astFactory->create(d);
		astFactory->addASTChild(currentAST, d_AST);
		match(_t,DISCRETE);
		_t = _t->getNextSibling();
		break;
	}
	case PARAMETER:
	{
		p = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST p_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		p_AST = astFactory->create(p);
		astFactory->addASTChild(currentAST, p_AST);
		match(_t,PARAMETER);
		_t = _t->getNextSibling();
		break;
	}
	case CONSTANT:
	{
		c = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST c_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		c_AST = astFactory->create(c);
		astFactory->addASTChild(currentAST, c_AST);
		match(_t,CONSTANT);
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case INPUT:
	{
		i = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		i_AST = astFactory->create(i);
		astFactory->addASTChild(currentAST, i_AST);
		match(_t,INPUT);
		_t = _t->getNextSibling();
		break;
	}
	case OUTPUT:
	{
		o = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST o_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		o_AST = astFactory->create(o);
		astFactory->addASTChild(currentAST, o_AST);
		match(_t,OUTPUT);
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 924 "walker.g"
	
				DOMElement *pFlow = pModelicaXMLDoc->createElement(X("flow"));
				if (f != NULL) { pFlow->setAttribute(X("flow"), X("true")); /* prefix.flow = RML_PRIM_MKBOOL(1); */ }
				else { pFlow->setAttribute(X("flow"), X("none")); /* prefix.flow = RML_PRIM_MKBOOL(0);  */ }
				prefix.flow = pFlow;
				DOMElement *pVariability = pModelicaXMLDoc->createElement(X("variability"));
				if (d != NULL) { pVariability->setAttribute(X("variability"), X("discrete")); /* prefix.variability = Absyn__DISCRETE; */ }
				else if (p != NULL) { pVariability->setAttribute(X("variability"), X("parameter")); /* prefix.variability = Absyn__PARAM; */ }
				else if (c != NULL) { pVariability->setAttribute(X("variability"), X("constant")); /* prefix.variability = Absyn__CONST; */ }
				else { pVariability->setAttribute(X("variability"), X("variable")); /* prefix.variability = Absyn__VAR; */ }
				prefix.variability = pVariability;
				DOMElement *pDirection = pModelicaXMLDoc->createElement(X("direction"));
				if (i != NULL) { pDirection->setAttribute(X("direction"), X("input")); /* prefix.direction = Absyn__INPUT; */ }
				else if (o != NULL) { pDirection->setAttribute(X("direction"), X("output")); /* prefix.direction = Absyn__OUTPUT; */ }
				else { pDirection->setAttribute(X("direction"), X("bidirectional")); /* prefix.direction = Absyn__BIDIR; */ }
				prefix.direction = pDirection;
			
#line 1432 "modelica_tree_parser.cpp"
	type_prefix_AST = currentAST.root;
	returnAST = type_prefix_AST;
	_retTree = _t;
}

DOMNode*  modelica_tree_parser::array_subscripts(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2416 "walker.g"
	DOMNode* ast;
#line 1441 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST array_subscripts_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST array_subscripts_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2416 "walker.g"
	
		l_stack el_stack;
		DOMNode* s = 0;
	
#line 1451 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t324 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp17_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp17_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp17_AST = astFactory->create(_t);
	tmp17_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp17_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST324 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,LBRACK);
	_t = _t->getFirstChild();
	s=subscript(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 2423 "walker.g"
	
					el_stack.push(s);
				
#line 1471 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_1.member(_t->getType()))) {
			s=subscript(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 2427 "walker.g"
			
								el_stack.push(s);
							
#line 1484 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop326;
		}
		
	}
	_loop326:;
	} // ( ... )*
	currentAST = __currentAST324;
	_t = __t324;
	_t = _t->getNextSibling();
#line 2431 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "array_subscripts");
			
#line 1500 "modelica_tree_parser.cpp"
	array_subscripts_AST = currentAST.root;
	returnAST = array_subscripts_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::class_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1025 "walker.g"
	DOMNode* ast;
#line 1510 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST class_modification_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST class_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1025 "walker.g"
	
		ast = 0;
	
#line 1519 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t120 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp18_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp18_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp18_AST = astFactory->create(_t);
	tmp18_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp18_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST120 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,CLASS_MODIFICATION);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ARGUMENT_LIST:
	{
		ast=argument_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST120;
	_t = __t120;
	_t = _t->getNextSibling();
#line 1031 "walker.g"
	
				/* if (!ast) ast = mk_nil(); */
			
#line 1560 "modelica_tree_parser.cpp"
	class_modification_AST = currentAST.root;
	returnAST = class_modification_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::comment(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2457 "walker.g"
	DOMNode* ast;
#line 1570 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST comment_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST comment_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2457 "walker.g"
	
		DOMNode* ann=0;
		DOMNode* cmt=0;
	ast = 0;
	
#line 1581 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t330 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp19_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp19_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp19_AST = astFactory->create(_t);
	tmp19_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp19_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST330 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,COMMENT);
	_t = _t->getFirstChild();
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ANNOTATION:
	{
		ann=annotation(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST330;
	_t = __t330;
	_t = _t->getNextSibling();
#line 2464 "walker.g"
	
				DOMElement *pComment = pModelicaXMLDoc->createElement(X("comment"));
				if (cmt) pComment->appendChild(cmt);
		  		if (ann) pComment->appendChild(ann);
				ast = pComment;
				/* if (ann) || cmt) ast = Absyn__COMMENT(ann ? mk_some(ann) : mk_none(), cmt ? mk_some(cmt) : mk_none()); */
			
#line 1629 "modelica_tree_parser.cpp"
	comment_AST = currentAST.root;
	returnAST = comment_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::enumeration_literal(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 463 "walker.g"
	DOMNode* ast;
#line 1639 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_literal_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST enumeration_literal_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i1 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
#line 464 "walker.g"
	
	DOMNode* c1=0;
	
#line 1651 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST __t33 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp20_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp20_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp20_AST = astFactory->create(_t);
	tmp20_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp20_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST33 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ENUMERATION_LITERAL);
	_t = _t->getFirstChild();
	i1 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i1_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i1_AST = astFactory->create(i1);
	astFactory->addASTChild(currentAST, i1_AST);
	match(_t,IDENT);
	_t = _t->getNextSibling();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		c1=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST33;
	_t = __t33;
	_t = _t->getNextSibling();
#line 468 "walker.g"
	
				DOMElement* pEnumerationLiteral = pModelicaXMLDoc->createElement(X("enumeration_literal"));
				pEnumerationLiteral->setAttribute(X("ident"), str2xml(i1));
				if (c1) pEnumerationLiteral->appendChild(c1);
				ast = pEnumerationLiteral;
			
#line 1700 "modelica_tree_parser.cpp"
	enumeration_literal_AST = currentAST.root;
	returnAST = enumeration_literal_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t,
	int iSwitch
) {
#line 637 "walker.g"
	DOMNode* ast;
#line 1712 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 637 "walker.g"
	
	DOMNode* e = 0;
	l_stack el_stack;
	DOMNode* ann = 0;
	
#line 1723 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXTENDS:
		case IMPORT:
		case DECLARATION:
		case DEFINITION:
		{
			{
			e=element(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 646 "walker.g"
			
			if (iSwitch == 1) ((DOMElement*)e)->setAttribute(X("visibility"), X("public"));
								else if (iSwitch == 2) ((DOMElement*)e)->setAttribute(X("visibility"), X("protected"));
								else { /* error, shouldn't happen */ } 
			el_stack.push(e);
			
#line 1746 "modelica_tree_parser.cpp"
			}
			break;
		}
		case ANNOTATION:
		{
			{
			ann=annotation(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 653 "walker.g"
			
			if (iSwitch == 1) ((DOMElement*)ann)->setAttribute(X("visibility"), X("public"));
								else if (iSwitch == 2) ((DOMElement*)ann)->setAttribute(X("visibility"), X("protected"));
								else { /* error, shouldn't happen */ } 
								((DOMElement*)ann)->setAttribute(X("inside"), X("definition"));
			el_stack.push(ann);
			
#line 1764 "modelica_tree_parser.cpp"
			}
			break;
		}
		default:
		{
			goto _loop65;
		}
		}
	}
	_loop65:;
	} // ( ... )*
#line 662 "walker.g"
	
	ast = (DOMElement*)stack2DOMNode(el_stack, "element_list");
	
#line 1780 "modelica_tree_parser.cpp"
	element_list_AST = currentAST.root;
	returnAST = element_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::public_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 550 "walker.g"
	DOMNode* ast;
#line 1790 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST public_element_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST public_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 550 "walker.g"
	
	DOMNode* el;    
	
#line 1801 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t49 = _t;
	p = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	p_AST = astFactory->create(p);
	astFactory->addASTChild(currentAST, p_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST49 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,PUBLIC);
	_t = _t->getFirstChild();
	el=element_list(_t,1 /* public */);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST49;
	_t = __t49;
	_t = _t->getNextSibling();
#line 559 "walker.g"
	
				DOMElement* pPublic = pModelicaXMLDoc->createElement(X("public"));
				pPublic->appendChild(el);
				ast = pPublic;
	
#line 1825 "modelica_tree_parser.cpp"
	public_element_list_AST = currentAST.root;
	returnAST = public_element_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::protected_element_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 566 "walker.g"
	DOMNode* ast;
#line 1835 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST protected_element_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST protected_element_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 566 "walker.g"
	
	DOMNode* el;
	
#line 1846 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t51 = _t;
	p = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	p_AST = astFactory->create(p);
	astFactory->addASTChild(currentAST, p_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST51 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,PROTECTED);
	_t = _t->getFirstChild();
	el=element_list(_t,2 /* protected */);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST51;
	_t = __t51;
	_t = _t->getNextSibling();
#line 575 "walker.g"
	
				DOMElement* pProtected = pModelicaXMLDoc->createElement(X("protected"));
				pProtected->appendChild(el);
				ast = pProtected;
	
#line 1870 "modelica_tree_parser.cpp"
	protected_element_list_AST = currentAST.root;
	returnAST = protected_element_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::equation_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1193 "walker.g"
	DOMNode* ast;
#line 1880 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1193 "walker.g"
	
		l_stack el_stack;
		DOMNode* e = 0;
		DOMNode* ann = 0;
	
#line 1891 "modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t145 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp21_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp21_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp21_AST = astFactory->create(_t);
		tmp21_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp21_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST145 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUATION);
		_t = _t->getFirstChild();
		{
		{ // ( ... )*
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EQUATION_STATEMENT:
			{
				e=equation(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1203 "walker.g"
				el_stack.push(e);
#line 1922 "modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1205 "walker.g"
				
								    DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
									pAnnotation->setAttribute(X("inside"), X("equation"));
									pAnnotation->appendChild(ann);
									el_stack.push(pAnnotation /* Absyn__EQUATIONITEMANN(ann) */);
								
#line 1937 "modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop148;
			}
			}
		}
		_loop148:;
		} // ( ... )*
		}
		currentAST = __currentAST145;
		_t = __t145;
		_t = _t->getNextSibling();
#line 1215 "walker.g"
		
					DOMElement*  pEquations = pModelicaXMLDoc->createElement(X("equations"));
					pEquations = (DOMElement*)appendKids(el_stack, pEquations);
					ast = pEquations;
					/* ast = Absyn__EQUATIONS((DOMElement*)stack2DOMNode(el_stack)); */
				
#line 1959 "modelica_tree_parser.cpp"
		equation_clause_AST = currentAST.root;
		break;
	}
	case INITIAL_EQUATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t149 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp22_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp22_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp22_AST = astFactory->create(_t);
		tmp22_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp22_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST149 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,INITIAL_EQUATION);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t150 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp23_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp23_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp23_AST = astFactory->create(_t);
		tmp23_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp23_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST150 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUATION);
		_t = _t->getFirstChild();
		{ // ( ... )*
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EQUATION_STATEMENT:
			{
				e=equation(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1225 "walker.g"
				el_stack.push(e);
#line 1999 "modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1227 "walker.g"
				
								    DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
									pAnnotation->setAttribute(X("inside"), X("equation"));
									pAnnotation->appendChild(ann);
									el_stack.push(pAnnotation /* Absyn__EQUATIONITEMANN(ann) */);
								
#line 2014 "modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop152;
			}
			}
		}
		_loop152:;
		} // ( ... )*
		currentAST = __currentAST150;
		_t = __t150;
		_t = _t->getNextSibling();
#line 1235 "walker.g"
		
						DOMElement*  pEquations = pModelicaXMLDoc->createElement(X("equations"));
						pEquations->setAttribute(X("initial"), X("true"));
						pEquations = (DOMElement*)appendKids(el_stack, pEquations);
						ast = pEquations;
						/* ast = Absyn__INITIALEQUATIONS((DOMElement*)stack2DOMNode(el_stack)); */
					
#line 2036 "modelica_tree_parser.cpp"
		currentAST = __currentAST149;
		_t = __t149;
		_t = _t->getNextSibling();
		equation_clause_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = equation_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::algorithm_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1245 "walker.g"
	DOMNode* ast;
#line 2056 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1245 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
		DOMNode* ann;
	
#line 2067 "modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ALGORITHM:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t154 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp24_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp24_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp24_AST = astFactory->create(_t);
		tmp24_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp24_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST154 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ALGORITHM);
		_t = _t->getFirstChild();
		{ // ( ... )*
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case ALGORITHM_STATEMENT:
			{
				e=algorithm(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1253 "walker.g"
				el_stack.push(e);
#line 2097 "modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1255 "walker.g"
				
								DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
								pAnnotation->setAttribute(X("inside"), X("algorithm"));
								pAnnotation->appendChild(ann);
								el_stack.push(pAnnotation /* Absyn__ALGORITHMITEMANN(ann) */);
							
#line 2112 "modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop156;
			}
			}
		}
		_loop156:;
		} // ( ... )*
		currentAST = __currentAST154;
		_t = __t154;
		_t = _t->getNextSibling();
#line 1263 "walker.g"
		
					DOMElement*  pAlgorithms = pModelicaXMLDoc->createElement(X("algorithms"));
					pAlgorithms = (DOMElement*)appendKids(el_stack, pAlgorithms);
					ast = pAlgorithms;
					/* ast = Absyn__ALGORITHMS((DOMElement*)stack2DOMNode(el_stack)); */
				
#line 2133 "modelica_tree_parser.cpp"
		algorithm_clause_AST = currentAST.root;
		break;
	}
	case INITIAL_ALGORITHM:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t157 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp25_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp25_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp25_AST = astFactory->create(_t);
		tmp25_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp25_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST157 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,INITIAL_ALGORITHM);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t158 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp26_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp26_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp26_AST = astFactory->create(_t);
		tmp26_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp26_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST158 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ALGORITHM);
		_t = _t->getFirstChild();
		{ // ( ... )*
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case ALGORITHM_STATEMENT:
			{
				e=algorithm(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1272 "walker.g"
				el_stack.push(e);
#line 2173 "modelica_tree_parser.cpp"
				break;
			}
			case ANNOTATION:
			{
				ann=annotation(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 1274 "walker.g"
								
									DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
									pAnnotation->setAttribute(X("inside"), X("algorithm"));
									pAnnotation->appendChild(ann);
									el_stack.push(pAnnotation /* Absyn__ALGORITHMITEMANN(ann) */);
				
#line 2188 "modelica_tree_parser.cpp"
				break;
			}
			default:
			{
				goto _loop160;
			}
			}
		}
		_loop160:;
		} // ( ... )*
		currentAST = __currentAST158;
		_t = __t158;
		_t = _t->getNextSibling();
#line 1282 "walker.g"
		
						DOMElement*  pAlgorithms = pModelicaXMLDoc->createElement(X("algorithms"));
						pAlgorithms->setAttribute(X("initial"), X("true"));
						pAlgorithms = (DOMElement*)appendKids(el_stack, pAlgorithms);
						ast = pAlgorithms;
						/* ast = Absyn__INITIALALGORITHMS((DOMElement*)stack2DOMNode(el_stack)); */
					
#line 2210 "modelica_tree_parser.cpp"
		currentAST = __currentAST157;
		_t = __t157;
		_t = _t->getNextSibling();
		algorithm_clause_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = algorithm_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::external_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 582 "walker.g"
	DOMNode* ast;
#line 2230 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST external_function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST external_function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 582 "walker.g"
	
		DOMNode* temp=0;
		DOMNode* temp2=0;
		DOMNode* temp3=0;
		ast = 0;
	
#line 2250 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING:
	{
		s = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST s_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		s_AST = astFactory->create(s);
		astFactory->addASTChild(currentAST, s_AST);
		match(_t,STRING);
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ANNOTATION:
	case EXTERNAL_FUNCTION_CALL:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL_FUNCTION_CALL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t55 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp27_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp27_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp27_AST = astFactory->create(_t);
		tmp27_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp27_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST55 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EXTERNAL_FUNCTION_CALL);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case IDENT:
		{
			{
			i = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			i_AST = astFactory->create(i);
			astFactory->addASTChild(currentAST, i_AST);
			match(_t,IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXPRESSION_LIST:
			{
				temp=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			}
#line 594 "walker.g"
			
									DOMElement* pExternalFunctionCall = 
										pModelicaXMLDoc->createElement(X("external"));
									if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));  
									if (i != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i));  
									if (temp) pExternalFunctionCall->appendChild(temp);
									ast = pExternalFunctionCall;
								
#line 2339 "modelica_tree_parser.cpp"
			break;
		}
		case EQUALS:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t59 = _t;
			e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			e_AST = astFactory->create(e);
			astFactory->addASTChild(currentAST, e_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST59 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,EQUALS);
			_t = _t->getFirstChild();
			temp2=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			i2 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			i2_AST = astFactory->create(i2);
			astFactory->addASTChild(currentAST, i2_AST);
			match(_t,IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXPRESSION_LIST:
			{
				temp3=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			currentAST = __currentAST59;
			_t = __t59;
			_t = _t->getNextSibling();
#line 603 "walker.g"
			
									DOMElement* pExternalFunctionCall = 
										pModelicaXMLDoc->createElement(X("external"));
									if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));  
									if (i2 != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i2));  
									DOMElement* pExternalEqual = 
										pModelicaXMLDoc->createElement(X("external_equal"));
									if (temp2) pExternalEqual->appendChild(temp2);
									pExternalFunctionCall->appendChild(pExternalEqual);
									if (temp3) pExternalFunctionCall->appendChild(temp3);
									ast = pExternalFunctionCall;
									/* ast = Absyn__EXTERNAL(Absyn__EXTERNALDECL(mk_some(str2xml(i2)),lang,mk_some(temp2),temp3)); */
								
#line 2401 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST55;
		_t = __t55;
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	case ANNOTATION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 618 "walker.g"
	
				if (!ast) 
				{ 
					DOMElement* pExternalFunctionCall = pModelicaXMLDoc->createElement(X("external"));
					if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));  
					ast = pExternalFunctionCall;
				}
	
#line 2435 "modelica_tree_parser.cpp"
	external_function_call_AST = currentAST.root;
	returnAST = external_function_call_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::annotation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2513 "walker.g"
	DOMNode* ast;
#line 2445 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST annotation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST annotation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST a = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2513 "walker.g"
	
	DOMNode* cmod=0;
	
#line 2456 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t337 = _t;
	a = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST a_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	a_AST = astFactory->create(a);
	astFactory->addASTChild(currentAST, a_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST337 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ANNOTATION);
	_t = _t->getFirstChild();
	cmod=class_modification(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST337;
	_t = __t337;
	_t = _t->getNextSibling();
#line 2519 "walker.g"
	
				DOMElement *pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
				pAnnotation->appendChild(cmod);
				ast = pAnnotation;
	/* ast = Absyn__ANNOTATION(cmod); */
	
#line 2481 "modelica_tree_parser.cpp"
	annotation_AST = currentAST.root;
	returnAST = annotation_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2374 "walker.g"
	DOMNode* ast;
#line 2491 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2374 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
	
#line 2501 "modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t315 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp28_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp28_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp28_AST = astFactory->create(_t);
	tmp28_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp28_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST315 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 2381 "walker.g"
	el_stack.push(e);
#line 2520 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 2382 "walker.g"
			el_stack.push(e);
#line 2531 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop317;
		}
		
	}
	_loop317:;
	} // ( ... )*
	currentAST = __currentAST315;
	_t = __t315;
	_t = _t->getNextSibling();
	}
#line 2385 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "expression_list");
			
#line 2548 "modelica_tree_parser.cpp"
	expression_list_AST = currentAST.root;
	returnAST = expression_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::component_reference(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2283 "walker.g"
	DOMNode* ast;
#line 2558 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2283 "walker.g"
	
		DOMNode* arr = 0;
		DOMNode* id = 0;
	
#line 2572 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t296 = _t;
		i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		i_AST = astFactory->create(i);
		astFactory->addASTChild(currentAST, i_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST296 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			arr=array_subscripts(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST296;
		_t = __t296;
		_t = _t->getNextSibling();
#line 2290 "walker.g"
		
						DOMElement *pCref = pModelicaXMLDoc->createElement(X("component_reference"));
						pCref->setAttribute(X("ident"), str2xml(i));
						if (arr) pCref->appendChild(arr);
						ast = pCref;
						/*
						if (!arr) arr = mk_nil();
						id = str2xml(i);
						ast = Absyn__CREF_5fIDENT(
							id,
							arr);
						*/
					
#line 2628 "modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t298 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp29_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp29_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp29_AST = astFactory->create(_t);
		tmp29_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp29_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST298 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DOT);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST __t299 = _t;
		i2 = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST i2_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		i2_AST = astFactory->create(i2);
		astFactory->addASTChild(currentAST, i2_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST299 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,IDENT);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LBRACK:
		{
			arr=array_subscripts(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST299;
		_t = __t299;
		_t = _t->getNextSibling();
		ast=component_reference(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST298;
		_t = __t298;
		_t = _t->getNextSibling();
#line 2305 "walker.g"
		
						DOMElement *pCref = pModelicaXMLDoc->createElement(X("component_reference"));
						pCref->setAttribute(X("ident"), str2xml(i2));
						if (arr) pCref->appendChild(arr);
						pCref->appendChild(ast);
						ast = pCref;
						/* 
						if (!arr) arr = mk_nil();
						id = str2xml(i2);
						ast = Absyn__CREF_5fQUAL(
							id,
							arr,
							ast);
						*/
					
#line 2700 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	component_reference_AST = currentAST.root;
	returnAST = component_reference_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::element(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 670 "walker.g"
	DOMNode* ast;
#line 2718 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST o_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST fd = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST fd_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST id = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST id_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST od = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST od_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rd = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST rd_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 670 "walker.g"
	
		DOMNode* class_def = 0;
		DOMNode* e_spec = 0;
		DOMNode* final = 0;
		DOMNode* innerouter = 0;
		DOMNode* constr = 0;
		DOMNode* cmt = 0;
	
#line 2748 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IMPORT:
	{
		e_spec=import_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
#line 681 "walker.g"
		
						ast = e_spec;
						/* ast = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,mk_scon("import"),e_spec,mk_none()); */
					
#line 2764 "modelica_tree_parser.cpp"
		break;
	}
	case EXTENDS:
	{
		e_spec=extends_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
#line 686 "walker.g"
		
						ast = e_spec;
						/* ast = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,mk_scon("extends"),e_spec,mk_none()); */
					
#line 2777 "modelica_tree_parser.cpp"
		break;
	}
	case DECLARATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t68 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp30_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp30_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp30_AST = astFactory->create(_t);
		tmp30_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp30_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST68 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DECLARATION);
		_t = _t->getFirstChild();
		{
#line 691 "walker.g"
		DOMElement* componentElement = pModelicaXMLDoc->createElement(X("component"));
#line 2796 "modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FINAL:
		{
			f = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST f_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			f_AST = astFactory->create(f);
			astFactory->addASTChild(currentAST, f_AST);
			match(_t,FINAL);
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
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 692 "walker.g"
		if (f) componentElement->setAttribute(X("final"), X("true"));
#line 2833 "modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INNER:
		{
			i = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			i_AST = astFactory->create(i);
			astFactory->addASTChild(currentAST, i_AST);
			match(_t,INNER);
			_t = _t->getNextSibling();
			break;
		}
		case OUTER:
		{
			o = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST o_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			o_AST = astFactory->create(o);
			astFactory->addASTChild(currentAST, o_AST);
			match(_t,OUTER);
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
		case IDENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 694 "walker.g"
		
								  if (i) componentElement->setAttribute(X("innerouter"), X("inner")); 
								  if (o) componentElement->setAttribute(X("innerouter"), X("outer")); 
								  /* innerouter = make_inner_outer(i,o); */
							
#line 2882 "modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			e_spec=component_clause(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 700 "walker.g"
			
										/* ast = Absyn__ELEMENT(final,RML_FALSE,innerouter,
											mk_scon("component"),e_spec,mk_none()); */
			componentElement->appendChild(e_spec);
			/* componentElement->appendChild(innerouter); */
										ast = componentElement;
									
#line 2907 "modelica_tree_parser.cpp"
			break;
		}
		case REPLACEABLE:
		{
			r = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST r_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			r_AST = astFactory->create(r);
			astFactory->addASTChild(currentAST, r_AST);
			match(_t,REPLACEABLE);
			_t = _t->getNextSibling();
			e_spec=component_clause(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
			{
				constr=constraining_clause(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				cmt=comment(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
#line 710 "walker.g"
			
										if (r) componentElement->setAttribute(X("replaceable"), X("true"));
			componentElement->appendChild(e_spec);
			if (constr) 
										{
											componentElement->appendChild(constr);
											// append the comment to the constraint
											if (cmt) ((DOMElement*)constr)->appendChild(cmt);
										}
										ast = componentElement;
										/*
										ast = Absyn__ELEMENT(final,
											r ? RML_TRUE : RML_FALSE,
											Absyn__UNSPECIFIED,
											mk_scon("replaceable_component"),e_spec,
											constr? mk_some(constr):mk_none()); */
									
#line 2963 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		}
		currentAST = __currentAST68;
		_t = __t68;
		_t = _t->getNextSibling();
		break;
	}
	case DEFINITION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t74 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp31_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp31_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp31_AST = astFactory->create(_t);
		tmp31_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp31_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST74 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,DEFINITION);
		_t = _t->getFirstChild();
		{
#line 731 "walker.g"
		DOMElement* definitionElement = pModelicaXMLDoc->createElement(X("definition"));
#line 2994 "modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FINAL:
		{
			fd = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST fd_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			fd_AST = astFactory->create(fd);
			astFactory->addASTChild(currentAST, fd_AST);
			match(_t,FINAL);
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
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 732 "walker.g"
		if (fd) definitionElement->setAttribute(X("final"), X("true"));
#line 3024 "modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INNER:
		{
			id = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST id_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			id_AST = astFactory->create(id);
			astFactory->addASTChild(currentAST, id_AST);
			match(_t,INNER);
			_t = _t->getNextSibling();
			break;
		}
		case OUTER:
		{
			od = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST od_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			od_AST = astFactory->create(od);
			astFactory->addASTChild(currentAST, od_AST);
			match(_t,OUTER);
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
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 734 "walker.g"
		
								  if (i) definitionElement->setAttribute(X("innerouter"), X("inner")); 
								  if (o) definitionElement->setAttribute(X("innerouter"), X("outer")); 
								  /* innerouter = make_inner_outer(i,o); */
							
#line 3066 "modelica_tree_parser.cpp"
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,fd != NULL);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 741 "walker.g"
			
										DOMElement* pDefinition = pModelicaXMLDoc->createElement(X("definition"));
										pDefinition->appendChild(class_def);
										/*
										ast = Absyn__CLASSDEF(RML_PRIM_MKBOOL(0),
											class_def);
										ast = Absyn__ELEMENT(final,RML_FALSE,innerouter,mk_scon("??"),ast,mk_none());*/
										definitionElement->appendChild(pDefinition);
										/* componentElement->appendChild(innerouter); */
										ast = definitionElement;
									
#line 3088 "modelica_tree_parser.cpp"
			break;
		}
		case REPLACEABLE:
		{
			{
			rd = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST rd_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			rd_AST = astFactory->create(rd);
			astFactory->addASTChild(currentAST, rd_AST);
			match(_t,REPLACEABLE);
			_t = _t->getNextSibling();
			class_def=class_definition(_t,fd != NULL);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
			{
				constr=constraining_clause(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				cmt=comment(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			}
#line 757 "walker.g"
			
										DOMElement* pDefinition = pModelicaXMLDoc->createElement(X("definition"));
										pDefinition->appendChild(class_def);
										definitionElement->appendChild(pDefinition);
										if (innerouter) definitionElement->appendChild(innerouter);
			if (constr) 
										{
											definitionElement->appendChild(constr);
											// append the comment to the constraint
											if (cmt) ((DOMElement*)constr)->appendChild(cmt);
										}
										if (rd) definitionElement->setAttribute(X("replaceable"), X("true"));
										ast = definitionElement;
										
										/*ast = Absyn__CLASSDEF(rd ? RML_TRUE : RML_FALSE,
											class_def);
										ast = Absyn__ELEMENT(final,
											rd ? RML_TRUE : RML_FALSE,innerouter,
											mk_scon("??"),
											ast,constr ? mk_some(constr) : mk_none()); */
									
#line 3150 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		}
		currentAST = __currentAST74;
		_t = __t74;
		_t = _t->getNextSibling();
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	element_AST = currentAST.root;
	returnAST = element_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::import_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 787 "walker.g"
	DOMNode* ast;
#line 3180 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST import_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST import_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 787 "walker.g"
	
		DOMNode* imp = 0;
		DOMNode* cmt = 0;
	
#line 3192 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t82 = _t;
	i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i_AST = astFactory->create(i);
	astFactory->addASTChild(currentAST, i_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST82 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IMPORT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	{
		imp=explicit_import_name(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case QUALIFIED:
	case UNQUALIFIED:
	{
		imp=implicit_import_name(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST82;
	_t = __t82;
	_t = _t->getNextSibling();
#line 799 "walker.g"
	
				DOMElement* pImport = pModelicaXMLDoc->createElement(X("import"));
				pImport->appendChild(imp);
				if (cmt) pImport->appendChild(cmt);
				ast = pImport;
				/* ast = Absyn__IMPORT(imp, cmt ? mk_some(cmt) : mk_none()); */
			
#line 3261 "modelica_tree_parser.cpp"
	import_clause_AST = currentAST.root;
	returnAST = import_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::extends_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 854 "walker.g"
	DOMNode* ast;
#line 3271 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST extends_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST extends_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 854 "walker.g"
	
		DOMNode* path;
		DOMNode* mod = 0;
	
#line 3283 "modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t93 = _t;
	e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	e_AST = astFactory->create(e);
	astFactory->addASTChild(currentAST, e_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST93 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EXTENDS);
	_t = _t->getFirstChild();
	path=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		mod=class_modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST93;
	_t = __t93;
	_t = _t->getNextSibling();
#line 864 "walker.g"
	
					DOMElement* pExtends = pModelicaXMLDoc->createElement(X("extends"));
					if (mod) pExtends->appendChild(mod);
					pExtends->appendChild(path);
					ast = pExtends;
					/* ast = Absyn__EXTENDS(path,mod); */
				
#line 3331 "modelica_tree_parser.cpp"
	}
	extends_clause_AST = currentAST.root;
	returnAST = extends_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::component_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 884 "walker.g"
	DOMNode* ast;
#line 3342 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 884 "walker.g"
	
		type_prefix_t pfx;
		DOMNode* attr = 0;
		DOMNode* path = 0;
		DOMNode* arr = 0;
		DOMNode* comp_list = 0;
	
#line 3355 "modelica_tree_parser.cpp"
	
	type_prefix(_t,pfx);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	path=type_specifier(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		arr=array_subscripts(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	comp_list=component_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 897 "walker.g"
	
				DOMElement* pComponents = pModelicaXMLDoc->createElement(X("component"));
				if (pfx.flow)        pComponents->appendChild(pfx.flow);
				if (pfx.variability) pComponents->appendChild(pfx.variability);
				if (pfx.direction)   pComponents->appendChild(pfx.direction);
				if (arr)             pComponents->appendChild(arr);
				if (path)            pComponents->appendChild(path);
				if (comp_list)       pComponents->appendChild(comp_list);
				ast = pComponents;
	
				/*
				attr = Absyn__ATTR(pfx.flow,pfx.variability,pfx.direction,arr);
				ast = Absyn__COMPONENTS(attr, path, comp_list);
				*/
			
#line 3403 "modelica_tree_parser.cpp"
	component_clause_AST = currentAST.root;
	returnAST = component_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::constraining_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 877 "walker.g"
	DOMNode* ast;
#line 3413 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST constraining_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST constraining_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	ast=extends_clause(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	}
	constraining_clause_AST = currentAST.root;
	returnAST = constraining_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::explicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 811 "walker.g"
	DOMNode* ast;
#line 3433 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST explicit_import_name_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST explicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 811 "walker.g"
	
		DOMNode* path;
	
#line 3444 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t86 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp32_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp32_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp32_AST = astFactory->create(_t);
	tmp32_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp32_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST86 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUALS);
	_t = _t->getFirstChild();
	i = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i_AST = astFactory->create(i);
	astFactory->addASTChild(currentAST, i_AST);
	match(_t,IDENT);
	_t = _t->getNextSibling();
	path=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST86;
	_t = __t86;
	_t = _t->getNextSibling();
#line 817 "walker.g"
	
				DOMElement* pExplicitImport = pModelicaXMLDoc->createElement(X("named_import"));
				pExplicitImport->setAttribute(X("ident"), str2xml(i));
				pExplicitImport->appendChild(path);
				ast = pExplicitImport;
				/* ast = Absyn__NAMED_5fIMPORT(id,path); */
			
#line 3477 "modelica_tree_parser.cpp"
	explicit_import_name_AST = currentAST.root;
	returnAST = explicit_import_name_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::implicit_import_name(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 828 "walker.g"
	DOMNode* ast;
#line 3487 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST implicit_import_name_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST implicit_import_name_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 828 "walker.g"
	
		DOMNode* path;
	
#line 3496 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNQUALIFIED:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t89 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp33_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp33_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp33_AST = astFactory->create(_t);
		tmp33_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp33_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST89 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,UNQUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST89;
		_t = __t89;
		_t = _t->getNextSibling();
#line 834 "walker.g"
		
						DOMElement* pUnqImport = pModelicaXMLDoc->createElement(X("unqualified_import"));
						pUnqImport->appendChild(path);
						ast = pUnqImport;
						/* ast = Absyn__UNQUAL_5fIMPORT(path); */
					
#line 3528 "modelica_tree_parser.cpp"
		break;
	}
	case QUALIFIED:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t90 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp34_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp34_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp34_AST = astFactory->create(_t);
		tmp34_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp34_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST90 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,QUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST90;
		_t = __t90;
		_t = _t->getNextSibling();
#line 841 "walker.g"
		
						DOMElement* pQuaImport = pModelicaXMLDoc->createElement(X("qualified_import"));
						pQuaImport->appendChild(path);
						ast = pQuaImport;
						/* ast = Absyn__QUAL_5fIMPORT(path); */
					
#line 3557 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	implicit_import_name_AST = currentAST.root;
	returnAST = implicit_import_name_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::type_specifier(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 944 "walker.g"
	DOMNode* ast;
#line 3575 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST type_specifier_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST type_specifier_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ast=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	type_specifier_AST = currentAST.root;
	returnAST = type_specifier_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::component_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 950 "walker.g"
	DOMNode* ast;
#line 3593 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 950 "walker.g"
	
		l_stack el_stack;
		DOMNode* e=0;
	
#line 3603 "modelica_tree_parser.cpp"
	
	e=component_declaration(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 956 "walker.g"
	el_stack.push(e);
#line 3610 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == IDENT)) {
			e=component_declaration(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 957 "walker.g"
			el_stack.push(e);
#line 3621 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop106;
		}
		
	}
	_loop106:;
	} // ( ... )*
#line 958 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "component_list");
			
#line 3634 "modelica_tree_parser.cpp"
	component_list_AST = currentAST.root;
	returnAST = component_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::component_declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 965 "walker.g"
	DOMNode* ast;
#line 3644 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_declaration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 965 "walker.g"
	
		DOMNode* cmt = 0;
		DOMNode* dec = 0;
	
	
#line 3655 "modelica_tree_parser.cpp"
	
	{
	dec=declaration(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	case EXTENDS:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 973 "walker.g"
	
				DOMElement *pComponentItem = pModelicaXMLDoc->createElement(X("component_item"));
				pComponentItem->appendChild(dec);
				if (cmt) pComponentItem->appendChild(cmt);
				ast = pComponentItem;
				/* ast = Absyn__COMPONENTITEM(dec,cmt ? mk_some(cmt) : mk_none()); */
			
#line 3693 "modelica_tree_parser.cpp"
	component_declaration_AST = currentAST.root;
	returnAST = component_declaration_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::declaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 984 "walker.g"
	DOMNode* ast;
#line 3703 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST declaration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST declaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 984 "walker.g"
	
		DOMNode* arr = 0;
		DOMNode* mod = 0;
		DOMNode* id = 0;
	
#line 3716 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t111 = _t;
	i = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i_AST = astFactory->create(i);
	astFactory->addASTChild(currentAST, i_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST111 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IDENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case LBRACK:
	{
		arr=array_subscripts(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		mod=modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST111;
	_t = __t111;
	_t = _t->getNextSibling();
#line 992 "walker.g"
	
				DOMElement *pComponent = pModelicaXMLDoc->createElement(X("component"));
				pComponent->setAttribute(X("ident"), str2xml(i));
				if (arr) pComponent->appendChild(arr);
				if (mod) pComponent->appendChild(mod);
				ast = pComponent;
				/* ast = Absyn__COMPONENT(id, arr, mod ? mk_some(mod) : mk_none()); */
			
#line 3787 "modelica_tree_parser.cpp"
	declaration_AST = currentAST.root;
	returnAST = declaration_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1002 "walker.g"
	DOMNode* ast;
#line 3797 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST modification_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1002 "walker.g"
	
		DOMNode* e = 0;
		DOMNode* cm = 0;
		int iswitch = 0;
	
#line 3808 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CLASS_MODIFICATION:
	{
		cm=class_modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case AND:
		case END:
		case FALSE:
		case IF:
		case NOT:
		case OR:
		case TRUE:
		case UNSIGNED_REAL:
		case LPAR:
		case LBRACK:
		case LBRACE:
		case PLUS:
		case MINUS:
		case STAR:
		case SLASH:
		case DOT:
		case LESS:
		case LESSEQ:
		case GREATER:
		case GREATEREQ:
		case EQEQ:
		case LESSGT:
		case POWER:
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
		{
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case 3:
		case STRING_COMMENT:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		break;
	}
	case EQUALS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t117 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp35_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp35_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp35_AST = astFactory->create(_t);
		tmp35_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp35_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST117 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,EQUALS);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST117;
		_t = __t117;
		_t = _t->getNextSibling();
#line 1010 "walker.g"
		iswitch = 1;
#line 3902 "modelica_tree_parser.cpp"
		break;
	}
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t118 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp36_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp36_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp36_AST = astFactory->create(_t);
		tmp36_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp36_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST118 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ASSIGN);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST118;
		_t = __t118;
		_t = _t->getNextSibling();
#line 1011 "walker.g"
		iswitch = 2;
#line 3926 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 1013 "walker.g"
	
				DOMElement *pModificationEQorASorARG = null;
				if (iswitch == 1) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_equals"));
				if (iswitch == 2) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_assign"));
				if (iswitch == 0) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_arguments"));
				if (e) pModificationEQorASorARG->appendChild(e);
				if (cm) pModificationEQorASorARG->appendChild(cm);
				ast = pModificationEQorASorARG;
				/* ast = Absyn__CLASSMOD(cm, e); */
			
#line 3946 "modelica_tree_parser.cpp"
	modification_AST = currentAST.root;
	returnAST = modification_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1796 "walker.g"
	DOMNode* ast;
#line 3956 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case END:
	case FALSE:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case RANGE2:
	case RANGE3:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=simple_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case IF:
	{
		ast=if_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
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
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	expression_AST = currentAST.root;
	returnAST = expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::argument_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1036 "walker.g"
	DOMNode* ast;
#line 4038 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1036 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
	
#line 4048 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t123 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp37_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp37_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp37_AST = astFactory->create(_t);
	tmp37_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp37_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST123 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ARGUMENT_LIST);
	_t = _t->getFirstChild();
	e=argument(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1043 "walker.g"
	el_stack.push(e);
#line 4066 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ELEMENT_MODIFICATION || _t->getType() == ELEMENT_REDECLARATION)) {
			e=argument(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1044 "walker.g"
			el_stack.push(e);
#line 4077 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop125;
		}
		
	}
	_loop125:;
	} // ( ... )*
	currentAST = __currentAST123;
	_t = __t123;
	_t = _t->getNextSibling();
#line 1046 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "argument_list");
			
#line 4093 "modelica_tree_parser.cpp"
	argument_list_AST = currentAST.root;
	returnAST = argument_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1051 "walker.g"
	DOMNode* ast;
#line 4103 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELEMENT_MODIFICATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t127 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp38_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp38_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp38_AST = astFactory->create(_t);
		tmp38_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp38_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST127 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ELEMENT_MODIFICATION);
		_t = _t->getFirstChild();
		ast=element_modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST127;
		_t = __t127;
		_t = _t->getNextSibling();
		argument_AST = currentAST.root;
		break;
	}
	case ELEMENT_REDECLARATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t128 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp39_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp39_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp39_AST = astFactory->create(_t);
		tmp39_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp39_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST128 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ELEMENT_REDECLARATION);
		_t = _t->getFirstChild();
		ast=element_redeclaration(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST128;
		_t = __t128;
		_t = _t->getNextSibling();
		argument_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = argument_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::element_modification(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1058 "walker.g"
	DOMNode* ast;
#line 4169 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_modification_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_modification_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1058 "walker.g"
	
		DOMNode* cref;
		DOMNode* mod=0;
		DOMNode* cmt=0;
	
#line 4184 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EACH:
	{
		e = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		e_AST = astFactory->create(e);
		astFactory->addASTChild(currentAST, e_AST);
		match(_t,EACH);
		_t = _t->getNextSibling();
		break;
	}
	case FINAL:
	case DOT:
	case IDENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FINAL:
	{
		f = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST f_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		f_AST = astFactory->create(f);
		astFactory->addASTChild(currentAST, f_AST);
		match(_t,FINAL);
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	case ASSIGN:
	case CLASS_MODIFICATION:
	{
		mod=modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	case STRING_COMMENT:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1070 "walker.g"
	
	
				DOMElement *pModification = pModelicaXMLDoc->createElement(X("modification"));
				if (f) pModification->setAttribute(X("final"), X("true"));
				if (e) pModification->setAttribute(X("each"), X("true"));
				pModification->appendChild(cref);
				if (mod) pModification->appendChild(mod);
				if (cmt) pModification->appendChild(cmt);
				ast = pModification;
				/*
				ast = Absyn__MODIFICATION(final, each, cref, mod ? mk_some(mod) : mk_none(), cmt ? mk_some(cmt) : mk_none());
				*/
			
#line 4281 "modelica_tree_parser.cpp"
	element_modification_AST = currentAST.root;
	returnAST = element_modification_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::element_redeclaration(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1085 "walker.g"
	DOMNode* ast;
#line 4291 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST element_redeclaration_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST element_redeclaration_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST r_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST f_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST re = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST re_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1085 "walker.g"
	
		DOMNode* class_def = 0;
		DOMNode* e_spec = 0; 
		DOMNode* constr = 0;
		DOMNode* final = 0;
		DOMNode* each = 0;
	
#line 4312 "modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t135 = _t;
	r = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST r_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	r_AST = astFactory->create(r);
	astFactory->addASTChild(currentAST, r_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST135 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,REDECLARE);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EACH:
	{
		e = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		e_AST = astFactory->create(e);
		astFactory->addASTChild(currentAST, e_AST);
		match(_t,EACH);
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
	case IDENT:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case FINAL:
	{
		f = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST f_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		f_AST = astFactory->create(f);
		astFactory->addASTChild(currentAST, f_AST);
		match(_t,FINAL);
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
	case IDENT:
	case CLASS_DEFINITION:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CONSTANT:
	case DISCRETE:
	case FLOW:
	case INPUT:
	case OUTPUT:
	case PARAMETER:
	case DOT:
	case IDENT:
	case CLASS_DEFINITION:
	{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,false);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1097 "walker.g"
			
										DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
										pElementRedeclaration->appendChild(class_def);
										if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
										if (each) pElementRedeclaration->setAttribute(X("each"), X("true"));
										ast = pElementRedeclaration;
										/*
										e_spec = Absyn__CLASSDEF(RML_FALSE,class_def);
										final = f != NULL ? RML_TRUE : RML_FALSE;
										each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH;				
										ast = Absyn__REDECLARATION(final, each, e_spec, mk_none());
										*/
									
#line 4429 "modelica_tree_parser.cpp"
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			e_spec=component_clause1(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1111 "walker.g"
			
										DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
										pElementRedeclaration->appendChild(e_spec);
										if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
										if (each) pElementRedeclaration->setAttribute(X("each"), X("true"));
										ast = pElementRedeclaration;
										/*
										final = f != NULL ? RML_TRUE : RML_FALSE;
										each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH;				
										ast = Absyn__REDECLARATION(final, each, e_spec, mk_none());
										*/
									
#line 4457 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		break;
	}
	case REPLACEABLE:
	{
		{
		re = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST re_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		re_AST = astFactory->create(re);
		astFactory->addASTChild(currentAST, re_AST);
		match(_t,REPLACEABLE);
		_t = _t->getNextSibling();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			class_def=class_definition(_t,false);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case CONSTANT:
		case DISCRETE:
		case FLOW:
		case INPUT:
		case OUTPUT:
		case PARAMETER:
		case DOT:
		case IDENT:
		{
			e_spec=component_clause1(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXTENDS:
		{
			constr=constraining_clause(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			break;
		}
		case 3:
		{
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 1130 "walker.g"
			
									DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
									if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
									if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
									if (re) pElementRedeclaration->setAttribute(X("replaceable"), X("true"));
									if (class_def) 
									{
										pElementRedeclaration->appendChild(class_def);
										if (constr) pElementRedeclaration->appendChild(constr);
									}
									else
									{
										pElementRedeclaration->appendChild(e_spec);
										if (constr) pElementRedeclaration->appendChild(constr);
									}
									ast = pElementRedeclaration;
									/*
									if (class_def) 
									{	
										e_spec = Absyn__CLASSDEF(RML_TRUE, class_def);	final = f != NULL ? RML_TRUE : RML_FALSE;
										each = e != NULL ? Absyn__EACH : Absyn__NON_5fEACH; 	
										ast = Absyn__REDECLARATION(final, each, e_spec,	constr ? mk_some(constr) : mk_none());
									} 
									else {	ast = Absyn__REDECLARATION(final, each, e_spec,	constr ? mk_some(constr) : mk_none());	}
									*/
								
#line 4556 "modelica_tree_parser.cpp"
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST135;
	_t = __t135;
	_t = _t->getNextSibling();
	}
	element_redeclaration_AST = currentAST.root;
	returnAST = element_redeclaration_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::component_clause1(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1162 "walker.g"
	DOMNode* ast;
#line 4579 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause1_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_clause1_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1162 "walker.g"
	
		type_prefix_t pfx;
		DOMNode* attr = 0;
		DOMNode* path = 0;
		DOMNode* arr = 0;
		DOMNode* comp_decl = 0;
		DOMNode* comp_list = 0;
	
#line 4593 "modelica_tree_parser.cpp"
	
	type_prefix(_t,pfx);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	path=type_specifier(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	comp_decl=component_declaration(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1175 "walker.g"
	
				DOMElement* pComponents = pModelicaXMLDoc->createElement(X("components"));
				if (path)            pComponents->appendChild(path);
				if (pfx.flow)        pComponents->appendChild(pfx.flow);
				if (pfx.variability) pComponents->appendChild(pfx.variability);
				if (pfx.direction)   pComponents->appendChild(pfx.direction);
				if (comp_decl)       pComponents->appendChild(comp_decl);
				ast = pComponents;
				/*
				if (!arr) {	arr = mk_nil();	}
				comp_list = mk_cons(comp_decl,mk_nil());
				attr = Absyn__ATTR(pfx.flow,pfx.variability,pfx.direction,arr);
				ast = Absyn__COMPONENTS(attr, path, comp_list);
				*/
			
#line 4620 "modelica_tree_parser.cpp"
	component_clause1_AST = currentAST.root;
	returnAST = component_clause1_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1292 "walker.g"
	DOMNode* ast;
#line 4630 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1292 "walker.g"
	
		DOMNode* cmt = 0;
	
#line 4639 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t162 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp40_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp40_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp40_AST = astFactory->create(_t);
	tmp40_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp40_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST162 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUATION_STATEMENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUALS:
	{
		ast=equality_equation(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case IF:
	{
		ast=conditional_equation_e(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case FOR:
	{
		ast=for_clause_e(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case WHEN:
	{
		ast=when_clause_e(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case CONNECT:
	{
		ast=connect_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case IDENT:
	{
		ast=equation_funcall(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 1306 "walker.g"
	
					DOMElement*  pEquation = pModelicaXMLDoc->createElement(X("equation"));
					pEquation->appendChild(ast);
					if (cmt) pEquation->appendChild(cmt);
					ast = pEquation;
					/* ast = Absyn__EQUATIONITEM(ast,cmt ? mk_some(cmt) : mk_none()); */
				
#line 4733 "modelica_tree_parser.cpp"
	currentAST = __currentAST162;
	_t = __t162;
	_t = _t->getNextSibling();
	equation_AST = currentAST.root;
	returnAST = equation_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::algorithm(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1331 "walker.g"
	DOMNode* ast;
#line 4746 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1331 "walker.g"
	
		DOMNode* cref;
		DOMNode* expr;
		DOMNode* tuple;
		DOMNode* args;
		DOMNode* cmt=0;
	
#line 4759 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t167 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp41_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp41_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp41_AST = astFactory->create(_t);
	tmp41_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp41_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST167 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ALGORITHM_STATEMENT);
	_t = _t->getFirstChild();
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ASSIGN:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t169 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp42_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp42_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp42_AST = astFactory->create(_t);
		tmp42_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp42_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST169 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,ASSIGN);
		_t = _t->getFirstChild();
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			expr=expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1343 "walker.g"
			
										DOMElement*  pAlgAssign = pModelicaXMLDoc->createElement(X("alg_assign"));
										pAlgAssign->appendChild(cref);
										pAlgAssign->appendChild(expr);
										ast = pAlgAssign;
										/* ast = Absyn__ALG_5fASSIGN(cref,expr); */
									
#line 4810 "modelica_tree_parser.cpp"
			break;
		}
		case EXPRESSION_LIST:
		{
			{
			tuple=expression_list(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			args=function_call(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			}
#line 1351 "walker.g"
			
										DOMElement*  pAlgAssign = pModelicaXMLDoc->createElement(X("alg_assign"));
										pAlgAssign->appendChild(tuple);
										pAlgAssign->appendChild(cref);
										pAlgAssign->appendChild(args);
										ast = pAlgAssign;
										/*
			<!ELEMENT alg_assign ((component_reference, %exp;) | (output_expression_list, component_reference, function_arguments))>
			<!ATTLIST alg_assign
				%location; 
			>
			*/
										/* ast = Absyn__ALG_5fTUPLE_5fASSIGN(Absyn__TUPLE(tuple),Absyn__CALL(cref,args)); */
									
#line 4841 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		currentAST = __currentAST169;
		_t = __t169;
		_t = _t->getNextSibling();
		break;
	}
	case DOT:
	case IDENT:
	{
		ast=algorithm_function_call(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case IF:
	{
		ast=conditional_equation_a(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case FOR:
	{
		ast=for_clause_a(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case WHILE:
	{
		ast=while_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case WHEN:
	{
		ast=when_clause_a(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case COMMENT:
	{
		cmt=comment(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 1374 "walker.g"
		
					DOMElement*  pAlgorithm = pModelicaXMLDoc->createElement(X("algorithm"));
					pAlgorithm->appendChild(ast);
					if (cmt) pAlgorithm->appendChild(cmt);
					ast = pAlgorithm;
					/*
					<!ELEMENT algorithm ((alg_assign | alg_call | alg_if | alg_for | alg_while | alg_when | alg_break | alg_return), comment?)>
					<!ATTLIST algorithm
						initial (true) #IMPLIED
						%location; 
					>
					*/
					/* ast = Absyn__ALGORITHMITEM(ast, cmt ?  mk_some(cmt) : mk_none()); */
		  		
#line 4933 "modelica_tree_parser.cpp"
	currentAST = __currentAST167;
	_t = __t167;
	_t = _t->getNextSibling();
	algorithm_AST = currentAST.root;
	returnAST = algorithm_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::equality_equation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1413 "walker.g"
	DOMNode* ast;
#line 4946 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equality_equation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equality_equation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1413 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
	
#line 4956 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t175 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp43_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp43_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp43_AST = astFactory->create(_t);
	tmp43_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp43_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST175 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUALS);
	_t = _t->getFirstChild();
	e1=simple_expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	e2=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST175;
	_t = __t175;
	_t = _t->getNextSibling();
#line 1420 "walker.g"
	
				DOMElement*  pEquEqual = pModelicaXMLDoc->createElement(X("equ_equal"));
				pEquEqual->appendChild(e1);
				pEquEqual->appendChild(e2);
				ast = pEquEqual;
				/*
				<!ELEMENT equ_equal (%exp;, %exp;)>
				<!ATTLIST equ_equal
					%location; 
				>
				*/
				/* ast = Absyn__EQ_5fEQUALS(e1,e2); */
			
#line 4992 "modelica_tree_parser.cpp"
	equality_equation_AST = currentAST.root;
	returnAST = equality_equation_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::conditional_equation_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1435 "walker.g"
	DOMNode* ast;
#line 5002 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1435 "walker.g"
	
		DOMNode* e1;
		DOMNode* then_b;
		DOMNode* else_b = 0;
		DOMNode* else_if_b;
		l_stack el_stack;
		DOMNode* e;
	
#line 5016 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t177 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp44_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp44_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp44_AST = astFactory->create(_t);
	tmp44_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp44_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST177 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	then_b=equation_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=equation_elseif(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1448 "walker.g"
			el_stack.push(e);
#line 5045 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop179;
		}
		
	}
	_loop179:;
	} // ( ... )*
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp45_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp45_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp45_AST = astFactory->create(_t);
		tmp45_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp45_AST);
		match(_t,ELSE);
		_t = _t->getNextSibling();
		else_b=equation_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST177;
	_t = __t177;
	_t = _t->getNextSibling();
#line 1451 "walker.g"
	
				/* else_if_b = (DOMElement*)stack2DOMNode(el_stack, else_if_b); */
				DOMElement*  pEquIf = pModelicaXMLDoc->createElement(X("equ_if"));
				pEquIf->appendChild(e1);
				pEquIf->appendChild(then_b);
				if (el_stack.size()>0) pEquIf = (DOMElement*)appendKids(el_stack, pEquIf); // ?? is this ok?
				if (else_b)    pEquIf->appendChild(else_b);
				ast = pEquIf;
				/* ast = Absyn__EQ_5fIF(e1, then_b, else_if_b, else_b); */
			
#line 5096 "modelica_tree_parser.cpp"
	conditional_equation_e_AST = currentAST.root;
	returnAST = conditional_equation_e_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::for_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1495 "walker.g"
	DOMNode* ast;
#line 5106 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1495 "walker.g"
	
		DOMNode* f;
		DOMNode* eq;
	
#line 5116 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t187 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp46_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp46_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp46_AST = astFactory->create(_t);
	tmp46_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp46_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST187 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,FOR);
	_t = _t->getFirstChild();
	f=for_indices(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	eq=equation_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST187;
	_t = __t187;
	_t = _t->getNextSibling();
#line 1502 "walker.g"
	
				DOMElement*  pEquFor = pModelicaXMLDoc->createElement(X("equ_for"));
				pEquFor->appendChild(f);
				pEquFor->appendChild(eq);
				ast = pEquFor;
				/*
				<!ELEMENT equ_for (for_indices, %equation_list;)>
				<!ATTLIST equ_for
					%location; 
				>
				*/
				/*
				id = str2xml(i);
				ast = Absyn__EQ_5fFOR(id,e,eq);
				*/
			
#line 5155 "modelica_tree_parser.cpp"
	for_clause_e_AST = currentAST.root;
	returnAST = for_clause_e_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::when_clause_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1584 "walker.g"
	DOMNode* ast;
#line 5165 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1584 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
		DOMNode* body;
		DOMNode* el = 0;
	
#line 5177 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t198 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp47_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp47_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp47_AST = astFactory->create(_t);
	tmp47_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp47_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST198 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	body=equation_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ELSEWHEN)) {
			el=else_when_e(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1595 "walker.g"
			el_stack.push(el);
#line 5206 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop200;
		}
		
	}
	_loop200:;
	} // ( ... )*
	currentAST = __currentAST198;
	_t = __t198;
	_t = _t->getNextSibling();
#line 1597 "walker.g"
	
				DOMElement* pEquWhen = pModelicaXMLDoc->createElement(X("equ_when"));
				pEquWhen->appendChild(e);
				DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
				pEquThen->appendChild(body);
				pEquWhen->appendChild(pEquThen);
				pEquWhen = (DOMElement*)appendKids(el_stack, pEquWhen); // ??is this ok?
				ast = pEquWhen;
				/* ast = Absyn__EQ_5fWHEN_5fE(e,body,(DOMElement*)stack2DOMNode(el_stack)); */
			
#line 5229 "modelica_tree_parser.cpp"
	when_clause_e_AST = currentAST.root;
	returnAST = when_clause_e_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::connect_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1738 "walker.g"
	DOMNode* ast;
#line 5239 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST connect_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST connect_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1738 "walker.g"
	
		DOMNode* r1;
		DOMNode* r2;
	
#line 5249 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t220 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp48_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp48_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp48_AST = astFactory->create(_t);
	tmp48_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp48_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST220 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,CONNECT);
	_t = _t->getFirstChild();
	r1=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	r2=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST220;
	_t = __t220;
	_t = _t->getNextSibling();
#line 1748 "walker.g"
	
				DOMElement* pEquConnect = pModelicaXMLDoc->createElement(X("equ_connect"));
				pEquConnect->appendChild(r1);
				pEquConnect->appendChild(r2);
				ast = pEquConnect;
				/* ast = Absyn__EQ_5fCONNECT(r1,r2); */
			
#line 5279 "modelica_tree_parser.cpp"
	connect_clause_AST = currentAST.root;
	returnAST = connect_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::equation_funcall(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1316 "walker.g"
	DOMNode* ast;
#line 5289 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_funcall_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_funcall_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1316 "walker.g"
	
	DOMNode* fcall = 0;
	
#line 5300 "modelica_tree_parser.cpp"
	
	i = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i_AST = astFactory->create(i);
	astFactory->addASTChild(currentAST, i_AST);
	match(_t,IDENT);
	_t = _t->getNextSibling();
	fcall=function_call(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1322 "walker.g"
	
				 DOMElement*  pEquCall = pModelicaXMLDoc->createElement(X("equ_call"));
				 pEquCall->setAttribute(X("ident"), str2xml(i));
				 pEquCall->appendChild(fcall);
				 ast = pEquCall;			
				/* ast = Absyn__EQ_5fNORETCALL(str2xml(i),fcall);  */
			
#line 5319 "modelica_tree_parser.cpp"
	equation_funcall_AST = currentAST.root;
	returnAST = equation_funcall_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2323 "walker.g"
	DOMNode* ast;
#line 5329 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t302 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp49_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp49_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp49_AST = astFactory->create(_t);
	tmp49_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp49_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST302 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,FUNCTION_ARGUMENTS);
	_t = _t->getFirstChild();
	ast=function_arguments(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST302;
	_t = __t302;
	_t = _t->getNextSibling();
	function_call_AST = currentAST.root;
	returnAST = function_call_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::algorithm_function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1391 "walker.g"
	DOMNode* ast;
#line 5361 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1391 "walker.g"
	
		DOMNode* cref;
		DOMNode* args;
	
#line 5371 "modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	args=function_call(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1398 "walker.g"
	
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
				/* ast = Absyn__ALG_5fNORETCALL(cref,args); */
			
#line 5393 "modelica_tree_parser.cpp"
	algorithm_function_call_AST = currentAST.root;
	returnAST = algorithm_function_call_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::conditional_equation_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1463 "walker.g"
	DOMNode* ast;
#line 5403 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST conditional_equation_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1463 "walker.g"
	
		DOMNode* e1;
		DOMNode* then_b;
		DOMNode* else_b = 0;
		DOMNode* else_if_b;
		l_stack el_stack;
		DOMNode* e;
	
#line 5417 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t182 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp50_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp50_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp50_AST = astFactory->create(_t);
	tmp50_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp50_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST182 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	then_b=algorithm_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=algorithm_elseif(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1476 "walker.g"
			el_stack.push(e);
#line 5446 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop184;
		}
		
	}
	_loop184:;
	} // ( ... )*
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp51_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp51_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp51_AST = astFactory->create(_t);
		tmp51_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp51_AST);
		match(_t,ELSE);
		_t = _t->getNextSibling();
		else_b=algorithm_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	currentAST = __currentAST182;
	_t = __t182;
	_t = _t->getNextSibling();
#line 1479 "walker.g"
	
				/*
				else_if_b = pModelicaXMLDoc->createElement(X("alg_elseif"));
				else_if_b = (DOMElement*)stack2DOMNode(el_stack, else_if_b);
				*/
				DOMElement*  pAlgIf = pModelicaXMLDoc->createElement(X("alg_if"));
				pAlgIf->appendChild(e1);
				pAlgIf->appendChild(then_b);
				if (el_stack.size()>0) pAlgIf = (DOMElement*)appendKids(el_stack, pAlgIf);
				if (else_b)    pAlgIf->appendChild(else_b);
				ast = pAlgIf;
	
				/* ast = Absyn__ALG_5fIF(e1, then_b, else_if_b, else_b); */
			
#line 5501 "modelica_tree_parser.cpp"
	conditional_equation_a_AST = currentAST.root;
	returnAST = conditional_equation_a_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::for_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1521 "walker.g"
	DOMNode* ast;
#line 5511 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1521 "walker.g"
	
		DOMNode* f;
		DOMNode* eq;
	
#line 5521 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t189 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp52_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp52_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp52_AST = astFactory->create(_t);
	tmp52_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp52_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST189 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,FOR);
	_t = _t->getFirstChild();
	f=for_indices(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	eq=algorithm_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST189;
	_t = __t189;
	_t = _t->getNextSibling();
#line 1528 "walker.g"
	
				DOMElement*  pEquFor = pModelicaXMLDoc->createElement(X("alg_for"));
				pEquFor->appendChild(f);
				pEquFor->appendChild(eq);
				ast = pEquFor;
				/*
				id = str2xml(i);
				ast = Absyn__ALG_5fFOR(id,e,eq);
				*/
			
#line 5554 "modelica_tree_parser.cpp"
	for_clause_a_AST = currentAST.root;
	returnAST = for_clause_a_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::while_clause(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1564 "walker.g"
	DOMNode* ast;
#line 5564 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST while_clause_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST while_clause_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1564 "walker.g"
	
		DOMNode* e;
		DOMNode* body;
	
#line 5574 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t196 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp53_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp53_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp53_AST = astFactory->create(_t);
	tmp53_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp53_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST196 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WHILE);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	body=algorithm_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST196;
	_t = __t196;
	_t = _t->getNextSibling();
#line 1573 "walker.g"
	
				DOMElement* pAlgWhile = pModelicaXMLDoc->createElement(X("alg_while"));
				pAlgWhile->appendChild(e);
				pAlgWhile->appendChild(body);
				ast = pAlgWhile;
				/*
				ast = Absyn__ALG_5fWHILE(e,body);
				*/
			
#line 5606 "modelica_tree_parser.cpp"
	while_clause_AST = currentAST.root;
	returnAST = while_clause_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::when_clause_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1629 "walker.g"
	DOMNode* ast;
#line 5616 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST when_clause_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1629 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
		DOMNode* body;
		DOMNode* el = 0;
	
#line 5628 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t204 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp54_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp54_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp54_AST = astFactory->create(_t);
	tmp54_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp54_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST204 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	body=algorithm_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ELSEWHEN)) {
			el=else_when_a(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1640 "walker.g"
			el_stack.push(el);
#line 5657 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop206;
		}
		
	}
	_loop206:;
	} // ( ... )*
	currentAST = __currentAST204;
	_t = __t204;
	_t = _t->getNextSibling();
#line 1642 "walker.g"
	
				DOMElement* pAlgWhen = pModelicaXMLDoc->createElement(X("alg_when"));
				pAlgWhen->appendChild(e);
				DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
				pAlgThen->appendChild(body);
				pAlgWhen->appendChild(pAlgThen);
				pAlgWhen = (DOMElement*)appendKids(el_stack, pAlgWhen);
				ast = pAlgWhen;
				/* ast = Absyn__ALG_5fWHEN_5fA(e,body,(DOMElement*)stack2DOMNode(el_stack)); */
			
#line 5680 "modelica_tree_parser.cpp"
	when_clause_a_AST = currentAST.root;
	returnAST = when_clause_a_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::simple_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1930 "walker.g"
	DOMNode* ast;
#line 5690 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST simple_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST simple_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1930 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
		DOMNode* e3;
	
#line 5701 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case RANGE3:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t246 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp55_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp55_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp55_AST = astFactory->create(_t);
		tmp55_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp55_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST246 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,RANGE3);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e3=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST246;
		_t = __t246;
		_t = _t->getNextSibling();
#line 1940 "walker.g"
		
						DOMElement* pRange = pModelicaXMLDoc->createElement(X("range"));
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
						/* ast = Absyn__RANGE(e1,mk_some(e2),e3); */
					
#line 5747 "modelica_tree_parser.cpp"
		break;
	}
	case RANGE2:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t247 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp56_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp56_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp56_AST = astFactory->create(_t);
		tmp56_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp56_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST247 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,RANGE2);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e3=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST247;
		_t = __t247;
		_t = _t->getNextSibling();
#line 1955 "walker.g"
		
						DOMElement* pRange = pModelicaXMLDoc->createElement(X("range"));
						pRange->appendChild(e1);
						pRange->appendChild(e3);
						ast = pRange;
						/* ast = Absyn__RANGE(e1,mk_none(),e3); */
					
#line 5780 "modelica_tree_parser.cpp"
		break;
	}
	case AND:
	case END:
	case FALSE:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	simple_expression_AST = currentAST.root;
	returnAST = simple_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::equation_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1714 "walker.g"
	DOMNode* ast;
#line 5833 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1714 "walker.g"
	
		DOMNode* e;
		l_stack el_stack;
	
#line 5843 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == EQUATION_STATEMENT)) {
			e=equation(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1720 "walker.g"
			el_stack.push(e);
#line 5855 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop215;
		}
		
	}
	_loop215:;
	} // ( ... )*
#line 1721 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "equation_list");
			
#line 5868 "modelica_tree_parser.cpp"
	equation_list_AST = currentAST.root;
	returnAST = equation_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::equation_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1672 "walker.g"
	DOMNode* ast;
#line 5878 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_elseif_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST equation_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1672 "walker.g"
	
		DOMNode* e;
		DOMNode* eq;
	
#line 5888 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t210 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp57_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp57_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp57_AST = astFactory->create(_t);
	tmp57_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp57_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST210 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	eq=equation_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST210;
	_t = __t210;
	_t = _t->getNextSibling();
#line 1682 "walker.g"
	
				DOMElement* pEquElseIf = pModelicaXMLDoc->createElement(X("equ_else_if"));
				pEquElseIf->appendChild(e);
				DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
				pEquThen->appendChild(eq);
				pEquElseIf->appendChild(pEquThen);
				ast = pEquElseIf;
				/* ast = mk_box2(0,e,eq); */
			
#line 5920 "modelica_tree_parser.cpp"
	equation_elseif_AST = currentAST.root;
	returnAST = equation_elseif_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::algorithm_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1726 "walker.g"
	DOMNode* ast;
#line 5930 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1726 "walker.g"
	
		DOMNode* e;
		l_stack el_stack;
	
#line 5940 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ALGORITHM_STATEMENT)) {
			e=algorithm(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1732 "walker.g"
			el_stack.push(e);
#line 5952 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop218;
		}
		
	}
	_loop218:;
	} // ( ... )*
#line 1733 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "algorithm_list");
			
#line 5965 "modelica_tree_parser.cpp"
	algorithm_list_AST = currentAST.root;
	returnAST = algorithm_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::algorithm_elseif(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1693 "walker.g"
	DOMNode* ast;
#line 5975 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_elseif_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST algorithm_elseif_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1693 "walker.g"
	
		DOMNode* e;
		DOMNode* body;
	
#line 5985 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t212 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp58_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp58_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp58_AST = astFactory->create(_t);
	tmp58_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp58_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST212 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	body=algorithm_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST212;
	_t = __t212;
	_t = _t->getNextSibling();
#line 1703 "walker.g"
	
				DOMElement* pAlgElseIf = pModelicaXMLDoc->createElement(X("alg_else_if"));
				pAlgElseIf->appendChild(e);
				DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
				pAlgThen->appendChild(body);
				pAlgElseIf->appendChild(pAlgThen);
				ast = pAlgElseIf;
				/* ast = mk_box2(0,e,body); */
			
#line 6017 "modelica_tree_parser.cpp"
	algorithm_elseif_AST = currentAST.root;
	returnAST = algorithm_elseif_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::for_indices(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1542 "walker.g"
	DOMNode* ast;
#line 6027 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST for_indices_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST for_indices_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1542 "walker.g"
	
		DOMNode* f;
		DOMNode* e;
		l_stack el_stack;
	
#line 6040 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == IN)) {
			ANTLR_USE_NAMESPACE(antlr)RefAST __t192 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp59_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp59_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp59_AST = astFactory->create(_t);
			tmp59_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp59_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST192 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,IN);
			_t = _t->getFirstChild();
			i = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			i_AST = astFactory->create(i);
			astFactory->addASTChild(currentAST, i_AST);
			match(_t,IDENT);
			_t = _t->getNextSibling();
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case AND:
			case END:
			case FALSE:
			case IF:
			case NOT:
			case OR:
			case TRUE:
			case UNSIGNED_REAL:
			case LPAR:
			case LBRACK:
			case LBRACE:
			case PLUS:
			case MINUS:
			case STAR:
			case SLASH:
			case DOT:
			case LESS:
			case LESSEQ:
			case GREATER:
			case GREATEREQ:
			case EQEQ:
			case LESSGT:
			case POWER:
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
			{
				e=expression(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			currentAST = __currentAST192;
			_t = __t192;
			_t = _t->getNextSibling();
#line 1550 "walker.g"
			
					DOMElement* pForIndex = pModelicaXMLDoc->createElement(X("for_index"));
					pForIndex->setAttribute(X("ident"), str2xml(i));
					if (e) pForIndex->appendChild(e);
					el_stack.push(pForIndex); 
				
#line 6133 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop194;
		}
		
	}
	_loop194:;
	} // ( ... )*
#line 1557 "walker.g"
	
			DOMElement*  pForIndices = pModelicaXMLDoc->createElement(X("for_indices"));
			pForIndices = (DOMElement*)appendKids(el_stack, pForIndices);
			ast = pForIndices;
		
#line 6148 "modelica_tree_parser.cpp"
	for_indices_AST = currentAST.root;
	returnAST = for_indices_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::else_when_e(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1609 "walker.g"
	DOMNode* ast;
#line 6158 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_e_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1609 "walker.g"
	
		DOMNode*  expr;
		DOMNode*  eqn;
	
#line 6170 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t202 = _t;
	e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	e_AST = astFactory->create(e);
	astFactory->addASTChild(currentAST, e_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST202 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	eqn=equation_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST202;
	_t = __t202;
	_t = _t->getNextSibling();
#line 1616 "walker.g"
	
				DOMElement* pEquElseWhen = pModelicaXMLDoc->createElement(X("equ_elsewhen"));
				pEquElseWhen->appendChild(expr);
				DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
				pEquThen->appendChild(eqn);
				pEquElseWhen->appendChild(pEquThen);
				ast = pEquElseWhen;
				/*
				ast = mk_box2(0,expr,eqn);
				*/
			
#line 6203 "modelica_tree_parser.cpp"
	else_when_e_AST = currentAST.root;
	returnAST = else_when_e_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::else_when_a(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1654 "walker.g"
	DOMNode* ast;
#line 6213 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_a_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST else_when_a_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1654 "walker.g"
	
		DOMNode*  expr;
		DOMNode*  alg;
	
#line 6225 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t208 = _t;
	e = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST e_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	e_AST = astFactory->create(e);
	astFactory->addASTChild(currentAST, e_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST208 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	alg=algorithm_list(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST208;
	_t = __t208;
	_t = _t->getNextSibling();
#line 1661 "walker.g"
	
				DOMElement* pAlgElseWhen = pModelicaXMLDoc->createElement(X("alg_else_when"));
				pAlgElseWhen->appendChild(expr);
				DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
				pAlgThen->appendChild(alg);
				pAlgElseWhen->appendChild(pAlgThen);
				ast = pAlgElseWhen;
				/* ast = mk_box2(0,expr,alg); */
			
#line 6256 "modelica_tree_parser.cpp"
	else_when_a_AST = currentAST.root;
	returnAST = else_when_a_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::if_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1883 "walker.g"
	DOMNode* ast;
#line 6266 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST if_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST if_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1883 "walker.g"
	
		DOMNode* cond;
		DOMNode* thenPart;
		DOMNode* elsePart;
		DOMNode* e;
		DOMNode* elseifPart;
		l_stack el_stack;
	
#line 6280 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t239 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp60_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp60_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp60_AST = astFactory->create(_t);
	tmp60_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp60_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST239 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,IF);
	_t = _t->getFirstChild();
	cond=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	thenPart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=elseif_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 1894 "walker.g"
			el_stack.push(e);
#line 6309 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop241;
		}
		
	}
	_loop241:;
	} // ( ... )*
	elsePart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1895 "walker.g"
	
					/*elseifPart = pModelicaXMLDoc->createElement(X("elseif"));
					elseifPart = (DOMElement*)stack2DOMNode(el_stack, elseifPart);*/
					DOMElement* pIfExp = pModelicaXMLDoc->createElement(X("if"));
					pIfExp->appendChild(cond);
					pIfExp->appendChild(thenPart);
					if (el_stack.size()>0) pIfExp = (DOMElement*)appendKids(el_stack, pIfExp); //??is this ok??
					pIfExp->appendChild(elsePart);
					ast = pIfExp; 
					/*
					ast = Absyn__IFEXP(cond,thenPart,elsePart,elseifPart);
					*/
				
#line 6335 "modelica_tree_parser.cpp"
	currentAST = __currentAST239;
	_t = __t239;
	_t = _t->getNextSibling();
	if_expression_AST = currentAST.root;
	returnAST = if_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::code_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1805 "walker.g"
	DOMNode* ast;
#line 6348 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST code_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST code_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CODE_MODIFICATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t224 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp61_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp61_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp61_AST = astFactory->create(_t);
		tmp61_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp61_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST224 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_MODIFICATION);
		_t = _t->getFirstChild();
		{
		ast=modification(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST224;
		_t = __t224;
		_t = _t->getNextSibling();
#line 1808 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pModification = pModelicaXMLDoc->createElement(X("modification"));
					pModification->appendChild(ast);
					ast = pModification;
					/*
					ast = Absyn__CODE(Absyn__C_5fMODIFICATION(ast));
					*/
				
#line 6388 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	case CODE_EXPRESSION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t226 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp62_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp62_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp62_AST = astFactory->create(_t);
		tmp62_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp62_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST226 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_EXPRESSION);
		_t = _t->getFirstChild();
		{
		ast=expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST226;
		_t = __t226;
		_t = _t->getNextSibling();
#line 1819 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pExpression = pModelicaXMLDoc->createElement(X("expression"));
					pExpression->appendChild(ast);
					ast = pExpression;
					/* ast = Absyn__CODE(Absyn__C_5fEXPRESSION(ast)); */
				
#line 6421 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	case CODE_ELEMENT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t228 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp63_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp63_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp63_AST = astFactory->create(_t);
		tmp63_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp63_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST228 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_ELEMENT);
		_t = _t->getFirstChild();
		{
		ast=element(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST228;
		_t = __t228;
		_t = _t->getNextSibling();
#line 1828 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pElement = pModelicaXMLDoc->createElement(X("element"));
					pElement->appendChild(ast);
					ast = pElement;
					/* ast = Absyn__CODE(Absyn__C_5fELEMENT(ast)); */
				
#line 6454 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	case CODE_EQUATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t230 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp64_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp64_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp64_AST = astFactory->create(_t);
		tmp64_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp64_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST230 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_EQUATION);
		_t = _t->getFirstChild();
		{
		ast=equation_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST230;
		_t = __t230;
		_t = _t->getNextSibling();
#line 1837 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
					pEquationSection->appendChild(ast);
					ast = pEquationSection; 
					/* ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_FALSE, 
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1)))); */
				
#line 6488 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	case CODE_INITIALEQUATION:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t232 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp65_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp65_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp65_AST = astFactory->create(_t);
		tmp65_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp65_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST232 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_INITIALEQUATION);
		_t = _t->getFirstChild();
		{
		ast=equation_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST232;
		_t = __t232;
		_t = _t->getNextSibling();
#line 1847 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
					((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
					pEquationSection->appendChild(ast);
					ast = pEquationSection; 
					/*
					ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_TRUE, 
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 6525 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	case CODE_ALGORITHM:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t234 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp66_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp66_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp66_AST = astFactory->create(_t);
		tmp66_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp66_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST234 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_ALGORITHM);
		_t = _t->getFirstChild();
		{
		ast=algorithm_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST234;
		_t = __t234;
		_t = _t->getNextSibling();
#line 1859 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pAlgorithmSection = pModelicaXMLDoc->createElement(X("algorithm_section"));
					pAlgorithmSection->appendChild(ast);
					ast = pAlgorithmSection; 
					/*
					ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_FALSE, 
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 6561 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	case CODE_INITIALALGORITHM:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t236 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp67_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp67_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp67_AST = astFactory->create(_t);
		tmp67_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp67_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST236 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,CODE_INITIALALGORITHM);
		_t = _t->getFirstChild();
		{
		ast=algorithm_clause(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		}
		currentAST = __currentAST236;
		_t = __t236;
		_t = _t->getNextSibling();
#line 1870 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pAlgorithmSection = pModelicaXMLDoc->createElement(X("algorithm_section"));
					((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
					pAlgorithmSection->appendChild(ast);
					ast = pAlgorithmSection; 
					/*
					ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_TRUE, 
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 6598 "modelica_tree_parser.cpp"
		code_expression_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = code_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::elseif_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1911 "walker.g"
	DOMNode* ast;
#line 6615 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST elseif_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST elseif_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1911 "walker.g"
	
		DOMNode* cond;
		DOMNode* thenPart;
	
#line 6625 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t243 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp68_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp68_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp68_AST = astFactory->create(_t);
	tmp68_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp68_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST243 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,ELSEIF);
	_t = _t->getFirstChild();
	cond=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	thenPart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 1918 "walker.g"
	
				DOMElement* pElseIf = pModelicaXMLDoc->createElement(X("elseif"));
				pElseIf->appendChild(cond);
				DOMElement* pThen = pModelicaXMLDoc->createElement(X("then"));
				pThen->appendChild(thenPart);
				pElseIf->appendChild(pThen);
				ast = pElseIf;
				/*	ast = mk_box2(0,cond,thenPart); */
			
#line 6654 "modelica_tree_parser.cpp"
	currentAST = __currentAST243;
	_t = __t243;
	_t = _t->getNextSibling();
	elseif_expression_AST = currentAST.root;
	returnAST = elseif_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::logical_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1966 "walker.g"
	DOMNode* ast;
#line 6667 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1966 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
	
#line 6677 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case END:
	case FALSE:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=logical_term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case OR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t250 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp69_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp69_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp69_AST = astFactory->create(_t);
		tmp69_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp69_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST250 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,OR);
		_t = _t->getFirstChild();
		e1=logical_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=logical_term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST250;
		_t = __t250;
		_t = _t->getNextSibling();
#line 1974 "walker.g"
		
						DOMElement* pOr = pModelicaXMLDoc->createElement(X("or"));
						pOr->appendChild(e1);
						pOr->appendChild(e2);
						ast = pOr;
						/* ast = Absyn__LBINARY(e1,Absyn__OR, e2); */
					
#line 6747 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	logical_expression_AST = currentAST.root;
	returnAST = logical_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::logical_term(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 1985 "walker.g"
	DOMNode* ast;
#line 6765 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_term_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 1985 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
	
#line 6775 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case NOT:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=logical_factor(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case AND:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t253 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp70_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp70_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp70_AST = astFactory->create(_t);
		tmp70_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp70_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST253 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,AND);
		_t = _t->getFirstChild();
		e1=logical_term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=logical_factor(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST253;
		_t = __t253;
		_t = _t->getNextSibling();
#line 1993 "walker.g"
		
						DOMElement* pAnd = pModelicaXMLDoc->createElement(X("and"));
						pAnd->appendChild(e1);
						pAnd->appendChild(e2);
						ast = pAnd;
						/* ast = Absyn__LBINARY(e1,Absyn__AND,e2); */
					
#line 6844 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	logical_term_AST = currentAST.root;
	returnAST = logical_term_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::logical_factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2003 "walker.g"
	DOMNode* ast;
#line 6862 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_factor_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST logical_factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case NOT:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t255 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp71_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp71_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp71_AST = astFactory->create(_t);
		tmp71_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp71_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST255 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,NOT);
		_t = _t->getFirstChild();
		ast=relation(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
#line 2006 "walker.g"
		
				DOMElement* pNot = pModelicaXMLDoc->createElement(X("not"));
				pNot->appendChild(ast);
				ast = pNot;
				/* ast = Absyn__LUNARY(Absyn__NOT,ast); */
			
#line 6894 "modelica_tree_parser.cpp"
		currentAST = __currentAST255;
		_t = __t255;
		_t = _t->getNextSibling();
		logical_factor_AST = currentAST.root;
		break;
	}
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=relation(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		logical_factor_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = logical_factor_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::relation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2014 "walker.g"
	DOMNode* ast;
#line 6947 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST relation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST relation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2014 "walker.g"
	
		DOMNode* e1;
		DOMNode* op = 0;
		DOMNode* e2 = 0;
	
#line 6958 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
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
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case LESS:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t259 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp72_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp72_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp72_AST = astFactory->create(_t);
			tmp72_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp72_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST259 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,LESS);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			currentAST = __currentAST259;
			_t = __t259;
			_t = _t->getNextSibling();
#line 2024 "walker.g"
			op = pModelicaXMLDoc->createElement(X("lt")); /* Absyn__LESS; */
#line 7025 "modelica_tree_parser.cpp"
			break;
		}
		case LESSEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t260 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp73_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp73_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp73_AST = astFactory->create(_t);
			tmp73_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp73_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST260 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,LESSEQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			currentAST = __currentAST260;
			_t = __t260;
			_t = _t->getNextSibling();
#line 2026 "walker.g"
			op = pModelicaXMLDoc->createElement(X("lte")); /* Absyn__LESSEQ; */
#line 7052 "modelica_tree_parser.cpp"
			break;
		}
		case GREATER:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t261 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp74_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp74_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp74_AST = astFactory->create(_t);
			tmp74_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp74_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST261 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,GREATER);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			currentAST = __currentAST261;
			_t = __t261;
			_t = _t->getNextSibling();
#line 2028 "walker.g"
			op = pModelicaXMLDoc->createElement(X("gt")); /* Absyn__GREATER; */
#line 7079 "modelica_tree_parser.cpp"
			break;
		}
		case GREATEREQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t262 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp75_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp75_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp75_AST = astFactory->create(_t);
			tmp75_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp75_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST262 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,GREATEREQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			currentAST = __currentAST262;
			_t = __t262;
			_t = _t->getNextSibling();
#line 2030 "walker.g"
			op = pModelicaXMLDoc->createElement(X("gte")); /* Absyn__GREATEREQ; */
#line 7106 "modelica_tree_parser.cpp"
			break;
		}
		case EQEQ:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t263 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp76_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp76_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp76_AST = astFactory->create(_t);
			tmp76_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp76_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST263 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,EQEQ);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			currentAST = __currentAST263;
			_t = __t263;
			_t = _t->getNextSibling();
#line 2032 "walker.g"
			op = pModelicaXMLDoc->createElement(X("eq")); /* Absyn__EQUAL; */
#line 7133 "modelica_tree_parser.cpp"
			break;
		}
		case LESSGT:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t264 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp77_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp77_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp77_AST = astFactory->create(_t);
			tmp77_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp77_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST264 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,LESSGT);
			_t = _t->getFirstChild();
			e1=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			e2=arithmetic_expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			currentAST = __currentAST264;
			_t = __t264;
			_t = _t->getNextSibling();
#line 2034 "walker.g"
			op = pModelicaXMLDoc->createElement(X("ne")); /* op = Absyn__NEQUAL; */
#line 7160 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
#line 2036 "walker.g"
		
						((DOMElement*)op)->appendChild(e1);
						((DOMElement*)op)->appendChild(e2);
						ast = op;
						/* ast = Absyn__RELATION(e1,op,e2); */
					
#line 7176 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	relation_AST = currentAST.root;
	returnAST = relation_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2058 "walker.g"
	DOMNode* ast;
#line 7194 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST arithmetic_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2058 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
	
#line 7204 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case STAR:
	case SLASH:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	case UNARY_MINUS:
	case UNARY_PLUS:
	{
		ast=unary_arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t267 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp78_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp78_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp78_AST = astFactory->create(_t);
		tmp78_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp78_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST267 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,PLUS);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST267;
		_t = __t267;
		_t = _t->getNextSibling();
#line 2066 "walker.g"
		
						DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));
						pAdd->setAttribute(X("operation"), X("binary"));
						pAdd->appendChild(e1);
						pAdd->appendChild(e2);
						ast = pAdd;
						/* ast = Absyn__BINARY(e1,Absyn__ADD,e2); */
					
#line 7265 "modelica_tree_parser.cpp"
		break;
	}
	case MINUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t268 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp79_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp79_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp79_AST = astFactory->create(_t);
		tmp79_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp79_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST268 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,MINUS);
		_t = _t->getFirstChild();
		e1=arithmetic_expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST268;
		_t = __t268;
		_t = _t->getNextSibling();
#line 2075 "walker.g"
		
						DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
						pSub->setAttribute(X("operation"), X("binary"));
						pSub->appendChild(e1);
						pSub->appendChild(e2);
						ast = pSub;
						/* ast = Absyn__BINARY(e1,Absyn__SUB,e2); */
					
#line 7299 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	arithmetic_expression_AST = currentAST.root;
	returnAST = arithmetic_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::unary_arithmetic_expression(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2086 "walker.g"
	DOMNode* ast;
#line 7317 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST unary_arithmetic_expression_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST unary_arithmetic_expression_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNARY_PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t271 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp80_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp80_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp80_AST = astFactory->create(_t);
		tmp80_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp80_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST271 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,UNARY_PLUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST271;
		_t = __t271;
		_t = _t->getNextSibling();
#line 2089 "walker.g"
		
					DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));
					pAdd->setAttribute(X("operation"), X("unary"));
					pAdd->appendChild(ast);
					ast = pAdd;
					/* ast = Absyn__UNARY(Absyn__UPLUS,ast); */
				
#line 7354 "modelica_tree_parser.cpp"
		break;
	}
	case UNARY_MINUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t272 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp81_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp81_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp81_AST = astFactory->create(_t);
		tmp81_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp81_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST272 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,UNARY_MINUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST272;
		_t = __t272;
		_t = _t->getNextSibling();
#line 2097 "walker.g"
		
					DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
					pSub->setAttribute(X("operation"), X("unary"));
					pSub->appendChild(ast);
					ast = pSub;
					/* ast = Absyn__UNARY(Absyn__UMINUS,ast); */
				
#line 7384 "modelica_tree_parser.cpp"
		break;
	}
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case STAR:
	case SLASH:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	unary_arithmetic_expression_AST = currentAST.root;
	returnAST = unary_arithmetic_expression_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::term(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2108 "walker.g"
	DOMNode* ast;
#line 7424 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST term_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST term_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2108 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
	
#line 7434 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case DOT:
	case POWER:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=factor(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case STAR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t275 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp82_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp82_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp82_AST = astFactory->create(_t);
		tmp82_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp82_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST275 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,STAR);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=factor(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST275;
		_t = __t275;
		_t = _t->getNextSibling();
#line 2116 "walker.g"
		
						DOMElement* pMul = pModelicaXMLDoc->createElement(X("mul"));
						pMul->appendChild(e1);
						pMul->appendChild(e2);
						ast = pMul;
						/* ast = Absyn__BINARY(e1,Absyn__MUL,e2); */
					
#line 7490 "modelica_tree_parser.cpp"
		break;
	}
	case SLASH:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t276 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp83_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp83_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp83_AST = astFactory->create(_t);
		tmp83_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp83_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST276 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,SLASH);
		_t = _t->getFirstChild();
		e1=term(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=factor(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST276;
		_t = __t276;
		_t = _t->getNextSibling();
#line 2124 "walker.g"
		
						DOMElement* pDiv = pModelicaXMLDoc->createElement(X("div"));
						pDiv->appendChild(e1);
						pDiv->appendChild(e2);
						ast = pDiv;
						/* ast = Absyn__BINARY(e1,Absyn__DIV,e2); */
					
#line 7523 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	term_AST = currentAST.root;
	returnAST = term_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::factor(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2134 "walker.g"
	DOMNode* ast;
#line 7541 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST factor_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST factor_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2134 "walker.g"
	
		DOMNode* e1;
		DOMNode* e2;
	
#line 7551 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case END:
	case FALSE:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case DOT:
	case IDENT:
	case UNSIGNED_INTEGER:
	case STRING:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=primary(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case POWER:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t279 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp84_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp84_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp84_AST = astFactory->create(_t);
		tmp84_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp84_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST279 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,POWER);
		_t = _t->getFirstChild();
		e1=primary(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		e2=primary(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST279;
		_t = __t279;
		_t = _t->getNextSibling();
#line 2142 "walker.g"
		
						DOMElement* pPow = pModelicaXMLDoc->createElement(X("pow"));
						pPow->appendChild(e1);
						pPow->appendChild(e2);
						ast = pPow;
						/* ast = Absyn__BINARY(e1,Absyn__POW,e2); */
					
#line 7606 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	factor_AST = currentAST.root;
	returnAST = factor_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::primary(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2152 "walker.g"
	DOMNode* ast;
#line 7624 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST primary_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST primary_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ui = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ui_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ur = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST ur_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST str = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST str_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2152 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
	
#line 7640 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNSIGNED_INTEGER:
	{
		ui = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST ui_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ui_AST = astFactory->create(ui);
		astFactory->addASTChild(currentAST, ui_AST);
		match(_t,UNSIGNED_INTEGER);
		_t = _t->getNextSibling();
#line 2159 "walker.g"
		
						DOMElement* pIntegerLiteral = pModelicaXMLDoc->createElement(X("integer_literal"));
						pIntegerLiteral->setAttribute(X("value"), str2xml(ui));
						ast = pIntegerLiteral;
						/* ast = Absyn__INTEGER(mk_icon(str_to_int(ui->getText()))); */
					
#line 7661 "modelica_tree_parser.cpp"
		break;
	}
	case UNSIGNED_REAL:
	{
		ur = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST ur_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ur_AST = astFactory->create(ur);
		astFactory->addASTChild(currentAST, ur_AST);
		match(_t,UNSIGNED_REAL);
		_t = _t->getNextSibling();
#line 2166 "walker.g"
		
						DOMElement* pRealLiteral = pModelicaXMLDoc->createElement(X("real_literal"));
						pRealLiteral->setAttribute(X("value"), str2xml(ur));
						ast = pRealLiteral;
						/* ast = Absyn__REAL(mk_rcon(str_to_double(ur->getText()))); */
					
#line 7679 "modelica_tree_parser.cpp"
		break;
	}
	case STRING:
	{
		str = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST str_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		str_AST = astFactory->create(str);
		astFactory->addASTChild(currentAST, str_AST);
		match(_t,STRING);
		_t = _t->getNextSibling();
#line 2173 "walker.g"
		
						DOMElement* pStringLiteral = pModelicaXMLDoc->createElement(X("string_literal"));
						pStringLiteral->setAttribute(X("value"), str2xml(str));
						ast = pStringLiteral;
						/* ast = Absyn__STRING(str2xml(str)); */
					
#line 7697 "modelica_tree_parser.cpp"
		break;
	}
	case FALSE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp85_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp85_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp85_AST = astFactory->create(_t);
		tmp85_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp85_AST);
		match(_t,FALSE);
		_t = _t->getNextSibling();
#line 2180 "walker.g"
		
					DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
					pBoolLiteral->setAttribute(X("value"), X("false"));
					ast = pBoolLiteral;
					/* ast = Absyn__BOOL(RML_FALSE); */ 
				
#line 7716 "modelica_tree_parser.cpp"
		break;
	}
	case TRUE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp86_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp86_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp86_AST = astFactory->create(_t);
		tmp86_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp86_AST);
		match(_t,TRUE);
		_t = _t->getNextSibling();
#line 2187 "walker.g"
		
					DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
					pBoolLiteral->setAttribute(X("value"), X("true"));
					ast = pBoolLiteral;
					/* ast = Absyn__BOOL(RML_TRUE); */
				
#line 7735 "modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	case IDENT:
	case FUNCTION_CALL:
	case INITIAL_FUNCTION_CALL:
	{
		ast=component_reference__function_call(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case LPAR:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t282 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp87_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp87_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp87_AST = astFactory->create(_t);
		tmp87_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp87_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST282 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,LPAR);
		_t = _t->getFirstChild();
		ast=tuple_expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST282;
		_t = __t282;
		_t = _t->getNextSibling();
		break;
	}
	case LBRACK:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t283 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp88_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp88_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp88_AST = astFactory->create(_t);
		tmp88_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp88_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST283 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,LBRACK);
		_t = _t->getFirstChild();
		e=expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
#line 2195 "walker.g"
		el_stack.push(e);
#line 7787 "modelica_tree_parser.cpp"
		{ // ( ... )*
		for (;;) {
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			if ((_t->getType() == EXPRESSION_LIST)) {
				e=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
#line 2196 "walker.g"
				el_stack.push(e);
#line 7798 "modelica_tree_parser.cpp"
			}
			else {
				goto _loop285;
			}
			
		}
		_loop285:;
		} // ( ... )*
		currentAST = __currentAST283;
		_t = __t283;
		_t = _t->getNextSibling();
#line 2197 "walker.g"
		
						DOMElement* pConcat = pModelicaXMLDoc->createElement(X("concat"));
						pConcat = (DOMElement*)appendKids(el_stack, pConcat);
						ast = pConcat;
						/* ast = Absyn__MATRIX((DOMElement*)stack2DOMNode(el_stack)); */
					
#line 7817 "modelica_tree_parser.cpp"
		break;
	}
	case LBRACE:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t286 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp89_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp89_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp89_AST = astFactory->create(_t);
		tmp89_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp89_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST286 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,LBRACE);
		_t = _t->getFirstChild();
		ast=expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		currentAST = __currentAST286;
		_t = __t286;
		_t = _t->getNextSibling();
#line 2204 "walker.g"
		
					DOMElement* pArray = pModelicaXMLDoc->createElement(X("array"));
					pArray->appendChild(ast);
					ast = pArray;
					/* ast = Absyn__ARRAY(ast); */
				
#line 7846 "modelica_tree_parser.cpp"
		break;
	}
	case END:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp90_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp90_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp90_AST = astFactory->create(_t);
		tmp90_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp90_AST);
		match(_t,END);
		_t = _t->getNextSibling();
#line 2211 "walker.g"
		
					DOMElement* pEnd = pModelicaXMLDoc->createElement(X("End"));
					ast = pEnd;
					/* ast = Absyn__END; */ 
				
#line 7864 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	primary_AST = currentAST.root;
	returnAST = primary_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::component_reference__function_call(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2219 "walker.g"
	DOMNode* ast;
#line 7882 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference__function_call_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST component_reference__function_call_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2219 "walker.g"
	
		DOMNode* cref;
		DOMNode* fnc = 0;
	
#line 7892 "modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case DOT:
	case IDENT:
	case FUNCTION_CALL:
	{
		{
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case FUNCTION_CALL:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t289 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp91_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp91_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp91_AST = astFactory->create(_t);
			tmp91_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp91_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST289 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,FUNCTION_CALL);
			_t = _t->getFirstChild();
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			{
			if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case FUNCTION_ARGUMENTS:
			{
				fnc=function_call(_t);
				_t = _retTree;
				astFactory->addASTChild( currentAST, returnAST );
				break;
			}
			case 3:
			{
				break;
			}
			default:
			{
				throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
			}
			}
			}
			currentAST = __currentAST289;
			_t = __t289;
			_t = _t->getNextSibling();
#line 2226 "walker.g"
			
							DOMElement* pCall = pModelicaXMLDoc->createElement(X("call"));
							pCall->appendChild(cref);
							if (fnc) pCall->appendChild(fnc);
							ast = pCall;
							/* ast = Absyn__CALL(cref,fnc); */
						
#line 7953 "modelica_tree_parser.cpp"
			break;
		}
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 2234 "walker.g"
			
							DOMElement* pCref = pModelicaXMLDoc->createElement(X("component_reference"));
							pCref->appendChild(cref);
							if (fnc) pCref->appendChild(fnc);
							ast = pCref;
							/* ast = Absyn__CREF(cref); */
						
#line 7970 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
		}
		}
		}
		component_reference__function_call_AST = currentAST.root;
		break;
	}
	case INITIAL_FUNCTION_CALL:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t291 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp92_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp92_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp92_AST = astFactory->create(_t);
		tmp92_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp92_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST291 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,INITIAL_FUNCTION_CALL);
		_t = _t->getFirstChild();
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp93_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
		ANTLR_USE_NAMESPACE(antlr)RefAST tmp93_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		tmp93_AST = astFactory->create(_t);
		tmp93_AST_in = _t;
		astFactory->addASTChild(currentAST, tmp93_AST);
		match(_t,INITIAL);
		_t = _t->getNextSibling();
		currentAST = __currentAST291;
		_t = __t291;
		_t = _t->getNextSibling();
#line 2244 "walker.g"
		
						DOMElement* pCall = pModelicaXMLDoc->createElement(X("call"));
						pCall->setAttribute(X("initial"), X("true"));
						/*
						pCall->appendChild(cref);
						if (fnc) pCall->appendChild(fnc);
						*/
						ast = pCall;
						/*
						ast = Absyn__CALL(Absyn__CREF_5fIDENT(mk_scon("initial"), mk_nil()),Absyn__FUNCTIONARGS(mk_nil(),mk_nil()));
						*/
					
#line 8018 "modelica_tree_parser.cpp"
		component_reference__function_call_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = component_reference__function_call_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::tuple_expression_list(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2390 "walker.g"
	DOMNode* ast;
#line 8035 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST tuple_expression_list_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tuple_expression_list_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2390 "walker.g"
	
		l_stack el_stack;
		DOMNode* e;
	
#line 8045 "modelica_tree_parser.cpp"
	
	{
	ANTLR_USE_NAMESPACE(antlr)RefAST __t320 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp94_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp94_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp94_AST = astFactory->create(_t);
	tmp94_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp94_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST320 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 2397 "walker.g"
	el_stack.push(e);
#line 8064 "modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 2398 "walker.g"
			el_stack.push(e);
#line 8075 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop322;
		}
		
	}
	_loop322:;
	} // ( ... )*
	currentAST = __currentAST320;
	_t = __t320;
	_t = _t->getNextSibling();
	}
#line 2401 "walker.g"
	
				if (el_stack.size() == 1)
				{
					ast = el_stack.top();
				}
				else
				{
					DOMElement *pTuple = pModelicaXMLDoc->createElement(X("output_expression_list"));
					pTuple = (DOMElement*)appendKids(el_stack, pTuple);
					ast = pTuple;
					/* ast = Absyn__TUPLE((DOMElement*)stack2DOMNode(el_stack)); */
				}
			
#line 8102 "modelica_tree_parser.cpp"
	tuple_expression_list_AST = currentAST.root;
	returnAST = tuple_expression_list_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::function_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2327 "walker.g"
	DOMNode* ast;
#line 8112 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST function_arguments_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST function_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2327 "walker.g"
	
		l_stack el_stack;
		DOMNode* elist=0;
		DOMNode* namel=0;
	
#line 8123 "modelica_tree_parser.cpp"
	
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXPRESSION_LIST:
	{
		elist=expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	case NAMED_ARGUMENTS:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case NAMED_ARGUMENTS:
	{
		namel=named_arguments(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 2335 "walker.g"
	
				DOMElement *pFunctionArguments = pModelicaXMLDoc->createElement(X("function_arguments"));
				if (namel) pFunctionArguments->appendChild(namel); 
				if (elist) pFunctionArguments->appendChild(elist);
				ast = pFunctionArguments;
				/* ast = Absyn__FUNCTIONARGS(elist,namel); */
			
#line 8176 "modelica_tree_parser.cpp"
	function_arguments_AST = currentAST.root;
	returnAST = function_arguments_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::named_arguments(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2347 "walker.g"
	DOMNode* ast;
#line 8186 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_arguments_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2347 "walker.g"
	
		l_stack el_stack;
		DOMNode* n;
	
#line 8196 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t307 = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp95_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST tmp95_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	tmp95_AST = astFactory->create(_t);
	tmp95_AST_in = _t;
	astFactory->addASTChild(currentAST, tmp95_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST307 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,NAMED_ARGUMENTS);
	_t = _t->getFirstChild();
	{
	n=named_argument(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
#line 2353 "walker.g"
	el_stack.push(n);
#line 8215 "modelica_tree_parser.cpp"
	}
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		if ((_t->getType() == EQUALS)) {
			n=named_argument(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
#line 2353 "walker.g"
			el_stack.push(n);
#line 8227 "modelica_tree_parser.cpp"
		}
		else {
			goto _loop310;
		}
		
	}
	_loop310:;
	} // ( ... )*
	currentAST = __currentAST307;
	_t = __t307;
	_t = _t->getNextSibling();
#line 2354 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "function_arguments");
			
#line 8243 "modelica_tree_parser.cpp"
	named_arguments_AST = currentAST.root;
	returnAST = named_arguments_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::named_argument(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2359 "walker.g"
	DOMNode* ast;
#line 8253 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST named_argument_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST named_argument_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST eq = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST eq_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2359 "walker.g"
	
		DOMNode* temp;
	
#line 8266 "modelica_tree_parser.cpp"
	
	ANTLR_USE_NAMESPACE(antlr)RefAST __t312 = _t;
	eq = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST eq_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	eq_AST = astFactory->create(eq);
	astFactory->addASTChild(currentAST, eq_AST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST312 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
	match(_t,EQUALS);
	_t = _t->getFirstChild();
	i = _t;
	ANTLR_USE_NAMESPACE(antlr)RefAST i_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
	i_AST = astFactory->create(i);
	astFactory->addASTChild(currentAST, i_AST);
	match(_t,IDENT);
	_t = _t->getNextSibling();
	temp=expression(_t);
	_t = _retTree;
	astFactory->addASTChild( currentAST, returnAST );
	currentAST = __currentAST312;
	_t = __t312;
	_t = _t->getNextSibling();
#line 2365 "walker.g"
	
				DOMElement *pNamedArgument = pModelicaXMLDoc->createElement(X("named_argument"));
				pNamedArgument->setAttribute(X("ident"), str2xml(i));
				pNamedArgument->appendChild(temp);
				ast = pNamedArgument;
				/* ast = Absyn__NAMEDARG(str2xml(i),temp); */
			
#line 8298 "modelica_tree_parser.cpp"
	named_argument_AST = currentAST.root;
	returnAST = named_argument_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::subscript(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2436 "walker.g"
	DOMNode* ast;
#line 8308 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST subscript_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST subscript_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST c_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2436 "walker.g"
	
		DOMNode* e;
	
#line 8319 "modelica_tree_parser.cpp"
	
#line 2440 "walker.g"
	DOMElement *pArraySubscripts = pModelicaXMLDoc->createElement(X("array_subscripts"));
#line 8323 "modelica_tree_parser.cpp"
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case AND:
	case END:
	case FALSE:
	case IF:
	case NOT:
	case OR:
	case TRUE:
	case UNSIGNED_REAL:
	case LPAR:
	case LBRACK:
	case LBRACE:
	case PLUS:
	case MINUS:
	case STAR:
	case SLASH:
	case DOT:
	case LESS:
	case LESSEQ:
	case GREATER:
	case GREATEREQ:
	case EQEQ:
	case LESSGT:
	case POWER:
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
	{
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
#line 2443 "walker.g"
		
						pArraySubscripts->appendChild(e);
						ast = pArraySubscripts;
						/* ast = Absyn__SUBSCRIPT(e); */
					
#line 8377 "modelica_tree_parser.cpp"
		break;
	}
	case COLON:
	{
		c = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST c_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		c_AST = astFactory->create(c);
		astFactory->addASTChild(currentAST, c_AST);
		match(_t,COLON);
		_t = _t->getNextSibling();
#line 2449 "walker.g"
		
						pArraySubscripts->appendChild(pColon);
						ast = pArraySubscripts;
						/* ast = Absyn__NOSUB; */
					
#line 8394 "modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
	subscript_AST = currentAST.root;
	returnAST = subscript_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::string_concatenation(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2490 "walker.g"
	DOMNode* ast;
#line 8412 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST string_concatenation_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST string_concatenation_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST p_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s2 = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s2_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2490 "walker.g"
	
			DOMNode *pString1;
			l_stack el_stack;
		
#line 8428 "modelica_tree_parser.cpp"
	
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case STRING:
	{
		s = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST s_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		s_AST = astFactory->create(s);
		astFactory->addASTChild(currentAST, s_AST);
		match(_t,STRING);
		_t = _t->getNextSibling();
#line 2497 "walker.g"
		
					DOMElement *pString = pModelicaXMLDoc->createElement(X("string"));
					pString->setAttribute(X("value"), str2xml(s));
			  		ast=pString;
				
#line 8447 "modelica_tree_parser.cpp"
		string_concatenation_AST = currentAST.root;
		break;
	}
	case PLUS:
	{
		ANTLR_USE_NAMESPACE(antlr)RefAST __t335 = _t;
		p = (_t == ASTNULL) ? ANTLR_USE_NAMESPACE(antlr)nullAST : _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST p_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		p_AST = astFactory->create(p);
		astFactory->addASTChild(currentAST, p_AST);
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST335 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
		match(_t,PLUS);
		_t = _t->getFirstChild();
		pString1=string_concatenation(_t);
		_t = _retTree;
		astFactory->addASTChild( currentAST, returnAST );
		s2 = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST s2_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		s2_AST = astFactory->create(s2);
		astFactory->addASTChild(currentAST, s2_AST);
		match(_t,STRING);
		_t = _t->getNextSibling();
		currentAST = __currentAST335;
		_t = __t335;
		_t = _t->getNextSibling();
#line 2503 "walker.g"
		
					 DOMElement *pString = pModelicaXMLDoc->createElement(X("add"));
					 pString->appendChild(pString1);
					 DOMElement *pString2 = pModelicaXMLDoc->createElement(X("string"));
					 pString2->setAttribute(X("value"), str2xml(s2));
					 pString->appendChild(pString2);
					 ast=pString;
				
#line 8484 "modelica_tree_parser.cpp"
		string_concatenation_AST = currentAST.root;
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	returnAST = string_concatenation_AST;
	_retTree = _t;
	return ast;
}

DOMNode*  modelica_tree_parser::interactive_stmt(ANTLR_USE_NAMESPACE(antlr)RefAST _t) {
#line 2528 "walker.g"
	DOMNode* ast;
#line 8501 "modelica_tree_parser.cpp"
	ANTLR_USE_NAMESPACE(antlr)RefAST interactive_stmt_AST_in = _t;
	returnAST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST interactive_stmt_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s = ANTLR_USE_NAMESPACE(antlr)nullAST;
	ANTLR_USE_NAMESPACE(antlr)RefAST s_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
#line 2528 "walker.g"
	
	DOMNode* al=0; 
	DOMNode* el=0;
		l_stack el_stack;	
	
#line 8514 "modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INTERACTIVE_ALG:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t340 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp96_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp96_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp96_AST = astFactory->create(_t);
			tmp96_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp96_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST340 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,INTERACTIVE_ALG);
			_t = _t->getFirstChild();
			{
			al=algorithm(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			}
			currentAST = __currentAST340;
			_t = __t340;
			_t = _t->getNextSibling();
#line 2537 "walker.g"
			
							DOMElement *pInteractiveALG = pModelicaXMLDoc->createElement(X("IALG"));
							pInteractiveALG->appendChild(al);
							el_stack.push(pInteractiveALG);
						
#line 8548 "modelica_tree_parser.cpp"
			break;
		}
		case INTERACTIVE_EXP:
		{
			ANTLR_USE_NAMESPACE(antlr)RefAST __t342 = _t;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp97_AST = ANTLR_USE_NAMESPACE(antlr)nullAST;
			ANTLR_USE_NAMESPACE(antlr)RefAST tmp97_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
			tmp97_AST = astFactory->create(_t);
			tmp97_AST_in = _t;
			astFactory->addASTChild(currentAST, tmp97_AST);
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST342 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = ANTLR_USE_NAMESPACE(antlr)nullAST;
			match(_t,INTERACTIVE_EXP);
			_t = _t->getFirstChild();
			{
			el=expression(_t);
			_t = _retTree;
			astFactory->addASTChild( currentAST, returnAST );
			}
			currentAST = __currentAST342;
			_t = __t342;
			_t = _t->getNextSibling();
#line 2544 "walker.g"
			
							DOMElement *pInteractiveEXP = pModelicaXMLDoc->createElement(X("IEXP"));
							pInteractiveEXP->appendChild(el);
							el_stack.push(pInteractiveEXP);
						
#line 8578 "modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			goto _loop344;
		}
		}
	}
	_loop344:;
	} // ( ... )*
	{
	if (_t == ANTLR_USE_NAMESPACE(antlr)nullAST )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case SEMICOLON:
	{
		s = _t;
		ANTLR_USE_NAMESPACE(antlr)RefAST s_AST_in = ANTLR_USE_NAMESPACE(antlr)nullAST;
		s_AST = astFactory->create(s);
		astFactory->addASTChild(currentAST, s_AST);
		match(_t,SEMICOLON);
		_t = _t->getNextSibling();
		break;
	}
	case 3:
	{
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(_t);
	}
	}
	}
#line 2551 "walker.g"
	
				DOMElement *pInteractiveSTMT = pModelicaXMLDoc->createElement(X("ISTMT"));
				pInteractiveSTMT = (DOMElement*)appendKids(el_stack, pInteractiveSTMT);
				if (s) pInteractiveSTMT->setAttribute(X("semicolon"),X("true"));
				ast = pInteractiveSTMT;
			
#line 8620 "modelica_tree_parser.cpp"
	interactive_stmt_AST = currentAST.root;
	returnAST = interactive_stmt_AST;
	_retTree = _t;
	return ast;
}

void modelica_tree_parser::initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory )
{
	factory.setMaxNodeType(133);
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
	"\"boundary\"",
	"\"Code\"",
	"\"class\"",
	"\"connect\"",
	"\"connector\"",
	"\"constant\"",
	"\"discrete\"",
	"\"each\"",
	"\"else\"",
	"\"elseif\"",
	"\"elsewhen\"",
	"\"end\"",
	"\"enumeration\"",
	"\"equation\"",
	"\"encapsulated\"",
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
	"\"overload\"",
	"\"outer\"",
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
	"\"when\"",
	"\"while\"",
	"\"within\"",
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
	"DOT",
	"COMMA",
	"LESS",
	"LESSEQ",
	"GREATER",
	"GREATEREQ",
	"EQEQ",
	"LESSGT",
	"COLON",
	"SEMICOLON",
	"POWER",
	"WS",
	"ML_COMMENT",
	"ML_COMMENT_CHAR",
	"SL_COMMENT",
	"IDENT",
	"NONDIGIT",
	"DIGIT",
	"EXPONENT",
	"UNSIGNED_INTEGER",
	"STRING",
	"SCHAR",
	"SESCAPE",
	"ESC",
	"ALGORITHM_STATEMENT",
	"ARGUMENT_LIST",
	"CLASS_DEFINITION",
	"CLASS_MODIFICATION",
	"CODE_EXPRESSION",
	"CODE_MODIFICATION",
	"CODE_ELEMENT",
	"CODE_EQUATION",
	"CODE_INITIALEQUATION",
	"CODE_ALGORITHM",
	"CODE_INITIALALGORITHM",
	"COMMENT",
	"DECLARATION",
	"DEFINITION",
	"ENUMERATION_LITERAL",
	"ELEMENT",
	"ELEMENT_MODIFICATION",
	"ELEMENT_REDECLARATION",
	"EQUATION_STATEMENT",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"EXPRESSION_LIST",
	"EXTERNAL_FUNCTION_CALL",
	"FOR_INDICES",
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
	"UNQUALIFIED",
	"INTERACTIVE_STMT",
	"INTERACTIVE_ALG",
	"INTERACTIVE_EXP",
	0
};

const unsigned long modelica_tree_parser::_tokenSet_0_data_[] = { 2097168UL, 49152UL, 0UL, 786432UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "equation" "protected" "public" INITIAL_EQUATION INITIAL_ALGORITHM 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_tree_parser::_tokenSet_0(_tokenSet_0_data_,8);
const unsigned long modelica_tree_parser::_tokenSet_1_data_[] = { 1107820576UL, 2829058624UL, 205717240UL, 830473208UL, 3UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "not" "or" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING CODE_EXPRESSION CODE_MODIFICATION 
// CODE_ELEMENT CODE_EQUATION CODE_INITIALEQUATION CODE_ALGORITHM CODE_INITIALALGORITHM 
// FUNCTION_CALL INITIAL_FUNCTION_CALL RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_tree_parser::_tokenSet_1(_tokenSet_1_data_,12);
const unsigned long modelica_tree_parser::_tokenSet_2_data_[] = { 1107820576UL, 2829058624UL, 205684472UL, 830473208UL, 3UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "not" "or" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT POWER IDENT UNSIGNED_INTEGER STRING CODE_EXPRESSION CODE_MODIFICATION 
// CODE_ELEMENT CODE_EQUATION CODE_INITIALEQUATION CODE_ALGORITHM CODE_INITIALALGORITHM 
// FUNCTION_CALL INITIAL_FUNCTION_CALL RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
const ANTLR_USE_NAMESPACE(antlr)BitSet modelica_tree_parser::_tokenSet_2(_tokenSet_2_data_,12);


