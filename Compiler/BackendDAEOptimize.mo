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
public import DAE;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEEXT;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Derive;
protected import Error;
protected import RTOpts;
protected import SCode;
protected import Util;
protected import Values;
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

/******************************************
 matchingAlgorithm and stuff
 *****************************************/

public function matchingAlgorithm
"function: matchingAlgorithm
  author: PA
  This function performs the matching algorithm, which is the first
  part of sorting the equations into BLT (Block Lower Triangular) form.
  The matching algorithm finds a variable that is solved in each equation.
  But to also find out which equations forms a block of equations, the
  the second algorithm of the BLT sorting: strong components
  algorithm is run.
  This function returns the updated DAE in case of index reduction has
  added equations and variables, and the incidence matrix. The variable
  assignments is returned as a vector of variable indices, as well as its
  inverse, i.e. which equation a variable is solved in as a vector of
  equation indices.
  BackendDAE.MatchingOptions contain options given to the algorithm.
    - if index reduction should be used or not.
    - if the equation system is allowed to be under constrained or not
      which is used when generating code for initial equations.
  
  inputs:  (DAELow,IncidenceMatrix, BackendDAE.IncidenceMatrixT, MatchingOptions)
  outputs: (int vector /* vector of equation indices */ ,
              int vector /* vector of variable indices */,
              DAELow,IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input DAE.FunctionTree inFunctions;
  output array<Integer> outIntegerArray1;
  output array<Integer> outIntegerArray2;
  output BackendDAE.DAELow outDAELow3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
algorithm
  (outIntegerArray1,outIntegerArray2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5) :=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions,inFunctions)
    local
      BackendDAE.Value nvars,neqns,memsize;
      String ns,ne;
      BackendDAE.Assignments assign1,assign2,ass1,ass2;
      BackendDAE.DAELow dae,dae_1,dae_2;
      BackendDAE.Variables v,kv,v_1,kv_1,vars,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie,e_1,re_1,ie_1,eqns;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev,einfo;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      BackendDAE.BinTree s;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst,e_lst_1,re_lst_1,ie_lst_1;
      list<BackendDAE.MultiDimEquation> ae_lst,ae_lst1;
      array<BackendDAE.Value> vec1,vec2;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.BinTree s;
      list<BackendDAE.WhenClause> whenclauses;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      list<DAE.Algorithm> algs;
    /* fail case if daelow is empty */
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,match_opts,inFunctions)
      equation
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        (nvars == 0) = true;
        (neqns == 0) = true;
        vec1 = listArray({});
        vec2 = listArray({});
      then
        (vec1,vec2,dae,m,mt);
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.REMOVE_SIMPLE_EQN())),inFunctions)
      equation
        DAEEXT.clearDifferentiated();
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,(dae as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc)),m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts,inFunctions,{},{});
        /* NOTE: Here it could be possible to run removeSimpleEquations again, since algebraic equations
        could potentially be removed after a index reduction has been done. However, removing equations here
        also require that e.g. zero crossings, array equations, etc. must be recalculated. */       
        s = BackendDAEUtil.statesDaelow(dae);
        e_lst = BackendDAEUtil.equationList(e);
        re_lst = BackendDAEUtil.equationList(re);
        ie_lst = BackendDAEUtil.equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, s); 
         BackendDAE.EVENT_INFO(whenClauseLst=whenclauses) = ev;
        (zero_crossings) = BackendDAECreate.findZeroCrossings(v,kv,e_lst,ae_lst,whenclauses,algs);
        e = BackendDAEUtil.listEquation(e_lst);
        re = BackendDAEUtil.listEquation(re_lst);
        ie = BackendDAEUtil.listEquation(ie_lst);
        ae = listArray(ae_lst);    
        einfo = BackendDAE.EVENT_INFO(whenclauses,zero_crossings); 
        dae_1 = BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,einfo,eoc);   
        m_1 = BackendDAEUtil.incidenceMatrix(dae_1) "Rerun matching to get updated assignments and incidence matrices
                                    TODO: instead of rerunning: find out which equations are removed
                                    and remove those from assignments and incidence matrix." ;
        mt_1 = BackendDAEUtil.transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mt_1);
        memsize = nvars + nvars;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae_2,m,mt,_,_) = matchingAlgorithm2(dae_1, m_1, mt_1, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae_2,m,mt);

    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.KEEP_SIMPLE_EQN())),inFunctions)
      equation
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae,m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m,mt);
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.MatchingAlgorithm failed\n");
      then
        fail();        
  end matchcontinue;
end matchingAlgorithm;

protected function checkMatching
"function: checkMatching
  author: PA

  Checks that the matching is correct, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no
  check is performed."
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ := matchcontinue (inDAELow,inMatchingOptions)
    local
      BackendDAE.Value esize,vars_size;
      BackendDAE.EquationArray eqns;
      String esize_str,vsize_str;
    case (_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED(),_)) then ();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        (esize == vars_size) = true;
      then
        ();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        (esize < vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        (esize > vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.checkMatching failed\n");
      then
        fail();
  end matchcontinue;
end checkMatching;

protected function assignmentsVector
"function: assignmentsVector
  author: PA
  Converts BackendDAE.Assignments to vector of int elements"
  input BackendDAE.Assignments inAssignments;
  output array<Integer> outIntegerArray;
algorithm
  outIntegerArray := matchcontinue (inAssignments)
    local
      array<BackendDAE.Value> newarr,newarr_1,arr;
      array<BackendDAE.Value> vec;
      BackendDAE.Value size;
    case (BackendDAE.ASSIGNMENTS(actualSize = size,arrOfIndices = arr))
      equation
        newarr = arrayCreate(size, 0);
        newarr_1 = Util.arrayNCopy(arr, newarr, size);
        vec = array_copy(newarr_1);
      then
        vec;
    case (_)
      equation
        print("- DAELow.assignmentsVector failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsVector;

protected function assignmentsCreate
"function: assignmentsCreate
  author: PA
  Creates an assignment array of n elements, filled with value v
  inputs:  (int /* size */, int /* memsize */, int)
  outputs: => Assignments"
  input Integer n;
  input Integer memsize;
  input Integer v;
  output BackendDAE.Assignments outAssignments;
  list<BackendDAE.Value> lst;
  array<BackendDAE.Value> arr;
algorithm
  lst := Util.listFill(0, memsize);
  arr := listArray(lst) "  array_create(memsize,v) => arr &" ;
  outAssignments := BackendDAE.ASSIGNMENTS(n,memsize,arr);
end assignmentsCreate;

protected function assignmentsSetnth
"function: assignmentsSetnth
  author: PA
  Sets the n:nt assignment Value.
  inputs:  (Assignments, int /* n */, int /* value */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments1;
  input Integer inInteger2;
  input Integer inInteger3;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments1,inInteger2,inInteger3)
    local
      array<BackendDAE.Value> arr;
      BackendDAE.Value s,ms,n,v;
    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),n,v)
      equation
        arr = arrayUpdate(arr, n + 1, v);
      then
        BackendDAE.ASSIGNMENTS(s,ms,arr);
    case (_,_,_)
      equation
        print("-assignments_setnth failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsSetnth;

protected function assignmentsExpand
"function: assignmentsExpand
  author: PA
  Expands the assignments array with n values, initialized with zero.
  inputs:  (Assignments, int /* n */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments;
  input Integer inInteger;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      BackendDAE.Assignments ass,ass_1,ass_2;
      BackendDAE.Value n_1,n;
    case (ass,0) then ass;
    case (ass,n)
      equation
        true = n > 0;
        ass_1 = assignmentsAdd(ass, 0);
        n_1 = n - 1;
        ass_2 = assignmentsExpand(ass_1, n_1);
      then
        ass_2;
    case (ass,_)
      equation
        print("DAELow.assignmentsExpand: n should not be negative!");
      then
        fail();
  end matchcontinue;
end assignmentsExpand;

protected function assignmentsAdd
"function: assignmentsAdd
  author: PA
  Adds a value to the end of the assignments array. If memsize = actual size
  this means copying the whole array, expanding it size to fit the value
  Expansion is made by a factor 1.4. Otherwise, the element is inserted taking O(1) in
  insertion cost.
  inputs:  (Assignments, int /* value */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments;
  input Integer inInteger;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      Real msr,msr_1;
      BackendDAE.Value ms_1,s_1,ms_2,s,ms,v;
      array<BackendDAE.Value> arr_1,arr_2,arr;

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        (s == ms) = true "Out of bounds, increase and copy." ;
        msr = intReal(ms);
        msr_1 = msr *. 0.4;
        ms_1 = realInt(msr_1);
        s_1 = s + 1;
        ms_2 = ms_1 + ms;
        arr_1 = Util.arrayExpand(ms_1, arr, 0);
        arr_2 = arrayUpdate(arr_1, s + 1, v);
      then
        BackendDAE.ASSIGNMENTS(s_1,ms_2,arr_2);

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        arr_1 = arrayUpdate(arr, s + 1, v) "space available, increase size and insert element." ;
        s_1 = s + 1;
      then
        BackendDAE.ASSIGNMENTS(s_1,ms,arr_1);

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        print("-assignments_add failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsAdd;

protected function matchingAlgorithm2
"function: matchingAlgorithm2
  author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (DAELow,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              DAELow, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input BackendDAE.Assignments inAssignments7;
  input BackendDAE.Assignments inAssignments8;
  input BackendDAE.MatchingOptions inMatchingOptions9;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
  output BackendDAE.DAELow outDAELow3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outAssignments1,outAssignments2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2,ass1_2,ass2_2;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,i,i_1,nv_1,nkv,nf_1,nvd;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.EquationArray eqns;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.EquationReduction r_simple;
      list<BackendDAE.Value> eqn_lst,var_lst;
      String eqn_str,var_str;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedAlgs2;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1,derivedMultiEqn2;      

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,derivedAlgs,derivedMultiEqn)
      equation
        (nv == i) = true;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,dae,m,mt,derivedAlgs,derivedMultiEqn);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        i_1 = i + 1;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,ass1,ass2,(BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        ((dae as BackendDAE.DAELOW(BackendDAE.VARIABLES(_,_,_,_,nv_1),BackendDAE.VARIABLES(_,_,_,_,nkv),_,_,eqns,_,_,_,_,_,_)),m,mt,derivedAlgs1,derivedMultiEqn1) = reduceIndexDummyDer(dae, m, mt, nv, nf, i, inFunctions,derivedAlgs,derivedMultiEqn) 
        "path_found failed, Try index reduction using dummy derivatives.
         When a constraint exist between states and index reduction is needed
         the dummy derivative will select one of the states as a dummy state
         (and the derivative of that state as a dummy derivative).
         For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
         and der(u1) as dummy derivative, named der_u1. The differentiated function
         then becomes: der_u1 = der(u2).
         In the dummy derivative method this equation is added and the original equation
         u1=u2 is kept. This is not the case for the original pantilides algorithm, where
         the original equation is removed from the system." ;
        nf_1 = BackendDAEUtil.equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
                                   be necessary to restart the matching, according to Bernard Bachmann. Instead one
                                   could continue the matching as usual. This was tested (2004-11-22) and it does not
                                   work to continue without restarting.
                                   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
                                   not restarting.
                                   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
                                   of the system in order to work. SO: Matching is not needed to be restarted from
                                   scratch." ;
        nvd = nv_1 - nv;
        ass1_1 = assignmentsExpand(ass1, nvd);
        ass2_1 = assignmentsExpand(ass2, nvd);
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2) = matchingAlgorithm2(dae, m, mt, nv_1, nf_1, i, ass1_1, ass2_1, (BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs1,derivedMultiEqn1);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2);

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,_,_)
      equation
        eqn_lst = DAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally singular." ;
        var_lst = DAEEXT.getMarkedVariables();
        eqn_str = BackendDump.dumpMarkedEqns(dae, eqn_lst);
        var_str = BackendDump.dumpMarkedVars(dae, var_lst);
        Error.addMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str});
        //print("structurally singular. IM:");
        //dumpIncidenceMatrix(m);
        //print("daelow:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end matchingAlgorithm2;

protected function pathFound "function: pathFound
  author: PA

  This function is part of the matching algorithm.
  It tries to find a matching for the equation index given as
  third argument, i.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int /* equation */,
               Assignments, Assignments)
  outputs: (Assignments, Assignments)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        DAEEXT.eMark(i) "Side effect" ;
        (ass1_1,ass2_1) = assignOneInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (m,mt,i,ass1,ass2)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end pathFound;

protected function assignOneInEqn "function: assignOneInEqn
  author: PA

  Helper function to path_found.
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<BackendDAE.Value> vars;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = BackendDAEUtil.varsInEqn(m, i);
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vars, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignOneInEqn;

protected function assignFirstUnassigned
"function: assignFirstUnassigned
  author: PA
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
  inputs:  (int /* equation */,
            int list /* variables */,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments,  /* ass1 */
            Assignments)  /* ass2 */"
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input BackendDAE.Assignments inAssignments3;
  input BackendDAE.Assignments inAssignments4;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inIntegerLst2,inAssignments3,inAssignments4)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      BackendDAE.Value i,v;
      list<BackendDAE.Value> vs;
    case (i,(v :: vs),ass1,ass2)
      equation
        0 = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = assign(v, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (i,(v :: vs),ass1,ass2)
      equation
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignFirstUnassigned;

protected function getAssigned
"function: getAssigned
  author: PA
  returns the assigned equation for a variable.
  inputs:  (int    /* variable */,
            Assignments,  /* ass1 */
            Assignments)  /* ass2 */
  outputs:  int /* equation */"
  input Integer inInteger1;
  input BackendDAE.Assignments inAssignments2;
  input BackendDAE.Assignments inAssignments3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inInteger1,inAssignments2,inAssignments3)
    local
      BackendDAE.Value v;
      array<BackendDAE.Value> m;
    case (v,BackendDAE.ASSIGNMENTS(arrOfIndices = m),_) then m[v];
  end matchcontinue;
end getAssigned;

protected function assign
"function: assign
  author: PA
  Assign a variable to an equation, updating both assignment lists.
  inputs: (int, /* variable */
           int, /* equation */
           Assignments, /* ass1 */
           Assignments) /* ass2 */
  outputs: (Assignments,  /* updated ass1 */
            Assignments)  /* updated ass2 */"
  input Integer inInteger1;
  input Integer inInteger2;
  input BackendDAE.Assignments inAssignments3;
  input BackendDAE.Assignments inAssignments4;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inInteger2,inAssignments3,inAssignments4)
    local
      BackendDAE.Value v_1,e_1,v,e;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
    case (v,e,ass1,ass2)
      equation
        v_1 = v - 1 "print \"assign \" & intString v => vs & intString e => es & print vs & print \" to eqn \" & print es & print \"\\n\" &" ;
        e_1 = e - 1;
        ass1_1 = assignmentsSetnth(ass1, v_1, e);
        ass2_1 = assignmentsSetnth(ass2, e_1, v);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assign;

protected function forallUnmarkedVarsInEqn
"function: forallUnmarkedVarsInEqn
  author: PA
  This function is part of the matching algorithm.
  It loops over all umarked variables in an equation.
  inputs:  (IncidenceMatrix,
            IncidenceMatrixT,
            int,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<BackendDAE.Value> vars,vars_1;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = BackendDAEUtil.varsInEqn(m, i);
        vars_1 = Util.listFilter(vars, isNotVMarked);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vars_1, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"function: isNotVMarked
  author: PA
  This function succeds for variables that are not marked."
  input Integer i;
algorithm
  false := DAEEXT.getVMark(i);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody
"function: forallUnmarkedVarsInEqnBody
  author: PA
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT,
            int,
            int list /* var list */
            Assignments
            Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input list<Integer> inIntegerLst4;
  input BackendDAE.Assignments inAssignments5;
  input BackendDAE.Assignments inAssignments6;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inIntegerLst4,inAssignments5,inAssignments6)
    local
      BackendDAE.Value assarg,i,v;
      BackendDAE.Assignments ass1_1,ass2_1,ass1_2,ass2_2,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      list<BackendDAE.Value> vars,vs;
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        assarg = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, ass1, ass2);
        (ass1_2,ass2_2) = assign(v, i, ass1_1, ass2_1);
      then
        (ass1_2,ass2_2);
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;

/******************************************
 strongComponents and stuff
 *****************************************/

public function strongComponents "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4)
    local
      BackendDAE.Value n,i;
      list<BackendDAE.Value> stack;
      list<list<BackendDAE.Value>> comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> ass1,ass2;
    case (m,mt,ass1,ass2)
      equation
        n = arrayLength(m);
        DAEEXT.initLowLink(n);
        DAEEXT.initNumber(n);
        (i,stack,comps) = strongConnectMain(m, mt, ass1, ass2, n, 0, 1, {}, {});
      then
        comps;
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "strong_components failed\n");
        Error.addMessage(Error.INTERNAL_ERROR,
          {"sorting equations(strong components failed)"});
      then
        fail();
  end matchcontinue;
end strongComponents;

protected function strongConnectMain "function: strongConnectMain
  author: PA

  Helper function to strong_components

  inputs:  (IncidenceMatrix,
              IncidenceMatrixT,
              int vector, /* Assignment */
              int vector, /* Assignment */
              int, /* n - number of equations */
              int, /* i */
              int, /* w */
              int list, /* stack */
              int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Value n,i,w,w_1,num;
      list<BackendDAE.Value> stack,stack_1,stack_2;
      list<list<BackendDAE.Value>> comp,comps;
    case (m,mt,a1,a2,n,i,w,stack,comp)
      equation
        (w > n) = true;
      then
        (i,stack,comp);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      local list<list<Integer>> comps2;

      equation
        0 = DAEEXT.getNumber(w);
        (i,stack_1,comps) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        w_1 = w + 1;
        (i,stack_2,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack_1, comps);
      then
        (i,stack_2,comps);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      equation
        num = DAEEXT.getNumber(w);
        (num == 0) = false;
        w_1 = w + 1;
        (i,stack_1,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack, comps);
      then
        (i,stack_1,comps);
  end matchcontinue;
end strongConnectMain;

protected function strongConnect "function: strongConnect
  author: PA

  Helper function to strong_connect_main

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */ )
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<list<Integer>> inIntegerLstLst8;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLstLst8)
    local
      BackendDAE.Value i_1,i,v;
      list<BackendDAE.Value> stack_1,eqns,stack_2,stack_3,comp,stack;
      list<list<BackendDAE.Value>> comps_1,comps_2,comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,stack,comps)
      equation
        i_1 = i + 1;
        DAEEXT.setNumber(v, i_1)  ;
        DAEEXT.setLowLink(v, i_1);
        stack_1 = (v :: stack);
        eqns = reachableNodes(v, m, mt, a1, a2);
        (i_1,stack_2,comps_1) = iterateReachableNodes(eqns, m, mt, a1, a2, i_1, v, stack_1, comps);
        (i_1,stack_3,comp) = checkRoot(m, mt, a1, a2, i_1, v, stack_2);
        comps_2 = consIfNonempty(comp, comps_1);
      then
        (i_1,stack_3,comps_2);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-strong_connect failed\n");
      then
        fail();
  end matchcontinue;
end strongConnect;

protected function consIfNonempty "function: consIfNonempty
  author: PA

  Small helper function to avoid empty sublists.
  Consider moving to Util?
"
  input list<Integer> inIntegerLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIntegerLst,inIntegerLstLst)
    local
      list<list<BackendDAE.Value>> lst;
      list<BackendDAE.Value> e;
    case ({},lst) then lst;
    case (e,lst) then (e :: lst);
  end matchcontinue;
end consIfNonempty;

public function reachableNodes "function: reachableNodes
  author: PA

  Helper function to strong_connect.
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1,n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2.
"
  input Integer inInteger1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      BackendDAE.Value eqn_1,var,var_1,pos,eqn;
      list<BackendDAE.Value> reachable,reachable_1,reachable_2;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      String eqnstr;
    case (eqn,m,mt,a1,a2)
      equation
        eqn_1 = eqn - 1;
        var = a2[eqn_1 + 1];
        var_1 = var - 1;
        reachable = mt[var_1 + 1] "Got the variable that is solved in the equation" ;
        reachable_1 = BackendDAEUtil.removeNegative(reachable) "in which other equations is this variable present ?" ;
        pos = Util.listPosition(eqn, reachable_1) ".. except this one" ;
        reachable_2 = listDelete(reachable_1, pos);
      then
        reachable_2;
    case (eqn,_,_,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-reachable_nodes failed, eqn: ");
        eqnstr = intString(eqn);
        Debug.fprint("failtrace", eqnstr);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end reachableNodes;

protected function iterateReachableNodes "function: iterateReachableNodes
  author: PA

  Helper function to strong_connect.

  inputs:  (int list, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input list<Integer> inIntegerLst1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIntegerLst1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      BackendDAE.Value i,lv,lw,minv,w,v,nw,nv,lowlinkv;
      list<BackendDAE.Value> stack,ws;
      list<list<BackendDAE.Value>> comps_1,comps_2,comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        0 = DAEEXT.getNumber(w);
        (i,stack,comps_1) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        lv = DAEEXT.getLowLink(v);
        lw = DAEEXT.getLowLink(w);
        minv = intMin(lv, lw);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_2) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps_1);
      then
        (i,stack,comps_2);
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        nw = DAEEXT.getNumber(w);
        nv = DAEEXT.getNumber(v);
        (nw < nv) = true;
        true = listMember(w, stack);
        lowlinkv = DAEEXT.getLowLink(v);
        minv = intMin(nw, lowlinkv);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);

    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);
    case ({},m,mt,a1,a2,i,v,stack,comps) then (i,stack,comps);
  end matchcontinue;
end iterateReachableNodes;

protected function checkRoot "function: checkRoot
  author: PA

  Helper function to strong_connect.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7)
    local
      BackendDAE.Value lv,nv,i,v;
      list<BackendDAE.Value> stack_1,comps,stack;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,stack)
      equation
        lv = DAEEXT.getLowLink(v);
        nv = DAEEXT.getNumber(v);
        (lv == nv) = true;
        (i,stack_1,comps) = checkStack(m, mt, a1, a2, i, v, stack, {});
      then
        (i,stack_1,comps);
    case (m,mt,a1,a2,i,v,stack) then (i,stack,{});
  end matchcontinue;
end checkRoot;

protected function checkStack "function: checkStack
  author: PA

  Helper function to check_root.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list /* component list */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<Integer> inIntegerLst8;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLst8)
    local
      BackendDAE.Value topn,vn,i,v,top;
      list<BackendDAE.Value> stack_1,comp_1,rest,comp,stack;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,(top :: rest),comp)
      equation
        topn = DAEEXT.getNumber(top);
        vn = DAEEXT.getNumber(v);
        (topn >= vn) = true;
        (i,stack_1,comp_1) = checkStack(m, mt, a1, a2, i, v, rest, comp);
      then
        (i,stack_1,(top :: comp_1));
    case (m,mt,a1,a2,i,v,stack,comp) then (i,stack,comp);
  end matchcontinue;
end checkStack;





/******************************************
 reduceIndexDummyDer and stuff
 *****************************************/




protected function reduceIndexDummyDer
"function: reduceIndexDummyDer
  author: PA
  When matching fails, this function is called to try to
  reduce the index by differentiating the marked equations and
  replacing one of the variable with a dummy derivative, i.e. making
  it algebraic.
  The new BackendDAE.DAELow is returned along with an updated incidence matrix.

  inputs: (DAELow, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT,
             int /* number of vars */, int /* number of eqns */, int /* i */)
  outputs: (DAELow, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output BackendDAE.DAELow outDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      list<BackendDAE.Value> eqns,diff_eqns,eqns_1,stateindx,deqns,reqns,changedeqns;
      list<BackendDAE.Key> states;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,stateno,i;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;      

    case (dae,m,mt,nv,nf,i,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        eqns = DAEEXT.getMarkedEqns();
        // print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        // print("\n");
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        // print("differentiating equations:");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        // print("\n");

        // Collect the states in the equations that are singular, i.e. composing a constraint between states.
        // Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt) "" ;
        (dae,m,mt,nv,nf,deqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(dae, m, mt, nv, nf, eqns_1,inFunctions,derivedAlgs,derivedMultiEqn);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        //  print("Selected ");print(ComponentReference.printComponentRefStr(state));print(" as dummy state\n");
        //  print(" From candidates:");print(Util.stringDelimitList(Util.listMap(states,ComponentReference.printComponentRefStr),", "));print("\n");
        dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae)  ;
        // print("Chosen dummy: ");print(ComponentReference.printComponentRefStr(dummy_der));print("\n");
        reqns = BackendDAEUtil.eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, int_eq);
        (dae,m,mt) = replaceDummyDer(state, dummy_der, dae, m, mt, changedeqns)
        "We need to change variables in the differentiated equations and in the equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, state);
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae, m, mt, changedeqns);
        // print("new DAE:");
        // dump(dae);
        // print("new IM:");
        // dumpIncidenceMatrix(m);
      then
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,_,_,_)
      equation
        eqns = DAEEXT.getMarkedEqns();
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        es = Util.listMap(eqns_1, intString);
        es_1 = Util.stringDelimitList(es, ", ");
        print("eqns =");print(es_1);print("\n");
        ({},_) = statesInEqns(eqns_1, dae, m, mt);
        print("no states found in equations:");
        BackendDump.printEquations(eqns_1, dae);
        print("differentiated equations:");
        BackendDump.printEquations(diff_eqns,dae);
        print("Variables :");
        print(Util.stringDelimitList(Util.listMap(DAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();

    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-reduce_index_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end reduceIndexDummyDer;

protected function makeAlgebraic
"function: makeAlgebraic
  author: PA
  Make the variable a dummy derivative, i.e.
  change varkind from STATE to DUMMY_STATE.
  inputs:  (DAELow, DAE.ComponentRef /* state */)
  outputs: (DAELow) = "
  input BackendDAE.DAELow inDAELow;
  input DAE.ComponentRef inComponentRef;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,inComponentRef)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection d;
      BackendDAE.Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Value> indx;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.DAELow daelow, daelow_1;

    case (BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,wc,eoc),cr)
      equation
        ((BackendDAE.VAR(cr,kind,d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),indx) = BackendVariable.getVar(cr, vars);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix), vars);        
      then
        BackendDAE.DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,wc,eoc);

    case (_,_)
      equation
        print("DAELow.makeAlgebraic failed\n");
      then
        fail();

  end matchcontinue;
end makeAlgebraic;

protected function propagateDummyFixedAttribute
"function: propagateDummyFixedAttribute
  author: PA
  This function takes a list of equations that are differentiated
  and the chosen dummy state.
  The fixed attribute of the selected dummy state is propagated to
  the other state. This must be done since the dummy state becomes
  an algebraic state which has fixed = false by default.
  For example consider the equations:
  s1 = b;
  b=2c;
  c = s2;
  if s2 is selected as dummy derivative and s2 has an initial equation
  i.e. fixed should be false for the state s2 (which is set by the user),
  this fixed value has to be propagated to s1 when s2 becomes a dummy
  state."
  input BackendDAE.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow,inIntegerLst,inComponentRef,inInteger)
    local
      list<BackendDAE.Value> eqns_1,eqns;
      list<BackendDAE.Equation> eqns_lst;
      list<BackendDAE.Key> crefs;
      DAE.ComponentRef state,dummy;
      BackendDAE.Var v,v_1,v_2;
      BackendDAE.Value indx,indx_1,dummy_no;
      Boolean dummy_fixed;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;      
      BackendDAE.DAELow dae;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ei;
      BackendDAE.ExternalObjectClasses eoc;

   /* eqns dummy state */
    case ((dae as BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, BackendDAEUtil.equationNth, e);
        crefs = BackendEquation.equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = BackendVariable.getVar(dummy, vars);
        (dummy_fixed as false) = BackendVariable.varFixed(v);
        ({v_1},{indx_1}) = BackendVariable.getVar(state, vars);
        v_2 = BackendVariable.setVarFixed(v_1, dummy_fixed);
        vars_1 = BackendVariable.addVar(v_2, vars);
      then
        BackendDAE.DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,ei,eoc);

    // Never propagate fixed=true
    case ((dae as BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, BackendDAEUtil.equationNth, e);
        crefs = BackendEquation.equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = BackendVariable.getVar(dummy, vars);
        true = BackendVariable.varFixed(v);
      then dae;

    case (dae,_,_,_)
      equation
        Debug.fprint("failtrace", "propagate_dummy_initial_equations failed\n");
      then
        dae;

  end matchcontinue;
end propagateDummyFixedAttribute;

protected function findState
"function: findState
  author: PA
  Returns the first state from a list of component references."
  input BackendDAE.Variables inVariables;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVariables,inExpComponentRefLst)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<BackendDAE.Key> crs;

    case (vars,(cr :: crs))
      equation
        ((v :: _),_) = BackendVariable.getVar(cr, vars);
        BackendDAE.STATE() = BackendVariable.varKind(v);
      then
        cr;

    case (vars,(cr :: crs))
      equation
        cr = findState(vars, crs);
      then
        cr;

  end matchcontinue;
end findState;

protected function replaceDummyDer
"function: replaceDummyDer
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with the variable dummy der.
  inputs:   (DAE.ComponentRef, /* state */
             DAE.ComponentRef, /* dummy der name */
             DAELow,
             IncidenceMatrix,
             IncidenceMatrixT,
             int list /* equations */)
  outputs:  (DAELow,
             IncidenceMatrix,
             IncidenceMatrixT)"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input BackendDAE.DAELow inDAELow3;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix4;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT5;
  input list<Integer> inIntegerLst6;
  output BackendDAE.DAELow outDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inComponentRef1,inComponentRef2,inDAELow3,inIncidenceMatrix4,inIncidenceMatrixT5,inIntegerLst6)
    local
      DAE.ComponentRef state,dummy,dummyder;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.Variables v_1,v,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie,ie1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2,ae3;
      array<DAE.Algorithm> al,al1,al2,al3;
      BackendDAE.EventInfo wc;
      list<BackendDAE.Value> rest;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> ieLst1,ieLst;

    case (state,dummy,dae,m,mt,{}) then (dae,m,mt);

    case (state,dummyder,BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc),m,mt,(e :: rest))
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        ieLst = BackendDAEUtil.equationList(ie);
        (eqn_1,al1,ae1) = replaceDummyDer2(state, dummyder, eqn, al, ae);
        (ieLst1,al2,ae2) = replaceDummyDerEqns(ieLst,state,dummyder, al1,ae1);
        ie1 = BackendDAEUtil.listEquation(ieLst1);
        (eqn_1,v_1,al3,ae3) = replaceDummyDerOthers(eqn_1, v,al2,ae2);
        eqns_1 = BackendEquation.equationSetnth(eqns, e_1, eqn_1)
         "incidence_row(v\'\',eqn\') => row\' &
          Util.list_replaceat(row\',e\',m) => m\' &
          transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(state, dummyder, BackendDAE.DAELOW(v_1,kv,ev,av,eqns_1,seqns,ie1,ae3,al3,wc,eoc), m, mt, rest);
      then
        (dae,m,mt);

    case (_,_,_,_,_,_)
      equation
        print("-replace_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end replaceDummyDer;

protected function replaceDummyDer2
"function: replaceDummyDer2
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with dummyDer variable in equation"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input BackendDAE.Equation inEquation3;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  output BackendDAE.Equation outEquation;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEquation,outAlgs,outMultiDimEquationArray) := matchcontinue (inComponentRef1,inComponentRef2,inEquation3,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp dercall,e1_1,e2_1,e1,e2;
      DAE.ComponentRef st,dummyder,cr;
      BackendDAE.Value ds,indx,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      BackendDAE.Equation res;
      BackendDAE.WhenEquation elsepartRes;
      BackendDAE.WhenEquation elsepart;
      DAE.ElementSource source,source1;
      array<DAE.Algorithm> algs;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<Integer> dimSize;
    case (st,dummyder,BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Expression.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),inAlgs,ae);
    case (st,dummyder,BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (expl1,_) = Expression.replaceListExp(expl, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Expression.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));    
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),inAlgs,ae1);  /* array equation */
    case (st,dummyder,BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (in_1,_) = Expression.replaceListExp(in_, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));        
        (out1,_) = Expression.replaceListExp(out, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));  
        algs = replaceDummyDerAlgs(indx,inAlgs,dercall, DAE.CREF(dummyder,DAE.ET_REAL()));     
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),algs,ae);  /* Algorithms */
    case (st,dummyder,BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE()),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,NONE()),source);
      then
        (res,inAlgs,ae);

    case (st,dummyder,BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (BackendDAE.WHEN_EQUATION(elsepartRes,source),algs,ae1) = replaceDummyDer2(st,dummyder, BackendDAE.WHEN_EQUATION(elsepart,source),inAlgs,ae);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)),source);
      then
        (res,algs,ae1);
    case (st,dummyder,BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Expression.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),inAlgs,ae);
     case (_,_,_,_,_)
      equation
        print("-DAELow.replaceDummyDer2 failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDer2;

protected function replaceDummyDerAlgs
  input Integer inIndex;
  input array<DAE.Algorithm> inAlgs;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output array<DAE.Algorithm> outAlgs;  
algorithm
  outAlgs:=
  matchcontinue (inIndex,inAlgs,inExp2,inExp3)
    local  
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
  case (inIndex,inAlgs,inExp2,inExp3)
    equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        statementLst1 = replaceDummyDerAlgs1(statementLst,inExp2,inExp3); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));   
    then
      algs;
  end matchcontinue;      
end replaceDummyDerAlgs;

protected function replaceDummyDerAlgs1
  input list<DAE.Statement> inStatementLst;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output list<DAE.Statement> outStatementLst;  
algorithm
  outStatementLst:=
  matchcontinue (inStatementLst,inExp2,inExp3)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1,inputExps;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
  case ({},_,_) then {};
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Expression.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN(t,e1,e_1,source)::st);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (elst1,_) = Expression.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (DAE.CREF(componentRef = cr1),_) = Expression.replaceExp(DAE.CREF(cr,DAE.ET_REAL()),inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inExp2,inExp3)
    equation
       (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
       stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
       else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
       st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        {s1} = replaceDummyDerAlgs1({s},inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Expression.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSERT(e1,e_1,source)::st);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TERMINATE(e1,source)::st);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Expression.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_REINIT(e1,e_1,source)::st);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_NORETCALL(e1,source)::st);
  case (DAE.STMT_RETURN(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_RETURN(source)::st);
  case (DAE.STMT_BREAK(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_BREAK(source)::st);
  case (DAE.STMT_FAILURE(body=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FAILURE(stlst1,source)::st);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TRY(stlst1,source)::st);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_CATCH(stlst1,source)::st);
  case (DAE.STMT_THROW(source=source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_THROW(source)::st);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_GOTO(labelName,source)::st);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_LABEL(labelName,source)::st);
  case (DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=elst,source=source)::rest,inExp2,inExp3)
    equation
        (elst1,_) = Expression.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_MATCHCASES(matchType,inputExps,elst1,source)::st);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs1;

protected function replaceDummyDerAlgs2
  input DAE.Else inElse;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output DAE.Else outElse;  
algorithm
  outElse:=
  matchcontinue (inElse,inExp2,inExp3)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
  case (DAE.NOELSE(),_,_) then DAE.NOELSE();
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
    then
      DAE.ELSEIF(e1,stlst1,else_1);
  case (DAE.ELSE(statementLst=stlst),inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
    then
      DAE.ELSE(stlst1);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs2;

protected function replaceDummyDerEqns
"function replaceDummyDerEqns
  author: PA
  Helper function to reduceIndexDummy<der
  replaces der(state) with dummy_der variable in list of equations."
  input list<BackendDAE.Equation> eqns;
  input DAE.ComponentRef st;
  input DAE.ComponentRef dummyder;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  output list<BackendDAE.Equation> outEqns;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEqns,outAlgs,outMultiDimEquationArray):=
  matchcontinue (eqns,st,dummyder,inAlgs,inMultiDimEquationArray)
    local
      DAE.ComponentRef st,dummyder;
      list<BackendDAE.Equation> eqns1,eqns;
      BackendDAE.Equation e,e1;
      array<DAE.Algorithm> algs,algs1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
    case ({},st,dummyder,inAlgs,ae) then ({},inAlgs,ae);
    case (e::eqns,st,dummyder,inAlgs,ae)
      equation
         (e1,algs,ae1) = replaceDummyDer2(st,dummyder,e,inAlgs,ae);
         (eqns1,algs1,ae2) = replaceDummyDerEqns(eqns,st,dummyder,algs,ae1);
      then
        (e1::eqns1,algs1,ae2);
  end matchcontinue;
end replaceDummyDerEqns;

protected function replaceDummyDerOthers
"function: replaceDummyDerOthers
  author: PA
  Helper function to reduceIndexDummyDer.
  This function replaces
  1. der(der_s)  with der2_s (Where der_s is a dummy state)
  2. der(der(v)) with der2_v (where v is a state)
  3. der(v)  for alg. var v with der_v
  in the BackendDAE.Equation given as arguments. To do this it needs the Variables
  also passed as argument to the function to e.g. determine if a variable
  is a dummy variable, etc."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;  
  output BackendDAE.Equation outEquation;
  output BackendDAE.Variables outVariables;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEquation,outVariables,outAlgs,outMultiDimEquationArray):=
  matchcontinue (inEquation,inVariables,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp e1_1,e2_1,e1,e2;
      BackendDAE.Variables vars_1,vars_2,vars_3,vars;
      BackendDAE.Value ds,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation elsePartRes;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source,source1;
      Integer indx;
      array<DAE.Algorithm> al;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<Integer> dimSize;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),vars,inAlgs,ae)
      equation
        ((e1_1,vars_1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),vars,inAlgs,ae) 
      equation
        (expl1,vars_1) = replaceDummyDerOthersExpLst(expl,vars);
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        ((e1_1,vars_2)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars_1);
        ((e2_1,vars_3)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars_2);       
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),vars_3,inAlgs,ae1);  /* array equation */

    case (BackendDAE.WHEN_EQUATION(whenEquation =
            BackendDAE.WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=NONE()),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e2_1,NONE()),source),vars_1,inAlgs,ae);

    case (BackendDAE.WHEN_EQUATION(whenEquation =
            BackendDAE.WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=SOME(elsePart)),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars);
        (BackendDAE.WHEN_EQUATION(elsePartRes,source), vars_2,al,ae1) = replaceDummyDerOthers(BackendDAE.WHEN_EQUATION(elsePart,source),vars_1,inAlgs,ae);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e2_1,SOME(elsePartRes)),source),vars_2,al,ae1);

    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),vars,inAlgs,ae)
      equation
        (in_1,vars_1) = replaceDummyDerOthersExpLst(in_, vars);
        (out1,vars_2) = replaceDummyDerOthersExpLst(out, vars_1);
        (vars_2,al) = replaceDummyDerOthersAlgs(indx,vars_1,inAlgs);     
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),vars_2,al,ae);

   case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),vars,inAlgs,ae)      
      equation
        ((e1_1,vars_1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (_,_,_,_)
      equation
        print("-DAELow.replaceDummyDerOthers failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDerOthers;

protected function replaceDummyDerOthersAlgs
  input Integer inIndex;
  input BackendDAE.Variables inVariables;
  input array<DAE.Algorithm> inAlgs;
  output BackendDAE.Variables outVariables;
  output array<DAE.Algorithm> outAlgs;
algorithm
  (outVariables,outAlgs):=
  matchcontinue (inIndex,inVariables,inAlgs)
    local
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
      BackendDAE.Variables vars;
      case(inIndex,inVariables,inAlgs)
        equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        (statementLst1,vars) = replaceDummyDerOthersAlgs1(statementLst,inVariables); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));           
      then
       (vars,algs); 
  end matchcontinue;        
end replaceDummyDerOthersAlgs;

protected function replaceDummyDerOthersAlgs1
  input list<DAE.Statement> inStatementLst;  
  input BackendDAE.Variables inVariables;
  output list<DAE.Statement> outStatementLst;  
  output BackendDAE.Variables outVariables;
algorithm
  (outStatementLst,outVariables) :=
  matchcontinue (inStatementLst,inVariables)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1,inputExps;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      BackendDAE.Variables vars,vars1,vars2,vars3;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
  case ({},inVariables) then ({},inVariables);
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN(t,e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (elst1,vars1) = replaceDummyDerOthersExpLst(elst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st,vars2);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((DAE.CREF(componentRef = cr1),vars1)) = Expression.traverseExp(DAE.CREF(cr,DAE.ET_REAL()),replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st,vars2);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inVariables)
    equation
       ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
       (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
       (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
       (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st,vars3);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inVariables)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        ({s1},vars2) = replaceDummyDerOthersAlgs1({s},vars1);
        (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st,vars3);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st,vars2);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSERT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TERMINATE(e1,source)::st,vars1);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_REINIT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_NORETCALL(e1,source)::st,vars1);
  case (DAE.STMT_RETURN(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_RETURN(source)::st,vars);
  case (DAE.STMT_BREAK(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_BREAK(source)::st,vars);
  case (DAE.STMT_FAILURE(body=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_FAILURE(stlst1,source)::st,vars1);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TRY(stlst1,source)::st,vars1);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_CATCH(stlst1,source)::st,vars1);
  case (DAE.STMT_THROW(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_THROW(source)::st,vars);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_GOTO(labelName,source)::st,vars);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_LABEL(labelName,source)::st,vars);
  case (DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=elst,source=source)::rest,inVariables)
    equation
        (elst1,vars) = replaceDummyDerOthersExpLst(elst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_MATCHCASES(matchType,inputExps,elst1,source)::st,vars1);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs1;

protected function replaceDummyDerOthersAlgs2
  input DAE.Else inElse;  
  input BackendDAE.Variables inVariables;
  output DAE.Else outElse; 
  output BackendDAE.Variables outVariables; 
algorithm
  (outElse,outVariables):=
  matchcontinue (inElse,inVariables)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
      BackendDAE.Variables vars,vars1,vars2;
  case (DAE.NOELSE(),inVariables) then (DAE.NOELSE(),inVariables);
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
    then
      (DAE.ELSEIF(e1,stlst1,else_1),vars2);
  case (DAE.ELSE(statementLst=stlst),inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
    then
      (DAE.ELSE(stlst1),vars);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs2;

protected function replaceDummyDerOthersExpLst
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input list<DAE.Exp> inExpLst;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpLst;
  output BackendDAE.Variables outVariables;
algorithm
  (outExpLst,outVariables) := matchcontinue (inExpLst,inVariables)
  local 
    list<DAE.Exp> rest,elst;
    DAE.Exp e,e1;
    BackendDAE.Variables vars,vars1,vars2;
    case ({},vars) then ({},vars); 
    case (e::rest,vars)
      equation
        ((e1,vars1)) = Expression.traverseExp(e,replaceDummyDerOthersExp,vars);
        (elst,vars2) = replaceDummyDerOthersExpLst(rest,vars1);
      then
       (e1::elst,vars2); 
  end matchcontinue;       
end replaceDummyDerOthersExpLst;

protected function replaceDummyDerOthersExp
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input tuple<DAE.Exp,BackendDAE.Variables> inExp;
  output tuple<DAE.Exp,BackendDAE.Variables> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.Variables vars,vars_1;
      DAE.VarDirection a;
      BackendDAE.Type b;
      Option<DAE.Exp> c;
      Option<Values.Value> d;
      BackendDAE.Value g;
      DAE.ComponentRef dummyder,dummyder_1,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.crefPrefixDer(dummyder);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((e,vars)) then ((e,vars));

  end matchcontinue;
end replaceDummyDerOthersExp;

protected function newDummyVar
"function: newDummyVar
  author: PA
  This function creates a new variable named
  der+<varname> and adds it to the dae."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.DAELow inDAELow;
  output DAE.ComponentRef outComponentRef;
  output BackendDAE.DAELow outDAELow;
algorithm
  (outComponentRef,outDAELow):=
  matchcontinue (inComponentRef,inDAELow)
    local
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ComponentRef name,dummyvar_cr,var;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;      
      BackendDAE.EquationArray eqns,seqns,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Var dummyvar;

    case (var,BackendDAE.DAELOW(vars, kv, ev, av, eqns, seqns, ie, ae, al, wc,eoc))
      equation
        ((BackendDAE.VAR(name,kind,dir,tp,bind,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(var, vars);
        dummyvar_cr = ComponentReference.crefPrefixDer(var);
        dummyvar = BackendDAE.VAR(dummyvar_cr,BackendDAE.DUMMY_DER(),dir,tp,NONE(),NONE(),dim,0,source,dae_var_attr,comment,flowPrefix,streamPrefix);
        /* Dummy variables are algebraic variables, hence fixed = false */
        dummyvar = BackendVariable.setVarFixed(dummyvar,false);
        vars_1 = BackendVariable.addVar(dummyvar, vars);
      then
        (dummyvar_cr,BackendDAE.DAELOW(vars_1,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc));

    case (_,_)
      equation
        print("-DAELow.newDummyVar failed!\n");
      then
        fail();
  end matchcontinue;
end newDummyVar;

protected function selectDummyState
"function: selectDummyState
  author: PA
  This function is the heuristic to select among the states which one
  will be transformed into  an algebraic variable, a so called dummy state
 (dummy derivative). It should in the future consider initial values, etc.
  inputs:  (DAE.ComponentRef list, /* variable names */
            int list, /* variable numbers */
            DAELow,
            IncidenceMatrix,
            IncidenceMatrixT)
  outputs: (DAE.ComponentRef, int)"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef;
  output Integer outInteger;
algorithm
  (outComponentRef,outInteger):=
  matchcontinue (varCrefs,varIndices,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef s;
      BackendDAE.Value sn;
      BackendDAE.Variables vars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;

    case (varCrefs,varIndices,BackendDAE.DAELOW(orderedVars=vars,orderedEqs = eqns),m,mt)
      equation
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
        //print("priorities:");print(Util.stringDelimitList(Util.listMap(prioTuples,printPrioTuplesStr),","));print("\n");
        (s,sn) = selectMinPrio(prioTuples);
      then (s,sn);

    case ({},_,dae,_,_)
      local BackendDAE.DAELow dae;
      equation
        print("Error, no state to select\nDAE:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end selectDummyState;

protected function selectMinPrio
"Selects the state with lowest priority. This will become a dummy state"
  input list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
  output DAE.ComponentRef s;
  output Integer sn;
algorithm
  (s,sn) := matchcontinue(tuples)
    case(tuples)
      equation
        ((s,sn,_)) = Util.listReduce(tuples,ssPrioTupleMin);
      then (s,sn);
  end matchcontinue;
end selectMinPrio;

protected function ssPrioTupleMin
"Select the minimum tuple of two tuples"
  input tuple<DAE.ComponentRef,Integer,Real> tuple1;
  input tuple<DAE.ComponentRef,Integer,Real> tuple2;
  output tuple<DAE.ComponentRef,Integer,Real> tuple3;
algorithm
  tuple3 := matchcontinue(tuple1,tuple2)
    local DAE.ComponentRef cr1,cr2;
      Integer ns1,ns2;
      Real rs1,rs2;
    case((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs1 <. rs2);
      then ((cr1,ns1,rs1));

    case ((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs2 <. rs1);
      then ((cr2,ns2,rs2));

    //exactly equal, choose first one.
    case ((cr1,ns1,rs1),(cr2,ns2,rs2)) then ((cr1,ns1,rs1));

  end matchcontinue;
end ssPrioTupleMin;

protected function calculateVarPriorities
"Calculates state selection priorities"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(varCrefs,varIndices,vars,eqns,m,mt)
  local DAE.ComponentRef varCref;
    Integer varIndx;
    BackendDAE.Var v;
    Real prio,prio1,prio2;
    list<tuple<DAE.ComponentRef,Integer,Real>> prios;
    case({},{},_,_,_,_) then {};
    case (varCref::varCrefs,varIndx::varIndices,vars,eqns,m,mt) equation
      prios = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
      (v::_,_) = BackendVariable.getVar(varCref,vars);
      prio1 = varStateSelectPrio(v);
      prio2 = varStateSelectHeuristicPrio(v,vars,eqns,m,mt);
      prio = prio1 +. prio2;
    then ((varCref,varIndx,prio)::prios);
  end matchcontinue;
end calculateVarPriorities;

protected function varStateSelectHeuristicPrio
"function varStateSelectHeuristicPrio
  author: PA
  A heuristic for selecting states when no stateSelect information is available.
  This heuristic is based on.
  1. If a state variable s has an equation on the form s = expr(s1,s2,...,sn) where s1..sn are states
     it should be a candiate for dummy state. Like for instance phi_rel = J1.phi-J2.phi will make phi_rel
     a candidate for dummy state whereas J1.phi and J2.phi would be candidates for states.

  2. If a state variable komponent_x.s has been selected as a dummy state then komponent_x.s2 could also
     be a dummy_state. Rationale: This will increase probability that all states belong to the same component
     which is more likely what a user expects.

  3. A priority based on the number of selectable states with the same name.
     For example if the state candidates are: m1.s, m1.v, m2.s, m2.v sd.s_rel (Two translational masses and a springdamper)
     then sd.s_rel should have lower priority than the others."
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output Real prio;
protected
  list<Integer> vEqns;
  DAE.ComponentRef vCr;
  Integer vindx;
  Real prio1,prio2,prio3;
algorithm
  (_,vindx::_) := BackendVariable.getVar(BackendVariable.varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := BackendDAEUtil.eqnsForVarWithStates(mt,vindx);
  vCr := BackendVariable.varCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,eqns);
  prio2 := varStateSelectHeuristicPrio2(vCr,vars);
  prio3 := varStateSelectHeuristicPrio3(vCr,vars);
  prio:= prio1 +. prio2 +. prio3;
end varStateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio3
"function varStateSelectHeuristicPrio3
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local list<BackendDAE.Var> varLst,sameIdentVarLst; Real c,prio;
    case(cr,vars)
      equation
        varLst = BackendDAEUtil.varList(vars);
        sameIdentVarLst = Util.listSelect1(varLst,cr,varHasSameLastIdent);
        c = intReal(listLength(sameIdentVarLst));
        prio = c *. 0.01;
      then prio;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varHasSameLastIdent
"function varHasSameLastIdent
  Helper funciton to varStateSelectHeuristicPrio3.
  Returns true if the variable has the same name (the last identifier)
  as the variable name given as second argument."
  input BackendDAE.Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(BackendDAE.VAR(varName=cr2 ),cr )
      equation
        true = ComponentReference.crefLastIdentEqual(cr,cr2);
      then true;
    case(_,_) then false;
  end matchcontinue;
end varHasSameLastIdent;

protected function varStateSelectHeuristicPrio2
"function varStateSelectHeuristicPrio2
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local
      list<BackendDAE.Var> varLst,sameCompVarLst;
    case(cr,vars)
      equation
        varLst = BackendDAEUtil.varList(vars);
        sameCompVarLst = Util.listSelect1(varLst,cr,varInSameComponent);
        _::_ = Util.listSelect(sameCompVarLst,BackendVariable.isDummyStateVar);
      then -1.0;
    case(cr,vars) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varInSameComponent
"function varInSameComponent
  Helper funciton to varStateSelectHeuristicPrio2.
  Returns true if the variable is defined in the same sub
  component as the variable name given as second argument."
  input BackendDAE.Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(BackendDAE.VAR(varName=cr2 ),cr )
      equation
        true = ComponentReference.crefEqualNoStringCompare(ComponentReference.crefStripLastIdent(cr2),ComponentReference.crefStripLastIdent(cr));
      then true;
    case(_,_) then false;
  end matchcontinue;
end varInSameComponent;

protected function varStateSelectHeuristicPrio1
"function varStateSelectHeuristicPrio1
  author:  PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input list<Integer> eqnLst;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  output Real prio;
algorithm
  prio := matchcontinue(cr,eqnLst,vars,eqns)
    local Integer e; BackendDAE.Equation eqn;
    case(cr,{},_,_) then 0.0;
    case(cr,e::eqnLst,vars,eqns)
      equation
        eqn = BackendDAEUtil.equationNth(eqns,e-1);
        true = isStateConstraintEquation(cr,eqn,vars);
      then -1.0;
    case(cr,_::eqnLst,vars,eqns) then varStateSelectHeuristicPrio1(cr,eqnLst,vars,eqns);
 end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function isStateConstraintEquation
"function isStateConstraintEquation
  author: PA
  Help function to varStateSelectHeuristicPrio2
  Returns true if an equation is on the form cr = expr(s1,s2...sn) for states cr, s1,s2..,sn"
  input DAE.ComponentRef cr;
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  output Boolean res;
algorithm
  res := matchcontinue(cr,eqn,vars)
    local
      DAE.ComponentRef cr2;
      list<DAE.ComponentRef> crs;
      list<list<BackendDAE.Var>> crVars;
      list<Boolean> blst;
      DAE.Exp e2;

    // s = expr(s1,..,sn)  where s1 .. sn are states
    case(cr,BackendDAE.EQUATION(exp = DAE.CREF(cr2,_), scalar = e2),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
        crs = Expression.extractCrefsFromExp(e2);
        (crVars,_) = Util.listMap12(crs,BackendVariable.getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),BackendVariable.isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,BackendDAE.EQUATION(exp = e2, scalar = DAE.CREF(cr2,_)),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
        crs = Expression.extractCrefsFromExp(e2);
        (crVars,_) = Util.listMap12(crs,BackendVariable.getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),BackendVariable.isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,eqn,vars) then false;
  end matchcontinue;
end isStateConstraintEquation;

protected function varStateSelectPrio
"function varStateSelectPrio
  Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Real prio;
  protected
  DAE.StateSelect ss;
algorithm
  ss := BackendVariable.varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2
"helper function to varStateSelectPrio"
  input DAE.StateSelect ss;
  output Real prio;
algorithm
  prio := matchcontinue(ss)
    case (DAE.NEVER()) then -10.0;
    case (DAE.AVOID()) then 0.0;
    case (DAE.DEFAULT()) then 10.0;
    case (DAE.PREFER()) then 50.0;
    case (DAE.ALWAYS()) then 100.0;
  end matchcontinue;
end varStateSelectPrio2;

protected function calculateDummyStatePriorities
"function: calculateDummyStatePriority
  Calculates a priority for dummy state candidates.
  The state with lowest priority number is selected as a dummy variable.
  Heuristic parameters:
   1. States that has an initial condition is given pentalty 10.
   2. BackendDAE.Equation s1= p  s2 with states s1 and s2 gives penalty 1 for state s1.
  The heuristic parameters are summed to get the priority number."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef, Integer, Integer>> outTplExpComponentRefIntegerIntegerLst;
algorithm
  outTplExpComponentRefIntegerIntegerLst:=
  matchcontinue (inExpComponentRefLst,inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx,prio;
      list<tuple<BackendDAE.Key, BackendDAE.Value, BackendDAE.Value>> res;
      list<BackendDAE.Key> crs;
      list<BackendDAE.Value> indxs;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
    case ({},{},_,_,_) then {};
    case ((cr :: crs),(indx :: indxs),dae,m,mt)
      equation
        (cr,indx,prio) = calculateDummyStatePriority(cr, indx, dae, m, mt);
        res = calculateDummyStatePriorities(crs, indxs, dae, m, mt);
      then
        ((cr,indx,prio) :: res);
  end matchcontinue;
end calculateDummyStatePriorities;

protected function calculateDummyStatePriority
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef1;
  output Integer outInteger2;
  output Integer outInteger3;
algorithm
  (outComponentRef1,outInteger2,outInteger3):=
  matchcontinue (inComponentRef,inInteger,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
    case (cr,indx,dae,m,mt) then (cr,indx,0);
  end matchcontinue;
end calculateDummyStatePriority;

protected function statesInEqns
"function: statesInEqns
  author: PA
  Helper function to reduce_index_dummy_der.
  Returns all states in the equations given as equation index list.
  inputs:  (int list /* eqns */,
              DAELow,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs: (DAE.ComponentRef list, /* name for each state */
              int list)  /* number for each state */"
  input list<Integer> inIntegerLst;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<BackendDAE.Key> res1,res11,res1_1;
      list<BackendDAE.Value> res2,vars2,res22,res2_1,rest;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.DAELow daelow;
    case ({},_,_,_) then ({},{});
    case ((e :: rest),daelow as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns),m,mt)
      equation
        (res1,res2) = statesInEqns(rest, daelow, m, mt);
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        vars2 = statesInEqn(eqn, vars);
        varlst = BackendDAEUtil.varList(vars);
        (res11,res22) = statesInVars(varlst, vars2);
        res1_1 = listAppend(res11, res1);
        res2_1 = listAppend(res22, res2);
      then
        (res1_1,res2_1);
    case ((e :: rest),_,_,_)
      local String se;
      equation
        se = intString(e);
        print("-DAELow.statesInEqns failed for eqn: ");
        print(se);
        print("\n");
      then
        fail();
  end matchcontinue;
end statesInEqns;

protected function statesInEqn "function: statesInEqn
  author: PA
  Helper function to states_in_eqns
"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  output list<Integer> res;
  BackendDAE.Variables vars_1;
algorithm
  vars_1 := statesAsAlgebraicVars(vars);
  res := BackendDAEUtil.incidenceRow(vars_1, eqn,{});
end statesInEqn;

protected function statesAsAlgebraicVars "function: statesAsAlgebraicVars
  author: PA

  Return the subset of variables consisting of all states, but changed
  varkind to variable.
"
  input BackendDAE.Variables vars;
  output BackendDAE.Variables v1_1;
  list<BackendDAE.Var> varlst,varlst_1;
  BackendDAE.Variables v1,v1_1;
algorithm
  varlst := BackendDAEUtil.varList(vars) "Creates a new set of BackendDAE.Variables from a BackendDAE.Var list" ;
  varlst_1 := statesAsAlgebraicVars2(varlst);
  v1 := BackendDAEUtil.emptyVars();
  v1_1 := BackendVariable.addVars(varlst_1, v1);
end statesAsAlgebraicVars;

protected function statesAsAlgebraicVars2 "function: statesAsAlgebraicVars2
  author: PA

  helper function to states_as_algebraic_vars
"
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<BackendDAE.Var> res,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection a;
      BackendDAE.Type b;
      Option<DAE.Exp> c,f;
      Option<Values.Value> d;
      list<DAE.Subscript> e;
      BackendDAE.Value g;
      list<Absyn.Path> i;
      DAE.ElementSource source "the element source";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case {} then {};
    case ((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "states treated as algebraic variables" ;
      then
        (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((BackendDAE.VAR(varName = cr,
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "other variables treated as known" ;
      then
        (BackendDAE.VAR(cr,BackendDAE.CONST(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((_ :: vs))
      equation
        res = statesAsAlgebraicVars2(vs);
      then
        res;
  end matchcontinue;
end statesAsAlgebraicVars2;



protected function statesInVars "function: statesInVars
  author: PA

  Helper function to states_in_eqns

  inputs:  (Var list, int list)
  outputs: (DAE.ComponentRef list, /* names of the states */
              int list /* number for each state */)
"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inVarLst,inIntegerLst)
    local
      list<BackendDAE.Var> vars;
      BackendDAE.Value v_1,v;
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
      list<BackendDAE.Key> res1;
      list<BackendDAE.Value> res2,rest;
    case (vars,{}) then ({},{});
    case (vars,(v :: rest))
      equation
        v_1 = v - 1;
        BackendDAE.VAR(varName = cr, flowPrefix = flowPrefix) = listNth(vars, v_1);
        (res1,res2) = statesInVars(vars, rest);
      then
        ((cr :: res1),(v :: res2));
    case (vars,(v :: rest))
      equation
        (res1,res2) = statesInVars(vars, rest);
      then
        (res1,res2);
  end matchcontinue;
end statesInVars;

protected function differentiateEqns
"function: differentiateEqns
  author: PA
  This function takes a dae, its incidence matrices and the number of
  equations an variables and a list of equation indices to
  differentiate. This is used in the index reduction algorithm
  using dummy derivatives, when all marked equations are differentiated.
  The function updates the dae, the incidence matrix and returns
  a list of indices of the differentiated equations, they are added last in
  the dae.
  inputs:  (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list) /* equations */
  outputs: (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list /* differentiated equations */)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.DAELow outDAELow1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
  output list<Integer> outIntegerLst6;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5,outIntegerLst6,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,e_1,leneqns,e;
      BackendDAE.Equation eqn,eqn_1;
      String str;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> reqns,es;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
    case (dae,m,mt,nv,nf,{},_,inDerivedAlgs,inDerivedMultiEqn) then (dae,m,mt,nv,nf,{},inDerivedAlgs,inDerivedMultiEqn);
    case ((dae as BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,true) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = BackendDump.equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = BackendDump.equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        eqns_1 = BackendEquation.equationAdd(eqns, eqn_1);
        leneqns = BackendDAEUtil.equationSize(eqns_1);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAELOW(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(leneqns :: (e :: reqns)),derivedAlgs1,derivedMultiEqn1);
    case ((dae as BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,false) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = BackendDump.equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = BackendDump.equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        leneqns = BackendDAEUtil.equationSize(eqns);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(e :: reqns),derivedAlgs1,derivedMultiEqn1);        
    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-differentiate_eqns failed\n");
      then
        fail();
  end matchcontinue;
end differentiateEqns;


/*  
 * tearing system of equations stuff 
 */ 

public function tearingSystem
" function: tearingSystem
  autor: Frenkel TUD
  Pervormes tearing method on a system.
  This is just a funktion to check the flack tearing.
  All other will be done at tearingSystem1."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
algorithm
  (outDlow,outM,outMT,outV1,outV2,outComps,outResEqn,outTearVar):=
  matchcontinue (inDlow,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<list<Integer>> comps,comps_1;
      list<list<Integer>> r,t;
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "Tearing\n==========\n");
        // get residual eqn and tearing var for each block
        // copy dlow
        dlow1 = copyDaeLowforTearing(dlow);
        (r,t,_,dlow_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        Debug.fcall("tearingdump", BackendDump.dumpComponents, comps_1);
        Debug.fcall("tearingdump", print, "==========\n");
        Debug.fcall2("tearingdump", BackendDump.dumpTearing, r,t);
        Debug.fcall("tearingdump", print, "==========\n");
      then
        (dlow_1,m_1,mT_1,v1_1,v2_1,comps_1,r,t);
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "No Tearing\n==========\n");
      then
        (dlow,m,mT,v1,v2,comps,{},{});
  end matchcontinue;
end tearingSystem;

protected function copyDaeLowforTearing
" function: copyDaeLowforTearing
  autor: Frenkel TUD
  Copy the dae to avoid changes in
  vectors."
  input BackendDAE.DAELow inDlow;
  output BackendDAE.DAELow outDlow;
algorithm
  outDlow:=
  matchcontinue (inDlow)
    local
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Value n,size,n1,size1;
      array<Option<BackendDAE.Equation>> arr_1,arr;
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr,crefIdxLstArr1;
      array<list<BackendDAE.StringIndex>> strIdxLstArr,strIdxLstArr1;
      BackendDAE.VariableArray varArr;
      Integer bucketSize;
      Integer numberOfVars;
      array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
    case (BackendDAE.DAELOW(ordvars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc))
      equation
        BackendDAE.VARIABLES(crefIdxLstArr,strIdxLstArr,varArr,bucketSize,numberOfVars) = ordvars;
        BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr) = varArr;
        crefIdxLstArr1 = arrayCreate(size1, {});
        crefIdxLstArr1 = Util.arrayCopy(crefIdxLstArr, crefIdxLstArr1);
        strIdxLstArr1 = arrayCreate(size1, {});
        strIdxLstArr1 = Util.arrayCopy(strIdxLstArr, strIdxLstArr1);
        varOptArr1 = arrayCreate(size1, NONE());
        varOptArr1 = Util.arrayCopy(varOptArr, varOptArr1);
        ordvars1 = BackendDAE.VARIABLES(crefIdxLstArr1,strIdxLstArr1,BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr1),bucketSize,numberOfVars);
        BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr) = eqns;
        arr_1 = arrayCreate(size, NONE());
        arr_1 = Util.arrayCopy(arr, arr_1);
        eqns1 = BackendDAE.EQUATION_ARRAY(n,size,arr_1);
      then
        BackendDAE.DAELOW(ordvars1,knvars,exobj,av,eqns1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
  end matchcontinue;
end copyDaeLowforTearing;

protected function tearingSystem1
" function: tearingSystem1
  autor: Frenkel TUD
  Main loop. Check all Comps and start tearing if
  strong connected components there"
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
algorithm
  (outResEqn,outTearVar,outDlow,outDlow1,outM,outMT,outV1,outV2,outComps):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      BackendDAE.IncidenceMatrix m,m_1,m_2,m_3,m_4;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2,mT_3,mT_4;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2,v1_3,v2_3;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,tearingeqns,l2,l2_1;
      list<list<Integer>> r,t;
      Integer ll;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{})
      then
        ({},{},dlow,dlow1,m,mT,v1,v2,{});
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // get all interesting vars
        (tvars,crlst) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},{},{},{},crlst);
        // clean v1,v2,m,mT
        v2_2 = arrayCreate(ll, 0);
        v2_2 = Util.arrayNCopy(v2_1, v2_2,ll);
        v1_2 = arrayCreate(ll, 0);
        v1_2 = Util.arrayNCopy(v1_1, v1_2,ll);
        m_3 = BackendDAEUtil.incidenceMatrix(dlow1_1);
        mT_3 = BackendDAEUtil.transposeMatrix(m_3);
        (v1_3,v2_3) = correctAssignments(v1_2,v2_2,residualeqns,tearingvars);
        // next Block
        (r,t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comps_1) = tearingSystem1(dlow_1,dlow1_1,m_3,mT_3,v1_2,v2_2,comps);
      then
        (residualeqns::r,tearingvars::t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comp_1::comps_1);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        false = ll > 1;
        // next Block
        (r,t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
      then
        ({0}::r,{0}::t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp::comps_1);
  end matchcontinue;
end tearingSystem1;

protected function correctAssignments
" function: correctAssignments
  Correct the assignments"
  input array<BackendDAE.Value> inV1;
  input array<BackendDAE.Value> inV2;
  input list<Integer> inRLst;
  input list<Integer> inTLst;
  output array<BackendDAE.Value> outV1;
  output array<BackendDAE.Value> outV2;
algorithm
  (outV1,outV2):=
  matchcontinue (inV1,inV2,inRLst,inTLst)
    local
      array<BackendDAE.Value> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<BackendDAE.Value> comp;
      list<Integer> rlst,tlst;
      Integer r,t;
    case (v1,v2,{},{}) then (v1,v2);
    case (v1,v2,r::rlst,t::tlst)
      equation
         v1_1 = arrayUpdate(v1,t,r);
         v2_1 = arrayUpdate(v2,r,t);
         (v1_2,v2_2) = correctAssignments(v1_1,v2_1,rlst,tlst);
      then
        (v1_2,v2_2);
  end matchcontinue;
end correctAssignments;

protected function getTearingVars
" function: getTearingVars
  Substracts all interesting vars for tearing"
  input BackendDAE.IncidenceMatrix inM;
  input array<BackendDAE.Value> inV1;
  input array<BackendDAE.Value> inV2;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.DAELow inDlow;
  output list<BackendDAE.Value> outVarLst;
  output list<DAE.ComponentRef> outCrLst;
algorithm
  (outVarLst,outCrLst):=
  matchcontinue (inM,inV1,inV2,inComp,inDlow)
    local
      BackendDAE.IncidenceMatrix m;
      array<BackendDAE.Value> v1,v2;
      BackendDAE.Value c,v;
      list<BackendDAE.Value> comp,varlst;
      BackendDAE.DAELow dlow;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Variables ordvars;
      BackendDAE.VariableArray varr;
    case (m,v1,v2,{},dlow) then ({},{});
    case (m,v1,v2,c::comp,dlow as BackendDAE.DAELOW(orderedVars = ordvars as BackendDAE.VARIABLES(varArr=varr)))
      equation
        v = v2[c];
        BackendDAE.VAR(varName = cr) = BackendVariable.vararrayNth(varr, v-1);
        (varlst,crlst) = getTearingVars(m,v1,v2,comp,dlow);
      then
        (v::varlst,cr::crlst);
  end matchcontinue;
end getTearingVars;

protected function tearingSystem2
" function: tearingSystem2
  Residualequation loop. This function
  select a residual equation.
  The equation with most connections to
  variables will be selected."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow1,dlow1_1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<Integer> tvars,vars,vars_1,comp,comp_1,exclude;
      String str,str1;
      Integer residualeqn;
      list<Integer> tearingvars,residualeqns,tearingvars_1,residualeqns_1,tearingeqns,tearingeqns_1;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        str = intString(residualeqn);
        str1 = stringAppend("ResidualEqn: ", str);
        Debug.fcall("tearingdump", print, str1);
         // get from mT variable with most equations
        vars = m[residualeqn];
        vars_1 = Util.listSelect1(vars,tvars,Util.listContains);
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars_1,{},residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
        // only succeed if tearing need less equations than system size is
//        true = listLength(tearingvars_1) < systemsize;
    then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        // try next equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,residualeqn::exclude,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,_)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        false = residualeqn > 0;
        Debug.fcall("tearingdump", print, "Select Residual BackendDAE.Equation failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem2;

protected function tearingSystem3
" function: tearingSystem3
  TearingVar loop. This function select
  a tearing variable. The variable with
  most connections to equations will be
  selected."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input Integer inResEqn;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqn,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow_2,dlow_3,dlow1,dlow1_1,dlow1,dlow1_1,dlow1_2,dlowc,dlowc1;
      BackendDAE.IncidenceMatrix m,m_1,m_2,m_3;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2,mT_3;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1,lstm,lstmp,onecomp,morecomps;
      list<Integer> vars,comp,comp_1,comp_2,r,t,exclude,b,cmops_flat,onecomp_flat,othereqns,resteareqns;
      String str,str1,str2;
      Integer tearingvar,residualeqn,compcount,tearingeqnid;
      list<Integer> residualeqns,residualeqns_1,tearingvars,tearingvars_1,tearingeqns,tearingeqns_1,tearingeqns_2;
      DAE.ComponentRef cr,crt;
      list<DAE.ComponentRef> crlst;
      DAE.Ident ident,ident_t;
      BackendDAE.VariableArray varr;
      BackendDAE.Value nvars,neqns,memsize;
      BackendDAE.Variables ordvars,vars_1,knvars,exobj,ordvars1;
      BackendDAE.AliasVariables av;
      BackendDAE.Assignments assign1,assign2,assign1_1,assign2_1,ass1,ass2;
      BackendDAE.EquationArray eqns, eqns_1, eqns_2,removedEqs,remeqns,inieqns,eqns1,eqns1_1,eqns1_2;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      DAE.Exp eqn,eqn_1,scalar,scalar_1;
      DAE.ElementSource source;
      DAE.ExpType identType;
      list<DAE.Subscript> subscriptLst;
      Integer replace,replace1;
    case (dlow,dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        str = intString(tearingvar);
        str1 = stringAppend("\nTearingVar: ", str);
        str2 = stringAppend(str1,"\n");
        Debug.fcall("tearingdump", print, str2);
        // copy dlow
        dlowc = copyDaeLowforTearing(dlow);
        BackendDAE.DAELOW(ordvars as BackendDAE.VARIABLES(varArr=varr),knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc) = dlowc;
        dlowc1 = copyDaeLowforTearing(dlow1);
        BackendDAE.DAELOW(orderedVars = ordvars1,orderedEqs = eqns1) = dlowc1;
        // add Tearing Var
        BackendDAE.VAR(varName = cr as DAE.CREF_IDENT(ident = ident, identType = identType, subscriptLst = subscriptLst )) = BackendVariable.vararrayNth(varr, tearingvar-1);
        ident_t = stringAppend("tearingresidual_",ident);
        crt = ComponentReference.makeCrefIdent(ident_t,identType,subscriptLst);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(crt, BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.REAL(),NONE(),NONE(),{},-1,DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), ordvars);
        // replace in residual equation orgvar with Tearing Var
        BackendDAE.EQUATION(eqn,scalar,source) = BackendDAEUtil.equationNth(eqns,residualeqn-1);
//        (eqn_1,replace) =  Expression.replaceExp(eqn,DAE.CREF(cr,DAE.ET_REAL()),DAE.CREF(crt,DAE.ET_REAL()));
//        (scalar_1,replace1) =  Expression.replaceExp(scalar,DAE.CREF(cr,DAE.ET_REAL()),DAE.CREF(crt,DAE.ET_REAL()));
//        true = replace + replace1 > 0;
        // Add Residual eqn
        eqns_1 = BackendEquation.equationSetnth(eqns,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.CREF(crt,DAE.ET_REAL()),source));
        eqns1_1 = BackendEquation.equationSetnth(eqns1,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.RCONST(0.0),source));
        // add equation to calc org var
        eqns_2 = BackendEquation.equationAdd(eqns_1,BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("tearing"),
                          {},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          DAE.CREF(cr,DAE.ET_REAL()), DAE.emptyElementSource));
        tearingeqnid = BackendDAEUtil.equationSize(eqns_2);
        dlow_1 = BackendDAE.DAELOW(vars_1,knvars,exobj,av,eqns_2,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        dlow1_1 = BackendDAE.DAELOW(ordvars1,knvars,exobj,av,eqns1_1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        // try causalisation
        m_1 = BackendDAEUtil.incidenceMatrix(dlow_1);
        mT_1 = BackendDAEUtil.transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mT_1);
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        // try matching
        checkMatching(dlow_1, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()));
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        (ass1,ass2,dlow_2,m_2,mT_2,_,_) = matchingAlgorithm2(dlow_1, m_1, mT_1, nvars, neqns, 1, assign1, assign2, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew(),{},{});
        v1_1 = assignmentsVector(ass1);
        v2_1 = assignmentsVector(ass2);
        (comps) = strongComponents(m_2, mT_2, v1_1, v2_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        Debug.fcall("tearingdump", BackendDump.dumpComponents, comps);
        // check strongComponents and split it into two lists: len(comp)==1 and len(comp)>1
        (morecomps,onecomp) = splitComps(comps);
        // try to solve the equations
        onecomp_flat = Util.listFlatten(onecomp);
        // remove residual equations and tearing eqns
        resteareqns = listAppend(tearingeqnid::tearingeqns,residualeqn::residualeqns);
        othereqns = Util.listSelect1(onecomp_flat,resteareqns,Util.listNotContains);
        eqns1_2 = solveEquations(eqns1_1,othereqns,v2_1,vars_1,crlst);
         // if we have not make alle equations causal select next residual equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comps_1,compcount) = tearingSystem4(dlow_2,dlow1_1,m_2,mT_2,v1_1,v2_1,comps,residualeqn::residualeqns,tearingvar::tearingvars,tearingeqnid::tearingeqns,comp,0,crlst);
        // check
        true = ((listLength(residualeqns_1) > listLength(residualeqns)) and
                (listLength(tearingvars_1) > listLength(tearingvars)) ) or (compcount == 0);
        // get specifig comps
        cmops_flat = Util.listFlatten(comps_1);
        comp_2 = Util.listSelect1(cmops_flat,comp,Util.listContains);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comp_2);
    case (dlow as BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        // try next TearingVar
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars,tearingvar::exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow as BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,_)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        false = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        Debug.fcall("tearingdump", print, "Select Tearing BackendDAE.Var failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem3;

protected function tearingSystem4
" function: tearingSystem4
  autor: Frenkel TUD
  Internal Main loop for additional
  tearing vars and residual eqns."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<Integer> inComp;
  input Integer inCompCount;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComp;
  output Integer outCompCount;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp,outCompCount):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps,inResEqns,inTearVars,inTearEqns,inComp,inCompCount,inCrlst)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      BackendDAE.IncidenceMatrix m,m_1,m_2;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,ccomp,r,t,r_1,t_1,te,te_1,tearingeqns;
      Integer ll,compcount,compcount_1,compcount_2;
      list<Boolean> checklst;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{},r,t,te,ccomp,compcount,crlst)
      then
        (r,t,te,dlow,dlow1,m,mT,v1,v2,{},compcount);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // get all interesting vars
        (tvars,_) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},r,t,te,crlst);
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps,residualeqns,tearingvars,tearingeqns,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comp_1::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // next Block
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_1) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_1);
  end matchcontinue;
end tearingSystem4;

protected function getMaxfromListList
" function: getMaxfromArrayList
  helper for tearingSystem2 and tearingSystem3
  This function select the equation/variable
  with most connections to variables/equations.
  If more than once is there the first will
  be selected."
  input BackendDAE.IncidenceMatrixT inM;
  input list<BackendDAE.Value> inLst;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.Value inMax;
  input BackendDAE.Value inEqn;
  input list<BackendDAE.Value> inExclude;
  output BackendDAE.Value outEqn;
  output BackendDAE.Value outMax;
algorithm
  (outEqn,outMax):=
  matchcontinue (inM,inLst,inComp,inMax,inEqn,inExclude)
    local
      BackendDAE.IncidenceMatrixT m;
      list<BackendDAE.Value> rest,eqn,eqn_1,eqn_2,eqn_3,comp,exclude;
      BackendDAE.Value v,v1,v2,max,max_1,en,en_1,en_2;
    case (m,{},comp,max,en,exclude) then (en,max);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_1,max_1) = getMaxfromListList(m,rest,comp,max,en,exclude);
        true = v > 0;
        false = Util.listContains(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = BackendDAEUtil.removeNegative(eqn);
        // select entries
        eqn_2 = Util.listSelect1(eqn_1,comp,Util.listContains);
        // remove multiple entries
        eqn_3 = removeMultiple(eqn_2);
        v1 = listLength(eqn_3);
        v2 = intMax(v1,max_1);
        en_2 = Util.if_(v1>max_1,v,en_1);
      then
        (en_2,v2);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_2,v2) = getMaxfromListList(m,rest,comp,max,en,exclude);
      then
        (en_2,v2);
  end matchcontinue;
end getMaxfromListList;

protected function removeMultiple
" function: removeMultiple
  remove mulitple entries from the list"
  input list<BackendDAE.Value> inLst;
  output list<BackendDAE.Value> outLst;
algorithm
  outLst:=
  matchcontinue (inLst)
    local
      list<BackendDAE.Value> rest,lst;
      BackendDAE.Value v;
    case ({}) then {};
    case (v::{})
      then
        {v};
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        false = Util.listContains(v,lst);
      then
        (v::lst);
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        true = Util.listContains(v,lst);
      then
        lst;
  end matchcontinue;
end removeMultiple;

protected function splitComps
" function: splitComps
  splits the comp in two list
  1: len(comp) == 1
  2: len(comp) > 1"
  input list<list<Integer>> inComps;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outComps1;
algorithm
  (outComps,outComps1):=
  matchcontinue (inComps)
    local
      list<list<Integer>> rest,comps,comps1;
      list<Integer> comp;
      Integer v;
    case ({}) then ({},{});
    case ({v}::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comps,{v}::comps1);
    case (comp::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comp::comps,comps1);
  end matchcontinue;
end splitComps;

protected function solveEquations
" function: solveEquations
  try to solve the equations"
  input BackendDAE.EquationArray inEqnArray;
  input list<Integer> inEqns;
  input array<Integer> inAssigments;
  input BackendDAE.Variables inVars;
  input list<DAE.ComponentRef> inCrlst;
  output BackendDAE.EquationArray outEqnArray;
algorithm
  outEqnArray:=
  matchcontinue (inEqnArray,inEqns,inAssigments,inVars,inCrlst)
    local
      BackendDAE.EquationArray eqns,eqns_1,eqns_2;
      list<Integer> rest;
      Integer e,e_1,v,v_1;
      array<Integer> ass;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,varexp,expr;
      list<DAE.Exp> divexplst,constexplst,nonconstexplst,tfixedexplst,tnofixedexplst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<list<DAE.ComponentRef>> crlstlst;
      DAE.ElementSource source;
      BackendDAE.VariableArray varr;
      list<Boolean> blst,blst_1;
      list<list<Boolean>> blstlst;
      list<String> s;
    case (eqns,{},ass,vars,crlst) then eqns;
    case (eqns,e::rest,ass,vars as BackendDAE.VARIABLES(varArr=varr),crlst)
      equation
        e_1 = e - 1;
        BackendDAE.EQUATION(e1,e2,source) = BackendDAEUtil.equationNth(eqns, e_1);
        v = ass[e_1 + 1];
        v_1 = v - 1;
        BackendDAE.VAR(varName=cr) = BackendVariable.vararrayNth(varr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = ExpressionSolve.solve(e1, e2, varexp);
        divexplst = Expression.extractDivExpFromExp(expr);
        (constexplst,nonconstexplst) = Util.listSplitOnTrue(divexplst,Expression.isConst);
        // check constexplst if equal 0
        blst = Util.listMap(constexplst, Expression.isZero);
        false = Util.boolOrList(blst);
        // check nonconstexplst if tearing variables or variables which will be
        // changed during solving process inside
        crlstlst = Util.listMap(nonconstexplst,Expression.extractCrefsFromExp);
        // add explst with variables which will not be changed during solving prozess
        blstlst = Util.listListMap2(crlstlst,Util.listContainsWithCompareFunc,crlst,ComponentReference.crefEqualNoStringCompare);
        blst_1 = Util.listMap(blstlst,Util.boolOrList);
        (tnofixedexplst,tfixedexplst) = Util.listSplitOnBoolList(nonconstexplst,blst_1);
        true = listLength(tnofixedexplst) < 1;
/*        print("\ntfixedexplst DivExpLst:\n");
        s = Util.listMap(tfixedexplst, ExpressionDump.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
        print("\ntnofixedexplst DivExpLst:\n");
        s = Util.listMap(tnofixedexplst, ExpressionDump.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
*/        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,BackendDAE.EQUATION(expr,varexp,source));
        eqns_2 = solveEquations(eqns_1,rest,ass,vars,crlst);
      then
        eqns_2;
  end matchcontinue;
end solveEquations;

end BackendDAEOptimize;
