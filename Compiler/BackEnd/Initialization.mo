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
  
encapsulated package Initialization
" file:        Initialization.mo
  package:     Initialization 
  description: Initialization.mo contains everything needed to set up the 
               BackendDAE for the initial system.

  RCS: $Id: Initialization.mo 14238 2012-12-05 14:00:00Z lochel $"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;
public import Util;

protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import CheckModel;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import List;

public function solveInitialSystem "public function solveInitialSystem
  author: jfrenkel, lochel
  This function generates a algebraic system of equations for the initialization and solves it."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output Option<BackendDAE.BackendDAE> outInitDAE;
algorithm
  (outDAE, outInitDAE) := matchcontinue(inDAE)
    local
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.Variables knvars, vars, fixvars, evars, eavars, avars;
      BackendDAE.EquationArray inieqns, eqns, emptyeqns, reeqns;
      BackendDAE.EqSystem initsyst;
      BackendDAE.BackendDAE initdae;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree functionTree;
      array<DAE.Constraint> constraints;
      array<DAE.ClassAttributes> classAttrs;
      
    case(BackendDAE.DAE(systs, BackendDAE.SHARED(knownVars=knvars,
                                                 aliasVars=avars,
                                                 initialEqs=inieqns,
                                                 constraints=constraints,
                                                 classAttrs=classAttrs,
                                                 cache=cache,
                                                 env=env,
                                                 functionTree=functionTree))) equation
      true = Flags.isSet(Flags.SOLVE_INITIAL_SYSTEM);
      
      // collect vars and eqns for initial system
      vars = BackendVariable.emptyVars();
      fixvars = BackendVariable.emptyVars();
      eqns = BackendEquation.listEquation({});
      reeqns = BackendEquation.listEquation({});
      
      ((vars, fixvars)) = BackendVariable.traverseBackendDAEVars(knvars, collectInitialVars, (vars, fixvars));
      ((eqns, reeqns)) = BackendEquation.traverseBackendDAEEqns(inieqns, collectInitialEqns, (eqns, reeqns));
      
      Debug.fcall(Flags.TRACE_INITIAL_SYSTEM, print, "\ninitial equations (" +& intString(BackendDAEUtil.equationSize(eqns)) +& ")\n=================\n");
      Debug.fcall(Flags.TRACE_INITIAL_SYSTEM, BackendDump.dumpEqnsArray, eqns);
      
      ((vars, fixvars, eqns, reeqns)) = List.fold(systs, collectInitialVarsEqnsSystem, ((vars, fixvars, eqns, reeqns)));
      ((eqns, reeqns)) = BackendVariable.traverseBackendDAEVars(vars, collectInitialBindings, (eqns, reeqns));
      
      // collect pre(var) from alias
      //((_, vars, fixvars)) = traverseBackendDAEExpsEqns(eqns, collectAliasPreVars, (avars, vars, fixvars));
      //((_, vars, fixvars)) = traverseBackendDAEExpsEqns(reeqns, collectAliasPreVars, (avars, vars, fixvars));
      
      // generate initial system
      initsyst = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING());
      initsyst = analyzeInitialSystem(initsyst, inDAE);      
      (initsyst, _, _) = BackendDAEUtil.getIncidenceMatrix(initsyst, BackendDAE.NORMAL());
      BackendDAE.EQSYSTEM(vars, eqns, _, _, _) = initsyst;

      evars = BackendVariable.emptyVars();
      eavars = BackendVariable.emptyVars();
      emptyeqns = BackendEquation.listEquation({});
      initdae = BackendDAE.DAE({initsyst},
                               BackendDAE.SHARED(fixvars,
                                                 evars,
                                                 eavars,
                                                 emptyeqns,
                                                 reeqns,
                                                 constraints,
                                                 classAttrs,
                                                 cache,
                                                 env,
                                                 functionTree,
                                                 BackendDAE.EVENT_INFO({},{},{},{},0,0),
                                                 {},
                                                 BackendDAE.INITIALSYSTEM(),
                                                 {}));

      // some debug prints
      Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, print, "\n##################\n# initial system #\n##################\n\n");
      Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, initdae);
      
      // now let's solve the system!
      initdae = solveInitialSystem1(vars, eqns, inDAE, initdae);
    then (inDAE, SOME(initdae));
      
    case BackendDAE.DAE(systs, shared)
    then (inDAE, NONE());
  end matchcontinue;
end solveInitialSystem;

protected function solveInitialSystem1 "protected function solveInitialSystem1
  author: jfrenkel, lochel
  This is a helper function of solveInitialSystem and solves the generated system."
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.BackendDAE inInitDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := matchcontinue(inVars, inEqns, inDAE, inInitDAE)
    local
      BackendDAE.BackendDAE isyst;
      list<tuple<BackendDAEUtil.pastoptimiseDAEModule, String, Boolean>> pastOptModules;
      tuple<BackendDAEUtil.StructurallySingularSystemHandlerFunc, String, BackendDAEUtil.stateDeselectionFunc, String> daeHandler;
      tuple<BackendDAEUtil.matchingAlgorithmFunc, String> matchingAlgorithm;
      Integer nVars, nEqns;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      
    // over-determined system
    case(vars, eqns, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intGt(nEqns, nVars);
      
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "It was not possible to solve the over-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
      Debug.fcall(Flags.TRACE_INITIAL_SYSTEM, print, "\nover-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)\n");
    then fail();
    
    // equal  
    case(vars, eqns, _, _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intEq(nEqns, nVars);
      
      pastOptModules = BackendDAEUtil.getPastOptModules(SOME({"constantLinearSystem", /* here we need a special case and remove only alias and constant (no variables of the system) variables "removeSimpleEquations", */ "tearingSystem"}));
      matchingAlgorithm = BackendDAEUtil.getMatchingAlgorithm(NONE());
      daeHandler = BackendDAEUtil.getIndexReductionMethod(NONE());
      
      // solve system
      isyst = BackendDAEUtil.transformBackendDAE(inInitDAE, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
      
      // simplify system
      (isyst, Util.SUCCESS()) = BackendDAEUtil.pastoptimiseDAE(isyst, pastOptModules, matchingAlgorithm, daeHandler);
      
      Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, print, "\n#########################\n# solved initial system #\n#########################\n\n");
      Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpBackendDAE, isyst);
    then isyst;
    
    // under-determined system  
    case(_, _, _, _) equation
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(inEqns);
      true = intLt(nEqns, nVars);
      
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "It was not possible to solve the under-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)");
      Debug.fcall(Flags.TRACE_INITIAL_SYSTEM, print, "\nunder-determined initial system (" +& intString(nEqns) +& " equations and " +& intString(nVars) +& " variables)\n");
    then fail();
  end matchcontinue;
end solveInitialSystem1;

protected function analyzeInitialSystem "protected function analyzeInitialSystem
  author: lochel
  This function fixes discrete and state variables to balance the initial equation system."
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.BackendDAE inDAE;      // original DAE
  output BackendDAE.EqSystem outSystem;
protected
  BackendDAE.EqSystem system;
  BackendDAE.IncidenceMatrix m, mt;
algorithm
  (system, m, mt) := BackendDAEUtil.getIncidenceMatrix(inSystem, BackendDAE.NORMAL());
  system := analyzeInitialSystem1(system, mt, 1);     // fix discrete vars to get rid of unneeded pre-vars
  system := analyzeInitialSystem2(system, inDAE);     // fix unbalanced initial system if it is definite
  (outSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(system, BackendDAE.NORMAL());
end analyzeInitialSystem;

protected function analyzeInitialSystem1 "protected function analyzeInitialSystem1
  author: lochel"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.IncidenceMatrix inMT;    // IncidenceMatrix = array<list<IncidenceMatrixElementEntry>>;
  input Integer inI;                        // current row (var-index)
  output BackendDAE.EqSystem outSystem;
algorithm
  outSystem := matchcontinue(inSystem, inMT, inI)
    local
      BackendDAE.EqSystem system;
      Integer nVars;
      Integer nIncidences;
      BackendDAE.Variables vars;
      BackendDAE.Var var;
      DAE.ComponentRef cr, preCR;
      BackendDAE.EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
      
      BackendDAE.Equation eqn;
      DAE.Exp startExp, preExp;
      DAE.Type tp;
      String crStr;
      
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=orderedEqs), _, _) equation
      nVars = arrayLength(inMT);
      true = intGt(inI, nVars);
    then inSystem;
    
    case (_, _, _) equation
      nIncidences = listLength(inMT[inI]);
      true = intGt(nIncidences, 0);
      
      system = analyzeInitialSystem1(inSystem, inMT, inI+1);
    then system;
    
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=orderedEqs), _, _) equation
      nIncidences = listLength(inMT[inI]);
      true = intEq(nIncidences, 0);
      
      var = BackendVariable.getVarAt(vars, inI);
      preCR = BackendVariable.varCref(var);
      true = ComponentReference.isPreCref(preCR);
      cr = ComponentReference.popPreCref(preCR);
      
      crStr = ComponentReference.crefStr(cr);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "pre(" +& crStr +& ") does not appear in the initialization system. Assuming fixed start value for " +& crStr);

      tp = BackendVariable.varType(var);
            
      startExp = Expression.crefExp(cr);
      tp = Expression.typeof(startExp);
      startExp = Expression.makeBuiltinCall("$_start", {startExp}, tp);
      
      preExp = Expression.crefExp(preCR);
      
      eqn = BackendDAE.EQUATION(preExp, startExp, DAE.emptyElementSource);
      orderedEqs = BackendEquation.equationAdd(eqn, orderedEqs);
      
      system = BackendDAE.EQSYSTEM(vars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING());
      system = analyzeInitialSystem1(system, inMT, inI+1);
    then system;
    
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=orderedEqs), _, _) equation
      nIncidences = listLength(inMT[inI]);
      true = intEq(nIncidences, 0);
      
      var = BackendVariable.getVarAt(vars, inI);
      cr = BackendVariable.varCref(var);
      false = ComponentReference.isPreCref(cr);
      
      crStr = "Following variable does not appear in any of the equations of the initialization system: " +& ComponentReference.crefStr(cr);
      Error.addMessage(Error.INTERNAL_ERROR, {crStr});
    then fail();
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function analyzeInitialSystem1 failed"});
    then fail();
  end matchcontinue;
end analyzeInitialSystem1;

protected function analyzeInitialSystem2 "function analyzeInitialSystem2
  author lochel"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.BackendDAE inDAE;  // original DAE
  output BackendDAE.EqSystem outSystem;
algorithm
  outSystem := matchcontinue(inSystem, inDAE)
    local
      BackendDAE.EqSystem system;
      Integer nVars, nEqns;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      
    // over-determined system
    case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intGt(nEqns, nVars);
      
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "Trying to fix over-determined initial system... [not implemented yet!]");
    then fail();
    
    // under-determined system  
    case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _) equation
      nVars = BackendVariable.varsSize(vars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intLt(nEqns, nVars);
      
      (true, vars, eqns) = fixUnderDeterminedInitialSystem(inDAE, vars, eqns);
      
      system = BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING());
    then system;
    
    else
    then inSystem;
  end matchcontinue;
end analyzeInitialSystem2;

protected function fixUnderDeterminedInitialSystem "protected function fixUnderDeterminedInitialSystem
  author: lochel"
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  output Boolean outSucceed;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqns;
algorithm
  (outSucceed, outVars, outEqns) := matchcontinue(inDAE, inVars, inEqns)
    local
      BackendDAE.SparsePattern sparsityPattern;
      BackendDAE.BackendDAE dae;
      list< .DAE.ComponentRef> someStates;
      list<BackendDAE.Var> outputs; // $res1 ... $resN (initial equations)
      list<BackendDAE.Var> states;
      BackendDAE.EqSystems systs;
      BackendDAE.Variables ivars;
      Integer nVars, nStates, nEqns;
      BackendDAE.EquationArray eqns;
      list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> dep;
    
    // fix all states
    case(_, _, eqns) equation
      (dae, outputs) = BackendDAEOptimize.generateInitialMatricesDAE(inDAE);
            
      BackendDAE.DAE(eqs=systs) = inDAE;
      ivars = BackendVariable.emptyVars();
      ivars = List.fold(systs, collectUnfixedStatesFromSystem, ivars);
      states = BackendVariable.varList(ivars);

      nStates = BackendVariable.varsSize(ivars);
      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intEq(nVars, nEqns+nStates);
      
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(nVars-nEqns) +& " states:");
      eqns = addStartValueEquations(states, eqns);
    then (true, inVars, eqns);
    
    // fix a subset of unfixed states
    case(_, _, eqns) equation
      (dae, outputs) = BackendDAEOptimize.generateInitialMatricesDAE(inDAE);
      
      BackendDAE.DAE(eqs=systs) = inDAE;
      ivars = BackendVariable.emptyVars();
      ivars = List.fold(systs, collectUnfixedStatesFromSystem, ivars);
      states = BackendVariable.varList(ivars);

      nVars = BackendVariable.varsSize(inVars);
      nEqns = BackendDAEUtil.equationSize(eqns);
      true = intLt(nEqns, nVars);
      
      (sparsityPattern, _) = BackendDAEOptimize.generateSparsePattern(dae, states, outputs);
      (dep, _) = sparsityPattern;
      someStates = collectIndependentVars(dep, {});
      
      Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, print, "\ninitial equations ($res1 ... $resN) with respect to states\n");
      Debug.fcall(Flags.DUMP_INITIAL_SYSTEM, BackendDump.dumpSparsityPattern, sparsityPattern);
      
      true = intEq(nVars-nEqns, listLength(someStates));  // fix only if it is definite
      
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "Assuming fixed start value for the following " +& intString(nVars-nEqns) +& " variables:");
      eqns = addStartValueEquations1(someStates, eqns);
    then (true, inVars, eqns);
    
    else
    then (false, inVars, inEqns);
  end matchcontinue;
end fixUnderDeterminedInitialSystem;

protected function collectIndependentVars "protected function collectIndependentVars
  author lochel"
  input list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> inPattern;
  input list< .DAE.ComponentRef> inVars;
  output list< .DAE.ComponentRef> outVars;
algorithm
  outVars := matchcontinue(inPattern, inVars)
    local
      tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>> curr;
      list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> rest;
      .DAE.ComponentRef cr;
      list< .DAE.ComponentRef> crList, vars;
      
    case ({}, _)
    then inVars;
    
    case (curr::rest, _) equation
      (cr, crList) = curr;
      0 = listLength(crList);
    
      vars = collectIndependentVars(rest, inVars);
      vars = cr::vars;
    then vars;
    
    case (curr::rest, _) equation
      vars = collectIndependentVars(rest, inVars);
    then vars;
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function collectIndependentVars failed"});
    then fail();
  end matchcontinue;
end collectIndependentVars;

protected function addStartValueEquations "function addStartValueEquations
  author lochel"
  input list<BackendDAE.Var> inVars;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := matchcontinue(inVars, inEqns)
    local
      BackendDAE.Var var;
      list<BackendDAE.Var> vars;
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;
      DAE.Exp e, e1, crefExp, startExp;
      DAE.ComponentRef cref;
      DAE.Type tp;
      String crStr;
      
    case ({}, _)
    then inEqns;
    
    case (var::vars, eqns) equation
      cref = BackendVariable.varCref(var);
      tp = BackendVariable.varType(var);
      
      crefExp = DAE.CREF(cref, tp);
      
      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);
      
      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource);
      
      crStr = ComponentReference.crefStr(cref);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  " +& crStr);
      
      eqns = BackendEquation.equationAdd(eqn, eqns);
      eqns = addStartValueEquations(vars, eqns);
    then eqns;
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function addStartValueEquations failed"});
    then fail();
  end matchcontinue;
end addStartValueEquations;

protected function addStartValueEquations1 "function addStartValueEquations1
  author lochel
  Same as addStartValueEquations - just with list<DAE.ComponentRef> instead of list<BackendDAE.Var>"
  input list<DAE.ComponentRef> inVars;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns := matchcontinue(inVars, inEqns)
    local
      DAE.ComponentRef var;
      list<DAE.ComponentRef> vars;
      BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqns;
      DAE.Exp e, e1, crefExp, startExp;
      DAE.Type tp;
      String crStr;
      
    case ({}, _)
    then inEqns;
    
    case (var::vars, eqns) equation      
      crefExp = DAE.CREF(var, DAE.T_REAL_DEFAULT);
      
      e = Expression.crefExp(var);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("$_start", {e}, tp);
      
      eqn = BackendDAE.EQUATION(crefExp, startExp, DAE.emptyElementSource);
      
      crStr = ComponentReference.crefStr(var);
      Debug.fcall(Flags.PEDANTIC, Error.addCompilerWarning, "  " +& crStr);
      
      eqns = BackendEquation.equationAdd(eqn, eqns);
      eqns = addStartValueEquations1(vars, eqns);
    then eqns;
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function addStartValueEquations1 failed"});
    then fail();
  end matchcontinue;
end addStartValueEquations1;

protected function collectAliasPreVars
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables avars,vars,fixvars;
    case ((exp,(avars,vars,fixvars)))
      equation
         ((_,(avars,vars,fixvars))) = Expression.traverseExp(exp,collectAliasPreVarsExp,(avars,vars,fixvars));
       then
        ((exp,(avars,vars,fixvars)));
    case _ then inTpl;
  end matchcontinue;
end collectAliasPreVars;

protected function collectAliasPreVarsExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables avars,vars,fixvars;
      DAE.ComponentRef cr;
      BackendDAE.Var v;    
    // add it?
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {DAE.CREF(componentRef = cr)}),(avars,vars,fixvars)))
      equation
         (v::_,_) = BackendVariable.getVar(cr, avars);
         ((_,(vars,fixvars))) =  collectInitialVars((v,(vars,fixvars)));
      then
        ((e, (avars,vars,fixvars)));
    else then inTuple;
  end matchcontinue;
end collectAliasPreVarsExp;

protected function collectInitialVarsEqnsSystem "function collectInitialVarsEqnsSystem
  author: lochel, Frenkel TUD 2012-10
  This function collects variables and equations for the initial system out of an given EqSystem."
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.EquationArray> iTpl;
  output tuple<BackendDAE.Variables, BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.EquationArray> oTpl;
protected
  BackendDAE.Variables orderedVars, vars, fixvars;
  BackendDAE.EquationArray orderedEqs, eqns, reqns;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs) := isyst;
  (vars, fixvars, eqns, reqns) := iTpl;

  ((vars, fixvars)) := BackendVariable.traverseBackendDAEVars(orderedVars, collectInitialVars, (vars, fixvars));
  ((eqns, reqns)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, collectInitialEqns, (eqns, reqns));

  oTpl := (vars, fixvars, eqns, reqns);
end collectInitialVarsEqnsSystem;

protected function collectUnfixedStatesFromSystem
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
protected
  BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := isyst;
  outVars := BackendVariable.traverseBackendDAEVars(vars, collectUnfixedStates, inVars);
end collectUnfixedStatesFromSystem;

protected function collectUnfixedStates
  input tuple<BackendDAE.Var, BackendDAE.Variables> inTpl;
  output tuple<BackendDAE.Var, BackendDAE.Variables> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, preCR;
    
    // state
    case((var as BackendDAE.VAR(varKind=BackendDAE.STATE()), vars)) equation
      false = BackendVariable.varFixed(var);
      vars = BackendVariable.addVar(var, vars);
    then ((var, vars));
    
    else
    then inTpl;
  end matchcontinue;
end collectUnfixedStates;

protected function collectInitialVars "protected function collectInitialVars
  This function collects all the vars for the initial system."
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.Variables>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, preVar, derVar;
      BackendDAE.Variables vars, fixvars;
      DAE.ComponentRef cr, preCR, derCR;
      Boolean isFixed;
      DAE.Type ty;
      DAE.InstDims arryDim;
      Option<DAE.Exp> startValue;
      DAE.Exp startExp;
      String errorMessage;
    
    // state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varType=ty, arryDim=arryDim), (vars, fixvars))) equation
      isFixed = BackendVariable.varFixed(var);
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      
      derCR = ComponentReference.crefPrefixDer(cr);  // cr => $DER.cr
      derVar = BackendDAE.VAR(derCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      
      vars = BackendVariable.addVar(derVar, vars);
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, var, fixvars, fixvars);
    then ((var, (vars, fixvars)));
    
    // discrete
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), varType=ty, arryDim=arryDim), (vars, fixvars))) equation
      isFixed = BackendVariable.varFixed(var);
      startValue = BackendVariable.varStartValueOption(var);
      
      var = BackendVariable.setVarFixed(var, false);
      
      preCR = ComponentReference.crefPrefixPre(cr);  // cr => $PRE.cr
      preVar = BackendDAE.VAR(preCR, BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      preVar = BackendVariable.setVarFixed(preVar, isFixed);
      preVar = BackendVariable.setVarStartValueOption(preVar, startValue);
      
      vars = BackendVariable.addVar(var, vars);
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, preVar, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, preVar, fixvars, fixvars);
    then ((var, (vars, fixvars)));
    
    // parameter (without binding)
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM(), bindExp=NONE()), (vars, fixvars))) equation
      true = BackendVariable.varFixed(var);
      startExp = BackendVariable.varStartValueType(var);
      var = BackendVariable.setBindExp(var, startExp);
      
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars)));
    
    // parameter
    case((var as BackendDAE.VAR(varKind=BackendDAE.PARAM()), (vars, fixvars))) equation
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars)));

    // constant
    case((var as BackendDAE.VAR(varKind=BackendDAE.CONST()), (vars, fixvars))) // equation
      // fixvars = BackendVariable.addVar(var, fixvars);
    then ((var, (vars, fixvars)));

    case((var as BackendDAE.VAR(bindExp=NONE()), (vars, fixvars))) equation
      isFixed = BackendVariable.varFixed(var);
      
      vars = Debug.bcallret2(not isFixed, BackendVariable.addVar, var, vars, vars);
      fixvars = Debug.bcallret2(isFixed, BackendVariable.addVar, var, fixvars, fixvars);
    then ((var, (vars, fixvars)));
    
    case((var as BackendDAE.VAR(bindExp=SOME(_)), (vars, fixvars))) equation
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, fixvars)));
    
    case ((var, _)) equation
      errorMessage = "./Compiler/BackEnd/BackendDAEUtil.mo: function collectInitialVars failed for: " +& BackendDump.varString(var);
      Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
    then fail();

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function collectInitialVars failed"});
    then fail();
  end matchcontinue;
end collectInitialVars;

protected function collectInitialBindings "protected function collectInitialBindings
  This function collects all the vars for the initial system."
  input tuple<BackendDAE.Var, tuple<BackendDAE.EquationArray,BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.EquationArray,BackendDAE.EquationArray>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      BackendDAE.Var var, preVar, derVar;
      BackendDAE.Variables vars, fixvars;
      DAE.ComponentRef cr, preCR, derCR;
      Boolean isFixed;
      DAE.Type ty;
      DAE.InstDims arryDim;
      Option<DAE.Exp> startValue;
      String errorMessage;
      BackendDAE.EquationArray eqns, reeqns;
      .DAE.Exp bindExp, crefExp;
      .DAE.ElementSource source;
      BackendDAE.Equation eqn;
    
    // no binding
    case((var as BackendDAE.VAR(bindExp=NONE()), (eqns, reeqns)))
    then ((var, (eqns, reeqns)));
    
    // discrete
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DISCRETE(), bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns))) equation
      crefExp = DAE.CREF(cr, ty);      
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));
    
    // parameter
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.PARAM(), bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns))) equation
      crefExp = DAE.CREF(cr, ty);      
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));
    
    // variable
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.VARIABLE(), bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns))) equation
      crefExp = DAE.CREF(cr, ty);      
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));
    
    // dummy-der
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DUMMY_DER(), bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns))) equation
      crefExp = DAE.CREF(cr, ty);      
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));
    
    // dummy-state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.DUMMY_STATE(), bindExp=SOME(bindExp), varType=ty, source=source), (eqns, reeqns))) equation
      crefExp = DAE.CREF(cr, ty);      
      eqn = BackendDAE.EQUATION(crefExp, bindExp, source);
      eqns = BackendEquation.equationAdd(eqn, eqns);
    then ((var, (eqns, reeqns)));
    
    case ((var, _)) equation
      errorMessage = "./Compiler/BackEnd/BackendDAEUtil.mo: function collectInitialBindings failed for: " +& BackendDump.varString(var);
      Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
    then fail();
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function collectInitialBindings failed"});
    then fail();
  end match;
end collectInitialBindings;

protected function generateInactiveWhenEquationForInitialization "function generateInactiveWhenEquationForInitialization
  author: lochel
  This function ... I guess the function name says it all!"
  input .DAE.ComponentRef inCRef;
  input .DAE.ElementSource inSource;
  output BackendDAE.Equation outEqn;
protected
  .DAE.Type identType;
  .DAE.ComponentRef preCR;
algorithm
  identType := ComponentReference.crefType(inCRef);
  preCR := ComponentReference.crefPrefixPre(inCRef);
  outEqn := BackendDAE.EQUATION(DAE.CREF(inCRef, identType), DAE.CREF(preCR, identType), inSource);
end generateInactiveWhenEquationForInitialization;

protected function generateInactiveWhenAlgStatementForInitialization "function generateInactiveWhenAlgStatementForInitialization
  author: lochel
  This function ... I guess the function name says it all!"
  input .DAE.ComponentRef inCRef;
  input .DAE.ElementSource inSource;
  output .DAE.Statement outAlgStatement;
protected
  .DAE.Type identType;
  .DAE.ComponentRef preCR;
algorithm
  identType := ComponentReference.crefType(inCRef);
  preCR := ComponentReference.crefPrefixPre(inCRef);
  outAlgStatement := DAE.STMT_ASSIGN(identType, DAE.CREF(inCRef, identType), DAE.CREF(preCR, identType), inSource);
end generateInactiveWhenAlgStatementForInitialization;

protected function generateInitialWhenEqn "public function generateInitialWhenEqn
  author: lochel
  This function generates out of a given when-equation, a equation for the initialization-problem."
  input BackendDAE.Equation inEqn;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue(inEqn)
    local
      .DAE.Exp condition        "The when-condition" ;
      .DAE.ComponentRef left    "Left hand side of equation" ;
      .DAE.Exp right            "Right hand side of equation" ;
      .DAE.ElementSource source "origin of equation";
      BackendDAE.Equation eqn;
      .DAE.Type identType;
      String errorMessage;
      .DAE.Algorithm alg;
      list< .DAE.ComponentRef> crefLst;
      list< .DAE.Statement> algStmts;
      Integer size;
      
    // active when equation during initialization
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(condition=condition, left=left, right=right), source=source) equation
      true = Expression.containsInitialCall(condition, false);  // do not use Expression.traverseExp
      identType = ComponentReference.crefType(left);
      eqn = BackendDAE.EQUATION(DAE.CREF(left, identType), right, source);
    then eqn;
    
    // inactive when equation during initialization
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(condition=condition, left=left, right=right), source=source) equation
      false = Expression.containsInitialCall(condition, false);
      eqn = generateInactiveWhenEquationForInitialization(left, source);
    then eqn;
    
    case eqn equation
      errorMessage = "./Compiler/BackEnd/BackendDAEUtil.mo: function generateInitialWhenEqn failed for:\n" +& BackendDump.equationString(eqn);
      Error.addMessage(Error.INTERNAL_ERROR, {errorMessage});
    then fail();
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function generateInitialWhenEqn failed"});
    then fail();
  end matchcontinue;
end generateInitialWhenEqn;

protected function generateInitialWhenAlg "public function generateInitialWhenAlg
  author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem."
  input BackendDAE.Equation inEqn;
  output BackendDAE.Equation outEqn;
protected
  Integer size;
  .DAE.Algorithm alg;
  .DAE.ElementSource source;
  list< .DAE.Statement> stmts;
algorithm
  BackendDAE.ALGORITHM(size=size, alg=alg, source=source) := inEqn;
  DAE.ALGORITHM_STMTS(statementLst=stmts) := alg;
  stmts := generateInitialWhenAlg1(stmts);
  alg := DAE.ALGORITHM_STMTS(stmts);
  outEqn := BackendDAE.ALGORITHM(size, alg, source);
end generateInitialWhenAlg;

protected function generateInitialWhenAlg1 "public function generateInitialWhenAlg1
  author: lochel
  This function generates out of a given when-algorithm, a algorithm for the initialization-problem."
  input list< .DAE.Statement> inStmts;
  output list< .DAE.Statement> outStmts;
algorithm
  outStmts := matchcontinue(inStmts)
    local
      .DAE.Exp condition        "The when-condition" ;
      .DAE.ComponentRef left    "Left hand side of equation" ;
      .DAE.Exp right            "Right hand side of equation" ;
      BackendDAE.Equation eqn;
      .DAE.Type identType;
      String errorMessage;
      list< .DAE.ComponentRef> crefLst;
      .DAE.Statement stmt;
      list< .DAE.Statement> stmts, rest;
      Integer size "size of equation" ;
      .DAE.Algorithm alg;
      .DAE.ElementSource source "origin of when-stmt";
      .DAE.ElementSource algSource "origin of algorithm";
      
    case {} then {};
    
    // active when equation during initialization
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts)::rest equation
      true = Expression.containsInitialCall(condition, false);
      rest = generateInitialWhenAlg1(rest);
      stmts = listAppend(stmts, rest);
    then stmts;
    
    // inactive when equation during initialization
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts, source=source)::rest equation
      false = Expression.containsInitialCall(condition, false);
      crefLst = CheckModel.algorithmStatementListOutputs(stmts);
      stmts = List.map1(crefLst, generateInactiveWhenAlgStatementForInitialization, source);
      rest = generateInitialWhenAlg1(rest);
      stmts = listAppend(stmts, rest);
    then stmts;
    
    // no when equation
    case stmt::rest equation
      // false = isWhenStmt(stmt);
      rest = generateInitialWhenAlg1(rest);
    then stmt::rest;
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/BackendDAEUtil.mo: function generateInitialWhenAlg1 failed"});
    then fail();
  end matchcontinue;
end generateInitialWhenAlg1;

protected function collectInitialEqns
  input tuple<BackendDAE.Equation, tuple<BackendDAE.EquationArray,BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.EquationArray,BackendDAE.EquationArray>> outTpl;
protected
  BackendDAE.Equation eqn, eqn1;
  BackendDAE.EquationArray eqns, reeqns;
  Integer size;
  Boolean b, isAlg, isWhen;
algorithm
  (eqn, (eqns, reeqns)) := inTpl;
  
  // replace der(x) with $DER.x and replace pre(x) with $PRE.x
  (eqn1, _) := BackendEquation.traverseBackendDAEExpsEqn(eqn, replaceDerPreCref, 0);
  
  // traverse when equations
  isWhen := BackendEquation.isWhenEquation(eqn);
  eqn1 := Debug.bcallret1(isWhen, generateInitialWhenEqn, eqn1, eqn1);
  
  // traverse when algorithms
  isAlg := BackendEquation.isAlgorithm(eqn);
  eqn1 := Debug.bcallret1(isAlg, generateInitialWhenAlg, eqn1, eqn1);
  
  // add it, if size is zero (terminate,assert,noretcall) move to removed equations
  size := BackendEquation.equationSize(eqn1);
  b := intGt(size, 0);
  
  eqns := Debug.bcallret2(b, BackendEquation.equationAdd, eqn1, eqns, eqns);
  reeqns := Debug.bcallret2(not b, BackendEquation.equationAdd, eqn1, reeqns, reeqns);
  outTpl := (eqn, (eqns, reeqns));
end collectInitialEqns;

protected function replaceDerPreCref "function replaceDerPreCref
  author: Frenkel TUD 2011-05
  helper for collectInitialEqns"
  input tuple<DAE.Exp, Integer> inExp;
  output tuple<DAE.Exp, Integer> outExp;
protected
   DAE.Exp e;
   Integer i;  
algorithm
  (e, i) := inExp;
  outExp := Expression.traverseExp(e, replaceDerPreCrefExp, i);
end replaceDerPreCref;

protected function replaceDerPreCrefExp "function replaceDerPreCrefExp
  author: Frenkel TUD 2011-05
  helper for replaceDerCref"
  input tuple<DAE.Exp, Integer> inExp;
  output tuple<DAE.Exp, Integer> outExp;
algorithm
  (outExp) := matchcontinue(inExp)
    local
      DAE.ComponentRef dummyder, cr;
      DAE.Type ty;
      Integer i;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), i)) equation
      dummyder = ComponentReference.crefPrefixDer(cr);
    then ((DAE.CREF(dummyder, ty), i+1));
    
    case ((DAE.CALL(path = Absyn.IDENT(name = "pre"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), i)) equation
      dummyder = ComponentReference.crefPrefixPre(cr);
    then ((DAE.CREF(dummyder, ty), i+1));
      
    else
    then inExp;
  end matchcontinue;
end replaceDerPreCrefExp;
end Initialization;
