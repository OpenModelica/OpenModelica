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

package PartFn
" file:	       PartFn.mo
  package:     PartFn
  description: partially evaluated functions
  
  RCS: $Id: PartFn.mo 4306 2009-10-06 06:32:29Z sjoelund.se $
  
  This module contains data structures and functions for partially evaulated functions.
  entry point: createPartEvalFunctions, partEvalDAELow, partEvalDAE
  "

public import DAE;
public import DAEUtil;
public import Debug;
public import Util;
public import Exp;
public import Absyn;
public import Types;
public import SCode;
public import DAELow;
public import RTOpts;

type Ident = String;

public function partEvalDAELow
"function: partEvalDAELow
	handles partially evaluated function in DAELow format"
  input list<DAE.Element> inFunctions;
  input DAELow.DAELow inDAELow;
  output list<DAE.Element> outFunctions;
  output DAELow.DAELow outDAELow;
algorithm
  (outFunctions,outDAELow) := matchcontinue(inFunctions,inDAELow)
    local
      list<DAE.Element> dae;
      DAELow.DAELow dlow;
      DAELow.Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
      DAELow.Variables knownVars "knownVars ; Known variables, i.e. constants and parameters" ;
      DAELow.Variables externalObjects "External object variables";
      DAELow.EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
      DAELow.EquationArray removedEqs "removedEqs ; Removed equations a=b" ;
      DAELow.EquationArray initialEqs "initialEqs ; Initial equations" ;
      DAELow.MultiDimEquation[:] arrayEqs "arrayEqs ; Array equations" ;
      DAE.Algorithm[:] algorithms "algorithms ; Algorithms" ;
      DAELow.EventInfo eventInfo "eventInfo" ;
      DAELow.ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    case(dae,dlow)
      equation
        false = RTOpts.debugFlag("fnptr") or RTOpts.acceptMetaModelicaGrammar();
      then
        (dae,dlow);
    case(dae,DAELow.DAELOW(orderedVars,knownVars,externalObjects,orderedEqs,removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses))
      equation
        (orderedEqs,dae) = partEvalEqArr(orderedEqs,dae);
      then
        (dae,DAELow.DAELOW(orderedVars,knownVars,externalObjects,orderedEqs,removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses));
    case(_,_)
      equation
        Debug.fprintln("failtrace","- PartFn.partEvalDAELow failed");
      then
        fail();
  end matchcontinue;
end partEvalDAELow;

protected function partEvalEqArr
"function: partEvalEqArr
	elabs calls in equations"
	input DAELow.EquationArray inEquationArray;
	input list<DAE.Element> inFunctions;
	output DAELow.EquationArray outEquationArray;
	output list<DAE.Element> outFunctions;
algorithm
  (outEquationArray,outFunctions) := matchcontinue(inEquationArray,inFunctions)
    local
      list<DAE.Element> dae;
      list<Option<DAELow.Equation>> eqlst;
      Option<DAELow.Equation>[:] eqarr;
      Integer num,size;
    case(DAELow.EQUATION_ARRAY(num,size,eqarr),dae)
      equation
        eqlst = arrayList(eqarr);
        (eqlst,dae) = partEvalEqs(eqlst,dae);
        eqarr = listArray(eqlst);
      then
        (DAELow.EQUATION_ARRAY(num,size,eqarr),dae);
    case(_,_)
      equation
        Debug.fprintln("failtrace","- PartFn.partEvalEqArr failed");
      then
        fail();
  end matchcontinue;
end partEvalEqArr;

protected function partEvalEqs
"function: partEvalEqs
	elabs calls in equations"
	input list<Option<DAELow.Equation>> inEquationList;
	input list<DAE.Element> inFunctions;
	output list<Option<DAELow.Equation>> outEquationList;
	output list<DAE.Element> outFunctions;
algorithm
  (outEquationList,outFunctions) := matchcontinue(inEquationList,inFunctions)
    local
      list<Option<DAELow.Equation>> cdr,cdr_1;
      list<DAE.Element> dae;
      Exp.Exp e,e_1,e1,e1_1,e2,e2_1;
      DAELow.Equation deleteme;
    case({},dae) then ({},dae);
    case(NONE :: cdr,dae)
      equation
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (NONE :: cdr_1,dae);
    case(SOME(DAELow.EQUATION(e1,e2)) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(DAELow.EQUATION(e1_1,e2_1)) :: cdr_1,dae);
    case(SOME(deleteme) :: cdr,dae)
      equation
        (cdr_1,dae) = partEvalEqs(cdr,dae);
      then
        (SOME(deleteme) :: cdr_1,dae);
    case(_,_)
      equation
        Debug.fprintln("failtrace","- PartFn.partEvalEqs failed");
      then
        fail();
  end matchcontinue;
end partEvalEqs;

public function partEvalDAE
"function: partEvalDAE
	goes through the DAE for Exp.PARTEVALFUNCTION, creates new classes and changes the function calls"
	input DAE.DAElist inDAE;
	input list<DAE.Element> infuncs;
	output DAE.DAElist outDAE;
	output list<DAE.Element> outfuncs;
algorithm
  (outDAE,outfuncs) := matchcontinue(inDAE,infuncs)
    local
      list<DAE.Element> elts,elts_1,dae;
      DAE.DAElist dlst;
    case(dlst,dae)
      equation
        false = RTOpts.debugFlag("fnptr") or RTOpts.acceptMetaModelicaGrammar();
      then
        (dlst,dae);
    case(DAE.DAE(elts),dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
      then
        (DAE.DAE(elts_1),dae);
    case(_,_)
      equation
        Debug.fprintln("failtrace","- PartFn.partEvalDAE failed");
      then
        fail();
  end matchcontinue;
end partEvalDAE;

public function createPartEvalFunctions
"function: createPartEvalFunctions
	goes through the DAE for Exp.PARTEVALFUNCTION, creates new classes and changes the function calls"
	input list<DAE.Element> inDAElist;
	output list<DAE.Element> outDAElist;
algorithm
  outDAElist := matchcontinue(inDAElist)
    local
      list<DAE.Element> elts,elts_1,elts_2;
    case(elts)
      equation
        false = RTOpts.debugFlag("fnptr") or RTOpts.acceptMetaModelicaGrammar();
      then
        elts;
    case(elts)
      equation
        (_,elts_1) = elabElements(elts,elts);
        elts_2 = Util.listSelect(elts_1,isFunctionElement);
      then
        elts_2;
    case(_)
      equation
        Debug.fprintln("failtrace","PartFn.createPartEvalFunctions failed");
      then
        fail();
  end matchcontinue;
end createPartEvalFunctions;

protected function isFunctionElement
"function: isFunctionElement
	checks if a DAE.Element is a function"
	input DAE.Element inElement;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inElement)
    case(DAE.FUNCTION(path = _)) then true;
    case(DAE.EXTFUNCTION(path = _)) then true;
    case(DAE.RECORD_CONSTRUCTOR(path = _)) then true;
    case(_) then false;
  end matchcontinue;
end isFunctionElement;

protected function elabElements
"function: elabElements
	goes through a list of DAE.Element for partevalfunction"
	input list<DAE.Element> inElementList;
	input list<DAE.Element> inDAE;
	output list<DAE.Element> outElementList;
	output list<DAE.Element> outDAE;
algorithm
  (outElementList,outDAE) := matchcontinue(inElementList,inDAE)
    local
      DAE.Element el,el_1,el1,el1_1,el2,el2_1;
      list<DAE.Element> cdr,cdr_1,elts,elts_1,dae;
      list<list<DAE.Element>> elm,elm_1;
      Exp.ComponentRef cref;
      DAE.VarKind kind;
      DAE.VarDirection direction;
      DAE.VarProtection protection;
      DAE.Type ty;
      Option<Exp.Exp> binding; 
      DAE.InstDims dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> pathLst;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      DAE.Type fullType;
      list<Integer> ilst;
      Ident i;
      Absyn.Path p;
      Boolean pp;
      DAE.ExternalDecl ed;
      list<Exp.Exp> elst,elst_1;
      Exp.Exp e,e_1,e1,e1_1,e2,e2_1;
    case({},dae) then ({},dae);
    case(DAE.VAR(cref,kind,direction,protection,ty,binding,dims,flowPrefix,streamPrefix,pathLst,variableAttributesOption,absynCommentOption,innerOuter) :: cdr,dae)
      equation
        (binding,dae) = elabExpOption(binding,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.VAR(cref,kind,direction,protection,ty,binding,dims,flowPrefix,streamPrefix,pathLst,variableAttributesOption,absynCommentOption,innerOuter) :: cdr_1,dae);
    case(DAE.DEFINE(cref,e) :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.DEFINE(cref,e_1) :: cdr_1,dae);
    case(DAE.INITIALDEFINE(cref,e) :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.INITIALDEFINE(cref,e_1) :: cdr_1,dae);
    case(DAE.EQUATION(e1,e2) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.EQUATION(e1_1,e2_1) :: cdr_1,dae);
    case(DAE.ARRAY_EQUATION(ilst,e1,e2) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.ARRAY_EQUATION(ilst,e1_1,e2_1) :: cdr_1,dae);
    case(DAE.COMPLEX_EQUATION(e1,e2) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.COMPLEX_EQUATION(e1_1,e2_1) :: cdr_1,dae);
    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.INITIAL_COMPLEX_EQUATION(e1_1,e2_1) :: cdr_1,dae);
    case(DAE.WHEN_EQUATION(e,elts,NONE) :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.WHEN_EQUATION(e_1,elts_1,NONE) :: cdr_1,dae);
    case(DAE.WHEN_EQUATION(e,elts,SOME(el)) :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (elts_1,dae) = elabElements(elts,dae);
        ({el_1},dae) = elabElements({el},dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.WHEN_EQUATION(e_1,elts_1,SOME(el_1)) :: cdr_1,dae);
    /*case(DAE.IF_EQUATION(elst,elm,elts) :: cdr,dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        elm_1 = Util.listMap1(elm,elabElements,dae);
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.IF_EQUATION(elst_1,elm_1,elts_1) :: cdr_1,dae);
    case(DAE.INITIAL_IF_EQUATION(elst,elm,elts) :: cdr,dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        elm_1 = Util.listMap1(elm,elabElements,dae);
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.INITIAL_IF_EQUATION(elst_1,elm_1,elts_1) :: cdr_1,dae);*/
    case(DAE.INITIALEQUATION(e1,e2) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.INITIALEQUATION(e1_1,e2_1) :: cdr_1,dae);
    // TODO: ALGORITHMS
    case(DAE.COMP(i,DAE.DAE(elts)) :: cdr,dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.COMP(i,DAE.DAE(elts_1)) :: cdr_1,dae);
    case(DAE.FUNCTION(p,DAE.DAE(elts),fullType,pp) :: cdr,dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.FUNCTION(p,DAE.DAE(elts_1),fullType,pp) :: cdr_1,dae);
    case(DAE.EXTFUNCTION(p,DAE.DAE(elts),fullType,ed) :: cdr,dae)
      equation
        (elts_1,dae) = elabElements(elts,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.EXTFUNCTION(p,DAE.DAE(elts),fullType,ed) :: cdr_1,dae);
    case(DAE.EXTOBJECTCLASS(p,el1,el2) :: cdr,dae)
      equation
        ({el1_1},dae) = elabElements({el1},dae);
        ({el2_1},dae) = elabElements({el2},dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.EXTOBJECTCLASS(p,el1_1,el2_1) :: cdr_1,dae);
    case(DAE.ASSERT(e1,e2) :: cdr,dae)
      equation
        ((e1_1,dae)) = Exp.traverseExp(e1,elabExp,dae);
        ((e2_1,dae)) = Exp.traverseExp(e2,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.ASSERT(e1_1,e2_1) :: cdr_1,dae);
    case(DAE.TERMINATE(e) :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.TERMINATE(e_1) :: cdr_1,dae);
    case(DAE.REINIT(cref,e) :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.REINIT(cref,e_1) :: cdr_1,dae);
    case(DAE.NORETCALL(p,elst) :: cdr,dae)
      equation
        (elst_1,dae) = elabExpList(elst,dae);
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (DAE.NORETCALL(p,elst_1) :: cdr_1,dae);
    case(el :: cdr,dae)
      equation
        (cdr_1,dae) = elabElements(cdr,dae);
      then
        (el :: cdr_1,dae);
    case(_,_)
      equation
        Debug.fprintln("failtrace","PartFn.elabElements failed");
      then
        fail();
  end matchcontinue;
end elabElements;

protected function elabExpList
"function: elabExpList
	elabs an exp list"
	input list<Exp.Exp> inExpList;
	input list<DAE.Element> inElementList;
	output list<Exp.Exp> outExpList;
	output list<DAE.Element> outElementList;
algorithm
  (outExpList,outElementList) := matchcontinue(inExpList,inElementList)
    local
      list<DAE.Element> dae;
      list<Exp.Exp> cdr,cdr_1;
      Exp.Exp e,e_1;
    case({},dae) then ({},dae);
    case(e :: cdr,dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
        (cdr_1,dae) = elabExpList(cdr,dae);
      then
        (e_1 :: cdr_1,dae);
  end matchcontinue;
end elabExpList;

protected function elabExpOption
"function: elabExpOption
	elabs an exp option if it is SOME, returns NONE otherwise"
	input Option<Exp.Exp> inExp;
	input list<DAE.Element> inElementList;
	output Option<Exp.Exp> outExp;
	output list<DAE.Element> outElementList;
algorithm
  (outExp,outElementList) := matchcontinue(inExp,inElementList)
    local
      Exp.Exp e,e_1;
      list<DAE.Element> dae;
    case(NONE,dae) then (NONE,dae);
    case(SOME(e),dae)
      equation
        ((e_1,dae)) = Exp.traverseExp(e,elabExp,dae);
      then
        (SOME(e_1),dae);
  end matchcontinue;
end elabExpOption;

protected function elabExp
"function: elabExp
	looks for a function call, checks the arguments for Exp.PARTEVALFUNCTION
	creates new functions and replaces the call as necessary"
	input tuple<Exp.Exp, list<DAE.Element>> inTuple;
	output tuple<Exp.Exp, list<DAE.Element>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Exp.Exp e;
      list<DAE.Element> dae;
      Absyn.Path p,p1,p_1;
      list<Exp.Exp> args,args1,args_1;
      Exp.Type ty;
      Boolean tu,bi,inl;
      Integer i,numArgs;
    case((DAE.CALL(p,args,tu,bi,ty,inl),dae))
      equation
        (DAE.PARTEVALFUNCTION(p1,args1,_),i) = getPartEvalFunction(args,0);
        numArgs = listLength(args1);
        args_1 = Util.listReplaceAtWithList(args1,i,args);
        p_1 = makeNewFnPath(p,p1);
        dae = buildNewFunction(dae,p,p1,numArgs);
      then
        ((DAE.CALL(p_1,args_1,tu,bi,ty,inl),dae));
    case((e,dae)) then ((e,dae));
  end matchcontinue;
end elabExp;

protected function makeNewFnPath
"function: makeNewFnPath
	creates a path for the new function using the path for the caller and the callee"
	input Absyn.Path inCaller;
	input Absyn.Path inCallee;
	output Absyn.Path newPath;
	String s1,s2,s;
algorithm
  s1 := Absyn.pathString(inCaller);
  s2 := Absyn.pathString(inCallee);
  s := s1 +& "_" +& s2;
  newPath := Absyn.makeIdentPathFromString(s);
end makeNewFnPath;

protected function buildNewFunction
"function: buildNewFunction
	creates a new function from the old one, given the old and new paths"
	input list<DAE.Element> inElementList;
	input Absyn.Path inPath1;
	input Absyn.Path inPath2;
	input Integer inInteger;
	output list<DAE.Element> outElementList;
algorithm
  outElementList := matchcontinue(inElementList,inPath1,inPath2,inInteger)
    local
      list<DAE.Element> dae,dae_1;
      DAE.Element fn1,fn2,newFn;
      Absyn.Path p1,p2,newPath;
      Integer numArgs;
    case(dae,p1,p2,numArgs)
      equation
        {fn1} = DAEUtil.getNamedFunction(p1,dae);
        {fn2} = DAEUtil.getNamedFunction(p2,dae);
        newPath = makeNewFnPath(p1,p2);
        newFn = buildNewFunction2(fn1,fn2,newPath,dae,numArgs);
      then
        newFn :: dae;
    case(_,_,_,_)
      equation
        Debug.fprintln("failtrace","PartFn.buildNewFunction failed");
      then
        fail();
  end matchcontinue;
end buildNewFunction;

protected function buildNewFunction2
"function: buildNewFunction2
	creates a new function based on given data"
	input DAE.Element bigFunction;
	input DAE.Element smallFunction;
	input Absyn.Path inPath;
	input list<DAE.Element> inElementList;
	input Integer inInteger;
	output DAE.Element outFunction;
algorithm
  outFunction := matchcontinue(bigFunction,smallFunction,inPath,inElementList,inInteger)
    local
      DAE.Element bigfn,smallfn,res;
      Absyn.Path p;
      list<DAE.Element> dae,fnparts,fnparts_1;
      DAE.Type ty;
      Boolean pp;
      Integer numArgs;
      list<DAE.Var> vars;
    case(bigfn as DAE.FUNCTION(_,DAE.DAE(fnparts),ty,pp),smallfn,p,dae,numArgs)
      equation
        (fnparts_1,vars) = buildNewFunctionParts(fnparts,smallfn,dae,numArgs);
        ty = buildNewFunctionType(ty,vars);
        res = DAE.FUNCTION(p,DAE.DAE(fnparts_1),ty,pp);
      then
        res;
    case(_,_,_,_,_)
      equation
        Debug.fprintln("failtrace","PartFn.buildNewFunction2 failed");
      then
        fail();
  end matchcontinue;
end buildNewFunction2;

protected function buildNewFunctionType
"function: buildNewFunctionType
	removes the funcarg that is of T_FUNCTION type and inserts the list of vars as funcargs at the end"
	input DAE.Type inType;
	input list<DAE.Var> inVarList;
	output DAE.Type outType;
algorithm
  outType := matchcontinue(inType,inVarList)
    local
      list<DAE.Var> vars;
      list<DAE.FuncArg> args,args_1,args_2,new_args;
      DAE.Type retType;
      Option<Absyn.Path> po;
    case((DAE.T_FUNCTION(args,retType),po),vars)
      equation
        new_args = Types.makeFargsList(vars);
        args_1 = Util.listSelect(args,isNotFunctionType);
        args_2 = listAppend(args_1,new_args);
      then
        ((DAE.T_FUNCTION(args_2,retType),po));
    case(_,_)
      equation
        Debug.fprintln("failtrace","- PartFn.buildNewFunctionType failed");
      then
        fail();
  end matchcontinue;
end buildNewFunctionType;

protected function isNotFunctionType
"function: isNotFunctionType
	checks to make sure a Types.FuncArg is not of type T_FUNCTION"
	input DAE.FuncArg inFuncArg;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inFuncArg)
    case((_,(DAE.T_FUNCTION(funcArg = _),_))) then false;
    case(_) then true;
  end matchcontinue;
end isNotFunctionType;

protected function buildNewFunctionParts
"function: buildNewFunctionParts
	inserts variables and alters call expressions in the new function"
	input list<DAE.Element> inFunctionParts;
	input DAE.Element smallFunction;
	input list<DAE.Element> inElementList;
	input Integer inInteger;
	output list<DAE.Element> outFunctionParts;
	output list<DAE.Var> outVarList;
algorithm
  (outFunctionParts,outVarList) := matchcontinue(inFunctionParts,smallFunction,inElementList,inInteger)
    local
      list<DAE.Element> parts,dae,inputs,res,smallparts;
      DAE.Element smallfn;
      Absyn.Path p;
      String s;
      Integer numArgs;
      list<DAE.Var> vars;
    case(parts,smallfn as DAE.FUNCTION(p,DAE.DAE(smallparts),_,_),dae,numArgs)
      equation
        inputs = Util.listSelect(smallparts,isInput);
        s = Absyn.pathString(p);
        inputs = Util.listMap1(inputs,renameInput,s);
        inputs = listReverse(getFirstNInputs(listReverse(inputs),numArgs));
        res = insertAfterInputs(parts,inputs);
        res = fixCalls(res,dae,p,inputs);
        res = Util.listSelect(res,isNotFunctionInput);
        vars = Util.listMap(inputs,buildTypeVar);
      then
        (res,vars);
    case(_,_,_,_)
      equation
        Debug.fprintln("failtrace","PartFn.buildNewFunctionParts failed");
      then
        fail();
  end matchcontinue;
end buildNewFunctionParts;

protected function buildTypeVar
"function: buildTypeVar
	turns a DAE.VAR into Types.VAR"
	input DAE.Element inElement;
	output DAE.Var outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      Exp.ComponentRef cref;
      Ident i;
      DAE.Type ty;
      DAE.Var res;
    case(DAE.VAR(componentRef = cref,ty = ty))
      equation
        i = Exp.printComponentRefStr(cref);
        res = DAE.TYPES_VAR(i,DAE.ATTR(false,false,SCode.RO(),SCode.VAR(),Absyn.INPUT(),Absyn.UNSPECIFIED()),false,ty,DAE.UNBOUND()); // TODO: FIXME: binding?
      then
        res;
    case(_)
      equation
        Debug.fprintln("failtrace","- PartFn.buildTypeVar failed");
      then
        fail();
  end matchcontinue;
end buildTypeVar;

protected function isNotFunctionInput
"function: isNotFunctionInput
	checks if an input var is of T_FUNCTION type"
	input DAE.Element inElement;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inElement)
    case(DAE.VAR(direction = DAE.INPUT(),ty = (DAE.T_FUNCTION(funcArg = _),_))) then false;
    case(_) then true;
  end matchcontinue;
end isNotFunctionInput;

protected function getFirstNInputs
"function: getLastNInputs
	returns the last n inputs from a given list"
	input list<DAE.Element> inInputs;
	input Integer inInteger;
	output list<DAE.Element> outInputs;
algorithm
  outInputs := matchcontinue(inInputs,inInteger)
    local
      list<DAE.Element> cdr,cdr_1;
      DAE.Element el;
      Integer numArgs;
    case({},_) then {};
    case(_,0) then {};
    case(el :: cdr,numArgs)
      equation
        cdr_1 = getFirstNInputs(cdr,numArgs-1);
      then
        el :: cdr_1;
  end matchcontinue;
end getFirstNInputs;

protected function insertAfterInputs
"function: insertAfterInputs
	goes through the first list of DAE.Element until it finds the end of the inputs
	then inserts the given list of DAE.Element"
	input list<DAE.Element> inParts;
	input list<DAE.Element> inInputs;
	output list<DAE.Element> outParts;
algorithm
  outParts := matchcontinue(inParts,inInputs)
    local
      list<DAE.Element> cdr,inputs,res;
      DAE.Element e;
    case({},_)
      equation
        Debug.fprintln("failtrace","PartFn.insertAfterInputs failed - no inputs found");
      then
        fail();
    case((e as DAE.VAR(direction = DAE.INPUT())) :: cdr,inputs)
      equation
        DAE.VAR(direction = DAE.INPUT) = Util.listFirst(cdr);
        res = insertAfterInputs(cdr,inputs);
      then
        e :: res;
    case((e as DAE.VAR(direction = DAE.INPUT())) :: cdr,inputs)
      equation
        res = listAppend(inputs,cdr);
      then
        e :: res;
    case(_,_)
      equation
        Debug.fprintln("failtrace","PartFn.insertAfterInputs failed - no inputs found");
      then
        fail();
  end matchcontinue;
end insertAfterInputs;

protected function renameInput
"function: renameInput
	assumes that the given element is a DAE.VAR with Input direction
	prepends the given string to the ComponentRef"
	input DAE.Element inElement;
	input String inString;
	output DAE.Element outElement;
algorithm
  outElement := matchcontinue(inElement,inString)
    local
      DAE.Element e,res;
      Exp.ComponentRef cref,cref_1;
      String s,s_1;
    case(e as DAE.VAR(componentRef = cref,direction=DAE.INPUT()),s)
      equation
        s_1 = stringAppend(s,"_");
        cref_1 = Exp.prependStringCref(s_1,cref);
        res = DAEUtil.replaceCrefInVar(cref_1,e);
      then
        res;
    case(_,_)
      equation
        Debug.fprintln("failtrace","PartFn.renameInput failed - expected input variable");
      then
        fail();
  end matchcontinue;
end renameInput;

protected function isInput
"function: isInput
	checks if a DAE.Element is an input var or not"
	input DAE.Element inElement;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inElement)
    case(DAE.VAR(direction = DAE.INPUT())) then true;
    case(_) then false;
  end matchcontinue;
end isInput;

protected function fixCalls
"function: fixCalls
	replaces calls in the newly built function with calls to the appropriate function, with the correct number of args"
	input list<DAE.Element> inParts;
	input list<DAE.Element> inDAE;
	input Absyn.Path inPath;
	input list<DAE.Element> inInputs;
	output list<DAE.Element> outParts;
algorithm
  outParts := matchcontinue(inParts,inDAE,inPath,inInputs)
    local
      list<DAE.Element> cdr,cdr_1,dae,inputs,res;
      Absyn.Path p;
      DAE.Element part;
      Exp.ComponentRef cref;
      Exp.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<DAE.Statement> alg,alg_1;
      list<Integer> ilst;
    case({},_,_,_) then {};
    // TODO: DAE.VAR()
    // TODO: Remove all cases that cannot appear in functions?
    case(DAE.DEFINE(cref,e) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.DEFINE(cref,e_1) :: cdr_1;
    case(DAE.INITIALDEFINE(cref,e) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.INITIALDEFINE(cref,e_1) :: cdr_1;
    case(DAE.EQUATION(e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.EQUATION(e1_1,e2_1) :: cdr_1;
    case(DAE.ARRAY_EQUATION(ilst,e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.ARRAY_EQUATION(ilst,e1_1,e2_1) :: cdr_1;
    case(DAE.COMPLEX_EQUATION(e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.COMPLEX_EQUATION(e1_1,e2_1) :: cdr_1;
    case(DAE.INITIAL_COMPLEX_EQUATION(e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.INITIAL_COMPLEX_EQUATION(e1_1,e2_1) :: cdr_1;
    // TODO: DAE.WHEN_EQUATION()
    // TODO: DAE.IF_EQUATION()
    // TODO: DAE.INITIAL_IF_EQUATION()
    case(DAE.INITIALEQUATION(e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.INITIALEQUATION(e1_1,e2_1) :: cdr_1;
    case(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(alg)) :: cdr,dae,p,inputs)
      equation
        alg_1 = fixCallsAlg(alg,dae,p,inputs);
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.ALGORITHM(DAE.ALGORITHM_STMTS(alg_1)) :: cdr_1;
    case(DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(alg)) :: cdr,dae,p,inputs)
      equation
        alg_1 = fixCallsAlg(alg,dae,p,inputs);
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        DAE.INITIALALGORITHM(DAE.ALGORITHM_STMTS(alg_1)) :: cdr_1;
    // TODO: More cases?
    case(part :: cdr,dae,p,inputs)
      equation
        cdr_1 = fixCalls(cdr,dae,p,inputs);
      then
        part :: cdr_1;
    case(_,_,_,_)
      equation
        Debug.fprintln("failtrace","PartFn.fixCalls failed");
      then
        fail();
  end matchcontinue;
end fixCalls;

protected function fixCallsAlg
"function: fixCallsAlg
	fixes calls in algorithm sections of the new function"
	input list<DAE.Statement> inStmts;
	input list<DAE.Element> inDAE;
	input Absyn.Path inPath;
	input list<DAE.Element> inInputs;
	output list<DAE.Statement> outStmts;
algorithm
  outStmts := matchcontinue(inStmts,inDAE,inPath,inInputs)
    local
      list<DAE.Statement> cdr,cdr_1,stmts,stmts_1;
      list<DAE.Element> dae,inputs;
      Absyn.Path p;
      Exp.Type ty;
      Exp.ComponentRef cref;
      DAE.Else el,el_1;
      Ident i;
      Boolean b;
      DAE.Statement stmt,stmt_1;
      list<Integer> ilst;
      Exp.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<Exp.Exp> elst,elst_1;
    case({},_,_,_) then {};
    case(DAE.STMT_ASSIGN(ty,e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_ASSIGN(ty,e1_1,e2_1) :: cdr_1;
    case(DAE.STMT_TUPLE_ASSIGN(ty,elst,e) :: cdr,dae,p,inputs)
      equation
        elst_1 = Util.listMap1(elst,handleExpList2,(p,inputs,dae));
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_TUPLE_ASSIGN(ty,elst_1,e_1) :: cdr_1;
    case(DAE.STMT_ASSIGN_ARR(ty,cref,e) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_ASSIGN_ARR(ty,cref,e_1) :: cdr_1;
    case(DAE.STMT_IF(e,stmts,el) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        el_1 = fixCallsElse(el,dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_IF(e_1,stmts_1,el_1) :: cdr_1;
    case(DAE.STMT_FOR(ty,b,i,e,stmts) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_FOR(ty,b,i,e_1,stmts_1) :: cdr_1;
    case(DAE.STMT_WHILE(e,stmts) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_WHILE(e_1,stmts_1) :: cdr_1;
    case(DAE.STMT_WHEN(e,stmts,SOME(stmt),ilst) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        {stmt,stmt_1} = fixCallsAlg({stmt},dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_WHEN(e_1,stmts_1,SOME(stmt_1),ilst) :: cdr_1;
    case(DAE.STMT_WHEN(e,stmts,NONE,ilst) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_WHEN(e_1,stmts_1,NONE,ilst) :: cdr_1;
    case(DAE.STMT_ASSERT(e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_ASSERT(e1_1,e2_1) :: cdr_1;
    case(DAE.STMT_TERMINATE(e) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_TERMINATE(e_1) :: cdr_1;
    case(DAE.STMT_REINIT(e1,e2) :: cdr,dae,p,inputs)
      equation
        ((e1_1,_)) = Exp.traverseExp(e1,fixCall,(p,inputs,dae));
        ((e2_1,_)) = Exp.traverseExp(e2,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_REINIT(e1_1,e2_1) :: cdr_1;
    case(DAE.STMT_NORETCALL(e) :: cdr,dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_NORETCALL(e) :: cdr_1;
    case(DAE.STMT_TRY(stmts) :: cdr,dae,p,inputs)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_TRY(stmts_1) :: cdr_1;
    case(DAE.STMT_CATCH(stmts) :: cdr,dae,p,inputs)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_CATCH(stmts_1) :: cdr_1;
    case(DAE.STMT_MATCHCASES(elst) :: cdr,dae,p,inputs)
      equation
        elst_1 = Util.listMap1(elst,handleExpList2,(p,inputs,dae));
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        DAE.STMT_MATCHCASES(elst_1) :: cdr_1;
    case(stmt :: cdr,dae,p,inputs)
      equation
        cdr_1 = fixCallsAlg(cdr,dae,p,inputs);
      then
        stmt :: cdr_1;
    case(_,_,_,_)
      equation
        Debug.fprintln("failtrace","PartFn.fixCallsAlg failed");
      then
        fail();
  end matchcontinue;
end fixCallsAlg;

protected function fixCallsElse
"function: fixCallsElse
	fixes calls in an DAE.Else"
	input DAE.Else inElse;
	input list<DAE.Element> inDAE;
	input Absyn.Path inPath;
	input list<DAE.Element> inInputs;
	output DAE.Else outElse;
algorithm
  outElse := matchcontinue(inElse,inDAE,inPath,inInputs)
    local
      Exp.Exp e,e_1;
      list<DAE.Statement> stmts,stmts_1;
      DAE.Else el,el_1;
      list<DAE.Element> dae,inputs;
      Absyn.Path p;
    case(DAE.ELSEIF(e,stmts,el),dae,p,inputs)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,(p,inputs,dae));
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
        el_1 = fixCallsElse(el,dae,p,inputs);
      then
        DAE.ELSEIF(e_1,stmts_1,el_1);
    case(DAE.ELSE(stmts),dae,p,inputs)
      equation
        stmts_1 = fixCallsAlg(stmts,dae,p,inputs);
      then
        DAE.ELSE(stmts_1);
    case(el,_,_,_) then el;
  end matchcontinue;
end fixCallsElse;

protected function handleExpList2
"function: handleExpList2
	helper function to fixCallsAlg"
	input Exp.Exp inExp;
	input tuple<Absyn.Path, list<DAE.Element>, list<DAE.Element>> inTuple;
	output Exp.Exp outExp;
algorithm
  outExp := matchcontinue(inExp,inTuple)
    local
      Exp.Exp e,e_1;
      tuple<Absyn.Path, list<DAE.Element>, list<DAE.Element>> tup;
    case(e,tup)
      equation
        ((e_1,_)) = Exp.traverseExp(e,fixCall,tup);
      then
        e_1;
    case(_,_)
      equation
        Debug.fprintln("failtrace","PartFn.handleExpList2 failed");
      then
        fail();
  end matchcontinue;
end handleExpList2;

protected function fixCall
"function: fixCall
	replaces the path and args in a function call"
	input tuple<Exp.Exp, tuple<Absyn.Path, list<DAE.Element>, list<DAE.Element>>> inTuple;
	output tuple<Exp.Exp, tuple<Absyn.Path, list<DAE.Element>, list<DAE.Element>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Exp.Exp e;
      Absyn.Path p,orig_p;
      list<DAE.Element> inputs,dae,tmp;
      Exp.Type ty;
      Boolean tup,bui,inl;
      list<Exp.Exp> args,args2,args_1;
      list<Exp.ComponentRef> crefs;
      String str;
      // TEMPFIX REMOVE UNBOX CALLS
    case((DAE.CALL(orig_p,args,tup,bui,ty,inl),(p,inputs,dae)))
      equation
        str = Absyn.pathString(orig_p);
        true = Util.strncmp(str,"mmc",3);
        e = Util.listFirst(args);
      then
        ((e,(p,inputs,dae)));
    case((DAE.CALL(orig_p,args,tup,false,ty,inl),(p,inputs,dae)))
      equation
        tmp = DAEUtil.getNamedFunction(orig_p,dae); // if function exists, do not replace call
        false = Util.isListNotEmpty(tmp);
        crefs = Util.listMap(inputs,DAEUtil.varCref);
        args2 = Util.listMap(crefs,Exp.crefExp);
        args_1 = listAppend(args,args2);
      then
        ((DAE.CALL(p,args_1,tup,false,ty,inl),(p,inputs,dae)));
    case((e,(p,inputs,dae))) then ((e,(p,inputs,dae)));
  end matchcontinue;
end fixCall;

protected function getPartEvalFunction
"function: getPartEvalFunction
	gets the exp and index of a partevalfunction from a list of exps
	fail if no partevalfunction is present"
	input list<Exp.Exp> inExpList;
	input Integer inInteger "accumulator";
	output Exp.Exp outExp;
	output Integer outInteger;
algorithm
  (outExp,outInteger) := matchcontinue(inExpList,inInteger)
    local
      list<Exp.Exp> cdr;
      Integer index,index_1;
      Exp.Exp e;
    case({},_) then fail();
    case((e as DAE.PARTEVALFUNCTION(path=_)) :: _,index) then (e,index);
    case(_ :: cdr,index)
      equation
        (e,index_1) = getPartEvalFunction(cdr,index+1);
      then
        (e,index_1);
  end matchcontinue;
end getPartEvalFunction;















end PartFn;