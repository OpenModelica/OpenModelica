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

encapsulated package CommonSubExpression
" file:        CommonSubExpression.mo
  package:     CommonSubExpression
  description: This package contains functions for the optimization modules
               wrapFunctionCalls, commonSubExpressionReplacement and cseBinary."


public
import BackendDAE;
import DAE;

protected
import Array;
import AvlSetInt;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVarTransform;
import BackendVariable;
import BaseHashTable;
import ComponentReference;
import DAEUtil;
import ExpandableArray;
import Expression;
import ExpressionDump;
import ExpressionSolve;
import ExpressionSimplify;
import GC;
import Global;
import HashSet;
import HashTableExpToExp;
import HashTableExpToIndex;
import HpcOmTaskGraph;
import List;
import ResolveLoops;
import Types;

uniontype CSE_Equation
  record CSE_EQUATION
    DAE.Exp cse "lhs";
    DAE.Exp call "rhs";
    list<Integer> dependencies;
  end CSE_EQUATION;
end CSE_Equation;

constant CSE_Equation dummy_equation = CSE_EQUATION(DAE.RCONST(0.0), DAE.RCONST(0.0), {});
constant Boolean debug = false;
constant String BORDER = "###############################################################";
constant String UNDERLINE = "========================================";

protected function printCSEEquation
  input CSE_Equation cseEquation;
  output String str;
protected
  Boolean first = true;
algorithm
  str := ExpressionDump.printExpStr(cseEquation.cse) + " - " + ExpressionDump.printExpStr(cseEquation.call) + " - {";

  for i in cseEquation.dependencies loop
    if first then
      str := str + intString(i);
      first := false;
    else
      str := str + ", " + intString(i);
    end if;
  end for;

  str := str + "}";
end printCSEEquation;

public function wrapFunctionCalls "
  This function traverses the equation systems and looks for function calls to store in $cse variables.
  This avoids unnecessary function evaluations.
  Main function: is called by postOpt and SymbolicJacobian
  authors: Jan Hagemann, Lennart Ochel and Patrick Täuber (FH Bielefeld, Germany)"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  Integer size;
  HashTableExpToIndex.HashTable HT "call -> index";
  ExpandableArray<CSE_Equation> exarray "id -> (cse, call, dependencies)";

  Integer cseIndex = System.tmpTickIndex(Global.backendDAE_cseIndex);
  Integer index;

  BackendDAE.Shared shared;
  DAE.FunctionTree functionTree;
  BackendDAE.EquationArray orderedEqs, orderedEqs_new;
  BackendDAE.Variables orderedVars, globalKnownVars;
  list<BackendDAE.EqSystem> eqSystems = {};
  list<BackendDAE.Var> varList;
  String daeTypeStr = BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType);
  Boolean isSimulationDAE = stringEq(daeTypeStr, "simulation");

  HashSet.HashSet globalKnownVarHT;

  DAE.Exp cse, call;
  list<Integer> dependencies;
algorithm
  size := BackendDAEUtil.maxSizeOfEqSystems(inDAE.eqs) + 42;   //create data structures independent from the size of the EqSystem
  exarray := ExpandableArray.new(size, dummy_equation);

  size := Util.nextPrime(realInt(2.4*size));
  HT := HashTableExpToIndex.emptyHashTableSized(size);

  shared := inDAE.shared;
  BackendDAE.SHARED(globalKnownVars=globalKnownVars,functionTree=functionTree) := shared;

  // Create Hashtable and store globally known variables in it
  globalKnownVarHT := HashSet.emptyHashSetSized(Util.nextPrime(realInt(2.4*(globalKnownVars.numberOfVars + 42))));
  if isSimulationDAE then
    globalKnownVarHT := BackendVariable.traverseBackendDAEVars(globalKnownVars, VarToGlobalKnownVarHT, globalKnownVarHT);
  end if;

  if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
    print("Start optimization module wrapFunctionCalls for " + daeTypeStr + " DAE\n" + BORDER + BORDER + "\n\n\n");
    print("Phase 0: Set up data structure\n" + BORDER + "\n");
    BackendDump.dumpVariables(globalKnownVars, "globalKnownVars before WFC");
    print("globalKnownVarHT before algorithm\n" + UNDERLINE + "\n");
    BaseHashSet.dumpHashSet(globalKnownVarHT);
  end if;

  // Start the WFC algorithm for all equation systems
  for syst in inDAE.eqs loop
    if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
      print("\n\nHandle system (belongs to " + daeTypeStr + " DAE):\n" + BORDER + "\n");
      BackendDump.dumpVariables(syst.orderedVars, "Variables");
      BackendDump.dumpEquationArray(syst.orderedEqs, "Equations");
      print("\nPhase 1: Analysis\n" + BORDER + "\n");
    end if;

    HT := BaseHashTable.clear(HT);
    exarray := ExpandableArray.clear(exarray);
    index := 0;

    orderedEqs := syst.orderedEqs;
    orderedVars := syst.orderedVars;

    // Phase 1: Analysis
    (HT, exarray, cseIndex, index, _) := BackendEquation.traverseEquationArray(orderedEqs, wrapFunctionCalls_analysis, (HT, exarray, cseIndex, index, functionTree));

    if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
      print("Hastable after analysis\n" + UNDERLINE + "\n");
      BaseHashTable.dumpHashTable(HT);
      print(ExpandableArray.toString(exarray, "\nExpandable Array after analysis", printCSEEquation));
    end if;

    if index > 0 then
      // Phase 2: Dependencies
      exarray := determineDependencies(exarray, HT);

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\n\nPhase 2: Dependencies\n" + BORDER + "\n\n");
        print("Hashtable after dependencies\n" + UNDERLINE + "\n");
        BaseHashTable.dumpHashTable(HT);
        print(ExpandableArray.toString(exarray, "\nExpandable Array after dependencies", printCSEEquation));
        print("\n\nPhase3: Substitution\n" + BORDER + "\n");
      end if;

      // Phase 3: Substitution
      orderedEqs_new := BackendEquation.emptyEqnsSized(ExpandableArray.getNumberOfElements(orderedEqs) + ExpandableArray.getNumberOfElements(exarray));
      (HT, exarray, orderedEqs_new) := BackendEquation.traverseEquationArray(orderedEqs, wrapFunctionCalls_substitution, (HT, exarray, orderedEqs_new));

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("Hashtable after substitution\n" + UNDERLINE + "\n");
        BaseHashTable.dumpHashTable(HT);
        print(ExpandableArray.toString(exarray, "\nExpandable Array after substitution", printCSEEquation));
        print("\n\nPhase 4: Create CSE-Equations\n" + BORDER + "\n\n");
      end if;

      // Phase 4: Create CSE equations
      (orderedEqs_new, orderedVars, globalKnownVars) := createCseEquations(exarray, orderedEqs_new, orderedVars, globalKnownVars, globalKnownVarHT);

      syst.orderedEqs := orderedEqs_new;
      syst.orderedVars := orderedVars;

      // Check for unbalanced system
      if not intEq(BackendEquation.equationArraySize(orderedEqs_new), orderedVars.numberOfVars) then
        Error.addCompilerWarning("After manipulating the system with postOptModule wrapFunctionCalls the system is unbalanced. This indicates that the original system is singular. You can use -d=dumpCSE and -d=dumpCSE_verbose for more information.");
      end if;

      // Reset Matching
      syst.m := NONE();
      syst.mT := NONE();
      syst.matching := BackendDAE.NO_MATCHING();

      if Flags.isSet(Flags.DUMP_CSE) or Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\n\n\n" + BORDER + "\nFinal Results\n" + BORDER + "\n");
        BackendDump.dumpVariables(syst.orderedVars, "########### Updated Variable List (" + BackendDump.printBackendDAEType2String(shared.backendDAEType) + ")");
        BackendDump.dumpEquationArray(syst.orderedEqs, "########### Updated Equation List (" + BackendDump.printBackendDAEType2String(shared.backendDAEType) + ")");
        BackendDump.dumpVariables(globalKnownVars, "########### Updated globalKnownVars (" + BackendDump.printBackendDAEType2String(shared.backendDAEType) + ")");
        print(ExpandableArray.toString(exarray, "\n########### CSE Replacements", printCSEEquation));
      end if;

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\n\n" + BORDER);
        BackendDump.dumpEqSystem(syst, "Final EqSystem");
      end if;
    else
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\n" + BORDER + "\nNo function calls found. Exiting the algorithm...\n\n\n");
      end if;
    end if;

    eqSystems := syst::eqSystems;
  end for;

  shared.globalKnownVars := globalKnownVars;

  System.tmpTickSetIndex(cseIndex, Global.backendDAE_cseIndex);
  eqSystems := MetaModelica.Dangerous.listReverseInPlace(eqSystems);
  outDAE := BackendDAE.DAE(eqSystems, shared);
end wrapFunctionCalls;

protected function VarToGlobalKnownVarHT
" Adds all globalKnownVars with bindExp to globalKnownVarHT except inputs and nonfixed parameters"
  input BackendDAE.Var inVar;
  input HashSet.HashSet inGlobalKnownVarHT;
  output BackendDAE.Var outVar = inVar;
  output HashSet.HashSet outGlobalKnownVarHT = inGlobalKnownVarHT;
algorithm
  // To-Do: Move inputs to localKnownVars
  if not BackendVariable.isInput(inVar) and not (BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar)) and isSome(inVar.bindExp) then
    outGlobalKnownVarHT := BaseHashSet.add(BackendVariable.varCref(inVar), inGlobalKnownVarHT);
  end if;
end VarToGlobalKnownVarHT;

protected function findCallsInGlobalKnownVars
"This function traverses the globalKnownVars and looks for function calls. The calls are stored in the HT/expArray"
  input BackendDAE.Var inVar;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> inTuple;
  output BackendDAE.Var outVar = inVar;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> outTuple = inTuple;
protected
  DAE.Exp exp;
  BackendDAE.Equation eq;
algorithm
  // To-Do: Move inputs to localKnownVars
  if not BackendVariable.isInput(inVar) and not (BackendVariable.isParam(inVar) and not BackendVariable.varFixed(inVar)) and isSome(inVar.bindExp) then
    SOME(exp):= inVar.bindExp;
    if isCall(exp) then
      eq := BackendEquation.generateEquation(DAE.CREF(inVar.varName, inVar.varType), exp);
      (_, outTuple) := wrapFunctionCalls_analysis(eq, inTuple);
    end if;
  end if;
end findCallsInGlobalKnownVars;

protected function wrapFunctionCalls_substitution
"Third phase of the WFC algorithm: The found function calls in the equation system which are stored in the HT are replaced by its cse-variables."
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, BackendDAE.EquationArray> inTuple;
  output BackendDAE.Equation outEq = inEq;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, BackendDAE.EquationArray> outTuple;
protected
  HashTableExpToIndex.HashTable HT;
  ExpandableArray<CSE_Equation> exarray;
  BackendDAE.EquationArray orderedEqs_new;
  BackendDAE.Equation eq;
algorithm
  (HT, exarray, orderedEqs_new) := inTuple;

  _ := match(inEq)
    case BackendDAE.COMPLEX_EQUATION() equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        BackendDump.dumpEquationList({inEq}, "wrapFunctionCalls_substitution (COMPLEX_EQUATION)");
      end if;

      (eq, (HT, exarray, orderedEqs_new)) = BackendEquation.traverseExpsOfEquation(inEq, wrapFunctionCalls_substitution2, (HT, exarray, orderedEqs_new));

      if not isEquationRedundant(eq) then
        orderedEqs_new = BackendEquation.add(eq, orderedEqs_new);
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          BackendDump.dumpEquationList({eq}, "isEquationRedundant? no");
        end if;
      else
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          BackendDump.dumpEquationList({eq}, "isEquationRedundant? yes");
        end if;
      end if;
    then ();

    case BackendDAE.EQUATION() equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        BackendDump.dumpEquationList({inEq}, "wrapFunctionCalls_substitution (EQUATION)");
      end if;

      (eq, (HT, exarray, orderedEqs_new)) = BackendEquation.traverseExpsOfEquation(inEq, wrapFunctionCalls_substitution2, (HT, exarray, orderedEqs_new));

      if not isEquationRedundant(eq) then
        orderedEqs_new = BackendEquation.add(eq, orderedEqs_new);
      end if;
    then ();

    // all other cases are not handled (e.g. algorithms)
    else equation
      orderedEqs_new = BackendEquation.add(inEq, orderedEqs_new);
    then ();
  end match;

  outTuple := (HT, exarray, orderedEqs_new);
end wrapFunctionCalls_substitution;

protected function wrapFunctionCalls_substitution2
  input DAE.Exp inExp;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, BackendDAE.EquationArray> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, BackendDAE.EquationArray> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpBottomUp(inExp, wrapFunctionCalls_substitution3, inTuple);
end wrapFunctionCalls_substitution2;

protected function wrapFunctionCalls_substitution3
  input DAE.Exp inExp;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, BackendDAE.EquationArray> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, BackendDAE.EquationArray> outTuple;
protected
  HashTableExpToIndex.HashTable HT;
  ExpandableArray<CSE_Equation> exarray;
  BackendDAE.EquationArray orderedEqs_new;
  Integer id, ix;
  DAE.Exp cse, call, tmp;
  list<DAE.Exp> PR;
  list<Integer> dependencies;
algorithm
  (HT, exarray, orderedEqs_new) := inTuple;

  if Expression.isCall(inExp) and BaseHashTable.hasKey(inExp, HT) then
    id := BaseHashTable.get(inExp, HT);
    CSE_EQUATION(cse=cse, call=call, dependencies=dependencies) := ExpandableArray.get(id, exarray);
    (HT, exarray) := substituteDependencies(dependencies, HT, exarray, call, cse);
    ExpandableArray.update(id, CSE_EQUATION(cse, call, {}), exarray);
    outExp := cse;
  elseif Expression.isTSUB(inExp) then
    DAE.TSUB(exp=tmp, ix=ix) := inExp;
    if Expression.isTuple(tmp) then
      DAE.TUPLE(PR) := tmp;
      outExp := listGet(PR, ix);
    else
      outExp := inExp;
    end if;
  else
    outExp := inExp;
  end if;

  outTuple := (HT, exarray, orderedEqs_new);
end wrapFunctionCalls_substitution3;

protected function substituteDependencies
  input list<Integer> inDependencies;
  input output HashTableExpToIndex.HashTable ht;
  input output ExpandableArray<CSE_Equation> exarray;
  input DAE.Exp inCall;
  input DAE.Exp inCSE;
protected
  DAE.Exp cse, call;
  list<Integer> dependencies;

  DAE.Exp cse2, call2;
  list<Integer> dependencies2;

  Integer id2;
algorithm
  for id in inDependencies loop
    CSE_EQUATION(cse=cse, call=call, dependencies=dependencies) := ExpandableArray.get(id, exarray);
    call := substituteExp(call, inCall, inCSE);

    //ExpandableArray.toString(exarray, "substituteDependencies", printCSEEquation);
    //print("Exp: " + ExpressionDump.printExpStr(call) + "\n");

    if not BaseHashTable.hasKey(call, ht) then
      ht := BaseHashTable.add((call, id), ht);
      ExpandableArray.update(id, CSE_EQUATION(cse, call, dependencies), exarray);
    else
      id2 := BaseHashTable.get(call, ht);
      CSE_EQUATION(cse=cse2, call=call2, dependencies=dependencies2) := ExpandableArray.get(id2, exarray);
      cse2 := mergeCSETuples(cse, cse2);
      ExpandableArray.update(id2, CSE_EQUATION(cse2, call, List.unique(listAppend(dependencies,dependencies2))), exarray);
      ExpandableArray.update(id, CSE_EQUATION(cse, cse2, {}), exarray);


      //print("substituteDependencies: not handled yet\n");
      //print("id: " + intString(id) + "\n");
      //print("inCall: " + ExpressionDump.printExpStr(inCall) + "\n");
      //print("inCSE: " + ExpressionDump.printExpStr(inCSE) + "\n");
      //BaseHashTable.dumpHashTable(ht);
      //ExpandableArray.toString(exarray, "substituteDependencies", printCSEEquation);
    end if;
  end for;
end substituteDependencies;

protected function substituteExp
  input DAE.Exp inExp;
  input DAE.Exp inKey;
  input DAE.Exp inValue;
  output DAE.Exp outExp;
algorithm
  outExp := Expression.traverseExpTopDown(inExp, substituteExp2, (inKey, inValue));
end substituteExp;

protected function substituteExp2
  input DAE.Exp inExp;
  input tuple<DAE.Exp, DAE.Exp> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.Exp, DAE.Exp> outTuple = inTuple;
protected
  DAE.Exp key, value, tmp;
  list<DAE.Exp> expList;
  Integer ix;
algorithm
  (key, value) := inTuple;

  if Expression.expEqual(inExp, key) then
    outExp := value;
    cont := false;
  elseif Expression.isTSUB(inExp) then
    DAE.TSUB(exp=tmp, ix=ix) := inExp;
    if Expression.expEqual(tmp, key) then
      DAE.TUPLE(expList) := value;
      outExp := listGet(expList, ix);
      cont := false;
    else
      outExp := inExp;
      cont := true;
    end if;
  else
    outExp := inExp;
    cont := true;
  end if;
end substituteExp2;

protected function createCseEquations
" Fourth phase of the WFC algorithm:
  Creates CSE equations from the expandable array and stores them in the correct data structure:
  1) cse var (i.e. function call) with $cse-prefix is dependending on variables
       -> store eqn in orderedEqs and var in orderedVars
  2) cse var (i.e. function call) without $cse-prefix is dependending on variables
       -> store eqn in orderedEqs
  3) cse var (i.e. function call) with $cse-prefix is only dependending on globally known variables
       -> store var in globalKnownVars (bindExp=call)
  4) cse var (i.e. function call) without $cse-prefix is only dependending on globally known variables
       -> store var in globalKnownVars (bindExp=call) and delete var from orderedVars
  author: ptaeuber"
  input ExpandableArray<CSE_Equation> exarray "id -> (cse, call, dependencies)";
  input output BackendDAE.EquationArray orderedEqs "equations of the system";
  input output BackendDAE.Variables orderedVars;
  input output BackendDAE.Variables globalKnownVars;
  input output HashSet.HashSet globalKnownVarHT;
protected
  DAE.Exp cse, call;
  list<DAE.Exp> callArg;
  BackendDAE.Equation eq;
  list<DAE.ComponentRef> crefList;
  DAE.ComponentRef cr;
  BackendDAE.Var var;
  list<BackendDAE.Var> varList, delVars;
  Boolean isGlobalKnown, eqRedundant, add;
  list<Integer> var_indexes;
algorithm
  if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
    print("globalKnownVars:\n" + UNDERLINE + "\n");
    BaseHashSet.dumpHashSet(globalKnownVarHT);
    print("\nTraverse expandable array\n"  + UNDERLINE + "\n");
  end if;
  for i in ExpandableArray.getNumberOfElements(exarray):-1:1 loop
    add := true;
    CSE_EQUATION(cse=cse, call=call) := ExpandableArray.get(i, exarray);
    if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
      print("\n--> cse-equation: " + ExpressionDump.printExpStr(cse) + " = " + ExpressionDump.printExpStr(call) + "\n");
    end if;

    eq := BackendEquation.generateEquation(cse, call);
    (globalKnownVarHT, globalKnownVars, orderedVars, eqRedundant, isGlobalKnown) := isEquationRedundant_flatten(eq, globalKnownVarHT, globalKnownVars, orderedVars);

    if debug then print("\ndebug 1 - eq redundant?\n"); end if;
    if not eqRedundant then
      if debug then print("\ndebug 2 - no, not redundant. let's loop\n"); end if;
      varList := createVarsForExp(cse);
      // If cse is a constant number add the equation
      if listEmpty(varList) then
        orderedEqs := BackendEquation.add(eq, orderedEqs);
      else
        for var in varList loop
          if debug then print("\ndebug 3 - handle var: " + BackendDump.varString(var) + " Is it a globalKnownVar?\n"); end if;
          cr := BackendVariable.varCref(var);
          // Variable is not in globalKnownVars HT
          if not isGlobalKnown then
            if debug then print("\ndebug 4 - The variable is not a globalKnownVar. Should an equation be added?\n"); end if;
            if add then
              if debug then print("\ndebug 5 - yes, definitely!\n"); end if;
              orderedEqs := BackendEquation.add(eq, orderedEqs);
              add := false;
            end if;
            if debug then print("\ndebug 6 - Is this cref a CSE cref?: " + ExpressionDump.printExpStr(Expression.crefExp(cr)) + "\n"); end if;
            if isCSECref(cr) then
              if debug then print("\ndebug 7 - yes it is a CSE cref. Add to orderedVars!\n"); end if;
              orderedVars := BackendVariable.addVar(var, orderedVars);
            end if;
            if debug then print("\ndebug 8\n"); end if;

          // Variable is in globalKnownVars HT: Add it to globalKnownVars and not to ordered vars and do not create a cse-equation
          else
            if debug then print("\ndebug 9 - The variable is a globalKnownVar.\n"); end if;

            if not isCSECref(cr) then
              if debug then print("\ndebug 10 - The globalKnownVar is no CSE cref, so copy attributes and delete it from orderedVars if it is in that list.\n"); end if;
              (delVars, orderedVars) := BackendVariable.deleteVarIfExistsAndReturn(cr, orderedVars);
              if listEmpty(delVars) then
                (delVars, _) := BackendVariable.getVar(cr, globalKnownVars);
              end if;
              var := listGet(delVars, 1);
            end if;

            // Save the rhs (call) as bind expression and set fixed=true
            var := BackendVariable.setBindExp(var, SOME(call));
            var := BackendVariable.setVarFixed(var, true);

            // If it is a tuple or a record (or record within tuple)
            if intGt(listLength(varList), 1) or Expression.isTuple(cse) then
              if debug then print("\ndebug 11 - It is a tuple! Add it to tplExp\n"); end if;
              var.tplExp := SOME(cse);
            end if;

            if debug then print("\ndebug 12 - Add the variable to globalKnownVars\n"); end if;
            // Add var to globalKnownVars
            globalKnownVars := BackendVariable.addVar(var, globalKnownVars);

          end if;
        end for;
      end if;
    end if;
  end for;
  if debug then print("\ndebug 13\n"); end if;
end createCseEquations;

protected function determineDependencies
"Second phase of the WFC algorithm: Finds the dependencies between nested function calls and stores them in the expandable array."
  input output ExpandableArray<CSE_Equation> exarray "id -> (cse, call, dependencies)";
  input HashTableExpToIndex.HashTable HT "call -> index";
protected
  list<DAE.Exp> callArguments;
algorithm
  for i in 1:ExpandableArray.getNumberOfElements(exarray) loop
    CSE_EQUATION(call=DAE.CALL(expLst=callArguments)) := ExpandableArray.get(i, exarray);
    (_, (_, exarray, _)) := Expression.traverseExpList(callArguments, determineDependencies2, (HT, exarray, i));
  end for;
end determineDependencies;

protected function determineDependencies2
  input DAE.Exp inExp;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer> inTuple;
  output DAE.Exp outExp = inExp;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer> outTuple;
protected
  Integer id, index;
  list<Integer> dependencies;
  HashTableExpToIndex.HashTable HT;
  ExpandableArray<CSE_Equation> exarray;
  DAE.Exp cse, call;
algorithm
  if Expression.isCall(inExp) then
    (HT, exarray, index) := inTuple;

    if BaseHashTable.hasKey(inExp, HT) then
      id := BaseHashTable.get(inExp, HT);
      CSE_EQUATION(cse=cse, call=call, dependencies=dependencies) := ExpandableArray.get(id, exarray);
      if not listMember(index, dependencies) then
        dependencies := index::dependencies;
        ExpandableArray.update(id, CSE_EQUATION(cse, call, dependencies), exarray);
      end if;
    end if;

    outTuple := (HT, exarray, index);
  else
    outTuple := inTuple;
  end if;
end determineDependencies2;

protected function allArgsInGlobalKnownVars
"Returns true if all call arguments are globally known"
  input list<DAE.Exp> callArgs;
  input HashSet.HashSet globalKnownVarHT;
  output Boolean allCrefsAreGlobal = true;
protected
  list<DAE.ComponentRef> crefList;
algorithm
  (_,crefList) := Expression.traverseExpList(callArgs, Expression.traversingComponentRefFinder, {});
  for cr in crefList loop
    if allCrefsAreGlobal then
      allCrefsAreGlobal := BaseHashSet.has(cr, globalKnownVarHT);
    else
      return;
    end if;
  end for;
end allArgsInGlobalKnownVars;

protected function addConstantCseVarsToGlobalKnownVarHT
"Adds the cse variable to the globalKnownVarHT. For tuples the crefs are stored separately.
 author: ptaeuber"
  input DAE.Exp cse_crExp;
  input output HashSet.HashSet globalKnownVarHT;
algorithm
  _ :=  match(cse_crExp)
    local
      list<DAE.Exp> expLst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;

    case(DAE.TUPLE(PR = expLst))
      algorithm
        for exp in expLst loop
          if Expression.isNotWild(exp) then
            globalKnownVarHT := addConstantCseVarsToGlobalKnownVarHT(exp, globalKnownVarHT);
          end if;
        end for;
     then ();

    case DAE.CREF(componentRef=cr, ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))
      algorithm
        globalKnownVarHT := BaseHashSet.add(cr, globalKnownVarHT);
        crefs := ComponentReference.expandCref(cr, true /*the way it is now we won't get records here. but if we do somehow expand them*/);

        for cr_ in crefs loop
          globalKnownVarHT := BaseHashSet.add(cr_, globalKnownVarHT);
        end for;
     then ();

    case DAE.CREF(componentRef=cr) guard(Expression.isArrayType(Expression.typeof(cse_crExp)))
      algorithm
        globalKnownVarHT := BaseHashSet.add(cr, globalKnownVarHT);
        crefs := ComponentReference.expandCref(cr, true);

        for cr_ in crefs loop
          globalKnownVarHT := BaseHashSet.add(cr_, globalKnownVarHT);
        end for;
     then ();

    case(DAE.CREF(componentRef=cr))
      algorithm
        globalKnownVarHT := BaseHashSet.add(cr, globalKnownVarHT);
     then ();
  end match;
end addConstantCseVarsToGlobalKnownVarHT;

protected function wrapFunctionCalls_analysis
"First phase of the WFC algorithm: The equation system is traversed and all occuring function calls are stored in the HT and the expandable array."
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> inTuple;
  output BackendDAE.Equation outEq = inEq;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> outTuple;
protected
  DAE.FunctionTree functionTree;
  HashTableExpToIndex.HashTable HT;
  ExpandableArray<CSE_Equation> exarray;

  Integer cseIndex, exIndex, index, ix;
  DAE.Exp lhs, rhs;
  DAE.Exp cref, call;
  DAE.Exp exp;
  list<DAE.Exp> expLst;
  DAE.Type ty;
  list<DAE.Type> types;
  CSE_Equation cseEquation;
  Boolean allCrefsAreGlobal = true;
  list<DAE.ComponentRef> crefList;
  list<BackendDAE.Var> varList;
algorithm
  (HT, exarray, cseIndex, index, functionTree) := inTuple;

  _ := match(inEq)
    case BackendDAE.COMPLEX_EQUATION(left=lhs, right=rhs) algorithm
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        BackendDump.dumpEquationList({inEq}, "wrapFunctionCalls_analysis (COMPLEX_EQUATION)");
      end if;

      // TUPLE = CALL
      // ************
      if isCallAndTuple(lhs, rhs) then
        (cref, call) := getTheRightPattern(lhs, rhs);

        // Tuple is already in HT
        if BaseHashTable.hasKey(call, HT) then
          exIndex := BaseHashTable.get(call, HT);
          cseEquation := ExpandableArray.get(exIndex, exarray);
          cseEquation.cse := mergeCSETuples(cseEquation.cse, cref);
          exarray := ExpandableArray.update(exIndex, cseEquation, exarray);

        // Tuple is not already in HT
        elseif not isSkipCase(call, functionTree) then
          index := index + 1;
          HT := BaseHashTable.add((call, index), HT);
          exarray := ExpandableArray.set(index, CSE_EQUATION(cref, call, {}), exarray);
        end if;

      // RECORD = CALL
      // *************
      elseif isCallAndRecord(lhs, rhs) then
        (cref, call) := getTheRightPattern(lhs, rhs);
        if BaseHashTable.hasKey(call, HT) then
          exIndex := BaseHashTable.get(call, HT);
          cseEquation := ExpandableArray.get(exIndex, exarray);
          cseEquation.cse := cref;
          exarray := ExpandableArray.update(exIndex, cseEquation, exarray);

        elseif not isSkipCase(call, functionTree) then
          index := index + 1;
          HT := BaseHashTable.add((call, index), HT);
          exarray := ExpandableArray.set(index, CSE_EQUATION(cref, call, {}), exarray);
        end if;
      end if;

      (_, (HT, exarray, cseIndex, index, functionTree)) := BackendEquation.traverseExpsOfEquation(inEq, wrapFunctionCalls_analysis2, (HT, exarray, cseIndex, index, functionTree));
    then ();

    case BackendDAE.EQUATION(exp=lhs, scalar=rhs) algorithm
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        BackendDump.dumpEquationList({inEq}, "wrapFunctionCalls_analysis (EQUATION)");
      end if;

      // CREF = CALL or CONST = CALL
      // ***************************
      if isCallAndCref(lhs, rhs) or isConstAndCall(lhs, rhs) then
        (cref, call) := getTheRightPattern(lhs, rhs);

        if BaseHashTable.hasKey(call, HT) then
          exIndex := BaseHashTable.get(call, HT);
          cseEquation := ExpandableArray.get(exIndex, exarray);
          cseEquation.cse := cref;
          exarray := ExpandableArray.update(exIndex, cseEquation, exarray);

        elseif not isSkipCase(call, functionTree) then
          index := index + 1;
          HT := BaseHashTable.add((call, index), HT);
          exarray := ExpandableArray.set(index, CSE_EQUATION(cref, call, {}), exarray);
        end if;

      // CREF = TSUB
      // ***********
      elseif isTsubAndCref(lhs, rhs) then
        (cref, DAE.TSUB(call as DAE.CALL(attr=DAE.CALL_ATTR(ty=DAE.T_TUPLE(types=types))),ix,_)) := getTheRightPattern(lhs, rhs);
        if BaseHashTable.hasKey(call, HT) then
          exIndex := BaseHashTable.get(call, HT);
          cseEquation := ExpandableArray.get(exIndex, exarray);
          cref := createCrefForTsub(listLength(types), ix, cref);
          cseEquation.cse := mergeCSETuples(cseEquation.cse, cref);
          exarray := ExpandableArray.update(exIndex, cseEquation, exarray);

        elseif not isSkipCase(call, functionTree) then
          index := index + 1;
          HT := BaseHashTable.add((call, index), HT);
          cref := createCrefForTsub(listLength(types), ix, cref);
          exarray := ExpandableArray.set(index, CSE_EQUATION(cref, call, {}), exarray);
        end if;
      end if;

      (_, (HT, exarray, cseIndex, index, functionTree)) := BackendEquation.traverseExpsOfEquation(inEq, wrapFunctionCalls_analysis2, (HT, exarray, cseIndex, index, functionTree));
    then ();

    // all other cases are not handled (e.g. algorithms)
    else ();
  end match;


  outTuple := (HT, exarray, cseIndex, index, functionTree);
end wrapFunctionCalls_analysis;

protected function createCrefForTsub "(4, 2, x)  -> TUPLE(_,x,_,_)"
  input Integer length;
  input Integer ix;
  input DAE.Exp cref;
  output DAE.Exp outCref;
protected
  list<DAE.Exp> expList = {};
algorithm
  for i in 1:ix-1 loop
    expList := DAE.CREF(DAE.WILD(),DAE.T_UNKNOWN_DEFAULT)::expList;
  end for;
  expList := cref::expList;
  for i in ix+1:length loop
    expList := DAE.CREF(DAE.WILD(),DAE.T_UNKNOWN_DEFAULT)::expList;
  end for;
  outCref := DAE.TUPLE(listReverse(expList));
end createCrefForTsub;

protected function wrapFunctionCalls_analysis2
  input DAE.Exp inExp;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> inTuple;
  output DAE.Exp outExp = inExp;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> outTuple;
algorithm
  (_, outTuple) := Expression.traverseExpTopDown(inExp, wrapFunctionCalls_analysis3, inTuple);
end wrapFunctionCalls_analysis2;


protected function wrapFunctionCalls_analysis3
  input DAE.Exp inExp;
  input tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> inTuple;
  output DAE.Exp outExp = inExp;
  output Boolean cont;
  output tuple<HashTableExpToIndex.HashTable, ExpandableArray<CSE_Equation>, Integer, Integer, DAE.FunctionTree> outTuple;
protected
  DAE.FunctionTree functionTree;
  HashTableExpToIndex.HashTable HT;
  ExpandableArray<CSE_Equation> exarray;
  Integer cseIndex, index;
  list<DAE.ComponentRef> crefList;
  DAE.Exp tsub;
algorithm
  (HT, exarray, cseIndex, index, functionTree) := inTuple;

  cont := match(inExp)
    local
      DAE.Exp cse_var, cse_var2, call, e, e2;
      DAE.Type ty;
      list<DAE.Type> types;
      Integer length, ix, id;
      list<DAE.Exp> expList={}, expLst;
      CSE_Equation cseEquation;
      Boolean allCrefsAreGlobal = true;
      DAE.ComponentRef cr;

    case DAE.IFEXP()
      algorithm
        (_, outTuple) := Expression.traverseExpTopDown(inExp.expCond, wrapFunctionCalls_analysis3, inTuple);
        cont := false;
        return;
      then fail();

    // TODO: split up skip cases
    case _
    guard isSkipCase(inExp, functionTree)
    then false;

    case tsub as DAE.TSUB(exp=call as DAE.CALL(attr=DAE.CALL_ATTR(ty=DAE.T_TUPLE(types=types))), ix=ix, ty=ty) algorithm
      if not BaseHashTable.hasKey(call, HT) then
        index := index + 1;
        HT := BaseHashTable.add((call, index), HT);
        (cse_var, cseIndex) := createReturnExp(ty, cseIndex, inComplex=false);
        cse_var2 := createCrefForTsub(listLength(types), ix, cse_var);
        exarray := ExpandableArray.set(index, CSE_EQUATION(cse_var2, call, {}), exarray);

      else
        id := BaseHashTable.get(call, HT);
        cseEquation := ExpandableArray.get(id, exarray);
        if Expression.isTuple(cseEquation.cse) then
          DAE.TUPLE(expList) := cseEquation.cse;
          e := listGet(expList, ix);
          if isWildCref(e) then
            (cse_var, cseIndex) := createReturnExp(ty, cseIndex, inComplex=false);
            expList := List.set(expList, ix, cse_var);
            cseEquation.cse := DAE.TUPLE(expList);
            exarray := ExpandableArray.update(id, cseEquation, exarray);
          end if;
        else
          Error.addMessage(Error.GENERIC_ELAB_EXPRESSION, {ExpressionDump.dumpExpStr(inExp, 0) + " This should never happen, Error in wrapFunctionCalls_analysis3. Trying to recover."});
        end if;
      end if;
    then true;

    /*
      check arguments of noEvent for functions but ignore noEvent itself.
      ticket #5771
    */
    case DAE.CALL(Absyn.IDENT("noEvent"),{DAE.RELATION(e,_,e2,_,_)}) algorithm
      (_, outTuple) := Expression.traverseExpTopDown(e, wrapFunctionCalls_analysis3, inTuple);
      (_, outTuple) := Expression.traverseExpTopDown(e2, wrapFunctionCalls_analysis3, outTuple);
      cont := false;
      return;
    then true;

    case DAE.CALL(attr=DAE.CALL_ATTR(ty=ty)) algorithm
      if not BaseHashTable.hasKey(inExp, HT) then
        index := index + 1;
        HT := BaseHashTable.add((inExp, index), HT);
        (cse_var, cseIndex) := createReturnExp(ty, cseIndex, inComplex=false);
        exarray := ExpandableArray.set(index, CSE_EQUATION(cse_var, inExp, {}), exarray);
      end if;
    then true;

    else true;
  end match;

  outTuple := (HT, exarray, cseIndex, index, functionTree);
end wrapFunctionCalls_analysis3;

protected function getTheRightPattern
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp1;
  output DAE.Exp outExp2;
algorithm
  (outExp1, outExp2) := match(inExp1, inExp2)
    case (DAE.RCONST(), DAE.CALL()) then (inExp1, inExp2);
    case (DAE.CALL(), DAE.RCONST()) then (inExp2, inExp1);
    case (DAE.TUPLE(), DAE.CALL()) then (inExp1, inExp2);
    case (DAE.CALL(), DAE.TUPLE()) then (inExp2, inExp1);
    case (DAE.CREF(), DAE.CALL()) then (inExp1, inExp2);
    case (DAE.CALL(), DAE.CREF()) then (inExp2, inExp1);
    case (DAE.CREF(), DAE.TSUB()) then (inExp1, inExp2);
    case (DAE.TSUB(), DAE.CREF()) then (inExp2, inExp1);
    else fail();
  end match;
end getTheRightPattern;

protected function isEquationRedundant
  input BackendDAE.Equation inEq;
  output Boolean outB "true if 'x=x', else false";
algorithm
  outB := match(inEq)
    local
      DAE.Exp exp1, exp2;
      list<DAE.Exp> lhs, rhs;

    case BackendDAE.EQUATION(exp=exp1, scalar=exp2)
    then Expression.expEqual(exp1, exp2);

    case BackendDAE.EQUATION(exp=DAE.TUPLE(lhs), scalar=DAE.TUPLE(rhs)) guard (listLength(lhs) == listLength(rhs)) equation
      print("This should never appear\n");
    then isEquationRedundant2(lhs, rhs);

    case BackendDAE.COMPLEX_EQUATION(left=DAE.TUPLE(lhs), right=DAE.TUPLE(rhs)) guard (listLength(lhs) == listLength(rhs))
    then isEquationRedundant2(lhs, rhs);

    case BackendDAE.COMPLEX_EQUATION(left = exp1 as DAE.CREF(ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))), right = exp2 as DAE.CREF(ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))))
    then Expression.expEqual(exp1, exp2);

    else false;
  end match;
end isEquationRedundant;

protected function isEquationRedundant2
  input list<DAE.Exp> lhs;
  input list<DAE.Exp> rhs;
  output Boolean result = true;
protected
  DAE.Exp l, r;
  list<DAE.Exp> ll, rr;
algorithm
  if listEmpty(lhs) then
    return;
  end if;

  l::ll := lhs;
  r::rr := rhs;

  if not isWildCref(l) and not isWildCref(r) then
    //print(ExpressionDump.printExpStr(l) + " ?= " + ExpressionDump.printExpStr(r) + "\n");
    if not Expression.expEqual(l, r) then
      result := false;
      return;
    end if;
  end if;

  result := isEquationRedundant2(ll, rr);
end isEquationRedundant2;

protected function isEquationRedundant_flatten
  "Same as isEquationRedundant but flattens equations of form 'tuple = tuple'
  (e.g. (a,_,b) = (_,c,d) => b=d), if left tuple elements are in globalKnownVarHT and adds them to globalKnownVars"
  input BackendDAE.Equation inEq;
  input output HashSet.HashSet globalKnownVarHT;
  input output BackendDAE.Variables globalKnownVars;
  input output BackendDAE.Variables orderedVars;
  output Boolean outB "true if 'x=x', else false";
  output Boolean isGlobalKnown = false;
algorithm
  outB := match(inEq)
    local
      DAE.Exp exp1, exp2;
      list<DAE.Exp> lhs, rhs;
      Boolean isRedundant;

    case BackendDAE.EQUATION(exp=exp1, scalar=exp2)
      algorithm
        isRedundant := Expression.expEqual(exp1, exp2);
        if not isRedundant then
          isGlobalKnown := allArgsInGlobalKnownVars({exp2}, globalKnownVarHT);
          if isGlobalKnown then
            globalKnownVarHT := addConstantCseVarsToGlobalKnownVarHT(exp1, globalKnownVarHT);
          end if;
        end if;
     then isRedundant;

    case BackendDAE.COMPLEX_EQUATION(left=DAE.TUPLE(lhs), right=DAE.TUPLE(rhs)) guard (listLength(lhs) == listLength(rhs))
      algorithm
        (globalKnownVarHT, globalKnownVars, orderedVars, isRedundant) := isEquationRedundant_flatten2(lhs, rhs, globalKnownVarHT, globalKnownVars, orderedVars);
     then isRedundant;

    case BackendDAE.COMPLEX_EQUATION(left=exp1, right=exp2)
      algorithm
        isRedundant := Expression.expEqual(exp1, exp2);
        if not isRedundant then
          isGlobalKnown := allArgsInGlobalKnownVars({exp2}, globalKnownVarHT);
          if isGlobalKnown then
            globalKnownVarHT := addConstantCseVarsToGlobalKnownVarHT(exp1, globalKnownVarHT);
          end if;
        end if;
     then isRedundant;

    else false;
  end match;
end isEquationRedundant_flatten;

protected function isEquationRedundant_flatten2
  input list<DAE.Exp> lhs;
  input list<DAE.Exp> rhs;
  input output HashSet.HashSet globalKnownVarHT;
  input output BackendDAE.Variables globalKnownVars;
  input output BackendDAE.Variables orderedVars;
  output Boolean result = true;
protected
  DAE.Exp l, r;
  list<DAE.Exp> ll, rr;
  BackendDAE.Var var;
algorithm
  if listEmpty(lhs) then
    return;
  end if;

  l::ll := lhs;
  r::rr := rhs;

  if not isWildCref(l) and not isWildCref(r) then
    //print(ExpressionDump.printExpStr(l) + " ?= " + ExpressionDump.printExpStr(r) + "\n");
    if not Expression.expEqual(l, r) then
      // Left variable in globalKnownVarHT?
      if BaseHashSet.has(Expression.expCref(r), globalKnownVarHT) then
        // create variable with bind exp
        {var} := createVarsForExp(l, {});
        var := BackendVariable.setBindExp(var, SOME(r));

        // Add var to globalKnownVars
        globalKnownVars := BackendVariable.addVar(var, globalKnownVars);

        // Add cref(s) to globalKnownVarHT
        globalKnownVarHT := addConstantCseVarsToGlobalKnownVarHT(l, globalKnownVarHT);

        // Delete var from ordered vars if no cse-cref
        if not isCSECref(var.varName) then
          (_, orderedVars) := BackendVariable.deleteVarIfExistsAndReturn(var.varName, orderedVars);
        end if;
      else
        result := false;
        return;
      end if;
    end if;
  end if;

  (globalKnownVarHT, globalKnownVars, orderedVars, result) := isEquationRedundant_flatten2(ll, rr, globalKnownVarHT, globalKnownVars, orderedVars);
end isEquationRedundant_flatten2;

protected function isCall
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp)
    case DAE.CALL() then true;
    else false;
  end match;
end isCall;

protected function isCallAndCref
  input DAE.Exp inExp;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inExp2)
    case (DAE.CREF(),DAE.CALL()) then true;
    case (DAE.CALL(),DAE.CREF()) then true;
    else false;
  end match;
end isCallAndCref;

protected function isTsubAndCref
  input DAE.Exp inExp;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inExp2)
    case (DAE.CREF(), DAE.TSUB()) then true;
    case (DAE.TSUB(), DAE.CREF()) then true;
    else false;
  end match;
end isTsubAndCref;

protected function isConstAndCall
  input DAE.Exp inExp;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inExp2)
    case (DAE.RCONST(), DAE.CALL()) then true;
    case (DAE.CALL(), DAE.RCONST()) then true;
    else false;
  end match;
end isConstAndCall;

protected function isCallAndTuple
  input DAE.Exp inExp;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inExp2)
    case (DAE.TUPLE(),DAE.CALL()) then true;
    case (DAE.CALL(),DAE.TUPLE()) then true;
    else false;
  end match;
end isCallAndTuple;

protected function isCallAndRecord
  input DAE.Exp inExp;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := match(inExp, inExp2)
    case (DAE.CREF(ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))), DAE.CALL()) then true;
    case (DAE.CALL(), DAE.CREF(ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))) then true;
    else false;
  end match;
end isCallAndRecord;

protected function mergeCSETuples
  input DAE.Exp inCref1;
  input DAE.Exp inCref2;
  output DAE.Exp outCref;
protected
  list<DAE.Exp> expLst1, expLst2, expLst3;
  DAE.Exp e;
algorithm
  // TUPLE = TUPLE
  if Expression.isTuple(inCref1) and Expression.isTuple(inCref2) then
    DAE.TUPLE(expLst1) := inCref1;
    DAE.TUPLE(expLst2) := inCref2;
    expLst1 := mergeCSETuples2(expLst1, expLst2);
    outCref := DAE.TUPLE(expLst1);
  // CREF = TUPLE   kann es diese fälle jetzt noch geben???
  elseif not Expression.isTuple(inCref1) and Expression.isTuple(inCref2) then
    print("mergeCSETuples: This should never appear! (1)\n");
    DAE.TUPLE(expLst2) := inCref2;
    e::expLst3 := expLst2;
    if isWildCref(e) then
      expLst2 := inCref1::expLst3;
    end if;
    outCref := DAE.TUPLE(expLst2);
  // TUPLE = CREF   kann es diese fälle jetzt noch geben???
  elseif Expression.isTuple(inCref1) and not Expression.isTuple(inCref2) then
    print("mergeCSETuples: This should never appear! (2)\n");
    DAE.TUPLE(expLst1) := inCref1;
    e::expLst3 := expLst1;
    if isWildCref(e) then
      expLst1 := inCref2::expLst3;
    end if;
    outCref := DAE.TUPLE(expLst1);
  // CREF = CREF
  else
    outCref := inCref1;
  end if;
end mergeCSETuples;

protected function mergeCSETuples2"(_,b,_,_) x (a,_,c,_) -> (a,b,c,_) || (_,b) x (a,d) -> (a,b)"
  input list<DAE.Exp> inExpLst1;
  input list<DAE.Exp> inExpLst2;
  output list<DAE.Exp> outExpLst = {};
algorithm
  outExpLst := match(inExpLst1, inExpLst2)
    local
      list<DAE.Exp> expLst1, expLst2;
      DAE.Exp e1, e2;

    case ({}, {})
    then outExpLst;

    case (e1::expLst1, e2::expLst2) equation
      outExpLst = mergeCSETuples2(expLst1, expLst2);
      if not isWildCref(e1) and not isWildCref(e2) then
        if isCSEExp(e1) and not isCSEExp(e2) then
          outExpLst = e2::outExpLst;
        else
          outExpLst = e1::outExpLst;
        end if;
      elseif isWildCref(e1) and not isWildCref(e2) then
        outExpLst = e2::outExpLst;
      elseif not isWildCref(e1) and isWildCref(e2) then
        outExpLst = e1::outExpLst;
      elseif isWildCref(e1) and isWildCref(e2) then
        outExpLst = e1::outExpLst;
      end if;
    then outExpLst;
  end match;
end mergeCSETuples2;

protected function isWildCref
  input DAE.Exp inExp;
  output Boolean outB;
algorithm
  outB := match(inExp)
    case DAE.CREF(componentRef=DAE.WILD()) then true;
    else false;
  end match;
end isWildCref;

protected function isSkipCase "outline all skip cases
  This contains amongst others
    * MLS 3.3 rev1, section 3.7.1
      Numeric Functions and Conversion Functions
    * MLS 3.3 rev1, section 3.7.1.1
      Event Triggering Mathematical Functions
    * MLS 3.3 rev1, section 3.7.2
      Derivative and Special Purpose Operators with Function Syntax
    * MLS 3.3 rev1, section 3.7.3
      Event-Related Operators with Function Syntax"
  input DAE.Exp inCall;
  input DAE.FunctionTree functionTree;
  output Boolean outB;
algorithm
  outB := match(inCall)
    local
      Absyn.Path path;
    case DAE.ASUB() then true;
    case DAE.CALL(path=Absyn.IDENT("$_round")) then true;
    case DAE.CALL(path=Absyn.IDENT("$getPart")) then true;
    case DAE.CALL(path=Absyn.IDENT("abs")) then true;
    case DAE.CALL(path=Absyn.IDENT("actualStream")) then true;
    case DAE.CALL(path=Absyn.IDENT("backSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("cardinality")) then true;
    case DAE.CALL(path=Absyn.IDENT("ceil")) then true;
    case DAE.CALL(path=Absyn.IDENT("change")) then true;
    case DAE.CALL(path=Absyn.IDENT("Clock")) then true;
    case DAE.CALL(path=Absyn.IDENT("delay")) then true;
    case DAE.CALL(path=Absyn.IDENT("der")) then true;
    case DAE.CALL(path=Absyn.IDENT("div")) then true;
    case DAE.CALL(path=Absyn.IDENT("edge")) then true;
    case DAE.CALL(path=Absyn.IDENT("firstTick")) then true;
    case DAE.CALL(path=Absyn.IDENT("floor")) then true;
    case DAE.CALL(path=Absyn.IDENT("getInstanceName")) then true;
    case DAE.CALL(path=Absyn.IDENT("hold")) then true;
    case DAE.CALL(path=Absyn.IDENT("homotopy")) then true;
    case DAE.CALL(path=Absyn.IDENT("initial")) then true;
    case DAE.CALL(path=Absyn.IDENT("inStream")) then true;
    case DAE.CALL(path=Absyn.IDENT("integer")) then true;
    case DAE.CALL(path=Absyn.IDENT("Integer")) then true;
    case DAE.CALL(path=Absyn.IDENT("interval")) then true;
    case DAE.CALL(path=Absyn.IDENT("mod")) then true;
    case DAE.CALL(path=Absyn.IDENT("noClock")) then true;
    //case DAE.CALL(path=Absyn.IDENT("noEvent")) then true;
    case DAE.CALL(path=Absyn.IDENT("pre")) then true;
    case DAE.CALL(path=Absyn.IDENT("previous")) then true;
    case DAE.CALL(path=Absyn.IDENT("reinit")) then true;
    case DAE.CALL(path=Absyn.IDENT("rem")) then true;
    case DAE.CALL(path=Absyn.IDENT("sample")) then true;
    case DAE.CALL(path=Absyn.IDENT("semiLinear")) then true;
    case DAE.CALL(path=Absyn.IDENT("shiftSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("sign")) then true;
    case DAE.CALL(path=Absyn.IDENT("smooth")) then true;
    case DAE.CALL(path=Absyn.IDENT("spatialDistribution")) then true;
    case DAE.CALL(path=Absyn.IDENT("sqrt")) then true;
    case DAE.CALL(path=Absyn.IDENT("String")) then true;
    case DAE.CALL(path=Absyn.IDENT("subSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("sum")) then true;
    case DAE.CALL(path=Absyn.IDENT("superSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("terminal")) then true;
    case DAE.CALL() guard(Expression.isImpureCall(inCall) or isCallRecordConstructor(inCall, functionTree)) then true;
    case DAE.CALL() guard(Flags.getConfigBool(Flags.WFC_ADVANCED)) then isSkipCase_advanced(inCall);
    else false;
  end match;
end isSkipCase;

protected function isSkipCase_advanced
"This contains
  * MLS 3.3 rev1, section 3.7.1.2
    Built-in Mathematical Functions and External Built-in Functions "
  input DAE.Exp inCall;
  output Boolean outB;
algorithm
  outB := match(inCall)
    local
      Absyn.Path path;
    case DAE.CALL(path=Absyn.IDENT("acos")) then true;
    case DAE.CALL(path=Absyn.IDENT("asin")) then true;
    case DAE.CALL(path=Absyn.IDENT("atan")) then true;
    case DAE.CALL(path=Absyn.IDENT("atan2")) then true;
    case DAE.CALL(path=Absyn.IDENT("cos")) then true;
    case DAE.CALL(path=Absyn.IDENT("cosh")) then true;
    case DAE.CALL(path=Absyn.IDENT("exp")) then true;
    case DAE.CALL(path=Absyn.IDENT("log")) then true;
    case DAE.CALL(path=Absyn.IDENT("log10")) then true;
    case DAE.CALL(path=Absyn.IDENT("sin")) then true;
    case DAE.CALL(path=Absyn.IDENT("sinh")) then true;
    case DAE.CALL(path=Absyn.IDENT("tan")) then true;
    case DAE.CALL(path=Absyn.IDENT("tanh")) then true;
    else false;
  end match;
end isSkipCase_advanced;

protected function isCallRecordConstructor
//DAEUtil.funcIsRecord(DAEUtil.getNamedFunction(path, functionTree))
  input DAE.Exp inExp;
  input DAE.FunctionTree funcsIn;
  output Boolean outIsCall;
algorithm
  outIsCall := matchcontinue(inExp)
    local
      Absyn.Path path;
      DAE.Function func;

    case DAE.CALL(path=path) equation
      SOME(func) = DAE.AvlTreePathFunction.get(funcsIn,path);
      then listEmpty(DAEUtil.getFunctionElements(func));
    else false;
  end matchcontinue;
end isCallRecordConstructor;

protected function createReturnExp
  input DAE.Type inType;
  input Integer inIndex;
  input String inPrefix = "$cse";
  input Boolean inComplex = true;
  output DAE.Exp outExp;
  output Integer outIndex;
algorithm
  (outExp, outIndex) := match(inType)
    local
      Integer i;
      String str;
      DAE.Exp value;
      DAE.ComponentRef cr;
      DAE.Type ty;
      list<DAE.Type> typeLst;
      list<DAE.Exp> expLst;
      list<DAE.ComponentRef> crefs;
      Absyn.Path path;
      list<DAE.Var> varLst;
      list<String> varNames;

    case DAE.T_REAL() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_REAL_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_INTEGER() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_INTEGER_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_INTEGER_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_STRING() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_STRING_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_STRING_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_BOOL() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_BOOL_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_BOOL_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_CLOCK() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_CLOCK_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_CLOCK_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_TUPLE(types=typeLst) equation
      if inComplex then
        (expLst, i) = List.mapFold(typeLst, function createReturnExp(inPrefix=inPrefix, inComplex=inComplex), inIndex);
        value = DAE.TUPLE(expLst);
      else
        ty::_ = typeLst;
        (value, i) = createReturnExp(ty, inIndex, inPrefix, false);
      end if;
    then (value, i);

    // Expanding
    case DAE.T_ARRAY() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, inType, {});
      // crefs = ComponentReference.expandCref(cr, false);
      // expLst = List.map(crefs, Expression.crefExp);
      // value = DAE.ARRAY(inType, true, expLst);
      value = DAE.CREF(cr, inType);
    then (value, inIndex + 1);

    // record types
    case DAE.T_COMPLEX( complexClassType=ClassInf.RECORD(_)) equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, inType, {});       //inType?
      // crefs = ComponentReference.expandCref(cr, true);
      // expLst = List.map(crefs, Expression.crefExp);
      // varNames = List.map(varLst, Expression.varName);
      // value = DAE.RECORD(path, expLst, varNames, inType);
      // print("   DAE.T_COMPLEX \n");
      value = DAE.CREF(cr, inType);
    then (value, inIndex + 1);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - createReturnExp failed for " + Types.printTypeStr(inType) + "\n");
      end if;
    then fail();
  end match;
end createReturnExp;

protected function createVarsForExp_onlyCSECrefs
"Same as createVarsForExp but only creates a variable if the crefs in inExp are $cse-crefs"
  input DAE.Exp inExp;
  input list<BackendDAE.Var> inAccumVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  (outVarLst) := match (inExp)
    local
      DAE.ComponentRef cr, cr_;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expLst;
      BackendDAE.Var var;
      DAE.Type ty;
      DAE.InstDims arrayDim;
/*
    case DAE.CREF(componentRef=cr) guard(not Expression.isArrayType(Expression.typeof(inExp))
                                         and not Expression.isRecordType(Expression.typeof(inExp))) equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;
*/
    case DAE.CREF(componentRef=DAE.WILD()) then inAccumVarLst;

    case DAE.CREF(componentRef=cr, ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))) guard isCSECref(cr) algorithm
      // use the correct type when creating var. The cref might have subs.
      crefs := ComponentReference.expandCref(cr, true /*the way it is now we won't get records here. but if we do somehow expand them*/);

      /* Create SimVars from the list of expanded crefs.*/
      /* Mark the first element as an arrayCref i.e. we have 'SOME(arraycref)' since this is how the C template
         detects first elements of arrays to generate VARNAME_indexed(..) macros for accessing the array
         with variable indexes.*/
      outVarLst := inAccumVarLst;
      for cr_ in crefs loop
        arrayDim := ComponentReference.crefDims(cr_);
        outVarLst := BackendVariable.createCSEArrayVar(cr_, ComponentReference.crefTypeFull(cr_), arrayDim)::outVarLst;
      end for;
    then outVarLst;

    case DAE.CREF(componentRef=cr) guard(isCSECref(cr) and Expression.isArrayType(Expression.typeof(inExp))) algorithm
      // use the correct type when creating var. The cref might have subs.
      crefs := ComponentReference.expandCref(cr, true);

      outVarLst := inAccumVarLst;
      ty := DAEUtil.expTypeElementType(Expression.typeof(inExp));
      for cr_ in crefs loop
        arrayDim := ComponentReference.crefDims(cr_);
        //expLst := DAE.CREF(cr_, ComponentReference.crefType(cr_))::expLst;
        outVarLst := BackendVariable.createCSEArrayVar(cr_, ty, arrayDim)::outVarLst;
      end for;
      //expLst = list(DAE.CREF(cr_, ComponentReference.crefType(cr_)) for cr_ in crefs);
    then outVarLst;

    case DAE.CREF(componentRef=cr) guard isCSECref(cr) equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;

    case DAE.TUPLE(expLst) equation
      outVarLst = List.fold(expLst, createVarsForExp_onlyCSECrefs, inAccumVarLst);
    then outVarLst;

    case DAE.ARRAY(array=expLst) equation
      //print("This should never appear\n");
      outVarLst = List.fold(expLst, createVarsForExp_onlyCSECrefs, inAccumVarLst);
    then outVarLst;

    case DAE.RECORD(exps=expLst) equation
      print("This should never appear\n");
      outVarLst = List.fold(expLst, createVarsForExp_onlyCSECrefs, inAccumVarLst);
    then outVarLst;

    // add no variable in all other cases
    else inAccumVarLst;
  end match;
end createVarsForExp_onlyCSECrefs;

protected function createVarsForExp
"Creates a variable list for crefs in inExp, e.g. inExp = (a, b, _, d) -> outVarLst = {a,b,d}"
  input DAE.Exp inExp;
  input list<BackendDAE.Var> inAccumVarLst = {};
  output list<BackendDAE.Var> outVarLst;
algorithm
  (outVarLst) := match (inExp)
    local
      DAE.ComponentRef cr, cr_;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expLst;
      BackendDAE.Var var;
      DAE.Type ty;
      DAE.InstDims arrayDim;
/*
    case DAE.CREF(componentRef=cr) guard(not Expression.isArrayType(Expression.typeof(inExp))
                                         and not Expression.isRecordType(Expression.typeof(inExp))) equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;
*/
    case DAE.CREF(componentRef=DAE.WILD()) then inAccumVarLst;

    case DAE.CREF(componentRef=cr, ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))) algorithm
      // use the correct type when creating var. The cref might have subs.
      crefs := ComponentReference.expandCref(cr, true /*the way it is now we won't get records here. but if we do somehow expand them*/);

      /* Create SimVars from the list of expanded crefs.*/
      /* Mark the first element as an arrayCref i.e. we have 'SOME(arraycref)' since this is how the C template
         detects first elements of arrays to generate VARNAME_indexed(..) macros for accessing the array
         with variable indexes.*/
      outVarLst := inAccumVarLst;
      for cr_ in crefs loop
        arrayDim := ComponentReference.crefDims(cr_);
        outVarLst := BackendVariable.createCSEArrayVar(cr_, ComponentReference.crefTypeFull(cr_), arrayDim)::outVarLst;
      end for;
    then outVarLst;

    case DAE.CREF(componentRef=cr) guard(Expression.isArrayType(Expression.typeof(inExp))) algorithm
      // use the correct type when creating var. The cref might have subs.
      crefs := ComponentReference.expandCref(cr, true);

      outVarLst := inAccumVarLst;
      ty := DAEUtil.expTypeElementType(Expression.typeof(inExp));
      for cr_ in crefs loop
        arrayDim := ComponentReference.crefDims(cr_);
        //expLst := DAE.CREF(cr_, ComponentReference.crefType(cr_))::expLst;
        outVarLst := BackendVariable.createCSEArrayVar(cr_, ty, arrayDim)::outVarLst;
      end for;
      //expLst = list(DAE.CREF(cr_, ComponentReference.crefType(cr_)) for cr_ in crefs);
    then outVarLst;

    case DAE.CREF(componentRef=cr) equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;

    case DAE.TUPLE(expLst) equation
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    case DAE.ARRAY(array=expLst) equation
      //print("This should never appear\n");
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    case DAE.RECORD(exps=expLst) equation
      print("This should never appear\n");
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    // add no variable in all other cases
    else inAccumVarLst;
  end match;
end createVarsForExp;

public function isCSECref
"Returns true if the cref is prefixed with '$cse'"
  input DAE.ComponentRef cr;
  output Boolean b;
protected
  String s;
algorithm
  b := matchcontinue(cr)
    case(DAE.CREF_IDENT(ident=s))
     then (substring(s, 1, 4) == "$cse");
    case(DAE.CREF_QUAL(ident=s))
     then (substring(s, 1, 4) == "$cse");
    else false;
  end matchcontinue;
end isCSECref;

public function isCSEExp
"Returns true if the exp is prefixed with '$cse'"
  input DAE.Exp inExp;
  output Boolean b;
protected
  DAE.ComponentRef cr;
  String s;
algorithm
  try
    cr := Expression.expCref(inExp);
    DAE.CREF_IDENT(ident=s) := cr;
    b := substring(s, 1, 4) == "$cse";
  else
    b := false;
  end try;
end isCSEExp;

public function cseBinary "authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)
  This module eliminates common subexpressions in an acausal environment.
  NOTE: This is currently just an experimental prototype to demonstrate interesting effects."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystemAndFold(inDAE, CSE1, 1);
end cseBinary;

protected function CSE1
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input Integer inIndex;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared = inShared;
  output Integer outIndex;
algorithm
  (outSystem, outIndex) := matchcontinue(inSystem)
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EqSystem syst;
      list<BackendDAE.Var> varList;
      list<BackendDAE.Equation> eqList;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2, HT3;
      Integer index = inIndex;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)) equation
    //if Flags.isSet(Flags.DUMP_CSE) then
    //  BackendDump.dumpVariables(orderedVars, "########### Updated Variable List ###########");
    //  BackendDump.dumpEquationArray(orderedEqs, "########### Updated Equation List ###########");
    //end if;
        HT = HashTableExpToExp.emptyHashTableSized(49999);  //2053    4013    25343   536870879
        HT2 = HashTableExpToIndex.emptyHashTableSized(49999);
        HT3 = HashTableExpToIndex.emptyHashTableSized(49999);
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("collect statistics\n========================================\n");
        end if;
        (HT, HT2, index) = BackendEquation.traverseEquationArray(orderedEqs, createStatistics, (HT, HT2, index));
    //BaseHashTable.dumpHashTable(HT);
    //BaseHashTable.dumpHashTable(HT2);
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("\nstart substitution\n========================================\n");
        end if;
        (orderedEqs, (HT, HT2, _, eqList, varList)) = BackendEquation.traverseEquationArray_WithUpdate (orderedEqs, substituteCSE, (HT, HT2, HT3, {}, {}));
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("\n");
        end if;
      syst.orderedEqs = BackendEquation.addList(eqList, orderedEqs);
      syst.orderedVars = BackendVariable.addVars(varList, orderedVars);
      if Flags.isSet(Flags.DUMP_CSE) then
        BackendDump.dumpVariables(syst.orderedVars, "########### Updated Variable List ###########");
        BackendDump.dumpEquationArray(syst.orderedEqs, "########### Updated Equation List ###########");
      end if;
    then (BackendDAEUtil.clearEqSyst(syst), index);

    else (inSystem, inIndex);
  end matchcontinue;
end CSE1;

protected function substituteCSE
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      BackendDAE.Equation eq;
      tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>> tpl;

    case BackendDAE.ALGORITHM() then (inEq, inTuple);
    case BackendDAE.WHEN_EQUATION() then (inEq, inTuple);  // not necessary
    //case BackendDAE.COMPLEX_EQUATION() then (inEq, inTuple);
    //case BackendDAE.ARRAY_EQUATION() then (inEq, inTuple);
    case BackendDAE.IF_EQUATION() then (inEq, inTuple);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("traverse " + BackendDump.equationString(inEq) + "\n");
      end if;
      (eq, (tpl, _)) = BackendEquation.traverseExpsOfEquation(inEq, substituteCSE1, (inTuple, BackendEquation.equationSource(inEq)));
    then (eq, tpl);
  end match;
end substituteCSE;

protected function substituteCSE1
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, substituteCSE_main, inTuple);
end substituteCSE1;

protected function substituteCSE_main
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> outTuple;
algorithm
  (outExp, cont, outTuple) := matchcontinue(inExp, inTuple)
    local
      DAE.Exp exp1, value;
      Absyn.Path path;
      DAE.CallAttributes attr;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2;
      HashTableExpToIndex.HashTable HT3;
      list<BackendDAE.Equation> eqLst, eqLst1;
      list<BackendDAE.Var> varLst, varLst1;
      Integer counter;
      BackendDAE.Equation eq;
      DAE.Exp expReplaced;
      list<DAE.Exp> expLst;
      DAE.ElementSource source;

    case (DAE.BINARY(), ((HT, HT2, HT3, eqLst, varLst), source)) equation
      value = BaseHashTable.get(inExp, HT);
      counter = BaseHashTable.get(value, HT2);
      true = intGt(counter, 1);

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - substitute cse binary: " + ExpressionDump.printExpStr(inExp) + " (counter: " + intString(counter) + ", id: " + ExpressionDump.printExpStr(value) + ")\n");
      end if;

      if not BaseHashTable.hasKey(value, HT3) then
        HT3 = BaseHashTable.add((value, 1), HT3);
        varLst = createVarsForExp_onlyCSECrefs(value, varLst);
        eq = BackendEquation.generateEquation(value, inExp, source /* TODO: Add CSE? */, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
        eqLst = eq::eqLst;
      end if;
    then (value, true, ((HT, HT2, HT3, eqLst, varLst), source));

    else (inExp, true, inTuple);
  end matchcontinue;
end substituteCSE_main;

protected function createStatistics
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      BackendDAE.Equation eq;
      tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> tpl;

    case BackendDAE.ALGORITHM() then (inEq, inTuple);
    case BackendDAE.WHEN_EQUATION() then (inEq, inTuple);  // not necessary
    //case BackendDAE.COMPLEX_EQUATION() then (inEq, inTuple);
    //case BackendDAE.ARRAY_EQUATION() then (inEq, inTuple);
    case BackendDAE.IF_EQUATION() then (inEq, inTuple);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("traverse " + BackendDump.equationString(inEq) + "\n");
      end if;
      (eq, tpl) = BackendEquation.traverseExpsOfEquation(inEq, createStatistics1, inTuple);
    then (eq, tpl);
  end match;
end createStatistics;

protected function createStatistics1
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, createStatistics_main, inTuple);
end createStatistics1;

protected function createStatistics_main
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> outTuple;
algorithm
  (outExp, cont, outTuple) := matchcontinue(inExp, inTuple)
    local
      DAE.Exp exp1, exp2, value;
      list<DAE.Exp> expLst;
      DAE.Operator op;
      Absyn.Path path;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2;
      list<BackendDAE.Equation> eqList;
      list<BackendDAE.Var> varList;
      Integer i, counter;
      String str;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      BackendDAE.Equation eq;
      DAE.Type tp;

    case (DAE.BINARY(exp1, op, exp2), (HT, HT2, i)) equation
      if checkOp(op) then
        if BaseHashTable.hasKey(inExp, HT) then
          value = BaseHashTable.get(inExp, HT);
          counter = BaseHashTable.get(value, HT2) + 1;
          BaseHashTable.update((value, counter), HT2);

          if isCommutative(op) then
            value = BaseHashTable.get(DAE.BINARY(exp2, op, exp1), HT);
            BaseHashTable.update((value, counter), HT2);
          end if;
        else
          (value, i) = createReturnExp(Expression.typeof(inExp), i, "$cseb");
          counter = 1;
          HT = BaseHashTable.add((inExp, value), HT);
          HT2 = BaseHashTable.add((value, counter), HT2);
          if isCommutative(op) then
            HT = BaseHashTable.add((DAE.BINARY(exp2, op, exp1), value), HT);
          end if;
        end if;

        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("  - cse binary expression: " + ExpressionDump.printExpStr(inExp) + " (counter: " + intString(counter) + ", id: " + ExpressionDump.printExpStr(value) + ")\n");
        end if;
      end if;
    then (inExp, true, (HT, HT2, i));

    // skip some kinds of expressions
    case (DAE.IFEXP(), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("der")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("smooth")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("noEvent")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("semiLinear")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("homotopy")), _)
    then (inExp, false, inTuple);

    else (inExp, true, inTuple);
  end matchcontinue;
end createStatistics_main;

protected function isCommutative
  input DAE.Operator inOp;
  output Boolean outCommutative;
algorithm
  outCommutative := match(inOp)
    case DAE.MUL() then true;
    case DAE.ADD() then true;
    else false;
  end match;
end isCommutative;

protected function checkOp
  input DAE.Operator inOp;
  output Boolean outB;
algorithm
  outB := match(inOp)
    case DAE.ADD() then true;
    case DAE.SUB() then true;
    case DAE.MUL() then true;
    case DAE.DIV() then true;
    case DAE.POW() then true;
    case DAE.UMINUS() then true;
    else false;
  end match;
end checkOp;

// =============================================================================
// Common Sub Expressions
//
// =============================================================================

protected
uniontype CommonSubExp
  record ASSIGNMENT_CSE
    //a = exp1;
    //b = exp1;
    //--> a = b;
    list<Integer> eqIdcs;
    list<Integer> sharedVars;
    list<Integer> aliasVars;
  end ASSIGNMENT_CSE;

  record SHORTCUT_CSE
    //a = exp1;
    //a = exp2;
    //--> exp1 = exp2;
    list<Integer> eqIdcs;
    Integer sharedVar;
  end SHORTCUT_CSE;
end CommonSubExp;

public function commonSubExpressionReplacement"detects common sub expressions and introduces alias variables for them.
REMARK: this is just a basic prototype. feel free to extend.
author:Waurich TUD 2014-11"
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
algorithm
  //print("SYSTEM IN\n");
  //BackendDump.printBackendDAE(daeIn);
  daeOut := BackendDAEUtil.mapEqSystem(daeIn, commonSubExpression);
  //print("SYSTEM OUT\n");
  //BackendDump.printBackendDAE(daeOut);
end commonSubExpressionReplacement;

protected function commonSubExpression
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
algorithm
  (sysOut, sharedOut) := matchcontinue(sysIn, sharedIn)
    local
    DAE.FunctionTree functionTree;
    BackendDAE.Variables vars;
    BackendDAE.EquationArray eqs;
    BackendDAE.Shared shared;
    BackendDAE.EqSystem syst;
    BackendDAE.AdjacencyMatrix m, mT;
    list<Integer> eqIdcs;
    list<CommonSubExp> cseLst;

    BackendDAE.Equation eqTest;
    BackendDAE.Var var1,var2;
    list<BackendDAE.Equation> eqLst;
    Boolean isInitial;

  case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs), BackendDAE.SHARED(functionTree=functionTree))
    algorithm
      isInitial := BackendDAEUtil.isInitializationDAE(sharedIn);
      (_, m, mT) := BackendDAEUtil.getAdjacencyMatrix(sysIn, BackendDAE.ABSOLUTE(), SOME(functionTree), isInitial);
          //print("start this eqSystem\n");
          //BackendDump.dumpEqSystem(sysIn, "eqSystem input");
          //BackendDump.dumpAdjacencyMatrix(m);
          //BackendDump.dumpAdjacencyMatrixT(mT);
      cseLst := commonSubExpressionFind(m, mT, vars, eqs, isInitial);
          //if not listEmpty(cseLst) then print("update "+stringDelimitList(List.map(cseLst, printCSE), "\n")+"\n");end if;
      syst := commonSubExpressionUpdate(cseLst, m, mT, sysIn);
      GC.free(m);
      GC.free(mT);
      syst.orderedEqs := eqs;
          //print("done this eqSystem\n");
          //BackendDump.dumpEqSystem(syst, "eqSystem");
      then (syst, sharedIn);
    else (sysIn, sharedIn);
  end matchcontinue;
end commonSubExpression;

protected function commonSubExpressionFind
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrix mTIn;
  input BackendDAE.Variables varsIn;
  input BackendDAE.EquationArray eqsIn;
  input Boolean isInitial;
  output list<CommonSubExp> cseOut;
protected
  Integer numVars;
  list<Integer> eqIdcs, varIdcs,lengthLst, range;
  list<list<Integer>> arrLst;
  list<list<Integer>> partitions;
  BackendDAE.Variables vars, linPathVars;
  BackendDAE.EquationArray eqs;
  BackendDAE.EqSystem eqSys;
  BackendDAE.AdjacencyMatrix m, mT;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
  list<CommonSubExp> cseLst2, cseLst3, shortenPathsCSE;
  list<tuple<Boolean, String>> varAtts, eqAtts;
  AvlSetInt.Tree varIdcsSet;
algorithm
  try
    range := List.intRange(arrayLength(mIn));
    arrLst := arrayList(mIn);
    lengthLst := List.map(arrLst, listLength);

    // check for CSE of length 1 (all eqs with 2 variables)
      //print("CHECK FOR CSE 2\n");
    (_, eqIdcs) := List.filter1OnTrueSync(lengthLst, intEq, 2, range);
    (eqLst, eqIdcs) := List.filterOnTrueSync(BackendEquation.getList(eqIdcs, eqsIn),BackendEquation.isNotAlgorithm,eqIdcs); // no algorithms
    eqs := BackendEquation.listEquation(eqLst);
    varIdcs := List.unique(List.flatten(List.map1(eqIdcs, Array.getIndexFirst, mIn)));
    varLst := List.map1(varIdcs, BackendVariable.getVarAtIndexFirst, varsIn);
    //(varLst,varIdcs) := List.filterOnTrueSync(varLst,BackendVariable.isVarNonDiscrete,varIdcs);// no discrete vars
    vars := BackendVariable.listVar1(varLst);
    eqSys := BackendDAEUtil.createEqSystem(vars, eqs);
    (_, m, mT) := BackendDAEUtil.getAdjacencyMatrix(eqSys, BackendDAE.ABSOLUTE(), NONE(), isInitial);
        //BackendDump.dumpEqSystem(eqSys, "reduced system for CSE 2");
        //BackendDump.dumpAdjacencyMatrix(m);
        //BackendDump.dumpAdjacencyMatrix(mT);
        //varAtts := List.threadMap(List.fill(false, listLength(varIdcs)), List.fill("", listLength(varIdcs)), Util.makeTuple);
        //eqAtts := List.threadMap(List.fill(false, listLength(eqIdcs)), List.fill("", listLength(eqIdcs)), Util.makeTuple);
        //BackendDump.dumpBipartiteGraphStrongComponent2(vars, eqs, m, varAtts, eqAtts, "CSE2_"+intString(arrayLength(mIn)));
    partitions := arrayList(ResolveLoops.partitionBipartiteGraph(m, mT));
    partitions := List.filterOnFalse(partitions,listEmpty);
        //print("the partitions for system  : \n"+stringDelimitList(List.map(partitions, HpcOmTaskGraph.intLstString), "\n")+"\n");
    cseLst2 := List.fold(partitions, function getCSE2(m=m, mT=mT, vars=vars, eqs=eqs, eqMap=eqIdcs, varMap=varIdcs), {});

    shortenPathsCSE := shortenPaths(partitions, m, mT, vars, eqs, listArray(eqIdcs), listArray(varIdcs), {}, isInitial);

    // check for CSE of length 2
      //print("CHECK FOR CSE 3\n");
    (_, eqIdcs) := List.filter1OnTrueSync(lengthLst, intEq, 3, range);
    (eqLst, eqIdcs) := List.filterOnTrueSync(BackendEquation.getList(eqIdcs, eqsIn),BackendEquation.isNotAlgorithm,eqIdcs); // no algorithms
    eqs := BackendEquation.listEquation(eqLst);
    varIdcsSet := AvlSetInt.EMPTY();
    for eq in eqIdcs loop
      varIdcsSet := AvlSetInt.addList(varIdcsSet, arrayGet(mIn, eq));
    end for;
    varIdcs := AvlSetInt.listKeysReverse(varIdcsSet);
    varLst := List.map1(varIdcs, BackendVariable.getVarAtIndexFirst, varsIn);
    vars := BackendVariable.listVar1(varLst);
    eqSys := BackendDAEUtil.createEqSystem(vars, eqs);
    (_, m, mT) := BackendDAEUtil.getAdjacencyMatrix(eqSys, BackendDAE.ABSOLUTE(), NONE(), isInitial);
        //BackendDump.dumpEqSystem(eqSys, "reduced system for CSE 3");
        //BackendDump.dumpAdjacencyMatrix(m);
        //BackendDump.dumpAdjacencyMatrix(mT);
        //varAtts := List.threadMap(List.fill(false, listLength(varIdcs)), List.fill("", listLength(varIdcs)), Util.makeTuple);
        //eqAtts := List.threadMap(List.fill(false, listLength(eqIdcs)), List.fill("", listLength(eqIdcs)), Util.makeTuple);
        //BackendDump.dumpBipartiteGraphStrongComponent2(vars, eqs, m, varAtts, eqAtts, "CSE3_"+intString(arrayLength(mIn)));
    partitions := arrayList(ResolveLoops.partitionBipartiteGraph(m, mT));
        //print("the partitions for system  : \n"+stringDelimitList(List.map(partitions, HpcOmTaskGraph.intLstString), "\n")+"\n");
    cseLst3 := List.fold(partitions, function getCSE3(m=m, mT=mT, vars=vars, eqs=eqs, eqMap=eqIdcs, varMap=varIdcs), {});
    cseOut := listAppend(cseLst2, listAppend(cseLst3,shortenPathsCSE));
        //print("the cses : \n"+stringDelimitList(List.map(cseOut, printCSE), "\n")+"\n");
  else
    cseOut := {};
  end try;
end commonSubExpressionFind;


protected function shortenPaths"looks for a path in the bipartite graph where each variable and equation has only 2 adjacent node.
Then check if variables which are shared by 2 equations can be combined somehow to rearrange edges and create a shortcut of this path.
author:Waurich TUD 2016-05"
  input list<list<Integer>> allPartitions;
  input BackendDAE.AdjacencyMatrix mIn;
  input BackendDAE.AdjacencyMatrix mTIn;
  input BackendDAE.Variables allVars;
  input BackendDAE.EquationArray allEqs;
  input array<Integer> eqMap;
  input array<Integer> varMap;
  input list<CommonSubExp> cseIn;
  input Boolean isInitial;
  output list<CommonSubExp> cseOut;
protected
  BackendDAE.AdjacencyMatrix m, mT;
  BackendDAE.AdjacencyMatrixEnhanced me,meT;
  BackendDAE.EqSystem eqSys;
  BackendDAE.Variables vars, pathVars;
  list<BackendDAE.Var> varLst;
  list<BackendDAE.Equation> eqLst, eqLst_all;
  BackendDAE.EquationArray eqs;
  list<tuple<Boolean, String>> varAtts, eqAtts;
  Integer numVars, varIdx;
  array<Integer> pathVarIdxMap;
  list<Integer> partition, varIdcs, adjEqs, pathVarIdcs;
  list<CommonSubExp> cses;
algorithm
  try
    // getall vars with only 2 adjacent equations
    numVars := BackendVariable.varsSize(allVars);
    (_, pathVarIdcs) := List.filter1OnTrueSync(List.map(arrayList(mTIn), listLength), intEq, 2, List.intRange(numVars));
    pathVars := BackendVariable.listVar1(List.map1(pathVarIdcs, BackendVariable.getVarAtIndexFirst, allVars));
    pathVarIdxMap := listArray(List.map1(pathVarIdcs,Array.getIndexFirst,varMap));
    cses := cseIn;
    eqLst_all := BackendEquation.equationList(allEqs);
    if BackendVariable.varsSize(pathVars) > 0 then
      for partition in allPartitions loop
        //print("partition "+stringDelimitList(List.map(partition, intString), ", ")+"\n");
        //print("pathVarIdxMap "+stringDelimitList(List.map(List.map1(pathVarIdcs,Array.getIndexFirst,varMap), intString), ", ")+"\n");

        //get only the partition equations
        eqLst := List.map1(partition,List.getIndexFirst,eqLst_all);
        eqs := BackendEquation.listEquation(eqLst);

        eqSys := BackendDAEUtil.createEqSystem(pathVars, eqs);
        (_, m, mT) := BackendDAEUtil.getAdjacencyMatrix(eqSys, BackendDAE.SOLVABLE(), NONE(), isInitial);

          //BackendDump.dumpAdjacencyMatrix(m);
          //BackendDump.dumpAdjacencyMatrixT(mT);
          //varAtts := List.threadMap(List.fill(false, arrayLength(mT)), List.fill("", arrayLength(mT)), Util.makeTuple);
          //eqAtts := List.threadMap(List.fill(false, arrayLength(m)), List.fill("", arrayLength(m)), Util.makeTuple);
          //BackendDump.dumpBipartiteGraphStrongComponent2(pathVars, eqs, m, varAtts, eqAtts, "shortenPaths"+stringDelimitList(List.map(partition,intString),"_"));

       for idx in 1:arrayLength(mT) loop
         adjEqs := arrayGet(mT,idx);

         if listLength(adjEqs)==2 then
         //print("varIdx1 "+intString(varIdx)+"\n");
         //print("adjEqs "+stringDelimitList(List.map(adjEqs,intString),",")+"\n");
           adjEqs := list(arrayGet(eqMap,listGet(partition,eq)) for eq in adjEqs);
           varIdx := arrayGet(pathVarIdxMap,idx);
           cses := SHORTCUT_CSE(adjEqs,varIdx)::cses;
         end if;
       end for; //end the variables
       GC.free(m);
       GC.free(mT);
     end for;  //end all partitions
      //print("the SHORTPATH cses : \n"+stringDelimitList(List.map(cses, printCSE), "\n")+"\n");
    end if;
    cseOut := cses;
  else
    cseOut := cseIn;
  end try;
end shortenPaths;

protected function getCSE2"traverses the partitions and checks for CSE2 i.e a=b+const. ; c = b+const. --> a=c
author:Waurich TUD 2014-11"
  input list<Integer> partition;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrix mT;
  input BackendDAE.Variables vars;  // for partition
  input BackendDAE.EquationArray eqs;  // for partition
  input list<Integer> eqMap;
  input list<Integer> varMap;
  input list<CommonSubExp> cseIn;
  output list<CommonSubExp> cseOut;
algorithm
  cseOut := matchcontinue(partition, m, mT, vars, eqs, eqMap, varMap, cseIn)
  local
    Integer sharedVarIdx, eqIdx1, eqIdx2, varIdx1, varIdx2;
    list<Integer> varIdcs1, varIdcs2, sharedVarIdcs, eqIdcs;
    BackendDAE.Equation eq1, eq2;
    BackendDAE.Var sharedVar, var1, var2;
    DAE.Exp varExp1, varExp2, lhs, rhs1, rhs2;
  case({eqIdx1, eqIdx2}, _, _, _, _, _, _, _)
    equation
        //print("partition "+stringDelimitList(List.map(partition, intString), ", ")+"\n");
      // the partition consists of 2 equations
      varIdcs1 = arrayGet(m, eqIdx1);
      varIdcs2 = arrayGet(m, eqIdx2);
      (sharedVarIdcs, varIdcs1, varIdcs2) = List.intersection1OnTrue(varIdcs1, varIdcs2, intEq);
        //print("sharedVarIdcs "+stringDelimitList(List.map(sharedVarIdcs, intString), ", ")+"\n");
      {varIdx1} = varIdcs1;
      {varIdx2} = varIdcs2;
      {sharedVarIdx} = sharedVarIdcs;
      {eq1, eq2} = BackendEquation.getList(partition, eqs);
      _ = BackendVariable.getVarAt(vars, sharedVarIdx);
      var1 = BackendVariable.getVarAt(vars, varIdx1);
      var2 = BackendVariable.getVarAt(vars, varIdx2);

      // compare the actual equations
      varExp1 = BackendVariable.varExp(var1);
      varExp2 = BackendVariable.varExp(var2);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs1) = eq1;
      (rhs1, _) = ExpressionSolve.solve(lhs, rhs1, varExp1);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs2) = eq2;
      (rhs2, _) = ExpressionSolve.solve(lhs, rhs2, varExp2);
      true = Expression.expEqual(rhs1, rhs2);
         //print("rhs1 " +ExpressionDump.printExpStr(rhs1)+"\n");
         //print("rhs2 " +ExpressionDump.printExpStr(rhs2)+"\n");
         //print("is equal\n");
      // build CSE
      sharedVarIdcs = List.map1(sharedVarIdcs, List.getIndexFirst, varMap);
      varIdcs2 = listAppend(varIdcs1, varIdcs2);
      varIdcs2 = List.map1(varIdcs2, List.getIndexFirst, varMap);
      eqIdcs = List.map1(partition, List.getIndexFirst, eqMap);
    then ASSIGNMENT_CSE(eqIdcs, sharedVarIdcs, varIdcs2)::cseIn;
  else cseIn;
  end matchcontinue;
end getCSE2;

protected function getCSE3"traverses the partitions and checks for CSE3 i.e a=b+c+const. ; d = b+c+const. --> a=d
author:Waurich TUD 2014-11"
  input list<Integer> partition;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrix mT;
  input BackendDAE.Variables vars;  // for partition
  input BackendDAE.EquationArray eqs;  // for partition
  input list<Integer> eqMap;
  input list<Integer> varMap;
  input list<CommonSubExp> cseIn;
  output list<CommonSubExp> cseOut;
algorithm
  cseOut := matchcontinue(partition, m, mT, vars, eqs, eqMap, varMap, cseIn)
  local
    Integer sharedVarIdx, eqIdx1, eqIdx2, varIdx1, varIdx2;
    list<Integer> varIdcs1, varIdcs2, sharedVarIdcs, eqIdcs;
    list<Integer> loop1;
    list<list<Integer>> loops;
    BackendDAE.Equation eq1, eq2;
    BackendDAE.Var var1, var2;
    DAE.Exp varExp1, varExp2, lhs, rhs1, rhs2;
    array<Integer> varMapArr, eqMapArr;
    list<CommonSubExp> cseLst;
  case(_, _, _, _, _, _, _, _)
    algorithm
      //print("partition "+stringDelimitList(List.map(partition, intString), ", ")+"\n");
      // partition has only one loop
      (loops, _, _) := ResolveLoops.resolveLoops_findLoops({partition}, m, mT, findExactlyOneLoop=false);
      cseLst := cseIn;
      for loop1 in loops loop
          //print("loop1 "+stringDelimitList(List.map(loop1, intString), ", ")+"\n");
          {eqIdx1, eqIdx2} := loop1;
          varIdcs1 := arrayGet(m, eqIdx1);
          varIdcs2 := arrayGet(m, eqIdx2);
          (sharedVarIdcs, varIdcs1, varIdcs2) := List.intersection1OnTrue(varIdcs1, varIdcs2, intEq);
            //print("sharedVarIdcs "+stringDelimitList(List.map(sharedVarIdcs, intString), ", ")+"\n");
            //print("varIdcs1 "+stringDelimitList(List.map(varIdcs1, intString), ", ")+"\n");
            //print("varIdcs2 "+stringDelimitList(List.map(varIdcs2, intString), ", ")+"\n");
          {varIdx1} := varIdcs1;
          {varIdx2} := varIdcs2;
          {eq1, eq2} := BackendEquation.getList(loop1, eqs);
          var1 := BackendVariable.getVarAt(vars, varIdx1);
          var2 := BackendVariable.getVarAt(vars, varIdx2);

          // compare the actual equations
          varExp1 := BackendVariable.varExp(var1);
          varExp2 := BackendVariable.varExp(var2);
          BackendDAE.EQUATION(exp=lhs, scalar=rhs1) := eq1;
          (rhs1, _) := ExpressionSolve.solve(lhs, rhs1, varExp1);
          BackendDAE.EQUATION(exp=lhs, scalar=rhs2) := eq2;
          (rhs2, _) := ExpressionSolve.solve(lhs, rhs2, varExp2);
          if Expression.expEqual(rhs1, rhs2) then
               //print("rhs1 " +ExpressionDump.printExpStr(rhs1)+"\n");
               //print("rhs2 " +ExpressionDump.printExpStr(rhs2)+"\n");
               //print("is equal\n");
            // build CSE
            eqMapArr := listArray(eqMap);
            varMapArr := listArray(varMap);
            sharedVarIdcs := list(arrayGet(varMapArr, i) for i in sharedVarIdcs);
            varIdcs2 := listAppend(varIdcs1, varIdcs2);
            varIdcs2 := list(arrayGet(varMapArr, i) for i in varIdcs2);
            eqIdcs := list(arrayGet(eqMapArr,i) for i in loop1);
            GC.free(eqMapArr);
            GC.free(varMapArr);
            cseLst := ASSIGNMENT_CSE(eqIdcs, sharedVarIdcs, varIdcs2)::cseLst;
          end if;
      end for;
    then cseLst;
  else cseIn;
  end matchcontinue;
end getCSE3;


protected function commonSubExpressionUpdate"updates the eqSystem.
remark: the vars are not explicitly declared as alias and an equation is not removed since there are cases where alias-replacements are invalid like :
x[1]=x[2];
for i in 1:2 loop x[i] =i*time; end for;
Thats why one original equation is replaced by an alias equation.
author:Waurich TUD 2014-11"
  input list<CommonSubExp> tplsIn;
  input BackendDAE.AdjacencyMatrix m;
  input BackendDAE.AdjacencyMatrix mT;
  input BackendDAE.EqSystem sysIn;
  output BackendDAE.EqSystem sysOut;
algorithm
  sysOut := matchcontinue (tplsIn, m, mT, sysIn)
    local
      Integer sharedVar, eqIdx1, eqIdx2, varIdx1, varIdx2, varIdx_remain, varIdxAlias, eqIdxDel, eqIdxLeft, n;
      list<Integer> eqIdcs, eqs1, eqs2, vars1, vars2, aliasVars;
      list<CommonSubExp> rest;
      BackendDAE.Var var1, var2, var_remain, var_alias;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Variables vars;
      BackendDAE.Var var;
      BackendDAE.Equation eq1,eq2, eqNew;
      BackendDAE.EquationArray eqs;
      BackendDAE.EqSystem syst;
      DAE.Exp varExp_remain, varExp_alias, lhs1,rhs1,lhs2,rhs2,varExp,exp;
      DAE.Type ty;
      DAE.ComponentRef cref;
      list<BackendDAE.Equation> eqLst;
  case({}, _, _, syst as BackendDAE.EQSYSTEM())
    equation
    then (BackendDAEUtil.clearEqSyst(syst));

  case ( ASSIGNMENT_CSE(eqIdcs={eqIdx1, eqIdx2}, aliasVars={varIdx1, varIdx2})::rest, _, _,
         syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs))
    equation
     // update the equations
     repl = BackendVarTransform.emptyReplacements();
     eqs1 = arrayGet(mT, varIdx1);
     eqs2 = arrayGet(mT, varIdx2);
           //print("eqs1 "+stringDelimitList(List.map(eqs1, intString), ", ")+"\n");
           //print("eqs2 "+stringDelimitList(List.map(eqs2, intString), ", ")+"\n");

     var1 = BackendVariable.getVarAt(vars, varIdx1);
     var2 = BackendVariable.getVarAt(vars, varIdx2);

     //choose alias variable
     if BackendVariable.isStateVar(var1) then varIdxAlias = varIdx2; varIdx_remain = varIdx1;
     elseif BackendVariable.isStateVar(var2) then varIdx_remain = varIdx2; varIdxAlias = varIdx1;
     else
       if intLe(listLength(eqs2), listLength(eqs1)) then varIdxAlias = varIdx2; varIdx_remain = varIdx1; else varIdxAlias = varIdx1; varIdx_remain = varIdx2; end if;
     end if;

     if intLe(listLength(eqs2), listLength(eqs1)) then eqIdxDel = eqIdx2; _ = eqIdx1; else eqIdxDel = eqIdx1; _ = eqIdx2; end if;

     var_remain = BackendVariable.getVarAt(vars, varIdx_remain);
     var_alias = BackendVariable.getVarAt(vars, varIdxAlias);
     cref = BackendVariable.varCref(var_alias);
     varExp_remain = BackendVariable.varExp(var_remain);
     varExp_alias = BackendVariable.varExp(var_alias);
     repl = BackendVarTransform.addReplacement(repl, cref, varExp_remain, NONE());
         //BackendVarTransform.dumpReplacements(repl);

     //replace in equations
     eqIdcs = arrayGet(mT, varIdxAlias);
     eqLst = BackendEquation.getList(eqIdcs, eqs);
     //(eqLst, _) = BackendVarTransform.replaceEquations(eqLst, repl, NONE());
     eqs = List.threadFold(eqIdcs, eqLst, BackendEquation.setAtIndexFirst, eqs);

     //replace original equation
     BackendEquation.setAtIndex(eqs,eqIdxDel,BackendDAE.EQUATION(varExp_remain,varExp_alias,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC));
    then commonSubExpressionUpdate(rest, m, mT, syst);

case (SHORTCUT_CSE(eqIdcs={eqIdx1, eqIdx2}, sharedVar=sharedVar)::rest, _, _, syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs))
    equation
      {eq1, eq2} = BackendEquation.getList({eqIdx1, eqIdx2}, eqs);
      var = BackendVariable.getVarAt(vars, sharedVar);
      varExp = BackendVariable.varExp(var);
      _ = Expression.typeof(varExp);
      BackendDAE.EQUATION(exp=lhs1, scalar=rhs1) = eq1;
      BackendDAE.EQUATION(exp=lhs2, scalar=rhs2) = eq2;

      // since ExpressionSolve is able to solve for vars in if-expressions, stop here
      true = hasAlgebraicOperationsOnly(lhs1);
      true = hasAlgebraicOperationsOnly(rhs1);
      true = hasAlgebraicOperationsOnly(lhs2);
      true = hasAlgebraicOperationsOnly(rhs2);

      (rhs1, _) = ExpressionSolve.solve(lhs1, rhs1, varExp);
      (lhs1, _) = ExpressionSolve.solve(lhs2, rhs2, varExp);

      (_,lhs1,rhs1) = cancelExpressions(lhs1,rhs1);
      n = listLength(Expression.getAllCrefs(Expression.makeDiff(lhs1,rhs1)));
        //print("n1 "+intString(n1)+"\n");
        //print("n2 "+intString(n2)+"\n");

      if n <= 2 then
          //print("FROM "+BackendDump.equationString(eq1)+"\n");
          //print("AND  "+BackendDump.equationString(eq2)+"\n");
        eqNew = BackendDAE.EQUATION(lhs1,rhs1,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
          //print("MADE A NEW EQUATION "+BackendDump.equationString(eqNew)+"\n\n");
        //replace original equation
        BackendEquation.setAtIndex(eqs,eqIdx1,eqNew);
      end if;

    then commonSubExpressionUpdate(rest, m, mT, syst);
 case (_::rest, _, _, _)
  then commonSubExpressionUpdate(rest, m, mT, sysIn);
  end matchcontinue;
end commonSubExpressionUpdate;


protected function hasAlgebraicOperationsOnly"checks if the expression contains algebraic operations only. (no realtions, ifs, etc.)
author:Waurich TUD 05-2016"
  input DAE.Exp exp;
  output Boolean isAlgOut;
algorithm
  isAlgOut := match(exp)
  local
    Boolean b;
    DAE.Exp e1,e2;
    case(DAE.RCONST())
      then true;
    case(DAE.CREF())
      then true;
    case(DAE.BINARY(e1,_,e2))
      equation
        b = hasAlgebraicOperationsOnly(e1);
        b = b and hasAlgebraicOperationsOnly(e2);
      then b;
    case(DAE.UNARY(_,e1))
      equation
        b = hasAlgebraicOperationsOnly(e1);
      then b;
    else
      then false;
  end match;
end hasAlgebraicOperationsOnly;


protected function cancelExpressions"checks if factors on each side of an equation can be cancelled
author: Waurich TUD 2016-05"
  input DAE.Exp e1In;//lhs
  input DAE.Exp e2In;//rhs
  output Boolean canceled = false;
  output DAE.Exp e1Out = e1In;
  output DAE.Exp e2Out = e2In;
protected
  list<DAE.Exp> topLevelFactors1, topLevelFactors2;
algorithm
  topLevelFactors1 := getTopLevelFactors(e1In,{});
    //print("topLevelFactors1 "+ExpressionDump.printExpListStr(topLevelFactors1)+"\n");
  topLevelFactors2 := getTopLevelFactors(e2In,{});
    //print("topLevelFactors2 "+ExpressionDump.printExpListStr(topLevelFactors2)+"\n");
  if not listEmpty(topLevelFactors1) and not listEmpty(topLevelFactors1) then
    topLevelFactors1 := List.intersectionOnTrue(topLevelFactors1,topLevelFactors2,Expression.expEqual);
    if listLength(topLevelFactors1) == 1 then
      e1Out := Expression.expDiv(e1In,listHead(topLevelFactors1));
      e1Out := ExpressionSimplify.simplify(e1Out);
      e2Out := Expression.expDiv(e2In,listHead(topLevelFactors2));
      e2Out := ExpressionSimplify.simplify(e2Out);
          //print("e1Out "+ExpressionDump.printExpListStr({e1Out})+"\n");
          //print("e2Out "+ExpressionDump.printExpListStr({e2Out})+"\n");
      canceled := true;
    end if;
  end if;
end cancelExpressions;

protected function getTopLevelFactors"Gets factors(crefs only) of the exp"
  input DAE.Exp exp;
  input list<DAE.Exp> lstIn;
  output list<DAE.Exp> lstOut;
algorithm
  lstOut := matchcontinue(exp,lstIn)
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> eLst;
  case(DAE.BINARY(e1,DAE.MUL(_),e2),_)
    equation
      eLst = getTopLevelFactors(e1,lstIn);
      eLst = getTopLevelFactors(e2,eLst);
   then eLst;
  case(DAE.UNARY(_ ,e1 as DAE.CREF()),_)
    equation
   then e1::lstIn;
  case(e1 as DAE.CREF(),_)
    equation
   then e1::lstIn;
  else
    then lstIn;
  end matchcontinue;
end getTopLevelFactors;

protected function printCSE"prints a CSE tuple string.
author:Waurich TUD 2014-11"
  input CommonSubExp cse;
  output String s;
algorithm
  s := match(cse)
local
  Integer sharedVar;
  list<Integer> eqIdcs;
  list<Integer> sharedVars;
  list<Integer> aliasVars;
    case(ASSIGNMENT_CSE(eqIdcs=eqIdcs, sharedVars=sharedVars, aliasVars=aliasVars))
  then "ASSIGN_CSE: eqs{"+stringDelimitList(List.map(eqIdcs, intString), ", ")+"}"+"   sharedVars{"+stringDelimitList(List.map(sharedVars, intString), ", ")+"}"+"   aliasVars{"+stringDelimitList(List.map(aliasVars, intString), ", ")+"}";
     case(SHORTCUT_CSE(eqIdcs, sharedVar))
  then "SHORTCUT_CSE: eqs{"+stringDelimitList(List.map(eqIdcs, intString), ", ")+"}"+"   sharedVar{"+intString(sharedVar)+"}";
    end match;
end printCSE;
annotation(__OpenModelica_Interface="backend");

end CommonSubExpression;
