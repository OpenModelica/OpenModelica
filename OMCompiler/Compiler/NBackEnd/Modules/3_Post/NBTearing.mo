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
  import Binding = NFBinding;
  import Expression = NFExpression;
  import NFFunction.Function;
  import Variable = NFVariable;
  import ComponentRef = NFComponentRef;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Call = NFCall;
  import Dimension = NFDimension;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import NFInstNode.InstNode;
  import NFBackendExtension.{BackendInfo, VariableAttributes, VariableKind};

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
  import Resizable = NBResizable;
  import NBResizable.EvalOrder;
  import NBEquation.{Iterator, EquationKind};

  //Util imports
  import BackendUtil = NBBackendUtil;
  import StringUtil;
  import ErrorExt;
  import Vector;

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
    Pointer<list<Pointer<Variable>>> new_vars = Pointer.create({});
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
          bdae.ode := tearingTraverser(bdae.ode, funcs, bdae.funcMap, eq_index, kind, new_vars);
      then bdae;

      case (_, BackendDAE.MAIN(eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index))) guard(Partition.kindIsInitial(kind))
        algorithm
          bdae.init := tearingTraverser(bdae.init, funcs, bdae.funcMap, eq_index, kind, new_vars);
          if isSome(bdae.init_0) then
            bdae.init_0 := SOME(tearingTraverser(Util.getOption(bdae.init_0), funcs, bdae.funcMap, eq_index, kind, new_vars));
          end if;
      then bdae;

      case (NBPartition.Kind.DAE, BackendDAE.MAIN(dae = SOME(partitions), eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          bdae.dae := SOME(tearingTraverser(partitions, funcs, bdae.funcMap, eq_index, kind, new_vars));
          // recursively call this function to also apply to the ODE section (used for events)
          // ToDo: only create event partitions, disregard rest
      then main(bdae, NBPartition.Kind.ODE);

    // ToDo: all the other cases: e.g. Jacobian, Hessian
    end match;

    // new whole arrays for partial resizable iteration variables
    bdae := match bdae
      case BackendDAE.MAIN() guard not listEmpty(Pointer.access(new_vars)) algorithm
        bdae.varData := VarData.addTypedList(bdae.varData, Pointer.access(new_vars), VarData.VarType.ALGEBRAIC);
      then bdae;
      else bdae;
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
  algorithm
    funcs := match flag
      case "minimalTearing" then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize};
      case "cellier"        then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, cellier, finalize};
      case "omcTearing"     then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize}; // TODO set `minimal = false` when it's actually doing something
      case "guruTearing"    then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, guru, finalize};
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
    input Pointer<list<Pointer<Variable>>> new_vars "new whole arrays for partial resizable iteration variables";
  protected
    Pointer<list<Pointer<Variable>>> part_vars;
    array<StrongComponent> strongComponents;
    StrongComponent tmp;
    Integer idx = 0;
    Adjacency.Matrix full "full adjacency matrix containing solvability info";
    Boolean resizable;
    list<Module.tearingInterface> pre_funcs;
    Module.tearingInterface fin;
    list<StrongComponent> comps, guesses;
  algorithm
    for part in partitions loop
      if isSome(part.strongComponents) and isSome(part.adjacencyMatrix) then
        SOME(strongComponents) := part.strongComponents;
        SOME(full) := part.adjacencyMatrix;
        // with resizable arrays adjacent parts of the same loop are merged before
        // they are finalized (the last function), see mergeResizableLoops
        resizable := Flags.getConfigBool(Flags.RESIZABLE_ARRAYS);
        pre_funcs := if resizable then List.firstN(funcs, listLength(funcs) - 1) else funcs;
        for i in 1:arrayLength(strongComponents) loop
          // each module has a list of functions that need to be applied
          tmp := strongComponents[i];
          for func in pre_funcs loop
            (tmp, full, idx) := func(tmp, full, funcMap, idx, part.unknowns, part.equations, eq_index, kind);
          end for;
          // only update if it changed
          if not referenceEq(tmp, strongComponents[i]) then
            arrayUpdate(strongComponents, i, tmp);
          end if;
        end for;
        if resizable then
          strongComponents := mergeResizableLoops(strongComponents);
          fin := List.last(funcs);
          part_vars := Pointer.create({});
          comps := {};
          for i in 1:arrayLength(strongComponents) loop
            (tmp, guesses) := resizableIterationArrays(strongComponents[i], eq_index, part_vars);
            (tmp, full, idx) := fin(tmp, full, funcMap, idx, part.unknowns, part.equations, eq_index, kind);
            comps := tmp :: List.append_reverse(guesses, comps);
          end for;
          strongComponents := listArray(List.flatten(list(splitGenericSlices(c) for c in listReverse(comps))));
          // the new whole arrays are unknowns of the partition (e.g. for the jacobian sparsity)
          part.unknowns := VariablePointers.addList(Pointer.access(part_vars), part.unknowns);
          Pointer.update(new_vars, listAppend(Pointer.access(part_vars), Pointer.access(new_vars)));
        end if;
        part.strongComponents := SOME(strongComponents);
        part.adjacencyMatrix := SOME(full);
      end if;
      new_partitions := part :: new_partitions;
    end for;
    new_partitions := listReverse(new_partitions);
  end tearingTraverser;

  function resizableIterationArrays
    "Partial slices of resizable arrays as iteration variables are only known at
     the analysis sizes. A slice that consists of boxes of elements becomes new
     whole resizable arrays, the elements of the slice are assigned from them first.
     The guesses assign the new arrays from the current values of the slices before the loop."
    input output StrongComponent comp;
    output list<StrongComponent> guesses = {};
    input Pointer<Integer> eq_index;
    input Pointer<list<Pointer<Variable>>> new_vars;
  protected
    list<Slice<VariablePointer>> vars = {}, new_slices;
    list<StrongComponent> copies = {}, new_copies, new_guesses;
  algorithm
    comp := match comp
      local
        Tearing strict;
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict as TEARING_SET()) algorithm
        for slice in strict.iteration_vars loop
          (new_slices, new_copies, new_guesses) := resizableIterationArray(wholeVarSlice(slice), eq_index, new_vars);
          vars := List.append_reverse(new_slices, vars);
          copies := List.append_reverse(new_copies, copies);
          guesses := List.append_reverse(new_guesses, guesses);
        end for;
        guesses := listReverse(guesses);
        if not listEmpty(copies) then
          strict.iteration_vars := listReverse(vars);
          strict.innerEquations := listArray(listAppend(listReverse(copies), arrayList(strict.innerEquations)));
          strict.jac := NONE();
          comp.strict := strict;
        end if;
      then comp;
      else comp;
    end match;
  end resizableIterationArrays;

  function resizableIterationArray
    "x[2:N] as iteration variable becomes $RZ[1:N-1] with the inner equation
     for i in 2:N loop x[i] = $RZ[i - 1]; end for; a slice that is no box is
     split into boxes first"
    input Slice<VariablePointer> slice;
    output list<Slice<VariablePointer>> slices = {slice};
    output list<StrongComponent> copies = {};
    output list<StrongComponent> guesses = {};
    input Pointer<Integer> eq_index;
    input Pointer<list<Pointer<Variable>>> new_vars;
  protected
    Variable var = Pointer.access(Slice.getT(slice));
    list<Dimension> dims;
    list<ComponentRef> iters;
    list<Expression> ranges;
    Iterator full_iter;
    list<list<Integer>> parts;
    list<Option<Iterator>> o_iters;
    StrongComponent copy, guess;
    Slice<VariablePointer> new_slice;
  algorithm
    dims := Type.arrayDims(var.ty);
    if listEmpty(slice.indices) or not List.any(dims, Dimension.isResizable) or not Type.isReal(Type.arrayElementType(var.ty)) then
      return;
    end if;

    // the slice as boxes over the dimensions
    iters := list(BVariable.getVarName(BackendDAE.lowerIterator(ComponentRef.makeIterator(InstNode.newUniqueIterator(), Type.INTEGER()))) for d in dims);
    ranges := list(Expression.RANGE(Type.ARRAY(Type.INTEGER(), {d}), Expression.INTEGER(1), NONE(), Dimension.sizeExp(d)) for d in dims);
    full_iter := Iterator.fromFrames(List.zip3(iters, ranges, list(NONE() for d in dims)));
    o_iters := {Resizable.restrictIterator(full_iter, slice.indices)};
    if isNone(listHead(o_iters)) then
      parts := Resizable.boxes(slice.indices, Iterator.sizes(full_iter, true));
      o_iters := list(Resizable.restrictIterator(full_iter, part) for part in parts);
    end if;
    if listEmpty(o_iters) or List.any(o_iters, isNone) then
      return;
    end if;

    slices := {};
    for o_iter in o_iters loop
      (new_slice, copy, guess) := resizableIterationBox(Slice.getT(slice), iters, Util.getOption(o_iter), eq_index, new_vars);
      slices := new_slice :: slices;
      copies := copy :: copies;
      guesses := guess :: guesses;
    end for;
    slices := listReverse(slices);
    copies := listReverse(copies);
    guesses := listReverse(guesses);
  end resizableIterationArray;

  function resizableIterationBox
    "the new whole array for a box of a variable, the assignment of its elements
     and the assignment of the new array from the current values as initial guess"
    input Pointer<Variable> var_ptr;
    input list<ComponentRef> iters "the iterators of the dimensions";
    input Iterator iter "the iterators restricted to the box";
    output Slice<VariablePointer> slice;
    output StrongComponent copy;
    output StrongComponent guess;
    input Pointer<Integer> eq_index;
    input Pointer<list<Pointer<Variable>>> new_vars;
  protected
    Variable var = Pointer.access(var_ptr), aux;
    VariableAttributes attrs;
    SliceFunc func;
    list<ComponentRef> names;
    list<Expression> ranges;
    Pointer<Variable> aux_ptr;
    ComponentRef aux_cref, elem_cref, aux_elem_cref;
    Expression lhs, rhs, start;
    list<Subscript> aux_subs = {};
    Pointer<Equation> eqn, guess_eqn;
    UnorderedMap<ComponentRef, EvalOrder> order;
  algorithm
    (names, ranges, _) := Iterator.getFrames(iter);
    (aux_ptr, aux_cref) := BVariable.makeAuxVar("$RZ", Pointer.access(eq_index), Type.ARRAY(Type.arrayElementType(var.ty),
      list(Type.nthDimension(Expression.typeOf(r), 1) for r in ranges)), false);
    aux := Pointer.access(aux_ptr);
    attrs := var.backendinfo.attributes;
    attrs := match attrs
      case VariableAttributes.VAR_ATTR_REAL() algorithm
        func := function sliceAttribute(subs = list(Subscript.SLICE(r) for r in ranges));
        attrs.start   := Util.applyOption(attrs.start, function Binding.mapExpShallow(mapFn = func));
        attrs.nominal := Util.applyOption(attrs.nominal, function Binding.mapExpShallow(mapFn = func));
        attrs.min     := Util.applyOption(attrs.min, function Binding.mapExpShallow(mapFn = func));
        attrs.max     := Util.applyOption(attrs.max, function Binding.mapExpShallow(mapFn = func));
      then attrs;
      else aux.backendinfo.attributes;
    end match;
    aux.backendinfo := BackendInfo.setAttributes(aux.backendinfo, attrs, var.backendinfo.annotations);
    Pointer.update(aux_ptr, aux);
    Pointer.update(new_vars, aux_ptr :: Pointer.access(new_vars));
    for tpl in List.zip(names, ranges) loop
      Expression.RANGE(start = start) := Util.tuple22(tpl);
      aux_subs := Subscript.INDEX(SimplifyExp.simplify(Expression.MULTARY({Expression.fromCref(Util.tuple21(tpl)), Expression.INTEGER(1)},
        {start}, Operator.makeAdd(Type.INTEGER())))) :: aux_subs;
    end for;
    aux_subs := listReverse(aux_subs);
    elem_cref := ComponentRef.mergeSubscripts(list(Subscript.INDEX(Expression.fromCref(i)) for i in iters), var.name, true, true);
    aux_elem_cref := ComponentRef.mergeSubscripts(aux_subs, aux_cref, true, true);
    lhs := Expression.fromCref(elem_cref);
    rhs := Expression.fromCref(aux_elem_cref);
    eqn := Equation.makeAssignment(lhs, rhs, eq_index, NBEquation.SIMULATION_STR, iter, EquationAttributes.default(EquationKind.CONTINUOUS, false));
    guess_eqn := Equation.makeAssignment(rhs, lhs, eq_index, NBEquation.SIMULATION_STR, iter, EquationAttributes.default(EquationKind.CONTINUOUS, false));
    order := UnorderedMap.new<EvalOrder>(ComponentRef.hash, ComponentRef.isEqual);
    for n in names loop
      UnorderedMap.add(n, EvalOrder.INDEPENDENT, order);
    end for;
    copy := StrongComponent.RESIZABLE_COMPONENT(elem_cref, Slice.SLICE(var_ptr, {}), Slice.SLICE(eqn, {}), order, NBSolve.Status.EXPLICIT);
    guess := StrongComponent.RESIZABLE_COMPONENT(aux_elem_cref, Slice.SLICE(aux_ptr, {}), Slice.SLICE(guess_eqn, {}), UnorderedMap.copy(order), NBSolve.Status.EXPLICIT);
    slice := Slice.SLICE(aux_ptr, {});
  end resizableIterationBox;

  partial function SliceFunc
    input output Expression exp;
  end SliceFunc;

  function sliceAttribute
    "the attribute of the box elements, e.g. the start values of x[2:N] for $RZ"
    input output Expression exp;
    input list<Subscript> subs;
  protected
    Integer n = Type.dimensionCount(Expression.typeOf(exp));
    Call call;
    list<tuple<InstNode, Expression>> iters = {};
    list<Subscript> rest;
    Expression range;
    Boolean ok = true;
  algorithm
    if n == 0 then return; end if;
    // an attribute with fewer dimensions applies to the trailing ones
    rest := List.lastN(subs, n);
    exp := match exp
      // {e for i in 1:n}[s:t] -> {e for i in s:t}, the last iterator belongs to the first dimension
      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR()) guard(listLength(call.iters) == n) algorithm
        for tpl in listReverse(call.iters) loop
          range := match (Util.tuple22(tpl), listHead(rest))
            local
              Expression slice;
            case (_, Subscript.WHOLE()) then Util.tuple22(tpl);
            case (Expression.RANGE(start = Expression.INTEGER(1), step = NONE()), Subscript.SLICE(slice = slice as Expression.RANGE())) then slice;
            else algorithm ok := false; then Util.tuple22(tpl);
          end match;
          iters := (Util.tuple21(tpl), range) :: iters;
          rest := listRest(rest);
        end for;
        call.iters := iters;
        call.ty := Type.ARRAY(Type.arrayElementType(call.ty), list(Type.nthDimension(Expression.typeOf(Util.tuple22(t)), 1) for t in listReverse(iters)));
      then if ok then Expression.CALL(call) else Expression.applySubscripts(List.lastN(subs, n), exp);
      else Expression.applySubscripts(rest, exp);
    end match;
  end sliceAttribute;

  function mergeResizableLoops
    "Adjacent algebraic loops that are parts of the same variables and equations
     are merged if together they are whole: with resizable arrays the parts are
     only known for the analysis sizes, the whole loop is valid for every size.
     Solving adjacent loops together is always correct."
    input array<StrongComponent> comps;
    output array<StrongComponent> outComps;
  protected
    list<StrongComponent> acc = {};
    Option<StrongComponent> merged;
    StrongComponent m;
  algorithm
    for c in comps loop
      if not listEmpty(acc) then
        merged := mergeLoops(listHead(acc), c);
        if isSome(merged) then
          SOME(m) := merged;
          acc := m :: listRest(acc);
          continue;
        end if;
      end if;
      acc := c :: acc;
    end for;
    outComps := listArray(listReverse(acc));
  end mergeResizableLoops;

  function mergeLoops
    input StrongComponent comp1;
    input StrongComponent comp2;
    output Option<StrongComponent> merged = NONE();
  protected
    Option<list<Slice<VariablePointer>>> ovars;
    Option<list<Slice<EquationPointer>>> oeqns;
    list<Slice<VariablePointer>> vars;
    list<Slice<EquationPointer>> eqns;
  algorithm
    merged := match (comp1, comp2)
      local
        StrongComponent c1, c2;
        Tearing t1, t2;
      case (c1 as StrongComponent.ALGEBRAIC_LOOP(strict = t1 as TEARING_SET(), casual = NONE()),
            c2 as StrongComponent.ALGEBRAIC_LOOP(strict = t2 as TEARING_SET(), casual = NONE()))
        algorithm
          ovars := mergeSliceLists(t1.iteration_vars, t2.iteration_vars, function sliceName(name = varSliceName));
          oeqns := mergeSliceLists(t1.residual_eqns, t2.residual_eqns, function sliceName(name = eqnSliceName));
          if isSome(ovars) and isSome(oeqns) then
            SOME(vars) := ovars;
            SOME(eqns) := oeqns;
            vars := list(wholeVarSlice(v) for v in vars);
            eqns := list(wholeEqnSlice(e) for e in eqns);
            if List.all(list(listEmpty(v.indices) for v in vars), Util.id) and
               List.all(list(listEmpty(e.indices) for e in eqns), Util.id) then
              t1.iteration_vars := vars;
              t1.residual_eqns := eqns;
              t1.innerEquations := listArray(listAppend(arrayList(t1.innerEquations), arrayList(t2.innerEquations)));
              t1.jac := NONE();
              c1.strict := t1;
              c1.linear := c1.linear and c2.linear;
              c1.mixed := c1.mixed or c2.mixed;
              c1.homotopy := c1.homotopy or c2.homotopy;
              merged := SOME(c1);
            end if;
          end if;
        then merged;
      else NONE();
    end match;
  end mergeLoops;

  function varSliceName
    input Slice<VariablePointer> slice;
    output String name = ComponentRef.toString(BVariable.getVarName(Slice.getT(slice)));
  end varSliceName;

  function eqnSliceName
    input Slice<EquationPointer> slice;
    output String name = ComponentRef.toString(Equation.getEqnName(Slice.getT(slice)));
  end eqnSliceName;

  function sliceName<T>
    input Slice<T> slice;
    input NameFunc name;
    output String str = name(slice);
    partial function NameFunc
      input Slice<T> slice;
      output String str;
    end NameFunc;
  end sliceName;

  function mergeSliceLists<T>
    "the slices of the same objects (by name) merged, NONE if the lists do not
     contain the same objects"
    input list<Slice<T>> l1;
    input list<Slice<T>> l2;
    input NameFunc name;
    output Option<list<Slice<T>>> merged = NONE();
    partial function NameFunc
      input Slice<T> slice;
      output String str;
    end NameFunc;
  protected
    list<Slice<T>> res = {};
    Slice<T> s2;
    array<Slice<T>> arr2 = listArray(l2);
    Option<Integer> opos;
    Integer pos;
    UnorderedMap<String, Integer> by_name "name -> position in l2";
    UnorderedSet<Integer> indices;
  algorithm
    if listLength(l1) <> listLength(l2) then
      return;
    end if;
    by_name := UnorderedMap.new<Integer>(stringHashDjb2, stringEq);
    for i in 1:arrayLength(arr2) loop
      UnorderedMap.add(name(arr2[i]), i, by_name);
    end for;
    for s1 in l1 loop
      opos := UnorderedMap.get(name(s1), by_name);
      if isNone(opos) then
        return;
      end if;
      SOME(pos) := opos;
      s2 := arr2[pos];
      if listEmpty(s1.indices) or listEmpty(s2.indices) then
        res := Slice.SLICE(Slice.getT(s1), {}) :: res;
      else
        indices := UnorderedSet.fromList(s1.indices, Util.id, intEq);
        for i in s2.indices loop
          UnorderedSet.add(i, indices);
        end for;
        res := Slice.SLICE(Slice.getT(s1), List.sort(UnorderedSet.toList(indices), intGt)) :: res;
      end if;
    end for;
    merged := SOME(listReverse(res));
  end mergeSliceLists;

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
        // slices with all elements are whole slices: with resizable arrays the
        // elements are only known for the analysis sizes, a whole slice stays
        // valid for every size
        strict.iteration_vars := list(wholeVarSlice(v) for v in strict.iteration_vars);
        strict.residual_eqns := list(wholeEqnSlice(e) for e in strict.residual_eqns);
        if Flags.getConfigBool(Flags.RESIZABLE_ARRAYS) then
          strict.residual_eqns := List.flatten(list(restrictedForSlice(e, eq_index) for e in strict.residual_eqns));
          strict.residual_eqns := List.flatten(list(bodyElementFors(e, eq_index) for e in strict.residual_eqns));
        end if;

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

  function numUnique
    "the number of different indices"
    input list<Integer> indices;
    output Integer n = UnorderedSet.size(UnorderedSet.fromList(indices, Util.id, intEq));
  end numUnique;

  function wholeVarSlice
    "a slice of all elements of a variable (at the resized sizes) as whole slice"
    input output Slice<VariablePointer> slice;
  algorithm
    if not listEmpty(slice.indices) and
       numUnique(slice.indices) == BVariable.size(Slice.getT(slice), true) then
      slice := Slice.SLICE(Slice.getT(slice), {});
    end if;
  end wholeVarSlice;

  function restrictedForSlice
    "a slice of a for-equation with a scalar body over a resizable range that
     consists of boxes of iterations as whole for-equations over the symbolic
     sub-ranges"
    input Slice<EquationPointer> slice;
    input Pointer<Integer> eq_index;
    output list<Slice<EquationPointer>> slices = {slice};
  protected
    Equation eqn;
    list<Option<Iterator>> iters;
    Pointer<Equation> eqn_ptr;
  algorithm
    eqn := Pointer.access(Slice.getT(slice));
    if listEmpty(slice.indices) or not Equation.isForEquation(Slice.getT(slice)) then
      return;
    end if;
    () := match eqn
      case Equation.FOR_EQUATION() guard Iterator.isResizable(eqn.iter) and
          Equation.size(Slice.getT(slice), true) == Iterator.size(eqn.iter, true) algorithm
        iters := restrictedIterators(eqn.iter, slice.indices);
        if not listEmpty(iters) then
          slices := {};
          for iter in iters loop
            eqn.iter := Util.getOption(iter);
            eqn.size := Iterator.size(eqn.iter);
            // a new residual variable with the restricted sizes
            eqn_ptr := Pointer.create(eqn);
            Equation.createName(eqn_ptr, eq_index, NBEquation.SIMULATION_STR);
            slices := Slice.SLICE(eqn_ptr, {}) :: slices;
          end for;
          slices := listReverse(slices);
        end if;
      then ();
      else ();
    end match;
  end restrictedForSlice;

  function bodyElementFors
    "a for-equation with a fixed size array body as one for-equation per body
     element, the iterators stay symbolic. a partial slice only if it has every
     iteration of its body elements."
    input Slice<EquationPointer> slice;
    input Pointer<Integer> eq_index;
    output list<Slice<EquationPointer>> slices = {slice};
  protected
    Equation eqn, body;
    list<Integer> sizes;
    list<list<Integer>> locations;
    list<Subscript> subs;
    Pointer<Equation> eqn_ptr;
  algorithm
    eqn := Pointer.access(Slice.getT(slice));
    () := match eqn
      case Equation.FOR_EQUATION(body = {body as Equation.ARRAY_EQUATION(recordSize = NONE())}) guard
          List.all(Type.arrayDims(body.ty), function Dimension.isKnown(allowExp = false)) and
          not List.any(Type.arrayDims(body.ty), Dimension.isResizable) algorithm
        sizes := list(Dimension.size(d) for d in Type.arrayDims(body.ty));
        if listEmpty(slice.indices) then
          locations := list(Slice.indexToLocation(i, sizes) for i in 0:List.fold(sizes, intMul, 1)-1);
        else
          locations := bodyElementLocations(eqn, listLength(sizes), slice.indices);
          if listEmpty(locations) then
            return;
          end if;
        end if;
        slices := {};
        for location in locations loop
          subs := list(Subscript.INDEX(Expression.INTEGER(l + 1)) for l in location);
          eqn.body := {Equation.SCALAR_EQUATION(Type.arrayElementType(body.ty),
            SimplifyExp.simplifyDump(Equation.scalarizeElement(body.lhs, subs), true, getInstanceName()),
            SimplifyExp.simplifyDump(Equation.scalarizeElement(body.rhs, subs), true, getInstanceName()),
            body.source, body.attr)};
          eqn.size := Iterator.size(eqn.iter);
          eqn_ptr := Pointer.create(eqn);
          Equation.createName(eqn_ptr, eq_index, NBEquation.SIMULATION_STR);
          slices := Slice.SLICE(eqn_ptr, {}) :: slices;
        end for;
        slices := listReverse(slices);
      then ();
      else ();
    end match;
  end bodyElementFors;

  function bodyElementLocations
    "the body elements of the rows of a for-equation with an array body, empty if
     one of them misses an iteration. the rows are numbered as in
     Equation.forArrayBodyRowResidual, at the analysis sizes of resizable arrays."
    input Equation eqn;
    input Integer n_body;
    input list<Integer> indices;
    output list<list<Integer>> locations;
  protected
    list<Integer> sizes = list(Dimension.size(d, true) for d in Type.arrayDims(Equation.getType(eqn)));
    Integer n_iter = Iterator.size(Equation.getForIterator(eqn), true);
    list<Integer> rows = List.sort(List.unique(indices), intGt);
    list<list<Integer>> row_locations;
  algorithm
    row_locations := list(List.firstN(listReverse(Slice.indexToLocation(i, sizes)), n_body) for i in rows);
    locations := List.uniqueOnTrue(row_locations, function List.isEqualOnTrue(inCompFunc = intEq));
    for location in locations loop
      if List.count(row_locations, function List.isEqualOnTrue(inList2 = location, inCompFunc = intEq)) <> n_iter then
        locations := {};
        return;
      end if;
    end for;
  end bodyElementLocations;

  function restrictedIterators
    "the iterator restricted to the boxes of the iterations, empty if not possible"
    input Iterator iter;
    input list<Integer> indices;
    output list<Option<Iterator>> iters;
  algorithm
    iters := {Resizable.restrictIterator(iter, indices)};
    if isNone(listHead(iters)) then
      iters := list(Resizable.restrictIterator(iter, part) for part in Resizable.boxes(indices, Iterator.sizes(iter, true)));
    end if;
    if List.any(iters, isNone) then
      iters := {};
    end if;
  end restrictedIterators;

  function splitGenericSlices
    "generic or sliced components of resizable for-equations whose slices are no
     boxes are split into boxes (also inside algebraic loops)"
    input StrongComponent comp;
    output list<StrongComponent> comps;
  algorithm
    comps := match comp
      local
        Tearing strict;
        Equation eqn;
        list<Option<Iterator>> iters;
      case StrongComponent.GENERIC_COMPONENT() guard not listEmpty(comp.eqn.indices) and Equation.isForEquation(Slice.getT(comp.eqn)) algorithm
        eqn := Pointer.access(Slice.getT(comp.eqn));
        if Iterator.isResizable(Equation.getForIterator(eqn)) and isNone(Resizable.restrictIterator(Equation.getForIterator(eqn), comp.eqn.indices))
           and Equation.size(Slice.getT(comp.eqn), true) == Iterator.size(Equation.getForIterator(eqn), true) then
          iters := restrictedIterators(Equation.getForIterator(eqn), comp.eqn.indices);
        else
          iters := {};
        end if;
      then if listEmpty(iters) then {comp} else list(StrongComponent.GENERIC_COMPONENT(comp.var_cref, comp.var, Slice.SLICE(Slice.getT(comp.eqn), part))
             for part in Resizable.boxes(comp.eqn.indices, Iterator.sizes(Equation.getForIterator(eqn), true)));
      // not yet solved slices (e.g. inner equations of algebraic loops)
      case StrongComponent.SLICED_COMPONENT() guard not listEmpty(comp.eqn.indices) and Equation.isForEquation(Slice.getT(comp.eqn)) algorithm
        eqn := Pointer.access(Slice.getT(comp.eqn));
        if Iterator.isResizable(Equation.getForIterator(eqn)) and isNone(Resizable.restrictIterator(Equation.getForIterator(eqn), comp.eqn.indices))
           and Equation.size(Slice.getT(comp.eqn), true) == Iterator.size(Equation.getForIterator(eqn), true) then
          iters := restrictedIterators(Equation.getForIterator(eqn), comp.eqn.indices);
        else
          iters := {};
        end if;
      then if listEmpty(iters) then {comp} else list(StrongComponent.SLICED_COMPONENT(comp.var_cref, comp.var, Slice.SLICE(Slice.getT(comp.eqn), part), comp.status)
             for part in Resizable.boxes(comp.eqn.indices, Iterator.sizes(Equation.getForIterator(eqn), true)));
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict as TEARING_SET()) algorithm
        strict.innerEquations := listArray(List.flatten(list(splitGenericSlices(c) for c in strict.innerEquations)));
        comp.strict := strict;
      then {comp};
      else {comp};
    end match;
  end splitGenericSlices;

  function wholeEqnSlice
    "a slice of all elements of an equation (at the resized sizes) as whole slice"
    input output Slice<EquationPointer> slice;
  algorithm
    if not listEmpty(slice.indices) and
       numUnique(slice.indices) == Equation.size(Slice.getT(slice), true) then
      slice := Slice.SLICE(Slice.getT(slice), {});
    end if;
  end wholeEqnSlice;

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
    UnorderedSet<ComponentRef> cont_set;
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
          // keep the slices, only a part of an array equation might belong to the loop
          cont_set := UnorderedSet.fromList(list(Equation.getEqnName(eqn) for eqn in cont_eqns), ComponentRef.hash, ComponentRef.isEqual);
          strict.residual_eqns  := list(eqn for eqn guard(UnorderedSet.contains(Equation.getEqnName(Slice.getT(eqn)), cont_set)) in strict.residual_eqns);
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
    // tears the variables with tearing select prefer or always of what minimal tearing left over.
    // if they do not suffice, cellier adds tear variables. loops without such variables are not torn.
  algorithm
    comp := match (comp, full)
      case (StrongComponent.ALGEBRAIC_LOOP(), Adjacency.FULL())
        guard(List.any(comp.strict.iteration_vars, function Slice.check(func = isGuruVar))) algorithm
        comp.strict := cellierTearingSet(comp.strict, full, equations, funcMap, true);
      then comp;
      else comp;
    end match;
  end guru;

  function isGuruVar
    input Pointer<Variable> var_ptr;
    output Boolean b = BVariable.hasTearingSelect(var_ptr, NFBackendExtension.TearingSelect.PREFER, intGe);
  end isGuruVar;

  function cellier extends Module.tearingInterface;
    // Cellier style tearing of what minimal tearing left over. Variables are only assigned as a whole
    // (the part of them that is in the loop), so arrays and records are never split any further.
    // The inner components of minimal tearing are kept as they are.
  protected
    Tearing strict, cellier_strict;
  algorithm
    comp := match (comp, full)
      case (StrongComponent.ALGEBRAIC_LOOP(strict = strict), Adjacency.FULL())
        guard(not listEmpty(strict.iteration_vars) and not listEmpty(strict.residual_eqns)) algorithm
        cellier_strict := cellierTearingSet(strict, full, equations, funcMap);
        // a linear loop is solved directly as linear system if its tearing set allows it, do not
        // replace such a tearing set by one that has to be solved as nonlinear system
        if not (comp.linear and linearSystemCapable(strict) and not linearSystemCapable(cellier_strict)) then
          comp.strict := cellier_strict;
        end if;
      then comp;
      else comp;
    end match;
  end cellier;

  function linearSystemCapable
    "true if the linear system codegen can handle the tearing set: no for equations in the inner
    equations, for equation residuals only if finalize splits them into rows (partial variables)
    and partial variables only if they are scalarized"
    input Tearing strict;
    output Boolean b;
  protected
    Boolean partial_vars = List.any(strict.iteration_vars, isPartialVarSlice);
  algorithm
    b := not Array.any(strict.innerEquations, isForComponent)
      and (partial_vars or not List.any(list(Slice.getT(e) for e in strict.residual_eqns), Equation.isForEquation))
      and (not partial_vars or Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE));
  end linearSystemCapable;

  function isForComponent
    input StrongComponent comp;
    output Boolean b = List.any(StrongComponent.getEquations(comp), Equation.isForEquation);
  end isForComponent;

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
    input Boolean guru = false "the variables with tearing select prefer or always are tear variables, others only if they do not suffice";
  protected
    UnorderedMap<Integer, Boolean> probes = UnorderedMap.new<Boolean>(Util.id, intEq);
    UnorderedMap<Integer, Integer> ranks = UnorderedMap.new<Integer>(Util.id, intEq);
    list<Pointer<Variable>> loop_vars, block_vars = {};
    list<Pointer<Equation>> loop_eqns;
    VariablePointers vars;
    EquationPointers eqns;
    Adjacency.Matrix adj;
    Adjacency.Mapping mapping;
    Integer nv, ne, nb, idx, start, size;
    array<Integer> unit_kind, eqn_glob, owner, eqn_step, row_var, block_step, row_step;
    array<Integer> row_chain, eqn_points;
    array<Boolean> row_scalar, row_resizable;
    list<Integer> left, chain_rows, chain_eqns;
    Option<StrongComponent> opt_comp;
    array<Slice<VariablePointer>> var_slices;
    array<Slice<EquationPointer>> eqn_slices;
    array<list<Integer>> block_in, block_out, eqn_rows, eqn_units;
    array<StrongComponent> blocks;
    list<Integer> tears, fixed = {}, trial;
    Option<Integer> opt_idx;
    Boolean complete = false;
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
      if BVariable.hasTearingSelect(Slice.getT(var), if guru then NFBackendExtension.TearingSelect.PREFER else NFBackendExtension.TearingSelect.ALWAYS, intGe) then
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
    eqn_points := listArray(list(cellierNonlinearityPoints(Pointer.access(EquationPointers.getEqnAt(eqns, e)), solvabilities[eqn_glob[e]]) for e in 1:ne));
    row_scalar := listArray(list(not cellierRowCapable(Pointer.access(EquationPointers.getEqnAt(eqns, e))) for e in 1:ne));
    row_resizable := listArray(list(cellierRowResizable(Pointer.access(EquationPointers.getEqnAt(eqns, e))) for e in 1:ne));

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
    if guru then
      (_, _, _, _, _, _, _, complete) := cellierCausalize(fixed, false, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, eqn_points, row_scalar, row_resizable, funcMap, probes, ranks);
    end if;
    if guru and complete then
      tears := fixed;
    else
      (tears, _, _, _, _, _, _, _) := cellierCausalize(fixed, true, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, eqn_points, row_scalar, row_resizable, funcMap, probes, ranks);
      for t in List.sort(tears, function cellierSizeLess(var_slices = var_slices)) loop
        if not listMember(t, fixed) then
          trial := list(i for i guard(i <> t) in tears);
          (_, _, _, _, _, _, _, complete) := cellierCausalize(trial, false, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, eqn_points, row_scalar, row_resizable, funcMap, probes, ranks);
          if complete then tears := trial; end if;
        end if;
      end for;
      // then try to replace every tear variable by a smaller one it shares an equation with
      for t in List.sort(tears, function cellierSizeLess(var_slices = var_slices)) loop
        if not listMember(t, fixed) then
          for c in List.sort(cellierNeighbours(t, adj, unit_kind, var_slices, tears), function cellierSizeGt(var_slices = var_slices)) loop
            trial := c :: list(i for i guard(i <> t) in tears);
            (_, _, _, _, _, _, _, complete) := cellierCausalize(trial, false, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, eqn_points, row_scalar, row_resizable, funcMap, probes, ranks);
            if complete then
              tears := trial;
              break;
            end if;
          end for;
        end if;
      end for;
    end if;
    (tears, eqn_step, eqn_units, row_var, block_step, row_step, row_chain, complete) := cellierCausalize(tears, false, adj, vars, eqns, eqn_glob, eqn_rows, solvabilities, unit_kind, var_slices, block_in, block_out, eqn_points, row_scalar, row_resizable, funcMap, probes, ranks);

    if not complete or (Array.all(eqn_step, function intEq(i2 = 0)) and Array.all(row_step, function intEq(i2 = 0))) then
      return;
    end if;

    // new inner components in causal order, interleaved with the blocks of minimal tearing
    for i in 1:ne loop
      if eqn_step[i] > 0 then
        ordered := (eqn_step[i], cellierComponent(i, eqn_units[i], eqn_rows[i], row_var, mapping, vars, eqns, var_slices, eqn_slices, solvabilities[eqn_glob[i]])) :: ordered;
      end if;
      for r in eqn_rows[i] loop
        if row_chain[r] > 0 and row_step[r] == row_chain[r] then
          chain_rows := list(q for q guard(row_chain[q] == row_chain[r]) in 1:arrayLength(row_chain));
          chain_eqns := List.unique(list(mapping.eqn_StA[q] for q in chain_rows));
          if List.hasOneElement(chain_eqns) then
            ordered := cellierChainComponent(i, eqn_rows[i], row_step, row_var, mapping, vars, eqns, solvabilities[eqn_glob[i]]) :: ordered;
          else
            // the rows of several equations alternate
            opt_comp := cellierEntwinedComponent(chain_rows, chain_eqns, row_step, row_var, mapping, vars, eqns, solvabilities, eqn_glob);
            if isNone(opt_comp) then return; end if;
            ordered := (row_chain[r], Util.getOption(opt_comp)) :: ordered;
          end if;
        end if;
      end for;
      for r in eqn_rows[i] loop
        if row_step[r] > 0 and row_chain[r] == 0 then
          ordered := (row_step[r], cellierComponent(i, {mapping.var_StA[row_var[r]]}, {r}, row_var, mapping, vars, eqns, var_slices, eqn_slices, solvabilities[eqn_glob[i]])) :: ordered;
        end if;
      end for;
    end for;
    for b in 1:nb loop
      ordered := (block_step[b], blocks[b]) :: ordered;
    end for;
    ordered := List.sort(ordered, function Util.compareTupleIntGt());

    tear_set := UnorderedSet.fromList(tears, Util.id, intEq);
    strict.innerEquations := listArray(list(Util.tuple22(tpl) for tpl in ordered));
    strict.iteration_vars := list(var for var guard(UnorderedSet.contains(UnorderedMap.getSafe(BVariable.getVarName(Slice.getT(var)), vars.map, sourceInfo()), tear_set)) in strict.iteration_vars);
    strict.residual_eqns := {};
    for i in ne:-1:1 loop
      if eqn_step[i] == 0 then
        // rows that are not assigned on their own stay residuals
        (start, size) := mapping.eqn_AtS[i];
        left := list(r - start for r guard(row_step[r] == 0) in eqn_rows[i]);
        if listLength(left) == listLength(eqn_rows[i]) then
          strict.residual_eqns := eqn_slices[i] :: strict.residual_eqns;
        elseif not listEmpty(left) then
          strict.residual_eqns := Slice.SLICE(Slice.getT(eqn_slices[i]), List.sort(left, intGt)) :: strict.residual_eqns;
        end if;
      end if;
    end for;
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

  function cellierChainComponent
    "one component for all rows of a for equation that are assigned as a chain"
    input Integer e;
    input list<Integer> rows;
    input array<Integer> row_step;
    input array<Integer> row_var;
    input Adjacency.Mapping mapping;
    input VariablePointers vars;
    input EquationPointers eqns;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    output tuple<Integer, StrongComponent> comp;
  protected
    list<Integer> sorted = List.sort(rows, function cellierRowStepGt(row_step = row_step));
    Integer first = listHead(sorted);
  algorithm
    comp := (row_step[first], StrongComponent.createPseudoSlice(mapping.var_StA[row_var[first]], e,
      cellierChainCref(e, sorted, row_var, mapping, vars, eqns, solvabilities), sorted, row_var, eqns, mapping));
  end cellierChainComponent;

  function cellierEntwinedComponent
    "one entwined component for the rows of several equations that are assigned as one chain,
    none if they have no periodic order but would need one"
    input list<Integer> chain_rows;
    input list<Integer> chain_eqns;
    input array<Integer> row_step;
    input array<Integer> row_var;
    input Adjacency.Mapping mapping;
    input VariablePointers vars;
    input EquationPointers eqns;
    input array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    input array<Integer> eqn_glob;
    output Option<StrongComponent> comp;
  protected
    list<Integer> rows = List.sort(chain_rows, function cellierRowStepGt(row_step = row_step));
    UnorderedMap<Integer, ComponentRef> cref_map = UnorderedMap.new<ComponentRef>(Util.id, intEq);
  algorithm
    for e in chain_eqns loop
      if Equation.isForEquation(EquationPointers.getEqnAt(eqns, e)) then
        UnorderedMap.add(e, cellierChainCref(e, list(q for q guard(mapping.eqn_StA[q] == e) in rows), row_var, mapping, vars, eqns, solvabilities[eqn_glob[e]]), cref_map);
      end if;
    end for;
    comp := StrongComponent.tryPseudoEntwined(rows, row_var, mapping, vars, eqns, cref_map);
  end cellierEntwinedComponent;

  function cellierChainCref
    "the occurrence of the variable that gives the order the rows of the equation were assigned in"
    input Integer e;
    input list<Integer> sorted "rows in assignment order";
    input array<Integer> row_var;
    input Adjacency.Mapping mapping;
    input VariablePointers vars;
    input EquationPointers eqns;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    output ComponentRef cref;
  protected
    EvalOrder dir = if listHead(sorted) < List.last(sorted) then EvalOrder.FORWARD else EvalOrder.BACKWARD;
    ComponentRef name = BVariable.getVarName(VariablePointers.getVarAt(vars, mapping.var_StA[row_var[listHead(sorted)]]));
    list<ComponentRef> crefs = cellierOccurrences(name, solvabilities);
    Equation eqn = Pointer.access(EquationPointers.getEqnAt(eqns, e));
  algorithm
    cref := listHead(crefs);
    for c in crefs loop
      if List.all(UnorderedMap.valueList(Resizable.detect(eqn, c)), function cellierIsOrder(dir = dir)) then
        cref := c;
        break;
      end if;
    end for;
  end cellierChainCref;

  function cellierRowStepGt
    input Integer r1;
    input Integer r2;
    input array<Integer> row_step;
    output Boolean b = row_step[r1] > row_step[r2];
  end cellierRowStepGt;

  function cellierIsOrder
    input EvalOrder eo;
    input EvalOrder dir;
    output Boolean b = eo == dir;
  end cellierIsOrder;

  function cellierNeighbours
    "the loop variables that are smaller than unit t and share an equation with it"
    input Integer t;
    input Adjacency.Matrix adj;
    input array<Integer> unit_kind;
    input array<Slice<VariablePointer>> var_slices;
    input list<Integer> tears;
    output list<Integer> units = {};
  protected
    Adjacency.IntMatrix m, mT;
    Adjacency.Mapping mapping;
    array<Integer> m_data, mT_data;
    array<Boolean> seen;
    Integer start, size, r, u;
  algorithm
    () := match adj
      case Adjacency.Matrix.FINAL() algorithm
        m := adj.m; mT := adj.mT; mapping := adj.mapping;
      then ();
      else fail();
    end match;
    m_data := Adjacency.IntMatrix.entries(m);
    mT_data := Adjacency.IntMatrix.entries(mT);
    seen := arrayCreate(arrayLength(mapping.var_AtS), false);
    for i in tears loop seen[i] := true; end for;
    (start, size) := mapping.var_AtS[t];
    for s in start:start + size - 1 loop
      for piece in mT.first[s]:mT.first[s] + mT.pieces[s] - 1 loop
        for p in Adjacency.IntMatrix.pieceBegin(mT, piece):Adjacency.IntMatrix.pieceEnd(mT, piece) loop
          r := mT_data[p];
          for piece2 in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
            for p2 in Adjacency.IntMatrix.pieceBegin(m, piece2):Adjacency.IntMatrix.pieceEnd(m, piece2) loop
              u := mapping.var_StA[m_data[p2]];
              if not seen[u] then
                seen[u] := true;
                if unit_kind[u] == 1 and cellierSizeLess(u, t, var_slices) then
                  units := u :: units;
                end if;
              end if;
            end for;
          end for;
        end for;
      end for;
    end for;
  end cellierNeighbours;

  function cellierSizeGt
    "sorts smaller units first"
    input Integer u1;
    input Integer u2;
    input array<Slice<VariablePointer>> var_slices;
    output Boolean b = cellierSizeLess(u2, u1, var_slices);
  end cellierSizeGt;

  function cellierSizeLess
    "sorts bigger units first"
    input Integer u1;
    input Integer u2;
    input array<Slice<VariablePointer>> var_slices;
    output Boolean b = Slice.size(var_slices[u1], function BVariable.size(resize = true)) < Slice.size(var_slices[u2], function BVariable.size(resize = true));
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
    input array<Integer> eqn_points;
    input array<Boolean> row_scalar "rows can not be assigned one at a time";
    input array<Boolean> row_resizable;
    input UnorderedMap<Path, Function> funcMap;
    input UnorderedMap<Integer, Boolean> probes "cached solver checks";
    input UnorderedMap<Integer, Integer> ranks "cached solvability ranks of a unit in an equation (2 * key), of a single row (2 * key + 1)";
    output list<Integer> tears = fixed_tears;
    output array<Integer> eqn_step;
    output array<list<Integer>> eqn_units;
    output array<Integer> row_var;
    output array<Integer> block_step;
    output array<Integer> row_step "step of a row that is assigned on its own, 0 otherwise";
    output array<Integer> row_chain "step of the first row of the chain the row is assigned in, 0 otherwise";
    output Boolean complete = true;
  protected
    Adjacency.IntMatrix m, mT;
    Adjacency.Mapping mapping;
    array<Integer> m_data, mT_data, unknown_rem, unknown_full, eqn_unknown, eqn_size, stamp;
    array<Boolean> known_scal, row_in_loop, row_capable;
    Vector<CellierCandidate> ready = Vector.new<CellierCandidate>(), ready_rows = Vector.new<CellierCandidate>();
    array<Integer> eqn_seq, unit_seq, row_seq "the newest candidate of each, older ones are outdated";
    Integer seq = 0, entry_seq, id;
    list<tuple<Integer, Integer>> chain = {};
    list<Integer> chain_eqns = {};
    Boolean chain_complete = false;
    Integer eq_cls, eq_points, e;
    array<list<Integer>> partial_eqns;
    array<Integer> partial_cov, partial_rank, cover_owner;
    Boolean is_partial, overlap;
    Integer nv, ne, nb = arrayLength(block_in), start, size, open_units = 0, step = 0, next_block = 1, stamp_id = 0;
    Integer rank, best = 0, u, points, best_points, best_row = 0, best_sv = 0, cnt, sv, cls, best_cls;
    list<Integer> fresh = {}, units = {}, touched = {};
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
    cover_owner := arrayCreate(arrayLength(mapping.var_StA), 0);
    row_step := arrayCreate(arrayLength(mapping.eqn_StA), 0);
    partial_rank := arrayCreate(nv, 0);
    eqn_seq := arrayCreate(ne, 0);
    unit_seq := arrayCreate(nv, 0);
    row_seq := arrayCreate(arrayLength(mapping.eqn_StA), 0);

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
        for piece in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
          for p in Adjacency.IntMatrix.pieceBegin(m, piece):Adjacency.IntMatrix.pieceEnd(m, piece) loop
            if not known_scal[m_data[p]] then
              eqn_unknown[e] := eqn_unknown[e] + 1;
            end if;
          end for;
        end for;
      end for;
    end for;
    for e in ne:-1:1 loop
      if eqn_unknown[e] == eqn_size[e] then fresh := e :: fresh; end if;
    end for;
    unknown_full := arrayCopy(unknown_rem);

    // the rows of a for equation can also be assigned one at a time, e.g. for a recursion x[i] = x[i+1] + y[i]
    // a scalar equation can solve a single element of an array this way
    row_capable := listArray(list(eqn_size[e] == 1 or not row_scalar[e] for e in 1:ne));
    row_chain := arrayCreate(arrayLength(mapping.eqn_StA), 0);
    for e in 1:ne loop
      if row_capable[e] then touched := listAppend(eqn_rows[e], touched); end if;
    end for;

    for t in fixed_tears loop
      (fresh, touched) := cellierMarkKnown(t, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, row_capable, fresh, touched);
      open_units := open_units - 1;
    end for;

    while true loop
      // fire all blocks of minimal tearing that have their inputs
      while next_block <= nb and List.all(block_in[next_block], function cellierIsKnown(unknown_rem = unknown_rem)) loop
        step := step + 1;
        block_step[next_block] := step;
        for o in block_out[next_block] loop
          (fresh, touched) := cellierMarkKnown(o, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, row_capable, fresh, touched);
        end for;
        next_block := next_block + 1;
      end while;

      // check the new candidates
      for e in fresh loop
        stamp_id := stamp_id + 1;
        (rank, units, is_partial) := cellierCanAssign(e, eqn_rows[e], eqn_size[e], mapping, m, m_data, known_scal, unknown_rem, eqn_unknown, unit_kind, stamp, stamp_id, row_var, vars, eqns, solvabilities, eqn_glob, funcMap, probes, ranks);
        if rank > 0 and not is_partial then
          seq := seq + 1;
          eqn_seq[e] := seq;
          cellierHeapPush(ready, (rank, eqn_points[e], seq, e, 0, units));
        elseif rank > 0 then
          // collect equations that solve distinct elements of the unit, the unit is assigned once they cover all of it
          u := listHead(units);
          overlap := List.any(eqn_rows[e], function cellierIsCovered(row_var = row_var, cover_owner = cover_owner));
          if not overlap then
            for r in eqn_rows[e] loop cover_owner[row_var[r]] := e; end for;
            partial_eqns[u] := e :: partial_eqns[u];
            partial_cov[u] := partial_cov[u] + eqn_size[e];
            partial_rank[u] := max(partial_rank[u], rank);
            if partial_cov[u] == unknown_rem[u] or unit_seq[u] > 0 then
              seq := seq + 1;
              unit_seq[u] := seq;
              cellierHeapPush(ready, (partial_rank[u], max(eqn_points[i] for i in partial_eqns[u]), seq, -u, 0, units));
            end if;
          end if;
        end if;
      end for;
      fresh := {};
      for r in touched loop
        if row_step[r] == 0 and eqn_step[mapping.eqn_StA[r]] == 0 then
          (cnt, sv) := cellierRowUnknown(r, m, m_data, known_scal);
          if cnt == 1 then
            rank := cellierRowSolvable(mapping.eqn_StA[r], mapping.var_StA[sv], unit_kind, vars, eqns, solvabilities, eqn_glob, funcMap, probes, ranks);
            if rank > 0 then
              seq := seq + 1;
              row_seq[r] := seq;
              cellierHeapPush(ready_rows, (rank, eqn_points[mapping.eqn_StA[r]], seq, r, sv, {}));
            end if;
          end if;
        end if;
      end for;
      touched := {};

      // candidates with the best rank first (a parameter coefficient can be zero), among them the most
      // nonlinear one like the old backend, so that the residuals stay as linear as possible. a
      // candidate stays valid as long as its unknowns do not change
      while Vector.size(ready) > 0 loop
        (_, _, entry_seq, id, _, _) := Vector.get(ready, 1);
        if entry_seq == (if id < 0 then unit_seq[-id] else eqn_seq[id]) and cellierIsValid(id, unknown_rem, eqn_step, eqn_unknown, eqn_size) then
          break;
        end if;
        cellierHeapPop(ready);
      end while;
      found := Vector.size(ready) > 0;
      if found then
        (best_cls, best_points, _, best, _, units) := Vector.get(ready, 1);
      else
        best_cls := 10;
        best_points := -1;
      end if;
      // rows only if they are better than every complete candidate and can be solved one after
      // another as a chain, single rows would scalarize the equations.
      eq_cls := best_cls;
      eq_points := best_points;
      while true loop
        best_row := 0;
        while Vector.size(ready_rows) > 0 loop
          (cls, points, entry_seq, id, sv, _) := Vector.get(ready_rows, 1);
          if entry_seq == row_seq[id] and cellierRowIsValid((id, sv), m, m_data, known_scal, row_step, eqn_step, mapping) then
            if cls < eq_cls or (cls == eq_cls and points > eq_points) then
              best_row := id;
              best_sv := sv;
            end if;
            break;
          end if;
          cellierHeapPop(ready_rows);
        end while;
        if best_row == 0 then break; end if;
        e := mapping.eqn_StA[best_row];
        // rather a chain through the rows of several equations than through only this one
        (chain, chain_complete) := cellierChain(best_row, best_sv, false, m, m_data, mT, mT_data, known_scal, row_in_loop, row_capable, row_step, eqn_step, eqn_rows, mapping, unit_kind, vars, eqns, solvabilities, eqn_glob, funcMap, probes, ranks);
        if not chain_complete then
          (chain, chain_complete) := cellierChain(best_row, best_sv, true, m, m_data, mT, mT_data, known_scal, row_in_loop, row_capable, row_step, eqn_step, eqn_rows, mapping, unit_kind, vars, eqns, solvabilities, eqn_glob, funcMap, probes, ranks);
        end if;
        chain_eqns := List.unique(list(mapping.eqn_StA[Util.tuple21(c)] for c in chain));
        // a chain through several equations becomes one component if it repeats one of them, through one
        // equation only with all its rows. the rows of resizable equations only as a chain through all of them
        chain_complete := chain_complete and listLength(chain) > listLength(chain_eqns)
          and (not List.hasOneElement(chain_eqns) or listLength(chain) == eqn_size[e])
          and List.all(list(eqn_size[ce] == sum(1 for c guard(mapping.eqn_StA[Util.tuple21(c)] == ce) in chain) for ce guard(row_resizable[ce]) in chain_eqns), Util.id);
        if chain_complete then break; end if;
        row_seq[best_row] := 0;
        cellierHeapPop(ready_rows);
      end while;

      if best_row > 0 then
        if chain_complete then
          for c in chain loop
            row_chain[Util.tuple21(c)] := step + 1;
          end for;
        end if;
        for c in chain loop
          (best_row, best_sv) := c;
          step := step + 1;
          row_step[best_row] := step;
          row_var[best_row] := best_sv;
          u := mapping.var_StA[best_sv];
          // equations that wanted to cover the unit together might solve this element as well
          if cover_owner[best_sv] <> 0 then partial_cov[u] := -arrayLength(mapping.var_StA); end if;
          (fresh, touched) := cellierMarkScalarKnown(best_sv, mapping, mT, mT_data, row_in_loop, known_scal, eqn_unknown, eqn_size, eqn_step, row_capable, fresh, touched);
          unknown_rem[u] := unknown_rem[u] - 1;
          if unknown_rem[u] == 0 then open_units := open_units - 1; end if;
        end for;
      elseif found then
        step := step + 1;
        for e in (if best < 0 then partial_eqns[-best] else {best}) loop
          eqn_step[e] := step;
          eqn_units[e] := units;
        end for;
        for un in units loop
          (fresh, touched) := cellierMarkKnown(un, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, row_capable, fresh, touched);
          open_units := open_units - 1;
        end for;
      elseif open_units == 0 then
        break;
      elseif greedy then
        u := cellierSelectTear(mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, unknown_full, unit_kind, eqn_step, vars);
        if u == 0 then
          complete := false;
          break;
        end if;
        tears := u :: tears;
        (fresh, touched) := cellierMarkKnown(u, mapping, mT, mT_data, row_in_loop, known_scal, unknown_rem, eqn_unknown, eqn_size, eqn_step, row_capable, fresh, touched);
        open_units := open_units - 1;
      else
        complete := false;
        break;
      end if;
    end while;
  end cellierCausalize;

  function cellierIsAliasSide
    input Option<Expression> side;
    output Boolean b;
  algorithm
    b := match side
      case SOME(Expression.CREF()) then true;
      case SOME(Expression.UNARY(exp = Expression.CREF())) then true;
      else false;
    end match;
  end cellierIsAliasSide;

  type CellierCandidate = tuple<Integer, Integer, Integer, Integer, Integer, list<Integer>>
    "rank, nonlinearity points, insertion, equation/row/negative unit, scalar variable of a row, units";

  function cellierHeapBefore
    "lower rank first, then more nonlinearity points, then the newest"
    input CellierCandidate a;
    input CellierCandidate b;
    output Boolean before;
  protected
    Integer ra, pa, sa, rb, pb, sb;
  algorithm
    (ra, pa, sa, _, _, _) := a;
    (rb, pb, sb, _, _, _) := b;
    before := ra < rb or (ra == rb and (pa > pb or (pa == pb and sa > sb)));
  end cellierHeapBefore;

  function cellierHeapPush
    input Vector<CellierCandidate> heap;
    input CellierCandidate c;
  protected
    Integer i, p;
  algorithm
    Vector.push(heap, c);
    i := Vector.size(heap);
    while i > 1 loop
      p := intDiv(i, 2);
      if not cellierHeapBefore(c, Vector.get(heap, p)) then break; end if;
      Vector.update(heap, i, Vector.get(heap, p));
      i := p;
    end while;
    Vector.update(heap, i, c);
  end cellierHeapPush;

  function cellierHeapPop
    "removes the first candidate"
    input Vector<CellierCandidate> heap;
  protected
    CellierCandidate last;
    Integer i = 1, k, n;
  algorithm
    last := Vector.get(heap, Vector.size(heap));
    Vector.pop(heap);
    n := Vector.size(heap);
    if n == 0 then return; end if;
    while 2 * i <= n loop
      k := 2 * i;
      if k < n and cellierHeapBefore(Vector.get(heap, k + 1), Vector.get(heap, k)) then k := k + 1; end if;
      if not cellierHeapBefore(Vector.get(heap, k), last) then break; end if;
      Vector.update(heap, i, Vector.get(heap, k));
      i := k;
    end while;
    Vector.update(heap, i, last);
  end cellierHeapPop;

  function cellierIsValid
    input Integer c "equation, or negative unit covered by several equations";
    input array<Integer> unknown_rem;
    input array<Integer> eqn_step;
    input array<Integer> eqn_unknown;
    input array<Integer> eqn_size;
    output Boolean b = if c < 0 then unknown_rem[-c] > 0 else eqn_step[c] == 0 and eqn_unknown[c] == eqn_size[c];
  end cellierIsValid;

  function cellierNonlinearityPoints
    "nonlinearity assessment of an equation as in the old backend (Tearing.getEquationNonlinearityPoints).
    a variable that already is one side of the equation counts nothing, a function alias counts as the
    nonlinear call it replaces."
    input Equation eqn;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    output Integer points = 0;
  protected
    list<ComponentRef> solved = {};
    ComponentRef cref;
    Solvability sol;
  algorithm
    // aliases the alias module could not remove, e.g. elements of arrays, are assigned first like the
    // old backend removes them before tearing
    if cellierIsAliasSide(Equation.getLHS(eqn)) and cellierIsAliasSide(Equation.getRHS(eqn)) then
      points := 1000;
      return;
    end if;
    for side in {Equation.getLHS(eqn), Equation.getRHS(eqn)} loop
      solved := match side
        case SOME(Expression.CREF(cref = cref)) then cref :: solved;
        else solved;
      end match;
    end for;
    for tpl in UnorderedMap.toList(solvabilities) loop
      (cref, sol) := tpl;
      if StringUtil.startsWith(ComponentRef.firstName(cref), NBVariable.FUNCTION_STR) then
        points := points + 50;
      elseif not List.isMemberOnTrue(cref, solved, ComponentRef.isEqual) then
        points := points + (match sol
          case Solvability.EXPLICIT_LINEAR(vars = SOME(_)) then 20;
          case Solvability.EXPLICIT_LINEAR(pars = SOME(_)) then 10;
          case Solvability.EXPLICIT_LINEAR()               then 2;
          case Solvability.EXPLICIT_NONLINEAR()            then 50;
          case Solvability.UNKNOWN()                       then 0;
          else 100;
        end match);
      end if;
    end for;
  end cellierNonlinearityPoints;

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
    input array<Boolean> row_capable;
    input output list<Integer> fresh;
    input output list<Integer> touched "rows that can be assigned on their own and lost an unknown";
  protected
    Integer start, size;
  algorithm
    (start, size) := mapping.var_AtS[u];
    for s in start:start + size - 1 loop
      (fresh, touched) := cellierMarkScalarKnown(s, mapping, mT, mT_data, row_in_loop, known_scal, eqn_unknown, eqn_size, eqn_step, row_capable, fresh, touched);
    end for;
    arrayUpdate(unknown_rem, u, 0);
  end cellierMarkKnown;

  function cellierMarkScalarKnown
    "marks a scalar known and collects the equations and rows that might be assignable now"
    input Integer s;
    input Adjacency.Mapping mapping;
    input Adjacency.IntMatrix mT;
    input array<Integer> mT_data;
    input array<Boolean> row_in_loop;
    input array<Boolean> known_scal;
    input array<Integer> eqn_unknown;
    input array<Integer> eqn_size;
    input array<Integer> eqn_step;
    input array<Boolean> row_capable;
    input output list<Integer> fresh;
    input output list<Integer> touched;
  protected
    Integer e, r;
  algorithm
    if known_scal[s] then return; end if;
    arrayUpdate(known_scal, s, true);
    for piece in mT.first[s]:mT.first[s] + mT.pieces[s] - 1 loop
      for p in Adjacency.IntMatrix.pieceBegin(mT, piece):Adjacency.IntMatrix.pieceEnd(mT, piece) loop
        r := mT_data[p];
        if row_in_loop[r] then
          e := mapping.eqn_StA[r];
          arrayUpdate(eqn_unknown, e, eqn_unknown[e] - 1);
          if eqn_unknown[e] == eqn_size[e] and eqn_step[e] == 0 then
            fresh := e :: fresh;
          end if;
          if row_capable[e] then
            touched := r :: touched;
          end if;
        end if;
      end for;
    end for;
  end cellierMarkScalarKnown;

  function cellierRowCapable
    "true for equations whose rows can be solved one at a time"
    input Equation eqn;
    output Boolean b;
  algorithm
    b := match eqn
      case Equation.FOR_EQUATION(body = {Equation.SCALAR_EQUATION()}) then true;
      else false;
    end match;
  end cellierRowCapable;

  function cellierRowResizable
    "true for for equations whose number of rows is not known, their rows can only be
    assigned all at once as a chain"
    input Equation eqn;
    output Boolean b;
  algorithm
    b := match eqn
      case Equation.FOR_EQUATION() then Iterator.isResizable(eqn.iter);
      else false;
    end match;
  end cellierRowResizable;

  function cellierChain
    "the rows that can be solved one after another starting with row r for the scalar sv, e.g.
    x[i] = x[i+1] + y[i]. the rows of different for equations can alternate, e.g. x[i] = y[i-1]
    and y[i] = f(x[i]). every equation solves elements of one variable. it is complete if it
    covers every unassigned row of its equations."
    input Integer r;
    input Integer sv;
    input Boolean single "only rows of the equation of r";
    input Adjacency.IntMatrix m;
    input array<Integer> m_data;
    input Adjacency.IntMatrix mT;
    input array<Integer> mT_data;
    input array<Boolean> known_scal;
    input array<Boolean> row_in_loop;
    input array<Boolean> row_capable;
    input array<Integer> row_step;
    input array<Integer> eqn_step;
    input array<list<Integer>> eqn_rows;
    input Adjacency.Mapping mapping;
    input array<Integer> unit_kind;
    input VariablePointers vars;
    input EquationPointers eqns;
    input array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    input array<Integer> eqn_glob;
    input UnorderedMap<Path, Function> funcMap;
    input UnorderedMap<Integer, Boolean> probes;
    input UnorderedMap<Integer, Integer> ranks;
    output list<tuple<Integer, Integer>> chain = {(r, sv)};
    output Boolean complete = true;
  protected
    Integer e0 = mapping.eqn_StA[r], e, u, cnt, s, q;
    UnorderedMap<Integer, Integer> eqn_unit = UnorderedMap.new<Integer>(Util.id, intEq);
    UnorderedMap<Integer, Integer> eqn_count = UnorderedMap.new<Integer>(Util.id, intEq);
    UnorderedSet<Integer> in_chain = UnorderedSet.new(Util.id, intEq);
    list<Integer> marked = {sv}, queue, next;
  algorithm
    UnorderedMap.add(e0, mapping.var_StA[sv], eqn_unit);
    UnorderedMap.add(e0, 1, eqn_count);
    UnorderedSet.add(r, in_chain);
    arrayUpdate(known_scal, sv, true);
    queue := {sv};
    // breadth first, every new row has exactly one unknown left
    while not listEmpty(queue) loop
      next := {};
      for k in listReverse(queue) loop
        for piece in mT.first[k]:mT.first[k] + mT.pieces[k] - 1 loop
          for p in Adjacency.IntMatrix.pieceBegin(mT, piece):Adjacency.IntMatrix.pieceEnd(mT, piece) loop
            q := mT_data[p];
            e := mapping.eqn_StA[q];
            if row_in_loop[q] and row_capable[e] and row_step[q] == 0 and eqn_step[e] == 0
               and not UnorderedSet.contains(q, in_chain) and (not single or e == e0) then
              (cnt, s) := cellierRowUnknown(q, m, m_data, known_scal);
              u := if cnt == 1 then mapping.var_StA[s] else 0;
              if cnt == 1 and (if UnorderedMap.contains(e, eqn_unit) then UnorderedMap.getSafe(e, eqn_unit, sourceInfo()) == u
                  else cellierRowSolvable(e, u, unit_kind, vars, eqns, solvabilities, eqn_glob, funcMap, probes, ranks) > 0) then
                UnorderedMap.tryAdd(e, u, eqn_unit);
                UnorderedMap.add(e, UnorderedMap.getOrDefault(e, eqn_count, 0) + 1, eqn_count);
                UnorderedSet.add(q, in_chain);
                arrayUpdate(known_scal, s, true);
                marked := s :: marked;
                chain := (q, s) :: chain;
                next := s :: next;
              end if;
            end if;
          end for;
        end for;
      end for;
      queue := next;
    end while;
    for k in marked loop
      arrayUpdate(known_scal, k, false);
    end for;
    chain := listReverse(chain);
    for tpl in UnorderedMap.toList(eqn_count) loop
      (e, cnt) := tpl;
      complete := complete and cnt == sum(1 for q guard(row_step[q] == 0) in eqn_rows[e]);
    end for;
  end cellierChain;

  function cellierRowUnknown
    "number of unknown scalars in a row and the last one of them"
    input Integer r;
    input Adjacency.IntMatrix m;
    input array<Integer> m_data;
    input array<Boolean> known_scal;
    output Integer cnt = 0;
    output Integer sv = 0;
  algorithm
    for piece in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
      for p in Adjacency.IntMatrix.pieceBegin(m, piece):Adjacency.IntMatrix.pieceEnd(m, piece) loop
        if not known_scal[m_data[p]] then
          cnt := cnt + 1;
          sv := m_data[p];
        end if;
      end for;
    end for;
  end cellierRowUnknown;

  function cellierRowIsValid
    input tuple<Integer, Integer> c "row and the scalar it would be solved for";
    input Adjacency.IntMatrix m;
    input array<Integer> m_data;
    input array<Boolean> known_scal;
    input array<Integer> row_step;
    input array<Integer> eqn_step;
    input Adjacency.Mapping mapping;
    output Boolean b;
  protected
    Integer r, sv, cnt, last;
  algorithm
    (r, sv) := c;
    b := row_step[r] == 0 and eqn_step[mapping.eqn_StA[r]] == 0 and not known_scal[sv];
    if b then
      (cnt, last) := cellierRowUnknown(r, m, m_data, known_scal);
      b := cnt == 1 and last == sv;
    end if;
  end cellierRowIsValid;

  function cellierRowSolvable
    "the rank of solving a row of the equation for an element of the loop variable. with several
    occurrences (x[i] and x[i+1]) only a coefficient of one is accepted."
    input Integer e;
    input Integer u;
    input array<Integer> unit_kind;
    input VariablePointers vars;
    input EquationPointers eqns;
    input array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
    input array<Integer> eqn_glob;
    input UnorderedMap<Path, Function> funcMap;
    input UnorderedMap<Integer, Boolean> probes;
    input UnorderedMap<Integer, Integer> ranks;
    output Integer rank = 0 "solvability rank, 0 if not solvable";
  protected
    ComponentRef name;
    Integer key;
  algorithm
    if unit_kind[u] <> 1 then return; end if;
    key := e * (arrayLength(unit_kind) + 1) + u;
    if UnorderedMap.contains(2 * key + 1, ranks) then
      rank := UnorderedMap.getSafe(2 * key + 1, ranks, sourceInfo());
      return;
    end if;
    name := BVariable.getVarName(VariablePointers.getVarAt(vars, u));
    rank := cellierRankCached(2 * key, name, solvabilities[eqn_glob[e]], ranks);
    if List.hasOneElement(cellierOccurrences(name, solvabilities[eqn_glob[e]])) then
      if rank >= 1 and rank <= 4 then
        if not UnorderedMap.contains(key, probes) then
          UnorderedMap.add(key, cellierSolvable(EquationPointers.getEqnAt(eqns, e), name, solvabilities[eqn_glob[e]], funcMap), probes);
        end if;
        if not UnorderedMap.getSafe(key, probes, sourceInfo()) then rank := 0; end if;
      else
        rank := 0;
      end if;
    elseif rank <> 1 then
      rank := 0;
    end if;
    UnorderedMap.add(2 * key + 1, rank, ranks);
  end cellierRowSolvable;

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
    input UnorderedMap<Integer, Integer> ranks;
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
      for piece in m.first[r]:m.first[r] + m.pieces[r] - 1 loop
        for p in Adjacency.IntMatrix.pieceBegin(m, piece):Adjacency.IntMatrix.pieceEnd(m, piece) loop
          if not known_scal[m_data[p]] then
            cnt := cnt + 1;
            sv := m_data[p];
          end if;
        end for;
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
      key := e * (arrayLength(unit_kind) + 1) + listHead(units);
      rank := cellierRankCached(2 * key, name, solvabilities[eqn_glob[e]], ranks);
      if rank < 1 or rank > 4 then
        rank := 0;
      else
        // make sure the solver can actually do it
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

  function cellierRankCached
    input Integer key;
    input ComponentRef name;
    input UnorderedMap<ComponentRef, Solvability> solvabilities;
    input UnorderedMap<Integer, Integer> ranks;
    output Integer rank;
  algorithm
    rank := match UnorderedMap.get(key, ranks)
      case SOME(rank) then rank;
      else algorithm
        rank := cellierRank(name, solvabilities);
        UnorderedMap.add(key, rank, ranks);
      then rank;
    end match;
  end cellierRankCached;

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
        // like the old backend: do not divide by parameters that are zero
        if b and isParameterDivision(UnorderedMap.getSafe(listHead(crefs), solvabilities, sourceInfo())) then
          b := not isZeroCoefficient(eqn, listHead(crefs), funcMap);
        end if;
      else
        b := false;
      end try;
      ErrorExt.rollBack(getInstanceName());
    end if;
  end cellierSolvable;

  function isParameterDivision
    input Solvability sol;
    output Boolean b;
  algorithm
    b := match sol
      case Solvability.EXPLICIT_LINEAR(pars = SOME(_), vars = NONE()) then true;
      else false;
    end match;
  end isParameterDivision;

  function isZeroCoefficient
    "true if the coefficient of the variable evaluates to zero with the parameter bindings"
    input Equation eqn;
    input ComponentRef cref;
    input UnorderedMap<Path, Function> funcMap;
    output Boolean b;
  protected
    Expression coeff;
  algorithm
    try
      (coeff, _) := Differentiate.differentiateExpression(Equation.getResidualExp(eqn), Differentiate.DifferentiationArguments.simpleCref(cref, funcMap));
      for i in 1:5 loop
        coeff := SimplifyExp.simplify(Expression.map(coeff, parameterBinding));
        if Expression.isLiteral(coeff) then break; end if;
      end for;
      b := Expression.isLiteral(coeff) and Expression.isZero(coeff);
    else
      b := false;
    end try;
  end isZeroCoefficient;

  function parameterBinding
    input output Expression exp;
  protected
    Pointer<Variable> var_ptr;
    Variable var;
  algorithm
    exp := match exp
      case Expression.CREF() guard(BVariable.checkCref(exp.cref, BVariable.isParamOrConst, sourceInfo())) algorithm
        var_ptr := BVariable.getVarPointer(exp.cref, sourceInfo());
        var := Pointer.access(var_ptr);
      then if Binding.hasExp(var.binding) then
          Expression.applySubscripts(ComponentRef.getSubscripts(exp.cref), Binding.getExp(var.binding))
        else exp;
      else exp;
    end match;
  end parameterBinding;

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
    input array<Integer> unknown_full;
    input array<Integer> unit_kind;
    input array<Integer> eqn_step;
    input VariablePointers vars;
    output Integer best = 0 "0 if there is no unit that can be torn as a whole";
  protected
    Integer start, size, cls, occ, e, best_cls = -1, best_occ = -1, best_size = 0;
    Boolean has_start, best_start = false;
    array<Integer> seen = arrayCreate(arrayLength(eqn_step), 0);
  algorithm
    for u in 1:arrayLength(unknown_rem) loop
      if unit_kind[u] <> 3 and unknown_rem[u] > 0 and unknown_rem[u] == unknown_full[u] then
        cls := Integer(BVariable.getTearingSelect(VariablePointers.getVarAt(vars, u)));
        // a tear variable without start value would start the iteration at zero
        has_start := isSome(BVariable.getStartAttribute(VariablePointers.getVarAt(vars, u)));
        occ := 0;
        (start, size) := mapping.var_AtS[u];
        for s in start:start + size - 1 loop
          if not known_scal[s] then
            for piece in mT.first[s]:mT.first[s] + mT.pieces[s] - 1 loop
              for p in Adjacency.IntMatrix.pieceBegin(mT, piece):Adjacency.IntMatrix.pieceEnd(mT, piece) loop
                if row_in_loop[mT_data[p]] then
                  e := mapping.eqn_StA[mT_data[p]];
                  if eqn_step[e] == 0 and seen[e] <> u then
                    seen[e] := u;
                    occ := occ + 1;
                  end if;
                end if;
              end for;
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

      // skip the placeholders of omitted outputs, e.g. (_, y) = f(x)
      case Equation.RECORD_EQUATION(lhs = tpl as Expression.TUPLE()) algorithm
      then list(BVariable.getVarPointer(tpl_cr, sourceInfo()) for tpl_cr guard(not (ComponentRef.isWild(tpl_cr) or ComponentRef.isEmpty(tpl_cr)))
        in UnorderedSet.toList(Expression.extractCrefs(tpl)));

      case Equation.RECORD_EQUATION(lhs = Expression.CREF()) algorithm
        // ToDo: if vars contains any child of cref add all children of cref
      then {};

      else {};
    end match;
  end getImpliedInnerVars;

  annotation(__OpenModelica_Interface="nbackend");
end NBTearing;

