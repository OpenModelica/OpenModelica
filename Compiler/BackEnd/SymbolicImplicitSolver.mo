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


encapsulated package SymbolicImplicitSolver
" file:        SymbolicImplicitSolver.mo
  package:     SymbolicImplicitSolver
  description: SymbolicImplicitSolver: der(x) is replaced with difference quotient so more symbolic
  optimization is possible. After removeSimpleEquation, before tearing.

  Original system is not changed, new system is stored in shared.InlineSystems.

  Flag --symSolver is needed

  "


public import BackendDAE;

protected
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import ComponentReference;
import Expression;
import ExpressionDump;
import Flags;
import List;


public function symSolver
  input BackendDAE.BackendDAE inDAE;
  output Option<BackendDAE.InlineData> inlineData;
algorithm

  //print("*********************inDAE*********************");
  //List.map_0(inDAE.eqs, BackendDump.printEqSystem);
  //BackendDump.printBackendDAE(inDAE);

  // generate inline solver
  if Flags.getConfigEnum(Flags.SYM_SOLVER)>0 then
    inlineData := SOME(symSolverWork(inDAE));
  else
    inlineData := NONE();
  end if;

  //print("*********************outDAE*********************");
  //List.map_0(outDAE.eqs, BackendDump.printEqSystem);
  //BackendDump.printBackendDAE(outDAE);
end symSolver;

protected function symSolverWork
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.InlineData inlineData;
protected
  list<BackendDAE.EqSystem> osystlst = {};
  BackendDAE.EqSystem syst_;
  BackendDAE.Shared shared;
  BackendDAE.Var tmpv;
  DAE.ComponentRef cref;
  BackendDAE.Shared sharedIn;
  BackendDAE.EqSystems localInline;
  BackendDAE.Variables knownVariables, saveKnGlobalVars;
  BackendDAE.BackendDAE inlineBDAE;
  Boolean execbool;
algorithm

  // create InlineSolverData
  // copy EqSystem in shared.inlineSystems, so original system is not changed
  localInline :=  BackendDAEUtil.copyEqSystems(inDAE.eqs);
  // create empty known inline variables
  knownVariables := BackendVariable.emptyVars(BackendDAEUtil.daeSize(inDAE));

  inlineData := BackendDAE.INLINE_DATA(localInline, knownVariables);

  // make dt
  cref := ComponentReference.makeCrefIdent(BackendDAE.symSolverDT, DAE.T_REAL_DEFAULT, {});
  tmpv := BackendVariable.makeVar(cref);
  //tmpv := BackendVariable.setVarKind(tmpv, BackendDAE.PARAM());
  tmpv := BackendVariable.setBindExp(tmpv, SOME(DAE.RCONST(0.0)));
  inlineData.knownVariables := BackendVariable.addVars({tmpv}, inlineData.knownVariables);

  // call symSolverUpdateSyst for every equation system in localInline
  knownVariables := inlineData.knownVariables;
  for syst in inlineData.inlineSystems  loop
   (syst_, knownVariables)  := symSolverUpdateSyst(syst, knownVariables);
   // add every result equation system to osystlst (list of equation systems)
   osystlst := syst_ :: osystlst;
  end for;
  inlineData.knownVariables := knownVariables;

  shared := inDAE.shared;

  // push known variables from shared to local known variables to provide full shared object
  saveKnGlobalVars := shared.globalKnownVars;
  knownVariables := BackendVariable.addVariables(shared.globalKnownVars, knownVariables);
  shared.globalKnownVars := knownVariables;

  //set backenddae type inline in shared
  shared.backendDAEType := BackendDAE.INLINESYSTEM();

  inlineBDAE := BackendDAE.DAE(osystlst, shared);

  execbool := Flags.disableDebug(Flags.EXEC_STAT);
  if Flags.isSet(Flags.DUMP_INLINE_SOLVER) then
    BackendDump.bltdump("Generated inline system:",inlineBDAE);
  end if;

  inlineBDAE := BackendDAEUtil.getSolvedSystemforJacobians(inlineBDAE,
                                                           {"removeEqualFunctionCalls",
                                                            "removeSimpleEquations",
                                                            "evalFunc"},
                                                           NONE(),
                                                           NONE(),
                                                           {
                                                            //"wrapFunctionCalls",
                                                            "inlineArrayEqn",
                                                            "constantLinearSystem",
                                                            "solveSimpleEquations",
                                                            "tearingSystem",
                                                            "calculateStrongComponentJacobians",
                                                            "removeConstants",
                                                            "simplifyTimeIndepFuncCalls"});
  _ := Flags.set(Flags.EXEC_STAT, execbool);
  if Flags.isSet(Flags.DUMP_INLINE_SOLVER) then
    BackendDump.bltdump("Final inline systems:", inlineBDAE);
  end if;

  if (Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) or Flags.isSet(Flags.DUMP_STATESELECTION_INFO) or Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO)) then
    BackendDump.dumpCompShort(inlineBDAE);
  end if;

  BackendDAE.DAE(localInline, _) := inlineBDAE;
  inlineData.inlineSystems := localInline;
  shared.globalKnownVars := saveKnGlobalVars;

end symSolverWork;

protected function symSolverUpdateSyst
  input BackendDAE.EqSystem iSyst;
  input BackendDAE.Variables inKnVars;
  output BackendDAE.EqSystem oSyst;
  output BackendDAE.Variables oKnVars = inKnVars;
protected
  array<Option<BackendDAE.Equation>> equOptArr;
  BackendDAE.Equation eqn;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  list<DAE.ComponentRef> crlst;
algorithm
  oSyst := match iSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)
      algorithm
        crlst := {};
        // for every equation in the input equation system
        for i in 1:ExpandableArray.getLastUsedIndex(eqns) loop
          if ExpandableArray.occupied(i, eqns) then
            eqn := ExpandableArray.get(i, eqns);
            // traverse all expression of the equation and replace der(x)
            (eqn, (crlst, _)) := BackendEquation.traverseExpsOfEquation(eqn, symSolverUpdateEqn, (crlst, syst.orderedVars));
            ExpandableArray.update(i, eqn, eqns);
          end if;
        end for;
        // change state variables to algebraic variables since der(x) is replaced by the difference quotient
        (vars, oKnVars) := symSolverState(vars, inKnVars, crlst);
        syst.orderedVars := vars;
        syst.orderedEqs := eqns;
      then BackendDAEUtil.clearEqSyst(syst);
  end match;
end symSolverUpdateSyst;

// function changes every state variable to algebraic variable
protected function symSolverState
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input list<DAE.ComponentRef> crlst;
  output BackendDAE.Variables ovars = vars;
  output BackendDAE.Variables oknvars = knvars;

protected
  Integer idx;
  DAE.ComponentRef oldCref;
  BackendDAE.Var var;
algorithm
  for cref in crlst loop
    // change former kind of from STATE to ALG_STATE
    (var, idx) := BackendVariable.getVar2(cref, ovars);
    ovars :=  BackendVariable.setVarKindForVar(idx, BackendDAE.ALG_STATE(), ovars);
    // create an old variable as known input
    oldCref := ComponentReference.appendStringLastIdent("$Old", cref);
    var := BackendVariable.copyVarNewName(oldCref, var);
    var := BackendVariable.setVarKind(var, BackendDAE.ALG_STATE_OLD());
    oknvars := BackendVariable.addVars({var}, oknvars);
  end for;
end symSolverState;

protected function symSolverUpdateEqn
  input DAE.Exp inExp;
  input tuple<list<DAE.ComponentRef>, BackendDAE.Variables> inTl;
  output DAE.Exp outExp;
  output tuple<list<DAE.ComponentRef>, BackendDAE.Variables> outTpl;
protected
  BackendDAE.Variables orderedVars;
  list<DAE.ComponentRef> inTpl;
algorithm
  (inTpl, orderedVars) := inTl;

  if (Flags.getConfigEnum(Flags.SYM_SOLVER) > 1) then
    // explicit euler
    (outExp, (inTpl, orderedVars)) := Expression.traverseExpTopDown(inExp, symSolverUpdateStates, (inTpl, orderedVars));
  else
    // implicit euler
    (outExp, inTpl) := Expression.traverseExpTopDown(inExp, symSolverUpdateDer, inTpl);
  end if;

  outTpl := (inTpl, orderedVars);
end symSolverUpdateEqn;


protected function symSolverUpdateStates
  input DAE.Exp inExp;
  input tuple<list<DAE.ComponentRef>, BackendDAE.Variables> inTl;
  output DAE.Exp outExp;
  output Boolean cont=true;
  output tuple<list<DAE.ComponentRef>, BackendDAE.Variables> outTl;
protected
  list<DAE.ComponentRef> inTpl;
  BackendDAE.Variables orderedVars;
algorithm
  (inTpl, orderedVars) := inTl;
  (outExp, outTl) := match (inTpl, inExp)
    local
      DAE.Exp e, e1, e2, e3;
      DAE.Type tp;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;

    case (cr_lst, DAE.CALL(path=Absyn.IDENT(name="der"), expLst={e1 as DAE.CREF(ty=tp, componentRef = cr)}))
      equation
        e2 = Expression.crefExp(ComponentReference.appendStringLastIdent("$Old", cr));
        e3 = Expression.crefExp(ComponentReference.makeCrefIdent(BackendDAE.symSolverDT, DAE.T_REAL_DEFAULT, {}));
        cont = false;
    then (DAE.BINARY(DAE.BINARY(e1, DAE.SUB(tp), e2), DAE.DIV(tp), e3), (List.unionElt(cr,cr_lst), orderedVars));

    case (cr_lst, DAE.CREF(ty=tp, componentRef=cr))
      equation
        (e, cr_lst) = symSolverAppendStringToStates(cr, cr_lst, orderedVars);
    then (e, (cr_lst, orderedVars));

    else (inExp, inTl);
  end match;
end symSolverUpdateStates;

protected function symSolverAppendStringToStates
  input DAE.ComponentRef inCr;
  input list<DAE.ComponentRef> incr_lst;
  input BackendDAE.Variables orderedVars;
  output DAE.Exp outExp = Expression.crefExp(inCr);
  output list<DAE.ComponentRef> outcr_lst = incr_lst;
algorithm
  if (BackendVariable.isState(inCr, orderedVars)) then
    outExp := Expression.crefExp(ComponentReference.appendStringLastIdent("$Old", inCr));
    outcr_lst := List.unionElt(inCr, incr_lst);
  end if;
end symSolverAppendStringToStates;

// function changes call "der" to difference quotient
protected function symSolverUpdateDer
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inTpl;
  output DAE.Exp outExp;
  output Boolean cont=true;
  output list<DAE.ComponentRef> outTpl;
algorithm
  (outExp, outTpl) := match (inTpl, inExp)
    local
      DAE.Exp e1, e2, e3;
      DAE.Type tp;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;

    case (cr_lst, DAE.CALL(path=Absyn.IDENT(name="der"), expLst={e1 as DAE.CREF(ty=tp, componentRef = cr)}))
      equation
        e2 = Expression.crefExp(ComponentReference.appendStringLastIdent("$Old", cr));
        e3 = Expression.crefExp(ComponentReference.makeCrefIdent(BackendDAE.symSolverDT, DAE.T_REAL_DEFAULT, {}));
    then (DAE.BINARY(DAE.BINARY(e1, DAE.SUB(tp), e2), DAE.DIV(tp), e3), List.unionElt(cr,cr_lst));

    else (inExp, inTpl);
  end match;
end symSolverUpdateDer;


annotation(__OpenModelica_Interface="backend");
end SymbolicImplicitSolver;
