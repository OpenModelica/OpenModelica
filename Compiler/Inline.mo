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

// stefan
package Inline
" file:	       Inline.mo
  package:     Inline
  description: inline functions

  RCS: $Id$

  This module contains data structures and functions for inline functions.

  The entry point is the inlineCalls function, or inlineCallsInFunctions
  "

public import Absyn;
public import DAE;
public import DAELow;
public import SCode;
public import Util;
public import Values;
public import Algorithm;

type Ident = String;
  
public type Functiontuple = tuple<Option<list<DAE.Element>>,Option<DAE.FunctionTree>,list<DAE.InlineType>>;  

protected import Debug;
protected import DAEUtil;
protected import Exp;
protected import VarTransform;

public function inlineCalls
"function: inlineCalls
	searches for calls where the inline flag is true, and inlines them"
	input Option<list<DAE.Element>> inElementList "functions";
	input Option<DAE.FunctionTree> inFTree "functions";
	input list<DAE.InlineType> inITLst;
	input DAELow.DAELow inDAELow;
  output DAELow.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue(inElementList,inFTree,inITLst,inDAELow)
    local
      Option<list<DAE.Element>> fns;
      Option<DAE.FunctionTree> ftree;
      list<DAE.InlineType> itlst;
      DAELow.Variables orderedVars;
      DAELow.Variables knownVars;
      DAELow.Variables externalObjects;
      VarTransform.VariableReplacements aliasVars "alias-variables' hashtable";
      DAELow.EquationArray orderedEqs;
      DAELow.EquationArray removedEqs;
      DAELow.EquationArray initialEqs;
      DAELow.MultiDimEquation[:] arrayEqs;
      list<DAELow.MultiDimEquation> mdelst;
      Algorithm.Algorithm[:] algorithms;
      list<Algorithm.Algorithm> alglst;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
    case(fns,ftree,itlst,DAELow.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses))
      equation
        orderedVars = inlineVariables(orderedVars,(fns,ftree,itlst));
        knownVars = inlineVariables(knownVars,(fns,ftree,itlst));
        externalObjects = inlineVariables(externalObjects,(fns,ftree,itlst));
        orderedEqs = inlineEquationArray(orderedEqs,(fns,ftree,itlst));
        removedEqs = inlineEquationArray(removedEqs,(fns,ftree,itlst));
        initialEqs = inlineEquationArray(initialEqs,(fns,ftree,itlst));
        mdelst = Util.listMap1(arrayList(arrayEqs),inlineMultiDimEqs,(fns,ftree,itlst));
        arrayEqs = listArray(mdelst);
        alglst = Util.listMap1(arrayList(algorithms),inlineAlgorithm,(fns,ftree,itlst));
        algorithms = listArray(alglst);
        eventInfo = inlineEventInfo(eventInfo,(fns,ftree,itlst));
        extObjClasses = inlineExtObjClasses(extObjClasses,(fns,ftree,itlst));
      then
        DAELow.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses);
    case(_,_,_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineCalls failed");
      then
        fail();
  end matchcontinue;
end inlineCalls;

protected function inlineEquationArray "
function: inlineEquationArray
	inlines function calls in an equation array"
	input DAELow.EquationArray inEquationArray;
	input Functiontuple inElementList;
	output DAELow.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue(inEquationArray,inElementList)
    local
      Functiontuple fns;
      Integer i1,i2;
      Option<DAELow.Equation>[:] eqarr,eqarr_1;
      list<Option<DAELow.Equation>> eqlst,eqlst_1;
    case(DAELow.EQUATION_ARRAY(i1,i2,eqarr),fns)
      equation
        eqlst = arrayList(eqarr);
        eqlst_1 = Util.listMap1(eqlst,inlineEqOpt,fns);
        eqarr_1 = listArray(eqlst_1);
      then
        DAELow.EQUATION_ARRAY(i1,i2,eqarr_1);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineEquationArray failed");
      then
        fail();        
  end matchcontinue;
end inlineEquationArray;

public function inlineEqOpt "
function: inlineEqOpt
	inlines function calls in equations"
	input Option<DAELow.Equation> inEquationOption;
	input Functiontuple inElementList;
	output Option<DAELow.Equation> outEquationOption;
algorithm
  outEquationOption := matchcontinue(inEquationOption,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      Integer i;
      list<DAE.Exp> explst,explst_1,explst1,explst1_1,explst2,explst2_1;
      DAE.ComponentRef cref;
      DAELow.WhenEquation weq,weq_1;
      DAE.ElementSource source "the origin of the element";

    case(NONE,_) then NONE;
    case(SOME(DAELow.EQUATION(e1,e2,source)),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        SOME(DAELow.EQUATION(e1_1,e2_1,source));

    case(SOME(DAELow.ARRAY_EQUATION(i,explst,source)),fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
      then
        SOME(DAELow.ARRAY_EQUATION(i,explst_1,source));

    case(SOME(DAELow.SOLVED_EQUATION(cref,e,source)),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        SOME(DAELow.SOLVED_EQUATION(cref,e_1,source));

    case(SOME(DAELow.RESIDUAL_EQUATION(e,source)),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        SOME(DAELow.RESIDUAL_EQUATION(e_1,source));

    case(SOME(DAELow.ALGORITHM(i,explst1,explst2,source)),fns)
      equation
        explst1_1 = Util.listMap1(explst1,inlineExp,fns);
        explst2_1 = Util.listMap1(explst2,inlineExp,fns);
      then
        SOME(DAELow.ALGORITHM(i,explst1_1,explst2_1,source));

    case(SOME(DAELow.WHEN_EQUATION(weq,source)),fns)
      equation
        weq_1 = inlineWhenEq(weq,fns);
      then
        SOME(DAELow.WHEN_EQUATION(weq_1,source));
  
    case(SOME(DAELow.COMPLEX_EQUATION(index=i,lhs=e1,rhs=e2,source=source)),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        SOME(DAELow.COMPLEX_EQUATION(i,e1_1,e2_1,source));        
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineEqOpt failed");
      then
        fail();          
  end matchcontinue;
end inlineEqOpt;

protected function inlineWhenEq
"function: inlineWhenEq
	inlines function calls in when equations"
	input DAELow.WhenEquation inWhenEquation;
	input Functiontuple inElementList;
	output DAELow.WhenEquation outWhenEquation;
algorithm
  outWhenEquation := matchcontinue(inWhenEquation,inElementList)
    local
      Functiontuple fns;
      Integer i;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      DAELow.WhenEquation weq,weq_1;
    case(DAELow.WHEN_EQ(i,cref,e,NONE),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAELow.WHEN_EQ(i,cref,e_1,NONE);
    case(DAELow.WHEN_EQ(i,cref,e,SOME(weq)),fns)
      equation
        e_1 = inlineExp(e,fns);
        weq_1 = inlineWhenEq(weq,fns);
      then
        DAELow.WHEN_EQ(i,cref,e_1,SOME(weq_1));
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineWhenEq failed");
      then
        fail();          
  end matchcontinue;
end inlineWhenEq;

protected function inlineVariables
"function: inlineVariables
	inlines function calls in variables"
	input DAELow.Variables inVariables;
	input Functiontuple inElementList;
	output DAELow.Variables outVariables;
algorithm
  outVariables := matchcontinue(inVariables,inElementList)
    local
      Functiontuple fns;
      list<DAELow.CrefIndex>[:] crefind;
      list<DAELow.StringIndex>[:] strind;
      Integer i1,i2,i3,i4;
      Option<DAELow.Var>[:] vararr,vararr_1;
      list<Option<DAELow.Var>> varlst,varlst_1;
    case(DAELow.VARIABLES(crefind,strind,DAELow.VARIABLE_ARRAY(i3,i4,vararr),i1,i2),fns)
      equation
        varlst = arrayList(vararr);
        varlst_1 = Util.listMap1(varlst,inlineVarOpt,fns);
        vararr_1 = listArray(varlst_1);
      then
        DAELow.VARIABLES(crefind,strind,DAELow.VARIABLE_ARRAY(i3,i4,vararr_1),i1,i2);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineVariables failed");
      then
        fail();          
  end matchcontinue;
end inlineVariables;

public function inlineVarOpt
"functio: inlineVarOpt
	inlines calls in a variable option"
	input Option<DAELow.Var> inVarOption;
	input Functiontuple inElementList;
	output Option<DAELow.Var> outVarOption;
algorithm
  outVarOption := matchcontinue(inVarOption,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef varName;
      DAELow.VarKind varKind;
      DAE.VarDirection varDirection;
      DAELow.Type varType;
      DAE.Exp e,e_1;
      Option<Values.Value> bindValue;
      DAE.InstDims arrayDim;
      Integer index;
      DAE.ComponentRef origVarName;
      list<Absyn.Path> className;
      Option<DAE.VariableAttributes> values;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<DAELow.Var> var;
      DAE.ElementSource source "the origin of the element";

    case(NONE,_) then NONE;
    case(SOME(DAELow.VAR(varName,varKind,varDirection,varType,SOME(e),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        SOME(DAELow.VAR(varName,varKind,varDirection,varType,SOME(e_1),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix));
    case(var,_) then var;
  end matchcontinue;
end inlineVarOpt;

public function inlineMultiDimEqs
"function: inlineMultiDimEqs
	inlines function calls in multi dim equations"
	input DAELow.MultiDimEquation inMultiDimEquation;
	input Functiontuple inElementList;
	output DAELow.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue(inMultiDimEquation,inElementList)
    local
      Functiontuple fns;
      list<Integer> ilst;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source "the origin of the element";

    case(DAELow.MULTIDIM_EQUATION(ilst,e1,e2,source),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAELow.MULTIDIM_EQUATION(ilst,e1_1,e2_1,source);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineMultiDimEqs failed");
      then
        fail();         
  end matchcontinue;
end inlineMultiDimEqs;

public function inlineEventInfo
"function: inlineEventInfo
	inlines function calls in event info"
	input DAELow.EventInfo inEventInfo;
	input Functiontuple inElementList;
	output DAELow.EventInfo outEventInfo;
algorithm
  outEventInfo := matchcontinue(inEventInfo,inElementList)
    local
      Functiontuple fns;
      list<DAELow.WhenClause> wclst,wclst_1;
      list<DAELow.ZeroCrossing> zclst,zclst_1;
    case(DAELow.EVENT_INFO(wclst,zclst),fns)
      equation
        wclst_1 = Util.listMap1(wclst,inlineWhenClause,fns);
        zclst_1 = Util.listMap1(zclst,inlineZeroCrossing,fns);
      then
        DAELow.EVENT_INFO(wclst_1,zclst_1);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineEventInfo failed");
      then
        fail();         
  end matchcontinue;
end inlineEventInfo;

protected function inlineZeroCrossing
"function: inlineZeroCrossing
	inlines function calls in a zero crossing"
	input DAELow.ZeroCrossing inZeroCrossing;
	input Functiontuple inElementList;
	output DAELow.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := matchcontinue(inZeroCrossing,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1;
      list<Integer> ilst1,ilst2;
    case(DAELow.ZERO_CROSSING(e,ilst1,ilst2),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAELow.ZERO_CROSSING(e_1,ilst1,ilst2);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineZeroCrossing failed");
      then
        fail();         
  end matchcontinue;
end inlineZeroCrossing;

protected function inlineWhenClause
"function: inlineWhenClause
	inlines function calls in a when clause"
	input DAELow.WhenClause inWhenClause;
	input Functiontuple inElementList;
	output DAELow.WhenClause outWhenClause;
algorithm
  outWhenClause := matchcontinue(inWhenClause,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1;
      list<DAELow.ReinitStatement> rslst,rslst_1;
      Option<Integer> io;

    case(DAELow.WHEN_CLAUSE(e,rslst,io),fns)
      equation
        e_1 = inlineExp(e,fns);
        rslst_1 = Util.listMap1(rslst,inlineReinitStmt,fns);
      then
        DAELow.WHEN_CLAUSE(e_1,rslst_1,io);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineWhenClause failed");
      then
        fail();        
  end matchcontinue;
end inlineWhenClause;

protected function inlineReinitStmt
"function: inlineReinitStmt
	inlines function calls in a reinit statement"
	input DAELow.ReinitStatement inReinitStatement;
	input Functiontuple inElementList;
	output DAELow.ReinitStatement outReinitStatement;
algorithm
  outReinitStatement := matchcontinue(inReinitStatement,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      DAELow.ReinitStatement rs;
      DAE.ElementSource source "the origin of the element";

    case(DAELow.REINIT(cref,e,source),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAELow.REINIT(cref,e_1,source);
    case(rs,_) then rs;
  end matchcontinue;
end inlineReinitStmt;

public function inlineExtObjClasses
"function: inlineExtObjClasses
	inlines function calls in external object classes"
	input DAELow.ExternalObjectClasses inExtObjClasses;
	input Functiontuple inElementList;
	output DAELow.ExternalObjectClasses outExtObjClasses;
algorithm
  outExtObjClasses := matchcontinue(inExtObjClasses,inElementList)
    local
      Functiontuple fns;
      DAELow.ExternalObjectClasses cdr,cdr_1;
      DAELow.ExternalObjectClass res;
      Absyn.Path p;
      DAE.Element e1,e1_1,e2,e2_1;
      DAE.ElementSource source "the origin of the element";

    case({},_) then {};
    case(DAELow.EXTOBJCLASS(p,e1,e2,source) :: cdr,fns)
      equation
        {e1_1,e2_1} = inlineDAEElements({e1,e2},fns);
        res = DAELow.EXTOBJCLASS(p,e1_1,e2_1,source);
        cdr_1 = inlineExtObjClasses(cdr,fns);
      then
        res :: cdr_1;
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineExtObjClasses failed");
      then
        fail();        
  end matchcontinue;
end inlineExtObjClasses;

public function inlineCallsInFunctions "
function: inlineCallsInFunctions
	inlines function calls within functions"
	input list<DAE.Element> inElementList;
	input list<DAE.InlineType> inITList;
	output list<DAE.Element> outElementList;
algorithm
  outElementList := inlineDAEElements(inElementList,(SOME(inElementList),NONE(),inITList));
end inlineCallsInFunctions;

protected function inlineDAEElements
"function: inlineDAEElements
	inlines calls in DAEElements"
	input list<DAE.Element> inElementList;
	input Functiontuple inFunctions;
	output list<DAE.Element> outElementList;
algorithm
  outDAElist := matchcontinue(inElementList,inFunctions)
    local
      Functiontuple fns;
      list<DAE.Element> cdr,cdr_1,elist,elist_1;
      list<list<DAE.Element>> dlist,dlist_1;
      DAE.Element el,el_1,res,el1,el1_1,el2,el2_1;
      DAE.ComponentRef componentRef;
      DAE.VarKind kind;
      DAE.VarDirection direction;
      DAE.VarProtection protection;
      DAE.Type ty,t;
      DAE.Exp binding,binding_1,exp,exp_1,exp1,exp1_1,exp2,exp2_1;
      DAE.InstDims dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> pathLst;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      list<Integer> dimension;
      Algorithm.Algorithm alg,alg_1;
      Ident i;
      Absyn.Path p;
      Boolean partialPrefix;
      DAE.ExternalDecl ext;
      list<DAE.Exp> explst,explst_1;
      DAE.InlineType inlineType;
      list<DAE.FunctionDefinition> funcDefs;
      DAE.ElementSource source "the origin of the element";

    case({},_) then {};
    case(DAE.VAR(componentRef,kind,direction,protection,ty,SOME(binding),dims,flowPrefix,streamPrefix,
                 source,variableAttributesOption,absynCommentOption,innerOuter) :: cdr,fns)
      equation
        binding_1 = inlineExp(binding,fns);
        res = DAE.VAR(componentRef,kind,direction,protection,ty,SOME(binding_1),dims,flowPrefix,streamPrefix,
                      source,variableAttributesOption,absynCommentOption,innerOuter);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.DEFINE(componentRef,exp,source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        res = DAE.DEFINE(componentRef,exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIALDEFINE(componentRef,exp,source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        res = DAE.INITIALDEFINE(componentRef,exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.EQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.EQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.ARRAY_EQUATION(dimension,exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.ARRAY_EQUATION(dimension,exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIAL_ARRAY_EQUATION(dimension,exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.INITIAL_ARRAY_EQUATION(dimension,exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.COMPLEX_EQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.COMPLEX_EQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIAL_COMPLEX_EQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.INITIAL_COMPLEX_EQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.WHEN_EQUATION(exp,elist,SOME(el),source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        elist_1 = inlineDAEElements(elist,fns);
        {el_1} = inlineDAEElements({el},fns);
        res = DAE.WHEN_EQUATION(exp_1,elist_1,SOME(el_1),source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.WHEN_EQUATION(exp,elist,NONE,source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.WHEN_EQUATION(exp_1,elist_1,NONE,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.IF_EQUATION(explst,dlist,elist,source) :: cdr,fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
        dlist_1 = Util.listMap1(dlist,inlineDAEElements,fns);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.IF_EQUATION(explst_1,dlist_1,elist_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIAL_IF_EQUATION(explst,dlist,elist,source) :: cdr,fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
        dlist_1 = Util.listMap1(dlist,inlineDAEElements,fns);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.INITIAL_IF_EQUATION(explst_1,dlist_1,elist_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIALEQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.INITIALEQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.ALGORITHM(alg,source) :: cdr,fns)
      equation
        alg_1 = inlineAlgorithm(alg,fns);
        res = DAE.ALGORITHM(alg_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIALALGORITHM(alg,source) :: cdr,fns)
      equation
        alg_1 = inlineAlgorithm(alg,fns);
        res = DAE.INITIALALGORITHM(alg_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.COMP(i,elist,source) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.COMP(i,elist_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.FUNCTION(p,DAE.FUNCTION_DEF(body = elist)::funcDefs,t,partialPrefix,inlineType,source) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.FUNCTION(p,DAE.FUNCTION_DEF(elist_1)::funcDefs,t,partialPrefix,inlineType,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;
    // external functions
    case(DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist,ext)::funcDefs,t,partialPrefix,inlineType,source) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist_1,ext)::funcDefs,t,partialPrefix,inlineType,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;
    case(DAE.EXTOBJECTCLASS(p,el1,el2,source) :: cdr,fns)
      equation
        {el1_1} = inlineDAEElements({el1},fns);
        {el2_1} = inlineDAEElements({el2},fns);
        res = DAE.EXTOBJECTCLASS(p,el1_1,el2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.ASSERT(exp1,exp2,source) :: cdr,fns)
      equation
        exp1_1 = inlineExp(exp1,fns);
        exp2_1 = inlineExp(exp2,fns);
        res = DAE.ASSERT(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.TERMINATE(exp,source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        res = DAE.TERMINATE(exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.REINIT(componentRef,exp,source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        res = DAE.REINIT(componentRef,exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.NORETCALL(p,explst,source) :: cdr,fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
        res = DAE.NORETCALL(p,explst_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(el :: cdr,fns)
      equation
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        el :: cdr_1;
  end matchcontinue;
end inlineDAEElements;

public function inlineAlgorithm
"function: inlineAlgorithm
	inline calls in an Algorithm.Algorithm"
	input Algorithm.Algorithm inAlgorithm;
	input Functiontuple inElementList;
	output Algorithm.Algorithm outAlgorithm;
algorithm
  outAlgorithm := matchcontinue(inAlgorithm,inElementList)
    local
      list<Algorithm.Statement> stmts,stmts_1;
      Functiontuple fns;
    case(DAE.ALGORITHM_STMTS(stmts),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.ALGORITHM_STMTS(stmts_1);
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineAlgorithm failed");
      then
        fail();         
  end matchcontinue;
end inlineAlgorithm;

protected function inlineStatement
"function: inlineStatement
	inlines calls in an Algorithm.Statement"
	input Algorithm.Statement inStatement;
	input Functiontuple inElementList;
	output Algorithm.Statement outStatement;
algorithm
  outStatement := matchcontinue(inStatement,inElementList)
    local
      Functiontuple fns;
      Algorithm.Statement stmt,stmt_1;
      DAE.ExpType t;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<DAE.Exp> explst,explst_1;
      DAE.ComponentRef cref;
      Algorithm.Else a_else,a_else_1;
      list<Algorithm.Statement> stmts,stmts_1;
      Boolean b;
      Ident i;
      list<Integer> ilst;
    case(DAE.STMT_ASSIGN(t,e1,e2),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAE.STMT_ASSIGN(t,e1_1,e2_1);
    case(DAE.STMT_TUPLE_ASSIGN(t,explst,e),fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_TUPLE_ASSIGN(t,explst_1,e_1);
    case(DAE.STMT_ASSIGN_ARR(t,cref,e),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_ASSIGN_ARR(t,cref,e_1);
    case(DAE.STMT_IF(e,stmts,a_else),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
        a_else_1 = inlineElse(a_else,fns);
      then
        DAE.STMT_IF(e_1,stmts_1,a_else_1);
    case(DAE.STMT_FOR(t,b,i,e,stmts),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_FOR(t,b,i,e_1,stmts_1);
    case(DAE.STMT_WHILE(e,stmts),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_WHILE(e_1,stmts_1);
    case(DAE.STMT_WHEN(e,stmts,SOME(stmt),ilst),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
        stmt_1 = inlineStatement(stmt,fns);
      then
        DAE.STMT_WHEN(e_1,stmts_1,SOME(stmt_1),ilst);
    case(DAE.STMT_WHEN(e,stmts,NONE,ilst),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_WHEN(e_1,stmts_1,NONE,ilst);
    case(DAE.STMT_ASSERT(e1,e2),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAE.STMT_ASSERT(e1_1,e2_1);
    case(DAE.STMT_TERMINATE(e),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_TERMINATE(e_1);
    case(DAE.STMT_REINIT(e1,e2),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAE.STMT_REINIT(e1_1,e2_1);
    case(DAE.STMT_NORETCALL(e),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_NORETCALL(e_1);
    case(DAE.STMT_TRY(stmts),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_TRY(stmts_1);
    case(DAE.STMT_CATCH(stmts),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_CATCH(stmts_1);
    case(DAE.STMT_MATCHCASES(explst),fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
      then
        DAE.STMT_MATCHCASES(explst_1);
    case(stmt,_) then stmt;
  end matchcontinue;
end inlineStatement;

protected function inlineElse
"function: inlineElse
	inlines calls in an Algorithm.Else"
	input Algorithm.Else inElse;
	input Functiontuple inElementList;
	output Algorithm.Else outElse;
algorithm
  outElse := matchcontinue(inElse,inElementList)
    local
      Functiontuple fns;
      Algorithm.Else a_else,a_else_1;
      DAE.Exp e,e_1;
      list<Algorithm.Statement> stmts,stmts_1;
    case(DAE.ELSEIF(e,stmts,a_else),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
        a_else_1 = inlineElse(a_else,fns);
      then
        DAE.ELSEIF(e_1,stmts_1,a_else_1);
    case(DAE.ELSE(stmts),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.ELSE(stmts_1);
    case(a_else,fns) then a_else;
  end matchcontinue;
end inlineElse;

public function inlineExp "
function: inlineExp
	inlines calls in an DAE.Exp"
	input DAE.Exp inExp;
	input Functiontuple inElementList;
	output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1;
    case(e,fns)
      equation
        ((e_1,fns)) = Exp.traverseExp(e,inlineCall,fns);
      then
        e_1;
    case(e,_) then e;
  end matchcontinue;
end inlineExp;

protected function inlineCall
"function: inlineCall
	replaces an inline call with the expression from the function"
	input tuple<DAE.Exp, Functiontuple> inTuple;
	output tuple<DAE.Exp, Functiontuple> outTuple;
algorithm
  outExp := matchcontinue(inTuple)
    local
      Functiontuple fns,fns1;
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      Boolean tup,built;
      DAE.ExpType t;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp newExp,newExp1, e1;
      DAE.InlineType inlineType;
    case((e1 as DAE.CALL(p,args,tup,built,t,inlineType),fns))
      equation
        true = DAEUtil.convertInlineTypeToBool(inlineType);
        true = checkInlineType(inlineType,fns);
        fn = getFunctionBody(p,fns);
        crefs = Util.listMap(fn,getInputCrefs);
        crefs = Util.listSelect(crefs,removeWilds);
        argmap = Util.listThreadTuple(crefs,args);
        argmap = extendCrefRecords(argmap);
        newExp = getRhsExp(fn);
        ((newExp,argmap)) = Exp.traverseExp(newExp,replaceArgs,argmap);
        // for inlinecals in functions
        ((newExp1,fns1)) = Exp.traverseExp(newExp,inlineCall,fns);
      then
        ((newExp1,fns));
    case((newExp,fns)) then ((newExp,fns));
  end matchcontinue;
end inlineCall;

protected function checkInlineType "
Author: Frenkel TUD, 2010-05"
  input DAE.InlineType inIT;
  input Functiontuple fns;
  output Boolean outb;
algorithm
  outb := matchcontinue(inIT,fns)
    local
      DAE.InlineType it;
      list<DAE.InlineType> itlst;
      Boolean b;
    case (it,(_,_,itlst))
      equation
       b = Util.listContains(it,itlst);
      then b; 
    case (_,_) then false; 
  end matchcontinue;
end checkInlineType;

protected function extendCrefRecords
"function: extendCrefRecords
	extends crefs from records"
	input list<tuple<DAE.ComponentRef, DAE.Exp>> inArgmap;
	output list<tuple<DAE.ComponentRef, DAE.Exp>> outArgmap;
algorithm
  outArgmap := matchcontinue(inArgmap)
    local
      list<tuple<DAE.ComponentRef, DAE.Exp>> res,res1,res2,new,new1;
      DAE.ComponentRef c,cref;
      DAE.Exp e;
      list<DAE.ExpVar> varLst;
    case ({}) then {}; 
    case((c,e as (DAE.CREF(componentRef = cref)))::res)
      equation
      res1 = extendCrefRecords(res);  
      DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cref);
      new = Util.listMap2(varLst,extendCrefRecords1,c,cref);
      new1 = extendCrefRecords(new);
      res2 = listAppend(new1,res1);
      then ((c,e)::res2);      
    case((c,e)::res)
      equation
      res1 = extendCrefRecords(res);  
      then ((c,e)::res1);
  end matchcontinue;
end extendCrefRecords;

protected function extendCrefRecords1
"function: extendCrefRecords1
	helper for extendCrefRecords"
	input DAE.ExpVar ev;
	input DAE.ComponentRef c;
	input DAE.ComponentRef e;
	output tuple<DAE.ComponentRef, DAE.Exp> outArg;
algorithm
  outArg := matchcontinue(ev,c,e)
    local
      list<DAE.ExpVar> varLst;
      DAE.Ident ident,eident;
      DAE.ExpType identType,eidentType,tp;
      list<DAE.Subscript> subscriptLst,esubscriptLst; 
      String name;
      DAE.ComponentRef c1,e1;
    case(DAE.COMPLEX_VAR(name=name,tp=tp),c,e) 
      equation
      c1 = Exp.extendCref(c,tp,name,{});  
      e1 = Exp.extendCref(e,tp,name,{});  
      then ((c1,DAE.CREF(e1,tp))); 
    case(_,_,_)
      equation
        Debug.fprintln("failtrace","Inline.extendCrefRecords1 failed");
      then
        fail();                   
  end matchcontinue;
end extendCrefRecords1;

protected function getFunctionBody
"function: getFunctionBody
	returns the body of a function"
	input Absyn.Path p;
	input Functiontuple fns;
	output list<DAE.Element> outfn;
algorithm
  outfn := matchcontinue(p,fns)
    local
      list<DAE.Element> flst,fn;
      DAE.FunctionTree ftree;
    case(p,(SOME(flst),_,_))
    equation
      DAE.FUNCTION( functions = DAE.FUNCTION_DEF(body = fn)::_) :: _ = DAEUtil.getNamedFunction(p,flst);  
    then fn;
    case(p,(_,SOME(ftree),_))
    equation
      DAE.FUNCTION( functions = DAE.FUNCTION_DEF(body = fn)::_) = DAEUtil.avlTreeGet(ftree,p); 
    then fn;   
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.getFunctionBody failed");
      then
        fail();        
  end matchcontinue;
end getFunctionBody;

protected function getRhsExp
"function: getRhsExp
	returns the right hand side of an assignment from a function"
	input list<DAE.Element> inElementList;
	output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inElementList)
    local
      list<DAE.Element> cdr;
      DAE.Exp res;
    case({})
      equation
        Debug.fprintln("failtrace","Inline.getRhsExp failed - cannot inline such a function");
      then
        fail();
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN(_,_,res)})) :: _) then res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(_,_,res)})):: _) then res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN_ARR(_,_,res)})) :: _) then res;
    case(_ :: cdr)
      equation
        res = getRhsExp(cdr);
      then
        res;
  end matchcontinue;
end getRhsExp;

protected function replaceArgs
"function: replaceArgs
	finds DAE.CREF and replaces them with new exps if the cref is in the argmap"
	input tuple<DAE.Exp, list<tuple<DAE.ComponentRef, DAE.Exp>>> inTuple;
	output tuple<DAE.Exp, list<tuple<DAE.ComponentRef, DAE.Exp>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      list<DAE.Element> fns;
      DAE.ComponentRef cref;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp e;
    case((DAE.CREF(componentRef = cref),argmap))
      equation
        e = getExpFromArgMap(argmap,cref);
      then
        ((e,argmap));
    case((e,argmap)) then ((e,argmap));
  end matchcontinue;
end replaceArgs;

protected function getExpFromArgMap
"function: getExpFromArgMap
	returns the exp from the given argmap with the given key"
	input list<tuple<DAE.ComponentRef, DAE.Exp>> inArgMap;
	input DAE.ComponentRef inComponentRef;
	output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inArgMap,inComponentRef)
    local
      DAE.ComponentRef key,cref;
      DAE.Exp exp,e;
      list<tuple<DAE.ComponentRef, DAE.Exp>> cdr;
      list<DAE.Subscript> subs;
    case({},_)
      equation
        Debug.fprintln("failtrace","Inline.getExpFromArgMap failed");
      then
        fail();
    case((cref,exp) :: cdr,key)
      equation
        subs = Exp.crefSubs(key);
        key = Exp.crefStripSubs(key);
        true = Exp.crefEqual(cref,key);
        e = Exp.applyExpSubscripts(exp,subs);
      then
        e;
    case(_ :: cdr,key)
      equation
        exp = getExpFromArgMap(cdr,key);
      then
        exp;
  end matchcontinue;
end getExpFromArgMap;

protected function getInputCrefs
"function: getInputCrefs
	returns the crefs of vars that are inputs, wild if not input"
	input DAE.Element inElement;
	output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef := matchcontinue(inElement)
    local
      DAE.ComponentRef cref;
    case(DAE.VAR(componentRef=cref,direction=DAE.INPUT())) then cref;
    case(_) then DAE.WILD();
  end matchcontinue;
end getInputCrefs;

protected function removeWilds
"function: removeWilds
	returns false if the given cref is a wild"
	input DAE.ComponentRef inComponentRef;
	output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inComponentRef)
    case(DAE.WILD()) then false;
    case(_) then true;
  end matchcontinue;
end removeWilds;

end Inline;
