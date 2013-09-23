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

public function constStrFriendly "return the DAE.Const as a friendly string. Used for debugging."
  input DAE.Const const;
  output String str;
algorithm
  str := match(const)
    case(DAE.C_VAR()) then "";
    case(DAE.C_PARAM()) then "parameter ";
    case(DAE.C_CONST()) then "constant ";

  end match;
end constStrFriendly;

public function expTypeSimple "returns true if type is simple type"
  input DAE.Type tp;
  output Boolean isSimple;
algorithm
  isSimple := matchcontinue(tp)
    case(DAE.T_REAL(varLst = _)) then true;
    case(DAE.T_INTEGER(varLst = _)) then true;
    case(DAE.T_STRING(varLst = _)) then true;
    case(DAE.T_BOOL(varLst = _)) then true;
    case(DAE.T_ENUMERATION(path=_)) then true;

    case(_) then false;

  end matchcontinue;
end expTypeSimple;

public function expTypeElementType "returns the element type of an array"
  input DAE.Type tp;
  output DAE.Type eltTp;
algorithm
  eltTp := matchcontinue(tp)
    local
      DAE.Type ty;
    case (DAE.T_ARRAY(ty=ty)) then expTypeElementType(ty);
    else tp;
  end matchcontinue;
end expTypeElementType;

public function expTypeComplex "returns true if type is complex type"
  input DAE.Type tp;
  output Boolean isComplex;
algorithm
  isComplex := matchcontinue(tp)
    case(DAE.T_COMPLEX(complexClassType = _)) then true;
    case(_) then false;
  end matchcontinue;
end expTypeComplex;

public function expTypeArray "returns true if type is array type
Alternative names: isArrayType, isExpTypeArray"
  input DAE.Type tp;
  output Boolean isArray;
algorithm
  isArray := matchcontinue(tp)
    case(DAE.T_ARRAY(ty=_)) then true;
    case(_) then false;
  end matchcontinue;
end expTypeArray;

public function expTypeArrayDimensions "returns the array dimensions of an ExpType"
  input DAE.Type tp;
  output list<Integer> dims;
algorithm
  dims := matchcontinue(tp)
    local DAE.Dimensions array_dims;
    case(DAE.T_ARRAY(dims=array_dims)) equation
      dims = List.map(array_dims, Expression.dimensionSize);
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
  input list<DAE.FunctionDefinition> inFuncDefs;
  output list<Absyn.Path> paths;
algorithm
  paths := matchcontinue(inFuncDefs)
    local
      list<Absyn.Path> pLst1,pLst2;
      Absyn.Path p1,p2;
      list<DAE.FunctionDefinition> funcDefs;

    case({}) then {};

    case(DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1,defaultDerivative=SOME(p2),lowerOrderDerivatives=pLst1)::funcDefs)
      equation
        pLst2 = getDerivativePaths(funcDefs);
        paths = List.union(p1::p2::pLst1,pLst2);
      then
        paths;

    case(DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1,defaultDerivative=NONE(),lowerOrderDerivatives=pLst1)::funcDefs)
      equation
        pLst2 = getDerivativePaths(funcDefs);
        paths = List.union(p1::pLst1,pLst2);
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
       Option<DAE.Exp> e1,e2,e3,e4,e5,e6,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.StateSelect> sSelectOption,sSelectOption2;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOption;
      Option<Boolean> ip,fn;
      String s;

    case (_,SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,unc,distOption,_,ip,fn,so)))
    then (SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,e4,e5,e6,sSelectOption,unc,distOption,SOME(bindExp),ip,fn,so)));

    case (_,SOME(DAE.VAR_ATTR_INT(e1,min,e2,e3,unc,distOption,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_INT(e1,min,e2,e3,unc,distOption,SOME(bindExp),ip,fn,so));

    case (_,SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,SOME(bindExp),ip,fn,so));

    case (_,SOME(DAE.VAR_ATTR_STRING(e1,e2,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_STRING(e1,e2,SOME(bindExp),ip,fn,so));

    case (_,SOME(DAE.VAR_ATTR_ENUMERATION(e1,min,e2,e3,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_ENUMERATION(e1,min,e2,e3,SOME(bindExp),ip,fn,so));

    else equation print("-failure in DAEUtil.addEquationBoundString\n"); then fail();
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
protected import BackendDAEUtil;
protected import Ceval;
protected import ComponentReference;
protected import Config;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import System;
protected import Types;
protected import Util;
protected import DAEDump;

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
        Debug.fprintln(Flags.FAILTRACE, "- DAEUtil.splitDAEIntoVarsAndEquations failed on: " );
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
  // outDae := List.fold(vars,removeVariable,dae);
  outDae := match(dae, vars)
    local
      list<DAE.Element> elements;
    case (DAE.DAE(elements), _)
      equation
        elements = removeVariablesFromElements(elements, vars, {});
      then
        DAE.DAE(elements);
  end match;
end removeVariables;

protected function removeVariablesFromElements
"@author: adrpo
  remove the variables that match for the element list"
  input list<DAE.Element> inElements;
  input list<DAE.ComponentRef> variableNames;
  input list<DAE.Element> inAcc;
  output list<DAE.Element> outElements;
algorithm
  outElements := match (inElements,variableNames,inAcc)
    local
      DAE.ComponentRef cr;
      list<DAE.Element> rest, els, elist;
      DAE.Element v;
      String id;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;
      Boolean isEmpty;

    // empty case
    case({},_,_) then listReverse(inAcc);

    // variable present, remove it
    case((v as DAE.VAR(componentRef = cr))::rest, _, _)
      equation
        // variable is in the list! jump over it
        isEmpty = List.isEmpty(List.select1(variableNames, ComponentReference.crefEqual, cr));
        els = removeVariablesFromElements(rest, variableNames, List.consOnTrue(isEmpty, v, inAcc));
      then els;

    // handle components
    case(DAE.COMP(id,elist,source,cmt)::rest, _, _)
      equation
        elist = removeVariablesFromElements(elist, variableNames, {});
        els = removeVariablesFromElements(rest, variableNames, DAE.COMP(id,elist,source,cmt)::inAcc);
      then els;

    // anything else, just keep it
    case(v::rest, _, _)
      equation
        els = removeVariablesFromElements(rest, variableNames, v::inAcc);
      then els;
  end match;
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

    case(_,DAE.DAE({})) then DAE.DAE({});

    case(_,DAE.DAE((v as DAE.VAR(componentRef = cr))::elist))
      equation
        true = ComponentReference.crefEqualNoStringCompare(var,cr);
      then DAE.DAE(elist);

    case(_,DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2))
      equation
        DAE.DAE(elist) = removeVariable(var,DAE.DAE(elist));
        DAE.DAE(elist2) = removeVariable(var,DAE.DAE(elist2));
      then DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2);

    case(_,DAE.DAE(e::elist))
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
  outDae := List.fold(vars,removeInnerAttr,dae);
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
      DAE.VarKind kind; DAE.VarParallelism prl;
      DAE.VarDirection dir; DAE.Type tp;
      Option<DAE.Exp> bind; DAE.InstDims dim;
      DAE.ConnectorType ct; list<Absyn.Path> cls;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt; Absyn.InnerOuter io,io2;
      DAE.VarVisibility prot;
      DAE.ElementSource source "the origin of the element";

    case (_,DAE.DAE({})) then DAE.DAE({});
     /* When having an inner outer, we declare two variables on the same line.
        Since we can not handle this with current instantiation procedure, we create temporary variables in the dae.
        These are named uniqly and renamed later in "instClass"
     */
    case(_,DAE.DAE(DAE.VAR(oldVar,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,(io as Absyn.INNER_OUTER()))::elist))
      equation
        true = compareUniquedVarWithNonUnique(var,oldVar);
        newVar = nameInnerouterUniqueCref(oldVar);
        o = DAE.VAR(oldVar,kind,dir,prl,prot,tp,NONE(),dim,ct,source,attr,cmt,Absyn.OUTER()) "intact";
        u = DAE.VAR(newVar,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,Absyn.NOT_INNER_OUTER()) " unique'ified";
        elist3 = u::{o};
        elist= listAppend(elist3,elist);
      then
        DAE.DAE(elist);

    case(_,DAE.DAE(DAE.VAR(cr,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,io)::elist))
      equation
        true = ComponentReference.crefEqualNoStringCompare(var,cr);
        io2 = removeInnerAttribute(io);
      then
        DAE.DAE(DAE.VAR(cr,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,io2)::elist);

    case(_,DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2))
      equation
        DAE.DAE(elist) = removeInnerAttr(var,DAE.DAE(elist));
        DAE.DAE(elist2) = removeInnerAttr(var,DAE.DAE(elist2));
      then DAE.DAE(DAE.COMP(id,elist,source,cmt)::elist2);

    case(_,DAE.DAE(e::elist))
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
protected
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
    DAE.Type idt;
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
    DAE.Type ty;
    DAE.ComponentRef child,child_2;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(str,ty,subs),_)
    equation
      str2 = System.stringReplace(str, removalString, "");
      then
        ComponentReference.makeCrefIdent(str2,ty,subs);
  case(DAE.CREF_QUAL(str,ty,subs,child),_)
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

protected function removeInnerAttribute "Help function to removeInnerAttr"
   input Absyn.InnerOuter io;
   output Absyn.InnerOuter ioOut;
algorithm
  ioOut := matchcontinue(io)
    case(Absyn.INNER()) then Absyn.NOT_INNER_OUTER();
    case(Absyn.INNER_OUTER()) then Absyn.OUTER();
    else io;
  end matchcontinue;
end removeInnerAttribute;

public function varCref " returns the component reference of a variable"
  input DAE.Element elt;
  output DAE.ComponentRef cr;
algorithm
  DAE.VAR(componentRef = cr) := elt;
end varCref;


public function getUnitAttr "
  Return the unit attribute"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm
  start := matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp u;
    case (SOME(DAE.VAR_ATTR_REAL(unit=SOME(u)))) then u;
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
    else optExp;
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

public function getMinMaxValues
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output Option<DAE.Exp> outMinValue;
  output Option<DAE.Exp> outMaxValue;
algorithm (outMinValue, outMaxValue) := matchcontinue(inVariableAttributesOption)
  local
    Option<DAE.Exp> minValue, maxValue;

  case(SOME(DAE.VAR_ATTR_ENUMERATION(min=(minValue, maxValue)))) equation
  then (minValue, maxValue);

  case(SOME(DAE.VAR_ATTR_INT(min=(minValue, maxValue)))) equation
  then (minValue, maxValue);

  case(SOME(DAE.VAR_ATTR_REAL(min=(minValue, maxValue)))) equation
  then (minValue, maxValue);

  case(_)
  then (NONE(), NONE());
  end matchcontinue;
end getMinMaxValues;

public function setMinMax "
  sets the minmax attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,minMax)
    local
      Option<DAE.Exp> q,u,du,f,n,i;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
      Option<DAE.Exp> so;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,_,i,f,n,ss,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,_,i,f,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,_,u,du,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn,so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),minMax,NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setMinMax;

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

public function getStartOrigin  "
  Return the startOrigin attribute"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output Option<DAE.Exp> startOrigin;
algorithm startOrigin:= match (inVariableAttributesOption)
    local
      Option<DAE.Exp> so;
    case (SOME(DAE.VAR_ATTR_REAL(startOrigin = so))) then so;
    case (SOME(DAE.VAR_ATTR_INT(startOrigin = so))) then so;
    case (SOME(DAE.VAR_ATTR_BOOL(startOrigin = so))) then so;
    case (SOME(DAE.VAR_ATTR_STRING(startOrigin = so))) then so;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(startOrigin = so))) then so;
    case (NONE()) then NONE();
  end match;
end getStartOrigin;

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

public function getNominalAttrFail "
  Return the nominal attribute. or fails"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp nominal;
algorithm nominal := match(inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(nominal = SOME(r)))) then r;
  end match;
end getNominalAttrFail;

public function setVariableAttributes "sets the attributes of a DAE.Element that is VAR"
  input DAE.Element var;
  input Option<DAE.VariableAttributes> varOpt;
  output DAE.Element outVar;
algorithm
  outVar := match(var,varOpt)
    local
      DAE.ComponentRef cr; DAE.VarKind k;
      DAE.VarDirection d ; DAE.VarParallelism prl;
      DAE.VarVisibility v; DAE.Type ty; Option<DAE.Exp> b;
      DAE.InstDims  dims; DAE.ConnectorType ct;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt; Absyn.InnerOuter io;

    case(DAE.VAR(cr,k,d,prl,v,ty,b,dims,ct,source,_,cmt,io),_)
      then DAE.VAR(cr,k,d,prl,v,ty,b,dims,ct,source,varOpt,cmt,io);
  end match;
end setVariableAttributes;

public function setStateSelect "
  sets the stateselect attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.StateSelect s;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,s)
    local
      Option<DAE.Exp> q,u,du,f,n,so,start;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,start,f,n,_,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,start,f,n,SOME(s),unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_INT(quantity =_)),_) then fail();
    case (SOME(DAE.VAR_ATTR_BOOL(quantity =_)),_) then fail();
    case (SOME(DAE.VAR_ATTR_STRING(quantity =_)),_) then fail();
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quantity =_)),_) then fail();
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(s),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setStateSelect;

public function setStartAttr "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,start)
    local
      Option<DAE.Exp> q,u,du,f,n,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,_,f,n,ss,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,SOME(start),f,n,ss,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,_,f,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,SOME(start),f,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,_,f,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,SOME(start),f,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,_,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,SOME(start),eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,SOME(start),du,eb,ip,fn,so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),SOME(start),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setStartAttr;

public function setStartAttrOption "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,start)
    local
      Option<DAE.Exp> q,u,du,f,n,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,_,f,n,ss,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,start,f,n,ss,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,_,f,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,start,f,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,_,f,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,start,f,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,_,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,start,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,start,du,eb,ip,fn,so));
    case (NONE(),NONE()) then NONE();
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),start,NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setStartAttrOption;

public function setStartOrigin "
  sets the startOrigin attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> startOrigin;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,startOrigin)
    local
      Option<DAE.Exp> q,u,du,f,n,s;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,unc,distOpt,eb,ip,fn,_)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,unc,distOpt,eb,ip,fn,startOrigin));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,s,f,unc,distOpt,eb,ip,fn,_)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,s,f,unc,distOpt,eb,ip,fn,startOrigin));
    case (SOME(DAE.VAR_ATTR_BOOL(q,s,f,eb,ip,fn,_)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,s,f,eb,ip,fn,startOrigin));
    case (SOME(DAE.VAR_ATTR_STRING(q,s,eb,ip,fn,_)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,s,eb,ip,fn,startOrigin));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,s,du,eb,ip,fn,_)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,s,du,eb,ip,fn,startOrigin));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),startOrigin));
  end match;
end setStartOrigin;

public function getNominalAttr "
  returns the nominal attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  output DAE.Exp nominal;
algorithm
  nominal:=
  match (attr)
    local
      DAE.Exp n;
    case (SOME(DAE.VAR_ATTR_REAL(nominal=SOME(n)))) then n;
    case (_) then DAE.RCONST(1.0);
  end match;
end getNominalAttr;

public function setNominalAttr "
  sets the nominal attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp nominal;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,nominal)
    local
      Option<DAE.Exp> q,u,du,f,s,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,_,ss,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,SOME(nominal),ss,unc,distOpt,eb,ip,fn,so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),SOME(nominal),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setNominalAttr;

public function setUnitAttr "
  sets the unit attribute."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp unit;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,unit)
    local
      Option<DAE.Exp> q,u,du,f,n,s,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,SOME(unit),du,minMax,s,f,n,ss,unc,distOpt,eb,ip,fn,so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),SOME(unit),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setUnitAttr;

public function setProtectedAttr "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Boolean isProtected;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,isProtected)
    local
      Option<DAE.Exp> q,u,du,i,f,n,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,unc,distOpt,eb,_,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,unc,distOpt,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,unc,distOpt,eb,_,fn,so)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,unc,distOpt,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,_,fn,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,_,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,SOME(isProtected),fn,so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(isProtected),NONE(),NONE()));
  end match;
end setProtectedAttr;

public function getProtectedAttr "
  retrieves the protected attribute form VariableAttributes."
  input Option<DAE.VariableAttributes> attr;
  output Boolean isProtected;
algorithm
  isProtected := matchcontinue (attr)
    case (SOME(DAE.VAR_ATTR_REAL(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_INT(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_BOOL(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_STRING(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(isProtected=SOME(isProtected)))) then isProtected;
    case(_) then false;
  end matchcontinue;
end getProtectedAttr;

public function setFixedAttr "Function: setFixedAttr
Sets the start attribute:fixed to inputarg"
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> fixed;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr,fixed)
    local
      Option<DAE.Exp> q,u,du,n,ini,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,ini,_,n,ss,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,ini,fixed,n,ss,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,ini,_,unc,distOpt,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,ini,fixed,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,ini,_,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,ini,fixed,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,_,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,fixed,eb,ip,fn,so));
  end match;
end setFixedAttr;

public function setFinalAttr "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Boolean finalPrefix;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match (attr,finalPrefix)
    local
      Option<DAE.Exp> q,u,du,i,f,n,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,unc,distOpt,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,i,f,n,ss,unc,distOpt,eb,ip,SOME(finalPrefix),so));
    case (SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,unc,distOpt,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_INT(q,minMax,i,f,unc,distOpt,eb,ip,SOME(finalPrefix),so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,SOME(finalPrefix),so));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,SOME(finalPrefix),so));

    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_ENUMERATION(q,minMax,u,du,eb,ip,SOME(finalPrefix),so));

    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(finalPrefix),NONE()));
  end match;
end setFinalAttr;

public function getFinalAttr "
  returns true if have final attr."
  input Option<DAE.VariableAttributes> attr;
  output Boolean finalPrefix;
algorithm
  finalPrefix := match (attr)
    local Boolean b;
    case (SOME(DAE.VAR_ATTR_REAL(finalPrefix=SOME(b)))) then b;
    case (SOME(DAE.VAR_ATTR_INT(finalPrefix=SOME(b)))) then b;
    case (SOME(DAE.VAR_ATTR_BOOL(finalPrefix=SOME(b)))) then b;
    case (SOME(DAE.VAR_ATTR_STRING(finalPrefix=SOME(b)))) then b;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(finalPrefix=SOME(b)))) then b;
  else false;
  end match;
end getFinalAttr;

public function boolVarVisibility "Function: boolVarVisibility
Takes a DAE.varprotection and returns true/false (is_protected / not)"
  input DAE.VarVisibility vp;
  output Boolean prot;
algorithm
  prot := matchcontinue(vp)
    case(DAE.PUBLIC()) then false;
    case(DAE.PROTECTED()) then true;
    case(_) equation print("- DAEUtil.boolVa_Protection failed\n"); then fail();
  end matchcontinue;
end boolVarVisibility;

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

public function getStartAttrString "
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

public function getMatchingElements "author:  LS

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
  oelist := List.filter(elist, cond);
end getMatchingElements;

public function getAllMatchingElements "author:  PA

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
      list<DAE.Element> elist1,elist2;
      DAE.Element e;
    case ({},_) then {};
    case (DAE.COMP(dAElist=elist1)::elist2,_)
      equation
        elist1 = getAllMatchingElements(elist1,cond);
        elist2 = getAllMatchingElements(elist2,cond);
      then listAppend(elist1,elist2);
    case(e::elist2,_)
      equation
        cond(e);
        elist2 = getAllMatchingElements(elist2,cond);
      then e::elist2;
    case(e::elist2,_)
      then getAllMatchingElements(elist2,cond);
  end matchcontinue;
end getAllMatchingElements;

public function findAllMatchingElements "author:  adrpo
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
    case(DAE.DAE(DAE.COMP(dAElist=lst)::rest),_,_)
      equation
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(lst),cond1,cond2);
        (DAE.DAE(elist1a),DAE.DAE(elist2a)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
        elist1 = listAppend(elist1,elist1a);
        elist2 = listAppend(elist2,elist2a);
      then (DAE.DAE(elist1),DAE.DAE(elist2));
    // handle both first and second condition true!
    case(DAE.DAE(e::rest),_,_)
      equation
        cond1(e);
        cond2(e);
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(e::elist1),DAE.DAE(e::elist2));
    // handle first condition true
    case(DAE.DAE(e::rest),_,_)
      equation
        cond1(e);
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(e::elist1),DAE.DAE(elist2));
    // handle the second condition
    case(DAE.DAE(e::rest),_,_)
      equation
        cond2(e);
        (DAE.DAE(elist1),DAE.DAE(elist2)) = findAllMatchingElements(DAE.DAE(rest),cond1,cond2);
      then (DAE.DAE(elist1),DAE.DAE(e::elist2));
    // move to next element.
    case(DAE.DAE(e::rest),_,_)
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

public function isParameter "author: LS
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

public function isParamOrConstVar
  input DAE.Var inVar;
  output Boolean outIsParamOrConst;
protected
  SCode.Variability var;
algorithm
  DAE.TYPES_VAR(attributes = DAE.ATTR(variability = var)) := inVar;
  outIsParamOrConst := SCode.isParameterOrConst(var);
end isParamOrConstVar;

public function isNotParamOrConstVar
  input DAE.Var inVar;
  output Boolean outIsNotParamOrConst;
algorithm
  outIsNotParamOrConst := not isParamOrConstVar(inVar);
end isNotParamOrConstVar;

public function isParamConstOrComplexVar
  input DAE.Var inVar;
  output Boolean outIsParamConstComplex;
algorithm
  outIsParamConstComplex := isParamOrConstVar(inVar) or
                            isComplexVar(inVar);
end isParamConstOrComplexVar;

public function isParamOrConstVarKind
  input DAE.VarKind inVarKind;
  output Boolean outIsParamOrConst;
algorithm
  outIsParamOrConst := match(inVarKind)
    case DAE.PARAM() then true;
    case DAE.CONST() then true;
    else false;
  end match;
end isParamOrConstVarKind;

public function isInnerVar "author: PA

  Succeeds if element is a variable with prefix inner.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.VAR(innerOuter = Absyn.INNER()) then ();
    case DAE.VAR(innerOuter = Absyn.INNER_OUTER())then ();
  end matchcontinue;
end isInnerVar;

public function isOuterVar "author: PA
  Succeeds if element is a variable with prefix outer.
"
  input DAE.Element inElement;
algorithm _:= matchcontinue (inElement)
    case DAE.VAR(innerOuter = Absyn.OUTER()) then ();
    // FIXME? adrpo: do we need this?
    // case DAE.VAR(innerOuter = Absyn.INNER_OUTER()) then ();
  end matchcontinue;
end isOuterVar;

public function isComp "author: LS

  Succeeds if element is component, COMP.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.COMP(ident = _) then ();
  end matchcontinue;
end isComp;

public function getOutputVars "author: LS

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
  vl_1 := getMatchingElements(vl, assertProtectedVar);
end getProtectedVars;

public function getBidirVars "author: LS

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
  DAE.VAR(kind = DAE.VARIABLE(), connectorType = DAE.FLOW()) := inElement;
end isFlowVar;

public function isStreamVar
  "Succeeds if the given variable has a stream prefix."
  input DAE.Element inElement;
algorithm
  DAE.VAR(kind = DAE.VARIABLE(), connectorType = DAE.STREAM()) := inElement;
end isStreamVar;

public function isFlow
  input DAE.ConnectorType inFlow;
  output Boolean outIsFlow;
algorithm
  outIsFlow := match(inFlow)
    case DAE.FLOW() then true;
    else false;
  end match;
end isFlow;

public function isStream
  input DAE.ConnectorType inStream;
  output Boolean outIsStream;
algorithm
  outIsStream := match(inStream)
    case DAE.STREAM() then true;
    else false;
  end match;
end isStream;

public function isOutputVar
"Succeeds if Element is an output variable."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.OUTPUT()) then ();
  end match;
end isOutputVar;

public function assertProtectedVar
"Succeeds if Element is a protected variable."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.VAR(protection=DAE.PROTECTED()) then ();
  end match;
end assertProtectedVar;

public function isProtectedVar
"Succeeds if Element is a protected variable."
  input DAE.Element inElement;
  output Boolean b;
algorithm
  b := match (inElement)
    case DAE.VAR(protection=DAE.PROTECTED()) then true;
    else false;
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

public function isBidirVarDirection
  input DAE.VarDirection inVarDirection;
  output Boolean outIsBidir;
algorithm
  outIsBidir := match(inVarDirection)
    case DAE.BIDIR() then true;
    else false;
  end match;
end isBidirVarDirection;

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
    case DAE.VAR(ty = DAE.T_FUNCTION(funcArg = _)) then true;
    else false;
  end match;
end isFunctionRefVar;

public function isAlgorithm "author: LS

  Succeeds if Element is an algorithm."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    case DAE.ALGORITHM(algorithm_ = _) then ();
  end match;
end isAlgorithm;

public function isFunctionInlineFalse "author: PA

  Succeeds if is a function with Inline=false"
  input DAE.Function inElement;
  output Boolean res;
algorithm
  res := match (inElement)
    case DAE.FUNCTION(inlineType = DAE.NO_INLINE()) then true;
    else false;
  end match;
end isFunctionInlineFalse;

public function findElement "
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
    case ((e::rest),f)
      equation
        f(e);
      then
        SOME(e);
    case ((e::rest),f)
      equation
        failure(f(e));
        e_1 = findElement(rest, f);
      then
        e_1;
  end matchcontinue;
end findElement;

public function getVariableBindingsStr "
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

protected function getVariableList "
  Return all variables from an Element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst := matchcontinue (inElementLst)
    local
      list<DAE.Element> res,lst;
      DAE.Element x;

    /* adrpo: filter out records! */
    case ((x as DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_))))::lst)
      equation
        res = getVariableList(lst);
      then
        (res);

    case ((x as DAE.VAR(ty = _))::lst)
      equation
        res = getVariableList(lst);
      then
        (x::res);
    case (_::lst)
      equation
        res = getVariableList(lst);
      then
        res;
    case {} then {};
  end matchcontinue;
end getVariableList;

protected function getBindingsStr "
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
    case (((v as DAE.VAR(componentRef = cr,binding = SOME(e)))::(lst as (_::_))))
      equation
        expstr = ExpressionDump.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((v as DAE.VAR(componentRef = cr,binding = NONE()))::(lst as (_::_))))
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

public function getBindings "Author: BZ, 2008-11
Get variable-bindings from element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outc;
  output list<DAE.Exp> oute;
algorithm
  (outc,oute) := matchcontinue (inElementLst)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Element> rest;
    case({}) then ({},{});
    case (DAE.VAR(componentRef = cr,binding = SOME(e))::rest)
      equation
        (outc,oute) = getBindings(rest);
      then
        (cr::outc,e::oute);
    case (DAE.VAR(componentRef = cr,binding  = NONE())::rest)
      equation
        (outc,oute) = getBindings(rest);
      then (outc,oute);
    else equation print(" error in getBindings \n"); then fail();
  end matchcontinue;
end getBindings;

public function toConnectorType
  "Converts a SCode.ConnectorType to a DAE.ConnectorType, given a class type."
  input SCode.ConnectorType inConnectorType;
  input ClassInf.State inState;
  output DAE.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType, inState)
    case (SCode.FLOW(), _) then DAE.FLOW();
    case (SCode.STREAM(), _) then DAE.STREAM();
    case (_, ClassInf.CONNECTOR(path = _)) then DAE.POTENTIAL();
    else DAE.NON_CONNECTOR();
  end match;
end toConnectorType;

public function toDaeParallelism "Converts scode parallelsim to dae parallelism.
  Prints a warning if parallel variables are used
  in a non-function class."
  input DAE.ComponentRef inCref;
  input SCode.Parallelism inParallelism;
  input ClassInf.State inState;
  input Absyn.Info inInfo;
  output DAE.VarParallelism outParallelism;
algorithm
  outParallelism := matchcontinue (inCref,inParallelism,inState,inInfo)
    local
      String str1;
      Absyn.Path path;

    case (_, SCode.NON_PARALLEL(), _, _) then DAE.NON_PARALLEL();

    //In functions. No worries.
    case (_, SCode.PARGLOBAL(), ClassInf.FUNCTION(_,_), _) then DAE.PARGLOBAL();
    case (_, SCode.PARLOCAL(), ClassInf.FUNCTION(_,_), _) then DAE.PARLOCAL();

    // In other classes print warning
    case (_, SCode.PARGLOBAL(), _, _)
      equation
        path = ClassInf.getStateName(inState);
        str1 = "\n" +&
        "- DAEUtil.toDaeParallelism: parglobal component '" +& ComponentReference.printComponentRefStr(inCref)
        +& "' in non-function class: " +& ClassInf.printStateStr(inState) +& " " +& Absyn.pathString(path);

        Error.addSourceMessage(Error.PARMODELICA_WARNING,
          {str1}, inInfo);
      then DAE.PARGLOBAL();

    case (_, SCode.PARLOCAL(), _, _)
      equation
        path = ClassInf.getStateName(inState);
        str1 = "\n" +&
        "- DAEUtil.toDaeParallelism: parlocal component '" +& ComponentReference.printComponentRefStr(inCref)
        +& "' in non-function class: " +& ClassInf.printStateStr(inState) +& " " +& Absyn.pathString(path);

        Error.addSourceMessage(Error.PARMODELICA_WARNING,
          {str1}, inInfo);
      then DAE.PARLOCAL();
  end matchcontinue;
end toDaeParallelism;

public function scodePrlToDaePrl
"Translates SCode.Parallelism to DAE.VarParallelism
  without considering if it is a function or not."
  input SCode.Parallelism inParallelism;
  output DAE.VarParallelism outVarParallelism;
algorithm
  outVarParallelism := match (inParallelism)
    case SCode.NON_PARALLEL() then DAE.NON_PARALLEL();
    case SCode.PARGLOBAL() then DAE.PARGLOBAL();
    case SCode.PARLOCAL() then DAE.PARLOCAL();
  end match;
end scodePrlToDaePrl;

public function daeParallelismEqual
  input DAE.VarParallelism inParallelism1;
  input DAE.VarParallelism inParallelism2;
  output Boolean equal;
algorithm
  equal := match(inParallelism1,inParallelism2)
    case(DAE.NON_PARALLEL(),DAE.NON_PARALLEL()) then true;
    case(DAE.PARGLOBAL(),DAE.PARGLOBAL()) then true;
    case(DAE.PARLOCAL(),DAE.PARLOCAL()) then true;
    case(_,_) then false;
  end match;
end daeParallelismEqual;

public function getFlowVariables "Retrive the flow variables of an Element list."
  input list<DAE.Element> inElementLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inElementLst)
    local
      list<DAE.ComponentRef> res,res1,res1_1,res2;
      DAE.ComponentRef cr;
      list<DAE.Element> xs,lst;
      String id;
    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,connectorType = DAE.FLOW())::xs))
      equation
        res = getFlowVariables(xs);
      then
        (cr::res);
    case ((DAE.COMP(ident = id,dAElist = lst)::xs))
      equation
        res1 = getFlowVariables(lst);
        res1_1 = getFlowVariables2(res1, id);
        res2 = getFlowVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_::xs))
      equation
        res = getFlowVariables(xs);
      then
        res;
  end matchcontinue;
end getFlowVariables;

protected function getFlowVariables2 "
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
    case ((cr::xs),id)
      equation
        res = getFlowVariables2(xs, id);
        cr_1 = ComponentReference.makeCrefQual(id,DAE.T_UNKNOWN_DEFAULT,{}, cr);
      then
        (cr_1::res);
  end matchcontinue;
end getFlowVariables2;

public function getStreamVariables "Retrive the stream variables of an Element list."
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
    case ((DAE.VAR(componentRef = cr,connectorType = DAE.STREAM())::xs))
      equation
        res = getStreamVariables(xs);
      then
        (cr::res);
    case ((DAE.COMP(ident = id,dAElist = lst)::xs))
      equation
        res1 = getStreamVariables(lst);
        res1_1 = getStreamVariables2(res1, id);
        res2 = getStreamVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_::xs))
      equation
        res = getStreamVariables(xs);
      then
        res;
  end matchcontinue;
end getStreamVariables;

protected function getStreamVariables2 "
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
    case ((cr::xs),id)
      equation
        res = getStreamVariables2(xs, id);
        cr_1 = ComponentReference.makeCrefQual(id,DAE.T_UNKNOWN_DEFAULT,{}, cr);
      then
        (cr_1::res);
  end matchcontinue;
end getStreamVariables2;

public function daeToRecordValue "Transforms a list of elements into a record value.
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
      DAE.ElementSource source;
      Absyn.Info info;

    case (cache,env,cname,{},_) then (cache,Values.RECORD(cname,{},{},-1));  /* impl */
    case (cache,env,cname,DAE.VAR(componentRef = cr, binding = SOME(rhs),
          source= source)::rest, impl)
      equation
        // Debug.fprintln(Flags.FAILTRACE, "- DAEUtil.daeToRecordValue typeOfRHS: " +& ExpressionDump.typeOfString(rhs));
        info = getElementSourceFileInfo(source);
        (cache, value,_) = Ceval.ceval(cache, env, rhs, impl, NONE(), Absyn.MSG(info),0);
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = ComponentReference.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value::vals),(cr_str::names),ix));
    /*
    case (cache,env,cname,(DAE.EQUATION(exp = DAE.CREF(componentRef = cr),scalar = rhs)::rest),impl)
      equation
        (cache, value,_) = Ceval.ceval(Env.emptyCache(),{}, rhs, impl,NONE(), NONE(), Absyn.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = ComponentReference.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value::vals),(cr_str::names),ix));
    */
    case (cache,env,_,el::_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = DAEDump.dumpDebugDAE(DAE.DAE({el}));
        Debug.fprintln(Flags.FAILTRACE, "- DAEUtil.daeToRecordValue failed on: " +& str);
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

protected function toModelicaFormElts "Helper function to toModelicaForm."
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst := matchcontinue (inElementLst)
    local
      String str,str_1,id;
      list<DAE.Element> elts_1,elts,welts_1,welts,telts_1,eelts_1,telts,eelts,elts2;
      Option<DAE.Exp> d_1,d,f;
      DAE.ComponentRef cr,cr_1,cref_,cr1,cr2;
      DAE.Type ty;
      DAE.VarKind a;
      DAE.VarDirection b;
      DAE.VarParallelism prl;
      DAE.Type t;
      DAE.InstDims instDim;
      DAE.ConnectorType ct;
      DAE.Element elt_1,elt;
      DAE.DAElist dae_1,dae;
      DAE.VarVisibility prot;
      list<Absyn.Path> h;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e_1,e1_1,e2_1,e1,e2,e_2,e,e3,e_3;
      Absyn.Path p;
      Absyn.InnerOuter io;
      list<DAE.Exp> conds, conds_1;
      list<list<DAE.Element>> trueBranches, trueBranches_1;
      Boolean partialPrefix;
      list<DAE.FunctionDefinition> derFuncs;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the element origin";
      DAE.Algorithm alg;

    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,
               kind = a,
               direction = b,
               parallelism = prl,
               protection = prot,
               ty = t,
               binding = d,
               dims = instDim,
               connectorType = ct,
               source=source,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io)::elts))
      equation
        str = ComponentReference.printComponentRefStr(cr);
        str_1 = Util.stringReplaceChar(str, ".", "_");
        elts_1 = toModelicaFormElts(elts);
        d_1 = toModelicaFormExpOpt(d);
        ty = ComponentReference.crefLastType(cr);
        cref_ = ComponentReference.makeCrefIdent(str_1,ty,{});
      then
        (DAE.VAR(cref_,a,b,prl,prot,t,d_1,instDim,ct,source,dae_var_attr,comment,io)::elts_1);

    case ((DAE.DEFINE(componentRef = cr,exp = e,source = source)::elts))
      equation
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.DEFINE(cr_1,e_1,source)::elts_1);

    case ((DAE.INITIALDEFINE(componentRef = cr,exp = e,source = source)::elts))
      equation
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALDEFINE(cr_1,e_1,source)::elts_1);

    case ((DAE.EQUATION(exp = e1,scalar = e2,source = source)::elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.EQUATION(e1_1,e2_1,source)::elts_1);

    case ((DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source)::elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.COMPLEX_EQUATION(e1_1,e2_1,source)::elts_1);

    case ((DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source)::elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIAL_COMPLEX_EQUATION(e1_1,e2_1,source)::elts_1);

    case ((DAE.EQUEQUATION(cr1 = cr1,cr2 = cr2,source = source)::elts))
      equation
         DAE.CREF(cr1,_) = toModelicaFormExp(Expression.crefExp(cr1));
         DAE.CREF(cr2,_) = toModelicaFormExp(Expression.crefExp(cr2));
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.EQUEQUATION(cr1,cr2,source)::elts_1);

    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = SOME(elt),source = source)::elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        {elt_1} = toModelicaFormElts({elt});
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,SOME(elt_1),source)::elts_1);

    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = NONE(),source = source)::elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,NONE(),source)::elts_1);

    case ((DAE.IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts,source = source)::elts))
      equation
        conds_1 = List.map(conds,toModelicaFormExp);
        trueBranches_1 = List.map(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.IF_EQUATION(conds_1,trueBranches_1,eelts_1,source)::elts_1);

    case ((DAE.INITIAL_IF_EQUATION(condition1 = conds,equations2 = trueBranches,equations3 = eelts,source = source)::elts))
      equation
        conds_1 = List.map(conds,toModelicaFormExp);
        trueBranches_1 = List.map(trueBranches,toModelicaFormElts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIAL_IF_EQUATION(conds_1,trueBranches_1,eelts_1,source)::elts_1);

    case ((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source)::elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALEQUATION(e1_1,e2_1,source)::elts_1);

    case ((DAE.ALGORITHM(algorithm_ = alg,source = source)::elts))
      equation
        print("to_modelica_form_elts(ALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.ALGORITHM(alg,source)::elts_1);

    case ((DAE.INITIALALGORITHM(algorithm_ = alg,source = source)::elts))
      equation
        print("to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALALGORITHM(alg,source)::elts_1);

    case ((DAE.COMP(ident = id,dAElist = elts2,source = source, comment = comment)::elts))
      equation
        elts2 = toModelicaFormElts(elts2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.COMP(id,elts2,source,comment)::elts_1);

    case ((DAE.ASSERT(condition = e1,message=e2,level=e3,source = source)::elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
        e_2 = toModelicaFormExp(e2);
        e_3 = toModelicaFormExp(e3);
      then
        (DAE.ASSERT(e_1,e_2,e_3,source)::elts_1);
    case ((DAE.TERMINATE(message = e1,source = source)::elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
      then
        (DAE.TERMINATE(e_1,source)::elts_1);
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
      DAE.VarDirection a3; DAE.VarParallelism prl;
      DAE.VarVisibility a4;
      DAE.Type a5; DAE.InstDims a7; DAE.ConnectorType ct;
      Option<DAE.Exp> a6;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> a11;
      Option<SCode.Comment> a12; Absyn.InnerOuter a13;

    case(_, DAE.VAR(a1,a2,a3,prl,a4,a5,a6,a7,ct,source,a11,a12,a13))
      then DAE.VAR(newCr,a2,a3,prl,a4,a5,a6,a7,ct,source,a11,a12,a13);
  end match;
end replaceCrefInVar;

protected function toModelicaFormExpOpt "Helper function to toMdelicaFormElts."
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption := matchcontinue (inExpExpOption)
    local DAE.Exp e_1,e;
    case (SOME(e)) equation e_1 = toModelicaFormExp(e); then SOME(e_1);
    case (NONE()) then NONE();
  end matchcontinue;
end toModelicaFormExpOpt;

protected function toModelicaFormCref "Helper function to toModelicaFormElts."
  input DAE.ComponentRef cr;
  output DAE.ComponentRef outComponentRef;
protected
  String str,str_1;
  DAE.Type ty;
algorithm
  str := ComponentReference.printComponentRefStr(cr);
  ty := ComponentReference.crefLastType(cr);
  str_1 := Util.stringReplaceChar(str, ".", "_");
  outComponentRef := ComponentReference.makeCrefIdent(str_1,ty,{});
end toModelicaFormCref;

protected function toModelicaFormExp "Helper function to toModelicaFormElts."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      DAE.ComponentRef cr_1,cr;
      DAE.Type t,tp;
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e,e3_1,e3;
      DAE.Operator op;
      list<DAE.Exp> expl_1,expl;
      Absyn.Path f;
      Boolean b,bt;
      Integer i;
      Option<DAE.Exp> eopt_1,eopt;
      DAE.CallAttributes attr;
      Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;

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
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2,index=i,optionExpisASUB=optionExpisASUB))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        DAE.RELATION(e1_1,op,e2_1,i,optionExpisASUB);
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        e3_1 = toModelicaFormExp(e3);
      then
        DAE.IFEXP(e1_1,e2_1,e3_1);
    case (DAE.CALL(path = f,expLst = expl,attr = attr))
      equation
        expl_1 = List.map(expl, toModelicaFormExp);
      then
        DAE.CALL(f,expl_1,attr);
    case (DAE.ARRAY(ty = t,scalar = b,array = expl))
      equation
        expl_1 = List.map(expl, toModelicaFormExp);
      then
        DAE.ARRAY(t,b,expl_1);
    case (DAE.TUPLE(PR = expl))
      equation
        expl_1 = List.map(expl, toModelicaFormExp);
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

    case (_,_) then Util.getOption(avlTreeGet(functions, path));
    case (_,_)
      equation
        msg = stringDelimitList(List.mapMap(getFunctionList(functions), functionName, Absyn.pathString), "\n  ");
        msg = "DAEUtil.getNamedFunction failed: " +& Absyn.pathString(path) +& "\nThe following functions were part of the cache:\n  ";
        // Error.addMessage(Error.INTERNAL_ERROR,{msg});
        Debug.fprintln(Flags.FAILTRACE, msg);
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getNamedFunctionFromList "Is slow; PartFn.mo should be rewritten using the FunctionTree"
  input Absyn.Path ipath;
  input list<DAE.Function> ifns;
  output DAE.Function fn;
algorithm
  fn := matchcontinue (ipath,ifns)
    local Absyn.Path path; list<DAE.Function> fns;
    case (path,fn::fns)
      equation
        true = Absyn.pathEqual(functionName(fn),path);
      then fn;
    case (path,fn::fns) then getNamedFunctionFromList(path, fns);
    case (path,{})
      equation
        Debug.fprintln(Flags.FAILTRACE, "- DAEUtil.getNamedFunctionFromList failed " +& Absyn.pathString(path));
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
  elsList := List.map(elements, getFunctionElements);
  els := List.flatten(elsList);
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

protected function crefToExp "
  Makes an expression from a ComponentRef.
"
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp:= Expression.makeCrefExp(inComponentRef,DAE.T_UNKNOWN_DEFAULT);
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
  input list<DAE.ComponentRef> inAcc;
  input DAE.ElementSource source "the element origin";
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs := match(inExps,inAcc,source)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> acc;
      list<DAE.Exp> exps;

    case ({},acc,_) then acc;
    case (e::exps,acc,_)
      equation
        acc = verifyWhenEquationStatements({DAE.EQUATION(e,e,source)},acc);
      then verifyWhenEquationStatements2(exps,acc,source);
  end match;
end verifyWhenEquationStatements2;

protected function verifyWhenEquationStatements "
Author BZ, 2008-09
Helper function for verifyWhenEquation
TODO: add some error reporting for this."
  input list<DAE.Element> inElems;
  input list<DAE.ComponentRef> inAcc;
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs:= match (inElems,inAcc)
    local
      String msg;
      list<DAE.Exp> exps,exps1;
      DAE.Exp exp,ee1,ee2;
      DAE.ComponentRef cref;
      DAE.Element el;
      list<DAE.Element> eqsfalseb,rest;
      list<list<DAE.Element>> eqstrueb;
      list<DAE.ComponentRef> crefs1,crefs2,acc;
      DAE.ElementSource source "the element origin";
      list<list<DAE.ComponentRef>> crefslist;
      Boolean b;
      Absyn.Info info;

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

    case(DAE.ARRAY_EQUATION(exp = DAE.CREF(cref, _))::rest,acc)
      then verifyWhenEquationStatements(rest,cref::acc);

    case(DAE.EQUEQUATION(cr1=cref,cr2=_)::rest,acc)
      then verifyWhenEquationStatements(rest,cref::acc);

    case(DAE.IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb,source = source)::rest,acc)
      equation
        crefslist = List.map1(eqstrueb,verifyWhenEquationStatements,{});
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
        info = getElementSourceFileInfo(getElementSource(el));
        Error.addSourceMessage(Error.INTERNAL_ERROR,{msg}, info);
      then
        fail();
  end match;
end verifyWhenEquationStatements;

protected function compareCrefList ""
  input list<list<DAE.ComponentRef>> inCrefs;
  output list<DAE.ComponentRef> outrefs;
  output Boolean matching;
algorithm (outrefs,matching) := matchcontinue(inCrefs)
  local
    list<DAE.ComponentRef> crefs,recRefs;
    Integer i;
    Boolean b1,b2,b3;
    list<list<DAE.ComponentRef>> llrefs;

  case({}) then ({},true);
  case(crefs::{}) then (crefs,true);
  case(crefs::llrefs) // this case will allways have revRefs >=1 unless we are supposed to have 0
    equation
      (recRefs,b3) = compareCrefList(llrefs);
      i = listLength(recRefs);
      b1 = (0 == intMod(listLength(crefs),listLength(recRefs)));
      crefs = List.unionOnTrueList({recRefs,crefs},ComponentReference.crefEqual);
      b2 = intEq(listLength(crefs),i);
      b1 = boolAnd(b1,boolAnd(b2,b3));
    then
      (crefs,b1);
  end matchcontinue;
end compareCrefList;

public function evaluateAnnotation "lochel: This is not used. 
  evaluates the annotation Evaluate"
  input Env.Cache inCache;
  input list<Env.Frame> env;
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm
  (outDAElist) := matchcontinue (inCache,env,inDAElist)
    local
      DAE.DAElist dae;
      HashTable2.HashTable ht,pv,ht1;
      list<DAE.Element> elts,elts1,elts2;
      Env.Cache cache;
    case (_,_,dae as DAE.DAE(elts))
      equation
        pv = getParameterVars(dae,HashTable2.emptyHashTable());
        (ht,true) = evaluateAnnotation1(dae,pv,HashTable2.emptyHashTable());
        (elts1,ht1,cache) = evaluateAnnotation2_loop(inCache,env,dae,ht,BaseHashTable.hashTableCurrentSize(ht));
        (elts2,(_,_,_)) = traverseDAE2(elts, evaluateAnnotationVisitor, (ht1,0,0));
      then
        DAE.DAE(elts2);
    case (_,_,dae) then dae;
  end matchcontinue;
end evaluateAnnotation;

protected function evaluateAnnotationVisitor "author: Frenkel TUD, 2010-12
  helper of evaluateAnnotation"
  input tuple<DAE.Exp,tuple<HashTable2.HashTable,Integer,Integer>> itpl;
  output tuple<DAE.Exp,tuple<HashTable2.HashTable,Integer,Integer>> otpl;
algorithm
  otpl := match itpl
    local
      DAE.Exp exp;
      tuple<HashTable2.HashTable,Integer,Integer> extra_arg;
    case ((exp,extra_arg)) then Expression.traverseExp(exp,evaluateAnnotationTraverse,extra_arg);
  end match;
end evaluateAnnotationVisitor;

protected function evaluateAnnotationTraverse "author: Frenkel TUD, 2010-12"
  input tuple<DAE.Exp, tuple<HashTable2.HashTable,Integer,Integer>> itpl;
  output tuple<DAE.Exp, tuple<HashTable2.HashTable,Integer,Integer>> otpl;
algorithm
  otpl := matchcontinue (itpl)
    local
      DAE.ComponentRef cr;
      HashTable2.HashTable ht;
      DAE.Exp exp,e1;
      Integer i,j,k;
      list<DAE.Var> varLst;

    // Special Case for Records
    case ((exp as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))),(ht,i,j)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((exp,(NONE(),false)));
        ((e1,(ht,i,k))) = Expression.traverseExp(e1,evaluateAnnotationTraverse,(ht,i,j));
        true = intGt(k,j);
      then
        ((e1,(ht,i,k)));
    // Special Case for Arrays
    case ((exp as DAE.CREF(ty = DAE.T_ARRAY(ty=_)),(ht,i,j)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((exp,(NONE(),false)));
        ((e1,(ht,i,k))) = Expression.traverseExp(e1,evaluateAnnotationTraverse,(ht,i,j));
        true = intGt(k,j);
      then
        ((e1,(ht,i,k)));

    case((exp as DAE.CREF(componentRef = _),(ht,i,j)))
      equation
        e1 = replaceCrefInAnnotation(exp, ht);
        true = Expression.isConst(e1);
      then
        ((e1,(ht,i,j+1)));

    case((exp as DAE.CREF(componentRef = _),(ht,i,j)))
      then ((exp,(ht,i+1,j)));

    else itpl;
  end matchcontinue;
end evaluateAnnotationTraverse;

protected function replaceCrefInAnnotation "
  helper of evaluateAnnotationTraverse"
  input DAE.Exp inExp;
  input HashTable2.HashTable inTable;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inTable)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp;

    case (DAE.CREF(componentRef = cr), _)
      equation
        exp = BaseHashTable.get(cr, inTable);
      then
        replaceCrefInAnnotation(exp, inTable);

    else inExp;
  end matchcontinue;
end replaceCrefInAnnotation;

public function getParameterVars
  input DAE.DAElist dae;
  input HashTable2.HashTable ht;
  output HashTable2.HashTable oht;
protected
  list<DAE.Element> elts;
algorithm
  DAE.DAE(elts) := dae;
  oht := List.fold(elts,getParameterVars2,ht);
end getParameterVars;

protected function getParameterVars2
  input DAE.Element elt;
  input HashTable2.HashTable ht;
  output HashTable2.HashTable ouHt;
algorithm
  (ouHt) := matchcontinue (elt,ht)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      Option<DAE.VariableAttributes> dae_var_attr;
      list<DAE.Element> elts;

    case (DAE.COMP(dAElist = elts),_) then List.fold(elts,getParameterVars2,ht);

    case (DAE.VAR(componentRef = cr,kind=DAE.PARAM(),binding=SOME(e)),_)
      then BaseHashTable.add((cr,e),ht);

    case (DAE.VAR(componentRef = cr,kind=DAE.PARAM(),variableAttributesOption=dae_var_attr),_)
      equation
        e = getStartAttrFail(dae_var_attr);
      then BaseHashTable.add((cr,e),ht);

    else ht;
  end matchcontinue;
end getParameterVars2;

public function evaluateAnnotation1
"evaluates the annotation Evaluate"
  input DAE.DAElist dae;
  input HashTable2.HashTable pv;
  input HashTable2.HashTable ht;
  output HashTable2.HashTable oht;
  output Boolean hasEvaluate;
protected
  list<DAE.Element> elts;
algorithm
  DAE.DAE(elts) := dae;
  ((oht,hasEvaluate)) := List.fold1r(elts,evaluateAnnotation1Fold,pv,(ht,false));
end evaluateAnnotation1;

protected function evaluateAnnotation1Fold
"evaluates the annotation Evaluate"
  input tuple<HashTable2.HashTable,Boolean> tpl;
  input DAE.Element el;
  input HashTable2.HashTable inPV;
  output tuple<HashTable2.HashTable,Boolean> otpl;
algorithm
  otpl := matchcontinue (tpl,el,inPV)
    local
      list<DAE.Element> rest,sublist;
      SCode.Comment comment;
      HashTable2.HashTable ht,ht1,ht2,pv;
      DAE.ComponentRef cr;
      SCode.Annotation anno;
      list<SCode.Annotation> annos;
      DAE.Exp e,e1;
      Boolean b,b1;
    case (_,DAE.COMP(dAElist = sublist),pv)
      then List.fold1r(sublist,evaluateAnnotation1Fold,pv,tpl);
    case ((ht,_),DAE.VAR(componentRef = cr,kind=DAE.PARAM(),binding=SOME(e),absynCommentOption=SOME(comment)),pv)
      equation
        SCode.COMMENT(annotation_=SOME(anno)) = comment;
        true = SCode.hasBooleanNamedAnnotation({anno},"Evaluate");
        e1 = evaluateParameter(e,pv);
        ht1 = BaseHashTable.add((cr,e1),ht);
      then
        ((ht1,true));
    else tpl;
  end matchcontinue;
end evaluateAnnotation1Fold;

protected function evaluateParameter
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
        false = Expression.expHasCrefs(e); // {} = Expression.extractCrefsFromExp(e);
      then e;
    case (e,pv)
      equation
        ((e1,(_,i,_))) = Expression.traverseExp(e,evaluateAnnotationTraverse,(pv,0,0));
        true = intEq(i,0);
        e2 = evaluateParameter(e1,pv);
      then
        e2;
  end matchcontinue;
end evaluateParameter;

protected function evaluateAnnotation2_loop
  input Env.Cache cache;
  input list<Env.Frame> env;
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  input Integer sizeBefore;
  output list<DAE.Element> outDAElist;
  output HashTable2.HashTable outHt;
  output Env.Cache outCache;
protected
  Integer newsize;
algorithm
  (outDAElist,outHt,outCache) := evaluateAnnotation2(cache,env,inDAElist,inHt);
  newsize := BaseHashTable.hashTableCurrentSize(outHt);
  (outDAElist,outHt,outCache) := evaluateAnnotation2_loop1(intEq(newsize,sizeBefore),outCache,env,DAE.DAE(outDAElist),outHt,newsize);
end evaluateAnnotation2_loop;

protected function evaluateAnnotation2_loop1
  input Boolean finish;
  input Env.Cache inCache;
  input list<Env.Frame> env;
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  input Integer sizeBefore;
  output list<DAE.Element> outDAElist;
  output HashTable2.HashTable outHt;
  output Env.Cache outCache;
algorithm
  (outDAElist,outHt,outCache) := match (finish,inCache,env,inDAElist,inHt,sizeBefore)
    local
      HashTable2.HashTable ht;
      list<DAE.Element> elst;
      Env.Cache cache;
    case(true,_,_,DAE.DAE(elst),_,_) then (elst,inHt,inCache);
    else
      equation
        (elst,ht,cache) = evaluateAnnotation2_loop(inCache,env,inDAElist,inHt,sizeBefore);
      then
        (elst,ht,cache);
  end match;
end evaluateAnnotation2_loop1;

protected function evaluateAnnotation2
"evaluates the parameters with bindings parameters with annotation Evaluate"
  input Env.Cache inCache;
  input list<Env.Frame> env;
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  output list<DAE.Element> outDAElist;
  output HashTable2.HashTable outHt;
  output Env.Cache outCache;
algorithm
  (outDAElist,outHt,outCache) := matchcontinue (inCache,env,inDAElist,inHt)
    local
      list<DAE.Element> elementLst,elementLst1;
      HashTable2.HashTable ht,ht1;
      Env.Cache cache;
    case (_,_,DAE.DAE({}),ht) then ({},ht,inCache);
    case (_,_,DAE.DAE(elementLst=elementLst),ht)
      equation
        (elementLst1,(ht1,cache,_)) = List.mapFold(elementLst,evaluateAnnotation3,(ht,inCache,env));
      then
        (elementLst1,ht1,cache);
  end matchcontinue;
end evaluateAnnotation2;

protected function evaluateAnnotation3
"evaluates the parameters with bindings parameters with annotation Evaluate"
  input DAE.Element iel;
  input tuple<HashTable2.HashTable,Env.Cache,list<Env.Frame>> inHt;
  output DAE.Element oel;
  output tuple<HashTable2.HashTable,Env.Cache,list<Env.Frame>> outHt;
algorithm
  (oel,outHt) := matchcontinue (iel,inHt)
    local
      tuple<HashTable2.HashTable,Env.Cache,list<Env.Frame>> httpl;
      Env.Cache cache;
      list<Env.Frame> env;
      list<DAE.Element> rest,sublist,sublist1,newlst;
      HashTable2.HashTable ht,ht1,ht2;
      DAE.ComponentRef cr;
      SCode.Annotation anno;
      list<SCode.Annotation> annos;
      DAE.Exp e,e1,e2;
      DAE.Ident ident;
      DAE.ElementSource source;
      Option<SCode.Comment> comment;
      DAE.VarKind kind,kind1;
      DAE.VarDirection direction;
      DAE.VarParallelism parallelism;
      DAE.VarVisibility protection;
      DAE.Type ty;
      Option<DAE.Exp> binding;
      DAE.InstDims  dims;
      DAE.ConnectorType ct;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      Integer i,j;

    case (DAE.COMP(ident=ident,dAElist = sublist,source=source,comment=comment),_)
      equation
        (sublist1,httpl) = List.mapFold(sublist,evaluateAnnotation3,inHt);
      then
        (DAE.COMP(ident,sublist1,source,comment),httpl);
    case (DAE.VAR(componentRef = cr,kind=DAE.PARAM(),direction=direction,parallelism=parallelism,
                  protection=protection,ty=ty,binding=SOME(e),dims=dims,connectorType=ct,
                  source=source,variableAttributesOption=variableAttributesOption,
                  absynCommentOption=absynCommentOption,innerOuter=innerOuter),(ht,cache,env))
      equation
        ((e1,(_,i,j))) = Expression.traverseExp(e,evaluateAnnotationTraverse,(ht,0,0));
        (e2,ht1,cache) = evaluateAnnotation4(cache,env,cr,e1,i,j,ht);
      then
        (DAE.VAR(cr,DAE.PARAM(),direction,parallelism,protection,ty,SOME(e2),dims,ct,
            source,variableAttributesOption,absynCommentOption,innerOuter),(ht1,cache,env));
    else (iel,inHt);
  end matchcontinue;
end evaluateAnnotation3;

protected function evaluateAnnotation4
"evaluates the parameters with bindings parameters with annotation Evaluate"
  input Env.Cache inCache;
  input list<Env.Frame> env;
  input DAE.ComponentRef inCr;
  input DAE.Exp inExp;
  input Integer inInteger1;
  input Integer inInteger2;
  input HashTable2.HashTable inHt;
  output DAE.Exp outExp;
  output HashTable2.HashTable outHt;
  output Env.Cache outCache;
algorithm
  (outExp,outHt,outCache) := matchcontinue (inCache,env,inCr,inExp,inInteger1,inInteger2,inHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Integer i,j;
      HashTable2.HashTable ht,ht1;
      Env.Cache cache;
      Values.Value value;
    case (_,_,cr,e,i,j,ht)
      equation
        // there is a paramter with evaluate=true
        true = intGt(j,0);
        // there are no other crefs
        true = intEq(i,0);
        // evalute expression
        ((e1,(ht,_,_))) = Expression.traverseExp(e,evaluateAnnotationTraverse,(ht,0,0));
        (cache, value,_) = Ceval.ceval(inCache, env, e1, false,NONE(),Absyn.NO_MSG(),0);
         e1 = ValuesUtil.valueExp(value);
        // e1 = e;
        ht1 = BaseHashTable.add((cr,e1),ht);
      then (e1,ht1,cache);
    case (_,_,_,e,_,_,ht) then (e,ht,inCache);
  end matchcontinue;
end evaluateAnnotation4;

public function renameTimeToDollarTime "author: BZ, 2009-1
  rename the keyword time to globalData->timeValue, this is a special case for functions since they do not get translated in to c_crefs."
  input list<DAE.Element> dae;
  output list<DAE.Element> odae;
algorithm
  (odae,_) := traverseDAE2(dae, renameTimeToDollarTimeVisitor, 0);
end renameTimeToDollarTime;

protected function renameTimeToDollarTimeVisitor "author: BZ, 2009-01
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

protected function renameTimeToDollarTimeFromCref "author: BZ, 2008-12
  Function for Expression.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local
      DAE.ComponentRef cr,cr2,cref_;
      DAE.Type cty,ty;
      Integer oarg;
      list<DAE.Subscript> subs;
      DAE.Exp exp;

    case((DAE.CREF(DAE.CREF_IDENT("time",cty,subs),ty),oarg))
      equation
        cref_ = ComponentReference.makeCrefIdent("globalData->timeValue",cty,subs);
        exp = Expression.makeCrefExp(cref_,ty);
      then
        ((exp,oarg));

    else inTplExpExpString;

  end matchcontinue;
end renameTimeToDollarTimeFromCref;


public function renameUniqueOuterVars "author: BZ, 2008-12
  Rename innerouter(the inner part of innerouter) variables that have been renamed to a.b.$unique$var
  Just remove the $unique$ from the var name.
  This function traverses the entire dae."
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm
  (odae,_,_) := traverseDAE(dae, DAE.emptyFuncTree, renameUniqueVisitor, 0);
end renameUniqueOuterVars;

protected function renameUniqueVisitor "author: BZ, 2008-12
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

protected function removeUniqieIdentifierFromCref "author: BZ, 2008-12
  Function for Expression.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local
      DAE.ComponentRef cr,cr2; DAE.Type ty; Integer oarg; DAE.Exp exp;

    case((DAE.CREF(cr,ty),oarg))
      equation
        cr2 = unNameInnerouterUniqueCref(cr,DAE.UNIQUEIO);
        exp = Expression.makeCrefExp(cr2,ty);
      then
        ((exp,oarg));

    else inTplExpExpString;

  end matchcontinue;
end removeUniqieIdentifierFromCref;

public function nameUniqueOuterVars "author: BZ, 2008-12
  Rename all variables to the form a.b.$unique$var, call
  This function traverses the entire dae."
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm
  (odae,_,_) := traverseDAE(dae, DAE.emptyFuncTree, nameUniqueVisitor, 0);
end nameUniqueOuterVars;

protected function nameUniqueVisitor "author: BZ, 2008-12
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

protected function addUniqueIdentifierToCref "author: BZ, 2008-12
  Function for Expression.traverseExp, adds the constant 'UNIQUEIO' to the CREF_IDENT() part of the cref."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local
      DAE.ComponentRef cr,cr2; DAE.Type ty; Integer oarg; DAE.Exp exp;

    case((DAE.CREF(cr,ty),oarg))
      equation
        cr2 = nameInnerouterUniqueCref(cr);
        exp = Expression.makeCrefExp(cr2,ty);
      then
        ((exp,oarg));

    case _ then inTplExpExpString;

  end matchcontinue;
end addUniqueIdentifierToCref;

// helper functions for traverseDAE
protected function traverseDAEOptExp "author: BZ, 2008-12
  Traverse an optional expression, helper function for traverseDAE"
  input Option<DAE.Exp> oexp;
  input FuncExpType func;
  input Type_a iextraArg;
  output Option<DAE.Exp> ooexp;
  output Type_a oextraArg;
  partial function FuncExpType
    input tuple<DAE.Exp,Type_a> arg;
    output tuple<DAE.Exp,Type_a> oarg;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (ooexp,oextraArg) := match(oexp,func,iextraArg)
    local
      DAE.Exp e;
      Type_a extraArg;

    case(NONE(),_,extraArg) then (NONE(),extraArg);

    case(SOME(e),_,extraArg)
      equation
        ((e,extraArg)) = func((e,extraArg));
      then
        (SOME(e),extraArg);
  end match;
end traverseDAEOptExp;

protected function traverseDAEExpList "author: BZ, 2008-12
  Traverse an list of expressions, helper function for traverseDAE"
  input list<DAE.Exp> iexps;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<DAE.Exp> oexps;
  output Type_a oextraArg;
  partial function FuncExpType
    input tuple<DAE.Exp,Type_a> arg;
    output tuple<DAE.Exp,Type_a> oarg;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (oexps,oextraArg) := match(iexps,func,iextraArg)
    local
      DAE.Exp e;
      Type_a extraArg;
      list<DAE.Exp> exps;

    case({},_,extraArg) then ({},extraArg);

    case(e::exps,_,extraArg)
      equation
        ((e,extraArg)) = func((e,extraArg));
        (oexps,extraArg) = traverseDAEExpList(exps,func,extraArg);
      then
        (e::oexps,extraArg);
  end match;
end traverseDAEExpList;

protected function traverseDAEList "author: BZ, 2008-12
  Helper function for traverseDAE, traverses a list of dae element list."
  input list<list<DAE.Element>> idaeList;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<list<DAE.Element>> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType
    input tuple<DAE.Exp,Type_a> arg;
    output tuple<DAE.Exp,Type_a> oarg;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := match(idaeList,func,iextraArg)
    local
      list<DAE.Element> branch,branch2;
      list<list<DAE.Element>> recRes,daeList;
      Type_a extraArg;

    case({},_,extraArg) then ({},extraArg);

    case(branch::daeList,_,extraArg)
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
      list<tuple<DAE.AvlKey,DAE.AvlValue>> lst, lstInvalid;
      String str;

    case _
      equation
        lst = avlTreeToList(ft);
      then
        List.mapMap(lst, Util.tuple22, Util.getOption);
    case _
      equation
        lst = avlTreeToList(ft);
        lstInvalid = List.select(lst, isInvalidFunctionEntry);
        str = stringDelimitList(List.map(List.map(lstInvalid, Util.tuple21), Absyn.pathString), ", ");
        Error.addMessage(Error.NON_INSTANTIATED_FUNCTION, {str});
      then
        fail();
  end matchcontinue;
end getFunctionList;

public function getFunctionNames
  input DAE.FunctionTree ft;
  output list<String> strs;
algorithm
  strs := List.mapMap(getFunctionList(ft), functionName, Absyn.pathString);
end getFunctionNames;

protected function isInvalidFunctionEntry
  input tuple<DAE.AvlKey,DAE.AvlValue> tpl;
  output Boolean b;
algorithm
  b := matchcontinue tpl
    case ((_,NONE())) then true;
    case ((_,_)) then false;
  end matchcontinue;
end isInvalidFunctionEntry;

protected function isValidFunctionEntry
  input tuple<DAE.AvlKey,DAE.AvlValue> tpl;
  output Boolean b;
algorithm
  b := not isInvalidFunctionEntry(tpl);
end isValidFunctionEntry;

public function traverseDAE "
  This function traverses all dae exps.
  NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
  input FuncExpType func;
  input Type_a iextraArg;
  output DAE.DAElist traversedDae;
  output DAE.FunctionTree outTree;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDae,outTree,oextraArg) := match(dae,functionTree,func,iextraArg)
  local
    list<DAE.Element> elts;
     list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
     DAE.FunctionTree funcs;
     Type_a extraArg;

  case(DAE.DAE(elts),funcs,_,extraArg) equation
     (elts,extraArg) = traverseDAE2(elts,func,extraArg);
     (funcLst,extraArg) = traverseDAEFuncLst(avlTreeToList(funcs),func,extraArg);
     funcs = avlTreeAddLst(funcLst,avlTreeNew());
  then (DAE.DAE(elts),funcs,extraArg);
  end match;
end traverseDAE;

public function traverseDAEFuncLst "help function to traverseDae. Traverses the functions "
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> ifuncLst;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<tuple<DAE.AvlKey,DAE.AvlValue>> outFuncLst;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;

algorithm
  (outFuncLst,oextraArg) := match(ifuncLst,func,iextraArg)
    local
      Absyn.Path p;
      DAE.Function daeFunc;
      Type_a extraArg;
      list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;

    case({},_,extraArg) then ({},extraArg);
    case((p,SOME(daeFunc))::funcLst,_,extraArg)
      equation
        (daeFunc,extraArg) = traverseDAEFunc(daeFunc,func,extraArg);
        (funcLst,extraArg) = traverseDAEFuncLst(funcLst,func,extraArg);
      then ((p,SOME(daeFunc))::funcLst,extraArg);
    case((p,NONE())::_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- DAEUtil.traverseDAEFuncLst failed: " +& Absyn.pathString(p));
      then fail();
  end match;
end traverseDAEFuncLst;

public function traverseDAEFunctions "
  Traverses the functions.
  Note: Only calls the top-most expressions If you need to also traverse the
  expression, use an extra helper function."
  input list<DAE.Function> ifuncLst;
  input FuncExpType func;
  input Type_a iextraArg;
  input list<DAE.Function> acc;
  output list<DAE.Function> outFuncLst;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outFuncLst,oextraArg) := match(ifuncLst,func,iextraArg,acc)
    local
      DAE.Function daeFunc;
      list<DAE.Function> funcLst;
      Type_a extraArg;

    case({},_,extraArg,_) then (listReverse(acc),extraArg);
    case(daeFunc::funcLst,_,extraArg,_)
      equation
        (daeFunc,extraArg) = traverseDAEFunc(daeFunc,func,extraArg);
        (funcLst,extraArg) = traverseDAEFunctions(funcLst,func,extraArg,daeFunc::acc);
      then (funcLst,extraArg);
  end match;
end traverseDAEFunctions;

protected function traverseDAEFunc
  input DAE.Function daeFn;
  input FuncExpType func;
  input Type_a iextraArg;
  output DAE.Function traversedFn;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedFn,oextraArg) := match (daeFn,func,iextraArg)
    local
      list<DAE.Element> elist,elist2;
      DAE.Type ftp,tp;
      Boolean partialPrefix, isImpure;
      Absyn.Path path;
      DAE.ExternalDecl extDecl;
      list<DAE.FunctionDefinition> derFuncs;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;
      Type_a extraArg;

    case(DAE.FUNCTION(path,(DAE.FUNCTION_DEF(body = elist)::derFuncs),ftp,partialPrefix,isImpure,inlineType,source,cmt),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      then (DAE.FUNCTION(path,DAE.FUNCTION_DEF(elist2)::derFuncs,ftp,partialPrefix,isImpure,inlineType,source,cmt),extraArg);

    case(DAE.FUNCTION(path,(DAE.FUNCTION_EXT(body = elist,externalDecl=extDecl)::derFuncs),ftp,partialPrefix,isImpure,inlineType,source,cmt),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      then (DAE.FUNCTION(path,DAE.FUNCTION_EXT(elist2,extDecl)::derFuncs,ftp,partialPrefix,isImpure,DAE.NO_INLINE(),source,cmt),extraArg);

    case(DAE.RECORD_CONSTRUCTOR(path,tp,source),_,extraArg)
      then (DAE.RECORD_CONSTRUCTOR(path,tp,source),extraArg);
  end match;
end traverseDAEFunc;


public function traverseDAE2 "author: BZ, 2008-12, adrpo, 2010-12
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

protected function traverseDAE2_tail "author: adrpo, 2010-12
  This function is a tail recursive function that traverses all dae exps.
  NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input list<DAE.Element> daeList;
  input FuncExpType func;
  input Type_a iextraArg;
  input list<DAE.Element> iaccumulator;
  output list<DAE.Element> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := match (daeList,func,iextraArg,iaccumulator)
    local
      list<DAE.Element> dae,dae2,accumulator;
      DAE.Element elt;
      Type_a extraArg;

    case({},_,extraArg,accumulator)
      equation
        accumulator = listReverse(accumulator);
      then
        (accumulator,extraArg);

    case(elt::dae,_,extraArg,accumulator)
      equation
        (elt,extraArg) = traverseDAE2_tail2(elt,func,extraArg);
        (dae2,extraArg) = traverseDAE2_tail(dae,func,extraArg,elt::accumulator);
      then
        (dae2,extraArg);
  end match;
end traverseDAE2_tail;

protected function traverseDAE2_tail2 "author: adrpo, 2010-12
  This function is a tail recursive function that traverses all dae exps.
  NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input DAE.Element ielt;
  input FuncExpType func;
  input Type_a iextraArg;
  output DAE.Element outElt;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outElt,oextraArg) := match (ielt,func,iextraArg)
    local
      DAE.ComponentRef cr,cr2,cr1,cr1_2;
      list<DAE.Element> elist,elist2,elist22;
      DAE.Element elt2,elt;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.InstDims dims;
      DAE.ConnectorType ct;
      DAE.VarParallelism prl;
      DAE.VarVisibility prot;
      DAE.Exp e,e2,e22,e1,e11,maybeCrExp,e3,e32;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      Option<DAE.Exp> optExp;
      Absyn.InnerOuter io;
      DAE.Dimensions idims;
      String id,str;
      list<DAE.Statement> stmts,stmts2;
      list<list<DAE.Element>> tbs,tbs_1;
      list<DAE.Exp> conds,conds_1, exps, exps_1;
      Absyn.Path path;
      list<DAE.Exp> expl;
      DAE.ElementSource source "the origin of the element";
      Type_a extraArg;
      Absyn.Info info;

    case(DAE.VAR(cr,kind,dir,prl,prot,tp,optExp,dims,ct,source,attr,cmt,io),_,extraArg)
      equation
        ((maybeCrExp,extraArg)) = func((Expression.crefExp(cr), extraArg));
        // If the result is DAE.CREF, we replace the name of the variable.
        // Otherwise, we only use the extraArg
        cr2 = Util.makeValueOrDefault(Expression.expCref,maybeCrExp,cr);
        (optExp,extraArg) = traverseDAEOptExp(optExp,func,extraArg);
        (attr,extraArg) = traverseDAEVarAttr(attr,func,extraArg);
        elt = DAE.VAR(cr2,kind,dir,prl,prot,tp,optExp,dims,ct,source,attr,cmt,io);
      then
        (elt,extraArg);

    case(DAE.DEFINE(cr,e,source),_,extraArg)
      equation
        ((e2,extraArg)) = func((e, extraArg));
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr), extraArg));
        elt = DAE.DEFINE(cr2,e2,source);
      then
        (elt,extraArg);

    case(DAE.INITIALDEFINE(cr,e,source),_,extraArg)
      equation
        ((e2,extraArg)) = func((e, extraArg));
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr), extraArg));
        elt = DAE.INITIALDEFINE(cr2,e2,source);
      then
        (elt,extraArg);

    case(DAE.EQUEQUATION(cr,cr1,source),_,extraArg)
      equation
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr), extraArg));
        ((DAE.CREF(cr1_2,_),extraArg)) = func((Expression.crefExp(cr1), extraArg));
        elt = DAE.EQUEQUATION(cr2,cr1_2,source);
      then
        (elt,extraArg);

    case(DAE.EQUATION(e1,e2,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.EQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.COMPLEX_EQUATION(e1,e2,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.COMPLEX_EQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.ARRAY_EQUATION(idims,e1,e2,source),_,extraArg)
      equation
        ((e11, extraArg)) = func((e1, extraArg));
        ((e22, extraArg)) = func((e2, extraArg));
        elt = DAE.ARRAY_EQUATION(idims,e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.INITIAL_ARRAY_EQUATION(idims,e1,e2,source),_,extraArg)
      equation
        ((e11, extraArg)) = func((e1, extraArg));
        ((e22, extraArg)) = func((e2, extraArg));
        elt = DAE.INITIAL_ARRAY_EQUATION(idims,e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.WHEN_EQUATION(e1,elist,SOME(elt),source),_,extraArg)
      equation
        ((e11, extraArg)) = func((e1, extraArg));
        ({elt2}, extraArg)= traverseDAE2_tail({elt},func,extraArg,{});
        (elist2, extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.WHEN_EQUATION(e11,elist2,SOME(elt2),source);
      then
        (elt,extraArg);

    case(DAE.WHEN_EQUATION(e1,elist,NONE(),source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.WHEN_EQUATION(e11,elist2,NONE(),source);
      then
        (elt,extraArg);

    case(DAE.INITIALEQUATION(e1,e2,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.INITIALEQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1, extraArg));
        ((e22,extraArg)) = func((e2, extraArg));
        elt = DAE.INITIAL_COMPLEX_EQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.COMP(id,elist,source,cmt),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.COMP(id,elist2,source,cmt);
      then
        (elt,extraArg);

    case(elt as DAE.EXTOBJECTCLASS(path,source),_,extraArg)
      then (elt,extraArg);

    case(DAE.ASSERT(e1,e2,e3,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1,extraArg));
        ((e22,extraArg)) = func((e2,extraArg));
        ((e32,extraArg)) = func((e3,extraArg));
        elt = DAE.ASSERT(e11,e22,e32,source);
      then
        (elt,extraArg);

    case(DAE.TERMINATE(e1,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1,extraArg));
        elt = DAE.TERMINATE(e11,source);
      then
        (elt,extraArg);

    case(DAE.NORETCALL(path,expl,source),_,extraArg)
      equation
        (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
        elt = DAE.NORETCALL(path,expl,source);
      then
        (elt,extraArg);

    case(DAE.REINIT(cr,e1,source),_,extraArg)
      equation
        ((e11,extraArg)) = func((e1,extraArg));
        ((DAE.CREF(cr2,_),extraArg)) = func((Expression.crefExp(cr),extraArg));
        elt = DAE.REINIT(cr2,e11,source);
      then
        (elt,extraArg);

    case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source),_,extraArg)
      equation
        (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        elt = DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source);
      then
        (elt,extraArg);

    case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts),source),_,extraArg)
      equation
        (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
        elt = DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source);
      then
        (elt,extraArg);

    case(DAE.CONSTRAINT(DAE.CONSTRAINT_EXPS(exps),source),_,extraArg)
      equation
        (exps_1,extraArg) = traverseDAEExpList(exps,func,extraArg);
        elt = DAE.CONSTRAINT(DAE.CONSTRAINT_EXPS(exps_1),source);
      then
        (elt,extraArg);

    case(elt as DAE.CLASS_ATTRIBUTES(_),_,extraArg)
      then
        (elt,extraArg);

    case(DAE.IF_EQUATION(conds,tbs,elist2,source),_,extraArg)
      equation
        (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
        (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
        (elist22,extraArg) = traverseDAE2_tail(elist2,func,extraArg,{});
        elt = DAE.IF_EQUATION(conds_1,tbs_1,elist22,source);
      then
        (elt,extraArg);

    case(DAE.INITIAL_IF_EQUATION(conds,tbs,elist2,source),_,extraArg)
      equation
        (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
        (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
        (elist22,extraArg) = traverseDAE2_tail(elist2,func,extraArg,{});
        elt = DAE.INITIAL_IF_EQUATION(conds_1,tbs_1,elist22,source);
      then
        (elt,extraArg);

    // Empty function call - stefan
    case(DAE.NORETCALL(source = source),_,extraArg)
      equation
        info = getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,
          {"Empty function call in equations",
           "Move the function calls to appropriate algorithm section"}, info);
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

protected uniontype TraverseStatementsOptions
  record TRAVERSE_ALL
  end TRAVERSE_ALL;
  record TRAVERSE_RHS_ONLY
  end TRAVERSE_RHS_ONLY;
end TraverseStatementsOptions;

public function traverseDAEEquationsStmts "Traversing of DAE.Statement."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := traverseDAEEquationsStmtsList(inStmts,func,TRAVERSE_ALL(),iextraArg);
end traverseDAEEquationsStmts;

public function traverseDAEEquationsStmtsRhsOnly "Traversing of DAE.Statement. Only rhs expressions are replaced, keeping lhs intact."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := traverseDAEEquationsStmtsList(inStmts,func,TRAVERSE_RHS_ONLY(),iextraArg);
end traverseDAEEquationsStmtsRhsOnly;

protected function traverseDAEEquationsStmtsList "Traversing of DAE.Statement."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input TraverseStatementsOptions opt;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
protected
  list<list<DAE.Statement>> outStmtsLst;
algorithm
  (outStmtsLst,oextraArg) := List.map2Fold(inStmts,traverseDAEEquationsStmtsWork,func,opt,iextraArg);
  outStmts := List.flatten(outStmtsLst);
end traverseDAEEquationsStmtsList;

protected function traverseStatementsOptionsEvalLhs
  input tuple<DAE.Exp,Type_a> inTpl;
  input FuncExpType func;
  input TraverseStatementsOptions opt;
  output tuple<DAE.Exp,Type_a> outTpl;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  outTpl := match (inTpl,func,opt)
    case (_,_,TRAVERSE_ALL())
      equation
        outTpl = func(inTpl);
      then outTpl;
    else inTpl;
  end match;
end traverseStatementsOptionsEvalLhs;

protected function traverseDAEEquationsStmtsWork "Handles the traversing of DAE.Statement."
  input DAE.Statement inStmts;
  input FuncExpType func;
  input TraverseStatementsOptions opt;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := matchcontinue(inStmts,func,opt,iextraArg)
    local
      DAE.Exp e_1,e_2,e,e2,e3,e_3;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts1,stmts2;
      DAE.Type tp;
      DAE.Statement x,ew,ew_1;
      Boolean b1;
      String id1,str;
      Integer ix;
      DAE.ElementSource source;
      DAE.Else algElse;
      Type_a extraArg;
      list<tuple<DAE.ComponentRef,Absyn.Info>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case (DAE.STMT_ASSIGN(type_ = tp,exp1 = e,exp = e2, source = source),_,_,extraArg)
      equation
        ((e_1,extraArg)) = traverseStatementsOptionsEvalLhs(((e, extraArg)),func,opt);
        ((e_2,extraArg)) = func((e2, extraArg));
      then (DAE.STMT_ASSIGN(tp,e_1,e_2,source)::{},extraArg);

    case (DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((DAE.TUPLE(expl2), extraArg)) = traverseStatementsOptionsEvalLhs(((DAE.TUPLE(expl1), extraArg)),func,opt);
      then (DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source)::{},extraArg);

    case (DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((e_2 as DAE.CREF(cr_1,_), extraArg)) = traverseStatementsOptionsEvalLhs(((Expression.crefExp(cr), extraArg)),func,opt);
      then (DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1,source)::{},extraArg);

    case (DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        failure(((DAE.CREF(_,_), _)) = func((Expression.crefExp(cr), extraArg)));
        /* We need to pass this through because simplify/etc may scalarize the cref...
        true = Flags.isSet(Flags.FAILTRACE);
        print(DAEDump.ppStatementStr(x));
        print("Warning, not allowed to set the componentRef to a expression in DAEUtil.traverseDAEEquationsStmts\n");
        */
      then (DAE.STMT_ASSIGN_ARR(tp,cr,e_1,source)::{},extraArg);

    case (DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source),_,_,extraArg)
      equation
        (algElse,extraArg) = traverseDAEEquationsStmtsElse(algElse,func,opt,extraArg);
        (stmts2,extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        ((e_1,extraArg)) = func((e, extraArg));
        stmts1 = Algorithm.optimizeIf(e_1,stmts2,algElse,source);
      then (stmts1,extraArg);

    case (DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_FOR(tp,b1,id1,ix,e_1,stmts2,source)::{},extraArg);

    case (DAE.STMT_PARFOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, loopPrlVars=loopPrlVars, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_PARFOR(tp,b1,id1,ix,e_1,stmts2,loopPrlVars,source)::{},extraArg);

    case (DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_WHILE(e_1,stmts2,source)::{},extraArg);

    case (DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=NONE(),source=source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,NONE(),source)::{},extraArg);

    case (DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=SOME(ew),source=source),_,_,extraArg)
      equation
        ({ew_1}, extraArg) = traverseDAEEquationsStmtsList({ew},func,opt,extraArg);
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,SOME(ew),source)::{},extraArg);

    case (DAE.STMT_ASSERT(cond = e, msg=e2, level=e3, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((e_2, extraArg)) = func((e2, extraArg));
        ((e_3, extraArg)) = func((e3, extraArg));
      then (DAE.STMT_ASSERT(e_1,e_2,e_3,source)::{},extraArg);

    case (DAE.STMT_TERMINATE(msg = e, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_TERMINATE(e_1,source)::{},extraArg);

    case (DAE.STMT_REINIT(var = e,value=e2, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
        ((e_2, extraArg)) = func((e2, extraArg));
      then (DAE.STMT_REINIT(e_1,e_2,source)::{},extraArg);

    case (DAE.STMT_NORETCALL(exp = e, source = source),_,_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, extraArg));
      then (DAE.STMT_NORETCALL(e_1,source)::{},extraArg);

    case (x as DAE.STMT_RETURN(source = source),_,_,extraArg)
      then (x::{},extraArg);

    case (x as DAE.STMT_BREAK(source = source),_,_,extraArg)
      then (x::{},extraArg);

    // MetaModelica extension. KS
    case (DAE.STMT_FAILURE(body=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
      then (DAE.STMT_FAILURE(stmts2,source)::{},extraArg);

    case (DAE.STMT_TRY(tryBody=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
      then (DAE.STMT_TRY(stmts2,source)::{},extraArg);

    case (DAE.STMT_CATCH(catchBody=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
      then (DAE.STMT_CATCH(stmts2,source)::{},extraArg);

    case (x as DAE.STMT_THROW(source = source),_,_,extraArg)
      then (x::{},extraArg);

    case (x,_,_,extraArg)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "DAEUtil.traverseDAEEquationsStmts not implemented correctly: " +& str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end traverseDAEEquationsStmtsWork;

protected function traverseDAEEquationsStmtsElse "Helper function for traverseDAEEquationsStmts"
  input DAE.Else inElse;
  input FuncExpType func;
  input TraverseStatementsOptions opt;
  input Type_a iextraArg;
  output DAE.Else outElse;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outElse,oextraArg) := match(inElse,func,opt,iextraArg)
  local
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    DAE.Else el,el_1;
    Type_a extraArg;
  case (DAE.NOELSE(),_,_,extraArg) then (DAE.NOELSE(),extraArg);
  case (DAE.ELSEIF(e,st,el),_,_,extraArg)
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,opt,extraArg);
      (st_1,extraArg) = traverseDAEEquationsStmtsList(st,func,opt,extraArg);
      ((e_1,extraArg)) = func((e, extraArg));
    then (Algorithm.optimizeElseIf(e_1,st_1,el_1),extraArg);
  case(DAE.ELSE(st),_,_,extraArg)
    equation
      (st_1,extraArg) = traverseDAEEquationsStmtsList(st,func,opt,extraArg);
    then (DAE.ELSE(st_1),extraArg);
end match;
end traverseDAEEquationsStmtsElse;

public function traverseDAEStmts
 "Author: BZ, 2008-12, wbraun 2012-09
  Traversing statemeant and provide current statement
  to FuncExptype
  Handles the traversing of DAE.Statement."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType
    input tuple<DAE.Exp, DAE.Statement, Type_a> arg;
    output tuple<DAE.Exp, Type_a> oarg;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := matchcontinue(inStmts,func,iextraArg)
    local
      DAE.Exp e_1,e_2,e,e2,e3,e_3;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts1,stmts2;
      DAE.Type tp;
      DAE.Statement x,ew,ew_1;
      Boolean b1;
      String id1,str;
      Integer ix;
      DAE.ElementSource source;
      DAE.Else algElse;
      Type_a extraArg;
      list<tuple<DAE.ComponentRef,Absyn.Info>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case ({},_,extraArg) then ({},extraArg);

    case (((x as DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x, extraArg));
        ((e_2, extraArg)) = func((e2, x, extraArg));
        (xs_1,extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_ASSIGN(tp,e_2,e_1,source)::xs_1,extraArg);

    case (((x as DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x,  extraArg));
        (expl2, extraArg) = traverseDAEExpListStmt(expl1,func, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then ((DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source)::xs_1),extraArg);

    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x,  extraArg));
        ((e_2 as DAE.CREF(cr_1,_), extraArg)) = func((Expression.crefExp(cr),  x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1,source)::xs_1,extraArg);

    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x, extraArg));
        failure(((DAE.CREF(_,_), _)) = func((Expression.crefExp(cr), x, extraArg)));
        // We need to pass this through because simplify/etc may scalarize the cref...
        // true = Flags.isSet(Flags.FAILTRACE);
        // print(DAEDump.ppStatementStr(x));
        // print("Warning, not allowed to set the componentRef to a expression in DAEUtil.traverseDAEEquationsStmts\n");
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_ASSIGN_ARR(tp,cr,e_1,source)::xs_1,extraArg);

    case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source))::xs),_,extraArg)
      equation
        (algElse,extraArg) = traverseDAEStmtsElse(algElse,func, x, extraArg);
        (stmts2,extraArg) = traverseDAEStmts(stmts,func,extraArg);
        ((e_1,extraArg)) = func((e, x, extraArg));
        (xs_1,extraArg) = traverseDAEStmts(xs, func, extraArg);
        stmts1 = Algorithm.optimizeIf(e_1,stmts2,algElse,source);
      then (listAppend(stmts1, xs_1),extraArg);

    case (((x as DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_FOR(tp,b1,id1,ix,e_1,stmts2,source)::xs_1,extraArg);

    case (((x as DAE.STMT_PARFOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, loopPrlVars=loopPrlVars, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_PARFOR(tp,b1,id1,ix,e_1,stmts2,loopPrlVars,source)::xs_1,extraArg);

    case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_WHILE(e_1,stmts2,source)::xs_1,extraArg);

    case (((x as DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=NONE(),source=source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,NONE(),source)::xs_1,extraArg);

    case (((x as DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=SOME(ew),source=source))::xs),_,extraArg)
      equation
        ({ew_1}, extraArg) = traverseDAEStmts({ew},func,extraArg);
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,SOME(ew),source)::xs_1,extraArg);

    case (((x as DAE.STMT_ASSERT(cond = e, msg=e2, level=e3, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x, extraArg));
        ((e_2, extraArg)) = func((e2, x, extraArg));
        ((e_3, extraArg)) = func((e3, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_ASSERT(e_1,e_2,e_3,source)::xs_1,extraArg);

    case (((x as DAE.STMT_TERMINATE(msg = e, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_TERMINATE(e_1,source)::xs_1,extraArg);

    case (((x as DAE.STMT_REINIT(var = e,value=e2, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x, extraArg));
        ((e_2, extraArg)) = func((e2, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_REINIT(e_1,e_2,source)::xs_1,extraArg);

    case (((x as DAE.STMT_NORETCALL(exp = e, source = source))::xs),_,extraArg)
      equation
        ((e_1, extraArg)) = func((e, x, extraArg));
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_NORETCALL(e_1,source)::xs_1,extraArg);

    case (((x as DAE.STMT_RETURN(source = source))::xs),_,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (x::xs_1,extraArg);

    case (((x as DAE.STMT_BREAK(source = source))::xs),_,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (x::xs_1,extraArg);

    // MetaModelica extension. KS
    case (((x as DAE.STMT_FAILURE(body=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_FAILURE(stmts2,source)::xs_1,extraArg);

    case (((x as DAE.STMT_TRY(tryBody=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_TRY(stmts2,source)::xs_1,extraArg);

    case (((x as DAE.STMT_CATCH(catchBody=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_CATCH(stmts2,source)::xs_1,extraArg);

    case (((x as DAE.STMT_THROW(source = source))::xs),_,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (x::xs_1,extraArg);

    case ((x::xs),_,extraArg)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "DAEUtil.traverseDAEStmts not implemented correctly: " +& str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end traverseDAEStmts;

protected function traverseDAEStmtsElse "Helper function for traverseDAEEquationsStmts"
  input DAE.Else inElse;
  input FuncExpType func;
  input DAE.Statement istmt;
  input Type_a iextraArg;
  output DAE.Else outElse;
  output Type_a oextraArg;
  partial function FuncExpType
    input tuple<DAE.Exp, DAE.Statement, Type_a> arg;
    output tuple<DAE.Exp, Type_a> oarg;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outElse,oextraArg) := match(inElse, func, istmt, iextraArg)
  local
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    DAE.Else el,el_1;
    Type_a extraArg;
  case (DAE.NOELSE(),_,_,extraArg) then (DAE.NOELSE(),extraArg);
  case (DAE.ELSEIF(e,st,el),_,_,extraArg)
    equation
      (el_1,extraArg) = traverseDAEStmtsElse(el,func,istmt,extraArg);
      (st_1,extraArg) = traverseDAEStmts(st,func,extraArg);
      ((e_1,extraArg)) = func((e, istmt, extraArg));
    then (Algorithm.optimizeElseIf(e_1,st_1,el_1),extraArg);
  case(DAE.ELSE(st),_,_,extraArg)
    equation
      (st_1,extraArg) = traverseDAEStmts(st,func,extraArg);
    then (DAE.ELSE(st_1),extraArg);
end match;
end traverseDAEStmtsElse;

protected function traverseDAEExpListStmt "
Author: BZ, 2008-12
Traverse an list of expressions, helper function for traverseDAE"
  input list<DAE.Exp> iexps;
  input FuncExpType func;
  input DAE.Statement istmt;
  input Type_a iextraArg;
  output list<DAE.Exp> oexps;
  output Type_a oextraArg;
  partial function FuncExpType
    input tuple<DAE.Exp, DAE.Statement, Type_a> arg;
    output tuple<DAE.Exp,Type_a> oarg;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (oexps,oextraArg) := match(iexps, func, istmt, iextraArg)
    local
      DAE.Exp e;
      Type_a extraArg;
      list<DAE.Exp> exps;

    case({},_,_,extraArg) then ({},extraArg);

    case(e::exps,_,_,extraArg)
      equation
        ((e,extraArg)) = func((e, istmt, extraArg));
        (oexps,extraArg) = traverseDAEExpListStmt(exps, func, istmt, extraArg);
      then
        (e::oexps,extraArg);
  end match;
end traverseDAEExpListStmt;

protected function traverseDAEVarAttr "
Author: BZ, 2008-12
Help function to traverseDAE
"
  input Option<DAE.VariableAttributes> attr;
  input FuncExpType func;
  input Type_a iextraArg;
  output Option<DAE.VariableAttributes> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input tuple<DAE.Exp,Type_a> arg; output tuple<DAE.Exp,Type_a> oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := match(attr,func,iextraArg)
    local
      Option<DAE.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal,eb,so;
      Option<DAE.StateSelect> stateSelect;
      Option<DAE.Uncertainty> uncertainty;
      Option<DAE.Distribution> distribution;
      Option<Boolean> ip,fn;
      Type_a extraArg;

    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,uncertainty,distribution,eb,ip,fn,so)),_,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (unit,extraArg) = traverseDAEOptExp(unit,func,extraArg);
        (displayUnit,extraArg) = traverseDAEOptExp(displayUnit,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        (nominal,extraArg) = traverseDAEOptExp(nominal,func,extraArg);
      then (SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect,uncertainty,distribution,eb,ip,fn,so)),extraArg);

    case(SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,uncertainty,distribution,eb,ip,fn,so)),_,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      then (SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed,uncertainty,distribution,eb,ip,fn,so)),extraArg);

      case(SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
          (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        then (SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed,eb,ip,fn,so)),extraArg);

      case(SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        then (SOME(DAE.VAR_ATTR_STRING(quantity,initial_,eb,ip,fn,so)),extraArg);

      case(SOME(DAE.VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (initial_,extraArg) = traverseDAEOptExp(initial_,func,extraArg);
        then (SOME(DAE.VAR_ATTR_ENUMERATION(quantity,(min,max),initial_,fixed,eb,ip,fn,so)),extraArg);

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
    case (DAE.DAE(elts),_)
      equation
        elts = List.map1(elts,addComponentType2,newtype);
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
      DAE.VarParallelism prl;
      DAE.Type tp;
      DAE.InstDims dim;
      DAE.ConnectorType ct;
      DAE.VarVisibility prot;
      Option<DAE.Exp> bind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Absyn.Path newtype;
      Absyn.InnerOuter io;
      DAE.ElementSource source "the element origin";

    case (DAE.VAR(componentRef = cr,
               kind = kind,
               direction = dir,
               parallelism = prl,
               protection = prot,
               ty = tp,
               binding = bind,
               dims = dim,
               connectorType = ct,
               source = source,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io),newtype)
      equation
        source = addElementSourceType(source, newtype);
      then
        DAE.VAR(cr,kind,dir,prl,prot,tp,bind,dim,ct,source,dae_var_attr,comment,io);
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
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;

    case (DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, operations,comment), _)
      then DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, classPath::typeLst, operations,comment);
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
    case (_, NONE()) then inSource; // no source change.
    case (_, SOME(classPath))
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
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;

    case (DAE.SOURCE(info,partOfLst, instanceOptLst, connectEquationOptLst, typeLst, operations,comment), _)
      then DAE.SOURCE(info,withinPath::partOfLst, instanceOptLst, connectEquationOptLst, typeLst, operations,comment);
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
    case (_, NONE())
      equation
        src = addElementSourcePartOf(inSource, Absyn.TOP());
      then inSource;
    case (_, SOME(classPath))
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
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;
    case (DAE.SOURCE(_,partOfLst,instanceOptLst,connectEquationOptLst,typeLst,operations,comment), info)
      then DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst,operations,comment);
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
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;

    // a NONE() means top level (equivalent to NO_PRE, SOME(cref) means subcomponent
    case (DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst,operations,comment), _)
      then DAE.SOURCE(info,partOfLst,instanceOpt::instanceOptLst,connectEquationOptLst,typeLst,operations,comment);
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
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;

    // a top level
    case (_, NONE()) then inSource;
    case (DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst,operations,comment), _)
      then DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOpt::connectEquationOptLst,typeLst,operations,comment);
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
      list<DAE.SymbolicOperation> o,operations1,operations2;
      list<SCode.Comment> comment, comment1,comment2;
    case (DAE.SOURCE(info, partOfLst1, instanceOptLst1, connectEquationOptLst1, typeLst1, operations1, comment1),
          DAE.SOURCE(_ /* Discard */, partOfLst2, instanceOptLst2, connectEquationOptLst2, typeLst2, operations2, comment2))
      equation
        p = List.union(partOfLst1, partOfLst2);
        i = List.union(instanceOptLst1, instanceOptLst2);
        c = List.union(connectEquationOptLst1, connectEquationOptLst2);
        t = List.union(typeLst1, typeLst2);
        o = listAppend(operations1, operations2);
        comment = List.union(comment1,comment2);
      then DAE.SOURCE(info,p,i,c,t, o,comment);
 end match;
end mergeSources;

public function addCommentToSource
  input DAE.ElementSource src1;
  input Option<SCode.Comment> commentIn;
  output DAE.ElementSource mergedSrc;
algorithm
  mergedSrc := match(src1,commentIn)
    local
      Absyn.Info info;
      list<Absyn.Within> partOfLst1;
      list<Option<DAE.ComponentRef>> instanceOptLst1;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst1;
      list<Absyn.Path> typeLst1;
      list<DAE.SymbolicOperation> operations1;
      list<SCode.Comment> comment1,comment2;
      SCode.Comment comment;
    case (DAE.SOURCE(info, partOfLst1, instanceOptLst1, connectEquationOptLst1, typeLst1, operations1, comment1),SOME(comment))
      equation
        comment2 = comment::comment1;
      then DAE.SOURCE(info,partOfLst1,instanceOptLst1,connectEquationOptLst1,typeLst1, operations1,comment2);
    case(_,_)
      then
        src1;
 end match;
end addCommentToSource;

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
algorithm
  b := match (it)
    case DAE.NO_INLINE() then false;
    else true;
  end match;
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
        elts = List.appendNoCopy(elts1,elts2);
        // t2 = clock();
        // ti = t2 -. t1;
        // Debug.fprintln(Flags.INNER_OUTER, " joinDAEs: (" +& realString(ti) +& ") -> " +& intString(listLength(elts1)) +& " + " +&  intString(listLength(elts2)));
      then DAE.DAE(elts);

  end match;
end joinDaes;

public function joinDaeLst "joins a list of daes by using joinDaes"
  input list<DAE.DAElist> idaeLst;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(idaeLst)
    local
      DAE.DAElist dae,dae1;
      list<DAE.DAElist> daeLst;
    case({dae}) then dae;
    case(dae::daeLst)
      equation
        dae1 = joinDaeLst(daeLst);
        dae = joinDaes(dae,dae1);
      then dae;
  end matchcontinue;
end joinDaeLst;

public function appendToCompDae
  input DAE.DAElist inCompDae;
  input DAE.DAElist inDae;
  output DAE.DAElist outCompDae;
protected
  DAE.Ident ident;
  list<DAE.Element> el, el2;
  DAE.ElementSource src;
  Option<SCode.Comment> cmt;
algorithm
  DAE.DAE({DAE.COMP(ident, el, src, cmt)}) := inCompDae;
  DAE.DAE(el2) := inDae;
  el := listAppend(el, el2);
  outCompDae := DAE.DAE({DAE.COMP(ident, el, src, cmt)});
end appendToCompDae;

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
  tree := DAE.emptyFuncTree;
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
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> inValues;
  input DAE.AvlTree inTree;
  output DAE.AvlTree outTree;
algorithm
  outTree := match(inValues,inTree)
    local
      DAE.AvlKey key;
      list<tuple<DAE.AvlKey,DAE.AvlValue>> values;
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
        true = Absyn.pathEqual(rkey, key);
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
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local Integer d; DAE.AvlTree bt;
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
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,inBt)
    local DAE.AvlTree bt;
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(_,bt) equation
      bt = doBalance2(difference,bt);
    then bt;
    case (_,bt) then bt;
  end  matchcontinue;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Integer difference;
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(difference,inBt)
    local DAE.AvlTree bt;
    case(_,bt) equation
      true = difference < 0;
      bt = doBalance3(bt);
      bt = rotateLeft(bt);
     then bt;
    case(_,bt) equation
      true = difference > 0;
      bt = doBalance4(bt);
      bt = rotateRight(bt);
     then bt;
  end matchcontinue;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
  local DAE.AvlTree rr,bt;
    case(bt) equation
      true = differenceInHeight(getOption(rightNode(bt))) > 0;
      rr = rotateRight(getOption(rightNode(bt)));
      bt = setRight(bt,SOME(rr));
    then bt;
    case(bt) then bt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := match(inBt)
  local DAE.AvlTree rl,bt;
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
    case(DAE.AVLTREENODE(value,height,l,r),_) then DAE.AVLTREENODE(value,height,l,right);
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
    case(DAE.AVLTREENODE(value,height,l,r),_) then DAE.AVLTREENODE(value,height,left,r);
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
  input DAE.AvlTree inode;
  input DAE.AvlTree iparent;
  output DAE.AvlTree outParent "updated parent";
algorithm
  outParent := match(inode,iparent)
    local
      DAE.AvlTree bt,node,parent;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeLeft;

protected function exchangeRight "help function to balance"
  input DAE.AvlTree inode;
  input DAE.AvlTree iparent;
  output DAE.AvlTree outParent "updated parent";
algorithm
  outParent := match(inode,iparent)
    local DAE.AvlTree bt,node,parent;
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
        0 = stringCompare(Absyn.pathStringNoQual(key),Absyn.pathStringNoQual(rkey));
      then
        rval;

    // Search to the right
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),right = SOME(right)),key)
      equation
        1 = stringCompare(Absyn.pathStringNoQual(key),Absyn.pathStringNoQual(rkey));
        res = avlTreeGet(right, key);
      then
        res;

    // Search to the left
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),left = SOME(left)),key)
      equation
        -1 = stringCompare(Absyn.pathStringNoQual(key),Absyn.pathStringNoQual(rkey));
        res = avlTreeGet(left, key);
      then
        res;
  end matchcontinue;
end avlTreeGet;

protected function getOptionStr "Retrieve the string from a string option.
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
   equations, algorithms, constraints and external objects"
  input list<DAE.Element> inElements;
  output list<DAE.Element> v;
  output list<DAE.Element> ie;
  output list<DAE.Element> ia;
  output list<DAE.Element> e;
  output list<DAE.Element> a;
  output list<DAE.Element> ca;
  output list<DAE.Element> co;
  output list<DAE.Element> o;
algorithm
  (v,ie,ia,e,a,ca,co,o) := splitElements_dispatch(inElements,{},{},{},{},{},{},{},{});
end splitElements;
protected function isIfEquation "Succeeds if Element is an if-equation.
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
   equations, algorithms, constraints and external objects"
  input list<DAE.Element> inElements;
  input list<DAE.Element> in_v_acc;   // variables
  input list<DAE.Element> in_ie_acc;  // initial equations
  input list<DAE.Element> in_ia_acc;  // initial algorithms
  input list<DAE.Element> in_e_acc;   // equations
  input list<DAE.Element> in_a_acc;   // algorithms
  input list<DAE.Element> in_ca_acc;  // class Attribute
  input list<DAE.Element> in_co_acc;  // constraints
  input list<DAE.Element> in_o_acc;
  output list<DAE.Element> v;
  output list<DAE.Element> ie;
  output list<DAE.Element> ia;
  output list<DAE.Element> e;
  output list<DAE.Element> a;
  output list<DAE.Element> ca;
  output list<DAE.Element> co;
  output list<DAE.Element> o;
algorithm
  (v,ie,ia,e,a,ca,co,o) := match(inElements,in_v_acc,in_ie_acc,in_ia_acc,in_e_acc,in_a_acc,in_ca_acc,in_co_acc,in_o_acc)
    local
      DAE.Element el;
      list<DAE.Element> rest, ell, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc;

    // handle empty case
    case ({}, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
    then (listReverse(v_acc),listReverse(ie_acc),listReverse(ia_acc),listReverse(e_acc),listReverse(a_acc),listReverse(ca_acc),listReverse(co_acc),listReverse(o_acc));

    // variables
    case ((el as DAE.VAR(kind=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, el::v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // initial equations
    case ((el as DAE.INITIALEQUATION(exp1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.INITIAL_ARRAY_EQUATION(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.INITIAL_COMPLEX_EQUATION(lhs=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.INITIALDEFINE(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.INITIAL_IF_EQUATION(condition1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // equations
    case ((el as DAE.EQUATION(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.EQUEQUATION(cr1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.ARRAY_EQUATION(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.COMPLEX_EQUATION(lhs=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.DEFINE(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.ASSERT(condition=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.IF_EQUATION(condition1=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.WHEN_EQUATION(condition=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.REINIT(exp=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
    case ((el as DAE.NORETCALL(functionName=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // initial algorithms
    case ((el as DAE.INITIALALGORITHM(algorithm_=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,el::ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // algorithms
    case ((el as DAE.ALGORITHM(algorithm_=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,el::a_acc,ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // constraints
    case ((el as DAE.CONSTRAINT(constraints=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,el::co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // ClassAttributes
    case ((el as DAE.CLASS_ATTRIBUTES(classAttrs =_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,el::ca_acc,co_acc,o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    // external objects
    case ((el as DAE.EXTOBJECTCLASS(path=_))::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,el::o_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc);

    case ((el as DAE.COMP(dAElist = ell))::rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc)
      equation
        v_acc = listAppend(ell, v_acc);
        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc) =
          splitElements_dispatch(rest, v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc);
      then
        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc);

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
        false = Config.acceptMetaModelicaGrammar();
      then {};
    case (_, _)
      equation
        paths1 = getUniontypePathsFunctions(funcs);
        paths2 = getUniontypePathsElements(els,{});
        // Use accumulators? Small gain as T_METAUNIONTYPE has lists of paths anyway?
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
    case _
      equation
        (_,(_,els1)) = traverseDAEFunctions(elements, Expression.traverseSubexpressionsHelper, (collectLocalDecls,{}), {});
        els2 = getFunctionsElements(elements);
        els = listAppend(els1, els2);
        outPaths = getUniontypePathsElements(els,{});
      then outPaths;
  end match;
end getUniontypePathsFunctions;

protected function getUniontypePathsElements
"May contain duplicates."
  input list<DAE.Element> elements;
  input list<DAE.Type> acc;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := match (elements,acc)
    local
      list<Absyn.Path> paths1;
      list<DAE.Element> rest;
      list<DAE.Type> tys;
      DAE.Type ft;
    case ({},_) then List.applyAndFold(acc, listAppend, Types.getUniontypePaths, {});
    case (DAE.VAR(ty = ft)::rest,_)
      equation
        tys = Types.getAllInnerTypesOfType(ft, Types.uniontypeFilter);
      then getUniontypePathsElements(rest,listAppend(tys,acc));
    case (_::rest,_) then getUniontypePathsElements(rest,acc);
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

// protected function transformDerInline "This is not used.
//   Simple euler inline of the equation system; only does explicit euler, and only der(cref)"
//   input DAE.DAElist dae;
//   output DAE.DAElist d;
// algorithm
//   d := matchcontinue (dae)
//     local
//       HashTable.HashTable ht;
//     case _
//       equation
//         false = Flags.isSet(Flags.FRONTEND_INLINE_EULER);
//       then dae;
//     case _
//       equation
//         ht = HashTable.emptyHashTable();
//         (d,_,ht) = traverseDAE(dae,DAE.emptyFuncTree,simpleInlineDerEuler,ht);
//       then d;
//   end matchcontinue;
// end transformDerInline;
// 
// protected function simpleInlineDerEuler "This is not used.
//   Helper function of transformDerInline."
//   input tuple<DAE.Exp,HashTable.HashTable> itpl;
//   output tuple<DAE.Exp,HashTable.HashTable> otpl;
// algorithm
//   otpl := matchcontinue (itpl)
//     local
//       DAE.ComponentRef cr,cref_1,cref_2;
//       HashTable.HashTable crs0,crs1;
//       DAE.Exp exp,e1,e2;
// 
//     case ((DAE.CALL(path=Absyn.IDENT("der"),expLst={exp as DAE.CREF(componentRef = cr, ty = DAE.T_REAL(varLst = _))}),crs0))
//       equation
//         cref_1 = ComponentReference.makeCrefQual("$old",DAE.T_REAL_DEFAULT,{},cr);
//         cref_2 = ComponentReference.makeCrefIdent("$current_step_size",DAE.T_REAL_DEFAULT,{});
//         e1 = Expression.makeCrefExp(cref_1,DAE.T_REAL_DEFAULT);
//         e2 = Expression.makeCrefExp(cref_2,DAE.T_REAL_DEFAULT);
//         exp = DAE.BINARY(
//                 DAE.BINARY(exp, DAE.SUB(DAE.T_REAL_DEFAULT), e1),
//                 DAE.DIV(DAE.T_REAL_DEFAULT),
//                 e2);
//         crs1 = BaseHashTable.add((cr,0),crs0);
//       then
//         ((exp,crs1));
// 
//     case ((exp,crs0)) then ((exp,crs0));
// 
//   end matchcontinue;
// end simpleInlineDerEuler;

public function transformationsBeforeBackend
  input Env.Cache cache;
  input list<Env.Frame> env;
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
protected
  list<DAE.Element> elts;
algorithm
  DAE.DAE(elts) := inDAElist;
  elts := List.map1(elts, makeEvaluatedParamFinal, Env.getEvaluatedParams(cache));
  outDAElist := DAE.DAE(elts);
  // Don't even run the function to try and do this; it doesn't work very well
  // outDAElist := transformDerInline(outDAElist);
end transformationsBeforeBackend;

protected function makeEvaluatedParamFinal "
  This function makes all evaluated parameters final."
  input DAE.Element inElement;
  input HashTable.HashTable ht "evaluated parameters";
  output DAE.Element outElement;
algorithm
  outElement := matchcontinue(inElement, ht)
    local
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> varOpt;
      String id;
      list<DAE.Element> elts;
      DAE.ElementSource source;
      Option<SCode.Comment> cmt;
      DAE.Element elt;
      
    case (DAE.VAR(componentRef=cr, kind=DAE.PARAM(), variableAttributesOption=varOpt), _) equation
      _ = BaseHashTable.get(cr, ht);
      // print("Make cr final " +& ComponentReference.printComponentRefStr(cr) +& "\n");
      elt = setVariableAttributes(inElement, setFinalAttr(varOpt, true));
    then elt;
    
    case (DAE.COMP(id, elts, source, cmt), _) equation
      elts = List.map1(elts, makeEvaluatedParamFinal, ht);
    then DAE.COMP(id, elts, source, cmt);
    
    else inElement;
  end matchcontinue;
end makeEvaluatedParamFinal;

public function setBindingSource "author: adrpo
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

    case (DAE.UNBOUND(), _) then inBinding;
    case (DAE.EQBOUND(exp, evaluatedExp, cnst, _), _) then DAE.EQBOUND(exp, evaluatedExp, cnst, bindingSource);
    case (DAE.VALBOUND(valBound, _), _) then DAE.VALBOUND(valBound, bindingSource);
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
        acc = List.fold(decls, collectFunctionRefVarPaths, acc);
      then ((exp,acc));
    case _ then itpl;
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
    case (DAE.VAR(ty = DAE.T_FUNCTION(source = {path})),_)
      then path::acc;
    case (_,_) then acc;
  end matchcontinue;
end collectFunctionRefVarPaths;

public function addDaeFunction "add functions present in the element list to the function tree"
  input list<DAE.Function> ifuncs;
  input DAE.FunctionTree itree;
  output DAE.FunctionTree outTree;
algorithm
  outTree := match(ifuncs,itree)
    local
      DAE.Function func;
      list<DAE.Function> funcs;
      DAE.FunctionTree tree;

    case ({},tree) then tree;
    case (func::funcs,tree)
      equation
        // print("Add to cache: " +& Absyn.pathString(functionName(func)) +& "\n");
        tree = avlTreeAdd(tree,functionName(func),SOME(func));
      then addDaeFunction(funcs,tree);

  end match;
end addDaeFunction;

public function addDaeExtFunction "
  add extermal functions present in the element list to the function tree
  Note: normal functions are skipped.
  See also addDaeFunction"
  input list<DAE.Function> ifuncs;
  input DAE.FunctionTree itree;
  output DAE.FunctionTree outTree;
algorithm
  outTree := matchcontinue(ifuncs,itree)
    local
      DAE.Function func;
      list<DAE.Function> funcs;
      DAE.FunctionTree tree;


    case ({},tree) then tree;
    case (func::funcs,tree)
      equation
        true = isExtFunction(func);
        tree = avlTreeAdd(tree,functionName(func),SOME(func));
      then addDaeExtFunction(funcs,tree);

    case (func::funcs,tree) then addDaeExtFunction(funcs,tree);

  end matchcontinue;
end addDaeExtFunction;

public function setAttrVariability "
  Sets the variability attribute in an Attributes record."
  input DAE.Attributes inAttr;
  input SCode.Variability inVar;
  output DAE.Attributes outAttr;
protected
  SCode.ConnectorType ct;
  SCode.Parallelism prl;
  Absyn.Direction dir;
  Absyn.InnerOuter io;
  SCode.Visibility vis;
algorithm
  DAE.ATTR(ct, prl, _, dir, io, vis) := inAttr;
  outAttr := DAE.ATTR(ct, prl, inVar, dir, io, vis);
end setAttrVariability;

public function getAttrVariability "
  Get the variability attribute in an Attributes record."
  input DAE.Attributes inAttr;
  output SCode.Variability outVar;
algorithm
  DAE.ATTR(variability = outVar) := inAttr;
end getAttrVariability;

public function addSymbolicTransformation
  input DAE.ElementSource source;
  input DAE.SymbolicOperation op;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue (source,op)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      DAE.Exp h1,t1,t2;
      list<DAE.Exp> es1,es2,es;
      list<SCode.Comment> comment;

    case (DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, DAE.SUBSTITUTION(es1 as (h1::_),t1)::operations,comment),DAE.SUBSTITUTION(es2,t2))
      equation
        // The tail of the new substitution chain is the same as the head of the old one...
        true = Expression.expEqual(t2,h1);
        // Reference equality would be fine as otherwise it is not really a chain... But replaceExp is stupid :(
        // true = referenceEq(t2,h1);
        es = listAppend(es2,es1);
      then DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, DAE.SUBSTITUTION(es,t1)::operations,comment);

    case (DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, operations, comment),_)
      then DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, op::operations,comment);
  end matchcontinue;
end addSymbolicTransformation;

public function condAddSymbolicTransformation
  input Boolean cond;
  input DAE.ElementSource source;
  input DAE.SymbolicOperation op;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (cond,source,op)
    case (true,_,_)
      then addSymbolicTransformation(source,op);
    else source;
  end match;
end condAddSymbolicTransformation;

public function addSymbolicTransformationDeriveLst
  input DAE.ElementSource isource;
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(isource,explst1,explst2)
    local
      DAE.SymbolicOperation op;
      list<DAE.Exp> rexplst1,rexplst2;
      DAE.Exp exp1,exp2;
      DAE.ElementSource source;
    case(_,{},_) then isource;
    case(_,exp1::rexplst1,exp2::rexplst2)
      equation
        op = DAE.OP_DIFFERENTIATE(DAE.crefTime,exp1,exp2);
        source = addSymbolicTransformation(isource,op);
      then
        addSymbolicTransformationDeriveLst(source,rexplst1,rexplst2);
  end match;
end addSymbolicTransformationDeriveLst;

public function addSymbolicTransformationSubstitutionLst
  input list<Boolean> add;
  input DAE.ElementSource isource;
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(add,isource,explst1,explst2)
    local
      list<Boolean> brest;
      list<DAE.Exp> rexplst1,rexplst2;
      DAE.Exp exp1,exp2;
      DAE.ElementSource source;
    case({},_,_,_) then isource;
    case(true::brest,_,exp1::rexplst1,exp2::rexplst2)
      equation
        source = addSymbolicTransformationSubstitution(true,isource,exp1,exp2);
      then
        addSymbolicTransformationSubstitutionLst(brest,source,rexplst1,rexplst2);
    case(false::brest,_,_::rexplst1,_::rexplst2)
      then
        addSymbolicTransformationSubstitutionLst(brest,isource,rexplst1,rexplst2);
  end match;
end addSymbolicTransformationSubstitutionLst;

public function addSymbolicTransformationSubstitution
  input Boolean add;
  input DAE.ElementSource source;
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  output DAE.ElementSource outSource;
algorithm
  outSource := condAddSymbolicTransformation(add,source,DAE.SUBSTITUTION({exp2},exp1));
end addSymbolicTransformationSubstitution;

public function addSymbolicTransformationSimplifyLst
  input list<Boolean> add;
  input DAE.ElementSource isource;
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(add,isource,explst1,explst2)
    local
      list<Boolean> brest;
      list<DAE.Exp> rexplst1,rexplst2;
      DAE.Exp exp1,exp2;
      DAE.ElementSource source;
    case({},_,_,_) then isource;
    case(true::brest,_,exp1::rexplst1,exp2::rexplst2)
      equation
        source = addSymbolicTransformation(isource, DAE.SIMPLIFY(DAE.PARTIAL_EQUATION(exp1),DAE.PARTIAL_EQUATION(exp2)));
      then
        addSymbolicTransformationSimplifyLst(brest,source,rexplst1,rexplst2);
    case(false::brest,_,_::rexplst1,_::rexplst2)
      then
        addSymbolicTransformationSimplifyLst(brest,isource,rexplst1,rexplst2);
  end match;
end addSymbolicTransformationSimplifyLst;

public function addSymbolicTransformationSimplify
  input Boolean add;
  input DAE.ElementSource source;
  input DAE.EquationExp exp1;
  input DAE.EquationExp exp2;
  output DAE.ElementSource outSource;
algorithm
  outSource := condAddSymbolicTransformation(add,source,DAE.SIMPLIFY(exp1,exp2));
end addSymbolicTransformationSimplify;

public function addSymbolicTransformationSolve
  input Boolean add;
  input DAE.ElementSource source;
  input DAE.ComponentRef cr;
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input DAE.Exp exp;
  input list<DAE.Statement> asserts;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (add,source,cr,exp1,exp2,exp,asserts)
    local
      list<DAE.Exp> assertExps;
      DAE.SymbolicOperation op,op1,op2;
    case (false,_,_,_,_,_,_) then source;
    case (_,_,_,_,_,_,_)
      equation
        assertExps = List.map(asserts,Algorithm.getAssertCond);
        op1 = DAE.SOLVE(cr,exp1,exp2,exp,assertExps);
        op2 = DAE.SOLVED(cr,exp2) "If it was already on solved form";
        op = Util.if_(Expression.expEqual(exp2,exp),op2,op1);
      then addSymbolicTransformation(source,op);
  end match;
end addSymbolicTransformationSolve;

public function getSymbolicTransformations
  input DAE.ElementSource source;
  output list<DAE.SymbolicOperation> ops;
algorithm
  DAE.SOURCE(operations=ops) := source;
end getSymbolicTransformations;

public function translateSCodeAttrToDAEAttr
  input SCode.Attributes inAttributes;
  input SCode.Prefixes inPrefixes;
  output DAE.Attributes outAttributes;
protected
  SCode.ConnectorType ct;
  SCode.Parallelism prl;
  SCode.Variability var;
  Absyn.Direction dir;
  Absyn.InnerOuter io;
  SCode.Visibility vis;
algorithm
  SCode.ATTR(connectorType = ct, parallelism = prl, variability = var, direction = dir) := inAttributes;
  SCode.PREFIXES(innerOuter = io, visibility = vis) := inPrefixes;
  outAttributes := DAE.ATTR(ct, prl, var, dir, io, vis);
end translateSCodeAttrToDAEAttr;

public function varName
  input DAE.Element var;
  output String name;
algorithm
  DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name)) := var;
end varName;

public function bindingExp "
  help function to instBinding, returns the expression of a binding"
  input DAE.Binding bind;
  output Option<DAE.Exp> exp;
algorithm
  exp := match(bind)
  local DAE.Exp e; Values.Value v;
    case DAE.UNBOUND() then NONE();
    case DAE.EQBOUND(evaluatedExp = SOME(v))
      equation
        e = ValuesUtil.valueExp(v);
      then
        SOME(e);
    case DAE.EQBOUND(exp = e) then SOME(e);
    case DAE.VALBOUND(valBound=v)
      equation
        e = ValuesUtil.valueExp(v);
      then
        SOME(e);
  end match;
end bindingExp;

public function isBound
  input DAE.Binding inBinding;
  output Boolean outIsBound;
algorithm
  outIsBound := match(inBinding)
    case DAE.UNBOUND() then false;
    else true;
  end match;
end isBound;

public function isCompleteFunction "author: adrpo
  this function returns true if the given function is complete:
  - has inputs
  - has outputs
  - has an algorithm section
  note that record constructors are always considered complete"
 input DAE.Function f;
 output Boolean isComplete;
algorithm
  isComplete := matchcontinue(f)
    local
      list<DAE.FunctionDefinition> functions;

    // record constructors are always complete!
    case (DAE.RECORD_CONSTRUCTOR(path = _)) then true;

    // functions are complete if they have inputs, outputs and algorithm section
    case (DAE.FUNCTION(functions = functions))
      equation
        true = isCompleteFunctionBody(functions);
      then
        true;

    case (_)
      then false;
  end matchcontinue;
end isCompleteFunction;

public function isCompleteFunctionBody "author: adrpo
  this function returns true if the given function body is complete"
  input list<DAE.FunctionDefinition> functions;
  output Boolean isComplete;
algorithm
  isComplete := matchcontinue(functions)
    local
      list<DAE.FunctionDefinition> rest;
      list<DAE.Element> els;
      list<DAE.Element> v, ie, ia, e, a, o, ca, co;

    case ({}) then false;

    // external are complete!
    case (DAE.FUNCTION_EXT(body = _)::rest) then true;

    // functions are complete if they have inputs, outputs and algorithm section
    case (DAE.FUNCTION_DEF(els)::rest)
      equation
        // algs are not empty
        (v,ie,ia,e,a,ca,co,o) = splitElements(els);
        false = List.isEmpty(a);
      then
        true;

    case (DAE.FUNCTION_DER_MAPPER(derivedFunction = _)::rest)
      equation
        true = isCompleteFunctionBody(rest);
      then
        true;

    case (_)
      then false;
  end matchcontinue;
end isCompleteFunctionBody;

public function isNotCompleteFunction
 input DAE.Function f;
 output Boolean isNotComplete;
algorithm
  isNotComplete := not isCompleteFunction(f);
end isNotCompleteFunction;

public function setAttributeDirection
  input Absyn.Direction inDirection;
  input DAE.Attributes inAttributes;
  output DAE.Attributes outAttributes;
protected
  SCode.ConnectorType ct;
  SCode.Parallelism p;
  SCode.Variability var;
  Absyn.InnerOuter io;
  SCode.Visibility vis;
algorithm
  DAE.ATTR(ct, p, var, _, io, vis) := inAttributes;
  outAttributes := DAE.ATTR(ct, p, var, inDirection, io, vis);
end setAttributeDirection;

public function varKindEqual
  input DAE.VarKind inVariability1;
  input DAE.VarKind inVariability2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inVariability1, inVariability2)
    case (DAE.VARIABLE(), DAE.VARIABLE()) then true;
    case (DAE.DISCRETE(), DAE.DISCRETE()) then true;
    case (DAE.CONST(), DAE.CONST()) then true;
    case (DAE.PARAM(), DAE.PARAM()) then true;
  end match;
end varKindEqual;

public function varDirectionEqual
  input DAE.VarDirection inDirection1;
  input DAE.VarDirection inDirection2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inDirection1, inDirection2)
    case (DAE.BIDIR(), DAE.BIDIR()) then true;
    case (DAE.INPUT(), DAE.INPUT()) then true;
    case (DAE.OUTPUT(), DAE.OUTPUT()) then true;
    else false;
  end match;
end varDirectionEqual;

public function isComplexVar
  input DAE.Var inVar;
  output Boolean outIsComplex;
protected
  DAE.Type ty;
algorithm
  DAE.TYPES_VAR(ty = ty) := inVar;
  outIsComplex := Types.isComplexType(ty);
end isComplexVar;

public function getElements
  input DAE.DAElist inDAE;
  output list<DAE.Element> outElements;
algorithm
  DAE.DAE(outElements) := inDAE;
end getElements;

public function addAdditionalComment
  input DAE.ElementSource source;
  input String message;
  output DAE.ElementSource outSource;
algorithm
  outSource := match (source,message)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<DAE.SymbolicOperation> operations;
      list<SCode.Comment> comment;
      Boolean b;
      SCode.Comment c;

    case (DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, operations, comment),_)
      equation
        c = SCode.COMMENT(NONE(), SOME(message));
        b = listMember(c, comment);
        comment = Util.if_(b, comment, c::comment);
      then
        DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst, operations, comment);

  end match;
end addAdditionalComment;

public function getCommentsFromSource
  input DAE.ElementSource source;
  output list<SCode.Comment> outComments;
algorithm
  outComments := matchcontinue (source)
    local
      list<SCode.Comment> comment;

    case (DAE.SOURCE(comment = comment)) then comment;

  end matchcontinue;
end getCommentsFromSource;

public function mkEmptyVar
  input String name;
  output DAE.Var outVar;
algorithm
  outVar := DAE.TYPES_VAR(
              name,
              DAE.dummyAttrVar,
              DAE.T_UNKNOWN_DEFAULT,
              DAE.UNBOUND(),
              NONE());
end mkEmptyVar;

public function getElementSource
  input DAE.Element element;
  output DAE.ElementSource source;
algorithm
  source := match element
    case DAE.VAR(source=source) then source;
    case DAE.DEFINE(source=source) then source;
    case DAE.INITIALDEFINE(source=source) then source;
    case DAE.EQUATION(source=source) then source;
    case DAE.EQUEQUATION(source=source) then source;
    case DAE.ARRAY_EQUATION(source=source) then source;
    case DAE.INITIAL_ARRAY_EQUATION(source=source) then source;
    case DAE.COMPLEX_EQUATION(source=source) then source;
    case DAE.INITIAL_COMPLEX_EQUATION(source=source) then source;
    case DAE.WHEN_EQUATION(source=source) then source;
    case DAE.IF_EQUATION(source=source) then source;
    case DAE.INITIAL_IF_EQUATION(source=source) then source;
    case DAE.INITIALEQUATION(source=source) then source;
    case DAE.ALGORITHM(source=source) then source;
    case DAE.INITIALALGORITHM(source=source) then source;
    case DAE.COMP(source=source) then source;
    case DAE.EXTOBJECTCLASS(source=source) then source;
    case DAE.ASSERT(source=source) then source;
    case DAE.TERMINATE(source=source) then source;
    case DAE.REINIT(source=source) then source;
    case DAE.NORETCALL(source=source) then source;
    case DAE.CONSTRAINT(source=source) then source;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"DAEUtil.getElementSource failed: Element does not have a source"});
      then fail();
  end match;
end getElementSource;

public function getStatementSource
  "Returns the element source associated with a statement."
  input DAE.Statement inStatement;
  output DAE.ElementSource outSource;
algorithm
  outSource := match(inStatement)
    local
      DAE.ElementSource source;

    case DAE.STMT_ASSIGN(source = source) then source;
    case DAE.STMT_TUPLE_ASSIGN(source = source) then source;
    case DAE.STMT_ASSIGN_ARR(source = source) then source;
    case DAE.STMT_IF(source = source) then source;
    case DAE.STMT_FOR(source = source) then source;
    case DAE.STMT_PARFOR(source = source) then source;
    case DAE.STMT_WHILE(source = source) then source;
    case DAE.STMT_WHEN(source = source) then source;
    case DAE.STMT_ASSERT(source = source) then source;
    case DAE.STMT_TERMINATE(source = source) then source;
    case DAE.STMT_REINIT(source = source) then source;
    case DAE.STMT_NORETCALL(source = source) then source;
    case DAE.STMT_RETURN(source = source) then source;
    case DAE.STMT_BREAK(source = source) then source;
    case DAE.STMT_ARRAY_INIT(source = source) then source;
    case DAE.STMT_FAILURE(source = source) then source;
    case DAE.STMT_TRY(source = source) then source;
    case DAE.STMT_CATCH(source = source) then source;
    case DAE.STMT_THROW(source = source) then source;

  end match;
end getStatementSource;

public function sortDAEInModelicaCodeOrder
"@author: adrpo
 sort the DAE back in the order they are in the file"
  input Boolean inShouldSort;
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input DAE.DAElist inDae;
  output DAE.DAElist outDae;
algorithm
  outDae := match(inShouldSort, inElements, inDae)
    local 
      list<DAE.Element> els;
    
    case (false, _, _) then inDae;
    
    case (true, {}, _) then inDae;
    
    case (true, _, DAE.DAE(els))
      equation
        els = sortDAEElementsInModelicaCodeOrder(inElements, els, {});
      then DAE.DAE(els);
  
  end match;
end sortDAEInModelicaCodeOrder;

protected function sortDAEElementsInModelicaCodeOrder
"@author: adrpo
 sort the DAE elements back in the order they are in the file"
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input list<DAE.Element> inDaeEls;
  input list<DAE.Element> inAcc;
  output list<DAE.Element> outDaeEls;
algorithm
  outDaeEls := match(inElements, inDaeEls, inAcc)
    local 
      list<DAE.Element> dae, named, rest, els, acc;
      Absyn.Ident name;
      list<tuple<SCode.Element, DAE.Mod>> restEl;
      
    case ({}, _, _) then listAppend(inAcc, inDaeEls);
      
    case (((SCode.COMPONENT(name = name),_))::restEl, dae, acc)
      equation
        (named, rest) = splitVariableNamed(dae, name, {}, {});
        acc = listAppend(acc, named); 
        els = sortDAEElementsInModelicaCodeOrder(restEl, rest, acc); 
      then 
        els;
  
    case (((_,_))::restEl, dae, acc)
      equation
        els = sortDAEElementsInModelicaCodeOrder(restEl, dae, acc);
      then 
        els;
  
  end match;
end sortDAEElementsInModelicaCodeOrder;

protected function splitVariableNamed 
"@author: adrpo
  Splits into a list with all variables with the given name and the rest"
  input list<DAE.Element> inElementLst;
  input Absyn.Ident inName;
  input list<DAE.Element> inAccNamed;
  input list<DAE.Element> inAccRest;
  output list<DAE.Element> outNamed;
  output list<DAE.Element> outRest;
algorithm
  (outNamed, outRest) := match(inElementLst, inName, inAccNamed, inAccRest)
    local
      list<DAE.Element> res,lst, accNamed, accRest;
      DAE.Element x;
      Boolean equal;
      DAE.ComponentRef cr;

    case ({}, _, _, _) then (listReverse(inAccNamed), listReverse(inAccRest));

    case ((x as DAE.VAR(componentRef = cr))::lst, _, accNamed, accRest)
      equation
        equal = stringEq(ComponentReference.crefFirstIdent(cr), inName);
        accNamed = List.consOnTrue(equal, x, accNamed);
        accRest = List.consOnTrue(boolNot(equal), x, accRest);
        (accNamed, accRest) = splitVariableNamed(lst, inName, accNamed, accRest);
      then
        (accNamed, accRest);

    case (x::lst, _, accNamed, accRest)
      equation
        (accNamed, accRest) = splitVariableNamed(lst, inName, accNamed, x::accRest);
      then
        (accNamed, accRest);
  
  end match;
end splitVariableNamed;

end DAEUtil;
