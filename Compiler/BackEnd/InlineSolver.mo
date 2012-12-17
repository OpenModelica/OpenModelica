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

  RCS: $Id: InlineSolver.mo 14238 2012-12-05 14:00:00Z lochel $"

public import Absyn;
public import BackendDAE;
public import DAE;

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
algorithm
  outDAE := matchcontinue(inDAE)
    local
      BackendDAE.BackendDAE dae;
      
    case _ equation /*do nothing */
      false = Flags.isSet(Flags.INLINE_SOLVER);
    then NONE();
    
    case dae equation
      true = Flags.isSet(Flags.INLINE_SOLVER);

      Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver: raw system");

      /*dae -> algebraic system*/      
      dae = dae_to_algSystem(dae);
      
      /*output: algebraic system */
      Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver: algebraic system");
    then NONE();
    
    else equation /* don't work */
      Error.addCompilerWarning("./Compiler/BackEnd/InlineSolver.mo: function generateDAE failed");
      Error.addCompilerWarning("inline solver can not be used.");
    then NONE();
  end matchcontinue;
end generateDAE;


protected function dae_to_algSystem "function dae_to_algSystem
  author: lochel, vruge
  This is a helper function for generateDAE.
  Transformation dae in algebraic system
  "
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  
  /*need for new matching */
  list<tuple<BackendDAEUtil.pastoptimiseDAEModule, String, Boolean>> pastOptModules;
  tuple<BackendDAEUtil.StructurallySingularSystemHandlerFunc, String, BackendDAEUtil.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEUtil.matchingAlgorithmFunc, String> matchingAlgorithm;
  BackendDAE.BackendDAE dae;
  
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  systs := List.map(systs, eliminiertStatesDerivations);
  dae := BackendDAE.DAE(systs, shared);
  
  // matching options
  pastOptModules := BackendDAEUtil.getPastOptModules(SOME({"constantLinearSystem", "removeSimpleEquations", "tearingSystem"}));
  matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
  daeHandler := BackendDAEUtil.getIndexReductionMethod(NONE());
  
  // solve system
  dae := BackendDAEUtil.transformBackendDAE(dae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());
  // simplify system
  (outDAE, Util.SUCCESS()) := BackendDAEUtil.pastoptimiseDAE(dae, pastOptModules, matchingAlgorithm, daeHandler);
end dae_to_algSystem;


protected function eliminiertStatesDerivations "function eliminiertStatesDerivations
  author: lochel, vruge
  This is a helper function for dae_to_algSystem.
  change function call der(x) in  variable xder
  change kind: state in known variable "
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
protected  
  BackendDAE.Variables orderedVars;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.EquationArray eqns;
  BackendDAE.EqSystem eqSystem;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs) := inEqSystem;
  vars := BackendVariable.emptyVars();
  eqns := BackendEquation.emptyEqns();
  // change function call der(x) in  variable xder
  ((_, eqns)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates_eqs, (orderedVars, eqns));  
  // change kind: state in known variable 
  ((vars, eqns)) := BackendVariable.traverseBackendDAEVars(orderedVars, replaceStates_vars, (vars, eqns));
  eqSystem := BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING());
  (outEqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(eqSystem, BackendDAE.NORMAL());
end eliminiertStatesDerivations;


protected function replaceStates_eqs "function replaceStates_eqs
  author: lochel, vruge
  This is a helper function for eliminiertStatesDerivations.
  replace der(x) with $DER.x."
  input tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> outTpl;
protected
  BackendDAE.Equation eqn, eqn1;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
algorithm
  (eqn, (vars, eqns)) := inTpl;
  // replace der(x) with $DER.x
  (eqn1, _) := BackendEquation.traverseBackendDAEExpsEqn(eqn, replaceDerStateCref, (vars, 0));
  eqns := BackendEquation.equationAdd(eqn1, eqns);
  outTpl := (eqn, (vars, eqns));
end replaceStates_eqs;


/*replaceDerStateCref*/
protected function replaceDerStateCref "function replaceDerStateCref
  author: lochel, vruge
  This is a helper function for dae_to_algSystem."
  input tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer>> inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer>> outExp;
protected
   DAE.Exp e;
   Integer i;
   BackendDAE.Variables vars;
algorithm
  (e, (vars, i)) := inExp;
  outExp := Expression.traverseExp(e, replaceDerStateExp, (vars, i));
end replaceDerStateCref;

protected function replaceDerStateExp "function replaceDerStateExp
  author: lochel, vruge
  This is a helper function for replaceDerStateCref."
  input tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer>> inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer>> outExp;
algorithm
  (outExp) := matchcontinue(inExp)
    local
      DAE.ComponentRef cr;
      DAE.Type ty;
      Integer i;
      BackendDAE.Variables vars;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), (vars, i))) equation
      cr = ComponentReference.popCref(cr);
      cr = ComponentReference.crefPrefixString("$t0_der", cr); //der(x) for timepoint t0
    then ((DAE.CREF(cr, ty), (vars, i+1)));
    
    case ((DAE.CREF(componentRef = cr, ty=ty), (vars, i))) equation
      true = BackendVariable.isState(cr, vars);
      cr = ComponentReference.crefPrefixString("$t0", cr); //x for timepoint t0
    then ((DAE.CREF(cr, ty), (vars, i+1)));
      
    else
    then inExp;
  end matchcontinue;
end replaceDerStateExp;

protected function replaceStates_vars "function replaceStates1_vars
  author: lochel, vruge"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, x0, x1, derx0;
      DAE.Type ty;
      DAE.InstDims arryDim;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      DAE.Exp dt;
    
    // state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varType=ty, arryDim=arryDim), (vars, eqns))) equation
      (x0,_) = make_var("$t0",cr,ty,arryDim);
      
      (x1,var) = make_var("$t1",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      
      (derx0,var) = make_var("$t0_der",cr,ty,arryDim);
      vars = BackendVariable.addVar(var, vars);
      
      dt = DAE.CREF(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT); 
      // explicit: x_{i+1} = x_{i} + dt * der(x_{i})  
      // implicit: x_{i+1} = x_{i} + dt * der(x_{i+1})
      eqn = eulerStep(x0,x1,derx0,dt,ty);
      eqns = BackendEquation.equationAdd(eqn, eqns);
      
    then ((var, (vars, eqns)));
    
    // else
    case((var, (vars, eqns))) equation
      vars = BackendVariable.addVar(var, vars);
    then ((var, (vars, eqns)));
    
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/InlineSolver.mo: function replaceStates1_vars failed"});
    then fail();
  end matchcontinue;
end replaceStates_vars;


protected function make_var
  input String varTyp;
  input DAE.ComponentRef inCR;
  input DAE.Type ty;
  input DAE.InstDims arryDim;
  output DAE.ComponentRef outCR;
  output BackendDAE.Var var;
  
algorithm
  outCR := ComponentReference.crefPrefixString(varTyp, inCR);
  var := BackendDAE.VAR(outCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
end make_var;

protected function eulerStep
  input DAE.ComponentRef x0, x1, derx;
  input DAE.Exp dt;
  input DAE.Type ty;
  output BackendDAE.Equation eqn;
protected
  DAE.Exp rhs, lhs, e1, e2;
algorithm
  lhs := DAE.CREF(x1, ty);
  e1 := DAE.CREF(derx, ty);
  e2 := DAE.CREF(x0, ty);
  
  rhs := DAE.BINARY(dt, DAE.MUL(ty), e1);
  rhs := DAE.BINARY(rhs, DAE.ADD(ty), e2);
  
  eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, false);
end eulerStep;

end InlineSolver;