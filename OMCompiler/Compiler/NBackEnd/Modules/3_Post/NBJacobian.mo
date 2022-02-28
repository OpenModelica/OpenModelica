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
  type JacobianType = enumeration(SIMULATION, NONLINEAR);

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

          if Flags.isSet(Flags.JAC_DUMP) then
            print(StringUtil.headline_1("[symjacdump] Creating symbolic Jacobians:") + "\n");
          end if;

          for syst in listReverse(oldSystems) loop
            (syst, funcTree) := systJacobian(syst, funcTree, knowns, name, func);
            newEvents := syst::newEvents;
          end for;

          for syst in listReverse(oldEvents) loop
            (syst, funcTree) := systJacobian(syst, funcTree, knowns, name, func);
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

  function nonlinear
    input VariablePointers variables;
    input EquationPointers equations;
    input array<StrongComponent> comps;
    output Option<Jacobian> jacobian;
    input output FunctionTree funcTree;
    input String name;
  algorithm
    (jacobian, funcTree) := jacobianSymbolic(
        name              = name,
        jacType           = JacobianType.NONLINEAR,
        seedCandidates    = variables,
        partialCandidates = EquationPointers.getResiduals(equations),      // these have to be updated once there are inner equations in torn systems
        equations         = equations,
        knowns            = VariablePointers.empty(0),      // remove them? are they necessary?
        strongComponents  = SOME(comps),
        funcTree          = funcTree
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
    list<Pointer<Equation>> equations = {}, results = {}, temporary = {}, auxiliaries= {}, removed = {};
    list<SparsityPatternCol> col_wise_pattern = {};
    list<SparsityPatternRow> row_wise_pattern = {};
    list<ComponentRef> seed_vars = {};
    list<ComponentRef> partial_vars = {};
    Integer nnz = 0;
    VarData varData;
    EqData eqData;
    SparsityPattern sparsityPattern;
    list<list<ComponentRef>> sparsityColoring = {};
  algorithm

    if listLength(jacobians) == 1 then
      jacobian := List.first(jacobians);
      jacobian := match jacobian case BackendDAE.JACOBIAN() algorithm jacobian.name := name; then jacobian; end match;
    else
      for jac in jacobians loop
        _ := match jac
          local
            VarData tmpVarData;
            EqData tmpEqData;
            SparsityPattern tmpPattern;
            Integer size1, size2;
            list<list<ComponentRef>> coloring1, coloring2;

          case BackendDAE.JACOBIAN(varData = tmpVarData as VarData.VAR_DATA_JAC(), eqData = tmpEqData as EqData.EQ_DATA_JAC(), sparsityPattern = tmpPattern) algorithm
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

            equations     := listAppend(EquationPointers.toList(tmpEqData.equations), equations);
            results       := listAppend(EquationPointers.toList(tmpEqData.results), results);
            temporary     := listAppend(EquationPointers.toList(tmpEqData.temporary), temporary);
            auxiliaries   := listAppend(EquationPointers.toList(tmpEqData.auxiliaries), auxiliaries);
            removed       := listAppend(EquationPointers.toList(tmpEqData.removed), removed);

            col_wise_pattern  := listAppend(tmpPattern.col_wise_pattern, col_wise_pattern);
            row_wise_pattern  := listAppend(tmpPattern.row_wise_pattern, row_wise_pattern);
            seed_vars         := listAppend(tmpPattern.seed_vars, seed_vars);
            partial_vars      := listAppend(tmpPattern.partial_vars, partial_vars);
            nnz               := nnz + tmpPattern.nnz;

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
        seed_vars         = seed_vars,
        partial_vars      = partial_vars,
        nnz               = nnz
      );

      jacobian := BackendDAE.JACOBIAN(
        name              = name,
        jacType           = jacType,
        varData           = varData,
        eqData            = eqData,
        sparsityPattern   = sparsityPattern,
        sparsityColoring  = sparsityColoring
      );
    end if;
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
    input Boolean compact = true;
  algorithm
    if not compact then
      str := BackendDAE.toString(jacobian, str);
    else
      str := match jacobian
        case BackendDAE.JACOBIAN() then StringUtil.headline_2(jacobianTypeString(jacobian.jacType) + " Jacobian " + jacobian.name + ": " + str)
                                        + "\n" + BEquation.EqData.toString(jacobian.eqData, 1)
                                        + "\n" + SparsityPattern.toString(jacobian.sparsityPattern, jacobian.sparsityColoring);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
        then fail();
      end match;
    end if;
  end toString;

  function jacobianTypeString
    input JacobianType jacType;
    output String str;
  algorithm
    str := match jacType
      case JacobianType.SIMULATION  then "[SIM]";
      case JacobianType.NONLINEAR   then "[NLS]";
                                    else "[ERR]";
    end match;
  end jacobianTypeString;

  type SparsityPatternCol = tuple<ComponentRef, list<ComponentRef>> "residual, {independents}";
  type SparsityPatternRow = SparsityPatternCol                      "independent, {residuals}";

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
      input SparsityColoring coloring;
      output String str = StringUtil.headline_2("Sparsity Pattern (nnz: " + intString(pattern.nnz) + ")");
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
      Boolean colEmpty = listEmpty(pattern.col_wise_pattern);
      Boolean rowEmpty = listEmpty(pattern.row_wise_pattern);
    algorithm
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
      if colEmpty and rowEmpty then
        str := str + "\n<empty sparsity pattern>\n";
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
      input VariablePointers seedCandidates;
      input VariablePointers partialCandidates;
      input Option<array<StrongComponent>> strongComponents "Strong Components";
      input JacobianType jacType;
      output SparsityPattern sparsityPattern;
      output SparsityColoring sparsityColoring;
    algorithm
      sparsityPattern := match strongComponents
        local
          array<StrongComponent> comps;
          list<ComponentRef> seed_vars, partial_vars, tmp;
          UnorderedMap<ComponentRef, list<ComponentRef>> map;
          list<SparsityPatternCol> cols = {};
          list<SparsityPatternRow> rows = {};
          Integer nnz = 0;

        case SOME(comps) guard(arrayEmpty(comps)) algorithm
        then EMPTY_SPARSITY_PATTERN;

        case SOME(comps) algorithm
          // get all relevant crefs
          partial_vars := VariablePointers.getVarNames(partialCandidates);
          seed_vars := VariablePointers.getVarNames(seedCandidates);

          // create a sufficiant big unordered map
          map := UnorderedMap.new<CrefLst>(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(seed_vars) + listLength(partial_vars)));

          // save all relevant crefs to know later on if a cref should be added
          for cref in seed_vars loop
            UnorderedMap.add(cref, {}, map);
          end for;

          // traverse all components and save cref dependencies (only column-wise)
          for i in 1:arrayLength(comps) loop
            StrongComponent.getDependentCrefs(comps[i], map, not partialCandidates.scalarized, jacType);
          end for;

          // create row-wise sparsity pattern
          for cref in partial_vars loop
            // only create rows for derivatives
            if jacType == JacobianType.NONLINEAR or BVariable.checkCref(cref, BVariable.isStateDerivative) then
              if UnorderedMap.contains(cref, map) then
                tmp := List.uniqueOnTrue(UnorderedMap.getSafe(cref, map), ComponentRef.isEqual);
                rows := (cref, tmp) :: rows;
                for dep in tmp loop
                  // also add inverse dependency (indep var) --> (res/tmp) :: rest
                  UnorderedMap.add(dep, cref :: UnorderedMap.getSafe(dep, map), map);
                end for;
              end if;
            end if;
          end for;

          // create column-wise sparsity pattern
          for cref in seed_vars loop
            tmp := List.uniqueOnTrue(UnorderedMap.getSafe(cref, map), ComponentRef.isEqual);
            cols := (cref, tmp) :: cols;
          end for;

          // find number of nonzero elements
          for col in cols loop
            (_, tmp) := col;
            nnz := nnz + listLength(tmp);
          end for;
        then SPARSITY_PATTERN(cols, rows, seed_vars, partial_vars, nnz);

        case NONE() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of missing strong components."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();

      end match;

      // create coloring
      sparsityColoring := createEmptyColoring(sparsityPattern);

      if Flags.isSet(Flags.DUMP_SPARSE) then
        print(toString(sparsityPattern, sparsityColoring));
      end if;
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
      sparsityColoring := list({cref} for cref in sparsityPattern.seed_vars);
    end createEmptyColoring;

  end SparsityPattern;

  constant SparsityPattern EMPTY_SPARSITY_PATTERN = SPARSITY_PATTERN({}, {}, {}, {}, 0);
  type SparsityColoring = list<list<ComponentRef>>  "list of independent variable groups belonging to the same color";

protected
  // ToDo: all the DAEMode stuff is probably incorrect!

  function systJacobian
    input output System.System syst;
    input output FunctionTree funcTree;
    input VariablePointers knowns;
    input String name                                     "Context name for jacobian";
    input Module.jacobianInterface func;
  protected
    list<Pointer<Variable>> derivative_vars, state_vars;
    VariablePointers seedCandidates, partialCandidates;
    Option<Jacobian> jacobian                             "Resulting jacobian";
  algorithm
    partialCandidates := syst.unknowns;
    derivative_vars := list(var for var guard(BVariable.isStateDerivative(var)) in VariablePointers.toList(syst.unknowns));
    state_vars := list(BVariable.getStateVar(var) for var in derivative_vars);
    seedCandidates := VariablePointers.fromList(state_vars, partialCandidates.scalarized);
    (jacobian, funcTree) := func(name, JacobianType.SIMULATION, seedCandidates, partialCandidates, syst.equations, knowns, syst.strongComponents, funcTree);
    syst.jacobian := jacobian;
    if Flags.isSet(Flags.JAC_DUMP) then
      print(System.System.toString(syst, 2));
    end if;
  end systJacobian;

  function jacobianSymbolic extends Module.jacobianInterface;
  protected
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    Pointer<UnorderedMap<ComponentRef,ComponentRef>> jacobianHT = Pointer.create(UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual));
    Option<UnorderedMap<ComponentRef,ComponentRef>> optHT;
    Differentiate.DifferentiationArguments diffArguments;

    list<Pointer<Equation>> eqn_lst, diffed_eqn_lst;
    EquationPointers diffedEquations;
    BEquation.EqData eqDataJac;
    Pointer<Integer> idx = Pointer.create(0);

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars;
    BVariable.VarData varDataJac;
    SparsityPattern sparsityPattern;
    SparsityColoring sparsityColoring;

  algorithm
    // ToDo: apply tearing to split residual/inner variables and equations
    // add inner / tmp cref tuples to HT
    //(seedCandidates, partialCandidates) := if isSome(daeUnknowns) then (Util.getOption(daeUnknowns), unknowns) else (unknowns, VariablePointers.empty());

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
      diffedFunctions = AvlSetPath.new(),
      scalarized      = seedCandidates.scalarized
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
    Pointer<Integer> idx = Pointer.create(0);
  algorithm
    (sparsityPattern, sparsityColoring) := SparsityPattern.create(seedCandidates, partialCandidates, strongComponents, jacType);

    jacobian := SOME(Jacobian.JACOBIAN(
      name              = name,
      jacType           = jacType,
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
