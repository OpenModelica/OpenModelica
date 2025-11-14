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
  import Subscript = NFSubscript;

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
  import Partition = NBPartition;
  import Replacements = NBReplacements;
  import Slice = NBSlice;
  import Sorting = NBSorting;
  import Causalize = NBCausalize;
  import StrongComponent = NBStrongComponent;
  import Tearing = NBTearing;
  import NFOperator.{MathClassification, SizeClassification};
  import NBVariable.{VariablePointers, VariablePointer, VarData};

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
        list<Partition.Partition> oldPartitions, newPartitions = {}               "Equation partitions before and afterwards";
        list<Partition.Partition> newEvents = {}, newAlg = {}, newAlgEvents = {}  "Event/Algebraic Equation partitions afterwards";

      case BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(knowns = knowns), funcTree = funcTree)
        algorithm
          (oldPartitions, name) := match kind
            case NBPartition.Kind.ODE then (bdae.ode, "ODE_JAC");
            case NBPartition.Kind.DAE then (Util.getOption(bdae.dae), "DAE_JAC");
            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Partition.Partition.kindToString(kind)});
            then fail();
          end match;

          if Flags.isSet(Flags.JAC_DUMP) then
            print(StringUtil.headline_1("[symjacdump] Creating symbolic Jacobians:") + "\n");
          end if;

          for part in listReverse(oldPartitions) loop
            (part, funcTree) := partJacobian(part, funcTree, knowns, name, func);
            newPartitions := part::newPartitions;
          end for;

          for part in listReverse(bdae.ode_event) loop
            (part, funcTree) := partJacobian(part, funcTree, knowns, name, func);
            newEvents := part::newEvents;
          end for;
          for part in listReverse(bdae.algebraic) loop
            (part, funcTree) := partJacobian(part, funcTree, knowns, name, func);
            newAlg := part::newAlg;
          end for;
          for part in listReverse(bdae.alg_event) loop
            (part, funcTree) := partJacobian(part, funcTree, knowns, name, func);
            newAlgEvents := part::newAlgEvents;
          end for;
          () := match kind
            case NBPartition.Kind.ODE algorithm bdae.ode := newPartitions; then ();
            case NBPartition.Kind.DAE algorithm bdae.dae := SOME(newPartitions); then ();
            else ();
          end match;
          bdae.ode_event := newEvents;
          bdae.algebraic := newAlg;
          bdae.alg_event := newAlgEvents;
          bdae.funcTree := funcTree;
      then bdae;

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + BackendDAE.toString(bdae)});
      then fail();

    end match;
  end main;

  function nonlinear
    input VariablePointers seedCandidates;
    input VariablePointers partialCandidates;
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
        seedCandidates    = seedCandidates,
        partialCandidates = partialCandidates,
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
        sparsityColoring  = sparsityColoring,
        isAdjoint         = if name == "ADJ" then true else false // this is maybe bad (e.g. when name changes)
      );
    end if;
  end combine;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.jacobianInterface func;
  algorithm
    func := match Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN)
      case "symbolic" then jacobianSymbolic;
      case "symbolicadjoint" then jacobianSymbolicAdjoint;
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

    // Pretty-print the bipartite adjacency map used during sparsity detection:
    // map[cref] -> list of neighbor crefs on the opposite side.
    function adjacencyMapToString
      input UnorderedMap<ComponentRef, list<ComponentRef>> map;
      output String s;
    protected
      list<ComponentRef> keys;
      ComponentRef k;
      list<ComponentRef> neighs;
      list<String> lines = {};
    algorithm
      keys := UnorderedMap.keyList(map);
      for k in keys loop
        neighs := UnorderedMap.getOrFail(k, map);
        lines := ("  " + ComponentRef.toString(k) + " -> " + ComponentRef.listToString(neighs)) :: lines;
      end for;
      lines := listReverse(lines);
      s := "Adjacency map (" + intString(listLength(keys)) + " keys):\n" + stringDelimitList(lines, "\n");
    end adjacencyMapToString;

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
      // sparsityColoring := SparsityColoring.PartialD2ColoringAlgColumnAndRow(sparsityPattern, map);

      if Flags.isSet(Flags.DUMP_SPARSE) then
        print(toString(sparsityPattern) + "\n" + SparsityColoring.toString(sparsityColoring) + "\n");
      end if;
    end create;

    function createEmpty
      output SparsityPattern sparsityPattern = EMPTY_SPARSITY_PATTERN;
      output SparsityColoring sparsityColoring = EMPTY_SPARSITY_COLORING;
    end createEmpty;
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
        str := str + "Column Color (" + intString(i) + ")\n"
          + "  - Column: " + ComponentRef.listToString(sparsityColoring.cols[i]) + "\n";
      end for;
      for i in 1:arrayLength(sparsityColoring.rows) loop
        str := str + "Row Color (" + intString(i) + ")\n"
          + "  - Row:    " + ComponentRef.listToString(sparsityColoring.rows[i]) + "\n";
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
      array<list<Integer>> cols, rows, colored_cols, colored_rows;
      array<SparsityColoringCol> cref_colored_cols, cref_colored_rows;
      function getIndices
        input ComponentRef cref;
        input UnorderedMap<ComponentRef, Integer> seed_indices;
        input UnorderedMap<ComponentRef, Integer> partial_indices;
        input array<list<Integer>> rows;
        output list<Integer> indices;
      algorithm
        if UnorderedMap.contains(cref, seed_indices) then
          indices := {UnorderedMap.getSafe(cref, seed_indices, sourceInfo())};
        elseif UnorderedMap.contains(cref, partial_indices) then
          indices := rows[UnorderedMap.getSafe(cref, partial_indices, sourceInfo())];
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref " + ComponentRef.toString(cref)
            + " is neither a seed nor a partial candidate!"});
          fail();
        end if;
      end getIndices;
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
        rows[UnorderedMap.getSafe(idx_cref, partial_indices, sourceInfo())] := listAppend(getIndices(dep, seed_indices, partial_indices, rows) for dep in deps);
      end for;

      // call C function (old backend - ToDo: port to new backend!)
      //colored_cols := SymbolicJacobian.createColoring(cols, rows, sizeRows, sizeCols);
      colored_cols := SymbolicJacobian.createColoring(rows, cols, sizeCols, sizeRows);
      // get cref based coloring
      cref_colored_cols := arrayCreate(arrayLength(colored_cols), {});
      for i in 1:arrayLength(colored_cols) loop
        cref_colored_cols[i] := list(seeds[idx] for idx in colored_cols[i]);
      end for;

      // THNK: is this correct? -> I think so
      // Row coloring (color partials)
      colored_rows := SymbolicJacobian.createColoring(cols, rows, sizeRows, sizeCols);
      cref_colored_rows := arrayCreate(arrayLength(colored_rows), {});
      for i in 1:arrayLength(colored_rows) loop
        cref_colored_rows[i] := list(partials[idx] for idx in colored_rows[i]);
      end for;

      //sparsityColoring := SPARSITY_COLORING(cref_colored_cols, arrayCreate(sizeRows, {}));
      sparsityColoring := SPARSITY_COLORING(cref_colored_cols, cref_colored_rows);
    end PartialD2ColoringAlgC;

    function PartialD2ColoringAlgColumnAndRow
      "author: fbrandt 2025-10
      taken from: 'What Color Is Your Jacobian? Graph Coloring for Computing Derivatives'
      https://doi.org/10.1137/S0036144504444711 (Algorithm 3.2)
      A greedy partial distance-2 coloring algorithm done twice to compute both column and row coloring."
      input SparsityPattern sparsityPattern;
      input UnorderedMap<ComponentRef, list<ComponentRef>> map;
      output SparsityColoring sparsityColoring;
    protected
      array<ComponentRef> seed_nodes, partial_nodes;
      list<SparsityColoringCol> col_groups = {};
      list<SparsityColoringRow> row_groups = {};
      Integer nCols, nRows, pad, k;
      array<SparsityColoringCol> cols_arr;
      array<SparsityColoringRow> rows_arr;
    algorithm
      // Nodes to color: seeds (columns) and partials (rows)
      seed_nodes := listArray(sparsityPattern.seed_vars);
      partial_nodes  := listArray(sparsityPattern.partial_vars);

      // Column coloring (seeds -> partials -> seeds)
      col_groups := GreedyPartialD2Color(seed_nodes, map);
      // Row coloring (partials -> seeds -> partials)
      row_groups := GreedyPartialD2Color(partial_nodes, map);
      // Build arrays for result
      cols_arr := listArray(col_groups);
      rows_arr := listArray(row_groups);

      sparsityColoring := SPARSITY_COLORING(cols_arr, rows_arr);
    end PartialD2ColoringAlgColumnAndRow;

    // Distance-2 greedy coloring on a bipartite graph represented by 'map':
    // Given a node set 'nodes' (either seeds or partials), assign colors so that
    // no two nodes at distance 2 (node -> opposite side -> node) share a color.
    // Returns the list of color groups in stable order.
    function GreedyPartialD2Color
      input array<ComponentRef> nodes;
      input UnorderedMap<ComponentRef, list<ComponentRef>> map;
      output list<list<ComponentRef>> groups_lst;
    protected
      UnorderedMap<ComponentRef, Integer> index_lookup;
      array<Integer> coloring, forbidden_colors;
      array<Boolean> color_exists;
      array<list<ComponentRef>> groups;
      Integer i, color, n = arrayLength(nodes);
      ComponentRef node, mid, neigh;
    algorithm
      // Build cref -> index lookup for the given nodes.
      index_lookup := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(n));
      for i in 1:n loop
        UnorderedMap.add(nodes[i], i, index_lookup);
      end for;

      // Init data structures
      coloring := arrayCreate(n, 0);
      forbidden_colors := arrayCreate(n, 0);
      color_exists := arrayCreate(n, false);
      groups := arrayCreate(n, {});

      // Greedy partial distance-2 coloring:
      // For node i, forbid colors of any already-colored neighbor at distance 2.
      for i in 1:n loop
        node := nodes[i];

        // Mark forbidden colors for neighbors at distance 2: node -> mid -> neigh
        for mid in UnorderedMap.getSafe(node, map, sourceInfo()) loop
          for neigh in UnorderedMap.getSafe(mid, map, sourceInfo()) loop
            color := coloring[UnorderedMap.getSafe(neigh, index_lookup, sourceInfo())];
            if color > 0 then
              forbidden_colors[color] := i;
            end if;
          end for;
        end for;

        // Pick smallest available color
        color := 1;
        while forbidden_colors[color] == i loop
          color := color + 1;
        end while;

        coloring[i] := color;
        color_exists[color] := true;
        groups[color] := node :: groups[color];
      end for;

      // Collect groups (reverse to keep stable order)
      groups_lst := {};
      for i in arrayLength(color_exists):-1:1 loop
        if color_exists[i] then
          groups_lst := groups[i] :: groups_lst;
        end if;
      end for;
    end GreedyPartialD2Color;

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
      cref_lookup := listArray(sparsityPattern.seed_vars); // x, y, z
      index_lookup := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(sparsityPattern.seed_vars)));
      for i in 1:arrayLength(cref_lookup) loop
        UnorderedMap.add(cref_lookup[i], i, index_lookup); // x->1, y->2, z->3
      end for;

      // create empty colorings
      coloring := arrayCreate(arrayLength(cref_lookup), 0);
      forbidden_colors := arrayCreate(arrayLength(cref_lookup), 0);
      color_exists := arrayCreate(arrayLength(cref_lookup), false);
      col_coloring := arrayCreate(arrayLength(cref_lookup), {});
      row_coloring := arrayCreate(arrayLength(cref_lookup), {});

      for i in 1:arrayLength(cref_lookup) loop
        // all neighbors w of v_i
        for row_var /* w */ in UnorderedMap.getSafe(cref_lookup[i], map, sourceInfo()) loop
          // all colored neighbors x of w
          for col_var /* x */ in UnorderedMap.getSafe(row_var, map, sourceInfo()) loop
            color := coloring[UnorderedMap.getSafe(col_var, index_lookup, sourceInfo())];
            if color > 0 then
              forbidden_colors[color] := i;
            end if;
          end for;
        end for;
        // assign the smallest available color to v_i
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
    Boolean updated;
  algorithm    
    // create algebraic loop jacobians
    part.strongComponents := match part.strongComponents
      local
        array<StrongComponent> comps;
        StrongComponent tmp;
      case SOME(comps) algorithm
        for i in 1:arrayLength(comps) loop
          (tmp, funcTree, updated) := compJacobian(comps[i], funcTree, kind);
          if updated then arrayUpdate(comps, i, tmp); end if;
        end for;
      then SOME(comps);
      else part.strongComponents;
    end match;

    // create the simulation jacobian
    if Partition.Partition.isODEorDAE(part) then
      partialCandidates := part.unknowns;
      unknowns  := if Partition.Partition.getKind(part) == NBPartition.Kind.DAE then Util.getOption(part.daeUnknowns) else part.unknowns;
      jacType   := if Partition.Partition.getKind(part) == NBPartition.Kind.DAE then JacobianType.DAE else JacobianType.ODE;

      derivative_vars := list(var for var guard(BVariable.isStateDerivative(var)) in VariablePointers.toList(unknowns));
      state_vars := list(Util.getOption(BVariable.getVarState(var)) for var in derivative_vars);
      seedCandidates := VariablePointers.fromList(state_vars, partialCandidates.scalarized);

      (jacobian, funcTree) := func(name, jacType, seedCandidates, partialCandidates, part.equations, knowns, part.strongComponents, funcTree, kind ==  NBPartition.Kind.INI);

      if Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN) == "symbolicadjoint" and Util.isSome(jacobian) then
        part.association := Partition.Association.CONTINUOUS(kind, NONE(), jacobian);
      else
        part.association := Partition.Association.CONTINUOUS(kind, jacobian, NONE());
      end if;
      if Flags.isSet(Flags.JAC_DUMP) then
        print(Partition.Partition.toString(part, 2));
      end if;
    end if;
  end partJacobian;

  function compJacobian
    input output StrongComponent comp;
    input output FunctionTree funcTree;
    input Partition.Kind kind;
    output Boolean updated;
  protected
    Tearing strict;
    list<StrongComponent> residual_comps;
    list<VariablePointer> seed_candidates, residual_vars, inner_vars;
    Option<Jacobian> jacobian;
    constant Boolean init = kind == NBPartition.Kind.INI;
  algorithm
    (comp, updated) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // create residual components
        residual_comps        := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in strict.residual_eqns);

        // create seed and partial candidates
        seed_candidates := list(Slice.getT(var) for var in strict.iteration_vars);
        residual_vars   := list(Equation.getResidualVar(Slice.getT(eqn)) for eqn in strict.residual_eqns);
        inner_vars      := listAppend(list(var for var guard(BVariable.isContinuous(var, init)) in StrongComponent.getVariables(comp)) for comp in strict.innerEquations);

        // update jacobian to take slices (just to have correct inner variables and such)
        (jacobian, funcTree) := nonlinear(
          seedCandidates    = VariablePointers.fromList(seed_candidates),
          partialCandidates = VariablePointers.fromList(listAppend(residual_vars, inner_vars)),
          equations         = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in strict.residual_eqns)),
          comps             = Array.appendList(strict.innerEquations, residual_comps),
          funcTree          = funcTree,
          name              = Partition.Partition.kindToString(kind) + (if comp.linear then "_LS_JAC_" else "_NLS_JAC_") + intString(comp.idx),
          init              = kind == NBPartition.Kind.INI);
        strict.jac := jacobian;
        comp.strict := strict;

        if Flags.isSet(Flags.JAC_DUMP) then
          print(StrongComponent.toString(comp) + "\n");
        end if;
      then (comp, true);
      else (comp, false);
    end match;
  end compJacobian;

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

    // // print strong components
    // print("Strong components for symbolic differentiation:\n");
    // print(jacobianTypeString(jacType) + "\n");
    // for c in comps loop
    //   print(StrongComponent.toString(c, 2) + "\n");
    // end for;

    // create seed vars
    VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, map = diff_map, makeVar = BVariable.makeSeedVar, init = init));

    // create pDer vars (also filters out discrete vars)
    (res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(init = init));
    print("tmp vars in symbolic:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(tmp_vars), "Tmp Vars") + "\n");

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
      sparsityColoring  = sparsityColoring,
      isAdjoint         = false
    ));
  end jacobianSymbolic;

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
      else if rnk == 2 then
        NFOperator.SizeClassification.MATRIX
      else 
        NFOperator.SizeClassification.ELEMENT_WISE;
  end sizeClassificationFromType;

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

    rhs := SimplifyExp.simplify(Expression.MULTARY(terms, {}, addOp));
    rhs := Expression.map(rhs, Expression.repairOperator);
  end buildAdjointRhs;

  function createAdjointEquation
    "Create an equation pointer for lhs = rhs.
     If rhs is an Expression.IF create an IF_EQUATION (with nested bodies).
     Otherwise fall back to standard makeAssignment (SCALAR/ARRAY/RECORD/FOR already handled there)."
    input Expression lhs;
    input Expression rhs;
    input Pointer<Integer> idx;
    input String contextName;
    input NBEquation.EquationAttributes attr;
    output Pointer<NBEquation.Equation> eqPtr;
  algorithm
    // print("Creating adjoint ASSIGNMENT for lhs = " + Expression.toString(lhs) + " with rhs = " + Expression.toString(rhs) + "\n");
    eqPtr := NBEquation.Equation.makeAssignment(
      lhs,
      rhs,
      idx,
      contextName,
      NBEquation.Iterator.EMPTY(),
      attr
    );
  end createAdjointEquation;

  // for saving terms for the same lhs in a map
  type ExpressionList = list<Expression>;
  // Add all variables in vars to the adjoint map with empty term lists if not already present.
  function addVarsToAdjointMap
    input output UnorderedMap<ComponentRef, ExpressionList> adjoint_map;
    input output list<Pointer<Variable>> vars;
    input String newName;
    input Boolean isTmp;
  protected
    ComponentRef baseCref;
  algorithm
    for v in vars loop
      baseCref := BVariable.getVarName(v);
      if not UnorderedMap.contains(baseCref, adjoint_map) then
        UnorderedMap.addNew(baseCref, {}, adjoint_map);
      end if;
    end for;
  end addVarsToAdjointMap;

  // Build processing order for adjoint equations:
  // - tmp_vars in reverse order (reverse-mode)
  // - res_vars in original order (order does not matter here)
  function buildAdjointProcessingOrder
    input UnorderedMap<ComponentRef, ExpressionList> adjoint_map;
    input list<Pointer<Variable>> res_vars;
    input list<Pointer<Variable>> tmp_vars;
    output list<ComponentRef> tmpKeys;
    output list<ComponentRef> resKeys;
  protected
    UnorderedSet<ComponentRef> seen = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    ComponentRef c;
    list<ComponentRef> tail = {};
    ExpressionList terms;
  algorithm
    tmpKeys := {};
    // reverse order of tmp vars
    for v in tmp_vars loop
      c := BVariable.getVarName(v);
      if UnorderedMap.contains(c, adjoint_map) then
        tmpKeys := c :: tmpKeys;
      end if;
    end for;

    // original order for result vars
    resKeys := {};
    for v in res_vars loop
      c := BVariable.getVarName(v);
      if UnorderedMap.contains(c, adjoint_map) then
        resKeys := c :: resKeys;
      end if;
    end for;
  end buildAdjointProcessingOrder;

  // Helper: run reverse-mode on a residual expression with a given seed (current_grad),
  // accumulating into the provided adjoint_map. Returns updated DifferentiationArguments.
  function accumulateAdjointForResidual
    input Expression residual;
    input Expression seed; // current_grad, typically a lambda_i cref
    input UnorderedMap<ComponentRef,ComponentRef> diff_map;
    input NFFlatten.FunctionTree funcTreeIn;
    input Boolean scalarized;
    input UnorderedMap<ComponentRef, ExpressionList> adjoint_map_in;
    output Differentiate.DifferentiationArguments diffArgumentsOut;
  protected
    Differentiate.DifferentiationArguments dargs;
    UnorderedMap<ComponentRef, ExpressionList> amap;
    NFFlatten.FunctionTree ft;
  algorithm
    // Prepare args to collect adjoints into the incoming map
    dargs := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),
      new_vars        = {},
      diff_map        = SOME(diff_map),
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcTree        = funcTreeIn,
      scalarized      = scalarized,
      adjoint_map     = SOME(adjoint_map_in),
      current_grad    = seed,
      collectAdjoints = true
    );

    // Run reverse-mode on the residual expression.
    (_, dargs) := NBDifferentiate.differentiateExpression(residual, dargs);

    diffArgumentsOut := dargs;
  end accumulateAdjointForResidual;

  // Reusable builder for a SINGLE_COMPONENT adjoint assignment (tmp or result var).
  function makeAdjointComponent
    input ComponentRef lhsKey;
    input UnorderedMap<ComponentRef, ExpressionList> adjoint_map;
    input String contextName;
    input Integer eqIndex;
    output NBStrongComponent diffed_comp;
  protected
    ExpressionList terms;
    Expression rhsExpr;
    Pointer<NBEquation.Equation> eqPtr;
    NBEquation.Equation eq;
    Pointer<Variable> lhsVarPtr;
  algorithm
    terms := UnorderedMap.getOrFail(lhsKey, adjoint_map);

    if listEmpty(terms) then
      rhsExpr := Expression.makeZero(ComponentRef.getComponentType(lhsKey));
    else
      rhsExpr := buildAdjointRhs(lhsKey, terms);
    end if;

    eqPtr := createAdjointEquation(
      Expression.fromCref(lhsKey),
      rhsExpr,
      Pointer.create(eqIndex),
      contextName,
      NBEquation.EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false)
    );

    lhsVarPtr := BVariable.getVarPointer(lhsKey, sourceInfo());
    eq := Pointer.access(eqPtr);

    diffed_comp := match eq
      local
        // helper: true if lhsKey carries any subscript (index/slice)
        Boolean lhsHasSubs = not listEmpty(ComponentRef.subscriptsAllFlat(lhsKey));
      case NBEquation.SCALAR_EQUATION() algorithm
        if lhsHasSubs then
          // Represent as a sliced component of size 1
          diffed_comp := NBStrongComponent.SLICED_COMPONENT(
            var_cref = lhsKey,                               // keep the subscripted cref for nice printing
            var      = Slice.SLICE(lhsVarPtr, {}),           // scalar element; indices not needed here
            eqn      = Slice.SLICE(eqPtr, {}),               // scalar equation
            status   = NBSolve.Status.EXPLICIT
          );
        else
          diffed_comp := NBStrongComponent.SINGLE_COMPONENT(
            var    = lhsVarPtr,
            eqn    = eqPtr,
            status = NBSolve.Status.EXPLICIT
          );
        end if;
      then diffed_comp;
      case NBEquation.ARRAY_EQUATION() then
        NBStrongComponent.SINGLE_COMPONENT(
          var    = lhsVarPtr,
          eqn    = eqPtr,
          status = NBSolve.Status.EXPLICIT
        );
      case NBEquation.RECORD_EQUATION() then
        NBStrongComponent.SINGLE_COMPONENT(
          var    = lhsVarPtr,
          eqn    = eqPtr,
          status = NBSolve.Status.EXPLICIT
        );
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " cannot create adjoint strong component for equation " + NBEquation.Equation.toString(eq)});
      then fail();
    end match;
  end makeAdjointComponent;

  function addEntryToLPAMap
    input Pointer<Variable> vptr;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
    input output UnorderedMap<ComponentRef, ExpressionList> loop_product_adjoint_map;
  protected
    ComponentRef vcref, mappedSeed;
  algorithm
    vcref := BVariable.getVarName(vptr);
    if UnorderedMap.contains(vcref, diff_map) then
      mappedSeed := UnorderedMap.getOrFail(vcref, diff_map);
      if not UnorderedMap.contains(mappedSeed, loop_product_adjoint_map) then
        UnorderedMap.add(mappedSeed, {}, loop_product_adjoint_map);
      end if;
    end if;
  end addEntryToLPAMap;

  // Build a filtered diff map for a given variable list.
  // For each variable pointer v in 'vars', if there exists a mapping
  //   base = BVariable.getVarName(v) -> mapped in 'globalDiffMap'
  // then add (base -> mapped) to the returned map.
  function populateDiffMap
    input list<NBVariable.VariablePointer> vars;
    input UnorderedMap<ComponentRef, ComponentRef> globalDiffMap;
    output UnorderedMap<ComponentRef, ComponentRef> outMap;
  protected
    ComponentRef baseCref, mappedCref;
    Integer n = listLength(vars);
  algorithm
    outMap := UnorderedMap.new<ComponentRef>(
      ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(n)
    );

    for vp in vars loop
      baseCref := BVariable.getVarName(vp);
      if UnorderedMap.contains(baseCref, globalDiffMap) then
        mappedCref := UnorderedMap.getOrFail(baseCref, globalDiffMap);
        UnorderedMap.add(baseCref, mappedCref, outMap);
      end if;
    end for;
  end populateDiffMap;

  // Collect all ComponentRefs used in an expression (shallow helper).
  function collectCrefsFromExpr
    input Expression exp;
    output list<ComponentRef> crefs;
  algorithm
    crefs := Expression.fold(exp, collectCrefsFold, {});
  end collectCrefsFromExpr;

  function collectCrefsFold
    input Expression e;
    input output list<ComponentRef> acc;
  algorithm
    () := match e
      case Expression.CREF(cref = _) algorithm
        acc := e.cref :: acc;
      then ();
      else ();
    end match;
  end collectCrefsFold;

  // True iff expr references any tmp var in tmpSet (excluding self).
  function exprDependsOnTmpVar
    input Expression expr;
    input UnorderedSet<ComponentRef> tmpSet;
    input ComponentRef self;
    output Boolean doesDepend = false;
  protected
    list<ComponentRef> deps;
  algorithm
    deps := collectCrefsFromExpr(expr);
    for c in deps loop
      if ComponentRef.isEqual(c, self) then
        // ignore self
      elseif UnorderedSet.contains(c, tmpSet) then
        doesDepend := true;
        return;
      end if;
    end for;
  end exprDependsOnTmpVar;

  // Partition tmpKeys into those whose RHS depends only on seeds (no tmp refs) and the rest.
  function partitionTmpBySeedFirst
    input list<ComponentRef> tmpKeys;
    input UnorderedMap<ComponentRef, ExpressionList> adjoint_map;
    output list<ComponentRef> seedOnlyFirst = {};
    output list<ComponentRef> rest = {};
  protected
    UnorderedSet<ComponentRef> tmpSet = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(tmpKeys)));
    list<Expression> terms;
    Expression rhs;
  algorithm
    for k in tmpKeys loop UnorderedSet.add(k, tmpSet); end for;

    for k in tmpKeys loop
      terms := UnorderedMap.getOrDefault(k, adjoint_map, {});
      rhs := buildAdjointRhs(k, terms);
      if exprDependsOnTmpVar(rhs, tmpSet, k) then
        rest := k :: rest;
      else
        seedOnlyFirst := k :: seedOnlyFirst;
      end if;
    end for;

    // keep original relative order
    seedOnlyFirst := listReverse(seedOnlyFirst);
    rest := listReverse(rest);
  end partitionTmpBySeedFirst;

  function jacobianSymbolicAdjoint extends Module.jacobianInterface;
  protected
    list<StrongComponent> comps, diffed_comps, comps_non_alg;
    StrongComponent diffed_comp, c_noalias;
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Integer> idx = Pointer.create(0);

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars, old_res_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;

    Integer i;
    String newName;
    ComponentRef newC;

    BVariable.checkVar func = getTmpFilterFunction(jacType);
    UnorderedMap<ComponentRef, ExpressionList> adjoint_map;
    ExpressionList terms, dF_in, dF_out;
    Expression rhsExpr;
    Pointer<Variable> lhsVarPtr;
    Pointer<NBEquation.Equation> eqPtr;
    NBEquation.Equation eq;

    UnorderedMap<ComponentRef, ComponentRef> mapPartialToNewSeed =
      UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedMap<ComponentRef, ComponentRef> mapSeedToNewPDer =
      UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    list<StrongComponent> pre_adjoint_comps = {};
    list<ComponentRef> tmpKeys;
    list<ComponentRef> resKeys;

    // added locals for causalization of tmp equations
    list<Pointer<Variable>> tmpVarPtrs_causal = {};
    list<Pointer<NBEquation.Equation>> tmpEqPtrs_causal = {};
    VariablePointers tmpVarsVP;
    EquationPointers tmpEqnsEP;
    Matching matchingTmp;
    list<StrongComponent> tmpComps, resComps;

    list<ComponentRef> tmpKeysSeedOnly, tmpKeysRest;
    list<StrongComponent> tmpCompsFirst = {}, tmpCompsRest = {};
  algorithm
    newName := name + "_ADJ";
    if Util.isSome(strongComponents) then
      comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(strongComponents));
      // only allow single components and algebraic loops
      for c in comps loop
        if not StrongComponent.isSingleComponent(c) and not StrongComponent.isAlgebraicLoop(c) then
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " only supports SINGLE_COMPONENT and ALGEBRAIC_LOOP!"});
          fail();
        end if;
      end for;
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed because no strong components were given!"});
      fail();
    end if;

    for c in comps loop
      print("start component:\n" + StrongComponent.toString(c) + "\n");
    end for;

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Seed candidates before pDer creation:\n" + BVariable.VariablePointers.toString(seedCandidates, "Seed Candidates") + "\n");
      print("Partial candidates before pDer creation:\n" + BVariable.VariablePointers.toString(partialCandidates, "Partial Candidates") + "\n");
    end if;

    // create seed vars
    for v in VariablePointers.toList(seedCandidates) loop makeVarTraverse(v, newName, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = false), init = init); end for;
    res_vars := Pointer.access(pDer_vars_ptr);

    // create pDer vars (also filters out discrete vars)
    (old_res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(init = init));

    for v in old_res_vars loop makeVarTraverse(v, newName, seed_vars_ptr, diff_map, BVariable.makeSeedVar, init = init); end for;
    seed_vars := Pointer.access(seed_vars_ptr);

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("seed vars after seed creation:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(seed_vars), "Seed Vars") + "\n");
      print("res vars after pDer creation:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(res_vars), "Res Vars") + "\n");
      print("tmp vars after pDer creation:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(tmp_vars), "Tmp Vars") + "\n");
    end if;

    pDer_vars_ptr := Pointer.create({});
    for v in tmp_vars loop makeVarTraverse(v, newName, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = true), init = init); end for;
    tmp_vars := Pointer.access(pDer_vars_ptr);

    // create adjoint map with seed vars and tmp vars as keys mapping to empty lists
    adjoint_map := UnorderedMap.new<ExpressionList>(ComponentRef.hash, ComponentRef.isEqual);
    addVarsToAdjointMap(adjoint_map, res_vars, newName, false);
    addVarsToAdjointMap(adjoint_map, tmp_vars, newName, true);

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Adjoint map before:\n" + adjointMapToString(SOME(adjoint_map)) + "\n");
      print("Diff map before:\n" + diffMapToString(diff_map) + "\n");
    end if;

    comps_non_alg := {};
    for c in comps loop
      c_noalias := StrongComponent.removeAlias(c);
      () := match c_noalias
        local
          // tearing data
          list<VariablePointer> itVarPtrs = {};
          list<Pointer<NBEquation.Equation>> resEqnPtrs = {};
          list<Expression> residuals = {};

          // reverse-mode lambda temporaries
          list<Pointer<Variable>> lambdaPtrs = {};
          list<ComponentRef>      lambdaCrefs = {};

          // misc
          Tearing tearing;
          Integer iRes;
          ExpressionList terms_x;
          Expression rhs_x;

          UnorderedMap<ComponentRef, ComponentRef> diff_map_y =
            UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
          // Map for inputs x only: base x -> $pDER_...(x)
          UnorderedMap<ComponentRef, ComponentRef> diff_map_x =
            UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, ComponentRef> diff_map_union =
            UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, ExpressionList> loop_product_adjoint_map =
            UnorderedMap.new<ExpressionList>(ComponentRef.hash, ComponentRef.isEqual);
          ComponentRef baseX, pDerX;
          list<Pointer<Variable>> seedPtrListX;

          list<Pointer<NBEquation.Equation>> linResEqnPtrs = {};
          list<Expression> terms_j;
          Expression lhs_j, rhs_j;
          Pointer<NBEquation.Equation> resid_j;
          ComponentRef ySeedCref;
          Operator addOp = Operator.fromClassification((MathClassification.ADDITION, SizeClassification.SCALAR), Type.REAL());
        case NBStrongComponent.ALGEBRAIC_LOOP(strict = tearing)
          algorithm
            // Collect iteration vars and residual equations
            itVarPtrs := Tearing.getIterationVars(tearing);
            resEqnPtrs := Tearing.getResidualEqns(tearing);

            // Extract residual expressions
            for ep in resEqnPtrs loop
              residuals := NBEquation.Equation.getResidualExp(Pointer.access(ep)) :: residuals;
            end for;
            residuals := listReverse(residuals);

            // Create scalar lambda_i temporaries (Real), referenced as seeds for reverse mode
            for iIdx in 1:listLength(residuals) loop
              // make an auxiliary scalar Real variable which will hold lambda_i
              (lhsVarPtr, newC) := BVariable.makeAuxVar(NBVariable.TEMPORARY_STR, Pointer.access(idx) + 1, Type.REAL(), false);
              Pointer.update(idx, Pointer.access(idx) + 1);
              (newC, lhsVarPtr) := BVariable.makePDerVar(newC, newName, isTmp = true);

              lambdaPtrs := lhsVarPtr :: lambdaPtrs;
              lambdaCrefs := newC :: lambdaCrefs;

              if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
                print("[adjoint] created lambda_" + intString(iIdx) + " = " + ComponentRef.toString(newC) + "\n");
              end if;
            end for;
            // keep 1..m order
            tmp_vars := List.append_reverse(lambdaPtrs, tmp_vars);
            lambdaPtrs := listReverse(lambdaPtrs);
            lambdaCrefs := listReverse(lambdaCrefs);

            // ===================== Unified accumulation =====================
              // Build filtered diff maps:
              //  - diff_map_y: base iteration var y -> $SEED(y)
              //  - diff_map_x: base input x       -> $pDER(x)
              // Combine both into diff_map_union and collect adjoints into loop_product_adjoint_map
            // diff_map_y: keep only iteration vars that have a $SEED mapping in the global diff_map
            diff_map_y := populateDiffMap(itVarPtrs, diff_map);
            
            // diff_map_x: keep only inputs x (seedCandidates) that have a $pDER mapping in the global diff_map
            seedPtrListX := BVariable.VariablePointers.toList(seedCandidates);
            diff_map_x := populateDiffMap(seedPtrListX, diff_map);

            // union/merge diff maps into diff_map_union
            diff_map_union := UnorderedMap.merge(diff_map_y, diff_map_x, sourceInfo());

            // Pre-populate loop_product_adjoint_map with all $SEED(y) keys
            for itVarPtr in itVarPtrs loop
              loop_product_adjoint_map := addEntryToLPAMap(itVarPtr, diff_map_y, loop_product_adjoint_map);
            end for;
            // ...and all $pDER(x) keys
            for seedVarPtr in seedPtrListX loop
              loop_product_adjoint_map := addEntryToLPAMap(seedVarPtr, diff_map_x, loop_product_adjoint_map);
            end for;

            // Accumulate reverse-mode adjoints per residual with seed = lambda_i into the unified map
            // we only need to process residuals 1..m with their corresponding lambda_i because everything is linear
            iRes := 1;
            for residual_i in residuals loop
              if iRes > listLength(lambdaCrefs) then
                break;
              end if;

              diffArguments := accumulateAdjointForResidual(
                residual_i,
                Expression.fromCref(listGet(lambdaCrefs, iRes)),  // current_grad = lambda_i
                diff_map_union,                                    // union: { y-> $SEED(y), x-> $pDER(x) }
                funcTree,
                seedCandidates.scalarized,
                loop_product_adjoint_map
              );

              // Thread state
              funcTree := diffArguments.funcTree;
              loop_product_adjoint_map := Util.getOption(diffArguments.adjoint_map);

              iRes := iRes + 1;
            end for;
            if Flags.isSet(Flags.DEBUG_DIFFERENTIATION) then
              print("[adjoint] loop_product_adjoint_map after: \n" + adjointMapToString(SOME(loop_product_adjoint_map)) + "\n");
            end if;


            // Build a linear algebraic loop for lambda: sum_i (d r_i / d y_j) * lambda_i = y_bar_j
            // For each iteration var y_j (in itVarPtrs order), create residual:
            //   LHS_j = sum(loop_product_adjoint_map[$SEED(y_j)]) ; residual_j = LHS_j - $SEED(y_j) = 0
            for vptr in itVarPtrs loop
              // Map base y to its seed cref (y_bar variable)
              if UnorderedMap.contains(BVariable.getVarName(vptr), diff_map_y) then
                ySeedCref := UnorderedMap.getOrFail(BVariable.getVarName(vptr), diff_map_y);

                // Get accumulated terms for this seed (may be empty)
                terms_j := UnorderedMap.getOrDefault(ySeedCref, loop_product_adjoint_map, {});

                // Build LHS as sum of terms (or 0 if empty)
                lhs_j := buildAdjointRhs(ySeedCref, terms_j);

                // RHS is the y_bar variable itself
                rhs_j := Expression.fromCref(ySeedCref);

                // Create assignment equation: lambda = lambda_vec
                resid_j := NBEquation.Equation.makeAssignment(
                  lhs_j,
                  rhs_j,
                  idx,
                  newName,
                  NBEquation.Iterator.EMPTY(),
                  NBEquation.EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false)
                );

                // Create scalar residual equation pointer for r_j = 0
                linResEqnPtrs := NBEquation.Equation.createResidual(resid_j) :: linResEqnPtrs;
              else
                // No mapping -> skip (nothing to solve for this y)
                continue;
              end if;
            end for;
            linResEqnPtrs := listReverse(linResEqnPtrs);

            // Wrap into a linear algebraic loop with lambda as iteration vars
            if not listEmpty(linResEqnPtrs) then
              pre_adjoint_comps := makeLinearAlgebraicLoop(
                lambdaPtrs,                  // iteration vars: lambda_1..m
                linResEqnPtrs,               // residuals: sum(...) - y_bar = 0
                NONE(),
                mixed = false,
                homotopy = false
              ) :: pre_adjoint_comps;
            end if;
            
            // -------------------------------------------------------------
            // Build x_bar = - lambda^T * (d r / d x)
            // Use the unified loop_product_adjoint_map:
            //   for each $pDER(x_k): terms_x = [dr1/dx_k*lambda_1, dr2/dx_k*lambda_2, ...]
            //   x_bar[k] = - sum(terms_x)
            // Append into global adjoint_map under the $pDER(x_k) keys.
            // -------------------------------------------------------------
            for seedVarPtrX in seedPtrListX loop
              baseX := BVariable.getVarName(seedVarPtrX);

              // If this base x has a $pDER mapping and collected terms, emit its equation
              if UnorderedMap.contains(baseX, diff_map_x) then
                pDerX := UnorderedMap.getOrFail(baseX, diff_map_x);

                terms_x := UnorderedMap.getOrDefault(pDerX, loop_product_adjoint_map, {});
                if listEmpty(terms_x) then
                  // no contributions -> skip
                  continue;
                end if;

                // Sum terms using correct type/operator for the LHS variable
                // and apply required minus sign
                rhs_x := Expression.negate(buildAdjointRhs(pDerX, terms_x));

                // Append to global adjoint_map so standard emission produces:
                //   $pDER_...x = - (sum_i lambda_i * d r_i / d x)
                UnorderedMap.add(
                  pDerX,
                  rhs_x :: UnorderedMap.getOrDefault(pDerX, adjoint_map, {}),
                  adjoint_map
                );
              end if;
            end for;
          then ();
        else algorithm
          // non-algebraic loop handled later
          comps_non_alg := c_noalias :: comps_non_alg;
        then ();
      end match;
    end for;
    // keep original order
    comps := listReverse(comps_non_alg);

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Adjoint map after loop adding:\n" + adjointMapToString(SOME(adjoint_map)) + "\n");
    end if;

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
      collectAdjoints = true
    );

    // differentiate all strong components
    (_, diffArguments) := Differentiate.differentiateStrongComponentListAdjoint(comps, diffArguments, idx, newName, getInstanceName());
    funcTree := diffArguments.funcTree;

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Adjoint map after differentiation:\n" + adjointMapToString(diffArguments.adjoint_map) + "\n");
    end if;

    adjoint_map := Util.getOption(diffArguments.adjoint_map);
    // New list of strong components replacing original diffed_comps
    diffed_comps := {};
    i := 1;
    (tmpKeys, resKeys) := buildAdjointProcessingOrder(adjoint_map, res_vars, tmp_vars);
    // 1. TMP VAR equations: simple heuristic ordering
    (tmpKeysSeedOnly, tmpKeysRest) := partitionTmpBySeedFirst(tmpKeys, adjoint_map);

    // Emit tmp vars that only depend on seeds first
    tmpCompsFirst := {};
    for lhsKey in tmpKeysSeedOnly loop
      diffed_comp := makeAdjointComponent(lhsKey, adjoint_map, newName, i);
      tmpCompsFirst := diffed_comp :: tmpCompsFirst;
      i := i + 1;
    end for;
    // no reversal needed as order does not matter?

    // Emit remaining tmp vars afterwards
    tmpCompsRest := {};
    for lhsKey in tmpKeysRest loop
      diffed_comp := makeAdjointComponent(lhsKey, adjoint_map, newName, i);
      tmpCompsRest := diffed_comp :: tmpCompsRest;
      i := i + 1;
    end for;
    // THNK: is this enough to ensure correct execution order?
    tmpCompsRest := listReverse(tmpCompsRest);

    // 3. RESULT VAR equations
    resComps := {};
    for lhsKey in resKeys loop
      diffed_comp := makeAdjointComponent(lhsKey, adjoint_map, newName, i);
      resComps := diffed_comp :: resComps;
      i := i + 1;
    end for;
    // no reversal needed as order does not matter?

    // here are also the loop components from above which might be empty though if there are none
    diffed_comps := listAppend(listAppend(tmpCompsFirst, tmpCompsRest), listAppend(pre_adjoint_comps, resComps));

    // for c in diffed_comps loop
    //   print("Diffed component:\n" + StrongComponent.toString(c) + "\n");
    // end for;

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

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Adjoint sparsity pattern and coloring:\n");
      print(SparsityPattern.toString(sparsityPattern) + "\n" + SparsityColoring.toString(sparsityColoring) + "\n");
    end if;

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = newName,
      jacType           = jacType,
      varData           = varDataJac,
      comps             = listArray(diffed_comps),
      sparsityPattern   = sparsityPattern,
      sparsityColoring  = sparsityColoring,
      isAdjoint         = true
    ));
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
      sparsityColoring  = sparsityColoring,
      isAdjoint         = false
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
    str := "{\n  " + stringDelimitList(entries, "\n  ") + " \n}";
  end adjointMapToString;

  function diffMapToString
    input UnorderedMap<ComponentRef, ComponentRef> map;
    output String s;
  protected
    list<ComponentRef> keys;
    ComponentRef k, v;
  algorithm
    keys := UnorderedMap.keyList(map);
    s := "{\n";
    for k in keys loop
      v := UnorderedMap.getOrFail(k, map);
      s := s + "  " + ComponentRef.toString(k) + " -> " + ComponentRef.toString(v) + "\n";
    end for;
    s := s + "}";
  end diffMapToString;

  // Local helper to index a 1-based vector expression
  function makeIndex
    input Integer k;
    input Expression lambda_vec;
    output Expression idxExpr;
  algorithm
    idxExpr := Expression.applySubscripts(
      {Subscript.INDEX(Expression.INTEGER(k))},
      lambda_vec,
      true
    );
  end makeIndex;

  function makeLinearAlgebraicLoop
    input list<NBVariable.VariablePointer> itVarPtrs;           // unknowns y (order = columns of A)
    input list<Pointer<NBEquation.Equation>> resEqnPtrs;        // residuals r_i(y)=0, same order as rows of A
    input Option<NBackendDAE> jac = NONE();                     // optional analytic Jacobian for A
    input Boolean mixed = false;
    input Boolean homotopy = false;
    output NBStrongComponent comp;
  protected
    Integer m1 = listLength(itVarPtrs);
    Integer m2 = listLength(resEqnPtrs);
    list<NBSlice.Slice<NBVariable.VariablePointer>> itVars_s;
    list<NBSlice.Slice<Pointer<NBEquation.Equation>>> res_s;
    NBTearing.Tearing tearingSet;
  algorithm
    // sanity
    if m1 <> m2 then
      Error.addMessage(Error.INTERNAL_ERROR, {"makeLinearAlgebraicLoop: |vars| != |eqns|"});
      fail();
    end if;

    // wrap as full slices (keep order)
    itVars_s := list(NBSlice.SLICE(vp, {}) for vp in itVarPtrs);
    res_s    := list(NBSlice.SLICE(ep, {}) for ep in resEqnPtrs);

    // strict tearing: no inner equations for a plain linear system
    tearingSet := NBTearing.TEARING_SET(
      iteration_vars = itVars_s,
      residual_eqns  = res_s,
      innerEquations = listArray({}),
      jac            = jac
    );

    // mark as linear algebraic loop
    comp := NBStrongComponent.ALGEBRAIC_LOOP(
      idx      = -1,
      strict   = tearingSet,
      casual   = NONE(),
      linear   = true,
      mixed    = mixed,
      homotopy = homotopy,
      status   = NBSolve.Status.IMPLICIT
    );
  end makeLinearAlgebraicLoop;

  annotation(__OpenModelica_Interface="backend");
end NBJacobian;
