/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package DAE
" file:	 DAE.mo
  package:      DAE
  description: DAE management and output
 
  RCS: $Id$
  
  This module defines data structures for DAE equations and 
  declarations of variables and functions. It also exports some help
  functions for other modules. The DAE data structure is the result of
  flattening, containing only flat modelica, i.e. equations, algorithms,
  variables and functions. 
 
  

  - Module header"

public import Absyn;
public import Exp;
public import Algorithm;
public import Types;
public import Values;
public import ClassInf;
public import Env;

public 
type Ident = String;

public 
type InstDims = list<Exp.Subscript>;

public 
type StartValue = Option<Exp.Exp>;
  
public constant String UNIQUEIO = "$unique$outer$";
  

public 
uniontype VarKind
  record VARIABLE end VARIABLE;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;

end VarKind;

public 
uniontype Type
  record REAL end REAL;

  record INT end INT;

  record BOOL end BOOL;

  record STRING end STRING;

  record ENUM end ENUM;

  record LIST end LIST; // MetaModelica list. KS
  
  record METATUPLE end METATUPLE;  // MetaModelica tuple. KS

  record METAOPTION end METAOPTION;  // MetaModelica option. KS

  record UNIONTYPE end UNIONTYPE; // MetaModelica UnionType. added by simbj
  
  record METARECORD end METARECORD; //MetaModelica extension, added by simbj
  
  record POLYMORPHIC end POLYMORPHIC; // Used in MetaModelica polymorphic function. sjoelund
  
  record FUNCTION_REFERENCE end FUNCTION_REFERENCE; // MetaModelica Partial Function. sjoelund
  
  record ENUMERATION
    list<String> stringLst;
  end ENUMERATION;
  
  record EXT_OBJECT
    Absyn.Path fullClassName;
  end EXT_OBJECT;  
  
  record COMPLEX
    Absyn.Path name;
    list<Var> varLst;
  end COMPLEX;
end Type;

public 
uniontype Var "a variable in a complex type"
  record TVAR 
    String name;
    Type tp;
  end TVAR;
end Var;

public 
uniontype Flow "The Flow of a variable indicates if it is a Flow variable or not, or if
   it is not a connector variable at all."
  record FLOW end FLOW;
 
  record NON_FLOW end NON_FLOW;

  record NON_CONNECTOR end NON_CONNECTOR;

end Flow;

public 
uniontype Stream "The Stream of a variable indicates if it is a Stream variable or not, or if
   it is not a connector variable at all."
  record STREAM end STREAM;

  record NON_STREAM end NON_STREAM;

  record NON_STREAM_CONNECTOR end NON_STREAM_CONNECTOR;
    
end Stream;


public
uniontype VarDirection
  record INPUT end INPUT;

  record OUTPUT end OUTPUT;

  record BIDIR end BIDIR;

end VarDirection;

uniontype VarProtection
  record PUBLIC "public variables" end PUBLIC; 
  record PROTECTED "protected variables" end PROTECTED;
end VarProtection;

public 
uniontype Element
  record VAR 
    Exp.ComponentRef componentRef " The variable name";
    VarKind kind "varible kind: variable, constant, parameter, discrete etc." ;
    VarDirection direction "input, output or bidir" ;
    VarProtection protection "if protected or public";
    Type ty "one of the builtin types" ;
    Option<Exp.Exp> binding "Binding expression e.g. for parameters ; value of start attribute" ; 
    InstDims  dims "dimensions";
    Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
    Stream streamPrefix "Stream variables in connectors" ;
    list<Absyn.Path> pathLst " " ;
    Option<VariableAttributes> variableAttributesOption;
    Option<Absyn.Comment> absynCommentOption;
    Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
    Types.Type fullType "Full type information required to analyze inner/outer elements";
  end VAR;

  record DEFINE "A solved equation"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end DEFINE;

  record INITIALDEFINE " A solved initial equation"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end INITIALDEFINE;
  
  record EQUATION "Scalar equation"
    Exp.Exp exp;
    Exp.Exp scalar ;
  end EQUATION;

  record EQUEQUATION "effort variable equality"
    Exp.ComponentRef cr1;
    Exp.ComponentRef cr2;
  end EQUEQUATION;

  record ARRAY_EQUATION " an array equation"
    list<Integer> dimension "dimension sizes" ;
    Exp.Exp exp;
    Exp.Exp array  ;
  end ARRAY_EQUATION;

  record COMPLEX_EQUATION "an equation of complex type, e.g. record = func(..)"
    Exp.Exp lhs;
    Exp.Exp rhs;
  end COMPLEX_EQUATION;
  
  record INITIAL_COMPLEX_EQUATION "an initial equation of complex type, e.g. record = func(..)"
    Exp.Exp lhs;
    Exp.Exp rhs;
  end INITIAL_COMPLEX_EQUATION;
  
  
  record WHEN_EQUATION " a when equation"
    Exp.Exp condition "Condition" ;
    list<Element> equations "Equations" ;
    Option<Element> elsewhen_ "Elsewhen should be of type WHEN_EQUATION" ;
  end WHEN_EQUATION;

  record IF_EQUATION " an if-equation"
    list<Exp.Exp> condition1 "Condition" ;
    list<list<Element>> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
  end IF_EQUATION;

  record INITIAL_IF_EQUATION "An initial if-equation"
    list<Exp.Exp> condition1 "Condition" ;
    list<list<Element>> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
  end INITIAL_IF_EQUATION;

  record INITIALEQUATION " An initial equaton"
    Exp.Exp exp1;
    Exp.Exp exp2;
  end INITIALEQUATION;

  record ALGORITHM " An algorithm section"
    Algorithm.Algorithm algorithm_;
  end ALGORITHM;

  record INITIALALGORITHM " An initial algorithm section"
    Algorithm.Algorithm algorithm_;
  end INITIALALGORITHM;

  record COMP
    Ident ident;
    DAElist dAElist "a component with 
						    subelements, normally 
						    only used at top level." ;
  end COMP;

  record FUNCTION " A Modelica function"
    Absyn.Path path;
    DAElist dAElist;
    Types.Type type_;
    Boolean partialPrefix "MetaModelica extension";
  end FUNCTION;

  record EXTFUNCTION "An external function"
    Absyn.Path path;
    DAElist dAElist;
    Types.Type type_;
    ExternalDecl externalDecl;
  end EXTFUNCTION;
  
  record EXTOBJECTCLASS "The 'class' of an external object"
    Absyn.Path path "className of external object";
    Element constructor "constructor is an EXTFUNCTION";
    Element destructor "destructor is an EXTFUNCTION";
  end EXTOBJECTCLASS;
  
  record ASSERT " The Modelica builtin assert"
    Exp.Exp condition;
    Exp.Exp message;
  end ASSERT;

  record TERMINATE " The Modelica builtin terminate(msg)"
    Exp.Exp message;
  end TERMINATE;

  record REINIT " reinit operator for reinitialization of states"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end REINIT;

   record NORETCALL "call with no return value, i.e. no equation. 
	   Typically sideeffect call of external function."  
     Absyn.Path functionName;
     list<Exp.Exp> functionArgs;
   end NORETCALL;
end Element;

public 
uniontype VariableAttributes
  record VAR_ATTR_REAL
    Option<Exp.Exp> quantity "quantity" ;
    Option<Exp.Exp> unit "unit" ;
    Option<Exp.Exp> displayUnit "displayUnit" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> nominal "nominal" ;
    Option<StateSelect> stateSelectOption;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_REAL;

  record VAR_ATTR_INT
    Option<Exp.Exp> quantity "quantity" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected; // ,eb,ip
    Option<Boolean> finalPrefix;
  end VAR_ATTR_INT;

  record VAR_ATTR_BOOL
    Option<Exp.Exp> quantity "quantity" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_BOOL;

  record VAR_ATTR_STRING
    Option<Exp.Exp> quantity "quantity" ;
    Option<Exp.Exp> initial_ "Initial value" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_STRING;

  record VAR_ATTR_ENUMERATION
    Option<Exp.Exp> quantity "quantity" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> start "start" ;
    Option<Exp.Exp> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Exp.Exp> equationBound;
    Option<Boolean> isProtected;
    Option<Boolean> finalPrefix;
  end VAR_ATTR_ENUMERATION;

end VariableAttributes;

public function addEquationBoundString "" 
  input Exp.Exp bindExp;
  input Option<VariableAttributes> attr;
  output Option<VariableAttributes> oattr;
algorithm oattr :=
matchcontinue (bindExp,attr)
    local
     	Option<Exp.Exp> e1,e2,e3,e4,e5,e6;
    	tuple<Option<Exp.Exp>, Option<Exp.Exp>> min;
      Option<StateSelect> sSelectOption,sSelectOption2;
      Option<Boolean> ip,fn;
      String s;
  case (bindExp,SOME(VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,_,ip,fn)))
    then (SOME(VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,SOME(bindExp),ip,fn))); 
  case (bindExp,SOME(VAR_ATTR_INT(e1,min,e2,e3,_,ip,fn)))
    then SOME(VAR_ATTR_INT(e1,min,e2,e3,SOME(bindExp),ip,fn));
  case (bindExp,SOME(VAR_ATTR_BOOL(e1,e2,e3,_,ip,fn)))	    
    then SOME(VAR_ATTR_BOOL(e1,e2,e3,SOME(bindExp),ip,fn));
  case (bindExp,SOME(VAR_ATTR_STRING(e1,e2,_,ip,fn)))
    then SOME(VAR_ATTR_STRING(e1,e2,SOME(bindExp),ip,fn));
  case(_,_) equation print("-failur DAE.add_Equation_Bound_String\n"); then fail();
   end matchcontinue;
end addEquationBoundString;

public function getClassList "get list of classes from Var"
  input Element v;
  output list<Absyn.Path> lst;
algorithm
  lst := matchcontinue(v)
    case(VAR(pathLst = lst)) then lst;
    case(_) then {};
  end matchcontinue;
end getClassList;

public function getBoundStartEquation ""
input VariableAttributes attr;
output Exp.Exp oe;
algorithm oe := matchcontinue(attr)
  local Exp.Exp beq;
  case (VAR_ATTR_REAL(equationBound = SOME(beq))) then beq; 
  case (VAR_ATTR_INT(equationBound = SOME(beq))) then beq; 
  case (VAR_ATTR_BOOL(equationBound = SOME(beq))) then beq; 
  case (VAR_ATTR_ENUMERATION(equationBound = SOME(beq))) then beq; 
end matchcontinue;
end getBoundStartEquation;

public 
uniontype StateSelect
  record NEVER end NEVER;

  record AVOID end AVOID;

  record DEFAULT end DEFAULT;

  record PREFER end PREFER;

  record ALWAYS end ALWAYS;

end StateSelect;

public 
uniontype ExtArg
  record EXTARG
    Exp.ComponentRef componentRef;
    Types.Attributes attributes;
    Types.Type type_;
  end EXTARG;

  record EXTARGEXP
    Exp.Exp exp;
    Types.Type type_;
  end EXTARGEXP;

  record EXTARGSIZE
    Exp.ComponentRef componentRef;
    Types.Attributes attributes;
    Types.Type type_;
    Exp.Exp exp;
  end EXTARGSIZE;

  record NOEXTARG end NOEXTARG;

end ExtArg;

public 
uniontype ExternalDecl
  record EXTERNALDECL
    Ident ident;
    list<ExtArg> external_ "external function name" ;
    ExtArg parameters "parameters" ;
    String returnType "return type" ;
    Option<Absyn.Annotation> language "language e.g. Library" ;
  end EXTERNALDECL;

end ExternalDecl;

public 
uniontype DAElist "A DAElist is a list of Elements. Variables, equations, functions, 
  algorithms, etc. are all found in this list.
"
  record DAE
    list<Element> elementLst;
  end DAE;

end DAElist;

protected import RTOpts;
protected import Graphviz;
protected import Dump;
protected import Print;
protected import Util;
protected import Ceval;
protected import ModUtil;
protected import Debug;
protected import Error;
protected import SCode;
protected import System;

public function removeEquations "Removes all equations and algorithms, from the dae"
	input list<Element> inDae;
	output list<Element> outDaeNonEq;
	output list<Element> outDaeEq;
algorithm
	inDae := matchcontinue(inDae)
	  local Element v,e;
	    list<Element> elts,elts2,elts22,elts1,elts11,elts3,elts33;
	    Ident  id;
	  case({}) then  ({},{});
	    
	  case((v as VAR(componentRef=_))::elts) equation
	    (elts2,elts3)=removeEquations(elts);
	  then (v::elts2,elts3);
	  case(COMP(id,DAE(elts1))::elts2) equation
	    (elts11,elts3) = removeEquations(elts1);
	    (elts22,elts33) = removeEquations(elts2);
	    elts3 = listAppend(elts3,elts33);
	  then (COMP(id,DAE(elts11))::elts22,elts3);
	  case((e as EQUATION(_,_))::elts2)
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as EQUEQUATION(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as INITIALEQUATION(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as ARRAY_EQUATION(_,_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as COMPLEX_EQUATION(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as INITIAL_COMPLEX_EQUATION(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as INITIALDEFINE(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    
	  case((e as DEFINE(_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    
	  case((e as WHEN_EQUATION(_,_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    
	  case((e as IF_EQUATION(_,_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    	    
	  case((e as INITIAL_IF_EQUATION(_,_,_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    	    	    	    
	  case((e as ALGORITHM(_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as INITIALALGORITHM(_))::elts2)  
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as FUNCTION(path=_))::elts2) equation
	    (elts22,elts3) = removeEquations(elts2);
    then (e::elts22,elts3);
	  case((e as EXTFUNCTION(path=_))::elts2) equation
	    (elts22,elts3) = removeEquations(elts2);
    then (e::elts22,elts3);  
	  case((e as EXTOBJECTCLASS(path=_))::elts2) equation
	    (elts22,elts3) = removeEquations(elts2);
    then (e::elts22,elts3);	            
	  case((e as ASSERT(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);
	  case((e as REINIT(_,_))::elts2) 
	    equation
	      (outDaeNonEq,outDaeEq) = removeEquations(elts2);
	    then (outDaeNonEq,e::outDaeEq);	    
	end matchcontinue;  
  
end removeEquations;

public function removeVariables "Remove the variables in the list from the DAE"
  input list<Element> dae;
  input list<Exp.ComponentRef> vars;
  output list<Element> outDae;
algorithm
  outDae := Util.listFold(vars,removeVariable,dae);
end removeVariables;

public function removeVariable "Remove the variable from the DAE"
  input Exp.ComponentRef var;
  input list<Element> dae;
  output list<Element> outDae;
algorithm
   outDae := matchcontinue(var,dae)
   			local Exp.ComponentRef cr;
   			  list<Element> elist,elist2;
   			  Element e,v;
   			  Ident id;
     case(var,{}) then {};
     case(var,(v as VAR(componentRef = cr))::dae) equation
       true = Exp.crefEqual(var,cr);
     then dae;
     case(var,COMP(id,DAE(elist))::dae) equation
       elist2=removeVariable(var,elist);
       dae = removeVariable(var,dae);
     then COMP(id,DAE(elist2))::dae;
     case(var,e::dae) equation
         dae = removeVariable(var,dae);
      then e::dae;        
   end matchcontinue;
end removeVariable;

public function removeInnerAttrs "Remove the inner attribute of all vars in list"
  input list<Element> dae;
  input list<Exp.ComponentRef> vars;
  output list<Element> outDae;
algorithm
  outDae := Util.listFold(vars,removeInnerAttr,dae);
end removeInnerAttrs;

public function removeInnerAttr "Remove the inner attribute from variable in the DAE"
  input Exp.ComponentRef var;
  input list<Element> dae;
  output list<Element> outDae;
algorithm
   outDae := matchcontinue(var,dae)
   			local Exp.ComponentRef cr,oldVar,newVar;
   			  list<Element> elist,elist2,elist3;
   			  Element e,v,u,o;
   			  Ident id;
   			  Exp.ComponentRef cr;
   			  VarKind kind;
   			  VarDirection dir;
    			Type tp;
   			  Option<Exp.Exp> bind;
   			  InstDims dim;
    			Flow flow_;
   			  list<Absyn.Path> cls;
    			Option<VariableAttributes> attr;
   			  Option<Absyn.Comment> cmt;
    			Absyn.InnerOuter io,io2;
   			  Types.Type ftp;
   			  VarProtection prot;
   			  Stream st;
     case(var,{}) then {};
     /* When having an inner outer, we declare two variables on the same line. 
        Since we can not handle this with current instantiation procedure, we create temporary variables in the dae.
        These are named uniqly and renamed later in "instClass" 
     */ 
     case(var,VAR(oldVar,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,(io as Absyn.INNEROUTER()),ftp)::dae) equation
       true = compareUniquedVarWithNonUnique(var,oldVar);
       newVar = nameInnerouterUniqueCref(oldVar);
       o = VAR(oldVar,kind,dir,prot,tp,NONE,dim,flow_,st,cls,attr,cmt,Absyn.OUTER(),ftp) "intact";
       u = VAR(newVar,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,Absyn.UNSPECIFIED(),ftp) " unique'ified";
       elist3 = u::{o};
       dae = listAppend(elist3,dae);
     then 
       dae;
         
     case(var,VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,io,ftp)::dae) equation
       true = Exp.crefEqual(var,cr);
       io2 = removeInnerAttribute(io);
     then 
       VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,cls,attr,cmt,io2,ftp)::dae;
       
     case(var,COMP(id,DAE(elist))::dae) equation
       elist2=removeInnerAttr(var,elist);
       dae = removeInnerAttr(var,dae);
     then COMP(id,DAE(elist2))::dae;
     case(var,e::dae) equation
         dae = removeInnerAttr(var,dae);
      then e::dae;        
   end matchcontinue;
end removeInnerAttr;

protected function compareUniquedVarWithNonUnique "
Author: BZ, workaround to get innerouter elements to work.
This function strips the 'unique identifer' from the cref and compares.
"
input Exp.ComponentRef cr1;
input Exp.ComponentRef cr2;
output Boolean equal;
String s1,s2,s3;
algorithm
  s1 := Exp.printComponentRefStr(cr1);
  s2 := Exp.printComponentRefStr(cr2);
  s1 := System.stringReplace(s1, UNIQUEIO, "");
  s2 := System.stringReplace(s2, UNIQUEIO, "");
  equal := stringEqual(s1,s2);
end compareUniquedVarWithNonUnique;

public function nameInnerouterUniqueCref "
Author: BZ, 2008-11
Renames a var to unique name
"
  input Exp.ComponentRef inCr;
  output Exp.ComponentRef outCr;
algorithm outCr := matchcontinue(inCr)
  local
    Exp.ComponentRef newChild,child;
    String id;
    Exp.Type idt;
    list<Exp.Subscript> subs;
  case(Exp.CREF_IDENT(id,idt,subs))
    equation
      id = UNIQUEIO +& id;
    then
      Exp.CREF_IDENT(id,idt,subs);
  case(Exp.CREF_QUAL(id,idt,subs,child))
    equation
      newChild = nameInnerouterUniqueCref(child);      
    then
      Exp.CREF_QUAL(id,idt,subs,newChild);
      
end matchcontinue;
end nameInnerouterUniqueCref;

public function unNameInnerouterUniqueCref ""
input Exp.ComponentRef cr;
input String removalString;
output Exp.ComponentRef ocr;
algorithm ocr := matchcontinue(cr,removalString)
  local
    String str,str2;
    Exp.Type ty;
    Exp.ComponentRef child,child_2;
    list<Exp.Subscript> subs;
  case(Exp.CREF_IDENT(str,ty,subs),removalString)
    equation
      str2 = System.stringReplace(str, removalString, "");
      then
        Exp.CREF_IDENT(str2,ty,subs);
  case(Exp.CREF_QUAL(str,ty,subs,child),removalString)
    equation
      child_2 = unNameInnerouterUniqueCref(child,removalString);
      str2 = System.stringReplace(str, removalString, "");
    then
      Exp.CREF_QUAL(str2,ty,subs,child_2);
  case(Exp.WILD(),_) then Exp.WILD(); 
  case(child,_) 
    equation 
      print(" failure unNameInnerouterUniqueCref: ");
      print(Exp.printComponentRefStr(child) +& "\n"); 
      then fail(); 
  end matchcontinue;
end unNameInnerouterUniqueCref;
protected function getOuterBinding "
Author: BZ, 2008-11
Aquire the binding on the outer/innerouter variable, to transfer to inner variable.
"
input Exp.ComponentRef currVar;
input list<tuple<Exp.ComponentRef, Exp.Exp>> inlst;
output Option<Exp.Exp> binding;
algorithm binding := matchcontinue(currVar,inlst)
  local Exp.ComponentRef cr1,cr2; Exp.Exp e;
  case(_,{}) then NONE; 
  case(cr1,(cr2,e)::inlst)
    equation
      true = Exp.crefEqual(cr1,cr2);
      then
        SOME(e);
  case(cr1,(_,_)::inlst) then getOuterBinding(cr1,inlst);
  end matchcontinue;
end getOuterBinding;

protected function removeInnerAttribute "Help function to removeInnerAttr"
	 input Absyn.InnerOuter io;
	 output Absyn.InnerOuter ioOut;
algorithm
  ioOut := matchcontinue(io)
    case(Absyn.INNER()) then Absyn.UNSPECIFIED();
    case(Absyn.INNEROUTER()) then Absyn.OUTER();
    case(io) then io;
  end matchcontinue;
end removeInnerAttribute;

public function varCref " returns the component reference of a variable"
input Element elt;
output Exp.ComponentRef cr;
algorithm
  cr := matchcontinue(elt)
    case(VAR(componentRef = cr)) then cr;
  end matchcontinue;
end varCref;

public function printDAE "function: printDAE
 
  This function prints out a list of elements (i.e. a DAE)
  to the stdout. Useful for example when called from Inst.instClass"
  input DAElist inDAElist;
algorithm  
  _:=
  matchcontinue (inDAElist)
    local
    	DAElist dae;
    	String str;
    case dae 
      equation
        Print.clearBuf();
        dump2(dae);
        str = Print.getString();
        print(str);
      then 
        ();
  end matchcontinue;
end printDAE;        


public function dump "function: dump
 
  This function prints the DAE in the standard output format.
"
  input DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local list<Element> daelist;
    case DAE(elementLst = daelist)
      equation 
        Util.listMap0(daelist, dumpFunction);
        Util.listMap0(daelist, dumpExtObjectClass);
        Util.listMap0(daelist, dumpCompElement);
      then
        ();
  end matchcontinue;
end dump;

public function dump2str ""
input DAElist inDAElist;
output String str;
algorithm 
  dump2(inDAElist);
  str := Print.getString();
  Print.clearBuf();
end dump2str;

public function dump2 "function: dump2
 
  Helper function to dump. Prints the DAE using module Print.
"
  input DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local
      Ident comment_str,ident,str,extdeclstr,s1;
      Exp.ComponentRef cr;
      Exp.Exp e,e1,e2;
      InstDims dims;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<Element> xs;
      DAElist lst,dae;
      Absyn.Path path;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      ExternalDecl extdecl;
    case DAE(elementLst = (VAR(componentRef = cr,
                               binding = SOME(e),
                               dims = dims,
                               variableAttributesOption = dae_var_attr,
                               absynCommentOption = comment) :: xs))
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        
        /* //include type of var 
        
        s1 = Exp.debugPrintComponentRefTypeStr(cr); 
        s1 = Util.stringReplaceChar(s1,"\n","");
        Print.printBuf("((" +& s1);        
        Print.printBuf("))");
        */
        Print.printBuf("=");
        Exp.printExp(e);
        Print.printBuf(",dims=");
        Dump.printList(dims, Exp.printSubscript, ", ");
        comment_str = Dump.unparseCommentOption(comment) "	dump_start_value start &" ;
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        Print.printBuf(", ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (VAR(componentRef = cr,binding = NONE,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: xs))
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        /* // include type in dump
        s1 = Exp.debugPrintComponentRefTypeStr(cr); 
        s1 = Util.stringReplaceChar(s1,"\n","");
        Print.printBuf("((" +& s1);
        Print.printBuf("))");
        */
        comment_str = Dump.unparseCommentOption(comment) "	dump_start_value start &" ;
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        Print.printBuf(", ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (DEFINE(componentRef = cr) :: xs))
      equation 
        Print.printBuf("DEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (INITIALDEFINE(componentRef = cr) :: xs))
      equation 
        Print.printBuf("INITIALDEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (EQUATION(exp = e1,scalar = e2) :: xs))
      equation 
        Print.printBuf("EQUATION(");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation 
        Print.printBuf("INITIALEQUATION(");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (ALGORITHM(algorithm_ = _) :: xs)))
      equation 
        Print.printBuf("ALGORITHM(...)");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (INITIALALGORITHM(algorithm_ = _) :: xs)))
      equation 
        Print.printBuf("INITIALALGORITHM(...)");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (COMP(ident = ident,dAElist = lst) :: xs)))
      equation 
        Print.printBuf("COMP(");
        Print.printBuf(ident);
        dump2(lst);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (FUNCTION(path = _) :: xs)))
      equation 
        Print.printBuf("FUNCTION(...)\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (EXTFUNCTION(path = path,dAElist = dae,type_ = tp,externalDecl = extdecl) :: xs)))
      equation 
        Print.printBuf("EXTFUNCTION(\n");
        str = Absyn.pathString(path);
        Print.printBuf(str);
        Print.printBuf(", ");
        dump2(dae);
        Print.printBuf(", ");
        Print.printBuf(Types.printTypeStr(tp));
        Print.printBuf(", ");
        extdeclstr = dumpExtDeclStr(extdecl);
        Print.printBuf(extdeclstr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (ASSERT(condition=e1,message=e2) :: xs)))
      equation 
        Print.printBuf("ASSERT(\n");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = {})) then (); 
    case (_)
      equation
        Print.printBuf("dump2 failed\n");
      then
        ();
  end matchcontinue;
end dump2;

protected function dumpStartValue "function: dumpStartValue
 
  Dumps the StartValue for a variable.
"
  input StartValue inStartValue;
algorithm 
  _:=
  matchcontinue (inStartValue)
    local Exp.Exp e;
    case (SOME(e))
      equation 
        Print.printBuf("(start=");
        Exp.printExp(e);
        Print.printBuf(")");
      then
        ();
    case (_) then (); 
  end matchcontinue;
end dumpStartValue;

public function dumpStartValueStr "function: dumpStartValueStr
 
  Dumps the start value for a variable to a string.
"
  input StartValue inStartValue;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStartValue)
    local
      Ident s,res;
      Exp.Exp e;
    case (SOME(e))
      equation 
        s = Exp.printExpStr(e);
        res = Util.stringAppendList({"(peterstart=",s,")"});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end dumpStartValueStr;

public function dumpExtDeclStr "function: dumpExtDeclStr
 
  Dumps the external declaration to a string.
"
  input ExternalDecl inExternalDecl;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExternalDecl)
    local
      Ident extargsstr,rettystr,str,id,lang;
      list<ExtArg> extargs;
      ExtArg retty;
      Option<Absyn.Annotation> ann;
    case EXTERNALDECL(ident = id,external_ = extargs,parameters = retty,returnType = lang,language = ann)
      equation 
        extargsstr = Dump.getStringList(extargs, dumpExtArgStr, ",");
        rettystr = dumpExtArgStr(retty);
        str = Util.stringAppendList(
          {"EXTERNALDECL(",id,", (",extargsstr,"), ",rettystr,", \"",
          lang,"\")"});
      then
        str;
  end matchcontinue;
end dumpExtDeclStr;

public function dumpExtArgStr "function: dumpExtArgStr
 
  Helper function to dump_ext_decl_str
"
  input ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Ident crstr,dirstr,tystr,str,dimstr;
      Exp.ComponentRef cr;
      Boolean fl,st;      
      SCode.Accessibility acc;
      SCode.Variability var;
      Absyn.Direction dir;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp exp,dim;
      Types.Attributes attr;
    case NOEXTARG() then "void"; 
    case EXTARG(componentRef = cr,attributes = Types.ATTR(flowPrefix = fl,streamPrefix=st,accessibility = acc,parameter_ = var,direction = dir),type_ = ty)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        dirstr = Dump.directionSymbol(dir);
        tystr = Types.getTypeName(ty);
        str = Util.stringAppendList({dirstr," ",tystr," ",crstr});
      then
        str;
    case EXTARGEXP(exp = exp,type_ = ty)
      equation 
        crstr = Exp.printExpStr(exp);
        tystr = Types.getTypeName(ty);
        str = Util.stringAppendList({"(",tystr,") ",crstr});
      then
        str;
    case EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
  end matchcontinue;
end dumpExtArgStr;

public function dumpStr "function: dumpStr
  
  This function prints the DAE to a string.
"
  input DAElist inDAElist;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDAElist)
    local
      list<Ident> flist,clist,slist,extlist;
      Ident str;
      list<Element> daelist;
    case DAE(elementLst = daelist)
      equation 
        flist = Util.listMap(daelist, dumpFunctionStr);
        extlist = Util.listMap(daelist, dumpExtObjClassStr);
        clist = Util.listMap(daelist, dumpCompElementStr);
        slist = Util.listFlatten({flist,extlist, clist});
        str = Util.stringAppendList(slist);
      then
        str;
  end matchcontinue;
end dumpStr;

protected function dumpCompElement "function: dumpCompElement
 
  Dumps Component elements.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Ident n;
      list<Element> l;
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        false = RTOpts.modelicaOutput();
        Print.printBuf("fclass ");
        Print.printBuf(n);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        true = RTOpts.modelicaOutput();
        Print.printBuf("class ");
        Print.printBuf(n);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case _ then ();  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */ 
  end matchcontinue;
end dumpCompElement;

protected function dumpCompElementStr "function: dumpCompElementStr
 
  Dumps components to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,s2,s3,s4,s5,s6,str,n;
      list<Element> l;
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        false = RTOpts.modelicaOutput();
        s1 = stringAppend("fclass ", n);
        s2 = stringAppend(s1, "\n");
        s3 = dumpElementsStr(l);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, "end ");
        s6 = stringAppend(s5, n);
        str = stringAppend(s6, ";\n");
      then
        str;
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        true = RTOpts.modelicaOutput();
        s1 = stringAppend("class ", n);
        s2 = stringAppend(s1, "\n");
        s3 = dumpElementsStr(l);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, "end ");
        s6 = stringAppend(s5, n);
        str = stringAppend(s6, ";\n");
      then
        str;
    case _ then "";  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */ 
  end matchcontinue;
end dumpCompElementStr;

public function dumpElements "function: dumpElements
 
  Dump elements. 
"
  input list<Element> l;
algorithm 
  dumpVars(l);
  Util.listMap0(l, dumpExtObjectClass);
  Print.printBuf("initial equation\n");
  Util.listMap0(l, dumpInitialequation);
  Print.printBuf("equation\n");
  Util.listMap0(l, dumpEquation);
  Util.listMap0(l, dumpInitialalgorithm);
  Util.listMap0(l, dumpAlgorithm);
  Util.listMap0(l, dumpCompElement);
  
end dumpElements;

public function dumpElementsStr "function: dumpElementsStr
 
  Dump elements to a string
"
  input list<Element> l;
  output String str;
  Ident s0,s1,s2,s3,s4,s5,initeqstr,initalgstr,eqstr,algstr;
  Boolean noiniteq,noinitalg,noeq,noalg;
algorithm 
  s1 := dumpVarsStr(l);
  s2 := dumpInitialequationsStr(l);
  s3 := dumpEquationsStr(l);
  s4 := dumpInitialalgorithmsStr(l);
  s5 := dumpAlgorithmsStr(l);
  noiniteq := stringEqual(s2, "");
  noinitalg := stringEqual(s4, "");
  noeq := stringEqual(s3, "");
  noalg := stringEqual(s5, "");
  initeqstr := Dump.selectString(noiniteq, "", "initial equation\n");
  initalgstr := Dump.selectString(noinitalg, "", "initial algorithm\n");
  eqstr := Dump.selectString(noeq, "", "equation\n");
  algstr := Dump.selectString(noalg, "", "algorithm\n");
  s0 := Util.stringDelimitListNonEmptyElts(Util.listMap(l,dumpExtObjClassStr),"\n");
  str := Util.stringAppendList({s0,s1,initeqstr,s2,initalgstr,s4,eqstr,s3,algstr,s5});
end dumpElementsStr;

public function dumpAlgorithmsStr "function: dumpAlgorithmsStr
 
  Dump algorithms to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,str;
      list<Algorithm.Statement> stmts;
      list<Element> xs;
    case ((ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts)) :: xs))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        s2 = stringAppend("algorithm\n", s1);
        s3 = dumpAlgorithmsStr(xs);
        str = stringAppend(s1, s3);
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpAlgorithmsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpAlgorithmsStr;

protected function dumpInitialalgorithmsStr "function: dumpInitialalgorithmsStr
 
  Dump initialalgorithms to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,str;
      list<Algorithm.Statement> stmts;
      list<Element> xs;
    case ((INITIALALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts)) :: xs))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        s2 = stringAppend("algorithm\n", s1);
        s3 = dumpInitialalgorithmsStr(xs);
        str = stringAppend(s1, s3);
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpInitialalgorithmsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpInitialalgorithmsStr;

protected function dumpEquationsStr "function: dumpEquationsStr
 
  Dump equations to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,s4,s4_1,s5,s6,str,s;
      Exp.Exp e1,e2,e;
      list<Element> xs,xs1,xs2;
      list<list<Element>> tb;
      Exp.ComponentRef c,cr,cr1,cr2;
    case ((EQUATION(exp = e1,scalar = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
        
      case ((EQUEQUATION(cr1,cr2) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(cr1)+&" = "+&Exp.printComponentRefStr(cr2)+&";\n";
        s2 = dumpEquationsStr(xs);
        str = s1+&s2;
      then
        str;
    case ((ARRAY_EQUATION(exp = e1,array = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((COMPLEX_EQUATION(lhs = e1,rhs= e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;        
    case ((DEFINE(componentRef = c,exp = e) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((ASSERT(condition=e1,message = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"assert(",s1,",",s2,");\n",s3});
      then
        str;
    case ((IF_EQUATION(condition1 = {},equations2 = {},equations3 = {}) :: xs)) then "";
      
    case ((IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::tb),equations3 = {}) :: xs))
      local 
        Exp.Exp c;
        list<Exp.Exp> conds;   
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpIfEquationsStr(conds,tb);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,s2,"  end if;\n",s3});
      then
        str;        
        
    case ((IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::tb),equations3 = xs2) :: xs))
      local 
        Exp.Exp c;
        list<Exp.Exp> conds;   
        String ss11; 
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpEquationsStr(xs2);
        ss11 = dumpIfEquationsStr(conds,tb);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,ss11,"  else\n",s2,"  end if;\n",s3});
      then
        str;
    case ((WHEN_EQUATION(condition = c,equations = xs1,elsewhen_ = SOME(xs2)) :: xs))
      local
        Exp.Exp c;
        Element xs2;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpEquationsStr((xs2 :: xs));
        str = Util.stringAppendList({"when ",s," then\n",s1,"  else",s2});
      then
        str;
    case ((WHEN_EQUATION(condition = c,equations = xs1,elsewhen_ = NONE) :: xs))
      local Exp.Exp c;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  when ",s," then\n",s1,"  end when;\n",s3});
      then
        str;
    case ((REINIT(componentRef = cr,exp = e) :: xs))
      equation 
        s = Exp.printComponentRefStr(cr);
        s1 = Exp.printExpStr(e);
        s2 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  reinit(",s,",",s1,");\n",s2});
      then
        str;
    case ((NORETCALL(functionName=path,functionArgs=expl) :: xs))
      local list<Exp.Exp> expl; Absyn.Path path;
      equation 
        s = Absyn.pathString(path);
        s1 = Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr),",");
        s2 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  ",s,"(",s1,");\n",s2});
      then
        str;        
    case ((_ :: xs))
      equation 
        str = dumpEquationsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpEquationsStr;

protected function dumpIfEquationsStr "" 
  input list<Exp.Exp> conds;
  input list<list<Element>> tbs;
  output String outString; 
algorithm outString := matchcontinue(conds,tbs)
  local
    Exp.Exp c;
    list<Element> tb;
    String s1,s2,sRec,sRes;
  case({},{}) then "";
  case(c::conds, tb::tbs)
    equation
      s1 = Exp.printExpStr(c);
      s2 = dumpEquationsStr(tb);
      sRec = dumpIfEquationsStr(conds,tbs);
      sRes = "  elseif " +& s1 +& " then\n" +& s2 +& sRec; //+& Util.if_(Util.isEmptyString(sRec),"","\n");
      then
        sRes;
end matchcontinue;
end dumpIfEquationsStr;

protected function dumpInitialequationsStr "function: dumpInitialequationsStr
 
  Dump initial equations to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,s4,s4_1,s5,s6,str,s;
      Exp.Exp e1,e2,e;
      list<Element> xs,xs1,xs2;
      list<list<Element>> trueBranches;
      Exp.ComponentRef c;
    case ((INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;    
    case ((INITIALDEFINE(componentRef = c,exp = e) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " := ");
        s4 = Exp.printExpStr(e);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((INITIAL_IF_EQUATION(condition1 = (c::conds),equations2 = (xs1::trueBranches),equations3 = xs2) :: xs))
      local        
        Exp.Exp c;
        list<Exp.Exp> conds;   
        String ss11; 
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpInitialequationsStr(xs1);
        s2 = dumpInitialequationsStr(xs2);
        ss11 = dumpIfEquationsStr(conds,trueBranches);
        s3 = dumpInitialequationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,ss11,"  else\n",s2,"  end if;\n",s3});
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpInitialequationsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpInitialequationsStr;

protected function dumpVars "function: dumpVars
 
  Dump variables to Print buffer.
"
  input list<Element> lst;
  Ident str;
algorithm 
  str := dumpVarsStr(lst);
  Print.printBuf(str);
end dumpVars;

public function dumpVarsStr "function: dumpVarsStr
 
  Dump variables to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,str;
      Element first;
      list<Element> rest;
    case {} then ""; 
    case (first :: rest)
      equation 
        s1 = dumpVarStr(first);
        s2 = dumpVarsStr(rest);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end dumpVarsStr;

protected function dumpKind "function: dumpKind
 
  Dump VarKind.
"
  input VarKind inVarKind;
algorithm 
  _:=
  matchcontinue (inVarKind)
    case CONST()
      equation 
        Print.printBuf(" constant  ");
      then
        ();
    case PARAM()
      equation 
        Print.printBuf(" parameter ");
      then
        ();
    case DISCRETE()
      equation 
        Print.printBuf(" discrete  ");
      then
        ();
    case VARIABLE()
      equation 
        Print.printBuf("           ");
      then
        ();
  end matchcontinue;
end dumpKind;

protected function dumpKindStr "function: dumpKindStr 
 
  Dump VarKind to a string.
"
  input VarKind inVarKind;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVarKind)
    case CONST() then "constant "; 
    case PARAM() then "parameter "; 
    case DISCRETE() then "discrete "; 
    case VARIABLE() then ""; 
  end matchcontinue;
end dumpKindStr;

protected function dumpDirection "function: dumpDirection
 
  Dump VarDirection.
"
  input VarDirection inVarDirection;
algorithm 
  _:=
  matchcontinue (inVarDirection)
    case INPUT()
      equation 
        Print.printBuf(" input  ");
      then
        ();
    case OUTPUT()
      equation 
        Print.printBuf(" output ");
      then
        ();
    case BIDIR()
      equation 
        Print.printBuf("        ");
      then
        ();
  end matchcontinue;
end dumpDirection;

public function dumpDirectionStr "function: dumpDirectionStr
 
  Dump VarDirection to a string
"
  input VarDirection inVarDirection;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVarDirection)
    case INPUT() then "input "; 
    case OUTPUT() then "output "; 
    case BIDIR() then ""; 
  end matchcontinue;
end dumpDirectionStr;

protected function dumpStateSelectStr "function dumpStateSelectStr
 
  Dump StateSelect to a string.
"
  input StateSelect inStateSelect;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStateSelect)
    case (NEVER()) then "StateSelect.never"; 
    case (AVOID()) then "StateSelect.avoid"; 
    case (PREFER()) then "StateSelect.prefer"; 
    case (ALWAYS()) then "StateSelect.always"; 
    case (DEFAULT()) then "StateSelect.default"; 
  end matchcontinue;
end dumpStateSelectStr;

public function dumpVariableAttributes "function: dumpVariableAttributes 
 
  Dump VariableAttributes option.
"
  input Option<VariableAttributes> attr;
  Ident res;
algorithm 
  res := dumpVariableAttributesStr(attr);
  Print.printBuf(res);
end dumpVariableAttributes;

public function getUnitAttr "
  Return the unit attribute
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output Exp.Exp start;
algorithm 
  start:=
  matchcontinue (inVariableAttributesOption)
    local
      Exp.Exp u;
    case (SOME(VAR_ATTR_REAL(_,SOME(u),_,_,_,_,_,_,_,_,_))) then u;
    case (_) then Exp.SCONST(""); 
  end matchcontinue;
end getUnitAttr;

public function getStartAttrEmpty " 
  Return the start attribute.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  input Type tp;
  output Exp.Exp start;
algorithm 
  start:=
  matchcontinue (inVariableAttributesOption,tp)
    local
      Exp.Exp r;
    case (SOME(VAR_ATTR_REAL(initial_ = SOME(r))),_) then r;
    case (SOME(VAR_ATTR_INT(initial_ = SOME(r))),_) then r;
    case (SOME(VAR_ATTR_BOOL(initial_ = SOME(r))),_) then r;
    case (SOME(VAR_ATTR_STRING(initial_ = SOME(r))),_) then r;
    case (_,REAL()) then Exp.RCONST(0.0);
    case (_,INT()) then Exp.ICONST(0);
    case (_,BOOL()) then Exp.BCONST(false);
    case (_,STRING()) then Exp.SCONST("");
    case(_,_) then Exp.RCONST(0.0);
  end matchcontinue;
end getStartAttrEmpty;

public function getMinMax "
Author: BZ, returns a list of optional exp, {opt<Min> opt<Max} 
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output list<Option<Exp.Exp>> oExps;
algorithm oExps := matchcontinue(inVariableAttributesOption)
  local 
    Option<Exp.Exp> e1,e2;
  case(SOME(VAR_ATTR_ENUMERATION(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(SOME(VAR_ATTR_INT(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(SOME(VAR_ATTR_REAL(min = (e1,e2))))
    equation
    then
      e1::{e2};  
  case(_) then {};
  end matchcontinue;
end getMinMax;

public function getStartAttr " 
  Return the start attribute.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output Exp.Exp start;
algorithm 
  start:=
  matchcontinue (inVariableAttributesOption)
    local
      Exp.Exp r;
    case (SOME(VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
    case (_) then Exp.RCONST(0.0); 
  end matchcontinue;
end getStartAttr;

public function getStartAttrFail " 
  Return the start attribute. or fails"
  input Option<VariableAttributes> inVariableAttributesOption;
  output Exp.Exp start;
algorithm start:= matchcontinue (inVariableAttributesOption)
    local
      Exp.Exp r;
    case (SOME(VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
  end matchcontinue;
end getStartAttrFail;

public function setVariableAttributes "sets the attributes of a DAE.Element that is VAR"
  input Element var;
  input Option<VariableAttributes> varOpt;
  output Element outVar;
algorithm
  outVar := matchcontinue(var,varOpt)
  local  Exp.ComponentRef cr; VarKind k;
    VarDirection d ;    VarProtection p;
    Type ty ;   Option<Exp.Exp> b; 
    InstDims  dims ;    Flow fl;
    Stream st;    list<Absyn.Path> cls;
    Option<Absyn.Comment> cmt;  Absyn.InnerOuter io; 
    Types.Type tp;
    
    case(VAR(cr,k,d,p,ty,b,dims,fl,st,cls,_,cmt,io,tp),varOpt) then VAR(cr,k,d,p,ty,b,dims,fl,st,cls,varOpt,cmt,io,tp);
  end matchcontinue;
end setVariableAttributes;

public function setStartAttr " 
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<VariableAttributes> attr;
  input Exp.Exp start;
  output Option<VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,start)
    local
      Option<Exp.Exp> q,u,du,i,f,n;
      tuple<Option<Exp.Exp>, Option<Exp.Exp>> minMax;
      Option<StateSelect> ss;
      Exp.Exp r;
      Option<Exp.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(VAR_ATTR_REAL(q,u,du,minMax,_,f,n,ss,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_REAL(q,u,du,minMax,SOME(start),f,n,ss,eb,ip,fn));
    case (SOME(VAR_ATTR_INT(q,minMax,_,f,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_INT(q,minMax,SOME(start),f,eb,ip,fn));
    case (SOME(VAR_ATTR_BOOL(q,_,f,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_BOOL(q,SOME(start),f,eb,ip,fn));
    case (SOME(VAR_ATTR_STRING(q,_,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_STRING(q,SOME(start),eb,ip,fn));
    case (SOME(VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_ENUMERATION(q,minMax,SOME(start),du,eb,ip,fn));
    case (NONE,start) 
      then SOME(VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),SOME(start),NONE,NONE,NONE,NONE,NONE,NONE)); 
  end matchcontinue;
end setStartAttr;

public function setUnitAttr " 
  sets the unit attribute. .
"
  input Option<VariableAttributes> attr;
  input Exp.Exp unit;
  output Option<VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,unit)
    local
      Option<Exp.Exp> q,u,du,i,f,n,s;
      tuple<Option<Exp.Exp>, Option<Exp.Exp>> minMax;
      Option<StateSelect> ss;
      Exp.Exp r;
      Option<Exp.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,eb,ip,fn)),unit) 
    then SOME(VAR_ATTR_REAL(q,SOME(unit),du,minMax,s,f,n,ss,eb,ip,fn));
    case (NONE,unit) 
      then SOME(VAR_ATTR_REAL(NONE,SOME(unit),NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,NONE,NONE)); 
  end matchcontinue;
end setUnitAttr;

public function setProtectedAttr " 
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<VariableAttributes> attr;
  input Boolean isProtected;
  output Option<VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,isProtected)
    local
      Option<Exp.Exp> q,u,du,i,f,n;
      tuple<Option<Exp.Exp>, Option<Exp.Exp>> minMax;
      Option<StateSelect> ss;
      Exp.Exp r;
      Option<Exp.Exp> eb;
      Option<Boolean> ip,fn; 
    case (SOME(VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,_,fn)),isProtected) 
    then SOME(VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,SOME(isProtected),fn));
    case (SOME(VAR_ATTR_INT(q,minMax,i,f,eb,_,fn)),isProtected)
    then SOME(VAR_ATTR_INT(q,minMax,i,f,eb,SOME(isProtected),fn));
    case (SOME(VAR_ATTR_BOOL(q,i,f,eb,_,fn)),isProtected) 
    then SOME(VAR_ATTR_BOOL(q,i,f,eb,SOME(isProtected),fn));
    case (SOME(VAR_ATTR_STRING(q,i,eb,_,fn)),isProtected)
    then SOME(VAR_ATTR_STRING(q,i,eb,SOME(isProtected),fn));
    case (SOME(VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn)),isProtected) 
    then SOME(VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,SOME(isProtected),fn));
    case (NONE,isProtected) 
      then SOME(VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,SOME(isProtected),NONE));
  end matchcontinue;
end setProtectedAttr;

public function getProtectedAttr " 
  retrieves the protected attribute form VariableAttributes.
"
  input Option<VariableAttributes> attr;
  output Boolean isProtected;
algorithm 
  isProtected:=
  matchcontinue (attr)      
    case (SOME(VAR_ATTR_REAL(isProtected=SOME(isProtected)))) then isProtected; 
    case (SOME(VAR_ATTR_INT(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(VAR_ATTR_BOOL(isProtected=SOME(isProtected)))) then isProtected;     
    case (SOME(VAR_ATTR_STRING(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(VAR_ATTR_ENUMERATION(isProtected=SOME(isProtected)))) then isProtected; 
    case(_) then false;
  end matchcontinue;
end getProtectedAttr;

public function setFixedAttr "Function: setFixedAttr
Sets the start attribute:fixed to inputarg
" 
  input Option<VariableAttributes> attr;
  input Option<Exp.Exp> start;
  output Option<VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,start)
    local
      Option<Exp.Exp> q,u,du,i,f,n,ini;
      tuple<Option<Exp.Exp>, Option<Exp.Exp>> minMax;
      Option<StateSelect> ss;
      Exp.Exp r;
      Option<Exp.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(VAR_ATTR_REAL(q,u,du,minMax,ini,_,n,ss,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_REAL(q,u,du,minMax,ini,start,n,ss,eb,ip,fn));
    case (SOME(VAR_ATTR_INT(q,minMax,ini,_,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_INT(q,minMax,ini,start,eb,ip,fn));
    case (SOME(VAR_ATTR_BOOL(q,ini,_,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_BOOL(q,ini,start,eb,ip,fn));
    case (SOME(VAR_ATTR_STRING(q,ini,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_STRING(q,ini,eb,ip,fn));
    case (SOME(VAR_ATTR_ENUMERATION(q,minMax,u,_,eb,ip,fn)),start) 
    then SOME(VAR_ATTR_ENUMERATION(q,minMax,u,start,eb,ip,fn));
  end matchcontinue;
end setFixedAttr;

public function setFinalAttr " 
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<VariableAttributes> attr;
  input Boolean finalPrefix;
  output Option<VariableAttributes> outAttr;  
algorithm 
  outAttr:=
  matchcontinue (attr,finalPrefix)
    local
      Option<Exp.Exp> q,u,du,i,f,n;
      tuple<Option<Exp.Exp>, Option<Exp.Exp>> minMax;
      Option<StateSelect> ss;
      Option<Exp.Exp> eb;
      Option<Boolean> ip,fn; 
    case (SOME(VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,ip,_)),finalPrefix) 
    then SOME(VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,ip,SOME(finalPrefix)));
    case (SOME(VAR_ATTR_INT(q,minMax,i,f,eb,ip,_)),finalPrefix)
    then SOME(VAR_ATTR_INT(q,minMax,i,f,eb,ip,SOME(finalPrefix)));
    case (SOME(VAR_ATTR_BOOL(q,i,f,eb,ip,_)),finalPrefix) 
    then SOME(VAR_ATTR_BOOL(q,i,f,eb,ip,SOME(finalPrefix)));
    case (SOME(VAR_ATTR_STRING(q,i,eb,ip,_)),finalPrefix)
    then SOME(VAR_ATTR_STRING(q,i,eb,ip,SOME(finalPrefix)));
      
    case (SOME(VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,_)),finalPrefix) 
    then SOME(VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,SOME(finalPrefix)));
      
    case (NONE,finalPrefix)
      then SOME(VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,NONE,SOME(finalPrefix)));
  end matchcontinue;
end setFinalAttr;

public function boolVarProtection "Function: boolVarProtection
Takes a DAE.varprotection and returns true/false (is_protected / not) 
"
input VarProtection vp;
output Boolean prot;
algorithm prot := matchcontinue(vp) 
  case(PUBLIC()) then false;
  case(PROTECTED()) then true; 
  case(_) equation print("-failure DAE.bool_Var_Protection\n"); then fail();
  end matchcontinue;
end boolVarProtection;

public function varHasName "returns true if variable equals name passed as argument"
  input Element var;
  input Exp.ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(var,cr) 
  local Exp.ComponentRef cr2;
    case(VAR(componentRef=cr2),cr) equation
      res = Exp.crefEqual(cr2,cr);      
    then res;
  end matchcontinue;
end varHasName;

public function hasStartAttr " 
  Returns true if variable attributes defines a start value.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output Boolean hasStart;
algorithm 
  hasStart:=
  matchcontinue (inVariableAttributesOption)
    local
      Exp.Exp r;
    case (SOME(VAR_ATTR_REAL(initial_ = SOME(r)))) then true;
    case (SOME(VAR_ATTR_INT(initial_ = SOME(r)))) then true;
    case (SOME(VAR_ATTR_BOOL(initial_ = SOME(r)))) then true;
    case (SOME(VAR_ATTR_STRING(initial_ = SOME(r)))) then true;
    case (_) then false; 
  end matchcontinue;
end hasStartAttr;

public function getStartAttrString "function: getStartAttrString
 
  Return the start attribute as a string.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      Ident s;
      Exp.Exp r;
    case (NONE) then ""; 
    case (SOME(VAR_ATTR_REAL(initial_ = SOME(r))))
      equation 
        s = Exp.printExpStr(r);
      then
        s;
    case (SOME(VAR_ATTR_INT(initial_ = SOME(r))))
      equation 
        s = Exp.printExpStr(r);        
      then
        s;
    case (_) then ""; 
  end matchcontinue;
end getStartAttrString;

protected function stringToString "function: stringToString
 
  Convert a string to a Modelica string, enclosed in citation marks.
"
  input String str;
  output String str_1;
  Ident str_1;
algorithm 
  str_1 := Util.stringAppendList({"\"",str,"\""});
end stringToString;

public function dumpVariableAttributesStr "function: dumpVariableAttributesStr
 
  Dump VariableAttributes option to a string.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      Ident quantity,unit_str,displayUnit_str,stateSel_str,min_str,max_str,nominal_str,Initial_str,fixed_str,res_1,res1,res;
      Boolean is_empty;
      Option<Exp.Exp> quant,unit,displayUnit;
      Option<Exp.Exp> min,max,Initial,nominal;
      Option<Exp.Exp> fixed;
      Option<StateSelect> stateSel;
    case (SOME(VAR_ATTR_REAL(quant,unit,displayUnit,(min,max),Initial,fixed,nominal,stateSel,_,_,_)))
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        unit_str = Dump.getOptionWithConcatStr(unit, Exp.printExpStr, "unit = ");
        displayUnit_str = Dump.getOptionWithConcatStr(displayUnit, Exp.printExpStr, "displayUnit = ");
        stateSel_str = Dump.getOptionWithConcatStr(stateSel, dumpStateSelectStr , "StateSelect = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        nominal_str = Dump.getOptionWithConcatStr(nominal, Exp.printExpStr, "nominal = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts(
          {quantity,unit_str,displayUnit_str,min_str,max_str,
          Initial_str,fixed_str,nominal_str,stateSel_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_INT(quant,(min,max),Initial,fixed,_,_,_)))
      local Option<Exp.Exp> min,max,Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_BOOL(quant,Initial,fixed,_,_,_)))
      local Option<Exp.Exp> Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_STRING(quant,Initial,_,_,_)))
      local Option<Exp.Exp> Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,Initial_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_ENUMERATION(quant,(min,max),Initial,fixed,_,_,_)))
      local Option<Exp.Exp> min,max,Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, Exp.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Exp.printExpStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (NONE) then ""; 
    case (_) then "unknown VariableAttributes"; 
  end matchcontinue;
end dumpVariableAttributesStr;

public function dumpType "function: dumpType
 
  Dump Type.
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    local list<Ident> l; Absyn.Path path;
    case INT()
      equation 
        Print.printBuf("Integer ");
      then
        ();
    case REAL()
      equation 
        Print.printBuf("Real    ");
      then
        ();
    case BOOL()
      equation 
        Print.printBuf("Boolean ");
      then
        ();
    case STRING()
      equation 
        Print.printBuf("String  ");
      then
        ();
        
    case ENUM()
      equation 
        Print.printBuf("Enum ");
      then
        ();
    case ENUMERATION(stringLst = l)
      equation 
        Print.printBuf("Enumeration(");
        Dump.printList(l, print, ",");
        Print.printBuf(") ");
      then
        ();
     case EXT_OBJECT(_)
      equation 
        Print.printBuf("ExternalObject   ");
      then
        ();
     case COMPLEX(name=path)
       equation
         Print.printBuf(Absyn.pathString(path));
       then ();
  end matchcontinue;
end dumpType;

public function dumpTypeStr "function: dumpTypeStr
 
  Dump Type to a string.
"
  input Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Ident s1,s2,str;
      list<Ident> l;
      Absyn.Path path;
    case INT() then "Integer "; 
    case REAL() then "Real "; 
    case BOOL() then "Boolean "; 
    case STRING() then "String "; 
    case ENUM() then "Enum "; 

    case ENUMERATION(stringLst = l)
      equation 
        s1 = Util.stringDelimitList(l, ", ");
        s2 = stringAppend("enumeration(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case EXT_OBJECT(_) then "ExternalObject ";
    case COMPLEX(name=path) then Absyn.pathString(path)+& " ";
  end matchcontinue;
end dumpTypeStr;

protected function dumpVar "function: dumpVar
 
  Dump Var.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef id;
      VarKind kind;
      VarDirection dir;
      Type typ;
      Flow flowPrefix;
      Stream streamPrefix;
      list<Absyn.Path> classlst,class_;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e;
    case VAR(componentRef = id,
             kind = kind,
             direction = dir,
             ty = typ,
             binding = NONE,
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = classlst,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        dumpKind(kind);
        dumpDirection(dir);
        dumpType(typ);
        Exp.printComponentRef(id);
        dumpCommentOption(comment) "	dump_start_value start &" ;
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(";\n") "	Util.list_map(classlst,Absyn.path_string) => classstrlst & 
	Util.string_delimit_list(classstrlst, \", \") => classstr &
	Print.printBuf \" \"{\" &
	Print.printBuf classstr &
	Print.printBuf \"}\" \" &" ;
      then
        ();
    case VAR(componentRef = id,
             kind = kind,
             direction = dir,
             ty = typ,
             binding = SOME(e),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = class_,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        dumpKind(kind);
        dumpDirection(dir);
        dumpType(typ);
        Exp.printComponentRef(id);
        dumpVariableAttributes(dae_var_attr) "	dump_start_value start &" ;
        Print.printBuf(" = ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (_) then (); 
  end matchcontinue;
end dumpVar;

protected function dumpVarStr "function: dumpVarStr
 
  Dump var to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,s2,s3,s4,comment_str,s5,str,s6,s7;
      Exp.ComponentRef id;
      VarKind kind;
      VarDirection dir;
      Type typ;
      Flow flowPrefix;
      Stream streamPrefix;
      list<Absyn.Path> classlst;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e;
      VarProtection prot;
    case VAR(componentRef = id,
             kind = kind,
             direction = dir,
             protection=prot,
             ty = typ,
             binding = NONE,
             flowPrefix = flowPrefix,
             streamPrefix =  streamPrefix,
             pathLst = classlst,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = dumpTypeStr(typ);
        s4 = Exp.printComponentRefStr(id);
        s7 = dumpVarProtectionStr(prot);
        comment_str = dumpCommentOptionStr(comment) "	dump_start_value_str start => s5 &" ;
        s5 = dumpVariableAttributesStr(dae_var_attr);
        str = Util.stringAppendList({s7,s1,s2,s3,s4,s5,comment_str,";\n"}) "	Util.list_map(classlst,Absyn.path_string) => classstrlst & 
	Util.string_delimit_list(classstrlst, \", \") => classstr &" ;
      then
        str;
    case VAR(componentRef = id,
             kind = kind,
             direction = dir,
             protection=prot,
             ty = typ,
             binding = SOME(e),
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = classlst,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = dumpTypeStr(typ);
        s4 = Exp.printComponentRefStr(id);
        s5 = Exp.printExpStr(e);
        comment_str = dumpCommentOptionStr(comment) "	dump_start_value_str start => s6 &" ;
        s6 = dumpVariableAttributesStr(dae_var_attr);
        s7 = dumpVarProtectionStr(prot);
        str = Util.stringAppendList({s7,s1,s2,s3,s4,s6," = ",s5,comment_str,";\n"})  ;
      then
        str;
    case (_) then ""; 
  end matchcontinue;
end dumpVarStr;

protected function dumpVarProtectionStr "Prints 'protected' to a string for protected variables"
  input VarProtection prot;
  output String str;
algorithm
  str := matchcontinue(prot)
    case(PUBLIC()) then "";
    case(PROTECTED()) then "protected ";  
  end matchcontinue;
end dumpVarProtectionStr;

public function dumpCommentOptionStr "function: dumpCommentOptionStr
 
  Dump Comment option to a string.
"
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynCommentOption)
    local
      Ident str,cmt;
      Option<Absyn.Annotation> annopt;
    case (NONE) then ""; 
    case (SOME(Absyn.COMMENT(annopt,SOME(cmt))))
      equation 
        str = Util.stringAppendList({" \"",cmt,"\""});
      then
        str;
    case (SOME(Absyn.COMMENT(annopt,NONE))) then ""; 
  end matchcontinue;
end dumpCommentOptionStr;

protected function dumpCommentOption "function: dumpCommentOption_str
 
  Dump Comment option.
"
  input Option<Absyn.Comment> comment;
  Ident str;
algorithm 
  str := dumpCommentOptionStr(comment);
  Print.printBuf(str);
end dumpCommentOption;

protected function dumpEquation "function: dumpEquation
 
  Dump equation.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.Exp e1,e2,e;
      Exp.ComponentRef c,cr1,cr2;
    case (EQUATION(exp = e1,scalar = e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
        
      case (EQUEQUATION(cr1,cr2))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(cr1);
        Print.printBuf(" = ");
        Exp.printComponentRef(cr2);
        Print.printBuf(";\n");
      then
        ();

    case (ARRAY_EQUATION(exp = e1,array= e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
        
    case (COMPLEX_EQUATION(lhs = e1,rhs= e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();        
        
    case (DEFINE(componentRef = c,exp = e))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(c);
        Print.printBuf(" ::= ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (ASSERT(condition=e1,message=e2))
      equation 
        Print.printBuf("assert(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(");\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpEquation;

protected function dumpInitialequation "function: dumpInitialequation
 
  Dump initial equation.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.Exp e1,e2,e;
      Exp.ComponentRef c;
    case (INITIALEQUATION(exp1 = e1,exp2 = e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    case (INITIALDEFINE(componentRef = c,exp = e))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(c);
        Print.printBuf(" ::= ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpInitialequation;

protected function dumpEquationStr "function: dumpEquationStr
 
  Dump equation to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,s2,s3,s4,s5,str,s;
      Exp.Exp e1,e2,e;
      Exp.ComponentRef c,cr1,cr2;
    case (EQUATION(exp = e1,scalar = e2))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
     case (EQUEQUATION(cr1,cr2))
      equation 
        s1 = Exp.printComponentRefStr(cr1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printComponentRefStr(cr2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
    case(ARRAY_EQUATION(_,e1,e2)) equation
      s1 = Exp.printExpStr(e1);
      s2 = Exp.printExpStr(e2);
      str = s1 +& " = " +& s2;
    then str;
    
    case(COMPLEX_EQUATION(e1,e2)) equation
      s1 = Exp.printExpStr(e1);
      s2 = Exp.printExpStr(e2);
      str = s1 +& " = " +& s2;
    then str;
      
    case (DEFINE(componentRef = c,exp = e))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(" ::= ", s2);
        s4 = Exp.printExpStr(e);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
    case (ASSERT(condition=e1,message = e2))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        str = Util.stringAppendList({"assert(",s1, ",",s2,");\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpEquationStr;

public function dumpAlgorithm "function: dumpAlgorithm
 
  Dump algorithm.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local list<Algorithm.Statement> stmts;
    case ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        Print.printBuf("algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpAlgorithm;

protected function dumpInitialalgorithm "function: dump_algorithm
 
  Dump initial algorithm.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local list<Algorithm.Statement> stmts;
    case INITIALALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        Print.printBuf("initial algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpInitialalgorithm;

public function dumpAlgorithmStr 
"function: dumpAlgorithmStr 
  Dump algorithm to a string"
  input Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      Ident s1,str;
      list<Algorithm.Statement> stmts;
    case (ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts)))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        str = stringAppend("algorithm\n", s1);
      then
        str;
    case (_) then ""; 
  end matchcontinue;
end dumpAlgorithmStr;

protected function dumpInitialalgorithmStr 
"function: dumpInitialalgorithmStr 
  Dump initial algorithm to a string"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,str;
      list<Algorithm.Statement> stmts;
    case INITIALALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        str = stringAppend("initial algorithm\n", s1);
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpInitialalgorithmStr;

protected function dumpExtObjectClass 
"function: dumpExtObjectClass 
  Dump External Object class"
  input Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    local
      Ident fstr;
      Absyn.Path fpath;
      Element constr,destr;
      list<Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case EXTOBJECTCLASS(path = fpath,constructor=constr,destructor=destr)
      equation 
        Print.printBuf("class ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n extends ExternalObject;\n");
        dumpFunction(constr);
        dumpFunction(destr);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpExtObjectClass;

protected function dumpFunction 
"function: dumpFunction 
  Dump function"
  input Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    local
      Ident fstr;
      Absyn.Path fpath;
      list<Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case FUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
      equation 
        Print.printBuf("function ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n");
        dumpElements(dae);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();
     case EXTFUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
       local String fstr,daestr,str;
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"\nexternal \"C\";\nend ",fstr,";\n\n"});
        Print.printBuf(str);
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpFunction;

public function dumpFunctionStr "function: dumpFunctionStr
 
  Dump function to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      Ident fstr,daestr,str;
      Absyn.Path fpath;
      list<Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case FUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"end ",fstr,";\n\n"});
      then
        str;
    case EXTFUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"\nexternal \"C\";\nend ",fstr,";\n\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpFunctionStr;

protected function dumpExtObjClassStr 
"function: dumpExtObjStr 
  Dump external object class to a string."
  input Element inElement;
  output String outString;
algorithm 
  outString := matchcontinue (inElement)
    local
      Ident fstr,daestr,str,c_str,d_str;
      Absyn.Path fpath;
      list<Element> dae;
      Element constr,destr;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case EXTOBJECTCLASS(path = fpath,constructor = constr, destructor = destr)
      equation 
        fstr = Absyn.pathString(fpath);
        c_str = dumpFunctionStr(constr);
        d_str = dumpFunctionStr(destr);
        str = Util.stringAppendList({"class  ",fstr,"\n  extends ExternalObject;\n",c_str,
          d_str,"end ",fstr,";\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpExtObjClassStr;

protected function ppStatement 
"function: ppStatement 
  Prettyprint an algorithm statement"
  input Algorithm.Statement alg;
algorithm 
  ppStmt(alg, 2);
end ppStatement;

public function ppStatementStr 
"function: ppStatementStr 
  Prettyprint an algorithm statement to a string."
  input Algorithm.Statement alg;
  output String str;
algorithm 
  str := ppStmtStr(alg, 2);
end ppStatementStr;

protected function ppStmt 
"function: ppStmt 
  Helper function to ppStatement."
  input Algorithm.Statement inStatement;
  input Integer inInteger;
algorithm 
  _ := matchcontinue (inStatement,inInteger)
    local
      Exp.ComponentRef c;
      Exp.Exp e,cond,msg,e2;
      Integer i,i_1;
      Ident s1,s2,s3,str,id;
      list<Ident> es;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Statement stmt;
      Algorithm.Else else_;
    case (Algorithm.ASSIGN(exp1 = e2 as Exp.ASUB(_,_),exp = e),i) local Exp.Exp ae1,ae2;
      equation 
        indent(i);
        Exp.printExp(e2);
        Print.printBuf(" := ");
        Exp.printExp(e); 
        Print.printBuf(";\n");
      then
        ();
    case (Algorithm.ASSIGN(exp1 = e2 as Exp.CREF(c,_),exp = e),i) 
      equation 
        indent(i);
        Exp.printComponentRef(c);
        Print.printBuf(" := ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        (); 
    case (Algorithm.ASSIGN_ARR(componentRef = c,exp = e),i)
      equation 
        indent(i);
        Exp.printComponentRef(c);
        Print.printBuf(" := ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (Algorithm.TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        es = Util.listMap(expl, Exp.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = Util.stringAppendList({s1,"(",s3,") := ",s2,";\n"});
        Print.printBuf(str);
      then
        ();
    case (Algorithm.IF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        indent(i);
        Print.printBuf("if ");
        Exp.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
        indent(i);
        Print.printBuf("end if;\n");
      then
        ();
    case (Algorithm.FOR(ident = id,exp = e,statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("for ");
        Print.printBuf(id);
        Print.printBuf(" in ");
        Exp.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end for;\n");
      then
        ();
    case (Algorithm.WHILE(exp = e,statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("while ");
        Exp.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end while;\n");
      then
        ();
    case (stmt as Algorithm.WHEN(exp = _),i)
      equation 
        indent(i);
        Print.printBuf(ppWhenStmtStr(stmt,1));
      then
        ();
    case (Algorithm.ASSERT(cond = cond,msg = msg),i)
      equation 
        indent(i);
        Print.printBuf("assert( ");
        Exp.printExp(cond);
        Print.printBuf(", ");
        Exp.printExp(msg);
        Print.printBuf(");\n");
      then
        ();
    case (Algorithm.BREAK(),i)
      equation 
        indent(i);
        Print.printBuf("break;\n");
      then
        ();
    case (Algorithm.REINIT(e1,e2),i)
           local Exp.Exp e1,e2;
      equation 
        indent(i);
        Print.printBuf("reinit(");
        Exp.printExp(e1); 
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(");\n");         
      then
        ();
    case (_,i)
      equation 
        indent(i);
        Print.printBuf("**ALGORITHM**;\n");
      then
        ();
  end matchcontinue;
end ppStmt;


protected function ppWhenStmtStr
  input Algorithm.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStatement,inInteger)
    local
      Ident s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str;
      Exp.ComponentRef c;
      Exp.Exp e,cond,msg;
      Integer i,i_1;
      list<Ident> es;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Statement stmt;
      Algorithm.Else else_;
    case (Algorithm.WHEN(exp = e,statementLst = stmts, elseWhen=NONE),i)
      equation 
        s3 = stringAppend("when ",Exp.printExpStr(e));
        s5 = stringAppend(s3, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end when;\n");
      then
        str;
    case (Algorithm.WHEN(exp = e,statementLst = stmts, elseWhen=SOME(stmt)),i)
      equation 
        s3 = Exp.printExpStr(e);
        s4 = stringAppend("when ", s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppWhenStmtStr(stmt,i);
        s9 = stringAppend(indentStr(i),"else");
        s10= stringAppend(s7,s9);
        str = stringAppend(s10, s8);
      then
        str;
   end matchcontinue;
end ppWhenStmtStr;

protected function ppStmtStr "function: ppStmtStr
 
  Helper function to pp_statement_str
"
  input Algorithm.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStatement,inInteger)
    local
      Ident s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str;
      Exp.ComponentRef c;
      Exp.Exp e,cond,msg,e2;
      Integer i,i_1;
      list<Ident> es;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Statement stmt;
      Algorithm.Else else_;
    case (Algorithm.ASSIGN(exp1 = e2 as Exp.CREF(c,_),exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printComponentRefStr(c);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    case (Algorithm.ASSIGN(exp1 = e2 as Exp.ASUB(_,_),exp = e),i) local Exp.Exp ae1,ae2;
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e2);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e); 
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    
    case (Algorithm.ASSIGN_ARR(componentRef = c,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printComponentRefStr(c);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    case (Algorithm.TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        es = Util.listMap(expl, Exp.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = Util.stringAppendList({s1,"(",s3,") := ",s2,";\n"});
      then
        str;
    case (Algorithm.IF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "if ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end if;\n");
      then
        str;
    case (Algorithm.FOR(ident = id,exp = e,statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "for ");
        s3 = stringAppend(s2, id);
        s4 = stringAppend(s3, " in ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        s7 = stringAppend(s6, " loop\n");
        i_1 = i + 2;
        s8 = ppStmtListStr(stmts, i_1);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end for;\n");
      then
        str;
    case (Algorithm.WHILE(exp = e,statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "while ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " loop\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end while;\n");
      then
        str;
    case (stmt as Algorithm.WHEN(exp = _),i)
      equation 
        s1 = indentStr(i);
        s2 = ppWhenStmtStr(stmt,i);
        str = stringAppend(s1,s2);
      then
        str;
    case (Algorithm.ASSERT(cond = cond,msg = msg),i)
      equation 
        s1 = indentStr(i);
        cond_str = Exp.printExpStr(cond);
        msg_str = Exp.printExpStr(msg);
        str = Util.stringAppendList({s1,"assert(",cond_str,", ",msg_str,");\n"});
      then
        str;

    case (Algorithm.NORETCALL(e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        str = Util.stringAppendList({s1,s2,"\n"});
      then
        str;

    case (Algorithm.BREAK(),i)
      equation 
        s1 = indentStr(i);
        str = stringAppend(s1, "break;\n");
      then
        str;
    case (Algorithm.REINIT(e1,e2),i)
      local Exp.Exp e1,e2; String e1_str,e2_str;
        equation
          s1 = indentStr(i);
          e1_str = Exp.printExpStr(e1);
          e2_str = Exp.printExpStr(e2);
          str = Util.stringAppendList({s1,"reinit(",e1_str,", ",e2_str,");\n"});
        then str;
    case (_,i)
      equation 
        s1 = indentStr(i);
        str = stringAppend(s1, "**ALGORITHM COULD NOT BE GENERATED(DAE.mo)**;\n");
      then
        str;
  end matchcontinue;
end ppStmtStr;

protected function ppStmtList "function: ppStmtList
 
  Helper function to pp_stmt
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inAlgorithmStatementLst,inInteger)
    local
      Algorithm.Statement stmt;
      list<Algorithm.Statement> stmts;
      Integer i;
    case ({},_) then (); 
    case ((stmt :: stmts),i)
      equation 
        ppStmt(stmt, i);
        ppStmtList(stmts, i);
      then
        ();
  end matchcontinue;
end ppStmtList;

protected function ppStmtListStr "function: ppStmtListStr
 
  Helper function to pp_stmt_str
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAlgorithmStatementLst,inInteger)
    local
      Ident s1,s2,str;
      Algorithm.Statement stmt;
      list<Algorithm.Statement> stmts;
      Integer i;
    case ({},_) then ""; 
    case ((stmt :: stmts),i)
      equation 
        s1 = ppStmtStr(stmt, i);
        s2 = ppStmtListStr(stmts, i);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end ppStmtListStr;

protected function ppElse "function: ppElse
 
  Helper function to pp_stmt
"
  input Algorithm.Else inElse;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inElse,inInteger)
    local
      Integer i_1,i;
      Exp.Exp e;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Else else_;
    case (Algorithm.NOELSE(),_) then (); 
    case (Algorithm.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        indent(i);
        Print.printBuf("elseif ");
        Exp.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
      then
        ();
    case (Algorithm.ELSE(statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("else\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
      then
        ();
  end matchcontinue;
end ppElse;

protected function ppElseStr "function: pp_else
 
  Helper function to ppElseStr
"
  input Algorithm.Else inElse;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElse,inInteger)
    local
      Ident s1,s2,s3,s4,s5,s6,s7,s8,str;
      Integer i_1,i;
      Exp.Exp e;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Else else_;
    case (Algorithm.NOELSE(),_) then ""; 
    case (Algorithm.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "elseif ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        str = stringAppend(s7, s8);
      then
        str;
    case (Algorithm.ELSE(statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "else\n");
        i_1 = i + 2;
        s3 = ppStmtListStr(stmts, i_1);
        str = stringAppend(s2, s3);
      then
        str;
  end matchcontinue;
end ppElseStr;

protected function indent "function: indent
 
  Print an indentation, given an indent level.
"
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inInteger)
    local Integer i_1,i;
    case 0 then (); 
    case i
      equation 
        Print.printBuf(" ");
        i_1 = i - 1;
        indent(i_1);
      then
        ();
  end matchcontinue;
end indent;

protected function indentStr "function: indentStr
 
  Print an indentation to a string, given an indent level.
"
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger)
    local
      Integer i_1,i;
      Ident s1,str;
    case 0 then ""; 
    case i
      equation 
        i_1 = i - 1;
        s1 = indentStr(i_1);
        str = stringAppend(" ", s1);
      then
        str;
  end matchcontinue;
end indentStr;

public function getMatchingElements "function getMatchingElements
  author:  LS 
 
  Retrive the elements for which the function given as second argument
  succeeds.
"
  input list<Element> elist;
  input FuncTypeElementTo cond;
  output list<Element> elist;
  partial function FuncTypeElementTo
    input Element inElement;
  end FuncTypeElementTo;
algorithm 
  elist := Util.listFilter(elist, cond);
end getMatchingElements;

public function getAllMatchingElements "function getAllMatchingElements
  author:  PA 
 
  Similar to getMatchingElements but traverses down in COMP elements also.
"
  input list<Element> elist;
  input FuncTypeElementTo cond;
  output list<Element> elist;
  partial function FuncTypeElementTo
    input Element inElement;
  end FuncTypeElementTo;
algorithm 
  
  elist := matchcontinue(elist,cond)
  local list<Element> elist2; Element e;
    case({},_) then {};
    case(COMP(_,DAE(elist))::elist2,cond) equation
      elist= getAllMatchingElements(elist,cond);
      elist2 = getAllMatchingElements(elist2,cond);
      elist2 = listAppend(elist,elist2);
      then elist2;
    case(e::elist,cond) equation
      cond(e);
      elist = getAllMatchingElements(elist,cond);
    then e::elist;

    case(e::elist,cond) equation
      elist = getAllMatchingElements(elist,cond);
    then elist;
  end matchcontinue;
end getAllMatchingElements;


public function isParameter "function isParameter
  author: LS 
  Succeeds if element is parameter.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(kind = PARAM()) then ();
  end matchcontinue;
end isParameter;

public function isParameterOrConstant "
  author: BZ 2008-06
  Succeeds if element is constant/parameter.
"
  input Element inElement;
  output Boolean b;
algorithm 
  b:=
  matchcontinue (inElement)
    case VAR(kind = CONST()) then true; 
    case VAR(kind = PARAM()) then true;
    case(_) then false;
  end matchcontinue;
end isParameterOrConstant;

public function isInnerVar "function isInnerVar
  author: PA 
 
  Succeeds if element is a variable with prefix inner.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(innerOuter = Absyn.INNER()) then ();
    case VAR(innerOuter = Absyn.INNEROUTER())then ();
  end matchcontinue;
end isInnerVar;

public function isOuterVar "function isOuterVar
  author: PA 
  Succeeds if element is a variable with prefix outer.
"
  input Element inElement;
algorithm _:= matchcontinue (inElement)
    case VAR(innerOuter = Absyn.OUTER()) then ();
    /* FIXME? adrpo: do we need this? case VAR(innerOuter = Absyn.INNEROUTER()) then (); */
  end matchcontinue;
end isOuterVar;

public function isComp "function isComp
  author: LS 
 
  Succeeds if element is component, COMP.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case COMP(ident = _) then (); 
  end matchcontinue;
end isComp;

public function getOutputVars "function getOutputVars
  author: LS 
 
  Retrieve all output variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isOutputVar);
end getOutputVars;

public function getProtectedVars "
  author: PA
 
  Retrieve all protected variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isProtectedVar);
end getProtectedVars;

public function getBidirVars "function get_output_vars
  author: LS 
 
  Retrieve all bidirectional variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isBidirVar);
end getBidirVars;

public function getInputVars "function getInputVars
  author: HJ 
 
  Retrieve all input variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isInput);
end getInputVars;

public function generateDaeType "function generateDaeType
 
  Generate a Types.Type from a DAE.Type
  Is needed when investigating the DAE and want to e.g. evaluate expressions.
"
  input Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    case (REAL()) then ((Types.T_REAL({}),NONE)); 
    case (INT()) then ((Types.T_INTEGER({}),NONE)); 
    case (BOOL()) then ((Types.T_BOOL({}),NONE)); 
    case (STRING()) then ((Types.T_STRING({}),NONE)); 
  end matchcontinue;
end generateDaeType;

public function setComponentTypeOpt "
  
  See setComponentType
"
  input list<Element> inElementLst;
  input Option<Absyn.Path> inPath;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst,inPath)
      local Absyn.Path p;
    case (inElementLst,SOME(p)) equation
      outElementLst = setComponentType(inElementLst,p);
    then outElementLst ;
    case(inElementLst,NONE) then inElementLst;
  end matchcontinue;
end setComponentTypeOpt;

public function setComponentType "function: setComponentType
  
  This function takes a dae element list and a type name and 
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable.
"
  input list<Element> inElementLst;
  input Absyn.Path inPath;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst,inPath)
    local
      list<Element> xs_1,xs;
      Exp.ComponentRef cr;
      VarKind kind;
      VarDirection dir;
      Type tp;
      Option<Exp.Exp> bind;
      InstDims dim;
      Flow flowPrefix;
      Stream streamPrefix;
      list<Absyn.Path> lst;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Absyn.Path newtype;
      Element x;
			Absyn.InnerOuter io;
			Types.Type ftp;
			VarProtection prot;
    case ({},_) then {}; 
    case ((VAR(componentRef = cr,
               kind = kind,
               direction = dir, 
               protection = prot,
               ty = tp,
               binding = bind,
               dims = dim,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix,
               pathLst = lst,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io,
               fullType=ftp) :: xs),newtype)
      equation 
        xs_1 = setComponentType(xs, newtype);
      then
        (VAR(cr,kind,dir,prot,tp,bind,dim,flowPrefix,streamPrefix,(newtype :: lst),dae_var_attr,comment,io,ftp) :: xs_1);
        
    case ((x :: xs),newtype)
      equation 
        xs_1 = setComponentType(xs, newtype);
      then
        (x :: xs_1);
  end matchcontinue;
end setComponentType;

public function isOutputVar 
"function: isOutputVar 
  author: LS  
  Succeeds if Element is an output variable."
  input Element inElement;
algorithm 
  _ := matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(componentRef = n,kind = VARIABLE(),direction = OUTPUT(),ty = ty) then ();
  end matchcontinue;
end isOutputVar;

public function isProtectedVar 
"function isProtectedVar
 author: PA 
 Succeeds if Element is a protected variable."
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(protection=PROTECTED()) then (); 
  end matchcontinue;
end isProtectedVar;

public function isPublicVar "
  author: PA 
 
  Succeeds if Element is a public variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(protection=PUBLIC()) then (); 
  end matchcontinue;
end isPublicVar;

public function isBidirVar "function: isBidirVar 
  author: LS 
 
  Succeeds if Element is a bidirectional variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(componentRef = n,kind = VARIABLE(),direction = BIDIR(),ty = ty) then ();
  end matchcontinue;
end isBidirVar;

public function isInputVar "function: isInputVar 
  author: HJ
 
  Succeeds if Element is an input variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(componentRef = n,kind = VARIABLE(),direction = INPUT(),ty = ty) then ();
  end matchcontinue;
end isInputVar;

public function isInput "function: isInputVar 
  author: PA
 
  Succeeds if Element is an input .
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(direction = INPUT()) then ();
  end matchcontinue;
end isInput;

protected function isNotVar "function: isNotVar 
  author: LS
 
  Succeeds if Element is not a variable.
"
  input Element e;
algorithm 
  failure(isVar(e));
end isNotVar;

public function isVar "function: isVar 
  author: LS
 
  Succeeds if Element is a variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(componentRef = _) then (); 
  end matchcontinue;
end isVar;

public function isFunctionRefVar 
"function: isFunctionRefVar
  return true if the element is a function reference variable"
  input Element inElem;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inElem)
    case VAR(ty = FUNCTION_REFERENCE()) then true;
    case _ then false;
  end matchcontinue;
end isFunctionRefVar;

public function isAlgorithm "function: isAlgorithm
  author: LS
 
  Succeeds if Element is an algorithm.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case ALGORITHM(algorithm_ = _) then (); 
  end matchcontinue;
end isAlgorithm;

public function isFunction "function: isFunction
  author: LS
 
  Succeeds if Element is not a function.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case FUNCTION(path = _) then (); 
    case EXTFUNCTION(path = _) then (); 
  end matchcontinue;
end isFunction;

public function dumpDebug "

 Dump the data structures in a 
 paranthesised way

"
  input DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local list<Element> elist;
    case DAE(elementLst = elist)
      equation 
        Print.printBuf("DAE(");
        dumpDebugElist(elist);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end dumpDebug;

protected function dumpDebugElist "function: dumpDebugElist
 
  Helper function to dump_debug.
"
  input list<Element> inElementLst;
algorithm 
  _:=
  matchcontinue (inElementLst)
    local
      Element first;
      list<Element> rest;
    case {} then (); 
    case (first :: rest)
      equation 
        dumpDebugElement(first);
        Print.printBuf("\n");
        dumpDebugElist(rest);
      then
        ();
  end matchcontinue;
end dumpDebugElist;

public function dumpDebugDAE ""
  input DAElist dae;
  output String str;
algorithm str := matchcontinue(dae)
  local
    list<Element> elems;
  case(DAE(elems)) 
    equation
      Print.clearBuf();
      dumpDebugElist(elems);
      str = Print.getString();
    then
      str;
end matchcontinue;
end dumpDebugDAE;

public function dumpDebugElement "function: dumpDebugElement
 
  Dump element using parenthesis.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Ident comment_str,tmp_str,n,fstr;
      Exp.ComponentRef cr,cr1,cr2;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e,exp,e1,e2;
      DAElist l;
      Absyn.Path fpath;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case VAR(componentRef = cr,
             kind = vk,
             direction = vd,
             ty = ty,
             binding = NONE,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk); 
        comment_str = Dump.unparseCommentOption(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case VAR(componentRef = cr,
             kind = vk,
             direction = vd,
             ty = ty,
             binding = SOME(e),
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment)
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        Print.printBuf(", binding: ");
        Exp.printExp(e);
        comment_str = Dump.unparseCommentOption(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);        
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DEFINE(componentRef = cr,exp = exp)
      equation 
        Print.printBuf("DEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        Exp.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case INITIALDEFINE(componentRef = cr,exp = exp)
      equation 
        Print.printBuf("INITIALDEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        Exp.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case EQUATION(exp = e1,scalar = e2)
      equation 
        Print.printBuf("EQUATION(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")");
      then
        ();
              
     case EQUEQUATION(cr1,cr2)
      equation 
        Print.printBuf("EQUATION(");
        Exp.printComponentRef(cr1);
        Print.printBuf(",");
        Exp.printComponentRef(cr2);
        Print.printBuf(")");
      then
        ();
    case INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation 
        Print.printBuf("INITIALEQUATION(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case ALGORITHM(algorithm_ = _)
      equation 
        Print.printBuf("ALGORITHM()");
      then
        ();
    case INITIALALGORITHM(algorithm_ = _)
      equation 
        Print.printBuf("INITIALALGORITHM()");
      then
        ();
    case COMP(ident = n,dAElist = l)
      equation 
        Print.printBuf("COMP(");
        Print.printBuf(n);
        Print.printBuf(",");
        dumpDebug(l);
        Print.printBuf(")");
      then
        ();
    case FUNCTION(path = fpath,dAElist = l,type_ = t)
      equation 
        Print.printBuf("FUNCTION(");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf(",");
        Print.printBuf(Types.printTypeStr(t));
        Print.printBuf(",");
        dumpDebug(l);
        Print.printBuf(")");
      then
        ();
    case _
      equation 
        Print.printBuf("UNKNOWN ");
      then
        ();
  end matchcontinue;
end dumpDebugElement;

public function findElement "function: findElement
 
  Search for an element for which the function passed as second 
  argument succeds. If no element is found return NONE.
"
  input list<Element> inElementLst;
  input FuncTypeElementTo inFuncTypeElementTo;
  output Option<Element> outElementOption;
  partial function FuncTypeElementTo
    input Element inElement;
  end FuncTypeElementTo;
algorithm 
  outElementOption:=
  matchcontinue (inElementLst,inFuncTypeElementTo)
    local
      Element e;
      list<Element> rest;
      FuncTypeElementTo f;
      Option<Element> e_1;
    case ({},_) then NONE; 
    case ((e :: rest),f)
      equation 
        f(e);
      then
        SOME(e);
    case ((e :: rest),f)
      equation 
        failure(f(e));
        e_1 = findElement(rest, f);
      then
        e_1;
  end matchcontinue;
end findElement;

public function dumpGraphviz "
 Graphviz functions to visualize 
 the dae
"
  input DAElist dae;
  Graphviz.Node r;
algorithm 
  r := buildGraphviz(dae);
  Graphviz.dump(r);
end dumpGraphviz;

protected function buildGraphviz "function: buildGraphviz
 
  Builds the graphviz node from a dae list.
"
  input DAElist inDAElist;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inDAElist)
    local
      list<Element> vars,nonvars,els;
      list<Graphviz.Node> nonvarnodes,varnodes,nodelist;
    case DAE(elementLst = els)
      equation 
        vars = getMatchingElements(els, isVar);
        nonvars = getMatchingElements(els, isNotVar);
        nonvarnodes = buildGrList(nonvars);
        varnodes = buildGrVars(vars);
        nodelist = listAppend(nonvarnodes, varnodes);
      then
        Graphviz.NODE("DAE",{},nodelist);
  end matchcontinue;
end buildGraphviz;

protected function buildGrList "function buildGrList
 
  Helper function to build_graphviz.
"
  input list<Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst:=
  matchcontinue (inElementLst)
    local
      Graphviz.Node node;
      list<Graphviz.Node> nodelist;
      Element el;
      list<Element> rest;
    case {} then {}; 
    case (el :: rest)
      equation 
        node = buildGrElement(el);
        nodelist = buildGrList(rest);
      then
        (node :: nodelist);
  end matchcontinue;
end buildGrList;

protected function buildGrVars "function buildGrVars
 
  Helper function to build_graphviz.
"
  input list<Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst:=
  matchcontinue (inElementLst)
    local
      list<Ident> strlist;
      list<Element> vars;
    case {} then {}; 
    case vars
      equation 
        (strlist,_) = buildGrStrlist(vars, buildGrVarStr, 10);
      then
        {Graphviz.LNODE("VARS",strlist,{Graphviz.box},{})};
  end matchcontinue;
end buildGrVars;

public function buildGrStrlist "function buildGrStrlist
 
  Helper function to build_graphviz.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input Integer inInteger;
  output list<String> outStringLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm 
  (outStringLst,outTypeALst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inInteger)
    local
      list<Type_a> ignored,rest;
      FuncTypeType_aToString printer;
      Integer count,count_1;
      list<Ident> strlist;
      Ident str;
      Type_a var;
    case ({},_,_) then ({},{}); 
    case (ignored,printer,count)
      equation 
        (count <= 0) = true;
      then
        ({"..."},ignored);
    case ((var :: rest),printer,count)
      equation 
        (count > 0) = true;
        count_1 = count - 1;
        (strlist,ignored) = buildGrStrlist(rest, printer, count_1);
        str = printer(var);
      then
        ((str :: strlist),ignored);
  end matchcontinue;
end buildGrStrlist;

protected function buildGrVarStr "function buildGrVarStr
 
  Helper function to build_graphviz.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident str,expstr,str_1,str_2;
      Exp.ComponentRef cr;
      Exp.Exp exp;
    case VAR(componentRef = cr,binding = NONE)
      equation 
        str = Exp.printComponentRefStr(cr);
      then
        str;
    case VAR(componentRef = cr,binding = SOME(exp))
      equation 
        str = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        str_1 = stringAppend(str, " = ");
        str_2 = stringAppend(str_1, expstr);
      then
        str_2;
  end matchcontinue;
end buildGrVarStr;

protected function printExpStrSpecial "function: printExpStrSpecial
 
  Prints an expression to a string suitable for graphviz.
"
  input Exp.Exp inExp;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExp)
    local
      Ident s_1,s_2,s,str;
      Exp.Exp exp;
    case Exp.SCONST(string = s)
      equation 
        s_1 = stringAppend("\\\"", s);
        s_2 = stringAppend(s_1, "\\\"");
      then
        s_2;
    case exp
      equation 
        str = Exp.printExpStr(exp);
      then
        str;
  end matchcontinue;
end printExpStrSpecial;

protected function buildGrElement "function: buildGrElement
 
  Builds a Graphviz.Node from an element.
"
  input Element inElement;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inElement)
    local
      Ident crstr,vkstr,expstr,expstr_1,e1str,e2str,n,fstr;
      Exp.ComponentRef cr,cr1,cr2;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Exp.Exp exp,e1,e2;
      Graphviz.Node node;
      DAElist dae;
      Absyn.Path fpath;
    case VAR(componentRef = cr,kind = vk,direction = vd,ty = ty,binding = NONE)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr},{},{});
    case VAR(componentRef = cr,kind = vk,direction = vd,ty = ty,binding = SOME(exp))
      equation 
        crstr = Exp.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr,expstr_1},{},{});
    case DEFINE(componentRef = cr,exp = exp)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("DEFINE",{crstr,expstr_1},{},{});
    case EQUATION(exp = e1,scalar = e2)
      equation 
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("EQUATION",{e1str,"=",e2str},{},{});
    case EQUEQUATION(cr1,cr2)
      equation 
        e1str = printExpStrSpecial(Exp.CREF(cr1,Exp.OTHER()));
        e2str = printExpStrSpecial(Exp.CREF(cr2,Exp.OTHER()));
      then
        Graphviz.LNODE("EQUEQUATION",{e1str,"=",e2str},{},{});
    case ALGORITHM(algorithm_ = _) then Graphviz.NODE("ALGORITHM",{},{}); 
    case INITIALDEFINE(componentRef = cr,exp = exp)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("INITIALDEFINE",{crstr,expstr_1},{},{});
    case INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation 
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("INITIALEQUATION",{e1str,"=",e2str},{},{});
    case INITIALALGORITHM(algorithm_ = _) then Graphviz.NODE("INITIALALGORITHM",{},{}); 
    case COMP(ident = n,dAElist = dae)
      equation 
        node = buildGraphviz(dae);
      then
        Graphviz.LNODE("COMP",{n},{},{node});
    case FUNCTION(path = fpath,dAElist = dae,type_ = ty)
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        node = buildGraphviz(dae);
        fstr = Absyn.pathString(fpath);
      then
        Graphviz.LNODE("FUNCTION",{fstr},{},{node});
  end matchcontinue;
end buildGrElement;

public function getVariableBindingsStr "function: getVariableBindingsStr
 
  This function takes a `DAE.Element\' list and returns a comma separated 
  string of variable bindings.
  E.g. model A Real x=1; Real y=2; end A; => \"1,2\"
"
  input list<Element> elts;
  output String str;
  list<Element> varlst;
algorithm 
  varlst := getVariableList(elts);
  str := getBindingsStr(varlst);
end getVariableBindingsStr;

protected function getVariableList "function: getVariableList
 
  Return all variables from an Element list.
"
  input list<Element> inElementLst;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst)
    local
      list<Element> res,lst;
      Exp.ComponentRef a;
      VarKind b;
      Element x;    
      VarDirection c;
      VarProtection prot;
      Type d;
      Option<Exp.Exp> e,g;
      InstDims f;
      Flow h;
      list<Absyn.Path> i;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Absyn.InnerOuter io;
      Types.Type tp;
            
    /* adrpo: filter out records! */
    case ((x as VAR(ty = COMPLEX(_,_))) :: lst)
      equation
        res = getVariableList(lst);
      then
        (res);   
              
    case ((x as VAR(_,_,_,_,_,_,_,_,_,_,_,_,_,_)) :: lst)
      equation 
        res = getVariableList(lst);
      then
        (x :: res);
    case (_ :: lst)
      equation 
        res = getVariableList(lst);
      then
        res;
    case {} then {}; 
  end matchcontinue;
end getVariableList;

protected function getBindingsStr "function: getBindingsStr
 
  Retrive the bindings from a list of Elements and output to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident expstr,s3,s4,str,s1,s2;
      Element v;
      Exp.ComponentRef cr;
      Exp.Exp e;
      list<Element> lst;
    case (((v as VAR(componentRef = cr,binding = SOME(e))) :: (lst as (_ :: _))))
      equation 
        expstr = Exp.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((v as VAR(componentRef = cr,binding = NONE)) :: (lst as (_ :: _))))
      equation 
        s1 = "-,";
        s2 = getBindingsStr(lst);
        str = stringAppend(s1, s2);
      then
        str;
    case ({(v as VAR(componentRef = cr,binding = SOME(e)))})
      equation 
        str = Exp.printExpStr(e);
      then
        str;
    case ({(v as VAR(componentRef = cr,binding = NONE))}) then ""; 
  end matchcontinue;
end getBindingsStr;

public function getBindings "function: getBindingsStr
Author: BZ, 2008-11
Get variable-bindings from element list.
"
  input list<Element> inElementLst;
  output list<Exp.ComponentRef> outc;
  output list<Exp.Exp> oute;
algorithm (outc,oute) := matchcontinue (inElementLst)
    local
      Exp.ComponentRef cr;
      Exp.Exp e;
      case({}) then ({},{});
    case (VAR(componentRef = cr,binding = SOME(e)) :: inElementLst)
      equation 
        (outc,oute) = getBindings(inElementLst);
      then
        (cr::outc,e::oute);
    case (VAR(componentRef = cr,binding  = NONE) :: inElementLst) 
      equation (outc,oute) = getBindings(inElementLst); then (outc,oute);
    case (_) equation print(" error in getBindings \n"); then fail();  
  end matchcontinue;
end getBindings;

public function toFlow "function: toFlow
 
  Create a Flow, given a ClassInf.State and a boolean flow value.
"
  input Boolean inBoolean;
  input ClassInf.State inState;
  output Flow outFlow;
algorithm 
  outFlow:=
  matchcontinue (inBoolean,inState)
    case (true,_) then FLOW(); 
    case (_,ClassInf.CONNECTOR(string = _)) then NON_FLOW(); 
    case (_,_) then NON_CONNECTOR(); 
  end matchcontinue;
end toFlow;

public function toStream "function: toStram
  Create a Stream, given a ClassInf.State and a boolean stream value."
  input Boolean inBoolean;
  input ClassInf.State inState;
  output Stream outStream;
algorithm
  outFlow:=
  matchcontinue (inBoolean,inState)
    case (true,_) then STREAM();
    case (_,ClassInf.CONNECTOR(string = _)) then NON_STREAM();
    case (_,_) then NON_STREAM_CONNECTOR();
  end matchcontinue;
end toStream;

public function getFlowVariables "function: getFlowVariables
 
  Retrive the flow variables of an Element list.
"
  input list<Element> inElementLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<Exp.ComponentRef> res,res1,res1_1,res2;
      Exp.ComponentRef cr;
      list<Element> xs,lst;
      Ident id;
    case ({}) then {}; 
    case ((VAR(componentRef = cr,flowPrefix = FLOW()) :: xs))
      equation 
        res = getFlowVariables(xs);
      then
        (cr :: res);
    case ((COMP(ident = id,dAElist = DAE(elementLst = lst)) :: xs))
      equation 
        res1 = getFlowVariables(lst);
        res1_1 = getFlowVariables2(res1, id);
        res2 = getFlowVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_ :: xs))
      equation 
        res = getFlowVariables(xs);
      then
        res;
  end matchcontinue;
end getFlowVariables;

protected function getFlowVariables2 "function: getFlowVariables2
 
  Helper function to get_flow_variables.
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Ident inIdent;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      Ident id;
      list<Exp.ComponentRef> res,xs;
      Exp.ComponentRef cr_1,cr;
    case ({},id) then {}; 
    case ((cr :: xs),id)
      equation 
        res = getFlowVariables2(xs, id);
        cr_1 = Exp.joinCrefs(Exp.CREF_IDENT(id,Exp.OTHER(),{}), cr);
      then
        (cr_1 :: res);
  end matchcontinue;
end getFlowVariables2;

public function getStreamVariables "function: getStreamVariables
  Retrive the stream variables of an Element list."
  input list<Element> inElementLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<Exp.ComponentRef> res,res1,res1_1,res2;
      Exp.ComponentRef cr;
      list<Element> xs,lst;
      Ident id;
    case ({}) then {};
    case ((VAR(componentRef = cr,streamPrefix = STREAM()) :: xs))
      equation
        res = getStreamVariables(xs);
      then
        (cr :: res);
    case ((COMP(ident = id,dAElist = DAE(elementLst = lst)) :: xs))
      equation
        res1 = getStreamVariables(lst);
        res1_1 = getStreamVariables2(res1, id);
        res2 = getStreamVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_ :: xs))
      equation
        res = getStreamVariables(xs);
      then
        res;
  end matchcontinue;
end getStreamVariables;

protected function getStreamVariables2 "function: getStreamVariables2

  Helper function to get_flow_variables.
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Ident inIdent;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      Ident id;
      list<Exp.ComponentRef> res,xs;
      Exp.ComponentRef cr_1,cr;
    case ({},id) then {};
    case ((cr :: xs),id)
      equation
        res = getStreamVariables2(xs, id);
        cr_1 = Exp.joinCrefs(Exp.CREF_IDENT(id,Exp.OTHER(),{}), cr);
      then
        (cr_1 :: res);
  end matchcontinue;
end getStreamVariables2;

public function daeToRecordValue "function: daeToRecordValue
  Transforms a list of elements into a record value.
  TODO: This does not work for records inside records. 
  For a general approach we need to build an environment from the DAE and then
  instead investigate the variables and lookup their values from the created environment."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath;
  input list<Element> inElementLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm 
  (outCache, outValue) := matchcontinue (inCache,inEnv,inPath,inElementLst,inBoolean)
    local
      Absyn.Path cname;
      Values.Value value,res;
      list<Values.Value> vals;
      list<Ident> names;
      Ident cr_str;
      Exp.ComponentRef cr;
      Exp.Exp rhs;
      list<Element> rest;
      Boolean impl;
      Integer ix;
      Element el;
      Env.Cache cache;
      Env.Env env;
      
    case (cache,env,cname,{},_) then (cache,Values.RECORD(cname,{},{},-1));  /* impl */
    case (cache,env,cname,VAR(componentRef = cr, binding = SOME(rhs)) :: rest, impl)
      equation
        // Debug.fprintln("failtrace", "- DAE.daeToRecordValue typeOfRHS: " +& Exp.typeOfString(rhs));        
        (cache, value,_) = Ceval.ceval(cache, env, rhs, impl, NONE, NONE, Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = Exp.printComponentRefStr(cr);        
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    /*    
    case (cache,env,cname,(EQUATION(exp = Exp.CREF(componentRef = cr),scalar = rhs) :: rest),impl)
      equation 
        (cache, value,_) = Ceval.ceval(Env.emptyCache(),{}, rhs, impl, NONE, NONE, Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = Exp.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    */
    case (cache,env,_,el::_,_)
      local String str;
      equation
        str = dumpDebugDAE(DAE({el}));
        Debug.fprintln("failtrace", "- DAE.daeToRecordValue failed on: " +& str);
      then
        fail();
  end matchcontinue;
end daeToRecordValue;

public function toModelicaForm "function toModelicaForm.
 
  Transforms all variables from a.b.c to a_b_c, etc
"
  input DAElist inDAElist;
  output DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inDAElist)
    local list<Element> elts_1,elts;
    case (DAE(elementLst = elts))
      equation 
        elts_1 = toModelicaFormElts(elts);
      then
        DAE(elts_1);
  end matchcontinue;
end toModelicaForm;

protected function toModelicaFormElts "function: toModelicaFormElts
 
  Helper function to to_modelica_form.
"
  input list<Element> inElementLst;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst)
    local
      Ident str,str_1,id;
      list<Element> elts_1,elts,welts_1,welts,telts_1,eelts_1,telts,eelts;
      Option<Exp.Exp> d_1,d,f;
      Exp.ComponentRef cr,cr_1;
      VarKind a;
      VarDirection b;
      Type c;
      InstDims e;
      Flow g;
      Stream streamPrefix;
      Stream s;
      list<Absyn.Path> h;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e_1,e1_1,e2_1,e1,e2;
      Element elt_1,elt;
      DAElist dae_1,dae;
      Absyn.Path p;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Types.Type tp;
      Absyn.InnerOuter io;
      list<Exp.Exp> conds, conds_1;
      list<list<Element>> trueBranches, trueBranches_1;
      list<Element> eelts;
      VarProtection prot;
      Boolean partialPrefix;
    case ({}) then {}; 
    case ((VAR(componentRef = cr,
               kind = a,
               direction = b,
               protection = prot,
               ty = c,
               binding = d,
               dims = e,
               flowPrefix = g,
               streamPrefix = streamPrefix,
               pathLst = h,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io,
               fullType=tp) :: elts))
      local Exp.Type ty;
      equation 
        str = Exp.printComponentRefStr(cr);
        str_1 = Util.stringReplaceChar(str, ".", "_");
        elts_1 = toModelicaFormElts(elts);
        d_1 = toModelicaFormExpOpt(d);
        ty = Exp.crefType(cr); 
      then
        (VAR(Exp.CREF_IDENT(str_1,ty,{}),a,b,prot,c,d_1,e,g,streamPrefix,h,dae_var_attr,
          comment,io,tp) :: elts_1);
    case ((DEFINE(componentRef = cr,exp = e) :: elts))
      local Exp.Exp e;
      equation 
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DEFINE(cr_1,e_1) :: elts_1);
    case ((INITIALDEFINE(componentRef = cr,exp = e) :: elts))
      local Exp.Exp e;
      equation 
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIALDEFINE(cr_1,e_1) :: elts_1);
    case ((EQUATION(exp = e1,scalar = e2) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (EQUATION(e1_1,e2_1) :: elts_1);
    case ((EQUEQUATION(cr1,cr2) :: elts))
      local Exp.ComponentRef cr1,cr2;
      equation 
         Exp.CREF(cr1,_) = toModelicaFormExp(Exp.CREF(cr1,Exp.OTHER()));
         Exp.CREF(cr2,_) = toModelicaFormExp(Exp.CREF(cr2,Exp.OTHER()));
        elts_1 = toModelicaFormElts(elts);
      then
        (EQUEQUATION(cr1,cr2) :: elts_1);
    case ((WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = SOME(elt)) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        {elt_1} = toModelicaFormElts({elt});
        elts_1 = toModelicaFormElts(elts);
      then
        (WHEN_EQUATION(e1_1,welts_1,SOME(elt_1)) :: elts_1);
    case ((WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = NONE) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        elts_1 = toModelicaFormElts(elts);
      then
        (WHEN_EQUATION(e1_1,welts_1,NONE) :: elts_1);
    case ((IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts) :: elts))
      equation 
        conds_1 = Util.listMap(conds,toModelicaFormExp);
        trueBranches_1 = Util.listMap(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (IF_EQUATION(conds_1,trueBranches_1,eelts_1) :: elts_1);
    case ((INITIAL_IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts) :: elts))
      equation 
        conds_1 = Util.listMap(conds,toModelicaFormExp);
        trueBranches_1 = Util.listMap(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIAL_IF_EQUATION(conds_1,trueBranches_1,eelts_1) :: elts_1);
    case ((INITIALEQUATION(exp1 = e1,exp2 = e2) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIALEQUATION(e1_1,e2_1) :: elts_1);
    case ((ALGORITHM(algorithm_ = a) :: elts))
      local Algorithm.Algorithm a;
      equation 
        print("to_modelica_form_elts(ALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (ALGORITHM(a) :: elts_1);
    case ((INITIALALGORITHM(algorithm_ = a) :: elts))
      local Algorithm.Algorithm a;
      equation 
        print("to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIALALGORITHM(a) :: elts_1);
    case ((COMP(ident = id,dAElist = dae) :: elts))
      equation 
        dae_1 = toModelicaForm(dae);
        elts_1 = toModelicaFormElts(elts);
      then
        (COMP(id,dae_1) :: elts_1);
    case ((FUNCTION(path = p,dAElist = dae,type_ = t,partialPrefix = partialPrefix) :: elts))
      equation 
        dae_1 = toModelicaForm(dae);
        elts_1 = toModelicaFormElts(elts);
      then
        (FUNCTION(p,dae_1,t,partialPrefix) :: elts_1);
    case ((EXTFUNCTION(path = p,dAElist = dae,type_ = t,externalDecl = d) :: elts))
      local ExternalDecl d;
      equation 
        elts_1 = toModelicaFormElts(elts);
        dae_1 = toModelicaForm(dae);
      then
        (EXTFUNCTION(p,dae,t,d) :: elts_1);
    case ((ASSERT(condition = e1,message=e2) :: elts))
      local Exp.Exp e1,e2,e_1,e_2;
      equation 
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
        e_2 = toModelicaFormExp(e2);
      then
        (ASSERT(e_1,e_2) :: elts_1);
  end matchcontinue;
end toModelicaFormElts;

public function replaceCrefInVar "
Author BZ 
 Function for updating the Component Ref of the Var
"
input Exp.ComponentRef newCr;
input Element inelem;
output Element outelem;
algorithm outelem := matchcontinue(newCr, inelem)
  local
    Exp.ComponentRef a1;
    VarKind a2;
    VarDirection a3;
    VarProtection a4;
    Type a5;
    Option<Exp.Exp> a6; 
    InstDims a7;
    Flow a8;
    Stream a9;
    list<Absyn.Path> a10;
    Option<VariableAttributes> a11;
    Option<Absyn.Comment> a12;
    Absyn.InnerOuter a13;
    Types.Type a14;
  case(newCr, VAR(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14))
    then VAR(newCr,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14);
  end matchcontinue;
end replaceCrefInVar;

protected function toModelicaFormExpOpt "function: toModelicaFormExpOpt
 
  Helper function to to_mdelica_form_elts.
"
  input Option<Exp.Exp> inExpExpOption;
  output Option<Exp.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inExpExpOption)
    local Exp.Exp e_1,e;
    case (SOME(e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        SOME(e_1);
    case (NONE) then NONE; 
  end matchcontinue;
end toModelicaFormExpOpt;

protected function toModelicaFormCref "function: toModelicaFormCref
 
  Helper function to to_modelica_form_elts.
"
  input Exp.ComponentRef cr;
  output Exp.ComponentRef outComponentRef;
  Ident str,str_1;
  Exp.Type ty;
algorithm 
  str := Exp.printComponentRefStr(cr);
  ty := Exp.crefType(cr); 
  str_1 := Util.stringReplaceChar(str, ".", "_");
  outComponentRef := Exp.CREF_IDENT(str_1,ty,{});
end toModelicaFormCref;

protected function toModelicaFormExp "function: toModelicaFormExp
 
  Helper function to to_modelica_form_elts.
"
  input Exp.Exp inExp;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Exp.ComponentRef cr_1,cr;
      Exp.Type t;
      Exp.Exp e1_1,e2_1,e1,e2,e_1,e,e3_1,e3;
      Exp.Operator op;
      list<Exp.Exp> expl_1,expl;
      Absyn.Path f;
      Boolean b;
      Integer i;
      Option<Exp.Exp> eopt_1,eopt;
    case (Exp.CREF(componentRef = cr,ty = t))
      equation 
        cr_1 = toModelicaFormCref(cr);
      then
        Exp.CREF(cr_1,t);
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        Exp.BINARY(e1_1,op,e2_1);
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        Exp.LBINARY(e1_1,op,e2_1);
    case (Exp.UNARY(operator = op,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.UNARY(op,e_1);
    case (Exp.LUNARY(operator = op,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.LUNARY(op,e_1);
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        Exp.RELATION(e1_1,op,e2_1);
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        e3_1 = toModelicaFormExp(e3);
      then
        Exp.IFEXP(e1_1,e2_1,e3_1);
    case (Exp.CALL(path = f,expLst = expl,tuple_ = t,builtin = b,ty=tp))
      local Boolean t; Exp.Type tp;
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        Exp.CALL(f,expl_1,t,b,tp);
    case (Exp.ARRAY(ty = t,scalar = b,array = expl))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        Exp.ARRAY(t,b,expl_1);
    case (Exp.TUPLE(PR = expl))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        Exp.TUPLE(expl_1);
    case (Exp.CAST(ty = t,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.CAST(t,e_1);
    case (Exp.ASUB(exp = e,sub = expl))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.ASUB(e_1,expl);
    case (Exp.SIZE(exp = e,sz = eopt))
      equation 
        e_1 = toModelicaFormExp(e);
        eopt_1 = toModelicaFormExpOpt(eopt);
      then
        Exp.SIZE(e_1,eopt_1);
    case (e) then e; 
  end matchcontinue;
end toModelicaFormExp;

public function getNamedFunction "function: getNamedFunction
 
  return the FUNCTION with the given name. Returns empty list if not found
  TODO: Only top level functions are checked. Add recursing into the DAE
  and path name checking.
  TODO: External functions?
"
  input Absyn.Path inPath;
  input list<Element> inElementLst;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inPath,inElementLst)
    local
      Absyn.Path path,elpath;
      Element el;
      list<Element> rest,res;
    case (_,{}) then {}; 
    case (path,((el as FUNCTION(path = elpath)) :: rest))
      equation 
        true = ModUtil.pathEqual(path, elpath);
      then
        {el};
    case (path,((el as EXTFUNCTION(path = elpath)) :: rest))
      equation 
        true = ModUtil.pathEqual(path, elpath);
      then
        {el};
    case (path,(el :: rest))
      equation 
        res = getNamedFunction(path, rest);
      then
        res;
    case (_,_)
      equation 
        Debug.fprintln("failtrace", "-- get_named_function failed");
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getAllExps "function: getAllExps
  
  This function goes through the DAE structure and finds all the
  expressions and returns them in a list
"
  input list<Element> elements;
  output list<Exp.Exp> exps;
  list<list<Exp.Exp>> expslist;
algorithm 
  expslist := Util.listMap(elements, getAllExpsElement);
  exps := Util.listFlatten(expslist);
end getAllExps;

protected function crefToExp "function: crefToExp
 
  Makes an expression from a ComponentRef.
"
  input Exp.ComponentRef inComponentRef;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef)
    local Exp.ComponentRef cref;
    case cref then Exp.CREF(cref,Exp.OTHER()); 
  end matchcontinue;
end crefToExp;

public function verifyWhenEquation "
Author BZ, 2008-09
This function verifies when-equations. 
Returns the crefs written to, and also checks for illegal statements in when-body eqn's.
"
  input list<Element> inElems;
  output list<Exp.ComponentRef> leftSideCrefs;
algorithm  leftSideCrefs := matchcontinue(inElems)
  local
    list<Element> elems1,oelems,moreWhen;
    list<Exp.ComponentRef> crefs1,crefs2;
  case({}) then {};
    // no need to check elseWhen, they are beein handled in a reverse order, from inst.mo.
  case(WHEN_EQUATION(_,elems1,_)::moreWhen) then verifyWhenEquationStatements(elems1);
    
  case(inElems) then verifyWhenEquationStatements(inElems);
  case(inElems) 
    equation 
      print("-verify_When_Equation FAILED\n"); 
      //print(dumpElementsStr(elems1) +& "\n\n");
      then fail();
end matchcontinue;
end verifyWhenEquation;

protected function verifyWhenEquationStatements2 ""
input list<Exp.Exp> inExps;
output list<Exp.ComponentRef> leftSideCrefs;
algorithm leftSideCrefs := matchcontinue(inExps)
  local
    Exp.Exp e;
    list<Exp.ComponentRef> crefs1,crefs2;
  case({}) then {};
  case(e::inExps)
    equation
      crefs1 = verifyWhenEquationStatements({EQUATION(e,e)});
      crefs2 = verifyWhenEquationStatements2(inExps);
      leftSideCrefs = listAppend(crefs1,crefs2);
      then
        leftSideCrefs;
  end matchcontinue;
end verifyWhenEquationStatements2;

protected function verifyWhenEquationStatements "
Author BZ, 2008-09
Helper function for verifyWhenEquation
TODO: add some error reporting for this. 
"
input list<Element> inElems;
output list<Exp.ComponentRef> leftSideCrefs;
algorithm 
  leftSideCrefs:=
  matchcontinue (inElems)
    local
      String s1,s2;
      Integer i;
      list<Exp.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3;
      Exp.Exp crefexp,exp,cond,ee1,ee2;
      Exp.ComponentRef cref;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Option<Exp.Exp> bndexp,startvalexp;
      InstDims instdims;
      Flow flowPrefix;
      list<Absyn.Path> pathlist;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<Element> ellist,elements,eqs,eqsfalseb,rest;
      list<list<Element>> eqstrueb;
      list<Exp.ComponentRef> lhsCrefs,crefs1,crefs2,crefs3;
      Element el;
      Option<Element> elsewhenopt;
      Algorithm.Algorithm alg;
      Ident id,fname,lang;
      Absyn.Path path;
      list<list<Exp.Exp>> argexps,expslist;
      list<ExtArg> args;
      ExtArg retarg;
      Option<Absyn.Annotation> ann;
      case({}) then {};
    case(VAR(componentRef = _)::rest) 
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DEFINE(componentRef = cref,exp = exp)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;

    case(EQUATION(exp = Exp.CREF(cref,_))::rest)
      equation
      lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;
    case(EQUATION(exp = Exp.TUPLE(exps1))::rest)
      equation
        crefs1 = verifyWhenEquationStatements2(exps1);
        lhsCrefs = verifyWhenEquationStatements(rest);
        lhsCrefs = listAppend(crefs1,lhsCrefs);
      then 
        lhsCrefs;
    case(EQUEQUATION(cref,_)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;
        
    case(IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb)::rest)
      local list<list<Exp.ComponentRef>> crefslist;
      equation 
        crefslist = Util.listMap(eqstrueb,verifyWhenEquationStatements);
        crefs2 = verifyWhenEquationStatements(eqsfalseb);
        crefslist = listAppend(crefslist,{crefs2});
        (crefs1,true) = compareCrefList(crefslist);
        lhsCrefs = verifyWhenEquationStatements(rest);
        lhsCrefs = listAppend(crefs1,lhsCrefs);
      then
        lhsCrefs;
    case(IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb)::rest)
      local list<list<Exp.ComponentRef>> crefslist;
      equation 
        crefslist = Util.listMap(eqstrueb,verifyWhenEquationStatements);
        crefs2 = verifyWhenEquationStatements(eqsfalseb);
        (crefs1,false) = compareCrefList(crefslist);
        s2 = dumpEquationStr(IF_EQUATION(exps,eqstrueb,eqsfalseb));
        s1 = "Error in IF-equation: \n" +& s2 +& "\n " +& "\nAll branches must write to same variables \n";
        print(s1);
      then
        fail();

    case(ALGORITHM(algorithm_ = alg)::rest)
      equation 
        print("ALGORITHM not implemented for use inside when equation\n"); 
      then
        fail();
    case(INITIALALGORITHM(algorithm_ = alg)::rest)
      equation 
        print("INITIALALGORITHM not allowed inside when equation\n"); 
      then
        fail();
    case(COMP(ident = _)::rest)
      equation 
      print("COMP not implemented for use inside when equation\n"); 
      then
        fail();

    case(ASSERT(condition=ee1,message=ee2)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(TERMINATE(message = _)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(REINIT(componentRef=cref)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        /*cref::*/lhsCrefs;
       
    case(FUNCTION(path = path,dAElist = DAE(elementLst = elements),type_ = ty)::rest)
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation print("FUNCTION not allowed inside when equation\n");
      then 
        fail();  
    case(EXTFUNCTION(path = path,dAElist = DAE(elementLst = elements),type_ = ty,externalDecl = EXTERNALDECL(ident = fname,external_ = args,parameters = retarg,returnType = lang,language = ann))::rest)
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation print("EXTFUNCTION not allowed inside when equation\n");
      then 
        fail();  
    case(INITIAL_IF_EQUATION(condition1 = _)::rest)
      equation print("INITIAL_IF_EQUATION not allowed inside when equation\n");
      then 
        fail();  
    case(INITIALEQUATION(exp1 = _)::rest)
      equation print("INITIALEQUATION not allowed inside when equation\n");
      then 
        fail();  
    case(NORETCALL(_,_)::rest)
      equation print("NORETCALL not allowed inside when equation\n"); 
      then 
        fail();  
    case(WHEN_EQUATION(condition = _)::rest)
      equation 
        print(" When-equation inside when equation..?\n");
      then
        fail(); 
    case(INITIALDEFINE(componentRef = cref,exp = exp)::_)
      equation 
        print("INITIALDEFINE inside when equation, error");
      then
        fail();
    case(_)
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_element failed");
      then
        fail();
  end matchcontinue;
end verifyWhenEquationStatements;

protected function compareCrefList ""
input list<list<Exp.ComponentRef>> inrefs;
output list<Exp.ComponentRef> outrefs;
output Boolean matching;
algorithm (outrefs,matching) := matchcontinue(inrefs)
  local
    list<Exp.ComponentRef> crefs,recRefs;
    Integer i;
    Boolean b1,b2,b3;
  case({}) then ({},true);
  case(crefs::{}) then (crefs,true);
  case(crefs::inrefs) // this case will allways have revRefs >=1 unless we are supposed to have 0
    equation
      (recRefs,b3) = compareCrefList(inrefs);
      i = listLength(recRefs);
      b1 = (0 == intMod(listLength(crefs),listLength(recRefs)));        
      crefs = Util.listListUnionOnTrue({recRefs,crefs},Exp.crefEqual);
      b2 = intEq(listLength(crefs),i);
      b1 = boolAnd(b1,boolAnd(b2,b3));
    then
      (crefs,b1);      
  end matchcontinue;
end compareCrefList; 

protected function getAllExpsElement "function: getAllExpsElement
  
  Helper to get_all_exps. Implements get_all_exps for different kinds of
  elements 
"
  input Element inElement;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inElement)
    local
      
      list<Exp.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3,ifcond;
      Exp.Exp crefexp,exp,cond;
      Exp.ComponentRef cref;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Option<Exp.Exp> bndexp,startvalexp;
      InstDims instdims;
      Flow flowPrefix;
      Stream streamPrefix;
      list<Absyn.Path> pathlist;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<Element> ellist,elements,eqs,eqsfalseb;
      list<list<Element>> eqstrueb;
      Option<Element> elsewhenopt;
      Algorithm.Algorithm alg;
      Ident id,fname,lang;
      Absyn.Path path;
      list<list<Exp.Exp>> argexps,expslist;
      list<ExtArg> args;
      ExtArg retarg;
      Option<Absyn.Annotation> ann;
    case VAR(componentRef = cref,
             kind = vk,
             direction= vd,
             ty = ty,
             binding = bndexp,
             dims = instdims,
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             pathLst = pathlist,
             variableAttributesOption = dae_var_attr,
             absynCommentOption = comment) /* VAR */ 
      equation 
        e1 = Util.optionToList(bndexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        crefexp = crefToExp(cref);
        exps = Util.listFlatten({e1,e3,{crefexp}});
      then
        exps;
    case DEFINE(componentRef = cref,exp = exp)
      equation 
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case INITIALDEFINE(componentRef = cref,exp = exp)
      equation 
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case EQUATION(exp = e1,scalar = e2)
      local Exp.Exp e1,e2;
      then
        {e1,e2};
    case EQUEQUATION(cr1,cr2)
      local Exp.ComponentRef cr1,cr2; Exp.Exp e1,e2;
        equation
          e1 = crefToExp(cr1);
          e2 = crefToExp(cr2);
      then
        {e1,e2};
    case WHEN_EQUATION(condition = cond,equations = eqs,elsewhen_ = elsewhenopt)
      equation 
        ellist = Util.optionToList(elsewhenopt);
        elements = listAppend(eqs, ellist);
        exps = getAllExps(elements);
      then
        (cond :: exps);
    case IF_EQUATION(condition1 = ifcond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation 
        explist1 = Util.listFlatten(Util.listMap(eqstrueb,getAllExps));
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({ifcond,explist1,explist2});
      then
        exps;
    case INITIAL_IF_EQUATION(condition1 = ifcond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation 
        explist1 = Util.listFlatten(Util.listMap(eqstrueb,getAllExps));
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({ifcond,explist1,explist2});
      then
        exps;
    case INITIALEQUATION(exp1 = e1,exp2 = e2)
      local Exp.Exp e1,e2;
      then
        {e1,e2};
    case ALGORITHM(algorithm_ = alg)
      equation 
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case INITIALALGORITHM(algorithm_ = alg)
      equation 
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case COMP(ident = id,dAElist = DAE(elementLst = elements))
      equation 
        exps = getAllExps(elements);
      then
        exps;
    case FUNCTION(path = path,dAElist = DAE(elementLst = elements),type_ = ty)
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps = listAppend(exps1, exps2);
      then
        exps;
    case EXTFUNCTION(path = path,dAElist = DAE(elementLst = elements),type_ = ty,externalDecl = EXTERNALDECL(ident = fname,external_ = args,parameters = retarg,returnType = lang,language = ann))
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps3 = getAllExpsExtarg(retarg);
        argexps = Util.listMap(args, getAllExpsExtarg);
        expslist = listAppend({exps1,exps2,exps3}, argexps);
        exps = Util.listFlatten(expslist);
      then
        exps;
    case ASSERT(condition=e1,message=e2) local Exp.Exp e1,e2; then {e1,e2}; 
    case NORETCALL(fname,fargs) 
    local Absyn.Path fname;
      list<Exp.Exp> fargs;
    then {Exp.CALL(fname,fargs,false,false,Exp.OTHER())};      
      
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_element failed");
      then
        fail();
  end matchcontinue;
end getAllExpsElement;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  
  Get all exps from a Subscript 
"
  input Exp.Subscript inSubscript;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inSubscript)
    local Exp.Exp e;
    case Exp.WHOLEDIM() then {}; 
    case Exp.SLICE(exp = e) then {e}; 
    case Exp.INDEX(exp = e) then {e}; 
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_subscript failed");
      then
        fail();
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsExtarg 
"function: getAllExpsExtarg  
  Get all exps from an ExtArg"
  input ExtArg inExtArg;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExtArg)
    local
      Exp.Exp exp1,crefexp,exp;
      list<Exp.Exp> explist,exps,tyexps;
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation 
        exp1 = crefToExp(cref);
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case EXTARGEXP(exp = exp1,type_ = ty)
      equation 
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case EXTARGSIZE(componentRef = cref,attributes = attr,type_ = ty,exp = exp)
      equation 
        crefexp = crefToExp(cref);
        tyexps = Types.getAllExps(ty);
        exps = Util.listFlatten({{crefexp},tyexps,{exp}});
      then
        exps;
    case NOEXTARG() then {}; 
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_extarg failed");
      then
        fail();
  end matchcontinue;
end getAllExpsExtarg;

public function transformIfEqToExpr 
"function: transformIfEqToExpr
  transform all if equations to ordinary equations involving if-expressions"
  input DAElist inDAElist;
  output DAElist outDAElist;
algorithm 
  outDAElist := matchcontinue (inDAElist)
    local
      DAElist sublist_result,result,sublist;
      list<Element> rest_result,rest,res2,res1,res;
      Element subresult,el;
      Ident name;
    case (DAE(elementLst = {})) then DAE({}); 
    case (DAE(elementLst = (COMP(ident = name,dAElist = sublist) :: rest)))
      equation 
        sublist_result = transformIfEqToExpr(sublist);
        DAE(rest_result) = transformIfEqToExpr(DAE(rest));
        subresult = COMP(name,sublist_result);
        result = DAE((subresult :: rest_result));
      then
        result;
    case (DAE(elementLst = (el :: rest)))
      equation 
        DAE(res2) = transformIfEqToExpr(DAE(rest));
        res1 = ifEqToExpr(el);
        res = listAppend(res1, res2);
      then
        DAE(res);
    case (DAE(elementLst = (el :: rest)))
      equation 
        DAE(res) = transformIfEqToExpr(DAE(rest));
      then
        DAE((el :: res));
  end matchcontinue;
end transformIfEqToExpr;

protected function ifEqToExpr 
"function: ifEqToExpr
  Transform one if-equation into equations involving if-expressions"
  input Element inElement;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElement)
    local
      Integer true_eq,false_eq;
      Ident elt_str;
      Element elt;
      list<Exp.Exp> cond;
      list<Element> false_branch,equations;
      list<list<Element>> true_branch;
    case ((elt as IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch)))
      equation 
        true_eq = ifEqToExpr2(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = false;
        elt_str = dumpEquationsStr({elt});
        Error.addMessage(Error.DIFFERENT_NO_EQUATION_IF_BRANCHES, {elt_str});
      then
        {};
    case (IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch))
      equation 
        true_eq = ifEqToExpr2(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = true;
        equations = makeEquationsFromIf(cond, true_branch, false_branch);
      then
        equations;
    case (_) then fail(); 
  end matchcontinue;
end ifEqToExpr;

protected function ifEqToExpr2
  input list<list<Element>> tbs;
  output Integer len;
algorithm len := matchcontinue(tbs)
  local
    list<Element> tb;
    Integer recLen;
  case(tb::{}) then listLength(tb);
  case(tb::tbs)
    equation
      recLen = ifEqToExpr2(tbs);
      recLen = Util.if_(intEq(recLen,listLength(tb)),recLen,-1);
    then 
      recLen;
end matchcontinue;
end ifEqToExpr2;

protected function makeEquationsFromIf
  input list<Exp.Exp> inExp1;
  input list<list<Element>> inElementLst2;
  input list<Element> inElementLst3;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inExp1,inElementLst2,inElementLst3)
      
    case (_,{{}},{}) then {}; 

    case (conds,tbs,fb::fbs)
      local 
        list<list<Element>> tbs,rest1,tbsRest,tbsFirstL;
        list<Element> tbsFirst,fbs,rest_res;
        Element fb,eq;
        list<Exp.Exp> conds,tbsexp; 
        Exp.Exp fbexp,ifexp;
      equation 
        tbsRest = Util.listMap(tbs,Util.listRest);
        rest_res = makeEquationsFromIf(conds, tbsRest, fbs);
        
        tbsFirst = Util.listMap(tbs,Util.listFirst);        
        tbsexp = Util.listMap(tbsFirst,makeEquationToResidualExp);        
        fbexp = makeEquationToResidualExp(fb);
        
        ifexp = Exp.makeNestedIf(conds,tbsexp,fbexp);
        eq = EQUATION(Exp.RCONST(0.0),ifexp);
      then
        (eq :: rest_res);
  end matchcontinue;
end makeEquationsFromIf;

protected function makeEquationToResidualExp ""
  input Element eq;
  output Exp.Exp oExp;
algorithm oExp := matchcontinue(eq)
  local Exp.Exp e1,e2;
  case(EQUATION(e1,e2))
    equation
      oExp = Exp.BINARY(e1,Exp.SUB(Exp.REAL()),e2);
    then 
      oExp;
end matchcontinue;
end makeEquationToResidualExp;

public function dumpFlow "
Author BZ 2008-07, dump flow properties to string.
"
  input Flow var;
  output String flowStrig;
algorithm flowString := matchcontinue(var)
  case(FLOW) then "flow";
  case(NON_FLOW) then "effort";
  case(NON_CONNECTOR) then "non_connector";
end matchcontinue;
end dumpFlow;

public function renameTimeToDollarTime "
Author: BZ, 2009-1
rename the keyword time to globalData->timeValue, this is a special case for functions since they do not get translated in to c_crefs.
"
  input list<Element> dae;
  output list<Element> odae;  
algorithm (odae,_) := traverseDAE(dae, renameTimeToDollarTimeVisitor,0);
end renameTimeToDollarTime;

protected function renameTimeToDollarTimeVisitor "
Author: BZ, 2009-01
The visitor function for traverseDAE.calls Exp.traverseExp on the expression.
"
input Exp.Exp exp; 
input Integer arg; 
output Exp.Exp oexp; 
output Integer oarg; 
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    Exp.Type ty;
    Exp.ComponentRef cr,cr2;
  case(exp,oarg) 
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,renameTimeToDollarTimeFromCref,oarg);
    then 
      (oexp,oarg);
  end matchcontinue;
end renameTimeToDollarTimeVisitor;

protected function renameTimeToDollarTimeFromCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit.
"
  input tuple<Exp.Exp, Integer> inTplExpExpString;
  output tuple<Exp.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local Exp.ComponentRef cr,cr2; Exp.Type cty,ty; Integer oarg; list<Exp.Subscript> subs;
  case((Exp.CREF(Exp.CREF_IDENT("time",cty,subs),ty),oarg))    
  then ((Exp.CREF(Exp.CREF_IDENT("globalData->timeValue",cty,subs),ty),oarg));
  case(inTplExpExpString) then inTplExpExpString;
end matchcontinue;   
end renameTimeToDollarTimeFromCref;


public function renameUniqueOuterVars "
Author: BZ, 2008-12
Rename innerouter(the inner part of innerouter) variables that have been renamed to a.b.$unique$var
Just remove the $unique$ from the var name.
This function traverses the entire dae.
"
  input list<Element> dae;
  output list<Element> odae;  
algorithm (odae,_) := traverseDAE(dae, renameUniqueVisitor,0);
end renameUniqueOuterVars;

protected function renameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE. 
calls Exp.traverseExp on the expression.
"
input Exp.Exp exp; 
input Integer arg; 
output Exp.Exp oexp; 
output Integer oarg; 
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    Exp.Type ty;
    Exp.ComponentRef cr,cr2;
  case(exp,oarg) 
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,removeUniqieIdentifierFromCref,oarg);
    then 
      (oexp,oarg);
  end matchcontinue;
end renameUniqueVisitor;

protected function removeUniqieIdentifierFromCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit.
"
  input tuple<Exp.Exp, Integer> inTplExpExpString;
  output tuple<Exp.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local Exp.ComponentRef cr,cr2; Exp.Type ty; Integer oarg;
  case((Exp.CREF(cr,ty),oarg))    
    equation
      cr2 = unNameInnerouterUniqueCref(cr,UNIQUEIO);
    then ((Exp.CREF(cr2,ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
  end matchcontinue;   
end removeUniqieIdentifierFromCref;

public function nameUniqueOuterVars "
Author: BZ, 2008-12
Rename all variables to the form a.b.$unique$var, call
This function traverses the entire dae.
"
  input list<Element> dae;
  output list<Element> odae;  
algorithm (odae,_) := traverseDAE(dae, nameUniqueVisitor,0);
end nameUniqueOuterVars;

protected function nameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE. 
calls Exp.traverseExp on the expression.
"
input Exp.Exp exp; 
input Integer arg; 
output Exp.Exp oexp; 
output Integer oarg; 
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    Exp.Type ty;
    Exp.ComponentRef cr,cr2;
  case(exp,oarg) 
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,addUniqieIdentifierToCref,oarg);
    then 
      (oexp,oarg);
  end matchcontinue;
end nameUniqueVisitor;

protected function addUniqieIdentifierToCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, adds the constant 'UNIQUEIO' to the CREF_IDENT() part of the cref.
"
  input tuple<Exp.Exp, Integer> inTplExpExpString;
  output tuple<Exp.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local Exp.ComponentRef cr,cr2; Exp.Type ty; Integer oarg;
  case((Exp.CREF(cr,ty),oarg))    
    equation
      cr2 = nameInnerouterUniqueCref(cr);
    then ((Exp.CREF(cr2,ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
  end matchcontinue;   
end addUniqieIdentifierToCref;

// helper functions for traverseDAE
protected function traverseDAEOptExp "
Author: BZ, 2008-12
Traverse an optional expression, helper function for traverseDAE
"
  input Option<Exp.Exp> oexp;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<Exp.Exp> ooexp;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(ooexp,oextraArg) := matchcontinue(oexp,func,extraArg)
  case(NONE,func,extraArg) then (NONE,extraArg);
  case(SOME(e),func,extraArg)
    local Exp.Exp e;
    equation
      (e,extraArg) = func(e,extraArg);
    then
      (SOME(e),extraArg);
end matchcontinue;
end traverseDAEOptExp;

protected function traverseDAEExpList "
Author: BZ, 2008-12
Traverse an list of expressions, helper function for traverseDAE
"
  input list<Exp.Exp> exps;
  input FuncExpType func;
  input Type_a extraArg;
  output list<Exp.Exp> oexps;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(oexps,oextraArg) := matchcontinue(exps,func,extraArg)
  local Exp.Exp e; 
  case({},func,extraArg) then ({},extraArg);
  case(e::exps,func,extraArg)
    equation
      (e,extraArg) = func(e,extraArg);
      (oexps,extraArg) = traverseDAEExpList(exps,func,extraArg);
    then
      (e::oexps,extraArg);
end matchcontinue;
end traverseDAEExpList;

protected function traverseDAEList "
Author: BZ, 2008-12
Helper function for traverseDAE, traverses a list of dae element list. 
"
  input list<list<Element>> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<list<Element>> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDaeList,Type_a) := matchcontinue(daeList,func,extraArg)
  local 
    list<Element> branch,branch2;
    list<list<Element>> recRes; 
  case({},func,extraArg) then ({},extraArg);
  case(branch::daeList,func,extraArg)
    equation
      (branch2,extraArg) = traverseDAE(branch,func,extraArg);
      (recRes,extraArg) = traverseDAEList(daeList,func,extraArg);
    then
      (branch2::recRes,extraArg);
end matchcontinue;
end traverseDAEList;

public function traverseDAE "
Author: BZ, 2008-12
This function traverses all dae exps.
NOTE, it also traverses DAE.VAR(componenname) as an expression.
"
  input list<Element> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<Element> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDaeList,Type_a) := matchcontinue(daeList,func,extraArg)
  local
    Exp.ComponentRef cr,cr2,cr1,cr1_2;
    list<Element> dae,dae2,elist,elist2,elist22,elist1,elist11;
    Element elt,elt2,elt22,elt1,elt11;
    VarKind kind;
    VarDirection dir;
    Type tp;
    Exp.Exp bindExp,bindExp2,e,e2,e22,e1,e11;
    InstDims dims;
    StartValue start;
    Flow fl;
    list<Absyn.Path> clsLst;
    Option<VariableAttributes> attr;
    Option<Absyn.Comment> cmt;
    Option<Exp.Exp> optExp;
    Absyn.InnerOuter io;
    Types.Type ftp;
    list<Integer> idims;
    ExternalDecl extDecl;
    Ident id;
    Absyn.Path path;
    list<Algorithm.Statement> stmts,stmts2;
    VarProtection prot;
    list<list<Element>> tbs,tbs_1;
    list<Exp.Exp> conds,conds_1, args; 
    Stream st;
    Boolean partialPrefix;
    Absyn.Path path; 
    list<Exp.Exp> expl;
  case({},_,extraArg) then ({},extraArg);
  case(VAR(cr,kind,dir,prot,tp,optExp,dims,fl,st,clsLst,attr,cmt,io,ftp)::dae,func,extraArg) 
    equation
      (Exp.CREF(cr2,_),extraArg) = func(Exp.CREF(cr,Exp.REAL()), extraArg);
      (optExp,extraArg) = traverseDAEOptExp(optExp,func,extraArg);      
      (attr,extraArg) = traverseDAEVarAttr(attr,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then  (VAR(cr2,kind,dir,prot,tp,optExp,dims,fl,st,clsLst,attr,cmt,io,ftp)::dae2,extraArg);
      
  case(DEFINE(cr,e)::dae,func,extraArg)
    equation
      (e2,extraArg) = func(e, extraArg);
      (Exp.CREF(cr2,_),extraArg) = func(Exp.CREF(cr,Exp.REAL()), extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (DEFINE(cr2,e2)::dae2,extraArg);
      
  case(INITIALDEFINE(cr,e)::dae,func,extraArg) 
    equation
      (e2,extraArg) = func(e, extraArg);
      (Exp.CREF(cr2,_),extraArg) = func(Exp.CREF(cr,Exp.REAL()), extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (INITIALDEFINE(cr2,e2)::dae2,extraArg);
      
  case(EQUEQUATION(cr,cr1)::dae,func,extraArg) 
    equation
      (Exp.CREF(cr2,_),extraArg) = func(Exp.CREF(cr,Exp.REAL()), extraArg);
      (Exp.CREF(cr1_2,_),extraArg) = func(Exp.CREF(cr1,Exp.REAL()), extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (EQUEQUATION(cr2,cr1_2)::dae2,extraArg);
      
  case(EQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (EQUATION(e11,e22)::dae2,extraArg);
      
  case(COMPLEX_EQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (COMPLEX_EQUATION(e11,e22)::dae2,extraArg);
      
  case(ARRAY_EQUATION(idims,e1,e2)::dae,func,extraArg) 
    equation
      (e11, extraArg) = func(e1, extraArg);
      (e22, extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (ARRAY_EQUATION(idims,e11,e22)::dae2,extraArg);
      
  case(WHEN_EQUATION(e1,elist,SOME(elt))::dae,func,extraArg) 
    equation
      (e11, extraArg) = func(e1, extraArg);
      ({elt2}, extraArg)= traverseDAE({elt},func,extraArg);
      (elist2, extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (WHEN_EQUATION(e11,elist2,SOME(elt2))::dae2,extraArg);
      
  case(WHEN_EQUATION(e1,elist,NONE)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (WHEN_EQUATION(e11,elist2,NONE)::dae2,extraArg);
      
  case(INITIALEQUATION(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (INITIALEQUATION(e11,e22)::dae2,extraArg);
      
  case(COMP(id,DAE(elist))::dae,func,extraArg) 
    equation
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (COMP(id,DAE(elist))::dae2,extraArg);
      
  case(FUNCTION(path,DAE(elist),ftp,partialPrefix)::dae,func,extraArg) 
    equation
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (FUNCTION(path,DAE(elist2),ftp,partialPrefix)::dae2,extraArg);
      
  case(EXTFUNCTION(path,DAE(elist),ftp,extDecl)::dae,func,extraArg) 
    equation
      (elist2,extraArg) = traverseDAE(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (EXTFUNCTION(path,DAE(elist2),ftp,extDecl)::dae2,extraArg);
      
  case(EXTOBJECTCLASS(path,elt1,elt2)::dae,func,extraArg) 
    equation
      ({elt11,elt22},extraArg) =  traverseDAE({elt1,elt2},func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (EXTOBJECTCLASS(path,elt1,elt2)::dae2,extraArg);
      
  case(ASSERT(e1,e2)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1,extraArg);
      (e22,extraArg) = func(e2,extraArg);          
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (ASSERT(e11,e22)::dae2,extraArg);
      
  case(TERMINATE(e1)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (TERMINATE(e11)::dae2,extraArg);    
  
  case(NORETCALL(path,expl)::dae,func,extraArg) 
    equation
      (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (NORETCALL(path,expl)::dae2,extraArg);
                
  case(NORETCALL(path,expl)::dae,func,extraArg) 
    equation
      (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (NORETCALL(path,expl)::dae2,extraArg);
                
  case(REINIT(cr,e1)::dae,func,extraArg) 
    equation
      (e11,extraArg) = func(e1,extraArg);
      (Exp.CREF(cr2,_),extraArg) = func(Exp.CREF(cr,Exp.REAL()),extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (REINIT(cr2,e11)::dae2,extraArg);
      
  case(ALGORITHM(Algorithm.ALGORITHM(stmts))::dae,func,extraArg) 
    equation
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (ALGORITHM(Algorithm.ALGORITHM(stmts2))::dae2,extraArg);
      
  case(INITIALALGORITHM(Algorithm.ALGORITHM(stmts))::dae,func,extraArg) 
    equation
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (INITIALALGORITHM(Algorithm.ALGORITHM(stmts2))::dae2,extraArg);
      
  case(IF_EQUATION(conds,tbs,elist2)::dae,func,extraArg)
    equation
      (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
      (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
      (elist22,extraArg) = traverseDAE(elist2,func,extraArg);
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (IF_EQUATION(conds_1,tbs_1,elist22)::dae2,extraArg);

  case(INITIAL_IF_EQUATION(conds,tbs,elist2)::dae,func,extraArg)
    equation
      (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
      (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
      (elist22,extraArg) = traverseDAE(elist2,func,extraArg); 
      (dae2,extraArg) = traverseDAE(dae,func,extraArg);
    then (INITIAL_IF_EQUATION(conds_1,tbs_1,elist22)::dae2,extraArg);
  // Empty function call - stefan
  case(NORETCALL(_, _)::dae,func,extraArg)
    equation
      Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"Empty function call in equations", "Move the function calls to appropriate algorithm section"});
      then fail();

  case(elt::_,_,_)
    equation print(" failure in DAE.traverseDAE\n"); dumpElements({elt}); then fail();
end matchcontinue;
end traverseDAE;

public function traverseDAEEquationsStmts "function: traverseDAEEquationsStmts
  Author: BZ, 2008-12
  Helper function to traverseDAE,
  Handles the traversing of Algorithm.Statement.
"
  input list<Algorithm.Statement> inStmts;
  input FuncExpType func;
  input Type_a extraArg;
  output list<Algorithm.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(outStmts,oextraArg) := matchcontinue(inStmts,func,extraArg)
    local
      Exp.Exp e_1,e_2,e,e2;
      list<Exp.Exp> expl1,expl2;
      Exp.ComponentRef cr_1,cr;
      list<Algorithm.Statement> xs_1,xs,stmts,stmts2;
      Exp.Type tp,tt;
      Algorithm.Statement x,ew,ew_1;
      Boolean b1;
      Algorithm.Ident id1;
      list<Integer> li;
  case ({},_,extraArg) then ({},extraArg);
      
  case ((Algorithm.ASSIGN(type_ = tp,exp1 = e2,exp = e) :: xs),func,extraArg)
    equation 
      (e_1,extraArg) = func(e, extraArg);
      (e_2,extraArg) = func(e2, extraArg);
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.ASSIGN(tp,e_2,e_1) :: xs_1,extraArg);
      
  case ((Algorithm.TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg);
      (expl2, extraArg) = traverseDAEExpList(expl1,func,extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then ((Algorithm.TUPLE_ASSIGN(tp,expl2,e_1) :: xs_1),extraArg);
      
  case ((Algorithm.ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg); 
      (e_2 as Exp.CREF(cr_1,_), extraArg) = func(Exp.CREF(cr,Exp.OTHER()), extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.ASSIGN_ARR(tp,cr_1,e_1) :: xs_1,extraArg);
      
  case (((x as Algorithm.FOR(type_=tp,boolean=b1,ident=id1,exp=e,statementLst=stmts)) :: xs),func,extraArg)
    equation 
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.FOR(tp,b1,id1,e_1,stmts2) :: xs_1,extraArg);
      
  case (((x as Algorithm.WHILE(exp = e,statementLst=stmts)) :: xs),func,extraArg)
    equation 
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.WHILE(e_1,stmts2) :: xs_1,extraArg);
      
  case (((x as Algorithm.WHEN(exp = e,statementLst=stmts,elseWhen=NONE,helpVarIndices=li)) :: xs),func,extraArg)
    equation 
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.WHEN(e_1,stmts2,NONE,li) :: xs_1,extraArg);
      
  case (((x as Algorithm.WHEN(exp = e,statementLst=stmts,elseWhen=SOME(ew),helpVarIndices=li)) :: xs),func,extraArg)
    equation 
      ({ew_1}, extraArg) = traverseDAEEquationsStmts({ew},func,extraArg);
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.WHEN(e_1,stmts2,SOME(ew),li) :: xs_1,extraArg);
      
  case (((x as Algorithm.ASSERT(cond = e, msg=e2)) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg); 
      (e_2, extraArg) = func(e2, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.ASSERT(e_1,e_2) :: xs_1,extraArg);
      
  case (((x as Algorithm.TERMINATE(msg = e)) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.TERMINATE(e_1) :: xs_1,extraArg);
      
  case (((x as Algorithm.REINIT(var = e,value=e2)) :: xs),func,extraArg)
    equation 
      (e_1, extraArg) = func(e, extraArg); 
      (e_2, extraArg) = func(e2, extraArg); 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.REINIT(e_1,e_2) :: xs_1,extraArg);
      
  case (((x as Algorithm.NORETCALL(e)) :: xs),func,extraArg)
    local Absyn.Path fnName;
    equation
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.NORETCALL(e_1) :: xs_1,extraArg);
      
  case (((x as Algorithm.RETURN()) :: xs),func,extraArg)
    equation 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (x :: xs_1,extraArg);   
      
  case (((x as Algorithm.BREAK()) :: xs),func,extraArg)
    equation 
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (x :: xs_1,extraArg);
      
  case (((x as Algorithm.IF(exp=e,statementLst=stmts,else_ = el)) :: xs),func,extraArg)
    local Algorithm.Else el,el_1;
    equation 
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1,extraArg) = func(e, extraArg); 
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (Algorithm.IF(e_1,stmts2,el_1) :: xs_1,extraArg);
      
  case ((x :: xs),func,extraArg)
    equation 
      print("Warning, not implemented in replace_equations_stmts\n");
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (x :: xs_1,extraArg);
end matchcontinue;
end traverseDAEEquationsStmts;

protected function traverseDAEEquationsStmtsElse "
Author: BZ, 2008-12
Helper function for traverseDAEEquationsStmts
"
  input Algorithm.Else inElse;
  input FuncExpType func;
  input Type_a extraArg;
  output Algorithm.Else outElse;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (outElse,extraArg) := matchcontinue(inElse,func,extraArg)
  local 
    Exp.Exp e,e_1;
    list<Algorithm.Statement> st,st_1;
    Algorithm.Else el,el_1;
  case(Algorithm.NOELSE(),_,extraArg) then (Algorithm.NOELSE,extraArg);
  case(Algorithm.ELSEIF(e,st,el),func,extraArg)
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
      (e_1,extraArg) = func(e, extraArg); 
    then (Algorithm.ELSEIF(e_1,st_1,el_1),extraArg);
  case(Algorithm.ELSE(st),func,extraArg)
    equation
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
    then (Algorithm.ELSE(st_1),extraArg);      
end matchcontinue;
end traverseDAEEquationsStmtsElse;

protected function traverseDAEVarAttr "
Author: BZ, 2008-12
Help function to traverseDAE
"
  input Option<VariableAttributes> attr;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<VariableAttributes> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input Exp.Exp exp; input Type_a arg; output Exp.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (outAttr,extraArg) := matchcontinue(attr,func,extraArg)
    local Option<Exp.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal,eb;
      Option<StateSelect> stateSelect;
      Option<Boolean> ip,fn;
    case(SOME(VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),func,extraArg) equation
      (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
      (unit,extraArg) = traverseDAEOptExp(unit,func,extraArg);
      (displayUnit,extraArg) = traverseDAEOptExp(displayUnit,func,extraArg);      
      (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
      (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
      (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
      (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      (nominal,extraArg) = traverseDAEOptExp(nominal,func,extraArg);                                          
      then (SOME(VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),extraArg);
   
    case(SOME(VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),func,extraArg) equation
      (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
      (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
      (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
      (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
      (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      then (SOME(VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),extraArg);
    
      case(SOME(VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),func,extraArg) equation
      (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
      (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
      (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      then (SOME(VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),extraArg);

      case(SOME(VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),func,extraArg) equation
      (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
      (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
      then (SOME(VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),extraArg);
        
      case(SOME(VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn)),func,extraArg) equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
      then (SOME(VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn)),extraArg);

      case (NONE(),_,extraArg) then (NONE(),extraArg);        
  end matchcontinue; 
end traverseDAEVarAttr; 

end DAE;

