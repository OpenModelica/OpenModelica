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
               
  RCS: $Id$
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import Builtin;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import Error;
protected import RTOpts;
protected import Util;
protected import VarTransform;


/* 
 * remove simply equations stuff
 */

public function removeSimpleEquations
"function: removeSimpleEquations
  This function moves simple equations on the form a=b from equations 2nd
  in BackendDAE.BackendDAE to simple equations 3rd in BackendDAE.BackendDAE to speed up assignment alg.
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
      BackendDAE.Equation eq1,eq2;      
      
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
        ((e1,_)) = BackendDAEUtil.extendArrExp((DAE.CREF(sc,ty),NONE()));
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
 numEqns := BackendEquation.traverseBackendDAEEqns(eqns,countSimpleEquations2,0);
 RTOpts.setEliminationLevel(elimLevel);
end countSimpleEquations;

protected function countSimpleEquations2
    input tuple<BackendDAE.Equation, Integer> inTpl;
    output tuple<BackendDAE.Equation, Integer> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local 
    BackendDAE.Equation e;
    Integer partialSum;
    case ((e,partialSum))
      equation
        (_,_,_) = simpleEquation(e,false);
      then ((e,partialSum+1));

      // Swaped args in simpleEquation
    case ((e,partialSum))
      equation
      (_,_,_) = simpleEquation(e,true);
      then ((e,partialSum+1));

      //Not simple eqn.
    case inTpl then inTpl;
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


/*  
 * tearing system of equations stuff 
 */ 

public function tearingSystem
" function: tearingSystem
  autor: Frenkel TUD
  Pervormes tearing method on a system.
  This is just a funktion to check the flack tearing.
  All other will be done at tearingSystem1."
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output BackendDAE.BackendDAE outDlow;
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
      BackendDAE.BackendDAE dlow,dlow_1,dlow1;
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
  input BackendDAE.BackendDAE inDlow;
  output BackendDAE.BackendDAE outDlow;
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
    case (BackendDAE.DAE(ordvars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc))
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
        BackendDAE.DAE(ordvars1,knvars,exobj,av,eqns1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
  end matchcontinue;
end copyDaeLowforTearing;

protected function tearingSystem1
" function: tearingSystem1
  autor: Frenkel TUD
  Main loop. Check all Comps and start tearing if
  strong connected components there"
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
algorithm
  (outResEqn,outTearVar,outDlow,outDlow1,outM,outMT,outV1,outV2,outComps):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
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
  input BackendDAE.BackendDAE inDlow;
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
      BackendDAE.BackendDAE dlow;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Variables ordvars;
      BackendDAE.VariableArray varr;
    case (m,v1,v2,{},dlow) then ({},{});
    case (m,v1,v2,c::comp,dlow as BackendDAE.DAE(orderedVars = ordvars as BackendDAE.VARIABLES(varArr=varr)))
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
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
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
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow1,dlow1_1;
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
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
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
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqn,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow_3,dlow1,dlow1_1,dlow1_2,dlowc,dlowc1;
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
        BackendDAE.DAE(ordvars as BackendDAE.VARIABLES(varArr=varr),knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc) = dlowc;
        dlowc1 = copyDaeLowforTearing(dlow1);
        BackendDAE.DAE(orderedVars = ordvars1,orderedEqs = eqns1) = dlowc1;
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
        dlow_1 = BackendDAE.DAE(vars_1,knvars,exobj,av,eqns_2,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        dlow1_1 = BackendDAE.DAE(ordvars1,knvars,exobj,av,eqns1_1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        // try causalisation
        m_1 = BackendDAEUtil.incidenceMatrix(dlow_1);
        mT_1 = BackendDAEUtil.transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mT_1);
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
	      assign1 = BackendDAETransform.assignmentsCreate(nvars, memsize, 0);
	      assign2 = BackendDAETransform.assignmentsCreate(nvars, memsize, 0);
        // try matching
	      BackendDAETransform.checkMatching(dlow_1, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()));
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
	      (ass1,ass2,dlow_2,m_2,mT_2,_,_) = BackendDAETransform.matchingAlgorithm2(dlow_1, m_1, mT_1, nvars, neqns, 1, assign1, assign2, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew(),{},{});
	      v1_1 = BackendDAETransform.assignmentsVector(ass1);
	      v2_1 = BackendDAETransform.assignmentsVector(ass2);
        (comps) = BackendDAETransform.strongComponents(m_2, mT_2, v1_1, v2_1);
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
    case (dlow as BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
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
    case (dlow as BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,_)
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
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.BackendDAE inDlow1;
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
  output BackendDAE.BackendDAE outDlow;
  output BackendDAE.BackendDAE outDlow1;
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
      BackendDAE.BackendDAE dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
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

/* 
 * Linearization section
 */

public function generateLinearMatrix
  // function: generateLinearMatrix
  // author: wbraun
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functionTree;
  input list<DAE.ComponentRef> inComRef1; // eqnvars
  input list<DAE.ComponentRef> inComRef2; // vars to differentiate 
  input list<BackendDAE.Var> inAllVar;
  output BackendDAE.BackendDAE outJacobian;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps1;
algorithm 
  (outJacobian,outV1,outV2,outComps1) :=
    matchcontinue (inBackendDAE,functionTree,inComRef1,inComRef2,inAllVar)
    local
      DAE.DAElist dae;
      BackendDAE.BackendDAE dlow;
      
      list<DAE.ComponentRef> eqvars,diffvars;
      list<BackendDAE.Var> varlst;
      array<Integer> v1,v2,v4,v31;
      list<Integer> v3;
      list<list<Integer>> comps1,comps2;
      list<BackendDAE.Var> derivedVariables;
      list<BackendDAE.Var> derivedVars;
      BackendDAE.BinTree jacElements;
      list<tuple<String,Integer>> varTuple;
      array<list<Integer>> m,mT;
      
      BackendDAE.Variables v,kv,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst;
      list<DAE.Algorithm> algs;
      list<BackendDAE.MultiDimEquation> ae_lst;
      
      list<String> s;
      String str;
      
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,{},_,_)
        equation
      v = BackendDAEUtil.listVar({});    
      then (BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,_,{},_)
        equation
      v = BackendDAEUtil.listVar({});    
      then (BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),functionTree,eqvars,diffvars,varlst)
        equation

        // prepare index for Matrix and variables for simpleEquations
        derivedVariables = BackendDAEUtil.varList(v);
        (varTuple) = determineIndices(eqvars, diffvars, 0, varlst);
        BackendDump.printTuple(varTuple);
        jacElements = BackendDAE.emptyBintree;
        (derivedVariables,jacElements) = changeIndices(derivedVariables, varTuple, jacElements);
        v = BackendDAEUtil.listVar(derivedVariables);
        
        // Remove simple Equtaion and 
        e_lst = BackendDAEUtil.equationList(e);
        re_lst = BackendDAEUtil.equationList(re);
        ie_lst = BackendDAEUtil.equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, jacElements); 
        e = BackendDAEUtil.listEquation(e_lst);
        re = BackendDAEUtil.listEquation(re_lst);
        ie = BackendDAEUtil.listEquation(ie_lst);
        ae = listArray(ae_lst);
        al = listArray(algs);
        dlow = BackendDAE.DAE(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
     
        // figure out new matching and the strong components  
        m = BackendDAEUtil.incidenceMatrix(dlow);
        mT = BackendDAEUtil.transposeMatrix(m);
        (v1,v2,dlow,m,mT) = BackendDAETransform.matchingAlgorithm(dlow, m, mT, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),functionTree);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrix, m);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrixT, mT);
        Debug.fcall("jacdump2", BackendDump.dump, dlow);
        Debug.fcall("jacdump2", BackendDump.dumpMatching, v1);
        (comps1) = BackendDAETransform.strongComponents(m, mT, v1, v2);
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);

        // figure out wich comps are needed to evaluate all derivedVariables  
        derivedVariables = BackendDAEUtil.varList(v);
        (derivedVars,_) = Util.listSplitOnTrue(derivedVariables,checkIndex);
        v3 = getVarIndex(derivedVars,derivedVariables);
        v31 = Util.arraySelect(v1,v3);
        v3 = arrayList(v31);
        s = Util.listMap(v3,intString);
        str = Util.stringDelimitList(s,",");
        Debug.fcall("markblocks",print,"Vars Indecies : " +& str +& "\n");
        v4 = arrayCreate(listLength(comps1),0);
        v4 = markArray(v3,comps1,v4);
        (comps1,_) = splitBlocks2(comps1,v4,1);
        
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        
        then (dlow,v1,v2,comps1);
    case(_, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateLinearMatrix failed"});
    then fail();          
   end matchcontinue;
end generateLinearMatrix;         

protected function splitBlocks2 
//function: splitBlocks2
//author: wbraun 
  input list<list<Integer>> inIntegerLstLst;
  input array<Integer> inIntegerArray;
  input Integer inPos;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray,inPos)
    local
      list<list<BackendDAE.Value>> states,output_,blocks;
      list<BackendDAE.Value> block_;
      array<BackendDAE.Value> arr;
      BackendDAE.Value i;
    case ({},_,_) then ({},{});
    case ((block_ :: blocks),arr,i)
      equation
        1 = arr[i];
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        ((block_ :: states),output_);
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));        
  end matchcontinue;
end splitBlocks2;

protected function markArray
  // function : markArray
  // author : wbraun
  input list<Integer> inVars1;
  input list<list<Integer>> inVars2;
  input array<Integer> inInt;
  output array<Integer> outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1,inVars2,inInt)
    local
      list<Integer> rest;
      list<list<Integer>> vars;
      Integer var;
      list<Integer> intlst,ilst2;
      Integer i;
      array<Integer> arr,arr1;
      list<String> s,s1;
      String str;
    case({},_,arr) then arr;      
    case(var::rest,vars,arr)
      equation
        i = Util.listlistPosition(var,vars);
        Debug.fcall("markblocks",print,"Var " +& intString(var) +& " at pos : " +& intString(i) +& "\n");
        arr1 = arrayCreate(i+1,1);
        arr = Util.arrayCopy(arr1,arr);
        arr = markArray(rest,vars,arr);
        s = Util.listMap(arrayList(arr),intString);
        str = stringAppendList(s);
        Debug.fcall("markblocks",print,str);
        Debug.fcall("markblocks",print,"\n");
      then arr;        
     case(_,_,_)
       equation
        Debug.fcall("failtrace",print,"Linearization.MarkArray failed\n");
       then fail();
  end matchcontinue;
end markArray; 

protected function getVarIndex
  // function : getVarIndex
  // author : wbraun
  input list<BackendDAE.Var> inVars1;
  input list<BackendDAE.Var> inVars2;
  output list<Integer> outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1, inVars2)
    local
      list<BackendDAE.Var> vars,rest;
      BackendDAE.Var var;
      list<Integer> intlst;
      Integer i;
    case({},_) then {};      
    case(var::rest,vars)
      equation
        i = Util.listPosition(var,vars)+1;
        intlst = getVarIndex(rest,vars);
      then (i::intlst);
    case(var::rest,_)
      equation
        Debug.fcall("failtrace",print,"Linearization.getVarIndex failed\n");
      then fail();
  end matchcontinue;
end getVarIndex;  

protected function checkIndex "function: checkIndex
  author: wbraun

  check if the index is greater 0
"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i >= 0;
  end matchcontinue;
end checkIndex;

/* 
 * Symbolic Jacobian subsection
 */ 

public function generateSymbolicJacobian
  // function: generateSymbolicJacobian
  // author: lochel
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functions;
  input list<DAE.ComponentRef> inVars;
  input list<BackendDAE.Var> stateVars;
  input list<BackendDAE.Var> inputVars;
  input list<BackendDAE.Var> paramVars;
  output BackendDAE.BackendDAE outJacobian;
algorithm
  outJacobian := matchcontinue(inBackendDAE, functions, inVars, stateVars, inputVars, paramVars)
    local
      BackendDAE.BackendDAE daeLow;
      DAE.DAElist daeList;
      list<DAE.ComponentRef> vars;
      BackendDAE.BackendDAE jacobian;
      
      // DAE
      BackendDAE.Variables orderedVars, jacOrderedVars;
      BackendDAE.Variables knownVars, jacKnownVars;
      BackendDAE.Variables externalObjects, jacExternalObjects;
      BackendDAE.AliasVariables aliasVars, jacAliasVars;
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs;
      BackendDAE.EquationArray removedEqs, jacRemovedEqs;
      BackendDAE.EquationArray initialEqs, jacInitialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs, jacArrayEqs;
      array<DAE.Algorithm> algorithms, jacAlgorithms;
      BackendDAE.EventInfo eventInfo, jacEventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses, jacExtObjClasses;
      // end DAE
      
      list<BackendDAE.Var> allVars, derivedVariables;
      list<BackendDAE.Equation> solvedEquations, derivedEquations, derivedEquations2;
      list<DAE.Algorithm> derivedAlgorithms;
      list<tuple<Integer, DAE.ComponentRef>> derivedAlgorithmsLookUp;
      
    case(_, _, {}, _, _,_) equation
      jacOrderedVars = BackendDAEUtil.emptyVars();
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation({});
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray({});
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
    then jacobian;
      
    case(daeLow as BackendDAE.DAE(orderedVars=orderedVars, knownVars=knownVars, externalObjects=externalObjects, aliasVars=aliasVars, orderedEqs=orderedEqs, removedEqs=removedEqs, initialEqs=initialEqs, arrayEqs=arrayEqs, algorithms=algorithms, eventInfo=eventInfo, extObjClasses=extObjClasses), functions, vars, stateVars, inputVars, paramVars) equation
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump:    input +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, daeLow);
      Debug.fcall("jacdump", print, "##################### daeLow-dump:    input #####################\n\n");
      
      allVars = listAppend(listAppend(stateVars, inputVars), paramVars);
      
      derivedVariables = generateJacobianVars(BackendDAEUtil.varList(orderedVars), vars, stateVars);
      (derivedAlgorithms, derivedAlgorithmsLookUp) = deriveAllAlg(arrayList(algorithms), vars, functions, 0);
      derivedEquations = deriveAll(BackendDAEUtil.equationList(orderedEqs), vars, functions, inputVars, paramVars, stateVars, derivedAlgorithmsLookUp);
      
      jacOrderedVars = BackendDAEUtil.listVar(derivedVariables);
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation(derivedEquations);
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray(derivedAlgorithms);
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAE(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
      
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump: jacobian +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, jacobian);
      Debug.fcall("jacdump", print, "##################### daeLow-dump: jacobian #####################\n");
    then jacobian;  
      
    case(_, _, _, _, _,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAE.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

protected function deriveAllAlg
  // function: deriveAllAlg
  // author: lochel
  input list<DAE.Algorithm> inAlgorithms;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex; // 0
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithms, inVars, inFunctions, inAlgIndex)
    local
      DAE.Algorithm currAlg;
      list<DAE.Algorithm> restAlgs;
      list<DAE.ComponentRef> vars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    case({}, _, _, _) then ({}, {});
      
    case(currAlg::restAlgs, vars, functions, algIndex)
    equation
      (rAlgs1, rLookUp1) = deriveOneAlg(currAlg, vars, functions, algIndex);
      (rAlgs2, rLookUp2) = deriveAllAlg(restAlgs, vars, functions, algIndex+1);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveAllAlg;

protected function deriveOneAlg
  // function: deriveOneAlg
  // author: lochel
  input DAE.Algorithm inAlgorithm;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex;
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithm, inVars, inFunctions, inAlgIndex)
    local
      DAE.Algorithm currAlg;
      list<DAE.Statement> statementLst, derivedStatementLst;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    case(_, {}, _, _) then ({}, {});
      
    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, algIndex)equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rLookUp1 = {(algIndex, currVar)};
      (rAlgs2, rLookUp2) = deriveOneAlg(currAlg, restVars, functions, algIndex);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveOneAlg;

protected function generateJacobianVars
  // function: generateJacobianVars
  // author: lochel
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars1, inVars2, inStateVars)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r, stateVars;
    list<DAE.ComponentRef> vars2;
    
    case({}, _, _)
    then {}; 
      
    case(currVar::restVar, vars2, stateVars) equation
      r1 = generateJacobianVars2(currVar, vars2, stateVars);
      r2 = generateJacobianVars(restVar, vars2, stateVars);
      r = listAppend(r1, r2);
    then r;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2
  // function: generateJacobianVars2
  // author: lochel
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVar1, inVars2, inStateVars)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar;
    list<BackendDAE.Var> r2;
    list<BackendDAE.Var> stateVars;
    
    case(_, {}, _)
    then {};
    
    case(var as BackendDAE.VAR(varName=cref), currVar::restVar, stateVars) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar, stateVars);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = generateJacobianVars2(var, restVar, stateVars);
    then r1::r2;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

protected function deriveAll
  // function: deriveAll
  // author: lochel
  input list<BackendDAE.Equation> inEquations;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquations, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<BackendDAE.Equation> restEquations;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
    case({}, _, _, _, _, _, _) then {};
      
    case(currEquation::restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      Debug.fcall("jacdumptime", BackendDump.dumpEqns, {currEquation});
      currDerivedEquations = deriveOne(currEquation, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function deriveOne
  // function: deriveOne
  // author: lochel
  input BackendDAE.Equation inEquation;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      Integer algNum;
      
      list<BackendDAE.Var> currDerivedVariables, restDerivedVariables, derivedVariables;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<DAE.Algorithm> currDerivedAlgorithms, restDerivedAlgorithms, derivedAlgorithms;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer i; 
    case(_, {}, _, _, _, _, _) then {};
      
    case(currEquation, currVar::restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      currDerivedEquations = derive(currEquation, currVar, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveOne(currEquation, restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.deriveOne failed"});
    then fail();
  end matchcontinue;
end deriveOne;

protected function derive
  // function: derive
  // author: lochel
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef var, cref, cref_;
      
      BackendDAE.Var currDerivedVariable;
      BackendDAE.Equation currDerivedEquation;
      DAE.Algorithm currDerivedAlgorithm;
      
      DAE.Exp lhs, rhs, lhs_, rhs_, exp, exp_;
      DAE.ElementSource source;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      Integer index;
      list<DAE.Exp> in_, derivedIn_,out, derivedOut;
      DAE.Algorithm singleAlgorithm, derivedAlgorithm;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer newAlgIndex;
    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      lhs_ = differentiateWithRespectToX(lhs, var, functions, inputVars, paramVars, stateVars);
      rhs_ = differentiateWithRespectToX(rhs, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.EQUATION(lhs_, rhs_, source)};
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(_, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.derive failed: ARRAY_EQUATION-case"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      cref_ = differentiateVarWithRespectToX(cref, var, stateVars);
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.SOLVED_EQUATION(cref_, exp_, source)};
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.RESIDUAL_EQUATION(exp_, source)};
      
    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out=out, source=source), var, functions, inputVars, paramVars, stateVars, algorithmsLookUp)
    equation
      derivedIn_ = Util.listMap5(in_, differentiateWithRespectToX, var, functions, {}, {}, {});
      derivedIn_ = listAppend(in_, derivedIn_);
      derivedOut = Util.listMap5(out, differentiateWithRespectToX, var, functions, {}, {}, {});
        
      newAlgIndex = Util.listPosition((index, var), algorithmsLookUp);
    then {BackendDAE.ALGORITHM(newAlgIndex, derivedIn_, derivedOut, source)};
        
    case(currEquation as BackendDAE.WHEN_EQUATION(_, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Debug.fcall("jacdump",print,"Linearization.derive: WHEN_EQUATION has been removed");
    then {};
      
    case(currEquation as BackendDAE.COMPLEX_EQUATION(_, _, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.derive failed: COMPLEX_EQUATION-case"});
    then fail();
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function differentiateVarWithRespectToX
  // function: differentiateVarWithRespectToX
  // author: lochel
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id,str;
      DAE.ExpType idType;
      list<DAE.Subscript> sLst;
      list<BackendDAE.Var> stateVars;
      BackendDAE.Var v1;
    
    // d(state)/d(x)
    case(cref, x, stateVars) equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      true = BackendVariable.isStateVar(v1);
      cref = ComponentReference.crefPrefixDer(cref);
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
    
    // d(no state)/d(x)
    case(cref, x, _) equation
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
      
    case(cref, _, _)
      equation
        str = "Linearization.differentiateVarWithRespectToX failed: " +&  ComponentReference.printComponentRefStr(cref);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end differentiateVarWithRespectToX;

protected function differentiateWithRespectToX
  // function: differentiateWithRespectToX
  // author: lochel
  
  input DAE.Exp inExp;
  input DAE.ComponentRef inX;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x, cref, cref_;
      DAE.FunctionTree functions;
      DAE.Exp e1, e1_, e2, e2_, e;
      DAE.ExpType et;
      DAE.Operator op;
      
      
      list<DAE.ComponentRef> diff_crefs;
      Absyn.Path fname,derFname;
      
      list<DAE.Exp> expList1, expList2;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      String str;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      DAE.Type tp;
      Integer nArgs;
      BackendDAE.Var v1, v2;
    case(DAE.ICONST(_), _, _, _, _, _)
    then DAE.ICONST(0);
      
    case(DAE.RCONST(_), _, _, _, _, _)
    then DAE.RCONST(0.0);
      
    case (DAE.CAST(ty=et, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.CAST(et, e1_);
      
    // d(x)/d(x)
    case(DAE.CREF(componentRef=cref), x, functions, inputVars, paramVars, stateVars) equation
      true = ComponentReference.crefEqual(cref, x);
    then DAE.RCONST(1.0);
      
    // d(time)/d(x)
    case(DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), x, functions, inputVars, paramVars, stateVars)
    then DAE.RCONST(0.0);
    
    // d(state1)/d(state2) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(state)/d(input) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(inputVars));
    then DAE.RCONST(0.0);
      
    // d(input)/d(state) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(inputVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(parameter1)/d(parameter2) != 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(paramVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(paramVars));
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // d(parameter)/d(no parameter) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars)
    equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(paramVars));
    then DAE.RCONST(0.0);
      
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) equation
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // a + b
    case(DAE.BINARY(exp1=e1, operator=DAE.ADD(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.ADD(et), e2_);
      
    // a - b
    case(DAE.BINARY(exp1=e1, operator=DAE.SUB(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.SUB(et), e2_);
      
    // a * b
    case(DAE.BINARY(exp1=e1, operator=DAE.MUL(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.ADD(et), DAE.BINARY(e1, DAE.MUL(et), e2_));
      e = ExpressionSimplify.simplify(e);
    then e;
      
    // a / b
    case(DAE.BINARY(exp1=e1, operator=DAE.DIV(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.SUB(et), DAE.BINARY(e1, DAE.MUL(et), e2_)), DAE.DIV(et), DAE.BINARY(e2, DAE.MUL(et), e2));
      e = ExpressionSimplify.simplify(e);
    then e;
    
    // a(x)^b
    case(e as DAE.BINARY(exp1=e1, operator=DAE.POW(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      true = Expression.isConst(e2);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(e1_, DAE.MUL(et), DAE.BINARY(e2, DAE.MUL(et), DAE.BINARY(e1, DAE.POW(et), DAE.BINARY(e2, DAE.SUB(et), DAE.RCONST(1.0)))));
    then e;
    
    // der(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      equation
      Builtin.isDer(fname);
      cref = Expression.expCref(e1);
      cref = ComponentReference.crefPrefixDer(cref);
      //str = derivativeNamePrefix +& ExpressionDump.printExpStr(e1);
      //cref = ComponentReference.makeCrefIdent(str, DAE.ET_REAL(),{});
      e1_ = differentiateWithRespectToX(Expression.crefExp(cref), x, functions, inputVars, paramVars, stateVars);
    then e1_;
    
    // -exp
    case(DAE.UNARY(operator=op, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(op, e1_);
      
    // sin(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isSin(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("cos"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

    // cos(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isCos(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()), DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("sin"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // ln(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), e1);

    // log10(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog10(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // exp(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isExp(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(fname,{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
  
    // sqrt(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      equation
        Builtin.isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()))),DAE.MUL(DAE.ET_REAL()),e1_);
        
    // abs(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isAbs(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(DAE.RELATION(e1_,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(0.0)), e1_, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),e1_));
      
      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(e, e1_, e2_);

    // extern functions (analytical)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));  
    then e1;

    // extern functions (numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    equation
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars);
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);  
    then e1;
           
    case(e, x, _, _, _, _)
      equation
        str = "differentiateWithRespectToX failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(x);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end differentiateWithRespectToX;

protected function deriveExpListwrtstate
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input list<tuple<Integer,DAE.derivativeCond>> inConditios;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
    case ({},_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum); 
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then r2;  
  end matchcontinue;
end deriveExpListwrtstate;

protected function deriveExpListwrtstate2
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;    
    case ({}, _, _, _, _, _, _) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars);
    then (r1::r2);
  end matchcontinue;
end deriveExpListwrtstate2;

protected function checkcondition
  input list<tuple<Integer,DAE.derivativeCond>> inConditions;
  input Integer inArgs;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inConditions, inArgs)
    local
      list<tuple<Integer,DAE.derivativeCond>> rest;
      Integer i,nArgs;
      DAE.derivativeCond cond;
      Boolean res;
      DAE.Exp e1;
    case ({},_) then true;
    case((i,cond)::rest,nArgs) 
      equation
        equality(i = nArgs);
        cond = DAE.ZERO_DERIVATIVE();
      then false;
      case((i,cond)::rest,nArgs) 
       equation
         equality(i = nArgs);
         DAE.NO_DERIVATIVE(_) = cond;
       then false;
    case((i,cond)::rest,nArgs) 
      equation
        res = checkcondition(rest,nArgs);
      then res;           
  end matchcontinue;
end checkcondition;

protected function partialAnalyticalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.Exp functionCall;
  input Absyn.Path derFname;
  input Integer nDerArgs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, functionCall, derFname, nDerArgs)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpList1Added, varExpListTotal;
      DAE.ExpType et;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
      Integer nArgs1, nArgs2;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, functionCall as DAE.CALL(expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), derFname, nDerArgs)
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - (nArgs2 + 1), varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, tuple_, builtin, et, inlineType);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialAnalyticalDifferentiation;

protected function partialNumericalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.ComponentRef inState;
  input DAE.Exp functionCall;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, inState, functionCall)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpListHAdded, varExpListTotal;
      DAE.ExpType et;
      Absyn.Path fname;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
      Integer nArgs1, nArgs2;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType))
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(1e-8)),DAE.OR(),DAE.RELATION(currVar,DAE.LESS(DAE.ET_REAL()),DAE.RCONST(-1e-8)));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = Util.listReplaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.ET_REAL()),delta),nArgs1-(nArgs2+1), varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, tuple_, builtin, et, inlineType), DAE.SUB(DAE.ET_REAL()), DAE.CALL(fname, varExpListTotal, tuple_, builtin, et, inlineType)), DAE.DIV(DAE.ET_REAL()), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialNumericalDifferentiation;

protected function differentiateAlgorithmStatements
  // function: differentiateAlgorithmStatements
  // author: lochel
  input list<DAE.Statement> inStatements;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions)
    local
      list<DAE.Statement> restStatements,statementLst,elseif_statementLst,else_statementLst;
      DAE.ComponentRef var,cref;
      list<DAE.ComponentRef> dependentVars;
      DAE.FunctionTree functions;
      
      DAE.Exp e1,e2,lhsExps,rhsExps,exp,exp2,elseif_exp;
      DAE.ExpType type_;
      
      DAE.Statement currStmt;
      list<DAE.Statement> derivedStatements1;
      list<DAE.Statement> derivedStatements2;
      
      list<DAE.Exp> eLst, exps1, exps2;
      
      list<DAE.ComponentRef> vars1, vars2;
      list<DAE.Algorithm> algorithms;
      DAE.ElementSource elemSrc,source;
      DAE.Else elseif_else_;
      Boolean iterIsArray;
      DAE.Ident ident;
      
    case({}, _, _) then {};
      
    case((currStmt as DAE.STMT_ASSIGN(type_=type_, exp1=e1, exp=e2))::restStatements, var, functions) equation
      lhsExps = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      rhsExps = differentiateWithRespectToX(e2, var, functions, {}, {}, {});
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, lhsExps, rhsExps, DAE.emptyElementSource), currStmt};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_TUPLE_ASSIGN(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
    then fail();
      
    case(DAE.STMT_ASSIGN_ARR(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE(), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, iter=ident, range=exp, statementLst=statementLst, source=elemSrc)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      
      /*cref = ComponentReference.makeCrefIdent(ident, DAE.ET_INT(), {});
      cref = differentiateVarWithRespectToX(cref, var, {});
      exp2 = DAE.CREF(cref, DAE.ET_INT());
      
      derivedStatements2 = {DAE.STMT_ASSIGN(DAE.ET_INT(), exp2, DAE.ICONST(StateVar);0), DAE.emptyElementSource)};
      derivedStatements1 = listAppend(derivedStatements2, derivedStatements1);*/
      
      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, exp, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
        
    case(DAE.STMT_WHILE(exp=e1, statementLst=statementLst, source=elemSrc)::restStatements, var, functions)
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_WHILE(e1, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_WHEN(exp=e2)::restStatements, var, functions) equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_ASSERT(cond=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_TERMINATE(msg=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(DAE.STMT_REINIT(value=e2)::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements2;
      
    case(DAE.STMT_NORETCALL(exp=e1, source=elemSrc)::restStatements, var, functions) equation
      e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();
      
    case((currStmt as DAE.STMT_RETURN(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_BREAK(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

public function determineIndices
  // function: determineIndices
  // using column major order
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStates2;
  input Integer inActInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inStates, inStates2, inActInd,inAllVars)
    local
      list<tuple<String,Integer>> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr;
      Boolean searchForStates;
      Integer actInd;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _) then {};
    case (curr::rest, states, actInd, allVars) equation
      (str, actInd) = determineIndices2(curr, states, actInd, allVars);
      erg = determineIndices(rest, states, actInd, allVars);
      str = listAppend(str, erg);
    then str;
  end matchcontinue;
end determineIndices;

protected function determineIndices2
  // function: determineIndices2
  input DAE.ComponentRef inDStates;
  input list<DAE.ComponentRef> inStates;
  input Integer actInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars)
    local
      tuple<String,Integer> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars) equation
      new = differentiateVarWithRespectToX(dState,curr,allVars);
      str = (ComponentReference.printComponentRefStr(new) ,actInd);
      actInd = actInd+1;      
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars);
    then (str::erg, actInd);
    case (_,_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.determineIndices2() failed"});
    then fail();
  end matchcontinue;
end determineIndices2;

public function changeIndices
  input list<BackendDAE.Var> derivedVariables;
  input list<tuple<String,Integer>> outTuple;
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Var> derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
  (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariables,outTuple,inBinTree)
    local
      list<BackendDAE.Var> rest,changedVariables;
      BackendDAE.Var derivedVariable;
      list<tuple<String,Integer>> restTuple;
      BackendDAE.BinTree bt;
    case ({},_,bt) then ({},bt);
    case (derivedVariable::rest,restTuple,bt) equation
      (derivedVariable,bt) = changeIndices2(derivedVariable,restTuple,bt);
      (changedVariables,bt) = changeIndices(rest,restTuple,bt);
    then (derivedVariable::changedVariables,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.changeIndices() failed"});
    then fail();      
  end matchcontinue;
end changeIndices;

protected function changeIndices2
  input BackendDAE.Var derivedVariable;
  input list<tuple<String,Integer>> varIndex; 
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
 (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariable, varIndex,inBinTree)
    local
      BackendDAE.Var curr, changedVar;
      DAE.ComponentRef currCREF;
      list<tuple<String,Integer>> restTuple;
      String currVar;
      Integer currInd;
      BackendDAE.BinTree bt;
      list<Integer> varInt;
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      true = stringEqual(currVar,ComponentReference.printComponentRefStr(currCREF));
      changedVar = BackendVariable.setVarIndex(curr,currInd);
      Debug.fcall("varIndex2",print, currVar +& " " +& intString(currInd)+&"\n");
      bt = BackendDAEUtil.treeAddList(bt,{currCREF});
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),{},bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
    then (changedVar,bt);      
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
      (changedVar,bt) = changeIndices2(changedVar,restTuple,bt);
    then (changedVar,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"Linearization.changeIndices2() failed"});
    then fail();      
  end matchcontinue;
end changeIndices2;


end BackendDAEOptimize;
