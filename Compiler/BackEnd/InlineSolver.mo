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
      
    case _ equation
      false = Flags.isSet(Flags.INLINE_SOLVER);
    then NONE();
    
    case dae equation
      true = Flags.isSet(Flags.INLINE_SOLVER);
      
      Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver (1)");
      
      dae = replaceStates(dae);
      
      Debug.fcall2(Flags.DUMP_INLINE_SOLVER, BackendDump.dumpBackendDAE, dae, "inlineSolver (2)");
    then NONE();
    
    else equation
      Error.addCompilerWarning("./Compiler/BackEnd/InlineSolver.mo: function generateDAE failed");
      Error.addCompilerWarning("inline solver can not be used.");
    then NONE();
  end matchcontinue;
end generateDAE;

protected function replaceStates "function replaceStates
  author: lochel, vruge
  This is a helper function for generateDAE."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  
  list<tuple<BackendDAEUtil.pastoptimiseDAEModule, String, Boolean>> pastOptModules;
  tuple<BackendDAEUtil.StructurallySingularSystemHandlerFunc, String, BackendDAEUtil.stateDeselectionFunc, String> daeHandler;
  tuple<BackendDAEUtil.matchingAlgorithmFunc, String> matchingAlgorithm;
  Integer nVars, nEqns;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.BackendDAE dae;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  
  systs := List.map(systs, replaceStates1);
  dae := BackendDAE.DAE(systs, shared);
  
  pastOptModules := BackendDAEUtil.getPastOptModules(SOME({"constantLinearSystem", "removeSimpleEquations", "tearingSystem"}));
  matchingAlgorithm := BackendDAEUtil.getMatchingAlgorithm(NONE());
  daeHandler := BackendDAEUtil.getIndexReductionMethod(NONE());

  // solve system
  dae := BackendDAEUtil.transformBackendDAE(dae, SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())), NONE(), NONE());

  // simplify system
  (outDAE, Util.SUCCESS()) := BackendDAEUtil.pastoptimiseDAE(dae, pastOptModules, matchingAlgorithm, daeHandler);
end replaceStates;

protected function replaceStates1 "function replaceStates1
  author: lochel, vruge
  This is a helper function for replaceStates."
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
  
  ((_, eqns)) := BackendEquation.traverseBackendDAEEqns(orderedEqs, replaceStates1_eqs, (orderedVars, eqns));  
  ((vars, eqns)) := BackendVariable.traverseBackendDAEVars(orderedVars, replaceStates1_vars, (vars, eqns));
  
  eqSystem := BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING());
  (outEqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(eqSystem, BackendDAE.NORMAL());
end replaceStates1;

protected function replaceStates1_eqs "function replaceStates1_eqs
  author: lochel, vruge"
  input tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> outTpl;
protected
  BackendDAE.Equation eqn, eqn1;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
algorithm
  (eqn, (vars, eqns)) := inTpl;
  
  // replace der(x) with $DER.x and replace pre(x) with $PRE.x
  (eqn1, _) := BackendEquation.traverseBackendDAEExpsEqn(eqn, replaceDerStateCref, (vars, 0));
  eqns := BackendEquation.equationAdd(eqn1, eqns);
  
  outTpl := (eqn, (vars, eqns));
end replaceStates1_eqs;

protected function replaceDerStateCref "function replaceDerStateCref
  author: lochel, vruge"
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
  author: lochel, vruge"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer>> inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables, Integer>> outExp;
algorithm
  (outExp) := matchcontinue(inExp)
    local
      DAE.ComponentRef dummyder, cr, vitCR;
      DAE.Type ty;
      Integer i;
      BackendDAE.Variables vars;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = cr)}, attr=DAE.CALL_ATTR(ty=ty)), (vars, i))) equation
      cr = ComponentReference.popCref(cr);
      dummyder = ComponentReference.crefPrefixString("$vit_0_der", cr);
    then ((DAE.CREF(dummyder, ty), (vars, i+1)));
    
    case ((DAE.CREF(componentRef = cr, ty=ty), (vars, i))) equation
      true = BackendVariable.isState(cr, vars);
      vitCR = ComponentReference.crefPrefixString("$vit_0", cr);
    then ((DAE.CREF(vitCR, ty), (vars, i+1)));
      
    else
    then inExp;
  end matchcontinue;
end replaceDerStateExp;

protected function replaceStates1_vars "function replaceStates1_vars
  author: lochel, vruge"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendDAE.EquationArray>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      BackendDAE.Var var, preVar;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr, vit_0CR, vit_1CR, vit_0_derCR;
      DAE.Type ty;
      DAE.InstDims arryDim;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      DAE.Exp vit_1Exp, rhs, exp, vit_0_derExp;
    
    // state
    case((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(), varType=ty, arryDim=arryDim), (vars, eqns))) equation
      vit_0CR = ComponentReference.crefPrefixString("$vit_0", cr);
      var = BackendDAE.VAR(vit_0CR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      //vars = BackendVariable.addVar(var, vars);
      
      vit_1CR = ComponentReference.crefPrefixString("$vit_1", cr);
      var = BackendDAE.VAR(vit_1CR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      vars = BackendVariable.addVar(var, vars);
      
      vit_0_derCR = ComponentReference.crefPrefixString("$vit_0_der", cr);
      var = BackendDAE.VAR(vit_0_derCR, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), ty, NONE(), NONE(), arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
      vars = BackendVariable.addVar(var, vars);
      
      // generate vit_1_x = vit_0_x + dt * vit_0_der_x
      vit_1Exp = DAE.CREF(vit_1CR, ty);
      vit_0_derExp = DAE.CREF(vit_0_derCR, ty);
      rhs = DAE.CREF(vit_0CR, ty);
      
      exp = DAE.CREF(DAE.CREF_IDENT("$dt", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT);
      exp = DAE.BINARY(exp, DAE.MUL(DAE.T_REAL_DEFAULT), vit_0_derExp);
      rhs = DAE.BINARY(rhs, DAE.ADD(DAE.T_REAL_DEFAULT), exp);
      
      eqn = BackendDAE.EQUATION(vit_1Exp, rhs, DAE.emptyElementSource, false);
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
end replaceStates1_vars;

end InlineSolver;
