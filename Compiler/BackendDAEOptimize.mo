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

package BackendDAEOptimize
" file:	       BackendDAEOptimize.mo
  package:     BackendDAEOptimize
  description: BackendDAEOPtimize contains functions that do some kind of
               optimazation on the BackendDAE datatype:
               - removing simpleEquations
               - Tearing/Relaxation
               - Linearization
               - Inline Integration
               - and so on ... 

"

public import Absyn;
public import BackendDAE;
public import Builtin;
public import DAE;
public import SCode;
public import Values;

protected import Algorithm;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendVarTransform;
protected import BackendVariable;
protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import DAEEXT;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Env;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import OptManager;
protected import RTOpts;
protected import System;
protected import Util;
protected import VarTransform;


/* 
 * remove simply equations stuff
 */

public function removeSimpleEquations
"function: removeSimpleEquations
  This function moves simple equations on the form a=b from equations 2nd
  in BackendDAE.DAELow to simple equations 3rd in BackendDAE.DAELow to speed up assignment alg.
  inputs:  (vars: Variables,
              knownVars: Variables,
              eqns: BackendDAE.Equation list,
              simpleEqns: BackendDAE.Equation list,
        initEqns : Equatoin list,
              binTree: BinTree)
  outputs: (Variables, BackendDAE.Variables, BackendDAE.Equation list, BackendDAE.Equation list
         BackendDAE.Equation list)"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  input list<BackendDAE.Equation> inEquationLst3;
  input list<BackendDAE.Equation> inEquationLst4;
  input list<BackendDAE.Equation> inEquationLst5;
  input list<BackendDAE.MultiDimEquation> inArrayEquationLst;
  input list<DAE.Algorithm> inAlgs;
  input BackendDAE.BinTree inBinTree6;
  output BackendDAE.Variables outVariables1;
  output BackendDAE.Variables outVariables2;
  output list<BackendDAE.Equation> outEquationLst3;
  output list<BackendDAE.Equation> outEquationLst4;
  output list<BackendDAE.Equation> outEquationLst5;
  output list<BackendDAE.MultiDimEquation> outArrayEquationLst;
  output list<DAE.Algorithm> outAlgs;
  output BackendDAE.AliasVariables aliasVars; // hash tables of alias-variables' replacement (a = b or a = -b)
algorithm
  (outVariables1,outVariables2,outEquationLst3,outEquationLst4,outEquationLst5,outArrayEquationLst,outAlgs,aliasVars):=
  matchcontinue (inVariables1,inVariables2,inEquationLst3,inEquationLst4,inEquationLst5,inArrayEquationLst,inAlgs,inBinTree6)
    local
      VarTransform.VariableReplacements repl,replc,replc_1,vartransf,vartransf1;
      list<BackendDAE.Equation> eqns_1,seqns,eqns_2,seqns_1,ieqns_1,eqns_3,seqns_2,ieqns_2,seqns_3,eqns,reqns,ieqns;
      list<BackendDAE.MultiDimEquation> arreqns,arreqns1,arreqns2;
      BackendDAE.BinTree movedvars_1,states,outputs;
      BackendDAE.Variables vars_1,knvars_1,vars,knvars;
      list<DAE.Exp> crlst,elst;
      list<DAE.Algorithm> algs,algs_1;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inputsoutputs;
      BackendDAE.AliasVariables varsAliases;      
      //HashTable2.HashTable aliasMappings "mappings alias-variable => true-variable";
      //Variables aliasVars "alias-variables metadata";
    case (vars,knvars,eqns,reqns,ieqns,arreqns,algs,states)
      equation
        repl = VarTransform.emptyReplacements();
        replc = VarTransform.emptyReplacements();

        outputs = BackendDAE.emptyBintree;
        outputs = getOutputsFromAlgorithms(eqns,outputs);
        (eqns_1,seqns,movedvars_1,vartransf,_,replc_1) = removeSimpleEquations2(eqns, simpleEquation, vars, knvars, BackendDAE.emptyBintree, states, outputs, repl, {},replc);
        vartransf1 = VarTransform.addMultiDimReplacements(vartransf);
        Debug.fcall("dumprepl", VarTransform.dumpReplacements, vartransf1);
        Debug.fcall("dumpreplc", VarTransform.dumpReplacements, replc_1);
        eqns_2 = BackendVarTransform.replaceEquations(eqns_1, replc_1);
        seqns_1 = BackendVarTransform.replaceEquations(seqns, replc_1);
        ieqns_1 = BackendVarTransform.replaceEquations(ieqns, replc_1);
        arreqns1 = BackendVarTransform.replaceMultiDimEquations(arreqns, replc_1);
        eqns_3 = BackendVarTransform.replaceEquations(eqns_2, vartransf1);
        seqns_2 = BackendVarTransform.replaceEquations(seqns_1, vartransf1);
        ieqns_2 = BackendVarTransform.replaceEquations(ieqns_1, vartransf1);
        arreqns2 = BackendVarTransform.replaceMultiDimEquations(arreqns1, vartransf1);
        algs_1 = BackendVarTransform.replaceAlgorithms(algs,vartransf1);
        (vars_1,knvars_1) = BackendVariable.moveVariables(vars, knvars, movedvars_1);
        inputsoutputs = Util.listMap1r(algs_1,BackendDAECreate.lowerAlgorithmInputsOutputs,vars_1);
        eqns_3 = Util.listMap1(eqns_3,updateAlgorithmInputsOutputs,inputsoutputs);
        seqns_3 = listAppend(seqns_2, reqns) "& print_vars_statistics(vars\',knvars\')" ;
        // return aliasVars empty for now
        varsAliases = BackendDAEUtil.emptyAliasVariables();
      then
        (vars_1,knvars_1,eqns_3,seqns_3,ieqns_2,arreqns2, algs_1, varsAliases);
    case (_,_,_,_,_,_,_,_)
      equation
        print("-remove_simple_equations failed\n");
      then
        fail();
  end matchcontinue;
end removeSimpleEquations;

protected function removeSimpleEquations2
"Traverses all equations and puts those that are simple in
 a separate list. It builds a set of varable replacements that
 are later used to replace these variable substitutions in the
 equations that are left."
  input list<BackendDAE.Equation> eqns;
  input FuncTypeSimpleEquation funcSimpleEquation "function as argument so it can be distinguish between a=b/a=-b and a=const.";
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree states;
  input BackendDAE.BinTree outputs;
  input VarTransform.VariableReplacements repl;
  input list<DAE.ComponentRef> inExtendLst;
  input VarTransform.VariableReplacements replc;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outSimpleEqns;
  output BackendDAE.BinTree outMvars;
  output VarTransform.VariableReplacements outRepl;
  output list<DAE.ComponentRef> outExtendLst;
  output VarTransform.VariableReplacements outReplc;
  partial function FuncTypeSimpleEquation
    input BackendDAE.Equation eqn;
    input Boolean swap;
    output DAE.Exp e1;
    output DAE.Exp e2;
    output DAE.ElementSource source;
  end FuncTypeSimpleEquation;  
algorithm
  (outEqns,outSimpleEqns,outMvars,outRepl,outExtendLst,outReplc) := matchcontinue (eqns,funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,inExtendLst,replc)
    local
      BackendDAE.BinTree mvars_1,mvars_2;
      VarTransform.VariableReplacements repl_1,repl_2,replc_1,replc_2;
      DAE.ComponentRef cr1,cr2;
      list<BackendDAE.Equation> eqns_1,seqns_1;
      BackendDAE.Equation e;
      DAE.ExpType t;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";
      list<DAE.ComponentRef> extlst,extlst1;
      
    case ({},funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,extlst,replc) then ({},{},mvars,repl,extlst,replc);

    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,inExtendLst,replc) equation
      {e} = BackendVarTransform.replaceEquations({e},repl);
      {e} = BackendVarTransform.replaceEquations({e},replc);
      (e1 as DAE.CREF(cr1,t),e2,source) = funcSimpleEquation(e,false);
      failure(_ = BackendDAEUtil.treeGet(states, cr1)) "cr1 not state";
      BackendVariable.isVariable(cr1, vars, knvars) "cr1 not constant";
      false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      failure(_ = BackendDAEUtil.treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,e2,t); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);      
      mvars_1 = BackendDAEUtil.treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2,extlst1,replc_2) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars_1, states, outputs, repl_1, extlst,replc_1);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2,extlst1,replc_2);

      // Swapped args
    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,inExtendLst,replc) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {BackendDAE.EQUATION(e1,e2,source)} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = simpleEquation(BackendDAE.EQUATION(e2,e1,source),true);
      failure(_ = BackendDAEUtil.treeGet(states, cr1)) "cr1 not state";
      BackendVariable.isVariable(cr1, vars, knvars) "cr1 not constant";
      false = BackendVariable.isTopLevelInputOrOutput(cr1,vars,knvars);
      failure(_ = BackendDAEUtil.treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,e2,t); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = BackendDAEUtil.treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2,extlst1,replc_2) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars_1, states, outputs, repl_1, extlst,replc_1);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2,extlst1,replc_2);

      // try next equation.
    case ((e :: eqns),funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,extlst,replc)
      local BackendDAE.Equation eq1,eq2;
      equation
        {eq1} = BackendVarTransform.replaceEquations({e},repl);
        {eq2} = BackendVarTransform.replaceEquations({eq1},replc);
        //print("not removed simple ");print(equationStr(e));print("\n     -> ");print(equationStr(eq1));
        //print("\n\n");
        (eqns_1,seqns_1,mvars_1,repl_1,extlst1,replc_1) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars, states, outputs, repl, extlst,replc) "Not a simple variable, check rest" ;
      then
        ((e :: eqns_1),seqns_1,mvars_1,repl_1,extlst1,replc_1);
  end matchcontinue;
end removeSimpleEquations2;

protected function removeSimpleEquations3"
Author: Frenkel TUD 2010-07 function removeSimpleEquations3
  helper for removeSimpleEquations2
  if a element of a cref from typ array has to be replaced
  the array have to extend"
  input list<DAE.ComponentRef> increflst;
  input VarTransform.VariableReplacements inrepl;
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input DAE.ExpType t;
  output list<DAE.ComponentRef> outcreflst;
  output VarTransform.VariableReplacements outrepl;
algorithm
  (outcreflst,outrepl) := matchcontinue (increflst,inrepl,cr,e,t)
    local
      list<DAE.ComponentRef> crlst;
      VarTransform.VariableReplacements repl,repl_1;
      DAE.Exp e1;
      DAE.ComponentRef sc;
      DAE.ExpType ty;
     case (crlst,repl,cr,e,t)
      equation
        // is Array
        (_::_) = ComponentReference.crefLastSubs(cr);
        // check if e is not array
        false = Expression.isArray(e);
        // stripLastIdent
        sc = ComponentReference.crefStripLastSubs(cr);
        ty = ComponentReference.crefLastType(cr);
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,ComponentReference.crefEqualNoStringCompare,false));
        // extend cr
        (e1,_) = BackendDAEUtil.extendArrExp(DAE.CREF(sc,ty),NONE());
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
      then
        (sc::crlst,repl_1);
    case (crlst,repl,_,_,_) then (crlst,repl);
  end matchcontinue;
end removeSimpleEquations3;

protected function getOutputsFromAlgorithms"
Author: Frenkel TUD 2010-09 function getOutputsFromAlgorithms
  helper for removeSimpleEquations
  collect all outpus from algorithms to avoid replacement
  of a algorithm output"
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inEqns,inBinTree)
    local
      list<BackendDAE.Equation> es;
      BackendDAE.Equation e;
      BackendDAE.BinTree bt,bt_1,bt_2;
      list<DAE.Exp> explst;
      list<DAE.ComponentRef> crefs;
    case ({},bt) then bt;
     case (BackendDAE.ALGORITHM(out=explst)::es,bt)
      equation
        crefs = Util.listFlatten(Util.listMap(explst,Expression.extractCrefsFromExp));
        bt_1 = BackendDAEUtil.treeAddList(bt,crefs);
        bt_2 = getOutputsFromAlgorithms(es,bt_1);  
      then bt_2;
    case (e::es,bt)
      equation
        bt_1 = getOutputsFromAlgorithms(es,bt);  
      then bt_1;
  end matchcontinue;
end getOutputsFromAlgorithms;

protected function updateAlgorithmInputsOutputs"
Author: Frenkel TUD 2010-09 function updateAlgorithmInputsOutputs
  helper for removeSimpleEquations
  update inputs and outputs of algorithms after remove simple equations"
  input BackendDAE.Equation inEqn;
  input list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inAlgsInputsOutputs;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue (inEqn,inAlgsInputsOutputs)
    local
      BackendDAE.Equation e;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inputsoutputs;
      Integer index;
      list<DAE.Exp> inputs,outputs;
      DAE.ElementSource source;
     case (BackendDAE.ALGORITHM(index=index,source=source),inputsoutputs)
      equation
        true = listLength(inputsoutputs) > index;
        ((inputs,outputs)) = listNth(inputsoutputs,index);
      then BackendDAE.ALGORITHM(index,inputs,outputs,source);
    case (e,_) then e;
  end matchcontinue;
end updateAlgorithmInputsOutputs;

public function countSimpleEquations
"Counts the number of trivial/simple equations
 e.g on form a=b, a=-b or a=constant"
  input BackendDAE.EquationArray eqns;
  output Integer numEqns;
protected Integer elimLevel;
algorithm
 elimLevel := RTOpts.eliminationLevel();
 RTOpts.setEliminationLevel(2) "Full elimination";
 numEqns := countSimpleEquations2(BackendDAEUtil.equationList(eqns),0);
 RTOpts.setEliminationLevel(elimLevel);
end countSimpleEquations;

protected function countSimpleEquations2
  input list<BackendDAE.Equation> eqns;
  input Integer partialSum "to enable tail-recursion";
  output Integer numEqns;
algorithm
  numEqns := matchcontinue(eqns,partialSum)
  local BackendDAE.Equation e;
    case({},partialSum) then partialSum;

    case (e::eqns,partialSum) equation
        (_,_,_) = simpleEquation(e,false);
        partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      // Swaped args in simpleEquation
    case (e::eqns,partialSum) equation
      (_,_,_) = simpleEquation(e,true);
      partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      //Not simple eqn.
    case (e::eqns,partialSum)
    then countSimpleEquations2(eqns,partialSum);
  end matchcontinue;
end countSimpleEquations2;

protected function simpleEquation
"Returns the two sides of an equation as expressions if it is a
 simple equation. Simple equations are
 a+b=0, a-b=0, a=constant, a=-b, etc.
 The first expression returned, e1, is always a CREF.
 If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  input Boolean swap "if true swap args.";
  output DAE.Exp e1;
  output DAE.Exp e2;
  output DAE.ElementSource source "the element source";
algorithm
  (e1,e2,source) := matchcontinue (eqn,swap)
      local
        DAE.Exp e;
        DAE.ExpType t;
        DAE.ElementSource src "the element source";
      // a = b;
      case (BackendDAE.EQUATION(e1 as DAE.CREF(componentRef = _),e2 as  DAE.CREF(componentRef = _),src),swap)
        equation
          true = RTOpts.eliminationLevel() > 0;
          true = RTOpts.eliminationLevel() <> 3;
        then (e1,e2,src);
        // a-b = 0
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);        
      // a-b = 0 swap
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);        
        // 0 = a-b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e1,e2,src);
        // 0 = a-b  swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then
        (e2,e1,src);
        // a + b = 0
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
        // a + b = 0 swap
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Expression.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Expression.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
      // 0 = a+b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // 0 = a+b swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
     // a = -b
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
      // -a = b => a = -b
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // -b - a = 0 => a = -b
    case (BackendDAE.EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
      // -b - a = 0 => a = -b swap
    case (BackendDAE.EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
        // 0 = -b - a => a = -b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e1,e2,src);
        // 0 = -b - a => a = -b swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Expression.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
        // -a = -b
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);        
        // a = constant
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Expression.isConst(e);
      then (e1,e,src);

        // -a = constant
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Expression.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e),src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Expression.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e),src);
  end matchcontinue;
end simpleEquation;



end BackendDAEOptimize;
