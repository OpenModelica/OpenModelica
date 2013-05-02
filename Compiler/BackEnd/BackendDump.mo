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

encapsulated package BackendDump
" file:  BackendDump.mo
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

protected import Absyn;
protected import Algorithm;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import BackendEquation;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import DumpHTML;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import IOStream;
protected import List;
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

public function printBackendDAE "function printBackendDAE
  This function dumps the BackendDAE.BackendDAE representaton to stdout."
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

public function printEqSystem "function printEqSystem
  This function prints the BackendDAE.EqSystem representaton to stdout."
  input BackendDAE.EqSystem inEqSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrix> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars,
                orderedEqs=orderedEqs,
                m=m,
                mT=mT,
                matching=matching,
                stateSets=stateSets) := inEqSystem;

  dumpVariables(orderedVars, "Variables");
  dumpEquationArray(orderedEqs, "Equations");
  dumpStateSets(stateSets, "State Sets");
  dumpOption(m, dumpIncidenceMatrix);
  dumpOption(mT, dumpIncidenceMatrixT);

  print("\n");
  dumpFullMatching(matching);
end printEqSystem;

public function printEquation "function printEquation
  author: PA
  Helper function to print_equations"
  input BackendDAE.Equation inEquation;
algorithm
  print(equationString(inEquation) +& "\n");
end printEquation;

public function printEquationArray "function printEquationArray
  Helper function to dump."
  input BackendDAE.EquationArray eqns;
algorithm
  _ := List.fold(BackendEquation.equationList(eqns), printEquationList2, (1, 1));
end printEquationArray;

public function printEquationList "function printEquationList
  Helper function to dump."
  input list<BackendDAE.Equation> eqns;
algorithm
  _ := List.fold(eqns, printEquationList2, (1, 1));
end printEquationList;

protected function printEquationList2 "function printEquationList2
  Helper function for printEquationArray and printEquationList"
  input BackendDAE.Equation inEquation;
  input tuple<Integer,Integer> inInteger;
  output tuple<Integer,Integer> oInteger;
protected
  Integer iscalar,i,size;
algorithm
  (i,iscalar) := inInteger;
  size := BackendEquation.equationSize(inEquation);
  print(intString(i) +& "/" +& intString(iscalar) +& " (" +& intString(size) +& "): " +& equationString(inEquation) +& "\n");
  oInteger := (i + 1,iscalar + size);
end printEquationList2;

public function printEquations "function printEquations
  "
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

protected function printEquationNo "function printEquationNo
  author: PA
  Helper function to printEquations"
  input Integer inInteger;
  input BackendDAE.EqSystem syst;
algorithm
  _:=
  match (inInteger,syst)
    local
      Integer eqno_1,eqno;
      BackendDAE.Equation eq;
      BackendDAE.EquationArray eqns;
    case (eqno,BackendDAE.EQSYSTEM(orderedEqs = eqns))
      equation
  eqno_1 = eqno - 1;
  eq = BackendDAEUtil.equationNth(eqns, eqno_1);
  printEquation(eq);
      then
  ();
  end match;
end printEquationNo;

public function printClassAttributes "function printClassAttributes
  This unction print the  Optimica ClassAttributes: objetiveE, objetiveE"
  input DAE.ClassAttributes optimicaFun;
  protected
    Option<DAE.Exp> e1,e2;
  algorithm
    DAE.OPTIMIZATION_ATTRS(objetiveE = e1, objectiveIntegrandE = e2) := optimicaFun;
    print("Mayer" +& "\n" +& UNDERLINE +& "\n\n");
    print(ExpressionDump.printOptExpStr(e1));
    print("Lagrange" +& "\n" +& UNDERLINE +& "\n\n");
    print(ExpressionDump.printOptExpStr(e2));
    print("\n");
end printClassAttributes;

public function printShared "function printShared
  This function dumps the BackendDAE.Shared representaton to stdout."
  input BackendDAE.Shared inShared;
protected
  BackendDAE.Variables knownVars, externalObjects, aliasVars;
  BackendDAE.EquationArray initialEqs, removedEqs;
  array<DAE.Constraint> constraints;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst, sampleLst;
  list<BackendDAE.WhenClause> whenClauseLst;
  Integer relationsNumber;
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
              eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst=zeroCrossingLst, sampleLst=sampleLst, whenClauseLst=whenClauseLst, relationsNumber=relationsNumber),
              extObjClasses=extObjClasses,
              backendDAEType=backendDAEType,
              symjacs=symjacs) := inShared;
  print("\nBackendDAEType: ");
  printBackendDAEType(backendDAEType);
  print("\n\n");

  dumpVariables(knownVars, "Known Variables (constants)");
  dumpVariables(externalObjects, "External Objects");
  dumpExternalObjectClasses(extObjClasses, "Classes of External Objects");
  dumpVariables(aliasVars, "AliasVariables");
  dumpEquationArray(removedEqs, "Simple Equations");
  dumpEquationArray(initialEqs, "Initial Equations");
  dumpZeroCrossingList(zeroCrossingLst, "Zero Crossings (number of relations: " +& intString(relationsNumber) +& ")");
  dumpZeroCrossingList(sampleLst, "Samples");
  dumpWhenClauseList(whenClauseLst, "When Clauses");
  dumpConstraintArray(constraints, "Constraints");
end printShared;

protected function printBackendDAEType "function printBackendDAEType
  This is a helper for printShared."
  input BackendDAE.BackendDAEType btp;
algorithm
  _ := match(btp)
    case (BackendDAE.SIMULATION()) equation print("simulation"); then ();
    case (BackendDAE.JACOBIAN()) equation print("jacobian"); then ();
    case (BackendDAE.ALGEQSYSTEM()) equation print("algebraic loop"); then ();
    case (BackendDAE.ARRAYSYSTEM()) equation print("multidim equation arrays"); then ();
    case (BackendDAE.PARAMETERSYSTEM()) equation print("parameter system"); then ();
    case (BackendDAE.INITIALSYSTEM()) equation print("initial system"); then ();
  end match;
end printBackendDAEType;

public function printStateSets "function printStateSets
  author: Frenkel TUD"
  input BackendDAE.StateSets stateSets;
algorithm
  List.map_0(stateSets, printStateSet);
end printStateSets;

protected function printStateSet "function printStateSet
  author: Frenkel TUD"
  input BackendDAE.StateSet statSet;
protected
  Integer rang;
  list<BackendDAE.Var> states;
  list<DAE.ComponentRef> crstates;
algorithm
  BackendDAE.STATESET(rang=rang,statescandidates=states) := statSet;
  crstates := List.map(states,BackendVariable.varCref);
  print("StateSet: select " +& intString(rang) +& " from\n");
  debuglst((crstates,ComponentReference.printComponentRefStr,"\n","\n"));
end printStateSet;

public function printVar "function printVar
  "
  input BackendDAE.Var inVar;
algorithm
  print(varString(inVar) +& "\n");
end printVar;

public function printVariables "function printVariables
  Helper function to dump."
  input BackendDAE.Variables vars;
algorithm
  _ := List.fold(BackendVariable.varList(vars), printVars1, 1);
end printVariables;

public function printVarList "function printVarList
  Helper function to dump."
  input list<BackendDAE.Var> vars;
algorithm
  _ := List.fold(vars, printVars1, 1);
end printVarList;

protected function printVars1 "function printVars1
  This is a helper function for printVariables and printVarList"
  input BackendDAE.Var inVar;
  input Integer inVarNo;
  output Integer outVarNo;
algorithm
  print(intString(inVarNo));
  print(": ");
  printVar(inVar);
  outVarNo := inVarNo + 1;
end printVars1;

protected function printExternalObjectClasses "function printExternalObjectClasses
  dump classes of external objects"
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

    case BackendDAE.EXTOBJCLASS(path,source)::xs equation
      print("class ");
      print(Absyn.pathString(path));
      print("\n  extends ExternalObject;");
      print("\n origin: ");
      paths = DAEUtil.getElementSourceTypes(source);
      paths_lst = List.map(paths, Absyn.pathString);
      path_str = stringDelimitList(paths_lst, ", ");
      print(path_str +& "\n");
      print("end ");print(Absyn.pathString(path));
    then ();
  end match;
end printExternalObjectClasses;

protected function printSparsityPattern "function printSparsityPattern
  author lochel"
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
      print(crStr +& " affects the following (" +& intString(listLength(crList)) +& ") outputs\n  ");
      ComponentReference.printComponentRefList(crList);

      printSparsityPattern(rest);
    then ();

    else
    then ();
  end matchcontinue;
end printSparsityPattern;

// =============================================================================
// section for all dump* functions
//
// These are functions, that print directly to the standard-stream and separates
// there output (e.g. with some kind of headings).
//   - dumpBackendDAE
//   - dumpBackendDAEEqnList
//   - dumpBackendDAEVarList
//   - dumpComponent
//   - dumpComponents
//   - dumpComponentsAdvanced
//   - dumpEqnsSolved
//   - dumpEqSystem
//   - dumpEquation
//   - dumpEquationArray
//   - dumpEquationList
//   - dumpSparsityPattern
//   - dumpTearing
//   - dumpVariables
//   - dumpVarList
// =============================================================================

protected constant String BORDER    = "########################################";
protected constant String UNDERLINE = "========================================";

public function dumpBackendDAE "function dumpBackendDAE
  This function dumps the BackendDAE.BackendDAE representaton to stdout."
  input BackendDAE.BackendDAE inBackendDAE;
  input String heading;
algorithm
  print("\n" +& BORDER +& "\n" +& heading +& "\n" +& BORDER +& "\n\n");
  printBackendDAE(inBackendDAE);
  print("\n");
end dumpBackendDAE;

public function dumpEqSystem "function dumpEqSystem"
  input BackendDAE.EqSystem inEqSystem;
  input String heading;
algorithm
  print("\n" +& heading +& "\n" +& UNDERLINE +& "\n");
  printEqSystem(inEqSystem);
  print("\n");
end dumpEqSystem;

public function dumpVariables "function dumpVariables"
  input BackendDAE.Variables inVars;
  input String heading;
algorithm
  print("\n" +& heading +& " (" +& intString(BackendVariable.varsSize(inVars)) +& ")\n" +& UNDERLINE +& "\n");
  printVariables(inVars);
  print("\n");
end dumpVariables;

public function dumpVarList "function dumpVarList"
  input list<BackendDAE.Var> inVars;
  input String heading;
algorithm
  print("\n" +& heading +& " (" +& intString(listLength(inVars)) +& ")\n" +& UNDERLINE +& "\n");
  printVarList(inVars);
  print("\n");
end dumpVarList;

public function dumpEquationArray "function dumpEquationArray"
  input BackendDAE.EquationArray inEqns;
  input String heading;
algorithm
  print("\n" +& heading +& " (" +& intString(listLength(BackendEquation.equationList(inEqns))) +& ", " +& intString(BackendDAEUtil.equationSize(inEqns)) +& ")\n" +& UNDERLINE +& "\n");
  printEquationArray(inEqns);
  print("\n");
end dumpEquationArray;

public function dumpEquationList "function dumpEquationList"
  input list<BackendDAE.Equation> inEqns;
  input String heading;
algorithm
  print("\n" +& heading +& " (" +& intString(listLength(inEqns)) +& ")\n" +& UNDERLINE +& "\n");
  printEquationList(inEqns);
  print("\n");
end dumpEquationList;

protected function dumpExternalObjectClasses "function dumpExternalObjectClasses
  dump classes of external objects"
  input BackendDAE.ExternalObjectClasses inEOC;
  input String heading;
algorithm
  print("\n" +& heading +& " (" +& intString(listLength(inEOC)) +& ")\n" +& UNDERLINE +& "\n");
  printExternalObjectClasses(inEOC);
  print("\n");
end dumpExternalObjectClasses;

protected function dumpStateSets
  input BackendDAE.StateSets stateSets;
  input String heading;
algorithm
  print("\n" +& heading +& "\n" +& UNDERLINE +& "\n");
  printStateSets(stateSets);
  print("\n");
end dumpStateSets;

protected function dumpZeroCrossingList "function dumpZeroCrossingList"
  input list<BackendDAE.ZeroCrossing> inZeroCrossingList;
  input String heading;
algorithm
  print("\n" +& heading +& "\n" +& UNDERLINE +& "\n");
  print(zeroCrossingListString(inZeroCrossingList));
  print("\n");
end dumpZeroCrossingList;

protected function dumpWhenClauseList "function dumpWhenClauseList"
  input list<BackendDAE.WhenClause> inWhenClauseList;
  input String heading;
algorithm
  print("\n" +& heading +& "\n" +& UNDERLINE +& "\n");
  print(whenClauseListString(inWhenClauseList));
  print("\n");
end dumpWhenClauseList;

protected function dumpConstraintArray "function dumpConstraintArray"
  input array<DAE.Constraint> inConstraintArray;
  input String heading;
algorithm
  print("\n" +& heading +& "\n" +& UNDERLINE +& "\n");
  dumpConstraints(arrayList(inConstraintArray), 0);
  print("\n");
end dumpConstraintArray;

public function dumpSparsityPattern "function dumpSparsityPattern
  author lochel"
  input BackendDAE.SparsePattern inPattern;
  input String heading;
protected
  list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>> pattern;
  list< .DAE.ComponentRef> diffVars, diffedVars;
algorithm
  (pattern, (diffVars, diffedVars)) := inPattern;

  print("\n" +& heading +& "\n" +& UNDERLINE +& "\n");
  print("independents [or inputs] (" +& intString(listLength(diffVars)) +& ")\n");
  ComponentReference.printComponentRefList(diffVars);

  print("dependents [or outputs] (" +& intString(listLength(diffedVars)) +& ")\n");
  ComponentReference.printComponentRefList(diffedVars);

  printSparsityPattern(pattern);
end dumpSparsityPattern;

public function dumpEquation "function dumpEquation
  author: Frenkel TUD"
  input BackendDAE.Equation inEquation;
algorithm
  _:=
  match (inEquation)
    local
      String s1,s2,res;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation w;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
  ExpressionDump.dumpExp(e1);
  print("=\n");
  ExpressionDump.dumpExp(e2);
      then
  ();
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1))
      equation
  ExpressionDump.dumpExp(e1);
  print("\n");
      then
  ();
    case (_)
      then
  ();
  end match;
end dumpEquation;

public function dumpTearing
" function: dumpTearing
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
   print(header +& "\n");
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

    case ({}, _) then ();
    case (BackendDAE.EQUATION(e1, e2, source, diffed)::res, printExpTree) equation /*done*/
      str = "EQUATION: ";
      str = str +& ExpressionDump.printExpStr(e1);
      str = str +& " = ";
      str = str +& ExpressionDump.printExpStr(e2);
      str = str +& "\n";
      print(str);

      str = "LHS:\n";
      str = str +& ExpressionDump.dumpExpStr(e1, 0);
      str = str +& "RHS:\n";
      str = str +& ExpressionDump.dumpExpStr(e2, 0);
      str = str +& "\n";
      str = Util.if_(printExpTree, str, "");
      print(str);

      dumpBackendDAEEqnList2(res, printExpTree);
    then ();
    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source)::res, printExpTree) equation /*done*/
      str = "COMPLEX_EQUATION: ";
      str = str +& ExpressionDump.printExpStr(e1);
      str = str +& " = ";
      str = str +& ExpressionDump.printExpStr(e2);
      str = str +& "\n";
      print(str);

      str = "LHS:\n";
      str = str +& ExpressionDump.dumpExpStr(e1, 0);
      str = str +& "RHS:\n";
      str = str +& ExpressionDump.dumpExpStr(e2, 0);
      str = str +& "\n";
      str = Util.if_(printExpTree, str, "");
      print(str);

      dumpBackendDAEEqnList2(res,printExpTree);
    then ();
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e,source=source)::res,printExpTree) equation
      print("SOLVED_EQUATION: ");
      str = ExpressionDump.printExpStr(e);
      print(str);
      print("\n");
      str = ExpressionDump.dumpExpStr(e,0);
      str = Util.if_(printExpTree,str,"");
      print(str);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();
    case (BackendDAE.RESIDUAL_EQUATION(exp=e,source=source)::res, printExpTree) equation /*done*/
      str = "RESIDUAL_EQUATION: ";
      str = str +& ExpressionDump.printExpStr(e);
      str = str +& "\n";
      print(str);

      str = ExpressionDump.dumpExpStr(e, 0);
      str = str +& "\n";
      str = Util.if_(printExpTree, str, "");
      print(str);

      dumpBackendDAEEqnList2(res, printExpTree);
    then ();
    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2,source=source)::res,printExpTree) equation
      print("ARRAY_EQUATION: ");
      str = ExpressionDump.printExpStr(e1);
      print(str);
      print("\n");
      str = ExpressionDump.dumpExpStr(e1,0);
      str = Util.if_(printExpTree,str,"");
      print(str);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();
    case (BackendDAE.ALGORITHM(alg=alg,source=source)::res,printExpTree) equation
      print("ALGORITHM: ");
      dumpAlgorithms({alg},0);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();
    case (BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(right=e/*TODO handle elsewhe also*/),source=source)::res, printExpTree) equation
      print("WHEN_EQUATION: ");
      str = ExpressionDump.printExpStr(e);
      print(str);
      print("\n");
      str = ExpressionDump.dumpExpStr(e,0);
      str = Util.if_(printExpTree,str,"");
      print(str);
      print("\n");
      dumpBackendDAEEqnList2(res,printExpTree);
    then ();
    case (_::res, printExpTree) equation
      print("SKIPED EQUATION\n");
      dumpBackendDAEEqnList2(res, printExpTree);
    then ();
  end matchcontinue;
end dumpBackendDAEEqnList2;

public function dumpBackendDAEVarList
  input list<BackendDAE.Var> inBackendDAEVarList;
  input String header;
algorithm
   print(header +& "\n");
   printVarList(inBackendDAEVarList);
   print("===================\n");
end dumpBackendDAEVarList;

public function dumpEqnsSolved "function dumpEqnsSolved
  This function dumps the equations in the order they have to be calculate."
  input BackendDAE.BackendDAE inBackendDAE;
protected
  BackendDAE.EqSystems eqs;
algorithm
  BackendDAE.DAE(eqs=eqs) := inBackendDAE;
  List.map_0(eqs, dumpEqnsSolved1);
end dumpEqnsSolved;

protected function dumpEqnsSolved1 "function dumpEqnsSolved1
  This is a helper for dumpEqnsSolved."
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

protected function dumpEqnsSolved2 "function dumpEqnsSolved2
  author: Frenkel TUD 2012-03"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Variables vars;
algorithm
  _ :=
  matchcontinue (inComps,eqns,vars)
    local
      Integer e,v;
      list<Integer> elst,vlst,vlst1,elst1;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.JacobianType jacType;
      list<tuple<Integer,list<Integer>>> eqnsvartpllst;
      Boolean b;
      String s;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
    case ({},_,_)  then ();
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v)::rest,_,_)
      equation
  print("SingleEquation: " +& intString(e) +& "\n");
  var = BackendVariable.getVarAt(vars,v);
  printVarList({var});
  eqn = BackendDAEUtil.equationNth(eqns,e-1);
  printEquationList({eqn});
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=elst,disc_vars=vlst)::rest,_,_)
      equation
  print("Mixed EquationSystem:\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqnlst = BackendEquation.getEqns(elst,eqns);
  printEquationList(eqnlst);
  dumpEqnsSolved2({comp},eqns,vars);
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst,jac=jac,jacType=jacType)::rest,_,_)
      equation
  print("Equationsystem " +& jacobianTypeStr(jacType) +& ":\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqnlst = BackendEquation.getEqns(elst,eqns);
  printEquationList(eqnlst);
  print("Jac:\n" +& dumpJacobianStr(jac) +& "\n");
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.SINGLEARRAY(eqn=e,vars=vlst)::rest,_,_)
      equation
  print("ArrayEquation:\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqn = BackendDAEUtil.equationNth(eqns,e-1);
  printEquationList({eqn});
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.SINGLEIFEQUATION(eqn=e,vars=vlst)::rest,_,_)
      equation
  print("IfEquation:\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqn = BackendDAEUtil.equationNth(eqns,e-1);
  printEquationList({eqn});
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.SINGLEALGORITHM(eqn=e,vars=vlst)::rest,_,_)
      equation
  print("Algorithm:\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqn = BackendDAEUtil.equationNth(eqns,e-1);
  printEquationList({eqn});
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e,vars=vlst)::rest,_,_)
      equation
  print("ComplexEquation:\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqn = BackendDAEUtil.equationNth(eqns,e-1);
  printEquationList({eqn});
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e,vars=vlst)::rest,_,_)
      equation
  print("WhenEquation:\n");
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqn = BackendDAEUtil.equationNth(eqns,e-1);
  printEquationList({eqn});
  dumpEqnsSolved2(rest,eqns,vars);
      then
  ();
    case (BackendDAE.TORNSYSTEM(tearingvars=vlst,residualequations=elst,otherEqnVarTpl=eqnsvartpllst,linear=b)::rest,_,_)
      equation
  s = Util.if_(b,"linear","nonlinear");
  print("torn " +& s +& " Equationsystem:\n");
  vlst1 = List.flatten(List.map(eqnsvartpllst,Util.tuple22));
  elst1 = List.map(eqnsvartpllst,Util.tuple21);
  varlst = List.map1r(vlst1, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
  printVarList(varlst);
  eqnlst = BackendEquation.getEqns(elst1,eqns);
  printEquationList(eqnlst);
  eqnlst = BackendEquation.getEqns(elst,eqns);
  printEquationList(eqnlst);
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

public function dumpComponentsAdvanced "function dumpComponentsAdvanced
  author: Frenkel TUD
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

protected function dumpComponentsAdvanced2 "function dumpComponentsAdvanced2
  author: PA
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
    case ((l :: lst),i,v2,vars)
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
      then
  ();
  end match;
end dumpComponentsAdvanced2;

protected function dumpComponentsAdvanced3 "function dumpComponentsAdvanced3
  author: PA
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
    case (i::{},v2,vars)
      equation
  v = v2[i];
  var = BackendVariable.getVarAt(vars,v);
  c = BackendVariable.varCref(var);
  b = BackendVariable.isStateVar(var);
  s = Util.if_(b,"der(","");
  print(s);
  s = ComponentReference.printComponentRefStr(c);
  print(s);
  s = Util.if_(b,") "," ");
  print(s);
      then
  ();
    case (i::l,v2,vars)
      equation
  v = v2[i];
  var = BackendVariable.getVarAt(vars,v);
  c = BackendVariable.varCref(var);
  b = BackendVariable.isStateVar(var);
  s = Util.if_(b,"der(","");
  print(s);
  s = ComponentReference.printComponentRefStr(c);
  print(s);
  s = Util.if_(b,") "," ");
  print(s);
  dumpComponentsAdvanced3(l,v2,vars);
      then
  ();
  end match;
end dumpComponentsAdvanced3;

public function dumpComponents
  input BackendDAE.StrongComponents inComps;
algorithm
  print("StrongComponents\n");
  print(UNDERLINE +& "\n");
  List.map_0(inComps,dumpComponent);
end dumpComponents;

public function dumpComponent
  input BackendDAE.StrongComponent inComp;
algorithm
  _:=
  match (inComp)
    local
      Integer i,v;
      list<Integer> ilst,vlst;
      list<String> ls;
      String s;
      BackendDAE.JacobianType jacType;
      BackendDAE.StrongComponent comp;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
      Boolean b;
    case BackendDAE.SINGLEEQUATION(eqn=i,var=v)
      equation
  print("{");
  print(intString(i));
  print(":");
  print(intString(v));
  print("}\n");
      then ();
    case BackendDAE.EQUATIONSYSTEM(eqns=ilst,vars=vlst,jacType=jacType)
      equation
  print("{");
  ls = List.map(ilst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("} Size: ");
  print(intString(listLength(vlst)));
  print(" ");
  print(jacobianTypeStr(jacType));
  print("\n");
      then
  ();
    case BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=ilst,disc_vars=vlst)
      equation
  print("{{");
  ls = List.map(ilst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("},\n");
  dumpComponent(comp);
  print("} Size: ");
  print(intString(listLength(vlst)));
  print("\n");
      then
  ();
    case BackendDAE.SINGLEARRAY(eqn=i,vars=vlst)
      equation
  print("Array ");
  print(" {{");
  print(intString(i));
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("}}\n");
      then
  ();
    case BackendDAE.SINGLEIFEQUATION(eqn=i,vars=vlst)
      equation
  print("IfEquation ");
  print(" {{");
  print(intString(i));
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("}}\n");
      then
  ();
    case BackendDAE.SINGLEALGORITHM(eqn=i,vars=vlst)
      equation
  print("Algorithm ");
  print(" {{");
  print(intString(i));
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("}}\n");
      then
  ();
    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=i,vars=vlst)
      equation
  print("ComplexEquation ");
  print(" {");
  print(intString(i));
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("}\n");
      then
  ();
    case BackendDAE.SINGLEWHENEQUATION(eqn=i,vars=vlst)
      equation
  print("WhenEquation ");
  print(" {");
  print(intString(i));
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("}\n");
      then
  ();
    case BackendDAE.TORNSYSTEM(residualequations=ilst,tearingvars=vlst,otherEqnVarTpl=eqnvartpllst,linear=b)
      equation
  print("{{");
  ls = List.map(eqnvartpllst, tupleString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("}\n,{");
  ls = List.map(ilst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print(":");
  ls = List.map(vlst, intString);
  s = stringDelimitList(ls, ", ");
  print(s);
  print("} Size: ");
  print(intString(listLength(vlst)));
  print(" ");
  s = Util.if_(b,"linear","nonlinear");
  print(s);
  print("\n");
      then
  ();
  end match;
end dumpComponent;

// =============================================================================
// section for all *String functions
//
// These are functions, that return their output with a String.
//   - componentRef_DIVISION_String
//   - equationString
//   - strongComponentString
//   - whenClauseString
//   - zeroCrossingListString
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
    case BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=ilst,disc_vars=vlst)
      equation
  ls = List.map(ilst, intString);
  s = stringDelimitList(ls, ", ");
  ls1 = List.map(vlst, intString);
  s1 = stringDelimitList(ls1, ", ");
  sl = intString(listLength(ilst));
  sj = strongComponentString(comp);
  s2 = stringAppendList({"{{",s,":",s1,"},\n",sj,"} Size: ",sl});
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
   case BackendDAE.TORNSYSTEM(residualequations=ilst,tearingvars=vlst,otherEqnVarTpl=eqnvartpllst,linear=b)
      equation
  ls = List.map(eqnvartpllst, tupleString);
  s = stringDelimitList(ls, ", ");
  ls = List.map(ilst, intString);
  s1 = stringDelimitList(ls, ", ");
  ls = List.map(vlst, intString);
  s2 = stringDelimitList(ls, ", ");
  sj = intString(listLength(vlst));
  sl = Util.if_(b,"linear","nonlinear");
  s2 = stringAppendList({"torn ",sl," Equationsystem","{{",s,"},\n{",s1,":",s2,"} Size: ",sj});
      then
  s2;
  end match;
end strongComponentString;

protected function whenEquationString "function whenEquationString
  Helper function to equationString"
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

public function equationString "function equationString
  Helper function to e.g. dump."
  input BackendDAE.Equation inEquation;
  output String outString;
algorithm
  outString := matchcontinue (inEquation)
    local
      String s1,s2,s3,s4,res;
      DAE.Exp e1,e2,e,cond;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
      DAE.Algorithm alg;
      DAE.ElementSource source;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse,eqns;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
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
    case (BackendDAE.IF_EQUATION(conditions=e1::expl, eqnstrue=eqns::eqnstrue, eqnsfalse=eqnsfalse, source=source))
      equation
  s1 = ExpressionDump.printExpStr(e1);
  s2 = stringDelimitList(List.map(eqns,equationString),"\n  ");
  s3 = stringAppendList({"if ",s1," then\n  ",s2});
  res = ifequationString(expl,eqnstrue,eqnsfalse,s3);
      then
  res;
  end matchcontinue;
end equationString;

public function zeroCrossingListString "function zeroCrossingListString"
  input list<BackendDAE.ZeroCrossing> inZeroCrossingList;
  output String outString;
algorithm
 outString := match(inZeroCrossingList)
  local
    BackendDAE.ZeroCrossing curr;
    list<BackendDAE.ZeroCrossing> rest;
  case ({}) then "";
  case (curr::rest) equation
  then zeroCrossingString(curr) +& "\n" +& zeroCrossingListString(rest);
end match;
end zeroCrossingListString;

protected function zeroCrossingString "function: zeroCrossingString
  Dumps a zerocrossing into a string, for debugging purposes."
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

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.LBINARY(operator=_),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.LUNARY(operator=_),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
    then str2;

    case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.CALL(path = Absyn.IDENT(name = _)),occurEquLst = eq,occurWhenLst = wc) equation
      eq_s_list = List.map(eq, intString);
      eq_s = stringDelimitList(eq_s_list, ",");
      wc_s_list = List.map(wc, intString);
      wc_s = stringDelimitList(wc_s_list, ",");
      str = ExpressionDump.printExpStr(e);
      str2 = stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
    then str2;

    else then "";
  end match;
end zeroCrossingString;

protected function whenClauseListString "function whenClauseListString"
  input list<BackendDAE.WhenClause> inWhenClauseList;
  output String outString;
protected
  list<String> strList;
algorithm
  strList := List.map(inWhenClauseList, whenClauseString);
  outString := stringDelimitList(strList, ",\n");
end whenClauseListString;

public function whenClauseString "function: whenClauseString
  Dumps a whenclause into a string, for debugging purposes."
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

    else then "";
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
  sc = "der(" +& sc +& ")";
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
  input tuple<String,list<DAE.ComponentRef>,String,String> inTpl;
protected
  list<DAE.ComponentRef> b;
  String a,c,d;
algorithm
  (a,b,c,d) := inTpl;
  print(a);
  debuglst((b,ComponentReference.printComponentRefStr,c,d));
end debugStrCrefLstStr;

public function debugCrefStr
  input tuple<DAE.ComponentRef,String> inTpl;
protected
  DAE.ComponentRef a;
  String b;
algorithm
  (a,b) := inTpl;
  print(ComponentReference.printComponentRefStr(a) +& b);
end debugCrefStr;

public function debugStrIntStr
  input tuple<String,Integer,String> inTpl;
protected
  String a,c;
  Integer b;
algorithm
  (a,b,c) := inTpl;
  print(a +& intString(b) +& c);
end debugStrIntStr;

public function debugStrIntStrIntStr
  input tuple<String,Integer,String,Integer,String> inTpl;
protected
  String a,c,e;
  Integer b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& intString(b) +& c +& intString(d) +& e);
end debugStrIntStrIntStr;

public function debugCrefStrIntStr
  input tuple<DAE.ComponentRef,String,Integer,String> inTpl;
protected
  DAE.ComponentRef a;
  String b,d;
  Integer c;
algorithm
  (a,b,c,d) := inTpl;
  print(ComponentReference.printComponentRefStr(a) +& b +& intString(c) +& d);
end debugCrefStrIntStr;

public function debugStrCrefStr
  input tuple<String,DAE.ComponentRef,String> inTpl;
protected
  String a,c;
  DAE.ComponentRef b;
algorithm
  (a,b,c) := inTpl;
  print(a +&ComponentReference.printComponentRefStr(b) +& c);
end debugStrCrefStr;

public function debugStrCrefStrIntStr
  input tuple<String,DAE.ComponentRef,String,Integer,String> inTpl;
protected
  String a,c,e;
  DAE.ComponentRef b;
  Integer d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& intString(d) +& e);
end debugStrCrefStrIntStr;

public function debugStrCrefStrRealStrRealStrRealStr
  input tuple<String,DAE.ComponentRef,String,Real,String,Real,String,Real,String> inTpl;
protected
  String a,c,e,g,i;
  DAE.ComponentRef b;
  Real d,f,h;
algorithm
  (a,b,c,d,e,f,g,h,i) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& realString(d) +& e +& realString(f) +& g +& realString(h) +& i);
end debugStrCrefStrRealStrRealStrRealStr;

public function debugStrRealStrRealStrRealStrRealStr
  input tuple<String,Real,String,Real,String,Real,String,Real,String> inTpl;
protected
  String a,c,e,g,i;
  Real b,d,f,h;
algorithm
  (a,b,c,d,e,f,g,h,i) := inTpl;
  print(a +& realString(b) +& c +& realString(d) +& e +& realString(f) +& g +& realString(h) +& i);
end debugStrRealStrRealStrRealStrRealStr;

public function debugStrCrefStrExpStr
  input tuple<String,DAE.ComponentRef,String,DAE.Exp,String> inTpl;
protected
  String a,c,e;
  DAE.ComponentRef b;
  DAE.Exp d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& ExpressionDump.printExpStr(d) +& e);
end debugStrCrefStrExpStr;

public function debugStrCrefStrCrefStr
  input tuple<String,DAE.ComponentRef,String,DAE.ComponentRef,String> inTpl;
protected
  String a,c,e;
  DAE.ComponentRef b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& ComponentReference.printComponentRefStr(d) +& e);
end debugStrCrefStrCrefStr;

public function debugExpStr
  input tuple<DAE.Exp,String> inTpl;
protected
  String b;
  DAE.Exp a;
algorithm
  (a,b) := inTpl;
  print(ExpressionDump.printExpStr(a) +& b);
end debugExpStr;

public function debugStrExpStr
  input tuple<String,DAE.Exp,String> inTpl;
protected
  String a,c;
  DAE.Exp b;
algorithm
  (a,b,c) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c);
end debugStrExpStr;

public function debugStrExpLstStr
  input tuple<String,list<DAE.Exp>,String,String> inTpl;
protected
  list<DAE.Exp> b;
  String a,c,d;
algorithm
  (a,b,c,d) := inTpl;
  print(a);
  debuglst((b,ExpressionDump.printExpStr,c,d));
end debugStrExpLstStr;

public function debugStrExpStrCrefStr
  input tuple<String,DAE.Exp,String,DAE.ComponentRef,String> inTpl;
protected
  String a,c,e;
  DAE.Exp b;
  DAE.ComponentRef d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c +& ComponentReference.printComponentRefStr(d) +& e);
end debugStrExpStrCrefStr;

public function debugStrExpStrExpStr
  input tuple<String,DAE.Exp,String,DAE.Exp,String> inTpl;
protected
  String a,c,e;
  DAE.Exp b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c +& ExpressionDump.printExpStr(d) +& e);
end debugStrExpStrExpStr;

public function debugExpStrExpStrExpStr
  input tuple<DAE.Exp,String,DAE.Exp,String,DAE.Exp,String> inTpl;
protected
  DAE.Exp a,c,e;
  String b,d,f;
algorithm
  (a,b,c,d,e,f) := inTpl;
  print(ExpressionDump.printExpStr(a) +& b +& ExpressionDump.printExpStr(c) +& d +& ExpressionDump.printExpStr(e) +& f);
end debugExpStrExpStrExpStr;

public function debugStrExpStrExpStrExpStr
  input tuple<String,DAE.Exp,String,DAE.Exp,String,DAE.Exp,String> inTpl;
protected
  String a,c,e,g;
  DAE.Exp b,d,f;
algorithm
  (a,b,c,d,e,f,g) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c +& ExpressionDump.printExpStr(d) +& e +& ExpressionDump.printExpStr(f) +& g);
end debugStrExpStrExpStrExpStr;

public function debugStrEqnStr
  input tuple<String,BackendDAE.Equation,String> inTpl;
protected
  String a,c,e;
  BackendDAE.Equation b,d;
algorithm
  (a,b,c) := inTpl;
  print(a +& equationString(b) +& c);
end debugStrEqnStr;

public function debugStrEqnStrEqnStr
  input tuple<String,BackendDAE.Equation,String,BackendDAE.Equation,String> inTpl;
protected
  String a,c,e;
  BackendDAE.Equation b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& equationString(b) +& c +& equationString(d) +& e);
end debugStrEqnStrEqnStr;

public function debuglst
  input tuple<list<Type_a>,FuncTypeType_aToStr,String,String> inTpl "(List,FuncListElementToString,DelemiterString,EndString";
  partial function FuncTypeType_aToStr
    input Type_a inTypeA;
    output String outTypeA;
  end FuncTypeType_aToStr;
  replaceable type Type_a subtypeof Any;
algorithm
   _ := match(inTpl)
    local
      Type_a a;
      list<Type_a> rest;
      FuncTypeType_aToStr f;
      String s,c,se;
    case (({},_,_,se))
      equation
  print(se);
      then ();
    case ((a::{},f,c,se))
      equation
       s = f(a);
       print(s);
       print(se);
    then ();
    case ((a::rest,f,c,se))
      equation
       s = f(a);
       print(s); print(c);
       debuglst((rest,f,c,se));
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
"function: printCallFunction2Str
  Print the exp of typ DAE.CALL."
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
      Expression.Ident s,s_1,s_2,fs,argstr;
      Absyn.Path fcn;
      list<DAE.Exp> args;
      DAE.Exp e1,e2;
      Expression.Type ty;
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

protected function printVarsStatistics "function: printVarsStatistics
  author: PA

  Prints statistics on variables, etc.
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
algorithm
  _:=
  matchcontinue (inVariables1,inVariables2)
    local
      String lenstr,bstr;
      BackendDAE.VariableArray v1,v2;
      Integer bsize1,n1,bsize2,n2;
    case (BackendDAE.VARIABLES(varArr = v1,bucketSize = bsize1,numberOfVars = n1),BackendDAE.VARIABLES(varArr = v2,bucketSize = bsize2,numberOfVars = n2))
      equation
  print("Variable Statistics\n");
  print("===================\n");
  print("Number of variables: ");
  lenstr = intString(n1);
  print(lenstr);
  print("\n");
  print("Bucket size for variables: ");
  bstr = intString(bsize1);
  print(bstr);
  print("\n");
  print("Number of known variables: ");
  lenstr = intString(n2);
  print(lenstr);
  print("\n");
  print("Bucket size for known variables: ");
  bstr = intString(bsize1);
  print(bstr);
  print("\n");
      then
  ();
  end matchcontinue;
end printVarsStatistics;

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
    case DAE.T_INTEGER(source = _) then "Integer ";
    case DAE.T_REAL(source = _) then "Real ";
    case DAE.T_BOOL(source = _) then "Boolean ";
    case DAE.T_STRING(source = _) then "String ";

    case DAE.T_ENUMERATION(names = l)
      equation
  s1 = stringDelimitList(l, ", ");
  s2 = stringAppend("enumeration(", s1);
  str = stringAppend(s2, ")");
      then
  str;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)) then "ExternalObject ";
  end match;
end dumpTypeStr;

public function dumpWhenOperatorStr
"function: dumpWhenOperatorStr
  Dumps a WhenOperator into a string, for debugging purposes."
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
    case BackendDAE.NORETCALL(functionName=functionName,functionArgs=functionArgs)
     equation
      se = Absyn.pathString(functionName);
      se1 = stringDelimitList(List.map(functionArgs,ExpressionDump.printExpStr),", ");
      str = stringAppendList({se,"(",se1,")"});
     then
      str;
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
    else then ();
  end match;
end dumpOption;

protected function dumpEqSystemHTML
"function: dumpEqSystemHTML
  This function dumps the BackendDAE.EqSystem representaton to stdout."
  input BackendDAE.EqSystem inEqSystem;
  input String inPrefixIdstr;
  input tuple<DumpHTML.Document,Integer> inTpl;
  output tuple<DumpHTML.Document,Integer> outTpl;
protected
  list<BackendDAE.Var> vars;
  Integer eqnlen,eqnssize,i;
  String varlen_str,eqnlen_str,prefixIdstr,prefixId;
  list<BackendDAE.Equation> eqnsl;
  BackendDAE.Variables vars1;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrix> mT;
  BackendDAE.Matching matching;
  DumpHTML.Document doc;
  DumpHTML.Tags tags;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars1,orderedEqs=eqns,m=m,mT=mT,matching=matching) := inEqSystem;
  (doc,i) := inTpl;
  prefixId := inPrefixIdstr +& "_" +& intString(i);
  vars := BackendVariable.varList(vars1);
  varlen_str := "Variables (" +& intString(listLength(vars)) +& ")";
  tags := DumpHTML.addHeadingTag(2,varlen_str,{});
  tags := printVarListHTML(vars,prefixId,tags);
  eqnsl := BackendEquation.equationList(eqns);
  eqnlen_str := "Equations (" +& intString(listLength(eqnsl)) +& "," +& intString(BackendDAEUtil.equationSize(eqns)) +& ")";
  tags := DumpHTML.addHeadingTag(2,eqnlen_str,tags);
  tags := dumpEqnsHTML(eqnsl,prefixId,tags);
  //dumpOption(m,dumpIncidenceMatrix);
  //dumpOption(mT,dumpIncidenceMatrixT);
  tags := dumpFullMatchingHTML(matching,prefixId,tags);
//  doc := DumpHTML.addBodyTags(tags,doc);
  doc := DumpHTML.addHyperLink("javascript:toggle('" +& prefixId +& "system')","System einblenden","System " +& intString(i) +& " ein/ausblenden",doc);
  doc := DumpHTML.addLine("",doc);
  doc := DumpHTML.addDivision(prefixId +& "system",{("display","none")},tags,doc);
  outTpl := (doc,i+1);
end dumpEqSystemHTML;

protected function printVarListHTML
"function: printVarListHTML
  Helper function to printVarList."
  input list<BackendDAE.Var> vars;
  input String prefixId;
  input DumpHTML.Tags inTags;
  output DumpHTML.Tags outTags;
protected
  DumpHTML.Tags tags;
algorithm
  ((tags,_)) := List.fold1(vars,dumpVarHTML,prefixId,({},1));
  outTags := DumpHTML.addHyperLinkTag("javascript:toggle('" +& prefixId +& "variables')","Variablen einblenden","Variablen ein/ausblenden",inTags);
  outTags := DumpHTML.addDivisionTag(prefixId +& "variables",{("background","#FFFFCC"),("display","none")},tags,outTags);
end printVarListHTML;

protected function dumpVarHTML
"function: dumpVar
  Helper function to printVarList."
  input BackendDAE.Var inVar;
  input String prefixId;
  input tuple<DumpHTML.Tags,Integer> inTpl;
  output tuple<DumpHTML.Tags,Integer> oTpl;
protected
  DumpHTML.Tags tags;
  Integer i;
  String ln,istr;
algorithm
  (tags,i) := inTpl;
  istr := intString(i);
  ln := prefixId +& "varanker" +& istr;
  tags := DumpHTML.addAnkerTag(ln,tags);
  ln := istr +& ": " +& varString(inVar);
  tags := DumpHTML.addLineTag(ln,tags);
  oTpl := (tags,i+1);
end dumpVarHTML;

protected function dumpEqnsHTML
"function: printVarListHTML
  Helper function to printVarList."
  input list<BackendDAE.Equation> eqns;
  input String prefixId;
  input DumpHTML.Tags inTags;
  output DumpHTML.Tags outTags;
protected
  DumpHTML.Tags tags;
algorithm
  ((tags,_)) := List.fold1(eqns,dumpEqnHTML,prefixId,({},1));
  outTags := DumpHTML.addHyperLinkTag("javascript:toggle('" +& prefixId +& "equations')","Equations einblenden","Equations ein/ausblenden",inTags);
  outTags := DumpHTML.addDivisionTag(prefixId +& "equations",{("background","#C0C0C0"),("display","none")},tags,outTags);
end dumpEqnsHTML;

protected function dumpEqnHTML
"function: dumpEqnHTML
  Helper function to dump_eqns"
  input BackendDAE.Equation inEquation;
  input String prefixId;
  input tuple<DumpHTML.Tags,Integer> inTpl;
  output tuple<DumpHTML.Tags,Integer> oTpl;
protected
  DumpHTML.Tags tags;
  Integer i;
  String ln,istr;
algorithm
  (tags,i) := inTpl;
  istr := intString(i);
  ln := prefixId +& "eqanker" +& istr;
  tags := DumpHTML.addAnkerTag(ln,tags);
  ln := istr +& " (" +& intString(BackendEquation.equationSize(inEquation)) +& "): " +& equationString(inEquation);
  tags := DumpHTML.addLineTag(ln,tags);
  oTpl := (tags,i+1);
end dumpEqnHTML;

protected function dumpFullMatchingHTML
  input BackendDAE.Matching inMatch;
  input String prefixId;
  input DumpHTML.Tags inTags;
  output DumpHTML.Tags outTags;
algorithm
  outTags:= match(inMatch,prefixId,inTags)
    local
      array<Integer> ass1;
      DumpHTML.Tags tags;
      BackendDAE.StrongComponents comps;
    case (BackendDAE.NO_MATCHING(),_,_) then inTags;
    case (BackendDAE.MATCHING(ass1,_,comps),_,_)
      equation
  tags = dumpMatchingHTML(ass1,prefixId,inTags);
  //dumpComponents(comps);
      then
  tags;
  end match;
end dumpFullMatchingHTML;

protected function dumpMatchingHTML
"function: dumpMatching
  author: Frenkel TUD 2012-11
  prints the matching information on stdout."
  input array<Integer> v;
  input String prefixId;
  input DumpHTML.Tags inTags;
  output DumpHTML.Tags outTags;
protected
  Integer len;
  String len_str;
  DumpHTML.Tags tags;
algorithm
  outTags := DumpHTML.addHeadingTag(2,"Matching",inTags);
  len := arrayLength(v);
  len_str := intString(len) +& " variables and equations\n";
  outTags := DumpHTML.addLineTag(len_str,outTags);
  tags := dumpMatchingHTML2(v, 1, len, prefixId, {});
  outTags := DumpHTML.addHyperLinkTag("javascript:toggle('" +& prefixId +& "matching')","Matching einblenden","Matching ein/ausblenden",outTags);
  outTags := DumpHTML.addDivisionTag(prefixId +& "matching",{("background","#339966"),("display","none")},tags,outTags);
end dumpMatchingHTML;

protected function dumpMatchingHTML2
"function: dumpMatchingHTML2
  author: PA
  Helper function to dumpMatching."
  input array<Integer> v;
  input Integer i;
  input Integer len;
  input String prefixId;
  input DumpHTML.Tags inTags;
  output DumpHTML.Tags outTags;
algorithm
  outTags := matchcontinue (v,i,len,prefixId,inTags)
    local
      Integer eqn;
      String s,s2;
    case (_,_,_,_,_)
      equation
  true = intLe(i,len);
  s = intString(i);
  eqn = v[i];
  s2 = intString(eqn);
  s = "Variable <a href=\"#" +& prefixId +& "varanker" +& s +& "\">" +& s +& "</a> is solved in Equation  <a href=\"#" +& prefixId +& "eqanker" +& s2 +& "\">" +& s2 +& "</a>";
      then
  dumpMatchingHTML2(v, i+1, len, prefixId, DumpHTML.LINE(s)::inTags);
    else
      then
  inTags;
  end matchcontinue;
end dumpMatchingHTML2;

protected function dumpSharedHTML
"function: dumpSharedHTML
  This function dumps the BackendDAE.Shared representaton to stdout."
  input BackendDAE.Shared inShared;
  input DumpHTML.Document inDoc;
  output DumpHTML.Document outDoc;
algorithm
  outDoc:= inDoc;
end dumpSharedHTML;

public function dumpAlgorithms "Help function to dump, prints algorithms to stdout"
  input list<DAE.Algorithm> ialgs;
  input Integer indx;
algorithm
  _ := match(ialgs,indx)
    local
      list<Algorithm.Statement> stmts;
      IOStream.IOStream myStream;
      String is;
      list<DAE.Algorithm> algs;

    case({},_) then ();
    case(DAE.ALGORITHM_STMTS(stmts)::algs,indx)
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
  print("Print sparse pattern: " +& intString(arrayLength(inSparsePatter)) +& "\n");
  dumpSparsePattern2(arrayList(inSparsePatter), 1);
  print("\n");
end dumpSparsePatternArray;

public function dumpSparsePattern
"function:  dumpSparsePattern
 author: wbraun
 description: function dumps sparse pattern of a Jacobain System."
  input list<list<Integer>> inSparsePatter;
algorithm
  print("Print sparse pattern: " +& intString(listLength(inSparsePatter)) +& "\n");
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
      sparsepatternStr = List.toString(elem, intString,"Row[" +& intString(inInteger) +& "] = ","{",";","}",true);
      print(sparsepatternStr +& "\n");
      dumpSparsePattern2(rest,inInteger+1);
    then ();
  end match;
end dumpSparsePattern2;

public function dumpJacobianStr
"function: dumpJacobianStr
  Dumps the sparse jacobian.
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
"function: dumpJacobianStr2
  Helper function to dumpJacobianStr"
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

public function jacobianTypeStr "function: jacobianTypeStr
  author: PA
  Returns the jacobian type as a string, used for debugging."
  input BackendDAE.JacobianType inJacobianType;
  output String outString;
algorithm
  outString := match (inJacobianType)
    case BackendDAE.JAC_CONSTANT() then "Jacobian Constant";
    case BackendDAE.JAC_TIME_VARYING() then "Jacobian Time varying";
    case BackendDAE.JAC_NONLINEAR() then "Jacobian Nonlinear";
    case BackendDAE.JAC_NO_ANALYTIC() then "No analytic jacobian";
  end match;
end jacobianTypeStr;

public function dumpEqnsStr
"function: printEquationList
  Helper function to dump."
  input list<BackendDAE.Equation> eqns;
  output String str;
algorithm
  str := stringDelimitList(dumpEqnsStr2(eqns, 1, {}),"\n");
end dumpEqnsStr;

protected function dumpEqnsStr2
"function: dumpEqnsStr2
  Helper function to dump_eqns"
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
  str = (is +& " : ") +& es;
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

public function varString "function varString
  Helper function to printVarList."
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
algorithm
  BackendDAE.VAR(varName = cr,
               varKind = kind,
               varDirection = dir,
               varType = var_type,
               arryDim = arrayDim,
               bindExp = bindExp,
               source = source,
               values = dae_var_attr,
               comment = comment,
               connectorType = ct) := inVar;
  paths := DAEUtil.getElementSourceTypes(source);
  paths_lst := List.map(paths, Absyn.pathString);
  outStr := DAEDump.dumpDirectionStr(dir) +& " " +& ComponentReference.printComponentRefStr(cr) +& ":"
      +& kindString(kind) +& "(" +& connectorTypeString(ct) +& attributesString(dae_var_attr)
      +& ") " +& optExpressionString(bindExp,"") +& DAEDump.dumpCommentOptionStr(comment)
      +& stringDelimitList(paths_lst, ", ") +& " type: " +& dumpTypeStr(var_type) +& ComponentReference.printComponentRef2Str("", arrayDim);
end varString;

public function dumpKind
"function: dumpKind
  Helper function to dump."
  input BackendDAE.VarKind inVarKind;
algorithm
  print(kindString(inVarKind));
end dumpKind;

public function kindString
"function: kindString
  Helper function to dump."
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
    case BackendDAE.STATE(index=i,derName=NONE())      then "STATE(" +& intString(i) +& ")";
    case BackendDAE.STATE(index=i,derName=SOME(dcr))      then "STATE(" +& intString(i) +& "," +& ComponentReference.printComponentRefStr(dcr) +& ")";
    case BackendDAE.STATE_DER()   then "STATE_DER";
    case BackendDAE.DUMMY_DER()   then "DUMMY_DER";
    case BackendDAE.DUMMY_STATE() then "DUMMY_STATE";
    case BackendDAE.DISCRETE()    then "DISCRETE";
    case BackendDAE.PARAM()       then "PARAM";
    case BackendDAE.CONST()       then "CONST";
    case BackendDAE.EXTOBJ(path)  then "EXTOBJ: " +& Absyn.pathString(path);
    case BackendDAE.JAC_VAR()     then "JACOBIAN_VAR";
    case BackendDAE.JAC_DIFF_VAR()then "JACOBIAN_DIFF_VAR";
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
"function: dumpAttributes
  Helper function to dump."
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
    case SOME(DAE.VAR_ATTR_REAL(min=(NONE(),NONE()),initial_=NONE(),fixed=NONE(),nominal=NONE(),stateSelectOption=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_REAL(min=(min,max),initial_=start,fixed=fixed,nominal=nominal,stateSelectOption=stateSelectOption,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist))
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
    case SOME(DAE.VAR_ATTR_INT(min=(NONE(),NONE()),initial_=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_INT(min=(min,max),initial_=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist))
      equation
  dumpOptExpression(min,"min");
  dumpOptExpression(max,"max");
  dumpOptExpression(start,"start");
  dumpOptExpression(fixed,"fixed");
  dumpOptBoolean(isProtected,"protected");
  dumpOptBoolean(finalPrefix,"final");
  dumpOptDistribution(dist);
     then ();
    case SOME(DAE.VAR_ATTR_BOOL(initial_=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
      then ();
    case SOME(DAE.VAR_ATTR_BOOL(initial_=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
  dumpOptExpression(start,"start");
  dumpOptExpression(fixed,"fixed");
  dumpOptBoolean(isProtected,"protected");
  dumpOptBoolean(finalPrefix,"final");
     then ();
    case SOME(DAE.VAR_ATTR_STRING(initial_=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_STRING(initial_=start,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
  dumpOptExpression(start,"start");
  dumpOptBoolean(isProtected,"protected");
  dumpOptBoolean(finalPrefix,"final");
     then ();
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=(NONE(),NONE()),start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then ();
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=(min,max),start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
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
      print("distribution = Distribution("+&ExpressionDump.printExpStr(e1)+&", "
      +&ExpressionDump.printExpStr(e2)+&", "
      +&ExpressionDump.printExpStr(e3)+&")");
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
"function: dumpOptExpression
  Helper function to dump."
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
"function: dumpOptBoolean
  Helper function to dump."
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
"function: attributesString
  Helper function to dump."
  input Option<DAE.VariableAttributes> inAttr;
  output String outString;
algorithm
  outString :=
  match (inAttr)
    local
       Option<DAE.Exp> min,max,start,fixed,nominal;
       Option<Boolean> isProtected,finalPrefix;
       Option<DAE.Distribution> dist;
       Option<DAE.StateSelect> stateSelectOption;
       Option<DAE.Uncertainty> uncertainopt;
       String str;
    case NONE() then "";
    case SOME(DAE.VAR_ATTR_REAL(min=(NONE(),NONE()),initial_=NONE(),fixed=NONE(),nominal=NONE(),stateSelectOption=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE(),uncertainOption=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_REAL(min=(min,max),initial_=start,fixed=fixed,nominal=nominal,stateSelectOption=stateSelectOption,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist,uncertainOption=uncertainopt))
      equation
  str = optExpressionString(min,"min") +& optExpressionString(max,"max") +& optExpressionString(start,"start") +& optExpressionString(fixed,"fixed")
       +& optExpressionString(nominal,"nominal") +& optStateSelectionString(stateSelectOption) +& optBooleanString(isProtected,"protected")
       +& optBooleanString(finalPrefix,"final") +& optDistributionString(dist) +& optUncertainty(uncertainopt);
     then str;
    case SOME(DAE.VAR_ATTR_INT(min=(NONE(),NONE()),initial_=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE(),distributionOption=NONE(),uncertainOption=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_INT(min=(min,max),initial_=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix,distributionOption=dist,uncertainOption=uncertainopt))
      equation
  str = optExpressionString(min,"min") +& optExpressionString(max,"max") +& optExpressionString(start,"start") +& optExpressionString(fixed,"fixed")
       +& optBooleanString(isProtected,"protected") +& optBooleanString(finalPrefix,"final") +& optUncertainty(uncertainopt);
     then str;
    case SOME(DAE.VAR_ATTR_BOOL(initial_=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
      then "";
    case SOME(DAE.VAR_ATTR_BOOL(initial_=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
  str = optExpressionString(start,"start") +& optExpressionString(fixed,"fixed") +& optBooleanString(isProtected,"protected") +& optBooleanString(finalPrefix,"final");
     then str;
    case SOME(DAE.VAR_ATTR_STRING(initial_=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_STRING(initial_=start,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
  str = optExpressionString(start,"start") +& optBooleanString(isProtected,"protected") +& optBooleanString(finalPrefix,"final");
     then str;
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=(NONE(),NONE()),start=NONE(),fixed=NONE(),isProtected=NONE(),finalPrefix=NONE()))
     then "";
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=(min,max),start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
  str = optExpressionString(min,"min") +& optExpressionString(max,"max") +& optExpressionString(start,"start") +& optExpressionString(fixed,"fixed")
       +& optBooleanString(isProtected,"protected") +& optBooleanString(finalPrefix,"final");
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
  str =  "distribution = Distribution(" +& ExpressionDump.printExpStr(e1) +& ", "
       +& ExpressionDump.printExpStr(e2) +& ", "
       +& ExpressionDump.printExpStr(e3) +& ")";
    then str;
  end match;
end optDistributionString;

protected function optUncertainty
"funcion optUncertainty"
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
" function optStateSelectionString "
  input Option<DAE.StateSelect> ss;
  output String outString;
algorithm
  outString:= match(ss)
  local
    case(SOME(DAE.NEVER())) then  "stateSelect=StateSelect.never ";
    case(SOME(DAE.AVOID())) then  "stateSelect=StateSelect.avoid ";
    case(SOME(DAE.DEFAULT())) then "";
    case(SOME(DAE.PREFER())) then  "stateSelect=StateSelect.prefer ";
    case(SOME(DAE.ALWAYS())) then  "stateSelect=StateSelect.alwas ";
    else "";
  end match;
end optStateSelectionString;

protected function optExpressionString
"function: optExpressionString
  Helper function to dump."
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
   str = inString +& " = " +& se +& " ";
     then str;
    else "";
  end match;
end optExpressionString;

protected function optBooleanString
"function: optBooleanString
  Helper function to dump."
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
   str = inString +& " = true ";
     then str;
    else "";
  end match;
end optBooleanString;

public function dumpIncidenceMatrix
"function: dumpIncidenceMatrix
  author: PA
  Prints the incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
protected
  Integer mlen;
  String mlen_str;
  list<list<Integer>> m_1;
algorithm
  print("\nIncidence Matrix (row: equation)\n");
  print(UNDERLINE +& "\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
  print("\n");
end dumpIncidenceMatrix;

public function dumpIncidenceMatrixT
"function: dumpIncidenceMatrixT
  author: PA
  Prints the transposed incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
protected
  Integer mlen;
  String mlen_str;
  list<list<Integer>> m_1;
algorithm
  print("\nTranspose Incidence Matrix (row: var)\n");
  print(UNDERLINE +& "\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
  print("\n");
end dumpIncidenceMatrixT;

protected function dumpIncidenceMatrix2
"function: dumpIncidenceMatrix2
  author: PA
  Helper function to dumpIncidenceMatrix (+T)."
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := match (inIntegerLstLst,rowIndex)
    local
      list<Integer> row;
      list<list<Integer>> rows;
    case ({},_) then ();
    case ((row :: rows),_)
      equation
  print(intString(rowIndex));print(":");
  dumpIncidenceRow(row);
  dumpIncidenceMatrix2(rows,rowIndex+1);
      then
  ();
  end match;
end dumpIncidenceMatrix2;

public function dumpIncidenceRow
"function: dumpIncidenceRow
  author: PA
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
"function: dumpAdjacencyMatrixEnhanced
  author: Frenkel TUD 2012-05
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
"function: dumpAdjacencyMatrixEnhanced
  author: Frenkel TUD 2012-05
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
"function: dumpAdjacencyMatrixEnhanced2
  author: Frenkel TUD 2012-05
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
"function: dumpAdjacencyRowEnhanced
  author: Frenkel TUD 2012-05
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
  print("(" +& s +& "," +& s1 +& ")");
  print(" ");
  dumpAdjacencyRowEnhanced(xs);
      then
  ();
  end match;
end dumpAdjacencyRowEnhanced;

public function dumpSolvability
"function: dumpSolvability
  author: Frenkel TUD 2012-05,
  returns a string for the Solvability"
  input BackendDAE.Solvability solva;
  output String s;
algorithm
  s := match(solva)
    local Boolean b;
    case BackendDAE.SOLVABILITY_SOLVED() then "solved";
    case BackendDAE.SOLVABILITY_CONSTONE() then "constone";
    case BackendDAE.SOLVABILITY_CONST() then "const";
    case BackendDAE.SOLVABILITY_PARAMETER(b=b) then "param(" +& boolString(b) +& ")";
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=b) then "variable(" +& boolString(b) +& ")";
    case BackendDAE.SOLVABILITY_NONLINEAR() then "nonlinear";
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then "unsolvable";
  end match;
end dumpSolvability;

public function dumpFullMatching
  input BackendDAE.Matching inMatch;
algorithm
  _:= match(inMatch)
    local
      array<Integer> ass1;
      BackendDAE.StrongComponents comps;
      case (BackendDAE.NO_MATCHING()) equation print("no matching\n"); then ();
      case (BackendDAE.MATCHING(ass1,_,comps))
  equation
    dumpMatching(ass1);
    print("\n\n");
    dumpComponents(comps);
  then
    ();
    end match;
end dumpFullMatching;

public function dumpMatching
"function: dumpMatching
  author: PA
  prints the matching information on stdout."
  input array<Integer> v;
protected
  Integer len;
  String len_str;
algorithm
  print("Matching\n");
  print(UNDERLINE +& "\n");
  len := arrayLength(v);
  len_str := intString(len);
  print(len_str);
  print(" variables and equations\n");
  dumpMatching2(v, 1, len);
end dumpMatching;

protected function dumpMatching2
"function: dumpMatching2
  author: PA
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
  print("var " +& s +& " is solved in eqn " +& s2 +& "\n");
  dumpMatching2(v, i+1, len);
      then
  ();
    else
      then
  ();
  end matchcontinue;
end dumpMatching2;

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
  Integer e_1;
  BackendDAE.Equation eqn;
algorithm
  e_1 := e - 1;
  eqn := BackendDAEUtil.equationNth(eqns, e_1);
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
  output list<String> lst;
algorithm
  lst := matchcontinue(i,n,m,mT,ass1,ass2)
    local
      list<list<Integer>> llst;
      list<Integer> eqns;
      list<String> strLst,slst;
      String str;
    case(_,_,_,_,_,_) equation
      true = (i > n);
      then {};
    case(_,_,_,_,_,_)
      equation
  eqns = BackendDAETransform.reachableNodes(i, mT, ass2);
  llst = List.map(eqns,List.create);
  llst = List.map1(llst, List.consr, i);
  slst = List.map(llst,intListStr);
  str = stringDelimitList(slst,",");
  str = stringAppendList({"{",str,"}"});
  strLst = dumpComponentsGraphStr2(i+1,n,m,mT,ass1,ass2);
      then str::strLst;
  end matchcontinue;
end dumpComponentsGraphStr2;

public function dumpList "function: dumpList
  author: PA

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

public function dumpComponentsOLD "function: dumpComponents
  author: PA

  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
algorithm
  print("Blocks\n");
  print("=======\n");
  dumpComponents2(l, 1);
end dumpComponentsOLD;

protected function dumpComponents2 "function: dumpComponents2
  author: PA

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

protected function dumpAliasVariable
"author: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var,list<Integer>> inTpl;
 output tuple<BackendDAE.Var,list<Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      String s,scr,se;
    case ((v,_))
      equation
  cr = BackendVariable.varCref(v);
  e = BackendVariable.varBindExp(v);
  //print("### dump var : " +&  ComponentReference.printComponentRefStr(cr) +& "\n");
  scr = ComponentReference.printComponentRefStr(cr);
  se = ExpressionDump.printExpStr(e);
  s = stringAppendList({scr," = ",se,"\n"});
  print(s);
      then ((v,{}));
    case inTpl then inTpl;
  end matchcontinue;
end dumpAliasVariable;

public function dumpStateVariables "function: dumpStateVariables
  author: Frenkel TUD 2010-12

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
"author: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, Integer> inTpl;
 output tuple<BackendDAE.Var, Integer> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      String scr;
      Integer pos;
    case ((v,pos))
      equation
  true = BackendVariable.isStateVar(v);
  cr = BackendVariable.varCref(v);
  scr = ComponentReference.printComponentRefStr(cr);
  print(intString(pos)); print(": ");
  print(scr); print("\n");
      then ((v,pos+1));
    case inTpl then inTpl;
  end matchcontinue;
end dumpStateVariable;

public function bltdump
"author: Frenkel TUD 2011-03"
  input tuple<String,BackendDAE.BackendDAE> inTpl;
algorithm
   _:=
  matchcontinue (inTpl)
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
      String str,strlow,headerline;
      DumpHTML.Document doc;
    case ((headerline,BackendDAE.DAE(eqs,shared)))
      equation
  Flags.STRING_FLAG(data=str) = Flags.getConfigValue(Flags.DUMP_TARGET);
  strlow = System.tolower(str);
  true = intGt(System.stringFind(str,".html"),0);
  doc = DumpHTML.emtypDocumentWithToggleFunktion();
  doc = DumpHTML.addHeading(1,headerline,doc);
  strlow = intString(realInt(System.time()));
  ((doc,_)) = List.fold1(eqs,dumpEqSystemHTML,strlow,(doc,1));
  doc = dumpSharedHTML(shared,doc);
  str = strlow +& str;
  DumpHTML.dumpDocument(doc,str);
      then
  ();
    case ((headerline,BackendDAE.DAE(eqs,shared)))
      equation
  print(headerline); print(":\n");
  List.map_0(eqs,printEqSystem);
  print("\n");
  printShared(shared);
      then
  ();
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
  s := "{"+&intString(e)+&":"+&s+&"}";
end tupleString;

public function dumpCompShort
  input BackendDAE.BackendDAE inDAE;
protected
  Integer sys,inp,st,seq,salg,sarr,sce;
  list<Integer> e_jc,e_jt,e_jn,e_nj,m_se,m_salg,m_sarr,m_sec;
  list<tuple<Integer,Integer>> me_jc,me_jt,me_jn,me_nj,me_lt,me_nt,te_l,te_nl;
  list<DAE.ComponentRef> states;
algorithm
  ((sys,inp,st,states,seq,salg,sarr,sce,(e_jc,e_jt,e_jn,e_nj),(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),(te_l,te_nl))) := BackendDAEUtil.foldEqSystem(inDAE,dumpCompShort1,(0,0,0,{},0,0,0,0,({},{},{},{}),({},{},{},{},{},{},{},{},{},{}),({},{})));
  print("##########################################################\n");
  print("Statistics\n");
  print("##########################################################\n");
  print("Number of independent Subsystems: " +& intString(sys) +& "\n");
  Debug.fcall(Flags.DUMP_STATESELECTION_INFO, debugStrCrefLstStr, ("selected States: ",states,", ","\n"));
  print("Number of States:           " +& intString(st) +& "\n");
  print("Toplevel Inputs:            " +& intString(inp) +& "\n\n");
  print("Single Equations:  " +& intString(seq) +& "\n");
  print("Array Equations:   " +& intString(sarr) +& "\n");
  print("Algorithms:  " +& intString(salg) +& "\n");
  print("Complex Equations: " +& intString(sce) +& "\n\n");
  print("Equationsystems with constant Jacobian:     " +& intString(listLength(e_jc)) +& " {");
  debuglst((e_jc,intString,", ","}\n"));
  print("Equationsystems with time varying Jacobian: " +& intString(listLength(e_jt)) +& " {");
  debuglst((e_jt,intString,", ","}\n"));
  print("Equationsystems with nonlinear Jacobian:    " +& intString(listLength(e_jn)) +& " {");
  debuglst((e_jn,intString,", ","}\n"));
  print("Equationsystems without analytic Jacobian:  " +& intString(listLength(e_nj)) +& " {");
  debuglst((e_nj,intString,", ","}\n\n"));
  print("mixed Equationsystems with Single Equation:       " +& intString(listLength(m_se)) +& " {");
  debuglst((m_se,intString,", ","}\n"));
  print("mixed Equationsystems with Array Equation:  " +& intString(listLength(m_sarr)) +& " {");
  debuglst((m_sarr,intString,", ","}\n"));
  print("mixed Equationsystems with Algorithm:       " +& intString(listLength(m_salg)) +& " {");
  debuglst((m_salg,intString,", ","}\n"));
  print("mixed Equationsystems with Complex Equation:      " +& intString(listLength(m_sec)) +& " {");
  debuglst((m_sec,intString,", ","}\n"));
  print("mixed Equationsystems with constant Jacobian:     " +& intString(listLength(me_jc)) +& " {");
  debuglst((me_jc,intTplString,", ","}\n"));
  print("mixed Equationsystems with time varying Jacobian: " +& intString(listLength(me_jt)) +& " {");
  debuglst((me_jt,intTplString,", ","}\n"));
  print("mixed Equationsystems with nonlinear Jacobian:    " +& intString(listLength(me_jn)) +& " {");
  debuglst((me_jn,intTplString,", ","}\n"));
  print("mixed Equationsystems without analytic Jacobian:  " +& intString(listLength(me_nj)) +& " {");
  debuglst((me_nj,intTplString,", ","}\n"));
  print("mixed Equationsystems without analytic Jacobian:  " +& intString(listLength(me_nj)) +& " {");
  debuglst((me_nj,intTplString,", ","}\n"));
  print("mixed Equationsystems with linear Tearing System:  " +& intString(listLength(me_lt)) +& " {");
  debuglst((me_lt,intTplString,", ","}\n"));
  print("mixed Equationsystems with nonlinear Tearing System:  " +& intString(listLength(me_nt)) +& " {");
  debuglst((me_nt,intTplString,", ","}\n"));
  print("torn linear Equationsystems:    " +& intString(listLength(te_l)) +& " {");
  debuglst((te_l,intTplString,", ","}\n"));
  print("torn nonlinear Equationsystems:  " +& intString(listLength(te_nl)) +& " {");
  debuglst((te_nl,intTplString,", ","}\n"));

  print("##########################################################\n");
end dumpCompShort;

protected function intTplString
  input tuple<Integer,Integer> inTpl;
  output String outStr;
protected
  Integer e,d;
algorithm
  (d,e) := inTpl;
  outStr := intString(d) +& " " +& intString(e);
end intTplString;

protected function dumpCompShort1
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  input tuple<Integer,Integer,Integer,list<DAE.ComponentRef>,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> inTpl;
  output tuple<Integer,Integer,Integer,list<DAE.ComponentRef>,Integer,Integer,Integer,Integer,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> outTpl;
algorithm
  outTpl:=
  match (inSyst,inShared,inTpl)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponents comps;
      Integer sys,inp,st,seq,salg,sarr,sce,inp1,st1,seq1,salg1,sarr1,sce1;
      tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>> eqsys,eqsys1;
      tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> meqsys,meqsys1;
      tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> teqsys,teqsys1;
      list<DAE.ComponentRef> states,states1;
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars),_,(sys,inp,st,states,seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      equation
  ((inp1,st1,states1)) = BackendVariable.traverseBackendDAEVars(vars,traversingisStateTopInputVarFinder,(inp,st,states));
  comps = BackendDAEUtil.getStrongComponents(syst);
  ((seq1,salg1,sarr1,sce1,eqsys1,meqsys1,teqsys1)) = List.fold(comps,dumpCompShort2,(seq,salg,sarr,sce,eqsys,meqsys,teqsys));
      then
  ((sys+1,inp1,st1,states1,seq1,salg1,sarr1,sce1,eqsys1,meqsys1,teqsys1));
  end match;
end dumpCompShort1;

protected function traversingisStateTopInputVarFinder
"author: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<Integer,Integer,list<DAE.ComponentRef>> > inTpl;
 output tuple<BackendDAE.Var, tuple<Integer,Integer,list<DAE.ComponentRef>> > outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      Integer inp,st;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> states;
    case ((v,(inp,st,states)))
      equation
  true = BackendVariable.isStateVar(v);
  cr = BackendVariable.varCref(v);
      then ((v,(inp,st+1,cr::states)));
    case ((v,(inp,st,states)))
      equation
  true = BackendVariable.isVarOnTopLevelAndInput(v);
      then ((v,(inp+1,st,states)));
    case _ then inTpl;
  end matchcontinue;
end traversingisStateTopInputVarFinder;

protected function dumpCompShort2
  input BackendDAE.StrongComponent inComp;
  input tuple<Integer,Integer,Integer,Integer,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> inTpl;
  output tuple<Integer,Integer,Integer,Integer,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>>,tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>,tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>>> outTpl;
algorithm
  outTpl:=
  match (inComp,inTpl)
    local
      Integer e,d;
      list<Integer> ilst,ilst1;
      Integer seq,salg,sarr,sce;
      list<Integer> e_jc,e_jt,e_jn,e_nj,m_se,m_salg,m_sarr,m_sec;
      list<tuple<Integer,Integer>> me_jc,me_jt,me_jn,me_nj,me_lt,me_nt,te_l,te_nl;
      tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>> eqsys;
      tuple<list<Integer>,list<Integer>,list<Integer>,list<Integer>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> meqsys;
      tuple<list<tuple<Integer,Integer>>,list<tuple<Integer,Integer>>> teqsys;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
    case (BackendDAE.SINGLEEQUATION(eqn=_),(seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      then
  ((seq+1,salg,sarr,sce,eqsys,meqsys,teqsys));
    case (BackendDAE.SINGLEARRAY(eqn=_),(seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      then
  ((seq,salg,sarr+1,sce,eqsys,meqsys,teqsys));
    case (BackendDAE.SINGLEIFEQUATION(eqn=_),(seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      then
  ((seq+1,salg,sarr,sce,eqsys,meqsys,teqsys));
    case (BackendDAE.SINGLEALGORITHM(eqn=_),(seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      then
  ((seq,salg+1,sarr,sce,eqsys,meqsys,teqsys));
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=_),(seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      then
  ((seq,salg,sarr,sce+1,eqsys,meqsys,teqsys));
    case (BackendDAE.SINGLEWHENEQUATION(eqn=_),(seq,salg,sarr,sce,eqsys,meqsys,teqsys))
      then
  ((seq+1,salg,sarr,sce,eqsys,meqsys,teqsys));
    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_CONSTANT()),(seq,salg,sarr,sce,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys))
      equation
  e = listLength(ilst);
      then
  ((seq,salg,sarr,sce,(e::e_jc,e_jt,e_jn,e_nj),meqsys,teqsys));
    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_TIME_VARYING()),(seq,salg,sarr,sce,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys))
      equation
  e = listLength(ilst);
      then
  ((seq,salg,sarr,sce,(e_jc,e::e_jt,e_jn,e_nj),meqsys,teqsys));
    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_NONLINEAR()),(seq,salg,sarr,sce,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys))
      equation
  e = listLength(ilst);
      then
  ((seq,salg,sarr,sce,(e_jc,e_jt,e::e_jn,e_nj),meqsys,teqsys));
    case (BackendDAE.EQUATIONSYSTEM(eqns=ilst,jacType=BackendDAE.JAC_NO_ANALYTIC()),(seq,salg,sarr,sce,(e_jc,e_jt,e_jn,e_nj),meqsys,teqsys))
      equation
  e = listLength(ilst);
      then
  ((seq,salg,sarr,sce,(e_jc,e_jt,e_jn,e::e_nj),meqsys,teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.SINGLEEQUATION(eqn=_),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
      then
  ((seq,salg,sarr,sce,eqsys,(d::m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.SINGLEALGORITHM(eqn=_),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,d::m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.SINGLECOMPLEXEQUATION(eqn=_),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,d::m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.SINGLEWHENEQUATION(eqn=_),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
      then
  ((seq,salg,sarr,sce,eqsys,(d::m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.EQUATIONSYSTEM(eqns=ilst1,jacType=BackendDAE.JAC_CONSTANT()),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
  e = listLength(ilst1);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,(d,e)::me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.EQUATIONSYSTEM(eqns=ilst1,jacType=BackendDAE.JAC_TIME_VARYING()),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
  e = listLength(ilst1);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,(d,e)::me_jt,me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.EQUATIONSYSTEM(eqns=ilst1,jacType=BackendDAE.JAC_NONLINEAR()),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
  e = listLength(ilst1);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,(d,e)::me_jn,me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.EQUATIONSYSTEM(eqns=ilst1,jacType=BackendDAE.JAC_NO_ANALYTIC()),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
  e = listLength(ilst1);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,(d,e)::me_nj,me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.TORNSYSTEM(tearingvars=ilst1,otherEqnVarTpl=eqnvartpllst,linear=true),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
  e = listLength(eqnvartpllst);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,(d,e)::me_lt,me_nt),teqsys));
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=BackendDAE.TORNSYSTEM(tearingvars=ilst1,otherEqnVarTpl=eqnvartpllst,linear=false),disc_eqns=ilst),(seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,me_nt),teqsys))
      equation
  d = listLength(ilst);
  e = listLength(eqnvartpllst);
      then
  ((seq,salg,sarr,sce,eqsys,(m_se,m_salg,m_sarr,m_sec,me_jc,me_jt,me_jn,me_nj,me_lt,(d,e)::me_nt),teqsys));
    case (BackendDAE.TORNSYSTEM(tearingvars=ilst,otherEqnVarTpl=eqnvartpllst,linear=true),(seq,salg,sarr,sce,eqsys,meqsys,(te_l,te_nl)))
      equation
  d = listLength(ilst);
  e = listLength(eqnvartpllst);
      then
  ((seq+1,salg,sarr,sce,eqsys,meqsys,((d,e)::te_l,te_nl)));
    case (BackendDAE.TORNSYSTEM(tearingvars=ilst,otherEqnVarTpl=eqnvartpllst,linear=false),(seq,salg,sarr,sce,eqsys,meqsys,(te_l,te_nl)))
      equation
  d = listLength(ilst);
  e = listLength(eqnvartpllst);
      then
  ((seq+1,salg,sarr,sce,eqsys,meqsys,(te_l,(d,e)::te_nl)));
      else
      equation
  print("dumpCompShort2 failed with:\n");
  dumpComponent(inComp);
  then fail();
  end match;
end dumpCompShort2;

public function dumpNrOfEquations
"function dumpNrOfEquations
  author Frenkel TUD 2012-11
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
  print(preStr +& " NrOfEquations: " +& intString(n) +& "\n");
end dumpNrOfEquations;
end BackendDump;
