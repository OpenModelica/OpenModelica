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
public import BackendDAE;
public import ComponentReference;
public import DAE;
public import SCode;
public import Util;
public import Values;
public import Algorithm;

type Ident = String;
  
public type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;

protected import Debug;
protected import DAEUtil;
protected import Exp;

public function inlineCalls
"function: inlineCalls
	searches for calls where the inline flag is true, and inlines them"
	input Option<DAE.FunctionTree> inFTree "functions";
	input list<DAE.InlineType> inITLst;
	input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue(inFTree,inITLst,inDAELow)
    local
      Option<list<DAE.Element>> fns;
      Option<DAE.FunctionTree> ftree;
      list<DAE.InlineType> itlst;
      BackendDAE.Variables orderedVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects;
      BackendDAE.AliasVariables aliasVars "alias-variables' hashtable";
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      BackendDAE.MultiDimEquation[:] arrayEqs;
      list<BackendDAE.MultiDimEquation> mdelst;
      Algorithm.Algorithm[:] algorithms;
      list<Algorithm.Algorithm> alglst;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
    case(ftree,itlst,BackendDAE.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses))
      equation
        orderedVars = inlineVariables(orderedVars,(ftree,itlst));
        knownVars = inlineVariables(knownVars,(ftree,itlst));
        externalObjects = inlineVariables(externalObjects,(ftree,itlst));
        orderedEqs = inlineEquationArray(orderedEqs,(ftree,itlst));
        removedEqs = inlineEquationArray(removedEqs,(ftree,itlst));
        initialEqs = inlineEquationArray(initialEqs,(ftree,itlst));
        mdelst = Util.listMap1(arrayList(arrayEqs),inlineMultiDimEqs,(ftree,itlst));
        arrayEqs = listArray(mdelst);
        alglst = Util.listMap1(arrayList(algorithms),inlineAlgorithm,(ftree,itlst));
        algorithms = listArray(alglst);
        eventInfo = inlineEventInfo(eventInfo,(ftree,itlst));
        extObjClasses = inlineExtObjClasses(extObjClasses,(ftree,itlst));
      then
        BackendDAE.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses);
    case(_,_,_)
      equation
        Debug.fprintln("failtrace","Inline.inlineCalls failed");
      then
        fail();
  end matchcontinue;
end inlineCalls;

protected function inlineEquationArray "
function: inlineEquationArray
	inlines function calls in an equation array"
	input BackendDAE.EquationArray inEquationArray;
	input Functiontuple inElementList;
	output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := matchcontinue(inEquationArray,inElementList)
    local
      Functiontuple fns;
      Integer i1,i2;
      Option<BackendDAE.Equation>[:] eqarr,eqarr_1;
      list<Option<BackendDAE.Equation>> eqlst,eqlst_1;
    case(BackendDAE.EQUATION_ARRAY(i1,i2,eqarr),fns)
      equation
        eqlst = arrayList(eqarr);
        eqlst_1 = Util.listMap1(eqlst,inlineEqOpt,fns);
        eqarr_1 = listArray(eqlst_1);
      then
        BackendDAE.EQUATION_ARRAY(i1,i2,eqarr_1);
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
	input Option<BackendDAE.Equation> inEquationOption;
	input Functiontuple inElementList;
	output Option<BackendDAE.Equation> outEquationOption;
algorithm
  outEquationOption := matchcontinue(inEquationOption,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      Integer i;
      list<DAE.Exp> explst,explst_1,explst1,explst1_1,explst2,explst2_1;
      DAE.ComponentRef cref;
      BackendDAE.WhenEquation weq,weq_1;
      DAE.ElementSource source "the origin of the element";

    case(NONE(),_) then NONE();
    case(SOME(BackendDAE.EQUATION(e1,e2,source)),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        SOME(BackendDAE.EQUATION(e1_1,e2_1,source));

    case(SOME(BackendDAE.ARRAY_EQUATION(i,explst,source)),fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
      then
        SOME(BackendDAE.ARRAY_EQUATION(i,explst_1,source));

    case(SOME(BackendDAE.SOLVED_EQUATION(cref,e,source)),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        SOME(BackendDAE.SOLVED_EQUATION(cref,e_1,source));

    case(SOME(BackendDAE.RESIDUAL_EQUATION(e,source)),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        SOME(BackendDAE.RESIDUAL_EQUATION(e_1,source));

    case(SOME(BackendDAE.ALGORITHM(i,explst1,explst2,source)),fns)
      equation
        explst1_1 = Util.listMap1(explst1,inlineExp,fns);
        explst2_1 = Util.listMap1(explst2,inlineExp,fns);
      then
        SOME(BackendDAE.ALGORITHM(i,explst1_1,explst2_1,source));

    case(SOME(BackendDAE.WHEN_EQUATION(weq,source)),fns)
      equation
        weq_1 = inlineWhenEq(weq,fns);
      then
        SOME(BackendDAE.WHEN_EQUATION(weq_1,source));
  
    case(SOME(BackendDAE.COMPLEX_EQUATION(index=i,lhs=e1,rhs=e2,source=source)),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        SOME(BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source));        
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
	input BackendDAE.WhenEquation inWhenEquation;
	input Functiontuple inElementList;
	output BackendDAE.WhenEquation outWhenEquation;
algorithm
  outWhenEquation := matchcontinue(inWhenEquation,inElementList)
    local
      Functiontuple fns;
      Integer i;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      BackendDAE.WhenEquation weq,weq_1;
    case(BackendDAE.WHEN_EQ(i,cref,e,NONE()),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        BackendDAE.WHEN_EQ(i,cref,e_1,NONE());
    case(BackendDAE.WHEN_EQ(i,cref,e,SOME(weq)),fns)
      equation
        e_1 = inlineExp(e,fns);
        weq_1 = inlineWhenEq(weq,fns);
      then
        BackendDAE.WHEN_EQ(i,cref,e_1,SOME(weq_1));
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
	input BackendDAE.Variables inVariables;
	input Functiontuple inElementList;
	output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue(inVariables,inElementList)
    local
      Functiontuple fns;
      list<BackendDAE.CrefIndex>[:] crefind;
      list<BackendDAE.StringIndex>[:] strind;
      Integer i1,i2,i3,i4;
      Option<BackendDAE.Var>[:] vararr,vararr_1;
      list<Option<BackendDAE.Var>> varlst,varlst_1;
    case(BackendDAE.VARIABLES(crefind,strind,BackendDAE.VARIABLE_ARRAY(i3,i4,vararr),i1,i2),fns)
      equation
        varlst = arrayList(vararr);
        varlst_1 = Util.listMap1(varlst,inlineVarOpt,fns);
        vararr_1 = listArray(varlst_1);
      then
        BackendDAE.VARIABLES(crefind,strind,BackendDAE.VARIABLE_ARRAY(i3,i4,vararr_1),i1,i2);
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
	input Option<BackendDAE.Var> inVarOption;
	input Functiontuple inElementList;
	output Option<BackendDAE.Var> outVarOption;
algorithm
  outVarOption := matchcontinue(inVarOption,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef varName;
      BackendDAE.VarKind varKind;
      DAE.VarDirection varDirection;
      BackendDAE.Type varType;
      DAE.Exp e,e_1,startv,startv_1;
      Option<Values.Value> bindValue;
      DAE.InstDims arrayDim;
      Integer index;
      DAE.ComponentRef origVarName;
      list<Absyn.Path> className;
      Option<DAE.VariableAttributes> values,values1;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<BackendDAE.Var> var;
      DAE.ElementSource source "the origin of the element";

    case(NONE(),_) then NONE();
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,SOME(e),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        e_1 = inlineExp(e,fns);
        startv = DAEUtil.getStartAttrFail(values);
        startv_1 = inlineExp(startv,fns);
        values1 = DAEUtil.setStartAttr(values,startv_1);
      then
        SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,SOME(e_1),bindValue,arrayDim,index,source,values1,comment,flowPrefix,streamPrefix));
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,NONE(),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        startv = DAEUtil.getStartAttrFail(values);
        startv_1 = inlineExp(startv,fns);
        values1 = DAEUtil.setStartAttr(values,startv_1);
      then
        SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,NONE(),bindValue,arrayDim,index,source,values1,comment,flowPrefix,streamPrefix));        
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,SOME(e),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        SOME(BackendDAE.VAR(varName,varKind,varDirection,varType,SOME(e_1),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix));
    case(var,_) then var;
  end matchcontinue;
end inlineVarOpt;

public function inlineMultiDimEqs
"function: inlineMultiDimEqs
	inlines function calls in multi dim equations"
	input BackendDAE.MultiDimEquation inMultiDimEquation;
	input Functiontuple inElementList;
	output BackendDAE.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue(inMultiDimEquation,inElementList)
    local
      Functiontuple fns;
      list<Integer> ilst;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source;

    case(BackendDAE.MULTIDIM_EQUATION(ilst,e1,e2,source),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        BackendDAE.MULTIDIM_EQUATION(ilst,e1_1,e2_1,source);
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
	input BackendDAE.EventInfo inEventInfo;
	input Functiontuple inElementList;
	output BackendDAE.EventInfo outEventInfo;
algorithm
  outEventInfo := matchcontinue(inEventInfo,inElementList)
    local
      Functiontuple fns;
      list<BackendDAE.WhenClause> wclst,wclst_1;
      list<BackendDAE.ZeroCrossing> zclst,zclst_1;
    case(BackendDAE.EVENT_INFO(wclst,zclst),fns)
      equation
        wclst_1 = Util.listMap1(wclst,inlineWhenClause,fns);
        zclst_1 = Util.listMap1(zclst,inlineZeroCrossing,fns);
      then
        BackendDAE.EVENT_INFO(wclst_1,zclst_1);
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
	input BackendDAE.ZeroCrossing inZeroCrossing;
	input Functiontuple inElementList;
	output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := matchcontinue(inZeroCrossing,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1;
      list<Integer> ilst1,ilst2;
    case(BackendDAE.ZERO_CROSSING(e,ilst1,ilst2),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        BackendDAE.ZERO_CROSSING(e_1,ilst1,ilst2);
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
	input BackendDAE.WhenClause inWhenClause;
	input Functiontuple inElementList;
	output BackendDAE.WhenClause outWhenClause;
algorithm
  outWhenClause := matchcontinue(inWhenClause,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1;
      list<BackendDAE.ReinitStatement> rslst,rslst_1;
      Option<Integer> io;

    case(BackendDAE.WHEN_CLAUSE(e,rslst,io),fns)
      equation
        e_1 = inlineExp(e,fns);
        rslst_1 = Util.listMap1(rslst,inlineReinitStmt,fns);
      then
        BackendDAE.WHEN_CLAUSE(e_1,rslst_1,io);
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
	input BackendDAE.ReinitStatement inReinitStatement;
	input Functiontuple inElementList;
	output BackendDAE.ReinitStatement outReinitStatement;
algorithm
  outReinitStatement := matchcontinue(inReinitStatement,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      BackendDAE.ReinitStatement rs;
      DAE.ElementSource source "the origin of the element";

    case(BackendDAE.REINIT(cref,e,source),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        BackendDAE.REINIT(cref,e_1,source);
    case(rs,_) then rs;
  end matchcontinue;
end inlineReinitStmt;

public function inlineExtObjClasses
"function: inlineExtObjClasses
	inlines function calls in external object classes"
	input BackendDAE.ExternalObjectClasses inExtObjClasses;
	input Functiontuple inElementList;
	output BackendDAE.ExternalObjectClasses outExtObjClasses;
algorithm
  outExtObjClasses := matchcontinue(inExtObjClasses,inElementList)
    local
      Functiontuple fns;
      BackendDAE.ExternalObjectClasses cdr,cdr_1;
      BackendDAE.ExternalObjectClass res;
      Absyn.Path p;
      DAE.Function f1,f2;
      DAE.ElementSource source "the origin of the element";

    case({},_) then {};
    case(BackendDAE.EXTOBJCLASS(p,f1,f2,source) :: cdr,fns)
      equation
        {f1,f2} = inlineCallsInFunctions({f1,f2},fns);
        res = BackendDAE.EXTOBJCLASS(p,f1,f2,source);
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

public function inlineCallsInFunctions
"function: inlineDAEElements
	inlines calls in DAEElements"
	input list<DAE.Function> inElementList;
	input Functiontuple inFunctions;
	output list<DAE.Function> outElementList;
algorithm
  outElementList := matchcontinue(inElementList,inFunctions)
    local
      Functiontuple fns;
      list<DAE.Function> cdr,cdr_1;
      list<DAE.Element> elist,elist_1;
      list<list<DAE.Element>> dlist,dlist_1;
      DAE.Function el,res;
      DAE.Type ty,t;
      Boolean partialPrefix;
      list<Absyn.Path> pathLst;
      Absyn.InnerOuter innerOuter;
      Ident i;
      Absyn.Path p;
      DAE.ExternalDecl ext;
      list<DAE.Exp> explst,explst_1;
      DAE.InlineType inlineType;
      list<DAE.FunctionDefinition> funcDefs;
      DAE.ElementSource source "the origin of the element";

    case({},_) then {};
    
    case(DAE.FUNCTION(p,DAE.FUNCTION_DEF(body = elist)::funcDefs,t,partialPrefix,inlineType,source) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.FUNCTION(p,DAE.FUNCTION_DEF(elist_1)::funcDefs,t,partialPrefix,inlineType,source);
        cdr_1 = inlineCallsInFunctions(cdr,fns);
      then
         res :: cdr_1;
    // external functions
    case(DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist,ext)::funcDefs,t,partialPrefix,inlineType,source) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist_1,ext)::funcDefs,t,partialPrefix,inlineType,source);
        cdr_1 = inlineCallsInFunctions(cdr,fns);
      then
        res :: cdr_1;

    case(el :: cdr,fns)
      equation
        cdr_1 = inlineCallsInFunctions(cdr,fns);
      then
        el :: cdr_1;
  end matchcontinue;
end inlineCallsInFunctions;

protected function inlineDAEElements
"function: inlineDAEElements
	inlines calls in DAEElements"
	input list<DAE.Element> inElementList;
	input Functiontuple inFunctions;
	output list<DAE.Element> outElementList;
algorithm
  outElementList := matchcontinue(inElementList,inFunctions)
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
      DAE.Function f1,f2;

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

    case(DAE.WHEN_EQUATION(exp,elist,NONE(),source) :: cdr,fns)
      equation
        exp_1 = inlineExp(exp,fns);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.WHEN_EQUATION(exp_1,elist_1,NONE(),source);
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

    case(DAE.COMP(i,elist,source,absynCommentOption) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.COMP(i,elist_1,source,absynCommentOption);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.EXTOBJECTCLASS(p,f1,f2,source) :: cdr,fns)
      equation
        {f1,f2} = inlineCallsInFunctions({f1,f2},fns);
        res = DAE.EXTOBJECTCLASS(p,f1,f2,source);
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
      list<DAE.Exp> explst,explst_1,inputExps;
      DAE.ComponentRef cref;
      Algorithm.Else a_else,a_else_1;
      list<Algorithm.Statement> stmts,stmts_1;
      Boolean b;
      Ident i;
      list<Integer> ilst;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
    case(DAE.STMT_ASSIGN(t,e1,e2,source),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAE.STMT_ASSIGN(t,e1_1,e2_1,source);
    case(DAE.STMT_TUPLE_ASSIGN(t,explst,e,source),fns)
      equation
        explst_1 = Util.listMap1(explst,inlineExp,fns);
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_TUPLE_ASSIGN(t,explst_1,e_1,source);
    case(DAE.STMT_ASSIGN_ARR(t,cref,e,source),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_ASSIGN_ARR(t,cref,e_1,source);
    case(DAE.STMT_IF(e,stmts,a_else,source),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
        a_else_1 = inlineElse(a_else,fns);
      then
        DAE.STMT_IF(e_1,stmts_1,a_else_1,source);
    case(DAE.STMT_FOR(t,b,i,e,stmts,source),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_FOR(t,b,i,e_1,stmts_1,source);
    case(DAE.STMT_WHILE(e,stmts,source),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_WHILE(e_1,stmts_1,source);
    case(DAE.STMT_WHEN(e,stmts,SOME(stmt),ilst,source),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
        stmt_1 = inlineStatement(stmt,fns);
      then
        DAE.STMT_WHEN(e_1,stmts_1,SOME(stmt_1),ilst,source);
    case(DAE.STMT_WHEN(e,stmts,NONE(),ilst,source),fns)
      equation
        e_1 = inlineExp(e,fns);
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_WHEN(e_1,stmts_1,NONE(),ilst,source);
    case(DAE.STMT_ASSERT(e1,e2,source),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAE.STMT_ASSERT(e1_1,e2_1,source);
    case(DAE.STMT_TERMINATE(e,source),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_TERMINATE(e_1,source);
    case(DAE.STMT_REINIT(e1,e2,source),fns)
      equation
        e1_1 = inlineExp(e1,fns);
        e2_1 = inlineExp(e2,fns);
      then
        DAE.STMT_REINIT(e1_1,e2_1,source);
    case(DAE.STMT_NORETCALL(e,source),fns)
      equation
        e_1 = inlineExp(e,fns);
      then
        DAE.STMT_NORETCALL(e_1,source);
    case(DAE.STMT_FAILURE(stmts,source),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_FAILURE(stmts_1,source);
    case(DAE.STMT_TRY(stmts,source),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_TRY(stmts_1,source);
    case(DAE.STMT_CATCH(stmts,source),fns)
      equation
        stmts_1 = Util.listMap1(stmts,inlineStatement,fns);
      then
        DAE.STMT_CATCH(stmts_1,source);
    case(DAE.STMT_MATCHCASES(matchType,inputExps,explst,source),fns)
      equation
        inputExps = Util.listMap1(inputExps,inlineExp,fns);
        explst_1 = Util.listMap1(explst,inlineExp,fns);
      then
        DAE.STMT_MATCHCASES(matchType,inputExps,explst_1,source);
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
      DAE.Exp e,e_1,e_2;
    case(e,fns)
      equation
        ((e_1,fns)) = Exp.traverseExp(e,inlineCall,fns);
        e_2 = Exp.simplify(e_1);
      then
        e_2;
    case(e,_) then e;
  end matchcontinue;
end inlineExp;

protected function inlineCall
"function: inlineCall
	replaces an inline call with the expression from the function"
	input tuple<DAE.Exp, Functiontuple> inTuple;
	output tuple<DAE.Exp, Functiontuple> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
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
    case (it,(_,itlst))
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
      list<DAE.Exp> expl;
      list<Option<Integer>> ad;
      list<DAE.ComponentRef> crlst;
      list<list<tuple<DAE.Exp, Boolean>>> scalar;
      list<tuple<DAE.Exp, Boolean>> flatscalar;
      list<list<DAE.Subscript>> subslst,subslst1;      
    case ({}) then {}; 
    case((c,e as (DAE.CREF(componentRef = cref,ty=DAE.ET_COMPLEX(varLst=varLst))))::res)
      equation
        res1 = extendCrefRecords(res);  
        new = Util.listMap2(varLst,extendCrefRecords1,c,cref);
        new1 = extendCrefRecords(new);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2);  
    case((c,e as (DAE.CALL(expLst = expl,ty=DAE.ET_COMPLEX(varLst=varLst))))::res)
      equation
        res1 = extendCrefRecords(res);  
        crlst = Util.listMap1(varLst,extendCrefRecords2,c);
        new = Util.listThreadTuple(crlst,expl);
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
      DAE.ExpType tp;
      String name;
      DAE.ComponentRef c1,e1;
    case(DAE.COMPLEX_VAR(name=name,tp=tp),c,e) 
      equation
        c1 = ComponentReference.crefPrependIdent(c,name,{},tp);  
        e1 = ComponentReference.crefPrependIdent(e,name,{},tp);  
      then ((c1,DAE.CREF(e1,tp))); 
    case(_,_,_)
      equation
        Debug.fprintln("failtrace","Inline.extendCrefRecords1 failed");
      then
        fail();                   
  end matchcontinue;
end extendCrefRecords1;

protected function extendCrefRecords2
"function: extendCrefRecords1
	helper for extendCrefRecords"
	input DAE.ExpVar ev;
	input DAE.ComponentRef c;
	output DAE.ComponentRef outArg;
algorithm
  outArg := matchcontinue(ev,c)
    local
      list<DAE.ExpVar> varLst;
      DAE.ExpType tp;
      String name;
      DAE.ComponentRef c1;
    case(DAE.COMPLEX_VAR(name=name,tp=tp),c) 
      equation
        c1 = ComponentReference.crefPrependIdent(c,name,{},tp);  
      then c1; 
    case(_,_)
      equation
        Debug.fprintln("failtrace","Inline.extendCrefRecords2 failed");
      then
        fail();                   
  end matchcontinue;
end extendCrefRecords2;

protected function getFunctionBody
"function: getFunctionBody
	returns the body of a function"
	input Absyn.Path p;
	input Functiontuple fns;
	output list<DAE.Element> outfn;
algorithm
  outfn := matchcontinue(p,fns)
    local
      list<DAE.Function> flst;
      list<DAE.Element> body;
      DAE.FunctionTree ftree;
    case(p,(SOME(ftree),_))
      equation
        SOME(DAE.FUNCTION( functions = DAE.FUNCTION_DEF(body = body)::_)) = DAEUtil.avlTreeGet(ftree,p); 
      then body;
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
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN(exp=res)})) :: _) then res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(exp=res)})):: _) then res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN_ARR(exp=res)})) :: _) then res;
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
        subs = ComponentReference.crefSubs(key);
        key = ComponentReference.crefStripSubs(key);
        true = ComponentReference.crefEqual(cref,key);
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
