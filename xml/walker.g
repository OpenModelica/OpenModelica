header "pre_include_hpp"
{
// adrpo disabling warnings
#pragma warning( disable : 4267)  // Disable warning messages C4267 
// disable: 'initializing' : conversion from 'size_t' to 'int', possible loss of data

#pragma warning( disable : 4231)  // Disable warning messages C4231 
// disable: nonstandard extension used : 'extern' before template explicit instantiation

#pragma warning( disable : 4101)  // Disable warning messages C4101 
// disable: warning C4101: 'pe' : unreferenced local variable
}

header "post_include_hpp" 
{
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

} 

header "post_include_cpp"
{
} 


options 
{
    language = "Cpp";
}


class modelica_tree_parser extends TreeParser;

options 
{
    importVocab = modelica_parser;
    k = 2;
    buildAST = true;
    defaultErrorHandler = false;
}

tokens 
{
    INTERACTIVE_STMT;
	INTERACTIVE_ALG;
	INTERACTIVE_EXP;
}
{

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
}


/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##modelicaxml
*/
stored_definition [mstring filename] returns [DOMNode *ast]
{
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

}
    :
        #(STORED_DEFINITION      
            ( within = within_clause )?
            ((f:FINAL )? 
                class_def = class_definition[f != NULL] 
                {
                    if (class_def)
                    {   
                        el_stack.push(class_def);
                    }
                }
            )*
        )
        {
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
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##modelicaxml
*/
within_clause returns [DOMNode* ast]
{
	DOMNode* pNamePath = 0;
}
    : #(WITHIN (pNamePath = name_path)?)	
        {
			DOMElement* pWithinElement = pModelicaXMLDoc->createElement(X("within"));
		    if (pNamePath) pWithinElement->appendChild(pNamePath);
			ast = pWithinElement;
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##definition
*/
class_definition [bool final] returns [DOMNode* ast ]
{
    DOMElement* definitionElement = 0;
    class_specifier_t sClassSpec;
}
    :
        #(CLASS_DEFINITION 
            (e:ENCAPSULATED )? 
            (p:PARTIAL )?
			(r:class_restriction)
            i:IDENT 	
            class_specifier[sClassSpec]
        )
        {   
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
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##definition
see restriction
*/
class_restriction /* returns [DOMNode* ast] */
    :
        ( CLASS     /*{ ast = Absyn__R_5fCLASS; }*/
        | MODEL     /*{ ast = Absyn__R_5fMODEL; }*/
        | RECORD    /*{ ast = Absyn__R_5fRECORD; }*/
        | BLOCK     /*{ ast = Absyn__R_5fBLOCK; }*/
        | CONNECTOR /*{ ast = Absyn__R_5fCONNECTOR; }*/
        | TYPE      /*{ ast = Absyn__R_5fTYPE; }*/
        | PACKAGE   /*{ ast = Absyn__R_5fPACKAGE; }*/
        | FUNCTION  /*{ ast = Absyn__R_5fFUNCTION; }*/
        )
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##class_specifier
*/
/* ([comment] + composition | derived | enumeration | overloading)*/
class_specifier [class_specifier_t& sClassSpec]
{
	DOMNode *comp = 0;
	DOMNode *cmt = 0;
	DOMNode *d = 0;
	DOMNode *e = 0;
	DOMNode *o = 0;
}
	:
	( (cmt = string_comment)
			comp = composition		
			{
                if (cmt) sClassSpec.string_comment = cmt;
				sClassSpec.composition = comp;
				/* ast = Absyn__PARTS(comp,cmt ? mk_some(cmt) : mk_none()); */
			}
		)
	| #(EQUALS 
	     (
		   d = derived_class | 
		   e = enumeration | 
		   o = overloading)) 
		{
			sClassSpec.derived = d;
			sClassSpec.enumeration = e;
			sClassSpec.overload = o;
		}

	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##derived
*/
derived_class returns [DOMNode* ast]
{
	DOMNode* p = 0;
	DOMNode* as = 0;
	DOMNode* cmod = 0;
  	DOMNode* cmt = 0;
	DOMNode* attr = 0;
	type_prefix_t pfx;
}
	:
		(   type_prefix[pfx]
			p = name_path 
			( as = array_subscripts )? 
			( cmod = class_modification )? 
			(cmt = comment)?
			{
				DOMElement* pDerived = pModelicaXMLDoc->createElement(X("derived"));
				if (p)               pDerived->appendChild(p);
				if (as)              pDerived->appendChild(as); 
				if (cmod)            pDerived->appendChild(cmod);
				if (pfx.flow)        pDerived->appendChild(pfx.flow);
				if (pfx.variability) pDerived->appendChild(pfx.variability);
				if (pfx.direction)   pDerived->appendChild(pfx.direction);
				if (cmt)             pDerived->appendChild(cmt);
				ast = pDerived;
			}
		)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##enumeration
*/
enumeration returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* el = 0;
	DOMNode* cmt = 0;
}
    : 
		#(ENUMERATION 
			el = enumeration_literal
			{ el_stack.push(el); }
			(
				el = enumeration_literal
				{ el_stack.push(el); }
				
			)* 
			(cmt=comment)?
		)
		{
			DOMElement* pEnumeration = pModelicaXMLDoc->createElement(X("enumeration"));
			pEnumeration = (DOMElement*)appendKids(el_stack, pEnumeration);
			if (cmt) pEnumeration->appendChild(cmt);
			ast = pEnumeration;
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##enumeration_literal
*/

enumeration_literal returns [DOMNode* ast] :
{
   DOMNode* c1=0;
}
		#(ENUMERATION_LITERAL i1:IDENT (c1=comment)?) 
		{
			DOMElement* pEnumerationLiteral = pModelicaXMLDoc->createElement(X("enumeration_literal"));
			pEnumerationLiteral->setAttribute(X("ident"), str2xml(i1));
			if (c1) pEnumerationLiteral->appendChild(c1);
			ast = pEnumerationLiteral;
		}
	;	

/*
Overloading is used internaly in the OpenModelica.
It shouldn't appear in the normal use of the ModelicaXML.
We leave it here for the future.
*/
overloading returns [DOMNode* ast] 
{
	l_stack el_stack;
	DOMNode* el = 0;
	DOMNode* cmt = 0;
}
	:
		#(OVERLOAD 
			el = name_path
			{ el_stack.push(el); }
			(
				el = name_path
				{ el_stack.push(el); }
				
			)* 
			(cmt=comment)?
		)
		{
			DOMElement* pOverload = pModelicaXMLDoc->createElement(X("overload"));
			pOverload = (DOMElement*)appendKids(el_stack, pOverload);
			if (cmt) pOverload->appendChild(cmt);
			ast = pOverload;
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##elements
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##composition
*/
composition returns [DOMNode* ast]
{
    DOMNode* el = 0;
    l_stack el_stack;
    DOMNode*  ann;	
}
    :
        el = element_list[1 /* public */]
        {
			/* 
			DOMElement* pPublic = pModelicaXMLDoc->createElement(X("public"));
			pPublic->appendChild(el);
			el_stack.push(pPublic);
			*/
            el_stack.push(el);
        }
        (
            (	
                el = public_element_list 
            |	el = protected_element_list 
			|   el = equation_clause
            |	el = algorithm_clause
            )
            {
                el_stack.push(el);
            }
        )*
        (	#(EXTERNAL
				( el = external_function_call)
				( ann = annotation)?
				{ 
					el_stack.push(el); 
				}
			)
		)?
        {
            ast = (DOMElement*)stack2DOMNode(el_stack, "composition");
        }
    ;

public_element_list returns [DOMNode* ast]
{
    DOMNode* el;    
}
    :
        
        #(p:PUBLIC 
            el = element_list[1 /* public */]
        )
        {
			DOMElement* pPublic = pModelicaXMLDoc->createElement(X("public"));
			pPublic->appendChild(el);
			ast = pPublic;
        }
    ;

protected_element_list returns [DOMNode* ast]
{
    DOMNode* el;
}
    :
        
        #(p:PROTECTED
            el = element_list[2 /* protected */]
        )
        {
			DOMElement* pProtected = pModelicaXMLDoc->createElement(X("protected"));
			pProtected->appendChild(el);
			ast = pProtected;
        }
    ;

external_function_call returns [DOMNode* ast]
{
	DOMNode* temp=0;
	DOMNode* temp2=0;
	DOMNode* temp3=0;
	ast = 0;
}
	:
        (s:STRING)?
        (#(EXTERNAL_FUNCTION_CALL 
				(
					(i:IDENT (temp = expression_list)?)
					{
						DOMElement* pExternalFunctionCall = 
							pModelicaXMLDoc->createElement(X("external"));
						if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));  
						if (i != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i));  
						if (temp) pExternalFunctionCall->appendChild(temp);
						ast = pExternalFunctionCall;
					}
				| #(e:EQUALS temp2 = component_reference i2:IDENT ( temp3 = expression_list)?)
					{
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
					}
				)
			))?                            
		{
			if (!ast) 
			{ 
				DOMElement* pExternalFunctionCall = pModelicaXMLDoc->createElement(X("external"));
				if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));  
				ast = pExternalFunctionCall;
			}
        }

    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##elements

  @HACK @FIXME add an enumeration type
  parameter iSwitch:
  1 public element
  2 protected element
*/
element_list[int iSwitch] returns [DOMNode* ast]
{
    DOMNode* e = 0;
    l_stack el_stack;
    DOMNode* ann = 0;
}
    :
        (
            (e = element
                {
                    if (iSwitch == 1) ((DOMElement*)e)->setAttribute(X("visibility"), X("public"));
					else if (iSwitch == 2) ((DOMElement*)e)->setAttribute(X("visibility"), X("protected"));
					else { /* error, shouldn't happen */ } 
                    el_stack.push(e);
                })
        | (ann = annotation 
                {
                    if (iSwitch == 1) ((DOMElement*)ann)->setAttribute(X("visibility"), X("public"));
					else if (iSwitch == 2) ((DOMElement*)ann)->setAttribute(X("visibility"), X("protected"));
					else { /* error, shouldn't happen */ } 
					((DOMElement*)ann)->setAttribute(X("inside"), X("definition"));
                    el_stack.push(ann);
                }
            )              
        )*
        {
            ast = (DOMElement*)stack2DOMNode(el_stack, "element_list");
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##elements
*/
element returns [DOMNode* ast]
{
	DOMNode* class_def = 0;
	DOMNode* e_spec = 0;
	DOMNode* final = 0;
	DOMNode* innerouter = 0;
	DOMNode* constr = 0;
	DOMNode* cmt = 0;
}
	: 
		( e_spec = import_clause
			{
				ast = e_spec;
				/* ast = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,mk_scon("import"),e_spec,mk_none()); */
			}
		| e_spec = extends_clause
			{
				ast = e_spec;
				/* ast = Absyn__ELEMENT(RML_FALSE,RML_FALSE,Absyn__UNSPECIFIED,mk_scon("extends"),e_spec,mk_none()); */
			}
		| #(DECLARATION 
			(   { DOMElement* componentElement = pModelicaXMLDoc->createElement(X("component")); }
					(f:FINAL)? { if (f) componentElement->setAttribute(X("final"), X("true")); }
					(i:INNER | o:OUTER)? 
					  { 
						  if (i) componentElement->setAttribute(X("innerouter"), X("inner")); 
						  if (o) componentElement->setAttribute(X("innerouter"), X("outer")); 
						  /* innerouter = make_inner_outer(i,o); */
					  }
					(e_spec = component_clause
						{
							/* ast = Absyn__ELEMENT(final,RML_FALSE,innerouter,
								mk_scon("component"),e_spec,mk_none()); */
                            componentElement->appendChild(e_spec);
                            /* componentElement->appendChild(innerouter); */
							ast = componentElement;
						}
					| r:REPLACEABLE 
						e_spec = component_clause 
						(constr = constraining_clause cmt=comment)?
						{
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
						}
					)
				)
			)
		| #(DEFINITION
				(   { DOMElement* definitionElement = pModelicaXMLDoc->createElement(X("definition")); }
					(fd:FINAL)? { if (fd) definitionElement->setAttribute(X("final"), X("true")); }
					(id:INNER | od:OUTER)? 
					  { 
						  if (i) definitionElement->setAttribute(X("innerouter"), X("inner")); 
						  if (o) definitionElement->setAttribute(X("innerouter"), X("outer")); 
						  /* innerouter = make_inner_outer(i,o); */
					  }
					(
						class_def = class_definition[fd != NULL] 
						{
							DOMElement* pDefinition = pModelicaXMLDoc->createElement(X("definition"));
							pDefinition->appendChild(class_def);
							/*
							ast = Absyn__CLASSDEF(RML_PRIM_MKBOOL(0),
								class_def);
							ast = Absyn__ELEMENT(final,RML_FALSE,innerouter,mk_scon("??"),ast,mk_none());*/
							definitionElement->appendChild(pDefinition);
							/* componentElement->appendChild(innerouter); */
							ast = definitionElement;
						}
					| 
						(rd:REPLACEABLE 
							class_def = class_definition[fd != NULL] 
							(constr = constraining_clause cmt=comment)?
						)
						{
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
						}
					)
				)
			)
		)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##import
*/
import_clause returns [DOMNode* ast]
{
	DOMNode* imp = 0;
	DOMNode* cmt = 0;
}
	:
		#(i:IMPORT 
			(imp = explicit_import_name
			|imp = implicit_import_name
			) 
			(cmt = comment)?
		)
		{
			DOMElement* pImport = pModelicaXMLDoc->createElement(X("import"));
			pImport->appendChild(imp);
			if (cmt) pImport->appendChild(cmt);
			ast = pImport;
			/* ast = Absyn__IMPORT(imp, cmt ? mk_some(cmt) : mk_none()); */
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##import
*/
explicit_import_name returns [DOMNode* ast]
{
	DOMNode* path;
}
	:
		#(EQUALS i:IDENT path = name_path)	
		{
			DOMElement* pExplicitImport = pModelicaXMLDoc->createElement(X("named_import"));
			pExplicitImport->setAttribute(X("ident"), str2xml(i));
			pExplicitImport->appendChild(path);
			ast = pExplicitImport;
			/* ast = Absyn__NAMED_5fIMPORT(id,path); */
		}
	;
/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##import
*/
implicit_import_name returns [DOMNode* ast]
{
	DOMNode* path;
}
	:
		(#(UNQUALIFIED path = name_path)
			{
				DOMElement* pUnqImport = pModelicaXMLDoc->createElement(X("unqualified_import"));
				pUnqImport->appendChild(path);
				ast = pUnqImport;
				/* ast = Absyn__UNQUAL_5fIMPORT(path); */
			}
		|#(QUALIFIED path = name_path)
			{
				DOMElement* pQuaImport = pModelicaXMLDoc->createElement(X("qualified_import"));
				pQuaImport->appendChild(path);
				ast = pQuaImport;
				/* ast = Absyn__QUAL_5fIMPORT(path); */
			}
		)
	;


/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##extends
*/
extends_clause returns [DOMNode* ast]
{
	DOMNode* path;
	DOMNode* mod = 0;
}
	: 
		(#(e:EXTENDS 
				path = name_path 
				(mod = class_modification)? 
			)
			{
				DOMElement* pExtends = pModelicaXMLDoc->createElement(X("extends"));
				if (mod) pExtends->appendChild(mod);
				pExtends->appendChild(path);
				ast = pExtends;
				/* ast = Absyn__EXTENDS(path,mod); */
			}
		)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##constrain
*/
constraining_clause returns [DOMNode* ast] :
		(ast = extends_clause)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##component
*/
component_clause returns [DOMNode* ast]
{
	type_prefix_t pfx;
	DOMNode* attr = 0;
	DOMNode* path = 0;
	DOMNode* arr = 0;
	DOMNode* comp_list = 0;
}
	:
		type_prefix[pfx] 
		path = type_specifier 
		(arr = array_subscripts)? 
		comp_list = component_list
		{
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
		}
	;

type_prefix [type_prefix_t& prefix]
	:
		(f:FLOW)?
		(d:DISCRETE 
		|p:PARAMETER
		|c:CONSTANT
		)?
		(i:INPUT 
		|o:OUTPUT 
		)?
		{
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
		}
	;

// returns datatype Path
type_specifier returns [DOMNode* ast]
	:
		ast = name_path;


// returns datatype Component list
component_list returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e=0;
}
	:
		e = component_declaration { el_stack.push(e); }
		(e = component_declaration { el_stack.push(e); } )*
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "component_list");
		}
	;


// returns datatype Component
component_declaration returns [DOMNode* ast]
{
	DOMNode* cmt = 0;
	DOMNode* dec = 0;

}
	:
		(dec = declaration) (cmt = comment)?
		{
			DOMElement *pComponentItem = pModelicaXMLDoc->createElement(X("component_item"));
			pComponentItem->appendChild(dec);
			if (cmt) pComponentItem->appendChild(cmt);
			ast = pComponentItem;
			/* ast = Absyn__COMPONENTITEM(dec,cmt ? mk_some(cmt) : mk_none()); */
		}
	;


// returns datatype Component
declaration returns [DOMNode* ast]
{
	DOMNode* arr = 0;
	DOMNode* mod = 0;
	DOMNode* id = 0;
}
	:
		#(i:IDENT (arr = array_subscripts)? (mod = modification)?)
		{
			DOMElement *pComponent = pModelicaXMLDoc->createElement(X("component"));
			pComponent->setAttribute(X("ident"), str2xml(i));
			if (arr) pComponent->appendChild(arr);
			if (mod) pComponent->appendChild(mod);
			ast = pComponent;
			/* ast = Absyn__COMPONENT(id, arr, mod ? mk_some(mod) : mk_none()); */
		}
	;

modification returns [DOMNode* ast] 
{
	DOMNode* e = 0;
	DOMNode* cm = 0;
	int iswitch = 0;
}
	:
		( cm = class_modification ( e = expression )?
		|#(EQUALS e = expression) { iswitch = 1; }
		|#(ASSIGN e = expression) { iswitch = 2; }
		)
		{
			DOMElement *pModificationEQorASorARG = null;
			if (iswitch == 1) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_equals"));
			if (iswitch == 2) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_assign"));
			if (iswitch == 0) pModificationEQorASorARG = pModelicaXMLDoc->createElement(X("modification_arguments"));
			if (e) pModificationEQorASorARG->appendChild(e);
			if (cm) pModificationEQorASorARG->appendChild(cm);
			ast = pModificationEQorASorARG;
			/* ast = Absyn__CLASSMOD(cm, e); */
		}
	;

class_modification returns [DOMNode* ast]
{
	ast = 0;
}
	:
		#(CLASS_MODIFICATION (ast = argument_list)?)
		{
			/* if (!ast) ast = mk_nil(); */
		}
	;

argument_list returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
}
	:
		#(ARGUMENT_LIST 
			e = argument { el_stack.push(e); }
			(e = argument { el_stack.push(e); } )*
		)
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "argument_list");
		}
	;

argument returns [DOMNode* ast]
	:
		#(ELEMENT_MODIFICATION ast = element_modification)
	|
		#(ELEMENT_REDECLARATION ast = element_redeclaration) 
	;

element_modification returns [DOMNode* ast]
{
	DOMNode* cref;
	DOMNode* mod=0;
	DOMNode* cmt=0;
}
	:
		(e:EACH)?
		(f:FINAL)? 
		cref = component_reference 
		(mod = modification)?
		cmt = string_comment
		{

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
		}
	;

element_redeclaration returns [DOMNode* ast]
{
	DOMNode* class_def = 0;
	DOMNode* e_spec = 0; 
	DOMNode* constr = 0;
	DOMNode* final = 0;
	DOMNode* each = 0;
}
	:
		(#(r:REDECLARE (e:EACH)? (f:FINAL)?
                (	
					(class_def = class_definition[false] 
						{
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
						}
					| e_spec = component_clause1
						{
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
						}
					)
				|
					( re:REPLACEABLE 
						(class_def = class_definition[false]                            
						| e_spec = component_clause1
						)
						(constr = constraining_clause)?
						{	
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
						}
					)
				)
			)
		)
	;

component_clause1 returns [DOMNode* ast]
{
	type_prefix_t pfx;
	DOMNode* attr = 0;
	DOMNode* path = 0;
	DOMNode* arr = 0;
	DOMNode* comp_decl = 0;
	DOMNode* comp_list = 0;
}
	:
		type_prefix[pfx]
		path = type_specifier 
		comp_decl = component_declaration
		{
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
		}
	;

// Return datatype ClassPart
equation_clause returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e = 0;
	DOMNode* ann = 0;
} 
	:
		#(EQUATION
			(
				(
				   e = equation { el_stack.push(e); }
				| ann = annotation 
				  { 
				    DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
					pAnnotation->setAttribute(X("inside"), X("equation"));
					pAnnotation->appendChild(ann);
					el_stack.push(pAnnotation /* Absyn__EQUATIONITEMANN(ann) */);
				  } 
				)*
				
			)
		)
		{
			DOMElement*  pEquations = pModelicaXMLDoc->createElement(X("equations"));
			pEquations = (DOMElement*)appendKids(el_stack, pEquations);
			ast = pEquations;
			/* ast = Absyn__EQUATIONS((DOMElement*)stack2DOMNode(el_stack)); */
		}
	|
		#(INITIAL_EQUATION
			#(EQUATION
				(
				  e = equation { el_stack.push(e); }
				| ann = annotation 
				  { 
				    DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
					pAnnotation->setAttribute(X("inside"), X("equation"));
					pAnnotation->appendChild(ann);
					el_stack.push(pAnnotation /* Absyn__EQUATIONITEMANN(ann) */);
				  } 
				)*
			)
			{
				DOMElement*  pEquations = pModelicaXMLDoc->createElement(X("equations"));
				pEquations->setAttribute(X("initial"), X("true"));
				pEquations = (DOMElement*)appendKids(el_stack, pEquations);
				ast = pEquations;
				/* ast = Absyn__INITIALEQUATIONS((DOMElement*)stack2DOMNode(el_stack)); */
			}
		)
	;	

algorithm_clause returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
	DOMNode* ann;
}
	:
		#(ALGORITHM 
			(e = algorithm { el_stack.push(e); }
			| ann = annotation 
			{ 
				DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
				pAnnotation->setAttribute(X("inside"), X("algorithm"));
				pAnnotation->appendChild(ann);
				el_stack.push(pAnnotation /* Absyn__ALGORITHMITEMANN(ann) */);
			} 
			)*
		)
		{
			DOMElement*  pAlgorithms = pModelicaXMLDoc->createElement(X("algorithms"));
			pAlgorithms = (DOMElement*)appendKids(el_stack, pAlgorithms);
			ast = pAlgorithms;
			/* ast = Absyn__ALGORITHMS((DOMElement*)stack2DOMNode(el_stack)); */
		}
	|
		#(INITIAL_ALGORITHM
			#(ALGORITHM 
				(e = algorithm { el_stack.push(e); }
				| ann = annotation 
				{ 				
					DOMElement*  pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
					pAnnotation->setAttribute(X("inside"), X("algorithm"));
					pAnnotation->appendChild(ann);
					el_stack.push(pAnnotation /* Absyn__ALGORITHMITEMANN(ann) */);
                }
				)*
			)
			{
				DOMElement*  pAlgorithms = pModelicaXMLDoc->createElement(X("algorithms"));
				pAlgorithms->setAttribute(X("initial"), X("true"));
				pAlgorithms = (DOMElement*)appendKids(el_stack, pAlgorithms);
				ast = pAlgorithms;
				/* ast = Absyn__INITIALALGORITHMS((DOMElement*)stack2DOMNode(el_stack)); */
			}
		)
	;

equation returns [DOMNode* ast] 
{
	DOMNode* cmt = 0;
}
	:
		#(EQUATION_STATEMENT
			(  ast = equality_equation
			|  ast = conditional_equation_e
			|  ast = for_clause_e
			|  ast = when_clause_e
			|  ast = connect_clause
			|  ast = equation_funcall	
			)
			(cmt = comment)?
			{
				DOMElement*  pEquation = pModelicaXMLDoc->createElement(X("equation"));
				pEquation->appendChild(ast);
				if (cmt) pEquation->appendChild(cmt);
				ast = pEquation;
				/* ast = Absyn__EQUATIONITEM(ast,cmt ? mk_some(cmt) : mk_none()); */
			}
		)
	;

equation_funcall returns [DOMNode* ast]
{
  DOMNode* fcall = 0;
}
	:
		i:IDENT fcall = function_call 
		{ 
			 DOMElement*  pEquCall = pModelicaXMLDoc->createElement(X("equ_call"));
			 pEquCall->setAttribute(X("ident"), str2xml(i));
			 pEquCall->appendChild(fcall);
			 ast = pEquCall;			
			/* ast = Absyn__EQ_5fNORETCALL(str2xml(i),fcall);  */
		}
	;

algorithm returns [DOMNode* ast]
{
	DOMNode* cref;
	DOMNode* expr;
	DOMNode* tuple;
	DOMNode* args;
  	DOMNode* cmt=0;
}
	:
		#(ALGORITHM_STATEMENT 
			(#(ASSIGN 
					(cref = component_reference expr = expression
						{
							DOMElement*  pAlgAssign = pModelicaXMLDoc->createElement(X("alg_assign"));
							pAlgAssign->appendChild(cref);
							pAlgAssign->appendChild(expr);
							ast = pAlgAssign;
							/* ast = Absyn__ALG_5fASSIGN(cref,expr); */
						}
					|	(tuple = expression_list cref = component_reference args = function_call)
						{
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
						}
					)
				)
			| ast = algorithm_function_call
			| ast = conditional_equation_a
			| ast = for_clause_a
			| ast = while_clause
			| ast = when_clause_a
			)
			(cmt = comment)?
	  		{	
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
	  		}
		)
	;

algorithm_function_call returns [DOMNode* ast]
{
	DOMNode* cref;
	DOMNode* args;
}
	:
		cref = component_reference args = function_call
		{
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
		}
	;

equality_equation returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
}
	:
		#(EQUALS e1 = simple_expression e2 = expression)
		{
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
		}
	;

conditional_equation_e returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* then_b;
	DOMNode* else_b = 0;
	DOMNode* else_if_b;
	l_stack el_stack;
	DOMNode* e;
}
	:
		#(IF
			e1 = expression
			then_b = equation_list
			( e = equation_elseif { el_stack.push(e); } )*
			(ELSE else_b = equation_list)?
		)
		{
			/* else_if_b = (DOMElement*)stack2DOMNode(el_stack, else_if_b); */
			DOMElement*  pEquIf = pModelicaXMLDoc->createElement(X("equ_if"));
			pEquIf->appendChild(e1);
			pEquIf->appendChild(then_b);
			if (el_stack.size()>0) pEquIf = (DOMElement*)appendKids(el_stack, pEquIf); // ?? is this ok?
			if (else_b)    pEquIf->appendChild(else_b);
			ast = pEquIf;
			/* ast = Absyn__EQ_5fIF(e1, then_b, else_if_b, else_b); */
		}
	;

conditional_equation_a returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* then_b;
	DOMNode* else_b = 0;
	DOMNode* else_if_b;
	l_stack el_stack;
	DOMNode* e;
}
	:
		#(IF
			e1 = expression
			then_b = algorithm_list
			( e = algorithm_elseif { el_stack.push(e); } )*
			( ELSE else_b = algorithm_list)?
		)
		{
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
		}
	;

for_clause_e returns [DOMNode* ast] 
{
	DOMNode* f;
	DOMNode* eq;
}
	:
		#(FOR f=for_indices	eq=equation_list)
		{
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
		}
	;


for_clause_a returns [DOMNode* ast]
{
	DOMNode* f;
	DOMNode* eq;
}
	:
		#(FOR f=for_indices eq=algorithm_list)
		{
			DOMElement*  pEquFor = pModelicaXMLDoc->createElement(X("alg_for"));
			pEquFor->appendChild(f);
			pEquFor->appendChild(eq);
			ast = pEquFor;
			/*
			id = str2xml(i);
			ast = Absyn__ALG_5fFOR(id,e,eq);
			*/
		}
	;



for_indices returns [DOMNode* ast]
{
	DOMNode* f;
	DOMNode* e;
	l_stack el_stack;
}
:
    (#(IN i:IDENT (e=expression)?)
	{ 
		DOMElement* pForIndex = pModelicaXMLDoc->createElement(X("for_index"));
		pForIndex->setAttribute(X("ident"), str2xml(i));
		if (e) pForIndex->appendChild(e);
		el_stack.push(pForIndex); 
	} 
	)*
	{
		DOMElement*  pForIndices = pModelicaXMLDoc->createElement(X("for_indices"));
		pForIndices = (DOMElement*)appendKids(el_stack, pForIndices);
		ast = pForIndices;
	}
;

while_clause returns [DOMNode* ast]
{
	DOMNode* e;
	DOMNode* body;
}
	:
		#(WHILE 
			e = expression 
			body = algorithm_list)
		{
			DOMElement* pAlgWhile = pModelicaXMLDoc->createElement(X("alg_while"));
			pAlgWhile->appendChild(e);
			pAlgWhile->appendChild(body);
			ast = pAlgWhile;
			/*
			ast = Absyn__ALG_5fWHILE(e,body);
			*/
		}
	;

when_clause_e returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
	DOMNode* body;
	DOMNode* el = 0;
}
	:
		#(WHEN 
			e = expression
			body = equation_list
	  		(el = else_when_e { el_stack.push(el); } )*
		)
		{
			DOMElement* pEquWhen = pModelicaXMLDoc->createElement(X("equ_when"));
			pEquWhen->appendChild(e);
			DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
			pEquThen->appendChild(body);
			pEquWhen->appendChild(pEquThen);
			pEquWhen = (DOMElement*)appendKids(el_stack, pEquWhen); // ??is this ok?
			ast = pEquWhen;
			/* ast = Absyn__EQ_5fWHEN_5fE(e,body,(DOMElement*)stack2DOMNode(el_stack)); */
		}
	;

else_when_e returns [DOMNode* ast]
{ 
	DOMNode*  expr;
	DOMNode*  eqn;
}
	:
		#(e:ELSEWHEN expr = expression  eqn = equation_list)
		{
			DOMElement* pEquElseWhen = pModelicaXMLDoc->createElement(X("equ_elsewhen"));
			pEquElseWhen->appendChild(expr);
			DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
			pEquThen->appendChild(eqn);
			pEquElseWhen->appendChild(pEquThen);
			ast = pEquElseWhen;
			/*
			ast = mk_box2(0,expr,eqn);
			*/
		}
	;

when_clause_a returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
	DOMNode* body;
	DOMNode* el = 0;
}
	:
		#(WHEN 
			e = expression
			body = algorithm_list 
			(el = else_when_a {el_stack.push(el); })* 
		)
		{
			DOMElement* pAlgWhen = pModelicaXMLDoc->createElement(X("alg_when"));
			pAlgWhen->appendChild(e);
			DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
			pAlgThen->appendChild(body);
			pAlgWhen->appendChild(pAlgThen);
			pAlgWhen = (DOMElement*)appendKids(el_stack, pAlgWhen);
			ast = pAlgWhen;
			/* ast = Absyn__ALG_5fWHEN_5fA(e,body,(DOMElement*)stack2DOMNode(el_stack)); */
		}
	;

else_when_a returns [DOMNode* ast]
{ 
	DOMNode*  expr;
	DOMNode*  alg;
}
	:
		#(e:ELSEWHEN expr = expression  alg = algorithm_list)
		{
			DOMElement* pAlgElseWhen = pModelicaXMLDoc->createElement(X("alg_else_when"));
			pAlgElseWhen->appendChild(expr);
			DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
			pAlgThen->appendChild(alg);
			pAlgElseWhen->appendChild(pAlgThen);
			ast = pAlgElseWhen;
			/* ast = mk_box2(0,expr,alg); */
		}
	;

equation_elseif returns [DOMNode* ast]
{
	DOMNode* e;
	DOMNode* eq;
}
	:
		#(ELSEIF 
			e = expression 
			eq = equation_list
		)
		{
			DOMElement* pEquElseIf = pModelicaXMLDoc->createElement(X("equ_else_if"));
			pEquElseIf->appendChild(e);
			DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
			pEquThen->appendChild(eq);
			pEquElseIf->appendChild(pEquThen);
			ast = pEquElseIf;
			/* ast = mk_box2(0,e,eq); */
		}
	;

algorithm_elseif returns [DOMNode* ast]
{
	DOMNode* e;
	DOMNode* body;
}
	:
		#(ELSEIF 
			e = expression
			body = algorithm_list
		)
		{
			DOMElement* pAlgElseIf = pModelicaXMLDoc->createElement(X("alg_else_if"));
			pAlgElseIf->appendChild(e);
			DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
			pAlgThen->appendChild(body);
			pAlgElseIf->appendChild(pAlgThen);
			ast = pAlgElseIf;
			/* ast = mk_box2(0,e,body); */
		}
	;

equation_list returns [DOMNode* ast]
{
	DOMNode* e;
	l_stack el_stack;
}
	:
		(e = equation { el_stack.push(e); })*
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "equation_list");
		}
	;

algorithm_list returns [DOMNode* ast]
{
	DOMNode* e;
	l_stack el_stack;
}
	:
		(e = algorithm { el_stack.push(e); } )*
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "algorithm_list");
		}
	;

connect_clause returns [DOMNode* ast]
{
	DOMNode* r1;
	DOMNode* r2;
}
	:
		#(CONNECT 
			r1 = component_reference
			r2 = component_reference
		)
		{
			DOMElement* pEquConnect = pModelicaXMLDoc->createElement(X("equ_connect"));
			pEquConnect->appendChild(r1);
			pEquConnect->appendChild(r2);
			ast = pEquConnect;
			/* ast = Absyn__EQ_5fCONNECT(r1,r2); */
		}
	;

/*
connector_ref returns [DOMNode* ast]
{
	DOMNode* as = 0;
	DOMNode* id = 0;
}
	:
		(#(i:IDENT (as = array_subscripts)? )
			{
				if (!as) as = mk_nil();
				id = str2xml(i);
				ast = Absyn__CREF_5fIDENT(id,as);
			}
		|#(DOT #(i2:IDENT (as = array_subscripts)?) 
				ast = connector_ref_2)
			{
				if (!as) as = mk_nil();
				id = str2xml(i2);
				ast = Absyn__CREF_5fQUAL(id,as,ast);
			}
		)
	;

connector_ref_2 returns [DOMNode* ast]
{
	DOMNode* as = 0;
	DOMNode* id;
}
	:
		#(i:IDENT (as = array_subscripts)? )
		{
			if (!as) as = mk_nil();
			id = str2xml(i);
			ast = Absyn__CREF_5fIDENT(id,as);
		}
	;

*/

expression returns [DOMNode* ast]
	:
		(	ast = simple_expression
		|	ast = if_expression
		|   ast = code_expression
		)
	;

// ?? what the hack is this?
code_expression returns [DOMNode* ast]
	:
		#(CODE_MODIFICATION (ast = modification) )
		{
			// ?? what the hack is this?
			DOMElement* pModification = pModelicaXMLDoc->createElement(X("modification"));
			pModification->appendChild(ast);
			ast = pModification;
			/*
			ast = Absyn__CODE(Absyn__C_5fMODIFICATION(ast));
			*/
		}

	|	#(CODE_EXPRESSION (ast = expression) )
		{
			// ?? what the hack is this?
			DOMElement* pExpression = pModelicaXMLDoc->createElement(X("expression"));
			pExpression->appendChild(ast);
			ast = pExpression;
			/* ast = Absyn__CODE(Absyn__C_5fEXPRESSION(ast)); */
		}

	|	#(CODE_ELEMENT (ast = element) )
		{
			// ?? what the hack is this?
			DOMElement* pElement = pModelicaXMLDoc->createElement(X("element"));
			pElement->appendChild(ast);
			ast = pElement;
			/* ast = Absyn__CODE(Absyn__C_5fELEMENT(ast)); */
		}
		
	|	#(CODE_EQUATION (ast = equation_clause) )
		{
			// ?? what the hack is this?
			DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
			pEquationSection->appendChild(ast);
			ast = pEquationSection; 
			/* ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_FALSE, 
					RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1)))); */
		}
		
	|	#(CODE_INITIALEQUATION (ast = equation_clause) )
		{
			// ?? what the hack is this?
			DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
			((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
			pEquationSection->appendChild(ast);
			ast = pEquationSection; 
			/*
			ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_TRUE, 
					RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
			*/
		}
	|	#(CODE_ALGORITHM (ast = algorithm_clause) )
		{
			// ?? what the hack is this?
			DOMElement* pAlgorithmSection = pModelicaXMLDoc->createElement(X("algorithm_section"));
			pAlgorithmSection->appendChild(ast);
			ast = pAlgorithmSection; 
			/*
			ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_FALSE, 
					RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
			*/
		}
	|	#(CODE_INITIALALGORITHM (ast = algorithm_clause) )
		{
			// ?? what the hack is this?
			DOMElement* pAlgorithmSection = pModelicaXMLDoc->createElement(X("algorithm_section"));
			((DOMElement*)ast)->setAttribute(X("initial"), X("true"));
			pAlgorithmSection->appendChild(ast);
			ast = pAlgorithmSection; 
			/*
			ast = Absyn__CODE(Absyn__C_5fALGORITHMSECTION(RML_TRUE, 
					RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1))));
			*/
		}
	;

if_expression returns [DOMNode* ast]
{
	DOMNode* cond;
	DOMNode* thenPart;
	DOMNode* elsePart;
	DOMNode* e;
	DOMNode* elseifPart;
	l_stack el_stack;
}
	:
		#(IF cond = expression
			thenPart = expression (e=elseif_expression {el_stack.push(e);} )* elsePart = expression
			{
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
			}
		)
	;

elseif_expression returns [DOMNode* ast]
{
	DOMNode* cond;
	DOMNode* thenPart;
}
	:
		#(ELSEIF cond = expression thenPart = expression
		{
			DOMElement* pElseIf = pModelicaXMLDoc->createElement(X("elseif"));
			pElseIf->appendChild(cond);
			DOMElement* pThen = pModelicaXMLDoc->createElement(X("then"));
			pThen->appendChild(thenPart);
			pElseIf->appendChild(pThen);
			ast = pElseIf;
			/*	ast = mk_box2(0,cond,thenPart); */
		}
	  )
	;

simple_expression returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
	DOMNode* e3;
}
	:
		(#(RANGE3 e1 = logical_expression 
				e2 = logical_expression 
				e3 = logical_expression)
			{
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
			}
		|#(RANGE2 e1 = logical_expression e3 = logical_expression)
			{
				DOMElement* pRange = pModelicaXMLDoc->createElement(X("range"));
				pRange->appendChild(e1);
				pRange->appendChild(e3);
				ast = pRange;
				/* ast = Absyn__RANGE(e1,mk_none(),e3); */
			}
		| ast = logical_expression
		)
	;

logical_expression returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
}
	: 
		(ast = logical_term
		| #(OR e1 = logical_expression e2 = logical_term)
			{
				DOMElement* pOr = pModelicaXMLDoc->createElement(X("or"));
				pOr->appendChild(e1);
				pOr->appendChild(e2);
				ast = pOr;
				/* ast = Absyn__LBINARY(e1,Absyn__OR, e2); */
			}
		)

	;

logical_term returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
}
	:
		(ast = logical_factor
		| #(AND e1 = logical_term e2 = logical_factor)
			{
				DOMElement* pAnd = pModelicaXMLDoc->createElement(X("and"));
				pAnd->appendChild(e1);
				pAnd->appendChild(e2);
				ast = pAnd;
				/* ast = Absyn__LBINARY(e1,Absyn__AND,e2); */
			}
		)
	;

logical_factor returns [DOMNode* ast]
	:
	#(NOT ast = relation 
      { 
		DOMElement* pNot = pModelicaXMLDoc->createElement(X("not"));
		pNot->appendChild(ast);
		ast = pNot;
		/* ast = Absyn__LUNARY(Absyn__NOT,ast); */
	  })
	| ast = relation;

relation returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* op = 0;
	DOMNode* e2 = 0;
}
     :   
		( ast = arithmetic_expression
		| 
			( #(LESS e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("lt")); /* Absyn__LESS; */ }                    
			| #(LESSEQ e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("lte")); /* Absyn__LESSEQ; */ }                    
			| #(GREATER e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("gt")); /* Absyn__GREATER; */ }                    
			| #(GREATEREQ e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("gte")); /* Absyn__GREATEREQ; */ }                    
			| #(EQEQ e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("eq")); /* Absyn__EQUAL; */ }                    
			| #(LESSGT e1=arithmetic_expression e2=arithmetic_expression )
				{ op = pModelicaXMLDoc->createElement(X("ne")); /* op = Absyn__NEQUAL; */ }                    
			)
			{
				((DOMElement*)op)->appendChild(e1);
				((DOMElement*)op)->appendChild(e2);
				ast = op;
				/* ast = Absyn__RELATION(e1,op,e2); */
			}
		)
	;

/*
rel_op returns [DOMNode *]
	:
		( LESS { ast = Absyn__LESS; }
		| LESSEQ { ast = Absyn__LESSEQ; }
		| GREATER { ast = Absyn__GREATER; }
		| GREATEREQ { ast = Absyn__GREATEREQ; }
		| EQEQ { ast = Absyn__EQUAL; }
		| LESSGT { ast = Absyn__NEQUAL; }
		)
	;
*/

arithmetic_expression returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
}
	:
		(ast = unary_arithmetic_expression
		|#(PLUS e1 = arithmetic_expression e2 = term)
			{
				DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));
				pAdd->setAttribute(X("operation"), X("binary"));
				pAdd->appendChild(e1);
				pAdd->appendChild(e2);
				ast = pAdd;
				/* ast = Absyn__BINARY(e1,Absyn__ADD,e2); */
			}
		|#(MINUS e1 = arithmetic_expression e2 = term)
			{
				DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
				pSub->setAttribute(X("operation"), X("binary"));
				pSub->appendChild(e1);
				pSub->appendChild(e2);
				ast = pSub;
				/* ast = Absyn__BINARY(e1,Absyn__SUB,e2); */
			}
		)
	;

unary_arithmetic_expression returns [DOMNode* ast]
	:
		(#(UNARY_PLUS ast = term) 
		{
			DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));
			pAdd->setAttribute(X("operation"), X("unary"));
			pAdd->appendChild(ast);
			ast = pAdd;
			/* ast = Absyn__UNARY(Absyn__UPLUS,ast); */
		}
		|#(UNARY_MINUS ast = term) 
		{ 
			DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
			pSub->setAttribute(X("operation"), X("unary"));
			pSub->appendChild(ast);
			ast = pSub;
			/* ast = Absyn__UNARY(Absyn__UMINUS,ast); */
		}
		| ast = term
		)
	;

term returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
}
	:
		(ast = factor
		|#(STAR e1 = term e2 = factor) 
			{
				DOMElement* pMul = pModelicaXMLDoc->createElement(X("mul"));
				pMul->appendChild(e1);
				pMul->appendChild(e2);
				ast = pMul;
				/* ast = Absyn__BINARY(e1,Absyn__MUL,e2); */
			}
		|#(SLASH e1 = term e2 = factor)
			{
				DOMElement* pDiv = pModelicaXMLDoc->createElement(X("div"));
				pDiv->appendChild(e1);
				pDiv->appendChild(e2);
				ast = pDiv;
				/* ast = Absyn__BINARY(e1,Absyn__DIV,e2); */
			}
		)
	;

factor returns [DOMNode* ast]
{
	DOMNode* e1;
	DOMNode* e2;
}
	:
		(ast = primary
		|#(POWER e1 = primary e2 = primary)
			{
				DOMElement* pPow = pModelicaXMLDoc->createElement(X("pow"));
				pPow->appendChild(e1);
				pPow->appendChild(e2);
				ast = pPow;
				/* ast = Absyn__BINARY(e1,Absyn__POW,e2); */
			}
		)
	;

primary returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
}
	:
		( ui:UNSIGNED_INTEGER 
			{ 
				DOMElement* pIntegerLiteral = pModelicaXMLDoc->createElement(X("integer_literal"));
				pIntegerLiteral->setAttribute(X("value"), str2xml(ui));
				ast = pIntegerLiteral;
				/* ast = Absyn__INTEGER(mk_icon(str_to_int(ui->getText()))); */
			}
		| ur:UNSIGNED_REAL
			{ 
				DOMElement* pRealLiteral = pModelicaXMLDoc->createElement(X("real_literal"));
				pRealLiteral->setAttribute(X("value"), str2xml(ur));
				ast = pRealLiteral;
				/* ast = Absyn__REAL(mk_rcon(str_to_double(ur->getText()))); */
			}
		| str:STRING
			{
				DOMElement* pStringLiteral = pModelicaXMLDoc->createElement(X("string_literal"));
				pStringLiteral->setAttribute(X("value"), str2xml(str));
				ast = pStringLiteral;
				/* ast = Absyn__STRING(str2xml(str)); */
			}
		| FALSE 
		{ 
			DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
			pBoolLiteral->setAttribute(X("value"), X("false"));
			ast = pBoolLiteral;
			/* ast = Absyn__BOOL(RML_FALSE); */ 
		}
		| TRUE 
		{
			DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
			pBoolLiteral->setAttribute(X("value"), X("true"));
			ast = pBoolLiteral;
			/* ast = Absyn__BOOL(RML_TRUE); */
		}
		| ast = component_reference__function_call
		| #(LPAR ast = tuple_expression_list)
		| #(LBRACK  e = expression_list { el_stack.push(e); }
				(e = expression_list { el_stack.push(e); } )* )
			{
				DOMElement* pConcat = pModelicaXMLDoc->createElement(X("concat"));
				pConcat = (DOMElement*)appendKids(el_stack, pConcat);
				ast = pConcat;
				/* ast = Absyn__MATRIX((DOMElement*)stack2DOMNode(el_stack)); */
			}
		| #(LBRACE ast = expression_list) 
		{ 
			DOMElement* pArray = pModelicaXMLDoc->createElement(X("array"));
			pArray->appendChild(ast);
			ast = pArray;
			/* ast = Absyn__ARRAY(ast); */
		}
		| END 
		{
			DOMElement* pEnd = pModelicaXMLDoc->createElement(X("End"));
			ast = pEnd;
			/* ast = Absyn__END; */ 
		}
		)
	;

component_reference__function_call returns [DOMNode* ast]
{
	DOMNode* cref;
	DOMNode* fnc = 0;
}
	:
		(#(FUNCTION_CALL cref = component_reference (fnc = function_call)?)
			{
				DOMElement* pCall = pModelicaXMLDoc->createElement(X("call"));
				pCall->appendChild(cref);
				if (fnc) pCall->appendChild(fnc);
				ast = pCall;
				/* ast = Absyn__CALL(cref,fnc); */
			}
		| cref = component_reference
			{
				DOMElement* pCref = pModelicaXMLDoc->createElement(X("component_reference"));
				pCref->appendChild(cref);
				if (fnc) pCref->appendChild(fnc);
				ast = pCref;
				/* ast = Absyn__CREF(cref); */
			}
		)
		|
		#(INITIAL_FUNCTION_CALL INITIAL )
			{
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
			}
		;
	
name_path returns [DOMNode* ast]
	:
		i:IDENT 
		{
			DOMElement* pIdent = pModelicaXMLDoc->createElement(X("ident"));
			pIdent->setAttribute(X("ident"), str2xml(i));
			ast = pIdent;
			/*
			str = str2xml(i);
			ast = Absyn__IDENT(str);
			*/
		}
	|#(d:DOT i2:IDENT ast = name_path )
		{
			DOMElement *pNamePath = pModelicaXMLDoc->createElement(X("qualified_name"));
			pNamePath->setAttribute(X("ident"), str2xml(i2));
			pNamePath->appendChild(ast);
			ast = pNamePath;
			/*
			str = str2xml(i2);
			ast = Absyn__QUALIFIED(str, ast);
			*/
		}
	;

component_reference	returns [DOMNode* ast]
{
	DOMNode* arr = 0;
	DOMNode* id = 0;
}
	:
		(#(i:IDENT (arr = array_subscripts)?) 
			{
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
			}
		|#(DOT #(i2:IDENT (arr = array_subscripts)?)  
				ast = component_reference)
			{
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
			}
		)
	;

function_call returns [DOMNode* ast]
	:
		#(FUNCTION_ARGUMENTS ast = function_arguments);

function_arguments 	returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* elist=0;
	DOMNode* namel=0;
}
	:
		(elist=expression_list)? (namel = named_arguments)?
		{
			DOMElement *pFunctionArguments = pModelicaXMLDoc->createElement(X("function_arguments"));
			if (namel) pFunctionArguments->appendChild(namel); 
			if (elist) pFunctionArguments->appendChild(elist);
			ast = pFunctionArguments;
			/* ast = Absyn__FUNCTIONARGS(elist,namel); */
		}
	;
/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##function_arguments
*/

named_arguments returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* n;
} 
	:
		#(NAMED_ARGUMENTS (n = named_argument { el_stack.push(n); }) (n = named_argument { el_stack.push(n); } )*)
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "function_arguments");
		}
	;

named_argument returns [DOMNode* ast]
{
	DOMNode* temp;
}
	:
		#(eq:EQUALS i:IDENT temp = expression) 
		{
			DOMElement *pNamedArgument = pModelicaXMLDoc->createElement(X("named_argument"));
			pNamedArgument->setAttribute(X("ident"), str2xml(i));
			pNamedArgument->appendChild(temp);
			ast = pNamedArgument;
			/* ast = Absyn__NAMEDARG(str2xml(i),temp); */
		}
	;

expression_list returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
}
	: 
		(#(EXPRESSION_LIST 
				e = expression { el_stack.push(e); }
				(e = expression { el_stack.push(e); } )*
			)
		)
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "expression_list");
		}
	;

tuple_expression_list returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* e;
}
	: 
		(#(EXPRESSION_LIST 
				e = expression { el_stack.push(e); }
				(e = expression { el_stack.push(e); } )*
			)
		)
		{
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
		}
	;

array_subscripts returns [DOMNode* ast]
{
	l_stack el_stack;
	DOMNode* s = 0;
}
	:
		#(LBRACK s = subscript 
			{
				el_stack.push(s);
			}
			(s = subscript
				{
					el_stack.push(s);
				}
			)* )
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "array_subscripts");
		}
	;

subscript returns [DOMNode* ast]
{
	DOMNode* e;
}
	: { DOMElement *pArraySubscripts = pModelicaXMLDoc->createElement(X("array_subscripts")); }
		(
			e = expression 
			{
				pArraySubscripts->appendChild(e);
				ast = pArraySubscripts;
				/* ast = Absyn__SUBSCRIPT(e); */
			}
		| c:COLON 
			{
				pArraySubscripts->appendChild(pColon);
				ast = pArraySubscripts;
				/* ast = Absyn__NOSUB; */
			}
		)
	;

comment returns [DOMNode* ast]
{
	DOMNode* ann=0;
	DOMNode* cmt=0;
    ast = 0;
}		:
		#(COMMENT cmt=string_comment (ann = annotation)?)
		{
			DOMElement *pComment = pModelicaXMLDoc->createElement(X("comment"));
			if (cmt) pComment->appendChild(cmt);
	  		if (ann) pComment->appendChild(ann);
			ast = pComment;
			/* if (ann) || cmt) ast = Absyn__COMMENT(ann ? mk_some(ann) : mk_none(), cmt ? mk_some(cmt) : mk_none()); */
		}
	;

string_comment returns [DOMNode* ast] :
	{
	  DOMNode* cmt=0;
	  ast = 0;	   
	}
		#(STRING_COMMENT cmt=string_concatenation)
		{
			DOMElement *pStringComment = pModelicaXMLDoc->createElement(X("string_comment"));
			pStringComment->appendChild(cmt);
			ast = pStringComment;
		}
	|
		{
			ast = 0;
		}
	;

string_concatenation returns [DOMNode* ast] 
	{
		DOMNode *pString1;
		l_stack el_stack;
	}
:
        s:STRING 
		  {
			DOMElement *pString = pModelicaXMLDoc->createElement(X("string"));
			pString->setAttribute(X("value"), str2xml(s));
	  		ast=pString;
		  }
		|#(p:PLUS pString1=string_concatenation s2:STRING)
		  {
			 DOMElement *pString = pModelicaXMLDoc->createElement(X("add"));
			 pString->appendChild(pString1);
			 DOMElement *pString2 = pModelicaXMLDoc->createElement(X("string"));
			 pString2->setAttribute(X("value"), str2xml(s2));
			 pString->appendChild(pString2);
			 ast=pString;
		  }
	;

annotation returns [DOMNode* ast]
{
    DOMNode* cmod=0;
}
    :
        #(a:ANNOTATION cmod = class_modification)
        {
			DOMElement *pAnnotation = pModelicaXMLDoc->createElement(X("annotation"));
			pAnnotation->appendChild(cmod);
			ast = pAnnotation;
            /* ast = Absyn__ANNOTATION(cmod); */
        }
    ;		


interactive_stmt returns [DOMNode* ast]
{ 
    DOMNode* al=0; 
    DOMNode* el=0;
	l_stack el_stack;	
}
    :
		(
			#(INTERACTIVE_ALG (al = algorithm) )
			{
				DOMElement *pInteractiveALG = pModelicaXMLDoc->createElement(X("IALG"));
				pInteractiveALG->appendChild(al);
				el_stack.push(pInteractiveALG);
			}	
		|	
			#(INTERACTIVE_EXP (el = expression ))
			{
				DOMElement *pInteractiveEXP = pModelicaXMLDoc->createElement(X("IEXP"));
				pInteractiveEXP->appendChild(el);
				el_stack.push(pInteractiveEXP);
			}
			
		)* (s:SEMICOLON)?
		{
			DOMElement *pInteractiveSTMT = pModelicaXMLDoc->createElement(X("ISTMT"));
			pInteractiveSTMT = (DOMElement*)appendKids(el_stack, pInteractiveSTMT);
			if (s) pInteractiveSTMT->setAttribute(X("semicolon"),X("true"));
			ast = pInteractiveSTMT;
		}
	;
