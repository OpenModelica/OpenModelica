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
  
encapsulated package InlineSolver
" file:        InlineSolver.mo
  package:     InlineSolver 
  description: InlineSolver.mo contains everything needed to set up the 
               BackendDAE for the inline solver

  RCS: $Id$"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;

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

public function generateDAE "function generateDAE
  author: lochel
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

protected function dae_to_algSystem "function dae_to_algSystem
  author: vruge
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
  list<tuple<BackendDAEUtil.pastoptimiseDAEModule, String, Boolean>> pastOptModules;
  tuple<BackendDAEUtil.StructurallySingularSystemHandlerFunc, String, BackendDAEUtil.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEUtil.matchingAlgorithmFunc, String> matchingAlgorithm;
  BackendDAE.BackendDAE dae;
  
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  ((systs,vars,outInlineVars)) := List.fold(systs, eliminatedStatesDerivations,({},BackendVariable.emptyVars(),BackendVariable.emptyVars()));
  timesystem := timeEquation();
  systs := listAppend(systs, {timesystem});
  shared := addKnowInitialValueForState(shared,vars);
  dae := BackendDAE.DAE(systs, shared);
  
  Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver: befor mathching algebraic system");
  // matching options
  pastOptModules := BackendDAEUtil.getPastOptModules(SOME({"constantLinearSystem", "removeSimpleEquations", "tearingSystem"}));
  matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
  daeHandler := BackendDAEUtil.getIndexReductionMethod(NONE());
  
  // solve system
  dae := BackendDAEUtil.transformBackendDAE(dae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
  // simplify system
  (outDAE, Util.SUCCESS()) := BackendDAEUtil.pastoptimiseDAE(dae, pastOptModules, matchingAlgorithm, daeHandler);
end dae_to_algSystem;

protected function addKnowInitialValueForState "function addKnowInitialValueForState
  author: vruge"
  input BackendDAE.Shared inShared;
  input BackendDAE.Variables invars;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Var var;
  BackendDAE.Variables knownVars, externalObjects, aliasVars;
  BackendDAE.EquationArray initialEqs;
  BackendDAE.EquationArray removedEqs;
  array< DAE.Constraint> constraints;
  array< DAE.ClassAttributes> classAttrs;
  Env.Cache cache;
  Env.Env env;
  DAE.FunctionTree functionTree;
  BackendDAE.EventInfo eventInfo;
  BackendDAE.ExternalObjectClasses extObjClasses;
  BackendDAE.BackendDAEType backendDAEType;
  BackendDAE.SymbolicJacobians symjacs;  
algorithm
   BackendDAE.SHARED(knownVars=knownVars, externalObjects=externalObjects, aliasVars=aliasVars,initialEqs=initialEqs, removedEqs=removedEqs, constraints=constraints, classAttrs=classAttrs, cache=cache, env=env, functionTree=functionTree, eventInfo=eventInfo, extObjClasses=extObjClasses, backendDAEType=backendDAEType, symjacs=symjacs) := inShared;
   knownVars := BackendVariable.mergeVariables(invars, knownVars);
   var := BackendDAE.VAR(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
   knownVars := BackendVariable.addVar(var, knownVars);
   outShared := BackendDAE.SHARED(knownVars, externalObjects, aliasVars,initialEqs, removedEqs, constraints, classAttrs, cache, env, functionTree, eventInfo, extObjClasses, backendDAEType, symjacs);
end addKnowInitialValueForState;

protected function timeEquation "function timeEquation
  author: vruge"
  output BackendDAE.EqSystem outEqSystem;
protected 
  BackendDAE.EqSystem eqSystem;
  BackendDAE.Equation eqn;
  BackendDAE.EquationArray eqns;
  DAE.ComponentRef cr,t0,t1,t2,t3,t4;
  DAE.Exp rhs0, lhs0, rhs1, lhs1, rhs2, lhs2, rhs3, lhs3, rhs4, lhs4, dt,t;
  BackendDAE.Variables vars;
  DAE.Type ty;
  BackendDAE.Var var;
algorithm
  ty := DAE.T_REAL_DEFAULT;
  eqns := BackendEquation.emptyEqns();
  vars := BackendVariable.emptyVars();
  ty := DAE.T_REAL_DEFAULT;
  cr := DAE.CREF_IDENT("time", ty, {});
  t0 := ComponentReference.crefPrefixString("$t0", cr);
  t1 := ComponentReference.crefPrefixString("$t1", cr);
  t2 := ComponentReference.crefPrefixString("$t2", cr);
  t3 := ComponentReference.crefPrefixString("$t3", cr);
  t4 := ComponentReference.crefPrefixString("$t4", cr);
  
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
   
  dt := DAE.CREF(DAE.CREF_IDENT("$dt", ty, {}), DAE.T_REAL_DEFAULT);
  
  t := DAE.CREF(cr,ty);
  
  lhs0 := DAE.CREF(t0,ty);
  rhs0 := t;
  eqn := BackendDAE.EQUATION(lhs0, rhs0, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  lhs1 := DAE.CREF(t1,ty);
  rhs1 := eADD(eMUL(DAE.RCONST(0.1726731646460114281008537718766),dt),t);
  eqn := BackendDAE.EQUATION(lhs1, rhs1, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  lhs2 := DAE.CREF(t2,ty);
  rhs2 := eADD(eMUL(DAE.RCONST(0.50),dt),t);
  eqn := BackendDAE.EQUATION(lhs2, rhs2, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  lhs3 := DAE.CREF(t3,ty);
  rhs3 := eADD(eMUL(DAE.RCONST(0.8273268353539885718991462281234),dt),t);
  eqn := BackendDAE.EQUATION(lhs3, rhs3, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  lhs4 := DAE.CREF(t4,ty);
  rhs4 := eADD(dt,t);
  
  eqn := BackendDAE.EQUATION(lhs4, rhs4, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  eqSystem := BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(),{});
  (outEqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(eqSystem, BackendDAE.NORMAL());
end timeEquation;

protected function eliminatedStatesDerivations "function eliminatedStatesDerivations
  author: vruge
  This is a helper function for dae_to_algSystem.
  change function call der(x) in  variable xder
  change kind: state in known variable"
  input BackendDAE.EqSystem inEqSystem;
  input tuple<BackendDAE.EqSystems, BackendDAE.Variables,BackendDAE.Variables> inTupel ;
  output tuple<BackendDAE.EqSystems, BackendDAE.Variables,BackendDAE.Variables> outTupel;
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
  (inSystems, invars, inInlinevars) := inTupel;
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
  ((vars, eqns, outvars, inlinevars)) := BackendVariable.traverseBackendDAEVars(orderedVars, replaceStates_vars, (vars, eqns2, invars,inInlinevars));
  eqSystem := BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets);
  (eqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(eqSystem, BackendDAE.NORMAL());
  outTupel := (listAppend(inSystems,{eqSystem}), BackendVariable.mergeVariables(invars,outvars),inlinevars);
end eliminatedStatesDerivations;

protected function replaceStates_eqs "function replaceStates_eqs
  author: vruge
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
algorithm
  (eqn, (vars, eqns, preState, preDer)) := inTpl;
  // replace der(x) with $DER.x
  (eqn1, (_,_,_,_)) := BackendEquation.traverseBackendDAEExpsEqn(eqn, replaceDerStateCref, (vars, 0, preState, preDer));
  eqns := BackendEquation.equationAdd(eqn1, eqns);
  outTpl := (eqn, (vars, eqns,preState,preDer));
end replaceStates_eqs;

protected function replaceDerStateCref "function replaceDerStateCref
  author: vruge
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

protected function replaceDerStateExp "function replaceDerStateExp
  author: vruge
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

protected function crefPrefixStringWithpopCref "function crefPrefixStringWithpopCref 
  author: vruge"
  input String name;
  input DAE.ComponentRef in_cr;
  output DAE.ComponentRef out_cr;
 algorithm
   out_cr := ComponentReference.popCref(in_cr);
   out_cr := ComponentReference.crefPrefixString(name, out_cr);
end crefPrefixStringWithpopCref;

protected function replaceStates_vars "function replaceStates_vars
  author: vruge"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.Variables, BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.Variables, BackendDAE.Variables>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Variables vars, vars0, inlineVars;
      DAE.ComponentRef cr, x0, x1, x2, x3, x4, derx0, derx1, derx2, derx3, derx4;
      DAE.Type ty;
      DAE.InstDims arryDim;
      BackendDAE.EquationArray eqns;
      //BackendDAE.Equation eqn;
      BackendDAE.EquationArray eqn;
      DAE.Exp dt;
 
    // state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varType=ty, arryDim=arryDim), (vars, eqns,vars0, inlineVars))) equation
      var = BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      vars = BackendVariable.addVar(var, vars);
    
      (x0,var) = stringCrVar("$t0", cr, ty, arryDim); // knownVars
      vars0 = BackendVariable.addVar(var, vars0);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (x1,var) = stringCrVar("$t1",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (x2,var) = stringCrVar("$t2",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (x3,var) = stringCrVar("$t3",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (x4,var) = stringCrVar("$t4",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (derx0,var) = stringCrVar("$t0_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (derx1,var) = stringCrVar("$t1_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (derx2,var) = stringCrVar("$t2_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (derx3,var) = stringCrVar("$t3_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      (derx4,var) = stringCrVar("$t4_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      inlineVars = BackendVariable.addVar(var,inlineVars);
      
      dt = DAE.CREF(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT);
      
      //eqn = eulerStep(x0,x1,derx0,dt,ty);
      eqn = stepLobatt(x0, x1, x2, x3, x4, derx0, derx1, derx2, derx3, derx4,dt,ty);
      eqns = BackendEquation.mergeEquationArray(eqn, eqns);
      eqns = BackendEquation.equationAdd(BackendDAE.EQUATION(DAE.CREF(cr, ty), DAE.CREF(x4, ty), DAE.emptyElementSource, false), eqns);
    then ((var, (vars, eqns,vars0,inlineVars)));
    
    // else
    case((var, (vars, eqns,vars0,inlineVars))) equation
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, eqns,vars0,inlineVars)));
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/InlineSolver.mo: function replaceStates1_vars failed"});
    then fail();
  end matchcontinue;
end replaceStates_vars;

protected function stepLobatt "function stepLobatt
  author: vruge
  implicit Runge Kutta method"
  input DAE.ComponentRef x0, x1, x2, x3, x4, derx0, derx1, derx2, derx3, derx4;
  input DAE.Exp dt;
  input DAE.Type ty;
  output BackendDAE.EquationArray eqns;
protected
  DAE.Exp rhs1, lhs1, rhs2, lhs2, rhs3, lhs3, rhs4, lhs4, e1, e2,e3, e4,e5,ee1,ee2,ee3,ee4,ee5, a0, a1,a2, a3, a4, d0, d1, dt;
  BackendDAE.Equation eqn;
algorithm
  eqns := BackendEquation.emptyEqns();
  
  ee1 := DAE.CREF(derx0, ty);
  ee2 := DAE.CREF(derx1, ty);
  ee3 := DAE.CREF(derx2, ty);
  ee4 := DAE.CREF(derx3, ty);
  ee5 := DAE.CREF(derx4, ty);
  
  e1 := DAE.CREF(x0, ty);
  e2 := DAE.CREF(x1, ty);
  e3 := DAE.CREF(x2, ty);
  e4 := DAE.CREF(x3, ty);
  e5 := DAE.CREF(x4, ty);
  
  dt := DAE.CREF(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT); 
  
  (a0, a1,a2, a3, a4, d0, d1) := coeffsLobattoIIIA1(ty);
  lhs1 := eADD(eMUL(eMUL(ee2,d1),dt),eMUL(e2,a1));
  rhs1 :=  eADD(eADD(eADD(eADD(eMUL(eMUL(dt,d0),ee1),eMUL(e1,a0)),eMUL(e3,a2)),eMUL(e4,a3)),eMUL(e5,a4));
  eqn := BackendDAE.EQUATION(lhs1, rhs1, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  
  (a0, a1,a2, a3, a4, d0, d1) := coeffsLobattoIIIA2(ty);
  lhs1 := eADD(eMUL(eMUL(ee3,d1),dt),eMUL(e3,a2));
  rhs1 :=  eADD(eADD(eADD(eADD(eMUL(eMUL(dt,d0),ee1),eMUL(e1,a0)),eMUL(e2,a1)),eMUL(e4,a3)),eMUL(e5,a4));
  eqn := BackendDAE.EQUATION(lhs1, rhs1, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  (a0, a1,a2, a3, a4, d0, d1) := coeffsLobattoIIIA3(ty);
  lhs1 := eADD(eMUL(eMUL(ee4,d1),dt),eMUL(e4,a3));
  rhs1 :=  eADD(eADD(eADD(eADD(eMUL(eMUL(dt,d0),ee1),eMUL(e1,a0)),eMUL(e2,a1)),eMUL(e3,a2)),eMUL(e5,a4));
  eqn := BackendDAE.EQUATION(lhs1, rhs1, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
  
  (a0, a1,a2, a3, a4, d0, d1) := coeffsLobattoIIIA4(ty);
  lhs1 := eADD(eMUL(eMUL(ee5,d1),dt),eMUL(e5,a4));
  rhs1 :=  eADD(eADD(eADD(eADD(eMUL(eMUL(dt,d0),ee1),eMUL(e1,a0)),eMUL(e2,a1)),eMUL(e3,a2)),eMUL(e4,a3));
  eqn := BackendDAE.EQUATION(lhs1, rhs1, DAE.emptyElementSource, false);
  eqns := BackendEquation.equationAdd(eqn, eqns);
end stepLobatt;

protected function stringCrVar "function stringCrVar
  author: vruge"
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


protected function eADD "function eADD
  author vruge"
  input DAE.Exp a;
  input DAE.Exp b;
  output DAE.Exp c;
algorithm
  c := DAE.BINARY(a,DAE.ADD(DAE.T_REAL_DEFAULT),b);
end eADD;

protected function eMUL "function eMUL
  author vruge"
  input DAE.Exp a;
  input DAE.Exp b;
  output DAE.Exp c;
algorithm
  c := DAE.BINARY(a,DAE.MUL(DAE.T_REAL_DEFAULT),b);
end eMUL;

protected function coeffsLobattoIIIA1 "function coeffsLobattoIIIA1
  author vruge"
  input DAE.Type ty;
  output DAE.Exp a0, a1,a2, a3, a4;
  output DAE.Exp d0, d1; 
algorithm
  d0 := DAE.RCONST(-0.4285714285714285714285714285714);
  d1 := DAE.RCONST(1.0);
  a0 := DAE.RCONST(-6.767694791776251429983152970084);
  a1 := DAE.RCONST(-5.791287847477920003294023596864);
  a2 := DAE.RCONST(1.205771958061592385971845480936);
  a3 := DAE.RCONST(-0.318813079129866672156705994773);
  a4 := DAE.RCONST(0.0894480653666057128739898870588);  
end coeffsLobattoIIIA1;

protected function coeffsLobattoIIIA2 "function coeffsLobattoIIIA2
  author vruge"
  input DAE.Type ty;
  output DAE.Exp a0, a1,a2, a3, a4;
  output DAE.Exp d0, d2;
algorithm
  d0 := DAE.RCONST(0.3750000000000000000000000000000);
  d2 := DAE.RCONST(1.0);

  a0 := DAE.RCONST(4.50);
  a1 := DAE.RCONST(-7.740546021934086673391964843596);
  a2 := DAE.RCONST(-2.0);
  a3 := DAE.RCONST(1.615546021934086673391964843596);
  a4 := DAE.RCONST(-0.3750);
end coeffsLobattoIIIA2;

protected function coeffsLobattoIIIA3 "function coeffsLobattoIIIA3
  author vruge"
  input DAE.Type ty;
  output DAE.Exp a0, a1,a2, a3, a4;
  output DAE.Exp d0, d3;
algorithm
  d0 := DAE.RCONST(-0.4285714285714285714285714285714);
  d3 := DAE.RCONST(1.0);
  
  a0 := DAE.RCONST(-4.803733779652319998588275601344);
  a1 := DAE.RCONST(7.318813079129866672156705994773);
  a2 := DAE.RCONST(-5.777200529490163814543274052364);
  a3 := DAE.RCONST(-1.208712152522079996705976403136);
  a4 := DAE.RCONST(2.053409077490537144268867255799);
end coeffsLobattoIIIA3;

protected function coeffsLobattoIIIA4 "function coeffsLobattoIIIA4
  author vruge"
  input DAE.Type ty;
  output DAE.Exp a0, a1,a2, a3, a4;
  output DAE.Exp d0, d4;
algorithm
  d0 := DAE.RCONST(1.0);
  d4 := DAE.RCONST(1.0);

  a0 := DAE.RCONST(11.0);
  a1 := DAE.RCONST(-16.33333333333333333333333333333);
  a2 := DAE.RCONST(10.66666666666666666666666666667);
  a3 := a1;
  a4 := DAE.RCONST(-11.0);
end coeffsLobattoIIIA4;

end InlineSolver;
