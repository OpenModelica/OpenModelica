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

encapsulated uniontype NBTearing
"file:        NBTearing.mo
 package:     NBTearing
 description: This file contains the data-types used for tearing. It is a
              uniontype and therefore also contains some structures for tearing.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;
  import Slice = NBSlice;
  import NBVariable.{VarSlice, VariablePointer, VariablePointers, VarData};
  import NBEquation.{Equation, EqnSlice, EquationPointer, EquationPointers, EqData, EquationAttributes};
  import StrongComponent = NBStrongComponent;

protected
  // selfimport
  import Tearing = NBTearing;

  // OF imports
  import Absyn.Path;

  // NF imports
  import Algorithm = NFAlgorithm;
  import Expression = NFExpression;
  import NFFunction.Function;
  import Variable = NFVariable;
  import ComponentRef = NFComponentRef;
  import Subscript = NFSubscript;
  import Type = NFType;
  import NFBackendExtension.{BackendInfo, VariableKind};

  // Backend imports
  import Adjacency = NBAdjacency;
  import NBAdjacency.Solvability;
  import Causalize = NBCausalize;
  import BEquation = NBEquation;
  import Initialization = NBInitialization;
  import BJacobian = NBJacobian;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import Inline = NBInline;
  import Jacobian = NBackendDAE.BackendDAE;
  import Matching = NBMatching;
  import Solve = NBSolve;
  import Sorting = NBSorting;
  import Partition = NBPartition;

  //Util imports
  import BackendUtil = NBBackendUtil;
  import StringUtil;

public

  record TEARING_SET
    list<Slice<VariablePointer>> iteration_vars   "the variables used for iteration";
    list<Slice<EquationPointer>> residual_eqns    "implicitely solved residual equations";
    array<StrongComponent> innerEquations         "array of matched equations and variables";
    Option<Jacobian> jac                          "optional jacobian";
  end TEARING_SET;

  function hash
    "compute hash value independent of ordering by adding hash of iteration variables, should be unique enough"
    input Tearing set;
    output Integer h = sum(Slice.hash(var, BVariable.hash) for var in set.iteration_vars);
  end hash;

  function isEqual
    "checking the jacobian should not be necessary"
    input Tearing set1;
    input Tearing set2;
    output Boolean b;
  algorithm
    b := UnorderedSet.equal_list(set1.residual_eqns, set2.residual_eqns, function Slice.hash(func = Equation.hash), function Slice.isEqual(func = Equation.isEqualPtr));
    b := if b then Array.isEqualOnTrue(set1.innerEquations, set2.innerEquations, StrongComponent.isEqual) else b; // TODO inner equations don't need to be sorted identically
    b := if b then UnorderedSet.equal_list(set1.iteration_vars, set2.iteration_vars, function Slice.hash(func = BVariable.hash), function Slice.isEqual(func = BVariable.equalName)) else b;
  end isEqual;

  function size
    input Tearing set;
    input Boolean resize;
    output Integer s;
  algorithm
    s := sum(Slice.size(eq, function Equation.size(resize = resize)) for eq in set.residual_eqns);
    s := s + sum(StrongComponent.size(eq, resize) for eq in set.innerEquations);
  end size;

  function toString
    input Tearing set;
    input output String str;
  algorithm
    str := StringUtil.headline_4(str);
    str := str + "### Iteration Variables:\n" + Slice.lstToString(set.iteration_vars, BVariable.pointerToString, "    ");
    str := str + "\n### Residual Equations:\n" + Slice.lstToString(set.residual_eqns, function Equation.pointerToString(str = "    "));
    str := str + "\n### Inner Equations:\n" + Array.toString(set.innerEquations, function StrongComponent.toString(index = -1), "", "    ", "\n  ", "");
    if isSome(set.jac) then
      str := str + "\n" + BJacobian.toString(Util.getOption(set.jac), "NLS");
    end if;
  end toString;

  function main
    "Wrapper function for any tearing function. This will be
    called during simulation and gets the corresponding subfunction from
    Config."
    extends Module.wrapper;
    input Partition.Kind kind;
  protected
    constant list<Module.tearingInterface> funcs = getModule();
  algorithm
    if Flags.isSet(Flags.TEARING_DUMP) then
      print(StringUtil.headline_1("[" + Partition.Partition.kindToString(kind) + "] Tearing") + "\n");
    end if;
    bdae := match (kind, bdae)
      local
        list<Partition.Partition> partitions;
        Pointer<Integer> eq_index;

      case (NBPartition.Kind.ODE, BackendDAE.MAIN(eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          bdae.ode := tearingTraverser(bdae.ode, funcs, bdae.funcMap, eq_index, kind);
      then bdae;

      case (_, BackendDAE.MAIN(eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index))) guard(Partition.kindIsInitial(kind))
        algorithm
          bdae.init := tearingTraverser(bdae.init, funcs, bdae.funcMap, eq_index, kind);
          if isSome(bdae.init_0) then
            bdae.init_0 := SOME(tearingTraverser(Util.getOption(bdae.init_0), funcs, bdae.funcMap, eq_index, kind));
          end if;
      then bdae;

      case (NBPartition.Kind.DAE, BackendDAE.MAIN(dae = SOME(partitions), eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          bdae.dae := SOME(tearingTraverser(partitions, funcs, bdae.funcMap, eq_index, kind));
          // recursively call this function to also apply to the ODE section (used for events)
          // ToDo: only create event partitions, disregard rest
      then main(bdae, NBPartition.Kind.ODE);

    // ToDo: all the other cases: e.g. Jacobian, Hessian
    end match;
  end main;

  function implicit
    input output StrongComponent comp                 "suspected algebraic loop";
    input UnorderedMap<Path, Function> funcMap        "Function call bodies";
    input output Integer index                        "current unique loop index";
    input Partition.Kind kind = NBPartition.Kind.ODE  "partition type";
  protected
    // dummy adjacency matrix, don't need it for implicit
    Adjacency.Matrix dummy = Adjacency.EMPTY(NBAdjacency.MatrixStrictness.FULL);
    StrongComponent new_comp;
    Pointer<Boolean> homotopy = Pointer.create(false);
  algorithm
    (comp, dummy, index) := match comp
      // create implicit equations
      case StrongComponent.SINGLE_COMPONENT() algorithm
        Equation.map(Pointer.access(comp.eqn), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(comp.var, comp.eqn),
          casual  = NONE(),
          // a multi-dimensional var (e.g. matrix-coupled array equation like A*x=b with
          // A a parameter matrix) can be genuinely linear even though it isn't solvable
          // one scalar element at a time -- check like SLICED_COMPONENT does instead of
          // always assuming nonlinear.
          linear  = isLinearSlice(comp.eqn, ComponentRef.scalarize(BVariable.getVarName(comp.var), false), funcMap),
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT,
          implicitlyCreated = true);
        index := index + 1;
      then finalize(new_comp, dummy, funcMap, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      case StrongComponent.MULTI_COMPONENT() algorithm
        Equation.map(Pointer.access(Slice.getT(comp.eqn)), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(Slice.getT(listHead(comp.vars)), Slice.getT(comp.eqn)), // this is wrong! need to take all vars
          casual  = NONE(),
          linear  = false,
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT,
          implicitlyCreated = true);
        index := index + 1;
      then finalize(new_comp, dummy, funcMap, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      case StrongComponent.RESIZABLE_COMPONENT() algorithm
        Equation.map(Pointer.access(Slice.getT(comp.eqn)), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(Slice.getT(comp.var), Slice.getT(comp.eqn)),
          casual  = NONE(),
          linear  = isLinearSlice(Slice.getT(comp.eqn), ComponentRef.scalarize(comp.var_cref, false), funcMap),
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT,
          implicitlyCreated = true);
        index := index + 1;
      then finalize(new_comp, dummy, funcMap, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      // a component matched to a genuine partial array slice (comp.var/comp.eqn already
      // carry the correct .indices) that could not be solved explicitly, e.g. a torn
      // matrix-shaped subsystem for i_s[{1, 2}]. Same treatment as
      // SINGLE_COMPONENT/RESIZABLE_COMPONENT, keeping the slice instead of wrapping a
      // whole variable/equation. Was previously missing, falling through to "do nothing".
      case StrongComponent.SLICED_COMPONENT() algorithm
        Equation.map(Pointer.access(Slice.getT(comp.eqn)), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = slicedImplicit(comp.var, comp.eqn),
          casual  = NONE(),
          linear  = isLinearSlice(Slice.getT(comp.eqn), ComponentRef.scalarize(comp.var_cref, false), funcMap),
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT,
          implicitlyCreated = true);
        index := index + 1;
      then finalize(new_comp, dummy, funcMap, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      // do nothing otherwise
      else (comp, dummy, index);
    end match;
  end implicit;

  function singleImplicit
    input VariablePointer var;
    input EquationPointer eqn;
    output NBTearing tearingSet = Tearing.TEARING_SET(
      iteration_vars  = {Slice.SLICE(var, {})},
      residual_eqns   = {Slice.SLICE(eqn, {})},
      innerEquations  = listArray({}),
      jac             = NONE());
  end singleImplicit;

  function slicedImplicit
    "same as singleImplicit, but var already carries the correct .indices (see the
    SLICED_COMPONENT case in implicit()) and must not be re-wrapped as a whole slice.
    eqn is expanded to one residual_eqns entry per scalar row (see scalarSlices):
    NBJacobian.compJacobian pulls one residual variable per residual_eqns entry
    (Equation.getResidualVar), so a single entry covering all rows of a multi-row
    array equation undercounts the residual side against a per-element iteration_vars
    seed list, producing an empty/mismatched Jacobian sparsity pattern."
    input Slice<VariablePointer> var;
    input Slice<EquationPointer> eqn;
    output NBTearing tearingSet = Tearing.TEARING_SET(
      iteration_vars  = {var},
      residual_eqns   = scalarSlices(eqn),
      innerEquations  = listArray({}),
      jac             = NONE());
  end slicedImplicit;

  function scalarSlices
    "expands a (possibly whole, .indices={}) equation slice into one Slice entry per
    scalar row, each wrapping its OWN, newly created scalar residual equation with a
    distinct residual variable -- NOT just the same underlying equation pointer
    re-sliced. Equations are keyed by their residual variable's name throughout this
    codebase (Equation.getEqnName/getResidualVar), which is a whole-variable property
    like everything else keyed that way here; multiple slices of one multi-row array
    equation would all resolve back to the SAME residual variable and collapse to one
    entry in any name-keyed collection built from them (e.g. EquationPointers.fromList
    in NBJacobian.jacobianNumeric's adjacency-matrix build), silently undercounting
    rows and producing an empty/wrong Jacobian sparsity pattern."
    input Slice<EquationPointer> eqn;
    output list<Slice<EquationPointer>> slices;
  protected
    Pointer<Equation> eqn_ptr = Slice.getT(eqn);
    Equation e = Pointer.access(eqn_ptr);
    list<Integer> indices = eqn.indices;
    ComponentRef base_cref;
    Expression residual;
    Type elem_ty;
    EquationAttributes attr;
    list<Subscript> subs;
    ComponentRef row_cref;
    Pointer<Variable> row_var;
    Variable row_var_data;
    Expression row_residual;
    Equation row_eqn;
    Boolean is_for;
  algorithm
    if listEmpty(indices) then
      indices := list(i for i in 0:(Equation.size(eqn_ptr) - 1));
    end if;
    if List.hasOneElement(indices) and Equation.size(eqn_ptr) == 1 then
      // already scalar: no row-collapse risk. A single row of a bigger array
      // equation still has the residual variable of the whole array.
      slices := {eqn};
    else
      base_cref := Equation.getEqnName(eqn_ptr);
      is_for    := Equation.isSingleBodyFor(e);
      residual  := if is_for then Expression.EMPTY(Type.UNKNOWN()) else Equation.getResidualExp(e);
      elem_ty   := Type.arrayElementType(Expression.typeOf(residual));
      attr      := Equation.getAttributes(e);
      attr.residual := true;
      slices := {};
      for i in indices loop
        if is_for then
          row_residual := Equation.forArrayBodyRowResidual(e, i);
          elem_ty      := Type.arrayElementType(Expression.typeOf(row_residual));
        else
          subs         := list(Subscript.INDEX(Expression.INTEGER(l + 1)) for l in Slice.indexToLocation(i, Equation.sizes(eqn_ptr)));
          row_residual := Expression.applySubscripts(subs, residual);
        end if;
        (row_var, row_cref) := BVariable.makeAuxVar(ComponentRef.toString(base_cref), i, elem_ty, false);
        // makeAuxVar tags the new var with a plain VariableKind derived from its type;
        // it must instead be marked RESIDUAL_VAR like any other residual variable, or
        // downstream Jacobian construction (NBJacobian.getTmpFilterFunction's
        // BVariable.isResidual check for LS/NLS/DAE) won't recognize it as a result row
        // and the Jacobian's sparsity pattern will come out empty for this equation.
        row_var_data := Pointer.access(row_var);
        row_var_data.backendinfo := BackendInfo.setVarKind(row_var_data.backendinfo, VariableKind.RESIDUAL_VAR());
        Pointer.update(row_var, row_var_data);
        attr.residualVar := SOME(row_var);
        row_eqn := Equation.SCALAR_EQUATION(elem_ty, Expression.fromCref(row_cref), row_residual, Equation.getSource(e), attr);
        slices := Slice.SLICE(Pointer.create(row_eqn), {}) :: slices;
      end for;
      slices := listReverse(slices);
    end if;
  end scalarSlices;

  function isLinearSlice
    "local, differentiation-based linearity check for a single equation against a
    list of crefs, for use where no adjacency-matrix solvability info is available
    (see checkLinearity for the normal, matrix-based version). Linear iff no
    partial derivative w.r.t. one of the crefs still contains any of them --
    catches both self- (x^2) and cross- (x*y) nonlinearity."
    input Pointer<Equation> eqn_ptr;
    input list<ComponentRef> crefs;
    input UnorderedMap<Path, Function> funcMap;
    output Boolean linear = true;
  protected
    Option<Expression> residual_opt = Equation.tryGetResidualExp(eqn_ptr);
    Expression residual;
    Differentiate.DifferentiationArguments diffArgs;
    Expression derivative;
  algorithm
    if isSome(residual_opt) then
      SOME(residual) := residual_opt;
      try
        for cref in crefs loop
          diffArgs := Differentiate.DifferentiationArguments.simpleCref(cref, funcMap);
          (derivative, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
          for other in crefs loop
            if Expression.containsCref(derivative, other) then
              linear := false;
            end if;
          end for;
        end for;
      else
        // not everything can be differentiated, e.g. functions with function inputs
        linear := false;
      end try;
    else
      // no residual could be constructed at all (e.g. a record type such as a
      // Medium's ThermodynamicState with no '+'/'-'/'0' operators, see
      // Equation.getResidualExp) -- can't check, so assume the conservative
      // (nonlinear) default instead of crashing the whole compilation.
      linear := false;
    end if;
  end isLinearSlice;

  function getModule
    "Returns the module function that was chosen by the user."
    output list<Module.tearingInterface> funcs;
  protected
    String flag = Flags.getConfigString(Flags.TEARING_METHOD);
    function isNotGuruVar extends BVariable.checkVar;
      input Boolean init;
    algorithm
      b := BVariable.hasTearingSelect(var_ptr, NFBackendExtension.TearingSelect.PREFER, intLt);
    end isNotGuruVar;
  algorithm
    funcs := match flag
      case "minimalTearing" then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize};
      case "cellier"        then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize}; // TODO set `minimal = false` when it's actually doing something
      case "omcTearing"     then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize}; // TODO set `minimal = false` when it's actually doing something
      case "guruTearing"    then {function initialize(varFunc = isNotGuruVar, eqnFunc = noFilterEqn), guru, finalize};
      /* ... New tearing modules have to be added here */
      else fail();
    end match;
  end getModule;

  function getVariables
    input Tearing tearing;
    output list<Pointer<Variable>> variables;
  algorithm
     variables := listAppend(var for var in list(Slice.getT(var) for var in tearing.iteration_vars) :: list(StrongComponent.getVariables(comp) for comp in tearing.innerEquations));
  end getVariables;

  function getResidualVars
    input Tearing tearing;
    output list<Pointer<Variable>> residuals = list(Equation.getResidualVar(Slice.getT(eqn)) for eqn in tearing.residual_eqns);
  end getResidualVars;

  function getIterationVars
    input Tearing tearing;
    output list<Pointer<Variable>> iterationVars = list(Slice.getT(var) for var in tearing.iteration_vars);
  end getIterationVars;

  function getResidualEqns
    input Tearing tearing;
    output list<Pointer<Equation>> residuals = list(Slice.getT(eqn) for eqn in tearing.residual_eqns);
  end getResidualEqns;

  function setResidualEqns
    input output Tearing tearing;
    input list<Slice<EquationPointer>> residuals;
  algorithm
    tearing.residual_eqns := residuals;
  end setResidualEqns;

protected
  // Traverser function
  function tearingTraverser
    input list<Partition.Partition> partitions;
    input list<Module.tearingInterface> funcs;
    output list<Partition.Partition> new_partitions = {};
    input UnorderedMap<Path, Function> funcMap;
    input Pointer<Integer> eq_index;
    input Partition.Kind kind;
  protected
    array<StrongComponent> strongComponents;
    StrongComponent tmp;
    Integer idx = 0;
    Adjacency.Matrix full "full adjacency matrix containing solvability info";
  algorithm
    for part in partitions loop
      if isSome(part.strongComponents) and isSome(part.adjacencyMatrix) then
        SOME(strongComponents) := part.strongComponents;
        SOME(full) := part.adjacencyMatrix;
        for i in 1:arrayLength(strongComponents) loop
          // each module has a list of functions that need to be applied
          tmp := strongComponents[i];
          for func in funcs loop
            (tmp, full, idx) := func(tmp, full, funcMap, idx, part.unknowns, part.equations, eq_index, kind);
          end for;
          // only update if it changed
          if not referenceEq(tmp, strongComponents[i]) then
            arrayUpdate(strongComponents, i, tmp);
          end if;
        end for;
        part.strongComponents := SOME(strongComponents);
        part.adjacencyMatrix := SOME(full);
      end if;
      new_partitions := part :: new_partitions;
    end for;
    new_partitions := listReverse(new_partitions);
  end tearingTraverser;

  function noFilterVar extends BVariable.checkVar;
    input Boolean init;
  algorithm
    b := true;
  end noFilterVar;

  function noFilterEqn extends BEquation.checkEqn;
  algorithm
    b := true;
  end noFilterEqn;

  function tolerantSubMap
    "Like UnorderedMap.subMap, but silently skips keys that don't exist in
     map instead of crashing (UnorderedMap.subMap uses getSafe)."
    input UnorderedMap<ComponentRef, Integer> map;
    input list<ComponentRef> lst;
    output UnorderedMap<ComponentRef, Integer> sub_map =
      UnorderedMap.subMap(map, list(k for k guard UnorderedMap.contains(k, map) in lst));
  end tolerantSubMap;

  function initialize
    extends Module.tearingInterface;
    input checkVarInit varFunc = noFilterVar;
    input BEquation.checkEqn eqnFunc = noFilterEqn;
    // varFunc/eqnFunc kept for API compatibility with getModule()'s partial applications,
    // but no longer consulted below (see comment further down).
    partial function checkVarInit extends BVariable.checkVar;
      input Boolean init;
    end checkVarInit;
  protected
    Tearing strict;
    list<ComponentRef> all_vars_lst, all_eqns_lst;
    UnorderedSet<ComponentRef> vars_set        "all loop vars, used by refine to detect self-referential (nonlinear) dependencies";
    UnorderedMap<ComponentRef, Integer> v_all, e_all "unfiltered loop vars/equations map";
  algorithm
    (comp, full, index) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        index := index + 1;
        comp.idx := index;

        // refine and checkLinearity both need the loop's full, unfiltered var/eqn set --
        // varFunc/eqnFunc's filtered one is often EMPTY for a purely continuous loop,
        // which silently misclassified such loops as linear (see #16463). Tolerant
        // lookup: not every name here is necessarily registered in variables.map/
        // equations.map yet.
        all_vars_lst := list(BVariable.getVarName(Slice.getT(var)) for var in strict.iteration_vars);
        all_eqns_lst := list(Equation.getEqnName(Slice.getT(eqn)) for eqn in strict.residual_eqns);
        vars_set := UnorderedSet.fromList(all_vars_lst, ComponentRef.hash, ComponentRef.isEqual);
        v_all := tolerantSubMap(variables.map, all_vars_lst);
        e_all := tolerantSubMap(equations.map, all_eqns_lst);

        // refine the adjacency matrix by updating solvability information
        full := Adjacency.Matrix.refine(full, funcMap, v_all, e_all, variables, equations, vars_set, Partition.kindIsInitial(kind));

        comp.linear := checkLinearity(full, v_all, e_all);
      then (comp, full, index);
      else (comp, full, index);
    end match;
  end initialize;

  function isPartialVarSlice
    input Slice<VariablePointer> var;
    output Boolean b = not listEmpty(var.indices) and BVariable.size(Slice.getT(var)) > listLength(var.indices);
  end isPartialVarSlice;

  function isPartialArraySlice
    input Slice<EquationPointer> eqn;
    output Boolean b = not listEmpty(eqn.indices) and (Equation.isArrayEquation(Slice.getT(eqn)) or Equation.isSingleBodyFor(Pointer.access(Slice.getT(eqn))))
                       and Equation.size(Slice.getT(eqn)) > listLength(eqn.indices);
  end isPartialArraySlice;

  function isArrayBodyFor
    "a for equation with an array body, its residual rows are split (codegen writes them per iteration)"
    input Slice<EquationPointer> eqn;
    output Boolean b;
  algorithm
    b := match Pointer.access(Slice.getT(eqn))
      local
        Equation body;
      case Equation.FOR_EQUATION(body = {body}) then Type.isArray(Equation.getType(body));
      else false;
    end match;
  end isArrayBodyFor;

  function finalize extends Module.tearingInterface;
  protected
    Tearing strict;
    Boolean partial_vars;
    list<list<Slice<EquationPointer>>> acc;
    UnorderedSet<VariablePointer> dummy_set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // inline potential records
        acc := list(Inline.inlineRecordSliceEquation(eqn, variables, dummy_set, eq_index, true) for eqn in strict.residual_eqns);

        // create residual equations, a part of an array equation needs residual variables for its rows only.
        // for equations are also split into rows if an iteration variable is only partially part of the loop,
        // otherwise the jacobian can not differentiate them w.r.t. single elements of that variable.
        partial_vars := List.any(strict.iteration_vars, isPartialVarSlice);
        strict.residual_eqns  := list(Slice.apply(eqn, function Equation.createResidual(residualCref_opt = NONE(), new = true, allowFail = false))
          for eqn in List.flatten(list(if isPartialArraySlice(eqn) or isArrayBodyFor(eqn) or (partial_vars and Equation.isSingleBodyFor(Pointer.access(Slice.getT(eqn))))
            then scalarSlices(eqn) else {eqn} for eqn in List.flatten(acc))));
        comp.strict := strict;

        if Flags.isSet(Flags.TEARING_DUMP) then
          print(StringUtil.headline_2("[" + Partition.Partition.kindToString(kind) + "] Tearing Result " + intString(comp.idx)) + "\n" + StrongComponent.toString(comp) + "\n");
        end if;
      then comp;
      else comp;
    end match;
  end finalize;

  function minimal extends Module.tearingInterface;
    // only extracts discrete variables to be solved as inner equations
  protected
    Tearing strict, innerStrict;
    list<Pointer<Variable>> vars_lst, cont_vars, disc_vars, implied_vars, alg_implied;
    list<Pointer<Equation>> eqns_lst, cont_eqns, disc_eqns, alg_eqns;
    Integer num_vars, num_eqns;
    list<Slice<VariablePointer>> iteration_vars = {};
    Adjacency.Matrix adj, sub;
    Matching matching;
    list<StrongComponent> inner_comps;
    VariablePointers disc_variables;
    EquationPointers disc_equations;
    UnorderedSet<ComponentRef> matched_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // split equations and variables for discretes and continuous
        vars_lst := list(Slice.getT(var) for var in strict.iteration_vars);
        eqns_lst := list(Slice.getT(eqn) for eqn in strict.residual_eqns);
        (cont_vars, disc_vars) := filterDiscreteVariables(vars_lst, Partition.kindIsInitial(kind));
        (cont_eqns, disc_eqns) := List.splitOnTrue(eqns_lst, Equation.isContinousRecordAware);
        // extract continuous algorithm equations; they have implied inner variables and cannot be residuals
        (alg_eqns, cont_eqns) := List.splitOnTrue(cont_eqns, Equation.isAlgorithm);

        // get the implied vars by algorithms and tuples (from both alg_eqns and disc_eqns)
        implied_vars := List.flatten(list(getImpliedInnerVars(eqn) for eqn in listAppend(alg_eqns, disc_eqns)));
        disc_vars := UnorderedSet.unique_list(listAppend(disc_vars, implied_vars), BVariable.hash, BVariable.equalName);
        cont_vars := UnorderedSet.difference_list(cont_vars, implied_vars, BVariable.hash, BVariable.equalName);

        num_vars := sum(BVariable.size(var) for var in disc_vars);
        num_eqns := sum(Equation.size(eqn) for eqn in disc_eqns) + sum(Equation.size(eqn) for eqn in alg_eqns);

        // do nothing if there are no discrete or algorithm equations
        if not (listEmpty(disc_eqns) and listEmpty(alg_eqns)) then
          comp.mixed := true;
          inner_comps := {};

          // algorithm equations: create MULTI_COMPONENTs directly with ALL outputs as inner variables
          // (they cannot be residuals and have multiple outputs, so standard 1:1 matching is wrong)
          for alg_eqn in alg_eqns loop
            alg_implied := getImpliedInnerVars(alg_eqn);
            for var in alg_implied loop
              UnorderedSet.add(BVariable.getVarName(var), matched_set);
            end for;
            inner_comps := StrongComponent.MULTI_COMPONENT(
              list(Slice.SLICE(var, {}) for var in alg_implied),
              Slice.SLICE(alg_eqn, {}),
              NBSolve.Status.UNPROCESSED
            ) :: inner_comps;
          end for;

          if not listEmpty(disc_eqns) then
            // local system of the discrete variables and equations, in the order of the full system
            disc_vars := sortByIndex(list(var for var guard(not UnorderedSet.contains(BVariable.getVarName(var), matched_set)) in disc_vars), BVariable.getVarName, variables.map);
            disc_eqns := sortByIndex(disc_eqns, Equation.getEqnName, equations.map);
            disc_variables := VariablePointers.fromList(disc_vars);
            disc_equations := EquationPointers.fromList(disc_eqns);
            sub := Adjacency.Matrix.subFull(full, list(UnorderedMap.getSafe(Equation.getEqnName(eqn), equations.map, sourceInfo()) for eqn in disc_eqns), disc_equations, disc_variables);

            // match the discretes to create inner components
            adj         := Adjacency.Matrix.fullToFinal(sub, disc_variables.map, disc_equations.map, disc_equations, NBAdjacency.MatrixStrictness.MATCHING);
            matching    := Matching.regular(NBMatching.EMPTY_MATCHING, adj, true, true);

            // build the matched variables set
            for var in Matching.getMatchedVars(matching, Adjacency.Matrix.getMappingOpt(adj), disc_variables.map, disc_variables) loop
              UnorderedSet.add(BVariable.getVarName(var), matched_set);
            end for;

            // upgrade adjacency matrix and sort the system creating inner equation components
            adj         := Adjacency.Matrix.upgrade(adj, sub, disc_variables.map, disc_equations.map, disc_equations, NBAdjacency.MatrixStrictness.SORTING);
            inner_comps := listAppend(Sorting.tarjan(adj, matching, disc_variables, disc_equations), inner_comps);
          end if;

          // only take variables that are not in the matched set
          for var in strict.iteration_vars loop
            if not UnorderedSet.contains(BVariable.getVarName(Slice.getT(var)), matched_set) then
              iteration_vars := var :: iteration_vars;
            end if;
          end for;

          strict.innerEquations := listArray(inner_comps);
          strict.residual_eqns  := list(Slice.SLICE(eqn, {}) for eqn in cont_eqns);
          strict.iteration_vars := listReverse(iteration_vars);
          comp.strict := strict;
        end if;
      then comp;
      else comp;
    end match;
  end minimal;

  function sortByIndex<T>
    "sorts the elements by their index in the map"
    input list<T> lst;
    input getName func;
    input UnorderedMap<ComponentRef, Integer> map;
    output list<T> sorted;
    partial function getName
      input T t;
      output ComponentRef name;
    end getName;
  protected
    list<tuple<Integer, T>> indexed = list((UnorderedMap.getSafe(func(t), map, sourceInfo()), t) for t in lst);
  algorithm
    indexed := List.sort(indexed, function Util.compareTupleIntGt());
    sorted := list(Util.tuple22(tpl) for tpl in indexed);
  end sortByIndex;

  function guru extends Module.tearingInterface;
  protected
    list<StrongComponent> inner_comps = {};
    list<EqnSlice> residuals = {};
    Tearing strict;
    Integer nEqn;
    list<VarSlice> inner_vars, guru_vars, failed_vars;
    UnorderedMap<ComponentRef, VarSlice> unsolved_inner_vars;
    UnorderedMap<ComponentRef, EqnSlice> unsolved_equations;
    Option<ComponentRef> solve_opt;
    ComponentRef solve_cref;
    VarSlice solve_var;
    EqnSlice solve_eqn;
    Boolean success, var_assigned;
    ComponentRef stripped;
    constant Boolean staticAsContinuous = Partition.kindIsInitial(kind);
  algorithm
    comp := match (comp, full)
      case (StrongComponent.ALGEBRAIC_LOOP(strict = strict), Adjacency.FULL()) algorithm
        nEqn := arrayLength(full.equation_names);

        // split variables to inner variables and guru iteration vars
        (inner_vars, guru_vars) := List.splitOnTrue(strict.iteration_vars,
          function Slice.check(func = function BVariable.hasTearingSelect(compareTS = NFBackendExtension.TearingSelect.PREFER, func = intLt)));

        if listEmpty(guru_vars) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. No guru variables provided for strong component:\n"
            + StrongComponent.toString(comp)});
          fail();
        else
          failed_vars := list(var for var guard(Slice.check(var, function NBVariable.isDiscontinuous(staticAsContinuous = staticAsContinuous))) in guru_vars);
          if not listEmpty(failed_vars) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Following variables cannot be chosen as iteration variables because they are discontinuous:\n"
              + List.toString(failed_vars, function Slice.toString(func = BVariable.pointerToString, maxLength = 10), List.Style.NEWLINE_TAB)});
            fail();
          end if;

          // collect the (yet) unsolved inner vars as a map of their name to their variable slice
          // at the end of the algorithm this set has to be empty
          unsolved_inner_vars := UnorderedMap.new<VarSlice>(ComponentRef.hash, ComponentRef.isEqual);
          for var in inner_vars loop
            UnorderedMap.add(BVariable.getVarName(Slice.getT(var)), var, unsolved_inner_vars);
          end for;

          // collect the (yet) unsolved equations. all remaining at the end will be residual
          unsolved_equations := UnorderedMap.new<EqnSlice>(ComponentRef.hash, ComponentRef.isEqual);
          for eqn in strict.residual_eqns loop
            UnorderedMap.add(Equation.getEqnName(Slice.getT(eqn)), eqn, unsolved_equations);
          end for;

          // main routine finding the inner variable and equation pairs
          while(not UnorderedMap.isEmpty(unsolved_inner_vars)) loop
            for i in 1:nEqn loop
              var_assigned := false;
              if UnorderedMap.contains(full.equation_names[i], unsolved_equations) then
                solve_opt := NONE();
                success := false;
                for cref in UnorderedSet.toList(full.occurrences[i]) loop
                  stripped := ComponentRef.stripSubscriptsAll(cref);
                  if UnorderedMap.contains(stripped, unsolved_inner_vars) then
                    if isNone(solve_opt) then
                      success := true;
                      solve_opt := SOME(cref);
                    else
                      success := false;
                      break;
                    end if;
                  end if;
                end for;

                // ToDo: multi-components (algorithms)
                ():= match (solve_opt, success)
                  // case I: possibly solvable as inner. check if the full cref can be solved
                  case (SOME(solve_cref), true) algorithm
                    // ToDo: for now assume it can be fully solved, needs to be checked!
                    // ToDo: check solvability? --> if not linear then fail or check strictness
                    stripped    := ComponentRef.stripSubscriptsAll(solve_cref);
                    solve_var   := UnorderedMap.getSafe(stripped, unsolved_inner_vars, sourceInfo());
                    solve_eqn   := UnorderedMap.getSafe(full.equation_names[i], unsolved_equations, sourceInfo());
                    inner_comps := StrongComponent.createSliceOrSingle(solve_cref, solve_var, solve_eqn) :: inner_comps;

                    // remove the variable and equation from candidates
                    UnorderedMap.remove(stripped, unsolved_inner_vars);
                    UnorderedMap.remove(full.equation_names[i], unsolved_equations);
                    var_assigned := true;
                  then ();

                  // case II: more than one inner found, just skip and do nothing until this might be solvable later
                  case (SOME(solve_cref), false) then ();

                  // case III: none found, has to be residual
                  case (NONE(), false) algorithm
                    residuals := UnorderedMap.getSafe(full.equation_names[i], unsolved_equations, sourceInfo()) :: residuals;
                    UnorderedMap.remove(full.equation_names[i], unsolved_equations);
                  then ();

                  // FAIL: algorithm should not be able to produce this impossible combination
                  else algorithm
                    Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Impossible result for equation representative: "
                      + ComponentRef.toString(full.equation_names[i]) + "."});
                  then ();
                end match;
              end if;
              if var_assigned then break; end if;
            end for;

            // if not variable could be assigned in a full circle of checking all equations the problem is impossible to solve
            if not var_assigned then
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Following variables could not be solved as inner variables:\n"
                + List.toString(UnorderedMap.valueList(unsolved_inner_vars), function Slice.toString(func = BVariable.pointerToString, maxLength = 10), List.Style.NEWLINE_TAB)});
              fail();
            end if;
          end while;

          comp.mixed := List.any(inner_vars, function Slice.check(func = function BVariable.isDiscontinuous(staticAsContinuous = staticAsContinuous)));

          // save residuals equations and iteration variables to the strong component
          strict.innerEquations := listArray(listReverse(inner_comps));
          strict.residual_eqns  := listAppend(UnorderedMap.valueList(unsolved_equations), residuals);
          strict.iteration_vars := guru_vars;
          comp.strict := strict;
        end if;

      then comp;
      else comp;
    end match;
  end guru;

  function checkLinearity
    input Adjacency.Matrix full;
    input UnorderedMap<ComponentRef, Integer> v "variables in the algebraic loop";
    input UnorderedMap<ComponentRef, Integer> e "equations in the algebraic loop";
    output Boolean linear;
  protected
    function varIsLinear
      input ComponentRef var;
      input UnorderedMap<ComponentRef, Integer> v;
      input UnorderedMap<ComponentRef, Solvability> sol;
      output Boolean b = not (UnorderedMap.contains(var, v) and Solvability.isNonlinearOrImplicit(UnorderedMap.getSafe(var, sol, sourceInfo())));
    end varIsLinear;

    function eqnIsLinear
      input Integer i "equation index";
      input array<UnorderedSet<ComponentRef>> occ;
      input array<UnorderedMap<ComponentRef, Solvability>> sol;
      input UnorderedMap<ComponentRef, Integer> v;
      output Boolean b = UnorderedSet.all(occ[i], function varIsLinear(v = v, sol = sol[i]));
    end eqnIsLinear;
  algorithm
    linear := match full
      case Adjacency.Matrix.FULL() then UnorderedMap.all(e, function eqnIsLinear(occ = full.occurrences, sol = full.solvabilities, v = v));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + Adjacency.strictnessString(Adjacency.Matrix.getStrictness(full)) + "."});
      then fail();
    end match;
  end checkLinearity;

  function filterDiscreteVariables
    "splits off all discrete variables. also splits off variables that belong to a record with a discrete variable in this algebraic loop"
    input list<Pointer<Variable>> vars_lst;
    input Boolean staticAsContinuous;
    output list<Pointer<Variable>> cont_vars;
    output list<Pointer<Variable>> disc_vars;
  protected
    UnorderedSet<ComponentRef> discrete_records = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    list<Pointer<Variable>> rec_disc_vars;

    function addDiscreteRecord
      "checks if it has a record parent that needs to be added"
      input Pointer<Variable> var;
      input UnorderedSet<ComponentRef> discrete_records;
    algorithm
      () := match BVariable.getParent(var)
        local
          Pointer<Variable> parent;
        case SOME(parent) algorithm
          UnorderedSet.add(BVariable.getVarName(parent), discrete_records);
          addDiscreteRecord(parent, discrete_records);
        then ();
        else ();
      end match;
    end addDiscreteRecord;

    function checkDiscreteRecord
      "checks if continuous variable is part of records of which discretes are in this loop"
      input Pointer<Variable> var;
      input UnorderedSet<ComponentRef> discrete_records;
      input Boolean is_parent;
      output Boolean b;
    algorithm
      b := match BVariable.getParent(var)
        local
          Pointer<Variable> parent;
        case SOME(parent) then checkDiscreteRecord(parent, discrete_records, true);
        else is_parent and UnorderedSet.contains(BVariable.getVarName(var), discrete_records);
      end match;
    end checkDiscreteRecord;
  algorithm
    // basic filter all discrete variables
    (cont_vars, disc_vars) := List.splitOnTrue(vars_lst, function BVariable.isContinuous(staticAsContinuous = staticAsContinuous));
    // add all records that contain discrete variables
    for var in disc_vars loop addDiscreteRecord(var, discrete_records); end for;
    // split off all variables that are part of records of which discretes are in this loop
    (rec_disc_vars, cont_vars) := List.splitOnTrue(cont_vars, function checkDiscreteRecord(discrete_records = discrete_records, is_parent = false));

    // add the continous record variables that might be solved alongside discretes to the list
    disc_vars := listReverse(listAppend(rec_disc_vars, disc_vars));
  end filterDiscreteVariables;

  function getImpliedInnerVars
    "returns all implied inner variables if the equation is solved. necessary if e.g. trying to solve a single discrete output
    from an algorithm. The full algorithm and all outputs need to be made inner variables."
    input Pointer<Equation> eqn;
    output list<Pointer<Variable>> vars;
  algorithm
    vars := match Pointer.access(eqn)
      local
        Algorithm alg;
        Expression tpl;

      case Equation.ALGORITHM(alg = alg) algorithm
        vars := list(BVariable.getVarPointer(out_cr, sourceInfo()) for out_cr in alg.outputs);
      then vars;

      case Equation.RECORD_EQUATION(lhs = tpl as Expression.TUPLE()) algorithm
      then list(BVariable.getVarPointer(tpl_cr, sourceInfo()) for tpl_cr in UnorderedSet.toList(Expression.extractCrefs(tpl)));

      case Equation.RECORD_EQUATION(lhs = Expression.CREF()) algorithm
        // ToDo: if vars contains any child of cref add all children of cref
      then {};

      else {};
    end match;
  end getImpliedInnerVars;

  annotation(__OpenModelica_Interface="nbackend");
end NBTearing;
