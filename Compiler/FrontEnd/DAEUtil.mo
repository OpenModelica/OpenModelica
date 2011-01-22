/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package DAEUtil
" file:        DAEUtil.mo
  package:     DAE
  description: DAE management and output

  RCS: $Id$

  This module exports some helper functions to the DAE AST."

public import Absyn;
public import ClassInf;
public import DAE;
public import Env;
public import SCode;
public import Values;
public import ValuesUtil;
public import HashTable;
public import HashTable2;


public constant DAE.AvlTree emptyFuncTree = DAE.AVLTREENODE(NONE(),0,NONE(),NONE());
public constant DAE.DAElist emptyDae = DAE.DAE({});

public function constStr "return the DAE.Const as a string. (VAR|PARAM|CONST)
Used for debugging."
  input DAE.Const const;
  output String str;
algorithm
  str := match(const)
    case(DAE.C_VAR()) then "VAR";
    case(DAE.C_PARAM()) then "PARAM";
    case(DAE.C_CONST()) then "CONST";
      
  end match;
end constStr;

public function expTypeSimple "returns true if type is simple type"
  input DAE.ExpType tp;
  output Boolean isSimple;
algorithm
  isSimple := matchcontinue(tp)
    case(DAE.ET_REAL()) then true;
    case(DAE.ET_INT()) then true;
    case(DAE.ET_STRING()) then true;
    case(DAE.ET_BOOL()) then true;
    case(DAE.ET_ENUMERATION(path=_)) then true;

    case(_) then false;

  end matchcontinue;
end expTypeSimple;

public function expTypeElementType "returns the element type of an array"
  input DAE.ExpType tp;
  output DAE.ExpType eltTp;
algorithm
  eltTp := matchcontinue(tp)
    case(DAE.ET_ARRAY(ty=tp)) then expTypeElementType(tp);
    case(tp) then tp;
  end matchcontinue;
end expTypeElementType;

public function expTypeComplex "returns true if type is complex type"
  input DAE.ExpType tp;
  output Boolean isComplex;
algorithm
  isComplex := matchcontinue(tp)
    case(DAE.ET_COMPLEX(name=_)) then true;
    case(_) then false;
  end matchcontinue;
end expTypeComplex;

public function expTypeArray "returns true if type is array type
Alternative names: isArrayType, isExpTypeArray"
  input DAE.ExpType tp;
  output Boolean isArray;
algorithm
  isArray := matchcontinue(tp)
    case(DAE.ET_ARRAY(ty=_)) then true;
    case(_) then false;
  end matchcontinue;
end expTypeArray;

public function expTypeArrayDimensions "returns the array dimensions of an ExpType"
  input DAE.ExpType tp;
  output list<Integer> dims;
algorithm
  dims := matchcontinue(tp)
    local list<DAE.Dimension> array_dims;
    case(DAE.ET_ARRAY(arrayDimensions=array_dims)) equation
      dims = Util.listMap(array_dims, Expression.dimensionSize);
    then dims;
  end matchcontinue;
end expTypeArrayDimensions;

public function derivativeOrder "
Function to sort derivatives.
Used for Util.sort"
  input tuple<Integer,DAE.derivativeCond> e1,e2; //greaterThanFunc
  output Boolean b;
protected
  Integer i1,i2;
algorithm
  b := match(e1,e2)
    case((i1,_),(i2,_))
      then Util.isIntGreater(i1,i2);
  end match;
end derivativeOrder;

public function getDerivativePaths " collects all paths representing derivative functions for a list of FunctionDefinition's"
  input list<DAE.FunctionDefinition> funcDefs;
  output list<Absyn.Path> paths;
algorithm
  paths := matchcontinue(funcDefs)
    local 
      list<Absyn.Path> pLst1,pLst2;
      Absyn.Path p1,p2;
    
    case({}) then {};
    
    case(DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1,defaultDerivative=SOME(p2),lowerOrderDerivatives=pLst1)::funcDefs)
      equation
        pLst2 = getDerivativePaths(funcDefs);
        paths = Util.listUnion(p1::p2::pLst1,pLst2);
      then 
        paths;
    
    case(DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1,defaultDerivative=NONE(),lowerOrderDerivatives=pLst1)::funcDefs)
      equation
        pLst2 = getDerivativePaths(funcDefs);
        paths = Util.listUnion(p1::pLst1,pLst2);
      then 
        paths;
    
    case(_::funcDefs) then getDerivativePaths(funcDefs);
  end matchcontinue;
end getDerivativePaths;

public function addEquationBoundString "
Set the optional equationBound value"
  input DAE.Exp bindExp;
  input Option<DAE.VariableAttributes> attr;
  output Option<DAE.VariableAttributes> oattr;
algorithm 
  oattr := matchcontinue (bindExp,attr)
    local
       Option<DAE.Exp> e1,e2,e3,e4,e5,e6;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.StateSelect> sSelectOption,sSelectOption2;
      Option<Boolean> ip,fn;
      String s;
  
    case (bindExp,SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,_,ip,fn)))
    then (SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,SOME(bindExp),ip,fn)));
    
    case (bindExp,SOME(DAE.VAR_ATTR_INT(e1,min,e2,e3,_,ip,fn)))
    then SOME(DAE.VAR_ATTR_INT(e1,min,e2,e3,SOME(bindExp),ip,fn));
    
    case (bindExp,SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,_,ip,fn)))
    then SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,SOME(bindExp),ip,fn));
    
    case (bindExp,SOME(DAE.VAR_ATTR_STRING(e1,e2,_,ip,fn)))
    then SOME(DAE.VAR_ATTR_STRING(e1,e2,SOME(bindExp),ip,fn));
       
    case (bindExp,SOME(DAE.VAR_ATTR_ENUMERATION(e1,min,e2,e3,_,ip,fn)))
    then SOME(DAE.VAR_ATTR_ENUMERATION(e1,min,e2,e3,SOME(bindExp),ip,fn));
      
    case(_,_) equation print("-failure in DAEUtil.addEquationBoundString\n"); then fail();
  end matchcontinue;
end addEquationBoundString;

public function getClassList "get list of classes from Var"
  input DAE.Element v;
  output list<Absyn.Path> lst;
algorithm
  lst := matchcontinue(v)
    case DAE.VAR(source = DAE.SOURCE(typeLst=lst)) then lst;
    case _ then {};
  end matchcontinue;
end getClassList;

public function getBoundStartEquation "
Returned bound equation"
  input DAE.VariableAttributes attr;
  output DAE.Exp oe;
algorithm 
  oe := matchcontinue(attr)
    local DAE.Exp beq;
    case (DAE.VAR_ATTR_REAL(equationBound = SOME(beq))) then beq;
    case (DAE.VAR_ATTR_INT(equationBound = SOME(beq))) then beq;
    case (DAE.VAR_ATTR_BOOL(equationBound = SOME(beq))) then beq;
    case (DAE.VAR_ATTR_ENUMERATION(equationBound = SOME(beq))) then beq;
  end matchcontinue;
end getBoundStartEquation;

protected import Algorithm;
protected import BaseHashTable;
protected import Ceval;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ModUtil;
protected import RTOpts;
protected import System;
protected import Types;
protected import Util;
protected import DAEDump;
protected import OptManager;

public function splitDAEIntoVarsAndEquations
"Splits the DAE into one with vars and no equations and algorithms
 and another one which has all the equations and algorithms but no variables.
 Note: the functions are copied to both dae's.
 "
  input DAE.DAElist inDae;
  output DAE.DAElist outDaeNoEqAllVars;
  output DAE.DAElist outDaeAllEqNoVars;
algorithm
  (outDaeNoEqAllVars,outDaeAllEqNoVars) := matchcontinue(inDae)
    local
      DAE.Element v,e;
      list<DAE.Element> elts,elts2,elts22,elts1,elts11,elts3,elts33;
      String  id;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;

    case(DAE.DAE({})) then  (DAE.DAE({}),DAE.DAE({}));

    case(DAE.DAE((v as DAE.VAR(componentRef=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(v::elts2),DAE.DAE(elts3));

    // adrpo: TODO! FIXME! a DAE.COMP SHOULD NOT EVER BE HERE!
    case(DAE.DAE(DAE.COMP(id,elts1,source,cmt)::elts2))
      equation
        (DAE.DAE(elts11),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts1));
        (DAE.DAE(elts22),DAE.DAE(elts33)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts2));
        elts3 = listAppend(elts3,elts33);
      then (DAE.DAE(DAE.COMP(id,elts11,source,cmt)::elts22),DAE.DAE(elts3));

    case(DAE.DAE((e as DAE.EQUATION(exp=_))::elts2))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts2));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.EQUEQUATION(cr1=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIALEQUATION(exp1=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.ARRAY_EQUATION(dimension=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIAL_ARRAY_EQUATION(dimension=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.COMPLEX_EQUATION(lhs=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIAL_COMPLEX_EQUATION(lhs=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIALDEFINE(componentRef=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.DEFINE(componentRef=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.WHEN_EQUATION(condition=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.IF_EQUATION(condition1=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIAL_IF_EQUATION(condition1=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.ALGORITHM(algorithm_=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIALALGORITHM(algorithm_=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    // adrpo: TODO! FIXME! why are external object constructor calls added to the non-equations DAE??
    // PA: are these external object constructor CALLS? Do not think so. But they should anyway be in funcs..
    case(DAE.DAE((e as DAE.EXTOBJECTCLASS(path=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(e::elts2),DAE.DAE(elts3));

    case(DAE.DAE((e as DAE.ASSERT(condition=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.TERMINATE(message=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.REINIT(componentRef=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    // handle also NORETCALL! Connections.root(...)
    case(DAE.DAE((e as DAE.NORETCALL(functionName=_))::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));
    case(DAE.DAE(e::elts))
      equation
        Debug.fprintln("failtrace", "- DAEUtil.splitDAEIntoVarsAndEquations failed on: " );
      then fail();
  end matchcontinue;
end splitDAEIntoVarsAndEquations;

public function removeVariables "Remove the variables in the list from the DAE"
  input DAE.DAElist dae;
  input list<DAE.ComponentRef> vars;
  output DAE.DAElist outDae;
algorithm
  // adrpo: TODO! FIXME! rather expensive function! 
  //        implement this by walking dae once and check element with each var in the list
  //        instead of walking the dae once for each var.
  // outDae := Util.listFold(vars,removeVariable,dae);  
  outDae := matchcontinue(dae, vars)
    local
      list<DAE.Element> elements;    
    case (DAE.DAE(elements), vars)
      equation
        elements = removeVariablesFromElements(elements, vars);
      then
        DAE.DAE(elements);
  end matchcontinue;
end removeVariables;

protected function removeVariablesFromElements
"@author: adrpo
  remove the variables that match for the element list"
  input list<DAE.Element> inElements;
  input list<DAE.ComponentRef> variableNames;
  output list<DAE.Element> outElements;
algorithm
  outElements := matchcontinue(inElements,variableNames)
    local
      DAE.ComponentRef cr;
      list<DAE.Element> rest, els, elist;
      DAE.Element e,v; String id;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;

    // empty case
    case({},_) then {};

    // variable present, remove it
    case(DAE.VAR(componentRef = cr)::rest, variableNames)
      equation
        // variable is in the list! jump over it
        _::_ = Util.listSelect1(variableNames, cr, ComponentReference.crefEqual);
        els = removeVariablesFromElements(rest, variableNames);
      then 
        els;

    // variable not present, keep it        
    case((v as DAE.VAR(componentRef = cr))::rest, variableNames)
      equation
        // variable NOT in the list! jump over it
        {} = Util.listSelect1(variableNames, cr, ComponentReference.crefEqual);
        els = removeVariablesFromElements(rest, variableNames);
      then 
        v::els;

    // handle components
    case(DAE.COMP(id,elist,source,cmt)::rest, variableNames)
      equation
        elist = removeVariablesFromElements(elist, variableNames);
        els = removeVariablesFromElements(rest, variableNames);
      then 
        DAE.COMP(id,elist,source,cmt)::els;

    // anything else, just keep it
    case(v::rest, variableNames)
      equation
        els = removeVariablesFromElements(rest, variableNames);
      then 
        v::els;
  end matchcontinue;
end removeVariablesFromElements;

protected function removeVariable "Remove the variable from the DAE"
  input DAE.ComponentRef var;
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(var,dae)
    local
      DAE.ComponentRef cr;
      list<DAE.Element> elist,elist2;
      DAE.Element e,v; String id;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;

    case(var,DAE.DAE({})) then DAE.DAE({});

    case(var,DAE.DAE((v as DAE.VAR(componentRef = cr))::elist))
      equation
        true = ComponentReference.crefEqualNoStringCompare(var,cr);
      then DAE.DAE(elist);

    case(var,DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2))
      equation
        DAE.DAE(elist) = removeVariable(var,DAE.DAE(elist));
        DAE.DAE(elist2) = removeVariable(var,DAE.DAE(elist2));
      then DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2);

    case(var,DAE.DAE(e::elist))
      equation
        DAE.DAE(elist) = removeVariable(var,DAE.DAE(elist));
      then DAE.DAE(e::elist);
  end matchcontinue;
end removeVariable;

public function removeInnerAttrs "Remove the inner attribute of all vars in list"
  input DAE.DAElist dae;
  input list<DAE.ComponentRef> vars;
  output DAE.DAElist outDae;
algorithm
  outDae := Util.listFold(vars,removeInnerAttr,dae);
end removeInnerAttrs;

public function removeInnerAttr "Remove the inner attribute from variable in the DAE"
  input DAE.ComponentRef var;
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(var,dae)
    local
      DAE.ComponentRef cr,oldVar,newVar;
      list<DAE.Element> elist,elist2,elist3;
      DAE.Element e,v,u,o; String id;
      DAE.VarKind kind;
      DAE.VarDirection dir; DAE.Type tp;
      Option<DAE.Exp> bind; DAE.InstDims dim;
      DAE.Flow flow_; list<Absyn.Path> cls;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt; Absyn.InnerOuter io,io2;
      DAE.VarProtection prot; DAE.Stream st;
      DAE.ElementSource source "the origin of the element";

    case(var,DAE.DAE({})) then DAE.DAE({});
     /* When having an inner outer, we declare two variables on the same line.
        Since we can not handle this with current instantiation procedure, we create temporary variables in the dae.
        These are named uniqly and renamed later in "instClass"
     */
    case(var,DAE.DAE(DAE.VAR(oldVar,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,(io as Absyn.INNEROUTER()))::elist))
      equation
        true = compareUniquedVarWithNonUnique(var,oldVar);
        newVar = nameInnerouterUniqueCref(oldVar);
        o = DAE.VAR(oldVar,kind,dir,prot,tp,NONE(),dim,flow_,st,source,attr,cmt,Absyn.OUTER()) "intact";
        u = DAE.VAR(newVar,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,Absyn.UNSPECIFIED()) " unique'ified";
        elist3 = u::{o};
        elist= listAppend(elist3,elist);
      then
        DAE.DAE(elist);

    case(var,DAE.DAE(DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,io)::elist))
      equation
        true = ComponentReference.crefEqualNoStringCompare(var,cr);
        io2 = removeInnerAttribute(io);
      then
        DAE.DAE(DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,io2)::elist);

    case(var,DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2))
      equation
        DAE.DAE(elist) = removeInnerAttr(var,DAE.DAE(elist));
        DAE.DAE(elist2) = removeInnerAttr(var,DAE.DAE(elist2));
      then DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2);

    case(var,DAE.DAE(e::elist))
      equation
        DAE.DAE(elist)= removeInnerAttr(var,DAE.DAE(elist));
      then DAE.DAE(e::elist);
  end matchcontinue;
end removeInnerAttr;

protected function compareUniquedVarWithNonUnique "
Author: BZ, workaround to get innerouter elements to work.
This function strips the 'unique identifer' from the cref and compares.
"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean equal;
  String s1,s2,s3;
algorithm
  s1 := ComponentReference.printComponentRefStr(cr1);
  s2 := ComponentReference.printComponentRefStr(cr2);
  s1 := System.stringReplace(s1, DAE.UNIQUEIO, "");
  s2 := System.stringReplace(s2, DAE.UNIQUEIO, "");
  equal := stringEq(s1,s2);
end compareUniquedVarWithNonUnique;

public function nameInnerouterUniqueCref "
Author: BZ, 2008-11
Renames a var to unique name"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm outCr := match(inCr)
  local
    DAE.ComponentRef newChild,child;
    String id;
    DAE.ExpType idt;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(id,idt,subs))
    equation
      id = DAE.UNIQUEIO +& id;
    then
      ComponentReference.makeCrefIdent(id,idt,subs);
  case(DAE.CREF_QUAL(id,idt,subs,child))
    equation
      newChild = nameInnerouterUniqueCref(child);
    then
      ComponentReference.makeCrefQual(id,idt,subs,newChild);

end match;
end nameInnerouterUniqueCref;

public function unNameInnerouterUniqueCref "
Function for stripping a cref of its uniqified part.
Remove 'removalString' from the cref if found
"
input DAE.ComponentRef cr;
input String removalString;
output DAE.ComponentRef ocr;
algorithm ocr := matchcontinue(cr,removalString)
  local
    String str,str2;
    DAE.ExpType ty;
    DAE.ComponentRef child,child_2;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(str,ty,subs),removalString)
    equation
      str2 = System.stringReplace(str, removalString, "");
      then
        ComponentReference.makeCrefIdent(str2,ty,subs);
  case(DAE.CREF_QUAL(str,ty,subs,child),removalString)
    equation
      child_2 = unNameInnerouterUniqueCref(child,removalString);
      str2 = System.stringReplace(str, removalString, "");
    then
      ComponentReference.makeCrefQual(str2,ty,subs,child_2);
  case(DAE.WILD(),_) then DAE.WILD();
  case(child,_)
    equation
      print(" failure unNameInnerouterUniqueCref: ");
      print(ComponentReference.printComponentRefStr(child) +& "\n");
      then fail();
  end matchcontinue;
end unNameInnerouterUniqueCref;

protected function getOuterBinding "
Author: BZ, 2008-11
Aquire the binding on the outer/innerouter variable, to transfer to inner variable."
input DAE.ComponentRef currVar;
input list<tuple<DAE.ComponentRef, DAE.Exp>> inlst;
output Option<DAE.Exp> binding;
algorithm binding := matchcontinue(currVar,inlst)
  local DAE.ComponentRef cr1,cr2; DAE.Exp e;
  case(_,{}) then NONE();
  case(cr1,(cr2,e)::inlst)
    equation
      true = ComponentReference.crefEqualNoStringCompare(cr1,cr2);
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
input DAE.Element elt;
output DAE.ComponentRef cr;
algorithm
  cr := match(elt)
    case(DAE.VAR(componentRef = cr)) then cr;
  end match;
end varCref;


public function getUnitAttr "
  Return the unit attribute"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm
  start := matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp u;
    case (SOME(DAE.VAR_ATTR_REAL(_,SOME(u),_,_,_,_,_,_,_,_,_))) then u;
    case (_) then DAE.SCONST("");
  end matchcontinue;
end getUnitAttr;

public function getStartAttrEmpty "
  Return the start attribute."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  input DAE.Exp optExp;
  output DAE.Exp start;
algorithm
  start := matchcontinue (inVariableAttributesOption,optExp)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(start = SOME(r))),_) then r;
    case(_,optExp) then optExp;
  end matchcontinue;
end getStartAttrEmpty;

public function getMinMax "
Author: BZ, returns a list of optional exp, {opt<Min> opt<Max} "
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output list<Option<DAE.Exp>> oExps;
algorithm oExps := matchcontinue(inVariableAttributesOption)
  local
    Option<DAE.Exp> e1,e2;
  case(SOME(DAE.VAR_ATTR_ENUMERATION(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(SOME(DAE.VAR_ATTR_INT(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(SOME(DAE.VAR_ATTR_REAL(min = (e1,e2))))
    equation
    then
      e1::{e2};
  case(_) then {};
  end matchcontinue;
end getMinMax;

public function getStartAttr "
  Return the start attribute."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm
  start := matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(start = SOME(r)))) then r;
    case (_) then DAE.RCONST(0.0);
  end matchcontinue;
end getStartAttr;

public function getStartAttrFail "
  Return the start attribute. or fails"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm start:= match (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(start = SOME(r)))) then r;
  end match;
end getStartAttrFail;

public function setVariableAttributes "sets the attributes of a DAE.Element that is VAR"
  input DAE.Element var;
  input Option<DAE.VariableAttributes> varOpt;
  output DAE.Element outVar;
algorithm
  outVar := match(var,varOpt)
    local
      DAE.ComponentRef cr; DAE.VarKind k;
      DAE.VarDirection d ; DAE.VarProtection p;
      DAE.Type ty; Option<DAE.Exp> b;
      DAE.InstDims  dims; DAE.Flow fl; DAE.Stream st;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt; Absyn.InnerOuter io;

    case(DAE.VAR(cr,k,d,p,ty,b,dims,fl,st,source,_,cmt,io),varOpt)
      then DAE.VAR(cr,k,d,p,ty,b,dims,fl,st,source,varOpt,cmt,io);
  end match;
end setVariableAttributes;

public function setStartAttr "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,start)
    local
      Option<DAE.Exp> q,u,du,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,_,f,n,ss,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,SOME(start),f,n,ss,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,_,f,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,SOME(start),f,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_BOOL(q,_,f,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_BOOL(q,SOME(start),f,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_STRING(q,_,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_STRING(q,SOME(start),eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,SOME(start),du,eb,ip,fn));
    case (NONE(),start)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),SOME(start),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setStartAttr;

public function setUnitAttr "
  sets the unit attribute. .
"
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp unit;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,unit)
    local
      Option<DAE.Exp> q,u,du,f,n,s;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,eb,ip,fn)),unit)
    then SOME(DAE.VAR_ATTR_REAL(q,SOME(unit),du,minMax,s,f,n,ss,eb,ip,fn));
    case (NONE(),unit)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),SOME(unit),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setUnitAttr;

public function setProtectedAttr "
  sets the start attribute. If NONE(), assumes Real attributes.
"
  input Option<DAE.VariableAttributes> attr;
  input Boolean isProtected;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  matchcontinue (attr,isProtected)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,_,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,_,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,_,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,_,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,SOME(isProtected),fn));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn)),isProtected)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,SOME(isProtected),fn));
    case (NONE(),isProtected)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(isProtected),NONE()));
  end matchcontinue;
end setProtectedAttr;

public function getProtectedAttr "
  retrieves the protected attribute form VariableAttributes.
"
  input Option<DAE.VariableAttributes> attr;
  output Boolean isProtected;
algorithm
  isProtected:=
  matchcontinue (attr)
    case (SOME(DAE.VAR_ATTR_REAL(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_INT(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_BOOL(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_STRING(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(isProtected=SOME(isProtected)))) then isProtected;
    case(_) then false;
  end matchcontinue;
end getProtectedAttr;

public function setFixedAttr "Function: setFixedAttr
Sets the start attribute:fixed to inputarg
"
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  matchcontinue (attr,start)
    local
      Option<DAE.Exp> q,u,du,i,f,n,ini;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,ini,_,n,ss,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,ini,start,n,ss,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,ini,_,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,ini,start,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_BOOL(q,ini,_,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_BOOL(q,ini,start,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,_,eb,ip,fn)),start)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,start,eb,ip,fn));
  end matchcontinue;
end setFixedAttr;

public function setFinalAttr "
  sets the start attribute. If NONE(), assumes Real attributes.
"
  input Option<DAE.VariableAttributes> attr;
  input Boolean finalPrefix;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,finalPrefix)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Exp> eb;
      Option<Boolean> ip;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,eb,ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,eb,ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,SOME(finalPrefix)));

    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,_)),finalPrefix)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,SOME(finalPrefix)));

    case (NONE(),finalPrefix)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(finalPrefix)));
  end match;
end setFinalAttr;

public function boolVarProtection "Function: boolVarProtection
Takes a DAE.varprotection and returns true/false (is_protected / not)
"
  input DAE.VarProtection vp;
  output Boolean prot;
algorithm
  prot := matchcontinue(vp)
    case(DAE.PUBLIC()) then false;
    case(DAE.PROTECTED()) then true;
    case(_) equation print("- DAEUtil.boolVa_Protection failed\n"); then fail();
  end matchcontinue;
end boolVarProtection;

public function hasStartAttr "
  Returns true if variable attributes defines a start value."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output Boolean hasStart;
algorithm
  hasStart:=
  matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then true;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then true;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then true;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then true;
    case (_) then false;
  end matchcontinue;
end hasStartAttr;

public function getStartAttrString "function: getStartAttrString

  Return the start attribute as a string.
"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      String s;
      DAE.Exp r;
    case (NONE()) then "";
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r))))
      equation
        s = ExpressionDump.printExpStr(r);
      then
        s;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r))))
      equation
        s = ExpressionDump.printExpStr(r);
      then
        s;
    case (_) then "";
  end matchcontinue;
end getStartAttrString;

public function getMatchingElements "function getMatchingElements
  author:  LS

  Retrive the elements for which the function given as second argument
  succeeds.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond;
  output list<DAE.Element> oelist;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm
  oelist := Util.listFilter(elist, cond);
end getMatchingElements;

public function getAllMatchingElements "function getAllMatchingElements
  author:  PA

  Similar to getMatchingElements but traverses down in COMP elements also.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond;
  output list<DAE.Element> outElist;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm
  outElist := matchcontinue(elist,cond)
    local
      list<DAE.Element> elist2;
      DAE.Element e;
    case({},_) then {};
    case(DAE.COMP(dAElist=elist)::elist2,cond) equation
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

public function findAllMatchingElements "function findAllMatchingElements
  author:  adrpo
  Similar to getMatchingElements but gets two conditions and returns two lists. The functions are copied to both."
  input DAE.DAElist elist;
  input FuncTypeElementTo cond1;
  input FuncTypeElementTo cond2;
  output DAE.DAElist firstList;
  output DAE.DAElist secondList;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm
  (firstList,secondList) := matchcontinue(elist,cond1,cond2)
    local
      list<DAE.Element> rest, lst, elist1, elist2, elist1a, elist2a;
      DAE.Element e;

    // handle the empty case
    case(DAE.DAE({}),_,_) then (DAE.DAE({}),DAE.DAE({}));
    // handle the dive-in case
    case(DAE.DAE(DAE.COMP(dAElist=lst)::rest),cond1,cond2)
      equation
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(lst),cond1,cond2);
        (DAE.DAE(elist1a),DAE.DAE(elist2a)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
        elist1 = listAppend(elist1,elist1a);
        elist2 = listAppend(elist2,elist2a);
      then (DAE.DAE(elist1),DAE.DAE(elist2));
    // handle both first and second condition true!
    case(DAE.DAE(e::rest),cond1,cond2)
      equation
        cond1(e);
        cond2(e);
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(e::elist1),DAE.DAE(e::elist2));
    // handle first condition true
    case(DAE.DAE(e::rest),cond1,cond2)
      equation
        cond1(e);
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(e::elist1),DAE.DAE(elist2));
    // handle the second condition
    case(DAE.DAE(e::rest),cond1,cond2)
      equation
        cond2(e);
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(elist1),DAE.DAE(e::elist2));
    // move to next element.
    case(DAE.DAE(e::rest),cond1,cond2)
      equation
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(elist1),DAE.DAE(elist2));
  end matchcontinue;
end findAllMatchingElements;

public function isAfterIndexInlineFunc "
Author BZ
"
input DAE.Function inElem;
output Boolean b;
algorithm
  b := matchcontinue(inElem)
    case(DAE.FUNCTION(inlineType=DAE.AFTER_INDEX_RED_INLINE())) then true;
    case(_) then false;
  end matchcontinue;
end isAfterIndexInlineFunc;

public function isParameter "function isParameter
  author: LS
  Succeeds if element is parameter.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.VAR(kind = DAE.PARAM()) then ();
  end matchcontinue;
end isParameter;

public function isParameterOrConstant "
  author: BZ 2008-06
  Succeeds if element is constant/parameter.
"
  input DAE.Element inElement;
  output Boolean b;
algorithm
  b:=
  matchcontinue (inElement)
    case DAE.VAR(kind = DAE.CONST()) then true;
    case DAE.VAR(kind = DAE.PARAM()) then true;
    case(_) then false;
  end matchcontinue;
end isParameterOrConstant;

public function isInnerVar "function isInnerVar
  author: PA

  Succeeds if element is a variable with prefix inner.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.VAR(innerOuter = Absyn.INNER()) then ();
    case DAE.VAR(innerOuter = Absyn.INNEROUTER())then ();
  end matchcontinue;
end isInnerVar;

public function isOuterVar "function isOuterVar
  author: PA
  Succeeds if element is a variable with prefix outer.
"
  input DAE.Element inElement;
algorithm _:= matchcontinue (inElement)
    case DAE.VAR(innerOuter = Absyn.OUTER()) then ();
    // FIXME? adrpo: do we need this?
    // case DAE.VAR(innerOuter = Absyn.INNEROUTER()) then ();
  end matchcontinue;
end isOuterVar;

public function isComp "function isComp
  author: LS

  Succeeds if element is component, COMP.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.COMP(ident = _) then ();
  end matchcontinue;
end isComp;

public function getOutputVars "function getOutputVars
  author: LS

  Retrieve all output variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isOutputVar);
end getOutputVars;

public function getProtectedVars "
  author: PA

  Retrieve all protected variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isProtectedVar);
end getProtectedVars;

public function getBidirVars "function get_output_vars
  author: LS

  Retrieve all bidirectional variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isBidirVar);
end getBidirVars;

public function getInputVars "
  Retrieve all input variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isInput);
end getInputVars;

public function isFlowVar
  "Succeeds if the given variable has a flow prefix."
  input DAE.Element inElement;
algorithm
  DAE.VAR(kind = DAE.VARIABLE(), flowPrefix = DAE.FLOW()) := inElement;
end isFlowVar;

public function isStreamVar
  "Succeeds if the given variable has a stream prefix."
  input DAE.Element inElement;
algorithm
  DAE.VAR(kind = DAE.VARIABLE(), streamPrefix = DAE.STREAM()) := inElement;
end isStreamVar;

public function isOutputVar
"Succeeds if Element is an output variable."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.OUTPUT()) then ();
  end match;
end isOutputVar;

public function isProtectedVar
"Succeeds if Element is a protected variable."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(protection=DAE.PROTECTED()) then ();
  end match;
end isProtectedVar;

public function isPublicVar "
  Succeeds if Element is a public variable.
"
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(protection=DAE.PUBLIC()) then ();
  end match;
end isPublicVar;

public function isBidirVar "
  Succeeds if Element is a bidirectional variable.
"
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.BIDIR()) then ();
  end match;
end isBidirVar;

public function isInputVar "
  Succeeds if Element is an input variable.
"
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.INPUT()) then ();
  end match;
end isInputVar;

public function isInput "
  Succeeds if Element is an input .
"
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(direction = DAE.INPUT()) then ();
  end match;
end isInput;

public function isNotVar "
  Succeeds if Element is *not* a variable."
  input DAE.Element e;
algorithm
  failure(isVar(e));
end isNotVar;

public function isVar "
  Succeeds if Element is a variable."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(componentRef = _) then ();
  end match;
end isVar;

public function isFunctionRefVar "
  return true if the element is a function reference variable"
  input DAE.Element inElem;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inElem)
    case DAE.VAR(ty = (DAE.T_FUNCTION(_,_,_),_)) then true;
    else false;
  end match;
end isFunctionRefVar;

public function isAlgorithm "function: isAlgorithm
  author: LS

  Succeeds if Element is an algorithm."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.ALGORITHM(algorithm_ = _) then ();
  end match;
end isAlgorithm;

public function isFunctionInlineFalse "function: isFunctionInlineFalse
  author: PA

  Succeeds if is a function with Inline=false"
  input DAE.Function inElement;
  output Boolean res;
algorithm
  res := match (inElement)
    case DAE.FUNCTION(inlineType = DAE.NO_INLINE()) then true;
    else false;
  end match;
end isFunctionInlineFalse;

public function findElement "function: findElement

  Search for an element for which the function passed as second
  argument succeds. If no element is found return NONE.
"
  input list<DAE.Element> inElementLst;
  input FuncTypeElementTo inFuncTypeElementTo;
  output Option<DAE.Element> outElementOption;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm
  outElementOption:=
  matchcontinue (inElementLst,inFuncTypeElementTo)
    local
      DAE.Element e;
      list<DAE.Element> rest;
      FuncTypeElementTo f;
      Option<DAE.Element> e_1;
    case ({},_) then NONE();
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

public function getVariableBindingsStr "function: getVariableBindingsStr

  This function takes a `DAE.Element\' list and returns a comma separated
  string of variable bindings.
  E.g. model A Real x=1; Real y=2; end A; => \"1,2\"
"
  input list<DAE.Element> elts;
  output String str;
protected
  list<DAE.Element> varlst;
algorithm
  varlst := getVariableList(elts);
  str := getBindingsStr(varlst);
end getVariableBindingsStr;

protected function getVariableList "function: getVariableList

  Return all variables from an Element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst:=
  matchcontinue (inElementLst)
    local
      list<DAE.Element> res,lst;
      DAE.Element x;

    /* adrpo: filter out records! */
    case ((x as DAE.VAR(ty = (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_))) :: lst)
      equation
        res = getVariableList(lst);
      then
        (res);

    case ((x as DAE.VAR(_,_,_,_,_,_,_,_,_,_,_,_,_)) :: lst)
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
  input list<DAE.Element> inElementLst;
  output String outString;
algorithm
  outString:=
  match (inElementLst)
    local
      String expstr,s3,s4,str,s1,s2;
      DAE.Element v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Element> lst;
    case (((v as DAE.VAR(componentRef = cr,binding = SOME(e))) :: (lst as (_ :: _))))
      equation
        expstr = ExpressionDump.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((v as DAE.VAR(componentRef = cr,binding = NONE())) :: (lst as (_ :: _))))
      equation
        s1 = "-,";
        s2 = getBindingsStr(lst);
        str = stringAppend(s1, s2);
      then
        str;
    case ({(v as DAE.VAR(componentRef = cr,binding = SOME(e)))})
      equation
        str = ExpressionDump.printExpStr(e);
      then
        str;
    case ({(v as DAE.VAR(componentRef = cr,binding = NONE()))}) then "";
  end match;
end getBindingsStr;

public function getBindings "function: getBindingsStr
Author: BZ, 2008-11
Get variable-bindings from element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outc;
  output list<DAE.Exp> oute;
algorithm (outc,oute) := matchcontinue (inElementLst)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      case({}) then ({},{});
    case (DAE.VAR(componentRef = cr,binding = SOME(e)) :: inElementLst)
      equation
        (outc,oute) = getBindings(inElementLst);
      then
        (cr::outc,e::oute);
    case (DAE.VAR(componentRef = cr,binding  = NONE()) :: inElementLst)
      equation
        (outc,oute) = getBindings(inElementLst);
      then (outc,oute);
    case (_) equation print(" error in getBindings \n"); then fail();
  end matchcontinue;
end getBindings;

public function toFlow "function: toFlow

  Create a Flow, given a ClassInf.State and a boolean flow value.
"
  input Boolean inBoolean;
  input ClassInf.State inState;
  output DAE.Flow outFlow;
algorithm
  outFlow:=
  matchcontinue (inBoolean,inState)
    case (true,_) then DAE.FLOW();
    case (_,ClassInf.CONNECTOR(path = _)) then DAE.NON_FLOW();
    case (_,_) then DAE.NON_CONNECTOR();
  end matchcontinue;
end toFlow;

public function toStream "function: toStram
  Create a Stream, given a ClassInf.State and a boolean stream value."
  input Boolean inBoolean;
  input ClassInf.State inState;
  output DAE.Stream outStream;
algorithm
  outStream := matchcontinue (inBoolean,inState)
    case (true,_) then DAE.STREAM();
    case (_,ClassInf.CONNECTOR(path = _)) then DAE.NON_STREAM();
    case (_,_) then DAE.NON_STREAM_CONNECTOR();
  end matchcontinue;
end toStream;

public function getFlowVariables "function: getFlowVariables

  Retrive the flow variables of an Element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<DAE.ComponentRef> res,res1,res1_1,res2;
      DAE.ComponentRef cr;
      list<DAE.Element> xs,lst;
      String id;
    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,flowPrefix = DAE.FLOW()) :: xs))
      equation
        res = getFlowVariables(xs);
      then
        (cr :: res);
    case ((DAE.COMP(ident = id,dAElist = lst) :: xs))
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
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input String inIdent;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      String id;
      list<DAE.ComponentRef> res,xs;
      DAE.ComponentRef cr_1,cr;
    case ({},id) then {};
    case ((cr :: xs),id)
      equation
        res = getFlowVariables2(xs, id);
        cr_1 = ComponentReference.makeCrefQual(id,DAE.ET_OTHER(),{}, cr);
      then
        (cr_1 :: res);
  end matchcontinue;
end getFlowVariables2;

public function getStreamVariables "function: getStreamVariables
  Retrive the stream variables of an Element list."
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<DAE.ComponentRef> res,res1,res1_1,res2;
      DAE.ComponentRef cr;
      list<DAE.Element> xs,lst;
      String id;
    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,streamPrefix = DAE.STREAM()) :: xs))
      equation
        res = getStreamVariables(xs);
      then
        (cr :: res);
    case ((DAE.COMP(ident = id,dAElist = lst) :: xs))
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
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input String inIdent;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      String id;
      list<DAE.ComponentRef> res,xs;
      DAE.ComponentRef cr_1,cr;
    case ({},id) then {};
    case ((cr :: xs),id)
      equation
        res = getStreamVariables2(xs, id);
        cr_1 = ComponentReference.makeCrefQual(id,DAE.ET_OTHER(),{}, cr);
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
  input list<DAE.Element> inElementLst;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output Values.Value outValue;
algorithm
  (outCache, outValue) := matchcontinue (inCache,inEnv,inPath,inElementLst,inBoolean)
    local
      Absyn.Path cname;
      Values.Value value,res;
      list<Values.Value> vals;
      list<String> names;
      String cr_str, str;
      DAE.ComponentRef cr;
      DAE.Exp rhs;
      list<DAE.Element> rest;
      Boolean impl;
      Integer ix;
      DAE.Element el;
      Env.Cache cache;
      Env.Env env;

    case (cache,env,cname,{},_) then (cache,Values.RECORD(cname,{},{},-1));  /* impl */
    case (cache,env,cname,DAE.VAR(componentRef = cr, binding = SOME(rhs)) :: rest, impl)
      equation
        // Debug.fprintln("failtrace", "- DAEUtil.daeToRecordValue typeOfRHS: " +& ExpressionDump.typeOfString(rhs));
        (cache, value,_) = Ceval.ceval(cache, env, rhs, impl,NONE(), NONE(), Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = ComponentReference.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    /*
    case (cache,env,cname,(DAE.EQUATION(exp = DAE.CREF(componentRef = cr),scalar = rhs) :: rest),impl)
      equation
        (cache, value,_) = Ceval.ceval(Env.emptyCache(),{}, rhs, impl,NONE(), NONE(), Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = ComponentReference.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    */
    case (cache,env,_,el::_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        str = DAEDump.dumpDebugDAE(DAE.DAE({el}));
        Debug.fprintln("failtrace", "- DAEUtil.daeToRecordValue failed on: " +& str);
      then
        fail();
  end matchcontinue;
end daeToRecordValue;

public function toModelicaForm "function toModelicaForm.

  Transforms all variables from a.b.c to a_b_c, etc
"
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm
  outDAElist:=
  matchcontinue (inDAElist)
    local list<DAE.Element> elts_1,elts;
    case (DAE.DAE(elts))
      equation
        elts_1 = toModelicaFormElts(elts);
      then
        DAE.DAE(elts_1);
  end matchcontinue;
end toModelicaForm;

protected function toModelicaFormElts "function: toModelicaFormElts
  Helper function to toModelicaForm."
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst := matchcontinue (inElementLst)
    local
      String str,str_1,id;
      list<DAE.Element> elts_1,elts,welts_1,welts,telts_1,eelts_1,telts,eelts,elts2;
      Option<DAE.Exp> d_1,d,f;
      DAE.ComponentRef cr,cr_1,cref_,cr1,cr2;
      DAE.ExpType ty;
      DAE.VarKind a;
      DAE.VarDirection b;
      DAE.Type t;
      DAE.InstDims instDim;
      DAE.Flow g;
      DAE.Stream streamPrefix;
      DAE.Stream s;
      DAE.Element elt_1,elt;
      DAE.DAElist dae_1,dae;
      DAE.VarProtection prot;
      list<Absyn.Path> h;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e_1,e1_1,e2_1,e1,e2,e_2,e;
      Absyn.Path p;
      Absyn.InnerOuter io;
      list<DAE.Exp> conds, conds_1;
      list<list<DAE.Element>> trueBranches, trueBranches_1;
      Boolean partialPrefix;
      list<DAE.FunctionDefinition> derFuncs;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the element origin";
      Algorithm.Algorithm alg;

    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,
               kind = a,
               direction = b,
               protection = prot,
               ty = t,
               binding = d,
               dims = instDim,
               flowPrefix = g,
               streamPrefix = streamPrefix,
               source=source,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io) :: elts))
      equation
        str = ComponentReference.printComponentRefStr(cr);
        str_1 = Util.stringReplaceChar(str, ".", "_");
        elts_1 = toModelicaFormElts(elts);
        d_1 = toModelicaFormExpOpt(d);
        ty = ComponentReference.crefLastType(cr);
        cref_ = ComponentReference.makeCrefIdent(str_1,ty,{});
      then
        (DAE.VAR(cref_,a,b,prot,t,d_1,instDim,g,streamPrefix,source,dae_var_attr,comment,io) :: elts_1);

    case ((DAE.DEFINE(componentRef = cr,exp = e,source = source) :: elts))
      equation
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.DEFINE(cr_1,e_1,source) :: elts_1);

    case ((DAE.INITIALDEFINE(componentRef = cr,exp = e,source = source) :: elts))
      equation
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALDEFINE(cr_1,e_1,source) :: elts_1);

    case ((DAE.EQUATION(exp = e1,scalar = e2,source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.EQUATION(e1_1,e2_1,source) :: elts_1);

    case ((DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.COMPLEX_EQUATION(e1_1,e2_1,source) :: elts_1);

    case ((DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIAL_COMPLEX_EQUATION(e1_1,e2_1,source) :: elts_1);

    case ((DAE.EQUEQUATION(cr1 = cr1,cr2 = cr2,source = source) :: elts))
      equation
         DAE.CREF(cr1,_) = toModelicaFormExp(Expression.crefExp(cr1));
         DAE.CREF(cr2,_) = toModelicaFormExp(Expression.crefExp(cr2));
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.EQUEQUATION(cr1,cr2,source) :: elts_1);

    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = SOME(elt),source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        {elt_1} = toModelicaFormElts({elt});
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,SOME(elt_1),source) :: elts_1);

    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = NONE(),source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,NONE(),source) :: elts_1);

    case ((DAE.IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts,source = source) :: elts))
      equation
        conds_1 = Util.listMap(conds,toModelicaFormExp);
        trueBranches_1 = Util.listMap(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.IF_EQUATION(conds_1,trueBranches_1,eelts_1,source) :: elts_1);

    case ((DAE.INITIAL_IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts,source = source) :: elts))
      equation
        conds_1 = Util.listMap(conds,toModelicaFormExp);
        trueBranches_1 = Util.listMap(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIAL_IF_EQUATION(conds_1,trueBranches_1,eelts_1,source) :: elts_1);

    case ((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALEQUATION(e1_1,e2_1,source) :: elts_1);

    case ((DAE.ALGORITHM(algorithm_ = alg,source = source) :: elts))
      equation
        print("to_modelica_form_elts(ALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.ALGORITHM(alg,source) :: elts_1);

    case ((DAE.INITIALALGORITHM(algorithm_ = alg,source = source) :: elts))
      equation
        print("to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALALGORITHM(alg,source) :: elts_1);

    case ((DAE.COMP(ident = id,dAElist = elts2,source = source, comment = comment) :: elts))
      equation
        elts2 = toModelicaFormElts(elts2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.COMP(id,elts2,source,comment) :: elts_1);

    case ((DAE.ASSERT(condition = e1,message=e2,source = source) :: elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
        e_2 = toModelicaFormExp(e2);
      then
        (DAE.ASSERT(e_1,e_2,source) :: elts_1);
    case ((DAE.TERMINATE(message = e1,source = source) :: elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
      then
        (DAE.TERMINATE(e_1,source) :: elts_1);
  end matchcontinue;
end toModelicaFormElts;

public function replaceCrefInVar "
Author BZ
 Function for updating the Component Ref of the Var"
  input DAE.ComponentRef newCr;
  input DAE.Element inelem;
  output DAE.Element outelem;
algorithm
  outelem := match(newCr, inelem)
    local
      DAE.ComponentRef a1; DAE.VarKind a2;
      DAE.VarDirection a3; DAE.VarProtection a4;
      DAE.Type a5; DAE.InstDims a7; DAE.Flow a8;
      DAE.Stream a9; Option<DAE.Exp> a6;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> a11;
      Option<SCode.Comment> a12; Absyn.InnerOuter a13;
    case(newCr, DAE.VAR(a1,a2,a3,a4,a5,a6,a7,a8,a9,source,a11,a12,a13))
      then DAE.VAR(newCr,a2,a3,a4,a5,a6,a7,a8,a9,source,a11,a12,a13);
  end match;
end replaceCrefInVar;

protected function toModelicaFormExpOpt "function: toModelicaFormExpOpt
  Helper function to toMdelicaFormElts."
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption := matchcontinue (inExpExpOption)
    local DAE.Exp e_1,e;
    case (SOME(e)) equation e_1 = toModelicaFormExp(e); then SOME(e_1);
    case (NONE()) then NONE();
  end matchcontinue;
end toModelicaFormExpOpt;

protected function toModelicaFormCref "function: toModelicaFormCref
  Helper function to toModelicaFormElts."
  input DAE.ComponentRef cr;
  output DAE.ComponentRef outComponentRef;
protected
  String str,str_1;
  DAE.ExpType ty;
algorithm
  str := ComponentReference.printComponentRefStr(cr);
  ty := ComponentReference.crefLastType(cr);
  str_1 := Util.stringReplaceChar(str, ".", "_");
  outComponentRef := ComponentReference.makeCrefIdent(str_1,ty,{});
end toModelicaFormCref;

protected function toModelicaFormExp "function: toModelicaFormExp
  Helper function to toModelicaFormElts."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      DAE.ComponentRef cr_1,cr;
      DAE.ExpType t,tp;
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e,e3_1,e3;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path f;
      Boolean b,bt;
      Integer i;
      Option<DAE.Exp> eopt_1,eopt;
      DAE.InlineType il;
    
    case (DAE.CREF(componentRef = cr,ty = t))
      equation
        cr_1 = toModelicaFormCref(cr);
      then
        Expression.makeCrefExp(cr_1,t);
    
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.BINARY(e1_1,op,e2_1);
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.LBINARY(e1_1,op,e2_1);
    case (DAE.UNARY(operator = op,exp = e))
      equation
        e_1 = toModelicaFormExp(e);
      then
        DAE.UNARY(op,e_1);
    case (DAE.LUNARY(operator = op,exp = e))
      equation
        e_1 = toModelicaFormExp(e);
      then
        DAE.LUNARY(op,e_1);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.RELATION(e1_1,op,e2_1,-1,NONE());
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        e3_1 = toModelicaFormExp(e3);
      then
        DAE.IFEXP(e1_1,e2_1,e3_1);
    case (DAE.CALL(path = f,expLst = expl,tuple_ = bt,builtin = b,ty=tp,inlineType=il))
      equation
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        DAE.CALL(f,expl_1,bt,b,tp,il);
    case (DAE.ARRAY(ty = t,scalar = b,array = expl))
      equation
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        DAE.ARRAY(t,b,expl_1);
    case (DAE.TUPLE(PR = expl))
      equation
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        DAE.TUPLE(expl_1);
    case (DAE.CAST(ty = t,exp = e))
      equation
        e_1 = toModelicaFormExp(e);
      then
        DAE.CAST(t,e_1);
    case (DAE.ASUB(exp = e,sub = expl))
      equation
        e_1 = toModelicaFormExp(e);
      then
        Expression.makeASUB(e_1,expl);
    case (DAE.SIZE(exp = e,sz = eopt))
      equation
        e_1 = toModelicaFormExp(e);
        eopt_1 = toModelicaFormExpOpt(eopt);
      then
        DAE.SIZE(e_1,eopt_1);
    case (e) then e;
  end matchcontinue;
end toModelicaFormExp;

public function getNamedFunction "Return the FUNCTION with the given name. Fails if not found."
  input Absyn.Path path;
  input DAE.FunctionTree functions;
  output DAE.Function outElement;
algorithm
  outElement := matchcontinue (path,functions)
    local
      String msg;
    case (path,functions) then Util.getOption(avlTreeGet(functions, path));
    case (path,functions)
      equation
        msg = Util.stringDelimitList(Util.listMapMap(getFunctionList(functions), functionName, Absyn.pathString), "\n  ");
        msg = "DAEUtil.getNamedFunction failed: " +& Absyn.pathString(path) +& "\nThe following functions were part of the cache:\n  ";
        // Error.addMessage(Error.INTERNAL_ERROR,{msg});
        Debug.fprintln("failtrace", msg);
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getNamedFunctionFromList "Is slow; PartFn.mo should be rewritten using the FunctionTree"
  input Absyn.Path path;
  input list<DAE.Function> fns;
  output DAE.Function fn;
algorithm
  fn := matchcontinue (path,fns)
    local
    case (path,fn::fns)
      equation
        true = Absyn.pathEqual(functionName(fn),path);
      then fn;
    case (path,fn::fns) then getNamedFunctionFromList(path, fns);
    case (path,{})
      equation
        Debug.fprintln("failtrace", "- DAEUtil.getNamedFunctionFromList failed " +& Absyn.pathString(path));
      then
        fail();
  end matchcontinue;
end getNamedFunctionFromList;

protected function getFunctionsElements
  input list<DAE.Function> elements;
  output list<DAE.Element> els;
protected
  list<list<DAE.Element>> elsList;
algorithm
  elsList := Util.listMap(elements, getFunctionElements);
  els := Util.listFlatten(elsList);
end getFunctionsElements;

public function getFunctionElements
  input DAE.Function fn;
  output list<DAE.Element> els;
algorithm
  els := match fn
    local
      list<DAE.Element> elements;
    case DAE.FUNCTION(functions = (DAE.FUNCTION_DEF(body = elements)::_)) then elements;
    case DAE.FUNCTION(functions = (DAE.FUNCTION_EXT(body = elements)::_)) then elements;
    case DAE.RECORD_CONSTRUCTOR(path = _) then {};
  end match;
end getFunctionElements;

protected function crefToExp "function: crefToExp

  Makes an expression from a ComponentRef.
"
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp:= Expression.makeCrefExp(inComponentRef,DAE.ET_OTHER());
end crefToExp;

public function verifyWhenEquation
"This function verifies when-equations.
Returns the crefs written to, and also checks for illegal statements in when-body eqn's."
  input list<DAE.Element> inElems;
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs := match (inElems)
    local
      list<DAE.Element> elems1,moreWhen;
      list<DAE.ComponentRef> crefs1;

    case {} then {};
      // no need to check elseWhen, they are being handled in a reverse order, from inst.mo.
    case (DAE.WHEN_EQUATION(equations=elems1)::moreWhen)
      equation
        crefs1 = verifyWhenEquationStatements(elems1,{});
      then listReverse(crefs1);
    case (elems1)
      equation
        crefs1 = verifyWhenEquationStatements(elems1,{});
      then listReverse(crefs1);
  end match;
end verifyWhenEquation;

protected function verifyWhenEquationStatements2 ""
  input list<DAE.Exp> inExps;
  input list<DAE.ComponentRef> acc;
  input DAE.ElementSource source "the element origin";
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs := match(inExps,acc,source)
    local
      DAE.Exp e;
    case ({},acc,_) then acc;
    case (e::inExps,acc,source)
      equation
        acc = verifyWhenEquationStatements({DAE.EQUATION(e,e,source)},acc);
      then verifyWhenEquationStatements2(inExps,acc,source);
  end match;
end verifyWhenEquationStatements2;

protected function verifyWhenEquationStatements "
Author BZ, 2008-09
Helper function for verifyWhenEquation
TODO: add some error reporting for this."
  input list<DAE.Element> inElems;
  input list<DAE.ComponentRef> acc;
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs:= match (inElems,acc)
    local
      String msg;
      list<DAE.Exp> exps,exps1;
      DAE.Exp exp,ee1,ee2;
      DAE.ComponentRef cref;
      DAE.Element el;
      list<DAE.Element> eqsfalseb,rest;
      list<list<DAE.Element>> eqstrueb;
      list<DAE.ComponentRef> crefs1,crefs2;
      DAE.ElementSource source "the element origin";
      list<list<DAE.ComponentRef>> crefslist;
      Boolean b;

    case({},acc) then acc;
    
    case(DAE.VAR(componentRef = _)::rest,acc)
      then verifyWhenEquationStatements(rest,acc);
    
    case(DAE.DEFINE(componentRef = cref,exp = exp)::rest,acc)
      then verifyWhenEquationStatements(rest,cref::acc);
    
    case(DAE.EQUATION(exp = DAE.CREF(cref,_))::rest,acc)
      then verifyWhenEquationStatements(rest,cref::acc);
    
    case(DAE.EQUATION(exp = DAE.TUPLE(exps1),source=source)::rest,acc)
      equation
        acc = verifyWhenEquationStatements2(exps1,acc,source);
      then verifyWhenEquationStatements(rest,acc);
    
    case(DAE.ARRAY_EQUATION(exp = DAE.CREF(cref, _)) :: rest,acc)
      then verifyWhenEquationStatements(rest,cref::acc);
    
    case(DAE.EQUEQUATION(cr1=cref,cr2=_)::rest,acc)
      then verifyWhenEquationStatements(rest,cref::acc);

    case(DAE.IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb,source = source)::rest,acc)
      equation
        crefslist = Util.listMap1(eqstrueb,verifyWhenEquationStatements,{});
        crefs2 = verifyWhenEquationStatements(eqsfalseb,{});
        crefslist = crefs2::crefslist;
        (crefs1,b) = compareCrefList(crefslist);
        Error.assertionOrAddSourceMessage(b,Error.WHEN_EQ_LHS,{"All branches must write to the same variable"},getElementSourceFileInfo(source));
        acc = listAppend(crefs1,acc);
      then verifyWhenEquationStatements(rest,acc);
    
    case(DAE.ASSERT(condition=ee1,message=ee2)::rest,acc)
      then verifyWhenEquationStatements(rest,acc);
    
    case(DAE.TERMINATE(message = _)::rest,acc)
      then verifyWhenEquationStatements(rest,acc);
    
    case(DAE.REINIT(componentRef=cref,source=source)::rest,acc)
      then verifyWhenEquationStatements(rest,acc);

    // adrpo: TODO! FIXME! WHY??!! we might push values to a file writeFile(time);
    case(DAE.NORETCALL(functionName=_)::rest,acc)
      then verifyWhenEquationStatements(rest,acc);
    
    case(DAE.EQUATION(exp = exp, source=source)::rest,acc)
      equation
        msg = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.WHEN_EQ_LHS,{msg},getElementSourceFileInfo(source));
      then fail();
    
    case(DAE.WHEN_EQUATION(condition = _,source=source)::rest,acc)
      equation
        Error.addSourceMessage(Error.NESTED_WHEN,{},getElementSourceFileInfo(source));
      then
        fail();
    
    case(el::_,acc)
      equation
        msg = "- DAEUtil.verifyWhenEquationStatements failed on: " +& DAEDump.dumpElementsStr({el}); 
        Error.addMessage(Error.INTERNAL_ERROR,{msg});
      then
        fail();
  end match;
end verifyWhenEquationStatements;

protected function compareCrefList ""
  input list<list<DAE.ComponentRef>> inrefs;
  output list<DAE.ComponentRef> outrefs;
  output Boolean matching;
algorithm (outrefs,matching) := matchcontinue(inrefs)
  local
    list<DAE.ComponentRef> crefs,recRefs;
    Integer i;
    Boolean b1,b2,b3;
  case({}) then ({},true);
  case(crefs::{}) then (crefs,true);
  case(crefs::inrefs) // this case will allways have revRefs >=1 unless we are supposed to have 0
    equation
      (recRefs,b3) = compareCrefList(inrefs);
      i = listLength(recRefs);
      b1 = (0 == intMod(listLength(crefs),listLength(recRefs)));
      crefs = Util.listListUnionOnTrue({recRefs,crefs},ComponentReference.crefEqual);
      b2 = intEq(listLength(crefs),i);
      b1 = boolAnd(b1,boolAnd(b2,b3));
    then
      (crefs,b1);
  end matchcontinue;
end compareCrefList;

public function transformIfEqToExpr
"function: transformIfEqToExpr
  transform all if equations to ordinary equations involving if-expressions"
  input DAE.DAElist inDAElist;
  input Boolean onlyConstantEval "if true, only perform the constant evaluation part, not transforming to if-expr";
  output DAE.DAElist outDAElist;
algorithm
  outDAElist := match (inDAElist,onlyConstantEval)
    local
      list<DAE.Element> elts;
    case (DAE.DAE(elts),onlyConstantEval)
      equation
        elts = transformIfEqToExpr2(elts,onlyConstantEval);
      then DAE.DAE(elts);
  end match;
end transformIfEqToExpr;

protected function transformIfEqToExpr2
"function: transformIfEqToExpr
  transform all if equations to ordinary equations involving if-expressions"
  input list<DAE.Element> elts;
  input Boolean onlyConstantEval "if true, only perform the constant evaluation part, not transforming to if-expr";
  output list<DAE.Element> outElts;
algorithm
  outElts := match (elts,onlyConstantEval)
    local
      list<DAE.Element> rest_result,rest,sublist_result,sublist,elts,res,res2;
      DAE.Element subresult,el;
      String name;
      DAE.ElementSource source "the origin of the element";
    case ({},onlyConstantEval) then {};
    case (DAE.COMP(ident = name,dAElist = sublist,source=source) :: rest,onlyConstantEval)
      equation
        sublist_result = transformIfEqToExpr2(sublist,onlyConstantEval);
        rest_result = transformIfEqToExpr2(rest,onlyConstantEval);
        subresult = DAE.COMP(name,sublist_result,source,NONE());
      then subresult :: rest_result;
    case ((el as (DAE.IF_EQUATION(source = _)))::rest,onlyConstantEval)
      equation
        elts= ifEqToExpr(el,onlyConstantEval);
        res2 = transformIfEqToExpr2(rest,onlyConstantEval);
        res = listAppend(elts, res2);
      then
        res;
    case (el :: rest,onlyConstantEval)
      equation
        elts = transformIfEqToExpr2(rest,onlyConstantEval);
      then
        el :: elts;
  end match;
end transformIfEqToExpr2;

public function evaluateAnnotation
"function: evaluateAnnotation
  evaluates the annotation Evaluate"
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm
  (outDAElist) := matchcontinue (inDAElist)
    local
      DAE.DAElist dae;
      HashTable2.HashTable ht,pv;
      list<DAE.Element> elts,elts1;
    case (dae as DAE.DAE(elts))
      equation
        pv = getParameterVars(dae,HashTable2.emptyHashTable());
        (ht,true) = evaluateAnnotation1(dae,pv,HashTable2.emptyHashTable());
        (elts1,(_,_)) = traverseDAE2(elts, evaluateAnnotationVisitor, (ht,0));
      then
        DAE.DAE(elts1);
    case (dae) then dae;
  end matchcontinue;
end evaluateAnnotation;

protected function evaluateAnnotationVisitor "
Author: Frenkel TUD, 2010-12"
  input tuple<DAE.Exp,tuple<HashTable2.HashTable,Integer>> itpl;
  output tuple<DAE.Exp,tuple<HashTable2.HashTable,Integer>> otpl;
algorithm
  otpl := match itpl
    local
      DAE.Exp exp;
      tuple<HashTable2.HashTable,Integer> extra_arg;
    case ((exp,extra_arg)) then Expression.traverseExp(exp,evaluateAnnotationTraverse,extra_arg);
  end match;
end evaluateAnnotationVisitor;

protected function evaluateAnnotationTraverse "
Author: Frenkel TUD, 2010-12"
  input tuple<DAE.Exp, tuple<HashTable2.HashTable,Integer>> itpl;
  output tuple<DAE.Exp, tuple<HashTable2.HashTable,Integer>> otpl;
algorithm
  otpl := matchcontinue (itpl)
    local
      DAE.ComponentRef cr;
      HashTable2.HashTable ht;
      DAE.Exp exp,e1;
      Integer i;
    
    case((exp as DAE.CREF(componentRef=cr),(ht,i)))
      equation
        e1 = BaseHashTable.get(cr,ht);
      then 
        ((e1,(ht,i)));
    case((exp as DAE.CREF(componentRef=cr),(ht,i)))
      equation
        failure(_ = BaseHashTable.get(cr,ht));
      then 
        ((exp,(ht,i+1)));
    case(itpl) then itpl;
  end matchcontinue;
end evaluateAnnotationTraverse;

public function getParameterVars
"function: getParameterVars"
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  output HashTable2.HashTable ouHt;
algorithm
  (ouHt) := matchcontinue (inDAElist,inHt)
    local
      list<DAE.Element> rest,sublist;
      DAE.Element el;
      HashTable2.HashTable ht,ht1,ht2;
      DAE.ComponentRef cr;
      DAE.Exp e;
      Option<DAE.VariableAttributes> dae_var_attr;
    case (DAE.DAE({}),ht) then ht;
    case (DAE.DAE((DAE.COMP(dAElist = sublist) :: rest)),ht)
      equation
        ht1 = getParameterVars(DAE.DAE(sublist),ht);
        ht2 = getParameterVars(DAE.DAE(rest),ht1);
      then
        ht2;
    case (DAE.DAE(((DAE.VAR(componentRef = cr,kind=DAE.PARAM(),binding=SOME(e)))):: rest),ht)
      equation
        ht1 = BaseHashTable.add((cr,e),ht);
        ht2 = getParameterVars(DAE.DAE(rest),ht1);
      then
        ht2;
    case (DAE.DAE(((DAE.VAR(componentRef = cr,kind=DAE.PARAM(),variableAttributesOption=dae_var_attr))):: rest),ht)
      equation
        e = getStartAttrFail(dae_var_attr);
        ht1 = BaseHashTable.add((cr,e),ht);
        ht2 = getParameterVars(DAE.DAE(rest),ht1);
      then
        ht2;        
    case (DAE.DAE(el :: rest),ht)
      equation
        ht1 = getParameterVars(DAE.DAE(rest),ht);
      then
        ht1;
  end matchcontinue;
end getParameterVars;

public function evaluateAnnotation1
"function: evaluateAnnotation1
  evaluates the annotation Evaluate"
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inPV;
  input HashTable2.HashTable inHt;
  output HashTable2.HashTable ouHt;
  output Boolean hasEvaluate;
algorithm
  (ouHt,hasEvaluate) := matchcontinue (inDAElist,inPV,inHt)
    local
      list<DAE.Element> rest,sublist;
      DAE.Element el;
      SCode.Comment comment;
      HashTable2.HashTable ht,ht1,ht2,pv;
      DAE.ComponentRef cr;
      SCode.Annotation anno;
      list<SCode.Annotation> annos;
      DAE.Exp e,e1;
      Boolean b,b1;
    case (DAE.DAE({}),_,ht) then (ht,false);
    case (DAE.DAE((DAE.COMP(dAElist = sublist) :: rest)),pv,ht)
      equation
        (ht1,b) = evaluateAnnotation1(DAE.DAE(sublist),pv,ht);
        (ht2,b1) = evaluateAnnotation1(DAE.DAE(rest),pv,ht1);
      then
        (ht2,b or b1);
    case (DAE.DAE(((DAE.VAR(componentRef = cr,kind=DAE.PARAM(),binding=SOME(e),absynCommentOption=SOME(comment)))):: rest),pv,ht)
      equation
        SCode.COMMENT(annotation_=SOME(anno)) = comment;
        true = hasBooleanNamedAnnotation1({anno},"Evaluate");
        e1 = evaluateParameter(e,pv);
        ht1 = BaseHashTable.add((cr,e1),ht);
        (ht2,_) = evaluateAnnotation1(DAE.DAE(rest),pv,ht1);
      then
        (ht2,true);
    case (DAE.DAE(((DAE.VAR(componentRef = cr,kind=DAE.PARAM(),binding=SOME(e),absynCommentOption=SOME(comment)))):: rest),pv,ht)
      equation
        SCode.CLASS_COMMENT(annotations=annos) = comment;
        true = hasBooleanNamedAnnotation1(annos,"Evaluate");
        e1 = evaluateParameter(e,pv);
        ht1 = BaseHashTable.add((cr,e1),ht);
        (ht2,_) = evaluateAnnotation1(DAE.DAE(rest),pv,ht1);
      then
        (ht2,true);        
    case (DAE.DAE(el :: rest),pv,ht)
      equation
        (ht1,b) = evaluateAnnotation1(DAE.DAE(rest),pv,ht);
      then
        (ht1,b);
  end matchcontinue;
end evaluateAnnotation1;

public function evaluateParameter
"function: evaluateParameter"
  input DAE.Exp inExp;
  input HashTable2.HashTable inPV;
  output DAE.Exp outExp;
algorithm
  (outExp) := matchcontinue (inExp,inPV)
    local
      HashTable2.HashTable pv;
      DAE.Exp e,e1,e2;
      Integer i;
    case (e,_)
      equation
        true = Expression.isConst(e);
      then e;
    case (e,_)
      equation
        {} = Expression.extractCrefsFromExp(e);
      then e;        
    case (e,pv)
      equation
        ((e1,(_,i))) = Expression.traverseExp(e,evaluateAnnotationTraverse,(pv,0));
        true = intEq(i,0);
        e2 = evaluateParameter(e1,pv);
      then
        e2;
  end matchcontinue;
end evaluateParameter;

public function hasBooleanNamedAnnotation
  input SCode.Class inClass;
  input String namedAnnotation;
  output Boolean hasAnn;
algorithm
  hasAnn := matchcontinue(inClass,namedAnnotation)
    local
      list<SCode.Annotation> anns;

    case(SCode.CLASS(classDef = SCode.PARTS(annotationLst = anns)),namedAnnotation)
      then hasBooleanNamedAnnotation1(anns,namedAnnotation);

    case(SCode.CLASS(classDef = SCode.CLASS_EXTENDS(annotationLst = anns)),namedAnnotation)
      then hasBooleanNamedAnnotation1(anns,namedAnnotation);
    else false;
  end matchcontinue;
end hasBooleanNamedAnnotation;

protected function hasBooleanNamedAnnotation1
"check if the named annotation is present"
  input list<SCode.Annotation> inAnnos;
  input String annotationName;
  output Boolean outB;
algorithm
  outB := matchcontinue (inAnnos,annotationName)
    local
      Boolean b;
      list<SCode.Annotation> rest;
      SCode.Mod mod;
    case (SCode.ANNOTATION(modification = mod) :: rest,annotationName)
      equation
        true = hasBooleanNamedAnnotation2(mod,annotationName);
      then
        true;
    case (SCode.ANNOTATION(modification = mod) :: rest,annotationName)
      equation
        false = hasBooleanNamedAnnotation2(mod,annotationName);
        b = hasBooleanNamedAnnotation1(rest,annotationName);
      then
        b;
  end matchcontinue;
end hasBooleanNamedAnnotation1;

protected function hasBooleanNamedAnnotation2
"check if the named annotation is present"
  input SCode.Mod inMod;
  input String annotationName;
  output Boolean outB;
algorithm
  (outB) := match (inMod,annotationName)
    local
      Boolean b;
      list<SCode.SubMod> subModLst;    
    case (SCode.MOD(subModLst=subModLst),annotationName)
      equation
        b = hasBooleanNamedAnnotation3(subModLst,annotationName);
      then
        b;
  end match;
end hasBooleanNamedAnnotation2;

protected function hasBooleanNamedAnnotation3
"check if the named annotation is present in comment"
  input list<SCode.SubMod> inSubModes;
  input String namedAnnotation;
  output Boolean outB;
algorithm
  (outB) := matchcontinue (inSubModes,namedAnnotation)
    local
      Boolean b;
      list<SCode.SubMod> rest;
      SCode.SubMod submod;
      SCode.Mod mod;
      String id;
    case (SCode.NAMEMOD(ident = id,A=SCode.MOD(absynExpOption=SOME((Absyn.BOOL(value=true),_)))) :: rest,namedAnnotation)
      equation
        true = id ==& namedAnnotation;
      then true;
    case (SCode.IDXMOD(an=mod) :: rest,namedAnnotation)
      equation
        true = hasBooleanNamedAnnotation2(mod,namedAnnotation);
      then
        true;
    case (submod :: rest,namedAnnotation)
      equation
        b = hasBooleanNamedAnnotation3(rest,namedAnnotation);
      then
        b;
  end matchcontinue;
end hasBooleanNamedAnnotation3;

protected function selectBranches
"@author: adrpo
 this function will select the equations in the
 correct branch IF (and only if) the conditions
 are boolean literals. We need this here as
 Connections.isRoot is replaced by true/false
 at the end of instatiation"
 input list<DAE.Exp> cond;
 input list<list<DAE.Element>> true_branch;
 input list<DAE.Element> false_branch;
 input DAE.ElementSource source "the origin of the element";
 input Boolean recursiveCall "true if is a recursive call; we need this to avoid stack overflow!";
 input Boolean onlyConstantEval;
 output list<DAE.Element> equations;
algorithm
 equations := matchcontinue(cond, true_branch, false_branch, source, recursiveCall, onlyConstantEval)
   local
     list<DAE.Exp> rest;
     list<list<DAE.Element>> restTrue;
     list<DAE.Element> eqs;

   // nothing selects the else
   case ({}, {}, false_branch, _, _, onlyConstantEval)
   then false_branch;

   // if true select the head from the true_branch
   case (DAE.BCONST(true)::rest, eqs::restTrue, false_branch, _, recursiveCall, onlyConstantEval)
     equation
       // transform further if needed
       DAE.DAE(eqs) = transformIfEqToExpr(DAE.DAE(eqs),onlyConstantEval);
     then eqs;

   // if false recurse with rest on both lists
   case (DAE.BCONST(false)::rest, eqs::restTrue, false_branch, source, _, onlyConstantEval)
     equation
       eqs = selectBranches(rest, restTrue, false_branch, source, true, onlyConstantEval);
       // transform further if needed
       DAE.DAE(eqs) = transformIfEqToExpr(DAE.DAE(eqs),onlyConstantEval);
     then eqs;
   // if is not a boolean literal, and is a recursive call just return the if equation!
   case (cond, true_branch, false_branch, source, true, onlyConstantEval)
     equation
       eqs = ifEqToExpr(DAE.IF_EQUATION(cond, true_branch, false_branch, source), onlyConstantEval);
     then eqs;
   // failure?!
   case (_, _, _, source, false, onlyConstantEval)
     equation
       // Debug.fprintln("failtrace", "- DAEUtil.selectBranches failed: the IF equation is malformed!");
     then fail();
 end matchcontinue;
end selectBranches;

protected function ifEqToExpr
"function: ifEqToExpr
  Transform one if-equation into equations involving if-expressions"
  input DAE.Element inElement;
  input Boolean onlyConstantEval;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst := matchcontinue (inElement,onlyConstantEval)
    local
      String elt_str;
      DAE.Element elt;
      list<DAE.Exp> cond,fbsExp;
      list<list<DAE.Exp>> tbsExp;
      list<DAE.Element> false_branch,equations;
      list<list<DAE.Element>> true_branch;
      DAE.ElementSource source "the origin of the element";
      Absyn.Path fpath;

    // adrpo: handle selection of branches if conditions are boolean literals
    //        this is needed as Connections.isRoot becomes true/false at the
    //        end of instantiation.
    case ((elt as DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch, source = source)),onlyConstantEval)
      equation
        equations = selectBranches(cond, true_branch, false_branch,source,false,onlyConstantEval);
        // transform further if needed
      then transformIfEqToExpr2(equations,onlyConstantEval);
    // handle the erroneous case where the number of equations are not equal in different branches
    /* BUG: The comparison of # equations in different branches below is wrong.
    The Modelica.Blocks.Examples.PID_Controller shows why. if an assert is present in one of the branches, the number
    does not match, but the "counting of equations" is still the same
    Therfore I comment this out for now.
    /PA
    */

    /*case ((elt as DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch)),onlyConstantEval)
      equation
        true_eq = ifEqToExpr2(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = false; // Bug here, must count the equations properly...
        elt_str = DAEDump.dumpEquationsStr({elt});
        Error.addMessage(Error.DIFFERENT_NO_EQUATION_IF_BRANCHES, {elt_str});
      then
        {};*/

    // This case does not work correctly if a branch contains an if-equation, see bug 1229
    /*case (DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch,source=source),onlyConstantEval as false)
      equation
        true_eq = ifEqToExpr2(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = true;
        equations = makeEquationsFromIf(cond, true_branch, false_branch, source);
      then
        equations;*/
    
    // adrpo: if we are running checkModel and condition is initial(), ignore error!
    case (DAE.IF_EQUATION(condition1 = cond as {DAE.CALL(path = fpath)},equations2 = true_branch,equations3 = false_branch,source=source),onlyConstantEval as false)
      equation
        true = OptManager.getOption("checkModel");
        true = Util.isEqual(fpath, Absyn.IDENT("initial"));
        // leave the if equation as it is!
      then {inElement};

    // handle the default case.
    case (DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch,source=source),onlyConstantEval as false)
      equation
        _ = countEquationsInBranches(true_branch, false_branch, source);
        fbsExp = makeEquationLstToResidualExpLst(false_branch);
        tbsExp = Util.listMap(true_branch, makeEquationLstToResidualExpLst);
        equations = makeEquationsFromResiduals(cond, tbsExp, fbsExp, source);
      then
        equations;
    case (elt as DAE.IF_EQUATION(condition1=_),onlyConstantEval as true)
      then
        {elt};
    case (elt as DAE.IF_EQUATION(source=source),onlyConstantEval) // only display failure on if equation
      equation
        // TODO: Do errors in the other functions...
        true = RTOpts.debugFlag("failtrace");
        elt_str = DAEDump.dumpElementsStr({elt});
        Debug.fprintln("failtrace", "- DAEUtil.ifEqToExpr failed " +& elt_str);
      then fail();
  end matchcontinue;
end ifEqToExpr;

protected function countEquations
  input list<DAE.Element> equations;
  output Integer nrOfEquations;
algorithm
  nrOfEquations := matchcontinue(equations)
    local
      list<list<DAE.Element>> tb;
      list<DAE.Element> rest,fb;
      DAE.ElementSource source;
      DAE.Element elt;
      Integer nr,n;
    // empty case
    case ({}) then 0;
    // ignore assert!
    case (DAE.ASSERT(condition = _)::rest)
      then countEquations(rest);
    // ignore terminate!
    case (DAE.TERMINATE(message=_)::rest)
      then countEquations(rest);
    // For an if-equation, count equations in branches    
    case (DAE.IF_EQUATION(equations2=tb,equations3=fb,source=source)::rest)
      equation
        n = countEquationsInBranches(tb,fb,source);
        nr = countEquations(rest);
      then nr + n;  
    case (DAE.INITIAL_IF_EQUATION(equations2=tb,equations3=fb,source=source)::rest)
      equation
        n = countEquationsInBranches(tb,fb,source);
        nr = countEquations(rest);
      then nr + n;  
    // any other case, just add 1
    case (elt::rest)
      equation
        failure(isIfEquation(elt));
        nr = countEquations(rest);
      then nr + 1;
  end matchcontinue;
end countEquations;

protected function countEquationsInBranches "
Checks that the number of equations is the same in all branches
of an if-equation"
  input list<list<DAE.Element>> trueBranches;
  input list<DAE.Element> falseBranch;
  input DAE.ElementSource source;
  output Integer nrOfEquations;
algorithm
  nrOfEquations := matchcontinue(trueBranches,falseBranch,source)
    local
      list<Boolean> b;
      list<String> strs;
      String str;
      list<Integer> nrOfEquationsBranches;
    case (trueBranches,falseBranch,source)
      equation
        nrOfEquations = countEquations(falseBranch);
        nrOfEquationsBranches = Util.listMap(trueBranches, countEquations);
        b = Util.listMap1(nrOfEquationsBranches, intEq, nrOfEquations);
        true = Util.listReduce(b,boolAnd);
      then (nrOfEquations);
    case (trueBranches,falseBranch,source)
      equation
        nrOfEquations = countEquations(falseBranch);
        nrOfEquationsBranches = Util.listMap(trueBranches, countEquations);
        strs = Util.listMap(nrOfEquationsBranches, intString);
        str = Util.stringDelimitList(strs,",");
        str = "{" +& str +& "," +& intString(nrOfEquations) +& "}";
        Error.addSourceMessage(Error.IF_EQUATION_UNBALANCED_2,{str},getElementSourceFileInfo(source));
      then fail();
  end matchcontinue;
end countEquationsInBranches;

protected function makeEquationsFromIf
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Element>> inElementLst2;
  input list<DAE.Element> inElementLst3;
  input DAE.ElementSource source "the origin of the element";
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst := matchcontinue (inExp1,inElementLst2,inElementLst3,source)
    local
      list<list<DAE.Element>> tbs,rest1,tbsRest,tbsFirstL;
      list<DAE.Element> tbsFirst,fbs,rest_res,tb;
      DAE.Element fb,eq;
      list<DAE.Exp> conds,tbsexp;
      DAE.Exp fbexp,ifexp, cond;
      DAE.ElementSource source "the origin of the element";

    case (_,tbs,{},_)
      equation
        Util.listMap0(tbs, Util.assertListEmpty);
      then {};

    // adrpo: not all equations can be transformed using makeEquationToResidualExp
    //        for example, assert, terminate, etc. TODO! FIXME!
    //        if cond then assert(cnd, ...); endif; can be translated to:
    //        assert(cond AND cnd, ...

    case (conds,tbs,fb::fbs,source)
      equation
        tbsRest = Util.listMap(tbs,Util.listRest);
        rest_res = makeEquationsFromIf(conds, tbsRest, fbs, source);

        tbsFirst = Util.listMap(tbs,Util.listFirst);
        tbsexp = Util.listMap(tbsFirst,makeEquationToResidualExp);
        fbexp = makeEquationToResidualExp(fb);

        ifexp = Expression.makeNestedIf(conds,tbsexp,fbexp);
        eq = DAE.EQUATION(DAE.RCONST(0.0),ifexp,source);
      then
        (eq :: rest_res);
  end matchcontinue;
end makeEquationsFromIf;

protected function makeEquationToResidualExpLst "
If-equations with more than 1 equation in each branch cannot be transformed
to a single equation with residual if-expression. This function translates such
equations to a list of residual if-expressions. Normal equations are translated 
to a list with a single residual expression."
  input DAE.Element eq;
  output list<DAE.Exp> oExpLst;
algorithm
  oExpLst := matchcontinue(eq)
    local
      list<list<DAE.Element>> tbs;
      list<DAE.Element> fbs;
      list<DAE.Exp> conds, fbsExp,exps;
      list<list<DAE.Exp>> tbsExp;
      DAE.Element elt;
      DAE.Exp exp;

    case (DAE.IF_EQUATION(condition1=conds,equations2=tbs,equations3=fbs))
      equation
        fbsExp = makeEquationLstToResidualExpLst(fbs);
        tbsExp = Util.listMap(tbs, makeEquationLstToResidualExpLst);
        exps = makeResidualIfExpLst(conds,tbsExp,fbsExp);
      then
        exps;  
    case (DAE.INITIAL_IF_EQUATION(condition1=conds,equations2=tbs,equations3=fbs))
      equation
        fbsExp = makeEquationLstToResidualExpLst(fbs);
        tbsExp = Util.listMap(tbs, makeEquationLstToResidualExpLst);
        exps = makeResidualIfExpLst(conds,tbsExp,fbsExp);
      then
        exps;  
    case (elt)
      equation
        exp=makeEquationToResidualExp(elt);
      then
        {exp};
  end matchcontinue;
end makeEquationToResidualExpLst;             

protected function makeEquationToResidualExp ""
  input DAE.Element eq;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(eq)
    local
      DAE.Exp e1,e2;
      DAE.ComponentRef cr1,cr2;
      DAE.ExpType ty,ty1,ty2;
    // normal equation
    case(DAE.EQUATION(e1,e2,_))
      equation
        ty = Expression.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // initial equation
    case(DAE.INITIALEQUATION(e1,e2,_))
      equation
        ty = Expression.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // complex equation
    case(DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2))
      equation
        ty = Expression.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // complex initial equation
    case(DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2))
      equation
        ty = Expression.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // equation from connect
    case(DAE.EQUEQUATION(cr1, cr2, _))
      equation
        ty1 = ComponentReference.crefLastType(cr1);
        ty2 = ComponentReference.crefLastType(cr2);
        e1 = Expression.makeCrefExp(cr1,ty1);
        e2 = Expression.makeCrefExp(cr2,ty2);
        oExp = DAE.BINARY(e1, DAE.SUB(ty1), e2);
      then
        oExp;
    // equation from define
    case(DAE.DEFINE(cr1, e2, _))
      equation
        ty1 = ComponentReference.crefLastType(cr1);
        e1 = Expression.makeCrefExp(cr1,ty1);
        oExp = DAE.BINARY(e1, DAE.SUB(ty1), e2);
      then
        oExp;
    // equation from initial define
    case(DAE.INITIALDEFINE(cr1, e2, _))
      equation
        ty1 = ComponentReference.crefLastType(cr1);
        e1 = Expression.makeCrefExp(cr1,ty1);
        oExp = DAE.BINARY(e1, DAE.SUB(ty1), e2);
      then
        oExp;
    // equation from array TODO! check if this works!
    case(DAE.ARRAY_EQUATION(_, e1, e2, _))
      equation
        ty = Expression.typeof(e1);
        oExp = DAE.BINARY(e1, DAE.SUB_ARR(ty), e2);
      then
        oExp;
    // initial array equation
    case(DAE.INITIAL_ARRAY_EQUATION(_, e1, e2, _))
      equation
        ty = Expression.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB_ARR(ty),e2);
      then
        oExp;
    // failure
    case(eq)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- DAEUtil.makeEquationToResidualExp failed to transform equation: " +&
          DAEDump.dumpEquationStr(eq) +& " to residual form!");
      then fail();
  end matchcontinue;
end makeEquationToResidualExp;

protected function makeEquationLstToResidualExpLst 
  input list<DAE.Element> eqLst;
  output list<DAE.Exp> oExpLst;
algorithm
  oExpLst := matchcontinue(eqLst)
    local
      list<DAE.Element> rest;
      list<DAE.Exp> exps1,exps2,exps;
      DAE.Element eq;
      DAE.ElementSource source;
      String str;
    case ({}) then {};
    case (eq::rest)
      equation
        exps1 = makeEquationToResidualExpLst(eq);
        exps2 = makeEquationLstToResidualExpLst(rest); 
        exps = listAppend(exps1,exps2);
      then 
        exps;
    case ((eq as DAE.ASSERT(source = source))::rest)
      equation
        str = DAEDump.dumpEquationStr(eq);
        str = Util.stringReplaceChar(str,"\n","");
        Error.addSourceMessage(Error.IF_EQUATION_WARNING,{str},getElementSourceFileInfo(source));
        exps = makeEquationLstToResidualExpLst(rest);
      then exps;
    case ((eq as DAE.TERMINATE(source = source))::rest)
      equation
        str = DAEDump.dumpEquationStr(eq);
        str = Util.stringReplaceChar(str,"\n","");
        Error.addSourceMessage(Error.IF_EQUATION_WARNING,{str},getElementSourceFileInfo(source));
        exps = makeEquationLstToResidualExpLst(rest);
      then exps;
  end matchcontinue;
end makeEquationLstToResidualExpLst;         

protected function makeResidualIfExpLst
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Exp>> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match (inExp1,inExpLst2,inExpLst3)
    local
      list<list<DAE.Exp>> tbs,tbsRest;
      list<DAE.Exp> tbsFirst,fbs,rest_res;
      list<DAE.Exp> conds;
      DAE.Exp ifexp,fb;

    case (_,tbs,{})
      equation
        Util.listMap0(tbs, Util.assertListEmpty);
      then {};

    case (conds,tbs,fb::fbs)
      equation
        tbsRest = Util.listMap(tbs,Util.listRest);
        rest_res = makeResidualIfExpLst(conds, tbsRest, fbs);

        tbsFirst = Util.listMap(tbs,Util.listFirst);

        ifexp = Expression.makeNestedIf(conds,tbsFirst,fb);
      then
        (ifexp :: rest_res);
  end match;
end makeResidualIfExpLst;

protected function makeEquationsFromResiduals
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Exp>> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  input DAE.ElementSource source "the origin of the element";
  output list<DAE.Element> outExpLst;
algorithm
  outExpLst := match (inExp1,inExpLst2,inExpLst3,source)
    local
      list<list<DAE.Exp>> tbs,tbsRest;
      list<DAE.Exp> tbsFirst,fbs;
      list<DAE.Exp> conds;
      DAE.Exp ifexp,fb;
      DAE.Element eq;
      list<DAE.Element> rest_res;
      DAE.ElementSource src;

    case (_,tbs,{},_)
      equation
        Util.listMap0(tbs, Util.assertListEmpty);
      then {};

    case (conds,tbs,fb::fbs,src)
      equation
        tbsRest = Util.listMap(tbs,Util.listRest);
        rest_res = makeEquationsFromResiduals(conds, tbsRest,fbs,src);

        tbsFirst = Util.listMap(tbs,Util.listFirst);

        ifexp = Expression.makeNestedIf(conds,tbsFirst,fb);
        eq = DAE.EQUATION(DAE.RCONST(0.0),ifexp,src);
      then
        (eq :: rest_res);
  end match;
end makeEquationsFromResiduals;

public function renameTimeToDollarTime "
Author: BZ, 2009-1
rename the keyword time to globalData->timeValue, this is a special case for functions since they do not get translated in to c_crefs."
  input list<DAE.Element> dae;
  output list<DAE.Element> odae;
algorithm
  (odae,_) := traverseDAE2(dae, renameTimeToDollarTimeVisitor, 0);
end renameTimeToDollarTime;

protected function renameTimeToDollarTimeVisitor "
Author: BZ, 2009-01
The visitor function for traverseDAE.calls Expression.traverseExp on the expression."
  input tuple<DAE.Exp,Integer> itpl;
  output tuple<DAE.Exp,Integer> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp exp,oexp;
      Integer arg,oarg;
    case ((exp,oarg)) then Expression.traverseExp(exp,renameTimeToDollarTimeFromCref,oarg);
  end matchcontinue;
end renameTimeToDollarTimeVisitor;

protected function renameTimeToDollarTimeFromCref "
Author: BZ, 2008-12
Function for Expression.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local
      DAE.ComponentRef cr,cr2,cref_;
      DAE.ExpType cty,ty;
      Integer oarg;
      list<DAE.Subscript> subs;
      DAE.Exp exp;
    
    case((DAE.CREF(DAE.CREF_IDENT("time",cty,subs),ty),oarg))
      equation
        cref_ = ComponentReference.makeCrefIdent("globalData->timeValue",cty,subs);
        exp = Expression.makeCrefExp(cref_,ty); 
      then 
        ((exp,oarg));
    
    case(inTplExpExpString) then inTplExpExpString;

  end matchcontinue;
end renameTimeToDollarTimeFromCref;


public function renameUniqueOuterVars "
Author: BZ, 2008-12
Rename innerouter(the inner part of innerouter) variables that have been renamed to a.b.$unique$var
Just remove the $unique$ from the var name.
This function traverses the entire dae."
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm
  (odae,_,_) := traverseDAE(dae, emptyFuncTree, renameUniqueVisitor, 0);
end renameUniqueOuterVars;

protected function renameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE.
calls Expression.traverseExp on the expression."
  input tuple<DAE.Exp,Integer> itpl;
  output tuple<DAE.Exp,Integer> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp exp,oexp;
      Integer arg,oarg;
    case ((exp,oarg)) then Expression.traverseExp(exp,removeUniqieIdentifierFromCref,oarg);
  end matchcontinue;
end renameUniqueVisitor;

protected function removeUniqieIdentifierFromCref "
Author: BZ, 2008-12
Function for Expression.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm 
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local 
      DAE.ComponentRef cr,cr2; DAE.ExpType ty; Integer oarg; DAE.Exp exp;
      
    case((DAE.CREF(cr,ty),oarg))
      equation
        cr2 = unNameInnerouterUniqueCref(cr,DAE.UNIQUEIO);
        exp = Expression.makeCrefExp(cr2,ty);
      then 
        ((exp,oarg));
    
    case(inTplExpExpString) then inTplExpExpString;
    
  end matchcontinue;
end removeUniqieIdentifierFromCref;

public function nameUniqueOuterVars "
Author: BZ, 2008-12
Rename all variables to the form a.b.$unique$var, call
This function traverses the entire dae."
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm
  (odae,_,_) := traverseDAE(dae, emptyFuncTree, nameUniqueVisitor, 0);
end nameUniqueOuterVars;

protected function nameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE.
calls Expression.traverseExp on the expression."
  input tuple<DAE.Exp,Integer> itpl;
  output tuple<DAE.Exp,Integer> otpl;
algorithm
  otpl := match itpl
    local
      DAE.Exp exp;
      Integer oarg;
    
    case ((exp,oarg)) then Expression.traverseExp(exp,addUniqueIdentifierToCref,oarg);
    
  end match;
end nameUniqueVisitor;

protected function addUniqueIdentifierToCref "
Author: BZ, 2008-12
Function for Expression.traverseExp, adds the constant 'UNIQUEIO' to the CREF_IDENT() part of the cref."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm 
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local 
      DAE.ComponentRef cr,cr2; DAE.ExpType ty; Integer oarg; DAE.Exp exp;
    
    case((DAE.CREF(cr,ty),oarg))
      equation
        cr2 = nameInnerouterUniqueCref(cr);
        exp = Expression.makeCrefExp(cr2,ty);
      then 
        ((exp,oarg));
    
    case(inTplExpExpString) then inTplExpExpString;
    
  end matchcontinue;
end addUniqueIdentifierToCref;

// helper functions for traverseDAE
protected function traverseDAEOptExp "
Author: BZ, 2008-12
Traverse an optional expression, helper function for traverseDAE"
  input Option<DAE.Exp> oexp;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<DAE.Exp> ooexp;
  output Type_a oextraArg;
  partial function FuncExpType 
    input tuple<DAE.Exp,Type_a> arg; 
    output tuple<DAE.Exp,Type_a> oarg; 
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (ooexp,oextraArg) := match(oexp,func,extraArg)
    local 
      DAE.Exp e;
    
    case(NONE(),func,extraArg) then (NONE(),extraArg);
    
    case(SOME(e),func,extraArg)
      equation
        ((e,extraArg)) = func((e,extraArg));
      then
        (SOME(e),extraArg);
  end match;
end traverseDAEOptExp;

protected function traverseDAEExpList "
Author: BZ, 2008-12
Traverse an list of expressions, helper function for traverseDAE"
  input list<DAE.Exp> exps;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Exp> oexps;
  output Type_a oextraArg;
  partial function FuncExpType 
    input tuple<DAE.Exp,Type_a> arg; 
    output tuple<DAE.Exp,Type_a> oarg; 
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (oexps,oextraArg) := match(exps,func,extraArg)
    local 
      DAE.Exp e;
    
    case({},func,extraArg) then ({},extraArg);
    
    case(e::exps,func,extraArg)
      equation
        ((e,extraArg)) = func((e,extraArg));
        (oexps,extraArg) = traverseDAEExpList(exps,func,extraArg);
      then
        (e::oexps,extraArg);
  end match;
end traverseDAEExpList;

protected function traverseDAEList "
Author: BZ, 2008-12
Helper function for traverseDAE, traverses a list of dae element list."
  input list<list<DAE.Element>> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<list<DAE.Element>> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType 
    input tuple<DAE.Exp,Type_a> arg; 
    output tuple<DAE.Exp,Type_a> oarg; 
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm 
  (traversedDaeList,oextraArg) := match(daeList,func,extraArg)
    local
      list<DAE.Element> branch,branch2;
      list<list<DAE.Element>> recRes;
    
    case({},func,extraArg) then ({},extraArg);
    
    case(branch::daeList,func,extraArg)
      equation
        (branch2,extraArg) = traverseDAE2(branch,func,extraArg);
        (recRes,extraArg) = traverseDAEList(daeList,func,extraArg);
      then
        (branch2::recRes,extraArg);
  end match;
end traverseDAEList;

public function getFunctionList
  input DAE.FunctionTree ft;
  output list<DAE.Function> fns;
algorithm
  fns := matchcontinue ft
    local
      list<tuple<DAE.AvlKey,DAE.AvlValue>> lst;
      Absyn.Path path;
      String str;
    case ft
      equation
        lst = avlTreeToList(ft);
      then Util.listMapMap(lst, Util.tuple22, Util.getOption);
    case ft
      equation
        lst = avlTreeToList(ft);
        ((path,_)) = Util.listSelectFirst(lst, isInvalidFunctionEntry);
        str = Absyn.pathString(path);
        Error.addMessage(Error.NON_INSTANTIATED_FUNCTION, {str});
      then fail();
  end matchcontinue;
end getFunctionList;

protected function isInvalidFunctionEntry
  input tuple<DAE.AvlKey,DAE.AvlValue> tpl;
  output Boolean b;
algorithm
  b := matchcontinue tpl
    case ((_,NONE())) then true;
    case ((_,_)) then false;
  end matchcontinue;
end isInvalidFunctionEntry;

public function traverseDAE " This function traverses all dae exps.
NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
  input FuncExpType func;
  input Type_a extraArg;
  output DAE.DAElist traversedDae;
  output DAE.FunctionTree outTree;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDae,outTree,oextraArg) := match(dae,functionTree,func,extraArg)
  local
    list<DAE.Element> elts;
     list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
     DAE.FunctionTree funcs;

  case(DAE.DAE(elts),funcs,func,extraArg) equation
     (elts,extraArg) = traverseDAE2(elts,func,extraArg);
     (funcLst,extraArg) = traverseDAEFuncLst(avlTreeToList(funcs),func,extraArg);
     funcs = avlTreeAddLst(funcLst,avlTreeNew());
  then (DAE.DAE(elts),funcs,extraArg);
  end match;
end traverseDAE;

protected function traverseDAEFuncLst "help function to traverseDae. Traverses the functions "
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
  input FuncExpType func;
  input Type_a extraArg;
  output list<tuple<DAE.AvlKey,DAE.AvlValue>> outFuncLst;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;

algorithm
  (outFuncLst,oextraArg) := match(funcLst,func,extraArg)
    local
      Absyn.Path p;
      DAE.Function daeFunc;

    case({},func,extraArg) then ({},extraArg);
    case((p,SOME(daeFunc))::funcLst,func,extraArg)
      equation
        (daeFunc,extraArg) = traverseDAEFunc(daeFunc,func,extraArg);
        (funcLst,extraArg) = traverseDAEFuncLst(funcLst,func,extraArg);
      then ((p,SOME(daeFunc))::funcLst,extraArg);
    case((p,NONE())::_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAEUtil.traverseDAEFuncLst failed: " +& Absyn.pathString(p));
      then fail();
  end match;
end traverseDAEFuncLst;

public function traverseDAEFunctions "Traverses the functions.
Note: Only calls the top-most expressions If you need to also traverse the
expression, use an extra helper function."
  input list<DAE.Function> funcLst;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Function> outFuncLst;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outFuncLst,oextraArg) := match(funcLst,func,extraArg)
    local
      DAE.Function daeFunc;
    case({},func,extraArg) then ({},extraArg);
    case(daeFunc::funcLst,func,extraArg)
      equation
        (daeFunc,extraArg) = traverseDAEFunc(daeFunc,func,extraArg);
        (funcLst,extraArg) = traverseDAEFunctions(funcLst,func,extraArg);
      then (daeFunc::funcLst,extraArg);
  end match;
end traverseDAEFunctions;

protected function traverseDAEFunc
  input DAE.Function daeFn;
  input FuncExpType func;
  input Type_a extraArg;
  output DAE.Function traversedFn;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedFn,oextraArg) := match (daeFn,func,extraArg)
    local
      list<DAE.Element> elist,elist2;
      DAE.Type ftp,tp;
      Boolean partialPrefix;
      Absyn.Path path;
      DAE.ExternalDecl extDecl;
      list<DAE.FunctionDefinition> derFuncs;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the origin of the element";
    
    case(DAE.FUNCTION(path,(DAE.FUNCTION_DEF(body = elist)::derFuncs),ftp,partialPrefix,inlineType,source),func,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      then (DAE.FUNCTION(path,DAE.FUNCTION_DEF(elist2)::derFuncs,ftp,partialPrefix,inlineType,source),extraArg);
    
    case(DAE.FUNCTION(path,(DAE.FUNCTION_EXT(body = elist,externalDecl=extDecl)::derFuncs),ftp,partialPrefix,inlineType,source),func,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      then (DAE.FUNCTION(path,DAE.FUNCTION_EXT(elist2,extDecl)::derFuncs,ftp,partialPrefix,DAE.NO_INLINE(),source),extraArg);
    
    case(DAE.RECORD_CONSTRUCTOR(path,tp,source),func,extraArg)
      then (DAE.RECORD_CONSTRUCTOR(path,tp,source),extraArg);
  end match;
end traverseDAEFunc;


public function traverseDAE2 
"@author: BZ, 2008-12, adrpo, 2010-12
  This function traverses all dae exps.
  NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input list<DAE.Element> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Element> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := traverseDAE2_tail(daeList,func,extraArg,{});
end traverseDAE2;

protected function traverseDAE2_tail 
"@uthor: adrpo, 2010-12
  This function is a tail recursive function that traverses all dae exps.
  NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input list<DAE.Element> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  input list<DAE.Element> accumulator;
  output list<DAE.Element> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := match (daeList,func,extraArg,accumulator)
    local
      list<DAE.Element> dae,dae2;
      DAE.Element elt;
  
    case({},_,extraArg,accumulator)
      equation
        accumulator = listReverse(accumulator);
      then 
        (accumulator,extraArg);
  
    case(elt::dae,func,extraArg,accumulator)
      equation
        (elt,extraArg) = traverseDAE2_tail2(elt,func,extraArg);
        (dae2,extraArg) = traverseDAE2_tail(dae,func,extraArg,elt::accumulator);
      then 
        (dae2,extraArg);
  end match;
end traverseDAE2_tail;

protected function traverseDAE2_tail2
"@uthor: adrpo, 2010-12
  This function is a tail recursive function that traverses all dae exps.
  NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input DAE.Element elt;
  input FuncExpType func;
  input Type_a extraArg;
  output DAE.Element outElt;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outElt,oextraArg) := match (elt,func,extraArg)
    local
      DAE.ComponentRef cr,cr2,cr1,cr1_2;
      list<DAE.Element> elist,elist2,elist22;
      DAE.Element elt2;
      DAE.Function f1,f2;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.InstDims dims;
      DAE.Flow fl;
      DAE.Stream st;
      DAE.VarProtection prot;
      DAE.Exp e,e2,e22,e1,e11,maybeCrExp;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      Option<DAE.Exp> optExp;
      Absyn.InnerOuter io;
      list<DAE.Dimension> idims;
      String id,str;
      list<DAE.Statement> stmts,stmts2;
      list<list<DAE.Element>> tbs,tbs_1;
      list<DAE.Exp> conds,conds_1;
      Absyn.Path path;
      list<DAE.Exp> expl;
      DAE.ElementSource source "the origin of the element";
  
    case(DAE.VAR(cr,kind,dir,prot,tp,optExp,dims,fl,st,source,attr,cmt,io),func,extraArg)
      equation
        ((maybeCrExp,extraArg)) = func((Expression.crefExp(cr), extraArg));
        // If the result is DAE.CREF, we replace the name of the variable.
        // Otherwise, we only use the extraArg
        cr2 = Util.makeValueOrDefault(Expression.expCref,maybeCrExp,cr);
        (optExp,extraArg) = traverseDAEOptExp(optExp,func,extraArg);
        (attr,extraArg) = traverseDAEVarAttr(attr,func,extraArg);
        elt = DAE.VAR(cr2,kind,dir,prot,tp,optExp,dims,fl,st,source,attr,cmt,io);
      then 
        (elt,extraArg);
 
    case(DAE.DEFINE(cr,e,source),func,extraArg)
      equation
        ((e2,extraArg)) = func((e, extraArg));
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr), extraArg));
        elt = DAE.DEFINE(cr2,e2,source);
      then 
        (elt,extraArg);
  
    case(DAE.INITIALDEFINE(cr,e,source),func,extraArg)
      equation
        ((e2,extraArg)) = func((e, extraArg));
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr), extraArg));
        elt = DAE.INITIALDEFINE(cr2,e2,source);
      then 
        (elt,extraArg);
        
    case(DAE.EQUEQUATION(cr,cr1,source),func,extraArg)
      equation
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr), extraArg));
        ((DAE.CREF(cr1_2,_),extraArg)) = func((Expression.crefExp(cr1), extraArg));
        elt = DAE.EQUEQUATION(cr2,cr1_2,source);
      then 
        (elt,extraArg);
        
    case(DAE.EQUATION(e1,e2,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.EQUATION(e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.COMPLEX_EQUATION(e1,e2,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.COMPLEX_EQUATION(e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.ARRAY_EQUATION(idims,e1,e2,source),func,extraArg)
      equation
        ((e11, extraArg)) = func((e1, extraArg));
        ((e22, extraArg)) = func((e2, extraArg));
        elt = DAE.ARRAY_EQUATION(idims,e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.INITIAL_ARRAY_EQUATION(idims,e1,e2,source),func,extraArg)
      equation
        ((e11, extraArg)) = func((e1, extraArg));
        ((e22, extraArg)) = func((e2, extraArg));
        elt = DAE.INITIAL_ARRAY_EQUATION(idims,e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.WHEN_EQUATION(e1,elist,SOME(elt),source),func,extraArg)
      equation
        ((e11, extraArg)) = func((e1, extraArg));
        ({elt2}, extraArg)= traverseDAE2_tail({elt},func,extraArg,{});
        (elist2, extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.WHEN_EQUATION(e11,elist2,SOME(elt2),source);
      then 
        (elt,extraArg);
        
    case(DAE.WHEN_EQUATION(e1,elist,NONE(),source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.WHEN_EQUATION(e11,elist2,NONE(),source);
      then 
        (elt,extraArg);
        
    case(DAE.INITIALEQUATION(e1,e2,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.INITIALEQUATION(e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.INITIAL_COMPLEX_EQUATION(e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.COMP(id,elist,source,cmt),func,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.COMP(id,elist2,source,cmt);
      then 
        (elt,extraArg);
        
    case(DAE.EXTOBJECTCLASS(path,f1,f2,source),func,extraArg)
      equation
        (f1,extraArg) =  traverseDAEFunc(f1,func,extraArg);
        (f2,extraArg) =  traverseDAEFunc(f2,func,extraArg);
        elt = DAE.EXTOBJECTCLASS(path,f1,f2,source);
      then 
        (elt,extraArg);
        
    case(DAE.ASSERT(e1,e2,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1,extraArg));
        ((e22,extraArg)) = func((e2,extraArg));
        elt = DAE.ASSERT(e11,e22,source);
      then 
        (elt,extraArg);
        
    case(DAE.TERMINATE(e1,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1,extraArg));
        elt = DAE.TERMINATE(e11,source);
      then 
        (elt,extraArg);
        
    case(DAE.NORETCALL(path,expl,source),func,extraArg)
      equation
        (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
        elt = DAE.NORETCALL(path,expl,source);
      then 
        (elt,extraArg);
        
    case(DAE.REINIT(cr,e1,source),func,extraArg)
      equation
        ((e11,extraArg)) = func((e1,extraArg));
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr),extraArg));
        elt = DAE.REINIT(cr2,e11,source);
      then 
        (elt,extraArg);
        
    case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source),func,extraArg)
      equation
        (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        elt = DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source);
      then 
        (elt,extraArg);
        
    case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts),source),func,extraArg)
      equation
        (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        elt = DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source);
      then 
        (elt,extraArg);
        
    case(DAE.IF_EQUATION(conds,tbs,elist2,source),func,extraArg)
      equation
        (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
        (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
        (elist22,extraArg) = traverseDAE2_tail(elist2,func,extraArg,{});
        elt = DAE.IF_EQUATION(conds_1,tbs_1,elist22,source);
      then 
        (elt,extraArg);
        
    case(DAE.INITIAL_IF_EQUATION(conds,tbs,elist2,source),func,extraArg)
      equation
        (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
        (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
        (elist22,extraArg) = traverseDAE2_tail(elist2,func,extraArg,{});
        elt = DAE.INITIAL_IF_EQUATION(conds_1,tbs_1,elist22,source);
      then 
        (elt,extraArg);
    
    // Empty function call - stefan
    case(DAE.NORETCALL(_, _, _),func,extraArg)
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"Empty function call in equations", "Move the function calls to appropriate algorithm section"});
      then 
        fail();
        
    case(elt,_,_)
      equation
        str = DAEDump.dumpElementsStr({elt});
        str = "DAEUtil.traverseDAE not implemented correctly for element:" +& str; 
        Error.addMessage(Error.INTERNAL_ERROR, {str});
        print(str);
      then 
        fail();
  end match;
end traverseDAE2_tail2;

public function traverseDAEEquationsStmts "function: traverseDAEEquationsStmts
  Author: BZ, 2008-12
  Helper function to traverseDAE,
  Handles the traversing of DAE.Statement."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := matchcontinue(inStmts,func,extraArg)
    local
      DAE.Exp e_1,e_2,e,e2;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts2;
      DAE.ExpType tp;
      DAE.Statement x,ew,ew_1;
      Boolean b1;
      String id1,str;
      list<Integer> li;
      DAE.ElementSource source;
      Algorithm.Else algElse;
      
    case ({},_,extraArg) then ({},extraArg);
      
    case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e, source = source) :: xs),func,extraArg)
      equation
        ((e_1,extraArg)) = func((e, extraArg));
        ((e_2,extraArg)) = func((e2, extraArg));
        (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_ASSIGN(tp,e_2,e_1,source) :: xs_1,extraArg);
        
    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        (expl2, extraArg) = traverseDAEExpList(expl1,func,extraArg);
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then ((DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source) :: xs_1),extraArg);
        
    case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((e_2 as DAE.CREF(cr_1,_), extraArg)) = func((Expression.crefExp(cr), extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source)) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        failure(((DAE.CREF(_,_), _)) = func((Expression.crefExp(cr), extraArg)));
        true = RTOpts.debugFlag("failtrace");
        print(DAEDump.ppStatementStr(x));
        print("Warning, not allowed to set the componentRef to a expression in DAEUtil.traverseDAEEquationsStmts\n");      
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_ASSIGN_ARR(tp,cr,e_1,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source)) :: xs),func,extraArg)
      equation
        (algElse,extraArg) = traverseDAEEquationsStmtsElse(algElse,func,extraArg);
        (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        ((e_1,extraArg)) = func((e, extraArg));
        (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_IF(e_1,stmts2,algElse,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,range=e,statementLst=stmts, source = source)) :: xs),func,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_FOR(tp,b1,id1,e_1,stmts2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source)) :: xs),func,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_WHILE(e_1,stmts2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=NONE(),helpVarIndices=li, source = source)) :: xs),func,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_WHEN(e_1,stmts2,NONE(),li,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=SOME(ew),helpVarIndices=li, source = source)) :: xs),func,extraArg)
      equation
        ({ew_1}, extraArg) = traverseDAEEquationsStmts({ew},func,extraArg);
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_WHEN(e_1,stmts2,SOME(ew),li,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_ASSERT(cond = e, msg=e2, source = source)) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((e_2, extraArg)) = func((e2, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_ASSERT(e_1,e_2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_TERMINATE(msg = e, source = source)) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_TERMINATE(e_1,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_REINIT(var = e,value=e2, source = source)) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((e_2, extraArg)) = func((e2, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_REINIT(e_1,e_2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_NORETCALL(exp = e, source = source)) :: xs),func,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_NORETCALL(e_1,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_RETURN(source = source)) :: xs),func,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (x :: xs_1,extraArg);
        
    case (((x as DAE.STMT_BREAK(source = source)) :: xs),func,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (x :: xs_1,extraArg);
        
    // MetaModelica extension. KS
    case (((x as DAE.STMT_FAILURE(body=stmts, source = source)) :: xs),func,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_FAILURE(stmts2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_TRY(tryBody=stmts, source = source)) :: xs),func,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_TRY(stmts2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_CATCH(catchBody=stmts, source = source)) :: xs),func,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (DAE.STMT_CATCH(stmts2,source) :: xs_1,extraArg);
        
    case (((x as DAE.STMT_THROW(source = source)) :: xs),func,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
      then (x :: xs_1,extraArg);
        
    case ((x :: xs),func,extraArg)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "DAEUtil.traverseDAEEquationsStmts not implemented correctly: " +& str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
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
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outElse,oextraArg) := match(inElse,func,extraArg)
  local
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    Algorithm.Else el,el_1;
  case(DAE.NOELSE(),_,extraArg) then (DAE.NOELSE(),extraArg);
  case(DAE.ELSEIF(e,st,el),func,extraArg)
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
      ((e_1,extraArg)) = func((e, extraArg));
    then (DAE.ELSEIF(e_1,st_1,el_1),extraArg);
  case(DAE.ELSE(st),func,extraArg)
    equation
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
    then (DAE.ELSE(st_1),extraArg);
end match;
end traverseDAEEquationsStmtsElse;

protected function traverseDAEVarAttr "
Author: BZ, 2008-12
Help function to traverseDAE
"
  input Option<DAE.VariableAttributes> attr;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<DAE.VariableAttributes> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := match(attr,func,extraArg)
    local
      Option<DAE.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal,eb;
      Option<DAE.StateSelect> stateSelect;
      Option<Boolean> ip,fn;
    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),func,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (unit,extraArg) = traverseDAEOptExp(unit,func,extraArg);
        (displayUnit,extraArg) = traverseDAEOptExp(displayUnit,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        (nominal,extraArg) = traverseDAEOptExp(nominal,func,extraArg);
      then (SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,eb,ip,fn)),extraArg);

    case(SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),func,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      then (SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,eb,ip,fn)),extraArg);

      case(SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),func,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
          (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        then (SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn)),extraArg);

      case(SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),func,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        then (SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn)),extraArg);

      case(SOME(DAE.VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn)),func,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        then (SOME(DAE.VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn)),extraArg);

      case (NONE(),_,extraArg) then (NONE(),extraArg);
  end match;
end traverseDAEVarAttr;

public function getElementSourceFileInfo
"Gets the file information associated with an element.
If there are several candidates, select the first one."
  input DAE.ElementSource source;
  output Absyn.Info info;
algorithm
  info := match source
    case DAE.SOURCE(info = info) then info;
  end match;
end getElementSourceFileInfo;

public function getElementSourceTypes
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.typeLst"
 input DAE.ElementSource source "the source of the element";
 output list<Absyn.Path> pathLst;
algorithm
  pathLst := match(source)
    local list<Absyn.Path> pLst;
    case DAE.SOURCE(typeLst = pLst) then pLst;
  end match;
end getElementSourceTypes;

public function getElementSourceInstances
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.instanceOptLst"
 input DAE.ElementSource source "the source of the element";
 output list<Option<DAE.ComponentRef>> instanceOptLst;
algorithm
  instanceOptLst := matchcontinue(source)
    local list<Option<DAE.ComponentRef>> pLst;
    case DAE.SOURCE(instanceOptLst = pLst) then pLst;
  end matchcontinue;
end getElementSourceInstances;

public function getElementSourceConnects
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.connectEquationOptLst"
 input DAE.ElementSource source "the source of the element";
 output list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst;
algorithm
  connectEquationOptLst := matchcontinue(source)
    local list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> pLst;
    case DAE.SOURCE(connectEquationOptLst = pLst) then pLst;
  end matchcontinue;
end getElementSourceConnects;

public function getElementSourcePartOfs
"@author: adrpo
 retrieves the withins from the DAE.ElementSource.SOURCE.partOfLst"
 input DAE.ElementSource source "the source of the element";
 output list<Absyn.Within> withinLst;
algorithm
  withinLst := matchcontinue(source)
    local list<Absyn.Within> pLst;
    case DAE.SOURCE(partOfLst = pLst) then pLst;
  end matchcontinue;
end getElementSourcePartOfs;

public function addComponentTypeOpt "
  See setComponentType"
  input DAE.DAElist inDae;
  input Option<Absyn.Path> inPath;
  output DAE.DAElist outDae;
algorithm
  outDae := match (inDae,inPath)
      local Absyn.Path p; DAE.DAElist dae;
    case (dae,SOME(p)) equation
      dae = addComponentType(dae,p);
    then dae;
    case(dae,NONE()) then dae;
  end match;
end addComponentTypeOpt;

public function addComponentType "
  This function takes a dae element list and a type name and
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable."
  input DAE.DAElist inDae;
  input Absyn.Path newtype;
  output DAE.DAElist outDae;
algorithm
  outDae := match (inDae,newtype)
    local
      list<DAE.Element> elts;
    case (DAE.DAE(elts),newtype)
      equation
        elts = Util.listMap1(elts,addComponentType2,newtype);
      then DAE.DAE(elts);
  end match;
end addComponentType;

protected function addComponentType2 "
  This function takes a dae element list and a type name and
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable."
  input DAE.Element elt;
  input Absyn.Path inPath;
  output DAE.Element outElt;
algorithm
  outElt := match (elt,inPath)
    local
      DAE.ComponentRef cr;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.InstDims dim;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.VarProtection prot;
      Option<DAE.Exp> bind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Absyn.Path newtype;
      Absyn.InnerOuter io;
      DAE.ElementSource source "the element origin";

    case (DAE.VAR(componentRef = cr,
               kind = kind,
               direction = dir,
               protection = prot,
               ty = tp,
               binding = bind,
               dims = dim,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix,
               source = source,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io),newtype)
      equation
        source = addElementSourceType(source, newtype);
      then
        DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flowPrefix,streamPrefix,source,dae_var_attr,comment,io);
    else elt;
  end match;
end addComponentType2;

protected function addElementSourceType
  input DAE.ElementSource inSource;
  input Absyn.Path classPath;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, classPath)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;

    case (DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst), classPath)
      then DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, classPath::typeLst);
  end match;
end addElementSourceType;

protected function addElementSourceTypeOpt
  input DAE.ElementSource inSource;
  input Option<Absyn.Path> classPathOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, classPathOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
    case (inSource, NONE()) then inSource; // no source change.
    case (inSource, SOME(classPath))
      equation
        src = addElementSourceType(inSource, classPath);
      then src;
  end match;
end addElementSourceTypeOpt;

public function addElementSourcePartOf
  input DAE.ElementSource inSource;
  input Absyn.Within withinPath;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, withinPath)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;

    case (DAE.SOURCE(info,partOfLst, instanceOptLst, connectEquationOptLst, typeLst), withinPath)
      then DAE.SOURCE(info,withinPath::partOfLst, instanceOptLst, connectEquationOptLst, typeLst);
  end match;
end addElementSourcePartOf;

public function addElementSourcePartOfOpt
  input DAE.ElementSource inSource;
  input Option<Absyn.Path> classPathOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, classPathOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
    // a top level
    case (inSource, NONE())
      equation
        src = addElementSourcePartOf(inSource, Absyn.TOP());
      then inSource;
    case (inSource, SOME(classPath))
      equation
        src = addElementSourcePartOf(inSource, Absyn.WITHIN(classPath));
      then src;
  end match;
end addElementSourcePartOfOpt;

public function addElementSourceFileInfo
  input DAE.ElementSource source;
  input Absyn.Info fileInfo;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (source,fileInfo)
    local
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      Absyn.Info info;
    case (DAE.SOURCE(_,partOfLst,instanceOptLst,connectEquationOptLst,typeLst), info)
      then DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst);
  end match;
end addElementSourceFileInfo;

public function addElementSourceInstanceOpt
  input DAE.ElementSource inSource;
  input Option<DAE.ComponentRef> instanceOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inSource, instanceOpt)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<Absyn.Path> typeLst "the classes where the type of the element is defined" ;

    // a NONE() means top level (equivalent to NO_PRE, SOME(cref) means subcomponent
    case (DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst), instanceOpt)
      then DAE.SOURCE(info,partOfLst,instanceOpt::instanceOptLst,connectEquationOptLst,typeLst);
  end match;
end addElementSourceInstanceOpt;

public function addElementSourceConnectOpt
  input DAE.ElementSource inSource;
  input Option<tuple<DAE.ComponentRef,DAE.ComponentRef>> connectEquationOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, connectEquationOpt)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<Absyn.Path> typeLst "the classes where the type of the element is defined" ;

    // a top level
    case (inSource, NONE()) then inSource;
    case (inSource as DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst), connectEquationOpt)
      then DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOpt::connectEquationOptLst,typeLst);
  end matchcontinue;
end addElementSourceConnectOpt;

public function isExtFunction "returns true if element matches an external function"
  input DAE.Function elt;
  output Boolean res;
algorithm
  res := matchcontinue(elt)
    case(DAE.FUNCTION(functions=DAE.FUNCTION_EXT(body=_)::_)) then true;
    case(_) then false;
  end matchcontinue;
end isExtFunction;


public function functionName "returns the name of a FUNCTION or RECORD_CONSTRUCTOR"
  input DAE.Function elt;
  output Absyn.Path name;
algorithm
  name:= match(elt)
    case(DAE.FUNCTION(path=name)) then name;
    case(DAE.RECORD_CONSTRUCTOR(path=name)) then name;
  end match;
end functionName;

public function mergeSources
  input DAE.ElementSource src1;
  input DAE.ElementSource src2;
  output DAE.ElementSource mergedSrc;
algorithm
  mergedSrc := match(src1,src2)
    local
      Absyn.Info info;
      list<Absyn.Within> partOfLst1,partOfLst2,p;
      list<Option<DAE.ComponentRef>> instanceOptLst1,instanceOptLst2,i;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst1,connectEquationOptLst2,c;
      list<Absyn.Path> typeLst1,typeLst2,t;
    case (DAE.SOURCE(info, partOfLst1, instanceOptLst1, connectEquationOptLst1, typeLst1),
          DAE.SOURCE(_ /* Discard */, partOfLst2, instanceOptLst2, connectEquationOptLst2, typeLst2))
      equation
        p = listAppend(partOfLst1, partOfLst2);
        i = listAppend(instanceOptLst1, instanceOptLst2);
        c = listAppend(connectEquationOptLst1, connectEquationOptLst1);
        t = listAppend(typeLst1, typeLst2);
      then DAE.SOURCE(info,p,i,c,t);
 end match;
end mergeSources;

function createElementSource
"@author: adrpo
 set the various sources of the element"
  input Absyn.Info fileInfo;
  input Option<Absyn.Path> partOf "the model(s) this element came from";
  input Option<DAE.ComponentRef> instanceOpt "the instance(s) this element is part of";
  input Option<tuple<DAE.ComponentRef, DAE.ComponentRef>> connectEquationOpt "this element came from this connect(s)";
  input Option<Absyn.Path> typeOpt "the classes where the type(s) of the element is defined";
  output DAE.ElementSource source;
algorithm
  source := addElementSourceFileInfo(DAE.emptyElementSource, fileInfo);
  source := addElementSourcePartOfOpt(source, partOf);
  source := addElementSourceInstanceOpt(source, instanceOpt);
  source := addElementSourceConnectOpt(source, connectEquationOpt);
  source := addElementSourceTypeOpt(source, typeOpt);
end createElementSource;

public function convertInlineTypeToBool "
Author: BZ, 2009-12
Function for converting a InlineType to a bool.
Whether the inline takes place before or after index reduction does not mather.
Any kind of inline will result in true.
"
input DAE.InlineType it;
output Boolean b;
algorithm b := matchcontinue(it)
  case(DAE.NO_INLINE()) then false;
  case(_) then true;
  end matchcontinue;
end convertInlineTypeToBool;

public function daeElements "Retrieve the elements from a DAEList"
  input DAE.DAElist dae;
  output list<DAE.Element> elts;
algorithm
  elts := match(dae)
    case(DAE.DAE(elts)) then elts;
  end match;
end daeElements;

public function joinDaes "joins two daes by appending the element lists and joining the function trees"
  input DAE.DAElist dae1;
  input DAE.DAElist dae2;
  output DAE.DAElist outDae;
algorithm
  outDae := match(dae1,dae2)
    local
      list<DAE.Element> elts1,elts2,elts;

    // just append lists 
    case(DAE.DAE(elts1), 
         DAE.DAE(elts2)) 
      equation
        // t1 = clock();
        elts = Util.listAppendNoCopy(elts1,elts2);
        // t2 = clock();
        // ti = t2 -. t1;
        // Debug.fprintln("innerouter", " joinDAEs: (" +& realString(ti) +& ") -> " +& intString(listLength(elts1)) +& " + " +&  intString(listLength(elts2)));
      then DAE.DAE(elts);
    
  end match;
end joinDaes;

public function joinDaeLst "joins a list of daes by using joinDaes"
  input list<DAE.DAElist> daeLst;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(daeLst)
    local
      DAE.DAElist dae,dae1;
    case({dae}) then dae;
    case(dae::daeLst)
      equation
        dae1 = joinDaeLst(daeLst);
        dae = joinDaes(dae,dae1);
      then dae;
  end matchcontinue;
end joinDaeLst;

/*AvlTree implementation for DAE functions.*/

public function keyStr "prints a key to a string"
input DAE.AvlKey k;
output String str;
algorithm
  str := Absyn.pathString(k);
end keyStr;

public function valueStr "prints a Value to a string"
input DAE.AvlValue v;
output String str;
algorithm
  str := DAEDump.dumpFunctionStr(Util.getOption(v));
end valueStr;

public function avlTreeNew "Return an empty tree"
  output DAE.AvlTree tree;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  tree := emptyFuncTree; // DAE.AVLTREENODE(NONE(),0,NONE(),NONE());
end avlTreeNew;

public function avlTreeToList "return tree as a flat list of tuples"
  input DAE.AvlTree tree;
  output list<tuple<DAE.AvlKey,DAE.AvlValue>> lst;
algorithm
  lst := avlTreeToList2(SOME(tree));
end avlTreeToList;

public function joinAvlTrees "joins two trees by adding the second one to the first"
  input DAE.AvlTree t1;
  input DAE.AvlTree t2;
  output DAE.AvlTree outTree;
algorithm
  outTree := avlTreeAddLst(avlTreeToList(t2),t1);
end joinAvlTrees;

protected function avlTreeToList2 "help function to avlTreeToList"
  input Option<DAE.AvlTree> tree;
  output list<tuple<DAE.AvlKey,DAE.AvlValue>> lst;
algorithm
  lst := match(tree)
  local Option<DAE.AvlTree> r,l; DAE.AvlKey k; DAE.AvlValue v;
    case NONE() then {};
    case(SOME(DAE.AVLTREENODE(value = NONE(),left = l,right = r) )) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then lst;
    case(SOME(DAE.AVLTREENODE(value=SOME(DAE.AVLTREEVALUE(k,v)),left = l, right = r))) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then (k,v)::lst;
  end match;
end avlTreeToList2;

public function avlTreeAddLst "Adds a list of (key,value) pairs"
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> values;
  input DAE.AvlTree inTree;
  output DAE.AvlTree outTree;
algorithm
  outTree := match(values,inTree)
  local DAE.AvlKey key;
    DAE.AvlValue val;
    DAE.AvlTree tree;
    case({},tree) then tree;
    case((key,val)::values,tree) equation
      tree = avlTreeAdd(tree,key,val);
      tree = avlTreeAddLst(values,tree);
    then tree;
  end match;
end avlTreeAddLst;

public function avlTreeAdd "
 Add a tuple (key,value) to the AVL tree."
  input DAE.AvlTree inAvlTree;
  input DAE.AvlKey inKey;
  input DAE.AvlValue inValue;
  output DAE.AvlTree outAvlTree;
algorithm
  outAvlTree := matchcontinue (inAvlTree,inKey,inValue)
    local
      DAE.AvlKey key,rkey;
      DAE.AvlValue value,rval;
      Option<DAE.AvlTree> left,right;
      Integer h;
      DAE.AvlTree t_1,t,bt;

      /* empty tree*/
    case (DAE.AVLTREENODE(value = NONE(),height=h,left = NONE(),right = NONE()),key,value)
      then DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(key,value)),1,NONE(),NONE());

      /* Replace this node.*/
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),height=h,left = left,right = right),key,value)
      equation
        true = ModUtil.pathEqual(rkey, key);
        bt = balance(DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(rkey,value)),h,left,right));
      then
        bt;

        /* Insert to right  */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),height=h,left = left,right = (right)),key,value)
      equation
        true = stringCompare(Absyn.pathString(key),Absyn.pathString(rkey)) > 0;
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(rkey,rval)),h,left,SOME(t_1)));
      then
        bt;

        /* Insert to left subtree */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),height=h,left = left ,right = right),key,value)
      equation
        /*true = stringCompare(key,rkey) < 0;*/
         t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(rkey,rval)),h,SOME(t_1),right));
      then
        bt;
    case (_,_,_)
      equation
        print("avlTreeAdd failed\n");
      then
        fail();
  end matchcontinue;
end avlTreeAdd;

protected function createEmptyAvlIfNone "Help function to DAE.AvlTreeAdd2"
input Option<DAE.AvlTree> t;
output DAE.AvlTree outT;
algorithm
  outT := match(t)
    case(NONE()) then DAE.AVLTREENODE(NONE(),0,NONE(),NONE());
    case(SOME(outT)) then outT;
  end match;
end createEmptyAvlIfNone;

protected function nodeValue "return the node value"
input DAE.AvlTree bt;
output DAE.AvlValue v;
algorithm
  v := matchcontinue(bt)
    case(DAE.AVLTREENODE(value=SOME(DAE.AVLTREEVALUE(_,v)))) then v;
  end matchcontinue;
end nodeValue;

protected function balance "Balances a DAE.AvlTree"
  input DAE.AvlTree bt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local Integer d;
    case(bt) equation
      d = differenceInHeight(bt);
      bt = doBalance(d,bt);
    then bt;
    case(_) equation
      print("balance failed\n");
    then fail();
  end matchcontinue;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
input Integer difference;
input DAE.AvlTree bt;
output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(difference,bt) equation
      bt = doBalance2(difference,bt);
    then bt;
    case(difference,bt) then bt;
  end  matchcontinue;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Integer difference;
  input DAE.AvlTree bt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,bt)
    case(difference,bt) equation
      true = difference < 0;
      bt = doBalance3(bt);
      bt = rotateLeft(bt);
     then bt;
    case(difference,bt) equation
      true = difference > 0;
      bt = doBalance4(bt);
      bt = rotateRight(bt);
     then bt;
  end matchcontinue;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input DAE.AvlTree bt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(bt)
  local DAE.AvlTree rr;
    case(bt) equation
      true = differenceInHeight(getOption(rightNode(bt))) > 0;
      rr = rotateRight(getOption(rightNode(bt)));
      bt = setRight(bt,SOME(rr));
    then bt;
    case(bt) then bt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input DAE.AvlTree bt;
  output DAE.AvlTree outBt;
algorithm
  outBt := match(bt)
  local DAE.AvlTree rl;
 case(bt) equation
      true = differenceInHeight(getOption(leftNode(bt))) < 0;
      rl = rotateLeft(getOption(leftNode(bt)));
      bt = setLeft(bt,SOME(rl));
    then bt;
  end match;
end doBalance4;

protected function setRight "set right treenode"
  input DAE.AvlTree node;
  input Option<DAE.AvlTree> right;
  output DAE.AvlTree outNode;
algorithm
  outNode := match(node,right)
   local Option<DAE.AvlTreeValue> value;
    Option<DAE.AvlTree> l,r;
    Integer height;
    case(DAE.AVLTREENODE(value,height,l,r),right) then DAE.AVLTREENODE(value,height,l,right);
  end match;
end setRight;

protected function setLeft "set left treenode"
  input DAE.AvlTree node;
  input Option<DAE.AvlTree> left;
  output DAE.AvlTree outNode;
algorithm
  outNode := match(node,left)
  local Option<DAE.AvlTreeValue> value;
    Option<DAE.AvlTree> l,r;
    Integer height;
    case(DAE.AVLTREENODE(value,height,l,r),left) then DAE.AVLTREENODE(value,height,left,r);
  end match;
end setLeft;


protected function leftNode "Retrieve the left subnode"
  input DAE.AvlTree node;
  output Option<DAE.AvlTree> subNode;
algorithm
  subNode := match(node)
    case(DAE.AVLTREENODE(left = subNode)) then subNode;
  end match;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input DAE.AvlTree node;
  output Option<DAE.AvlTree> subNode;
algorithm
  subNode := match(node)
    case(DAE.AVLTREENODE(right = subNode)) then subNode;
  end match;
end rightNode;

protected function exchangeLeft "help function to balance"
  input DAE.AvlTree node;
  input DAE.AvlTree parent;
  output DAE.AvlTree outParent "updated parent";
algorithm
  outParent := match(node,parent)
    local
      DAE.AvlTree bt;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeLeft;

protected function exchangeRight "help function to balance"
input DAE.AvlTree node;
input DAE.AvlTree parent;
output DAE.AvlTree outParent "updated parent";
algorithm
  outParent := match(node,parent)
  local DAE.AvlTree bt;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeRight;

protected function rotateLeft "help function to balance"
input DAE.AvlTree node;
output DAE.AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(getOption(rightNode(node)),node);
end rotateLeft;

protected function getOption "Retrieve the value of an option"
  replaceable type T subtypeof Any;
  input Option<T> opt;
  output T val;
algorithm
  val := match(opt)
    case(SOME(val)) then val;
  end match;
end getOption;

protected function rotateRight "help function to balance"
input DAE.AvlTree node;
output DAE.AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(getOption(leftNode(node)),node);
end rotateRight;

protected function differenceInHeight "help function to balance, calculates the difference in height
between left and right child"
input DAE.AvlTree node;
output Integer diff;
algorithm
  diff := match(node)
  local Integer lh,rh;
    Option<DAE.AvlTree> l,r;
    case(DAE.AVLTREENODE(left=l,right=r)) equation
      lh = getHeight(l);
      rh = getHeight(r);
    then lh - rh;
  end match;
end differenceInHeight;

public function avlTreeGet "  Get a value from the binary tree given a key.
"
  input DAE.AvlTree inAvlTree;
  input DAE.AvlKey inKey;
  output DAE.AvlValue outValue;
algorithm
  outValue := matchcontinue (inAvlTree,inKey)
    local
      DAE.AvlKey rkey,key;
      DAE.AvlValue rval,res;
      DAE.AvlTree left,right;
    
    // hash func Search to the right
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval))),key)
      equation
        0 = stringCompare(Absyn.pathString(key),Absyn.pathString(rkey));
      then
        rval;

    // Search to the right
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),right = SOME(right)),key)
      equation
        1 = stringCompare(Absyn.pathString(key),Absyn.pathString(rkey));
        res = avlTreeGet(right, key);
      then
        res;

    // Search to the left
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),left = SOME(left)),key)
      equation
        -1 = stringCompare(Absyn.pathString(key),Absyn.pathString(rkey));
        res = avlTreeGet(left, key);
      then
        res;
  end matchcontinue;
end avlTreeGet;

protected function getOptionStr "function getOptionStr
  Retrieve the string from a string option.
  If NONE() return empty string."
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString := matchcontinue (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_) then "";
  end matchcontinue;
end getOptionStr;

protected function printAvlTreeStr "
  Prints the avl tree to a string"
  input DAE.AvlTree inAvlTree;
  output String outString;
algorithm
  outString := matchcontinue (inAvlTree)
    local
      DAE.AvlKey rkey;
      String s1,s2,s3,res;
      DAE.AvlValue rval;
      Option<DAE.AvlTree> l,r;
      Integer h;

    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),height = h,left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "< value=" +& valueStr(rval) +& ",key=" +& keyStr(rkey) +& ",height="+& intString(h)+& s2 +& s3 +& ">\n";
      then
        res;
    case (DAE.AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "<NONE," +& s2 +& ", "+& s3 +& ">";

      then
        res;
  end matchcontinue;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the DAE.AvlTree and store in the node info"
  input DAE.AvlTree bt;
  output DAE.AvlTree outBt;
algorithm
 outBt := match(bt)
 local Option<DAE.AvlTree> l,r;
   Option<DAE.AvlTreeValue> v;
   DAE.AvlValue val;
   Integer hl,hr,height;
 case(DAE.AVLTREENODE(value=v as SOME(DAE.AVLTREEVALUE(_,val)),left=l,right=r)) equation
    hl = getHeight(l);
    hr = getHeight(r);
    height = intMax(hl,hr) + 1;
 then DAE.AVLTREENODE(v,height,l,r);
 end match;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<DAE.AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(DAE.AVLTREENODE(height = height))) then height;
  end match;
end getHeight;

public function splitElements
"@author: adrpo
  This function will split DAE elements into:
   variables, initial equations, initial algorithms, 
   equations, algorithms, external objects"
  input list<DAE.Element> inElements;
  output list<DAE.Element> v;
  output list<DAE.Element> ie;
  output list<DAE.Element> ia;
  output list<DAE.Element> e;
  output list<DAE.Element> a;
  output list<DAE.Element> o;
algorithm
  (v,ie,ia,e,a,o) := splitElements_dispatch(inElements,{},{},{},{},{},{});  
end splitElements;
protected function isIfEquation "function: isIfEquation
  Succeeds if Element is an if-equation.
"
  input DAE.Element inElement;
algorithm
  _:=
  match (inElement)
    case DAE.IF_EQUATION(condition1 = _) then ();
    case DAE.INITIAL_IF_EQUATION(condition1 = _) then ();
  end match;
end isIfEquation;

public function splitElements_dispatch
"@author: adrpo
  This function will split DAE elements into:
   variables, initial equations, initial algorithms, 
   equations, algorithms, external objects"
  input list<DAE.Element> inElements;
  input list<DAE.Element> v_acc;
  input list<DAE.Element> ie_acc;
  input list<DAE.Element> ia_acc;
  input list<DAE.Element> e_acc;
  input list<DAE.Element> a_acc;
  input list<DAE.Element> o_acc;
  output list<DAE.Element> v;
  output list<DAE.Element> ie;
  output list<DAE.Element> ia;
  output list<DAE.Element> e;
  output list<DAE.Element> a;
  output list<DAE.Element> o;
algorithm
  (v,ie,ia,e,a,o) := match(inElements,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
    local
      DAE.Element el;
      list<DAE.Element> rest;
      
    // handle empty case
    case ({}, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) 
    then (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc);
    
    // variables
    case ((el as DAE.VAR(kind=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc);  
      then
        (el::v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc);
  
    // initial equations
    case ((el as DAE.INITIALEQUATION(exp1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,el::ie_acc,ia_acc,e_acc,a_acc,o_acc);
    case ((el as DAE.INITIAL_ARRAY_EQUATION(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,el::ie_acc,ia_acc,e_acc,a_acc,o_acc);
    case ((el as DAE.INITIAL_COMPLEX_EQUATION(lhs=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,el::ie_acc,ia_acc,e_acc,a_acc,o_acc);
    case ((el as DAE.INITIALDEFINE(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,el::ie_acc,ia_acc,e_acc,a_acc,o_acc);
    case ((el as DAE.INITIAL_IF_EQUATION(condition1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,el::ie_acc,ia_acc,e_acc,a_acc,o_acc);

    // equations
    case ((el as DAE.EQUATION(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.EQUEQUATION(cr1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.ARRAY_EQUATION(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.COMPLEX_EQUATION(lhs=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.DEFINE(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.ASSERT(condition=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);        
    case ((el as DAE.IF_EQUATION(condition1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.WHEN_EQUATION(condition=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.REINIT(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
    case ((el as DAE.NORETCALL(functionName=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,el::e_acc,a_acc,o_acc);
        
    // initial algorithms
    case ((el as DAE.INITIALALGORITHM(algorithm_=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,el::ia_acc,e_acc,a_acc,o_acc);        

    // algorithms
    case ((el as DAE.ALGORITHM(algorithm_=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,e_acc,el::a_acc,o_acc);
        
    // external objects
    case ((el as DAE.EXTOBJECTCLASS(path=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc); 
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,el::o_acc);
  end match;
end splitElements_dispatch;

public function collectLocalDecls
"Used to traverse expressions and collect all local declarations"
  input tuple<DAE.Exp,list<DAE.Element>> tpl;
  output tuple<DAE.Exp,list<DAE.Element>> otpl;
algorithm
  otpl := matchcontinue (tpl)
    local
      DAE.Exp e;
      list<DAE.Element> ld1,ld2,ld;
    case ((e as DAE.MATCHEXPRESSION(localDecls = ld1),ld2))
      equation
        ld = listAppend(ld1,ld2);
      then ((e,ld));
    else tpl;
  end matchcontinue;
end collectLocalDecls;

public function getUniontypePaths
"Traverses DAE elements to find all Uniontypes, and return the paths
of all of their records. This list contains duplicates; handle that in
the other function."
  input list<DAE.Function> funcs;
  input list<DAE.Element> els;
  output list<Absyn.Path> outPaths;
protected
  list<Absyn.Path> paths1,paths2;
algorithm
  outPaths := matchcontinue (funcs, els)
    case (_,_)
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then {};
    case (funcs, els)
      equation
        paths1 = getUniontypePathsFunctions(funcs);
        paths2 = getUniontypePathsElements(els);
        // Use accumulators? Small gain as T_UNIONTYPE has lists of paths anyway?
        outPaths = listAppend(paths1, paths2);
      then outPaths;
  end matchcontinue;
end getUniontypePaths;

protected function getUniontypePathsFunctions
"May contain duplicates."
  input list<DAE.Function> elements;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := match elements
    local
      list<DAE.Element> els,els1,els2;
    case elements
      equation
        (_,(_,els1)) = traverseDAEFunctions(elements, Expression.traverseSubexpressionsHelper, (collectLocalDecls,{}));
        els2 = getFunctionsElements(elements);
        els = listAppend(els1, els2);
        outPaths = getUniontypePathsElements(els);
      then outPaths;
  end match;
end getUniontypePathsFunctions;

protected function getUniontypePathsElements
"May contain duplicates."
  input list<DAE.Element> elements;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := match elements
    local
      list<Absyn.Path> paths1;
      list<DAE.Element> rest;
      list<DAE.Type> tys;
      DAE.Type ft;
    case {} then {};
    case DAE.VAR(ty = ft)::rest
      equation
        paths1 = getUniontypePathsElements(rest);
        tys = Types.getAllInnerTypesOfType(ft, Types.uniontypeFilter);
      then Util.listApplyAndFold(tys, listAppend, Types.getUniontypePaths, paths1);
    case _::rest then getUniontypePathsElements(rest);
  end match;
end getUniontypePathsElements;

protected function getDAEDeclsFromValueblocks
  input list<DAE.Exp> exps;
  output list<DAE.Element> outEls;
algorithm
  outEls := matchcontinue (exps)
    local
      list<DAE.Exp> rest;
      list<DAE.Element> els1,els2;
    case {} then {};
    case DAE.MATCHEXPRESSION(localDecls = els1)::rest
      equation
        els2 = getDAEDeclsFromValueblocks(rest);
      then listAppend(els1,els2);
    case _::rest then getDAEDeclsFromValueblocks(rest);
  end matchcontinue;
end getDAEDeclsFromValueblocks;

public function transformDerInline
"Simple euler inline of the equation system; only does explicit euler, and only der(cref)"
  input DAE.DAElist dae;
  output DAE.DAElist d;
algorithm
  d := matchcontinue (dae)
    local
      HashTable.HashTable ht;
    case (dae)
      equation
        false = RTOpts.debugFlag("frontend-inline-euler");
      then dae;
    case (dae)
      equation
        ht = HashTable.emptyHashTable();
        (d,_,ht) = traverseDAE(dae,emptyFuncTree,simpleInlineDerEuler,ht);
      then d;
  end matchcontinue;
end transformDerInline;

public function simpleInlineDerEuler
"Simple euler inline of the equation system; only does explicit euler, and only der(cref)"
  input tuple<DAE.Exp,HashTable.HashTable> itpl;
  output tuple<DAE.Exp,HashTable.HashTable> otpl;
algorithm
  otpl := matchcontinue (itpl)
    local
      DAE.ComponentRef cr,cref_1,cref_2;
      HashTable.HashTable crs0,crs1;
      DAE.Exp exp,e1,e2;
      
    case ((DAE.CALL(path=Absyn.IDENT("der"),expLst={exp as DAE.CREF(componentRef = cr, ty = DAE.ET_REAL())}),crs0))
      equation
        cref_1 = ComponentReference.makeCrefQual("$old",DAE.ET_REAL(),{},cr);
        cref_2 = ComponentReference.makeCrefIdent("$current_step_size",DAE.ET_REAL(),{});
        e1 = Expression.makeCrefExp(cref_1,DAE.ET_REAL());
        e2 = Expression.makeCrefExp(cref_2,DAE.ET_REAL());
        exp = DAE.BINARY(
                DAE.BINARY(exp, DAE.SUB(DAE.ET_REAL()), e1),
                DAE.DIV(DAE.ET_REAL()),
                e2);
        crs1 = BaseHashTable.add((cr,0),crs0);
      then 
        ((exp,crs1));
    
    case ((exp,crs0)) then ((exp,crs0));
    
  end matchcontinue;
end simpleInlineDerEuler;

public function transformationsBeforeBackend
  input DAE.DAElist dae;
  output DAE.DAElist d;
algorithm
  d := dae;
  // Transform if equations to if expression before going into code generation.
  d := evaluateAnnotation(d);
  d := transformIfEqToExpr(d,false);
  // Don't even run the function to try and do this; it doesn't work very well
  // d := transformDerInline(d);
end transformationsBeforeBackend;

public function setBindingSource
"@author: adrpo
  This function will set the source of the binding"
 input DAE.Binding inBinding;
 input DAE.BindingSource bindingSource;
 output DAE.Binding outBinding;
algorithm
  outBinding := match(inBinding, bindingSource)
    local
      DAE.Exp exp "exp";
      Option<Values.Value> evaluatedExp "evaluatedExp; evaluated exp";
      DAE.Const cnst "constant";
      Values.Value valBound;
        
    case (inBinding as DAE.UNBOUND(), _) then inBinding;
    case (DAE.EQBOUND(exp, evaluatedExp, cnst, _), bindingSource) then DAE.EQBOUND(exp, evaluatedExp, cnst, bindingSource);
    case (DAE.VALBOUND(valBound, _), bindingSource) then DAE.VALBOUND(valBound, bindingSource);
 end match;
end setBindingSource;

public function printBindingExpStr "prints a binding"
  input DAE.Binding binding;
  output String str;
algorithm
  str := match(binding)
    local 
      DAE.Exp e; Values.Value v;
    case(DAE.UNBOUND()) then "";
    case(DAE.EQBOUND(exp=e)) 
      equation
        str = ExpressionDump.printExpStr(e);
      then 
        str;
    case(DAE.VALBOUND(valBound=v)) 
      equation
        str = " = " +& ValuesUtil.valString(v);
      then 
        str;
  end match;
end printBindingExpStr;

public function printBindingSourceStr "prints a binding source as a string"
  input DAE.BindingSource bindingSource;
  output String str;
algorithm
  str := match(bindingSource)
    local 
    case(DAE.BINDING_FROM_DEFAULT_VALUE()) then "[DEFAULT VALUE]";
    case(DAE.BINDING_FROM_START_VALUE()) then  "[START VALUE]";
  end match;
end printBindingSourceStr;

public function collectValueblockFunctionRefVars
"Collect the function names of variables in valueblock local sections"
  input tuple<DAE.Exp,list<Absyn.Path>> itpl;
  output tuple<DAE.Exp,list<Absyn.Path>> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      list<DAE.Element> decls;
      DAE.Exp exp;
      list<Absyn.Path> acc;
    case ((exp as DAE.MATCHEXPRESSION(localDecls = decls),acc))
      equation
        acc = Util.listFold(decls, collectFunctionRefVarPaths, acc);
      then ((exp,acc));
    case itpl then itpl;
  end matchcontinue;
end collectValueblockFunctionRefVars;

public function collectFunctionRefVarPaths
"Collect the function names of declared variables"
  input DAE.Element inElem;
  input list<Absyn.Path> acc;
  output list<Absyn.Path> outAcc;
algorithm
  outAcc := matchcontinue (inElem,acc)
    local
      Absyn.Path path;
    case (DAE.VAR(ty = ((DAE.T_FUNCTION(funcArg=_)),SOME(path))),acc)
      then path::acc;
    case (_,acc) then acc;
  end matchcontinue;
end collectFunctionRefVarPaths;

public function addDaeFunction "add functions present in the element list to the function tree"
  input list<DAE.Function> funcs;
  input DAE.FunctionTree tree;
  output DAE.FunctionTree outTree;
algorithm
  outTree := match(funcs,tree)
    local
      DAE.Function func;

    case ({},tree) then tree;
    case (func::funcs,tree)
      equation
        // print("Add to cache: " +& Absyn.pathString(functionName(func)) +& "\n");
        tree = avlTreeAdd(tree,functionName(func),SOME(func));
      then addDaeFunction(funcs,tree);

  end match;
end addDaeFunction;

public function addDaeExtFunction "add extermal functions present in the element list to the function tree
Note: normal functions are skipped.
See also addDaeFunction"
  input list<DAE.Function> funcs;
  input DAE.FunctionTree tree;
  output DAE.FunctionTree outTree;
algorithm
  outTree := matchcontinue(funcs,tree)
    local
      DAE.Function func;

    case ({},tree) then tree;
    case (func::funcs,tree)
      equation
        true = isExtFunction(func);
        tree = avlTreeAdd(tree,functionName(func),SOME(func));
      then addDaeExtFunction(funcs,tree);

    case (func::funcs,tree) then addDaeExtFunction(funcs,tree);

  end matchcontinue;
end addDaeExtFunction;

end DAEUtil;

/* adrpo: 2010-10-04 never used by OpenModelica!
public function varHasName "returns true if variable equals name passed as argument"
  input DAE.Element var;
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(var,cr)
  local DAE.ComponentRef cr2;
    case(DAE.VAR(componentRef=cr2),cr) equation
      res = ComponentReference.crefEqualNoStringCompare(cr2,cr);
    then res;
  end matchcontinue;
end varHasName;
*/
