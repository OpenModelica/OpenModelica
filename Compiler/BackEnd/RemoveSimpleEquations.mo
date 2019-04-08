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

encapsulated package RemoveSimpleEquations "
  file:        RemoveSimpleEquations.mo
  package:     RemoveSimpleEquations
  description: RemoveSimpleEquations contains functions to remove simple equations.
               Simple equations are either alias equations or time independent equations.
               Alias equations can be simplified to 'a = b', 'a = -b' or 'a = not b'.
               The package contains three main functions.
               fastAcausal: to remove with a linear scaling with respect to the
                            number of equations in an acausal system as much as
                            possible simple equations.
               allAcausal:  to remove all simple equations in an acausal system
                            the function may needs a lots of time.
               causal:      to remove with a linear scaling with respect to the
                            number of equations in an causal system all
                            simple equations"

public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;

protected
import AvlSetInt;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import BackendVarTransform;
import BaseHashSet;
import BaseHashTable;
import Ceval;
import ComponentReference;
import Debug;
import ElementSource;
import Error;
import EvaluateFunctions;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import ExpressionSolve;
import Flags;
import GC;
import HashSet;
import HashTableCrToCrEqLst;
import HashTableCrToExp;
import HashTableExpToIndex;
import List;
import SimCodeUtil;
import Types;
import Util;



protected type EquationSourceAndAttributes = tuple<DAE.ElementSource, BackendDAE.EquationAttributes> "eqnAttributes(source,EquationAttributes)";

protected
uniontype SimpleContainer
  record ALIAS
    DAE.ComponentRef cr1;
    Boolean negatedCr1;
    Integer i1;
    DAE.ComponentRef cr2;
    Boolean negatedCr2;
    Integer i2;
    EquationSourceAndAttributes eqnAttributes;
    Integer visited;
  end ALIAS;

  record PARAMETERALIAS
    DAE.ComponentRef unknowncr;
    Boolean negatedCr1;
    Integer i1;
    DAE.ComponentRef paramcr;
    Boolean negatedCr2;
    Integer i2;
    EquationSourceAndAttributes eqnAttributes;
    Integer visited;
  end PARAMETERALIAS;

  record TIMEALIAS
    DAE.ComponentRef cr1;
    Boolean negatedCr1;
    Integer i1;
    DAE.ComponentRef cr2;
    Boolean negatedCr2;
    Integer i2;
    EquationSourceAndAttributes eqnAttributes;
    Integer visited;
  end TIMEALIAS;

  record TIMEINDEPENTVAR
    DAE.ComponentRef cr;
    Integer i;
    DAE.Exp exp;
    EquationSourceAndAttributes eqnAttributes;
    Integer visited;
  end TIMEINDEPENTVAR;
end SimpleContainer;

protected type AccTuple = tuple<BackendDAE.Variables, BackendDAE.Shared, list<BackendDAE.Equation>, list<SimpleContainer>, Integer, array<list<Integer>>, Boolean>;

protected type VarSetAttributes =
  tuple<
    Boolean,
    tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>>,
    list<tuple<DAE.Exp, DAE.ComponentRef>>,
    tuple<Option<DAE.Exp>,
          Option<DAE.Exp>>
  > "fixed, list<startvalue, origin, cr>, nominal, (min, max)";

protected constant VarSetAttributes EMPTYVARSETATTRIBUTES = (false, (-1, {}), {}, (NONE(), NONE()));

// =============================================================================
// Starting point for preOpt and postOpt removeSimpleEquations module
//
// =============================================================================

public function removeSimpleEquations "
  This is the main function of 'remove simple equations' for both acausal and
  causal systems."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if BackendDAEUtil.hasDAEMatching(inDAE) then
    // This case performs "remove simple equations" on a causal system.
    // Note: It is fine to do some substitutions in order to minimize SCCs, but
    // alias/known variable vectors may not be touched.
    outDAE := match(Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS))
      case "default" then causal(inDAE);
      case "causal" then causal(inDAE);
      case "new" then performAliasEliminationBB(inDAE, findAliases=true);
      else inDAE;
    end match;

    outDAE := fixAliasVars(outDAE) "workaround for #3323";
    outDAE := fixAliasAndKnownVarsCausal(inDAE, outDAE);
  else
    // This case performs "remove simple equations" on an acausal system.
    outDAE := match(Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS))
      case "default" then fastAcausal(inDAE);
      case "fastAcausal" then fastAcausal(inDAE);
      case "allAcausal" then allAcausal(inDAE);
      case "new" then performAliasEliminationBB(inDAE, true);
      else inDAE;
    end match;

    outDAE := fixAliasVars(outDAE) "workaround for #3323";
    outDAE := fixKnownVars(outDAE);
  end if;
end removeSimpleEquations;

public function removeVerySimpleEquations "This is a very simple removeSimpleEquations, finding a few variables and removing them to speed up the rest of the backend"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  if BackendDAEUtil.hasDAEMatching(inDAE) then
    Error.addInternalError("Cannot run removeVerySimpleEquations on a matched system (continuing anyway)", sourceInfo());
    outDAE := inDAE;
  else
    outDAE := performAliasEliminationBB(inDAE, findAliases=true);
  end if;
end removeVerySimpleEquations;

protected function fixAliasVars "author: lochel
  This is a workaround for #3323
  TODO: Remove this once removeSimpleEquations is implemented properly.

  This module traverses all alias variables and double-checks if they are alias or known variables."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.Variables aliasVars;
  list<BackendDAE.Var> aliasVarList = {};
  list<BackendDAE.Var> knownVarList;
  DAE.Exp binding;
algorithm
  aliasVars := BackendDAEUtil.getAliasVars(inDAE);
  knownVarList := BackendVariable.varList(BackendDAEUtil.getGlobalKnownVarsFromDAE(inDAE));

  for var in BackendVariable.varList(aliasVars) loop
    binding := BackendVariable.varBindExp(var);
    if Expression.isConst(binding) then
      knownVarList := var::knownVarList;
    else
      aliasVarList := var::aliasVarList;
    end if;
  end for;

  outDAE := BackendDAEUtil.setAliasVars(inDAE, BackendVariable.listVar(aliasVarList));
  outDAE := BackendDAEUtil.setDAEGlobalKnownVars(outDAE, BackendVariable.listVar(knownVarList));
end fixAliasVars;

protected function fixKnownVars "author: lochel
  This is a workaround.
  TODO: Remove this once removeSimpleEquations is implemented properly.

  This module traverses all known variables and double-checks if they are known or not."
  input output BackendDAE.BackendDAE dae;
protected
  BackendDAE.EqSystem eqs;
  BackendDAE.Variables globalKnownVars;
  DAE.Exp binding;
  list<BackendDAE.Equation> eqnList = {};
  list<BackendDAE.Var> varList = {};
  list<BackendDAE.Var> knownVarList = {};
  list<DAE.ComponentRef> crlst;
algorithm
  globalKnownVars := dae.shared.globalKnownVars;

  for var in BackendVariable.varList(globalKnownVars) loop
    if BackendVariable.varHasBindExp(var) then
      binding := BackendVariable.varBindExp(var);
      (_, crlst) := Expression.traverseExpTopDown(binding, Expression.traversingComponentRefFinderNoPreDer, {});
      if BackendDAEUtil.containAnyVar(crlst, dae.shared.localKnownVars) then
        varList := BackendVariable.setBindExp(var, NONE())::varList;
        eqnList := BackendDAE.EQUATION(BackendVariable.varExp(var), binding, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING)::eqnList;
      else
        knownVarList := var::knownVarList;
      end if;
    else
      knownVarList := var::knownVarList;
    end if;
  end for;

  if not listEmpty(varList) then
    eqs := BackendDAEUtil.createEqSystem(BackendVariable.listVar(varList), BackendEquation.listEquation(eqnList), {}, BackendDAE.UNSPECIFIED_PARTITION());
    dae.eqs := eqs::dae.eqs;
  end if;

  dae := BackendDAEUtil.setDAEGlobalKnownVars(dae, BackendVariable.listVar(knownVarList));
end fixKnownVars;

protected function fixAliasAndKnownVarsCausal "author: lochel
  TODO: Remove this once removeSimpleEquations is implemented properly.

  This module moves back all newly introduced alias variables to the correct partition."
  input BackendDAE.BackendDAE inDAE1 "original dae";
  input BackendDAE.BackendDAE inDAE2 "transformed dae";
  output BackendDAE.BackendDAE outDAE = inDAE2;
protected
  BackendDAE.Variables aliasVars1, knownVars1;
  BackendDAE.Variables aliasVars2, knownVars2;
  list<BackendDAE.Var> aliasVarList = {};
  list<BackendDAE.Var> knownVarList = {};
  DAE.ComponentRef cref;
algorithm
  aliasVars1 := BackendDAEUtil.getAliasVars(inDAE1);
  aliasVars2 := BackendDAEUtil.getAliasVars(inDAE2);

  knownVars1 := BackendDAEUtil.getGlobalKnownVarsFromDAE(inDAE1);
  knownVars2 := BackendDAEUtil.getGlobalKnownVarsFromDAE(inDAE2);

  for var in BackendVariable.varList(aliasVars2) loop
    cref := BackendVariable.varCref(var);
    if not BackendVariable.existsVar(cref, aliasVars1, false) then
      // put var back to the correct partition
      outDAE := fixAliasVarsCausal2(var, outDAE);
    else
      aliasVarList := var::aliasVarList;
    end if;
  end for;
  outDAE := BackendDAEUtil.setAliasVars(outDAE, BackendVariable.listVar(aliasVarList));

  //BackendDump.dumpVarList(knownVarList, "knownVarList in");
  for var in BackendVariable.varList(knownVars2) loop
    cref := BackendVariable.varCref(var);
    if not BackendVariable.existsVar(cref, knownVars1, false) and
       not (BackendVariable.isInput(var) or BackendVariable.isAlgebraicOldState(var)) then
      // put var back to the correct partition
      outDAE := fixKnownVarsCausal2(var, outDAE);
    else
      knownVarList := var::knownVarList;
    end if;
  end for;
  //BackendDump.dumpVarList(knownVarList, "knownVarList out");
  outDAE := BackendDAEUtil.setDAEGlobalKnownVars(outDAE, BackendVariable.listVar(knownVarList));
end fixAliasAndKnownVarsCausal;

protected function fixAliasVarsCausal2
  input BackendDAE.Var inVar;
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  DAE.Exp binding;
  list<DAE.ComponentRef> rightCrefs;
  BackendDAE.EqSystems eqs, eqs1 = {};
  BackendDAE.Shared shared;
  Boolean done=false;

  BackendDAE.Var var;
  BackendDAE.Equation eqn;

  BackendDAE.Variables orderedVars "ordered Variables, only states and alg. vars";
  BackendDAE.EquationArray orderedEqs "ordered Equations";
algorithm
  try
    binding := BackendVariable.varBindExp(inVar);
    rightCrefs := Expression.getAllCrefs(binding);
    BackendDAE.DAE(eqs, shared) := inDAE;
    var := BackendVariable.setBindExp(inVar, NONE());
    var := BackendVariable.setVarFixed(var, false) "??? should we do this ???";
    eqn := BackendDAE.EQUATION(BackendVariable.varExp(var), binding, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
    for eq in eqs loop
      BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs) := eq;
      if BackendVariable.existsAnyVar(rightCrefs, orderedVars, false) then
        orderedVars := BackendVariable.addVar(var, orderedVars);
        orderedEqs := BackendEquation.add(eqn, orderedEqs);
        eqs1 := BackendDAEUtil.setEqSystEqs(BackendDAEUtil.setEqSystVars(eq, orderedVars), orderedEqs)::eqs1;
        false := done;
        done := true;
      else
        eqs1 := eq::eqs1;
      end if;
    end for;

    // if no partition was selected, create a new one
    if not done then
      eqs1 := BackendDAEUtil.createEqSystem( BackendVariable.listVar({var}), BackendEquation.listEquation({eqn}),
                                         {}, BackendDAE.UNSPECIFIED_PARTITION() )::eqs1;
    end if;
    outDAE := BackendDAE.DAE(listReverse(eqs1), shared);
    //BackendDump.dumpVarList({inVar}, "fixAliasVarsCausal2 done for ...");
  else
    BackendDump.dumpVarList({inVar}, "fixAliasVarsCausal2 failed for ...");
    Error.addCompilerError("fixAliasVarsCausal2 failed");
    fail();
  end try;
end fixAliasVarsCausal2;

protected function fixKnownVarsCausal2
  input BackendDAE.Var inVar;
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  DAE.Exp binding;
  list<DAE.ComponentRef> rightCrefs;
  BackendDAE.EqSystems eqs1 = {};
  Boolean done=false;

  BackendDAE.Var var;
  BackendDAE.Equation eqn;

  BackendDAE.Variables orderedVars "ordered Variables, only states and alg. vars";
  BackendDAE.EquationArray orderedEqs "ordered Equations";
algorithm
  try
    binding := BackendVariable.varBindExp(inVar);
    rightCrefs := Expression.getAllCrefs(binding);
    var := BackendVariable.setBindExp(inVar, NONE());
    eqn := BackendDAE.EQUATION(BackendVariable.varExp(var), binding, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
    for eq in inDAE.eqs loop
      BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs) := eq;
      if BackendVariable.existsAnyVar(rightCrefs, orderedVars, false) then
        orderedVars := BackendVariable.addVar(var, orderedVars);
        orderedEqs := BackendEquation.add(eqn, orderedEqs);
        eqs1 := BackendDAEUtil.setEqSystEqs(BackendDAEUtil.setEqSystVars(eq, orderedVars), orderedEqs)::eqs1;
        false := done;
        done := true;
      else
        eqs1 := eq::eqs1;
      end if;
    end for;

    // if no partition was selected, create a new one
    if not done then
      eqs1 := BackendDAEUtil.createEqSystem( BackendVariable.listVar({var}), BackendEquation.listEquation({eqn}),
                                         {}, BackendDAE.UNSPECIFIED_PARTITION() )::eqs1;
    end if;
    outDAE := BackendDAE.DAE(listReverse(eqs1), inDAE.shared);
  else
    BackendDump.dumpVarList({inVar}, "fixKnownVarsCausal2 failed for ...");
    Error.addCompilerError("fixKnownVarsCausal2 failed");
    fail();
  end try;
end fixKnownVarsCausal2;

// =============================================================================
// section for fastAcausal
//
// =============================================================================

public function fastAcausal "author: Frenkel TUD 2012-12
  This Function remove with a linear scaling with respect to the number of
  equations in an acausal system as much as possible simple equations."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b, warnAliasConflicts;
  Integer size;
  HashSet.HashSet unReplaceable;
algorithm
  // get the size of the system to set up the replacement hashmap
  size := BackendDAEUtil.daeSize(inDAE);
  size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // check for unReplaceable crefs
  unReplaceable := HashSet.emptyHashSet();
  unReplaceable := BackendDAEUtil.foldEqSystem(inDAE, addUnreplaceable, unReplaceable);
  ((_,unReplaceable)) := BackendDAEUtil.traverseBackendDAEExps(inDAE, Expression.traverseSubexpressionsHelper, (traverserExpUnreplaceable, unReplaceable));
  unReplaceable := addUnreplaceableFromWhens(inDAE, unReplaceable);
  if Flags.isSet(Flags.DUMP_REPL) then
    BackendDump.dumpHashSet(unReplaceable, "Unreplaceable Crefs:");
  end if;
  // traverse all systems and remove simple equations
  (outDAE, (repl, b, _, _, warnAliasConflicts)) := BackendDAEUtil.mapEqSystemAndFold(inDAE, fastAcausal1, (repl, false, unReplaceable, Flags.getConfigInt(Flags.MAXTRAVERSALS), false));
  if warnAliasConflicts and BackendDAEUtil.isSimulationDAE(inDAE.shared) then
    Error.addMessage(Error.CONFLICTING_ALIAS_SET, {});
  end if;
  // traverse the shared parts
  outDAE := removeSimpleEquationsShared(b, outDAE, repl);
end fastAcausal;

protected function addUnreplaceable
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable = inUnreplaceable;
protected
  BackendDAE.Variables orderedVars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := syst;
  for var in BackendVariable.varList(orderedVars) loop
    if BackendVariable.varUnreplaceable(var) then
      outUnreplaceable := BaseHashSet.add(BackendVariable.varCref(var), outUnreplaceable);
    end if;
  end for;
end addUnreplaceable;

protected function fastAcausal1 "author: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input tuple<BackendVarTransform.VariableReplacements, Boolean, HashSet.HashSet, Integer, Boolean> inTpl;
  output BackendDAE.EqSystem outSystem = BackendDAEUtil.copyEqSystem(inSystem);
  output BackendDAE.Shared outShared;
  output tuple<BackendVarTransform.VariableReplacements, Boolean, HashSet.HashSet, Integer, Boolean> outTpl;
protected
  BackendVarTransform.VariableReplacements repl;
  HashSet.HashSet unReplaceable;
  list<BackendDAE.Equation> eqnslst;
  list<SimpleContainer> simpleeqnslst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  array<list<Integer>> mT; //[varIdx] = simpleContainer
  Boolean foundSimple, globalFoundSimple, warnAliasConflicts;
  Integer maxTraversals;
algorithm
  // Don't apply removeSimpleEquations to clocked partitions
  if BackendDAEUtil.isClockedSyst(inSystem) then
    outSystem := inSystem;
    outShared := inShared;
    outTpl := inTpl;
    return;
  end if;

  try
    BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns) := outSystem;
    ((repl, globalFoundSimple, unReplaceable, maxTraversals, warnAliasConflicts)) := inTpl;
    // transform to list, this is later not neccesary because the acausal system should save the equations as list
    eqnslst := BackendEquation.equationList(eqns);
    mT := arrayCreate(BackendVariable.varsSize(vars), {});
    // check equations
    ((_, _, eqnslst, simpleeqnslst, _, _, foundSimple)) := List.fold( eqnslst, simpleEquationsFinder,
                                                                      (vars, inShared, {}, {}, 1, mT, false) );

    //print("Found "+intString(listLength(simpleeqnslst))+" SimpleEquationsContainers\n");
    //print(stringDelimitList(List.map(simpleeqnslst, dumpSimpleContainer),"\n")+"\n");

    (vars, outShared, repl, unReplaceable, eqnslst, globalFoundSimple, warnAliasConflicts) := causalFinder(foundSimple, simpleeqnslst, eqnslst, 1, maxTraversals, vars, inShared, repl, unReplaceable, mT, {}, globalFoundSimple, warnAliasConflicts);

    outSystem := updateSystem(globalFoundSimple, eqnslst, vars, repl, outSystem);
    outTpl := ((repl, globalFoundSimple, unReplaceable, maxTraversals, warnAliasConflicts));
    GC.free(mT);
  else
    //Error.addCompilerWarning("The module removeSimpleEquations failed for a subsystem. The relevant subsystem get skipped and the transformation is proceeded.");
    outSystem := inSystem;
    outShared := inShared;
    outTpl := inTpl;
  end try;
end fastAcausal1;

protected function causalFinder "author: Frenkel TUD 2012-12"
  input Boolean foundSimple;
  input list<SimpleContainer> simpleContainerIn;
  input list<BackendDAE.Equation> iEqnslst;
  input Integer traversalIdx;
  input Integer maxTraversals;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input HashSet.HashSet iUnreplaceable;
  input array<list<Integer>> iMT;
  input list<BackendDAE.Equation> iGlobalEqnslst;
  input Boolean inGlobalFoundSimple;
  output BackendDAE.Variables outVars = iVars;
  output BackendDAE.Shared outShared = ishared;
  output BackendVarTransform.VariableReplacements outRepl = iRepl;
  output HashSet.HashSet outUnReplaceable = iUnreplaceable;
  output list<BackendDAE.Equation> outEqnslst;
  output Boolean outGlobalFoundSimple = inGlobalFoundSimple;
  input output Boolean warnAliasConflicts;
protected
  BackendDAE.Variables vars;
  BackendVarTransform.VariableReplacements repl;
  Boolean b, b1;
  array<SimpleContainer> simpleContainer;
  list<BackendDAE.Equation> eqnslst;
  BackendDAE.Shared shared;
algorithm
  if foundSimple then
    // transform simpleeqns to array
    simpleContainer := List.listArrayReverse(simpleContainerIn);
    // collect and handle sets
    (vars, eqnslst, shared, repl, b) := handleSets(arrayLength(simpleContainer), 1, simpleContainer, iMT, iUnreplaceable, iVars, iEqnslst, ishared, iRepl);
    warnAliasConflicts := warnAliasConflicts or b;

    // perform replacements and try again
    (eqnslst, b1) := BackendVarTransform.replaceEquations(eqnslst, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
    (outVars, outShared, outRepl, outUnReplaceable, outEqnslst, warnAliasConflicts) := causalFinder1(intGt(traversalIdx, maxTraversals), b1, eqnslst, traversalIdx+1, maxTraversals, vars, shared, repl, iUnreplaceable, iMT, iGlobalEqnslst, inGlobalFoundSimple, warnAliasConflicts);
    outGlobalFoundSimple := true;
  else
    outEqnslst := listAppend(iEqnslst, iGlobalEqnslst);
  end if;
end causalFinder;

protected function causalFinder1 "author: Frenkel TUD 2012-12"
  input Boolean finished "index > traversal";
  input Boolean b;
  input list<BackendDAE.Equation> iEqnslst;
  input Integer index;
  input Integer maxTraversals;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input HashSet.HashSet iUnreplaceable;
  input array<list<Integer>> iMT;
  input list<BackendDAE.Equation> iGlobalEqnslst;
  input Boolean inGlobalFoundSimple;
  output BackendDAE.Variables outVars = iVars;
  output BackendDAE.Shared outShared = ishared;
  output BackendVarTransform.VariableReplacements outRepl = iRepl;
  output HashSet.HashSet outUnReplaceable = iUnreplaceable;
  output list<BackendDAE.Equation> outEqnslst = listAppend(iEqnslst, iGlobalEqnslst);
  input output Boolean warnAliasConflicts;
algorithm
  (outVars, outShared, outRepl, outUnReplaceable, outEqnslst) :=
  match (finished, b, iEqnslst, index, iVars, ishared, iRepl, iUnreplaceable, iGlobalEqnslst)
    local
      Boolean b1;
      list<BackendDAE.Equation> eqnslst;
      list<SimpleContainer> simpleeqnslst;
      BackendDAE.Variables vars;
      BackendDAE.Shared shared;
    case(true, _, _, _, _, _, _, _, _) then (iVars, ishared, iRepl, iUnreplaceable, listAppend(iEqnslst, iGlobalEqnslst));
    case(_, false, {}, _, _, _, _, _, _) then (iVars, ishared, iRepl, iUnreplaceable, iGlobalEqnslst);
    case(_, false, _, _, _, _, _, _, _) then (iVars, ishared, iRepl, iUnreplaceable, listAppend(iEqnslst, iGlobalEqnslst));
    case(_, true, _, _, _, _, _, _, _)
      equation
        ((vars, shared, eqnslst, simpleeqnslst, _, _, b1)) = List.fold(iEqnslst, simpleEquationsFinder, (iVars, ishared, {}, {}, 1, iMT, false));
        (outVars, outShared, outRepl, outUnReplaceable, outEqnslst, _, warnAliasConflicts) = causalFinder(b1, simpleeqnslst, eqnslst, index, maxTraversals, vars, shared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, inGlobalFoundSimple, warnAliasConflicts);
      then
        (outVars, outShared, outRepl, outUnReplaceable, outEqnslst);
  end match;
end causalFinder1;


// =============================================================================
// section for allAcausal
//
// =============================================================================

public function allAcausal "author: Frenkel TUD 2012-12"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b, warnAliasConflicts;
  Integer size;
  HashSet.HashSet unReplaceable;
algorithm
  // get the size of the system to set up the replacement hashmap
  size := BackendDAEUtil.daeSize(inDAE);
  size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // check for unReplaceable crefs
  unReplaceable := HashSet.emptyHashSet();
  unReplaceable := BackendDAEUtil.foldEqSystem(inDAE, addUnreplaceable, unReplaceable);
  ((_,unReplaceable)) := BackendDAEUtil.traverseBackendDAEExps(inDAE, Expression.traverseSubexpressionsHelper, (traverserExpUnreplaceable, unReplaceable));
  unReplaceable := addUnreplaceableFromWhens(inDAE, unReplaceable);
  if Flags.isSet(Flags.DUMP_REPL) then
    BackendDump.dumpHashSet(unReplaceable, "Unreplaceable Crefs:");
  end if;
  (outDAE, (repl, _, b, warnAliasConflicts)) := BackendDAEUtil.mapEqSystemAndFold(inDAE, allAcausal1, (repl, unReplaceable, false, false));
  if warnAliasConflicts and BackendDAEUtil.isSimulationDAE(inDAE.shared) then
    Error.addMessage(Error.CONFLICTING_ALIAS_SET, {});
  end if;
  outDAE := removeSimpleEquationsShared(b, outDAE, repl);
  // until remove simple equations does not update assignments and comps remove them
end allAcausal;

protected function allAcausal1 "author: Frenkel TUD 2012-12
  This function moves simple equations on the form a=b and a=const and
  a=f(not time) in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean, Boolean> inTpl;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared;
  output tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean, Boolean> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendVarTransform.VariableReplacements repl;
  HashSet.HashSet unReplaceable;
  Boolean b, b1, warnAliasConflicts;
  array<list<Integer>> mT;
  list<BackendDAE.Equation> eqnslst;
  BackendDAE.EqSystem syst;
algorithm
  // Don't apply removeSimpleEquations to clocked partitions
  if BackendDAEUtil.isClockedSyst(inSystem) then
    outSystem := inSystem;
    outShared := inShared;
    outTpl := inTpl;
    return;
  end if;

  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns) := inSystem;
  ((repl, unReplaceable, b1, warnAliasConflicts)) := inTpl;

  // transform to list, this is later not neccesary because the acausal system should save the equations as list
  eqnslst := BackendEquation.equationList(eqns);
  mT := arrayCreate(BackendVariable.varsSize(vars), {});

  // check equations
  ((vars, outShared, repl, unReplaceable, _, eqnslst, b, warnAliasConflicts)) := allCausalFinder(eqnslst, (vars, inShared, repl, unReplaceable, mT, {}, false, warnAliasConflicts));

  outSystem := updateSystem(b, eqnslst, vars, repl, inSystem);
  outTpl := ((repl, unReplaceable, b or b1, warnAliasConflicts));
end allAcausal1;


// =============================================================================
// section for causal
//
// =============================================================================

public function causal "author: Frenkel TUD 2012-12"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b, warnAliasConflicts;
  Integer size;
  HashSet.HashSet unReplaceable;
algorithm
  // get the size of the system to set up the replacement hashmap
  size := BackendDAEUtil.daeSize(inDAE);
  size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // check for unReplaceable crefs
  unReplaceable := HashSet.emptyHashSet();
  unReplaceable := BackendDAEUtil.foldEqSystem(inDAE, addUnreplaceable, unReplaceable);
  ((_,unReplaceable)) := BackendDAEUtil.traverseBackendDAEExps(inDAE, Expression.traverseSubexpressionsHelper, (traverserExpUnreplaceable, unReplaceable));
  unReplaceable := addUnreplaceableFromWhens(inDAE, unReplaceable);
  // do not replace state sets
  unReplaceable := addUnreplaceableFromStateSets(inDAE, unReplaceable);
  if Flags.isSet(Flags.DUMP_REPL) then
    BackendDump.dumpHashSet(unReplaceable, "Unreplaceable Crefs:");
  end if;
  (outDAE, (repl, _, b, warnAliasConflicts)) := BackendDAEUtil.mapEqSystemAndFold(inDAE, causal1, (repl, unReplaceable, false, false));
  if warnAliasConflicts and BackendDAEUtil.isSimulationDAE(inDAE.shared) then
    Error.addMessage(Error.CONFLICTING_ALIAS_SET, {});
  end if;
  outDAE := removeSimpleEquationsShared(b, outDAE, repl);
  // until remove simple equations does not update assignments and comps remove them
end causal;

protected function causal1 "author: Frenkel TUD 2012-12
  This function moves simple equations on the form a=b and a=const and
  a=f(not time) in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean, Boolean> inTpl;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared;
  output tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean, Boolean> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.StrongComponents comps;
  BackendVarTransform.VariableReplacements repl;
  HashSet.HashSet unReplaceable;
  Boolean b, b1, warnAliasConflicts;
  array<list<Integer>> mT;
  list<BackendDAE.Equation> eqnslst;
  BackendDAE.EqSystem syst;
algorithm
  // Don't apply removeSimpleEquations to clocked partitions
  if BackendDAEUtil.isClockedSyst(inSystem) then
    outSystem := inSystem;
    outShared := inShared;
    outTpl := inTpl;
    return;
  end if;

  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, matching=BackendDAE.MATCHING(comps=comps)) := inSystem;
  ((repl, unReplaceable, b1, warnAliasConflicts)) := inTpl;

  mT := arrayCreate(BackendVariable.varsSize(vars), {});

  // check equations
  ((vars, outShared, repl, unReplaceable, _, eqnslst, b, warnAliasConflicts)) := traverseComponents(comps, eqns, allCausalFinder, (vars, inShared, repl, unReplaceable, mT, {}, false, warnAliasConflicts));

  outSystem := updateSystem(b, eqnslst, vars, repl, inSystem);
  outTpl := ((repl, unReplaceable, b or b1, warnAliasConflicts));
end causal1;

protected function traverseComponents "author: Frenkel TUD 2010-12"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EquationArray iEqns;
  input FuncType inFunc;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncType
    input list<BackendDAE.Equation> iEqns;
    input Type_a inTypeA;
    output Type_a outTypeA;
  end FuncType;
algorithm
  outTypeA :=
  match(inComps, iEqns, inFunc, inTypeA)
    local
      Integer e;
      list<Integer> elst;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqnlst, eqnlst1;
      BackendDAE.InnerEquations innerEquations;
      BackendDAE.InnerEquation innerEquation;
      Type_a arg;
    case ({}, _, _, _) then inTypeA;
    case (BackendDAE.SINGLEEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.get(iEqns, e);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst)::rest, _, _, _)
      equation
        eqnlst = BackendEquation.getList(elst, iEqns);
        arg = inFunc(eqnlst, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEARRAY(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.get(iEqns, e);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEIFEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.get(iEqns, e);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEALGORITHM(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.get(iEqns, e);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.get(iEqns, e);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.get(iEqns, e);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=elst, innerEquations=innerEquations))::rest, _, _, _)
      equation
        // collect all equations
        eqnlst = BackendEquation.getList(elst, iEqns);
        (elst,_,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        eqnlst1 = BackendEquation.getList(elst, iEqns);
        eqnlst = listAppend(eqnlst, eqnlst1);
        arg = inFunc(eqnlst, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
  end match;
end traverseComponents;

protected function allCausalFinder "author: Frenkel TUD 2012-12"
  input list<BackendDAE.Equation> eqns;
  input tuple<BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean, Boolean> inTpl;
  output tuple<BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean, Boolean> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.Shared shared;
  BackendVarTransform.VariableReplacements repl;
  HashSet.HashSet unReplaceable;
  array<list<Integer>> mt;
  Boolean b, b1, b2, b3, globalFoundSimple, warnAliasConflicts;
  list<BackendDAE.Equation> globaleqnslst, eqnslst;
  list<SimpleContainer> simpleeqnslst;
algorithm
  (vars, shared, repl, unReplaceable, mt, globaleqnslst, b, warnAliasConflicts) := inTpl;
  (eqnslst, b2) := BackendVarTransform.replaceEquations(eqns, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
  ((_, _, eqnslst, simpleeqnslst, _, _, b1)) := List.fold(eqnslst, simpleEquationsFinder, (vars, shared, {}, {}, 1, mt, false));
  (vars, shared, repl, unReplaceable, eqnslst, globalFoundSimple, b3) := allCausalFinder1(b1, b2, simpleeqnslst, eqnslst, vars, shared, repl, unReplaceable, mt, globaleqnslst, b, warnAliasConflicts);
  warnAliasConflicts := warnAliasConflicts or b3;
  outTpl := (vars, shared, repl, unReplaceable, mt, eqnslst, globalFoundSimple, warnAliasConflicts);
end allCausalFinder;

protected function allCausalFinder1 "author: Frenkel TUD 2012-12"
  input Boolean foundSimple;
  input Boolean didReplacement;
  input list<SimpleContainer> iSimpleeqnslst;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input HashSet.HashSet iUnreplaceable;
  input array<list<Integer>> iMT;
  input list<BackendDAE.Equation> iGlobalEqnslst;
  input Boolean globalFoundSimple;
  output BackendDAE.Variables outVars;
  output BackendDAE.Shared outShared;
  output BackendVarTransform.VariableReplacements outRepl;
  output HashSet.HashSet outUnReplaceable;
  output list<BackendDAE.Equation> outEqnslst;
  output Boolean outGlobalFoundSimple;
  input output Boolean warnAliasConflicts;
algorithm
  (outVars, outShared, outRepl, outUnReplaceable, outEqnslst, outGlobalFoundSimple, warnAliasConflicts) :=
  match (foundSimple, didReplacement, iSimpleeqnslst, iEqnslst, iVars, ishared, iRepl, iUnreplaceable, iGlobalEqnslst, globalFoundSimple)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      Boolean b, b1;
      array<SimpleContainer> simpleeqns;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
    case (false, _, _, {}, _, _, _, _, _, _)
      then (iVars, ishared, iRepl, iUnreplaceable, iGlobalEqnslst, didReplacement or globalFoundSimple, warnAliasConflicts);
    case (false, _, _, _, _, _, _, _, _, _)
      then (iVars, ishared, iRepl, iUnreplaceable, listAppend(iEqnslst, iGlobalEqnslst), didReplacement or globalFoundSimple, warnAliasConflicts);
    case (true, _, _, _, _, _, _, _, _, _)
      equation
        // transform simpleeqns to array
        simpleeqns = List.listArrayReverse(iSimpleeqnslst);
        // collect and handle sets
        (vars, eqnslst, shared, repl, b) = handleSets(arrayLength(simpleeqns), 1, simpleeqns, iMT, iUnreplaceable, iVars, iEqnslst, ishared, iRepl);
        warnAliasConflicts = warnAliasConflicts or b;

        // perform replacements and try again
        (eqnslst, b1) = BackendVarTransform.replaceEquations(eqnslst, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
      then
        allCausalFinder2(b1, eqnslst, vars, shared, repl, iUnreplaceable, iMT, iGlobalEqnslst, true, warnAliasConflicts);
  end match;
end allCausalFinder1;

protected function allCausalFinder2 "author: Frenkel TUD 2012-12"
  input Boolean b;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input HashSet.HashSet iUnreplaceable;
  input array<list<Integer>> iMT;
  input list<BackendDAE.Equation> iGlobalEqnslst;
  input Boolean globalFoundSimple;
  output BackendDAE.Variables outVars;
  output BackendDAE.Shared outShared;
  output BackendVarTransform.VariableReplacements outRepl;
  output HashSet.HashSet outUnReplaceable;
  output list<BackendDAE.Equation> outEqnslst;
  output Boolean outGlobalFoundSimple;
  input output Boolean warnAliasConflicts;
algorithm
  (outVars, outShared, outRepl, outUnReplaceable, outEqnslst, outGlobalFoundSimple, warnAliasConflicts) :=
  match (b, iEqnslst, iVars, ishared, iRepl, iUnreplaceable, iGlobalEqnslst, globalFoundSimple)
    local
      Boolean b1;
      list<BackendDAE.Equation> eqnslst;
      list<SimpleContainer> simpleeqnslst;
      BackendDAE.Variables vars;
      BackendDAE.Shared shared;
    case(false, {}, _, _, _, _, _, _) then (iVars, ishared, iRepl, iUnreplaceable, iGlobalEqnslst, globalFoundSimple, warnAliasConflicts);
    case(false, _, _, _, _, _, _, _) then (iVars, ishared, iRepl, iUnreplaceable, listAppend(iEqnslst, iGlobalEqnslst), globalFoundSimple, warnAliasConflicts);
    case(true, _, _, _, _, _, _, _)
      equation
        ((vars, shared, eqnslst, simpleeqnslst, _, _, b1)) = List.fold(iEqnslst, simpleEquationsFinder, (iVars, ishared, {}, {}, 1, iMT, false));
      then
        allCausalFinder1(b1, false, simpleeqnslst, eqnslst, vars, shared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple, warnAliasConflicts);
  end match;
end allCausalFinder2;


// =============================================================================
// functions to find simple equations
//
// =============================================================================

protected function simpleEquationsFinder "author: Frenkel TUD 2012-12
  map from equation to lhs and rhs"
  input BackendDAE.Equation eqn;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl:=
  matchcontinue (eqn, inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp e1, e2;
      DAE.ElementSource source;
      BackendDAE.Variables v;
      BackendDAE.Shared s;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      Boolean b;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr), _)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStrExpStr("Found Equation ", e1, " = ", e2, " to handle.\n");
        end if;
      then
        simpleEquationAcausal(e1, e2, (source, eqAttr), false, inTpl);

    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), _)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStrExpStr("Found Array Equation ", e1, " = ", e2, " to handle.\n");
        end if;
      then
        simpleArrayEquationAcausal(e1, e2, Expression.typeof(e1), (source, eqAttr), inTpl);

    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, attr=eqAttr), _)
      equation
        e1 = Expression.crefExp(cr);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStrExpStr("Found Solved Equation ", e1, " = ", e2, " to handle.\n");
        end if;
      then
        simpleEquationAcausal(e1, e2, (source, eqAttr), false, inTpl);

    case (BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, attr=eqAttr), _)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStr("Found Residual Equation ", e1, " to handle.\n");
        end if;
      then
        simpleExpressionAcausal(e1, (source, eqAttr), false, inTpl);

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), _)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStrExpStr("Found Complex Equation ", e1, " = ", e2, " to handle.\n");
        end if;
      then
        simpleEquationAcausal(e1, e2, (source, eqAttr), false, inTpl);

    case (_, (v, s, eqns, seqns, index, mT, b))
      then ((v, s, eqn::eqns, seqns, index, mT, b));

   end matchcontinue;
end simpleEquationsFinder;

protected function simpleEquationAcausal "author Frenkel TUD 2012-12
  helper for simpleEquationsFinder"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (lhs, rhs, eqnAttributes, selfCalled, inTpl)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2;
      DAE.Type ty;
      list<DAE.Exp> elst1, elst2;
      list<list<DAE.Exp>> elstlst1, elstlst2;
      DAE.Operator op;

    // a = b;
    case (DAE.CREF(componentRef = cr1), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, false, cr2, rhs, false, eqnAttributes, selfCalled, inTpl);

    // a = -b;
    case (DAE.CREF(componentRef = cr1), DAE.UNARY(op as DAE.UMINUS(_), DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.UNARY(op, lhs), false, cr2, rhs, true, eqnAttributes, selfCalled, inTpl);

    case (DAE.CREF(componentRef = cr1), DAE.UNARY(op as DAE.UMINUS_ARR(_), DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.UNARY(op, lhs), false, cr2, rhs, true, eqnAttributes, selfCalled, inTpl);

    // -a = b;
    case (DAE.UNARY(op as DAE.UMINUS(_), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, true, cr2,  DAE.UNARY(op, rhs), false, eqnAttributes, selfCalled, inTpl);

    case (DAE.UNARY(op as DAE.UMINUS_ARR(_), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, true, cr2,  DAE.UNARY(op, rhs), false, eqnAttributes, selfCalled, inTpl);

    // -a = -b;
    case (DAE.UNARY(DAE.UMINUS(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS(_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);

    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);

    // a = not b;
    case (DAE.CREF(componentRef = cr1), DAE.LUNARY(op as DAE.NOT(_), DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.LUNARY(op, lhs), false, cr2, rhs, true, eqnAttributes, selfCalled, inTpl);

    // not a = b;
    case (DAE.LUNARY(op as DAE.NOT(_), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, true, cr2, DAE.LUNARY(op, lhs), false, eqnAttributes, selfCalled, inTpl);

    // not a = not b;
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = cr1)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);

    // {a1, a2, a3, ..} = {b1, b2, b3, ..};
    case (DAE.ARRAY(array = elst1), DAE.ARRAY(array = elst2), _, _, _)
      then List.threadFold2(elst1, elst2, simpleEquationAcausal, eqnAttributes, true, inTpl);

    case (DAE.MATRIX(matrix = elstlst1), DAE.MATRIX(matrix = elstlst2), _, _, _)
      then List.threadFold2(elstlst1, elstlst2, simpleEquationAcausalLst, eqnAttributes, true, inTpl);

    // a = {b1, b2, b3, ..}
    case (DAE.CREF(), DAE.ARRAY(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.CREF(), DAE.MATRIX(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // -a = {b1, b2, b3, ..}
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.ARRAY(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.MATRIX(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // a = -{b1, b2, b3, ..}
    case (DAE.CREF(), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.CREF(), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // -a = -{b1, b2, b3, ..}
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF()), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF()), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    // {a1, a2, a3, ..} = b
    case (DAE.ARRAY(ty=ty), DAE.CREF(), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.MATRIX(ty=ty), DAE.CREF(), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // -{a1, a2, a3, ..} = b
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(ty=ty)), DAE.CREF(), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.MATRIX(ty=ty)), DAE.CREF(), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // {a1, a2, a3, ..} = -b
    case (DAE.ARRAY(ty=ty), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.MATRIX(ty=ty), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // -{a1, a2, a3, ..} = -b
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.ARRAY(ty=ty)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.MATRIX(ty=ty)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    // not a = {b1, b2, b3, ..}
    case (DAE.LUNARY(DAE.NOT(_), DAE.CREF()), DAE.ARRAY(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.LUNARY(DAE.NOT(_), DAE.CREF()), DAE.MATRIX(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // a = not {b1, b2, b3, ..}
    case (DAE.CREF(), DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.CREF(), DAE.LUNARY(DAE.NOT(_), DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // not a = not {b1, b2, b3, ..}
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF()), DAE.LUNARY(DAE.NOT(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF()), DAE.LUNARY(DAE.NOT(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    // {a1, a2, a3, ..} = not b
    case (DAE.ARRAY(ty=ty), DAE.LUNARY(DAE.NOT(_), DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.MATRIX(ty=ty), DAE.LUNARY(DAE.NOT(_), DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // not {a1, a2, a3, ..} = b
    case (DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(ty=ty)), DAE.CREF(), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    case (DAE.LUNARY(DAE.NOT(_), DAE.MATRIX(ty=ty)), DAE.CREF(), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);

    // not {a1, a2, a3, ..} = not b
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.ARRAY(ty=ty)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.MATRIX(ty=ty)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF()), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    // time independent equations
    else
      then simpleEquationAcausal1(lhs, rhs, eqnAttributes, selfCalled, inTpl);

  end match;
end simpleEquationAcausal;


protected function simpleArrayEquationAcausal "author Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type ty;
  input EquationSourceAndAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
protected
  DAE.Dimensions dims;
  list<Integer> ds;
  list<list<DAE.Subscript>> subslst;
  list<DAE.Exp> elst1, elst2;
  Boolean hasInlineAfterIndexReduction, expandLhs, expandRhs;
  DAE.ElementSource source;
  BackendDAE.EquationAttributes attr;
  BackendDAE.Equation eq;
algorithm
  dims := Expression.arrayDimension(ty);
  ds := Expression.dimensionsSizes(dims);
  subslst := List.map(ds, Expression.dimensionSizeSubscripts);
  subslst := Expression.rangesToSubscripts(subslst);
  if listEmpty(subslst) then
    (source,attr) := eqnAttributes;
    outTpl := inTpl;
    return;
    /* TODO: Shouldn't we generate some sort of assertion for the lhs/rhs actually being of zero dimension or not throwing errors at run-time? */
    for e in {lhs,rhs} loop
      if Expression.isEvaluatedConst(e) then
        continue;
      end if;
      eq := BackendDAE.WHEN_EQUATION(0, BackendDAE.WHEN_STMTS(
        DAE.BCONST(false),
        {BackendDAE.ASSERT(DAE.BCONST(false), DAE.SCONST("Failed assertion exp is 0"), DAE.ASSERTIONLEVEL_ERROR, source)},
        NONE()
      ), source, attr);
      outTpl := simpleEquationsFinder(eq, outTpl);
    end for;
    return;
    /* End TODO. Note: The above code does not execute */
  end if;
  (,hasInlineAfterIndexReduction) := Expression.traverseExpTopDown(lhs, Expression.findCallIsInlineAfterIndexReduction, false);
  (,hasInlineAfterIndexReduction) := Expression.traverseExpTopDown(rhs, Expression.findCallIsInlineAfterIndexReduction, hasInlineAfterIndexReduction);
  (elst1,expandLhs) := List.mapFold(subslst, function Expression.applyExpSubscriptsFoldCheckSimplify(exp=lhs), false);
  (elst2,expandRhs) := List.mapFold(subslst, function Expression.applyExpSubscriptsFoldCheckSimplify(exp=rhs), false);
  if not hasInlineAfterIndexReduction then
    // If inlining after index reduction or i, we need to expand equations to pass sorting+matching
    // Note: We *should* be looking for the derivative annotation here, but it's not available directly
    //       and better would be if sorting+matching could expand/split equations when necessary
    if false and not (expandLhs and expandRhs) then
      print(getInstanceName() + " not expanding " + ExpressionDump.printExpStr(lhs) + " = " + ExpressionDump.printExpStr(rhs) + "\n");
    end if;
    true := expandLhs and expandRhs "Do not expand equation if it doesn't help with anything... Like x=f(...); => x[1]=f()[1], ..., x[n]=f()[n]";
  else
  end if;
  outTpl := List.threadFold2(elst1, elst2, simpleEquationAcausal, eqnAttributes, true, inTpl);
end simpleArrayEquationAcausal;

protected function simpleEquationAcausalLst "author: Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input list<DAE.Exp> elst1;
  input list<DAE.Exp> elst2;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := List.threadFold2(elst1, elst2, simpleEquationAcausal, eqnAttributes, selfCalled, inTpl);
end simpleEquationAcausalLst;

protected function simpleEquationAcausal1 "author: Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs, rhs, eqnAttributes, selfCalled, inTpl)
    local
      list<DAE.Exp> elst1, elst2;
    // Record
    case (_, _, _, _, _)
      equation
        elst1 = Expression.splitRecord(lhs, Expression.typeof(lhs));
        elst2 = Expression.splitRecord(rhs, Expression.typeof(rhs));
      then List.threadFold2(elst1, elst2, simpleEquationAcausal, eqnAttributes, true, inTpl);
    // {a1+b1, a2+b2, a3+b3, ..} = 0;
    case (DAE.ARRAY(array = elst1), _, _, _, _)
      guard
        Expression.isZero(rhs)
      then List.fold2(elst1, simpleExpressionAcausal, eqnAttributes, true, inTpl);
    // 0 = {a1+b1, a2+b2, a3+b3, ..};
    case (_, DAE.ARRAY(array = elst2), _, _, _)
      guard
        Expression.isZero(lhs)
      then List.fold2(elst2, simpleExpressionAcausal, eqnAttributes, true, inTpl);
     // lhs = 0
    case (_, _, _, _, _)
      guard
        Expression.isZero(rhs)
      then simpleExpressionAcausal(lhs, eqnAttributes, selfCalled, inTpl);
    // 0 = rhs
    case (_, _, _, _, _)
      guard
        Expression.isZero(lhs)
      then simpleExpressionAcausal(rhs, eqnAttributes, selfCalled, inTpl);
    // time independent equations
    else
      then timeIndependentEquationAcausal(lhs, rhs, eqnAttributes, selfCalled, inTpl);
  end matchcontinue;
end simpleEquationAcausal1;

protected function generateEquation "author: Frenkel TUD 2012-12
  helper to generate an equation from lhs and rhs.
  This function is called if an equation is found which is not simple"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Type ty;
  input EquationSourceAndAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs, rhs, ty, eqnAttributes, inTpl)
    local
      Integer size;
      DAE.Dimensions dims;
      list<Integer> ds;
      BackendDAE.Variables v;
      BackendDAE.Shared s;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      Boolean b, b1, b2;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;

    // complex types to complex equations
    case (_, _, _, (source, eqAttr), (v, s, eqns, seqns, index, mT, b))
      guard
        DAEUtil.expTypeComplex(ty)
      equation
        size = Expression.sizeOf(ty);
        //  print("Add Equation:\n" + BackendDump.equationStr(BackendDAE.COMPLEX_EQUATION(size, lhs, rhs, source)) + "\n");
       then
        ((v, s, BackendDAE.COMPLEX_EQUATION(size, lhs, rhs, source, eqAttr)::eqns, seqns, index, mT, b));
    // array types to array equations
    case (_, _, _, (source, eqAttr), (v, s, eqns, seqns, index, mT, b))
      guard
        DAEUtil.expTypeArray(ty)
      equation
        dims = Expression.arrayDimension(ty);
        ds = Expression.dimensionsSizes(dims);
        //  print("Add Equation:\n" + BackendDump.equationStr(BackendDAE.ARRAY_EQUATION(ds, lhs, rhs, source)) + "\n");
      then
        ((v, s, BackendDAE.ARRAY_EQUATION(ds, lhs, rhs, source, eqAttr)::eqns, seqns, index, mT, b));
    // other types
    case (_, _, _, (source, eqAttr), (v, s, eqns, seqns, index, mT, b))
      equation
        b1 = DAEUtil.expTypeComplex(ty);
        b2 = DAEUtil.expTypeArray(ty);
        false = b1 or b2;
        //  print("Add Equation:\n" + BackendDump.equationStr(BackendDAE.EQUATION(lhs, rhs, source)) + "\n");
        //Error.assertionOrAddSourceMessage(not b1, Error.INTERNAL_ERROR, {str}, Absyn.dummyInfo);
      then
        ((v, s, BackendDAE.EQUATION(lhs, rhs, source, eqAttr)::eqns, seqns, index, mT, b));
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAEOptimize.generateEquation failed on: " + ExpressionDump.printExpStr(lhs) + " = " + ExpressionDump.printExpStr(rhs) + "\n");
      then
        fail();
  end matchcontinue;
end generateEquation;

protected function simpleExpressionAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp exp;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (exp, eqnAttributes, selfCalled, inTpl)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2;
      DAE.Type ty, tp;

    // a + b = 0 => a = -b
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.ADD(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.UNARY(DAE.UMINUS(ty), e1), false, cr2, e2, true, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.ADD_ARR(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.UNARY(DAE.UMINUS_ARR(ty), e1), false, cr2, e2, true, eqnAttributes, selfCalled, inTpl);

    // a - b = 0 => a = b
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.SUB(), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.SUB_ARR(), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);

    // -a + b = 0 => a = b
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ADD(), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ADD_ARR(), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);

    // -a - b = 0 => -a = b
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = cr1)), DAE.SUB(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, true, cr2, DAE.UNARY(DAE.UMINUS(ty), e2), false, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = cr1)), DAE.SUB_ARR(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, true, cr2,  DAE.UNARY(DAE.UMINUS_ARR(ty), e2), false, eqnAttributes, selfCalled, inTpl);

    // a + {b1, b2, b3} = 0 => a = -{b1, b2, b3}
    case (DAE.BINARY(e1 as DAE.CREF(), DAE.ADD_ARR(tp), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(tp), e2), ty, eqnAttributes, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(), DAE.ADD_ARR(tp), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(tp), e2), ty, eqnAttributes, inTpl);

    // a - {b1, b2, b3} = 0 => a = {b1, b2, b3}
    case (DAE.BINARY(e1 as DAE.CREF(), DAE.SUB_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(), DAE.SUB_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    // -a + {b1, b2, b3} = 0 => a = {b1, b2, b3}
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF()), DAE.ADD_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF()), DAE.ADD_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);

    // -a - {b1, b2, b3} = 0 => -a = {b1, b2, b3}
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.SUB_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(ty), e2), ty, eqnAttributes, inTpl);
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.SUB_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(ty), e2), ty, eqnAttributes, inTpl);

    // time independent equations
    else
      then timeIndependentExpressionAcausal(exp, eqnAttributes, selfCalled, inTpl);

  end match;

end simpleExpressionAcausal;

protected function addSimpleEquationAcausal "author: Frenkel TUD 2012-12
  add a simple equation to the list of simple equations"
  input DAE.ComponentRef cr1;
  input DAE.Exp inE1;
  input Boolean negatedCr1;
  input DAE.ComponentRef cr2;
  input DAE.Exp inE2;
  input Boolean negatedCr2;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean genEqn "true if not possible to get the Alias generate an equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue(cr1, inE1, negatedCr1, cr2, inE2, negatedCr2, eqnAttributes, genEqn, inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      list<BackendDAE.Var> vars1, vars2;
      list<Integer> ilst1, ilst2;
      Boolean b, varskn1, varskn2, time1, time2;
      DAE.Exp e1, e2;
      DAE.Type ty;

    case(_, _, _, _, _, _, _, _, (vars, shared, eqns, seqns, index, mT, _))
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrCrefStr("Alias Equation ", cr1, " = ", cr2, " found. Negated lhs[" + boolString(negatedCr1) + "] = rhs[" + boolString(negatedCr2) + "].\n");
        end if;
        // get Variables
        (vars1, ilst1, varskn1, time1) = getVars(cr1, vars, shared);
        (vars2, ilst2, varskn2, time2) = getVars(cr2, vars, shared);
        // add to Simple Equations List
        true = intEq(listLength(vars1),listLength(vars2));
        (seqns, index, mT) = generateSimpleContainters(vars1, negatedCr1, ilst1, varskn1, time1, vars2, negatedCr2, ilst2, varskn2, time2, eqnAttributes, seqns, index, mT);
      then
        ((vars, shared, eqns, seqns, index, mT, true));

    case(_, _, _, _, _, _, _, true, _)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStrExpStr("Non Alias Equation ", inE1, " = ", inE2, " to generate.\n");
        end if;
        e1 = Expression.crefExp(cr1);
        ty = Expression.typeof(e1);
        e2 = inE2;
      then
        generateEquation(e1, e2, ty, eqnAttributes, inTpl);

  end matchcontinue;
end addSimpleEquationAcausal;

protected function getVars "author: Frenkel TUD 2012-11"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  input BackendDAE.Shared shared;
  output list<BackendDAE.Var> oVars;
  output list<Integer> oIndexs;
  output Boolean varskn;
  output Boolean time_;
algorithm
  (oVars, oIndexs, varskn, time_) := matchcontinue(cr, vars, shared)
    case (DAE.CREF_IDENT(ident = "time", subscriptLst = {}), _, _)
      then
        ({}, {}, true, true);
    case (_, _, _)
      equation
        (oVars as _::_, oIndexs) = BackendVariable.getVar(cr, vars);
      then
        (oVars, oIndexs, false, false);
    case (_, _, _)
      algorithm
        (oVars as _::_, oIndexs) := BackendVariable.getVarShared(cr, shared);
        if ComponentReference.crefIsScalarWithVariableSubs(cr) then
        //waurich: We don't support this case properly at the moment. Don't assign an alias.
          oVars := {};
          oIndexs := {};
        end if;
      then
        (oVars, oIndexs, true, false);
  end matchcontinue;
end getVars;

protected function generateSimpleContainters "author: Frenkel TUD 2012-12
  add a simple equation to the list of simple equations"
  input list<BackendDAE.Var> vars1;
  input Boolean negatedCr1;
  input list<Integer> ilst1;
  input Boolean varskn1;
  input Boolean time1;
  input list<BackendDAE.Var> vars2;
  input Boolean negatedCr2;
  input list<Integer> ilst2;
  input Boolean varskn2;
  input Boolean time2;
  input EquationSourceAndAttributes eqnAttributes;
  input list<SimpleContainer> iSeqns;
  input Integer iIndex;
  input array<list<Integer>> iMT;
  output list<SimpleContainer> oSeqns;
  output Integer oIndex;
  output array<list<Integer>> oMT;
algorithm
  (oSeqns, oIndex, oMT) := match(vars1, negatedCr1, ilst1, varskn1, time1, vars2, negatedCr2, ilst2, varskn2, time2, eqnAttributes, iSeqns, iIndex, iMT)
    local
      BackendDAE.Var v1, v2;
      Integer i1, i2;
      list<BackendDAE.Var> vlst1, vlst2;
      list<Integer> irest1, irest2, colum;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      DAE.ComponentRef cr1, cr2;

    case ({BackendDAE.VAR(varName=cr1)}, _, {i1}, true, true, {BackendDAE.VAR(varName=cr2)}, _, {i2}, false, false, _, _, _, _)
      equation
        colum = iMT[i2];
        arrayUpdate(iMT, i2, iIndex::colum);
      then
        (TIMEALIAS(cr2, negatedCr2, i2, cr1, negatedCr1, i1, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);

    case ({BackendDAE.VAR(varName=cr1)}, _, {i1}, false, false, {BackendDAE.VAR(varName=cr2)}, _, {i2}, true, true, _, _, _, _)
      equation
        colum = iMT[i1];
        arrayUpdate(iMT, i1, iIndex::colum);
      then
        (TIMEALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);

    case({}, _, _, _, _, {}, _, _, _, _, _, _, _, _) then (iSeqns, iIndex, iMT);

    case(v1::vlst1, _, i1::irest1, _, false, v2::vlst2, _, i2::irest2, _, false, _, _, _, _)
      equation
        (seqns, index, mT) = generateSimpleContainter(v1, negatedCr1, i1, varskn1, v2, negatedCr2, i2, varskn2, eqnAttributes, iSeqns, iIndex, iMT);
        (seqns, index, mT) = generateSimpleContainters(vlst1, negatedCr1, irest1, varskn1, time1, vlst2, negatedCr2, irest2, varskn2, time2, eqnAttributes, seqns, index, mT);
      then
        (seqns, index, mT);

  end match;
end generateSimpleContainters;

protected function generateSimpleContainter "author: Frenkel TUD 2012-12
  add a simple equation to the list of simple equations"
  input BackendDAE.Var v1;
  input Boolean negatedCr1;
  input Integer i1;
  input Boolean varskn1;
  input BackendDAE.Var v2;
  input Boolean negatedCr2;
  input Integer i2;
  input Boolean varskn2;
  input EquationSourceAndAttributes eqnAttributes;
  input list<SimpleContainer> iSeqns;
  input Integer iIndex;
  input array<list<Integer>> iMT;
  output list<SimpleContainer> oSeqns;
  output Integer oIndex;
  output array<list<Integer>> oMT;
algorithm
  (oSeqns, oIndex, oMT) := match(v1, negatedCr1, i1, varskn1, v2, negatedCr2, i2, varskn2, eqnAttributes, iSeqns, iIndex, iMT)
    local
      DAE.ComponentRef cr1, cr2;
      list<Integer> colum;
      DAE.Exp crexp1, crexp2;
      String lhs, rhs;
      DAE.ElementSource source;

    case (BackendDAE.VAR(varName=cr1), _, _, false, BackendDAE.VAR(varName=cr2), _, _, false, _, _, _, _)
      equation
        checkEqualAlias(intEq(i1, i2), v1, negatedCr1, v2, negatedCr2, eqnAttributes);
        colum = iMT[i1];
        arrayUpdate(iMT, i1, iIndex::colum);
        colum = iMT[i2];
        arrayUpdate(iMT, i2, iIndex::colum);
      then
        (ALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);

    case (BackendDAE.VAR(varName=cr1), _, _, true, BackendDAE.VAR(varName=cr2), _, _, false, _, _, _, _)
      equation
        colum = iMT[i2];
        arrayUpdate(iMT, i2, iIndex::colum);
      then
        (PARAMETERALIAS(cr2, negatedCr2, i2, cr1, negatedCr1, i1, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);

    case (BackendDAE.VAR(varName=cr1), _, _, false, BackendDAE.VAR(varName=cr2), _, _, true, _, _, _, _)
      equation
        colum = iMT[i1];
        arrayUpdate(iMT, i1, iIndex::colum);
      then
        (PARAMETERALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);
    case (BackendDAE.VAR(varName=cr1), _, _, true, BackendDAE.VAR(varName=cr2), _, _, true, (source, _), _, _, _)
      equation
        crexp1 = Expression.crefExp(cr1);
        crexp2 = Expression.crefExp(cr2);
        crexp1 = negateExpression(negatedCr1, crexp1, crexp1, " generateSimpleContainter ");
        crexp2 = negateExpression(negatedCr2, crexp2, crexp2, " generateSimpleContainter ");
        lhs = ExpressionDump.printExpStr(crexp1);
        rhs = ExpressionDump.printExpStr(crexp2);
        Error.addSourceMessage(Error.EQ_WITHOUT_TIME_DEP_VARS, {lhs, rhs}, ElementSource.getElementSourceFileInfo(source));
      then
        fail();

  end match;
end generateSimpleContainter;

protected function checkEqualAlias "author: Frenkel TUD 2012-12
  report a warning if we found an equation a=a"
  input Boolean equal;
  input BackendDAE.Var v1;
  input Boolean negatedCr1;
  input BackendDAE.Var v2;
  input Boolean negatedCr2;
  input EquationSourceAndAttributes eqnAttributes;
algorithm
  _ := match(equal, v1, negatedCr1, v2, negatedCr2, eqnAttributes)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp crexp1, crexp2;
      String eqn_str, var_str;
      SourceInfo info;
      DAE.ElementSource source;

    case(false, _, _, _, _, _) then ();

    case(true, BackendDAE.VAR(varName=cr1), _, BackendDAE.VAR(varName=cr2), _, (source, _))
      equation
        var_str = BackendDump.varString(v1);
        crexp1 = Expression.crefExp(cr1);
        crexp2 = Expression.crefExp(cr2);
        crexp1 = negateExpression(negatedCr1, crexp1, crexp1, " checkEqualAlias ");
        crexp2 = negateExpression(negatedCr2, crexp2, crexp2, " checkEqualAlias ");
        eqn_str = ExpressionDump.printExpStr(crexp1) + " = " + ExpressionDump.printExpStr(crexp2) + "\n";
        info = ElementSource.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str, var_str}, info);
      then
        fail();

  end match;
end checkEqualAlias;

protected function timeIndependentEquationAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs, rhs, eqnAttributes, selfCalled, inTpl)
    local
      DAE.Type ty;
      BackendDAE.Variables vars, globalKnownVars;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
      AvlSetInt.Tree tree;

    case (_, _, _, _, (vars, BackendDAE.SHARED(globalKnownVars=globalKnownVars), _, _, _, _, _))
      equation
        // collect vars and check if variable time not there
        (_, (false, _, _, _, _, ilst)) = Expression.traverseExpTopDown(lhs, traversingTimeVarsFinder, (false, vars, globalKnownVars, false, false, {}));
        (_, (false, _, _, _, _, ilst)) = Expression.traverseExpTopDown(rhs, traversingTimeVarsFinder, (false, vars, globalKnownVars, false, false, ilst));
        tree = AvlSetInt.new();
        tree = AvlSetInt.addList(tree, ilst);
        ilst = AvlSetInt.listKeys(tree);
        vlst = List.map1r(ilst, BackendVariable.getVarAt, vars);
      then
        solveTimeIndependentAcausal(vlst, ilst, lhs, rhs, eqnAttributes, inTpl);
    // in all other case keep the equation
    case (_, _, _, true, _)
      equation
        ty = Expression.typeof(lhs);
      then
        generateEquation(lhs, rhs, ty, eqnAttributes, inTpl);
  end matchcontinue;
end timeIndependentEquationAcausal;

protected function timeIndependentExpressionAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp exp;
  input EquationSourceAndAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (exp, eqnAttributes, selfCalled, inTpl)
    local
      DAE.Exp e2;
      DAE.Type ty;
      BackendDAE.Variables vars, globalKnownVars;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
      AvlSetInt.Tree tree;

    case (_, _, _, (vars, BackendDAE.SHARED(globalKnownVars=globalKnownVars), _, _, _, _, _))
      equation
        // collect vars and check if variable time not there
        (_, (false, _, _, _, _, ilst)) = Expression.traverseExpTopDown(exp, traversingTimeVarsFinder, (false, vars, globalKnownVars, false, false, {}));
        tree = AvlSetInt.new();
        tree = AvlSetInt.addList(tree, ilst);
        ilst = AvlSetInt.listKeys(tree);
        vlst = List.map1r(ilst, BackendVariable.getVarAt, vars);
        ty = Expression.typeof(exp);
        e2 = Expression.makeConstZero(ty);
      then
        // shoulde be ok since solve checks only for iszero
        solveTimeIndependentAcausal(vlst, ilst, exp, e2, eqnAttributes, inTpl);
    // in all other case keep the equation
    case (_, _, true, _)
      equation
        ty = Expression.typeof(exp);
        e2 = Expression.makeConstZero(ty);
      then
        generateEquation(exp, e2, ty, eqnAttributes, inTpl);
  end matchcontinue;
end timeIndependentExpressionAcausal;

protected function toplevelInputOrUnfixed "author: Frenkel TUD 2012-12
  return true is var on topliven and input or is unfixed parameter or unreplaceable"
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := BackendVariable.isVarOnTopLevelAndInput(inVar) or BackendVariable.varUnreplaceable(inVar) or
       BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar);
end toplevelInputOrUnfixed;

protected function traversingTimeVarsFinder "author: Frenkel 2012-12"
  input DAE.Exp inExp;
  input tuple<Boolean, BackendDAE.Variables, BackendDAE.Variables, Boolean, Boolean, list<Integer>> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<Boolean, BackendDAE.Variables, BackendDAE.Variables, Boolean, Boolean, list<Integer>> outTuple;
algorithm
  (outExp,cont,outTuple) := matchcontinue (inExp,inTuple)
    local
      Boolean b, b1, b2;
      BackendDAE.Variables vars, globalKnownVars;
      DAE.ComponentRef cr;
      list<Integer> ilst, vlst;
      list<BackendDAE.Var> varlst;

    case (DAE.CREF(DAE.CREF_IDENT(ident="time", subscriptLst={}), _), (b, vars, globalKnownVars, b1, b2, ilst))
    then (inExp, false, if b then inTuple else (true, vars, globalKnownVars, b1, b2, ilst));

    case (DAE.CREF(cr, _), (b, vars, globalKnownVars, b1, b2, ilst)) equation
      (varlst, _::_)= BackendVariable.getVar(cr, globalKnownVars) "input variables stored in known variables are input on top level";
      false = List.mapAllValueBool(varlst, toplevelInputOrUnfixed, false);
    then (inExp, false, if b then inTuple else (true, vars, globalKnownVars, b1, b2, ilst));

    case (DAE.CALL(path = Absyn.IDENT(name="pre")), (b, vars, globalKnownVars, b1, b2, ilst)) then (inExp, false, if b then inTuple else (true, vars, globalKnownVars, b1, b2, ilst));
    case (DAE.CALL(path = Absyn.IDENT(name="previous")), (b, vars, globalKnownVars, b1, b2, ilst)) then (inExp, false, if b then inTuple else (true, vars, globalKnownVars, b1, b2, ilst) );
    case (DAE.CALL(path = Absyn.IDENT(name="change")), (b, vars, globalKnownVars, b1, b2, ilst)) then (inExp, false, if b then inTuple else (true, vars, globalKnownVars, b1, b2, ilst));
    case (DAE.CALL(path = Absyn.IDENT(name="edge")), (b, vars, globalKnownVars, b1, b2, ilst)) then (inExp, false, if b then inTuple else (true, vars, globalKnownVars, b1, b2, ilst));

    // var
    case (DAE.CREF(cr, _), (b, vars, globalKnownVars, b1, b2, ilst)) equation
      (_::_, vlst)= BackendVariable.getVar(cr, vars);
      ilst = listAppend(ilst, vlst);
    then (inExp, true, (b, vars, globalKnownVars, b1, b2, ilst));

    case (_, (b, _, _, _, _, _))
    then (inExp, not b, inTuple);
  end matchcontinue;
end traversingTimeVarsFinder;

protected function solveTimeIndependentAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input list<BackendDAE.Var> vlst;
  input list<Integer> ilst;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationSourceAndAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (vlst, ilst, lhs, rhs, eqnAttributes, inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp cre, es;
      BackendDAE.Var v;
      Integer i, size;
      DAE.FunctionTree functionTree;
      DAE.ElementSource source;
      Boolean diffed;
      BackendDAE.EquationAttributes eqAttr;

    case ({v as BackendDAE.VAR(varName=cr)}, {i}, _, _, _, _)
      equation
        // try to solve the equation
        cre = Expression.crefExp(cr);
        (es, {}) = ExpressionSolve.solve(lhs, rhs, cre);
        // constant or alias
      then
        constOrAliasAcausal(v, i, cr, es, eqnAttributes, inTpl);
    case (_, _, _, _, (source, eqAttr), (_, BackendDAE.SHARED(), _, _, _, _, _))
      equation
        // size of equation have to be equal with number of vars
        size = Expression.sizeOf(Expression.typeof(lhs));
        true = intEq(size, listLength(vlst));
     then
        solveTimeIndependentAcausal1(vlst, ilst, lhs, rhs, (source, eqAttr), inTpl);
  end match;
end solveTimeIndependentAcausal;

protected function solveTimeIndependentAcausal1 "author: Frenkel TUD 2012-12
  helper for simpleEquations"
  input list<BackendDAE.Var> vlst;
  input list<Integer> ilst;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationSourceAndAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (vlst, ilst, lhs, rhs, eqnAttributes, inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp cre, es;
      list<DAE.ComponentRef> crlst;
    // a = ...
    case (_, _, _, _, _, _)
      equation
        cr::crlst = List.map(vlst, BackendVariable.varCref);
        cr = ComponentReference.crefStripLastSubs(cr);
        List.map1rAllValue(crlst, ComponentReference.crefPrefixOf, true, cr);
        // try to solve the equation
        cre = Expression.crefExp(cr);
        (es, {}) = ExpressionSolve.solve(lhs, rhs, cre);
        // constant or alias
      then
        constOrAliasArrayAcausal(vlst, ilst, es, eqnAttributes, inTpl);
    // {a1, a2, a3, ..} = ...

  end match;
end solveTimeIndependentAcausal1;

protected function constOrAliasArrayAcausal "author: Frenkel TUD 2012-12"
  input list<BackendDAE.Var> vars;
  input list<Integer> indxs;
  input DAE.Exp exp;
  input EquationSourceAndAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (vars, indxs, exp, eqnAttributes, inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      Integer i;
      list<Integer> ilst;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Subscript> subs;
      AccTuple tpl;
    case ({}, _, _, _, _) then inTpl;
    case ((v as BackendDAE.VAR(varName=cr))::vlst, i::ilst, _, _, _)
      equation
        subs = ComponentReference.crefLastSubs(cr);
        e = Expression.applyExpSubscripts(exp, subs);
        tpl = constOrAliasAcausal(v, i, cr, e, eqnAttributes, inTpl);
      then
        constOrAliasArrayAcausal(vlst, ilst, exp, eqnAttributes, tpl);
  end match;
end constOrAliasArrayAcausal;

protected function constOrAliasAcausal "author: Frenkel TUD 2012-12"
  input BackendDAE.Var var;
  input Integer i;
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  input EquationSourceAndAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (var, i, cr, exp, eqnAttributes, inTpl)
    local
      BackendDAE.Variables vars, globalKnownVars;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> eqns;
      list<SimpleContainer> seqns;
      Integer index;
      array<list<Integer>> mT;
      DAE.ComponentRef cra;
      list<BackendDAE.Var> vars2;
      list<Integer> ilst2;
      Boolean b, negated;
      list<Integer> colum;
      DAE.FunctionTree functions;
      DAE.Exp exp2;
    // alias a
    case (_, _, _, _, _, (vars, shared, eqns, seqns, index, mT, _))
      equation
        // alias
        (negated, cra) = aliasExp(exp);
        // get Variables
        globalKnownVars = BackendVariable.daeGlobalKnownVars(shared);
        (vars2, ilst2) = BackendVariable.getVar(cra, globalKnownVars);
        // add to Simple Equations List
        (seqns, index, mT) = generateSimpleContainters({var}, false, {i}, false, false, vars2, negated, ilst2, true, false, eqnAttributes, seqns, index, mT);
      then
         ((vars, shared, eqns, seqns, index, mT, true));
    // const
    case (_, _, _, _, _, (vars, shared, eqns, seqns, index, mT, _))
      guard
        Expression.isConstValue(exp)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Const Equation ", cr, " = ", exp, " found.\n");
        end if;
        colum = mT[i];
        arrayUpdate(mT, i, index::colum);
      then
        ((vars, shared, eqns, TIMEINDEPENTVAR(cr, i, exp, eqnAttributes, -1)::seqns, index+1, mT, true));

    case (_, _, _, _, _, (vars, shared as BackendDAE.SHARED(functionTree=functions), eqns, seqns, index, mT, _))
      guard
        not Expression.isImpure(exp) and not Expression.containsComplexCall(exp) // lochel: this is at least needed for impure functions
      equation
        //exp2 = Ceval.cevalSimpleWithFunctionTreeReturnExp(exp, functions);
        exp2 = EvaluateFunctions.evaluateConstantFunctionCallExp(exp, functions, false);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Const Equation (through Ceval, case 1) ", cr, " = ", exp, " found.\n");
        end if;
        colum = mT[i];
        arrayUpdate(mT, i, index::colum);
      then
        ((vars, shared, eqns, TIMEINDEPENTVAR(cr, i, exp2, eqnAttributes, -1)::seqns, index+1, mT, true));

      // TODO: Remove or fix this case. We do not want to add function calls here as they are inlined in a very bad way sometimes.
    case (_, _, _, _, _, (vars, shared, eqns, seqns, index, mT, _))
      guard
        not Expression.isImpure(exp) and not Expression.containsComplexCall(exp) // lochel: this is at least needed for impure functions
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Const Equation (through Ceval, case 2) ", cr, " = ", exp, " found.\n");
        end if;
        colum = mT[i];
        arrayUpdate(mT, i, index::colum);
      then ((vars, shared, eqns, TIMEINDEPENTVAR(cr, i, exp, eqnAttributes, -1)::seqns, index+1, mT, true));

  end matchcontinue;
end constOrAliasAcausal;

protected function aliasExp "author: Frenkel TUD 2011-04"
  input DAE.Exp exp;
  output Boolean negate;
  output DAE.ComponentRef outCr;
algorithm
  (negate, outCr) := match (exp)
    local DAE.ComponentRef cr;
    // alias a
    case (DAE.CREF(componentRef = cr)) then (false, cr);
    // alias -a
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = cr))) then (true, cr);
    // alias -a
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = cr))) then (true, cr);
    // alias not a
    case (DAE.LUNARY(DAE.NOT(_), DAE.CREF(componentRef = cr))) then (true, cr);
  end match;
end aliasExp;

protected function handleSets "author: Frenkel TUD 2012-12
  convert the found simple equtions to replacements and remove the simple
  variabes from the variables"
  input Integer containerIdx "downwards";
  input Integer inMark;
  input array<SimpleContainer> containerArr;
  input array<list<Integer>> iMT;
  input HashSet.HashSet unReplaceable;
  input output BackendDAE.Variables vars;
  input output list<BackendDAE.Equation> eqnslst;
  input output BackendDAE.Shared shared;
  input output BackendVarTransform.VariableReplacements repl;
  output Boolean warnAliasConflicts = false;
protected
  Option<tuple<Integer, Integer>> rmax, smax;
  Option<Integer> unremovable, const;
  Integer mark = inMark;
  Boolean b;
algorithm
  for idx in containerIdx:-1:1 loop
    if not intGt(getVisited(containerArr[idx]), 0) then
      // convert the found simple equtions to replacements and remove the simple
      // variabes from the variables

      // collect set
      //print("Check Simple Container "+dumpSimpleContainer(containerArr[idx])+"\n");
      (rmax, smax, unremovable, const, _) := getAlias({idx}, NONE(), mark, containerArr, iMT, vars, unReplaceable, false, {}, NONE(), NONE(), NONE(), NONE());
      // traverse set and add replacements, move vars, ...
      (vars, eqnslst, shared, repl, b) := handleSet(rmax, smax, unremovable, const, mark+1, containerArr, iMT, unReplaceable, vars, eqnslst, shared, repl);
      mark := mark+2;
      warnAliasConflicts := warnAliasConflicts or b;
    end if;
  end for;
end handleSets;

protected function getAlias "author: Frenkel TUD 2012-12
  traverse the simple tree to find the variable we keep"
  input list<Integer> rows; //{containerIdx}
  input Option<Integer> prevVar; //previous variable
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> containerArr;
  input array<list<Integer>> iMT;//[varIdx] = simpleContainer
  input BackendDAE.Variables vars;
  input HashSet.HashSet unReplaceable;
  input Boolean negate;
  input list<Integer> stack;
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer, Integer>> oRmax;
  output Option<tuple<Integer, Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax, oSmax, oUnremovable, oConst, oContinue) := match(rows, prevVar, mark, containerArr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      Integer r;
      list<Integer> rest;
      SimpleContainer container;
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      Boolean visited, cont;

    case ({}, _, _, _, _, _, _, _, _, _, _, _, _) then (iRmax, iSmax, iUnremovable, iConst, true);

    case (r::rest, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        container = containerArr[r];
        visited = isVisited(mark, container);
        (rmax, smax, unremovable, const, cont) = getAlias1(visited, container, r, rest, prevVar, mark, containerArr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst);
      then
        (rmax, smax, unremovable, const, cont);

  end match;
end getAlias;

protected function getAlias1 "author: Frenkel TUD 2012-12"
  input Boolean visited;
  input SimpleContainer containerIn;
  input Integer currIdx; //the container idx
  input list<Integer> rows;
  input Option<Integer> prevVar;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> containerArr;
  input array<list<Integer>> iMT;//[varIdx] = simpleContainer
  input BackendDAE.Variables vars;
  input HashSet.HashSet unReplaceable;
  input Boolean negate;
  input list<Integer> stack;
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer, Integer>> oRmax;
  output Option<tuple<Integer, Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax, oSmax, oUnremovable, oConst, oContinue) :=
  matchcontinue(visited, containerIn, currIdx, rows, prevVar, mark, containerArr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      Boolean cont;
      String msg;
      DAE.ComponentRef cr;

    case (false, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // set visited
        arrayUpdate(containerArr, currIdx, setVisited(mark, containerIn));
        // check alias connection
        (rmax, smax, unremovable, const, cont) = getAlias2(containerIn, currIdx, prevVar, mark, containerArr, iMT, vars, unReplaceable, negate, currIdx::stack, iRmax, iSmax, iUnremovable, iConst);
        // next arm
        if cont then
          (rmax, smax, unremovable, const, cont) = getAlias(rows, prevVar, mark, containerArr, iMT, vars, unReplaceable, negate, stack, rmax, smax, unremovable, const);
        end if;
      then
        (rmax, smax, unremovable, const, cont);

    // valid circular equality
    case (true, _, _, _, _, _, _, _, _, _, true, _, _, _, SOME(_), _)
      equation
        // is only valid for real or int
        ALIAS(cr1=cr) = containerArr[currIdx];
        true = Types.isIntegerOrRealOrSubTypeOfEither(ComponentReference.crefLastType(cr));
      then
        (NONE(), NONE(), NONE(), iUnremovable, false);

    case (true, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _)
      equation
        // is only valid for real or int
        ALIAS(cr1=cr) = containerArr[currIdx];
        true = Types.isIntegerOrRealOrSubTypeOfEither(ComponentReference.crefLastType(cr));
      then
        (NONE(), NONE(), NONE(), SOME(currIdx), false);

    case (true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        msg = "Circular Equalities Detected for Variables:\n";
        msg = circularEqualityMsg(stack, currIdx, containerArr, msg);
        // report error
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end getAlias1;

protected function circularEqualityMsg "author: Frenkel TUD 2013-05, adrpo"
  input list<Integer> stack;
  input Integer iR;
  input array<SimpleContainer> simpleeqnsarr;
  input String iMsg;
  output String oMsg;
protected
  list<String> lst;
  String msg;
algorithm
  lst := circularEqualityMsg_dispatch(stack, iR, simpleeqnsarr, {});
  msg := stringDelimitList(lst, "\n");
  msg := stringAppendList({iMsg, msg, "\n"});
  oMsg := msg;
end circularEqualityMsg;

protected function circularEqualityMsg_dispatch "author: Frenkel TUD 2013-05, adrpo"
  input list<Integer> stack;
  input Integer iR;
  input array<SimpleContainer> simpleeqnsarr;
  input list<String> iMsg;
  output list<String> oMsg;
algorithm
  oMsg := match(stack, iR, simpleeqnsarr, iMsg)
    local
      Integer r;
      list<Integer> rest;
      String msg;
      list<DAE.ComponentRef> names;
      list<String> slst;
    case ({}, _, _, _) then iMsg;
    case (r::_, _, _, _) guard intEq(r, iR) then iMsg;
    case (r::rest, _, _, _)
      equation
        names = getVarsNames(simpleeqnsarr[r]);
        slst = List.map(names, ComponentReference.printComponentRefStr);
        slst = listAppend(slst, {"----------------------------------"});
        slst = listAppend(iMsg, slst);
      then
        circularEqualityMsg_dispatch(rest, iR, simpleeqnsarr, slst);
  end match;
end circularEqualityMsg_dispatch;

protected function getVarsNames "author: Frenkel TUD 2013-05"
  input SimpleContainer iS;
  output list<DAE.ComponentRef> names;
algorithm
  names := match(iS)
    local
      DAE.ComponentRef cr1, cr2;
      Integer i1, i2;
      EquationSourceAndAttributes eqnAttributes;
      Boolean negate;
      DAE.Exp exp;
    case (ALIAS(cr1=cr1, cr2=cr2)) then {cr1, cr2};
    case (PARAMETERALIAS(unknowncr=cr1, paramcr=cr2)) then {cr1, cr2};
    case (TIMEALIAS(cr1=cr1,cr2=cr2)) equation  then {cr1, cr2};
    case (TIMEINDEPENTVAR(cr=cr1)) then {cr1};
  end match;
end getVarsNames;

protected function getAlias2 "author: Frenkel TUD 2012-12
is the container connected somehow?"
  input SimpleContainer containerIn;
  input Integer currIdx; //the container idx
  input Option<Integer> prevVar;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;//[varIdx] = simpleContainer
  input BackendDAE.Variables vars;
  input HashSet.HashSet unReplaceable;
  input Boolean negate; //do we negate negative aliases?
  input list<Integer> stack;
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  output Option<tuple<Integer, Integer>> oRmax;
  output Option<tuple<Integer, Integer>> oSmax;
  output Option<Integer> oUnremovable;
  output Option<Integer> oConst;
  output Boolean oContinue;
algorithm
  (oRmax, oSmax, oUnremovable, oConst, oContinue) :=
  match(containerIn, currIdx, prevVar, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      list<Integer> adjEqs;
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      BackendDAE.Var v;
      Integer i1, i2, i, prevVarIdx;
      Boolean state, replaceable_, cont, replaceble1, neg, negatedCr1, negatedCr2;

    case (ALIAS(i1=i1, negatedCr1=negatedCr1, i2=i2, negatedCr2=negatedCr2), _, NONE(), _, _, _, _, _, _, _, _, _, _, _)
      equation
        // collect next rows
        neg = boolOr(negatedCr1, negatedCr2);
        adjEqs = List.removeOnTrue(currIdx, intEq, iMT[i1]);
        v = BackendVariable.getVarAt(vars, i1);
        // update max
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
        state = BackendVariable.isStateVar(v) or BackendVariable.isClockedStateVar(v);
        (rmax, smax, unremovable) = getAlias3(v, i1, state, replaceable_ and replaceble1, currIdx, iRmax, iSmax, iUnremovable);
        // go deeper
        neg = if neg then not negate else negate;
        (rmax, smax, unremovable, const, cont) = getAlias(adjEqs, SOME(i1), mark, simpleeqnsarr, iMT, vars, unReplaceable, neg, stack, rmax, smax, unremovable, iConst);
        // collect next rows
        adjEqs = List.removeOnTrue(currIdx, intEq, iMT[i2]);
        v = BackendVariable.getVarAt(vars, i2);
        // update max
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
        state = BackendVariable.isStateVar(v) or BackendVariable.isClockedStateVar(v);
        (rmax, smax, unremovable) = getAlias3(v, i2, state, replaceable_ and replaceble1, currIdx, rmax, smax, unremovable);
        // go deeper
        if cont then
          (rmax, smax, unremovable, const, cont) = getAlias(adjEqs, SOME(i2), mark, simpleeqnsarr, iMT, vars, unReplaceable, neg, stack, rmax, smax, unremovable, const);
        end if;
       then
         (rmax, smax, unremovable, const, cont);

    case (ALIAS(i1=i1, negatedCr1=negatedCr1, i2=i2, negatedCr2=negatedCr2), _, SOME(prevVarIdx), _, _, _, _, _, _, _, _, _, _, _)
      equation
        i = if intEq(prevVarIdx, i1) then i2 else i1;
        neg = boolOr(negatedCr1, negatedCr2);
        // collect next rows
        adjEqs = List.removeOnTrue(currIdx, intEq, iMT[i]);
        v = BackendVariable.getVarAt(vars, i);
        // update max
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
        state = BackendVariable.isStateVar(v) or BackendVariable.isClockedStateVar(v);
        (rmax, smax, unremovable) = getAlias3(v, i, state, replaceable_ and replaceble1, currIdx, iRmax, iSmax, iUnremovable);
        // go deeper
        neg = if neg then not negate else negate;
        (rmax, smax, unremovable, const, cont) = getAlias(adjEqs, SOME(i), mark, simpleeqnsarr, iMT, vars, unReplaceable, neg, stack, rmax, smax, unremovable, iConst);
       then
         (rmax, smax, unremovable, const, cont);

    case (PARAMETERALIAS(), _, _, _, _, _, _, _, _, _, _, _, _, _)
       then
        (NONE(), NONE(), NONE(), SOME(currIdx), false);

    case (TIMEALIAS(), _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (NONE(), NONE(), NONE(), SOME(currIdx), false);

    case (TIMEINDEPENTVAR(), _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (NONE(), NONE(), NONE(), SOME(currIdx), false);

  end match;
end getAlias2;

protected function getAlias3 "
apply some heuristics which variable should be kept in the system. quantify some properties, distributes some points.
handle states differently
author: Frenkel TUD 2012-12"
  input BackendDAE.Var var;
  input Integer i;
  input Boolean state;
  input Boolean replaceable_;
  input Integer r;
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  output Option<tuple<Integer, Integer>> oRmax; //(idx,points)
  output Option<tuple<Integer, Integer>> oSmax;
  output Option<Integer> oUnremovable;
algorithm
  (oRmax, oSmax, oUnremovable) := match(var, i, state, replaceable_, r, iRmax, iSmax, iUnremovable)
    local
      Integer w1, w2;
      Option<tuple<Integer, Integer>> tpl;
    case(_, _, false, false, _, _, _, NONE())
      equation
        w1 = BackendVariable.calcAliasKey(var);
      then
        (SOME((i, w1)), iSmax, SOME(i));
    case(_, _, true, false, _, _, _, NONE())
      equation
        w1 = BackendVariable.varStateSelectPrioAlias(var);
      then
        (iRmax, SOME((i, w1)), SOME(i));
    case(_, _, true, _, _, _, NONE(), _)
      equation
        w1 = BackendVariable.varStateSelectPrioAlias(var);
      then
        (iRmax, SOME((i, w1)), iUnremovable);
    case(_, _, true, _, _, _, SOME((_, w2)), _)
      equation
        w1 = BackendVariable.varStateSelectPrioAlias(var);
        tpl = if intGt(w1, w2) then SOME((i, w1)) else iSmax;
      then
        (iRmax, tpl, iUnremovable);
    case(_, _, false, _, _, NONE(), _, _)
      equation
        w1 = BackendVariable.calcAliasKey(var);
      then
        (SOME((i, w1)), iSmax, iUnremovable);
    case(_, _, false, _, _, SOME((_, w2)), _, _)
      equation
        w1 = BackendVariable.calcAliasKey(var);
        tpl = if intLt(w1, w2) then SOME((i, w1)) else iRmax;
      then
        (tpl, iSmax, iUnremovable);
  end match;
end getAlias3;

protected function isVisited "author: Frenkel TUD 2012-12"
  input Integer mark; //how to mark a visited container
  input SimpleContainer iS;
  output Boolean visited;
algorithm
  visited := intEq(mark, getVisited(iS));
end isVisited;

protected function getVisited "author: Frenkel TUD 2012-12"
  input SimpleContainer iS;
  output Integer visited;
algorithm
  visited := match(iS)
    case ALIAS(visited=visited) then visited;
    case PARAMETERALIAS(visited=visited) then visited;
    case TIMEALIAS(visited=visited) then visited;
    case TIMEINDEPENTVAR(visited=visited) then visited;
  end match;
end getVisited;

protected function setVisited "author: Frenkel TUD 2012-12"
  input Integer visited;
  input SimpleContainer iS;
  output SimpleContainer oS;
algorithm
  oS := match(visited, iS)
    local
      DAE.ComponentRef cr1, cr2;
      Integer i1, i2;
      EquationSourceAndAttributes eqnAttributes;
      Boolean negatedCr1, negatedCr2;
      DAE.Exp exp;

    case (_, ALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, _))
      then ALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, visited);

    case (_, PARAMETERALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, _))
      then PARAMETERALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, visited);

    case (_, TIMEALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, _))
      then TIMEALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, visited);

    case (_, TIMEINDEPENTVAR(cr1, i1, exp, eqnAttributes, _))
      then TIMEINDEPENTVAR(cr1, i1, exp, eqnAttributes, visited);

  end match;
end setVisited;

protected function replaceableAlias "author Frenkel TUD 2012-11
  check if the variable is a replaceable_ alias."
  input BackendDAE.Var var;
  input HashSet.HashSet unReplaceable;
  output Boolean res;
  output Boolean res1 "true if not in unReplaceable Map";
algorithm
  (res, res1) := matchcontinue (var, unReplaceable)
    local
      BackendDAE.VarKind kind;
      DAE.ComponentRef cr;
      Boolean b;

    case (BackendDAE.VAR(varName=cr, varKind=kind), _) equation
      BackendVariable.isVarKindVariable(kind) "cr1 not constant";
      false = BackendVariable.isVarOnTopLevelAndOutput(var);
      false = BackendVariable.isVarOnTopLevelAndInput(var);
      false = BackendVariable.varHasUncertainValueRefine(var);
      cr = ComponentReference.crefStripLastSubs(cr);
      b = not BaseHashSet.has(cr, unReplaceable);
    then (true, b);

    else
    then (false, false);
  end matchcontinue;
end replaceableAlias;

protected function handleSet "author: Frenkel TUD 2012-12
  traverse an equations system to remove simple equations"
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input HashSet.HashSet unReplaceable;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
  output Boolean warnAliasConflicts = false;
algorithm
  (oVars, oEqnslst, oshared, oRepl):=
  matchcontinue (iRmax, iSmax, iUnremovable, iConst, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl)
    local
      SimpleContainer s;
      Integer r, i1, i2, i;
      BackendDAE.Var v,v1, pv;
      DAE.ComponentRef pcr, cr1, cr2, cr;
      EquationSourceAndAttributes eqnAttributes;
      Boolean negated, replaceable_, replaceble1, constExp, isState, negatedCr1, negatedCr2;
      DAE.Exp exp1, exp2, expcr, dexp, exp;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      VarSetAttributes vsattr;
      list<Integer> rows;
      Option<DAE.Exp> oexp;

   // constant alias set
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       // for parameter alias the second component reference is *ALWAYS* the parameter!
       PARAMETERALIAS(unknowncr=cr1, negatedCr1=negatedCr1, i1=i1, negatedCr2=negatedCr2, i2=i2, paramcr=cr2, eqnAttributes=eqnAttributes) = s;
       arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       negated = boolOr(negatedCr1, negatedCr2);
       // generate exp from cref an negate if necessary
       exp = Expression.crefExp(cr2);
       exp2 = negateExpression(negated, exp, exp, " PARAMETERALIAS ");
       v = BackendVariable.getVarAt(iVars, i1);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
       (vars, eqnslst, shared, repl) = handleSetVar(replaceable_ and replaceble1, SOME(DAE.RCONST(0.0)), v, i1, eqnAttributes, exp2, iMT, iVars, iEqnslst, ishared, iRepl);
       expcr = Expression.crefExp(cr1);
       pv = BackendVariable.getVarSharedAt(i2, ishared);
       vsattr = addVarSetAttributes(pv, negated, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       vsattr = if replaceable_ and replaceble1 then addVarSetAttributes(v, negated, mark, simpleeqnsarr, vsattr) else vsattr;
       rows = List.removeOnTrue(r, intEq, iMT[i1]);
       arrayUpdate(iMT, i1, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i1, exp, SOME(expcr), negated, SOME(DAE.RCONST(0.0)), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);

   // time set
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       // for time alias the time variable is *ALWAYS* the second
       TIMEALIAS(cr1=cr1, i1=i1, negatedCr1=negatedCr1, negatedCr2=negatedCr2, eqnAttributes=eqnAttributes) = s;
       arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       negated = boolOr(negatedCr1,negatedCr2);
       // generate exp from cref an negate if necessary
       exp = Expression.crefExp(DAE.crefTime);
       exp1 = negateExpression(negated, exp, exp, " timealias ");
       v = BackendVariable.getVarAt(iVars, i1);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
       dexp = negateExpression(negated, exp, DAE.RCONST(1.0), " timealias der ");
       (vars, eqnslst, shared, repl) = handleSetVar(replaceable_ and replaceble1, SOME(dexp), v, i1, eqnAttributes, exp1, iMT, iVars, iEqnslst, ishared, iRepl);
       expcr = Expression.crefExp(cr1);
       vsattr = addVarSetAttributes(v, negated, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       rows = List.removeOnTrue(r, intEq, iMT[i1]);
       arrayUpdate(iMT, i1, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i1, exp, SOME(expcr), negated, SOME(dexp), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);

   // constant set
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       TIMEINDEPENTVAR(cr=cr, i=i, exp=exp, eqnAttributes=eqnAttributes) = s;
       arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
       (vars, shared, isState, eqnslst) = optMoveVarShared(replaceable_, v, i, eqnAttributes, exp, BackendVariable.addGlobalKnownVarDAE, iMT, iVars, ishared, iEqnslst);
       constExp = Expression.isConstValue(exp);
       // add to replacements if constant
       repl = if replaceable_ and constExp and replaceble1 then BackendVarTransform.addReplacement(iRepl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator)) else iRepl;
       // if state der(var) has to replaced to 0
       repl = if isState then BackendVarTransform.addDerConstRepl(cr, DAE.RCONST(0.0), repl) else repl;
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       rows = List.removeOnTrue(r, intEq, iMT[i]);
       arrayUpdate(iMT, i, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i, exp, NONE(), false, SOME(DAE.RCONST(0.0)), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);

   // valid circular equality
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       ALIAS(i1=i, i2=i2, eqnAttributes=eqnAttributes) = s;
       arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = if Types.isRealOrSubTypeReal(ComponentReference.crefLastType(cr)) then DAE.RCONST(0.0) else DAE.ICONST(0);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
       (vars, shared, isState, eqnslst) = optMoveVarShared(replaceable_, v, i, eqnAttributes, exp, BackendVariable.addGlobalKnownVarDAE, iMT, iVars, ishared, iEqnslst);
       constExp = Expression.isConstValue(exp);
       // add to replacements if constant
       repl = if replaceable_ and constExp and replaceble1 then BackendVarTransform.addReplacement(iRepl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator)) else iRepl;
       // if state der(var) has to replaced to 0
       repl = if isState then BackendVarTransform.addDerConstRepl(cr, DAE.RCONST(0.0), repl) else repl;
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       rows = List.removeOnTrue(r, intEq, iMT[i2]);
       arrayUpdate(iMT, i2, rows);
       rows = List.removeOnTrue(r, intEq, iMT[i]);
       arrayUpdate(iMT, i, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i, exp, NONE(), false, SOME(DAE.RCONST(0.0)), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);

   // variable set state
   case (_, SOME((i, _)), _, NONE(), _, _, _, _, _, _, _, _)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       oexp = varStateDerivative(v);
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(iMT[i], i, exp, NONE(), false, oexp, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, vsattr);
       arrayUpdate(iMT, i, {});
       (vars, warnAliasConflicts) = handleVarSetAttributes(vsattr, v, vars, shared);
     then
       (vars, eqnslst, shared, repl);

   // variable set unReplaceable
   case (_, NONE(), SOME(i), NONE(), _, _, _, _, _, _, _, _)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(iMT[i], i, exp, NONE(), false, NONE(), mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, vsattr);
       arrayUpdate(iMT, i, {});
       (vars, warnAliasConflicts) = handleVarSetAttributes(vsattr, v, vars, shared);
     then
       (vars, eqnslst, shared, repl);

   // variable set
   case (SOME((i, _)), NONE(), _, NONE(), _, _, _, _, _, _, _, _)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(iMT[i], i, exp, NONE(), false, NONE(), mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, vsattr);
       arrayUpdate(iMT, i, {});
       (vars, warnAliasConflicts) = handleVarSetAttributes(vsattr, v, vars, shared);
     then
       (vars, eqnslst, shared, repl);

  end matchcontinue;
end handleSet;

protected function varStateDerivative "author: Frenkel TUD 2013-01"
  input BackendDAE.Var inVar;
  output Option<DAE.Exp> outExp;
algorithm
  outExp := match(inVar)
    local
      DAE.ComponentRef dcr;
      DAE.Exp e;
    case(BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr))))
      equation
        e = Expression.crefExp(dcr);
      then SOME(e);
    else NONE();
  end match;
end varStateDerivative;

protected function handleSetVar "author: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input Boolean replaceable_;
  input Option<DAE.Exp> derReplaceState;
  input BackendDAE.Var v;
  input Integer i;
  input EquationSourceAndAttributes eqnAttributes;
  input DAE.Exp exp;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oVars, oEqnslst, oshared, oRepl):=
  match (replaceable_, derReplaceState, v, i, eqnAttributes, exp, iMT, iVars, iEqnslst, ishared, iRepl)
    local
      DAE.ComponentRef cr;
      DAE.Exp crexp;
      BackendDAE.Variables vars;
      Boolean bs;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      DAE.ElementSource source;

   case (true, _, BackendDAE.VAR(varName=cr), _, (source, _), _, _, _, _, _, _)
     equation
       (vars, shared, bs) = moveVarShared(v, i, source, exp, BackendVariable.addAliasVarDAE, iVars, ishared);
       // add to replacements
       repl = BackendVarTransform.addReplacement(iRepl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
       // if state der(var) has to replaced
       repl = addDerConstRepl(bs, derReplaceState, cr, repl);
     then
       (vars, iEqnslst, shared, repl);

   case (false, _, BackendDAE.VAR(varName=cr), _, _, _, _, _, _, _, _)
     equation
       crexp = Expression.crefExp(cr);
       ((vars, shared, eqnslst, _, _, _, _)) = generateEquation(crexp, exp, Expression.typeof(exp), eqnAttributes, (iVars, ishared, iEqnslst, {}, -1, iMT, false));
     then
       (vars, eqnslst, shared, iRepl);

  end match;
end handleSetVar;

protected function addDerConstRepl "author: Frenkel TUD 2013-01"
  input Boolean state;
  input Option<DAE.Exp> derConstRepl;
  input DAE.ComponentRef cr;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  oRepl := match(state, derConstRepl, cr, iRepl)
    local DAE.Exp e;
    case(true, SOME(e), _, _) then BackendVarTransform.addDerConstRepl(cr, e, iRepl);
    else iRepl;
  end match;
end addDerConstRepl;

protected function optMoveVarShared "author: Frenkel TUD 2012-12"
  input Boolean replaceable_;
  input BackendDAE.Var v;
  input Integer i;
  input EquationSourceAndAttributes eqnAttributes;
  input DAE.Exp exp;
  input FuncMoveVarShared func;
  input array<list<Integer>> iMT;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input list<BackendDAE.Equation> iEqnslst;
  output BackendDAE.Variables oVars;
  output BackendDAE.Shared oshared;
  output Boolean bs;
  output list<BackendDAE.Equation> oEqnslst;
  partial function FuncMoveVarShared
    input BackendDAE.Var v;
    input BackendDAE.Shared ishared;
    output BackendDAE.Shared oshared;
  end FuncMoveVarShared;
algorithm
  (oVars, oshared, bs, oEqnslst) := match(replaceable_, v, i, eqnAttributes, exp, func, iMT, iVars, ishared, iEqnslst)
    local
      DAE.ComponentRef cr;
      DAE.Exp crexp;
      DAE.ElementSource source;

    case(true, _, _, (source, _), _, _, _, _, _, _)
      equation
        (oVars, oshared, bs) = moveVarShared(v, i, source, exp, func, iVars, ishared);
      then
        (oVars, oshared, bs, iEqnslst);

    case(false, BackendDAE.VAR(varName=cr), _, _, _, _, _, _, _, _)
     equation
       crexp = Expression.crefExp(cr);
       ((oVars, oshared, oEqnslst, _, _, _, _)) = generateEquation(crexp, exp, Expression.typeof(exp), eqnAttributes, (iVars, ishared, iEqnslst, {}, -1, iMT, false));
     then
       (oVars, oshared, false, oEqnslst);

  end match;
end optMoveVarShared;

protected function moveVarShared "author: Frenkel TUD 2012-12"
  input BackendDAE.Var v;
  input Integer i;
  input DAE.ElementSource source;
  input DAE.Exp exp;
  input FuncMoveVarShared func;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables oVars;
  output BackendDAE.Shared oshared;
  output Boolean bs;
  partial function FuncMoveVarShared
    input BackendDAE.Var v;
    input BackendDAE.Shared ishared;
    output BackendDAE.Shared oshared;
  end FuncMoveVarShared;
protected
  DAE.ComponentRef cr;
  list<DAE.SymbolicOperation> ops;
  BackendDAE.Var v1;
algorithm
  BackendDAE.VAR(varName=cr) := v;
  // add bindExp
  v1 := BackendVariable.setBindExp(v, SOME(exp));
  ops := ElementSource.getSymbolicTransformations(source);
  v1 := BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr, exp)::ops);
  // State?
  bs := BackendVariable.isStateVar(v);
  v1 := if bs then BackendVariable.setVarKind(v1, BackendDAE.DUMMY_STATE()) else v1;
  // remove from vars
  (oVars, _) := BackendVariable.removeVar(i, iVars);
  // store changed var
  oshared := func(v1, ishared);
end moveVarShared;

protected function traverseAliasTree "author: Frenkel TUD 2012-12
  traverse an equations system to remove simple equations"
  input list<Integer> rows;
  input Integer ilast;
  input DAE.Exp exp;
  input Option<DAE.Exp> optExp;
  input Boolean globalnegate;
  input Option<DAE.Exp> derReplaceState;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input HashSet.HashSet unReplaceable;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input VarSetAttributes iAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
  output VarSetAttributes oAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
algorithm
 (oVars, oEqnslst, oshared, oRepl, oAttributes):=
  match (rows, ilast, exp, optExp, globalnegate, derReplaceState, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, iAttributes)
    local
      Integer r;
      list<Integer> rest;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      SimpleContainer s;
      VarSetAttributes vsattr;

    case ({}, _, _, _, _, _, _, _, _, _, _, _, _, _, _) then (iVars, iEqnslst, ishared, iRepl, iAttributes);
    case (r::rest, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        s = simpleeqnsarr[r];
        arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
        (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree1(s, r, ilast, exp, optExp, globalnegate, derReplaceState, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, iAttributes);
        (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rest, ilast, exp, optExp, globalnegate, derReplaceState, mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
      then
        (vars, eqnslst, shared, repl, vsattr);

  end match;
end traverseAliasTree;

protected function traverseAliasTree1 "author: Frenkel TUD 2012-12
  traverse an equations system to remove simple equations"
  input SimpleContainer sc;
  input Integer r;
  input Integer ilast;
  input DAE.Exp exp;
  input Option<DAE.Exp> optExp;
  input Boolean globalnegated;
  input Option<DAE.Exp> derReplaceState;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input HashSet.HashSet unReplaceable;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input VarSetAttributes iAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
  output VarSetAttributes oAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
algorithm
 (oVars, oEqnslst, oshared, oRepl, oAttributes):=
  match (sc, r, ilast, exp, optExp, globalnegated, derReplaceState, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, iAttributes)
    local
      Integer i1, i2, i;
      list<Integer> rows;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cr, cr1, cr2;
      Boolean replaceable_, globalnegated1, replaceble1, negatedCr1, negatedCr2, negated;
      DAE.ElementSource source;
      DAE.Exp crexp, exp1;
      Option<DAE.Exp> dexp, derReplacement;
      String lhs,rhs;
      VarSetAttributes vsattr;
      BackendDAE.EquationAttributes eqAttr;

    case (ALIAS(_, negatedCr1, i1, _, negatedCr2, i2, (source, eqAttr), _), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        i = if intEq(i1, ilast) then i2 else i1;
        negated = boolOr(negatedCr2, negatedCr1);
        (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable); // (isreplaceable, isNotInUnreplaceblaHashMap)
        crexp = Expression.crefExp(cr);
        // negate if necessary
        globalnegated1 = if negated then not globalnegated else globalnegated;
        exp1 = negateExpression(globalnegated1, exp, exp, " ALIAS_1 ");
        derReplacement = if globalnegated1 then negateOptExp(derReplaceState) else derReplaceState;
        // replace alias with selected variable if replaceable_
        source = if replaceable_ then addSubstitutionOption(optExp, crexp, source) else source;
        (vars, eqnslst, shared, repl) = handleSetVar(replaceable_ and replaceble1, derReplacement, v, i, (source, eqAttr), exp1, iMT, iVars, iEqnslst, ishared, iRepl);
        vsattr = if replaceable_ and replaceble1 then addVarSetAttributes(v, globalnegated1, mark, simpleeqnsarr, iAttributes) else iAttributes;
        // negate if necessary
        crexp = negateExpression(negated, crexp, crexp, " ALIAS_2 ");
        rows = List.removeOnTrue(r, intEq, iMT[i]);
        arrayUpdate(iMT, i, {});
        (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i, exp, SOME(crexp), globalnegated1, derReplaceState, mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
      then
        (vars, eqnslst, shared, repl, vsattr);

    case (PARAMETERALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, _, (source, _), _), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // report error
        cr = if intEq(i1, ilast) then cr2 else cr1;
        negated = boolOr(negatedCr1, negatedCr2);
        crexp = Expression.crefExp(cr);
        crexp = negateExpression(negated, crexp, crexp, " PARAMETERLAIAS ");
        lhs = ExpressionDump.printExpStr(exp);
        rhs = ExpressionDump.printExpStr(crexp);
        Error.addSourceMessage(Error.EQ_WITHOUT_TIME_DEP_VARS, {lhs, rhs}, ElementSource.getElementSourceFileInfo(source));
      then
        fail();

    case (TIMEALIAS(eqnAttributes=(source,_)), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // report error
        rhs = ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.EQ_WITHOUT_TIME_DEP_VARS, {"time", rhs}, ElementSource.getElementSourceFileInfo(source));
      then
        fail();

    case (TIMEINDEPENTVAR(exp=exp1, eqnAttributes=(source,_)), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // report error
        lhs = ExpressionDump.printExpStr(exp);
        rhs = ExpressionDump.printExpStr(exp1);
        Error.addSourceMessage(Error.EQ_WITHOUT_TIME_DEP_VARS, {lhs, rhs}, ElementSource.getElementSourceFileInfo(source));
      then
        fail();

  end match;
end traverseAliasTree1;

protected function negateOptExp "author: Frenkel TUD 2012-12"
  input Option<DAE.Exp> iExp;
  output Option<DAE.Exp> oExp;
algorithm
  oExp := match(iExp)
    local DAE.Exp e;
      case(SOME(e))
        equation
          e = negateExpression(true, e, e, " in negateOptExp ");
        then SOME(e);
      else iExp;
  end match;
end negateOptExp;

protected function addSubstitutionOption "author: Frenkel TUD 2012-12"
 input Option<DAE.Exp> optExp;
 input DAE.Exp exp;
 input output DAE.ElementSource source;
protected
  DAE.Exp e;
algorithm
  if isSome(optExp) then
    SOME(e) := optExp;
    source := ElementSource.addSymbolicTransformationSubstitution(true, source, exp, e);
  end if;
end addSubstitutionOption;

protected function addVarSetAttributes "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input VarSetAttributes iAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
  output VarSetAttributes oAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
protected
  Boolean fixed, fixedset;
  Option<DAE.Exp> start, origin;
  list<tuple<DAE.Exp, DAE.ComponentRef>> nominalset;
  tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmaxset;
  tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> startvalues;
algorithm
  (fixedset, startvalues, nominalset, minmaxset) := iAttributes;
  // get attributes
  // fixed
  fixed := BackendVariable.varFixed(inVar);
  // start, add only if fixed == fixedset or fixed
  start := BackendVariable.varStartValueOption(inVar);
  origin := BackendVariable.varStartOrigin(inVar);
  (fixedset, startvalues) := addStartValue(fixed, fixedset, BackendVariable.varCref(inVar), start, origin, negate, mark, simpleeqnsarr, startvalues);
  // nominal
  (nominalset) := addNominalValue(inVar, nominalset);
  // minmax
  minmaxset := addMinMaxAttribute(inVar, negate, mark, simpleeqnsarr, minmaxset);
  oAttributes := (fixedset, startvalues, nominalset, minmaxset);
end addVarSetAttributes;

protected function addStartValue "author: Frenkel TUD 2012-12"
  input Boolean fixed;
  input Boolean fixedset;
  input DAE.ComponentRef cr;
  input Option<DAE.Exp> start;
  input Option<DAE.Exp> origin;
  input Boolean negate;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> iStartvalues;
  output Boolean oFixed;
  output  tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> oStartvalues;
algorithm
  (oFixed, oStartvalues) := matchcontinue(fixed, fixedset, cr, start, origin, negate, mark, simpleeqnsarr, iStartvalues)
    local
      DAE.Exp startexp;
      Integer setorigin, originvalue;
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> startvalues, startvalues1;
      Boolean b, b1;
    case (false, true, _, _, _, _, _, _, _) then (fixedset, iStartvalues);
    case (true, false, _, NONE(), _, _, _, _, _)
      equation
        originvalue = BackendVariable.startOriginToValue(origin);
      then
        (true, (originvalue, {(start, cr)}));
    case (true, false, _, SOME(startexp), _, _, _, _, _)
      equation
        startexp = negateExpression(negate, startexp, startexp, " start_1 ");
        originvalue = BackendVariable.startOriginToValue(origin);
      then
        (true, (originvalue, {(SOME(startexp), cr)}));
    case (_, _, _, NONE(), _, _, _, _, (setorigin, startvalues))
      equation
        originvalue = BackendVariable.startOriginToValue(origin);
        b = intGt(originvalue, setorigin);
        b1 = intEq(originvalue, setorigin);
        startvalues = List.consOnTrue(b1 and fixed, (start, cr), startvalues);
        startvalues1 = if fixed then {(start, cr)} else {};
        ((setorigin, startvalues)) = if b then (originvalue, startvalues1) else ((setorigin, startvalues));
      then
        (fixedset, (setorigin, startvalues));
    case (_, _, _, SOME(startexp), _, _, _, _, (setorigin, startvalues))
      equation
        startexp = negateExpression(negate, startexp, startexp, " start_2 ");
        originvalue = BackendVariable.startOriginToValue(origin);
        b = intGt(originvalue, setorigin);
        b1 = intEq(originvalue, setorigin);
        startvalues = List.consOnTrue(b1, (SOME(startexp), cr), startvalues);
        ((setorigin, startvalues)) = if b then (originvalue, {(SOME(startexp), cr)}) else ((setorigin, startvalues));
      then
        (fixedset, (setorigin, startvalues));
    else
      equation
        print("RemoveSimpleEquations.addStartValue failed!\n");
      then
        fail();
  end matchcontinue;
end addStartValue;

protected function mergeStartFixedAttributes "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean fixed;
  input tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> startvalues;
  input BackendDAE.Shared ishared;
  output BackendDAE.Var outVar;
  output Boolean warnAliasConflicts = false;
algorithm
  outVar := matchcontinue(inVar, fixed, startvalues, ishared)
    local
      DAE.ComponentRef cr;
      Option<DAE.Exp> start, start1;
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> values;
      list<tuple<DAE.Exp, DAE.ComponentRef>> zerofreevalues;
      BackendDAE.Var v;
      BackendDAE.Variables globalKnownVars;

    // default value
    case (_, _, (_, {}), _) then inVar;

    // fixed true only one start value -> nothing changed
    case (_, true, (_, {(start, _)}), _) equation
      v = BackendVariable.setVarFixed(inVar, true);
    then BackendVariable.setVarStartValueOption(v, start);

    // fixed true several start values, this need some investigation
    case (_, true, (_, (start, cr)::values), BackendDAE.SHARED(globalKnownVars=globalKnownVars)) equation
      v = BackendVariable.setVarFixed(inVar, true);
      start1 = optExpReplaceCrefWithBindExp(start, globalKnownVars);
      ((_, start, _)) = equalNonFreeStartValues(values, globalKnownVars, (start1, start, cr));
    then BackendVariable.setVarStartValueOption(v, start);

    case (_, true, (_, values), BackendDAE.SHARED(globalKnownVars=globalKnownVars)) equation
      v = BackendVariable.setVarFixed(inVar, true);
      // get all nonzero values
      zerofreevalues = List.fold(values, getZeroFreeValues, {});
      warnAliasConflicts = not Flags.isSet(Flags.ALIAS_CONFLICTS);
    then selectFreeValue1(zerofreevalues, {}, "Fixed Alias set with conflicting start values\n", "start", BackendVariable.setVarStartValue, v, globalKnownVars);

    // fixed false only one start value -> nothing changed
    case (_, false, (_, {(start, _)}), _)
    then BackendVariable.setVarStartValueOption(inVar, start);

    // fixed false several start value, this need some investigation
    case (_, false, (_, (start, cr)::values), BackendDAE.SHARED(globalKnownVars=globalKnownVars)) equation
      start1 = optExpReplaceCrefWithBindExp(start, globalKnownVars);
      ((_, start, _)) = equalFreeStartValues(values, globalKnownVars, (start1, start, cr));
    then BackendVariable.setVarStartValueOption(inVar, start);

    case (_, false, (_, values), BackendDAE.SHARED(globalKnownVars=globalKnownVars)) equation
      // get all nonzero values
      zerofreevalues = List.fold(values, getZeroFreeValues, {});
      (v, warnAliasConflicts) = selectFreeValue(zerofreevalues, inVar, globalKnownVars);
    then v;
  end matchcontinue;
end mergeStartFixedAttributes;

protected function addNominalValue
  input BackendDAE.Var inVar;
  input list<tuple<DAE.Exp, DAE.ComponentRef>> iNominal;
  output list<tuple<DAE.Exp, DAE.ComponentRef>> oNominal;
protected
  DAE.Exp nominal;
  DAE.ComponentRef cr;
algorithm
  try
    nominal := BackendVariable.varNominalValue(inVar);
    cr := BackendVariable.varCref(inVar);
    oNominal := (nominal, cr)::iNominal;
  else
    oNominal := iNominal;
  end try;
end addNominalValue;

protected function mergeNominalAttribute
  input list<tuple<DAE.Exp, DAE.ComponentRef>> nominalList;
  input BackendDAE.Var inVar;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Var outVar;
  output Boolean warnAliasConflicts = false;
algorithm
  outVar := matchcontinue (nominalList, inVar)
    local
      DAE.Exp e;
      list<DAE.Exp> allExp;

    case ({}, _) then inVar;

    //check if all expressions are equal take just one
    case (_, _)
      equation
        allExp = List.map(nominalList, Util.tuple21);
        {e} = List.uniqueOnTrue(allExp, Expression.expEqual);
      then BackendVariable.setVarNominalValue(inVar, e);

    else
      equation
        warnAliasConflicts = not Flags.isSet(Flags.ALIAS_CONFLICTS);
      then selectFreeValue1(nominalList, {}, "Alias set with conflicting nominal values\n", "nominal", BackendVariable.setVarNominalValue, inVar, globalKnownVars);
  end matchcontinue;
end mergeNominalAttribute;

protected function addMinMaxAttribute "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> iMinMax;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> oMinMax;
protected
  Option<DAE.VariableAttributes> attr;
  list<Option<DAE.Exp>> ominmax;
algorithm
  BackendDAE.VAR(values = attr) := inVar;
  ominmax := DAEUtil.getMinMax(attr);
  oMinMax := mergeMinMax(negate, ominmax, iMinMax, mark, simpleeqnsarr);
end addMinMaxAttribute;

protected function mergeMinMax "author: Frenkel TUD 2012-12"
  input Boolean negate;
  input list<Option<DAE.Exp>> ominmax;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> ominmax1;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> outMinMax;
algorithm
  outMinMax :=
  match (negate, ominmax, ominmax1, mark, simpleeqnsarr)
    local
      DAE.Exp min, max, min1, max1;
      Option<DAE.Exp> omin, omax;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
    case (_, {}, _, _, _)
      then
        ominmax1;
    case (false, {omin, omax}, _, _, _)
      equation
        minMax = mergeMinMax1((omin, omax), ominmax1);
        checkMinMax(minMax, mark, simpleeqnsarr);
      then
        minMax;
    // in case of a=-b, min and max have to be changed and negated
    case (true, {NONE(), NONE()}, _, _, _)
      then
        ominmax1;
    case (true, {SOME(min), SOME(max)}, _, _, _)
      equation
        min1 = negateExpression(true, min, min, " min_1 ");
        max1 = negateExpression(true, max, max, " max_1 ");
        minMax = mergeMinMax1((SOME(max1), SOME(min1)), ominmax1);
        checkMinMax(minMax, mark, simpleeqnsarr);
      then
        minMax;
    case (true, {NONE(), SOME(max)}, _, _, _)
      equation
        max1 = negateExpression(true, max, max, " max_2 ");
        minMax = mergeMinMax1((SOME(max1), NONE()), ominmax1);
        checkMinMax(minMax, mark, simpleeqnsarr);
      then
        minMax;
    case (true, {SOME(min), NONE()}, _, _, _)
      equation
        min1 = negateExpression(true, min, min, " min_2 ");
        minMax = mergeMinMax1((NONE(), SOME(min1)), ominmax1);
        checkMinMax(minMax, mark, simpleeqnsarr);
      then
        minMax;
    else
      equation
        print("RemoveSimpleEquations.mergeMinMax failed!\n");
      then
        fail();
  end match;
end mergeMinMax;

protected function mergeMinMax1 "author: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> ominmax;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> ominmax1;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
protected
  Option<DAE.Exp> omin, omin1, omin2;
  Option<DAE.Exp> omax, omax1, omax2;
algorithm
  (omin, omax) := ominmax;
  (omin1, omax1) := ominmax1;

  omin2 := Expression.expOptMaxScalar(omin, omin1);
  omax2 := Expression.expOptMinScalar(omax, omax1);
  if referenceEq(omin2,omin) and referenceEq(omax2, omax) then
    minMax := ominmax;
  elseif referenceEq(omin2,omin1) and referenceEq(omax2, omax1) then
    minMax := ominmax1;
  else
    minMax := (omin2, omax2);
  end if;
end mergeMinMax1;

protected function checkMinMax "author: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmax;
  input Integer mark; //how to mark a visited container
  input array<SimpleContainer> simpleeqnsarr;
algorithm
  _ :=
  matchcontinue (minmax, mark, simpleeqnsarr)
    local
      DAE.Exp min, max;
      String s, s4, s5;
      Real rmin, rmax;
    case ((SOME(min), SOME(max)), _, _)
      equation
        rmin = Expression.toReal(min);
        rmax = Expression.toReal(max);
        true = realGt(rmin, rmax);
        s4 = ExpressionDump.printExpStr(min);
        s5 = ExpressionDump.printExpStr(max);
        s = stringAppendList({"Alias variables with invalid limits min ", s4, " > max ", s5});
        Error.addMessage(Error.COMPILER_WARNING, {s});
      then ();
    // no error
    else
      ();
  end matchcontinue;
end checkMinMax;

protected function handleVarSetAttributes "author: Frenkel TUD 2012-12"
  input VarSetAttributes inAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared inShared;
  output BackendDAE.Variables outVars;
  output Boolean warnAliasConflicts = false;
algorithm
  outVars := matchcontinue(inAttributes, inVar, inVars, inShared)
    local
      Boolean fixedset, isdiscrete, b1=false, b2=false;
      list<tuple<DAE.Exp, DAE.ComponentRef>> nominalset;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmaxset;
      tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> startvalues;
      BackendDAE.Var v = inVar;
      BackendDAE.Variables vars, globalKnownVars;
      Option<DAE.Exp> min, max;

    case((fixedset, startvalues, nominalset, minmaxset), _, _, BackendDAE.SHARED(globalKnownVars=globalKnownVars)) equation
      isdiscrete = BackendVariable.isVarDiscrete(inVar);

      // start and fixed
      if not isdiscrete then
        (v, b1) = mergeStartFixedAttributes(inVar, fixedset, startvalues, inShared);
      end if;
      // nominal
      (v, b2) = mergeNominalAttribute(nominalset, v, globalKnownVars);
      // min max
      (min, max) = minmaxset;
      v = BackendVariable.setVarMinMax(v, min, max);

      // update vars
      vars = BackendVariable.addVar(v, inVars);
      warnAliasConflicts = b1 or b2;
    then vars;

    else equation
      print("RemoveSimpleEquations.handleVarSetAttributes failed!\n");
    then fail();
  end matchcontinue;
end handleVarSetAttributes;

protected function optExpReplaceCrefWithBindExp "author: Frenkel TUD 2012-12"
  input Option<DAE.Exp> iOExp;
  input BackendDAE.Variables globalKnownVars;
  output Option<DAE.Exp> oOExp;
algorithm
  oOExp := match(iOExp, globalKnownVars)
    local
      DAE.Exp e;
      Boolean b;
    case(SOME(e), _)
      equation
        (e, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e, _) = ExpressionSimplify.condsimplify(b, e);
      then
        SOME(e);
    else iOExp;
 end match;
end optExpReplaceCrefWithBindExp;

protected function equalNonFreeStartValues "author: Frenkel TUD 2012-12"
  input list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> iValues;
  input BackendDAE.Variables globalKnownVars;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> iValue;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> oValue;
algorithm
  oValue := match(iValues, globalKnownVars, iValue)
    local
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> values;
      DAE.Exp e, e1, e2;
      Boolean b;
      DAE.ComponentRef cr;
    case ({}, _, _) then iValue;
    case (((NONE(), _))::values, _, _)
      then
        equalNonFreeStartValues(values, globalKnownVars, iValue);
    case (((NONE(), _))::values, _, (NONE(), _, _))
      then
        equalNonFreeStartValues(values, globalKnownVars, iValue);
    case (((NONE(), cr))::values, _, (SOME(e2), _, _))
      guard
        Expression.isZero(e2)
      then
        equalNonFreeStartValues(values, globalKnownVars, (NONE(), NONE(), cr));
    case (((SOME(e), _))::values, _, (SOME(e2), _, _))
      equation
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        true = Expression.expEqual(e1, e2);
      then
        equalNonFreeStartValues(values, globalKnownVars, iValue);
  end match;
end equalNonFreeStartValues;

protected function equalFreeStartValues "author: Frenkel TUD 2012-12"
  input list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> iValues;
  input BackendDAE.Variables globalKnownVars;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> iValue;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> oValue;
algorithm
  oValue := match(iValues, globalKnownVars, iValue)
    local
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> values;
      DAE.Exp e, e1, e2;
      Boolean b;
      DAE.ComponentRef cr;
    case ({}, _, _) then iValue;
    // ignore default values
    case (((NONE(), _))::values, _, _)
      then
        equalFreeStartValues(values, globalKnownVars, iValue);
    case (((SOME(e), cr))::values, _, (NONE(), _, _))
      equation
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
      then
        equalFreeStartValues(values, globalKnownVars, (SOME(e1), SOME(e), cr));
    // compare
    case (((SOME(e), _))::values, _, (SOME(e2), _, _))
      equation
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        true = Expression.expEqual(e1, e2);
      then
        equalFreeStartValues(values, globalKnownVars, iValue);
  end match;
end equalFreeStartValues;

protected function replaceCrefWithBindExp "author: Frenkel TUD 2012-12"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, Boolean, HashSet.HashSet> inTuple;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, Boolean, HashSet.HashSet> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp,inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case (DAE.CREF(componentRef=cr), (vars, _, hs))
      guard
        // check for cyclic bindings in start value
        not BaseHashSet.has(cr, hs)
      equation
        (BackendDAE.VAR(bindExp = SOME(e)), _) = BackendVariable.getVarSingle(cr, vars);
        hs = BaseHashSet.add(cr, hs);
        (e, (_, _, hs)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (vars, false, hs));
      then
        (e, (vars, true, hs));
    // true if crefs in expression
    case (e as DAE.CREF(), (_, true, _))
      then
        (e, inTuple);
    case (e as DAE.CREF(), (vars, _, hs))
      then
        (e, (vars, true, hs));
    else (inExp,inTuple);
  end matchcontinue;
end replaceCrefWithBindExp;

protected function getZeroFreeValues "author: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>, DAE.ComponentRef> inTpl;
  input list<tuple<DAE.Exp, DAE.ComponentRef>> iAcc;
  output list<tuple<DAE.Exp, DAE.ComponentRef>> oAcc;
algorithm
  oAcc := match(inTpl, iAcc)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
    case ((SOME(e), cr), _) then (e, cr)::iAcc;
    else iAcc;
  end match;
end getZeroFreeValues;

protected function selectFreeValue "author: Frenkel TUD 2012-12"
  input list<tuple<DAE.Exp, DAE.ComponentRef>> iZeroFreeValues;
  input BackendDAE.Var inVar;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Var outVar;
  output Boolean warnAliasConflicts = false;
algorithm
  outVar := match(iZeroFreeValues, inVar)
    case ({}, _) then inVar;
    case (_, _)
      equation
        warnAliasConflicts = not Flags.isSet(Flags.ALIAS_CONFLICTS);
      then selectFreeValue1(iZeroFreeValues, {}, "Alias set with conflicting start values\n", "start", BackendVariable.setVarStartValue, inVar, globalKnownVars);
  end match;
end selectFreeValue;

protected function selectNonZeroExpression
"adrpo: select one that is non zero if possible"
  input list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> iFavorit;
  output tuple<DAE.Exp, DAE.ComponentRef, Integer> selected;
algorithm
  selected := match(iFavorit)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Integer i;
      list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> rest;

    case ({(e, cr, i)}) then ((e, cr, i));

    case ((e, cr, i)::_) guard not Expression.isZero(e) then ((e, cr, i));

    case ((_, _, _)::rest)
      then
        selectNonZeroExpression(rest);
  end match;
end selectNonZeroExpression;

protected function selectFreeValue1 "author: Frenkel TUD 2012-12
  adrpo: the value is selected as follows:
  - if the exp is a cref with less depth
  - for the ones with the minimum depth equal, select one that is non-zero"
  input list<tuple<DAE.Exp, DAE.ComponentRef>> iZeroFreeValues;
  input list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> iFavorit;
  input String iStr;
  input String iAttributeName;
  input FuncSetAttribute inFunc;
  input BackendDAE.Var inVar;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Var outVar;
  partial function FuncSetAttribute
    input BackendDAE.Var iVar;
    input DAE.Exp iExp;
    output BackendDAE.Var oVar;
  end FuncSetAttribute;
algorithm
  outVar := matchcontinue(iZeroFreeValues, iFavorit, iStr, iAttributeName, inFunc, inVar)
    local
      DAE.Exp e, e1, es;
      DAE.ComponentRef cr, crs, crVar;
      BackendDAE.Var v;
      list<tuple<DAE.Exp, DAE.ComponentRef>> zerofreevalues;
      Integer i, is;
      list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> favorit;
      list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> rest;
      String s="", s2;
      Boolean b, hardcoded;

    case ({}, {}, _, _, _, _) then inVar;

    // end of list analyse what we got
    case ({}, rest, _, _, _, _) equation
      ((e, cr, _)) = selectNonZeroExpression(rest);
      crVar = BackendVariable.varCref(inVar);
      if Flags.isSet(Flags.ALIAS_CONFLICTS) then
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        s2 = if b then " = " + ExpressionDump.printExpStr(e1) else "";
        s = iStr + "=> Select value from " +  ComponentReference.printComponentRefStr(cr) +  "(" + iAttributeName + " = " + ExpressionDump.printExpStr(e) + s2 + ") for variable: " +  ComponentReference.printComponentRefStr(crVar) + "\n";
        Error.addMessage(Error.COMPILER_WARNING, {s});
      end if;
      v = inFunc(inVar, e);
    then v;

    // none, push it in
    case ((e, cr)::zerofreevalues, {}, _, _, _, _) equation
      (_, (i, hardcoded)) = Expression.traverseExpTopDown(e, selectMinDepth, (ComponentReference.crefDepth(cr), true));
      if hardcoded then
        i = i + 5;
      end if;
      if Flags.isSet(Flags.ALIAS_CONFLICTS) then
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        s2 = if b then " = " + ExpressionDump.printExpStr(e1) else "";
        s = iStr + " * Candidate: " + ComponentReference.printComponentRefStr(cr) + "(" + iAttributeName + " = " + ExpressionDump.printExpStr(e) + s2 + ", confidence number = " + intString(i) + ")\n";
      end if;
    then selectFreeValue1(zerofreevalues, {(e, cr, i)}, s, iAttributeName, inFunc, inVar, globalKnownVars);

    // equal, put it in
    case ((e, cr)::zerofreevalues, (es, crs, is)::rest, _, _, _, _) equation
      (_, (i, hardcoded)) = Expression.traverseExpTopDown(e, selectMinDepth, (ComponentReference.crefDepth(cr), true));
      if hardcoded then
        i = i + 5;
      end if;
      if Flags.isSet(Flags.ALIAS_CONFLICTS) then
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        s2 = if b then " = " + ExpressionDump.printExpStr(e1) else "";
        s = iStr + " * Candidate: " + ComponentReference.printComponentRefStr(cr) + "(" + iAttributeName + " = " + ExpressionDump.printExpStr(e) + s2 + ", confidence number = " + intString(i) + ")\n";
      end if;
      true = intEq(i, is);
      crVar = BackendVariable.varCref(inVar);
      favorit = if ComponentReference.crefEqual(crVar, crs) then {(es, crs, is), (e, cr, i)} else {(e, cr, i), (es, crs, is)};
      favorit = listAppend(favorit,rest);
    then selectFreeValue1(zerofreevalues, favorit, s, iAttributeName, inFunc, inVar, globalKnownVars);

    // less than, remove all from list, return just this one
    case ((e, cr)::zerofreevalues, (es, crs, is)::_, _, _, _, _) equation
      (_, (i, hardcoded)) = Expression.traverseExpTopDown(e, selectMinDepth, (ComponentReference.crefDepth(cr), true));
      if hardcoded then
        i = i + 5;
      end if;
      if Flags.isSet(Flags.ALIAS_CONFLICTS) then
        (e1, (_, b, _)) = Expression.traverseExpBottomUp(e, replaceCrefWithBindExp, (globalKnownVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        s2 = if b then " = " + ExpressionDump.printExpStr(e1) else "";
        s = iStr + " * Candidate: " + ComponentReference.printComponentRefStr(cr) + "(" + iAttributeName + " = " + ExpressionDump.printExpStr(e) + s2 + ", confidence number = " + intString(i) + ")\n";
      end if;
      favorit = if intLt(i, is) then {(e, cr, i)} else iFavorit;
    then selectFreeValue1(zerofreevalues, favorit, s, iAttributeName, inFunc, inVar, globalKnownVars);
  end matchcontinue;
end selectFreeValue1;

protected function selectMinDepth "author: adrpo
  if the start expression is a cref
  with less depth than the one given
  return the minimum depth between the
  two. Maybe we should o min of all the
  cref in the expression! - ptaeuber: Now we do."
  input DAE.Exp e;
  input tuple<Integer, Boolean> inMin;
  output DAE.Exp eOut=e;
  output Boolean cont=true;
  output tuple<Integer, Boolean> outMin;
algorithm
  outMin := match(e, inMin)
    local
      Integer i,d;
      DAE.ComponentRef cr;

    case (DAE.CREF(cr, _), (d, _)) equation
      i = ComponentReference.crefDepth(cr);
    then (intMin(i, d), false);

    else inMin;
  end match;
end selectMinDepth;


// =============================================================================
// functions to update equation system and shared
//
// =============================================================================

protected function updateSystem "author: Frenkel TUD 2012-12
  replace the simplified variables and equations in the system"
  input Boolean foundSimple;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Variables iVars;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst:=
  match (foundSimple, isyst)
    local

      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.EqSystem syst;
    case (false, _) then isyst;
    case (true, syst as BackendDAE.EQSYSTEM())
      equation
        // remove empty entries from vars and update stateorder
        ((vars, _)) = BackendVariable.traverseBackendDAEVars(iVars, updateVar, (BackendVariable.emptyVars(), repl));
        // replace unoptimized equations with optimized
        eqns = BackendEquation.listEquation(listReverse(iEqnslst));
        syst.orderedEqs = eqns; syst.orderedVars = vars;
      then
        BackendDAEUtil.clearEqSyst(syst);
  end match;
end updateSystem;

protected function updateVar "author: Frenkel TUD 2012-12
  update the derivatives of states and add the vars to varrarr"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables, BackendVarTransform.VariableReplacements> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables, BackendVarTransform.VariableReplacements> oTpl;
algorithm
  (outVar,oTpl) := matchcontinue (inVar,inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
    case (v as BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(cr))), (vars, repl))
      equation
        e = BackendVarTransform.getReplacement(repl, cr);
        v = updateStateOrder(e, v);
        vars = BackendVariable.addVar(v, vars);
      then (v, (vars, repl));
    case (v, (vars, repl))
      equation
        vars = BackendVariable.addVar(v, vars);
      then (v, (vars, repl));
  end matchcontinue;
end updateVar;

protected function updateStateOrder "author: Frenkel TUD 2012-12
  update the derivatives of states"
  input DAE.Exp inExp;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match(inExp, inVar)
    local
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef=cr), _) then BackendVariable.setStateDerivative(inVar, SOME(cr));
    else BackendVariable.setStateDerivative(inVar, NONE());
  end match;
end updateStateOrder;

protected function removeSimpleEquationsShared
  input Boolean b;
  input BackendDAE.BackendDAE inDAE;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:=
  match (b, inDAE)
    local
      BackendDAE.Variables globalKnownVars, externalObjects;
      BackendDAE.Variables aliasVars;
      BackendDAE.EquationArray inieqns;
      list<DAE.Constraint> constraintsLst;
      list<DAE.ClassAttributes> clsAttrsLst;

      BackendDAE.EqSystems systs, systs1;
      list<BackendDAE.Equation> eqnslst;
      list<BackendDAE.Var> varlst;
      Boolean b1;
      BackendDAE.Shared shared;

    case (false, _) then inDAE;
    case (true, BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars, externalObjects=externalObjects, aliasVars=aliasVars,
                                                                  constraints=constraintsLst, classAttrs=clsAttrsLst)))
      equation
        if Flags.isSet(Flags.DUMP_REPL) then
          BackendVarTransform.dumpReplacements(repl);
          BackendVarTransform.dumpExtendReplacements(repl);
          BackendVarTransform.dumpDerConstReplacements(repl);
        end if;
        // replace moved vars in globalKnownVars, remeqns
        (_, (_, varlst)) = BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, replaceAliasVarTraverser, (repl, {}));
        aliasVars = List.fold(varlst, fixAliasConstBindings, aliasVars);
        shared.aliasVars = aliasVars;

        (_, _) = BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars, replaceVarTraverser, repl);
        (_, _) = BackendVariable.traverseBackendDAEVarsWithUpdate(externalObjects, replaceVarTraverser, repl);

        ((_, eqnslst, b1)) = BackendEquation.traverseEquationArray(shared.initialEqs, replaceEquationTraverser, (repl, {}, false));
        shared.initialEqs = if b1 then BackendEquation.listEquation(eqnslst) else shared.initialEqs;

        ((_, eqnslst, _)) = BackendEquation.traverseEquationArray(shared.removedEqs, replaceEquationTraverser, (repl, {}, false));
        eqnslst = List.select(eqnslst, BackendEquation.assertWithCondTrue);
        shared.removedEqs = BackendEquation.listEquation(eqnslst);

        (constraintsLst, clsAttrsLst) = replaceOptimicaExps(constraintsLst, clsAttrsLst, repl);
        shared.constraints = constraintsLst;
        shared.classAttrs = clsAttrsLst;

        systs1 = removeSimpleEquationsShared1(systs, {}, repl, NONE(), aliasVars);

      then
        BackendDAE.DAE(systs1, shared);
  end match;
end removeSimpleEquationsShared;

protected function fixAliasConstBindings "author: Frenkel TUD 2012-12
  traverse the alias vars and perfom the alias (not the constant) replacements"
  input BackendDAE.Var iAVar;
  input BackendDAE.Variables iAVars;
  output BackendDAE.Variables oAVars;
protected
  DAE.ComponentRef cr;
  DAE.Exp e;
  BackendDAE.Var avar;
algorithm
  cr := BackendVariable.varCref(iAVar);
  e := BackendVariable.varBindExp(iAVar);
  e := fixAliasConstBindings1(cr, e, iAVars);
  avar := BackendVariable.setBindExp(iAVar, SOME(e));
  oAVars := BackendVariable.addVar(avar, iAVars);
end fixAliasConstBindings;

protected function fixAliasConstBindings1 "author: Frenkel TUD 2012-12"
  input DAE.ComponentRef iCr;
  input DAE.Exp iExp;
  input BackendDAE.Variables iAVars;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(iCr, iExp, iAVars)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
    case (_, _, _)
      equation
        cr::_ = Expression.extractCrefsFromExp(iExp);
        (BackendDAE.VAR(bindExp=SOME(e)), _) = BackendVariable.getVarSingle(cr, iAVars);
      then
        fixAliasConstBindings1(cr, e, iAVars);
    else
      then
        iExp;
  end matchcontinue;
end fixAliasConstBindings1;

protected function replaceAliasVarTraverser "author: Frenkel TUD 2011-12"
 input BackendDAE.Var inVar;
 input tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Var>> inTpl;
 output BackendDAE.Var outVar;
 output tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Var>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v, v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e, e1;
      list<BackendDAE.Var> varlst;
      Boolean b;
    case (v as BackendDAE.VAR(bindExp=SOME(e)), (repl, varlst))
      equation
        (e1, true) = BackendVarTransform.replaceExp(e, repl, NONE());
        b = Expression.isConstValue(e1);
        v1 = if not b then BackendVariable.setBindExp(v, SOME(e1)) else v;
        varlst = List.consOnTrue(b, v1, varlst);
      then (v1, (repl, varlst));
    else (inVar,inTpl);
  end matchcontinue;
end replaceAliasVarTraverser;

protected function replaceVarTraverser "author: Frenkel TUD 2011-03"
 input BackendDAE.Var inVar;
 input BackendVarTransform.VariableReplacements inRepl;
 output BackendDAE.Var outVar;
 output BackendVarTransform.VariableReplacements repl;
algorithm
  (outVar,repl) := matchcontinue (inVar,inRepl)
    local
      BackendDAE.Var v, v1;
      DAE.Exp e, e1;
    case (v as BackendDAE.VAR(bindExp=SOME(e)), repl)
      equation
        (e1, true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v, SOME(e1));
      then (v1, repl);
    else (inVar,inRepl);
  end matchcontinue;
end replaceVarTraverser;

protected function removeSimpleEquationsShared1 "author: Frenkel TUD 2012-12"
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.EqSystems inSysts1;
  input BackendVarTransform.VariableReplacements repl;
  input Option<BackendVarTransform.VariableReplacements> statesetrepl;
  input BackendDAE.Variables aliasVars;
  output BackendDAE.EqSystems outSysts;
algorithm
  outSysts := match (inSysts, inSysts1, repl, statesetrepl, aliasVars)
    local
      BackendDAE.EqSystems rest;
      BackendDAE.Variables v;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnslst;
      Boolean b, b1;
      BackendDAE.EqSystem syst;
      BackendDAE.StateSets stateSets;
      Option<BackendVarTransform.VariableReplacements> statesetrepl1;

    case ({}, _, _, _, _) then inSysts1;
    case (syst::rest, _, _, _, _)
      algorithm
        ((_, eqnslst, b)) := BackendEquation.traverseEquationArray(syst.orderedEqs, replaceEquationTraverser, (repl, {}, false));
        (stateSets, b1, statesetrepl1) := removeAliasVarsStateSets(syst.stateSets, statesetrepl, syst.orderedVars, aliasVars, {}, false);
        if b or b1 then
          eqns := BackendEquation.listEquation(listReverse(eqnslst));
          syst.stateSets := stateSets;
          syst.orderedEqs := eqns;
          syst := BackendDAEUtil.clearEqSyst(syst);
        end if;

        ((_, eqnslst, _)) := BackendEquation.traverseEquationArray(syst.removedEqs, replaceEquationTraverser, (repl, {}, false));
        // remove asserts with condition=true from removed equations
        eqnslst := List.select(eqnslst, BackendEquation.assertWithCondTrue);
        syst.removedEqs := BackendEquation.listEquation(eqnslst);
      then
        removeSimpleEquationsShared1(rest, syst::inSysts1, repl, statesetrepl1, aliasVars);
    end match;
end removeSimpleEquationsShared1;

protected function removeAliasVarsStateSets "author: Frenkel TUD 2012-12"
  input BackendDAE.StateSets iStateSets;
  input Option<BackendVarTransform.VariableReplacements> iStatesetrepl;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables aliasVars;
  input BackendDAE.StateSets iAcc;
  input Boolean inB;
  output BackendDAE.StateSets oStateSets;
  output Boolean outB;
  output Option<BackendVarTransform.VariableReplacements> oStatesetrepl;
algorithm
  (oStateSets, outB, oStatesetrepl) := match(iStateSets, iStatesetrepl, vars, aliasVars, iAcc, inB)
    local
      BackendDAE.StateSets stateSets;
      Integer index, rang;
      list< DAE.ComponentRef> states;
      DAE.ComponentRef crA, crJ;
      list< BackendDAE.Var> varA, statescandidates, ovars, varJ;
      list< BackendDAE.Equation> eqns, oeqns;
      BackendVarTransform.VariableReplacements repl;
      HashSet.HashSet hs;
      Boolean b, b1;
      BackendDAE.Jacobian jac;
    case ({}, _, _, _, _, _) then (listReverse(iAcc), inB, iStatesetrepl);
    case (BackendDAE.STATESET(index, rang, states, crA, varA, statescandidates, ovars, eqns, oeqns, crJ, varJ, jac)::stateSets, _, _, _, _, _)
      equation
        repl = getAliasReplacements(iStatesetrepl, aliasVars);
        // do not replace the set variables
        hs = HashSet.emptyHashSet();
        hs = List.applyAndFold(statescandidates, BaseHashSet.add, BackendVariable.varCref, hs);
        ovars = replaceOtherStateSetVars(ovars, vars, aliasVars, hs, {});
        (eqns, b) = BackendVarTransform.replaceEquations(eqns, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        (oeqns, b1) = BackendVarTransform.replaceEquations(oeqns, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        oeqns = List.fold(oeqns, removeEqualLshRshEqns, {});
        oeqns = listReverse(oeqns);
        (stateSets, b, oStatesetrepl) = removeAliasVarsStateSets(stateSets, SOME(repl), vars, aliasVars, BackendDAE.STATESET(index, rang, states, crA, varA, statescandidates, ovars, eqns, oeqns, crJ, varJ, jac)::iAcc, b or b1);
      then
        (stateSets, b, oStatesetrepl);
  end match;
end removeAliasVarsStateSets;

protected function removeEqualLshRshEqns "author: Frenkel TUD 2012-12"
  input BackendDAE.Equation iEqn;
  input list<BackendDAE.Equation> iEqns;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := matchcontinue(iEqn, iEqns)
    local
      DAE.Exp rhs, lhs;
      Boolean b;
    case (BackendDAE.EQUATION(exp=lhs, scalar=rhs), _)
      equation
        b = Expression.expEqual(lhs, rhs);
      then
        List.consOnTrue(not b, iEqn, iEqns);
    case (BackendDAE.ARRAY_EQUATION(left=lhs, right=rhs), _)
      equation
        b = Expression.expEqual(lhs, rhs);
      then
        List.consOnTrue(not b, iEqn, iEqns);
    case (BackendDAE.COMPLEX_EQUATION(left=lhs, right=rhs), _)
      equation
        b = Expression.expEqual(lhs, rhs);
      then
        List.consOnTrue(not b, iEqn, iEqns);
    else iEqn::iEqns;
  end matchcontinue;
end removeEqualLshRshEqns;

protected function replaceOtherStateSetVars "author: Frenkel TUD 2012-12"
  input list< BackendDAE.Var> iVarLst;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables aliasVars;
  input HashSet.HashSet hs;
  input list< BackendDAE.Var> iAcc;
  output list< BackendDAE.Var> oVarLst;
algorithm
  oVarLst := matchcontinue(iVarLst, vars, aliasVars, hs, iAcc)
    local
      BackendDAE.Var var;
      list< BackendDAE.Var> varlst;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      Boolean b;
    case ({}, _, _, _, _) then iAcc;
    case (var::varlst, _, _, _, _)
      equation
        cr = BackendVariable.varCref(var);
        false = BaseHashSet.has(cr, hs);
        (var, _) = BackendVariable.getVarSingle(cr, aliasVars);
        exp = BackendVariable.varBindExp(var);
        cr::{} = Expression.extractCrefsFromExp(exp);
        b = BaseHashSet.has(cr, hs);
        (var, _) = BackendVariable.getVarSingle(cr, vars);
        varlst = List.consOnTrue(not b, var, iAcc);
      then
        replaceOtherStateSetVars(varlst, vars, aliasVars, hs, varlst);
    case (var::varlst, _, _, _, _)
      equation
        cr = BackendVariable.varCref(var);
        true = BaseHashSet.has(cr, hs);
      then
        replaceOtherStateSetVars(varlst, vars, aliasVars, hs, iAcc);
    case (var::varlst, _, _, _, _)
      then
        replaceOtherStateSetVars(varlst, vars, aliasVars, hs, var::iAcc);
  end matchcontinue;
end replaceOtherStateSetVars;

protected function replaceOptimicaExps
" Helper function to removeSimpleEquationsShared.
  Replaces variables in constraints and classAttributes
  Expressions."
  input list<DAE.Constraint> icontraints;
  input list<DAE.ClassAttributes> iclassAttributes;
  input BackendVarTransform.VariableReplacements irepl;
  output list<DAE.Constraint> ocontraints;
  output list<DAE.ClassAttributes> oclassAttributes;
algorithm
  (ocontraints, oclassAttributes) := match(icontraints, iclassAttributes, irepl)
    local
      Option<DAE.Exp> objetiveE, objectiveIntegrandE, startTimeE, finalTimeE;
      list<DAE.Constraint> constraintLst, rest;
      list<DAE.Exp> constraintLstExps;
      list<DAE.ClassAttributes> classAttributes, restClassAtr;
    case ({}, {}, _) then ({}, {});
    case ({}, DAE.OPTIMIZATION_ATTRS(objetiveE, objectiveIntegrandE, startTimeE, finalTimeE)::restClassAtr, _)
      equation
        ((_, (_, {objetiveE}, _))) = replaceOptExprTraverser((objetiveE, (irepl, {}, false)));
        ((_, (_, {objectiveIntegrandE}, _))) = replaceOptExprTraverser((objectiveIntegrandE, (irepl, {}, false)));
        ((_, (_, {startTimeE}, _))) = replaceOptExprTraverser((startTimeE, (irepl, {}, false)));
        ((_, (_, {finalTimeE}, _))) = replaceOptExprTraverser((finalTimeE, (irepl, {}, false)));
        (_, classAttributes) = replaceOptimicaExps({}, restClassAtr, irepl);
        classAttributes = DAE.OPTIMIZATION_ATTRS(objetiveE, objectiveIntegrandE, startTimeE, finalTimeE)::classAttributes;
      then ({}, classAttributes);
    case (DAE.CONSTRAINT_EXPS(constraintLstExps)::rest, _, _)
      equation
        (constraintLstExps) = replaceOptimicaContraints(constraintLstExps, irepl);
        (constraintLst, _) = replaceOptimicaExps(rest, iclassAttributes, irepl);
        constraintLst = DAE.CONSTRAINT_EXPS(constraintLstExps)::constraintLst;
      then (constraintLst, iclassAttributes);
  end match;
end replaceOptimicaExps;

protected function replaceOptimicaContraints
  input list<DAE.Exp> icontraints;
  input BackendVarTransform.VariableReplacements irepl;
  output list<DAE.Exp> ocontraints;
algorithm
  (ocontraints) := match(icontraints, irepl)
    local
      list<DAE.Exp> constraintLst, rest;
      DAE.Exp e;
    case ({}, _) then ({});
    case (e::rest, _)
      equation
        ((_, (_, {e}, _))) = replaceExprTraverser((e, (irepl, {}, false)));
        (constraintLst) = replaceOptimicaContraints(rest, irepl);
        constraintLst = e::constraintLst;
      then (constraintLst);
  end match;
end replaceOptimicaContraints;

protected function getAliasReplacements "author: Frenkel TUD 2012-12"
  input Option<BackendVarTransform.VariableReplacements> iStatesetrepl;
  input BackendDAE.Variables aliasVars;
  output BackendVarTransform.VariableReplacements oStatesetrepl;
algorithm
  oStatesetrepl := match(iStatesetrepl, aliasVars)
    local
      BackendVarTransform.VariableReplacements repl;
    case (SOME(repl), _) then repl;
    else
      equation
        repl = BackendVarTransform.emptyReplacementsSized(BackendVariable.varsSize(aliasVars));
        repl = BackendVariable.traverseBackendDAEVars(aliasVars, getAliasVarReplacements, repl);
      then
        repl;
  end match;
end getAliasReplacements;

protected function getAliasVarReplacements
  input BackendDAE.Var inVar;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Var v;
  output BackendVarTransform.VariableReplacements repl;
protected
  DAE.Exp exp;
  DAE.ComponentRef cr;
algorithm
  v := inVar;
  BackendDAE.VAR(varName=cr, bindExp=SOME(exp)) := v;
  repl := BackendVarTransform.addReplacement(inRepl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
end getAliasVarReplacements;

protected function replaceEquationTraverser "
  Helper function to e.g. removeSimpleEquations"
  input BackendDAE.Equation inEq;
  input tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Equation>, Boolean> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Equation>, Boolean> outTpl;
algorithm
  (outEq,outTpl) := match (inEq,inTpl)
    local
      BackendDAE.Equation e, eqn;
      DAE.Exp lhs, rhs, res;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqns, eqns1;
      Boolean b, b1;
    case (e, (repl, eqns, b))
      equation
        (eqns1, b1) = BackendVarTransform.replaceEquations({e}, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        if BackendEquation.isInitialEquation(e) and BackendEquation.isEquation(e) then
          eqn = listHead(eqns1);

          lhs = BackendEquation.getEquationLHS(eqn);
          rhs = BackendEquation.getEquationRHS(eqn);
          res = Expression.createResidualExp(lhs, rhs);

          if Expression.isConst(res) then
            if Expression.isZero(res) then
              Error.addCompilerNotification("The following initial equation is redundant and consistent due to simplifications in RemoveSimpleEquations and therefore removed from the initialization problem: " + BackendDump.equationString(e) + (if b1 then " -> " + BackendDump.equationString(eqn) else ""));
              eqns1 = {};
              b1 = true;
            else
              Error.addCompilerWarning("The following initial equation is inconsistent due to simplifications in RemoveSimpleEquations and therefore removed from the initialization problem: " + BackendDump.equationString(e) + (if b1 then " -> " + BackendDump.equationString(eqn) else ""));
              eqns1 = {};
              b1 = true;
            end if;
          end if;
        end if;
        eqns = listAppend(eqns1, eqns);
      then (e, (repl, eqns, b or b1));
  end match;
end replaceEquationTraverser;

protected function replaceExprTraverser "
  Helper function to e.g. removeSimpleEquations"
  input tuple<DAE.Exp, tuple<BackendVarTransform.VariableReplacements, list<DAE.Exp>, Boolean>> inTpl;
  output tuple<DAE.Exp, tuple<BackendVarTransform.VariableReplacements, list<DAE.Exp>, Boolean>> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local
      DAE.Exp exp, exp1;
      BackendVarTransform.VariableReplacements repl;
      list<DAE.Exp> exps;
      Boolean b, b1;
    case ((exp, (repl, exps, b)))
      equation
        (exp1, b1) = BackendVarTransform.replaceExp(exp, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        exps = exp1::exps;
      then ((exp, (repl, exps, b or b1)));
  end match;
end replaceExprTraverser;

protected function replaceOptExprTraverser "
  Helper function to e.g. removeSimpleEquations"
  input tuple<Option<DAE.Exp>, tuple<BackendVarTransform.VariableReplacements, list<Option<DAE.Exp>>, Boolean>> inTpl;
  output tuple<Option<DAE.Exp>, tuple<BackendVarTransform.VariableReplacements, list<Option<DAE.Exp>>, Boolean>> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local
      DAE.Exp exp, exp1;
      BackendVarTransform.VariableReplacements repl;
      list<Option<DAE.Exp>> exps;
      Boolean b, b1;
    case ((NONE(), (repl, exps, b)))
      equation
        exps = NONE()::exps;
      then ((NONE(), (repl, exps, b)));
    case ((SOME(exp), (repl, exps, b)))
      equation
        (exp1, b1) = BackendVarTransform.replaceExp(exp, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        exps = SOME(exp1)::exps;
      then ((SOME(exp), (repl, exps, b or b1)));
  end match;
end replaceOptExprTraverser;


// =============================================================================
// functions to find unReplaceable variables
//
// unReplaceable:
//   - variables with variable subscribts
//   - variables set in when-clauses
//   - variables used in pre
//   - statescandidates of statesets
//   - lhs of array assign statement, because there is a cref used and this is not replaceable_ with array of crefs
// =============================================================================

protected function addUnreplaceableFromStateSets "author: Frenkel TUD 2012-12"
  input BackendDAE.BackendDAE inDAE;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable;
protected
  BackendDAE.EqSystems systs;
algorithm
  BackendDAE.DAE(eqs=systs) := inDAE;
  outUnreplaceable := List.fold(systs, addUnreplaceableFromStateSetSystem, inUnreplaceable);
end addUnreplaceableFromStateSets;

protected function addUnreplaceableFromStateSetSystem "author: Frenkel TUD 2012-12
  traverse an equation system to handle states sets"
  input BackendDAE.EqSystem isyst;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable;
algorithm
  outUnreplaceable:= match (isyst, inUnreplaceable)
    local
      BackendDAE.StateSets stateSets;
      HashSet.HashSet unReplaceable;
    // no stateSet
    case (BackendDAE.EQSYSTEM(stateSets={}), _) then inUnreplaceable;
    // sets
    case (BackendDAE.EQSYSTEM(stateSets=stateSets), _)
      equation
        unReplaceable = List.fold(stateSets, addUnreplaceableFromStateSet, inUnreplaceable);
      then
        unReplaceable;
  end match;
end addUnreplaceableFromStateSetSystem;

protected function addUnreplaceableFromStateSet "author: Frenkel TUD 2012-12"
  input BackendDAE.StateSet iStateSet;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable;
protected
  list<BackendDAE.Var> statevars;
  list<DAE.ComponentRef> crlst;
algorithm
  BackendDAE.STATESET(statescandidates=statevars) := iStateSet;
  crlst := List.map(statevars, BackendVariable.varCref);
  crlst := List.map(crlst, ComponentReference.crefStripLastSubs);
  outUnreplaceable := List.fold(crlst, BaseHashSet.add, inUnreplaceable);
end addUnreplaceableFromStateSet;

protected function addUnreplaceableFromWhens "collect all lhs of whens and array assign statement because these are not
  replaceable_ or if they are replaced the initial system get in trouble"
  input BackendDAE.BackendDAE inDAE;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.DAE(eqs=systs, shared=BackendDAE.SHARED(initialEqs=eqns)) := inDAE;
  outUnreplaceable := List.fold(systs, addUnreplaceableFromWhensSystem, inUnreplaceable);
  ((_,outUnreplaceable)) := BackendDAEUtil.traverseBackendDAEExpsEqns(eqns, Expression.traverseSubexpressionsHelper, (addUnreplaceableFromEqnsExp, outUnreplaceable));
end addUnreplaceableFromWhens;

protected function addUnreplaceableFromEqnsExp
  input DAE.Exp e;
  input HashSet.HashSet hs;
  output DAE.Exp outExp;
  output HashSet.HashSet ohs;
algorithm
  (outExp,ohs) := match (e,hs)
    local
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef=DAE.WILD()), _)
      then (e,hs);

    case (DAE.CREF(componentRef=cr), _)
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
        ohs = BaseHashSet.add(cr, hs);
      then (e,ohs);
    // let WILD pass
    else (e,hs);
  end match;
end addUnreplaceableFromEqnsExp;

protected function addUnreplaceableFromWhensSystem "traverse the Whens of an  equation system to add all variables set in when"
  input BackendDAE.EqSystem isyst;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable;
protected
  BackendDAE.EquationArray eqns;
algorithm
  eqns := BackendEquation.getEqnsFromEqSystem(isyst);
  outUnreplaceable := BackendEquation.traverseEquationArray(eqns, addUnreplaceableFromWhenEqn, inUnreplaceable);
end addUnreplaceableFromWhensSystem;

protected function addUnreplaceableFromWhenEqn
  input BackendDAE.Equation inEq;
  input HashSet.HashSet inHs;
  output BackendDAE.Equation eqn;
  output HashSet.HashSet hs;
algorithm
  (eqn,hs) := match (inEq,inHs)
    local
      BackendDAE.WhenEquation weqn;
      list< DAE.Statement> stmts;
    // when eqn
    case (eqn as BackendDAE.WHEN_EQUATION(whenEquation=weqn), hs)
      equation
        hs = addUnreplaceableFromWhen(weqn, hs);
      then (eqn,hs);
    // algorithm
    case (eqn as BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst=stmts)), hs)
      equation
        hs = List.fold(stmts, addUnreplaceableFromWhenStmt, hs);
      then (eqn, hs);
    else (inEq,inHs);
  end match;
end addUnreplaceableFromWhenEqn;

protected function addUnreplaceableFromWhenStmt
  input DAE.Statement inStmt;
  input HashSet.HashSet inHS;
  output HashSet.HashSet outHS;
algorithm
  outHS := matchcontinue(inStmt, inHS)
    local
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      HashSet.HashSet hs;
      DAE.ComponentRef cr;

    case (DAE.STMT_WHEN(statementLst=stmts, elseWhen=NONE()), _) equation
      hs = List.fold(stmts, addUnreplaceableFromStmt, inHS);
    then hs;

    case (DAE.STMT_WHEN(statementLst=stmts, elseWhen=SOME(stmt)), _) equation
      hs = List.fold(stmts, addUnreplaceableFromStmt, inHS);
      hs = addUnreplaceableFromWhenStmt(stmt, hs);
    then hs;

    // add also lhs of array assign stmts because these are not replaceable with array(...)
    case (DAE.STMT_ASSIGN_ARR(lhs=DAE.CREF(componentRef=cr)), _) equation
      cr = ComponentReference.crefStripLastSubs(cr);
      hs = BaseHashSet.add(cr, inHS);
    then hs;

    // lochel: do not replace arrays that appear on lhs [#2271]
    // TODO: improve this case, it blocks too much simplifications
    case (DAE.STMT_ASSIGN(exp1=DAE.CREF(componentRef=cr)), _) equation
      // DAE.T_ARRAY(ty=_) = ComponentReference.crefLastType(cr);
      // failure({} = ComponentReference.crefLastSubs(cr));
      // true = ComponentReference.isArrayElement(cr);
      cr = ComponentReference.crefStripLastSubs(cr);
      hs = BaseHashSet.add(cr, inHS);
    then hs;

    else
    then inHS;
  end matchcontinue;
end addUnreplaceableFromWhenStmt;

protected function addUnreplaceableFromStmt
  input DAE.Statement inStmt;
  input HashSet.HashSet inHS;
  output HashSet.HashSet outHS;
algorithm
  outHS := match(inStmt, inHS)
    local
      DAE.ComponentRef cr;
      HashSet.HashSet hs;
      list<DAE.Exp> expExpLst;
      list<DAE.ComponentRef> crlst;

    case (DAE.STMT_ASSIGN(exp1=DAE.CREF(componentRef=cr)), _) equation
      cr = ComponentReference.crefStripLastSubs(cr);
      hs = BaseHashSet.add(cr, inHS);
    then hs;

    case (DAE.STMT_TUPLE_ASSIGN(expExpLst=expExpLst), _) equation
      crlst = List.flatten(List.map(expExpLst, Expression.extractCrefsFromExp));
      crlst = List.map(crlst, ComponentReference.crefStripLastSubs);
      hs = List.fold(crlst, BaseHashSet.add, inHS);
    then hs;

    case (DAE.STMT_ASSIGN_ARR(lhs=DAE.CREF(componentRef=cr)), _) equation
      cr = ComponentReference.crefStripLastSubs(cr);
      hs = BaseHashSet.add(cr, inHS);
    then hs;

    else
    then inHS;
  end match;
end addUnreplaceableFromStmt;

protected function addUnreplaceableFromWhen "This is a helper function for addUnreplaceableFromWhenEqn."
  input BackendDAE.WhenEquation inWEqn;
  input HashSet.HashSet iHs;
  output HashSet.HashSet oHs;
algorithm
  oHs := match(inWEqn, iHs)
    local
      DAE.ComponentRef left;
      BackendDAE.WhenEquation weqn;
      HashSet.HashSet hs;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Option<BackendDAE.WhenEquation> oweqn;

    case (BackendDAE.WHEN_STMTS(whenStmtLst=whenStmtLst,elsewhenPart=oweqn), _)
      equation
       hs = addUnreplaceableFromWhenOps(whenStmtLst, iHs);
       if isSome(oweqn) then
         SOME(weqn) = oweqn;
         hs = addUnreplaceableFromWhen(weqn, hs);
       end if;
       then hs;
  end match;
end addUnreplaceableFromWhen;

protected function addUnreplaceableFromWhenOps
"This is a helper function for addUnreplaceableFromWhenEqn."
  input list<BackendDAE.WhenOperator> inWhenOps;
  input HashSet.HashSet iHs;
  output HashSet.HashSet oHs;
algorithm
  oHs := match(inWhenOps)
  local
    DAE.ComponentRef left;
    list<DAE.ComponentRef> crefLst;
    DAE.Exp e;
    list<BackendDAE.WhenOperator> rest;
    HashSet.HashSet hs;

    case BackendDAE.ASSIGN(left = DAE.CREF(componentRef = left))::rest
      equation
        left = ComponentReference.crefStripLastSubs(left);
        hs = BaseHashSet.add(left, iHs);
      then addUnreplaceableFromWhenOps(rest, hs);
    case BackendDAE.ASSIGN(left = e)::rest
      algorithm
        crefLst := Expression.getAllCrefs(e);
        hs := iHs;
        for left in crefLst loop
          left := ComponentReference.crefStripLastSubs(left);
          hs := BaseHashSet.add(left, hs);
        end for;
      then addUnreplaceableFromWhenOps(rest, hs);
    else
      then iHs;
  end match;
end addUnreplaceableFromWhenOps;

protected function traverserExpUnreplaceable
  input DAE.Exp e;
  input HashSet.HashSet unReplaceable;
  output DAE.Exp outExp;
  output HashSet.HashSet outHt;
algorithm
  (outExp,outHt) := matchcontinue (e,unReplaceable)
    local
      DAE.ComponentRef cr;
      list<DAE.Exp> explst;
      list<DAE.ComponentRef> crlst;
    case (DAE.CREF(componentRef = cr), _)
      equation
        outHt = traverseCrefUnreplaceable(cr, NONE(), unReplaceable);
      then (e, outHt);
     case (DAE.CALL(path=Absyn.IDENT(name = "pre"), expLst=explst), _)
      equation
        crlst = List.flatten(List.map(explst, Expression.extractCrefsFromExp));
        crlst = List.map(crlst, ComponentReference.crefStripLastSubs);
        outHt = List.fold(crlst, BaseHashSet.add, unReplaceable);
      then (e, outHt);
    else (e,unReplaceable);
  end matchcontinue;
end traverserExpUnreplaceable;

protected function traverseCrefUnreplaceable
  input DAE.ComponentRef inCref;
  input Option<DAE.ComponentRef> preCref;
  input HashSet.HashSet iUnreplaceable;
  output HashSet.HashSet oUnreplaceable;
algorithm
  oUnreplaceable := match(inCref, preCref)
    local
      DAE.Ident name;
      DAE.ComponentRef cr, pcr;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      HashSet.HashSet unReplaceable;
      Boolean b;

    case (DAE.CREF_QUAL(ident=name, identType=ty, subscriptLst=subs, componentRef=cr), SOME(pcr)) equation
      (_, b) = Expression.traverseExpTopDownCrefHelper(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
      pcr = if b then ComponentReference.crefPrependIdent(pcr, name, {}, ty) else pcr;
      unReplaceable = if b then BaseHashSet.add(pcr, iUnreplaceable) else iUnreplaceable;
      pcr = ComponentReference.crefPrependIdent(pcr, name, subs, ty);
    then traverseCrefUnreplaceable(cr, SOME(pcr), unReplaceable);

    case (DAE.CREF_QUAL(ident=name, identType=ty, subscriptLst=subs, componentRef=cr), NONE()) equation
      (_, b) = Expression.traverseExpTopDownCrefHelper(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
      pcr = DAE.CREF_IDENT(name, ty, {});
      unReplaceable = if b then BaseHashSet.add(pcr, iUnreplaceable) else iUnreplaceable;
    then traverseCrefUnreplaceable(cr, SOME(DAE.CREF_IDENT(name, ty, subs)), unReplaceable);

    case (DAE.CREF_IDENT(ident=name, identType=ty, subscriptLst=subs), SOME(pcr)) equation
      (_, b) = Expression.traverseExpTopDownCrefHelper(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
      pcr = ComponentReference.crefPrependIdent(pcr, name, {}, ty);
      unReplaceable = if b then BaseHashSet.add(pcr, iUnreplaceable) else iUnreplaceable;
    then unReplaceable;

    case (DAE.CREF_IDENT(ident=name, identType=ty, subscriptLst=subs), NONE()) equation
      (_, b) = Expression.traverseExpTopDownCrefHelper(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
      pcr = DAE.CREF_IDENT(name, ty, {});
      unReplaceable = if b then BaseHashSet.add(pcr, iUnreplaceable) else iUnreplaceable;
    then unReplaceable;

    case (DAE.CREF_ITER(), _) then iUnreplaceable;
    case (DAE.OPTIMICA_ATTR_INST_CREF(), _) then iUnreplaceable;
    case (DAE.WILD(), _) then iUnreplaceable;
  end match;
end traverseCrefUnreplaceable;

protected function negateExpression "negate an expression with a debug message"
  input Boolean negationFlag;
  input DAE.Exp inExp "the expression we should negate if flag is true";
  input DAE.Exp inAlternative "the expression we should return if flag is false";
  input String message;
  output DAE.Exp outExpression;
algorithm
  outExpression := match(negationFlag, inExp, inAlternative, message)
    local DAE.Exp exp, negatedExp, negate;
    // we should negate
    case (true, _, _, _)
      equation
        negatedExp = Expression.negate(inExp);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStr("Negating: ", inExp, " " + message + ".\n");
        end if;
      then
        negatedExp;
    // we should not negate
    case (false, _, _, _)
      equation
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrExpStrExpStr("Not negating: ", inExp, " returning: ", inAlternative, " " + message + ".\n");
        end if;
      then
        inAlternative;
  end match;
end negateExpression;

protected function performAliasEliminationBB "BB,
  This module changes the DAE by finding simple equations, doing appropriate substitutions, e.g. known and alias vars!
  NOTE: This is currently an experimental prototype."
  input BackendDAE.BackendDAE inDAE;
  input Boolean findAliases;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, function eliminateTrivialEquations(findAliases=findAliases));
  outDAE := BackendDAEUtil.mapEqSystem(outDAE, getAliasAttributes);
end performAliasEliminationBB;

protected function eliminateTrivialEquations "BB,
main module for eliminating trivial equations
"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input Boolean findAliases;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared;
algorithm
  (outSystem,outShared) := matchcontinue(inSystem,inShared)
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.Variables globalKnownVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EquationArray inieqns;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

      list<BackendDAE.Var> varList;
      list<BackendDAE.Equation> eqList;
      list<BackendDAE.Equation> initEqList, remEqList;
      list<BackendDAE.Equation> simpleEqList;

      HashTableCrToExp.HashTable HTCrToExp;
      HashTableCrToCrEqLst.HashTable HTCrToCrEqLst, HTAliasLst;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplExp;
      list<tuple<DAE.ComponentRef,list<tuple<DAE.ComponentRef,BackendDAE.Equation>>>> tplCrEqLst, tplAliasLst;

      Integer countAliasEquations, countSimpleEquations, size;
      Boolean b;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.Variables globalKnownVars, exobj, globalKnownVars1;
      BackendDAE.Variables aliasVars;
      BackendDAE.EquationArray remeqns, inieqns, remeqns1;
      list<DAE.Constraint> constraintsLst;
      list<DAE.ClassAttributes> clsAttrsLst;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      BackendDAE.EqSystems systs, systs1;
      list<BackendDAE.Equation> eqnslst;
      list<BackendDAE.Var> varlst;
      Boolean b1;
      BackendVarTransform.VariableReplacements repl;

    case ( syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs),
           shared as BackendDAE.SHARED( globalKnownVars=globalKnownVars, aliasVars=aliasVars, initialEqs=inieqns,
                                       eventInfo=eventInfo) )
      equation

      // sizes of Hash tables are system dependent!!!!
      size = BackendVariable.varsSize(orderedVars);
      size = intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
      HTCrToExp = HashTableCrToExp.emptyHashTableSized(size);
      HTCrToCrEqLst = HashTableCrToCrEqLst.emptyHashTableSized(size);
      repl = BackendVarTransform.emptyReplacementsSized(size);

      //SimCodeUtil.execStat("START :");
      // Find known variables and all simple equations and add known variables to shared object!!!
      (_, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList) = BackendEquation.traverseEquationArray(orderedEqs, function findSimpleEquations(findAliases=findAliases),
      (orderedVars, HTCrToExp, HTCrToCrEqLst, {}, {}));
      (tplExp) = BaseHashTable.hashTableList(HTCrToExp);
//    (globalKnownVars, orderedVars) = moveVars(tplExp, globalKnownVars, orderedVars);
      //SimCodeUtil.execStat("FINDSIMPLE1: ");


      //Find Alias variables and move variables to shared object!!!
      (tplCrEqLst) = BaseHashTable.hashTableList(HTCrToCrEqLst);
      HTCrToExp = addRestCrefs(tplCrEqLst, HTCrToExp, HTCrToCrEqLst);
      (tplExp) = BaseHashTable.hashTableList(HTCrToExp);
      (aliasVars, orderedVars) = moveVars(tplExp, aliasVars, orderedVars);

      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      // Necessary, since no update of variable size is done so far !!!!
      varList = BackendVariable.varList(orderedVars);
      // Necessary since no pdate is done for stateDerInfo, this information should be collected afterwards
      varList = removeStateDerInfo(varList);
      orderedVars = BackendVariable.listVar1(varList);
      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      //SimCodeUtil.execStat("FINDSIMPLE2: ");

      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      //Insert known simplifications at all relevant places!!!!
      //This should be changed to traverseEquationArray_WithUpdate or traverseExpsOfEquationArray
      //update kept system equations
      (eqList,_) = BackendEquation.traverseExpsOfEquationList(eqList, traverseExpTopDown, HTCrToExp);
      orderedEqs = BackendEquation.listEquation(eqList);
      //Update initial equations
      initEqList = BackendEquation.equationList(inieqns);
      (initEqList,_) = BackendEquation.traverseExpsOfEquationList(initEqList, traverseExpTopDown, HTCrToExp);
      inieqns = BackendEquation.listEquation(initEqList);

      // Update removed equations !!!
      remEqList = BackendEquation.equationList(syst.removedEqs);
      (remEqList,_) = BackendEquation.traverseExpsOfEquationList(remEqList, traverseExpTopDown, HTCrToExp);
      //remove asserts with condition=true from removed equations
      syst.removedEqs = BackendEquation.listEquation(List.select(remEqList, BackendEquation.assertWithCondTrue));

      remEqList = BackendEquation.equationList(shared.removedEqs);
      (remEqList,_) = BackendEquation.traverseExpsOfEquationList(remEqList, traverseExpTopDown, HTCrToExp);
      //remove asserts with condition=true from removed equations
      shared.removedEqs = BackendEquation.listEquation(List.select(remEqList, BackendEquation.assertWithCondTrue));


      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      repl = addVarReplacements(tplExp,repl);
      // Update Alias variables, some might be moved to known variables!!!
      (aliasVars, (_, varlst)) = BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, replaceAliasVarTraverser, (repl, {}));
      aliasVars = List.fold(varlst, fixAliasConstBindings, aliasVars);
      (globalKnownVars, _) = BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars, replaceVarTraverser, repl);

      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      // Update optimica expressions !!!
      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      // BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      //SimCodeUtil.execStat("FINDSIMPLE4: ");

      if Flags.isSet(Flags.DUMP_REPL) then
        (tplExp) = BaseHashTable.hashTableList(HTCrToExp);
        countAliasEquations = listLength(tplExp);
        countSimpleEquations = listLength(simpleEqList);
        print("Number of Unknowns:    " + intString(BackendVariable.varsSize(orderedVars)) + "\n");
        print("Number of \"Complex\" Equations:   " + intString(BackendEquation.equationLstSize(eqList)) + "\n");
        print("Number of Alias Equations:   " +  intString(countAliasEquations) + "\n");
        print("Number of Simple Equations:   " +  intString(countSimpleEquations) + "\n");
        print("\nAliases:\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
      end if;
      //SimCodeUtil.execStat("FINDSIMPLE6: ");

      syst.orderedVars = orderedVars;
      syst.orderedEqs = orderedEqs;

      shared.eventInfo = eventInfo;
      shared.globalKnownVars = globalKnownVars;
      shared.aliasVars = aliasVars;
      shared.initialEqs = inieqns;

    then (BackendDAEUtil.clearEqSyst(syst), shared);
    else (inSystem, inShared);
  end matchcontinue;
end eliminateTrivialEquations;

protected function moveVars "BB,
move found variables to the alias variables
"
  input list<tuple<DAE.ComponentRef, DAE.Exp>> cr_exp_lst;
  input BackendDAE.Variables inAliasVars;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outAliasVars = inAliasVars;
  output BackendDAE.Variables outVars = inVars;
protected
  DAE.ComponentRef cr;
  DAE.Exp e;
  BackendDAE.Var v;
  Integer i;
  list<DAE.SymbolicOperation> ops;
  Boolean bs;
algorithm
  for cr_exp in cr_exp_lst loop
    (cr,e) := cr_exp;
    try
      (v,i) := BackendVariable.getVarSingle(cr,outVars);
      // add bindExp
      v := BackendVariable.setBindExp(v, SOME(e));
      // Update this to given source information!!!!
      ops := ElementSource.getSymbolicTransformations(DAE.emptyElementSource);
      v := BackendVariable.mergeVariableOperations(v, DAE.SOLVED(cr, e)::ops);
      bs := BackendVariable.isStateVar(v);
      v := if bs then BackendVariable.setVarKind(v, BackendDAE.DUMMY_STATE()) else v;
      // remove and add from corresponding var set
      (outVars, _) := BackendVariable.removeVar(i, outVars);
      outAliasVars := BackendVariable.addVar(v, outAliasVars);
    else
      outAliasVars := outAliasVars;
      outVars := outVars;
    end try;
  end for;
end moveVars;

protected function addVarReplacements "BB,
use VarReplacements only for whileLst
"
  input list<tuple<DAE.ComponentRef, DAE.Exp>> cr_exp_lst;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl=inRepl;
protected
  DAE.ComponentRef cr;
  DAE.Exp e;
algorithm
  for cr_exp in cr_exp_lst loop
    (cr,e) := cr_exp;
    // add to replacements
    outRepl := BackendVarTransform.addReplacement(outRepl, cr, e, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
  end for;
end addVarReplacements;

protected function traverseExpTopDown "BB,
traverse top down, when inserting
"
  input DAE.Exp inExp;
  input HashTableCrToExp.HashTable inHTCrToExp;
  output DAE.Exp outExp;
  output HashTableCrToExp.HashTable outHTCrToExp = inHTCrToExp;
algorithm
  (outExp, _) := Expression.traverseExpTopDown(inExp, insertReplacementsInEquations, inHTCrToExp);
  (outExp,_) := ExpressionSimplify.simplify(outExp);
end traverseExpTopDown;

protected function insertReplacementsInEquations "BB,
inserts replacements stored in the hash table into equations
"
   input DAE.Exp inE1;
   input HashTableCrToExp.HashTable inHTCrToExp;
   output DAE.Exp outE1;
   output Boolean cont;
   output HashTableCrToExp.HashTable outHTCrToExp;
algorithm
   (outE1, cont, outHTCrToExp) := matchcontinue(inE1)
    local
       DAE.ComponentRef cr;
       DAE.Exp value;
       DAE.Type ty;
    case DAE.CREF(componentRef=cr) equation
      if BaseHashTable.hasKey(cr, inHTCrToExp) then
        value = BaseHashTable.get(cr, inHTCrToExp);
      else
        value = inE1;
      end if;
    then (value, true, inHTCrToExp);
    else (inE1, true, inHTCrToExp);
  end matchcontinue;
end insertReplacementsInEquations;

protected function removeStateDerInfo "BB,
remove stateDerInfo! This information should be collected after removeSimpleEquations
"
  input list<BackendDAE.Var> inVarList;
  output list<BackendDAE.Var> vars;
algorithm
  vars := list(if BackendVariable.isStateVar(var) then BackendVariable.setStateDerivative(var, NONE()) else var for var in inVarList);
end removeStateDerInfo;

protected function findSimpleEquations "BB,
main function for detecting simple equations
"
  input BackendDAE.Equation inEq;
  input tuple <BackendDAE.Variables, HashTableCrToExp.HashTable, HashTableCrToCrEqLst.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Equation>> inTuple;
  input Boolean findAliases;
  output BackendDAE.Equation outEq;
  output tuple <BackendDAE.Variables, HashTableCrToExp.HashTable, HashTableCrToCrEqLst.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Equation>> outTuple;
algorithm
  (outEq, outTuple) := matchcontinue(inEq, inTuple)
    local
      BackendDAE.Equation eq, eqSolved;
      HashTableCrToExp.HashTable HTCrToExp;
      HashTableCrToCrEqLst.HashTable HTCrToCrEqLst;
      list<DAE.ComponentRef> cr_lst;
      list<DAE.Exp> exp_lst;
      list<BackendDAE.Var> varList;
      list<BackendDAE.Equation> eqList;
      list<BackendDAE.Equation> simpleEqList;
      Integer count, paramCount;
      DAE.ComponentRef cr, cr1, cr2;
      DAE.Exp res, value, exp1, exp2;
      BackendDAE.Variables vars;
      Boolean keepEquation, cont;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;

    case (eq ,(vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList)) equation
        res = BackendEquation.getEquationRHS(eq);
        (_, (cr_lst,_,count,paramCount,true)) = Expression.traverseExpTopDown(res, findCrefs, ({},vars,0,0,true));
        res = BackendEquation.getEquationLHS(eq);
        (_, (cr_lst,_,count,_,true)) = Expression.traverseExpTopDown(res, findCrefs, (cr_lst,vars,count,paramCount,true));
        keepEquation = true;
        if (count == 1) then
          if Flags.isSet(Flags.DEBUG_ALIAS) then
            print("Found Equation knw0: " + BackendDump.equationString(eq) + "\n");
          end if;
          {cr} = cr_lst;
          false = BackendVariable.isState(cr,vars);
          false = BackendVariable.isClockedState(cr,vars);
          false = BackendVariable.isOutput(cr,vars);
          false = BackendVariable.isDiscrete(cr,vars);
          exp1 = Expression.crefExp(cr);
          true = Types.isSimpleType(Expression.typeof(exp1));
          eqSolved as BackendDAE.EQUATION(scalar=res) = BackendEquation.solveEquation(eq,exp1,NONE());
          true = isSimple(res);
          if Flags.isSet(Flags.DEBUG_ALIAS) then
            print("Found Equation knw1: " + BackendDump.equationString(eq) + "\n");
          end if;
          HTCrToExp = addToCrToExp(cr, eqSolved, HTCrToExp, HTCrToCrEqLst);
          keepEquation = false;
       elseif (count == 2) and findAliases then
          if Flags.isSet(Flags.DEBUG_ALIAS) then
            print("Found Equation al0: " + BackendDump.equationString(eq) + "\n");
          end if;
          {cr2, cr1} = cr_lst;
          // Be careful, when replacing states!!!
          // if BackendVariable.isState(cr1,vars) then
            // true = BackendVariable.isState(cr2,vars);
          // end if;
          false = BackendVariable.isState(cr1,vars) or BackendVariable.isState(cr2,vars);
          false = BackendVariable.isClockedState(cr1,vars) or BackendVariable.isClockedState(cr2,vars);
          false = BackendVariable.isOutput(cr1,vars) or BackendVariable.isOutput(cr2,vars);
          false = BackendVariable.isDiscrete(cr1,vars) or BackendVariable.isDiscrete(cr2,vars);
          exp1 = Expression.crefExp(cr1);
          true = Types.isSimpleType(Expression.typeof(exp1));
          exp2 = Expression.crefExp(cr2);

          BackendDAE.EQUATION(scalar=res) = BackendEquation.solveEquation(eq,exp2,NONE());
          true = isSimple(res);
          BackendDAE.EQUATION(scalar=res) = BackendEquation.solveEquation(eq,exp1,NONE());
          true = isSimple(res);
          if Flags.isSet(Flags.DEBUG_ALIAS) then
            print("Found Equation al1: "  + BackendDump.equationString(eq) + "\n");
          end if;

          HTCrToCrEqLst = addToCrAndEqLists(cr2, cr1, inEq, HTCrToCrEqLst);
          HTCrToCrEqLst = addToCrAndEqLists(cr1, cr2, inEq, HTCrToCrEqLst);

          if (BaseHashTable.hasKey(cr2, HTCrToExp)) then
            value = BaseHashTable.get(cr2, HTCrToExp);
            BackendDAE.EQUATION(scalar=res, source=source, attr=eqAttr) = BackendEquation.solveEquation(eq, Expression.crefExp(cr1),NONE());
            (res,_) = Expression.replaceExp(res,Expression.crefExp(cr2),value);
            (res,_) = ExpressionSimplify.simplify(res);
            HTCrToExp = addToCrToExp(cr1, BackendDAE.EQUATION(Expression.crefExp(cr1), res, source, eqAttr), HTCrToExp, HTCrToCrEqLst);
          else
            if (BaseHashTable.hasKey(cr1, HTCrToExp)) then
              value = BaseHashTable.get(cr1, HTCrToExp);
              BackendDAE.EQUATION(scalar=res, source=source, attr=eqAttr) = BackendEquation.solveEquation(eq, Expression.crefExp(cr2),NONE());
              (res,_) = Expression.replaceExp(res,Expression.crefExp(cr1),value);
              (res,_) = ExpressionSimplify.simplify(res);
              HTCrToExp = addToCrToExp(cr2, BackendDAE.EQUATION(Expression.crefExp(cr2), res, source, eqAttr), HTCrToExp, HTCrToCrEqLst);
            end if;
          end if;
          keepEquation = false;
      end if;
      if (keepEquation) then
        eqList = inEq::eqList;
      else
        simpleEqList = inEq::simpleEqList;
      end if;
    then (inEq, (vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList));
    case (_,(vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList))equation
       eqList = inEq::eqList;
    then (inEq, (vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList));
    else equation
      print("\n++++++++++ Error in RemoveSimpleEquations.findSimpleEquations ++++++++++\n");
    then (inEq, inTuple);
  end matchcontinue;
end findSimpleEquations;

protected function findCrefs "BB,
looks for variable crefs in Expressions, if more then 2 are found stop searching
also stop if complex structures appear, e.g. IFEXP
"
   input DAE.Exp inE1;
   input tuple<list<DAE.ComponentRef>, BackendDAE.Variables, Integer, Integer, Boolean> inTuple;
   output DAE.Exp outE1;
   output Boolean cont;
   output tuple<list<DAE.ComponentRef>, BackendDAE.Variables, Integer, Integer, Boolean> outTuple;
algorithm
    (outE1, cont, outTuple) := matchcontinue(inE1,inTuple)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> cr_lst;
      Integer count, paramCount;
      BackendDAE.VarKind kind;
      BackendDAE.Variables vars;
    case(_,(_,vars,count,_,_)) guard(count<0) then(inE1, false, ({},vars,-1,-1,false));
    case (DAE.CREF(componentRef=cr),(cr_lst,vars,count,paramCount,true)) guard(count < 2 and not (ComponentReference.crefEqual(cr,DAE.crefTime))) equation
      (_,_) = BackendVariable.getVar(cr, vars);
    then (inE1, true, (cr::cr_lst,vars,count+1,paramCount,true));
    case (DAE.CREF(componentRef=cr),(cr_lst,vars,count,paramCount,true)) guard(count < 2 and not (ComponentReference.crefEqual(cr,DAE.crefTime)))
    then (inE1, true, (cr_lst,vars,count,paramCount+1,true));
    case (DAE.CREF(),(_,vars,_,_,true))
    then (inE1, false, ({},vars,-1,-1,false));
    case (DAE.RELATION(),(_,vars,_,_,_))
    then (inE1, false, ({},vars,-1,-1,false));
    case (DAE.IFEXP(),(_,vars,_,_,_))
    then (inE1, false, ({},vars,-1,-1,false));
    case (DAE.CALL(),(_,vars,_,_,_))
    then (inE1, false, ({},vars,-1,-1,false));
    case (DAE.RECORD(),(_,vars,_,_,_))
    then (inE1, false, ({},vars,-1,-1,false));
    else (inE1, true, inTuple);
  end matchcontinue;
end findCrefs;

protected function addToCrAndEqLists "BB,
collect depending varaibles and corresponding equations
in a lookup hash table
"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input BackendDAE.Equation eq;
  input HashTableCrToCrEqLst.HashTable inHTCrToCrEqLst;
  output HashTableCrToCrEqLst.HashTable outHTCrToCrEqLst;
protected
  list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
  BackendDAE.Equation eqSolved;
algorithm
  outHTCrToCrEqLst := match(inHTCrToCrEqLst)
  local
    HashTableCrToCrEqLst.HashTable HTCrToCrEqLst;
  case (HTCrToCrEqLst) equation
    eqSolved = BackendEquation.solveEquation(eq, Expression.crefExp(cr2),NONE());
    if (BaseHashTable.hasKey(cr1, HTCrToCrEqLst)) then
      cr_eq_lst = BaseHashTable.get(cr1, HTCrToCrEqLst);
      cr_eq_lst = (cr2,eqSolved)::cr_eq_lst;
    else
      cr_eq_lst = {(cr2,eqSolved)};
    end if;
    HTCrToCrEqLst = BaseHashTable.add((cr1, cr_eq_lst), HTCrToCrEqLst);
  then HTCrToCrEqLst;
  else equation
      print("\n++++++++++ Error in RemoveSimpleEquations.addToCrAndEqLists ++++++++++\n");
      BackendDump.printEquation(eq);
      print("Solve for:" + ComponentReference.debugPrintComponentRefTypeStr(cr1) + "\n");
  then fail();
end match;
end addToCrAndEqLists;

protected function addToCrToExp "BB,
add one entry and all depending ones to the hash table HTCrToExp
"
  input DAE.ComponentRef cr;
  input BackendDAE.Equation eq;
  input HashTableCrToExp.HashTable inHTCrToExp;
  input HashTableCrToCrEqLst.HashTable inHTCrToCrEqLst;
  output HashTableCrToExp.HashTable outHTCrToExp;
protected
  DAE.Exp value;
algorithm
  (outHTCrToExp) := matchcontinue()
    case () equation
      BackendDAE.EQUATION(scalar=value) = BackendEquation.solveEquation(eq, Expression.crefExp(cr),NONE());
      outHTCrToExp = BaseHashTable.add((cr, value), inHTCrToExp);
      // if Flags.isSet(Flags.DEBUG_ALIAS) then
          // print("ADD: " + ComponentReference.debugPrintComponentRefTypeStr(cr) + " = " + ExpressionDump.printExpStr(value) + "\n");
          // BaseHashTable.dumpHashTable(outHTCrToExp);
          // print("LOOKUP HASH TABLE: \n");
          // BaseHashTable.dumpHashTable(inHTCrToCrEqLst);
      // end if;
      outHTCrToExp = solveAllCrefs(cr, value, outHTCrToExp, inHTCrToCrEqLst);
    then outHTCrToExp;
    else equation
      print("\n++++++++++ Error in RemoveSimpleEquations.addToCrToExp ++++++++++\n");
      BackendDump.printEquation(eq);
      print(ComponentReference.debugPrintComponentRefTypeStr(cr) + "\n");
    then fail();
  end matchcontinue;
end addToCrToExp;

protected function solveAllCrefs "BB,
if an entry with cr = exp is added to HTCrToExp, all depending
variables will be added, too
"
  input DAE.ComponentRef cr;
  input DAE.Exp value;
  input HashTableCrToExp.HashTable inHTCrToExp;
  input HashTableCrToCrEqLst.HashTable inHTCrToCrEqLst;
  output HashTableCrToExp.HashTable outHTCrToExp;
algorithm
  (outHTCrToExp) := matchcontinue(inHTCrToExp)
  local
    HashTableCrToExp.HashTable HTCrToExp;
    list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
  case (HTCrToExp) equation
    if BaseHashTable.hasKey(cr, inHTCrToCrEqLst) then
      cr_eq_lst = BaseHashTable.get(cr, inHTCrToCrEqLst);
      HTCrToExp = solveAllCrefs1(cr, value, cr_eq_lst, HTCrToExp, inHTCrToCrEqLst);
    end if;
  then (HTCrToExp);
  else equation
     print("\n++++++++++ Error in RemoveSimpleEquations.solveAllCrefs ++++++++++\n");
  then (inHTCrToExp);
  end matchcontinue;
end solveAllCrefs;

protected function solveAllCrefs1 "BB,
  helper function for solveAllCrefs
"
  input DAE.ComponentRef cr;
  input DAE.Exp value;
  input list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
  input HashTableCrToExp.HashTable inHTCrToExp;
  input HashTableCrToCrEqLst.HashTable inHTCrToCrEqLst;
  output HashTableCrToExp.HashTable outHTCrToExp;
algorithm
  (outHTCrToExp) := matchcontinue(cr, value, cr_eq_lst, inHTCrToExp)
  local
    DAE.ComponentRef cr1;
    DAE.Exp res;
    BackendDAE.Equation eq;
    HashTableCrToExp.HashTable HTCrToExp;
    list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_rest;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;

    case (_,_,{},HTCrToExp) then HTCrToExp;
    case (_,_,(cr1,eq)::cr_eq_rest, HTCrToExp) equation
      if (not BaseHashTable.hasKey(cr1, HTCrToExp) and not isCrefInValue(cr1,value)) then
        BackendDAE.EQUATION(scalar=res, source=source, attr=eqAttr) = BackendEquation.solveEquation(eq, Expression.crefExp(cr1),NONE());
        (res,_) = Expression.replaceExp(res,Expression.crefExp(cr),value);
        (res,_) = ExpressionSimplify.simplify(res);
        //source = ElementSource.addSymbolicTransformationSubstitution(true, source, Expression.crefExp(cr1), res);
        HTCrToExp = addToCrToExp(cr1, BackendDAE.EQUATION(Expression.crefExp(cr1), res, source, eqAttr), inHTCrToExp, inHTCrToCrEqLst);
      end if;
      HTCrToExp = solveAllCrefs1(cr, value, cr_eq_rest, HTCrToExp, inHTCrToCrEqLst);
    then (HTCrToExp);
    else equation
      print("\n++++++++++ Error in RemoveSimpleEquations.solveAllCrefs1 ++++++++++\n");
    then (inHTCrToExp);
  end matchcontinue;
end solveAllCrefs1;

protected function isCrefInValue "BB,
true, if cr is in expression value
"
  input DAE.ComponentRef cr;
  input DAE.Exp value;
  output Boolean isInValue;
protected
  list<DAE.ComponentRef> cr_lst;
algorithm
  cr_lst := Expression.extractCrefsFromExp(value);
  isInValue := listMember(cr, cr_lst);
end isCrefInValue;

protected function addRestCrefs "BB,
add all non-constant alias variables to the hash table HTCrToExp
"
  input list<tuple<DAE.ComponentRef,list<tuple<DAE.ComponentRef,BackendDAE.Equation>>>> tplCrEqLst;
  input HashTableCrToExp.HashTable inHTCrToExp;
  input HashTableCrToCrEqLst.HashTable inHTCrToCrEqLst;
  output HashTableCrToExp.HashTable HTCrToExp = inHTCrToExp;
protected
  DAE.ComponentRef cr1;
  list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
algorithm
  try
    for tpl in tplCrEqLst loop
      (cr1,cr_eq_lst) := tpl;
      if not BaseHashTable.hasKey(cr1, HTCrToExp) then
        HTCrToExp := addThisCrefs(cr_eq_lst, HTCrToExp, inHTCrToCrEqLst);
      end if;
    end for;
  else
    print("\n++++++++++ Error in RemoveSimpleEquations.addRestCrefs ++++++++++\n");
    fail();
  end try;
end addRestCrefs;

protected function addThisCrefs "BB
add all dependent alias variable (cr1 = expression) to
the hash table HTCrToExp.
"
  input list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
  input HashTableCrToExp.HashTable inHTCrToExp;
  input HashTableCrToCrEqLst.HashTable inHTCrToCrEqLst;
  output HashTableCrToExp.HashTable outHTCrToExp;
algorithm
  (outHTCrToExp) := matchcontinue(cr_eq_lst, inHTCrToExp)
  local
    DAE.ComponentRef cr1;
    DAE.Exp res;
    BackendDAE.Equation eq;
    HashTableCrToExp.HashTable HTCrToExp;
    list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_rest;
    DAE.ElementSource source;
  BackendDAE.EquationAttributes eqAttr;

    case ({},HTCrToExp) then HTCrToExp;
    case ((cr1,eq)::cr_eq_rest, HTCrToExp) equation
       if (not BaseHashTable.hasKey(cr1, HTCrToExp)) then
          HTCrToExp = addToCrToExp(cr1, eq, HTCrToExp, inHTCrToCrEqLst);
      end if;
      HTCrToExp = addThisCrefs(cr_eq_rest, HTCrToExp, inHTCrToCrEqLst);
    then (HTCrToExp);
    else equation
      print("\n++++++++++ Error in RemoveSimpleEquations.addThisCrefs ++++++++++\n");
    then (inHTCrToExp);
  end matchcontinue;
end addThisCrefs;

protected function isSimple "BB
start module for detecting simple equation/expressions
"
  input DAE.Exp inExp;
  output Boolean outIsSimple;
algorithm
   //print("Traverse "  + ExpressionDump.printExpStr(inExp) + "\n");
  (_,outIsSimple) := Expression.traverseExpTopDown(inExp, checkOperator, true);
  //print("Simple: " +  boolString(outIsSimple) + "\n");
end isSimple;

protected function checkOperator "BB
check, if left and right expression of an equation are simple:
a = b, a = -b, a = not b, a = 2.0, etc.
this module will be extended in the future!
"
  input DAE.Exp inExp;
  input Boolean inIsSimple;
  output DAE.Exp outExp;
  output Boolean cont;
  output Boolean outIsSimple;
algorithm
  (outExp, cont, outIsSimple) := matchcontinue(inExp)
    local
      DAE.Exp exp1, exp2;
      DAE.Operator op;
      Boolean check;
    case DAE.BINARY(exp1, op, exp2) equation
      true = checkOp(op);
      (_, true,_) = checkOperator(exp1,inIsSimple);
      (_, true,_) = checkOperator(exp2,inIsSimple);
    then (inExp, true, true);
    case DAE.UNARY(_,exp1)
    then checkOperator(exp1,inIsSimple);
    case DAE.LUNARY(_,exp1)
    then checkOperator(exp1,inIsSimple);
    case DAE.CREF()
    then (inExp, true, true);
    case DAE.ICONST()
    then (inExp, true, true);
    case DAE.RCONST()
    then (inExp, true, true);
    case DAE.BCONST()
    then (inExp, true, true);
    case DAE.SCONST()
    then (inExp, true, true);
    else (inExp, false, false);
  end matchcontinue;
end checkOperator;

protected function checkOp "BB,
"
  input DAE.Operator inOp;
  output Boolean outB;
algorithm
  outB := match(inOp)
    case DAE.ADD() then true;
    case DAE.SUB() then true;
    case DAE.UMINUS() then true;
    case DAE.MUL() then false;
    case DAE.EQUAL() then false;
    case DAE.DIV() then false;
    case DAE.POW() then false;
    else false;
  end match;
end checkOp;

protected function determineAliasLst "BB,
determine all alias variables and store them in a hash table
Problem: aliasVars are in the shared object, and has to be traversed
for every equation system.
"
  input BackendDAE.Variables inAliasVars;
  input BackendDAE.Variables inVars;
  input HashTableCrToCrEqLst.HashTable inHTAliasLst;
  output HashTableCrToCrEqLst.HashTable outHTAliasLst = inHTAliasLst;
protected
  DAE.ComponentRef cr1, cr2;
  list<DAE.ComponentRef> cr_lst;
  DAE.Exp e;
  BackendDAE.Equation eq;
  Option<BackendDAE.Var> w;
  BackendDAE.Var v;
  Integer i;
  list<DAE.SymbolicOperation> ops;
  Boolean bs;
  Integer count;
  array<Option<BackendDAE.Var>> vars;

algorithm
BackendDAE.VARIABLES(varArr = BackendDAE.VARIABLE_ARRAY(varOptArr = vars)) := inAliasVars;
  for w in vars loop
    try
      SOME(v) := w;
      cr1 := BackendVariable.varCref(v);
      (e) := BackendVariable.varBindExp(v);
      (_, (cr_lst,_,count,_,_)) := Expression.traverseExpTopDown(e, findCrefs, ({},inVars,0,0,true));
      // add bindExp
      1 := count;
      {cr2} := cr_lst;
      eq := BackendDAE.EQUATION(Expression.crefExp(cr1), e, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
      outHTAliasLst := addToCrAndEqLists(cr2, cr1, eq, outHTAliasLst);
    else
      outHTAliasLst := outHTAliasLst;
    end try;
  end for;
end determineAliasLst;


protected function getAliasAttributes "BB,
go through all equation systems and set the start and nominal
values of the alias variables.
"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared = inShared;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.Variables aliasVars;

  HashTableCrToCrEqLst.HashTable HTAliasLst;
  list<tuple<DAE.ComponentRef,list<tuple<DAE.ComponentRef,BackendDAE.Equation>>>> tplAliasLst;
  Integer size;
algorithm
   BackendDAE.EQSYSTEM(orderedVars=orderedVars):= inSystem;
   BackendDAE.SHARED(aliasVars=aliasVars) := inShared;

   size := BackendVariable.varsSize(orderedVars);
   size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
   HTAliasLst := HashTableCrToCrEqLst.emptyHashTableSized(size);

   HTAliasLst := determineAliasLst(aliasVars, orderedVars, HTAliasLst);
   (tplAliasLst) := BaseHashTable.hashTableList(HTAliasLst);
   orderedVars := setAttributes(tplAliasLst, orderedVars, aliasVars);

   outSystem := BackendDAEUtil.setEqSystVars(inSystem, orderedVars);
end getAliasAttributes;

protected function setAttributes "BB
determine all start and nominal values for alias variables and
set the corresponding values of the variable which is kept in the system
"
  input list<tuple<DAE.ComponentRef,list<tuple<DAE.ComponentRef,BackendDAE.Equation>>>> tplCrEqLst;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inAliasVars;
  output BackendDAE.Variables outVars = inVars;
protected
  DAE.ComponentRef cr1;
  list<DAE.ComponentRef> cr_lst;
  DAE.Exp e;
  BackendDAE.Var v;
  Integer i, j;
  list<tuple<DAE.ComponentRef,list<tuple<DAE.ComponentRef,BackendDAE.Equation>>>> tplCrEqRest;
  list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
  HashTableExpToIndex.HashTable HTStartExpToInt;
  HashTableExpToIndex.HashTable HTNominalExpToInt;
  list<tuple<DAE.Exp,Integer>> tplExpIndList;
algorithm
  if listEmpty(tplCrEqLst) then
    return;
  end if;
  try
  HTStartExpToInt := HashTableExpToIndex.emptyHashTableSized(100);
  HTNominalExpToInt := HashTableExpToIndex.emptyHashTableSized(100);
  for tpl in tplCrEqLst loop
    (cr1,cr_eq_lst) := tpl;
    BaseHashTable.clear(HTStartExpToInt);
    BaseHashTable.clear(HTNominalExpToInt);
    (v,i) := BackendVariable.getVarSingle(cr1,outVars);
    if BackendVariable.varHasStartValue(v) then
      e := BackendVariable.varStartValue(v);
      if Expression.isZero(e) then
        e := DAE.RCONST(0.0);
      end if;
      cr_lst := Expression.extractCrefsFromExp(e);
      j := 2 - listLength(cr_lst);
      j := j*ComponentReference.crefDepth(cr1);
      HTStartExpToInt := BaseHashTable.add((e, j), HTStartExpToInt);
      if Flags.isSet(Flags.DEBUG_ALIAS) then
        print("START: " + ComponentReference.printComponentRefStr(cr1) + " = " + ExpressionDump.printExpStr(e) + "\n");
      end if;
    end if;
    if BackendVariable.varHasNominalValue(v) then
      e := BackendVariable.varNominalValue(v);
      cr_lst := Expression.extractCrefsFromExp(e);
      j := 2 - listLength(cr_lst);
      j := j*ComponentReference.crefDepth(cr1);
      HTNominalExpToInt := BaseHashTable.add((e, j), HTNominalExpToInt);
      if Flags.isSet(Flags.DEBUG_ALIAS) then
        print("NOMINAL: " + ComponentReference.printComponentRefStr(cr1) + " = " + ExpressionDump.printExpStr(e) + "\n");
      end if;
    end if;
    (HTStartExpToInt,HTNominalExpToInt) := getThisAttributes(cr1,cr_eq_lst,inAliasVars,HTStartExpToInt,HTNominalExpToInt);
    tplExpIndList := BaseHashTable.hashTableList(HTStartExpToInt);
    if not listEmpty(tplExpIndList) then
      e := getDominantAttributeValue(tplExpIndList);
      v := BackendVariable.setVarStartValue(v,e);
      if Flags.isSet(Flags.DEBUG_ALIAS) then
        print("START: " + ComponentReference.printComponentRefStr(cr1) + " = " + ExpressionDump.printExpStr(e) + "\n");
        BaseHashTable.dumpHashTable(HTStartExpToInt);
      end if;
    end if;
    tplExpIndList := BaseHashTable.hashTableList(HTNominalExpToInt);
    if not listEmpty(tplExpIndList) then
      e := getDominantAttributeValue(tplExpIndList);
      v := BackendVariable.setVarNominalValue(v,e);
      if Flags.isSet(Flags.DEBUG_ALIAS) then
        print("NOMINAL: " + ComponentReference.printComponentRefStr(cr1) + " = " + ExpressionDump.printExpStr(e) + "\n");
        BaseHashTable.dumpHashTable(HTNominalExpToInt);
      end if;
    end if;
    outVars := BackendVariable.setVarAt(outVars,i,v);
  end for;
  else
    print("\n++++++++++ Error in RemoveSimpleEquations.setAttributes ++++++++++\n");
  end try;
end setAttributes;

protected function getThisAttributes "BB,
get start and nominal values of alias variables and prioritize
the expressions with respect to the crefDeth.
"
  input DAE.ComponentRef cr;
  input list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_lst;
  input BackendDAE.Variables inAliasVars;
  input HashTableExpToIndex.HashTable inHTStartExpToInt;
  input HashTableExpToIndex.HashTable inHTNominalExpToInt;
  output HashTableExpToIndex.HashTable outHTStartExpToInt=inHTStartExpToInt;
  output HashTableExpToIndex.HashTable outHTNominalExpToInt=inHTNominalExpToInt;

algorithm
  (outHTStartExpToInt,outHTNominalExpToInt) := matchcontinue(cr_eq_lst)
  local
    DAE.ComponentRef cr1;
    list<DAE.ComponentRef> cr_lst;
    DAE.Exp res, e, e1, e2;
    BackendDAE.Equation eq;
    BackendDAE.Var v;
    list<tuple<DAE.ComponentRef,BackendDAE.Equation>> cr_eq_rest;
    Integer j, j1;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;

    case ({}) then (outHTStartExpToInt,outHTNominalExpToInt);
    case (cr1,_)::cr_eq_rest equation
      (v,_) = BackendVariable.getVarSingle(cr1,inAliasVars);
      e = BackendVariable.varBindExp(v);
      if BackendVariable.varHasStartValue(v) then
        res = BackendVariable.varStartValue(v);
        BackendDAE.EQUATION(scalar=e1) = BackendEquation.solveEquation(BackendDAE.EQUATION(Expression.crefExp(cr1),e,DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING), Expression.crefExp(cr),NONE());
        BackendDAE.EQUATION(scalar=e2) = BackendEquation.solveEquation(BackendDAE.EQUATION(res,e,DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING), Expression.crefExp(cr),NONE());
        (e2,_) = ExpressionSimplify.simplify(e2);
        if Expression.isZero(e2) then
          e2 = DAE.RCONST(0.0);
        end if;
        cr_lst = Expression.extractCrefsFromExp(e2);
        j = 2 - listLength(cr_lst);
        j = j*ComponentReference.crefDepth(cr1);
        if BaseHashTable.hasKey(e2, outHTStartExpToInt) then
          j1 = BaseHashTable.get(e2, outHTStartExpToInt);
          if (j1<j) then
            j = j1;
          end if;
        end if;
        outHTStartExpToInt = BaseHashTable.add((e2, j), outHTStartExpToInt);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          print("START: " + ComponentReference.printComponentRefStr(cr) + " = " + ExpressionDump.printExpStr(e1) + " = " + ExpressionDump.printExpStr(e2) + "\n");
        end if;
      end if;
      if BackendVariable.varHasNominalValue(v) then
        e2 = BackendVariable.varNominalValue(v);
        cr_lst = Expression.extractCrefsFromExp(e2);
        j = 2 - listLength(cr_lst);
        j = j*ComponentReference.crefDepth(cr1);
        if BaseHashTable.hasKey(e2, outHTNominalExpToInt) then
          j1 = BaseHashTable.get(e2, outHTNominalExpToInt);
          if (j1<j) then
            j = j1;
          end if;
        end if;
        outHTNominalExpToInt = BaseHashTable.add((e2, j), outHTNominalExpToInt);
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          print("NOMINAL: " + ComponentReference.printComponentRefStr(cr) + " = " + ExpressionDump.printExpStr(e1) + " = " + ExpressionDump.printExpStr(e2) + "\n");
        end if;
      end if;
      (outHTStartExpToInt,outHTNominalExpToInt) = getThisAttributes(cr, cr_eq_rest, inAliasVars, outHTStartExpToInt, outHTNominalExpToInt);
    then (outHTStartExpToInt,outHTNominalExpToInt);
    else equation
      print("\n++++++++++ Error in RemoveSimpleEquations.getThisAttributes ++++++++++\n");
    then (outHTStartExpToInt,outHTNominalExpToInt);
  end matchcontinue;
end getThisAttributes;

function getDominantAttributeValue "BB,
pick the expression with lowest integer value, if two
integer values are equal, take the first occurring one.
"
  input list<tuple<DAE.Exp,Integer>> tplExpIndList;
  output DAE.Exp outE;
protected
  DAE.Exp e;
  tuple<DAE.Exp,Integer> tpl;
  Integer i, j = 111111;
algorithm
  for tpl in tplExpIndList loop
    (e,i) := tpl;
    if (i<j) then
      outE := e;
      j := i;
    end if;
  end for;
end getDominantAttributeValue;


protected function dumpSimpleContainer
  input SimpleContainer container;
  output String sOut;
algorithm
  sOut := matchcontinue(container)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e;
      String s1,s2;
      Boolean n1,n2;
      Integer i1,i2;
  case(ALIAS(cr1,n1,i1,cr2,n2,i2,_,_))
    equation
      s1 = if n1 then "(-)" else "" ;
      s2 = if n2 then "(-)" else "" ;
      s1 = s1 +ComponentReference.printComponentRefStr(cr1);
      s2= s2 +ComponentReference.printComponentRefStr(cr2);
    then "ALIASE: \t\t"+s1 + " = " +s2+"  ("+intString(i1)+", "+intString(i2)+")";
  case(PARAMETERALIAS(cr1,n1,i1,cr2,n2,i2,_,_))
    equation
      s1 = if n1 then "(-)" else "" ;
      s2 = if n2 then "(-)" else "" ;
      s1 = s1 +ComponentReference.printComponentRefStr(cr1);
      s2= s2 +ComponentReference.printComponentRefStr(cr2);
    then "PARAMETERALIASE: \t"+s1 + " = " +s2+"  ("+intString(i1)+", "+intString(i2)+")";
  case(TIMEALIAS(cr1,n1,i1,cr2,n2,i2,_,_))
    equation
      s1 = if n1 then "(-)" else "" ;
      s2 = if n2 then "(-)" else "" ;
      s1 = s1 +ComponentReference.printComponentRefStr(cr1);
      s2= s2 +ComponentReference.printComponentRefStr(cr2);
    then "TIMEALIASE: \t"+s1 + " = " +s2+"  ("+intString(i1)+", "+intString(i2)+")";
  case(TIMEINDEPENTVAR(cr1,_,e,_,_))
    equation
    then "TIMEINDEPENT: \t"+ComponentReference.printComponentRefStr(cr1) + " = " +ExpressionDump.printExpStr(e);
  else
    then "----------";
  end matchcontinue;
end dumpSimpleContainer;

annotation(__OpenModelica_Interface="backend");
end RemoveSimpleEquations;
