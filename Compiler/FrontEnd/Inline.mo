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
public import BackendDAE;
public import BaseHashTable;
public import DAE;
public import Env;
public import HashTableCG;
public import SCode;
public import Util;
public import Values;

protected type Ident = String;
protected type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;

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
protected import VarTransform;

// =============================================================================
// late inline functions stuff
//
// =============================================================================
public function lateInlineFunction
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := inlineCalls({DAE.NORM_INLINE(), DAE.AFTER_INDEX_RED_INLINE()}, inDAE);
end lateInlineFunction;

// =============================================================================
// inline calls stuff
//
// =============================================================================

public function inlineCalls
"searches for calls where the inline flag is true, and inlines them"
  input list<DAE.InlineType> inITLst;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := matchcontinue(inITLst,inBackendDAE)
    local
      list<DAE.InlineType> itlst;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects,aliasVars "alias-variables' hashtable";
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      Functiontuple tpl;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.SymbolicJacobians symjacs;
      DAE.FunctionTree functionTree;
      Env.Cache cache;
      Env.Env env;
      BackendDAE.ExtraInfo ei;
      
    case (itlst,BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars=knownVars,externalObjects=externalObjects,aliasVars=aliasVars,initialEqs=initialEqs,removedEqs=removedEqs,constraints=constrs,classAttrs=clsAttrs,cache=cache,env=env,functionTree=functionTree,eventInfo=eventInfo,extObjClasses=extObjClasses,backendDAEType=btp,symjacs=symjacs,info=ei)))
      equation
        tpl = (SOME(functionTree),itlst);
        eqs = List.map1(eqs,inlineEquationSystem,tpl);
        (knownVars,_) = inlineVariables(knownVars,tpl);
        (externalObjects,_) = inlineVariables(externalObjects,tpl);
        (initialEqs,_) = inlineEquationArray(initialEqs,tpl);
        (removedEqs,_) = inlineEquationArray(removedEqs,tpl);
        eventInfo = inlineEventInfo(eventInfo,tpl);
      then
        BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,removedEqs,constrs,clsAttrs,cache,env,functionTree,eventInfo,extObjClasses,btp,symjacs,ei));
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
      BackendDAE.EqSystem syst;
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.Matching matching;
      Boolean b1,b2;
      BackendDAE.StateSets stateSets;
    case (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars,orderedEqs=orderedEqs,matching=matching,stateSets=stateSets),_)
      equation
        (orderedVars,b1) = inlineVariables(orderedVars,tpl);
        (orderedEqs,b2) = inlineEquationArray(orderedEqs,tpl);
        syst = Util.if_(b1 or b2,BackendDAE.EQSYSTEM(orderedVars,orderedEqs,NONE(),NONE(),matching,stateSets),syst);
      then
        syst;
  end match;
end inlineEquationSystem;

protected function inlineEquationArray "
function: inlineEquationArray
  inlines function calls in an equation array"
  input BackendDAE.EquationArray inEquationArray;
  input Functiontuple inElementList;
  output BackendDAE.EquationArray outEquationArray;
  output Boolean oInlined;
algorithm
  (outEquationArray,oInlined) := matchcontinue(inEquationArray,inElementList)
    local
      Functiontuple fns;
      Integer i1,i2,size;
      array<Option<BackendDAE.Equation>> eqarr;
    case(BackendDAE.EQUATION_ARRAY(size,i1,i2,eqarr),fns)
      equation
        oInlined = inlineEquationOptArray(1,eqarr,i2,fns,false);
      then
        (BackendDAE.EQUATION_ARRAY(size,i1,i2,eqarr),oInlined);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineEquationArray failed");
      then
        fail();
  end matchcontinue;
end inlineEquationArray;

protected function inlineEquationOptArray
"functio: inlineEquationrOptArray
  inlines calls in a equation option"
  input Integer Index;
  input array<Option<BackendDAE.Equation>> inEqnArray;
  input Integer arraysize;
  input Functiontuple fns;
  input Boolean iInlined;
  output Boolean oInlined;
algorithm
  oInlined := matchcontinue(Index,inEqnArray,arraysize,fns,iInlined)
    local
      Option<BackendDAE.Equation> eqn;
      Boolean b;
    case(_,_,_,_,_)
      equation
        true = intLe(Index,arraysize);
        eqn = inEqnArray[Index];
        (eqn,b) = inlineEqOpt(eqn,fns);
        updateArrayCond(b,inEqnArray,Index,eqn);
      then
        inlineEquationOptArray(Index+1,inEqnArray,arraysize,fns,b or iInlined);
    case(_,_,_,_,_)
      equation
        false = intLe(Index,arraysize);
      then
        iInlined;
  end matchcontinue;
end inlineEquationOptArray;

protected function inlineEqOpt "
function: inlineEqOpt
  inlines function calls in equations"
  input Option<BackendDAE.Equation> inEquationOption;
  input Functiontuple inElementList;
  output Option<BackendDAE.Equation> outEquationOption;
  output Boolean inlined;
algorithm
  (outEquationOption,inlined) := match(inEquationOption,inElementList)
    local
      BackendDAE.Equation eqn;
      Boolean b;
    case(NONE(),_) then (NONE(),false);
    case(SOME(eqn),_)
      equation
        (eqn,b) = inlineEq(eqn,inElementList);
      then
        (SOME(eqn),b);
  end match;
end inlineEqOpt;

public function inlineEq "
function: inlineEq
  inlines function calls in equations"
  input BackendDAE.Equation inEquation;
  input Functiontuple fns;
  output BackendDAE.Equation outEquation;
  output Boolean inlined;
algorithm
  (outEquation,inlined) := matchcontinue(inEquation,fns)
    local
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      Integer size;
      list<DAE.Exp> explst;
      DAE.ComponentRef cref;
      BackendDAE.WhenEquation weq,weq_1;
      DAE.ElementSource source;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts,stmts1,assrtLst;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;
      Boolean b1,b2,b3,d;
      DAE.Expand crefExpand;
   
    case(BackendDAE.EQUATION(e1,e2,source,d),_)
      equation
        (e1_1,source,b1,assrtLst) = inlineExp(e1,fns,source);
        (e2_1,source,b2,assrtLst) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
       (BackendDAE.EQUATION(e1_1,e2_1,source,d),true);

    case(BackendDAE.ARRAY_EQUATION(dimSize,e1,e2,source,d),_)
      equation
        (e1_1,source,b1,assrtLst) = inlineExp(e1,fns,source);
        (e2_1,source,b2,assrtLst) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e1_1,e2_1,source,d),true);

    case(BackendDAE.SOLVED_EQUATION(cref,e,source,d),_)
      equation
        (e_1,source,true,assrtLst) = inlineExp(e,fns,source);
      then
        (BackendDAE.SOLVED_EQUATION(cref,e_1,source,d),true);

    case(BackendDAE.RESIDUAL_EQUATION(e,source,d),_)
      equation
        (e_1,source,true,assrtLst) = inlineExp(e,fns,source);
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source,d),true);

    case(BackendDAE.ALGORITHM(size=size,alg=alg as DAE.ALGORITHM_STMTS(statementLst = stmts),source=source,expand=crefExpand),_)
      equation
        (stmts1,true) = inlineStatements(stmts,fns,{},false);
        alg = DAE.ALGORITHM_STMTS(stmts1);
      then
        (BackendDAE.ALGORITHM(size,alg,source,crefExpand),true);

    case(BackendDAE.WHEN_EQUATION(size,weq,source),_)
      equation
        (weq_1,source,true) = inlineWhenEq(weq,fns,source);
      then
        (BackendDAE.WHEN_EQUATION(size,weq_1,source),true);

    case(BackendDAE.COMPLEX_EQUATION(size,e1,e2,source,d),_)
      equation
        (e1_1,source,b1,assrtLst) = inlineExp(e1,fns,source);
        (e2_1,source,b2,assrtLst) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (BackendDAE.COMPLEX_EQUATION(size,e1_1,e2_1,source,d),true);

    case(BackendDAE.IF_EQUATION(explst,eqnslst,eqns,source),_)
      equation
        (explst,source,b1) = inlineExps(explst,fns,source);
        (eqnslst,b2) = inlineEqsLst(eqnslst,fns,{},false);
        (eqns,b3) = inlineEqs(eqns,fns,{},false);
        true = b1 or b2 or b3;
      then
        (BackendDAE.IF_EQUATION(explst,eqnslst,eqns,source),true);
    else
      then
        (inEquation,false);
  end matchcontinue;
end inlineEq;

protected function inlineEqsLst
  input list<list<BackendDAE.Equation>> inEqnsList;
  input Functiontuple inFunctions;
  input list<list<BackendDAE.Equation>> iAcc;
  input Boolean iInlined;
  output list<list<BackendDAE.Equation>> outEqnsList;
  output Boolean OInlined;
algorithm
  (outEqnsList,OInlined) := match(inEqnsList,inFunctions,iAcc,iInlined)
    local
      list<BackendDAE.Equation> eqn;
      list<list<BackendDAE.Equation>> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (eqn::rest,_,_,_)
      equation
        (eqn,inlined) = inlineEqs(eqn,inFunctions,{},false);
        (acc,inlined) = inlineEqsLst(rest,inFunctions,eqn::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineEqsLst;

public function inlineEqs
  input list<BackendDAE.Equation> inEqnsList;
  input Functiontuple inFunctions;
  input list<BackendDAE.Equation> iAcc;
  input Boolean iInlined;
  output list<BackendDAE.Equation> outEqnsList;
  output Boolean OInlined;
algorithm
  (outEqnsList,OInlined) := match(inEqnsList,inFunctions,iAcc,iInlined)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (eqn::rest,_,_,_)
      equation
        (eqn,inlined) = inlineEq(eqn,inFunctions);
        (acc,inlined) = inlineEqs(rest,inFunctions,eqn::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineEqs;

protected function inlineWhenEq
"inlines function calls in when equations"
  input BackendDAE.WhenEquation inWhenEquation;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  output BackendDAE.WhenEquation outWhenEquation;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outWhenEquation,outSource,inlined) := matchcontinue(inWhenEquation,fns,inSource)
    local
      DAE.ComponentRef cref;
      DAE.Exp e,e_1,cond;
      BackendDAE.WhenEquation weq,weq_1;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      list<DAE.Statement> assrtLst;
    case (BackendDAE.WHEN_EQ(cond,cref,e,NONE()),_,_)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,inSource);
        (cond,source,b2,assrtLst) = inlineExp(cond,fns,source);
        true = b1 or b2;
      then
        (BackendDAE.WHEN_EQ(cond,cref,e_1,NONE()),source,true);
    case (BackendDAE.WHEN_EQ(cond,cref,e,SOME(weq)),_,_)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,inSource);
        (cond,source,b2,assrtLst) = inlineExp(cond,fns,source);
        (weq_1,source,b3) = inlineWhenEq(weq,fns,source);
        true = b1 or b2 or b3;
      then
        (BackendDAE.WHEN_EQ(cond,cref,e_1,SOME(weq_1)),source,true);
    else
      then
        (inWhenEquation,inSource,false);
  end matchcontinue;
end inlineWhenEq;

protected function inlineVariables
"inlines function calls in variables"
  input BackendDAE.Variables inVariables;
  input Functiontuple inElementList;
  output BackendDAE.Variables outVariables;
  output Boolean inlined;
algorithm
  (outVariables,inlined) := matchcontinue(inVariables,inElementList)
    local
      Functiontuple fns;
      array<list<BackendDAE.CrefIndex>> crefind;
      Integer i1,i2,i3,i4;
      array<Option<BackendDAE.Var>> vararr;
    case(BackendDAE.VARIABLES(crefind,BackendDAE.VARIABLE_ARRAY(i3,i4,vararr),i1,i2),fns)
      equation
        inlined = inlineVarOptArray(1,vararr,i4,fns,false);
      then
        (BackendDAE.VARIABLES(crefind,BackendDAE.VARIABLE_ARRAY(i3,i4,vararr),i1,i2),inlined);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineVariables failed");
      then
        fail();
  end matchcontinue;
end inlineVariables;

protected function updateArrayCond
  input Boolean cond;
  input array<Type_a> inArr;
  input Integer index;
  input Type_a value;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := match(cond,inArr,index,value)
    case(false,_,_,_) then ();
    case(true,_,_,_)
      equation
        _ = arrayUpdate(inArr,index,value);
      then
        ();
  end match;
end updateArrayCond;

protected function inlineVarOptArray
"functio: inlineVarOptArray
  inlines calls in a variable option"
  input Integer index;
  input array<Option<BackendDAE.Var>> inVarArray;
  input Integer arraysize;
  input Functiontuple fns;
  input Boolean iInlined;
  output Boolean oInlined;
algorithm
  oInlined := inlineVarOptArrayWork(index > arraysize,index,inVarArray,arraysize,fns,iInlined);
end inlineVarOptArray;

protected function inlineVarOptArrayWork
"functio: inlineVarOptArray
  inlines calls in a variable option"
  input Boolean stop;
  input Integer index;
  input array<Option<BackendDAE.Var>> inVarArray;
  input Integer arraysize;
  input Functiontuple fns;
  input Boolean iInlined;
  output Boolean oInlined;
algorithm
  oInlined := match (stop,index,inVarArray,arraysize,fns,iInlined)
    local
      Option<BackendDAE.Var> var;
      Boolean b;
    case (true,_,_,_,_,_)
      then iInlined;
    else
      equation
        var = inVarArray[index];
        (var,b) = inlineVarOpt(var,fns);
        updateArrayCond(b,inVarArray,index,var);
      then inlineVarOptArrayWork(index+1 > arraysize,index+1,inVarArray,arraysize,fns,b or iInlined);
  end match;
end inlineVarOptArrayWork;

protected function inlineVarOpt
"functio: inlineVarOpt
  inlines calls in a variable option"
  input Option<BackendDAE.Var> inVarOption;
  input Functiontuple fns;
  output Option<BackendDAE.Var> outVarOption;
  output Boolean inlined;
algorithm
  (outVarOption,inlined) := match(inVarOption,fns)
    local
      BackendDAE.Var var;
      Boolean b;
    case(NONE(),_) then (NONE(),false);
    case(SOME(var),_)
      equation
        (var,b) = inlineVar(var,fns);
      then
        (SOME(var),b);
  end match;
end inlineVarOpt;

public function inlineVar
"functio: inlineVar
  inlines calls in a variable"
  input BackendDAE.Var inVar;
  input Functiontuple inElementList;
  output BackendDAE.Var outVar;
  output Boolean inlined;
algorithm
  (outVar,inlined) := match(inVar,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef varName;
      BackendDAE.VarKind varKind;
      DAE.VarDirection varDirection;
      DAE.VarParallelism varParallelism;
      BackendDAE.Type varType;
      Option<Values.Value> bindValue;
      DAE.InstDims arrayDim;
      Option<DAE.VariableAttributes> values,values1;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      DAE.ElementSource source;
      Option<DAE.Exp> bind;
      Boolean b1,b2;
    case(BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,bind,bindValue,arrayDim,source,values,comment,ct),fns)
      equation
        (bind,source,b1) = inlineExpOpt(bind,fns,source);
        (values1,source,b2) = inlineStartAttribute(values,source,fns);
      then
        (BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,bind,bindValue,arrayDim,source,values1,comment,ct),b1 or b2);
    case(var,_) then (var,false);
  end match;
end inlineVar;

public function inlineStartAttribute
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  input DAE.ElementSource isource;
  input Functiontuple fns;
  output Option<DAE.VariableAttributes> outVariableAttributesOption;
  output DAE.ElementSource osource;
  output Boolean b;
algorithm
  (outVariableAttributesOption,osource,b):=matchcontinue (inVariableAttributesOption,isource,fns)
    local
      DAE.ElementSource source;
      DAE.Exp r;
      Option<DAE.Exp> quantity,unit,displayUnit,fixed,nominal,so;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.StateSelect> stateSelectOption;
      Option<DAE.Uncertainty> uncertainOption;
      Option<DAE.Distribution> distributionOption;
      Option<DAE.Exp> equationBound;
      Option<Boolean> isProtected,finalPrefix;
      list<DAE.Statement> assrtLst;
    case (NONE(),_,_) then (NONE(),isource,false);
    case (SOME(DAE.VAR_ATTR_REAL(quantity=quantity,unit=unit,displayUnit=displayUnit,min=min,start = SOME(r),
          fixed=fixed,nominal=nominal,stateSelectOption=stateSelectOption,uncertainOption=uncertainOption,
          distributionOption=distributionOption,equationBound=equationBound,isProtected=isProtected,finalPrefix=finalPrefix,
          startOrigin=so)),_,_)
      equation
        (r,source,true,assrtLst) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,SOME(r),fixed,nominal,
          stateSelectOption,uncertainOption,distributionOption,equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_INT(quantity=quantity,min=min,start = SOME(r),
          fixed=fixed,uncertainOption=uncertainOption,distributionOption=distributionOption,equationBound=equationBound,
          isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,assrtLst) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_INT(quantity,min,SOME(r),fixed,uncertainOption,distributionOption,equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_BOOL(quantity=quantity,start = SOME(r),
          fixed=fixed,equationBound=equationBound,isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,assrtLst) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_BOOL(quantity,SOME(r),fixed,equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_STRING(quantity=quantity,start = SOME(r),
          equationBound=equationBound,isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,assrtLst) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_STRING(quantity,SOME(r),equationBound,isProtected,finalPrefix,so)),source,true);
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quantity=quantity,min=min,start = SOME(r),
          fixed=fixed,equationBound=equationBound,
          isProtected=isProtected,finalPrefix=finalPrefix,startOrigin=so)),_,_)
      equation
        (r,source,true,assrtLst) = inlineExp(r,fns,isource);
      then (SOME(DAE.VAR_ATTR_ENUMERATION(quantity,min,SOME(r),fixed,equationBound,isProtected,finalPrefix,so)),source,true);
    case (_,_,_) then (inVariableAttributesOption,isource,false);
  end matchcontinue;
end inlineStartAttribute;

protected function inlineEventInfo "inlines function calls in event info"
  input BackendDAE.EventInfo inEventInfo;
  input Functiontuple inElementList;
  output BackendDAE.EventInfo outEventInfo;
algorithm
  outEventInfo := matchcontinue(inEventInfo, inElementList)
    local
      Functiontuple fns;
      list<BackendDAE.WhenClause> wclst, wclst_1;
      list<BackendDAE.ZeroCrossing> zclst, zclst_1, relations, samples;
      Integer numberOfRelations, numberOfMathEvents;
      BackendDAE.EventInfo ev;
      Boolean b1, b2, b3;
      list<BackendDAE.TimeEvent> timeEvents;
      
    case(BackendDAE.EVENT_INFO(timeEvents, wclst, zclst, samples, relations, numberOfRelations, numberOfMathEvents), fns) equation
      (wclst_1, b1) = inlineWhenClauses(wclst, fns, {}, false);
      (zclst_1, b2) = inlineZeroCrossings(zclst, fns, {}, false);
      (relations, b3) = inlineZeroCrossings(relations, fns, {}, false);
      ev = Util.if_(b1 or b2 or b3, BackendDAE.EVENT_INFO(timeEvents, wclst_1, zclst_1, samples, relations, numberOfRelations, numberOfMathEvents), inEventInfo);
    then ev;
    
    case(_, _) equation
      Debug.fprintln(Flags.FAILTRACE, "Inline.inlineEventInfo failed");
    then fail();
  end matchcontinue;
end inlineEventInfo;

protected function inlineZeroCrossings "inlines function calls in zero crossings"
  input list<BackendDAE.ZeroCrossing> inStmts;
  input Functiontuple fns;
  input list<BackendDAE.ZeroCrossing> iAcc;
  input Boolean iInlined;
  output list<BackendDAE.ZeroCrossing> outStmts;
  output Boolean oInlined;
algorithm
  (outStmts, oInlined) := match (inStmts, fns, iAcc, iInlined)
    local
      BackendDAE.ZeroCrossing zc;
      list<BackendDAE.ZeroCrossing> rest, stmts;
      Boolean b;

    case ({}, _, _, _)
    then (listReverse(iAcc), iInlined);
    
    case (zc::rest, _, _, _) equation
      (zc, b) = inlineZeroCrossing(zc, fns);
      (stmts, b) = inlineZeroCrossings(rest, fns, zc::iAcc, b or iInlined);
    then (stmts, b);
  end match;
end inlineZeroCrossings;

protected function inlineZeroCrossing "inlines function calls in a zero crossing"
  input BackendDAE.ZeroCrossing inZeroCrossing;
  input Functiontuple inElementList;
  output BackendDAE.ZeroCrossing outZeroCrossing;
  output Boolean oInlined;
algorithm
  (outZeroCrossing, oInlined) := matchcontinue(inZeroCrossing, inElementList)
    local
      Functiontuple fns;
      DAE.Exp e, e_1;
      list<Integer> ilst1, ilst2;
      list<DAE.Statement> assrtLst;
    
    case(BackendDAE.ZERO_CROSSING(e, ilst1, ilst2), fns) equation
      (e_1, _, true, assrtLst) = inlineExp(e, fns, DAE.emptyElementSource/*TODO: Propagate operation info*/);
    then (BackendDAE.ZERO_CROSSING(e_1, ilst1, ilst2), true);
    
    case(_, _)
    then (inZeroCrossing, false);
  end matchcontinue;
end inlineZeroCrossing;

protected function inlineWhenClauses
"inlines function calls in reinit statements"
  input list<BackendDAE.WhenClause> inStmts;
  input Functiontuple fns;
  input list<BackendDAE.WhenClause> iAcc;
  input Boolean iInlined;
  output list<BackendDAE.WhenClause> outStmts;
  output Boolean oInlined;
algorithm
  (outStmts,oInlined) := match (inStmts,fns,iAcc,iInlined)
    local
      BackendDAE.WhenClause wc;
      list<BackendDAE.WhenClause> rest,stmts;
      Boolean b;

    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (wc::rest,_,_,_)
      equation
        (wc,b) = inlineWhenClause(wc,fns);
        (stmts,b) = inlineWhenClauses(rest,fns,wc::iAcc,b or iInlined);
      then
        (stmts,b);
  end match;
end inlineWhenClauses;

protected function inlineWhenClause
"inlines function calls in a when clause"
  input BackendDAE.WhenClause inWhenClause;
  input Functiontuple inElementList;
  output BackendDAE.WhenClause outWhenClause;
  output Boolean inlined;
algorithm
  (outWhenClause,inlined) := matchcontinue(inWhenClause,inElementList)
    local
      Functiontuple fns;
      DAE.Exp e,e_1;
      list<BackendDAE.WhenOperator> rslst,rslst_1;
      Option<Integer> io;
      Boolean b1,b2;
      list<DAE.Statement> assrtLst;
    case(BackendDAE.WHEN_CLAUSE(e,rslst,io),fns)
      equation
        (e_1,_,b1,assrtLst) = inlineExp(e,fns,DAE.emptyElementSource/*TODO: Propagate operation info*/);
        (rslst_1,b2) = inlineReinitStmts(rslst,fns,{},false);
        true = b1 or b2;
      then
        (BackendDAE.WHEN_CLAUSE(e_1,rslst_1,io),true);
    case(_,_)
      then
        (inWhenClause,false);
  end matchcontinue;
end inlineWhenClause;

protected function inlineReinitStmts
"inlines function calls in reinit statements"
  input list<BackendDAE.WhenOperator> inStmts;
  input Functiontuple fns;
  input list<BackendDAE.WhenOperator> iAcc;
  input Boolean iInlined;
  output list<BackendDAE.WhenOperator> outStmts;
  output Boolean oInlined;
algorithm
  (outStmts,oInlined) := match (inStmts,fns,iAcc,iInlined)
    local
      BackendDAE.WhenOperator re;
      list<BackendDAE.WhenOperator> rest,stmts;
      Boolean b;

    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (re::rest,_,_,_)
      equation
        (re,b) = inlineReinitStmt(re,fns);
        (stmts,b) = inlineReinitStmts(rest,fns,re::iAcc,b or iInlined);
      then
        (stmts,b);
  end match;
end inlineReinitStmts;

protected function inlineReinitStmt
"inlines function calls in a reinit statement"
  input BackendDAE.WhenOperator inReinitStatement;
  input Functiontuple inElementList;
  output BackendDAE.WhenOperator outReinitStatement;
  output Boolean inlined;
algorithm
  (outReinitStatement,inlined) := matchcontinue(inReinitStatement,inElementList)
    local
      Functiontuple fns;
      DAE.ComponentRef cref;
      DAE.Exp e,e_1;
      BackendDAE.WhenOperator rs;
      DAE.ElementSource source;
      list<DAE.Statement> assrtLst;
    case (BackendDAE.REINIT(cref,e,source),fns)
      equation
        (e_1,source,true,assrtLst) = inlineExp(e,fns,source);
      then
        (BackendDAE.REINIT(cref,e_1,source),true);
    case (rs,_) then (rs,false);
  end matchcontinue;
end inlineReinitStmt;

public function inlineCallsInFunctions
"inlines calls in DAEElements"
  input list<DAE.Function> inElementList;
  input Functiontuple inFunctions;
  input list<DAE.Function> iAcc;
  output list<DAE.Function> outElementList;
algorithm
  outElementList := matchcontinue(inElementList,inFunctions,iAcc)
    local
      list<DAE.Function> cdr;
      list<DAE.Element> elist,elist_1;
      DAE.Function el,res;
      DAE.Type t;
      Boolean partialPrefix, isImpure;
      Absyn.Path p;
      DAE.ExternalDecl ext;
      DAE.InlineType inlineType;
      list<DAE.FunctionDefinition> funcDefs;
      DAE.ElementSource source;
      Option<SCode.Comment> cmt;

    case({},_,_) then listReverse(iAcc);

    case(DAE.FUNCTION(p,DAE.FUNCTION_DEF(body = elist)::funcDefs,t,partialPrefix,isImpure,inlineType,source,cmt) :: cdr,_,_)
      equation
        (elist_1,true)= inlineDAEElements(elist,inFunctions,{},false);
        res = DAE.FUNCTION(p,DAE.FUNCTION_DEF(elist_1)::funcDefs,t,partialPrefix,isImpure,inlineType,source,cmt);
      then
        inlineCallsInFunctions(cdr,inFunctions,res::iAcc);
    // external functions
    case(DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist,ext)::funcDefs,t,partialPrefix,isImpure,inlineType,source,cmt) :: cdr,_,_)
      equation
        (elist_1,true)= inlineDAEElements(elist,inFunctions,{},false);
        res = DAE.FUNCTION(p,DAE.FUNCTION_EXT(elist_1,ext)::funcDefs,t,partialPrefix,isImpure,inlineType,source,cmt);
      then
        inlineCallsInFunctions(cdr,inFunctions,res::iAcc);

    case(el :: cdr,_,_)
      then
        inlineCallsInFunctions(cdr,inFunctions,el::iAcc);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"Inline.inlineCallsInFunctions failed"});
      then fail();
  end matchcontinue;
end inlineCallsInFunctions;


protected function inlineDAEElementsLst
  input list<list<DAE.Element>> inElementList;
  input Functiontuple inFunctions;
  input list<list<DAE.Element>> iAcc;
  input Boolean iInlined;
  output list<list<DAE.Element>> outElementList;
  output Boolean OInlined;
algorithm
  (outElementList,OInlined) := match(inElementList,inFunctions,iAcc,iInlined)
    local
      list<DAE.Element> elem;
      list<list<DAE.Element>> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (elem::rest,_,_,_)
      equation
        (elem,inlined) = inlineDAEElements(elem,inFunctions,{},false);
        (acc,inlined) = inlineDAEElementsLst(rest,inFunctions,elem::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineDAEElementsLst;

protected function inlineDAEElements
  input list<DAE.Element> inElementList;
  input Functiontuple inFunctions;
  input list<DAE.Element> iAcc;
  input Boolean iInlined;
  output list<DAE.Element> outElementList;
  output Boolean OInlined;
algorithm
  (outElementList,OInlined) := match(inElementList,inFunctions,iAcc,iInlined)
    local
      DAE.Element elem;
      list<DAE.Element> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (elem::rest,_,_,_)
      equation
        (elem,inlined) = inlineDAEElement(elem,inFunctions);
        (acc,inlined) = inlineDAEElements(rest,inFunctions,elem::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineDAEElements;

protected function inlineDAEElement
"inlines calls in DAEElements"
  input DAE.Element inElement;
  input Functiontuple inFunctions;
  output DAE.Element outElement;
  output Boolean inlined;
algorithm
  (outElement,inlined) := matchcontinue(inElement,inFunctions)
    local
      Functiontuple fns;
      list<DAE.Element> elist,elist_1;
      list<list<DAE.Element>> dlist,dlist_1;
      DAE.Element el,el_1;
      DAE.ComponentRef componentRef;
      DAE.VarKind kind;
      DAE.VarDirection direction;
      DAE.VarParallelism parallelism;
      DAE.VarVisibility protection;
      DAE.Type ty;
      DAE.Exp binding,binding_1,exp,exp_1,exp1,exp1_1,exp2,exp2_1,exp3,exp3_1;
      DAE.InstDims dims;
      DAE.ConnectorType ct;
      Option<DAE.VariableAttributes> variableAttributesOption;
      Option<SCode.Comment> absynCommentOption;
      Absyn.InnerOuter innerOuter;
      DAE.Dimensions dimension;
      DAE.Algorithm alg,alg_1;
      Ident i;
      Absyn.Path p;
      list<DAE.Exp> explst,explst_1;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      list<DAE.Statement> assrtLst;

    case (DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(binding),dims,ct,
                 source,variableAttributesOption,absynCommentOption,innerOuter),fns)
      equation
        (binding_1,source,true,assrtLst) = inlineExp(binding,fns,source);
      then
        (DAE.VAR(componentRef,kind,direction,parallelism,protection,ty,SOME(binding_1),dims,ct,
                      source,variableAttributesOption,absynCommentOption,innerOuter),true);

    case (DAE.DEFINE(componentRef,exp,source) ,fns)
      equation
        (exp_1,source,true,assrtLst) = inlineExp(exp,fns,source);
      then
        (DAE.DEFINE(componentRef,exp_1,source),true);

    case(DAE.INITIALDEFINE(componentRef,exp,source) ,fns)
      equation
        (exp_1,source,true,assrtLst) = inlineExp(exp,fns,source);
      then
        (DAE.INITIALDEFINE(componentRef,exp_1,source),true);

    case(DAE.EQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.EQUATION(exp1_1,exp2_1,source),true);

    case(DAE.ARRAY_EQUATION(dimension,exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.ARRAY_EQUATION(dimension,exp1_1,exp2_1,source),true);

    case(DAE.INITIAL_ARRAY_EQUATION(dimension,exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.INITIAL_ARRAY_EQUATION(dimension,exp1_1,exp2_1,source),true);

    case(DAE.COMPLEX_EQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.COMPLEX_EQUATION(exp1_1,exp2_1,source),true);

    case(DAE.INITIAL_COMPLEX_EQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
        true = b1 or b2;
      then
        (DAE.INITIAL_COMPLEX_EQUATION(exp1_1,exp2_1,source),true);

    case(DAE.WHEN_EQUATION(exp,elist,SOME(el),source),fns)
      equation
        (exp_1,source,b1,assrtLst) = inlineExp(exp,fns,source);
        (elist_1,b2) = inlineDAEElements(elist,fns,{},false);
        (el_1,b3) = inlineDAEElement(el,fns);
        true = b1 or b2 or b3;
      then
        (DAE.WHEN_EQUATION(exp_1,elist_1,SOME(el_1),source),true);

    case(DAE.WHEN_EQUATION(exp,elist,NONE(),source),fns)
      equation
        (exp_1,source,b1,assrtLst) = inlineExp(exp,fns,source);
        (elist_1,b2) = inlineDAEElements(elist,fns,{},false);
        true = b1 or b2;
      then
        (DAE.WHEN_EQUATION(exp_1,elist_1,NONE(),source),true);

    case(DAE.IF_EQUATION(explst,dlist,elist,source) ,fns)
      equation
        (explst_1,source,b1) = inlineExps(explst,fns,source);
        (dlist_1,b2) = inlineDAEElementsLst(dlist,fns,{},false);
        (elist_1,b3) = inlineDAEElements(elist,fns,{},false);
        true = b1 or b2 or b3;
      then
        (DAE.IF_EQUATION(explst_1,dlist_1,elist_1,source),true);

    case(DAE.INITIAL_IF_EQUATION(explst,dlist,elist,source) ,fns)
      equation
        (explst_1,source,b1) = inlineExps(explst,fns,source);
        (dlist_1,b2) = inlineDAEElementsLst(dlist,fns,{},false);
        (elist_1,b3) = inlineDAEElements(elist,fns,{},false);
        true = b1 or b2 or b3;
      then
        (DAE.INITIAL_IF_EQUATION(explst_1,dlist_1,elist_1,source),true);

    case(DAE.INITIALEQUATION(exp1,exp2,source),fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
      then
        (DAE.INITIALEQUATION(exp1_1,exp2_1,source),true);

    case((el as DAE.ALGORITHM(alg,source)),fns)
      equation
        (alg_1,true) = inlineAlgorithm(alg,fns);
      then
        (DAE.ALGORITHM(alg_1,source),true);

    case((el as DAE.INITIALALGORITHM(alg,source)) ,fns)
      equation
        (alg_1,true) = inlineAlgorithm(alg,fns);
      then
        (DAE.INITIALALGORITHM(alg_1,source),true);

    case(DAE.COMP(i,elist,source,absynCommentOption),fns)
      equation
        (elist_1,true) = inlineDAEElements(elist,fns,{},false);
      then
        (DAE.COMP(i,elist_1,source,absynCommentOption),true);

    case(DAE.ASSERT(exp1,exp2,exp3,source) ,fns)
      equation
        (exp1_1,source,b1,assrtLst) = inlineExp(exp1,fns,source);
        (exp2_1,source,b2,assrtLst) = inlineExp(exp2,fns,source);
        (exp3_1,source,b3,assrtLst) = inlineExp(exp3,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.ASSERT(exp1_1,exp2_1,exp3_1,source),true);

    case(DAE.TERMINATE(exp,source),fns)
      equation
        (exp_1,source,true,assrtLst) = inlineExp(exp,fns,source);
      then
        (DAE.TERMINATE(exp_1,source),true);

    case(DAE.REINIT(componentRef,exp,source),fns)
      equation
        (exp_1,source,true,assrtLst) = inlineExp(exp,fns,source);
      then
        (DAE.REINIT(componentRef,exp_1,source),true);

    case(DAE.NORETCALL(p,explst,source),fns)
      equation
        (explst_1,source,true) = inlineExps(explst,fns,source);
      then
        (DAE.NORETCALL(p,explst_1,source),true);

    case(el,fns)
      then
        (el,false);
  end matchcontinue;
end inlineDAEElement;

public function inlineAlgorithm
"inline calls in an DAE.Algorithm"
  input DAE.Algorithm inAlgorithm;
  input Functiontuple inElementList;
  output DAE.Algorithm outAlgorithm;
  output Boolean inlined;
algorithm
  (outAlgorithm,inlined) := matchcontinue(inAlgorithm,inElementList)
    local
      list<DAE.Statement> stmts,stmts_1;
      Functiontuple fns;
    case(DAE.ALGORITHM_STMTS(stmts),fns)
      equation
        (stmts_1,inlined) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.ALGORITHM_STMTS(stmts_1),inlined);
    case(_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"Inline.inlineAlgorithm failed");
      then
        fail();
  end matchcontinue;
end inlineAlgorithm;

protected function inlineStatements
  input list<DAE.Statement> inStatements;
  input Functiontuple inElementList;
  input list<DAE.Statement> iAcc;
  input Boolean iInlined;
  output list<DAE.Statement> outStatements;
  output Boolean OInlined;
algorithm
  (outStatements,OInlined) := match(inStatements,inElementList,iAcc,iInlined)
    local
      DAE.Statement stmt;
      list<DAE.Statement> rest,acc;
      Boolean inlined;
    case ({},_,_,_) then (listReverse(iAcc),iInlined);
    case (stmt::rest,_,_,_)
      equation
        (stmt,inlined) = inlineStatement(stmt,inElementList);
        (acc,inlined) = inlineStatements(rest,inElementList,stmt::iAcc,inlined or iInlined);
      then
        (acc,inlined);
  end match;
end inlineStatements;

protected function inlineStatement
"inlines calls in an DAE.Statement"
  input DAE.Statement inStatement;
  input Functiontuple inElementList;
  output DAE.Statement outStatement;
  output Boolean inlined;
algorithm
  (outStatement,inlined) := matchcontinue(inStatement,inElementList)
    local
      Functiontuple fns;
      DAE.Statement stmt,stmt_1;
      DAE.Type t;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1,e3,e3_1;
      list<DAE.Exp> explst,explst_1;
      DAE.ComponentRef cref;
      DAE.Else a_else,a_else_1;
      list<DAE.Statement> stmts,stmts_1;
      Boolean b,b1,b2,b3;
      Ident i;
      Integer ix;
      DAE.ElementSource source;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;
      list<DAE.Statement> assrtLst;
    case (DAE.STMT_ASSIGN(t,e1,e2,source),fns)
      equation
        (e1_1,source,b1,assrtLst) = inlineExp(e1,fns,source);
        (e2_1,source,b2,assrtLst) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_ASSIGN(t,e1_1,e2_1,source),true);
    case(DAE.STMT_TUPLE_ASSIGN(t,explst,e,source),fns)
      equation
        (explst_1,source,b1) = inlineExps(explst,fns,source);
        (e_1,source,b2,assrtLst) = inlineExp(e,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_TUPLE_ASSIGN(t,explst_1,e_1,source),true);
    case(DAE.STMT_ASSIGN_ARR(t,cref,e,source),fns)
      equation
        (e_1,source,true,assrtLst) = inlineExp(e,fns,source);
      then
        (DAE.STMT_ASSIGN_ARR(t,cref,e_1,source),true);
    case(DAE.STMT_IF(e,stmts,a_else,source),fns)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        (a_else_1,source,b3) = inlineElse(a_else,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.STMT_IF(e_1,stmts_1,a_else_1,source),true);
    case(DAE.STMT_FOR(t,b,i,ix,e,stmts,source),fns)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        true = b1 or b2;
      then
        (DAE.STMT_FOR(t,b,i,ix,e_1,stmts_1,source),true);
    case(DAE.STMT_WHILE(e,stmts,source),fns)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        true = b1 or b2;
      then
        (DAE.STMT_WHILE(e_1,stmts_1,source),true);
    case(DAE.STMT_WHEN(e,conditions,initialCall,stmts,SOME(stmt),source),fns)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        (stmt_1,b3) = inlineStatement(stmt,fns);
        true = b1 or b2 or b3;
      then
        (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts_1,SOME(stmt_1),source),true);
    case(DAE.STMT_WHEN(e,conditions,initialCall,stmts,NONE(),source),fns)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        true = b1 or b2;
      then
        (DAE.STMT_WHEN(e_1,conditions,initialCall,stmts_1,NONE(),source),true);
    case(DAE.STMT_ASSERT(e1,e2,e3,source),fns)
      equation
        (e1_1,source,b1,assrtLst) = inlineExp(e1,fns,source);
        (e2_1,source,b2,assrtLst) = inlineExp(e2,fns,source);
        (e3_1,source,b3,assrtLst) = inlineExp(e3,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.STMT_ASSERT(e1_1,e2_1,e3_1,source),true);
    case(DAE.STMT_TERMINATE(e,source),fns)
      equation
        (e_1,source,true,assrtLst) = inlineExp(e,fns,source);
      then
        (DAE.STMT_TERMINATE(e_1,source),true);
    case(DAE.STMT_REINIT(e1,e2,source),fns)
      equation
        (e1_1,source,b1,assrtLst) = inlineExp(e1,fns,source);
        (e2_1,source,b2,assrtLst) = inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (DAE.STMT_REINIT(e1_1,e2_1,source),true);
    case(DAE.STMT_NORETCALL(e,source),fns)
      equation
        (e_1,source,true,assrtLst) = inlineExp(e,fns,source);
      then
        (DAE.STMT_NORETCALL(e_1,source),true);
    case(DAE.STMT_FAILURE(stmts,source),fns)
      equation
        (stmts_1,true) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.STMT_FAILURE(stmts_1,source),true);
    case(DAE.STMT_TRY(stmts,source),fns)
      equation
        (stmts_1,true) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.STMT_TRY(stmts_1,source),true);
    case(DAE.STMT_CATCH(stmts,source),fns)
      equation
        (stmts_1,true) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.STMT_CATCH(stmts_1,source),true);
    case(stmt,_) then (stmt,false);
  end matchcontinue;
end inlineStatement;

protected function inlineElse
"inlines calls in an DAE.Else"
  input DAE.Else inElse;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Else outElse;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outElse,outSource,inlined) := matchcontinue(inElse,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Else a_else,a_else_1;
      DAE.Exp e,e_1;
      list<DAE.Statement> stmts,stmts_1;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      list<DAE.Statement> assrtLst;
    case (DAE.ELSEIF(e,stmts,a_else),fns,source)
      equation
        (e_1,source,b1,assrtLst) = inlineExp(e,fns,source);
        (stmts_1,b2) = inlineStatements(stmts,fns,{},false);
        (a_else_1,source,b3) = inlineElse(a_else,fns,source);
        true = b1 or b2 or b3;
      then
        (DAE.ELSEIF(e_1,stmts_1,a_else_1),source,true);
    case (DAE.ELSE(stmts),fns,source)
      equation
        (stmts_1,true) = inlineStatements(stmts,fns,{},false);
      then
        (DAE.ELSE(stmts_1),source,true);
    case (a_else,fns,source) then (a_else,source,false);
  end matchcontinue;
end inlineElse;

public function inlineExpOpt "
function: inlineExpOpt
  inlines calls in an DAE.Exp"
  input Option<DAE.Exp> inExpOption;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output Option<DAE.Exp> outExpOption;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outExpOption,outSource,inlined) := match(inExpOption,inElementList,inSource)
    local
      DAE.Exp exp;
      DAE.ElementSource source;
      Boolean b;
      list<DAE.Statement> assrtLst;
    case(NONE(),_,_) then (NONE(),inSource,false);
    case(SOME(exp),_,_)
      equation
        (exp,source,b,assrtLst) = inlineExp(exp,inElementList,inSource);
      then
        (SOME(exp),source,b);
  end match;
end inlineExpOpt;

public function inlineExp "
function: inlineExp
  inlines calls in a DAE.Exp"
  input DAE.Exp inExp;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output DAE.Exp outExp;
  output DAE.ElementSource outSource;
  output Boolean inlined;
  output list<DAE.Statement> assrtLstOut;
algorithm
  (outExp,outSource,inlined,assrtLstOut) := matchcontinue (inExp,inElementList,inSource)
    local
      Functiontuple fns;
      DAE.Exp e,e_1,e_2;
      DAE.ElementSource source;
      list<DAE.Statement> assrtLst;
    
    // never inline WILD!
    case (e as DAE.CREF(componentRef = DAE.WILD()),fns,source) then (inExp,inSource,false,{});
    
    case (e,fns,source)
      equation
        ((e_1,(fns,true,assrtLst))) = Expression.traverseExp(e,inlineCall,(fns,false,{}));
        source = DAEUtil.addSymbolicTransformation(source,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e_1)));
        (DAE.PARTIAL_EQUATION(e_2),source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e_1), source);
      then
        (e_2,source,true,assrtLst);
    
    else (inExp,inSource,false,{});
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
      DAE.ElementSource source;
      list<DAE.Statement> assrtLst;
    case (e,fns,source)
      equation
        ((e_1,(fns,true,assrtLst))) = Expression.traverseExp(e,forceInlineCall,(fns,false,{}));
        source = DAEUtil.addSymbolicTransformation(source,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e_1)));
        (DAE.PARTIAL_EQUATION(e_2),source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e_1), source);
      then
        (e_2,source,true);
    else (inExp,inSource,false);
  end matchcontinue;
end forceInlineExp;

public function inlineExps "
function: inlineExp
  inlines calls in an DAE.Exp"
  input list<DAE.Exp> inExps;
  input Functiontuple inElementList;
  input DAE.ElementSource inSource;
  output list<DAE.Exp> outExps;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outExps,outSource,inlined) := inlineExpsWork(inExps,inElementList,inSource,{},false);
end inlineExps;

protected function inlineExpsWork "
function: inlineExp
  inlines calls in an DAE.Exp"
  input list<DAE.Exp> inExps;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  input list<DAE.Exp> iAcc;
  input Boolean iInlined;
  output list<DAE.Exp> outExps;
  output DAE.ElementSource outSource;
  output Boolean oInlined;
algorithm
  (outExps,outSource,oInlined) := match (inExps,fns,inSource,iAcc,iInlined)
    local
      DAE.Exp e;
      list<DAE.Exp> exps;
      DAE.ElementSource source;
      Boolean b;
      list<DAE.Statement> assrtLst;

    case ({},_,_,_,_) then (listReverse(iAcc),inSource,iInlined);
    case (e::exps,_,_,_,_)
      equation
        (e,source,b,assrtLst) = inlineExp(e,fns,inSource);
        (exps,source,b) = inlineExpsWork(exps,fns,source,e::iAcc,b or iInlined);
      then
        (exps,source,b);
  end match;
end inlineExpsWork;

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
    case (_, _)
      equation
        // adrpo: DO NOT COMPARE TYPES for equivalence for MetaModelica!
        true = Config.acceptMetaModelicaGrammar();
      then true;
    case (_, _)
      equation
        false = Config.acceptMetaModelicaGrammar();
        ty1 = Expression.typeof(inExp1);
        ty2 = Expression.typeof(inExp2);
        ((ty2, _)) = Types.traverseType((ty2, -1), Types.makeExpDimensionsUnknown);
        b = Types.equivtypes(ty1,ty2);
      then
        b;
  end matchcontinue;
end checkExpsTypeEquiv;

public function inlineCall
"replaces an inline call with the expression from the function"
  input tuple<DAE.Exp, tuple<Functiontuple,Boolean,list<DAE.Statement>>> inTuple;
  output tuple<DAE.Exp, tuple<Functiontuple,Boolean,list<DAE.Statement>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Functiontuple fns,fns1;
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      DAE.Exp newExp,newExp1, e1, cond, msg, level, newAssrtCond, newAssrtMsg, newAssrtLevel;
      DAE.InlineType inlineType;
      DAE.Statement assrt;
      HashTableCG.HashTable checkcr;
      list<DAE.Statement> stmts,assrtStmts, assrtLstIn, assrtLst;
      VarTransform.VariableReplacements repl;
      Boolean generateEvents;
      Option<SCode.Comment> comment;

      /* If we disable inlining by use of flags, we still inline builtin functions */
    case ((DAE.CALL(attr=DAE.CALL_ATTR(inlineType=inlineType)),_))
      equation
        false = Flags.isSet(Flags.INLINE_FUNCTIONS);
        failure(DAE.BUILTIN_EARLY_INLINE() = inlineType);
      then inTuple;

    case ((e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)),(fns,_,assrtLstIn)))
      equation
        true = Config.acceptMetaModelicaGrammar();
        true = DAEUtil.convertInlineTypeToBool(inlineType);
        true = checkInlineType(inlineType,fns);
        (fn,_) = getFunctionBody(p,fns);
        crefs = List.map(fn,getInputCrefs);
        crefs = List.select(crefs,removeWilds);
        argmap = List.threadTuple(crefs,args);
        false = List.exist(fn,DAEUtil.isProtectedVar);
        (argmap,checkcr) = extendCrefRecords(argmap,HashTableCG.emptyHashTable());
        newExp = getRhsExp(fn);
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        // add noEvent to avoid events as usually for functions
        // MSL 3.2.1 need GenerateEvents to disable this
        newExp = Expression.addNoEventToRelationsAndConds(newExp);
        ((newExp,(_,_,true))) = Expression.traverseExp(newExp,replaceArgs,(argmap,checkcr,true));
        // for inlinecalls in functions
        ((newExp1,(fns1,_,assrtLst))) = Expression.traverseExp(newExp,inlineCall,(fns,true,assrtLstIn));
      then
        ((newExp1,(fns,true,assrtLst)));

    case ((e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)),(fns,_,assrtLstIn)))
      // no assert detected
      equation
        false = Config.acceptMetaModelicaGrammar();
        true = DAEUtil.convertInlineTypeToBool(inlineType);
        true = checkInlineType(inlineType,fns);
        (fn,comment) = getFunctionBody(p,fns);
        // get inputs, body and output
        (crefs,{cr},stmts,repl) = getFunctionInputsOutputBody(fn,{},{},{},VarTransform.emptyReplacements());
        // merge statements to one line
        (repl,assrtStmts) = mergeFunctionBody(stmts,repl,{});
        true = List.isEmpty(assrtStmts);
        newExp = VarTransform.getReplacement(repl,cr);
        argmap = List.threadTuple(crefs,args);
        (argmap,checkcr) = extendCrefRecords(argmap,HashTableCG.emptyHashTable());
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        // add noEvent to avoid events as usually for functions
        // MSL 3.2.1 need GenerateEvents to disable this
        generateEvents = hasGenerateEventsAnnotation(comment);
        newExp = Debug.bcallret1(not generateEvents,Expression.addNoEventToRelationsAndConds,newExp,newExp);
        ((newExp,(_,_,true))) = Expression.traverseExp(newExp,replaceArgs,(argmap,checkcr,true));
        // for inlinecalls in functions
        ((newExp1,(fns1,_,assrtLst))) = Expression.traverseExp(newExp,inlineCall,(fns,true,assrtLstIn));
      then
        ((newExp1,(fns,true,assrtLst)));
        
    case ((e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)),(fns,_,assrtLstIn)))
      // assert detected
      equation
        false = Config.acceptMetaModelicaGrammar();
        true = DAEUtil.convertInlineTypeToBool(inlineType);
        true = checkInlineType(inlineType,fns);
        (fn,comment) = getFunctionBody(p,fns);
        // get inputs, body and output
        (crefs,{cr},stmts,repl) = getFunctionInputsOutputBody(fn,{},{},{},VarTransform.emptyReplacements());
        // merge statements to one line
        (repl,assrtStmts) = mergeFunctionBody(stmts,repl,{});
        true = List.isNotEmpty(assrtStmts);
        true = listLength(assrtStmts) == 1;
        assrt = listGet(assrtStmts,1);
        DAE.STMT_ASSERT(cond=cond, msg=msg, level=level, source=source) = assrt;
        newExp = VarTransform.getReplacement(repl,cr);  // the function that replaces the output variable
        argmap = List.threadTuple(crefs,args);
        (argmap,checkcr) = extendCrefRecords(argmap,HashTableCG.emptyHashTable());
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        // add noEvent to avoid events as usually for functions
        // MSL 3.2.1 need GenerateEvents to disable this
        generateEvents = hasGenerateEventsAnnotation(comment);
        newExp = Debug.bcallret1(not generateEvents,Expression.addNoEventToRelationsAndConds,newExp,newExp);
        ((newExp,(_,_,true))) = Expression.traverseExp(newExp,replaceArgs,(argmap,checkcr,true));
        assrt = inlineAssert(assrt,fns,argmap,checkcr);
        // for inlinecalls in functions
        ((newExp1,(fns1,_,assrtLst))) = Expression.traverseExp(newExp,inlineCall,(fns,true,assrt::assrtLstIn));
      then
        ((newExp1,(fns,true,assrtLst)));

    else inTuple;
  end matchcontinue;
end inlineCall;


protected function inlineAssert "inlines an assert.
author:Waurich TUD 2013-10"
  input DAE.Statement assrtIn;
  input Functiontuple fns;
  input list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
  input HashTableCG.HashTable checkcr;
  output DAE.Statement assrtOut;
protected
  DAE.ElementSource source;
  DAE.Exp cond, msg, level;
algorithm
  DAE.STMT_ASSERT(cond=cond, msg=msg, level=level, source=source) := assrtIn;  
  (cond,_,_,_) := inlineExp(cond,fns,source);
  ((cond,(_,_,true))) := Expression.traverseExp(cond,replaceArgs,(argmap,checkcr,true));
  //print("ASSERT inlined: "+&ExpressionDump.printExpStr(cond)+&"\n");
  (msg,_,_,_) := inlineExp(msg,fns,source);
  ((msg,(_,_,true))) := Expression.traverseExp(msg,replaceArgs,(argmap,checkcr,true));
  assrtOut := DAE.STMT_ASSERT(cond, msg, level, source);
end inlineAssert;


protected function hasGenerateEventsAnnotation
  input Option<SCode.Comment> comment;
  output Boolean b;
algorithm
  b := match(comment)
    local
      SCode.Annotation anno;
      list<SCode.Annotation> annos;
    case (SOME(SCode.COMMENT(annotation_=SOME(anno))))
      then
        SCode.hasBooleanNamedAnnotation({anno},"GenerateEvents");
    else then false;
  end match;
end hasGenerateEventsAnnotation;

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
"replaces an inline call with the expression from the function"
  input tuple<DAE.Exp, tuple<Functiontuple,Boolean,list<DAE.Statement>>> inTuple;
  output tuple<DAE.Exp, tuple<Functiontuple,Boolean,list<DAE.Statement>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      Functiontuple fns,fns1;
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      list<DAE.Statement> assrtStmts;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      DAE.Exp newExp,newExp1, e1;
      DAE.InlineType inlineType;
      DAE.Statement assrt;
      HashTableCG.HashTable checkcr;
      list<DAE.Statement> stmts, assrtLstIn, assrtLst;
      VarTransform.VariableReplacements repl;
      Boolean generateEvents,b;
      Option<SCode.Comment> comment;
    
    case ((e1 as DAE.CALL(p,args,DAE.CALL_ATTR(inlineType=inlineType)),(fns,_,assrtLstIn)))
      equation
        false = Config.acceptMetaModelicaGrammar();
        true = checkInlineType(inlineType,fns);
        (fn,comment) = getFunctionBody(p,fns);
        // get inputs, body and output
        (crefs,{cr},stmts,repl) = getFunctionInputsOutputBody(fn,{},{},{},VarTransform.emptyReplacements());
        // merge statements to one line
        (repl,assrtStmts) = mergeFunctionBody(stmts,repl,{});
        newExp = VarTransform.getReplacement(repl,cr);
        argmap = List.threadTuple(crefs,args);
        (argmap,checkcr) = extendCrefRecords(argmap,HashTableCG.emptyHashTable());
        // compare types
        true = checkExpsTypeEquiv(e1, newExp);
        // add noEvent to avoid events as usually for functions
        // MSL 3.2.1 need GenerateEvents to disable this
        generateEvents = hasGenerateEventsAnnotation(comment);
        newExp = Debug.bcallret1(not generateEvents,Expression.addNoEventToRelationsAndConds,newExp,newExp);
        ((newExp,(_,_,true))) = Expression.traverseExp(newExp,replaceArgs,(argmap,checkcr,true));
        // for inlinecalls in functions
        ((newExp1,(fns1,b,assrtLst))) = Expression.traverseExp(newExp,forceInlineCall,(fns,true,assrtLstIn));
      then
        ((newExp1,(fns,b,assrtLst)));
    
    else inTuple;
  end matchcontinue;
end forceInlineCall;

protected function mergeFunctionBody
  input list<DAE.Statement> iStmts;
  input VarTransform.VariableReplacements iRepl;
  input list<DAE.Statement> assertStmtsIn;
  output VarTransform.VariableReplacements oRepl;
  output list<DAE.Statement> assertStmtsOut;
algorithm
  (oRepl,assertStmtsOut) := match(iStmts,iRepl,assertStmtsIn)
    local
      list<DAE.Statement> stmts;
      VarTransform.VariableReplacements repl;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      DAE.Exp exp, exp1, exp2;
      DAE.Statement stmt;
      list<DAE.Exp> explst;
      list<DAE.Statement> assertStmts;
    case ({},_,_) then (iRepl,assertStmtsIn);
    case (DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = cr), exp = exp)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        repl = VarTransform.addReplacementNoTransitive(iRepl,cr,exp);
        (repl,assertStmts) = mergeFunctionBody(stmts,repl,assertStmtsIn);
      then
        (repl,assertStmts);
    case (DAE.STMT_ASSIGN_ARR(componentRef = cr, exp = exp)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        repl = VarTransform.addReplacementNoTransitive(iRepl,cr,exp);
        (repl,assertStmts) = mergeFunctionBody(stmts,repl,assertStmtsIn);
      then
        (repl,assertStmts);
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = explst, exp = exp)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        repl = addTplAssignToRepl(explst,1,exp,iRepl);
        (repl,assertStmts) = mergeFunctionBody(stmts,repl,assertStmtsIn);
      then
        (repl,assertStmts);
    case (DAE.STMT_ASSERT(cond = exp, msg = exp1, level = exp2, source = source)::stmts,_,_)
      equation
        (exp,_) = VarTransform.replaceExp(exp,iRepl,NONE());
        (exp1,_) = VarTransform.replaceExp(exp1,iRepl,NONE());
        (exp2,_) = VarTransform.replaceExp(exp2,iRepl,NONE());
        stmt = DAE.STMT_ASSERT(exp,exp1,exp2,source);
        (repl,assertStmts) = mergeFunctionBody(stmts,iRepl,stmt::assertStmtsIn);
      then
        (repl,assertStmts);
  end match;
end mergeFunctionBody;

protected function addTplAssignToRepl
  input list<DAE.Exp> explst;
  input Integer indx;
  input DAE.Exp iExp;
  input VarTransform.VariableReplacements iRepl;
  output VarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(explst,indx,iExp,iRepl)
    local
      VarTransform.VariableReplacements repl;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      list<DAE.Exp> rest;
      DAE.Type tp;
    case ({},_,_,_) then iRepl;
    case (DAE.CREF(componentRef = cr,ty=tp)::rest,_,_,_)
      equation
        exp = DAE.TSUB(iExp,indx,tp);
        repl = VarTransform.addReplacementNoTransitive(iRepl,cr,exp);
      then
        addTplAssignToRepl(rest,indx+1,iExp,repl);
  end match;
end addTplAssignToRepl;

protected function getFunctionInputsOutputBody
  input list<DAE.Element> fn;
  input list<DAE.ComponentRef> iInputs;
  input list<DAE.ComponentRef> iOutput;
  input list<DAE.Statement> iBody;
  input VarTransform.VariableReplacements iRepl;
  output list<DAE.ComponentRef> oInputs;
  output list<DAE.ComponentRef> oOutput;
  output list<DAE.Statement> oBody;
  output VarTransform.VariableReplacements oRepl;
algorithm
  (oInputs,oOutput,oBody,oRepl) := match(fn,iInputs,iOutput,iBody,iRepl)
    local
      DAE.ComponentRef cr;
      list<DAE.Statement> st;
      list<DAE.Element> rest;
      VarTransform.VariableReplacements repl;
      Option<DAE.Exp> binding;
      DAE.Type tp;
    case ({},_,_,_,_) then (listReverse(iInputs),listReverse(iOutput),iBody,iRepl);
    case (DAE.VAR(componentRef=cr,direction=DAE.INPUT())::rest,_,_,_,_)
      equation
         (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,cr::iInputs,iOutput,iBody,iRepl);
      then
        (oInputs,oOutput,oBody,repl);
    case (DAE.VAR(componentRef=cr,direction=DAE.OUTPUT())::rest,_,_,_,_)
      equation
        (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,iInputs,cr::iOutput,iBody,iRepl);
      then
        (oInputs,oOutput,oBody,repl);
    case (DAE.VAR(componentRef=cr,protection=DAE.PROTECTED(),ty=tp,binding=binding)::rest,_,_,_,_)
      equation
        false = Expression.isArrayType(tp);
        false = Expression.isRecordType(tp);
        repl = addOptBindingReplacements(cr,binding,iRepl);
        (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,iInputs,iOutput,iBody,repl);
      then
        (oInputs,oOutput,oBody,repl);
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(st))::rest,_,_,_,_)
      equation
        st = listAppend(iBody,st);
        (oInputs,oOutput,oBody,repl) = getFunctionInputsOutputBody(rest,iInputs,iOutput,st,iRepl);
      then
        (oInputs,oOutput,oBody,repl);
  end match;
end getFunctionInputsOutputBody;

protected function addOptBindingReplacements
  input DAE.ComponentRef cr;
  input Option<DAE.Exp> binding;
  input VarTransform.VariableReplacements iRepl;
  output VarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(cr,binding,iRepl)
    local
      DAE.Exp e;
    case (_,SOME(e),_) then addReplacement(cr, e, iRepl);
    case (_,NONE(),_) then iRepl;
  end match;
end addOptBindingReplacements;

protected function addReplacement
  input DAE.ComponentRef iCr;
  input DAE.Exp iExp;
  input VarTransform.VariableReplacements iRepl;
  output VarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(iCr,iExp,iRepl)
    local
      DAE.Type tp;
    case (DAE.CREF_IDENT(identType=tp),_,_)
      equation
        false = Expression.isArrayType(tp);
        false = Expression.isRecordType(tp);
      then VarTransform.addReplacement(iRepl, iCr, iExp);
  end match;
end addReplacement;

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
"extends crefs from records"
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
      /* All elements of the record have correct type already. No cast needed. */
    case((c,(DAE.CAST(exp=e,ty=DAE.T_COMPLEX(varLst=_))))::res,ht)
      equation
        (new1,ht1) = extendCrefRecords((c,e)::res,ht);
      then (new1,ht1);
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
    case((c,e as (DAE.RECORD(exps = expl,ty=DAE.T_COMPLEX(varLst=varLst))))::res,ht)
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
"helper for extendCrefRecords"
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

    case(DAE.TYPES_VAR(name=name,ty=tp),_,_)
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
"helper for extendCrefRecords"
  input DAE.Var ev;
  input DAE.ComponentRef c;
  output DAE.ComponentRef outArg;
algorithm
  outArg := matchcontinue(ev,c)
    local
      DAE.Type tp;
      String name;
      DAE.ComponentRef c1;

    case(DAE.TYPES_VAR(name=name,ty=tp),_)
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
"returns the body of a function"
  input Absyn.Path p;
  input Functiontuple fns;
  output list<DAE.Element> outfn;
  output Option<SCode.Comment> oComment;
algorithm
  (outfn,oComment) := matchcontinue(p,fns)
    local
      list<DAE.Element> body;
      DAE.FunctionTree ftree;
      Option<SCode.Comment> comment;
    case(_,(SOME(ftree),_))
      equation
        SOME(DAE.FUNCTION( functions = DAE.FUNCTION_DEF(body = body)::_,comment=comment)) = DAEUtil.avlTreeGet(ftree,p);
      then (body,comment);
    case(_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("Inline.getFunctionBody failed for function: " +& Absyn.pathString(p));
        // Error.addMessage(Error.INTERNAL_ERROR, {"Inline.getFunctionBody failed"});
      then
        fail();
  end matchcontinue;
end getFunctionBody;

protected function getRhsExp
"returns the right hand side of an assignment from a function"
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

protected function replaceArgs
"finds DAE.CREF and replaces them with new exps if the cref is in the argmap"
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
      Boolean tuple_,b, isImpure;
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
    case ((DAE.UNBOX(DAE.CALL(path,expLst,DAE.CALL_ATTR(_,tuple_,false,isImpure,inlineType,tc)),ty),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);
        (e as DAE.CREF(componentRef=cref)) = getExpFromArgMap(argmap,cref);
        path = ComponentReference.crefToPath(cref);
        expLst = List.map(expLst,Expression.unboxExp);
        b = Expression.isBuiltinFunctionReference(e);
        e = DAE.CALL(path,expLst,DAE.CALL_ATTR(ty,tuple_,b,isImpure,inlineType,tc));
        (e,_) = ExpressionSimplify.simplify(e);
      then
        ((e,(argmap,checkcr,true)));
    case ((e as DAE.UNBOX(DAE.CALL(path,expLst,DAE.CALL_ATTR(_,tuple_,false,_,inlineType,tc)),ty),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);
        _ = BaseHashTable.get(cref,checkcr);
      then
        ((e,(argmap,checkcr,false)));
        /* TODO: Use the inlineType of the function reference! */
    case((e as DAE.CALL(path,expLst,DAE.CALL_ATTR(DAE.T_METATYPE(ty = _),tuple_,false,isImpure,_,tc)),(argmap,checkcr,true)))
      equation
        cref = ComponentReference.pathToCref(path);
        (e as DAE.CREF(componentRef=cref,ty=ty)) = getExpFromArgMap(argmap,cref);
        path = ComponentReference.crefToPath(cref);
        expLst = List.map(expLst,Expression.unboxExp);
        b = Expression.isBuiltinFunctionReference(e);
        (ty2,inlineType) = functionReferenceType(ty);
        e = DAE.CALL(path,expLst,DAE.CALL_ATTR(ty2,tuple_,b,isImpure,inlineType,tc));
        e = boxIfUnboxedFunRef(e,ty);
        (e,_) = ExpressionSimplify.simplify(e);
      then ((e,(argmap,checkcr,true)));
    case((e as DAE.CALL(path,expLst,DAE.CALL_ATTR(DAE.T_METATYPE(ty = _),tuple_,false,_,_,tc)),(argmap,checkcr,true)))
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
"returns the exp from the given argmap with the given key"
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
        Debug.fprintln(Flags.FAILTRACE,"Inline.getExpFromArgMap failed with empty argmap and cref: " +& ComponentReference.printComponentRefStr(inComponentRef));
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
"returns the crefs of vars that are inputs, wild if not input"
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
"returns false if the given cref is a wild"
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
    case(DAE.BUILTIN_EARLY_INLINE()) then "Inline as soon as possible, even if inlining is globally disabled";
    case(DAE.NORM_INLINE()) then "Inline before index reduction";
  end matchcontinue;
end printInlineTypeStr;

public function simplifyAndInlineEquationExp "
  Takes a residual or equality equation, then
  simplifies, inlines and simplifies again
"
  input DAE.EquationExp inExp;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  output DAE.EquationExp exp;
  output DAE.ElementSource source;
algorithm
  (exp,source) := ExpressionSimplify.simplifyAddSymbolicOperation(inExp,inSource);
  (exp,source) := inlineEquationExp(exp,inlineCall,fns,source);
end simplifyAndInlineEquationExp;

public function simplifyAndForceInlineEquationExp "
  Takes a residual or equality equation, then
  simplifies, inlines and simplifies again
"
  input DAE.EquationExp inExp;
  input Functiontuple fns;
  input DAE.ElementSource inSource;
  output DAE.EquationExp exp;
  output DAE.ElementSource source;
algorithm
  (exp,source) := ExpressionSimplify.simplifyAddSymbolicOperation(inExp,inSource);
  (exp,source) := inlineEquationExp(exp,forceInlineCall,fns,source);
end simplifyAndForceInlineEquationExp;

public function inlineEquationExp "
  Takes a residual or equality equation, then
  simplifies, inlines and simplifies again
"
  input DAE.EquationExp inExp;
  input Func fn;
  input Functiontuple infns;
  input DAE.ElementSource inSource;
  output DAE.EquationExp outExp;
  output DAE.ElementSource source;
  partial function Func
    input tuple<DAE.Exp, tuple<Functiontuple,Boolean,list<DAE.Statement>>> inTuple;
    output tuple<DAE.Exp, tuple<Functiontuple,Boolean,list<DAE.Statement>>> outTuple;
  end Func;
  type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;
algorithm
  (outExp,source) := match (inExp,fn,infns,inSource)
    local
      Boolean changed;
      DAE.Exp e,e_1,e1,e1_1,e2,e2_1;
      DAE.EquationExp eq2;
      Functiontuple fns;
      list<DAE.Statement> assrtLst;
    case (DAE.PARTIAL_EQUATION(e),_,fns,_)
      equation
        ((e_1,(fns,changed,assrtLst))) = Expression.traverseExp(e,fn,(fns,false,{}));
        eq2 = DAE.PARTIAL_EQUATION(e_1);
        source = DAEUtil.condAddSymbolicTransformation(changed,inSource,DAE.OP_INLINE(inExp,eq2));
        (eq2,source) = ExpressionSimplify.condSimplifyAddSymbolicOperation(changed, eq2, source);
      then (eq2,source);
    case (DAE.RESIDUAL_EXP(e),_,fns,_)
      equation
        ((e_1,(fns,changed,assrtLst))) = Expression.traverseExp(e,fn,(fns,false,{}));
        eq2 = DAE.RESIDUAL_EXP(e_1);
        source = DAEUtil.condAddSymbolicTransformation(changed,inSource,DAE.OP_INLINE(inExp,eq2));
        (eq2,source) = ExpressionSimplify.condSimplifyAddSymbolicOperation(changed, eq2, source);
      then (eq2,source);
    case (DAE.EQUALITY_EXPS(e1,e2),_,fns,_)
      equation
        ((e1_1,(fns,changed,assrtLst))) = Expression.traverseExp(e1,fn,(fns,false,{}));
        ((e2_1,(fns,changed,assrtLst))) = Expression.traverseExp(e2,fn,(fns,changed,{}));
        eq2 = DAE.EQUALITY_EXPS(e1_1,e2_1);
        source = DAEUtil.condAddSymbolicTransformation(changed,inSource,DAE.OP_INLINE(inExp,eq2));
        (eq2,source) = ExpressionSimplify.condSimplifyAddSymbolicOperation(changed, eq2, source);
      then (eq2,source);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Inline.inlineEquationExp failed"});
      then fail();
  end match;
end inlineEquationExp;

end Inline;
