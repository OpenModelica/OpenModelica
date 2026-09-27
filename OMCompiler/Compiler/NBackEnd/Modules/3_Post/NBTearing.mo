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
  import ErrorExt;

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

  function containsNamedCref
    input Expression exp;
    input UnorderedSet<ComponentRef> names;
    input output Boolean b;
  algorithm
    b := match (b, exp)
      case (false, Expression.CREF()) then UnorderedSet.contains(ComponentRef.stripSubscriptsAll(exp.cref), names);
      else b;
    end match;
  end containsNamedCref;

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
    UnorderedSet<ComponentRef> names = UnorderedSet.fromList(list(ComponentRef.stripSubscriptsAll(c) for c in crefs), ComponentRef.hash, ComponentRef.isEqual);
    list<ComponentRef> occurrences;
  algorithm
    if isSome(residual_opt) then
      SOME(residual) := residual_opt;
      // differentiate w.r.t. the crefs as they occur (e.g. x[$i1, :] in a for equation), the elements would give zero
      occurrences := list(c for c guard(UnorderedSet.contains(ComponentRef.stripSubscriptsAll(c), names)) in UnorderedSet.toList(Expression.extractCrefs(residual)));
      if listEmpty(occurrences) then
        occurrences := crefs;
      end if;
      try
        for cref in occurrences loop
          diffArgs := Differentiate.DifferentiationArguments.simpleCref(cref, funcMap);
          (derivative, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
          if Expression.fold(derivative, function containsNamedCref(names = names), false) then
            linear := false;
          end if;
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
      case "cellier"        then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, cellier, finalize};
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

  function cellier extends Module.tearingInterface;
    // Cellier style tearing of what minimal tearing left over. Variables are only assigned as a whole
    // (the part of them that is in the loop), so arrays and records are never split any further.
    // The inner components of minimal tearing are kept as they are.
  protected
    Tearing strict;
  algorithm
    comp := match (comp, full)
      case (StrongComponent.ALGEBRAIC_LOOP(strict = strict), Adjacency.FULL())
        guard(not listEmpty(strict.iteration_vars) and not listEmpty(strict.residual_eqns)) algorithm
        comp.strict := cellierTearingSet(strict, full, equations, funcMap);
      then comp;
      else comp;
    end match;
  end cellier;

  function cellierHasRow
    input Pointer<Equation> eqn;
    input UnorderedMap<ComponentRef, Integer> map;
    output Boolean b = UnorderedMap.contains(Equation.getEqnName(eqn), map);
  end cellierHasRow;

  function cellierTearingSet
    input output Tearing strict;
    input Adjacency.Matrix full;
    input EquationPointers equations;
    input UnorderedMap<Path, Function> funcMap;
  protected
    UnorderedMap<Integer, Boolean> probes = UnorderedMap.new<Boolean>(Util.id, intEq);
    list<Pointer<Variable>> loop_vars, block_vars = {};
    list<Pointer<Equation>> loop_eqns;
    VariablePointers vars;
    EquationPointers eqns;
    Adjacency.Matrix adj;
    Adjacency.Mapping mapping;
    Integer nv, ne, nb, idx, start, size;
    array<Integer> unit_kind, eqn_glob, owner, eqn_step, row_var, block_step;
    array<Slice<VariablePointer>> var_slices;
    array<Slice<EquationPointer>> eqn_slices;
    array<list<Integer>> block_in, block_out, eqn_rows, eqn_units;
    array<StrongComponent> blocks;
    list<Integer> tears, fixed = {}, trial;
    Option<Integer> opt_idx;
    Boolean complete;
    list<tuple<Integer, StrongComponent>> ordered = {};
    UnorderedSet<Integer> tear_set;
    array<UnorderedSet<ComponentRef>> occurrences;
    array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    Slice<EquationPointer> eqn_slice;
  algorithm
    () := match full
      case Adjacency.FULL() algorithm
        occurrences := full.occurrences;
        solvabilities := full.solvabilities;
      then ();
      else fail();
    end match;
    blocks := strict.innerEquations;
    nb := arrayLength(blocks);
    loop_vars := list(Slice.getT(var) for var in strict.iteration_vars);
    for b in nb:-1:1 loop
      block_vars := listAppend(StrongComponent.getVariables(blocks[b]), block_vars);
    end for;
    loop_eqns := list(Slice.getT(eqn) for eqn in strict.residual_eqns);
    vars := VariablePointers.fromList(listAppend(loop_vars, block_vars));
    eqns := EquationPointers.fromList(loop_eqns);
    nv := VariablePointers.size(vars);
    ne := EquationPointers.size(eqns);
    // a variable or equation that occurs more than once can not be handled as one unit
    if nv <> listLength(loop_vars) + listLength(block_vars) or ne <> listLength(loop_eqns) then
      return;
    end if;
    // equations without adjacency row (not in the equation map) can not be handled
    for b in 1:nb loop
      loop_eqns := listAppend(StrongComponent.getEquations(blocks[b]), loop_eqns);
    end for;
    if not List.all(loop_eqns, function cellierHasRow(map = equations.map)) then
      return;
    end if;
    loop_eqns := list(Slice.getT(eqn) for eqn in strict.residual_eqns);

    // unit kinds: 1 = loop variable, 3 = solved by a block of minimal tearing
    unit_kind := arrayCreate(nv, 3);
    var_slices := arrayCreate(nv, listHead(strict.iteration_vars));
    for var in strict.iteration_vars loop
      idx := UnorderedMap.getSafe(BVariable.getVarName(Slice.getT(var)), vars.map, sourceInfo());
      unit_kind[idx] := 1;
      var_slices[idx] := var;
      if Integer(BVariable.getTearingSelect(Slice.getT(var))) == Integer(NFBackendExtension.TearingSelect.ALWAYS) then
        fixed := idx :: fixed;
      end if;
    end for;

    // scalar adjacency of the leftover system, only the rows of the loop count
    eqn_glob := listArray(list(UnorderedMap.getSafe(Equation.getEqnName(eqn), equations.map, sourceInfo()) for eqn in loop_eqns));
    adj := Adjacency.Matrix.subFull(full, arrayList(eqn_glob), eqns, vars);
    adj := Adjacency.Matrix.fullToFinal(adj, vars.map, eqns.map, eqns, NBAdjacency.MatrixStrictness.SORTING);
    mapping := Util.getOption(Adjacency.Matrix.getMappingOpt(adj));
    eqn_slices := listArray(strict.residual_eqns);
    eqn_rows := arrayCreate(ne, {});
    for i in 1:ne loop
      eqn_slice := eqn_slices[i];
      (start, size) := mapping.eqn_AtS[i];
      eqn_rows[i] := if listEmpty(eqn_slice.indices) then list(start + k for k in 0:size - 1)
        else list(start + k for k in List.sort(eqn_slice.indices, intGt));
    end for;

    // blocks of minimal tearing keep their order, they wait for the loop variables they depend on
    owner := arrayCreate(nv, 0);
    block_in := arrayCreate(nb, {});
    block_out := arrayCreate(nb, {});
    for b in 1:nb loop
      block_out[b] := list(UnorderedMap.getSafe(BVariable.getVarName(v), vars.map, sourceInfo()) for v in StrongComponent.getVariables(blocks[b]));
      for o in block_out[b] loop owner[o] := b; end for;
    end for;
    for b in 1:nb loop
      for eqn in StrongComponent.getEquations(blocks[b]) loop
        for cref in UnorderedSet.toList(occurrences[UnorderedMap.getSafe(Equation.getEqnName(eqn), equations.map, sourceInfo())]) loop
          opt_idx := UnorderedMap.get(ComponentRef.stripSubscriptsAll(cref), vars.map);
          if isSome(opt_idx) then
            SOME(idx) := opt_idx;
            if owner[idx] < b and not listMember(idx, block_in[b]) then
              block_in[b] := idx :: block_in[b];
            end if;
          end if;
        end for;
      end for;
    end for;

    // greedy tearing, then try to remove every tear variable again, biggest first
    (tears, _, _, _, _, _) := cellierCausalize(fixed, true, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, funcMap, probes);
    for t in List.sort(tears, function cellierSizeLess(var_slices = var_slices)) loop
      if not listMember(t, fixed) then
        trial := list(i for i guard(i <> t) in tears);
        (_, _, _, _, _, complete) := cellierCausalize(trial, false, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, funcMap, probes);
        if complete then tears := trial; end if;
      end if;
    end for;
    (tears, eqn_step, eqn_units, row_var, block_step, complete) := cellierCausalize(tears, false, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, funcMap, probes);

    if not complete or Array.all(eqn_step, function intEq(i2 = 0)) then
      return;
    end if;

    // new inner components in causal order, interleaved with the blocks of minimal tearing
    for i in 1:ne loop
      if eqn_step[i] > 0 then
        ordered := (eqn_step[i], cellierComponent(i, eqn_units[i], eqn_rows[i], row_var, mapping, vars, eqns, var_slices, eqn_slices, solvabilities[eqn_glob[i]])) :: ordered;
      end if;
    end for;
    for b in 1:nb loop
      ordered := (block_step[b], blocks[b]) :: ordered;
    end for;
    ordered := List.sort(ordered, function Util.compareTupleIntGt());

    tear_set := UnorderedSet.fromList(tears, Util.id, intEq);
    strict.innerEquations := listArray(list(Util.tuple22(tpl) for tpl in ordered));
    strict.iteration_vars := list(var for var guard(UnorderedSet.contains(UnorderedMap.getSafe(BVariable.getVarName(Slice.getT(var)), vars.map, sourceInfo()), tear_set)) in strict.iteration_vars);
    strict.residual_eqns  := list(eqn for eqn guard(eqn_step[UnorderedMap.getSafe(Equation.getEqnName(Slice.getT(eqn)), eqns.map, sourceInfo())] == 0) in strict.residual_eqns);
  end cellierTearingSet;

  function cellierComponent
    "creates the inner component of an assignment like sorting does"
    input Integer e;
    input list<Integer> units;
    input list<Integer> rows;
    input array<Integer> row_var;
    input Adjacency.Mapping mapping;
    input VariablePointers vars;
    input EquationPointers eqns;
    input array<Slice<VariablePointer>> var_slices;
    input array<Slice<EquationPointer>> eqn_slices;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    output StrongComponent comp;
  protected
    Integer u;
    ComponentRef name;
  algorithm
    if not List.hasOneElement(units) then
      comp := StrongComponent.MULTI_COMPONENT(list(var_slices[i] for i in units), eqn_slices[e], NBSolve.Status.UNPROCESSED);
    elseif List.hasOneElement(rows) then
      comp := StrongComponent.createPseudoScalar(rows, row_var, mapping, vars, eqns);
    else
      u := listHead(units);
      name := BVariable.getVarName(VariablePointers.getVarAt(vars, u));
      comp := StrongComponent.createPseudoSlice(u, e, listHead(cellierOccurrences(name, solvabilities)), rows, row_var, eqns, mapping,
        Equation.isArrayEquation(EquationPointers.getEqnAt(eqns, e)));
    end if;
  end cellierComponent;

  function cellierSizeLess
    "sorts bigger units first"
    input Integer u1;
    input Integer u2;
    input array<Slice<VariablePointer>> var_slices;
    output Boolean b = Slice.size(var_slices[u1], function BVariable.size(resize = false)) < Slice.size(var_slices[u2], function BVariable.size(resize = false));
  end cellierSizeLess;

  function cellierCausalize
    "causalizes the leftover system for the given tear variables. greedy chooses new tear
    variables whenever it gets stuck, otherwise it stops and reports the system incomplete."
    input list<Integer> fixed_tears;
    input Boolean greedy;
    input Adjacency.Matrix adj;
    input VariablePointers vars;
    input EquationPointers eqns;
    input array<Integer> eqn_glob;
    input array<list<Integer>> eqn_rows;
    input array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    input array<Integer> unit_kind;
    input array<Slice<VariablePointer>> var_slices;
    input array<list<Integer>> block_in;
    input array<list<Integer>> block_out;
    input UnorderedMap<Path, Function> funcMap;
    input UnorderedMap<Integer, Boolean> probes "cached solver checks";
    output list<Integer> tears = fixed_tears;
    output array<Integer> eqn_step;
    output array<list<Integer>> eqn_units;
    output array<Integer> row_var;
    output array<Integer> block_step;
    output Boolean complete = true;
  protected
    Adjacency.IntMatrix m, mT;
    Adjacency.Mapping mapping;
    array<Integer> m_data, mT_data, unknown_rem, eqn_unknown, eqn_size, stamp;
    array<Boolean> known_scal, row_in_loop;
    array<list<tuple<Integer, list<Integer>>>> ready = arrayCreate(4, {});
    array<list<Integer>> partial_eqns;
    array<Integer> partial_cov, partial_rank, cover_owner;
    Boolean is_partial, overlap;
    Integer nv, ne, nb = arrayLength(block_in), start, size, open_units = 0, step = 0, next_block = 1, stamp_id = 0;
    Integer rank, best = 0, u;
    list<Integer> fresh = {}, units = {};
    Boolean found;
    Slice<VariablePointer> slice;
  algorithm
    () := match adj
      case Adjacency.Matrix.FINAL() algorithm
        m := adj.m; mT := adj.mT; mapping := adj.mapping;
      then ();
      else fail();
    end match;
    m_data := Adjacency.IntMatrix.entries(m);
    mT_data := Adjacency.IntMatrix.entries(mT);
    nv := arrayLength(mapping.var_AtS);
    ne := arrayLength(mapping.eqn_AtS);
    eqn_step := arrayCreate(ne, 0);
    eqn_units := arrayCreate(ne, {});
    row_var := arrayCreate(arrayLength(mapping.eqn_StA), -1);
    block_step := arrayCreate(nb, 0);
    stamp := arrayCreate(arrayLength(mapping.var_StA), 0);
    partial_eqns := arrayCreate(nv, {});
    partial_cov := arrayCreate(nv, 0);
    partial_rank := arrayCreate(nv, 0);
    cover_owner := arrayCreate(arrayLength(mapping.var_StA), 0);

    // elements of partially contained variables that are not in the loop are known
    known_scal := arrayCreate(arrayLength(mapping.var_StA), false);
    unknown_rem := arrayCreate(nv, 0);
    for i in 1:nv loop
      (start, size) := mapping.var_AtS[i];
      slice := var_slices[i];
      if unit_kind[i] == 1 and not listEmpty(slice.indices) then
        for k in 0:size - 1 loop known_scal[start + k] := true; end for;
        for k in slice.indices loop known_scal[start + k] := false; end for;
        unknown_rem[i] := listLength(slice.indices);
      else
        unknown_rem[i] := size;
      end if;
      if unit_kind[i] <> 3 and unknown_rem[i] > 0 then
        open_units := open_units + 1;
      end if;
    end for;

    // unknown entries per equation, an equation can only be assigned if every row has exactly one
    row_in_loop := arrayCreate(arrayLength(mapping.eqn_StA), false);
    eqn_unknown := arrayCreate(ne, 0);
    eqn_size := arrayCreate(ne, 0);
    for e in 1:ne loop
      eqn_size[e] := listLength(eqn_rows[e]);
      for r in eqn_rows[e] loop
        row_in_loop[r] := true;
        for p in m.start[r]:m.start[r] + m.len[r] - 1 loop
          if not known_scal[m_data[p]] then
            eqn_unknown[e] := eqn_unknown[e] + 1;
          end if;
        end for;
      end for;
    end for;
    for e in ne:-1:1 loop
      if eqn_unknown[e] == eqn_size[e] then fresh := e :: fresh; end if;
    end for;

    for t in fixed_tears loop
      fresh := cellierMarkKnown(t, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, fresh);
      open_units := open_units - 1;
    end for;

    while true loop
      // fire all blocks of minimal tearing that have their inputs
      while next_block <= nb and List.all(block_in[next_block], function cellierIsKnown(unknown_rem = unknown_rem)) loop
        step := step + 1;
        block_step[next_block] := step;
        for o in block_out[next_block] loop
          fresh := cellierMarkKnown(o, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, fresh);
        end for;
        next_block := next_block + 1;
      end while;

      // check the new candidates
      for e in fresh loop
        stamp_id := stamp_id + 1;
        (rank, units, is_partial) := cellierCanAssign(e, eqn_rows[e], eqn_size[e], mapping, m, m_data, known_scal, unknown_rem, eqn_unknown, unit_kind, stamp, stamp_id, row_var, vars, eqns, solvabilities, eqn_glob, funcMap, probes);
        if rank > 0 and not is_partial then
          ready[rank] := (e, units) :: ready[rank];
        elseif rank > 0 then
          // collect equations that solve distinct elements of the unit, the unit is assigned once they cover all of it
          u := listHead(units);
          overlap := List.any(eqn_rows[e], function cellierIsCovered(row_var = row_var, cover_owner = cover_owner));
          if not overlap then
            for r in eqn_rows[e] loop cover_owner[row_var[r]] := e; end for;
            partial_eqns[u] := e :: partial_eqns[u];
            partial_cov[u] := partial_cov[u] + eqn_size[e];
            partial_rank[u] := max(partial_rank[u], rank);
            if partial_cov[u] == unknown_rem[u] then
              ready[partial_rank[u]] := (-u, units) :: ready[partial_rank[u]];
            end if;
          end if;
        end if;
      end for;
      fresh := {};

      // assign the best valid candidate, a candidate stays valid as long as its unknowns do not change
      found := false;
      for r in 1:4 loop
        while not found and not listEmpty(ready[r]) loop
          (best, units) := listHead(ready[r]);
          ready[r] := listRest(ready[r]);
          if best < 0 then
            found := unknown_rem[-best] > 0;
          elseif eqn_step[best] == 0 and eqn_unknown[best] == eqn_size[best] then
            found := true;
          end if;
        end while;
        if found then break; end if;
      end for;

      if found then
        step := step + 1;
        for e in (if best < 0 then partial_eqns[-best] else {best}) loop
          eqn_step[e] := step;
          eqn_units[e] := units;
        end for;
        for un in units loop
          fresh := cellierMarkKnown(un, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, fresh);
          open_units := open_units - 1;
        end for;
      elseif open_units == 0 then
        break;
      elseif greedy then
        u := cellierSelectTear(mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, unit_kind, eqn_step, vars);
        tears := u :: tears;
        fresh := cellierMarkKnown(u, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, fresh);
        open_units := open_units - 1;
      else
        complete := false;
        break;
      end if;
    end while;
  end cellierCausalize;

  function cellierIsCovered
    input Integer r;
    input array<Integer> row_var;
    input array<Integer> cover_owner;
    output Boolean b = cover_owner[row_var[r]] <> 0;
  end cellierIsCovered;

  function cellierIsKnown
    input Integer u;
    input array<Integer> unknown_rem;
    output Boolean b = unknown_rem[u] == 0;
  end cellierIsKnown;

  function cellierMarkKnown
    "marks all scalars of a unit known and collects the equations that might be assignable now"
    input Integer u;
    input Adjacency.Mapping mapping;
    input Adjacency.IntMatrix mT;
    input array<Integer> mT_data;
    input array<Boolean> row_in_loop;
    input array<Boolean> known_scal;
    input array<Integer> unknown_rem;
    input array<Integer> eqn_unknown;
    input array<Integer> eqn_size;
    input array<Integer> eqn_step;
    input output list<Integer> fresh;
  protected
    Integer start, size, e, r;
  algorithm
    (start, size) := mapping.var_AtS[u];
    for s in start:start + size - 1 loop
      if not known_scal[s] then
        arrayUpdate(known_scal, s, true);
        for p in mT.start[s]:mT.start[s] + mT.len[s] - 1 loop
          r := mT_data[p];
          if row_in_loop[r] then
            e := mapping.eqn_StA[r];
            arrayUpdate(eqn_unknown, e, eqn_unknown[e] - 1);
            if eqn_unknown[e] == eqn_size[e] and eqn_step[e] == 0 then
              fresh := e :: fresh;
            end if;
          end if;
        end for;
      end if;
    end for;
    arrayUpdate(unknown_rem, u, 0);
  end cellierMarkKnown;

  function cellierCanAssign
    "returns the solvability rank (0 if not assignable) and the units an equation can be solved for.
    every row needs exactly one unknown scalar, all distinct and together covering the units."
    input Integer e;
    input list<Integer> rows;
    input Integer size;
    input Adjacency.Mapping mapping;
    input Adjacency.IntMatrix m;
    input array<Integer> m_data;
    input array<Boolean> known_scal;
    input array<Integer> unknown_rem;
    input array<Integer> eqn_unknown;
    input array<Integer> unit_kind;
    input array<Integer> stamp;
    input Integer stamp_id;
    input array<Integer> row_var;
    input VariablePointers vars;
    input EquationPointers eqns;
    input array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    input array<Integer> eqn_glob;
    input UnorderedMap<Path, Function> funcMap;
    input UnorderedMap<Integer, Boolean> probes;
    output Integer rank = 0;
    output list<Integer> units = {};
    output Boolean is_partial = false "the rows only cover a part of the unit";
  protected
    Integer cnt, sv = 0, u, covered = 0, key;
    ComponentRef name;
  algorithm
    if eqn_unknown[e] <> size then return; end if;
    for r in rows loop
      cnt := 0;
      for p in m.start[r]:m.start[r] + m.len[r] - 1 loop
        if not known_scal[m_data[p]] then
          cnt := cnt + 1;
          sv := m_data[p];
        end if;
      end for;
      if cnt <> 1 then
        units := {};
        return;
      elseif stamp[sv] == stamp_id then
        units := {};
        return;
      end if;
      arrayUpdate(stamp, sv, stamp_id);
      arrayUpdate(row_var, r, sv);
      u := mapping.var_StA[sv];
      if not listMember(u, units) then
        if unit_kind[u] <> 1 then
          units := {};
          return;
        end if;
        units := u :: units;
        covered := covered + unknown_rem[u];
      end if;
    end for;
    // a single unit can also be covered by several equations together
    is_partial := covered > size and List.hasOneElement(units);
    if covered <> size and not is_partial then
      units := {};
      return;
    end if;

    if List.hasOneElement(units) then
      name := BVariable.getVarName(VariablePointers.getVarAt(vars, listHead(units)));
      rank := cellierRank(name, solvabilities[eqn_glob[e]]);
      if rank < 1 or rank > 4 then
        rank := 0;
      else
        // make sure the solver can actually do it
        key := e * (arrayLength(unit_kind) + 1) + listHead(units);
        if not UnorderedMap.contains(key, probes) then
          UnorderedMap.add(key, cellierSolvable(EquationPointers.getEqnAt(eqns, e), name, solvabilities[eqn_glob[e]], funcMap), probes);
        end if;
        if not UnorderedMap.getSafe(key, probes, sourceInfo()) then rank := 0; end if;
      end if;
    elseif isRecordAssignment(EquationPointers.getEqnAt(eqns, e), list(VariablePointers.getVarAt(vars, i) for i in units)) then
      rank := 1;
    end if;
    if rank == 0 then units := {}; end if;
  end cellierCanAssign;

  function cellierOccurrences
    "all crefs of a variable as they occur in an equation"
    input ComponentRef name;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    output list<ComponentRef> crefs = list(c for c guard(ComponentRef.isEqual(ComponentRef.stripSubscriptsAll(c), name)) in UnorderedMap.keyList(solvabilities));
  end cellierOccurrences;

  function cellierSolvable
    "checks with the solver if the equation can be solved explicitly for the only occurrence of the variable"
    input Pointer<Equation> eqn_ptr;
    input ComponentRef name;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    input UnorderedMap<Path, Function> funcMap;
    output Boolean b = false;
  protected
    list<ComponentRef> crefs = cellierOccurrences(name, solvabilities);
    Equation eqn = Pointer.access(eqn_ptr);
    Solve.Status status;
    Boolean single;
  algorithm
    (eqn, single) := match eqn
      local
        Equation body;
      case Equation.FOR_EQUATION(body = {body}) then (body, true);
      case Equation.FOR_EQUATION() then (eqn, false);
      else (eqn, true);
    end match;
    if single and List.hasOneElement(crefs) then
      ErrorExt.setCheckpoint(getInstanceName());
      try
        (_, status, _) := Solve.solveBody(eqn, listHead(crefs), funcMap);
        b := status == NBSolve.Status.EXPLICIT;
      else
        b := false;
      end try;
      ErrorExt.rollBack(getInstanceName());
    end if;
  end cellierSolvable;

  function cellierRank
    "worst solvability rank of all occurrences of a variable, for equations also keyed by subscripted crefs"
    input ComponentRef name;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    output Integer rank = 0;
  protected
    Integer r;
  algorithm
    for tpl in UnorderedMap.toList(solvabilities) loop
      if ComponentRef.isEqual(ComponentRef.stripSubscriptsAll(Util.tuple21(tpl)), name) then
        r := Solvability.rank(Util.tuple22(tpl));
        // unknown solvability makes the whole variable unknown
        if r == 0 then
          rank := 0;
          return;
        end if;
        rank := max(rank, r);
      end if;
    end for;
  end cellierRank;

  function isRecordAssignment
    "true if the record equation has all variables (or their record parents) on the lhs and none on the rhs"
    input Pointer<Equation> eqn;
    input list<Pointer<Variable>> vars;
    output Boolean b = true;
  protected
    UnorderedSet<ComponentRef> lhs, rhs;
    list<ComponentRef> names;
  algorithm
    () := match Pointer.access(eqn)
      local
        Equation e;
      case e as Equation.RECORD_EQUATION() algorithm
        lhs := UnorderedSet.fromList(list(ComponentRef.stripSubscriptsAll(c) for c in UnorderedSet.toList(Expression.extractCrefs(e.lhs))), ComponentRef.hash, ComponentRef.isEqual);
        rhs := UnorderedSet.fromList(list(ComponentRef.stripSubscriptsAll(c) for c in UnorderedSet.toList(Expression.extractCrefs(e.rhs))), ComponentRef.hash, ComponentRef.isEqual);
        for var in vars loop
          names := recordNames(var);
          if not List.any(names, function UnorderedSet.contains(set = lhs)) or List.any(names, function UnorderedSet.contains(set = rhs)) then
            b := false;
          end if;
        end for;
      then ();
      else algorithm b := false; then ();
    end match;
  end isRecordAssignment;

  function recordNames
    "the variable name and the names of all its record parents"
    input Pointer<Variable> var;
    output list<ComponentRef> names = {BVariable.getVarName(var)};
  algorithm
    names := match BVariable.getParent(var)
      local
        Pointer<Variable> parent;
      case SOME(parent) then listAppend(names, recordNames(parent));
      else names;
    end match;
  end recordNames;

  function cellierSelectTear
    "chooses the unknown unit with the best tearing select, then a start value, then most open equations, then smallest size"
    input Adjacency.Mapping mapping;
    input Adjacency.IntMatrix mT;
    input array<Integer> mT_data;
    input array<Boolean> row_in_loop;
    input array<Boolean> known_scal;
    input array<Integer> unknown_rem;
    input array<Integer> unit_kind;
    input array<Integer> eqn_step;
    input VariablePointers vars;
    output Integer best = 0;
  protected
    Integer start, size, cls, occ, e, best_cls = -1, best_occ = -1, best_size = 0;
    Boolean has_start, best_start = false;
    array<Integer> seen = arrayCreate(arrayLength(eqn_step), 0);
  algorithm
    for u in 1:arrayLength(unknown_rem) loop
      if unit_kind[u] <> 3 and unknown_rem[u] > 0 then
        cls := Integer(BVariable.getTearingSelect(VariablePointers.getVarAt(vars, u)));
        // a tear variable without start value would start the iteration at zero
        has_start := isSome(BVariable.getStartAttribute(VariablePointers.getVarAt(vars, u)));
        occ := 0;
        (start, size) := mapping.var_AtS[u];
        for s in start:start + size - 1 loop
          if not known_scal[s] then
            for p in mT.start[s]:mT.start[s] + mT.len[s] - 1 loop
              if row_in_loop[mT_data[p]] then
                e := mapping.eqn_StA[mT_data[p]];
                if eqn_step[e] == 0 and seen[e] <> u then
                  seen[e] := u;
                  occ := occ + 1;
                end if;
              end if;
            end for;
          end if;
        end for;
        if cls > best_cls or (cls == best_cls and ((has_start and not best_start) or (has_start == best_start
           and (occ > best_occ or (occ == best_occ and unknown_rem[u] < best_size))))) then
          best := u; best_cls := cls; best_start := has_start; best_occ := occ; best_size := unknown_rem[u];
        end if;
      end if;
    end for;
  end cellierSelectTear;

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

