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
  import NBEquation;
  import NBVariable;

protected
  // OF imports
  import Absyn.Path;
  import DAE;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Algorithm = NFAlgorithm;
  import Expression = NFExpression;
  import NFFunction.Function;
  import Statement = NFStatement;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;
  import NFInstNode.InstNode;

  // Backend imports
  import NFBackendExtension.BackendInfo;
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
  import StrongComponent = NBStrongComponent;
  import Tearing = NBTearing;
  import NFOperator.{MathClassification, SizeClassification};
  import NBVariable.{VariablePointer, VariablePointers, VarData};

  // Sparsity-pattern graph coloring, shared with the old backend.
  import Coloring;

  // Util imports
  import StringUtil;
  import UnorderedMap;
  import UnorderedSet;
  import Util;

public
  type JacobianType = enumeration(ODE, DAE, LS, NLS, OPT_LFG, OPT_MRF, OPT_R0);

  function isDynamic
    "is the jacobian used for integration (-> true)
     or solving algebraic systems (-> false)?"
    input JacobianType jacType;
    output Boolean b;
  algorithm
    b := match jacType
      case JacobianType.ODE     then true;
      case JacobianType.DAE     then true;
      case JacobianType.OPT_LFG then true;
      case JacobianType.OPT_MRF then true;
      case JacobianType.OPT_R0  then true;
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
        String name             "Context name for jacobian";
        VariablePointers knowns "Variable array of knowns";

      case BackendDAE.MAIN(varData = BVariable.VAR_DATA_SIM(knowns = knowns))
        algorithm
          if Flags.isSet(Flags.JAC_DUMP) then
            print(StringUtil.headline_1("[symjacdump] Creating symbolic Jacobians:") + "\n");
          end if;

          name := match kind
            case NBPartition.Kind.ODE algorithm
              name := "ODE_JAC";
              bdae.ode := applyToPartitions(bdae.ode, bdae.funcMap, knowns, name, func);
            then name;
            case NBPartition.Kind.DAE algorithm
              name := "DAE_JAC";
              bdae.dae := SOME(applyToPartitions(Util.getOption(bdae.dae), bdae.funcMap, knowns, name, func));
            then name;
            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + Partition.Partition.kindToString(kind)});
            then fail();
          end match;

          bdae.ode_event := applyToPartitions(bdae.ode_event, bdae.funcMap, knowns, name, func);
          bdae.algebraic := applyToPartitions(bdae.algebraic, bdae.funcMap, knowns, name, func);
          bdae.alg_event := applyToPartitions(bdae.alg_event, bdae.funcMap, knowns, name, func);
          bdae.init := applyToPartitions(bdae.init, bdae.funcMap, knowns, name, func);
          if isSome(bdae.init_0) then
            bdae.init_0 := SOME(applyToPartitions(Util.getOption(bdae.init_0), bdae.funcMap, knowns, name, func));
          end if;
      then bdae;

      else algorithm
        // maybe add failtrace here and allow failing
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for: " + BackendDAE.toString(bdae)});
      then fail();

    end match;
  end main;

  function applyToPartitions
    input output list<Partition.Partition> partitions;
    input output UnorderedMap<Path, Function> funcMap;
    input VariablePointers knowns;
    input String name;
    input Module.jacobianInterface func;
  algorithm
    partitions := list(partJacobian(part, funcMap, knowns, name, func) for part in partitions);
  end applyToPartitions;

  function nonlinear
    input VariablePointers seedCandidates;
    input VariablePointers partialCandidates;
    input EquationPointers equations;
    input array<StrongComponent> comps;
    input Option<Adjacency.Matrix> full;
    input UnorderedMap<Path, Function> funcMap;
    input String name;
    input Boolean staticAsContinuous;
    output Option<Jacobian> jacobian;
  protected
    constant Module.jacobianInterface func = if Flags.isSet(Flags.NLS_ANALYTIC_JACOBIAN)
      then jacobianSymbolic
      else jacobianNumeric;
  algorithm
    jacobian := func(
        name                = name,
        jacType             = JacobianType.NLS,
        seedCandidates      = seedCandidates,
        partialCandidates   = partialCandidates,
        equations           = equations,
        strongComponents    = SOME(comps),
        full                = full,
        funcMap             = funcMap,
        staticAsContinuous  = staticAsContinuous
      );
  end nonlinear;

  function combine
    input list<BackendDAE> jacobians;
    input String name;
    output BackendDAE jacobian;
  protected
    JacobianType jacType = JacobianType.NLS;
    list<Pointer<Variable>> variables = {}, unknowns = {}, auxiliaryVars = {}, aliasVars = {};
    list<Pointer<Variable>> diffVars = {}, dependencies = {}, resultVars = {}, tmpVars = {}, seedVars = {};
    list<StrongComponent> comps = {};
    list<Adjacency.Matrix> sparsity_patterns = {};
    VarData varData;
  algorithm
    if List.hasOneElement(jacobians) then
      jacobian := listHead(jacobians);
      jacobian := match jacobian case BackendDAE.JACOBIAN() algorithm
          jacobian.name := name;
        then jacobian;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + BackendDAE.toString(jacobian)});
        then fail();
      end match;
    else
      for jac in jacobians loop
        () := match jac
          local
            VarData tmpVarData;

          case BackendDAE.JACOBIAN(varData = tmpVarData as VarData.VAR_DATA_JAC()) algorithm
            jacType       := jac.jacType;
            variables     := listAppend(VariablePointers.toList(tmpVarData.variables), variables);
            unknowns      := listAppend(VariablePointers.toList(tmpVarData.unknowns), unknowns);
            auxiliaryVars := listAppend(VariablePointers.toList(tmpVarData.auxiliaries), auxiliaryVars);
            aliasVars     := listAppend(VariablePointers.toList(tmpVarData.aliasVars), aliasVars);
            diffVars      := listAppend(VariablePointers.toList(tmpVarData.diffVars), diffVars);
            dependencies  := listAppend(VariablePointers.toList(tmpVarData.dependencies), dependencies);
            resultVars    := listAppend(VariablePointers.toList(tmpVarData.resultVars), resultVars);
            tmpVars       := listAppend(VariablePointers.toList(tmpVarData.tmpVars), tmpVars);
            seedVars      := listAppend(VariablePointers.toList(tmpVarData.seedVars), seedVars);
            comps         := listAppend(arrayList(jac.comps), comps);
            sparsity_patterns := jac.sparsity :: sparsity_patterns;
          then ();

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for\n" + BackendDAE.toString(jac)});
          then fail();
        end match;
      end for;

      varData := VarData.VAR_DATA_JAC(
        variables     = VariablePointers.fromList(variables),
        unknowns      = VariablePointers.fromList(unknowns),
        auxiliaries   = VariablePointers.fromList(auxiliaryVars),
        aliasVars     = VariablePointers.fromList(aliasVars),
        diffVars      = VariablePointers.fromList(diffVars),
        dependencies  = VariablePointers.fromList(dependencies),
        resultVars    = VariablePointers.fromList(resultVars),
        tmpVars       = VariablePointers.fromList(tmpVars),
        seedVars      = VariablePointers.fromList(seedVars)
      );

      jacobian := BackendDAE.JACOBIAN(
        name      = name,
        jacType   = jacType,
        varData   = varData,
        comps     = listArray(comps),
        sparsity  = Adjacency.Matrix.combine(sparsity_patterns),
        isAdjoint = name == "ADJ" // this is maybe bad (e.g. when name changes)
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
      case "bidirectional" then jacobianSymbolic;
      case "numeric"  then jacobianNumeric;
      case "none"     then jacobianNone;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown jacobian type: " + Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN)});
      then fail();
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
      case JacobianType.ODE     then "[ODE]";
      case JacobianType.DAE     then "[DAE]";
      case JacobianType.LS      then "[LS-]";
      case JacobianType.NLS     then "[NLS]";
      case JacobianType.OPT_LFG then "[OPT-LFG]";
      case JacobianType.OPT_MRF then "[OPT-MRF]";
      case JacobianType.OPT_R0  then "[OPT-R0]";
                                else "[ERR]";
    end match;
  end jacobianTypeString;


protected
  // ToDo: all the DAEMode stuff is probably incorrect!

  // TODO: refactor with map
  function getOptimizableVars
    input VariablePointers variables;
    output list<Pointer<Variable>> optimizable_vars = {};
  algorithm
    for var_ptr in VariablePointers.toList(variables) loop
      if BVariable.isOptimizable(var_ptr) then
        optimizable_vars := var_ptr :: optimizable_vars;
      end if;
    end for;
  end getOptimizableVars;

  function getSeedCandidatesDynamicOptimization
    input Partition.Partition part;
    input VariablePointers all_knowns;
    input BVariable.checkVar filter;
    output list<Pointer<Variable>> unknowns;
  protected
    list<Pointer<Variable>> derivative_vars, unknown_states;
  algorithm
    // we could absorb the filter into getOptimizableVars as its faster
    unknowns := getOptimizableVars(all_knowns); // all optimizable inputs + parameters
    derivative_vars := list(var for var guard(BVariable.isStateDerivative(var)) in VariablePointers.toList(part.unknowns));
    unknown_states := list(Util.getOption(BVariable.getVarState(var)) for var in derivative_vars); // all states
    unknowns := listAppend(unknown_states, unknowns); // all states, inputs and parameters (optimizable)
    unknowns := List.filterOnTrue(unknowns, filter);
    // sort?
  end getSeedCandidatesDynamicOptimization;

  function getLfgPartialCandidates
    input Partition.Partition part;
    output list<Pointer<Variable>> partialCandidates;
  protected
    list<Pointer<Variable>> lagrange_vars = {}, derivative_vars = {}, path_vars = {};
  algorithm
    for var_ptr in VariablePointers.toList(part.unknowns) loop
      if BVariable.isLagrange(var_ptr) then
        lagrange_vars := var_ptr :: lagrange_vars;
      elseif BVariable.isStateDerivative(var_ptr) then
        derivative_vars := var_ptr :: derivative_vars;
      elseif BVariable.isPathConstraint(var_ptr) then
        path_vars := var_ptr :: path_vars;
      end if;
    end for;
    partialCandidates := listReverse(listAppend(lagrange_vars, listAppend(derivative_vars, path_vars)));
  end getLfgPartialCandidates;

  function getMrfPartialCandidates
    input Partition.Partition part;
    output list<Pointer<Variable>> partialCandidates;
  protected
    list<Pointer<Variable>> mayer_vars = {}, final_vars = {};
  algorithm
    for var_ptr in VariablePointers.toList(part.unknowns) loop
      if BVariable.isMayer(var_ptr) then
        mayer_vars := var_ptr :: mayer_vars;
      elseif BVariable.isFinalConstraint(var_ptr) then
        final_vars := var_ptr :: final_vars;
      end if;
    end for;
    partialCandidates := listReverse(listAppend(mayer_vars, final_vars));
  end getMrfPartialCandidates;

  function getR0PartialCandidates
    input Partition.Partition part;
    output list<Pointer<Variable>> partialCandidates = {};
  algorithm
    for var_ptr in VariablePointers.toList(part.unknowns) loop
      if BVariable.isInitialConstraint(var_ptr) then
        partialCandidates := var_ptr :: partialCandidates;
      end if;
    end for;
    partialCandidates := listReverse(partialCandidates);
  end getR0PartialCandidates;

  // TODO: before this is ever called, we should check if the variable / annotation pairs are even valid: e.g. path constraint with final time or so!
  // add a module for optimization? where we check the model, may do some transformations etc?
  function partJacobianDynamicOptimization
    input Partition.Partition part;
    input VariablePointers all_knowns;
    input String name;
    input Module.jacobianInterface func;
    input UnorderedMap<Path, Function> funcMap;
    output Option<Jacobian> LFG_jacobian;
    output Option<Jacobian> MRF_jacobian;
    output Option<Jacobian> R0_jacobian;
  protected
    Boolean staticAsContinuous = true;
    VariablePointers seedCandidates, partialCandidates;
  algorithm
    // Lfg Jacobian (Lagrange (L), ODE (f), Path Constraints (g)), append all unkowns of partition, as we might need their partials for inner
    partialCandidates := VariablePointers.fromList(listAppend(getLfgPartialCandidates(part), VariablePointers.toList(part.unknowns)), part.unknowns.scalarized);
    seedCandidates := VariablePointers.fromList(getSeedCandidatesDynamicOptimization(part, all_knowns, BVariable.isLfgVariable), partialCandidates.scalarized);

    // TODO: add _OPT to name?
    LFG_jacobian := func(name, JacobianType.OPT_LFG, seedCandidates, partialCandidates,
                         part.equations, part.strongComponents, part.adjacencyMatrix, funcMap, staticAsContinuous);

    // Mrf Jacobian (Mayer (M), Final Constraints (rf)), append all unkowns of partition, as we might need their partials
    partialCandidates := VariablePointers.fromList(listAppend(getMrfPartialCandidates(part), VariablePointers.toList(part.unknowns)), part.unknowns.scalarized);
    seedCandidates := VariablePointers.fromList(getSeedCandidatesDynamicOptimization(part, all_knowns, BVariable.isMrfVariable), partialCandidates.scalarized);

    // TODO: add _OPT to name?
    MRF_jacobian := func(name, JacobianType.OPT_MRF, seedCandidates, partialCandidates,
                         part.equations, part.strongComponents, part.adjacencyMatrix, funcMap, staticAsContinuous);

    // r0 Jacobian (Initial Constraints (r0)), append all unkowns of partition, as we might need their partials
    partialCandidates := VariablePointers.fromList(listAppend(getR0PartialCandidates(part), VariablePointers.toList(part.unknowns)), part.unknowns.scalarized);
    seedCandidates := VariablePointers.fromList(getSeedCandidatesDynamicOptimization(part, all_knowns, BVariable.isR0Variable), partialCandidates.scalarized);

    // TODO: add _OPT to name?
    R0_jacobian := func(name, JacobianType.OPT_R0, seedCandidates, partialCandidates,
                        part.equations, part.strongComponents, part.adjacencyMatrix, funcMap, staticAsContinuous);
  end partJacobianDynamicOptimization;

  function partJacobian
    input output Partition.Partition part;
    input UnorderedMap<Path, Function> funcMap;
    input VariablePointers knowns;
    input String name                                     "Context name for jacobian";
    input Module.jacobianInterface func;
  protected
    JacobianType jacType;
    VariablePointers unknowns;
    list<Pointer<Variable>> derivative_vars, state_vars;
    VariablePointers seedCandidates, partialCandidates;
    Option<Jacobian> jacobian, LFG_jacobian = NONE(), MRF_jacobian = NONE(), R0_jacobian = NONE()  "Resulting jacobians";
    Option<Jacobian> adjointJac;
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
          (tmp, updated) := compJacobian(comps[i], part.adjacencyMatrix, funcMap, kind);
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

      jacobian := func(name, jacType, seedCandidates, partialCandidates, part.equations, part.strongComponents, part.adjacencyMatrix, funcMap, Partition.kindIsInitial(kind));

      if Flags.getConfigBool(Flags.MOO_DYNAMIC_OPTIMIZATION) then
        /* Add Lfg + Mr Jacobians for MOO dynamic optimization */
        (LFG_jacobian, MRF_jacobian, R0_jacobian) := partJacobianDynamicOptimization(part, knowns, name, func, funcMap);
      end if;

      if Flags.getConfigString(Flags.GENERATE_DYNAMIC_JACOBIAN) == "bidirectional" and isSome(jacobian) and not BackendDAE.getIsAdjoint(Util.getOption(jacobian)) then
        // Bidirectional: generate adjoint jacobian in addition to forward
        adjointJac := jacobianSymbolicAdjoint(name, jacType, seedCandidates, partialCandidates, part.equations, part.strongComponents, part.adjacencyMatrix, funcMap, kind == NBPartition.Kind.INI);
        part.association := Partition.Association.CONTINUOUS(kind, jacobian, adjointJac, LFG_jacobian, MRF_jacobian, R0_jacobian);
      elseif isSome(jacobian) then
        if BackendDAE.getIsAdjoint(Util.getOption(jacobian)) then
          part.association := Partition.Association.CONTINUOUS(kind, NONE(), jacobian, LFG_jacobian, MRF_jacobian, R0_jacobian);
        else
          part.association := Partition.Association.CONTINUOUS(kind, jacobian, NONE(), LFG_jacobian, MRF_jacobian, R0_jacobian);
        end if;
      else
        part.association := Partition.Association.CONTINUOUS(kind, NONE(), NONE(), LFG_jacobian, MRF_jacobian, R0_jacobian);
      end if;
      if Flags.isSet(Flags.JAC_DUMP) then
        print(Partition.Partition.toString(part, 2));
      end if;
    end if;
  end partJacobian;

  function compJacobian
    input output StrongComponent comp;
    input Option<Adjacency.Matrix> full;
    input UnorderedMap<Path, Function> funcMap;
    input Partition.Kind kind;
    output Boolean updated;
  protected
    Tearing strict;
    list<StrongComponent> residual_comps;
    list<VariablePointer> seed_candidates, residual_vars, inner_vars;
    constant Boolean staticAsContinuous = Partition.kindIsInitial(kind);
  algorithm
    (comp, updated) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // create residual components
        residual_comps        := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in strict.residual_eqns);

        // create seed and partial candidates
        seed_candidates := list(Slice.getT(var) for var in strict.iteration_vars);
        residual_vars   := list(Equation.getResidualVar(Slice.getT(eqn)) for eqn in strict.residual_eqns);
        inner_vars      := listAppend(list(var for var guard(BVariable.isContinuous(var, staticAsContinuous)) in StrongComponent.getVariables(comp)) for comp in strict.innerEquations);

        // update jacobian to take slices (just to have correct inner variables and such)
        strict.jac := nonlinear(
          seedCandidates     = VariablePointers.fromList(seed_candidates),
          partialCandidates  = VariablePointers.fromList(listAppend(residual_vars, inner_vars)),
          equations          = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in strict.residual_eqns)),
          comps              = Array.appendList(strict.innerEquations, residual_comps),
          full               = full,
          funcMap            = funcMap,
          name               = Partition.Partition.kindToString(kind) + (if comp.linear then "_LS_JAC_" else "_NLS_JAC_") + intString(comp.idx),
          staticAsContinuous = staticAsContinuous);
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

    VariablePointers adjacencyVars;
    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, res_vars_d, tmp_vars, tmp_vars_d, seed_vars, seed_vars_d;
    BVariable.VarData varDataJac;
    Adjacency.Matrix fullLocal, sparsity;
    UnorderedSet<ComponentRef> seed_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> pder_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

    BVariable.checkVar func = getTmpFilterFunction(jacType);
  algorithm
    if isSome(strongComponents) then
      // filter all discrete strong components and differentiate the others
      // todo: mixed algebraic loops should be here without the discrete subsets
      comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(strongComponents));
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no strong components were given!"});
      fail();
    end if;

    // create seed vars
    VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, map = diff_map,
                                                                     makeVar = BVariable.makeSeedVar, staticAsContinuous = staticAsContinuous));
    for v in VariablePointers.toList(seedCandidates) loop
      if BVariable.isContinuous(v, staticAsContinuous) then
        UnorderedSet.add(BVariable.getVarName(v), seed_set);
      end if;
    end for;

    // create pDer vars (also filters out discrete vars)
    (res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(staticAsContinuous = staticAsContinuous));

    for v in res_vars loop
      makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = false), staticAsContinuous = staticAsContinuous);
    end for;

    for v in res_vars loop
      UnorderedSet.add(BVariable.getVarName(v), pder_set);
    end for;
    res_vars_d := listReverse(Pointer.access(pDer_vars_ptr));

    pDer_vars_ptr := Pointer.create({});
    for v in tmp_vars loop makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = true), staticAsContinuous = staticAsContinuous); end for;
    tmp_vars_d := Pointer.access(pDer_vars_ptr);

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),   // no explicit cref necessary, rules are set by diff map
      new_vars        = {},
      diff_map        = SOME(diff_map),         // seed and temporary cref map
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcMap         = funcMap,
      scalarized      = seedCandidates.scalarized,
      adjoint_map     = NONE(),
      current_grad    = Expression.EMPTY(Type.REAL()),
      collectAdjoints = false
    );

    // differentiate all strong components
    (diffed_comps, diffArguments) := Differentiate.differentiateStrongComponentList(comps, diffArguments, idx, name, getInstanceName());

    // collect var data (most of this can be removed)
    unknown_vars  := listAppend(res_vars_d, tmp_vars_d);
    all_vars      := unknown_vars;  // add other vars later on

    seed_vars_d   := listReverse(Pointer.access(seed_vars_ptr));
    aux_vars      := seed_vars_d;     // add other auxiliaries later on
    alias_vars    := {};
    depend_vars   := {};

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(all_vars),
      unknowns      = VariablePointers.fromList(unknown_vars),
      auxiliaries   = VariablePointers.fromList(aux_vars),
      aliasVars     = VariablePointers.fromList(alias_vars),
      diffVars      = partialCandidates,
      dependencies  = VariablePointers.fromList(depend_vars),
      resultVars    = VariablePointers.fromList(res_vars_d),
      tmpVars       = VariablePointers.fromList(tmp_vars_d),
      seedVars      = VariablePointers.fromList(seed_vars_d)
    );

    // Always rebuild the full matrix from the actual comps equations.
    // Using part.adjacencyMatrix (the `full` param) would fail because residual
    // equations created by finalize() during tearing get new names and don't
    // appear in the partition's pre-tearing adjacency matrix.
    adjacencyVars := VariablePointers.clone(seedCandidates);
    adjacencyVars := VariablePointers.addList(tmp_vars, adjacencyVars);
    // For ODE Jacobians, also include state derivatives as adjacency variables.
    // Some equations use der(x_j) as an RHS input (e.g. der(x_i) = f(der(x_j), x_k)).
    // Without this, the transitive seed dependency der(x_i) -> der(x_j) -> x_j is lost.
    if jacType == JacobianType.ODE then
      adjacencyVars := VariablePointers.addList(res_vars, adjacencyVars);
    end if;
    fullLocal := Adjacency.Matrix.createFull(adjacencyVars,
      EquationPointers.fromList(List.flatten(list(StrongComponent.getEquations(comp) for comp in comps))));
    sparsity := Adjacency.Matrix.fullToSparsity(fullLocal, comps, seed_set, pder_set, diff_map);

    jacobian := SOME(Jacobian.JACOBIAN(
      name      = name,
      jacType   = jacType,
      varData   = varDataJac,
      comps     = listArray(diffed_comps),
      sparsity  = sparsity,
      isAdjoint = false
    ));
  end jacobianSymbolic;

  function sizeClassificationFromType
    input Type ty;
    output SizeClassification sc;
  algorithm
    sc := match Type.dimensionCount(ty)
      case 0 then SizeClassification.SCALAR;
      case 1 then SizeClassification.ELEMENT_WISE;
      case 2 then SizeClassification.MATRIX;
      else SizeClassification.ELEMENT_WISE;
    end match;
  end sizeClassificationFromType;

  // Helper: build addition (or single term) expression from a list of terms for a given LHS cref.
  function buildAdjointRhs
    input ComponentRef lhsCref;
    input list<Expression> terms;
    output Expression rhs;
  protected
    Type vty;
    SizeClassification sc;
    Operator addOp;
  algorithm
    // Retrieve variable type
    vty := ComponentRef.getComponentType(lhsCref);

    if listEmpty(terms) then
      rhs := Expression.makeZero(vty);
      return;
    end if;

    if List.hasOneElement(terms) then
      rhs := listHead(terms);
      return;
    end if;

    sc := sizeClassificationFromType(vty);
    addOp := Operator.fromClassification(
      (MathClassification.ADDITION, sc),
      vty
    );

    rhs := SimplifyExp.simplify(Expression.MULTARY(terms, {}, addOp));
    rhs := Expression.map(rhs, Expression.repairOperator);
  end buildAdjointRhs;

  // Helper: run reverse-mode on a residual expression with a given seed (current_grad),
  // accumulating into the provided adjoint_map. Returns updated DifferentiationArguments.
  function accumulateAdjointForResidual
    input Expression residual;
    input Expression seed; // current_grad, typically a lambda_i cref
    input UnorderedMap<ComponentRef,ComponentRef> diff_map;
    input UnorderedMap<Path, Function> funcMapIn;
    input Boolean scalarized;
    input UnorderedMap<ComponentRef, AdjointTermList> adjoint_map_in;
    output Differentiate.DifferentiationArguments diffArguments;
  algorithm
    // Prepare args to collect adjoints into the incoming map
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),
      new_vars        = {},
      diff_map        = SOME(diff_map),
      diffType        = NBDifferentiate.DifferentiationType.JACOBIAN,
      funcMap         = funcMapIn,
      scalarized      = scalarized,
      adjoint_map     = SOME(adjoint_map_in),
      current_grad    = seed,
      collectAdjoints = true
    );

    // Run reverse-mode on the residual expression.
    (_, diffArguments) := NBDifferentiate.differentiateExpression(residual, diffArguments);
  end accumulateAdjointForResidual;

  // Reusable builder for a SINGLE_COMPONENT adjoint assignment (tmp or result var).
  function makeAdjointComponentFromRhs
    input ComponentRef lhsKey;
    input Expression rhsExpr;
    input String contextName;
    input Integer eqIndex;
    output NBStrongComponent diffed_comp;
  protected
    Pointer<NBEquation.Equation> eqPtr;
    NBEquation.Equation eq;
    Pointer<Variable> lhsVarPtr;
  algorithm
    eqPtr := Equation.makeAssignment(
      Expression.fromCref(lhsKey),
      rhsExpr,
      Pointer.create(eqIndex),
      contextName,
      BEquation.Iterator.EMPTY(),
      NBEquation.EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false)
    );

    lhsVarPtr := BVariable.getVarPointer(lhsKey, sourceInfo());
    eq := Pointer.access(eqPtr);

    diffed_comp := match eq
      case NBEquation.SCALAR_EQUATION() algorithm
        if not listEmpty(ComponentRef.subscriptsAllFlat(lhsKey)) then
          // Represent as a sliced component of size 1
          diffed_comp := NBStrongComponent.SLICED_COMPONENT(
            var_cref = lhsKey,
            var      = Slice.SLICE(lhsVarPtr, {}),
            eqn      = Slice.SLICE(eqPtr, {}),
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
  end makeAdjointComponentFromRhs;

  function addEntryToLPAMap
    input Pointer<Variable> vptr;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
    input UnorderedMap<ComponentRef, AdjointTermList> loop_product_adjoint_map;
  protected
    Option<ComponentRef> mappedSeed;
  algorithm
    mappedSeed := UnorderedMap.get(BVariable.getVarName(vptr), diff_map);
    if isSome(mappedSeed) then
      UnorderedMap.tryAdd(Util.getOption(mappedSeed), {}, loop_product_adjoint_map);
    end if;
  end addEntryToLPAMap;

  // Resolve base variables that were actually mapped to tmp pDER vars.
  // This avoids relying on splitOnTrue output ordering semantics.
  function getBaseTmpVarCandidates
    input list<NBVariable.VariablePointer> partialVars;
    input list<NBVariable.VariablePointer> tmpPDerVars;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
    output list<NBVariable.VariablePointer> baseTmpVars = {};
  protected
    UnorderedSet<ComponentRef> tmpPDerSet;
    ComponentRef baseCref;
    Option<ComponentRef> o_mapped;
  algorithm
    tmpPDerSet := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(tmpPDerVars)));

    for v in tmpPDerVars loop
      UnorderedSet.add(BVariable.getVarName(v), tmpPDerSet);
    end for;

    for v in partialVars loop
      baseCref := BVariable.getVarName(v);
      o_mapped := UnorderedMap.get(baseCref, diff_map);
      if isSome(o_mapped) and UnorderedSet.contains(Util.getOption(o_mapped), tmpPDerSet) then
        baseTmpVars := v :: baseTmpVars;
      end if;
    end for;

    baseTmpVars := listReverse(baseTmpVars);
  end getBaseTmpVarCandidates;

  // Build a filtered diff map for a given variable list.
  // For each variable pointer v in 'vars', if there exists a mapping
  //   base = BVariable.getVarName(v) -> mapped in 'globalDiffMap'
  // then add (base -> mapped) to the returned map.
  function populateDiffMap
    input list<NBVariable.VariablePointer> vars;
    input UnorderedMap<ComponentRef, ComponentRef> globalDiffMap;
    output UnorderedMap<ComponentRef, ComponentRef> outMap;
  protected
    ComponentRef baseCref;
    Option<ComponentRef> o_mappedCref;
  algorithm
    outMap := UnorderedMap.new<ComponentRef>(
      ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(vars))
    );

    for vp in vars loop
      baseCref := BVariable.getVarName(vp);
      o_mappedCref := UnorderedMap.get(baseCref, globalDiffMap);
      if isSome(o_mappedCref) then
        UnorderedMap.add(baseCref, Util.getOption(o_mappedCref), outMap);
      end if;
    end for;
  end populateDiffMap;

  function isSupportedAdjointStrongComponent
    input StrongComponent comp;
    output Boolean ok;
  algorithm
    ok := match comp
      case StrongComponent.SINGLE_COMPONENT()    then true;
      case StrongComponent.MULTI_COMPONENT()     then true;
      case StrongComponent.SLICED_COMPONENT()    then true;
      case StrongComponent.RESIZABLE_COMPONENT() then true;
      case StrongComponent.ALGEBRAIC_LOOP()      then true;
      case StrongComponent.ALIAS()               then isSupportedAdjointStrongComponent(comp.original);
      else false;
    end match;
  end isSupportedAdjointStrongComponent;

  type AdjointTermList = list<Expression>;
  function generateAdjointComponent
    "Generate adjoint strong component(s) for a single primal strong component.
     Uses a fresh adjoint_map per component and returns the resulting adjoint
     component(s) plus any new temporary variables."
    input StrongComponent comp;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
    input UnorderedMap<Path, Function> funcMap;
    input Boolean scalarized;
    input Boolean staticAsContinuous;
    input Pointer<Integer> idx;
    input String contextName;
    input VariablePointers seedCandidates "for algebraic loop x-inputs";
    input list<Pointer<Variable>> tmpVarCandidates "base tmp variables to also include in diff_map_x for algebraic loops";
    output list<StrongComponent> adjointComps = {};
    output list<Pointer<Variable>> newTmpVars = {};
  protected
    StrongComponent c_noalias;
    UnorderedMap<ComponentRef, AdjointTermList> fresh_adjoint_map;
    Differentiate.DifferentiationArguments diffArgs;
    Equation eq;
    list<Statement> adjStmts;
    Pointer<Equation> eqPtr;
    list<Slice<VariablePointer>> adjVarSlices;
    // SSA helper: accumulator for pDer vars created for SSA temporaries
    Pointer<list<Pointer<Variable>>> ssaPDerVarsPtr = Pointer.create({});
  algorithm
    c_noalias := StrongComponent.removeAlias(comp);

    () := match c_noalias
      local
        // ALGEBRAIC_LOOP locals
        Tearing tearing;
        list<VariablePointer> itVarPtrs;
        list<Expression> residuals;
        list<Pointer<Variable>> lambdaPtrs;
        list<ComponentRef> lambdaCrefs;
        Integer iRes;
        Pointer<Variable> lhsVarPtr;
        ComponentRef newC;
        UnorderedMap<ComponentRef, ComponentRef> diff_map_y, diff_map_x, diff_map_union;
        UnorderedMap<ComponentRef, AdjointTermList> loop_product_adjoint_map;
        list<Pointer<Variable>> seedPtrListX;
        list<Pointer<Equation>> linResEqnPtrs;
        AdjointTermList terms_j, terms_x;
        Expression lhs_j, rhs_j, rhs_x;
        Pointer<Equation> resid_j;
        Option<ComponentRef> o_ySeedCref, o_pDerX;
        ComponentRef ySeedCref, baseX, pDerX;
        StrongComponent loopComp;

        StrongComponent ssaAlg;
        list<tuple<ComponentRef, tuple<ComponentRef, Integer>>> replacements = {};
        list<Pointer<Variable>> newVars = {};
        // SSA seed-init locals (used in MULTI_COMPONENT adjoint)
        UnorderedSet<ComponentRef> seenCrefs;
        ComponentRef origCref, finalSsaCref, pDerOrigCref, pDerSsaCref;
        Type vty;
        // x_bar algorithm locals (used in ALGEBRAIC_LOOP adjoint)
        list<Statement> xbarStmts;
        SizeClassification sc_x;
        Operator addOp_x;
        Expression accRhs;
        // this true when its an initial problem? but we are only in the dynamic case
        Boolean init = false;

      // ===================== ALGEBRAIC_LOOP =====================
      case StrongComponent.ALGEBRAIC_LOOP(strict = tearing) algorithm
        // Collect iteration vars and residual equations and turn into residual expressions
        itVarPtrs := Tearing.getIterationVars(tearing);
        residuals := list(Equation.getResidualExp(Pointer.access(e)) for e in Tearing.getResidualEqns(tearing));

        // Create scalar lambda_i temporaries
        // Is it possible to create it as a vector?
        lambdaPtrs := {};
        lambdaCrefs := {};
        for iIdx in 1:listLength(residuals) loop
          (lhsVarPtr, newC) := BVariable.makeAuxVar(NBVariable.TEMPORARY_STR, Pointer.access(idx) + 1, Type.REAL(), false);
          Pointer.update(idx, Pointer.access(idx) + 1);
          (newC, lhsVarPtr) := BVariable.makePDerVar(newC, contextName, isTmp = true);
          lambdaPtrs := lhsVarPtr :: lambdaPtrs;
          lambdaCrefs := newC :: lambdaCrefs;
        end for;
        lambdaPtrs := listReverse(lambdaPtrs);
        lambdaCrefs := listReverse(lambdaCrefs);
        newTmpVars := lambdaPtrs;

        // Build filtered diff maps
        diff_map_y := populateDiffMap(itVarPtrs, diff_map);
        seedPtrListX := listAppend(BVariable.VariablePointers.toList(seedCandidates), tmpVarCandidates);
        seedPtrListX := list(vp for vp guard(not UnorderedMap.contains(BVariable.getVarName(vp), diff_map_y)) in seedPtrListX);
        diff_map_x := populateDiffMap(seedPtrListX, diff_map);
        diff_map_union := UnorderedMap.merge(diff_map_y, diff_map_x, sourceInfo());

        // Pre-populate loop_product_adjoint_map
        loop_product_adjoint_map := UnorderedMap.new<AdjointTermList>(ComponentRef.hash, ComponentRef.isEqual, listLength(itVarPtrs) + listLength(seedPtrListX));
        for vp in itVarPtrs loop addEntryToLPAMap(vp, diff_map_y, loop_product_adjoint_map); end for;
        for vp in seedPtrListX loop addEntryToLPAMap(vp, diff_map_x, loop_product_adjoint_map); end for;

        // Accumulate reverse-mode adjoints per residual with seed = lambda_i
        iRes := 1;
        for residual_i in residuals loop
          if iRes > listLength(lambdaCrefs) then break; end if;
          diffArgs := accumulateAdjointForResidual(
            residual_i,
            Expression.fromCref(listGet(lambdaCrefs, iRes)),
            diff_map_union,
            funcMap,
            scalarized,
            loop_product_adjoint_map
          );
          // Update loop_product_adjoint_map with new adjoint terms collected from this residual
          loop_product_adjoint_map := Util.getOption(diffArgs.adjoint_map);
          iRes := iRes + 1;
        end for;

        // Build linear algebraic loop: sum_i(dr_i/dy_j * lambda_i) = y_bar_j
        linResEqnPtrs := {};
        for vp in itVarPtrs loop
          o_ySeedCref := UnorderedMap.get(BVariable.getVarName(vp), diff_map_y);
          if isSome(o_ySeedCref) then
            ySeedCref := Util.getOption(o_ySeedCref);
            terms_j := UnorderedMap.getOrDefault(ySeedCref, loop_product_adjoint_map, {});
            lhs_j := buildAdjointRhs(ySeedCref, terms_j);
            rhs_j := Expression.fromCref(ySeedCref);
            resid_j := Equation.makeAssignment(lhs_j, rhs_j, idx, contextName,
              NBEquation.Iterator.EMPTY(), NBEquation.EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false));
            linResEqnPtrs := Equation.createResidual(resid_j) :: linResEqnPtrs;
          end if;
        end for;
        linResEqnPtrs := listReverse(linResEqnPtrs);

        if not listEmpty(linResEqnPtrs) then
          loopComp := makeLinearAlgebraicLoop(lambdaPtrs, linResEqnPtrs, NONE(), mixed = false, homotopy = false);
          adjointComps := loopComp :: adjointComps;
        end if;

        // Build x_bar = -lambda^T * (dr/dx) as a single algorithm component
        xbarStmts := {};
        for seedVarPtrX in seedPtrListX loop
          baseX := BVariable.getVarName(seedVarPtrX);
          o_pDerX := UnorderedMap.get(baseX, diff_map_x);
          if isSome(o_pDerX) then
            pDerX := Util.getOption(o_pDerX);
            terms_x := UnorderedMap.getOrDefault(pDerX, loop_product_adjoint_map, {});
            if not listEmpty(terms_x) then
              rhs_x := Expression.negate(buildAdjointRhs(pDerX, terms_x));
              vty := ComponentRef.getComponentType(pDerX);
              if Expression.containsCref(rhs_x, pDerX) then
                accRhs := rhs_x;
              else
                sc_x := sizeClassificationFromType(vty);
                addOp_x := Operator.fromClassification((MathClassification.ADDITION, sc_x), vty);
                accRhs := SimplifyExp.simplify(Expression.MULTARY({Expression.fromCref(pDerX), rhs_x}, {}, addOp_x));
              end if;
              accRhs := Expression.map(accRhs, Expression.repairOperator);
              xbarStmts := Statement.ASSIGNMENT(
                Expression.fromCref(pDerX), accRhs, vty, DAE.emptyElementSource
              ) :: xbarStmts;
            end if;
          end if;
        end for;
        xbarStmts := listReverse(xbarStmts);
        if not listEmpty(xbarStmts) then
          eqPtr := Equation.makeAlgorithm(xbarStmts, init);
          Equation.createName(eqPtr, idx, contextName);
          adjVarSlices := listReverse(collectAdjointVarSlices(xbarStmts, {}));
          adjointComps := StrongComponent.MULTI_COMPONENT(
            vars   = adjVarSlices,
            eqn    = Slice.SLICE(eqPtr, {}),
            status = NBSolve.Status.EXPLICIT
          ) :: adjointComps;
        end if;
      then ();

      // ===================== SINGLE_COMPONENT (scalar/array/record equation) =====================
      case StrongComponent.SINGLE_COMPONENT() algorithm
        eq := Pointer.access(c_noalias.eqn);

        // Build fresh adjoint_map
        fresh_adjoint_map := UnorderedMap.new<AdjointTermList>(ComponentRef.hash, ComponentRef.isEqual, 16);
        diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
          diffCref        = ComponentRef.EMPTY(),
          new_vars        = {},
          diff_map        = SOME(diff_map),
          diffType        = DifferentiationType.JACOBIAN,
          funcMap         = funcMap,
          scalarized      = scalarized,
          adjoint_map     = SOME(fresh_adjoint_map),
          current_grad    = Expression.EMPTY(Type.REAL()),
          collectAdjoints = true
        );

        (diffArgs, adjStmts) := Differentiate.differentiateEquationAdjoint(eq, diffArgs);

        if not listEmpty(adjStmts) then
          eqPtr := Equation.makeAlgorithm(adjStmts, init);
          Equation.createName(eqPtr, idx, contextName);

          // Collect output variables from adjoint statements (handles FOR and IF nesting)
          adjVarSlices := listReverse(collectAdjointVarSlices(adjStmts, {}));

          adjointComps := {StrongComponent.MULTI_COMPONENT(
            vars   = adjVarSlices,
            eqn    = Slice.SLICE(eqPtr, {}),
            status = NBSolve.Status.EXPLICIT
          )};
        end if;
      then ();

      // ===================== MULTI_COMPONENT (algorithm or if-equation) =====================
      case StrongComponent.MULTI_COMPONENT() algorithm
        eq := match Pointer.access(Slice.getT(c_noalias.eqn))
          case Equation.ALGORITHM() algorithm
            (ssaAlg, replacements, newVars) := algorithmToSSA(c_noalias);
            if Flags.isSet(Flags.DEBUG_ADJOINT) then
              print("SSA algorithm for adjoint of component " + StrongComponent.toString(c_noalias) + ":\n" + StrongComponent.toString(ssaAlg) + "\n");
            end if;

            // ── Register SSA variables in diff_map ──
            // For each new SSA variable, create a pDer companion and add the mapping
            // ssaCref -> pDerCref to diff_map so the adjoint differentiation can propagate
            // gradients through the SSA rename chain (e.g. x_1 -> pDer.x_1).
            for ssaVarPtr in newVars loop
              makeVarTraverse(ssaVarPtr, contextName, ssaPDerVarsPtr, diff_map,
                function BVariable.makePDerVar(isTmp = true), staticAsContinuous = staticAsContinuous);
            end for;
            // Collect the newly created pDer vars as temporaries
            for pDerVarPtr in Pointer.access(ssaPDerVarsPtr) loop
              newTmpVars := pDerVarPtr :: newTmpVars;
            end for;

          then match ssaAlg
            case StrongComponent.MULTI_COMPONENT() then Pointer.access(Slice.getT(ssaAlg.eqn));
            else Pointer.access(Slice.getT(c_noalias.eqn));
          end match;
          else algorithm
            then Pointer.access(Slice.getT(c_noalias.eqn));
          end match;

        // Build fresh adjoint_map
        fresh_adjoint_map := UnorderedMap.new<AdjointTermList>(ComponentRef.hash, ComponentRef.isEqual, 16);
        diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
          diffCref        = ComponentRef.EMPTY(),
          new_vars        = {},
          diff_map        = SOME(diff_map),
          diffType        = DifferentiationType.JACOBIAN,
          funcMap         = funcMap,
          scalarized      = scalarized,
          adjoint_map     = SOME(fresh_adjoint_map),
          current_grad    = Expression.EMPTY(Type.REAL()),
          collectAdjoints = true
        );

        (diffArgs, adjStmts) := Differentiate.differentiateEquationAdjoint(eq, diffArgs);

        // TODO: Check if it works as intended and make a test case
        // ── Prepend seed-initialization statements for the final SSA variable of each
        //    multi-assigned original variable ──
        // The last SSA rename (x_N) represents the final value of x after the algorithm.
        // Before the adjoint reverse sweep we must:
        //   1. seed  pDer.x_N := pDer.x   (transfer the incoming gradient for x)
        // We iterate replacements in REVERSE line order so the FIRST entry we see for
        // each base variable IS its final SSA rename.  A local seen-set avoids re-seeding
        // non-final renames.
        if not listEmpty(newVars) then
          seenCrefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, 4);
          for replacement in listReverse(replacements) loop
            (origCref, (finalSsaCref, _)) := replacement;
            if not UnorderedSet.contains(origCref, seenCrefs) then
              UnorderedSet.add(origCref, seenCrefs);
              if UnorderedMap.contains(origCref, diff_map) and
                 UnorderedMap.contains(finalSsaCref, diff_map) then
                pDerOrigCref := UnorderedMap.getOrFail(origCref, diff_map);
                pDerSsaCref  := UnorderedMap.getOrFail(finalSsaCref, diff_map);
                vty := ComponentRef.getSubscriptedType(pDerSsaCref, true);
                adjStmts := Statement.ASSIGNMENT(
                  Expression.fromCref(pDerSsaCref),
                  Expression.fromCref(pDerOrigCref),
                  vty, DAE.emptyElementSource) :: adjStmts;
              end if;
            end if;
          end for;
        end if;

        if not listEmpty(adjStmts) then
          eqPtr := Equation.makeAlgorithm(adjStmts, init);
          Equation.createName(eqPtr, idx, contextName);

          // Collect output variables from adjoint statements (handles FOR and IF nesting)
          adjVarSlices := listReverse(collectAdjointVarSlices(adjStmts, {}));

          adjointComps := {StrongComponent.MULTI_COMPONENT(
            vars   = adjVarSlices,
            eqn    = Slice.SLICE(eqPtr, {}),
            status = NBSolve.Status.EXPLICIT
          )};
        end if;
      then ();

      // ===================== ForComponent: SLICED / RESIZABLE / GENERIC =====================
      case StrongComponent.SLICED_COMPONENT() algorithm
        eq := Pointer.access(Slice.getT(c_noalias.eqn));
        adjointComps := generateAdjointForComponent(eq, c_noalias, diff_map, funcMap, scalarized, init, idx, contextName);
      then ();

      case StrongComponent.RESIZABLE_COMPONENT() algorithm
        eq := Pointer.access(Slice.getT(c_noalias.eqn));
        adjointComps := generateAdjointForComponent(eq, c_noalias, diff_map, funcMap, scalarized, init, idx, contextName);
      then ();

      case StrongComponent.GENERIC_COMPONENT() algorithm
        eq := Pointer.access(Slice.getT(c_noalias.eqn));
        adjointComps := generateAdjointForComponent(eq, c_noalias, diff_map, funcMap, scalarized, init, idx, contextName);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " unsupported component type: " + StrongComponent.toString(c_noalias)});
      then ();
    end match;
  end generateAdjointComponent;

  function generateAdjointForComponent
    "Handle SLICED/RESIZABLE/GENERIC components that wrap for-equations.
     Extracts the body equations, differentiates them, wraps in a for-algorithm."
    input Equation eq;
    input StrongComponent originalComp;
    input UnorderedMap<ComponentRef, ComponentRef> diff_map;
    input UnorderedMap<Path, Function> funcMap;
    input Boolean scalarized;
    input Boolean init;
    input Pointer<Integer> idx;
    input String contextName;
    output list<StrongComponent> adjointComps = {};
  protected
    UnorderedMap<ComponentRef, AdjointTermList> fresh_adjoint_map;
    Differentiate.DifferentiationArguments diffArgs;
    list<Statement> adjStmts;
    Pointer<Equation> eqPtr;
    list<Slice<VariablePointer>> adjVarSlices;
    ComponentRef adjVarCref;
  algorithm
    // Build fresh adjoint_map and diff arguments
    fresh_adjoint_map := UnorderedMap.new<AdjointTermList>(ComponentRef.hash, ComponentRef.isEqual, 16);
    diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),
      new_vars        = {},
      diff_map        = SOME(diff_map),
      diffType        = DifferentiationType.JACOBIAN,
      funcMap         = funcMap,
      scalarized      = scalarized,
      adjoint_map     = SOME(fresh_adjoint_map),
      current_grad    = Expression.EMPTY(Type.REAL()),
      collectAdjoints = true
    );

    // differentiateEquationAdjoint handles FOR_EQUATION (wraps with reversed iterators)
    (diffArgs, adjStmts) := Differentiate.differentiateEquationAdjoint(eq, diffArgs);

    if not listEmpty(adjStmts) then
      eqPtr := Equation.makeAlgorithm(adjStmts, init);
      Equation.createName(eqPtr, idx, contextName);

      // Collect variable slices from statements (handles ASSIGNMENT, FOR, and IF nesting)
      adjVarSlices := listReverse(collectAdjointVarSlices(adjStmts, {}));

      // Determine the adjoint var cref for the component wrapper
      adjVarCref := match originalComp
        case StrongComponent.SLICED_COMPONENT() then originalComp.var_cref;
        case StrongComponent.RESIZABLE_COMPONENT() then originalComp.var_cref;
        case StrongComponent.GENERIC_COMPONENT() then originalComp.var_cref;
        else ComponentRef.EMPTY();
      end match;

      adjointComps := {StrongComponent.MULTI_COMPONENT(
        vars   = adjVarSlices,
        eqn    = Slice.SLICE(eqPtr, {}),
        status = NBSolve.Status.EXPLICIT
      )};
    end if;
  end generateAdjointForComponent;

  function collectAdjointVarSlices
    "Recursively collect variable pointer slices from adjoint statements.
     Handles ASSIGNMENT at any nesting depth inside FOR and IF bodies."
    input list<Statement> stmts;
    input output list<Slice<VariablePointer>> varSlices;
  protected
    Pointer<Variable> vPtr;
    ComponentRef baseCref;
  algorithm
    for s in stmts loop
      () := match s
        case Statement.ASSIGNMENT(lhs = Expression.CREF()) algorithm
          baseCref := ComponentRef.stripSubscriptsAll(Expression.toCref(s.lhs));
          try
            vPtr := BVariable.getVarPointer(baseCref, sourceInfo());
            varSlices := Slice.SLICE(vPtr, {}) :: varSlices;
          else
          end try;
        then ();
        case Statement.FOR() algorithm
          varSlices := collectAdjointVarSlices(s.body, varSlices);
        then ();
        case Statement.IF() algorithm
          for branch in s.branches loop
            varSlices := collectAdjointVarSlices(Util.tuple22(branch), varSlices);
          end for;
        then ();
        else ();
      end match;
    end for;
  end collectAdjointVarSlices;

  function jacobianSymbolicAdjoint extends Module.jacobianInterface;
  protected
    list<StrongComponent> comps, primalComps, diffed_comps = {};
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
    Pointer<Integer> idx = Pointer.create(0);

    list<Pointer<Variable>> all_vars, unknown_vars, aux_vars, alias_vars, depend_vars, res_vars, tmp_vars, seed_vars, old_res_vars, baseTmpVarCandidates;
    BVariable.VarData varDataJac;

    VariablePointers adjacencyVars;
    Adjacency.Matrix fullLocal, sparsity;
    UnorderedSet<ComponentRef> seed_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> pder_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

    String newName;

    BVariable.checkVar func = getTmpFilterFunction(jacType);

    // Per-component adjoint generation
    list<StrongComponent> compAdjComps;
    list<Pointer<Variable>> compNewVars;
  algorithm
    newName := name + "_ADJ";
    if isSome(strongComponents) then
      comps := list(comp for comp guard(not StrongComponent.isDiscrete(comp)) in Util.getOption(strongComponents));
      primalComps := comps;
      // only allow currently implemented adjoint-capable components
      for c in comps loop
        if not isSupportedAdjointStrongComponent(c) then
          Error.addMessage(Error.INTERNAL_ERROR, {
            getInstanceName() + " only supports SINGLE_COMPONENT, MULTI_COMPONENT, SLICED_COMPONENT, RESIZABLE_COMPONENT and ALGEBRAIC_LOOP in symbolic adjoint jacobian generation!"
          });
          fail();
        end if;
        if Flags.isSet(Flags.DEBUG_ADJOINT) then
          print("Primal component: " + StrongComponent.toString(c) + "\n");
        end if;
      end for;
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed because no strong components were given!"});
      fail();
    end if;

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Seed candidates before pDer creation:\n" + BVariable.VariablePointers.toString(seedCandidates, "Seed Candidates") + "\n");
      print("Partial candidates before pDer creation:\n" + BVariable.VariablePointers.toString(partialCandidates, "Partial Candidates") + "\n");
    end if;

    // create seed vars
    for v in VariablePointers.toList(seedCandidates) loop
      makeVarTraverse(v, newName, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = false), staticAsContinuous = staticAsContinuous);
    end for;
    res_vars := Pointer.access(pDer_vars_ptr);

    // create pDer vars (also filters out discrete vars)
    (old_res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(staticAsContinuous = staticAsContinuous));

    for v in old_res_vars loop makeVarTraverse(v, newName, seed_vars_ptr, diff_map, BVariable.makeSeedVar, staticAsContinuous = staticAsContinuous); end for;
    seed_vars := Pointer.access(seed_vars_ptr);

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("seed vars after seed creation:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(seed_vars), "Seed Vars") + "\n");
      print("res vars after pDer creation:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(res_vars), "Res Vars") + "\n");
      print("tmp vars after pDer creation:\n" + BVariable.VariablePointers.toString(VariablePointers.fromList(tmp_vars), "Tmp Vars") + "\n");
    end if;

    pDer_vars_ptr := Pointer.create({});
    for v in tmp_vars loop makeVarTraverse(v, newName, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = true), staticAsContinuous = staticAsContinuous); end for;
    tmp_vars := Pointer.access(pDer_vars_ptr);
    baseTmpVarCandidates := getBaseTmpVarCandidates(VariablePointers.toList(partialCandidates), tmp_vars, diff_map);

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Diff map before component generation:\n" + diffMapToString(diff_map) + "\n");
    end if;

    // ===================== Sequential adjoint component generation =====================
    // Process each primal component in reverse order (LIFO), generate adjoint component(s),
    // and prepend to the unified list.
    for comp in primalComps loop
      (compAdjComps, compNewVars) := generateAdjointComponent(
        comp, diff_map, funcMap, seedCandidates.scalarized, staticAsContinuous, idx, newName, seedCandidates, baseTmpVarCandidates);

      // Prepend adjoint components (already in correct order from generateAdjointComponent)
      // only more than one if the original component was an algebraic loop
      for ac in compAdjComps loop
        diffed_comps := ac :: diffed_comps;
      end for;

      // Collect any new temporary variables (e.g. lambda vars from algebraic loops)
      for v in compNewVars loop
        tmp_vars := v :: tmp_vars;
      end for;

      if Flags.isSet(Flags.DEBUG_ADJOINT) then
        for ac in compAdjComps loop
          print("[adjoint] generated component: " + StrongComponent.toString(ac) + "\n");
        end for;
      end if;
    end for;
    // diffed_comps is now in LIFO order (correct for adjoint execution)

    if Flags.isSet(Flags.DEBUG_ADJOINT) then
      print("Final list of differentiated components:\n");
      for comp in diffed_comps loop
        print(StrongComponent.toString(comp) + "\n");
      end for;
    end if;

    // collect var data (most of this can be removed)
    unknown_vars  := listAppend(res_vars, tmp_vars);
    all_vars      := unknown_vars;  // add other vars later on

    seed_vars     := Pointer.access(seed_vars_ptr);
    aux_vars      := seed_vars;     // add other auxiliaries later on. TODO: Need to add the SSA vars and the lambda vars from algebraic loops as auxiliaries?
    alias_vars    := {};
    depend_vars   := {};

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList(all_vars),
      unknowns      = VariablePointers.fromList(unknown_vars),
      auxiliaries   = VariablePointers.fromList(aux_vars),
      aliasVars     = VariablePointers.fromList(alias_vars),
      diffVars      = partialCandidates,
      dependencies  = VariablePointers.fromList(depend_vars),
      resultVars    = VariablePointers.fromList(res_vars),
      tmpVars       = VariablePointers.fromList(tmp_vars),
      seedVars      = VariablePointers.fromList(seed_vars)
    );

    adjacencyVars := VariablePointers.clone(seedCandidates);
    adjacencyVars := VariablePointers.addList(tmp_vars, adjacencyVars);
    if jacType == JacobianType.ODE then
      adjacencyVars := VariablePointers.addList(res_vars, adjacencyVars);
    end if;
    fullLocal := Adjacency.Matrix.createFull(adjacencyVars,
      EquationPointers.fromList(List.flatten(list(StrongComponent.getEquations(comp) for comp in comps))));
    sparsity := Adjacency.Matrix.fullToSparsity(fullLocal, comps, seed_set, pder_set, diff_map);

    jacobian := SOME(Jacobian.JACOBIAN(
      name      = newName,
      jacType   = jacType,
      varData   = varDataJac,
      comps     = listArray(diffed_comps),
      sparsity  = sparsity,
      isAdjoint = true
    ));
  end jacobianSymbolicAdjoint;

  function jacobianNumeric
    extends Module.jacobianInterface;
  protected
    VarData varDataJac;
    VariablePointers adjacencyVars;
    Adjacency.Matrix sparsity, fullLocal;
    list<Pointer<Variable>> res_vars, tmp_vars, seed_vars_d, pDer_vars_d;
    BVariable.checkVar func = getTmpFilterFunction(jacType);
    Pointer<list<Pointer<Variable>>> seed_vars_ptr = Pointer.create({});
    Pointer<list<Pointer<Variable>>> pDer_vars_ptr = Pointer.create({});
    UnorderedMap<ComponentRef,ComponentRef> diff_map = UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);

    UnorderedSet<ComponentRef> seed_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> pder_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    (res_vars, tmp_vars) := List.splitOnTrue(VariablePointers.toList(partialCandidates), func);
    (tmp_vars, _) := List.splitOnTrue(tmp_vars, function BVariable.isContinuous(staticAsContinuous = staticAsContinuous));

    VariablePointers.mapPtr(seedCandidates, function makeVarTraverse(name = name, vars_ptr = seed_vars_ptr, map = diff_map, makeVar = BVariable.makeSeedVar, staticAsContinuous = staticAsContinuous));
    seed_vars_d := Pointer.access(seed_vars_ptr);
    for v in VariablePointers.toList(seedCandidates) loop
      if BVariable.isContinuous(v, staticAsContinuous) then
        UnorderedSet.add(BVariable.getVarName(v), seed_set);
      end if;
    end for;

    for v in res_vars loop
      UnorderedSet.add(BVariable.getVarName(v), pder_set);
      makeVarTraverse(v, name, pDer_vars_ptr, diff_map, function BVariable.makePDerVar(isTmp = false), staticAsContinuous = staticAsContinuous);
    end for;
    pDer_vars_d := Pointer.access(pDer_vars_ptr);

    varDataJac := BVariable.VAR_DATA_JAC(
      variables     = VariablePointers.fromList({}),
      unknowns      = partialCandidates,
      auxiliaries   = VariablePointers.fromList(seed_vars_d),
      aliasVars     = VariablePointers.fromList({}),
      diffVars      = partialCandidates,
      dependencies  = VariablePointers.fromList({}),
      resultVars    = VariablePointers.fromList(pDer_vars_d),
      tmpVars       = VariablePointers.fromList(tmp_vars),
      seedVars      = VariablePointers.fromList(seed_vars_d)
    );

    if isSome(strongComponents) then
      adjacencyVars := VariablePointers.clone(seedCandidates);
      adjacencyVars := VariablePointers.addList(tmp_vars, adjacencyVars);
      if jacType == JacobianType.ODE then
        adjacencyVars := VariablePointers.addList(res_vars, adjacencyVars);
      end if;
      fullLocal := Adjacency.Matrix.createFull(adjacencyVars, EquationPointers.fromList(
        List.flatten(list(StrongComponent.getEquations(comp) for comp in arrayList(Util.getOption(strongComponents))))));
      sparsity := Adjacency.Matrix.fullToSparsity(fullLocal, arrayList(Util.getOption(strongComponents)), seed_set, pder_set, diff_map);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because strong components are missing."});
      fail();
    end if;

    jacobian := SOME(Jacobian.JACOBIAN(
      name      = name,
      jacType   = jacType,
      varData   = varDataJac,
      comps     = listArray({}),
      sparsity  = sparsity,
      isAdjoint = false
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
      case JacobianType.ODE     then BVariable.isStateDerivative;
      case JacobianType.DAE     then BVariable.isResidual;
      case JacobianType.LS      then BVariable.isResidual;
      case JacobianType.NLS     then BVariable.isResidual;
      case JacobianType.OPT_LFG then BVariable.isLfgFunction;
      case JacobianType.OPT_MRF then BVariable.isMrfFunction;
      case JacobianType.OPT_R0  then BVariable.isInitialConstraint;
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
    input Boolean staticAsContinuous;

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
    if BVariable.isContinuous(var_ptr, staticAsContinuous) then
      // make the new differentiated variable itself
      (diff, diff_ptr) := makeVar(var.name, name);
      // add $<new>.x variable pointer to the variables
      Pointer.update(vars_ptr, diff_ptr :: Pointer.access(vars_ptr));
      // add x -> $<new>.x to the map for later lookup
      UnorderedMap.add(var.name, diff, map);

      // differentiate parent and add to map
      () := match BVariable.getParent(var_ptr)
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

  function diffMapToString
    input UnorderedMap<ComponentRef, ComponentRef> map;
    output String s;
  algorithm
    s := UnorderedMap.toString(map, ComponentRef.toString, ComponentRef.toString, "\n  ", " -> ");
    s := "{\n  " + s + "\n}";
  end diffMapToString;

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
    list<NBSlice<NBVariable.VariablePointer>> itVars_s;
    list<NBSlice<Pointer<NBEquation.Equation>>> res_s;
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


  function makeSSAVar
    "Creates a fresh SSA variable named 'baseName_idx' that copies all
     attributes from the variable referenced by baseCref.
     The new variable and its component reference are linked cyclically
     via the InstNode VAR_NODE pointer (same pattern as BVariable.makeAuxVar)."
    input  ComponentRef baseCref "original base cref (no subscripts)";
    input  Integer idx           "SSA subscript index (1 for x_1, 2 for x_2, ...)";
    output Pointer<Variable> ssaVarPtr;
    output ComponentRef ssaCref;
  protected
    Pointer<Variable> origVarPtr;
    Variable origVar;
    InstNode newNode;
    Type ty;
  algorithm
    origVarPtr := BVariable.getVarPointer(baseCref, sourceInfo());
    origVar    := Pointer.access(origVarPtr);
    ty         := ComponentRef.getSubscriptedType(baseCref, false);

    // Build a fresh VAR_NODE with the SSA name; the variable pointer is
    // initially a dummy and becomes cyclic via makeVarPtrCyclic below.
    newNode := InstNode.VAR_NODE(
      ComponentRef.firstName(baseCref) + "_" + intString(idx),
      Pointer.create(NBVariable.DUMMY_VARIABLE));
    ssaCref := ComponentRef.CREF(newNode, {}, ty,
      NFComponentRef.Origin.CREF, ComponentRef.EMPTY());

    // Clear any inherited partner pointers (pDer, seed) so that a fresh pDer
    // variable is created for this SSA temporary rather than reusing the
    // original variable's existing partner.
    origVar.backendinfo := BackendInfo.BACKEND_INFO(
      origVar.backendinfo.varKind,
      origVar.backendinfo.attributes,
      origVar.backendinfo.annotations,
      origVar.backendinfo.var_pre,
      NONE() /* var_seed */,
      NONE() /* var_pder_res */,
      NONE() /* var_pder_tmp */,
      origVar.backendinfo.var_start,
      origVar.backendinfo.parent
    );

    // Establish the cyclic Variable <-> InstNode pointer link
    (ssaVarPtr, ssaCref) := BVariable.makeVarPtrCyclic(origVar, ssaCref);
  end makeSSAVar;

  function algorithmToSSA
    "Transforms a MULTI_COMPONENT algorithm strong component into SSA
     (Static Single Assignment) form.

     Variables assigned more than once receive fresh indexed names,
     e.g. x -> x_1, x_2, ...  RHS reads are updated to use the latest
     SSA name of each written variable.
     Only ASSIGNMENT statements are expected in the algorithm body.

     Each entry (orig_cref, (ssa_cref, line_index)) in `replacements`
     records that orig_cref was renamed to ssa_cref at the statement
     with 1-based index line_index within the original algorithm."
    input  StrongComponent comp;
    output StrongComponent ssaComp;
    output list<tuple<ComponentRef, tuple<ComponentRef, Integer>>> replacements
      "original_var -> (ssa_var, line_of_replacement)";
    output list<Pointer<Variable>> newVars
      "newly created SSA variable pointers; caller must register them in the variable system";
  protected
    Equation eqn;
    Algorithm alg;
    Statement stmt;
    ComponentRef lhsCref, baseCref, ssaCref;
    Integer cnt, idx, lineIdx;
    Pointer<Variable> ssaVarPtr;
    Expression lhsExp, rhsExp;
    // Phase 1: how many times is each base cref assigned?
    UnorderedMap<ComponentRef, Integer> assignCount =
      UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
    // Phase 2: current per-variable SSA counter
    UnorderedMap<ComponentRef, Integer> ssaIdx =
      UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
    // Phase 2: current active SSA expression for each multi-assigned cref
    UnorderedMap<ComponentRef, Expression> activeRepl =
      UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    list<Statement> ssaStmts = {};
    list<tuple<ComponentRef, tuple<ComponentRef, Integer>>> replAcc = {};
    list<Pointer<Variable>> newVarsAcc = {};
    Pointer<Equation> ssaEqnPtr;
  algorithm
    (ssaComp, replacements, newVars) := match comp

      case StrongComponent.MULTI_COMPONENT() algorithm
        eqn := Pointer.access(Slice.getT(comp.eqn));
        Equation.ALGORITHM(alg = alg) := eqn;

        // ── Phase 1: count how many times each base cref appears on the LHS ──
        for origStmt in alg.statements loop
          () := match origStmt
            case Statement.ASSIGNMENT() algorithm
              lhsCref := match origStmt.lhs
                case Expression.CREF(cref = lhsCref) then lhsCref;
                else ComponentRef.EMPTY();
              end match;
              if not ComponentRef.isEmpty(lhsCref) then
                baseCref := ComponentRef.stripSubscriptsAll(lhsCref);
                cnt := UnorderedMap.getOrDefault(baseCref, assignCount, 0);
                UnorderedMap.add(baseCref, cnt + 1, assignCount);
              end if;
            then ();
            else ();
          end match;
        end for;

        // ── Phase 2: rename multi-assigned variables; substitute RHS reads ──
        lineIdx := 1;
        for origStmt in alg.statements loop
          stmt := match origStmt
            case Statement.ASSIGNMENT() algorithm
              // Substitute every RHS read with its current SSA name
              rhsExp := Expression.map(origStmt.rhs,
                function Replacements.applySimpleExp(replacements = activeRepl));

              // Check whether the LHS variable needs SSA renaming
              lhsExp  := origStmt.lhs;
              lhsCref := match origStmt.lhs
                case Expression.CREF(cref = lhsCref) then lhsCref;
                else ComponentRef.EMPTY();
              end match;

              if not ComponentRef.isEmpty(lhsCref) then
                baseCref := ComponentRef.stripSubscriptsAll(lhsCref);
                if UnorderedMap.getOrDefault(baseCref, assignCount, 1) > 1 then
                  // Increment the SSA index and create a fresh variable
                  idx := UnorderedMap.getOrDefault(baseCref, ssaIdx, 0) + 1;
                  UnorderedMap.add(baseCref, idx, ssaIdx);
                  (ssaVarPtr, ssaCref) := makeSSAVar(baseCref, idx);
                  newVarsAcc := ssaVarPtr :: newVarsAcc;

                  // Re-attach original subscripts to the new SSA cref
                  ssaCref := ComponentRef.copySubscripts(lhsCref, ssaCref);

                  // Update active replacement map (keyed by unsubscripted base cref)
                  UnorderedMap.add(baseCref,
                    Expression.fromCref(ComponentRef.stripSubscriptsAll(ssaCref)),
                    activeRepl);

                  // Record: original base cref -> (ssa base cref, 1-based line index)
                  replAcc := (baseCref,
                    (ComponentRef.stripSubscriptsAll(ssaCref), lineIdx)) :: replAcc;

                  // Replace the LHS with the SSA cref expression
                  lhsExp := Expression.fromCref(ssaCref);
                end if;
              end if;
            then Statement.ASSIGNMENT(lhsExp, rhsExp, origStmt.ty, origStmt.source);

            else origStmt;
          end match;

          ssaStmts := stmt :: ssaStmts;
          lineIdx   := lineIdx + 1;
        end for;

        // Build a fresh equation pointer with the SSA statement list so the
        // original primal equation is left untouched. Is that intended? SSA variables are appended to the component's var list so
        // that code generation can declare them as local temporaries.
        alg.statements := listReverse(ssaStmts);
        eqn := match eqn
          case Equation.ALGORITHM() algorithm eqn.alg := alg; then eqn;
          else eqn;
        end match;
        ssaEqnPtr := Pointer.create(eqn);
      then (StrongComponent.MULTI_COMPONENT(
              vars   = listAppend(comp.vars, list(Slice.SLICE(v, {}) for v in listReverse(newVarsAcc))),
              eqn    = Slice.SLICE(ssaEqnPtr, {}),
              status = comp.status
            ), listReverse(replAcc), listReverse(newVarsAcc));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {getInstanceName() + " expects a MULTI_COMPONENT with an ALGORITHM equation."});
      then fail();

    end match;
  end algorithmToSSA;

  annotation(__OpenModelica_Interface="nbackend");
end NBJacobian;
