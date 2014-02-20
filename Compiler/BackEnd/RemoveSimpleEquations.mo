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
                            simple equations

  RCS: $Id: RemoveSimpleEquations.mo 14235 2012-12-05 04:34:35Z wbraun $"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;

protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashSet;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import Flags;
protected import HashSet;
protected import Inline;
protected import List;
protected import Types;
protected import Util;

protected type EquationAttributes = tuple<DAE.ElementSource, Boolean> "eqnAttributes(source,differentiated)";

protected
uniontype SimpleContainer
  record ALIAS
    DAE.ComponentRef cr1;
    Boolean negatedCr1;
    Integer i1;
    DAE.ComponentRef cr2;
    Boolean negatedCr2;
    Integer i2;
    EquationAttributes eqnAttributes;
    Integer visited;
  end ALIAS;
  record PARAMETERALIAS
    DAE.ComponentRef unknowncr;
    Boolean negatedCr1;
    Integer i1;
    DAE.ComponentRef paramcr;
    Boolean negatedCr2;
    Integer i2;
    EquationAttributes eqnAttributes;
    Integer visited;
  end PARAMETERALIAS;
  record TIMEALIAS
    DAE.ComponentRef cr1;
    Boolean negatedCr1;
    Integer i1;
    DAE.ComponentRef cr2;
    Boolean negatedCr2;
    Integer i2;
    EquationAttributes eqnAttributes;
    Integer visited;
  end TIMEALIAS;
  record TIMEINDEPENTVAR
    DAE.ComponentRef cr;
    Integer i;
    DAE.Exp exp;
    EquationAttributes eqnAttributes;
    Integer visited;
  end TIMEINDEPENTVAR;
end SimpleContainer;

protected type AccTuple = tuple<BackendDAE.Variables, BackendDAE.Shared, list<BackendDAE.Equation>, list<SimpleContainer>, Integer, array<list<Integer>>, Boolean>;

protected type VarSetAttributes =
  tuple<Boolean, tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>>, Option<DAE.Exp>, Integer, tuple<Option<DAE.Exp>, Option<DAE.Exp>>>
  "fixed, list<startvalue, origin, cr>, nominal, nNominals, min, max";

protected constant VarSetAttributes EMPTYVARSETATTRIBUTES = (false, (-1, {}), NONE(), 0, (NONE(), NONE()));

/*
 * fastAcausal
 *
 */

public function fastAcausal "author: Frenkel TUD 2012-12
  This Function remove with a linear scaling with respect to the number of
  equations in an acausal system as much as possible simple equations."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b;
  Integer size;
  HashSet.HashSet unReplaceable;
algorithm
  // get the size of the system to set up the replacement hashmap
  size := BackendDAEUtil.daeSize(dae);
  size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // check for unReplaceable crefs
  unReplaceable := HashSet.emptyHashSet();
  unReplaceable := BackendDAEUtil.traverseBackendDAEExps(dae, traverserUnreplaceable, unReplaceable);
  unReplaceable := addUnreplaceableFromWhens(dae, unReplaceable);
  Debug.fcall2(Flags.DUMP_REPL, BackendDump.dumpHashSet, unReplaceable, "Unreplaceable Crefs:");
  // traverse all systems and remove simple equations
  (odae, (repl, b, _, _)) := BackendDAEUtil.mapEqSystemAndFold(dae, fastAcausal1, (repl, false, unReplaceable, Flags.getConfigInt(Flags.MAXTRAVERSALS)));
  // traverse the shared parts
  odae := removeSimpleEquationsShared(b, odae, repl);
end fastAcausal;

protected function fastAcausal1 "author: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, tuple<BackendVarTransform.VariableReplacements, Boolean, HashSet.HashSet, Integer>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, tuple<BackendVarTransform.VariableReplacements, Boolean, HashSet.HashSet, Integer>> osharedOptimized;
protected
  BackendVarTransform.VariableReplacements repl;
  HashSet.HashSet unReplaceable;
  BackendDAE.Shared shared;
  list<BackendDAE.Equation> eqnslst;
  list<SimpleContainer> simpleeqnslst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.StateSets stateSets;
  array<list<Integer>> mT;
  Boolean foundSimple, globalFindSimple, b;
  Integer traversals;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, stateSets=stateSets) := isyst;
  (shared, (repl, globalFindSimple, unReplaceable, traversals)) := sharedOptimized;
  // transform to list, this is later not neccesary because the acausal system should save the equations as list
  eqnslst := BackendEquation.equationList(eqns);
  mT := arrayCreate(BackendVariable.varsSize(vars), {});
  // check equations
  ((_, _, eqnslst, simpleeqnslst, _, _, foundSimple)) := List.fold(eqnslst, simpleEquationsFinder, (vars, shared, {}, {}, 1, mT, false));
  ((_, vars, shared, repl, unReplaceable, _, eqnslst, b)) := 
     causalFinder(foundSimple, simpleeqnslst, eqnslst, 1, traversals, vars, shared, repl, unReplaceable, mT, {}, globalFindSimple);
  osyst := updateSystem(b, eqnslst, vars, stateSets, repl, isyst);
  osharedOptimized := (shared, (repl, b, unReplaceable, traversals));
end fastAcausal1;

protected function causalFinder "author: Frenkel TUD 2012-12"
  input Boolean foundSimple;
  input list<SimpleContainer> iSimpleeqnslst;
  input list<BackendDAE.Equation> iEqnslst;
  input Integer index;
  input Integer traversals;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input HashSet.HashSet iUnreplaceable;
  input array<list<Integer>> iMT;
  input list<BackendDAE.Equation> iGlobalEqnslst;
  input Boolean globalFoundSimple;
  output tuple<Integer, BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean> oTpl;
algorithm
  oTpl:=
  match (foundSimple, iSimpleeqnslst, iEqnslst, index, traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      Boolean b1;
      array<SimpleContainer> simpleeqns;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
    
    case (false, _, {}, _, _, _, _, _, _, _, _, _)
      then ((traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple));
    
    case (false, _, _, _, _, _, _, _, _, _, {}, _)
      then ((traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, iEqnslst, globalFoundSimple));
    
    case (false, _, _, _, _, _, _, _, _, _, _, _)
      then ((traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, listAppend(iEqnslst, iGlobalEqnslst), globalFoundSimple));
    
    case (true, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // transform simpleeqns to array
        simpleeqns = listArray(listReverse(iSimpleeqnslst));
        // collect and handle sets
        (vars, eqnslst, shared, repl) = handleSets(arrayLength(simpleeqns), 1, simpleeqns, iMT, iUnreplaceable, iVars, iEqnslst, ishared, iRepl);
        // perform replacements and try again
        (eqnslst, b1) = BackendVarTransform.replaceEquations(eqnslst, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
      then
        causalFinder1(intGt(index, traversals), b1, eqnslst, index+1, traversals, vars, shared, repl, iUnreplaceable, iMT, iGlobalEqnslst, true);
  
  end match;
end causalFinder;

protected function causalFinder1 "author: Frenkel TUD 2012-12"
  input Boolean finished "index > traversal";
  input Boolean b;
  input list<BackendDAE.Equation> iEqnslst;
  input Integer index;
  input Integer traversals;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements iRepl;
  input HashSet.HashSet iUnreplaceable;
  input array<list<Integer>> iMT;
  input list<BackendDAE.Equation> iGlobalEqnslst;
  input Boolean globalFoundSimple;
  output tuple<Integer, BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean> outTpl;
algorithm
  outTpl := match (finished, b, iEqnslst, index, traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple)
    local
      Boolean b1;
      list<BackendDAE.Equation> eqnslst;
      list<SimpleContainer> simpleeqnslst;
      BackendDAE.Variables vars;
      BackendDAE.Shared shared;
    case(true, _, _, _, _, _, _, _, _, _, _, _) then ((traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, listAppend(iEqnslst, iGlobalEqnslst), globalFoundSimple));
    case(_, false, {}, _, _, _, _, _, _, _, _, _) then ((traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple));
    case(_, false, _, _, _, _, _, _, _, _, _, _) then ((traversals, iVars, ishared, iRepl, iUnreplaceable, iMT, listAppend(iEqnslst, iGlobalEqnslst), globalFoundSimple));
    case(_, true, _, _, _, _, _, _, _, _, _, _)
      equation
        ((vars, shared, eqnslst, simpleeqnslst, _, _, b1)) = List.fold(iEqnslst, simpleEquationsFinder, (iVars, ishared, {}, {}, 1, iMT, false));
      then
        causalFinder(b1, simpleeqnslst, eqnslst, index, traversals, vars, shared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple);
  end match;
end causalFinder1;

/*
 * allAcausal
 */

public function allAcausal "author: Frenkel TUD 2012-12"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b;
  Integer size;
  HashSet.HashSet unReplaceable;
algorithm
  // get the size of the system to set up the replacement hashmap
  size := BackendDAEUtil.daeSize(inDAE);
  size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // check for unReplaceable crefs
  unReplaceable := HashSet.emptyHashSet();
  unReplaceable := BackendDAEUtil.traverseBackendDAEExps(inDAE, traverserUnreplaceable, unReplaceable);
  unReplaceable := addUnreplaceableFromWhens(inDAE, unReplaceable);
  Debug.fcall2(Flags.DUMP_REPL, BackendDump.dumpHashSet, unReplaceable, "Unreplaceable Crefs:");
  (outDAE, (repl, _, b)) := BackendDAEUtil.mapEqSystemAndFold(inDAE, allAcausal1, (repl, unReplaceable, false));
  outDAE := removeSimpleEquationsShared(b, outDAE, repl);
  // until remove simple equations does not update assignments and comps remove them
end allAcausal;

protected function allAcausal1 "author: Frenkel TUD 2012-12
  This function moves simple equations on the form a=b and a=const and 
  a=f(not time) in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean>> osharedOptimized;
algorithm
  (osyst, osharedOptimized):=
  match (isyst, sharedOptimized)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      HashSet.HashSet unReplaceable;
      Boolean b, b1;
      array<list<Integer>> mT;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.EqSystem syst;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, stateSets=stateSets), (shared, (repl, unReplaceable, b1)))
      equation
        // transform to list, this is later not neccesary because the acausal system should save the equations as list
        eqnslst = BackendEquation.equationList(eqns);
        mT = arrayCreate(BackendVariable.varsSize(vars), {});
        // check equations
        ((vars, shared, repl, unReplaceable, _, eqnslst, b)) = allCausalFinder(eqnslst, (vars, shared, repl, unReplaceable, mT, {}, false));
        syst = updateSystem(b, eqnslst, vars, stateSets, repl, isyst);
      then (syst, (shared, (repl, unReplaceable, b or b1)));
  end match;
end allAcausal1;


/*
 * causal
 */

public function causal "author: Frenkel TUD 2012-12"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendVarTransform.VariableReplacements repl;
  Boolean b;
  Integer size;
  HashSet.HashSet unReplaceable;
algorithm
  // get the size of the system to set up the replacement hashmap
  size := BackendDAEUtil.daeSize(inDAE);
  size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
  repl := BackendVarTransform.emptyReplacementsSized(size);
  // check for unReplaceable crefs
  unReplaceable := HashSet.emptyHashSet();
  unReplaceable := BackendDAEUtil.traverseBackendDAEExps(inDAE, traverserUnreplaceable, unReplaceable);
  unReplaceable := addUnreplaceableFromWhens(inDAE, unReplaceable);
  // do not replace state sets
  unReplaceable := addUnreplaceableFromStateSets(inDAE, unReplaceable);
  Debug.fcall2(Flags.DUMP_REPL, BackendDump.dumpHashSet, unReplaceable, "Unreplaceable Crefs:");
  (outDAE, (repl, _, b)) := BackendDAEUtil.mapEqSystemAndFold(inDAE, causal1, (repl, unReplaceable, false));
  outDAE := removeSimpleEquationsShared(b, outDAE, repl);
  // until remove simple equations does not update assignments and comps remove them
end causal;

protected function causal1 "author: Frenkel TUD 2012-12
  This function moves simple equations on the form a=b and a=const and 
  a=f(not time) in BackendDAE.BackendDAE to get speed up"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared, tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean>> sharedOptimized;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, tuple<BackendVarTransform.VariableReplacements, HashSet.HashSet, Boolean>> osharedOptimized;
algorithm
  (osyst, osharedOptimized):=
  match (isyst, sharedOptimized)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponents comps;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
      HashSet.HashSet unReplaceable;
      Boolean b, b1;
      array<list<Integer>> mT;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.EqSystem syst;
      BackendDAE.StateSets stateSets;
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, matching=BackendDAE.MATCHING(comps=comps), stateSets=stateSets), (shared, (repl, unReplaceable, b1)))
      equation
        mT = arrayCreate(BackendVariable.varsSize(vars), {});
        // check equations
        ((vars, shared, repl, unReplaceable, _, eqnslst, b)) =
          traverseComponents(comps, eqns, allCausalFinder,
            (vars, shared, repl, unReplaceable, mT, {}, false));
        syst = updateSystem(b, eqnslst, vars, stateSets, repl, isyst);
      then (syst, (shared, (repl, unReplaceable, b or b1)));
  end match;
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
      list<tuple<Integer, list<Integer>>> eqnvartpllst;
      Type_a arg;
    case ({}, _, _, _) then inTypeA;
    case (BackendDAE.SINGLEEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.equationNth0(iEqns, e-1);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp, disc_eqns=elst)::rest, _, _, _)
      equation
        // collect alle equations
        eqnlst = BackendEquation.getEqns(elst, iEqns);
        (elst, _) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        eqnlst1 = BackendEquation.getEqns(elst, iEqns);
        eqnlst = listAppend(eqnlst, eqnlst1);
        arg = inFunc(eqnlst, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst)::rest, _, _, _)
      equation
        eqnlst = BackendEquation.getEqns(elst, iEqns);
        arg = inFunc(eqnlst, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEARRAY(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.equationNth0(iEqns, e-1);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEIFEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.equationNth0(iEqns, e-1);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEALGORITHM(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.equationNth0(iEqns, e-1);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.equationNth0(iEqns, e-1);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e)::rest, _, _, _)
      equation
        eqn = BackendEquation.equationNth0(iEqns, e-1);
        arg = inFunc({eqn}, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
    case (BackendDAE.TORNSYSTEM(residualequations=elst, otherEqnVarTpl=eqnvartpllst)::rest, _, _, _)
      equation
        // collect alle equations
        eqnlst = BackendEquation.getEqns(elst, iEqns);
        elst = List.map(eqnvartpllst, Util.tuple21);
        eqnlst1 = BackendEquation.getEqns(elst, iEqns);
        eqnlst = listAppend(eqnlst, eqnlst1);
        arg = inFunc(eqnlst, inTypeA);
      then
        traverseComponents(rest, iEqns, inFunc, arg);
  end match;
end traverseComponents;

protected function allCausalFinder "author: Frenkel TUD 2012-12"
  input list<BackendDAE.Equation> eqns;
  input tuple<BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean> inTpl;
  output tuple<BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.Shared shared;
  BackendVarTransform.VariableReplacements repl;
  HashSet.HashSet unReplaceable;
  array<list<Integer>> mt;
  Boolean b, b1, b2;
  list<BackendDAE.Equation> globaleqnslst, eqnslst;
  list<SimpleContainer> simpleeqnslst;
algorithm
  (vars, shared, repl, unReplaceable, mt, globaleqnslst, b) := inTpl;
  (eqnslst, b2) := BackendVarTransform.replaceEquations(eqns, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
  ((_, _, eqnslst, simpleeqnslst, _, _, b1)) := List.fold(eqnslst, simpleEquationsFinder, (vars, shared, {}, {}, 1, mt, false));
  outTpl := allCausalFinder1(b1, b2, simpleeqnslst, eqnslst, vars, shared, repl, unReplaceable, mt, globaleqnslst, b);
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
  output tuple<BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean> oTpl;
algorithm
  oTpl:=
  match (foundSimple, didReplacement, iSimpleeqnslst, iEqnslst, iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      Boolean b1;
      array<SimpleContainer> simpleeqns;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
    case (false, _, _, {}, _, _, _, _, _, _, _)
      then ((iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, didReplacement or globalFoundSimple));
    case (false, _, _, _, _, _, _, _, _, _, _)
      then ((iVars, ishared, iRepl, iUnreplaceable, iMT, listAppend(iEqnslst, iGlobalEqnslst), didReplacement or globalFoundSimple));
    case (true, _, _, _, _, _, _, _, _, _, _)
      equation
        // transform simpleeqns to array
        simpleeqns = listArray(listReverse(iSimpleeqnslst));
        // collect and handle sets
        (vars, eqnslst, shared, repl) = handleSets(arrayLength(simpleeqns), 1, simpleeqns, iMT, iUnreplaceable, iVars, iEqnslst, ishared, iRepl);
        // perform replacements and try again
        (eqnslst, b1) = BackendVarTransform.replaceEquations(eqnslst, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
      then
        allCausalFinder2(b1, eqnslst, vars, shared, repl, iUnreplaceable, iMT, iGlobalEqnslst, true);
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
  output tuple<BackendDAE.Variables, BackendDAE.Shared, BackendVarTransform.VariableReplacements, HashSet.HashSet, array<list<Integer>>, list<BackendDAE.Equation>, Boolean> outTpl;
algorithm
  outTpl := match (b, iEqnslst, iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple)
    local
      Boolean b1;
      list<BackendDAE.Equation> eqnslst;
      list<SimpleContainer> simpleeqnslst;
      BackendDAE.Variables vars;
      BackendDAE.Shared shared;
    case(false, {}, _, _, _, _, _, _, _) then ((iVars, ishared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple));
    case(false, _, _, _, _, _, _, _, _) then ((iVars, ishared, iRepl, iUnreplaceable, iMT, listAppend(iEqnslst, iGlobalEqnslst), globalFoundSimple));
    case(true, _, _, _, _, _, _, _, _)
      equation
        ((vars, shared, eqnslst, simpleeqnslst, _, _, b1)) = List.fold(iEqnslst, simpleEquationsFinder, (iVars, ishared, {}, {}, 1, iMT, false));
      then
        allCausalFinder1(b1, false, simpleeqnslst, eqnslst, vars, shared, iRepl, iUnreplaceable, iMT, iGlobalEqnslst, globalFoundSimple);
  end match;
end allCausalFinder2;

/*
 * protected section
 *
 */

/*
 * functions to find simple equations
 */

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
      Boolean b, differentiated;
    case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, differentiated=differentiated), _)
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStrExpStr, ("Found Equation ", e1, " = ", e2, " to handle.\n"));
      then 
        simpleEquationAcausal(e1, e2, (source, differentiated), false, inTpl);
    
    case (BackendDAE.ARRAY_EQUATION(left=e1, right=e2, source=source, differentiated=differentiated), _)
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStrExpStr, ("Found Array Equation ", e1, " = ", e2, " to handle.\n"));
      then 
        simpleEquationAcausal(e1, e2, (source, differentiated), false, inTpl);
    
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=e2, source=source, differentiated=differentiated), _)
      equation
        e1 = Expression.crefExp(cr);
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStrExpStr, ("Found Solved Equation ", e1, " = ", e2, " to handle.\n"));
      then 
        simpleEquationAcausal(e1, e2, (source, differentiated), false, inTpl);
    
    case (BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source, differentiated=differentiated), _)
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStr, ("Found Residual Equation ", e1, " to handle.\n"));
      then 
        simpleExpressionAcausal(e1, (source, differentiated), false, inTpl);
    
    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, differentiated=differentiated), _)
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStrExpStr, ("Found Complex Equation ", e1, " = ", e2, " to handle.\n"));
      then 
        simpleEquationAcausal(e1, e2, (source, differentiated), false, inTpl);
    
    case (_, (v, s, eqns, seqns, index, mT, b))
      then ((v, s, eqn::eqns, seqns, index, mT, b));
   
   end matchcontinue;
end simpleEquationsFinder;

protected function simpleEquationAcausal "author Frenkel TUD 2012-12
  helper for simpleEquationsFinder"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationAttributes eqnAttributes;
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
    
    // a = b;
    case (DAE.CREF(componentRef = cr1), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, false, cr2, rhs, false, eqnAttributes, selfCalled, inTpl);
    
    // a = -b;
    case (DAE.CREF(componentRef = cr1), DAE.UNARY(DAE.UMINUS(ty), DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.UNARY(DAE.UMINUS(ty), lhs), false, cr2, rhs, true, eqnAttributes, selfCalled, inTpl);
    
    case (DAE.CREF(componentRef = cr1), DAE.UNARY(DAE.UMINUS_ARR(ty), DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.UNARY(DAE.UMINUS_ARR(ty), lhs), false, cr2, rhs, true, eqnAttributes, selfCalled, inTpl);
    
    // -a = b;
    case (DAE.UNARY(DAE.UMINUS(ty), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, true, cr2,  DAE.UNARY(DAE.UMINUS(ty), rhs), false, eqnAttributes, selfCalled, inTpl);
    
    case (DAE.UNARY(DAE.UMINUS_ARR(ty), e1 as DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, true, cr2,  DAE.UNARY(DAE.UMINUS_ARR(ty), rhs), false, eqnAttributes, selfCalled, inTpl);
    
    // -a = -b;
    case (DAE.UNARY(DAE.UMINUS(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS(_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    
    // a = not b;
    case (DAE.CREF(componentRef = cr1), DAE.LUNARY(DAE.NOT(ty), DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, DAE.LUNARY(DAE.NOT(ty), lhs), false, cr2, rhs, true, eqnAttributes, selfCalled, inTpl);
    
    // not a = b;
    case (DAE.LUNARY(DAE.NOT(ty), DAE.CREF(componentRef = cr1)), DAE.CREF(componentRef = cr2), _, _, _)
      then addSimpleEquationAcausal(cr1, lhs, true, cr2, DAE.LUNARY(DAE.NOT(ty), lhs), false, eqnAttributes, selfCalled, inTpl);
    
    // not a = not b;
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = cr1)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    
    // {a1, a2, a3, ..} = {b1, b2, b3, ..};
    case (DAE.ARRAY(array = elst1), DAE.ARRAY(array = elst2), _, _, _)
      then List.threadFold2(elst1, elst2, simpleEquationAcausal, eqnAttributes, true, inTpl);
    
    case (DAE.MATRIX(matrix = elstlst1), DAE.MATRIX(matrix = elstlst2), _, _, _)
      then List.threadFold2(elstlst1, elstlst2, simpleEquationAcausalLst, eqnAttributes, true, inTpl);
    
    // a = {b1, b2, b3, ..}
    case (DAE.CREF(componentRef = _), DAE.ARRAY(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.CREF(componentRef = _), DAE.MATRIX(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // -a = {b1, b2, b3, ..}
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.ARRAY(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.MATRIX(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // a = -{b1, b2, b3, ..}
    case (DAE.CREF(componentRef = _), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.CREF(componentRef = _), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // -a = -{b1, b2, b3, ..}
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = _)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = _)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    // {a1, a2, a3, ..} = b
    case (DAE.ARRAY(ty=ty), DAE.CREF(componentRef = _), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.MATRIX(ty=ty), DAE.CREF(componentRef = _), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // -{a1, a2, a3, ..} = b
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.ARRAY(ty=ty)), DAE.CREF(componentRef = _), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.MATRIX(ty=ty)), DAE.CREF(componentRef = _), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // {a1, a2, a3, ..} = -b
    case (DAE.ARRAY(ty=ty), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.MATRIX(ty=ty), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // -{a1, a2, a3, ..} = -b
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.ARRAY(ty=ty)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    case (DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.MATRIX(ty=ty)), DAE.UNARY(DAE.UMINUS_ARR(_), e2 as DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    // not a = {b1, b2, b3, ..}
    case (DAE.LUNARY(DAE.NOT(_), DAE.CREF(componentRef = _)), DAE.ARRAY(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.LUNARY(DAE.NOT(_), DAE.CREF(componentRef = _)), DAE.MATRIX(ty=ty), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // a = not {b1, b2, b3, ..}
    case (DAE.CREF(componentRef = _), DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.CREF(componentRef = _), DAE.LUNARY(DAE.NOT(_), DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // not a = not {b1, b2, b3, ..}
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = _)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.CREF(componentRef = _)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    // {a1, a2, a3, ..} = not b
    case (DAE.ARRAY(ty=ty), DAE.LUNARY(DAE.NOT(_), DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.MATRIX(ty=ty), DAE.LUNARY(DAE.NOT(_), DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // not {a1, a2, a3, ..} = b
    case (DAE.LUNARY(DAE.NOT(_), DAE.ARRAY(ty=ty)), DAE.CREF(componentRef = _), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    case (DAE.LUNARY(DAE.NOT(_), DAE.MATRIX(ty=ty)), DAE.CREF(componentRef = _), _, _, _)
      then simpleArrayEquationAcausal(lhs, rhs, ty, eqnAttributes, inTpl);
    
    // not {a1, a2, a3, ..} = not b
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.ARRAY(ty=ty)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = _)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    case (DAE.LUNARY(DAE.NOT(_), e1 as DAE.MATRIX(ty=ty)), DAE.LUNARY(DAE.NOT(_), e2 as DAE.CREF(componentRef = _)), _, _, _)
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
  input EquationAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
protected
  DAE.Dimensions dims;
  list<Integer> ds;
  list<Option<Integer>> ad;
  list<list<DAE.Subscript>> subslst;
  list<DAE.Exp> elst1, elst2;
algorithm
  dims := Expression.arrayDimension(ty);
  ds := Expression.dimensionsSizes(dims);
  ad := List.map(ds, Util.makeOption);
  subslst := BackendDAEUtil.arrayDimensionsToRange(ad);
  subslst := BackendDAEUtil.rangesToSubscripts(subslst);
  elst1 := List.map1r(subslst, Expression.applyExpSubscripts, lhs);
  elst2 := List.map1r(subslst, Expression.applyExpSubscripts, rhs);
  outTpl := List.threadFold2(elst1, elst2, simpleEquationAcausal, eqnAttributes, true, inTpl);
end simpleArrayEquationAcausal;

protected function simpleEquationAcausalLst "author: Frenkel TUD 2012-12
  helper for simpleEquationAcausal"
  input list<DAE.Exp> elst1;
  input list<DAE.Exp> elst2;
  input EquationAttributes eqnAttributes;
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
  input EquationAttributes eqnAttributes;
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
      equation
        true = Expression.isZero(rhs);
      then List.fold2(elst1, simpleExpressionAcausal, eqnAttributes, true, inTpl);
    // 0 = {a1+b1, a2+b2, a3+b3, ..};
    case (_, DAE.ARRAY(array = elst2), _, _, _)
      equation
        true = Expression.isZero(lhs);
      then List.fold2(elst2, simpleExpressionAcausal, eqnAttributes, true, inTpl);
     // lhs = 0
    case (_, _, _, _, _)
      equation
        true = Expression.isZero(rhs);
      then simpleExpressionAcausal(lhs, eqnAttributes, selfCalled, inTpl);
    // 0 = rhs
    case (_, _, _, _, _)
      equation
        true = Expression.isZero(lhs);
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
  input EquationAttributes eqnAttributes;
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
      Boolean b, b1, b2, differentiated;
      DAE.ElementSource source;
    // complex types to complex equations
    case (_, _, _, (source, differentiated), (v, s, eqns, seqns, index, mT, b))
      equation
        true = DAEUtil.expTypeComplex(ty);
        size = Expression.sizeOf(ty);
        //  print("Add Equation:\n" +& BackendDump.equationStr(BackendDAE.COMPLEX_EQUATION(size, lhs, rhs, source)) +& "\n");
       then
        ((v, s, BackendDAE.COMPLEX_EQUATION(size, lhs, rhs, source, differentiated)::eqns, seqns, index, mT, b));
    // array types to array equations
    case (_, _, _, (source, differentiated), (v, s, eqns, seqns, index, mT, b))
      equation
        true = DAEUtil.expTypeArray(ty);
        dims = Expression.arrayDimension(ty);
        ds = Expression.dimensionsSizes(dims);
        //  print("Add Equation:\n" +& BackendDump.equationStr(BackendDAE.ARRAY_EQUATION(ds, lhs, rhs, source)) +& "\n");
      then
        ((v, s, BackendDAE.ARRAY_EQUATION(ds, lhs, rhs, source, differentiated)::eqns, seqns, index, mT, b));
    // other types
    case (_, _, _, (source, differentiated), (v, s, eqns, seqns, index, mT, b))
      equation
        b1 = DAEUtil.expTypeComplex(ty);
        b2 = DAEUtil.expTypeArray(ty);
        false = b1 or b2;
        //  print("Add Equation:\n" +& BackendDump.equationStr(BackendDAE.EQUATION(lhs, rhs, source)) +& "\n");
        //Error.assertionOrAddSourceMessage(not b1, Error.INTERNAL_ERROR, {str}, Absyn.dummyInfo);
      then
        ((v, s, BackendDAE.EQUATION(lhs, rhs, source, differentiated)::eqns, seqns, index, mT, b));
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAEOptimize.generateEquation failed on: " +& ExpressionDump.printExpStr(lhs) +& " = " +& ExpressionDump.printExpStr(rhs) +& "\n");
      then
        fail();
  end matchcontinue;
end generateEquation;

protected function simpleExpressionAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp exp;
  input EquationAttributes eqnAttributes;
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
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.SUB(ty=_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = cr1), DAE.SUB_ARR(ty=_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    
    // -a + b = 0 => a = b
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ADD(ty=_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = cr1)), DAE.ADD_ARR(ty=_), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, false, cr2, e2, false, eqnAttributes, selfCalled, inTpl);
    
    // -a - b = 0 => -a = b
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = cr1)), DAE.SUB(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, true, cr2, DAE.UNARY(DAE.UMINUS(ty), e2), false, eqnAttributes, selfCalled, inTpl);
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = cr1)), DAE.SUB_ARR(ty=ty), e2 as DAE.CREF(componentRef = cr2)), _, _, _)
      then addSimpleEquationAcausal(cr1, e1, true, cr2,  DAE.UNARY(DAE.UMINUS_ARR(ty), e2), false, eqnAttributes, selfCalled, inTpl);

    // a + {b1, b2, b3} = 0 => a = -{b1, b2, b3}
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _), DAE.ADD_ARR(tp), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(tp), e2), ty, eqnAttributes, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _), DAE.ADD_ARR(tp), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(tp), e2), ty, eqnAttributes, inTpl);
    
    // a - {b1, b2, b3} = 0 => a = {b1, b2, b3}
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _), DAE.SUB_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _), DAE.SUB_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    // -a + {b1, b2, b3} = 0 => a = {b1, b2, b3}
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = _)), DAE.ADD_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), e1 as DAE.CREF(componentRef = _)), DAE.ADD_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, e2, ty, eqnAttributes, inTpl);
    
    // -a - {b1, b2, b3} = 0 => -a = {b1, b2, b3}
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.SUB_ARR(_), e2 as DAE.ARRAY(ty=ty)), _, _, _)
      then simpleArrayEquationAcausal(e1, DAE.UNARY(DAE.UMINUS_ARR(ty), e2), ty, eqnAttributes, inTpl);
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.SUB_ARR(_), e2 as DAE.MATRIX(ty=ty)), _, _, _)
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
  input EquationAttributes eqnAttributes;
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
    
    case(_, _, _, _, _, _, _, _, (vars, shared, eqns, seqns, index, mT, b))
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrCrefStr, ("Alias Equation ", cr1, " = ", cr2, " found. Negated lhs[" +& boolString(negatedCr1) +& "] = rhs[" +& boolString(negatedCr2) +& "].\n"));
        // get Variables
        (vars1, ilst1, varskn1, time1) = getVars(cr1, vars, shared);
        (vars2, ilst2, varskn2, time2) = getVars(cr2, vars, shared);
        // add to Simple Equations List
        (seqns, index, mT) = generateSimpleContainters(vars1, negatedCr1, ilst1, varskn1, time1, vars2, negatedCr2, ilst2, varskn2, time2, eqnAttributes, seqns, index, mT);
      then
        ((vars, shared, eqns, seqns, index, mT, true));
    
    case(_, _, _, _, _, _, _, true, _)
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStrExpStr, ("Non Alias Equation ", inE1, " = ", inE2, " to generate.\n"));
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
      equation
        (oVars as _::_, oIndexs) = BackendVariable.getVarShared(cr, shared);
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
  input EquationAttributes eqnAttributes;
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
        _ = arrayUpdate(iMT, i2, iIndex::colum);
      then
        (TIMEALIAS(cr2, negatedCr2, i2, cr1, negatedCr1, i1, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);
    
    case ({BackendDAE.VAR(varName=cr1)}, _, {i1}, false, false, {BackendDAE.VAR(varName=cr2)}, _, {i2}, true, true, _, _, _, _)
      equation
        colum = iMT[i1];
        _ = arrayUpdate(iMT, i1, iIndex::colum);
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
  input EquationAttributes eqnAttributes;
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
      String msg;
      DAE.ElementSource source;
    
    case (BackendDAE.VAR(varName=cr1), _, _, false, BackendDAE.VAR(varName=cr2), _, _, false, _, _, _, _)
      equation
        checkEqualAlias(intEq(i1, i2), v1, negatedCr1, v2, negatedCr2, eqnAttributes);
        colum = iMT[i1];
        _ = arrayUpdate(iMT, i1, iIndex::colum);
        colum = iMT[i2];
        _ = arrayUpdate(iMT, i2, iIndex::colum);
      then
        (ALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);
    
    case (BackendDAE.VAR(varName=cr1), _, _, true, BackendDAE.VAR(varName=cr2), _, _, false, _, _, _, _)
      equation
        colum = iMT[i2];
        _ = arrayUpdate(iMT, i2, iIndex::colum);
      then
        (PARAMETERALIAS(cr2, negatedCr2, i2, cr1, negatedCr1, i1, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);
    
    case (BackendDAE.VAR(varName=cr1), _, _, false, BackendDAE.VAR(varName=cr2), _, _, true, _, _, _, _)
      equation
        colum = iMT[i1];
        _ = arrayUpdate(iMT, i1, iIndex::colum);
      then
        (PARAMETERALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, eqnAttributes, -1)::iSeqns, iIndex+1, iMT);
    
    case (BackendDAE.VAR(varName=cr1), _, _, true, BackendDAE.VAR(varName=cr2), _, _, true, (source, _), _, _, _)
      equation
        crexp1 = Expression.crefExp(cr1);
        crexp2 = Expression.crefExp(cr2);
        crexp1 = negateExpression(negatedCr1, crexp1, crexp1, " generateSimpleContainter ");
        crexp2 = negateExpression(negatedCr2, crexp2, crexp2, " generateSimpleContainter ");
        msg = "Found Equation without time dependent variables ";
        msg = msg +& ExpressionDump.printExpStr(crexp1) +& " = " +& ExpressionDump.printExpStr(crexp2) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
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
  input EquationAttributes eqnAttributes;
algorithm
  _ := match(equal, v1, negatedCr1, v2, negatedCr2, eqnAttributes)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp crexp1, crexp2;
      String eqn_str, var_str;
      Absyn.Info info;
      DAE.ElementSource source;
    
    case(false, _, _, _, _, _) then ();
    
    case(true, BackendDAE.VAR(varName=cr1), _, BackendDAE.VAR(varName=cr2), _, (source, _))
      equation
        var_str = BackendDump.varString(v1);
        crexp1 = Expression.crefExp(cr1);
        crexp2 = Expression.crefExp(cr2);
        crexp1 = negateExpression(negatedCr1, crexp1, crexp1, " checkEqualAlias ");
        crexp2 = negateExpression(negatedCr2, crexp2, crexp2, " checkEqualAlias ");
        eqn_str = ExpressionDump.printExpStr(crexp1) +& " = " +& ExpressionDump.printExpStr(crexp2) +& "\n";
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str, var_str}, info);
      then
        fail();
  
  end match;
end checkEqualAlias;

protected function timeIndependentEquationAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (lhs, rhs, eqnAttributes, selfCalled, inTpl)
    local
      DAE.Type ty;
      BackendDAE.Variables vars, knvars;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
    // a = const
    // wbraun:
    // speacial case for Jacobains, since there are all known variablen
    // time depending input variables
    case (_, _, _, _, (vars, BackendDAE.SHARED(knownVars=knvars, backendDAEType = BackendDAE.JACOBIAN()), _, _, _, _, _))
      equation
        // collect vars and check if variable time not there
        ((_, (false, _, _, _, _, ilst))) = Expression.traverseExpTopDown(lhs, traversingTimeVarsFinder, (false, vars, knvars, true, false, {}));
        ((_, (false, _, _, _, _, ilst))) = Expression.traverseExpTopDown(rhs, traversingTimeVarsFinder, (false, vars, knvars, true, false, ilst));
        ilst = List.uniqueIntN(ilst, BackendVariable.varsSize(vars));
        vlst = List.map1r(ilst, BackendVariable.getVarAt, vars);
      then
        solveTimeIndependentAcausal(vlst, ilst, lhs, rhs, eqnAttributes, inTpl);
    case (_, _, _, _, (vars, BackendDAE.SHARED(knownVars=knvars), _, _, _, _, _))
      equation
        // collect vars and check if variable time not there
        ((_, (false, _, _, _, _, ilst))) = Expression.traverseExpTopDown(lhs, traversingTimeVarsFinder, (false, vars, knvars, false, false, {}));
        ((_, (false, _, _, _, _, ilst))) = Expression.traverseExpTopDown(rhs, traversingTimeVarsFinder, (false, vars, knvars, false, false, ilst));
        ilst = List.uniqueIntN(ilst, BackendVariable.varsSize(vars));
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
  input EquationAttributes eqnAttributes;
  input Boolean selfCalled "this is a flag to know if we are selfcalled to save memory in case of non simple equation";
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (exp, eqnAttributes, selfCalled, inTpl)
    local
      DAE.Exp e2;
      DAE.Type ty;
      BackendDAE.Variables vars, knvars;
      list<Integer> ilst;
      list<BackendDAE.Var> vlst;
    case (_, _, _, (vars, BackendDAE.SHARED(knownVars=knvars, backendDAEType = BackendDAE.JACOBIAN()), _, _, _, _, _))
      equation
        // collect vars and check if variable time not there
        ((_, (false, _, _, _, _, ilst))) = Expression.traverseExpTopDown(exp, traversingTimeVarsFinder, (false, vars, knvars, true, false, {}));
        ilst = List.uniqueIntN(ilst, BackendVariable.varsSize(vars));
        vlst = List.map1r(ilst, BackendVariable.getVarAt, vars);
      then
        // shoulde be ok since solve checks only for iszero
        solveTimeIndependentAcausal(vlst, ilst, exp, DAE.RCONST(0.0), eqnAttributes, inTpl);
    case (_, _, _, (vars, BackendDAE.SHARED(knownVars=knvars), _, _, _, _, _))
      equation
        // collect vars and check if variable time not there
        ((_, (false, _, _, _, _, ilst))) = Expression.traverseExpTopDown(exp, traversingTimeVarsFinder, (false, vars, knvars, false, false, {}));
        ilst = List.uniqueIntN(ilst, BackendVariable.varsSize(vars));
        vlst = List.map1r(ilst, BackendVariable.getVarAt, vars);
      then
        // shoulde be ok since solve checks only for iszero
        solveTimeIndependentAcausal(vlst, ilst, exp, DAE.RCONST(0.0), eqnAttributes, inTpl);
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
  return true is var on topliven and input or is unfixed parameter"
  input BackendDAE.Var inVar;
  output Boolean b;
algorithm
  b := BackendVariable.isVarOnTopLevelAndInput(inVar) or
       BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar);
end toplevelInputOrUnfixed;

protected function traversingTimeVarsFinder "author: Frenkel 2012-12"
  input tuple<DAE.Exp, tuple<Boolean, BackendDAE.Variables, BackendDAE.Variables, Boolean, Boolean, list<Integer>> > inExp;
  output tuple<DAE.Exp, Boolean, tuple<Boolean, BackendDAE.Variables, BackendDAE.Variables, Boolean, Boolean, list<Integer>> > outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e;
      Boolean b, b1, b2;
      BackendDAE.Variables vars, knvars;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<Integer> ilst, vlst;
      list<BackendDAE.Var> varlst;

    case((e as DAE.CREF(DAE.CREF_IDENT(ident = "time", subscriptLst = {}), _), (_, vars, knvars, b1, b2, ilst)))
      then ((e, false, (true, vars, knvars, b1, b2, ilst)));
    case((e as DAE.CREF(cr, _), (_, vars, knvars, b1, b2, ilst)))
      equation
        (varlst, _::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        false = List.mapAllValueBool(varlst, toplevelInputOrUnfixed, false);
      then ((e, false, (true, vars, knvars, b1, b2, ilst)));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "sample")), (_, vars, knvars, b1, b2, ilst))) then ((e, false, (true, vars, knvars, b1, b2, ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "pre")), (_, vars, knvars, b1, b2, ilst))) then ((e, false, (true, vars, knvars, b1, b2, ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "change")), (_, vars, knvars, b1, b2, ilst))) then ((e, false, (true, vars, knvars, b1, b2, ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "edge")), (_, vars, knvars, b1, b2, ilst))) then ((e, false, (true, vars, knvars, b1, b2, ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "delay")), (_, vars, knvars, b1, b2, ilst))) then ((e, false, (true, vars, knvars, b1, b2, ilst) ));
    case((e as DAE.CALL(path = Absyn.IDENT(name = "terminal")), (_, vars, knvars, b1, b2, ilst))) then ((e, false, (true, vars, knvars, b1, b2, ilst) ));
    // case for finding simple equation in jacobians
    // there are all known variables mark as input
    // and they are all time-depending
    case((e as DAE.CREF(cr, _), (_, vars, knvars, true, b2, ilst)))
      equation
        (var::_, _::_)= BackendVariable.getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
        DAE.INPUT() = BackendVariable.getVarDirection(var);
      then ((e, false, (true, vars, knvars, true, b2, ilst)));
    // var
    case((e as DAE.CREF(cr, _), (b, vars, knvars, b1, b2, ilst)))
      equation
        (var::_, vlst)= BackendVariable.getVar(cr, vars);
        ilst = listAppend(ilst, vlst);
      then ((e, true, (b, vars, knvars, b1, b2, ilst)));
    case((e, (b, vars, knvars, b1, b2, ilst))) then ((e, not b, (b, vars, knvars, b1, b2, ilst)));

  end matchcontinue;
end traversingTimeVarsFinder;

protected function solveTimeIndependentAcausal "author: Frenkel TUD 2012-12
  helper for simpleEquationsAcausal"
  input list<BackendDAE.Var> vlst;
  input list<Integer> ilst;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := match (vlst, ilst, lhs, rhs, eqnAttributes, inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp cre, es, lhs1, rhs1;
      BackendDAE.Var v;
      Integer i, size;
      DAE.FunctionTree functionTree;
      DAE.ElementSource source;
      Boolean diffed;
    case ({v as BackendDAE.VAR(varName=cr)}, {i}, _, _, _, _)
      equation
        // try to solve the equation
        cre = Expression.crefExp(cr);
        (es, {}) = ExpressionSolve.solve(lhs, rhs, cre);
        // constant or alias
      then
        constOrAliasAcausal(v, i, cr, es, eqnAttributes, inTpl);
    case (_, _, _, _, (source, diffed), (_, BackendDAE.SHARED(functionTree=functionTree), _, _, _, _, _))
      equation
        // size of equation have to be equal with number of vars
        size = Expression.sizeOf(Expression.typeof(lhs));
        true = intEq(size, listLength(vlst));
        // force inline
        (lhs1, source, _) = Inline.forceInlineExp(lhs, (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
        (rhs1, source, _) = Inline.forceInlineExp(rhs, (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
      then
        solveTimeIndependentAcausal1(vlst, ilst, lhs1, rhs1, (source, diffed), inTpl);
  end match;
end solveTimeIndependentAcausal;

protected function solveTimeIndependentAcausal1 "author: Frenkel TUD 2012-12
  helper for simpleEquations"
  input list<BackendDAE.Var> vlst;
  input list<Integer> ilst;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input EquationAttributes eqnAttributes;
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
  input EquationAttributes eqnAttributes;
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
  input EquationAttributes eqnAttributes;
  input AccTuple inTpl;
  output AccTuple outTpl;
algorithm
  outTpl := matchcontinue (var, i, cr, exp, eqnAttributes, inTpl)
    local
      BackendDAE.Variables vars, knvars;
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
    // alias a
    case (_, _, _, _, _, (vars, shared, eqns, seqns, index, mT, b))
      equation
        // alias
        (negated, cra) = aliasExp(exp);
        // get Variables
        knvars = BackendVariable.daeKnVars(shared);
        (vars2, ilst2) = BackendVariable.getVar(cra, knvars);
        // add to Simple Equations List
        (seqns, index, mT) = generateSimpleContainters({var}, false, {i}, false, false, vars2, negated, ilst2, true, false, eqnAttributes, seqns, index, mT);
      then
         ((vars, shared, eqns, seqns, index, mT, true));
    // const
    case (_, _, _, _, _, (vars, shared, eqns, seqns, index, mT, b))
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Const Equation ", cr, " = ", exp, " found.\n"));
        colum = mT[i];
        _ = arrayUpdate(mT, i, index::colum);
      then
        ((vars, shared, eqns, TIMEINDEPENTVAR(cr, i, exp, eqnAttributes, -1)::seqns, index+1, mT, true));
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
  input Integer index "downwarts";
  input Integer inMark;
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
algorithm
  (oVars, oEqnslst, oshared, oRepl) := match (index, inMark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl)
    local
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      Integer mark;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
    case (0, _, _, _, _, _, _, _, _) then (iVars, iEqnslst, ishared, iRepl);
    else
      equation
        (mark, vars, eqnslst, shared, repl) = handleSetsWork(intGt(getVisited(simpleeqnsarr[index]), 0), index, inMark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl);
        (vars, eqnslst, shared, repl) = handleSets(index-1, mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl);
      then
        (vars, eqnslst, shared, repl);
  end match;
end handleSets;

protected function handleSetsWork "author: Frenkel TUD 2012-12
  convert the found simple equtions to replacements and remove the simple 
  variabes from the variables"
  input Boolean isVisited;
  input Integer index "downwarts";
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
  input HashSet.HashSet unReplaceable;
  input BackendDAE.Variables iVars;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Shared iShared;
  input BackendVarTransform.VariableReplacements iRepl;
  output Integer oMark;
  output BackendDAE.Variables oVars;
  output list<BackendDAE.Equation> oEqnslst;
  output BackendDAE.Shared oshared;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oMark, oVars, oEqnslst, oshared, oRepl) := match (isVisited, index, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, iShared, iRepl)
    local
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;

      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqnslst;
      BackendDAE.Shared shared;
      BackendVarTransform.VariableReplacements repl;
    
    case (true, _, _, _, _, _, _, _, _, _)
      then (mark, iVars, iEqnslst, iShared, iRepl);
    
    else
      equation
        // collect set
        (rmax, smax, unremovable, const, _) = getAlias({index}, NONE(), mark, simpleeqnsarr, iMT, iVars, unReplaceable, false, {}, NONE(), NONE(), NONE(), NONE());
        // traverse set and add replacements, move vars, ...
        (vars, eqnslst, shared, repl) = handleSet(rmax, smax, unremovable, const, mark+1, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, iShared, iRepl);
      then (mark+2, vars, eqnslst, shared, repl);
  
  end match;
end handleSetsWork;

protected function getAlias "author: Frenkel TUD 2012-12
  traverse the simple tree to find the variable we keep"
  input list<Integer> rows;
  input Option<Integer> i;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
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
  (oRmax, oSmax, oUnremovable, oConst, oContinue) := match(rows, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      Integer r;
      list<Integer> rest;
      SimpleContainer s;
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      Boolean b, continue;
    
    case ({}, _, _, _, _, _, _, _, _, _, _, _, _) then (iRmax, iSmax, iUnremovable, iConst, true);
    
    case (r::rest, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        s = simpleeqnsarr[r];
        b = isVisited(mark, s);
        (rmax, smax, unremovable, const, continue) = getAlias1(b, s, r, rest, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst);
      then
        (rmax, smax, unremovable, const, continue);
  
  end match;
end getAlias;

protected function getAlias1 "author: Frenkel TUD 2012-12"
  input Boolean visited;
  input SimpleContainer s;
  input Integer r;
  input list<Integer> rows;
  input Option<Integer> i;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
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
  matchcontinue(visited, s, r, rows, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      Boolean continue;
      String msg;
      DAE.ComponentRef cr;
    
    case (false, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // set visited
        _= arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
        // check alias connection
        (rmax, smax, unremovable, const, continue) = getAlias2(s, r, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, r::stack, iRmax, iSmax, iUnremovable, iConst);
        // next arm
        (rmax, smax, unremovable, const, continue) = getAliasContinue(continue, rows, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, rmax, smax, unremovable, const);
      then
        (rmax, smax, unremovable, const, continue);
    
    // valid circular equality
    case (true, _, _, _, _, _, _, _, _, _, true, _, _, _, SOME(_), _)
      equation
        // is only valid for real or int
        ALIAS(cr1=cr) = simpleeqnsarr[r];
        true = Types.isIntegerOrRealOrSubTypeOfEither(ComponentReference.crefLastType(cr));
      then
        (NONE(), NONE(), NONE(), iUnremovable, false);
    
    case (true, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _)
      equation
        // is only valid for real or int
        ALIAS(cr1=cr) = simpleeqnsarr[r];
        true = Types.isIntegerOrRealOrSubTypeOfEither(ComponentReference.crefLastType(cr));
      then
        (NONE(), NONE(), NONE(), SOME(r), false);
    
    case (true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        msg = "Circular Equalities Detected for Variables:\n";
        msg = circularEqualityMsg(stack, r, simpleeqnsarr, msg);
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
  oMsg := matchcontinue(stack, iR, simpleeqnsarr, iMsg)
    local
      Integer r;
      list<Integer> rest;
      String msg;
      list<DAE.ComponentRef> names;
      list<String> slst;
    case ({}, _, _, _) then iMsg;
    case (r::rest, _, _, _)
      equation
        false = intEq(r, iR);
        names = getVarsNames(simpleeqnsarr[r]);
        slst = List.map(names, ComponentReference.printComponentRefStr);
        slst = listAppend(slst, {"----------------------------------"});
        slst = listAppend(iMsg, slst);
      then
        circularEqualityMsg_dispatch(rest, iR, simpleeqnsarr, slst);
    
    case (r::rest, _, _, _)
      equation
        true = intEq(r, iR);
      then
        iMsg;
  
  end matchcontinue;
end circularEqualityMsg_dispatch;

protected function getVarsNames "author: Frenkel TUD 2013-05"
  input SimpleContainer iS;
  output list<DAE.ComponentRef> names;
algorithm
  names := match(iS)
    local
      DAE.ComponentRef cr1, cr2;
      Integer i1, i2;
      EquationAttributes eqnAttributes;
      Boolean negate;
      DAE.Exp exp;
    case (ALIAS(cr1=cr1, cr2=cr2)) then {cr1, cr2};
    case (PARAMETERALIAS(unknowncr=cr1, paramcr=cr2)) then {cr1, cr2};
    case (TIMEALIAS(cr1=cr1,cr2=cr2)) equation  then {cr1, cr2};
    case (TIMEINDEPENTVAR(cr=cr1)) then {cr1};
  end match;
end getVarsNames;

protected function getAlias2 "author: Frenkel TUD 2012-12"
  input SimpleContainer s;
  input Integer r;
  input Option<Integer> oi;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
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
  match(s, r, oi, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      list<Integer> next;
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      BackendDAE.Var v;
      Integer i1, i2, i;
      Boolean state, replaceable_, continue, replaceble1, neg, negatedCr1, negatedCr2;
    
    case (ALIAS(i1=i1, negatedCr1=negatedCr1, i2=i2, negatedCr2=negatedCr2), _, NONE(), _, _, _, _, _, _, _, _, _, _, _)
      equation
        // collect next rows
        neg = boolOr(negatedCr1, negatedCr2);
        next = List.removeOnTrue(r, intEq, iMT[i1]);
        v = BackendVariable.getVarAt(vars, i1);
        // update max
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
        state = BackendVariable.isStateVar(v);
        (rmax, smax, unremovable) = getAlias3(v, i1, state, replaceable_ and replaceble1, r, iRmax, iSmax, iUnremovable);
        // go deeper
        neg = Util.if_(neg, not negate, negate);
        (rmax, smax, unremovable, const, continue) = getAlias(next, SOME(i1), mark, simpleeqnsarr, iMT, vars, unReplaceable, neg, stack, rmax, smax, unremovable, iConst);
        // collect next rows
        next = List.removeOnTrue(r, intEq, iMT[i2]);
        v = BackendVariable.getVarAt(vars, i2);
        // update max
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
        state = BackendVariable.isStateVar(v);
        (rmax, smax, unremovable) = getAlias3(v, i2, state, replaceable_ and replaceble1, r, rmax, smax, unremovable);
        // go deeper
        (rmax, smax, unremovable, const, continue) = getAliasContinue(continue, next, SOME(i2), mark, simpleeqnsarr, iMT, vars, unReplaceable, neg, stack, rmax, smax, unremovable, const);
       then
         (rmax, smax, unremovable, const, continue);
    
    case (ALIAS(i1=i1, negatedCr1=negatedCr1, i2=i2, negatedCr2=negatedCr2), _, SOME(i), _, _, _, _, _, _, _, _, _, _, _)
      equation
        i = Util.if_(intEq(i, i1), i2, i1);
        neg = boolOr(negatedCr1, negatedCr2);
        // collect next rows
        next = List.removeOnTrue(r, intEq, iMT[i]);
        v = BackendVariable.getVarAt(vars, i);
        // update max
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
        state = BackendVariable.isStateVar(v);
        (rmax, smax, unremovable) = getAlias3(v, i, state, replaceable_ and replaceble1, r, iRmax, iSmax, iUnremovable);
        // go deeper
        neg = Util.if_(neg, not negate, negate);
        (rmax, smax, unremovable, const, continue) = getAlias(next, SOME(i), mark, simpleeqnsarr, iMT, vars, unReplaceable, neg, stack, rmax, smax, unremovable, iConst);
       then
         (rmax, smax, unremovable, const, continue);
    
    case (PARAMETERALIAS(visited=_), _, _, _, _, _, _, _, _, _, _, _, _, _)
       then
        (NONE(), NONE(), NONE(), SOME(r), false);
    
    case (TIMEALIAS(visited=_), _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (NONE(), NONE(), NONE(), SOME(r), false);
    
    case (TIMEINDEPENTVAR(visited=_), _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (NONE(), NONE(), NONE(), SOME(r), false);
  
  end match;
end getAlias2;

protected function getAlias3 "author: Frenkel TUD 2012-12"
  input BackendDAE.Var var;
  input Integer i;
  input Boolean state;
  input Boolean replaceable_;
  input Integer r;
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  output Option<tuple<Integer, Integer>> oRmax;
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
        tpl = Util.if_(intGt(w1, w2), SOME((i, w1)), iSmax);
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
        tpl = Util.if_(intLt(w1, w2), SOME((i, w1)), iRmax);
      then
        (tpl, iSmax, iUnremovable);
  end match;
end getAlias3;

protected function getAliasContinue
"author: Frenkel TUD 2012-12"
  input Boolean iContinue;
  input list<Integer> rows;
  input Option<Integer> i;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input array<list<Integer>> iMT;
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
  match(iContinue, rows, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst)
    local
      Option<tuple<Integer, Integer>> rmax, smax;
      Option<Integer> unremovable, const;
      Boolean continue;
    case (true, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // update candidates
        (rmax, smax, unremovable, const, continue) = getAlias(rows, i, mark, simpleeqnsarr, iMT, vars, unReplaceable, negate, stack, iRmax, iSmax, iUnremovable, iConst);
      then
        (rmax, smax, unremovable, const, continue);
    case (false, _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (iRmax, iSmax, iUnremovable, iConst, iContinue);
  end match;
end getAliasContinue;

protected function appendNextRow "author: Frenkel TUD 2012-12"
  input Integer nr;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input list<Integer> iNext;
  output list<Integer> oNext;
algorithm
  oNext := List.consOnTrue(intNe(getVisited(simpleeqnsarr[nr]), mark), nr, iNext);
end appendNextRow;

protected function isVisited "author: Frenkel TUD 2012-12"
  input Integer mark;
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
      EquationAttributes eqnAttributes;
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
    
    case (BackendDAE.VAR(varName=cr, varKind=kind), _)
      equation
        BackendVariable.isVarKindVariable(kind) "cr1 not constant";
        false = BackendVariable.isVarOnTopLevelAndOutput(var);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
        cr = ComponentReference.crefStripLastSubs(cr);
        b = not BaseHashSet.has(cr, unReplaceable);
      then
        (true, b);
    
    else
      then
        (false, false);
  
  end matchcontinue;
end replaceableAlias;

protected function handleSet "author: Frenkel TUD 2012-12
  traverse an equations system to remove simple equations"
  input Option<tuple<Integer, Integer>> iRmax;
  input Option<tuple<Integer, Integer>> iSmax;
  input Option<Integer> iUnremovable;
  input Option<Integer> iConst;
  input Integer mark;
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
algorithm
  (oVars, oEqnslst, oshared, oRepl):=
  matchcontinue (iRmax, iSmax, iUnremovable, iConst, mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl)
    local
      SimpleContainer s;
      Integer r, i1, i2, i;
      BackendDAE.Var v, pv;
      DAE.ComponentRef pcr, cr1, cr2, cr;
      EquationAttributes eqnAttributes;
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
       _= arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       negated = boolOr(negatedCr1, negatedCr2);
       // generate exp from cref an negate if necessary
       exp = Expression.crefExp(cr2);
       exp2 = negateExpression(negated, exp, exp, " PARAMETERALIAS ");
       v = BackendVariable.getVarAt(iVars, i1);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
       (vars, eqnslst, shared, repl) = handleSetVar(replaceable_ and replaceble1, SOME(DAE.RCONST(0.0)), v, i1, eqnAttributes, exp2, iMT, iVars, iEqnslst, ishared, iRepl);
       expcr = Expression.crefExp(cr1);
       pv = BackendVariable.getVarSharedAt(i2, ishared);
       vsattr = addVarSetAttributes(pv, negated, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       vsattr = Debug.bcallret5(replaceable_ and replaceble1, addVarSetAttributes, v, negated, mark, simpleeqnsarr, vsattr, vsattr);
       rows = List.removeOnTrue(r, intEq, iMT[i1]);
       _ = arrayUpdate(iMT, i1, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i1, exp, SOME(expcr), negated, SOME(DAE.RCONST(0.0)), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);
   
   // time set
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       // for time alias the time variable is *ALWAYS* the second 
       TIMEALIAS(cr1=cr1, i1=i1, negatedCr1=negatedCr1, negatedCr2=negatedCr2, eqnAttributes=eqnAttributes) = s;
       _= arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       negated = boolOr(negatedCr1,negatedCr2);
       // generate exp from cref an negate if necessary
       exp = Expression.crefExp(DAE.crefTime);
       exp1 = negateExpression(negated, exp, exp, " timealias ");
       v = BackendVariable.getVarAt(iVars, i1);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
       dexp = negateExpression(negated, exp, DAE.RCONST(1.0), " timealias der ");
       (vars, eqnslst, shared, repl) = handleSetVar(replaceable_ and replaceble1, SOME(dexp), v, i1, eqnAttributes, exp1, iMT, iVars, iEqnslst, ishared, iRepl);
       expcr = Expression.crefExp(cr1);
       vsattr = addVarSetAttributes(v, negated, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       rows = List.removeOnTrue(r, intEq, iMT[i1]);
       _ = arrayUpdate(iMT, i1, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i1, exp, SOME(expcr), negated, SOME(dexp), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);
   
   // constant set
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       TIMEINDEPENTVAR(cr=cr, i=i, exp=exp, eqnAttributes=eqnAttributes) = s;
       _= arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
       (vars, shared, isState, eqnslst) = optMoveVarShared(replaceable_, v, i, eqnAttributes, exp, BackendVariable.addKnVarDAE, iMT, iVars, ishared, iEqnslst);
       constExp = Expression.isConst(exp);
       // add to replacements if constant
       repl = Debug.bcallret4(replaceable_ and constExp and replaceble1, BackendVarTransform.addReplacement, iRepl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator), iRepl);
       // if state der(var) has to replaced to 0
       repl = Debug.bcallret3(isState, BackendVarTransform.addDerConstRepl, cr, DAE.RCONST(0.0), repl, repl);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       rows = List.removeOnTrue(r, intEq, iMT[i]);
       _ = arrayUpdate(iMT, i, {});
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i, exp, NONE(), false, SOME(DAE.RCONST(0.0)), mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
     then
       (vars, eqnslst, shared, repl);
   
   // valid circular equality
   case (_, _, _, SOME(r), _, _, _, _, _, _, _, _)
     equation
       s = simpleeqnsarr[r];
       ALIAS(i1=i, i2=i2, eqnAttributes=eqnAttributes) = s;
       _= arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = Util.if_(Types.isRealOrSubTypeReal(ComponentReference.crefLastType(cr)), DAE.RCONST(0.0), DAE.ICONST(0));
       (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
       (vars, shared, isState, eqnslst) = optMoveVarShared(replaceable_, v, i, eqnAttributes, exp, BackendVariable.addKnVarDAE, iMT, iVars, ishared, iEqnslst);
       constExp = Expression.isConst(exp);
       // add to replacements if constant
       repl = Debug.bcallret4(replaceable_ and constExp and replaceble1, BackendVarTransform.addReplacement, iRepl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator), iRepl);
       // if state der(var) has to replaced to 0
       repl = Debug.bcallret3(isState, BackendVarTransform.addDerConstRepl, cr, DAE.RCONST(0.0), repl, repl);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       rows = List.removeOnTrue(r, intEq, iMT[i2]);
       _ = arrayUpdate(iMT, i2, rows);
       rows = List.removeOnTrue(r, intEq, iMT[i]);
       _ = arrayUpdate(iMT, i, {});
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
       _ = arrayUpdate(iMT, i, {});
       vars = handleVarSetAttributes(vsattr, v, i, vars, shared);
     then
       (vars, eqnslst, shared, repl);
   
   // variable set unReplaceable
   case (_, NONE(), SOME(i), NONE(), _, _, _, _, _, _, _, _)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(iMT[i], i, exp, NONE(), false, NONE(), mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, vsattr);
       _ = arrayUpdate(iMT, i, {});
       vars = handleVarSetAttributes(vsattr, v, i, vars, shared);
     then
       (vars, eqnslst, shared, repl);
   
   // variable set
   case (SOME((i, _)), NONE(), _, NONE(), _, _, _, _, _, _, _, _)
     equation
       (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
       exp = Expression.crefExp(cr);
       vsattr = addVarSetAttributes(v, false, mark, simpleeqnsarr, EMPTYVARSETATTRIBUTES);
       (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(iMT[i], i, exp, NONE(), false, NONE(), mark, simpleeqnsarr, iMT, unReplaceable, iVars, iEqnslst, ishared, iRepl, vsattr);
       _ = arrayUpdate(iMT, i, {});
       vars = handleVarSetAttributes(vsattr, v, i, vars, shared);
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
    else then NONE();
  end match;
end varStateDerivative;

protected function handleSetVar "author: Frenkel TUD 2012-12
  traverse an Equations system to remove simple equations"
  input Boolean replaceable_;
  input Option<DAE.Exp> derReplaceState;
  input BackendDAE.Var v;
  input Integer i;
  input EquationAttributes eqnAttributes;
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
    else then iRepl;
  end match;
end addDerConstRepl;

protected function optMoveVarShared "author: Frenkel TUD 2012-12"
  input Boolean replaceable_;
  input BackendDAE.Var v;
  input Integer i;
  input EquationAttributes eqnAttributes;
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
  ops := DAEUtil.getSymbolicTransformations(source);
  v1 := BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr, exp)::ops);
  // State?
  bs := BackendVariable.isStateVar(v);
  v1 := Debug.bcallret2(bs, BackendVariable.setVarKind, v1, BackendDAE.DUMMY_STATE(), v1);
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
  input Integer mark;
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
        _= arrayUpdate(simpleeqnsarr, r, setVisited(mark, s));
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
  input Integer mark;
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
      Boolean replaceable_, globalnegated1, diffed, replaceble1, negatedCr1, negatedCr2, negated;
      DAE.ElementSource source;
      DAE.Exp crexp, exp1;
      Option<DAE.Exp> dexp;
      String msg;
      VarSetAttributes vsattr;
    
    case (ALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, (source, diffed), _), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        i = Util.if_(intEq(i1, ilast), i2, i1);
        negated = boolOr(negatedCr2, negatedCr1);
        (v as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(iVars, i);
        (replaceable_, replaceble1) = replaceableAlias(v, unReplaceable);
        crexp = Expression.crefExp(cr);
        // negate if necessary
        globalnegated1 = Util.if_(negated, not globalnegated, globalnegated);
        exp1 = negateExpression(globalnegated1, exp, exp, " ALIAS_1 ");
        dexp = Debug.bcallret1(globalnegated1, negateOptExp, derReplaceState, derReplaceState);
        // replace alias with selected variable if replaceable_
        source = Debug.bcallret3(replaceable_, addSubstitutionOption, optExp, crexp, source, source);
        (vars, eqnslst, shared, repl) = handleSetVar(replaceable_ and replaceble1, derReplaceState, v, i, (source, diffed), exp1, iMT, iVars, iEqnslst, ishared, iRepl);
        vsattr = Debug.bcallret5(replaceable_ and replaceble1, addVarSetAttributes, v, globalnegated1, mark, simpleeqnsarr, iAttributes, iAttributes);
        // negate if necessary
        crexp = negateExpression(negated, crexp, crexp, " ALIAS_2 ");
        rows = List.removeOnTrue(r, intEq, iMT[i]);
        _ = arrayUpdate(iMT, i, {});
        (vars, eqnslst, shared, repl, vsattr) = traverseAliasTree(rows, i, exp, SOME(crexp), globalnegated1, derReplaceState, mark, simpleeqnsarr, iMT, unReplaceable, vars, eqnslst, shared, repl, vsattr);
      then
        (vars, eqnslst, shared, repl, vsattr);
    
    case (PARAMETERALIAS(cr1, negatedCr1, i1, cr2, negatedCr2, i2, (source, _), _), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // report error
        cr = Util.if_(intEq(i1, ilast), cr2, cr1);
        negated = boolOr(negatedCr1, negatedCr2);
        crexp = Expression.crefExp(cr);
        crexp = negateExpression(negated, crexp, crexp, " PARAMETERLAIAS ");
        msg = "Found Equation without time dependent variables ";
        msg = msg +& ExpressionDump.printExpStr(exp) +& " = " +& ExpressionDump.printExpStr(crexp) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    
    case (TIMEALIAS(cr1=cr1, negatedCr1=negatedCr1, cr2=cr2, negatedCr2=negatedCr2), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // report error
        msg = "Found Equation without time dependent variables ";
        msg = msg +& " time = " +& ExpressionDump.printExpStr(exp) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    
    case (TIMEINDEPENTVAR(cr=cr, exp=exp1), _, _, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // report error
        msg = "Found Equation without time dependent variables ";
        msg = msg +& ExpressionDump.printExpStr(exp) +& " = " +& ExpressionDump.printExpStr(exp1) +& "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
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
      else then iExp;
  end match;
end negateOptExp;

protected function addSubstitutionOption "author: Frenkel TUD 2012-12"
 input Option<DAE.Exp> optExp;
 input DAE.Exp exp;
 input DAE.ElementSource iSource;
 output DAE.ElementSource oSource;
algorithm
  oSource := match(optExp, exp, iSource)
    local DAE.Exp e;
    case (NONE(), _, _) then iSource;
    case (SOME(e), _, _) then DAEUtil.addSymbolicTransformationSubstitution(true, iSource, exp, e);
  end match;
end addSubstitutionOption;

protected function addVarSetAttributes "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Integer mark;
  input array<SimpleContainer> simpleeqnsarr;
  input VarSetAttributes iAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
  output VarSetAttributes oAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
protected
  Boolean fixed, fixedset;
  Option<DAE.Exp> start, origin, nominalset;
  tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmaxset;
  Integer nNominal;
  tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> startvalues;
algorithm
  (fixedset, startvalues, nominalset, nNominal, minmaxset) := iAttributes;
  // get attributes
  // fixed
  fixed := BackendVariable.varFixed(inVar);
  // start, add only if fixed == fixedset or fixed
  start := BackendVariable.varStartValueOption(inVar);
  origin := BackendVariable.varStartOrigin(inVar);
  (fixedset, startvalues) := addStartValue(fixed, fixedset, BackendVariable.varCref(inVar), start, origin, negate, mark, simpleeqnsarr, startvalues);
  // nominal
  (nominalset, nNominal) := addNominalAttribute(inVar, negate, nominalset, nNominal);
  // minmax
  minmaxset := addMinMaxAttribute(inVar, negate, mark, simpleeqnsarr, minmaxset);
  oAttributes := (fixedset, startvalues, nominalset, nNominal, minmaxset);
end addVarSetAttributes;

protected function addStartValue "author: Frenkel TUD 2012-12"
  input Boolean fixed;
  input Boolean fixedset;
  input DAE.ComponentRef cr;
  input Option<DAE.Exp> start;
  input Option<DAE.Exp> origin;
  input Boolean negate;
  input Integer mark;
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
        startvalues1 = Util.if_(fixed, {(start, cr)}, {});
        ((setorigin, startvalues)) = Util.if_(b, (originvalue, startvalues1), ((setorigin, startvalues)));
      then
        (fixedset, (setorigin, startvalues));
    case (_, _, _, SOME(startexp), _, _, _, _, (setorigin, startvalues))
      equation
        startexp = negateExpression(negate, startexp, startexp, " start_2 ");
        originvalue = BackendVariable.startOriginToValue(origin);
        b = intGt(originvalue, setorigin);
        b1 = intEq(originvalue, setorigin);
        startvalues = List.consOnTrue(b1, (SOME(startexp), cr), startvalues);
        ((setorigin, startvalues)) = Util.if_(b, (originvalue, {(SOME(startexp), cr)}), ((setorigin, startvalues)));
      then
        (fixedset, (setorigin, startvalues));
    else
      equation
        print("RemoveSimpleEquations.addStartValue failed!\n");
      then
        fail();
  end matchcontinue;
end addStartValue;

protected function addNominalAttribute "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Option<DAE.Exp> iNominal;
  input Integer iNNominals;
  output Option<DAE.Exp> oNominal;
  output Integer oNNominals;
algorithm
  (oNominal, oNNominals):= matchcontinue(inVar, negate, iNominal, iNNominals)
    local
      DAE.Exp nominal, nominalset;
    case(_, _, SOME(nominalset), _)
      equation
        nominal = BackendVariable.varNominalValue(inVar);
        nominal = negateExpression(negate, nominal, nominal, " nominal_1 ");
        nominalset = Expression.expAdd(nominal, nominalset);
      then
        (SOME(nominalset), iNNominals+1);
    case(_, _, NONE(), _)
      equation
        nominal = BackendVariable.varNominalValue(inVar);
        nominal = negateExpression(negate, nominal, nominal, " nominal_2 ");
      then
        (SOME(nominal), 1);
    else then (iNominal, iNNominals);
  end matchcontinue;
end addNominalAttribute;

protected function addMinMaxAttribute "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean negate;
  input Integer mark;
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
  input Integer mark;
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

protected function checkMinMax "author: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmax;
  input Integer mark;
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
        rmin = Expression.expReal(min);
        rmax = Expression.expReal(max);
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

protected function mergeMinMax1 "author: Frenkel TUD 2012-12"
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> ominmax;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>> ominmax1;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>> minMax;
algorithm
  minMax :=
  match (ominmax, ominmax1)
    local
      DAE.Exp min, max, min1, max1, min_2, max_2, smin, smax;
    // (_, _), ()
    case (_, (NONE(), NONE()))
      then ominmax;
    case ((NONE(), NONE()), _)
      then ominmax1;
    // (min, ), (min, )
    case ((SOME(min), NONE()), (SOME(min1), NONE()))
      equation
        min_2 = Expression.expMaxScalar(min, min1);
        (smin, _) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin), NONE()));
    // (, max), (, max)
    case ((NONE(), SOME(max)), (NONE(), SOME(max1)))
      equation
        max_2 = Expression.expMinScalar(max, max1);
        (smax, _) = ExpressionSimplify.simplify(max_2);
      then ((NONE(), SOME(smax)));
    // (min, ), (, max)
    case ((SOME(min), NONE()), (NONE(), SOME(max1)))
      then ((SOME(min), SOME(max1)));
    // (, max), (min, )
    case ((NONE(), SOME(max)), (SOME(min1), NONE()))
      then ((SOME(min1), SOME(max)));
    // (, max), (min, max)
    case ((NONE(), SOME(max)), (SOME(min1), SOME(max1)))
      equation
        max_2 = Expression.expMinScalar(max, max1);
        (smax, _) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min1), SOME(smax)));
    // (min, max), (, max)
    case ((SOME(min), SOME(max)), (NONE(), SOME(max1)))
      equation
        max_2 = Expression.expMinScalar(max, max1);
        (smax, _) = ExpressionSimplify.simplify(max_2);
      then ((SOME(min), SOME(smax)));
    // (min, ), (min, max)
    case ((SOME(min), NONE()), (SOME(min1), SOME(max1)))
      equation
        min_2 = Expression.expMaxScalar(min, min1);
        (smin, _) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin), SOME(max1)));
    // (min, max), (min, )
    case ((SOME(min), SOME(max)), (SOME(min1), NONE()))
      equation
        min_2 = Expression.expMaxScalar(min, min1);
        (smin, _) = ExpressionSimplify.simplify(min_2);
      then ((SOME(smin), SOME(max)));
    // (min, max), (min, max)
    case ((SOME(min), SOME(max)), (SOME(min1), SOME(max1)))
      equation
        min_2 = Expression.expMaxScalar(min, min1);
        max_2 = Expression.expMinScalar(max, max1);
        (smin, _) = ExpressionSimplify.simplify(min_2);
        (smax, _) = ExpressionSimplify.simplify(max_2);
      then ((SOME(smin), SOME(smax)));
    else
      equation
        print("RemoveSimpleEquations.mergeMinMax1 failed!\n");
      then
        fail();
  end match;
end mergeMinMax1;

protected function handleVarSetAttributes "author: Frenkel TUD 2012-12"
  input VarSetAttributes iAttributes "fixed, list<startvalue, origin, cr>, nominal, min, max";
  input BackendDAE.Var inVar;
  input Integer i;
  input BackendDAE.Variables iVars;
  input BackendDAE.Shared ishared;
  output BackendDAE.Variables oVars;
algorithm
  oVars := matchcontinue(iAttributes, inVar, i, iVars, ishared)
    local
      Boolean fixedset, isdiscrete;
      Option<DAE.Exp> nominalset;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> minmaxset;
      Integer nNominal;
      tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> startvalues;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
    case((fixedset, startvalues, nominalset, nNominal, minmaxset), _, _, _, _)
      equation
        isdiscrete = BackendVariable.isVarDiscrete(inVar);
        // start and fixed
        v = Debug.bcallret4(not isdiscrete, mergeStartFixedAttributes, inVar, fixedset, startvalues, ishared, inVar);
        // nominal
        v = mergeNominalAttribute(nominalset, nNominal, v);
        // min max
        v = BackendVariable.setVarMinMax(v, minmaxset);
        // update vars
        vars = BackendVariable.addVar(v, iVars);
      then
        vars;
    else
      equation
        print("RemoveSimpleEquations.handleVarSetAttributes failed!\n");
      then
        fail();
  end matchcontinue;
end handleVarSetAttributes;

protected function mergeStartFixedAttributes "author: Frenkel TUD 2012-12"
  input BackendDAE.Var inVar;
  input Boolean fixed;
  input tuple<Integer, list<tuple<Option<DAE.Exp>, DAE.ComponentRef>>> startvalues;
  input BackendDAE.Shared ishared;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inVar, fixed, startvalues, ishared)
    local
      DAE.ComponentRef cr;
      Option<DAE.Exp> start, start1;
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> values;
      list<tuple<DAE.Exp, DAE.ComponentRef>> zerofreevalues;
      BackendDAE.Var v;
      BackendDAE.Variables knVars;
    // default value
    case (_, _, (_, {}), _) then inVar;
    // fixed true only one start value -> nothing changed
    case (_, true, (_, {(start, _)}), _)
      equation
        v = BackendVariable.setVarFixed(inVar, true);
      then
        BackendVariable.setVarStartValueOption(v, start);
    // fixed true several start values, this need some investigation
    case (_, true, (_, (start, cr)::values), BackendDAE.SHARED(knownVars=knVars))
      equation
        v = BackendVariable.setVarFixed(inVar, true);
        start1 = optExpReplaceCrefWithBindExp(start, knVars);
        ((_, start, _)) = equalNonFreeStartValues(values, knVars, (start1, start, cr));
      then
        BackendVariable.setVarStartValueOption(v, start);
    case (_, true, (_, values), BackendDAE.SHARED(knownVars=knVars))
      equation
        v = BackendVariable.setVarFixed(inVar, true);
        // get all nonzero values
        zerofreevalues = List.fold(values, getZeroFreeValues, {});
      then
        selectFreeValue1(zerofreevalues, NONE(), "fixed Alias set with several free start values\n", v);
    // fixed false only one start value -> nothing changed
    case (_, false, (_, {(start, _)}), _)
      then
        BackendVariable.setVarStartValueOption(inVar, start);
    // fixed false several start value, this need some investigation
    case (_, false, (_, (start, cr)::values), BackendDAE.SHARED(knownVars=knVars))
      equation
        start1 = optExpReplaceCrefWithBindExp(start, knVars);
        ((_, start, _)) = equalFreeStartValues(values, knVars, (start1, start, cr));
      then
        BackendVariable.setVarStartValueOption(inVar, start);
    case (_, false, (_, values), _)
      equation
        // get all nonzero values
        zerofreevalues = List.fold(values, getZeroFreeValues, {});
      then
        selectFreeValue(zerofreevalues, inVar);
  end matchcontinue;
end mergeStartFixedAttributes;

protected function optExpReplaceCrefWithBindExp "author: Frenkel TUD 2012-12"
  input Option<DAE.Exp> iOExp;
  input BackendDAE.Variables knVars;
  output Option<DAE.Exp> oOExp;
algorithm
  oOExp := match(iOExp, knVars)
    local
      DAE.Exp e;
      Boolean b;
    case(NONE(), _) then iOExp;
    case(SOME(e), _)
      equation
        ((e, (_, b, _))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars, false, HashSet.emptyHashSet()));
        (e, _) = ExpressionSimplify.condsimplify(b, e);
      then
        SOME(e);
 end match;
end optExpReplaceCrefWithBindExp;

protected function equalNonFreeStartValues "author: Frenkel TUD 2012-12"
  input list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> iValues;
  input BackendDAE.Variables knVars;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> iValue;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> oValue;
algorithm
  oValue := matchcontinue(iValues, knVars, iValue)
    local
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> values;
      DAE.Exp e, e1, e2;
      Boolean b;
      DAE.ComponentRef cr;
    case ({}, _, _) then iValue;
    case (((NONE(), _))::values, _, _)
      then
        equalNonFreeStartValues(values, knVars, iValue);
    case (((NONE(), _))::values, _, (NONE(), _, _))
      then
        equalNonFreeStartValues(values, knVars, iValue);
    case (((NONE(), cr))::values, _, (SOME(e2), _, _))
      equation
        true = Expression.isZero(e2);
      then
        equalNonFreeStartValues(values, knVars, (NONE(), NONE(), cr));
    case (((SOME(e), _))::values, _, (SOME(e2), _, _))
      equation
        ((e1, (_, b, _))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        true = Expression.expEqual(e1, e2);
      then
        equalNonFreeStartValues(values, knVars, iValue);
  end matchcontinue;
end equalNonFreeStartValues;

protected function equalFreeStartValues "author: Frenkel TUD 2012-12"
  input list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> iValues;
  input BackendDAE.Variables knVars;
  input tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> iValue;
  output tuple<Option<DAE.Exp>, Option<DAE.Exp>, DAE.ComponentRef> oValue;
algorithm
  oValue := match(iValues, knVars, iValue)
    local
      list<tuple<Option<DAE.Exp>, DAE.ComponentRef>> values;
      DAE.Exp e, e1, e2;
      Boolean b;
      DAE.ComponentRef cr;
    case ({}, _, _) then iValue;
    // ignore default values
    case (((NONE(), _))::values, _, _)
      then
        equalFreeStartValues(values, knVars, iValue);
    case (((SOME(e), cr))::values, _, (NONE(), _, _))
      equation
        ((e1, (_, b, _))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
      then
        equalFreeStartValues(values, knVars, (SOME(e1), SOME(e), cr));
    // compare
    case (((SOME(e), _))::values, _, (SOME(e2), _, _))
      equation
        ((e1, (_, b, _))) = Expression.traverseExp(e, replaceCrefWithBindExp, (knVars, false, HashSet.emptyHashSet()));
        (e1, _) = ExpressionSimplify.condsimplify(b, e1);
        true = Expression.expEqual(e1, e2);
      then
        equalFreeStartValues(values, knVars, iValue);
  end match;
end equalFreeStartValues;

protected function replaceCrefWithBindExp "author: Frenkel TUD 2012-12"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables, Boolean, HashSet.HashSet>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables, Boolean, HashSet.HashSet>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      HashSet.HashSet hs;
    // true if crefs replaced in expression
    case ((DAE.CREF(componentRef=cr), (vars, _, hs)))
      equation
        // check for cyclic bindings in start value
        false = BaseHashSet.has(cr, hs);
        ({BackendDAE.VAR(bindExp = SOME(e))}, _) = BackendVariable.getVar(cr, vars);
        hs = BaseHashSet.add(cr, hs);
        ((e, (_, _, hs))) = Expression.traverseExp(e, replaceCrefWithBindExp, (vars, false, hs));
      then
        ((e, (vars, true, hs)));
    // true if crefs in expression
    case ((e as DAE.CREF(componentRef=cr), (vars, _, hs)))
      then
        ((e, (vars, true, hs)));
    else then inTuple;
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
    case((NONE(), _), _) then iAcc;
    case ((SOME(e), cr), _) then (e, cr)::iAcc;
  end match;
end getZeroFreeValues;

protected function selectFreeValue "author: Frenkel TUD 2012-12"
  input list<tuple<DAE.Exp, DAE.ComponentRef>> iZeroFreeValues;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := match(iZeroFreeValues, inVar)
    local
    case ({}, _) then inVar;
    case (_, _)
      then
        selectFreeValue1(iZeroFreeValues, NONE(), "Alias set with several free start values\n", inVar);
  end match;
end selectFreeValue;

protected function selectNonZeroExpression 
"adrpo: select one that is non zero if possible"
  input list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> iFavorit;
  output tuple<DAE.Exp, DAE.ComponentRef, Integer> selected;
algorithm
  selected := matchcontinue(iFavorit)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Integer i;
      list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> rest;
    
    case ({(e, cr, i)}) then ((e, cr, i)); 
    
    case ((e, cr, i)::rest)
      equation
        false = Expression.isZero(e);
      then
        ((e, cr, i));
    
    case ((e, cr, i)::rest)
      equation
        true = Expression.isZero(e);
        ((e, cr, i)) = selectNonZeroExpression(rest);
      then
        ((e, cr, i));
  end matchcontinue;
end selectNonZeroExpression;

protected function selectFreeValue1 
"@author: Frenkel TUD 2012-12
 adrpo: the value is selected as follows:
 - if the exp is a cref with less depth
 - for the ones with the minimum depth equal, select one that is non-zero 
 "
  input list<tuple<DAE.Exp, DAE.ComponentRef>> iZeroFreeValues;
  input Option<list<tuple<DAE.Exp, DAE.ComponentRef, Integer>>> iFavorit;
  input String iStr;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(iZeroFreeValues, iFavorit, iStr, inVar)
    local
      DAE.Exp e, es;
      DAE.ComponentRef cr, crs;
      BackendDAE.Var v;
      list<tuple<DAE.Exp, DAE.ComponentRef>> zerofreevalues;
      Integer i, is;
      Option<list<tuple<DAE.Exp, DAE.ComponentRef, Integer>>> favorit;
      list<tuple<DAE.Exp, DAE.ComponentRef, Integer>> rest;
      String s;
    
    case ({}, NONE(), _, _) then inVar;
      
    case ({}, SOME({}), _, _) then inVar;
    
    // end of list analyse what we got
    case ({}, SOME(rest), _, _)
      equation
        ((e, cr, i)) = selectNonZeroExpression(rest);
        s = iStr +& "         Selected value from " +& 
            ComponentReference.printComponentRefStr(cr) +& 
            "(start = " +& ExpressionDump.printExpStr(e) +& ")\n" +& 
            "         because its component reference (or its binding component reference) is closer to the top level scope with depth: " +& 
                    intString(i) +& ".\n" +&
            "         If we have equal component reference depth for several components choose the one with non zero binding.";
        Error.addMessage(Error.COMPILER_WARNING, {s});
        v = BackendVariable.setVarStartValue(inVar, e);
      then
        v;
    
    // none, push it in
    case ((e, cr)::zerofreevalues, NONE(), _, _)
      equation
        s = iStr +& "         Candidate " +& ComponentReference.printComponentRefStr(cr) +& "(start = " +& ExpressionDump.printExpStr(e) +& ")\n";
        i = selectMinDepth(ComponentReference.crefDepth(cr), e);
      then
        selectFreeValue1(zerofreevalues, SOME({(e, cr, i)}), s, inVar);
    
    // equal, put it in
    case ((e, cr)::zerofreevalues, SOME((es, crs, is)::rest), _, _)
      equation
        s = iStr +& "         Candidate " +& ComponentReference.printComponentRefStr(cr) +& "(start = " +& ExpressionDump.printExpStr(e) +& ")\n";
        i = selectMinDepth(ComponentReference.crefDepth(cr), e);
        true = intEq(i, is);
        favorit = SOME((e, cr, i)::(es, crs, is)::rest);
      then
        selectFreeValue1(zerofreevalues, favorit, s, inVar);
    
    // less than, remove all from list, return just this one
    case ((e, cr)::zerofreevalues, SOME((es, crs, is)::rest), _, _)
      equation
        s = iStr +& "         Candidate " +& ComponentReference.printComponentRefStr(cr) +& "(start = " +& ExpressionDump.printExpStr(e) +& ")\n";
        i = selectMinDepth(ComponentReference.crefDepth(cr), e);
        favorit = Util.if_(intLt(i, is), SOME({(e, cr, i)}), iFavorit);
      then
        selectFreeValue1(zerofreevalues, favorit, s, inVar);
        
  end matchcontinue;
end selectFreeValue1;

protected function selectMinDepth
"@author: adrpo
 if the start expression is a cref
 with less depth than the one given
 return the minimum depth between the 
 two. Maybe we should o min of all the 
 cref in the expression!"
  input Integer d;
  input DAE.Exp e;
  output Integer m;
algorithm
  m := match(d, e)
    local 
      Integer i;
      DAE.ComponentRef cr;
    case (_, DAE.CREF(cr, _))
      equation
        i = ComponentReference.crefDepth(cr);
      then
        intMin(i, d);
    else d;
  end match;
end selectMinDepth;

protected function mergeNominalAttribute "author: Frenkel TUD 2012-12"
  input Option<DAE.Exp> nominal;
  input Integer n;
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar :=
  match (nominal, n, inVar)
    local
      Real r;
      DAE.Exp e;
    case (SOME(e), _, _)
      equation
        r = intReal(n);
        e = Expression.expDiv(e, DAE.RCONST(r)); // Real is legal because only Reals have nominal attribute
        (e, _) = ExpressionSimplify.simplify(e);
      then
        BackendVariable.setVarNominalValue(inVar, e);
    case (NONE(), _, _) then inVar;
  end match;
end mergeNominalAttribute;

/*
 * functions to update equation system and shared
 */

protected function updateSystem "author: Frenkel TUD 2012-12
  replace the simplified variables and equations in the system"
  input Boolean foundSimple;
  input list<BackendDAE.Equation> iEqnslst;
  input BackendDAE.Variables iVars;
  input BackendDAE.StateSets stateSets;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst:=
  match (foundSimple, iEqnslst, iVars, stateSets, repl, isyst)
    local

      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
    case (false, _, _, _, _, _) then isyst;
    case (true, _, _, _, _, _)
      equation
        // remove empty entries from vars and update stateorder
        vars = BackendVariable.emptyVars();
        ((vars, _)) = BackendVariable.traverseBackendDAEVars(iVars, updateVar, (vars, repl));
        // replace unoptimized equations with optimized
        eqns = BackendEquation.listEquation(listReverse(iEqnslst));
      then
        BackendDAE.EQSYSTEM(vars, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets);
  end match;
end updateSystem;

protected function updateVar "author: Frenkel TUD 2012-12
  update the derivatives of states and add the vars to varrarr"
  input tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendVarTransform.VariableReplacements>> inTpl;
  output tuple<BackendDAE.Var, tuple<BackendDAE.Variables, BackendVarTransform.VariableReplacements>> oTpl;
algorithm
  oTpl := matchcontinue(inTpl)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
    case ((v as BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(cr))), (vars, repl)))
      equation
        e = BackendVarTransform.getReplacement(repl, cr);
        v = updateStateOrder(e, v);
        vars = BackendVariable.addVar(v, vars);
      then
        ((v, (vars, repl)));
    case ((v, (vars, repl)))
      equation
        vars = BackendVariable.addVar(v, vars);
      then
        ((v, (vars, repl)));
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
    else then BackendVariable.setStateDerivative(inVar, NONE());
  end match;
end updateStateOrder;

protected function removeSimpleEquationsShared
  input Boolean b;
  input BackendDAE.BackendDAE inDAE;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE:=
  match (b, inDAE, repl)
    local
      BackendDAE.Variables knvars, exobj, knvars1;
      BackendDAE.Variables aliasVars;
      BackendDAE.EquationArray remeqns, inieqns, remeqns1;
      list<DAE.Constraint> constraintsLst;
      list<DAE.ClassAttributes> clsAttrsLst;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst, whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst, relationsLst, sampleLst;
      Integer numberOfRealtions, numMathFunctions;
      BackendDAE.BackendDAEType btp;
      BackendDAE.EqSystems systs, systs1;
      list<BackendDAE.Equation> eqnslst;
      list<BackendDAE.Var> varlst;
      Boolean b1;
      list<BackendDAE.TimeEvent> timeEvents;
      BackendDAE.ExtraInfo ei;
      
    case (false, _, _) then inDAE;
    case (true, BackendDAE.DAE(systs, BackendDAE.SHARED(knvars, exobj, aliasVars, inieqns, remeqns, constraintsLst, clsAttrsLst, cache, env, funcTree, BackendDAE.EVENT_INFO(timeEvents, whenClauseLst, zeroCrossingLst, sampleLst, relationsLst, numberOfRealtions, numMathFunctions), eoc, btp, symjacs, ei)), _)
      equation
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpReplacements, repl);
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpExtendReplacements, repl);
        Debug.fcall(Flags.DUMP_REPL, BackendVarTransform.dumpDerConstReplacements, repl);
        // replace moved vars in knvars, remeqns
        (aliasVars, (_, varlst)) = BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, replaceAliasVarTraverser, (repl, {}));
        aliasVars = List.fold(varlst, fixAliasConstBindings, aliasVars);
        (knvars1, _) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars, replaceVarTraverser, repl);
        ((_, eqnslst, b1)) = BackendEquation.traverseBackendDAEEqns(inieqns, replaceEquationTraverser, (repl, {}, false));
        inieqns = Debug.bcallret1(b1, BackendEquation.listEquation, eqnslst, inieqns);
        ((_, eqnslst, b1)) = BackendEquation.traverseBackendDAEEqns(remeqns, replaceEquationTraverser, (repl, {}, false));
        remeqns1 = Debug.bcallret1(b1, BackendEquation.listEquation, eqnslst, remeqns);
        (whenClauseLst1, _) = BackendVarTransform.replaceWhenClauses(whenClauseLst, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        // remove optimica contraints and classAttributes
        (constraintsLst, clsAttrsLst) = replaceOptimicaExps(constraintsLst, clsAttrsLst, repl);
        systs1 = removeSimpleEquationsShared1(systs, {}, repl, NONE(), aliasVars);
        // remove asserts with condition=true from removed equations
        remeqns1 = BackendEquation.listEquation(List.select(BackendEquation.equationList(remeqns1), assertWithCondTrue));
      then
        BackendDAE.DAE(systs1, BackendDAE.SHARED(knvars1, exobj, aliasVars, inieqns, remeqns1, constraintsLst, clsAttrsLst, cache, env, funcTree, BackendDAE.EVENT_INFO(timeEvents, whenClauseLst1, zeroCrossingLst, sampleLst, relationsLst, numberOfRealtions, numMathFunctions), eoc, btp, symjacs, ei));
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
        (BackendDAE.VAR(bindExp=SOME(e))::{}, _) = BackendVariable.getVar(cr, iAVars);
      then
        fixAliasConstBindings1(cr, e, iAVars);
    else
      then
        iExp;
  end matchcontinue;
end fixAliasConstBindings1;

protected function replaceAliasVarTraverser "author: Frenkel TUD 2011-12"
 input tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Var>>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Var>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v, v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e, e1;
      list<BackendDAE.Var> varlst;
      Boolean b;
    case ((v as BackendDAE.VAR(bindExp=SOME(e)), (repl, varlst)))
      equation
        (e1, true) = BackendVarTransform.replaceExp(e, repl, NONE());
        b = Expression.isConst(e1);
        v1 = Debug.bcallret2(not b, BackendVariable.setBindExp, v, SOME(e1), v);
        varlst = List.consOnTrue(b, v1, varlst);
      then ((v1, (repl, varlst)));
    case _ then inTpl;
  end matchcontinue;
end replaceAliasVarTraverser;

protected function replaceVarTraverser "author: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v, v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e, e1;
    case ((v as BackendDAE.VAR(bindExp=SOME(e)), repl))
      equation
        (e1, true) = BackendVarTransform.replaceExp(e, repl, NONE());
        v1 = BackendVariable.setBindExp(v, SOME(e1));
      then ((v1, repl));
    case _ then inTpl;
  end matchcontinue;
end replaceVarTraverser;

protected function assertWithCondTrue "author: Frenkel TUD 2012-12"
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match inEqn
    case BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond=DAE.BCONST(true))})) then false;
    else then true;
  end match;
end assertWithCondTrue;

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
    case ((syst as BackendDAE.EQSYSTEM(orderedVars=v, orderedEqs=eqns, stateSets=stateSets))::rest, _, _, _, _)
      equation
        ((_, eqnslst, b)) = BackendEquation.traverseBackendDAEEqns(eqns, replaceEquationTraverser, (repl, {}, false));
        eqnslst = Debug.bcallret1(b, listReverse, eqnslst, eqnslst);
        eqns = Debug.bcallret1(b, BackendEquation.listEquation, eqnslst, eqns);
        (stateSets, b1, statesetrepl1) = removeAliasVarsStateSets(stateSets, statesetrepl, v, aliasVars, {}, false);
        syst = Util.if_(b or b1, BackendDAE.EQSYSTEM(v, eqns, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets), syst);
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
      Integer rang;
      list< DAE.ComponentRef> states;
      DAE.ComponentRef crA, crJ;
      list< BackendDAE.Var> varA, statescandidates, ovars, varJ;
      list< BackendDAE.Equation> eqns, oeqns;
      BackendVarTransform.VariableReplacements repl;
      HashSet.HashSet hs;
      Boolean b, b1;
    case ({}, _, _, _, _, _) then (listReverse(iAcc), inB, iStatesetrepl);
    case (BackendDAE.STATESET(rang, states, crA, varA, statescandidates, ovars, eqns, oeqns, crJ, varJ)::stateSets, _, _, _, _, _)
      equation
        repl = getAliasReplacements(iStatesetrepl, aliasVars);
        // do not replace the set variables
        hs = HashSet.emptyHashSet();
        hs = List.fold(List.map(statescandidates, BackendVariable.varCref), BaseHashSet.add, hs);
        ovars = replaceOtherStateSetVars(ovars, vars, aliasVars, hs, {});
        (eqns, b) = BackendVarTransform.replaceEquations(eqns, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        (oeqns, b1) = BackendVarTransform.replaceEquations(oeqns, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        oeqns = List.fold(oeqns, removeEqualLshRshEqns, {});
        oeqns = listReverse(oeqns);
        (stateSets, b, oStatesetrepl) = removeAliasVarsStateSets(stateSets, SOME(repl), vars, aliasVars, BackendDAE.STATESET(rang, states, crA, varA, statescandidates, ovars, eqns, oeqns, crJ, varJ)::iAcc, b or b1);
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
    else then iEqn::iEqns;
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
        ({var}, _) = BackendVariable.getVar(cr, aliasVars);
        exp = BackendVariable.varBindExp(var);
        cr::{} = Expression.extractCrefsFromExp(exp);
        b = BaseHashSet.has(cr, hs);
        ({var}, _) = BackendVariable.getVar(cr, vars);
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
  (ocontraints, oclassAttributes) := matchcontinue(icontraints, iclassAttributes, irepl)
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
        classAttributes = listAppend({DAE.OPTIMIZATION_ATTRS(objetiveE, objectiveIntegrandE, startTimeE, finalTimeE)}, classAttributes);
      then ({}, classAttributes);
    case (DAE.CONSTRAINT_EXPS(constraintLstExps)::rest, _, _)
      equation
        (constraintLstExps) = replaceOptimicaContraints(constraintLstExps, irepl);
        (constraintLst, _) = replaceOptimicaExps(rest, iclassAttributes, irepl);
        constraintLst = listAppend({DAE.CONSTRAINT_EXPS(constraintLstExps)}, constraintLst);
      then (constraintLst, iclassAttributes);
  end matchcontinue;
end replaceOptimicaExps;

protected function replaceOptimicaContraints
  input list<DAE.Exp> icontraints;
  input BackendVarTransform.VariableReplacements irepl;
  output list<DAE.Exp> ocontraints;
algorithm
  (ocontraints) := matchcontinue(icontraints, irepl)
    local
      list<DAE.Exp> constraintLst, rest;
      DAE.Exp e;
    case ({}, _) then ({});
    case (e::rest, _)
      equation
        ((_, (_, {e}, _))) = replaceExprTraverser((e, (irepl, {}, false)));
        (constraintLst) = replaceOptimicaContraints(rest, irepl);
        constraintLst = listAppend({e}, constraintLst);
      then (constraintLst);
  end matchcontinue;
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
    case (NONE(), _)
      equation
        repl = BackendVarTransform.emptyReplacementsSized(BackendVariable.varsSize(aliasVars));
        repl = BackendVariable.traverseBackendDAEVars(aliasVars, getAliasVarReplacements, repl);
      then
        repl;
  end match;
end getAliasReplacements;

protected function getAliasVarReplacements "author: Frenkel TUD 2012-12"
  input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
  output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
protected
  BackendDAE.Var v;
  DAE.Exp exp;
  DAE.ComponentRef cr;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (v, repl) := inTpl;
  BackendDAE.VAR(varName=cr, bindExp=SOME(exp)) := v;
  repl := BackendVarTransform.addReplacement(repl, cr, exp, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
  outTpl := (v, repl);
end getAliasVarReplacements;

protected function replaceEquationTraverser "
  Helper function to e.g. removeSimpleEquations"
  input tuple<BackendDAE.Equation, tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Equation>, Boolean>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendVarTransform.VariableReplacements, list<BackendDAE.Equation>, Boolean>> outTpl;
algorithm
  outTpl:=
  match (inTpl)
    local
      BackendDAE.Equation e;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqns, eqns1;
      Boolean b, b1;
    case ((e, (repl, eqns, b)))
      equation
        (eqns1, b1) = BackendVarTransform.replaceEquations({e}, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        eqns = listAppend(eqns1, eqns);
      then ((e, (repl, eqns, b or b1)));
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
        exps = listAppend({exp1}, exps);
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
        exps = listAppend({NONE()}, exps);
      then ((NONE(), (repl, exps, b)));
    case ((SOME(exp), (repl, exps, b)))
      equation
        (exp1, b1) = BackendVarTransform.replaceExp(exp, repl, SOME(BackendVarTransform.skipPreChangeEdgeOperator));
        exps = listAppend({SOME(exp1)}, exps);
      then ((SOME(exp), (repl, exps, b or b1)));
  end match;
end replaceOptExprTraverser;

/*
 * functions to find unReplaceable variables
 *
 * unReplaceable:
 *   - variables with variable subscribts
 *   - variables set in when-clauses
 *   - variables used in pre
 *   - statescandidates of statesets
 *   - lhs of array assign statement, because there is a cref used and this is not replaceable_ with array of crefs
 */

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

protected function addUnreplaceableFromWhens "author: Frenkel TUD 2012-12
  collect all lhs of whens and array assign statement because these are not
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
  outUnreplaceable := BackendDAEUtil.traverseBackendDAEExpsEqns(eqns, addUnreplaceableFromEqns, outUnreplaceable);
end addUnreplaceableFromWhens;

protected function addUnreplaceableFromEqns "author: Frenkel TUD 2010-12
  helper for equationsCrefs"
  input tuple<DAE.Exp, HashSet.HashSet> inTpl;
  output tuple<DAE.Exp, HashSet.HashSet> outTpl;
protected
  HashSet.HashSet hs;
  DAE.Exp e, e1;
algorithm
  (e, hs) := inTpl;
  outTpl := Expression.traverseExp(e, addUnreplaceableFromEqnsExp, hs);
end addUnreplaceableFromEqns;

protected function addUnreplaceableFromEqnsExp "author: Frenkel TUD 2010-12"
  input tuple<DAE.Exp, HashSet.HashSet> inExp;
  output tuple<DAE.Exp, HashSet.HashSet> outExp;
algorithm
  outExp := match(inExp)
    local
      HashSet.HashSet hs;
      DAE.ComponentRef cr;
      DAE.Exp e;
    case((e as DAE.CREF(componentRef=DAE.WILD()), hs))
      then
        inExp;

    case((e as DAE.CREF(componentRef=cr), hs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
        hs = BaseHashSet.add(cr, hs);
      then
        ((e, hs ));
    // let WILD pass
    case _ then inExp;
  end match;
end addUnreplaceableFromEqnsExp;

protected function addUnreplaceableFromWhensSystem "author: Frenkel TUD 2012-12
  traverse the Whens of an  equation system to add all variables set in when"
  input BackendDAE.EqSystem isyst;
  input HashSet.HashSet inUnreplaceable;
  output HashSet.HashSet outUnreplaceable;
protected
  BackendDAE.EquationArray eqns;
algorithm
  eqns := BackendEquation.daeEqns(isyst);
  outUnreplaceable := BackendEquation.traverseBackendDAEEqns(eqns, addUnreplaceableFromWhenEqn, inUnreplaceable);
end addUnreplaceableFromWhensSystem;

protected function addUnreplaceableFromWhenEqn "author: Frenkel TUD 2012-12"
  input tuple<BackendDAE.Equation, HashSet.HashSet> inTpl;
  output tuple<BackendDAE.Equation, HashSet.HashSet> outTpl;
algorithm
  outTpl := match inTpl
    local
      BackendDAE.Equation eqn;
      HashSet.HashSet hs;
      BackendDAE.WhenEquation weqn;
      list< DAE.Statement> stmts;
    // when eqn
    case ((eqn as BackendDAE.WHEN_EQUATION(whenEquation=weqn), hs))
      equation
        hs = addUnreplaceableFromWhen(weqn, hs);
      then
        ((eqn, hs));
    // algorithm
    case ((eqn as BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst=stmts)), hs))
      equation
        hs = List.fold(stmts, addUnreplaceableFromWhenStmt, hs);
      then
       ((eqn, hs));
    else then inTpl;
  end match;
end addUnreplaceableFromWhenEqn;

protected function addUnreplaceableFromWhenStmt "author: Frenkel TUD 2012-12"
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
    case (DAE.STMT_ASSIGN_ARR(componentRef=cr), _) equation
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

protected function addUnreplaceableFromStmt "author: Frenkel TUD 2012-12"
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
    
    case (DAE.STMT_ASSIGN_ARR(componentRef=cr), _) equation
      cr = ComponentReference.crefStripLastSubs(cr);
      hs = BaseHashSet.add(cr, inHS);
    then hs;
    
    else
    then inHS;
  end match;
end addUnreplaceableFromStmt;

protected function addUnreplaceableFromWhen "author: Frenkel TUD 2012-12
  This is a helper function for addUnreplaceableFromWhenEqn."
  input BackendDAE.WhenEquation inWEqn;
  input HashSet.HashSet iHs;
  output HashSet.HashSet oHs;
algorithm
  oHs := match(inWEqn, iHs)
    local
      DAE.ComponentRef left;
      BackendDAE.WhenEquation weqn;
      HashSet.HashSet hs;
    case (BackendDAE.WHEN_EQ(left=left, elsewhenPart=NONE()), _)
      equation
        left = ComponentReference.crefStripLastSubs(left);
        hs = BaseHashSet.add(left, iHs);
      then
        hs;
    case (BackendDAE.WHEN_EQ(left=left, elsewhenPart=SOME(weqn)), _)
      equation
        left = ComponentReference.crefStripLastSubs(left);
        hs = BaseHashSet.add(left, iHs);
      then
        addUnreplaceableFromWhen(weqn, hs);
  end match;
end addUnreplaceableFromWhen;

protected function traverserUnreplaceable "author: Frenkel TUD 2012-12"
  input tuple<DAE.Exp, HashSet.HashSet> inExp;
  output tuple<DAE.Exp, HashSet.HashSet> outExp;
protected
   HashSet.HashSet unReplaceable;
   DAE.Exp e;
algorithm
  (e, unReplaceable) := inExp;
  outExp := Expression.traverseExp(e, traverserExpUnreplaceable, unReplaceable);
end traverserUnreplaceable;

protected function traverserExpUnreplaceable "author: Frenkel TUD 2012-12"
  input tuple<DAE.Exp, HashSet.HashSet> inExp;
  output tuple<DAE.Exp, HashSet.HashSet> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      HashSet.HashSet unReplaceable;
      DAE.Exp e;
      DAE.ComponentRef cr;
      list<DAE.Exp> explst;
      list<DAE.ComponentRef> crlst;
    case((e as DAE.CREF(componentRef = cr), unReplaceable))
      equation
        unReplaceable = traverseCrefUnreplaceable(cr, NONE(), unReplaceable);
      then
        ((e, unReplaceable));
     case((e as DAE.CALL(path=Absyn.IDENT(name = "pre"), expLst=explst), unReplaceable))
      equation
        crlst = List.flatten(List.map(explst, Expression.extractCrefsFromExp));
        crlst = List.map(crlst, ComponentReference.crefStripLastSubs);
        unReplaceable = List.fold(crlst, BaseHashSet.add, unReplaceable);
      then
        ((e, unReplaceable));
    case _ then inExp;
  end matchcontinue;
end traverserExpUnreplaceable;

protected function traverseCrefUnreplaceable "author: Frenkel TUD 2012-12"
  input DAE.ComponentRef inCref;
  input Option<DAE.ComponentRef> preCref;
  input HashSet.HashSet iUnreplaceable;
  output HashSet.HashSet oUnreplaceable;
algorithm
  oUnreplaceable := match(inCref, preCref, iUnreplaceable)
    local
      DAE.Ident name;
      DAE.ComponentRef cr, pcr;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      HashSet.HashSet unReplaceable;
      Boolean b;
    case (DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), SOME(pcr), _)
      equation
        (_, b) = Expression.traverseExpCref(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
        pcr = Debug.bcallret4(b, ComponentReference.crefPrependIdent, pcr, name, {}, ty, pcr);
        unReplaceable = Debug.bcallret2(b, BaseHashSet.add, pcr, iUnreplaceable, iUnreplaceable);
        pcr = ComponentReference.crefPrependIdent(pcr, name, subs, ty);
      then
        traverseCrefUnreplaceable(cr, SOME(pcr), unReplaceable);
    case (DAE.CREF_QUAL(ident = name, identType = ty, subscriptLst = subs, componentRef = cr), NONE(), _)
      equation
        (_, b) = Expression.traverseExpCref(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
        pcr = DAE.CREF_IDENT(name, ty, {});
        unReplaceable = Debug.bcallret2(b, BaseHashSet.add, pcr, iUnreplaceable, iUnreplaceable);
      then
        traverseCrefUnreplaceable(cr, SOME(DAE.CREF_IDENT(name, ty, subs)), unReplaceable);

    case (DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), SOME(pcr), _)
      equation
        (_, b) = Expression.traverseExpCref(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
        pcr = ComponentReference.crefPrependIdent(pcr, name, {}, ty);
        unReplaceable = Debug.bcallret2(b, BaseHashSet.add, pcr, iUnreplaceable, iUnreplaceable);
      then
        unReplaceable;
    case (DAE.CREF_IDENT(ident = name, identType = ty, subscriptLst = subs), NONE(), _)
      equation
        (_, b) = Expression.traverseExpCref(DAE.CREF_IDENT(name, ty, subs), Expression.traversingComponentRefPresent, false);
        pcr = DAE.CREF_IDENT(name, ty, {});
        unReplaceable = Debug.bcallret2(b, BaseHashSet.add, pcr, iUnreplaceable, iUnreplaceable);
      then
        unReplaceable;

    case (DAE.CREF_ITER(ident = _), _, _) then iUnreplaceable;
    case (DAE.OPTIMICA_ATTR_INST_CREF(componentRef = _), _, _) then iUnreplaceable;
    case (DAE.WILD(), _, _) then iUnreplaceable;
  end match;
end traverseCrefUnreplaceable;

protected function negateExpression
"@author: adrpo
 negate an expression with a debug message"
  input Boolean negationFlag;
  input DAE.Exp inExp "the expression we should negate if flag is true";
  input DAE.Exp inAlternative "the expression we should return if flag is false";
  input String message;
  output DAE.Exp outExpression;
algorithm
  outExpression := matchcontinue(negationFlag, inExp, inAlternative, message)
    local DAE.Exp exp, negatedExp, negate;
    // we should negate
    case (true, _, _, _)
      equation
        negatedExp = Expression.negate(inExp);
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStr, ("Negating: ", inExp, " " +& message +& ".\n"));
      then
        negatedExp;
    // we should not negate
    case (false, _, _, _)
      equation
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrExpStrExpStr, ("Not negating: ", inExp, " returning: ", inAlternative, " " +& message +& ".\n"));
      then
        inAlternative;
  end matchcontinue;
end negateExpression;

end RemoveSimpleEquations;
