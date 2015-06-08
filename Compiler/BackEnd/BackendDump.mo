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

  RCS: $Id$

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
protected import BackendDAETransform;
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
  input BackendDAE.EqSystem inEqSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrix> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars,
                      orderedEqs=orderedEqs,
                      m=m,
                      mT=mT,
                      matching=matching,
                      stateSets=stateSets,
                      partitionKind=partitionKind) := inEqSystem;

  print("\n" + partitionKindString(partitionKind) + " partition\n" + UNDERLINE + "\n");
  dumpVariables(orderedVars, "Variables");
  dumpEquationArray(orderedEqs, "Equations");
  dumpStateSets(stateSets, "State Sets");
  dumpOption(m, dumpIncidenceMatrix);
  dumpOption(mT, dumpIncidenceMatrixT);

  print("\n");
  dumpFullMatching(matching);
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
protected
  BackendDAE.Variables knownVars, externalObjects, aliasVars;
  BackendDAE.EquationArray initialEqs, removedEqs;
  list<DAE.Constraint> constraints;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst, sampleLst, relationsLst;
  list<BackendDAE.WhenClause> whenClauseLst;
  list<BackendDAE.TimeEvent> timeEvents;
  BackendDAE.ExternalObjectClasses extObjClasses;
  BackendDAE.BackendDAEType backendDAEType;
  BackendDAE.SymbolicJacobians symjacs;
algorithm
  BackendDAE.SHARED(knownVars=knownVars,
                    externalObjects=externalObjects,
                    aliasVars=aliasVars,
                    initialEqs=initialEqs,
                    removedEqs=removedEqs,
                    constraints=constraints,
                    eventInfo=BackendDAE.EVENT_INFO(timeEvents=timeEvents, relationsLst=relationsLst, zeroCrossingLst=zeroCrossingLst, sampleLst=sampleLst, whenClauseLst=whenClauseLst),
                    extObjClasses=extObjClasses,
                    backendDAEType=backendDAEType,
                    symjacs=symjacs) := inShared;
  print("\nBackendDAEType: ");
  printBackendDAEType(backendDAEType);
  print("\n\n");

  dumpVariables(knownVars, "Known Variables (constants)");
  dumpVariables(externalObjects, "External Objects");
  dumpExternalObjectClasses(extObjClasses, "Classes of External Objects");
  dumpVariables(aliasVars, "Alias Variables");
  dumpEquationArray(removedEqs, "Simple Equations");
  dumpEquationArray(initialEqs, "Initial Equations");
  dumpZeroCrossingList(zeroCrossingLst, "Zero Crossings");
  dumpZeroCrossingList(relationsLst, "Relations");
  if stringEqual(Config.simCodeTarget(), "Cpp") then
    dumpZeroCrossingList(sampleLst, "Samples");
  else
    dumpTimeEvents(timeEvents, "Time Events");
  end if;
  dumpWhenClauseList(whenClauseLst, "When Clauses");
  dumpConstraintList(constraints, "Constraints");
end printShared;

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

protected function printStateSet "author: Frenkel TUD"
  input BackendDAE.StateSet statSet;
protected
  Integer rang;
  list<BackendDAE.Var> states;
  list<DAE.ComponentRef> crstates;
algorithm
  BackendDAE.STATESET(rang=rang,statescandidates=states) := statSet;
  crstates := List.map(states,BackendVariable.varCref);
  print("StateSet: select " + intString(rang) + " from\n");
  debuglst(crstates,ComponentReference.printComponentRefStr,"\n","\n");
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
      paths = DAEUtil.getElementSourceTypes(source);
      paths_lst = List.map(paths, Absyn.pathString);
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

protected constant String BORDER    = "########################################";
protected constant String UNDERLINE = "========================================";

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

public function dumpEqSystem "function dumpEqSystem"
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

protected function dumpWhenClauseList
  input list<BackendDAE.WhenClause> inWhenClauseList;
  input String heading;
algorithm
  print("\n" + heading + " (" + intString(listLength(inWhenClauseList)) + ")\n" + UNDERLINE + "\n");
  print(whenClauseListString(inWhenClauseList));
  print("\n");
end dumpWhenClauseList;

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
algorithm
  (pattern, _, (diffVars, diffedVars)) := inPattern;

  print("\n" + heading + "\n" + UNDERLINE + "\n");
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

    case (BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(right=e/*TODO handle elsewhe also*/),  attr=BackendDAE.EQUATION_ATTRIBUTES(kind=eqKind))::res, _) equation
      print("WHEN_EQUATION: ");
      str = ExpressionDump.printExpStr(e);
      print(str);
      str = str + " (" + equationKindString(eqKind) + ")\n";
      str = ExpressionDump.dumpExpStr(e,0);
      str = if printExpTree then str else "";
      print(str);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
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
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.JacobianType jacType;
      list<tuple<Integer,list<Integer>>> eqnsvartpllst,eqnsvartpllst2;
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
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst,residualequations=elst,otherEqnVarTpl=eqnsvartpllst),NONE(),linear=b)::rest,_,_)
      equation
        s = if b then "linear" else "nonlinear";
        print("torn " + s + " Equationsystem:\n");
        vlst1 = List.flatten(List.map(eqnsvartpllst,Util.tuple22));
        elst1 = List.map(eqnsvartpllst,Util.tuple21);
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
      then
        ();
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst,residualequations=elst,otherEqnVarTpl=eqnsvartpllst),SOME(BackendDAE.TEARINGSET(tearingvars=vlst2,residualequations=elst2,otherEqnVarTpl=eqnsvartpllst2)),linear=b)::rest,_,_)
      equation
        s = if b then "linear" else "nonlinear";
        print("Strict torn " + s + " Equationsystem:\n");
        vlst1 = List.flatten(List.map(eqnsvartpllst,Util.tuple22));
        elst1 = List.map(eqnsvartpllst,Util.tuple21);
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
        vlst1 = List.flatten(List.map(eqnsvartpllst2,Util.tuple22));
        elst1 = List.map(eqnsvartpllst2,Util.tuple21);
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
      list<tuple<Integer,list<Integer>>> eqnvartpllst,eqnvartpllst2;
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
    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=ilst,tearingvars=vlst,otherEqnVarTpl=eqnvartpllst),NONE(),linear=b)
      equation
        ls = List.map(eqnvartpllst, tupleString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(ilst, intString);
        s2 = stringDelimitList(ls, ", ");
        ls = List.map(vlst, intString);
        s3 = stringDelimitList(ls, ", ");
        s4 = if b then "linear" else "nonlinear";
        tmpStr = "{{" + s + "}\n,{" + s2 + ":" + s3 + "}} Size: " + intString(listLength(vlst)) + " " + s4 + "\n";
      then tmpStr;
    case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=ilst,tearingvars=vlst,otherEqnVarTpl=eqnvartpllst),SOME(BackendDAE.TEARINGSET(residualequations=ilst2,tearingvars=vlst2,otherEqnVarTpl=eqnvartpllst2)),linear=b)
      equation
        ls = List.map(eqnvartpllst, tupleString);
        s = stringDelimitList(ls, ", ");
        ls = List.map(ilst, intString);
        s2 = stringDelimitList(ls, ", ");
        ls = List.map(vlst, intString);
        s3 = stringDelimitList(ls, ", ");
        s4 = if b then "linear" else "nonlinear";
        tmpStr = "{{" + s + "}\n,{" + s2 + ":" + s3 + "}} Size: " + intString(listLength(vlst)) + " " + s4 + " (strict tearing set)\n";
        ls = List.map(eqnvartpllst2, tupleString);
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

// =============================================================================
// section for all *String functions
//
// These are functions, that return their output with a String.
//   - componentRef_DIVISION_String
//   - equationString
//   - strongComponentString
//   - whenClauseString
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
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
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
   case BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(residualequations=ilst,tearingvars=vlst,otherEqnVarTpl=eqnvartpllst),linear=b)
      equation
        ls = List.map(eqnvartpllst, tupleString);
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

protected function whenEquationString "Helper function to equationString"
  input BackendDAE.WhenEquation inWhenEqn;
  output String outString;
algorithm
  outString := match (inWhenEqn)
    local
      String s1,s2,res,s3,cs;
      DAE.Exp e2,cond;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
    case (BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2, elsewhenPart = SOME(weqn)))
      equation
        s1 = whenEquationString(weqn);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(cond);
        cs = ComponentReference.printComponentRefStr(cr);
        res = stringAppendList({"elsewhen ",s3," then\n  ",cs, " := ",s2,"\n", s1});
      then
        res;
    case (BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2, elsewhenPart = NONE()))
      equation
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(cond);
        cs = ComponentReference.printComponentRefStr(cr);
        res = stringAppendList({"elsewhen ",s3," then\n  ",cs, " := ",s2,"\n"});
      then
        res;
  end match;
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
    case (BackendDAE.EQUATION(exp = e1,scalar = e2, attr=attr))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = printEqAtts(attr);
        res = stringAppendList({s1," = ",s2," ",s3});
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
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2, elsewhenPart = SOME(weqn))))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = whenEquationString(weqn);
        s4 = ExpressionDump.printExpStr(cond);
        res = stringAppendList({"when ",s4," then\n  ",s1," := ",s2,"\n",s3,"end when"});
      then
        res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(condition=cond,left = cr,right = e2)))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        s4 = ExpressionDump.printExpStr(cond);
        res = stringAppendList({"when ",s4," then\n  ",s1," := ",s2,"\nend when"});
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
      list<String> eq_s_list,wc_s_list;
      String eq_s,wc_s,str,str2,str_index;
      DAE.Exp e;
      Integer index_;
      list<Integer> eq,wc;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.RELATION(index=index_),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str_index=intString(index_);
      str2 = stringAppendList({str," with index = ",str_index," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.LBINARY(),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.LUNARY(),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.CALL(path = Absyn.IDENT()),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
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

protected function whenClauseListString "function whenClauseListString"
  input list<BackendDAE.WhenClause> inWhenClauseList;
  output String outString;
protected
  list<String> strList;
algorithm
  strList := List.map(inWhenClauseList, whenClauseString);
  outString := stringDelimitList(strList, ",\n");
end whenClauseListString;

public function whenClauseString "Dumps a whenclause into a string, for debugging purposes."
  input BackendDAE.WhenClause inWhenClause;
  output String outString;
algorithm
  outString:= match(inWhenClause)
    local
      String sc,s1,si,str;
      DAE.Exp c;
      list<BackendDAE.WhenOperator> reinitStmtLst;
      Integer i;

    case BackendDAE.WHEN_CLAUSE(condition = c,reinitStmtLst = reinitStmtLst,elseClause = SOME(i)) equation
      sc = ExpressionDump.printExpStr(c);
      s1 = stringDelimitList(List.map(reinitStmtLst,dumpWhenOperatorStr),"  ");
      si = intString(i);
      str = stringAppendList({" whenclause = ",sc," then ",s1," else whenclause",si});
    then str;

    case BackendDAE.WHEN_CLAUSE(condition = c,reinitStmtLst = reinitStmtLst,elseClause = NONE()) equation
      sc = ExpressionDump.printExpStr(c);
      s1 = stringDelimitList(List.map(reinitStmtLst,dumpWhenOperatorStr),"  ");
      str = stringAppendList({" whenclause = ",sc," then ",s1});
    then str;

    else "";
  end match;
end whenClauseString;

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

public function dumpTypeStr
"Dump BackendDAE.Type to a string."
  input BackendDAE.Type inType;
  output String outString;
algorithm
  outString:=
  match (inType)
    local
      String s1,s2,str;
      list<String> l;
    case DAE.T_INTEGER() then "Integer ";
    case DAE.T_REAL() then "Real ";
    case DAE.T_BOOL() then "Boolean ";
    case DAE.T_STRING() then "String ";

    case DAE.T_ENUMERATION(names = l)
      equation
        s1 = stringDelimitList(l, ", ");
        s2 = stringAppend("enumeration(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)) then "ExternalObject ";
    case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)) then "Record ";
    case DAE.T_ARRAY() then "Array ";
  end match;
end dumpTypeStr;

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
      dumpBackendDAE(dae,"Jacobian System");
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
  DAE.ComponentRef cr;
  BackendDAE.VarKind kind;
  DAE.VarDirection dir;
  BackendDAE.Type var_type;
  DAE.InstDims arrayDim;
  Option<DAE.Exp> bindExp;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> dae_var_attr;
  Option<SCode.Comment> comment;
  DAE.ConnectorType ct;
  list<Absyn.Path> paths;
  list<String> paths_lst;
  String path_str;
  Boolean unreplaceable;
  String unreplaceableStr;
algorithm
  BackendDAE.VAR(varName=cr,
                 varKind=kind,
                 varDirection=dir,
                 varType=var_type,
                 arryDim=arrayDim,
                 bindExp=bindExp,
                 source=source,
                 values=dae_var_attr,
                 comment=comment,
                 connectorType=ct,
                 unreplaceable=unreplaceable) := inVar;
  paths := DAEUtil.getElementSourceTypes(source);
  paths_lst := List.map(paths, Absyn.pathString);
  unreplaceableStr := if unreplaceable then " unreplaceable" else "";
  outStr := DAEDump.dumpDirectionStr(dir) + ComponentReference.printComponentRefStr(cr) + ":"
            + kindString(kind) + "(" + connectorTypeString(ct) + attributesString(dae_var_attr)
            + ") " + optExpressionString(bindExp,"") + DAEDump.dumpCommentAnnotationStr(comment)
            + stringDelimitList(paths_lst, ", ") + " type: " + dumpTypeStr(var_type) + "["+ExpressionDump.dimensionsString(arrayDim) + "]" + unreplaceableStr;
end varString;

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

protected function partitionKindString
  input BackendDAE.BaseClockPartitionKind inPartitionKind;
  output String outString;
algorithm
  outString := match(inPartitionKind)
    case BackendDAE.CLOCKED_PARTITION() then "clocked";
    case BackendDAE.CONTINUOUS_TIME_PARTITION() then "continuous time";
    case BackendDAE.UNSPECIFIED_PARTITION() then "unspecified";
    case BackendDAE.UNKNOWN_PARTITION() then "unknown";
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
  Integer subPartitionIndex;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(kind=kind, subPartitionIndex=subPartitionIndex) := inEqAttr;
  outString := "[" + equationKindString(kind);
  outString := if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then (outString + ", sub-partition index: " + subPartitionString(subPartitionIndex)) else outString;
  outString := outString + "]";
end equationAttrString;

protected function subPartitionString
  input Integer inSubPartitionIndex;
  output String outString;
algorithm
  outString := match inSubPartitionIndex
    case 0 then "unknown";
    else intString(inSubPartitionIndex);
  end match;
end subPartitionString;

protected function equationKindString
  input BackendDAE.EquationKind inEqKind;
  output String outString;
algorithm
  outString := match(inEqKind)
    case BackendDAE.BINDING_EQUATION() then "binding";
    case BackendDAE.DYNAMIC_EQUATION() then "dynamic";
    case BackendDAE.INITIAL_EQUATION() then "initial";
    case BackendDAE.UNKNOWN_EQUATION_KIND() then "unknown";
    else equation
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
  print("Incidence Matrix (row == equation)\n");
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
  print("Transpose Incidence Matrix (row == var)\n");
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
      String s,s1;
      Integer x;
      BackendDAE.Solvability solva;
      BackendDAE.AdjacencyMatrixElementEnhanced xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case (((x,solva) :: xs))
      equation
        s = intString(x);
        s1 = dumpSolvability(solva);
        print("(" + s + "," + s1 + ")");
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
    case BackendDAE.SOLVABILITY_CONST() then "const";
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

protected function tupleString
  input tuple<Integer, list<Integer>> iTpl;
  output String s;
protected
  Integer e;
  list<Integer> v;
algorithm
  (e,v) := iTpl;
  s := stringDelimitList(List.map(v,intString), ", ");
  s := "{"+intString(e)+":"+s+"}";
end tupleString;

protected type DumpCompShortSystemsTpl = tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>;
protected type DumpCompShortMixedTpl = tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>;
protected type DumpCompShortTornTpl = tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>;

public function dumpCompShort
  input BackendDAE.BackendDAE inDAE;
protected
  Integer sys,inp,st,dvar,dst,seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys,strcomps;
  list<Integer> e_jc,e_jn,e_nj;
  list<tuple<Integer,Integer>> te_l,te_nl;
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
  DumpCompShortTornTpl tornTpl;
  BackendDAE.BackendDAEType backendDAEType;
algorithm
  BackendDAE.DAE(systs, BackendDAE.SHARED(removedEqs=removedEqs, backendDAEType=backendDAEType)) := inDAE;
  daeType := printBackendDAEType2String(backendDAEType);

  HS := HashSet.emptyHashSet();
  HS := List.fold(systs, Initialization.collectPreVariablesEqSystem, HS);
  ((_,HS)) := BackendDAEUtil.traverseBackendDAEExpsEqns(removedEqs, Expression.traverseSubexpressionsHelper, (Initialization.collectPreVariablesTraverseExp, HS));
  discstates := BaseHashSet.hashSetList(HS);
  dst := listLength(discstates);

  ((sys,inp,st,states,dvar,discvars,seq,salg,sarr,sce,swe,sie,systemsTpl,mixedTpl,tornTpl)) := BackendDAEUtil.foldEqSystem(inDAE,dumpCompShort1,(0,0,0,{},0,{},0,0,0,0,0,0,({},{},{},{}),({},{},{},{},{},{},{},{},{},{}),({},{})));
  (e_jc,e_jt,e_jn,e_nj) := systemsTpl;
  (m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt) := mixedTpl;
  (te_l,te_nl) := tornTpl;
  eqsys := listLength(e_jc)+listLength(e_jt)+listLength(e_jn)+listLength(e_nj);
  meqsys := listLength(m_se)+listLength(m_sarr)+listLength(m_salg)+listLength(m_sec)+listLength(me_jc)+listLength(me_jt)+listLength(me_jn)+listLength(me_nj)+listLength(me_lt)+listLength(me_nt);
  teqsys := listLength(te_l)+listLength(te_nl);
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
    dumpCompTorn(tornTpl);
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
protected
  list<tuple<Integer,Integer>> te_l,te_nl;
  String s_l,s_nl;
algorithm
  (te_l,te_nl) := systemsTpl;
  s_l := equationSizesStr(te_l,intTplString);
  s_nl := equationSizesStr(te_nl,intTplString);
  Error.addMessage(Error.BACKENDDAEINFO_TORN, {s_l,s_nl});
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
  input tuple<Integer,Integer,Integer,list<DAE.ComponentRef>,Integer,list<DAE.ComponentRef>,Integer,Integer,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> inTpl;
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
       DumpCompShortTornTpl> outTpl;
protected
  BackendDAE.Variables vars;
  BackendDAE.StrongComponents comps;
  Integer sys,inp,st,dvar,seq,salg,sarr,sce,swe,sie,inp1,st1,dvar1,seq1,salg1,sarr1,sce1,swe1,sie1;
  tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>> eqsys,eqsys1;
  tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> meqsys,meqsys1;
  tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> teqsys,teqsys1;
  list<DAE.ComponentRef> states,states1,discvars,discvars1;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars) := inSyst;
  (sys, inp, st, states, dvar, discvars, seq, salg, sarr, sce, swe, sie, eqsys, meqsys, teqsys) := inTpl;

  ((inp1,st1,states1,dvar1,discvars1)) := BackendVariable.traverseBackendDAEVars(vars,traversingisStateTopInputVarFinder,(inp,st,states,dvar,discvars));
  comps := BackendDAEUtil.getStrongComponents(inSyst);
  ((seq1,salg1,sarr1,sce1,swe1,sie1,eqsys1,meqsys1,teqsys1)) := List.fold(comps,dumpCompShort2,(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys));

  outTpl := ((sys+1, inp1, st1, states1, dvar1, discvars1, seq1, salg1, sarr1, sce1, swe1, sie1, eqsys1, meqsys1, teqsys1));
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
  input tuple<Integer,Integer,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> inTpl;
  output tuple<Integer,Integer,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> outTpl;
algorithm
  outTpl := match (inComp,inTpl)
    local
      Integer e,d,nnz;
      list<Integer> ilst,ilst1;
      Integer seq,salg,sarr,sce,swe,sie;
      list<Integer> e_jc,e_jn,e_nj,m_se,m_salg,m_sarr,m_sec;
      list<tuple<Integer,Integer>> e_jt,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt,te_l,te_nl;
      tuple<list<Integer>,list<tuple<Integer,Integer>>,list<Integer>,list<Integer>> eqsys;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> meqsys;
      tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> teqsys;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;

    case (BackendDAE.SINGLEEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys))
    then ((seq+1,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys));

    case (BackendDAE.SINGLEARRAY(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys))
    then ((seq,salg,sarr+1,sce,swe,sie,eqsys,meqsys,teqsys));

    case (BackendDAE.SINGLEIFEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys))
    then ((seq,salg,sarr,sce,swe,sie+1,eqsys,meqsys,teqsys));

    case (BackendDAE.SINGLEALGORITHM(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys))
    then ((seq,salg+1,sarr,sce,swe,sie,eqsys,meqsys,teqsys));

    case (BackendDAE.SINGLECOMPLEXEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys))
    then((seq,salg,sarr,sce+1,swe,sie,eqsys,meqsys,teqsys));

    case (BackendDAE.SINGLEWHENEQUATION(),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,teqsys))
    then ((seq,salg,sarr,sce,swe+1,sie,eqsys,meqsys,teqsys));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_CONSTANT()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys)) equation
        e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e::e_jc,e_jt,e_jn,e_nj),meqsys,teqsys));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jac=BackendDAE.FULL_JACOBIAN(SOME(jac)),jacType=BackendDAE.JAC_LINEAR()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys))
      equation
        e = listLength(ilst);
        nnz = listLength(jac);
      then ((seq,salg,sarr,sce,swe,sie,(e_jc,(e,nnz)::e_jt,e_jn,e_nj),meqsys,teqsys));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_NONLINEAR()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys)) equation
      e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e::e_jn,e_nj),meqsys,teqsys));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_GENERIC()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys)) equation
      e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e::e_jn,e_nj),meqsys,teqsys));

    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_NO_ANALYTIC()),(seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys)) equation
      e = listLength(ilst);
    then ((seq,salg,sarr,sce,swe,sie,(e_jc,e_jt,e_jn,e::e_nj),meqsys,teqsys));

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,otherEqnVarTpl=eqnvartpllst),linear=true),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl))) equation
      d = listLength(ilst);
      e = listLength(eqnvartpllst);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,((d,e)::te_l,te_nl)));

    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=ilst,otherEqnVarTpl=eqnvartpllst),linear=false),(seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,te_nl))) equation
      d = listLength(ilst);
      e = listLength(eqnvartpllst);
    then ((seq,salg,sarr,sce,swe,sie,eqsys,meqsys,(te_l,(d,e)::te_nl)));

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

protected function printEqAtts
  input BackendDAE.EquationAttributes atts;
  output String s;
protected
  BackendDAE.LoopInfo li;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(loopInfo=li) := atts;
  s := printLoopInfoStr(li);
end printEqAtts;

public function printLoopInfoStr"outputs a string representation of a loopInfo"
  input BackendDAE.LoopInfo loopInfoIn;
  output String s;
algorithm
  s := match(loopInfoIn)
    local
      String s1,s2,s3;
      String loopId;
      Integer id;
      DAE.Exp startIt;
      DAE.Exp endIt;
      list<BackendDAE.IterCref> crefs;
  case(BackendDAE.LOOP(loopId=id, startIt=startIt, endIt=endIt, crefs=crefs))
    equation
      s1 = "LOOP"+intString(id)+":";
      s2 = "[ "+ExpressionDump.printExpStr(startIt)+"->"+ExpressionDump.printExpStr(endIt)+" ] ";
      s3 = stringDelimitList(List.map(crefs,printIterCrefStr),"| ");
  then s1+s2+s3;
  case(_)
    then "";
  end match;
end printLoopInfoStr;

public function printIterCrefStr"outputs a string representation of a IterCref"
  input BackendDAE.IterCref itCref;
  output String s;
algorithm
  s := match(itCref)
    local
      DAE.ComponentRef cref;
      DAE.Exp it;
      DAE.Operator op;
    case(BackendDAE.ITER_CREF(cref=cref, iterator=it))
      equation
        then "{"+ComponentReference.printComponentRefStr(cref)+" :iter["+ExpressionDump.printExpStr(it)+"]}";
    case(BackendDAE.ACCUM_ITER_CREF(cref=cref, op=op))
      equation
        then "ACCUM{"+ComponentReference.printComponentRefStr(cref)+" :op["+DAEDump.dumpOperatorString(op)+"]}";
  end match;
end printIterCrefStr;

annotation(__OpenModelica_Interface="backend");
end BackendDump;
