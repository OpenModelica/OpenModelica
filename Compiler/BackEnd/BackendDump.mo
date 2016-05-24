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

encapsulated package BackendDump
" file:        BackendDump.mo
  package:     BackendDump
  description: Unparsing the BackendDAE structure


  These file is subdivided into several section:
    - section for all print* functions
    - section for all dump* functions
    - section for all *String functions
    - section for all debug* functions
    - unsorted section

  Please follow the introduced naming style (above) and sort all new functions
  into the corresponding section (except unsorted section).
"

public import BackendDAE;
public import DAE;
public import HashSet;
public import Tpl;

protected import Absyn;
protected import Array;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import BaseHashSet;
protected import ClassInf;
protected import CodegenModelica;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import DumpHTML;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import GraphvizDump;
protected import GraphML;
protected import HpcOmTaskGraph;
protected import Initialization;
protected import IOStream;
protected import List;
protected import Matching;
protected import SCode;
protected import System;
protected import Util;

// =============================================================================
// section for all print* functions
//
// These are functions, that print directly to the standard-stream.
//   - printBackendDAE
//   - printEqSystem
//   - printEquation
//   - printEquationArray
//   - printEquationList
//   - printEquations
//   - printClassAttributes
//   - printShared
//   - printStateSets
//   - printVar
//   - printVariables
//   - printVarList
// =============================================================================

public function printBackendDAE "This function dumps the BackendDAE.BackendDAE representation to stdout."
  input BackendDAE.BackendDAE inBackendDAE;
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(eqs, shared) := inBackendDAE;
  List.map_0(eqs, printEqSystem);
  print("\n");
  printShared(shared);
end printBackendDAE;

public function printEqSystem "This function prints the BackendDAE.EqSystem representation to stdout."
  input BackendDAE.EqSystem inSyst;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrix> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  print("\n" + partitionKindString(inSyst.partitionKind) + "\n" + UNDERLINE + "\n");
  dumpVariables(inSyst.orderedVars, "Variables");
  dumpEquationArray(inSyst.orderedEqs, "Equations");
  dumpEquationArray(inSyst.removedEqs, "Simple Equations");
  dumpStateSets(inSyst.stateSets, "State Sets");
  dumpOption(inSyst.m, dumpIncidenceMatrix);
  dumpOption(inSyst.mT, dumpIncidenceMatrixT);

  print("\n");
  dumpFullMatching(inSyst.matching);
  print("\n");
end printEqSystem;

public function printEquation "author: PA
  Helper function to print_equations"
  input BackendDAE.Equation inEquation;
algorithm
  print(equationString(inEquation) + "\n");
end printEquation;

public function printEquationArray "Helper function to dump."
  input BackendDAE.EquationArray eqns;
algorithm
  _ := List.fold(BackendEquation.equationList(eqns), printEquationList2, (1, 1));
end printEquationArray;

public function printEquationList "Helper function to dump."
  input list<BackendDAE.Equation> eqns;
algorithm
  _ := List.fold(eqns, printEquationList2, (1, 1));
end printEquationList;

protected function printEquationList2 "Helper function for printEquationArray and printEquationList"
  input BackendDAE.Equation inEquation;
  input tuple<Integer,Integer> inInteger;
  output tuple<Integer,Integer> oInteger;
protected
  Integer iscalar,i,size;
  BackendDAE.EquationAttributes attr;
algorithm
  (i,iscalar) := inInteger;
  size := BackendEquation.equationSize(inEquation);
  attr := BackendEquation.getEquationAttributes(inEquation);
  print(intString(i) + "/" + intString(iscalar) + " (" + intString(size) + "): " + equationString(inEquation) + "   " + equationAttrString(attr) + "\n");
  oInteger := (i + 1,iscalar + size);
end printEquationList2;

public function equationListString
  input list<BackendDAE.Equation> inEqns;
  input String heading;
  output String outString;
algorithm
  outString := match(inEqns, heading)
    local
      String buffer;

    case (_, "") equation
      ((_, _, buffer)) = List.fold(inEqns, equationList2String, (1, 1, ""));
    then buffer;

    else equation
      ((_, _, buffer)) = List.fold(inEqns, equationList2String, (1, 1, ""));
      buffer = heading + "\n" + UNDERLINE + "\n" + buffer;
    then buffer;
  end match;
end equationListString;

protected function equationList2String
  input BackendDAE.Equation inEquation;
  input tuple<Integer, Integer, String /*buffer*/> inTuple;
  output tuple<Integer, Integer, String /*buffer*/> outTuple;
protected
  Integer iscalar, i, size;
  String buffer;
algorithm
  (i, iscalar, buffer) := inTuple;
  size := BackendEquation.equationSize(inEquation);
  buffer := buffer + intString(i) + "/" + intString(iscalar) + " (" + intString(size) + "): " + equationString(inEquation) + "\n";
  outTuple := (i + 1, iscalar + size, buffer);
end equationList2String;

public function printEquations ""
  input list<Integer> inIntegerLst;
  input BackendDAE.EqSystem syst;
algorithm
  _:= match(inIntegerLst, syst)
    local
      Integer n;
      list<Integer> rest;
    case ({}, _) then ();
    case ((n :: rest), _) equation
      printEquations(rest, syst);
      printEquationNo(n, syst);
    then ();
  end match;
end printEquations;

protected function printEquationNo "author: PA
  Helper function to printEquations"
  input Integer inInteger;
  input BackendDAE.EqSystem syst;
algorithm
  _:=
  match (inInteger,syst)
    local
      Integer eqno;
      BackendDAE.Equation eq;
      BackendDAE.EquationArray eqns;
    case (eqno,BackendDAE.EQSYSTEM(orderedEqs = eqns))
      equation
        eq = BackendEquation.equationNth1(eqns, eqno);
        printEquation(eq);
      then
        ();
  end match;
end printEquationNo;

public function printClassAttributes "This unction print the  Optimica ClassAttributes: objetiveE, objetiveE"
  input DAE.ClassAttributes optimicaFun;
  protected
    Option<DAE.Exp> e1,e2;
  algorithm
    DAE.OPTIMIZATION_ATTRS(objetiveE = e1, objectiveIntegrandE = e2) := optimicaFun;
    print("Mayer" + "\n" + UNDERLINE + "\n\n");
    print(ExpressionDump.printOptExpStr(e1));
    print("Lagrange" + "\n" + UNDERLINE + "\n\n");
    print(ExpressionDump.printOptExpStr(e2));
    print("\n");
end printClassAttributes;

public function printShared "This function dumps the BackendDAE.Shared representation to stdout."
  input BackendDAE.Shared inShared;
algorithm
  print("\nBackendDAEType: ");
  printBackendDAEType(inShared.backendDAEType);
  print("\n\n");

  dumpVariables(inShared.globalKnownVars, "Known variables only depending on parameters and constants - globalKnownVars");
  dumpVariables(inShared.localKnownVars, "Known variables only depending on states and inputs - localKnownVars");
  dumpVariables(inShared.externalObjects, "External Objects");
  dumpExternalObjectClasses(inShared.extObjClasses, "Classes of External Objects");
  dumpVariables(inShared.aliasVars, "Alias Variables");
  dumpEquationArray(inShared.removedEqs, "Simple Shared Equations");
  dumpEquationArray(inShared.initialEqs, "Initial Equations");
  dumpZeroCrossingList(inShared.eventInfo.zeroCrossingLst, "Zero Crossings");
  dumpZeroCrossingList(inShared.eventInfo.relationsLst, "Relations");
  if stringEqual(Config.simCodeTarget(), "Cpp") then
    dumpZeroCrossingList(inShared.eventInfo.sampleLst, "Samples");
  else
    dumpTimeEvents(inShared.eventInfo.timeEvents, "Time Events");
  end if;
  dumpConstraintList(inShared.constraints, "Constraints");
  dumpBasePartitions(inShared.partitionsInfo.basePartitions, "Base partitions");
  dumpSubPartitions(inShared.partitionsInfo.subPartitions, "Sub partitions");

  if Flags.isSet(Flags.DUMP_FUNCTIONS) then
    DAEDump.dumpFunctionTree(inShared.functionTree, "Functions");
  end if;
end printShared;

public function printBasePartitions
  input array<BackendDAE.BasePartition> basePartitions;
protected
  String clkExpStr, nSubClocksStr;
algorithm
  for i in 1:arrayLength(basePartitions) loop
    clkExpStr := Tpl.tplString2( ExpressionDumpTpl.dumpClockKind,
                                 basePartitions[i].clock, "");
    nSubClocksStr := intString(basePartitions[i].nSubClocks);
    print(intString(i) + ": " + clkExpStr + "[" + nSubClocksStr + "]" + "\n");
  end for;
end printBasePartitions;

public function printSubPartitions
  input array<BackendDAE.SubPartition> subPartitions;
protected
  String subClockStr, eventStr;
algorithm
  for i in 1:arrayLength(subPartitions) loop
    subClockStr := subClockString(subPartitions[i].clock);
    eventStr := "event(" + boolString(subPartitions[i].holdEvents) + ")";
    print(intString(i) + ": " + subClockStr + " " + eventStr + "\n");
  end for;
end printSubPartitions;

public function subClockString
  input BackendDAE.SubClock subClock;
  output String subClockString;
protected
  String factorStr, shiftStr, solverStr;
algorithm
  factorStr := "factor(" + MMath.rationalString(subClock.factor) + ")";
  shiftStr := "shift(" + MMath.rationalString(subClock.shift) + ")";
  solverStr := "solver(" + optionString(subClock.solver) + ")";
  if stringLength(solverStr) > 8 then
    subClockString := factorStr + " " + shiftStr + " " + solverStr;
  else
    subClockString := factorStr + " " + shiftStr + " ";
  end if;
end subClockString;

public function optionString
  input Option<String> option;
  output String optionString;
algorithm
  optionString := match option
    local
      String s;
    case SOME(s) then s;
    else "";
  end match;
end optionString;

public function printBackendDAEType "This is a helper for printShared."
  input BackendDAE.BackendDAEType btp;
algorithm
  print(printBackendDAEType2String(btp));
end printBackendDAEType;

public function printBackendDAEType2String "This is a helper for printShared."
  input BackendDAE.BackendDAEType btp;
  output String str;
algorithm
  str := match(btp)
    case (BackendDAE.SIMULATION()) then "simulation";
    case (BackendDAE.JACOBIAN()) then "jacobian";
    case (BackendDAE.ALGEQSYSTEM()) then "algebraic loop";
    case (BackendDAE.ARRAYSYSTEM()) then "multidim equation arrays";
    case (BackendDAE.PARAMETERSYSTEM()) then "parameter system";
    case (BackendDAE.INITIALSYSTEM()) then "initialization";
  end match;
end printBackendDAEType2String;

public function printStateSets "author: Frenkel TUD"
  input BackendDAE.StateSets stateSets;
algorithm
  List.map_0(stateSets, printStateSet);
end printStateSets;

protected function printStateSet "author: lochel"
  input BackendDAE.StateSet inStateSet;
algorithm
  print("StateSet \"" + ComponentReference.printComponentRefStr(ComponentReference.crefFirstCref(inStateSet.crA)) + "\" (rang " + intString(inStateSet.rang) + ")\n");

  dumpVarList(inStateSet.statescandidates, "state candidates");
  dumpEquationList(inStateSet.eqns, "eqns");

  dumpVarList(inStateSet.ovars, "ovars");
  dumpEquationList(inStateSet.oeqns, "oeqns");

  dumpVarList(inStateSet.varA, "varA");
  dumpVarList(inStateSet.varJ, "varJ");

  //print(jacobianString(inStateSet.jacobian));
end printStateSet;

public function printVar
  input BackendDAE.Var inVar;
algorithm
  print(varString(inVar) + "\n");
end printVar;

public function printVariables "Helper function to dump."
  input BackendDAE.Variables vars;
algorithm
  _ := List.fold(BackendVariable.varList(vars), printVars1, 1);
end printVariables;

public function printVarList "Helper function to dump."
  input list<BackendDAE.Var> vars;
algorithm
  _ := List.fold(vars, printVars1, 1);
end printVarList;

protected function printVars1 "This is a helper function for printVariables and printVarList"
  input BackendDAE.Var inVar;
  input Integer inVarNo;
  output Integer outVarNo;
algorithm
  print(intString(inVarNo));
  print(": ");
  printVar(inVar);
  outVarNo := inVarNo + 1;
end printVars1;

public function varListString
  input list<BackendDAE.Var> inVars;
  input String heading;
  output String outString;
algorithm
  outString := match(inVars, heading)
    local
      String buffer;

    case (_, "") equation
      ((_, buffer)) = List.fold(inVars, var1String, (1, ""));
    then buffer;

    else equation
      ((_, buffer)) = List.fold(inVars, var1String, (1, ""));
      buffer = heading + "\n" + UNDERLINE + "\n" + buffer;
    then buffer;
  end match;
end varListString;

protected function var1String
  input BackendDAE.Var inVar;
  input tuple<Integer /*inVarNo*/, String /*buffer*/> inTpl;
  output tuple<Integer /*outVarNo*/, String /*buffer*/> outTpl;
protected
  Integer varNo;
  String buffer;
algorithm
  (varNo, buffer) := inTpl;
  buffer := buffer + intString(varNo) + ": ";
  buffer := buffer + varString(inVar) + "\n";
  outTpl := (varNo + 1, buffer);
end var1String;

protected function printExternalObjectClasses "dump classes of external objects"
  input BackendDAE.ExternalObjectClasses cls;
algorithm
  _ := match(cls)
    local
      BackendDAE.ExternalObjectClasses xs;
      Absyn.Path path;
      list<Absyn.Path> paths;
      list<String> paths_lst;
      DAE.ElementSource source "the element source";
      String path_str;

    case {} then ();

    case BackendDAE.EXTOBJCLASS(path,source)::_ equation
      print("class ");
      print(Absyn.pathString(path));
      print("\n  extends ExternalObject;");
      print("\n origin: ");
      paths = ElementSource.getElementSourceTypes(source);
      paths_lst = list(Absyn.pathString(p) for p in paths);
      path_str = stringDelimitList(paths_lst, ", ");
      print(path_str + "\n");
      print("end ");print(Absyn.pathString(path));
    then ();
  end match;
end printExternalObjectClasses;

protected function printSparsityPattern "author lochel"
  input list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> inPattern;
algorithm
  () := matchcontinue(inPattern)
    local
      tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>> curr;
      list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> rest;
      .DAE.ComponentRef cr;
      list< .DAE.ComponentRef> crList;
      String crStr;

    case (curr::rest) equation
      (cr, crList) = curr;
      crStr = ComponentReference.crefStr(cr);
      print(crStr + " affects the following (" + intString(listLength(crList)) + ") outputs\n  ");
      ComponentReference.printComponentRefList(crList);

      printSparsityPattern(rest);
    then ();

    else
    then ();
  end matchcontinue;
end printSparsityPattern;

// =============================================================================
// section for all graphviz* functions
//
// =============================================================================

public function graphvizBackendDAE
  input BackendDAE.BackendDAE inBackendDAE;
  input String inFileNameSuffix;
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.EqSystems eqSystems;
  String fileNamePrefix;
  String buffer;
algorithm
  dae := setIncidenceMatrix(inBackendDAE);
  Tpl.tplNoret2(GraphvizDump.dumpBackendDAE, dae, inFileNameSuffix);
end graphvizBackendDAE;

public function graphvizIncidenceMatrix
  input BackendDAE.BackendDAE inBackendDAE;
  input String inFileNameSuffix;
protected
  BackendDAE.BackendDAE dae;
  BackendDAE.EqSystems eqSystems;
  String fileNamePrefix;
  String buffer;
algorithm
  dae := setIncidenceMatrix(inBackendDAE);
  Tpl.tplNoret2(GraphvizDump.dumpIncidenceMatrix, dae, inFileNameSuffix);
end graphvizIncidenceMatrix;

protected function setIncidenceMatrix
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.EqSystems eqSystems;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(eqSystems, shared) := inBackendDAE;
  eqSystems := List.map(eqSystems, setIncidenceMatrix1);
  outBackendDAE := BackendDAE.DAE(eqSystems, shared);
end setIncidenceMatrix;

protected function setIncidenceMatrix1
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
algorithm
  (outEqSystem, _, _) := BackendDAEUtil.getIncidenceMatrix(inEqSystem, BackendDAE.NORMAL(), NONE());
end setIncidenceMatrix1;

// =============================================================================
// section for all dump* functions
//
// These are functions, that print directly to the standard-stream and separates
// there output (e.g. with some kind of headings).
//   - dumpBackendDAE
//   - dumpBackendDAEToModelica
//   - dumpBackendDAEEqnList
//   - dumpBackendDAEVarList
//   - dumpComponent
//   - dumpComponents
//   - dumpComponentsAdvanced
//   - dumpEqnsSolved
//   - dumpEqSystem
//   - dumpEqSystems
//   - dumpEquationArray
//   - dumpEquationList
//   - dumpHashSet
//   - dumpSparsityPattern
//   - dumpTearing
//   - dumpVariables
//   - dumpVarList
// =============================================================================

public constant String BORDER    = "########################################";
public constant String UNDERLINE = "========================================";

public function dumpDAE "dumps the DAE representation of the current transformation state"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
algorithm
  dumpBackendDAE(inDAE, "dumpDAE");
end dumpDAE;

public function dumpBackendDAE "This function dumps the BackendDAE.BackendDAE representation to stdout."
  input BackendDAE.BackendDAE inBackendDAE;
  input String heading;
algorithm
  print("\n" + BORDER + "\n" + heading + "\n" + BORDER + "\n\n");
  printBackendDAE(inBackendDAE);
  print("\n");
end dumpBackendDAE;

public function dumpBackendDAEToModelica "This function dumps the BackendDAE.BackendDAE representation to a Modelica file."
  input BackendDAE.BackendDAE inBackendDAE;
  input String suffix;
protected
  String str;
algorithm
  str := Tpl.tplString(CodegenModelica.dumpBackendDAE, inBackendDAE);
  Error.addMessage(Error.BACKEND_DAE_TO_MODELICA, {suffix, str});
end dumpBackendDAEToModelica;

public function dumpEqSystem
  input BackendDAE.EqSystem inEqSystem;
  input String heading;
algorithm
  print("\n" + heading + "\n" + UNDERLINE + "\n");
  printEqSystem(inEqSystem);
  print("\n");
end dumpEqSystem;

public function dumpEqSystems
  input BackendDAE.EqSystems inEqSystems;
  input String heading;
algorithm
  print("\n" + BORDER + "\n" + heading + " (" + intString(listLength(inEqSystems)) + " partitions)\n" + BORDER + "\n\n");
  List.map_0(inEqSystems, printEqSystem);
  print("\n");
end dumpEqSystems;

public function dumpBasePartitions
  input array<BackendDAE.BasePartition> basePartitions;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(arrayLength(basePartitions)) + ")\n" + UNDERLINE + "\n");
  printBasePartitions(basePartitions);
  print("\n");
end dumpBasePartitions;

public function dumpSubPartitions
  input array<BackendDAE.SubPartition> subPartitions;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(arrayLength(subPartitions)) + ")\n" + UNDERLINE + "\n");
  printSubPartitions(subPartitions);
  print("\n");
end dumpSubPartitions;


public function dumpVariables "function dumpVariables"
  input BackendDAE.Variables inVars;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(BackendVariable.varsSize(inVars)) + ")\n" + UNDERLINE + "\n");
  printVariables(inVars);
  print("\n");
end dumpVariables;

public function dumpVarList "function dumpVarList"
  input list<BackendDAE.Var> inVars;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(listLength(inVars)) + ")\n" + UNDERLINE + "\n");
  printVarList(inVars);
  print("\n");
end dumpVarList;

public function dumpEquationArray "function dumpEquationArray"
  input BackendDAE.EquationArray inEqns;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(listLength(BackendEquation.equationList(inEqns))) + ", " + intString(BackendDAEUtil.equationSize(inEqns)) + ")\n" + UNDERLINE + "\n");
  printEquationArray(inEqns);
  print("\n");
end dumpEquationArray;

public function dumpEquationList "function dumpEquationList"
  input list<BackendDAE.Equation> inEqns;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(listLength(inEqns)) + ")\n" + UNDERLINE + "\n");
  printEquationList(inEqns);
  print("\n");
end dumpEquationList;

protected function dumpExternalObjectClasses "dump classes of external objects"
  input BackendDAE.ExternalObjectClasses inEOC;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(listLength(inEOC)) + ")\n" + UNDERLINE + "\n");
  printExternalObjectClasses(inEOC);
  print("\n");
end dumpExternalObjectClasses;

protected function dumpStateSets
  input BackendDAE.StateSets stateSets;
  input String heading;
algorithm
  print("\n" + heading + "\n" + UNDERLINE + "\n");
  printStateSets(stateSets);
  print("\n");
end dumpStateSets;

public function dumpZeroCrossingList
  input list<BackendDAE.ZeroCrossing> inZeroCrossingList;
  input String heading;
protected
  BackendDAE.ZeroCrossing zeroCrossing;
algorithm
  print("\n" + heading + " (" + intString(listLength(inZeroCrossingList)) + ")\n" + UNDERLINE + "\n");
  for zeroCrossing in inZeroCrossingList loop
    print(zeroCrossingString(zeroCrossing) + "\n");
  end for;
  print("\n");
end dumpZeroCrossingList;

public function dumpTimeEvents
  input list<BackendDAE.TimeEvent> inTimeEvents;
  input String heading;
protected
  BackendDAE.TimeEvent timeEvent;
algorithm
  print("\n" + heading + " (" + intString(listLength(inTimeEvents)) + ")\n" + UNDERLINE + "\n");
  for timeEvent in inTimeEvents loop
    print(timeEventString(timeEvent) + "\n");
  end for;
  print("\n");
end dumpTimeEvents;

protected function dumpConstraintList
  input list<DAE.Constraint> inConstraintArray;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(listLength(inConstraintArray)) + ")\n" + UNDERLINE + "\n");
  dumpConstraints(inConstraintArray, 0);
  print("\n");
end dumpConstraintList;

public function dumpHashSet "author lochel"
  input HashSet.HashSet hashSet;
  input String heading;
protected
  Integer size;
algorithm
  size := BaseHashSet.currentSize(hashSet);
  print("\n" + heading + " (" + intString(size) + ")\n" + UNDERLINE + "\n");
  BaseHashSet.printHashSet(hashSet);
  print("\n");
end dumpHashSet;

public function dumpSparsityPattern "author lochel"
  input BackendDAE.SparsePattern inPattern;
  input String heading;
protected
  list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> pattern;
  list< .DAE.ComponentRef> diffVars, diffedVars;
  Integer nnz;
algorithm
  (pattern, _, (diffVars, diffedVars), nnz) := inPattern;

  print("\n" + heading + "\n" + UNDERLINE + "\n");
  print("Number of non zero elements: " + intString(nnz) + ")\n");
  print("independents [or inputs] (" + intString(listLength(diffVars)) + ")\n");
  ComponentReference.printComponentRefList(diffVars);

  print("dependents [or outputs] (" + intString(listLength(diffedVars)) + ")\n");
  ComponentReference.printComponentRefList(diffedVars);

  printSparsityPattern(pattern);
end dumpSparsityPattern;

public function dumpTearing "
  author: Frenkel TUD
  Dump tearing vars and residual equations."
  input list<list<Integer>> inResEqn;
  input list<list<Integer>> inTearVar;
algorithm
  _:=
  match (inResEqn,inTearVar)
    local
      list<Integer> tearingvars,residualeqns;
      list<list<Integer>> r,t;
      list<String> str_r,str_t;
      String str_r_f,str_r_1,str_t_f,str_t_1,str,sr,st;
    case (residualeqns::r,tearingvars::t)
      equation
        str_r = List.map(residualeqns, intString);
        str_r_f = stringDelimitList(str_r, ", ");
        str_r_1 = stringAppend(str_r_f, "\n");
        sr = stringAppend("ResidualEqns: ",str_r_1);
        str_t = List.map(tearingvars, intString);
        str_t_f = stringDelimitList(str_t, ", ");
        str_t_1 = stringAppend(str_t_f, "\n");
        st = stringAppend("TearingVars: ",str_t_1);
        str = stringAppend(sr, st);
        print(str);
        print("\n");
        dumpTearing(r,t);
      then
        ();
  end match;
end dumpTearing;

public function dumpBackendDAEEqnList
  input list<BackendDAE.Equation> inBackendDAEEqnList;
  input String header;
  input Boolean printExpTree;
algorithm
  print(header + "\n");
  dumpBackendDAEEqnList2(inBackendDAEEqnList,printExpTree);
  print("===================\n");
end dumpBackendDAEEqnList;

protected function dumpBackendDAEEqnList2
  input list<BackendDAE.Equation> inBackendDAEEqnList;
  input Boolean printExpTree;
algorithm
  _ := matchcontinue (inBackendDAEEqnList,printExpTree)
    local
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e;
      String str;
      list<String> strList;
      list<BackendDAE.Equation> res;
      list<DAE.Exp> expList,expList2;
      Integer i;
      DAE.ElementSource source;
      DAE.Algorithm alg;
      Boolean diffed;
      DAE.ComponentRef cr;
      BackendDAE.EquationKind eqKind;
      BackendDAE.WhenEquation weqn;

    case ({}, _) then ();

    case (BackendDAE.EQUATION(exp=e1, scalar=e2, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res, _) equation /*done*/
      str = "EQUATION: ";
      str = str + ExpressionDump.printExpStr(e1);
      str = str + " = ";
      str = str + ExpressionDump.printExpStr(e2);
      str = str + " (" + equationKindString(eqKind) + ")\n";
      print(str);

      str = "LHS:\n";
      str = str + ExpressionDump.dumpExpStr(e1, 0);
      str = str + "RHS:\n";
      str = str + ExpressionDump.dumpExpStr(e2, 0);
      str = str + "\n";
      str = if printExpTree then str else "";
      print(str);

      dumpBackendDAEEqnList2(res, printExpTree);
    then ();

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res, _) equation /*done*/
      str = "COMPLEX_EQUATION: ";
      str = str + ExpressionDump.printExpStr(e1);
      str = str + " = ";
      str = str + ExpressionDump.printExpStr(e2);
      str = str + " (" + equationKindString(eqKind) + ")\n";
      print(str);

      str = "LHS:\n";
      str = str + ExpressionDump.dumpExpStr(e1, 0);
      str = str + "RHS:\n";
      str = str + ExpressionDump.dumpExpStr(e2, 0);
      str = str + "\n";
      str = if printExpTree then str else "";
      print(str);

      dumpBackendDAEEqnList2(res,printExpTree);
    then ();

    case (BackendDAE.SOLVED_EQUATION(exp=e, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res,_) equation
      print("SOLVED_EQUATION: ");
      str = ExpressionDump.printExpStr(e);
      print(str);
      print(" (" + equationKindString(eqKind) + ")\n");
      str = ExpressionDump.dumpExpStr(e,0);
      str = if printExpTree then str else "";
      print(str);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();

    case (BackendDAE.RESIDUAL_EQUATION(exp=e, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res, _) equation /*done*/
      str = "RESIDUAL_EQUATION: ";
      str = str + ExpressionDump.printExpStr(e);
      str = str + " (" + equationKindString(eqKind) + ")\n";
      print(str);

      str = ExpressionDump.dumpExpStr(e, 0);
      str = str + "\n";
      str = if printExpTree then str else "";
      print(str);

      dumpBackendDAEEqnList2(res, printExpTree);
    then ();

    case (BackendDAE.ARRAY_EQUATION(left=e1, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res,_) equation
      print("ARRAY_EQUATION: ");
      str = ExpressionDump.printExpStr(e1);
      print(str);
      str = str + " (" + equationKindString(eqKind) + ")\n";
      str = ExpressionDump.dumpExpStr(e1,0);
      str = if printExpTree then str else "";
      print(str);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();

    case (BackendDAE.ALGORITHM(alg=alg, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res,_) equation
      print("ALGORITHM: ");
      dumpAlgorithms({alg},0);
      print(" (" + equationKindString(eqKind) + ")\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();

    case (BackendDAE.WHEN_EQUATION(whenEquation=weqn,  attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res, _) equation
      print("WHEN_EQUATION: ");
      str = whenEquationString(weqn, true);
      print(str);
      str = str + " (" + equationKindString(eqKind) + ")\n";
      e = weqn.condition;
      str = ExpressionDump.dumpExpStr(e,0);
      str = if printExpTree then str else "";
      print(str);
      print("\n");
    then ();

    case (_::res, _) equation
      print("SKIPED EQUATION\n");
      dumpBackendDAEEqnList2(res, printExpTree);
    then ();
  end matchcontinue;
end dumpBackendDAEEqnList2;

public function dumpBackendDAEVarList
  input list<BackendDAE.Var> inBackendDAEVarList;
  input String header;
algorithm
   print(header + "\n");
   printVarList(inBackendDAEVarList);
   print("===================\n");
end dumpBackendDAEVarList;

public function dumpEqnsSolved "This function dumps the equations in the order they have to be calculate."
  input BackendDAE.BackendDAE inBackendDAE;
  input String heading;
protected
  BackendDAE.EqSystems eqs;
algorithm
  print("\n" + heading + "\n" + UNDERLINE + "\n");
  BackendDAE.DAE(eqs=eqs) := inBackendDAE;
  List.map_0(eqs, dumpEqnsSolved1);
  print("\n");
end dumpEqnsSolved;

protected function dumpEqnsSolved1 "This is a helper for dumpEqnsSolved."
  input BackendDAE.EqSystem inEqSystem;
algorithm
  _:= match(inEqSystem)
    local
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponents comps;
    case (BackendDAE.EQSYSTEM(orderedVars=vars,
                              orderedEqs=eqns,
                              matching=BackendDAE.MATCHING(comps=comps))) equation
      dumpEqnsSolved2(comps, eqns, vars);
    then ();

    else equation
      print("No Matching\n");
    then ();
  end match;
end dumpEqnsSolved1;

protected function dumpEqnsSolved2 "author: Frenkel TUD 2012-03"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Variables vars;
algorithm
  _ :=
  matchcontinue (inComps,eqns,vars)
    local
      Integer e,v;
      list<Integer> elst,vlst,vlst1,elst1,vlst2,elst2;
      list<list<Integer>> vlst1Lst;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.JacobianType jacType;
      BackendDAE.InnerEquations innerEquations,innerEquations2;
      Boolean b;
      String s;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
    case ({},_,_)  then ();
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v)::rest,_,_)
      equation
        print("SingleEquation: " + intString(e) + "\n");
        var = BackendVariable.getVarAt(vars,v);
        printVarList({var});
        eqn = BackendEquation.equationNth1(eqns,e);
        printEquationList({eqn});
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst,jac=BackendDAE.FULL_JACOBIAN(jac),jacType=jacType)::rest,_,_)
      equation
        print("Equationsystem " + jacobianTypeStr(jacType) + ":\n");
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        eqnlst = BackendEquation.getEqns(elst,eqns);
        printEquationList(eqnlst);
        print("\n");
        print("Jac:\n" + dumpJacobianStr(jac) + "\n");
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (BackendDAE.SINGLEARRAY(eqn=e,vars=vlst)::rest,_,_)
      equation
        print("ArrayEquation:\n");
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        eqn = BackendEquation.equationNth1(eqns,e);
        printEquationList({eqn});
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (BackendDAE.SINGLEIFEQUATION(eqn=e,vars=vlst)::rest,_,_)
      equation
        print("IfEquation:\n");
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        eqn = BackendEquation.equationNth1(eqns,e);
        printEquationList({eqn});
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (BackendDAE.SINGLEALGORITHM(eqn=e,vars=vlst)::rest,_,_)
      equation
        print("Algorithm:\n");
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        eqn = BackendEquation.equationNth1(eqns,e);
        printEquationList({eqn});
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e,vars=vlst)::rest,_,_)
      equation
        print("ComplexEquation:\n");
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        eqn = BackendEquation.equationNth1(eqns,e);
        printEquationList({eqn});
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e,vars=vlst)::rest,_,_)
      equation
        print("WhenEquation:\n");
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        eqn = BackendEquation.equationNth1(eqns,e);
        printEquationList({eqn});
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    // no dynamic tearing
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst,residualequations=elst,innerEquations=innerEquations),NONE(),linear=b)::rest,_,_)
      equation
        s = if b then "linear" else "nonlinear";
        print("torn " + s + " Equationsystem:\n");
        (elst1,vlst1Lst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        vlst1 = List.flatten(vlst1Lst);
        varlst = List.map1r(vlst1, BackendVariable.getVarAt, vars);
        print("\ninternal vars\n");
        printVarList(varlst);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        print("\nresidual vars\n");
        printVarList(varlst);
        print("\ninternal equation\n");
        eqnlst = BackendEquation.getEqns(elst1,eqns);
        printEquationList(eqnlst);
        print("\nresidual equations\n");
        eqnlst = BackendEquation.getEqns(elst,eqns);
        printEquationList(eqnlst);
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    // dynamic tearing
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst,residualequations=elst,innerEquations=innerEquations),SOME(BackendDAE.TEARINGSET(tearingvars=vlst2,residualequations=elst2,innerEquations=innerEquations2)),linear=b)::rest,_,_)
      equation
        s = if b then "linear" else "nonlinear";
        print("Strict torn " + s + " Equationsystem:\n");
        (elst1,vlst1Lst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        vlst1 = List.flatten(vlst1Lst);
        varlst = List.map1r(vlst1, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        print("\n");
        eqnlst = BackendEquation.getEqns(elst1,eqns);
        printEquationList(eqnlst);
        print("\n");
        eqnlst = BackendEquation.getEqns(elst,eqns);
        printEquationList(eqnlst);
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
        print("Casual torn " + s + " Equationsystem:\n");
        (elst1,vlst1Lst,_) = List.map_3(innerEquations2, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        vlst1 = List.flatten(vlst1Lst);
        varlst = List.map1r(vlst1, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        varlst = List.map1r(vlst2, BackendVariable.getVarAt, vars);
        printVarList(varlst);
        print("\n");
        eqnlst = BackendEquation.getEqns(elst1,eqns);
        printEquationList(eqnlst);
        print("\n");
        eqnlst = BackendEquation.getEqns(elst2,eqns);
        printEquationList(eqnlst);
        print("\n");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
    case (_::rest,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("BackendDump.dumpEqnsSolved2 failed!");
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
  case (_::rest,_,_)
      equation
        dumpEqnsSolved2(rest,eqns,vars);
      then
        ();
  end matchcontinue;
end dumpEqnsSolved2;

public function dumpLoops "author: vitalij"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  BackendDAE.StrongComponents comps;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
  Integer isyst = 1;
algorithm
    _ := match outDAE.shared
            case BackendDAE.SHARED(backendDAEType=BackendDAE.SIMULATION()) then print("SIMULATION\n");
            case BackendDAE.SHARED(backendDAEType=BackendDAE.INITIALSYSTEM()) then print("INITIALSYSTEM\n");
            else print("UNKNOWN\n");
            end match;

   for syst in inDAE.eqs loop
     print("\nsystem " + intString(isyst) + "\n");
     BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns, matching=BackendDAE.MATCHING(comps=comps)) := syst;
     for comp in comps loop
       if BackendEquation.isEquationsSystem(comp) or BackendEquation.isTornSystem(comp) then
         dumpEqnsSolved2({comp}, eqns, vars);
       end if;
     end for;
   isyst := isyst + 1;
   end for;
end dumpLoops;

public function dumpComponentsAdvanced "author: Frenkel TUD
  Prints the blocks of the BLT sorting on stdout."
  input list<list<Integer>> l;
  input array<Integer> v2;
  input BackendDAE.EqSystem syst;
protected
  BackendDAE.Variables vars;
algorithm
  print("Blocks\n");
  print("=======\n");
  vars := BackendVariable.daeVars(syst);
  dumpComponentsAdvanced2(l, 1,v2,vars);
end dumpComponentsAdvanced;

protected function dumpComponentsAdvanced2 "author: PA
  Helper function to dump_components."
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
  input array<Integer> v2;
  input BackendDAE.Variables vars;
algorithm
  _:=
  match (inIntegerLstLst,inInteger,v2,vars)
    local
      Integer ni,i_1,i;
      list<String> ls;
      String s;
      list<Integer> l;
      list<list<Integer>> lst;
    case ({},_,_,_) then ();
    case ((l :: lst),i,_,_)
      equation
        print("{");
        ls = List.map(l, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("} ");
        dumpComponentsAdvanced3(l,v2,vars);
        print("\n");
        i_1 = i + 1;
        dumpComponentsAdvanced2(lst, i_1,v2,vars);
      then ();
  end match;
end dumpComponentsAdvanced2;

protected function dumpComponentsAdvanced3 "author: PA
  Helper function to dump_components."
  input list<Integer> inIntegerLst;
  input array<Integer> v2;
  input BackendDAE.Variables vars;
algorithm
  _:=
  match (inIntegerLst,v2,vars)
    local
      Integer i,v;
      list<String> ls;
      String s;
      list<Integer> l;
      DAE.ComponentRef c;
      BackendDAE.Var var;
      Boolean b;
    case ({},_,_) then ();
    case (i::{},_,_)
      equation
        v = v2[i];
        var = BackendVariable.getVarAt(vars,v);
        c = BackendVariable.varCref(var);
        b = BackendVariable.isStateVar(var);
        s = if b then "der(" else "";
        print(s);
        s = ComponentReference.printComponentRefStr(c);
        print(s);
        s = if b then ") " else " ";
        print(s);
      then ();
    case (i::l,_,_)
      equation
        v = v2[i];
        var = BackendVariable.getVarAt(vars,v);
        c = BackendVariable.varCref(var);
        b = BackendVariable.isStateVar(var);
        s = if b then "der(" else "";
        print(s);
        s = ComponentReference.printComponentRefStr(c);
        print(s);
        s = if b then ") " else " ";
        print(s);
        dumpComponentsAdvanced3(l,v2,vars);
      then ();
  end match;
end dumpComponentsAdvanced3;

public function dumpComponents
  input BackendDAE.StrongComponents inComps;
algorithm
  print("StrongComponents\n");
  print(UNDERLINE + "\n");
  List.map_0(inComps,dumpComponent);
end dumpComponents;

public function dumpComponent
  input BackendDAE.StrongComponent inComp;

algorithm
  print(printComponent(inComp));

end dumpComponent;

public function printComponent
  input BackendDAE.StrongComponent inComp;
  output String oString;

protected
  String tmpStr,tmpStr2;

algorithm
  oString := match (inComp)
    local
      Integer i,v;
      list<Integer> ilst,vlst,ilst2,vlst2;
      list<String> ls;
      String s,s2,s3,s4;
      BackendDAE.JacobianType jacType;
      BackendDAE.StrongComponent comp;
      BackendDAE.InnerEquations innerEquations,innerEquations2;
      Boolean b;
    case BackendDAE.SINGLEEQUATION(eqn=i,var=v)
      equation
        tmpStr = "{" + intString(i) + ":" + intString(v) + "}\n";
      then tmpStr;
    case BackendDAE.EQUATIONSYSTEM(eqns=ilst,vars=vlst,jacType=jacType)
      equation
        ls = List.map(ilst, intString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(vlst, intString);
        s2 = stringDelimitList(ls, ", ");

        tmpStr = "{" + s + ":" + s2 + "} Size: " + intString(listLength(vlst)) + " " + jacobianTypeStr(jacType) + "\n";
      then tmpStr;
    case BackendDAE.SINGLEARRAY(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        tmpStr = "Array " + " {{" + intString(i) + ":" + s + "}}\n";
      then tmpStr;
    case BackendDAE.SINGLEIFEQUATION(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        tmpStr = "IfEquation " + " {{" + intString(i) + ":" + s + "}}\n";
      then tmpStr;
    case BackendDAE.SINGLEALGORITHM(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        tmpStr = "Algorithm " + " {{" + intString(i) + ":" + s + "}}\n";
      then tmpStr;
    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        tmpStr = "ComplexEquation " + " {" + intString(i) + ":" + s + "}\n";
      then tmpStr;
    case BackendDAE.SINGLEWHENEQUATION(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        tmpStr = "WhenEquation " + " {" + intString(i) + ":" + s + "}\n";
      then tmpStr;
    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=ilst,tearingvars=vlst,innerEquations=innerEquations),NONE(),linear=b)
      equation
        ls = List.map(innerEquations, innerEquationString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(ilst, intString);
        s2 = stringDelimitList(ls, ", ");
        ls = List.map(vlst, intString);
        s3 = stringDelimitList(ls, ", ");
        s4 = if b then "linear" else "nonlinear";
        tmpStr = "{{" + s + "}\n,{" + s2 + ":" + s3 + "}} Size: " + intString(listLength(vlst)) + " " + s4 + "\n";
      then tmpStr;
    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=ilst,tearingvars=vlst,innerEquations=innerEquations),SOME(BackendDAE.TEARINGSET(residualequations=ilst2,tearingvars=vlst2,innerEquations=innerEquations2)),linear=b)
      equation
        ls = List.map(innerEquations, innerEquationString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(ilst, intString);
        s2 = stringDelimitList(ls, ", ");
        ls = List.map(vlst, intString);
        s3 = stringDelimitList(ls, ", ");
        s4 = if b then "linear" else "nonlinear";
        tmpStr = "{{" + s + "}\n,{" + s2 + ":" + s3 + "}} Size: " + intString(listLength(vlst)) + " " + s4 + " (strict tearing set)\n";
        ls = List.map(innerEquations2, innerEquationString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(ilst2, intString);
        s2 = stringDelimitList(ls, ", ");
        ls = List.map(vlst2, intString);
        s3 = stringDelimitList(ls, ", ");
        s4 = if b then "linear" else "nonlinear";
        tmpStr2 = "{{" + s + "}\n,{" + s2 + ":" + s3 + "}} Size: " + intString(listLength(vlst2)) + " " + s4 + " (casual tearing set)\n";
      then tmpStr + tmpStr2;
  end match;
end printComponent;


public function dumpListList
  input list<list<Integer>> lstLst;
  input String heading;
algorithm
  print("\n" + heading + ":\n" + UNDERLINE + "\n" + stringDelimitList(List.map(lstLst,intListStr),"\n") + "\n\n");
end dumpListList;


// =============================================================================
// section for all *String functions
//
// These are functions, that return their output with a String.
//   - componentRef_DIVISION_String
//   - equationString
//   - strongComponentString
// =============================================================================

public function strongComponentString
  input BackendDAE.StrongComponent inComp;
  output String outS;
algorithm
  outS := match(inComp)
    local
      Integer i,v;
      list<Integer> ilst,vlst;
      list<String> ls,ls1;
      String s,s1,s2,sl,sj;
      BackendDAE.JacobianType jacType;
      BackendDAE.StrongComponent comp;
      BackendDAE.InnerEquations innerEquations;
      Boolean b;
    case BackendDAE.SINGLEEQUATION(eqn=i,var=v)
      equation
        s = intString(i);
        s1 = intString(v);
        s = stringAppendList({"{",s,":",s1,"}"});
      then s;
    case BackendDAE.EQUATIONSYSTEM(eqns=ilst,vars=vlst,jacType=jacType)
      equation
        ls = List.map(ilst, intString);
        s = stringDelimitList(ls, ", ");
        ls1 = List.map(vlst, intString);
        s1 = stringDelimitList(ls1, ", ");
        sl = intString(listLength(ilst));
        sj = jacobianTypeStr(jacType);
        s2 = stringAppendList({"{",s,":",s1,"} Size: ",sl," ",sj});
      then
        s2;
    case BackendDAE.SINGLEARRAY(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        sl = intString(i);
        s2 = stringAppendList({"Array ",sl," {",s,"}"});
      then
        s2;
    case BackendDAE.SINGLEIFEQUATION(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        sl = intString(i);
        s2 = stringAppendList({"Array ",sl," {",s,"}"});
      then
        s2;
    case BackendDAE.SINGLEALGORITHM(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        sl = intString(i);
        s2 = stringAppendList({"Algorithm ",sl," {",s,"}"});
      then
        s2;
    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        sl = intString(i);
        s2 = stringAppendList({"ComplexEquation ",sl," {",s,"}"});
      then
        s2;
    case BackendDAE.SINGLEWHENEQUATION(eqn=i,vars=vlst)
      equation
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        sl = intString(i);
        s2 = stringAppendList({"WhenEquation ",sl," {",s,"}"});
      then
        s2;
   case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=ilst,tearingvars=vlst,innerEquations=innerEquations),linear=b)
      equation
        ls = List.map(innerEquations, innerEquationString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(ilst, intString);
        s1 = stringDelimitList(ls, ", ");
        ls = List.map(vlst, intString);
        s2 = stringDelimitList(ls, ", ");
        sj = intString(listLength(vlst));
        sl = if b then "linear" else "nonlinear";
        s2 = stringAppendList({"torn ",sl," Equationsystem","{{",s,"},\n{",s1,":",s2,"} Size: ",sj});
      then
        s2;
  end match;
end strongComponentString;

public function whenEquationString
  input BackendDAE.WhenEquation inWhenEqn;
  input Boolean inStart;
  output String outString;
protected
  String conditionStr, whenStmtStr, elseWhenStr;
  DAE.Exp cond;
  BackendDAE.WhenEquation weqn;
  Option<BackendDAE.WhenEquation> oweqn;
  list<BackendDAE.WhenOperator> whenStmtLst;
algorithm
  BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst=whenStmtLst, elsewhenPart=oweqn) := inWhenEqn;
  conditionStr := ExpressionDump.printExpStr(cond);
  whenStmtStr := stringDelimitList(List.map(whenStmtLst, dumpWhenOperatorStr), ";\n  ") + ";\n";
  if isSome(oweqn) then
    SOME(weqn) := oweqn;
    elseWhenStr := whenEquationString(weqn, false);
  else
    elseWhenStr := "";
  end if;

  if inStart then
    outString := "when " + conditionStr + " then\n  " + whenStmtStr + elseWhenStr + "end when;";
  else
    outString := "elsewhen " + conditionStr + " then\n  " + whenStmtStr + elseWhenStr;
  end if;
end whenEquationString;

public function equationString "Helper function to e.g. dump."
  input BackendDAE.Equation inEquation;
  output String outString;
algorithm
  outString := matchcontinue (inEquation)
    local
      String s1,s2,s3,s4,res;
      DAE.Exp e1,e2,e,cond, start, stop, iter;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
      BackendDAE.EquationAttributes attr;
      DAE.Algorithm alg;
      DAE.ElementSource source;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse,eqns;
      list<BackendDAE.WhenOperator> whenStmtLst;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2, attr=attr))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," := ",s2});
      then
        res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = weqn))
      equation
        res = whenEquationString(weqn, true);
      then
        res;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e))
      equation
        s1 = ExpressionDump.printExpStr(e);
        res = stringAppendList({s1,"= 0"});
      then
        res;
    case (BackendDAE.ALGORITHM(alg = alg,source = source))
      equation
        res = DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
      then
        res;
    case (BackendDAE.IF_EQUATION(conditions=e1::expl, eqnstrue=eqns::eqnstrue, eqnsfalse=eqnsfalse))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = stringDelimitList(List.map(eqns,equationString),"\n  ");
        s3 = stringAppendList({"if ",s1," then\n  ",s2});
        res = ifequationString(expl,eqnstrue,eqnsfalse,s3);
      then
        res;
    case (BackendDAE.FOR_EQUATION(iter=iter, start=start, stop=stop, left=e1, right=e2))
      equation
        s1 = ExpressionDump.printExpStr(iter) + " in " + ExpressionDump.printExpStr(start) + " : " + ExpressionDump.printExpStr(stop);
        s2 = ExpressionDump.printExpStr(e1) + "=" + ExpressionDump.printExpStr(e2);
        res = stringAppendList({"for ",s1," loop \n    ",s2, "; end for; "});
      then
        res;
  end matchcontinue;
end equationString;

protected function zeroCrossingString "Dumps a zerocrossing into a string, for debugging purposes."
  input BackendDAE.ZeroCrossing inZeroCrossing;
  output String outString;
algorithm
  outString:= match(inZeroCrossing)
    local
      list<String> eq_s_list;
      String eq_s,str,str2,str_index;
      DAE.Exp e;
      Integer index_;
      list<Integer> eq;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.RELATION(index=index_),occurEquLst = eq) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str_index=intString(index_);
      str2 = stringAppendList({str," with index = ",str_index," in equations [",eq_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.LBINARY(),occurEquLst = eq) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.LUNARY(),occurEquLst = eq) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.CALL(path = Absyn.IDENT()),occurEquLst = eq) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"]"});
    then str2;

    else "";
  end match;
end zeroCrossingString;

protected function timeEventString
  input BackendDAE.TimeEvent inTimeEvent;
  output String outString;
algorithm
  outString := match(inTimeEvent)
    case BackendDAE.SIMPLE_TIME_EVENT()
    then "SIMPLE_TIME_EVENT";

    case BackendDAE.SAMPLE_TIME_EVENT()
    then intString(inTimeEvent.index) + ": sample(" + ExpressionDump.printExpStr(inTimeEvent.startExp) + ", " + ExpressionDump.printExpStr(inTimeEvent.intervalExp) + ")";

    else "unknown time event";
  end match;
end timeEventString;


public function componentRef_DIVISION_String
  input DAE.ComponentRef inCref;
  input Integer dummy;
  output String outString;
algorithm
  outString := matchcontinue(inCref,dummy)
    local
      DAE.ComponentRef c;
      String sc;
    case(DAE.CREF_QUAL(ident="$DER",componentRef=c),_)
      equation
        sc = ComponentReference.printComponentRefStr(c);
        sc = "der(" + sc + ")";
      then
        sc;
    case(c,_)
      equation
        sc = ComponentReference.printComponentRefStr(c);
      then
        sc;
  end matchcontinue;
end componentRef_DIVISION_String;

// =============================================================================
// section for all debug* functions
//
// description: ???
// =============================================================================

public function debugStrCrefLstStr
  input String a;
  input list<DAE.ComponentRef> b;
  input String c;
  input String d;
algorithm
  print(a);
  debuglst(b,ComponentReference.printComponentRefStr,c,d);
end debugStrCrefLstStr;

public function debugCrefStr
  input DAE.ComponentRef a;
  input String b;
algorithm
  print(ComponentReference.printComponentRefStr(a) + b);
end debugCrefStr;

public function debugStrIntStr
  input String a;
  input Integer b;
  input String c;
algorithm
  print(a + intString(b) + c);
end debugStrIntStr;

public function debugStrIntStrIntStr
  input String a;
  input Integer b;
  input String c;
  input Integer d;
  input String e;
algorithm
  print(a + intString(b) + c + intString(d) + e);
end debugStrIntStrIntStr;

public function debugCrefStrIntStr
  input DAE.ComponentRef a;
  input String b;
  input Integer c;
  input String d;
algorithm
  print(ComponentReference.printComponentRefStr(a) + b + intString(c) + d);
end debugCrefStrIntStr;

public function debugStrCrefStr
  input String a;
  input DAE.ComponentRef b;
  input String c;
algorithm
  print(a +ComponentReference.printComponentRefStr(b) + c);
end debugStrCrefStr;

public function debugStrCrefStrIntStr
  input String a;
  input DAE.ComponentRef b;
  input String c;
  input Integer d;
  input String e;
algorithm
  print(a + ComponentReference.printComponentRefStr(b) + c + intString(d) + e);
end debugStrCrefStrIntStr;

public function debugStrCrefStrRealStrRealStrRealStr
  input String a;
  input DAE.ComponentRef b;
  input String c;
  input Real d;
  input String e;
  input Real f;
  input String g;
  input Real h;
  input String i;
algorithm
  print(a + ComponentReference.printComponentRefStr(b) + c + realString(d) + e + realString(f) + g + realString(h) + i);
end debugStrCrefStrRealStrRealStrRealStr;

public function debugStrRealStrRealStrRealStrRealStr
  input String a;
  input Real b;
  input String c;
  input Real d;
  input String e;
  input Real f;
  input String g;
  input Real h;
  input String i;
algorithm
  print(a + realString(b) + c + realString(d) + e + realString(f) + g + realString(h) + i);
end debugStrRealStrRealStrRealStrRealStr;

public function debugStrCrefStrExpStr
  input String a;
  input DAE.ComponentRef b;
  input String c;
  input DAE.Exp d;
  input String e;
algorithm
  print(a + ComponentReference.printComponentRefStr(b) + c + ExpressionDump.printExpStr(d) + e);
end debugStrCrefStrExpStr;

public function debugStrCrefStrCrefStr
  input String a;
  input DAE.ComponentRef b;
  input String c;
  input DAE.ComponentRef d;
  input String e;
algorithm
  print(a + ComponentReference.printComponentRefStr(b) + c + ComponentReference.printComponentRefStr(d) + e);
end debugStrCrefStrCrefStr;

public function debugExpStr
  input DAE.Exp a;
  input String b;
algorithm
  print(ExpressionDump.printExpStr(a) + b);
end debugExpStr;

public function debugStrExpStr
  input String a;
  input DAE.Exp b;
  input String c;
algorithm
  print(a + ExpressionDump.printExpStr(b) + c);
end debugStrExpStr;

public function debugStrExpLstStr
  input String a;
  input list<DAE.Exp> b;
  input String c, d;
algorithm
  print(a);
  debuglst(b,ExpressionDump.printExpStr,c,d);
end debugStrExpLstStr;

public function debugStrExpStrCrefStr
  input String a;
  input DAE.Exp b;
  input String c;
  input DAE.ComponentRef d;
  input String e;
algorithm
  print(a + ExpressionDump.printExpStr(b) + c + ComponentReference.printComponentRefStr(d) + e);
end debugStrExpStrCrefStr;

public function debugStrExpStrExpStr
  input String a;
  input DAE.Exp b;
  input String c;
  input DAE.Exp d;
  input String e;
algorithm
  print(a + ExpressionDump.printExpStr(b) + c + ExpressionDump.printExpStr(d) + e);
end debugStrExpStrExpStr;

public function debugExpStrExpStrExpStr
  input DAE.Exp a;
  input String b;
  input DAE.Exp c;
  input String d;
  input DAE.Exp e;
  input String f;
algorithm
  print(ExpressionDump.printExpStr(a) + b + ExpressionDump.printExpStr(c) + d + ExpressionDump.printExpStr(e) + f);
end debugExpStrExpStrExpStr;

public function debugStrExpStrExpStrExpStr
  input String a;
  input DAE.Exp b;
  input String c;
  input DAE.Exp d;
  input String e;
  input DAE.Exp f;
  input String g;
algorithm
  print(a + ExpressionDump.printExpStr(b) + c + ExpressionDump.printExpStr(d) + e + ExpressionDump.printExpStr(f) + g);
end debugStrExpStrExpStrExpStr;

public function debugStrEqnStr
  input String a;
  input BackendDAE.Equation b;
  input String c;
algorithm
  print(a + equationString(b) + c);
end debugStrEqnStr;

public function debugStrEqnStrEqnStr
  input String a;
  input BackendDAE.Equation b;
  input String c;
  input BackendDAE.Equation d;
  input String e;
algorithm
  print(a + equationString(b) + c + equationString(d) + e);
end debugStrEqnStrEqnStr;

public function debuglst
  input list<Type_a> lst;
  input FuncTypeType_aToStr f;
  input String c;
  input String se;
  partial function FuncTypeType_aToStr
    input Type_a inTypeA;
    output String outTypeA;
  end FuncTypeType_aToStr;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := match lst
    local
      Type_a a;
      list<Type_a> rest;
    case {}
      equation
        print(se);
      then ();
    case a::{}
      equation
        print(f(a));
        print(se);
      then ();
    case a::rest
      equation
        print(f(a));
        print(c);
        debuglst(rest,f,c,se);
     then ();
  end match;
end debuglst;

// =============================================================================
// unsorted section
//
// These section should be empty. Feel free to sort these functions into one of
// the upper sections.
// =============================================================================

public function printCallFunction2StrDIVISION
"Print the exp of typ DAE.CALL."
  input DAE.Exp inExp;
  input String stringDelimiter;
  input Option<tuple<strongComponentStringRefStrFunc,Type_a>> opcreffunc "tuple of function that print component references and a extra parameter passet throug the function";
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function strongComponentStringRefStrFunc
    input DAE.ComponentRef inComponentRef;
    input Type_a Param;
    output String outString;
  end strongComponentStringRefStrFunc;
algorithm
  outString := matchcontinue (inExp,stringDelimiter,opcreffunc)
    local
      String s,s_1,s_2,fs,argstr;
      Absyn.Path fcn;
      list<DAE.Exp> args;
      DAE.Exp e1,e2;
      DAE.Type  ty;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION"), expLst = {e1,e2,DAE.SCONST(_)}, attr = DAE.CALL_ATTR(ty = ty)), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION_ARRAY_SCALAR"),expLst = {e1,e2,DAE.SCONST(_)}, attr = DAE.CALL_ATTR(ty =ty)), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION_SCALAR_ARRAY"),expLst = {e1,e2,DAE.SCONST(_)}, attr = DAE.CALL_ATTR(ty =ty)), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case (DAE.CALL(path = fcn,expLst = args), _,_)
      equation
        fs = Absyn.pathString(fcn);
        argstr = stringDelimitList(
          List.map3(args, ExpressionDump.printExp2Str, stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION)), ",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
  end matchcontinue;
end printCallFunction2StrDIVISION;

// protected function printVarsStatistics "author: PA
//
//   Prints statistics on variables, etc.
// "
//   input BackendDAE.Variables inVariables1;
//   input BackendDAE.Variables inVariables2;
// algorithm
//   _:=
//   matchcontinue (inVariables1,inVariables2)
//     local
//       String lenstr,bstr;
//       BackendDAE.VariableArray v1,v2;
//       Integer bsize1,n1,bsize2,n2;
//     case (BackendDAE.VARIABLES(varArr = v1,bucketSize = bsize1,numberOfVars = n1),BackendDAE.VARIABLES(varArr = v2,bucketSize = bsize2,numberOfVars = n2))
//       equation
//         print("Variable Statistics\n");
//         print("===================\n");
//         print("Number of variables: ");
//         lenstr = intString(n1);
//         print(lenstr);
//         print("\n");
//         print("Bucket size for variables: ");
//         bstr = intString(bsize1);
//         print(bstr);
//         print("\n");
//         print("Number of known variables: ");
//         lenstr = intString(n2);
//         print(lenstr);
//         print("\n");
//         print("Bucket size for known variables: ");
//         bstr = intString(bsize1);
//         print(bstr);
//         print("\n");
//       then
//         ();
//   end matchcontinue;
// end printVarsStatistics;

public function dumpWhenOperatorStr
"Dumps a WhenOperator into a string, for debugging purposes."
  input BackendDAE.WhenOperator inWhenOperator;
  output String outString;
algorithm
  outString:=
  match (inWhenOperator)
    local
      String scr,se,se1,str;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      Absyn.Path functionName;
      list<DAE.Exp> functionArgs;
    case BackendDAE.ASSIGN(left=cr, right=e)
     equation
      scr = ComponentReference.printComponentRefStr(cr);
      se = ExpressionDump.printExpStr(e);
      str = stringAppendList({scr," := ",se});
     then
      str;
    case BackendDAE.REINIT(stateVar=cr,value=e)
     equation
      scr = ComponentReference.printComponentRefStr(cr);
      se = ExpressionDump.printExpStr(e);
      str = stringAppendList({"reinit(",scr,",",se,")"});
     then
      str;
    case BackendDAE.ASSERT(condition=e,message=e1)
     equation
      se = ExpressionDump.printExpStr(e);
      se1 = ExpressionDump.printExpStr(e1);
      str = stringAppendList({"assert(",se,",",se1,")"});
     then
      str;
    case BackendDAE.TERMINATE(message=e)
     equation
      se = ExpressionDump.printExpStr(e);
      str = stringAppendList({"terminate(",se,")"});
     then
      str;
    case BackendDAE.NORETCALL(exp=e)
      then
        ExpressionDump.printExpStr(e);
  end match;
end dumpWhenOperatorStr;

public function dumpOption
  replaceable type Type_A subtypeof Any;
  input Option<Type_A> inType;
  input printType_A infunc;
  partial function printType_A
    input Type_A inType;
  end printType_A;
algorithm
  _ :=
  match(inType,infunc)
    local
      Type_A a;
    case (SOME(a), _) equation infunc(a); then();
    else ();
  end match;
end dumpOption;

public function dumpAlgorithms "Help function to dump, prints algorithms to stdout"
  input list<DAE.Algorithm> ialgs;
  input Integer indx;
algorithm
  _ := match(ialgs,indx)
    local
      list<DAE.Statement> stmts;
      IOStream.IOStream myStream;
      String is;
      list<DAE.Algorithm> algs;

    case({},_) then ();
    case(DAE.ALGORITHM_STMTS(stmts)::algs,_)
      equation
        is = intString(indx);
        myStream = IOStream.create("", IOStream.LIST());
        myStream = IOStream.append(myStream,stringAppend(is,". "));
        myStream = DAEDump.dumpAlgorithmStream(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource), myStream);
        IOStream.print(myStream, IOStream.stdOutput);
        dumpAlgorithms(algs,indx+1);
    then ();
  end match;
end dumpAlgorithms;

public function dumpConstraints "Help function to dump, prints constraints to stdout"
  input list<DAE.Constraint> ionstrs;
  input Integer indx;
algorithm
  _ := match(ionstrs,indx)
    local
      list<DAE.Exp> exps;
      IOStream.IOStream myStream;
      String is;
      list<DAE.Constraint> constrs;

    case({},_) then ();
    case(DAE.CONSTRAINT_EXPS(exps)::constrs,_)
      equation
        is = intString(indx);
        myStream = IOStream.create("", IOStream.LIST());
        myStream = IOStream.append(myStream,stringAppend(is,". "));
        myStream = DAEDump.dumpConstraintStream({DAE.CONSTRAINT(DAE.CONSTRAINT_EXPS(exps),DAE.emptyElementSource)}, myStream);
        IOStream.print(myStream, IOStream.stdOutput);
        dumpConstraints(constrs,indx+1);
    then ();
  end match;
end dumpConstraints;

public function dumpSparsePatternArray
"function:  dumpSparsePattern
 author: wbraun
 description: function dumps sparse pattern of a Jacobain System."
  input array<list<Integer>> inSparsePatter;
algorithm
  print("Print sparse pattern: " + intString(arrayLength(inSparsePatter)) + "\n");
  dumpSparsePattern2(arrayList(inSparsePatter), 1);
  print("\n");
end dumpSparsePatternArray;

public function dumpSparsePattern
"function:  dumpSparsePattern
 author: wbraun
 description: function dumps sparse pattern of a Jacobain System."
  input list<list<Integer>> inSparsePatter;
algorithm
  print("Print sparse pattern: " + intString(listLength(inSparsePatter)) + "\n");
  dumpSparsePattern2(inSparsePatter, 1);
  print("\n");
end dumpSparsePattern;

public function dumpSparsePattern2
"function:  dumpSparsePattern
 author: wbraun
 description: help function to dumpSparsePattern."
  input list<list<Integer>> inSparsePatter;
  input Integer inInteger;
algorithm
  _ := match(inSparsePatter, inInteger)
  local
    list<list<Integer>> rest;
    list<Integer> elem;
    String sparsepatternStr;
    case({},_) then ();
    case(elem::rest,_)
      equation
      sparsepatternStr = List.toString(elem, intString,"Row[" + intString(inInteger) + "] = ","{",";","}",true);
      print(sparsepatternStr + "\n");
      dumpSparsePattern2(rest,inInteger+1);
    then ();
  end match;
end dumpSparsePattern2;

public function dumpJacobianStr
"Dumps the sparse jacobian.
  Uses the variables to determine size of Jacobian matrix."
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output String outString;
algorithm
  outString:=
  match (inTplIntegerIntegerEquationLstOption)
    local
      list<String> res;
      String res_1;
      list<tuple<Integer, Integer, BackendDAE.Equation>> eqns;
    case (SOME(eqns))
      equation
        res = dumpJacobianStr2(eqns);
        res_1 = stringDelimitList(res, ",\n");
      then
        res_1;
    case (NONE()) then "No analytic jacobian available\n";
  end match;
end dumpJacobianStr;

protected function dumpJacobianStr2
"Helper function to dumpJacobianStr"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (inTplIntegerIntegerEquationLst)
    local
      String estr,rowstr,colstr,str;
      list<String> strs;
      Integer row,col;
      DAE.Exp e;
      list<tuple<Integer, Integer, BackendDAE.Equation>> eqns;
    case ({}) then {};
    case (((row,col,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        estr = ExpressionDump.printExpStr(e);
        rowstr = intString(row);
        colstr = intString(col);
        str = stringAppendList({"{",rowstr,",",colstr,"}:",estr});
        strs = dumpJacobianStr2(eqns);
      then
        (str :: strs);
  end match;
end dumpJacobianStr2;

public function jacobianTypeStr "author: PA
  Returns the jacobian type as a string, used for debugging."
  input BackendDAE.JacobianType inJacobianType;
  output String outString;
algorithm
  outString := match (inJacobianType)
    case BackendDAE.JAC_CONSTANT() then "Jacobian Constant";
    case BackendDAE.JAC_LINEAR() then "Jacobian Linear";
    case BackendDAE.JAC_NONLINEAR() then "Jacobian Nonlinear";
    case BackendDAE.JAC_GENERIC() then "Generic Jacobian via directional derivatives";
    case BackendDAE.JAC_NO_ANALYTIC() then "No analytic jacobian";
  end match;
end jacobianTypeStr;

public function jacobianString"dumps a string representation of a jacobian.
author: Waurich TUD 2014-10"
  input BackendDAE.Jacobian jacIn;
  output String sOut;
algorithm
  sOut := match(jacIn)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.FullJacobian fJac;
      BackendDAE.SymbolicJacobian sJac;
      BackendDAE.SparsePattern sparsePattern;
      BackendDAE.SparseColoring coloring;
      String s;
  case(BackendDAE.FULL_JACOBIAN(jacobian=fJac))
    equation
      s = "FULL JACOBIAN:\n";
      s = s + dumpJacobianStr(fJac);
    then s;
  case(BackendDAE.GENERIC_JACOBIAN(jacobian=sJac))
    equation
      ((dae,_,_,_,_)) = sJac;
      s = "GENERIC JACOBIAN:\n";
      dumpBackendDAE(dae,"Directional Derivatives System");
    then s;
  case(BackendDAE.EMPTY_JACOBIAN())
    equation
      s = "EMPTY JACOBIAN:\n";
    then s;
  end match;
end jacobianString;

public function dumpEqnsStr
"Helper function to dump."
  input list<BackendDAE.Equation> eqns;
  output String str;
algorithm
  str := stringDelimitList(dumpEqnsStr2(eqns, 1, {}),"\n");
end dumpEqnsStr;

protected function dumpEqnsStr2
"Helper function to dump_eqns"
  input list<BackendDAE.Equation> inEquationLst;
  input Integer inInteger;
  input list<String> inAcc;
  output list<String> strs;
algorithm
  strs := match (inEquationLst,inInteger,inAcc)
    local
      String es,is,str;
      Integer index_1,index;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      list<String> acc;

    case ({},_,acc) then listReverse(acc);
    case ((eqn :: eqns),index,acc)
      equation
        es = equationString(eqn);
        is = intString(index);
        str = (is + " : ") + es;
        index_1 = index + 1;
        acc = str::acc;
      then dumpEqnsStr2(eqns, index_1, acc);
  end match;
end dumpEqnsStr2;

protected function ifequationString
  input list<DAE.Exp> conditions;
  input list<list<BackendDAE.Equation>> eqnstrue;
  input list<BackendDAE.Equation> eqnsfalse;
  input String iString;
  output String outString;
algorithm
  outString := match(conditions,eqnstrue,eqnsfalse,iString)
    local
      list<list<BackendDAE.Equation>> eqnslst;
      list<BackendDAE.Equation> eqns;
      String seqns,s,se;
      DAE.Exp e;
      list<DAE.Exp> elst;
    case ({},_,{},_)
      equation
        s = stringAppendList({iString,"\nend if"});
      then
        s;
    case ({},_,_,_)
      equation
        seqns = stringDelimitList(List.map(eqnsfalse,equationString),"\n  ");
        s = stringAppendList({iString,"\nelse\n  ",seqns,"\nend if"});
      then
        s;
    case(e::elst,eqns::eqnslst,_,_)
      equation
        se = ExpressionDump.printExpStr(e);
        seqns = stringDelimitList(List.map(eqns,equationString),"\n  ");
        s = stringAppendList({iString,"\nelseif ",se," then\n  ",seqns});
      then
        ifequationString(elst,eqnslst,eqnsfalse,s);
  end match;
end ifequationString;

public function varString "Helper function to printVarList."
  input BackendDAE.Var inVar;
  output String outStr;
protected
  list<Absyn.Path> paths;
  list<String> paths_lst;
  String unreplaceableStr;
  String dimensions;
algorithm
  paths := ElementSource.getElementSourceTypes(inVar.source);
  paths_lst := list(Absyn.pathString(p) for p in paths);
  unreplaceableStr := if inVar.unreplaceable then " unreplaceable" else "";
  dimensions := ExpressionDump.dimensionsString(inVar.arryDim);
  dimensions := if dimensions <> "" then " [" + dimensions + "]" else "";
  outStr := DAEDump.dumpDirectionStr(inVar.varDirection) + ComponentReference.printComponentRefStr(inVar.varName) + ":"
            + kindString(inVar.varKind) + "(" + connectorTypeString(inVar.connectorType) + attributesString(inVar.values)
            + ") " + optExpressionString(inVar.bindExp, "") + DAEDump.dumpCommentAnnotationStr(inVar.comment)
            + stringDelimitList(paths_lst, ", ") + " type: " + DAEDump.daeTypeStr(inVar.varType) + dimensions + unreplaceableStr;
end varString;

public function varStringShort "prints the cref name of the var only"
  input BackendDAE.Var inVar;
  output String outStr;
algorithm
  outStr := ComponentReference.printComponentRefStr(inVar.varName);
end varStringShort;

public function dumpKind
"Helper function to dump."
  input BackendDAE.VarKind inVarKind;
algorithm
  print(kindString(inVarKind));
end dumpKind;

public function kindString
"Helper function to dump."
  input BackendDAE.VarKind inVarKind;
  output String kindStr;
algorithm
  kindStr:=
  match (inVarKind)
    local
      Absyn.Path path;
      Integer i;
      DAE.ComponentRef dcr;
    case BackendDAE.VARIABLE()    then "VARIABLE";
    case BackendDAE.STATE(index=i,derName=NONE())      then "STATE(" + intString(i) + ")";
    case BackendDAE.STATE(index=i,derName=SOME(dcr))      then "STATE(" + intString(i) + "," + ComponentReference.printComponentRefStr(dcr) + ")";
    case BackendDAE.STATE_DER()   then "STATE_DER";
    case BackendDAE.DUMMY_DER()   then "DUMMY_DER";
    case BackendDAE.DUMMY_STATE() then "DUMMY_STATE";
    case BackendDAE.CLOCKED_STATE()  then "CLOCKED_STATE";
    case BackendDAE.DISCRETE()    then "DISCRETE";
    case BackendDAE.PARAM()       then "PARAM";
    case BackendDAE.CONST()       then "CONST";
    case BackendDAE.EXTOBJ(path)  then "EXTOBJ: " + Absyn.pathString(path);
    case BackendDAE.JAC_VAR()     then "JACOBIAN_VAR";
    case BackendDAE.JAC_DIFF_VAR()then "JACOBIAN_DIFF_VAR";
    case BackendDAE.OPT_CONSTR()  then "OPT_CONSTR";
    case BackendDAE.OPT_FCONSTR()  then "OPT_FCONSTR";
    case BackendDAE.OPT_INPUT_WITH_DER()  then "OPT_INPUT_WITH_DER";
    case BackendDAE.OPT_INPUT_DER()  then "OPT_INPUT_DER";
    case BackendDAE.OPT_TGRID()  then "OPT_TGRID";
    case BackendDAE.OPT_LOOP_INPUT()  then "OPT_LOOP_INPUT";
    case BackendDAE.ALG_STATE()  then "ALG_STATE";
  end match;
end kindString;

public function dumpConnectorType
  input DAE.ConnectorType inConnectorType;
algorithm
  print(connectorTypeString(inConnectorType));
end dumpConnectorType;

public function connectorTypeString
  input DAE.ConnectorType inConnectorType;
  output String connectorTypeStr;
algorithm
  connectorTypeStr := match(inConnectorType)
    case DAE.FLOW() then "flow=true ";
    case DAE.POTENTIAL() then "flow=false ";
    else "";
  end match;
end connectorTypeString;

public function dumpAttributes
"Helper function to dump."
  input Option<DAE.VariableAttributes> inAttr;
algorithm
  _:=
  match (inAttr)
    local
       Option<DAE.Exp> min,max,start,fixed,nominal;
       Option<Boolean> isProtected,finalPrefix;
       Option<DAE.Distribution> dist;
       Option<DAE.StateSelect> stateSelectOption;
    case NONE() then ();
    case SOME(DAE.VAR_ATTR_REAL(min=NONE(),max=NONE(),start=NONE(),fixed=NONE(),nominal=NONE(),stateSelectOption=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_REAL(min=min,max=max,start=start,fixed=fixed,nominal=nominal,stateSelectOption=stateSelectOption,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist))
      equation
        dumpOptExpression(min,"min");
        dumpOptExpression(max,"max");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptExpression(nominal,"nominal");
        dumpOptStateSelection(stateSelectOption);
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        dumpOptDistribution(dist);
     then ();
    case SOME(DAE.VAR_ATTR_INT(min=NONE(),max=NONE(),start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_INT(min=min,max=max,start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist))
      equation
        dumpOptExpression(min,"min");
        dumpOptExpression(max,"max");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        dumpOptDistribution(dist);
     then ();
    case SOME(DAE.VAR_ATTR_BOOL(start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
      then ();
    case SOME(DAE.VAR_ATTR_BOOL(start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
     then ();
    case SOME(DAE.VAR_ATTR_STRING(start=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_STRING(start=start,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        dumpOptExpression(start,"start");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
     then ();
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=NONE(),max=NONE(),start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=min,max=max,start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        dumpOptExpression(min,"min");
        dumpOptExpression(max,"max");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
     then ();
    else ();
  end match;
end dumpAttributes;

protected function dumpOptDistribution "

"
  input Option<DAE.Distribution> dist;
algorithm
  _ := match(dist)
  local
    DAE.Exp e1,e2,e3;

    case(NONE()) then ();
    case(SOME(DAE.DISTRIBUTION(e1,e2,e3))) equation
      print("distribution = Distribution("+ExpressionDump.printExpStr(e1)+", "
      +ExpressionDump.printExpStr(e2)+", "
      +ExpressionDump.printExpStr(e3)+")");
    then ();
  end match;
end dumpOptDistribution;


protected function dumpOptStateSelection "

"
  input Option<DAE.StateSelect> ss;
algorithm
  _ := match(ss)
  local
    case(SOME(DAE.NEVER())) equation print("stateSelect=StateSelect.never "); then ();
    case(SOME(DAE.AVOID())) equation print("stateSelect=StateSelect.avoid "); then ();
    case(SOME(DAE.DEFAULT())) then ();
    case(SOME(DAE.PREFER())) equation print("stateSelect=StateSelect.prefer "); then ();
    case(SOME(DAE.ALWAYS())) equation print("stateSelect=StateSelect.alwas "); then ();
    else ();
  end match;
end dumpOptStateSelection;

protected function dumpOptExpression
"Helper function to dump."
  input Option<DAE.Exp> inExp;
  input String inString;
algorithm
  _:=
  match (inExp,inString)
    local
       DAE.Exp e;
       String s,se,str;
    case (SOME(e),s)
      equation
         se = ExpressionDump.printExpStr(e);
         str = stringAppendList({s," = ",se," "});
         print(str);
     then ();
    else ();
  end match;
end dumpOptExpression;

protected function dumpOptBoolean
"Helper function to dump."
  input Option<Boolean> inExp;
  input String inString;
algorithm
  _:=
  match (inExp,inString)
    local
       String s,str;
    case (SOME(true),s)
      equation
         str = stringAppendList({s," = true "});
         print(str);
     then ();
    else ();
  end match;
end dumpOptBoolean;

public function attributesString
"Helper function to dump."
  input Option<DAE.VariableAttributes> inAttr;
  output String outString;
algorithm
  outString :=
  match (inAttr)
    local
       Option<DAE.Exp> min,max,start,fixed,nominal,unit;
       Option<Boolean> isProtected,finalPrefix;
       Option<DAE.Distribution> dist;
       Option<DAE.StateSelect> stateSelectOption;
       Option<DAE.Uncertainty> uncertainopt;
       String str;
    case NONE() then "";
    case SOME(DAE.VAR_ATTR_REAL(min=NONE(),max=NONE(),start=NONE(),unit=NONE(),fixed=NONE(),nominal=NONE(),stateSelectOption=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE(),uncertainOption=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_REAL(min=min,max=max,start=start,unit=unit,fixed=fixed,nominal=nominal,stateSelectOption=stateSelectOption,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist,uncertainOption=uncertainopt))
      equation
        str = optExpressionString(min,"min") + optExpressionString(max,"max") + optExpressionString(start,"start") + optExpressionString(unit,"unit") + optExpressionString(fixed,"fixed")
             + optExpressionString(nominal,"nominal") + optStateSelectionString(stateSelectOption) + optBooleanString(isProtected,"protected")
             + optBooleanString(finalPrefix,"final") + optDistributionString(dist) + optUncertainty(uncertainopt);
     then str;
    case SOME(DAE.VAR_ATTR_INT(min=NONE(),max=NONE(),start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE(),uncertainOption=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_INT(min=min,max=max,start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix,uncertainOption=uncertainopt))
      equation
        str = optExpressionString(min,"min") + optExpressionString(max,"max") + optExpressionString(start,"start") + optExpressionString(fixed,"fixed")
             + optBooleanString(isProtected,"protected") + optBooleanString(finalPrefix,"final") + optUncertainty(uncertainopt);
     then str;
    case SOME(DAE.VAR_ATTR_BOOL(start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
      then "";
    case SOME(DAE.VAR_ATTR_BOOL(start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        str = optExpressionString(start,"start") + optExpressionString(fixed,"fixed") + optBooleanString(isProtected,"protected") + optBooleanString(finalPrefix,"final");
     then str;
    case SOME(DAE.VAR_ATTR_STRING(start=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_STRING(start=start,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        str = optExpressionString(start,"start") + optBooleanString(isProtected,"protected") + optBooleanString(finalPrefix,"final");
     then str;
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=NONE(),max=NONE(),start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=min,max=max,start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        str = optExpressionString(min,"min") + optExpressionString(max,"max") + optExpressionString(start,"start") + optExpressionString(fixed,"fixed")
             + optBooleanString(isProtected,"protected") + optBooleanString(finalPrefix,"final");
     then str;
    else "";
  end match;
end attributesString;

protected function optDistributionString
"funcion optDistributionString"
  input Option<DAE.Distribution> dist;
  output String outString;
algorithm
  outString := match(dist)
    local
      DAE.Exp e1,e2,e3;
      String str;
    case(NONE()) then "";
    case(SOME(DAE.DISTRIBUTION(e1,e2,e3)))
      equation
        str =  "distribution = Distribution(" + ExpressionDump.printExpStr(e1) + ", "
             + ExpressionDump.printExpStr(e2) + ", "
             + ExpressionDump.printExpStr(e3) + ")";
    then str;
  end match;
end optDistributionString;

protected function optUncertainty
  input Option<DAE.Uncertainty> uncertainty;
  output String outString;
algorithm
  outString := match(uncertainty)
    case(NONE()) then "";
    case(SOME(DAE.GIVEN())) then "uncertain=Uncertainty.given";
    case(SOME(DAE.SOUGHT())) then "uncertain=Uncertainty.sought";
    case(SOME(DAE.REFINE())) then "uncertain=Uncertainty.refine";
  end match;
end optUncertainty;

protected function optStateSelectionString
  input Option<DAE.StateSelect> ss;
  output String outString;
algorithm
  outString:= match(ss)
    case(SOME(DAE.NEVER())) then  "stateSelect=StateSelect.never ";
    case(SOME(DAE.AVOID())) then  "stateSelect=StateSelect.avoid ";
    case(SOME(DAE.DEFAULT())) then "";
    case(SOME(DAE.PREFER())) then  "stateSelect=StateSelect.prefer ";
    case(SOME(DAE.ALWAYS())) then  "stateSelect=StateSelect.always ";
    else "";
  end match;
end optStateSelectionString;

public function partitionKindString
  input BackendDAE.BaseClockPartitionKind inPartitionKind;
  output String outString;
algorithm
  outString := match(inPartitionKind)
    local
      Integer idx;
    case BackendDAE.CLOCKED_PARTITION(idx) then "clocked partition(" + intString(idx) + ")";
    case BackendDAE.CONTINUOUS_TIME_PARTITION() then "continuous time partition";
    case BackendDAE.UNSPECIFIED_PARTITION() then "unspecified partition";
    case BackendDAE.UNKNOWN_PARTITION() then "unknown partition";
    else equation
      Error.addInternalError("function partitionKindString failed", sourceInfo());
    then fail();
  end match;
end partitionKindString;

protected function equationAttrString
  input BackendDAE.EquationAttributes inEqAttr;
  output String outString;
protected
  BackendDAE.EquationKind kind;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(kind=kind) := inEqAttr;
  outString := "[" + equationKindString(kind);
  outString := outString + "]";
end equationAttrString;

protected function equationKindString
  input BackendDAE.EquationKind inEqKind;
  output String outString;
algorithm
  outString := match(inEqKind)
    local
     Integer i;
     DAE.ComponentRef cr;
    case BackendDAE.BINDING_EQUATION() then "binding";
    case BackendDAE.DYNAMIC_EQUATION() then "dynamic";
    case BackendDAE.INITIAL_EQUATION() then "initial";
    case BackendDAE.UNKNOWN_EQUATION_KIND() then "unknown";
    case BackendDAE.CLOCKED_EQUATION(i)
      equation
        cr = DAE.CREF_IDENT(BackendDAE.WHENCLK_PRREFIX + intString(i), DAE.T_CLOCK_DEFAULT, {});
      then "clocked(" + DAE.ComponentReference.printComponentRefStr(cr) + ")";
    else
      equation
        Error.addInternalError("function equationKindString failed", sourceInfo());
      then fail();
  end match;
end equationKindString;

protected function optExpressionString
"Helper function to dump."
  input Option<DAE.Exp> inExp;
  input String inString;
  output String outString;
algorithm
  outString:=
  match (inExp,inString)
    local
       DAE.Exp e;
       String se,str;
    case (SOME(e),_)
      equation
         se = ExpressionDump.printExpStr(e);
         str = inString + " = " + se + " ";
     then str;
    else "";
  end match;
end optExpressionString;

protected function optBooleanString
"Helper function to dump."
  input Option<Boolean> inExp;
  input String inString;
  output String outString;
algorithm
  outString :=
  match (inExp,inString)
    local
       String str;
    case (SOME(true),_)
      equation
         str = inString + " = true ";
     then str;
    else "";
  end match;
end optBooleanString;

public function dumpIncidenceMatrix "Prints incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
protected
  Integer rowIndex=0;
algorithm
  print("\nIncidence Matrix (row: equation)\n" + UNDERLINE + "\n");
  print("number of rows: " + intString(arrayLength(m)));

  for row in m loop
    rowIndex := rowIndex+1;
    print("\n" + intString(rowIndex) + ":");
    for i in row loop
      print(" " + intString(i));
    end for;
  end for;
  print("\n");
end dumpIncidenceMatrix;

public function dumpIncidenceMatrixT "Prints the transposed incidence matrix on stdout."
  input BackendDAE.IncidenceMatrixT mT;
protected
  Integer rowIndex=0;
algorithm
  print("\nTransposed Incidence Matrix (row: variable)\n" + UNDERLINE + "\n");
  print("number of rows: " + intString(arrayLength(mT)));

  for row in mT loop
    rowIndex := rowIndex+1;
    print("\n" + intString(rowIndex) + ":");
    for i in row loop
      print(" " + intString(i));
    end for;
  end for;
  print("\n");
end dumpIncidenceMatrixT;

public function dumpIncidenceRow
"author: PA
  Helper function to dumpIncidenceMatrix2."
  input list<Integer> inIntegerLst;
algorithm
  _ := match (inIntegerLst)
    local
      String s;
      Integer x;
      list<Integer> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        s = intString(x);
        print(s);
        print(" ");
        dumpIncidenceRow(xs);
      then
        ();
  end match;
end dumpIncidenceRow;

public function dumpAdjacencyMatrixEnhanced
"author: Frenkel TUD 2012-05
  Prints the incidence matrix on stdout."
  input BackendDAE.AdjacencyMatrixEnhanced m;
protected
  Integer mlen;
  String mlen_str;
  list<BackendDAE.AdjacencyMatrixElementEnhanced> m_1;
algorithm
  print("Adjacency Matrix Enhanced (row == equation)\n");
  print("====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpAdjacencyMatrixEnhanced2(m_1,1);
end dumpAdjacencyMatrixEnhanced;

public function dumpAdjacencyMatrixTEnhanced
"author: Frenkel TUD 2012-05
  Prints the transposed incidence matrix on stdout."
  input BackendDAE.AdjacencyMatrixTEnhanced m;
protected
  Integer mlen;
  String mlen_str;
  list<BackendDAE.AdjacencyMatrixElementEnhanced> m_1;
algorithm
  print("Transpose Adjacency Matrix Enhanced (row == var)\n");
  print("=====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpAdjacencyMatrixEnhanced2(m_1,1);
end dumpAdjacencyMatrixTEnhanced;

protected function dumpAdjacencyMatrixEnhanced2
"author: Frenkel TUD 2012-05
  Helper function to dumpAdjacencyMatrixEnhanced (+T)."
  input list<BackendDAE.AdjacencyMatrixElementEnhanced> inRows;
  input Integer rowIndex;
algorithm
  _ := match (inRows,rowIndex)
    local
      BackendDAE.AdjacencyMatrixElementEnhanced row;
      list<BackendDAE.AdjacencyMatrixElementEnhanced> rows;
    case ({},_) then ();
    case ((row :: rows),_)
      equation
        print(intString(rowIndex));print(":");
        dumpAdjacencyRowEnhanced(row);
        dumpAdjacencyMatrixEnhanced2(rows,rowIndex+1);
      then
        ();
  end match;
end dumpAdjacencyMatrixEnhanced2;

public function dumpAdjacencyRowEnhanced
"author: Frenkel TUD 2012-05
  Helper function to dumpAdjacencyMatrixEnhanced2."
  input BackendDAE.AdjacencyMatrixElementEnhanced inRow;
algorithm
  _ := match (inRow)
    local
      String s,s1,s2;
      Integer x;
      BackendDAE.Solvability solva;
      BackendDAE.AdjacencyMatrixElementEnhanced xs;
      BackendDAE.Constraints cons;
    case ({})
      equation
        print("\n");
      then
        ();
    case (((x,solva,{}) :: xs))
      equation
        s = intString(x);
        s1 = dumpSolvability(solva);
        print("(" + s + "," + s1 + ")");
        print(" ");
        dumpAdjacencyRowEnhanced(xs);
      then
        ();
    case (((x,solva,cons) :: xs))
      equation
        s = intString(x);
        s1 = dumpSolvability(solva);
        s2 = ExpressionDump.constraintDTlistToString(cons,",");
        print("(" + s + "," + s1 + s2 +")");
        print(" ");
        dumpAdjacencyRowEnhanced(xs);
      then
        ();
  end match;
end dumpAdjacencyRowEnhanced;

public function dumpSolvability
"author: Frenkel TUD 2012-05,
  returns a string for the Solvability"
  input BackendDAE.Solvability solva;
  output String s;
algorithm
  s := match(solva)
    local Boolean b;
    case BackendDAE.SOLVABILITY_SOLVED() then "solved";
    case BackendDAE.SOLVABILITY_CONSTONE() then "constone";
    case BackendDAE.SOLVABILITY_CONST(b=b) then "const(" + boolString(b) + ")";
    case BackendDAE.SOLVABILITY_PARAMETER(b=b) then "param(" + boolString(b) + ")";
    case BackendDAE.SOLVABILITY_LINEAR(b=b) then "variable(" + boolString(b) + ")";
    case BackendDAE.SOLVABILITY_NONLINEAR() then "nonlinear";
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then "unsolvable";
    case BackendDAE.SOLVABILITY_SOLVABLE() then "solvable";
  end match;
end dumpSolvability;

public function dumpFullMatching
  input BackendDAE.Matching inMatch;
algorithm
  _:= match(inMatch)
    local
      array<Integer> ass1;
      BackendDAE.StrongComponents comps;

    case (BackendDAE.NO_MATCHING()) equation
      print("no matching\n");
    then ();

    case (BackendDAE.MATCHING(ass1, _, comps)) equation
      dumpMatching(ass1);
      print("\n\n");
      dumpComponents(comps);
    then ();
  end match;
end dumpFullMatching;

public function dumpMatching "author: PA
  prints the matching information on stdout."
  input array<Integer> v;
protected
  Integer len;
  String len_str;
algorithm
  print("Matching\n");
  print(UNDERLINE + "\n");
  len := arrayLength(v);
  len_str := intString(len);
  print(len_str);
  print(" variables and equations\n");
  dumpMatching2(v, 1, len);
end dumpMatching;

protected function dumpMatching2 "author: PA
  Helper function to dumpMatching."
  input array<Integer> v;
  input Integer i;
  input Integer len;
algorithm
  _ := matchcontinue (v,i,len)
    local
      Integer eqn;
      String s,s2;
    case (_,_,_)
      equation
        true = intLe(i,len);
        s = intString(i);
        eqn = v[i];
        s2 = intString(eqn);
        print("var " + s + " is solved in eqn " + s2 + "\n");
        dumpMatching2(v, i+1, len);
      then
        ();
    else
      then
        ();
  end matchcontinue;
end dumpMatching2;

public function dumpMatchingVars "Prints matching information on stdout."
  input array<Integer> ass1 "eqn := ass1[var]";
protected
  Integer varIndex=0;
algorithm
  print("\nMatching\n" + UNDERLINE + "\n");
  print(intString(arrayLength(ass1)) + " variables\n");

  for i in ass1 loop
    varIndex := varIndex+1;
    print("var " + intString(varIndex) + " is solved in eqn " + intString(i) + "\n");
  end for;
end dumpMatchingVars;

public function dumpMatchingEqns "Prints matching information on stdout."
  input array<Integer> ass2 "var := ass2[eqn]";
protected
  Integer eqnIndex=0;
algorithm
  print("\nMatching\n" + UNDERLINE + "\n");
  print(intString(arrayLength(ass2)) + " equations\n");

  for i in ass2 loop
    eqnIndex := eqnIndex+1;
    print("eqn " + intString(eqnIndex) + " is solved for var " + intString(i) + "\n");
  end for;
end dumpMatchingEqns;

public function dumpMarkedEqns
"Dumps only the equations given as list of indexes to a string."
  input BackendDAE.EqSystem syst;
  input list<Integer> inIntegerLst;
  output String outString;
protected
  BackendDAE.EquationArray eqns;
  list<Integer> sortedeqns;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs = eqns) := syst;
  outString := List.fold1(inIntegerLst,dumpMarkedEqns1,eqns,"");
end dumpMarkedEqns;

protected function dumpMarkedEqns1
  input Integer e;
  input BackendDAE.EquationArray eqns;
  input String inS;
  output String outS;
protected
  String s1,s2,s3;
  BackendDAE.Equation eqn;
algorithm
  eqn := BackendEquation.equationNth1(eqns, e);
  s2 := equationString(eqn);
  s3 := intString(e);
  outS := stringAppendList({inS,s3,": ",s2,";\n"});
end dumpMarkedEqns1;

public function dumpMarkedVars
"Dumps only the variable names given as list of indexes to a string."
  input BackendDAE.EqSystem syst;
  input list<Integer> inIntegerLst;
  output String outString;
protected
  BackendDAE.Variables vars;
  list<String> slst;
algorithm
  BackendDAE.EQSYSTEM(orderedVars = vars) := syst;
  slst := List.map1(inIntegerLst,dumpMarkedVars1,vars);
  outString := stringDelimitList(slst,", ");
end dumpMarkedVars;

protected function dumpMarkedVars1
"Dumps only the variable names given as list of indexes to a string."
  input Integer v;
  input BackendDAE.Variables vars;
  output String outS;
protected
  String s1,s2,s3;
  DAE.ComponentRef cr;
algorithm
  BackendDAE.VAR(varName = cr) := BackendVariable.getVarAt(vars, v);
  s2 := ComponentReference.printComponentRefStr(cr);
  s3 := intString(v);
  outS := stringAppendList({s2,"(",s3,")"});
end dumpMarkedVars1;

public function dumpComponentsGraphStr
"Dumps the assignment graph used to determine strong
 components to format suitable for Mathematica"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  Integer n;
  list<String> lst;
  String s;
  BackendDAE.EqSystem syst;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrix mT;
  array<Integer> ass1,ass2;
algorithm
  BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT),matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2))}) := inDAE;
  n :=  BackendDAEUtil.systemSize(syst);
  lst := dumpComponentsGraphStr2(1,n,m,mT,ass1,ass2);
  s := stringDelimitList(lst,",");
  s := stringAppendList({"{",s,"}"});
  print(s);
  outDAE := inDAE;
end dumpComponentsGraphStr;

protected function dumpComponentsGraphStr2 "help function"
  input Integer i;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<String> lst = {};
protected
  list<list<Integer>> llst;
  list<Integer> eqns;
  list<String> strLst,slst;
  String str;
algorithm
  if i <= n then
    eqns := Matching.reachableEquations(i, mT, ass2);
    llst := List.map(eqns, List.create);
    llst := List.map1(llst, List.consr, i);
    slst := List.map(llst, intListStr);
    str := stringDelimitList(slst, ",");
    str := stringAppendList({"{", str, "}"});
    strLst := dumpComponentsGraphStr2(i+1, n, m, mT, ass1, ass2);
    lst := str::strLst;
  end if;
end dumpComponentsGraphStr2;

public function dumpList "author: PA

  Helper function to dump.
"
  input list<Integer> l;
  input String str;
protected
  list<String> s;
  String sl;
algorithm
  s := List.map(l, intString);
  sl := stringDelimitList(s, ", ");
  print(str);
  print(sl);
  print("\n");
end dumpList;

public function dumpComponentsOLD "author: PA

  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
algorithm
  print("Blocks\n");
  print("=======\n");
  dumpComponents2(l, 1);
end dumpComponentsOLD;

protected function dumpComponents2 "author: PA

  Helper function to dump_components.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
algorithm
  _:=
  match (inIntegerLstLst,inInteger)
    local
      Integer i_1,i;
      list<String> ls;
      String s;
      list<Integer> l;
      list<list<Integer>> lst;
    case ({},_) then ();
    case ((l :: lst),i)
      equation
        print("{");
        ls = List.map(List.sort(l,intGt), intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
        i_1 = i + 1;
        dumpComponents2(lst, i_1);
      then
        ();
  end match;
end dumpComponents2;

protected function intListStr "Takes a list of Integers and produces a string  on form: \"{1,2,3}\" "
  input list<Integer> lst;
  output String res;
algorithm
  res := stringDelimitList(List.map(lst,intString),",");
  res := stringAppendList({"{",res,"}"});
end intListStr;

// protected function dumpAliasVariable
// "author: Frenkel TUD 2010-11"
//  input tuple<BackendDAE.Var,list<Integer>> inTpl;
//  output tuple<BackendDAE.Var,list<Integer>> outTpl;
// algorithm
//   outTpl:=
//   matchcontinue (inTpl)
//     local
//       BackendDAE.Var v;
//       DAE.ComponentRef cr;
//       DAE.Exp e;
//       String s,scr,se;
//     case ((v,_))
//       equation
//         cr = BackendVariable.varCref(v);
//         e = BackendVariable.varBindExp(v);
//         //print("### dump var : " +  ComponentReference.printComponentRefStr(cr) + "\n");
//         scr = ComponentReference.printComponentRefStr(cr);
//         se = ExpressionDump.printExpStr(e);
//         s = stringAppendList({scr," = ",se,"\n"});
//         print(s);
//       then ((v,{}));
//     else inTpl;
//   end matchcontinue;
// end dumpAliasVariable;

public function dumpStateVariables "author: Frenkel TUD 2010-12

  dump State Variables.
"
  input BackendDAE.Variables inVars;
algorithm
  print("States Variables\n");
  print("=================\n");
  _ := BackendVariable.traverseBackendDAEVars(inVars,dumpStateVariable,1);
  print("\n");
end dumpStateVariables;

protected function dumpStateVariable
  input BackendDAE.Var inVar;
  input Integer inPos;
  output BackendDAE.Var v;
  output Integer pos;
algorithm
  (v,pos) := matchcontinue (inVar,inPos)
    local
      DAE.ComponentRef cr;
      String scr;
    case (v,pos)
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        scr = ComponentReference.printComponentRefStr(cr);
        print(intString(pos)); print(": ");
        print(scr); print("\n");
      then (v,pos+1);
    else (inVar,inPos);
  end matchcontinue;
end dumpStateVariable;

public function bltdump "author: Frenkel TUD 2011-03"
  input String headerline;
  input BackendDAE.BackendDAE inDAE;
algorithm
   _ := matchcontinue inDAE
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
      String str, strlow;

    case _ equation
      Flags.STRING_FLAG(data=str) = Flags.getConfigValue(Flags.DUMP_TARGET);
      strlow = System.tolower(str);
      true = intGt(System.stringFind(strlow, ".html"), 0);
      DumpHTML.dumpDAE(inDAE, headerline, str);
    then ();

    case BackendDAE.DAE(eqs, shared) equation
      print(headerline + ":\n");
      List.map_0(eqs, printEqSystem);
      print("\n");
      printShared(shared);
    then ();
  end matchcontinue;
end bltdump;

public function innerEquationString
  input BackendDAE.InnerEquation innerEquation;
  output String s;
protected
  Integer e;
  list<Integer> v;
algorithm
  (e,v) := BackendDAEUtil.getEqnAndVarsFromInnerEquation(innerEquation);
  s := stringDelimitList(List.map(v,intString), ",");
  s := "{"+intString(e)+":"+s+"}";
end innerEquationString;

protected type DumpCompShortSystemsTpl = tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>;
protected type DumpCompShortMixedTpl = tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>;
protected type DumpCompShortTornTpl = tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>;

public function dumpCompShort
  input BackendDAE.BackendDAE inDAE;
protected
  Integer sys,inp,st,dvar,dst,seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2,strcomps;
  list<Integer> e_jc,e_jn,e_nj;
  list<tuple<Integer,Integer,Integer>> te_l,te_l2;
  list<tuple<Integer,Integer>> te_nl,te_nl2;
  list<Integer> m_se,m_salg,m_sarr,m_sec;
  list<tuple<Integer,Integer>> me_jc,e_jt,me_jt,me_jn,me_nj,me_lt,me_nt;
  list<DAE.ComponentRef> states,discvars,discstates;
  HashSet.HashSet HS;
  BackendDAE.EqSystems systs;
  BackendDAE.EquationArray removedEqs;
  String statesStr, sysStr, stStr, dvarStr, dstStr, statesStr, discvarsStr, discstatesStr, inpStr, strcompsStr, seqStr, sarrStr, salgStr, sceStr, sweStr, sieStr, eqsysStr, teqsysStr, meqsysStr, daeType;

  list<String> msgs;
  DumpCompShortSystemsTpl systemsTpl;
  DumpCompShortMixedTpl mixedTpl;
  DumpCompShortTornTpl tornTpl,tornTpl2;
  BackendDAE.BackendDAEType backendDAEType;
algorithm
  BackendDAE.DAE(systs, BackendDAE.SHARED(backendDAEType=backendDAEType)) := inDAE;
  removedEqs := BackendDAEUtil.collapseRemovedEqs(inDAE);
  daeType := printBackendDAEType2String(backendDAEType);

  HS := HashSet.emptyHashSet();
  HS := List.fold(systs, Initialization.collectPreVariablesEqSystem, HS);
  ((_,HS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(removedEqs, Expression.traverseSubexpressionsHelper, (Initialization.collectPreVariablesTraverseExp, HS));
  discstates := BaseHashSet.hashSetList(HS);
  dst := listLength(discstates);

  ((sys,inp,st,states,dvar,discvars,seq,salg,sarr,sce,swe,sie,systemsTpl,mixedTpl,tornTpl,tornTpl2)) := BackendDAEUtil.foldEqSystem(inDAE,dumpCompShort1,(0,0,0,{},0,{},0,0,0,0,0,0,({},{},{},{}),({},{},{},{},{},{},{},{},{},{}),({},{}),({},{})));
  (e_jc,e_jt,e_jn,e_nj) := systemsTpl;
  (m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt) := mixedTpl;
  (te_l,te_nl) := tornTpl;
  (te_l2,te_nl2) := tornTpl2;

  eqsys := listLength(e_jc)+listLength(e_jt)+listLength(e_jn)+listLength(e_nj);
  meqsys := listLength(m_se)+listLength(m_sarr)+listLength(m_salg)+listLength(m_sec)+listLength(me_jc)+listLength(me_jt)+listLength(me_jn)+listLength(me_nj)+listLength(me_lt)+listLength(me_nt);
  teqsys := listLength(te_l)+listLength(te_nl);
  teqsys2 := listLength(te_l2)+listLength(te_nl2);
  strcomps := seq+eqsys+meqsys+sarr+salg+sce+swe+sie+teqsys;

  sysStr := intString(sys);
  stStr := intString(st);
  dvarStr := intString(dvar);
  dstStr := intString(dst);
  statesStr := if Flags.isSet(Flags.DUMP_STATESELECTION_INFO)
    then " (" + stringDelimitList(List.map(states, ComponentReference.printComponentRefStr),",") + ")"
    else " ('+d=stateselection' for list of states)";
  discvarsStr := if Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO)
    then " (" + stringDelimitList(List.map(discvars, ComponentReference.printComponentRefStr),",") + ")"
    else " ('+d=discreteinfo' for list of discrete vars)";
  discstatesStr := if Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO)
     then " (" + stringDelimitList(List.map(discstates, ComponentReference.printComponentRefStr),",") + ")"
     else " ('+d=discreteinfo' for list of discrete states)";
  inpStr := intString(inp);
  stStr := stStr+statesStr;
  dvarStr := dvarStr+discvarsStr;
  dstStr := dstStr+discstatesStr;
  msgs := {daeType,sysStr,stStr,dvarStr,dstStr,inpStr};
  Error.addMessage(Error.BACKENDDAEINFO_STATISTICS, msgs);

  strcompsStr := intString(strcomps);
  seqStr := intString(seq);
  sarrStr := intString(sarr);
  salgStr := intString(salg);
  sceStr := intString(sce);
  sweStr := intString(swe);
  sieStr := intString(sie);
  eqsysStr := intString(eqsys);
  teqsysStr := intString(teqsys);
  meqsysStr := intString(meqsys);

  msgs := {daeType,strcompsStr,seqStr,sarrStr,salgStr,sceStr,sweStr,sieStr,eqsysStr,teqsysStr,meqsysStr};
  Error.addMessage(Error.BACKENDDAEINFO_STRONGCOMPONENT_STATISTICS, msgs);

  if intGt(eqsys,0) then
    dumpCompSystems(systemsTpl);
  end if;
  if intGt(meqsys,0) then
    dumpCompMixed(mixedTpl);
  end if;
  if intGt(teqsys,0) then
    dumpCompTorn(tornTpl,"strict");
  end if;
  if intGt(teqsys2,0) and not stringEqual(Config.dynamicTearing(),"false") then
    dumpCompTorn(tornTpl2,"casual");
  end if;
end dumpCompShort;

protected function dumpCompSystems
  input DumpCompShortSystemsTpl systemsTpl;
protected
  list<Integer> e_jc,e_jn,e_nj;
  list<tuple<Integer,Integer>> e_jt;
  String s_jc,s_jn,s_nj,s_jt;
algorithm
  (e_jc,e_jt,e_jn,e_nj) := systemsTpl;
  s_jc := equationSizesStr(e_jc,intString);
  s_jt := equationSizesStr(e_jt,sizeNumNonZeroTplString);
  s_jn := equationSizesStr(e_jn,intString);
  s_nj := equationSizesStr(e_nj,intString);
  Error.addMessage(Error.BACKENDDAEINFO_SYSTEMS, {s_jc,s_jt,s_jn,s_nj});
end dumpCompSystems;

protected function dumpCompTorn
  input DumpCompShortTornTpl systemsTpl;
  input String whichset;
protected
  list<tuple<Integer,Integer,Integer>> te_l;
  list<tuple<Integer,Integer>> te_nl;
  String s_l,s_nl;
algorithm
  (te_l,te_nl) := systemsTpl;
  s_l := equationSizesStr(te_l,sizeNumNonZeroTornTplString);
  s_nl := equationSizesStr(te_nl,intTplString);
  Error.addMessage(Error.BACKENDDAEINFO_TORN, {whichset,s_l,s_nl});
end dumpCompTorn;

protected function dumpCompMixed
  input DumpCompShortMixedTpl mixedTpl;
protected
  list<Integer> m_se,m_salg,m_sarr,m_sec;
  list<tuple<Integer,Integer>> me_jc,e_jt,me_jt,me_jn,me_nj,me_lt,me_nt;
  String s_se,s_salg,s_sarr,s_sec,s_jc,s_jt,s_jn,s_nj,s_lt,s_nt;
algorithm
  (m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt) := mixedTpl;
  s_se := equationSizesStr(m_se,intString);
  s_salg := equationSizesStr(m_salg,intString);
  s_sarr := equationSizesStr(m_sarr,intString);
  s_sec := equationSizesStr(m_sec,intString);
  s_jc := equationSizesStr(me_jc,intTplString);
  s_jt := equationSizesStr(me_jt,intTplString);
  s_jn := equationSizesStr(me_jn,intTplString);
  s_nj := equationSizesStr(me_nj,intTplString);
  s_lt := equationSizesStr(me_lt,intTplString);
  s_nt := equationSizesStr(me_nt,intTplString);
  Error.addMessage(Error.BACKENDDAEINFO_MIXED, {s_se,s_salg,s_sarr,s_sec,s_jc,s_jt,s_jn,s_nj,s_lt,s_nt});
end dumpCompMixed;

protected function equationSizesStr
  input list<A> eqs;
  input AToStr fn;
  output String str;
  replaceable type A subtypeof Any;
  partial function AToStr
    input A a;
    output String str;
  end AToStr;
protected
  Integer len;
algorithm
  len := listLength(eqs);
  str := if len == 0 then "0" else (intString(len) + " {" + stringDelimitList(List.map(eqs,fn),",") + "}");
end equationSizesStr;

protected function sizeNumNonZeroTplString
  input tuple<Integer,Integer> inTpl;
  output String str;
protected
  Integer sz,nnz;
  Real density;
algorithm
  (sz,nnz) := inTpl;
  density := realDiv(realMul(100.0,intReal(nnz)),realMul(intReal(sz),intReal(sz)));
  str := System.snprintff("%.1f",20,density);
  str := "(" + intString(sz) + "," + str + "%)";
end sizeNumNonZeroTplString;

protected function sizeNumNonZeroTornTplString
  input tuple<Integer,Integer,Integer> inTpl;
  output String str;
protected
  Integer sz,nnz,others;
  Real density;
algorithm
  (sz,others,nnz) := inTpl;
  density := if nnz == 0 then 0.0 else realDiv(realMul(100.0,intReal(nnz)),realMul(intReal(sz),intReal(sz)));
  str := System.snprintff("%.1f",20,density);
  str := "(" + intString(sz) + "," + str + "%)" + " " + intString(others);
end sizeNumNonZeroTornTplString;

protected function intTplString
  input tuple<Integer,Integer> inTpl;
  output String outStr;
protected
  Integer e,d;
algorithm
  (d,e) := inTpl;
  outStr := intString(d) + " " + intString(e);
end intTplString;

protected function dumpCompShort1
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  input tuple<Integer,Integer,Integer,list<DAE.ComponentRef>,Integer,list<DAE.ComponentRef>,Integer,Integer,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>> inTpl;
  output tuple<
       Integer,
       Integer,
       Integer,
       list<DAE.ComponentRef>,
       Integer,
       list<DAE.ComponentRef>,
       Integer,
       Integer,
       Integer,
       Integer,
       Integer,
       Integer,
       DumpCompShortSystemsTpl,
       DumpCompShortMixedTpl,
       DumpCompShortTornTpl,
       DumpCompShortTornTpl> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.StrongComponents comps;
  Integer sys,inp,st,dvar,seq,salg,sarr,sce,swe,sie,inp1,st1,dvar1,seq1,salg1,sarr1,sce1,swe1,sie1;
  tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>> eqsys,eqsys1;
  tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> meqsys,meqsys1;
  tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>> teqsys,teqsys1,teqsys_2,teqsys1_2;
  list<DAE.ComponentRef> states,states1,discvars,discvars1;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := inSyst;
  (sys, inp, st, states, dvar, discvars, seq, salg, sarr, sce, swe, sie, eqsys, meqsys, teqsys, teqsys_2) := inTpl;

  ((inp1,st1,states1,dvar1,discvars1)) := BackendVariable.traverseBackendDAEVars(vars,traversingisStateTopInputVarFinder,(inp,st,states,dvar,discvars));
  comps := BackendDAEUtil.getStrongComponents(inSyst);
  ((seq1,salg1,sarr1,sce1,swe1,sie1,eqsys1,meqsys1,teqsys1,teqsys1_2)) := List.fold(comps,dumpCompShort2,(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys_2));

  outTpl := ((sys+1, inp1, st1, states1, dvar1, discvars1, seq1, salg1, sarr1, sce1, swe1, sie1, eqsys1, meqsys1, teqsys1, teqsys1_2));
end dumpCompShort1;

protected function traversingisStateTopInputVarFinder
  input BackendDAE.Var inVar;
  input tuple<Integer,Integer,list<DAE.ComponentRef>,Integer,list<DAE.ComponentRef>> inTpl;
  output BackendDAE.Var outVar;
  output tuple<Integer,Integer,list<DAE.ComponentRef>,Integer,list<DAE.ComponentRef>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      Integer inp,st,dvar;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> states,discvars;

    case (v,(inp,st,states,dvar,discvars)) equation
      true = BackendVariable.isStateVar(v);
      cr = BackendVariable.varCref(v);
    then (v,(inp,st+1,cr::states,dvar,discvars));

    case (v,(inp,st,states,dvar,discvars)) equation
      true = BackendVariable.isVarDiscrete(v);
      cr = BackendVariable.varCref(v);
    then (v,(inp,st,states,dvar+1,cr::discvars));

    case (v,(inp,st,states,dvar,discvars)) equation
      true = BackendVariable.isVarOnTopLevelAndInput(v);
    then (v,(inp+1,st,states,dvar,discvars));

    else (inVar,inTpl);
  end matchcontinue;
end traversingisStateTopInputVarFinder;

protected function dumpCompShort2
  input BackendDAE.StrongComponent inComp;
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>> inTpl;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>>> outTpl;
algorithm
  outTpl := match (inComp,inTpl)
    local
      Integer e,d,e2,d2,nnz,nnz2;
      list<Integer> ilst,ilst1,ilst2;
      Integer seq,salg,sarr,sce,swe,sie;
      list<Integer> e_jc,e_jn,e_nj,m_se,m_salg,m_sarr,m_sec;
      list<tuple<Integer,Integer,Integer>> te_l,te_l2;
      list<tuple<Integer,Integer>> e_jt,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt,te_nl,te_nl2;
      tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>> eqsys;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> meqsys;
      tuple<list<tuple<Integer,Integer,Integer>>,list<tuple<Integer,Integer>>> teqsys,teqsys2;
      BackendDAE.InnerEquations innerEquations,innerEquations2;
      list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> patternLst;

    case (BackendDAE.SINGLEEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2))
    then ((seq+1,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2));

    case (BackendDAE.SINGLEARRAY(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2))
    then ((seq,salg,sarr+1,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2));

    case (BackendDAE.SINGLEIFEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2))
    then ((seq,salg,sarr,sce,swe,sie+1,eqsys,meqsys,teqsys,teqsys2));

    case (BackendDAE.SINGLEALGORITHM(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2))
    then ((seq,salg+1,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2));

    case (BackendDAE.SINGLECOMPLEXEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2))
    then((seq,salg,sarr,sce+1,swe,sie,eqsys,meqsys,teqsys,teqsys2));

    case (BackendDAE.SINGLEWHENEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,teqsys2))
    then ((seq,salg,sarr,sce,swe+1,sie,eqsys,meqsys,teqsys,teqsys2));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_CONSTANT()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2)) equation
        e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e::e_jc,e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jac=BackendDAE.FULL_JACOBIAN(SOME(jac)),jacType=BackendDAE.JAC_LINEAR()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2))
      equation
        e = listLength(ilst);
        nnz = listLength(jac);
      then ((seq,salg,sarr,sce,swe,sie,(e_jc,(e,nnz)::e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_NONLINEAR()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2)) equation
      e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e::e_jn,e_nj),meqsys,teqsys,teqsys2));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_GENERIC()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2)) equation
      e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e::e_jn,e_nj),meqsys,teqsys,teqsys2));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_NO_ANALYTIC()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys,teqsys2)) equation
      e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e::e_nj),meqsys,teqsys,teqsys2));

    // no dynamic tearing
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,innerEquations=innerEquations,jac=BackendDAE.GENERIC_JACOBIAN(_,(_,_,_,nnz),_)),NONE(),linear=true),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl),(te_l2,te_nl2))) equation
      d = listLength(ilst);
      e = listLength(innerEquations);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,((d,e,nnz)::te_l,te_nl),((0,0,0)::te_l2,te_nl2)));

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,innerEquations=innerEquations),NONE(),linear=false),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl),(te_l2,te_nl2))) equation
      d = listLength(ilst);
      e = listLength(innerEquations);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,(d,e)::te_nl),(te_l2,(0,0)::te_nl2)));

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,innerEquations=innerEquations,jac=BackendDAE.EMPTY_JACOBIAN()),NONE(),linear=true),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl),(te_l2,te_nl2))) equation
      d = listLength(ilst);
      e = listLength(innerEquations);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,((d,e,0)::te_l,te_nl),((0,0,0)::te_l2,te_nl2)));

    // dynamic tearing
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,innerEquations=innerEquations,jac=BackendDAE.GENERIC_JACOBIAN(_,(_,_,_,nnz),_)),SOME(BackendDAE.TEARINGSET(tearingvars=ilst2,innerEquations=innerEquations2,jac=BackendDAE.GENERIC_JACOBIAN(_,(_,_,_,nnz2),_))),linear=true),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl),(te_l2,te_nl2))) equation
      d = listLength(ilst);
      e = listLength(innerEquations);
      d2 = listLength(ilst2);
      e2 = listLength(innerEquations2);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,((d,e,nnz)::te_l,te_nl),((d2,e2,nnz2)::te_l2,te_nl2)));

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,innerEquations=innerEquations),SOME(BackendDAE.TEARINGSET(tearingvars=ilst2,innerEquations=innerEquations2)),linear=false),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl),(te_l2,te_nl2))) equation
      d = listLength(ilst);
      e = listLength(innerEquations);
      d2 = listLength(ilst2);
      e2 = listLength(innerEquations2);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,(d,e)::te_nl),(te_l2,(d2,e2)::te_nl2)));

    else equation
      print("dumpCompShort2 failed with:\n");
      dumpComponent(inComp);
    then fail();
  end match;
end dumpCompShort2;

public function dumpNrOfEquations
"author Frenkel TUD 2012-11
  prints the number of scalar equations in the dae system"
  input BackendDAE.BackendDAE inDAE;
  input String preStr;
protected
  list<Integer> nlst;
  Integer n;
  BackendDAE.EqSystems systs;
algorithm
  BackendDAE.DAE(eqs=systs) := inDAE;
  nlst := List.map(systs,BackendDAEUtil.systemSize);
  n := List.fold(nlst,intAdd,0);
  print(preStr + " NrOfEquations: " + intString(n) + "\n");
end dumpNrOfEquations;

public function dumpCompInfo"dumps the information about the operations in the component.
author Waurich TUD 2014-04"
  input BackendDAE.CompInfo compInfo;
algorithm
  print(printCompInfo(compInfo));
end dumpCompInfo;

protected function printCompInfo""
  input BackendDAE.CompInfo compInfo;
  output String sOut;
algorithm
  sOut := matchcontinue(compInfo)
    local
      Integer numAdds,numMul,numDiv,numOth,numTrig,numRel,numLog,numFuncs, size;
      Real dens;
      String s;
      BackendDAE.CompInfo allOps, tornEqs ,otherEqs;
      BackendDAE.StrongComponent comp;
      case(BackendDAE.COUNTER(comp=comp,numAdds=numAdds,numMul=numMul,numDiv=numDiv,numTrig=numTrig,numRelations=numRel,numLog=numLog,numOth=numOth,funcCalls=numFuncs))
        equation
          s = "";
          if BackendDAEUtil.isSingleEquationComp(comp) then s= "SE "+printComponent(comp);
          elseif BackendDAEUtil.isWhenComp(comp) then s= "WE "+printComponent(comp);
          elseif BackendDAEUtil.isArrayComp(comp) then s= "AE "+printComponent(comp);
          end if;
          s = s+"\tadd|"+intString(numAdds)+"\tmul|"+intString(numMul)+"\tdiv|"+intString(numDiv)+"\ttrig|"+intString(numTrig)+"\trel|"+intString(numRel)+"\tlog|"+intString(numLog)+"\toth|"+intString(numOth)+"\tfuncs|"+intString(numFuncs)+"\n";
        then s;
      case(BackendDAE.SYSTEM(allOperations=allOps,comp=comp,size=size,density=dens))
        equation
          s = "";
          if BackendDAEUtil.isLinearEqSystemComp(comp) then s= "LSYS";
          else s = "NLSYS";
          end if;
          s = s+printComponent(comp)+"\tsize|"+intString(size)+"\tdens|"+intString(realInt(dens*100.0))+ printCompInfo(allOps);
        then s;
      case(BackendDAE.TORN_ANALYSE(tornEqs=tornEqs, otherEqs=otherEqs,comp=comp,tornSize=size))
        equation
          //if BackendDAEUtil.isLinearTornSystem(comp) then s = "linear"; else s = "nonlinear"; end if;
          s = "TS "+printComponent(comp)+"\tsize|"+intString(size)+"\n";
          s = s + "\tthe torn eqs:\t"+ printCompInfo(tornEqs);
          s = s + "\tthe other eqs:\t" + printCompInfo(otherEqs);
        then s;
      case(BackendDAE.NO_COMP(numAdds=numAdds,numMul=numMul,numDiv=numDiv,numTrig=numTrig,numRelations=numRel,numLog=numLog,numOth=numOth,funcCalls=numFuncs))
        equation
          s = "NC";
          s = s+"\tadd|"+intString(numAdds)+"\tmul|"+intString(numMul)+"\tdiv|"+intString(numDiv)+"\ttrig|"+intString(numTrig)+"\trel|"+intString(numRel)+"\tlog|"+intString(numLog)+"\toth|"+intString(numOth)+"\tfuncs|"+intString(numFuncs)+"\n";
        then s;
      else
        then "Dont know this compInfo\n";
  end matchcontinue;
end printCompInfo;


// =============================================================================
// section for all html-dumping functions
//
// =============================================================================

public function dumpEqSystemMatrixHTML"dumps the incidence matrix for the eqsystem as html file.
author: waurich TUD 2016-05"
  input BackendDAE.EqSystem sys;
protected
  BackendDAE.IncidenceMatrix m;
algorithm
  if Util.isSome(sys.m) then
    m := Util.getOption(sys.m);
  else
    (_,m,_) := BackendDAEUtil.getIncidenceMatrix(sys,BackendDAE.NORMAL(),NONE());
  end if;
  BackendDump.dumpEqSystem(sys,"SYS");
  BackendDump.dumpMatrixHTML(m,List.map(List.intRange(BackendDAEUtil.systemSize(sys)),intString),
                               List.map(BackendVariable.varList(sys.orderedVars),BackendDump.varStringShort),
                               "MATRIX_"+intString(BackendDAEUtil.systemSize(sys)));
end dumpEqSystemMatrixHTML;

public function dumpEqSystemBLTmatrixHTML"dumps the incidence matrix for the eqsystem as html file.
author: waurich TUD 2016-05"
  input BackendDAE.EqSystem sys;
algorithm
  _ := matchcontinue(sys)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.EquationArray eqs;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varLst;
      list<BackendDAE.Equation> eqLst;
      list<Integer> vIdxs, eIdxs;
  case(BackendDAE.EQSYSTEM(vars,eqs,_,_,BackendDAE.MATCHING(comps=comps),_,_,_))
    algorithm
      (varLst,vIdxs,eqLst,eIdxs) := BackendDAEUtil.getStrongComponentsVarsAndEquations(comps, vars, eqs);
      eqs := BackendEquation.listEquation(eqLst);
      vars := BackendVariable.listVar1(varLst);
      (m, _) := BackendDAEUtil.incidenceMatrixDispatch(vars, eqs, BackendDAE.NORMAL(), NONE());
      BackendDump.dumpMatrixHTML(m,List.map(eIdxs,intString),
                                    List.map(vIdxs,intString),
                                   "BLT_MATRIX_"+intString(BackendDAEUtil.systemSize(sys)));
    then ();
  else
    algorithm
      print("dumpEqSystemBLTmatrixHTML does not output anything since there is no BLT sorting.");
    then ();
  end matchcontinue;
end dumpEqSystemBLTmatrixHTML;


public function dumpMatrixHTML
  input BackendDAE.IncidenceMatrix m;
  input list<String> rowNames;
  input list<String> columNames;
  input String fileName;
protected
  Integer size;
algorithm
  size := arrayLength(m);
  if listLength(rowNames)==size and listLength(columNames)==size then
    DumpHTML.dumpMatrixHTML(m,rowNames,columNames,fileName);
  else
    DumpHTML.dumpMatrixHTML(m,List.fill("?",size),List.fill("?",size),fileName);
  end if;
end dumpMatrixHTML;

// =============================================================================
// section for all graphML dumping functions
//
// =============================================================================

public function dumpBipartiteGraphDAE" Dumps a *.graphml of the complete BackendDAE.BackendDAE as a bipartite graph. Can be opened with yEd.
author: Waurich"
  input BackendDAE.BackendDAE dae;
  input String fileName;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.EqSystems eqSysts;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Shared shared;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
  list<tuple<Boolean,String>> varAtts,eqAtts;
algorithm
  BackendDAE.DAE(eqs=eqSysts, shared=shared) := dae;
  eqLst := List.flatten(List.mapMap(eqSysts,BackendEquation.getEqnsFromEqSystem,BackendEquation.equationList));
  varLst := List.flatten(List.mapMap(eqSysts,BackendVariable.daeVars,BackendVariable.varList));
  vars := BackendVariable.listVar1(varLst);
  eqs := BackendEquation.listEquation(eqLst);
  // build the incidence matrix for the whole System
  (_,m,_,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),BackendDAE.NO_MATCHING(), {},BackendDAE.UNKNOWN_PARTITION(), BackendEquation.emptyEqns()),BackendDAE.SOLVABLE(), SOME(BackendDAEUtil.getFunctions(shared)));
  varAtts := List.threadMap(List.fill(false,listLength(varLst)),List.fill("",listLength(varLst)),Util.makeTuple);
  eqAtts := List.threadMap(List.fill(false,listLength(eqLst)),List.fill("",listLength(eqLst)),Util.makeTuple);
  dumpBipartiteGraphStrongComponent2(vars,eqs,m,varAtts,eqAtts,"BipartiteGraph_"+fileName);
end dumpBipartiteGraphDAE;

  public function dumpBipartiteGraphEqSystem" Dumps a *.graphml of an BackendDAE.EqSystem as a bipartite graph. Can be opened with yEd.
author: Waurich"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input String fileName;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.AdjacencyMatrixEnhanced me,meT;
  BackendDAE.IncidenceMatrix m;
  Option<BackendDAE.IncidenceMatrix> mO;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
  list<tuple<Boolean,String>> varAtts,eqAtts;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs, m=mO) := syst;
  varLst := BackendVariable.varList(vars);
  eqLst := BackendEquation.equationList(eqs);
  varAtts := List.threadMap(List.fill(false,listLength(varLst)),List.fill("",listLength(varLst)),Util.makeTuple);
  eqAtts := List.threadMap(List.fill(false,listLength(eqLst)),List.fill("",listLength(eqLst)),Util.makeTuple);
  if Util.isSome(mO) then
      dumpBipartiteGraphStrongComponent2(vars,eqs,Util.getOption(mO),varAtts,eqAtts,"BipartiteGraph_"+fileName);
  else
    // build the incidence matrix
    (_,m,_,_,_) := BackendDAEUtil.getIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(BackendDAEUtil.getFunctions(shared)));
    dumpBipartiteGraphStrongComponent2(vars,eqs,m,varAtts,eqAtts,"BipartiteGraph_"+fileName);
  end if;
end dumpBipartiteGraphEqSystem;

public function dumpBipartiteGraphStrongComponent"dumps a bipartite graph of an equation system or a torn system as graphml.Can be opened with yEd.
waurich: TUD 2014-09"
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EqSystem eqSys;
  input Option<DAE.FunctionTree> funcs;
  input String name;
protected
  BackendDAE.EquationArray eqs;
  BackendDAE.Variables vars;
  list<BackendDAE.Var> varLst;
  list<BackendDAE.Equation> eqLst;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs) := eqSys;
  varLst := BackendVariable.varList(vars);
  eqLst := BackendEquation.equationList(eqs);
  dumpBipartiteGraphStrongComponent1(inComp,eqLst,varLst,funcs,name);
end dumpBipartiteGraphStrongComponent;

public function dumpBipartiteGraphStrongComponent1"helper function for dumpBipartiteGraphStrongComponent which handles either an equationsystem or a torn system"
  input BackendDAE.StrongComponent inComp;
  input list<BackendDAE.Equation> eqsIn;
  input list<BackendDAE.Var> varsIn;
  input Option<DAE.FunctionTree> funcs;
  input String graphName;
algorithm
  () := matchcontinue(inComp,eqsIn,varsIn,funcs,graphName)
    local
      Integer numEqs, numVars, compIdx;
      list<Boolean> tornInfo;
      list<String> addInfo;
      list<Integer> eqIdcs,varIdcs,tVarIdcs,rEqIdcs, tVarIdcsNew, rEqIdcsNew;
      list<list<Integer>> varIdcsLst;
      BackendDAE.InnerEquations innerEquations;
      list<tuple<Boolean,String>> varAtts,eqAtts;
      BackendDAE.EquationArray compEqs;
      BackendDAE.Variables compVars;
      BackendDAE.StrongComponent comp;
      BackendDAE.IncidenceMatrix m,mT;
      list<BackendDAE.Equation> compEqLst;
      list<BackendDAE.Var> compVarLst;
  case((BackendDAE.EQUATIONSYSTEM(eqns=eqIdcs,vars=varIdcs)),_,_,_,_)
    equation
      compEqLst = List.map1(eqIdcs,List.getIndexFirst,eqsIn);
      compVarLst = List.map1(varIdcs,List.getIndexFirst,varsIn);
      compVars = BackendVariable.listVar1(compVarLst);
      compEqs = BackendEquation.listEquation(compEqLst);

      numEqs = listLength(compEqLst);
      numVars = listLength(compVarLst);
      (_,m,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(BackendDAE.EQSYSTEM(compVars,compEqs,NONE(),NONE(),BackendDAE.NO_MATCHING(),{},BackendDAE.UNKNOWN_PARTITION(),BackendEquation.emptyEqns()), BackendDAE.SOLVABLE(), funcs);

      varAtts = List.threadMap(List.fill(false,numVars),List.fill("",numVars),Util.makeTuple);
      eqAtts = List.threadMap(List.fill(false,numEqs),List.fill("",numEqs),Util.makeTuple);
      dumpBipartiteGraphStrongComponent2(compVars,compEqs,m,varAtts,eqAtts,"rL_eqSys_"+graphName);
    then ();
  case((BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=rEqIdcs,tearingvars=tVarIdcs,innerEquations=innerEquations))),_,_,_,_)
    equation
      //gather equations ans variables
      (eqIdcs,varIdcsLst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
      varIdcs = List.flatten(varIdcsLst);
      eqIdcs = listAppend(eqIdcs, rEqIdcs);
      varIdcs = listAppend(varIdcs, tVarIdcs);
      compEqLst = List.map1(eqIdcs,List.getIndexFirst,eqsIn);
      compVarLst = List.map1(varIdcs,List.getIndexFirst,varsIn);
      compVars = BackendVariable.listVar1(compVarLst);
      compEqs = BackendEquation.listEquation(compEqLst);

      // get incidence matrix
      numEqs = listLength(compEqLst);
      numVars = listLength(compVarLst);
      (_,m,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(BackendDAE.EQSYSTEM(compVars,compEqs,NONE(),NONE(),BackendDAE.NO_MATCHING(),{},BackendDAE.UNKNOWN_PARTITION(),BackendEquation.emptyEqns()), BackendDAE.SOLVABLE(), funcs);

      // add tearing info to graph object and dump graph
      addInfo = List.map(varIdcs,intString);// the DAE idcs for the vars
      tornInfo = List.fill(true,numVars);
      tVarIdcsNew = List.intRange(numVars-listLength(tVarIdcs));
      tornInfo = List.fold1(tVarIdcsNew,List.replaceAtIndexFirst,false,tornInfo);//is it a tearing var or not
      varAtts = List.threadMap(tornInfo,addInfo,Util.makeTuple);
      addInfo = List.map(eqIdcs,intString);// the DAE idcs for the eqs
      tornInfo = List.fill(true,numEqs);
      rEqIdcsNew = List.intRange(numEqs-listLength(rEqIdcs));
      tornInfo = List.fold1(rEqIdcsNew,List.replaceAtIndexFirst,false,tornInfo);//is it a residual eq or not
      eqAtts = List.threadMap(tornInfo,addInfo,Util.makeTuple);
      dumpBipartiteGraphStrongComponent2(compVars,compEqs,m,varAtts,eqAtts,graphName);
    then ();
  else
    equation
      print("dumpTornSystemBipartiteGraphML1 failed\n");
    then ();
  end matchcontinue;
end dumpBipartiteGraphStrongComponent1;

public function dumpBipartiteGraphStrongComponent2"helper function for dumpBipartiteGraphStrongComponent1 which dumps the graphml"
  input BackendDAE.Variables varsIn;
  input BackendDAE.EquationArray eqsIn;
  input BackendDAE.IncidenceMatrix mIn;
  input list<tuple<Boolean,String>> varAtts;  //<isTornVar,daeIdx>
  input list<tuple<Boolean,String>> eqAtts;  //<isResEq,daeIdx>
  input String name;
protected
  Integer nameAttIdx,typeAttIdx,idxAttIdx, numVars,numEqs;
  list<Integer> varRange,eqRange;
  BackendDAE.IncidenceMatrix m;
  GraphML.GraphInfo graphInfo;
  Integer graphIdx;
algorithm
  numEqs := BackendDAEUtil.equationArraySize(eqsIn);
  numVars := BackendVariable.varsSize(varsIn);
  varRange := List.intRange(numVars);
  eqRange := List.intRange(numEqs);
  graphInfo := GraphML.createGraphInfo();
  (graphInfo,(_,graphIdx)) := GraphML.addGraph("EqSystemGraph", true, graphInfo);
  (graphInfo,(_,typeAttIdx)) := GraphML.addAttribute("", "type", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  (graphInfo,(_,nameAttIdx)) := GraphML.addAttribute("", "name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  (graphInfo,(_,idxAttIdx)) := GraphML.addAttribute("", "systIdx", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  ((graphInfo,graphIdx)) := List.fold3(eqRange,addEqNodeToGraph,eqsIn,eqAtts,{nameAttIdx,typeAttIdx,idxAttIdx}, (graphInfo,graphIdx));
  ((graphInfo,graphIdx)) := List.fold3(varRange,addVarNodeToGraph,varsIn,varAtts,{nameAttIdx,typeAttIdx,idxAttIdx}, (graphInfo,graphIdx));
  graphInfo := List.fold1(eqRange,addEdgeToGraph,mIn,graphInfo);
  GraphML.dumpGraph(graphInfo,name+".graphml");
end dumpBipartiteGraphStrongComponent2;

public function dumpDAGStrongComponent"dumps a directed acyclic graph for the matched strongly connected component"
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input String fileName;
protected
  Integer graphIdx, nameAttIdx;
  GraphML.GraphInfo graphInfo;
algorithm
  graphInfo := GraphML.createGraphInfo();
  (graphInfo, (_,graphIdx)) := GraphML.addGraph("TornSystemGraph", true, graphInfo);
  (graphInfo,(_,nameAttIdx)) := GraphML.addAttribute("", "Name", GraphML.TYPE_STRING(), GraphML.TARGET_NODE(), graphInfo);
  graphInfo := buildGraphInfoDAG(graphIn,metaIn,graphInfo,graphIdx,{nameAttIdx});
  GraphML.dumpGraph(graphInfo, fileName+".graphml");
end dumpDAGStrongComponent;

protected function buildGraphInfoDAG"helper function for dumpDAGStrongComponent"
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input GraphML.GraphInfo graphInfoIn;
  input Integer graphIdx;
  input list<Integer> attIdcs;
  output GraphML.GraphInfo graphInfoOut;
protected
  GraphML.GraphInfo graphInfo;
  list<Integer> nodeIdcs;
  list<GraphML.Node> nodes;
  Integer nameAttIdx;
algorithm
  nameAttIdx := listHead(attIdcs);
  nodeIdcs := List.intRange(arrayLength(graphIn));
  graphInfoOut := List.fold4(nodeIdcs,addNodeToDAG,graphIn,metaIn,graphIdx,{nameAttIdx},graphInfoIn);
  GraphML.GRAPHINFO(nodes=nodes) := graphInfoOut;
end buildGraphInfoDAG;

protected function addNodeToDAG"add a node to a DAG.
author:Waurich TUD 2014-07"
  input Integer nodeIdx;
  input HpcOmTaskGraph.TaskGraph graphIn;
  input HpcOmTaskGraph.TaskGraphMeta metaIn;
  input Integer graphIdx;
  input list<Integer> atts; //{nameAtt}
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
  GraphML.GraphInfo tmpGraph;
  Integer nameAttIdx;
  list<Integer> childNodes;
  array<String> compDescs;
  array<list<Integer>> inComps;
  GraphML.NodeLabel nodeLabel;
  String nodeString, nodeDesc, compName;
algorithm
  HpcOmTaskGraph.TASKGRAPHMETA(inComps=inComps,compDescs=compDescs) := metaIn;
  nodeDesc := arrayGet(compDescs,nodeIdx);
  nodeString := intString(nodeIdx);
  compName := stringDelimitList(List.map(arrayGet(inComps,nodeIdx),intString),",");
  nameAttIdx := listGet(atts,1);
  nodeLabel := GraphML.NODELABEL_INTERNAL(nodeString,NONE(),GraphML.FONTPLAIN());
  (tmpGraph,(_,_)) := GraphML.addNode("Node"+intString(nodeIdx),
                                              GraphML.COLOR_ORANGE,
                                              {nodeLabel},
                                              GraphML.RECTANGLE(),
                                              SOME(nodeDesc),
                                              {(nameAttIdx,compName)},
                                              graphIdx,
                                              graphInfoIn);
  childNodes := arrayGet(graphIn,nodeIdx);
  graphInfoOut := List.fold1(childNodes, addDirectedEdge, nodeIdx, tmpGraph);
end addNodeToDAG;

protected function addDirectedEdge"add a directed edge from child to parent
author: Waurich TUD 2014-07"
  input Integer child;
  input Integer parent;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
algorithm
  (graphInfoOut,(_,_)) := GraphML.addEdge( "Edge" + intString(parent)+intString(child),
                                      "Node" + intString(child),
                                      "Node" + intString(parent),
                                      GraphML.COLOR_BLACK,
                                      GraphML.LINE(),
                                      GraphML.LINEWIDTH_STANDARD,
                                      false,{},
                                      (GraphML.ARROWNONE(),GraphML.ARROWSTANDART()),
                                      {},
                                      graphInfoIn);
end addDirectedEdge;

protected function addVarNodeToGraph "adds a node for a variable to the graph.
author:Waurich TUD 2013-12"
  input Integer indx;
  input BackendDAE.Variables vars;
  input list<tuple<Boolean,String>> attsIn; //<isTearingVar,"index in the dae">
  input list<Integer> attributeIdcs;//<name,type,daeidx>
  input tuple<GraphML.GraphInfo,Integer> graphInfoIn;
  output tuple<GraphML.GraphInfo,Integer> graphInfoOut;
protected
  BackendDAE.Var var;
  Boolean isTearVar;
  Integer nameAttrIdx,typeAttIdx,idxAttrIdx, graphIdx;
  String varString, varNodeId, idxString, typeStr, daeIdxStr;
  list<String> varChars;
  GraphML.GraphInfo graphInfo;
  GraphML.NodeLabel nodeLabel;
algorithm
  (graphInfo,graphIdx) := graphInfoIn;
  nameAttrIdx := listGet(attributeIdcs,1);
  typeAttIdx := listGet(attributeIdcs,2); // if its a tearingvar or not
  idxAttrIdx:= listGet(attributeIdcs,3);
  isTearVar := Util.tuple21(listGet(attsIn,indx));
  daeIdxStr := Util.tuple22(listGet(attsIn,indx));
  typeStr := if isTearVar then "tearingVar" else "otherVar";
  var := BackendVariable.getVarAt(vars,indx);
  varString := BackendDump.varString(var);
  varNodeId := getVarNodeIdx(indx);
  idxString := intString(indx);
  nodeLabel := GraphML.NODELABEL_INTERNAL(idxString,NONE(),GraphML.FONTPLAIN());
  (graphInfo,_) := GraphML.addNode(varNodeId, GraphML.COLOR_ORANGE2, {nodeLabel},GraphML.ELLIPSE(),SOME(varString),{(nameAttrIdx,varString),(typeAttIdx,typeStr),(idxAttrIdx,daeIdxStr)},graphIdx,graphInfo);
  graphInfoOut := (graphInfo,graphIdx);
end addVarNodeToGraph;

protected function addEqNodeToGraph "adds a node for an equation to the graph.
author:Waurich TUD 2013-12"
  input Integer indx;
  input BackendDAE.EquationArray eqs;
  input list<tuple<Boolean,String>> attsIn; // <isResEq,"daeIdx">
  input list<Integer> attributeIdcs;//<name,type>
  input tuple<GraphML.GraphInfo,Integer> graphInfoIn;
  output tuple<GraphML.GraphInfo,Integer> graphInfoOut;
protected
  BackendDAE.Equation eq;
  Boolean isResEq;
  Integer nameAttrIdx,typeAttrIdx,idxAttrIdx,  graphIdx;
  String eqString, eqNodeId, idxString, typeStr, daeIdxStr;
  list<String> eqChars;
  GraphML.GraphInfo graphInfo;
  GraphML.NodeLabel nodeLabel;
algorithm
  (graphInfo,graphIdx) := graphInfoIn;
  nameAttrIdx := listGet(attributeIdcs,1);
  typeAttrIdx := listGet(attributeIdcs,2); // if its a residual or not
  idxAttrIdx := listGet(attributeIdcs,3);
  isResEq := Util.tuple21(listGet(attsIn,indx));
  daeIdxStr := Util.tuple22(listGet(attsIn,indx));
  typeStr := if isResEq then "residualEq" else "otherEq";
  {eq} := BackendEquation.getEqns({indx}, eqs);
  eqString := BackendDump.equationString(eq);
  eqNodeId := getEqNodeIdx(indx);
  idxString := intString(indx);
  nodeLabel := GraphML.NODELABEL_INTERNAL(idxString,NONE(),GraphML.FONTPLAIN());
  (graphInfo,_) := GraphML.addNode(eqNodeId,GraphML.COLOR_GREEN2,{nodeLabel},GraphML.RECTANGLE(),SOME(eqString),{(nameAttrIdx,eqString),(typeAttrIdx,typeStr),(idxAttrIdx,daeIdxStr)},graphIdx,graphInfo);
  graphInfoOut := (graphInfo,graphIdx);
end addEqNodeToGraph;

protected function addEdgeToGraph "adds an edge to the graph by traversing the incidence matrix.
author:Waurich TUD 2013-12"
  input Integer eqIdx;
  input BackendDAE.IncidenceMatrix m;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
  list<Integer> varLst;
algorithm
  varLst := arrayGet(m,eqIdx);
  graphInfoOut := List.fold1(varLst,addEdgeToGraph2,eqIdx,graphInfoIn);
end addEdgeToGraph;

protected function addEdgeToGraph2 "helper for addEdgeToGraph.
author:Waurich TUD 2013-12"
  input Integer varIdxIn;
  input Integer eqIdx;
  input GraphML.GraphInfo graphInfoIn;
  output GraphML.GraphInfo graphInfoOut;
protected
  Integer varIdx;
  String eqNodeId, varNodeId;
  GraphML.LineType lt;
algorithm
  if varIdxIn <= 0 then lt := GraphML.DASHED(); else lt := GraphML.LINE(); end if;
  varIdx := intAbs(varIdxIn);
  eqNodeId := getEqNodeIdx(eqIdx);
  varNodeId := getVarNodeIdx(varIdx);
  (graphInfoOut,_) := GraphML.addEdge("Edge_"+intString(varIdx)+"_"+intString(eqIdx),varNodeId,eqNodeId,GraphML.COLOR_BLACK,lt,GraphML.LINEWIDTH_STANDARD,false,{},(GraphML.ARROWNONE(),GraphML.ARROWNONE()),{}, graphInfoIn);
end addEdgeToGraph2;

protected function getVarNodeIdx "outputs the identifier string for the given varIdx.
author:Waurich TUD 2013-12"
  input Integer idx;
  output String varString;
algorithm
  varString := "varNode"+intString(intAbs(idx));
end getVarNodeIdx;

protected function getEqNodeIdx "outputs the identifier string for the given eqIdx.
author:Waurich TUD 2013-12"
  input Integer idx;
  output String eqString;
algorithm
  eqString := "eqNode"+intString(intAbs(idx));
end getEqNodeIdx;

annotation(__OpenModelica_Interface="backend");
end BackendDump;
