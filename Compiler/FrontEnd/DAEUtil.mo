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
public import ClassInf;
public import DAE;
public import FCore;
public import SCode;
public import Values;
public import ValuesUtil;
public import HashTable;
public import HashTable2;

protected import Algorithm;
protected import BaseHashTable;
protected import Ceval;
protected import ComponentReference;
protected import Config;
protected import ConnectUtil;
protected import DAEDump;
protected import Debug;
protected import ElementSource;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import System;
protected import Types;
protected import Util;
protected import StateMachineFlatten;

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
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  output Boolean isTopLevel;
algorithm
  isTopLevel := match (inVarDirection, inComponentRef)
    case (DAE.INPUT(), DAE.CREF_IDENT()) then true;
    case (DAE.INPUT(), _)
      guard(ConnectUtil.faceEqual(ConnectUtil.componentFaceType(inComponentRef), Connect.OUTSIDE()))
      then topLevelConnectorType(inConnectorType);
    else false;
  end match;
end topLevelInput;

public function topLevelOutput "author: PA
  if variable is output declared at the top level of the model,
  or if it is an output in a connector instance at top level return true."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  output Boolean isTopLevel;
algorithm
  isTopLevel := match (inVarDirection, inComponentRef)
    case (DAE.OUTPUT(), DAE.CREF_IDENT()) then true;
    case (DAE.OUTPUT(), _)
      guard(ConnectUtil.faceEqual(ConnectUtil.componentFaceType(inComponentRef), Connect.OUTSIDE()))
      then topLevelConnectorType(inConnectorType);
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

    case (_,SOME(DAE.VAR_ATTR_STRING(e1,e2,_,ip,fn,so)))
    then SOME(DAE.VAR_ATTR_STRING(e1,e2,SOME(bindExp),ip,fn,so));

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

    case(DAE.DAE((v as DAE.VAR())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(v::elts2),DAE.DAE(elts3));

    // adrpo: TODO! FIXME! a DAE.COMP SHOULD NOT EVER BE HERE!
    case(DAE.DAE(DAE.COMP(id,elts1,source,cmt)::elts2))
      equation
        (DAE.DAE(elts11),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts1));
        (DAE.DAE(elts22),DAE.DAE(elts33)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts2));
        elts33 = listAppend(elts3,elts33);
      then (DAE.DAE(DAE.COMP(id,elts11,source,cmt)::elts22),DAE.DAE(elts33));

    case(DAE.DAE((e as DAE.EQUATION())::elts2))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts2));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.EQUEQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIALEQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.ARRAY_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIAL_ARRAY_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.COMPLEX_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIAL_COMPLEX_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIALDEFINE())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.DEFINE())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.WHEN_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.IF_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIAL_IF_EQUATION())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.ALGORITHM())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.INITIALALGORITHM())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    // adrpo: TODO! FIXME! why are external object constructor calls added to the non-equations DAE??
    // PA: are these external object constructor CALLS? Do not think so. But they should anyway be in funcs..
    case(DAE.DAE((e as DAE.EXTOBJECTCLASS())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(e::elts2),DAE.DAE(elts3));

    case(DAE.DAE((e as DAE.ASSERT())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.TERMINATE())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    case(DAE.DAE((e as DAE.REINIT())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));

    // handle also NORETCALL! Connections.root(...)
    case(DAE.DAE((e as DAE.NORETCALL())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));
    case(DAE.DAE((e as DAE.INITIAL_NORETCALL())::elts))
      equation
        (DAE.DAE(elts2),DAE.DAE(elts3)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts));
      then (DAE.DAE(elts2),DAE.DAE(e::elts3));
    case(DAE.DAE(_::_))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- DAEUtil.splitDAEIntoVarsAndEquations failed on:\n");
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
protected
  DAE.ComponentRef c;
  DAE.Type ty;
algorithm
  DAE.VAR(componentRef = c, ty = ty) := elt;
  cr := ComponentReference.crefSetLastType(c,ty);
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

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,_,_,i,f,n,ss,unc,distOpt,eb,ip,fn,so)), _, _)
      then SOME(DAE.VAR_ATTR_REAL(q,u,du,inMin,inMax,i,f,n,ss,unc,distOpt,eb,ip,fn,so));

    case (SOME(DAE.VAR_ATTR_INT(q,_,_,i,f,unc,distOpt,eb,ip,fn,so)), _, _)
      then SOME(DAE.VAR_ATTR_INT(q,inMin,inMax,i,f,unc,distOpt,eb,ip,fn,so));

    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,_,_,u,du,eb,ip,fn,so)), _, _)
      then SOME(DAE.VAR_ATTR_ENUMERATION(q,inMin,inMax,u,du,eb,ip,fn,so));

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
    case SOME(va as DAE.VAR_ATTR_REAL())
      algorithm
        va.start := start;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_INT())
      algorithm
        va.start := start;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_BOOL())
      algorithm
        va.start := start;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_STRING())
      algorithm
        va.start := start;
      then SOME(va);
    case SOME(va as DAE.VAR_ATTR_ENUMERATION())
      algorithm
        va.start := start;
      then SOME(va);
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
  match (attr,isProtected)
    local
      Option<DAE.Exp> q,u,du,i,f,n,so,min,max;
      Option<DAE.StateSelect> ss;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distOpt;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;

    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,_,fn,so)),_)
      then SOME(DAE.VAR_ATTR_REAL(q,u,du,min,max,i,f,n,ss,unc,distOpt,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,_,fn,so)),_)
      then SOME(DAE.VAR_ATTR_INT(q,min,max,i,f,unc,distOpt,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,_,fn,so)),_)
    then SOME(DAE.VAR_ATTR_BOOL(q,i,f,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,_,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,_,fn,so)),_)
      then SOME(DAE.VAR_ATTR_ENUMERATION(q,min,max,u,du,eb,SOME(isProtected),fn,so));
    case (SOME(DAE.VAR_ATTR_CLOCK(fn,_)), _)
      then SOME(DAE.VAR_ATTR_CLOCK(fn,SOME(isProtected)));
    case (NONE(),_)
      then SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),SOME(isProtected),NONE(),NONE()));
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
    case (SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,ini,eb,ip,fn,so));
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
    case (SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,_,so)),_)
    then SOME(DAE.VAR_ATTR_STRING(q,i,eb,ip,SOME(finalPrefix),so));
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

public function isInnerVar
  "Returns true if the element is an inner variable."
  input DAE.Element element;
  output Boolean isInner;
algorithm
  isInner := match element
    case DAE.VAR() then Absyn.isInner(element.innerOuter);
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
    case (SCode.STREAM(), _) then DAE.STREAM();
    case (_, ClassInf.CONNECTOR()) then DAE.POTENTIAL();
    else DAE.NON_CONNECTOR();
  end match;
end toConnectorType;

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
        + "' in non-function class: " + ClassInf.printStateStr(inState) + " " + Absyn.pathString(path);

        Error.addSourceMessage(Error.PARMODELICA_WARNING,
          {str1}, inInfo);
      then DAE.PARGLOBAL();

    case (_, SCode.PARLOCAL(), _, _)
      equation
        path = ClassInf.getStateName(inState);
        str1 = "\n" +
        "- DAEUtil.toDaeParallelism: parlocal component '" + ComponentReference.printComponentRefStr(inCref)
        + "' in non-function class: " + ClassInf.printStateStr(inState) + " " + Absyn.pathString(path);

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
        (cache, value,_) = Ceval.ceval(cache, env, rhs, impl, NONE(), Absyn.MSG(info),0);
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
    case ((DAE.TERMINATE(message = e1,source = source)::elts))
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
      then
        (DAE.TERMINATE(e_1,source)::elts_1);
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

    case (_,_) then Util.getOption(avlTreeGet(functions, path));
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        msg = stringDelimitList(List.mapMap(getFunctionList(functions), functionName, Absyn.pathStringDefault), "\n  ");
        msg = "DAEUtil.getNamedFunction failed: " + Absyn.pathString(path) + "\nThe following functions were part of the cache:\n  " + msg;
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

    case (_,_,_) then Util.getOption(avlTreeGet(functions, path));
    else
      equation
        msg = stringDelimitList(List.mapMap(getFunctionList(functions), functionName, Absyn.pathStringDefault), "\n  ");
        msg = "DAEUtil.getNamedFunction failed: " + Absyn.pathString(path) + "\nThe following functions were part of the cache:\n  " + msg;
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
        true = Absyn.pathEqual(functionName(fn),path);
      then fn;
    case (path,fn::fns) then getNamedFunctionFromList(path, fns);
    case (path,{})
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- DAEUtil.getNamedFunctionFromList failed " + Absyn.pathString(path));
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
          Error.addSourceMessageAndFail(Error.REINIT_NOTIN_WHEN, {}, info);
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
          Error.addSourceMessageAndFail(Error.REINIT_NOTIN_WHEN, {}, info);
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
  Boolean initCond = Expression.containsInitialCall(inCond, false);
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
        (elts2,_) = traverseDAE2(elts, Expression.traverseSubexpressionsHelper, (evaluateAnnotationTraverse, (ht1,0,0)));
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
        true = SCode.hasBooleanNamedAnnotation(anno,"Evaluate");
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
        (cache, value,_) = Ceval.ceval(inCache, env, e1, false,NONE(),Absyn.NO_MSG(),0);
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
  (odae,_,_) := traverseDAE(dae, DAE.emptyFuncTree, Expression.traverseSubexpressionsHelper, (removeUniqieIdentifierFromCref, {}));
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
  (odae,_,_) := traverseDAE(dae, DAE.emptyFuncTree, Expression.traverseSubexpressionsHelper, (addUniqueIdentifierToCref, {}));
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
        fns = List.mapMap(lst, Util.tuple22, Util.getOption);
        // fns = List.mapMap(List.select(lst, isValidFunctionEntry), Util.tuple22, Util.getOption);
      then fns;
    case _
      equation
        lst = avlTreeToList(ft);
        lstInvalid = List.select(lst, isInvalidFunctionEntry);
        str = stringDelimitList(list(Absyn.pathString(p) for p in List.map(lstInvalid, Util.tuple21)), "\n ");
        str = "\n " + str + "\n";
        Error.addMessage(Error.NON_INSTANTIATED_FUNCTION, {str});
        fns = List.mapMap(List.select(lst, isValidFunctionEntry), Util.tuple22, Util.getOption);
      then
        fns;
  end matchcontinue;
end getFunctionList;

public function getFunctionNames
  input DAE.FunctionTree ft;
  output list<String> strs;
algorithm
  strs := List.mapMap(getFunctionList(ft), functionName, Absyn.pathStringDefault);
end getFunctionNames;

protected function isInvalidFunctionEntry
  input tuple<DAE.AvlKey,DAE.AvlValue> tpl;
  output Boolean b;
algorithm
  b := match tpl
    case ((_,NONE())) then true;
    else false;
  end match;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
    /*
    case((p,NONE())::funcLst,_,extraArg)
      equation
        (funcLst,extraArg) = traverseDAEFuncLst(funcLst,func,extraArg);
      then (funcLst,extraArg);*/
    case((p,NONE())::_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- DAEUtil.traverseDAEFuncLst failed: " + Absyn.pathString(p));
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
      SCode.Visibility visibility;

      DAE.VarKind kind;

    case (DAE.FUNCTION(path,(DAE.FUNCTION_DEF(body = elist)::derFuncs),ftp,visibility,partialPrefix,isImpure,inlineType,source,cmt),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      then (DAE.FUNCTION(path,DAE.FUNCTION_DEF(elist2)::derFuncs,ftp,visibility,partialPrefix,isImpure,inlineType,source,cmt),extraArg);

    case (DAE.FUNCTION(path,(DAE.FUNCTION_EXT(body = elist,externalDecl=extDecl)::derFuncs),ftp,visibility,partialPrefix,isImpure,_,source,cmt),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      then (DAE.FUNCTION(path,DAE.FUNCTION_EXT(elist2,extDecl)::derFuncs,ftp,visibility,partialPrefix,isImpure,DAE.NO_INLINE(),source,cmt),extraArg);


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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output DAE.Exp outExp;
    output Type_a outA;
  end FuncExpType;
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
      SourceInfo info;

    case(DAE.VAR(cr,kind,dir,prl,prot,tp,optExp,dims,ct,source,attr,cmt,io),_,extraArg)
      equation
        (maybeCrExp,extraArg) = func(Expression.crefExp(cr), extraArg);
        // If the result is DAE.CREF, we replace the name of the variable.
        // Otherwise, we only use the extraArg
        dims = list(match d
            case DAE.DIM_EXP(e)
              equation
                (e2,extraArg) = func(e, extraArg);
              then if referenceEq(e,e2) then d else DAE.DIM_EXP(e2);
            else d;
          end match
          for d in dims);
        cr2 = Util.makeValueOrDefault(Expression.expCref,maybeCrExp,cr);
        (optExp,extraArg) = traverseDAEOptExp(optExp,func,extraArg);
        (attr,extraArg) = traverseDAEVarAttr(attr,func,extraArg);
        elt = DAE.VAR(cr2,kind,dir,prl,prot,tp,optExp,dims,ct,source,attr,cmt,io);
      then
        (elt,extraArg);

    case(DAE.DEFINE(cr,e,source),_,extraArg)
      equation
        (e2,extraArg) = func(e, extraArg);
        (DAE.CREF(cr2,_),extraArg) = func(Expression.crefExp(cr), extraArg);
        elt = DAE.DEFINE(cr2,e2,source);
      then
        (elt,extraArg);

    case(DAE.INITIALDEFINE(cr,e,source),_,extraArg)
      equation
        (e2,extraArg) = func(e, extraArg);
        (DAE.CREF(cr2,_),extraArg) = func(Expression.crefExp(cr), extraArg);
        elt = DAE.INITIALDEFINE(cr2,e2,source);
      then
        (elt,extraArg);

    case(DAE.EQUEQUATION(cr,cr1,source),_,extraArg)
      equation
        (DAE.CREF(cr2,_),extraArg) = func(Expression.crefExp(cr), extraArg);
        (DAE.CREF(cr1_2,_),extraArg) = func(Expression.crefExp(cr1), extraArg);
        elt = DAE.EQUEQUATION(cr2,cr1_2,source);
      then
        (elt,extraArg);

    case(DAE.EQUATION(e1,e2,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1, extraArg);
        (e22,extraArg) = func(e2, extraArg);
        elt = DAE.EQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.COMPLEX_EQUATION(e1,e2,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1, extraArg);
        (e22,extraArg) = func(e2, extraArg);
        elt = DAE.COMPLEX_EQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.ARRAY_EQUATION(idims,e1,e2,source),_,extraArg)
      equation
        (e11, extraArg) = func(e1, extraArg);
        (e22, extraArg) = func(e2, extraArg);
        elt = DAE.ARRAY_EQUATION(idims,e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.INITIAL_ARRAY_EQUATION(idims,e1,e2,source),_,extraArg)
      equation
        (e11, extraArg) = func(e1, extraArg);
        (e22, extraArg) = func(e2, extraArg);
        elt = DAE.INITIAL_ARRAY_EQUATION(idims,e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.WHEN_EQUATION(e1,elist,SOME(elt),source),_,extraArg)
      equation
        (e11, extraArg) = func(e1, extraArg);
        ({elt2}, extraArg)= traverseDAE2_tail({elt},func,extraArg,{});
        (elist2, extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.WHEN_EQUATION(e11,elist2,SOME(elt2),source);
      then
        (elt,extraArg);

    case(DAE.WHEN_EQUATION(e1,elist,NONE(),source),_,extraArg)
      equation
        (e11,extraArg) = func(e1, extraArg);
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.WHEN_EQUATION(e11,elist2,NONE(),source);
      then
        (elt,extraArg);

    case(DAE.INITIALEQUATION(e1,e2,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1, extraArg);
        (e22,extraArg) = func(e2, extraArg);
        elt = DAE.INITIALEQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1, extraArg);
        (e22,extraArg) = func(e2, extraArg);
        elt = DAE.INITIAL_COMPLEX_EQUATION(e11,e22,source);
      then
        (elt,extraArg);

    case(DAE.COMP(id,elist,source,cmt),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.COMP(id,elist2,source,cmt);
      then
        (elt,extraArg);

    case(elt as DAE.EXTOBJECTCLASS(_,_),_,extraArg)
      then (elt,extraArg);

    case(DAE.ASSERT(e1,e2,e3,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1,extraArg);
        (e22,extraArg) = func(e2,extraArg);
        (e32,extraArg) = func(e3,extraArg);
        elt = DAE.ASSERT(e11,e22,e32,source);
      then
        (elt,extraArg);

    case(DAE.TERMINATE(e1,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1,extraArg);
        elt = DAE.TERMINATE(e11,source);
      then
        (elt,extraArg);

    case(DAE.NORETCALL(e1,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1,extraArg);
        elt = DAE.NORETCALL(e11,source);
      then
        (elt,extraArg);

    case(DAE.INITIAL_NORETCALL(e1,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1,extraArg);
        elt = DAE.INITIAL_NORETCALL(e11,source);
      then
        (elt,extraArg);

    case(DAE.REINIT(cr,e1,source),_,extraArg)
      equation
        (e11,extraArg) = func(e1,extraArg);
        (DAE.CREF(cr2,_),extraArg) = func(Expression.crefExp(cr),extraArg);
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
    case(DAE.NORETCALL(source = source),_,_)
      equation
        info = ElementSource.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,
          {"Empty function call in equations",
           "Move the function calls to appropriate algorithm section"}, info);
      then
        fail();

    case(DAE.FLAT_SM(id,elist),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.FLAT_SM(id,elist2);
      then
        (elt,extraArg);

    case(DAE.SM_COMP(cr,elist),_,extraArg)
      equation
        (elist2,extraArg) = traverseDAE2_tail(elist,func,extraArg,{});
        elt = DAE.SM_COMP(cr,elist2);
      then
        (elt,extraArg);

    case(elt,_,_)
      equation
        str = DAEDump.dumpElementsStr({elt});
        str = "DAEUtil.traverseDAE not implemented correctly for element:" + str;
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

      case(SOME(DAE.VAR_ATTR_STRING(quantity,start,eb,ip,fn,so)),_,extraArg)
        equation
          (quantity,extraArg) = traverseDAEOptExp(quantity,func,extraArg);
          (start,extraArg) = traverseDAEOptExp(start,func,extraArg);
        then (SOME(DAE.VAR_ATTR_STRING(quantity,start,eb,ip,fn,so)),extraArg);

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
  if not Flags.isSet(Flags.INFO_XML_OPERATIONS) then
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
        elts = List.appendNoCopy(elts1,elts2);
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

protected function avlKeyCompare
  input DAE.AvlKey key1;
  input DAE.AvlKey key2;
  output Integer c;
algorithm
  c := Absyn.pathCompareNoQual(key1,key2);
  // c := stringCompare(Absyn.pathStringNoQual(key1),Absyn.pathStringNoQual(key2));
end avlKeyCompare;

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
  output DAE.AvlTree outTree = inTree;
protected
  DAE.AvlKey key;
  list<tuple<DAE.AvlKey,DAE.AvlValue>> values = inValues;
  DAE.AvlValue val;
algorithm
  while not listEmpty(values) loop
    (key,val)::values := values;
    outTree := avlTreeAdd(outTree,key,val);
  end while;
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
    case (DAE.AVLTREENODE(value = NONE(),left = NONE(),right = NONE()),key,value)
      then DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(key,value)),1,NONE(),NONE());

      /* Replace this node.*/
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,_)),height=h,left = left,right = right),key,value)
      equation
        true = Absyn.pathEqual(rkey, key);
        bt = balance(DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(rkey,value)),h,left,right));
      then
        bt;

        /* Insert to right  */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),height=h,left = left,right = (right)),key,value)
      equation
        true = avlKeyCompare(key,rkey) > 0;
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
    else
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
  v := match(bt)
    case(DAE.AVLTREENODE(value=SOME(DAE.AVLTREEVALUE(_,v)))) then v;
  end match;
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
    else equation
      print("balance failed\n");
    then fail();
  end matchcontinue;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
  input Integer difference;
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt = inBt;
algorithm
  if difference < -1 or difference > 1 then
    try
      outBt :=  doBalance2(difference, inBt);
    else
      outBt  := inBt;
    end try;
  else
    outBt := computeHeight(inBt);
  end if;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Integer difference;
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
protected
  DAE.AvlTree bt = inBt;
algorithm
  if difference < 0 then
    bt := doBalance3(bt);
    bt := rotateLeft(bt);
  end if;
  if difference > 0 then
    bt := doBalance4(bt);
    bt := rotateRight(bt);
  end if;
  outBt := bt;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := match(inBt)
  local DAE.AvlTree rr,bt;
    case(bt) guard differenceInHeight(getOption(rightNode(bt))) > 0
    equation
      rr = rotateRight(getOption(rightNode(bt)));
      bt = setRight(bt,SOME(rr));
    then bt;
    else inBt;
  end match;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input DAE.AvlTree inBt;
  output DAE.AvlTree outBt;
algorithm
  outBt := match(inBt)
  local DAE.AvlTree rl,bt;
  case(bt) guard differenceInHeight(getOption(leftNode(bt))) < 0
    equation
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
    case(DAE.AVLTREENODE(value,height,l,_),_) then DAE.AVLTREENODE(value,height,l,right);
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
    case(DAE.AVLTREENODE(value,height,_,r),_) then DAE.AVLTREENODE(value,height,left,r);
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

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input DAE.AvlTree inAvlTree;
  input DAE.AvlKey inKey;
  output DAE.AvlValue outValue;
algorithm
  outValue := match (inAvlTree,inKey)
    local
      DAE.AvlKey rkey,key;
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(key=rkey))),key)
      then avlTreeGet2(inAvlTree,avlKeyCompare(key,rkey),key);
  end match;
end avlTreeGet;

protected function avlTreeGet2
  "Get a value from the binary tree given a key."
  input DAE.AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input DAE.AvlKey inKey;
  output DAE.AvlValue outValue;
algorithm
  outValue := match (inAvlTree,keyComp,inKey)
    local
      DAE.AvlKey key;
      DAE.AvlValue rval;
      DAE.AvlTree left,right;

    // hash func Search to the right
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(value=rval))),0,_)
      then rval;

    // search to the right
    case (DAE.AVLTREENODE(right = SOME(right)),1,key)
      then avlTreeGet(right, key);

    // search to the left
    case (DAE.AVLTREENODE(left = SOME(left)),-1,key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

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
  outString := match (inTypeAOption,inFuncTypeTypeAToString)
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
  end match;
end getOptionStr;

public function printAvlTreeStr "
  Prints the avl tree to a string"
  input DAE.AvlTree inAvlTree;
  output String outString;
algorithm
  outString := match (inAvlTree)
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
        res = "< value=" + valueStr(rval) + ",key=" + keyStr(rkey) + ",height="+ intString(h)+ s2 + s3 + ">\n";
      then
        res;
    case (DAE.AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "<NONE," + s2 + ", "+ s3 + ">";

      then
        res;
  end match;
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
 case(DAE.AVLTREENODE(value=v as SOME(DAE.AVLTREEVALUE(_,_)),left=l,right=r)) equation
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
  output list<DAEDump.compWithSplitElements> sm;
algorithm
  (v,ie,ia,e,a,ca,co,o,sm) := splitElements_dispatch(inElements,{},{},{},{},{},{},{},{},{});
end splitElements;
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

public function splitElements_dispatch
"@author: adrpo
  This function will split DAE elements into:
   variables, initial equations, initial algorithms,
   equations, algorithms, constraints, external objects and state machines"
  input list<DAE.Element> inElements;
  input list<DAE.Element> in_v_acc;   // variables
  input list<DAE.Element> in_ie_acc;  // initial equations
  input list<DAE.Element> in_ia_acc;  // initial algorithms
  input list<DAE.Element> in_e_acc;   // equations
  input list<DAE.Element> in_a_acc;   // algorithms
  input list<DAE.Element> in_ca_acc;  // class Attribute
  input list<DAE.Element> in_co_acc;  // constraints
  input list<DAE.Element> in_o_acc;
  input list<DAEDump.compWithSplitElements> in_sm_acc;  // state machine components
  output list<DAE.Element> v;
  output list<DAE.Element> ie;
  output list<DAE.Element> ia;
  output list<DAE.Element> e;
  output list<DAE.Element> a;
  output list<DAE.Element> ca;
  output list<DAE.Element> co;
  output list<DAE.Element> o;
  output list<DAEDump.compWithSplitElements> sm;
algorithm
  (v,ie,ia,e,a,ca,co,o,sm) := match(inElements,in_v_acc,in_ie_acc,in_ia_acc,in_e_acc,in_a_acc,in_ca_acc,in_co_acc,in_o_acc,in_sm_acc)
    local
      DAE.Element el;
      list<DAE.Element> rest, ell, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc;
      list<DAEDump.compWithSplitElements> sm_acc,sm2;
      list<DAE.Element> v2,ie2,ia2,e2,a2,ca2,co2,o2;
      DAEDump.splitElements loc_splelem;
      DAEDump.compWithSplitElements compWSplElem;
      DAE.ComponentRef cref;
      DAE.Ident n;

    // handle empty case
    case ({}, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
    then (listReverse(v_acc),listReverse(ie_acc),listReverse(ia_acc),listReverse(e_acc),listReverse(a_acc),listReverse(ca_acc),listReverse(co_acc),listReverse(o_acc),listReverse(sm_acc));

    // variables
    case ((el as DAE.VAR())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, el::v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // initial equations
    case ((el as DAE.INITIALEQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.INITIAL_ARRAY_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.INITIAL_COMPLEX_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.INITIALDEFINE())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.INITIAL_IF_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // equations
    case ((el as DAE.EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.EQUEQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.ARRAY_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.COMPLEX_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.DEFINE())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.ASSERT())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.IF_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.WHEN_EQUATION())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.REINIT())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.NORETCALL())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,el::e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
    case ((el as DAE.INITIAL_NORETCALL())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,el::ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // initial algorithms
    case ((el as DAE.INITIALALGORITHM())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,el::ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // algorithms
    case ((el as DAE.ALGORITHM())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,el::a_acc,ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // constraints
    case ((el as DAE.CONSTRAINT())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,el::co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // ClassAttributes
    case ((el as DAE.CLASS_ATTRIBUTES())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,el::ca_acc,co_acc,o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    // external objects
    case ((el as DAE.EXTOBJECTCLASS())::rest,v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc) = splitElements_dispatch(rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,el::o_acc,sm_acc);
      then
        (v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc);

    case ((DAE.COMP(dAElist = ell))::rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        v_acc = listAppend(ell, v_acc);
        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,sm_acc) =
          splitElements_dispatch(rest, v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,sm_acc);
      then
        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,sm_acc);

    // state machine
    case ((DAE.FLAT_SM(ident = n,dAElist = ell))::rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        (v2,ie2,ia2,e2,a2,ca2,co2,o2,sm2) = DAEUtil.splitElements(ell);
        loc_splelem = DAEDump.SPLIT_ELEMENTS(v2,ie2,ia2,e2,a2,ca2,co2,o2,sm2);
        /* Hack: Encode FLAT_SM kind into comment ("stateMachine") */
        compWSplElem = DAEDump.COMP_WITH_SPLIT(n, loc_splelem, SOME(SCode.COMMENT(NONE(),SOME("stateMachine"))));

        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,sm_acc) =
          splitElements_dispatch(rest, v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,compWSplElem::sm_acc);
      then
        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc, sm_acc);

    // state machine components
    case ((DAE.SM_COMP(componentRef = cref,dAElist = ell))::rest, v_acc,ie_acc,ia_acc,e_acc,a_acc,ca_acc,co_acc,o_acc,sm_acc)
      equation
        n = ComponentReference.crefStr(cref);
        (v2,ie2,ia2,e2,a2,ca2,co2,o2,sm2) = DAEUtil.splitElements(ell);
        loc_splelem = DAEDump.SPLIT_ELEMENTS(v2,ie2,ia2,e2,a2,ca2,co2,o2,sm2);
        /* Hack: Encode SM_COMP kind into comment ("state") */
        compWSplElem = DAEDump.COMP_WITH_SPLIT(n, loc_splelem, SOME(SCode.COMMENT(NONE(),SOME("state"))));

        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,sm_acc) =
          splitElements_dispatch(rest, v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc,compWSplElem::sm_acc);
      then
        (v_acc, ie_acc, ia_acc, e_acc, a_acc,ca_acc,co_acc, o_acc, sm_acc);

  end match;
end splitElements_dispatch;

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
  input FCore.Cache cache;
  input FCore.Graph env;
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
protected
  DAE.DAElist dAElist;
  list<DAE.Element> elts;
  HashTable.HashTable ht;
algorithm
  // Transform Modelica state machines to flat data-flow equations
  dAElist := StateMachineFlatten.stateMachineToDataFlow(cache, env, inDAElist);

  DAE.DAE(elts) := dAElist;

  ht := FCore.getEvaluatedParams(cache);
  elts := List.map1(elts, makeEvaluatedParamFinal, ht);

  if Flags.isSet(Flags.PRINT_STRUCTURAL) then
    transformationsBeforeBackendNotification(ht);
  end if;
  outDAElist := DAE.DAE(elts);
  // Don't even run the function to try and do this; it doesn't work very well
  // outDAElist := transformDerInline(outDAElist);
end transformationsBeforeBackend;

protected function transformationsBeforeBackendNotification
  input HashTable.HashTable ht;
algorithm
  _ := matchcontinue ht
    local
      list<DAE.ComponentRef> crs;
      list<String> strs;
      String str;
    case _
      equation
        (crs as _::_) = BaseHashTable.hashTableKeyList(ht);
        strs = List.map(crs, ComponentReference.printComponentRefStr);
        strs = List.sort(strs, Util.strcmpBool);
        str = stringDelimitList(strs, ", ");
        Error.addMessage(Error.NOTIFY_FRONTEND_STRUCTURAL_PARAMETERS, {str});
      then ();
    else ();
  end matchcontinue;
end transformationsBeforeBackendNotification;

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
      // print("Make cr final " + ComponentReference.printComponentRefStr(cr) + "\n");
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
  outAcc := match(inElem,acc)
    local
      Absyn.Path path;
    case (DAE.VAR(ty = DAE.T_FUNCTION(source = {path})),_)
      then path::acc;
    else acc;
  end match;
end collectFunctionRefVarPaths;

public function addDaeFunction "add functions present in the element list to the function tree"
  input list<DAE.Function> ifuncs;
  input DAE.FunctionTree itree;
  output DAE.FunctionTree outTree;
algorithm
  outTree := match (ifuncs,itree)
    local
      DAE.Function func, fOld;
      list<DAE.Function> funcs;
      DAE.FunctionTree tree;
      String msg;

    case ({},tree)
      equation
        //showCacheFuncs(tree);
      then
        tree;
/*
    case (func::funcs,tree)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        // print("Add to cache [check] : " + Absyn.pathString(functionName(func)) + "\n");
        // print("Function added: \n" + DAEDump.dumpFunctionStr(func) + "\n");
        fOld = Util.getOption(avlTreeGet(tree, functionName(func)));
        failure(equality(fOld = func));
        print("Function already in the tree and different (keep the one already in the tree):" +
          "\nnew:\n" + DAEDump.dumpFunctionStr(func) +
          "\nold:\n" + DAEDump.dumpFunctionStr(fOld) + "\n");
      then
        fail();
*/
    case (func::funcs,tree)
      equation
        // print("Add to cache: " + Absyn.pathString(functionName(func)) + "\n");
        tree = avlTreeAdd(tree,functionName(func),SOME(func));
      then addDaeFunction(funcs,tree);

  end match;
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
        // print("Add ext to cache: " + Absyn.pathString(functionName(func)) + "\n");
        tree = avlTreeAdd(tree,functionName(func),SOME(func));
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
      list<tuple<DAE.AvlKey,DAE.AvlValue>> lst;

    case _
      equation
        lst = avlTreeToList(ft);
        strs = List.map(lst, getInfo);
        strs = List.sort(strs, Util.strcmpBool);
      then
        strs;
  end match;
end getFunctionsInfo;


public function getInfo
  input tuple<DAE.AvlKey,DAE.AvlValue> tpl;
  output String str;
algorithm
  str := match tpl
    local
      Absyn.Path p;
    case ((p, NONE()))
      equation
        str = Absyn.pathString(p) + " [invalid]";
      then
        str;
    case ((p, SOME(_)))
      equation
        str = Absyn.pathString(p) + " [valid]  ";
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
  outAttributes := DAE.ATTR(ct, prl, var, dir, io, vis);
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
  (_, (_, outCrefs)) := traverseDAE2(elts, Expression.traverseSubexpressionsHelper, (collectAllExpandableCrefsInExp, {}));
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
  caOut := match(caIn,typeIn)
    local
      Boolean tpl,bi,impure_,isFunctionPointerCall;
      DAE.CallAttributes ca;
      DAE.InlineType iType;
      DAE.Type ty;
      DAE.TailCall tailCall;
    case(DAE.CALL_ATTR(builtin=bi, isImpure=impure_, isFunctionPointerCall=isFunctionPointerCall, inlineType=iType,tailCall=tailCall),DAE.T_TUPLE(_,_))
      equation
        ca = DAE.CALL_ATTR(typeIn,true,bi,impure_,isFunctionPointerCall,iType,tailCall);
      then
        ca;
    else
      equation
        DAE.CALL_ATTR(tuple_=tpl, builtin=bi, isImpure=impure_, inlineType=iType, isFunctionPointerCall=isFunctionPointerCall, tailCall=tailCall) = caIn;
        ca = DAE.CALL_ATTR(typeIn,tpl,bi,impure_,isFunctionPointerCall,iType,tailCall);
      then
        ca;
  end match;
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

annotation(__OpenModelica_Interface="frontend");
end DAEUtil;
