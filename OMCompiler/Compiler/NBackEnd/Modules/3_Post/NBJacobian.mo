/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBJacobian
"file:        NBJacobian.mo
 package:     NBJacobian
 description: This file contains the functions to create and manipulate jacobians.
              The main type is inherited from NBackendDAE.mo
              NOTE: There is no real jacobian type, it is a BackendDAE.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;

protected
  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import Adjacency = NBAdjacency;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.{DifferentiationArguments, DifferentiationType};
  import NBEquation.{Equation, EquationPointers, EqData};
  import Jacobian = NBackendDAE.BackendDAE;
  import Matching = NBMatching;
  import Replacements = NBReplacements;
  import Sorting = NBSorting;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import NFOperator.{MathClassification, SizeClassification};
  import NBVariable.{VariablePointers, VarData};

  // Util imports
  import AvlSetPath;
  import StringUtil;
  import UnorderedMap;
  import Util;

public
  function main
    "Wrapper function for any jacobian function. This will be called during
     simulation and gets the corresponding subfunction from Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    constant Module.jacobianInterface func = getModule();
  algorithm
    bdae := match bdae
      local
        String name                                     "Context name for jacobian";
        VariablePointers knowns                         "Variable array of knowns";
        Option<Jacobian> jacobian                       "Resulting jacobian";
        FunctionTree funcTree                           "Function call bodies";
        list<System.System> oldSystems, newSystems = {} "Equation systems before and afterwards";
        list<System.System> oldEvents, newEvents = {}   "Event Equation systems before and afterwards";

      case BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(knowns = knowns), funcTree = funcTree)
        algorithm
          (oldSystems, oldEvents, name) := match systemType
            case NBSystem.SystemType.ODE    then (bdae.ode, bdae.ode_event, "ODE_JAC");
            case NBSystem.SystemType.DAE    then (Util.getOption(bdae.dae), bdae.ode_event,"DAE_JAC");
            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + System.System.systemTypeString(systemType)});
            then fail();
          end match;

          for syst in listReverse(oldSystems) loop
            (jacobian, funcTree) := match syst
              case System.SYSTEM() then func(name, syst.unknowns, syst.daeUnknowns, syst.equations, knowns, syst.strongComponents, funcTree);
            end match;
            syst.jacobian := jacobian;
            newSystems := syst::newSystems;
          end for;

          for syst in listReverse(oldEvents) loop
            (jacobian, funcTree) := match syst
              case System.SYSTEM() then func(name, syst.unknowns, syst.daeUnknowns, syst.equations, knowns, syst.strongComponents, funcTree);
            end match;
            syst.jacobian := jacobian;
            newEvents := syst::newEvents;
          end for;

          _ := match systemType
            case NBSystem.SystemType.ODE algorithm
              bdae.ode := newSystems;
              bdae.ode_event := newEvents;
            then ();

            case NBSystem.SystemType.DAE algorithm
              bdae.dae := SOME(newSystems);
              bdae.ode_event := newEvents;
            then ();
          end match;
          bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + BackendDAE.toString(bdae)});
      then fail();

    end match;
  end main;

  function simple
    input VariablePointers variables;
    input EquationPointers equations;
    input StrongComponent comp;
    output Option<Jacobian> jacobian;
    input output FunctionTree funcTree;
    input String name;
  algorithm
    (jacobian, funcTree) := jacobianSymbolic(
        name              = name,
        unknowns          = variables,
        daeUnknowns       = NONE(),
        equations         = equations,
        knowns            = VariablePointers.empty(0), // remove them? are they necessary?
        strongComponents  = SOME(arrayCreate(1, comp)),
        funcTree          = funcTree
      );
  end simple;

  function combine
    input list<BackendDAE> jacobians;
    input String name;
    output BackendDAE jacobian;
  protected
    list<Pointer<Variable>> variables = {}, unknowns = {}, knowns = {}, auxiliaryVars = {}, aliasVars = {};
    list<Pointer<Variable>> diffVars = {}, dependencies = {}, resultVars = {}, tmpVars = {}, seedVars = {};
    list<Pointer<Equation>> equations = {}, results = {}, temporary = {}, auxiliaries= {}, removed = {};
    list<SparsityPatternCol> col_wise_pattern = {};
    list<SparsityPatternRow> row_wise_pattern = {};
    list<ComponentRef> independent_vars = {};
    list<ComponentRef> residual_vars = {};
    Integer nnz = 0;
    VarData varData;
    EqData eqData;
    SparsityPattern sparsityPattern;
    list<list<ComponentRef>> sparsityColoring = {};
  algorithm
    for jac in jacobians loop
      _ := match jac
        local
          VarData tmpVarData;
          EqData tmpEqData;
          SparsityPattern tmpPattern;
          Integer size1, size2;
          list<list<ComponentRef>> coloring1, coloring2;

        case BackendDAE.JACOBIAN(varData = tmpVarData as VarData.VAR_DATA_JAC(), eqData = tmpEqData as EqData.EQ_DATA_JAC(), sparsityPattern = tmpPattern) algorithm
          variables := listAppend(VariablePointers.toList(tmpVarData.variables), variables);
          unknowns := listAppend(VariablePointers.toList(tmpVarData.unknowns), unknowns);
          knowns := listAppend(VariablePointers.toList(tmpVarData.knowns), knowns);
          auxiliaryVars := listAppend(VariablePointers.toList(tmpVarData.auxiliaries), auxiliaryVars);
          aliasVars := listAppend(VariablePointers.toList(tmpVarData.aliasVars), aliasVars);
          diffVars := listAppend(VariablePointers.toList(tmpVarData.diffVars), diffVars);
          dependencies := listAppend(VariablePointers.toList(tmpVarData.dependencies), dependencies);
          resultVars := listAppend(VariablePointers.toList(tmpVarData.resultVars), resultVars);
          tmpVars := listAppend(VariablePointers.toList(tmpVarData.tmpVars), tmpVars);
          seedVars := listAppend(VariablePointers.toList(tmpVarData.seedVars), seedVars);

          equations := listAppend(EquationPointers.toList(tmpEqData.equations), equations);
          results := listAppend(EquationPointers.toList(tmpEqData.results), results);
          temporary := listAppend(EquationPointers.toList(tmpEqData.temporary), temporary);
          auxiliaries := listAppend(EquationPointers.toList(tmpEqData.auxiliaries), auxiliaries);
          removed := listAppend(EquationPointers.toList(tmpEqData.removed), removed);

          col_wise_pattern := listAppend(tmpPattern.col_wise_pattern, col_wise_pattern);
          row_wise_pattern := listAppend(tmpPattern.col_wise_pattern, row_wise_pattern);
          independent_vars := listAppend(tmpPattern.independent_vars, independent_vars);
          residual_vars := listAppend(tmpPattern.residual_vars, residual_vars);
          nnz := nnz + tmpPattern.nnz;

          // combine the sparsity colorings since all are independent
          size1 := listLength(sparsityColoring);
          size2 := listLength(jac.sparsityColoring);
          (coloring1, coloring2) := if size1 > size2
                                    then (sparsityColoring, jac.sparsityColoring)
                                    else (jac.sparsityColoring, sparsityColoring);

          // fill up the smaller coloring with empty groups
          for i in 1:intAbs(size1-size2) loop
            coloring2 := {} :: coloring2;
          end for;

          sparsityColoring := List.threadMap(coloring1, coloring2, listAppend);
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + BackendDAE.toString(jac)});
        then fail();
      end match;
    end for;

    varData := VarData.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(variables),
      unknowns      = VariablePointers.fromList(unknowns),
      knowns        = VariablePointers.fromList(knowns),
      auxiliaries   = VariablePointers.fromList(auxiliaryVars),
      aliasVars     = VariablePointers.fromList(aliasVars),
      diffVars      = VariablePointers.fromList(diffVars),
      dependencies  = VariablePointers.fromList(dependencies),
      resultVars    = VariablePointers.fromList(resultVars),
      tmpVars       = VariablePointers.fromList(tmpVars),
      seedVars      = VariablePointers.fromList(seedVars)
    );

    eqData := EqData.EQ_DATA_JAC(
      uniqueIndex   = Pointer.create(0),
      equations     = EquationPointers.fromList(equations),
      results       = EquationPointers.fromList(results),
      temporary     = EquationPointers.fromList(temporary),
      auxiliaries   = EquationPointers.fromList(auxiliaries),
      removed       = EquationPointers.fromList(removed)
    );

    sparsityPattern := SPARSITY_PATTERN(
      col_wise_pattern  = col_wise_pattern,
      row_wise_pattern  = row_wise_pattern,
      independent_vars  = independent_vars,
      residual_vars     = residual_vars,
      nnz               = nnz
    );

    jacobian := BackendDAE.JACOBIAN(
      name              = name,
      varData           = varData,
      eqData            = eqData,
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    );
  end combine;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.jacobianInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.JACOBIAN)
  algorithm
    (func) := match flag
      case "default"  then (jacobianSymbolic);
      case "symbolic" then (jacobianSymbolic);
      case "numeric"  then (jacobianNumeric);
      /* ... New jacobian modules have to be added here */
      else fail();
    end match;
  end getModule;

  function toString
    input BackendDAE jacobian;
    input output String str = "";
    input Boolean compact = false;
  algorithm
    if not compact then
      str := BackendDAE.toString(jacobian, str);
    else
      str := match jacobian
        case BackendDAE.JACOBIAN() then StringUtil.headline_3("Jacobian " + jacobian.name + ": " + str)
                                        + BEquation.EqData.toString(jacobian.eqData, 1);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end if;
  end toString;

  type SparsityPatternCol = tuple<ComponentRef, list<ComponentRef>> "residual, {independents}";
  type SparsityPatternRow = SparsityPatternCol                      "independent, {residuals}";

  uniontype SparsityPattern
    record SPARSITY_PATTERN
      list<SparsityPatternCol> col_wise_pattern   "colum-wise sparsity pattern";
      list<SparsityPatternRow> row_wise_pattern   "row-wise sparsity pattern";
      list<ComponentRef> independent_vars         "independent variables solved here";
      list<ComponentRef> residual_vars            "residual vars e.g. $RES_DAE_0";
      Integer nnz                                 "number of nonzero elements";
    end SPARSITY_PATTERN;

    function toString
      input SparsityPattern pattern;
      input SparsityColoring coloring;
      output String str = StringUtil.headline_3("Sparsity Pattern (nnz: " + intString(pattern.nnz) + ")");
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
    algorithm
      if not listEmpty(pattern.col_wise_pattern) then
        for col in pattern.col_wise_pattern loop
          (cref, dependencies) := col;
          str := str + "(" + ComponentRef.toString(cref) + ")\t" + ComponentRef.listToString(dependencies) + "\n";
        end for;
      else
        str := str + "<empty sparsity pattern>\n";
      end if;
      str := str + "\n" + StringUtil.headline_3("Sparsity Coloring Groups");
      if not listEmpty(coloring) then
        for group in coloring loop
          str := str + ComponentRef.listToString(group) + "\n";
        end for;
      else
        str := str + "<empty sparsity coloring>\n";
      end if;
    end toString;

    // necessary as wrapping value type for UnorderedMap
    type CrefLst = list<ComponentRef>;

    function create
      input VariablePointers independentVars;
      input VariablePointers residualVars;
      input EquationPointers equations;
      input Option<array<StrongComponent>> strongComponents "Strong Components";
      output SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring;
    algorithm
      sparsityPattern := match strongComponents
        local
          array<StrongComponent> comps;
          list<ComponentRef> independent_vars, residual_vars, tmp;
          UnorderedMap<ComponentRef, list<ComponentRef>> map;
          list<SparsityPatternCol> cols = {};
          list<SparsityPatternRow> rows = {};
          Integer nnz = 0;

        case SOME(comps) guard(arrayEmpty(comps)) algorithm
        then EMPTY_SPARSITY_PATTERN;

        case SOME(comps) algorithm
          // get all relevant crefs
          residual_vars := VariablePointers.getVarNames(residualVars);
          independent_vars := VariablePointers.getVarNames(independentVars);

          // create a sufficiant big unordered map
          map := UnorderedMap.new<CrefLst>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(independent_vars) + listLength(residual_vars)));

          // save all relevant crefs to know later on if a cref should be added
          for cref in independent_vars loop
            UnorderedMap.add(cref, {}, map);
          end for;
          for cref in residual_vars loop
            UnorderedMap.add(cref, {}, map);
          end for;

          // traverse all components and save cref dependencies (only column-wise)
          for i in 1:arrayLength(comps) loop
            StrongComponent.getDependentCrefs(comps[i], map);
          end for;

          // create row-wise sparsity pattern
          for cref in residual_vars loop
            tmp := List.uniqueOnTrue(UnorderedMap.getSafe(cref, map), ComponentRef.isEqual);
            rows := (cref, tmp) :: rows;
            for dep in tmp loop
              // also add inverse dependency (indep var) --> (res/tmp) :: rest
              UnorderedMap.add(dep, cref :: UnorderedMap.getSafe(dep, map), map);
            end for;
          end for;

          // create column-wise sparsity pattern
          for cref in independent_vars loop
            tmp := List.uniqueOnTrue(UnorderedMap.getSafe(cref, map), ComponentRef.isEqual);
            cols := (cref, tmp) :: cols;
          end for;

          // find number of nonzero elements
          for col in cols loop
            (_, tmp) := col;
            nnz := nnz + listLength(tmp);
          end for;
        then SPARSITY_PATTERN(cols, rows, independent_vars, residual_vars, nnz);

        case NONE() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing strong components."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();

      end match;

      // create coloring
      sparsityColoring := createEmptyColoring(sparsityPattern);
    end create;

    function createEmpty
      output SparsityPattern sparsityPattern = EMPTY_SPARSITY_PATTERN;
      output SparsityColoring sparsityColoring = createEmptyColoring(sparsityPattern);
    end createEmpty;

    function createEmptyColoring
      "creates an empty coloring that just groups each independent variable individually"
      input SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring = {};
    algorithm
      sparsityColoring := list({cref} for cref in sparsityPattern.independent_vars);
    end createEmptyColoring;

  end SparsityPattern;

  constant SparsityPattern EMPTY_SPARSITY_PATTERN = SPARSITY_PATTERN({}, {}, {}, {}, 0);

  type SparsityColoring = list<list<ComponentRef>>  "list of independent variable groups belonging to the same color";

  type LinearJacobianRow = UnorderedMap<Integer, Real>;
  type LinearJacobianRhs = array<Expression>;
  type LinearJacobianInd = array<Integer>;

  uniontype LinearJacobian
    record LINEAR_JACOBIAN
      array<LinearJacobianRow> rows   "all loop variables entries";
      LinearJacobianRhs rhs           "the expression containing all non loop variable entries";
      LinearJacobianInd ind           "equation indices  <array, scalar>";
      array<Boolean> eq_marks         "changed equations";
    end LINEAR_JACOBIAN;

    public function toString
      input LinearJacobian linJac;
      input String heading = "";
      output String str;
    algorithm
      str := "######################################################\n" +
          " LinearJacobian sparsity pattern: " + heading + "\n" +
          "######################################################\n" +
          "(scal_idx|arr_idx|changed) [var_index, value] || RHS_EXPRESSION\n";
      for idx in 1:arrayLength(linJac.rows) loop
        str := str + rowToString(linJac.rows[idx], linJac.rhs[idx], linJac.ind[idx], linJac.eq_marks[idx]);
      end for;
      str := str + "\n";
    end toString;

    function rowToString
      input LinearJacobianRow row;
      input Expression rhs;
      input Integer eqn_index;
      input Boolean changed;
      output String str;
    protected
      Integer var_index;
      Real value;
      list<tuple<Integer, Real>> row_lst = UnorderedMap.toList(row);
    algorithm
      str := "(" + intString(eqn_index) + "|" + boolString(changed) +"):    ";
      if listEmpty(row_lst) then
        str := str + "EMPTY ROW     ";
      else
        for element in row_lst loop
          (var_index, value) := element;
          str := str + "[" + intString(var_index) + "|" + realString(value) + "] ";
        end for;
      end if;
      str := str + "    || RHS: " + Expression.toString(SimplifyExp.simplify(rhs)) + "\n";
    end rowToString;

    function ASSC
      input output Adjacency.Matrix adj;
      input output Matching matching;
      input VariablePointers vars;
      input EquationPointers eqns;
    protected
      list<StrongComponent> comps;
      list<tuple<Pointer<Variable>, Integer>> loopVars;
      list<tuple<Pointer<Equation>, Integer>> loopEqns;
      LinearJacobian linJac;
    algorithm
      comps := Sorting.tarjan(adj, matching, vars, eqns);
      for comp in comps loop
        _ := match comp
          case StrongComponent.ALGEBRAIC_LOOP() algorithm
            loopVars := list((var, VariablePointers.getVarIndex(vars, BVariable.getVarName(var))) for var in comp.vars);
            loopEqns := list((eqn, EquationPointers.getEqnIndex(eqns, Equation.getEqnName(eqn))) for eqn in comp.eqns);
            linJac := generate(loopVars, loopEqns);
            if not emptyOrSingle(linJac) then
              linJac := solve(linJac);
              (adj, matching) := resolveASSC(linJac, adj, matching, vars, eqns);
            end if;
          then ();
          else ();
        end match;
      end for;
    end ASSC;

    function generate
      "author: kabdelhak FHB 03-2021
       Generates a jacobian from algebraic loop equations which are linear
       w.r.t. all loopVars. Fails if these criteria are not met."
      input list<tuple<Pointer<Variable>, Integer>> loopVars;
      input list<tuple<Pointer<Equation>, Integer>> loopEqns;
      output LinearJacobian linJac;
    protected
      Integer eqn_index = 1, var_index;
      Real constReal;
      LinearJacobianRow row;
      list<LinearJacobianRow> tmp_mat = {};
      list<Expression> tmp_rhs = {};
      list<Integer> tmp_idx = {};
      Pointer<Variable> var;
      Pointer<Equation> eqn;
      Integer index;
      Expression res, pDer, constZero = Expression.INTEGER(0);
      UnorderedMap<ComponentRef, Expression> varRep = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
      DifferentiationArguments diffArgs = DifferentiationArguments.default(DifferentiationType.SIMPLE);
    algorithm
      /* Add a replacement rule var->0 for each loopVar, so that the RHS can be determined afterwards */
      for loopVar in loopVars loop
        (var, _) := loopVar;
        UnorderedMap.add(BVariable.getVarName(var), constZero, varRep);
      end for;

      /* Loop over all equations and create residual expression. */
      for loopEq in loopEqns loop
        row := UnorderedMap.new<Real>(intMod, intEq);
        (eqn, index) := loopEq;
        res := Equation.getResidualExp(Pointer.access(eqn));
        /* Loop over all variables and differentiate residual expression for each. */
        try
          for loopVar in loopVars loop
            (var, var_index) := loopVar;
            diffArgs.diffCref := BVariable.getVarName(var);
            (pDer, _) := Differentiate.differentiateExpression(res, diffArgs);
            pDer := SimplifyExp.simplify(pDer);
            constReal := Expression.realValue(pDer);
            if not realEq(constReal, 0.0) then
              UnorderedMap.add(var_index, constReal, row);
            end if;
          end for;
          /*
            Save the full row.
              - row entries
              - rhs
              - equation index
            Perform var replacements, multiply by -1 and simplify for rhs.
            NOTE: Multiplication with -1 is not really necessary for the
                  conversion of analytical to structural singularity, but
                  would be necessary if used for anything else.
          */
          res := Replacements.applySimpleExp(res, varRep);
          tmp_mat := row :: tmp_mat;
          tmp_rhs := SimplifyExp.simplify(Expression.MULTARY(
              arguments     = {Expression.REAL(-1.0), res},
              inv_arguments = {},
              operator      = Operator.fromClassification((MathClassification.MULTIPLICATION, SizeClassification.SCALAR), Type.REAL()))
            ) :: tmp_rhs;
          tmp_idx := index :: tmp_idx;

          /* set var as matched so that it can be chosen as pivot element for gaussian elimination */
          eqn_index := eqn_index + 1;
        else
          /*
            Differentiation not possible or not convertible to a real.
            Purposely fails.
          */
        end try;
      end for;
      /* convert and store all data */
      linJac := LINEAR_JACOBIAN(
        rows      = listArray(tmp_mat),
        rhs       = listArray(tmp_rhs),
        ind       = listArray(tmp_idx),
        eq_marks  = arrayCreate(listLength(tmp_mat), false)
      );
    end generate;

    public function emptyOrSingle
      "author: kabdelhak FHB 03-2021
       Returns true if the linear real jacobian is empty or has only one single row."
      input LinearJacobian linJac;
      output Boolean empty = (arrayLength(linJac.rows) < 2)
                         and (arrayLength(linJac.rhs) < 2)
                         and (arrayLength(linJac.ind) < 2)
                         and (arrayLength(linJac.eq_marks) < 2);
    end emptyOrSingle;

    public function solve
      "author: kabdelhak FHB 03-2021
       Performs a gaussian elimination algorithm on the jacobian without reducing the
       pivot elements to one to maintain the integer structure. This guarantees that
       no numerical errors can occur and analytical singularities will be detected.
       Also keeps track of the RHS for later equation replacement.

      Performs gaussian elimination for one pivot row and all following rows to reduce.
      new_row = old_row * pivot_element - pivot_row * row_element
      Example:
        pivot idx: 2, because the first is zero
        pivot row:     |  0 -1 -4 |
        row-to change: | -3  2  3 |
        new_row:       |  3  0  5 |"
      input output LinearJacobian linJac;
    protected
      Integer col_index;
      Real piv_value, row_value;
    algorithm
      /*
        Gaussian Algorithm without rearranging rows.
      */
      for i in 1:arrayLength(linJac.rows) loop
        try
          /*
            no pivot element can be chosen?
            jump over all manipulations, nothing to do
          */
          (col_index, piv_value) := getPivot(linJac.rows[i]);
          linJac.rhs[i] := updatePivotRow(linJac.rows[i], linJac.rhs[i], piv_value);
          for j in i+1:arrayLength(linJac.rows) loop
            row_value := getElementValue(linJac.rows[j], col_index);
            if not realEq(row_value, 0.0) then
              // set row to processed and perform pivot step
              linJac.eq_marks[j] := true;
              solveRow(linJac.rows[i], linJac.rows[j], 1.0, row_value);
              // pivot row is already normalized to pivot element = 1
              // rhs <- rhs - piv_rhs * row_val
              linJac.rhs[j] := Expression.MULTARY(
                arguments     = {linJac.rhs[j]},
                inv_arguments = {Expression.MULTARY(
                                  arguments     = {linJac.rhs[i]},
                                  inv_arguments = {Expression.REAL(row_value)},
                                  operator      = Operator.makeMul(Expression.typeOf(linJac.rhs[i]))
                                )},
                operator      = Operator.makeAdd(Expression.typeOf(linJac.rhs[j]))
              );
            end if;
          end for;
        else
          /* no pivot element, nothing to do */
        end try;
      end for;
    end solve;

    public function solveRow
    "author: kabdelhak FHB 03-2021
     performs one single row update : new_row = old_row * pivot_element - pivot_row * row_element"
      input LinearJacobianRow pivot_row;
      input LinearJacobianRow row;
      input Real piv_value;
      input Real row_value;
    protected
      Integer idx;
      Real val, diag_val;
    algorithm
      for idx in UnorderedMap.keyList(pivot_row) loop
        _ := match (UnorderedMap.get(idx, row), UnorderedMap.get(idx, pivot_row))

          // row to be updated has and element at this position
          case (SOME(val), SOME(diag_val)) algorithm
            val := val * piv_value - diag_val * row_value;
            if realAbs(val) < 1e-12 then
              /* delete element if zero */
              UnorderedMap.remove(idx, row);
            else
              UnorderedMap.add(idx, val, row);
            end if;
          then ();

          // row to be updated does not have an element at this position
          case (NONE(), SOME(diag_val)) algorithm
            UnorderedMap.add(idx, -diag_val * row_value, row);
          then ();

          else algorithm
            Error.assertion(false, getInstanceName() + " key does not have an element in pivot row.", sourceInfo());
          then ();
         end match;
      end for;
    end solveRow;

    public function updatePivotRow
    "author: kabdelhak FHB 03-2021
     updates the pivot row by deviding everything by its pivot value"
      input LinearJacobianRow pivot_row;
      input output Expression rhs;
      input Real piv_value;
    protected
      Real value;
    algorithm
      if not realEq(piv_value, 1.0) then
        for idx in UnorderedMap.keyList(pivot_row) loop
          SOME(value) := UnorderedMap.get(idx, pivot_row);
          UnorderedMap.add(idx, value/piv_value, pivot_row);
        end for;
      end if;
      // also update rhs expression
      rhs := Expression.MULTARY(
        arguments     = {rhs},
        inv_arguments = {Expression.REAL(piv_value)},
        operator      = Operator.makeMul(Expression.typeOf(rhs))
      );
    end updatePivotRow;

    protected function getPivot
    "author: kabdelhak FHB 03-2021
     Returns the first element that can be chosen as pivot, fails if none can be chosen."
      input LinearJacobianRow pivot_row;
      output tuple<Integer, Real> pivot_elem;
    protected
      Integer idx;
    algorithm
      if Vector.isEmpty(pivot_row.keys) then
        /* singular row */
        fail();
      else
        idx := UnorderedMap.firstKey(pivot_row);
        pivot_elem := (idx, Util.getOption(UnorderedMap.get(idx, pivot_row)));
      end if;
    end getPivot;

    protected function getElementValue
    "author: kabdelhak FHB 03-2021
     Returns the value at given column and zero if it does not exist in sparse structure."
      input LinearJacobianRow row;
      input Integer col_index;
      output Real value;
    algorithm
      value := match UnorderedMap.get(col_index, row)
        case SOME(value) then value;
        else 0.0;
      end match;
    end getElementValue;

    public function resolveASSC
    "author: kabdelhak FHB 03-2021
     Resolves analytical singularities by replacing the equations with
     zero rows in the jacobian with new equations. Needs preceeding
     solving of the linear real jacobian."
      input LinearJacobian linJac;
      input output Adjacency.Matrix adj;
      input output Matching matching;
      input VariablePointers vars;
      input EquationPointers eqns;
    protected
      Expression lhs;
      Pointer<Equation> eqn;
      list<Integer> updates = {};
    algorithm
      _ := match matching
        case Matching.SCALAR_MATCHING() algorithm
          for r in 1:arrayLength(linJac.rows) loop
            /*
              check if row has been changed
              for now also only resolve singularities and not replace full loop
              otherwise it sometimes leads to mixed determined systems
            */
            if linJac.eq_marks[r] and (UnorderedMap.isEmpty(linJac.rows[r]) or Flags.getConfigBool(Flags.FULL_ASSC)) then
              /* remove assignments */
              matching.eqn_to_var[matching.var_to_eqn[linJac.ind[r]]] := -1;
              matching.var_to_eqn[linJac.ind[r]] := -1;

              /* replace equation */
              lhs := generateLHSfromList(
                row_indices     = UnorderedMap.keyArray(linJac.rows[r]),
                row_values      = UnorderedMap.valueArray(linJac.rows[r]),
                vars            = vars
              );

              eqn := EquationPointers.getEqnAt(eqns, linJac.ind[r]);
              /* dump replacements */
              if Flags.isSet(Flags.DUMP_ASSC) or (Flags.isSet(Flags.BLT_DUMP) and UnorderedMap.isEmpty(linJac.rows[r])) then
                print("[ASSC] The equation: " + Equation.toString(Pointer.access(eqn)) + "\n");
              end if;

              Equation.updateLHSandRHS(eqn, lhs, SimplifyExp.simplify(linJac.rhs[r]));

              if Flags.isSet(Flags.DUMP_ASSC) or (Flags.isSet(Flags.BLT_DUMP) and UnorderedMap.isEmpty(linJac.rows[r])) then
                print("[ASSC] Gets replaced by equation: " + Equation.toString(Pointer.access(eqn)) + "\n");
              end if;

              updates := linJac.ind[r] :: updates;
            end if;
          end for;
          /*
            update adjacency matrix and transposed adjacency matrix
            isInitial should always be false
          */
          if not listEmpty(updates) then
            (adj, _) := Adjacency.Matrix.update(adj, vars, eqns, updates, NONE());
          end if;

          if not listEmpty(updates) and not Flags.isSet(Flags.DUMP_ASSC) and Flags.isSet(Flags.BLT_DUMP) then
            print("--- Some equations have been changed, for more information please use -d=dumpASSC.---\n\n");
          end if;
        then ();
        else algorithm
          Error.assertion(false, getInstanceName() + "ASSC not yet supported for SBGraphs.", sourceInfo());
        then fail();
      end match;
    end resolveASSC;

    protected function generateLHSfromList
    "author: kabdelhak FHB 03-2021
     Generates the LHS expression from a flattened linear real jacobian row.
     Only used for full replacement of causalized loop."
      input array<Integer> row_indices;
      input array<Real> row_values;
      input VariablePointers vars;
      output Expression lhs;
    protected
      Integer length = arrayLength(row_indices);
      list<Expression> arguments = {};
      list<Expression> inv_arguments = {};
      Expression var_tmp, arg_tmp;
      Real value;
    algorithm
      if length == 0 then
        lhs := Expression.REAL(0.0);
      else
        for i in 1:length loop
          var_tmp := BVariable.toExpression(VariablePointers.getVarAt(vars, i));
          arg_tmp := Expression.MULTARY(
                        arguments     = {Expression.REAL(realAbs(row_values[i])), var_tmp},
                        inv_arguments = {},
                        operator      = Operator.makeMul(Expression.typeOf(var_tmp))
                     );
          // add element to inverse elements if value was negative (now absolute value)
          if row_values[i] > 0 then
            arguments := arg_tmp :: arguments;
          else
            inv_arguments := arg_tmp :: inv_arguments;
          end if;
        end for;
        lhs := Expression.MULTARY(
          arguments     = arguments,
          inv_arguments = inv_arguments,
          operator      = Operator.makeAdd(Expression.typeOf(var_tmp))
        );
      end if;
    end generateLHSfromList;

    public function anyChanges
    "author: kabdelhak FHB 03-2021
     Returns true if any row of the jacobian got changed during gaussian elimination."
      input LinearJacobian linJac;
      output Boolean changed = false;
    algorithm
      for i in 1:arrayLength(linJac.eq_marks) loop
        if linJac.eq_marks[i] then
          changed := true;
          return;
        end if;
      end for;
    end anyChanges;
  end LinearJacobian;

protected
  function jacobianSymbolic extends Module.jacobianInterface;
  protected
    VariablePointers seedCandidates, partialCandidates, residuals;
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    Pointer<UnorderedMap<ComponentRef,ComponentRef>> jacobianHT = Pointer.create(UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual));
    Option<UnorderedMap<ComponentRef,ComponentRef>> optHT;
    Differentiate.DifferentiationArguments diffArguments;

    list<Pointer<Equation>> eqn_lst, diffed_eqn_lst;
    EquationPointers diffedEquations;
    BEquation.EqData eqDataJac;
    Pointer<Integer> idx = Pointer.create(0);
    list<Pointer<Variable>> residual_vars;

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;

  algorithm
    // ToDo: apply tearing to split residual/inner variables and equations
    // add inner / tmp cref tuples to HT
    (seedCandidates, partialCandidates) := if isSome(daeUnknowns) then (Util.getOption(daeUnknowns), unknowns) else (unknowns, VariablePointers.empty());

    // create seed and pDer vars (also filters out discrete vars)
    VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, ht = jacobianHT, makeVar = BVariable.makeSeedVar));
    VariablePointers.mapPtr(partialCandidates, function makeVarTraverse(name = name, vars_ptr = pDer_vars_ptr, ht = jacobianHT, makeVar = BVariable.makePDerVar));

    optHT := SOME(Pointer.access(jacobianHT));

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),             // no explicit cref necessary, rules are set by HT
      new_vars        = {},
      jacobianHT      = optHT, // seed and temporary cref hashtable
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcTree        = funcTree,
      diffedFunctions = AvlSetPath.new()
    );

    // filter all discrete equations and differentiate the others
    eqn_lst := list(eqn for eqn guard(not Equation.isDiscrete(eqn)) in EquationPointers.toList(equations));
    (diffed_eqn_lst, diffArguments) := Differentiate.differentiateEquationPointerList(eqn_lst, diffArguments, idx, name, getInstanceName());
    diffedEquations := EquationPointers.fromList(diffed_eqn_lst);

    // create equation data for jacobian
    // ToDo: split temporary and auxiliares once tearing is applied
    eqDataJac := BEquation.EQ_DATA_JAC(
      uniqueIndex   = idx,
      equations     = diffedEquations,
      results       = diffedEquations,
      temporary     = EquationPointers.empty(),
      auxiliaries   = EquationPointers.empty(),
      removed       = EquationPointers.empty()
    );

    // collect var data
    unknown_vars  := listReverse(Pointer.access(pDer_vars_ptr));
    all_vars      := unknown_vars; // add other vars later on

    seed_vars     := Pointer.access(seed_vars_ptr);
    aux_vars      := seed_vars; // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    res_vars      := {};
    tmp_vars      := {}; // ToDo: add this once system has been torn

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(all_vars),
      unknowns      = VariablePointers.fromList(unknown_vars),
      knowns        = knowns,
      auxiliaries   = VariablePointers.fromList(aux_vars),
      aliasVars     = VariablePointers.fromList(alias_vars),
      diffVars      = unknowns,
      dependencies  = VariablePointers.fromList(depend_vars),
      resultVars    = VariablePointers.fromList(res_vars),
      tmpVars       = VariablePointers.fromList(tmp_vars),
      seedVars      = VariablePointers.fromList(seed_vars)
    );

    if isSome(daeUnknowns) then
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(Util.getOption(daeUnknowns), unknowns, equations, strongComponents);
    else
      //EquationPointers.map(equations, function BEquation.Equation.createResidual(context = "SIM", residual_vars = residual_vars_ptr, idx = idx));
      eqn_lst := EquationPointers.toList(equations);
      residual_vars := list(Equation.getResidualVar(eqn) for eqn in eqn_lst);
      residuals := VariablePointers.fromList(listReverse(residual_vars));
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(unknowns, residuals, equations, strongComponents);
      // safe residuals somewhere?
    end if;

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = name,
      varData           = varDataJac,
      eqData            = eqDataJac,
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianSymbolic;

  function jacobianNumeric extends Module.jacobianInterface;
  protected
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;
  protected
    VariablePointers residuals;
    Pointer<list<Pointer<Variable>>> residual_vars_ptr = Pointer.create({});
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    if isSome(daeUnknowns) then
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(Util.getOption(daeUnknowns), unknowns, equations, strongComponents);
    else
      EquationPointers.map(equations, function BEquation.Equation.createResidual(context = "SIM", residual_vars = residual_vars_ptr, idx = idx));
      residuals := VariablePointers.fromList(listReverse(Pointer.access(residual_vars_ptr)));
      (sparsityPattern, sparsityColoring) := SparsityPattern.create(unknowns, residuals, equations, strongComponents);
      // safe residuals somewhere?
    end if;
    jacobian := SOME(Jacobian.JACOBIAN(
      name              = name,
      varData           = BVariable.VAR_DATA_EMPTY(),
      eqData            = BEquation.EQ_DATA_EMPTY(),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianNumeric;

  function makeVarTraverse
    input Pointer<Variable> var_ptr;
    input String name;
    input Pointer<list<Pointer<Variable>>> vars_ptr;
    input Pointer<UnorderedMap<ComponentRef,ComponentRef>> ht;
    input Func makeVar;

    partial function Func
      input output ComponentRef cref;
      input String name;
      output Pointer<Variable> new_var_ptr;
    end Func;
  protected
    Variable var = Pointer.access(var_ptr);
    ComponentRef cref;
    Pointer<Variable> new_var_ptr;
  algorithm
    // only create seed or pDer var if it is continuous
    if BVariable.isContinuous(var_ptr) then
      (cref, new_var_ptr) := makeVar(var.name, name);
      // add $<new>.x variable pointer to the variables
      Pointer.update(vars_ptr, new_var_ptr :: Pointer.access(vars_ptr));
      // add x -> $<new>.x to the hashTable for later lookup
      UnorderedMap.add(var.name, cref, Pointer.access(ht)); // PHI: Pointer.update ?
    end if;
  end makeVarTraverse;

  annotation(__OpenModelica_Interface="backend");
end NBJacobian;
