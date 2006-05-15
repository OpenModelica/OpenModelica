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
#include "ModelicaXml.h"
#endif

#include "MyAST.h"

typedef ANTLR_USE_NAMESPACE(antlr)ASTRefCount<MyAST> RefMyAST;

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
	ASTLabelType = "RefMyAST";
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
	DOMElement* pRootElementModelicaXML;
	char stmp[500];


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
}

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##modelicaxml
*/
stored_definition [mstring moFilename, DOMDocument* pModelicaXMLDocParam] returns [DOMElement *ast]
{
    DOMElement *within = 0;
    l_stack el_stack;
    pModelicaXMLDoc = pModelicaXMLDocParam;
    
	pRootElementModelicaXML = pModelicaXMLDoc->createElement(X("modelicaxml"));
	// set the location of the .mo file we're representing in XML
	pRootElementModelicaXML->setAttribute(X("file"), X(moFilename.c_str()));
	
	DOMElement* pDefinitionElement = 0;	
}
    :
        #(STORED_DEFINITION      
            ( pRootElementModelicaXML = within_clause[pRootElementModelicaXML] )?
				((f:FINAL )? { pDefinitionElement = pModelicaXMLDoc->createElement(X("definition")); }
                pDefinitionElement = class_definition[f != NULL, pDefinitionElement] 
                {
                    if (pDefinitionElement /* adrpo modified 2004-10-27 && pDefinitionElement->hasChildNodes()*/)
                    {   
                        el_stack.push_back(pDefinitionElement);
                    }
                }
            )*
        )
        {
			//pRootElementModelicaXML = within; 
			pRootElementModelicaXML = (DOMElement*)appendKids(el_stack, pRootElementModelicaXML);
            ast = pRootElementModelicaXML;
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##modelicaxml
*/
within_clause[DOMElement* parent] returns [DOMElement* ast]
{
	void* pNamePath = 0;
}
    : #(WITHIN (pNamePath = name_path)?)	
        {
		    if (pNamePath) parent->setAttribute(X("within"), X(((mstring *)pNamePath)->c_str())); 
			ast = parent;
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##definition
*/
class_definition [bool final, DOMElement *definitionElement] returns [DOMElement* ast]
{
    class_specifier_t sClassSpec;
    sClassSpec.composition = definitionElement;
}
:       #(cd:CLASS_DEFINITION 
            (e:ENCAPSULATED )? 
            (p:PARTIAL )?
            (ex:EXPANDABLE)?
			(r:class_restriction)
            (i:IDENT)?
			class_specifier[sClassSpec] { definitionElement=sClassSpec.composition; }
        )
        {   			
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
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##definition
see restriction
*/
class_restriction /* returns [DOMElement* ast] */
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
	DOMElement *comp = 0;
	DOMElement *cmt = 0;
	DOMElement *d = 0;
	DOMElement *e = 0;
	DOMElement *o = 0;
	DOMElement *p = 0;
	void *cmod = 0;
}
	:
	( (cmt = string_comment)
			comp = composition[sClassSpec.composition]		
			{
                if (cmt) sClassSpec.string_comment = cmt;				
				sClassSpec.composition = comp;
			}
		)
	| #(EQUALS 
	     (
		   d = derived_class | 
		   e = enumeration | 
		   o = overloading |
		   p = pder)) 
		{
			sClassSpec.derived = d;
			sClassSpec.enumeration = e;
			sClassSpec.overload = o;
			sClassSpec.pder = p;
		}
    | #(CLASS_EXTENDS i:IDENT (cmod = class_modification)? 
	                    { 
						  sClassSpec.classExtends = pModelicaXMLDoc->createElement(X("extended_class"));
						  if (cmod) sClassSpec.classExtends = 
							  (DOMElement*)appendKidsFromStack((l_stack *)cmod, sClassSpec.classExtends); 
						}
                        cmt = string_comment comp = composition[sClassSpec.classExtends])
        {
			sClassSpec.classExtends = pModelicaXMLDoc->createElement(X("extended_class"));
            if (cmt) sClassSpec.classExtends->appendChild(cmt);
            sClassSpec.classExtends->setAttribute(
				X("ident"), 
				X(i->getText().c_str()));
        }
	;

pder returns [DOMElement* ast] 
{
    void* func=0;
    DOMElement* var_lst=0;
}
    : #(DER func = name_path var_lst = ident_list)
        {
			ast = pModelicaXMLDoc->createElement(X("pder"));
			if (func) ast->setAttribute(X("type"), X(((mstring*)func)->c_str()));
			ast->appendChild(var_lst);
        }
    ;

ident_list returns [DOMElement* ast]
{
    l_stack el_stack;
	DOMElement* pIdent = 0; 
}
    : #(IDENT_LIST 
            (i:IDENT 
			{
				pIdent = pModelicaXMLDoc->createElement(X("pder_var"));
				pIdent->setAttribute(X("ident"), X(i->getText().c_str()));
				el_stack.push_back(pIdent); 
			} )
            (i2:IDENT 
			{
				pIdent = pModelicaXMLDoc->createElement(X("pder_var"));
				pIdent->setAttribute(X("ident"), X(i2->getText().c_str()));
				el_stack.push_back(pIdent); 
			} )*
        )
        {

			DOMElement* pIdentList = pModelicaXMLDoc->createElement(X("variables"));
			pIdentList = (DOMElement*)appendKids(el_stack, pIdentList);
			ast = pIdentList;
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##derived
*/
derived_class returns [DOMElement* ast]
{
	void* p = 0;
	DOMElement* as = 0;
	void *cmod = 0;
  	DOMElement* cmt = 0;
	DOMElement* attr = 0;
	type_prefix_t pfx;	
	DOMElement* pDerived = pModelicaXMLDoc->createElement(X("derived"));
}
	:
		(   type_prefix[pDerived]
			p = name_path 
			( as = array_subscripts[0] )? 
			( cmod = class_modification )? 
			(cmt = comment)?
			{						
				if (p)               pDerived->setAttribute(X("type"), X(((mstring*)p)->c_str())); 
				if (as)              pDerived->appendChild(as); 
				if (cmod)            pDerived = (DOMElement*)appendKidsFromStack((l_stack *)cmod, pDerived); 
				if (cmt)             pDerived->appendChild(cmt);
				ast = pDerived;
			}
		)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##enumeration
*/
enumeration returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* el = 0;
	DOMElement* cmt = 0;
}
    : 
		#(en:ENUMERATION 
			((el = enumeration_literal
			{ el_stack.push_back(el); }
			(
				el = enumeration_literal
				{ el_stack.push_back(el); }
				
			)*)
            |
                c:COLON
			)
			(cmt=comment)?
		)
		{
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
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##enumeration_literal
*/

enumeration_literal returns [DOMElement* ast] :
{
   DOMElement* c1=0;
}
    #(ENUMERATION_LITERAL i1:IDENT (c1=comment)?) 
		{
			DOMElement* pEnumerationLiteral = pModelicaXMLDoc->createElement(X("enumeration_literal"));
			pEnumerationLiteral->setAttribute(X("ident"), str2xml(i1));

			pEnumerationLiteral->setAttribute(X("sline"), X(itoa(i1->getLine(),stmp,10)));
			pEnumerationLiteral->setAttribute(X("scolumn"), X(itoa(i1->getColumn(),stmp,10)));

			if (c1) pEnumerationLiteral->appendChild(c1);
			ast = pEnumerationLiteral;
		}
	;	

/*
Overloading is used internaly in the OpenModelica.
It shouldn't appear in the normal use of the ModelicaXML.
We leave it here for the future.
*/
overloading returns [DOMElement* ast] 
{
	std::deque<void*> el_stack;
	void* el = 0;
	DOMElement* cmt = 0;
}
	:
		#(ov:OVERLOAD 
			el = name_path
			{ el_stack.push_back(el); }
			(
				el = name_path
				{ el_stack.push_back(el); }
				
			)* 
			(cmt=comment)?
		)
		{
			DOMElement* pOverload = pModelicaXMLDoc->createElement(X("overload"));
			if (cmt) pOverload->appendChild(cmt);

			pOverload->setAttribute(X("sline"), X(itoa(ov->getLine(),stmp,10)));
			pOverload->setAttribute(X("scolumn"), X(itoa(ov->getColumn(),stmp,10)));

			ast = pOverload;
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##elements
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##composition
*/
composition [DOMElement* definition] returns [DOMElement* ast]
{
    DOMElement* el = 0;
    l_stack el_stack;
    DOMElement*  ann;	
    DOMElement* pExternalFunctionCall = 0;
}
    :
        definition = element_list[1 /* public */, definition]
        (
            (	
			definition = public_element_list[definition] 
            |	definition = protected_element_list[definition] 
			|   definition = equation_clause[definition]
            |	definition = algorithm_clause[definition]
            )
        )*
		(	#(EXTERNAL { pExternalFunctionCall = pModelicaXMLDoc->createElement(X("external")); }
				( pExternalFunctionCall = external_function_call[pExternalFunctionCall])
				(pExternalFunctionCall = annotation[0 /*none*/, pExternalFunctionCall, INSIDE_EXTERNAL])?
				( 
				 { pExternalFunctionCall->appendChild(pModelicaXMLDoc->createElement(X("semicolon"))); }
				  #(EXTERNAL_ANNOTATION pExternalFunctionCall = annotation[0 /*none*/, pExternalFunctionCall, INSIDE_EXTERNAL])
				 )*
			)
		)?
        {
			if (pExternalFunctionCall) definition->appendChild(pExternalFunctionCall);
            ast = definition; 
        }
    ;

public_element_list[DOMElement* definition] returns [DOMElement* ast]
{
    DOMElement* el;    
}
    :
        #(p:PUBLIC 
            definition = element_list[1 /* public */, definition]
        )
        {
			ast = definition;
        }
    ;

protected_element_list[DOMElement* definition] returns [DOMElement* ast]
{
    DOMElement* el;
}
    :
        
        #(p:PROTECTED
            definition = element_list[2 /* protected */, definition]
        )
        {
			ast = definition;
        }
    ;

/*
<!ELEMENT external  ((external_equal?, (expression_list)?), 
          annotation?, (semicolon, annotation)?)  >
<!ATTLIST external  

	ident CDATA #IMPLIED
	language_specification CDATA #IMPLIED
	%location;
 >
*/

external_function_call[DOMElement *pExternalFunctionCall] returns [DOMElement* ast]
{
	DOMElement* temp=0;
	DOMElement* temp2=0;
	DOMElement* temp3=0;
	ast = 0;
	DOMElement* pExternalEqual = pModelicaXMLDoc->createElement(X("external_equal"));
}
	:
        (s:STRING)?
        (#(EXTERNAL_FUNCTION_CALL 
				(
					(i:IDENT (temp = expression_list)?)
					{
						if (s != NULL) pExternalFunctionCall->setAttribute(X("language_specification"), str2xml(s));  
						if (i != NULL) pExternalFunctionCall->setAttribute(X("ident"), str2xml(i));
						if (temp) pExternalFunctionCall->appendChild(temp);

						pExternalFunctionCall->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
						pExternalFunctionCall->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

						ast = pExternalFunctionCall;
					}
				| #(e:EQUALS temp2 = component_reference i2:IDENT ( temp3 = expression_list)?)
					{
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
					}
				)
			))? 
		{
			if (!ast) 
			{ 
				//parent->appendChild(ast);
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

element_list[int iSwitch, DOMElement*definition] returns [DOMElement* ast]
{
    DOMElement* e = 0;
    l_stack el_stack;
    DOMElement* ann = 0;
}
    :
        ((definition = element[iSwitch, definition])
         |(definition = annotation[iSwitch, definition, INSIDE_ELEMENT]))*
        {
			ast = definition;
        }
    ;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##elements
*/

element[int iSwitch, DOMElement *parent] returns [DOMElement* ast]
{
	DOMElement* class_def = 0;
	DOMElement* e_spec = 0;
	DOMElement* final = 0;
	DOMElement* innerouter = 0;
	DOMElement* constr = 0;
	DOMElement* cmt = 0;
	DOMElement* comp_clause = 0;
}
	: 
		( parent = import_clause[iSwitch, parent]
			{
				ast = parent;				
			}
		| parent = extends_clause[iSwitch, parent]
			{
				ast = parent;
			}
		| #(DECLARATION 
			( (re:REDELCARE)?
				{ 
				   DOMElement* componentElement = pModelicaXMLDoc->createElement(X("component_clause")); 
				   setVisibility(iSwitch, componentElement);
				   if (re) componentElement->setAttribute(X("redeclare"), X("true")); 
			    }
			        (f:FINAL)? { if (f) componentElement->setAttribute(X("final"), X("true")); }
					(i:INNER)? (o:OUTER)? 
					  { 
						  if (i && o) componentElement->setAttribute(X("innerouter"), X("innerouter"));
						  else
						  {
							if (i) componentElement->setAttribute(X("innerouter"), X("inner")); 
							if (o) componentElement->setAttribute(X("innerouter"), X("outer"));
						  }
					  }
					(parent = component_clause[parent, componentElement]
						{
							ast = parent;
						}
						| r:REPLACEABLE {if (r) componentElement->setAttribute(X("replaceable"), X("true"));}
						parent = component_clause[parent, componentElement] 
						(constr = constraining_clause cmt=comment)?
						{							
                            if (constr) 
							{
								// append the comment to the constraint
								if (cmt) ((DOMElement*)constr)->appendChild(cmt);
								parent->appendChild(constr);																
							}
							ast = parent;
						}
					)
				)
			)
		| #(DEFINITION
				(   (re2:REDECLARE)? 
					{ 
						DOMElement* definitionElement = pModelicaXMLDoc->createElement(X("definition")); 
						setVisibility(iSwitch, definitionElement);
				        if (re2) definitionElement->setAttribute(X("redeclare"), X("true")); 
					}
					(fd:FINAL)? { if (fd) definitionElement->setAttribute(X("final"), X("true")); }
					(id:INNER)? (od:OUTER)? 
					  { 
						  if (i && o) definitionElement->setAttribute(X("innerouter"), X("outer"));
						  else
						  {
							  if (i) definitionElement->setAttribute(X("innerouter"), X("inner")); 
							  if (o) definitionElement->setAttribute(X("innerouter"), X("outer"));
						  }
					  }
					(
						definitionElement = class_definition[fd != NULL, definitionElement] 
						{
							if (definitionElement && definitionElement->hasChildNodes())
								parent->appendChild(definitionElement);
							ast = parent;
						}
					| 
						(rd:REPLACEABLE 
							definitionElement = class_definition[fd != NULL, definitionElement] 
							(constr = constraining_clause cmt=comment)?
						)
						{
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
						}
					)
				)
			)
		)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##import
*/
import_clause[int iSwitch, DOMElement *parent] returns [DOMElement* ast]
{
	DOMElement* imp = 0;
	DOMElement* cmt = 0;
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
			setVisibility(iSwitch, pImport);

			pImport->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pImport->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

			pImport->appendChild(imp);
			if (cmt) pImport->appendChild(cmt);
			parent->appendChild(pImport);
			ast = parent;
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##import
*/
explicit_import_name returns [DOMElement* ast]
{
	void* path;
}
	:
		#(EQUALS i:IDENT path = name_path)	
		{
			DOMElement* pExplicitImport = pModelicaXMLDoc->createElement(X("named_import"));
			pExplicitImport->setAttribute(X("ident"), str2xml(i));

			pExplicitImport->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pExplicitImport->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

			if (path) pExplicitImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));
			ast = pExplicitImport;
		}
	;
/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##import
*/
implicit_import_name returns [DOMElement* ast]
{
	void* path;
}
	:
		(#(unq:UNQUALIFIED path = name_path)
			{
				DOMElement* pUnqImport = pModelicaXMLDoc->createElement(X("unqualified_import"));
				if (path) pUnqImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));

				pUnqImport->setAttribute(X("sline"), X(itoa(unq->getLine(),stmp,10)));
				pUnqImport->setAttribute(X("scolumn"), X(itoa(unq->getColumn(),stmp,10)));

				ast = pUnqImport;
			}
		|#(qua:QUALIFIED path = name_path)
			{
				DOMElement* pQuaImport = pModelicaXMLDoc->createElement(X("qualified_import"));
				if (path) pQuaImport->setAttribute(X("name"), X(((mstring*)path)->c_str()));

				pQuaImport->setAttribute(X("sline"), X(itoa(qua->getLine(),stmp,10)));
				pQuaImport->setAttribute(X("scolumn"), X(itoa(qua->getColumn(),stmp,10)));

				ast = pQuaImport;
			}
		)
	;


/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##extends
*/
extends_clause[int iSwitch, DOMElement* parent] returns [DOMElement* ast]
{
	void *path = 0;
	void *mod = 0;	
}
	: 
		(#(e:EXTENDS 
				path = name_path 
				( mod = class_modification)? 
			)
			{				
				DOMElement* pExtends = pModelicaXMLDoc->createElement(X("extends"));
				setVisibility(iSwitch, pExtends);

				pExtends->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
				pExtends->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));

				if (mod) pExtends = (DOMElement*)appendKidsFromStack((l_stack *)mod, pExtends);
				if (path) pExtends->setAttribute(X("type"), X(((mstring*)path)->c_str()));
				parent->appendChild(pExtends);
				ast = parent;
			}
		)
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##constrain
*/
constraining_clause returns [DOMElement* ast] 
{
   DOMElement* pConstrain = pModelicaXMLDoc->createElement(X("constrain"));
}
	:
		(ast = extends_clause[0, pConstrain])
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##component
*/
component_clause[DOMElement* parent, DOMElement* attributes] returns [DOMElement* ast]
{
	type_prefix_t pfx;
	void* path = 0;
	DOMElement* arr = 0;
	DOMElement* comp_list = 0;
}
	:
		type_prefix[attributes] 
		path = type_specifier { if (path) attributes->setAttribute(X("type"), X(((mstring*)path)->c_str())); }
		(arr = array_subscripts[1])? 
		parent = component_list[parent, attributes, arr]
		{
			ast = parent; 
		}
	;

type_prefix[DOMElement* parent]
	:
		(f:FLOW)?
		(d:DISCRETE | p:PARAMETER | c:CONSTANT)?
		(i:INPUT | o:OUTPUT)?
		{
			if (f != NULL) { parent->setAttribute(X("flow"), X("true")); }
			//else { parent->setAttribute(X("flow"), X("none")); }
			if (d != NULL) { parent->setAttribute(X("variability"), X("discrete")); }
			else if (p != NULL) { parent->setAttribute(X("variability"), X("parameter")); }
			else if (c != NULL) { parent->setAttribute(X("variability"), X("constant")); }
			//else { parent->setAttribute(X("variability"), X("variable")); }
			if (i != NULL) { parent->setAttribute(X("direction"), X("input")); } 
			else if (o != NULL) { parent->setAttribute(X("direction"), X("output")); }
			//else { parent->setAttribute(X("direction"), X("bidirectional")); }
		}
	;

// returns datatype Path
type_specifier returns [void* ast]
	:
		ast = name_path;


// returns datatype Component list
component_list[DOMElement* parent, DOMElement *attributes, DOMElement* type_array] 
              returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e=0;
}
	:
		parent = component_declaration[parent, attributes, type_array] 
		(parent = component_declaration[parent, attributes, type_array])*
		{
			ast = parent; 
		}
	;

conditional_attribute returns [DOMElement* ast]
{
	DOMElement* cda = 0;
	DOMElement* e = 0;
}
: #(i:IF e=expression)
{
	cda = pModelicaXMLDoc->createElement(X("conditional"));			
	cda->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
	cda->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
	cda->appendChild(e);
	ast = cda;
}
;

// returns datatype Component
component_declaration[DOMElement* parent, DOMElement *attributes, DOMElement *type_array] 
         returns [DOMElement* ast]
{
	DOMElement* cmt = 0;
	DOMElement* dec = 0;
	DOMElement* cda = 0;
}
	:
		(dec = declaration[attributes, type_array])
		(cda = conditional_attribute)?
		(cmt = comment)?
		{
			if (cmt) dec->appendChild(cmt);
			if (cda) dec->appendChild(cda);
			parent->appendChild(dec); 
			ast = parent; 
		}
	;


// returns datatype Component
declaration[DOMElement* parent, DOMElement* type_array] returns [DOMElement* ast]
{
	DOMElement* arr = 0;
	DOMElement* mod = 0;
	DOMElement* id = 0;
}
	:
		#(i:IDENT (arr = array_subscripts[0])? (mod = modification)?)
		{
			DOMElement *pComponent = pModelicaXMLDoc->createElement(X("component"));
			pComponent->setAttribute(X("ident"), str2xml(i));			
			pComponent->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pComponent->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			setAttributes(pComponent, parent);
			if (type_array) pComponent->appendChild(type_array);
			if (arr) pComponent->appendChild(arr);
			if (mod) pComponent->appendChild(mod);
			ast = pComponent;
		}
	;

modification returns [DOMElement* ast] 
{
	DOMElement* e = 0;
	void *cm = 0;
	int iswitch = 0;
}
	:
		( cm = class_modification (e = expression )?
		  |#(eq:EQUALS e = expression) { iswitch = 1; }
		  |#(as:ASSIGN e = expression) { iswitch = 2; }
		)
		{
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
		}
	;

class_modification returns [void *stack]
{	
	stack = 0;
}
	:
		#(CLASS_MODIFICATION (stack = argument_list)?)
	;

argument_list returns [void *stack]
{
	l_stack *el_stack = new l_stack;
	DOMElement* e;
}
	:
		#(ARGUMENT_LIST 
			e = argument { el_stack->push_back(e); }
			(e = argument { el_stack->push_back(e); } )*
		)
		{
			if (el_stack->size()) stack = (void*)el_stack;
			else (stack = 0);
		}
	;

argument returns [DOMElement* ast]
	:
		#(em:ELEMENT_MODIFICATION ast = element_modification)
		{
			if (em) 
			{
				ast->setAttribute(X("sline"), X(itoa(em->getLine(),stmp,10)));
				ast->setAttribute(X("scolumn"), X(itoa(em->getColumn(),stmp,10)));
			}
		}
		|#(er:ELEMENT_REDECLARATION ast = element_redeclaration) 
		{
			if (er) 
			{
				ast->setAttribute(X("sline"), X(itoa(er->getLine(),stmp,10)));
				ast->setAttribute(X("scolumn"), X(itoa(er->getColumn(),stmp,10)));
			}
		}
	;

element_modification returns [DOMElement* ast]
{
	DOMElement* cref;
	DOMElement* mod=0;
	DOMElement* cmt=0;
}
	:
		(e:EACH)?
		(f:FINAL)? 
		cref = component_reference 
		(mod = modification)?
		cmt = string_comment
		{
			DOMElement *pModification = pModelicaXMLDoc->createElement(X("element_modification"));
			if (f) pModification->setAttribute(X("final"), X("true"));
			if (e) pModification->setAttribute(X("each"), X("true"));
			pModification->appendChild(cref);
			if (mod) pModification->appendChild(mod);
			if (cmt) pModification->appendChild(cmt);
			ast = pModification;
		}
	;

element_redeclaration returns [DOMElement* ast]
{
	DOMElement* class_def = 0;
	DOMElement* e_spec = 0; 
	DOMElement* constr = 0;
	DOMElement* final = 0;
	DOMElement* each = 0;
	class_def = pModelicaXMLDoc->createElement(X("definition"));
}
	:
		(#(r:REDECLARE (e:EACH)? (f:FINAL)?
			(
					(class_def = class_definition[false, class_def] 
						{
							DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration"));
							if (class_def && class_def->hasChildNodes())
								pElementRedeclaration->appendChild(class_def);
							if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
							if (each) pElementRedeclaration->setAttribute(X("each"), X("true"));
							ast = pElementRedeclaration;
						}
					|   { DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration")); }
						pElementRedeclaration = component_clause1[pElementRedeclaration]
						{							
							if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
							if (each) pElementRedeclaration->setAttribute(X("each"), X("true"));
							ast = pElementRedeclaration;
						}
					)
				   |
					( re:REPLACEABLE 
					    { DOMElement *pElementRedeclaration = pModelicaXMLDoc->createElement(X("element_redeclaration")); }
						(class_def = class_definition[false, class_def]                            
						| pElementRedeclaration = component_clause1[pElementRedeclaration]
						)
						(constr = constraining_clause)?
						{	
							if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
							if (f) pElementRedeclaration->setAttribute(X("final"), X("true"));
							if (re) pElementRedeclaration->setAttribute(X("replaceable"), X("true"));
							if (class_def &&  class_def->hasChildNodes()) 
							{
								pElementRedeclaration->appendChild(class_def);
								if (constr) pElementRedeclaration->appendChild(constr);
							}
							else
							{
								if (constr) pElementRedeclaration->appendChild(constr);
							}
							ast = pElementRedeclaration;
						}
					)
				)
			)
		)
	;

component_clause1[DOMElement *parent] returns [DOMElement* ast]
{
	type_prefix_t pfx;
	DOMElement* attr = pModelicaXMLDoc->createElement(X("tmp"));
	void* path = 0;
	DOMElement* arr = 0;
	DOMElement* comp_decl = 0;
	DOMElement* comp_list = 0;
}
	:
		type_prefix[attr]
		path = type_specifier { if (path) attr->setAttribute(X("type"), X(((mstring*)path)->c_str())); }
		parent = component_declaration[parent, attr, null]
		{			
			ast = parent;
		}
	;

// Return datatype ClassPart
equation_clause[DOMElement *definition] returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e = 0;
	DOMElement* ann = 0;
} 
	:
		#(eq:EQUATION
			(
				(
				  definition = equation[definition] 
				| definition = annotation[0 /*none*/, definition, INSIDE_EQUATION])*
			)
		)
		{
			ast = definition;
		}
	|
		#(INITIAL_EQUATION
			#(EQUATION
				(
				  definition = equation[definition] 
				| definition = annotation [0 /* none */, definition, INSIDE_EQUATION ])*
			)
			{
				ast = definition; 
			}
		)
	;	

algorithm_clause[DOMElement* definition] returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e;
	DOMElement* ann;
}
	:
		#(ALGORITHM 
			(definition = algorithm[definition] 
			| definition = annotation [0 /* none */, definition, INSIDE_ALGORITHM])*
		)
		{
			ast = definition; 
		}
	|
		#(INITIAL_ALGORITHM
			#(ALGORITHM 
				(definition = algorithm[definition] 
				| definition = annotation [0 /* none */, definition, INSIDE_ALGORITHM])*
			)
			{
				ast = definition;
			}
		)
	;

equation[DOMElement* definition] returns [DOMElement* ast] 
{
	DOMElement* cmt = 0;
}
	:
		#(es:EQUATION_STATEMENT
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
				if (es) 
				{
					pEquation->setAttribute(X("sline"), X(itoa(es->getLine(),stmp,10)));
					pEquation->setAttribute(X("scolumn"), X(itoa(es->getColumn(),stmp,10)));
				}
				definition->appendChild(pEquation);
				ast = definition;
			}
		)
	;

equation_funcall returns [DOMElement* ast]
{
  DOMElement* fcall = 0;
}
	:
		i:IDENT fcall = function_call 
		{ 
			 DOMElement*  pEquCall = pModelicaXMLDoc->createElement(X("equ_call"));
			 pEquCall->setAttribute(X("ident"), str2xml(i));
			 pEquCall->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			 pEquCall->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			 pEquCall->appendChild(fcall);
			 ast = pEquCall;			
		}
	;

algorithm[DOMElement *definition] returns [DOMElement* ast]
{
	DOMElement* cref;
	DOMElement* expr;
	DOMElement* tuple;
	DOMElement* args;
  	DOMElement* cmt=0;
}
	:
		#(as:ALGORITHM_STATEMENT 
			(#(az:ASSIGN 
					(cref = component_reference expr = expression
						{
							DOMElement*  pAlgAssign = pModelicaXMLDoc->createElement(X("alg_assign"));
							if (az)
							{
								pAlgAssign->setAttribute(X("sline"), X(itoa(az->getLine(),stmp,10)));
								pAlgAssign->setAttribute(X("scolumn"), X(itoa(az->getColumn(),stmp,10)));
							}
							pAlgAssign->appendChild(cref);
							pAlgAssign->appendChild(expr);
							ast = pAlgAssign;
						}
					|	(tuple = tuple_expression_list cref = component_reference args = function_call)
						{
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
	  		}
		)
	;

algorithm_function_call returns [DOMElement* ast]
{
	DOMElement* cref;
	DOMElement* args;
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
		}
	;

equality_equation returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
}
	:
		#(eq:EQUALS e1 = simple_expression e2 = expression)
		{
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
		}
	;

conditional_equation_e returns [DOMElement* ast]
{
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
}
	:
		#(i:IF
	        e1 = expression { pEquIf->appendChild(e1); }
			pEquThen = equation_list[pEquThen] { pEquIf->appendChild(pEquThen); }
			( e = equation_elseif { el_stack.push_back(e); } )*
				(ELSE pEquElse = equation_list[pEquElse] { fbElse = true;} )?
		)
		{
			pEquIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pEquIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

			if (el_stack.size()>0) pEquIf = (DOMElement*)appendKids(el_stack, pEquIf); // ?? is this ok?
			if (fbElse) pEquIf->appendChild(pEquElse);
			ast = pEquIf;
		}
	;

conditional_equation_a returns [DOMElement* ast]
{
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
}
	:
		#(i:IF
	        e1 = expression { pAlgIf->appendChild(e1); }
			pAlgThen = algorithm_list[pAlgThen] 
			{ 
				if (pAlgThen)
				pAlgIf->appendChild(pAlgThen); 
			}
			( e = algorithm_elseif { el_stack.push_back(e); } )*
				( ELSE pAlgElse = algorithm_list[pAlgElse] {fbElse = true; } )?
		)
		{
			pAlgIf->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pAlgIf->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
			if (el_stack.size()>0) pAlgIf = (DOMElement*)appendKids(el_stack, pAlgIf);
			if (fbElse)  pAlgIf->appendChild(pAlgElse);
			ast = pAlgIf;
		}
	;

/*
<!ELEMENT equ_for (for_indices, %equation_list;)>
<!ATTLIST equ_for
 		  %location; 
>
*/


for_clause_e returns [DOMElement* ast] 
{
	DOMElement* f;
	DOMElement* eq;
	DOMElement*  pEquFor = pModelicaXMLDoc->createElement(X("equ_for"));
}
	:
		#(i:FOR f=for_indices { pEquFor->appendChild(f); }	
	          pEquFor=equation_list[pEquFor])
		{
			pEquFor->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pEquFor->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

			ast = pEquFor;
		}
	;


for_clause_a returns [DOMElement* ast]
{
	DOMElement* f;
	DOMElement* eq;
	DOMElement*  pAlgFor = pModelicaXMLDoc->createElement(X("alg_for"));
}
	:
		#(i:FOR f=for_indices 
			{ 
				f->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				f->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));
				pAlgFor->appendChild(f); 
			}
			pAlgFor = algorithm_list[pAlgFor])
		{
			pAlgFor->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pAlgFor->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

			ast = pAlgFor;
		}
	;


for_iterator returns[DOMElement* ast]
{
	DOMElement* expr;
	DOMElement* iter;
}
    :
        #(f:FOR expr = expression #(IN i:IDENT iter=expression))
        {
		    DOMElement*  pForIter = pModelicaXMLDoc->createElement(X("for_iterator"));
			pForIter->appendChild(expr);
			DOMElement* pForIndex = pModelicaXMLDoc->createElement(X("for_index"));
			pForIndex->setAttribute(X("ident"), str2xml(i));
			pForIndex->setAttribute(X("sline"), X(itoa(f->getLine(),stmp,10)));
			pForIndex->setAttribute(X("scolumn"), X(itoa(f->getColumn(),stmp,10)));
		    if (iter) pForIndex->appendChild(iter);
			pForIter->appendChild(pForIndex);
			ast = pForIter;
        }
    ;

for_indices returns [DOMElement* ast]
{
	DOMElement* f;
	DOMElement* e;
	l_stack el_stack;
}
:
    (#(IN i:IDENT (e=expression)?)
	{ 
		DOMElement* pForIndex = pModelicaXMLDoc->createElement(X("for_index"));
		pForIndex->setAttribute(X("ident"), str2xml(i));

		pForIndex->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
		pForIndex->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

		if (e) pForIndex->appendChild(e);
		el_stack.push_back(pForIndex); 
	} 
	)*
	{
		DOMElement*  pForIndices = pModelicaXMLDoc->createElement(X("for_indices"));
		pForIndices = (DOMElement*)appendKids(el_stack, pForIndices);
		ast = pForIndices;
	}
;

while_clause returns [DOMElement* ast]
{
	DOMElement* e;
	DOMElement* body;
	DOMElement* pAlgWhile = pModelicaXMLDoc->createElement(X("alg_while"));
}
	:
		#(w:WHILE 
	      e = expression 
		  { 
			  pAlgWhile->appendChild(e); 
		  }
		  pAlgWhile = algorithm_list[pAlgWhile])
		{
			pAlgWhile->setAttribute(X("sline"), X(itoa(w->getLine(),stmp,10)));
			pAlgWhile->setAttribute(X("scolumn"), X(itoa(w->getColumn(),stmp,10)));

			ast = pAlgWhile;
		}
	;


/*
<!ELEMENT equ_when  (%exp;, equ_then, equ_elsewhen*)  >
<!ATTLIST equ_when  

	%location;
 >
*/

when_clause_e returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e;
	DOMElement* body;
	DOMElement* el = 0;
	DOMElement* pEquWhen = pModelicaXMLDoc->createElement(X("equ_when"));
	DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
}
	:
		#(wh:WHEN 
	        e = expression { pEquWhen->appendChild(e); }
			pEquThen = equation_list[pEquThen] { pEquWhen->appendChild(pEquThen); }
	  		(el = else_when_e { el_stack.push_back(el); } )*
		)
		{
			pEquWhen->setAttribute(X("sline"), X(itoa(wh->getLine(),stmp,10)));
			pEquWhen->setAttribute(X("scolumn"), X(itoa(wh->getColumn(),stmp,10)));

			if (el_stack.size()>0) pEquWhen = (DOMElement*)appendKids(el_stack, pEquWhen); // ??is this ok?
			ast = pEquWhen;
		}
	;

else_when_e returns [DOMElement* ast]
{ 
	DOMElement*  expr;
	DOMElement*  eqn;
	DOMElement* pEquElseWhen = pModelicaXMLDoc->createElement(X("equ_elsewhen"));
    DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
}
	:
        #(e:ELSEWHEN expr = expression { pEquElseWhen->appendChild(expr); }  
	      pEquThen = equation_list[pEquThen])
		{
			pEquElseWhen->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
			pEquElseWhen->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));

			pEquElseWhen->appendChild(pEquThen);
			ast = pEquElseWhen;
		}
	;

when_clause_a returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e;
	DOMElement* body;
	DOMElement* el = 0;
	DOMElement* pAlgWhen = pModelicaXMLDoc->createElement(X("alg_when"));
	DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
}
	:
		#(wh:WHEN 
	      e = expression { pAlgWhen->appendChild(e); }
		  pAlgThen = algorithm_list[pAlgThen] { pAlgWhen->appendChild(pAlgThen); }
			(el = else_when_a {el_stack.push_back(el); })* 
		 )
		{
			pAlgWhen->setAttribute(X("sline"), X(itoa(wh->getLine(),stmp,10)));
			pAlgWhen->setAttribute(X("scolumn"), X(itoa(wh->getColumn(),stmp,10)));

			if (el_stack.size() > 0) pAlgWhen = (DOMElement*)appendKids(el_stack, pAlgWhen);
			ast = pAlgWhen;
		}
	;

else_when_a returns [DOMElement* ast]
{ 
	DOMElement*  expr;
	DOMElement*  alg;
	DOMElement* pAlgElseWhen = pModelicaXMLDoc->createElement(X("alg_elsewhen"));
	DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
}
	:
        #(e:ELSEWHEN expr = expression { pAlgElseWhen->appendChild(expr); }
	      pAlgThen = algorithm_list[pAlgThen])
		{
			pAlgElseWhen->setAttribute(X("sline"), X(itoa(e->getLine(),stmp,10)));
			pAlgElseWhen->setAttribute(X("scolumn"), X(itoa(e->getColumn(),stmp,10)));

	        pAlgElseWhen->appendChild(pAlgThen);
			ast = pAlgElseWhen;
		}
	;

equation_elseif returns [DOMElement* ast]
{
	DOMElement* e;
	DOMElement* eq;
	DOMElement* pEquElseIf = pModelicaXMLDoc->createElement(X("equ_elseif"));
	DOMElement* pEquThen = pModelicaXMLDoc->createElement(X("equ_then"));
}
	:
		#(els:ELSEIF 
	        e = expression { pEquElseIf->appendChild(e); }
			pEquThen = equation_list[pEquThen]
		)
		{
			pEquElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
			pEquElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));

			pEquElseIf->appendChild(pEquThen);
			ast = pEquElseIf;
		}
	;

algorithm_elseif returns [DOMElement* ast]
{
	DOMElement* e;
	DOMElement* body;
	DOMElement* pAlgElseIf = pModelicaXMLDoc->createElement(X("alg_elseif"));
	DOMElement* pAlgThen = pModelicaXMLDoc->createElement(X("alg_then"));
}
	:
		#(els:ELSEIF 
	        e = expression { pAlgElseIf->appendChild(e); }
			pAlgThen = algorithm_list[pAlgThen]
		)
		{
			pAlgElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
			pAlgElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));

			pAlgElseIf->appendChild(pAlgThen);
			ast = pAlgElseIf;
		}
	;

equation_list[DOMElement* pEquationList] returns [DOMElement* ast]
{
	DOMElement* e;
	l_stack el_stack;
}
	:
		(pEquationList = equation[pEquationList])*
		{
			ast = pEquationList; 
		}
	;

algorithm_list[DOMElement*  pAlgorithmList] returns [DOMElement* ast]
{
	DOMElement* e;
	l_stack el_stack;
}
	:
	   (pAlgorithmList = algorithm[pAlgorithmList] )*
		{			
			ast = pAlgorithmList; 
		}
	;

connect_clause returns [DOMElement* ast]
{
	DOMElement* r1;
	DOMElement* r2;
}
	:
		#(c:CONNECT 
			r1 = component_reference
			r2 = component_reference
		)
		{
			DOMElement* pEquConnect = pModelicaXMLDoc->createElement(X("equ_connect"));

			pEquConnect->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
			pEquConnect->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));

			pEquConnect->appendChild(r1);
			pEquConnect->appendChild(r2);
			ast = pEquConnect;
		}
	;


expression returns [DOMElement* ast]
	:
		(	ast = simple_expression
		|	ast = if_expression
		|   ast = code_expression
		)
	;

if_expression returns [DOMElement* ast]
{
	DOMElement* cond;
	DOMElement* thenPart;
	DOMElement* elsePart;
	DOMElement* e;
	DOMElement* elseifPart;
	l_stack el_stack;
}
	:
		#(i:IF cond = expression
			thenPart = expression (e=elseif_expression {el_stack.push_back(e);} )* elsePart = expression
			{
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
			}
		)
	;

elseif_expression returns [DOMElement* ast]
{
	DOMElement* cond;
	DOMElement* thenPart;
}
	:
		#(els:ELSEIF cond = expression thenPart = expression
		{
			DOMElement* pElseIf = pModelicaXMLDoc->createElement(X("elseif"));

			pElseIf->setAttribute(X("sline"), X(itoa(els->getLine(),stmp,10)));
			pElseIf->setAttribute(X("scolumn"), X(itoa(els->getColumn(),stmp,10)));

			pElseIf->appendChild(cond);
			DOMElement* pThen = pModelicaXMLDoc->createElement(X("then"));
			pThen->appendChild(thenPart);
			pElseIf->appendChild(pThen);
			ast = pElseIf;
		}
	  )
	;

simple_expression returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
	DOMElement* e3;
}
	:
	(#(r3:RANGE3 e1 = logical_expression 
				e2 = logical_expression 
				e3 = logical_expression)
			{
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
			}
	|#(r2:RANGE2 e1 = logical_expression e3 = logical_expression)
			{
				DOMElement* pRange = pModelicaXMLDoc->createElement(X("range"));

				pRange->setAttribute(X("sline"), X(itoa(r2->getLine(),stmp,10)));
				pRange->setAttribute(X("scolumn"), X(itoa(r2->getColumn(),stmp,10)));

				pRange->appendChild(e1);
				pRange->appendChild(e3);
				ast = pRange;
			}
	| ast = logical_expression
	)
	;

// ?? what the hack is this?
code_expression returns [DOMElement* ast]
{
	DOMElement*pCode = pModelicaXMLDoc->createElement(X("code"));
}

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

	|	#(CODE_ELEMENT (ast = element[0 /* none */, pCode]) )
		{
			// ?? what the hack is this?
			DOMElement* pElement = pModelicaXMLDoc->createElement(X("element"));
			pElement->appendChild(ast);
			ast = pElement;
			/* ast = Absyn__CODE(Absyn__C_5fELEMENT(ast)); */
		}
		
	|	#(CODE_EQUATION (ast = equation_clause[pCode]) )
		{
			// ?? what the hack is this?
			DOMElement* pEquationSection = pModelicaXMLDoc->createElement(X("equation_section"));
			pEquationSection->appendChild(ast);
			ast = pEquationSection; 
			/* ast = Absyn__CODE(Absyn__C_5fEQUATIONSECTION(RML_FALSE, 
					RML_FETCH(RML_OFFSET(RML_UNTAGPTR(ast), 1)))); */
		}
		
	|	#(CODE_INITIALEQUATION (ast = equation_clause[pCode]) )
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
	|	#(CODE_ALGORITHM (ast = algorithm_clause[pCode]) )
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
	|	#(CODE_INITIALALGORITHM (ast = algorithm_clause[pCode]) )
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

logical_expression returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
}
	: 
		(ast = logical_term
		| #(o:OR e1 = logical_expression e2 = logical_term)
			{
				DOMElement* pOr = pModelicaXMLDoc->createElement(X("or"));

				pOr->setAttribute(X("sline"), X(itoa(o->getLine(),stmp,10)));
				pOr->setAttribute(X("scolumn"), X(itoa(o->getColumn(),stmp,10)));

				pOr->appendChild(e1);
				pOr->appendChild(e2);
				ast = pOr;
			}
		)

	;

logical_term returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
}
	:
		(ast = logical_factor
		| #(a:AND e1 = logical_term e2 = logical_factor)
			{
				DOMElement* pAnd = pModelicaXMLDoc->createElement(X("and"));

				pAnd->setAttribute(X("sline"), X(itoa(a->getLine(),stmp,10)));
				pAnd->setAttribute(X("scolumn"), X(itoa(a->getColumn(),stmp,10)));

				pAnd->appendChild(e1);
				pAnd->appendChild(e2);
				ast = pAnd;
			}
		)
	;

logical_factor returns [DOMElement* ast]
	:
	#(n:NOT ast = relation 
      { 
		DOMElement* pNot = pModelicaXMLDoc->createElement(X("not"));

		pNot->setAttribute(X("sline"), X(itoa(n->getLine(),stmp,10)));
		pNot->setAttribute(X("scolumn"), X(itoa(n->getColumn(),stmp,10)));

		pNot->appendChild(ast);
		ast = pNot;
	  })
	| ast = relation;

relation returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* op = 0;
	DOMElement* e2 = 0;
}
     :   
		( ast = arithmetic_expression
		| 
		( #(lt:LESS e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("lt")); /* Absyn__LESS; */ }                    
		| #(lte:LESSEQ e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("lte")); /* Absyn__LESSEQ; */ }                    
		| #(gt:GREATER e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("gt")); /* Absyn__GREATER; */ }                    
		| #(gte:GREATEREQ e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("gte")); /* Absyn__GREATEREQ; */ }                    
		| #(eq:EQEQ e1=arithmetic_expression e2=arithmetic_expression)
				{ op = pModelicaXMLDoc->createElement(X("eq")); /* Absyn__EQUAL; */ }                    
		| #(ne:LESSGT e1=arithmetic_expression e2=arithmetic_expression )
				{ op = pModelicaXMLDoc->createElement(X("ne")); /* op = Absyn__NEQUAL; */ }                    
			)
			{
				op->appendChild(e1);
				op->appendChild(e2);
				if (lt) { op->setAttribute(X("sline"), X(itoa(lt->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(lt->getColumn(),stmp,10))); }
				if (lte){ op->setAttribute(X("sline"), X(itoa(lte->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(lte->getColumn(),stmp,10)));	}
				if (gt) { op->setAttribute(X("sline"), X(itoa(gt->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(gt->getColumn(),stmp,10))); }
				if (gte){ op->setAttribute(X("sline"), X(itoa(gte->getLine(),stmp,10))); op->setAttribute(X("scolumn"), X(itoa(gte->getColumn(),stmp,10)));	}
				if (eq)	{ op->setAttribute(X("sline"), X(itoa(eq->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(eq->getColumn(),stmp,10))); }
				if (ne) { op->setAttribute(X("sline"), X(itoa(ne->getLine(),stmp,10)));	op->setAttribute(X("scolumn"), X(itoa(ne->getColumn(),stmp,10))); }
				ast = op;
			}
		)
	;

arithmetic_expression returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
}
	:
		(ast = unary_arithmetic_expression
		|#(add:PLUS e1 = arithmetic_expression e2 = term)
			{
				DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));

				pAdd->setAttribute(X("sline"), X(itoa(add->getLine(),stmp,10)));
				pAdd->setAttribute(X("scolumn"), X(itoa(add->getColumn(),stmp,10)));

				pAdd->setAttribute(X("operation"), X("binary"));
				pAdd->appendChild(e1);
				pAdd->appendChild(e2);
				ast = pAdd;
			}
		|#(sub:MINUS e1 = arithmetic_expression e2 = term)
			{
				DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));

				pSub->setAttribute(X("sline"), X(itoa(sub->getLine(),stmp,10)));
				pSub->setAttribute(X("scolumn"), X(itoa(sub->getColumn(),stmp,10)));

				pSub->setAttribute(X("operation"), X("binary"));
				pSub->appendChild(e1);
				pSub->appendChild(e2);
				ast = pSub;
			}
		)
	;

unary_arithmetic_expression returns [DOMElement* ast]
	:
		(#(add:UNARY_PLUS ast = term) 
		{
			DOMElement* pAdd = pModelicaXMLDoc->createElement(X("add"));

			pAdd->setAttribute(X("sline"), X(itoa(add->getLine(),stmp,10)));
			pAdd->setAttribute(X("scolumn"), X(itoa(add->getColumn(),stmp,10)));

			pAdd->setAttribute(X("operation"), X("unary"));
			pAdd->appendChild(ast);
			ast = pAdd;
		}
		|#(sub:UNARY_MINUS ast = term) 
		{ 
			DOMElement* pSub = pModelicaXMLDoc->createElement(X("sub"));
			
			pSub->setAttribute(X("sline"), X(itoa(sub->getLine(),stmp,10)));
			pSub->setAttribute(X("scolumn"), X(itoa(sub->getColumn(),stmp,10)));

			pSub->setAttribute(X("operation"), X("unary"));
			pSub->appendChild(ast);
			ast = pSub;
		}
		| ast = term
		)
	;

term returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
}
	:
		(ast = factor
		|#(mul:STAR e1 = term e2 = factor) 
			{
				DOMElement* pMul = pModelicaXMLDoc->createElement(X("mul"));

				pMul->setAttribute(X("sline"), X(itoa(mul->getLine(),stmp,10)));
				pMul->setAttribute(X("scolumn"), X(itoa(mul->getColumn(),stmp,10)));

				pMul->appendChild(e1);
				pMul->appendChild(e2);
				ast = pMul;
			}
		|#(div:SLASH e1 = term e2 = factor)
			{
				DOMElement* pDiv = pModelicaXMLDoc->createElement(X("div"));

				pDiv->setAttribute(X("sline"), X(itoa(div->getLine(),stmp,10)));
				pDiv->setAttribute(X("scolumn"), X(itoa(div->getColumn(),stmp,10)));

				pDiv->appendChild(e1);
				pDiv->appendChild(e2);
				ast = pDiv;
			}
		)
	;

factor returns [DOMElement* ast]
{
	DOMElement* e1;
	DOMElement* e2;
}
	:
		(ast = primary
		|#(pw:POWER e1 = primary e2 = primary)
			{
				DOMElement* pPow = pModelicaXMLDoc->createElement(X("pow"));

				pPow->setAttribute(X("sline"), X(itoa(pw->getLine(),stmp,10)));
				pPow->setAttribute(X("scolumn"), X(itoa(pw->getColumn(),stmp,10)));

				pPow->appendChild(e1);
				pPow->appendChild(e2);
				ast = pPow;
			}
		)
	;

primary returns [DOMElement* ast]
{
	l_stack* el_stack = new l_stack;
	DOMElement* e;
	DOMElement* exp = 0;
	DOMElement* pSemicolon = pModelicaXMLDoc->createElement(X("semicolon"));
}
	:
		( ui:UNSIGNED_INTEGER 
			{ 
				DOMElement* pIntegerLiteral = pModelicaXMLDoc->createElement(X("integer_literal"));
				pIntegerLiteral->setAttribute(X("value"), str2xml(ui));

				pIntegerLiteral->setAttribute(X("sline"), X(itoa(ui->getLine(),stmp,10)));
				pIntegerLiteral->setAttribute(X("scolumn"), X(itoa(ui->getColumn(),stmp,10)));

				ast = pIntegerLiteral;
			}
		| ur:UNSIGNED_REAL
			{ 
				DOMElement* pRealLiteral = pModelicaXMLDoc->createElement(X("real_literal"));
				pRealLiteral->setAttribute(X("value"), str2xml(ur));

				pRealLiteral->setAttribute(X("sline"), X(itoa(ur->getLine(),stmp,10)));
				pRealLiteral->setAttribute(X("scolumn"), X(itoa(ur->getColumn(),stmp,10)));

				ast = pRealLiteral;
			}
		| str:STRING
			{
				DOMElement* pStringLiteral = pModelicaXMLDoc->createElement(X("string_literal"));
				pStringLiteral->setAttribute(X("value"), str2xml(str));

				pStringLiteral->setAttribute(X("sline"), X(itoa(str->getLine(),stmp,10)));
				pStringLiteral->setAttribute(X("scolumn"), X(itoa(str->getColumn(),stmp,10)));

				ast = pStringLiteral;
			}
		| f:FALSE 
		{ 
			DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
			pBoolLiteral->setAttribute(X("value"), X("false"));

			pBoolLiteral->setAttribute(X("sline"), X(itoa(f->getLine(),stmp,10)));
			pBoolLiteral->setAttribute(X("scolumn"), X(itoa(f->getColumn(),stmp,10)));

			ast = pBoolLiteral;
		}
		| t:TRUE 
		{
			DOMElement* pBoolLiteral = pModelicaXMLDoc->createElement(X("bool_literal"));
			pBoolLiteral->setAttribute(X("value"), X("true"));

			pBoolLiteral->setAttribute(X("sline"), X(itoa(t->getLine(),stmp,10)));
			pBoolLiteral->setAttribute(X("scolumn"), X(itoa(t->getColumn(),stmp,10)));

			ast = pBoolLiteral;
		}
		| ast = component_reference__function_call
		| #(d:DER e = function_call)
            {
				DOMElement* pDer = pModelicaXMLDoc->createElement(X("der"));
				pDer->setAttribute(X("sline"), X(itoa(d->getLine(),stmp,10)));
				pDer->setAttribute(X("scolumn"), X(itoa(d->getColumn(),stmp,10)));
				pDer->appendChild(e);
				ast = pDer;
            }
		| #(LPAR ast = tuple_expression_list)
		| #(lbk:LBRACK  e = expression_list { el_stack->push_back(e); }
				(e = expression_list { el_stack->push_back(e); } )* )
			{
				DOMElement* pConcat = pModelicaXMLDoc->createElement(X("concat"));

				pConcat->setAttribute(X("sline"), X(itoa(lbk->getLine(),stmp,10)));
				pConcat->setAttribute(X("scolumn"), X(itoa(lbk->getColumn(),stmp,10)));

				pConcat = (DOMElement*)appendKidsFromStack(el_stack, pConcat);
				//if (el_stack) delete el_stack;
				ast = pConcat;
			}
		| #(lbr:LBRACE ( (ast = expression_list)
                   | #(FOR_ITERATOR (ast = for_iterator) )))
		{ 
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
		}
		| tend:END 
		{
			DOMElement* pEnd = pModelicaXMLDoc->createElement(X("end"));
			pEnd->setAttribute(X("sline"), X(itoa(tend->getLine(),stmp,10)));
			pEnd->setAttribute(X("scolumn"), X(itoa(tend->getColumn(),stmp,10)));
			ast = pEnd;
		}
		)
	;

component_reference__function_call returns [DOMElement* ast]
{
	DOMElement* cref;
	DOMElement* fnc = 0;
}
	:
		(#(fc:FUNCTION_CALL cref = component_reference (fnc = function_call)?)
			{
				DOMElement* pCall = pModelicaXMLDoc->createElement(X("call"));

				pCall->setAttribute(X("sline"), X(itoa(fc->getLine(),stmp,10)));
				pCall->setAttribute(X("scolumn"), X(itoa(fc->getColumn(),stmp,10)));
		
				pCall->appendChild(cref);
				if (fnc) pCall->appendChild(fnc);
				ast = pCall;
			}
		| cref = component_reference
			{
				if (fnc && cref) cref->appendChild(fnc);
				ast = cref;
			}
		)
		|
		#(ifc:INITIAL_FUNCTION_CALL i:INITIAL )
			{
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
			}
		;
	
name_path returns [void *ast]
{
	void *s1=0;
	void *s2=0;
}
	:
		i:IDENT 
		{
			ast = (void*)new mstring(i->getText()); 
		}
	|#(d:DOT i2:IDENT s2 = name_path)
		{
			s1 = (void*)new mstring(i2->getText());
			ast = (void*)new mstring(mstring(((mstring*)s1)->c_str())+mstring(".")+mstring(((mstring*)s2)->c_str()));
		}
	;

component_reference	returns [DOMElement* ast]
{
	DOMElement* arr = 0;
	DOMElement* id = 0;
}
	:
		(#(i:IDENT (arr = array_subscripts[0])?) 
			{
				DOMElement *pCref = pModelicaXMLDoc->createElement(X("component_reference"));

				pCref->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
				pCref->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

				pCref->setAttribute(X("ident"), str2xml(i));
				if (arr) pCref->appendChild(arr);
				ast = pCref;
			}
		|#(DOT #(i2:IDENT (arr = array_subscripts[0])?)  
				ast = component_reference)
			{
				DOMElement *pCref = pModelicaXMLDoc->createElement(X("component_reference"));
				pCref->setAttribute(X("ident"), str2xml(i2));

				pCref->setAttribute(X("sline"), X(itoa(i2->getLine(),stmp,10)));
				pCref->setAttribute(X("scolumn"), X(itoa(i2->getColumn(),stmp,10)));

				if (arr) pCref->appendChild(arr);
				pCref->appendChild(ast);
				ast = pCref;
			}
		)
	;

function_call returns [DOMElement* ast]
	:
		#(fa:FUNCTION_ARGUMENTS ast = function_arguments
		{
			ast->setAttribute(X("sline"), X(itoa(fa->getLine(),stmp,10)));
			ast->setAttribute(X("scolumn"), X(itoa(fa->getColumn(),stmp,10)));
		}
		)
	;


expression_list2[DOMElement *parent] returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e;
}
	: 
		(#(el:EXPRESSION_LIST 
			e = expression { parent->appendChild(e); }
			(e = expression { parent->appendChild(e); } )*
			)
		)
		{
			ast = parent;
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##function_arguments
*/

function_arguments 	returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e=0;
	DOMElement* namel=0;
	DOMElement *pFunctionArguments = pModelicaXMLDoc->createElement(X("function_arguments"));
}
	:
	  (
	  (pFunctionArguments = expression_list2[pFunctionArguments])?
	  (pFunctionArguments = named_arguments[pFunctionArguments])?
	  {	
			ast = pFunctionArguments;
	  }
	  | #(FOR_ITERATOR ast = for_iterator)
	  )
	;
/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##named_arguments
*/

named_arguments[DOMElement *parent] returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* n;
} 
	:
	#(na:NAMED_ARGUMENTS (n = named_argument { parent->appendChild(n); }) 
	                     (n = named_argument { parent->appendChild(n); } )*)
		{
			ast = parent;
		}
	;

named_argument returns [DOMElement* ast]
{
	DOMElement* temp;
}
	:
		#(eq:EQUALS i:IDENT temp = expression) 
		{
			DOMElement *pNamedArgument = pModelicaXMLDoc->createElement(X("named_argument"));
			pNamedArgument->setAttribute(X("ident"), str2xml(i));

			pNamedArgument->setAttribute(X("sline"), X(itoa(i->getLine(),stmp,10)));
			pNamedArgument->setAttribute(X("scolumn"), X(itoa(i->getColumn(),stmp,10)));

			pNamedArgument->appendChild(temp);
			ast = pNamedArgument;
		}
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##expression_list
*/

expression_list returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e;
	//DOMElement* pComma = pModelicaXMLDoc->createElement(X("comma"));
}
	: 
		(#(el:EXPRESSION_LIST 
			e = expression { el_stack.push_back(e); }
			(e = expression { el_stack.push_back(pModelicaXMLDoc->createElement(X("comma"))); el_stack.push_back(e); } )*
			)
		)
		{
			ast = (DOMElement*)stack2DOMNode(el_stack, "expression_list");

			ast->setAttribute(X("sline"), X(itoa(el->getLine(),stmp,10)));
			ast->setAttribute(X("scolumn"), X(itoa(el->getColumn(),stmp,10)));
		}
	;

tuple_expression_list returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* e;
	//DOMElement* pComma = pModelicaXMLDoc->createElement(X("comma"));
}
	: 
		(#(el:EXPRESSION_LIST 
				e = expression { el_stack.push_back(e); }
				(e = expression { el_stack.push_back(pModelicaXMLDoc->createElement(X("comma"))); el_stack.push_back(e); } )*
			)
		)
		{
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
		}
	;

array_subscripts[int kind] returns [DOMElement* ast]
{
	l_stack el_stack;
	DOMElement* s = 0;
	DOMElement *pArraySubscripts = 0;
	if (kind) 
	  pArraySubscripts = pModelicaXMLDoc->createElement(X("type_array_subscripts"));
	else 
	  pArraySubscripts = pModelicaXMLDoc->createElement(X("array_subscripts"));
}
	:
			#(lbk:LBRACK pArraySubscripts = subscript[pArraySubscripts] 
			(pArraySubscripts = subscript[pArraySubscripts])*)
		{			

			pArraySubscripts->setAttribute(X("sline"), X(itoa(lbk->getLine(),stmp,10)));
			pArraySubscripts->setAttribute(X("scolumn"), X(itoa(lbk->getColumn(),stmp,10)));

			ast = pArraySubscripts; 
		}
	;

subscript[DOMElement* parent] returns [DOMElement* ast]
{
	DOMElement* e;
	DOMElement* pColon = pModelicaXMLDoc->createElement(X("colon"));
}
	: 
		(
			e = expression 
			{
				parent->appendChild(e);
				ast = parent;
			}
		| c:COLON 
			{

				pColon->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
				pColon->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));

				parent->appendChild(pColon);
				ast = parent;
			}
		)
	;

comment returns [DOMElement* ast]
{
	DOMElement* ann=0;
	DOMElement* cmt=0;
    ast = 0;
	DOMElement *pComment = pModelicaXMLDoc->createElement(X("comment"));
	bool bAnno = false;
}		:
#(c:COMMENT cmt=string_comment { if (cmt) pComment->appendChild(cmt); } 
(pComment = annotation [0 /* none */, pComment, INSIDE_COMMENT] { bAnno = true; })?)
		{
			if (c)
			{
				pComment->setAttribute(X("sline"), X(itoa(c->getLine(),stmp,10)));
				pComment->setAttribute(X("scolumn"), X(itoa(c->getColumn(),stmp,10)));
			}
			if ((cmt !=0) || bAnno) ast = pComment;
			else ast = 0;
		}
	;

string_comment returns [DOMElement* ast] :
	{
	  DOMElement* cmt=0;
	  ast = 0;	   
	}
		#(sc:STRING_COMMENT cmt=string_concatenation)
		{
			DOMElement *pStringComment = pModelicaXMLDoc->createElement(X("string_comment"));

			pStringComment->setAttribute(X("sline"), X(itoa(sc->getLine(),stmp,10)));
			pStringComment->setAttribute(X("scolumn"), X(itoa(sc->getColumn(),stmp,10)));

			pStringComment->appendChild(cmt);
			ast = pStringComment;
		}
	|
		{
			ast = 0;
		}
	;

string_concatenation returns [DOMElement* ast] 
	{
		DOMElement*pString1;
		l_stack el_stack;
	}
:
        s:STRING 
		  {
			DOMElement *pString = pModelicaXMLDoc->createElement(X("string_literal"));
			pString->setAttribute(X("value"), str2xml(s));

			pString->setAttribute(X("sline"), X(itoa(s->getLine(),stmp,10)));
			pString->setAttribute(X("scolumn"), X(itoa(s->getColumn(),stmp,10)));

	  		ast=pString;
		  }
		|#(p:PLUS pString1=string_concatenation s2:STRING)
		  {
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
		  }
	;

/*
http://www.ida.liu.se/~adrpo/modelica/xml/modelicaxml-v2.html##annotation
*/

annotation[int iSwitch, DOMElement *parent, enum anno awhere] returns [DOMElement* ast]
{
    void* cmod=0;
}
    :
        #(a:ANNOTATION cmod = class_modification)
        {
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
        }
    ;		


interactive_stmt returns [DOMElement* ast]
{ 
    DOMElement* al=0; 
    DOMElement* el=0;
	l_stack el_stack;	
    DOMElement *pInteractiveSTMT = pModelicaXMLDoc->createElement(X("ISTMT"));
	DOMElement *pInteractiveALG = pModelicaXMLDoc->createElement(X("IALG"));
}
    :
		(
			#(INTERACTIVE_ALG (pInteractiveALG = algorithm[pInteractiveALG]) )
			{				
				//pInteractiveALG->appendChild(al);
				el_stack.push_back(pInteractiveALG);
			}	
		|	
			#(INTERACTIVE_EXP (el = expression ))
			{
				DOMElement *pInteractiveEXP = pModelicaXMLDoc->createElement(X("IEXP"));
				pInteractiveEXP->appendChild(el);
				el_stack.push_back(pInteractiveEXP);
			}
			
		)* (s:SEMICOLON)?
		{			
			pInteractiveSTMT = (DOMElement*)appendKids(el_stack, pInteractiveSTMT);
			if (s) pInteractiveSTMT->setAttribute(X("semicolon"),X("true"));
			ast = pInteractiveSTMT;
		}
	;
