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
encapsulated package Inline
" file:        Inline.mo
  package:     Inline
  description: inline functions

  RCS: $Id$

  This module contains data structures and functions for inline functions.

  The entry point is the inlineCalls function, or inlineCallsInFunctions
  "

public import Absyn;
public import Algorithm;
public import BackendDAE;
public import BaseHashTable;
public import DAE;
public import HashTableCG;
public import SCode;
public import Util;
public import Values;

type Ident = String;
  
public type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;

protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import List;
protected import Types;


public function inlineCalls
"function: inlineCalls
  searches for calls where the inline flag is true, and inlines them"
  input list<DAE.InlineType> inITLst;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := matchcontinue(inITLst,inBackendDAE)
    local
      list<DAE.InlineType> itlst;
      BackendDAE.Variables orderedVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects;
      BackendDAE.AliasVariables aliasVars "alias-variables' hashtable";
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      list<BackendDAE.MultiDimEquation> mdelst;
      array<Algorithm.Algorithm> algorithms;
      list<Algorithm.Algorithm> alglst;
      array<DAE.Constraint> constrs;
      array<BackendDAE.ComplexEquation> ce,ce1;
      list<BackendDAE.ComplexEquation> celst;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      Functiontuple tpl;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.SymbolicJacobians symjacs;
      DAE.FunctionTree functionTree;
    case (itlst,BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,removedEqs=removedEqs,arrayEqs=arrayEqs,algorithms=algorithms,complEqs=ce,constraints=constrs,functionTree=functionTree,eventInfo=eventInfo,extObjClasses=extObjClasses,backendDAEType=btp,symjacs=symjacs)))
      equation
        tpl = (SOME(functionTree),itlst);
        eqs = List.map1(eqs,inlineEquationSystem,tpl);
        knownVars = inlineVariables(knownVars,tpl);
        externalObjects = inlineVariables(externalObjects,tpl);
        initialEqs = inlineEquationArray(initialEqs,tpl);
        removedEqs = inlineEquationArray(removedEqs,tpl);
        mdelst = List.map1(arrayList(arrayEqs),inlineMultiDimEqs,tpl);
        arrayEqs = listArray(mdelst);
        alglst = List.map1(arrayList(algorithms),inlineAlgorithm,tpl);
        algorithms = listArray(alglst);
        celst = List.map1(arrayList(ce),inlineComplexEqs,tpl);
        ce1 = listArray(celst);
        eventInfo = inlineEventInfo(eventInfo,tpl);
      then  
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,arrayEqs,algorithms,constrs,ce1,functionTree,eventInfo,extObjClasses,btp,symjacs));
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineCalls failed");
      then
        fail();
  end matchcontinue;
end inlineCalls;

protected function inlineEquationSystem
  input BackendDAE.EqSystem eqs;
  input Functiontuple tpl;
  output BackendDAE.EqSystem oeqs;
algorithm
  oeqs := match (eqs,tpl)
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EquationArray initialEqs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),tpl)
      equation
        orderedVars = inlineVariables(orderedVars,tpl);
        orderedEqs = inlineEquationArray(orderedEqs,tpl);
        // TODO: Incidencematrix may change, but it's not updated here?! 
      then BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching);
  end match;
end inlineEquationSystem;

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
      array<Option<BackendDAE.Equation>> eqarr,eqarr_1;
      list<Option<BackendDAE.Equation>> eqlst,eqlst_1;
    case(BackendDAE.EQUATION_ARRAY(i1,i2,eqarr),fns)
      equation
        eqlst = arrayList(eqarr);
        eqlst_1 = List.map1(eqlst,inlineEqOpt,fns);
        eqarr_1 = listArray(eqlst_1);
      then
        BackendDAE.EQUATION_ARRAY(i1,i2,eqarr_1);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineEquationArray failed");
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
        (e1_1,source) = inlineExp(e1,fns,source);
        (e2_1,source) = inlineExp(e2,fns,source);
      then
        SOME(BackendDAE.EQUATION(e1_1,e2_1,source));

    case(SOME(BackendDAE.ARRAY_EQUATION(i,explst,source)),fns)
      equation
        (explst_1,source) = inlineExps(explst,fns,source);
      then
        SOME(BackendDAE.ARRAY_EQUATION(i,explst_1,source));

    case(SOME(BackendDAE.SOLVED_EQUATION(cref,e,source)),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        SOME(BackendDAE.SOLVED_EQUATION(cref,e_1,source));

    case(SOME(BackendDAE.RESIDUAL_EQUATION(e,source)),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        SOME(BackendDAE.RESIDUAL_EQUATION(e_1,source));

    case(SOME(BackendDAE.ALGORITHM(i,explst1,explst2,source)),fns)
      equation
        (explst1_1,source) = inlineExps(explst1,fns,source);
        (explst2_1,source) = inlineExps(explst2,fns,source);
      then
        SOME(BackendDAE.ALGORITHM(i,explst1_1,explst2_1,source));

    case(SOME(BackendDAE.WHEN_EQUATION(weq,source)),fns)
      equation
        (weq_1,source) = inlineWhenEq(weq,fns,source);
      then
        SOME(BackendDAE.WHEN_EQUATION(weq_1,source));
  
    case(SOME(BackendDAE.COMPLEX_EQUATION(index=i,crefOrDerCref=explst,source=source)),fns)
      equation
        (explst_1,source) = inlineExps(explst,fns,source);
      then
        SOME(BackendDAE.COMPLEX_EQUATION(i,explst_1,source));
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineEqOpt failed");
      then
        fail();
  end matchcontinue;
end inlineEqOpt;

protected function inlineWhenEq
"function: inlineWhenEq
  inlines function calls in when equations"
  input BackendDAE.WhenEquation inWhenEquation;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output BackendDAE.WhenEquation outWhenEquation;
  output DAE.ElementSource outSource;
algorithm
  (outWhenEquation,outSource) := matchcontinue(inWhenEquation,inElementList,inSource)
    local
      Functiontuple fns;
      Integer i;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      BackendDAE.WhenEquation weq,weq_1;
      DAE.ElementSource source;
      
    case (BackendDAE.WHEN_EQ(i,cref,e,NONE()),fns,source)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        (BackendDAE.WHEN_EQ(i,cref,e_1,NONE()),source);
    case (BackendDAE.WHEN_EQ(i,cref,e,SOME(weq)),fns,source)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        (weq_1,source) = inlineWhenEq(weq,fns,source);
      then
        (BackendDAE.WHEN_EQ(i,cref,e_1,SOME(weq_1)),source);
    else
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineWhenEq failed");
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
      array<list<BackendDAE.CrefIndex>> crefind;
      Integer i1,i2,i3,i4;
      array<Option<BackendDAE.Var>> vararr,vararr_1;
      list<Option<BackendDAE.Var>> varlst,varlst_1;
    case(BackendDAE.VARIABLES(crefind,BackendDAE.VARIABLE_ARRAY(i3,i4,vararr),i1,i2),fns)
      equation
        varlst = arrayList(vararr);
        varlst_1 = List.map1(varlst,inlineVarOpt,fns);
        vararr_1 = listArray(varlst_1);
      then
        BackendDAE.VARIABLES(crefind,BackendDAE.VARIABLE_ARRAY(i3,i4,vararr_1),i1,i2);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineVariables failed");
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
      DAE.VarParallelism varParallelism;
      BackendDAE.Type varType;
      DAE.Exp e,e_1,startv,startv_1;
      Option<Values.Value> bindValue;
      DAE.InstDims arrayDim;
      Integer index;
      Option<DAE.VariableAttributes> values,values1;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<BackendDAE.Var> var;
      DAE.ElementSource source "the origin of the element";

    case(NONE(),_) then NONE();
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,SOME(e),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        startv = DAEUtil.getStartAttrFail(values);
        (startv_1,source) = inlineExp(startv,fns,source);
        values1 = DAEUtil.setStartAttr(values,startv_1);
      then
        SOME(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,SOME(e_1),bindValue,arrayDim,index,source,values1,comment,flowPrefix,streamPrefix));
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,NONE(),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        startv = DAEUtil.getStartAttrFail(values);
        (startv_1,source) = inlineExp(startv,fns,source);
        values1 = DAEUtil.setStartAttr(values,startv_1);
      then
        SOME(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,NONE(),bindValue,arrayDim,index,source,values1,comment,flowPrefix,streamPrefix));
    case(SOME(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,SOME(e),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix)),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        SOME(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,SOME(e_1),bindValue,arrayDim,index,source,values,comment,flowPrefix,streamPrefix));
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
        (e1_1,source) = inlineExp(e1,fns,source);
        (e2_1,source) = inlineExp(e2,fns,source);
      then
        BackendDAE.MULTIDIM_EQUATION(ilst,e1_1,e2_1,source);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineMultiDimEqs failed");
      then
        fail();
  end matchcontinue;
end inlineMultiDimEqs;

public function inlineComplexEqs
"function: inlineComplexEqs
  inlines function calls in complex equations"
  input BackendDAE.ComplexEquation inComplexEquation;
  input Functiontuple inElementList;
  output BackendDAE.ComplexEquation outComplexEquation;
algorithm
  outComplexEquation := matchcontinue(inComplexEquation,inElementList)
    local
      Functiontuple fns;
      Integer i;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source;

    case(BackendDAE.COMPLEXEQUATION(i,e1,e2,source),fns)
      equation
        (e1_1,source) = inlineExp(e1,fns,source);
        (e2_1,source) = inlineExp(e2,fns,source);
      then
        BackendDAE.COMPLEXEQUATION(i,e1_1,e2_1,source);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineComplexEqs failed");
      then
        fail();
  end matchcontinue;
end inlineComplexEqs;

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
        wclst_1 = List.map1(wclst,inlineWhenClause,fns);
        zclst_1 = List.map1(zclst,inlineZeroCrossing,fns);
      then
        BackendDAE.EVENT_INFO(wclst_1,zclst_1);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineEventInfo failed");
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
        (e_1,_) = inlineExp(e,fns,DAE.emptyElementSource/*TODO: Propagate operation info*/);
      then
        BackendDAE.ZERO_CROSSING(e_1,ilst1,ilst2);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineZeroCrossing failed");
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
      list<BackendDAE.WhenOperator> rslst,rslst_1;
      Option<Integer> io;

    case(BackendDAE.WHEN_CLAUSE(e,rslst,io),fns)
      equation
        (e_1,_) = inlineExp(e,fns,DAE.emptyElementSource/*TODO: Propagate operation info*/);
        rslst_1 = List.map1(rslst,inlineReinitStmt,fns);
      then
        BackendDAE.WHEN_CLAUSE(e_1,rslst_1,io);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineWhenClause failed");
      then
        fail();
  end matchcontinue;
end inlineWhenClause;

protected function inlineReinitStmt
"function: inlineReinitStmt
  inlines function calls in a reinit statement"
  input BackendDAE.WhenOperator inReinitStatement;
  input Functiontuple inElementList;
  output BackendDAE.WhenOperator outReinitStatement;
algorithm
  outReinitStatement := matchcontinue(inReinitStatement,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      BackendDAE.WhenOperator rs;
      DAE.ElementSource source "the origin of the element";

    case (BackendDAE.REINIT(cref,e,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        BackendDAE.REINIT(cref,e_1,source);
    case (rs,_) then rs;
  end matchcontinue;
end inlineReinitStmt;

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
      DAE.Function el,res;
      DAE.Type t;
      Boolean partialPrefix;
      Absyn.Path p;
      DAE.ExternalDecl ext;
      DAE.InlineType inlineType;
      list<DAE.FunctionDefinition> funcDefs;
      DAE.ElementSource source "the origin of the element";
      Option<SCode.Comment> cmt;

    case({},_) then {};
    
    case(DAE.FUNCTION(p,DAE.FUNCTION_DEF(body = elist)::funcDefs,t,partialPrefix,inlineType,source,cmt) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.FUNCTION(p,DAE.FUNCTION_DEF(elist_1)::funcDefs,t,partialPrefix,inlineType,source,cmt);
        cdr_1 = inlineCallsInFunctions(cdr,fns);
      then
         res :: cdr_1;
    // external functions
    case(DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist,ext)::funcDefs,t,partialPrefix,inlineType,source,cmt) :: cdr,fns)
      equation
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist_1,ext)::funcDefs,t,partialPrefix,inlineType,source,cmt);
        cdr_1 = inlineCallsInFunctions(cdr,fns);
      then
        res :: cdr_1;

    case(el :: cdr,fns)
      equation
        cdr_1 = inlineCallsInFunctions(cdr,fns);
      then
        el :: cdr_1;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Inline.inlineCallsInFunctions failed"});
      then fail();
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
      DAE.Element el,el_1,res;
      DAE.ComponentRef componentRef;
      DAE.VarKind kind;
      DAE.VarDirection direction;
      DAE.VarParallelism parallelism;
      DAE.VarVisibility protection;
      DAE.Type ty;
      DAE.Exp binding,binding_1,exp,exp_1,exp1,exp1_1,exp2,exp2_1;
      DAE.InstDims dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      DAE.Dimensions dimension;
      Algorithm.Algorithm alg,alg_1;
      Ident i;
      Absyn.Path p;
      list<DAE.Exp> explst,explst_1;
      DAE.ElementSource source "the origin of the element";
      DAE.Function f1,f2;      

    case ({},_) then {};
    case (DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(binding),dims,flowPrefix,streamPrefix,
                 source,variableAttributesOption,absynCommentOption,innerOuter) :: cdr,fns)
      equation
        (binding_1,source) = inlineExp(binding,fns,source);
        res = DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(binding_1),dims,flowPrefix,streamPrefix,
                      source,variableAttributesOption,absynCommentOption,innerOuter);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case (DAE.DEFINE(componentRef,exp,source) :: cdr,fns)
      equation
        (exp_1,source) = inlineExp(exp,fns,source);
        res = DAE.DEFINE(componentRef,exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIALDEFINE(componentRef,exp,source) :: cdr,fns)
      equation
        (exp_1,source) = inlineExp(exp,fns,source);
        res = DAE.INITIALDEFINE(componentRef,exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.EQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
        res = DAE.EQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.ARRAY_EQUATION(dimension,exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
        res = DAE.ARRAY_EQUATION(dimension,exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIAL_ARRAY_EQUATION(dimension,exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
        res = DAE.INITIAL_ARRAY_EQUATION(dimension,exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.COMPLEX_EQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
        res = DAE.COMPLEX_EQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIAL_COMPLEX_EQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
        res = DAE.INITIAL_COMPLEX_EQUATION(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.WHEN_EQUATION(exp,elist,SOME(el),source) :: cdr,fns)
      equation
        (exp_1,source) = inlineExp(exp,fns,source);
        elist_1 = inlineDAEElements(elist,fns);
        {el_1} = inlineDAEElements({el},fns);
        res = DAE.WHEN_EQUATION(exp_1,elist_1,SOME(el_1),source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.WHEN_EQUATION(exp,elist,NONE(),source) :: cdr,fns)
      equation
        (exp_1,source) = inlineExp(exp,fns,source);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.WHEN_EQUATION(exp_1,elist_1,NONE(),source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.IF_EQUATION(explst,dlist,elist,source) :: cdr,fns)
      equation
        (explst_1,source) = inlineExps(explst,fns,source);
        dlist_1 = List.map1(dlist,inlineDAEElements,fns);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.IF_EQUATION(explst_1,dlist_1,elist_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIAL_IF_EQUATION(explst,dlist,elist,source) :: cdr,fns)
      equation
        (explst_1,source) = inlineExps(explst,fns,source);
        dlist_1 = List.map1(dlist,inlineDAEElements,fns);
        elist_1 = inlineDAEElements(elist,fns);
        res = DAE.INITIAL_IF_EQUATION(explst_1,dlist_1,elist_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.INITIALEQUATION(exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
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

    case(DAE.ASSERT(exp1,exp2,source) :: cdr,fns)
      equation
        (exp1_1,source) = inlineExp(exp1,fns,source);
        (exp2_1,source) = inlineExp(exp2,fns,source);
        res = DAE.ASSERT(exp1_1,exp2_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.TERMINATE(exp,source) :: cdr,fns)
      equation
        (exp_1,source) = inlineExp(exp,fns,source);
        res = DAE.TERMINATE(exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.REINIT(componentRef,exp,source) :: cdr,fns)
      equation
        (exp_1,source) = inlineExp(exp,fns,source);
        res = DAE.REINIT(componentRef,exp_1,source);
        cdr_1 = inlineDAEElements(cdr,fns);
      then
        res :: cdr_1;

    case(DAE.NORETCALL(p,explst,source) :: cdr,fns)
      equation
        (explst_1,source) = inlineExps(explst,fns,source);
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
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.ALGORITHM_STMTS(stmts_1);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineAlgorithm failed");
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
      DAE.Type t;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      list<DAE.Exp> explst,explst_1;
      DAE.ComponentRef cref;
      Algorithm.Else a_else,a_else_1;
      list<Algorithm.Statement> stmts,stmts_1;
      Boolean b;
      Ident i;
      list<Integer> ilst;
      DAE.ElementSource source;
    case (DAE.STMT_ASSIGN(t,e1,e2,source),fns)
      equation
        (e1_1,source) = inlineExp(e1,fns,source);
        (e2_1,source) = inlineExp(e2,fns,source);
      then
        DAE.STMT_ASSIGN(t,e1_1,e2_1,source);
    case(DAE.STMT_TUPLE_ASSIGN(t,explst,e,source),fns)
      equation
        (explst_1,source) = inlineExps(explst,fns,source);
        (e_1,source) = inlineExp(e,fns,source);
      then
        DAE.STMT_TUPLE_ASSIGN(t,explst_1,e_1,source);
    case(DAE.STMT_ASSIGN_ARR(t,cref,e,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        DAE.STMT_ASSIGN_ARR(t,cref,e_1,source);
    case(DAE.STMT_IF(e,stmts,a_else,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        stmts_1 = List.map1(stmts,inlineStatement,fns);
        (a_else_1,source) = inlineElse(a_else,fns,source);
      then
        DAE.STMT_IF(e_1,stmts_1,a_else_1,source);
    case(DAE.STMT_FOR(t,b,i,e,stmts,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.STMT_FOR(t,b,i,e_1,stmts_1,source);
    case(DAE.STMT_WHILE(e,stmts,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.STMT_WHILE(e_1,stmts_1,source);
    case(DAE.STMT_WHEN(e,stmts,SOME(stmt),ilst,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        stmts_1 = List.map1(stmts,inlineStatement,fns);
        stmt_1 = inlineStatement(stmt,fns);
      then
        DAE.STMT_WHEN(e_1,stmts_1,SOME(stmt_1),ilst,source);
    case(DAE.STMT_WHEN(e,stmts,NONE(),ilst,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.STMT_WHEN(e_1,stmts_1,NONE(),ilst,source);
    case(DAE.STMT_ASSERT(e1,e2,source),fns)
      equation
        (e1_1,source) = inlineExp(e1,fns,source);
        (e2_1,source) = inlineExp(e2,fns,source);
      then
        DAE.STMT_ASSERT(e1_1,e2_1,source);
    case(DAE.STMT_TERMINATE(e,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        DAE.STMT_TERMINATE(e_1,source);
    case(DAE.STMT_REINIT(e1,e2,source),fns)
      equation
        (e1_1,source) = inlineExp(e1,fns,source);
        (e2_1,source) = inlineExp(e2,fns,source);
      then
        DAE.STMT_REINIT(e1_1,e2_1,source);
    case(DAE.STMT_NORETCALL(e,source),fns)
      equation
        (e_1,source) = inlineExp(e,fns,source);
      then
        DAE.STMT_NORETCALL(e_1,source);
    case(DAE.STMT_FAILURE(stmts,source),fns)
      equation
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.STMT_FAILURE(stmts_1,source);
    case(DAE.STMT_TRY(stmts,source),fns)
      equation
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.STMT_TRY(stmts_1,source);
    case(DAE.STMT_CATCH(stmts,source),fns)
      equation
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        DAE.STMT_CATCH(stmts_1,source);
    case(stmt,_) then stmt;
  end matchcontinue;
end inlineStatement;

protected function inlineElse
"function: inlineElse
  inlines calls in an Algorithm.Else"
  input Algorithm.Else inElse;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output Algorithm.Else outElse;
  output DAE.ElementSource outSource;
algorithm
  (outElse,outSource) := matchcontinue(inElse,inElementList,inSource)
    local
      Functiontuple fns;
      Algorithm.Else a_else,a_else_1;
      DAE.Exp e,e_1;
      list<Algorithm.Statement> stmts,stmts_1;
      DAE.ElementSource source;
      
    case (DAE.ELSEIF(e,stmts,a_else),fns,source)
      equation
        (e_1,source) = inlineExp(e,fns,source);
        stmts_1 = List.map1(stmts,inlineStatement,fns);
        (a_else_1,source) = inlineElse(a_else,fns,source);
      then
        (DAE.ELSEIF(e_1,stmts_1,a_else_1),source);
    case (DAE.ELSE(stmts),fns,source)
      equation
        stmts_1 = List.map1(stmts,inlineStatement,fns);
      then
        (DAE.ELSE(stmts_1),source);
    case (a_else,fns,source) then (a_else,source);
  end matchcontinue;
end inlineElse;

public function inlineExp "
function: inlineExp
  inlines calls in an DAE.Exp"
  input DAE.Exp inExp;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Exp outExp;
  output DAE.ElementSource outSource;
algorithm
  (outExp,outSource) := matchcontinue (inExp,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e_2;
      Boolean b;
      DAE.ElementSource source;
      
    case (e,fns,source)
      equation
        ((e_1,(fns,b))) = Expression.traverseExp(e,inlineCall,(fns,false));
        source = DAEUtil.condAddSymbolicTransformation(b,source,DAE.OP_INLINE(e,e_1));
        (e_2,b) = ExpressionSimplify.simplify(e_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b,source,e_1,e_2);
      then
        (e_2,source);
    else (inExp,inSource);
  end matchcontinue;
end inlineExp;

public function forceInlineExp "
function: inlineExp
  inlines calls in an DAE.Exp"
  input DAE.Exp inExp;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Exp outExp;
  output DAE.ElementSource outSource;
  output Boolean inlineperformed;
algorithm
  (outExp,outSource,inlineperformed) := matchcontinue (inExp,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e_2;
      Boolean b,b1;
      DAE.ElementSource source;
      
    case (e,fns,source)
      equation
        ((e_1,(fns,b))) = Expression.traverseExp(e,forceInlineCall,(fns,false));
        source = DAEUtil.condAddSymbolicTransformation(b,source,DAE.OP_INLINE(e,e_1));
        (e_2,b1) = ExpressionSimplify.simplify(e_1);
        source = DAEUtil.addSymbolicTransformationSimplify(b1,source,e_1,e_2);
      then
        (e_2,source,b);
    else (inExp,inSource,false);
  end matchcontinue;
end forceInlineExp;

protected function inlineExps "
function: inlineExp
  inlines calls in an DAE.Exp"
  input list<DAE.Exp> inExps;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output list<DAE.Exp> outExps;
  output DAE.ElementSource outSource;
algorithm
  (outExps,outSource) := match (inExps,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e_2;
      list<DAE.Exp> exps;
      DAE.ElementSource source;
      
    case ({},_,source) then ({},source);
    case (e::exps,fns,source)
      equation
        (e,source) = inlineExp(e,fns,source);
        (exps,source) = inlineExps(exps,fns,source);
      then
        (e::exps,source);
  end match;
end inlineExps;

public function checkExpsTypeEquiv
"@author: adrpo
  check two types for equivalence"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean bEquiv;
algorithm
  bEquiv := matchcontinue(inExp1, inExp2)
    local
      DAE.Type ty1,ty2;
      Boolean b;
    case (inExp1, inExp2)
      equation
        // adrpo: DO NOT COMPARE TYPES for equivalence for MetaModelica!
        true = Config.acceptMetaModelicaGrammar();
      then true;
    case (inExp1, inExp2)
      equation
        false = Config.acceptMetaModelicaGrammar();
        ty1 = Expression.typeof(inExp1);
        ty2 = Expression.typeof(inExp2);
        b = Types.equivtypes(ty1,ty2);
      then 
        b;
  end matchcontinue;  
end checkExpsTypeEquiv;

public function inlineCall
"function: inlineCall
  replaces an inline call with the expression from the function"
  input tuple<DAE.Exp, tuple<Functiontuple,Boolean>> inTuple;
  output tuple<DAE.Exp, tuple<Functiontuple,Boolean>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Functiontuple fns,fns1;
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      Boolean tup,built;
      DAE.Type t;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp newExp,newExp1, e1;
      DAE.InlineType inlineType;
      DAE.Type ty1,ty2;
      HashTableCG.HashTable checkcr;
    case ((e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)),(fns,_)))
      equation
        true = DAEUtil.convertInlineTypeToBool(inlineType);
        true = checkInlineType(inlineType,fns);
        fn = getFunctionBody(p,fns);
        crefs = List.map(fn,getInputCrefs);
        crefs = List.select(crefs,removeWilds);
        argmap = List.threadTuple(crefs,args);
        (argmap,checkcr) = extendCrefRecords(argmap,HashTableCG.emptyHashTable());
        newExp = getRhsExp(fn);
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        ((newExp,(_,_,true))) = Expression.traverseExp(newExp,replaceArgs,(argmap,checkcr,true));
        // for inlinecalls in functions
        ((newExp1,(fns1,_))) = Expression.traverseExp(newExp,inlineCall,(fns,true));
      then
        ((newExp1,(fns,true)));
    else inTuple;
  end matchcontinue;
end inlineCall;

protected function dumpArgmap
  input tuple<DAE.ComponentRef, DAE.Exp> inTpl;
protected
  DAE.ComponentRef cr;
  DAE.Exp exp;
algorithm
  (cr,exp) := inTpl;
  print(ComponentReference.printComponentRefStr(cr) +& " -> " +& ExpressionDump.printExpStr(exp) +& "\n");
end dumpArgmap;

public function forceInlineCall
"function: inlineCall
  replaces an inline call with the expression from the function"
  input tuple<DAE.Exp, tuple<Functiontuple,Boolean>> inTuple;
  output tuple<DAE.Exp, tuple<Functiontuple,Boolean>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Functiontuple fns,fns1;
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      Boolean tup,built;
      DAE.Type t;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp newExp,newExp1, e1;
      DAE.InlineType inlineType;
      HashTableCG.HashTable checkcr;
    case ((e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)),(fns,_)))
      equation
        false = Config.acceptMetaModelicaGrammar();
        true = checkInlineType(inlineType,fns);
        fn = getFunctionBody(p,fns);  
        crefs = List.map(fn,getInputCrefs);
        crefs = List.select(crefs,removeWilds);
        argmap = List.threadTuple(crefs,args);
        (argmap,checkcr) = extendCrefRecords(argmap,HashTableCG.emptyHashTable());
        newExp::{} = getRhsExp1(fn);
        ((newExp,(_,_,true))) = Expression.traverseExp(newExp,replaceArgs,(argmap,checkcr,true));
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        // for inlinecalls in functions
        ((newExp1,(fns1,_))) = Expression.traverseExp(newExp,forceInlineCall,(fns,true));
      then
        ((newExp1,(fns,true)));
    else inTuple;
  end matchcontinue;
end forceInlineCall;

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
       b = listMember(it,itlst);
      then b;
    case (_,_) then false;
  end matchcontinue;
end checkInlineType;

protected function extendCrefRecords
"function: extendCrefRecords
  extends crefs from records"
  input list<tuple<DAE.ComponentRef, DAE.Exp>> inArgmap;
  input HashTableCG.HashTable inCheckCr;
  output list<tuple<DAE.ComponentRef, DAE.Exp>> outArgmap;
  output HashTableCG.HashTable outCheckCr;  
algorithm
  (outArgmap,outCheckCr) := matchcontinue(inArgmap,inCheckCr)
    local
      HashTableCG.HashTable ht,ht1,ht2,ht3;
      list<tuple<DAE.ComponentRef, DAE.Exp>> res,res1,res2,new,new1;
      DAE.ComponentRef c,cref;
      DAE.Exp e;
      list<DAE.Var> varLst;
      list<DAE.Exp> expl;
      list<DAE.ComponentRef> crlst;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef>> creftpllst;
    case ({},ht) then ({},ht);
    case((c,e as (DAE.CREF(componentRef = cref,ty=DAE.T_COMPLEX(varLst=varLst))))::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
        new = List.map2(varLst,extendCrefRecords1,c,cref);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    /* cause of an error somewhere the type of the expression CREF is not equal to the componentreference type
       this case is needed. */    
    case((c,e as (DAE.CREF(componentRef = cref)))::res,ht)
      equation
        DAE.T_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cref);
        (res1,ht1) = extendCrefRecords(res,ht);
        new = List.map2(varLst,extendCrefRecords1,c,cref);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    case((c,e as (DAE.CALL(expLst = expl,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst)))))::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
        crlst = List.map1(varLst,extendCrefRecords2,c);
        new = List.threadTuple(crlst,expl);
        (new1,ht2) = extendCrefRecords(new,ht1);
        res2 = listAppend(new1,res1);
      then ((c,e)::res2,ht2);
    case((c,e)::res,ht)
      equation
        DAE.T_COMPLEX(varLst=varLst) = Expression.typeof(e);
        crlst = List.map1(varLst,extendCrefRecords2,c);
        creftpllst = List.map1(crlst,Util.makeTuple,c);
        ht1 = List.fold(creftpllst,BaseHashTable.add,ht);
        ht2 = getCheckCref(crlst,ht1);        
        (res1,ht3) = extendCrefRecords(res,ht2);
      then ((c,e)::res1,ht3);        
    case((c,e)::res,ht)
      equation
        (res1,ht1) = extendCrefRecords(res,ht);
      then ((c,e)::res1,ht1);
  end matchcontinue;
end extendCrefRecords;

protected function getCheckCref
  input list<DAE.ComponentRef> inCrefs;
  input HashTableCG.HashTable inCheckCr;
  output HashTableCG.HashTable outCheckCr;
algorithm
  outCheckCr := matchcontinue(inCrefs,inCheckCr)
    local
      HashTableCG.HashTable ht,ht1,ht2,ht3;
      list<DAE.ComponentRef> rest,crlst;
      DAE.ComponentRef cr;
      list<DAE.Var> varLst;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef>> creftpllst;
      case ({},ht) 
        then ht;
    case (cr::rest,ht)
      equation
        DAE.T_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr);
        crlst = List.map1(varLst,extendCrefRecords2,cr);
        ht1 = getCheckCref(crlst,ht);
        creftpllst = List.map1(crlst,Util.makeTuple,cr);
        ht2 = List.fold(creftpllst,BaseHashTable.add,ht1);
        ht3 = getCheckCref(rest,ht2);
      then 
        ht3;          
    case (cr::rest,ht)
      equation
        ht1 = getCheckCref(rest,ht);
      then 
        ht1;
   end matchcontinue;
end getCheckCref;

protected function extendCrefRecords1
"function: extendCrefRecords1
  helper for extendCrefRecords"
  input DAE.Var ev;
  input DAE.ComponentRef c;
  input DAE.ComponentRef e;
  output tuple<DAE.ComponentRef, DAE.Exp> outArg;
algorithm
  outArg := matchcontinue(ev,c,e)
    local
      DAE.Type tp;
      String name;
      DAE.ComponentRef c1,e1;
      DAE.Exp exp;
    
    case(DAE.TYPES_VAR(name=name,ty=tp),c,e) 
      equation
        c1 = ComponentReference.crefPrependIdent(c,name,{},tp);
        e1 = ComponentReference.crefPrependIdent(e,name,{},tp);
        exp = Expression.makeCrefExp(e1,tp);
      then ((c1,exp));
    case(_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.extendCrefRecords1 failed");
      then
        fail();
  end matchcontinue;
end extendCrefRecords1;

protected function extendCrefRecords2
"function: extendCrefRecords1
  helper for extendCrefRecords"
  input DAE.Var ev;
  input DAE.ComponentRef c;
  output DAE.ComponentRef outArg;
algorithm
  outArg := matchcontinue(ev,c)
    local
      DAE.Type tp;
      String name;
      DAE.ComponentRef c1;
      
    case(DAE.TYPES_VAR(name=name,ty=tp),c) 
      equation
        c1 = ComponentReference.crefPrependIdent(c,name,{},tp);
      then c1;
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.extendCrefRecords2 failed");
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
      list<DAE.Element> body;
      DAE.FunctionTree ftree;
    case(p,(SOME(ftree),_))
      equation
        SOME(DAE.FUNCTION( functions = DAE.FUNCTION_DEF(body = body)::_)) = DAEUtil.avlTreeGet(ftree,p);
      then body;
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "Inline.getFunctionBody failed");
        // Error.addMessage(Error.INTERNAL_ERROR, {"Inline.getFunctionBody failed"});
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
        Debug.fprintln(Flags.FAILTRACE,"Inline.getRhsExp failed - cannot inline such a function");
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

protected function getRhsExp1
"function: getRhsExp1
  returns the right hand side of an assignment from a function"
  input list<DAE.Element> inElementList;
  output list<DAE.Exp> outExps;
algorithm
  outExps := matchcontinue(inElementList)
    local
      list<DAE.Element> cdr;
      DAE.Exp exp;
      list<DAE.Exp> res;
    case({})
      then
        {};
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN(exp=exp)})) :: cdr)
      equation
        res = getRhsExp1(cdr);
      then
        exp::res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(exp=exp)})) :: cdr)
      equation
        res = getRhsExp1(cdr);
      then
        exp::res;
    case(DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS({DAE.STMT_ASSIGN_ARR(exp=exp)})) :: cdr)
      equation
        res = getRhsExp1(cdr);
      then
        exp::res;
    case(_ :: cdr)
      equation
        res = getRhsExp1(cdr);
      then
        res;
  end matchcontinue;
end getRhsExp1;

protected function replaceArgs
"function: replaceArgs
  finds DAE.CREF and replaces them with new exps if the cref is in the argmap"
  input tuple<DAE.Exp, tuple<list<tuple<DAE.ComponentRef,DAE.Exp>>,HashTableCG.HashTable,Boolean>> inTuple;
  output tuple<DAE.Exp, tuple<list<tuple<DAE.ComponentRef,DAE.Exp>>,HashTableCG.HashTable,Boolean>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.ComponentRef cref;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp e;
      Absyn.Path path;
      list<DAE.Exp> expLst;
      Boolean tuple_,b;
      DAE.Type ty,ty2;
      DAE.InlineType inlineType;
      DAE.TailCall tc;
      HashTableCG.HashTable checkcr;
      Boolean replacedfailed;
    case ((DAE.CREF(componentRef = cref),(argmap,checkcr,true)))
      equation
        e = getExpFromArgMap(argmap,cref);
        (e,_) = ExpressionSimplify.simplify(e);
      then
        ((e,(argmap,checkcr,true)));
    case ((e as DAE.CREF(componentRef = cref),(argmap,checkcr,true)))
      equation
        _ = BaseHashTable.get(cref,checkcr);
      then
        ((e,(argmap,checkcr,false)));        
    case ((DAE.UNBOX(DAE.CALL(path,expLst,DAE.CALL_ATTR(_,tuple_,false,inlineType,tc)),ty),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);
        (e as DAE.CREF(componentRef=cref)) = getExpFromArgMap(argmap,cref);
        path = ComponentReference.crefToPath(cref);
        expLst = List.map(expLst,Expression.unboxExp);
        b = Expression.isBuiltinFunctionReference(e);
        e = DAE.CALL(path,expLst,DAE.CALL_ATTR(ty,tuple_,b,inlineType,tc));
        (e,_) = ExpressionSimplify.simplify(e);
      then
        ((e,(argmap,checkcr,true)));
    case ((e as DAE.UNBOX(DAE.CALL(path,expLst,DAE.CALL_ATTR(_,tuple_,false,inlineType,tc)),ty),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);        
        _ = BaseHashTable.get(cref,checkcr);
      then
        ((e,(argmap,checkcr,false)));        
        /* TODO: Use the inlineType of the function reference! */
    case((e as DAE.CALL(path,expLst,DAE.CALL_ATTR(DAE.T_METATYPE(ty = _),tuple_,false,_,tc)),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);
        (e as DAE.CREF(componentRef=cref,ty=ty)) = getExpFromArgMap(argmap,cref);
        path = ComponentReference.crefToPath(cref);
        expLst = List.map(expLst,Expression.unboxExp);
        b = Expression.isBuiltinFunctionReference(e);
        (ty2,inlineType) = functionReferenceType(ty);
        e = DAE.CALL(path,expLst,DAE.CALL_ATTR(ty2,tuple_,b,inlineType,tc));
        e = boxIfUnboxedFunRef(e,ty);
        (e,_) = ExpressionSimplify.simplify(e);
      then ((e,(argmap,checkcr,true)));
    case((e as DAE.CALL(path,expLst,DAE.CALL_ATTR(DAE.T_METATYPE(ty = _),tuple_,false,_,tc)),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);
        _ = BaseHashTable.get(cref,checkcr);        
      then
        ((e,(argmap,checkcr,false)));         
    case((e,(argmap,checkcr,replacedfailed))) then ((e,(argmap,checkcr,replacedfailed)));
  end matchcontinue;
end replaceArgs;

protected function boxIfUnboxedFunRef
  "Replacing a function pointer with a regular function means that you:
  (1) Need to unbox all inputs
  (2) Need to box the output if it was not done before
  This function handles (2)
  "
  input DAE.Exp iexp;
  input DAE.Type ty;
  output DAE.Exp outExp;
algorithm
  outExp := match (iexp,ty)
    local
      DAE.Type t;
      DAE.Exp exp;
    case (exp,DAE.T_FUNCTION_REFERENCE_FUNC(functionType=DAE.T_FUNCTION(funcResultType=t)))
      equation
        exp = Util.if_(Types.isBoxedType(t), exp, DAE.BOX(exp));
      then exp;
    else iexp;
  end match;
end boxIfUnboxedFunRef;

protected function functionReferenceType
  "Retrieves the ExpType that the call should have (this changes if the replacing
  function does not return a boxed value).
  We also return the inline type of the new call."
  input DAE.Type ty1;
  output DAE.Type ty2;
  output DAE.InlineType inlineType;
algorithm
  (ty2,inlineType) := match ty1
    local
      DAE.Type ty;
    case DAE.T_FUNCTION_REFERENCE_FUNC(functionType=DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(inline=inlineType),funcResultType=ty))
      then (Types.simplifyType(ty),inlineType);
    else (ty1,DAE.NO_INLINE());
  end match;
end functionReferenceType;

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
        Debug.fprintln(Flags.FAILTRACE,"Inline.getExpFromArgMap failed");
      then
        fail();
    case((cref,exp) :: cdr,key)
      equation
        subs = ComponentReference.crefSubs(key);
        key = ComponentReference.crefStripSubs(key);
        true = ComponentReference.crefEqual(cref,key);
        e = Expression.applyExpSubscripts(exp,subs);
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

public function printInlineTypeStr 
"Print what kind of inline we have"
  input DAE.InlineType it;
  output String str;
algorithm
  str := matchcontinue(it)
    case(DAE.NO_INLINE()) then "No inline";
    case(DAE.AFTER_INDEX_RED_INLINE()) then "Inline after index reduction";
    case(DAE.EARLY_INLINE()) then "Inline as soon as possible";
    case(DAE.NORM_INLINE()) then "Inline before index reduction";
  end matchcontinue;
end printInlineTypeStr;

end Inline;
