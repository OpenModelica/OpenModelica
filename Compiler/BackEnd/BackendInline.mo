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

encapsulated package BackendInline
" file:        BackendInline.mo
  package:     BackendInline
  description: inline functions


  This module contains data structures and functions for inline functions.

  The entry point is the inlineCalls function, or inlineCallsInFunctions
  "

public import BackendDAE;
public import DAE;
public import Inline;
public import SCode;
public import Values;

protected
 import BackendVarTransform;
 import BackendDAEUtil;
 import BackendDump;
 import BackendEquation;
 import BackendVariable;
 import BackendDAEOptimize;
 import ComponentReference;
 import Debug;
 import DAEDump;
 import DAEUtil;
 import ExpressionDump;
 import Flags;
 import InlineArrayEquations;
 import List;

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
// normal inline functions stuff
//
// =============================================================================
public function normalInlineFunction
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if Flags.getConfigEnum(Flags.INLINE_METHOD) == 1 then
    outDAE := inlineCalls({DAE.NORM_INLINE()}, inDAE);
  else
    outDAE := inlineCallsBDAE({DAE.NORM_INLINE()}, inDAE);
  end if;
end normalInlineFunction;

// =============================================================================
// inline calls stuff
//
// =============================================================================

protected function inlineCalls
"searches for calls where the inline flag is true, and inlines them"
  input list<DAE.InlineType> inITLst;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  list<DAE.InlineType> itlst;
  Inline.Functiontuple tpl;
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
algorithm
  try
    shared := inBackendDAE.shared;
    eqs := inBackendDAE.eqs;
    tpl := (SOME(shared.functionTree), inITLst);
    eqs := List.map1(eqs, inlineEquationSystem, tpl);
    shared.globalKnownVars := inlineVariables(shared.globalKnownVars, tpl);
    shared.externalObjects := inlineVariables(shared.externalObjects, tpl);
    shared.initialEqs := inlineEquationArray(shared.initialEqs, tpl);
    shared.removedEqs := inlineEquationArray(shared.removedEqs, tpl);
    inlineEventInfo(shared.eventInfo, tpl);
    outBackendDAE := BackendDAE.DAE(eqs, shared);
  else
    if Flags.isSet(Flags.FAILTRACE) then
        Debug.traceln("BackendInline.inlineCalls failed");
    end if;
    fail();
  end try;
end inlineCalls;

protected function inlineEquationSystem
  input BackendDAE.EqSystem eqs;
  input Inline.Functiontuple tpl;
  output BackendDAE.EqSystem oeqs = eqs;
algorithm
  inlineVariables(oeqs.orderedVars, tpl);
  inlineEquationArray(oeqs.orderedEqs, tpl);
  inlineEquationArray(oeqs.removedEqs, tpl);
end inlineEquationSystem;

protected function inlineEquationArray "
function: inlineEquationArray
  inlines function calls in an equation array"
  input BackendDAE.EquationArray inEquationArray;
  input Inline.Functiontuple inElementList;
  output BackendDAE.EquationArray outEquationArray;
  output Boolean oInlined;
algorithm
  (outEquationArray,oInlined) := matchcontinue(inEquationArray,inElementList)
    local
      Inline.Functiontuple fns;
      Integer i1,size;
      array<Option<BackendDAE.Equation>> eqarr;
    case(BackendDAE.EQUATION_ARRAY(size,i1,eqarr),fns)
      equation
        oInlined = inlineEquationOptArray(eqarr,fns);
      then
        (BackendDAE.EQUATION_ARRAY(size,i1,eqarr),oInlined);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.inlineEquationArray failed\n");
      then
        fail();
  end matchcontinue;
end inlineEquationArray;

protected function inlineEquationOptArray
"functio: inlineEquationrOptArray
  inlines calls in a equation option"
  input array<Option<BackendDAE.Equation>> inEqnArray;
  input Inline.Functiontuple fns;
  output Boolean oInlined = false;
protected
  Option<BackendDAE.Equation> eqn;
  Boolean inlined;
algorithm
  for i in 1:arrayLength(inEqnArray) loop
    (eqn, inlined) := inlineEqOpt(inEqnArray[i], fns);

    if inlined then
      arrayUpdate(inEqnArray, i, eqn);
      oInlined := true;
    end if;
  end for;
end inlineEquationOptArray;

public function inlineEqOpt "
function: inlineEqOpt
  inlines function calls in equations"
  input Option<BackendDAE.Equation> inEquationOption;
  input Inline.Functiontuple inElementList;
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

protected function inlineEq "
  inlines function calls in equations"
  input BackendDAE.Equation inEquation;
  input Inline.Functiontuple fns;
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
      Boolean b1,b2,b3;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes attr;

    case(BackendDAE.EQUATION(e1,e2,source,attr),_)
      equation
        (e1_1,source,b1,_) = Inline.inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = Inline.inlineExp(e2,fns,source);
        true = b1 or b2;
      then
       (BackendDAE.EQUATION(e1_1,e2_1,source,attr),true);

    case(BackendDAE.ARRAY_EQUATION(dimSize,e1,e2,source,attr),_)
      equation
        (e1_1,source,b1,_) = Inline.inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = Inline.inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e1_1,e2_1,source,attr),true);

    case(BackendDAE.SOLVED_EQUATION(cref,e,source,attr),_)
      equation
        (e_1,source,true,_) = Inline.inlineExp(e,fns,source);
      then
        (BackendDAE.SOLVED_EQUATION(cref,e_1,source,attr),true);

    case(BackendDAE.RESIDUAL_EQUATION(e,source,attr),_)
      equation
        (e_1,source,true,_) = Inline.inlineExp(e,fns,source);
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source,attr),true);

    case(BackendDAE.ALGORITHM(size,alg as DAE.ALGORITHM_STMTS(statementLst=stmts),source,crefExpand,attr),_)
      equation
        (stmts1,true) = Inline.inlineStatements(stmts,fns,{},false);
        alg = DAE.ALGORITHM_STMTS(stmts1);
      then
        (BackendDAE.ALGORITHM(size,alg,source,crefExpand,attr),true);

    case(BackendDAE.WHEN_EQUATION(size,weq,source,attr),_)
      equation
        (weq_1,source,true) = inlineWhenEq(weq,fns,source);
      then
        (BackendDAE.WHEN_EQUATION(size,weq_1,source,attr),true);

    case(BackendDAE.COMPLEX_EQUATION(size,e1,e2,source,attr),_)
      equation
        (e1_1,source,b1,_) = Inline.inlineExp(e1,fns,source);
        (e2_1,source,b2,_) = Inline.inlineExp(e2,fns,source);
        true = b1 or b2;
      then
        (BackendDAE.COMPLEX_EQUATION(size,e1_1,e2_1,source,attr),true);

    case(BackendDAE.IF_EQUATION(explst,eqnslst,eqns,source,attr),_)
      equation
        (explst,source,b1) = Inline.inlineExps(explst,fns,source);
        (eqnslst,b2) = inlineEqsLst(eqnslst,fns,{},false);
        (eqns,b3) = inlineEqs(eqns,fns,{},false);
        true = b1 or b2 or b3;
      then
        (BackendDAE.IF_EQUATION(explst,eqnslst,eqns,source,attr),true);
    else
      then
        (inEquation,false);
  end matchcontinue;
end inlineEq;

protected function inlineEqsLst
  input list<list<BackendDAE.Equation>> inEqnsList;
  input Inline.Functiontuple inFunctions;
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
  input Inline.Functiontuple inFunctions;
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
  input Inline.Functiontuple fns;
  input DAE.ElementSource inSource;
  output BackendDAE.WhenEquation outWhenEquation;
  output DAE.ElementSource outSource;
  output Boolean inlined;
algorithm
  (outWhenEquation,outSource,inlined) := match(inWhenEquation)
    local
      DAE.ComponentRef cref;
      DAE.Exp e,e_1,cond;
      BackendDAE.WhenEquation weq,weq_1;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      list<DAE.Statement> assrtLst;
      BackendDAE.WhenEquation we, elsewe;
      Option<BackendDAE.WhenEquation> oelsewe;
      list<BackendDAE.WhenOperator> whenStmtLst;

    case BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst=whenStmtLst, elsewhenPart = oelsewe)
      equation
        (cond, source, b1,_) = Inline.inlineExp(cond, fns, inSource);
        (whenStmtLst, b2) = inlineWhenOps(whenStmtLst, fns);

        if isSome(oelsewe) then
          SOME(elsewe) = oelsewe;
          (elsewe, source, b3) = inlineWhenEq(elsewe, fns, source);
          oelsewe = SOME(elsewe);
        else
          oelsewe = NONE();
          b3 = false;
        end if;
      then (BackendDAE.WHEN_STMTS(cond, whenStmtLst, oelsewe), source, b1 or b2 or b3);

  end match;
end inlineWhenEq;

protected function inlineWhenOps
  input list<BackendDAE.WhenOperator> inWhenOps;
  input Inline.Functiontuple fns;
  output list<BackendDAE.WhenOperator> outWhenOps = {};
  output Boolean inlined = false;
protected

algorithm
  for whenOp in inWhenOps loop
    _ := match (whenOp)
    local
      Boolean b, b2;
      DAE.Exp e1, e2, level;
      DAE.ComponentRef cr;
      list<BackendDAE.WhenOperator> rest;
      DAE.ElementSource source;

    case BackendDAE.ASSIGN(left = e1, right = e2, source = source)
      equation
        (e2, source, b,_) = Inline.inlineExp(e2, fns, source);
        outWhenOps = (if b then BackendDAE.ASSIGN(e1, e2, source) else whenOp)::outWhenOps;
        inlined = inlined or b;
      then ();

    case BackendDAE.REINIT(stateVar = cr, value = e2,  source = source)
      equation
        (e2, source, b,_) = Inline.inlineExp(e2, fns, source);
        outWhenOps = (if b then BackendDAE.REINIT(cr, e2, source) else whenOp)::outWhenOps;
        inlined = inlined or b;
      then ();

    case BackendDAE.ASSERT(condition = e1, message = e2, level = level,  source = source)
      equation
        (e1, source, b,_) = Inline.inlineExp(e1, fns, source);
        (e2, source, b2,_) = Inline.inlineExp(e2, fns, source);
        outWhenOps = (if b or b2 then BackendDAE.ASSERT(e1, e2, level, source) else whenOp)::outWhenOps;
        inlined = inlined or b or b2;
      then ();

    case BackendDAE.TERMINATE(message = e1,  source = source)
      equation
        (e1, source, b,_) = Inline.inlineExp(e1, fns, source);
        outWhenOps = (if b then BackendDAE.TERMINATE(e1, source) else whenOp)::outWhenOps;
        inlined = inlined or b;
      then ();

    case BackendDAE.NORETCALL(exp = e1,  source = source)
      equation
        (e1, source, b,_) = Inline.inlineExp(e1, fns, source);
        outWhenOps = (if b then BackendDAE.NORETCALL(e1, source) else whenOp)::outWhenOps;
        inlined = inlined or b;
      then ();
  end match;
  end for;
end inlineWhenOps;

protected function inlineVariables
"inlines function calls in variables"
  input BackendDAE.Variables inVariables;
  input Inline.Functiontuple inElementList;
  output BackendDAE.Variables outVariables;
  output Boolean inlined;
algorithm
  (outVariables,inlined) := matchcontinue(inVariables,inElementList)
    local
      Inline.Functiontuple fns;
      array<list<BackendDAE.CrefIndex>> crefind;
      Integer i1,i2,i3;
      array<Option<BackendDAE.Var>> vararr;
    case(BackendDAE.VARIABLES(crefind,BackendDAE.VARIABLE_ARRAY(i3,vararr),i1,i2),fns)
      equation
        inlined = inlineVarOptArray(vararr,fns);
      then
        (BackendDAE.VARIABLES(crefind,BackendDAE.VARIABLE_ARRAY(i3,vararr),i1,i2),inlined);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.inlineVariables failed\n");
      then
        fail();
  end matchcontinue;
end inlineVariables;

protected function inlineVarOptArray
"function: inlineVarOptArray
  inlines calls in a variable option"
  input array<Option<BackendDAE.Var>> inVarArray;
  input Inline.Functiontuple fns;
  output Boolean oInlined = false;
protected
  Boolean b;
  Option<BackendDAE.Var> var;
algorithm
  for index in 1:arrayLength(inVarArray) loop
    var := inVarArray[index];
    (var,b) := inlineVarOpt(var,fns);
    if b then
      arrayUpdate(inVarArray,index,var);
    end if;
    oInlined := oInlined or b;
  end for;
end inlineVarOptArray;

protected function inlineVarOpt
"functio: inlineVarOpt
  inlines calls in a variable option"
  input Option<BackendDAE.Var> inVarOption;
  input Inline.Functiontuple fns;
  output Option<BackendDAE.Var> outVarOption;
  output Boolean inlined;
algorithm
  (outVarOption,inlined) := match(inVarOption,fns)
    local
      BackendDAE.Var var,var2;
      Boolean b;
    case(NONE(),_) then (NONE(),false);
    case(SOME(var),_)
      equation
        (var2,b) = inlineVar(var,fns);
      then
        (if referenceEq(var, var2) then inVarOption else SOME(var2),b);
  end match;
end inlineVarOpt;

protected function inlineVar
"functio: inlineVar
  inlines calls in a variable"
  input BackendDAE.Var inVar;
  input Inline.Functiontuple inElementList;
  output BackendDAE.Var outVar;
  output Boolean inlined;
algorithm
  (outVar, inlined) := match(inVar)
    local
      DAE.ComponentRef varName;
      BackendDAE.VarKind varKind;
      DAE.VarDirection varDirection;
      DAE.VarParallelism varParallelism;
      BackendDAE.Type varType;
      Option<Values.Value> bindValue;
      DAE.InstDims arrayDim;
      Option<DAE.VariableAttributes> values,values1;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      Option<DAE.Exp> bind;
      Boolean b1,b2;
      DAE.VarInnerOuter io;
      Boolean unreplaceable;

    case BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,bind,bindValue,arrayDim,source,values,ts,hideResult,comment,ct,io,unreplaceable) equation
      (bind,source,b1) = Inline.inlineExpOpt(bind,inElementList,source);
      (values1,source,b2) = Inline.inlineStartAttribute(values,source,inElementList);
    then (BackendDAE.VAR(varName,varKind,varDirection,varParallelism,varType,bind,bindValue,arrayDim,source,values1,ts,hideResult,comment,ct,io,unreplaceable), b1 or b2);

    else (inVar, false);
  end match;
end inlineVar;

protected function inlineEventInfo "inlines function calls in event info"
  input BackendDAE.EventInfo inEventInfo;
  input Inline.Functiontuple fns;
algorithm
  _ := matchcontinue inEventInfo
    local
      BackendDAE.ZeroCrossingSet zclst;
      DoubleEndedList<BackendDAE.ZeroCrossing> relations;

    case BackendDAE.EVENT_INFO(zeroCrossings=zclst, relations=relations) equation
      inlineZeroCrossings(zclst.zc, fns);
      inlineZeroCrossings(relations, fns);
    then ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("Inline.inlineEventInfo failed\n");
      then fail();
  end matchcontinue;
end inlineEventInfo;

protected function inlineZeroCrossings "inlines function calls in zero crossings"
  input DoubleEndedList<BackendDAE.ZeroCrossing> inStmts;
  input Inline.Functiontuple fns;
protected
  BackendDAE.ZeroCrossing zc;
algorithm
  DoubleEndedList.mapNoCopy_1(inStmts, inlineZeroCrossing, fns);
end inlineZeroCrossings;

protected function inlineZeroCrossing "inlines function calls in a zero crossing"
  input output BackendDAE.ZeroCrossing zc;
  input Inline.Functiontuple fns;
algorithm
  zc := match zc
    local
      DAE.Exp e, e_1;
      list<Integer> ilst1;
      Boolean b;

    case BackendDAE.ZERO_CROSSING(e, ilst1)
      equation
        (e_1, _, b, _) = Inline.inlineExp(e, fns, DAE.emptyElementSource/*TODO: Propagate operation info*/);
      then if not referenceEq(e,e_1) then BackendDAE.ZERO_CROSSING(e_1, ilst1) else zc;

    else zc;
  end match;
end inlineZeroCrossing;

// =============================================================================
// inline append functions
//
// =============================================================================

protected function inlineCallsBDAE
"searches for calls where the inline flag is true, and inlines them"
  input list<DAE.InlineType> inITLst;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  list<DAE.InlineType> itlst;
  Inline.Functiontuple tpl;
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
algorithm
  try

    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      if Flags.getConfigEnum(Flags.INLINE_METHOD) == 1 then
        print("\n############ BackendInline Method: replace ############");
      elseif Flags.getConfigEnum(Flags.INLINE_METHOD) == 2 then
        print("\n############ BackendInline Method: append ############");
      end if;
    end if;

    shared := inBackendDAE.shared;
    eqs := inBackendDAE.eqs;
    tpl := (SOME(shared.functionTree), inITLst);
    if Flags.getConfigEnum(Flags.INLINE_METHOD) == 1 then
      eqs := List.map1(eqs, BackendInline.inlineEquationSystem, tpl);
    elseif Flags.getConfigEnum(Flags.INLINE_METHOD) == 2 then
      eqs := List.map2(eqs, inlineEquationSystemAppend, tpl, shared);
    end if;
    if Flags.isSet(Flags.DUMPBACKENDINLINE) then
      BackendDump.dumpEqSystems(eqs, "Result DAE after Inline.");
    end if;
    // TODO: use new BackendInline also for other parts
    shared.globalKnownVars := BackendInline.inlineVariables(shared.globalKnownVars, tpl);
    shared.externalObjects := BackendInline.inlineVariables(shared.externalObjects, tpl);
    shared.initialEqs := BackendInline.inlineEquationArray(shared.initialEqs, tpl);
    shared.removedEqs := BackendInline.inlineEquationArray(shared.removedEqs, tpl);

    outBackendDAE := BackendDAE.DAE(eqs, shared);
  else
    if Flags.isSet(Flags.FAILTRACE) then
        Debug.traceln("BackendInline.inlineCallsBDAE failed");
    end if;
    fail();
  end try;

  // fix "tuple = tuple" expression after inline functions
  outBackendDAE := BackendDAEOptimize.simplifyComplexFunction1(outBackendDAE, false);
end inlineCallsBDAE;


protected function inlineEquationSystemAppend
  input BackendDAE.EqSystem eqs;
  input Inline.Functiontuple tpl;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem oeqs = eqs;
protected
  BackendDAE.Shared shared = ishared;
  BackendDAE.EqSystem new;
  Boolean inlined=true;
  BackendDAE.EquationArray eqnsArray;
algorithm
  //inlineVariables(oeqs.orderedVars, tpl);
  (eqnsArray, new, inlined, shared) := inlineEquationArrayAppend(oeqs.orderedEqs, tpl, shared);
  //inlineEquationArray(oeqs.removedEqs, tpl);
  if inlined then
    oeqs.orderedEqs := eqnsArray;
    new := inlineEquationSystemAppend(new, tpl, shared);
    oeqs := BackendDAEUtil.mergeEqSystems(new, oeqs);
  end if;
end inlineEquationSystemAppend;

protected function inlineEquationArrayAppend "
function: inlineEquationArray
  inlines function calls in an equation array"
  input BackendDAE.EquationArray inEquationArray;
  input Inline.Functiontuple fns;
  input BackendDAE.Shared iShared;
  output BackendDAE.EquationArray outEquationArray;
  output BackendDAE.EqSystem outEqs;
  output Boolean oInlined;
  output BackendDAE.Shared shared = iShared;
protected
  Integer i1,size;
  array<Option<BackendDAE.Equation>> eqarr;
algorithm
  try
    BackendDAE.EQUATION_ARRAY(size,i1,eqarr) := inEquationArray;
    (outEqs, oInlined, shared) := inlineEquationOptArrayAppend(inEquationArray, fns, shared);
    outEquationArray := BackendDAE.EQUATION_ARRAY(size,i1,eqarr);
 else
   if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("BackendInline.inlineEquationArrayAppend failed\n");
   end if;
 end try;

end inlineEquationArrayAppend;

protected function inlineEquationOptArrayAppend
"functio: inlineEquationrOptArray
  inlines calls in a equation option"
  input BackendDAE.EquationArray inEqnArray;
  input Inline.Functiontuple fns;
  input BackendDAE.Shared iShared;
  output BackendDAE.EqSystem outEqs;
  output Boolean oInlined = false;
  output BackendDAE.Shared shared = iShared;
protected
  Option<BackendDAE.Equation> eqn;
  Boolean inlined;
  BackendDAE.EqSystem tmpEqs;
algorithm
  outEqs := BackendDAEUtil.createEqSystem( BackendVariable.listVar({}), BackendEquation.listEquation({}));
  for i in 1:inEqnArray.numberOfElement loop
    (eqn, tmpEqs, inlined, shared) := inlineEqOptAppend(inEqnArray.equOptArr[i], fns, shared);
    if inlined then
      outEqs := BackendDAEUtil.mergeEqSystems(tmpEqs, outEqs);
      arrayUpdate(inEqnArray.equOptArr, i, eqn);
      oInlined := true;
    end if;
  end for;
end inlineEquationOptArrayAppend;

public function inlineEqOptAppend "
function: inlineEqOpt
  inlines function calls in equations"
  input Option<BackendDAE.Equation> inEquationOption;
  input Inline.Functiontuple inElementList;
  input BackendDAE.Shared iShared;
  output Option<BackendDAE.Equation> outEquationOption;
  output BackendDAE.EqSystem outEqs;
  output Boolean inlined;
  output BackendDAE.Shared shared = iShared;
protected
  BackendDAE.Equation eqn, eqn1;
algorithm
  outEqs := BackendDAEUtil.createEqSystem( BackendVariable.listVar({}), BackendEquation.listEquation({}));
  if isSome(inEquationOption) then
     SOME(eqn) := inEquationOption;
     (eqn1,outEqs,inlined,shared) := inlineEqAppend(eqn,inElementList,outEqs,shared);

     // debug
     if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) and inlined then
       print("Equation before inline: "+BackendDump.equationString(eqn)+"\n");
       BackendDump.dumpEqSystem(outEqs, "Tmp DAE after Inline Eqn: "+BackendDump.equationString(eqn1)+"\n");
     end if;
     outEquationOption  := SOME(eqn1);
  else
    outEquationOption := NONE();
    inlined := false;
  end if;
end inlineEqOptAppend;

protected function inlineEqAppend "
  inlines function calls in equations"
  input BackendDAE.Equation inEquation;
  input Inline.Functiontuple fns;
  input BackendDAE.EqSystem inEqs;
  input BackendDAE.Shared iShared;
  output BackendDAE.Equation outEquation;
  output BackendDAE.EqSystem outEqs;
  output Boolean inlined;
  output BackendDAE.Shared shared = iShared;
algorithm
  (outEquation,outEqs,inlined) := matchcontinue(inEquation)
    local
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      Boolean b1,b2,b3;
      BackendDAE.EquationAttributes attr;
      BackendDAE.Equation eqn;
      Integer size;
      list<DAE.Exp> explst;
      DAE.ComponentRef cref;
      BackendDAE.WhenEquation weq,weq_1;
      list<DAE.Statement> stmts, stmts1;
      DAE.Expand crefExpand;
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns;

    case BackendDAE.EQUATION(e1,e2,source,attr)
      equation
        (e1,source,outEqs,b1,shared) = inlineCallsAppend(e1,fns,source,inEqs,shared);
        (e2,source,outEqs,b2,shared) = inlineCallsAppend(e2,fns,source,outEqs,shared);
        b3 = b1 or b2;
      then
        (BackendEquation.generateEquation(e1,e2,source,attr),outEqs,b3);

    case BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=attr)
      equation
        (e1,source,outEqs,b1,shared) = inlineCallsAppend(e1,fns,source,inEqs,shared);
        (e2,source,outEqs,b2,shared) = inlineCallsAppend(e2,fns,source,outEqs,shared);
        b3 = b1 or b2;
        if b2 and Expression.isScalar(e1) and Expression.isTuple(e2) then
          e2 = DAE.TSUB(e2, 1, Expression.typeof(e1));
        end if;
      then
        (BackendEquation.generateEquation(e1,e2,source,attr),outEqs,b3);

    case BackendDAE.ARRAY_EQUATION(left=e1, right=e2, source=source, attr=attr)
      equation
        (e1,source,outEqs,b1,shared) = inlineCallsAppend(e1,fns,source,inEqs,shared);
        (e2,source,outEqs,b2,shared) = inlineCallsAppend(e2,fns,source,outEqs,shared);
         b3 = b1 or b2;
      then
        (BackendEquation.generateEquation(e1,e2,source,attr),outEqs,b3);

     case BackendDAE.SOLVED_EQUATION(cref,e2,source,attr)
       equation
       (e2,source,outEqs,b2,shared) = inlineCallsAppend(e2,fns,source,inEqs,shared);
       then
        (BackendDAE.SOLVED_EQUATION(cref,e2,source,attr),outEqs,b2);

     case BackendDAE.RESIDUAL_EQUATION(e1,source,attr)
       equation
       (e1,source,outEqs,b1,shared) = inlineCallsAppend(e1,fns,source,inEqs,shared);
     then
       (BackendDAE.RESIDUAL_EQUATION(e1,source,attr),outEqs,b1);

      case eqn as BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(statementLst=stmts),source,crefExpand,attr)
      equation
        (stmts1,b1) = Inline.inlineStatements(stmts,fns,{},false);
        if b1 then
          eqn = BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS(stmts1),source,crefExpand,attr);
        end if;
      then
        (eqn,inEqs,b1);

     case eqn as BackendDAE.WHEN_EQUATION(size,weq,source,attr)
      equation
        (weq_1,source,b1) = inlineWhenEq(weq,fns,source);
        if b1 then
           eqn = BackendDAE.WHEN_EQUATION(size,weq_1,source,attr);
        end if;
      then
        (eqn,inEqs, b1);

     case eqn as BackendDAE.IF_EQUATION(explst,eqnslst,eqns,source,attr)
      equation
        (explst,source,b1) = Inline.inlineExps(explst,fns,source);
        (eqnslst,b2) = inlineEqsLst(eqnslst,fns,{},false);
        (eqns,b3) = inlineEqs(eqns,fns,{},false);
        b3 = b1 or b2 or b3;
        if b3 then
          eqn = BackendDAE.IF_EQUATION(explst,eqnslst,eqns,source,attr);
        end if;
      then
        (eqn, inEqs, b3);

     else (inEquation,inEqs,false);

  end matchcontinue;
end inlineEqAppend;

protected function inlineCallsAppend "
function: inlineCalls
  inlines calls in a DAE.Exp"
  input DAE.Exp inExp;
  input Inline.Functiontuple fns;
  input DAE.ElementSource inSource;
  input BackendDAE.EqSystem inEqs;
  input BackendDAE.Shared iShared;
  output DAE.Exp outExp;
  output DAE.ElementSource outSource;
  output BackendDAE.EqSystem outEqs;
  output Boolean inlined;
  output BackendDAE.Shared shared = iShared;
algorithm
  (outExp,outSource,outEqs,inlined) := matchcontinue (inExp)
    local
      DAE.Exp e,e1,e2;
      DAE.ElementSource source;
      list<DAE.Statement> assrtLst;
      Boolean b;

    case (e)
      equation
        (e1,(_,outEqs,b,_)) = Expression.traverseExpBottomUp(e,inlineCallsWork,(fns,inEqs,false,false));
        //source = DAEUtil.addSymbolicTransformation(b, inSource,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e1)));
        source = inSource;
        e2 = e1;
        //(DAE.PARTIAL_EQUATION(e2),source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e1), source);
        // debug
        if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
          print("\ninExp: " + ExpressionDump.printExpStr(inExp));
          print("\noutExp: " + ExpressionDump.printExpStr(e2));
        end if;
      then
        (e2,source,outEqs,b);

    else (inExp,inSource,inEqs,false);
  end matchcontinue;
end inlineCallsAppend;

protected function inlineCallsWork
"replaces an expression call with the statements from the function"
  input DAE.Exp inExp;
  input tuple<Inline.Functiontuple,BackendDAE.EqSystem,Boolean,Boolean> inTuple;
  output DAE.Exp outExp;
  output tuple<Inline.Functiontuple,BackendDAE.EqSystem,Boolean,Boolean> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      Inline.Functiontuple fns,fns1;
      list<DAE.Element> fn;
      Absyn.Path p;
      list<DAE.Exp> args;
      list<DAE.ComponentRef> outputCrefs;
      list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
      list<DAE.ComponentRef> lst_cr;
      DAE.ElementSource source;
      DAE.Exp newExp,newExp1, e1, cond, msg, level, newAssrtCond, newAssrtMsg, newAssrtLevel, e2, e3;
      DAE.InlineType inlineType;
      DAE.Statement assrt;
      HashTableCG.HashTable checkcr;
      list<DAE.Statement> stmts,assrtStmts, assrtLstIn, assrtLst;
      Boolean generateEvents, b, b1;
      Boolean inCoplexFunction, inArrayEq;
      Option<SCode.Comment> comment;
      DAE.Type ty;
      String funcname;
      BackendDAE.EqSystem eqSys, newEqSys;
      Boolean insideIfExp;

    case (e1 as DAE.IFEXP(), (fns,eqSys,b,insideIfExp))
      then fail();

    case (DAE.CALL(attr=DAE.CALL_ATTR(builtin=true)),_)
      then (inExp,inTuple);

    case (e1 as DAE.CALL(p,args,DAE.CALL_ATTR(ty=ty,inlineType=inlineType)),(fns,eqSys,b,false))
    guard Inline.checkInlineType(inlineType,fns) and Flags.getConfigEnum(Flags.INLINE_METHOD)==2
      equation
        (fn,comment) = Inline.getFunctionBody(p,fns);
        funcname = Util.modelicaStringToCStr(Absyn.pathString(p), false);
        if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
          print("Inline Function " +funcname+" type: "+DAEDump.dumpInlineTypeStr(inlineType)+"\n");
          print("in : " + ExpressionDump.printExpStr(inExp) + "\n");
        end if;

        // get inputs, body and output
        (outputCrefs, newEqSys) = createEqnSysfromFunction(fn,args,funcname);
        newExp = Expression.makeTuple(list( Expression.crefExp(cr) for cr in outputCrefs));
        if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
          print("out: " + ExpressionDump.printExpStr(newExp) + "\n");
        end if;

        // MSL 3.2.1 need GenerateEvents to disable this
        if not Inline.hasGenerateEventsAnnotation(comment) then
          _ = BackendDAEUtil.traverseBackendDAEExpsEqSystemWithUpdate(newEqSys, addNoEvent, false);
        end if;
        newEqSys = BackendDAEUtil.mergeEqSystems(newEqSys, eqSys);
      then
        (newExp,(fns,newEqSys,true,false));

    //fallback use old implementation
    case (e1 as DAE.CALL(p,args,DAE.CALL_ATTR(ty=ty,inlineType=inlineType)),(fns,eqSys,b,insideIfExp))
      equation
        //TODO sace assertLst
        (newExp, _) = Inline.inlineCall(inExp, {}, fns);

        if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
          funcname = Util.modelicaStringToCStr(Absyn.pathString(p), false);
          print("\nBackendInline fallback replace implementation: " +funcname+" type: " +DAEDump.dumpInlineTypeStr(inlineType)+"\n");
          print("in : " + ExpressionDump.printExpStr(inExp) + "\n");
          print("out: " + ExpressionDump.printExpStr(newExp) + "\n");
        end if;
      then (newExp,(fns,eqSys,b,insideIfExp));

    else (inExp,inTuple);
  end matchcontinue;
end inlineCallsWork;

function addNoEvent
  input DAE.Exp inExp;
  input Boolean inB;
  output DAE.Exp outExp;
  output Boolean outB = inB;
algorithm
  outExp := Expression.addNoEventToRelationsAndConds(inExp);
  outExp := Expression.addNoEventToEventTriggeringFunctions(outExp);
end addNoEvent;

protected function createReplacementVariables
  input DAE.ComponentRef inCref;
  input String funcName;
  input BackendVarTransform.VariableReplacements inRepls;
  output DAE.ComponentRef crVar;
  output list<BackendDAE.Var> outVars = {};
  output BackendVarTransform.VariableReplacements outRepls = inRepls;
protected
  DAE.Exp eVar, e;
  list<DAE.Exp> arrExp;
  list<DAE.ComponentRef> crefs, crefs1;
  DAE.ComponentRef cr;
  BackendDAE.Var var;
algorithm
  // create variable and expression from cref
  var := BackendVariable.createTmpVar(inCref, funcName);
  crVar := BackendVariable.varCref(var);
  eVar := Expression.crefExp(crVar);

  //TODO: handle record cases
  false := Expression.isRecord(eVar);

  // create top-level replacement
  outRepls := BackendVarTransform.addReplacement(outRepls, inCref, eVar, NONE());

  // handle array cases for replacements
  crefs := ComponentReference.expandCref(inCref, false);
  crefs1 := ComponentReference.expandCref(crVar, false);
  try
    arrExp := Expression.getArrayOrRangeContents(eVar);
  else
    arrExp := {eVar};
  end try;

  // error handling
  if listLength(crefs) <> listLength(arrExp) then
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.traceln("BackendInline.createReplacementVariables failed with array handling "+ExpressionDump.printExpStr(eVar)+"\n");
    end if;
    fail();
  end if;

  // add every array scalar to replacements
  for c in crefs loop
    cr :: crefs1 := crefs1;
    e :: arrExp := arrExp;
    var.varName := cr;
    outVars := var::outVars;
    outRepls := BackendVarTransform.addReplacement(outRepls, c, e, NONE());
  end for;
  outVars := listReverse(outVars);
end createReplacementVariables;

protected function createEqnSysfromFunction
  input list<DAE.Element> fns;
  input list<DAE.Exp> inArgs;
  input String funcname;
  output list<DAE.ComponentRef> oOutput = {};
  output BackendDAE.EqSystem outEqs;
protected
  list<DAE.Exp> args = inArgs, left_lst;
  BackendVarTransform.VariableReplacements repl;
  list<DAE.ComponentRef> fnInputs = {};
  DAE.Type tp;
  list<tuple<DAE.ComponentRef, DAE.Exp>> argmap;
  HashTableCG.HashTable checkcr;
  DAE.ComponentRef cr;
  BackendDAE.Var var;
  BackendDAE.IncidenceMatrix m;
  array<Integer> ass1, ass2;
  list<BackendDAE.Equation> eqlst;
algorithm
  if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
    print("\ncreate EqnSys from function: "+funcname);
  end if;
  outEqs := BackendDAEUtil.createEqSystem( BackendVariable.listVar({}), BackendEquation.listEquation({}));
  repl := BackendVarTransform.emptyReplacements();

  for fn in fns loop
  _ := match(fn)
    local
      DAE.ComponentRef crVar;
      list<DAE.Statement> st;
      DAE.Exp eVar, eBind, e;
      list<DAE.Exp> arrExp;
      BackendDAE.Equation eq;
      Integer varDim;
      list<DAE.ComponentRef> crefs;
      Integer n,i;
      DAE.Dimensions dims;
      DAE.Dimension dim;
      list<BackendDAE.Var> varLst;

    // assume inArgs is syncron to fns.inputs
    case (DAE.VAR(componentRef=cr,direction=DAE.INPUT(),kind=DAE.VARIABLE()))
      algorithm
        fnInputs := cr :: fnInputs;
      then ();

    //fns.outputs
    case DAE.VAR(componentRef=cr,direction=DAE.OUTPUT(),kind=DAE.VARIABLE())
    guard (not Expression.isRecordType(ComponentReference.crefTypeFull(cr))) and ComponentReference.crefDepth(cr) > 0
      algorithm
        // create variables
        (crVar, varLst, repl) := createReplacementVariables(cr, funcname, repl);
        outEqs := BackendVariable.addVarsDAE(varLst, outEqs);
        // collect output variables
        oOutput := crVar::oOutput;
      then ();

    case (DAE.VAR(componentRef=cr,protection=DAE.PROTECTED(),binding=NONE()))
    guard not Expression.isRecordType(ComponentReference.crefTypeFull(cr))
      algorithm
        // create variables
        (_, varLst, repl) := createReplacementVariables(cr, funcname, repl);
        varLst := list(BackendVariable.setVarTS(_var, SOME(BackendDAE.AVOID())) for _var in varLst);
        outEqs := BackendVariable.addVarsDAE(varLst, outEqs);
    then ();

    case (DAE.VAR(componentRef=cr,protection=DAE.PROTECTED(),binding=SOME(eBind)))
    guard not Expression.isRecordType(ComponentReference.crefTypeFull(cr))
      algorithm
        // create variables
        (crVar, varLst, repl) := createReplacementVariables(cr, funcname, repl);
        // add variables
        eVar := Expression.crefExp(crVar);
        varLst := list(BackendVariable.setVarTS(_var, SOME(BackendDAE.AVOID())) for _var in varLst);
        outEqs := BackendVariable.addVarsDAE(varLst, outEqs);
        // add equation for binding
        eq := BackendEquation.generateEquation(eVar,eBind);
        outEqs := BackendEquation.equationAddDAE(eq, outEqs);
      then ();

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(st)))
      equation
        eqlst = List.map(st, BackendEquation.statementEq);
        outEqs = BackendEquation.equationsAddDAE(eqlst, outEqs);
      then ();
    end match;
  end for;

  // bring output variables in the right order
  oOutput := listReverse(oOutput);

  /* TODO: remove this check for a square system */
  if (BackendDAEUtil.systemSize(outEqs) <> BackendVariable.daenumVariables(outEqs)) then
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.trace("newBackendInline.createEqnSysfromFunction failed for function " + funcname + "with different sizes\n");
      print(intString(BackendDAEUtil.systemSize(outEqs)) + " <> "  + intString(BackendVariable.daenumVariables(outEqs)));
    end if;
    fail();
  end if;

  // debug
  if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
    print("\noriginal function body of: "+funcname);
    BackendDump.printEqSystem(outEqs);
    print("\nDump replacements: ");
    BackendVarTransform.dumpReplacements(repl);
  end if;

  // scalarize array equations
  outEqs.orderedEqs := BackendEquation.listEquation(InlineArrayEquations.getScalarArrayEqns(BackendEquation.equationList(outEqs.orderedEqs)));

  // replace protected and output variables in function body
  outEqs := BackendVarTransform.performReplacementsEqSystem(outEqs, repl);

  // debug
  if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
    print("\n replaced protected and output for: "+funcname);
    BackendDump.printEqSystem(outEqs);
  end if;


  // replace inputs variables
  argmap := List.threadTuple(listReverse(fnInputs), args);
  (argmap,checkcr) := Inline.extendCrefRecords(argmap, HashTableCG.emptyHashTable());
  BackendDAEUtil.traverseBackendDAEExpsEqSystemWithUpdate(outEqs, replaceArgs, (argmap,checkcr,true));


  // debug
  if Flags.isSet(Flags.DUMPBACKENDINLINE_VERBOSE) then
    print("\nreplaced input arguments for: "+funcname);
    BackendDump.printEqSystem(outEqs);
  end if;

end createEqnSysfromFunction;

protected function addReplacement
  input DAE.ComponentRef iCr;
  input DAE.Exp iExp;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(iCr,iExp,iRepl)
    local
      DAE.Type tp;
      BackendVarTransform.VariableReplacements repl;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> arrExp;
      DAE.Exp e;

    case (DAE.CREF_IDENT(identType=tp),_,_)
      guard not Expression.isRecordType(tp) and not Expression.isArrayType(tp)
    then BackendVarTransform.addReplacement(iRepl, iCr, iExp, NONE());

    case (DAE.CREF_IDENT(identType=tp),_,_)
      guard Expression.isArrayType(tp)
      algorithm
        crefs := ComponentReference.expandCref(iCr, false);
        repl := iRepl;
        arrExp := Expression.getArrayOrRangeContents(iExp);
        for c in crefs loop
          e :: arrExp := arrExp;
          repl := BackendVarTransform.addReplacement(repl, c, e, NONE());
        end for;
    then repl;
   else fail();
  end match;
end addReplacement;

protected function replaceArgs
"finds DAE.CREF and replaces them with new exps if the cref is in the argmap"
  input DAE.Exp inExp;
  input tuple<list<tuple<DAE.ComponentRef,DAE.Exp>>,HashTableCG.HashTable,Boolean> inTuple;
  output DAE.Exp outExp;
  output tuple<list<tuple<DAE.ComponentRef,DAE.Exp>>,HashTableCG.HashTable,Boolean> outTuple;
algorithm
  (outExp,outTuple) := Expression.Expression.traverseExpBottomUp(inExp,Inline.replaceArgs,inTuple);
  if not Util.tuple33(outTuple) then
    if Flags.isSet(Flags.FAILTRACE) then
      Debug.traceln("BackendInline.replaceArgs failed");
    end if;
    fail();
  end if;
end replaceArgs;

annotation(__OpenModelica_Interface="backend");
end BackendInline;
