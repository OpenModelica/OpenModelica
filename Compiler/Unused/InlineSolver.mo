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

encapsulated package InlineSolver
" file:        InlineSolver.mo
  package:     InlineSolver
  description: InlineSolver.mo contains everything needed to set up the
               BackendDAE for the inline solver


public import Absyn;
public import BackendDAE;
public import BackendDAEFunc;
public import DAE;
public import FCore;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import List;
protected import Util;

// =============================================================================
// section for all public functions
//
// These are functions, that can be used to do anything regarding inline solver.
// =============================================================================

public function generateDAE "author: lochel
  This function generates a algebraic system of equations for the inline solver"
  input BackendDAE.BackendDAE inDAE;
  output Option<BackendDAE.BackendDAE> outDAE;
  output Option<BackendDAE.Variables> outInlineVars;
protected
  BackendDAE.Variables vars;
algorithm
  (outDAE, outInlineVars) := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE dae;

    case _ equation /*do nothing */
      false = Flags.isSet(Flags.INLINE_SOLVER);
    then (NONE(), NONE());

    case dae equation
      true = Flags.isSet(Flags.INLINE_SOLVER);

      Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver: raw system");

      /* dae -> algebraic system */
      (dae,vars) = dae_to_algSystem(dae);

      /* output: algebraic system */
      Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver: algebraic system");
    then (SOME(dae), SOME(vars));

    else equation /* don't work */
      Error.addCompilerWarning("./Compiler/BackEnd/InlineSolver.mo: function generateDAE failed");
      Error.addCompilerWarning("inline solver can not be used.");
    then (NONE(), NONE());
  end matchcontinue;
end generateDAE;

protected function dae_to_algSystem "author: vitalij
  This is a helper function for generateDAE.
  Transformation dae in algebraic system"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
  output BackendDAE.Variables outInlineVars;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.EqSystem timesystem;
  BackendDAE.Shared shared;

  BackendDAE.Variables orderedVars, vars;
  BackendDAE.EquationArray orderedEqs;

  /*need for new matching */
  list<tuple<BackendDAEFunc.postOptimizationDAEModule, String, Boolean>> pastOptModules;
  tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc, String, BackendDAEFunc.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEFunc.matchingAlgorithmFunc, String> matchingAlgorithm;
  BackendDAE.BackendDAE dae;

algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  ((systs,vars)) := List.fold(systs, eliminatedStatesDerivations,({},BackendVariable.emptyVars()));
  timesystem := timeEquation();
  systs := listAppend(systs, {timesystem});
  shared := addKnowInitialValueForState(shared,vars);
  dae := BackendDAE.DAE(systs, shared);
  Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver: befor mathching algebraic system");
  // matching options
  pastOptModules := BackendDAEUtil.getPostOptModules(SOME({"constantLinearSystem", "simplifyTimeIndepFuncCalls", "removeSimpleEquations", "tearingSystem", "removeConstants"}));
  matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
  daeHandler := BackendDAEUtil.getIndexReductionMethod(NONE());

  // solve system
  dae := BackendDAEUtil.transformBackendDAE(dae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
  // simplify system
  (outDAE, Util.SUCCESS()) := BackendDAEUtil.postOptimizeDAE(dae, pastOptModules, matchingAlgorithm, daeHandler);

  outInlineVars := BackendVariable.emptyVars();
end dae_to_algSystem;

protected function addKnowInitialValueForState "author: vitalij"
  input BackendDAE.Shared inShared;
  input BackendDAE.Variables invars;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Var var;
  BackendDAE.Variables knownVars, externalObjects, aliasVars;
  BackendDAE.EquationArray initialEqs;
  BackendDAE.EquationArray removedEqs;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  FCore.Cache cache;
  FCore.Graph env;
  DAE.FunctionTree functionTree;
  BackendDAE.EventInfo eventInfo;
  BackendDAE.ExternalObjectClasses extObjClasses;
  BackendDAE.BackendDAEType backendDAEType;
  BackendDAE.SymbolicJacobians symjacs;
  BackendDAE.ExtraInfo ei;
algorithm
   BackendDAE.SHARED(knownVars=knownVars, externalObjects=externalObjects, aliasVars=aliasVars,initialEqs=initialEqs, removedEqs=removedEqs, constraints=constrs, classAttrs=clsAttrs, cache=cache, env=env, functionTree=functionTree, eventInfo=eventInfo, extObjClasses=extObjClasses, backendDAEType=backendDAEType, symjacs=symjacs, info = ei) := inShared;
   knownVars := BackendVariable.mergeVariables(invars, knownVars);
   var := BackendDAE.VAR(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
   knownVars := BackendVariable.addVar(var, knownVars);
   outShared := BackendDAE.SHARED(knownVars, externalObjects, aliasVars,initialEqs, removedEqs, constrs, clsAttrs, cache, env, functionTree, eventInfo, extObjClasses, backendDAEType, symjacs, ei);
end addKnowInitialValueForState;

protected function timeEquation "author: vitalij"
  output BackendDAE.EqSystem outEqSystem;
protected
  BackendDAE.EqSystem eqSystem;
  BackendDAE.Equation eqn;
  BackendDAE.EquationArray eqns;
  DAE.ComponentRef cr,t0,t1,t2,t3,t4;
  DAE.Exp rhs, dt,t;
  BackendDAE.Variables vars;
  DAE.Type ty;
  BackendDAE.Var var;
algorithm
  ty := DAE.T_REAL_DEFAULT;
  eqns := BackendEquation.emptyEqns();
  vars := BackendVariable.emptyVars();
  ty := DAE.T_REAL_DEFAULT;
  cr := DAE.CREF_IDENT("time", ty, {});

  (_,var):= stringCrVar("$t0", cr, ty, {});
  vars := BackendVariable.addVar(var, vars);
  (_,var):= stringCrVar("$t1", cr, ty, {});
  vars := BackendVariable.addVar(var, vars);
  (_,var):= stringCrVar("$t2", cr, ty, {});
  vars := BackendVariable.addVar(var, vars);
  (_,var):= stringCrVar("$t3", cr, ty, {});
  vars := BackendVariable.addVar(var, vars);
  (_,var):= stringCrVar("$t4", cr, ty, {});
  vars := BackendVariable.addVar(var, vars);

  t := DAE.CREF(cr,ty);
  t0 := ComponentReference.crefPrefixString("$t0", cr);
  t1 := ComponentReference.crefPrefixString("$t1", cr);
  t2 := ComponentReference.crefPrefixString("$t2", cr);
  t3 := ComponentReference.crefPrefixString("$t3", cr);
  t4 := ComponentReference.crefPrefixString("$t4", cr);
  dt := DAE.CREF(DAE.CREF_IDENT("$dt", ty, {}), ty);

  eqn := BackendDAE.SOLVED_EQUATION(t0, t, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  rhs := Expression.expAdd(Expression.expMul(DAE.RCONST(0.1726731646460114281008537718766),dt),t);
  eqn := BackendDAE.SOLVED_EQUATION(t1, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  rhs := Expression.expAdd(Expression.expMul(DAE.RCONST(0.50),dt),t);
  eqn := BackendDAE.SOLVED_EQUATION(t2, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  rhs := Expression.expAdd(Expression.expMul(DAE.RCONST(0.8273268353539885718991462281234),dt),t);
  eqn := BackendDAE.SOLVED_EQUATION(t3, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  rhs := Expression.expAdd(dt,t);
  eqn := BackendDAE.SOLVED_EQUATION(t4, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  eqSystem := BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(),{});
  (outEqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(eqSystem, BackendDAE.NORMAL(),NONE());
end timeEquation;

protected function eliminatedStatesDerivations "author: vitalij
  This is a helper function for dae_to_algSystem.
  change function call der(x) in  variable xder
  change kind: state in known variable"
  input BackendDAE.EqSystem inEqSystem;
  input tuple<BackendDAE.EqSystems, BackendDAE.Variables> inTupel ;
  output tuple<BackendDAE.EqSystems, BackendDAE.Variables> outTupel;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.Variables vars, invars, outvars,inlinevars,inInlinevars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.EquationArray eqns, eqns1, eqns2;
  BackendDAE.EqSystem eqSystem;
  BackendDAE.EqSystems inSystems;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := inEqSystem;
  (inSystems, invars) := inTupel;
  vars := BackendVariable.emptyVars();
  eqns := BackendEquation.emptyEqns();
  eqns2 := BackendEquation.emptyEqns();
  // change function call der(x) in  variable xder
  ((_, eqns1,_,_)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates_eqs, (orderedVars, eqns,"$t0","$t0_der"));
  eqns2 :=  BackendEquation.mergeEquationArray(eqns1,eqns2);
  ((_, eqns1,_,_)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates_eqs, (orderedVars, eqns,"$t1","$t1_der"));
  eqns2 :=  BackendEquation.mergeEquationArray(eqns1,eqns2);
  ((_, eqns1,_,_)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates_eqs, (orderedVars, eqns,"$t2","$t2_der"));
  eqns2 :=  BackendEquation.mergeEquationArray(eqns1,eqns2);
  ((_, eqns1,_,_)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates_eqs, (orderedVars, eqns,"$t3","$t3_der"));
  eqns2 :=  BackendEquation.mergeEquationArray(eqns1,eqns2);
  ((_, eqns1,_,_)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates_eqs, (orderedVars, eqns,"$t4","$t4_der"));
  eqns2 :=  BackendEquation.mergeEquationArray(eqns1,eqns2);
  // change kind: state in known variable
  ((vars, eqns, outvars)) := BackendVariable.traverseBackendDAEVars(orderedVars, replaceStates_vars, (vars, eqns2, invars));
  eqSystem := BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets);
  (eqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(eqSystem, BackendDAE.NORMAL(),NONE());
  outTupel := (listAppend(inSystems,{eqSystem}), BackendVariable.mergeVariables(invars,outvars));
end eliminatedStatesDerivations;

protected function replaceStates_eqs "author: vitalij
  This is a helper function for eliminiertStatesDerivations.
  replace der(x) with $DER.x."
  input tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, BackendDAE.EquationArray, String, String>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, BackendDAE.EquationArray, String, String>> outTpl;
protected
  BackendDAE.Equation eqn, eqn1;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  String preState;
  String preDer;
  Boolean derEq;
  DAE.Exp e1,e2;
algorithm
  (eqn, (vars, eqns, preState, preDer)) := inTpl;
  // replace der(x) with $DER.x
  BackendDAE.EQUATION(exp=e1,scalar=e2) := eqn;
  derEq := isDerEq(e1);
  (eqn1, (_,_,_,_)) := BackendEquation.traverseBackendDAEExpsEqn(eqn, replaceDerStateCref, (vars, 0, preState, preDer));
  eqn1 := EqSolvedEq(eqn1, derEq);
  eqns := BackendEquation.addEquation(eqn1, eqns);
  outTpl := (eqn, (vars, eqns,preState,preDer));
end replaceStates_eqs;

protected function EqSolvedEq
"function EqSolvedEq"
  input BackendDAE.Equation inEqn;
  input Boolean b;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue(inEqn,b)
    local
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      Boolean differentiated;
      DAE.ComponentRef cr;
      BackendDAE.Equation eqn;
    case (BackendDAE.EQUATION(exp=e1,scalar=e2,source=source,differentiated=differentiated),true) equation
      cr = Expression.expCref(e1);
      eqn = BackendDAE.SOLVED_EQUATION(cr, e2, source, differentiated);
      then eqn;
    else
      then inEqn;
    end matchcontinue;
end EqSolvedEq;

protected function isDerEq
"author: vitalij
true if left site is only a call of der(...)
else false"
input DAE.Exp e1;
output Boolean b;
algorithm
  b := matchcontinue(e1)
    case  DAE.CALL(path = Absyn.IDENT(name = "der"))
      then true;
    else
      then false;
    end matchcontinue;
end isDerEq;

protected function replaceDerStateCref "author: vitalij
  This is a helper function for dae_to_algSystem."
  input tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer, String, String>> inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer, String, String>> outExp;
protected
   DAE.Exp e;
   Integer i;
   BackendDAE.Variables vars;
   String preState;
   String preDer;
algorithm
  (e, (vars, i, preState, preDer)) := inExp;
  outExp := Expression.traverseExp(e, replaceDerStateExp, (vars, i,preState,preDer));
end replaceDerStateCref;

protected function replaceDerStateExp "author: vitalij
  This is a helper function for replaceDerStateCref."
  input tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer, String, String>> inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer, String, String>> outExp;
algorithm
  (outExp) := matchcontinue(inExp)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      Integer i;
      BackendDAE.Variables vars;
      String preState;
      String preDer;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), (vars, i,preState,preDer))) equation
      cr = crefPrefixStringWithpopCref(preDer,cr); //der(x) for timepoint t0
    then ((DAE.CREF(cr, ty), (vars, i+1,preState, preDer)));

    case ((DAE.CREF(DAE.CREF_IDENT("time", ty, {}), _), (vars, i,preState,preDer))) equation
       cr = DAE.CREF_IDENT("time", ty, {});
       cr = crefPrefixStringWithpopCref(preState,cr);
    then ((DAE.CREF(cr, ty), (vars, i+1, preState, preDer)));
    case ((DAE.CREF(componentRef = cr, ty=ty), (vars, i,preState,preDer))) equation
      true = BackendVariable.isState(cr, vars);
      cr = ComponentReference.crefPrefixString(preState, cr); //x for timepoint t0
    then ((DAE.CREF(cr, ty), (vars, i+1, preState, preDer)));

    else
    then inExp;
  end matchcontinue;
end replaceDerStateExp;

protected function crefPrefixStringWithpopCref "author: vitalij"
  input String name;
  input DAE.ComponentRef in_cr;
  output DAE.ComponentRef out_cr;
 algorithm
   out_cr := ComponentReference.popCref(in_cr);
   out_cr := ComponentReference.crefPrefixString(name, out_cr);
end crefPrefixStringWithpopCref;

protected function replaceStates_vars "author: vitalij"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.Variables>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, var0;
      BackendDAE.Variables vars, vars0;
      DAE.ComponentRef cr, x0, x1, x2, x3, x4, derx0, derx1, derx2, derx3, derx4;
      DAE.Type ty;
      DAE.InstDims arryDim;
      BackendDAE.EquationArray eqns;
      //BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqn;
      DAE.Exp dt;

    // state
    case((var0 as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=_), varType=ty, arryDim=arryDim), (vars, eqns,vars0))) equation
      var = BackendVariable.setVarKind(var0, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);

      (x0,var) = stringCrVar("$t0", cr, ty, arryDim); // knownVars
      vars0 = BackendVariable.addVar(var, vars0);

      (x1,var) = stringCrVar("$t1",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (x2,var) = stringCrVar("$t2",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (x3,var) = stringCrVar("$t3",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (x4,var) = stringCrVar("$t4",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (derx0,var) = stringCrVar("$t0_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (derx1,var) = stringCrVar("$t1_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (derx2,var) = stringCrVar("$t2_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (derx3,var) = stringCrVar("$t3_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      (derx4,var) = stringCrVar("$t4_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);

      var = BackendVariable.setVarKind(var0, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);

      dt = DAE.CREF(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT);

      eqn = stepLobatt(x0, x1, x2, x3, x4, derx0, derx1, derx2, derx3, derx4, dt, ty);
      eqns = BackendEquation.mergeEquationArray(eqn, eqns);
      eqns = BackendEquation.addEquation(BackendDAE.SOLVED_EQUATION(cr, DAE.CREF(x4, ty), DAE.emptyElementSource, false), eqns);
    then ((var, (vars, eqns,vars0)));

    // else
    case((var, (vars, eqns,vars0))) equation
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, eqns,vars0)));

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/InlineSolver.mo: function replaceStates1_vars failed"});
    then fail();
  end matchcontinue;
end replaceStates_vars;

protected function stepLobatt "author: vitalij
  implicit Runge Kutta method"
  input DAE.ComponentRef x0_, x1_, x2_, x3_, x4_, derx0_, derx1_, derx2_, derx3_, derx4_;
  input DAE.Exp dt;
  input DAE.Type ty;
  output BackendDAE.EquationArray eqns;
protected
  DAE.Exp rhs, lhs;
  DAE.Exp x0, x1, x2, x3, x4;
  DAE.Exp f0, f1, f2, f3, f4;
  DAE.Exp k0, k1, k2, k3, k4, z0, z1;
  BackendDAE.Equation eqn;
algorithm
  eqns := BackendEquation.emptyEqns();

  f0 := DAE.CREF(derx0_, ty);
  f1 := DAE.CREF(derx1_, ty);
  f2 := DAE.CREF(derx2_, ty);
  f3 := DAE.CREF(derx3_, ty);
  f4 := DAE.CREF(derx4_, ty);

  x0 := DAE.CREF(x0_, ty);
  x1 := DAE.CREF(x1_, ty);
  x2 := DAE.CREF(x2_, ty);
  x3 := DAE.CREF(x3_, ty);
  x4 := DAE.CREF(x4_, ty);

  (k0, k1, k2, k3, k4, z0, z1) := LobattoTerms(
    DAE.RCONST(0.3922348462484228573781445426331),  //(0)
    DAE.RCONST(0.6934764274975466670326692885405),  //(1)
    DAE.RCONST(0.1258778219019580956563839488081),  // -(2)
    DAE.RCONST(0.0615951195845599998169986890631),  // (3)
    DAE.RCONST(0.02142857142857142857142857142857), //-(4)
    DAE.RCONST(5.791287847477920003294023596864),   // +0,-1
    f0, f1, f2, f3, f4, x0, x1);

  lhs := Expression.expAdd(z0, Expression.expMul(Expression.makeSum({k0, k1, k3}),dt));
  rhs := Expression.expAdd(z1, Expression.expMul(Expression.expAdd(k2, k4),dt));
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  (k0, k1, k2, k3, k4, z0, z1) := LobattoTerms(
      DAE.RCONST(0.08125000000000000000000000000000),  //(0)
      DAE.RCONST(0.6934764274975466670326692885405),  //(1)
      DAE.RCONST(0.3555555555555555555555555555556),  //(2)
      DAE.RCONST(0.0619239222016411115914895523205),  //-(3)
      DAE.RCONST(0.018750), //(4)
      DAE.RCONST(2.0),   // +0,-1
      f0, f1, f2, f3, f4, x0, x2);

  lhs := Expression.expAdd(z0, Expression.expMul(Expression.makeSum({k0, k1, k2, k4}),dt));
  rhs := Expression.expAdd(z1, Expression.expMul(k3,dt));
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  (k0, k1, k2, k3, k4, z0, z1) := LobattoTerms(
      DAE.RCONST(0.0649080108944342854789983145097),  //(0)
      DAE.RCONST(0.3161826581932177779607790887147),  //(1)
      DAE.RCONST(0.4560365520606882543865426789669),  //(2)
      DAE.RCONST(0.1843013502802311107451084892373),  //(3)
      DAE.RCONST(0.02142857142857142857142857142857), //-(4)
      DAE.RCONST(1.208712152522079996705976403136),   // +0,-1
      f0, f1, f2, f3, f4, x0, x3);

  lhs := Expression.expAdd(z0, Expression.expMul(Expression.makeSum({k0, k1, k2, k3}),dt));
  rhs := Expression.expAdd(z1, Expression.expMul(k4,dt));
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

  (k0, k1, k2, k3, k4, z0, z1) := LobattoTerms(
    DAE.RCONST(0.05000000000000000000000000000000),  //(0)
    DAE.RCONST(0.2722222222222222222222222222222),  //(1)
    DAE.RCONST(0.3555555555555555555555555555556),  //(2)
    DAE.RCONST(0.2722222222222222222222222222222),  //(3)
    DAE.RCONST(0.05000000000000000000000000000000), //(4)
    DAE.RCONST(1.0),   // +0,-1
    f0, f1, f2, f3, f4, x0, x4);

  lhs := Expression.expAdd(z0, Expression.expMul(Expression.makeSum({k0, k1, k2, k3,k4}),dt));
  rhs := z1;
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, false);
  eqns := BackendEquation.addEquation(eqn, eqns);

end stepLobatt;

protected function LobattoTerms
  input DAE.Exp a0, a1, a2, a3, a4, aa;
  input DAE.Exp f0, f1, f2, f3, f4, x0, x1;
  output DAE.Exp k0, k1, k2, k3, k4, z0, z1;
 algorithm
   k0 := Expression.expMul(a0, f0);
   k1 := Expression.expMul(a1, f1);
   k2 := Expression.expMul(a2, f2);
   k3 := Expression.expMul(a3, f3);
   k4 := Expression.expMul(a4, f4);
   z0 := Expression.expMul(aa, x0);
   z1 := Expression.expMul(aa, x1);
end LobattoTerms;

protected function stringCrVar "author: vitalij"
  input String varTyp;
  input DAE.ComponentRef inCR;
  input DAE.Type ty;
  input DAE.InstDims arryDim;
  output DAE.ComponentRef outCR;
  output BackendDAE.Var var;
algorithm
  outCR := ComponentReference.crefPrefixString(varTyp, inCR);
  var := BackendDAE.VAR(outCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
end stringCrVar;

end InlineSolver;
