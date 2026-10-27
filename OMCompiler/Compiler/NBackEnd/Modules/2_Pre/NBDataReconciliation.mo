/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NBDataReconciliation
" file:         NBDataReconciliation.mo
  package:      NBDataReconciliation
  description:  Extraction algorithm for data reconciliation, computes the
                auxiliary conditions (SET-C) and intermediate equations (SET-S).
"

protected
  import Module = NBModule;

  import BackendDAE = NBackendDAE;
  import BackendExtension = NFBackendExtension;
  import Causalize = NBCausalize;
  import ComponentRef = NFComponentRef;
  import NBEquation.{Equation, EqData, EquationPointers};
  import Expression = NFExpression;
  import NBMatching.Matching;
  import NFBackendExtension.Uncertainty;
  import Type = NFType;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};
  import Variable = NFVariable;

  // Util
  import Error;
  import Flags;
  import List;
  import SCodeUtil;
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;

public constant String UNDERLINE = "==========================================================================";

public uniontype ExtractionSystem
  "Index based view of the system as used by the extraction algorithm. Variables
  and equations are numbered from 1, like orderedVars and orderedEqs in the old
  backend."
  record EXTRACTION_SYSTEM
    VariablePointers vars;
    EquationPointers eqns;
    array<Pointer<Variable>> varArr;
    array<Pointer<Equation>> eqnArr;
    array<list<Integer>> adjacency  "eqn -> all variables occurring in it";
    array<Integer> var_to_eqn;
    array<Integer> eqn_to_var;
  end EXTRACTION_SYSTEM;
end ExtractionSystem;

public function main extends Module.wrapper;
  input String fileNamePrefix;
protected
  ExtractionSystem sys;
  list<Integer> knowns, boundaryConditions, bindingEquations, ebltEquations, setS;
  list<tuple<Integer, Integer>> setB;
  list<tuple<Integer, Pointer<Equation>, list<Integer>>> setBFailedBoundaryConditionEquations = {};
  Boolean status;
algorithm
  print("\nModelInfo: " + fileNamePrefix + "\n" + UNDERLINE + "\n\n");

  bdae := setBoundaryConditionEquationsAndVars(bdae);

  () := match bdae
    local
      VarData varData;
      EqData eqData;
    case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
      sys := createSystem(VariablePointers.toList(varData.unknowns), EquationPointers.toList(eqData.simulation));
      bindingEquations := getBindingEquations(sys);
      dumpOrderedVariables(sys);
      dumpOrderedEquations(sys, bindingEquations);
      dumpMatching(sys);
      // the old backend lists the matching from the last variable to the first
      dumpEquationList(sys, list(sys.var_to_eqn[i] for i in arrayLength(sys.var_to_eqn):-1:1), "Standard BLT of the original model");

      (knowns, boundaryConditions, _, _) := getVariableCategories(sys);
      dumpVarList(sys, knowns, "Variables of interest");
      dumpVarList(sys, boundaryConditions, "Boundary conditions");
      dumpEquationList(sys, bindingEquations, "Binding equations");

      ebltEquations := getEBLTEquations(sys, knowns, bindingEquations);
      dumpEquationList(sys, ebltEquations, "E-BLT: equations that compute the variables of interest");

      (setBFailedBoundaryConditionEquations, setS, _, setB, status) := traverseEBLTAndExtractSetCAndSetS(
        sys, ebltEquations, knowns, boundaryConditions, bindingEquations, setBFailedBoundaryConditionEquations);
      if status then
        print("\nExtraction procedure is successfully completed in iteration count: 1\n" + UNDERLINE + "\n");
        print("\nSET_C: " + List.toString(ebltEquations, intString) + "\nSET_S: " + List.toString(setS, intString) + "\n\n");
      else
        print("\nExtraction procedure failed for iteration count: 1, re-running with modified model\n" + UNDERLINE + "\n");
        print("\nSET_B: " + List.toString(setB, setBEntryString) + "\n\n");
      end if;
    then ();
  end match;
end main;

public function isEnabled
  output Boolean b = List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES), stringEq)
                  or List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES_ADD), stringEq);
end isEnabled;

protected function setBoundaryConditionEquationsAndVars
  "Real parameters that are boundary conditions or variables of interest, e.g.
     parameter Real x = 1 annotation(__OpenModelica_BoundaryCondition = true);
   become algebraic variables with their binding as binding equation."
  input output BackendDAE bdae;
protected
  list<Pointer<Variable>> bc_vars = {};
  list<Pointer<Equation>> bc_eqns = {};
  UnorderedSet<Pointer<Variable>> new_iters = UnorderedSet.new(BVariable.hash, BVariable.equalName);
  Variable var;
  Type ty;
algorithm
  bdae := match bdae
    local
      VarData varData;
      EqData eqData;
    case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
      for var_ptr in VariablePointers.toList(varData.parameters) loop
        var := Pointer.access(var_ptr);
        ty := Type.arrayElementType(var.ty);
        if Type.isReal(ty) and (isBoundaryCondition(var_ptr) or hasUncertainty(var_ptr, Uncertainty.REFINE) or hasUncertainty(var_ptr, Uncertainty.PROPAGATE)) then
          // the kind has to be set first, it decides the kind of the binding equation
          BVariable.setVarKind(var_ptr, BackendExtension.VariableKind.ALGEBRAIC());
          bc_eqns := Equation.generateBindingEquation(var_ptr, eqData.uniqueIndex, false, new_iters) :: bc_eqns;
          bc_vars := var_ptr :: bc_vars;
        elseif (Type.isInteger(ty) or Type.isBoolean(ty)) and isBoundaryCondition(var_ptr) then
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + ": Boundary Condition cannot be set on Integer or Boolean parameters: "
            + ComponentRef.toString(var.name) + " must be Real, The extraction algorithm will fail"});
          fail();
        end if;
      end for;

      bc_vars := listReverse(bc_vars);
      varData.parameters := VariablePointers.removeList(bc_vars, varData.parameters);
      bdae.varData := VarData.addTypedList(varData, bc_vars, VarData.VarType.ALGEBRAIC);
      bdae.eqData := EqData.addTypedList(eqData, listReverse(bc_eqns), EqData.EqType.CONTINUOUS, false);
    then bdae;
  end match;
end setBoundaryConditionEquationsAndVars;

protected function createSystem
  input list<Pointer<Variable>> var_lst;
  input list<Pointer<Equation>> eqn_lst;
  output ExtractionSystem sys;
protected
  VariablePointers vars = VariablePointers.fromList(var_lst);
  EquationPointers eqns = EquationPointers.fromList(eqn_lst);
  array<Pointer<Variable>> varArr = listArray(VariablePointers.toList(vars));
  array<Pointer<Equation>> eqnArr = listArray(EquationPointers.toList(eqns));
  array<list<Integer>> adjacency;
  Matching matching;
  list<ComponentRef> crefs;
algorithm
  // the extraction algorithm works on scalar equation and variable indices
  if VariablePointers.scalarSize(vars) <> arrayLength(varArr) or EquationPointers.scalarSize(eqns) <> arrayLength(eqnArr) then
    Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed, data reconciliation requires a scalarized system."});
    fail();
  end if;

  (matching, _) := Causalize.simple(vars, eqns, NBPartition.Kind.ODE);

  adjacency := arrayCreate(arrayLength(eqnArr), {});
  for i in 1:arrayLength(eqnArr) loop
    crefs := Equation.collectCrefs(Pointer.access(eqnArr[i]), function Equation.collectFromMap(check_map = vars.map));
    adjacency[i] := list(UnorderedMap.getSafe(cr, vars.map, sourceInfo()) for cr in crefs);
  end for;

  sys := EXTRACTION_SYSTEM(vars, eqns, varArr, eqnArr, adjacency, matching.var_to_eqn, matching.eqn_to_var);
end createSystem;

protected function getVariableCategories
  "knowns: uncertain = Uncertainty.refine
   boundaryConditions: annotation(__OpenModelica_BoundaryCondition = true)
   exactEquationVars: all others
   unmeasured: uncertain = Uncertainty.propagate, can also be a boundary condition"
  input ExtractionSystem sys;
  output list<Integer> knowns = {};
  output list<Integer> boundaryConditions = {};
  output list<Integer> exactEquationVars = {};
  output list<Integer> unmeasured = {};
protected
  Pointer<Variable> var;
algorithm
  for i in arrayLength(sys.varArr):-1:1 loop
    var := sys.varArr[i];
    if hasUncertainty(var, Uncertainty.REFINE) then
      knowns := i :: knowns;
    elseif isBoundaryCondition(var) then
      boundaryConditions := i :: boundaryConditions;
    else
      exactEquationVars := i :: exactEquationVars;
    end if;
    if hasUncertainty(var, Uncertainty.PROPAGATE) then
      unmeasured := i :: unmeasured;
    end if;
  end for;
end getVariableCategories;

protected function hasUncertainty
  input Pointer<Variable> var_ptr;
  input Uncertainty uncertainty;
  output Boolean b;
protected
  Variable var = Pointer.access(var_ptr);
algorithm
  b := match BackendExtension.VariableAttributes.getUncertainty(var.backendinfo.attributes)
    local
      Uncertainty u;
    case SOME(u) then u == uncertainty;
    else false;
  end match;
end hasUncertainty;

protected function isBoundaryCondition
  input Pointer<Variable> var_ptr;
  output Boolean b;
protected
  Variable var = Pointer.access(var_ptr);
algorithm
  b := SCodeUtil.commentHasBooleanNamedAnnotation(var.comment, "__OpenModelica_BoundaryCondition");
end isBoundaryCondition;

protected function getBindingEquations
  "binding equations are created by NBBindings with the residual name $RES_BND_<n>"
  input ExtractionSystem sys;
  output list<Integer> bindingEquations = {};
algorithm
  for i in arrayLength(sys.eqnArr):-1:1 loop
    if StringUtil.startsWith(ComponentRef.firstName(Equation.getEqnName(sys.eqnArr[i])), NBVariable.RESIDUAL_STR + "_BND_") then
      bindingEquations := i :: bindingEquations;
    end if;
  end for;
end getBindingEquations;

protected function getEBLTEquations
  "returns the equations matched to the variables of interest, without binding equations"
  input ExtractionSystem sys;
  input list<Integer> knowns;
  input list<Integer> bindingEquations;
  output list<Integer> ebltEquations = {};
protected
  Integer eqn;
algorithm
  for var in knowns loop
    eqn := sys.var_to_eqn[var];
    if eqn > 0 and not listMember(eqn, bindingEquations) then
      ebltEquations := eqn :: ebltEquations;
    end if;
  end for;
  ebltEquations := listReverse(ebltEquations);
end getEBLTEquations;

protected function getVariablesAfterExtraction
  "returns all variables occurring in the given equations"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  output list<Integer> vars = {};
algorithm
  for eqn in eqns loop
    for var in sys.adjacency[eqn] loop
      vars := var :: vars;
    end for;
  end for;
  vars := List.unique(vars);
end getVariablesAfterExtraction;

protected function traverseEBLTAndExtractSetCAndSetS
  "applies the extraction procedure on each equation of the E-BLT. If a procedure
  fails, setB contains the variable of interest and the equation involving the
  boundary condition that failed the procedure, to modify the model with."
  input ExtractionSystem sys;
  input list<Integer> ebltEquations;
  input list<Integer> knowns;
  input list<Integer> boundaryConditions;
  input list<Integer> bindingEquations;
  input output list<tuple<Integer, Pointer<Equation>, list<Integer>>> setBFailedBoundaryConditionEquations "(boundary condition var, equation, intermediate vars)";
  output list<Integer> finalSetS = {};
  output list<tuple<Integer, list<Integer>>> mappedEbltSetS = {} "(set-C eqn, set-S eqns)";
  output list<tuple<Integer, Integer>> setB = {} "(var of interest, eqn to remove)";
  output Boolean outStatus = false;
protected
  list<Integer> intermediateVars, minimalSetS, eqlistToRemove = {};
  Boolean status;
  Integer boundaryConditionVar;
algorithm
  print("\nExtracting SET-C and SET-S from E-BLT\nProcedure is applied on each equation in the E-BLT\n" + UNDERLINE);
  for eqn in ebltEquations loop
    intermediateVars := listReverse(List.setDifferenceOnTrue(getVariablesAfterExtraction(sys, {eqn}), knowns, intEq));
    dumpSetSTargetEquation(sys, eqn, ">>>");
    (minimalSetS, status, boundaryConditionVar) := extractNewMinimalSetS(sys, intermediateVars, knowns, boundaryConditions, bindingEquations, true);
    print("\nProcedure " + (if status then "success" else "failed") + "\n");
    mappedEbltSetS := (eqn, listReverse(minimalSetS)) :: mappedEbltSetS;

    for i in minimalSetS loop
      if not listMember(i, finalSetS) then
        finalSetS := i :: finalSetS;
      end if;
    end for;

    if not status then
      // the first equation is detected as boundary condition equation
      if listEmpty(minimalSetS) then
        minimalSetS := {eqn};
      end if;
      if not listMember(listHead(minimalSetS), eqlistToRemove) then
        eqlistToRemove := listHead(minimalSetS) :: eqlistToRemove;
        setB := (sys.eqn_to_var[eqn], listHead(minimalSetS)) :: setB;
        // store the failed boundary condition equations for D.2, they are removed from the modified model
        if not List.any(setBFailedBoundaryConditionEquations, function isBoundaryConditionVar(var = boundaryConditionVar)) then
          intermediateVars := listReverse(List.setDifferenceOnTrue(getVariablesAfterExtraction(sys, {listHead(minimalSetS)}), knowns, intEq));
          setBFailedBoundaryConditionEquations := (boundaryConditionVar, sys.eqnArr[listHead(minimalSetS)], intermediateVars) :: setBFailedBoundaryConditionEquations;
        end if;
      end if;
    end if;
  end for;

  if listEmpty(setB) then
    outStatus := true;
    finalSetS := listReverse(finalSetS);
    mappedEbltSetS := listReverse(mappedEbltSetS);
  else
    setB := listReverse(setB);
  end if;
end traverseEBLTAndExtractSetCAndSetS;

protected function setBEntryString
  input tuple<Integer, Integer> entry;
  output String str;
protected
  Integer var, eqn;
algorithm
  (var, eqn) := entry;
  str := "(" + intString(var) + ", " + intString(eqn) + ")";
end setBEntryString;

protected function isBoundaryConditionVar
  input tuple<Integer, Pointer<Equation>, list<Integer>> failed;
  input Integer var;
  output Boolean b;
protected
  Integer bc;
algorithm
  (bc, _, _) := failed;
  b := bc == var;
end isBoundaryConditionVar;

protected function extractNewMinimalSetS
  "constructs a minimal set-S needed to solve the intermediate variables of a set-C equation,
  by following the matching from each intermediate variable to its equation"
  input ExtractionSystem sys;
  input list<Integer> unknownsInSetC;
  input list<Integer> knowns;
  input list<Integer> boundaryConditions;
  input list<Integer> bindingEquations;
  input Boolean extractSetCAndSetS  "stop at boundary conditions, only for D.1";
  output list<Integer> minimalSetS = {};
  output Boolean status = true;
  output Integer boundaryConditionVar = -1;
protected
  list<Integer> unknowns = unknownsInSetC, rest, intermediateVars, visitedVars = {};
  Integer var, mappedEq;
algorithm
  while not listEmpty(unknowns) loop
    var :: rest := unknowns;
    visitedVars := var :: visitedVars;

    if extractSetCAndSetS and listMember(var, boundaryConditions) then
      print("\n" + varName(sys, var) + " is a boundary condition ---> exit procedure");
      status := false;
      boundaryConditionVar := var;
      break;
    end if;

    mappedEq := sys.var_to_eqn[var];
    if not listMember(mappedEq, bindingEquations) then
      minimalSetS := mappedEq :: minimalSetS;
      dumpSetSTargetEquation(sys, mappedEq, "");
    end if;

    intermediateVars := List.setDifferenceOnTrue(getVariablesAfterExtraction(sys, {mappedEq}), knowns, intEq);
    intermediateVars := List.setDifferenceOnTrue(intermediateVars, visitedVars, intEq);
    rest := List.setDifferenceOnTrue(rest, visitedVars, intEq);
    unknowns := List.unique(listAppend(intermediateVars, rest));
  end while;
end extractNewMinimalSetS;

protected function varString
  "same format as BackendDump in the old backend, e.g. Q1:VARIABLE(start = 2.0 uncertain=Uncertainty.refine)  type: Real"
  input Pointer<Variable> var_ptr;
  output String str;
protected
  Variable var = Pointer.access(var_ptr);
  String kind, attr;
algorithm
  kind := match var.backendinfo.varKind
    case BackendExtension.VariableKind.ALGEBRAIC() then "VARIABLE";
    case BackendExtension.VariableKind.STATE()     then "STATE";
    case BackendExtension.VariableKind.DISCRETE()  then "DISCRETE";
    else BackendExtension.VariableKind.toString(var.backendinfo.varKind);
  end match;
  attr := stringDelimitList(list(s for s guard(not stringEmpty(s)) in {
    BackendExtension.VariableAttributes.toString(var.backendinfo.attributes),
    uncertaintyString(BackendExtension.VariableAttributes.getUncertainty(var.backendinfo.attributes))}), " ");
  str := ComponentRef.toString(var.name) + ":" + kind + "(" + attr + ")  type: " + Type.toString(var.ty);
end varString;

protected function uncertaintyString
  input Option<Uncertainty> uncertainty;
  output String str;
algorithm
  str := match uncertainty
    case SOME(Uncertainty.GIVEN)     then "uncertain=Uncertainty.given";
    case SOME(Uncertainty.SOUGHT)    then "uncertain=Uncertainty.sought";
    case SOME(Uncertainty.REFINE)    then "uncertain=Uncertainty.refine";
    case SOME(Uncertainty.PROPAGATE) then "uncertain=Uncertainty.propagate";
    else "";
  end match;
end uncertaintyString;

protected function equationString
  "lhs = rhs without the attributes of the new backend, like BackendDump.equationString"
  input Pointer<Equation> eqn_ptr;
  output String str;
protected
  Equation eqn = Pointer.access(eqn_ptr);
algorithm
  str := match (Equation.getLHS(eqn), Equation.getRHS(eqn))
    local
      Expression lhs, rhs;
    case (SOME(lhs), SOME(rhs)) then Expression.toString(lhs) + " = " + Expression.toString(rhs);
    else Equation.toString(eqn);
  end match;
end equationString;

protected function dumpOrderedVariables
  input ExtractionSystem sys;
algorithm
  print("\nOrderedVariables (" + intString(arrayLength(sys.varArr)) + ")\n========================================\n");
  for i in 1:arrayLength(sys.varArr) loop
    print(intString(i) + ": " + varString(sys.varArr[i]) + "\n");
  end for;
  print("\n");
end dumpOrderedVariables;

protected function dumpOrderedEquations
  input ExtractionSystem sys;
  input list<Integer> bindingEquations;
protected
  Integer n = arrayLength(sys.eqnArr);
algorithm
  print("\nOrderedEquation (" + intString(n) + ", " + intString(EquationPointers.scalarSize(sys.eqns)) + ")\n========================================\n");
  for i in 1:n loop
    print(intString(i) + "/" + intString(i) + " (" + intString(Equation.size(sys.eqnArr[i])) + "): " + equationString(sys.eqnArr[i])
      + (if listMember(i, bindingEquations) then "   [binding]" else "   [dynamic]") + "\n");
  end for;
  print("\n");
end dumpOrderedEquations;

protected function dumpMatching
  input ExtractionSystem sys;
algorithm
  print("Matching\n========================================\n" + intString(arrayLength(sys.var_to_eqn)) + " variables and equations\n");
  for i in 1:arrayLength(sys.var_to_eqn) loop
    print("var " + intString(i) + " is solved in eqn " + intString(sys.var_to_eqn[i]) + "\n");
  end for;
end dumpMatching;

protected function varName
  input ExtractionSystem sys;
  input Integer var;
  output String str = if var > 0 then ComponentRef.toString(BVariable.getVarName(sys.varArr[var])) else "-";
end varName;

protected function dumpSetSTargetEquation
  "same format as dumpSetSTargetEquations in the old backend:
  <prefix><solved var index>: <solved var>: (<eqn>/<eqn>): (<size>): <equation>"
  input ExtractionSystem sys;
  input Integer eqn;
  input String prefix;
protected
  Integer var = sys.eqn_to_var[eqn];
algorithm
  print("\n" + prefix + intString(var) + ": " + varName(sys, var) + ": (" + intString(eqn) + "/" + intString(eqn)
    + "): (" + intString(Equation.size(sys.eqnArr[eqn])) + "): " + equationString(sys.eqnArr[eqn]));
end dumpSetSTargetEquation;

protected function dumpEquationList
  "same format as dumpSetSVarsSolvedInfo in the old backend"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  input String heading;
algorithm
  print("\n" + heading + ":(" + intString(listLength(eqns)) + ")\n============================================================\n");
  for eqn in eqns loop
    dumpSetSTargetEquation(sys, eqn, "");
  end for;
  print("\n\n");
end dumpEquationList;

protected function dumpVarList
  input ExtractionSystem sys;
  input list<Integer> vars;
  input String heading;
protected
  Integer i = 1;
algorithm
  print("\n" + heading + " (" + intString(listLength(vars)) + ")\n========================================\n");
  for var in vars loop
    print(intString(i) + ": " + varString(sys.varArr[var]) + "\n");
    i := i + 1;
  end for;
  print("\n");
end dumpVarList;

annotation(__OpenModelica_Interface="nbackend");
end NBDataReconciliation;
