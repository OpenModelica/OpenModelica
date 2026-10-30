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
  import NFBinding.Binding;
  import Causalize = NBCausalize;
  import Jacobian = NBJacobian;
  import StrongComponent = NBStrongComponent;
  import ComponentRef = NFComponentRef;
  import NBEquation.{Equation, EqData, EquationAttributes, EquationKind, EquationPointers, Iterator};
  import Expression = NFExpression;
  import NBMatching.Matching;
  import NFBackendExtension.Uncertainty;
  import Attributes = NFAttributes;
  import NFPrefixes;
  import Slice = NBSlice;
  import Type = NFType;
  import BVariable = NBVariable;
  import NBVariable.{VariablePointers, VarData};
  import Variable = NFVariable;

  // Util
  import Absyn;
  import DAE;
  import Error;
  import Flags;
  import List;
  import ProgramUtil;
  import SCode;
  import SCodeUtil;
  import Settings;
  import StringUtil;
  import System;
  import UnorderedMap;
  import UnorderedSet;
  import Util;

public constant String UNDERLINE = "==========================================================================";

public uniontype ExtractionSystem
  "Index based view of the system as used by the extraction algorithm. Variables
  and equations are numbered from 1, like orderedVars and orderedEqs in the old
  backend. An equation of size n, e.g. a record equation, has n scalar rows; the
  matching and the extraction work on rows, like the old backend."
  record EXTRACTION_SYSTEM
    VariablePointers vars;
    EquationPointers eqns;
    array<Pointer<Variable>> varArr;
    array<Pointer<Equation>> eqnArr;
    array<Integer> rowToEqn         "mapIncRowEqn in the old backend";
    array<list<Integer>> eqnToRows  "mapEqnIncRow in the old backend";
    array<Integer> colToVar         "the scalar variables (columns) of the old backend";
    array<ComponentRef> colNames;
    array<list<Integer>> adjacency  "row -> all columns occurring in its equation";
    array<Integer> var_to_row;
    array<Integer> row_to_var;
  end EXTRACTION_SYSTEM;
end ExtractionSystem;

public uniontype ReconciliationData
  "The system the runtime reconciles: the residuals of SET-C are computed from the
  variables of interest (inputs) with the help of SET-S."
  record RECONCILIATION_DATA
    list<Pointer<Variable>> inputVars       "variables of interest";
    list<Pointer<Variable>> residualVars    "$RES_F_i, one per SET-C equation";
    list<Pointer<Equation>> residualEqns    "$RES_F_i = rhs - lhs of the SET-C equations";
    list<Pointer<Variable>> setSVars        "unknowns of SET-S";
    list<Pointer<Equation>> setSEqns;
    list<Pointer<Variable>> parameters      "parameters in SET-C and SET-S";
    list<Pointer<Variable>> unmeasuredVars  "uncertain = Uncertainty.propagate";
    Integer relatedBoundaryConditions;
    Option<BackendDAE> jacobian             "F = d$RES_F/d inputVars, created by createJacobian";
  end RECONCILIATION_DATA;
end ReconciliationData;

public function main extends Module.wrapper;
protected
  BackendDAE.ExtraInfo info = BackendDAE.getExtraInfo(bdae);
  String fileNamePrefix = info.fileNamePrefix;
  String csvFileName;
  ExtractionSystem sys;
  list<Integer> knowns = {}, boundaryConditionVars, boundaryConditions, bindingEquations = {}, ebltEquations = {}, setC, setS = {};
  list<Integer> approximatedEquations = {}, approximatedRows = {}, boundaryConditionEquations, setSVars, unmeasured = {};
  list<Integer> setCEqns, setSEqns "SET-C and SET-S as equations, the extraction works on rows";
  list<tuple<Integer, Integer>> setB;
  list<tuple<Integer, list<Integer>>> mappedEbltSetS = {};
  list<tuple<Integer, Pointer<Equation>, list<Integer>>> setBFailedBoundaryConditionEquations = {};
  list<Pointer<Variable>> unknowns, var_lst, bc_vars, params;
  list<Pointer<Equation>> eqn_lst, bc_eqns;
  ReconciliationData data;
  list<tuple<String, String>> measurements;
  Boolean status = false;
  Integer procedureCount = 1;
algorithm
  print("\nModelInfo: " + fileNamePrefix + "\n" + UNDERLINE + "\n\n");

  () := match bdae
    local
      VarData varData;
      EqData eqData;
    case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
      // the old backend stores the variables in reverse order, followed by the boundary condition
      // parameters, whose binding equations come first
      unknowns := listReverse(VariablePointers.toList(varData.unknowns));
      eqn_lst := EquationPointers.toList(eqData.simulation);
    then ();
  end match;

  (bdae, bc_vars, bc_eqns) := setBoundaryConditionEquationsAndVars(bdae);
  var_lst := listAppend(unknowns, bc_vars);
  eqn_lst := listAppend(bc_eqns, eqn_lst);

  data := match bdae
    local
      VarData varData;
      EqData eqData;
    case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
      // run the procedure on a modified model until it succeeds
      sys := createSystem(var_lst, eqn_lst);
      while not status loop
        bindingEquations := getBindingEquations(sys);
        dumpOrderedVariables(sys);
        //print(VariablePointers.toString(sys.vars, "Ordered Vars new backend"));
        //print(EquationPointers.toString(sys.eqns, "Ordered Eqs new backend"));
        dumpEquationArray(sys, List.intRange(arrayLength(sys.eqnArr)), bindingEquations, "OrderedEquation");
        dumpMatching(sys);
        // the old backend lists the matching from the last variable to the first
        dumpEquationList(sys, list(sys.var_to_row[i] for i in arrayLength(sys.var_to_row):-1:1), "Standard BLT of the original model");

        (approximatedEquations, boundaryConditionEquations) := getEquationsTaggedApproximatedOrBoundaryCondition(sys);
        approximatedRows := rowsOf(sys, approximatedEquations);

        (knowns, boundaryConditionVars, _, unmeasured) := getVariableCategories(sys);
        // the variables solved by equations tagged as boundary condition are boundary conditions too
        boundaryConditions := listAppend(boundaryConditionVars, list(sys.row_to_var[row] for row in rowsOf(sys, boundaryConditionEquations)));
        dumpVarList(sys, knowns, "Variables of interest");
        dumpVarList(sys, boundaryConditions, "Boundary conditions");
        dumpEquationList(sys, bindingEquations, "Binding equations");
        dumpEquations(sys, approximatedEquations, bindingEquations, "Approximated equations");
        dumpEquations(sys, boundaryConditionEquations, bindingEquations, "boundary condition equations");

        ebltEquations := getEBLTEquations(sys, knowns, bindingEquations);
        dumpEquationList(sys, ebltEquations, "E-BLT: equations that compute the variables of interest");

        (setBFailedBoundaryConditionEquations, setS, mappedEbltSetS, setB, status) := traverseEBLTAndExtractSetCAndSetS(
          sys, ebltEquations, knowns, boundaryConditions, bindingEquations, setBFailedBoundaryConditionEquations);

        if not status then
          print("\nExtraction procedure failed for iteration count: " + intString(procedureCount) + ", re-running with modified model\n" + UNDERLINE + "\n");
          eqn_lst := modifyModel(sys, setB, eqData.uniqueIndex);
          sys := createSystem(var_lst, eqn_lst);
          procedureCount := procedureCount + 1;
        end if;
      end while;

      print("\nExtraction procedure is successfully completed in iteration count: " + intString(procedureCount) + "\n" + UNDERLINE + "\n");

      // remove approximated equations from SET-C and SET-S
      setC := List.setDifferenceOnTrue(ebltEquations, approximatedRows, intEq);
      setS := List.setDifferenceOnTrue(setS, approximatedRows, intEq);
      (setC, setS) := swapComplexEquationsInSetC(sys, setC, setS, mappedEbltSetS, bindingEquations);
      setCEqns := eqnsOf(sys, setC);
      setSEqns := eqnsOf(sys, setS);

      print("\nFinal set of equations after extraction algorithm\n" + UNDERLINE + "\nSET_C: " + List.toString(setCEqns, intString) + "\nSET_S: " + List.toString(setSEqns, intString) + "\n\n");
      dumpEquationArray(sys, setCEqns, bindingEquations, "SET_C");
      dumpEquationArray(sys, setSEqns, bindingEquations, "SET_S");

      setSVars := List.setDifferenceOnTrue(getVariablesAfterExtraction(sys, setS), knowns, intEq);
      dumpSetSVars(sys, setSVars, "Unknown variables in SET_S");
      params := getParameters(sys, listAppend(setSEqns, setCEqns), varData.parameters);
      dumpVariables(params, "Parameters in SET_S");

      System.writeFile(fileNamePrefix + "_AuxiliaryConditions.html", dumpExtractedEquationsToHTML(list(sys.eqnArr[eqn] for eqn in setCEqns), "Auxiliary conditions"));
      System.writeFile(fileNamePrefix + "_IntermediateEquations.html", dumpExtractedEquationsToHTML(list(sys.eqnArr[eqn] for eqn in setSEqns), "Intermediate equations for measured variables"));
      dumpRelatedBoundaryConditionsEquations(setBFailedBoundaryConditionEquations, fileNamePrefix);

      verifyDataReconciliation(sys, setC, setS, setCEqns, setSEqns, knowns, setSVars, listLength(unmeasured), fileNamePrefix);

      data := createReconciliationData(sys, setCEqns, setSEqns, knowns, setSVars, params, unmeasured, listLength(setBFailedBoundaryConditionEquations), eqData.uniqueIndex);
      if Flags.isSet(Flags.DUMP_DATARECONCILIATION) then
        dumpReconciliationData(data);
      end if;
    then data;
  end match;

  // the measurements as start values help the convergence
  (csvFileName, measurements) := readMeasurementsFromCSV(info.simflags, info.program);
  setStartValuesToMeasurements(data.inputVars, measurements, csvFileName);

  // templates for the measurements, existing files of the user are not overwritten
  if not System.regularFileExists(fileNamePrefix + "_Inputs.csv") then
    System.writeFile(fileNamePrefix + "_Inputs.csv", "Variable Names,Measured Value-x,HalfWidthConfidenceInterval\n"
      + dumpToCsv(data.inputVars));
  end if;
  if not System.regularFileExists(fileNamePrefix + "_Correlation_Inputs.csv") then
    System.writeFile(fileNamePrefix + "_Correlation_Inputs.csv", dumpCorrelationVarsToCsv(data.inputVars) + "\n"
      + dumpToCsv(data.inputVars));
  end if;
  // write the new Reconciled vars and equations to .mo File
  System.writeFile(fileNamePrefix + "_Reconciled_tmp.mo", dumpReconciledModel(data, fileNamePrefix));
  bdae := replaceModel(bdae, data);
end main;

protected function extractSxPath
  "returns the csv file of the -sx flag in the simulation flags"
  input String simflags;
  output String csvFilePath = "";
protected
  Integer nummatches;
  list<String> matches;
algorithm
  if System.stringFind(simflags, "-sx") < 0 then
    Error.addMessage(Error.INTERNAL_ERROR, {": No -sx flag found in simflags, hence no csv file will be read for setting start values of the variables of interest for data reconciliation initialization."});
    fail();
  end if;

  (nummatches, matches) := System.regex(simflags, "-sx[ \t]*=[ \t]*(\"[^\"]*\"|[^, \t]+)", 2, true);
  if nummatches == 2 then
    csvFilePath := System.stringReplace(listGet(matches, 2), " ", "");
    csvFilePath := System.stringReplace(csvFilePath, "\"", "");
  end if;
end extractSxPath;

protected function readMeasurementsFromCSV
  "reads the (name, value) pairs of the -sx csv file"
  input Option<String> simflags;
  input Absyn.Program program;
  output String csvFileName;
  output list<tuple<String, String>> measurementData = {};
protected
  String content;
  list<String> tokens;
algorithm
  if isNone(simflags) then
    Error.addMessage(Error.INTERNAL_ERROR, {": simflags is NONE, expected the simulation flags to be present for reading measurements from csv file for data reconciliation initialization."});
    fail();
  end if;

  csvFileName := extractSxPath(Util.getOption(simflags));
  if stringEmpty(csvFileName) then
    Error.addMessage(Error.INTERNAL_ERROR, {": No csv file provided or failed to read file with -sx flag in simflags."});
    fail();
  end if;

  if StringUtil.startsWith(csvFileName, "modelica://") or StringUtil.startsWith(csvFileName, "file://") then
    csvFileName := ProgramUtil.getFullPathFromUri(program, csvFileName, true);
  end if;

  content := System.readFile(csvFileName);
  if stringEmpty(content) then
    Error.addMessage(Error.INTERNAL_ERROR, {": Failed to read csv file content from " + csvFileName + " and hence start values can not be set."});
    fail();
  end if;

  for line in System.strtok(content, "\n") loop
    line := System.trim(System.stringReplace(line, ";", ","));
    tokens := Util.stringSplitAtChar(line, ",");
    if listLength(tokens) >= 2 then
      measurementData := (listGet(tokens, 1), listGet(tokens, 2)) :: measurementData;
    end if;
  end for;
end readMeasurementsFromCSV;

protected function setStartValuesToMeasurements
  input list<Pointer<Variable>> vars;
  input list<tuple<String, String>> measurementData;
  input String csvFileName;
protected
  String name;
  Option<String> valueStr;
  Real value;
algorithm
  for var_ptr in vars loop
    name := ComponentRef.toString(BVariable.getVarName(var_ptr));
    valueStr := List.findSome(measurementData, function measurementValue(name = name));
    if isNone(valueStr) then
      Error.addMessage(Error.INTERNAL_ERROR, {": Entry for variable of interest " + name + " not found in the measurement csv file " + csvFileName});
      fail();
    end if;
    try
      value := stringReal(Util.getOption(valueStr));
    else
      Error.addMessage(Error.INTERNAL_ERROR, {": Failed to convert the measurement value \"" + Util.getOption(valueStr) + "\" for variable of interest " + name + " from csv file " + csvFileName + " to a valid Real number for setting start value for data reconciliation initialization."});
      fail();
    end try;
    Pointer.update(var_ptr, BVariable.setStartAttribute(Pointer.access(var_ptr), Expression.REAL(value), true));
  end for;
end setStartValuesToMeasurements;

protected function measurementValue
  input tuple<String, String> measurement;
  input String name;
  output Option<String> value;
protected
  String var_name, str;
algorithm
  (var_name, str) := measurement;
  value := if var_name == name then SOME(str) else NONE();
end measurementValue;

// TODO: algebraic loops in SET-S, e.g. a torn loop over pressure drop and density, become loops
//   of the jacobian F. The new backend cannot generate loops inside a jacobian yet, so such models
//   fail at runtime ("residual function pointer is invalid"). The old backend generates them as
//   linear systems of the model (SimCodeUtil.addAlgebraicLoopsModelInfoSymJacs) that are part of
//   the jacobian (partOfJac, parentJacobian in the runtime). For the new backend NSimCode needs to:
//   1. resolve the iteration variables of a loop in SimJacobian.create with the jac_map of the
//      jacobian instead of the empty dummy map, so that the loop becomes a LINEAR block (the
//      derivative of a loop is always linear, see NBDifferentiate),
//   2. create these LINEAR_SYSTEMs with partOfJac = true and a jacobian of their own w.r.t. the
//      $pDER iteration variables,
//   3. collect them into the linear systems of the model, as NSimCode does for the partitions.
//   This is the TODO about the linear systems of jacobians in NSimCode.main and also concerns the
//   simulation jacobian A.
public function createJacobian
  "Creates the jacobian F of the residuals with respect to the variables of interest,
  SET-S gives the inner derivatives. Needs the solved strong components."
  extends Module.wrapper;
protected
  Boolean scalarized = Flags.isSet(Flags.NF_SCALARIZE);
algorithm
  bdae := match bdae
    local
      ReconciliationData data;
      list<NBPartition.Partition> partitions;
      list<StrongComponent> comps;
      list<Pointer<Variable>> unknowns;
      list<Pointer<Equation>> equations;

    case BackendDAE.MAIN(dataReconciliation = SOME(data as RECONCILIATION_DATA())) algorithm
      partitions := listAppend(bdae.ode, bdae.algebraic);
      comps := List.flatten(list(arrayList(Util.getOption(p.strongComponents)) for p guard(isSome(p.strongComponents)) in partitions));
      // the runtime reads the columns in the order of the inputs and the rows in the order of the residuals
      unknowns := List.flatten(list(VariablePointers.toList(p.unknowns) for p in partitions));
      unknowns := listAppend(data.residualVars, List.filterOnFalse(unknowns, isResidual));
      equations := List.flatten(list(EquationPointers.toList(p.equations) for p in partitions));

      data.jacobian := Jacobian.dataReconciliation(
        seedCandidates      = VariablePointers.fromList(data.inputVars, scalarized),
        partialCandidates   = VariablePointers.fromList(unknowns, scalarized),
        equations           = EquationPointers.fromList(equations),
        comps               = listArray(comps),
        funcMap             = bdae.funcMap,
        name                = "F");
      bdae.dataReconciliation := SOME(data);
    then bdae;

    else bdae;
  end match;
end createJacobian;

public function isVariableOfInterest
  "true for the variables of interest after the model has been replaced by the reconciled
  system, they are known inputs even if they are not top level"
  input Pointer<Variable> var_ptr;
  output Boolean b = BVariable.isInput(var_ptr) and hasUncertainty(var_ptr, Uncertainty.REFINE);
end isVariableOfInterest;

public function isResidual
  "the residuals $RES_F_<i> are the result variables of the jacobian F"
  input Pointer<Variable> var_ptr;
  output Boolean b = StringUtil.startsWith(ComponentRef.firstName(BVariable.getVarName(var_ptr)), NBVariable.RESIDUAL_STR + "_F_");
end isResidual;

public function isEnabled
  output Boolean b = List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES), stringEq)
                  or List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES_ADD), stringEq);
end isEnabled;

protected function setBoundaryConditionEquationsAndVars
  "Real parameters that are boundary conditions or variables of interest, e.g.
     parameter Real x = 1 annotation(__OpenModelica_BoundaryCondition = true);
   become algebraic variables with their binding as binding equation."
  input output BackendDAE bdae;
  output list<Pointer<Variable>> bc_vars = {};
  output list<Pointer<Equation>> bc_eqns = {};
protected
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
      bc_eqns := listReverse(bc_eqns);
      varData.parameters := VariablePointers.removeList(bc_vars, varData.parameters);
      bdae.varData := VarData.addTypedList(varData, bc_vars, VarData.VarType.ALGEBRAIC);
      bdae.eqData := EqData.addTypedList(eqData, bc_eqns, EqData.EqType.CONTINUOUS, false);
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
  array<Integer> rowToEqn;
  array<list<Integer>> eqnToRows, adjacency, varToCols;
  array<Integer> colToVar;
  array<ComponentRef> colNames;
  Matching matching;
  list<ComponentRef> crefs, names;
  list<Integer> vars_of_eqn;
  Integer row = 1, col = 1, size;
algorithm
  // the matching numbers the scalar elements of the variables and the rows of the equations in their order
  (matching, _) := Causalize.simple(vars, eqns, NBPartition.Kind.ODE);

  colToVar := arrayCreate(VariablePointers.scalarSize(vars), 0);
  colNames := arrayCreate(arrayLength(colToVar), ComponentRef.EMPTY());
  varToCols := arrayCreate(arrayLength(varArr), {});
  for i in 1:arrayLength(varArr) loop
    names := listReverse(ComponentRef.scalarizeAll(BVariable.getVarName(varArr[i]), false));
    varToCols[i] := List.intRange2(col, col + listLength(names) - 1);
    for name in names loop
      colToVar[col] := i;
      colNames[col] := name;
      col := col + 1;
    end for;
  end for;

  rowToEqn := arrayCreate(EquationPointers.scalarSize(eqns), 0);
  eqnToRows := arrayCreate(arrayLength(eqnArr), {});
  adjacency := arrayCreate(arrayLength(rowToEqn), {});
  for i in 1:arrayLength(eqnArr) loop
    // a record, e.g. f(r), depends on all its elements and an array element, e.g. x[1], on all elements of x
    crefs := Equation.collectCrefs(Pointer.access(eqnArr[i]), function Slice.getDependentCref(map = vars.map, pseudo = true));
    vars_of_eqn := List.unique(List.flatten(list(varToCols[UnorderedMap.getSafe(ComponentRef.stripSubscriptsAll(cr), vars.map, sourceInfo())] for cr in crefs)));
    // descending, so that the procedure visits the variables in ascending order like the old backend
    vars_of_eqn := List.sort(vars_of_eqn, intLt);
    size := Equation.size(eqnArr[i]);
    eqnToRows[i] := List.intRange2(row, row + size - 1);
    for r in row:row + size - 1 loop
      rowToEqn[r] := i;
      adjacency[r] := vars_of_eqn;
    end for;
    row := row + size;
  end for;

  sys := EXTRACTION_SYSTEM(vars, eqns, varArr, eqnArr, rowToEqn, eqnToRows, colToVar, colNames, adjacency, matching.var_to_eqn, matching.eqn_to_var);
end createSystem;

protected function varOf
  input ExtractionSystem sys;
  input Integer col;
  output Pointer<Variable> var = sys.varArr[sys.colToVar[col]];
end varOf;

protected function scalarVarOf
  "the variables of the reconciled system have to be scalar"
  input ExtractionSystem sys;
  input Integer col;
  output Pointer<Variable> var = varOf(sys, col);
algorithm
  if BVariable.size(var) <> 1 then
    Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed, data reconciliation of the array variable "
      + BVariable.pointerToString(var) + " is not supported yet."});
    fail();
  end if;
end scalarVarOf;

protected function rowsOf
  "maps equations to their rows, mapEqnIncRow in the old backend"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  output list<Integer> rows = List.flatten(list(sys.eqnToRows[eqn] for eqn in eqns));
end rowsOf;

protected function eqnsOf
  "maps rows to their unique equations, getAbsoluteIndexHelper in the old backend"
  input ExtractionSystem sys;
  input list<Integer> rows;
  output list<Integer> eqns = List.unique(list(sys.rowToEqn[row] for row in rows));
end eqnsOf;

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
  for i in arrayLength(sys.colToVar):-1:1 loop
    var := varOf(sys, i);
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
  "rows of the binding equations, which are created by NBBindings with the residual name $RES_BND_<n>"
  input ExtractionSystem sys;
  output list<Integer> bindingRows;
protected
  list<Integer> bindingEquations = {} "descending, like in the old backend";
algorithm
  for i in 1:arrayLength(sys.eqnArr) loop
    if StringUtil.startsWith(ComponentRef.firstName(Equation.getEqnName(sys.eqnArr[i])), NBVariable.RESIDUAL_STR + "_BND_") then
      bindingEquations := i :: bindingEquations;
    end if;
  end for;
  bindingRows := rowsOf(sys, bindingEquations);
end getBindingEquations;

protected function getEquationsTaggedApproximatedOrBoundaryCondition
  "returns the equations with annotation(__OpenModelica_ApproximatedEquation = true) and
  annotation(__OpenModelica_BoundaryCondition = true), descending like in the old backend"
  input ExtractionSystem sys;
  output list<Integer> approximatedEquations = {};
  output list<Integer> boundaryConditionEquations = {};
protected
  list<SCode.Comment> comments;
algorithm
  for i in 1:arrayLength(sys.eqnArr) loop
    DAE.SOURCE(comment = comments) := Equation.getSource(Pointer.access(sys.eqnArr[i]));
    if List.any(comments, function SCodeUtil.commentHasBooleanNamedAnnotation(annotationName = "__OpenModelica_ApproximatedEquation")) then
      approximatedEquations := i :: approximatedEquations;
    elseif List.any(comments, function SCodeUtil.commentHasBooleanNamedAnnotation(annotationName = "__OpenModelica_BoundaryCondition")) then
      boundaryConditionEquations := i :: boundaryConditionEquations;
    end if;
  end for;
end getEquationsTaggedApproximatedOrBoundaryCondition;

protected function getEBLTEquations
  "returns the rows matched to the variables of interest, without binding equations"
  input ExtractionSystem sys;
  input list<Integer> knowns;
  input list<Integer> bindingRows;
  output list<Integer> ebltRows = {};
protected
  Integer row;
algorithm
  for var in knowns loop
    row := sys.var_to_row[var];
    if row > 0 and not listMember(row, bindingRows) then
      ebltRows := row :: ebltRows;
    end if;
  end for;
  ebltRows := listReverse(ebltRows);
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
        setB := (sys.row_to_var[eqn], listHead(minimalSetS)) :: setB;
        // store the failed boundary condition equations for D.2, they are removed from the modified model
        if not List.any(setBFailedBoundaryConditionEquations, function isBoundaryConditionVar(var = boundaryConditionVar)) then
          intermediateVars := listReverse(List.setDifferenceOnTrue(getVariablesAfterExtraction(sys, {listHead(minimalSetS)}), knowns, intEq));
          setBFailedBoundaryConditionEquations := (boundaryConditionVar, sys.eqnArr[sys.rowToEqn[listHead(minimalSetS)]], intermediateVars) :: setBFailedBoundaryConditionEquations;
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

protected function modifyModel
  "For each failed procedure, the equation involving the boundary condition that
  failed the procedure is replaced by x = 0 where x is the variable of interest of
  the procedure. The new equations are binding equations, like in the old backend."
  input ExtractionSystem sys;
  input list<tuple<Integer, Integer>> setB "(var of interest, row to remove)";
  input Pointer<Integer> uniqueIndex;
  output list<Pointer<Equation>> eqn_lst = {};
protected
  list<Integer> eqlistToRemove = eqnsOf(sys, list(Util.tuple22(entry) for entry in setB));
algorithm
  for i in arrayLength(sys.eqnArr):-1:1 loop
    if not listMember(i, eqlistToRemove) then
      eqn_lst := sys.eqnArr[i] :: eqn_lst;
    end if;
  end for;

  for entry in listReverse(setB) loop
    eqn_lst := Equation.makeAssignment(Expression.fromCref(sys.colNames[Util.tuple21(entry)]), Expression.REAL(0.0), uniqueIndex,
      "BND", Iterator.EMPTY(), EquationAttributes.default(EquationKind.CONTINUOUS, false)) :: eqn_lst;
  end for;
end modifyModel;

protected function getParameters
  "returns the parameters occurring in the given equations, sorted by name"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  input VariablePointers parameters;
  output list<Pointer<Variable>> params;
protected
  list<ComponentRef> crefs = {};
algorithm
  for eqn in listReverse(eqns) loop
    crefs := listAppend(Equation.collectCrefs(Pointer.access(sys.eqnArr[eqn]), function Equation.collectFromMap(check_map = parameters.map)), crefs);
  end for;
  crefs := List.sort(UnorderedSet.unique_list(crefs, ComponentRef.hash, ComponentRef.isEqual), crefNameGreater);
  params := list(BVariable.getVarPointer(cr, sourceInfo()) for cr in crefs);
end getParameters;

protected function createReconciliationData
  input ExtractionSystem sys;
  input list<Integer> setC;
  input list<Integer> setS;
  input list<Integer> knowns;
  input list<Integer> setSVars;
  input list<Pointer<Variable>> parameters;
  input list<Integer> unmeasured;
  input Integer relatedBoundaryConditions;
  input Pointer<Integer> uniqueIndex;
  output ReconciliationData data;
protected
  Pointer<Variable> res_var;
  ComponentRef res_cref;
  list<Pointer<Variable>> residualVars = {};
  list<Pointer<Equation>> residualEqns = {};
  Integer i = 1;
algorithm
  for eqn in setC loop
    (res_var, res_cref) := BVariable.makeResidualVar("F", i, Type.REAL());
    // the residuals are computed from the inputs like any algebraic variable
    BVariable.setVarKind(res_var, BackendExtension.VariableKind.ALGEBRAIC());
    residualVars := res_var :: residualVars;
    residualEqns := Equation.makeAssignment(Expression.fromCref(res_cref), Equation.getResidualExp(Pointer.access(sys.eqnArr[eqn])),
      uniqueIndex, NBEquation.SIMULATION_STR, Iterator.EMPTY(), EquationAttributes.default(EquationKind.CONTINUOUS, false)) :: residualEqns;
    i := i + 1;
  end for;

  data := RECONCILIATION_DATA(
    inputVars                 = list(scalarVarOf(sys, v) for v in knowns),
    residualVars              = listReverse(residualVars),
    residualEqns              = listReverse(residualEqns),
    setSVars                  = list(scalarVarOf(sys, v) for v in setSVars),
    setSEqns                  = list(sys.eqnArr[eqn] for eqn in setS),
    parameters                = parameters,
    unmeasuredVars            = list(scalarVarOf(sys, v) for v in unmeasured),
    relatedBoundaryConditions = relatedBoundaryConditions,
    jacobian                  = NONE());
end createReconciliationData;

protected function replaceModel
  "Replaces the model with the system the runtime reconciles: the residuals and SET-S
  are the only equations, the variables of interest are inputs and only the parameters
  in SET-C and SET-S are kept, like in the old backend."
  input output BackendDAE bdae;
  input ReconciliationData data;
protected
  Boolean scalarized = Flags.isSet(Flags.NF_SCALARIZE);
  list<Pointer<Variable>> unknowns = listAppend(data.residualVars, data.setSVars);
  list<Pointer<Equation>> equations = listAppend(data.residualEqns, data.setSEqns);
  Variable var;
  Attributes attr;
algorithm
  for var_ptr in data.inputVars loop
    var := Pointer.access(var_ptr);
    attr := var.attributes;
    attr.direction := NFPrefixes.Direction.INPUT;
    var.attributes := attr;
    Pointer.update(var_ptr, var);
  end for;

  bdae := match bdae
    local
      VarData varData;
      EqData eqData;
    case BackendDAE.MAIN(varData = varData as VarData.VAR_DATA_SIM(), eqData = eqData as EqData.EQ_DATA_SIM()) algorithm
      varData.variables       := VariablePointers.addList(data.residualVars, varData.variables);
      varData.unknowns        := VariablePointers.fromList(unknowns, scalarized);
      varData.algebraics      := VariablePointers.fromList(unknowns, scalarized);
      varData.initials        := VariablePointers.fromList(unknowns, scalarized);
      varData.knowns          := VariablePointers.removeList(listAppend(VariablePointers.toList(varData.states), listAppend(
                                   VariablePointers.toList(varData.previous), VariablePointers.toList(varData.parameters))), varData.knowns);
      varData.knowns          := VariablePointers.addList(listAppend(data.inputVars, data.parameters), varData.knowns);
      varData.top_level_inputs:= VariablePointers.fromList(data.inputVars, scalarized);
      varData.parameters      := VariablePointers.fromList(data.parameters, scalarized);
      varData.states          := VariablePointers.empty(scalarized = scalarized);
      varData.derivatives     := VariablePointers.empty(scalarized = scalarized);
      varData.discretes       := VariablePointers.empty(scalarized = scalarized);
      varData.discrete_states := VariablePointers.empty(scalarized = scalarized);
      varData.clocked_states  := VariablePointers.empty(scalarized = scalarized);
      varData.previous        := VariablePointers.empty(scalarized = scalarized);
      bdae.varData := varData;

      eqData.equations        := EquationPointers.fromList(equations);
      eqData.simulation       := EquationPointers.fromList(equations);
      eqData.continuous       := EquationPointers.fromList(equations);
      eqData.discretes        := EquationPointers.empty();
      eqData.clocked          := EquationPointers.empty();
      eqData.initials         := EquationPointers.empty();
      eqData.auxiliaries      := EquationPointers.empty();
      // the removed equations would otherwise be added back to the system
      eqData.removed          := EquationPointers.empty();
      bdae.eqData := eqData;

      // The old backend creates the jacobian F here with SymbolicJacobian.getSymbolicJacobian, which
      // sorts the residual and SET-S equations itself. NBJacobian needs solved strong components,
      // which only exist after causalization, and chooses the result variables by the jacobian type.
      // F is therefore created from this data by createJacobian, which NBackendDAE.main runs as the
      // post-optimization module DataReconciliation.createJacobian.
      bdae.dataReconciliation := SOME(data);
    then bdae;
  end match;
end replaceModel;

protected function dumpToCsv
  "one variable name per line"
  input list<Pointer<Variable>> vars;
  output String str = stringAppendList(list(ComponentRef.toString(BVariable.getVarName(v)) + "\n" for v in vars));
end dumpToCsv;

protected function dumpCorrelationVarsToCsv
  "header line of the correlation matrix"
  input list<Pointer<Variable>> vars;
  output String str = "Sxij," + stringAppendList(list(ComponentRef.toString(BVariable.getVarName(v)) + "," for v in vars));
end dumpCorrelationVarsToCsv;

protected function dumpReconciledModel
  "the reconciled system in Modelica format, same as in the old backend"
  input ReconciliationData data;
  input String fileNamePrefix;
  output String str;
protected
  String modelName = "Reconciled_" + System.stringReplace(fileNamePrefix, ".", "_");
algorithm
  str := "/* This is a Reconciled Model which is generated by the Data Reconciliation extraction algorithm */\n";
  str := str + "model " + modelName;
  str := str + dumpExtractedVars(data.inputVars, "Variables of Interest");
  str := str + dumpExtractedVars(data.parameters, "parameters in SET-S");
  str := str + dumpResidualVars(data.residualVars, "residualVars");
  str := str + dumpExtractedVars(data.setSVars, "remaining variables in setS");
  str := str + "\nequation";
  str := str + dumpExtractedEquations(data.residualEqns, "set-C Canonical form");
  str := str + dumpExtractedEquations(data.setSEqns, "remaining equations in Set-S");
  str := str + "\nend " + modelName + ";";
end dumpReconciledModel;

protected function modelicaName
  input Pointer<Variable> var_ptr;
  output String str = System.stringReplace(ComponentRef.toString(BVariable.getVarName(var_ptr)), ".", "_");
end modelicaName;

protected function dumpExtractedVars
  "variables of interest become parameters, record elements are declared as their record"
  input list<Pointer<Variable>> vars;
  input String comment;
  output String str = "\n  //" + comment;
protected
  Variable var, parent;
  list<String> records = {};
  String record_name;
algorithm
  for var_ptr in vars loop
    var := Pointer.access(var_ptr);
    if hasUncertainty(var_ptr, Uncertainty.REFINE) then
      str := str + "\n  parameter " + Type.toString(var.ty) + " " + modelicaName(var_ptr) + ";";
    elseif BVariable.isParamOrConst(var_ptr) then
      str := str + "\n  parameter " + Type.toString(var.ty) + " " + modelicaName(var_ptr)
        + (if Binding.hasExp(var.binding) then " = " + Expression.toString(Binding.getExp(var.binding)) else "") + ";";
    else
      str := match BVariable.getParent(var_ptr)
        local
          Pointer<Variable> parent_ptr;
        case SOME(parent_ptr) algorithm
          record_name := modelicaName(parent_ptr);
          if not listMember(record_name, records) then
            records := record_name :: records;
            parent := Pointer.access(parent_ptr);
            str := str + "\n  " + Type.toString(parent.ty) + " " + record_name + ";";
          end if;
        then str;
        else str + "\n  " + Type.toString(var.ty) + " " + modelicaName(var_ptr) + ";";
      end match;
    end if;
  end for;
end dumpExtractedVars;

protected function dumpResidualVars
  input list<Pointer<Variable>> vars;
  input String comment;
  output String str = "\n  //" + comment;
protected
  Variable var;
algorithm
  for var_ptr in vars loop
    var := Pointer.access(var_ptr);
    str := str + "\n  " + Type.toString(var.ty) + " " + System.stringReplace(modelicaName(var_ptr), "$", "") + ";";
  end for;
end dumpResidualVars;

protected function dumpExtractedEquations
  input list<Pointer<Equation>> eqns;
  input String comment;
  output String str = "\n  //" + comment;
algorithm
  for eqn in eqns loop
    // the residual variables are declared without $
    str := str + "\n  " + System.stringReplace(equationString(eqn), "$", "") + ";";
  end for;
end dumpExtractedEquations;

protected function dumpReconciliationData
  "same headings as the debug dump of the old backend"
  input ReconciliationData data;
algorithm
  dumpVariables(data.inputVars, "Jacobian_knownVariables");
  dumpVariables(data.residualVars, "Jacobian_outResidualVars");
  dumpVariables(data.setSVars, "Jacobian_outOtherVars");
  dumpEquationPointers(data.residualEqns, "Jacobian_ResidualEquation");
  dumpEquationPointers(data.setSEqns, "Jacobian_other_Equation");
end dumpReconciliationData;

protected function dumpEquationPointers
  "same format as BackendDump.dumpEquationArray in the old backend, nothing is printed for no equations"
  input list<Pointer<Equation>> eqns;
  input String heading;
protected
  Integer i = 1;
algorithm
  if listEmpty(eqns) then
    return;
  end if;
  print("\n" + heading + " (" + intString(listLength(eqns)) + ", " + intString(sum(Equation.size(eqn) for eqn in eqns))
    + ")\n========================================\n");
  for eqn in eqns loop
    print(intString(i) + "/" + intString(i) + " (" + intString(Equation.size(eqn)) + "): " + equationString(eqn) + "\n");
    i := i + 1;
  end for;
  print("\n");
end dumpEquationPointers;

protected function dumpExtractedEquationsToHTML
  "returns the html page of a list of equations, same as in the old backend"
  input list<Pointer<Equation>> eqns;
  input String heading;
  output String str;
protected
  String comment = heading + " (" + intString(listLength(eqns)) + ", " + intString(sum(Equation.size(eqn) for eqn in eqns)) + ")";
algorithm
  if listEmpty(eqns) then
    str := "The set of " + comment + " is empty.";
  else
    str := "<html>\n<body>\n<h2>" + comment + "</h2>\n<ol>";
    for eqn in eqns loop
      str := str + "\n  <li>(" + intString(Equation.size(eqn)) + "): " + equationString(eqn) + " </li>";
    end for;
    str := str + "\n</ol>\n</body>\n</html>";
  end if;
end dumpExtractedEquationsToHTML;

protected function dumpRelatedBoundaryConditionsEquations
  "writes the equations involving the boundary conditions that failed a procedure"
  input list<tuple<Integer, Pointer<Equation>, list<Integer>>> setBFailedBoundaryConditionEquations;
  input String fileNamePrefix;
protected
  Pointer<Equation> eqn;
  String str;
algorithm
  if listEmpty(setBFailedBoundaryConditionEquations) then
    str := "The set of Related boundary conditions are empty.";
  else
    str := "<html>\n<body>\n<h2> Related boundary conditions (" + intString(listLength(setBFailedBoundaryConditionEquations)) + ") </h2>\n<ol>";
    for item in setBFailedBoundaryConditionEquations loop
      (_, eqn, _) := item;
      str := str + "\n  <li>(" + intString(Equation.size(eqn)) + "): " + equationString(eqn) + " </li>";
    end for;
    str := str + "\n</ol>\n</body>\n</html>";
  end if;
  System.writeFile(fileNamePrefix + "_relatedBoundaryConditionsEquations.html", str);
end dumpRelatedBoundaryConditionsEquations;

protected function verifyDataReconciliation
  "checks the conditions SET-C and SET-S have to fulfill, a failed condition other
  than condition 2 writes an html report and fails"
  input ExtractionSystem sys;
  input list<Integer> setC "rows";
  input list<Integer> setS "rows";
  input list<Integer> setCEqns;
  input list<Integer> setSEqns;
  input list<Integer> knowns;
  input list<Integer> setSVars;
  input Integer unmeasuredVariables;
  input String fileNamePrefix;
protected
  list<Integer> commonEqns, knownsInSetC, unknownsInSetC, knownsInSetS, unknownsInSetS;
  list<Integer> knownsFound, knownsNotInSetC, knownsInSetSOnly, knownsNotFound, intermediateFound, intermediateNotFound;
  String auxiliaryConditions = intString(listLength(setCEqns)), varsToReconcile = intString(listLength(knowns)), msg;
  Integer setSSize;
algorithm
  print("\n\nAutomatic Verification Steps of DataReconciliation Algorithm\n" + UNDERLINE + "\n");
  dumpVarList(sys, knowns, "knownVariables:" + List.toString(knowns, intString));
  print("-SET_C:" + List.toString(setCEqns, intString) + "\n-SET_S:" + List.toString(setSEqns, intString) + "\n\n");

  // Condition-1
  print("Condition-1 \"SET_C and SET_S must not have no equations in common\"\n" + UNDERLINE + "\n");
  commonEqns := List.intersectionOnTrue(setCEqns, setSEqns, intEq);
  if listEmpty(commonEqns) then
    print("-Passed\n\n");
  else
    print("-Failed\n");
    dumpEquations(sys, commonEqns, {}, "Sets C and S have equations in common" + List.toString(commonEqns, intString));
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 1-Failed: SET_C and SET_S must not have no equations in common: The data reconciliation problem is ill-posed"});
    generateCompileTimeHtmlReport(sys, fileNamePrefix, "Internal Error: Condition 1-Failed: \"SET_C and SET_S must not have no equations in common\": The data reconciliation problem is ill-posed",
      auxiliaryConditions, varsToReconcile, unmeasuredVariables, condition1 = ("Sets C and S have equations in common", commonEqns));
    fail();
  end if;

  (knownsInSetC, unknownsInSetC) := getVariableOccurence(sys, setC, knowns);
  (knownsInSetS, unknownsInSetS) := getVariableOccurence(sys, setS, knowns);

  // Condition-2
  print("Condition-2 \"All variables of interest must be involved in SET_C or SET_S\"\n" + UNDERLINE + "\n");
  (knownsFound, _, knownsNotInSetC) := List.intersection1OnTrue(knownsInSetC, knowns, intEq);
  if listEmpty(knownsNotInSetC) then
    print("-Passed\n");
    dumpVarList(sys, knownsFound, "-SET_C has all known variables:" + List.toString(knownsFound, intString));
  else
    (knownsInSetSOnly, knownsNotFound, _) := List.intersection1OnTrue(knownsNotInSetC, knownsInSetS, intEq);
    if listEmpty(knownsNotFound) then
      print("-Passed\n");
    else
      print("-Failed\n");
      dumpVarList(sys, knownsNotFound, "knownVariables not Found:" + List.toString(knownsNotFound, intString));
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 2-Failed: All variables of interest must be involved in Set-C or Set-S: The data reconciliation problem is ill-posed"});
      System.writeFile(fileNamePrefix + "_NonReconcilcedVars.txt", stringAppendList(list(varName(sys, v) + "\n" for v in knownsNotFound)));
    end if;
    dumpVarList(sys, knownsFound, "-SET_C has known variables:" + List.toString(knownsFound, intString));
    dumpVarList(sys, knownsInSetSOnly, "-SET_S has known variables:" + List.toString(knownsInSetSOnly, intString));
  end if;

  // Condition-3
  print("Condition-3 \"SET_C equations must be strictly less than Variable of Interest\"\n" + UNDERLINE + "\n");
  if listLength(setC) < listLength(knowns) and not listEmpty(setC) then
    print("-Passed\n-SET_C contains:" + intString(listLength(setC)) + " equations < " + intString(listLength(knowns)) + " known variables\n\n");
  else
    msg := "Set-C has " + intString(listLength(setC)) + " equations and " + intString(listLength(knowns)) + " variables to be reconciled";
    print("-Failed\n-" + msg + "\n\n");
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 3-Failed: The number of auxiliary conditions must be strictly less than the number of variables to be reconciled. The data reconciliation problem is ill-posed"});
    if listEmpty(setC) then
      generateCompileTimeHtmlReport(sys, fileNamePrefix, "", auxiliaryConditions, varsToReconcile, unmeasuredVariables,
        condition3 = "<b>User Error:</b> Condition 7 failed: \"The set of auxiliary conditions is empty.\" The data reconciliation problem is ill-posed");
    else
      generateCompileTimeHtmlReport(sys, fileNamePrefix, "<b>User Error:</b> Condition 3-Failed: \"The number of auxiliary conditions must be strictly less than the number of variables to be reconciled.\": The data reconciliation problem is ill-posed",
        auxiliaryConditions, varsToReconcile, unmeasuredVariables, condition3 = msg);
    end if;
    fail();
  end if;

  // Condition-4
  print("Condition-4 \"SET_S should contain all intermediate variables involved in SET_C\"\n" + UNDERLINE + "\n");
  if listEmpty(unknownsInSetC) then
    print("-Passed\n-SET_C contains No Intermediate Variables\n\n");
    return;
  end if;
  dumpVarList(sys, unknownsInSetC, "-SET_C has intermediate variables:" + List.toString(unknownsInSetC, intString));
  (intermediateFound, intermediateNotFound, _) := List.intersection1OnTrue(unknownsInSetC, unknownsInSetS, intEq);
  if listEmpty(intermediateNotFound) then
    dumpVarList(sys, intermediateFound, "-SET_S has intermediate variables involved in SET_C:" + List.toString(intermediateFound, intString));
    print("-Passed\n\n");
  else
    dumpVarList(sys, intermediateNotFound, "-SET_S does not have intermediate variables involved in SET_C:" + List.toString(intermediateNotFound, intString));
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 4-Failed: SET_S should contain all intermediate variables involved in SET_C: The data reconciliation problem is ill-posed"});
    generateCompileTimeHtmlReport(sys, fileNamePrefix, "<b>Internal Error:</b> Condition 4-Failed: \"SET_S should contain all intermediate variables involved in SET_C\": The data reconciliation problem is ill-posed",
      auxiliaryConditions, varsToReconcile, unmeasuredVariables, condition4 = ("Set-S does not have intermediate variables involved in Set-C", intermediateNotFound));
    fail();
  end if;

  // Condition-5
  print("Condition-5 \"SET_S should be square\"\n" + UNDERLINE + "\n");
  if listEmpty(setSEqns) then
    print("-Passed\n-SET_S contains 0 intermediate variables and 0 equations\n\n");
    return;
  end if;
  setSSize := sum(Equation.size(sys.eqnArr[eqn]) for eqn in setSEqns);
  if setSSize == listLength(setSVars) then
    print("-Passed\n Set_S has " + intString(listLength(setS)) + " equations and " + intString(listLength(setSVars)) + " variables\n\n");
  else
    msg := "Set-S has " + intString(setSSize) + " equations and " + intString(listLength(setSVars)) + " variables";
    print("-Failed\n " + msg + "\n\n");
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 5-Failed: Set_S should be square: The data reconciliation problem is ill-posed"});
    generateCompileTimeHtmlReport(sys, fileNamePrefix, "<b>Internal Error:</b> Condition 5-Failed: \"Set_S should be square\": The data reconciliation problem is ill-posed",
      auxiliaryConditions, varsToReconcile, unmeasuredVariables, condition5 = msg);
    fail();
  end if;
end verifyDataReconciliation;

protected function getVariableOccurence
  "returns the variables of interest and the other variables occurring in the given equations"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  input list<Integer> knowns;
  output list<Integer> knownVariables = {};
  output list<Integer> unknownVariables = {};
algorithm
  for eqn in eqns loop
    for var in sys.adjacency[eqn] loop
      if listMember(var, knowns) then
        knownVariables := var :: knownVariables;
      else
        unknownVariables := var :: unknownVariables;
      end if;
    end for;
  end for;
  knownVariables := List.unique(knownVariables);
  unknownVariables := List.unique(unknownVariables);
end getVariableOccurence;

protected function generateCompileTimeHtmlReport
  "writes <fileNamePrefix>.html for errors found during the verification of the extraction algorithm"
  input ExtractionSystem sys;
  input String fileNamePrefix;
  input String conditions;
  input String auxiliaryConditions;
  input String varsToReconcile;
  input Integer unmeasuredVariables;
  input tuple<String, list<Integer>> condition1 = ("", {}) "message, equations";
  input String condition3 = "";
  input tuple<String, list<Integer>> condition4 = ("", {}) "message, variables";
  input String condition5 = "";
protected
  String data, msg;
  list<Integer> lst;
algorithm
  data := "<html> \n <head> <h1> Data Reconciliation Report</h1></head> \n <body> \n <h2> Overview: </h2> \n";
  data := data + "<table> \n <tr> \n <th align=right> Model file: </th> \n";
  data := data + "<td>" + fileNamePrefix + ".mo" + "</td>\n</tr>\n";
  data := data + " <tr> \n <th align=right> Model name: </th>\n";
  data := data + "<td>" + fileNamePrefix + "</td>\n</tr>\n";
  data := data + "<tr> \n <th align=right> Generated: </th>\n";
  data := data + "<td>" + System.getCurrentTimeStr() + "<b> by OpenModelica " + Settings.getVersionNr() + "</b>" + "</td>\n</tr>\n <table>\n";
  data := data + "<h2> Analysis: </h2>\n<table>";
  data := data + "<tr>\n <th align=right> Number of auxiliary conditions: </th> \n <td>" + auxiliaryConditions + "</td>\n</tr>\n";
  data := data + "<tr>\n <th align=right> Number of measured variables: </th> \n <td>" + varsToReconcile + "</td>\n</tr>\n";
  data := data + "<tr>\n <th align=right> Number of unmeasured variables: </th> \n <td>" + intString(unmeasuredVariables) + "</td>\n</tr>\n";
  data := data + "<tr>\n <th align=right> Number of related boundary conditions: </th> \n <td>0</td>\n</tr>\n</table>";
  data := data + "<h3> <a href=" + fileNamePrefix + "_IntermediateEquations.html target=_blank> Intermediate equations for measured variables </a> </h3>";
  data := data + "<h3> Errors: </h3> " + "\n <p>" + conditions + "</p>" + "\n";

  (msg, lst) := condition1;
  if not listEmpty(lst) then
    data := data + "<p>" + msg + "\n <ol>";
    for eqn in lst loop
      data := data + "\n" + "  <li>" + equationString(sys.eqnArr[eqn]) + " </li>";
    end for;
    data := data + "\n</ol> \n</p>";
  end if;

  if not stringEmpty(condition3) then
    data := data + "<p>" + condition3 + "</p>";
  end if;

  (msg, lst) := condition4;
  if not listEmpty(lst) then
    data := data + "<p>" + msg + "\n <ol>";
    for var in lst loop
      data := data + "\n <li>" + varName(sys, var) + "</li>";
    end for;
    data := data + "\n</ol>";
  end if;

  if not stringEmpty(condition5) then
    data := data + "<p>" + condition5 + "</p>";
  end if;

  data := data + "\n</html>";
  System.writeFile(fileNamePrefix + ".html", data);
end generateCompileTimeHtmlReport;

protected function crefNameGreater
  input ComponentRef cr1;
  input ComponentRef cr2;
  output Boolean b = stringCompare(ComponentRef.toString(cr1), ComponentRef.toString(cr2)) > 0;
end crefNameGreater;

protected function swapComplexEquationsInSetC
  "work around for condition-1 failed, because complex equations are detected
  in Set-C and it should be swapped with any simple equation in Set-S with procedure = success"
  input ExtractionSystem sys;
  input output list<Integer> setC;
  input output list<Integer> setS;
  input list<tuple<Integer, list<Integer>>> mappedEbltSetS "(set-C eqn, set-S eqns)";
  input list<Integer> bindingEquations;
protected
  Integer eqn;
  list<Integer> matchedEqns, complexEquations = {}, swappedEquations = {};
algorithm
  for item in mappedEbltSetS loop
    (eqn, matchedEqns) := item;
    if isComplexEquation(sys.eqnArr[sys.rowToEqn[eqn]]) then
      complexEquations := eqn :: complexEquations;
      for i in matchedEqns loop
        if not isComplexEquation(sys.eqnArr[sys.rowToEqn[i]]) then
          setC := i :: List.removeOnTrue(eqn, intEq, setC);
          setS := eqn :: List.removeOnTrue(i, intEq, setS);
          swappedEquations := i :: swappedEquations;
          break;
        end if;
      end for;
    end if;
  end for;

  if not listEmpty(complexEquations) then
    dumpEquationArray(sys, eqnsOf(sys, listReverse(complexEquations)), bindingEquations, "Warning complex equation detected in Set-C");
    dumpEquationArray(sys, eqnsOf(sys, listReverse(swappedEquations)), bindingEquations, "Swapping Equations from Set-S");
  end if;
end swapComplexEquationsInSetC;

protected function isComplexEquation
  "record and tuple equations, COMPLEX_EQUATION in the old backend"
  input Pointer<Equation> eqn;
  output Boolean b;
algorithm
  b := match Pointer.access(eqn)
    case Equation.RECORD_EQUATION() then true;
    else false;
  end match;
end isComplexEquation;

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

    mappedEq := sys.var_to_row[var];
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
  input Option<ComponentRef> scalarName = NONE() "the scalar element of an array variable";
  output String str;
protected
  Variable var = Pointer.access(var_ptr);
  String kind, attr, binding = "";
  ComponentRef name = Util.getOptionOrDefault(scalarName, var.name);
  Type ty = if isSome(scalarName) then Type.arrayElementType(var.ty) else var.ty;
algorithm
  kind := match var.backendinfo.varKind
    case BackendExtension.VariableKind.ALGEBRAIC() then "VARIABLE";
    case BackendExtension.VariableKind.STATE()     then "STATE";
    case BackendExtension.VariableKind.DISCRETE()  then "DISCRETE";
    case BackendExtension.VariableKind.PARAMETER() algorithm
      if Binding.hasExp(var.binding) then
        binding := " = " + Expression.toString(Binding.getExp(var.binding)) + " ";
      end if;
    then "PARAM";
    else BackendExtension.VariableKind.toString(var.backendinfo.varKind);
  end match;
  attr := stringDelimitList(list(s for s guard(not stringEmpty(s)) in {
    BackendExtension.VariableAttributes.toString(var.backendinfo.attributes),
    uncertaintyString(BackendExtension.VariableAttributes.getUncertainty(var.backendinfo.attributes))}), " ");
  str := ComponentRef.toString(name) + ":" + kind + "(" + attr + ") " + binding + " type: " + Type.toString(ty);
end varString;

protected function colString
  input ExtractionSystem sys;
  input Integer col;
  output String str = varString(varOf(sys, col), SOME(sys.colNames[col]));
end colString;

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
  print("\nOrderedVariables (" + intString(arrayLength(sys.colToVar)) + ")\n========================================\n");
  for i in 1:arrayLength(sys.colToVar) loop
    print(intString(i) + ": " + colString(sys, i) + "\n");
  end for;
  print("\n");
end dumpOrderedVariables;

protected function dumpEquationArray
  "same format as BackendDump.dumpEquationArray in the old backend, nothing is printed for no equations"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  input list<Integer> bindingRows;
  input String heading;
algorithm
  if listEmpty(eqns) then
    return;
  end if;
  print("\n" + heading + " (" + intString(listLength(eqns)) + ", " + intString(sum(Equation.size(sys.eqnArr[eqn]) for eqn in eqns))
    + ")\n========================================\n");
  printEquations(sys, eqns, bindingRows);
  print("\n");
end dumpEquationArray;

protected function printEquations
  "<i>/<scalar index> (<size>): <equation>   [binding|dynamic], like BackendDump"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  input list<Integer> bindingRows;
protected
  Integer i = 1, j = 1;
algorithm
  for eqn in eqns loop
    print(intString(i) + "/" + intString(j) + " (" + intString(Equation.size(sys.eqnArr[eqn])) + "): " + equationString(sys.eqnArr[eqn])
      + (if isBindingEquation(sys, eqn, bindingRows) then "   [binding]" else "   [dynamic]") + "\n");
    i := i + 1;
    j := j + Equation.size(sys.eqnArr[eqn]);
  end for;
end printEquations;

protected function isBindingEquation
  input ExtractionSystem sys;
  input Integer eqn;
  input list<Integer> bindingRows;
  output Boolean b = false;
algorithm
  for row in sys.eqnToRows[eqn] loop
    if listMember(row, bindingRows) then
      b := true;
      return;
    end if;
  end for;
end isBindingEquation;

protected function dumpSetSVars
  "same format as dumpSetSVars in the old backend"
  input ExtractionSystem sys;
  input list<Integer> vars;
  input String heading;
protected
  Integer i = 1;
  Variable var;
algorithm
  print("\n" + heading + " (" + intString(listLength(vars)) + ")\n========================================\n");
  for v in vars loop
    var := Pointer.access(varOf(sys, v));
    print("\n" + intString(i) + ": " + ComponentRef.toString(sys.colNames[v]) + " type: " + Type.toString(Type.arrayElementType(var.ty)));
    i := i + 1;
  end for;
  print("\n\n");
end dumpSetSVars;

protected function dumpVariables
  "same format as BackendDump.dumpVariables in the old backend, nothing is printed for no variables"
  input list<Pointer<Variable>> vars;
  input String heading;
protected
  Integer i = 1;
algorithm
  if listEmpty(vars) then
    return;
  end if;
  print("\n" + heading + " (" + intString(listLength(vars)) + ")\n========================================\n");
  for var in vars loop
    print(intString(i) + ": " + varString(var) + "\n");
    i := i + 1;
  end for;
  print("\n");
end dumpVariables;

protected function dumpEquations
  "same format as BackendDump.dumpEquationList in the old backend, nothing is printed for no equations"
  input ExtractionSystem sys;
  input list<Integer> eqns;
  input list<Integer> bindingRows;
  input String heading;
algorithm
  if not listEmpty(eqns) then
    print("\n" + heading + " (" + intString(listLength(eqns)) + ")\n========================================\n");
    printEquations(sys, eqns, bindingRows);
    print("\n");
  end if;
end dumpEquations;

protected function dumpMatching
  input ExtractionSystem sys;
algorithm
  print("Matching\n========================================\n" + intString(arrayLength(sys.var_to_row)) + " variables and equations\n");
  for i in 1:arrayLength(sys.var_to_row) loop
    print("var " + intString(i) + " is solved in eqn " + intString(sys.var_to_row[i]) + "\n");
  end for;
end dumpMatching;

protected function varName
  input ExtractionSystem sys;
  input Integer var;
  output String str = if var > 0 then ComponentRef.toString(sys.colNames[var]) else "-";
end varName;

protected function dumpSetSTargetEquation
  "same format as dumpSetSTargetEquations in the old backend:
  <prefix><solved var index>: <solved var>: (<eqn>/<row>): (<size>): <equation>"
  input ExtractionSystem sys;
  input Integer row;
  input String prefix;
protected
  Integer var = sys.row_to_var[row], eqn = sys.rowToEqn[row];
algorithm
  print("\n" + prefix + intString(var) + ": " + varName(sys, var) + ": (" + intString(eqn) + "/" + intString(row)
    + "): (" + intString(Equation.size(sys.eqnArr[eqn])) + "): " + equationString(sys.eqnArr[eqn]));
end dumpSetSTargetEquation;

protected function dumpEquationList
  "same format as dumpSetSVarsSolvedInfo in the old backend"
  input ExtractionSystem sys;
  input list<Integer> rows;
  input String heading;
algorithm
  print("\n" + heading + ":(" + intString(listLength(rows)) + ")\n============================================================\n");
  for row in rows loop
    dumpSetSTargetEquation(sys, row, "");
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
    print(intString(i) + ": " + colString(sys, var) + "\n");
    i := i + 1;
  end for;
  print("\n");
end dumpVarList;

annotation(__OpenModelica_Interface="nbackend");
end NBDataReconciliation;
