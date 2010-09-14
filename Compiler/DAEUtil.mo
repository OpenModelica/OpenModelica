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

package DAEUtil
" file:	 DAEUtil.mo
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

public constant DAE.AvlTree emptyFuncTree = DAE.AVLTREENODE(NONE(),0,NONE(),NONE());
public constant DAE.DAElist emptyDae = DAE.DAE({},emptyFuncTree);

public function constStr "return the DAE.Const as a string. (VAR|PARAM|CONST)
Used for debugging."
  input DAE.Const const;
  output String str;
algorithm
  str := matchcontinue(const)
    case(DAE.C_VAR()) then "VAR";
    case(DAE.C_PARAM()) then "PARAM";
    case(DAE.C_CONST()) then "CONST";
      
  end matchcontinue;
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
Alternative names: isArrayType, isExpTypeArray
"
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
      dims = Util.listMap(array_dims, Exp.dimensionSize);
    then dims;
  end matchcontinue;
end expTypeArrayDimensions;

public function derivativeOrder "
Function to sort derivatives.
Used for Util.sort"
input tuple<Integer,DAE.derivativeCond> e1,e2; //greaterThanFunc
output Boolean b;
Integer i1,i2;
algorithm
  b := matchcontinue(e1,e2)
    case((i1,_),(i2,_))
      then Util.isIntGreater(i1,i2);
  end matchcontinue;
end derivativeOrder;

public function getDerivativePaths " collects all paths representing derivative functions for a list of FunctionDefinition's"
  input list<DAE.FunctionDefinition> funcDefs;
  output list<Absyn.Path> paths;
algorithm
  paths := matchcontinue(funcDefs)
  local list<Absyn.Path> pLst1,pLst2;
    Absyn.Path p1,p2;
    case({}) then {};
    case(DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1,defaultDerivative=SOME(p2),lowerOrderDerivatives=pLst1)::funcDefs) equation
      pLst2 = getDerivativePaths(funcDefs);
      paths = Util.listUnion(p1::p2::pLst1,pLst2);
    then paths;
    case(DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1,defaultDerivative=NONE,lowerOrderDerivatives=pLst1)::funcDefs) equation
      pLst2 = getDerivativePaths(funcDefs);
      paths = Util.listUnion(p1::pLst1,pLst2);
    then paths;
    case(_::funcDefs) then getDerivativePaths(funcDefs);
  end matchcontinue;
end getDerivativePaths;

public function addEquationBoundString "
Set the optional equationBound value
"
  input DAE.Exp bindExp;
  input Option<DAE.VariableAttributes> attr;
  output Option<DAE.VariableAttributes> oattr;
algorithm oattr :=
matchcontinue (bindExp,attr)
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
Returned bound equation
"
input DAE.VariableAttributes attr;
output DAE.Exp oe;
algorithm oe := matchcontinue(attr)
  local DAE.Exp beq;
  case (DAE.VAR_ATTR_REAL(equationBound = SOME(beq))) then beq;
  case (DAE.VAR_ATTR_INT(equationBound = SOME(beq))) then beq;
  case (DAE.VAR_ATTR_BOOL(equationBound = SOME(beq))) then beq;
  case (DAE.VAR_ATTR_ENUMERATION(equationBound = SOME(beq))) then beq;
end matchcontinue;
end getBoundStartEquation;

protected import Algorithm;
protected import Ceval;
protected import Debug;
protected import Error;
protected import Exp;
protected import ModUtil;
protected import RTOpts;
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
	    DAE.FunctionTree funcs,funcs1,funcs2;

	  case(DAE.DAE({},funcs)) then  (DAE.DAE({},funcs),DAE.DAE({},funcs));

	  case(DAE.DAE((v as DAE.VAR(componentRef=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(v::elts2,funcs),DAE.DAE(elts3,funcs));

	  // adrpo: TODO! FIXME! a DAE.COMP SHOULD NOT EVER BE HERE!
	  case(DAE.DAE(DAE.COMP(id,elts1,source)::elts2,funcs))
	    equation
	      (DAE.DAE(elts11,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts1,funcs));
	      (DAE.DAE(elts22,_),DAE.DAE(elts33,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts2,funcs));
	      elts3 = listAppend(elts3,elts33);
	    then (DAE.DAE(DAE.COMP(id,elts11,source)::elts22,funcs),DAE.DAE(elts3,funcs));

	  case(DAE.DAE((e as DAE.EQUATION(exp=_))::elts2,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts2,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.EQUEQUATION(cr1=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.INITIALEQUATION(exp1=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.ARRAY_EQUATION(dimension=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

		case(DAE.DAE((e as DAE.INITIAL_ARRAY_EQUATION(dimension=_))::elts,funcs))
			equation
				(DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
			then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.COMPLEX_EQUATION(lhs=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.INITIAL_COMPLEX_EQUATION(lhs=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.INITIALDEFINE(componentRef=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.DEFINE(componentRef=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.WHEN_EQUATION(condition=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.IF_EQUATION(condition1=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.INITIAL_IF_EQUATION(condition1=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.ALGORITHM(algorithm_=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.INITIALALGORITHM(algorithm_=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));
	  // adrpo: TODO! FIXME! why are function calls added to the non-equations DAE??
	  // PA: are these function CALLS? Do not think so. But they should anyway be in funcs..
	  case(DAE.DAE((e as DAE.FUNCTION(path=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(e::elts2,funcs),DAE.DAE(elts3,funcs));

	  // adrpo: TODO! FIXME! why are record constructor calls added to the non-equations DAE??
	  // PA: are these record constructo CALLS? Do not think so. But they should anyway be in funcs..
	  case(DAE.DAE((e as DAE.RECORD_CONSTRUCTOR(path=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(e::elts2,funcs),DAE.DAE(elts3,funcs));

	  // adrpo: TODO! FIXME! why are external object constructor calls added to the non-equations DAE??
	  // PA: are these external object constructor CALLS? Do not think so. But they should anyway be in funcs..
	  case(DAE.DAE((e as DAE.EXTOBJECTCLASS(path=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(e::elts2,funcs),DAE.DAE(elts3,funcs));

	  case(DAE.DAE((e as DAE.ASSERT(condition=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.TERMINATE(message=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  case(DAE.DAE((e as DAE.REINIT(componentRef=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));

	  // handle also NORETCALL! Connections.root(...)
	  case(DAE.DAE((e as DAE.NORETCALL(functionName=_))::elts,funcs))
	    equation
	      (DAE.DAE(elts2,_),DAE.DAE(elts3,_)) = splitDAEIntoVarsAndEquations(DAE.DAE(elts,funcs));
	    then (DAE.DAE(elts2,funcs),DAE.DAE(e::elts3,funcs));
	  case(DAE.DAE(e::elts,funcs))
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
      DAE.FunctionTree functions;
      
    case (DAE.DAE(elements, functions), vars)
      equation
        elements = removeVariablesFromElements(elements, vars);
      then
        DAE.DAE(elements, functions);
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

    // empty case
    case({},_) then {};

    // variable present, remove it
    case(DAE.VAR(componentRef = cr)::rest, variableNames)
      equation
        // variable is in the list! jump over it
        _::_ = Util.listSelect1(variableNames, cr, Exp.crefEqual);
        els = removeVariablesFromElements(rest, variableNames);
      then 
        els;

    // variable not present, keep it        
    case((v as DAE.VAR(componentRef = cr))::rest, variableNames)
      equation
        // variable NOT in the list! jump over it
        {} = Util.listSelect1(variableNames, cr, Exp.crefEqual);
        els = removeVariablesFromElements(rest, variableNames);
      then 
        v::els;

    // handle components
    case(DAE.COMP(id,elist,source)::rest, variableNames)
      equation
        elist = removeVariablesFromElements(elist, variableNames);
        els = removeVariablesFromElements(rest, variableNames);
      then 
        DAE.COMP(id,elist,source)::els;

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
      DAE.FunctionTree funcs;

    case(var,DAE.DAE({},funcs)) then DAE.DAE({},funcs);

    case(var,DAE.DAE((v as DAE.VAR(componentRef = cr))::elist,funcs))
      equation
        true = Exp.crefEqual(var,cr);
      then DAE.DAE(elist,funcs);

    case(var,DAE.DAE(DAE.COMP(id,elist,source)::elist2,funcs))
      equation
        DAE.DAE(elist,_) = removeVariable(var,DAE.DAE(elist,funcs));
        DAE.DAE(elist2,_) = removeVariable(var,DAE.DAE(elist2,funcs));
      then DAE.DAE(DAE.COMP(id,elist,source)::elist2,funcs);

    case(var,DAE.DAE(e::elist,funcs))
      equation
        DAE.DAE(elist,_) = removeVariable(var,DAE.DAE(elist,funcs));
      then DAE.DAE(e::elist,funcs);
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
      DAE.ComponentRef cr; DAE.VarKind kind;
      DAE.VarDirection dir; DAE.Type tp;
      Option<DAE.Exp> bind; DAE.InstDims dim;
      DAE.Flow flow_; list<Absyn.Path> cls;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt; Absyn.InnerOuter io,io2;
      DAE.VarProtection prot; DAE.Stream st;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;

    case(var,DAE.DAE({},funcs)) then DAE.DAE({},funcs);
     /* When having an inner outer, we declare two variables on the same line.
        Since we can not handle this with current instantiation procedure, we create temporary variables in the dae.
        These are named uniqly and renamed later in "instClass"
     */
    case(var,DAE.DAE(DAE.VAR(oldVar,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,(io as Absyn.INNEROUTER()))::elist,funcs))
      equation
        true = compareUniquedVarWithNonUnique(var,oldVar);
        newVar = nameInnerouterUniqueCref(oldVar);
        o = DAE.VAR(oldVar,kind,dir,prot,tp,NONE,dim,flow_,st,source,attr,cmt,Absyn.OUTER()) "intact";
        u = DAE.VAR(newVar,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,Absyn.UNSPECIFIED()) " unique'ified";
        elist3 = u::{o};
        elist= listAppend(elist3,elist);
      then
        DAE.DAE(elist,funcs);

    case(var,DAE.DAE(DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,io)::elist,funcs))
      equation
        true = Exp.crefEqual(var,cr);
        io2 = removeInnerAttribute(io);
      then
        DAE.DAE(DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flow_,st,source,attr,cmt,io2)::elist,funcs);

    case(var,DAE.DAE(DAE.COMP(id,elist,source)::elist2,funcs))
      equation
        DAE.DAE(elist,_) = removeInnerAttr(var,DAE.DAE(elist,funcs));
        DAE.DAE(elist2,_) = removeInnerAttr(var,DAE.DAE(elist2,funcs));
      then DAE.DAE(DAE.COMP(id,elist,source)::elist2,funcs);

    case(var,DAE.DAE(e::elist,funcs))
      equation
        DAE.DAE(elist,funcs)= removeInnerAttr(var,DAE.DAE(elist,funcs));
      then DAE.DAE(e::elist,funcs);
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
  s1 := Exp.printComponentRefStr(cr1);
  s2 := Exp.printComponentRefStr(cr2);
  s1 := System.stringReplace(s1, DAE.UNIQUEIO, "");
  s2 := System.stringReplace(s2, DAE.UNIQUEIO, "");
  equal := stringEqual(s1,s2);
end compareUniquedVarWithNonUnique;

public function nameInnerouterUniqueCref "
Author: BZ, 2008-11
Renames a var to unique name"
  input DAE.ComponentRef inCr;
  output DAE.ComponentRef outCr;
algorithm outCr := matchcontinue(inCr)
  local
    DAE.ComponentRef newChild,child;
    String id;
    DAE.ExpType idt;
    list<DAE.Subscript> subs;
  case(DAE.CREF_IDENT(id,idt,subs))
    equation
      id = DAE.UNIQUEIO +& id;
    then
      DAE.CREF_IDENT(id,idt,subs);
  case(DAE.CREF_QUAL(id,idt,subs,child))
    equation
      newChild = nameInnerouterUniqueCref(child);
    then
      DAE.CREF_QUAL(id,idt,subs,newChild);

end matchcontinue;
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
        DAE.CREF_IDENT(str2,ty,subs);
  case(DAE.CREF_QUAL(str,ty,subs,child),removalString)
    equation
      child_2 = unNameInnerouterUniqueCref(child,removalString);
      str2 = System.stringReplace(str, removalString, "");
    then
      DAE.CREF_QUAL(str2,ty,subs,child_2);
  case(DAE.WILD(),_) then DAE.WILD();
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
input DAE.ComponentRef currVar;
input list<tuple<DAE.ComponentRef, DAE.Exp>> inlst;
output Option<DAE.Exp> binding;
algorithm binding := matchcontinue(currVar,inlst)
  local DAE.ComponentRef cr1,cr2; DAE.Exp e;
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
input DAE.Element elt;
output DAE.ComponentRef cr;
algorithm
  cr := matchcontinue(elt)
    case(DAE.VAR(componentRef = cr)) then cr;
  end matchcontinue;
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
    case (_) then DAE.RCONST(0.0);
  end matchcontinue;
end getStartAttr;

public function getStartAttrFail "
  Return the start attribute. or fails"
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output DAE.Exp start;
algorithm start:= matchcontinue (inVariableAttributesOption)
    local
      DAE.Exp r;
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_BOOL(initial_ = SOME(r)))) then r;
    case (SOME(DAE.VAR_ATTR_STRING(initial_ = SOME(r)))) then r;
  end matchcontinue;
end getStartAttrFail;

public function setVariableAttributes "sets the attributes of a DAE.Element that is VAR"
  input DAE.Element var;
  input Option<DAE.VariableAttributes> varOpt;
  output DAE.Element outVar;
algorithm
  outVar := matchcontinue(var,varOpt)
    local
      DAE.ComponentRef cr; DAE.VarKind k;
      DAE.VarDirection d ; DAE.VarProtection p;
      DAE.Type ty; Option<DAE.Exp> b;
      DAE.InstDims  dims; DAE.Flow fl; DAE.Stream st;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt; Absyn.InnerOuter io;

    case(DAE.VAR(cr,k,d,p,ty,b,dims,fl,st,source,_,cmt,io),varOpt)
      then DAE.VAR(cr,k,d,p,ty,b,dims,fl,st,source,varOpt,cmt,io);
  end matchcontinue;
end setVariableAttributes;

public function setStartAttr "
  sets the start attribute. If NONE, assumes Real attributes."
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp start;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  matchcontinue (attr,start)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
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
    case (NONE,start)
      then SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),SOME(start),NONE,NONE,NONE,NONE,NONE,NONE));
  end matchcontinue;
end setStartAttr;

public function setUnitAttr "
  sets the unit attribute. .
"
  input Option<DAE.VariableAttributes> attr;
  input DAE.Exp unit;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  matchcontinue (attr,unit)
    local
      Option<DAE.Exp> q,u,du,i,f,n,s;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      DAE.Exp r;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
    case (SOME(DAE.VAR_ATTR_REAL(q,u,du,minMax,s,f,n,ss,eb,ip,fn)),unit)
    then SOME(DAE.VAR_ATTR_REAL(q,SOME(unit),du,minMax,s,f,n,ss,eb,ip,fn));
    case (NONE,unit)
      then SOME(DAE.VAR_ATTR_REAL(NONE,SOME(unit),NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,NONE,NONE));
  end matchcontinue;
end setUnitAttr;

public function setProtectedAttr "
  sets the start attribute. If NONE, assumes Real attributes.
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
    case (NONE,isProtected)
      then SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,SOME(isProtected),NONE));
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
  sets the start attribute. If NONE, assumes Real attributes.
"
  input Option<DAE.VariableAttributes> attr;
  input Boolean finalPrefix;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr:=
  matchcontinue (attr,finalPrefix)
    local
      Option<DAE.Exp> q,u,du,i,f,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
      Option<DAE.StateSelect> ss;
      Option<DAE.Exp> eb;
      Option<Boolean> ip,fn;
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

    case (NONE,finalPrefix)
      then SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,NONE,NONE,NONE,NONE,NONE,SOME(finalPrefix)));
  end matchcontinue;
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

public function varHasName "returns true if variable equals name passed as argument"
  input DAE.Element var;
  input DAE.ComponentRef cr;
  output Boolean res;
algorithm
  res := matchcontinue(var,cr)
  local DAE.ComponentRef cr2;
    case(DAE.VAR(componentRef=cr2),cr) equation
      res = Exp.crefEqual(cr2,cr);
    then res;
  end matchcontinue;
end varHasName;

public function hasStartAttr "
  Returns true if variable attributes defines a start value.
"
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
    case (NONE) then "";
    case (SOME(DAE.VAR_ATTR_REAL(initial_ = SOME(r))))
      equation
        s = Exp.printExpStr(r);
      then
        s;
    case (SOME(DAE.VAR_ATTR_INT(initial_ = SOME(r))))
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
  String str_1;
algorithm
  str_1 := Util.stringAppendList({"\"",str,"\""});
end stringToString;


public function getMatchingElements "function getMatchingElements
  author:  LS

  Retrive the elements for which the function given as second argument
  succeeds.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond;
  output list<DAE.Element> elist;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm
  elist := Util.listFilter(elist, cond);
end getMatchingElements;

public function getAllMatchingElements "function getAllMatchingElements
  author:  PA

  Similar to getMatchingElements but traverses down in COMP elements also.
"
  input list<DAE.Element> elist;
  input FuncTypeElementTo cond;
  output list<DAE.Element> elist;
  partial function FuncTypeElementTo
    input DAE.Element inElement;
  end FuncTypeElementTo;
algorithm
  elist := matchcontinue(elist,cond)
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

public function isNormalInlineFunc "
Author BZ
"
input DAE.Element inElem;
output Boolean b;
algorithm
  b := matchcontinue(inElem)
    case(DAE.FUNCTION(inlineType=DAE.NORM_INLINE)) then true;
    case(_) then false;
  end matchcontinue;
end isNormalInlineFunc;

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
      DAE.FunctionTree funcs;

    // handle the empty case
    case(DAE.DAE({},funcs),_,_) then (DAE.DAE({},funcs),DAE.DAE({},funcs));
    // handle the dive-in case
    case(DAE.DAE(DAE.COMP(dAElist=lst)::rest,funcs),cond1,cond2)
      equation
        (DAE.DAE(elist1,_),DAE.DAE(elist2,_)) = findAllMatchingElements(DAE.DAE(lst,funcs),cond1,cond2);
        (DAE.DAE(elist1a,_),DAE.DAE(elist2a,_)) = findAllMatchingElements(DAE.DAE(rest,funcs),cond1,cond2);
        elist1 = listAppend(elist1,elist1a);
        elist2 = listAppend(elist2,elist2a);
      then (DAE.DAE(elist1,funcs),DAE.DAE(elist2,funcs));
    // handle both first and second condition true!
    case(DAE.DAE(e::rest,funcs),cond1,cond2)
      equation
        cond1(e);
        cond2(e);
        (DAE.DAE(elist1,_),DAE.DAE(elist2,_)) = findAllMatchingElements(DAE.DAE(rest,funcs),cond1,cond2);
      then (DAE.DAE(e::elist1,funcs),DAE.DAE(e::elist2,funcs));
    // handle first condition true
    case(DAE.DAE(e::rest,funcs),cond1,cond2)
      equation
        cond1(e);
        (DAE.DAE(elist1,_),DAE.DAE(elist2,_)) = findAllMatchingElements(DAE.DAE(rest,funcs),cond1,cond2);
      then (DAE.DAE(e::elist1,funcs),DAE.DAE(elist2,funcs));
    // handle the second condition
    case(DAE.DAE(e::rest,funcs),cond1,cond2)
      equation
        cond2(e);
        (DAE.DAE(elist1,_),DAE.DAE(elist2,_)) = findAllMatchingElements(DAE.DAE(rest,funcs),cond1,cond2);
      then (DAE.DAE(elist1,funcs),DAE.DAE(e::elist2,funcs));
    // move to next element.
    case(DAE.DAE(e::rest,funcs),cond1,cond2)
      equation
        (DAE.DAE(elist1,_),DAE.DAE(elist2,_)) = findAllMatchingElements(DAE.DAE(rest,funcs),cond1,cond2);
      then (DAE.DAE(elist1,funcs),DAE.DAE(elist2,funcs));
  end matchcontinue;
end findAllMatchingElements;

public function isAfterIndexInlineFunc "
Author BZ
"
input DAE.Element inElem;
output Boolean b;
algorithm
  b := matchcontinue(inElem)
    case(DAE.FUNCTION(inlineType=DAE.AFTER_INDEX_RED_INLINE)) then true;
    case(_) then false;
  end matchcontinue;
end isAfterIndexInlineFunc;

public function isEqualInlineType "
Author BZ
"
input DAE.InlineType a1,a2;
output Boolean b;
algorithm
  b := matchcontinue(a1,a2)
    case(DAE.NO_INLINE,DAE.NO_INLINE) then true;
    case(DAE.NORM_INLINE,DAE.NORM_INLINE) then true;
    case(DAE.AFTER_INDEX_RED_INLINE,DAE.AFTER_INDEX_RED_INLINE) then true;
    case(_,_) then false;
  end matchcontinue;
end isEqualInlineType;

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
  list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isOutputVar);
end getOutputVars;

public function getProtectedVars "
  author: PA

  Retrieve all protected variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isProtectedVar);
end getProtectedVars;

public function getBidirVars "function get_output_vars
  author: LS

  Retrieve all bidirectional variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isBidirVar);
end getBidirVars;

public function getInputVars "
  Retrieve all input variables from an Element list.
"
  input list<DAE.Element> vl;
  output list<DAE.Element> vl_1;
  list<DAE.Element> vl_1;
algorithm
  vl_1 := getMatchingElements(vl, isInput);
end getInputVars;

public function isOutputVar
"Succeeds if Element is an output variable."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.OUTPUT()) then ();
  end matchcontinue;
end isOutputVar;

public function isProtectedVar
"Succeeds if Element is a protected variable."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    case DAE.VAR(protection=DAE.PROTECTED()) then ();
  end matchcontinue;
end isProtectedVar;

public function isPublicVar "
  Succeeds if Element is a public variable.
"
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    case DAE.VAR(protection=DAE.PUBLIC()) then ();
  end matchcontinue;
end isPublicVar;

public function isBidirVar "
  Succeeds if Element is a bidirectional variable.
"
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.BIDIR()) then ();
  end matchcontinue;
end isBidirVar;

public function isInputVar "
  Succeeds if Element is an input variable.
"
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    case DAE.VAR(kind = DAE.VARIABLE(),direction = DAE.INPUT()) then ();
  end matchcontinue;
end isInputVar;

public function isInput "
  Succeeds if Element is an input .
"
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    case DAE.VAR(direction = DAE.INPUT()) then ();
  end matchcontinue;
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
  _ := matchcontinue (inElement)
    case DAE.VAR(componentRef = _) then ();
  end matchcontinue;
end isVar;

public function isFunctionRefVar "
  return true if the element is a function reference variable"
  input DAE.Element inElem;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inElem)
    case DAE.VAR(ty = (DAE.T_FUNCTION(_,_,_),_)) then true;
    case _ then false;
  end matchcontinue;
end isFunctionRefVar;

public function isAlgorithm "function: isAlgorithm
  author: LS

  Succeeds if Element is an algorithm."
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.ALGORITHM(algorithm_ = _) then ();
  end matchcontinue;
end isAlgorithm;

public function isFunction "function: isFunction
  author: LS

  Succeeds if Element is not a function."
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    case DAE.FUNCTION(path = _) then ();
    case DAE.RECORD_CONSTRUCTOR(path = _) then ();
  end matchcontinue;
end isFunction;

public function isFunctionInlineFalse "function: isFunctionInlineFalse
  author: PA

  Succeeds if Element is a function with Inline=false"
  input DAE.Element inElement;
  output Boolean res;
algorithm
  res := matchcontinue (inElement)
    case DAE.FUNCTION(inlineType = DAE.NO_INLINE()) then true;
    case _ then false;
  end matchcontinue;
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

public function getVariableBindingsStr "function: getVariableBindingsStr

  This function takes a `DAE.Element\' list and returns a comma separated
  string of variable bindings.
  E.g. model A Real x=1; Real y=2; end A; => \"1,2\"
"
  input list<DAE.Element> elts;
  output String str;
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
  matchcontinue (inElementLst)
    local
      String expstr,s3,s4,str,s1,s2;
      DAE.Element v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Element> lst;
    case (((v as DAE.VAR(componentRef = cr,binding = SOME(e))) :: (lst as (_ :: _))))
      equation
        expstr = Exp.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((v as DAE.VAR(componentRef = cr,binding = NONE)) :: (lst as (_ :: _))))
      equation
        s1 = "-,";
        s2 = getBindingsStr(lst);
        str = stringAppend(s1, s2);
      then
        str;
    case ({(v as DAE.VAR(componentRef = cr,binding = SOME(e)))})
      equation
        str = Exp.printExpStr(e);
      then
        str;
    case ({(v as DAE.VAR(componentRef = cr,binding = NONE))}) then "";
  end matchcontinue;
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
    case (DAE.VAR(componentRef = cr,binding  = NONE) :: inElementLst)
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
  outFlow:=
  matchcontinue (inBoolean,inState)
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
        cr_1 = Exp.joinCrefs(DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}), cr);
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
        cr_1 = Exp.joinCrefs(DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}), cr);
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
      String cr_str;
      DAE.ComponentRef cr;
      DAE.Exp rhs;
      list<DAE.Element> rest;
      Boolean impl;
      Integer ix;
      DAE.Element el;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;

    case (cache,env,cname,{},_) then (cache,Values.RECORD(cname,{},{},-1));  /* impl */
    case (cache,env,cname,DAE.VAR(componentRef = cr, binding = SOME(rhs)) :: rest, impl)
      equation
        // Debug.fprintln("failtrace", "- DAEUtil.daeToRecordValue typeOfRHS: " +& Exp.typeOfString(rhs));
        (cache, value,_) = Ceval.ceval(cache, env, rhs, impl, NONE, NONE, Ceval.MSG());
        (cache, Values.RECORD(cname,vals,names,ix)) = daeToRecordValue(cache, env, cname, rest, impl);
        cr_str = Exp.printComponentRefStr(cr);
      then
        (cache,Values.RECORD(cname,(value :: vals),(cr_str :: names),ix));
    /*
    case (cache,env,cname,(DAE.EQUATION(exp = DAE.CREF(componentRef = cr),scalar = rhs) :: rest),impl)
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
				true = RTOpts.debugFlag("failtrace");
				funcs = avlTreeNew();
        str = DAEDump.dumpDebugDAE(DAE.DAE({el},funcs));
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
      DAE.FunctionTree funcs;
    case (DAE.DAE(elts,funcs))
      equation
        elts_1 = toModelicaFormElts(elts);
      then
        DAE.DAE(elts_1,funcs);
  end matchcontinue;
end toModelicaForm;

protected function toModelicaFormElts "function: toModelicaFormElts
  Helper function to toModelicaForm."
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
algorithm
  outElementLst:=
  matchcontinue (inElementLst)
    local
      String str,str_1,id;
      list<DAE.Element> elts_1,elts,welts_1,welts,telts_1,eelts_1,telts,eelts,elts2;
      Option<DAE.Exp> d_1,d,f;
      DAE.ComponentRef cr,cr_1;
      DAE.VarKind a;
      DAE.VarDirection b;
      DAE.Type t;
      DAE.InstDims e;
      DAE.Flow g;
      DAE.Stream streamPrefix;
      DAE.Stream s;
      DAE.Element elt_1,elt;
      DAE.DAElist dae_1,dae;
      DAE.VarProtection prot;
      list<Absyn.Path> h;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e_1,e1_1,e2_1,e1,e2;
      Absyn.Path p;
      Absyn.InnerOuter io;
      list<DAE.Exp> conds, conds_1;
      list<list<DAE.Element>> trueBranches, trueBranches_1;
      Boolean partialPrefix;
      list<DAE.FunctionDefinition> derFuncs;
      DAE.InlineType inlineType;
      DAE.ElementSource source "the element origin";

    case ({}) then {};
    case ((DAE.VAR(componentRef = cr,
               kind = a,
               direction = b,
               protection = prot,
               ty = t,
               binding = d,
               dims = e,
               flowPrefix = g,
               streamPrefix = streamPrefix,
               source=source,
               variableAttributesOption = dae_var_attr,
               absynCommentOption = comment,
               innerOuter=io) :: elts))
      local
        DAE.ExpType ty;
      equation
        str = Exp.printComponentRefStr(cr);
        str_1 = Util.stringReplaceChar(str, ".", "_");
        elts_1 = toModelicaFormElts(elts);
        d_1 = toModelicaFormExpOpt(d);
        ty = Exp.crefType(cr);
      then
        (DAE.VAR(DAE.CREF_IDENT(str_1,ty,{}),a,b,prot,t,d_1,e,g,streamPrefix,source,dae_var_attr,comment,io) :: elts_1);

    case ((DAE.DEFINE(componentRef = cr,exp = e,source = source) :: elts))
      local
        DAE.Exp e;
      equation
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.DEFINE(cr_1,e_1,source) :: elts_1);

    case ((DAE.INITIALDEFINE(componentRef = cr,exp = e,source = source) :: elts))
      local
        DAE.Exp e;
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
      local
        DAE.ComponentRef cr1,cr2;
      equation
         DAE.CREF(cr1,_) = toModelicaFormExp(DAE.CREF(cr1,DAE.ET_OTHER()));
         DAE.CREF(cr2,_) = toModelicaFormExp(DAE.CREF(cr2,DAE.ET_OTHER()));
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

    case ((DAE.WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = NONE,source = source) :: elts))
      equation
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.WHEN_EQUATION(e1_1,welts_1,NONE,source) :: elts_1);

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

    case ((DAE.ALGORITHM(algorithm_ = a,source = source) :: elts))
      local
        Algorithm.Algorithm a;
      equation
        print("to_modelica_form_elts(ALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.ALGORITHM(a,source) :: elts_1);

    case ((DAE.INITIALALGORITHM(algorithm_ = a,source = source) :: elts))
      local
        Algorithm.Algorithm a;
      equation
        print("to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.INITIALALGORITHM(a,source) :: elts_1);

    case ((DAE.COMP(ident = id,dAElist = elts2,source = source) :: elts))
      equation
        elts2 = toModelicaFormElts(elts2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.COMP(id,elts2,source) :: elts_1);

    case ((DAE.FUNCTION(path = p,functions = (DAE.FUNCTION_DEF(elts2)::derFuncs),
           type_ = t,partialPrefix=partialPrefix,inlineType = inlineType,source = source) :: elts))
      equation
        elts2 = toModelicaFormElts(elts2);
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.FUNCTION(p,(DAE.FUNCTION_DEF(elts2)::derFuncs),t,partialPrefix,inlineType,source) :: elts_1);

    case ((DAE.FUNCTION(path = p,functions = (DAE.FUNCTION_EXT(elts2, d)::derFuncs),
           type_ = t,partialPrefix=partialPrefix,inlineType = inlineType,source = source) :: elts))
      local DAE.ExternalDecl d;
      equation
        elts_1 = toModelicaFormElts(elts);
        elts2 = toModelicaFormElts(elts2);
      then
        (DAE.FUNCTION(p,(DAE.FUNCTION_EXT(elts2, d)::derFuncs),t,partialPrefix,inlineType,source) :: elts_1);

    case ((DAE.RECORD_CONSTRUCTOR(path = p,type_ = t,source = source) :: elts))
      equation
        elts_1 = toModelicaFormElts(elts);
      then
        (DAE.RECORD_CONSTRUCTOR(p,t,source) :: elts_1);

    case ((DAE.ASSERT(condition = e1,message=e2,source = source) :: elts))
      local
        DAE.Exp e1,e2,e_1,e_2;
      equation
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e1);
        e_2 = toModelicaFormExp(e2);
      then
        (DAE.ASSERT(e_1,e_2,source) :: elts_1);
    case ((DAE.TERMINATE(message = e1,source = source) :: elts))
      local
        DAE.Exp e1,e2,e_1,e_2;
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
  outelem := matchcontinue(newCr, inelem)
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
  end matchcontinue;
end replaceCrefInVar;

protected function toModelicaFormExpOpt "function: toModelicaFormExpOpt
  Helper function to toMdelicaFormElts."
  input Option<DAE.Exp> inExpExpOption;
  output Option<DAE.Exp> outExpExpOption;
algorithm
  outExpExpOption := matchcontinue (inExpExpOption)
    local DAE.Exp e_1,e;
    case (SOME(e)) equation e_1 = toModelicaFormExp(e); then SOME(e_1);
    case (NONE) then NONE;
  end matchcontinue;
end toModelicaFormExpOpt;

protected function toModelicaFormCref "function: toModelicaFormCref
  Helper function to toModelicaFormElts."
  input DAE.ComponentRef cr;
  output DAE.ComponentRef outComponentRef;
  String str,str_1;
  DAE.ExpType ty;
algorithm
  str := Exp.printComponentRefStr(cr);
  ty := Exp.crefType(cr);
  str_1 := Util.stringReplaceChar(str, ".", "_");
  outComponentRef := DAE.CREF_IDENT(str_1,ty,{});
end toModelicaFormCref;

protected function toModelicaFormExp "function: toModelicaFormExp
  Helper function to toModelicaFormElts."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp)
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
        DAE.CREF(cr_1,t);
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
        DAE.RELATION(e1_1,op,e2_1);
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
        DAE.ASUB(e_1,expl);
    case (DAE.SIZE(exp = e,sz = eopt))
      equation
        e_1 = toModelicaFormExp(e);
        eopt_1 = toModelicaFormExpOpt(eopt);
      then
        DAE.SIZE(e_1,eopt_1);
    case (e) then e;
  end matchcontinue;
end toModelicaFormExp;

public function getNamedFunction "Return the FUNCTION with the given name. Fails if not found.
First tries to use the DAE.FunctionTree; if that fails, fall back to the old method of checking
top-level functions."
  input Absyn.Path path;
  input DAE.DAElist dae;
  output DAE.Element outElement;
algorithm
  outElement := matchcontinue (path,dae)
    local
      list<DAE.Element> elements;
      DAE.FunctionTree functions;
    case (path,DAE.DAE(functions = functions)) then avlTreeGet(functions, path);
    case (path,DAE.DAE(elementLst = elements)) then getNamedFunctionFromElementList(path,elements);
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- DAEUtil.getNamedFunction failed");
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getNamedFunctionFromElementList "
  TODO: Only top level functions are checked. Add recursing into the DAE
  and path name checking.
  TODO: External functions?
"
  input Absyn.Path inPath;
  input list<DAE.Element> inElementLst;
  output DAE.Element outElement;
algorithm
  outElement := matchcontinue (inPath,inElementLst)
    local
      Absyn.Path path,elpath;
      DAE.Element el;
      list<DAE.Element> rest,res;
    case (path,((el as DAE.FUNCTION(path = elpath)) :: rest))
      equation
        true = ModUtil.pathEqual(path, elpath);
      then el;
    case (path,((el as DAE.RECORD_CONSTRUCTOR(path = elpath)) :: rest))
      equation
        true = ModUtil.pathEqual(path, elpath);
      then el;
    case (path,(el :: rest)) then getNamedFunctionFromElementList(path, rest);
  end matchcontinue;
end getNamedFunctionFromElementList;

public function getAllExps "function: getAllExps

  This function goes through the DAE structure and finds all the
  expressions and returns them in a list
"
  input list<DAE.Element> elements;
  output list<DAE.Exp> exps;
  list<list<DAE.Exp>> expslist;
algorithm
  expslist := Util.listMap(elements, getAllExpsElement);
  exps := Util.listFlatten(expslist);
end getAllExps;

protected function crefToExp "function: crefToExp

  Makes an expression from a ComponentRef.
"
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inComponentRef)
    local DAE.ComponentRef cref;
    case cref then DAE.CREF(cref,DAE.ET_OTHER());
  end matchcontinue;
end crefToExp;

public function verifyWhenEquation "
Author BZ, 2008-09
This function verifies when-equations.
Returns the crefs written to, and also checks for illegal statements in when-body eqn's.
"
  input list<DAE.Element> inElems;
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm  leftSideCrefs := matchcontinue(inElems)
  local
    list<DAE.Element> elems1,oelems,moreWhen;
    list<DAE.ComponentRef> crefs1,crefs2;
  case({}) then {};
    // no need to check elseWhen, they are beein handled in a reverse order, from inst.mo.
  case(DAE.WHEN_EQUATION(equations=elems1)::moreWhen) then verifyWhenEquationStatements(elems1);
  case(inElems) then verifyWhenEquationStatements(inElems);
  case(inElems)
    equation
      print("-verify_When_Equation FAILED\n");
      //print(DAEDump.dumpElementsStr(elems1) +& "\n\n");
    then fail();
end matchcontinue;
end verifyWhenEquation;

protected function verifyWhenEquationStatements2 ""
  input list<DAE.Exp> inExps;
  input DAE.ElementSource source "the element origin";
  output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs := matchcontinue(inExps,source)
    local
      DAE.Exp e;
      list<DAE.ComponentRef> crefs1,crefs2;
      DAE.ElementSource source "the element origin";
    case({},_) then {};
    case(e::inExps,source)
      equation
        crefs1 = verifyWhenEquationStatements({DAE.EQUATION(e,e,source)});
        crefs2 = verifyWhenEquationStatements2(inExps,source);
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
input list<DAE.Element> inElems;
output list<DAE.ComponentRef> leftSideCrefs;
algorithm
  leftSideCrefs:=
  matchcontinue (inElems)
    local
      String s1,s2;
      Integer i;
      list<DAE.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3;
      DAE.Exp crefexp,exp,cond,ee1,ee2;
      DAE.ComponentRef cref;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.InstDims instdims;
      DAE.Flow flowPrefix;
      DAE.Element el;
      DAE.ExtArg retarg;
      Option<DAE.Exp> bndexp,startvalexp;
      list<Absyn.Path> pathlist;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> ellist,elements,eqs,eqsfalseb,rest;
      list<list<DAE.Element>> eqstrueb;
      list<DAE.ComponentRef> lhsCrefs,crefs1,crefs2,crefs3;
      Option<DAE.Element> elsewhenopt;
      Algorithm.Algorithm alg;
      String id,fname,lang;
      Absyn.Path path;
      list<list<DAE.Exp>> argexps,expslist;
      list<DAE.ExtArg> args;
      Option<Absyn.Annotation> ann;
      DAE.ElementSource source "the element origin";

    case({}) then {};
    case(DAE.VAR(componentRef = _)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DAE.DEFINE(componentRef = cref,exp = exp)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;
    case(DAE.EQUATION(exp = DAE.CREF(cref,_))::rest)
      equation
      lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;
    case(DAE.EQUATION(exp = DAE.TUPLE(exps1),source=source)::rest)
      equation
        crefs1 = verifyWhenEquationStatements2(exps1,source);
        lhsCrefs = verifyWhenEquationStatements(rest);
        lhsCrefs = listAppend(crefs1,lhsCrefs);
      then
        lhsCrefs;
    case(DAE.ARRAY_EQUATION(exp = DAE.CREF(cref, _)) :: rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref :: lhsCrefs;
    case(DAE.EQUEQUATION(cr1=cref,cr2=_)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        cref::lhsCrefs;

    case(DAE.IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb)::rest)
      local list<list<DAE.ComponentRef>> crefslist;
      equation
        crefslist = Util.listMap(eqstrueb,verifyWhenEquationStatements);
        crefs2 = verifyWhenEquationStatements(eqsfalseb);
        crefslist = listAppend(crefslist,{crefs2});
        (crefs1,true) = compareCrefList(crefslist);
        lhsCrefs = verifyWhenEquationStatements(rest);
        lhsCrefs = listAppend(crefs1,lhsCrefs);
      then
        lhsCrefs;
    case(DAE.IF_EQUATION(condition1 = exps,equations2 = eqstrueb,equations3 = eqsfalseb,source=source)::rest)
      local
        list<list<DAE.ComponentRef>> crefslist;
        DAE.ElementSource source "the origin of the element";
      equation
        crefslist = Util.listMap(eqstrueb,verifyWhenEquationStatements);
        crefs2 = verifyWhenEquationStatements(eqsfalseb);
        (crefs1,false) = compareCrefList(crefslist);
        s2 = DAEDump.dumpEquationStr(DAE.IF_EQUATION(exps,eqstrueb,eqsfalseb,source));
        s1 = "Error in IF-equation: \n" +& s2 +& "\n " +& "\nAll branches must write to same variables \n";
        print(s1);
      then
        fail();
    case(DAE.ALGORITHM(algorithm_ = alg)::rest)
      equation
        print("ALGORITHM not implemented for use inside when equation\n");
      then
        fail();
    case(DAE.INITIALALGORITHM(algorithm_ = alg)::rest)
      equation
        print("INITIALALGORITHM not allowed inside when equation\n");
      then
        fail();
    case(DAE.COMP(ident = _)::rest)
      equation
      print("COMP not implemented for use inside when equation\n");
      then
        fail();

    case(DAE.ASSERT(condition=ee1,message=ee2)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DAE.TERMINATE(message = _)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        lhsCrefs;
    case(DAE.REINIT(componentRef=cref)::rest)
      equation
        lhsCrefs = verifyWhenEquationStatements(rest);
      then
        /*cref::*/lhsCrefs;

    case(DAE.FUNCTION(path = path)::rest)
      equation
        print("FUNCTION not allowed inside when equation\n");
      then
        fail();
    case(DAE.RECORD_CONSTRUCTOR(path = path)::rest)
      equation
        print("RECORD_CONSTRUCTOR not allowed inside when equation\n");
      then
        fail();
    case(DAE.INITIAL_IF_EQUATION(condition1 = _)::rest)
      equation print("INITIAL_IF_EQUATION not allowed inside when equation\n");
      then
        fail();
    case(DAE.INITIALEQUATION(exp1 = _)::rest)
      equation print("INITIALEQUATION not allowed inside when equation\n");
      then
        fail();
    // adrpo: TODO! FIXME! WHY??!! we might read from outside file x = readFile();
    case(DAE.NORETCALL(functionName=_)::rest)
      equation print("NORETCALL not allowed inside when equation\n");
      then
        fail();
    case(DAE.WHEN_EQUATION(condition = _)::rest)
      equation
        print(" When-equation inside when equation..?\n");
      then
        fail();
    case(DAE.INITIALDEFINE(componentRef = cref,exp = exp)::_)
      equation
        print("INITIALDEFINE inside when equation, error");
      then
        fail();
    case(_)
      equation
        Debug.fprintln("failtrace", "- DAEUtil.verifyWhenEquationStatements failed");
      then
        fail();
  end matchcontinue;
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
      crefs = Util.listListUnionOnTrue({recRefs,crefs},Exp.crefEqual);
      b2 = intEq(listLength(crefs),i);
      b1 = boolAnd(b1,boolAnd(b2,b3));
    then
      (crefs,b1);
  end matchcontinue;
end compareCrefList;

protected function getAllExpsElement "function: getAllExpsElement
  Helper to getAllExps. Implements getAllExps for different kinds of elements "
  input DAE.Element inElement;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inElement)
    local
      list<DAE.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3,ifcond;
      DAE.Exp crefexp,exp,cond;
      DAE.ComponentRef cref;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<DAE.Exp> bndexp,startvalexp;
      DAE.InstDims instdims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> pathlist;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> ellist,elements,eqs,eqsfalseb;
      list<list<DAE.Element>> eqstrueb;
      Option<DAE.Element> elsewhenopt;
      Algorithm.Algorithm alg;
      String id,fname,lang;
      Absyn.Path path;
      list<list<DAE.Exp>> argexps,expslist;
      list<DAE.ExtArg> args;
      DAE.ExtArg retarg;
      Option<Absyn.Annotation> ann;
      DAE.ElementSource source "the element origin";

    case DAE.VAR(componentRef = cref,
             kind = vk,
             direction= vd,
             ty = ty,
             binding = bndexp,
             dims = instdims,
             flowPrefix = flowPrefix,
             streamPrefix = streamPrefix,
             source = source,
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
    case DAE.DEFINE(componentRef = cref,exp = exp)
      equation
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case DAE.INITIALDEFINE(componentRef = cref,exp = exp)
      equation
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case DAE.EQUATION(exp = e1,scalar = e2)
      local DAE.Exp e1,e2;
      then
        {e1,e2};
    case DAE.EQUEQUATION(cr1=cr1,cr2=cr2)
      local DAE.ComponentRef cr1,cr2; DAE.Exp e1,e2;
        equation
          e1 = crefToExp(cr1);
          e2 = crefToExp(cr2);
      then
        {e1,e2};
    case DAE.WHEN_EQUATION(condition = cond,equations = eqs,elsewhen_ = elsewhenopt)
      equation
        ellist = Util.optionToList(elsewhenopt);
        elements = listAppend(eqs, ellist);
        exps = getAllExps(elements);
      then
        (cond :: exps);
    case DAE.IF_EQUATION(condition1 = ifcond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation
        explist1 = Util.listFlatten(Util.listMap(eqstrueb,getAllExps));
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({ifcond,explist1,explist2});
      then
        exps;
    case DAE.INITIAL_IF_EQUATION(condition1 = ifcond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation
        explist1 = Util.listFlatten(Util.listMap(eqstrueb,getAllExps));
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({ifcond,explist1,explist2});
      then
        exps;
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      local DAE.Exp e1,e2;
      then
        {e1,e2};
    case DAE.ALGORITHM(algorithm_ = alg)
      equation
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case DAE.INITIALALGORITHM(algorithm_ = alg)
      equation
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case DAE.COMP(ident = id,dAElist = elements)
      equation
        exps = getAllExps(elements);
      then
        exps;
    case DAE.FUNCTION(path = path,functions = (DAE.FUNCTION_DEF(body = elements)::_),type_ = ty)
     local tuple<DAE.TType, Option<Absyn.Path>> ty;
      equation
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps = listAppend(exps1, exps2);
      then
        exps;
    case DAE.FUNCTION(path = path,functions = (DAE.FUNCTION_EXT(body = elements,externalDecl = DAE.EXTERNALDECL(ident = fname,external_ = args,parameters = retarg,returnType = lang,language = ann))::_),type_ = ty)
      local tuple<DAE.TType, Option<Absyn.Path>> ty;
      equation
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps3 = getAllExpsExtarg(retarg);
        argexps = Util.listMap(args, getAllExpsExtarg);
        expslist = listAppend({exps1,exps2,exps3}, argexps);
        exps = Util.listFlatten(expslist);
      then
        exps;
    case DAE.RECORD_CONSTRUCTOR(path = path) then {};
    case DAE.ASSERT(condition=e1,message=e2) local DAE.Exp e1,e2; then {e1,e2};
    case DAE.NORETCALL(functionName=fname,functionArgs=fargs)
      local
        Absyn.Path fname;
        list<DAE.Exp> fargs;
      then {DAE.CALL(fname,fargs,false,false,DAE.ET_OTHER(),DAE.NO_INLINE)};

    case _
      equation
        Debug.fprintln("failtrace", "- DAEUtil.getAllExpsElement failed");
      then
        fail();
  end matchcontinue;
end getAllExpsElement;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  Get all exps from a Subscript"
  input DAE.Subscript inSubscript;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inSubscript)
    local DAE.Exp e;
    case DAE.WHOLEDIM() then {};
    case DAE.SLICE(exp = e) then {e};
    case DAE.INDEX(exp = e) then {e};
    case _
      equation
        Debug.fprintln("failtrace", "- DAEUtil.getAllExpsSubscript failed");
      then
        fail();
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsExtarg
"function: getAllExpsExtarg
  Get all exps from an ExtArg"
  input DAE.ExtArg inExtArg;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inExtArg)
    local
      DAE.Exp exp1,crefexp,exp;
      list<DAE.Exp> explist,exps,tyexps;
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
    case DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation
        exp1 = crefToExp(cref);
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case DAE.EXTARGEXP(exp = exp1,type_ = ty)
      equation
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case DAE.EXTARGSIZE(componentRef = cref,attributes = attr,type_ = ty,exp = exp)
      equation
        crefexp = crefToExp(cref);
        tyexps = Types.getAllExps(ty);
        exps = Util.listFlatten({{crefexp},tyexps,{exp}});
      then
        exps;
    case DAE.NOEXTARG() then {};
    case _
      equation
        Debug.fprintln("failtrace", "- DAEUtil.getAllExpsExtarg failed");
      then
        fail();
  end matchcontinue;
end getAllExpsExtarg;

public function transformIfEqToExpr
"function: transformIfEqToExpr
  transform all if equations to ordinary equations involving if-expressions"
  input DAE.DAElist inDAElist;
  input Boolean onlyConstantEval "if true, only perform the constant evaluation part, not transforming to if-expr";
  output DAE.DAElist outDAElist;
algorithm
  outDAElist := matchcontinue (inDAElist,onlyConstantEval)
    local
      DAE.DAElist result,res1,res2,res;
      list<DAE.Element> rest_result,rest,sublist_result,sublist,elts;
      DAE.Element subresult,el;
      String name;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
    case (DAE.DAE({},funcs),onlyConstantEval) then DAE.DAE({},funcs);
    case (DAE.DAE((DAE.COMP(ident = name,dAElist = sublist,source=source) :: rest),funcs),onlyConstantEval)
      equation
        DAE.DAE(sublist_result,_) = transformIfEqToExpr(DAE.DAE(sublist,funcs),onlyConstantEval);
        DAE.DAE(rest_result,funcs) = transformIfEqToExpr(DAE.DAE(rest,funcs),onlyConstantEval);
        subresult = DAE.COMP(name,sublist_result,source);
        result = DAE.DAE((subresult :: rest_result),funcs);
      then
        result;
    case (DAE.DAE((el as (DAE.IF_EQUATION(source = _))):: rest,funcs),onlyConstantEval)
      equation
        elts= ifEqToExpr(el,onlyConstantEval);
        res2 = transformIfEqToExpr(DAE.DAE(rest,funcs),onlyConstantEval);
        res = joinDaes(DAE.DAE(elts,funcs), res2);
      then
        res;
    case (DAE.DAE((el :: rest),funcs),onlyConstantEval)
      equation
        failure(DAE.IF_EQUATION(source = _) = el);
        DAE.DAE(elts,funcs) = transformIfEqToExpr(DAE.DAE(rest,funcs),onlyConstantEval);
      then
        DAE.DAE((el :: elts),funcs);
  end matchcontinue;
end transformIfEqToExpr;

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
     DAE.FunctionTree funcs;

   // nothing selects the else
   case ({}, {}, false_branch, _, _, onlyConstantEval)
   then false_branch;

   // if true select the head from the true_branch
   case (DAE.BCONST(true)::rest, eqs::restTrue, false_branch, _, recursiveCall, onlyConstantEval)
     equation
       // transform further if needed
       funcs = avlTreeNew();
       DAE.DAE(eqs,_) = transformIfEqToExpr(DAE.DAE(eqs,funcs),onlyConstantEval);
     then eqs;

   // if false recurse with rest on both lists
   case (DAE.BCONST(false)::rest, eqs::restTrue, false_branch, source, _, onlyConstantEval)
     equation
       eqs = selectBranches(rest, restTrue, false_branch, source, true, onlyConstantEval);
       // transform further if needed
       funcs = avlTreeNew();
       DAE.DAE(eqs,_) = transformIfEqToExpr(DAE.DAE(eqs,funcs),onlyConstantEval);
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
  outElementLst:=
  matchcontinue (inElement,onlyConstantEval)
    local
      Integer true_eq,false_eq;
      String elt_str;
      DAE.Element elt;
      list<DAE.Exp> cond,fbsExp;
      list<list<DAE.Exp>> tbsExp;
      list<DAE.Element> false_branch,equations;
      list<list<DAE.Element>> true_branch;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;

    // adrpo: handle selection of branches if conditions are boolean literals
    //        this is needed as Connections.isRoot becomes true/false at the
    //        end of instantiation.
    case ((elt as DAE.IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch, source = source)),onlyConstantEval)
      equation
        equations = selectBranches(cond, true_branch, false_branch,source,false,onlyConstantEval);
          funcs = avlTreeNew();
        // transform further if needed
        DAE.DAE(equations,_) = transformIfEqToExpr(DAE.DAE(equations,funcs),onlyConstantEval);
      then
        equations;
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
      Integer nrOfEquations;
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

        ifexp = Exp.makeNestedIf(conds,tbsexp,fbexp);
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
        ty = Exp.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // initial equation
    case(DAE.INITIALEQUATION(e1,e2,_))
      equation
        ty = Exp.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // complex equation
    case(DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2))
      equation
        ty = Exp.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // complex initial equation
    case(DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2))
      equation
        ty = Exp.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
    // equation from connect
    case(DAE.EQUEQUATION(cr1, cr2, _))
      equation
        ty1 = Exp.crefType(cr1);
        ty2 = Exp.crefType(cr2);
        oExp = DAE.BINARY(DAE.CREF(cr1,ty1),DAE.SUB(ty1),DAE.CREF(cr2,ty2));
      then
        oExp;
    // equation from define
    case(DAE.DEFINE(cr1, e2, _))
      equation
        ty1 = Exp.crefType(cr1);
        oExp = DAE.BINARY(DAE.CREF(cr1,ty1),DAE.SUB(ty1),e2);
      then
        oExp;
    // equation from initial define
    case(DAE.INITIALDEFINE(cr1, e2, _))
      equation
        ty1 = Exp.crefType(cr1);
        oExp = DAE.BINARY(DAE.CREF(cr1,ty1),DAE.SUB(ty1),e2);
      then
        oExp;
    // equation from array TODO! check if this works!
    case(DAE.ARRAY_EQUATION(_, e1, e2, _))
      equation
        ty = Exp.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
      then
        oExp;
		// initial array equation
		case(DAE.INITIAL_ARRAY_EQUATION(_, e1, e2, _))
      equation
        ty = Exp.typeof(e1);
        oExp = DAE.BINARY(e1,DAE.SUB(ty),e2);
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
      DAE.Exp exp;
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
  outExpLst := matchcontinue (inExp1,inExpLst2,inExpLst3)
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

        ifexp = Exp.makeNestedIf(conds,tbsFirst,fb);
      then
        (ifexp :: rest_res);
  end matchcontinue;
end makeResidualIfExpLst;

protected function makeEquationsFromResiduals
  input list<DAE.Exp> inExp1;
  input list<list<DAE.Exp>> inExpLst2;
  input list<DAE.Exp> inExpLst3;
  input DAE.ElementSource source "the origin of the element";
  output list<DAE.Element> outExpLst;
algorithm
  outExpLst := matchcontinue (inExp1,inExpLst2,inExpLst3,source)
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

        ifexp = Exp.makeNestedIf(conds,tbsFirst,fb);
        eq = DAE.EQUATION(DAE.RCONST(0.0),ifexp,src);
      then
        (eq :: rest_res);
  end matchcontinue;
end makeEquationsFromResiduals;

public function renameTimeToDollarTime "
Author: BZ, 2009-1
rename the keyword time to globalData->timeValue, this is a special case for functions since they do not get translated in to c_crefs."
  input list<DAE.Element> dae;
  output list<DAE.Element> odae;
algorithm
  (odae,_) := traverseDAE2(dae, renameTimeToDollarTimeVisitor,0);
end renameTimeToDollarTime;

protected function renameTimeToDollarTimeVisitor "
Author: BZ, 2009-01
The visitor function for traverseDAE.calls Exp.traverseExp on the expression."
  input DAE.Exp exp;
  input Integer arg;
  output DAE.Exp oexp;
  output Integer oarg;
algorithm
  (oexp,oarg) := matchcontinue(exp,arg)
    local
      DAE.ExpType ty;
      DAE.ComponentRef cr,cr2;
    case(exp,oarg)
      equation
        ((oexp,oarg)) = Exp.traverseExp(exp,renameTimeToDollarTimeFromCref,oarg);
      then
        (oexp,oarg);
  end matchcontinue;
end renameTimeToDollarTimeVisitor;

protected function renameTimeToDollarTimeFromCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm
  outTplExpExpString := matchcontinue (inTplExpExpString)
    local
      DAE.ComponentRef cr,cr2;
      DAE.ExpType cty,ty;
      Integer oarg;
      list<DAE.Subscript> subs;
    case((DAE.CREF(DAE.CREF_IDENT("time",cty,subs),ty),oarg))
      then ((DAE.CREF(DAE.CREF_IDENT("globalData->timeValue",cty,subs),ty),oarg));
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
  (odae,_) := traverseDAE(dae, renameUniqueVisitor, 0);
end renameUniqueOuterVars;

protected function renameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE.
calls Exp.traverseExp on the expression."
  input DAE.Exp exp;
  input Integer arg;
  output DAE.Exp oexp;
  output Integer oarg;
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    DAE.ExpType ty;
    DAE.ComponentRef cr,cr2;
  case(exp,oarg)
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,removeUniqieIdentifierFromCref,oarg);
    then
      (oexp,oarg);
  end matchcontinue;
end renameUniqueVisitor;

protected function removeUniqieIdentifierFromCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, removes the constant 'UNIQUEIO' from any cref it might visit."
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local DAE.ComponentRef cr,cr2; DAE.ExpType ty; Integer oarg;
  case((DAE.CREF(cr,ty),oarg))
    equation
      cr2 = unNameInnerouterUniqueCref(cr,DAE.UNIQUEIO);
    then ((DAE.CREF(cr2,ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
  end matchcontinue;
end removeUniqieIdentifierFromCref;

public function nameUniqueOuterVars "
Author: BZ, 2008-12
Rename all variables to the form a.b.$unique$var, call
This function traverses the entire dae.
"
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm (odae,_) := traverseDAE(dae, nameUniqueVisitor,0);
end nameUniqueOuterVars;

protected function nameUniqueVisitor "
Author: BZ, 2008-12
The visitor function for traverseDAE.
calls Exp.traverseExp on the expression.
"
input DAE.Exp exp;
input Integer arg;
output DAE.Exp oexp;
output Integer oarg;
algorithm (oexp,oarg) := matchcontinue(exp,arg)
  local
    DAE.ExpType ty;
    DAE.ComponentRef cr,cr2;
  case(exp,oarg)
    equation
      ((oexp,oarg)) = Exp.traverseExp(exp,addUniqueIdentifierToCref,oarg);
    then
      (oexp,oarg);
  end matchcontinue;
end nameUniqueVisitor;

protected function addUniqueIdentifierToCref "
Author: BZ, 2008-12
Function for Exp.traverseExp, adds the constant 'UNIQUEIO' to the CREF_IDENT() part of the cref.
"
  input tuple<DAE.Exp, Integer> inTplExpExpString;
  output tuple<DAE.Exp, Integer> outTplExpExpString;
algorithm outTplExpExpString := matchcontinue (inTplExpExpString)
  local DAE.ComponentRef cr,cr2; DAE.ExpType ty; Integer oarg;
  case((DAE.CREF(cr,ty),oarg))
    equation
      cr2 = nameInnerouterUniqueCref(cr);
    then ((DAE.CREF(cr2,ty),oarg));
    case(inTplExpExpString) then inTplExpExpString;
  end matchcontinue;
end addUniqueIdentifierToCref;

// helper functions for traverseDAE
protected function traverseDAEOptExp "
Author: BZ, 2008-12
Traverse an optional expression, helper function for traverseDAE
"
  input Option<DAE.Exp> oexp;
  input FuncExpType func;
  input Type_a extraArg;
  output Option<DAE.Exp> ooexp;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(ooexp,oextraArg) := matchcontinue(oexp,func,extraArg)
  case(NONE,func,extraArg) then (NONE,extraArg);
  case(SOME(e),func,extraArg)
    local DAE.Exp e;
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
  input list<DAE.Exp> exps;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Exp> oexps;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm(oexps,oextraArg) := matchcontinue(exps,func,extraArg)
  local DAE.Exp e;
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
  input list<list<DAE.Element>> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<list<DAE.Element>> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDaeList,oextraArg) := matchcontinue(daeList,func,extraArg)
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
end matchcontinue;
end traverseDAEList;

public function traverseDAE " This function traverses all dae exps.
NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input DAE.DAElist dae;
  input FuncExpType func;
  input Type_a extraArg;
  output DAE.DAElist traversedDae;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDae,oextraArg) := matchcontinue(dae,func,extraArg)
  local
    list<DAE.Element> elts;
     list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
     DAE.FunctionTree funcs;

  case(DAE.DAE(elts,funcs),func,extraArg) equation
     (elts,extraArg) = traverseDAE2(elts,func,extraArg);
     (funcLst,extraArg) = traverseDAEFuncLst(avlTreeToList(funcs),func,extraArg);
     funcs = avlTreeAddLst(funcLst,avlTreeNew());
  then (DAE.DAE(elts,funcs),extraArg);
  end matchcontinue;
end traverseDAE;

protected function traverseDAEFuncLst "help function to traverseDae. Traverses the functions "
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> funcLst;
  input FuncExpType func;
  input Type_a extraArg;
  output list<tuple<DAE.AvlKey,DAE.AvlValue>> outFuncLst;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;

algorithm
  (outFuncLst,oextraArg) := matchcontinue(funcLst,func,extraArg)
  local
    Absyn.Path p;
    DAE.Element elt;

    case({},func,extraArg) then ({},extraArg);
    case((p,elt)::funcLst,func,extraArg) equation
      ({elt},extraArg) = traverseDAE2({elt},func,extraArg);
      (funcLst,extraArg) = traverseDAEFuncLst(funcLst,func,extraArg);
    then ((p,elt)::funcLst,extraArg);
  end matchcontinue;
end traverseDAEFuncLst;

public function traverseDAE2 "
Author: BZ, 2008-12
This function traverses all dae exps.
NOTE, it also traverses DAE.VAR(componenname) as an expression."
  input list<DAE.Element> daeList;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Element> traversedDaeList;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (traversedDaeList,oextraArg) := matchcontinue(daeList,func,extraArg)
  local
    DAE.ComponentRef cr,cr2,cr1,cr1_2;
    list<DAE.Element> dae,dae2,elist,elist2,elist22,elist1,elist11;
    DAE.Element elt,elt2,elt22,elt1,elt11;
    DAE.VarKind kind;
    DAE.VarDirection dir;
    DAE.Type tp,ftp;
    DAE.InstDims dims;
    DAE.StartValue start;
    DAE.Flow fl;
    DAE.Stream st;
    DAE.ExternalDecl extDecl;
    DAE.VarProtection prot;
    DAE.Exp bindExp,bindExp2,e,e2,e22,e1,e11;
    list<Absyn.Path> clsLst;
    Option<DAE.VariableAttributes> attr;
    Option<SCode.Comment> cmt;
    Option<DAE.Exp> optExp;
    Absyn.InnerOuter io;
    list<Integer> idims;
    String id,str;
    Absyn.Path path;
    list<DAE.Statement> stmts,stmts2;
    list<list<DAE.Element>> tbs,tbs_1;
    list<DAE.Exp> conds,conds_1, args;
    Boolean partialPrefix;
    Absyn.Path path;
    list<DAE.Exp> expl;
    list<DAE.FunctionDefinition> derFuncs;
    DAE.InlineType inlineType;
    DAE.ElementSource source "the origin of the element";

  case({},_,extraArg) then ({},extraArg);
  case(DAE.VAR(cr,kind,dir,prot,tp,optExp,dims,fl,st,source,attr,cmt,io)::dae,func,extraArg)
    equation
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (optExp,extraArg) = traverseDAEOptExp(optExp,func,extraArg);
      (attr,extraArg) = traverseDAEVarAttr(attr,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.VAR(cr2,kind,dir,prot,tp,optExp,dims,fl,st,source,attr,cmt,io)::dae2,extraArg);

  case(DAE.DEFINE(cr,e,source)::dae,func,extraArg)
    equation
      (e2,extraArg) = func(e, extraArg);
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.DEFINE(cr2,e2,source)::dae2,extraArg);

  case(DAE.INITIALDEFINE(cr,e,source)::dae,func,extraArg)
    equation
      (e2,extraArg) = func(e, extraArg);
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.INITIALDEFINE(cr2,e2,source)::dae2,extraArg);

  case(DAE.EQUEQUATION(cr,cr1,source)::dae,func,extraArg)
    equation
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()), extraArg);
      (DAE.CREF(cr1_2,_),extraArg) = func(DAE.CREF(cr1,DAE.ET_REAL()), extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.EQUEQUATION(cr2,cr1_2,source)::dae2,extraArg);

  case(DAE.EQUATION(e1,e2,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.EQUATION(e11,e22,source)::dae2,extraArg);

  case(DAE.COMPLEX_EQUATION(e1,e2,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.COMPLEX_EQUATION(e11,e22,source)::dae2,extraArg);

  case(DAE.ARRAY_EQUATION(idims,e1,e2,source)::dae,func,extraArg)
    equation
      (e11, extraArg) = func(e1, extraArg);
      (e22, extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.ARRAY_EQUATION(idims,e11,e22,source)::dae2,extraArg);

  case(DAE.INITIAL_ARRAY_EQUATION(idims,e1,e2,source)::dae,func,extraArg)
    equation
      (e11, extraArg) = func(e1, extraArg);
      (e22, extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.INITIAL_ARRAY_EQUATION(idims,e11,e22,source)::dae2,extraArg);

  case(DAE.WHEN_EQUATION(e1,elist,SOME(elt),source)::dae,func,extraArg)
    equation
      (e11, extraArg) = func(e1, extraArg);
      ({elt2}, extraArg)= traverseDAE2({elt},func,extraArg);
      (elist2, extraArg) = traverseDAE2(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.WHEN_EQUATION(e11,elist2,SOME(elt2),source)::dae2,extraArg);

  case(DAE.WHEN_EQUATION(e1,elist,NONE,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1, extraArg);
      (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.WHEN_EQUATION(e11,elist2,NONE,source)::dae2,extraArg);

  case(DAE.INITIALEQUATION(e1,e2,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.INITIALEQUATION(e11,e22,source)::dae2,extraArg);

  case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1, extraArg);
      (e22,extraArg) = func(e2, extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.INITIAL_COMPLEX_EQUATION(e11,e22,source)::dae2,extraArg);

  case(DAE.COMP(id,elist,source)::dae,func,extraArg)
    equation
      (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.COMP(id,elist2,source)::dae2,extraArg);

  case(DAE.FUNCTION(path,(DAE.FUNCTION_DEF(body = elist)::derFuncs),ftp,partialPrefix,inlineType,source)::dae,func,extraArg)
    equation
      (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.FUNCTION(path,DAE.FUNCTION_DEF(elist2)::derFuncs,ftp,partialPrefix,inlineType,source)::dae2,extraArg);

  case(DAE.FUNCTION(path,(DAE.FUNCTION_EXT(body = elist,externalDecl=extDecl)::derFuncs),ftp,partialPrefix,inlineType,source)::dae,func,extraArg)
    equation
      (elist2,extraArg) = traverseDAE2(elist,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
     then (DAE.FUNCTION(path,DAE.FUNCTION_EXT(elist2,extDecl)::derFuncs,ftp,partialPrefix,DAE.NO_INLINE,source)::dae2,extraArg);

  case(DAE.RECORD_CONSTRUCTOR(path,tp,source)::dae,func,extraArg)
    equation
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.RECORD_CONSTRUCTOR(path,tp,source)::dae2,extraArg);

  case(DAE.EXTOBJECTCLASS(path,elt1,elt2,source)::dae,func,extraArg)
    equation
      ({elt11,elt22},extraArg) =  traverseDAE2({elt1,elt2},func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.EXTOBJECTCLASS(path,elt11,elt22,source)::dae2,extraArg);

  case(DAE.ASSERT(e1,e2,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1,extraArg);
      (e22,extraArg) = func(e2,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.ASSERT(e11,e22,source)::dae2,extraArg);

  case(DAE.TERMINATE(e1,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.TERMINATE(e11,source)::dae2,extraArg);

  case(DAE.NORETCALL(path,expl,source)::dae,func,extraArg)
    equation
      (expl,extraArg) = traverseDAEExpList(expl,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.NORETCALL(path,expl,source)::dae2,extraArg);

  case(DAE.REINIT(cr,e1,source)::dae,func,extraArg)
    equation
      (e11,extraArg) = func(e1,extraArg);
      (DAE.CREF(cr2,_),extraArg) = func(DAE.CREF(cr,DAE.ET_REAL()),extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.REINIT(cr2,e11,source)::dae2,extraArg);

  case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::dae,func,extraArg)
    equation
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source)::dae2,extraArg);

  case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)::dae,func,extraArg)
    equation
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(stmts2),source)::dae2,extraArg);

  case(DAE.IF_EQUATION(conds,tbs,elist2,source)::dae,func,extraArg)
    equation
      (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
      (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
      (elist22,extraArg) = traverseDAE2(elist2,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.IF_EQUATION(conds_1,tbs_1,elist22,source)::dae2,extraArg);

  case(DAE.INITIAL_IF_EQUATION(conds,tbs,elist2,source)::dae,func,extraArg)
    equation
      (conds_1,extraArg) = traverseDAEExpList(conds, func, extraArg);
      (tbs_1,extraArg) = traverseDAEList(tbs,func,extraArg);
      (elist22,extraArg) = traverseDAE2(elist2,func,extraArg);
      (dae2,extraArg) = traverseDAE2(dae,func,extraArg);
    then (DAE.INITIAL_IF_EQUATION(conds_1,tbs_1,elist22,source)::dae2,extraArg);
  // Empty function call - stefan
  case(DAE.NORETCALL(_, _, _)::dae,func,extraArg)
    equation
      Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"Empty function call in equations", "Move the function calls to appropriate algorithm section"});
    then fail();

  case(elt::_,_,_)
    equation
      print(" failure in DAE.traverseDAE\n");
      str = DAEDump.dumpElementsStr({elt});
      print(str);
    then fail();
end matchcontinue;
end traverseDAE2;

public function traverseDAEEquationsStmts "function: traverseDAEEquationsStmts
  Author: BZ, 2008-12
  Helper function to traverseDAE,
  Handles the traversing of DAE.Statement.
"
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input Type_a extraArg;
  output list<DAE.Statement> outStmts;
  output Type_a oextraArg;
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outStmts,oextraArg) := matchcontinue(inStmts,func,extraArg)
    local
      DAE.Exp e_1,e_2,e,e2;
      list<DAE.Exp> expl1,expl2;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts2;
      DAE.ExpType tp,tt;
      DAE.Statement x,ew,ew_1;
      Boolean b1;
      String id1;
      list<Integer> li;
      DAE.ElementSource source;
  case ({},_,extraArg) then ({},extraArg);

  case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e, source = source) :: xs),func,extraArg)
    equation
      (e_1,extraArg) = func(e, extraArg);
      (e_2,extraArg) = func(e2, extraArg);
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_ASSIGN(tp,e_2,e_1,source) :: xs_1,extraArg);

  case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source) :: xs),func,extraArg)
    equation
      (e_1, extraArg) = func(e, extraArg);
      (expl2, extraArg) = traverseDAEExpList(expl1,func,extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then ((DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source) :: xs_1),extraArg);

  case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source) :: xs),func,extraArg)
    equation
      (e_1, extraArg) = func(e, extraArg);
      (e_2 as DAE.CREF(cr_1,_), extraArg) = func(DAE.CREF(cr,DAE.ET_OTHER()), extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_FOR(type_=tp,iterIsArray=b1,ident=id1,exp=e,statementLst=stmts, source = source)) :: xs),func,extraArg)
    equation
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_FOR(tp,b1,id1,e_1,stmts2,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source)) :: xs),func,extraArg)
    equation
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_WHILE(e_1,stmts2,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=NONE,helpVarIndices=li, source = source)) :: xs),func,extraArg)
    equation
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_WHEN(e_1,stmts2,NONE,li,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=SOME(ew),helpVarIndices=li, source = source)) :: xs),func,extraArg)
    equation
      ({ew_1}, extraArg) = traverseDAEEquationsStmts({ew},func,extraArg);
      (stmts2, extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_WHEN(e_1,stmts2,SOME(ew),li,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_ASSERT(cond = e, msg=e2, source = source)) :: xs),func,extraArg)
    equation
      (e_1, extraArg) = func(e, extraArg);
      (e_2, extraArg) = func(e2, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_ASSERT(e_1,e_2,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_TERMINATE(msg = e, source = source)) :: xs),func,extraArg)
    equation
      (e_1, extraArg) = func(e, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_TERMINATE(e_1,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_REINIT(var = e,value=e2, source = source)) :: xs),func,extraArg)
    equation
      (e_1, extraArg) = func(e, extraArg);
      (e_2, extraArg) = func(e2, extraArg);
      (xs_1, extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_REINIT(e_1,e_2,source) :: xs_1,extraArg);

  case (((x as DAE.STMT_NORETCALL(exp = e, source = source)) :: xs),func,extraArg)
    local Absyn.Path fnName;
    equation
      (e_1, extraArg) = func(e, extraArg);
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

  case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = el, source = source)) :: xs),func,extraArg)
    local Algorithm.Else el,el_1;
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (stmts2,extraArg) = traverseDAEEquationsStmts(stmts,func,extraArg);
      (e_1,extraArg) = func(e, extraArg);
      (xs_1,extraArg) = traverseDAEEquationsStmts(xs, func, extraArg);
    then (DAE.STMT_IF(e_1,stmts2,el_1,source) :: xs_1,extraArg);

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
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm (outElse,extraArg) := matchcontinue(inElse,func,extraArg)
  local
    DAE.Exp e,e_1;
    list<DAE.Statement> st,st_1;
    Algorithm.Else el,el_1;
  case(DAE.NOELSE(),_,extraArg) then (DAE.NOELSE,extraArg);
  case(DAE.ELSEIF(e,st,el),func,extraArg)
    equation
      (el_1,extraArg) = traverseDAEEquationsStmtsElse(el,func,extraArg);
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
      (e_1,extraArg) = func(e, extraArg);
    then (DAE.ELSEIF(e_1,st_1,el_1),extraArg);
  case(DAE.ELSE(st),func,extraArg)
    equation
      (st_1,extraArg) = traverseDAEEquationsStmts(st,func,extraArg);
    then (DAE.ELSE(st_1),extraArg);
end matchcontinue;
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
  partial function FuncExpType input DAE.Exp exp; input Type_a arg; output DAE.Exp oexp; output Type_a oarg; end FuncExpType;
  replaceable type Type_a subtypeof Any;
algorithm
  (outAttr,extraArg) := matchcontinue(attr,func,extraArg)
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
  end matchcontinue;
end traverseDAEVarAttr;

public function getElementSourceFileInfo
"Gets the file information associated with an element.
If there are several candidates, select the first one."
  input DAE.ElementSource source;
  output Absyn.Info info;
algorithm
  info := matchcontinue source
    case DAE.SOURCE(info = info) then info;
  end matchcontinue;
end getElementSourceFileInfo;

public function getElementSourceTypes
"@author: adrpo
 retrieves the paths from the DAE.ElementSource.SOURCE.typeLst"
 input DAE.ElementSource source "the source of the element";
 output list<Absyn.Path> pathLst;
algorithm
  pathLst := matchcontinue(source)
    local list<Absyn.Path> pLst;
    case DAE.SOURCE(typeLst = pLst) then pLst;
  end matchcontinue;
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
  outDae := matchcontinue (inDae,inPath)
      local Absyn.Path p; DAE.DAElist dae;
    case (dae,SOME(p)) equation
      dae = addComponentType(dae,p);
    then dae;
    case(dae,NONE) then dae;
  end matchcontinue;
end addComponentTypeOpt;

public function addComponentType "
  This function takes a dae element list and a type name and
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable."
  input DAE.DAElist inDae;
  input Absyn.Path inPath;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inDae,inPath)
    local
      list<DAE.Element> xs_1,xs;
      DAE.ComponentRef cr;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.InstDims dim;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.Element x;
			DAE.VarProtection prot;
			Option<DAE.Exp> bind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Absyn.Path newtype;
      Absyn.InnerOuter io;
      DAE.ElementSource source "the element origin";
      DAE.FunctionTree funcs;

    case (DAE.DAE({},funcs),_) then DAE.DAE({},funcs);
    case (DAE.DAE(DAE.VAR(componentRef = cr,
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
               innerOuter=io) :: xs,funcs),newtype)
      equation
        DAE.DAE(xs_1,funcs) = addComponentType(DAE.DAE(xs,funcs), newtype);
        source = addElementSourceType(source, newtype);
      then
        DAE.DAE(DAE.VAR(cr,kind,dir,prot,tp,bind,dim,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: xs_1,funcs);
    // adrpo: TODO! FIXME! set also the type in the equations, not only in vars.
    case (DAE.DAE(x :: xs,funcs),newtype)
      equation
        DAE.DAE(xs_1,funcs) = addComponentType(DAE.DAE(xs,funcs), newtype);
      then
        DAE.DAE(x :: xs_1,funcs);
  end matchcontinue;
end addComponentType;

protected function addElementSourceType
  input DAE.ElementSource inSource;
  input Absyn.Path classPath;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, classPath)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;

    case (DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst), classPath)
      then DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, classPath::typeLst);
  end matchcontinue;
end addElementSourceType;

protected function addElementSourceTypeOpt
  input DAE.ElementSource inSource;
  input Option<Absyn.Path> classPathOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, classPathOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
    case (inSource, NONE()) then inSource; // no source change.
    case (inSource, SOME(classPath))
      equation
        src = addElementSourceType(inSource, classPath);
      then src;
  end matchcontinue;
end addElementSourceTypeOpt;

public function addElementSourcePartOf
  input DAE.ElementSource inSource;
  input Absyn.Within withinPath;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, withinPath)
    local
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;

    case (DAE.SOURCE(info,partOfLst, instanceOptLst, connectEquationOptLst, typeLst), withinPath)
      then DAE.SOURCE(info,withinPath::partOfLst, instanceOptLst, connectEquationOptLst, typeLst);
  end matchcontinue;
end addElementSourcePartOf;

public function addElementSourcePartOfOpt
  input DAE.ElementSource inSource;
  input Option<Absyn.Path> classPathOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, classPathOpt)
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
  end matchcontinue;
end addElementSourcePartOfOpt;

public function addElementSourceFileInfo
  input DAE.ElementSource source;
  input Absyn.Info fileInfo;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue (source,fileInfo)
    local
      list<Absyn.Path> typeLst "the absyn type of the element" ;
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      Absyn.Info info;
    case (DAE.SOURCE(_,partOfLst,instanceOptLst,connectEquationOptLst,typeLst), info)
      then DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst);
  end matchcontinue;
end addElementSourceFileInfo;

public function addElementSourceInstanceOpt
  input DAE.ElementSource inSource;
  input Option<DAE.ComponentRef> instanceOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, instanceOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
      Absyn.Info info "the line and column numbers of the equations and algorithms this element came from";
      list<Absyn.Within> partOfLst "the models this element came from" ;
      list<Option<DAE.ComponentRef>> instanceOptLst "the instance this element is part of" ;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst "this element came from this connect" ;
      list<Absyn.Path> typeLst "the classes where the type of the element is defined" ;

    // a NONE means top level (equivalent to NO_PRE, SOME(cref) means subcomponent
    case (DAE.SOURCE(info,partOfLst,instanceOptLst,connectEquationOptLst,typeLst), instanceOpt)
      then DAE.SOURCE(info,partOfLst,instanceOpt::instanceOptLst,connectEquationOptLst,typeLst);
  end matchcontinue;
end addElementSourceInstanceOpt;

public function addElementSourceConnectOpt
  input DAE.ElementSource inSource;
  input Option<tuple<DAE.ComponentRef,DAE.ComponentRef>> connectEquationOpt;
  output DAE.ElementSource outSource;
algorithm
  outSource := matchcontinue(inSource, connectEquationOpt)
    local
      Absyn.Path classPath;
      DAE.ElementSource src;
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

public function elementIsFunction "returns true if element matches any kind of function"
  input DAE.Element elt;
  output Boolean res;
algorithm
  res := matchcontinue(elt)
    case(DAE.FUNCTION(path=_)) then true;
    case(DAE.RECORD_CONSTRUCTOR(path=_)) then true;
    case(_) then false;
  end matchcontinue;
end elementIsFunction;

public function elementIsExtFunction "returns true if element matches an external function"
  input DAE.Element elt;
  output Boolean res;
algorithm
  res := matchcontinue(elt)
    case(DAE.FUNCTION(functions=DAE.FUNCTION_EXT(body=_)::_)) then true;
    case(_) then false;
  end matchcontinue;
end elementIsExtFunction;


protected function functionName "returns the name of a FUNCTION or RECORD_CONSTRUCTOR"
  input DAE.Element elt;
  output Absyn.Path name;
algorithm
  name:= matchcontinue(elt)
    case(DAE.FUNCTION(path=name)) then name;
    case(DAE.RECORD_CONSTRUCTOR(path=name)) then name;
  end matchcontinue;
end functionName;

public function getFunctionNames "returns the name of a FUNCTION or RECORD_CONSTRUCTOR"
  input list<DAE.Element> elts;
  output list<Absyn.Path> name;
algorithm
  name:= matchcontinue(elts)
    local
      list<Absyn.Path> functionPaths;
      Absyn.Path name;
      list<DAE.Element> rest;
    // empty case
    case({}) then {};
    // function
    case(DAE.FUNCTION(path=name)::rest)
      equation
        Debug.traceln("adding func " +& Absyn.pathString(name));
        functionPaths = getFunctionNames(rest); 
      then name::functionPaths;
    // record constructors
    case(DAE.RECORD_CONSTRUCTOR(path=name)::rest) 
      equation
        functionPaths = getFunctionNames(rest); 
      then name::functionPaths;
    // anything else
    case(_::rest) 
      equation
        functionPaths = getFunctionNames(rest); 
      then functionPaths;        
  end matchcontinue;
end getFunctionNames;

public function addDaeFunction "add functions present in the element list to the function tree"
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(dae)
  local DAE.FunctionTree funcs;
    list<DAE.Element> elts;
    DAE.Element elt;

    case(DAE.DAE({},funcs)) then DAE.DAE({},funcs);
      /* is function */
    case(DAE.DAE(elt::elts,funcs)) equation
        true = elementIsFunction(elt);
        funcs = avlTreeAdd(funcs,functionName(elt),elt);
        DAE.DAE(elts,funcs) = addDaeFunction(DAE.DAE(elts,funcs));
    then DAE.DAE(elts,funcs);

      /* Not function */
    case(DAE.DAE(elt::elts,funcs)) equation
        DAE.DAE(elts,funcs) = addDaeFunction(DAE.DAE(elts,funcs));
    then DAE.DAE(elt::elts,funcs);
  end matchcontinue;
end addDaeFunction;

public function addDaeExtFunction "add extermaö functions present in the element list to the function tree
Note: normal functions are skipped.
See also addDaeFunction
"
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(dae)
  local DAE.FunctionTree funcs;
    list<DAE.Element> elts;
    DAE.Element elt;

    case(DAE.DAE({},funcs)) then DAE.DAE({},funcs);

      /* is external function */
    case(DAE.DAE(elt::elts,funcs)) equation
        true = elementIsExtFunction(elt);
        //print("adding external function "+&Absyn.pathString(functionName(elt))+&"\n");
        funcs = avlTreeAdd(funcs,functionName(elt),elt);
        DAE.DAE(elts,funcs) = addDaeFunction(DAE.DAE(elts,funcs));
    then DAE.DAE(elts,funcs);
      
      /* Other functions removed*/
    case(DAE.DAE(elt::elts,funcs)) equation
      true = elementIsFunction(elt);     
      DAE.DAE(elts,funcs) = addDaeFunction(DAE.DAE(elts,funcs));
    then DAE.DAE(elts,funcs);
        
      /* Not external or normal function, keep */
    case(DAE.DAE(elt::elts,funcs)) equation
        DAE.DAE(elts,funcs) = addDaeFunction(DAE.DAE(elts,funcs));
    then DAE.DAE(elt::elts,funcs);
  end matchcontinue;
end addDaeExtFunction;

public function mergeSources
  input DAE.ElementSource src1;
  input DAE.ElementSource src2;
  output DAE.ElementSource mergedSrc;
algorithm
  mergedSrc := matchcontinue(src1,src2)
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
 end matchcontinue;
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
  case(DAE.NO_INLINE) then false;
  case(_) then true;
  end matchcontinue;
end convertInlineTypeToBool;

public function daeElements "Retrieve the elements from a DAEList"
  input DAE.DAElist dae;
  output list<DAE.Element> elts;
algorithm
  elts := matchcontinue(dae)
    case(DAE.DAE(elts,_)) then elts;
  end matchcontinue;
end daeElements;

public function daeFunctionTree "Retrieve the function tree from a DAEList"
  input DAE.DAElist dae;
  output DAE.FunctionTree funcs;
algorithm
  funcs := matchcontinue(dae)
    case(DAE.DAE(_,funcs)) then funcs;
  end matchcontinue;
end daeFunctionTree;

public function joinDaes "joins two daes by appending the element lists and joining the function trees"
  input DAE.DAElist dae1;
  input DAE.DAElist dae2;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(dae1,dae2)
    local
      list<DAE.Element> elts1,elts2,elts;
      DAE.FunctionTree funcs1,funcs2,funcs;
      Real t1, t2, ti;

    // deal with the empty case
    case(DAE.DAE({},DAE.AVLTREENODE(NONE(),0,NONE(),NONE())),
         DAE.DAE({},DAE.AVLTREENODE(NONE(),0,NONE(),NONE()))) 
      then emptyDae;

    // we have something in the first argument  
    case(dae1 as DAE.DAE(elts1,funcs1),
         dae2 as DAE.DAE({},DAE.AVLTREENODE(NONE(),0,NONE(),NONE()))) 
      then dae1;

    // we have something in the second argument
    case(dae1 as DAE.DAE({},DAE.AVLTREENODE(NONE(),0,NONE(),NONE())), 
         dae2 as DAE.DAE(elts2,funcs2)) 
      then dae2;
        
    // we have empty trees in both arguments, just append lists 
    case(DAE.DAE(elts1,DAE.AVLTREENODE(NONE(),0,NONE(),NONE())), 
         DAE.DAE(elts2,DAE.AVLTREENODE(NONE(),0,NONE(),NONE()))) 
      equation
        // t1 = clock();
        elts = Util.listAppendNoCopy(elts1,elts2);
        // t2 = clock();
        // ti = t2 -. t1;
        // Debug.fprintln("innerouter", " joinDAEs: (" +& realString(ti) +& ") -> " +& intString(listLength(elts1)) +& " + " +&  intString(listLength(elts2)));
      then DAE.DAE(elts, emptyFuncTree);
    
    // we have empty trees in first argument 
    case(DAE.DAE(elts1,DAE.AVLTREENODE(NONE(),0,NONE(),NONE())), 
         DAE.DAE(elts2,funcs2)) 
      equation
        // t1 = clock();
        elts = Util.listAppendNoCopy(elts1,elts2);
        // t2 = clock();
        // ti = t2 -. t1;
        // Debug.fprintln("innerouter", " joinDAEs: (" +& realString(ti) +& ") -> " +& intString(listLength(elts1)) +& " + " +&  intString(listLength(elts2)));
      then DAE.DAE(elts, funcs2);
    
    // we have empty trees in second argument 
    case(DAE.DAE(elts1,funcs1), 
         DAE.DAE(elts2,DAE.AVLTREENODE(NONE(),0,NONE(),NONE()))) 
      equation
        // t1 = clock();
        elts = Util.listAppendNoCopy(elts1,elts2);
        // t2 = clock();
        // ti = t2 -. t1;
        // Debug.fprintln("innerouter", " joinDAEs: (" +& realString(ti) +& ") -> " +& intString(listLength(elts1)) +& " + " +&  intString(listLength(elts2)));
      then DAE.DAE(elts, funcs1);
    
    // we have something in both arguments
    case(DAE.DAE(elts1,funcs1),
         DAE.DAE(elts2,funcs2)) 
      equation
        // t1 = clock();
        elts = Util.listAppendNoCopy(elts1,elts2);
        funcs = joinAvlTrees(funcs1,funcs2);
        // t2 = clock();
        // ti = t2 -. t1;
        // Debug.fprintln("innerouter", " joinDAEs: (" +& realString(ti) +& ") -> " +& intString(listLength(elts1)) +& " + " +&  intString(listLength(elts2)));      
    then DAE.DAE(elts,funcs);
  end matchcontinue;
end joinDaes;

public function joinDaeLst "joins a list of daes by using joinDaes"
  input list<DAE.DAElist> daeLst;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(daeLst)
  local DAE.DAElist dae,dae1,dae2;
    case({dae}) then dae;
    case(dae::daeLst) equation
      dae1 = joinDaeLst(daeLst);
      dae = joinDaes(dae,dae1);
    then dae;
  end matchcontinue;
end joinDaeLst;

public function extractFunctions "Extracts only the functions from a DAE.DAElist and returns an empty element list
Is typically used when no dae should be generated, but functions must be passed along.
"
  input DAE.DAElist dae;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(dae) 
  local DAE.FunctionTree funcs;
    case(DAE.DAE(_,funcs)) then DAE.DAE({},funcs);
  end matchcontinue; 
end extractFunctions;
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
  str := DAEDump.dumpElementsStr({v});
end valueStr;

public function avlTreeNew "Return an empty tree"
  output DAE.AvlTree tree;
algorithm
  tree := emptyFuncTree; // DAE.AVLTREENODE(NONE,0,NONE,NONE);
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
  lst := matchcontinue(tree)
  local Option<DAE.AvlTree> r,l; DAE.AvlKey k; DAE.AvlValue v;
    case NONE then {};
    case(SOME(DAE.AVLTREENODE(value = NONE,left = l,right = r) )) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then lst;
    case(SOME(DAE.AVLTREENODE(value=SOME(DAE.AVLTREEVALUE(k,v)),left = l, right = r))) equation
      lst = listAppend(avlTreeToList2(l),avlTreeToList2(r));
    then (k,v)::lst;
  end matchcontinue;
end avlTreeToList2;

public function avlTreeAddLst "Adds a list of (key,value) pairs"
  input list<tuple<DAE.AvlKey,DAE.AvlValue>> values;
  input DAE.AvlTree inTree;
  output DAE.AvlTree outTree;
algorithm
  outTree := matchcontinue(values,inTree)
  local DAE.AvlKey key;
    DAE.AvlValue val;
    DAE.AvlTree tree;
    case({},tree) then tree;
    case((key,val)::values,tree) equation
      tree = avlTreeAdd(tree,key,val);
      tree = avlTreeAddLst(values,tree);
    then tree;
  end matchcontinue;
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
      Integer rhval,h;
      DAE.AvlTree t_1,t,right_1,left_1,bt;

      /* empty tree*/
    case (DAE.AVLTREENODE(value = NONE,height=h,left = NONE,right = NONE),key,value)
    	then DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(key,value)),1,NONE,NONE);

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
        true = System.strcmp(Absyn.pathString(key),Absyn.pathString(rkey)) > 0;
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
        bt = balance(DAE.AVLTREENODE(SOME(DAE.AVLTREEVALUE(rkey,rval)),h,left,SOME(t_1)));
      then
        bt;

        /* Insert to left subtree */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),height=h,left = left ,right = right),key,value)
      equation
        /*true = System.strcmp(key,rkey) < 0;*/
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
  outT := matchcontinue(t)
    case(NONE) then DAE.AVLTREENODE(NONE,0,NONE,NONE);
    case(SOME(outT)) then outT;
  end matchcontinue;
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
  outBt := matchcontinue(bt)
  local DAE.AvlTree rl;
 case(bt) equation
      true = differenceInHeight(getOption(leftNode(bt))) < 0;
      rl = rotateLeft(getOption(leftNode(bt)));
      bt = setLeft(bt,SOME(rl));
    then bt;
  end matchcontinue;
end doBalance4;

protected function setRight "set right treenode"
  input DAE.AvlTree node;
  input Option<DAE.AvlTree> right;
  output DAE.AvlTree outNode;
algorithm
  outNode := matchcontinue(node,right)
   local Option<DAE.AvlTreeValue> value;
    Option<DAE.AvlTree> l,r;
    Integer height;
    case(DAE.AVLTREENODE(value,height,l,r),right) then DAE.AVLTREENODE(value,height,l,right);
  end matchcontinue;
end setRight;

protected function setLeft "set left treenode"
  input DAE.AvlTree node;
  input Option<DAE.AvlTree> left;
  output DAE.AvlTree outNode;
algorithm
  outNode := matchcontinue(node,left)
  local Option<DAE.AvlTreeValue> value;
    Option<DAE.AvlTree> l,r;
    Integer height;
    case(DAE.AVLTREENODE(value,height,l,r),left) then DAE.AVLTREENODE(value,height,left,r);
  end matchcontinue;
end setLeft;


protected function leftNode "Retrieve the left subnode"
  input DAE.AvlTree node;
  output Option<DAE.AvlTree> subNode;
algorithm
  subNode := matchcontinue(node)
    case(DAE.AVLTREENODE(left = subNode)) then subNode;
  end matchcontinue;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input DAE.AvlTree node;
  output Option<DAE.AvlTree> subNode;
algorithm
  subNode := matchcontinue(node)
    case(DAE.AVLTREENODE(right = subNode)) then subNode;
  end matchcontinue;
end rightNode;

protected function exchangeLeft "help function to balance"
input DAE.AvlTree node;
input DAE.AvlTree parent;
output DAE.AvlTree outParent "updated parent";
algorithm
  outParent := matchcontinue(node,parent)
    local Option<DAE.AvlTreeValue> value;
      Integer height ;
      DAE.AvlTree left,right,bt,leftNode,rightNode;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end matchcontinue;
end exchangeLeft;

protected function exchangeRight "help function to balance"
input DAE.AvlTree node;
input DAE.AvlTree parent;
output DAE.AvlTree outParent "updated parent";
algorithm
  outParent := matchcontinue(node,parent)
  local DAE.AvlTree bt;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end matchcontinue;
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
  val := matchcontinue(opt)
    case(SOME(val)) then val;
  end matchcontinue;
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
  diff := matchcontinue(node)
  local Integer lh,rh;
    Option<DAE.AvlTree> l,r;
    case(DAE.AVLTREENODE(left=l,right=r)) equation
      lh = getHeight(l);
      rh = getHeight(r);
    then lh - rh;
  end matchcontinue;
end differenceInHeight;

public function avlTreeGet "  Get a value from the binary tree given a key.
"
  input DAE.AvlTree inAvlTree;
  input DAE.AvlKey inKey;
  output DAE.AvlValue outValue;
algorithm
  outValue:=
  matchcontinue (inAvlTree,inKey)
    local
      DAE.AvlKey rkey,key;
      DAE.AvlValue rval,res;
      Option<DAE.AvlTree> left,right;
      Integer rhval;
      /* hash func Search to the right */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),left = left,right = right),key)
      equation
        true = ModUtil.pathEqual(rkey,key);
      then
        rval;

        /* Search to the right */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),left = left,right = SOME(right)),key)
      local DAE.AvlTree right;
      equation
        true = System.strcmp(Absyn.pathString(key),Absyn.pathString(rkey)) > 0;
        res = avlTreeGet(right, key);
      then
        res;

        /* Search to the left */
    case (DAE.AVLTREENODE(value = SOME(DAE.AVLTREEVALUE(rkey,rval)),left = SOME(left),right = right),key)
      local DAE.AvlTree left;
      equation
        /*true = System.strcmp(key,rkey) < 0;*/
        res = avlTreeGet(left, key);
      then
        res;
  end matchcontinue;
end avlTreeGet;

protected function getOptionStr "function getOptionStr

  Retrieve the string from a string option.
  If NONE return empty string.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  matchcontinue (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE,_) then "";
  end matchcontinue;
end getOptionStr;

protected function printAvlTreeStr "
  Prints the avl tree to a string
"
  input DAE.AvlTree inAvlTree;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAvlTree)
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
    case (DAE.AVLTREENODE(value = NONE,left = l,right = r))
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
 outBt := matchcontinue(bt)
 local Option<DAE.AvlTree> l,r;
   Option<DAE.AvlTreeValue> v;
   DAE.AvlValue val;
   Integer hl,hr,height;
 case(DAE.AVLTREENODE(value=v as SOME(DAE.AVLTREEVALUE(_,val)),left=l,right=r)) equation
    hl = getHeight(l);
    hr = getHeight(r);
    height = intMax(hl,hr) + 1;
 then DAE.AVLTREENODE(v,height,l,r);
 end matchcontinue;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<DAE.AvlTree> bt;
  output Integer height;
algorithm
  height := matchcontinue(bt)
    case(NONE) then 0;
    case(SOME(DAE.AVLTREENODE(height = height))) then height;
  end matchcontinue;
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
  matchcontinue (inElement)
    case DAE.IF_EQUATION(condition1 = _) then ();
    case DAE.INITIAL_IF_EQUATION(condition1 = _) then ();
  end matchcontinue;
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
  output list<DAE.Element> v_acc;
  output list<DAE.Element> ie;
  output list<DAE.Element> ia;
  output list<DAE.Element> e;
  output list<DAE.Element> a;
  output list<DAE.Element> o;
algorithm
  (v,ie,ia,e,a,o) := matchcontinue(inElements,v_acc,ie_acc,ia_acc,e_acc,a_acc,o_acc)
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
  end matchcontinue;
end splitElements_dispatch;

public function matchValueblock
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local
      list<DAE.Exp> res, exps, exps2;
      DAE.Exp e,resE;
      list<DAE.Element> ld;
      list<DAE.Statement> body;
    case e as DAE.VALUEBLOCK(localDecls = ld,body = body,result = resE)
      equation
        exps = getAllExps(ld);
        exps2 = Algorithm.getAllExpsStmts(body);
        exps = listAppend(exps,exps2);
        res = Exp.getMatchingExpsList(resE::exps,matchValueblock);
      then e::res;
  end matchcontinue;
end matchValueblock;

public function getUniontypePaths
"Traverses DAE elements to find all Uniontypes, and return the paths
of all of their records"
  input list<DAE.Element> elements;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue elements
    local
      list<Absyn.Path> paths1;
      list<Absyn.Path> paths2;
      list<DAE.Exp> exps;
      list<DAE.Element> els;
    case elements
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        paths1 = getUniontypePaths2(elements);
        exps = getAllExps(elements);
        exps = Exp.getMatchingExpsList(exps, matchValueblock);
        els = getDAEDeclsFromValueblocks(exps);
        paths2 = getUniontypePaths2(els);
        outPaths = listAppend(paths1, paths2);
        outPaths = Util.listUnion(outPaths, outPaths); // Remove duplicates
      then outPaths;
    case _
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then {};
    case _
      equation
        Debug.fprintln("failtrace", "- DAEUtil.getUniontypePaths failed");
      then fail();
  end matchcontinue;
end getUniontypePaths;

protected function getUniontypePaths2
  input list<DAE.Element> elements;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue elements
    local
      list<Absyn.Path> paths,paths1,paths2;
      list<list<Absyn.Path>> listPaths;
      list<DAE.Element> els,rest;
      list<DAE.Type> tys;
      DAE.Type ft;
    case {} then {};
    case DAE.FUNCTION(functions = {DAE.FUNCTION_DEF(body = els)})::rest
      equation
        paths1 = getUniontypePaths2(els);
        paths2 = getUniontypePaths2(rest);
        paths = listAppend(paths1,paths2);
      then paths;
    case DAE.VAR(ty = ft)::rest
      equation
        tys = Types.getAllInnerTypesOfType(ft, Types.uniontypeFilter);
        listPaths = Util.listMap(tys, Types.getUniontypePaths);
        paths1 = getUniontypePaths2(rest);
        listPaths = paths1::listPaths;
        paths = Util.listFlatten(listPaths);
      then paths;
    case _::rest then getUniontypePaths2(rest);
  end matchcontinue;
end getUniontypePaths2;

protected function getDAEDeclsFromValueblocks
  input list<DAE.Exp> exps;
  output list<DAE.Element> outEls;
algorithm
  outEls := matchcontinue (exps)
    local
      list<DAE.Exp> rest;
      list<DAE.Element> els1,els2;
    case {} then {};
    case DAE.VALUEBLOCK(localDecls = els1)::rest
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
  d := matchcontinue dae
    local
      HashTable.HashTable ht;
    case dae
      equation
        false = RTOpts.debugFlag("frontend-inline-euler");
      then dae;
    case dae
      equation
        ht = HashTable.emptyHashTable();
        (d,ht) = traverseDAE(dae,simpleInlineDerEuler,ht);
      then d;
  end matchcontinue;
end transformDerInline;

public function simpleInlineDerEuler
"Simple euler inline of the equation system; only does explicit euler, and only der(cref)"
  input DAE.Exp exp;
  input HashTable.HashTable crs0;
  output DAE.Exp exp1;
  output HashTable.HashTable crs1;
algorithm
  (exp1,crs1) := matchcontinue (exp,crs0)
    local
      DAE.ComponentRef cr;
    case (DAE.CALL(path=Absyn.IDENT("der"),expLst={exp as DAE.CREF(componentRef = cr, ty = DAE.ET_REAL())}),crs0)
      equation
        exp = DAE.BINARY(
          DAE.BINARY(exp,DAE.SUB(DAE.ET_REAL()),DAE.CREF(DAE.CREF_QUAL("$old",DAE.ET_REAL(),{},cr),DAE.ET_REAL())),
          DAE.DIV(DAE.ET_REAL()),
          DAE.CREF(DAE.CREF_IDENT("$current_step_size",DAE.ET_REAL(),{}),DAE.ET_REAL()));
        crs1 = HashTable.add((cr,0),crs0);
      then (exp,crs1);
    case (exp,crs0) then (exp,crs0);
  end matchcontinue;
end simpleInlineDerEuler;

public function transformationsBeforeBackend
  input DAE.DAElist dae;
  output DAE.DAElist d;
algorithm
  d := dae;
  // Transform if equations to if expression before going into code generation.
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
  outBinding := matchcontinue(inBinding, bindingSource)
    local
      DAE.Exp exp "exp";
      Option<Values.Value> evaluatedExp "evaluatedExp; evaluated exp";
      DAE.Const cnst "constant";
      Values.Value valBound;
        
    case (inBinding as DAE.UNBOUND(), _) then inBinding;
    case (DAE.EQBOUND(exp, evaluatedExp, cnst, _), bindingSource) then DAE.EQBOUND(exp, evaluatedExp, cnst, bindingSource);
    case (DAE.VALBOUND(valBound, _), bindingSource) then DAE.VALBOUND(valBound, bindingSource);
 end matchcontinue;
end setBindingSource;

public function printBindingExpStr "prints a binding"
  input DAE.Binding binding;
  output String str;
algorithm
  str := matchcontinue(binding)
    local 
      DAE.Exp e; Values.Value v;
    case(DAE.UNBOUND()) then "";
    case(DAE.EQBOUND(exp=e)) 
      equation
        str = Exp.printExpStr(e);
      then 
        str;
    case(DAE.VALBOUND(valBound=v)) 
      equation
        str = " = " +& ValuesUtil.valString(v);
      then 
        str;
  end matchcontinue;
end printBindingExpStr;

public function printBindingSourceStr "prints a binding source as a string"
  input DAE.BindingSource bindingSource;
  output String str;
algorithm
  str := matchcontinue(bindingSource)
    local 
    case(DAE.BINDING_FROM_DEFAULT_VALUE()) then "[DEFAULT VALUE]";
    case(DAE.BINDING_FROM_START_VALUE()) then  "[START VALUE]";
  end matchcontinue;
end printBindingSourceStr;

end DAEUtil;
