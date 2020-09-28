/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package DAEUtil
" file:        DAEUtil.mo
  package:     DAE
  description: DAE management and output


  This module exports some helper functions to the DAE AST."

public import Absyn;
public import AbsynUtil;
public import ClassInf;
public import DAE;
public import FCore;
public import SCode;
public import Values;
public import ValuesUtil;
public import HashTable;
public import HashTable2;

protected
import Algorithm;
import BaseHashTable;
import Ceval;
import DAE.AvlTreePathFunction;
import ComponentReference;
import Config;
import DAE.Connect;
import ConnectUtil;
import DAEDump;
import Debug;
import DoubleEnded;
import ElementSource;
import Error;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import Flags;
import List;
import SCodeUtil;
import System;
import Types;
import Util;
import StateMachineFlatten;
import VarTransform;

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

public function const2VarKind
  input DAE.Const const;
  output DAE.VarKind kind;
algorithm
  kind := match(const)
    case(DAE.C_VAR()) then DAE.VARIABLE();
    case(DAE.C_PARAM()) then DAE.PARAM();
    case(DAE.C_CONST()) then DAE.CONST();
  end match;
end const2VarKind;

public function dumpVarParallelismStr "Dump VarParallelism to a string"
  input DAE.VarParallelism inVarParallelism;
  output String outString;
algorithm
  outString := match (inVarParallelism)
    case DAE.NON_PARALLEL() then "";
    case DAE.PARGLOBAL() then "parglobal ";
    case DAE.PARLOCAL() then "parlocal ";
  end match;
end dumpVarParallelismStr;

public function topLevelInput "author: PA
  if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level return true."
  input DAE.ComponentRef componentRef;
  input DAE.VarDirection varDirection;
  input DAE.ConnectorType connectorType;
  input DAE.VarVisibility visibility = DAE.PUBLIC();
  output Boolean isTopLevel;
algorithm
  isTopLevel := match (varDirection, componentRef, visibility)
    case (          _,                _, DAE.PROTECTED()) then false;
    case (DAE.INPUT(), DAE.CREF_IDENT(),               _) then true;
    case (DAE.INPUT(),                _,               _)
      guard(ConnectUtil.faceEqual(ConnectUtil.componentFaceType(componentRef), Connect.OUTSIDE()))
      then topLevelConnectorType(connectorType);
    else false;
  end match;
end topLevelInput;

public function topLevelOutput "author: PA
  if variable is output declared at the top level of the model,
  or if it is an output in a connector instance at top level return true."
  input DAE.ComponentRef componentRef;
  input DAE.VarDirection varDirection;
  input DAE.ConnectorType connectorType;
  output Boolean isTopLevel;
algorithm
  isTopLevel := match (varDirection, componentRef)
    case (DAE.OUTPUT(), DAE.CREF_IDENT()) then true;
    case (DAE.OUTPUT(), _)
      guard(ConnectUtil.faceEqual(ConnectUtil.componentFaceType(componentRef), Connect.OUTSIDE()))
      then topLevelConnectorType(connectorType);
    else false;
  end match;
end topLevelOutput;

protected function topLevelConnectorType
  input DAE.ConnectorType inConnectorType;
  output Boolean isTopLevel;
algorithm
  isTopLevel := match (inConnectorType)
    case DAE.FLOW() then true;
    case DAE.POTENTIAL() then true;
    else false;
  end match;
end topLevelConnectorType;

public function expTypeSimple "returns true if type is simple type"
  input DAE.Type tp;
  output Boolean isSimple;
algorithm
  isSimple := match(tp)
    case(DAE.T_REAL()) then true;
    case(DAE.T_INTEGER()) then true;
    case(DAE.T_STRING()) then true;
    case(DAE.T_BOOL()) then true;
    // BTH
    case(DAE.T_CLOCK()) then true;
    case(DAE.T_ENUMERATION()) then true;
    else false;
  end match;
end expTypeSimple;

public function expTypeElementType "returns the element type of an array"
  input DAE.Type tp;
  output DAE.Type eltTp;
algorithm
  eltTp := match(tp)
    local
      DAE.Type ty;
    case (DAE.T_ARRAY(ty=ty)) then expTypeElementType(ty);
    else tp;
  end match;
end expTypeElementType;

public function expTypeComplex "returns true if type is complex type"
  input DAE.Type tp;
  output Boolean isComplex;
algorithm
  isComplex := match(tp)
    case(DAE.T_COMPLEX()) then true;
    else false;
  end match;
end expTypeComplex;

public function expTypeArray "returns true if type is array type
Alternative names: isArrayType, isExpTypeArray"
  input DAE.Type tp;
  output Boolean isArray;
algorithm
  isArray := match(tp)
    case(DAE.T_ARRAY()) then true;
    else false;
  end match;
end expTypeArray;

public function expTypeTuple
"returns true if type is tuple type."
  input DAE.Type tp;
  output Boolean isTuple;
algorithm
  isTuple := match(tp)
    case(DAE.T_TUPLE()) then true;
    else false;
  end match;
end expTypeTuple;

public function expTypeArrayDimensions "returns the array dimensions of an ExpType"
  input DAE.Type tp;
  output list<Integer> dims;
algorithm
  dims := match(tp)
    local DAE.Dimensions array_dims;
    case(DAE.T_ARRAY(dims=array_dims)) equation
      dims = List.map(array_dims, Expression.dimensionSize);
    then dims;
  end match;
end expTypeArrayDimensions;

public function dimExp
 "Converts a dimension to an expression, covering constants and paramters."
  input DAE.Dimension dim;
  output DAE.Exp exp;
algorithm
  exp := match dim
    local
      Integer iconst;
    case DAE.DIM_INTEGER(iconst) then
      DAE.ICONST(iconst);
    case DAE.DIM_EXP(exp) then
      exp;
    else algorithm
      Error.addMessage(Error.DIMENSION_NOT_KNOWN, {anyString(dim)});
    then fail();
  end match;
end dimExp;

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
  oattr := match(bindExp,attr)
    local
      Option<DAE.Exp> e1,e2,e3,e4,e5,e6,so,min,max;
      Option<DAE.StateSelect> sSelectOption,sSelectOption2;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOption;
      Option<Boolean> ip,fn;
      String s;

    case (_,SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,max,e4,e5,e6,sSelectOption,unc,distOption,_,ip,fn,so)))
      then (SOME(DAE.VAR_ATTR_REAL(e1,e2,e3,min,max,e4,e5,e6,sSelectOption,unc,distOption,SOME(bindExp),ip,fn,so)));

    case (_,SOME(DAE.VAR_ATTR_INT(e1,min,max,e2,e3,unc,distOption,_,ip,fn,so)))
      then SOME(DAE.VAR_ATTR_INT(e1,min,max,e2,e3,unc,distOption,SOME(bindExp),ip,fn,so));

    case (_,SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_BOOL(e1,e2,e3,SOME(bindExp),ip,fn,so));

    case (_,SOME(DAE.VAR_ATTR_STRING(e1,e2,e3,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_STRING(e1,e2,e3,SOME(bindExp),ip,fn,so));

    case (_,SOME(DAE.VAR_ATTR_ENUMERATION(e1,min,max,e2,e3,_,ip,fn,so)))
      then SOME(DAE.VAR_ATTR_ENUMERATION(e1,min,max,e2,e3,SOME(bindExp),ip,fn,so));

    else equation print("-failure in DAEUtil.addEquationBoundString\n"); then fail();
  end match;
end addEquationBoundString;

public function getClassList "get list of classes from Var"
  input DAE.Element v;
  output list<Absyn.Path> lst;
algorithm
  lst := match(v)
    case DAE.VAR(source = DAE.SOURCE(typeLst=lst)) then lst;
    else {};
  end match;
end getClassList;

public function getBoundStartEquation "
Returned bound equation"
  input DAE.VariableAttributes attr;
  output DAE.Exp oe;
algorithm
  oe := match(attr)
    local DAE.Exp beq;
    case (DAE.VAR_ATTR_REAL(equationBound = SOME(beq))) then beq;
    case (DAE.VAR_ATTR_INT(equationBound = SOME(beq))) then beq;
    case (DAE.VAR_ATTR_BOOL(equationBound = SOME(beq))) then beq;
    case (DAE.VAR_ATTR_ENUMERATION(equationBound = SOME(beq))) then beq;
  end match;
end getBoundStartEquation;

public function splitDAEIntoVarsAndEquations
"Splits the DAE into one with vars and no equations and algorithms
 and another one which has all the equations and algorithms but no variables.
 Note: the functions are copied to both dae's.
 "
  input DAE.DAElist inDae;
  output DAE.DAElist allVars;
  output DAE.DAElist allEqs;
protected
  list<DAE.Element> rest;
  DoubleEnded.MutableList<DAE.Element> vars, eqs;
algorithm
  DAE.DAE(rest) := inDae;
  vars := DoubleEnded.fromList({});
  eqs := DoubleEnded.fromList({});
  for elt in rest loop
    _ := match elt
      local
        DAE.Element v,e;
        list<DAE.Element> elts,elts2,elts22,elts1,elts11,elts3,elts33;
        String  id;
        DAE.ElementSource source "the origin of the element";
        Option<SCode.Comment> cmt;

      case DAE.VAR()
        algorithm
          DoubleEnded.push_back(vars, elt);
        then ();

      // adrpo: TODO! FIXME! a DAE.COMP SHOULD NOT EVER BE HERE!
      case DAE.COMP(id,elts1,source,cmt)
        algorithm
          (DAE.DAE(elts11),DAE.DAE(elts3)) := splitDAEIntoVarsAndEquations(DAE.DAE(elts1));
          DoubleEnded.push_back(vars, DAE.COMP(id,elts11,source,cmt));
          DoubleEnded.push_list_back(eqs, elts3);
        then ();

      case DAE.EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.EQUEQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIALEQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.ARRAY_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIAL_ARRAY_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.COMPLEX_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIAL_COMPLEX_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIALDEFINE()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.DEFINE()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.WHEN_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.FOR_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.IF_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIAL_IF_EQUATION()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.ALGORITHM()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIALALGORITHM()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      // adrpo: TODO! FIXME! why are external object constructor calls added to the non-equations DAE??
      // PA: are these external object constructor CALLS? Do not think so. But they should anyway be in funcs..
      case DAE.EXTOBJECTCLASS()
        algorithm
          DoubleEnded.push_back(vars, elt);
        then ();

      case DAE.ASSERT()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIAL_ASSERT()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.TERMINATE()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIAL_TERMINATE()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.REINIT()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      // handle also NORETCALL! Connections.root(...)
      case DAE.NORETCALL()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      case DAE.INITIAL_NORETCALL()
        algorithm
          DoubleEnded.push_back(eqs, elt);
        then ();

      else
        algorithm
          Error.addInternalError(getInstanceName() + " failed for " + DAEDump.dumpDAEElementsStr(DAE.DAE({elt})), sourceInfo());
        then fail();
    end match;
  end for;
  allVars := DAE.DAE(DoubleEnded.toListAndClear(vars));
  allEqs := DAE.DAE(DoubleEnded.toListAndClear(eqs));
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

    case (_, {}) then dae;

    case (DAE.DAE(elements), _)
      equation
        elements = removeVariablesFromElements(elements, vars);
      then
        DAE.DAE(elements);

  end match;
end removeVariables;

protected function removeVariablesFromElements
"@author: adrpo
  remove the variables that match for the element list"
  input list<DAE.Element> inElements;
  input list<DAE.ComponentRef> variableNames;
  output list<DAE.Element> outElements = {};
algorithm
  if listEmpty(variableNames) then
    outElements := inElements;
    return;
  end if;
  for el in inElements loop
    _ := match el
      local
        DAE.ComponentRef cr;
        list<DAE.Element> elist;
        DAE.Element v;
        String id;
        DAE.ElementSource source "the origin of the element";
        Option<SCode.Comment> cmt;
        Boolean isEmpty;

      case (v as DAE.VAR(componentRef = cr))
        equation
          // variable is in the list! jump over it
          if listEmpty(List.select1(variableNames, ComponentReference.crefEqual, cr)) then
            outElements = v::outElements;
          end if;
          then ();

      // handle components
      case DAE.COMP(id,elist,source,cmt)
        equation
          elist = removeVariablesFromElements(elist, variableNames);
          outElements = DAE.COMP(id,elist,source,cmt)::outElements;
        then ();

      // anything else, just keep it
      else
        equation
          outElements = el::outElements;
        then ();
    end match;
  end for;
  outElements := MetaModelica.Dangerous.listReverseInPlace(outElements);
end removeVariablesFromElements;

protected function removeVariable "Remove the variable from the DAE, UNUSED"
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

    case(_,DAE.DAE((DAE.VAR(componentRef = cr))::elist))
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
  outDae := match(var,dae)
    local
      DAE.ComponentRef cr,oldVar,newVar;
      list<DAE.Element> elist,elist2;
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
    case(_,DAE.DAE(DAE.VAR(oldVar,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,(Absyn.INNER_OUTER()))::elist))
      guard
        compareUniquedVarWithNonUnique(var,oldVar)
      equation
        newVar = nameInnerouterUniqueCref(oldVar);
        o = DAE.VAR(oldVar,kind,dir,prl,prot,tp,NONE(),dim,ct,source,attr,cmt,Absyn.OUTER()) "intact";
        u = DAE.VAR(newVar,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,Absyn.NOT_INNER_OUTER()) " unique'ified";
        elist= u::o::elist;
      then
        DAE.DAE(elist);

    case(_,DAE.DAE(DAE.VAR(cr,kind,dir,prl,prot,tp,bind,dim,ct,source,attr,cmt,io)::elist))
      guard
        ComponentReference.crefEqualNoStringCompare(var,cr)
      equation
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
  end match;
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
      id = DAE.UNIQUEIO + id;
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
      print(ComponentReference.printComponentRefStr(child) + "\n");
      then fail();
  end matchcontinue;
end unNameInnerouterUniqueCref;

protected function removeInnerAttribute "Help function to removeInnerAttr"
   input Absyn.InnerOuter io;
   output Absyn.InnerOuter ioOut;
algorithm
  ioOut := match(io)
    case(Absyn.INNER()) then Absyn.NOT_INNER_OUTER();
    case(Absyn.INNER_OUTER()) then Absyn.OUTER();
    else io;
  end match;
end removeInnerAttribute;

public function varCref " returns the component reference of a variable"
  input DAE.Element elt;
  output DAE.ComponentRef cr;
algorithm
  DAE.VAR(componentRef = cr) := elt;
end varCref;

public function getVariableAttributes " gets the attributes of a DAE.Element that is VAR"
  input DAE.Element elt;
  output Option<DAE.VariableAttributes> variableAttributesOption;
algorithm
  DAE.VAR(variableAttributesOption=variableAttributesOption) := elt;
end getVariableAttributes;

public function getUnitAttr "
  Return the unit attribute"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm
  start := match (inVariableAttributesOption)
    local
      DAE.Exp u;
    case (SOME(DAE.VAR_ATTR_REAL(unit=SOME(u)))) then u;
    else DAE.SCONST("");
  end match;
end getUnitAttr;

public function getStartAttrEmpty "
  Return the start attribute."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  input DAE.Exp optExp;
  output DAE.Exp start;
algorithm
  start := match (inVariableAttributesOption,optExp)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(start = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_INT(start = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(start = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_STRING(start = SOME(r))),_) then r;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(start = SOME(r))),_) then r;
    else optExp;
  end match;
end getStartAttrEmpty;

public function getMinMax "
Author: BZ, returns a list of optional exp, {opt<Min> opt<Max} "
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output list<Option<DAE.Exp>> oExps;
algorithm
  oExps := match(inVariableAttributesOption)
  local
    Option<DAE.Exp> e1,e2;

    case(SOME(DAE.VAR_ATTR_ENUMERATION(min = e1, max = e2))) then {e1, e2};
    case(SOME(DAE.VAR_ATTR_INT(min = e1, max = e2))) then {e1, e2};
    case(SOME(DAE.VAR_ATTR_REAL(min = e1, max = e2))) then {e1, e2};
  else {};

  end match;
end getMinMax;

public function getMinMaxValues
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output Option<DAE.Exp> outMinValue;
  output Option<DAE.Exp> outMaxValue;
algorithm
  (outMinValue, outMaxValue) := match(inVariableAttributesOption)
  local
    Option<DAE.Exp> minValue, maxValue;

    case(SOME(DAE.VAR_ATTR_ENUMERATION(min = minValue, max = maxValue)))
  then (minValue, maxValue);

    case(SOME(DAE.VAR_ATTR_INT(min = minValue, max = maxValue)))
  then (minValue, maxValue);

    case(SOME(DAE.VAR_ATTR_REAL(min = minValue, max = maxValue)))
  then (minValue, maxValue);

  else (NONE(), NONE());
  end match;
end getMinMaxValues;

public function setMinMax
  "Sets the min and max attributes. If inAttr is NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> inAttr;
  input Option<DAE.Exp> inMin;
  input Option<DAE.Exp> inMax;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match(inAttr, inMin, inMax)
    local
      Option<DAE.Exp> q,u,du,f,n,i;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
      Option<DAE.Exp> so;
      Option<DAE.Exp> min,max;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,ip,fn,so)), _, _)
      then if referenceEq(min,inMin) and referenceEq(max,inMax) then inAttr else SOME(DAE.VAR_ATTR_REAL(q,u,du,inMin,inMax,i,f,n,ss,unc,distOpt,eb,ip,fn,so));

    case (SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,ip,fn,so)), _, _)
      then if referenceEq(min,inMin) and referenceEq(max,inMax) then inAttr else SOME(DAE.VAR_ATTR_INT(q,inMin,inMax,i,f,unc,distOpt,eb,ip,fn,so));

    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,ip,fn,so)), _, _)
      then if referenceEq(min,inMin) and referenceEq(max,inMax) then inAttr else SOME(DAE.VAR_ATTR_ENUMERATION(q,inMin,inMax,u,du,eb,ip,fn,so));

    case (NONE(), _, _)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),inMin,inMax,NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setMinMax;

public function getStartAttr "
  Return the start attribute."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm
  start := match(inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(start = SOME(r)))) then r;
    else DAE.RCONST(0.0);
  end match;
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
    case (SOME(DAE.VAR_ATTR_REAL(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(start = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(start = SOME(r)))) then r;
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

public function getMinAttrFail "
  Return the min attribute. or fails"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp outMin;
algorithm
  SOME(DAE.VAR_ATTR_REAL(min = SOME(outMin))) := inVariableAttributesOption;
end getMinAttrFail;

public function getMaxAttrFail "
  Return the max attribute. or fails"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp outMax;
algorithm
  SOME(DAE.VAR_ATTR_REAL(max = SOME(outMax))) := inVariableAttributesOption;
end getMaxAttrFail;

public function setVariableAttributes "sets the attributes of a DAE.Element that is VAR"
  input DAE.Element var;
  input Option<DAE.VariableAttributes> varOpt;
  output DAE.Element v = var;
algorithm
  v := match v
    case DAE.VAR()
      algorithm
        v.variableAttributesOption := varOpt;
      then v;
  end match;
end setVariableAttributes;

public function setStateSelect "
  sets the stateselect attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.StateSelect s;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match attr
    local
      DAE.VariableAttributes va;
    case SOME(va as DAE.VAR_ATTR_REAL())
      algorithm
        va.stateSelectOption := SOME(s);
      then SOME(va);
    case NONE()
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(s),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setStateSelect;

public function setStartAttr "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := setStartAttrOption(attr,SOME(start));
end setStartAttr;

public function setStartAttrOption "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match attr
    local
      DAE.VariableAttributes va;
      Option<DAE.VariableAttributes> at;
    case SOME(va as DAE.VAR_ATTR_REAL())
      algorithm
        if valueEq(va.start, start) then
          at := attr;
        else
          va.start := start;
          at := SOME(va);
        end if;
      then at;
    case SOME(va as DAE.VAR_ATTR_INT())
      algorithm
        if valueEq(va.start, start) then
          at := attr;
        else
          va.start := start;
          at := SOME(va);
        end if;
      then at;
    case SOME(va as DAE.VAR_ATTR_BOOL())
      algorithm
        if valueEq(va.start, start) then
          at := attr;
        else
          va.start := start;
          at := SOME(va);
        end if;
      then at;
    case SOME(va as DAE.VAR_ATTR_STRING())
      algorithm
        if valueEq(va.start, start) then
          at := attr;
        else
          va.start := start;
          at := SOME(va);
        end if;
      then at;
    case SOME(va as DAE.VAR_ATTR_ENUMERATION())
      algorithm
        if valueEq(va.start, start) then
          at := attr;
        else
          va.start := start;
          at := SOME(va);
        end if;
      then at;
    case NONE()
      then if isNone(start) then NONE() else SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),start,NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setStartAttrOption;

public function setStartOrigin "
  sets the startOrigin attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Option<DAE.Exp> startOrigin;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match attr
    local
      DAE.VariableAttributes va;
    case SOME(va as DAE.VAR_ATTR_REAL())
      algorithm
        va.startOrigin := startOrigin;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_INT())
      algorithm
        va.startOrigin := startOrigin;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_BOOL())
      algorithm
        va.startOrigin := startOrigin;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_STRING())
      algorithm
        va.startOrigin := startOrigin;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_ENUMERATION())
      algorithm
        va.startOrigin := startOrigin;
      then SOME(va);
    case NONE()
      then if isNone(startOrigin) then NONE() else SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),startOrigin));
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
    else DAE.RCONST(1.0);
  end match;
end getNominalAttr;

public function setNominalAttr "
  sets the nominal attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp nominal;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := match attr
    local
      DAE.VariableAttributes va;
    case SOME(va as DAE.VAR_ATTR_REAL())
      algorithm
        va.nominal := SOME(nominal);
      then SOME(va);
    case NONE()
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(nominal),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
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
      Option<DAE.Exp> q,u,du,f,n,s,so,min,max;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,_,du,min,max,s,f,n,ss,unc,distOpt,eb,ip,fn,so)),_)
      then SOME(DAE.VAR_ATTR_REAL(q,SOME(unit),du,min,max,s,f,n,ss,unc,distOpt,eb,ip,fn,so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),SOME(unit),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE()));
  end match;
end setUnitAttr;

public function setElementVarVisibility "
  This function takes a VAR elemets and sets var visibility."
  input DAE.Element elt;
  input DAE.VarVisibility visibility;
  output DAE.Element e = elt;
algorithm
  e := match e
    case DAE.VAR()
      algorithm
        e.protection := visibility;
      then e;
    else e;
  end match;
end setElementVarVisibility;

public function setElementVarDirection "
  This function takes a VAR elemets and sets var direction."
  input DAE.Element elt;
  input DAE.VarDirection direction;
  output DAE.Element e = elt;
algorithm
  e := match e
    case DAE.VAR()
      algorithm
        e.direction := direction;
      then e;
    else e;
  end match;
end setElementVarDirection;

public function setElementVarBinding
  "Sets the binding of a VAR DAE.Element."
  input DAE.Element elt;
  input Option<DAE.Exp> binding;
  output DAE.Element e = elt;
algorithm
  e := match e
    case DAE.VAR()
      algorithm
        e.binding := binding;
      then e;
    else e;
  end match;
end setElementVarBinding;

public function setProtectedAttr "
  sets the start attribute. If NONE(), assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input Boolean isProtected;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  match (attr)
    local
      Option<DAE.Exp> q,u,du,i,f,n,so,min,max;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,_,fn,so)))
      then SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,_,fn,so)))
      then SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,_,fn,so)))
      then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,f,eb,_,fn,so)))
      then SOME(DAE.VAR_ATTR_STRING(q,i,f,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,_,fn,so)))
      then SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_CLOCK(fn,_)))
      then SOME(DAE.VAR_ATTR_CLOCK(fn,SOME(isProtected)));
    case (NONE())
      // lochel: maybe we should let this case just fail
      then setProtectedAttr(SOME(DAE.emptyVarAttrReal), isProtected);
  end match;
end setProtectedAttr;

public function getProtectedAttr "
  retrieves the protected attribute form VariableAttributes."
  input Option<DAE.VariableAttributes> attr;
  output Boolean isProtected;
algorithm
  isProtected := match(attr)
    case (SOME(DAE.VAR_ATTR_REAL(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_INT(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_BOOL(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_STRING(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_ENUMERATION(isProtected=SOME(isProtected)))) then isProtected;
    case (SOME(DAE.VAR_ATTR_CLOCK(isProtected=SOME(isProtected)))) then isProtected;
    else false;
  end match;
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
      Option<DAE.Exp> q,u,du,n,ini,so,min,max;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,ini,_,n,ss,unc,distOpt,eb,ip,fn,so)),_)
      then SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,ini,fixed,n,ss,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,min,max,ini,_,unc,distOpt,eb,ip,fn,so)),_)
      then SOME(DAE.VAR_ATTR_INT(q,min,max,ini,fixed,unc,distOpt,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,ini,_,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,ini,fixed,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,ini,_,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,ini,fixed,eb,ip,fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,_,eb,ip,fn,so)),_)
      then SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,fixed,eb,ip,fn,so));
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
      Option<DAE.Exp> q,u,du,i,f,n,so,min,max;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,ip,_,so)),_)
      then SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,ip,SOME(finalPrefix),so));
    case (SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,ip,_,so)),_)
      then SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,ip,SOME(finalPrefix),so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,ip,SOME(finalPrefix),so));
    // BTH
    case (SOME(DAE.VAR_ATTR_CLOCK(ip,_)),_)
      then SOME(DAE.VAR_ATTR_CLOCK(ip,SOME(finalPrefix)));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,f,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,i,f,eb,ip,SOME(finalPrefix),so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,ip,_,so)),_)
      then SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,ip,SOME(finalPrefix),so));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(finalPrefix),NONE()));
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
    case (SOME(DAE.VAR_ATTR_CLOCK(finalPrefix=SOME(b)))) then b;
  else false;
  end match;
end getFinalAttr;

public function boolVarVisibility "Function: boolVarVisibility
Takes a DAE.varprotection and returns true/false (is_protected / not)"
  input DAE.VarVisibility vp;
  output Boolean prot;
algorithm
  prot := match(vp)
    case(DAE.PUBLIC()) then false;
    case(DAE.PROTECTED()) then true;
    else equation print("- DAEUtil.boolVarVisibility failed\n"); then fail();
  end match;
end boolVarVisibility;

public function hasStartAttr "
  Returns true if variable attributes defines a start value."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output Boolean hasStart;
algorithm
  hasStart:= match(inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(start = SOME(_)))) then true;
    case (SOME(DAE.VAR_ATTR_INT(start = SOME(_)))) then true;
    case (SOME(DAE.VAR_ATTR_BOOL(start = SOME(_)))) then true;
    case (SOME(DAE.VAR_ATTR_STRING(start = SOME(_)))) then true;
    else false;
  end match;
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
    case (SOME(DAE.VAR_ATTR_REAL(start = SOME(r))))
      equation
        s = ExpressionDump.printExpStr(r);
      then
        s;
    case (SOME(DAE.VAR_ATTR_INT(start = SOME(r))))
      equation
        s = ExpressionDump.printExpStr(r);
      then
        s;
    else "";
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
    output Boolean outMatch;
  end FuncTypeElementTo;
algorithm
  oelist := List.filterOnTrue(elist, cond);
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
    case(_::elist2,_)
      then getAllMatchingElements(elist2,cond);
  end matchcontinue;
end getAllMatchingElements;

public function findAllMatchingElements "author:  adrpo
  Similar to getMatchingElements but gets two conditions and returns two lists. The functions are copied to both."
  input DAE.DAElist dae;
  input CondFunc cond1;
  input CondFunc cond2;
  output DAE.DAElist firstList;
  output DAE.DAElist secondList;

  partial function CondFunc
    input DAE.Element element;
    output Boolean result;
  end CondFunc;
protected
  list<DAE.Element> elements, el1, el2;
algorithm
  DAE.DAE(elementLst = elements) := dae;
  (el1, el2) := findAllMatchingElements2(elements, cond1, cond2);
  firstList := DAE.DAE(MetaModelica.Dangerous.listReverseInPlace(el1));
  secondList := DAE.DAE(MetaModelica.Dangerous.listReverseInPlace(el2));
end findAllMatchingElements;

protected function findAllMatchingElements2
  input list<DAE.Element> elements;
  input CondFunc cond1;
  input CondFunc cond2;
  input list<DAE.Element> accumFirst = {};
  input list<DAE.Element> accumSecond = {};
  output list<DAE.Element> firstList = accumFirst;
  output list<DAE.Element> secondList = accumSecond;

  partial function CondFunc
    input DAE.Element element;
    output Boolean result;
  end CondFunc;
algorithm
  for e in elements loop
    _ := match e
      case DAE.COMP()
        algorithm
          (firstList, secondList) :=
            findAllMatchingElements2(e.dAElist, cond1, cond2, firstList, secondList);
        then
          ();

      else
        algorithm
          if cond1(e) then
            firstList := e :: firstList;
          end if;

          if cond2(e) then
            secondList := e :: secondList;
          end if;
        then
          ();

    end match;
  end for;
end findAllMatchingElements2;

public function isAfterIndexInlineFunc "
Author BZ
"
input DAE.Function inElem;
output Boolean b;
algorithm
  b := match(inElem)
    case(DAE.FUNCTION(inlineType=DAE.AFTER_INDEX_RED_INLINE())) then true;
    else false;
  end match;
end isAfterIndexInlineFunc;

public function isParameter "author: LS
  True if element is parameter.
"
  input DAE.Element inElement;
  output Boolean outB;
algorithm
  outB :=
  match (inElement)
    case DAE.VAR(kind = DAE.PARAM()) then true;
    else false;
  end match;
end isParameter;

public function isParameterOrConstant "
  author: BZ 2008-06
  Succeeds if element is constant/parameter.
"
  input DAE.Element inElement;
  output Boolean b;
algorithm
  b := match(inElement)
    case DAE.VAR(kind = DAE.CONST()) then true;
    case DAE.VAR(kind = DAE.PARAM()) then true;
    else false;
  end match;
end isParameterOrConstant;

public function isParamOrConstVar
  input DAE.Var inVar;
  output Boolean outIsParamOrConst;
protected
  SCode.Variability var;
algorithm
  DAE.TYPES_VAR(attributes = DAE.ATTR(variability = var)) := inVar;
  outIsParamOrConst := SCodeUtil.isParameterOrConst(var);
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

public function isInnerVar
  "Returns true if the element is an inner variable."
  input DAE.Element element;
  output Boolean isInner;
algorithm
  isInner := match element
    case DAE.VAR() then AbsynUtil.isInner(element.innerOuter);
    else false;
  end match;
end isInnerVar;

public function isOuterVar
  "Returns true if the element is an outer variable."
  input DAE.Element element;
  output Boolean isOuter;
algorithm
  isOuter := match element
    case DAE.VAR(innerOuter = Absyn.OUTER()) then true;
    // FIXME? adrpo: do we need this?
    // case DAE.VAR(innerOuter = Absyn.INNER_OUTER()) then true;
    else false;
  end match;
end isOuterVar;

public function isComp "author: LS

  Succeeds if element is component, COMP.
"
  input DAE.Element inElement;
algorithm
  _:=
  match (inElement)
    case DAE.COMP() then ();
  end match;
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
  vl_1 := getMatchingElements(vl, isProtectedVar);
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
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.OUTPUT()) then true;
    else false;
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
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.VAR(protection=DAE.PUBLIC()) then true;
    else false;
  end match;
end isPublicVar;

public function isBidirVar "
  Succeeds if Element is a bidirectional variable.
"
  input DAE.Element inElement;
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.BIDIR()) then true;
    else false;
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
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.INPUT()) then true;
    else false;
  end match;
end isInputVar;

public function isInput "
  Succeeds if Element is an input .
"
  input DAE.Element inElement;
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.VAR(direction = DAE.INPUT()) then true;
    else false;
  end match;
end isInput;

public function isNotVar
  "Returns true if the element is not a variable, otherwise false."
  input DAE.Element e;
  output Boolean outMatch;
algorithm
  outMatch := match e
    case DAE.VAR(__) then false;
    else true;
  end match;
end isNotVar;

public function isVar
  "Returns true if the element is a variable, otherwise false."
  input DAE.Element inElement;
  output Boolean outMatch;
algorithm
  outMatch := match inElement
    case DAE.VAR(__) then true;
    else false;
  end match;
end isVar;

public function isFunctionRefVar "
  return true if the element is a function reference variable"
  input DAE.Element inElem;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inElem)
    case DAE.VAR(ty = DAE.T_FUNCTION()) then true;
    else false;
  end match;
end isFunctionRefVar;

function isComment
  input DAE.Element elt;
  output Boolean b;
algorithm
  b := match elt
    case DAE.COMMENT(__) then true;
    else false;
  end match;
end isComment;

public function isAlgorithm "author: LS
  Succeeds if Element is an algorithm."
  input DAE.Element inElement;
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.ALGORITHM(__) then true;
    else false;
  end match;
end isAlgorithm;

public function isStmtAssert" outputs true if the stmt is an assert.
author:Waurich TUD 2014-04"
  input DAE.Statement stmt;
  output Boolean b;
algorithm
  b := match(stmt)
    case DAE.STMT_ASSERT(__) then true;
    else false;
  end match;
end isStmtAssert;

public function isStmtReturn" outputs true if the stmt is a return.
author:Waurich TUD 2014-04"
  input DAE.Statement stmt;
  output Boolean b;
algorithm
  b := match(stmt)
    case DAE.STMT_RETURN(__) then true;
    else false;
  end match;
end isStmtReturn;

public function isStmtReinit" outputs true if the stmt is a reinit.
author:Waurich TUD 2014-04"
  input DAE.Statement stmt;
  output Boolean b;
algorithm
  b := match(stmt)
    case DAE.STMT_REINIT(__) then true;
    else false;
  end match;
end isStmtReinit;

public function isStmtTerminate" outputs true if the stmt is a terminate.
author:Waurich TUD 2014-04"
  input DAE.Statement stmt;
  output Boolean b;
algorithm
  b := match(stmt)
    case DAE.STMT_TERMINATE(__) then true;
    else false;
  end match;
end isStmtTerminate;

public function isComplexEquation "author: LS
  Succeeds if Element is an complex equation."
  input DAE.Element inElement;
  output Boolean outMatch;
algorithm
  outMatch := match (inElement)
    case DAE.COMPLEX_EQUATION(__) then true;
    else false;
  end match;
end isComplexEquation;

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
  outElementOption:= match (inElementLst,inFuncTypeElementTo)
    local
      DAE.Element e;
      list<DAE.Element> rest;
      FuncTypeElementTo f;
      Option<DAE.Element> e_1;

    case ({},_) then NONE();

    case (e::rest, f)
      equation
        e_1 = matchcontinue ()
          case ()
            equation
              f(e);
            then SOME(e);
          else
            equation
              failure(f(e));
              e_1 = findElement(rest, f);
            then e_1;
        end matchcontinue;
      then
        e_1;

  end match;
end findElement;

public function getVariableBindingsStr "
  This function takes a `DAE.Element\' list and returns a comma separated
  string of variable bindings.
  E.g. model A Real x=1; Real y=2; end A; => \"1,2\"
"
  input list<DAE.Element> elts;
  output String str;
protected
  list<DAE.Element> varlst, els;
algorithm
  str := match elts
    case {DAE.COMP(dAElist = els)} then getVariableBindingsStr(els);
    else
     algorithm
       varlst := getVariableList(elts);
       str := getBindingsStr(varlst);
     then str;
  end match;
end getVariableBindingsStr;

protected function getVariableList "
  Return all variables from an Element list.
"
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  /* adrpo: filter out records! */
  outElementLst := list(e for e guard match e
      case DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_))) then false;
      case DAE.VAR() then true;
      else false;
    end match in inElementLst);
end getVariableList;

public function getVariableType
"function: getVariableType
  Return the type of a variable, otherwise fails.
"
  input DAE.Element inElement;
  output DAE.Type outType;
algorithm
  outType := match (inElement)
    local
      DAE.Type tp;

    case (DAE.VAR(ty = tp)) then tp;

    else fail();
  end match;
end getVariableType;

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
    case (((DAE.VAR(binding = SOME(e)))::(lst as (_::_))))
      equation
        expstr = ExpressionDump.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((DAE.VAR(binding = NONE()))::(lst as (_::_))))
      equation
        s1 = "-,";
        s2 = getBindingsStr(lst);
        str = stringAppend(s1, s2);
      then
        str;
    case ({(DAE.VAR(binding = SOME(e)))})
      equation
        str = ExpressionDump.printExpStr(e);
      then
        str;
    case ({(DAE.VAR(binding = NONE()))}) then "";
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
    case (DAE.VAR(binding  = NONE())::rest)
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
    case (SCode.STREAM(), _) then DAE.STREAM(NONE());
    case (_, ClassInf.CONNECTOR()) then DAE.POTENTIAL();
    else DAE.NON_CONNECTOR();
  end match;
end toConnectorType;

public function toConnectorTypeNoState
 input SCode.ConnectorType scodeConnectorType;
 input Option<DAE.ComponentRef> flowName = NONE();
 output DAE.ConnectorType daeConnectorType;
algorithm
  daeConnectorType := match scodeConnectorType
    case SCode.FLOW() then DAE.FLOW();
    case SCode.STREAM() then DAE.STREAM(flowName);
    else DAE.POTENTIAL();
  end match;
end toConnectorTypeNoState;

public function toDaeParallelism "Converts scode parallelsim to dae parallelism.
  Prints a warning if parallel variables are used
  in a non-function class."
  input DAE.ComponentRef inCref;
  input SCode.Parallelism inParallelism;
  input ClassInf.State inState;
  input SourceInfo inInfo;
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
        str1 = "\n" +
        "- DAEUtil.toDaeParallelism: parglobal component '" + ComponentReference.printComponentRefStr(inCref)
        + "' in non-function class: " + ClassInf.printStateStr(inState) + " " + AbsynUtil.pathString(path);

        Error.addSourceMessage(Error.PARMODELICA_WARNING,
          {str1}, inInfo);
      then DAE.PARGLOBAL();

    case (_, SCode.PARLOCAL(), _, _)
      equation
        path = ClassInf.getStateName(inState);
        str1 = "\n" +
        "- DAEUtil.toDaeParallelism: parlocal component '" + ComponentReference.printComponentRefStr(inCref)
        + "' in non-function class: " + ClassInf.printStateStr(inState) + " " + AbsynUtil.pathString(path);

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
    else false;
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
  match (inExpComponentRefLst,inIdent)
    local
      String id;
      list<DAE.ComponentRef> res,xs;
      DAE.ComponentRef cr_1,cr;
    case ({},_) then {};
    case ((cr::xs),id)
      equation
        res = getFlowVariables2(xs, id);
        cr_1 = ComponentReference.makeCrefQual(id,DAE.T_UNKNOWN_DEFAULT,{}, cr);
      then
        (cr_1::res);
  end match;
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
  match (inExpComponentRefLst,inIdent)
    local
      String id;
      list<DAE.ComponentRef> res,xs;
      DAE.ComponentRef cr_1,cr;
    case ({},_) then {};
    case ((cr::xs),id)
      equation
        res = getStreamVariables2(xs, id);
        cr_1 = ComponentReference.makeCrefQual(id,DAE.T_UNKNOWN_DEFAULT,{}, cr);
      then
        (cr_1::res);
  end match;
end getStreamVariables2;

public function daeToRecordValue "Transforms a list of elements into a record value.
  TODO: This does not work for records inside records.
  For a general approach we need to build an environment from the DAE and then
  instead investigate the variables and lookup their values from the created environment."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input Absyn.Path inPath;
  input list<DAE.Element> inElementLst;
  input Boolean inBoolean;
  output FCore.Cache outCache;
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
      FCore.Cache cache;
      FCore.Graph env;
      DAE.ElementSource source;
      SourceInfo info;

    case (cache,_,cname,{},_) then (cache,Values.RECORD(cname,{},{},-1));  /* impl */
    case (cache,env,cname,DAE.VAR(componentRef = cr, binding = SOME(rhs),
          source= source)::rest, impl)
      equation
        // fprintln(Flags.FAILTRACE, "- DAEUtil.daeToRecordValue typeOfRHS: " + ExpressionDump.typeOfString(rhs));
        info = ElementSource.getElementSourceFileInfo(source);
        (cache, value) = Ceval.ceval(cache, env, rhs, impl, Absyn.MSG(info),0);
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = ComponentReference.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value::vals),(cr_str::names),ix));
    case (_,_,_,el::_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = DAEDump.dumpDebugDAE(DAE.DAE({el}));
        Debug.traceln("- DAEUtil.daeToRecordValue failed on: " + str);
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
  match (inDAElist)
    local list<DAE.Element> elts_1,elts;
    case (DAE.DAE(elts))
      equation
        elts_1 = toModelicaFormElts(elts);
      then
        DAE.DAE(elts_1);
  end match;
end toModelicaForm;

protected function toModelicaFormElts "Helper function to toModelicaForm."
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst := match (inElementLst)
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
               comment = comment,
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

    case ((DAE.INITIAL_ASSERT(condition = e1,message=e2,level=e3,source = source)::elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
        e_2 = toModelicaFormExp(e2);
        e_3 = toModelicaFormExp(e3);
      then
        (DAE.INITIAL_ASSERT(e_1,e_2,e_3,source)::elts_1);

    case ((DAE.TERMINATE(message = e1,source = source)::elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
      then
        (DAE.TERMINATE(e_1,source)::elts_1);

    case ((DAE.INITIAL_TERMINATE(message = e1,source = source)::elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
      then
        (DAE.INITIAL_TERMINATE(e_1,source)::elts_1);
  end match;
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

    case(_, DAE.VAR(_,a2,a3,prl,a4,a5,a6,a7,ct,source,a11,a12,a13))
      then DAE.VAR(newCr,a2,a3,prl,a4,a5,a6,a7,ct,source,a11,a12,a13);
  end match;
end replaceCrefInVar;

public function replaceTypeInVar "
Author BZ
 Function for updating the Type of the Var"
  input DAE.Type newType;
  input DAE.Element inelem;
  output DAE.Element outelem;
algorithm
  outelem := match(newType, inelem)
    local
      DAE.ComponentRef a1; DAE.VarKind a2;
      DAE.VarDirection a3; DAE.VarParallelism prl;
      DAE.VarVisibility a4;
      DAE.Type a5; DAE.InstDims a7; DAE.ConnectorType ct;
      Option<DAE.Exp> a6;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> a11;
      Option<SCode.Comment> a12; Absyn.InnerOuter a13;

    case(_, DAE.VAR(a1,a2,a3,prl,a4,_,a6,a7,ct,source,a11,a12,a13))
      then DAE.VAR(a1,a2,a3,prl,a4,newType,a6,a7,ct,source,a11,a12,a13);
  end match;
end replaceTypeInVar;

public function replaceCrefandTypeInVar "
Author BZ
 Function for updating the Component Ref and the Type of the Var"
  input DAE.ComponentRef newCr;
  input DAE.Type newType;
  input DAE.Element inelem;
  output DAE.Element outelem;
algorithm
  outelem := match(newCr, newType, inelem)
    local
      DAE.ComponentRef a1; DAE.VarKind a2;
      DAE.VarDirection a3; DAE.VarParallelism prl;
      DAE.VarVisibility a4;
      DAE.Type a5; DAE.InstDims a7; DAE.ConnectorType ct;
      Option<DAE.Exp> a6;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> a11;
      Option<SCode.Comment> a12; Absyn.InnerOuter a13;

    case(_, _, DAE.VAR(_,a2,a3,prl,a4,_,a6,a7,ct,source,a11,a12,a13))
      equation
        outelem = DAE.VAR(newCr,a2,a3,prl,a4,newType,a6,a7,ct,source,a11,a12,a13);
      then outelem;
  end match;
end replaceCrefandTypeInVar;


public function replaceBindungInVar "
Author BZ
 Function for updating the Component Ref of the Var"
  input DAE.Exp newBindung;
  input DAE.Element inelem;
  output DAE.Element outelem;
algorithm
  outelem := match(newBindung, inelem)
    local
      DAE.ComponentRef a1; DAE.VarKind a2;
      DAE.VarDirection a3; DAE.VarParallelism prl;
      DAE.VarVisibility a4;
      DAE.Type a5; DAE.InstDims a7; DAE.ConnectorType ct;
      Option<DAE.Exp> a6;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> a11;
      Option<SCode.Comment> a12; Absyn.InnerOuter a13;

    case(_, DAE.VAR(a1,a2,a3,prl,a4,a5,_,a7,ct,source,a11,a12,a13))
      then DAE.VAR(a1,a2,a3,prl,a4,a5,SOME(newBindung),a7,ct,source,a11,a12,a13);
  end match;
end replaceBindungInVar;

protected function toModelicaFormExpOpt "Helper function to toMdelicaFormElts."
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption := match (inExpExpOption)
    local DAE.Exp e_1,e;
    case (SOME(e)) equation e_1 = toModelicaFormExp(e); then SOME(e_1);
    case (NONE()) then NONE();
  end match;
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

    case (_,_) then Util.getOption(DAE.AvlTreePathFunction.get(functions, path));
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        msg = stringDelimitList(List.mapMap(getFunctionList(functions), functionName, AbsynUtil.pathStringDefault), "\n  ");
        msg = "DAEUtil.getNamedFunction failed: " + AbsynUtil.pathString(path) + "\nThe following functions were part of the cache:\n  " + msg;
        // Error.addMessage(Error.INTERNAL_ERROR,{msg});
        Debug.traceln(msg);
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getNamedFunctionWithError "Return the FUNCTION with the given name. Fails if not found."
  input Absyn.Path path;
  input DAE.FunctionTree functions;
  input SourceInfo info;
  output DAE.Function outElement;
algorithm
  outElement := matchcontinue (path,functions,info)
    local
      String msg;

    case (_,_,_) then Util.getOption(DAE.AvlTreePathFunction.get(functions, path));
    else
      equation
        msg = stringDelimitList(List.mapMap(getFunctionList(functions), functionName, AbsynUtil.pathStringDefault), "\n  ");
        msg = "DAEUtil.getNamedFunction failed: " + AbsynUtil.pathString(path) + "\nThe following functions were part of the cache:\n  " + msg;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{msg},info);
      then fail();
  end matchcontinue;
end getNamedFunctionWithError;

public function getNamedFunctionFromList "Is slow; PartFn.mo should be rewritten using the FunctionTree"
  input Absyn.Path ipath;
  input list<DAE.Function> ifns;
  output DAE.Function fn;
algorithm
  fn := matchcontinue (ipath,ifns)
    local Absyn.Path path; list<DAE.Function> fns;
    case (path,fn::_)
      equation
        true = AbsynUtil.pathEqual(functionName(fn),path);
      then fn;
    case (path,_::fns) then getNamedFunctionFromList(path, fns);
    case (path,{})
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- DAEUtil.getNamedFunctionFromList failed " + AbsynUtil.pathString(path));
      then
        fail();
  end matchcontinue;
end getNamedFunctionFromList;

public function getFunctionVisibility
  input DAE.Function fn;
  output SCode.Visibility visibility;
algorithm
  visibility := match fn
    case DAE.FUNCTION(visibility = visibility) then visibility;
    else SCode.PUBLIC();
  end match;
end getFunctionVisibility;

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
    case DAE.RECORD_CONSTRUCTOR() then {};
  end match;
end getFunctionElements;

public function getFunctionType
  input DAE.Function fn;
  output DAE.Type outType;
algorithm
  outType := match fn
    local
      list<DAE.Element> elements;
    case DAE.FUNCTION(type_ = outType) then outType;
    case DAE.FUNCTION(type_ = outType) then outType;
    case DAE.RECORD_CONSTRUCTOR(type_ = outType) then outType;
  end match;
end getFunctionType;

public function getFunctionImpureAttribute
  input DAE.Function fn;
  output Boolean outImpure;
algorithm
  outImpure := match fn
    local
    case DAE.FUNCTION(isImpure = outImpure) then outImpure;
  end match;
end getFunctionImpureAttribute;

public function getFunctionInlineType
  input DAE.Function fn;
  output DAE.InlineType outInlineType;
algorithm
  outInlineType := match fn
    local
    case DAE.FUNCTION(inlineType = outInlineType) then outInlineType;
  end match;
end getFunctionInlineType;

public function getFunctionInputVars
  input DAE.Function fn;
  output list<DAE.Element> outEls;
protected
  list<DAE.Element> elements;
algorithm
  elements := getFunctionElements(fn);
  outEls := List.filterOnTrue(elements, isInputVar);
end getFunctionInputVars;

public function getFunctionOutputVars
  input DAE.Function fn;
  output list<DAE.Element> outEls;
protected
  list<DAE.Element> elements;
algorithm
  elements := getFunctionElements(fn);
  outEls := List.filterOnTrue(elements, isOutputVar);
end getFunctionOutputVars;

public function getFunctionProtectedVars
  input DAE.Function fn;
  output list<DAE.Element> outEls;
protected
  list<DAE.Element> elements;
algorithm
  elements := getFunctionElements(fn);
  outEls := List.filterOnTrue(elements, isProtectedVar);
end getFunctionProtectedVars;

public function getFunctionAlgorithms
  input DAE.Function fn;
  output list<DAE.Element> outEls;
protected
  list<DAE.Element> elements;
algorithm
  elements := getFunctionElements(fn);
  outEls := List.filterOnTrue(elements, isAlgorithm);
end getFunctionAlgorithms;

public function getFunctionAlgorithmStmts
  input DAE.Function fn;
  output list<DAE.Statement> bodyStmts;
protected
  list<DAE.Element> elements;
algorithm
  elements := getFunctionElements(fn);
  bodyStmts := List.mapFlat(List.filterOnTrue(elements, isAlgorithm), getStatement);
end getFunctionAlgorithmStmts;

public function getStatement
  input DAE.Element inElement;
  output list<DAE.Statement> outStatements;
algorithm
  (outStatements):=
  matchcontinue (inElement)
    local
      list<DAE.Statement> stmts;
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)))
    then
      stmts;
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Differentiatte.getStatement failed\n");
      then
        fail();
  end matchcontinue;
end getStatement;

public function getTupleSize "gets the size of a DAE.TUPLE"
  input DAE.Exp inExp;
  output Integer size;
algorithm
  size := match(inExp)
    local
      list<DAE.Exp> exps;
    case(DAE.TUPLE(exps))
      equation
        size = listLength(exps);
        then
          size;
    else
      then
        0;
  end match;
end getTupleSize;

public function getTupleExps "gets the list<DAE.Exp> of a DAE.TUPLE or the list of the exp if its not a tuple"
  input DAE.Exp inExp;
  output list<DAE.Exp> exps;
algorithm
  exps := match(inExp)
    local
    case(DAE.TUPLE(exps))
        then
          exps;
    else
      then
        {inExp};
  end match;
end getTupleExps;

protected function crefToExp "
  Makes an expression from a ComponentRef.
"
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp:= Expression.makeCrefExp(inComponentRef,DAE.T_UNKNOWN_DEFAULT);
end crefToExp;

public function verifyEquationsDAE "
  Perform some checks for DAE equations:
  1. Assert equations should be used only inside when equations;
  2. Bolean when equation should:
    2.1 not contain nested clocked or boolean when equations;
    2.2 not have clocked else-when parts;
    2.3 have component references on left side of its equations, and
        for each branch the set of left hand references should be same;
  3. Clocked when equation should not:
    3.1 contain nested clocked when equations;
    3.2 contain else-when parts;
    3.3 contain reinit equation(?);
  4. Initial when equation should not contain assert equation.
"
  input DAE.DAElist dae;
protected
  DAE.Exp cond;
  list<DAE.Element> dae_elts, eqs;
  Option<DAE.Element> ew;
  DAE.ElementSource source;
  DAE.Element el;
  SourceInfo info;
algorithm
  DAE.DAE(dae_elts) := dae;
  for el in dae_elts loop
    () := match el
      case DAE.WHEN_EQUATION(cond, eqs, ew, source)
        equation verifyWhenEquation(cond, eqs, ew, source);
        then ();
      case DAE.REINIT()
        equation
          info = ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(el));
          Error.addSourceMessageAndFail(Error.REINIT_NOT_IN_WHEN, {}, info);
        then ();
      else ();
    end match;
  end for;
end verifyEquationsDAE;

protected function verifyWhenEquation
  input DAE.Exp cond;
  input list<DAE.Element> eqs;
  input Option<DAE.Element> ew;
  input DAE.ElementSource source;
algorithm
  if Types.isClockOrSubTypeClock(Expression.typeof(cond))
    then verifyClockWhenEquation(cond, eqs, ew, source);
    else verifyBoolWhenEquation(cond, eqs, ew, source);
  end if;
end verifyWhenEquation;

protected function verifyClockWhenEquation
  input DAE.Exp cond;
  input list<DAE.Element> eqs;
  input Option<DAE.Element> ew;
  input DAE.ElementSource source;
protected
  SourceInfo info;
algorithm
  if not isNone(ew) then
    info := ElementSource.getElementSourceFileInfo(source);
    Error.addSourceMessageAndFail(Error.ELSE_WHEN_CLOCK, {}, info);
  end if;
  verifyClockWhenEquation1(eqs);
end verifyClockWhenEquation;

protected function verifyClockWhenEquation1
  input list<DAE.Element> inEqs;
protected
  DAE.Element el;
algorithm
  for el in inEqs loop
    () := match el
      local
        DAE.Exp cond;
        list<DAE.Element> eqs;
        Option<DAE.Element> ew;
        DAE.ElementSource source;
        SourceInfo info;
      case DAE.REINIT()
        equation
          info = ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(el));
          Error.addSourceMessageAndFail(Error.REINIT_NOT_IN_WHEN, {}, info);
        then ();
      case DAE.WHEN_EQUATION(cond, eqs, ew, source)
        equation
          if Types.isClockOrSubTypeClock(Expression.typeof(cond)) then
            info = ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(el));
            Error.addSourceMessageAndFail(Error.NESTED_CLOCKED_WHEN, {}, info);
          end if;
          verifyBoolWhenEquation(cond, eqs, ew, source);
        then ();
      else ();
    end match;
  end for;
end verifyClockWhenEquation1;

protected function verifyBoolWhenEquation
  input DAE.Exp inCond;
  input list<DAE.Element> inEqs;
  input Option<DAE.Element> inElseWhen;
  input DAE.ElementSource source;
protected
  list<DAE.ComponentRef> crefs1, crefs2;
  list<tuple<DAE.Exp, list<DAE.Element>>> whenBranches;
  tuple<DAE.Exp, list<DAE.Element>> whenBranch;
  DAE.Exp cond;
  list<DAE.Element> eqs;
  SourceInfo info;
algorithm
  crefs1 := verifyBoolWhenEquationBranch(inCond, inEqs);
  whenBranches := collectWhenEquationBranches(inElseWhen);
  for whenBranch in whenBranches loop
    (cond, eqs) := whenBranch;
    if Types.isClockOrSubTypeClock(Expression.typeof(cond)) then
      info := ElementSource.getElementSourceFileInfo(source);
      Error.addSourceMessageAndFail(Error.CLOCKED_WHEN_BRANCH, {}, info);
    end if;
    crefs2 := verifyBoolWhenEquationBranch(cond, eqs);
    crefs2 := List.unionOnTrue(crefs1, crefs2, ComponentReference.crefEqual);
    if listLength(crefs2) <> listLength(crefs1) then
      info := ElementSource.getElementSourceFileInfo(source);
      Error.addSourceMessageAndFail(Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, {}, info);
    end if;
  end for;
end verifyBoolWhenEquation;

protected function collectWhenEquationBranches
  input Option<DAE.Element> inElseWhen;
  input list<tuple<DAE.Exp, list<DAE.Element>>> inWhenBranches = {};
  output list<tuple<DAE.Exp, list<DAE.Element>>> outWhenBranches;
algorithm
  outWhenBranches := match inElseWhen
    local
      DAE.Exp cond;
      list<DAE.Element> eqs;
      Option<DAE.Element> ew;
      SourceInfo info;
      String msg;
      DAE.Element el;
    case NONE()
      then inWhenBranches;
    case SOME(DAE.WHEN_EQUATION(cond, eqs, ew, _))
      then collectWhenEquationBranches(ew, (cond, eqs)::inWhenBranches);
    case SOME(el)
      equation
        msg = "- DAEUtil.collectWhenEquationBranches failed on: " + DAEDump.dumpElementsStr({el});
        info = ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(el));
        Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, info);
      then fail();
  end match;
end collectWhenEquationBranches;

protected function verifyBoolWhenEquationBranch
  input DAE.Exp inCond;
  input list<DAE.Element> inEqs;
  output list<DAE.ComponentRef> crefs;
protected
  Boolean initCond = Expression.containsInitialCall(inCond);
algorithm
  crefs := verifyBoolWhenEquation1(inEqs, initCond);
end verifyBoolWhenEquationBranch;

protected function verifyBoolWhenEquation1
  input list<DAE.Element> inElems;
  input Boolean initCond;
  input list<DAE.ComponentRef> inCrefs = {};
  output list<DAE.ComponentRef> outCrefs;
algorithm
outCrefs := match inElems
    local
      list<DAE.Element> rest;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Exp> exps;
      list<DAE.ComponentRef> crefs;
      list<list<DAE.ComponentRef>> crefsLists;
      DAE.ElementSource source;
      SourceInfo info;
      DAE.Element el;
      list<DAE.Element> falseEqs;
      list<list<DAE.Element>> trueEqs;
      Boolean b;
      String msg;
    case {} then inCrefs;

    case DAE.VAR()::rest
      then verifyBoolWhenEquation1(rest, initCond, inCrefs);

    case DAE.DEFINE(componentRef = cr)::rest
      then verifyBoolWhenEquation1(rest, initCond, cr::inCrefs);

    case DAE.EQUATION(exp = e, source = source)::rest
      equation crefs = collectWhenCrefs1(e, source, inCrefs);
      then verifyBoolWhenEquation1(rest, initCond, crefs);

    case DAE.ARRAY_EQUATION(exp = e, source = source)::rest
      equation crefs = collectWhenCrefs1(e, source, inCrefs);
      then verifyBoolWhenEquation1(rest, initCond, crefs);

    case DAE.COMPLEX_EQUATION(lhs = e, source = source)::rest
      equation crefs = collectWhenCrefs1(e, source, inCrefs);
      then verifyBoolWhenEquation1(rest, initCond, crefs);

    case DAE.EQUEQUATION(cr1 = cr)::rest
      then verifyBoolWhenEquation1(rest, initCond, cr::inCrefs);

    case DAE.IF_EQUATION(equations2 = trueEqs, equations3 = falseEqs, source = source)::rest
      equation
        crefsLists = List.map2(trueEqs, verifyBoolWhenEquation1, initCond, {});
        crefs = verifyBoolWhenEquation1(falseEqs, initCond);
        crefsLists = crefs::crefsLists;
        (crefs, b) = compareCrefList(crefsLists);
        if not b then
          info = ElementSource.getElementSourceFileInfo(source);
          msg = "All branches must write to the same variable";
          Error.addSourceMessage(Error.WHEN_EQ_LHS, {msg}, info);
          fail();
        end if;
      then verifyBoolWhenEquation1(rest, initCond, listAppend(crefs, inCrefs));

    case DAE.ASSERT()::rest
      then verifyBoolWhenEquation1(rest, initCond, inCrefs);

    case DAE.TERMINATE()::rest
      then verifyBoolWhenEquation1(rest, initCond, inCrefs);

    case DAE.REINIT(source = source)::rest
      equation
        if initCond then
          info = ElementSource.getElementSourceFileInfo(source);
          Error.addSourceMessage(Error.REINIT_IN_WHEN_INITIAL, {}, info);
          fail();
        end if;
      then verifyBoolWhenEquation1(rest, initCond, inCrefs);

    // adrpo: TODO! FIXME! WHY??!! we might push values to a file writeFile(time);
    case DAE.NORETCALL()::rest
      then verifyBoolWhenEquation1(rest, initCond, inCrefs);

    case DAE.WHEN_EQUATION(condition = e, source=source)::_
      equation
        info = ElementSource.getElementSourceFileInfo(source);
        if Types.isClockOrSubTypeClock(Expression.typeof(e)) then
          Error.addSourceMessage(Error.CLOCKED_WHEN_IN_WHEN_EQ , {}, info);
        else
          Error.addSourceMessage(Error.NESTED_WHEN, {}, info);
        end if;
      then fail();

    case el::_
      equation
        msg = "- DAEUtil.verifyWhenEquationStatements failed on: " + DAEDump.dumpElementsStr({el});
        info = ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(el));
        Error.addSourceMessage(Error.INTERNAL_ERROR, {msg}, info);
      then fail();
  end match;
end verifyBoolWhenEquation1;

protected function collectWhenCrefs
  input list<DAE.Exp> inExps;
  input DAE.ElementSource source;
  input list<DAE.ComponentRef> inCrefs = {};
  output list<DAE.ComponentRef> outCrefs;
algorithm
  outCrefs := List.fold1(inExps, collectWhenCrefs1, source, inCrefs);
end collectWhenCrefs;

protected function collectWhenCrefs1
  input DAE.Exp inExp;
  input DAE.ElementSource source;
  input list<DAE.ComponentRef> inCrefs = {};
  output list<DAE.ComponentRef> outCrefs;
protected
  DAE.Exp e;
  list<DAE.Exp> exps;
  DAE.ComponentRef cr;
algorithm
  outCrefs := match inExp
    local
      String msg;
      SourceInfo info;
    case DAE.CREF(cr, _) then cr::inCrefs;
    case DAE.TUPLE(exps) then collectWhenCrefs(exps, source, inCrefs);
    else
      equation
        msg = ExpressionDump.printExpStr(inExp);
        info = ElementSource.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.WHEN_EQ_LHS, {msg}, info);
      then fail();
  end match;
end collectWhenCrefs1;

protected function compareCrefList ""
  input list<list<DAE.ComponentRef>> inCrefs;
  output list<DAE.ComponentRef> outrefs;
  output Boolean matching;
algorithm (outrefs,matching) := match(inCrefs)
  local
    list<DAE.ComponentRef> crefs,recRefs;
    Integer i;
    Boolean b1,b2,b3;
    list<list<DAE.ComponentRef>> llrefs;


  case({}) then ({},true);

  case(crefs::{}) then (crefs,true);

  case(crefs::llrefs)
    equation
      (recRefs,b3) = compareCrefList(llrefs);
      i = listLength(recRefs);
      // make sure is more than 0!
      if (intGt(i, 0))
      then
        // this case will allways have revRefs >=1 unless we are supposed to have 0
        b1 = (0 == intMod(listLength(crefs),i));
        crefs = List.unionOnTrueList({recRefs,crefs},ComponentReference.crefEqual);
        b2 = intEq(listLength(crefs),i);
        b1 = boolAnd(b1,boolAnd(b2,b3));
      else
        // this deals with 0 as the number of set crefs in one of the branches, for example:
        // if then reinint;reinit; else reinit;reinit; end if;
        // make sure both of them are 0!
        true = intEq(i, 0);
        true = intEq(listLength(crefs), 0);
        b1 = true;
      end if;
    then
      (crefs,b1);

  end match;
end compareCrefList;

public function evaluateAnnotation "lochel: This is not used.
  evaluates the annotation Evaluate"
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm
  (outDAElist) := matchcontinue (inCache,env,inDAElist)
    local
      DAE.DAElist dae;
      HashTable2.HashTable ht,pv,ht1;
      list<DAE.Element> elts,elts1,elts2;
      FCore.Cache cache;
    case (_,_,dae as DAE.DAE(elts))
      equation
        pv = getParameterVars(dae,HashTable2.emptyHashTable());
        (ht,true) = evaluateAnnotation1(dae,pv,HashTable2.emptyHashTable());
        (_,ht1,_) = evaluateAnnotation2_loop(inCache,env,dae,ht,BaseHashTable.hashTableCurrentSize(ht));
        (elts2,_) = traverseDAEElementList(elts, Expression.traverseSubexpressionsHelper, (evaluateAnnotationTraverse, (ht1,0,0)));
      then
        DAE.DAE(elts2);
    else inDAElist;
  end matchcontinue;
end evaluateAnnotation;

protected function evaluateAnnotationTraverse "author: Frenkel TUD, 2010-12"
  input DAE.Exp inExp;
  input tuple<HashTable2.HashTable,Integer,Integer> itpl;
  output DAE.Exp outExp;
  output tuple<HashTable2.HashTable,Integer,Integer> otpl;
algorithm
  (outExp,otpl) := matchcontinue (inExp,itpl)
    local
      DAE.ComponentRef cr;
      HashTable2.HashTable ht;
      DAE.Exp exp,e1;
      Integer i,j,k;
      list<DAE.Var> varLst;

    // Special Case for Records
    case (exp as DAE.CREF(ty= DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))),(ht,i,j))
      equation
        (e1,true) = Expression.extendArrExp(exp,false);
        (e1,(ht,i,k)) = Expression.traverseExpBottomUp(e1,evaluateAnnotationTraverse,itpl);
        true = intGt(k,j);
      then (e1,(ht,i,k));
    // Special Case for Arrays
    case (exp as DAE.CREF(ty = DAE.T_ARRAY()),(ht,i,j))
      equation
        (e1,true) = Expression.extendArrExp(exp,false);
        (e1,(ht,i,k)) = Expression.traverseExpBottomUp(e1,evaluateAnnotationTraverse,itpl);
        true = intGt(k,j);
      then (e1,(ht,i,k));

    case (exp as DAE.CREF(),(ht,i,j))
      equation
        e1 = replaceCrefInAnnotation(exp, ht);
        true = Expression.isConst(e1);
      then (e1,(ht,i,j+1));

    case (exp as DAE.CREF(),(ht,i,j))
      then (exp,(ht,i+1,j));

    else (inExp,itpl);
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
    case ((ht,_),DAE.VAR(componentRef = cr,kind=DAE.PARAM(),binding=SOME(e),comment=SOME(comment)),pv)
      equation
        SCode.COMMENT(annotation_=SOME(anno)) = comment;
        true = SCodeUtil.hasBooleanNamedAnnotation(anno,"Evaluate");
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
        (e1,(_,i,_)) = Expression.traverseExpBottomUp(e,evaluateAnnotationTraverse,(pv,0,0));
        true = intEq(i,0);
        e2 = evaluateParameter(e1,pv);
      then
        e2;
  end matchcontinue;
end evaluateParameter;

protected function evaluateAnnotation2_loop
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  input Integer sizeBefore;
  output list<DAE.Element> outDAElist;
  output HashTable2.HashTable outHt;
  output FCore.Cache outCache;
protected
  Integer newsize;
algorithm
  (outDAElist,outHt,outCache) := evaluateAnnotation2(cache,env,inDAElist,inHt);
  newsize := BaseHashTable.hashTableCurrentSize(outHt);
  (outDAElist,outHt,outCache) := evaluateAnnotation2_loop1(intEq(newsize,sizeBefore),outCache,env,DAE.DAE(outDAElist),outHt,newsize);
end evaluateAnnotation2_loop;

protected function evaluateAnnotation2_loop1
  input Boolean finish;
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  input Integer sizeBefore;
  output list<DAE.Element> outDAElist;
  output HashTable2.HashTable outHt;
  output FCore.Cache outCache;
algorithm
  (outDAElist,outHt,outCache) := match (finish,inCache,env,inDAElist,inHt,sizeBefore)
    local
      HashTable2.HashTable ht;
      list<DAE.Element> elst;
      FCore.Cache cache;
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
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.DAElist inDAElist;
  input HashTable2.HashTable inHt;
  output list<DAE.Element> outDAElist;
  output HashTable2.HashTable outHt;
  output FCore.Cache outCache;
algorithm
  (outDAElist,outHt,outCache) := matchcontinue (inCache,env,inDAElist,inHt)
    local
      list<DAE.Element> elementLst,elementLst1;
      HashTable2.HashTable ht,ht1;
      FCore.Cache cache;
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
  input tuple<HashTable2.HashTable,FCore.Cache,FCore.Graph> inHt;
  output DAE.Element oel;
  output tuple<HashTable2.HashTable,FCore.Cache,FCore.Graph> outHt;
algorithm
  (oel,outHt) := matchcontinue (iel,inHt)
    local
      tuple<HashTable2.HashTable,FCore.Cache,FCore.Graph> httpl;
      FCore.Cache cache;
      FCore.Graph env;
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
                  comment=absynCommentOption,innerOuter=innerOuter),(ht,cache,env))
      equation
        (e1,(_,i,j)) = Expression.traverseExpBottomUp(e,evaluateAnnotationTraverse,(ht,0,0));
        (e2,ht1,cache) = evaluateAnnotation4(cache,env,cr,e1,i,j,ht);
      then
        (DAE.VAR(cr,DAE.PARAM(),direction,parallelism,protection,ty,SOME(e2),dims,ct,
            source,variableAttributesOption,absynCommentOption,innerOuter),(ht1,cache,env));
    else (iel,inHt);
  end matchcontinue;
end evaluateAnnotation3;

protected function evaluateAnnotation4
"evaluates the parameters with bindings parameters with annotation Evaluate"
  input FCore.Cache inCache;
  input FCore.Graph env;
  input DAE.ComponentRef inCr;
  input DAE.Exp inExp;
  input Integer inInteger1;
  input Integer inInteger2;
  input HashTable2.HashTable inHt;
  output DAE.Exp outExp;
  output HashTable2.HashTable outHt;
  output FCore.Cache outCache;
algorithm
  (outExp,outHt,outCache) := matchcontinue (inCache,env,inCr,inExp,inInteger1,inInteger2,inHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Integer i,j;
      HashTable2.HashTable ht,ht1;
      FCore.Cache cache;
      Values.Value value;
    case (_,_,cr,e,i,j,ht)
      equation
        // there is a paramter with evaluate=true
        true = intGt(j,0);
        // there are no other crefs
        true = intEq(i,0);
        // evalute expression
        (e1,(ht,_,_)) = Expression.traverseExpBottomUp(e,evaluateAnnotationTraverse,(ht,0,0));
        (cache, value) = Ceval.ceval(inCache, env, e1, false, Absyn.NO_MSG(),0);
         e1 = ValuesUtil.valueExp(value);
        // e1 = e;
        ht1 = BaseHashTable.add((cr,e1),ht);
      then (e1,ht1,cache);
    case (_,_,_,e,_,_,ht) then (e,ht,inCache);
  end matchcontinue;
end evaluateAnnotation4;

public function renameUniqueOuterVars "author: BZ, 2008-12
  Rename innerouter(the inner part of innerouter) variables that have been renamed to a.b.$unique$var
  Just remove the $unique$ from the var name.
  This function traverses the entire dae."
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm
  (odae,_,_) := traverseDAE(dae, DAE.AvlTreePathFunction.Tree.EMPTY(), Expression.traverseSubexpressionsHelper, (removeUniqieIdentifierFromCref, {}));
end renameUniqueOuterVars;

protected function removeUniqieIdentifierFromCref "Function for Expression.traverseExpBottomUp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input DAE.Exp inExp;
  input Type_a oarg;
  output DAE.Exp outExp;
  output Type_a outDummy;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outDummy) := matchcontinue (inExp,oarg)
    local
      DAE.ComponentRef cr,cr2;
      DAE.Type ty;
      DAE.Exp exp;

    case (DAE.CREF(cr,ty),_)
      equation
        cr2 = unNameInnerouterUniqueCref(cr,DAE.UNIQUEIO);
        exp = Expression.makeCrefExp(cr2,ty);
      then (exp,oarg);

    else (inExp,oarg);

  end matchcontinue;
end removeUniqieIdentifierFromCref;

public function nameUniqueOuterVars "author: BZ, 2008-12
  Rename all variables to the form a.b.$unique$var, call
  This function traverses the entire dae."
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm
  (odae,_,_) := traverseDAE(dae, DAE.AvlTreePathFunction.Tree.EMPTY(), Expression.traverseSubexpressionsHelper, (addUniqueIdentifierToCref, {}));
end nameUniqueOuterVars;

protected function addUniqueIdentifierToCref "author: BZ, 2008-12
  Function for Expression.traverseExpBottomUp, adds the constant 'UNIQUEIO' to the CREF_IDENT() part of the cref."
  input DAE.Exp inExp;
  input Type_a oarg;
  output DAE.Exp outExp;
  output Type_a outDummy;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outDummy) := matchcontinue (inExp,oarg)
    local
      DAE.ComponentRef cr,cr2;
      DAE.Type ty;
      DAE.Exp exp;

    case (DAE.CREF(cr,ty),_)
      equation
        cr2 = nameInnerouterUniqueCref(cr);
        exp = Expression.makeCrefExp(cr2,ty);
      then (exp,oarg);

    else (inExp,oarg);

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
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
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
        (e,extraArg) = func(e,extraArg);
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
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
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
        (e,extraArg) = func(e,extraArg);
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
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
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
        (branch2,extraArg) = traverseDAEElementList(branch,func,extraArg);
        (recRes,extraArg) = traverseDAEList(daeList,func,extraArg);
      then
        (branch2::recRes,extraArg);
  end match;
end traverseDAEList;

public function getFunctionList
  input DAE.FunctionTree ft;
  input Boolean failOnError=false;
  output list<DAE.Function> fns;
protected
  list<tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value>> lst, lstInvalid;
  String str;
algorithm
  try
    fns := List.map(DAE.AvlTreePathFunction.listValues(ft), Util.getOption);
  else
    lst := DAE.AvlTreePathFunction.toList(ft);
    lstInvalid := List.select(lst, isInvalidFunctionEntry);
    str := stringDelimitList(list(AbsynUtil.pathString(p) for p in List.map(lstInvalid, Util.tuple21)), "\n ");
    str := "\n " + str + "\n";
    Error.addMessage(Error.NON_INSTANTIATED_FUNCTION, {str});
    if failOnError then
      fail();
    end if;
    fns := List.mapMap(List.select(lst, isValidFunctionEntry), Util.tuple22, Util.getOption);
  end try;
end getFunctionList;

public function getFunctionNames
  input DAE.FunctionTree ft;
  output list<String> strs;
algorithm
  strs := List.mapMap(getFunctionList(ft), functionName, AbsynUtil.pathStringDefault);
end getFunctionNames;

protected function isInvalidFunctionEntry
  input tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value> tpl;
  output Boolean b;
algorithm
  b := match tpl
    case ((_,NONE())) then true;
    else false;
  end match;
end isInvalidFunctionEntry;

protected function isValidFunctionEntry
  input tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value> tpl;
  output Boolean b;
algorithm
  b := not isInvalidFunctionEntry(tpl);
end isValidFunctionEntry;

public function traverseDAE<ArgT>
  "This function traverses all dae exps.
   NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input output DAE.DAElist dae;
  input output DAE.FunctionTree functionTree;
  input FuncExpType func;
  input output ArgT arg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output ArgT arg;
  end FuncExpType;
protected
  list<DAE.Element> el;
algorithm
  (el, arg) := traverseDAEElementList(dae.elementLst, func, arg);
  dae.elementLst := el;
  (functionTree, arg) := DAE.AvlTreePathFunction.mapFold(functionTree,
    function traverseDAEFuncHelper(func = func), arg);
end traverseDAE;

protected function traverseDAEFuncHelper<ArgT>
  "Helper function to traverseDae. Traverses the functions."
  input DAE.AvlTreePathFunction.Key key;
  input output DAE.AvlTreePathFunction.Value value;
  input FuncExpType func;
  input output ArgT arg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output ArgT arg;
  end FuncExpType;
algorithm
  (value,arg) := match value
    local
      DAE.Function daeFunc1,daeFunc2;
    case SOME(daeFunc1)
      equation
        (daeFunc2,arg) = traverseDAEFunc(daeFunc1,func,arg);
      then (if referenceEq(daeFunc1,daeFunc2) then value else SOME(daeFunc2),arg);
    case NONE()
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- DAEUtil.traverseDAEFuncLst failed: " + AbsynUtil.pathString(key));
      then fail();
  end match;
end traverseDAEFuncHelper;

public function traverseDAEFunctions<ArgT>
  "Traverses the functions.
   Note: Only calls the top-most expressions. If you need to also traverse the
   expression, use an extra helper function."
  input output list<DAE.Function> functions;
  input FuncExpType func;
  input output ArgT arg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output ArgT arg;
  end FuncExpType;
algorithm
  (functions, arg) := List.mapFold(functions,
    function traverseDAEFunc(func = func), arg);
end traverseDAEFunctions;

protected function traverseDAEFunc<ArgT>
  input output DAE.Function daeFunction;
  input FuncExpType func;
  input output ArgT arg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output ArgT arg;
  end FuncExpType;
algorithm
  _ := match daeFunction
    local
      DAE.FunctionDefinition fdef;
      list<DAE.FunctionDefinition> rest_defs;
      list<DAE.Element> el;

    case DAE.FUNCTION(functions = (fdef as DAE.FUNCTION_DEF()) :: rest_defs)
      algorithm
        (el, arg) := traverseDAEElementList(fdef.body, func, arg);

        if not referenceEq(fdef.body, el) then
          fdef.body := el;
          daeFunction.functions := fdef :: rest_defs;
        end if;
      then
        ();

    case DAE.FUNCTION(functions = (fdef as DAE.FUNCTION_EXT()) :: rest_defs)
      algorithm
        (el, arg) := traverseDAEElementList(fdef.body, func, arg);

        if not referenceEq(fdef.body, el) then
          fdef.body := el;
          daeFunction.functions := fdef :: rest_defs;
        end if;
      then
        ();

    case DAE.RECORD_CONSTRUCTOR() then ();
  end match;
end traverseDAEFunc;

public function traverseDAEElementList<ArgT>
  "author: BZ, 2008-12, adrpo, 2010-12
   This function traverses all dae exps.
   NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input output list<DAE.Element> elements;
  input FuncExpType func;
  input output ArgT arg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output ArgT arg;
  end FuncExpType;
algorithm
  (elements, arg) := List.mapFold(elements,
    function traverseDAEElement(func = func), arg);
end traverseDAEElementList;

protected function traverseDAEElement<ArgT>
  "author: adrpo, 2010-12
   This function is a tail recursive function that traverses all dae exps.
   NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input output DAE.Element element;
  input FuncExpType func;
  input output ArgT arg;

  partial function FuncExpType
    input output DAE.Exp exp;
    input output ArgT arg;
  end FuncExpType;
algorithm
  _ := match element
    local
      DAE.Exp e1, e2, e3, new_e1, new_e2, new_e3;
      DAE.ComponentRef cr1, cr2, new_cr1, new_cr2;
      list<DAE.Element> el, new_el;
      list<list<DAE.Element>> eqll, new_eqll;
      DAE.Element e, new_e;
      list<DAE.Statement> stmts, new_stmts;
      list<DAE.Exp> expl, new_expl;
      Option<DAE.Exp> binding, new_binding;
      Option<DAE.VariableAttributes> attr, new_attr;
      list<DAE.Var> varLst;
      DAE.Binding daebinding, new_daebinding;
      Boolean changed;
      DAE.Type new_ty;

    case DAE.VAR(componentRef = cr1, binding = binding,
        variableAttributesOption = attr)
      algorithm
        (e1, arg) := func(Expression.crefExp(cr1), arg);

        if Expression.isCref(e1) then
          new_cr1 := Expression.expCref(e1);
          if not referenceEq(cr1, new_cr1) then
            element.componentRef := new_cr1;
          end if;
        end if;

        element.dims := list(match d
            case DAE.DIM_EXP(e1)
              algorithm
                (new_e1, arg) := func(e1, arg);
              then
                if referenceEq(e1, new_e1) then d else DAE.DIM_EXP(new_e1);
            else d;
          end match for d in element.dims);

        new_ty := match ty as element.ty
          case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD())
          algorithm
            changed := false;
            varLst := list(
            match v
              case DAE.TYPES_VAR(binding=daebinding as DAE.EQBOUND())
              algorithm
                (e2,arg) := func(daebinding.exp, arg);
                if not referenceEq(daebinding.exp, e2) then
                  daebinding := DAE.EQBOUND(e2,NONE(),daebinding.constant_,daebinding.source);
                  v.binding := daebinding;
                  changed := true;
                end if;
              then v;
              case DAE.TYPES_VAR(binding=daebinding as DAE.VALBOUND())
              algorithm
                e1 := ValuesUtil.valueExp(daebinding.valBound);
                (e2,arg) := func(e1, arg);
                if not referenceEq(e1, e2) then
                  new_daebinding := DAE.EQBOUND(e2,NONE(),DAE.C_CONST(),daebinding.source);
                  v.binding := new_daebinding;
                  changed := true;
                end if;
              then v;
              else v;
            end match
            for v in ty.varLst
            );
            if not referenceEq(varLst, ty.varLst) then
              ty.varLst := varLst;
            end if;
          then ty;
          else ty;
        end match;

        if not referenceEq(element.ty, new_ty) then element.ty := new_ty; end if;

        (new_binding, arg) := traverseDAEOptExp(binding, func, arg);
        if not referenceEq(binding, new_binding) then element.binding := new_binding; end if;
        (new_attr, arg) := traverseDAEVarAttr(attr, func, arg);
        if not referenceEq(attr, new_attr) then
          element.variableAttributesOption := new_attr;
        end if;
      then
        ();

    case DAE.DEFINE(componentRef = cr1, exp = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
        (DAE.CREF(new_cr1), arg) := func(Expression.crefExp(cr1), arg);
        if not referenceEq(cr1, new_cr1) then element.componentRef := new_cr1; end if;
      then
        ();

    case DAE.INITIALDEFINE(componentRef = cr1, exp = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
        (DAE.CREF(new_cr1), arg) := func(Expression.crefExp(cr1), arg);
        if not referenceEq(cr1, new_cr1) then element.componentRef := new_cr1; end if;
      then
        ();

    case DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2)
      algorithm
        (DAE.CREF(new_cr1), arg) := func(Expression.crefExp(cr1), arg);
        if not referenceEq(cr1, new_cr1) then element.cr1 := new_cr1; end if;
        (DAE.CREF(new_cr2), arg) := func(Expression.crefExp(cr2), arg);
        if not referenceEq(cr2, new_cr2) then element.cr2 := new_cr2; end if;
      then
        ();

    case DAE.EQUATION(exp = e1, scalar = e2)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.scalar := new_e2; end if;
      then
        ();

    case DAE.INITIALEQUATION(exp1 = e1, exp2 = e2)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp1 := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.exp2 := new_e2; end if;
      then
        ();

    case DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.lhs := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.rhs := new_e2; end if;
      then
        ();

    case DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.lhs := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.rhs := new_e2; end if;
      then
        ();

    case DAE.ARRAY_EQUATION(exp = e1, array = e2)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.array := new_e2; end if;
      then
        ();

    case DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.array := new_e2; end if;
      then
        ();

    case DAE.WHEN_EQUATION(condition = e1, equations = el)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.condition := new_e1; end if;
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.equations := new_el; end if;

        if isSome(element.elsewhen_) then
          SOME(e) := element.elsewhen_;
          (new_e, arg) := traverseDAEElement(e, func, arg);
          if not referenceEq(e, new_e) then element.elsewhen_ := SOME(new_e); end if;
        end if;
      then
        ();

    case DAE.FOR_EQUATION(range = e1, equations = el)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.range := new_e1; end if;
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.equations := new_el; end if;
      then
        ();

    case DAE.COMP(dAElist = el)
      algorithm
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.dAElist := new_el; end if;
      then
        ();

    case DAE.EXTOBJECTCLASS() then ();

    case DAE.ASSERT(condition = e1, message = e2, level = e3)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.condition := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.message := new_e2; end if;
        (new_e3, arg) := func(e3, arg);
        if not referenceEq(e3, new_e3) then element.level := new_e3; end if;
      then
        ();

    case DAE.INITIAL_ASSERT(condition = e1, message = e2, level = e3)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.condition := new_e1; end if;
        (new_e2, arg) := func(e2, arg);
        if not referenceEq(e2, new_e2) then element.message := new_e2; end if;
        (new_e3, arg) := func(e3, arg);
        if not referenceEq(e3, new_e3) then element.level := new_e3; end if;
      then
        ();

    case DAE.TERMINATE(message = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.message := new_e1; end if;
      then
        ();

    case DAE.INITIAL_TERMINATE(message = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.message := new_e1; end if;
      then
        ();

    case DAE.NORETCALL(exp = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
      then
        ();

    case DAE.INITIAL_NORETCALL(exp = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
      then
        ();

    case DAE.REINIT(componentRef = cr1, exp = e1)
      algorithm
        (new_e1, arg) := func(e1, arg);
        if not referenceEq(e1, new_e1) then element.exp := new_e1; end if;
        (DAE.CREF(new_cr1), arg) := func(Expression.crefExp(cr1), arg);
        if not referenceEq(cr1, new_cr1) then element.componentRef := new_cr1; end if;
      then
        ();

    case DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(stmts))
      algorithm
        (new_stmts, arg) := traverseDAEEquationsStmts(stmts, func, arg);
        if not referenceEq(stmts, new_stmts) then
          element.algorithm_ := DAE.ALGORITHM_STMTS(new_stmts);
        end if;
      then
        ();

    case DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(stmts))
      algorithm
        (new_stmts, arg) := traverseDAEEquationsStmts(stmts, func, arg);
        if not referenceEq(stmts, new_stmts) then
          element.algorithm_ := DAE.ALGORITHM_STMTS(new_stmts);
        end if;
      then
        ();

    case DAE.CONSTRAINT(constraints = DAE.CONSTRAINT_EXPS(expl))
      algorithm
        (new_expl, arg) := traverseDAEExpList(expl, func, arg);
        if not referenceEq(expl, new_expl) then
          element.constraints := DAE.CONSTRAINT_EXPS(new_expl);
        end if;
      then
        ();

    case DAE.CLASS_ATTRIBUTES() then ();

    case DAE.IF_EQUATION(condition1 = expl, equations2 = eqll, equations3 = el)
      algorithm
        (new_expl, arg) := traverseDAEExpList(expl, func, arg);
        if not referenceEq(expl, new_expl) then element.condition1 := new_expl; end if;
        (new_eqll, arg) := traverseDAEList(eqll, func, arg);
        if not referenceEq(eqll, new_eqll) then element.equations2 := new_eqll; end if;
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.equations3 := new_el; end if;
      then
        ();

    case DAE.INITIAL_IF_EQUATION(condition1 = expl, equations2 = eqll, equations3 = el)
      algorithm
        (new_expl, arg) := traverseDAEExpList(expl, func, arg);
        if not referenceEq(expl, new_expl) then element.condition1 := new_expl; end if;
        (new_eqll, arg) := traverseDAEList(eqll, func, arg);
        if not referenceEq(eqll, new_eqll) then element.equations2 := new_eqll; end if;
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.equations3 := new_el; end if;
      then
        ();

    case DAE.FLAT_SM(dAElist = el)
      algorithm
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.dAElist := new_el; end if;
      then
        ();

    case DAE.SM_COMP(dAElist = el)
      algorithm
        (new_el, arg) := traverseDAEElementList(el, func, arg);
        if not referenceEq(el, new_el) then element.dAElist := new_el; end if;
      then
        ();

    case DAE.COMMENT()
      then ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"DAEUtil.traverseDAEElement not implemented correctly for element: " +
           DAEDump.dumpElementsStr({element})});
      then
        fail();

  end match;
end traverseDAEElement;

protected uniontype TraverseStatementsOptions
  record TRAVERSE_ALL
  end TRAVERSE_ALL;
  record TRAVERSE_RHS_ONLY
  end TRAVERSE_RHS_ONLY;
end TraverseStatementsOptions;

public function traverseAlgorithmExps "
  This function goes through the Algorithm structure and finds all the
  expressions and performs the function on them
"
  replaceable type Type_a subtypeof Any;
  input DAE.Algorithm inAlgorithm;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
algorithm
  outTypeA := match (inAlgorithm,func,inTypeA)
    local
      list<DAE.Statement> stmts;
      Type_a ext_arg_1;
    case (DAE.ALGORITHM_STMTS(statementLst = stmts),_,_)
      equation
        (_,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
      then
        ext_arg_1;
  end match;
end traverseAlgorithmExps;

public function traverseDAEEquationsStmts "Traversing of DAE.Statement."
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
protected
  list<list<DAE.Statement>> outStmtsLst;
  Boolean b;
algorithm
  (outStmtsLst,oextraArg) := List.map2Fold(inStmts,traverseDAEEquationsStmtsWork,func,opt,iextraArg);
  outStmts := List.flatten(outStmtsLst);
  b := List.allReferenceEq(inStmts,outStmts);
  outStmts := if b then inStmts else outStmts;
end traverseDAEEquationsStmtsList;

protected function traverseStatementsOptionsEvalLhs
  input DAE.Exp inExp;
  input Type_a inA;
  input FuncExpType func;
  input TraverseStatementsOptions opt;
  output DAE.Exp outExp;
  output Type_a outA;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outExp,outA) := match (inExp,inA,func,opt)
    case (_,_,_,TRAVERSE_ALL())
      equation
        (outExp,outA) = func(inExp,inA);
      then (outExp,outA);
    else (inExp,inA);
  end match;
end traverseStatementsOptionsEvalLhs;

protected function traverseDAEEquationsStmtsWork "Handles the traversing of DAE.Statement."
  input DAE.Statement inStmt;
  input FuncExpType func;
  input TraverseStatementsOptions opt;
  input Type_a iextraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := matchcontinue (inStmt,func,opt,iextraArg)
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
      DAE.Else algElse,algElse1;
      Type_a extraArg;
      list<tuple<DAE.ComponentRef,SourceInfo>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall,b;

    case (DAE.STMT_ASSIGN(type_ = tp,exp1 = e,exp = e2, source = source),_,_,extraArg)
      equation
        (e_1,extraArg) = traverseStatementsOptionsEvalLhs(e, extraArg, func, opt);
        (e_2,extraArg) = func(e2, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(e2,e_2) then inStmt else DAE.STMT_ASSIGN(tp,e_1,e_2,source);
      then (x::{},extraArg);

    case (DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source),_,_,extraArg)
      equation
        (e_1, extraArg) = func(e, extraArg);
        (DAE.TUPLE(expl2), extraArg) = traverseStatementsOptionsEvalLhs(DAE.TUPLE(expl1), extraArg, func, opt);
        x = if referenceEq(e,e_1) and referenceEq(expl1,expl2) then inStmt else DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source);
      then (x::{},extraArg);

    case (DAE.STMT_ASSIGN_ARR(type_ = tp, lhs=e, exp = e2, source = source),_,_,extraArg)
      equation
        (e_2, extraArg) = func(e2, extraArg);
        _ = matchcontinue()
          case ()
            equation
              (e_1 as DAE.CREF(_,_), extraArg) = traverseStatementsOptionsEvalLhs(e, extraArg, func, opt);
               x = if referenceEq(e2,e_2) and referenceEq(e,e_1) then inStmt else DAE.STMT_ASSIGN_ARR(tp,e_1,e_2,source);
             then
               ();
          else
            equation
              failure((DAE.CREF(_,_), _) = func(e, extraArg));
              x = if referenceEq(e2,e_2) then inStmt else DAE.STMT_ASSIGN_ARR(tp,e,e_2,source);
              /* We need to pass this through because simplify/etc may scalarize the cref...
                 true = Flags.isSet(Flags.FAILTRACE);
                 print(DAEDump.ppStatementStr(x));
                 print("Warning, not allowed to set the componentRef to a expression in DAEUtil.traverseDAEEquationsStmts\n");
              */
            then
              ();
        end matchcontinue;
      then (x::{},extraArg);

    case (DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source),_,_,extraArg)
      equation
        (algElse1,extraArg) = traverseDAEEquationsStmtsElse(algElse,func,opt,extraArg);
        (stmts2,extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        (e_1,extraArg) = func(e, extraArg);
        (stmts1,b) = Algorithm.optimizeIf(e_1,stmts2,algElse1,source);
        stmts1 = if not b and referenceEq(e,e_1) and referenceEq(stmts,stmts2) and referenceEq(algElse,algElse1) then (inStmt::{}) else stmts1;
      then (stmts1,extraArg);

    case (DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(stmts,stmts2) then inStmt else DAE.STMT_FOR(tp,b1,id1,ix,e_1,stmts2,source);
      then (x::{},extraArg);

    case (DAE.STMT_PARFOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, loopPrlVars=loopPrlVars, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(stmts,stmts2) then inStmt else DAE.STMT_PARFOR(tp,b1,id1,ix,e_1,stmts2,loopPrlVars,source);
      then (x::{},extraArg);

    case (DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(stmts,stmts2) then inStmt else DAE.STMT_WHILE(e_1,stmts2,source);
      then (x::{},extraArg);

    case (DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=NONE(),source=source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(stmts,stmts2) then inStmt else DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,NONE(),source);
      then (x::{},extraArg);

    case (DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=SOME(ew),source=source),_,_,extraArg)
      equation
        ({ew_1}, extraArg) = traverseDAEEquationsStmtsList({ew},func,opt,extraArg);
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(ew,ew_1) and referenceEq(e,e_1) and referenceEq(stmts,stmts2) then inStmt else DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,SOME(ew_1),source);
      then (x::{},extraArg);

    case (DAE.STMT_ASSERT(cond = e, msg=e2, level=e3, source = source),_,_,extraArg)
      equation
        (e_1, extraArg) = func(e, extraArg);
        (e_2, extraArg) = func(e2, extraArg);
        (e_3, extraArg) = func(e3, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(e2,e_2) and referenceEq(e3,e_3) then inStmt else DAE.STMT_ASSERT(e_1,e_2,e_3,source);
      then (x::{},extraArg);

    case (DAE.STMT_TERMINATE(msg = e, source = source),_,_,extraArg)
      equation
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(e,e_1) then inStmt else DAE.STMT_TERMINATE(e_1,source);
      then (x::{},extraArg);

    case (DAE.STMT_REINIT(var = e,value=e2, source = source),_,_,extraArg)
      equation
        (e_1, extraArg) = func(e, extraArg);
        (e_2, extraArg) = func(e2, extraArg);
        x = if referenceEq(e,e_1) and referenceEq(e2,e_2) then inStmt else DAE.STMT_REINIT(e_1,e_2,source);
      then (x::{},extraArg);

    case (DAE.STMT_NORETCALL(exp = e, source = source),_,_,extraArg)
      equation
        (e_1, extraArg) = func(e, extraArg);
        x = if referenceEq(e,e_1) then inStmt else DAE.STMT_NORETCALL(e_1,source);
      then (x::{},extraArg);

    case (x as DAE.STMT_RETURN(),_,_,extraArg)
      then (x::{},extraArg);

    case (x as DAE.STMT_BREAK(),_,_,extraArg)
      then (x::{},extraArg);

    case (x as DAE.STMT_CONTINUE(),_,_,extraArg)
      then (x::{},extraArg);

    // MetaModelica extension. KS
    case (DAE.STMT_FAILURE(body=stmts, source = source),_,_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEEquationsStmtsList(stmts,func,opt,extraArg);
        x = if referenceEq(stmts,stmts2) then inStmt else DAE.STMT_FAILURE(stmts2,source);
      then (x::{},extraArg);

    case (x,_,_,_)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "DAEUtil.traverseDAEEquationsStmts not implemented correctly: " + str;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outElse,oextraArg) := match(inElse,func,opt,iextraArg)
  local
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    DAE.Else el,el_1;
    Type_a extraArg;
    Boolean b;
  case (DAE.NOELSE(),_,_,extraArg) then (DAE.NOELSE(),extraArg);
  case (DAE.ELSEIF(e,st,el),_,_,extraArg)
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,opt,extraArg);
      (st_1,extraArg) = traverseDAEEquationsStmtsList(st,func,opt,extraArg);
      (e_1,extraArg) = func(e, extraArg);
      outElse = Algorithm.optimizeElseIf(e_1,st_1,el_1);
      b = referenceEq(el,el_1) and referenceEq(st,st_1) and referenceEq(e,e_1);
      outElse = if b then inElse else outElse;
    then (outElse,extraArg);
  case(DAE.ELSE(st),_,_,extraArg)
    equation
      (st_1,extraArg) = traverseDAEEquationsStmtsList(st,func,opt,extraArg);
      outElse = if referenceEq(st,st_1) then inElse else DAE.ELSE(st_1);
    then (outElse,extraArg);
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
    input DAE.Exp inExp;
    input DAE.Statement inStmt;
    input Type_a arg;
    output DAE.Exp outExp;
    output Type_a oarg;
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
      list<tuple<DAE.ComponentRef,SourceInfo>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case ({},_,extraArg) then ({},extraArg);

    case (((x as DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e, source = source))::xs),_,extraArg)
      equation
        (e_1, extraArg) = func(e, x, extraArg);
        (e_2, extraArg) = func(e2, x, extraArg);
        (xs_1,extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(e2,e_2) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_ASSIGN(tp,e_2,e_1,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source))::xs),_,extraArg)
      equation
        (e_1, extraArg) = func(e, x,  extraArg);
        (expl2, extraArg) = traverseDAEExpListStmt(expl1,func, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(expl2,expl1) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp, lhs=e, exp = e2, source = source))::xs),_,extraArg)
      algorithm
        (e_2, extraArg) := func(e2, x,  extraArg);
        try
          (e_1 as DAE.CREF(_,_), extraArg) := func(e,  x, extraArg);
        else
          // We need to pass this through because simplify/etc may scalarize the cref...
          e_1 := e;
        end try;
        (xs_1, extraArg) := traverseDAEStmts(xs, func, extraArg);
        outStmts := if referenceEq(e,e_1) and referenceEq(e2,e_2) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_ASSIGN_ARR(tp,e_1,e_2,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source))::xs),_,extraArg)
      equation
        (algElse,extraArg) = traverseDAEStmtsElse(algElse,func, x, extraArg);
        (stmts2,extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (e_1,extraArg) = func(e, x, extraArg);
        (xs_1,extraArg) = traverseDAEStmts(xs, func, extraArg);
        (stmts1,_) = Algorithm.optimizeIf(e_1,stmts2,algElse,source);
      then (listAppend(stmts1, xs_1),extraArg);

    case (((x as DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(stmts,stmts2) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_FOR(tp,b1,id1,ix,e_1,stmts2,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_PARFOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, loopPrlVars=loopPrlVars, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_PARFOR(tp,b1,id1,ix,e_1,stmts2,loopPrlVars,source)::xs_1,extraArg);

    case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(stmts,stmts2) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_WHILE(e_1,stmts2,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=NONE(),source=source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,NONE(),source)::xs_1,extraArg);

    case (((x as DAE.STMT_WHEN(exp=e,conditions=conditions,initialCall=initialCall,statementLst=stmts,elseWhen=SOME(ew),source=source))::xs),_,extraArg)
      equation
        ({_}, extraArg) = traverseDAEStmts({ew},func,extraArg);
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
      then (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts2,SOME(ew),source)::xs_1,extraArg);

    case (((x as DAE.STMT_ASSERT(cond = e, msg=e2, level=e3, source = source))::xs),_,extraArg)
      equation
        (e_1, extraArg) = func(e, x, extraArg);
        (e_2, extraArg) = func(e2, x, extraArg);
        (e_3, extraArg) = func(e3, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(e2,e_2) and referenceEq(e3,e_3) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_ASSERT(e_1,e_2,e_3,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_TERMINATE(msg = e, source = source))::xs),_,extraArg)
      equation
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_TERMINATE(e_1,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_REINIT(var = e,value=e2, source = source))::xs),_,extraArg)
      equation
        (e_1, extraArg) = func(e, x, extraArg);
        (e_2, extraArg) = func(e2, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(e2,e_2) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_REINIT(e_1,e_2,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_NORETCALL(exp = e, source = source))::xs),_,extraArg)
      equation
        (e_1, extraArg) = func(e, x, extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(e,e_1) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_NORETCALL(e_1,source)::xs_1;
      then (outStmts,extraArg);

    case (((x as DAE.STMT_RETURN())::xs),_,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        (, extraArg) = func(DAE.ICONST(-1), x, extraArg); // Dummy argument, so we can traverse over statements without expressions
      then (if referenceEq(xs,xs_1) then inStmts else x::xs_1,extraArg);

    case (((x as DAE.STMT_BREAK())::xs),_,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        (, extraArg) = func(DAE.ICONST(-1), x, extraArg); // Dummy argument, so we can traverse over statements without expressions
      then (if referenceEq(xs,xs_1) then inStmts else x::xs_1,extraArg);

    case (((x as DAE.STMT_CONTINUE())::xs),_,extraArg)
      equation
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        (, extraArg) = func(DAE.ICONST(-1), x, extraArg); // Dummy argument, so we can traverse over statements without expressions
      then (if referenceEq(xs,xs_1) then inStmts else x::xs_1,extraArg);

    // MetaModelica extension. KS
    case (((DAE.STMT_FAILURE(body=stmts, source = source))::xs),_,extraArg)
      equation
        (stmts2, extraArg) = traverseDAEStmts(stmts,func,extraArg);
        (xs_1, extraArg) = traverseDAEStmts(xs, func, extraArg);
        outStmts = if referenceEq(stmts,stmts2) and referenceEq(xs,xs_1) then inStmts else DAE.STMT_FAILURE(stmts2,source)::xs_1;
      then (outStmts,extraArg);

    case ((x::_),_,_)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "DAEUtil.traverseDAEStmts not implemented correctly: " + str;
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
    input DAE.Exp inExp;
    input DAE.Statement inStmt;
    input Type_a arg;
    output DAE.Exp outExp;
    output Type_a oarg;
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
      (e_1,extraArg) = func(e, istmt, extraArg);
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
    input DAE.Exp inExp;
    input DAE.Statement inStmt;
    input Type_a arg;
    output DAE.Exp outExp;
    output Type_a oarg;
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
        (e,extraArg) = func(e, istmt, extraArg);
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (traversedDaeList,oextraArg) := match(attr,func,iextraArg)
    local
      Option<DAE.Exp> quantity,unit,displayUnit,min,max,start,fixed,nominal,eb,so;
      Option<DAE.StateSelect> stateSelect;
      Option<DAE.Uncertainty> uncertainty;
      Option<DAE.Distribution> distribution;
      Option<Boolean> ip,fn;
      Type_a extraArg;

    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,max,start,fixed,nominal,stateSelect,uncertainty,distribution,eb,ip,fn,so)),_,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (unit,extraArg) = traverseDAEOptExp(unit,func,extraArg);
        (displayUnit,extraArg) = traverseDAEOptExp(displayUnit,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (start,extraArg) = traverseDAEOptExp(start,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        (nominal,extraArg) = traverseDAEOptExp(nominal,func,extraArg);
      then (SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,max,start,fixed,nominal,stateSelect,uncertainty,distribution,eb,ip,fn,so)),extraArg);

    case(SOME(DAE.VAR_ATTR_INT(quantity,min,max,start,fixed,uncertainty,distribution,eb,ip,fn,so)),_,extraArg)
      equation
        (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
        (min,extraArg) = traverseDAEOptExp(min,func,extraArg);
        (max,extraArg) = traverseDAEOptExp(max,func,extraArg);
        (start,extraArg) = traverseDAEOptExp(start,func,extraArg);
        (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
      then (SOME(DAE.VAR_ATTR_INT(quantity,min,max,start,fixed,uncertainty,distribution,eb,ip,fn,so)),extraArg);

      case(SOME(DAE.VAR_ATTR_BOOL(quantity,start,fixed,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (start,extraArg) = traverseDAEOptExp(start,func,extraArg);
          (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        then (SOME(DAE.VAR_ATTR_BOOL(quantity,start,fixed,eb,ip,fn,so)),extraArg);
      // BTH
      case(SOME(DAE.VAR_ATTR_CLOCK(_,_)),_,extraArg)
        then (attr,extraArg);

      case(SOME(DAE.VAR_ATTR_STRING(quantity,start,fixed,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (start,extraArg) = traverseDAEOptExp(start,func,extraArg);
          (fixed,extraArg) = traverseDAEOptExp(fixed,func,extraArg);
        then (SOME(DAE.VAR_ATTR_STRING(quantity,start,fixed,eb,ip,fn,so)),extraArg);

      case(SOME(DAE.VAR_ATTR_ENUMERATION(quantity,min,max,start,fixed,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (start,extraArg) = traverseDAEOptExp(start,func,extraArg);
        then (SOME(DAE.VAR_ATTR_ENUMERATION(quantity,min,max,start,fixed,eb,ip,fn,so)),extraArg);

      case (NONE(),_,extraArg) then (NONE(),extraArg);

  end match;
end traverseDAEVarAttr;

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
  input output DAE.DAElist dae;
  input Absyn.Path newtype;
algorithm
  if not (Flags.isSet(Flags.INFO_XML_OPERATIONS) or Flags.isSet(Flags.VISUAL_XML)) then
    return;
  end if;
  dae := match dae
    local
      list<DAE.Element> elts;
    case DAE.DAE(elts)
      equation
        elts = List.map1(elts,addComponentType2,newtype);
      then DAE.DAE(elts);
  end match;
end addComponentType;

protected function addComponentType2 "
  This function takes a dae element list and a type name and
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable."
  input output DAE.Element elt;
  input Absyn.Path inPath;
algorithm
  elt := match elt
    local
      DAE.ElementSource source;
    case DAE.VAR()
      equation
        elt.source = ElementSource.addElementSourceType(elt.source, inPath);
      then elt;
    else elt;
  end match;
end addComponentType2;

public function isExtFunction "returns true if element matches an external function"
  input DAE.Function elt;
  output Boolean res;
algorithm
  res := match(elt)
    case(DAE.FUNCTION(functions=DAE.FUNCTION_EXT()::_)) then true;
    else false;
  end match;
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
        elts = listAppend(elts1,elts2);
        // t2 = clock();
        // ti = t2 -. t1;
        // fprintln(Flags.INNER_OUTER, " joinDAEs: (" + realString(ti) + ") -> " + intString(listLength(elts1)) + " + " +  intString(listLength(elts2)));
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

public function splitElements
  "This functions splits DAE elements into multiple groups."
  input list<DAE.Element> elements;
  output list<DAE.Element> variables = {};
  output list<DAE.Element> initialEquations = {};
  output list<DAE.Element> initialAlgorithms = {};
  output list<DAE.Element> equations = {};
  output list<DAE.Element> algorithms = {};
  output list<DAE.Element> classAttributes = {};
  output list<DAE.Element> constraints = {};
  output list<DAE.Element> externalObjects = {};
  output list<DAEDump.compWithSplitElements> stateMachineComps = {};
  output list<SCode.Comment> comments = {};
protected
  DAEDump.compWithSplitElements split_comp;
algorithm
  for e in elements loop
    _ := match e
      case DAE.VAR()
        algorithm variables := e :: variables; then ();

      case DAE.INITIALEQUATION()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIAL_ARRAY_EQUATION()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIAL_COMPLEX_EQUATION()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIALDEFINE()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIAL_IF_EQUATION()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIAL_ASSERT()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIAL_TERMINATE()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIAL_NORETCALL()
        algorithm initialEquations := e :: initialEquations; then ();
      case DAE.INITIALALGORITHM()
        algorithm initialAlgorithms := e :: initialAlgorithms; then ();

      case DAE.EQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.EQUEQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.ARRAY_EQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.COMPLEX_EQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.DEFINE()
        algorithm equations := e :: equations; then ();
      case DAE.ASSERT()
        algorithm equations := e :: equations; then ();
      case DAE.TERMINATE()
        algorithm equations := e :: equations; then ();
      case DAE.IF_EQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.FOR_EQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.WHEN_EQUATION()
        algorithm equations := e :: equations; then ();
      case DAE.REINIT()
        algorithm equations := e :: equations; then ();
      case DAE.NORETCALL()
        algorithm equations := e :: equations; then ();

      case DAE.ALGORITHM()
        algorithm algorithms := e :: algorithms; then ();
      case DAE.CONSTRAINT()
        algorithm constraints := e :: constraints; then ();
      case DAE.CLASS_ATTRIBUTES()
        algorithm classAttributes := e :: classAttributes; then ();
      case DAE.EXTOBJECTCLASS()
        algorithm externalObjects := e :: externalObjects; then ();
      case DAE.COMP()
        algorithm variables := listAppend(e.dAElist, variables); then ();
      case DAE.FLAT_SM()
        algorithm
          split_comp := splitComponent(DAE.COMP(e.ident, e.dAElist,
            DAE.emptyElementSource, SOME(SCode.COMMENT(NONE(), SOME("stateMachine")))));
          stateMachineComps := split_comp :: stateMachineComps;
        then
          ();
      case DAE.SM_COMP()
        algorithm
          split_comp := splitComponent(DAE.COMP(ComponentReference.crefStr(e.componentRef),
            e.dAElist, DAE.emptyElementSource, SOME(SCode.COMMENT(NONE(), SOME("state")))));
          stateMachineComps := split_comp :: stateMachineComps;
        then
          ();

      case DAE.COMMENT()
        algorithm comments := e.cmt :: comments; then ();

      else
        algorithm
          Error.addInternalError("DAEUtil.splitElements got unknown element.", AbsynUtil.dummyInfo);
        then
          fail();
    end match;
  end for;

  variables := listReverse(variables);
  initialEquations := listReverse(initialEquations);
  initialAlgorithms := listReverse(initialAlgorithms);
  equations := listReverse(equations);
  algorithms := listReverse(algorithms);
  classAttributes := listReverse(classAttributes);
  constraints := listReverse(constraints);
  externalObjects := listReverse(externalObjects);
  stateMachineComps := listReverse(stateMachineComps);
end splitElements;

public function splitComponent
  "Transforms a DAE.COMP to a DAEDump.COMP_WITH_SPLIT."
  input DAE.Element component;
  output DAEDump.compWithSplitElements splitComponent;
protected
  list<DAE.Element> v, ie, ia, e, a, co, o, ca;
  list<DAEDump.compWithSplitElements> sm;
protected
  DAEDump.splitElements split_el;
algorithm
  splitComponent := match component
    case DAE.COMP()
      algorithm
        (v, ie, ia, e, a, co, o, ca, sm) := splitElements(component.dAElist);
        split_el := DAEDump.SPLIT_ELEMENTS(v, ie, ia, e, a, co, o, ca, sm);
      then
        DAEDump.COMP_WITH_SPLIT(component.ident, split_el, component.comment);
  end match;
end splitComponent;

protected function isIfEquation "Succeeds if Element is an if-equation.
"
  input DAE.Element inElement;
algorithm
  _:=
  match (inElement)
    case DAE.IF_EQUATION() then ();
    case DAE.INITIAL_IF_EQUATION() then ();
  end match;
end isIfEquation;

public function collectLocalDecls
"Used to traverse expressions and collect all local declarations"
  input DAE.Exp e;
  input list<DAE.Element> inElements;
  output DAE.Exp outExp;
  output list<DAE.Element> outElements;
algorithm
  (outExp,outElements) := match (e,inElements)
    local
      list<DAE.Element> ld1,ld2,ld;
    case (DAE.MATCHEXPRESSION(localDecls = ld1),ld2)
      equation
        ld = listAppend(ld1,ld2);
      then (e,ld);
    else (e,inElements);
  end match;
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
    else
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
        (_,(_,els1)) = traverseDAEFunctions(elements, Expression.traverseSubexpressionsHelper, (collectLocalDecls,{}));
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
  output list<DAE.Element> outEls = {};
algorithm
  for ex in exps loop
    _ := match ex
      local
        list<DAE.Element> els1;
      case DAE.MATCHEXPRESSION(localDecls = els1)
        algorithm
          outEls := List.append_reverse(els1, outEls);
        then ();
      else ();
    end match;
  end for;
  outEls := MetaModelica.Dangerous.listReverseInPlace(outEls);
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
//         (d,_,ht) = traverseDAE(dae,DAE.AvlTreePathFunction.Tree.EMPTY(),simpleInlineDerEuler,ht);
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
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
protected
  DAE.DAElist dAElist;
  list<DAE.Element> elts;
  AvlSetCR.Tree ht;
algorithm
  // Transform Modelica state machines to flat data-flow equations
  dAElist := StateMachineFlatten.stateMachineToDataFlow(cache, env, inDAElist);

  if Flags.isSet(Flags.SCODE_INST) then
    // This is stupid, but `outDAElist := dAElist` causes crashes for some reason. GC bug?
    DAE.DAE(elts) := dAElist;
    outDAElist := DAE.DAE(elts);
  else
    DAE.DAE(elts) := dAElist;

    ht := FCore.getEvaluatedParams(cache);
    elts := List.map1(elts, makeEvaluatedParamFinal, ht);

    if Flags.isSet(Flags.PRINT_STRUCTURAL) then
      transformationsBeforeBackendNotification(ht);
    end if;

    outDAElist := DAE.DAE(elts);
  end if;

  // Don't even run the function to try and do this; it doesn't work very well
  // outDAElist := transformDerInline(outDAElist);
end transformationsBeforeBackend;

protected function transformationsBeforeBackendNotification
  input AvlSetCR.Tree ht;
protected
  list<DAE.ComponentRef> crs;
  list<String> strs;
  String str;
algorithm
  crs := AvlSetCR.listKeys(ht);
  if not listEmpty(crs) then
    strs := List.map(crs, ComponentReference.printComponentRefStr);
    str := stringDelimitList(strs, ", ");
    Error.addMessage(Error.NOTIFY_FRONTEND_STRUCTURAL_PARAMETERS, {str});
  end if;
end transformationsBeforeBackendNotification;

protected function makeEvaluatedParamFinal "
  This function makes all evaluated parameters final."
  input DAE.Element inElement;
  input AvlSetCR.Tree ht "evaluated parameters";
  output DAE.Element outElement;
algorithm
  outElement := match (inElement, ht)
    local
      DAE.ComponentRef cr;
      Option<DAE.VariableAttributes> varOpt;
      String id;
      list<DAE.Element> elts;
      DAE.ElementSource source;
      Option<SCode.Comment> cmt;
      DAE.Element elt;

    case (DAE.VAR(componentRef=cr, kind=DAE.PARAM(), variableAttributesOption=varOpt), _) equation
      elt = if AvlSetCR.hasKey(ht, cr) then setVariableAttributes(inElement, setFinalAttr(varOpt, true)) else inElement;
    then elt;

    case (DAE.COMP(id, elts, source, cmt), _) equation
      elts = List.map1(elts, makeEvaluatedParamFinal, ht);
    then DAE.COMP(id, elts, source, cmt);

    else inElement;
  end match;
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
        str = " = " + ValuesUtil.valString(v);
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
    case(DAE.BINDING_FROM_DEFAULT_VALUE()) then "[RECORD SUBMOD]";
    case(DAE.BINDING_FROM_START_VALUE()) then  "[START VALUE]";
  end match;
end printBindingSourceStr;

public function collectValueblockFunctionRefVars
"Collect the function names of variables in valueblock local sections"
  input DAE.Exp exp;
  input list<Absyn.Path> acc;
  output DAE.Exp outExp;
  output list<Absyn.Path> outAcc;
algorithm
  (outExp,outAcc) := match (exp,acc)
    local
      list<DAE.Element> decls;
    case (DAE.MATCHEXPRESSION(localDecls = decls),_)
      equation
        outAcc = List.fold(decls, collectFunctionRefVarPaths, acc);
      then (exp,outAcc);
    else (exp,acc);
  end match;
end collectValueblockFunctionRefVars;

public function collectFunctionRefVarPaths
"Collect the function names of declared variables"
  input DAE.Element inElem;
  input list<Absyn.Path> acc;
  output list<Absyn.Path> outAcc;
algorithm
  outAcc := match inElem
    local
      Absyn.Path path;
    case DAE.VAR(ty = DAE.T_FUNCTION(path = path))
      then path::acc;
    else acc;
  end match;
end collectFunctionRefVarPaths;

public function addDaeFunction "add functions present in the element list to the function tree"
  input list<DAE.Function> functions;
  input output DAE.FunctionTree functionTree;
algorithm
  for f in functions loop
    functionTree := DAE.AvlTreePathFunction.add(functionTree, functionName(f), SOME(f));
  end for;
end addDaeFunction;

public function addFunctionDefinition
"adds a functionDefinition to a function. can be used to add function_der_mapper to a function"
  input DAE.Function ifunc;
  input DAE.FunctionDefinition iFuncDef;
  output DAE.Function func = ifunc;
algorithm
  _ := match func
    case DAE.FUNCTION()
      algorithm
        func.functions := List.appendElt(iFuncDef, func.functions);
      then
        ();

    else ();
  end match;
end addFunctionDefinition;

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
      String msg;

    case ({},tree)
      equation
        //showCacheFuncs(tree);
      then tree;

    case (func::funcs,tree)
      equation
        true = isExtFunction(func);
        // print("Add ext to cache: " + AbsynUtil.pathString(functionName(func)) + "\n");
        tree = DAE.AvlTreePathFunction.add(tree,functionName(func),SOME(func));
      then addDaeExtFunction(funcs,tree);

    case (_::funcs,tree) then addDaeExtFunction(funcs,tree);

  end matchcontinue;
end addDaeExtFunction;

public function getFunctionsInfo
  input DAE.FunctionTree ft;
  output list<String> strs;
algorithm
  strs := match ft
    local
      list<tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value>> lst;

    case _
      equation
        lst = DAE.AvlTreePathFunction.toList(ft);
        strs = List.map(lst, getInfo);
        strs = List.sort(strs, Util.strcmpBool);
      then
        strs;
  end match;
end getFunctionsInfo;


public function getInfo
  input tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value> tpl;
  output String str;
algorithm
  str := match tpl
    local
      Absyn.Path p;
    case ((p, NONE()))
      equation
        str = AbsynUtil.pathString(p) + " [invalid]";
      then
        str;
    case ((p, SOME(_)))
      equation
        str = AbsynUtil.pathString(p) + " [valid]  ";
      then
        str;
  end match;
end getInfo;

protected function showCacheFuncs
  input DAE.FunctionTree tree;
algorithm
  _ := match(tree)
    local
      String msg;
    case (_)
      equation
        msg = stringDelimitList(getFunctionsInfo(tree), "\n  ");
        print("Cache has: \n  " + msg + "\n");
      then ();
  end match;
end showCacheFuncs;

public function setAttrVariability "
  Sets the variability attribute in an Attributes record."
  input output DAE.Attributes attr;
  input SCode.Variability var;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  attr.variability := var;
end setAttrVariability;

public function getAttrVariability "
  Get the variability attribute in an Attributes record."
  input DAE.Attributes attr;
  output SCode.Variability var = attr.variability;
  annotation(__OpenModelica_EarlyInline = true);
end getAttrVariability;

public function setAttrDirection
  "Sets the direction attribute in an Attributes record."
  input output DAE.Attributes attr;
  input Absyn.Direction dir;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  attr.direction := dir;
end setAttrDirection;

public function getAttrDirection
  input DAE.Attributes attr;
  output Absyn.Direction dir = attr.direction;
  annotation(__OpenModelica_EarlyInline = true);
end getAttrDirection;

public function setAttrInnerOuter
  "Sets the innerOuter attribute in an Attributes record."
  input output DAE.Attributes attr;
  input Absyn.InnerOuter io;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  attr.innerOuter := io;
end setAttrInnerOuter;

public function getAttrInnerOuter
  input DAE.Attributes attr;
  output Absyn.InnerOuter io = attr.innerOuter;
  annotation(__OpenModelica_EarlyInline = true);
end getAttrInnerOuter;

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
  outAttributes := DAE.ATTR(toConnectorTypeNoState(ct), prl, var, dir, io, vis);
end translateSCodeAttrToDAEAttr;

public function varName
  input DAE.Element var;
  output String name;
algorithm
  DAE.VAR(componentRef=DAE.CREF_IDENT(ident=name)) := var;
end varName;

public function typeVarIdent
  input DAE.Var var;
  output DAE.Ident name;
algorithm
  DAE.TYPES_VAR(name=name) := var;
end typeVarIdent;

public function typeVarIdentEqual
  input DAE.Var var;
  input String name;
  output Boolean b;
protected
  String name2;
algorithm
  DAE.TYPES_VAR(name=name2) := var;
  b := stringEq(name,name2);
end typeVarIdentEqual;

public function varType
  input DAE.Var var;
  output DAE.Type type_;
algorithm
  DAE.TYPES_VAR(ty=type_) := var;
end varType;

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
  isComplete := match(f)
    local
      list<DAE.FunctionDefinition> functions;

    // record constructors are always complete!
    case (DAE.RECORD_CONSTRUCTOR()) then true;

    // functions are complete if they have inputs, outputs and algorithm section
    case (DAE.FUNCTION(functions = functions))
      then isCompleteFunctionBody(functions);

    else false;
  end match;
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
    case (DAE.FUNCTION_EXT()::_) then true;

    // functions are complete if they have inputs, outputs and algorithm section
    case (DAE.FUNCTION_DEF(els)::_)
      equation
        // algs are not empty
        (_,_,_,_,a,_,_,_) = splitElements(els);
        false = listEmpty(a);
      then
        true;

    case (DAE.FUNCTION_DER_MAPPER()::rest)
      then isCompleteFunctionBody(rest);

    else false;
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
  DAE.ConnectorType ct;
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

public function mkEmptyVar
  input String name;
  output DAE.Var outVar;
algorithm
  outVar := DAE.TYPES_VAR(
              name,
              DAE.dummyAttrVar,
              DAE.T_UNKNOWN_DEFAULT,
              DAE.UNBOUND(),
              false,
              NONE());
end mkEmptyVar;

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
        els = sortDAEElementsInModelicaCodeOrder(inElements, els);
      then DAE.DAE(els);

  end match;
end sortDAEInModelicaCodeOrder;

protected function sortDAEElementsInModelicaCodeOrder
"@author: adrpo
 sort the DAE elements back in the order they are in the file"
  input list<tuple<SCode.Element, DAE.Mod>> inElements;
  input list<DAE.Element> inDaeEls;
  output list<DAE.Element> outDaeEls = {};
protected
  list<DAE.Element> rest = inDaeEls;
algorithm
  for e in inElements loop
    _ := match e
      local
        list<DAE.Element> named;
        Absyn.Ident name;
      case (SCode.COMPONENT(name = name),_)
        algorithm
          (named, rest) := splitVariableNamed(rest, name, {}, {});
          outDaeEls := List.append_reverse(named, outDaeEls);
        then ();
      else ();
    end match;
  end for;
  outDaeEls := List.append_reverse(inDaeEls, outDaeEls);
  outDaeEls := MetaModelica.Dangerous.listReverseInPlace(outDaeEls);
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

public function getAllExpandableCrefsFromDAE
"@author: adrpo
 collect all crefs from the DAE"
  input DAE.DAElist inDAE;
  output list<DAE.ComponentRef> outCrefs;
protected
  list<DAE.Element> elts;
algorithm
  DAE.DAE(elts) := inDAE;
  (_, (_, outCrefs)) := traverseDAEElementList(elts, Expression.traverseSubexpressionsHelper, (collectAllExpandableCrefsInExp, {}));
end getAllExpandableCrefsFromDAE;

protected function collectAllExpandableCrefsInExp "collect all crefs from expression"
  input DAE.Exp exp;
  input list<DAE.ComponentRef> acc;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outCrefs;
algorithm
  (outExp,outCrefs) := match (exp,acc)
    local
      DAE.ComponentRef cr;

    case (DAE.CREF(componentRef = cr),_)
      then (exp,List.consOnTrue(ConnectUtil.isExpandable(cr),cr,acc));

    else (exp,acc);

  end match;
end collectAllExpandableCrefsInExp;

public function daeDescription
  input DAE.DAElist inDAE;
  output String comment;
algorithm
  comment := match inDAE
    case DAE.DAE(elementLst=DAE.COMP(comment=SOME(SCode.COMMENT(comment=SOME(comment))))::_) then comment;
    else "";
  end match;
end daeDescription;

public function replaceCallAttrType  "replaces the type in the geiven DAE.CALL_ATTR"
  input DAE.CallAttributes caIn;
  input DAE.Type typeIn;
  output DAE.CallAttributes caOut;
algorithm
  caOut := caIn;
  caOut.ty := typeIn;
  if Types.isTuple(typeIn) then
    caOut.tuple_ := true;
  end if;
end replaceCallAttrType;

public function funcIsRecord
  input DAE.Function func;
  output Boolean isRec;
algorithm
  isRec := match(func)
    case(DAE.RECORD_CONSTRUCTOR())
      then true;
    else
      then false;
   end match;
end funcIsRecord;

public function funcArgDim"gets the number of flattened scalars for a FuncArg"
  input DAE.FuncArg argIn;
  output Integer dim;
algorithm
  dim := match(argIn)
    local
      DAE.Type ty;
      DAE.Dimensions arrayDims;
      list<String> names;
  case(DAE.FUNCARG(ty = DAE.T_ARRAY(dims=arrayDims)))
    equation
      then List.applyAndFold(arrayDims, intAdd, Expression.dimensionSize,0);
  case(DAE.FUNCARG(ty = DAE.T_ENUMERATION(names=names)))
    equation
    then listLength(names);
  else
    then 1;
  end match;
end funcArgDim;

public function toDAEInnerOuter
  input Absyn.InnerOuter ioIn;
  output DAE.VarInnerOuter ioOut;
algorithm
  ioOut := match ioIn
    case Absyn.INNER() then DAE.INNER();
    case Absyn.OUTER() then DAE.OUTER();
    case Absyn.INNER_OUTER() then DAE.INNER_OUTER();
    case Absyn.NOT_INNER_OUTER() then DAE.NOT_INNER_OUTER();
  end match;
end toDAEInnerOuter;

public function getAssertConditionCrefs"gets the crefs of the assert condition.
author:Waurich 2015-04"
  input DAE.Statement stmt;
  input list<DAE.ComponentRef> crefsIn;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := match(stmt,crefsIn)
    local
      DAE.Exp cond;
      list<DAE.ComponentRef> crefs;
  case(DAE.STMT_ASSERT(cond=cond),_)
    algorithm
      crefs := Expression.extractCrefsFromExp(cond);
    then (listAppend(crefsIn,crefs));
    else
    then crefsIn;
  end match;
end getAssertConditionCrefs;

public function getSubscriptIndex "author: marcusw
  Get the index of the given subscript as Integer. If the subscript is not a constant integer, the function returns -1."
  input DAE.Subscript iSubscript;
  output Integer oIndex;
protected
  Integer index;
  DAE.Exp exp;
algorithm
  oIndex := match(iSubscript)
    case(DAE.INDEX(DAE.ICONST(integer=index)))
      then index;
    case(DAE.INDEX(DAE.ENUM_LITERAL(index=index)))
      then index;
    else
      then -1;
  end match;
end getSubscriptIndex;

public function bindingValue
  input DAE.Binding inBinding;
  output Option<Values.Value> outValue;
algorithm
  outValue := match inBinding
    case DAE.EQBOUND() then inBinding.evaluatedExp;
    case DAE.VALBOUND() then SOME(inBinding.valBound);
    else NONE();
  end match;
end bindingValue;

public

function statementsContainReturn
  input list<DAE.Statement> stmts;
  output Boolean b;
algorithm
  (,b) := traverseDAEStmts(stmts, statementsContainReturn2, false);
end statementsContainReturn;

function statementsContainTryBlock
  input list<DAE.Statement> stmts;
  output Boolean b;
algorithm
  (,b) := traverseDAEStmts(stmts, statementsContainTryBlock2, false);
end statementsContainTryBlock;

protected

function statementsContainReturn2
  input DAE.Exp inExp;
  input DAE.Statement inStmt;
  input Boolean b;
  output DAE.Exp outExp = inExp;
  output Boolean ob = b;
algorithm
  if not b then
    ob := match inStmt
      case DAE.STMT_RETURN() then true;
      else (match inExp
        local
          list<DAE.MatchCase> cases;
          list<DAE.Statement> body;
        case DAE.MATCHEXPRESSION(cases=cases)
          algorithm
            for c in cases loop
              if not ob then
                DAE.CASE(body=body) := c;
                ob := statementsContainReturn(body);
              end if;
            end for;
          then ob;
        else false;
      end match);
    end match;
  end if;
end statementsContainReturn2;

function statementsContainTryBlock2
  input DAE.Exp inExp;
  input DAE.Statement inStmt;
  input Boolean b;
  output DAE.Exp outExp = inExp;
  output Boolean ob = b;
algorithm
  if not b then
    ob := match inExp
      case DAE.MATCHEXPRESSION(matchType=DAE.MATCHCONTINUE()) then true;
      else false;
    end match;
  end if;
end statementsContainTryBlock2;

public function getVarBinding "
  Retrive the binding from a list of Elements
  that matches the given cref
"
  input list<DAE.Element> iels;
  input DAE.ComponentRef icr;
  output Option<DAE.Exp> obnd;
protected
  DAE.ComponentRef cr;
  DAE.Exp e;
  list<DAE.Element> lst;
algorithm
  obnd := NONE();
  for i in iels loop
    obnd := match i
      case DAE.VAR(componentRef = cr, binding = obnd)
        algorithm
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      case DAE.DEFINE(componentRef = cr, exp = e)
        algorithm
          obnd := SOME(e);
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      case DAE.INITIALDEFINE(componentRef = cr, exp = e)
        algorithm
          obnd := SOME(e);
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      case DAE.EQUATION(exp = DAE.CREF(componentRef = cr), scalar = e)
        algorithm
          obnd := SOME(e);
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      case DAE.EQUATION(exp = e, scalar = DAE.CREF(componentRef = cr))
        algorithm
          obnd := SOME(e);
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      case DAE.INITIALEQUATION(exp1 = DAE.CREF(componentRef = cr), exp2 = e)
        algorithm
          obnd := SOME(e);
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      case DAE.INITIALEQUATION(exp1 = e, exp2 = DAE.CREF(componentRef = cr))
        algorithm
          obnd := SOME(e);
          if ComponentReference.crefEqualNoStringCompare(icr, cr) then
            return;
          end if;
        then
          obnd;

      else obnd;

    end match;
  end for;
end getVarBinding;

public function evaluateCref
"pour man's constant evaluation"
  input DAE.ComponentRef icr;
  input list<DAE.Element> iels;
  output Option<DAE.Exp> oexp;
protected
  DAE.Exp e, ee;
  list<DAE.ComponentRef> crefs;
  list<Option<DAE.Exp>> oexps;
  Option<DAE.Exp> o;
algorithm
  oexp := getVarBinding(iels, icr);
  if isSome(oexp) then
    SOME(e) := oexp;
    (e, _) := ExpressionSimplify.simplify(e);
    // is constant
    if Expression.isConst(e) then
      oexp := SOME(e);
      return;
    end if;
    // not constant
    crefs := Expression.getAllCrefs(e);
    oexps := List.map1(crefs, evaluateCref, iels);
    for c in crefs loop
      SOME(ee)::oexps := oexps;
      e := Expression.replaceCref(e, (c, ee));
      (e, _) := ExpressionSimplify.simplify(e);
    end for;
    oexp := SOME(e);
  end if;
end evaluateCref;

public function evaluateExp
"pour man's constant evaluation"
  input DAE.Exp iexp;
  input list<DAE.Element> iels;
  output Option<DAE.Exp> oexp = NONE();
protected
  DAE.Exp e, ee;
  list<DAE.ComponentRef> crefs;
  list<Option<DAE.Exp>> oexps;
  Option<DAE.Exp> o;
algorithm
  // is constant
  if Expression.isConst(iexp) then
    oexp := SOME(iexp);
    return;
  end if;

  // not constant
  try
    e := iexp;
    crefs := Expression.getAllCrefs(e);
    oexps := List.map1(crefs, evaluateCref, iels);
    for c in crefs loop
      SOME(ee)::oexps := oexps;
      e := Expression.replaceCrefBottomUp(e, c, ee);
      (e, _) := ExpressionSimplify.simplify(e);
    end for;
    oexp := SOME(e);
  else
    oexp := NONE();
  end try;
end evaluateExp;

public function replaceCrefInDAEElements
  input list<DAE.Element> inElements;
  input DAE.ComponentRef inCref;
  input DAE.Exp inExp;
  output list<DAE.Element> outElements;
protected
  VarTransform.VariableReplacements repl;
algorithm
  repl := VarTransform.emptyReplacements();
  repl := VarTransform.addReplacement(repl,inCref,inExp);
  (outElements, _) := traverseDAEElementList(inElements,replaceCrefBottomUp,repl);
end replaceCrefInDAEElements;

public function replaceCrefBottomUp
  input DAE.Exp inExp;
  input VarTransform.VariableReplacements replIn;
  output DAE.Exp outExp;
  output VarTransform.VariableReplacements replOut;
algorithm
  replOut := replIn;
  (outExp,_) := Expression.traverseExpBottomUp(inExp,replaceCompRef,replIn);
end replaceCrefBottomUp;

protected function replaceCompRef
  input DAE.Exp inExp;
  input VarTransform.VariableReplacements replIn;
  output DAE.Exp outExp;
  output VarTransform.VariableReplacements replOut;
algorithm
  replOut := replIn;
  (outExp,_) := VarTransform.replaceExp(inExp,replIn,NONE());
end replaceCompRef;

public function connectorTypeStr
  input DAE.ConnectorType connectorType;
  output String string;
algorithm
  string := match connectorType
    local
      DAE.ComponentRef cref;
      String cref_str;

    case DAE.POTENTIAL() then "";
    case DAE.FLOW() then "flow";
    case DAE.STREAM(NONE()) then "stream()";
    case DAE.STREAM(SOME(cref))
      algorithm
        cref_str := ComponentReference.printComponentRefStr(cref);
      then
        "stream(" + cref_str + ")";
    else "non connector";
  end match;
end connectorTypeStr;

public function streamBool
  input DAE.ConnectorType inStream;
  output Boolean bStream;
algorithm
  bStream := match(inStream)
    case DAE.STREAM() then true;
    else false;
  end match;
end streamBool;

public function potentialBool
  input DAE.ConnectorType inConnectorType;
  output Boolean outPotential;
algorithm
  outPotential := match(inConnectorType)
    case DAE.POTENTIAL() then true;
    else false;
  end match;
end potentialBool;

public function connectorTypeEqual
  input DAE.ConnectorType inConnectorType1;
  input DAE.ConnectorType inConnectorType2;
  output Boolean outEqual;
algorithm
  outEqual := match(inConnectorType1, inConnectorType2)
    case (DAE.POTENTIAL(), DAE.POTENTIAL()) then true;
    case (DAE.FLOW(), DAE.FLOW()) then true;
    case (DAE.STREAM(_), DAE.STREAM(_)) then true;
    case (DAE.NON_CONNECTOR(), DAE.NON_CONNECTOR()) then true;
  end match;
end connectorTypeEqual;

public function toSCodeConnectorType
 input DAE.ConnectorType daeConnectorType;
 output SCode.ConnectorType scodeConnectorType;
algorithm
  scodeConnectorType := match daeConnectorType
    case DAE.FLOW() then SCode.FLOW();
    case DAE.STREAM(_) then SCode.STREAM();
    case DAE.POTENTIAL() then SCode.POTENTIAL();
    case DAE.NON_CONNECTOR() then SCode.POTENTIAL();
  end match;
end toSCodeConnectorType;

public function mergeAlgorithmSections
"@author: adrpo
 experimental merging of all algorithm sections into:
 - one for initial algorithms
 - one for normal algorithms
 - only happens on a flag (-d=mergeAlgSections)"
  input DAE.DAElist inDae;
  output DAE.DAElist outDae;
protected
  list<DAE.Element> els, newEls = {}, dAElist;
  list<DAE.Statement> istmts = {}, stmts = {}, s;
  DAE.ElementSource source, src;
  DAE.Ident ident;
  Option<SCode.Comment> comment;
algorithm
  // do nothing if the flag is not activated
  if not Flags.isSet(Flags.MERGE_ALGORITHM_SECTIONS) then
    outDae := inDae;
    return;
  end if;

  DAE.DAE(els) := inDae;
  for e in els loop
    _ :=
    match e
      case DAE.COMP(ident, dAElist, src, comment)
        equation
          DAE.DAE(dAElist) = mergeAlgorithmSections(DAE.DAE(dAElist));
          newEls = DAE.COMP(ident, dAElist, src, comment)::newEls;
        then
          ();

      case DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(s), source = source)
        equation
          stmts = List.append_reverse(s, stmts);
        then ();
      case DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(s), source = source)
        equation
          istmts = List.append_reverse(s, istmts);
        then ();
      else
        equation
          newEls = e::newEls;
        then ();
    end match;
  end for;
  if not listEmpty(istmts) then
    newEls := DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(listReverse(istmts)), source) :: newEls;
  end if;
  if not listEmpty(stmts) then
    newEls := DAE.ALGORITHM(DAE.ALGORITHM_STMTS(listReverse(stmts)), source) :: newEls;
  end if;

  newEls := listReverse(newEls);
  outDae := DAE.DAE(newEls);

end mergeAlgorithmSections;

public function moveElementToInitialSection "Converts DAE.Element from the equation section to the initial equation section"
  input output DAE.Element elt;
algorithm
  elt := match elt
    case DAE.EQUATION() then DAE.INITIALEQUATION(elt.exp, elt.scalar, elt.source);
    case DAE.DEFINE() then DAE.INITIALDEFINE(elt.componentRef, elt.exp, elt.source);
    case DAE.ARRAY_EQUATION() then DAE.INITIAL_ARRAY_EQUATION(elt.dimension, elt.exp, elt.array, elt.source);
    case DAE.COMPLEX_EQUATION() then DAE.INITIAL_COMPLEX_EQUATION(elt.lhs, elt.rhs, elt.source);
    case DAE.IF_EQUATION() then DAE.INITIAL_IF_EQUATION(elt.condition1, elt.equations2, elt.equations3, elt.source);
    case DAE.ALGORITHM() then DAE.INITIALALGORITHM(elt.algorithm_, elt.source);
    case DAE.ASSERT() then DAE.INITIAL_ASSERT(elt.condition, elt.message, elt.level, elt.source);
    case DAE.TERMINATE() then DAE.INITIAL_TERMINATE(elt.message, elt.source);
    case DAE.NORETCALL() then DAE.INITIAL_NORETCALL(elt.exp, elt.source);
    else elt;
  end match;
end moveElementToInitialSection;

public function getParameters
  input list<DAE.Element> elts;
  input list<DAE.Element> acc;
  output list<DAE.Element> params;
algorithm
  (params) := match (elts,acc)
    local
      DAE.Element e;
      list<DAE.Element> rest, celts, a;

    case ({},_) then acc;

    case ((DAE.COMP(dAElist = celts))::rest,_)
      algorithm
        a := getParameters(celts, acc);
        a := getParameters(rest, a);
      then
        a;

    case ((e as DAE.VAR())::rest,_)
      then if isParameterOrConstant(e)
           then e::getParameters(rest, acc)
           else getParameters(rest, acc);

    case (_::rest,_)
      then getParameters(rest, acc);

  end match;
end getParameters;

annotation(__OpenModelica_Interface="frontend");
end DAEUtil;
