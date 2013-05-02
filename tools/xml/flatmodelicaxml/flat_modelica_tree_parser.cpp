/* $ANTLR 2.7.7 (2006-11-01): "walker.g" -> "flat_modelica_tree_parser.cpp"$ */
#include "flat_modelica_tree_parser.hpp"
#include <antlr/Token.hpp>
#include <antlr/AST.hpp>
#include <antlr/NoViableAltException.hpp>
#include <antlr/MismatchedTokenException.hpp>
#include <antlr/SemanticException.hpp>
#include <antlr/BitSet.hpp>
#line 52 "walker.g"


#line 13 "flat_modelica_tree_parser.cpp"
#line 1 "walker.g"
#line 15 "flat_modelica_tree_parser.cpp"
flat_modelica_tree_parser::flat_modelica_tree_parser()
	: ANTLR_USE_NAMESPACE(antlr)TreeParser() {
}

DOMElement * flat_modelica_tree_parser::stored_definition(RefMyAST _t,
	mstring xmlFilename,
	 mstring mofFilename,
	 mstring docType
) {
#line 213 "walker.g"
	DOMElement *ast;
#line 27 "flat_modelica_tree_parser.cpp"
	RefMyAST stored_definition_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST stored_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 213 "walker.g"
	
	DOMElement *within = 0;
	//DOMElement*class_def = 0;
	l_stack el_stack;
	
		// initialize xml framework
	XMLPlatformUtils::Initialize();
	
	// XML DOM creation
	DOMImplementation* pDOMImpl = DOMImplementationRegistry::getDOMImplementation(X("Core"));
	
	
	// create the document type (according to flatmodelica.dtd)
	DOMDocumentType* pDoctype = pDOMImpl->createDocumentType(
			 X("modelica"),
			 NULL,
			 X(docType.c_str()));
	
	// create the <program> root element
	pFlatModelicaXMLDoc = pDOMImpl->createDocument(
	0,                    // root element namespace URI.
	X("modelica"),         // root element name
	pDoctype);                   // document type object (DTD).
	
	pRootElementModelica = pFlatModelicaXMLDoc->getDocumentElement();
		pRootElementFlatModelicaXML = pFlatModelicaXMLDoc->createElement(X("modelicaxml"));
		// set the location of the .mo file we're representing in XML
		pRootElementFlatModelicaXML->setAttribute(X("file"), X(mofFilename.c_str()));
	
		DOMElement* pDefinitionElement = 0;
	
#line 66 "flat_modelica_tree_parser.cpp"
	
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
		pRootElementFlatModelicaXML=within_clause(_t,pRootElementFlatModelicaXML);
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
#line 251 "walker.g"
			pDefinitionElement = pFlatModelicaXMLDoc->createElement(X("definition"));
#line 133 "flat_modelica_tree_parser.cpp"
			pDefinitionElement=class_definition(_t,f != NULL, pDefinitionElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 253 "walker.g"
			
			if (pDefinitionElement && pDefinitionElement->hasChildNodes())
			{
			el_stack.push(pDefinitionElement);
			}
			
#line 144 "flat_modelica_tree_parser.cpp"
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
#line 261 "walker.g"
	
				//pRootElementFlatModelicaXML = within;
	
				pRootElementFlatModelicaXML = (DOMElement*)appendKids(el_stack, pRootElementFlatModelicaXML);
				pRootElementModelica->appendChild(pRootElementFlatModelicaXML);
	ast = pRootElementModelica;
	
				XMLSize_t elementCount = pFlatModelicaXMLDoc->getElementsByTagName(X("*"))->getLength();
				std::cout << std::endl;
		        std::cout << "The tree just created contains: " << elementCount
		        << " elements." << std::endl;
	
	// get a serializer, an instance of DOMLSSerializer
	XMLCh tempStr[3] = {chLatin_L, chLatin_S, chNull};
	DOMImplementation *impl = DOMImplementationRegistry::getDOMImplementation(tempStr);
		        // create the writer            
	DOMLSSerializer   *domSerializer = ((DOMImplementationLS*)impl)->createLSSerializer();
	DOMLSOutput       *theOutputDesc = ((DOMImplementationLS*)impl)->createLSOutput();
	static XMLCh*                   gOutputEncoding        = 0;
	// set user specified output encoding
	theOutputDesc->setEncoding(gOutputEncoding);            
	
	DOMConfiguration* serializerConfig=domSerializer->getDomConfig();
				// set the pretty print feature
				if (serializerConfig->canSetParameter(XMLUni::fgDOMWRTFormatPrettyPrint, true))
					 serializerConfig->setParameter(XMLUni::fgDOMWRTFormatPrettyPrint, true);
			    
				// fix the file
				XMLFormatTarget *myFormatTarget = new LocalFileFormatTarget(X(xmlFilename.c_str()));
	theOutputDesc->setByteStream(myFormatTarget);
	
				// serialize a DOMNode to the local file "
				domSerializer->write(pFlatModelicaXMLDoc, theOutputDesc);
	
				myFormatTarget->flush();
	theOutputDesc->release();
				domSerializer->release();
	
				delete myFormatTarget;
	
				// release the document
				pFlatModelicaXMLDoc->release();
				// terminate the XML framework
				XMLPlatformUtils::Terminate();
	
#line 202 "flat_modelica_tree_parser.cpp"
	stored_definition_AST = RefMyAST(currentAST.root);
	returnAST = stored_definition_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::within_clause(RefMyAST _t,
	DOMElement* parent
) {
#line 311 "walker.g"
	DOMElement* ast;
#line 214 "flat_modelica_tree_parser.cpp"
	RefMyAST within_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST within_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 311 "walker.g"
	
		void* pNamePath = 0;
	
#line 223 "flat_modelica_tree_parser.cpp"
	
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
#line 316 "walker.g"
	
			    if (pNamePath) parent->setAttribute(X("within"), X(((mstring *)pNamePath)->c_str()));
				ast = parent;
	
#line 266 "flat_modelica_tree_parser.cpp"
	within_clause_AST = RefMyAST(currentAST.root);
	returnAST = within_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::class_definition(RefMyAST _t,
	bool final, DOMElement *definitionElement
) {
#line 325 "walker.g"
	DOMElement* ast;
#line 278 "flat_modelica_tree_parser.cpp"
	RefMyAST class_definition_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_definition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 325 "walker.g"
	
	class_specifier_t sClassSpec;
	sClassSpec.composition = definitionElement;
	
#line 296 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t11 = _t;
	RefMyAST tmp3_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp3_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp3_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp3_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp3_AST));
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
	i = _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IDENT);
	_t = _t->getNextSibling();
	class_specifier(_t,sClassSpec);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 335 "walker.g"
	definitionElement=sClassSpec.composition;
#line 390 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST11;
	_t = __t11;
	_t = _t->getNextSibling();
#line 337 "walker.g"
	
	definitionElement->setAttribute(X("ident"), X(i->getText().c_str()));
	
				definitionElement->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				definitionElement->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				if (p != 0) definitionElement->setAttribute(X("partial"), X("true"));
				if (final) definitionElement->setAttribute(X("final"), X("true"));
				if (e != 0) definitionElement->setAttribute(X("encapsulated"), X("true"));
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
				ast = definitionElement;
	
#line 429 "flat_modelica_tree_parser.cpp"
	class_definition_AST = RefMyAST(currentAST.root);
	returnAST = class_definition_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::name_path(RefMyAST _t) {
#line 2289 "walker.g"
	void *ast;
#line 439 "flat_modelica_tree_parser.cpp"
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
#line 2289 "walker.g"
	
		void *s1=0;
		void *s2=0;
	
#line 455 "flat_modelica_tree_parser.cpp"
	
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
#line 2296 "walker.g"
		
					ast = (void*)new mstring(i->getText());
				
#line 472 "flat_modelica_tree_parser.cpp"
		name_path_AST = RefMyAST(currentAST.root);
		break;
	}
	case DOT:
	{
		RefMyAST __t296 = _t;
		d = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST d_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		d_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(d));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(d_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST296 = currentAST;
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
		currentAST = __currentAST296;
		_t = __t296;
		_t = _t->getNextSibling();
#line 2300 "walker.g"
		
					s1 = (void*)new mstring(i2->getText());
					ast = (void*)new mstring(mstring(((mstring*)s1)->c_str())+mstring(".")+mstring(((mstring*)s2)->c_str()));
				
#line 505 "flat_modelica_tree_parser.cpp"
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

void flat_modelica_tree_parser::class_restriction(RefMyAST _t) {
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
		RefMyAST tmp4_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp4_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp4_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp4_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp4_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CLASS);
		_t = _t->getNextSibling();
		break;
	}
	case MODEL:
	{
		RefMyAST tmp5_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp5_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp5_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp5_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp5_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),MODEL);
		_t = _t->getNextSibling();
		break;
	}
	case RECORD:
	{
		RefMyAST tmp6_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp6_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp6_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp6_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp6_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),RECORD);
		_t = _t->getNextSibling();
		break;
	}
	case BLOCK:
	{
		RefMyAST tmp7_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp7_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp7_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp7_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp7_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),BLOCK);
		_t = _t->getNextSibling();
		break;
	}
	case CONNECTOR:
	{
		RefMyAST tmp8_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp8_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp8_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp8_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp8_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CONNECTOR);
		_t = _t->getNextSibling();
		break;
	}
	case TYPE:
	{
		RefMyAST tmp9_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp9_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp9_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp9_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp9_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),TYPE);
		_t = _t->getNextSibling();
		break;
	}
	case PACKAGE:
	{
		RefMyAST tmp10_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp10_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp10_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp10_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp10_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PACKAGE);
		_t = _t->getNextSibling();
		break;
	}
	case FUNCTION:
	{
		RefMyAST tmp11_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp11_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp11_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp11_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp11_AST));
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

void flat_modelica_tree_parser::class_specifier(RefMyAST _t,
	class_specifier_t& sClassSpec
) {
	RefMyAST class_specifier_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_specifier_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 394 "walker.g"
	
		DOMElement *comp = 0;
		DOMElement *cmt = 0;
		DOMElement *d = 0;
		DOMElement *e = 0;
		DOMElement *o = 0;
	
#line 643 "flat_modelica_tree_parser.cpp"
	
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
#line 405 "walker.g"
		
		if (cmt) sClassSpec.string_comment = cmt;
						sClassSpec.composition = comp;
					
#line 677 "flat_modelica_tree_parser.cpp"
		}
		class_specifier_AST = RefMyAST(currentAST.root);
		break;
	}
	case EQUALS:
	{
		RefMyAST __t20 = _t;
		RefMyAST tmp12_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp12_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp12_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp12_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp12_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST20 = currentAST;
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
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST20;
		_t = __t20;
		_t = _t->getNextSibling();
#line 415 "walker.g"
		
					sClassSpec.derived = d;
					sClassSpec.enumeration = e;
					sClassSpec.overload = o;
				
#line 742 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::string_comment(RefMyAST _t) {
#line 2542 "walker.g"
	DOMElement* ast;
#line 758 "flat_modelica_tree_parser.cpp"
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
#line 2543 "walker.g"
		
			  DOMElement* cmt=0;
			  ast = 0;
			
#line 776 "flat_modelica_tree_parser.cpp"
		RefMyAST __t341 = _t;
		sc = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sc_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sc_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sc));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sc_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST341 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),STRING_COMMENT);
		_t = _t->getFirstChild();
		cmt=string_concatenation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST341;
		_t = __t341;
		_t = _t->getNextSibling();
#line 2548 "walker.g"
		
					DOMElement *pStringComment = pFlatModelicaXMLDoc->createElement(X("string_comment"));
		
					pStringComment->setAttribute(X("sline"), X(itoa(sc->getLine(),stmp,10)));
					pStringComment->setAttribute(X("scolumn"), X(itoa(sc->getColumn(),stmp,10)));
		
					pStringComment->appendChild(cmt);
					ast = pStringComment;
				
#line 803 "flat_modelica_tree_parser.cpp"
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
	case DECLARATION:
	case DEFINITION:
	case INITIAL_EQUATION:
	case INITIAL_ALGORITHM:
	{
#line 2558 "walker.g"
		
					ast = 0;
				
#line 825 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::composition(RefMyAST _t,
	DOMElement* definition
) {
#line 542 "walker.g"
	DOMElement* ast;
#line 844 "flat_modelica_tree_parser.cpp"
	RefMyAST composition_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST composition_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 542 "walker.g"
	
	DOMElement* el = 0;
	l_stack el_stack;
	DOMElement*  ann;
	DOMElement* pExternalFunctionCall = 0;
	
#line 856 "flat_modelica_tree_parser.cpp"
	
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
			goto _loop43;
		}
		
	}
	_loop43:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL:
	{
		RefMyAST __t45 = _t;
		RefMyAST tmp13_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp13_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp13_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp13_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp13_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST45 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXTERNAL);
		_t = _t->getFirstChild();
#line 559 "walker.g"
		pExternalFunctionCall = pFlatModelicaXMLDoc->createElement(X("external"));
#line 933 "flat_modelica_tree_parser.cpp"
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
#line 563 "walker.g"
				pExternalFunctionCall->appendChild(pFlatModelicaXMLDoc->createElement(X("semicolon")));
#line 968 "flat_modelica_tree_parser.cpp"
				RefMyAST __t49 = _t;
				RefMyAST tmp14_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				RefMyAST tmp14_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				tmp14_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
				tmp14_AST_in = _t;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp14_AST));
				ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST49 = currentAST;
				currentAST.root = currentAST.child;
				currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
				match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXTERNAL_ANNOTATION);
				_t = _t->getFirstChild();
				pExternalFunctionCall=annotation(_t,0 /*none*/, pExternalFunctionCall, INSIDE_EXTERNAL);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
				currentAST = __currentAST49;
				_t = __t49;
				_t = _t->getNextSibling();
			}
			else {
				goto _loop50;
			}
			
		}
		_loop50:;
		} // ( ... )*
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
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 568 "walker.g"
	
				if (pExternalFunctionCall) definition->appendChild(pExternalFunctionCall);
	ast = definition;
	
#line 1014 "flat_modelica_tree_parser.cpp"
	composition_AST = RefMyAST(currentAST.root);
	returnAST = composition_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::derived_class(RefMyAST _t) {
#line 426 "walker.g"
	DOMElement* ast;
#line 1024 "flat_modelica_tree_parser.cpp"
	RefMyAST derived_class_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST derived_class_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 426 "walker.g"
	
		void* p = 0;
		DOMElement* as = 0;
		void *cmod = 0;
		DOMElement* cmt = 0;
		DOMElement* attr = 0;
		type_prefix_t pfx;
		DOMElement* pDerived = pFlatModelicaXMLDoc->createElement(X("derived"));
	
#line 1039 "flat_modelica_tree_parser.cpp"
	
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
#line 442 "walker.g"
	
					if (p)               pDerived->setAttribute(X("type"), X(((mstring*)p)->c_str()));
					if (as)              pDerived->appendChild(as);
					if (cmod)            pDerived = (DOMElement*)appendKidsFromStack((l_stack *)cmod, pDerived);
					if (cmt)             pDerived->appendChild(cmt);
					ast = pDerived;
				
#line 1122 "flat_modelica_tree_parser.cpp"
	}
	derived_class_AST = RefMyAST(currentAST.root);
	returnAST = derived_class_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::enumeration(RefMyAST _t) {
#line 455 "walker.g"
	DOMElement* ast;
#line 1133 "flat_modelica_tree_parser.cpp"
	RefMyAST enumeration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST en = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST en_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 455 "walker.g"
	
		l_stack el_stack;
		DOMElement* el = 0;
		DOMElement* cmt = 0;
	
#line 1146 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t28 = _t;
	en = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST en_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	en_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(en));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(en_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST28 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ENUMERATION);
	_t = _t->getFirstChild();
	el=enumeration_literal(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 464 "walker.g"
	el_stack.push(el);
#line 1163 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ENUMERATION_LITERAL)) {
			el=enumeration_literal(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 467 "walker.g"
			el_stack.push(el);
#line 1174 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop30;
		}
		
	}
	_loop30:;
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
	currentAST = __currentAST28;
	_t = __t28;
	_t = _t->getNextSibling();
#line 472 "walker.g"
	
				DOMElement* pEnumeration = pFlatModelicaXMLDoc->createElement(X("enumeration"));
				pEnumeration = (DOMElement*)appendKids(el_stack, pEnumeration);
				if (cmt) pEnumeration->appendChild(cmt);
	
				pEnumeration->setAttribute(X("sline"), X(itoa(en->getLine(),stmp,10)));
				pEnumeration->setAttribute(X("scolumn"), X(itoa(en->getColumn(),stmp,10)));
	
				ast = pEnumeration;
			
#line 1218 "flat_modelica_tree_parser.cpp"
	enumeration_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::overloading(RefMyAST _t) {
#line 510 "walker.g"
	DOMElement* ast;
#line 1228 "flat_modelica_tree_parser.cpp"
	RefMyAST overloading_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST overloading_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ov = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST ov_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 510 "walker.g"
	
		std::stack<void*> el_stack;
		void* el = 0;
		DOMElement* cmt = 0;
	
#line 1241 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t36 = _t;
	ov = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST ov_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ov_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ov));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ov_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST36 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),OVERLOAD);
	_t = _t->getFirstChild();
	el=name_path(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 519 "walker.g"
	el_stack.push(el);
#line 1258 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == DOT || _t->getType() == IDENT)) {
			el=name_path(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 522 "walker.g"
			el_stack.push(el);
#line 1269 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop38;
		}
		
	}
	_loop38:;
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
	currentAST = __currentAST36;
	_t = __t36;
	_t = _t->getNextSibling();
#line 527 "walker.g"
	
				DOMElement* pOverload = pFlatModelicaXMLDoc->createElement(X("overload"));
				if (cmt) pOverload->appendChild(cmt);
	
				pOverload->setAttribute(X("sline"), X(itoa(ov->getLine(),stmp,10)));
				pOverload->setAttribute(X("scolumn"), X(itoa(ov->getColumn(),stmp,10)));
	
				ast = pOverload;
			
#line 1312 "flat_modelica_tree_parser.cpp"
	overloading_AST = RefMyAST(currentAST.root);
	returnAST = overloading_AST;
	_retTree = _t;
	return ast;
}

void flat_modelica_tree_parser::type_prefix(RefMyAST _t,
	DOMElement* parent
) {
	RefMyAST type_prefix_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST type_prefix_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
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
#line 930 "walker.g"
	
				if (f != NULL) { parent->setAttribute(X("flow"), X("true")); }
				//else { parent->setAttribute(X("flow"), X("none")); }
				if (d != NULL) { parent->setAttribute(X("variability"), X("discrete")); }
				else if (p != NULL) { parent->setAttribute(X("variability"), X("parameter")); }
				else if (c != NULL) { parent->setAttribute(X("variability"), X("constant")); }
				//else { parent->setAttribute(X("variability"), X("variable")); }
				if (i != NULL) { parent->setAttribute(X("direction"), X("input")); }
				else if (o != NULL) { parent->setAttribute(X("direction"), X("output")); }
				//else { parent->setAttribute(X("direction"), X("bidirectional")); }
			
#line 1463 "flat_modelica_tree_parser.cpp"
	type_prefix_AST = RefMyAST(currentAST.root);
	returnAST = type_prefix_AST;
	_retTree = _t;
}

DOMElement*  flat_modelica_tree_parser::array_subscripts(RefMyAST _t,
	int kind
) {
#line 2475 "walker.g"
	DOMElement* ast;
#line 1474 "flat_modelica_tree_parser.cpp"
	RefMyAST array_subscripts_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST array_subscripts_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2475 "walker.g"
	
		l_stack el_stack;
		DOMElement* s = 0;
		DOMElement *pArraySubscripts = 0;
		if (kind)
		  pArraySubscripts = pFlatModelicaXMLDoc->createElement(X("type_array_subscripts"));
		else
		  pArraySubscripts = pFlatModelicaXMLDoc->createElement(X("array_subscripts"));
	
#line 1491 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t332 = _t;
	lbk = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST lbk_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	lbk_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lbk));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lbk_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST332 = currentAST;
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
			goto _loop334;
		}
		
	}
	_loop334:;
	} // ( ... )*
	currentAST = __currentAST332;
	_t = __t332;
	_t = _t->getNextSibling();
#line 2488 "walker.g"
	
	
				pArraySubscripts->setAttribute(X("sline"), X(itoa(lbk->getLine(),stmp,10)));
				pArraySubscripts->setAttribute(X("scolumn"), X(itoa(lbk->getColumn(),stmp,10)));
	
				ast = pArraySubscripts;
			
#line 1533 "flat_modelica_tree_parser.cpp"
	array_subscripts_AST = RefMyAST(currentAST.root);
	returnAST = array_subscripts_AST;
	_retTree = _t;
	return ast;
}

void * flat_modelica_tree_parser::class_modification(RefMyAST _t) {
#line 1049 "walker.g"
	void *stack;
#line 1543 "flat_modelica_tree_parser.cpp"
	RefMyAST class_modification_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST class_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1049 "walker.g"
	
		stack = 0;
	
#line 1552 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t123 = _t;
	RefMyAST tmp15_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp15_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp15_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp15_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp15_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST123 = currentAST;
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
	currentAST = __currentAST123;
	_t = __t123;
	_t = _t->getNextSibling();
	class_modification_AST = RefMyAST(currentAST.root);
	returnAST = class_modification_AST;
	_retTree = _t;
	return stack;
}

DOMElement*  flat_modelica_tree_parser::comment(RefMyAST _t) {
#line 2521 "walker.g"
	DOMElement* ast;
#line 1598 "flat_modelica_tree_parser.cpp"
	RefMyAST comment_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST comment_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2521 "walker.g"
	
		DOMElement* ann=0;
		DOMElement* cmt=0;
	ast = 0;
		DOMElement *pComment = pFlatModelicaXMLDoc->createElement(X("comment"));
		bool bAnno = false;
	
#line 1613 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t338 = _t;
	c = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST338 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),COMMENT);
	_t = _t->getFirstChild();
	cmt=string_comment(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2529 "walker.g"
	if (cmt) pComment->appendChild(cmt);
#line 1630 "flat_modelica_tree_parser.cpp"
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ANNOTATION:
	{
		pComment=annotation(_t,0 /* none */, pComment, INSIDE_COMMENT);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2530 "walker.g"
		bAnno = true;
#line 1642 "flat_modelica_tree_parser.cpp"
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
	currentAST = __currentAST338;
	_t = __t338;
	_t = _t->getNextSibling();
#line 2531 "walker.g"
	
				if (c)
				{
					pComment->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
					pComment->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
				}
				if ((cmt !=0) || bAnno) ast = pComment;
				else ast = 0;
			
#line 1668 "flat_modelica_tree_parser.cpp"
	comment_AST = RefMyAST(currentAST.root);
	returnAST = comment_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::enumeration_literal(RefMyAST _t) {
#line 488 "walker.g"
	DOMElement* ast;
#line 1678 "flat_modelica_tree_parser.cpp"
	RefMyAST enumeration_literal_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST enumeration_literal_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i1 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
#line 489 "walker.g"
	
	DOMElement* c1=0;
	
#line 1690 "flat_modelica_tree_parser.cpp"
	RefMyAST __t33 = _t;
	RefMyAST tmp16_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp16_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp16_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp16_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp16_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST33 = currentAST;
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
	currentAST = __currentAST33;
	_t = __t33;
	_t = _t->getNextSibling();
#line 493 "walker.g"
	
				DOMElement* pEnumerationLiteral = pFlatModelicaXMLDoc->createElement(X("enumeration_literal"));
				pEnumerationLiteral->setAttribute(X("ident"), str2xml(i1));
	
				pEnumerationLiteral->setAttribute(X("sline"), X(itoa(i1->getLine(),stmp,10)));
				pEnumerationLiteral->setAttribute(X("scolumn"), X(itoa(i1->getColumn(),stmp,10)));
	
				if (c1) pEnumerationLiteral->appendChild(c1);
				ast = pEnumerationLiteral;
			
#line 1743 "flat_modelica_tree_parser.cpp"
	enumeration_literal_AST = RefMyAST(currentAST.root);
	returnAST = enumeration_literal_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::element_list(RefMyAST _t,
	int iSwitch, DOMElement*definition
) {
#line 668 "walker.g"
	DOMElement* ast;
#line 1755 "flat_modelica_tree_parser.cpp"
	RefMyAST element_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 668 "walker.g"
	
	DOMElement* e = 0;
	l_stack el_stack;
	DOMElement* ann = 0;
	
#line 1766 "flat_modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case EXTENDS:
		case IMPORT:
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
			goto _loop68;
		}
		}
	}
	_loop68:;
	} // ( ... )*
#line 677 "walker.g"
	
				ast = definition;
	
#line 1806 "flat_modelica_tree_parser.cpp"
	element_list_AST = RefMyAST(currentAST.root);
	returnAST = element_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::public_element_list(RefMyAST _t,
	DOMElement* definition
) {
#line 574 "walker.g"
	DOMElement* ast;
#line 1818 "flat_modelica_tree_parser.cpp"
	RefMyAST public_element_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST public_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 574 "walker.g"
	
	DOMElement* el;
	
#line 1829 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t52 = _t;
	p = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST52 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PUBLIC);
	_t = _t->getFirstChild();
	definition=element_list(_t,1 /* public */, definition);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST52;
	_t = __t52;
	_t = _t->getNextSibling();
#line 582 "walker.g"
	
				ast = definition;
	
#line 1851 "flat_modelica_tree_parser.cpp"
	public_element_list_AST = RefMyAST(currentAST.root);
	returnAST = public_element_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::protected_element_list(RefMyAST _t,
	DOMElement* definition
) {
#line 587 "walker.g"
	DOMElement* ast;
#line 1863 "flat_modelica_tree_parser.cpp"
	RefMyAST protected_element_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST protected_element_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST p_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 587 "walker.g"
	
	DOMElement* el;
	
#line 1874 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t54 = _t;
	p = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST54 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),PROTECTED);
	_t = _t->getFirstChild();
	definition=element_list(_t,2 /* protected */, definition);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST54;
	_t = __t54;
	_t = _t->getNextSibling();
#line 596 "walker.g"
	
				ast = definition;
	
#line 1896 "flat_modelica_tree_parser.cpp"
	protected_element_list_AST = RefMyAST(currentAST.root);
	returnAST = protected_element_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::equation_clause(RefMyAST _t,
	DOMElement *definition
) {
#line 1192 "walker.g"
	DOMElement* ast;
#line 1908 "flat_modelica_tree_parser.cpp"
	RefMyAST equation_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1192 "walker.g"
	
		l_stack el_stack;
		DOMElement* e = 0;
		DOMElement* ann = 0;
	
#line 1921 "flat_modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EQUATION:
	{
		RefMyAST __t148 = _t;
		eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST148 = currentAST;
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
				goto _loop151;
			}
			}
		}
		_loop151:;
		} // ( ... )*
		}
		currentAST = __currentAST148;
		_t = __t148;
		_t = _t->getNextSibling();
#line 1206 "walker.g"
		
					ast = definition;
				
#line 1974 "flat_modelica_tree_parser.cpp"
		equation_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	case INITIAL_EQUATION:
	{
		RefMyAST __t152 = _t;
		RefMyAST tmp17_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp17_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp17_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp17_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp17_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST152 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INITIAL_EQUATION);
		_t = _t->getFirstChild();
		RefMyAST __t153 = _t;
		RefMyAST tmp18_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp18_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp18_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp18_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp18_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST153 = currentAST;
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
				goto _loop155;
			}
			}
		}
		_loop155:;
		} // ( ... )*
		currentAST = __currentAST153;
		_t = __t153;
		_t = _t->getNextSibling();
#line 1216 "walker.g"
		
						ast = definition;
					
#line 2036 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST152;
		_t = __t152;
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

DOMElement*  flat_modelica_tree_parser::algorithm_clause(RefMyAST _t,
	DOMElement* definition
) {
#line 1222 "walker.g"
	DOMElement* ast;
#line 2058 "flat_modelica_tree_parser.cpp"
	RefMyAST algorithm_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1222 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* ann;
	
#line 2069 "flat_modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ALGORITHM:
	{
		RefMyAST __t157 = _t;
		RefMyAST tmp19_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp19_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp19_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp19_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp19_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST157 = currentAST;
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
				goto _loop159;
			}
			}
		}
		_loop159:;
		} // ( ... )*
		currentAST = __currentAST157;
		_t = __t157;
		_t = _t->getNextSibling();
#line 1233 "walker.g"
		
					ast = definition;
				
#line 2121 "flat_modelica_tree_parser.cpp"
		algorithm_clause_AST = RefMyAST(currentAST.root);
		break;
	}
	case INITIAL_ALGORITHM:
	{
		RefMyAST __t160 = _t;
		RefMyAST tmp20_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp20_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp20_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp20_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp20_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST160 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INITIAL_ALGORITHM);
		_t = _t->getFirstChild();
		RefMyAST __t161 = _t;
		RefMyAST tmp21_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp21_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp21_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp21_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp21_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST161 = currentAST;
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
				goto _loop163;
			}
			}
		}
		_loop163:;
		} // ( ... )*
		currentAST = __currentAST161;
		_t = __t161;
		_t = _t->getNextSibling();
#line 1242 "walker.g"
		
						ast = definition;
					
#line 2183 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST160;
		_t = __t160;
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

DOMElement*  flat_modelica_tree_parser::external_function_call(RefMyAST _t,
	DOMElement *pExternalFunctionCall
) {
#line 612 "walker.g"
	DOMElement* ast;
#line 2205 "flat_modelica_tree_parser.cpp"
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
#line 612 "walker.g"
	
		DOMElement* temp=0;
		DOMElement* temp2=0;
		DOMElement* temp3=0;
		ast = 0;
		DOMElement* pExternalEqual = pFlatModelicaXMLDoc->createElement(X("external_equal"));
	
#line 2226 "flat_modelica_tree_parser.cpp"
	
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
	case EXTERNAL_FUNCTION_CALL:
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
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case EXTERNAL_FUNCTION_CALL:
	{
		RefMyAST __t58 = _t;
		RefMyAST tmp22_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp22_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp22_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp22_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp22_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST58 = currentAST;
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
#line 625 "walker.g"
			
									if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));
									if (i != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i));
									if (temp) pExternalFunctionCall->appendChild(temp);
			
									pExternalFunctionCall->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
									pExternalFunctionCall->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			
									ast = pExternalFunctionCall;
								
#line 2318 "flat_modelica_tree_parser.cpp"
			break;
		}
		case EQUALS:
		{
			RefMyAST __t62 = _t;
			e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST62 = currentAST;
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
			currentAST = __currentAST62;
			_t = __t62;
			_t = _t->getNextSibling();
#line 636 "walker.g"
			
									if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));
									if (i2 != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i2));
									pExternalFunctionCall->setAttribute(X("sline"), X(itoa(i2->getLine(),stmp,10)));
									pExternalFunctionCall->setAttribute(X("scolumn"), X(itoa(i2->getColumn(),stmp,10)));
									DOMElement* pExternalEqual =
										pFlatModelicaXMLDoc->createElement(X("external_equal"));
									if (temp2) pExternalEqual->appendChild(temp2);
									pExternalFunctionCall->appendChild(pExternalEqual);
									if (temp3) pExternalFunctionCall->appendChild(temp3);
									ast = pExternalFunctionCall;
								
#line 2379 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST58;
		_t = __t58;
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
#line 650 "walker.g"
	
				if (!ast)
				{
					//parent->appendChild(ast);
					ast = pExternalFunctionCall;
				}
	
#line 2413 "flat_modelica_tree_parser.cpp"
	external_function_call_AST = RefMyAST(currentAST.root);
	returnAST = external_function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::annotation(RefMyAST _t,
	int iSwitch, DOMElement *parent, enum anno awhere
) {
#line 2602 "walker.g"
	DOMElement* ast;
#line 2425 "flat_modelica_tree_parser.cpp"
	RefMyAST annotation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST annotation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2602 "walker.g"
	
	void* cmod=0;
	
#line 2436 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t345 = _t;
	a = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST a_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	a_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(a));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(a_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST345 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ANNOTATION);
	_t = _t->getFirstChild();
	cmod=class_modification(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST345;
	_t = __t345;
	_t = _t->getNextSibling();
#line 2608 "walker.g"
	
				DOMElement *pAnnotation = pFlatModelicaXMLDoc->createElement(X("annotation"));
	
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
	
#line 2484 "flat_modelica_tree_parser.cpp"
	annotation_AST = RefMyAST(currentAST.root);
	returnAST = annotation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::expression_list(RefMyAST _t) {
#line 2425 "walker.g"
	DOMElement* ast;
#line 2494 "flat_modelica_tree_parser.cpp"
	RefMyAST expression_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2425 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		//DOMElement* pComma = pFlatModelicaXMLDoc->createElement(X("comma"));
	
#line 2507 "flat_modelica_tree_parser.cpp"
	
	{
	RefMyAST __t323 = _t;
	el = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST el_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	el_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(el));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST323 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2433 "walker.g"
	el_stack.push(e);
#line 2525 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2434 "walker.g"
			el_stack.push(pFlatModelicaXMLDoc->createElement(X("comma"))); el_stack.push(e);
#line 2536 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop325;
		}
		
	}
	_loop325:;
	} // ( ... )*
	currentAST = __currentAST323;
	_t = __t323;
	_t = _t->getNextSibling();
	}
#line 2437 "walker.g"
	
				ast = (DOMElement*)stack2DOMNode(el_stack, "expression_list");
	
				ast->setAttribute(X("sline"), X(itoa(el->getLine(),stmp,10)));
				ast->setAttribute(X("scolumn"), X(itoa(el->getColumn(),stmp,10)));
			
#line 2556 "flat_modelica_tree_parser.cpp"
	expression_list_AST = RefMyAST(currentAST.root);
	returnAST = expression_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::component_reference(RefMyAST _t) {
#line 2306 "walker.g"
	DOMElement* ast;
#line 2566 "flat_modelica_tree_parser.cpp"
	RefMyAST component_reference_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_reference_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2306 "walker.g"
	
		DOMElement* arr = 0;
		DOMElement* id = 0;
	
#line 2580 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IDENT:
	{
		RefMyAST __t299 = _t;
		i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST299 = currentAST;
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
		currentAST = __currentAST299;
		_t = __t299;
		_t = _t->getNextSibling();
#line 2313 "walker.g"
		
						DOMElement *pCref = pFlatModelicaXMLDoc->createElement(X("component_reference"));
		
						pCref->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
						pCref->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
		
						pCref->setAttribute(X("ident"), str2xml(i));
						if (arr) pCref->appendChild(arr);
						ast = pCref;
					
#line 2633 "flat_modelica_tree_parser.cpp"
		break;
	}
	case DOT:
	{
		RefMyAST __t301 = _t;
		RefMyAST tmp23_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp23_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp23_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp23_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp23_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST301 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DOT);
		_t = _t->getFirstChild();
		RefMyAST __t302 = _t;
		i2 = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST i2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		i2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i2));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i2_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST302 = currentAST;
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
		currentAST = __currentAST302;
		_t = __t302;
		_t = _t->getNextSibling();
		ast=component_reference(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST301;
		_t = __t301;
		_t = _t->getNextSibling();
#line 2325 "walker.g"
		
						DOMElement *pCref = pFlatModelicaXMLDoc->createElement(X("component_reference"));
						pCref->setAttribute(X("ident"), str2xml(i2));
		
						pCref->setAttribute(X("sline"), X(itoa(i2->getLine(),stmp,10)));
						pCref->setAttribute(X("scolumn"), X(itoa(i2->getColumn(),stmp,10)));
		
						if (arr) pCref->appendChild(arr);
						pCref->appendChild(ast);
						ast = pCref;
					
#line 2701 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::element(RefMyAST _t,
	int iSwitch, DOMElement *parent
) {
#line 686 "walker.g"
	DOMElement* ast;
#line 2721 "flat_modelica_tree_parser.cpp"
	RefMyAST element_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fd = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fd_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST id = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST id_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST od = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST od_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST rd = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST rd_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 686 "walker.g"
	
		DOMElement* class_def = 0;
		DOMElement* e_spec = 0;
		DOMElement* final = 0;
		DOMElement* innerouter = 0;
		DOMElement* constr = 0;
		DOMElement* cmt = 0;
		DOMElement* comp_clause = 0;
	
#line 2752 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case IMPORT:
	{
		parent=import_clause(_t,iSwitch, parent);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 698 "walker.g"
		
						ast = parent;
					
#line 2767 "flat_modelica_tree_parser.cpp"
		break;
	}
	case EXTENDS:
	{
		parent=extends_clause(_t,iSwitch, parent);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 702 "walker.g"
		
						ast = parent;
					
#line 2779 "flat_modelica_tree_parser.cpp"
		break;
	}
	case DECLARATION:
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
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DECLARATION);
		_t = _t->getFirstChild();
		{
#line 706 "walker.g"
		
						   DOMElement* componentElement = pFlatModelicaXMLDoc->createElement(X("component_clause"));
						   setVisibility(iSwitch, componentElement);
					
#line 2801 "flat_modelica_tree_parser.cpp"
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
#line 710 "walker.g"
		if (f) componentElement->setAttribute(X("final"), X("true"));
#line 2838 "flat_modelica_tree_parser.cpp"
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
#line 712 "walker.g"
		
								  if (i) componentElement->setAttribute(X("innerouter"), X("inner"));
								  if (o) componentElement->setAttribute(X("innerouter"), X("outer"));
							
#line 2886 "flat_modelica_tree_parser.cpp"
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
		case IDENT:
		{
			parent=component_clause(_t,parent, componentElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 717 "walker.g"
			
										ast = parent;
									
#line 2907 "flat_modelica_tree_parser.cpp"
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
#line 720 "walker.g"
			if (r) componentElement->setAttribute(X("replaceable"), X("true"));
#line 2920 "flat_modelica_tree_parser.cpp"
			parent=component_clause(_t,parent, componentElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			{
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			switch ( _t->getType()) {
			case EXTENDS:
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
#line 723 "walker.g"
			
			if (constr)
										{
											// append the comment to the constraint
											if (cmt) ((DOMElement*)constr)->appendChild(cmt);
											parent->appendChild(constr);
										}
										ast = parent;
									
#line 2958 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		}
		currentAST = __currentAST71;
		_t = __t71;
		_t = _t->getNextSibling();
		break;
	}
	case DEFINITION:
	{
		RefMyAST __t77 = _t;
		RefMyAST tmp25_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp25_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp25_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp25_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp25_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST77 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),DEFINITION);
		_t = _t->getFirstChild();
		{
#line 736 "walker.g"
		
								DOMElement* definitionElement = pFlatModelicaXMLDoc->createElement(X("definition"));
								setVisibility(iSwitch, definitionElement);
							
#line 2992 "flat_modelica_tree_parser.cpp"
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
#line 740 "walker.g"
		if (fd) definitionElement->setAttribute(X("final"), X("true"));
#line 3022 "flat_modelica_tree_parser.cpp"
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
#line 742 "walker.g"
		
								  if (i) definitionElement->setAttribute(X("innerouter"), X("inner"));
								  if (o) definitionElement->setAttribute(X("innerouter"), X("outer"));
							
#line 3063 "flat_modelica_tree_parser.cpp"
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case CLASS_DEFINITION:
		{
			definitionElement=class_definition(_t,fd != NULL, definitionElement);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 748 "walker.g"
			
										if (definitionElement && definitionElement->hasChildNodes())
										{
											parent->appendChild(definitionElement);
										}
										ast = parent;
									
#line 3081 "flat_modelica_tree_parser.cpp"
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
#line 760 "walker.g"
			
										if (definitionElement)
										{
											if (innerouter)
												definitionElement->appendChild(innerouter);
											if (constr)
											{
												definitionElement->appendChild(constr);
												// append the comment to the constraint
												if (cmt) ((DOMElement*)constr)->appendChild(cmt);
											}
											if (rd) definitionElement->setAttribute(X("replaceable"), X("true"));
											if (definitionElement->hasChildNodes())
											{
												parent->appendChild(definitionElement);
											}
										}
										ast = parent;
									
#line 3141 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		}
		currentAST = __currentAST77;
		_t = __t77;
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

DOMElement*  flat_modelica_tree_parser::import_clause(RefMyAST _t,
	int iSwitch, DOMElement *parent
) {
#line 788 "walker.g"
	DOMElement* ast;
#line 3173 "flat_modelica_tree_parser.cpp"
	RefMyAST import_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST import_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 788 "walker.g"
	
		DOMElement* imp = 0;
		DOMElement* cmt = 0;
	
#line 3185 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t85 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST85 = currentAST;
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
	currentAST = __currentAST85;
	_t = __t85;
	_t = _t->getNextSibling();
#line 800 "walker.g"
	
				DOMElement* pImport = pFlatModelicaXMLDoc->createElement(X("import"));
				setVisibility(iSwitch, pImport);
	
				pImport->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pImport->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				pImport->appendChild(imp);
				if (cmt) pImport->appendChild(cmt);
				parent->appendChild(pImport);
				ast = parent;
			
#line 3259 "flat_modelica_tree_parser.cpp"
	import_clause_AST = RefMyAST(currentAST.root);
	returnAST = import_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::extends_clause(RefMyAST _t,
	int iSwitch, DOMElement* parent
) {
#line 869 "walker.g"
	DOMElement* ast;
#line 3271 "flat_modelica_tree_parser.cpp"
	RefMyAST extends_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST extends_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 869 "walker.g"
	
		void *path = 0;
		void *mod = 0;
	
#line 3283 "flat_modelica_tree_parser.cpp"
	
	{
	RefMyAST __t96 = _t;
	e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST96 = currentAST;
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
	currentAST = __currentAST96;
	_t = __t96;
	_t = _t->getNextSibling();
#line 879 "walker.g"
	
					DOMElement* pExtends = pFlatModelicaXMLDoc->createElement(X("extends"));
					setVisibility(iSwitch, pExtends);
	
					pExtends->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
					pExtends->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));
	
					if (mod) pExtends = (DOMElement*)appendKidsFromStack((l_stack *)mod, pExtends);
					if (path) pExtends->setAttribute(X("type"), X(((mstring*)path)->c_str()));
					parent->appendChild(pExtends);
					ast = parent;
				
#line 3336 "flat_modelica_tree_parser.cpp"
	}
	extends_clause_AST = RefMyAST(currentAST.root);
	returnAST = extends_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::component_clause(RefMyAST _t,
	DOMElement* parent, DOMElement* attributes
) {
#line 908 "walker.g"
	DOMElement* ast;
#line 3349 "flat_modelica_tree_parser.cpp"
	RefMyAST component_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 908 "walker.g"
	
		type_prefix_t pfx;
		void* path = 0;
		DOMElement* arr = 0;
		DOMElement* comp_list = 0;
	
#line 3361 "flat_modelica_tree_parser.cpp"
	
	type_prefix(_t,attributes);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	path=type_specifier(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 917 "walker.g"
	if (path) attributes->setAttribute(X("type"), X(((mstring*)path)->c_str()));
#line 3371 "flat_modelica_tree_parser.cpp"
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
#line 920 "walker.g"
	
				ast = parent;
			
#line 3400 "flat_modelica_tree_parser.cpp"
	component_clause_AST = RefMyAST(currentAST.root);
	returnAST = component_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::constraining_clause(RefMyAST _t) {
#line 897 "walker.g"
	DOMElement* ast;
#line 3410 "flat_modelica_tree_parser.cpp"
	RefMyAST constraining_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST constraining_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 897 "walker.g"
	
	DOMElement* pConstrain = pFlatModelicaXMLDoc->createElement(X("constrain"));
	
#line 3419 "flat_modelica_tree_parser.cpp"
	
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

DOMElement*  flat_modelica_tree_parser::explicit_import_name(RefMyAST _t) {
#line 817 "walker.g"
	DOMElement* ast;
#line 3435 "flat_modelica_tree_parser.cpp"
	RefMyAST explicit_import_name_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST explicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 817 "walker.g"
	
		void* path;
	
#line 3446 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t89 = _t;
	RefMyAST tmp26_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp26_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp26_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp26_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp26_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST89 = currentAST;
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
	currentAST = __currentAST89;
	_t = __t89;
	_t = _t->getNextSibling();
#line 823 "walker.g"
	
				DOMElement* pExplicitImport = pFlatModelicaXMLDoc->createElement(X("named_import"));
				pExplicitImport->setAttribute(X("ident"), str2xml(i));
	
				pExplicitImport->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pExplicitImport->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				if (path) pExplicitImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
				ast = pExplicitImport;
			
#line 3482 "flat_modelica_tree_parser.cpp"
	explicit_import_name_AST = RefMyAST(currentAST.root);
	returnAST = explicit_import_name_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::implicit_import_name(RefMyAST _t) {
#line 837 "walker.g"
	DOMElement* ast;
#line 3492 "flat_modelica_tree_parser.cpp"
	RefMyAST implicit_import_name_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST implicit_import_name_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST unq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST unq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST qua = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST qua_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 837 "walker.g"
	
		void* path;
	
#line 3505 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNQUALIFIED:
	{
		RefMyAST __t92 = _t;
		unq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST unq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		unq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(unq));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(unq_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST92 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNQUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST92;
		_t = __t92;
		_t = _t->getNextSibling();
#line 843 "walker.g"
		
						DOMElement* pUnqImport = pFlatModelicaXMLDoc->createElement(X("unqualified_import"));
						if (path) pUnqImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
		
						pUnqImport->setAttribute(X("sline"), X(itoa(unq->getLine(),stmp,10)));
						pUnqImport->setAttribute(X("scolumn"), X(itoa(unq->getColumn(),stmp,10)));
		
						ast = pUnqImport;
					
#line 3539 "flat_modelica_tree_parser.cpp"
		break;
	}
	case QUALIFIED:
	{
		RefMyAST __t93 = _t;
		qua = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST qua_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		qua_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(qua));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(qua_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST93 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),QUALIFIED);
		_t = _t->getFirstChild();
		path=name_path(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST93;
		_t = __t93;
		_t = _t->getNextSibling();
#line 853 "walker.g"
		
						DOMElement* pQuaImport = pFlatModelicaXMLDoc->createElement(X("qualified_import"));
						if (path) pQuaImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
		
						pQuaImport->setAttribute(X("sline"), X(itoa(qua->getLine(),stmp,10)));
						pQuaImport->setAttribute(X("scolumn"), X(itoa(qua->getColumn(),stmp,10)));
		
						ast = pQuaImport;
					
#line 3570 "flat_modelica_tree_parser.cpp"
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

void*  flat_modelica_tree_parser::type_specifier(RefMyAST _t) {
#line 944 "walker.g"
	void* ast;
#line 3588 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::component_list(RefMyAST _t,
	DOMElement* parent, DOMElement *attributes, DOMElement* type_array
) {
#line 950 "walker.g"
	DOMElement* ast;
#line 3608 "flat_modelica_tree_parser.cpp"
	RefMyAST component_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 950 "walker.g"
	
		l_stack el_stack;
		DOMElement* e=0;
	
#line 3618 "flat_modelica_tree_parser.cpp"
	
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
			goto _loop109;
		}
		
	}
	_loop109:;
	} // ( ... )*
#line 959 "walker.g"
	
				ast = parent;
			
#line 3643 "flat_modelica_tree_parser.cpp"
	component_list_AST = RefMyAST(currentAST.root);
	returnAST = component_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::component_declaration(RefMyAST _t,
	DOMElement* parent, DOMElement *attributes, DOMElement *type_array
) {
#line 966 "walker.g"
	DOMElement* ast;
#line 3655 "flat_modelica_tree_parser.cpp"
	RefMyAST component_declaration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 966 "walker.g"
	
		DOMElement* cmt = 0;
		DOMElement* dec = 0;
	
	
#line 3666 "flat_modelica_tree_parser.cpp"
	
	{
	dec=declaration(_t,attributes, type_array);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
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
#line 975 "walker.g"
	
				if (cmt) dec->appendChild(cmt);
				parent->appendChild(dec);
				ast = parent;
			
#line 3702 "flat_modelica_tree_parser.cpp"
	component_declaration_AST = RefMyAST(currentAST.root);
	returnAST = component_declaration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::declaration(RefMyAST _t,
	DOMElement* parent, DOMElement* type_array
) {
#line 984 "walker.g"
	DOMElement* ast;
#line 3714 "flat_modelica_tree_parser.cpp"
	RefMyAST declaration_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST declaration_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 984 "walker.g"
	
		DOMElement* arr = 0;
		DOMElement* mod = 0;
		DOMElement* id = 0;
	
#line 3727 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t114 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST114 = currentAST;
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
	currentAST = __currentAST114;
	_t = __t114;
	_t = _t->getNextSibling();
#line 992 "walker.g"
	
				DOMElement *pComponent = pFlatModelicaXMLDoc->createElement(X("component"));
				pComponent->setAttribute(X("ident"), str2xml(i));
				pComponent->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pComponent->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
				setAttributes(pComponent, parent);
				if (type_array) pComponent->appendChild(type_array);
				if (arr) pComponent->appendChild(arr);
				if (mod) pComponent->appendChild(mod);
				ast = pComponent;
			
#line 3801 "flat_modelica_tree_parser.cpp"
	declaration_AST = RefMyAST(currentAST.root);
	returnAST = declaration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::modification(RefMyAST _t) {
#line 1005 "walker.g"
	DOMElement* ast;
#line 3811 "flat_modelica_tree_parser.cpp"
	RefMyAST modification_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1005 "walker.g"
	
		DOMElement* e = 0;
		void *cm = 0;
		int iswitch = 0;
	
#line 3826 "flat_modelica_tree_parser.cpp"
	
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
		RefMyAST __t120 = _t;
		eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST120 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EQUALS);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST120;
		_t = __t120;
		_t = _t->getNextSibling();
#line 1013 "walker.g"
		iswitch = 1;
#line 3919 "flat_modelica_tree_parser.cpp"
		break;
	}
	case ASSIGN:
	{
		RefMyAST __t121 = _t;
		as = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST as_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		as_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(as));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(as_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST121 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ASSIGN);
		_t = _t->getFirstChild();
		e=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST121;
		_t = __t121;
		_t = _t->getNextSibling();
#line 1014 "walker.g"
		iswitch = 2;
#line 3942 "flat_modelica_tree_parser.cpp"
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
#line 1016 "walker.g"
	
				DOMElement *pModificationEQorASorARG = null;
				if (iswitch == 1) pModificationEQorASorARG = pFlatModelicaXMLDoc->createElement(X("modification_equals"));
				if (iswitch == 2) pModificationEQorASorARG = pFlatModelicaXMLDoc->createElement(X("modification_assign"));
				if (iswitch == 0) pModificationEQorASorARG = pFlatModelicaXMLDoc->createElement(X("modification_arguments"));
				if (cm) pModificationEQorASorARG = (DOMElement*)appendKidsFromStack((l_stack*)cm, pModificationEQorASorARG);
				if (e)
				{
					if (iswitch == 0)
					{
						DOMElement *z = pFlatModelicaXMLDoc->createElement(X("modification_equals"));
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
			
#line 3983 "flat_modelica_tree_parser.cpp"
	modification_AST = RefMyAST(currentAST.root);
	returnAST = modification_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::expression(RefMyAST _t) {
#line 1762 "walker.g"
	DOMElement* ast;
#line 3993 "flat_modelica_tree_parser.cpp"
	RefMyAST expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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

void * flat_modelica_tree_parser::argument_list(RefMyAST _t) {
#line 1057 "walker.g"
	void *stack;
#line 4075 "flat_modelica_tree_parser.cpp"
	RefMyAST argument_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST argument_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1057 "walker.g"
	
		l_stack *el_stack = new l_stack;
		DOMElement* e;
	
#line 4085 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t126 = _t;
	RefMyAST tmp27_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tmp27_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	tmp27_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	tmp27_AST_in = _t;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp27_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST126 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ARGUMENT_LIST);
	_t = _t->getFirstChild();
	e=argument(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1064 "walker.g"
	el_stack->push(e);
#line 4103 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELEMENT_MODIFICATION || _t->getType() == ELEMENT_REDECLARATION)) {
			e=argument(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1065 "walker.g"
			el_stack->push(e);
#line 4114 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop128;
		}
		
	}
	_loop128:;
	} // ( ... )*
	currentAST = __currentAST126;
	_t = __t126;
	_t = _t->getNextSibling();
#line 1067 "walker.g"
	
				if (el_stack) stack = (void*)el_stack;
				else (stack = 0);
			
#line 4131 "flat_modelica_tree_parser.cpp"
	argument_list_AST = RefMyAST(currentAST.root);
	returnAST = argument_list_AST;
	_retTree = _t;
	return stack;
}

DOMElement*  flat_modelica_tree_parser::argument(RefMyAST _t) {
#line 1073 "walker.g"
	DOMElement* ast;
#line 4141 "flat_modelica_tree_parser.cpp"
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
		RefMyAST __t130 = _t;
		em = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST em_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		em_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(em));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(em_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST130 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELEMENT_MODIFICATION);
		_t = _t->getFirstChild();
		ast=element_modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST130;
		_t = __t130;
		_t = _t->getNextSibling();
#line 1076 "walker.g"
		
					if (em)
					{
						ast->setAttribute(X("sline"), X(itoa(em->getLine(),stmp,10)));
						ast->setAttribute(X("scolumn"), X(itoa(em->getColumn(),stmp,10)));
					}
				
#line 4180 "flat_modelica_tree_parser.cpp"
		argument_AST = RefMyAST(currentAST.root);
		break;
	}
	case ELEMENT_REDECLARATION:
	{
		RefMyAST __t131 = _t;
		er = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST er_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		er_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(er));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(er_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST131 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELEMENT_REDECLARATION);
		_t = _t->getFirstChild();
		ast=element_redeclaration(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST131;
		_t = __t131;
		_t = _t->getNextSibling();
#line 1084 "walker.g"
		
					if (er)
					{
						ast->setAttribute(X("sline"), X(itoa(er->getLine(),stmp,10)));
						ast->setAttribute(X("scolumn"), X(itoa(er->getColumn(),stmp,10)));
					}
				
#line 4210 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::element_modification(RefMyAST _t) {
#line 1093 "walker.g"
	DOMElement* ast;
#line 4227 "flat_modelica_tree_parser.cpp"
	RefMyAST element_modification_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST element_modification_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST f_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1093 "walker.g"
	
		DOMElement* cref;
		DOMElement* mod=0;
		DOMElement* cmt=0;
	
#line 4242 "flat_modelica_tree_parser.cpp"
	
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
#line 1105 "walker.g"
	
				DOMElement *pModification = pFlatModelicaXMLDoc->createElement(X("element_modification"));
				if (f) pModification->setAttribute(X("final"), X("true"));
				if (e) pModification->setAttribute(X("each"), X("true"));
				pModification->appendChild(cref);
				if (mod) pModification->appendChild(mod);
				if (cmt) pModification->appendChild(cmt);
				ast = pModification;
			
#line 4335 "flat_modelica_tree_parser.cpp"
	element_modification_AST = RefMyAST(currentAST.root);
	returnAST = element_modification_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::element_redeclaration(RefMyAST _t) {
#line 1116 "walker.g"
	DOMElement* ast;
#line 4345 "flat_modelica_tree_parser.cpp"
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
	RefMyAST re = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST re_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1116 "walker.g"
	
		DOMElement* class_def = 0;
		DOMElement* e_spec = 0;
		DOMElement* constr = 0;
		DOMElement* final = 0;
		DOMElement* each = 0;
		class_def = pFlatModelicaXMLDoc->createElement(X("definition"));
	
#line 4367 "flat_modelica_tree_parser.cpp"
	
	{
	RefMyAST __t138 = _t;
	r = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST r_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	r_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST138 = currentAST;
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
	case IDENT:
	case CLASS_DEFINITION:
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
#line 1129 "walker.g"
			
										DOMElement *pElementRedeclaration = pFlatModelicaXMLDoc->createElement(X("element_redeclaration"));
										if (class_def->hasChildNodes())
											pElementRedeclaration->appendChild(class_def);
										if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
										if (each) pElementRedeclaration->setAttribute(X("each"), X("true"));
										ast = pElementRedeclaration;
									
#line 4479 "flat_modelica_tree_parser.cpp"
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
#line 1137 "walker.g"
			DOMElement *pElementRedeclaration = pFlatModelicaXMLDoc->createElement(X("element_redeclaration"));
#line 4493 "flat_modelica_tree_parser.cpp"
			pElementRedeclaration=component_clause1(_t,pElementRedeclaration);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1139 "walker.g"
			
										if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
										if (each) pElementRedeclaration->setAttribute(X("each"), X("true"));
										ast = pElementRedeclaration;
									
#line 4503 "flat_modelica_tree_parser.cpp"
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
	case REPLACEABLE:
	{
		{
		re = _t;
		RefMyAST re_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		re_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(re));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(re_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),REPLACEABLE);
		_t = _t->getNextSibling();
#line 1147 "walker.g"
		DOMElement *pElementRedeclaration = pFlatModelicaXMLDoc->createElement(X("element_redeclaration"));
#line 4525 "flat_modelica_tree_parser.cpp"
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
		{
			constr=constraining_clause(_t);
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
#line 1152 "walker.g"
		
									if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
									if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
									if (re) pElementRedeclaration->setAttribute(X("replaceable"), X("true"));
									if (class_def && class_def->hasChildNodes())
									{
										pElementRedeclaration->appendChild(class_def);
										if (constr) pElementRedeclaration->appendChild(constr);
									}
									else
									{
										if (constr) pElementRedeclaration->appendChild(constr);
									}
									ast = pElementRedeclaration;
								
#line 4594 "flat_modelica_tree_parser.cpp"
		}
		break;
	}
	default:
	{
		throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
	}
	}
	}
	currentAST = __currentAST138;
	_t = __t138;
	_t = _t->getNextSibling();
	}
	element_redeclaration_AST = RefMyAST(currentAST.root);
	returnAST = element_redeclaration_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::component_clause1(RefMyAST _t,
	DOMElement *parent
) {
#line 1173 "walker.g"
	DOMElement* ast;
#line 4619 "flat_modelica_tree_parser.cpp"
	RefMyAST component_clause1_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST component_clause1_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1173 "walker.g"
	
		type_prefix_t pfx;
		DOMElement* attr = pFlatModelicaXMLDoc->createElement(X("tmp"));
		void* path = 0;
		DOMElement* arr = 0;
		DOMElement* comp_decl = 0;
		DOMElement* comp_list = 0;
	
#line 4633 "flat_modelica_tree_parser.cpp"
	
	type_prefix(_t,attr);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	path=type_specifier(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1184 "walker.g"
	if (path) attr->setAttribute(X("type"), X(((mstring*)path)->c_str()));
#line 4643 "flat_modelica_tree_parser.cpp"
	parent=component_declaration(_t,parent, attr, null);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1186 "walker.g"
	
				ast = parent;
			
#line 4651 "flat_modelica_tree_parser.cpp"
	component_clause1_AST = RefMyAST(currentAST.root);
	returnAST = component_clause1_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::equation(RefMyAST _t,
	DOMElement* definition
) {
#line 1248 "walker.g"
	DOMElement* ast;
#line 4663 "flat_modelica_tree_parser.cpp"
	RefMyAST equation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST es = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST es_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1248 "walker.g"
	
		DOMElement* cmt = 0;
	
#line 4674 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t165 = _t;
	es = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST es_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	es_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(es));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(es_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST165 = currentAST;
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
#line 1262 "walker.g"
	
					DOMElement*  pEquation = pFlatModelicaXMLDoc->createElement(X("equation"));
					pEquation->appendChild(ast);
					if (cmt) pEquation->appendChild(cmt);
					if (es)
					{
						pEquation->setAttribute(X("sline"), X(itoa(es->getLine(),stmp,10)));
						pEquation->setAttribute(X("scolumn"), X(itoa(es->getColumn(),stmp,10)));
					}
					definition->appendChild(pEquation);
					ast = definition;
				
#line 4773 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST165;
	_t = __t165;
	_t = _t->getNextSibling();
	equation_AST = RefMyAST(currentAST.root);
	returnAST = equation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::algorithm(RefMyAST _t,
	DOMElement *definition
) {
#line 1292 "walker.g"
	DOMElement* ast;
#line 4788 "flat_modelica_tree_parser.cpp"
	RefMyAST algorithm_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST as_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST az = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST az_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1292 "walker.g"
	
		DOMElement* cref;
		DOMElement* expr;
		DOMElement* tuple;
		DOMElement* args;
		DOMElement* cmt=0;
	
#line 4805 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t170 = _t;
	as = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST as_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	as_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(as));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(as_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST170 = currentAST;
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
		RefMyAST __t172 = _t;
		az = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST az_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		az_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(az));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(az_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST172 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ASSIGN);
		_t = _t->getFirstChild();
		{
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			expr=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1304 "walker.g"
			
										DOMElement*  pAlgAssign = pFlatModelicaXMLDoc->createElement(X("alg_assign"));
										if (az)
										{
											pAlgAssign->setAttribute(X("sline"), X(itoa(az->getLine(),stmp,10)));
											pAlgAssign->setAttribute(X("scolumn"), X(itoa(az->getColumn(),stmp,10)));
										}
										pAlgAssign->appendChild(cref);
										pAlgAssign->appendChild(expr);
										ast = pAlgAssign;
									
#line 4858 "flat_modelica_tree_parser.cpp"
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
#line 1316 "walker.g"
			
										DOMElement*  pAlgAssign = pFlatModelicaXMLDoc->createElement(X("alg_assign"));
										DOMElement*  pCall = pFlatModelicaXMLDoc->createElement(X("call"));
			
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
									
#line 4900 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
		currentAST = __currentAST172;
		_t = __t172;
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
#line 1350 "walker.g"
	
					DOMElement* pAlgorithm = pFlatModelicaXMLDoc->createElement(X("algorithm"));
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
		  		
#line 4997 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST170;
	_t = __t170;
	_t = _t->getNextSibling();
	algorithm_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::equality_equation(RefMyAST _t) {
#line 1393 "walker.g"
	DOMElement* ast;
#line 5010 "flat_modelica_tree_parser.cpp"
	RefMyAST equality_equation_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equality_equation_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1393 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 5022 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t178 = _t;
	eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST178 = currentAST;
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
	currentAST = __currentAST178;
	_t = __t178;
	_t = _t->getNextSibling();
#line 1400 "walker.g"
	
				DOMElement*  pEquEqual = pFlatModelicaXMLDoc->createElement(X("equ_equal"));
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
			
#line 5058 "flat_modelica_tree_parser.cpp"
	equality_equation_AST = RefMyAST(currentAST.root);
	returnAST = equality_equation_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::conditional_equation_e(RefMyAST _t) {
#line 1416 "walker.g"
	DOMElement* ast;
#line 5068 "flat_modelica_tree_parser.cpp"
	RefMyAST conditional_equation_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1416 "walker.g"
	
		DOMElement* e1;
		DOMElement* then_b;
		DOMElement* else_b = 0;
		DOMElement* else_if_b;
		l_stack el_stack;
		DOMElement* e;
	
		DOMElement*  pEquIf = pFlatModelicaXMLDoc->createElement(X("equ_if"));
		DOMElement*  pEquThen = pFlatModelicaXMLDoc->createElement(X("equ_then"));
	DOMElement*  pEquElse = pFlatModelicaXMLDoc->createElement(X("equ_else"));
	
		bool fbElse = false;
	
#line 5090 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t180 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST180 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1433 "walker.g"
	pEquIf->appendChild(e1);
#line 5107 "flat_modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1434 "walker.g"
	pEquIf->appendChild(pEquThen);
#line 5113 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=equation_elseif(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1435 "walker.g"
			el_stack.push(e);
#line 5124 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop182;
		}
		
	}
	_loop182:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		RefMyAST tmp28_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp28_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp28_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp28_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp28_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSE);
		_t = _t->getNextSibling();
		pEquElse=equation_list(_t,pEquElse);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1436 "walker.g"
		fbElse = true;
#line 5151 "flat_modelica_tree_parser.cpp"
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
	currentAST = __currentAST180;
	_t = __t180;
	_t = _t->getNextSibling();
#line 1438 "walker.g"
	
				pEquIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pEquIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				if (el_stack.size()>0) pEquIf = (DOMElement*)appendKids(el_stack, pEquIf); // ?? is this ok?
				if (fbElse) pEquIf->appendChild(pEquElse);
				ast = pEquIf;
			
#line 5176 "flat_modelica_tree_parser.cpp"
	conditional_equation_e_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::for_clause_e(RefMyAST _t) {
#line 1489 "walker.g"
	DOMElement* ast;
#line 5186 "flat_modelica_tree_parser.cpp"
	RefMyAST for_clause_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1489 "walker.g"
	
		DOMElement* f;
		DOMElement* eq;
		DOMElement*  pEquFor = pFlatModelicaXMLDoc->createElement(X("equ_for"));
	
#line 5199 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t190 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST190 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR);
	_t = _t->getFirstChild();
	f=for_indices(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1496 "walker.g"
	pEquFor->appendChild(f);
#line 5216 "flat_modelica_tree_parser.cpp"
	pEquFor=equation_list(_t,pEquFor);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST190;
	_t = __t190;
	_t = _t->getNextSibling();
#line 1498 "walker.g"
	
				pEquFor->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pEquFor->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				ast = pEquFor;
			
#line 5230 "flat_modelica_tree_parser.cpp"
	for_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = for_clause_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::when_clause_e(RefMyAST _t) {
#line 1587 "walker.g"
	DOMElement* ast;
#line 5240 "flat_modelica_tree_parser.cpp"
	RefMyAST when_clause_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1587 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* body;
		DOMElement* el = 0;
		DOMElement* pEquWhen = pFlatModelicaXMLDoc->createElement(X("equ_when"));
		DOMElement* pEquThen = pFlatModelicaXMLDoc->createElement(X("equ_then"));
	
#line 5256 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t201 = _t;
	wh = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST wh_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	wh_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(wh));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(wh_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST201 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1598 "walker.g"
	pEquWhen->appendChild(e);
#line 5273 "flat_modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1599 "walker.g"
	pEquWhen->appendChild(pEquThen);
#line 5279 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEWHEN)) {
			el=else_when_e(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1600 "walker.g"
			el_stack.push(el);
#line 5290 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop203;
		}
		
	}
	_loop203:;
	} // ( ... )*
	currentAST = __currentAST201;
	_t = __t201;
	_t = _t->getNextSibling();
#line 1602 "walker.g"
	
				pEquWhen->setAttribute(X("sline"), X(itoa(wh->getLine(),stmp,10)));
				pEquWhen->setAttribute(X("scolumn"), X(itoa(wh->getColumn(),stmp,10)));
	
				if (el_stack.size()>0) pEquWhen = (DOMElement*)appendKids(el_stack, pEquWhen); // ??is this ok?
				ast = pEquWhen;
			
#line 5310 "flat_modelica_tree_parser.cpp"
	when_clause_e_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::connect_clause(RefMyAST _t) {
#line 1739 "walker.g"
	DOMElement* ast;
#line 5320 "flat_modelica_tree_parser.cpp"
	RefMyAST connect_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST connect_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1739 "walker.g"
	
		DOMElement* r1;
		DOMElement* r2;
	
#line 5332 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t223 = _t;
	c = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST c_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	c_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(c));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(c_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST223 = currentAST;
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
	currentAST = __currentAST223;
	_t = __t223;
	_t = _t->getNextSibling();
#line 1749 "walker.g"
	
				DOMElement* pEquConnect = pFlatModelicaXMLDoc->createElement(X("equ_connect"));
	
				pEquConnect->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
				pEquConnect->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
	
				pEquConnect->appendChild(r1);
				pEquConnect->appendChild(r2);
				ast = pEquConnect;
			
#line 5364 "flat_modelica_tree_parser.cpp"
	connect_clause_AST = RefMyAST(currentAST.root);
	returnAST = connect_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::equation_funcall(RefMyAST _t) {
#line 1277 "walker.g"
	DOMElement* ast;
#line 5374 "flat_modelica_tree_parser.cpp"
	RefMyAST equation_funcall_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_funcall_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1277 "walker.g"
	
	DOMElement* fcall = 0;
	DOMElement* cref = 0;
	
#line 5384 "flat_modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	fcall=function_call(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1284 "walker.g"
	
				 DOMElement*  pEquCall = pFlatModelicaXMLDoc->createElement(X("equ_call"));
				 pEquCall->appendChild(cref);
				 pEquCall->appendChild(fcall);
				 ast = pEquCall;
			
#line 5399 "flat_modelica_tree_parser.cpp"
	equation_funcall_AST = RefMyAST(currentAST.root);
	returnAST = equation_funcall_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::function_call(RefMyAST _t) {
#line 2339 "walker.g"
	DOMElement* ast;
#line 5409 "flat_modelica_tree_parser.cpp"
	RefMyAST function_call_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fa = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST fa_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	RefMyAST __t305 = _t;
	fa = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST fa_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	fa_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(fa));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(fa_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST305 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FUNCTION_ARGUMENTS);
	_t = _t->getFirstChild();
	ast=function_arguments(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2342 "walker.g"
	
				ast->setAttribute(X("sline"), X(itoa(fa->getLine(),stmp,10)));
				ast->setAttribute(X("scolumn"), X(itoa(fa->getColumn(),stmp,10)));
			
#line 5435 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST305;
	_t = __t305;
	_t = _t->getNextSibling();
	function_call_AST = RefMyAST(currentAST.root);
	returnAST = function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::tuple_expression_list(RefMyAST _t) {
#line 2445 "walker.g"
	DOMElement* ast;
#line 5448 "flat_modelica_tree_parser.cpp"
	RefMyAST tuple_expression_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST tuple_expression_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2445 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		//DOMElement* pComma = pFlatModelicaXMLDoc->createElement(X("comma"));
	
#line 5461 "flat_modelica_tree_parser.cpp"
	
	{
	RefMyAST __t328 = _t;
	el = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST el_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	el_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(el));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST328 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2453 "walker.g"
	el_stack.push(e);
#line 5479 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2454 "walker.g"
			el_stack.push(pFlatModelicaXMLDoc->createElement(X("comma"))); el_stack.push(e);
#line 5490 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop330;
		}
		
	}
	_loop330:;
	} // ( ... )*
	currentAST = __currentAST328;
	_t = __t328;
	_t = _t->getNextSibling();
	}
#line 2457 "walker.g"
	
				if (el_stack.size() == 1)
				{
					ast = el_stack.top();
				}
				else
				{
					DOMElement *pTuple = pFlatModelicaXMLDoc->createElement(X("output_expression_list"));
					pTuple = (DOMElement*)appendKids(el_stack, pTuple);
	
					pTuple->setAttribute(X("sline"), X(itoa(el->getLine(),stmp,10)));
					pTuple->setAttribute(X("scolumn"), X(itoa(el->getColumn(),stmp,10)));
	
					ast = pTuple;
				}
			
#line 5520 "flat_modelica_tree_parser.cpp"
	tuple_expression_list_AST = RefMyAST(currentAST.root);
	returnAST = tuple_expression_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::algorithm_function_call(RefMyAST _t) {
#line 1372 "walker.g"
	DOMElement* ast;
#line 5530 "flat_modelica_tree_parser.cpp"
	RefMyAST algorithm_function_call_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_function_call_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1372 "walker.g"
	
		DOMElement* cref;
		DOMElement* args;
	
#line 5540 "flat_modelica_tree_parser.cpp"
	
	cref=component_reference(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	args=function_call(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1379 "walker.g"
	
				DOMElement*  pAlgCall = pFlatModelicaXMLDoc->createElement(X("alg_call"));
				pAlgCall->appendChild(cref);
				pAlgCall->appendChild(args);
				ast = pAlgCall;
				/*
				<!ELEMENT alg_call (component_reference, function_arguments)>
				<!ATTLIST alg_call
					%location;
				>
				*/
			
#line 5561 "flat_modelica_tree_parser.cpp"
	algorithm_function_call_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_function_call_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::conditional_equation_a(RefMyAST _t) {
#line 1448 "walker.g"
	DOMElement* ast;
#line 5571 "flat_modelica_tree_parser.cpp"
	RefMyAST conditional_equation_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST conditional_equation_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1448 "walker.g"
	
		DOMElement* e1;
		DOMElement* then_b;
		DOMElement* else_b = 0;
		DOMElement* else_if_b;
		l_stack el_stack;
		DOMElement* e;
		DOMElement*  pAlgIf = pFlatModelicaXMLDoc->createElement(X("alg_if"));
		DOMElement*  pAlgThen = pFlatModelicaXMLDoc->createElement(X("alg_then"));
		DOMElement*  pAlgElse = pFlatModelicaXMLDoc->createElement(X("alg_else"));
		bool fbElse = false;
	
#line 5591 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t185 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST185 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),IF);
	_t = _t->getFirstChild();
	e1=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1463 "walker.g"
	pAlgIf->appendChild(e1);
#line 5608 "flat_modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1465 "walker.g"
	
					if (pAlgThen)
					pAlgIf->appendChild(pAlgThen);
				
#line 5617 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEIF)) {
			e=algorithm_elseif(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1469 "walker.g"
			el_stack.push(e);
#line 5628 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop187;
		}
		
	}
	_loop187:;
	} // ( ... )*
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case ELSE:
	{
		RefMyAST tmp29_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp29_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp29_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp29_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp29_AST));
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSE);
		_t = _t->getNextSibling();
		pAlgElse=algorithm_list(_t,pAlgElse);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1470 "walker.g"
		fbElse = true;
#line 5655 "flat_modelica_tree_parser.cpp"
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
	currentAST = __currentAST185;
	_t = __t185;
	_t = _t->getNextSibling();
#line 1472 "walker.g"
	
				pAlgIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pAlgIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
				if (el_stack.size()>0) pAlgIf = (DOMElement*)appendKids(el_stack, pAlgIf);
				if (fbElse)  pAlgIf->appendChild(pAlgElse);
				ast = pAlgIf;
			
#line 5679 "flat_modelica_tree_parser.cpp"
	conditional_equation_a_AST = RefMyAST(currentAST.root);
	returnAST = conditional_equation_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::for_clause_a(RefMyAST _t) {
#line 1507 "walker.g"
	DOMElement* ast;
#line 5689 "flat_modelica_tree_parser.cpp"
	RefMyAST for_clause_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1507 "walker.g"
	
		DOMElement* f;
		DOMElement* eq;
		DOMElement*  pAlgFor = pFlatModelicaXMLDoc->createElement(X("alg_for"));
	
#line 5702 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t192 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST192 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),FOR);
	_t = _t->getFirstChild();
	f=for_indices(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1515 "walker.g"
	
					f->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
					f->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
					pAlgFor->appendChild(f);
				
#line 5723 "flat_modelica_tree_parser.cpp"
	pAlgFor=algorithm_list(_t,pAlgFor);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST192;
	_t = __t192;
	_t = _t->getNextSibling();
#line 1521 "walker.g"
	
				pAlgFor->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pAlgFor->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				ast = pAlgFor;
			
#line 5737 "flat_modelica_tree_parser.cpp"
	for_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = for_clause_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::while_clause(RefMyAST _t) {
#line 1557 "walker.g"
	DOMElement* ast;
#line 5747 "flat_modelica_tree_parser.cpp"
	RefMyAST while_clause_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST while_clause_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST w = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST w_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1557 "walker.g"
	
		DOMElement* e;
		DOMElement* body;
		DOMElement* pAlgWhile = pFlatModelicaXMLDoc->createElement(X("alg_while"));
	
#line 5760 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t199 = _t;
	w = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST w_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	w_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(w));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(w_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST199 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WHILE);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1566 "walker.g"
	
				  pAlgWhile->appendChild(e);
			
#line 5779 "flat_modelica_tree_parser.cpp"
	pAlgWhile=algorithm_list(_t,pAlgWhile);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST199;
	_t = __t199;
	_t = _t->getNextSibling();
#line 1570 "walker.g"
	
				pAlgWhile->setAttribute(X("sline"), X(itoa(w->getLine(),stmp,10)));
				pAlgWhile->setAttribute(X("scolumn"), X(itoa(w->getColumn(),stmp,10)));
	
				ast = pAlgWhile;
			
#line 5793 "flat_modelica_tree_parser.cpp"
	while_clause_AST = RefMyAST(currentAST.root);
	returnAST = while_clause_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::when_clause_a(RefMyAST _t) {
#line 1630 "walker.g"
	DOMElement* ast;
#line 5803 "flat_modelica_tree_parser.cpp"
	RefMyAST when_clause_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST when_clause_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST wh_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1630 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* body;
		DOMElement* el = 0;
		DOMElement* pAlgWhen = pFlatModelicaXMLDoc->createElement(X("alg_when"));
		DOMElement* pAlgThen = pFlatModelicaXMLDoc->createElement(X("alg_then"));
	
#line 5819 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t207 = _t;
	wh = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST wh_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	wh_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(wh));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(wh_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST207 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),WHEN);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1641 "walker.g"
	pAlgWhen->appendChild(e);
#line 5836 "flat_modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1642 "walker.g"
	pAlgWhen->appendChild(pAlgThen);
#line 5842 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == ELSEWHEN)) {
			el=else_when_a(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1643 "walker.g"
			el_stack.push(el);
#line 5853 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop209;
		}
		
	}
	_loop209:;
	} // ( ... )*
	currentAST = __currentAST207;
	_t = __t207;
	_t = _t->getNextSibling();
#line 1645 "walker.g"
	
				pAlgWhen->setAttribute(X("sline"), X(itoa(wh->getLine(),stmp,10)));
				pAlgWhen->setAttribute(X("scolumn"), X(itoa(wh->getColumn(),stmp,10)));
	
				if (el_stack.size() > 0) pAlgWhen = (DOMElement*)appendKids(el_stack, pAlgWhen);
				ast = pAlgWhen;
			
#line 5873 "flat_modelica_tree_parser.cpp"
	when_clause_a_AST = RefMyAST(currentAST.root);
	returnAST = when_clause_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::simple_expression(RefMyAST _t) {
#line 1823 "walker.g"
	DOMElement* ast;
#line 5883 "flat_modelica_tree_parser.cpp"
	RefMyAST simple_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST simple_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r3 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r3_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r2 = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST r2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1823 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
		DOMElement* e3;
	
#line 5898 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case RANGE3:
	{
		RefMyAST __t234 = _t;
		r3 = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST r3_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		r3_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r3));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r3_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST234 = currentAST;
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
		currentAST = __currentAST234;
		_t = __t234;
		_t = _t->getNextSibling();
#line 1833 "walker.g"
		
						DOMElement* pRange = pFlatModelicaXMLDoc->createElement(X("range"));
		
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
					
#line 5946 "flat_modelica_tree_parser.cpp"
		break;
	}
	case RANGE2:
	{
		RefMyAST __t235 = _t;
		r2 = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST r2_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		r2_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(r2));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(r2_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST235 = currentAST;
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
		currentAST = __currentAST235;
		_t = __t235;
		_t = _t->getNextSibling();
#line 1851 "walker.g"
		
						DOMElement* pRange = pFlatModelicaXMLDoc->createElement(X("range"));
		
						pRange->setAttribute(X("sline"), X(itoa(r2->getLine(),stmp,10)));
						pRange->setAttribute(X("scolumn"), X(itoa(r2->getColumn(),stmp,10)));
		
						pRange->appendChild(e1);
						pRange->appendChild(e3);
						ast = pRange;
					
#line 5981 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::equation_list(RefMyAST _t,
	DOMElement* pEquationList
) {
#line 1715 "walker.g"
	DOMElement* ast;
#line 6036 "flat_modelica_tree_parser.cpp"
	RefMyAST equation_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1715 "walker.g"
	
		DOMElement* e;
		l_stack el_stack;
	
#line 6046 "flat_modelica_tree_parser.cpp"
	
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
			goto _loop218;
		}
		
	}
	_loop218:;
	} // ( ... )*
#line 1722 "walker.g"
	
				ast = pEquationList;
			
#line 6068 "flat_modelica_tree_parser.cpp"
	equation_list_AST = RefMyAST(currentAST.root);
	returnAST = equation_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::equation_elseif(RefMyAST _t) {
#line 1673 "walker.g"
	DOMElement* ast;
#line 6078 "flat_modelica_tree_parser.cpp"
	RefMyAST equation_elseif_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST equation_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1673 "walker.g"
	
		DOMElement* e;
		DOMElement* eq;
		DOMElement* pEquElseIf = pFlatModelicaXMLDoc->createElement(X("equ_elseif"));
		DOMElement* pEquThen = pFlatModelicaXMLDoc->createElement(X("equ_then"));
	
#line 6092 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t213 = _t;
	els = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST els_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	els_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(els));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(els_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST213 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1682 "walker.g"
	pEquElseIf->appendChild(e);
#line 6109 "flat_modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST213;
	_t = __t213;
	_t = _t->getNextSibling();
#line 1685 "walker.g"
	
				pEquElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
				pEquElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));
	
				pEquElseIf->appendChild(pEquThen);
				ast = pEquElseIf;
			
#line 6124 "flat_modelica_tree_parser.cpp"
	equation_elseif_AST = RefMyAST(currentAST.root);
	returnAST = equation_elseif_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::algorithm_list(RefMyAST _t,
	DOMElement*  pAlgorithmList
) {
#line 1727 "walker.g"
	DOMElement* ast;
#line 6136 "flat_modelica_tree_parser.cpp"
	RefMyAST algorithm_list_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_list_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1727 "walker.g"
	
		DOMElement* e;
		l_stack el_stack;
	
#line 6146 "flat_modelica_tree_parser.cpp"
	
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
			goto _loop221;
		}
		
	}
	_loop221:;
	} // ( ... )*
#line 1734 "walker.g"
	
				ast = pAlgorithmList;
			
#line 6168 "flat_modelica_tree_parser.cpp"
	algorithm_list_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_list_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::algorithm_elseif(RefMyAST _t) {
#line 1694 "walker.g"
	DOMElement* ast;
#line 6178 "flat_modelica_tree_parser.cpp"
	RefMyAST algorithm_elseif_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST algorithm_elseif_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1694 "walker.g"
	
		DOMElement* e;
		DOMElement* body;
		DOMElement* pAlgElseIf = pFlatModelicaXMLDoc->createElement(X("alg_elseif"));
		DOMElement* pAlgThen = pFlatModelicaXMLDoc->createElement(X("alg_then"));
	
#line 6192 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t215 = _t;
	els = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST els_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	els_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(els));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(els_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST215 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEIF);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1703 "walker.g"
	pAlgElseIf->appendChild(e);
#line 6209 "flat_modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST215;
	_t = __t215;
	_t = _t->getNextSibling();
#line 1706 "walker.g"
	
				pAlgElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
				pAlgElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));
	
				pAlgElseIf->appendChild(pAlgThen);
				ast = pAlgElseIf;
			
#line 6224 "flat_modelica_tree_parser.cpp"
	algorithm_elseif_AST = RefMyAST(currentAST.root);
	returnAST = algorithm_elseif_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::for_indices(RefMyAST _t) {
#line 1531 "walker.g"
	DOMElement* ast;
#line 6234 "flat_modelica_tree_parser.cpp"
	RefMyAST for_indices_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST for_indices_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1531 "walker.g"
	
		DOMElement* f;
		DOMElement* e;
		l_stack el_stack;
	
#line 6247 "flat_modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == IN)) {
			RefMyAST __t195 = _t;
			RefMyAST tmp30_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp30_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp30_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp30_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp30_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST195 = currentAST;
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
			currentAST = __currentAST195;
			_t = __t195;
			_t = _t->getNextSibling();
#line 1539 "walker.g"
			
					DOMElement* pForIndex = pFlatModelicaXMLDoc->createElement(X("for_index"));
					pForIndex->setAttribute(X("ident"), str2xml(i));
			
					pForIndex->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
					pForIndex->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			
					if (e) pForIndex->appendChild(e);
					el_stack.push(pForIndex);
				
#line 6344 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop197;
		}
		
	}
	_loop197:;
	} // ( ... )*
#line 1550 "walker.g"
	
			DOMElement*  pForIndices = pFlatModelicaXMLDoc->createElement(X("for_indices"));
			pForIndices = (DOMElement*)appendKids(el_stack, pForIndices);
			ast = pForIndices;
		
#line 6359 "flat_modelica_tree_parser.cpp"
	for_indices_AST = RefMyAST(currentAST.root);
	returnAST = for_indices_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::else_when_e(RefMyAST _t) {
#line 1611 "walker.g"
	DOMElement* ast;
#line 6369 "flat_modelica_tree_parser.cpp"
	RefMyAST else_when_e_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1611 "walker.g"
	
		DOMElement*  expr;
		DOMElement*  eqn;
		DOMElement* pEquElseWhen = pFlatModelicaXMLDoc->createElement(X("equ_elsewhen"));
	DOMElement* pEquThen = pFlatModelicaXMLDoc->createElement(X("equ_then"));
	
#line 6383 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t205 = _t;
	e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST205 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1619 "walker.g"
	pEquElseWhen->appendChild(expr);
#line 6400 "flat_modelica_tree_parser.cpp"
	pEquThen=equation_list(_t,pEquThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST205;
	_t = __t205;
	_t = _t->getNextSibling();
#line 1621 "walker.g"
	
				pEquElseWhen->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
				pEquElseWhen->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));
	
				pEquElseWhen->appendChild(pEquThen);
				ast = pEquElseWhen;
			
#line 6415 "flat_modelica_tree_parser.cpp"
	else_when_e_AST = RefMyAST(currentAST.root);
	returnAST = else_when_e_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::else_when_a(RefMyAST _t) {
#line 1654 "walker.g"
	DOMElement* ast;
#line 6425 "flat_modelica_tree_parser.cpp"
	RefMyAST else_when_a_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST else_when_a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST e_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1654 "walker.g"
	
		DOMElement*  expr;
		DOMElement*  alg;
		DOMElement* pAlgElseWhen = pFlatModelicaXMLDoc->createElement(X("alg_elsewhen"));
		DOMElement* pAlgThen = pFlatModelicaXMLDoc->createElement(X("alg_then"));
	
#line 6439 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t211 = _t;
	e = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST e_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	e_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(e));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(e_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST211 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),ELSEWHEN);
	_t = _t->getFirstChild();
	expr=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1662 "walker.g"
	pAlgElseWhen->appendChild(expr);
#line 6456 "flat_modelica_tree_parser.cpp"
	pAlgThen=algorithm_list(_t,pAlgThen);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
	currentAST = __currentAST211;
	_t = __t211;
	_t = _t->getNextSibling();
#line 1664 "walker.g"
	
				pAlgElseWhen->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
				pAlgElseWhen->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));
	
		        pAlgElseWhen->appendChild(pAlgThen);
				ast = pAlgElseWhen;
			
#line 6471 "flat_modelica_tree_parser.cpp"
	else_when_a_AST = RefMyAST(currentAST.root);
	returnAST = else_when_a_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::if_expression(RefMyAST _t) {
#line 1770 "walker.g"
	DOMElement* ast;
#line 6481 "flat_modelica_tree_parser.cpp"
	RefMyAST if_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST if_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1770 "walker.g"
	
		DOMElement* cond;
		DOMElement* thenPart;
		DOMElement* elsePart;
		DOMElement* e;
		DOMElement* elseifPart;
		l_stack el_stack;
	
#line 6497 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t227 = _t;
	i = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST i_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	i_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(i));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(i_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST227 = currentAST;
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
#line 1781 "walker.g"
			el_stack.push(e);
#line 6525 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop229;
		}
		
	}
	_loop229:;
	} // ( ... )*
	elsePart=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1782 "walker.g"
	
					DOMElement* pIf = pFlatModelicaXMLDoc->createElement(X("if"));
					DOMElement* pThen = pFlatModelicaXMLDoc->createElement(X("then"));
					DOMElement* pElse = pFlatModelicaXMLDoc->createElement(X("else"));
	
					pIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
					pIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
					pIf->appendChild(cond);
					pThen->appendChild(thenPart);
					pIf->appendChild(pThen);
					if (el_stack.size()>0) pIf = (DOMElement*)appendKids(el_stack, pIf); //??is this ok??
					pElse->appendChild(elsePart);
					pIf->appendChild(pElse);
					ast = pIf;
				
#line 6554 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST227;
	_t = __t227;
	_t = _t->getNextSibling();
	if_expression_AST = RefMyAST(currentAST.root);
	returnAST = if_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::code_expression(RefMyAST _t) {
#line 1866 "walker.g"
	DOMElement* ast;
#line 6567 "flat_modelica_tree_parser.cpp"
	RefMyAST code_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST code_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1866 "walker.g"
	
		DOMElement*pCode = pFlatModelicaXMLDoc->createElement(X("code"));
	
#line 6576 "flat_modelica_tree_parser.cpp"
	
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case CODE_MODIFICATION:
	{
		RefMyAST __t237 = _t;
		RefMyAST tmp31_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp31_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp31_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp31_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp31_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST237 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_MODIFICATION);
		_t = _t->getFirstChild();
		{
		ast=modification(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST237;
		_t = __t237;
		_t = _t->getNextSibling();
#line 1873 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pModification = pFlatModelicaXMLDoc->createElement(X("modification"));
					pModification->appendChild(ast);
					ast = pModification;
					/*
					ast = Absyn__CODE(Absyn__C_5fMODIFICATION(ast));
					*/
				
#line 6612 "flat_modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_EXPRESSION:
	{
		RefMyAST __t239 = _t;
		RefMyAST tmp32_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp32_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp32_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp32_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp32_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST239 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_EXPRESSION);
		_t = _t->getFirstChild();
		{
		ast=expression(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST239;
		_t = __t239;
		_t = _t->getNextSibling();
#line 1884 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pExpression = pFlatModelicaXMLDoc->createElement(X("expression"));
					pExpression->appendChild(ast);
					ast = pExpression;
					/* ast = Absyn__CODE(Absyn__C_5fEXPRESSION(ast)); */
				
#line 6645 "flat_modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_ELEMENT:
	{
		RefMyAST __t241 = _t;
		RefMyAST tmp33_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp33_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp33_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp33_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp33_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST241 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_ELEMENT);
		_t = _t->getFirstChild();
		{
		ast=element(_t,0 /* none */, pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST241;
		_t = __t241;
		_t = _t->getNextSibling();
#line 1893 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pElement = pFlatModelicaXMLDoc->createElement(X("element"));
					pElement->appendChild(ast);
					ast = pElement;
					/* ast = Absyn__CODE(Absyn__C_5fELEMENT(ast)); */
				
#line 6678 "flat_modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_EQUATION:
	{
		RefMyAST __t243 = _t;
		RefMyAST tmp34_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp34_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp34_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp34_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp34_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST243 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_EQUATION);
		_t = _t->getFirstChild();
		{
		ast=equation_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST243;
		_t = __t243;
		_t = _t->getNextSibling();
#line 1902 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pEquationSection = pFlatModelicaXMLDoc->createElement(X("equation_section"));
					pEquationSection->appendChild(ast);
					ast = pEquationSection;
					/* ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_FALSE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1)))); */
				
#line 6712 "flat_modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_INITIALEQUATION:
	{
		RefMyAST __t245 = _t;
		RefMyAST tmp35_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp35_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp35_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp35_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp35_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST245 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_INITIALEQUATION);
		_t = _t->getFirstChild();
		{
		ast=equation_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST245;
		_t = __t245;
		_t = _t->getNextSibling();
#line 1912 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pEquationSection = pFlatModelicaXMLDoc->createElement(X("equation_section"));
					((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
					pEquationSection->appendChild(ast);
					ast = pEquationSection;
					/*
					ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_TRUE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 6749 "flat_modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_ALGORITHM:
	{
		RefMyAST __t247 = _t;
		RefMyAST tmp36_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp36_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp36_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp36_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp36_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST247 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_ALGORITHM);
		_t = _t->getFirstChild();
		{
		ast=algorithm_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST247;
		_t = __t247;
		_t = _t->getNextSibling();
#line 1924 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pAlgorithmSection = pFlatModelicaXMLDoc->createElement(X("algorithm_section"));
					pAlgorithmSection->appendChild(ast);
					ast = pAlgorithmSection;
					/*
					ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_FALSE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 6785 "flat_modelica_tree_parser.cpp"
		code_expression_AST = RefMyAST(currentAST.root);
		break;
	}
	case CODE_INITIALALGORITHM:
	{
		RefMyAST __t249 = _t;
		RefMyAST tmp37_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp37_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp37_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp37_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp37_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST249 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),CODE_INITIALALGORITHM);
		_t = _t->getFirstChild();
		{
		ast=algorithm_clause(_t,pCode);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		}
		currentAST = __currentAST249;
		_t = __t249;
		_t = _t->getNextSibling();
#line 1935 "walker.g"
		
					// ?? what the hack is this?
					DOMElement* pAlgorithmSection = pFlatModelicaXMLDoc->createElement(X("algorithm_section"));
					((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
					pAlgorithmSection->appendChild(ast);
					ast = pAlgorithmSection;
					/*
					ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_TRUE,
							RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
					*/
				
#line 6822 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::elseif_expression(RefMyAST _t) {
#line 1801 "walker.g"
	DOMElement* ast;
#line 6839 "flat_modelica_tree_parser.cpp"
	RefMyAST elseif_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST elseif_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST els_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1801 "walker.g"
	
		DOMElement* cond;
		DOMElement* thenPart;
	
#line 6851 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t231 = _t;
	els = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST els_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	els_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(els));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(els_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST231 = currentAST;
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
#line 1808 "walker.g"
	
				DOMElement* pElseIf = pFlatModelicaXMLDoc->createElement(X("elseif"));
	
				pElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
				pElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));
	
				pElseIf->appendChild(cond);
				DOMElement* pThen = pFlatModelicaXMLDoc->createElement(X("then"));
				pThen->appendChild(thenPart);
				pElseIf->appendChild(pThen);
				ast = pElseIf;
			
#line 6882 "flat_modelica_tree_parser.cpp"
	currentAST = __currentAST231;
	_t = __t231;
	_t = _t->getNextSibling();
	elseif_expression_AST = RefMyAST(currentAST.root);
	returnAST = elseif_expression_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::logical_expression(RefMyAST _t) {
#line 1948 "walker.g"
	DOMElement* ast;
#line 6895 "flat_modelica_tree_parser.cpp"
	RefMyAST logical_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST o_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1948 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 6907 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case OR:
	{
		RefMyAST __t253 = _t;
		o = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST o_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		o_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(o));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(o_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST253 = currentAST;
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
		currentAST = __currentAST253;
		_t = __t253;
		_t = _t->getNextSibling();
#line 1956 "walker.g"
		
						DOMElement* pOr = pFlatModelicaXMLDoc->createElement(X("or"));
		
						pOr->setAttribute(X("sline"), X(itoa(o->getLine(),stmp,10)));
						pOr->setAttribute(X("scolumn"), X(itoa(o->getColumn(),stmp,10)));
		
						pOr->appendChild(e1);
						pOr->appendChild(e2);
						ast = pOr;
					
#line 6979 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::logical_term(RefMyAST _t) {
#line 1970 "walker.g"
	DOMElement* ast;
#line 6997 "flat_modelica_tree_parser.cpp"
	RefMyAST logical_term_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST logical_term_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST a_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 1970 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 7009 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case AND:
	{
		RefMyAST __t256 = _t;
		a = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST a_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		a_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(a));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(a_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST256 = currentAST;
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
		currentAST = __currentAST256;
		_t = __t256;
		_t = _t->getNextSibling();
#line 1978 "walker.g"
		
						DOMElement* pAnd = pFlatModelicaXMLDoc->createElement(X("and"));
		
						pAnd->setAttribute(X("sline"), X(itoa(a->getLine(),stmp,10)));
						pAnd->setAttribute(X("scolumn"), X(itoa(a->getColumn(),stmp,10)));
		
						pAnd->appendChild(e1);
						pAnd->appendChild(e2);
						ast = pAnd;
					
#line 7080 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::logical_factor(RefMyAST _t) {
#line 1991 "walker.g"
	DOMElement* ast;
#line 7098 "flat_modelica_tree_parser.cpp"
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
		RefMyAST __t258 = _t;
		n = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST n_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		n_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(n));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(n_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST258 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),NOT);
		_t = _t->getFirstChild();
		ast=relation(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 1994 "walker.g"
		
				DOMElement* pNot = pFlatModelicaXMLDoc->createElement(X("not"));
		
				pNot->setAttribute(X("sline"), X(itoa(n->getLine(),stmp,10)));
				pNot->setAttribute(X("scolumn"), X(itoa(n->getColumn(),stmp,10)));
		
				pNot->appendChild(ast);
				ast = pNot;
			
#line 7134 "flat_modelica_tree_parser.cpp"
		currentAST = __currentAST258;
		_t = __t258;
		_t = _t->getNextSibling();
		logical_factor_AST = RefMyAST(currentAST.root);
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

DOMElement*  flat_modelica_tree_parser::relation(RefMyAST _t) {
#line 2005 "walker.g"
	DOMElement* ast;
#line 7187 "flat_modelica_tree_parser.cpp"
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
#line 2005 "walker.g"
	
		DOMElement* e1;
		DOMElement* op = 0;
		DOMElement* e2 = 0;
	
#line 7210 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
			RefMyAST __t262 = _t;
			lt = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST lt_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			lt_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lt));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lt_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST262 = currentAST;
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
			currentAST = __currentAST262;
			_t = __t262;
			_t = _t->getNextSibling();
#line 2015 "walker.g"
			op = pFlatModelicaXMLDoc->createElement(X("lt")); /* Absyn__LESS; */
#line 7276 "flat_modelica_tree_parser.cpp"
			break;
		}
		case LESSEQ:
		{
			RefMyAST __t263 = _t;
			lte = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST lte_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			lte_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lte));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lte_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST263 = currentAST;
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
			currentAST = __currentAST263;
			_t = __t263;
			_t = _t->getNextSibling();
#line 2017 "walker.g"
			op = pFlatModelicaXMLDoc->createElement(X("lte")); /* Absyn__LESSEQ; */
#line 7302 "flat_modelica_tree_parser.cpp"
			break;
		}
		case GREATER:
		{
			RefMyAST __t264 = _t;
			gt = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST gt_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			gt_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(gt));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(gt_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST264 = currentAST;
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
			currentAST = __currentAST264;
			_t = __t264;
			_t = _t->getNextSibling();
#line 2019 "walker.g"
			op = pFlatModelicaXMLDoc->createElement(X("gt")); /* Absyn__GREATER; */
#line 7328 "flat_modelica_tree_parser.cpp"
			break;
		}
		case GREATEREQ:
		{
			RefMyAST __t265 = _t;
			gte = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST gte_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			gte_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(gte));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(gte_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST265 = currentAST;
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
			currentAST = __currentAST265;
			_t = __t265;
			_t = _t->getNextSibling();
#line 2021 "walker.g"
			op = pFlatModelicaXMLDoc->createElement(X("gte")); /* Absyn__GREATEREQ; */
#line 7354 "flat_modelica_tree_parser.cpp"
			break;
		}
		case EQEQ:
		{
			RefMyAST __t266 = _t;
			eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST266 = currentAST;
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
			currentAST = __currentAST266;
			_t = __t266;
			_t = _t->getNextSibling();
#line 2023 "walker.g"
			op = pFlatModelicaXMLDoc->createElement(X("eq")); /* Absyn__EQUAL; */
#line 7380 "flat_modelica_tree_parser.cpp"
			break;
		}
		case LESSGT:
		{
			RefMyAST __t267 = _t;
			ne = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST ne_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			ne_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ne));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ne_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST267 = currentAST;
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
			currentAST = __currentAST267;
			_t = __t267;
			_t = _t->getNextSibling();
#line 2025 "walker.g"
			op = pFlatModelicaXMLDoc->createElement(X("ne")); /* op = Absyn__NEQUAL; */
#line 7406 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			throw ANTLR_USE_NAMESPACE(antlr)NoViableAltException(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		}
		}
		}
#line 2027 "walker.g"
		
						op->appendChild(e1);
						op->appendChild(e2);
						if (lt) { op->setAttribute(X("sline"), X(itoa(lt->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(lt->getColumn(),stmp,10))); }
						if (lte){ op->setAttribute(X("sline"), X(itoa(lte->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(lte->getColumn(),stmp,10)));	}
						if (gt) { op->setAttribute(X("sline"), X(itoa(gt->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(gt->getColumn(),stmp,10))); }
						if (gte){ op->setAttribute(X("sline"), X(itoa(gte->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(gte->getColumn(),stmp,10)));	}
						if (eq)	{ op->setAttribute(X("sline"), X(itoa(eq->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(eq->getColumn(),stmp,10))); }
						if (ne) { op->setAttribute(X("sline"), X(itoa(ne->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(ne->getColumn(),stmp,10))); }
						ast = op;
					
#line 7427 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::arithmetic_expression(RefMyAST _t) {
#line 2041 "walker.g"
	DOMElement* ast;
#line 7445 "flat_modelica_tree_parser.cpp"
	RefMyAST arithmetic_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST arithmetic_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2041 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 7459 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case PLUS:
	{
		RefMyAST __t270 = _t;
		add = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST add_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		add_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(add));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(add_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST270 = currentAST;
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
		currentAST = __currentAST270;
		_t = __t270;
		_t = _t->getNextSibling();
#line 2049 "walker.g"
		
						DOMElement* pAdd = pFlatModelicaXMLDoc->createElement(X("add"));
		
						pAdd->setAttribute(X("sline"), X(itoa(add->getLine(),stmp,10)));
						pAdd->setAttribute(X("scolumn"), X(itoa(add->getColumn(),stmp,10)));
		
						pAdd->setAttribute(X("operation"), X("binary"));
						pAdd->appendChild(e1);
						pAdd->appendChild(e2);
						ast = pAdd;
					
#line 7522 "flat_modelica_tree_parser.cpp"
		break;
	}
	case MINUS:
	{
		RefMyAST __t271 = _t;
		sub = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sub_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sub_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sub));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sub_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST271 = currentAST;
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
		currentAST = __currentAST271;
		_t = __t271;
		_t = _t->getNextSibling();
#line 2061 "walker.g"
		
						DOMElement* pSub = pFlatModelicaXMLDoc->createElement(X("sub"));
		
						pSub->setAttribute(X("sline"), X(itoa(sub->getLine(),stmp,10)));
						pSub->setAttribute(X("scolumn"), X(itoa(sub->getColumn(),stmp,10)));
		
						pSub->setAttribute(X("operation"), X("binary"));
						pSub->appendChild(e1);
						pSub->appendChild(e2);
						ast = pSub;
					
#line 7558 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::unary_arithmetic_expression(RefMyAST _t) {
#line 2075 "walker.g"
	DOMElement* ast;
#line 7576 "flat_modelica_tree_parser.cpp"
	RefMyAST unary_arithmetic_expression_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST unary_arithmetic_expression_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST add_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST sub_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
		_t = ASTNULL;
	switch ( _t->getType()) {
	case UNARY_PLUS:
	{
		RefMyAST __t274 = _t;
		add = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST add_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		add_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(add));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(add_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST274 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNARY_PLUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST274;
		_t = __t274;
		_t = _t->getNextSibling();
#line 2078 "walker.g"
		
					DOMElement* pAdd = pFlatModelicaXMLDoc->createElement(X("add"));
		
					pAdd->setAttribute(X("sline"), X(itoa(add->getLine(),stmp,10)));
					pAdd->setAttribute(X("scolumn"), X(itoa(add->getColumn(),stmp,10)));
		
					pAdd->setAttribute(X("operation"), X("unary"));
					pAdd->appendChild(ast);
					ast = pAdd;
				
#line 7619 "flat_modelica_tree_parser.cpp"
		break;
	}
	case UNARY_MINUS:
	{
		RefMyAST __t275 = _t;
		sub = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST sub_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		sub_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(sub));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(sub_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST275 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),UNARY_MINUS);
		_t = _t->getFirstChild();
		ast=term(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST275;
		_t = __t275;
		_t = _t->getNextSibling();
#line 2089 "walker.g"
		
					DOMElement* pSub = pFlatModelicaXMLDoc->createElement(X("sub"));
		
					pSub->setAttribute(X("sline"), X(itoa(sub->getLine(),stmp,10)));
					pSub->setAttribute(X("scolumn"), X(itoa(sub->getColumn(),stmp,10)));
		
					pSub->setAttribute(X("operation"), X("unary"));
					pSub->appendChild(ast);
					ast = pSub;
				
#line 7651 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::term(RefMyAST _t) {
#line 2103 "walker.g"
	DOMElement* ast;
#line 7691 "flat_modelica_tree_parser.cpp"
	RefMyAST term_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST term_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST mul = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST mul_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST div = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST div_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2103 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 7705 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case STAR:
	{
		RefMyAST __t278 = _t;
		mul = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST mul_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		mul_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(mul));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(mul_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST278 = currentAST;
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
		currentAST = __currentAST278;
		_t = __t278;
		_t = _t->getNextSibling();
#line 2111 "walker.g"
		
						DOMElement* pMul = pFlatModelicaXMLDoc->createElement(X("mul"));
		
						pMul->setAttribute(X("sline"), X(itoa(mul->getLine(),stmp,10)));
						pMul->setAttribute(X("scolumn"), X(itoa(mul->getColumn(),stmp,10)));
		
						pMul->appendChild(e1);
						pMul->appendChild(e2);
						ast = pMul;
					
#line 7763 "flat_modelica_tree_parser.cpp"
		break;
	}
	case SLASH:
	{
		RefMyAST __t279 = _t;
		div = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST div_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		div_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(div));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(div_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST279 = currentAST;
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
		currentAST = __currentAST279;
		_t = __t279;
		_t = _t->getNextSibling();
#line 2122 "walker.g"
		
						DOMElement* pDiv = pFlatModelicaXMLDoc->createElement(X("div"));
		
						pDiv->setAttribute(X("sline"), X(itoa(div->getLine(),stmp,10)));
						pDiv->setAttribute(X("scolumn"), X(itoa(div->getColumn(),stmp,10)));
		
						pDiv->appendChild(e1);
						pDiv->appendChild(e2);
						ast = pDiv;
					
#line 7798 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::factor(RefMyAST _t) {
#line 2135 "walker.g"
	DOMElement* ast;
#line 7816 "flat_modelica_tree_parser.cpp"
	RefMyAST factor_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST factor_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST pw = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST pw_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2135 "walker.g"
	
		DOMElement* e1;
		DOMElement* e2;
	
#line 7828 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		break;
	}
	case POWER:
	{
		RefMyAST __t282 = _t;
		pw = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST pw_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		pw_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(pw));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(pw_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST282 = currentAST;
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
		currentAST = __currentAST282;
		_t = __t282;
		_t = _t->getNextSibling();
#line 2143 "walker.g"
		
						DOMElement* pPow = pFlatModelicaXMLDoc->createElement(X("pow"));
		
						pPow->setAttribute(X("sline"), X(itoa(pw->getLine(),stmp,10)));
						pPow->setAttribute(X("scolumn"), X(itoa(pw->getColumn(),stmp,10)));
		
						pPow->appendChild(e1);
						pPow->appendChild(e2);
						ast = pPow;
					
#line 7885 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::primary(RefMyAST _t) {
#line 2156 "walker.g"
	DOMElement* ast;
#line 7903 "flat_modelica_tree_parser.cpp"
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
	RefMyAST lbk = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbk_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbr = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST lbr_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tend = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST tend_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2156 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
		DOMElement* pSemicolon = pFlatModelicaXMLDoc->createElement(X("semicolon"));
	
#line 7930 "flat_modelica_tree_parser.cpp"
	
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
#line 2164 "walker.g"
		
						DOMElement* pIntegerLiteral = pFlatModelicaXMLDoc->createElement(X("integer_literal"));
						pIntegerLiteral->setAttribute(X("value"), str2xml(ui));
		
						pIntegerLiteral->setAttribute(X("sline"), X(itoa(ui->getLine(),stmp,10)));
						pIntegerLiteral->setAttribute(X("scolumn"), X(itoa(ui->getColumn(),stmp,10)));
		
						ast = pIntegerLiteral;
					
#line 7954 "flat_modelica_tree_parser.cpp"
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
#line 2174 "walker.g"
		
						DOMElement* pRealLiteral = pFlatModelicaXMLDoc->createElement(X("real_literal"));
						pRealLiteral->setAttribute(X("value"), str2xml(ur));
		
						pRealLiteral->setAttribute(X("sline"), X(itoa(ur->getLine(),stmp,10)));
						pRealLiteral->setAttribute(X("scolumn"), X(itoa(ur->getColumn(),stmp,10)));
		
						ast = pRealLiteral;
					
#line 7975 "flat_modelica_tree_parser.cpp"
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
#line 2184 "walker.g"
		
						DOMElement* pStringLiteral = pFlatModelicaXMLDoc->createElement(X("string_literal"));
						pStringLiteral->setAttribute(X("value"), str2xml(str));
		
						pStringLiteral->setAttribute(X("sline"), X(itoa(str->getLine(),stmp,10)));
						pStringLiteral->setAttribute(X("scolumn"), X(itoa(str->getColumn(),stmp,10)));
		
						ast = pStringLiteral;
					
#line 7996 "flat_modelica_tree_parser.cpp"
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
#line 2194 "walker.g"
		
					DOMElement* pBoolLiteral = pFlatModelicaXMLDoc->createElement(X("bool_literal"));
					pBoolLiteral->setAttribute(X("value"), X("false"));
		
					pBoolLiteral->setAttribute(X("sline"), X(itoa(f->getLine(),stmp,10)));
					pBoolLiteral->setAttribute(X("scolumn"), X(itoa(f->getColumn(),stmp,10)));
		
					ast = pBoolLiteral;
				
#line 8017 "flat_modelica_tree_parser.cpp"
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
#line 2204 "walker.g"
		
					DOMElement* pBoolLiteral = pFlatModelicaXMLDoc->createElement(X("bool_literal"));
					pBoolLiteral->setAttribute(X("value"), X("true"));
		
					pBoolLiteral->setAttribute(X("sline"), X(itoa(t->getLine(),stmp,10)));
					pBoolLiteral->setAttribute(X("scolumn"), X(itoa(t->getColumn(),stmp,10)));
		
					ast = pBoolLiteral;
				
#line 8038 "flat_modelica_tree_parser.cpp"
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
	case LPAR:
	{
		RefMyAST __t285 = _t;
		RefMyAST tmp38_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		RefMyAST tmp38_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		tmp38_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
		tmp38_AST_in = _t;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp38_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST285 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LPAR);
		_t = _t->getFirstChild();
		ast=tuple_expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST285;
		_t = __t285;
		_t = _t->getNextSibling();
		break;
	}
	case LBRACK:
	{
		RefMyAST __t286 = _t;
		lbk = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST lbk_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		lbk_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lbk));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lbk_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST286 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LBRACK);
		_t = _t->getFirstChild();
		e=expression_list(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2215 "walker.g"
		el_stack.push(e);
#line 8089 "flat_modelica_tree_parser.cpp"
		{ // ( ... )*
		for (;;) {
			if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
				_t = ASTNULL;
			if ((_t->getType() == EXPRESSION_LIST)) {
				e=expression_list(_t);
				_t = _retTree;
				astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2216 "walker.g"
				el_stack.push(e);
#line 8100 "flat_modelica_tree_parser.cpp"
			}
			else {
				goto _loop288;
			}
			
		}
		_loop288:;
		} // ( ... )*
		currentAST = __currentAST286;
		_t = __t286;
		_t = _t->getNextSibling();
#line 2217 "walker.g"
		
						DOMElement* pConcat = pFlatModelicaXMLDoc->createElement(X("concat"));
		
						pConcat->setAttribute(X("sline"), X(itoa(lbk->getLine(),stmp,10)));
						pConcat->setAttribute(X("scolumn"), X(itoa(lbk->getColumn(),stmp,10)));
		
						pConcat = (DOMElement*)appendKids(el_stack, pConcat);
						ast = pConcat;
					
#line 8122 "flat_modelica_tree_parser.cpp"
		break;
	}
	case LBRACE:
	{
		RefMyAST __t289 = _t;
		lbr = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST lbr_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		lbr_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(lbr));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(lbr_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST289 = currentAST;
		currentAST.root = currentAST.child;
		currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),LBRACE);
		_t = _t->getFirstChild();
		ast=function_arguments(_t);
		_t = _retTree;
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
		currentAST = __currentAST289;
		_t = __t289;
		_t = _t->getNextSibling();
#line 2227 "walker.g"
		
					DOMElement* pArray = pFlatModelicaXMLDoc->createElement(X("array"));
		
					pArray->setAttribute(X("sline"), X(itoa(lbr->getLine(),stmp,10)));
					pArray->setAttribute(X("scolumn"), X(itoa(lbr->getColumn(),stmp,10)));
		
					pArray->appendChild(ast);
					ast = pArray;
				
#line 8153 "flat_modelica_tree_parser.cpp"
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
#line 2237 "walker.g"
		
					DOMElement* pEnd = pFlatModelicaXMLDoc->createElement(X("end"));
					pEnd->setAttribute(X("sline"), X(itoa(tend->getLine(),stmp,10)));
					pEnd->setAttribute(X("scolumn"), X(itoa(tend->getColumn(),stmp,10)));
					ast = pEnd;
				
#line 8171 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::component_reference__function_call(RefMyAST _t) {
#line 2246 "walker.g"
	DOMElement* ast;
#line 8189 "flat_modelica_tree_parser.cpp"
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
#line 2246 "walker.g"
	
		DOMElement* cref;
		DOMElement* fnc = 0;
	
#line 8205 "flat_modelica_tree_parser.cpp"
	
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
			RefMyAST __t292 = _t;
			fc = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
			RefMyAST fc_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			fc_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(fc));
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(fc_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST292 = currentAST;
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
			currentAST = __currentAST292;
			_t = __t292;
			_t = _t->getNextSibling();
#line 2253 "walker.g"
			
							DOMElement* pCall = pFlatModelicaXMLDoc->createElement(X("call"));
			
							pCall->setAttribute(X("sline"), X(itoa(fc->getLine(),stmp,10)));
							pCall->setAttribute(X("scolumn"), X(itoa(fc->getColumn(),stmp,10)));
			
							pCall->appendChild(cref);
							if (fnc) pCall->appendChild(fnc);
							ast = pCall;
						
#line 8268 "flat_modelica_tree_parser.cpp"
			break;
		}
		case DOT:
		case IDENT:
		{
			cref=component_reference(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2264 "walker.g"
			
							if (fnc && cref) cref->appendChild(fnc);
							ast = cref;
						
#line 8282 "flat_modelica_tree_parser.cpp"
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
		RefMyAST __t294 = _t;
		ifc = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST ifc_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		ifc_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(ifc));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(ifc_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST294 = currentAST;
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
		currentAST = __currentAST294;
		_t = __t294;
		_t = _t->getNextSibling();
#line 2271 "walker.g"
		
						// calling function initial
						DOMElement* pCall = pFlatModelicaXMLDoc->createElement(X("call"));
		
						DOMElement* pCref = pFlatModelicaXMLDoc->createElement(X("component_reference"));
						pCref->setAttribute(X("ident"), X("initial"));
						pCref->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
						pCref->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
		
						pCall->appendChild(pCref);
		
						pCall->setAttribute(X("sline"), X(itoa(ifc->getLine(),stmp,10)));
						pCall->setAttribute(X("scolumn"), X(itoa(ifc->getColumn(),stmp,10)));
		
						ast = pCall;
					
#line 8332 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::function_arguments(RefMyAST _t) {
#line 2372 "walker.g"
	DOMElement* ast;
#line 8349 "flat_modelica_tree_parser.cpp"
	RefMyAST function_arguments_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST function_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2372 "walker.g"
	
		l_stack el_stack;
		DOMElement* elist=0;
		DOMElement* namel=0;
		DOMElement *pFunctionArguments = pFlatModelicaXMLDoc->createElement(X("function_arguments"));
	
#line 8361 "flat_modelica_tree_parser.cpp"
	
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
#line 2382 "walker.g"
	
				ast = pFunctionArguments;
			
#line 8410 "flat_modelica_tree_parser.cpp"
	function_arguments_AST = RefMyAST(currentAST.root);
	returnAST = function_arguments_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::expression_list2(RefMyAST _t,
	DOMElement *parent
) {
#line 2351 "walker.g"
	DOMElement* ast;
#line 8422 "flat_modelica_tree_parser.cpp"
	RefMyAST expression_list2_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST expression_list2_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST el_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2351 "walker.g"
	
		l_stack el_stack;
		DOMElement* e;
	
#line 8434 "flat_modelica_tree_parser.cpp"
	
	{
	RefMyAST __t308 = _t;
	el = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST el_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	el_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(el));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(el_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST308 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),EXPRESSION_LIST);
	_t = _t->getFirstChild();
	e=expression(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2358 "walker.g"
	parent->appendChild(e);
#line 8452 "flat_modelica_tree_parser.cpp"
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_tokenSet_2.member(_t->getType()))) {
			e=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2359 "walker.g"
			parent->appendChild(e);
#line 8463 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop310;
		}
		
	}
	_loop310:;
	} // ( ... )*
	currentAST = __currentAST308;
	_t = __t308;
	_t = _t->getNextSibling();
	}
#line 2362 "walker.g"
	
				ast = parent;
			
#line 8480 "flat_modelica_tree_parser.cpp"
	expression_list2_AST = RefMyAST(currentAST.root);
	returnAST = expression_list2_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::named_arguments(RefMyAST _t,
	DOMElement *parent
) {
#line 2390 "walker.g"
	DOMElement* ast;
#line 8492 "flat_modelica_tree_parser.cpp"
	RefMyAST named_arguments_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_arguments_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST na = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST na_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2390 "walker.g"
	
		l_stack el_stack;
		DOMElement* n;
	
#line 8504 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t315 = _t;
	na = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST na_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	na_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(na));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(na_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST315 = currentAST;
	currentAST.root = currentAST.child;
	currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),NAMED_ARGUMENTS);
	_t = _t->getFirstChild();
	{
	n=named_argument(_t);
	_t = _retTree;
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2396 "walker.g"
	parent->appendChild(n);
#line 8522 "flat_modelica_tree_parser.cpp"
	}
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		if ((_t->getType() == EQUALS)) {
			n=named_argument(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2397 "walker.g"
			parent->appendChild(n);
#line 8534 "flat_modelica_tree_parser.cpp"
		}
		else {
			goto _loop318;
		}
		
	}
	_loop318:;
	} // ( ... )*
	currentAST = __currentAST315;
	_t = __t315;
	_t = _t->getNextSibling();
#line 2398 "walker.g"
	
				ast = parent;
			
#line 8550 "flat_modelica_tree_parser.cpp"
	named_arguments_AST = RefMyAST(currentAST.root);
	returnAST = named_arguments_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::named_argument(RefMyAST _t) {
#line 2403 "walker.g"
	DOMElement* ast;
#line 8560 "flat_modelica_tree_parser.cpp"
	RefMyAST named_argument_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST named_argument_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST eq_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST i_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2403 "walker.g"
	
		DOMElement* temp;
	
#line 8573 "flat_modelica_tree_parser.cpp"
	
	RefMyAST __t320 = _t;
	eq = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	RefMyAST eq_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	eq_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(eq));
	astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(eq_AST));
	ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST320 = currentAST;
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
	currentAST = __currentAST320;
	_t = __t320;
	_t = _t->getNextSibling();
#line 2409 "walker.g"
	
				DOMElement *pNamedArgument = pFlatModelicaXMLDoc->createElement(X("named_argument"));
				pNamedArgument->setAttribute(X("ident"), str2xml(i));
	
				pNamedArgument->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pNamedArgument->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	
				pNamedArgument->appendChild(temp);
				ast = pNamedArgument;
			
#line 8608 "flat_modelica_tree_parser.cpp"
	named_argument_AST = RefMyAST(currentAST.root);
	returnAST = named_argument_AST;
	_retTree = _t;
	return ast;
}

DOMElement*  flat_modelica_tree_parser::subscript(RefMyAST _t,
	DOMElement* parent
) {
#line 2497 "walker.g"
	DOMElement* ast;
#line 8620 "flat_modelica_tree_parser.cpp"
	RefMyAST subscript_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST subscript_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST c_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2497 "walker.g"
	
		DOMElement* e;
		DOMElement* pColon = pFlatModelicaXMLDoc->createElement(X("colon"));
	
#line 8632 "flat_modelica_tree_parser.cpp"
	
	{
	if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
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
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
#line 2505 "walker.g"
		
						parent->appendChild(e);
						ast = parent;
					
#line 8686 "flat_modelica_tree_parser.cpp"
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
#line 2510 "walker.g"
		
		
						pColon->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
						pColon->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
		
						parent->appendChild(pColon);
						ast = parent;
					
#line 8706 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::string_concatenation(RefMyAST _t) {
#line 2563 "walker.g"
	DOMElement* ast;
#line 8724 "flat_modelica_tree_parser.cpp"
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
#line 2563 "walker.g"
	
			DOMElement*pString1;
			l_stack el_stack;
		
#line 8740 "flat_modelica_tree_parser.cpp"
	
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
#line 2570 "walker.g"
		
					DOMElement *pString = pFlatModelicaXMLDoc->createElement(X("string_literal"));
					pString->setAttribute(X("value"), str2xml(s));
		
					pString->setAttribute(X("sline"), X(itoa(s->getLine(),stmp,10)));
					pString->setAttribute(X("scolumn"), X(itoa(s->getColumn(),stmp,10)));
		
			  		ast=pString;
				
#line 8763 "flat_modelica_tree_parser.cpp"
		string_concatenation_AST = RefMyAST(currentAST.root);
		break;
	}
	case PLUS:
	{
		RefMyAST __t343 = _t;
		p = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
		RefMyAST p_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
		p_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(p));
		astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(p_AST));
		ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST343 = currentAST;
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
		currentAST = __currentAST343;
		_t = __t343;
		_t = _t->getNextSibling();
#line 2580 "walker.g"
		
					 DOMElement *pString = pFlatModelicaXMLDoc->createElement(X("add_string"));
		
					 pString->setAttribute(X("sline"), X(itoa(p->getLine(),stmp,10)));
					 pString->setAttribute(X("scolumn"), X(itoa(p->getColumn(),stmp,10)));
		
					 pString->appendChild(pString1);
					 DOMElement *pString2 = pFlatModelicaXMLDoc->createElement(X("string_literal"));
					 pString2->setAttribute(X("value"), str2xml(s2));
		
					 pString2->setAttribute(X("sline"), X(itoa(s2->getLine(),stmp,10)));
					 pString2->setAttribute(X("scolumn"), X(itoa(s2->getColumn(),stmp,10)));
		
					 pString->appendChild(pString2);
					 ast=pString;
				
#line 8808 "flat_modelica_tree_parser.cpp"
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

DOMElement*  flat_modelica_tree_parser::interactive_stmt(RefMyAST _t) {
#line 2640 "walker.g"
	DOMElement* ast;
#line 8825 "flat_modelica_tree_parser.cpp"
	RefMyAST interactive_stmt_AST_in = (_t == RefMyAST(ASTNULL)) ? RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) : _t;
	returnAST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	ANTLR_USE_NAMESPACE(antlr)ASTPair currentAST;
	RefMyAST interactive_stmt_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
	RefMyAST s_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
#line 2640 "walker.g"
	
	DOMElement* al=0;
	DOMElement* el=0;
		l_stack el_stack;
	DOMElement *pInteractiveSTMT = pFlatModelicaXMLDoc->createElement(X("ISTMT"));
		DOMElement *pInteractiveALG = pFlatModelicaXMLDoc->createElement(X("IALG"));
	
#line 8840 "flat_modelica_tree_parser.cpp"
	
	{ // ( ... )*
	for (;;) {
		if (_t == RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST) )
			_t = ASTNULL;
		switch ( _t->getType()) {
		case INTERACTIVE_ALG:
		{
			RefMyAST __t348 = _t;
			RefMyAST tmp39_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp39_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp39_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp39_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp39_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST348 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INTERACTIVE_ALG);
			_t = _t->getFirstChild();
			{
			pInteractiveALG=algorithm(_t,pInteractiveALG);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			currentAST = __currentAST348;
			_t = __t348;
			_t = _t->getNextSibling();
#line 2651 "walker.g"
			
							//pInteractiveALG->appendChild(al);
							el_stack.push(pInteractiveALG);
						
#line 8873 "flat_modelica_tree_parser.cpp"
			break;
		}
		case INTERACTIVE_EXP:
		{
			RefMyAST __t350 = _t;
			RefMyAST tmp40_AST = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			RefMyAST tmp40_AST_in = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			tmp40_AST = astFactory->create(ANTLR_USE_NAMESPACE(antlr)RefAST(_t));
			tmp40_AST_in = _t;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(tmp40_AST));
			ANTLR_USE_NAMESPACE(antlr)ASTPair __currentAST350 = currentAST;
			currentAST.root = currentAST.child;
			currentAST.child = RefMyAST(ANTLR_USE_NAMESPACE(antlr)nullAST);
			match(ANTLR_USE_NAMESPACE(antlr)RefAST(_t),INTERACTIVE_EXP);
			_t = _t->getFirstChild();
			{
			el=expression(_t);
			_t = _retTree;
			astFactory->addASTChild(currentAST, ANTLR_USE_NAMESPACE(antlr)RefAST(returnAST));
			}
			currentAST = __currentAST350;
			_t = __t350;
			_t = _t->getNextSibling();
#line 2657 "walker.g"
			
							DOMElement *pInteractiveEXP = pFlatModelicaXMLDoc->createElement(X("IEXP"));
							pInteractiveEXP->appendChild(el);
							el_stack.push(pInteractiveEXP);
						
#line 8903 "flat_modelica_tree_parser.cpp"
			break;
		}
		default:
		{
			goto _loop352;
		}
		}
	}
	_loop352:;
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
#line 2664 "walker.g"
	
				pInteractiveSTMT = (DOMElement*)appendKids(el_stack, pInteractiveSTMT);
				if (s) pInteractiveSTMT->setAttribute(X("semicolon"),X("true"));
				ast = pInteractiveSTMT;
			
#line 8944 "flat_modelica_tree_parser.cpp"
	interactive_stmt_AST = RefMyAST(currentAST.root);
	returnAST = interactive_stmt_AST;
	_retTree = _t;
	return ast;
}

void flat_modelica_tree_parser::initializeASTFactory( ANTLR_USE_NAMESPACE(antlr)ASTFactory& factory )
{
	factory.setMaxNodeType(159);
}
const char* flat_modelica_tree_parser::tokenNames[] = {
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
	"\"when\"",
	"\"while\"",
	"\"within\"",
	"\"abstype\"",
	"\"as\"",
	"\"axiom\"",
	"\"datatype\"",
	"\"fail\"",
	"\"let\"",
	"\"interface\"",
	"\"module\"",
	"\"of\"",
	"\"relation\"",
	"\"rule\"",
	"\"val\"",
	"\"_\"",
	"\"with\"",
	"\"withtype\"",
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
	"YIELDS",
	"AMPERSAND",
	"PIPEBAR",
	"COLONCOLON",
	"DASHES",
	"WS",
	"ML_COMMENT",
	"ML_COMMENT_CHAR",
	"SL_COMMENT",
	"an identifier",
	"a type identifier",
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
	"BEGIN_DEFINITION",
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
	"COMPONENT_DEFINITION",
	"DECLARATION",
	"DEFINITION",
	"END_DEFINITION",
	"ENUMERATION_LITERAL",
	"ELEMENT",
	"ELEMENT_MODIFICATION",
	"ELEMENT_REDECLARATION",
	"EQUATION_STATEMENT",
	"INITIAL_EQUATION",
	"INITIAL_ALGORITHM",
	"IMPORT_DEFINITION",
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
	"UNQUALIFIED",
	"INTERACTIVE_STMT",
	"INTERACTIVE_ALG",
	"INTERACTIVE_EXP",
	"EXTERNAL_ANNOTATION",
	0
};

const unsigned long flat_modelica_tree_parser::_tokenSet_0_data_[] = { 1048592UL, 24576UL, 0UL, 0UL, 1536UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "algorithm" "equation" "protected" "public" INITIAL_EQUATION INITIAL_ALGORITHM 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_tree_parser::_tokenSet_0(_tokenSet_0_data_,12);
const unsigned long flat_modelica_tree_parser::_tokenSet_1_data_[] = { 553910304UL, 5243168UL, 3216910848UL, 2130756096UL, 107151360UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "not" "or" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT COLON POWER IDENT UNSIGNED_INTEGER STRING CODE_EXPRESSION CODE_MODIFICATION 
// CODE_ELEMENT CODE_EQUATION CODE_INITIALEQUATION CODE_ALGORITHM CODE_INITIALALGORITHM 
// FUNCTION_CALL INITIAL_FUNCTION_CALL RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_tree_parser::_tokenSet_1(_tokenSet_1_data_,12);
const unsigned long flat_modelica_tree_parser::_tokenSet_2_data_[] = { 553910304UL, 5243168UL, 2680039936UL, 2130756096UL, 107151360UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL };
// "and" "end" "false" "if" "not" "or" "true" "unsigned_real" LPAR LBRACK 
// LBRACE PLUS MINUS STAR SLASH DOT LESS LESSEQ GREATER GREATEREQ EQEQ 
// LESSGT POWER IDENT UNSIGNED_INTEGER STRING CODE_EXPRESSION CODE_MODIFICATION 
// CODE_ELEMENT CODE_EQUATION CODE_INITIALEQUATION CODE_ALGORITHM CODE_INITIALALGORITHM 
// FUNCTION_CALL INITIAL_FUNCTION_CALL RANGE2 RANGE3 UNARY_MINUS UNARY_PLUS 
const ANTLR_USE_NAMESPACE(antlr)BitSet flat_modelica_tree_parser::_tokenSet_2(_tokenSet_2_data_,12);


