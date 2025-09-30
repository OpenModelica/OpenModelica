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
  import NFExpandExp;
  import NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import Adjacency = NBAdjacency;
  import NBAdjacency.Mapping;
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
  import Partition = NBPartition;
  import NFOperator.{MathClassification, SizeClassification};
  import DifferentiatePartials = NBDifferentiatePartials;
  import NBVariable.{VariablePointers, VariablePointer, VarData};
  import NBDifferentiateReverse;
  //import NBSeedGather;

  import Call = NFCall;
  import NFBuiltinFuncs;
  import NFPrefixes;

  // Old Backend Import (remove once coloring ins ported)
  import SymbolicJacobian;

  // Util imports
  import AvlSetPath;
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;
  import Util;

public
  type JacobianType = enumeration(ODE, DAE, LS, NLS);

  function isDynamic
    "is the jacobian used for integration (-> ture)
     or solving algebraic systems (-> false)?"
    input JacobianType jacType;
    output Boolean b;
  algorithm
    b := match jacType
      case JacobianType.ODE then true;
      case JacobianType.DAE then true;
      else false;
    end match;
  end isDynamic;

  function main
    "Wrapper function for any jacobian function. This will be called during
     simulation and gets the corresponding subfunction from Config."
    extends Module.wrapper;
    input Partition.Kind kind;
  protected
    constant Module.jacobianInterface func = getModule();
  algorithm
    bdae := match bdae
      local
        String name                                     "Context name for jacobian";
        VariablePointers knowns                         "Variable array of knowns";
        FunctionTree funcTree                           "Function call bodies";
        list<Partition.Partition> oldPartitions, newPartitions = {} "Equation partitions before and afterwards";
        list<Partition.Partition> oldEvents, newEvents = {}   "Event Equation partitions before and afterwards";

      case BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(knowns = knowns), funcTree = funcTree)
        algorithm
          (oldPartitions, name) := match kind
            case NBPartition.Kind.ODE then (bdae.ode, "ODE_JAC");
            case NBPartition.Kind.DAE then (Util.getOption(bdae.dae), "DAE_JAC");
            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Partition.Partition.kindToString(kind)});
            then fail();
          end match;
          oldEvents := bdae.ode_event;

          if Flags.isSet(Flags.JAC_DUMP) then
            print(StringUtil.headline_1("[symjacdump] Creating symbolic Jacobians:") + "\n");
          end if;

          for part in listReverse(oldPartitions) loop
            (part, funcTree) := partJacobian(part, funcTree, knowns, name, func);
            newPartitions := part::newPartitions;
          end for;

          for part in listReverse(oldEvents) loop
            (part, funcTree) := partJacobian(part, funcTree, knowns, name, func);
            newEvents := part::newEvents;
          end for;

          () := match kind
            case NBPartition.Kind.ODE algorithm bdae.ode := newPartitions; then ();
            case NBPartition.Kind.DAE algorithm bdae.dae := SOME(newPartitions); then ();
            else ();
          end match;
          bdae.ode_event := newEvents;
          bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + BackendDAE.toString(bdae)});
      then fail();

    end match;
  end main;

  function nonlinear
    input VariablePointers variables;
    input EquationPointers equations;
    input array<StrongComponent> comps;
    output Option<Jacobian> jacobian;
    input output FunctionTree funcTree;
    input String name;
    input Boolean init;
  protected
    constant Module.jacobianInterface func = if Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN)
      then jacobianSymbolic
      else jacobianNumeric;
  algorithm
    (jacobian, funcTree) := func(
        name              = name,
        jacType           = JacobianType.NLS,
        seedCandidates    = variables,
        partialCandidates = EquationPointers.getResiduals(equations),      // these have to be updated once there are inner equations in torn partitions
        equations         = equations,
        knowns            = VariablePointers.empty(0),      // remove them? are they necessary?
        strongComponents  = SOME(comps),
        funcTree          = funcTree,
        init              = init
      );
  end nonlinear;

  function combine
    input list<BackendDAE> jacobians;
    input String name;
    output BackendDAE jacobian;
  protected
    JacobianType jacType;
    list<Pointer<Variable>> variables = {}, unknowns = {}, knowns = {}, auxiliaryVars = {}, aliasVars = {};
    list<Pointer<Variable>> diffVars = {}, dependencies = {}, resultVars = {}, tmpVars = {}, seedVars = {};
    list<StrongComponent> comps = {};
    list<SparsityPatternCol> col_wise_pattern = {};
    list<SparsityPatternRow> row_wise_pattern = {};
    list<ComponentRef> seed_vars = {};
    list<ComponentRef> partial_vars = {};
    Integer nnz = 0;
    VarData varData;
    EqData eqData;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring = SparsityColoring.lazy(EMPTY_SPARSITY_PATTERN);
  algorithm

    if List.hasOneElement(jacobians) then
      jacobian := listHead(jacobians);
      jacobian := match jacobian case BackendDAE.JACOBIAN() algorithm jacobian.name := name; then jacobian; end match;
    else
      for jac in jacobians loop
        () := match jac
          local
            VarData tmpVarData;
            SparsityPattern tmpPattern;

          case BackendDAE.JACOBIAN(varData = tmpVarData as VarData.VAR_DATA_JAC(), sparsityPattern = tmpPattern) algorithm
            jacType       := jac.jacType;
            variables     := listAppend(VariablePointers.toList(tmpVarData.variables), variables);
            unknowns      := listAppend(VariablePointers.toList(tmpVarData.unknowns), unknowns);
            knowns        := listAppend(VariablePointers.toList(tmpVarData.knowns), knowns);
            auxiliaryVars := listAppend(VariablePointers.toList(tmpVarData.auxiliaries), auxiliaryVars);
            aliasVars     := listAppend(VariablePointers.toList(tmpVarData.aliasVars), aliasVars);
            diffVars      := listAppend(VariablePointers.toList(tmpVarData.diffVars), diffVars);
            dependencies  := listAppend(VariablePointers.toList(tmpVarData.dependencies), dependencies);
            resultVars    := listAppend(VariablePointers.toList(tmpVarData.resultVars), resultVars);
            tmpVars       := listAppend(VariablePointers.toList(tmpVarData.tmpVars), tmpVars);
            seedVars      := listAppend(VariablePointers.toList(tmpVarData.seedVars), seedVars);

            comps         := listAppend(arrayList(jac.comps), comps);

            col_wise_pattern  := listAppend(tmpPattern.col_wise_pattern, col_wise_pattern);
            row_wise_pattern  := listAppend(tmpPattern.row_wise_pattern, row_wise_pattern);
            seed_vars         := listAppend(tmpPattern.seed_vars, seed_vars);
            partial_vars      := listAppend(tmpPattern.partial_vars, partial_vars);
            nnz               := nnz + tmpPattern.nnz;
            sparsityColoring  := SparsityColoring.combine(sparsityColoring, jac.sparsityColoring);
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

      sparsityPattern := SPARSITY_PATTERN(
        col_wise_pattern  = col_wise_pattern,
        row_wise_pattern  = row_wise_pattern,
        seed_vars         = seed_vars,
        partial_vars      = partial_vars,
        nnz               = nnz
      );

      jacobian := BackendDAE.JACOBIAN(
        name              = name,
        jacType           = jacType,
        varData           = varData,
        comps             = listArray(comps),
        sparsityPattern   = sparsityPattern,
        sparsityColoring  = sparsityColoring
      );
    end if;
  end combine;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.jacobianInterface func;
  algorithm
    func := match Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN)
      case "symbolic" then jacobianSymbolic;
      case "adjoint" then jacobianSymbolicAdjoint2;
      case "numeric"  then jacobianNumeric;
      case "none"     then jacobianNone;
    end match;
  end getModule;

  function toString
    input BackendDAE jacobian;
    input output String str;
  algorithm
    str := BackendDAE.toString(jacobian, str);
  end toString;

  function jacobianTypeString
    input JacobianType jacType;
    output String str;
  algorithm
    str := match jacType
      case JacobianType.ODE then "[ODE]";
      case JacobianType.DAE then "[DAE]";
      case JacobianType.LS  then "[LS-]";
      case JacobianType.NLS then "[NLS]";
                            else "[ERR]";
    end match;
  end jacobianTypeString;

  // necessary as wrapping value type for UnorderedMap
  type CrefLst = list<ComponentRef>;

  type SparsityPatternCol = tuple<ComponentRef, list<ComponentRef>> "partial_vars, {seed_vars}";
  type SparsityPatternRow = SparsityPatternCol                      "seed_vars, {partial_vars}";

  uniontype SparsityPattern
    record SPARSITY_PATTERN
      list<SparsityPatternCol> col_wise_pattern   "colum-wise sparsity pattern";
      list<SparsityPatternRow> row_wise_pattern   "row-wise sparsity pattern";
      list<ComponentRef> seed_vars                "independent variables solved here ($SEED)";
      list<ComponentRef> partial_vars             "LHS variables of the jacobian ($pDER)";
      Integer nnz                                 "number of nonzero elements";
    end SPARSITY_PATTERN;

    function toString
      input SparsityPattern pattern;
      output String str = StringUtil.headline_2("Sparsity Pattern (nnz: " + intString(pattern.nnz) + ")");
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
      Boolean colEmpty = listEmpty(pattern.col_wise_pattern);
      Boolean rowEmpty = listEmpty(pattern.row_wise_pattern);
    algorithm
      str := str + "\n" + StringUtil.headline_3("### Seeds (col vars) ###");
      str := str + List.toString(pattern.seed_vars, ComponentRef.toString) + "\n";
      str := str + "\n" + StringUtil.headline_3("### Partials (row vars) ###");
      str := str + List.toString(pattern.partial_vars, ComponentRef.toString) + "\n";
      if not colEmpty then
        str := str + "\n" + StringUtil.headline_3("### Columns ###");
        for col in pattern.col_wise_pattern loop
          (cref, dependencies) := col;
          str := str + "(" + ComponentRef.toString(cref) + ")\t affects:\t" + ComponentRef.listToString(dependencies) + "\n";
        end for;
      end if;
      if not rowEmpty then
        str := str + "\n" + StringUtil.headline_3("##### Rows #####");
        for row in pattern.row_wise_pattern loop
          (cref, dependencies) := row;
          str := str + "(" + ComponentRef.toString(cref) + ")\t depends on:\t" + ComponentRef.listToString(dependencies) + "\n";
        end for;
      end if;
    end toString;

    function lazy
      input VariablePointers seedCandidates;
      input VariablePointers partialCandidates;
      input Option<array<StrongComponent>> strongComponents "Strong Components";
      input JacobianType jacType;
      output SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring;
    protected
      list<ComponentRef> seed_vars, partial_vars;
      list<SparsityPatternCol> cols = {};
      list<SparsityPatternRow> rows = {};
      Integer nnz;
    algorithm
      // get all relevant crefs
      seed_vars     := VariablePointers.getScalarVarNames(seedCandidates);
      partial_vars  := VariablePointers.getScalarVarNames(partialCandidates);

      // assume full dependency
      cols := list((s, partial_vars) for s in seed_vars);
      rows := list((p, seed_vars) for p in partial_vars);
      nnz := listLength(partial_vars) * listLength(seed_vars);

      sparsityPattern := SPARSITY_PATTERN(cols, rows, seed_vars, partial_vars, nnz);
      sparsityColoring := SparsityColoring.lazy(sparsityPattern);
    end lazy;

    function create
      input VariablePointers seedCandidates;
      input VariablePointers partialCandidates;
      input Option<array<StrongComponent>> strongComponents "Strong Components";
      input JacobianType jacType;
      output SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring;
    protected
      UnorderedMap<ComponentRef, list<ComponentRef>> map;
    algorithm
      (sparsityPattern, map) := match strongComponents
        local
          Mapping seed_mapping, partial_mapping;
          array<StrongComponent> comps;
          list<ComponentRef> seed_vars, seed_vars_array, partial_vars, partial_vars_array, tmp, row_vars = {}, col_vars = {};
          UnorderedSet<ComponentRef> set;
          list<SparsityPatternCol> cols = {};
          list<SparsityPatternRow> rows = {};
          Integer nnz = 0;

        case SOME(comps) guard(arrayEmpty(comps)) algorithm
        then (EMPTY_SPARSITY_PATTERN, UnorderedMap.new<CrefLst>(ComponentRef.hash, ComponentRef.isEqual));

        case SOME(comps) algorithm
          // create index mapping only for variables
          seed_mapping    := Mapping.create(EquationPointers.empty(), seedCandidates);
          partial_mapping := Mapping.create(EquationPointers.empty(), partialCandidates);

          // get all relevant crefs
          partial_vars        := VariablePointers.getScalarVarNames(partialCandidates);
          seed_vars           := VariablePointers.getScalarVarNames(seedCandidates);
          // unscalarized seed vars are currently needed for sparsity pattern
          seed_vars_array     := VariablePointers.getVarNames(seedCandidates);
          partial_vars_array  := VariablePointers.getVarNames(partialCandidates);

          // create a sufficient big unordered map
          map := UnorderedMap.new<CrefLst>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(seed_vars) + listLength(partial_vars)));
          set := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(seed_vars_array)));

          // save all seed_vars and partial_vars to know later on if a cref should be added
          for cref in seed_vars loop UnorderedMap.add(cref, {}, map); end for;
          for cref in partial_vars loop UnorderedMap.add(cref, {}, map); end for;
          for cref in seed_vars_array loop UnorderedSet.add(cref, set); end for;
          for cref in partial_vars_array loop UnorderedSet.add(cref, set); end for;

          // traverse all components and save cref dependencies (only column-wise)
          for i in 1:arrayLength(comps) loop
            StrongComponent.collectCrefs(comps[i], seedCandidates, partialCandidates, seed_mapping, partial_mapping, map, set, jacType);
          end for;

          // create row-wise sparsity pattern
          for cref in listReverse(partial_vars) loop
            // only create rows for derivatives
            if jacType == JacobianType.NLS or BVariable.checkCref(cref, BVariable.isStateDerivative, sourceInfo()) or BVariable.checkCref(cref, BVariable.isResidual, sourceInfo()) then
              if UnorderedMap.contains(cref, map) then
                tmp := UnorderedSet.unique_list(UnorderedMap.getOrFail(cref, map), ComponentRef.hash, ComponentRef.isEqual);
                rows := (cref, tmp) :: rows;
                row_vars := cref :: row_vars;
                for dep in tmp loop
                  // also add inverse dependency (indep var) --> (res/tmp) :: rest
                  UnorderedMap.add(dep, cref :: UnorderedMap.getSafe(dep, map, sourceInfo()), map);
                end for;
              end if;
            end if;
          end for;

          // create column-wise sparsity pattern
          for cref in listReverse(seed_vars) loop
            if jacType == JacobianType.NLS or BVariable.checkCref(cref, BVariable.isState, sourceInfo()) then
              tmp := UnorderedSet.unique_list(UnorderedMap.getSafe(cref, map, sourceInfo()), ComponentRef.hash, ComponentRef.isEqual);
              cols := (cref, tmp) :: cols;
              col_vars := cref :: col_vars;
            end if;
          end for;

          // find number of nonzero elements
          for col in cols loop
            (_, tmp) := col;
            nnz := nnz + listLength(tmp);
          end for;
        then (SPARSITY_PATTERN(cols, rows, listReverse(col_vars), listReverse(row_vars), nnz), map);

        case NONE() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing strong components."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();

      end match;

      // create coloring
      sparsityColoring := SparsityColoring.PartialD2ColoringAlgC(sparsityPattern, jacType);

      if Flags.isSet(Flags.DUMP_SPARSE) then
        print(toString(sparsityPattern) + "\n" + SparsityColoring.toString(sparsityColoring) + "\n");
      end if;
    end create;

    function createEmpty
      output SparsityPattern sparsityPattern = EMPTY_SPARSITY_PATTERN;
      output SparsityColoring sparsityColoring = EMPTY_SPARSITY_COLORING;
    end createEmpty;

    function transposeRenamed
      "Transpose a sparsity pattern while applying renaming maps:
          oldPartial -> newSeed
          oldSeed    -> newPartial (pDer)
        The new col_wise is the renamed old row_wise,
        and the new row_wise is the renamed old col_wise."
      input SparsityPattern pattern;
      input UnorderedMap<ComponentRef, ComponentRef> mapPartialToNewSeed;
      input UnorderedMap<ComponentRef, ComponentRef> mapSeedToNewPDer;
      input JacobianType jacType;
      output SparsityPattern transposedPattern;
      output SparsityColoring transposedColoring;
    protected
      list<SparsityPatternCol> newCols = {};
      list<SparsityPatternRow> newRows = {};
      list<ComponentRef> newSeedVars = {};
      list<ComponentRef> newPartialVars = {};
      ComponentRef oldHead, newHead, depOld, depNew;
      list<ComponentRef> deps, newDeps;
      Integer nnz = 0;
    algorithm
      // New seed_vars = renamed old partials
      for oldHead in pattern.partial_vars loop
        if UnorderedMap.contains(oldHead, mapPartialToNewSeed) then
          newSeedVars := UnorderedMap.getOrFail(oldHead, mapPartialToNewSeed) :: newSeedVars;
        end if;
      end for;
      newSeedVars := listReverse(newSeedVars);

      // New partial_vars = renamed old seeds
      for oldHead in pattern.seed_vars loop
        if UnorderedMap.contains(oldHead, mapSeedToNewPDer) then
          newPartialVars := UnorderedMap.getOrFail(oldHead, mapSeedToNewPDer) :: newPartialVars;
        end if;
      end for;
      newPartialVars := listReverse(newPartialVars);

      // New columns = renamed old rows (oldPartial -> list oldSeeds)
      // the renamed row wise pattern is the new col_wise pattern
      for row in pattern.row_wise_pattern loop
        (oldHead, deps) := row;
        if UnorderedMap.contains(oldHead, mapPartialToNewSeed) then
          newHead := UnorderedMap.getOrFail(oldHead, mapPartialToNewSeed); // get the renamed partial (new seed)
          newDeps := {};
          for depOld in deps loop
            if UnorderedMap.contains(depOld, mapSeedToNewPDer) then
              depNew := UnorderedMap.getOrFail(depOld, mapSeedToNewPDer); // get the renamed seed (new pDer)
              newDeps := depNew :: newDeps;
            end if;
          end for;
          // keep unique deps and stable order
          newDeps := UnorderedSet.unique_list(listReverse(newDeps), ComponentRef.hash, ComponentRef.isEqual);
          newCols := (newHead, newDeps) :: newCols;
          nnz := nnz + listLength(newDeps);
        end if;
      end for;
      newCols := listReverse(newCols);

      // New rows = renamed old columns (oldSeed -> list oldPartials)
      for col in pattern.col_wise_pattern loop
        (oldHead, deps) := col;
        if UnorderedMap.contains(oldHead, mapSeedToNewPDer) then
          newHead := UnorderedMap.getOrFail(oldHead, mapSeedToNewPDer); // get the renamed seed (new pDer)
          newDeps := {};
          for depOld in deps loop
            if UnorderedMap.contains(depOld, mapPartialToNewSeed) then
              depNew := UnorderedMap.getOrFail(depOld, mapPartialToNewSeed); // get the renamed partial (new seed)
              newDeps := depNew :: newDeps;
            end if;
          end for;
          newDeps := UnorderedSet.unique_list(listReverse(newDeps), ComponentRef.hash, ComponentRef.isEqual);
          newRows := (newHead, newDeps) :: newRows;
        end if;
      end for;
      newRows := listReverse(newRows);

      transposedPattern := SPARSITY_PATTERN(
        col_wise_pattern = newCols,
        row_wise_pattern = newRows,
        seed_vars        = newSeedVars,
        partial_vars     = newPartialVars,
        nnz              = nnz
      );

      // Re-color after transpose
      transposedColoring := SparsityColoring.PartialD2ColoringAlgC(transposedPattern, jacType);
    end transposeRenamed;
  end SparsityPattern;

  constant SparsityPattern EMPTY_SPARSITY_PATTERN = SPARSITY_PATTERN({}, {}, {}, {}, 0);
  constant SparsityColoring EMPTY_SPARSITY_COLORING = SPARSITY_COLORING(listArray({}), listArray({}));

  type SparsityColoringCol = list<ComponentRef>  "seed variable lists belonging to the same color";
  type SparsityColoringRow = SparsityColoringCol "partial variable lists for each color (multiples allowed!)";

  uniontype SparsityColoring
    record SPARSITY_COLORING
      "column wise coloring with extra row sparsity information"
      array<SparsityColoringCol> cols;
      array<SparsityColoringRow> rows;
    end SPARSITY_COLORING;

    function toString
      input SparsityColoring sparsityColoring;
      output String str = StringUtil.headline_2("Sparsity Coloring");
    protected
      Boolean empty = arrayLength(sparsityColoring.cols) == 0;
    algorithm
      if empty then
        str := str + "\n<empty sparsity pattern>\n";
      end if;
      for i in 1:arrayLength(sparsityColoring.cols) loop
        str := str + "Color (" + intString(i) + ")\n"
          + "  - Column: " + ComponentRef.listToString(sparsityColoring.cols[i]) + "\n"
          + "  - Row:    " + ComponentRef.listToString(sparsityColoring.rows[i]) + "\n\n";
      end for;
    end toString;

    function lazy
      "creates a lazy coloring that just groups each independent variable individually
      and implies dependence for each row"
      input SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring;
    protected
      array<SparsityColoringCol> cols;
      array<SparsityColoringRow> rows;
    algorithm
      cols := listArray(list({cref} for cref in sparsityPattern.seed_vars));
      rows := arrayCreate(arrayLength(cols), sparsityPattern.partial_vars);
      sparsityColoring := SPARSITY_COLORING(cols, rows);
    end lazy;

    function PartialD2ColoringAlgC
      "author: kabdelhak 2022-03
      taken from: 'What Color Is Your Jacobian? Graph Coloring for Computing Derivatives'
      https://doi.org/10.1137/S0036144504444711
      A greedy partial distance-2 coloring algorithm implemented in C."
      input SparsityPattern sparsityPattern;
      input JacobianType jacType;
      output SparsityColoring sparsityColoring;
    protected
      array<ComponentRef> seeds, partials;
      UnorderedMap<ComponentRef, Integer> seed_indices, partial_indices;
      Integer sizeCols, sizeRows;
      ComponentRef idx_cref;
      list<ComponentRef> deps;
      array<list<Integer>> cols, rows, colored_cols;
      array<SparsityColoringCol> cref_colored_cols;
    algorithm
      // create index -> cref arrays
      seeds := listArray(sparsityPattern.seed_vars);
      if jacType == JacobianType.NLS then
        partials := listArray(sparsityPattern.partial_vars);
      else
        partials := listArray(list(cref for cref guard(BVariable.checkCref(cref, BVariable.isStateDerivative, sourceInfo()) or
          BVariable.checkCref(cref, BVariable.isResidual, sourceInfo())) in sparsityPattern.partial_vars));
      end if;

      // create cref -> index maps
      sizeCols := arrayLength(seeds);
      sizeRows := arrayLength(partials);
      seed_indices := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(sizeCols));
      partial_indices := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(sizeRows));
      for i in 1:sizeCols loop
        UnorderedMap.add(seeds[i], i, seed_indices);
      end for;
      for i in 1:sizeRows loop
        UnorderedMap.add(partials[i], i, partial_indices);
      end for;
      cols := arrayCreate(sizeCols, {});
      rows := arrayCreate(sizeRows, {});

      // prepare index based sparsity pattern for C
      for tpl in sparsityPattern.col_wise_pattern loop
        (idx_cref, deps) := tpl;
        cols[UnorderedMap.getSafe(idx_cref, seed_indices, sourceInfo())] := list(UnorderedMap.getSafe(dep, partial_indices, sourceInfo()) for dep in deps);
      end for;
      for tpl in sparsityPattern.row_wise_pattern loop
        (idx_cref, deps) := tpl;
        rows[UnorderedMap.getSafe(idx_cref, partial_indices, sourceInfo())] := list(UnorderedMap.getSafe(dep, seed_indices, sourceInfo()) for dep in deps);
      end for;

      // call C function (old backend - ToDo: port to new backend!)
      //colored_cols := SymbolicJacobian.createColoring(cols, rows, sizeRows, sizeCols);
      colored_cols := SymbolicJacobian.createColoring(rows, cols, sizeCols, sizeRows);

      // get cref based coloring - currently no row coloring
      cref_colored_cols := arrayCreate(arrayLength(colored_cols), {});
      for i in 1:arrayLength(colored_cols) loop
        cref_colored_cols[i] := list(seeds[idx] for idx in colored_cols[i]);
      end for;

      sparsityColoring := SPARSITY_COLORING(cref_colored_cols, arrayCreate(sizeRows, {}));
    end PartialD2ColoringAlgC;

    function PartialD2ColoringAlg
      "author: kabdelhak 2022-03
      taken from: 'What Color Is Your Jacobian? Graph Coloring for Computing Derivatives'
      https://doi.org/10.1137/S0036144504444711
      A greedy partial distance-2 coloring algorithm. Slightly adapted to also track row sparsity."
      input SparsityPattern sparsityPattern;
      input UnorderedMap<ComponentRef, list<ComponentRef>> map;
      output SparsityColoring sparsityColoring;
    protected
      array<ComponentRef> cref_lookup;
      UnorderedMap<ComponentRef, Integer> index_lookup;
      array<Boolean> color_exists;
      array<Integer> coloring, forbidden_colors;
      array<list<ComponentRef>> col_coloring, row_coloring;
      Integer color;
      list<SparsityColoringCol> cols_lst = {};
      list<SparsityColoringRow> rows_lst = {};
    algorithm
      // integer to cref and reverse lookup arrays
      cref_lookup := listArray(sparsityPattern.seed_vars);
      index_lookup := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(sparsityPattern.seed_vars)));
      for i in 1:arrayLength(cref_lookup) loop
        UnorderedMap.add(cref_lookup[i], i, index_lookup);
      end for;

      // create empty colorings
      coloring := arrayCreate(arrayLength(cref_lookup), 0);
      forbidden_colors := arrayCreate(arrayLength(cref_lookup), 0);
      color_exists := arrayCreate(arrayLength(cref_lookup), false);
      col_coloring := arrayCreate(arrayLength(cref_lookup), {});
      row_coloring := arrayCreate(arrayLength(cref_lookup), {});

      for i in 1:arrayLength(cref_lookup) loop
        for row_var /* w */ in UnorderedMap.getSafe(cref_lookup[i], map, sourceInfo()) loop
          for col_var /* x */ in UnorderedMap.getSafe(row_var, map, sourceInfo()) loop
            color := coloring[UnorderedMap.getSafe(col_var, index_lookup, sourceInfo())];
            if color > 0 then
              forbidden_colors[color] := i;
            end if;
          end for;
        end for;
        color := 1;
        while forbidden_colors[color] == i loop
          color := color + 1;
        end while;
        coloring[i] := color;
        // also save all row dependencies of this color
        row_coloring[color] := listAppend(row_coloring[color], UnorderedMap.getSafe(cref_lookup[i], map, sourceInfo()));
        color_exists[color] := true;
      end for;

      for i in 1:arrayLength(coloring) loop
        col_coloring[coloring[i]] := cref_lookup[i] :: col_coloring[coloring[i]];
      end for;

      // traverse in reverse to have correct ordering in the end)
      for i in arrayLength(color_exists):-1:1 loop
        if color_exists[i] then
          cols_lst := col_coloring[i] :: cols_lst;
          rows_lst := row_coloring[i] :: rows_lst;
        end if;
      end for;

      sparsityColoring := SPARSITY_COLORING(listArray(cols_lst), listArray(rows_lst));
    end PartialD2ColoringAlg;

    function combine
      "combines sparsity patterns by just appending them because they are supposed to
      be entirely independent of each other."
      input SparsityColoring coloring1;
      input SparsityColoring coloring2;
      output SparsityColoring coloring_out;
    protected
      SparsityColoring smaller_coloring;
    algorithm
      // append the smaller to the bigger
      (coloring_out, smaller_coloring) := if arrayLength(coloring2.cols) > arrayLength(coloring1.cols) then (coloring2, coloring1) else (coloring1, coloring2);

      for i in 1:arrayLength(smaller_coloring.cols) loop
        coloring_out.cols[i] := listAppend(coloring_out.cols[i], smaller_coloring.cols[i]);
        coloring_out.rows[i] := listAppend(coloring_out.rows[i], smaller_coloring.rows[i]);
      end for;
    end combine;
  end SparsityColoring;

protected
  // ToDo: all the DAEMode stuff is probably incorrect!

  function partJacobian
    input output Partition.Partition part;
    input output FunctionTree funcTree;
    input VariablePointers knowns;
    input String name                                     "Context name for jacobian";
    input Module.jacobianInterface func;
  protected
    JacobianType jacType;
    VariablePointers unknowns;
    list<Pointer<Variable>> derivative_vars, state_vars;
    VariablePointers seedCandidates, partialCandidates;
    Option<Jacobian> jacobian                             "Resulting jacobian";
    Partition.Kind kind = Partition.Partition.getKind(part);
  algorithm
    partialCandidates := part.unknowns;
    unknowns  := if Partition.Partition.getKind(part) == NBPartition.Kind.DAE then Util.getOption(part.daeUnknowns) else part.unknowns;
    jacType   := if Partition.Partition.getKind(part) == NBPartition.Kind.DAE then JacobianType.DAE else JacobianType.ODE;

    derivative_vars := list(var for var guard(BVariable.isStateDerivative(var)) in VariablePointers.toList(unknowns));
    state_vars := list(Util.getOption(BVariable.getVarState(var)) for var in derivative_vars);
    seedCandidates := VariablePointers.fromList(state_vars, partialCandidates.scalarized);

    (jacobian, funcTree) := func(name, jacType, seedCandidates, partialCandidates, part.equations, knowns, part.strongComponents, funcTree, kind ==  NBPartition.Kind.INI);

    if Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN) == "adjoint" and Util.isSome(jacobian) then
      part.association := Partition.Association.CONTINUOUS(kind, NONE(), jacobian);
    else
      part.association := Partition.Association.CONTINUOUS(kind, jacobian, NONE());
    end if;
    if Flags.isSet(Flags.JAC_DUMP) then
      print(Partition.Partition.toString(part, 2));
    end if;
  end partJacobian;

  function jacobianSymbolic extends Module.jacobianInterface;
  protected
    list<StrongComponent> comps, diffed_comps;
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Integer> idx = Pointer.create(0);

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;

    BVariable.checkVar func = getTmpFilterFunction(jacType);
  algorithm
    if Util.isSome(strongComponents) then
      // filter all discrete strong components and differentiate the others
      // todo: mixed algebraic loops should be here without the discrete subsets
      comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(strongComponents));
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no strong components were given!"});
    end if;

    // create seed vars
    VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, map = diff_map, makeVar = BVariable.makeSeedVar, init = init));

    // create pDer vars (also filters out discrete vars)
    (res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(init = init));

    for v in res_vars loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = false), init = init); end for;
    res_vars := Pointer.access(pDer_vars_ptr);

    pDer_vars_ptr := Pointer.create({});
    for v in tmp_vars loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = true), init = init); end for;
    tmp_vars := Pointer.access(pDer_vars_ptr);

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),   // no explicit cref necessary, rules are set by diff map
      new_vars        = {},
      diff_map        = SOME(diff_map),         // seed and temporary cref map
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcTree        = funcTree,
      scalarized      = seedCandidates.scalarized,
      adjoint_map     = NONE(),
      current_grad    = Expression.EMPTY(Type.REAL()),
      collectAdjoints = false
    );

    // differentiate all strong components
    (diffed_comps, diffArguments) := Differentiate.differentiateStrongComponentList(comps, diffArguments, idx, name, getInstanceName());
    funcTree := diffArguments.funcTree;

    // collect var data (most of this can be removed)
    unknown_vars  := listAppend(res_vars, tmp_vars);
    all_vars      := unknown_vars;  // add other vars later on

    seed_vars     := Pointer.access(seed_vars_ptr);
    aux_vars      := seed_vars;     // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(all_vars),
      unknowns      = VariablePointers.fromList(unknown_vars),
      knowns        = knowns,
      auxiliaries   = VariablePointers.fromList(aux_vars),
      aliasVars     = VariablePointers.fromList(alias_vars),
      diffVars      = partialCandidates,
      dependencies  = VariablePointers.fromList(depend_vars),
      resultVars    = VariablePointers.fromList(res_vars),
      tmpVars       = VariablePointers.fromList(tmp_vars),
      seedVars      = VariablePointers.fromList(seed_vars)
    );

    (sparsityPattern, sparsityColoring) := SparsityPattern.create(seedCandidates, partialCandidates, strongComponents, jacType);

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = name,
      jacType           = jacType,
      varData           = varDataJac,
      comps             = listArray(diffed_comps),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianSymbolic;

  function mulCoeffRhs
    input Expression coeff;
    input ComponentRef rhsVar;
    input NFOperator.SizeClassification sizeCl;
    output Expression term;
  protected
    // For robustness we still use REAL; NFOperator classification encodes the array shape.
    Operator mulOp = Operator.fromClassification(
      (NFOperator.MathClassification.MULTIPLICATION, sizeCl),
      Type.REAL()
    );
  algorithm
    term := SimplifyExp.simplify(Expression.MULTARY({coeff, Expression.CREF(Type.REAL(), rhsVar)}, {}, mulOp), true);
  end mulCoeffRhs;

  // Element-wise array multiplication: a .* q
  // Uses mulCoeffRhs with SizeClassification.ELEMENT_WISE.
  function arrayElemMul
    input Expression a;
    input Expression b;
    output Expression out;
  algorithm
    // Expect b to be a cref; fall back to generic element-wise if not.
    out := match b
      case Expression.CREF() then
        mulCoeffRhs(a, b.cref, NFOperator.SizeClassification.ELEMENT_WISE);
      else
        SimplifyExp.simplify(
          Expression.MULTARY(
            {a, b}, {},
            Operator.fromClassification(
              (NFOperator.MathClassification.MULTIPLICATION, NFOperator.SizeClassification.ELEMENT_WISE),
              Type.REAL()
            )), true);
    end match;
  end arrayElemMul;

  // Matrix-vector product: A * q (no element-wise), i.e., MATRIX_VECTOR
  // Uses mulCoeffRhs with SizeClassification.MATRIX_VECTOR.
  function matVecMul
    input Expression A;
    input Expression v;
    output Expression out;
  algorithm
    // Expect v to be a cref; fall back to generic matrix-vector operator if not.
    out := match v
      case Expression.CREF() then
        mulCoeffRhs(A, v.cref, NFOperator.SizeClassification.MATRIX_VECTOR);
      else
        SimplifyExp.simplify(
          Expression.MULTARY(
            {A, v}, {},
            Operator.fromClassification(
              (NFOperator.MathClassification.MULTIPLICATION, NFOperator.SizeClassification.MATRIX_VECTOR),
              Type.REAL()
            )), true);
    end match;
  end matVecMul;

  // is called with a result var as baseCref
  // pDer -> seed
  function ensureSeedVarCref
    input ComponentRef baseCref;
    input String name;
    output ComponentRef seedCref;
    output Pointer<Variable> vp;
  algorithm
    // Use returned canonical cref: $SEED_<name>.<baseCref>
    (seedCref, vp) := BVariable.makeSeedVar(baseCref, name);
  end ensureSeedVarCref;


  // is called with a seed var or a tmp var as baseCref
  // seed or tmp -> pDer
  // Create or reuse the canonical pDer cref: $pDER_<name>.<cref>
  // isTmp = false -> result var (JAC_VAR), true -> tmp var (JAC_TMP_VAR)
  function ensurePDerVarCref
    input ComponentRef baseCref;
    input String name;
    input Boolean isTmp;
    output ComponentRef pderCref;
    output Pointer<Variable> vp;
  algorithm
    // Use returned canonical cref: $pDER_<name>.<baseCref>
    (pderCref, vp) := BVariable.makePDerVar(baseCref, name, isTmp);
  end ensurePDerVarCref;

  function typeTransposeCall
    "Create a typed builtin transpose(mat) call without expanding mat.
     Returns mat if it is not an array with at least 2 dimensions."
    input Expression mat;
    output Expression tr;
  protected
    Type inTy = Expression.typeOf(mat);
    list<Type.Dimension> dims;
    Type elTy;
    Type resTy;
    NFCall call;
    NFPrefixes.Variability var = Expression.variability(mat);
    NFPrefixes.Purity pur = Expression.purity(mat);
    NFFunction.Function TRANSPOSE_FUNC;
  algorithm
    // Only handle array types
    if not Type.isArray(inTy) then
      tr := mat;
      return;
    end if;

    elTy := Type.arrayElementType(inTy);
    dims := Type.arrayDims(inTy);

    // Need at least 2 dimensions to transpose
    if listLength(dims) < 2 then
      tr := mat;
      return;
    end if;

    // Swap first two dimensions; keep the rest
    resTy := Type.ARRAY(
      elTy,
      listAppend({listGet(dims,2), listGet(dims,1)}, listRest(listRest(dims)))
    );

    // Build a minimal builtin function descriptor (local, not globally registered)
    TRANSPOSE_FUNC :=
      NFFunction.Function.FUNCTION(
        Absyn.Path.IDENT("transpose"),
        NFInstNode.EMPTY_NODE(),
        {}, {}, {}, {},
        resTy,
        DAE.FUNCTION_ATTRIBUTES_BUILTIN,
        {}, {}, listArray({}),
        Pointer.createImmutable(NFFunction.FunctionStatus.BUILTIN),
        Pointer.createImmutable(0));

    call := NFCall.makeTypedCall(TRANSPOSE_FUNC, {mat}, var, pur, resTy);
    tr := Expression.CALL(call);
  end typeTransposeCall;

  // Create the adjoint contribution term for coeff * rhsVar
  // depending on the type of coeff (scalar, vector, matrix)
  function makeAdjointContribution
    input Expression coeff;
    input ComponentRef rhsVar;
    output Expression term;
  protected
    Type tyC = Expression.typeOf(coeff);
    Integer rnk = Type.dimensionCount(tyC); // 0: scalar, 1: vector, 2: matrix
    Expression qexp = Expression.CREF(Type.REAL(), rhsVar); // actual type is handled by helpers
    Expression transposeCoeff;
  algorithm
    if not Type.isArray(tyC) then
      // scalar
      term := mulCoeffRhs(coeff, rhsVar, NFOperator.SizeClassification.SCALAR);
    elseif rnk == 1 then
      // vector coeff -> element-wise multiply
      print("arrayElemMul with coeff: " + Expression.toStringTyped(coeff) + "\n");
      term := SimplifyExp.simplify(arrayElemMul(coeff, qexp));
    elseif rnk == 2 then
      // matrix coeff -> transpose(coeff) * q
      print("matVecMul with coeff: " + Expression.toStringTyped(coeff) + "\n");
      transposeCoeff := typeTransposeCall(coeff);
      print("matVecMul with coeff transposed: " + Expression.toStringTyped(transposeCoeff) + "\n");
      term := SimplifyExp.simplify(matVecMul(transposeCoeff, qexp));
    else
      // higher ranks: fallback to plain multiply
      term := mulCoeffRhs(coeff, rhsVar, NFOperator.SizeClassification.SCALAR);
    end if;
  end makeAdjointContribution;

  function sizeClassificationFromType
    input Type ty;
    output NFOperator.SizeClassification sc;
  protected
    Integer rnk = Type.dimensionCount(ty);
  algorithm
    sc := if rnk == 0 then 
        NFOperator.SizeClassification.SCALAR
      else if rnk == 1 then 
        NFOperator.SizeClassification.ELEMENT_WISE
      else
        NFOperator.SizeClassification.MATRIX_VECTOR;
  end sizeClassificationFromType;

  function adjointMapToString
    "Pretty print the optional adjoint_map:
       { cref1 -> [e1, e2, ...]; cref2 -> [ ... ]; }
     If NONE() => {}"
    input Option<UnorderedMap<ComponentRef, ExpressionList>> adjoint_map;
    output String str;
  protected
    UnorderedMap<ComponentRef, ExpressionList> map;
    list<ComponentRef> keys;
    list<String> entries = {};
    ComponentRef k;
    ExpressionList elst;
    String kstr;
    String vstr;
    list<String> vparts;
  algorithm
    if not Util.isSome(adjoint_map) then
      str := "{}";
      return;
    end if;

    SOME(map) := adjoint_map;

    // Collect and sort keys (for deterministic output).
    keys := UnorderedMap.keyList(map);
    entries := {};
    for k in keys loop
      elst := UnorderedMap.getOrFail(k, map);
      vparts := list(Expression.toString(e) for e in elst);
      vstr := "[" + stringDelimitList(vparts, ", ") + "]";
      kstr := ComponentRef.toString(k);
      entries := (kstr + " -> " + vstr) :: entries;
    end for;

    entries := listReverse(entries);
    str := "{ " + stringDelimitList(entries, ";\n") + " }";
  end adjointMapToString;

  // Helper: build addition (or single term) expression from a list of terms for a given LHS cref.
  function buildAdjointRhs
    input ComponentRef lhsCref;
    input ExpressionList terms;
    output Expression rhs;
  protected
    Pointer<Variable> vptr;
    Variable v;
    Type vty;
    NFOperator.SizeClassification sc;
    Operator addOp;
  algorithm
    // Retrieve variable type (fallback Real if not found)
    vty := ComponentRef.getComponentType(lhsCref);

    if listEmpty(terms) then
      rhs := Expression.makeZero(vty);
      return;
    end if;

    if listLength(terms) == 1 then
      rhs := listHead(terms);
      return;
    end if;

    sc := sizeClassificationFromType(vty);
    addOp := Operator.fromClassification(
      (NFOperator.MathClassification.ADDITION, sc),
      vty
    );

    rhs := Expression.MULTARY(terms, {}, addOp);
  end buildAdjointRhs;


  function jacobianSymbolicAdjoint2 extends Module.jacobianInterface;
  protected
    list<StrongComponent> comps, diffed_comps;
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Integer> idx = Pointer.create(0);

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars, old_res_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;

    BVariable.checkVar func = getTmpFilterFunction(jacType);
    UnorderedMap<ComponentRef, ExpressionList> adjoint_map;
    ExpressionList terms;
    Expression lhsExpr, rhsExpr;
    Pointer<Variable> lhsVarPtr;
    Pointer<NBEquation.Equation> eqPtr;
    Integer i, i_idx;
    ComponentRef newC, baseCref;

    UnorderedMap<ComponentRef, ComponentRef> mapPartialToNewSeed =
      UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<ComponentRef, ComponentRef> mapSeedToNewPDer =
      UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    VariablePointers vp_single;
    list<ComponentRef> scalarCrefs;
    list<Expression> scalarTerms, vectorTerms, unitElems;
    Boolean anyNonZero;
    ExpressionList sc_terms, existing;
    Expression scalarRhs, arrayExpr, unitVec, vectorTerm, aggregatedVec;
    Type elementTy;
  algorithm
    if Util.isSome(strongComponents) then
      // filter all discrete strong components and differentiate the others
      // todo: mixed algebraic loops should be here without the discrete subsets
      comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(strongComponents));
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no strong components were given!"});
    end if;

    // create seed vars
    for v in VariablePointers.toList(seedCandidates) loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = false), init = init); end for;
    //VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = pDer_vars_ptr, map = diff_map, makeVar = BVariable.makePDerVar(isTmp = false), init = init));
    res_vars := Pointer.access(pDer_vars_ptr);

    // create pDer vars (also filters out discrete vars)
    (old_res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(init = init));

    for v in old_res_vars loop makeVarTraverse(v, name, seed_vars_ptr, diff_map, BVariable.makeSeedVar, init = init); end for;
    seed_vars := Pointer.access(seed_vars_ptr);

    pDer_vars_ptr := Pointer.create({});
    for v in tmp_vars loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = true), init = init); end for;
    tmp_vars := Pointer.access(pDer_vars_ptr);

    // create empty adjoint map with seed vars and tmp vars as keys mapping to empty lists
    adjoint_map := UnorderedMap.new<ExpressionList>(ComponentRef.hash, ComponentRef.isEqual);
    for v in res_vars loop
      UnorderedMap.addNew(BVariable.getVarName(v), {}, adjoint_map);
      // Expand to scalar components and add them as keys too
      // to handle array seeds correctly
      vp_single := VariablePointers.fromList({v});
      for scalarCref in VariablePointers.getScalarVarNames(vp_single) loop
        if not UnorderedMap.contains(scalarCref, adjoint_map) then
          UnorderedMap.addNew(scalarCref, {}, adjoint_map);
        end if;
      end for;
    end for;
    for v in tmp_vars loop
      UnorderedMap.addNew(BVariable.getVarName(v), {}, adjoint_map);
      vp_single := VariablePointers.fromList({v});
      for scalarCref in VariablePointers.getScalarVarNames(vp_single) loop
        if not UnorderedMap.contains(scalarCref, adjoint_map) then
          UnorderedMap.addNew(scalarCref, {}, adjoint_map);
        end if;
      end for;
    end for;

    print("Adjoint map before:\n" + adjointMapToString(SOME(adjoint_map)) + "\n");

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),   // no explicit cref necessary, rules are set by diff map
      new_vars        = {},
      diff_map        = SOME(diff_map),         // seed and temporary cref map
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcTree        = funcTree,
      scalarized      = seedCandidates.scalarized,
      adjoint_map     = SOME(adjoint_map),
      current_grad    = Expression.EMPTY(Type.REAL()),
      collectAdjoints  = true
    );

    print(BVariable.VariablePointers.toString(seedCandidates, "Seed Candidates"));
    print(boolString(seedCandidates.scalarized));
    print(BVariable.VariablePointers.toString(partialCandidates, "Partial Candidates"));
    print(boolString(partialCandidates.scalarized));

    // differentiate all strong components
    (_, diffArguments) := Differentiate.differentiateStrongComponentListAdjoint(comps, diffArguments, idx, name, getInstanceName());
    funcTree := diffArguments.funcTree;

    print("Adjoint map after:\n" + adjointMapToString(diffArguments.adjoint_map) + "\n");

    // Collapse only array variables: gather k[i] contributions into a single array term and
    // append that term to the base variable entry. Do NOT clear the base entry itself.
    if Util.isSome(diffArguments.adjoint_map) then
      adjoint_map := Util.getOption(diffArguments.adjoint_map);

      for v in listAppend(res_vars, tmp_vars) loop
        baseCref := BVariable.getVarName(v);
        // Skip if base already missing (defensive)
        if not UnorderedMap.contains(baseCref, adjoint_map) then
          continue;
        end if;

        // Only collapse if variable type is an array (rank > 0)
        if not Type.isArray(ComponentRef.getComponentType(baseCref)) then
          continue; // scalar variable: leave as-is
        end if;

        vp_single := VariablePointers.fromList({v});
        scalarCrefs := VariablePointers.getScalarVarNames(vp_single);

        // Filter out the base cref itself (we only want indexed scalar components)
        scalarCrefs :=
          list(sc for sc guard(not ComponentRef.isEqual(sc, baseCref)) in scalarCrefs);
        // If no scalar component crefs (should not happen for arrays) skip
        if listEmpty(scalarCrefs) then
          continue;
        end if;

        scalarTerms := {};
        anyNonZero := false;
        elementTy := Type.arrayElementType(ComponentRef.getComponentType(baseCref));

        for sc in scalarCrefs loop
          sc_terms := UnorderedMap.getOrDefault(sc, adjoint_map, {});
          // Combine contributions for this scalar component into a scalar expression.
          scalarRhs := match sc_terms
            local
              Expression single;
            case {} then Expression.makeZero(elementTy);
            case {single} then single;
            else
              Expression.MULTARY(
                listReverse(sc_terms), {},
                Operator.fromClassification(
                  (NFOperator.MathClassification.ADDITION, NFOperator.SizeClassification.SCALAR),
                  elementTy
                ));
          end match;

          // If (due to upstream typing) we still got an array, force it to zero (defensive)
          if Type.isArray(Expression.typeOf(scalarRhs)) then
            scalarRhs := Expression.makeZero(elementTy);
          end if;

            // Track non-zero (heuristic)
          if not Expression.isZero(scalarRhs) then
            anyNonZero := true;
          end if;

          // Accumulate in natural order (we will NOT reverse later)
          scalarTerms := scalarRhs :: scalarTerms;
        end for;

        if not anyNonZero then
          // nothing meaningful in scalar components
          continue;
        end if;

        // Build aggregated vector directly as an array literal of scalar entries (ordered k[1], k[2], ...).
        aggregatedVec := Expression.ARRAY(
          ComponentRef.getComponentType(baseCref),
          listArray(listReverse(scalarTerms)),
          true
        );

        // Append aggregated vector AFTER existing base contributions
        existing := UnorderedMap.getOrDefault(baseCref, adjoint_map, {});
        UnorderedMap.add(baseCref, aggregatedVec :: existing, adjoint_map);

        // Clear only the indexed scalar entries k[1], k[2], ...
        for sc in scalarCrefs loop
          if UnorderedMap.contains(sc, adjoint_map) then
            UnorderedMap.add(sc, {}, adjoint_map);
          end if;
        end for;
      end for;

      diffArguments.adjoint_map := SOME(adjoint_map);
    end if;

    print("Adjoint map collapsed:\n" + adjointMapToString(diffArguments.adjoint_map) + "\n");


    if Util.isSome(diffArguments.adjoint_map) then
      adjoint_map := Util.getOption(diffArguments.adjoint_map);

      // New list of strong components replacing original diffed_comps
      diffed_comps := {};
      i := 1;

      for lhsKey in UnorderedMap.keyList(adjoint_map) loop
        terms := UnorderedMap.getOrFail(lhsKey, adjoint_map);

        // (Terms were appended preserving order; use as-is.)
        if listEmpty(terms) then
          // Skip variables with no contributions
          continue;
        end if;

        // Build RHS
        rhsExpr := buildAdjointRhs(lhsKey, terms);

        // LHS expression
        lhsExpr := Expression.fromCref(lhsKey);

        // Create assignment equation
        eqPtr := NBEquation.Equation.makeAssignment(
          lhsExpr, rhsExpr,
          Pointer.create(i),
          "JAC_ADJ",
          NBEquation.Iterator.EMPTY(),
          BackendDAE.EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false));

        // Get (or create) variable pointer for strong component
        lhsVarPtr := BVariable.getVarPointer(lhsKey, sourceInfo());

        // Add strong component
        diffed_comps := NBStrongComponent.SINGLE_COMPONENT(
          var    = lhsVarPtr,
          eqn    = eqPtr,
          status = NBSolve.Status.EXPLICIT
        ) :: diffed_comps;

        if Flags.isSet(Flags.JAC_DUMP) then
          print("[adjoint] " + ComponentRef.toString(lhsKey) + " = " + Expression.toString(rhsExpr) + "\n");
        end if;

        i := i + 1;
      end for;

      diffed_comps := listReverse(diffed_comps);
    end if;

    // collect var data (most of this can be removed)
    unknown_vars  := listAppend(res_vars, tmp_vars);
    all_vars      := unknown_vars;  // add other vars later on

    seed_vars     := Pointer.access(seed_vars_ptr);
    aux_vars      := seed_vars;     // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(all_vars),
      unknowns      = VariablePointers.fromList(unknown_vars),
      knowns        = knowns,
      auxiliaries   = VariablePointers.fromList(aux_vars),
      aliasVars     = VariablePointers.fromList(alias_vars),
      diffVars      = partialCandidates,
      dependencies  = VariablePointers.fromList(depend_vars),
      resultVars    = VariablePointers.fromList(res_vars),
      tmpVars       = VariablePointers.fromList(tmp_vars),
      seedVars      = VariablePointers.fromList(seed_vars)
    );


    (sparsityPattern, _) := SparsityPattern.create(seedCandidates, partialCandidates, strongComponents, jacType);
    // 1) old partials -> new seeds
    i := 1;
    for oldC in sparsityPattern.partial_vars loop
      if i <= listLength(sparsityPattern.seed_vars) then
        newC := listGet(sparsityPattern.seed_vars, i);
        // (partner, _) := BVariable.getVarSeed(newVar);
        // newC := BVariable.getVarName(Util.getOption(partner));
        UnorderedMap.add(oldC, newC, mapPartialToNewSeed);
      end if;
      i := i + 1;
    end for;

    // print("Map original partials to new seeds:\n");
    // print(UnorderedMap.toString(mapPartialToNewSeed, ComponentRef.toString, ComponentRef.toString) + "\n");

    // 2) old seeds -> new pDers
    i := 1;
    for oldC in sparsityPattern.seed_vars loop
      if i <= listLength(sparsityPattern.partial_vars) then
        newC := listGet(sparsityPattern.partial_vars, i);
        // (partner, _) := BVariable.getVarPDer(newC);
        // newC := BVariable.getVarName(Util.getOption(partner));
        UnorderedMap.add(oldC, newC, mapSeedToNewPDer);
      end if;
      i := i + 1;
    end for;

    // print("Map original seeds to new pDers:\n");
    // print(UnorderedMap.toString(mapSeedToNewPDer, ComponentRef.toString, ComponentRef.toString) + "\n");

    (sparsityPattern, sparsityColoring) :=
      SparsityPattern.transposeRenamed(
        sparsityPattern,
        mapPartialToNewSeed,
        mapSeedToNewPDer,
        jacType
      );

    print(SparsityPattern.toString(sparsityPattern) + "\n" + SparsityColoring.toString(sparsityColoring) + "\n");

    // (sparsityPattern, sparsityColoring) := SparsityPattern.create(seedCandidates, partialCandidates, strongComponents, jacType);

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = name,
      jacType           = jacType,
      varData           = varDataJac,
      comps             = listArray(diffed_comps),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianSymbolicAdjoint2;

  // for saving terms for the same lhs in a map
  type ExpressionList = list<Expression>;
  function jacobianSymbolicAdjoint extends Module.jacobianInterface;
  protected
    list<StrongComponent> comps, diffed_comps;
    list<list<NBDifferentiateReverse.PartialsForComponent>> results;
    // sets for naming and filtering
    UnorderedSet<ComponentRef> seedVarsSet;
    UnorderedSet<ComponentRef> resVarsSet;
    UnorderedSet<ComponentRef> tmpVarsSet;
    list<Pointer<Variable>> res_vars, tmp_vars, seed_vars_list, res_vars_list, tmp_vars_list;
    BVariable.checkVar func = getTmpFilterFunction(jacType);
    ExpressionList terms;
    Expression term, lhsExpr, rhsExpr;
    Pointer<Equation> eqPtr;
    Pointer<Variable> lhsVarPtr, vp;
    UnorderedMap<ComponentRef, ExpressionList> lhsToRhs;

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars, diff_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;
    Integer i;

    UnorderedMap<ComponentRef, ComponentRef> mapPartialToNewSeed =
      UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<ComponentRef, ComponentRef> mapSeedToNewPDer =
      UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);

    Pointer<Variable> newVar;
    Option<Pointer<Variable>> partner;
    ComponentRef newC;

    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Integer> idx = Pointer.create(0);
    list<ComponentRef> seeds;
    SparsityPattern sp;
    String newName;
  algorithm
    if Util.isSome(strongComponents) then
      // filter all discrete strong components and differentiate the others
      // todo: mixed algebraic loops should be here without the discrete subsets
      comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(strongComponents));
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no strong components were given!"});
    end if;
    newName := name + "_ADJ";
    print(BVariable.VariablePointers.toString(seedCandidates, "Seed Candidates"));
    print(BVariable.VariablePointers.toString(partialCandidates, "Partial Candidates"));

    // compute top level partial derivatives for each component separately
    results := NBDifferentiateReverse.collectPartialsForComponents(comps);

    for res in results loop
      print(intString(listLength(res)) + " partials for component:\n");
      for r in res loop
        print("  Output: " + Expression.toString(r.outputExpr) + "\n");
        print(NBDifferentiateReverse.partialMapToString(r.partials) + "\n");
      end for;
      print("\n");
    end for;

    // create original result and tmp vars
    (res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(init = init));

    // Build sets for seed, result, and tmp vars for fast filtering
    seedVarsSet := UnorderedSet.fromList(
      VariablePointers.getVarNames(seedCandidates),
      ComponentRef.hash, ComponentRef.isEqual);

    resVarsSet := UnorderedSet.fromList(
      VariablePointers.getVarNames(VariablePointers.fromList(res_vars)),
      ComponentRef.hash, ComponentRef.isEqual);

    tmpVarsSet := UnorderedSet.fromList(
      VariablePointers.getVarNames(VariablePointers.fromList(tmp_vars)),
      ComponentRef.hash, ComponentRef.isEqual);


    // put together the new adjoint equations
    lhsToRhs := UnorderedMap.new<ExpressionList>(ComponentRef.hash, ComponentRef.isEqual);
    res_vars_list := {};
    seed_vars_list := {};
    tmp_vars_list := {};
    for res in results loop
      for r in res loop
        () := match r
          local
            ComponentRef outCref, q_adj, inCref, x_adj;
            Expression outExpr, inExpr;
            NBDifferentiateReverse.PartialMap pm;
            list<Expression> inputs;
            Expression dqdv;
          // for each component's partials
          case NBDifferentiateReverse.PartialsForComponent.PARTIALS_FOR_COMPONENT(outputExpr = outExpr, partials = pm) algorithm
            outCref := NBDifferentiateReverse.getCref(outExpr);
            if not ComponentRef.isEmpty(outCref) then
              // RHS driver adjoint for the output
              // change of roles for the variables
              if UnorderedSet.contains(outCref, resVarsSet) then
                (q_adj, vp) := ensureSeedVarCref(outCref, newName);     // q_s
                seed_vars_list := vp :: seed_vars_list; // add to seed vars
              elseif UnorderedSet.contains(outCref, tmpVarsSet) then
                (q_adj, vp) := ensurePDerVarCref(outCref, newName, true);     // q_p
                tmp_vars_list := vp :: tmp_vars_list; // add to tmp vars
              else
                (q_adj, vp) := ensurePDerVarCref(outCref, newName, true);     // fallback
              end if;

              inputs := UnorderedMap.keyList(pm);
              print(StringUtil.headline_3("Adjoint equations for " + ComponentRef.toString(outCref)) + "\n");

              for inExpr in inputs loop
                inCref := NBDifferentiateReverse.getCref(inExpr);
                // keep only CREF inputs
                if ComponentRef.isEmpty(inCref) then
                  continue;
                end if;
                print("with input " + Expression.toString(inExpr) + "\n");
                // Only generate equations for seeds and tmp vars; skip params/knowns
                if not UnorderedSet.contains(inCref, seedVarsSet) and not UnorderedSet.contains(inCref, tmpVarsSet) then
                  print(ComponentRef.toString(inCref) + " not in seed or tmp vars, skipping\n");
                  continue;
                end if;

                print(ComponentRef.toString(inCref) + " in seed or tmp vars, not skipping\n");
                // LHS naming per variable class
                if UnorderedSet.contains(inCref, seedVarsSet) then
                  (x_adj, vp) := ensurePDerVarCref(inCref, newName, false);  // x_r
                  res_vars_list := vp :: res_vars_list; // add to result vars
                elseif UnorderedSet.contains(inCref, tmpVarsSet) then
                  (x_adj, vp) := ensurePDerVarCref(inCref, newName, true);    // q_p (tmp var)
                elseif UnorderedSet.contains(inCref, resVarsSet) then
                  (x_adj, vp) := ensureSeedVarCref(inCref, newName);    // der(x)_s
                else
                  // nothing to print
                  continue;
                end if;

                // make the multiplication term: dqdv * q_adj
                // dqdv is the partial derivative of outExpr wrt inExpr
                // and q_adj is the new adjoint variable (seed or tmp var)
                dqdv := UnorderedMap.getSafe(inExpr, pm, sourceInfo());
                print("simplified dqdv: " + Expression.toString(NFSimplifyExp.simplify(dqdv, true)) + "\n");
                term := makeAdjointContribution(dqdv, q_adj);
                print(ComponentRef.toString(x_adj) + " = " + Expression.toString(term) + "\n");

                terms := if UnorderedMap.contains(x_adj, lhsToRhs)
                         then UnorderedMap.getSafe(x_adj, lhsToRhs, sourceInfo())
                         else {};
                UnorderedMap.add(x_adj, term :: terms, lhsToRhs);
              end for;
            end if;
          then ();
          else ();
        end match;
      end for;
    end for;


    print(StringUtil.headline_2("Accumulated contributions (lhs -> sum of rhs terms)") + "\n");
    i := 1;
    diffed_comps := {};
    for lhsKey in UnorderedMap.keyList(lhsToRhs) loop
      terms := listReverse(UnorderedMap.getSafe(lhsKey, lhsToRhs, sourceInfo()));

      rhsExpr := Expression.MULTARY(terms, {}, Operator.fromClassification(
        (NFOperator.MathClassification.ADDITION, sizeClassificationFromType(ComponentRef.getComponentType(lhsKey))),
        Type.REAL()
      ));
      print(ComponentRef.toString(lhsKey) + " = " + Expression.toString(rhsExpr) + "\n");

      // LHS expression (cref with Real type)
      lhsExpr := Expression.CREF(ComponentRef.getComponentType(lhsKey), lhsKey);
      print(Expression.toStringTyped(lhsExpr));

      // Create the new equation lhs = rhs
      eqPtr := NBEquation.Equation.makeAssignment(
        lhsExpr, rhsExpr, 
        Pointer.create(i), "JAC", NBEquation.Iterator.EMPTY(), 
        BackendDAE.EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false));

      // Variable pointer for the LHS
      lhsVarPtr := BVariable.getVarPointer(lhsKey, sourceInfo());

      // Create a solved single-component (explicit) for this equation
      diffed_comps := NBStrongComponent.SINGLE_COMPONENT(
        var    = lhsVarPtr,
        eqn    = eqPtr,
        status = NBSolve.Status.EXPLICIT
      ) :: diffed_comps;
      i := i + 1;
    end for;
    diffed_comps := listReverse(diffed_comps);

    // collect var data
    unknown_vars  := listAppend(res_vars_list, tmp_vars_list);
    all_vars      := unknown_vars;  // add other vars later on

    seed_vars     := seed_vars_list;
    aux_vars      := seed_vars;     // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    // i am not sure if everything is correct here
    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(all_vars),
      unknowns      = VariablePointers.fromList(unknown_vars),
      knowns        = knowns,
      auxiliaries   = VariablePointers.fromList(aux_vars),
      aliasVars     = VariablePointers.fromList(alias_vars),
      diffVars      = partialCandidates,
      dependencies  = VariablePointers.fromList(depend_vars),
      resultVars    = VariablePointers.fromList(res_vars_list),
      tmpVars       = VariablePointers.fromList(tmp_vars_list),
      seedVars      = VariablePointers.fromList(seed_vars)
    );

    (sparsityPattern, _) := SparsityPattern.create(seedCandidates, partialCandidates, strongComponents, jacType);
    // 1) old partials -> new seeds
    i := 1;
    for oldC in sparsityPattern.partial_vars loop
      if i <= listLength(sparsityPattern.seed_vars) then
        newC := listGet(sparsityPattern.seed_vars, i);
        // (partner, _) := BVariable.getVarSeed(newVar);
        // newC := BVariable.getVarName(Util.getOption(partner));
        UnorderedMap.add(oldC, newC, mapPartialToNewSeed);
      end if;
      i := i + 1;
    end for;

    // print("Map original partials to new seeds:\n");
    // print(UnorderedMap.toString(mapPartialToNewSeed, ComponentRef.toString, ComponentRef.toString) + "\n");

    // 2) old seeds -> new pDers
    i := 1;
    for oldC in sparsityPattern.seed_vars loop
      if i <= listLength(sparsityPattern.partial_vars) then
        newC := listGet(sparsityPattern.partial_vars, i);
        // (partner, _) := BVariable.getVarPDer(newC);
        // newC := BVariable.getVarName(Util.getOption(partner));
        UnorderedMap.add(oldC, newC, mapSeedToNewPDer);
      end if;
      i := i + 1;
    end for;

    // print("Map original seeds to new pDers:\n");
    // print(UnorderedMap.toString(mapSeedToNewPDer, ComponentRef.toString, ComponentRef.toString) + "\n");

    (sparsityPattern, sparsityColoring) :=
      SparsityPattern.transposeRenamed(
        sparsityPattern,
        mapPartialToNewSeed,
        mapSeedToNewPDer,
        jacType
      );

    print(SparsityPattern.toString(sparsityPattern) + "\n" + SparsityColoring.toString(sparsityColoring) + "\n");

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = newName,
      jacType           = jacType,
      varData           = varDataJac,
      comps             = listArray(diffed_comps),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));


    for comp in diffed_comps loop
      print(NBStrongComponent.toString(comp) + "\n");
    end for;
  end jacobianSymbolicAdjoint;

  function jacobianNumeric "still creates sparsity pattern"
    extends Module.jacobianInterface;
  protected
    VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;
    list<Pointer<Variable>> res_vars, tmp_vars;
    BVariable.checkVar func = getTmpFilterFunction(jacType);
  algorithm
    (res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(init = init));

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList({}),
      unknowns      = partialCandidates,
      knowns        = VariablePointers.fromList({}),
      auxiliaries   = VariablePointers.fromList({}),
      aliasVars     = VariablePointers.fromList({}),
      diffVars      = VariablePointers.fromList({}),
      dependencies  = VariablePointers.fromList({}),
      resultVars    = VariablePointers.fromList(res_vars),
      tmpVars       = VariablePointers.fromList(tmp_vars),
      seedVars      = seedCandidates
    );

    (sparsityPattern, sparsityColoring) := SparsityPattern.create(seedCandidates, partialCandidates, strongComponents, jacType);

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = name,
      jacType           = jacType,
      varData           = varDataJac,
      comps             = listArray({}),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring
    ));
  end jacobianNumeric;

  function jacobianNone
    extends Module.jacobianInterface;
  algorithm
    jacobian := NONE();
  end jacobianNone;

  function getTmpFilterFunction
    " - ODE filter by state derivative / algebraic
      - LS/NLS/DAE filter by residual / inner"
    input JacobianType jacType;
    output BVariable.checkVar func;
  algorithm
    func := match jacType
      case JacobianType.ODE then BVariable.isStateDerivative;
      case JacobianType.DAE then BVariable.isResidual;
      case JacobianType.LS  then BVariable.isResidual;
      case JacobianType.NLS then BVariable.isResidual;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because jacobian type is not known: " + jacobianTypeString(jacType)});
      then fail();
    end match;
  end getTmpFilterFunction;

  function makeVarTraverse
    input Pointer<Variable> var_ptr;
    input String name;
    input Pointer<list<Pointer<Variable>>> vars_ptr;
    input UnorderedMap<ComponentRef,ComponentRef> map;
    input Func makeVar;
    input Boolean init;

    partial function Func
      input output ComponentRef cref;
      input String name;
      output Pointer<Variable> diff_ptr;
    end Func;
  protected
    Variable var = Pointer.access(var_ptr);
    ComponentRef diff, parent_name, diff_parent_name;
    Pointer<Variable> diff_ptr, parent, diff_parent;
  algorithm
    // only create seed or pDer var if it is continuous
    if BVariable.isContinuous(var_ptr, init) then
      // make the new differentiated variable itself
      (diff, diff_ptr) := makeVar(var.name, name);
      // add $<new>.x variable pointer to the variables
      Pointer.update(vars_ptr, diff_ptr :: Pointer.access(vars_ptr));
      // add x -> $<new>.x to the map for later lookup
      UnorderedMap.add(var.name, diff, map);

      // differentiate parent and add to map
      _ := match BVariable.getParent(var_ptr)
        case SOME(parent) algorithm
          parent_name := BVariable.getVarName(parent);
          diff_parent := match UnorderedMap.get(parent_name, map)
            case SOME(diff_parent_name) then BVariable.getVarPointer(diff_parent_name, sourceInfo());
            else algorithm
              (diff_parent_name, _) := makeVar(parent_name, name);
              UnorderedMap.add(parent_name, diff_parent_name, map);
            then BVariable.getVarPointer(diff_parent_name, sourceInfo());
          end match;

          // add the child to the list of children
          BVariable.addRecordChild(diff_parent, diff_ptr);
          // set the parent of the child
          diff_ptr := BVariable.setParent(diff_ptr, diff_parent);
        then ();

        else ();
      end match;
    end if;
  end makeVarTraverse;

  annotation(__OpenModelica_Interface="backend");
end NBJacobian;
